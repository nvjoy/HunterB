#!/bin/env python
"""This module is used to patch oracle database application running on Linux"""
import os
import re
import time
import itertools
from subprocess import PIPE, Popen
from ansible.module_utils.basic import AnsibleModule

LOGFILE = "/ora/expimp/ansible_patch_oracle.log"
SUPPORTED_ORAVERSION = ['12', '18', '19']

def getdbobjectinvalids(dbinfo, oratemp):
    """This function is used to get database objects status information using sql"""
    oratemp = oratemp + "/ansible_dbobjectinvalids.sql"
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    fdata = '''
set feedback off
set pagesize 150
set linesize 150
col object_name,object_type for a20
col owner,status for a5
set timi off
select name from v$database;
Select object_name,object_type,owner,status from dba_objects where status='INVALID';
@$ORACLE_HOME/rdbms/admin/utlrp.sql;
Select object_name,object_type,owner,status from dba_objects where status='INVALID';
exit
'''
    createfile(oratemp, fdata)
    logger("Getting detail information from dba_objects to check invalid objects")
    for key, value in dbinfo.items():
        logger("INVALID objects status from database " + key)
        cmmd = 'export ORACLE_SID=' + key + ';export ORACLE_HOME=' + value + \
        ';export PATH=$PATH:$ORACLE_HOME/bin;sqlplus -s / as sysdba @' + oratemp
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        logger('\n                '.join(sout_lines))
        logger(serr)
        if len(sout_lines) != 0:
            logger(key + " Invalid objects details")
            msg = "Invalid objects details"
            fled = False
            chged = True
        else:
            fled = True
            chged = False
            msg = "Invalid objects check failed " + key
            logger(msg)
            return msg, chged, fled, sout, sout_lines, serr, serr_lines
    return msg, chged, fled, sout, sout_lines, serr, serr_lines

def getdbsqlpatchregistry(dbsqlpatchregistry, oratemp):
    """This function is used to get sql patch information using sql"""
    oratemp = oratemp + "/ansible_dbsqlpatchregistry.sql"
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    fdata = '''
set feedback off
set pagesize 200
set linesize 200
set timi off
col action,status for a5
col ACTION_TIME,description for a10
select name from v$database;
select patch_id,status,ACTION_TIME,action,description from dba_registry_sqlpatch where rownum <=2 order by 3 desc;
exit
'''
    createfile(oratemp, fdata)
    logger("Getting detail information from dba_registry_sqlpatch")
    for key, value in dbsqlpatchregistry.items():
        logger("DBA SQLPATCH Patch registry details from database " + key)
        cmmd = 'export ORACLE_SID=' + key + ';export ORACLE_HOME=' + value + \
        ';export PATH=$PATH:$ORACLE_HOME/bin;sqlplus -s / as sysdba @' + oratemp
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        logger('\n                '.join(sout_lines))
        logger(serr)
        if len(sout_lines) != 0:
            logger(key + " DBA SQLPATCH Patch registry details")
            msg = "DBA SQLPATCH Patch registry details"
            fled = False
            chged = True
        else:
            fled = True
            chged = False
            msg = "DBA SQLPATCH Patch registry check failed " + key
            logger(msg)
            return msg, chged, fled, sout, sout_lines, serr, serr_lines
    return msg, chged, fled, sout, sout_lines, serr, serr_lines

def getdbregistryvalidate(dbregistryvalidate, oratemp):
    """This function is used to get database registry information using sql"""
    oratemp = oratemp + "/ansible_dbregistryvalidate.sql"
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    fdata = '''
set feedback off
set pagesize 200
set linesize 200
col COMP_NAME for a30
col SCHEMA for a20
set timi off
select name from v$database;
select COMP_NAME,VERSION,STATUS,SCHEMA from dba_registry;
exit
'''
    createfile(oratemp, fdata)
    logger("Getting detail information from databases registry")
    for key, value in dbregistryvalidate.items():
        logger("DBA REGISTRY details from database " + key)
        cmmd = 'export ORACLE_SID=' + key + ';export ORACLE_HOME=' + value + \
        ';export PATH=$PATH:$ORACLE_HOME/bin;sqlplus -s / as sysdba @' + oratemp
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        logger('\n                '.join(sout_lines))
        logger(serr)
        if len(sout_lines) != 0:
            logger(key + " DBA REGISTRY details")
            msg = "DBA REGISTRY details"
            fled = False
            chged = True
        else:
            fled = True
            chged = False
            msg = "DBA REGISTRY check failed " + key
            logger(msg)
            return msg, chged, fled, sout, sout_lines, serr, serr_lines
    return msg, chged, fled, sout, sout_lines, serr, serr_lines

