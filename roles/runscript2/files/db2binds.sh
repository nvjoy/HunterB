#!/bin/bash
# Script Name: db2binds.sh
# Description: This script will run db2 binds on all databases or 1 database.
# Arguments: DBNAME (Run as Instance)
# Date: Aug, 2022

function main {
    run_db2_profile
    get_vars
    list_dbs
    run_binds
}

function get_vars {
    TIMESTAMP=$(date +%y%m%d%H%M)
    DB2INST=$(whoami)
    LOGFILE=/tmp/db2bind_${DB2INST}_${TIMESTAMP}.log

    if [[ -z "$1" ]]; then
        list_dbs
    else
        echo "$1" > /tmp/${DB2INST}.db.lst
    fi

    DB2VR=$(db2level | grep -i "Informational tokens" | awk '{print $5}')
    if [[ "${DB2VR:0:5}" == "v11.1" ]]; then
        DB2UPDB=db2updv111
    elif [[ "${DB2VR:0:5}" == "v11.5" ]]; then
        DB2UPDB=db2updv115
    else
        DB2UPDB=db2updv105
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

function run_binds {
    log "Start - Bind packages for each db in the instance - ${DB2INST}"
    
    while read DBNAME
    do
        DBROLE=$(db2 get db cfg for ${DBNAME} | grep -i "HADR database role" | cut -d "=" -f2 | awk '{print $1}'s)
        if [[ "${DBROLE}" == "PRIMARY" || "${DBROLE}" == "STANDARD" ]]; then
            log "Running binds on Database - ${DBNAME}"
            db2 -v "connect to ${DBNAME}" | tee -a ${LOGFILE} 2>&1
            if [[ $? -ne 0 ]]; then log "Not able to connect DB - ${DBNAME}, Please check!";exit 1; fi
            db2 -v "bind $HOME/sqllib/bnd/@db2ubind.lst blocking all grant public action add" | tee -a ${LOGFILE} 2>&1
            db2 -v "bind $HOME/sqllib/bnd/@db2cli.lst blocking all grant public" | tee -a ${LOGFILE} 2>&1
            db2 -v "bind $HOME/sqllib/bnd/db2schema.bnd blocking all grant public sqlerror continue" | tee -a ${LOGFILE} 2>&1
            db2 -v "terminate" | tee -a ${LOGFILE} 2>&1

            log "Running - ${DB2UPDB} -d ${DBNAME}"
            ${DB2UPDB} -d ${DBNAME} | tee -a ${LOGFILE} 2>&1
            
            db2 -v "connect to ${DBNAME}" | tee -a ${LOGFILE} 2>&1
            if [[ $? -ne 0 ]]; then log "Not able to connect DB - ${DBNAME}, Please check!";exit 1; fi
            db2 -v "select count(*) from syscat.tables with ur" | tee -a ${LOGFILE} 2>&1
            db2 get snapshot for tablespaces on ${DBNAME} | grep -i state | tee -a ${LOGFILE} 2>&1
            db2 -v "terminate" | tee -a ${LOGFILE} 2>&1
        elif [[ "${DBROLE}" == "STANDBY" ]]; then
            log "${DBNAME} - Standby"
        else
            log "${DBNAME} - Invalid dbrole or something not good please check"
        fi
    done < /tmp/${DB2INST}.db.lst

    log "Current instance db2level"
    db2level | tee -a ${LOGFILE}
    log "Db2 License Information"
    db2licm -l | tee -a ${LOGFILE}
}

main