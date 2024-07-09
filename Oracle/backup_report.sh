#!/bin/bash

# LOGSDIR="{{ logsdir }}"
LOGSDIR=/tmp
HNAME=$(hostname -s)
HVERSION=$(uname -s)
SCRIPTNAME=ora_backup_info.sh
REPORT_FILE=${LOGSDIR}/${SCRIPTNAME}.final

if [[ -f ${REPORT_FILE} ]]; then rm -f ${REPORT_FILE}; fi
function main {
    cat /etc/oratab | grep -v "^#" | grep -v "^$" | awk -F ":" '{print $1" "$2" "$3}' | while read DBNAME ORAHOME ACTIVEFLAG
    do
        check_pmon_process ${DBNAME}
        if [[ "${ACTIVEFLAG}" == "Y" ]]; then
            export ORAENV_ASK=NO
            export ORACLE_SID=${DBNAME}
            export ORACLE_HOME=${ORAHOME}
            export PATH=${ORACLE_HOME}/bin:$PATH

            ## Check database role and log_mode
            OUTPUT=$(run_sql "select name, database_role,log_mode FROM v\$database;")
            DBROLE=$(echo ${OUTPUT} | awk '{print $2}')
            LOG_MODE=$(echo ${OUTPUT} | awk '{print $3}')

            if [[ "${DBROLE}" == "PRIMARY" || "${LOG_MODE}" == "ARCHIVELOG" ]]; then
                # echo "Database Name: ${DBNAME}"
                # echo "Database Role: ${DBROLE}"
                # echo "Database Log_Mode: ${LOG_MODE}"

                get_last_success_backup_info
                check_n_days_backup_info 2
                check_n_days_backup_info 7
                check_archive_failure
            else
                echo "STANDBY: ${HNAME}_${DBNAME}" >> ${REPORT_FILE}
            fi
        else
            echo "AUTO_FLAG_${ACTIVEFLAG}: ${HNAME}_${DBNAME}" >> ${REPORT_FILE}
        fi
    done
}

function run_sql {
    QUERY=$1
    sqlplus -s "/ as sysdba" << EOF
       set heading off feedback off verify off
       ${QUERY}
       exit
EOF
# echo ${OUTPUT}
}

function get_last_success_backup_info {
    NO_OF_BACKUPS_SQL="set linesize 500 pagesize 2000
                select count(*) from V\$RMAN_BACKUP_JOB_DETAILS where INPUT_TYPE in ('DB FULL','DB INCR') and STATUS='COMPLETED';"
    
    BACKUP_REPORT_SQL="set linesize 500 pagesize 2000
                COLUMN RMAN_BKUP_START_TIME FORMAT A24
                COLUMN host_name FORMAT A20
                COLUMN name FORMAT A15
                COLUMN RMAN_BKUP_END_TIME FORMAT A24
                COLUMN STATUS FORMAT A10
                select INPUT_TYPE, STATUS, to_char(START_TIME, 'DD-Mon-YYYY-HH24:MI:SS') as RMAN_Bkup_start_time, to_char(END_TIME, 'DD-Mon-YYYY-HH24:MI:SS') as RMAN_Bkup_end_time, elapsed_seconds/3600 Hours from V\$RMAN_BACKUP_JOB_DETAILS where INPUT_TYPE in ('DB FULL','DB INCR') and STATUS='COMPLETED' order by END_TIME desc fetch first 1 row only;"

    NO_OF_BACKUPS=$(run_sql "${NO_OF_BACKUPS_SQL}" | grep -v "^$" | awk '{print $1}')
    if [[ ${NO_OF_BACKUPS} -lt 1 ]]; then
        echo "LATEST_BACKUP: ${HNAME}_${DBNAME} - NO BACKUP FOUND" >> ${REPORT_FILE}
    else
        BACKUP_REPORT=$(run_sql "${BACKUP_REPORT_SQL}" | grep -v "^$")
        echo "LATEST_BACKUP: ${HNAME}_${DBNAME} - ${BACKUP_REPORT}" >> ${REPORT_FILE}
    fi
}

