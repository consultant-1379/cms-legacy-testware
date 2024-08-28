#!/net/atrnjump/share/guitest/perl/bin/perl
use strict;
use warnings;
use lib "/net/atrnjump/share/guitest/perl/lib";

use CS::Test;

my $plan = "my_plan";

my $result = create_plan($plan);

if ($result)
{
   print "Error code is $result\n";
}
else
{
   print "Plan created OK\n";
}

my $mo = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=RNC01-10-2";

$result = set_mo_attributes_CS( mo => $mo, plan => $plan, attributes => "pwrAdm 65 qRxLevMin -100" );

if ($result)
{
   print "Error code is $result\n";
}
else
{
   print "Attributes set OK\n";
}

