#!/usr/bin/perl
#use strict;
use warnings;
use Getopt::Long;
#use POSIX;
use Env;

use lib "/opt/ericsson/atoss/tas/WR_CMS/PERL/modules"; 

use NE::Test;
use CS::Test;
use CT::Common;
use CT::Basic;
use TC::MasterProxyUtils;

my $VERSION = '1.0';



#################### STDERR output Handling ##################
my $std_error_file = "/tmp/nead.tmp";
open STDERR, ">>$std_error_file";
###############################################################


#######################################################################
#
#  Master Log File Name
#
#######################################################################
 $home = "/opt/ericsson/atoss/tas/WR_CMS";
 die "Do not have write access to automation home directory $home" if ( !-w $home );
 my $script_start_time = get_time_string(); #Script Start Time



####################### STDOUT trace handling and die calls handling ###############
#open STDOUT, ">>$std_error_file";
# local $SIG{__DIE__} = sub { error_writer($std_error_file,$_[0]) }; # to handle die call
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
 $smtool       = "/opt/ericsson/nms_cif_sm/bin/smtool";

 my $nesu_conn = `$smtool -config cms_nead_seg | grep nesuPollrateConnectedNE`;
 my ($digits) = $nesu_conn =~ /(\d+)/;
 $nesu_conn = ($digits * 1.5);          # increased as agreed at meeting with EEIOSN, EPASOFA.

 my $nesu_disc = `$smtool -config cms_nead_seg | grep nesuPollrateDisconnectedNE`;
 my ($digits2) = $nesu_disc =~ /(\d+)/;
 $nesu_disc = ($digits2 * 1.5);          # increased as agreed at meeting with EEIOSN, EPASOFA.


 $log_dir      = "$HOME";        # directory for storage of error log files
 $review_cache = "/opt/ericsson/nms_umts_cms_lib_com/bin/run_moscript /opt/ericsson/nms_umts_cms_lib_com/info/XReviewCache.py";

 my $nammy = `grep SegmentCS= /etc/opt/ericsson/system.env`;
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
 $start_databases ="/opt/ericsson/nms_umts_cms_lib_com/bin/start_databases.sh ";   ### valid for R4.
 $isql_cmd     = "/opt/sybase/sybase/OCS-15_0/bin/isql"; 
#### NBNBNB /opt/Ericsson/nms_umts_wranmom/bin/ for R5 ###

 $nead_dir     = path_to_managed_component("cms_nead_seg");
 test_failed($test_slogan) if not $nead_dir;
 exit "0" if not $nead_dir;
 $snad_dir     = path_to_managed_component("cms_snad_reg");
 test_failed($test_slogan) if not $snad_dir;
 exit "0" if not $snad_dir;

 $rute = `grep IM_ROOT= /etc/opt/ericsson/system.env`;
 exit "0" if not $rute;
 chomp($rute);
 $rute =~ s/IM_ROOT=SubNetwork=//;


 $start_adjust = "/opt/ericsson/fwSysConf/bin/startAdjust.sh sync true BaseMo SubNetwork=$rute";
 $snad_log     = "$snad_dir/$rute" . "_R_NEAD.log";
 $top_one = "SubNetwork=" . "$rute" . "_R";
 $nead_log     = "$nead_dir/Seg_${nammy}_NEAD.log";


 my $maf_log      = "";
 my $PLMN = "ExternalGsmPlmn=15-15";
 $tail_command = "$nead_log";        # "tail -f $nead_log";
 $tail_command_snad = "$snad_log";    # = "tail -f $snad_log";
 $cstest = "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest";
 @error_indicators = qw(ERRO EXPT NullP LOCK);     # Look for these strings in the error log files
 $errors_to_find   = join "|", @error_indicators;  # create a string for use in grep of log files
 my $SNAD_long_sleep_indication = "about to do long sleep";

 $debug = "";
 $help = "";
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

 $rel_file    = "/opt/ericsson/atoss/tas/WR_CMS/rels.txt"; # To set attributes of Master Mo



my $usage = <<"USAGE";
Usage:   rel-tjn.pl -Lte_Gsm

   -Lte_Gsm create relations from LTE Cell to Master ExternalGsmCell
   -Lte_UtranFreq create relations from LTE Cell to Master ExternalUtranFreq
   -Lte_Utran create relations from LTE Cell to Master ExternalUtranCell
   -Lte_TDD create relations from LTE Cell to Master ExternalUtranCellTDD

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
   "Lte_Gsm"    => \$Lte_Gsm,
   "verbose"    => \$verbose,
   "version"    => \$version,
   "Lte_UtranFreq"  => \$Lte_UtranFreq,
   "Lte_Utran"  => \$Lte_Utran,
   "Lte_TDD"  => \$Lte_TDD
);
}
else
{

 print $usage;
 exit;

}


=head1 NAME

nead.pl - Perl script for testing NEAD.

=head1 SYNOPSIS

 nead.pl Lte_Gsm

   Lte_Gsm create relations from LTE Cell to Master ExternalGsmCell
   Lte_UtranFreq create relations from LTE Cell to Master ExternalUtranFreq
   Lte_Utran create relations from LTE Cell to Master ExternalUtranCell
   Lte_TDD create relations from LTE Cell to Master ExternalUtranCellTDD

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
   print "$usage";
   exit;
}
elsif ($version)
{
   print "Version is $VERSION\n";
   exit;
}
elsif ($Lte_Gsm)
{
  LTE_GSM();

}
elsif ($Lte_Utran)
{
  LTE_UTRAN();
}
elsif ($Lte_UtranFreq)
{
  LTE_UTRANFREQ();
}
elsif ($Lte_TDD)
{
  LTE_TDD();
}
else
{
   print "$usage";
   exit;
}




