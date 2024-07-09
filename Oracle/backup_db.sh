#!/bin/bash

# Oracle Database credentials
export ORACLE_SID=ORCLCDB
export ORACLE_HOME=/opt/oracle/product/19c/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
export NLS_DATE_FORMAT='YYYY-MM-DD_HH24:MI:SS'

# Backup directory
backup_dir="/home/oracle/backups"
timestamp=$(date +%Y%m%d_%H%M%S)

# RMAN backup options
backup_type="full"
backup_file="${backup_dir}/full_backup_${timestamp}.bkp"

# Perform the backup using RMAN
rman target / <<EOF
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '${backup_file}';
RUN {
  ALLOCATE CHANNEL ch1 DEVICE TYPE DISK;
  BACKUP $backup_type DATABASE;
}
EXIT;
EOF

echo "Backup completed successfully!"


        set feedback off
        set heading off
        set feed off
        set linesize 100
        set pagesize 200
        col host_name a10
        col instance_name a80
        col STATUS format a99
        col hrs format 999.99
        set lines 12345 pages 12345
        select
        t1.host_name,t1.instance_name, t2.SESSION_KEY, t2.INPUT_TYPE, t2.STATUS,
        to_char(t2.START_TIME,'mm/dd/yy hh24:mi') start_time,
        to_char(t2.END_TIME,'mm/dd/yy hh24:mi') end_time,
        t2.elapsed_seconds/3600 hrs
        from V$RMAN_BACKUP_JOB_DETAILS t2,
        v$instance t1
        where t2.END_TIME > sysdate - 7
        order by session_key;


1. **Last Good Backup
2. **Exempt Backups
3. MISSING backups > 2 days
4. ARCH details along with locked is not sure about that

http://www.acehints.com/2012/06/purpose-of-oraenvaskno-yes-variable-in.html
export ORAENV_ASK=NO;export ORACLE_SID=DEVDB1;export ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_DEVDB1;. oraenv;export ORACLE_SID=DEVDB12; ./sql.sh inse.sql



set pages 100 lines 200 feedback off markup html on
alter session set nls_date_format='DD-MON-YYYY HH24:MI';
spool /tmp/backup.html append
select host_name,instance_name from v$instance;
select
(select host_name from v$instance) AS "Host_NAME",
(Select name from v$database) as "DB_NAME",
start_time,end_time,elapsed_seconds/60/60 as "DURATION(HOURS)", INPUT_TYPE,
(r.status) as status,(b.incremental_level) as incremental_level
from v$RMAN_BACKUP_JOB_DETAILS r
inner join
(select distinct session_stamp,incremental_level from v$backup_set_details) b on
r.session_stamp = b.session_stamp where incremental_level is not null
and r.start_time > sysdate - 7
and INPUT_TYPE <>'ARCHIVELOG' order by 3;
spool off;