def getdbdetails(dbhomeloc):
    """This function is used to get database information from oratab"""
    dbdetails = {}
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    logger("Getting configured  database")
    cmmd = "cat /etc/oratab| egrep ':N|:Y'|grep -v \*|grep -v '\#' |grep " + dbhomeloc
    chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
    if len(sout_lines) == 0:
        msg = "Unable to find a valid database"
        logger(msg)
        fled = True
    if fled:
        msg = "Unable get database info from /etc/oratab"
        logger(msg)
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    for dbfline in sout_lines:
        dbsplit = dbfline.split(":")
        if len(dbsplit) >= 2:
            dbdetails[dbsplit[0]] = dbsplit[1]
            msg = "dbname: " + dbsplit[0] + " - dbhome: " + dbsplit[1]
            logger(msg)
            cmmdl = "ls " + dbsplit[1] + "/lib/libcell*.so |  awk " + \
            r"'match($0, /libcell([[:digit:]][[:digit:]])\.so/, ver) { print ver[1] }'"
            chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmdl)
            if fled:
                msg = "Failed when getting a oracle version"
                logger(msg)
                return msg, chged, fled, sout, sout_lines, serr, serr_lines
            if sout not in SUPPORTED_ORAVERSION:
                msg = "Running oracle version " + sout + \
                " is not supported. Supported oracle versions are " + str(SUPPORTED_ORAVERSION)
                logger(msg)
                fled = True
                chged = False
                return msg, chged, fled, sout, sout_lines, serr, serr_lines
    sout = dbdetails
    return msg, chged, fled, sout, sout_lines, serr, serr_lines

def getdbinfo(dbinfo, oratemp):
    """This function is used to get database information using sql"""
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    oratemp = oratemp + "/ansible_dbinfo.sql"
    fdata = '''
set head off
set feedback off
set pagesize 100
set linesize 100
set timi off
select ';'||
(select name from v$database) ||';'||
(select version from v$instance)||';'||
(select database_role from v$database) ||';'||
(select value from v$parameter where name = 'cluster_database')||';'||
(select listagg(instance_name,',') within group (order by instance_number) instance_list from v$instance) ||';'||
(select status from v$instance where status in ('MOUNTED','OPEN')) ||';'||
(select value from v$parameter where name = 'db_unique_name')  db_metadata
from dual;
exit
'''
    createfile(oratemp, fdata)
    strdbinfo_lines = []
    logger("Getting detail information from databases")
    logger(";name;version;database_role;cluster_database;instance_name;status;db_unique_name")
    for key, value in dbinfo.items():
        cmmd = 'export ORACLE_SID=' + key + ';export ORACLE_HOME=' + value + \
        ';export PATH=$PATH:$ORACLE_HOME/bin;sqlplus -s / as sysdba @' + oratemp
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        if len(sout_lines) > 1:
            strdbinfo_lines.append(sout_lines[1])
            logger(sout_lines[1])
            if re.search(";MOUNTED;", sout_lines[1], re.IGNORECASE):
                msg = key + " database is not in OPEN state. Patching terminated"
                logger(msg)
                fled = True
                chged = False
        if fled:
            return msg, chged, fled, sout, sout_lines, serr, serr_lines
    sout = " ".join(strdbinfo_lines)
    return msg, chged, fled, sout, strdbinfo_lines, serr, serr_lines

