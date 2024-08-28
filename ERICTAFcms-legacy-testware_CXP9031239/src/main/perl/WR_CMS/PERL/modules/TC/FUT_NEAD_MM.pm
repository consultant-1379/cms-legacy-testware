#!/usr/bin/perl

#################################################################
#
# To deal with Mixed mode Nead test Cases
#
#################################################################

sub FUT0000001 # 1.19.1.1.3
{

 log_registry("Checking New Nead module...");
}

sub FUT154 # 1.23.1.1.2
{

 log_registry("Checking delta sequence test cases...");
  my $test_slogan = $_[0];
  my $tc_id,$tc_info;
  $tc_info = "WRANCM_CMSnead_1.23.1.1.2 ; Add to sequence long, verify delta SequenceNotification received in NEAD";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my $attribute = "utranCellPosition";

  #my $rnc_name = pick_a_ne("RncFunction","NEW");
  my $rnc_name= "SubNetwork=ONRM_ROOT_MO_R,SubNetwork=RNC31,MeContext=RNC31,ManagedElement=1,RncFunction=1";
  my $result="PASSED";   # use this flag to tell if all sets worked not just one...

  if($rnc_name)
	{
	my $UtranCell = pick_a_cell($rnc_name);
        log_registry("It seems no UtranCell has been selected for the RNC => $rnc_name") if not $UtranCell;
        test_failed($test_slogan) if not $UtranCell;
        return "0" if not $UtranCell;

	for ($x=1; $x<=3; $x++)
		{
		log_registry("===== Attributes of MO Before =============");
   		my $count_attr = get_mo_attr($UtranCell,$attribute);
   		log_registry("===========================================");
		if ($x == 1)
			{  $UCposValue = "=$x"; }
		else
			{  $UCposValue = $UCposValue."+$x"; }

		my $status = set_attribute($UtranCell,$attribute,$UCposValue);	# Set with building value
		my $stat = compare_attributes($UtranCell,$attribute,$UCposValue); # Compare the values with expected

        	log_registry("========= Attributes of MO After =========");
        	$count_attr = get_mo_attr($UtranCell,$attribute);
        	log_registry("===========================================");

		$result = "FAILED" if ($stat == 0 || $status == 0 );
		}
		test_passed($test_slogan) if ($result eq "PASSED");
		test_failed($test_slogan) if ($result eq "FAILED");
	}
}

sub set_attribute
{
    my $mo = $_[0];
    my $attr = $_[1];
    my $value = $_[2];
    my $setValue = $attr.$value;
#    log_registry(" $cli_tool CLI sa:$mo:$setValue  ===========================");
    my $result = `$cli_tool CLI "sa:$mo:$setValue"  2>&1`;

    if($result =~ /Exception/ or $result =~ /Connection refused/)
	{
	        log_registry("Problem in setting attributes of MO: $mo_fdn \n $result");
		return 0;
	}
    else
	{
	return 1;
	}

}

sub compare_attributes
{
    my $mo = $_[0];
    my $attr = $_[1];
    my $value = $_[2];

    $value =~ s/\+/ /g; # To remove the + and replace with a space
    $value =~ s/^\=//g; # To remove the + and replace with a space

    my %rezzy = get_mo_attributes_CS( mo => $mo, attributes => $attr);
    if ($rezzy{$attr} =~ $value)
	{          
		log_registry("Attributes are the same $attr, $value == $rezzy{$attr}");
        	return 1; 
 	}
   else {
		log_registry("Attributes are NOT the same $attr, $value != $rezzy{$attr}");
        	return 0; 
	}

}


