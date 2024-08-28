#!/usr/bin/perl 
use warnings;
use Getopt::Long;
use POSIX;
use lib "/opt/ericsson/atoss/tas/WR_CMS/PERL/modules"; 
use CT::Basic;
use TC::FUT_PROXY;
use TC::FUT_NEAD_MM;
use TC::FUT_MASTER;
use TC::MasterProxyUtils;
use CT::Common;
use CS::Test;
use NE::Test;
use Env;

#####################################################################
# Desricption: 
#             "proxy.pl" to test CMS test cases 
#
#
#
#
#####################################################################

#####################################################################
# Version History:
# 0.0 => ehimgar
#
#
#####################################################################

my $VERSION = '0.0';

#################### STDERR output Handling ##################
my $std_error_file = "/tmp/proxy.tmp";
open STDERR, ">>$std_error_file";
##############################################################

my @testcases = qw(
   FUT001_4.4.1.2.1
   FUT008_4.4.2.2.9
   FUT012_4.4.3.2.7
   FUT002_4.4.1.2.2
   FUT003_4.4.1.2.3
   FUT004_4.4.1.2.4
   FUT005_4.4.2.2.1
   FUT006_4.4.2.2.4
   FUT007_4.4.2.2.6
   FUT011_4.4.3.2.3
   FUT010_4.4.3.2.2
   FUT009_4.4.3.2.1
   FUT013_4.4.1.2.21
   FUT020_4.4.3.2.15
   FUT014_4.4.1.2.15
   FUT015_4.4.1.2.17
   FUT016_4.4.1.2.19
   FUT019_4.4.3.2.11
   FUT018_4.4.3.2.10
   FUT017_4.4.3.2.9
   FUT021_4.4.1.2.7
   FUT022_4.4.2.2.14
   FUT023_4.4.3.2.4
   FUT024_4.4.1.2.28
   FUT025_4.4.3.2.12
   FUT026_4.4.1.2.5
   FUT027_4.4.2.2.10
   FUT028_4.4.3.2.6
   FUT029_4.4.1.2.23
   FUT030_4.4.3.2.14
   FUT031_4.4.1.2.6
   FUT032_4.4.2.2.8
   FUT033_4.4.3.2.5
   FUT034_4.4.1.2.26
   FUT035_4.4.3.2.13
   FUT036_4.4.1.2.32
   FUT041_4.4.2.2.11
   FUT037_4.4.3.2.19
   FUT038_4.4.1.2.41
   FUT039_4.4.1.2.33
   FUT040_4.4.1.2.34
   FUT042_4.4.3.2.8
   FUT043_4.4.3.2.16
   FUT044_4.4.1.3.1
   FUT045_4.4.2.3.1
   FUT046_4.4.3.3.1
   FUT047_4.4.1.3.4
   FUT048_4.4.1.3.5
   FUT049_4.4.3.3.3
   FUT050_4.4.1.4.1
   FUT051_4.4.1.4.10
   FUT052_4.4.1.4.19
   FUT053_4.4.2.4.1
   FUT054_4.4.2.4.2
   FUT055_4.4.2.4.5
   FUT056_4.4.3.4.7
   FUT057_4.4.3.4.4
   FUT058_4.4.3.4.1
   FUT059_4.4.1.4.6
   FUT061_4.4.1.4.24
   FUT062_4.4.3.4.8
   FUT063_4.4.3.4.5
   FUT064_4.4.3.4.2
   FUT071_4.4.1.6.1
   FUT072_4.4.1.6.2
   FUT073_4.4.1.6.3
   FUT075_4.4.1.6.4
   FUT077_4.4.1.7.2
   FUT078_4.4.1.7.3
   FUT079_4.4.1.7.4
   FUT080_4.4.1.7.5
   FUT081_4.4.1.7.6
   FUT082_4.4.1.6.14
   FUT083_4.4.1.6.15
   FUT128_4.4.1.2.61
   FUT128_4.4.1.2.62
   FUT518_5.1.1.1.8
   FUT524_5.3.1.1.1
   FUT084_4.4.1.6.16
   FUT085_4.4.1.6.17
   FUT086_4.4.1.6.18
   FUT087_4.4.1.3.14
   FUT090_4.5.1.2.17
   FUT090_4.4.2.2.31
   FUT091_4.3.2.1.19
   FUT088_4.4.1.3.12
   FUT089_4.3.2.2.11
   FUT089_4.3.2.2.14
   FUT092_4.4.1.2.70
   FUT092_4.4.1.2.72
   FUT093_4.4.2.3.9
   FUT093_4.5.1.2.25
   FUT111_4.4.3.3.5
   FUT087_4.4.3.6.8
   FUT088_4.4.3.6.7
   FUT095_4.3.1.1.11
   FUT095_4.3.1.1.12
   FUT096_4.4.1.6.20
   FUT097_4.4.1.8.3
   FUT098_4.4.1.8.4
   FUT099_4.4.1.8.5
   FUT100_4.4.1.8.6
   FUT101_4.4.1.9.2
   FUT102_4.4.1.9.3
   FUT103_4.4.1.9.4
   FUT104_4.4.1.9.5
   FUT082_4.4.3.6.3
   FUT071_4.4.3.6.4
   FUT073_4.4.3.6.5
   FUT105_4.4.3.4.3
   FUT106_4.4.3.4.6
   FUT107_4.4.3.4.9
   FUT108_4.4.3.2.18
   FUT109_4.4.3.3.4
   FUT110_4.4.3.3.2
   FUT094_4.5.1.2.23
   FUT112_4.4.1.2.39
   FUT021_4.4.1.2.43
   FUT113_4.4.1.2.45
   FUT113_4.4.1.2.46
   FUT114_4.4.1.11.2
   FUT115_4.4.1.11.3
   FUT116_4.4.1.11.4
   FUT117_4.4.1.11.5
   FUT118_4.4.3.6.9
   FUT119_4.4.3.6.10
   FUT120_4.4.1.10.13
   FUT120_4.4.3.6.11
   FUT121_4.5.1.8.10
   FUT122_4.5.1.8.11
   FUT124_4.4.2.2.20
   FUT125_4.4.3.2.20
   FUT125_4.4.3.2.22
   FUT126_4.4.3.2.24
   FUT127_4.4.2.2.16
   FUT129_4.4.3.2.26
   FUT129_4.4.3.2.28
   FUT130_4.4.3.2.29
   FUT131_4.4.3.2.27
   FUT132_4.4.3.2.21
   FUT132_4.4.3.2.23
   FUT133_4.4.2.2.17
   FUT101_4.4.1.9.6
   FUT135_4.4.2.2.22
   FUT135_4.4.2.2.23
   FUT135_4.4.2.2.24
   FUT077_4.4.2.3.2
   FUT077_4.4.2.3.3
   FUT136_4.4.2.3.4
   FUT137_4.4.2.4.6
   FUT137_4.4.2.4.9
   FUT024_4.4.2.2.15
   FUT060_4.4.2.4.3
   FUT002_4.4.2.2.2
   FUT002_4.4.2.2.7
   FUT002_4.4.2.2.5
   FUT134_4.4.1.2.50
   FUT134_4.4.1.2.52
   FUT138_4.4.1.7.7
   FUT139_4.4.1.2.55
   FUT139_4.4.1.2.57
   FUT140_4.4.2.2.21
   FUT141_4.4.2.1.12
   FUT142_4.4.2.1.6
   FUT142_4.4.2.1.7
   FUT142_4.4.2.1.8
   FUT142_4.4.2.1.2
   FUT142_4.4.2.1.3
   FUT142_4.4.2.1.4
   FUT141_4.4.2.1.5
   FUT143_4.4.2.1.9
   FUT143_4.4.2.1.10
   FUT143_4.4.2.1.11
   FUT141_4.4.2.1.13
   FUT074_4.4.1.6.6
   FUT076_4.4.1.6.5
   FUT519_5.1.1.1.3
   FUT520_5.2.1.1.1
   FUT521_5.2.1.1.5
   FUT522_5.2.1.1.3 
   FUT524_5.3.1.1.1
   FUT525_5.3.1.1.3
   FUT065_4.4.1.5.1
   FUT066_4.4.1.5.13
   FUT067_4.4.2.5.1
   FUT068_4.4.2.5.5
   FUT069_4.4.3.5.10
   FUT070_4.4.3.5.1
   FUT076_4.4.1.6.5
   FUT150_4.3.1.1.31
   FUT151_4.3.1.1.28
   FUT152_4.3.1.2.19
   FUT153_4.3.1.2.15
   FUT154_1.23.1.1.1
   FUT155_1.23.1.1.2
   FUT156_4.3.1.1.16
   FUT157_4.3.2.1.11
   FUT158_4.3.3.1.23
   FUT159_4.3.5.1.4
   FUT160_4.3.2.1.15
   FUT161_4.3.3.1.27
   FUT000_0.0.0.0.0CLEAN
);
#################### Commented Test Cases becuase of some issue but implemented well #############
   #FUT060_4.4.1.4.15  #redirectionInfoPrioX is not available for newer version of nodes
   #FUT065_4.4.1.5.1
   #FUT066_4.4.1.5.13
   #FUT067_4.4.2.5.1
   #FUT068_4.4.2.5.5
   #FUT069_4.4.3.5.10
   #FUT070_4.4.3.5.1
   #FUT074_4.4.1.6.6  #  Have a TR for this 
   #FUT076_4.4.1.6.5  #  nodeRelationType value is not matching with description 
   #FUT123_4.5.1.8.13 # Under discussion with dev team
   #FUT128_4.4.1.2.58 # CR 865/109 18-FCP 103 8147/11
   #FUT128_4.4.1.2.61 # Added back in now to proxy batch 2
   #FUT128_4.4.1.2.62 # Added back in now to proxy batch 2
   #FUT144_4.3.1.4.44 # TR id HO23651
