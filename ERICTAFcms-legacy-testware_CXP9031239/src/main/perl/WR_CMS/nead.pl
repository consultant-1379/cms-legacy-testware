#!/usr/bin/perl
#use strict;
use warnings;
use Getopt::Long;
use POSIX;
use Env;

use lib "/opt/ericsson/atoss/tas/WR_CMS/PERL/modules"; 

use NE::Test;
use CS::Test;
use CT::Common;
use CT::Basic;
use TC::MasterProxyUtils;
use Net::FTP;

my $VERSION = '9.3';

# 0.01 EEICHRN
# 0.02 EEIMHES updated for masterservice (R4).
# 0.03 EEIMHES added dummy testcase 9.99 and expanded comments. Started Pre and Post-Conditions
# 0.94 EEIMHES readying for handover to CMS test. Problems with stop/start RNC
# 0.990 EEIMHES fixing up to run from nead_super batch for release
# 1.200  added handling of optional error messages in nead log.
# 1.204  added colour to enable output to be visually scanned on terms that handle the ANSI codes. 
 #      Red means a Bad Thing has happened, green is OK.
# 2.0 redelivery of 1.2 1.3 1.4 1.6 2006-01-27
# 2.001 rehash of error log message handling... using $nXX for nead msgs 
# 2.004 added more error messages for 1.2, 1.3, 1.4, 1.6
# 2.010 cleaned up code. Organised subs in alphabetical order etc.
# 2.011 more cleanup... made tc_chk sub to centrally handle nead log checking. Deglobalized error message variables. 
# 2.012 fixed up 1.7
# 2.025 Ready for LSV with TCs 1.1 1.2 1.3 1.4 1.5
# 2.026 more verbosity 1.1. Added 1.8
# 3.0 pick up smtool -config pollrates 2006-04-07
# 3.1 removing hardcoded RNCfunction etc. references... preparing 1.16, 1.17, 1.18, 1.19 for re-release.
# 3.11 randomised selection of cell based on RNC.
# 3.12 working on create_cell for 1.9
# 3.30 re-release for LSV testing 2006-06-14
# 4.00 re-release for LSV testing of 1.2, 1.3, 1.4, 1.5 (added LDAP lookup of Root MO.) 2006-06-30
# 4.01 fixing GET_SIM_INFO failures... 
# 5.00 2006-07-11 final batch of nead test cases added.
#       1.1..1.11 and 1.16..1.17
# 6.00
# 7.00 updated for new version of long sleep :-(
# 7.20 added 1.20 reservedBy
# 7.5 removed _R from startadjust command for 1.23
# 8.00 final testcase added (reservedBy)
# 8.5 Numerous updates suggested by EPASOFA and EGARDOO
# 8.8 more updates.
# 8.9 fixes to 1.1, 1.7, 1,9, 1.11, 1.18, 1.21, 1.24
# 9.0 updates as requested to 1.11, 1.21
# 9.1 1.24 updated to increase timeout.
# 9.2 
# 9.3
######
#################### STDERR output Handling ##################
my $std_error_file = "/tmp/nead.tmp";
open STDERR, ">>$std_error_file";
###############################################################


my @testcases = qw(
   FUT4384_1.1.1
   FUT4385_1.1.2
   FUT4386_1.1.3
   FUT4387_1.1.4
   FUT4388_1.1.5
   FUT4389_1.1.6
   FUT4390_1.1.7
   FUT4391_1.1.8
   FUT4392_1.1.9
   FUT4393_1.1.10
   FUT4394_1.1.11
   FUT4398_1.1.15
   FUT4399_1.1.16
   FUT4400_1.1.17
   FUT4401_1.1.18
   FUT4402_1.1.19
   FUT4403_1.1.20
   FUT4404_1.1.21
   FUT4406_1.1.23
   FUT4407_1.1.24
   FUT0001_1.4.1
   FUT0002_1.4.2
   FUT0003_1.4.3
   FUT0004_1.4.4
   FUT0005_1.4.6
   FUT0006_1.4.7
   FUT0007_1.4.8
   FUT0008_1.4.9
   FUT0009_1.7.1
   FUT0010_1.7.2
   FUT0011_1.7.6
   FUT0012_1.7.8
   FUT0013_1.4.12
   FUT0014_1.15.3
   FUT0015_1.15.4
   FUT0017_1.15.68
   FUT0016_1.9.9
   FUTDUXX_9.98.9
   FUTDUMM_9.99.9
   FUTCLEANUP_1.1.27
);

#######################################################################
#
#  Master Log File Name
#
#######################################################################
 $home = "/opt/ericsson/atoss/tas/WR_CMS";
 die "Do not have write access to automation home directory $home" if ( !-w $home );
my $script_start_time = get_time_string(); #Script Start Time
my $log_time     = $script_start_time;
 $log_time     =~ s/\s+//g;
 $log_time     =~ s/(\-|\:)//g;
 $log_file     = "nead_CMS_".substr($log_time,0,12).".log";
 $log_file     = "$home/results"."/"."$log_file";

 $smlog_time = "";
 system("touch $log_file");
 open(LOGFILE,">>$log_file") or die "Unable to write content in log file $log_file";
 print LOGFILE ("$script_start_time :: nead_new.pl started");
 print "\nLOG FILE:: $log_file \n";

####################### STDOUT trace handling and die calls handling ###############
 open STDOUT, ">>$std_error_file";
 local $SIG{__DIE__} = sub { error_writer($std_error_file,$_[0]) }; # to handle die call
####################################################################################

####### COLOUR FOR OUTPUT. RED means BAD/FAILURE, GREEN means GOOD/SUCCESS ###################
 my $esc = chr (27);
 my $left_brack = "[";
 my $csi = $esc . $left_brack;

 #$red = $csi . "31m";
 #$green = $csi . "32m";
 my $blue = $csi . "34m";

 #$bold = $csi . "1m";
 #$blink = $csi . "5m";

 my $bgwhite = $csi . "47m";
 #$bgblue = $csi . "44m";
 $bgred = $csi . "41m";
 $bggreen = $csi . "42m";

 $off = $csi . "0m";
######### END OF COLOUR FOR OUTPUT
 log_registry("Reading config values for cms_nead_seg via smtool. . .");
 $smtool       = "/opt/ericsson/nms_cif_sm/bin/smtool";

 my $nesu_conn = `$smtool -config cms_nead_seg | grep nesuPollrateConnectedNE`;
 my ($digits) = $nesu_conn =~ /(\d+)/;
 $nesu_conn = ($digits * 1.5);          # increased as agreed at meeting with EEIOSN, EPASOFA.
 log_registry("nesuPollrateConnectedNE is $nesu_conn");

 my $nesu_disc = `$smtool -config cms_nead_seg | grep nesuPollrateDisconnectedNE`;
 my ($digits2) = $nesu_disc =~ /(\d+)/;
 $nesu_disc = ($digits2 * 1.5);          # increased as agreed at meeting with EEIOSN, EPASOFA.
 log_registry("nesuPollrateDisconnectedNE is $nesu_disc");

 #$IM_ROOT = "";

 $log_dir      = "$HOME";        # directory for storage of error log files
 $review_cache = "/opt/ericsson/nms_umts_cms_lib_com/bin/run_moscript /opt/ericsson/nms_umts_cms_lib_com/info/XReviewCache.py";
 $review_incon = "/opt/ericsson/nms_umts_cms_lib_com/bin/run_moscript /opt/ericsson/nms_umts_cms_lib_com/info/XReport.py";
 $review_subnet = "/opt/ericsson/nms_umts_cms_lib_com/bin/run_moscript /opt/ericsson/nms_umts_cms_lib_com/info/SubnetworkStatus.py";

my $nammy = `grep SegmentCS= /etc/opt/ericsson/system.env`;
 log_registry("It seems SegmentCS variable is not set in /etc/opt/ericsson/system.env file...") if not $nammy;
 exit "0" if not $nammy;
 chomp($nammy) if $nammy;

 $nammy =~ s/SegmentCS=//;
my @kjk = split /\137/, $nammy;
 $nammy = $kjk[1];
 $segment_CS   = "Seg_${nammy}_CS";

 $nammy        = `grep RegionCS= /etc/opt/ericsson/system.env`;
 $nammy        =~ s/RegionCS=//g;
 $nammy        =~ s/\n[a-zA-z\_]*//g;
 $region_CS    = $nammy;
 $cs_log_file  = "$HOME/cs_test.log";
 $start_databases ="/opt/ericsson/nms_umts_cms_lib_com/bin/start_databases.sh ";   ### valid for R4.

 $isql_cmd     = "/opt/sybase/sybase/OCS-15_0/bin/isql"; 
#### NBNBNB /opt/Ericsson/nms_umts_wranmom/bin/ for R5 ###

 $nead_dir     = path_to_managed_component("cms_nead_seg");
 log_registry("It seems no nead directory specified...") if not $nead_dir;
 test_failed($test_slogan) if not $nead_dir;
 exit "0" if not $nead_dir;
 $snad_dir     = path_to_managed_component("cms_snad_reg");
 log_registry("It seems no snad directory specified...") if not $snad_dir;
 test_failed($test_slogan) if not $snad_dir;
 exit "0" if not $snad_dir;

 $rute = `grep IM_ROOT= /etc/opt/ericsson/system.env`;
 log_registry("It seems IM_ROOT variable is not set in /etc/opt/ericsson/system.env file...") if not $rute;
 exit "0" if not $rute;
 chomp($rute);
 $rute =~ s/IM_ROOT=SubNetwork=//;


 $start_adjust = "/opt/ericsson/fwSysConf/bin/startAdjust.sh sync true BaseMo SubNetwork=$rute";


 $snad_log     = "$snad_dir/$rute" . "_R_NEAD.log";

 $top_one = "SubNetwork=" . "$rute" . "_R";

 log_registry("snad_log is $snad_log");
 $nead_log     = "$nead_dir/Seg_${nammy}_NEAD.log";

 log_registry("Looking for NEAD LOG at $nead_log . . .");

 my $maf_log      = "";
 my $PLMN = "ExternalGsmPlmn=15-15";

 #$ExternalGsmPlmn = "dummy";

 $tail_command = "$nead_log";        # "tail -f $nead_log";
 $tail_command_snad = "$snad_log";    # = "tail -f $snad_log";

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
 $all = "";

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

 $mo_master_cms = "CMSAUTOMASTER_1"; # This variable represents the name of MOs getting created by this script

######################################################################

my $usage = <<"USAGE";
Usage:   nead.pl [-t testcase]

   -t testcase  This can be the last significant digits (e.g. 1.2.1) of the testcase slogan or
		the whole testcase slogan (e.g. FUT4385_1.2.1)
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

 log_registry("Usage => $usage");
 print $usage;
 exit;

}


=head1 NAME

nead.pl - Perl script for testing NEAD.

=head1 SYNOPSIS

  nead.pl [-t testcase]

   -t testcase  This can be the last significant digits (e.g. 1.2) of the testcase slogan or
		the whole testcase slogan (e.g. FUT4385_1.2)

   -h, --help
		display this help and exit
    --verbose
		output additional information
    --version
		output version information and exit






The --verbose option produces some additional information such as the values of the attributes.


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2006 Ericsson

=cut


=head1 Introduction

=cut

=head1  Assumptions and General Preconditions

For an individual testcase to run, all nodes must be connected and synchronized.
The managed components used must be online/started. 




=cut




=head1 TestCases


zdasdfgasdgasd

=cut



if ($help)
{
   log_registry("Usage => $usage");
   print "$usage";
   exit;
}
elsif ($version)
{
   log_registry("Version is $VERSION");
   print "Version is $VERSION\n";
   exit;
}
elsif ($testcase)
{
   die "Must give at least the three digit sequence of the testcase slogan - $testcase not valid\n" unless $testcase =~ m/\d+\.\d+\.\d+$/;      # must give at least three digit sequence, e.g. 2.1.1

    ($test_slogan) = grep {/\_$testcase\b/} @testcases;      # find the test_slogan in the testcases list
   die "Testcase $testcase not found\n" unless $test_slogan;
   log_registry("Testcase is $test_slogan");
   print "Testcase is $test_slogan\n\n" if $debug;
   do_test($test_slogan);
   sybase_event_log();
}
elsif ($all)   # do all tests
{
   for my $test_slogan (@testcases)
   {
      do_test($test_slogan);
      sybase_event_log();
   }
}
else
{
   log_registry("Usage => $usage");
   print "$usage";
   exit;
}

# testcase routines

sub FUTDUMM #9.99.9 dummy for development
{
#        my $base_fdn = "SubNetwork=ONRM_RootMo_R,MeContext=LTE06ERBS00042,ManagedElement=1,ENodeBFunction=1,Cdma2000Network=1,Cdma2000FreqBand=CMSAUTOPROXY_1";
#        log_registry("Looks like $base_fdn...");
#        my $mo_exist = does_mo_exist_NE($base_fdn);

#        log_registry(" returned is $mo_exist ...");

#  	

#        my $base_fdn = "SubNetwork=ONRM_ROOT_MO_R,SubNetwork=ERBS-SUBNW-1,MeContext=LTE01ERBS00027,ManagedElement=1,ENodeBFunction=1,EUtranCellFDD=LTE01ERBS00027-4,EUtranFreqRelation=E4,EUtranCellRelation=CMSAUTOPROXY_1";

        #my $clean_issue = delete_mo_CS( mo => $base_fdn);
        #log_registry("Warning => $clean_issue");
        
        log_registry("Warning => ");
        
        my $get_cell = get_master("SubNetwork=ONRM_ROOT_MO_R,ExternalGsmCell=GsmCell");
        log_registry("Warning => $get_cell  ");

        my $get_plmn = get_master("SubNetwork=ONRM_ROOT_MO_R,ExternalGsmPlmn=1");
        log_registry("Warning => $get_plmn  ");

        my $get_prox_cell = get_proxy("SubNetwork=ONRM_ROOT_MO_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,ExternalGsmNetwork=4,ExternalGsmCell=99");
        log_registry("Warning => $get_prox_cell  ");

}





sub FUTDUXX #9.98.9 dummy for development
{
   #test_passed($test_slogan) if ($rev_d == 1);
   #test_failed($test_slogan) if ($rev_d != 1);
	
   my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_; 

   my $rnc="$top_one,SubNetwork=CMSAuto,MeContext=CMSAuto";
   my $rbs="$top_one,SubNetwork=CMSAuto,MeContext=CMSAutoRBS";
   my $erbs="$top_one,MeContext=CMSAutoERBS";
   my $ranag="$top_one,MeContext=CMSAutoRXI";
   
   
   my $RC_bef = rev_bef($test_slogan);
   my ($state_rnc, $rev_rnc) = rev_find(file => $RC_bef ,mo => $rnc.",ManagedElement=1,RncFunction=1");
   log_registry("hello.... $state_rnc : $rev_rnc ");
   my ($state_rbs, $rev_rbs) = rev_find(file => $RC_bef ,mo => $rbs.",ManagedElement=1,NodeBFunction=1,Iub=1");
   my ($state_erbs, $rev_erbs) = rev_find(file => $RC_bef ,mo => $erbs.",ManagedElement=1,ENodeBFunction=1");
   if ($state_rnc || $state_rbs || $state_erbs)
   {
        log_registry("Looks like all Nodes exist in Review Cache ok...");
   }
   else
   {
        log_registry("Looks like Nodes don't exist in Review Cache Not Ok ...");
        log_registry("will carry on with delete ");
   }


   my %xyz = get_mo_attributes_CS(mo => $rbs, attributes => "fdnOfRncIubLink");
   log_registry("fdnOfRncIubLink $xyz{fdnOfRncIubLink} "); 
   my $mo_fdn     = mo_name_is_OK($xyz{fdnOfRncIubLink}, qr/SubNetwork=\S+/);
   unless ($mo_fdn)
   {
		   log_registry("It seems fdnOfRncIubLink is not set...");
		   test_failed($test_slogan); 
		   return;
   }

   %xyz = get_mo_attributes_CS(mo => $xyz{fdnOfRncIubLink}, attributes => "iubLinkNodeBFunction");
   log_registry("iubLinkNodeBFunction $xyz{iubLinkNodeBFunction} ");
   $mo_fdn     = mo_name_is_OK($xyz{iubLinkNodeBFunction}, qr/SubNetwork=\S+/);
   unless ($mo_fdn)
   {
		   log_registry("It seems iubLinkNodeBFunction is not set...");
		   test_failed($test_slogan); 
		   return;
   }
   %xyz = get_mo_attributes_CS(mo => $xyz{iubLinkNodeBFunction}, attributes => "nodeBFunctionIubLink");
   log_registry("nodeBFunctionIubLink $xyz{nodeBFunctionIubLink} ");
   $mo_fdn     = mo_name_is_OK($xyz{nodeBFunctionIubLink}, qr/SubNetwork=\S+/);
   unless ($mo_fdn)
   {
		   log_registry("It seems nodeBFunctionIubLink is not set...");
		   test_failed($test_slogan); 
		   return;
   }

   %xyz = get_mo_attributes_CS(mo => $rbs, attributes => "rbsIubId");
   log_registry("rbsIubId $xyz{rbsIubId} "); 
   if ($xyz{rbsIubId} ne "1")
   {
		   log_registry("It seems rbsIubId is not set to 1 ...");
		   test_failed($test_slogan); 
		   return;
   }

}



