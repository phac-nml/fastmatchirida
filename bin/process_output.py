#!/usr/bin/env python

from pathlib import Path
from mimetypes import guess_type
from functools import partial
from enum import Enum
import gzip
import sys
import argparse
import pandas as pd
import bisect

DEFAULT_NUM_CLOSEST_SAMPLES = 5

class Metadata(Enum):
    # Input
    QUERY_ID = "Query ID"
    QUERY_SAMPLE_NAME = "Query Sample Name"
    REFERENCE_ID = "Reference ID"
    REFERENCE_SAMPLE_NAME = "Reference Sample Name"
    GENOMIC_ADDRESS_NAME = "genomic_address_name"
    NATIONAL_OUTBREAK_CODE = "national_outbreak_code"
    DISTANCE = "Distance"

    # Renamed Input
    # Pandas' .itertuples() (namedtuples specifically) cannot handle spaces,
    # so we must rename the IDs that have spaces.
    QUERY_ID_RENAME = "query_id"
    QUERY_SAMPLE_NAME_RENAME = "query_sample_name"
    REFERENCE_ID_RENAME = "reference_id"
    REFERENCE_SAMPLE_NAME_RENAME = "reference_sample_name"

    # Output
    STATUS = "fastmatch_status"
    TOP_SAMPLES = "fastmatch_top_samples"
    MATCHED_SAMPLES_COUNT = "fastmatch_matched_samples_count"
    THRESHOLD = "fastmatch_threshold"
    DATE = "fastmatch_date"
    CODE_MATCH = "fastmatch_code_match"
    TOP_GENOMIC_ADDRESS = "fastmatch_top_genomic_address"
    RESULTS_FILENAME = "fastmatch_results_filename"

    # Values:
    COMPLETED = "Completed"

class Summary():
    """
    The Summary object summarizes information related to an individual query ID (ex: sample1),
    which will likely match to multiple queries and references (ex: sample1, sample2, sample3).
    """

    class Sample():
        def __init__(self, reference_id, distance, genomic_address_name):
            self.reference_id = reference_id
            self.distance = distance
            self.genomic_address_name = genomic_address_name

    def __init__(self, query_id, top_samples_threshold):
        self.query_id = query_id
        self.top_samples_threshold = top_samples_threshold

        self.genomic_address_names = []
        self.national_outbreak_codes = []
        self.closest_samples = []
        self.matched_samples = 0

    def add_national_outbreak_code(self, national_outbreak_code):
        if national_outbreak_code not in self.national_outbreak_codes:
            self.national_outbreak_codes.append(str(national_outbreak_code))

    def maintain_closest_samples(self, sample):
        bisect.insort(self.closest_samples, sample, key=lambda sample: sample.distance)
        self.closest_samples = self.closest_samples[:self.top_samples_threshold]

    def process_row(self, row):
        genomic_address_name = getattr(row, Metadata.GENOMIC_ADDRESS_NAME.value)
        national_outbreak_code = getattr(row, Metadata.NATIONAL_OUTBREAK_CODE.value)
        reference_id = getattr(row, Metadata.REFERENCE_ID_RENAME.value)
        distance = getattr(row, Metadata.DISTANCE.value)

        self.matched_samples += 1

        self.add_national_outbreak_code(national_outbreak_code)

        sample = self.Sample(reference_id, distance, genomic_address_name)
        self.maintain_closest_samples(sample)

    def get_genomic_address_names(self):
        closest_addresses = [sample.genomic_address_name for sample in self.closest_samples]
        return ",".join(closest_addresses)

    def get_national_outbreak_codes(self):
        codes = sorted(self.national_outbreak_codes)
        return ",".join(codes)

    def get_closest_samples(self):
        closest_samples = [sample.reference_id for sample in self.closest_samples]
        return ",".join(closest_samples) # List is already sorted by distance.

def get_open(f):
    if "gzip" == guess_type(str(f))[1]:
        return partial(gzip.open)
    else:
        return open

def rename_columns(data):
    renamed = data.rename(columns={
        Metadata.QUERY_ID.value: Metadata.QUERY_ID_RENAME.value,
        Metadata.QUERY_SAMPLE_NAME.value: Metadata.QUERY_SAMPLE_NAME_RENAME.value,
        Metadata.REFERENCE_ID.value: Metadata.REFERENCE_ID_RENAME.value,
        Metadata.REFERENCE_SAMPLE_NAME: Metadata.REFERENCE_SAMPLE_NAME_RENAME.value
    })

    return renamed

