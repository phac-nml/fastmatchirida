/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap; fromSamplesheet  } from 'plugin/nf-validation'

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
include { LOCIDEX_MERGE    } from '../modules/local/locidex/merge/main'
include { PROFILE_DISTS    } from '../modules/local/profile_dists/main'
include { INPUT_ASSURE     } from "../modules/local/input_assure/main"

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
    // Track processed IDs
    def processedIDs = [] as Set

    // Create a new channel of metadata from a sample sheet
    // NB: `input` corresponds to `params.input` and associated sample sheet schema
    input = Channel.fromSamplesheet("input").view()
    // and remove non-alphanumeric characters in sample_names (meta.id), whilst also correcting for duplicate sample_names (meta.id)
    .map { meta, mlst_file ->
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
            // Add the ID to the set of processed IDs
            processedIDs << meta.id
            // If the fastmatch_category is blank make the default "reference"
            if (!meta.ref_query) {
                meta.ref_query = "reference"
            }
            tuple(meta, mlst_file)}.view()
    // Make sure the ID in samplesheet / meta.id is the same ID
    // as the corresponding MLST JSON file:
    input_assure = INPUT_ASSURE(input)
    ch_versions = ch_versions.mix(input_assure.versions)

    merged_alleles = input_assure.result.map{
        meta, mlst_files -> mlst_files
    }.collect()

    metadata_headers = Channel.of(
        tuple(
            SAMPLE_HEADER,
            params.metadata_1_header, params.metadata_2_header,
            params.metadata_3_header, params.metadata_4_header,
            params.metadata_5_header, params.metadata_6_header,
            params.metadata_7_header, params.metadata_8_header)
        )

    metadata_rows = input_assure.result.map{
        meta, mlst_files -> tuple(meta.id, meta.irida_id,
        meta.metadata_1, meta.metadata_2, meta.metadata_3, meta.metadata_4,
        meta.metadata_5, meta.metadata_6, meta.metadata_7, meta.metadata_8)
    }.toList()

    merged = LOCIDEX_MERGE(merged_alleles)
    ch_versions = ch_versions.mix(merged.versions)

    // optional files passed in
    mapping_file = prepareFilePath(params.pd_mapping_file)
    if(mapping_file == null){
        exit 1, "${params.pd_mapping_file}: Does not exist but was passed to the pipeline. Exiting now."
    }

    columns_file = prepareFilePath(params.pd_columns)
    if(columns_file == null){
        exit 1, "--pd_columns ${params.pd_columns}: Does not exist but was passed to the pipeline. Exiting now."
    }

    if ((params.pd_distm != 'hamming') & (params.pd_distm != 'scaled')) {
        exit 1, "'--pd_distm ${params.pd_distm}' is an invalid value. Please set to either 'hamming' or 'scaled'."
    }

    // Options related to profile dists
    mapping_format = Channel.value(params.pd_outfmt)

    distances = PROFILE_DISTS(merged.combined_profiles, mapping_format, mapping_file, columns_file)
    ch_versions = ch_versions.mix(distances.versions)

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