=begin
=end

=cut

=head2 10.1

INPUT: /opt/ericsson/atoss/tas/WR_CMS/INPUT/cmslsv.xml - XML file of nodes to be imported via ARNE
OUTPUT:  
PRECONDITIONS:




=cut


sub FUTCLEANUP # Shell TestCase for cleanups
{
# Any cleanup can be done here with this TestCase...
# Always remove added RNC,RBS,RXi,Erbs as it could be added on different servers  

  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.27;Delete NEs after CMS upgrade, check NE's removed from Cache; ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
# Delete first if the node exists via arne

  log_registry("Check if node added in TC 1.1 exist and remove them now \n");

  my $rnc="$top_one,SubNetwork=CMSAuto,MeContext=CMSAuto";
  my $rbs="$top_one,SubNetwork=CMSAuto,MeContext=CMSAutoRBS";
  my $erbs="$top_one,MeContext=CMSAutoERBS";
  my $ranag="$top_one,MeContext=CMSAutoRXI";

  my $RC_bef = rev_bef($test_slogan);
  # rev_find will return number and MoFDN, number is whether mo is consistent, inconsistent...... in cache..
  
  my ($state_rnc, $rev_rnc) = rev_find(file => $RC_bef ,mo => $rnc.",ManagedElement=1,RncFunction=1");
  my ($state_rbs, $rev_rbs) = rev_find(file => $RC_bef ,mo => $rbs.",ManagedElement=1,NodeBFunction=1,Iub=1");
  my ($state_erbs, $rev_erbs) = rev_find(file => $RC_bef ,mo => $erbs.",ManagedElement=1,ENodeBFunction=1");
  if ($state_rnc || $state_rbs || $state_erbs)
  {
        log_registry("Looks like all Nodes exist in Review Cache ok...");
  }
  else
  {
        log_registry("Looks like Nodes don't exist in Review Cache Not Ok ...");
        log_registry("Will carry on with delete, as we want to do Clean UP ");
  }

  my $resultrnc = does_mo_exist_CS( mo => $rnc );
  my $resulterbs = does_mo_exist_CS( mo => $erbs );

  log_registry("Check $resultrnc  \n Check $resulterbs \n");

  if ($resultrnc == $result_code_CS{MO_DOESNT_EXIST} && $resulterbs == $result_code_CS{MO_DOESNT_EXIST})
  {
   log_registry("Nodes are not in the CS \n");
  }
  elsif ($resultrnc == $result_code_CS{MO_ALREADY_EXISTS} || $resulterbs == $result_code_CS{MO_ALREADY_EXISTS})
  {
   my $flag = change_Root_In_Xml();
   return "0" if $flag;
  
   $ror = `/opt/ericsson/arne/bin/import.sh -import -f /opt/ericsson/atoss/tas/WR_CMS/INPUT/cmslsv-DEL.xml `;
   log_registry("\n\n\n $ror \n\n\n");
  }
  else
  {
   log_registry("Error code is $result");
  }
  
  my $time = sleep_start_time();
  long_sleep_found($time);

  #log_registry("waiting 720 seconds... ");
  #sleep 720; # what is the minimum time we can wait when nead/snad go online again,for the synchstatus to be updated.

  my $RC_aft = rev_aft($test_slogan);   
  ($state_rnc, $rev_rnc) = rev_find(file => $RC_aft ,mo => $rnc.",ManagedElement=1,RncFunction=1");
  ($state_rbs, $rev_rbs) = rev_find(file => $RC_aft ,mo => $rbs.",ManagedElement=1,NodeBFunction=1,Iub=1");
  ($state_erbs, $rev_erbs) = rev_find(file => $RC_aft ,mo => $erbs.",ManagedElement=1,ENodeBFunction=1");

  if ($state_rnc || $state_rbs || $state_erbs)
  {
        log_registry("Looks like all Nodes still exist in Review Cache ok...");
        test_failed($test_slogan); 
	return;
  }
  else
  {
        log_registry("Looks like Nodes don't exist in Review Cache Not Ok ...");
  }

  test_passed($test_slogan);

  stop_log_nead();
  stop_log_snad();

}



sub change_Root_In_Xml
{
	log_registry("$top_one    $rute");
	my $result = `cp /opt/ericsson/atoss/tas/WR_CMS/INPUT/cmsDEL.xml  /opt/ericsson/atoss/tas/WR_CMS/INPUT/cmslsv-DEL.xml`;
	$result = `sed -e 's/SubNetwork=REPLACE/SubNetwork=$rute/' /opt/ericsson/atoss/tas/WR_CMS/INPUT/cmslsv-DEL.xml >  /opt/ericsson/atoss/tas/WR_CMS/INPUT/copy-DEL.xml`;
        $result = `mv /opt/ericsson/atoss/tas/WR_CMS/INPUT/copy-DEL.xml /opt/ericsson/atoss/tas/WR_CMS/INPUT/cmslsv-DEL.xml`;

	if (-e "/opt/ericsson/atoss/tas/WR_CMS/INPUT/cmslsv-DEL.xml" )    		 
	{
		return "0";
	}
	else
	{
		log_registry("Sorry, problems have arisen with reading and writing to /opt/ericsson/atoss/tas/WR_CMS/INPUT/cmslsv-DEL.xml\n");
		return "1";
	}

}



=head2 1.1

INPUT: /opt/ericsson/atoss/tas/WR_CMS/INPUT/cmslsv.xml - XML file of nodes to be imported via ARNE
OUTPUT:  
PRECONDITIONS:

=cut

sub FUT4384   # 1.1
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.1;Add/Synch NEs after CMS upgrade or initial installation; ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
# Delete first if the node exists via arne

  log_registry("Check if node already exists and Delete it first ");

  my $rnc="$top_one,SubNetwork=CMSAuto,MeContext=CMSAuto";
  my $rbs="$top_one,SubNetwork=CMSAuto,MeContext=CMSAutoRBS";
  my $erbs="$top_one,MeContext=CMSAutoERBS";
  my $ranag="$top_one,MeContext=CMSAutoRXI";

  my $result = does_mo_exist_CS( mo => $rnc );
  if ($result == $result_code_CS{MO_DOESNT_EXIST})
  {
   log_registry("MO doesn't exist");
  }
  elsif ($result == $result_code_CS{MO_ALREADY_EXISTS})
  {
   $ror = `/opt/ericsson/arne/bin/import.sh -import -f /opt/ericsson/atoss/tas/WR_CMS/INPUT/cmslsv-DEL.xml `;
   log_registry("MO_ALREADY_EXISTS => $ror");
   sleep 240;
  }
  else
  {
   log_registry("Error code is $result, error message is $result_string_CS{$result}");
  }

# ADD via arne

  $ror = `/opt/ericsson/arne/bin/import.sh -f /opt/ericsson/atoss/tas/WR_CMS/INPUT/cmslsv.xml -val:rall -i_nau`;
  log_registry("$ror");

  $ror = `/opt/ericsson/arne/bin/import.sh -import -f /opt/ericsson/atoss/tas/WR_CMS/INPUT/cmslsv.xml -i_nau`;
  log_registry("$ror");

  log_registry("Waiting for 240 seconds... ");
  sleep 240;

# if RNC is syncd then other nodes should be syncd by then.

  wait_for_rnc_sync();

  my @newNodes = get_mo_list_for_class_CS ( mo  => "MeContext");
  for my $rrr (@newNodes)
  {
   if ($rrr =~ "CMSAuto")
   {
        log_registry("$rrr");
	my %rezzy = get_mo_attributes_CS( mo => $rrr, attributes => "mirrorMIBsynchStatus");
	my $sync = $rezzy{mirrorMIBsynchStatus};
        log_registry("$sync");
	if (0+$sync != 3)
  	{  
		   log_registry("It seems other nodes are not in sync...");
		   test_failed($test_slogan); 
		   return;
	}
   }
  }


  log_registry("Waiting for 300 seconds... ");
  sleep 300;

   my $RC_name = rev_aft($test_slogan);   
   my %xyz = get_mo_attributes_CS(mo => $rbs, attributes => "fdnOfRncIubLink");
   log_registry("fdnOfRncIubLink $xyz{fdnOfRncIubLink} "); 
   my $mo_fdn     = mo_name_is_OK($xyz{fdnOfRncIubLink}, qr/SubNetwork=\S+/);
   unless ($mo_fdn)
   {
		   log_registry("It seems fdnOfRncIubLink is not set...");
		   test_failed($test_slogan); 
		   return;
   }

   %xyz = get_mo_attributes_CS(mo => $xyz{fdnOfRncIubLink}, attributes => "iubLinkNodeBFunction");
   log_registry("iubLinkNodeBFunction $xyz{iubLinkNodeBFunction} ");
   $mo_fdn     = mo_name_is_OK($xyz{iubLinkNodeBFunction}, qr/SubNetwork=\S+/);
   unless ($mo_fdn)
   {
		   log_registry("It seems iubLinkNodeBFunction is not set...");
		   test_failed($test_slogan); 
		   return;
   }
   %xyz = get_mo_attributes_CS(mo => $xyz{iubLinkNodeBFunction}, attributes => "nodeBFunctionIubLink");
   log_registry("nodeBFunctionIubLink $xyz{nodeBFunctionIubLink} ");
   $mo_fdn     = mo_name_is_OK($xyz{nodeBFunctionIubLink}, qr/SubNetwork=\S+/);
   unless ($mo_fdn)
   {
		   log_registry("It seems nodeBFunctionIubLink is not set...");
		   test_failed($test_slogan); 
		   return;
   }

   %xyz = get_mo_attributes_CS(mo => $rbs, attributes => "rbsIubId");
   log_registry("rbsIubId $xyz{rbsIubId} "); 
   if ($xyz{rbsIubId} ne "1")
   {
		   log_registry("It seems rbsIubId is not set to 1 ...");
		   test_failed($test_slogan); 
		   return;
   }

   test_passed($test_slogan);
}

