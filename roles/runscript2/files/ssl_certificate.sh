#!/bin/bash
# Script Name: ssl_certificate.sh
# Description: This script will list out all available backup images for database.
# Arguments: DB2INST (Run as Instance)
# Date: Feb 27, 2022

SCRIPTNAME=ssl_certificate.sh
HNAME=$(hostname -s)
HVERSION=$(uname -s)
DB2INST=$(whoami)
CURTIMSTP=$(date +'%Y%m%d%H%m%S')
EMAILTO=Jaiganesh.Thangavelu1@kyndryl.com
if [[ -d /db/exp ]]; then
    LOGSDIR=/db/exp
else
    LOGSDIR=/tmp
fi
mkdir -p ${LOGSDIR}/logs
LOGFILE=${LOGSDIR}/logs/${SCRIPTNAME}_${CURTIMSTP}.log

function log {
    echo "$(date +'%Y-%m-%d %H:%m:%S') >>" $1 | tee -a ${LOGFILE}
}

## Source db2profile
    if [[ -f $HOME/sqllib/db2profile ]]; then
        . $HOME/sqllib/db2profile
    fi

CUR_SSL_SVR_KEYDB=$(db2 get dbm cfg | grep -i SSL_SVR_KEYDB | awk -F "= " '{print $2}')

if [[ ! -z ${CUR_SSL_SVR_KEYDB} ]]; then

    log "Identify the expiring certificate and label for ${CUR_SSL_SVR_KEYDB}"

        # gsk8capicmd_64 -cert -list -db ${CUR_SSL_SVR_KEYDB} -stashed
        KEYLABEL=$(gsk8capicmd_64 -cert -list -db ${CUR_SSL_SVR_KEYDB} -stashed | tail -1 | awk '{print $2}')
        # gsk8capicmd_64 -cert -details -label "${KEYLABEL}" -db ${CUR_SSL_SVR_KEYDB} -stashed
        EXPDATE=$(gsk8capicmd_64 -cert -details -label "${KEYLABEL}" -db ${CUR_SSL_SVR_KEYDB} -stashed | grep -i "Not After" | awk -F ": " '{print $2}' | awk '{print $1" "$2" "$3}')

        CURDDATE=$(date +'%Y-%m-%d')
        EXPDATEBEFORE7DAYS=$(date -d "${EXPDATE} - 7 days" +'%s')

        let DIFF=(${EXPDATEBEFORE7DAYS}-$(date +%s))/86400
        #echo $DIFF

        if [[ ${DIFF} -lt 1 ]]; then
            log "Error: ${HNAME}_${DB2INST} - SSL Certificate going to Expire in ${DIFF} Days"
            mail -s "Error: ${HNAME}_${DB2INST} - SSL Certificate going to Expire in ${DIFF} Days" ${EMAILTO} < /dev/null
        elif [[ ${DIFF} -lt 7 ]]; then
            log "Warning: ${HNAME}_${DB2INST} - SSL Certificate going to Expire in ${DIFF} Days, Trying to regenerate"
            mail -s "Warning: ${HNAME}_${DB2INST} - SSL Certificate going to Expire in ${DIFF} Days" ${EMAILTO} < /dev/null

            log "Recreate the certificate signing request for ${KEYLABEL} Label"
                # gsk8capicmd_64 -certreq -recreate -db ${CUR_SSL_SVR_KEYDB} -stashed -label "${KEYLABEL}" -target new_cert_request. csr | tee -a ${LOGFILE}

            log "Send the resulting new_cert_request.csr certificate to be signed by the original Certificate Authority (CA)."
            log "Once the signed certificate has been returned, then receive it back into your server keystore"
                # gsk8capicmd_64 -cert -receive -db ${CUR_SSL_SVR_KEYDB} -stashed -file new_cert_signed.pem | tee -a ${LOGFILE}

            log "Verify the new dates on the received certificate by running:"
                # gsk8capicmd_64 -cert -details -label ${KEYLABEL} -db ${CUR_SSL_SVR_KEYDB} -stashed | tee -a ${LOGFILE}

            log "If the Db2 level is Version 11.5 Mod Pack 3 or later, refresh the SSL certificate used by Db2 by attaching to the instance and updating the SSL_SVR_LABEL database manager configuration parameter"

            DB2V=$(db2level | grep -i "Informational tokens" | awk '{print $5}')
            DB2VR=$(echo ${DB2V:1:6} | sed 's/\.//g')
            if [[ ${DB2VR} -gt 1153 ]]; then
                db2 -v attach to ${DB2INST} | tee -a ${LOGFILE}
                db2 -v update dbm cfg using SSL_SVR_LABEL ${KEYLABEL} | tee -a ${LOGFILE}
            else
                log "Warning: DB2 Version - ${DB2VR}"
            fi
        else
            log "Info: ${HNAME}_${DB2INST} - SSL Certificate going to Expire in ${DIFF} Days."
        fi
else
    log "Info: ${HNAME}_${DB2INST} - NO SSL Key setup on this Instance"
fi