#!/usr/bin/perl
sub FUT518 # 5.1.1.1.8
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_5.1.1.1.8; Create proxy ExternalENodeBFunction directly on the Node when no ExternalENodeBFunction master exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
 
  my ($base_fdn,$attr) = get_fdn("ProxyENBFunction","create");
  
  log_registry("$base_fdn,$attr");

#  my $erbs_name = pick_a_erbs_using_cell(CELL => "ExternalEUtranCellFDD" , VER => "NEW");
  my $erbs_name  = pick_a_ne(ENodeBFunction,EUtranCellFDD); # Select ERBS those have EUtranCellFDD

  if($erbs_name)
  {
	my $EUtraNetwork = pick_a_mo($erbs_name,EUtraNetwork);
	log_registry("The Network is ###### $EUtraNetwork");
	log_registry("The base_fdn number 1 is $base_fdn");
	$base_fdn =~ s/ProxyENBFunction/ExternalENodeBFunction/g;
	log_registry("$attr");
	log_registry("It seems no EUtraNetwork has been selected for the ERBS => $erbs_name") if not $EUtraNetwork;
	test_failed($test_slogan) if not $EUtraNetwork;
	return "0" if not $EUtraNetwork;
	$base_fdn = base_fdn_modify("$EUtraNetwork","$base_fdn");
        my $master_fdn = $base_fdn;
	log_registry("$EUtraNetwork");
	log_registry("The base_fdn number 2 is $base_fdn");
	my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$attr,"nowait");
	log_registry("It seems mo $base_fdn is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
	
	
	my ($EUF_count,@EUF_FDD) = get_CMS_mo("EUtranFrequency",$erbs_name);
	$flag = 1 if (!($EUF_count));
	log_registry("It seems no EUtranFrequency MO found under any of ERBS ...") if $flag;
	test_failed("$test_slogan") if $flag;
    return "0" if $flag;
	my $EUF_FDD = $EUF_FDD[0];
	
	
	my $fdd = $base_fdn;
	$fdd = "$fdd".","."ExternalEUtranCellFDD=$mo_proxy_cms";
	log_registry("This has ExternalEUtranCellFDD appended $fdd");
	
	my ($base_fdn,$attr) = get_fdn("ExternalEUtranCellFDD","create");
	$attr = "$attr"." "."$EUF_FDD";
	my ($status,$rev_id) = proxy_mo_create_decision("CLI",$fdd,$attr,"nowait");

	
	
	
	############################
	
        my %attrs = get_mo_attributes_CS(mo => $EUF_FDD , attributes => "reservedBy");
        my $Freq;
        my @Freq = split(" ","$attrs{reservedBy}");
        foreach(@Freq)
        {
                $Freq = $_ if ($_ =~ /EUtranFreqRelation\=/);
                last if $Freq;
        }

        log_registry("This is the result :: $Freq");
        log_registry("It seems ExternalEUtranCellFDD are not reservedby EUtranCellRelation, that is
needed for this test case...") if not $Freq;

        my $time = sleep_start_time();
	
        $EUCR_fdd = create_EUtranCellRelation(base=>"CLI", EUFR=>$Freq,EEUCXDD => $fdd);
        log_registry("The cell $EUCR_fdd");

#        my $time = sleep_start_time();
	long_sleep_found($time);
	


        my $master_mo = get_master_for_proxy($fdd);
        log_registry("This is the proxies master $master_mo"); 
        if($master_mo)
         {
                test_passed($test_slogan);
		log_registry("Created Proxy MO $fdd has found its master $master_mo");
		log_registry("The master for proxy result is: \n $master_mo");
	}
	else
	{
		test_failed($test_slogan);
		return "0";
	}
  }
  else
  {
	log_registry("It seems no synched ERBS found....");
	test_failed($test_slogan);
  }
  
}


sub FUT519 # 5.1.1.1.3
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_5.1.1.1.3; Create proxy ExternalEUtranCellTDD directly on the node, no master exists in the subnetwork (Missing Master autofix on); Normal; 1;";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
 
  my ($base_fdn,$attr) = get_fdn("ProxyENBFunction","create");
  
  log_registry("$base_fdn,$attr");
