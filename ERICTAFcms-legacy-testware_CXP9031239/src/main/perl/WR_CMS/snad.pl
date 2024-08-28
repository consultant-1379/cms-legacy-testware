#!/usr/bin/perl
#use strict;
use warnings;
use Getopt::Long;
use lib "/opt/ericsson/atoss/tas/WR_CMS/PERL/modules"; 
use POSIX;
use Env;

use NE::Test;
use CS::Test;
use CT::Common;
use CT::Basic;
use TC::MasterProxyUtils;


my $VERSION = '8.3';

# REVISION HISTORY
# 0.01 EEIMHES new snad testcases
# 1.00 EEIMHES released.
# 1.01 EEIMHES 11.6 and 11.8 cleaned up to remove defect of dependency on R12A netsim.
# 2.0 release of 11.6 2006-01-27. 11.8 test case not yet agreed.
# 2.07
# 2.5 working on 11.1, 11.2, 11.3, 11.4, 11.5
# 3.0 re-release of 11.7 with wait_for_long_sleep
# 6.3 re-did LAs creation - more generic.
# 7.0 merging of functions between snad.pl and nead.pl
# 8.0 updates to 11.3 .4 .6 .8 .9 
# 8.1
# 8.2
# 8.3 EHIMGAR 11.1,11.2,11.5,11.6,11.7 done 

#################### STDERR output Handling ##################
my $std_error_file = "/tmp/snad.tmp";
open STDERR, ">>$std_error_file";
##############################################################

my @testcases = qw(   
    FUT15035_5.1.1.1.51
    FUT14956_5.1.1.1.52
    FUT14957_5.1.1.1.53
    FUT14959_5.1.1.1.54
    FUT14960_5.1.1.1.55
    FUT14961_5.1.1.1.56
    FUT14962_5.1.1.1.57
    FUT14963_5.1.1.1.58
    FUT1124_5.1.1.1.3
    FUT1811_4.4.2.1.20
    FUT999_9.9.9.9.9
    FUT999_8.8.8.8.8
    FUT8888_7.7.7.7.7DUMMY
    FUT9999_6.6.6.6.6DUMMY
  );

####### COLOUR FOR OUTPUT. RED means BAD/FAILURE, GREEN means GOOD/SUCCESS ###################
my $esc = chr (27);
my $left_brack = "[";
my $csi = $esc . $left_brack;

my $blue = $csi . "34m";
my $bgwhite = $csi . "47m";
 $bgred = $csi . "41m";
 $bggreen = $csi . "42m";

 $off = $csi . "0m";
######### END OF COLOUR FOR OUTPUT

 $smtool       = "/opt/ericsson/nms_cif_sm/bin/smtool";

#######################################################################
#
#  Master Log File Name
#
#######################################################################
 $home = "/opt/ericsson/atoss/tas/WR_CMS";
 die "Do not have write access to automation home directory $home" if( !-w $home );
my $script_start_time = get_time_string(); #Script Start Time
my $log_time     = $script_start_time;
 $log_time     =~ s/\s+//g;
 $log_time     =~ s/(\-|\:)//g;
 $log_file     = "snad_CMS_".substr($log_time,0,12).".log";
 $log_file     = "$home/results"."/"."$log_file";

 $smlog_time = "";
 system("touch $log_file");
 open(LOGFILE,">>$log_file") or die "Unable to write content in log file $log_file";
 print LOGFILE ("$script_start_time :: snad_new.pl started");
 print "\nLOG FILE:: $log_file \n";

####################### STDOUT trace handling and die calls handling ###################
 open STDOUT, ">>$std_error_file";
 local $SIG{__DIE__} = sub { error_writer($std_error_file,$_[0]) }; # die signal handler
########################################################################################

 $log_dir      = "$HOME";        # directory for storage of error log files
########################### List of Existing MOs ###########################################
 $bef_list = "cms_automation_mo_list_before";
 $bef_list = "$home/results"."/"."$bef_list";
 $aft_list = "cms_automation_mo_list_after";
 $aft_list = "$home/results"."/"."$aft_list";
############################################################################################

 $review_cache = "/opt/ericsson/nms_umts_cms_lib_com/bin/run_moscript /opt/ericsson/nms_umts_cms_lib_com/info/XReviewCache.py";

my $nammy      = `grep RegionCS= /etc/opt/ericsson/system.env`;
 $nammy        =~ s/RegionCS=//g;
 $nammy        =~ s/\n[a-zA-z\_]*//g;
 $region_CS    = $nammy;

 $nammy = `grep SegmentCS= /etc/opt/ericsson/system.env`;
 log_registry("It seems SegmentCS variable is not set in /etc/opt/ericsson/system.env file...") if not $nammy;
 exit "0" if not $nammy;
 chomp($nammy);
 $nammy =~ s/SegmentCS=//;
 @kjk = split /\137/, $nammy;
 $nammy = $kjk[1];
 $segment_CS   = "Seg_${nammy}_CS";

 $rute = `grep IM_ROOT= /etc/opt/ericsson/system.env`;
 log_registry("It seems IM_ROOT variable is not set in /etc/opt/ericsson/system.env file...") if not $rute;
 exit "0" if not $rute;
chomp($rute);
$rute =~ s/IM_ROOT=SubNetwork=//;
 $top_one = "SubNetwork=" . "$rute" . "_R";

######################################################################
#
# Special case for 11.2 package onwards
#
######################################################################

 $freqmanagement = `cat /var/opt/ericsson/sck/data/cp.status  | grep -i "shipment"`;

 shipment_chk($freqmanagement); # If OSSRC package is 11.2 onwards then only MO FDN has FreqManagement

###########################################################################

 $start_databases = "/opt/ericsson/nms_umts_wranmom/bin/start_databases.sh";   
 $schema_upgrade  = "/opt/ericsson/nms_umts_wranmom/bin/schema_upgrade.sh";
 $isql_cmd     = "/opt/sybase/sybase/OCS-15_0/bin/isql";
 $start_adjust = "/opt/ericsson/fwSysConf/bin/startAdjust.sh sync true BaseMo SubNetwork=$rute";
 $start_rah_export = "/opt/ericsson/nms_umts_wran_bcg/bin/start_rah_export.sh";

 $nead_dir     = path_to_managed_component("cms_nead_seg");
 log_registry("It seems nead directory path is not assigned...") if not $nead_dir;
 test_failed("$test_slogan") if not $nead_dir;
 exit "0" if not $nead_dir;
 $snad_dir     = path_to_managed_component("cms_snad_reg");
 log_registry("It seems snad directory path is not assigned...") if not $snad_dir;
 test_failed("$test_slogan") if not $snad_dir;
 exit "0" if not $snad_dir;
 $snad_log     = "$snad_dir/ONRM_RootMo_R_NEAD.log";
 $nead_log     = "$nead_dir/Seg_${nammy}_NEAD.log";
my $maf_log      = "";


 #$ROOT_MO = "SubNetwork=" . "$rute" . "_R";
 #$PLMN = "ExternalGsmPlmn=15-15";
 #$ExternalGsmPlmn = "$ROOT_MO,$PLMN"; 
 $tail_command = "tail -f $nead_log";
 $tail_command_snad = "tail -f $snad_log";

 $cstest = "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest";


 @error_indicators = qw(ERRO EXPT NullP LOCK);     # Look for these strings in the error log files

 $errors_to_find   = join "|", @error_indicators;  # create a string for use in grep of log files
my $SNAD_long_sleep_indication = "about to do long sleep";


 $debug = "";
 $help = "";
 $testcase = "";
 $verbose = "";
 $version = "";
 $test_slogan ="";

#######################################################################
#
# Configuration file Names
#
#######################################################################

 $cfg_cm_file     = "/opt/ericsson/atoss/tas/WR_CMS/admin/master_create_delete.cfg"; # To create Master Mo
 $cfg_dm_file     = "/opt/ericsson/atoss/tas/WR_CMS/admin/master_create_delete.cfg"; # To delete Master Mo
 $cfg_set_file    = "/opt/ericsson/atoss/tas/WR_CMS/admin/master_set.cfg"; # To set attributes of Master Mo

######################################################################

######################################################################

 #$mo_master_cms = "CMSAUTOMASTER_1"; # This variable represents the name of MOs getting created by this script TC 5.1.1.1.54

######################################################################
my $usage = <<"USAGE";
Usage:   snad.pl [-t testcase]

   -t testcase  This can be the last significant digits (e.g. 1.2.1.1.1) of the testca
se slogan or
                the whole testcase slogan (e.g. FUT0001_1.2.1.1.1)
   -a           To run all the test cases one by one
   -h, --help
                display this help and exit
    --verbose
                output additional information
    --version
                output version information and exit

