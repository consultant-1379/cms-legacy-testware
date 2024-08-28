#!/usr/bin/perl
use warnings;
use Getopt::Long;
use POSIX;
use lib "/opt/ericsson/atoss/tas/WR_CMS/PERL/modules"; 
use CT::Basic;
use TC::FUT;
use TC::MasterProxyUtils;
use CT::Common;
use CS::Test;
use Env;

#####################################################################
# Desricption: 
#             "master.pl" to test CMS test cases 
#
#
# FUT001   means reference to Idle Mode VS numbers
# FUTVS001 means reference to SNAD VS
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
my $std_error_file = "/tmp/master.tmp";
open STDERR, ">>$std_error_file";
##############################################################

my @testcases = qw(
   FUT001_4.3.1.2.1
   FUT029_4.3.2.2.1
   FUT002_4.3.3.2.1
   FUT003_4.3.1.3.1
   FUT004_4.3.1.3.5
   FUT005_4.3.1.3.9
   FUT031_4.3.2.3.7
   FUT032_4.3.2.3.3
   FUT033_4.3.2.3.1
   FUT006_4.3.3.3.9
   FUT007_4.3.3.3.5
   FUT008_4.3.3.3.1
   FUT009_4.3.1.4.1
   FUT010_4.3.1.4.8
   FUTVS004_4.3.1.1.8
   FUT011_4.3.1.1.4
   FUT037_4.3.2.4.15
   FUT038_4.3.2.4.3
   FUT039_4.3.2.4.1
   FUT012_4.3.3.4.9
   FUT013_4.3.3.4.1
   FUT014_4.3.3.4.13
   FUT015_4.3.1.2.5
   FUT030_4.3.2.2.7
   FUT016_4.3.3.2.7
   FUT017_4.3.1.3.13
   FUT018_4.3.1.3.17
   FUT019_4.3.1.3.21
   FUT034_4.3.2.3.18
   FUT035_4.3.2.3.14
   FUT036_4.3.2.3.12
   FUT020_4.3.3.3.21
   FUT021_4.3.3.3.17
   FUT022_4.3.3.3.13
   FUT023_4.3.1.4.22
   FUT024_4.3.1.4.29
   FUT025_4.3.1.4.40
   FUT040_4.3.2.4.27
   FUT041_4.3.2.4.18
   FUT042_4.3.2.4.16
   FUT026_4.3.3.4.25
   FUT027_4.3.3.4.17
   FUT028_4.3.3.4.29
   FUTVS001_4.4.1.1.1
   FUTVS003_4.4.2.1.1
   FUTVS002_4.4.3.1.1
   FUTVS005_4.3.2.1.8
   FUTVS006_4.3.3.1.9
   FUTVS007_4.3.1.1.6
   FUTVS019_4.3.1.1.9
   FUTVS021_4.3.2.1.4
   FUTVS020_4.3.3.1.17
   FUTVS038_4.3.5.1.28
   FUTVS039_4.3.5.1.29
   FUTVS040_4.3.5.1.30
   FUTVS037_4.3.1.1.1
   FUTVS044_4.3.1.1.2
   FUTVS045_4.3.1.1.3
   FUTVS041_4.3.2.1.1
   FUTVS046_4.3.2.1.2
   FUTVS047_4.3.2.1.3
   FUTVS048_4.3.3.1.13
   FUTVS049_4.3.3.1.15
   FUTVS042_4.3.3.1.11
   FUTVS008_4.3.2.1.7
   FUTVS009_4.3.3.1.5
   FUTVS010_4.3.5.1.2CEGP
   FUTVS011_4.3.5.1.6DEGP
   FUTVS012_4.3.5.1.22
   FUTVS013_4.3.5.1.2CUCL
   FUTVS014_4.3.5.1.6DUCL
   FUTVS015_4.4.1.1.10
   FUTVS016_4.4.3.1.7
   FUTVS017_4.4.1.1.9
   FUTVS018_4.4.3.1.6
   FUTVS027_4.3.1.1.7
   FUTVS032_4.3.1.1.5
   FUTVS061_4.3.1.2.13
   FUTVS062_4.3.2.2.16
   FUTVS063_4.3.3.2.16
   FUTVS033_4.3.2.1.6
   FUTVS060_4.3.1.2.9
   FUTVS058_4.3.2.2.15
   FUTVS034_4.3.3.1.3
   FUTVS059_4.3.3.2.14
   FUTVS028_4.3.2.1.9
   FUTVS029_4.3.3.1.7
   FUTVS030_4.3.5.1.2CEUP
   FUTVS035_4.3.5.1.2CEUC
   FUTVS036_4.3.5.1.6DEUC
   FUTVS031_4.3.5.1.7
   FUTVS043_4.3.5.1.19
   FUTVS056_4.3.1.1.22
   FUTVS057_4.3.3.1.31
   FUTVS056_4.3.1.1.22P
   FUTVS057_4.3.3.1.31P
   FUT000_0.0.0.0.0CLEAN
);