##################################################################################################
####### COLOUR FOR OUTPUT. RED means BAD/FAILURE, GREEN means GOOD/SUCCESS ###################
my $esc = chr (27);
my $left_brack = "[";
my $csi = $esc . $left_brack;

 $bgred = $csi . "41m";
 $bggreen = $csi . "42m";
 $off = $csi . "0m";

######### END OF COLOUR FOR OUTPUT ############################################################

########################################################################
#
# Variables Declaration
#
########################################################################
 $cs_log_file  = "$HOME/cs_test.log";
 $start_time   = get_time_string(); # Script Start Time
 $smlog_time   = "";
 $test_time    = "";
 $home         = "/opt/ericsson/atoss/tas/WR_CMS";
 $log_dir      = "$home/results";        # directory for storage of error log files
 $smtool       = "/opt/ericsson/nms_cif_sm/bin/smtool"; #path to use smtool
 $moscript     = "/opt/ericsson/nms_umts_cms_lib_com/bin/run_moscript";
 $review_cache = "$moscript /opt/ericsson/nms_umts_cms_lib_com/info/XReviewCache.py";
 $nead_dir     = path_to_managed_component("cms_nead_seg");
#$snad_dir     = path_to_managed_component("cms_snad_reg");
 
my $nammy      = `grep RegionCS= /etc/opt/ericsson/system.env`;
 $nammy        =~ s/RegionCS=//g;
 $nammy        =~ s/\n[a-zA-z\_]*//g;
 $region_CS    = $nammy; 
 $cstest       = "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest";
 $isql_cmd     = "/opt/sybase/sybase/OCS-15_0/bin/isql"; 

 $nammy        = `grep SegmentCS= /etc/opt/ericsson/system.env`;
 $nammy        =~ s/SegmentCS=//g;
 $nammy        =~ s/\n[a-zA-z\_]*//g;
 $segment_CS   = $nammy; 

