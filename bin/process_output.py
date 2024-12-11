#!/usr/bin/env python

from pathlib import Path
from mimetypes import guess_type
from functools import partial
import gzip
import sys
import argparse


def get_open(f):
    if "gzip" == guess_type(str(f))[1]:
        return partial(gzip.open)
    else:
        return open

def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Parses a profile_dists distances to create query-reference-format output for the FastMatch pipeline.",
        epilog="Example: python process_output.py --input matrix.csv",
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

    headers = ["query", "reference", "distance"]
    results = [["A", "B", "1"], ["C", "D", "2"], ["E", "F", "3"]]

    with open(output, "w") as output_file:
        output_file.write((",").join(headers) + "\n")

        for line in results:
            output_file.write((",").join(line) + "\n")

    print(f"Output written to [{output}]")

    return 0


if __name__ == "__main__":
    sys.exit(main())
