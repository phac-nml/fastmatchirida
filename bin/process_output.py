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
        type=int,
        help="distance threshold to be included in output",
        default=None,
        required=True,
    )

    parser.add_argument(
        "--output",
        action="store",
        dest="output",
        type=str,
        help="output in query-reference format",
        default=None,
        required=True,
    )

    args = parser.parse_args(argv)

    input = Path(args.input)
    output = Path(args.output)
    threshold = args.threshold

    data = pd.read_csv(input, sep="\t")
    data = data[data['Distance'] <= threshold]
    data.to_csv(output, sep="\t", index=False)

    print(f"Output written to [{output}]")

    return 0


if __name__ == "__main__":
    sys.exit(main())