my $rute = `grep IM_ROOT= /etc/opt/ericsson/system.env`;
 log_registry("It seems IM_ROOT variable is not set in /etc/opt/ericsson/system.env file...") if not $rute;
 exit "0" if not $rute;
 chomp($rute);
 $rute =~ s/IM_ROOT=SubNetwork=//;
 $top_one = "SubNetwork=" . "$rute" . "_R";

 $debug = "";
 $help = "";
 $testcase = "";
 $version = "";
 $test_slogan ="";
 $all = "";
 $batch = "";

######################################################################
#
# Special case for 11.2 package onwards
#
######################################################################

 $freqmanagement = `cat /var/opt/ericsson/sck/data/cp.status  | grep -i "shipment"`;

 shipment_chk($freqmanagement); # If OSSRC package is 11.2 onwards then only MO FDN has FreqManagement

#######################################################################
#
# Configuration file Names
#
#######################################################################

 $cfg_cm_file     = "/opt/ericsson/atoss/tas/WR_CMS/admin/proxy_create_delete.cfg"; # To create Proxy Mo
 $cfg_dm_file     = "/opt/ericsson/atoss/tas/WR_CMS/admin/proxy_create_delete.cfg"; # To delete Proxy Mo
 $cfg_set_file    = "/opt/ericsson/atoss/tas/WR_CMS/admin/proxy_set.cfg"; # To set attributes of Proxy Mo

#######################################################################

 $mo_proxy_cms = "CMSAUTOPROXY_1"; # This variable represents the name of MOs getting created by this script

#######################################################################

#######################################################################
#
# CLI Utility to create/set/delete Proxy Mos on CS and NE side
#
#######################################################################

 $key_proxy = "start_unsupported_p";
 $cli_proxy = "/opt/ericsson/nms_umts_cms_lib_com/bin/proxy/bin/start_unsupported_proxy.sh";
 $cli_tool  = "/opt/ericsson/nms_umts_cms_lib_com/bin/proxy/bin/cli.sh";
 $cli_support = "/opt/ericsson/nms_umts_cms_lib_com/bin/proxy/bin/snadcli.sh";

