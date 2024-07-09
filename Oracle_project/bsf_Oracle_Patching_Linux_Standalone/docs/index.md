Oracle Patching on Linux
------------------------

Summary :
---------
“This ansible automation enables ORACLE database Patching via Ansible Tower.  It works on ORACLE 12 / 18 / 19 versions. It can reduce manual work and human errors significantly by more than 95% thereby freeing the team for higher value add work.”

Benefits :
----------
       + Manual efforts can be reduced to more than 95%
       + There is no human intervention required, reduces human errors
       + It works on all the versions that are most used in market (12/18/19).
       + Writing into modules help to easy in modifying the code and reusability.
       + Anyone can patch – No skill required to patch
       + Automation aligned to organization’s direction

Requirements:
-------------
        + Oracle installed on Linux

Variables:
---------
#Oracle user

oracleuser: "oracle"


#temp directory for ansible.If not available, it will be created

ora_tempdir: "/tmp/oraansiblepatch"


#Patch downloaded directory

ora_patchdir: "/home/oracle/30593149"


Playbook:
---------
oraclelinuxpatching.yml
