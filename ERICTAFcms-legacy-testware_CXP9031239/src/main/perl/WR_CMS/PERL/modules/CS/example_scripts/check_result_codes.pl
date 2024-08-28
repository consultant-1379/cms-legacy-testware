#!/net/atrnjump/share/guitest/perl/bin/perl
use strict;
use warnings;
use lib "/net/atrnjump/share/guitest/perl/lib";

use CS::Test;

print "List of all result values and strings\n";
for my $result (sort {$a <=> $b} values %result_code_CS)
{
   printf "result is %2d, string is $result_string{$result}\n", $result;
}
print "\n";

print "Test 1: Does MO exist - it should exist\n";
my $mo = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=RNC01-10-2"; 
my $result = does_mo_exist_CS( mo => $mo );
print_result($result);

print "\nTest 2: Does MO exist - it should not exist\n";
$mo = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=dummy"; 
$result = does_mo_exist_CS( mo => $mo );
print_result($result);

print "\nTest 5: Does MO exist - it should fail with MO name is invalid\n";
$mo = "+++++"; 
$result = does_mo_exist_CS( mo => $mo );
print_result($result);

print "\nTest 4: Does MO exist - should fail with plan doesn't exist\n";
$mo = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=dummy"; 
$result = does_mo_exist_CS( mo => $mo, plan => "my_plan_unknown" );
print_result($result);

print "\nTest 5: Does MO exist - it should fail with server is invalid\n";
$mo = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=dummy"; 
$result = does_mo_exist_CS( mo => $mo, server => "my_server_unknown" );
print_result($result);


sub print_result
{
   my $result = shift;
   
   if ($result eq $result_code_CS{OK})
   {
      print "Result OK\n";
   }
   elsif ($result == $result_code_CS{MO_NAME_INVALID})
   {
      print "MO name is invalid\n";
   }
   elsif ($result == $result_code_CS{ATTRIBUTES_INVALID})
   {
      print "Attributes are invalid\n";
   }
   elsif ($result == $result_code_CS{PLAN_NAME_INVALID})
   {
      print "Plan name is invalid\n";
   }
   elsif ($result == $result_code_CS{SERVER_NAME_INVALID})
   {
      print "Server name is invalid\n";
   }
   elsif ($result == $result_code_CS{MO_ALREADY_EXISTS})
   {
      print "MO exists OK\n";
   }
   elsif ($result == $result_code_CS{MO_DOESNT_EXIST})
   {
      print "MO doesn't exist\n";
   }
   elsif ($result == $result_code_CS{MIM_VERSION_INVALID})
   {
      print "MIM version is invalid\n";
   }
   elsif ($result == $result_code_CS{CS_ERROR})
   {
      print "CS error\n";
   }
   elsif ($result == $result_code_CS{PLAN_ALREADY_EXISTS})
   {
      print "Plan already exists\n";
   }
   elsif ($result == $result_code_CS{PLAN_DOESNT_EXIST})
   {
      print "Plan doesn't exist\n";
   }
   elsif ($result == $result_code_CS{MIM_FILE_NOT_FOUND})
   {
      print "MIM file not found\n";
   }
   elsif ($result == $result_code_CS{UNKNOWN_ERROR})
   {
      print "Unknown error\n";
   }
   else
   {
      print "Error code is $result, error message is $result_string{$result}\n";
   }
}

