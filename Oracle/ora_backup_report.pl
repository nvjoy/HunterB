# First refresh the oratab entries and pmons # just use the existing .oratab for list to refresh # $BASE='/igs_swdepot/igs/MidrangeDBAServices/DB2/db2info';
open(ERR,'>',"$BASE/reports/oracle_daily_report.err");

print "Phase 1: Refreshing oratab, pmon, cron_sched, rman_backup.lst, rman_auxcat.lst lists\n";
while(<$BASE/servers/*.oratab>) {
  print "eval $_\n";
  (undef,$server)=split /vers\//,$_;
  ($server)=split /\./,$server;
  print "server=$server\n";
  `ssh $server \'grep -v ^\$ /etc/oratab | grep -v ^# | grep -v ^*\' > $BASE/servers/temp.oracle.oratab`;
  if(`wc -l $BASE/servers/temp.oracle.oratab` > 0) {
     `mv $BASE/servers/temp.oracle.oratab $BASE/servers/$server.oracle.oratab`;
  } else {
    print ERR "Oratab missing or empty for $server\n";
    `mv $BASE/servers/$server.oracle.oratab $BASE/prev/$server.oracle.oratab`;
  }
  
  `ssh $server \'ps -ef | grep pmon | grep -v grep\' > $BASE/servers/temp.oracle.pmon`;
  if(`wc -l $BASE/servers/temp.oracle.pmon` > 0) {
    `mv $BASE/servers/temp.oracle.pmon $BASE/servers/$server.oracle.pmon`;
  } else {
    print ERR "No oracle pmons on $server\n";
    `mv $BASE/servers/$server.oracle.pmon $BASE/prev/$server.oracle.pmon`;
  }
  `ssh $server \'cat \~oracle/cron_sched\' > $BASE/servers/temp.oracle.cron_sched`;
  if(`wc -l $BASE/servers/temp.oracle.cron_sched` > 0) {
    `mv $BASE/servers/temp.oracle.cron_sched $BASE/servers/$server.oracle.cron_sched`;
  } else {
    print "unable to get cron_sched from oracle on $server\n";
    `mv $BASE/servers/$server.oracle.cron_sched $BASE/prev/$server.oracle.cron_sched`;
  }
  `ssh $server \'cat \~oracle/local/rman/backup_scripts/rman_backup.lst\' > $BASE/servers/temp.oracle.rman_backup`;
  if(`wc -l $BASE/servers/temp.oracle.rman_backup` > 0) {
    `mv $BASE/servers/temp.oracle.rman_backup $BASE/servers/$server.oracle.rman_backup`;
  } else {
    print ERR "unable to get ~oracle/local/rman/backup_scripts/rman_backup.lst from $server\n";
    `mv $BASE/servers/$server.oracle.rman_backup $BASE/prev/$server.oracle.rman_backup`;
  }
  `ssh $server 'cat ~oracle/local/rman/backup_scripts/rman_auxcat.lst' > $BASE/servers/temp.oracle.rman_auxcat`;
  if(`wc -l $BASE/servers/temp.oracle.rman_auxcat` > 0) {
    `mv $BASE/servers/temp.oracle.rman_auxcat $BASE/servers/$server.oracle.rman_auxcat`;
  } else {
    print ERR "unable to get ~oracle/local/rman/backup_scripts/rman_auxcat.lst from $server\n";
    `mv $BASE/servers/$server.oracle.rman_auxcat $BASE/prev/$server.oracle.rman_auxcat`;
  }
}
`rm -f $BASE/servers/temp.oracle.oratab`;
`rm -f $BASE/servers/temp.oracle.pmon`;
`rm -f $BASE/servers/temp.oracle.cron_sched`;
`rm -f $BASE/servers/temp.oracle.rman_backup`;
`rm -f $BASE/servers/temp.oracle.rman_auxcat`;

#
# load the oratab and build list of DBs marked with auto start = Y # print "Phase 2: Loading current oratab\n"; %ORATAB_Y; %ORATAB;
while(<$BASE/servers/*.oratab>) {
  #print "eval $_\n";
  (undef,$server)=split /vers\//,$_;
  ($server)=split /\./,$server;
  open(F,$_);
  while(<F>) {
    chomp;
    s/\s+//g;
    #print "eval2: $server:$_\n";
    @TMP=split /:/;
    #print "eval2: SID=@TMP[0]  STARTUP=@TMP[2]\n";
    #push(@ORATAB, "$server:$_");
    $ORATAB{$server . '_' . @TMP[0]}=1;
    if(@TMP[2] eq 'y' or @TMP[2] eq 'Y') {
      $ORATAB_Y{$server . '_' . @TMP[0]}=1;
    }
  }
  close(F);
}
#foreach $key (keys %ORATAB) {
#  print "ORATAB => $key\n";
#}
#foreach $key (sort (keys %ORATAB_Y)) {
#  print "ORATAB_Y : $key\n";
#}
#
#
# load the list of pmons for active databases # print "Phase 3: Loading current running pmons\n"; %ACTIVE_DB;
while(<$BASE/servers/*.pmon>) {
  #print "eval $_\n";
  (undef,$server)=split /vers\//,$_;
  ($server)=split /\./,$server;
  open(F,$_);
  while(<F>) {
    chomp;
    s/\s+$//g;
    (undef,$sid)=split /ora_pmon_/,$_;
    #print "eval2: $server Active DB =>  $sid\n";
    $ACTIVE_DB{$server . '_' . $sid}=1;
  }
  close(F);
}
#foreach $key (sort (keys %ACTIVE_DB)) { #  print "ACTIVE_DB $key\n"; #} # # future -- load rman_backup.lst and rman_auxcat.lst #

#
# Now load previous values
#
open(F,"$BASE/reports/oracle_daily_report.oratab");
%PREV_ORATAB;
while(<F>) {
  chomp;
  #print "ADDING '$_' to PREV_ORATAB\n";
  $PREV_ORATAB{$_}=1;
}
close(F);
%PREV_ORATAB_Y;
open(F,"$BASE/reports/oracle_daily_report.oratab_y");
while(<F>) {
  chomp;
  $PREV_ORATAB_Y{$_}=1;
}
close(F);
%PREV_ACTIVE_DB;
open(F,"$BASE/reports/oracle_daily_report.active_db");
while(<F>) {
  chomp;
  $PREV_ACTIVE_DB{$_}=1;
}
close(F);

foreach $key (sort keys %ORATAB) {
  if( $PREV_ORATAB{$key}!=1 ) {
    print "New Entry in ORATAB: $key\n"; 
    push(@ORATAB_CHANGE, "New Entry in ORATAB: $key");
  }
}
foreach $key (sort keys %PREV_ORATAB) {
  if( $ORATAB{$key}!=1 ) {
    print "Entry DELETED from ORATAB: $key\n";
    push(@ORATAB_CHANGE, "Entry DELETED from ORATAB: $key");
  }
}
foreach $key (sort keys %ORATAB_Y) {
  if( $PREV_ORATAB_Y{$key}!=1 ) {
    print "New Entry in ORATAB with for autostart: $key\n"; 
    push(@ORATAB_Y_CHANGE, "New Entry in ORATAB with for autostart: $key");
  }
}
foreach $key (sort keys %PREV_ORATAB_Y) {
  if( $ORATAB_Y{$key}!=1 ) {
    print "Entry Chaged/Deleted from ORATAB with for autostart: $key\n";
    push(@ORATAB_Y_CHANGE, "Entry Chaged/Deleted from ORATAB with for autostart: $key");
  }
}
foreach $key (sort keys %ACTIVE_DB) {
  if( $PREV_ACTIVE_DB{$key}!=1 ) {
    print "New ACTIVE DB: $key\n"; 
    push(@ACTIVE_DB_CHANGE, "New ACTIVE DB: $key");
  }
}
foreach $key (sort keys %PREV_ACTIVE_DB) {
  if( $ACTIVE_DB{$key}!=1 ) {
    print "DB NOT ACTIVE today: $key\n";
    push(@ACTIVE_DB_CHANGE, "DB NOT ACTIVE today: $key");
  }
}

#
# Start daily report
#
'mv $BASE/reports/oracle_daily_report.txt $BASE/reports/oracle_daily_report.txt.prev';
$FULL_DATE=`date`;
chomp($CURDAY=`date +%j`);
$PRVDAY=$CURDAY-1;
open(REPORT,'>', "$BASE/reports/oracle_daily_report.txt");
print REPORT "\n=====================================================================\n\n";
print REPORT   " Oracle Daily Report generated $FULL_DATE\n";
print REPORT   "   Current Day of Year is $CURDAY\n";
print REPORT "=====================================================================\n";
print REPORT "\n--BEGIN Comparison of ORATAB and PMONS since last run--\n\n";
if(@ACTIVE_DB_CHANGE) {
  while($line=shift(@ACTIVE_DB_CHANGE)) {
    print REPORT "ACTIVE DB CHANGE:        $line\n";
  }
} else {
    print REPORT "ACTIVE DB CHANGE:        NONE - no changes\n";
}
if(@ORATAB_Y_CHANGE) {
  while($line=shift(@ORATAB_Y_CHANGE)) {
    print REPORT "ORATAB AUTOSTART CHANGE: $line\n";
  }
} else {
    print REPORT "ORATAB AUTOSTART CHANGE: NONE - no changes\n"; }
if(@ORATAB_CHANGE) {
  while($line=shift(@ORATAB_CHANGE)) {
    print REPORT "ORATAB CHANGE:           $line\n";
  }
} else {
    print REPORT "ORATAB CHANGE:           NONE - no changes\n";
}
print REPORT "\n--END   Comparison of ORATAB and PMONS since last run--\n";

print REPORT "\n=====================================================================\n";
#
# get backup information
#


print "Phase 4: Get current backup metrics\n";

use Switch;

$year=`date +%Y`;
chomp($year);
chomp($CURMON=`date +%m`);
$prev_year=$year-1;

switch ($CURMON) {
    case "01"    { $prev_mth="01" }
    case "02"    { $prev_mth="01" }
    case "03"    { $prev_mth="02" }
    case "04"    { $prev_mth="03" }
    case "05"    { $prev_mth="04" }
    case "06"    { $prev_mth="05" }
    case "07"    { $prev_mth="06" }
    case "08"    { $prev_mth="07" }
    case "09"    { $prev_mth="08" }
        else         { $prev_mth=$CURMON-1 }
}


while(<$BASE/servers/*.oracle.bumtx>) {
  chomp;
  `rm -f $_`;
}
while(<$BASE/servers/*.pmon>) {
  (undef,$server)=split /vers\//,$_;
  ($server)=split /\./,$server;
  print "processing server $server\n";
  `ssh $server "grep -v noaction \~oracle/local/rman/logs/bumtx*.csv | grep -v $prev_year | grep -e $year\/$CURMON -e $year\/$prev_mth" > $BASE/servers/$server.oracle.bumtx`;
}

##
## evaluation backups
##
print "Phase 5: evaluate backup metrics\n"; %LAST_FULL_PRD; %LAST_INCR_PRD; %LAST_ARCH_PRD; %LAST_SYNC_PRD; %LAST_FULL_DEV; %LAST_INCR_DEV; %LAST_ARCH_DEV; %LAST_SYNC_DEV; %LAST_FULL_TRL; %LAST_INCR_TRL; %LAST_ARCH_TRL; %LAST_SYNC_TRL;

while(<$BASE/servers/*.oracle.bumtx>) {
 chomp;
 (undef,$server)=split /vers\//,$_;
 ($server)=split /\./,$server;
 print "evaluation bumtx for $server\n";  open(M,$_);
 while(<M>) {
   chomp;
   @TMP1=split /\,/;
   @TMP2=split /"/;
   @TMP3=split /:/,@TMP1[0];
   @TMP4=split /\//,@TMP3[0];
   $file=pop(@TMP4);
   ($file)=split /\./,$file;
   $db=@TMP3[1];
   $status=@TMP1[1];
   $begin=@TMP1[2];
   $end=@TMP1[3];
   $seconds=@TMP1[4];
  
   # check if $db is active

   `grep $db $BASE/servers/$server.oracle.pmon > $BASE/servers/temp.db.active`;

   if(`wc -l $BASE/servers/temp.db.active` > 0) {

   # type1 = backup opration: 0,1,arch,resync
   $type1=@TMP1[5];
   # type2 = method: database,tape
   $type2=@TMP1[6];
   # type3 = backup option: hot,cold
   $type3=@TMP1[7];
   # parm1 = current option being processed: 0 tape hot|0 tape cold|
   #                                         1 tape hot|1,cum tape hot|
   #                                         arch tape hot|resync|
   $parm1=@TMP2[1];
   # parm2 = complete rman command
   $parm2=@TMP2[3];
   #print "$server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~\n";
 
   (undef,$doy)=split /bumtx/,$file;

   if($server=~/p0/ or $server=~/p1/) {
     #print "PROD => $server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~\n";
     if($status eq 'success') {
       #print "PROD SUCCESS Type($type) => $server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~\n";
       if($type1 eq '0') {
         print "PROD SUCCESS FULL => $server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~\n";
         $LAST_FULL_PRD{$server . '_' . $db}=$doy;
       } elsif($type1 eq '1') {
         $LAST_INCR_PRD{$server . '_' . $db}=$doy;
       } elsif($type1 eq 'arch') {
         $LAST_ARCH_PRD{$server . '_' . $db}=$doy;
       } elsif($type1 eq 'resync') {
         $LAST_SYNC_PRD{$server . '_' . $db}=$doy;
       }
     } elsif($status eq 'failure' or $status eq 'locked') {
       if($type1 eq '0') {
         push(@PRD_FULL_FAIL,"$server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~");
       } elsif($type1 eq '1') {
         push(@PRD_INCR_FAIL,"$server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~");
       } elsif($type1 eq 'arch') {
         push(@PRD_ARCH_FAIL,"$server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~");
       } elsif($type1 eq 'resync') {
         push(@PRD_SYNC_FAIL,"$server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~");
       }
     }
   } elsif($server=~/d0/) {
     #print "DEV => $server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~\n";
     if($status eq 'success') {
       if($type1 eq '0') {
         print "DEV SUCCESS FULL => $server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~\n";
         $LAST_FULL_DEV{$server . '_' . $db}=$doy;
       } elsif($type1 eq '1') {
         $LAST_INCR_DEV{$server . '_' . $db}=$doy;
       } elsif($type1 eq 'arch') {
         $LAST_ARCH_DEV{$server . '_' . $db}=$doy;
       } elsif($type1 eq 'resync') {
         $LAST_SYNC_DEV{$server . '_' . $db}=$doy;
       }
     } elsif($status eq 'failure' or $status eq 'locked') {
       if($type1 eq '0') {
         push(@DEV_FULL_FAIL,"$server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~");
       } elsif($type1 eq '1') {
         push(@DEV_INCR_FAIL,"$server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~");
       } elsif($type1 eq 'arch') {
         push(@DEV_ARCH_FAIL,"$server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~");
       } elsif($type1 eq 'resync') {
         push(@DEV_SYNC_FAIL,"$server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~");
       }
     }
   } else {
     #print "TRN/TST/TRL=> $server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~\n";
     if($status eq 'success') {
       if($type1 eq '0') {
         print "TRL SUCCESS FULL => $server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~\n";
         $LAST_FULL_TRL{$server . '_' . $db}=$doy;
       } elsif($type1 eq '1') {
         $LAST_INCR_TRL{$server . '_' . $db}=$doy;
       } elsif($type1 eq 'arch') {
         $LAST_ARCH_TRL{$server . '_' . $db}=$doy;
       } elsif($type1 eq 'resync') {
         $LAST_SYNC_TRL{$server . '_' . $db}=$doy;
       }
     } elsif($status eq 'failure' or $status eq 'locked') {
       if($type1 eq '0') {
         push(@TRL_FULL_FAIL,"$server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~");
       } elsif($type1 eq '1') {
         push(@TRL_INCR_FAIL,"$server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~");
       } elsif($type1 eq 'arch') {
         push(@TRL_ARCH_FAIL,"$server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~");
       } elsif($type1 eq 'resync') {
         push(@TRL_SYNC_FAIL,"$server~$file~$db~$status~$begin~$end~$seconds~$type1~$type2~$type3~$parm1~$parm2~");
       }
     }
   } 
   
 }
 }
 close(M);
}



#foreach $key (keys %LAST_FULL_PRD) {
#  print "LAST FULL PRD: $key \t= $LAST_FULL_PRD{$key}\n"; #} #foreach $key (keys %LAST_INCR_PRD) { #  print "LAST INCR PRD: $key \t= $LAST_INCR_PRD{$key}\n"; #} #foreach $key (keys %LAST_ARCH_PRD) { #  print "LAST ARCH PRD: $key \t= $LAST_ARCH_PRD{$key}\n"; #} #foreach $key (keys %LAST_SYNC_PRD) { #  print "LAST SYNC PRD: $key \t= $LAST_SYNC_PRD{$key}\n"; #} #foreach $key (keys %LAST_FULL_DEV) { #  print "LAST FULL DEV: $key \t= $LAST_FULL_DEV{$key}\n"; #} #foreach $key (keys %LAST_INCR_DEV) { #  print "LAST INCR DEV: $key \t= $LAST_INCR_DEV{$key}\n"; #} #foreach $key (keys %LAST_ARCH_DEV) { #  print "LAST ARCH DEV: $key \t= $LAST_ARCH_DEV{$key}\n"; #} #foreach $key (keys %LAST_SYNC_DEV) { #  print "LAST SYNC DEV: $key \t= $LAST_SYNC_DEV{$key}\n"; #} #foreach $key (keys %LAST_FULL_TRL) { #  print "LAST FULL TRL: $key \t= $LAST_FULL_TRL{$key}\n"; #} #foreach $key (keys %LAST_INCR_TRL) { #  print "LAST INCR TRL: $key \t= $LAST_INCR_TRL{$key}\n"; #} #foreach $key (keys %LAST_ARCH_TRL) { #  print "LAST ARCH TRL: $key \t= $LAST_ARCH_TRL{$key}\n"; #} #foreach $key (keys %LAST_SYNC_TRL) { #  print "LAST SYNC TRL: $key \t= $LAST_SYNC_TRL{$key}\n"; #}

$failure=0;
print REPORT "--BEGIN PROD  BACKUP FAILURES for Current($CURDAY) and Previous($PRVDAY) days (Full/Incr/Arch)--\n";
foreach $line (@PRD_FULL_FAIL) {
  print "PRD FULL Fail: $line\n";
  @TMP=split /~/,$line;
  (undef,$doy)=split /bumtx/,@TMP[1];
  if($doy == $CURDAY or $doy == ($CURDAY-1)){
    print REPORT "PROD FULL FAIL: @TMP[0]\t@TMP[2]\t@TMP[4]\t@TMP[5]\t@TMP[3]\t\n";
    $failure=1;
  }
}
if($failure==0) {
  print REPORT "PROD FULL FAIL: NONE\n";
} else {
  $failure=0;  
}

foreach $line (@PRD_INCR_FAIL) {
  print "PRD INCR Fail: $line\n";
  @TMP=split /~/,$line;
  (undef,$doy)=split /bumtx/,@TMP[1];
  if($doy == $CURDAY or $doy == ($CURDAY-1)){
    print REPORT "PROD INCR FAIL: @TMP[0]\t@TMP[2]\t@TMP[4]\t@TMP[5]\t@TMP[3]\t\n";
    $failure=1;
  }
}
if($failure==0) {
  print REPORT "PROD INCR FAIL: NONE\n";
} else {
  $failure=0;  
}
foreach $line (@PRD_ARCH_FAIL) {
  print "PRD ARCH Fail: $line\n";
  @TMP=split /~/,$line;
  (undef,$doy)=split /bumtx/,@TMP[1];
  if($doy == $CURDAY or $doy == ($CURDAY-1)){
    print REPORT "PROD ARCH FAIL: @TMP[0]\t@TMP[2]\t@TMP[4]\t@TMP[5]\t@TMP[3]\t\n";
    $failure=1;
  }
}
if($failure==0) {
  print REPORT "PROD ARCH FAIL: NONE\n";
} else {
  $failure=0;  
}
print REPORT "--END   PROD  BACKUP FAILURES for Current($CURDAY) and Previous($PRVDAY) days (Full/Incr/Arch)--\n";

print REPORT "--BEGIN TRIAL BACKUP FAILURES for Current($CURDAY) and Previous($PRVDAY) days (Full/Incr/Arch)--\n";
foreach $line (@TRL_FULL_FAIL) {
  print "TRL FULL Fail: $line\n";
  @TMP=split /~/,$line;
  (undef,$doy)=split /bumtx/,@TMP[1];
  if($doy == $CURDAY or $doy == ($CURDAY-1)){
    print REPORT "TRIAL FULL FAIL: @TMP[0]\t@TMP[2]\t@TMP[4]\t@TMP[5]\t@TMP[3]\t\n";
    $failure=1;
  }
}
if($failure==0) {
  print REPORT "TRIAL FULL FAIL: NONE\n";
} else {
  $failure=0;  
}

foreach $line (@TRL_INCR_FAIL) {
  print "TRL INCR Fail: $line\n";
  @TMP=split /~/,$line;
  (undef,$doy)=split /bumtx/,@TMP[1];
  if($doy == $CURDAY or $doy == ($CURDAY-1)){
    print REPORT "TRIAL INCR FAIL: @TMP[0]\t@TMP[2]\t@TMP[4]\t@TMP[5]\t@TMP[3]\t\n";
    $failure=1;
  }
}
if($failure==0) {
  print REPORT "TRIAL INCR FAIL: NONE\n";
} else {
  $failure=0;  
}
foreach $line (@TRL_ARCH_FAIL) {
  print "TRL ARCH Fail: $line\n";
  @TMP=split /~/,$line;
  (undef,$doy)=split /bumtx/,@TMP[1];
  if($doy == $CURDAY or $doy == ($CURDAY-1)){
    print REPORT "TRIAL ARCH FAIL: @TMP[0]\t@TMP[2]\t@TMP[4]\t@TMP[5]\t@TMP[3]\t\n";
    $failure=1;
  }
}
if($failure==0) {
  print REPORT "TRIAL ARCH FAIL: NONE\n";
} else {
  $failure=0;  
}
print REPORT "--END   TRIAL BACKUP FAILURES for Current($CURDAY) and Previous($PRVDAY) days (Full/Incr/Arch)--\n";

print REPORT "--BEGIN DEV   BACKUP FAILURES for Current($CURDAY) and Previous($PRVDAY) days (Full/Incr/Arch)--\n";
foreach $line (@DEV_FULL_FAIL) {
  print "DEV FULL Fail: $line\n";
  @TMP=split /~/,$line;
  (undef,$doy)=split /bumtx/,@TMP[1];
  if($doy == $CURDAY or $doy == ($CURDAY-1)){
    print REPORT "DEV   FULL FAIL: @TMP[0]\t@TMP[2]\t@TMP[4]\t@TMP[5]\t@TMP[3]\t\n";
    $failure=1;
  }
}
if($failure==0) {
  print REPORT "DEV   FULL FAIL: NONE\n";
} else {
  $failure=0;  
}

foreach $line (@DEV_INCR_FAIL) {
  print "DEV INCR Fail: $line\n";
  @TMP=split /~/,$line;
  (undef,$doy)=split /bumtx/,@TMP[1];
  if($doy == $CURDAY or $doy == ($CURDAY-1)){
    print REPORT "DEV   INCR FAIL: @TMP[0]\t@TMP[2]\t@TMP[4]\t@TMP[5]\t@TMP[3]\t\n";
    $failure=1;
  }
}
if($failure==0) {
  print REPORT "DEV   INCR FAIL: NONE\n";
} else {
  $failure=0;  
}
foreach $line (@DEV_ARCH_FAIL) {
  print "DEV ARCH Fail: $line\n";
  @TMP=split /~/,$line;
  (undef,$doy)=split /bumtx/,@TMP[1];
  if($doy == $CURDAY or $doy == ($CURDAY-1)){
    print REPORT "DEV   ARCH FAIL: @TMP[0]\t@TMP[2]\t@TMP[4]\t@TMP[5]\t@TMP[3]\t\n";
    $failure=1;
  }
}
if($failure==0) {
  print REPORT "DEV   ARCH FAIL: NONE\n";
} else {
  $failure=0;  
}
print REPORT "--END   DEV   BACKUP FAILURES for Current($CURDAY) and Previous($PRVDAY) days (Full/Incr/Arch)--\n";

print REPORT "\n=====================================================================\n";
print REPORT "  **Missing Backups**\n";
print REPORT "\n=====================================================================\n";

open(FILE,"$BASE/config/oracle.server.exclude");
@list=<FILE>;
close FILE;

foreach $key (keys %ACTIVE_DB) {
  @TMP=split /_/,$key;
  next unless (@TMP[0]=~/p0/ or @TMP[0]=~/p1/);
  if ((grep{/^$key$/} @list) eq 0) {
  if( ! exists $LAST_FULL_PRD{$key} ) {
    if( ! exists $LAST_INCR_PRD{$key} ) {
      print REPORT "NO BACKUP FOR PROD  DB: $key\n\n";
    } 
  }
  }
}
foreach $key (keys %ACTIVE_DB) {
  @TMP=split /_/,$key;
  next if(@TMP[0]=~/p0/ or @TMP[0]=~/p1/ or @TMP[0]=~/d0/);
  if ((grep{/$key/} @list) eq 0) {
  if( ! exists $LAST_FULL_TRL{$key} ) {
    if( ! exists $LAST_INCR_TRL{$key} ) {
      print REPORT "NO BACKUP FOR TRIAL DB: $key\n\n";
    } 
  }
  }
}
foreach $key (keys %ACTIVE_DB) {
  @TMP=split /_/,$key;
  next unless @TMP[0]=~/d0/;
  if ((grep{/$key/} @list) eq 0) {
  if( ! exists $LAST_FULL_DEV{$key} ) {
    if( ! exists $LAST_INCR_DEV{$key} ) {
      print REPORT "NO BACKUP FOR DEV   DB: $key\n\n";
    } 
  }
  }
}

print REPORT "--BEGIN Missing PROD  Backups (Full/Incr) > 2 Days--\n\n";
foreach $key (sort (keys %LAST_FULL_PRD)) {
  if( ($CURDAY - $LAST_FULL_PRD{$key}) > 1 and ($CURDAY - $LAST_INCR_PRD{$key}) > 1)  {
      print "$key missing backup > 2 days\n\n" ;
      if(exists $LAST_INCR_PRD{$key}) {
        print REPORT "PROD DB $key Last FULL on $LAST_FULL_PRD{$key} and Last INCR on $LAST_INCR_PRD{$key}\n\n";
      } else {
        print REPORT "PROD DB $key Last FULL on $LAST_FULL_PRD{$key} - no INCR\n\n";
      }
  }  
}
print REPORT "--END   Missing PROD  Backups (Full/Incr) > 2 Days--\n\n\n";
print REPORT "--BEGIN Missing TRIAL Backups (Full/Incr) > 2 Days--\n\n";
foreach $key (sort (keys %LAST_FULL_TRL)) {
  if( ($CURDAY - $LAST_FULL_TRL{$key}) > 1 and ($CURDAY - $LAST_INCR_TRL{$key}) > 1)  {
      print "$key missing backup > 2 days\n\n" ;
      if(exists $LAST_INCR_TRL{$key}) {
        print REPORT "TRIAL DB $key Last FULL on $LAST_FULL_TRL{$key} and Last INCR on $LAST_INCR_TRL{$key}\n\n";
      } else {
        print REPORT "TRIAL DB $key Last FULL on $LAST_FULL_TRL{$key} - no INCR\n\n";
      }
  }  
}
print REPORT "--END   Missing TRIAL Backups (Full/Incr) > 2 Days--\n\n\n";
print REPORT "--BEGIN Missing DEV   Backups (Full/Incr) > 7 Days--\n\n";
foreach $key (sort (keys %LAST_FULL_DEV)) {
  if( ($CURDAY - $LAST_FULL_DEV{$key}) > 6 and ($CURDAY - $LAST_INCR_DEV{$key}) > 1)  {
      print "$key missing backup > 2 days\n\n" ;
      if(exists $LAST_INCR_DEV{$key}) {
        print REPORT "DEV DB $key Last FULL on $LAST_FULL_DEV{$key} and Last INCR on $LAST_INCR_DEV{$key}\n\n";
      } else {
        print REPORT "DEV DB $key Last FULL on $LAST_FULL_DEV{$key} - no INCR\n\n";
      }
  }  
}
print REPORT "--END   Missing DEV   Backups (Full/Incr) > 7 Days--\n\n\n";


print REPORT "\n=====================================================================\n";
print REPORT "  **Exempt Backups\n";
print REPORT "\n=====================================================================\n";

open(FILE,"$BASE/config/oracle.server.exclude");
while (<FILE>) {
print REPORT "$_";
}
close FILE;


print REPORT "\n=====================================================================\n";
print REPORT "  **Last Good Backup\n";
print REPORT "\n=====================================================================\n";


print REPORT "--BEGIN Last Good Backup PROD --\n";
foreach $key (sort(keys %LAST_FULL_PRD)) {
  if(exists $LAST_INCR_PRD{$key}) {
     if(exists $LAST_ARCH_PRD{$key}) {
       print REPORT "LAST Good Backups PROD: $key\tFull($LAST_FULL_PRD{$key})\tINCR($LAST_INCR_PRD{$key})\tARCH($LAST_ARCH_PRD{$key})\n";
     } else {
       print REPORT "LAST Good Backups PROD: $key\tFull($LAST_FULL_PRD{$key})\tINCR($LAST_INCR_PRD{$key})\tARCH(noarch)\n";
     }
  } else {
     if(exists $LAST_ARCH_PRD{$key}) {
       print REPORT "LAST Good Backups PROD: $key\tFull($LAST_FULL_PRD{$key})\tINCR(none)\tARCH($LAST_ARCH_PRD{$key})\n";
     } else {
       print REPORT "LAST Good Backups PROD: $key\tFull($LAST_FULL_PRD{$key})\tINCR(none)\tARCH(noarch)\n";
     }
  }
}
print REPORT "--END   Last Good Backup PROD --\n";

print REPORT "--BEGIN Last Good Backup TRIAL--\n";
foreach $key (sort(keys %LAST_FULL_TRL)) {
  if(exists $LAST_INCR_TRL{$key}) {
     if(exists $LAST_ARCH_TRL{$key}) {
       print REPORT "LAST Good Backups TRIAL: $key\tFull($LAST_FULL_TRL{$key})\tINCR($LAST_INCR_TRL{$key})\tARCH($LAST_ARCH_TRL{$key})\n";
     } else {
       print REPORT "LAST Good Backups TRIAL: $key\tFull($LAST_FULL_TRL{$key})\tINCR($LAST_INCR_TRL{$key})\tARCH(noarch)\n";
     }
  } else {
     if(exists $LAST_ARCH_TRL{$key}) {
       print REPORT "LAST Good Backups TRIAL: $key\tFull($LAST_FULL_TRL{$key})\tINCR(none)\tARCH($LAST_ARCH_TRL{$key})\n";
     } else {
       print REPORT "LAST Good Backups TRIAL: $key\tFull($LAST_FULL_TRL{$key})\tINCR(none)\tARCH(noarch)\n";
     }
  }
}
print REPORT "--END   Last Good Backup TRIAL--\n";

print REPORT "--BEGIN Last Good Backup DEV--\n";
foreach $key (sort(keys %LAST_FULL_DEV)) {
  if(exists $LAST_INCR_DEV{$key}) {
     if(exists $LAST_ARCH_DEV{$key}) {
       print REPORT "LAST Good Backups DEV: $key\tFull($LAST_FULL_DEV{$key})\tINCR($LAST_INCR_DEV{$key})\tARCH($LAST_ARCH_DEV{$key})\n";
     } else {
       print REPORT "LAST Good Backups DEV: $key\tFull($LAST_FULL_DEV{$key})\tINCR($LAST_INCR_DEV{$key})\tARCH(noarch)\n";
     }
  } else {
     if(exists $LAST_ARCH_DEV{$key}) {
       print REPORT "LAST Good Backups DEV: $key\tFull($LAST_FULL_DEV{$key})\tINCR(none)\tARCH($LAST_ARCH_DEV{$key})\n";
     } else {
       print REPORT "LAST Good Backups DEV: $key\tFull($LAST_FULL_DEV{$key})\tINCR(none)\tARCH(noarch)\n";
     }
  }
}
print REPORT "--END   Last Good Backup DEV--\n";



#
# write out today's values
#
open(R,'>',"$BASE/reports/oracle_daily_report.oratab");
foreach $key (sort keys %ORATAB) {
  print R "$key\n";
} 
close(R);
open(R,'>',"$BASE/reports/oracle_daily_report.oratab_y");
foreach $key (sort (keys %ORATAB_Y)) {
  print R "$key\n";
} 
close(R);
open(R,'>',"$BASE/reports/oracle_daily_report.active_db");
foreach $key (sort (keys %ACTIVE_DB)) {
  print R "$key\n";
} 
print REPORT "\n=====================================================================\n";
print REPORT "  Oracle Metrics\n";
print REPORT "\n=====================================================================\n";
$ACTIVE=`wc -l $BASE/reports/oracle_daily_report.active_db`;
$ACTIVE_SVR=`cat $BASE/reports/oracle_daily_report.active_db|awk -F_ '{print \$1}'|sort -u| wc -l`;
print REPORT "Total Active Oracle DBs $ACTIVE\n";
print REPORT "Total Servers with Active DBs $ACTIVE_SVR\n";
close(R);
close(REPORT);