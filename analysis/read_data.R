library(tidyverse)
library(magrittr)
library(glue)
library(scales)

# read in data
data_dir = "/Users/joshgardner/Documents/Github/mooc-peer-grading/temp/extract"

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

#todo: number of peer-graded assignment submissions in each course
peer_evaluations %>%
    dplyr::mutate(course_session = factor(course_session)) %>%
    group_by(course_session) %>%
    tally() %>%
    ggplot(aes(x = reorder(course_session, n), y = n)) + 
    geom_bar(stat = "identity") + 
    coord_flip() + 
    ggtitle("Peer Evaluation Counts By Course-Session") + 
    scale_y_continuous(labels = comma)
peer_evaluations %>%
    group_by(course) %>%
    tally() %>%
    ggplot(aes(x = reorder(course, n), y = n)) + 
    geom_bar(stat = "identity") + 
    coord_flip() + 
    ggtitle("Peer Evaluation Counts By Course") + 
    scale_y_continuous(labels = comma)
peer_evaluations %>%
    group_by(course, anon_user_id) %>%
    tally() %>% 
    ggplot(aes(x =n, fill = course)) + geom_density() + xlim(0,50) + guides(fill = FALSE) + ggtitle("Number of Peer Assessments Conducted Per User") + facet_wrap(course ~ .)

# todo: peer grades vs. self grades
dplyr::filter(overall_evaluations, self_grade != "N") %>%
    ggplot(aes(x = peer_grade, y = self_grade, color = course)) + 
    geom_jitter(alpha = 0.3, size = rel(0.3)) + 
    ggtitle("Peer Grades vs. Self Grades") + 
    guides(color = F) + 
    facet_wrap(course ~ .)

overall_evaluations %>% 
    ggplot(aes(x = self_grade - peer_grade)) + 
    geom_density() +
    ggtitle("Difference Between Self and Peer Grade") + 
    xlim(-5, 5) +
    facet_wrap(course ~ .)

# todo: variance in peer grades by assignment

submission_id_assessment_id = dplyr::select(submissions, c("id", "assessment_id")) %>% unique()

overall_evaluations %>%
    # dplyr::inner_join(submission_id_assessment_id, by = c("submission_id" = "id")) %>%
    group_by(course_session) %>%
    summarise(peer_grade_variance = var(peer_grade, na.rm = TRUE), total.count = n()) %>% # this is variance of final "peer grade" by assignment
    ggplot(aes(x=peer_grade_variance, y = 0, fill = peer_grade_variance, size = total.count, label = course_session)) + 
    geom_point() + 
    geom_text(size=2) +
    ggtitle("Variance of Peer Grades")