########### Temporary commented out Test Cases ################
   #FUTVS064_4.3.1.1.31 Moved to proxy.pl
   #FUTVS065_4.3.1.2.15 Moved to proxy.pl
   #FUTVS066_4.3.1.2.19 Moved to proxy.pl

   #FUTVS050_4.3.1.1.16 Moved to proxy.pl
   #FUTVS051_4.3.2.1.11 These are all ExternalEutranFrequency
   #FUTVS052_4.3.3.1.23 and they need CMS CLI to create
   #FUTVS053_4.3.5.1.4  with a strucRef attribute
   #FUTVS054_4.3.2.1.15
   #FUTVS055_4.3.3.1.27

   # After FUTVS018_4.4.3.1.6
   #FUTVS022_4.4.1.1.4
   #FUTVS023_4.4.2.1.14
   #FUTVS024_4.4.3.1.20
   #FUTVS025_4.3.5.1.2CEUCFD
   #FUTVS026_4.3.5.1.6DEUCFD
   # Before FUTVS027_4.3.1.1.7
###############################################################

####### COLOUR FOR OUTPUT. RED means BAD/FAILURE, GREEN means GOOD/SUCCESS ###################
my $esc = chr (27);
my $left_brack = "[";
my $csi = $esc . $left_brack;

#$blink = $csi . "5m";
#$bgblue = $csi . "44m";
 $bgred = $csi . "41m";
 $bggreen = $csi . "42m";
 $off = $csi . "0m";

######### END OF COLOUR FOR OUTPUT ############################################################

########################################################################
#
# Variables Declaration
#
########################################################################
 $start_time   = get_time_string(); # Script Start Time
 $smlog_time   = "";
 $test_time    = "";
 $home	       = "/opt/ericsson/atoss/tas/WR_CMS";
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

#######################################################################
#
# Configuration file Names
#
#######################################################################

 $cfg_cm_file     = "/opt/ericsson/atoss/tas/WR_CMS/admin/master_create_delete.cfg"; # To create Master Mo
 $cfg_dm_file     = "/opt/ericsson/atoss/tas/WR_CMS/admin/master_create_delete.cfg"; # To delete Master Mo
 $cfg_set_file    = "/opt/ericsson/atoss/tas/WR_CMS/admin/master_set.cfg"; # To set attributes of Master Mo

#######################################################################

 $mo_master_cms = "CMSAUTOMASTER_1"; # This variable represents the name of MOs getting created by this script

#######################################################################

#######################################################################
#
#  Master Log File Name
#
#######################################################################

 if( !-w "$home")
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
 $log_file     = "master_CMS_".substr($log_time,0,12).".log";
 $log_file     = "$log_dir"."/"."$log_file";

 system("touch $log_file");
 open(LOGFILE,">>$log_file") or die "Unable to write content in log file $log_file";
 print LOGFILE ("$start_time :: master.pl started");   
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

