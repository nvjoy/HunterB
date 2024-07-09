#!/bin/bash
# Script Name: create_inst.sh
# Description: This script will create db2 instance.
# Arguements: DB2 Instance to create
# Date: Oct, 2022

SCRIPTNAME=create_inst.sh

## Call commanly used functions and variables
    . /tmp/include_db2

DB2INST=$1
log_roll ${LOGFILE}

function chk_file {
    FILENAME=$1
    if [[ -f "${FILENAME}" ]]; then
        return 0
    else
        log "Warning: ${FILENAME} - File not exist, Please check"
    fi
}

log "START - ${SCRIPTNAME} execution started at $(date)"

    log "Current shell - $SHELL"
        log "Changing shell to ksh"
	    chsh -s /bin/ksh ${DB2INST}
    log "Current shell - $SHELL"

        chk_file /engnfs/igs/dba/DB2/server_config_files.tar
        if [[ $? -eq 0 ]]; then
            log "Running - tar -xvf /engnfs/igs/dba/DB2/server_config_files.tar"
            cd $HOME  
            tar -xvf /engnfs/igs/dba/DB2/server_config_files.tar >> ${LOGFILE}
        fi

    log "Creating messages directory"
        if [[ ! -d "/db/messagelog/${DB2INST}" ]]; then
            mkdir -m 3777 /db/messagelog/${DB2INST}
        fi

    log "Copying .profile"
        chk_file .profile_base
        if [[ $? -eq 0 ]]; then
            log "Running cp .profile_base .profile"
            cd $HOME  
            cp .profile_base .profile
        fi

    log "Checking db2ilist and db2level"
        log "Instance list"
        db2ilist >> ${LOGFILE}
        log "Instance level"
        db2level >> ${LOGFILE}

    log "Checking $HOME/bin/create_gdg.sh scripts to create the GDG logs"
        chk_file $HOME/bin/create_gdg.sh
        if [[ $? -eq 0 ]]; then
            log "Running - $HOME/bin/create_gdg.sh"
            cd $HOME  
            $HOME/bin/create_gdg.sh >> ${LOGFILE}
        fi

    log "Configuring db2 instance"

        chk_file $HOME/dbmcfg.cmd
        if [[ $? -eq 0 ]]; then
            log "Running - $HOME/dbmcfg.cmd"
            cd $HOME
            cat $HOME/dbmcfg.cmd | sed '+s+<instance>+${DB2INST}+g' > /tmp/${DB2INST}_dbmcfg.cmd
            db2 -svtf /tmp/${DB2INST}_dbmcfg.cmd | tee -a /${LOGSDIR}/dbmcfg.out >> ${LOGFILE}
            db2set DB2COMM=SSL,TCPIP
        fi

    log "Verifying db2 registry variables"
        db2set -all >> ${LOGFILE}

    log "Checking $HOME/registry.cmd"
        chk_file $HOME/registry.cmd
        log "Running - $HOME/registry.cmd"
        if [[ $? -eq 0 ]]; then
            $HOME/registry.cmd >> ${LOGFILE}
            db2set -all >> ${LOGFILE}
        fi

    log "Restart db2 instance"
        chk_file $HOME/startup/db2.clean
        if [[ $? -eq 0 ]]; then
            log "Running - startup/db2.clean"
            $HOME/startup/db2.clean >> ${LOGFILE}
        fi
        chk_file $HOME/startup/rc.db2
        if [[ $? -eq 0 ]]; then
            log "Running - startup/rc.db2"
            $HOME/startup/rc.db2 >> ${LOGFILE}
            db2start >> ${LOGFILE}
        fi

log "END - ${SCRIPTNAME} execution ended at $(date)"