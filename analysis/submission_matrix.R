source("read_data.R")


make_submission_matrix <- function(course_in, session_in, submissions_df, peer_evaluations_df, assessment_id_in){
    course_session_submissions_df = dplyr::filter(submissions_df, course == course_in, session == session_in)
    course_session_peer_evaluations_df = dplyr::filter(peer_evaluations_df, course == course_in, session == session_in, author_group == "student")
    most_recent_submits = course_session_submissions_df %>% group_by(author_id, assessment_id) %>% summarise(max_submission_submit_time = max(submit_time))
    message(glue("creating submission for course {course} session {session} assessment_id {assessment_id_in}, this may take a while..."))
    df = course_session_peer_evaluations_df %>% 
        dplyr::inner_join(course_session_submissions_df, by = c("course_session" = "course_session", "submission_id" = "id"), suffix = c("_peer", "_submission")) %>%
        dplyr::inner_join(most_recent_submits, by = c("author_id" = "author_id", "assessment_id" = "assessment_id")) %>%
        dplyr::filter(included_in_grading == 1, submit_time_submission == max_submission_submit_time, assessment_id == assessment_id_in, grade != "N") %>%
        dplyr::select(c("anon_user_id", "author_id", "grade")) %>%
        tidyr::spread(key = author_id, value = grade, fill = NA)
    return(df)
}

## sample usage
assessment_7_submission_matrix = make_submission_matrix("gamification", "2012-001", submissions, peer_evaluations, 7)