#  my $erbs_name = pick_a_erbs_using_cell(CELL => "ExternalEUtranCellTDD");
  my $erbs_name  = pick_a_ne(ENodeBFunction,EUtranCellTDD); # Select ERBS those have EUtranCellFDD

  if($erbs_name)
  {
	my $EUtraNetwork = pick_a_mo($erbs_name,EUtraNetwork);
	log_registry("The Network is ###### $EUtraNetwork");
	log_registry("The base_fdn number 1 is $base_fdn");
	$base_fdn =~ s/ProxyENBFunction/ExternalENodeBFunction/g;
	log_registry("$attr");
	log_registry("It seems no EUtraNetwork has been selected for the ERBS => $erbs_name") if not $EUtraNetwork;
	test_failed($test_slogan) if not $EUtraNetwork;
	return "0" if not $EUtraNetwork;
	$base_fdn = base_fdn_modify("$EUtraNetwork","$base_fdn");
	log_registry("$EUtraNetwork");
	log_registry("The base_fdn number 2 is $base_fdn");
	my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr,"nowait");
	log_registry("It seems mo $base_fdn is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
	
	
	my ($EUF_count,@EUF_TDD) = get_CMS_mo("EUtranFrequency",$erbs_name);
	$flag = 1 if (!($EUF_count));
	log_registry("It seems no EUtranFrequency MO found under any of ERBS ...") if $flag;
	test_failed("$test_slogan") if $flag;
    return "0" if $flag;
	my $EUF_TDD = $EUF_TDD[0];
	
	
	my $tdd = $base_fdn;
	$tdd = "$tdd".","."ExternalEUtranCellTDD=$mo_proxy_cms";
	log_registry("This has ExternalEUtranCellTDD appended $tdd");
	
	my ($base_fdn,$attr) = get_fdn("ExternalEUtranCellTDD","create");
	$attr = "$attr"." "."$EUF_TDD";
	my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$tdd,$attr,"nowait");

	
	
	############################
	
        my %attrs = get_mo_attributes_CS(mo => $EUF_TDD , attributes => "reservedBy");
        my $Freq;
        my @Freq = split(" ","$attrs{reservedBy}");
        foreach(@Freq)
        {
                $Freq = $_ if ($_ =~ /EUtranFreqRelation\=/);
                last if $Freq;
        }

        log_registry("This is the result :: $Freq");
        log_registry("It seems ExternalEUtranCellTDD are not reservedby EUtranCellRelation, that is
needed for this test case...") if not $Freq;

	
    $EUCR_tdd = create_EUtranCellRelation(base=>"CLI", EUFR=>$Freq,EEUCXDD => $tdd);
	
        my $time = sleep_start_time();
        long_sleep_found($time);

        my $master_mo = get_master_for_proxy($tdd);
        log_registry("This is the proxies master $master_mo");
        if($master_mo)
         {
                test_passed($test_slogan);
                log_registry("Created Proxy MO $fdd has found its master $master_mo");
                log_registry("The master for proxy result is: \n $master_mo");
        }
        else
        {
                test_failed($test_slogan);
                return "0";
        }
  }
  else
  {
	log_registry("It seems no synched ERBS found....");
	test_failed($test_slogan);
  }
  
}




sub FUT520  # 5.2.1.1.1  
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMS SNAD_5.2.1.1.1:: Set Proxy MO - Set Proxy MO ExternalENodeBFunction attribute, Master in SubNetwork; Normal; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

   my ($count,@ENB_fdn) = get_CMS_mo("ExternalENodeBFunction",$mo_proxy_cms); 
   foreach(@ENB_fdn)
   { 
          $EENBF = $_ if ($_ =~ /ManagedElement\=/);
          last if $EENBF;
   }

  log_registry("$EENBF"); 
  if($count)
  {
     my ($fdn,$set_attrs) = get_fdn("ExternalENodeBFunction","set");
	($status,$rev_id) = proxy_mo_set_decision("CSCLI",$EENBF,$set_attrs);
	

	log_registry("Problem in setting attributes of proxy ExternalENodeBFunction mo ...") if not $status;
	test_failed("$test_slogan") if not $status;
    test_passed("$test_slogan") if $status;
 }
  

}