def getlistener(oratemp, dbhomeloc):
    """This function is used to get listener information"""
    lstdetails = {}
    listenerfile = oratemp + "/oralistener"
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    logger("Getting listeners")
    cmmd = 'ps -eo args | grep "/tnslsnr " | grep -v grep | cut -d" " -f1,2 | grep ' + dbhomeloc
    chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
    if len(sout_lines) == 0:
        if os.path.exists(listenerfile):
            cmmd = 'cat ' + listenerfile
            chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
            if len(sout_lines) == 0:
                msg = "No running listeners found. No tnslsnr process is in ps command"
                logger(msg)
    else:
        createfile(listenerfile, '\n'.join(sout_lines))
    for lstline in sout_lines:
        lstsplit = lstline.split(" ")
        if len(lstsplit) >= 2:
            lsthome = lstsplit[0].split("/")
            lsthome = lsthome[: len(lsthome) - 2]
            lsthome = "/".join(lsthome)
            lstdetails[lstsplit[1]] = lsthome
            msg = "listener name: " + lstsplit[1] + " - homedir: " + lsthome
            logger(msg)
    return msg, chged, fled, lstdetails, sout_lines, serr, serr_lines

def stopdatabase(dbinfo, oratemp):
    """This function is used to stop a database"""
    oratemp = oratemp + "/ansible_dbstop.sql"
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    fdata = '''
set head off
set feedback off
set pagesize 100
set linesize 100
set timi off
shu immediate;
exit
'''
    createfile(oratemp, fdata)
    for key, value in dbinfo.items():
        logger("Stopping database " + key)
        cmmd = 'export ORACLE_SID=' + key + ';export ORACLE_HOME=' + value + \
        ';export PATH=$PATH:$ORACLE_HOME/bin;sqlplus -s / as sysdba @' + oratemp
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        logger('\n                '.join(sout_lines))
        logger(serr)
        if fled:
            msg = "Failed when stopping database " + key
            logger(msg)
            return msg, chged, fled, sout, sout_lines, serr, serr_lines
        cmmd = 'ps -eo command|grep pmon | grep -v grep | grep -i "_' + key + '$"'
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        if len(sout_lines) == 0:
            logger(key + " database stopped successfully")
            msg = "database stopped successfully"
            fled = False
            chged = True
        else:
            fled = True
            chged = False
            msg = "Unable to stop database " + key
            logger(msg)
            return msg, chged, fled, sout, sout_lines, serr, serr_lines
    return msg, chged, fled, sout, sout_lines, serr, serr_lines

def stoplistener(listener):
    """This function is used to stop a listener"""
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    if len(listener) == 0:
        msg = "No listeners available to stop"
        logger(msg)
    for key, value in listener.items():
        cmmd = 'ps -eo command|grep "/tnslsnr " | grep -v grep ' + \
        '| cut -d" " -f1,2 | grep -i " ' + key + '$"'
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        if len(sout_lines) > 0:
            logger("Stopping listener " + key)
            cmmdl = 'export ORACLE_HOME=' + value + \
            ';export PATH=$PATH:$ORACLE_HOME/bin;lsnrctl stop ' + key
            chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmdl)
            logger('\n                '.join(sout_lines))
            logger(serr)
            if fled:
                msg = "Failed when stopping a listener " + key
                logger(msg)
                return msg, chged, fled, sout, sout_lines, serr, serr_lines
            cmmdl = 'ps -eo command|grep "/tnslsnr " | grep -v grep ' + \
            '| cut -d" " -f1,2 | grep -i " ' + key + '$"'
            chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmdl)
            if len(sout_lines) == 0:
                fled = False
                logger(key + " - listener stopped successfully")
                msg = "listener stopped successfully"
            else:
                chged = False
                msg = "Unable to stop listener " + key
                logger(msg)
        else:
            fled = False
            chged = False
            msg = "listeners are already in stopped state"
            logger(key + " - listener is already in stopped state")
        if fled:
            return msg, chged, fled, sout, sout_lines, serr, serr_lines
    return msg, chged, fled, sout, sout_lines, serr, serr_lines

def startdatabase(dbinfo, oratemp):
    """This function is used to start a database"""
    oratemp = oratemp + "/ansible_dbstart.sql"
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    fdata = '''
set head off
set feedback off
set pagesize 100
set linesize 100
set timi off
startup;
exit
'''
    createfile(oratemp, fdata)
    for key, value in dbinfo.items():
        logger("Starting database " + key)
        cmmd = 'export ORACLE_SID=' + key + ';export ORACLE_HOME=' + value + \
        ';export PATH=$PATH:$ORACLE_HOME/bin;sqlplus -s / as sysdba @' + oratemp
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        logger('\n                '.join(sout_lines))
        logger(serr)
        if fled:
            msg = "Failed when starting database " + key
            logger(msg)
            return msg, chged, fled, sout, sout_lines, serr, serr_lines
        cmmdl = 'ps -eo command|grep pmon | grep -v grep | grep -i "_' + key + '$"'
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmdl)
        if len(sout_lines) == 0:
            chged = False
            fled = True
            msg = "Unable to start database " + key
            logger(msg)
        else:
            logger(key + " database started successfully")
            msg = "database started successfully"
            fled = False
            chged = True
    return msg, chged, fled, sout, sout_lines, serr, serr_lines

