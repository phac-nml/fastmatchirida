#!/usr/bin/env python

import json
import argparse
import csv
import gzip
import sys


def open_file(file_path, mode):
    # Open a file based on the file extension
    if file_path.endswith(".gz"):
        return gzip.open(file_path, mode)
    else:
        return open(file_path, mode)


def check_inputs(json_file, sample_id, address, output_error_file, output_json_file):
    with open_file(json_file, "rt") as f:
        json_data = json.load(f)

    # Extract the profile from the json_data
    profile = json_data.get("data", {}).get("profile", {})
    # Check for multiple keys in the JSON file and define error message
    keys = sorted(profile.keys())
    original_key = keys[0] if keys else None

    # Define a variable to store the match_status (True or False)
    match_status = sample_id in profile

    # Initialize the error message
    error_message = None

    if not keys:
        error_message = (
            f"{json_file} is missing the 'profile' section or is completely empty!"
        )
        print(error_message)
        sys.exit(1)
    elif len(keys) > 1:
        # Check if sample_id matches any key
        if not match_status:
            error_message = f"No key in the MLST JSON file ({json_file}) matches the specified sample ID '{sample_id}'. The first key '{original_key}' has been forcefully changed to '{sample_id}' and all other keys have been removed."
            # Retain only the specified sample ID
            json_data["data"]["profile"] = {sample_id: profile.pop(original_key)}
        else:
            error_message = f"MLST JSON file ({json_file}) contains multiple keys: {keys}. The MLST JSON file has been modified to retain only the '{sample_id}' entry"
            # Retain only the specified sample_id in the profile
            json_data["data"]["profile"] = {sample_id: profile[sample_id]}
    elif not match_status:
        # Define error message based on meta.address (query or reference)
        if address == "null":
            error_message = f"Query {sample_id} ID and JSON key in {json_file} DO NOT MATCH. The '{original_key}' key in {json_file} has been forcefully changed to '{sample_id}': User should manually check input files to ensure correctness."
        else:
            error_message = f"Reference {sample_id} ID and JSON key in {json_file} DO NOT MATCH. The '{original_key}' key in {json_file} has been forcefully changed to '{sample_id}': User should manually check input files to ensure correctness."
        # Update the JSON file with the new sample ID
        json_data["data"]["profile"] = {sample_id: profile.pop(original_key)}
        json_data["data"]["sample_name"] = sample_id

    # Write file containing relevant error messages
    if error_message:
        with open(output_error_file, "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["sample", "JSON_key", "error_message"])
            writer.writerow([sample_id, keys, error_message])

    # Write the updated JSON data back to the original file
    with gzip.open(output_json_file, "wt") as f:
        json.dump(json_data, f, indent=4)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Check sample inputs, force change if ID ≠ KEY, and generate an error report."
    )
    parser.add_argument("--input", help="Path to the mlst.json file.", required=True)
    parser.add_argument(
        "--sample_id", help="Sample ID to check in the JSON file.", required=True
    )
    parser.add_argument(
        "--address", help="Address to use in the error message.", required=True
    )
    parser.add_argument(
        "--output_error", help="Path to the error report file.", required=True
    )
    parser.add_argument(
        "--output_json", help="Path to the MLST JSON file (gzipped).", required=True
    )

    args = parser.parse_args()

    check_inputs(
        args.input, args.sample_id, args.address, args.output_error, args.output_json
    )
