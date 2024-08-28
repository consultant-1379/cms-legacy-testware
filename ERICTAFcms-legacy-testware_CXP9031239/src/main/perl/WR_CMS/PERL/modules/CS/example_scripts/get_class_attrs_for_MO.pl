#!/net/atrnjump/share/guitest/perl/bin/perl
use strict;
use warnings;
use lib "/net/atrnjump/share/guitest/perl/lib";

use CS::Test;
my @rbs_attrs = qw(uniSaalTpRef1 uniSaalTpRef2);
my @rnc_attrs = qw(activeUniSaalTpRef standbyUniSaalTpRef);

my %nbapCommon_hash  = get_class_attributes_CS( mo => "NbapCommon",  attributes => "@rnc_attrs @rbs_attrs" );

for my $mo (sort keys %nbapCommon_hash)
{
   print "$mo\n";

   for my $attr (sort keys %{$nbapCommon_hash{$mo}})
   {
      printf "   %-20s : %s\n", $attr, $nbapCommon_hash{$mo}{$attr};
   }
}
print "\n";

my %uniSaalTp_hash   = get_class_attributes_CS( mo => "UniSaalTp",   attributes => "aal5TpVccTpId" );

for my $mo (sort keys %uniSaalTp_hash)
{
   print "$mo\n";

   for my $attr (sort keys %{$uniSaalTp_hash{$mo}})
   {
      printf "   %s : %s\n", $attr, $uniSaalTp_hash{$mo}{$attr};
   }
}
print "\n";

my %aal5TpVccTp_hash = get_class_attributes_CS( mo => "Aal5TpVccTp", attributes => "vclTpId" );

for my $mo (sort keys %aal5TpVccTp_hash)
{
   print "$mo\n";

   for my $attr (sort keys %{$aal5TpVccTp_hash{$mo}})
   {
      printf "   %s : %s\n", $attr, $aal5TpVccTp_hash{$mo}{$attr};
   }
}
print "\n";

my %vclTp_hash = get_class_attributes_CS( mo => "VclTp", attributes => "reservedBy" );

for my $mo (sort keys %vclTp_hash)
{
   print "$mo\n";

   for my $attr (sort keys %{$vclTp_hash{$mo}})
   {
      printf "   %s : %s\n", $attr, $vclTp_hash{$mo}{$attr};
   }
}
print "\n";