def startlistener(listener):
    """This function is used to start a listener"""
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    if len(listener) == 0:
        msg = "No listeners available to start. It happened because of no tnslsnr " + \
        "process in ps command while getting a listener. " + \
        "Please start the listener manually"
        logger(msg)
    for key, value in listener.items():
        logger("Starting listener " + key)
        cmmd = 'export ORACLE_HOME=' + value + \
        ';export PATH=$PATH:$ORACLE_HOME/bin;lsnrctl start ' + key
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        logger('\n                '.join(sout_lines))
        logger(serr)
        if fled:
            msg = "Failed when starting a listener"
            logger(msg)
            return msg, chged, fled, sout, sout_lines, serr, serr_lines
        cmmdl = 'ps -eo command|grep "/tnslsnr " | grep -v grep ' + \
        '| cut -d" " -f1,2 | grep -i " ' + key + '$"'
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmdl)
        if len(sout_lines) == 0:
            chged = False
            msg = "Unable to start listener " + key
            logger(msg)
    return msg, chged, fled, sout, sout_lines, serr, serr_lines

def prepatch(patchdir, dbinfo):
    """This function is used to validate a patch - prepatching task"""
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    patchdir = patchdir+"/"
    opatch_checkconflict_pattern = "Prereq \"checkConflictAgainstOHWithDetail\" passed"
    if not os.access(patchdir, os.R_OK):
        msg = "Patch directory "+ patchdir + " is not readable by oracleuser"
        serr = msg
        logger(msg)
        fled = True
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    orahome = list(sort_uniq(list(dbinfo.values())))
    if len(orahome) == 0:
        msg = "Patching precheck failed. unable to find a valid oracle home"
        logger(msg)
        fled = True
    else:
        logger("Validating patch directory " + patchdir)
        msg, chged, fled, sout, sout_lines, serr, serr_lines = validatepatchdir(patchdir, orahome)
    if fled:
        logger(msg)
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    for orahomevar in orahome:
        logger("Getting prepatch lsinventory as oracle home - " + orahomevar)
        cmmd = 'export ORACLE_HOME=' + orahomevar + \
        ';export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch;opatch lsinventory'
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        logger('\n                '.join(sout_lines))
        logger(serr)
        if fled:
            return msg, chged, fled, sout, sout_lines, serr, serr_lines
        logger("checking prereq CheckConflictAgainstOHWithDetail as oracle home - " + orahomevar)
        cmmd = 'export ORACLE_HOME=' + orahomevar + \
        ';export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch;opatch prereq ' + \
        'CheckConflictAgainstOHWithDetail -phBaseDir ' + patchdir
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        soutmsg = '\n                '.join(sout_lines)
        logger(soutmsg)
        logger(serr)
        if re.search(opatch_checkconflict_pattern, soutmsg, re.IGNORECASE) is None:
            msg = "CheckConflictAgainstOHWithDetail failed. Patching terminated"
            fled = True
            chged = False
            return msg, chged, fled, sout, sout_lines, serr, serr_lines
        else:
            msg = opatch_checkconflict_pattern
            logger(msg)
    return msg, chged, fled, sout, sout_lines, serr, serr_lines

def validatepatchdir(patchdir, orahome):
    """This function is used to validate the patch directory"""
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    for orahomevar in orahome:
        cmmd = 'export ORACLE_HOME=' + orahomevar + \
        ';export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch;opatch lspatches ' + patchdir +\
        ' | grep "^patch_id:" | cut -d: -f2'
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        if fled:
            msg = "Failed when get a patch id from " + patchdir
        if len(sout) == 0:
            fled = True
            msg = "Invalid patch directory. Unable to get a patch id from " + patchdir
        if not fled:
            cmmd = 'export ORACLE_HOME=' + orahomevar + \
            ';export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch;opatch lspatches -id ' +\
            sout + ' | grep -i applied_date:'
            chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
            if fled:
                fled = False
            else:
                fled = True
                msg = "Patch already applied. " + sout
    return msg, chged, fled, sout, sout_lines, serr, serr_lines

