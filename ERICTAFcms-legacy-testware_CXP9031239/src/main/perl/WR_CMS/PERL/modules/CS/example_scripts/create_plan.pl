#!/net/atrnjump/share/guitest/perl/bin/perl
use strict;
use warnings;
use lib "/net/atrnjump/share/guitest/perl/lib";

use CS::Test;

my $result = create_plan("my_plan");

if ($result)
{
   print "Error code is $result\n";
}
else
{
   print "OK\n";
}