function check_n_days_backup_info {
    NOOFDAYS=$1
    NO_DAYS_BEFORE_BACKUPS_COUNT_SQL="set linesize 500 pagesize 2000
                select count(*) from V\$RMAN_BACKUP_JOB_DETAILS where INPUT_TYPE in ('DB FULL','DB INCR') and END_TIME > sysdate - ${NOOFDAYS} and STATUS='COMPLETED';"

                NO_DAYS_BEFORE_BACKUPS_COUNT=$(run_sql "${NO_DAYS_BEFORE_BACKUPS_COUNT_SQL}" | awk '{print $1}' | grep -v "^$")

                # echo "No of Backups Before ${NOOFDAYS} Days - ${BKPS_COUNT}"
                if [[ ${NO_DAYS_BEFORE_BACKUPS_COUNT} -lt 1 ]]; then
                    echo "NO_BACKUP_${NOOFDAYS}: ${HNAME}_${DBNAME}" >> ${REPORT_FILE}
                    get_last_success_backup_info
                fi
}

function check_archive_failure {
    NO_OF_ARCHIVE_FAILURE_COUNT_SQL="set linesize 500 pagesize 2000
                select count(*) from V\$RMAN_BACKUP_JOB_DETAILS where INPUT_TYPE in ('ARCHIVELOG') and STATUS != 'COMPLETED' and END_TIME > sysdate - 1;"
    
    ARCHIVE_FAILURE_REPORT_SQL="set linesize 500 pagesize 2000
                COLUMN RMAN_BKUP_START_TIME FORMAT A24
                COLUMN host_name FORMAT A20
                COLUMN name FORMAT A15
                COLUMN RMAN_BKUP_END_TIME FORMAT A24
                COLUMN STATUS FORMAT A10
                select INPUT_TYPE, STATUS, to_char(START_TIME, 'DD-Mon-YYYY-HH24:MI:SS') as RMAN_Bkup_start_time, to_char(END_TIME, 'DD-Mon-YYYY-HH24:MI:SS') as RMAN_Bkup_end_time, elapsed_seconds/3600 Hours from V\$RMAN_BACKUP_JOB_DETAILS where INPUT_TYPE in ('ARCHIVELOG') and STATUS !='COMPLETED' and END_TIME > sysdate - 1 order by END_TIME desc fetch first 1 row only;"

    NO_OF_ARCHIVE_FAILURE_COUNT=$(run_sql "${NO_OF_ARCHIVE_FAILURE_COUNT_SQL}" | grep -v "^$" | awk '{print $1}')

    ## No of Archive log failures > 1 get latest failed since last 24hours and add in report
    if [[ ${NO_OF_ARCHIVE_FAILURE_COUNT} -gt 0 ]]; then
        ARCHIVE_FAILURE_REPORT=$(run_sql "${ARCHIVE_FAILURE_REPORT_SQL}" | grep -v "^$")
        echo "ARCHIVE_FAILURE: ${HNAME}_${DBNAME} - ${ARCHIVE_FAILURE_REPORT}" >> ${REPORT_FILE}
    fi
}

function check_pmon_process {
    DBNAME=$1
    PRC_CNT=$(ps -ef | grep -v grep | grep -i pmon | grep -i ${DBNAME} | wc -l)

    if [[ ${PRC_CNT} -eq 0 ]]; then
        echo "NO_PMON: ${HNAME}_${DBNAME}" >> ${REPORT_FILE}
    fi
}

main

cat ${REPORT_FILE} | sort -n | sort -u

# select t1.host_name,t2.name,t3.INPUT_TYPE, t3.STATUS, to_char(t3.START_TIME, 'DD-Mon-YYYY-HH24:MI:SS') as RMAN_Bkup_start_time, to_char(t3.END_TIME, 'DD-Mon-YYYY-HH24:MI:SS') as RMAN_Bkup_end_time, t3.elapsed_seconds/3600 Hours from V\$RMAN_BACKUP_JOB_DETAILS t3,v\$instance t1,V\$Database t2 where INPUT_TYPE in ('DB FULL','DB INCR','ARCHIVELOG' ) order by session_key fetch first 1 row only;"