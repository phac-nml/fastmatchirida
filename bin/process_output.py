#!/usr/bin/env python

from pathlib import Path
from mimetypes import guess_type
from functools import partial
import gzip
import sys
import argparse
import pandas as pd


def get_open(f):
    if "gzip" == guess_type(str(f))[1]:
        return partial(gzip.open)
    else:
        return open

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

    args = parser.parse_args(argv)

    input = Path(args.input)
    tsv_path = Path(args.output + ".tsv")
    excel_path = Path(args.output + ".xlsx")
    threshold = args.threshold

    data = pd.read_csv(input, sep="\t")
    data = data[data['Distance'] <= threshold]
    data.to_csv(tsv_path, sep="\t", index=False)
    data.to_excel(excel_path)

    print("Output written to:")
    print(tsv_path)
    print(excel_path)

    return 0


if __name__ == "__main__":
    sys.exit(main())