def process_scheduled_pipelines_data(data, date_string, threshold, excel_path, top_samples_threshold):
    # Check that the necessary metadata exists:
    headers = data.columns.values

    if not Metadata.QUERY_ID.value in headers:
        raise Exception(str(Metadata.QUERY_ID.value) + " is missing from the input data.")

    if not Metadata.GENOMIC_ADDRESS_NAME.value in headers:
        raise Exception(str(Metadata.GENOMIC_ADDRESS_NAME.value) + " is missing from the input data.")

    if not Metadata.NATIONAL_OUTBREAK_CODE.value in headers:
        raise Exception(str(Metadata.NATIONAL_OUTBREAK_CODE.value) + " is missing from the input data.")

    if not date_string:
        raise Exception("A date string was not provided.")

    if top_samples_threshold < 0:
        raise Exception("The number of closest samples to maintain must be a non-negative integer.")

    summaries = {}

    # Rename columns to remove spaces for upcoming .itertuples() call:
    data = rename_columns(data)

    for row in data.itertuples():
        query_id = getattr(row, Metadata.QUERY_ID_RENAME.value)

        if query_id not in summaries:
            summaries[query_id] = Summary(query_id, top_samples_threshold)

        summaries[query_id].process_row(row)

    summaries_data = []

    for query_id in summaries:
        summary = summaries[query_id]
        summaries_data.append((summary.query_id,
                               summary.get_closest_samples(),
                               summary.matched_samples,
                               summary.get_genomic_address_names(),
                               summary.get_national_outbreak_codes()))

    processed_data = pd.DataFrame.from_records(summaries_data,
                                               columns=[Metadata.QUERY_ID_RENAME.value,
                                                        Metadata.TOP_SAMPLES.value,
                                                        Metadata.MATCHED_SAMPLES_COUNT.value,
                                                        Metadata.TOP_GENOMIC_ADDRESS.value,
                                                        Metadata.CODE_MATCH.value])

    # Insert date:
    processed_data.insert(len(processed_data.columns),
                          Metadata.DATE.value, date_string)

    # Insert status:
    processed_data.insert(len(processed_data.columns),
                          Metadata.STATUS.value, Metadata.COMPLETED.value)

    # Insert threshold:
    processed_data.insert(len(processed_data.columns),
                          Metadata.THRESHOLD.value, threshold)

    # Insert results file location:
    processed_data.insert(len(processed_data.columns),
                          Metadata.RESULTS_FILENAME.value, excel_path)

    columns = [Metadata.QUERY_ID_RENAME.value,
               Metadata.STATUS.value,
               Metadata.TOP_SAMPLES.value,
               Metadata.MATCHED_SAMPLES_COUNT.value,
               Metadata.THRESHOLD.value,
               Metadata.DATE.value,
               Metadata.CODE_MATCH.value,
               Metadata.TOP_GENOMIC_ADDRESS.value,
               Metadata.RESULTS_FILENAME.value]

    processed_data = processed_data.reindex(columns=columns)

    return processed_data

def main(argv=None):

    parser = argparse.ArgumentParser(
        description="Parses a profile_dists distances to create query-reference-format output for the FastMatch pipeline.",
        epilog="Example: python process_output.py --input distances.tsv --output results --threshold 10",
    )

    parser.add_argument(
        "--input",
        action="store",
        dest="input",
        type=str,
        help="profile_dists-generated distance matrix",
        default=None,
        required=True,
    )

    parser.add_argument(
        "--threshold",
        action="store",
        dest="threshold",
        type=float,
        help="distance threshold to be included in output",
        default=None,
        required=True,
    )

    parser.add_argument(
        "--output",
        action="store",
        dest="output",
        type=str,
        help="The output path name (without extension). For example: 'results' -> 'results.tsv', 'results.xlsx'.",
        default=None,
        required=True,
    )

    parser.add_argument(
        "--scheduled",
        action="store_true",
        dest="scheduled",
        help="Whether or not the output should be in the scheduled pipelines output format."
    )

    parser.add_argument(
        "--date_string",
        action="store",
        dest="date_string",
        type=str,
        help="The date to report for each sample. Only used and required when running in scheduled pipelines mode.",
        default=""
    )

    parser.add_argument(
        "--prefix_string",
        action="store",
        dest="prefix_string",
        type=str,
        help="A prefix that will later be prepended by Nextflow to the output files. This prefix is NOT added to the file path in this program, but rather informs the eventual file path name reported by scheduled pipelines output.",
        default=""
    )

    parser.add_argument(
        "--top_samples_threshold",
        action="store",
        dest="top_samples_threshold",
        type=int,
        help="When running with the scheduled pipelines option enabled, this controls the number of closest samples to each query that are maintained and reported.",
        default=DEFAULT_NUM_CLOSEST_SAMPLES
    )

    args = parser.parse_args(argv)

    input = Path(args.input)
    threshold = args.threshold
    prefix_string = args.prefix_string
    date_string = args.date_string
    output_string = args.output
    top_samples_threshold = args.top_samples_threshold

    tsv_path = Path(output_string + ".tsv")
    excel_path = Path(output_string + ".xlsx")

    data = pd.read_csv(input, sep="\t")
    data = data[data['Distance'] <= threshold]

    if args.scheduled:
        scheduled_excel_path = prefix_string + output_string + ".xlsx"
        data = process_scheduled_pipelines_data(data, date_string, threshold, scheduled_excel_path, top_samples_threshold)

    data.to_csv(tsv_path, sep="\t", index=False)
    data.to_excel(excel_path, index=False)

    print("Output written to:")
    print(tsv_path)
    print(excel_path)

    return 0


if __name__ == "__main__":
    sys.exit(main())
