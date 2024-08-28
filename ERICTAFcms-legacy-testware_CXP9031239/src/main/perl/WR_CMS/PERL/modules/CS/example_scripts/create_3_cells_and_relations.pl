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

# same Iub Link used for all cells
my $iubLink   = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,IubLink=99";

my $mo_prefix = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=my_cell_";

my %cell_hash = map {("$mo_prefix$_" => $_)} (2001 .. 2003);  # create cell hash in format $cell_hash{$mo_fdn}=$cellId, for cellIds 2001,2002,2003

print "Cell list:\n";
print "Cell is $_\nCell Id is $cell_hash{$_}\n" for sort keys %cell_hash;

for my $cell (keys %cell_hash)
{
   print "Cell is $cell\n";
   my $result = create_mo_CS( mo => "$cell", plan => $plan, attributes => "cId $cell_hash{$cell} utranCellIubLink $iubLink" );
   print_result($result);
   
   my $relation = 1;
   for my $adj_cell (keys %cell_hash)
   {
      next if $cell eq $adj_cell;  # don't try to create a relation from a cell to itself
      my $mo = "$cell,UtranRelation=" . $relation++;
      print "relation is $mo\nAdj cell is $adj_cell\n";
      my $result = create_mo_CS( mo => $mo, plan => $plan, attributes => "adjacentCell $adj_cell" );
      print_result($result);
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


