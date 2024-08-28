#!/net/atrnjump/share/guitest/perl/bin/perl
use strict;
use warnings;
use lib "/net/atrnjump/share/guitest/perl/lib";

use CS::Test;


my $result = delete_mo_CS( mo => $mo );

print "result is ", $result ? $result : "OK", "\n";

