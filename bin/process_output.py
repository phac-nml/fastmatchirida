#!/usr/bin/env python

from pathlib import Path
from mimetypes import guess_type
from functools import partial
from enum import Enum
import gzip
import sys
import argparse
import pandas as pd

class Metadata(Enum):
    # Input
    GENOMIC_ADDRESS_NAME = "genomic_address_name"
    NATIONAL_OUTBREAK_CODE = "national_outbreak_code"

    # Output
    STATUS = "fastmatch_status"
    TOP_SAMPLES = "fastmatch_top_samples"
    MATCHED_SAMPLES_COUNT = "fastmatch_matched_samples_count"
    THRESHOLD = "fastmatch_threshold"
    DATE = "fastmatch_date"
    CODE_MATCH = "fastmatch_code_match"
    TOP_GENOMIC_ADDRESS = "fastmatch_top_genomic_address"
    RESULTS_FILENAME = "fastmatch_results_filename"

def get_open(f):
    if "gzip" == guess_type(str(f))[1]:
        return partial(gzip.open)
    else:
        return open

def process_scheduled_pipelines_data(data, date_string):
    # Check that the necessary metadata exists:
    headers = data.columns.values

    if not Metadata.GENOMIC_ADDRESS_NAME.value in headers:
        raise Exception(str(Metadata.GENOMIC_ADDRESS_NAME.value) + " is missing from the input data.")

    if not Metadata.NATIONAL_OUTBREAK_CODE.value in headers:
        raise Exception(str(Metadata.NATIONAL_OUTBREAK_CODE.value) + " is missing from the input data.")

    if not date_string:
        raise Exception("A date string was not provided.")

    # Insert date:
    data.insert(len(data.columns), Metadata.DATE.value, date_string)

    return data

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
        data = process_scheduled_pipelines_data(data, date_string)

    data.to_csv(tsv_path, sep="\t", index=False)
    data.to_excel(excel_path, index=False)

    print("Output written to:")
    print(tsv_path)
    print(excel_path)

    return 0


if __name__ == "__main__":
    sys.exit(main())
