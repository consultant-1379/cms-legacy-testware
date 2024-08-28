#!/net/atrnjump/share/guitest/perl/bin/perl
use strict;
use warnings;
use lib "/net/atrnjump/share/guitest/perl/lib";

use CS::Test;

my $result = create_plan("my_plan");

if ($result)
{
   print "Plan not created: Error code is $result, error message is $result_string_CS{$result}\n";   # result_string_CS is now available in the local namespace
}
else
{
   print "Plan created OK\n";
}

$result = create_plan("my_plan");
if ($result)
{
   print "Plan not created: Error code is $result, error message is ${CS::Test::result_string_CS{$result}}\n";# can also call directly
}
else
{
   print "Plan created OK\n";
}

