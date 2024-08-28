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

my $rnc = "RNC01";
my $cell_prefix    = "SubNetwork=ONRM_RootMo_R,SubNetwork=$rnc,MeContext=$rnc,ManagedElement=1,RncFunction=1,UtranCell=$rnc";
my $iubLink_prefix = "SubNetwork=ONRM_RootMo_R,SubNetwork=$rnc,MeContext=$rnc,ManagedElement=1,RncFunction=1,IubLink=";

my $cell_id = 2000;
for my $iub (1..99)
{
   my @cells = map {"$cell_prefix-$iub-$_"} (1..3);
   for my $cell (@cells)
   {
      $cell_id++;
      print "Cell is $cell with Id $cell_id\n";
      my $result = create_mo_CS( mo => "$cell", plan => $plan, attributes => "cId $cell_id utranCellIubLink $iubLink_prefix$iub" );
      print_result($result);

      my $relation = 1;
      for my $adj_cell (@cells)
      {
         next if $cell eq $adj_cell;  # don't try to create a relation from a cell to itself
         my $mo = "$cell,UtranRelation=" . $relation++;
         print "relation is $mo\nAdj cell is $adj_cell\n";
         my $result = create_mo_CS( mo => $mo, plan => $plan, attributes => "adjacentCell $adj_cell" );
         print_result($result);
      }
   }   
}



sub print_result
{
   my $result = shift;
   if ($result)
   {
      print "Error code is $result\n";
   }
   else
   {
      print "MO created OK\n";
   }
}


