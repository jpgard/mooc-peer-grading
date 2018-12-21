library(tidyverse)
library(magrittr)
library(glue)
library(scales)

# read in data
data_dir = "/Users/joshgardner/Documents/Github/mooc-peer-grading/temp/extract"

SUBMISSION_THRESHOLD = 50 # when plotting, only use assignments with at least this many submissions

## read in all data
hg_data = list()
course_sessions = list()
for (course in list.dirs(data_dir, full.names = FALSE, recursive = FALSE)){
    for (session in list.dirs(file.path(data_dir, course), full.names = FALSE, recursive = FALSE)){
        course_sessions[[course]] = c(course_sessions[[course]], session)
        message(glue("[INFO] processing course {course} session {session}"))
        for (fname in list.files(path = file.path(data_dir, course, session), pattern = "hg_assessment_.*\\.csv$")){
            fp = file.path(data_dir, course, session, fname)
            if (file.info(fp)$size > 0){ # only try to read non-empty files
                tablename = stringr::str_match(fname, "hg_assessment_(.*)\\.csv$")[2]
                df = read.csv(fp)
                hg_data[[paste(course, session, tablename, sep="_")]] = df
            } else {
                message(glue("[INFO] skipping empty file {fp}"))
            }
        }
    }
}

## concatenate individual tables across courses/sessions

# wrangle peer evaluation data
peer_evaluations = list()
for (submission_table in names(hg_data)){
    # only take hg_assessment_evaluation_metadata tables
    if (grepl("evaluation_metadata", submission_table, fixed=TRUE) & !grepl("overall_evaluation_metadata", submission_table, fixed=TRUE)){
        course = str_split(submission_table, pattern = "_", simplify = TRUE)[1]
        session = str_split(submission_table, pattern = "_", simplify = TRUE)[2]
        message(glue("adding evaluation metadata for course {course} session {session}"))
        peer_evaluations[[paste(course, session, sep = "_")]] = hg_data[[submission_table]]
    }
}
peer_evaluations %<>% dplyr::bind_rows(.id = "course_session") %>% tidyr::separate(col = "course_session", into = c("course", "session"), sep = "_", remove = FALSE)     

# wrangle overall evaluation data
overall_evaluations = list()
for (submission_table in names(hg_data)){
    # only take hg_assessment_evaluation_metadata tables
    if (grepl("overall_evaluation_metadata", submission_table, fixed=TRUE)){
        course = str_split(submission_table, pattern = "_", simplify = TRUE)[1]
        session = str_split(submission_table, pattern = "_", simplify = TRUE)[2]
        message(glue("adding overall evaluation metadata for course {course} session {session}"))
        overall_evaluations[[paste(course, session, sep = "_")]] = hg_data[[submission_table]]
    }
}
overall_evaluations %<>% 
    dplyr::bind_rows(.id = "course_session") %>% 
    tidyr::separate(col = "course_session", into = c("course", "session"), sep = "_", remove = FALSE) %>% 
    dplyr::mutate_at(vars(grade:self_grade), as.numeric)    

# wrangle assessment submission metadata
submissions = list()
for (submission_table in names(hg_data)){
    # only take hg_assessment_evaluation_metadata tables
    if (grepl("submission_metadata", submission_table, fixed=TRUE)){
        course = str_split(submission_table, pattern = "_", simplify = TRUE)[1]
        session = str_split(submission_table, pattern = "_", simplify = TRUE)[2]
        message(glue("adding submission metadata for course {course} session {session}"))
        df = hg_data[[submission_table]] %>% mutate(submit_time = as.character(submit_time)) # handle special case of submit time; inconsistent dtype
        submissions[[paste(course, session, sep = "_")]] = df
    }
}

submissions %<>% 
    dplyr::bind_rows(.id = "course_session") %>% 
    tidyr::separate(col = "course_session", into = c("course", "session"), sep = "_", remove = FALSE) 


