#!/net/atrnjump/share/guitest/perl/bin/perl
use strict;
use warnings;
use lib "/net/atrnjump/share/guitest/perl/lib";

use CS::Test;
my @rbs_attrs = qw(uniSaalTpRef1 uniSaalTpRef2);
my @rnc_attrs = qw(activeUniSaalTpRef standbyUniSaalTpRef);

my %nbapCommon_hash  = get_class_attributes_CS( mo => "NbapCommon",  attributes => "@rnc_attrs @rbs_attrs" );
my %uniSaalTp_hash   = get_class_attributes_CS( mo => "UniSaalTp",   attributes => "aal5TpVccTpId" );
my %aal5TpVccTp_hash = get_class_attributes_CS( mo => "Aal5TpVccTp", attributes => "vclTpId" );

for my $mo (sort keys %nbapCommon_hash)
{
   my ($parent) = $mo =~ m/(SubNetwork.*),/; 
   my @uniSaalTp;
   if ($nbapCommon_hash{$mo}{activeUniSaalTpRef})
   {
      $uniSaalTp[0] = $nbapCommon_hash{$mo}{activeUniSaalTpRef};
      $uniSaalTp[1] = $nbapCommon_hash{$mo}{standbyUniSaalTpRef};
   }
   elsif ($nbapCommon_hash{$mo}{uniSaalTpRef1})
   {
      $uniSaalTp[0] = $nbapCommon_hash{$mo}{uniSaalTpRef1};
      $uniSaalTp[1] = $nbapCommon_hash{$mo}{uniSaalTpRef2};
   }
   for my $uniSaalTp (@uniSaalTp)
   {
      print "$parent\n";
      print "  $mo\n";
      print "    $uniSaalTp\n";
      my $aal5TpVccTpId = $uniSaalTp_hash{$uniSaalTp}{aal5TpVccTpId};
      print "      $aal5TpVccTpId\n";
      my $vclTpId = $aal5TpVccTp_hash{$aal5TpVccTpId}{vclTpId};
      print "        $vclTpId\n";

      print "\n";
      my ($rdn) = $parent =~ m/,([^,]+)$/;
      print "  $rdn\n";
      ($rdn) = $mo =~ m/,([^,]+)$/;
      print "  $rdn\n";
      ($rdn) = $uniSaalTp =~ m/,([^,]+)$/;
      print "  $rdn\n";
      ($rdn) = $aal5TpVccTpId =~ m/,([^,]+)$/;
      print "  $rdn\n";
      ($rdn) = $vclTpId =~ m/,([^,]+)$/;
      print "  $rdn\n";
      print "\n";
   }  
}


