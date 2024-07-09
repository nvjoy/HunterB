#!/bin/bash
# Script Name: db2diag_chk.sh
# Description: This script will Checks diag messages(Critical/Error/Severe) for last 30mins(default) and send .
# Arguments: TIMEINTERVAL=30m/1h/2d etc (Run as Instance)
# Date: Oct, 2022
# - To display all logged error messages containing the DB2 ZRC return code 0x87040055, and the application ID 916625D.NA8C.068149162729, enter:
#         db2diag -g msg:=0x87040055 -l Error | db2diag -gi appid^=G916625D.NA
#  - To display all messages not containing the LOADID data, enter:
#         db2diag -gv data:=LOADID

SCRIPTNAME=db2diag_chk.sh
HNAME=$(hostname -s)
HVERSION=$(uname -s)
DB2INST=$(whoami)
TIMEINTERVAL=$1
EMAILTO=Jaiganesh.Thangavelu1@kyndryl.com

if [[ -z ${TIMEINTERVAL} ]]; then
    TIMEINTERVAL=30m
else
    TIMEINTERVAL=$1
fi

## Source db2profile
    if [[ -f $HOME/sqllib/db2profile ]]; then
        . $HOME/sqllib/db2profile
    fi

## Checking diag messages
MSGCOUNT=$(db2diag -level "Severe,Critical,Error" -H ${TIMEINTERVAL} | wc -l)

if [[ ${MSGCOUNT} -gt 0 ]]; then
    echo "Error: ${HNAME}_${DB2INST} - Observed Severe/Critical/Error messages in db2diag Since last ${TIMEINTERVAL}, Pls Check" | tee /tmp/diag_error.txt
    db2diag -level "Severe,Critical,Error" -H ${TIMEINTERVAL} | tee -a /tmp/diag_error.txt
    db2instance -list | tee -a /tmp/diag_error.txt
    mail -s "Error: db2diag - ${HNAME}_${DB2INST} - Severe/Critical/Error messages" ${EMAILTO} < /tmp/diag_error.txt
    rm -f /tmp/diag_error.txt
else
    echo "Info: ${HNAME}_${DB2INST} - No Severe/Critical/Error messages in db2diag Since last ${TIMEINTERVAL}" | tee /tmp/diag_error.txt
fi