USAGE

if( @ARGV > 0 )
{
GetOptions(
   "debug"      => \$debug,
   "help"       => \$help,
   "testcase=s" => \$testcase,
   "verbose"    => \$verbose,
   "version"    => \$version,
   "all"        => \$all
);
}
else
{
  print $usage;
  log_registry("Usage -> $usage");
  exit;
}


#die "$usage" unless $help or $version or $testcase;


=head1 NAME

snad.pl - Perl script for testing SNAD.

=head1 SYNOPSIS

  snad.pl [-t testcase]

   -t testcase  This can be the last significant digits (e.g. 1.2) of the testcase slogan or
		the whole testcase slogan (e.g. FUT4385_1.2)

   -h, --help
		display this help and exit
    --verbose
		output additional information
    --version
		output version information and exit


=head1 DESCRIPTION

This script ...




The --verbose option produces some additional information such as the values of the attributes.

=head1 Examples

1. To test ...




=head1 AUTHOR

AN Other, another@ericsson.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Ericsson

=cut


if ($help)
{
   print "$usage";
   log_registry("Usage -> $usage");
   exit;
}
elsif ($version)
{
   print "Version is $VERSION\n";
   log_registry("Version -> $VERSION");
   exit;
}
elsif ($testcase)
{
   die "Must give at least the last five digit sequence of the testcase slogan - $testcase not valid\n" unless $testcase =~ m/\d+\.\d+\.\d+\.\d+\.\d+\w*$/;      # must give at least five digit sequence, e.g. 2.1.1.1.1

    ($test_slogan) = grep {/\_$testcase\b/} @testcases;      # find the test_slogan in the testcases list
   die "Testcase $testcase not found\n" unless $test_slogan;
   print "Testcase is $test_slogan\n\n" if $debug;
   log_registry("Testcase is $test_slogan");
   do_test($test_slogan);
   sybase_event_log();
}
elsif ($all)   # do all tests
{
   for my $test_slogan (@testcases)
   {
      do_test($test_slogan);
   }
}
else
{
  print "$usage";
  log_registry("Usage -> $usage");
  exit;
}

# testcase routines


sub FUT9090
{   
  my $ip_address = "192.11.38.244";
  my $ver = netsim_ver_for_ip ($ip_address);
  print "$ver\n";
  log_registry("$ver");
}


sub netsim_ver_for_ip
{   
  my $ip_address = shift;
  my $epmd = `rsh -l netsim $ip_address "ps -ef | grep epmd | grep -v grep"`;
  my @bits = split /\057/, $epmd;
  log_registry("Netsim version on $ip_address is $bits[2]");
  return $bits[2];
}

sub FUT999  #9.9.9.9.9 and 8.8.8.8.8  To list all mos exist in cstest in a file
{
  my $test_slogan = $_[0];
  my $id; my $chk;
  $id = 1 if ($test_slogan =~ /9\.9\.9\.9\.9/);
  $id = 2 if ($test_slogan =~ /8\.8\.8\.8\.8/);
  log_registry("==================== CLEAN UP: List all mos of cstest ========================");
  log_registry("===============================================================");
  log_registry("== Before:List of MOs in File:$bef_list ==") if ($id == 1);
  log_registry("== After:List of MOs in File:$aft_list ==") if ($id == 2);
  system("touch $bef_list") if ($id == 1);
  open(MOBEFFILE,">$bef_list") or die "Unable to read or write content in file $bef_list" if ($id == 1);
  $chk = list_all_mos($bef_list) if ($id == 1);
  system("touch $aft_list") if ($id == 2);
  open(MOAFTFILE,"+<$aft_list") or die "Unable to read or write content in file $aft_list" if ($id == 2);
  $chk = list_all_mos($aft_list) if ($id == 2);
  open(MOBEFFILE,"<$bef_list") or die "Unable to read content from file $bef_list" if ($id == 2);
  my @before_mos = <MOBEFFILE> if ($id == 2);
  my @after_mos = <MOAFTFILE> if ($id == 2);
  my %before_mos = map {$_, 1} @before_mos if ($id == 2); # Compare old and new UtranCellRelation
  my @difference = grep {!$before_mos{$_}} @after_mos if ($id == 2);
  close(MOAFTFILE) if ($id == 2);
  close(MOBEFFILE);
  log_registry("There is some problem in getting list of mos...") if $chk;
  log_registry("===============================================================");
  log_registry("===============================================================");
  log_registry("==== List of MOs remain in snad db after completion of automation ====")if($id == 2 and scalar(@difference));
  log_registry("@difference") if ($id == 2 and scalar(@difference));
  log_registry("===============================================================") if ($id == 2 and scalar(@difference));
}