=head2 1.2

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut
sub FUT4385   # 1.2
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.2;Offline/Online NEAD Managed Component; ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
    
  my ($before_total_nodes , $before_alive_nodes, $before_dead_nodes, $before_synced_nodes, $before_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($before_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($before_total_nodes eq "NONE");
  return "0" if ($before_total_nodes eq "NONE");

  # Turn down the time nead waits before pinging nodes
  # This should speed up nodes being reconnected and resynched
  # Then we can compare node counts better.

  `$smtool -set cms_nead_seg nesuPollrateDisconnectedRBS 90`;
  `$smtool -set cms_nead_seg nesuPollrateDisconnectedERBS 90`;


  managed_component("cms_nead_seg", "offline", 5) or die "Offline of cms_nead_seg failed\n";
  managed_component("cms_nead_seg", "online", 30) or die "Online of cms_nead_seg failed\n";
  log_registry("waiting 10 minutes...");
  sleep 720; # what is the minimum time we can wait when nead goes online again, for the synchstatus to be updated.
  wait_for_rnc_sync();

  # Wait 10 minutes or there abouts checking to see if we have nodes synching now....
  if (wait_10_for_sync())
  {  
        log_registry("Looks like all nodes are synched now");
  }
  else
  {  
     log_registry("It seems nodes are not in sync....."); 
     test_failed($test_slogan);   
     return;
  }

  my ($after_total_nodes , $after_alive_nodes, $after_dead_nodes, $after_synced_nodes, $after_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($after_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($after_total_nodes eq "NONE");
  return "0" if ($after_total_nodes eq "NONE");

  log_registry("Before: total_nodes=$before_total_nodes ,alive_nodes=$before_alive_nodes, dead_nodes=$before_dead_nodes, synced_nodes=$before_synced_nodes,never_nodes=$before_never_nodes");
  log_registry("After: total_nodes=$after_total_nodes ,alive_nodes=$after_alive_nodes, dead_nodes=$after_dead_nodes, synced_nodes=$after_synced_nodes, never_nodes=$after_never_nodes");

  if ($before_total_nodes == $after_total_nodes)
  {  
        log_registry("before_total_nodes $before_total_nodes = after_total_nodes $after_total_nodes");
        test_passed($test_slogan);
        return;
  }
  else
  {  
     	log_registry("before_total_nodes $before_total_nodes != after_total_nodes $after_total_nodes don't seem to match"); 
        test_failed($test_slogan);  
        return;
  }


  `$smtool -set cms_nead_seg nesuPollrateDisconnectedRBS 420`;
  `$smtool -set cms_nead_seg nesuPollrateDisconnectedERBS 1200`;

}

=head2 1.3

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4386   # 1.3
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.3;Stop/Restart NEAD and SNAD;; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
    
  my ($before_total_nodes , $before_alive_nodes, $before_dead_nodes, $before_synced_nodes, $before_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($before_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($before_total_nodes eq "NONE");
  return "0" if ($before_total_nodes eq "NONE");


  # Turn down the time nead waits before pinging nodes
  # This should speed up nodes being reconnected and resynched
  # Then we can compare node counts better.

  `$smtool -set cms_nead_seg nesuPollrateDisconnectedRBS 90`;
  `$smtool -set cms_nead_seg nesuPollrateDisconnectedERBS 90`;

  managed_component("cms_nead_seg", "offline", 5) or die "Offline of cms_nead_seg failed\n";
  managed_component("cms_snad_reg", "offline", 5) or die "Offline of cms_snad_reg failed\n";
  managed_component("cms_nead_seg", "online", 30) or die "Online of cms_nead_seg failed\n";
  managed_component("cms_snad_reg", "online", 30) or die "Online of cms_snad_reg failed\n";

# check sleep mode in SNAD log ??????????????
  log_registry("Wait for SNAD long Sleep..");
  long_sleep_found();
  
  wait_for_rnc_sync(); 

  # Wait 10 minutes or there abouts checking to see if we have nodes synching now....
  if (wait_10_for_sync())
  {  
	log_registry("Looks like all nodes are synched now");
  }
  else
  {  
     log_registry("It seems all nodes are not in sync...");
     test_failed($test_slogan);   
     return; 
  }

  my ($after_total_nodes , $after_alive_nodes, $after_dead_nodes, $after_synced_nodes, $after_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($after_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($after_total_nodes eq "NONE");
  return "0" if ($after_total_nodes eq "NONE");
  log_registry("Before: total_nodes=$before_total_nodes ,alive_nodes=$before_alive_nodes, dead_nodes=$before_dead_nodes, synced_nodes=$before_synced_nodes,never_nodes=$before_never_nodes");
  log_registry("After: total_nodes=$after_total_nodes ,alive_nodes=$after_alive_nodes, dead_nodes=$after_dead_nodes, synced_nodes=$after_synced_nodes, never_nodes=$after_never_nodes");

  if ($before_total_nodes == $after_total_nodes)
  {  
        log_registry("before_total_nodes $before_total_nodes = after_total_nodes $after_total_nodes");
        test_passed($test_slogan);   
	return;
  }
  else
  {  
     	log_registry("before_total_nodes $before_total_nodes != after_total_nodes $after_total_nodes don't seem to match"); 
        test_failed($test_slogan); 
	return;
  }

  `$smtool -set cms_nead_seg nesuPollrateDisconnectedRBS 420`;
  `$smtool -set cms_nead_seg nesuPollrateDisconnectedERBS 1200`;

}

=head2 1.4

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4387   # 1.4
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.4;Offline/Online cms_nead_seg/cms_snad_reg/Region_CS/Seg_masterservice_CS;  ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
  my ($before_total_nodes , $before_alive_nodes, $before_dead_nodes, $before_synced_nodes, $before_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($before_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($before_total_nodes eq "NONE");
  return "0" if ($before_total_nodes eq "NONE");
  managed_component("cms_nead_seg", "offline", 5) or die "Offline of cms_nead_seg failed\n";
  managed_component("cms_snad_reg", "offline", 5) or die "Offline of cms_snad_reg failed\n";
  managed_component("Region_CS",    "offline", 5) or die "Offline of Region_CS failed\n";
  managed_component("$segment_CS",  "offline", 5) or die "Offline of $segment_CS failed\n";
  managed_component("cms_nead_seg", "online", 10) or die "Online of cms_nead_seg failed\n";
  managed_component("cms_snad_reg", "online", 30) or die "Online of cms_snad_reg failed\n";
#  unless (check_snad_log($test_slogan, "Failed to start SNAD"))  # a SNAD error condition expected here
#  {
#    test_failed($test_slogan);
#    return;
#  }
  log_registry("Sleeping for 3 minutes");
  sleep 180; # wait for 3 minutes
  managed_component("Region_CS", "online", 30) or die "Online of Region_CS failed\n";
  managed_component("$segment_CS", "online", 30) or die "Online of $segment_CS failed\n";
# check sleep mode in SNAD log ??????????????
  log_registry("Wait for SNAD long Sleep..");
  long_sleep_found();

  wait_for_rnc_sync();

  my ($after_total_nodes , $after_alive_nodes, $after_dead_nodes, $after_synced_nodes, $after_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($after_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($after_total_nodes eq "NONE");
  return "0" if ($after_total_nodes eq "NONE");
  log_registry("Before: total_nodes=$before_total_nodes ,alive_nodes=$before_alive_nodes, dead_nodes=$before_dead_nodes, synced_nodes=$before_synced_nodes,never_nodes=$before_never_nodes");
  log_registry("After: total_nodes=$after_total_nodes ,alive_nodes=$after_alive_nodes, dead_nodes=$after_dead_nodes, synced_nodes=$after_synced_nodes, never_nodes=$after_never_nodes");

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

=head2 1.5

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4388   # 1.5
{

  log_registry("TestCase 1.5 will fail most of the time when run after TC 1.3");
  log_registry("This can be cause not all nodes come back alive after nead restart in TC 1.3");

  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.5;Offline/Online SNAD Managed Component; ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
    
  my ($before_master_MOs, $before_proxy_MOs, $before_unmanaged_MOs) = get_review_cache_MOs();
  log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($before_master_MOs eq "NONE");
  test_failed($test_slogan) if ($before_master_MOs eq "NONE");
  return "0" if ($before_master_MOs eq "NONE");
  my ($before_total_nodes , $before_alive_nodes, $before_dead_nodes, $before_synced_nodes, $before_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($before_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($before_total_nodes eq "NONE");
  return "0" if ($before_total_nodes eq "NONE");
  log_registry("Run SubnetworkStatus.py script output is in /var/tmp/RCFUT4388-B.$$");
  `$review_subnet > /var/tmp/RCFUT4388-B.$$`;


  managed_component("cms_snad_reg", "offline", 5) or die "Offline of cms_snad_reg failed\n";
  managed_component("cms_snad_reg", "online", 36) or die "Online of cms_snad_reg failed\n";


#  check sleep mode in SNAD log ??????????????
  log_registry("Wait for SNAD long Sleep..");
  long_sleep_found();

  # Wait 10 minutes or there abouts checking to see if we have nodes synching now....
  if (wait_10_for_sync())
  {  
	log_registry("Looks like all nodes are synched now");	
  }
  else
  {  
     log_registry("It seems all nodes are not in synch....");
     test_failed($test_slogan);   
     return;
  }
  # need the new wait for snad long sleep function here.


  my ($after_total_nodes , $after_alive_nodes, $after_dead_nodes, $after_synced_nodes, $after_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($after_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($after_total_nodes eq "NONE");
  return "0" if ($after_total_nodes eq "NONE");
  log_registry("Before: total_nodes=$before_total_nodes ,alive_nodes=$before_alive_nodes, dead_nodes=$before_dead_nodes, synced_nodes=$before_synced_nodes,never_nodes=$before_never_nodes");
  log_registry("After: total_nodes=$after_total_nodes ,alive_nodes=$after_alive_nodes, dead_nodes=$after_dead_nodes, synced_nodes=$after_synced_nodes, never_nodes=$after_never_nodes");

  log_registry("Going to generate Inconsistency Report from Report.py");
  `$review_incon`;
  log_registry("Going to generate SubnetworkStatus Report output is in /var/tmp/RCFUT4388-A.$$");
  `$review_subnet > /var/tmp/RCFUT4388-A.$$`;

  my ($after_master_MOs, $after_proxy_MOs, $after_unmanaged_MOs) = get_review_cache_MOs();
  log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($after_master_MOs eq "NONE");
  test_failed($test_slogan) if ($after_master_MOs eq "NONE");
  return "0" if ($after_master_MOs eq "NONE");
  if ((  $after_master_MOs    ne $before_master_MOs )     or
     ( $after_proxy_MOs     ne $before_proxy_MOs   )    or
	( $after_unmanaged_MOs ne $before_unmanaged_MOs))
  {
    log_registry("********** Totals don't match in SNAD ReviewCache **********");
    log_registry("********** Use script diff-RevCacheII.pl to check the difference between before and After ReviewCache files **********");

    log_registry("Before:  $before_master_MOs, $before_proxy_MOs, $before_unmanaged_MOs");
    log_registry("After :  $after_master_MOs, $after_proxy_MOs, $after_unmanaged_MOs");
    my ($total_nodes, $synced_nodes) = check_nead_status("TOTAL_NODES", "SYNCED_NODES");   # 
#    test_failed($test_slogan);
#    return;
  }
    log_registry("Before:  $before_master_MOs, $before_proxy_MOs, $before_unmanaged_MOs");
    log_registry("After :  $after_master_MOs, $after_proxy_MOs, $after_unmanaged_MOs\n");

  if ($before_total_nodes == $after_total_nodes)
  {  
        log_registry("before_total_nodes $before_total_nodes = after_total_nodes $after_total_nodes");
        test_passed($test_slogan);  
        return; 
  }
  else
  {  
     	log_registry("before_total_nodes $before_total_nodes != after_total_nodes $after_total_nodes don't seem to match"); 
        test_failed($test_slogan);  
	return;
  }
}

=head2 1.6

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4389   # 1.6
{
 my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
 my $tc_info = "WRANCM_CMSNead_1A_R_1.1.6;Stop/Start a RNC or RBS for 5 minutes; ; 1";
 $test_slogan = "$test_slogan"."-"."$tc_info";
 log_registry("$tc_info"); 
 
 my $rnc = pick_an_rnc();   # randomly select one

 my ($result, $sim, $node) = get_sim_info("$rnc");

 if ($result)
 {
    log_registry("Error code is $result, error message is $result_code_NE{$result}");
    log_registry("Something happened in get_sim_info $rnc");
    test_failed($test_slogan);
    return;
  }
  else
  {
    log_registry("Sim is $sim\nNode is $node");
  }

  my ($dead_nodes, $unsynced_nodes) = check_nead_status("DEAD_NODES", "UNSYNCED_NODES");
  log_registry("It seems count of Dead or Unsynched nodes is not available...") if ($dead_nodes eq "NONE");
  test_failed($test_slogan) if ($dead_nodes eq "NONE");
  return "0" if ($dead_nodes eq "NONE");
  log_registry("dead_nodes=$dead_nodes, unsynced_nodes=$unsynced_nodes");
  my $result_command = do_netsim_command('.stop', $rnc, $sim, $node);
  log_registry("Stopping simulated NE...");
  if ($result_command)
  {
	log_registry("result = $result_command");
  }
  log_registry("waiting $nesu_conn seconds before checking...");
  sleep $nesu_conn;

#do initial check here i.e. result 1.
# check NE is unsynch and count Dead Nodes

  my @ch = split /\054/, $rnc;
  my $mec = "$ch[0],$ch[1],$ch[2]";    # mecontext 
  log_registry("CHECKing CS mirrorMIBsynchStatus (4=>unsynched) for RNC:  $mec");
  print "synchstate = ";
  my %rezzy = get_mo_attributes_CS( mo => $mec, attributes => "mirrorMIBsynchStatus");
  my $sync = $rezzy{mirrorMIBsynchStatus};
  log_registry("synchstate = $sync");
  if (0+$sync != 4)
  {
  # fail and cleanup i.e. start the node and wait for synch
    log_registry("0+$sync != 4 ");
    test_failed($test_slogan);
    do_netsim_command(".start", $rnc, $sim, $node);
    sleep $nesu_disc;
    wait_for_rnc_sync ();
    return;
  }  
  
  ($dead_nodes, $unsynced_nodes) = check_nead_status("DEAD_NODES", "UNSYNCED_NODES");
  log_registry("It seems count of Dead or Unsynched nodes is not available...") if ($dead_nodes eq "NONE");
  test_failed($test_slogan) if ($dead_nodes eq "NONE");
  return "0" if ($dead_nodes eq "NONE");
  log_registry("dead_nodes=$dead_nodes, unsynced_nodes=$unsynced_nodes");

  log_registry("Starting simulated NE... ");
  do_netsim_command(".start", $rnc, $sim, $node);
  log_registry("waiting $nesu_disc seconds before checking... ");

  sleep $nesu_disc;


  wait_for_rnc_sync (); # need to supervise this... in case it never finishes.... ###
  ($dead_nodes, $unsynced_nodes) = check_nead_status("DEAD_NODES", "UNSYNCED_NODES");
  log_registry("It seems count of Dead or Unsynched nodes is not available...") if ($dead_nodes eq "NONE");
  test_failed($test_slogan) if ($dead_nodes eq "NONE");
  return "0" if ($dead_nodes eq "NONE");
  log_registry("dead_nodes=$dead_nodes, unsynced_nodes=$unsynced_nodes");

  $sync = get_synch_status($rnc);
  if ($sync == "3" )
  {  test_passed($test_slogan);   }
  else
  {  test_failed($test_slogan);   }
}

=head2 1.7

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4390   # 1.7
{
  log_registry("TestCase 1.7 will fail if we pick a small RNC");
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.7;Stop an RNC or an RBS while performing a synch;; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");  
  
  my ($before_total_nodes , $before_alive_nodes, $before_dead_nodes, $before_synced_nodes, $before_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($before_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($before_total_nodes eq "NONE");
  return "0" if ($before_total_nodes eq "NONE");
  my $count=0;
  my $attempts=0;
  my $max_attempts=10;
  my $rnc="";
  do {
      return $count if $attempts++ > $max_attempts;
      $rnc = pick_an_rnc();
      $count = `$cstest -s $segment_CS lm $rnc -l 1 -f '\$type_name==UtranCell' | wc -l`;
      log_registry("Found $count Cell, RNC should be large enough !!!!!!");
   } until $count > 70;


  my $mec = get_mec($rnc);
  reset_genc($mec);
  
  #WE NEED to offline NEAD to get reset of GC to work  

  managed_component("cms_nead_seg", "offline", 5) or die "Offline of cms_nead_seg failed\n";

  my $time_to_sleep = 2;
  my $mc = "cms_nead_seg";
  my $operation = "online"; 

  my ($result, $sim, $node) = get_sim_info($mec);
  if ($result)
  {
    log_registry("Error code is $result, error message is $result_code_NE{$result}");
    log_registry("Something happened in get_sim_info $rnc");
    test_failed($test_slogan);
    return;
  }
  else
  {
  log_registry("Sim is $sim");
  log_registry("Node is $node");
  }


# stoping rnc in netsim 

  $result = do_netsim_command('.stop', $rnc, $sim, $node);

# online NEAD Now

  log_registry("Turning $mc $operation");
  managed_component("cms_nead_seg", "online", 30) or die "Online of cms_nead_seg failed\n";



#### need to check here that other nodes synch up ok.
#  this is causing problems if any node is unsynchronized.....................
#  sleep 30;
#  wait_for_all_conn_to_sync ();

  my ($dead_nodes, $unsynced_nodes) = check_nead_status("DEAD_NODES", "UNSYNCED_NODES");
  log_registry("It seems count of Dead or Unsynched nodes is not available...") if ($dead_nodes eq "NONE");
  test_failed($test_slogan) if ($dead_nodes eq "NONE");
  return "0" if ($dead_nodes eq "NONE");
  log_registry("dead_nodes=$dead_nodes, unsynced_nodes=$unsynced_nodes");

  log_registry("Doing start node");
  $result = do_netsim_command('.start', $rnc, $sim, $node);

  my $state = wait_for_sync_status($rnc,1);
  log_registry("It seems selected RNC $rnc is not come back into state 1 after getting start since last 1 hr") if not $state;
  test_failed("$test_slogan") if not $state;
  return "0" if not $state;

# stop node for nesu x 1.1 (2.2) and then start again... wait for this node to sync fully.
  $result = do_netsim_command('.stop', $rnc, $sim, $node);

  log_registry("Waiting $nesu_conn seconds... ");
  sleep $nesu_conn;

  $result = do_netsim_command('.start', $rnc, $sim, $node);

  $state = wait_for_sync_status($rnc,3);
  log_registry("It seems selected RNC $rnc is not come back into state 3 after getting start since last 1 hr") if not $state;
  test_failed("$test_slogan") if not $state;
  return "0" if not $state;

  wait_for_rnc_sync();

  my ($after_total_nodes , $after_alive_nodes, $after_dead_nodes, $after_synced_nodes, $after_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($after_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($after_total_nodes eq "NONE");
  return "0" if ($after_total_nodes eq "NONE");
  log_registry("Before: total_nodes=$before_total_nodes ,alive_nodes=$before_alive_nodes, dead_nodes=$before_dead_nodes, synced_nodes=$before_synced_nodes,never_nodes=$before_never_nodes");
  log_registry("After: total_nodes=$after_total_nodes ,alive_nodes=$after_alive_nodes, dead_nodes=$after_dead_nodes, synced_nodes=$after_synced_nodes, never_nodes=$after_never_nodes");

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

=head2 1.8

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4391   # 1.8

{   # need to reset generation counter to be sure ???

  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.8; Manual Synch; ;1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");  
  my $rnc = pick_an_rnc();
  my $mec = get_mec($rnc);
  log_registry("ADJUSTing via CStest: $mec ");
  my $plan = " ";
  my $cs_server = "Region_CS";
  #my $cstest = "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest";
  my $res =`$cstest $plan -s $cs_server adjust $mec`;
  log_registry("$res");
  log_registry("Waiting $nesu_conn seconds... ");
  sleep $nesu_conn;
  wait_for_rnc_sync();

  my @temp = split /\054/, $rnc;
  my @npart = split /\075/,$temp[1];
  my $np = "\U$npart[1]\E";

  my $sync = get_synch_status($rnc);
  if ($sync == "3" )
  {  test_passed($test_slogan);   }
  else
  {  test_failed($test_slogan);   }



# wait_for_long_sleep(); # to protect 1.9 or other immediately subsequent TC when running in batch

  log_registry("waiting 720 seconds... ");
  sleep 720; # what is the minimum time we can wait when nead/snad go online again,for the synchstatus to be updated.

}

=head2 1.9

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4392   # 1.9
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.9;Activate a Planned Area Configuration/Create MO using Common Explorer; ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
# get_review_cache_MOs need updating 
#  my ($before_master_MOs, $before_proxy_MOs, $before_unmanaged_MOs) = get_review_cache_MOs();

  rev_bef($test_slogan);
  my $cell = create_cell();
  return "0" if not $cell;
  # wait_for_long_sleep();
  log_registry("waiting 720 seconds... ");
  sleep 720; # what is the minimum time we can wait

  my $RC_name = rev_aft($test_slogan);   

  my $result = rev_find( mo => $cell , file => $RC_name);
  
  #  if file found and MO found in file then do report of cache as well....
  #  testcase will currently pass if UtranCell is being managed by SNAD and is in the cache, regardless of whether it is consistent or not. Need to create additional MOs along with UtranCell for it to be consistent. For the moment, testcase pass when MO is in cache only.Code to create additional MOs needs to be looked at. 

   if ($result)
   {
	log_registry("$result");
	rev_comp_add($test_slogan);
        test_passed($test_slogan);
   }
   else
   {
        log_registry("$result");
        test_failed($test_slogan);
   }
}

=head2 1.10

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4393   # 1.10
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.10;Activate a Planned Area Configuration/Set an MO using Common Explorer; ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
  update_cell($test_slogan);     # checks/results in sub...

}

=head2 1.11

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4394   # 1.11
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.11;Activate a Planned Area Configuration/Delete MO using Common Explorer; ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
  # my ($before_master_MOs, $before_proxy_MOs, $before_unmanaged_MOs) = get_review_cache_MOs();

  # Do Review Cache before instead of above ..
  
  rev_bef($test_slogan);

  my $rnc = pick_an_rnc();  
  my $cell = pick_a_cell($rnc);    # Bonus would be: create a cell if NONE exists. But sims come with cells, so OKEY DOKEY..

  my $plan_name = create_plan_name();
  create_plan($plan_name);
  my $plan = "-p $plan_name";
  log_registry("PLAN is $plan... ");

  # for each reservedBy, remove MO

  my %xyz = get_mo_attributes_CS(mo => $cell, attributes => "reservedBy");
  log_registry("reservedBy $xyz{reservedBy} ");

  # Check if returned has is empty or not ....
  if ( keys %xyz )
  {
	my @zzz = split /\040/, $xyz{reservedBy};
	foreach my $resby(@zzz)
	{ 
                log_registry("Deleting reserving MO $resby in planned area $plan: ...  ");
		delete_mo_CS(mo => $resby, plan => $plan_name);
	}
  }

  log_registry(" Deleting Cell $cell in planned area $plan... ");
  my  $result = delete_mo_CS( mo => $cell, plan => $plan_name);
  if ($result)
  {      
    test_failed($test_slogan);
    log_registry("Error code is $result, error message is $result_string_CS{$result}");
    return;
  } 
  #verify that the delete was successful
  $result = does_mo_exist_CS( mo => $cell, plan => $plan_name);

  log_registry("Result of checking if MO exists in plan $plan: $result_string_CS{$result}");

  log_registry("Activating plan.... ");
  my $Activate_result = activate_plan($plan_name);
  if ($Activate_result)
  {
    test_failed($test_slogan);
    log_registry("Error code is $Activate_result, error message is $result_string_CS{$Activate_result}");
    delete_plan($plan_name);
    return;
  }

  #wait for snad long sleep, Mo removed from CS and from ReviewCache
  log_registry("Wait for SNAD long Sleep..");
  sleep 120;# wait for long sleep is too quick
  my $time = sleep_start_time();
  long_sleep_found($time);
  delete_plan($plan_name);

  $result = does_mo_exist_CS( mo => $cell);
  my $sync = get_synch_status($rnc);

  log_registry("Result of checking if MO exists in valid area: $result_string_CS{$result}");

  if (($result == $result_code_CS{MO_DOESNT_EXIST}) && ($sync == 3))
  {
   my $RC_name = rev_aft($test_slogan);   
   $result = rev_find( mo => $cell , file => $RC_name);
   if ($result)
   {
        log_registry("$result ");
	rev_comp_add($test_slogan);
        test_failed($test_slogan);
   }
   else
   {
	rev_comp_add($test_slogan);
        test_passed($test_slogan);
   }
  } 
  else
  {
     test_failed($test_slogan);
     return;
  }
}

=head2 1.15 # Create Mo in the valid Area

INPUT: 
OUTPUT:  
PRECONDITIONS:
=cut

sub FUT4398   # 1.15
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.15;Create an MO in the Valid Area using Common Explorer;  ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  	# Do Review Cache before 
	
	rev_bef($test_slogan);

        my $cell = create_cell_valid();
        if (!$cell)
        { 
   	log_registry(" Problem with the RNC when we tried create Cell");
	test_failed($test_slogan);
	return;
        }
        log_registry("cell is $cell");

	# wait here while mos are entered in the valid CS...
        log_registry("Waiting 120 seconds for MO to be entered in cache. ");
	sleep 120; # wait for 2 minutes

	my $result = does_mo_exist_CS( mo => $cell);
        log_registry(" Result of checking if MO exists in valid area: $result_string_CS{$result}");


        my $sync = get_synch_status($cell);
	
	if (($result == $result_code_CS{MO_ALREADY_EXISTS}) && ($sync == 3))
	{
	my $RC_name = rev_aft($test_slogan);
	$result = rev_find( mo => $cell , file => $RC_name);
	if ($result)
	{
		log_registry("$result");
		rev_comp_add($test_slogan);
		test_passed($test_slogan);
	}
 	else
	{
  		log_registry("$result");
        	test_failed($test_slogan);
	}
  	} 
  	else
  	{
		test_failed($test_slogan);
		return;
	}
}


=head2 1.16

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4399   # 1.16
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.16;Set an MO attribute in the Valid Area using Common Explorer;  ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
    
# update_cell_valid();
  my $rnc = pick_an_rnc();  
  my $cell = pick_a_cell($rnc);    # Bonus would be: create a cell if NONE exists. But sims come with cells, so OKEY DOKEY..
  if (!$cell)
        { 
 	log_registry("Didn't find a Cell to update..");
	test_failed($test_slogan);
	return;
        }

  my ($ul, $dl) = (162, 662);

  my %result = get_mo_attributes_CS( mo => $cell, attributes => "uarfcnUl uarfcnDl");
  my $uarfcnUl = $result{uarfcnUl};
  my $uarfcnDl = $result{uarfcnDl};

  log_registry("Values before setting: uarfcnUl $uarfcnUl uarfcnDl $uarfcnDl ");


  log_registry("setting mo attributes: uarfcnUl $ul uarfcnDl $dl ");
 
  my  $result = set_mo_attributes_CS( mo => $cell, attributes => "uarfcnUl $ul uarfcnDl $dl" );
  if ($result)
  {      
    test_failed($test_slogan);
    log_registry("Error code is $result, error message is $result_code_CS{$result}");
    return;
  } 
  #verify that the update has been successful
  %result = get_mo_attributes_CS( mo => $cell, attributes => "uarfcnUl uarfcnDl");
  $uarfcnUl = $result{uarfcnUl};
  $uarfcnDl = $result{uarfcnDl};

  log_registry("result is uarfcnUl $uarfcnUl uarfcnDl $uarfcnDl ");
  if (!($uarfcnUl ==$ul) and !($uarfcnDl == $dl))
  {
    test_failed($test_slogan);
    return;
  } 
  else
  {  
    test_passed($test_slogan);
  }
}

=head2 1.17

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4400   # 1.17
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.17;Delete an MO in the Valid Area using Common Explorer;  ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
    
# delete_cell_valid();

  my $rnc = pick_an_rnc();  
  my $cell = pick_a_cell($rnc);    # Bonus would be: create a cell if NONE exists. But sims come with cells, so OKEY DOKEY..
  if (!$cell)
        { 
	log_registry("Didn't find a Cell to Delete ");
	test_failed($test_slogan);
	return;
        }
  rev_bef($test_slogan);

# for each reservedBy, remove MO

  my %xyz = get_mo_attributes_CS(mo => $cell, attributes => "reservedBy");
  my @zzz = split /\040/, $xyz{reservedBy};
  foreach my $resby(@zzz)
  { 
  log_registry("Deleting reserving MO: $resby ... ");
  delete_mo_CS(mo => $resby);
  }
 log_registry("Deleting Cell $cell ... ");
  my  $result = delete_mo_CS( mo => $cell);
  if ($result)
  {      
    test_failed($test_slogan);
    log_registry("Error code is $result, error message is $result_code_CS{$result}");
    return;
  } 
  #verify that the delete was successful
  $result = does_mo_exist_CS( mo => $cell);

  log_registry("Result of checking if MO exists: $result");
  # wait_for_long_sleep();
  log_registry("waiting 720 seconds... ");
  sleep 720; # what is the minimum time we can wait

  if (($result == $result_code_CS{MO_DOESNT_EXIST}) ) # && (wait_10_for_sync()))
  {
	my $RC_name = rev_aft($test_slogan);
	$result = rev_find( mo => $cell , file => $RC_name);
   	if ($result)
		{
		log_registry("$result");
		rev_comp_add($test_slogan);
      	  	test_failed($test_slogan);
		}
  	 else
		{
		rev_comp_add($test_slogan);
        	test_passed($test_slogan);
		}
  }
  else
  {
    test_failed($test_slogan);
    return;
  }
}



=head2 1.18

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4401   # 1.18
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.18;Execute CS Test Client script to Create all Master mo's in the Valid Area;  ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");  
  
  # Do Review Cache before 
	
  rev_bef($test_slogan);
  my $result = execute_master_script();
  test_failed($test_slogan) if not $result;
  return "0" if not $result;
  # wait here while mos are entered in the valid CS...
  log_registry("Waiting 120 seconds for MO to be entered in cache. ");
  sleep 120; # wait for 2 minutes

  my $mo = "$top_one,Areas=1,Plmn=master";

  my $check_res =  does_mo_exist_CS( mo => $mo );
  if ($check_res == $result_code_CS{MO_ALREADY_EXISTS})
	{
 	my $RC_name = rev_aft($test_slogan);
  	my $masters = `grep =master $RC_name`;
	log_registry("$masters");

	rev_comp_add($test_slogan);
	test_passed($test_slogan);
	}
 	else
	{
	log_registry("$check_res");
      	test_failed($test_slogan);
	}
}


=head2 1.19

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut
sub FUT4402   # 1.19
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.19;Execute CS Test Client script to Delete all the Master MO s in the Valid Area;  ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
  # Do Review Cache before 
	
  rev_bef($test_slogan);

  my $result = execute_del_master_script();
  test_failed($test_slogan) if not $result;
  return "0" if not $result;
  # wait here while mos are deleted in the valid CS...
  log_registry("Waiting 120 seconds for MO to be entered in cache. ");
  sleep 120; # wait for 2 minutes
  
  my $mo = "$top_one,Areas=1,Plmn=master";
  my $check_res =  does_mo_exist_CS( mo => $mo );

  if ($check_res == $result_code_CS{MO_DOESNT_EXIST})
	{
        my $RC_name = rev_aft($test_slogan);
  	my $masters = `grep =master $RC_name`;
	log_registry("Should BE NO MO Listed here.... $masters");

	rev_comp_add($test_slogan);
	test_passed($test_slogan);
	}
 	else
	{
	log_registry("$check_res");
      	test_failed($test_slogan);
	}
}


=head2 1.20

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4403   # 1.20
{
        # create UtranCell and checks the LA,RA,SA reservedBy
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.20;Test of 'reservedBy' attribute; ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
  my $mark = "PASSED";
  my $workingRNC = pick_an_rnc();
  if($workingRNC)
   {
        my $cell = create_UtranCell($workingRNC);
	test_failed($test_slogan) if not ($cell);
	return "0" if not ($cell);
	log_registry("cell is $cell");
        log_registry("checking reservedBy values for LA, RA and SA...");
	my %rezzy = get_mo_attributes_CS( mo => $cell, attributes => "locationAreaRef routingAreaRef serviceAreaRef");
	my $LA = $rezzy{locationAreaRef};
	my $RA = $rezzy{routingAreaRef};
	my $SA = $rezzy{serviceAreaRef};
	$mark = "FAILED" if not is_resby($LA, $cell);
	$mark = "FAILED" if not is_resby($RA, $cell);
	$mark = "FAILED" if not is_resby($SA, $cell);
    
######################################## end of part 1 ##########################################################

        # create another UtranCell on same RNC
        # create Utran Relation between the 2 new UtranCells.

        my $cell2 = create_UtranCell($workingRNC);
	test_failed($test_slogan) if not ($cell2);
        return "0" if not ($cell2);
	log_registry("cell is $cell2");
	my $utranRel = "$cell,UtranRelation=CMSAUTO";
        my $create_result = create_mo_CS( mo => $utranRel, attributes =>  "qOffset1sn 1 qOffset2sn 1 frequencyRelationType 1 loadSharingCandidate 1 adjacentCell $cell2");  
	if ($create_result)
	{      
		log_registry("Problem in creation of UtranRelation....");
		log_registry("Error code is $create_result, error message is $result_code_CS{$create_result}");
		test_failed($test_slogan);
		return;
	}

        # look at reservedBy of cell1, cell2 and look for Utranrel MO
        log_registry("Check reservedBy in $cell2 ");

	$mark = "FAILED" if not is_resby($cell2, $utranRel);

################################ end of part 2 ####################################################################

        # Pick another UtranCell on a different RNC
        # create Utran Relation between the 2 new UtranCells on different RNCs.

       my $rnc2 = pick_a_different_rnc($workingRNC);   		# Select different RNC than $rnc
       my $cell3 = pick_a_cell($rnc2);				# Select Cell
       if (!$cell3)
       { 
		log_registry("Didn't find a Cell to update ");
		test_failed($test_slogan);
		return;
       }

	$utranRel = "$cell,UtranRelation=CMSAUTO_2";
        $create_result = create_mo_CS( mo => $utranRel, attributes =>  "qOffset1sn 1 qOffset2sn 1 frequencyRelationType 1 loadSharingCandidate 1 adjacentCell $cell3");  
	if ($create_result)
	{      
		log_registry("Problem in creation of UtranRelation....");
		log_registry("Error code is $create_result, error message is $result_code_CS{$create_result}");
		test_failed($test_slogan);
		return;
	}

       # look at reservedBy of Proxy ExternalUtranCell and look for Utranrel MO
        log_registry("Waiting 60 seconds for Proxy ExternalUtranCell attrs to be set. ");
	sleep 60; # wait for 1 minute
	%rezzy = get_mo_attributes_CS( mo => $utranRel, attributes => "utranCellRef");
        my $utranCellRef = $rezzy{utranCellRef};
        log_registry("Check reservedBy in $utranCellRef ");
	$mark = "FAILED" if not is_resby($utranCellRef, $utranRel);

       # look at reservedBy of UtranNetwork and look for IurLink MO

        my ($parent, $mo_class) = $utranCellRef =~ m/(SubNetwork=.*),(\w+)/;
        log_registry("MO class is $mo_class,\tParent is $parent\n");

	%rezzy = get_mo_attributes_CS( mo => $parent, attributes => "utranNetworkRef");
        my $utranNetworkRef = $rezzy{utranNetworkRef};
        log_registry("Check reservedBy in $utranNetworkRef ");
	$mark = "FAILED" if not is_resby($utranNetworkRef, $parent);


################################ end of part 3 ####################################################################

        my $GSMcell = pick_a_MasterMO("ExternalGsmCell");   # pick any exist master GsmCell

	$GSMRel = "$cell,GsmRelation=CMSAUTO";
        $create_result = create_mo_CS( mo => $GSMRel, attributes =>  "selectionPriority 15 adjacentCell $GSMcell");  
	if ($create_result)
	{      
		log_registry("Problem in creation of GsmRelation....");
		log_registry("Error code is $create_result, error message is $result_code_CS{$create_result}");
		test_failed($test_slogan);
		return;
	}

	%rezzy = get_mo_attributes_CS( mo => $GSMRel, attributes => "externalGsmCellRef");
        my $externalGsmCellRef = $rezzy{externalGsmCellRef};
        log_registry("Check reservedBy in $externalGsmCellRef ");
	$mark = "FAILED" if not is_resby($externalGsmCellRef, $GSMRel);

################################ end of part 3 ####################################################################


	%rezzy = get_mo_attributes_CS( mo => $cell, attributes => "utranCellIubLink");
        my $utranCellIubLink = $rezzy{utranCellIubLink};
        log_registry("Check reservedBy in $utranCellIubLink ");
	$mark = "FAILED" if not is_resby($utranCellIubLink, $cell);


        if ($mark eq "PASSED")
	{
		# delete the 2 cells used now.
		delete_mo_CS(mo => $cell);
		delete_mo_CS(mo => $cell2);

		test_passed($test_slogan);
	}
	else
	{
		test_failed($test_slogan);
	}
   }
   else
   {
	test_failed($test_slogan);
   }

}


=head2 1.21

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut

sub FUT4404   # 1.21
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.21;Execute XReviewCache script; ; 3";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");


  my ($before_total_nodes , $before_alive_nodes, $before_dead_nodes, $before_synced_nodes, $before_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($before_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($before_total_nodes eq "NONE");
  return "0" if ($before_total_nodes eq "NONE");
#reviewcache

  log_registry("Run the XReviewCache.py script and check the numbers");

  my ($master_MOs, $proxy_MOs, $unmanaged_MOs) = get_review_cache_MOs();
  log_registry("It seems count of master/proxy and unmanged MO is not available..") if ($master_MOs eq "NONE");
  test_failed($test_slogan) if ($master_MOs eq "NONE");
  return "0" if ($master_MOs eq "NONE");
  log_registry("Masters: $master_MOs");
  log_registry("Proxies: $proxy_MOs");
  log_registry("Unmanaged: $unmanaged_MOs"); 
  my ($after_total_nodes , $after_alive_nodes, $after_dead_nodes, $after_synced_nodes, $after_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($after_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($after_total_nodes eq "NONE");
  return "0" if ($after_total_nodes eq "NONE");
  log_registry("Before: total_nodes=$before_total_nodes ,alive_nodes=$before_alive_nodes, dead_nodes=$before_dead_nodes, synced_nodes=$before_synced_nodes,never_nodes=$before_never_nodes");
  log_registry("After: total_nodes=$after_total_nodes ,alive_nodes=$after_alive_nodes, dead_nodes=$after_dead_nodes, synced_nodes=$after_synced_nodes, never_nodes=$after_never_nodes");

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

=head2 1.23

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut
sub   FUT4406 # _1.23

{

  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  log_registry("Run snad_new.pl -t 11.1 "); 
  log_registry("Its the SAME test............ "); 

}


=head2 1.24

INPUT: 
OUTPUT:  
PRECONDITIONS:




=cut
sub FUT4407	# 1.24
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.1.24;Perform a continous Re-Synch of an RNC/RBS in Netsim ; ;2";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
  my ($before_total_nodes , $before_alive_nodes, $before_dead_nodes, $before_synced_nodes, $before_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($before_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($before_total_nodes eq "NONE");
  return "0" if ($before_total_nodes eq "NONE");
  my $rnc = pick_an_rnc();   # randomly select one
  my ($result, $sim, $node) = get_sim_info("$rnc");
  if ($result)
  {
    log_registry("Error code is $result, error message is $result_code_NE{$result}");
    return;
  }
  else
  {
    log_registry("Sim is $sim");
    log_registry("Node is $node");
  }

for (my $i=1; $i < 6; $i++)
  {
  log_registry("xxxx Iteration $i xxxx");

  my $result_command = do_netsim_command('.stop', $rnc, $sim, $node);
  log_registry("Stopping simulated NE...");
  if ($result_command)
  {
	log_registry("result = $result_command");
  }
  log_registry("waiting $nesu_conn seconds ");
  sleep $nesu_conn;

  my @ch = split /\054/, $rnc;
  my $mec = "$ch[0],$ch[1],$ch[2]";    # mecontext 
  log_registry("CHECKing CS mirrorMIBsynchStatus for RNC:  $mec ");
  my %rezzy = get_mo_attributes_CS( mo => $mec, attributes => "mirrorMIBsynchStatus");
  my $sync = $rezzy{mirrorMIBsynchStatus};
  log_registry("synchstate = $sync ");
  log_registry("Starting simulated NE...");
  do_netsim_command(".start", $rnc, $sim, $node);

  log_registry("waiting $nesu_disc seconds ");
  sleep $nesu_disc;

  @ch = split /\054/, $rnc;
  $mec = "$ch[0],$ch[1],$ch[2]";    # mecontext 
  log_registry("CHECKing CS mirrorMIBsynchStatus for RNC:  $mec ");
  %rezzy = get_mo_attributes_CS( mo => $mec, attributes => "mirrorMIBsynchStatus");
  $sync = $rezzy{mirrorMIBsynchStatus};
  log_registry("synchstate = $sync ");
}
  wait_for_rnc_sync (); # need to supervise this... in case it never finishes.... ###
  my ($dead_nodes, $unsynced_nodes) = check_nead_status("DEAD_NODES", "UNSYNCED_NODES");
  log_registry("It seems count of Dead or Unsynched nodes is not available...") if ($dead_nodes eq "NONE");
  test_failed($test_slogan) if ($dead_nodes eq "NONE");
  return "0" if ($dead_nodes eq "NONE");
  log_registry("dead_nodes=$dead_nodes, before_dead_nodes=$before_dead_nodes unsynced_nodes=$unsynced_nodes");
  if ( $before_dead_nodes != $dead_nodes ) 
  {
	log_registry("It seems dead node count is not same as before...");
	test_failed($test_slogan);
	return;
  }

  my ($after_total_nodes , $after_alive_nodes, $after_dead_nodes, $after_synced_nodes, $after_never_nodes) = nodes_synced();
  log_registry("It seems count of nodes are not available..") if ($after_total_nodes eq "NONE");
  test_failed("$test_slogan") if ($after_total_nodes eq "NONE");
  return "0" if ($after_total_nodes eq "NONE");
  log_registry("Before: total_nodes=$before_total_nodes ,alive_nodes=$before_alive_nodes, dead_nodes=$before_dead_nodes, synced_nodes=$before_synced_nodes,never_nodes=$before_never_nodes");
  log_registry("After: total_nodes=$after_total_nodes ,alive_nodes=$after_alive_nodes, dead_nodes=$after_dead_nodes, synced_nodes=$after_synced_nodes, never_nodes=$after_never_nodes");

  if ($before_total_nodes == $after_total_nodes && $before_alive_nodes == $after_alive_nodes)
  {  
        test_passed($test_slogan);   
  }
  else
  {  
     	log_registry("Node count before Test don't seem to match Node counts after....!!!!"); 
        test_failed($test_slogan);  
  }
  # has been seen to effect 12.4 in cms_lsv so we try and extra 5 minute to left snad recover the RNC
  sleep 360;

}

sub FUT0001 #  1.4.1 Create an MO on NE side
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.4.1; Create an MO on NE side, check that a equivalent MO is created in the mirror MIB; 2";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne(RncFunction);

  if($rnc)
  {
	my ($base_fdn,$attr_full) = get_fdn("Ura","create");
	$base_fdn = base_fdn_modify("$rnc","$base_fdn");
   	log_registry("Base Fdn of MO is: $base_fdn");
 	log_registry("Creation process can be seen in LOG FILE: $cs_log_file by current date & time"); 
	my $result = create_mo_NE(mo => $base_fdn);
	if($result)
	{
		log_registry("There is some issue in creation of Ura MO on NE side, Error Code : $result");
		test_failed($test_slogan);
	}
	else
	{
		log_registry("Wait for 3 mins to get system stabilized....");
		sleep 180;
		my $mo_exist = does_mo_exist_CS(mo => $base_fdn);
		if ($mo_exist == $result_code_CS{MO_ALREADY_EXISTS}) # 5 is the code return by does_mo_exist_CS sub routine if MO exist
          	{
             		log_registry("Mo $base_fdn Exist Result code:$mo_exist ");
             		test_passed($test_slogan);
          	}
          	else
          	{
             		log_registry("Master Mo $base_fdn does not Exist Result code:$mo_exist");
             		test_failed($test_slogan);
          	}
	}
  }
  else
  {
	log_registry("It seems there is no synched RNC found, so leaving Test Case processing....");
	test_failed($test_slogan);
 	return;
  }
}

sub FUT0002 # 1.4.2 Set attributes on MO on NE side
{
   my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
   my $tc_info = "WRANCM_CMSNead_1A_R_1.4.2; Set attributes on MO on NE side, check updates in the mirror MO; ; 2";
   $test_slogan = "$test_slogan"."-"."$tc_info";
   log_registry("$tc_info");
   my ($count,@mo_FDN) = get_CMS_mo(Ura,$mo_master_cms);
   my $count_attr = "";
   if($count)
   {
	my ($base_fdn,$attr) = get_fdn("Ura","set");		
	$base_fdn = $mo_FDN[0];
  	log_registry("Selected MO is: $base_fdn");	
        log_registry("========= Attributes of MO Before =========");
        $count_attr = get_mo_attr($base_fdn,$attr);
        log_registry("===========================================");
	log_registry("Set attributes process can be seen in LOG FILE: $cs_log_file by current date & time");
	my $result = set_mo_attributes_NE(mo => $base_fdn,attributes => $attr);
        if($result)
        {
                log_registry("There is some issue in setting attributes of Ura MO on NE side, Error Code : $result");
                test_failed($test_slogan);
        }
        else
        {
		log_registry("Wait for 3 mins to get system stabilized....");
                sleep 180;
		log_registry("========= Attributes of MO After  =========");
		$count_attr = get_mo_attr($base_fdn,$attr);
		log_registry("===========================================");
		my $mo_exist = does_mo_exist_CS(mo => $base_fdn);
		my $status = attr_value_comp($base_fdn,$attr);
                if ($mo_exist == $result_code_CS{MO_ALREADY_EXISTS} and $status)
                {
                        log_registry("Mo $base_fdn Exist in CS and attributes has been modified sucessfully Result code:$mo_exist");
                        test_passed($test_slogan);
                }
                else
                {
                        log_registry("Master Mo $base_fdn does not Exist Result code:$mo_exist OR Attributes have not modified properly");
                        test_failed($test_slogan);
                }
        }
   }
   else
   {
        log_registry("It seems there is no preexisting Ura type MO of $mo_master_cms, please run the nead.pl with 1.4.1 TC..");
	test_failed($test_slogan);
   }
}

sub FUT0003 # 1.4.3 Delete an MO on the NE side
{
   my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
   my $tc_info = "WRANCM_CMSNead_1A_R_1.4.3; Delete an MO on the NE side, check that the mirror MO is deleted; ; 2";
   $test_slogan = "$test_slogan"."-"."$tc_info";
   log_registry("$tc_info");
   my ($count,@mo_FDN) = get_CMS_mo(Ura,$mo_master_cms);
   if($count)
   {
        $base_fdn = $mo_FDN[0];
	log_registry("Selected MO is : $base_fdn"); 
	log_registry("Delete process can be seen in LOG FILE: $cs_log_file by current date & time");
        my $result = delete_mo_NE(mo => $base_fdn);
        if($result)
        {
                log_registry("There is some issue in deleting of Ura MO on NE side, Error Code : $result");
                test_failed($test_slogan);
        }
        else
        {
		log_registry("Wait for 3 mins to get system stabilized....");
                sleep 180;
		my $mo_exist = does_mo_exist_CS(mo => $base_fdn);
                if ($mo_exist != $result_code_CS{MO_DOESNT_EXIST}) # 6 is the code return by does_mo_exist_CS if MO does not exist
                {
                        log_registry("Master Mo $base_fdn Exist Result code:$mo_exist");
                        test_failed($test_slogan);
                }
                else
                {
                        log_registry("Mo $base_fdn does not Exist Result code:$mo_exist");
                        test_passed($test_slogan);
                }
        }
   }
   else
   {
        log_registry("It seems there is no preexisting Ura type MO of $mo_master_cms, please run the nead.pl with 1.4.1 TC..");
        test_failed($test_slogan);
   }
}


sub FUT0004 # 1.4.4 Create a MO using cstest and see same exist on NE side
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.4.4; Create a new MO in the mirror MIB, check MO is created in the NE MIB; ; 2";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");  my $rnc = pick_a_ne(RncFunction);
  if($rnc)
  {
        my ($base_fdn,$attr_full) = get_fdn("Ura","create");
	$base_fdn = base_fdn_modify("$rnc",$base_fdn);
        log_registry("Base Fdn of MO is: $base_fdn");
        log_registry("Creation process can be seen in LOG FILE: $cs_log_file by current date & time");
        my $result = create_mo_CS(mo => $base_fdn,attributes => $attr_full);
        if($result)
        {
                log_registry("There is some issue in creation of Ura MO on CS side, Error Code : $result");
                test_failed($test_slogan);
        }
        else
        {
                log_registry("Wait for some time to get system stabilized....");
		sleep 180;
                my $mo_exist = does_mo_exist_NE($base_fdn);
                if ($mo_exist == 3) # 3 is the code return by does_mo_exist_NE sub routine if MO exist
                {
			log_registry("========= Attributes of MO in CS  =========");
                	get_mo_attr($base_fdn,$attr_full);
                	log_registry("===========================================");
                	my $status = attr_value_comp_NE_CS($base_fdn,$attr_full);
			if($status)
			{
                       		log_registry("Mo $base_fdn Exist and Attributes in CS and NE are same Result code:$mo_exist ");
                        	test_passed($test_slogan);
			}
			else
			{
				log_registry("Mo $base_fdn Exist but Attributes in CS and NE are not same Result code:$mo_exist ");
				test_failed($test_slogan);
			}
                }
                else
                {
                        log_registry("Master Mo $base_fdn does not Exist Result code:$mo_exist");
                        test_failed($test_slogan);
                }
        }
  }
  else
  {
        log_registry("It seems there is no synched RNC found, so leaving Test Case processing....");
        test_failed($test_slogan);
        return;
  }   
}

sub FUT0005  # 1.4.6 Set attributes of a MO using cstest and see same in NE side
{
   my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
   my $tc_info = "WRANCM_CMSNead_1A_R_1.4.6; Set attributes in the mirror  , check attributes are updated in the NE MO; ; 2";
   $test_slogan = "$test_slogan"."-"."$tc_info";
   log_registry("$tc_info");
   my ($count,@mo_FDN) = get_CMS_mo(Ura,$mo_master_cms);
   my $count_attr = "";
   if($count)
   {
        my ($base_fdn,$attr) = get_fdn("Ura","set");
        $base_fdn = $mo_FDN[0];
        log_registry("Selected MO is: $base_fdn");
        log_registry("========= Attributes of MO Before =========");
        $count_attr = get_mo_attr($base_fdn,$attr);
        log_registry("===========================================");
        log_registry("Set attributes process can be seen in LOG FILE: $cs_log_file by current date & time");
        my $result = set_mo_attributes_CS(mo => $base_fdn,attributes => $attr);
        if($result)
        {
                log_registry("There is some issue in setting attributes of Ura MO on CS side, Error Code : $result");
                test_failed($test_slogan);
        }
        else
        {
                log_registry("Wait for 3 mins to get system stabilized....");
                sleep 180;
                log_registry("========= Attributes of MO After  =========");
                $count_attr = get_mo_attr($base_fdn,$attr);
                log_registry("===========================================");
                my $mo_exist = does_mo_exist_NE($base_fdn);
                my $status_CS = attr_value_comp($base_fdn,$attr);
		my $status_NE = attr_value_comp_NE_CS($base_fdn,$attr);
                if ($mo_exist == 3 and $status_CS)
                {
			if($status_NE)
			{
                        	log_registry("Mo $base_fdn Exist in CS and attributes has been modified sucessfully in CS and NE both Result code:$mo_exist");
                        	test_passed($test_slogan);
			}
			else
			{
				log_registry("Mo $base_fdn Exist in CS but attributes are not same in CS and NE");
				test_failed($test_slogan);
			}
                }
                else
                {
                        log_registry("Master Mo $base_fdn does not Exist Result code:$mo_exist OR Attributes has not set properly");
                        test_failed($test_slogan);
                }
        }
   }
   else
   {
        log_registry("It seems there is no preexisting Ura type MO of $mo_master_cms, please run the nead.pl with 1.4.1 TC..");
        test_failed($test_slogan);
   }
}

sub FUT0006 # 1.4.7 Delete an MO on the CS side and see the same in NE
{
   my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
   my $tc_info = "WRANCM_CMSNead_1A_R_1.4.7; Delete a MO in the mirror MIB, check MO is deleted in the NE MO; ; 2";
   $test_slogan = "$test_slogan"."-"."$tc_info";
   log_registry("$tc_info");
   my ($count,@mo_FDN) = get_CMS_mo(Ura,$mo_master_cms);
   if($count)
   {
        $base_fdn = $mo_FDN[0];
        log_registry("Selected MO is : $base_fdn");
        log_registry("Delete process can be seen in LOG FILE: $cs_log_file by current date & time");
        my $result = delete_mo_CS(mo => $base_fdn);
        if($result)
        {
                log_registry("There is some issue in deleting of Ura MO on NE side, Error Code : $result");
                test_failed($test_slogan);
        }
        else
        {
                log_registry("Wait for 3 mins to get system stabilized....");
                sleep 180;
                my $mo_exist = does_mo_exist_NE($base_fdn);
                if ($mo_exist != 4) # 4 is the code return by does_mo_exist_NE if MO does not exist
                {
                        log_registry("Master Mo $base_fdn Exist in NE Result code:$mo_exist");
                        test_failed($test_slogan);
                }
                else
                {
                        log_registry("Mo $base_fdn does not Exist in NE Result code:$mo_exist");
                        test_passed($test_slogan);
                }
        }
   }
   else
   {
        log_registry("It seems there is no preexisting Ura type MO of $mo_master_cms, please run the nead.pl with 1.4.1 TC..");
        test_failed($test_slogan);
   }
}

sub FUT0007 # 1.4.8 Create UtranCell
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.4.8; Create UtranCell ; 2";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info"); 
  my $rnc = pick_a_ne(RncFunction);
  if($rnc)
  {
	log_registry("RNC => $rnc ");
	################################# Location Area Creation ############################ 
	my @list_LAs = PICK_NEW_LAS(1);
	my $lac_val = $list_LAs[0];
	my $newLA = "$rnc,LocationArea=$lac_val";
    	log_registry("Creating LocationArea => $newLA LocationAreaId $lac_val lac $lac_val");
	log_registry("Create process can be seen in LOG FILE: $cs_log_file by current date & time");
    	my $create_result = create_mo_NE(mo => $newLA);
    	if($create_result)
    	{
        	log_registry("Problem in creation of LA Error Code:=> $create_result");
        	test_failed($test_slogan);
		return;
    	}
	sleep 60;
        log_registry("SET Attributes of LA process can be seen in LOG FILE: $cs_log_file by current date & time");
	my $set_result = set_mo_attributes_NE(mo => $newLA,attributes => "LocationAreaId $lac_val lac $lac_val");
    	if($set_result)
    	{
                log_registry("There is some issue in setting attributes of Location Area on NE side, Error Code : $result");
                test_failed($test_slogan);
		return;
    	}
	################################# Service Area Creation ############################ 
	my $topSA = highest_SA($rnc,$lac_val);
	log_registry("TOP SA => $topSA");
	my $sac_val = ($topSA + 1);
    	my $newSA = "$rnc,LocationArea=$lac_val,ServiceArea=$sac_val";
    	log_registry("Creating ServiceArea => $newSA ServiceAreaId $sac_val sac $sac_val");
 	log_registry("Create process can be seen in LOG FILE: $cs_log_file by current date & time");
    	$create_result = create_mo_NE( mo => $newSA);
    	if($create_result)
    	{
        	log_registry("Problem in creation of SA => $create_result");
        	test_failed($test_slogan);
		return;
    	}
	sleep 60;
	log_registry("SET Attributes of SA process can be seen in LOG FILE: $cs_log_file by current date & time");
	$set_result = set_mo_attributes_NE(mo => $newSA, attributes => "ServiceAreaId $sac_val sac $sac_val");
    	if($set_result)
    	{
        	log_registry("There is some issue in setting attributes of Service Area on NE side, Error Code : $result");
        	test_failed($test_slogan);
		return;
    	}
	################################# Routing Area Creation ############################
	my $topRA = highest_RA($rnc,$lac_val);
    	log_registry("Top RA => $topRA");
	$rac_val = ($topRA + 1);
    	my $newRA = "$rnc,LocationArea=$lac_val,RoutingArea=$rac_val";
    	log_registry("Creating RoutingArea => $newRA RoutingAreaId $rac_val rac $rac_val");
	log_registry("Create process can be seen in LOG FILE: $cs_log_file by current date & time");
    	$create_result = create_mo_NE(mo => $newRA);
    	if($create_result)
    	{
        	log_registry("Problem in creation of RA => $create_result");
		test_failed($test_slogan);
        	return;
    	}
	sleep 60;
	log_registry("SET Attributes of RA process can be seen in LOG FILE: $cs_log_file by current date & time");
	$set_result = set_mo_attributes_NE( mo => $newRA, attributes =>  "RoutingAreaId $rac_val rac $rac_val ");
    	if($set_result)
    	{
        	log_registry("There is some issue in setting attributes of Routing Area on NE side, Error Code : $result");
        	test_failed($test_slogan);
		return;
    	}
	################################# Utran Cell Creation ############################
	my $LA_exist = does_mo_exist_CS(mo => $newLA);
	my $SA_exist = does_mo_exist_CS(mo => $newSA);
	my $RA_exist = does_mo_exist_CS(mo => $newRA);
	if($LA_exist != $result_code_CS{MO_ALREADY_EXISTS} and $SA_exist != $result_code_CS{MO_ALREADY_EXISTS} and $RA_exist != $result_code_CS{MO_ALREADY_EXISTS}) 
	{
		log_registry("Location Area,Service Area or Routing Area does not exist in CS");
		test_failed($test_slogan);
		return;
	}
	else
	{
		log_registry(" Location Area => $newLA : EXIST \n Service Area => $newSA : EXIST \n Routing Area => $newRA : EXIST ");
	}
	my ($base_fdn,$attr_full) = get_fdn("UtranCell","create");
	my $localCellId = int(rand(65534)); # To select randomly a localCellId cID and localCellId would be same
    log_registry("localCellId and cId => $localCellId");
	my $utranCellIubLink = pick_a_mo($rnc,IubLink);
	if($utranCellIubLink)
	{
		log_registry("utranCellIubLink selected for UtranCell is: $utranCellIubLink");
	}
	else
	{
        	log_registry("No utranCellIubLink has been picked from RNC $rnc for UtranCell");
        	test_failed($test_slogan);
		return;		
	}
    	$attr_full = "$attr_full"." "."lac"." "."$lac_val"." "."sac"." "."$sac_val"." "."rac"." "."$rac_val"." "."localCellId"." "."$localCellId"." "."cId"." "."$localCellId"." "."utranCellIubLink"." "."$utranCellIubLink";
    	$attr_full =~ s/\n+//g ;
	$base_fdn = base_fdn_modify("$rnc",$base_fdn);
    	log_registry("Creating Cell => $base_fdn $attr_full");
	log_registry("Create process can be seen in LOG FILE: $cs_log_file by current date & time");
	my $time = sleep_start_time();
    	$create_result = create_mo_CS(mo =>"$base_fdn",attributes =>"$attr_full");
    	if($create_result)
    	{
        	log_registry("Problem in creation of cell => ERROR code: $create_result");
        	test_failed($test_slogan);
        	return;
    	}
	long_sleep_found($time);
	my $mo_exist = does_mo_exist_NE($base_fdn);
	my ($result_code,$mo_id) = get_moid($base_fdn);
 	log_registry(" MO id of Cell is: $mo_id \n Result code: $result_code");
 	if($mo_exist == $result_code_NE{MO_ALREADY_EXISTS})
	{
		my %la_nezzy = get_mo_attributes_NE( mo => $newLA, attributes => "reservedBy");
		my %sa_nezzy = get_mo_attributes_NE( mo => $newSA, attributes => "reservedBy");
		my %ra_nezzy = get_mo_attributes_NE( mo => $newRA, attributes => "reservedBy");
		if($la_nezzy{reservedBy} == $mo_id and $sa_nezzy{reservedBy} == $mo_id and $ra_nezzy{reservedBy} == $mo_id)
 		{
			log_registry("reserveBy relationship of Location Area with Cell: $la_nezzy{reservedBy}");
			log_registry("reserveBy relationship of Service Area with Cell: $sa_nezzy{reservedBy}");
			log_registry("reserveBy relationship of Routing Area with Cell: $ra_nezzy{reservedBy}");
			get_mo_attr($base_fdn,"locationAreaRef $lac_val routingAreaRef $rac_val serviceAreaRef $sac_val");
			log_registry("UtranCell Exists in NE/opt/ericsson/atoss/tas/WR_CMS/results/nead_CMS_201203220944.log.... : Result code => $mo_exist");
			test_passed("$test_slogan");
		}
		else
		{
			log_registry("reserveBy relationship of Location Area with Cell: $la_nezzy{reservedBy}");
                        log_registry("reserveBy relationship of Service Area with Cell: $sa_nezzy{reservedBy}");
                        log_registry("reserveBy relationship of Routing Area with Cell: $ra_nezzy{reservedBy}");
                        get_mo_attr($base_fdn,"locationAreaRef $lac_val routingAreaRef $rac_val serviceAreaRef $sac_val");
			log_registry("UtranCell Exists in NE but reservedBy association of LA RA and SA is not with CELL: Result code => $mo_exist");
			test_failed($test_slogan);
		}
	}
	else
	{
		log_registry("UtranCell does not Exists in NE....");
		test_failed($test_slogan);
	}
  }
  else
  {
	log_registry("It seems no SYNCHED RNC found");
	test_failed($test_slogan);
  }
}

# Please make sure to run 1.4.9 TC you have run once 1.4.8 TC
# So if 1.4.9 TC get PASSED or FAILED check status of 1.4.8 TC as well
sub FUT0008 # 1.4.9 Delete UtranCell in NE and check LA/SA/RA Exist
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.4.9; Delete  , check that all proxy MO's are not deleted; ; 2";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
  my ($count,@mo_FDN) = get_CMS_mo(UtranCell,$mo_master_cms);
  if($count)
  {
	my $cell_fdn = $mo_FDN[0];
	log_registry("Selected CELL => $cell_fdn ");
       	######################## Getting Location Area/Service Area/Routing Area of selected cell############################
	my %cell_nezzy = get_mo_attributes_CS( mo => $cell_fdn, attributes => "locationAreaRef serviceAreaRef routingAreaRef");
	log_registry(" Location Area Linked with Cell is: $cell_nezzy{locationAreaRef} \n Service Area linked with Cell is: $cell_nezzy{serviceAreaRef} \n Routing Area linked with cell is: $cell_nezzy{routingAreaRef} ");
	my $la_fdn   = mo_name_is_OK($cell_nezzy{locationAreaRef}, qr/SubNetwork=\S+/);
	my $sa_fdn   = mo_name_is_OK($cell_nezzy{serviceAreaRef}, qr/SubNetwork=\S+/);
	my $ra_fdn   = mo_name_is_OK($cell_nezzy{routingAreaRef}, qr/SubNetwork=\S+/);
        if(!($la_fdn and $sa_fdn and $ra_fdn)) 
	{
		log_registry("Selected LA/SA/RA name is not OK");
		test_failed($test_slogan);
		return;
	}
	my ($cell_code,$cell_id) = get_moid($cell_fdn);
        my ($la_code,$la_id) = get_moid($cell_nezzy{locationAreaRef});
	my ($sa_code,$sa_id) = get_moid($cell_nezzy{serviceAreaRef});
	my ($ra_code,$ra_id) = get_moid($cell_nezzy{routingAreaRef});
	log_registry(" Cell Ref id: $cell_id \n Location Area Ref id: $la_id \n Service Area Ref id: $sa_id \n Routing Area Ref id: $ra_id ");
	###################################### Delete Cell###############################################
	log_registry("Delete Cell process can be seen in LOG FILE: $cs_log_file by current date & time");
	my $result = delete_mo_NE(mo => $cell_fdn);
	if($result)
	{
		log_registry("There is some issue in deletion of Cell....");
		test_failed($test_slogan);
		return;
	}
	log_registry("Wait for 3 mins to get system stabilized....");
	sleep 180;
	my $cell_exist_CS = does_mo_exist_CS(mo => $cell_fdn);
	my $cell_exist_NE = does_mo_exist_NE($cell_fdn);
	if(($cell_exist_CS != $result_code_CS{MO_DOESNT_EXIST}) and ($cell_exist_NE != $result_code_NE{MO_DOESNT_EXIST}))
	{
		log_registry("Cell $cell_fdn exist in CS/NE side, there is some issue...");
		test_failed($test_slogan);
		return;
	}
        my $LA_exist = does_mo_exist_CS(mo => $cell_nezzy{locationAreaRef});
        my $SA_exist = does_mo_exist_CS(mo => $cell_nezzy{serviceAreaRef});
        my $RA_exist = does_mo_exist_CS(mo => $cell_nezzy{routingAreaRef});
        if($LA_exist == $result_code_CS{MO_ALREADY_EXISTS} and $SA_exist == $result_code_CS{MO_ALREADY_EXISTS} and $RA_exist == $result_code_CS{MO_ALREADY_EXISTS} and $cell_exist_CS != $result_code_CS{MO_ALREADY_EXISTS} )
        {
                log_registry("Location Area,Service Area or Routing Area exist in CS while Cell does not exist in CS/NE");
        }
        else
        {
                log_registry(" Location Area,Service Area or Routing Area does not exist in CS");
		test_failed($test_slogan);
		return;
        }
        my %la_nezzy = get_mo_attributes_NE( mo => $cell_nezzy{locationAreaRef}, attributes => "reservedBy lac");
        my %sa_nezzy = get_mo_attributes_NE( mo => $cell_nezzy{serviceAreaRef}, attributes => "reservedBy");
        my %ra_nezzy = get_mo_attributes_NE( mo => $cell_nezzy{routingAreaRef}, attributes => "reservedBy");
        if($la_nezzy{reservedBy} ne $cell_id and $sa_nezzy{reservedBy} ne $cell_id and $ra_nezzy{reservedBy} ne $cell_id)
        {
	     get_mo_attr($cell_nezzy{locationAreaRef});
	     get_mo_attr($cell_nezzy{serviceAreaRef});
             get_mo_attr($cell_nezzy{routingAreaRef});
             log_registry("UtranCell does not Exists while LA/SA/RA exist and have no association with Cell in Netsim as well....");
             test_passed("$test_slogan");
        }
        else
        {
	    get_mo_attr($cell_nezzy{locationAreaRef});
            get_mo_attr($cell_nezzy{serviceAreaRef});
            get_mo_attr($cell_nezzy{routingAreaRef});
            log_registry("UtranCell doesnot Exists in but reservedBy association of LA RA and SA is with CELL...");
            test_failed($test_slogan);
        }
 ###############################To Avoid Junk deleting Location Area Master Mo ###################
	my ($count_LA,@mo_la) = get_CMS_mo(LocationArea,$la_nezzy{lac});
 	if($count_LA)
	{
		log_registry("Number of LAs found with lac:$la_nezzy{lac} => $count_LA");
		foreach(@mo_la)
		{
			log_registry("Deleting Location Area: $_");	
			delete_mo_CS(mo => $_ );
		}
	}
    }
    else
    {
        log_registry("It seems no UtranCell found created by $mo_master_cms, please run the TC nead.pl -t 1.4.8");
        test_failed($test_slogan);
    }
}

sub FUT0009  # 1.7.1 Update the reservedBy attribute for in the mirror MIB 
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.7.1; Update the reservedBy attribute for   in the mirror MIB; ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne(RncFunction);
  if($rnc)
  {
	my ($count_net_before,@mo_fdn_before) = get_CMS_mo(ExternalGsmNetwork);
	my $cell = pick_a_mo($rnc,UtranCell);
        if($cell)
        {
                log_registry("Selected UtranCell is: $cell");
        }
        else
        {
                log_registry("No UtranCell has been picked from RNC $rnc");
                test_failed($test_slogan);
                return;
        }
  	my ($Plmn_fdn, $Plmn_attr) = get_fdn("ExternalGsmPlmn","create");#
  	mo_create_decision("0",$Plmn_fdn, $Plmn_attr);
  	my ($GsmCell_fdn, $GsmCell_attr) = get_fdn("ExternalGsmCell","create");
  	$GsmCell_attr = "$GsmCell_attr"." "."$Plmn_fdn";
  	$GsmCell_attr =~ s/\n+//g ;
  	mo_create_decision("0",$GsmCell_fdn, $GsmCell_attr);
        ############################ Creating Relation #####################################
	my $GSMRel = "$cell,GsmRelation=CMSAUTOMASTER_1-7-1";
	log_registry("Creating GsmRelation : $GSMRel selectionPriority 50 adjacentCell $GsmCell_fdn");
	log_registry("Creation Process can be seen in in LOG FILE: $cs_log_file by current date & time");
        $create_result = create_mo_CS( mo => $GSMRel, attributes =>  "selectionPriority 50 adjacentCell $GsmCell_fdn");
        if ($create_result)
        {
            log_registry("Error code is $create_result");
      	    test_failed($test_slogan);
            return;
	}
        log_registry("Wait for some time to get system Stabilized...");
	sleep 180;
	%rezzy = get_mo_attributes_CS( mo => $GSMRel, attributes => "externalGsmCellRef");
	my $externalGsmCellRef = $rezzy{externalGsmCellRef};
	log_registry("Check reservedBy in $externalGsmCellRef ");
 	my $mark = "";
	$mark = "FAILED" if not is_resby($externalGsmCellRef, $GSMRel);
 	if($mark)
        {
		log_registry("It seems that reservedBy of GSM Cell has not been updated");
		test_failed($test_slogan);
		return;
   	}
	my ($count_net_after,@mo_fdn_after) = get_CMS_mo(ExternalGsmNetwork);
	my %mo_fdn_before = map {$_, 1} @mo_fdn_before;
	my @difference = grep {!$mo_fdn_before {$_}} @mo_fdn_after;
	log_registry("==============================================");
	log_registry(" ExternalGsmNetwork MO Count Before : $count_net_before \n ExternalGsmNetwork MO Count After : $count_net_after");
	log_registry("==============================================");
	my $diff_net = scalar @difference;
	my $get_cell = get_master($GsmCell_fdn);
	my $get_plmn = get_master($Plmn_fdn);
	my $get_prox_cell = get_proxy($externalGsmCellRef);
	my $get_net = get_proxy($difference[0]) if ($diff_net == 1);
	if(($count_net_after == ($count_net_before + 1)) and $diff_net == 1 and $get_cell == 1 and $get_plmn == 1 and $get_prox_cell == 1 and $get_net == 1)
	{
		log_registry("ExternalGsmNetwork created automatically is: @difference");
		test_passed($test_slogan);
	}
	else
	{
		if($diff_net > 1) { log_registry("It seems difference of ExternalGsmNetwork Mo between before and after is more than one , \n List of ExternalGsmNetwork is: @difference");}
		log_registry("It seems ExternalGsmNetwork Mo has not been created for the relation..") if not $diff_net;
		test_failed($test_slogan);
	}
	################################### To avoid Junk of Database deleting Mos created above#######################
        log_registry("Deleting GsmRelation.......");
	my $del_rel = delete_mo_CS(mo => $GSMRel);
	sleep 90;
	log_registry("Deleting ExternalGsmCell.....");
	my $del_cell = delete_mo_CS(mo => $GsmCell_fdn);
	sleep 90;
	log_registry("Deleting ExternalGsmPlmn...");
	my $del_plmn = delete_mo_CS(mo => $Plmn_fdn);
	sleep 90;
	if($del_rel or $del_cell or $del_plmn)
	{
		log_registry("Problem in deletion of GsmRelation/ExternalGsmCell/ExiernalGsmPlmn.... Please check once manually......");
	}	

  }
  else
  {
	log_registry("It seems no SYNCHED RNC found...");
	test_failed($test_slogan);
  }
}

sub FUT0010  # 1.7.2 Update the reservedBy attribute for   in the mirror MIB for N / N-1 Main Delivery Node 
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.7.2: Update the reservedBy attribute for   in the mirror MIB for N / N-1 Main Delivery Node; ; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne(RncFunction);
  if($rnc)
  {
        my ($count_net_before,@mo_fdn_before) = get_CMS_mo(UtranNetwork);
        my $cell = pick_a_mo($rnc,UtranCell);
        if($cell)
        {
                log_registry("Selected UtranCell is: $cell");
        }
        else
        {
                log_registry("No UtranCell has been picked from RNC $rnc");
                test_failed($test_slogan);
                return;
        }
        my ($Plmn_fdn, $Plmn_attr) = get_fdn("ExternalUtranPlmn","create");
        mo_create_decision("0",$Plmn_fdn, $Plmn_attr);
        my ($UtranCell_fdn, $UtranCell_attr) = get_fdn("ExternalUtranCell","create");
        $UtranCell_attr = "$UtranCell_attr"." "."$Plmn_fdn";
        $UtranCell_attr =~ s/\n+//g ;
        mo_create_decision("0",$UtranCell_fdn, $UtranCell_attr);
        ############################ Creating Relation #####################################
        my $UtranRel = "$cell,UtranRelation=CMSAUTOMASTER_1-7-2";
        log_registry("Creating UtranRelation : $UtranRel selectionPriority 50 UtranRelationId 50 adjacentCell $UtranCell_fdn");
        log_registry("Creation Process can be seen in in LOG FILE: $cs_log_file by current date & time");
        $create_result = create_mo_CS( mo => $UtranRel, attributes =>  "selectionPriority 50 UtranRelationId 50 adjacentCell $UtranCell_fdn");
        if ($create_result)
        {
            log_registry("Error code is $create_result");
            test_failed($test_slogan);
            return;
        }
        log_registry("Wait for some time to get system Stabilized...");
        sleep 180;
        %rezzy = get_mo_attributes_CS( mo => $UtranRel, attributes => "utranCellRef");
        my $utranCellRef = $rezzy{utranCellRef};
        log_registry("Check reservedBy in $utranCellRef ");
        my $mark = "";
        $mark = "FAILED" if not is_resby($utranCellRef, $UtranRel);
        if($mark)
        {
                log_registry("It seems that reservedBy of Utran Cell has not been updated");
                test_failed($test_slogan);
                return;
        }
        my ($count_net_after,@mo_fdn_after) = get_CMS_mo(UtranNetwork);
        my %mo_fdn_before = map {$_, 1} @mo_fdn_before;
        my @difference = grep {!$mo_fdn_before {$_}} @mo_fdn_after;
        log_registry("==============================================");
        log_registry(" UtranNetwork MO Count Before : $count_net_before \n UtranNetwork MO Count After : $count_net_after");
        log_registry("==============================================");
        my $diff_net = scalar @difference;
        my $get_cell = get_master($UtranCell_fdn);
        my $get_plmn = get_master($Plmn_fdn);
        my $get_prox_cell = get_proxy($utranCellRef);
        my $get_net = get_proxy($difference[0]) if ($diff_net == 1);
        if(($count_net_after == ($count_net_before + 1)) and $diff_net == 1 and $get_cell == 1 and $get_plmn == 1 and $get_prox_cell == 1 and $get_net == 1)
        {
                log_registry("UtranNetwork created automatically is: @difference");
                test_passed($test_slogan);
        }
        else
        {
                if($diff_net > 1) { log_registry("It seems difference of UtranNetwork Mo between before and after is more than one , \n List of UtranNetwork is: @difference");}
                log_registry("It seems UtranNetwork Mo has not been created for the relation..") if not $diff_net;
                test_failed($test_slogan);
        }
        ################################### To avoid Junk of Database deleting Mos created above#######################
        log_registry("Deleting UtranRelation.......");
        my $del_rel = delete_mo_CS(mo => $UtranRel);
        sleep 90;
        log_registry("Deleting ExternalUtranCell.....");
        my $del_cell = delete_mo_CS(mo => $UtranCell_fdn);
        sleep 90;
        log_registry("Deleting ExternalUtranPlmn...");
        my $del_plmn = delete_mo_CS(mo => $Plmn_fdn);
        sleep 90;
        if($del_rel or $del_cell or $del_plmn)
        {
                log_registry("Problem in deletion of UtranRelation/ExternalUtranCell/ExiernalUtranPlmn.... Please check once manually......");
        }

  }
  else
  {
        log_registry("It seems no SYNCHED RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT0011  # 1.7.6 Try and delete an MO that is referenced by another MO with a reservedBy attribute
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.7.6: Try and delete an MO that is referenced by another MO with a reservedBy attribute; ; 2";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne(RncFunction);
  if($rnc)
  {
        my $cell = pick_a_mo($rnc,UtranCell);
        if($cell)
        {
                log_registry("Selected UtranCell is: $cell");
        }
        else
        {
                log_registry("No UtranCell has been picked from RNC $rnc");
                test_failed($test_slogan);
                return;
        }
	get_mo_attr($cell,reservedBy);
	my %rezzy = get_mo_attributes_CS( mo => $cell, attributes => "reservedBy");
	my $resby = $rezzy{reservedBy};
	if(!$resby)
	{
		log_registry("Selected UtranCell does not have a reservedBy relationship with other MO...");
		log_registry("Please try again, this Test Case is intended to delete a UtranCell which has atleast one MO as reservedBY..");
	        test_failed($test_slogan);
                return;
	}
	my $result = delete_mo_CS(mo => $cell);
	sleep 60;
	my $review_cache_log = cache_file();
        my $rev_log = rev_find(file => $review_cache_log,mo => $cell);
	if($result and $rev_log)
	{
		log_registry("UtranCell has not deleted because of reservedBy relationship with other Mos....");
		log_registry("UtranCell exist in Review Cache..........");
		test_passed($test_slogan);
	}
	else
	{
		log_registry("It seems UtranCell has been deleted eventhough it is reservedBy other MOs.....");
		log_registry("UtranCell does not exist in review cache....");
		test_failed($test_slogan);
	}
  }
  else
  {
        log_registry("It seems no SYNCHED RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT0012  # 1.7.8 Create an MO reference to an MO that doesn't exist
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.7.8:Create an MO reference to an MO that doesn't exist; ; 2";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne(RncFunction);
  if($rnc)
  {
        my ($count_net_before,@mo_fdn_before) = get_CMS_mo(ExternalGsmNetwork);
	my ($count_unet_before,@mo_ufdn_before) = get_CMS_mo(UtranNetwork);
        my $cell = pick_a_mo($rnc,UtranCell);
        if($cell)
        {
                log_registry("Selected UtranCell is: $cell");
        }
        else
        {
                log_registry("No UtranCell has been picked from RNC $rnc");
                test_failed($test_slogan);
                return;
        }
        my ($GsmCell_fdn, $GsmCell_attr) = get_fdn("ExternalGsmCell","create");
        my $cell_exist = does_mo_exist_CS(mo => $GsmCell_fdn);
	if($cell_exist != $result_code_CS{MO_DOESNT_EXIST})
	{
		log_registry("It seems MO defined in cfg file is already exist, please write configuration for a ExternalGsmCell that does not exist...");
		test_failed($test_slogan);
		return;
	}
	else
	{
		log_registry("ExternalGsmCell $GsmCell_fdn does not exist...");
	}
        ############################ Creating GsmRelation #####################################
        my $GSMRel = "$cell,GsmRelation=CMSAUTOMASTER_1-7-8";
        log_registry("Creating GsmRelation : $GSMRel selectionPriority 50 adjacentCell $GsmCell_fdn");
        log_registry("Creation Process can be seen in in LOG FILE: $cs_log_file by current date & time");
        my $create_result = create_mo_CS( mo => $GSMRel, attributes =>  "selectionPriority 50 adjacentCell $GsmCell_fdn");
	my ($count_net_after,@mo_fdn_after) = get_CMS_mo(ExternalGsmNetwork);
        my %mo_fdn_before = map {$_, 1} @mo_fdn_before;
        my @difference = grep {!$mo_fdn_before {$_}} @mo_fdn_after;
        log_registry("==============================================");
        log_registry(" ExternalGsmNetwork MO Count Before : $count_net_before \n ExternalGsmNetwork MO Count After : $count_net_after");
        log_registry("==============================================");
        my $diff_net = scalar @difference;
        if ($create_result and (!$diff_net))
        {
       	     log_registry("Error code is $create_result");
	     log_registry("GsmRelation can not be create for the cell which does not exist...");
        }
	else
	{
	     log_registry("New ExternalGsmNetwork Mo: @difference");
	     log_registry("There is some issue GsmRelation has been created for the cell $GsmCell_fdn which does not exist...");
	     test_failed($test_slogan);
	     return;
	}
############################## For UtranRelation ##########################################################
	my ($UtranCell_fdn, $UtranCell_attr) = get_fdn("ExternalUtranCell","create");
        $cell_exist = does_mo_exist_CS(mo => $UtranCell_fdn);
        if($cell_exist != $result_code_CS{MO_DOESNT_EXIST})
        {
                log_registry("It seems MO defined in cfg file is already exist, please write configuration for a ExternalUtranCell that does not exist...");
                test_failed($test_slogan);
                return;
        }
        else
        {
                log_registry("ExternalUtranCell $UtranCell_fdn does not exist...");
        }
######################### Creating UtranRelation ##############################################################
	my $UtranRel = "$cell,UtranRelation=CMSAUTOMASTER_1-7-8";
	log_registry("Creating UtranRelation : $UtranRel selectionPriority 50 UtranRelationId 50 adjacentCell $UtranCell_fdn");
	log_registry("Creation Process can be seen in in LOG FILE: $cs_log_file by current date & time");
	$create_result = create_mo_CS( mo => $UtranRel, attributes =>  "selectionPriority 50 UtranRelationId 50 adjacentCell $UtranCell_fdn");
	my ($count_unet_after,@mo_ufdn_after) = get_CMS_mo(UtranNetwork);
	my %mo_ufdn_before = map {$_, 1} @mo_ufdn_before;
	@difference = grep {!$mo_ufdn_before {$_}} @mo_ufdn_after;
	log_registry("==============================================");
	log_registry(" UtranNetwork MO Count Before : $count_unet_before \n UtranNetwork MO Count After : $count_unet_after");
	log_registry("==============================================");
	$diff_net = scalar @difference;
        if ($create_result and (!$diff_net))
        {
             log_registry("Error code is $create_result");
             log_registry("UtranRelation can not be create for the cell which does not exist...");
	     test_passed($test_slogan);
        }
        else
        {
             log_registry("New ExternalUtranNetwork Mo: @difference");
             log_registry("There is some issue UtranRelation has been created for the cell $UtranCell_fdn which does not exist...
");
             test_failed($test_slogan);
             return;
        }

  }
  else
  {
        log_registry("It seems no SYNCHED RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT0013 # 1.4.12 Create / Delete of Multiple UtranCells
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_; 
  my $tc_info = "WRANCM_CMSNead_1A_R_1.4.12; Create / Delete of Multiple UtranCells,; ; 2";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
  my $rnc = pick_a_ne(RncFunction);
  if($rnc)
  {
        log_registry("RNC => $rnc ");
        ################################# Location Area Creation ############################
	log_registry("Highest Value of Location Area selected: 65535");
        my $lac_val = 65535; # Highest value of LA
        my $newLA = "$rnc,LocationArea=$mo_master_cms";
 	my $lac_exist = does_mo_exist_CS(mo => $newLA);
	if($lac_exist != $result_code_CS{MO_ALREADY_EXISTS})
	{
        	log_registry("Creating LocationArea => $newLA LocationAreaId $lac_val lac $lac_val");
        	log_registry("Create process can be seen in LOG FILE: $cs_log_file by current date & time");
        	my $create_result = create_mo_CS(mo => $newLA,attributes => "LocationAreaId $lac_val lac $lac_val");
        	if($create_result)
        	{
                	log_registry("Problem in creation of LA Error Code:=> $create_result");
                	test_failed($test_slogan);
                	return;
        	}
        	sleep 60;
	}
	else
	{
		log_registry("LocationArea $newLA Already exist, so using it for TC");
	}
        ################################# Service Area Creation ############################
        my @sac_val = (65535,1);
        my @newSA = () ;
	my $count_sa = 0;
	foreach(@sac_val)
	{
		push (@newSA ,"$rnc,LocationArea=$mo_master_cms,ServiceArea=$_");
		my $sac_exist = does_mo_exist_CS(mo => $newSA[$count_sa]);
		if($sac_exist != $result_code_CS{MO_ALREADY_EXISTS})
		{
        		log_registry("Creating ServiceArea => $newSA[$count_sa] ServiceAreaId $_ sac $_");
        		log_registry("Create process can be seen in LOG FILE: $cs_log_file by current date & time");
        		$create_result = create_mo_CS( mo => $newSA[$count_sa],attributes => "ServiceAreaId $_ sac $_");
        		if($create_result)
        		{
               	 		log_registry("Problem in creation of SA => $create_result");
                		test_failed($test_slogan);
                		return;
        		}
        		sleep 60;
		}
		else
		{
			log_registry("Service Area $newSA[$count_sa] Already Exist");
		}
		$count_sa++;
	}
        ################################# Routing Area Creation ############################
        my @rac_val = (255,1);
        my @newRA = () ;
	my $count_ra = 0;
        foreach(@rac_val)
        {
                push (@newRA ,"$rnc,LocationArea=$mo_master_cms,RoutingArea=$_");
                my $rac_exist = does_mo_exist_CS(mo => $newRA[$count_ra]);
                if($rac_exist != $result_code_CS{MO_ALREADY_EXISTS})
                {
        		log_registry("Creating RoutingArea => $newRA[$count_ra] RoutingAreaId $_ rac $_");
        		log_registry("Create process can be seen in LOG FILE: $cs_log_file by current date & time");
        		$create_result = create_mo_CS(mo => $newRA[$count_ra],attributes =>  "RoutingAreaId $_ rac $_ ");
                        if($create_result)
                        {
                                log_registry("Problem in creation of RA => $create_result");
                                test_failed($test_slogan);
                                return;
                        }
                        sleep 60;
                }
                else
                {
                        log_registry("Routing Area $newRA[$count_ra] Already Exist");
                }
                $count_ra++;
        }
        ################################# Utran Cell Creation ############################
        my ($base_fdn,$attr_full) = get_fdn("UtranCell","create");
	$base_fdn = base_fdn_modify("$rnc","$base_fdn");
	my $no_cell = 6;
	log_registry("Number of UtranCell getting created: $no_cell");
	my @array_cell = ();
	my $js = $count_sa - 1;
	my $jr = $count_ra - 1;
	for(my $i = 0; $i<$no_cell; $i++)
	{
		my $mo_id = int(rand(20));
        	my $localCellId = int(rand(65534)); # To select randomly a localCellId cID and localCellId would be same
    		log_registry("localCellId and cId => $localCellId");
        	my $utranCellIubLink = pick_a_mo($rnc,IubLink);
        	if($utranCellIubLink)
        	{
                	log_registry("utranCellIubLink selected for UtranCell is: $utranCellIubLink");
        	}
        	else
        	{
                	log_registry("No utranCellIubLink has been picked from RNC $rnc for UtranCell");
                	test_failed($test_slogan);
                	return;
        	}
        	$attr_full = "$attr_full"." "."lac"." "."$lac_val"." "."sac"." "."$sac_val[$js]"." "."rac"." "."$rac_val[$jr]"." "."localCellId"." "."$localCellId"." "."cId"." "."$localCellId"." "."utranCellIubLink"." "."$utranCellIubLink";
        	$attr_full =~ s/\n+//g ;
        	$base_fdn = "$base_fdn"."$mo_id";
        	$base_fdn =~ s/\n+//g ;
        	log_registry("Creating Cell => $base_fdn $attr_full");
        	log_registry("Create process can be seen in LOG FILE: $cs_log_file by current date & time");
        	$create_result = create_mo_CS(mo =>"$base_fdn",attributes =>"$attr_full");
        	if($create_result)
        	{
                	log_registry("Problem in creation of cell => ERROR code: $create_result");
                	test_failed($test_slogan);
                	return;
        	}
		$js = ($js - 1) if ($i == ($no_cell/2));
		$jr = ($jr - 1) if ($i == ($no_cell/2));
		push(@array_cell,$base_fdn);
	}
	sleep 120;
        my $time = sleep_start_time();
        long_sleep_found($time);
	my $flag = 0;
        my $review_cache_log = cache_file();
	foreach(@array_cell)
	{
		log_registry("UtranCell => $_");
        	my $mo_exist = does_mo_exist_CS(mo=> $_);
        	my ($stat,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
		$flag = 1 if not $rev_log;
        	if($mo_exist != $result_code_CS{MO_ALREADY_EXISTS} or $flag)
        	{
                	log_registry("UtranCell $_ does not Exists in CS....");
                	test_failed($test_slogan);
			return;
        	}
	}
	log_registry("It seems all new UtranCell has created successfully....");
 	$flag = 0;
	foreach(@array_cell)
	{
		log_registry("Deleteing UtranCell : $_");
		delete_mo_CS(mo => $_);
		sleep 90;
		my $mo_exist = does_mo_exist_CS(mo=> $_);
		my $stat = get_master($_);
		$flag = 1 if ($stat != 0);
		if($mo_exist != $result_code_CS{MO_DOESNT_EXIST} or $flag)
                {
                        log_registry("ERROR => UtranCell $_ Exists in CS....");
                }
	}
	log_registry("It seems all new UtranCell has deleted successfully....") if not $flag;
	log_registry("It seems some UtranCell has not deleted...") if $flag;
	test_failed($test_slogan) if $flag;
	test_passed($test_slogan) if not $flag;
##############################To avoid Junk deleting Location Area as well#######################
	log_registry("Deleting Location Area.....");
	my ($count_LA,@mo_la) = get_CMS_mo(LocationArea,$mo_master_cms);
	if($count_LA)
	{
		foreach(@mo_la)
		{
			log_registry("Deleting Location Area:$_");
			delete_mo_CS(mo => $_);
		}
	}
  }
  else
  {
	log_registry("It seems no SYNCHED RNC found...");
	test_failed($test_slogan);
  }
}

########
sub FUT0014  # 1.15.3 Create an MO reference to an MO that doesn't exist
{
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.15.3:Create EnodeBfunction; ; 2";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne(RncFunction);
  my ($result,$sim,$node) = get_sim_info("$rnc");
  my $ERBS = pick_a_ne(ENodeBFunction);
  log_registry("$ERBS");
  if($ERBS )
  {
    my $mec = get_mec($ERBS );
    get_mo_attr($mec,"ipAddress");
    log_registry("ERBS => $ERBS ");#
  }
  if($result)
  {
   log_registry("Error code is $result, error message is $result_code_NE{$result}");
   log_registry("Something happened in get_sim_info $rnc");
   test_failed($test_slogan);
   return;
  }
  else
  {
   log_registry("Sim is $sim\nNode is $node");
  }
  do_netsim_command(".stop", $rnc, $sim, $node);
}

#######

sub log_check_event_sybase
{
  my $time = $_[0];

  log_registry("checking for EVENT in log database after -> $time");

my $isql_out=`$isql_cmd -Usa -Psybase11 -Dlvlogdb -w2240 -s#<< EOF
select * from Logs where time_stamp>'$time' and application_name like 'cms%' and command_name like '%EVENT%'
go
EOF`;

  if($isql_out =~ /0 rows affected/)
  {
     return;
  }
  else

  {
     return $isql_out;
  }

}


sub FUT0015 # 1.15.4 Add ANR event for the creating, modifying and deleting of MO
{
  my $time = sleep_start_time();
  log_registry("TC Start time $time :: $smlog_time :: $_[0]\n");
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "Test Case WRANCM_CMSNead_1A_R_1.15.4; Add ANR event for the creating of LTE EUtranCellRelation MO; Normal;1";

  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = "";
  my $ipAdd = "";

  my ($count,@nes) = get_CMS_mo("ENodeBFunction");

  # Option 1 for cloud where nodes always the same if we know newest ipv4 LTE node
  # my($count2,@RET) = select_mo_cs(MO => "ENodeBFunction", ATTR => "eNBId", VAL => "11", KEY => "11");
  # log_registry("Got this $count2 , @RET");

  log_registry("Pick every 3rd ERBS to check  ");
  my $i;
  my @every_third = grep {not ++$i % 3} @nes; # Pick every 3rd element from @nes

  if($count)
	{
  	my @NE; # 			      # Go through smaller list of ERBS's
  	for my $rrr (@every_third)
  	 {
                log_registry("whats rrr -> $rrr");
                my $mecontext = get_mec($rrr);

                log_registry("2. $mecontext ");

    		if (!(grep {$_ =~ $mecontext}@NE))
   		 {
    		 push(@NE,$mecontext);
    		 my %result = get_mo_attributes_CS( mo => $mecontext, attributes => "ipAddress neMIMversion");
    		 $ipAdd = $result{ipAddress};
    		 $neMIMversion = $result{neMIMversion};
		 # log_registry("4 $ipAdd :: $neMIMversion");
    	         if ($ipAdd =~ m/\./ && $neMIMversion =~ m/vD/)  # Don't pick a ipv6 address && $neMIMversion D.1
			{
			 my $sync = get_synch_status($mecontext);
   	   			if ($sync == 3 )
   	   				{
					$ERBS=$mecontext;
					log_registry("Got a ipv4 address $ERBS , $ipAdd and its synched $sync");
			 		last;
					} 
			}
		else { log_registry("its... address, $ipAdd "); } 
		}

    	  }
	}
  else
	{
        log_registry("Error : did get any ERBS Of version D.1 in the CS, check version being searched for in TC!!!!!");
        test_failed($test_slogan);
        return;
	}

  my ($result,$sim,$node) = get_sim_info("$ERBS");

  log_registry("Picked this : $ERBS");

  if($ERBS )
  {
    my $mec = get_mec($ERBS );
    get_mo_attr($mec,"ipAddress");
    log_registry("ERBS => $ERBS ");
    my %result = get_mo_attributes_CS(mo => $mec, attributes => "ipAddress");
    our $ERBS_ip = $result{ipAddress};
    RCP_files($ERBS_ip);
  }
  if($result)
  {
   log_registry("Error code is $result, error message is $result_code_NE{$result}");
   log_registry("Something happened in get_sim_info $rnc");
   test_failed($test_slogan);
   return;
  }
  else
  {
   log_registry("Sim is $sim\nNode is $node");
   do_netsim_command('\'kertayle:file=\"/netsim/AllMosCreate.mo\";\'',
   $ERBS, $sim, $node);
  }
  sleep (60);
 my $ANRevents = log_check_event_sybase($time);
 if($ANRevents)
 {
  if ($ANRevents =~ m/ANR EVENT/)
  {
    log_registry("Match for ADD ANR EVENT found");

    parse_event($ANRevents, "ADD", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.4; Add ANR event for the creating of LTE EUtranCellRelation MO; Normal; 1", "EUtranCellRelation");
    parse_event($ANRevents, "ADD", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.7; Add ANR event for the creating of LTE ExternalENodeBFunction MO; Normal; 1 ");
    parse_event($ANRevents, "ADD", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.10; Add ANR event for the creating of LTE ExternalEUtranCellFDD/TDD MO; Normal; 1 ","ExternalEUtranCell");
    parse_event($ANRevents, "ADD", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.13; Add ANR event for the creating of LTE TermPointToENB MO; Normal; 1 ","TermPointToENB");
    parse_event($ANRevents, "ADD", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.22; Add ANR event for the creating of LTE ExternalUtranCellFDD/TDD MO; Normal; 1 ","ExternalUtranCell");
    parse_event($ANRevents, "ADD", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.23; Add ANR event for the creating of LTE UtranCellRelation MO; Normal; 1","UtranCellRelation");
    parse_event($ANRevents, "ADD", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.33; Add ANR event for the creating of LTE ExternalGeranCell MO; Normal; 1 ","ExternalGeranCell");
    parse_event($ANRevents, "ADD", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.34; Add ANR event for the creating of LTE GeranCellRelation MO; Normal; 1 ","GeranCellRelation");
  }
 }
 else
 {
   test_failed($test_slogan);
 }

if($result)
  {
   log_registry("Error code is $result, error message is $result_code_NE{$result}");
   log_registry("Something happened in get_sim_info $rnc");
   test_failed($test_slogan);
   return;
  }
  else
  {
  log_registry("Sim is $sim\nNode is $node");
   do_netsim_command('\'kertayle:file=\"/netsim/AllMosSet.mo\";\'',
   $ERBS, $sim, $node);
  }
  sleep (60);
  log_registry("after delete mo's $time");

 $ANRevents = log_check_event_sybase($time);

  log_registry("$ANRevents ");


 if($ANRevents)
 {
  log_registry("ANR Event Exists");
  if ($ANRevents =~ m/ANR EVENT/)
  {
    log_registry("Match for ANR EVENT found");
     parse_event($ANRevents, "MODIFY", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.5; Modify ANR event for the modifying of LTE EUtranCellRelation MO; Normal; 1", "EUtranCellRelation");
     parse_event($ANRevents, "MODIFY", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.8; Modify ANR event for the modifying of LTE ExternalENodeBFunction MO; Normal; 1");
     parse_event($ANRevents, "MODIFY", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.11; Modify ANR event for the modifying of LTE ExternalEUtranCellFDD/TDD MO; Normal; 1","ExternalEUtranCell");
parse_event($ANRevents, "MODIFY", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.14; Modify ANR event for the modifying of LTE TermPointToENB MO; Normal; 1", "TermPointToENB");

  }
 }
 else
 {
 test_failed($test_slogan);
 }
if($result)
  {
   log_registry("Error code is $result, error message is $result_code_NE{$result}");
   log_registry("Something happened in get_sim_info $rnc");
   test_failed($test_slogan);
   return;
  }
  else
  {
  log_registry("Sim is $sim\nNode is $node");
   do_netsim_command('\'kertayle:file=\"/netsim/AllMosDelete.mo\";\'',
   $ERBS, $sim, $node);
  }
  sleep (60);
 $ANRevents = log_check_event_sybase($time);
 if($ANRevents)
 {
  log_registry("ANR REMOVE Event Exists");
  if ($ANRevents =~ m/ANR EVENT/)
  {
    log_registry("Match for ANR EVENT found");
     parse_event($ANRevents, "REMOVE", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.6; Remove ANR event for the removal of LTE EUtranCellRelation MO; Normal; 1", "EUtranCellRelation");
     parse_event($ANRevents, "REMOVE", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.9; Remove ANR event for the removal of LTE ExternalENodeBFunction MO; Normal; 1");
     parse_event($ANRevents, "EVENT_ANR_NEIGHBCELL_REMOVE", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.12; Remove ANR event for the removal of LTE ExternalEUtranCellFDD/TDD MO; Normal; 1","ExternalEUtranCell");
     parse_event($ANRevents, "DELETE", $ERBS, "Test Case WRANCM_CMSNead_1A_R_1.15.15; Remove ANR event for the removal of LTE TermPointToENB MO; Normal; 1", "TermPointToENB");

  }
 }
 else
 {
 log_registry("NO DELTE REMOVE ANR EVENT found....");
 test_failed($test_slogan);
 }

}


sub FUT0017 # 1.15.68 Add ANR event for RNC nodes......
{
  my $time = sleep_start_time();
  log_registry("TC Start time $time :: $smlog_time :: $_[0]\n");
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "Test Case WRANCM_CMSNead_1A_R_1.15.68; Add ANR event for the creating of WCDMA UtranCellRelation MO (Intra RNC); Normal;1";

  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $RNC = "";
  my $ipAdd = "";

  my ($count,@nes) = get_CMS_mo("RncFunction", "RNC01");
  log_registry("Count is $count, the Node is   @nes");
  $RNC = $nes[0];

  my ($result,$sim,$node) = get_sim_info("$RNC");
  log_registry("Picked this : $RNC");

  if($RNC )
  {
    my $mec = get_mec($RNC);
    get_mo_attr($mec,"ipAddress");
    log_registry("RNC => $RNC ");
    my %result = get_mo_attributes_CS(mo => $mec, attributes => "ipAddress");
    our $RNC_ip = $result{ipAddress};
    RCP_files($RNC_ip);
  }
  if($result)
  {
   log_registry("Error code is $result, error message is $result_code_NE{$result}");
   log_registry("Something happened in get_sim_info $rnc");
   test_failed($test_slogan);
   return;
  }
  else
  {
   log_registry("Sim is $sim\nNode is $node");
   do_netsim_command('\'kertayle:file=\"/netsim/CreateWcdmaUtranRel\";\'',
   $RNC, $sim, $node);
  }
sleep(60);
 my $ANRevents = log_check_event_sybase($time);
 if($ANRevents)
 {
  if ($ANRevents =~ m/ANR EVENT/)
  {
    log_registry("Match for ADD ANR EVENT found");

    parse_event($ANRevents, "ADD", $RNC, "Test Case WRANCM_CMSNead_1A_R_1.15.68; Add ANR event for the creating of WCDMA UtranCellRelation MO (Intra RNC); Normal; 1", "UtranRelation");

  }
 }
 else
 {
   test_failed($test_slogan);
 }


if($result)
  {
   log_registry("Error code is $result, error message is $result_code_NE{$result}");
   log_registry("Something happened in get_sim_info $rnc");
   test_failed($test_slogan);
   return;
  }
  else
  {
  log_registry("Sim is $sim\nNode is $node");
   do_netsim_command('\'kertayle:file=\"/netsim/DeleteWcdmaUtranRel\";\'',
   $RNC, $sim, $node);
  }
}
############################
#Function to parse Event Logs
############################

sub parse_event 
{
  my $type = $_[1];
  my $mo = $_[2];
  my @events = split('Traffic ID', $_[0]);
  my $te = $_[3];
  my $test_type = $_[4];
  my $tp = 0;
  foreach(@events)
  {
     if (/$type/)
     {
	if (/$mo/)
	{
	   if (/$test_type/)
	   {
	    log_registry("$type Event Found");
	    log_registry($_);
	    $tp = 1;
	    test_passed($te);
            return; 
	   }
	}

     }

  }
  if ($tp == 0)
  {
     test_failed($te);
  }
}

#######################
#Function to send files to netsim
#######################

sub RCP_files
{
 my $server = "hostname";    #Variable to store hostname 
 my $ip = $_[0];             #Variable used to store ERBS Node ip address
 log_registry ("Test = $ip");    #Print out the ip address in the log registry 
 my $result=`rsh -n -l netsim "$ip" "$server"`;  #Logon to the current netsim server and return                                                          its hostname 
 chop($result);     #Erase the carriage return 
 my $netsim = "netsim\@$result:/netsim";      #Store the path to the netsim box
 log_registry ("Netsim SERVER = $netsim");
`rcp $home/INPUT/AllMosCreate.mo $netsim`;          #Remote file copy command to send the file to the netsim                                                box without specifying a password
`rcp $home/INPUT/AllMosSet.mo $netsim`; 
`rcp $home/INPUT/AllMosDelete.mo $netsim`;
`rcp $home/INPUT/CreateWcdmaUtranRel $netsim`; 
`rcp $home/INPUT/DeleteWcdmaUtranRel $netsim`;  

}


##########################################
sub FUT0016 # 1.9.9
{
my $time = sleep_start_time();
  log_registry("hello $time :: $smlog_time :: $_[0]\n");
  my ($test_slogan, $testcase_logfile, $testcase_logfile_snad) = @_;
  my $tc_info = "WRANCM_CMSNead_1A_R_1.16.0;
MO; Normal; 1";

  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $RNC = get_mec(pick_an_rnc());
  print $RNC;
  $filename = get_time_string()."_RNC_export";
#  @filename = $RNC =~ /\w\w\w\d\d/;
#  print $RNC;
#  print @filename;
  my $result = `/opt/ericsson/nms_umts_wran_bcg/bin/bcgtool.sh -e $filename -d b -n $RNC`;
  print $result;
  if ($result =~ /"succeeded"/)
  {
    test_passed("Export was successfull");
  }
}

# XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# XOOOOOOOOOOOOOOOOOOOOOOOOOOOOO-----------------------------------OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOX
# XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# utility routines

sub do_test
{
   my $test = shift;
   $start_time = get_time_string();
   my $s_time = substr($start_time,11,5)."  "."on"."  ".substr($start_time,8,2).substr($start_time,4,4).substr($start_time,0,4);
   log_registry("$test Started at $s_time");
   $smlog_time = sleep_start_time();
   preconditions_OK("MAF") or die "Preconditions not valid\n";
   my $testcase_logfile = get_logfile_name("nead", $test);   #dupe this
   my $testcase_logfile_snad = get_logfile_name("snad", $test);   #duped
   start_log_nead($testcase_logfile);
   start_log_snad($testcase_logfile_snad);                             # duped
   my $test_slogan = $test;     # save the test_slogan
   $test_slogan =~ s/.*_//;     # Test case id only
   $test_slogan = "Test Case"." "."$test_slogan ";
   $test =~ s/_.*//;            # remove numerical suffix to get test subroutine name
   no strict qw(refs);          # turn off strict refs checking so that next line can call subroutine with test name
   $test->($test_slogan, $testcase_logfile, $testcase_logfile_snad);  # call the subroutine to do the actual test
}

sub reset_genc   #works on MeContext
{
my $mec = shift;
log_registry("Resetting generation counter for $mec ");
my  $result = set_mo_attributes_CS( mo => $mec, attributes => "generationCounter 0" );
log_registry("$result ");

}

sub get_MO_by_type_attr
{
   my $typeMO = $_[0];
   my $attr = $_[1];
   my $attr2 = $_[2]; 
   my $result = `$cstest -s $segment_CS lt $typeMO -an $attr $attr2`;
   log_registry("$result");
}


close STDERR;
close STDOUT;
error_writer($std_error_file);
log_registry("nead_new.pl execution ends");
close(LOGFILE);
