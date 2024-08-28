#!/net/atrnjump/share/guitest/perl/bin/perl
use strict;
use warnings;
use lib "/net/atrnjump/share/guitest/perl/lib";

use CS::Test;


my $mo = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=RNC01-10-2";

my $result = set_mo_attributes_CS( mo => $mo, attributes => "pwrAdm 65 qRxLevMin -100" );

if ($result)
{
   print "Error code is $result\n";
}
else
{
   print "Attributes set OK\n";
}