sub LTE_GSM 
{
  system("rm $Grel_file");
  $Grel_file    = "/opt/ericsson/atoss/tas/WR_CMS/Grels.txt"; # Generated relations file
  unlink($Grel_file);
  
  print "Create a GsmRelation between the first EUtranCell on each RBS and a input ExternalGsmCell \n";
  print "Ensure the FrequencyGroup matches with the ExternalGsmCell BcchFrequency \n";
  print "Give me the GeranFreqGroupRelation RDN (1 to 8 on standard sim) \n";
  $freGRel = <>;
  chomp($freGRel);
  print "Give me the ExternalGsmCell RDN\n";
  $ExtGCell = <>;
  chomp($ExtGCell);

  print "$ExtGCell";
  my $base = "$top_one,ExternalGsmCell=$ExtGCell";
  print "GsmCell -> $base \n";
  
  open(GRELFILE,">>$Grel_file") or die "Unable to write content in log file $Grel_file";
  
  my @FDD = get_mo_list_for_class_CS ( mo  => "EUtranCellFDD");
  for my $rrr (@FDD)
  {
     # print "$rrr\n";
     # sleep 1;
      if ($rrr =~ "-2")
      {
      print GRELFILE "cm $rrr,GeranFreqGroupRelation=$freGRel,GeranCellRelation=Oneto$ExtGCell -attr adjacentCell $base\n";
      }
  }
  my @TDD = get_mo_list_for_class_CS ( mo  => "EUtranCellTDD");
  for my $rrr (@TDD)
  {
      if ($rrr =~ "-2")
      {
      print GRELFILE "cm $rrr,GeranFreqGroupRelation=$freGRel,GeranCellRelation=Oneto$ExtGCell -attr adjacentCell $base\n";
      }
  }
}


sub LTE_UTRANFREQ 
{
  system("rm $Ufreqrel_file");
  $Ufreqrel_file = "/opt/ericsson/atoss/tas/WR_CMS/Ufreqrels.txt"; # Generated relations file
  unlink($Ufreqrel_file);

  print "Create a FreqRelation between the first EUtranCell on each RBS and a input Frequency \n";
  print "Give me the UtranFrequency= RDN (1 to 6 on standard sim) \n";
  $UfreqRel = <>;
  chomp($UfreqRel);
  my $base = "$top_one,FreqManagement=1,ExternalUtranFreq=$UfreqRel";
  print "ExternalUtranFreq -> $base \n";
  
  open(UFRELFILE,">>$Ufreqrel_file") or die "Unable to write content in log file $rel_file";
  
  my @FDD = get_mo_list_for_class_CS ( mo  => "EUtranCellFDD");
  for my $rrr (@FDD)
  {
      if ($rrr =~ "-2")
      {
      print UFRELFILE "cm $rrr,UtranFreqRelation=$UfreqRel -attr adjacentFreq $base\n";
      }
  }

}


sub LTE_UTRAN 
{
  system("rm $Urel_file");
  $Urel_file = "/opt/ericsson/atoss/tas/WR_CMS/Urels.txt"; # Generated relations file
  unlink($Urel_file);

  print "Create a Relation between the first EUtranCell on each RBS and a input ExternalUtanCell \n";
  print "Ensure the UtranFrequency matches with the ExternalUtranCell  \n";
  print "Give me the UtranFrequency= RDN (1 to 6 on standard sim) \n";
  $freURel = <>;
  chomp($freURel);
  print "Give me the ExternalUtranCell RDN\n";
  $ExtUCell = <>;
  chomp($ExtUCell);
  my $base = "$top_one,ExternalUtranCell=$ExtUCell";
  print "UtranCell -> $base \n";
  
  open(URELFILE,">>$Urel_file") or die "Unable to write content in log file $rel_file";
  
  my @FDD = get_mo_list_for_class_CS ( mo  => "EUtranCellFDD");
  for my $rrr (@FDD)
  {
      if ($rrr =~ "-2")
      {
      print URELFILE "cm $rrr,UtranFreqRelation=$freURel,UtranCellRelation=OnetoEXT -attr adjacentCell $base\n";
      }
  }

}


sub LTE_TDD 
{
  $Urel_TDD = "/opt/ericsson/atoss/tas/WR_CMS/UTDDrels.txt"; # Generated relations file
  unlink($Urel_TDD);


  print "Create a Relation between the first EUtranCellTDD on each RBS and a input ExternalUtanCellTDD \n";
  print "Ensure the UtranFrequency matches ExternalUtranCellTDD arfcnValueUtranDl \n";
  print "Give me the UtranFrequency RDN (1 to 8 on standard sim) \n";
  $freURel = <>;
  chomp($freURel);
  print "Give me the ExternalUtranCellTDD RDN\n";
  $ExtCellTDD = <>;
  chomp($ExtCellTDD);

  print "$ExtCellTDD";
  my $base = "$top_one,ExternalUtranCellTDD=$ExtCellTDD";
  print "CellTDD -> $base \n";
  
  open(URELFILE,">>$Urel_TDD") or die "Unable to write content in log file $Urel_TDD";
  my @TDD = get_mo_list_for_class_CS ( mo  => "EUtranCellTDD");
  for my $rrr (@TDD)
  {
      if ($rrr =~ "-2")
      {
      print URELFILE "cm $rrr,UtranTDDFreqRelation=$freURel,UtranCellRelation=Oneto$ExtGCell -attr adjacentCell $base\n";
      }
  }
}


close(GRELFILE);
close(URELFILE);
