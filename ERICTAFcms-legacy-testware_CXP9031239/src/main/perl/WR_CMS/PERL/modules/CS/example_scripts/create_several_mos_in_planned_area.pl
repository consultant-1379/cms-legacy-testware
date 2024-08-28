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

# create several MOs with the default attributes, except for some specified attribute values - cId and utranCellIubLink

my $mo_prefix = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=my_cell_";

for my $cellId (2001 .. 2005)
{
   $result = create_mo_CS( mo => "$mo_prefix$cellId", plan => $plan, attributes => "cId $cellId utranCellIubLink SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,IubLink=99" );

   if ($result)
   {
      print "Error code is $result\n";
   }
   else
   {
      print "MO created OK\n";
   }
}
