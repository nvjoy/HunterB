#!/bin/bash

# Oracle Database Connection Details
ORACLE_USER="your_username"
ORACLE_PASSWORD="your_password"
ORACLE_SID="your_database_sid"

# Output File
REPORT_FILE="backup_report.txt"

# Get current date and time
CURRENT_DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Connect to the Oracle database and fetch backup information
BACKUP_INFO=$(sqlplus / as sysdba <<EOF
set feedback off
set linesize 200
set pagesize 1000
col START_TIME format a20
col END_TIME format a20
col STATUS format a10
spool ${REPORT_FILE}
SELECT START_TIME, END_TIME, STATUS, INPUT_BYTES/1024/1024 as INPUT_MB, OUTPUT_BYTES/1024/1024 as OUTPUT_MB
FROM V$RMAN_BACKUP_JOB_DETAILS
ORDER BY START_TIME DESC;
spool off
exit;
EOF
)

# Create the report header
echo "Oracle Database Backup Report" > ${REPORT_FILE}
echo "Generated on: ${CURRENT_DATE}" >> ${REPORT_FILE}
echo "" >> ${REPORT_FILE}

# Append the backup information to the report
echo "${BACKUP_INFO}" >> ${REPORT_FILE}

echo "Backup report generated: ${REPORT_FILE}"


[Monday 12:54 PM] Sampath Natarajan

database_role it will display as PRIMARY [or] Stand By

[Monday 12:54 PM] Sampath Natarajan

1st Check DB is active or not   i.e. etc ora tab comented or not

[Monday 12:55 PM] Sampath Natarajan

2nd Check whether DB restart Status as Y or N

[Monday 12:55 PM] Sampath Natarajan

last column of etc ora tab is Y or N

[Monday 12:55 PM] Sampath Natarajan

3 rd check database_role for Primary or Stand by

[Monday 12:56 PM] Sampath Natarajan

4th Check DB in Arhive log mode or NOT

[Monday 12:56 PM] Sampath Natarajan

Use the above hierarchy for logic



set linesize 500 pagesize 2000
COLUMN RMAN_BKUP_START_TIME FORMAT A24
COLUMN RMAN_BKUP_END_TIME FORMAT A24
COLUMN STATUS FORMAT A10
select $(hosname -s) as HOST,INPUT_TYPE, STATUS, to_char(START_TIME, 'Dy DD-Mon-YYYY HH24:MI:SS') as RMAN_Bkup_start_time, to_char(END_TIME, 'Dy DD-Mon-YYYY HH24:MI:SS') as RMAN_Bkup_end_time, elapsed_seconds/3600 Hours from V$RMAN_BACKUP_JOB_DETAILS where INPUT_TYPE in ('DB FULL','DB INCR','ARCHIVELOG' ) order by session_key;