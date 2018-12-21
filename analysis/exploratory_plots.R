source("read_data.R")
# number of peer-graded assignment submissions in each course
peer_evaluations %>%
    dplyr::mutate(course_session = factor(course_session)) %>%
    group_by(course_session) %>%
    tally() %>%
    ggplot(aes(x = reorder(course_session, n), y = n)) + 
    geom_bar(stat = "identity") + 
    coord_flip() + 
    ggtitle("Peer Evaluation Counts By Course-Session") + 
    scale_y_continuous(labels = comma) +
    theme_bw()

peer_evaluations %>%
    group_by(course) %>%
    tally() %>%
    ggplot(aes(x = reorder(course, n), y = n)) + 
    geom_bar(stat = "identity") + 
    coord_flip() + 
    ggtitle("Peer Evaluation Counts By Course") + 
    scale_y_continuous(labels = comma) +
    theme_bw()

peer_evaluations %>%
    group_by(course, anon_user_id) %>%
    tally() %>% 
    ggplot(aes(x =n, fill = course)) + 
    geom_density() + 
    xlim(0,50) + 
    guides(fill = FALSE) + 
    ggtitle("Number of Peer Assessments Conducted Per User") + 
    facet_wrap(course ~ .) + 
    theme_bw()

peer_evaluations %>% 
    group_by(course_session, submission_id) %>% tally() %>% 
    ggplot(aes(x = n)) + 
    geom_histogram() + 
    xlim(0,15) +
    xlab("Number of Unique Peer Assessments") + 
    ggtitle("Number of Peer Assessments Per Assignment") +
    theme_bw()

# peer grades vs. self grades
dplyr::filter(overall_evaluations, self_grade != "N") %>%
    ggplot(aes(x = peer_grade, y = self_grade, color = course)) + 
    geom_jitter(alpha = 0.3, size = rel(0.3)) + 
    ggtitle("Correlation: Peer Grades vs. Self Grades") + 
    guides(color = F) + 
    facet_wrap(course ~ .) + 
    theme_bw()

overall_evaluations %>% 
    ggplot(aes(x = self_grade - peer_grade)) + 
    geom_density() +
    ggtitle("Difference Between Self and Peer Grade") + 
    xlim(-5, 5) +
    facet_wrap(course ~ .) + 
    theme_bw()

# peer grades vs. staff grades (NOT: this is only available for one MOOC!)
overall_evaluations[!is.na(overall_evaluations$staff_grade) & !(is.na(overall_evaluations$peer_grade)),] %>%
    ggplot(aes(x = staff_grade, y = peer_grade, color = course_session)) + 
    geom_jitter() + 
    ggtitle("Staff Grades vs. Peer Grades (Note: Some Data May Be Staff-Generated") + 
    theme_bw()

overall_evaluations %>%
    dplyr::inner_join(submissions, by = c("submission_id" = "id", "course_session" = "course_session")) %>% # NOTE: submission and assessment IDs get reused across courses! so, need to join on course/session too
    group_by(course_session, assessment_id) %>%
    summarise(peer_grade_variance = var(peer_grade, na.rm = TRUE), total.count = n()) %>% # this is variance of final "peer grade" by assignment
    dplyr::filter(total.count >= SUBMISSION_THRESHOLD) %>%
    ggplot(aes(x=assessment_id, y = course_session, fill = log(peer_grade_variance), label = total.count)) + 
    geom_tile() +
    geom_text(size = rel(2)) +
    scale_fill_gradient(low = "white", high = "black") +
    ggtitle("Variance of Peer Grades By Assignment") + 
    theme_bw()

