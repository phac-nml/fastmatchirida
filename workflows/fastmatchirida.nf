/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap; fromSamplesheet  } from 'plugin/nf-validation'
include { loadIridaSampleIds                                   } from 'plugin/nf-iridanext'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

Workflowfastmatchirida.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { WRITE_METADATA                         } from '../modules/local/write/main'
include { COPY_FILE                              } from '../modules/local/copyFile/main'
include { LOCIDEX_MERGE as LOCIDEX_MERGE_REF     } from '../modules/local/locidex/merge/main'
include { LOCIDEX_MERGE as LOCIDEX_MERGE_QUERY   } from '../modules/local/locidex/merge/main'
include { LOCIDEX_CONCAT as LOCIDEX_CONCAT_QUERY } from '../modules/local/locidex/concat/main'
include { LOCIDEX_CONCAT as LOCIDEX_CONCAT_REF   } from '../modules/local/locidex/concat/main'
include { PROFILE_DISTS                          } from '../modules/local/profile_dists/main'
include { PROCESS_OUTPUT                         } from '../modules/local/process_output/main'
include { APPEND_METADATA                        } from '../modules/local/append_metadata/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/


def prepareFilePath(String filep){
    // Rerturns null if a file is not valid
    def return_path = null
    if(filep){
        file_in = file(filep)
        if(file_in.exists()){
            return_path = file_in
        }
    }else{
        return_path = []
    }

    return return_path // empty value if file argument is null
}

