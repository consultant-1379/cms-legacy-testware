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

# create an MO with the default attributes
my $mo = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=my_cell_1";

$result = create_mo_CS( mo => $mo, plan => $plan );

if ($result)
{
   print "Error code is $result\n";
}
else
{
   print "MO created OK\n";
}

