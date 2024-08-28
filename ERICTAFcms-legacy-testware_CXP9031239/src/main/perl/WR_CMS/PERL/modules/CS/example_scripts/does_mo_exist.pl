#!/net/atrnjump/share/guitest/perl/bin/perl
use strict;
use warnings;
use lib "/net/atrnjump/share/guitest/perl/lib";

use CS::Test;


my $mo = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=RNC01-10-2"; 

my $result = does_mo_exist_CS( mo => $mo );

if ($result == $result_code_CS{MO_DOESNT_EXIST})
{
   print "MO doesn't exist\n";
}
elsif ($result == $result_code_CS{MO_ALREADY_EXISTS})
{
   print "MO exists OK\n";
}
else
{
   print "Error code is $result, error message is $result_string_CS{$result}\n";
}


$mo = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=dummy"; 

$result = does_mo_exist_CS( mo => $mo );

if ($result == $result_code_CS{MO_DOESNT_EXIST})
{
   print "MO doesn't exist\n";
}
elsif ($result == $result_code_CS{MO_ALREADY_EXISTS})
{
   print "MO exists OK\n";
}
else
{
   print "Error code is $result, error message is $result_string_CS{$result}\n";
}