workflow FASTMATCH {
    SAMPLE_HEADER = "sample"
    ch_versions = Channel.empty()
    // Track processed IDs and MLST files
    def processedIDs  = [] as Set
    def processedMLST  = [] as Set
    // Create a new channel of metadata from a sample sheet
    // NB: `input` corresponds to `params.input` and associated sample sheet schema
    pre_input = Channel.fromSamplesheet("input")
    // and remove non-alphanumeric characters in sample_names (meta.id), whilst also correcting for duplicate sample_names (meta.id)
    .map { meta, mlst_file, ref_query ->
            uniqueMLST = true
            if (!meta.id) {
                meta.id = meta.irida_id
            } else {
                // Non-alphanumeric characters (excluding _,-,.) will be replaced with "_"
                meta.id = meta.id.replaceAll(/[^A-Za-z0-9_.\-]/, '_')
            }
            // Ensure ID is unique by appending meta.irida_id if needed
            while (processedIDs.contains(meta.id)) {
                meta.id = "${meta.id}_${meta.irida_id}"

            }
            // Check if the MLST file is unique
            if (processedMLST.contains(mlst_file.baseName)) {
                uniqueMLST = false
            }
            // Add the ID to the set of processed IDs
            processedIDs << meta.id
            processedMLST << mlst_file.baseName
            // If the fastmatch_category is blank make the default "reference"
            if (!ref_query) {
                meta.ref_query = "reference"
            } else {
                meta.ref_query = ref_query
            }
            tuple(meta, mlst_file, uniqueMLST)}.loadIridaSampleIds()

    // For the MLST files that are not unique, rename them
    pre_input
        .branch { meta, mlst_file, uniqueMLST ->
            keep: uniqueMLST == true // Keep the unique MLST files as is
            replace: uniqueMLST == false // Rename the non-unique MLST files to avoid collisions
        }.set {mlst_file_rename}
    renamed_input = COPY_FILE(mlst_file_rename.replace)
    unchanged_input = mlst_file_rename.keep
        .map { meta, mlst_file, uniqueMLST ->
            tuple(meta, mlst_file) }
    input = unchanged_input.mix(renamed_input)

    // Metadata formatting
    metadata_headers = Channel.of(
        tuple(
            SAMPLE_HEADER,
            params.metadata_1_header, params.metadata_2_header,
            params.metadata_3_header, params.metadata_4_header,
            params.metadata_5_header, params.metadata_6_header,
            params.metadata_7_header, params.metadata_8_header)
        )

    metadata_rows = input.map{
        meta, mlst_files -> tuple(meta.id, meta.irida_id,
        meta.metadata_1, meta.metadata_2, meta.metadata_3, meta.metadata_4,
        meta.metadata_5, meta.metadata_6, meta.metadata_7, meta.metadata_8)
    }.toList()


    // Seperate the input into two channels based on the referemce or query samples
    input
    .branch { meta, mlst_file ->
        reference: meta.ref_query == "reference"
        query: meta.ref_query == "query"
        }.set {merged_alleles}

    // Prepare reference and query MLST files for LOCIDEX_MERGE
    merged_alleles_query = merged_alleles.query.map{
        meta, mlst_files -> mlst_files
    }.collect()

    merged_alleles_reference = merged_alleles.reference.
    concat(merged_alleles.query).map{   // Reference will contain both query and reference
        meta, mlst_files -> mlst_files
    }.collect()

    // LOCIDEX BLOCK
    // Two Steps: 1) Merge and 2) Concatenate
    // LOCIDEX value channels
    ref_tag   = Channel.value("ref")                                             // Seperate the reference samples
    query_tag = Channel.value("query")                                           // Seperate the query samples

    // Create channels to be used to create a MLST override file (below)
    SAMPLE_HEADER = "sample"
    MLST_HEADER   = "mlst_alleles"

    write_metadata_headers = Channel.of(
        tuple(
            SAMPLE_HEADER, MLST_HEADER)
        )

    write_metadata_rows = input.map{
        def meta = it[0]
        def mlst = it[1]
        tuple(meta.id,mlst)
    }.toList()

    merge_tsv = WRITE_METADATA (write_metadata_headers, write_metadata_rows).results.first() // MLST override file value channel

        // LOCIDEX Step 1:
    // Merge MLST files into TSV

    // 1A) Divide up inputs into groups for LOCIDEX
    def refbatchCounter = 1
    grouped_ref_files = merged_alleles_reference.flatten() //
        .buffer( size: params.batch_size, remainder: true )
                .map { batch ->
        def index = refbatchCounter++
        return tuple(index, batch)
    }
    def quebatchCounter = 1
    grouped_query_files = merged_alleles_query.flatten() //
        .buffer( size: params.batch_size, remainder: true )
        .map { batch ->
        def index = quebatchCounter++
        return tuple(index, batch)
    }

    // 1B) Run LOCIDEX on grouped query and reference samples
    references = LOCIDEX_MERGE_REF(grouped_ref_files, ref_tag, merge_tsv)
    ch_versions = ch_versions.mix(references.versions)

    queries = LOCIDEX_MERGE_QUERY(grouped_query_files, query_tag, merge_tsv)
    ch_versions = ch_versions.mix(queries.versions)

    // LOCIDEX Step 2:
    // Combine outputs

    // LOCIDEX Concatenate References
    combined_references = LOCIDEX_CONCAT_REF(references.combined_profiles.collect(),
        references.combined_error_report.collect(),
        ref_tag,
        references.combined_profiles.collect().flatten().count())
    ch_versions = ch_versions.mix(combined_references.versions)
    // LOCIDEX Concatenate References
    combined_queries = LOCIDEX_CONCAT_QUERY(queries.combined_profiles.collect(),
        queries.combined_error_report.collect(),
        query_tag,
        queries.combined_profiles.collect().flatten().count())
    ch_versions = ch_versions.mix(combined_queries.versions)

    // optional files passed in
    mapping_file = prepareFilePath(params.pd_mapping_file)
    if(mapping_file == null){
        exit 1, "${params.pd_mapping_file}: Does not exist but was passed to the pipeline. Exiting now."
    }

    columns_file = prepareFilePath(params.pd_columns)
    if(columns_file == null){
        exit 1, "--pd_columns ${params.pd_columns}: Does not exist but was passed to the pipeline. Exiting now."
    }

    // Check that only 'hamming' or 'scaled' are provided to pd_distm
    if ((params.pd_distm != 'hamming') & (params.pd_distm != 'scaled')) {
        exit 1, "'--pd_distm ${params.pd_distm}' is an invalid value. Please set to either 'hamming' or 'scaled'."
    }

    // Check that when using scaled the threshold exists between 0-100
    if (params.pd_distm == 'scaled') {
        if ((params.threshold < 0.0) || (params.threshold > 100.0)) {
            exit 1, ("'--pd_distm ${params.pd_distm}' is set, but '--threshold ${params.threshold}' contains thresholds outside of range [0, 100]."
                    + " Please either set '--threshold' or adjust the threshold values.")
        }
    }
    // Options related to profile dists
    mapping_format = Channel.value("pairwise")

    distances = PROFILE_DISTS(combined_queries.combined_profiles, combined_references.combined_profiles, mapping_format, mapping_file, columns_file)
    ch_versions = ch_versions.mix(distances.versions)

    // Append metadata to references:
    distances_metadata = APPEND_METADATA(distances.results, metadata_rows, metadata_headers)

    // Process the output:
    processed_output = PROCESS_OUTPUT(distances_metadata.distances, params.threshold)
    ch_versions = ch_versions.mix(processed_output.versions)

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
