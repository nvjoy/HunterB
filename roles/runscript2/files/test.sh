#touch /tmp/standby.complete
#chmod -f 777 /tmp/standby.complete
#ls /tmp/standby.complete

#/igs_swdepot/igs/MidrangeDBAServices/DB2/V11.5_Linux/SpecialBuild_requested_upgrades/db2_11.1.4.6_SB/universal/db2_install -b /opt/IBM/db2/V11.1 -p SERVER -l /tmp/install_db2.log -n -y

#/opt/IBM/db2/V11.1/instance/db2iupgrade -u db2udf db2npoc
#startrpdomain db2_hadr_domian
#echo "This is a test script"
#rm -rf /tmp/*.complete
cd /igs_swdepot/igs/MidrangeDBAServices/DB2/v11.5.8
tar -xvf special_23839_v11.5.8_linuxx64_universal_fixpack.tar.gz
chmod -R 755 universal