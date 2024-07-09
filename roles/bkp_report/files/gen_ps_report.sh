#!/bin/bash

FINALRPT=$1
LOGSDIR=$2
echo "=======================================================" > ${FINALRPT}
echo "=        Purescale - Daily Backup Report Generated on - $(date +'%Y-%m-%d %H:%M:%S')      =" >> ${FINALRPT}
echo "=======================================================" >> ${FINALRPT}
echo "" >> ${FINALRPT}
echo "-- BEGIN - Backups In Progress" >> ${FINALRPT}
echo "---------------------------------------------------------------" >> ${FINALRPT}
cat ${LOGSDIR}/daily_report_*.final | grep -i BackupInProgress >> ${FINALRPT}
echo "-- END" >> ${FINALRPT}
echo "" >> ${FINALRPT}

echo "-- BEGIN - Purescale latest full backup information" >> ${FINALRPT}
echo "------------------------------------------------------------------------------------------------------------------------------" >> ${FINALRPT}
echo "HOSTNAME_INST_DBNAME              BACKUP_TYPE         START_TIME     END_TIME       STATUS  ERR_CODE    BKP_EXEC_TIME_MIN" >> ${FINALRPT}
echo "------------------------------------------------------------------------------------------------------------------------------" >> ${FINALRPT}
cat ${LOGSDIR}/daily_report_*.final | grep FULL >> ${FINALRPT}
echo "-- END" >> ${FINALRPT}
echo "" >> ${FINALRPT}

echo "-- BEGIN - Standby Report --No Action needed" >> ${FINALRPT}
echo "---------------------------------------------------------------" >> ${FINALRPT}
cat ${LOGSDIR}/daily_report_*.final | grep -i "Standby - No Backup Needed" >> ${FINALRPT}
echo "-- END" >> ${FINALRPT}
echo "" >> ${FINALRPT}

echo "-- BEGIN - Error, Unable to connect or Instance not running --Take Action" >> ${FINALRPT}
echo "-------------------------------------------------------------------------" >> ${FINALRPT}
cat ${LOGSDIR}/daily_report_*.final | grep -i "ERROR:" >> ${FINALRPT}
echo "-- END" >> ${FINALRPT}
echo "" >> ${FINALRPT}

echo "-- BEGIN - Ingnoring Test Databases" >> ${FINALRPT}
echo "---------------------------------------------------------------" >> ${FINALRPT}
cat ${LOGSDIR}/daily_report_*.final | grep -i "Database does not need to be backed up" >> ${FINALRPT}
echo "-- END" >> ${FINALRPT}
echo "" >> ${FINALRPT}

#mail -s "Purescale Backup Report - $(hostname -s) - $(date)" ${MAILTO} < ${FINALRPT}
#cat ${FINALRPT}