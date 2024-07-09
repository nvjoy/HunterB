# Synopsis:

This role (oracle psu patch) is designed to automate Oracle Database Patching via Ansible Tower. The module supports Oracle 12c, 18c, and 19c versions.</br>
The module is designed to run on `standalone` Oracle Database instances and does not support RAC infrastructure.</br>
The module will apply Oracle Patch to all the databases under the provided Home.</br>
It can reduce manual work and human errors significantly by more than 95% thereby freeing the team for higher value add work.</br>

The module is integrated Slack notification with webhook. For any successful and failure message Slack notification will push the notification to dedicated slack channel.

# Variables:

Parameter   | Default | Comments
------------|---------|-----------
oratab_path | /etc/oratab | Mandatory - oratab file path on the endpoint
oracleuser	| oracle | Mandatory - OS user for oracle database on the endpoint
oraclegroup | dba | Mandatory - OS group for oracle user on the endpoint
ora_home  	| - | Mandatory - Oracle Home path required. Patch will be applied to the provided ORACLE_HOME. example: /ora001/home/19c
archiveextension | zip | Mandatory - extension for archive process
unarchive_patch_file_required	| false | Optional - set this parameter to 'true' if oracle psu patch file unzip is required on the endpoint. **example: /DBA/dba_admin/newpatch_test/33567270/33561310**
patch_file_loc_source | - | Mandatory - oracle psu patch zip file location on endpoint as source. **example: /DBA/dba_admin/newpatch_test/p33567270_190000_Linux-x86-64.zip**
patch_file_loc_dest	| - | Mandatory - oracle psu patch unzip file location on endpoint as destination. **example: /DBA/dba_admin/newpatch_test/**
opatchutility_file_location | - | Mandatory - oracle psu opatch patch zip file location on endpoint as source. unzip will be perform at the oracle_home location by default. **example: /DBA/dba_admin/newpatch_test/p6880880_190000_Linux-x86-64.zip**
ora_backup_required	| true | Mandatory - variable to initiate oracle home and opatch utility backup on the endpoint. set this variable to 'false' if backup not required
ora_backup_loc_input | default | Mandatory - variable to provide the backup location if `ora_backup_required: true`. Default - Backup will be perform at Oracle Home `ora_home` location. parameters need to passed is either `default or custom`.
ora_backup_loc	| - | Mandatory - if `ora_backup_loc_input: custom`, custom backup location has to be provided. Custom - Backup will be perform at custom location provided by the user. Required permission has to be set by the sme to perform backup at custom location provided. example: /DBA/dba_admin/newpatch_test
ora_patchdir | - | Mandatory - variable to provide exact patch location. orapatch module will pick the patch provided under `ora_patchdir` location. Dependent on `patch_file_loc_dest` **example: /DBA/dba_admin/newpatch_test/33567270/33561310**
ora_tempdir	| /tmp/oraansiblepatch_temp | Optional - Temp folder location for oracle patch role execution on the endpoint
oracle_psu_patch_version | - | Optional - Oracle Database PSU patch title. example: DATABASE APR 2021
slack_notification	| True | Mandatory - variable to enable slack notification if required.
slack_webhook_url | - | Mandatory - variable to initiate slack notification. Weebhook url for the slack channel where notification need to be posted. parameter is required only if `slack_notification: true`. **example: https://hooks.slack.com/workflows/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**

# Results from execution:

Return Code Group        | Return Code | Comments
-------------------------|-------------|------------
success                  | 0 | Successful execution of oracle psu patch role
misconfiguration         | 101 | ansible_limit or localhost entry missing in Job LIMIT field in Template
misconfiguration         | 102 | Tower Credentials not provided in Job Template
misconfiguration         | 103 | Slack notification role failed. Verify the error message and take action accordingly
misconfiguration         | 301 | DB SID and Home entry missing in Oratab file. No record found in oratab file for Oracle Home: `ora_home`
misconfiguration         | 302 | Error while performing Temp directory creation on endpoint. Verify error: `ora_temp_create` output message
misconfiguration         | 303 | Error while performing Unarchive Oracle PSU Patch file on the endpoint. Verify Unzip Patch directory error: `ora_patchdirectory_unarchive` output message
misconfiguration         | 304 | Error while performing Unarchive Oracle OPatch utility Patch file under Oracle Home location on the endpoint. Verify Unzip OPatch utility error: `ora_opatchutility_unarchive` output message
misconfiguration         | 305 | Error while gathering information from oratab file. Verify Error: `oradb` output message
misconfiguration         | 306 | Oracle Database not in Open state. Verify the error in logfile and bring database to Open mode. Error: `oradbinfo` output message
misconfiguration         | 307 | Error while performing PrePatch validation. Verify logfile for more information Error for PrePatch validation: `prepatch` output message
misconfiguration         | 308 | Error while performing backup of Oracle Home. Verify Oracle Home backup error: `backup_ora_home` output message
misconfiguration         | 309 | Error while performing backup of OPatch uitlity. Verify Oracle OPatch utility backup error: `backup_opatch` output message
misconfiguration         | 310 | Failed to get Invalid objects details from the database. Verify logfile and perform correction Error for Inavlid objects: `getdbobjectinvalids` output message
misconfiguration         | 311 | One or more options in DBA registry is in Invalid status. Verify logfile for more information. Error for DBA Registry status: `oradbregistryvalidate` output message
misconfiguration         | 312 |   Error while performing Database shutdown. Check logfile for further details and take action accordingly. Error message for Database shutdown: `stopdatabase` output message
misconfiguration         | 313 | Error while performing Listener shutdown. Check logfile for further details and take action accordingly. Error message for Listener shutdown: `stoplistener` output message
misconfiguration         | 314 | Error while performing Oracle PSU Patch apply on the endpoints. Check logfile for further details and take action accordingly. Error message for Opatch apply: `opatch` output message
misconfiguration         | 315 | Error while performing Database startup. Check logfile for further details and take action accordingly. Error message for Database startup: `startdatabase` output message
misconfiguration         | 316 | Error while performing Oracle PSU Post Patch operation (Database -verbose). Check logfile for further details and take action accordingly. Error message for Oracle PSU Post Patch operation: `postpatch` output message
misconfiguration         | 317 | Error while performing Listener startup. Check logfile for further details and take action accordingly. Error message for Listener startup: `startlistener` output message
misconfiguration         | 318 | Error while fetching patch details from Database. Check logfile for further details and take action accordingly. Error message for sqlpatch_registry: `getdbsqlpatchregistry_output` output message
misconfiguration         | 316 | Error while performing Oracle PSU Post Patch operation (Database -verbose). Check logfile for further details and take action accordingly. Error message for Oracle PSU Post Patch operation: `postpatch` output message

# Procedure:

  1. The module will start with running the pre-checks which include:</br>
    - Get the list of all running databases under the provided `ora_home`</br>
    - Unzip Oracle PSU Patch directory</br>
    - Unzip/update OPatch utility binaries to the latest</br>
    - Perform Oracle Home and OPatch utility backup</br>
    - Create Temp directory to store the logfile/sqlfile</br>
  2. The module will continue to gather the required Database and Listener details</br>
  3. Check for Invalid objects in the Database and run utlrp package</br>
  4. Next, module will check for the status of DBA registry options</br>
  5. If all DBA registry options information is in Valid state, now next step would be to run the pre-patch validation:</br>
    - Check for Patch conflict</br>
    - Check for if Patch is already applied</br>
    - Patch directory validation</br>
     **Note:** If any of the DBA registry status is "INVALID" the process will end and exit.
  6. The module will start with Oracle Patching activity:</br>
    - Stop Database and Listener</br>
    - Apply Oracle Patch</br>
    - Start Database</br>
    - Run Post patch (Database verbose)</br>
    - Start Listener</br>
    - Check for Invalid objects in the Database and run utlrp package</br>
    - Check for DBA registry options status</br>
    - Check details from sqlpatch registry for the latest patch applied</br>

# Deployment

**Note:**</br>
 * The variables described in the `Variables` section can be passed as Extra Variables in the job template if the default values  are not suitable.
 * Variables marked as 'Mandatory' need to be passed by sme, if no default value provided.
 * For the variable which requires location/path need to be provided under Extra Variables.
 * Patch module will take only database entry for the provided `ora_home` parameter as per `variables` section. Any other "ORACLE_HOME" databases entries should be commented(#) under `oratab` file.
 * If the module fails at any step, the patching process will be aborted.

**Example parameters:**

 * patch_file_loc_source: "/DBA/dba_admin/newpatch_test/p33567270_190000_Linux-x86-64.zip"
 * patch_file_loc_dest: "/DBA/dba_admin/newpatch_test/"
 * ora_patchdir: "/DBA/dba_admin/newpatch_test/33567270/33561310"
 * ora_home: "/ora001/home/19c"
 * opatchutility_file_location: "/DBA/dba_admin/newpatch_test/p6880880_190000_Linux-x86-64.zip"
 * ora_backup_loc_input: "custom"
 * ora_backup_loc: "/DBA/dba_admin/newpatch_test"
 * oracle_psu_patch_version: "33567270"
 * unarchive_patch_file_required: true
 * ora_backup_required: true
 * slack_notification: true

**Environments Tested**
* The playbooks have been tested on Linux Standalone single Oracle 12c Database instance.
* The playbooks have been tested on Linux Standalone server with multiple Oracle 19c Database instances.

# Support:

 * This is a CACM managed solution, please raise any requests or issues at: [COMMON REPOSITORY](https://github.kyndryl.net/Continuous-Engineering/CACM_Common_Repository/issues)
 * For General Queries/Playbook help implementation you could try the slack channel: [#continuous-engineering](https://kyndryl.slack.com/archives/C028DSA63TQ), [#cacm](https://kyndryl.slack.com/archives/C02C37022LD)
 * Author Information: Ponit Kaur

# Known problems and limitations

 * The module only support Standalone Oracle Database on Linux platform.
 * Oracle Patch has to be downloaded from Oracle support and need to be placed on server before.
 * Any commented(#) database in Oratab file will not be included in Patching activity
 * If an error is encountered and you restart the process, the module will not automatically start previously stopped services. The module   will note stopped services at the beginning of the process and it will leave the services stopped at the end of execution. Due to the nature of how Oracle patching is performed, in some cases if something breaks a manual intervention might be needed. In other words if you restart the Ansible process do not expect to continue from where it stopped.

# Prerequisites

 * Standard Ansible prerequisites and PowerShell version 3.0 or above.
 * Ansible user ID should have permissions to connect to the Oracle instance.
 * Sufficient space should be available under Home and Temp directory provided.
 * Oracle Patch has to be downloaded from Oracle Support and need to be placed on the server.

# License:
 [Kyndryl Intellectual Property](https://github.kyndryl.net/Continuous-Engineering/CE-Documentation/blob/master/files/LICENSE.md)