sub FUT153 # 1.23.1.1.1
{
  my $test_slogan = $_[0];
  my $tc_id,$tc_info;
  $tc_info = "WRANCM_CMSnead_1.23.1.1.1 ; Add to sequence MoRef, verify delta SequenceNotification received in NEAD";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
#my $rnc = pick_a_ne("RncFunction","NEW");

  my $rnc = "SubNetwork=ONRM_ROOT_MO_R,SubNetwork=RNC32,MeContext=RNC32,ManagedElement=1,RncFunction=1";
  my $result="PASSED";   # use this flag to tell if all sets worked not just one...

  if($rnc)
  {
        my ($EF_fdn,$EF_attr) = get_fdn("EutranFrequency","create");
        my $EutraNW = pick_a_mo($rnc,"EutraNetwork");
        if(!($EutraNW))
        {
                $EutraNW = "$rnc".","."EutraNetwork=$mo_proxy_cms";
                my $result = create_mo_CS(mo => $EutraNW);
                log_registry("Problem in creation of EutraNetwork mo..") if $result;
                test_failed($test_slogan) if $result;
                return "0" if $result;
        }


        $EF_fdn = base_fdn_modify("$EutraNW","$EF_fdn");
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$EF_fdn,$EF_attr,"no wait");
        test_failed($test_slogan) if not $status;
        return "0" if not $status;

	for ($x=1; $x<=3; $x++)
        	{
		log_registry("=================== Create the relation $x now =======================");
		my $utran_cell = create_UtranCell($rnc,"uarfcnUl 10 uarfcnDl 2100");
        	test_failed($test_slogan) if not $utran_cell;
        	return "0" if not $utran_cell;
        	# log_registry("Selected UtranCell for EutranFreqRelation is: $utran_cell");
        	sleep 10;
        	my ($EFR_fdn,$EF_proxy) = create_EutranFreqRelation_noWait(UC => $utran_cell, EF => $EF_fdn, base => "CLI" , number => $x);
        	log_registry("It seems there is some problem in creation of ExternalEutranFreqRelation ...") if not $EFR_fdn;
        	test_failed($test_slogan) if not $EFR_fdn;
        	$result="FAILED" if not $EFR_fdn;
		}
        my $count_attr = get_mo_attr($EF_fdn, "reservedBy");
	test_passed($test_slogan) if ($result eq "PASSED");
	test_failed($test_slogan) if ($result eq "FAILED"); 

# the 2 TC 1.23.1.1.1 and  1.23.1.1.5 will be run together
# 1.23.1.1.5 will be called to do the clean up from 1.23.1.1.1

        FUT153Delete("1.23.1.1.5" , $EF_fdn, $utran_cell, $EutraNW);

   }

} 

sub FUT153Delete # 1.23.1.1.5
{      
	my $test_slogan = $_[0];
	my $EF_fdn = $_[1];
	my $utrancell = $_[2];
	my $EutraNW = $_[3];

  	my $tc_id,$tc_info;
	$tc_info = "WRANCM_CMSnead_1.23.1.1.5 ; Delete items from an MoRef Sequence attribute on an Mo on NE Side";
	$test_slogan = "$test_slogan"."-"."$tc_info";
        log_registry("====================================================================");
        log_registry("$tc_info");

#	$EF_fdn = "SubNetwork=ONRM_ROOT_MO_R,SubNetwork=RNC32,MeContext=RNC32,ManagedElement=1,RncFunction=1,EutraNetwork=1,EutranFrequency=CMSAUTOPROXY_1";
#	$utrancell = "SubNetwork=ONRM_ROOT_MO_R,SubNetwork=RNC32,MeContext=RNC32,ManagedElement=1,RncFunction=1,UtranCell=CMSAUTOPROXY_140,EutranFreqRelation=CMSAUTOPROXY_2";

	get_mo_attr($EF_fdn, "reservedBy");
	my $clean_issue;
	# first try to delete the middle relation 

	my %EF_attrs = get_mo_attributes_CS(mo =>$EF_fdn, attributes => "reservedBy");  # get the 3 FDN's into a string
        $mo = join(" ",$EF_attrs{reservedBy});						
        my @mo = split(" ",$mo);    							# convert to array of FDNs
   	
	log_registry("=================== Delete the middle $mo[1] =======================");
        my $status = delete_mo_CLI(mo => $mo[1], base => "CLI");
        my $mark = is_resby($EF_fdn, $mo[1]);
        if($mark)
		{
		log_registry("It seems that reservedBy of $EF_fdn has not been updated");
                test_failed($test_slogan);
		return;
        	}


	log_registry("=================== Delete the last $mo[2] =======================");
        $status = delete_mo_CLI(mo => $mo[2], base => "CLI");
        $mark = is_resby($EF_fdn, $mo[2]);
        if($mark)
		{
		log_registry("It seems that reservedBy of $EF_fdn has not been updated");
                test_failed($test_slogan);
		return;
		}


	log_registry("=================== Delete the first $mo[0] =======================");
        my $status = delete_mo_CLI(mo => $mo[0], base => "CLI");
        $mark = is_resby($EF_fdn, $mo[0]);

        if($mark)
		{
		log_registry("It seems that reservedBy of $EF_fdn has not been updated");
                test_failed($test_slogan);
		}

	test_passed($test_slogan) if ($mark == 0);

        my $master_mo = get_master_for_proxy($EF_fdn);
        my $mo2 = join(" ",$EFR_fdn,$EF_proxy,$utran_cell,$master_mo);
        $mo2 = join(" ",$EFR_fdn,$EF_proxy,$utran_cell,$EutraNW,$master_mo) if ($EutraNW =~ /$mo_proxy_cms/);
        my @mo2 = split(" ",$mo);
        foreach(@mo2)
        	{
               	log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        	}


}

1;
