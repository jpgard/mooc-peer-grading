import os
import subprocess
import shutil
import pandas as pd


DATABASE_NAME = "course"


def execute_mysql_query_into_csv(query, file, database_name=DATABASE_NAME, delimiter=","):
    """
    Execute a mysql query into a file.
    :param query: valid mySQL query as string.
    :param file: csv filename to write to.
    :param database_name: name of database to use.
    :param delimiter: type of delimiter to use in file.
    :return: None
    """
    formatted_query = """{} INTO OUTFILE '{}' FIELDS TERMINATED BY '{}' ;""".format(query, file, delimiter)
    command = '''mysql -u root -proot {} -e"{}"'''.format(database_name, formatted_query)
    subprocess.call(command, shell=True)
    return


def load_mysql_dump(dumpfile, database_name=DATABASE_NAME):
    """
    Load a mySQL data dump into DATABASE_NAME.
    :param file: path to mysql database dump
    :return:
    """
    command = '''mysql -u root -proot {} < {}'''.format(database_name, dumpfile)
    subprocess.call(command, shell=True)
    return


def initialize_database(database_name=DATABASE_NAME):
    """
    Start mySQL service and initialize mySQL database with database_name.
    :param database_name: name of database.
    :return: None
    """
    # start mysql server
    subprocess.call("service mysql start", shell=True)
    # create database
    subprocess.call('''mysql -u root -proot -e "CREATE DATABASE {}"'''.format(database_name), shell=True)
    return


def extract_coursera_sql_data(course, session, outfile):
    """
    Initialize the mySQL database, load files, and execute queries to deposit csv files of data into /input/course/session directory.
    :param course: course name.
    :param session: session.
    :param outfile: name of csv file to write to.
    :return:
    """
    # paths for reading and writing results
    course_session_dir = os.path.join("/input", course, session)
    mysql_default_output_dir = "/var/lib/mysql/{}/".format(
        DATABASE_NAME)  # this is the only location mysql can write to
    outfile_temp_fp = os.path.join(mysql_default_output_dir, outfile)
    outfile_fp = os.path.join(course_session_dir, outfile)
    hash_mapping_sql_dump = \
        [x for x in os.listdir(course_session_dir) if "anonymized_general" in x and session in x][0] # contains users table
    initialize_database()
    load_mysql_dump(os.path.join(course_session_dir, hash_mapping_sql_dump))
    # execute forum comment query and send to csv
    query = """SELECT * FROM quiz_submission_metadata WHERE item_id IN (SELECT id FROM quiz_metadata WHERE quiz_type = 'quiz' AND deleted = 0 AND parent_id = -1) AND session_user_id IN (SELECT session_user_id FROM users WHERE access_group_id = 4)"""
    execute_mysql_query_into_csv(query, file=outfile_temp_fp)
    # move both files to intended location -- this is a hack but it works without needing to chance mysql permissions
    shutil.move(outfile_temp_fp, outfile_fp)
    return
