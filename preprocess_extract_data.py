"""
Script to unzip peer assessment data and add headers to csv files by iterating through directory and unzipping files.
"""
import argparse
import os
import pandas as pd
from morf.utils import unarchive_file
import re

JOB_ID = "mooc_peer_grading"
TABLE_HEADERS = {
    "hg_assessment_calibration_gradings": ["id", "item_number", "calibration_set_id", "evaluation_id", "type",
                                           "submit_time"],
    "hg_assessment_evaluation_metadata": ["id", "anon_user_id", "author_group", "submission_id",
                                          "start_time", "save_time", "submit_time", "grade", "ignore"],
    "hg_assessment_metadata": ["id", "session_user_id", "open_time", "submission_deadline",
                               "submission_deadline_grace_period", "grading_start", "grading_deadline",
                               "grading_deadline_grace_period", "display_grades_time", "title",
                               "max_grade", "last_updated", "published", "deleted"],
    "hg_assessment_overall_evaluation_metadata": ["id", "submission_id", "grade", "final_grade",
                                                  "staff_grade", "peer_grade", "self_grade"],
    "hg_assessment_peer_grading_metadata": ["id", "item_number", "peer_grading_set_id", "evaluation_id", "submit_time",
                                            "required", "last_required"],
    "hg_assessment_peer_grading_set_metadata": ["id", "anon_user_id", "assessment_id", "start_time", "finish_time",
                                                "status"],
    "hg_assessment_self_grading_set_metadata": ["id", "anon_user_id", "assessment_id", "start_time", "finish_time",
                                                "status"],
    "hg_assessment_submission_metadata": ["id", "author_id", "title", "assessment_id",
                                          "included_in_training", "included_in_grading",
                                          "included_in_ground_truth", "excluded_from_circulation",
                                          "anonymized_if_showcased", "blank", "start_time", "save_time",
                                          "submit_time", "allocation_score", "authenticated_submission_id", "ignore_grade_adjustments"],
    "hg_assessment_training_metadata": ["id", "item_number", "training_set_id", "evaluation_id", "submit_time"],
    "hg_assessment_training_set_metadata": ["id", "anon_user_id", "assessment_id", "start_time", "finish_time",
                                            "status"]
}

parser = argparse.ArgumentParser(description="execute feature extraction, training, or testing.")
parser.add_argument("--extract_dir", help="directory containing course/session/*.tgz files")
args = parser.parse_args()
if __name__ == "__main__":
    for dirpath, dirnames, filenames in os.walk(args.extract_dir):
        for f in filenames:
            if f.endswith(".tgz") and JOB_ID in f:
                archive_fp = os.path.join(dirpath, f)
                unarchive_file(archive_fp, dirpath, remove=False)
                for extract_file in os.listdir(dirpath):
                    if extract_file.startswith("hg_assessment") and extract_file.endswith(".csv"):
                        tablename = extract_file.split(".")[0]
                        print("[INFO] processing {}".format(extract_file))
                        csv_fp = os.path.join(dirpath, extract_file)
                        if os.stat(csv_fp).st_size == 0:
                            print("[INFO] file is empty: {}".format(csv_fp))
                        else:
                            try:
                                df = pd.read_csv(csv_fp, dtype=object, escapechar="\\", na_values="\\N", encoding="utf-8")
                                assert len(TABLE_HEADERS[tablename]) == df.shape[
                                    1], "mismatch between table headers and csv file dimensions"
                                df.columns = TABLE_HEADERS[tablename]
                                df.to_csv(csv_fp, index=False)
                            except Exception as e:
                                import ipdb;ipdb.set_trace()
                                print("[ERROR] exception processing file {}: {}".format(extract_file, e))