sub FUT521  # 5.2.1.1.5  
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMS SNAD_5.2.1.1.5:: Set Proxy MO - Set Proxy MO ExternalENodeBFunction Trafficial Information attributes, Master in SubNetwork (autofix on); Normal; 1";
  log_registry("$tc_info");
  $test_slogan = "$test_slogan"."-"."$tc_info";

   my ($count,@ENB_fdn) = get_CMS_mo("ExternalENodeBFunction",$mo_proxy_cms); 
   foreach(@ENB_fdn)
   { 
          $EENBF = $_ if ($_ =~ /ManagedElement\=/);
          last if $EENBF;
   }

   log_registry("This is the selected MoFDN $EENBF"); 
   my $state = get_master_for_proxy($EENBF);
   log_registry("This is the proxies master $state");
   get_mo_attr($EENBF,"eNodeBPlmnId");
   log_registry("=============================================================================");
   my $new_id = "$mo_proxy_cms"." eNodeBPlmnId mcc=000+mnc=111+mncLength=3";
   log_registry("result1 = $new_id");
   my $new_attrs = "eNodeBPlmnId"." "."$new_id";
   log_registry("result2 = $new_attrs");  
   ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$EENBF,$new_attrs,"NW");
   log_registry("Either Problem in setting attribute ...") if not $status;

   my %EENBF_attr_aft = get_mo_attributes_CS(mo =>$EENBF, attributes => "eNodeBPlmnId");
   log_registry("======================== ExternalENodeBFunction attribute After ===============");
   get_mo_attr($EENBF,"eNodeBPlmnId");
   log_registry("===============================================================================");
   my $master = get_master_for_proxy($EENBF);
   log_registry("This is the proxies master $master");
   if($master)
   {
       test_passed($test_slogan);
       my $delete_master = delete_mo_CS(mo => $state);
   } 
   else
   {
       test_failed($test_slogan);
       return "0";
   }	

}

sub FUT522  # 5.2.1.1.3  
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMS_SNAD_5.2.1.1.3; Set Proxy MO - Set Proxy MO ExternalEUtranCellFDD/TDD Network Information/ Traffic Information attributes, Master in SubNetwork (autofix on); Normal; 1";
  log_registry("$tc_info");
  $test_slogan = "$test_slogan"."-"."$tc_info";

   my ($count,@UF_fdn) = get_CMS_mo("ExternalEUtranCellFDD",$mo_proxy_cms);  
  
   foreach(@UF_fdn)
   { 
          $EENBF = $_ if ($_ =~ /ManagedElement\=/);
          last if $EENBF;
   }

   log_registry("This is the selected MoFDN $EENBF"); 
   my $state = get_master_for_proxy($EENBF);
   log_registry("This is the proxies master $state");
   get_mo_attr($EENBF,"masterEUtranCellFDDId");
   log_registry("=============================================================================");
   my $new_id = "$mo_proxy_cms"." masterEUtranCellFDDId CMS_AUTOPROXY_9";
   log_registry("result1 = $new_id");
   my $new_attrs = "masterEUtranCellFDDId"." "."$new_id";
   log_registry("result2 = $new_attrs");  
   ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$EENBF,$new_attrs,"NW");
   log_registry("Either Problem in setting attribute ...") if not $status;

   my %EENBF_attr_aft = get_mo_attributes_CS(mo =>$EENBF, attributes => "masterEUtranCellFDDId");
   log_registry("======================== ExternalEUtranCellFDD attribute After ===============");
   get_mo_attr($EENBF,"masterEUtranCellFDDId");
   log_registry("===============================================================================");
   my $master = get_master_for_proxy($EENBF);
   log_registry("This is the proxies master $master");
   if($master)
   {
       test_passed($test_slogan);
       my $delete_master = delete_mo_CS(mo => $state);
   } 
   else
   {
       test_failed($test_slogan);
       return "0";
   }	


   ($count,@UF_fdn) = get_CMS_mo("ExternalEUtranCellTDD",$mo_proxy_cms);  
  
   foreach(@UF_fdn)
   { 
          $EENBF = $_ if ($_ =~ /ManagedElement\=/);
          last if $EENBF;
   }

   log_registry("This is the selected MoFDN $EENBF"); 
   my $state = get_master_for_proxy($EENBF);
   log_registry("This is the proxies master $state");
   get_mo_attr($EENBF,"masterEUtranCellTDDId");
   log_registry("=============================================================================");
   my $new_id = "$mo_proxy_cms"." masterEUtranCellTDDId CMS_AUTOPROXY_9";
   log_registry("result1 = $new_id");
   my $new_attrs = "masterEUtranCellTDDId"." "."$new_id";
   log_registry("result2 = $new_attrs");  
   ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$EENBF,$new_attrs,"NW");
   log_registry("Either Problem in setting attribute ...") if not $status;

   my %EENBF_attr_aft = get_mo_attributes_CS(mo =>$EENBF, attributes => "masterEUtranCellTDDId");
   log_registry("======================== ExternalEUtranCellFDD attribute After ===============");
   get_mo_attr($EENBF,"masterEUtranCellTDDId");
   log_registry("===============================================================================");
   my $master = get_master_for_proxy($EENBF);
   log_registry("This is the proxies master $master");
   if($master)
   {
       test_passed($test_slogan);
       my $delete_master = delete_mo_CS(mo => $state);
   } 
   else
   {
       test_failed($test_slogan);
       return "0";
   }	

}