sub FUT15035  # 5.1.1.1.51 
{
  my ($test_slogan, $testcase_logfile) = @_;
  my $tc_info = "WRANCM_CMSSnad_5.1.1.1.51 ; Mib Consistency - Test Of Snad and Nead synch at initial database creation; Normal ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  
  my $user = `whoami`;
  $user =~ s/\n//g;
  if( $user ne "root" )
  {
	log_registry("Please login as root user to run the TC 5.1.1.1.51");
	print "Please login as root user to run the TC 5.1.1.1.51 \n";
	return;
  } 
  my ($before_total_nodes , $before_alive_nodes, $before_dead_nodes, $before_synced_nodes, $before_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($before_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($before_total_nodes eq "NONE");
  return "0" if ($before_total_nodes eq "NONE");
# offline of reg cs, seg cs, nead, snad
  managed_component("cms_nead_seg", "offline", 1) or die "Offline of cms_nead_seg failed\n";
  managed_component("cms_snad_reg", "offline", 1) or die "Offline of cms_snad_reg failed\n";
  managed_component("ONRM_CS",    "offline", 1) or die "Offline of ONRM_CS failed\n";
  managed_component("Region_CS",    "offline", 1) or die "Offline of Region_CS failed\n";
  managed_component("$segment_CS",  "offline", 1) or die "Offline of $segment_CS failed\n";
  managed_component("MAF", "offline", 1) or die "Offline of MAF failed\n";

  log_registry(" cms_nead_seg :: offline \n cms_snad_reg :: offline \n ONRM_CS :: offline \n Region_CS :: offline \n $segment_CS :: offline \n MAF :: offline");

  log_registry("Database is getting removed ......");
  my $result  = `su - nmsadm -c "$start_databases -f" 2>&1`; 
  #my $result  = `$start_databases -f 2>&1`;
  log_registry("Start Database result: $result");

  log_registry("Schema Upgrade is getting started by user :$user ......");
  $result  = `$schema_upgrade -upgrade /opt/ericsson/nms_umts_wranmom/upgrade 2>&1`; 
  log_registry("Schema Upgrade result: $result");

# online of reg cs, seg cs, nead, snad

  log_registry("Now Trying to online MCs......");
  my $stat_online_nead = status_mc("cms_nead_seg", "online", 30);
  my $stat_online_snad =  status_mc("cms_snad_reg", "online", 30);
  log_registry("Sleeping for 3 minutes");
  sleep 180; # wait for 3 minutes
  my $stat_online_ONRM = status_mc("ONRM_CS", "online", 30);
  my $stat_online_Region = status_mc("Region_CS", "online", 30);
  my $stat_online_segment = status_mc("$segment_CS", "online", 30);
  my $stat_online_MAF = status_mc("MAF","online",30);

  # Check if any MC has not started

  if($stat_online_MAF and $stat_online_segment and $stat_online_Region and $stat_online_ONRM and $stat_online_snad and $stat_online_nead)
  {
	log_registry("It seems MAF ,$segment_CS,Region_CS,ONRM_CS,cms_snad_reg and cms_nead_seg MCs are online...");
	log_registry(" MAF : $stat_online_MAF \n $segment_CS : $stat_online_segment \n Region_CS : $stat_online_Region \n ONRM_CS : $stat_online_ONRM \n cms_snad_reg : $stat_online_snad \n cms_nead_seg : $stat_online_nead ");
  }
  else
  {
	log_registry("It seems some of MCs are not ONLINE so leaving the Test Execution....");
	log_registry(" MAF : $stat_online_MAF \n $segment_CS : $stat_online_segment \n Region_CS : $stat_online_Region \n ONRM_CS : $stat_online_ONRM \n cms_snad_reg : $stat_online_snad \n cms_nead_seg : $stat_online_nead ");
 	test_failed($test_slogan);
	return;
  }
 
  log_registry("Waiting for 5 mins to get system stabilized....");
  sleep 300;

# arne import
  $result = `su - nmsadm -c $start_adjust 2>&1`;
  #$result = `$start_adjust 2>&1`;
  log_registry(" Adjust Result: $result");
  log_registry("Waiting for 10 mins.....");
  sleep 600;

  # wait for sync
  wait_for_rnc_sync();

  $time = sleep_start_time();

  # Wait 10 minutes or there abouts checking to see if we have nodes synching now....
  if (wait_10_for_sync())
  {
        log_registry("Looks like all nodes are synched now...");
  }
  else
  {
        test_failed($test_slogan);
        log_registry("Looks like all nodes are not synched, so leaving execution of test case from now onwards....");
        return;
  }

  log_registry("Wait for SNAD long Sleep..");
  long_sleep_found($time);

  #to Export UTRAN_TOPOLOGY.xml
  $time = sleep_start_time();
  $time =~ s/\s+/\_/g;
  $time =~ s/\://g; 
  my $xml_file = "Utran_Topology_"."$time".".xml";
  my $XML_FILE = "/ossrc/ericsson/nms_umts_wran_bcg/files/export/"."$xml_file";
  log_registry("Rah Export Started... \n XML file name : $XML_FILE");
  $result = `su - nmsadm -c "$start_rah_export radio $xml_file" 2>&1`;
  #$result = `$start_rah_export radio $xml_file 2>&1`;
  log_registry("Export result : $result");
  # wait for XML file 
  log_registry("Waiting for Export of XML file approx 10 mins....");
  sleep 600;
  if( !-f $XML_FILE )
  {
 	log_registry("It seems XML has not been exported yet, so waiting for another 10 mins...");
  	sleep 600;
  }
  if( -f $XML_FILE )
  { 
  	my $grep_undef = `grep -ic undef $XML_FILE`;
  	if($grep_undef > 1)
  	{
		log_registry("Undefined radio MOs found : Number of Undefined $grep_undef");
		log_registry("Please check XML file : $XML_FILE......");
		log_registry("Leaving Test case execution now onwards...");
		test_failed($test_slogan);
		return;
  	}
   	`rm -f $XML_FILE`; # Delete XML file if there is no Undef because size of file is very large
  }
  else
  {
	log_registry("It seems XML has not been Exported yet, after waiting 15 mins..., so leaving Test Case Execution..");
	test_failed($test_slogan);
	return;
  }

  my ($after_total_nodes , $after_alive_nodes, $after_dead_nodes, $after_synced_nodes, $after_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($after_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($after_total_nodes eq "NONE");
  return "0" if ($after_total_nodes eq "NONE");
  log_registry("Before...: \n total_nodes=$before_total_nodes \n alive_nodes=$before_alive_nodes \n dead_nodes=$before_dead_nodes \n synced_nodes=$before_synced_nodes \n never_nodes=$before_never_nodes");
  log_registry("After....: \n total_nodes=$after_total_nodes \n alive_nodes=$after_alive_nodes \n dead_nodes=$after_dead_nodes \n synced_nodes=$after_synced_nodes \n never_nodes=$after_never_nodes");

  if ($before_total_nodes == $after_total_nodes)
  {
        log_registry("before_total_nodes $before_total_nodes = after_total_nodes $after_total_nodes");
        test_passed($test_slogan);
  }
  else
  {
        log_registry("before_total_nodes $before_total_nodes != after_total_nodes $after_total_nodes don't seem to match");
        test_failed($test_slogan);
  }

}


sub FUT14956  #  5.1.1.1.52 
{
  my ($test_slogan, $testcase_logfile) = @_;
  my $tc_info = "WRANCM_CMSSnad_5.1.1.1.52 ; Mib Consistency - Test Of Snad and Nead synch at full network synch; Normal ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";

  my ($before_total_nodes , $before_alive_nodes, $before_dead_nodes, $before_synced_nodes, $before_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($before_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($before_total_nodes eq "NONE");
  return "0" if ($before_total_nodes eq "NONE");
# Run ReviewCache script to print current status of network.
  log_registry("Performing review cache before sync...");
  my ($mast1, $prox1, $unma1) = get_review_cache_MOs();
  log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($mast1 eq "NONE");
  test_failed($test_slogan) if ($mast1 eq "NONE");
  return "0" if ($mast1 eq "NONE");
  my $tota1 = $mast1+$prox1+$unma1;

# Using a reset of generation counter script, reset the generation counter on all nodes. 

  log_registry("Restting generation counter.........");
  reset_all_genc();

#Then restart the Nead MC.
  managed_component("cms_nead_seg", "offline", 1) or die "Offline of cms_nead_seg failed\n";
  managed_component("cms_nead_seg", "online", 30) or die "Online of cms_nead_seg failed\n";
  log_registry("Wait for <5> mins to get system stabilized.......");
  sleep 300;
  wait_for_rnc_sync();

  my $time = sleep_start_time(); 

  # Wait 10 minutes or there abouts checking to see if we have nodes synching now....
  if (wait_10_for_sync())
  {
        log_registry("Looks like all nodes are synched now...");
  }
  else
  {  
	test_failed($test_slogan);
	log_registry("Looks like all nodes are not synched, so leaving execution of test case from now onwards....");
     	return;
  }

  log_registry("Wait for SNAD long Sleep..");
  long_sleep_found($time);

  my ($after_total_nodes , $after_alive_nodes, $after_dead_nodes, $after_synced_nodes, $after_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($after_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($after_total_nodes eq "NONE");
  return "0" if ($after_total_nodes eq "NONE");
  log_registry("Before: total_nodes=$before_total_nodes ,alive_nodes=$before_alive_nodes, dead_nodes=$before_dead_nodes, synced_nodes=$before_synced_nodes,never_nodes=$before_never_nodes");
  log_registry("After: total_nodes=$after_total_nodes ,alive_nodes=$after_alive_nodes, dead_nodes=$after_dead_nodes, synced_nodes=$after_synced_nodes, never_nodes=$after_never_nodes");
  if ($after_synced_nodes != $before_synced_nodes)
  {  
        log_registry("Don't think all nodes are synced yet, will Sleep for 15 Minutes");
        sleep 900;
  }
 


# Run ReviewCache script to print current status of network.
  log_registry("Performing review cache after sync...");
  my ($mast2, $prox2, $unma2) = get_review_cache_MOs();
  log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($mast2 eq "NONE");
  test_failed($test_slogan) if ($mast2 eq "NONE");
  return "0" if ($mast2 eq "NONE");
  my $tota2 = $mast2+$prox2+$unma2;

  # print before and after table
  log_registry("     Before                     |               After ");
  log_registry("-------------------------------------------------------------");
  log_registry("Masters         $mast1          |Masters        $mast2");
  log_registry("Proxies         $prox1          |Proxies        $prox2");
  log_registry("UnManaged       $unma1          |UnManaged      $unma2");
  log_registry("=============================================================");
  log_registry("Total:          $tota1          |Total:         $tota2");


  if (($mast1 == $mast2) && ($prox1 == $prox2) && ($unma1 == $unma2)) 

  #### check total only.... if ($tota1 == $tota2)
  { 
    test_passed($test_slogan); 
  }
  else 
  { 
    test_failed($test_slogan);
  }
}

sub FUT14957  # 5.1.1.1.53 
{
# "Add MO's directly to a node (30 LocationAreas, 100 RoutingAreas, 1000 ServiceAreas) using a script through netsim.
# check that Correct number of master MO's are created in the SubNetwork"
}


###########################################################################################################
# Description of TC 5.1.1.1.54:
# additional moving of existing cells into new areas, i.e. GUI, import file, not used.
#Testcase says: Import an xml file to a Planned Area using Import function from Wran Explorer GUI (Network->Import Configuration). 
#In the Import file, create Areas, and UtranCells associated with these new Areas. 
#Also update existing cells to move them to the newly created Areas.
#check Verify with cstest that the Area Mos and cells are created correctly in the planned area. The existing cells are correctly moved to newly created areas.
#Activate the Planned area.
#check that The Planned data is correctly activated and all changes are seen in the valid area.
###########################################################################################################
sub FUT14959  # 5.1.1.1.54
{
  my ($test_slogan, $testcase_logfile) = @_;
  my $tc_info = "WRANCM_CMSSnad_5.1.1.1.54 ; Mib Consistency - Test Of Snad and Nead with large scale imports; Normal ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  
# Run ReviewCache script to print current status of network.
  log_registry("Performing review cache before sync...");
  my ($mast1, $prox1, $unma1) = get_review_cache_MOs();
  log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($mast1 eq "NONE");
  test_failed($test_slogan) if ($mast1 eq "NONE");
  return "0" if ($mast1 eq "NONE");
  my $tota1 = $mast1+$prox1+$unma1;

  ################################# LOCATION AREAS #######################################################
  #create new las
  my $num_new_LAs = 3;   # EXPECT (1 unmanaged) * $num_new_LAs
  log_registry("Number of New LAs => $num_new_LAs");
  my $workingRNC = pick_an_rnc();
  if($workingRNC)
  {
       log_registry("RNC => $workingRNC ");
       my @list_LAs = PICK_NEW_LAS($num_new_LAs);
       my $plan_name = create_plan_name();		
       log_registry("Plan Name for LA is: $plan_name");
       my $status_LA = create_LAs($workingRNC,\@list_LAs,$num_new_LAs,$plan_name);
	if (!$status_LA)
        {
   		log_registry("Problem in creation of LAs....");
		test_failed($test_slogan);
		return;
	}
       #################################### SERVICE AREAS #####################################################
       #create new SAs in new top LA
       my $topSA = highest_SA($workingRNC,$list_LAs[0]);
       log_registry("TOP SA => $topSA");
       my $num_new_SAs = 3;      # EXPECT (1 unmanaged) * $num_new_SAs
       log_registry("Number of New SAs => $num_new_SAs");
       $plan_name = create_plan_name();	
       log_registry("Plan Name for SA is: $plan_name");
       my $status_SA = create_SAs($workingRNC,$list_LAs[0],$topSA,$num_new_SAs,$plan_name);
	if(!$status_SA)
	{
		log_registry("Problem in creation of SAs......");
		test_failed($test_slogan);
		return;
	}
       #################################### ROUTING AREAS ############################################################
       #create new ra
       my $num_new_RAs = 3;       # EXPECT (1 unmanaged) * $num_new_RAs
       log_registry("Number of new RAs => $num_new_RAs");
       my $topRA = highest_RA($workingRNC,$list_LAs[0]);
       log_registry("Top RA => $topRA");
       $plan_name = create_plan_name();
       log_registry("Plan Name for RA is: $plan_name");
       my $status_RA = create_RAs($workingRNC,$list_LAs[0],$topRA,$num_new_RAs,$plan_name);
	if(!$status_RA)
	{
		log_registry("Problem in creation of RAs....");
		test_failed($test_slogan);
		return;
	}
       ############################## CELLS with new LAs ################################################################

       my $num_Cells_create = 3;
       log_registry("Number of Cells are creating => $num_Cells_create");
       $plan_name = create_plan_name();
       log_registry("Plan Name for Cells is: $plan_name");
       my $plan_dec = plan_decision($plan_name);
       if(!$plan_dec)
       {
         	log_registry("Problem in Plan Area....");
		test_failed($test_slogan);
               	return;
       }
       for(my $i=0;$i < $num_Cells_create;$i++)
       {
                my $rand = int(rand(100));
                my ($base_fdn,$attr_full) = get_fdn("UtranCell","create");
                my ($rnc_name,$rest_attr) = cell_attr_fdn($base_fdn,$attr_full,$workingRNC);
                $attr_full = "$attr_full"." "."$rest_attr";
                $attr_full =~ s/\n+//g ;
		$base_fdn = "$base_fdn"."$rand";
                $base_fdn = base_fdn_modify("$rnc_name","$base_fdn");
                log_registry("Creating Cell => $base_fdn $attr_full");
                my $create_result = create_mo_CS(mo =>"$base_fdn",attributes =>"$attr_full",plan =>"$plan_name");
                if($create_result)
                {
                        log_registry("Problem in creation of cell => ERROR code: $create_result");
			test_failed($test_slogan);
			return;
                }
        }
	$activ_pl = activate_plan_area($plan_name);
        my $time = sleep_start_time();
        log_registry("Wait for some time <3 Mins> to get plan activated....");
        sleep 180;
        $delete_pl = delete_plan_area($plan_name);
        if($activ_pl or $delete_pl)
        {
                log_registry("Problem in Activation/Deletion of plan Area for Cells...");
		test_failed($test_slogan);
                return;
        }
        long_sleep_found($time);
        log_registry("Performing review cache after creates... ");
        my ($mast2, $prox2, $unma2) = get_review_cache_MOs();
	log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($mast2 eq "NONE");
  	test_failed($test_slogan) if ($mast2 eq "NONE");
  	return "0" if ($mast2 eq "NONE");
        my $tota2 = $mast2+$prox2+$unma2;
        # print before and after table
        log_registry("     Before                     |               After ");
        log_registry("-------------------------------------------------------------");
        log_registry("Masters         $mast1          |Masters        $mast2");
        log_registry("Proxies         $prox1          |Proxies        $prox2");
        log_registry("UnManaged       $unma1          |UnManaged      $unma2");
        log_registry("=============================================================");
        log_registry("Total:          $tota1          |Total:         $tota2");

        my $exp_mast = 3;
        my $exp_unma = 9;

        log_registry("Expecting $exp_mast more masters.....");
        log_registry("Expecting $exp_unma more unmanaged...");

        if ( (($mast2 - $mast1) == $exp_mast) && (($unma2 - $unma1) == $exp_unma ) )
        {
                test_passed($test_slogan);
        }
        else
        {
                test_failed($test_slogan);
        }
        ###########################To Avoid Junk of SNAD Database All created Cells would get deleted#############
=begin DEACTIVE
	## TC 5.1.1.1.56 is getting failed because deletion of UtranCell cause RNC unstable
	## Any following TC do not need or create UtranCells so it will be clean up by master.pl cleanup TC 
        my ($countUtranCell,@UtranCellFDN) = get_UtranCell($mo_master_cms);
        if($countUtranCell)
        {
		my $flag = 0;
                for(my $j = 0; $j <$countUtranCell ;$j++)
                {
                        log_registry("Deleting UtranCell : $UtranCellFDN[$j]");
                        my $result = delete_mo_CS( mo => "$UtranCellFDN[$j]");
                        if($result)
                        {
                                log_registry("Problem in deletion of UtranCell Error Code : $result");
				$flag++;
                        }
                }
        }
        else
        {
                log_registry("No more Cell exist to delete");
        }
=end DEACTIVE
=cut
        ###########################################################################################################
  }
  else
  {
        log_registry("No Synched RNC found so leaving the test case processing");
        test_failed($test_slogan);
  }
}

###########################################################################################################
# Description of TC 5.1.1.1.55:
# PreCondition: At least one RNC connected and synched. For this TC, should have more, see VS for details.
# This TC STOPS AND STARTS EACH RNC IT FINDS ON THE ASSOCIATED NETSIM MACHINE.
# SYNCHING AFTER THIS CURRENTLY TAKES APPROX 600 SECONDS FOR 2 RNCS
# POST Rncs are started and synched again.
#############################################################################################################
sub FUT14960 #5.1.1.1.55
{
  my ($test_slogan, $testcase_logfile) = @_;
  my $tc_info = "WRANCM_CMSSnad_5.1.1.1.55 ; Mib Consistency - Restart of nodes in parallel; Normal ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  
  # Run ReviewCache script to print current status of network.
  log_registry("Performing review cache before sync...");
  my ($mast1, $prox1, $unma1) = get_review_cache_MOs();
  log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($mast1 eq "NONE");
  test_failed($test_slogan) if ($mast1 eq "NONE");
  return "0" if ($mast1 eq "NONE");
  my $tota1 = $mast1+$prox1+$unma1;

  # restart all connected RNCs in netsim
  # i.e. lt RncFunction.
  # for each result, fetch ipaddress attr values from MeContext
  # for each ip address, do a .show started that matched the ipaddress
  # on netsim, and restart it

  my @rncs = get_mo_list_for_class_CS ( mo  => "RncFunction");
  for my $rrr (@rncs) 
  {  
	my $rnc = $rrr;
	log_registry("Selected RNC is : $rnc");
	my $sync_state = get_synch_status($rnc);
        if($sync_state == 3)
        {
                my ($result, $sim, $node) = get_sim_info("$rnc");
                if ($result)
                {
                        log_registry("Error code is $result");
                        log_registry("Something happened in get_sim_info $rnc");
                        test_failed($test_slogan);
                        return;
                }
                else
                {
                        log_registry("Sim is $sim\nNode is $node");
                        my $result_command = do_netsim_command('.stop', $rnc, $sim, $node);
                        log_registry("Stopping simulated NE...");
                        if ($result_command)
                        {
                                log_registry("result = $result_command");
                        }
                        log_registry("Wait for 30 Sec before start rnc again");
                        sleep 30;
                        $result_command = do_netsim_command('.start', $rnc, $sim, $node);
                        log_registry("Starting simulated NE...");
                        if ($result_command)
                        {
                                log_registry("result = $result_command");
                        }
                }
        }
        else
        {
                log_registry("Selected RNC : $rnc is not synched..., So leaving this rnc as it is..");
        }
  }

  wait_for_rnc_sync();
  my $time = sleep_start_time();


  # Wait 10 minutes or there abouts checking to see if we have nodes synching now....
  if (wait_10_for_sync())
  {
        log_registry("Looks like all nodes are synched now...");
  }
  else
  {
        test_failed($test_slogan);
        log_registry("Looks like all nodes are not synched, so leaving execution of test case from now onwards....");
        return;
  }

  log_registry("Wait for SNAD long Sleep..");
  long_sleep_found($time);

  #Run ReviewCache script to print current status of network.
  log_registry("Performing review cache after sync...");
  my ($mast2, $prox2, $unma2) = get_review_cache_MOs();
  log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($mast2 eq "NONE");
  test_failed($test_slogan) if ($mast2 eq "NONE");
  return "0" if ($mast2 eq "NONE");
  my $tota2 = $mast2+$prox2+$unma2;

  # print before and after table
  log_registry("     Before                     |               After ");
  log_registry("-------------------------------------------------------------");
  log_registry("Masters         $mast1          |Masters        $mast2");
  log_registry("Proxies         $prox1          |Proxies        $prox2");
  log_registry("UnManaged       $unma1          |UnManaged      $unma2");
  log_registry("=============================================================");
  log_registry("Total:          $tota1          |Total:         $tota2");

  if (($mast1 == $mast2) && ($prox1 == $prox2) && ($unma1 == $unma2)) 
  { 
    test_passed($test_slogan); 
  }
  else 
  { 
    test_failed($test_slogan);
  }
}

sub FUT14961 #5.1.1.1.56
{
  my ($test_slogan, $testcase_logfile) = @_;
  my $tc_info = "WRANCM_CMSSnad_5.1.1.1.56 ; Mib Consistency - Force synch of nodes in parallel; Normal ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  
  # Run ReviewCache script to print current status of network.
  log_registry("Performing review cache before sync...");
  my ($mast1, $prox1, $unma1) = get_review_cache_MOs();
  log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($mast1 eq "NONE");
  test_failed($test_slogan) if ($mast1 eq "NONE");
  return "0" if ($mast1 eq "NONE");
  my $tota1 = $mast1+$prox1+$unma1;
  my ($before_total_nodes , $before_alive_nodes, $before_dead_nodes, $before_synced_nodes, $before_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($before_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($before_total_nodes eq "NONE");
  return "0" if ($before_total_nodes eq "NONE");
  # adjusting all
  log_registry("Adjusting all mec....");
  my $stat = adjust_all_mecs();
  if($stat)
  {
        my $time = sleep_start_time();
  	log_registry("Sleeping for 10 minutes");
  	sleep 600;

	# wait for RNC_sync
  	wait_for_rnc_sync();

  	# Wait 10 minutes or there abouts checking to see if we have nodes synching now....
  	if (wait_10_for_sync())
  	{
        	log_registry("Looks like all nodes are synched now...");
  	}
  	else
  	{
       		test_failed($test_slogan);
        	log_registry("Looks like all nodes are not synched, so leaving execution of test case from now onwards....");
        	return;
  	}
  	log_registry("Wait for SNAD long Sleep..");
  	long_sleep_found($time);
	my ($after_total_nodes , $after_alive_nodes, $after_dead_nodes, $after_synced_nodes, $after_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($after_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($after_total_nodes eq "NONE");
  return "0" if ($after_total_nodes eq "NONE");
	log_registry("Before...: \n total_nodes=$before_total_nodes \n alive_nodes=$before_alive_nodes \n dead_nodes=$before_dead_nodes \n synced_nodes=$before_synced_nodes \n never_nodes=$before_never_nodes");
	log_registry("After....: \n total_nodes=$after_total_nodes \n alive_nodes=$after_alive_nodes \n dead_nodes=$after_dead_nodes \n synced_nodes=$after_synced_nodes \n never_nodes=$after_never_nodes");

	# Run ReviewCache script to print current status of network.
  	log_registry("Performing review cache after sync...");
  	my ($mast2, $prox2, $unma2) = get_review_cache_MOs();
  	log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($mast2 eq "NONE");
  	test_failed($test_slogan) if ($mast2 eq "NONE");
  	return "0" if ($mast2 eq "NONE");
  	my $tota2 = $mast2+$prox2+$unma2;

  	# print before and after table
  	log_registry("     Before                     |               After ");
  	log_registry("-------------------------------------------------------------");
  	log_registry("Masters         $mast1          |Masters        $mast2");
  	log_registry("Proxies         $prox1          |Proxies        $prox2");
  	log_registry("UnManaged       $unma1          |UnManaged      $unma2");
  	log_registry("=============================================================");
  	log_registry("Total:          $tota1          |Total:         $tota2");

  	if (($mast1 == $mast2) && ($prox1 == $prox2) && ($unma1 == $unma2)) 
  	{ 
    		test_passed($test_slogan); 
  	}
  	else 
  	{ 
    		test_failed($test_slogan);
	}
   }
   else
   {
	log_registry("There is some Problem..., so leaving Test case execution.");
	test_failed($test_slogan);
   }
}


###################################################################################################################
###################################################################################################################
sub FUT14962 #5.1.1.1.57
###################################################################################################################
###################################################################################################################
#PRE   None
#POST None
{

  print "Performing review cache to /var/tmp/xxy118.log. \n";

  `/opt/ericsson/nms_umts_cms_lib_com/bin/run_moscript /opt/ericsson/nms_umts_cms_lib_com/info/ReviewCache.py > /var/tmp/xxy118.log`;

  my $mast1 = 0+`tail -7 /var/tmp/xxy118.log | head -1`;
  my $prox1 = 0+`tail -5 /var/tmp/xxy118.log | head -1`;
  my $unma1 = 0+`tail -3 /var/tmp/xxy118.log | head -1`;

  my $tota1 = $mast1+$prox1+$unma1;

managed_component("cms_snad_reg", "offline", 1) or die "Offline of cms_snad_reg failed\n";



## change cell data here....
# get all utrancells.
# pick some of them and read attribs
# modify attributes
# keep track - find them in the reviewcache output.




  my @cells = get_mo_list_for_class_CS ( mo  => "UtranCell");

#could randomize this, but need to keep track.

## print "$cells[3] \n $cells[5] \n $cells[7] \n";

my %mo_hash = get_mo_attributes_CS(mo => $cells[3], attrib =>"locationAreaRef");

# using standard sims: swap laref 1 for laref 2.
my $lar = $mo_hash{locationAreaRef};
print "changing locationAreaRef for UtranCell: $cells[3] ($lar)\n";

### example laref 2 SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,LocationArea=2
### example laref 1 SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,LocationArea=1

#split into bits and look at last bit (split l+r of the equals)
# rebuild with locationarea = 2 if 1 and 1 if 2 STANDARD SIMS!!! 

    my @ch = split /\054/, $lar;
#modify $ch[5] here
my @val = split /\075/, $ch[5];

if (0+$val[1] == 2)
  {
# print "new laref: 1 \n";
#  set_mo_attributes_CS(mo => $cells[3], attributes => "lac 1");
$val[1] = 1;
  }
elsif (0+$val[1] == 1)
  {
#  set_mo_attributes_CS(mo => $cells[3], attributes => "lac 2");
#  print "new laref: 2 \n";
$val[1] = 2;
  }

print "old value: $ch[5] \n";
$ch[5] = "$val[0]=$val[1]";
print "new value: $ch[5] \n";
    my $newlar = "$ch[0],$ch[1],$ch[2],$ch[3],$ch[4],$ch[5]";
print "\n $newlar\n";
 set_mo_attributes_CS(mo => $cells[3], attributes => "locationAreaRef $newlar");

managed_component("cms_snad_reg", "online", 10) or die "Online of cms_snad_reg failed\n";

sleep 60;

# redo review cache and compare numbers to original. Look for specific changes made while snad was offline!!!


#wait_for_long_sleep();    # added 2006-11-09

  print "Performing review cache to /var/tmp/xxz118.log. \n";
  `/opt/ericsson/nms_umts_cms_lib_com/bin/run_moscript /opt/ericsson/nms_umts_cms_lib_com/info/ReviewCache.py > /var/tmp/xxz118.log`;

  my $mast2 = 0+`tail -7 /var/tmp/xxz118.log | head -1`; 
  my $prox2 = 0+`tail -5 /var/tmp/xxz118.log | head -1`;
  my $unma2 = 0+`tail -3 /var/tmp/xxz118.log | head -1`;

  my $tota2 = $mast2+$prox2+$unma2;

# print before and after table
  print "\n     Before \t \t \t|\t     After \n";
  print "-------------------------------------------------------------\n";
  print "Masters \t$mast1\t\t|Masters \t$mast2 \n";
  print "Proxies \t$prox1\t\t|Proxies \t$prox2 \n";
  print "UnManaged \t$unma1 \t\t|UnManaged \t$unma2 \n";
  print "=============================================================\n";
  print "Total:  \t$tota1 \t\t|Total:  \t$tota2  \n";


### count no. of mentions of each LocationArea before and after (should be +1)

print "Counting references to MOs in reviewcache output... :\n";

my $tosend = "\"cat /var/tmp/xxy118.log \| grep $newlar \| wc -l\"";
my $bef2 = `"$tosend"`;
print "$bef2\n";

$tosend = "\"cat /var/tmp/xxy118.log \| grep $lar \| wc -l\"";
my $bef1 = `"$tosend"`;
print "$bef1\n";

$tosend = "\"cat /var/tmp/xxz118.log \| grep $newlar \| wc -l\"";
my $aft2 = `"$tosend"`;
print "$aft2\n";

$tosend = "\"cat /var/tmp/xxz118.log \| grep $lar \| wc -l\"";
my $aft1 = `"$tosend"`;
print "$aft1\n";

  ### e.g.   $rope = "\"rsh -l netsim $eyep 'echo \".start\" \| /netsim/R12A/netsim_pipe -sim $siminfo[3] -ne $simname[1]'\"";


#my $bef1 = 0;
#my $bef2 = 1;
#my $aft1 = 0;
#my $aft2 = 1;

### FAULTY: NEED A DETERMINISTIC WAY TO READ THE REVIEWCACHE OUTPUT.

  if (($tota2 == $tota1) && (($bef1-$aft1) == 0) && (($bef2-$aft2) == 1))
  { 
    test_passed($test_slogan); 
  }
  else 
  { 
    test_failed($test_slogan);
  }

}



sub FUT14963  #5.1.1.1.58
{
  print "Now do step 3 in the VS and hit return when ready\n";
  my $stall = getc();
  print "finished\n";
}




sub FUT1124  # 5.1.1.1.3 Run Synchronise Master on 100 plus Mo's
{
# Pick an RNC
# Select all UtranCell and use smtool action forceCC to sync then

  my ($test_slogan, $testcase_logfile) = @_;
  my $tc_info = "WRANCM_CMSSnad_5.1.1.1.3 ; Robust - Run Synchronise Master on 100 plus MO's; Normal ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";

# Run ReviewCache script to print current status of network.	

  log_registry("Performing review cache before sync...");

  my ($mast1, $prox1, $unma1) = get_review_cache_MOs();
  log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($mast1 eq "NONE");
  test_failed($test_slogan) if ($mast1 eq "NONE");
  return "0" if ($mast1 eq "NONE");
  my $tota1 = $mast1+$prox1+$unma1;
  my $rnc = pick_an_rnc();   # randomly select one
  my ($result, @children) = get_mo_children_CS( mo => $rnc);

#  print "Result code is $result, message is $result_string_CS{$result}\n";

  unless ($result)
  {
   log_registry("Going to (Sync) forceCC UtranCells:");

# get_mo_children_CS return all children under RncFunction so we have to get rid or Relations ...
# firstly get all children which don't match UtranCell=name, so we get all UtranCell and not there children as well

   my @grepUtranCell = grep(!/,UtranCell.*,/ , @children );

# next get all which UtranCell so we just have UtranCells

   my @grepUtranCell2 = grep(/,UtranCell/ , @grepUtranCell );

# for SynchMasters.py script we have to seperate fdns with ; and put in quotes ""

   my $string = join(':' , @grepUtranCell2);
   my $synch_log = "/tmp/synch_log_$$.log";

#   print "\n/opt/ericsson/nms_umts_cms_lib_com/bin/run_moscript /opt/ericsson/nms_umts_cms_lib_com/info/SynchMasters.py $string > $synch_log\n\n";

   `/opt/ericsson/nms_umts_cms_lib_com/bin/run_moscript /opt/ericsson/nms_umts_cms_lib_com/info/SynchMasters.py $string > $synch_log`;

   my $file_name = `grep SNAD_SynchMastersResult $synch_log`;
 log_registry("It seems there is no entry for SNAD_SynchMastersResult in log file $synch_log ...") if not $file_name;
 exit "0" if not $file_name;
   chomp($file_name);

#   `rm $synch_log`;
   my @file = split /\s+/, $file_name;
   log_registry("SynchMastersResult file name is $file[3]");
   my $grep_error = `grep ERROR $file[3]`;
   if ($grep_error)
	{
        log_registry("ERROR found in synch master log $file[3]");
	test_failed($test_slogan);
	return;
	}

  long_sleep_found();

  my ($after_total_nodes , $after_alive_nodes, $after_dead_nodes, $after_synced_nodes, $after_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($after_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($after_total_nodes eq "NONE");
  return "0" if ($after_total_nodes eq "NONE");
  log_registry("total_nodes , alive_nodes , dead_nodes , synced_nodes, never_nodes");
  log_registry("$after_total_nodes ,\t\t$after_alive_nodes, \t\t$after_dead_nodes, \t\t$after_synced_nodes, \t$after_never_nodes");


# redo review cache and compare numbers to original. 

  log_registry("Performing review cache after sync...");
  my ($mast2, $prox2, $unma2) = get_review_cache_MOs();
  log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($mast2 eq "NONE");
  test_failed($test_slogan) if ($mast2 eq "NONE");
  return "0" if ($mast2 eq "NONE");
  my $tota2 = $mast2+$prox2+$unma2;

  log_registry("     Before	 	 	|		After ");
  log_registry("-------------------------------------------------------------");
  log_registry("Masters 	$mast1		|Masters 	$mast2");
  log_registry("Proxies 	$prox1		|Proxies 	$prox2");
  log_registry("UnManaged	$unma1		|UnManaged 	$unma2");
  log_registry("=============================================================");
  log_registry("Total:  	$tota1 		|Total:  	$tota2");


  if ( $mast1 == $mast2 && $prox1 == $prox2 && $unma2 == $unma1) 
  	{ 
	test_passed($test_slogan); 
	}
	else 
	{ 
	test_failed($test_slogan);
	}

   }
  else 
	{ 
	log_registry("Problem in getting RNC or UtranCells to sync !!!!");
	test_failed($test_slogan);
	}
}



    

sub FUT1811  # 4.4.2.1.20 Update Attribute of master UtranCell in netsim for which an utranRelation Mo exists
{
# Pick an 2 different RNCs
# create relations between Cells then update primaryScrambling code in Master Cells

  my ($test_slogan, $testcase_logfile) = @_;
  my $tc_info = "WRANCM_CMSSnad_4.4.2.1.20 ; Update Attribute of master UtranCell in netsim for which an utranRelation Mo exists; Normal ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";

# Run ReviewCache script to print current status of network.	

  log_registry("Performing review cache before sync... ");
  my ($mast1, $prox1, $unma1) = get_review_cache_MOs();
  log_registry("$mast1, $prox1, $unma1 xxxxxxx..");

  log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($mast1 eq "NONE");
  test_failed($test_slogan) if ($mast1 eq "NONE");
  return "0" if ($mast1 eq "NONE");
  my $tota1 = $mast1+$prox1+$unma1;

  my $rnc = pick_an_rnc();   		# Select RNC
  my $cell = pick_a_cell($rnc);		# Select Cell
  if (!$cell)
  { 
        log_registry("Didn't find a Cell to update");
	test_failed($test_slogan);
	return;
  }

  my $rnc2 = pick_a_different_rnc($rnc);   			# Select RNC
  log_registry("It seems no other Sync RNC found other than $rnc....") if not $rnc2;
  test_failed($test_slogan) if not $rnc2;
  return "0" if not $rnc2;
  my $cell2 = pick_a_cell($rnc2);		# Select Cell
  if (!$cell2)
  { 
        log_registry("Didn't find a Cell to update");
	test_failed($test_slogan);
	return;
  }
  my $rand = int (rand (65534)); 		# hope not to collide with others
  my $relname = "$cell,UtranRelation=CMSAUTO$rand";

  if ($cell)
  { 
  	my $create_result = create_mo_CS( mo => $relname, attributes =>  "qOffset1sn 0 qOffset2sn 0 frequencyRelationType 1 loadSharingCandidate 0 adjacentCell $cell2");   #utranCellRef $cell 
        if ($create_result)
	{      
		log_registry("Problem in creation of UtranRelation.....");
 		log_registry("Error code is $create_result, error message is $result_code_CS{$create_result}");
		test_failed($test_slogan);
		return;  #return 
	}
  }
  log_registry("UtranRelation name is $relname ");
  sleep 60;
  my $primaryScrambling = int (rand (510)); 		# hope not to collide with others
  log_registry("Going to set primaryScramblingCode in master to $primaryScrambling");
  log_registry("========= Attributes of MO Before =========");
  get_mo_attr($cell2,"primaryScramblingCode");
  log_registry("===========================================");

  my  $result = set_mo_attributes_CS( mo => $cell2, attributes => "primaryScramblingCode $primaryScrambling" );
  if ($result)
  {      
    log_registry("Problem in setting attribute of UtranCell $cell2..");
    log_registry("Error code is $result, error message is $result_code_CS{$result}");
    test_failed($test_slogan);
    return;
  } 
  sleep 60;
  log_registry("========= Attributes of MO After =========");
  get_mo_attr($cell2,"primaryScramblingCode");
  log_registry("===========================================");

  #verify that the update has been successful

  my %rezzy = get_mo_attributes_CS( mo => $relname, attributes => "utranCellRef");
  my $utranCellRef = $rezzy{utranCellRef};
  log_registry("utranCellRef is $utranCellRef ");

  %rezzy = get_mo_attributes_CS( mo => $utranCellRef, attributes => "primaryScramblingCode");
  $result = $rezzy{primaryScramblingCode};

  log_registry("primaryScrambling is $result ");
  if (!($primaryScrambling == $result))
  {
    log_registry("It seems proxy ExternalUtranCell primaryScramblingCode is not updated with new value....");
    test_failed($test_slogan);
    return;
  } 

# redo review cache and compare numbers to original. 
  log_registry("Performing review cache after sync... ");

  my ($mast2, $prox2, $unma2) = get_review_cache_MOs();
  log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($mast2 eq "NONE");
  test_failed($test_slogan) if ($mast2 eq "NONE");
  return "0" if ($mast2 eq "NONE");
  my $tota2 = $mast2+$prox2+$unma2;

  log_registry("     Before                     |               After ");
  log_registry("-------------------------------------------------------------");
  log_registry("Masters         $mast1          |Masters        $mast2");
  log_registry("Proxies         $prox1          |Proxies        $prox2");
  log_registry("UnManaged       $unma1          |UnManaged      $unma2");
  log_registry("=============================================================");
  log_registry("Total:          $tota1          |Total:         $tota2");


  if ( $mast1 == $mast2 && $prox1 == $prox2 && $unma2 == $unma1)  # masters / proxies should be different 
  { 
	test_failed($test_slogan);
  }
  else 
  { 
	test_passed($test_slogan); 
  }

# clean up and get rid of created relation 

  $result = delete_mo_CS(mo => $relname);
  if ($result)
  {      
    log_registry("Problem In Delete of $relname ");
    log_registry("Error code is $result, error message is $result_code_CS{$result}");
    return;
  } 


}



###################################################################################################################
###################################################################################################################
sub FUT9999 #6.6.6.6.6DUMMY dummy for live development purposes
###################################################################################################################
###################################################################################################################
#PRE   None
#POST None
{
print "starting 9.98 dummy\n";
my @mo = ("SubNetwork=ONRM_RootMo_R,MeContext=ERBS02,ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=LTE01ERBS00002-2","SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,WcdmaCarrier=1","SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=RNC01-4-1","SubNetwork=ONRM_RootMo_R,MeContext=ERBS02,ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=LTE01ERBS00002-2","SubNetwork=ONRM_RootMo_R,MeContext=ERBS03,ManagedElement=1,ENodeBFunction=1,EUtraNetwork=1,ExternalENodeBFunction=14,ExternalEUtranCellFDD=4");
my $review_cache_log = cache_file();
foreach(@mo)
{
	my ($rev_log,$stat) = rev_find(file => $review_cache_log,mo => $_);
	log_registry("MO State => $rev_log \n State Code is => $stat");
}
}
###################################################################################################################
sub FUT8888 #7.7.7.7.7DUMMY dummy for live development purposes
###################################################################################################################
###################################################################################################################
#PRE   None
#POST None
{
#####Dummy#####
my $mo = "SubNetwork=ONRM_RootMo_R,MeContext=LTE01ERBS00064,ManagedElement=1,ENodeBFunction=1";
my %param = get_mo_attributes_CS(mo => $mo, attributes => "eNodeBPlmnId eNBId");
log_registry("attribute1 => $param{eNodeBPlmnId} \n attribute2 => $param{eNBId}");
}

sub classify_node_versions
{
  my @nodes = get_mo_list_for_class_CS ( mo  => "MeContext");
  my $node_count = ($#nodes + 1);
  my (@rnc, @rbs, @rxi);
  foreach my $mec(@nodes)
  {
    my %hash = get_mo_attributes_CS(mo => $mec, attrib =>"neMIMversion neMIMName ");
    my ($ver,$type) = ( $hash{neMIMversion},$hash{neMIMName} );
    log_registry("$mec type is $type. Version is $ver");
    if ("$type" eq "RANAG_NODE_MODEL")
    {
    push @rxi, $ver;
    }
    elsif ("$type" eq "RBS_NODE_MODEL")
    {
    push @rbs, $ver;
    }    
    elsif ("$type" eq "RNC_NODE_MODEL")
    {
    push @rnc, $ver;
    }    
 
  }
  log_registry("$node_count nodes found in the system.");
  log_registry("(1+$#rnc) RNCs, (1+$#rbs) RBSes and (1+$#rxi) RXIs found");
}


#count RNCs, RXIs, RBSes

#RNC
#add versions to a list
#sort and cull list, count.
# print list in order.

sub create_LAs()
{
  my $rnc = shift;
  my $LA = shift;
  my $count = shift;
  my $plan_name = shift;
  log_registry("rnc is: $rnc \n number of new LAs is: $count" );
  if($plan_name)
  {
       	my $result = plan_decision($plan_name);
       	if(!$result)
	{
		log_registry("Problem in Plan Area....");
		return;
	}
  }
  for(my $i=0;$i<$count;$i++)
  {
  	my $newLA = "$rnc,LocationArea=$$LA[$i]";
  	log_registry("Creating LocationArea => $newLA LocationAreaId $$LA[$i] lac $$LA[$i]");
  	my $create_result = create_mo_CS( mo => $newLA,plan => $plan_name, attributes => "LocationAreaId $$LA[$i] lac $$LA[$i] ");
  	if($create_result)
  	{
 		log_registry("Problem in creation of LA Error Code:=> $create_result");
		return;
  	}
  }
  if($plan_name)
  {
	$activ_pl = activate_plan_area($plan_name);
        log_registry("Wait for some time <3 Mins> to get plan activated....");
        sleep 180;
        $delete_pl = delete_plan_area($plan_name);
	if($activ_pl or $delete_pl)
        {
		log_registry("Problem in Activation/Deletion of plan Area...");
		return;
        }
  }
  return OK;
}

sub create_RAs()
{
  my $rnc = shift;
  my $topLA = shift;
  my $topRA = (0+shift);
  my $num_to_create = shift;
  my $plan_name = shift;
  log_registry("rnc is $rnc \n la is $topLA \n topRA is $topRA \n need to create $num_to_create RAs");
  if($plan_name)
  {
        my $result = plan_decision($plan_name);
        if(!$result)
        {
                log_registry("Problem in Plan Area....");
                return;
        }
  }

  for (my $newLAcount = 1; $newLAcount <= $num_to_create; $newLAcount++)
  {
    my $next = ($topRA + $newLAcount);
    my $newRA = "$rnc,LocationArea=$topLA,RoutingArea=$next";
    log_registry("Creating RoutingArea => $newRA RoutingAreaId $next rac $next");
    my $create_result = create_mo_CS( mo => $newRA, attributes =>  "RoutingAreaId $next rac $next ",plan => "$plan_name");
    if($create_result)
    {
        log_registry("Problem in creation of RA => $create_result");
	return;
    }
  } 
  if($plan_name)
  {
        $activ_pl = activate_plan_area($plan_name);
        log_registry("Wait for some time <3 Mins> to get plan activated....");
        sleep 180;
        $delete_pl = delete_plan_area($plan_name);
        if($activ_pl or $delete_pl)
        {
                log_registry("Problem in Activation/Deletion of plan Area...");
                return;
        }
  }
  return OK;
}

sub create_SAs()
{
  my $rnc = shift;
  my $topLA = shift;
  my $topSA = (0+shift);
  my $num_to_create = shift;
  my $plan_name = shift;
  log_registry("rnc is $rnc \n la is $topLA  \n topSA is $topSA \n need to create $num_to_create SAs");

  if($plan_name)
  {
        my $result = plan_decision($plan_name);
        if(!$result)
        {
                log_registry("Problem in Plan Area....");
                return;
        }
  }

# find topSA  
  for (my $newLAcount = 1; $newLAcount <= $num_to_create; $newLAcount++)
  {
    my $next = ($topSA + $newLAcount);
    my $newSA = "$rnc,LocationArea=$topLA,ServiceArea=$next";
    log_registry("Creating ServiceArea => $newSA ServiceAreaId $next sac $next");
    my $create_result = create_mo_CS( mo => $newSA, attributes =>  "ServiceAreaId $next sac $next ");
    if($create_result)
    {
        log_registry("Problem in creation of SA => $create_result");
	return;
    }
  } 
  if($plan_name)
  {
        $activ_pl = activate_plan_area($plan_name);
        log_registry("Wait for some time <3 Mins> to get plan activated....");
        sleep 180;
        $delete_pl = delete_plan_area($plan_name);
        if($activ_pl or $delete_pl)
        {
                log_registry("Problem in Activation/Deletion of plan Area...");
                return;
        }
  }
  return OK;
}

sub voldone {
# get all utrancells.
# pick some of them and read attribs
# modify attributes
# keep track - find them in the reviewcache output.

  my @cells = get_mo_list_for_class_CS ( mo  => "UtranCell");

#could randomize this, but need to keep track.

## print "$cells[3] \n $cells[5] \n $cells[7] \n";

my %mo_hash = get_mo_attributes_CS(mo => $cells[3], attrib =>"locationAreaRef");

# using standard sims: swap laref 1 for laref 2.
my $lar = $mo_hash{locationAreaRef};
log_registry("changing locationAreaRef for UtranCell: $cells[3] ($lar)");

### example laref 2 SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,LocationArea=2
### example laref 1 SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,LocationArea=1

#split into bits and look at last bit (split l+r of the equals)
# rebuild with locationarea = 2 if 1 and 1 if 2 STANDARD SIMS!!! 

    my @ch = split /\054/, $lar;
#modify $ch[5] here
my @val = split /\075/, $ch[5];

if (0+$val[1] == 2)
  {
# print "new laref: 1 \n";
#  set_mo_attributes_CS(mo => $cells[3], attributes => "lac 1");
$val[1] = 1;
  }
elsif (0+$val[1] == 1)
  {
#  set_mo_attributes_CS(mo => $cells[3], attributes => "lac 2");
#  print "new laref: 2 \n";
$val[1] = 2;
  }

log_registry("old value: $ch[5]");
$ch[5] = "$val[0]=$val[1]";
log_registry("new value: $ch[5] ");
    my $newlar = "$ch[0],$ch[1],$ch[2],$ch[3],$ch[4],$ch[5]";
log_registry(" $newlar");
 set_mo_attributes_CS(mo => $cells[3], attributes => "locationAreaRef $newlar");
}



sub old_one
{
#my $ippy = "192.11.38.240";
#print "$ippy \n";
#### OK, but hardcoded: my $outty =  `rsh -l netsim netsim208 'echo ".show started" | /netsim/R12A/netsim_pipe | grep "192.11.38.240 "'`;
#my $outty =  `rsh -l netsim $ippy 'echo ".show started" | /netsim/R12A/netsim_pipe | grep "$ippy "'`;
# print "$outty\n";
#my @siminfo = split /\057/ ,$outty;
#PRE   None
#print "sim is $siminfo[3]\n";

#my @simname = split /\s+/, $siminfo[0];
#print "NE name is $simname[1] \n";
#print "Ip address is $simname[2] \n";

#my $rope = "rsh -l netsim $ippy 'echo \".start\" \| /netsim/R12A/netsim_pipe -sim $siminfo[3] -ne $simname[1]";

# coding.../netsim/R12A/netsim_pipe -sim Wal-C3-notransport-RNC01_MHES -ne RNC01'
# $rope .= 

#`echo "$rope" > /tmp/helloo`;

#print "\n $rope \n";


### HERE ... $outty = `rsh -l netsim $ippy 'echo ".start" | /netsim/R12A/netsim_pipe -ne '`;
#rsh -l netsim 192.11.38.240 'echo ".start" | /netsim/R12A/netsim_pipe -sim Wal-C3-notransport-RNC01_MHES -ne RNC01'
# `rsh -l netsim $ippy 'echo ".start" | /netsim/R12A/netsim_pipe -ne '`;

#PREFECT STRING TO NETSIM!!! : root@atrcus17> rsh -l netsim 192.11.38.240 'echo ".start" | /netsim/R12A/netsim_pipe -sim Wal-C3-notransport-RNC01_MHES -ne RNC01'
}

#####################################################################################################################
#####################################################################################################################

# utility routines

sub do_test
{
   my $test = shift;

   $start_time = get_time_string();
   my $s_time = substr($start_time,11,5)."  "."on"."  ".substr($start_time,8,2).substr($start_time,4,4).substr($start_time,0,4);
   log_registry("$test Started at $s_time ");
   $smlog_time = sleep_start_time();
   preconditions_OK("MAF") or die "Preconditions not valid\n";
   my $testcase_logfile = get_logfile_name("nead", $test);   #dupe this
   my $testcase_logfile_snad = get_logfile_name("snad", $test);   #duped

#   start_log_nead($testcase_logfile);
#print "NEAD LOG IS: $testcase_logfile\n";
#   start_log_snad($testcase_logfile_snad);                             # duped
#print "SNAD LOG IS: $testcase_logfile_snad\n";

   my $test_slogan = $test;     # save the test_slogan
   $test_slogan =~ s/.*_//;     # Test case id only
   $test_slogan = "Test Case"." "."$test_slogan ";
   $test =~ s/_.*//;            # remove numerical suffix to get test subroutine name
   no strict qw(refs);          # turn off strict refs checking so that next line can call subroutine with test name
   $test->($test_slogan, $testcase_logfile, $testcase_logfile_snad);  # call the subroutine to do the actual test
}


sub adjust_all_mecs
{
  my $plan = " ";
  my @rncs = get_mo_list_for_class_CS ( mo  => "RncFunction");
  if($#rncs > 0)
  {
  	for my $rrr (@rncs)
  	{  
		log_registry("Selected RNC is: $rrr");
    		my $mec = get_mec($rrr);
    		log_registry("Adjusting via CStest: $mec ");
    		my $res =`$cstest $plan -s $region_CS adjust $mec`;
    		if($res)
    		{
    			log_registry("There is a problem in adjusting $mec: $res");
			return;
    		}
  	}
   }
   else
   {
	log_registry("No RNC Selected");
	return;
   }
   return OK;
}

sub start_log
{
   my $testcase_logfile = shift;
   if (my $pid = fork)
   {
      sleep 1;
   }
   else
   {
      die "cannot fork: $!" unless defined $pid;
      exec("$tail_command > $testcase_logfile");
   }
}


sub does_mo_exist_ONRM
{
   my $mo = shift;
    my $attempts      = 0;
   my $max_attempts  = 10;
   my $time_to_sleep =6;

   my $result;
do {
      return $result if $attempts++ > $max_attempts;
      $result =  does_mo_exist_CS( mo => $mo, server => "ONRM");
      sleep $time_to_sleep if $time_to_sleep;
      log_registry("checking mo do exist");
   } until $result =$result_code_CS{MO_ALREADY_EXISTS};

  return $result; 
    }

sub move_cells
{
  my $num_to_move = shift;
  my $plan = shift;
  for (my $moveCellcount = 1; $moveCellcount <= $num_to_move; $moveCellcount++)
  { 
    my $rnc = pick_an_rnc();
    my $cell = pick_a_cell($rnc);
    my $topLA = highest_LA($rnc);
    my $topSA = highest_SA($rnc,$topLA);
    my $topRA = highest_RA($rnc,$topLA);
    my  $result = set_mo_attributes_CS( plan => $plan, mo => $cell, attributes => "lac $topLA sac $topSA rac $topRA" );
    if ($result)
    {        
#      test_failed($test_slogan);
      log_registry("Error code is $result, error message is $result_code_CS{$result}");
      return;
    }
  }
}

close STDERR;
close STDOUT;
error_writer($std_error_file);
log_registry("snad_new.pl execution ends");
close(LOGFILE);
