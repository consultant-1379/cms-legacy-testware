#!/usr/bin/perl 
use warnings;
use Getopt::Long;
use POSIX;
use lib "/opt/ericsson/atoss/tas/WR_CMS/PERL/modules"; 
use CT::Basic;
use TC::FUT_NEAD_MM;
use TC::MasterProxyUtils;
use CT::Common;
use CS::Test;
use NE::Test;
use Env;

#####################################################################
# Desricption: 
#             "nead_mm.pl" to test CMS test cases 
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
my $std_error_file = "/tmp/neadmm.tmp";
open STDERR, ">>$std_error_file";
##############################################################

my @testcases = qw(
   FUT001_1.19.1.1.3
);
#################### Commented Test Cases becuase of some issue but implemented well #############
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

# $cfg_cm_file     = "/opt/ericsson/atoss/tas/WR_CMS/admin/proxy_create_delete.cfg"; # To create Proxy Mo
# $cfg_dm_file     = "/opt/ericsson/atoss/tas/WR_CMS/admin/proxy_create_delete.cfg"; # To delete Proxy Mo
# $cfg_set_file    = "/opt/ericsson/atoss/tas/WR_CMS/admin/proxy_set.cfg"; # To set attributes of Proxy Mo

#######################################################################

# $mo_nead_cms = "CMSAUTONEAD_1"; # This variable represents the name of MOs getting created by this script

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
#  Nead Log File Name
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
 $log_file     = "nead_CMS_".substr($log_time,0,12).".log";
 $log_file     = "$log_dir"."/"."$log_file";

 system("touch $log_file");
 open(LOGFILE,">>$log_file") or die "Unable to write content in log file $log_file";
 print LOGFILE ("$start_time :: nead_mm.pl started");   
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
   log_registry("Nead mixed Mode TC automation script works with 11.2.7 package onwards....");
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
   log_registry("Nead Mixed Mode TC automation script works with 11.2.7 package onwards....");
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
   log_registry("Mixed Mode TC automation script works with 11.2.7 package onwards....");
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
Usage:   nead_mm.pl [-t testcase]

   -t testcase  This can be the last significant digits (e.g. 1.2.1.0.0) of the testcase slogan or
		the whole testcase slogan (e.g. FUT4385_1.2.1.0.0)
   -verbose     display additional information 
   -a           To run all the test cases one by one
   -b batch_id  To run a chunk of Test cases one by one
		value of batch_id e.g. 1,2,3 or 4
		e.g. nead_mm.pl -b 1
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
   my $max_batch = 1; # Number of Batches
   log_registry("Test cases will run in batches,Till the time all Test Cases has been divided into <$max_batch> batches.");
   die " Batch number required-e.g. 1,2,3 or 4 etc\n Given batch number <$batch> is not valid" unless $batch =~ m/^\d+$/;
   my @count_batch = (1..$max_batch);
   my $exist = grep {/^$batch$/} @count_batch;
   die "Till now all test cases are divided into $max_batch batch ...\n Given batch number <$batch> is not valid.." unless $exist; 
   log_registry("===================================================================================================");
   log_registry("======================= Batch selected for execution is <$batch> ====================================");
   log_registry("===================================================================================================");

   ################# Batch Defination ############

   my @batch1 = @testcases[0..$#testcases];

   my @main = (\@batch1); 

   ###############################################

   my $i = ($batch - 1);
   my $count = 0;
   for my $j (0..$#{$main[$i]})
   {
      log_registry("==== Batch <$batch> will execute Test Case from $main[$i][0] to Test Case $main[$i][$#{$main[$i]}] ====") if not $count;
      log_registry("=====================================================") if $count;
      log_registry("===================Next Test Case====================") if $count;
      log_registry("=====================================================") if $count;
      do_test_proxy($main[$i][$j],$count);
      sleep 120; # Wait for 2 Mins to get system stabilized for next TC
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
log_registry("nead_mm.pl execution ends");
close(LOGFILE);
