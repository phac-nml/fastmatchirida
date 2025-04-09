# phac-nml/fastmatchirida: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - yyyy-mm-dd

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
