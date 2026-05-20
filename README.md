[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A524.10.3-brightgreen.svg)](https://www.nextflow.io/)

# FastMatch IRIDA Workflow

This workflow takes query and reference JSON-formatted MLST profiles and reports query-reference pairs that are sufficiently within a specified distance of each other.

A brief overview of the usage of this pipeline is given below. Further documentation can be found in the [docs](docs/) directory.

# Input

The input to the pipeline is a standard sample sheet (passed as `--input samplesheet.csv`) that looks like:

| sample  | fastmatch_category | mlst_alleles      | metadata_1 | metadata_2 | metadata_3 | metadata_4 | metadata_5 | metadata_6 | metadata_7 | metadata_8 | metadata_9 | metadata_10 | metadata_11 | metadata_12 | metadata_13 | metadata_14 | metadata_15 | metadata_16 |
| ------- | ------------------ | ----------------- | ---------- | ---------- | ---------- | ---------- | ---------- | ---------- | ---------- | ---------- | ---------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- | ----------- |
| SampleA | query              | sampleA.mlst.json | meta1      | meta2      | meta3      | meta4      | meta5      | meta6      | meta7      | meta8      | meta9      | meta10      | meta11      | meta12      | meta13      | meta14      | meta15      | meta16      |
| SampleB | reference          | sampleB.mlst.json | meta1      | meta2      | meta3      | meta4      | meta5      | meta6      | meta7      | meta8      | meta9      | meta10      | meta11      | meta12      | meta13      | meta14      | meta15      | meta16      |

Note that each sample must be defined as a `query` or `reference`. Samples designated with `query` will have their distance calculated to every sample in the sample sheet (`query` and `reference` samples), whereas `reference`-`reference` sample pairings do not have their distances calculated or reported.

The structure of this file is defined in [assets/schema_input.json](assets/schema_input.json). Validation of the sample sheet is performed by [nf-validation](https://nextflow-io.github.io/nf-validation/). Details on the columns can be found in the [Full Samplesheet](docs/usage.md#full-standard-samplesheet) documentation.

## Irida Next Optional Sample Name Configuration

`fastmatchirida` accepts the [IRIDA Next](https://github.com/phac-nml/irida-next) format for samplesheets which can contain an additional column: `sample_name`

`sample_name`: An **optional** column, that overrides `sample` for outputs (filenames and sample names) and reference assembly identification.

`sample_name` allows more flexibility in naming output files or sample identification. Unlike `sample`, `sample_name` is not required to contain unique values. `Nextflow` requires unique sample names, and therefore in the instance of repeat `sample_names`, `sample` will be suffixed to any `sample_name`. Non-alphanumeric characters (excluding `_`,`-`,`.`) will be replaced with `"_"`.

# Parameters

The main parameters are `--threshold`, `--input` as defined above and `--output` for specifying the output results directory. You may wish to provide `-profile singularity` to specify the use of singularity containers and `-r [branch]` to specify which GitHub branch you would like to run.

- `--threshold` the minimum alleles for filtering matches (default: 50)

## Metadata

In order to customize metadata headers, the parameters `--metadata_1_header` through `--metadata_16_header` may be specified. These parameters are used to re-name the headers in the final metadata table from the defaults (e.g., rename `metadata_1` to `country`).

## LOCIDEX

When large samplesheets are provided to LOCIDEX, they are split-up, into batches (default batch size: 100), to allow for `LOCIDEX_MERGE` to be run in parallel. To modify the size of batches use the parameter `--batch_size n`

## Distance Threshold

A distance threshold parameter may be used to constrain the maximum distances between reported sample pairs in the final reports. This can be accomplished by specifying `--threshold DISTANCE`, where `DISTANCE` is a non-negative integer when using Hamming distances or a float between [0.0, 100.0] when using scaled distances. See below for more information on these distance methods.

## Distance Methods

The distance measurement used can be one of two methods: Hamming or scaled.

### Hamming Distances

Hamming distances are integers representing the number of differing loci between two sequences and will range between [0, n], where `n` is the total number of loci. When using Hamming distances, you must specify `--pd_distm hamming`.

### Scaled Distances

Scaled distances are floats representing the percentage of differing loci between two sequences and will range between [0.0, 100.0]. When using scaled distances, you must specify `--pd_distm scaled`.

## profile_dists

The following can be used to adjust parameters for the [profile_dists][] tool.

- `--pd_distm`: The distance method/unit, either _hamming_ or _scaled_. For _hamming_ distances, the distance values will be a non-negative integer. For _scaled_ distances, the distance values are between 0.0 and 100.0. Please see the [Distance Method](#distance-method) section for more information.
- `--pd_missing_threshold`: The maximum proportion of missing data per locus for a locus to be kept in the analysis. Values from 0.0 to 1.0.
- `--pd_sample_quality_threshold`: The maximum proportion of missing data per sample for a sample to be kept in the analysis. Values from 0.0 to 1.0.
- `--pd_file_type`: Output format file type. One of _text_ or _parquet_.
- `--pd_mapping_file`: A file used to map allele codes to integers for internal distance calculations. Normally, this is unneeded unless you wish to override the automated process of mapping alleles to integers.
- `--pd_skip`: Skip QA/QC steps. Can be used as a flag, `--pd_skip`, or passing a boolean, `--pd_skip true` or `--pd_skip false`.
- `--pd_columns`: Defines the loci to keep within the analysis (default when unset is to keep all loci). Formatted as a single column file with one locus name per line. For example:
  - **Single column format**
    ```
    loci1
    loci2
    loci3
    ```
- `--pd_count_missing`: Count missing alleles as different. Can be used as a flag, `--pd_count_missing`, or passing a boolean, `--pd_count_missing true` or `--pd_count_missing false`. If true, will consider missing allele calls for the same locus between samples as a difference, increasing the distance counts.

## Output File Path Prefixes

The names of some output files can be prepended with additional information. A UTC time zone date and time string can be added with the `--prefix_include_date` flag. A user-defined prefix string may be provided with `--output_prefix`. For example:

- `--output_prefix Listeria_ --prefix_include_date`: `Listeria_2026-04-10T1531Z_fastmatch.xlsx`
- `--output_prefix Listeria_`: `Listeria_fastmatch.xlsx`
- `--prefix_include_date`: `2026-04-10T1531Z_fastmatch.xlsx`

## Schedule Pipelines

The `--output_type` parameter may be used to control whether the output should be formatted for a regular IRIDA Next execution (`--output_type iridanext` / default) or for a scheduled pipeline execution (`--output_type scheduled`). An additional parameter, `--fastmatch_top_samples_threshold` (default `5`), controls the number of closest samples to maintain for each query when running in scheduled pipelines output mode.

### Metadata

The following metadata is generated in scheduled pipeline output mode:

- **fastmatch_status**: The status of the sample from previous FastMatch runs. Example: "Completed".
- **fastmatch_top_samples**: A comma-seperated list of the top matching samples. The number of samples to maintain is determined by the `--fastmatch_top_samples_threshold` parameter. Example: "sample1,sample2,sample3".
- **fastmatch_matched_samples_count**: The number of samples that the query matched below the `--threshold`.
- **fastmatch_threshold**: Simply reports the `--threshold` parameter that was used to generate the results.
- **fastmatch_date**: The date and time in UTC that the pipeline was run.
- **fastmatch_code_match**: A comma-seperated list of all national outbreak code matches. This is not limited by the `--fastmatch_top_samples_threshold` parameter. Example: "1,2,3,4".
- **fastmatch_top_genomic_address**: The closest matches to each query. The number of samples is determined by the `--fastmatch_top_samples_threshold` parameter. Example: "1.1.1.1,1.2.2.2,2.3.4.5".
- **fastmatch_results_filename**: Simply reports the name of the XLSX file generated by the pipeline. The name may be prepended by a user-defined prefix (`--output_prefix`) and by a UTC date and time string (`--prefix_include_date`). Example: "Listeria_2026-04-10T1531Z_fastmatch.xlsx"

For example:

```
query_id       fastmatch_status        fastmatch_top_samples   fastmatch_matched_samples_count fastmatch_threshold     fastmatch_date  fastmatch_code_match  fastmatch_top_genomic_address    fastmatch_results_filename
sample1 Completed       sample1,sample2,sample3 3       50.0    2026-04-10T1531Z       1,2,3   1.1.1.1,1.1.1.2,2.3.4.5 Listeria_2026-04-10T1531Z_fastmatch.xlsx
sample2 Completed       sample1,sample2,sample3 3       50.0    2026-04-10T1531Z       1,2,3   1.1.1.1,1.1.1.2,2.3.4.5 Listeria_2026-04-10T1531Z_fastmatch.xlsx
```

### Output Files

When run in scheduled pipelines output mode, only the final report `fastmatch.xlsx` file is provided back to IRIDA Next as a result file associated with the pipeline run.

### Requirements

Scheduled pipelines output mode requires that `genomic_address_name` and `national_outbreak_code` are provided as metadata through the samplesheet and with metadata header specification (ex: `--metadata_1_header genomic_address_name`).

## Other

Other parameters (defaults from nf-core) are defined in [nextflow_schema.json](nextflow_schema.json).

See [Scheduled Pipeline Samplesheet](docs/usage.md#scheduled-pipeline-samplesheet) for running with `--query_selection_method "fastmatch_status"`.

# Running

To run the pipeline, please do:

```bash
nextflow run phac-nml/fastmatchirida -profile singularity -r main -latest --input https://github.com/phac-nml/fastmatchirida/raw/dev/assets/samplesheet.csv --outdir results
```

Where the `samplesheet.csv` is structured as specified in the [Input](#input) section.

# Output

A JSON file for loading metadata into IRIDA Next is output by this pipeline. The format of this JSON file is specified in our [Pipeline Standards for the IRIDA Next JSON](https://github.com/phac-nml/pipeline-standards#32-irida-next-json). This JSON file is written directly within the `--outdir` provided to the pipeline with the name `iridanext.output.json.gz` (ex: `[outdir]/iridanext.output.json.gz`).

An example of the what the contents of the IRIDA Next JSON file looks like for this particular pipeline is as follows:

```
{
    "files": {
      "global": [
            {
                "path": "pipeline_info/software_versions.yml"
            },
            {
                "path": "process/fastmatch.xlsx"
            },
            {
                "path": "process/fastmatch.tsv"
            },
            {
                "path": "distances/profile_dists.run.json"
            },
            {
                "path": "distances/profile_dists.results.tsv"
            },
            {
                "path": "distances/profile_dists.ref_profile.tsv"
            },
            {
                "path": "distances/profile_dists.query_profile.tsv"
            },
            {
                "path": "distances/profile_dists.allele_map.json"
            },
            {
                "path": "locidex/concat/query/MLST_error_report_concat_query.csv"
            },
            {
                "path": "locidex/concat/reference/MLST_error_report_concat_ref.csv"
            }
        ],
        "samples": {

        }
    },
    "metadata": {
        "samples": {

        }
    }
}
```

Within the `files` section of this JSON file, all of the output paths are relative to the `outdir`. Therefore, `"path": "process/results.xlsx"` refers to a file located within `outdir/process/results.xlsx`.

Details on the individual output files can be found in the [Output Documentation](docs/output.md).

## Test Profile

To run with the test profile, please do:

```bash
nextflow run phac-nml/fastmatchirida -profile docker,test -r main -latest --outdir results
```

# Legal

Copyright 2024 Government of Canada

Licensed under the MIT License (the "License"); you may not use
this work except in compliance with the License. You may obtain a copy of the
License at:

https://opensource.org/license/mit/

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

[profile_dists]: https://github.com/phac-nml/profile_dists
