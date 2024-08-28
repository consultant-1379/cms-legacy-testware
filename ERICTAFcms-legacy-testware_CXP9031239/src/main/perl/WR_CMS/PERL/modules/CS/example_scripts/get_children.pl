#!/net/atrnjump/share/guitest/perl/bin/perl
use strict;
use warnings;
use lib "/net/atrnjump/share/guitest/perl/lib";

use CS::Test;

my $mo = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01RBS01,ManagedElement=1,NodeBFunction=1,Iub=1"; 
my $plan = "my_plan"; 

my ($result, @children) = get_mo_children_CS( mo => $mo, plan => $plan );

print "Result code is $result, message is $result_string_CS{$result}\n";

unless ($result)
{
   print "Children are:\n";
   print "  $_\n" for @children;
}