sub FUT524  # 5.3.1.1.1 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_5.3.1.1.1 ; Delete Proxy MO - Delete Proxy Mo ExternalEUtranCellFDD from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  log_registry("From first $EUCR_fdd");

  my ($count1,@FDD_fdn) = get_CMS_mo("ExternalEUtranCellFDD",$mo_proxy_cms);
  my ($count3,@ENB_fdn) = get_CMS_mo("ExternalENodeBFunction",$mo_proxy_cms);
  
  if($count1)
  {
     log_registry("FDD ARRAY: @FDD_fdn");
     foreach(@FDD_fdn)
     { 
          $FDD = $_ if ($_ =~ /ManagedElement\=/);
          last if $FDD;
     } 
	 ############################
	
        my %attrs = get_mo_attributes_CS(mo => $FDD , attributes => "reservedBy");
        my $Freq;
        my @Freq = split(" ","$attrs{reservedBy}");
        foreach(@Freq)
        {
                $Freq = $_ if ($_ =~ /EUtranFreqRelation\=/);
                last if $Freq;
        }

        log_registry("This is the result :: $Freq");
        log_registry("It seems ExternalEUtranCellFDD are not reservedby EUtranCellRelation, that is
needed for this test case...") if not $Freq;
	 log_registry("This is the MoFDN $FDD");
     my $master_mo = get_master_for_proxy($FDD);
     log_registry("THE MASTER IS: $master_mo");
     proxy_mo_delete_decision("0","CSCLI",$Freq);
     proxy_mo_delete_decision("0","CSCLI",$FDD);
     my $delete_master = delete_mo_CS(mo => $master_mo);
  }
  if($count3)
  { 
     log_registry("ENB ARRAY: @ENB_fdn");
     log_registry("The selected ENB is : $ENB_fdn[0]");
     my $master_mo = get_master_for_proxy($ENB_fdn[0]);
     log_registry("THE MASTER IS: $master_mo");
     proxy_mo_delete_decision($test_slogan,"CSCLI",$ENB_fdn[0]);
  }	 
  else
  {
        log_registry("It seems no ExternalEUtranCellFDD/ExternalEUtranCellTDD found  ...");
        test_failed("$test_slogan");
  } 
}



sub FUT525  # 5.3.1.1.3 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_5.3.1.1.3 ; Delete Proxy Mo - Delete Prxoy ExternalEUtranCellTDD through the EM (Netsim)";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  log_registry("From first $EUCR_fdd");


  my ($count1,@TDD_fdn) = get_CMS_mo("ExternalEUtranCellTDD",$mo_proxy_cms);
  my ($count3,@ENB_fdn) = get_CMS_mo("ExternalENodeBFunction",$mo_proxy_cms);
  
  if($count1)
  {
     log_registry("TDD ARRAY: @TDD_fdn");
     foreach(@TDD_fdn)
     { 
          $TDD = $_ if ($_ =~ /ManagedElement\=/);
          last if $TDD;
     } 
	 ############################
	
        my %attrs = get_mo_attributes_CS(mo => $TDD , attributes => "reservedBy");
        my $Freq;
        my @Freq = split(" ","$attrs{reservedBy}");
        foreach(@Freq)
        {
                $Freq = $_ if ($_ =~ /EUtranFreqRelation\=/);
                last if $Freq;
        }

        log_registry("This is the result :: $Freq");
        log_registry("It seems ExternalEUtranCellTDD are not reservedby EUtranCellRelation, that is
needed for this test case...") if not $Freq;
	 
	 log_registry("This is the MoFDN $TDD");
     my $master_mo = get_master_for_proxy($TDD);
     proxy_mo_delete_decision($test_slogan,"CLI",$Freq);
     proxy_mo_delete_decision($test_slogan,"CLI",$TDD);
     my $delete_master = delete_mo_CS(mo => $master_mo);
  }
  if($count3)
  { 
     log_registry("ENB ARRAY: @ENB_fdn");
     log_registry("The selected ENB is : $ENB_fdn[0]");
     my $master_mo = get_master_for_proxy($ENB_fdn[0]);
     log_registry("THE MASTER IS: $master_mo");
     proxy_mo_delete_decision($test_slogan,"CLI",$ENB_fdn[0]);
  }	 
  else
  {
        log_registry("It seems no ExternalEUtranCellFDD/ExternalEUtranCellTDD found  ...");
        test_failed("$test_slogan");
  }
	
	

  
}

