#!/bin/bash
##################################################################
#  This script makes a online backup of database to tsm.         #
##################################################################
##################################################################
#               Set Local Variables                              #
##################################################################
USER=$USER
#TYPE=Full
BEGIN_JOB=$(date)
HOSTNAME=$(uname -n)
TIMESTAMP=$(date +%m%d%y_%H:%M)
ERRMSG="Usage: `basename $0` <DBNAME> <EMAIL> <f/i>(Optional default f=full)"
DB2INST=$(whoami)

##################################################################
# Verify that all input parmaters needed have been provided.     #
##################################################################
if [[ "$1" ]]; then
    DBNAME=$1
else echo ${ERRMSG}
    exit
fi

if [[ "$2" ]]; then
    EMAIL=$2
else echo $ERRMSG
     exit
fi

if [[ "$3" ]]; then
    TYPE=$3
else 
    TYPE=f
fi

if [[ "${TYPE}" == "f" || "${TYPE}" == "full" ]]; then
    echo "Submitted Online Full Backup"
elif [[ "${TYPE}" == "i" || "${TYPE}" == "incremental" ]]; then
    echo "Submitted Online Incremental Backup"
else
    echo "Invalid type $ERRMSG"
    exit
fi

##################################################################
#   Initialize rest of the variables and take backup             #
##################################################################
LOGFILE=$HOME/${DBNAME}_$TYPE_bkup_${TIMESTAMP}.log
export START_DATE=`date +"%d-%b-%Y_%H:%M%S"`

DBROLE=$(db2 get db cfg for ${DBNAME} | grep -i "HADR database role" | cut -d "=" -f2 | awk '{print $1}')
if [[ "${DBROLE}" == "PRIMARY" || "${DBROLE}" == "STANDARD" ]]; then
    # Run the generated backup command
    ###db2 backup db $DBNAME online use tsm without prompting > $LOGFILE
    if [[ "${TYPE}" == "f" || "${TYPE}" == "full" ]]; then
        db2 backup db $DBNAME online use tsm open 4 sessions WITH 4 BUFFERS without prompting > $LOGFILE
        export FINISH_DATE=`date +"%d-%b-%Y_%H:%M%S"`
        TYPE=Full
    elif [[ "${TYPE}" == "i" || "${TYPE}" == "incremental" ]]; then
        db2 backup db $DBNAME online incremental use tsm open 4 sessions WITH 4 BUFFERS without prompting > $LOGFILE
        export FINISH_DATE=`date +"%d-%b-%Y_%H:%M%S"`
        TYPE=Incremental
    fi
    ### SOX Reporting
    if [[ `grep SQL ${LOGFILE}|wc -l` -ge 1 ]]; then
        SQL_ERROR=`grep SQL ${LOGFILE} | grep -v SQLSTATE | awk '{print $1}'`
        ERROR_TEXT=`cat ${LOGFILE} | cut -d" " -f2-`

        echo "$TYPE backup of database $DBNAME failed on $BEGIN_JOB"
        mail -s "$TYPE backup of db $DBNAME in DB2 instance $DB2INSTANCE on server $HOSTNAME FAILED." "$EMAIL" < $LOGFILE
    else
        SQL_ERROR="0"
        ERROR_TEXT="0"
        echo "$TYPE backup of database $DBNAME completed successfully on $BEGIN_JOB"
    fi
else
    echo "$(hostname -s)_$(whoami)_${DBNAME} - Standby database - Exiting..!"
    exit 0
fi

function tsamp_bkp {
    DB2VR=$(db2level | grep -i "Informational tokens" | awk '{print $5}')
    if [[ $(lssam | grep -i ${DB2INST}| wc -l) -gt 0 ]]; then
        if [[ "${DB2VR:0:5}" == "v10.5" ]]; then
            echo "We cannot backup db2haicu xml on DB2 ${DB2VR:0:5}"
        else
            db2haicu -o $HOME/${HOSTNAME}_${DB2INST}_db2haicu.xml
        fi
    fi   
}
rm $LOGFILE
tsamp_bkp
#########################################################################
#       SOX Reporting                                                   #
#########################################################################
#/usr/local/bin/SOX/sox "ftwaxorad001" 1 `hostname` iss.bnr.com ${DBNAME} "${SQL_ERROR}" "${ERROR_TEXT}" ${START_DATE} ${FINISH_DATE} FULL
exit