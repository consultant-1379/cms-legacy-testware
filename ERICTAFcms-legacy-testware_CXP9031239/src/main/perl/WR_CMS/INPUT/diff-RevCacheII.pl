#!/usr/bin/perl
$help_text = "Usage: diff-RevCache.pl  <Review Cache Log File>\n";

if ( $#ARGV != 0 ) 
	{
	print $help_text;
	exit;
	}
	else {
   	 $filename = $ARGV[0];  
	}

open(REVFILE, $filename) or  die "\nCan't open: $filename !\n";

#print "\n $filename \n";

$filename_master = "$filename.master";
$filename_prox = "$filename.prox";
$filename_um = "$filename.um";


#print "\n $filename_master , $filename_prox, $filename_um \n";

open(MASTFILE, "+>$filename_master") || die "Sorry, file $filename_master is not found.\n";
open(PROXFILE, "+>$filename_prox") || die "Sorry, file $filename_prox is not found.\n";
open(UMFILE, "+>$filename_um") || die "Sorry, file $filename_um is not found.\n";


LINE : while ($SX_Line = <REVFILE>)					# skip the first few lines !!!!!1 
	{								
	chop($SX_Line);
last LINE if ( $SX_Line =~ /\=====/ ); 				 
	}

@mos = ();

LINE : while ($SX_Line = <REVFILE>)					 
	{								# Get masters
	if ( $SX_Line =~ /MO Name/ )
		{
		push @mos, $SX_Line;
		}

last LINE if ( $SX_Line =~ /PROXY MOs/ ); 				 
	}

@mos = sort(@mos);
print MASTFILE "@mos";
close(MASTFILE);

@mos = ();

LINE : while ($SX_Line = <REVFILE>)					#  
	{								# get proxies
#	chop($SX_Line);
	if ( $SX_Line =~ /MO Name/ )
		{
		push @mos, $SX_Line;
		}

last LINE if ( $SX_Line =~ /UNMANAGED MOs/ ); 				
	}

@mos = sort(@mos);
print PROXFILE "@mos";
close(PROXFILE);

@mos = ();

LINE : while ($SX_Line = <REVFILE>)					#  
	{								# get unmanaged
#	chop($SX_Line);
	if ( $SX_Line =~ /MO Name/ )
		{
		push @mos, $SX_Line;
		}

last LINE if ( $SX_Line =~ /UNMANAGED MOs/ ); 				 
	}

@mos = sort(@mos);
print UMFILE "@mos";
close(UMFILE);

@mos = ();



#$MOs=`grep "MO Name" $filename`;
#print OUTFILE $MOs;
#$SortedMOs=`sort $filename.sorted`;
#close(OUTFILE);
#open(OUTFILE, "+>$filename.sorted") || die "Sorry, can't create $filename.sorted file.\n";
#print OUTFILE $SortedMOs;

print" \n use comm -3 bef-file after-file \n";