# eeitjn 30th October 2012
# So master mo's not have struct attributes, so cannot use cstest any more, have to use proxy CLI
# These TC's below have been moved from master script into proxy script.



sub FUT150  # 4.3.1.1.31 Create   - Create   ExternalEUtranPlmn from an application;
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.31 ; Create   - Create   ExternalEUtranPlmn from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("MasterExternalEUtranPlmn","create");
  log_registry("FDN is $base_fdn, attributes are : $attr");

  my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr,"nowait");
  
  my $stat = get_master($base_fdn);

  log_registry("The ExternalEUtranPlmn does not appear in the SNAD cache");

  test_passed($test_slogan) if not ($stat);
  test_failed($test_slogan) if ($stat);
  return "1" if not ($stat); 
}



sub FUT151  # 4.3.1.1.28 Create - Create ExternalENodeBFunction from an application;
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.28 ; Create - Create ExternalENodeBFunction from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("MasterExternalENodeBFunction","create");
  log_registry("FDN is $base_fdn, attributes are : $attr");

  my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr,"nowait");
  
  my $stat = get_master($base_fdn);

  test_passed($test_slogan) if ($stat);
  test_failed($test_slogan) if not ($stat);
  return "1" if not ($stat);
}



sub FUT152  # 4.3.1.2.19 Create   ExternalEUtranCellFDD from an application
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.2.19 ; Create   - Create   ExternalEUtranCellFDD from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("MasterExternalEUtranCellFDD","create");
  log_registry("FDN is $base_fdn, attributes are : $attr");
  my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr,"nowait");
  my $stat = get_master($base_fdn);

  test_passed($test_slogan) if ($stat);
  test_failed($test_slogan) if not ($stat);
  return "0" if not ($stat);
}

sub FUT153  # 4.3.1.2.15 Create   ExternalEUtranCellTDD from an application
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.2.15 ; Create   - Create   ExternalEUtranCellTDD from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("MasterExternalEUtranCellTDD","create");
  log_registry("FDN is $base_fdn, attributes are : $attr");
  my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr,"nowait");
  my $stat = get_master($base_fdn);

  test_passed($test_slogan) if ($stat);
  test_failed($test_slogan) if not ($stat);
  return "0" if not ($stat);

}

sub FUT156  #4.3.1.1.16
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.16;Create master sn ExternalEutranFrequency from an application";
  my ($base_fdn, $attr) = get_fdn("ExternalEutranFrequency","create");
#  mo_create_decision($test_slogan,$base_fdn, $attr);
  log_registry("FDN is $base_fdn, attributes are : $attr");
  my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr,"nowait");
  my $stat = get_master($base_fdn);

  test_passed($test_slogan) if ($stat);
  test_failed($test_slogan) if not ($stat);
  return "0" if not ($stat);
}

sub FUT157  # 4.3.2.1.11
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.2.1.11 ; Set ExternalEutranFrequency attribute";

  my ($base_fdn, $attr) = get_fdn("ExternalEutranFrequency","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUT158  # 4.3.3.1.23
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.1.23;Delete Master ExternalEutranFrequency MO from an application";

  my ($base_fdn, $attr) = get_fdn("ExternalEutranFrequency","delete");

  mo_delete_decision($test_slogan,$base_fdn,$attr);
}

# Not sure if CMS CLI works in planned area...
# create Mo again in valid so we can do the set and delete below. (For now)
sub FUT159  #4.3.5.1.4
{

  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.5.1.4;Create master ExternalEutranFrequency from an application in a PLANNED Area";
  my $plan_name = create_plan_name();
  my ($base_fdn, $attr) = get_fdn("ExternalEutranFrequency","create");

  log_registry("FDN is $base_fdn, attributes are : $attr");
  my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr,"nowait");
  my $stat = get_master($base_fdn);

  test_passed($test_slogan) if ($stat);
  test_failed($test_slogan) if not ($stat);
  return "0" if not ($stat);
}

sub FUT160  # 4.3.2.1.15
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.2.1.15 ; Set ExternalEutranFrequency attribute, Planned Area";
  my $plan_name = create_plan_name();
  my ($base_fdn, $attr) = get_fdn("ExternalEutranFrequency","set");
  mo_set_decision($test_slogan,$base_fdn,$attr,$plan_name);
}

sub FUT161  # 4.3.3.1.27
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.1.27;Delete Master ExternalEutranFrequency MO from an application, Planned Area";
  my $plan_name = create_plan_name();
  my ($base_fdn, $attr) = get_fdn("ExternalEutranFrequency","delete");
  mo_delete_decision($test_slogan,$base_fdn,$attr,$plan_name);
}


1;
