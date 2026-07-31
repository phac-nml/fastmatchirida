# phac-nml/fastmatchirida: Output

## Introduction

This document describes the output produced by the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

- **append**: The passed metadata to the pipeline appended to sample-sample distance pairings.
- **distances**: Distances between genomes from [profile_dists](https://github.com/phac-nml/profile_dists).
- **locidex**: The merged MLST JSON files (merge) into a single MLST profiles file (concat).
- **pipeline_info**: Information about the pipeline's execution.
- **process**: Processed sample-sample distance pairings.
- **write**: Headers for generating final files.

The IRIDA Next-compliant JSON output file will be named `iridanext.output.json.gz` and will be written to the top-level of the results directory. This file is compressed using GZIP and conforms to the [IRIDA Next JSON output specifications](https://github.com/phac-nml/pipeline-standards#42-irida-next-json). The file will automatically be validated against the fastmatchirida-specific JSON output schema.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [Locidex Merge/Concat Query](#locidex-merge-concat) - Merges query MLST profile JSON files into profile files then concatenates them into a single file.
- [Locidex Merge/Concat References](#locidex-merge-concat) - Merges reference MLST profile JSON files into profiles files then concatenates them into a single file.
- [Profile Dists](#profile-dists) - Computes pairwise distances between genomes using MLST allele differences.
- [Append Metadata](#append-metadata) - Appends the passed input metadata to the pairwise distances.
- [Process Output](#process-output) - Processes sample-sample distance pairings by distance threshold.

### Locidex Merge Concat

<details markdown="1">
<summary>Output files</summary>

- `locidex/`
  - `merge/`
    - `query/`
      - Merged MLST query profiles: `profile_{n}.tsv`
      - Merged MLST query error reports: `MLST_error_report_{n}.csv`
    - `ref/`
      - Merged MLST reference profiles: `profile_{n}.tsv`
      - Merged MLST reference error reports: `MLST_error_report_{n}.csv`

  - `concat/`
    - `query/`
      - Concatenated MLST query profiles: `profile_concat_query.tsv`
      - Concatenated MLST error reports: `MLST_error_report_concat_query.csv`
    - `reference/`
      - Concatenated MLST reference profiles: `profile_concat_ref.tsv`
      - Concatenated MLST error reports: `MLST_error_report_concat_ref.csv`

</details>

### Profile Dists

<details markdown="1">
<summary>Output files</summary>

- `distances/`
  - Mapping allele identifiers to integers: `allele_map.json`.
    For example:
    ```json
    {
      "l1": {
        "60b725f10c9c85c70d97880dfe8191b3": 1
      },
      "l2": {
        "60b725f10c9c85c70d97880dfe8191b3": 1
      },
      "l3": {
        "3b5d5c3712955042212316173ccf37be": 1,
        "60b725f10c9c85c70d97880dfe8191b3": 2
      }
    }
    ```
  - The query MLST profiles: `query_profile.tsv`
  - The reference MLST profiles: `ref_profile.tsv`
  - The computed distances based on MLST allele differences: `results.tsv`
  - Information on the profile_dists run: `run.json`

</details>

### Append Metadata

<details markdown="1">
<summary>Output files</summary>

- `append/`
  - The passed input metadata columns appended to the pairwise distances: `distances_and_metadata.tsv`

</details>

### Process Output

<details markdown="1">
<summary>Output files</summary>

- `process/`
  - Pairwise distance results meeting specifications in TSV-format (file path may have a prefix added): `fastmatch.tsv`
  - Pairwise distance results meeting specifications in XLSX-format (file path may have a prefix added): `fastmatch.xlsx`

The following parameters may be used (independently or together) to modify the prefix of the above file paths:

- `--output_prefix`: Prepends the specified prefix to the TSV and XLSX-format files above. For example, `--output_prefix PREFIX_` will result in the following file paths: `PREFIX_fastmatch.tsv` and `PREFIX_fastmatch.xlsx`.
- `--prefix_include_date`: Prepends the date and time in the UTC time zone. For example, `2026-03-31T1332Z_fastmatch.tsv` and `2026-03-31T1332Z_fastmatch.xlsx`.

The output of the Process Output module will change significantly if the `--output_type schedule` parameter option is provided. This option configures the process to generate output for scheduled pipelines runs. The following metadata is generated in scheduled pipeline output mode:

- **fastmatch_status**: The status of the sample from previous FastMatch runs. Example: "Completed".
- **fastmatch_top_samples**: A comma-seperated list of the top matching samples. The number of samples to maintain is determined by the `--fastmatch_top_samples_threshold` parameter. Example: "sample1,sample2,sample3".
- **fastmatch_matched_samples_count**: The number of samples that the query matched below the `--threshold`.
- **fastmatch_threshold**: Simply reports the `--threshold` parameter that was used to generate the results.
- **fastmatch_date**: The date and time in UTC that the pipeline was run.
- **fastmatch_code_match**: A comma-seperated list of all national outbreak code matches. This is not limited by the `--fastmatch_top_samples_threshold` parameter. Example: "1,2,3,4".
- **fastmatch_top_genomic_address**: The closest matches to each query. The number of samples is determined by the `--fastmatch_top_samples_threshold` parameter. Example: "1.1.1.1,1.2.2.2,2.3.4.5".
- **fastmatch_results_filename**: Simply reports the name of the XLSX file generated by the pipeline. The name may be prepended by a user-defined prefix (`--output_prefix`) and by a UTC date and time string (`--prefix_include_date`). Example: "Listeria_2026-04-10T1531Z_fastmatch.xlsx"

When run in scheduled pipelines output mode, only the final report `fastmatch.xlsx` file is provided back to IRIDA Next as a result file associated with the pipeline run. The IRIDA Next sample metadata results are parsed from a `fastmatch.scheduled.tsv` file that itself is not written back to IRIDA Next as a result file.

</details>

### IRIDA Next Output

<details markdown="1">
<summary>Output files</summary>

- `/`
  - IRIDA Next-compliant JSON output: `iridanext.output.json.gz`

</details>

### Pipeline Information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