#######################################################################

#######################################################################
#
#  Proxy Log File Name
#
#######################################################################

 if( !-w "$home" )
 {
	die "Do not have write access to automation home directory $home";
 }
 if( !-d "$log_dir" )
 {
   system("mkdir -p $log_dir");
 }

 $log_time     = $start_time;
 $log_time     =~ s/\s+//g;
 $log_time     =~ s/(\-|\:)//g;
 $log_file     = "proxy_CMS_".substr($log_time,0,12).".log";
 $log_file     = "$log_dir"."/"."$log_file";

 system("touch $log_file");
 open(LOGFILE,">>$log_file") or die "Unable to write content in log file $log_file";
 print LOGFILE ("$start_time :: proxy.pl started");   
 print "\nLOG FILE:: $log_file \n";

####################### STDOUT trace handling and die calls handling ######################
 open STDOUT, ">>$std_error_file";
 local $SIG{__DIE__} = sub { error_writer($std_error_file,$_[0]) }; # die signal handling
##########################################################################################

########################################################################
#
# Envoirnment checking
#
########################################################################

 if( !-f "$smtool" )
 {
   log_registry("Problem to locate smtool $smtool");
   exit;
 }

 if( !-f "$moscript" )
 {
   log_registry("Problem to locate moscript $moscript, So we have a problem to run ReviewCache");
   exit; 
 }

 if( !-f "$cstest" )
 {
   log_registry("Problem to locate cstest $cstest");
   exit;
 }

 if( !-f "$cli_proxy" )
 {
   log_registry("Problem to locate CLI utility proxy file : $cli_proxy");
   log_registry("Proxy TC automation script works with 11.2.7 package onwards....");
   exit;
 }
 else
 {
   #only applicable for nmsadm user
   #my $temp = "$cli_proxy"."_TEMP";
   #`dos2unix $cli_proxy >> $temp`;
   #`mv $temp $cli_proxy`;
   #`chmod 755 $cli_proxy`;
 }

 if( !-f "$cli_tool" )
 {
   log_registry("Problem to locate CLI utility tool file : $cli_tool");
   log_registry("Proxy TC automation script works with 11.2.7 package onwards....");
   exit;
 }
 else
 {
   #only applicable for nmsadm user
   #my $temp = "$cli_tool"."_TEMP";
   #`dos2unix $cli_tool >> $temp`;
   #`mv $temp $cli_tool`;
   #`chmod 755 $cli_tool`;
 }

 if( !-f "$cli_support" )
 {
   log_registry("Problem to locate CLI utility support file : $cli_support");
   log_registry("Proxy TC automation script works with 11.2.7 package onwards....");
   exit;
 }
 else
 {
   #only applicable for nmsadm user
   #my $temp = "$cli_support"."_TEMP";
   #`dos2unix $cli_support >> $temp`;
   #`mv $temp $cli_support`;
   #`chmod 755 $cli_support`;
 }

###########################################################################
#
# Parameters passing to script
#
########################################################################### 
my $usage = <<"USAGE";
Usage:   proxy.pl [-t testcase]

   -t testcase  This can be the last significant digits (e.g. 1.2.1.1.1) of the testcase slogan or
		the whole testcase slogan (e.g. FUT4385_1.2.1.1.1)
   -verbose     display additional information 
   -a           To run all the test cases one by one
   -b batch_id  To run a chunk of Test cases one by one
		value of batch_id e.g. 1,2,3 or 4
		e.g. proxy.pl -b 1
   -h, --help
		display this help and exit
    --version
		output version information and exit

USAGE

if( @ARGV > 0 )
{
GetOptions(
   "debug"      => \$debug,
   "help"       => \$help,
   "testcase=s" => \$testcase,
   "version"    => \$version,
   "verbose"    => \$verbose,
   "all"        => \$all,
   "batch=s"	=> \$batch
);
}
else
{

 print $usage;
 log_registry("$usage");
 exit;

}


