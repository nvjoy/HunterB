#!/bin/bash
# Script Name: create_inst.sh
# Description: This script will create db2 instance.
# Arguements: DB2 Instance to create
# Date: Apr 4, 2022
# Written by: Naveen C

SCRIPTNAME=drop_db2inst.sh

## Call commanly used functions and variables
    . /tmp/include_db2

DB2INST=$1
get_inst_home
log_roll ${LOGFILE}

## Calling DB2 Profile
if [[ -f ${INSTHOME}/sqllib/db2profile ]]; then
    . ${INSTHOME}/sqllib/db2profile
fi

function chk_file {
    FILENAME=$1
    if [[ -f "${FILENAME}" ]]; then
        return 0
    else
        log "Warning: ${FILENAME} - File not exist, Please check"
    fi
}

log "START - ${SCRIPTNAME} execution started at $(date)"
    list_dbs
    log "Checking any local databases"
    if [[ $(cat /tmp/${DB2INST}.db.lst | wc -l) -gt 0 ]]; then
        log "Warning - One or more databases still exist under ${DB2INST}, Please drop them first."
        cat /tmp/${DB2INST}.db.lst
        exit 0
    fi

    log "Remove the monitoring into the instance"
    /opt/IBM/ITM/bin/itmcmd agent -o ${DB2INST} stop ud

    if [[ $(ps -ef | grep -i kuddb2 | grep -v grep | grep -i ${DB2INST}) -eq 0 ]]; then
        log "Info: Monitoring removed for ${DB2INST}"
    else
        log "Warning: Monitoring not removed for ${DB2INST}, Pls Check"
    fi

    # log "Checking db2 backups and drop databases"
    # while read DBNAME
    # do
    #     if [[ $(db2adutl query db ${DBNAME} | wc -l) -gt 0 ]]; then
    #         ~/bin/tsmpurge.sh ${DBNAME} 7 Y
    #     fi
    #     db2 -v "get db cfg for ${DBNAME}" > ${LOGDIR}/db_cfg_${DBNAME}.txt
    #     db2 -v force applications all >> ${LOGFILE}; db2 -v terminate >> ${LOGFILE}; db2 -v deactivate db ${DBNAME} >> ${LOGFILE}
    #     db2 -v drop db ${DBNAME} >> ${LOGFILE}
    # done < /tmp/${DB2INST}.db.lst

    log "Removing crontab"
    crontab -l > ${LOGDIR}/crontab.txt
    $HOME/startup/db2.clean >> ${LOGFILE}
    if [[ -s ${LOGDIR}/crontab.txt ]]; then
        crontab -r >> ${LOGFILE}
    fi

    db2 get dbm cfg >> ${LOGDIR}/dbm_cfg_${DB2INST}.txt
    db2level | tee -a >> ${LOGDIR}/db2level_${DB2INST}.txt > /tmp/db2level_${DB2INST}.txt

    log "Stopping and Dropping db2 instance"
    if [[ $(ps -ef | grep -v grep | grep -i ${DB2INST} | grep -i db2sysc | wc -l) -gt 0 ]]; then
        db2stop force;
        ipclean -a
    # else
    #     DB2VPATH=$(db2level | grep 'installed'  | awk '{print $5'} | sed "s/..$//g" | sed "s/^.//g" | head -1)
    #     . ${DB2VPATH}/instace/db2idrop ${DB2INST} >> ${LOGFILE}
    fi

log "END - ${SCRIPTNAME} execution ended at $(date)"