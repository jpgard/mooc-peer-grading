"""
a utility script to extract peer grading data from MORF
"""
from feature_extraction.sql_utils import *
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="execute feature extraction, training, or testing.")
    parser.add_argument("-c", "--course", required=False,
                        help="course slug")
    parser.add_argument("-r", "--session", required=False,
                        help="3-digit course session identifier")
    parser.add_argument("-m", "--mode", required=True, help="mode to run image in; {extract, train, test}")
    args = parser.parse_args()
    if args.mode == "extract":
        # this block expects individual session-level data mounted by extract_session() and outputs one CSV file per session in /output
        # generate forum post CSV files for each session and aggregate into single file
        extract_coursera_sql_data(args.course, args.session)
    else:  # this script should not be called in any other mode
        raise NotImplementedError("this script is only for extraction")