if ($help)
{
   print "$usage";
   log_registry("$usage");
   exit;
}
elsif ($verbose)
{
  print "$usage";
  print "\n";
  log_registry("$usage");
  print "Checking Basic Precondition......";
  log_registry("Checking Basic Precondition......");
  preconditions_OK() or die "Preconditions not valid\n";
}
elsif ($version)
{
   print "Version is $VERSION\n";
   log_registry("Current Version of script is -> $VERSION");
   exit;
}
elsif ($testcase)
{
   die "Must give at least the last five digit sequence of the testcase slogan - $testcase not valid\n" unless $testcase =~ m/\d+\.\d+\.\d+\.\d+\.\d+\w*$/;      # must give at least five digit sequence, e.g. 2.1.1.1.1

   ($test_slogan) = grep {/\_$testcase\b/} @testcases;      # find the test_slogan in the testcases list
   die "Testcase $testcase not found\n" unless $test_slogan;
   print "Testcase is $test_slogan\n\n" if $debug;
   do_test_proxy($test_slogan,"SINGLE");
}
elsif ($all)   # do all tests
{
   log_registry("All test cases would get started one by one");
   my $count = 0;
   for my $test_slogan (@testcases)
   {
      log_registry("============= Cleaning the Snad first before starting full Batch ##############") if not $count;
      do_test_proxy($testcases[$#testcases]) if not $count; #CLEANUP Test Case
      log_registry("=====================================================") if not $count;
      log_registry("============== Regular Test Cases Starts Now ========") if not $count;
      log_registry("=====================================================") if not $count;
      log_registry("=====================================================") if $count;
      log_registry("===================Next Test Case====================") if $count;
      log_registry("=====================================================") if $count;
      do_test_proxy($test_slogan,$count);
      $count++;
      sleep 120; # Wait for 2 Mins to get system stabilized for next TC
   }
   cli_proxy_handle("stop");    # To stop the CLI Proxy
}
elsif ($batch) # to run Test Cases in small batches
{
   my $max_batch = 5; # Number of Batches
   log_registry("Test cases will run in batches,Till the time all Test Cases has been divided into <$max_batch> batches.");
   die " Batch number required-e.g. 1,2,3 or 4 etc\n Given batch number <$batch> is not valid" unless $batch =~ m/^\d+$/;
   my @count_batch = (1..$max_batch);
   my $exist = grep {/^$batch$/} @count_batch;
   die "Till now all test cases are divided into $max_batch batch ...\n Given batch number <$batch> is not valid.." unless $exist; 
   log_registry("===================================================================================================");
   log_registry("======================= Batch selected for execution is <$batch> ====================================");
   log_registry("===================================================================================================");

   ################# Batch Defination ############

   # my @batch5 is specifically for CMS BIT test  [eeitjn]

   my @batch1 = @testcases[0..39];
   my @batch2 = @testcases[40..77];
   my @batch3 = @testcases[78..115];
   my @batch4 = @testcases[116..$#testcases];
   my @batch5 = @testcases[0..5,21,28..32,35,37,43..35,49..51,55..57,64..66,68,72..73,78,81..84,85,95,98..99,103..107,109,113,115]; # Trial for cms bit - ft

   my @main = (\@batch1,\@batch2,\@batch3,\@batch4,\@batch5); 
   


   ###############################################

   my $i = ($batch - 1);
   my $count = 0;
   for my $j (0..$#{$main[$i]})
   {
      log_registry("==== Batch <$batch> will execute Test Case from $main[$i][0] to Test Case $main[$i][$#{$main[$i]}] ====") if not $count;
      log_registry("======================== Cleaning the Snad first before starting Batch <$batch> =======================") if not $count;
      log_registry("========================================================================================") if not $count;
      do_test_proxy($testcases[$#testcases]) if not $count;
      log_registry("=====================================================") if not $count;
      log_registry("============ Regular Test Cases Starts Now ==========") if not $count;
      log_registry("=====================================================") if not $count;
      log_registry("=====================================================") if $count;
      log_registry("===================Next Test Case====================") if $count;
      log_registry("=====================================================") if $count;
      do_test_proxy($main[$i][$j],$count);
      sleep 120; # Wait for 2 Mins to get system stabilized for next TC
      log_registry("====================================================") if (($count == $#{$main[$i]}) and ($i != $#main));
      log_registry("================= Clean Up Test Case ===============") if (($count == $#{$main[$i]}) and ($i != $#main));
      log_registry("====================================================") if (($count == $#{$main[$i]}) and ($i != $#main));
      do_test_proxy($testcases[$#testcases]) if (($count == $#{$main[$i]}) and ($i != $#main)); 
      $count++;
   }
   cli_proxy_handle("stop");    # To stop the CLI Proxy
}
else
{
   print "$usage";
   log_registry("$usage");
   exit;
}


close STDERR;
close STDOUT;
error_writer($std_error_file);
log_registry("proxy.pl execution ends");
close(LOGFILE);
