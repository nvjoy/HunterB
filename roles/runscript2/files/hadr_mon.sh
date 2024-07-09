#!/bin/bash
# Script Name: hadr_mon.sh
# Description: This script will insert a row and monitor hadr.
# Arguments: DBNAME (Run as Instance)
# Date: Aug, 2022

function main {
    run_db2_profile
    get_vars
    list_dbs
    create_tab_insert
    mon_hadr
}

function get_vars {
    TIMESTAMP=$(date +%y%m%d%H%M)
    DB2INST=$(whoami)
    MONSCH=METRICS
    MONTAB=HADR_MON
    HVERSION=$(uname -s)
    LOGFILE=/tmp/hadr_mon_${DB2INST}_${TIMESTAMP}.log

    if [[ -z "$1" ]]; then
        list_dbs
    else
        echo "$1" > /tmp/${DB2INST}.db.lst
    fi
}

function log {
    echo "" | tee -a ${LOGFILE}
    echo "@ $(date +"%Y-%m-%d %H:%M:%S") - "$1 | tee -a ${LOGFILE}
}

function run_db2_profile {
    if [[ -f $HOME/sqllib/db2profile ]]; then
        . $HOME/sqllib/db2profile
    fi
}

function list_dbs {
    run_db2_profile
    if [[ "${HVERSION}" == "AIX" ]]; then
        db2 list db directory | grep -ip indirect | grep -i "database name" | awk '{print $4}' | sort -u > /tmp/${DB2INST}.db.lst
    elif [[ "${HVERSION}" == "Linux" ]]; then
        db2 list db directory | grep -B6 -i indirect | grep -i "database name" | awk '{print $4}' | sort -u > /tmp/${DB2INST}.db.lst
    fi

    chmod 666 /tmp/${DB2INST}.db.lst
}

function create_tab_insert {
        
    while read DBNAME
    do
        DBROLE=$(db2 get db cfg for ${DBNAME} | grep -i "HADR database role" | cut -d "=" -f2 | awk '{print $1}')
        if [[ "${DBROLE}" == "PRIMARY" ]]; then
            log "Create table if not exist - ${DBNAME}"
            db2 -v "connect to ${DBNAME}" | tee -a ${LOGFILE} 2>&1
            if [[ $? -ne 0 ]]; then log "Not able to connect DB - ${DBNAME}, Please check!";exit 1; fi
            TABCHK=$(db2 -x "connect to ${DBNAME}" > /dev/null;db2 -x "select count(*) from syscat.tables where tabschema='${MONSCH}' and tabname='${MONTAB}' with ur" | awk '{print $1}')
            echo ${TABCHK}
            if [[ ${TABCHK} -eq 0 ]]; then
                log "Creating ${MONSCH}.${MONTAB} Table"
                db2 -v "create table ${MONSCH}.${MONTAB} as (select * from table(MON_GET_HADR(NULL))) with no data" | tee -a ${LOGFILE}
                db2 -v "alter table ${MONSCH}.${MONTAB} add column ROW_INSERT_TIMESTAMP TIMESTAMP NOT NULL IMPLICITLY HIDDEN WITH DEFAULT CURRENT TIMESTAMP" | tee -a ${LOGFILE}
                log "Inserting data to ${MONSCH}.${MONTAB} Table"
                echo "" | tee -a ${LOGFILE}
                db2 -v -m "insert into ${MONSCH}.${MONTAB} select * from table(MON_GET_HADR(NULL))" | tee -a ${LOGFILE}
                #db2 -x "select * from ${MONSCH}.${MONTAB} fetch first 15 rows only" > /tmp/monhadr.txt
                db2 -x "select HADR_ROLE,HADR_SYNCMODE,HADR_STATE,HADR_CONNECT_STATUS,HADR_CONNECT_STATUS_TIME,LOG_HADR_WAIT_CUR,HADR_LOG_GAP,STANDBY_RECV_REPLAY_GAP,STANDBY_RECV_BUF_PERCENT,STANDBY_RECV_BUF_PERCENT,HADR_LAST_TAKEOVER_TIME,ROW_INSERT_TIMESTAMP from METRICS.HADR_MON" > /tmp/monhadr.txt

                log "Deleting data from ${MONSCH}.${MONTAB} Table which is older than 30 Days"
                echo "" | tee -a ${LOGFILE}
                db2 -v "delete from METRICS.HADR_MON where date(ROW_INSERT_TIMESTAMP) < current date - 30 days" | tee -a ${LOGFILE}
            else
                log "Inserting data to ${MONSCH}.${MONTAB} Table"
                db2 -v -m "insert into ${MONSCH}.${MONTAB} select * from table(MON_GET_HADR(NULL))" | tee -a ${LOGFILE}
                #db2 -x "select * from ${MONSCH}.${MONTAB} fetch first 15 rows only" > /tmp/monhadr.txt
                db2 -x "select HADR_ROLE,HADR_SYNCMODE,HADR_STATE,HADR_CONNECT_STATUS,HADR_CONNECT_STATUS_TIME,LOG_HADR_WAIT_CUR,HADR_LOG_GAP,STANDBY_RECV_REPLAY_GAP,STANDBY_RECV_BUF_PERCENT,STANDBY_RECV_BUF_PERCENT,HADR_LAST_TAKEOVER_TIME,ROW_INSERT_TIMESTAMP from METRICS.HADR_MON" > /tmp/monhadr.txt

                log "Deleting data from ${MONSCH}.${MONTAB} Table which is older than 30 Days"
                echo "" | tee -a ${LOGFILE}
                db2 -v "delete from METRICS.HADR_MON where date(ROW_INSERT_TIMESTAMP) < current date - 30 days" | tee -a ${LOGFILE}
            fi
            db2 -v "terminate" | tee -a ${LOGFILE} 2>&1
        elif [[ "${DBROLE}" == "STANDBY" ]]; then
            log "${DBNAME} - Standby database"

        elif [[ "${DBROLE}" == "STANDARD" ]]; then
            log "${DBNAME} - Standard database"
            
        else
            log "${DBNAME} - Invalid dbrole or something not good please check"
        fi
    done < /tmp/${DB2INST}.db.lst
}

function mon_hadr {
    if [[ -s /tmp/monhadr.txt ]]; then
        cat /tmp/monhadr.txt | while read LINE
        do
            echo ${LINE} 
        done
    fi
}

main