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

NUM_CLOSEST_SAMPLES = 5

class Metadata(Enum):
    # Input
    QUERY_ID = "Query ID"
    REFERENCE_ID = "Reference ID"
    GENOMIC_ADDRESS_NAME = "genomic_address_name"
    NATIONAL_OUTBREAK_CODE = "national_outbreak_code"
    DISTANCE = "Distance"

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

    def __init__(self, query_id):
        self.query_id = query_id
        self.genomic_address_names = []
        self.national_outbreak_codes = []
        self.closest_samples = []
        self.matched_samples = 0

    def add_genomic_address_name(self, genomic_address_name):
        if genomic_address_name not in self.genomic_address_names:
            self.genomic_address_names.append(str(genomic_address_name))

    def add_national_outbreak_code(self, national_outbreak_code):
        if national_outbreak_code not in self.national_outbreak_codes:
            self.national_outbreak_codes.append(str(national_outbreak_code))

    def maintain_closest_samples(self, reference_id, distance):
        sample = (reference_id, distance)
        bisect.insort(self.closest_samples, sample, key=lambda sample: sample[1])
        self.closest_samples = self.closest_samples[:NUM_CLOSEST_SAMPLES]

    def add_row(self, row):
        genomic_address_name = row[Metadata.GENOMIC_ADDRESS_NAME.value]
        national_outbreak_code = row[Metadata.NATIONAL_OUTBREAK_CODE.value]
        reference_id = row[Metadata.REFERENCE_ID.value]
        distance = row[Metadata.DISTANCE.value]

        self.matched_samples += 1

        self.add_genomic_address_name(genomic_address_name)
        self.add_national_outbreak_code(national_outbreak_code)
        self.maintain_closest_samples(reference_id, distance)

    def get_genomic_address_names(self):
        return ",".join(self.genomic_address_names)

    def get_national_outbreak_codes(self):
        return ",".join(self.national_outbreak_codes)

    def get_closest_samples(self):
        closest = [str(x[0]) for x in self.closest_samples]
        return ",".join(closest)

def get_open(f):
    if "gzip" == guess_type(str(f))[1]:
        return partial(gzip.open)
    else:
        return open

def process_scheduled_pipelines_data(data, date_string, threshold, excel_path):
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

    summaries = {}

    for index, row in data.iterrows():
        query_id = row[Metadata.QUERY_ID.value]

        if query_id not in summaries:
            summaries[query_id] = Summary(query_id)

        summaries[query_id].add_row(row)

    summaries_data = []

    for query_id in summaries:
        summary = summaries[query_id]
        summaries_data.append((summary.query_id,
                               summary.get_closest_samples(),
                               summary.matched_samples,
                               summary.get_genomic_address_names(),
                               summary.get_national_outbreak_codes()))

    df = pd.DataFrame.from_records(summaries_data,
                                   columns=[Metadata.QUERY_ID.value,
                                            Metadata.TOP_SAMPLES.value,
                                            Metadata.MATCHED_SAMPLES_COUNT.value,
                                            Metadata.TOP_GENOMIC_ADDRESS.value,
                                            Metadata.CODE_MATCH.value])

    # Insert date:
    df.insert(len(df.columns), Metadata.DATE.value, date_string)

    # Insert status:
    df.insert(len(df.columns), Metadata.STATUS.value, Metadata.COMPLETED.value)

    # Insert threshold:
    df.insert(len(df.columns), Metadata.THRESHOLD.value, threshold)

    # Insert results file location:
    df.insert(len(df.columns), Metadata.RESULTS_FILENAME.value, excel_path)

    print(df)

    return df

def main(argv=None):

    parser = argparse.ArgumentParser(
        description="Parses a profile_dists distances to create query-reference-format output for the FastMatch pipeline.",
        epilog="Example: python process_output.py --input distances.tsv --output results.tsv --threshold 10",
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
        help="output prefix (without extension)",
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
        default=None
    )

    args = parser.parse_args(argv)

    input = Path(args.input)
    tsv_path = Path(args.output + ".tsv")
    excel_path = Path(args.output + ".xlsx")
    threshold = args.threshold
    date_string = args.date_string

    data = pd.read_csv(input, sep="\t")
    data = data[data['Distance'] <= threshold]

    if args.scheduled:
        data = process_scheduled_pipelines_data(data, date_string, threshold, excel_path)

    data.to_csv(tsv_path, sep="\t", index=False)
    data.to_excel(excel_path, index=False)

    print("Output written to:")
    print(tsv_path)
    print(excel_path)

    return 0


if __name__ == "__main__":
    sys.exit(main())
