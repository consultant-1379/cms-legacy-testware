#!/net/atrnjump/share/guitest/perl/bin/perl
use strict;
use warnings;
use lib "/net/atrnjump/share/guitest/perl/lib";

use CS::Test;

my $mo = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=RNC01-10-2"; 

my %result = get_mo_attributes_CS( mo => $mo );

print "$mo\n";
for my $attr (sort keys %result)
{
   printf "   %-30s : %s\n", $attr, $result{$attr};
}


