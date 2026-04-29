# phac-nml/fastmatchirida: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.2] - 2026/04/29

### Changed

- The scheduled pipelines output mode (`--output_type scheduled`) now outputs only the original FastMatch XLSX file format. An additional file (`process/fastmatch.scheduled.tsv`) is now generated as described in v0.5.0 as scheduled mode ouput that is used exclusive for parsing schedule pipelines metadata back to IRIDA Next. [PR 53](https://github.com/phac-nml/fastmatchirida/pull/53)

## [0.5.1] - 2026/04/24

### Bug Fix

- The output filename, when used with `--prefix_include_date`, had an invalid character ":" for Azure Blob Storage in the timestamp. We will conform to the ISO 8601 basic format for the time component of the date, thereby dropping ":" from it. [PR 51](https://github.com/phac-nml/fastmatchirida/pull/51)

## [0.5.0] - 2026/04/21

### Added

- Scheduled Pipelines: Added a new operational mode for running the pipeline as a scheduled pipeline.
  - Added an `--output_type` parameter that controls whether the output should be formatted for a regular IRIDA Next execution (`--output_type iridanext` / default) or for a scheduled pipeline execution (`--output_type scheduled`). [PR 49](https://github.com/phac-nml/fastmatchirida/pull/49)
  - Added a parameter `query_selection_method` which takes either "user_provided" or "fastmatch_status" to determine which behavior for selecting the reference/query samples. "user_provided", the default behaves as before, with `fastmatch_category` being the column in the samplesheet for selecting reference/query based on "reference","query" or empty. "fastmatch_status", is to be used in the scheduled pipelines of IRIDA-Next, where it looks for a metadata_n column renamed to "fastmatch_status". Samples with values "Completed" are set as referene and empty values are set as query, and samples with other values are dropped. [PR #47](https://github.com/phac-nml/fastmatchirida/pull/47)
  - `--output_prefix`: a parameter for adding a prefix to the results files. [PR #48](https://github.com/phac-nml/fastmatchirida/pull/48)
  - `--prefix_include_date`: a parameter for adding a date and time prefix in the UTC time zone to the results files. [PR #48](https://github.com/phac-nml/fastmatchirida/pull/48)
  - Added a `--fastmatch_top_samples_threshold` parameter that is only used when generating output for a scheduled pipeline execution (`--output_type scheduled`). `--fastmatch_top_samples_threshold` controls the number of samples that are reported as `fastmatch_top_samples` and `fastmatch_top_genomic_address`. [PR 49](https://github.com/phac-nml/fastmatchirida/pull/49)

### `Updated`

- Set nextflow version 25.10.4 to replace 'latest-everything' to confirm compatibility with next IRIDA-Next nextflow version in `.github/workflows` for nf-test. [PR 4#4](https://github.com/phac-nml/fastmatchirida/pull/44)
- Updated tests and GitHub Actions/Workflows to the latest versions from the nf-core template. [PR #46](https://github.com/phac-nml/fastmatchirida/pull/46)
- Updated the minimum Nextflow version to `24.10.3`. [PR #46](https://github.com/phac-nml/fastmatchirida/pull/46)
- Changed `LOCIDEX_MERGE`from profile `proccess_medium` to `process_single`. [PR #47](https://github.com/phac-nml/fastmatchirida/pull/47)

### `Fixed`

- Fixed `containerOptions` string so the required options are only passed when using the `docker` profile (and not for `singularity`). [PR #45](https://github.com/phac-nml/fastmatchirida/pull/45)

## [0.4.2] - 2025-11-20

### `Changed`

- Adding GitHub CI tests against Nextflow `24.10.3`. [PR #40](https://github.com/phac-nml/fastmatchirida/pull/40)
- Version of `profile_dists` to `1.0.10`. [PR #41](https://github.com/phac-nml/fastmatchirida/pull/41)

## [0.4.1] - 2025-09-12

### `Updated`

- Upgraded `locidex` to [v.0.4.0](https://github.com/phac-nml/locidex/releases/tag/v0.4.0). [PR 33](https://github.com/phac-nml/fastmatchirida/pull/33)

### `Added`

- Added a process level `nf-test` for `LOCIDEX_MERGE` to confirm backward compatibility between MLST JSON files with and without a `"manfiest"` key. [PR 33](https://github.com/phac-nml/fastmatchirida/pull/33)

## [0.4.0] - 2025-08-11

### `Changed`

- The number of metadata columns in the sample sheet has been increased from 8 to 16. [PR 28](https://github.com/phac-nml/fastmatchirida/pull/28)

## [0.3.3] - 2025-06-12

### `Updated`

- Update `profile_dists` to `v.1.0.8`. [PR 25](https://github.com/phac-nml/fastmatchirida/pull/25)
- Updated nf-core linting and some of the nf-core GitHub actions to the latest versions. [PR 25](https://github.com/phac-nml/fastmatchirida/pull/25)
- Updated nf-core module [custom_dumpsoftwareversions](https://nf-co.re/modules/custom_dumpsoftwareversions/) to latest version (commit `05954dab2ff481bcb999f24455da29a5828af08d`). [PR 25](https://github.com/phac-nml/fastmatchirida/pull/25)

### `Added`

- Added an ubuntu container for the `COPY_FILE` process to ensure bash commands are functional. [PR 26](https://github.com/phac-nml/fastmatchirida/pull/26)

## [0.3.2] - 2025-05-23

- Added `baseName` to the check for repeat MLST allele files (in case file paths are different). [PR 22](https://github.com/phac-nml/fastmatchirida/pull/22)

## [0.3.1] - 2025-05-23

### `Fixes`

- Fix Issue [#19](https://github.com/phac-nml/fastmatchirida/issues/19) by providing a new process `copyFile` to rename duplicate MLST files. [PR 20](https://github.com/phac-nml/fastmatchirida/pull/20)
- Fix Issue [#18](https://github.com/phac-nml/fastmatchirida/issues/18) changing input type for `merge_tsv`. [PR 20](https://github.com/phac-nml/fastmatchirida/pull/20)

### `Updated`

- Update `profile_dists` to `v.1.0.6`. [PR 20](https://github.com/phac-nml/fastmatchirida/pull/20)

## [0.3.0] - 2025-05-08

### `Update`

- Update `profile_dists` to [1.0.5](https://github.com/phac-nml/profile_dists/releases/tag/1.0.5). [PR 14](https://github.com/phac-nml/fastmatchirida/pull/14)
- Update the `locidex` version to [0.3.0](https://pypi.org/project/locidex/0.3.0/). `locidex merge` has integrated the functionality of module `input_assure`. [PR 15](https://github.com/phac-nml/fastmatchirida/pull/15)

### `Add`

- Add `software_versions.yml` to `iridanext.output.json.gz` global files. [PR 14](https://github.com/phac-nml/fastmatchirida/pull/14)

### `Changed`

- Change the default `profile_dists` default setting `pd_skip = true`. [PR 16](https://github.com/phac-nml/fastmatchirida/pull/16)

### `Enhancement`

- `locidex merge` in `0.3.0` now performs the functionality of `input_assure` (checking sample name against MLST profiles). This allows `fastmatchirida` to remove `input_assure` so that the MLST JSON file is read only once, and no longer needs to re-write with correction. [PR 15](https://github.com/phac-nml/fastmatchirida/pull/15)
- Added a pre-processing step to the input of `LOCIDEX_MERGE` that splits-up samples, into batches (default batch size: `100`), to allow for `LOCIDEX_MERGE` to be run in parallel. To modify the size of batches use the parameter `--batch_size n`. [PR 15](https://github.com/phac-nml/fastmatchirida/pull/15)

## [0.2.0] - 2025-04-09

### `Changed`

- Changed file extensions (`.text` -> `.tsv`) of output files from `GAS_MCLUSTER` and `PROFILE_DISTS` found in the `iridanext.output.json`. Output files are now compatiable with file preview feature in IRIDA Next. [PR 10](https://github.com/phac-nml/fastmatchirida/pull/10)
- Changed the default threshold for minimum matching alleles from 1 to 50 for filtering. The idea being to show more results and let user filter themselves after. [PR 12](https://github.com/phac-nml/fastmatchirida/pull/12)

### `Updated`

- Update the `profile_dist` version to [1.0.4](https://github.com/phac-nml/profile_dists/releases/tag/1.0.4). [PR 11](https://github.com/phac-nml/fastmatchirida/pull/11)

## [0.1.1] - 2024-01-17

This release improves documentation and testing.

## [0.1.0] - 2024-12-13

fastmatchirida is built using Gasclustering [0.4.0] as a template. Set up the basic-functionality of taking a query and reference set of samples and returning the samples distance, above a user-set threshold.

[0.1.1]: https://github.com/phac-nml/fastmatchirida/releases/tag/0.1.1
[0.1.0]: https://github.com/phac-nml/fastmatchirida/releases/tag/0.1.0
[0.2.0]: https://github.com/phac-nml/fastmatchirida/releases/tag/0.2.0
[0.3.0]: https://github.com/phac-nml/fastmatchirida/releases/tag/0.3.0
[0.3.1]: https://github.com/phac-nml/fastmatchirida/releases/tag/0.3.1
[0.3.2]: https://github.com/phac-nml/fastmatchirida/releases/tag/0.3.2
[0.3.3]: https://github.com/phac-nml/fastmatchirida/releases/tag/0.3.3
[0.4.0]: https://github.com/phac-nml/fastmatchirida/releases/tag/0.4.0
[0.4.1]: https://github.com/phac-nml/fastmatchirida/releases/tag/0.4.1
[0.4.2]: https://github.com/phac-nml/fastmatchirida/releases/tag/0.4.2
[0.5.0]: https://github.com/phac-nml/fastmatchirida/releases/tag/0.5.0
[0.5.1]: https://github.com/phac-nml/fastmatchirida/releases/tag/0.5.1
[0.5.2]: https://github.com/phac-nml/fastmatchirida/releases/tag/0.5.2