def opatch(patchdir, dbinfo):
    """This function is used to patch a oracle application"""
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    patchdir = patchdir+"/"
    orahome = list(sort_uniq(list(dbinfo.values())))
    if len(orahome) == 0:
        msg = "Patching failed. unable to find a valid oracle home"
        logger(msg)
        fled = True
    for orahomevar in orahome:
        logger("Patching as oracle home - " + orahomevar)
        cmmd = 'export ORACLE_HOME=' + orahomevar + ';export PATH=$PATH:$ORACLE_HOME/bin:' + \
        '$ORACLE_HOME/OPatch;opatch apply -silent ' + patchdir
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        logger('\n                '.join(sout_lines))
        logger(serr)
        if fled:
            msg = "Patching failed. Please refer the log " + LOGFILE
            logger(msg)
    return msg, chged, fled, sout, sout_lines, serr, serr_lines

def postpatch(dbinfo):
    """This function is used to do a post patch task"""
    msg, chged, fled, sout, sout_lines, serr, serr_lines = checklogfile()
    if fled:
        return msg, chged, fled, sout, sout_lines, serr, serr_lines
    for key, value in dbinfo.items():
        msg = "postpatch for database " + key
        logger(msg)
        cmmd = 'export ORACLE_SID=' + key + ';export ORACLE_HOME=' + value + \
        ';export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch;datapatch -verbose'
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        logger('\n                '.join(sout_lines))
        logger(serr)
        if fled:
            return msg, chged, fled, sout, sout_lines, serr, serr_lines
        cmmd = 'export ORACLE_SID=' + key + ';export ORACLE_HOME=' + value + \
        ';export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch;opatch lspatches'
        chged, fled, sout, sout_lines, serr, serr_lines = runcmd(cmmd)
        logger("Running opatch lspatches")
        logger('\n                '.join(sout_lines))
        logger(serr)
    if not fled:
        msg = "Postpatch successfully completed"
        logger(msg)
    return msg, chged, fled, sout, sout_lines, serr, serr_lines

def createfile(filename, data):
    """This function is used to create a file"""
    cfile = open(filename, "w")
    cfile.write(data)
    cfile.close()

def cleanupfile(filename):
    """This function is used to delete a file"""
    if os.path.exists(filename):
        os.remove(filename)

def logger(logmsg):
    """This function is used to add a log in log file"""
    if not logmsg:
        return
    logmessage = time.strftime("%c") + "\t" + logmsg + "\n"
    lfile = open(LOGFILE, 'a')
    lfile.write(logmessage)
    lfile.close()

def sort_uniq(listvar):
    """This function is used to sort list"""
    return (x[0] for x in itertools.groupby(sorted(listvar)))

def checklogfile():
    """This function is used to check a logfile"""
    msg = ""
    chged = False
    fled = False
    chged = False
    fled = False
    sout = ""
    sout_lines = []
    serr = ""
    serr_lines = []
    if os.path.exists(LOGFILE):
        if not os.access(LOGFILE, os.W_OK):
            msg = "Log file "+ LOGFILE + " is not writable by oracleuser. " + \
            "Please delete/move the existing log file."
            serr = msg
            fled = True
    return msg, chged, fled, sout, sout_lines, serr, serr_lines

def runcmd(rcmd):
    """This function is used to run a command"""
    fled = True
    soutput = ""
    prcmd = Popen(rcmd, shell=True, stdout=PIPE, stderr=PIPE)
    sout, serr = prcmd.communicate()
    prcmd.wait()
    chged = True
    if prcmd.returncode == 0:
        fled = False
    if len(sout) > 0:
        soutput = sout.splitlines()[0]
    return chged, fled, soutput, sout.splitlines(), serr, serr.splitlines()