###########################################################################
#
# Parameters passing to script
#
########################################################################### 
my $usage = <<"USAGE";
Usage:   master.pl [-t testcase]

   -t testcase  This can be the last significant digits (e.g. 4.1.1.2.1) of the testcase slogan or
		the whole testcase slogan (e.g. FUT4385_4.1.1.2.1)
   -verbose     display additional information 
   -a           To run all the test cases one by one
   -b batch_id  To run a chunk of Test cases one by one
                value of batch_id e.g. 1,2,3 or 4
                e.g. master.pl -b 1
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
   "batch=s"    => \$batch
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
   do_test_master($test_slogan);
}
elsif ($all)   # do all tests
{
   log_registry("All test cases would get started one by one");
   my $count = 0;
   for my $test_slogan (@testcases)
   {
      log_registry("============= Cleaning the Snad first before starting full Batch ##############") if not $count;
      do_test_master($testcases[$#testcases]) if not $count; #CLEANUP Test Case
      log_registry("=====================================================") if not $count;
      log_registry("============== Regular Test Cases Starts Now ========") if not $count;
      log_registry("=====================================================") if not $count;
      log_registry("=====================================================") if $count;
      log_registry("===================Next Test Case====================") if $count;
      log_registry("=====================================================") if $count;
      do_test_master($test_slogan);
      $count++;
      sleep 120; # To get system stabilized for next TC
   }
}
elsif ($batch) # to run Test Cases in small batches
{
   my $max_batch = 5; # Number of Batches
   log_registry("Test cases will run in batches,Till the time all Test Cases has been divided into <$max_batch> batches.");
   die " Batch number required-e.g. 1 or 2 etc..\n Given batch number <$batch> is not valid ..." unless $batch =~ m/^\d+$/;   my @count_batch = (1..$max_batch);
   my $exist = grep {/^$batch$/} @count_batch;
   die "Till now all test cases are divided into $max_batch batch \n Given batch number <$batch> is not valid.." unless $exist;
   log_registry("===================================================================================================");
   log_registry("======================= Batch selected for execution is <$batch> ====================================");
   log_registry("===================================================================================================");

   ################# Batch Defination ############

   ### my @batch4 is specifically for CMS BIT [eeitjn]

   my @batch1 = @testcases[0..47]; # FUT001 to FUTVS006 dependent Test Case
   my @batch2 = @testcases[48..86];# FUTVS007 to FUTVS043 
   my @batch3 = @testcases[87..$#testcases]; # from FUTVS050 to last
   my @batch4 = @testcases[0..5,10..13,19..20,22..27,31..33,34..35,37,41,43..45,48..49,55..57,51,61..63,65..67,69..72,75,76,83,86,92,94,95,97..99,14]; # Trial for cms bit - ft
   my @main = (\@batch1,\@batch2,\@batch3,\@batch4);


   ###############################################

   my $i = ($batch - 1);
   my $count = 0;
   for my $j (0..$#{$main[$i]})
   {
      	log_registry("==== Batch <$batch> will execute Test Case from $main[$i][0] to Test Case $main[$i][$#{$main[$i]}] ====") if not $count;
      	log_registry("======================== Cleaning the Snad first before starting Batch <$batch> =======================") if not $count;
      	log_registry("======================================================================================") if not $count;
    	do_test_master($testcases[$#testcases]) if not $count;
      	log_registry("=====================================================") if not $count;
      	log_registry("============ Regular Test Cases Starts Now ==========") if not $count;
      	log_registry("=====================================================") if not $count;
      	log_registry("=====================================================") if $count;
      	log_registry("===================Next Test Case====================") if $count;
      	log_registry("=====================================================") if $count;
      	do_test_master($main[$i][$j]);
      	sleep 120; # Wait for 2 Mins to get system stabilized for next TC
      	log_registry("==================================================") if (($count == $#{$main[$i]}) and ($i != $#main));
  	log_registry("================= Clean Up Test Case =============") if (($count == $#{$main[$i]}) and ($i != $#main));
  	log_registry("=================================================") if (($count == $#{$main[$i]}) and ($i != $#main));
  	do_test_master($testcases[$#testcases]) if (($count == $#{$main[$i]}) and ($i != $#main));
      	$count++;
   }
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
log_registry("master.pl execution ends");
close(LOGFILE);