if __name__ == '__main__':
    FIELDS = {
        "oratask": {"required": True, "type": "str"},
        "dbdict": {"required": False, "type": "dict"},
        "listenerdict": {"required": False, "type": "dict"},
        "oratemp": {"required": False, "type": "str"},
        "patchdir": {"required": False, "type": "str"},
        "dbhomeloc": {"required": False, "type": "str"}
    }

    MODULE = AnsibleModule(argument_spec=FIELDS)
    ORATASK = MODULE.params['oratask']
    DBDICT = {}
    ORATEMP = ""
    PATCHDIR = ""
    DBHOMELOC = ""
    LISTENERDICT = {}
    if MODULE.params['dbdict']:
        DBDICT = MODULE.params['dbdict']
    if MODULE.params['oratemp']:
        ORATEMP = MODULE.params['oratemp']
    if MODULE.params['listenerdict']:
        LISTENERDICT = MODULE.params['listenerdict']
    if MODULE.params['patchdir']:
        PATCHDIR = MODULE.params['patchdir']
    if MODULE.params['dbhomeloc']:
        DBHOMELOC = MODULE.params['dbhomeloc']

    if ORATASK == "getdb":
        MSGOP, CHGDOP, FLEDOP, SOUTOP, SOUT_LINESOP, SERROP, SERR_LINESOP = \
        getdbdetails(DBHOMELOC)
    if ORATASK == "getdbregistryvalidate":
        MSGOP, CHGDOP, FLEDOP, SOUTOP, SOUT_LINESOP, SERROP, SERR_LINESOP = \
        getdbregistryvalidate(DBDICT, ORATEMP)
    if ORATASK == "getdbobjectinvalids":
        MSGOP, CHGDOP, FLEDOP, SOUTOP, SOUT_LINESOP, SERROP, SERR_LINESOP = \
        getdbobjectinvalids(DBDICT, ORATEMP)
    if ORATASK == "getdbsqlpatchregistry":
        MSGOP, CHGDOP, FLEDOP, SOUTOP, SOUT_LINESOP, SERROP, SERR_LINESOP = \
        getdbsqlpatchregistry(DBDICT, ORATEMP)
    if ORATASK == "getdbinfo":
        MSGOP, CHGDOP, FLEDOP, SOUTOP, SOUT_LINESOP, SERROP, SERR_LINESOP = \
        getdbinfo(DBDICT, ORATEMP)
    if ORATASK == "getlistener":
        MSGOP, CHGDOP, FLEDOP, SOUTOP, SOUT_LINESOP, SERROP, SERR_LINESOP = \
        getlistener(ORATEMP, DBHOMELOC)
    if ORATASK == "stopdatabase":
        MSGOP, CHGDOP, FLEDOP, SOUTOP, SOUT_LINESOP, SERROP, SERR_LINESOP = \
        stopdatabase(DBDICT, ORATEMP)
    if ORATASK == "stoplistener":
        MSGOP, CHGDOP, FLEDOP, SOUTOP, SOUT_LINESOP, SERROP, SERR_LINESOP = \
        stoplistener(LISTENERDICT)
    if ORATASK == "startdatabase":
        MSGOP, CHGDOP, FLEDOP, SOUTOP, SOUT_LINESOP, SERROP, SERR_LINESOP = \
        startdatabase(DBDICT, ORATEMP)
    if ORATASK == "startlistener":
        MSGOP, CHGDOP, FLEDOP, SOUTOP, SOUT_LINESOP, SERROP, SERR_LINESOP = \
        startlistener(LISTENERDICT)
    if ORATASK == "prepatch":
        MSGOP, CHGDOP, FLEDOP, SOUTOP, SOUT_LINESOP, SERROP, SERR_LINESOP = \
        prepatch(PATCHDIR, DBDICT)
    if ORATASK == "opatch":
        MSGOP, CHGDOP, FLEDOP, SOUTOP, SOUT_LINESOP, SERROP, SERR_LINESOP = \
        opatch(PATCHDIR, DBDICT)
    if ORATASK == "postpatch":
        MSGOP, CHGDOP, FLEDOP, SOUTOP, SOUT_LINESOP, SERROP, SERR_LINESOP = \
        postpatch(DBDICT)

    MODULE.exit_json(msg=MSGOP, changed=CHGDOP, failed=FLEDOP, stdout=SOUTOP, \
           stdout_lines=SOUT_LINESOP, stderr=SERROP, stderr_lines=SERR_LINESOP)
