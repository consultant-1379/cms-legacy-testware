#!/usr/bin/perl

#################################################################
#
# To deal with Proxy Mos
#
#################################################################

sub FUT000  #0.0.0.0.0CLEAN  To check if MO exist created by proxy.pl after completion
{
  log_registry("==================== CLEAN UP: proxy.pl ========================");
  log_registry("Check if any MO still exist created by proxy.pl after completion of batch...");
  my $list_mos = list_mos_exist_cs("9",$mo_proxy_cms);
  if($list_mos)
  {
        log_registry("===============================================================");
        log_registry("========= LIST of MOs =========================================");
        log_registry("$list_mos");
        log_registry("===============================================================");
        log_registry("Trying to delete MOs.... if someone fails please delete it manually....");
        my @mo = split ('\n',$list_mos);
	my @rev_mo = reverse(@mo);
        foreach(@rev_mo)
        {
                log_registry("Trying to delete MO => $_ ");
                my $result = delete_mo_CS( mo => $_ );
                log_registry("ERROR => problem in deletion of MO $_ ") if $result;

                # eeitjn if any failed to delete retry using CLI (EUtranCellRelation were not deleting in 13.0)
                if ($result) {
                	    my $status = delete_mo_CLI(mo => $_, base => "CLI");
                	    log_registry("Delete result => $status");   
                	    }

        }
  }
  else
  {
        log_registry("It seems no MO exist in cs created by proxy.pl.....");
        log_registry("It looking good,But please check once manually in cstest as well...");
  }
}

sub FUT001 # 4.4.1.2.1 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.1; Create   - Create ExternalUtranCell proxy when no ExternalUtranCell master exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
 
  my ($base_fdn,$attr) = get_fdn("ExternalUtranCell","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
	my $IurLink = pick_a_mo($rnc_name,IurLink);
	log_registry("It seems no IurLink has been selected for the RNC => $rnc_name") if not $IurLink;
	test_failed($test_slogan) if not $IurLink;
	return "0" if not $IurLink;
	$base_fdn = base_fdn_modify("$IurLink","$base_fdn");
	my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	log_registry("It seems mo $base_fdn is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
	test_passed($test_slogan) if ($status and $rev_id == 7);
	test_failed($test_slogan) if (!($status) or $rev_id != 7);
  }
  else
  {
	log_registry("It seems no synched RNC found....");
	test_failed($test_slogan);
  }
}


sub FUT002  # 4.4.1.2.2 and 4.4.2.2.2, 4.4.2.2.7, 4.4.2.2.5
{
  my $test_slogan = $_[0];
  my $tc_id,$tc_info;
  $tc_id = 1 if($test_slogan =~ /4\.4\.1\.2\.2/);
  $tc_id = 2 if($test_slogan =~ /4\.4\.2\.2\.2/);
  $tc_id = 3 if($test_slogan =~ /4\.4\.2\.2\.7/);
  $tc_id = 4 if($test_slogan =~ /4\.4\.2\.2\.5/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.2; Create   - Create  rncLocationArea when no master exists from an application" if($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.2.2.2 ; Set Proxy MO - Set   rncLocationArea attribute lac value" if($tc_id == 2);
  $tc_info = "WRANCM_CMSSnad_4.4.2.2.7 ; Set Proxy MO - Set   rncServiceArea attribute sac value" if($tc_id == 3);
  $tc_info = "WRANCM_CMSSnad_4.4.2.2.5 ; Set Proxy MO - Set   rncRoutingArea attribute rac value" if($tc_id == 4);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($base_fdn,$attr) = get_fdn("LocationArea","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
	my @list_LAs = PICK_NEW_LAS(2);
	my $lac_val = $list_LAs[0];
	my $oth_lac = $list_LAs[1];
	log_registry("It seems no new lac values are selected ..") if not ($lac_val and $oth_lac);
	test_failed($test_slogan) if not ($lac_val and $oth_lac);
	return "0" if not ($lac_val and $oth_lac);
	$base_fdn = base_fdn_modify($rnc_name,$base_fdn);
	$attr = "$attr"." "."lac"." "."$lac_val";
	my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	if($status and $rev_id == 7)
	{
        	my $sac_fdn = "$base_fdn".","."ServiceArea="."$mo_proxy_cms"."_TEMP_1";
        	my ($sac_status,$rev_sac) = proxy_mo_create_decision("CSCLI",$sac_fdn,"sac 1","no wait");
		test_failed($test_slogan) if not $sac_status;
		return "0" if not $sac_status;
        	my $rac_fdn = "$base_fdn".","."RoutingArea="."$mo_proxy_cms"."_TEMP_1";
        	my ($rac_status,$rev_rac) = proxy_mo_create_decision("CSCLI",$rac_fdn,"rac 30","no wait");
		test_failed($test_slogan) if not $rac_status;
		return "0" if not $rac_status;
		my $time = sleep_start_time();
		my $cell = create_UtranCell($rnc_name,"lac $lac_val sac 1 rac 30");	
		log_registry("It seems problem in creation of UtranCell..") if not $cell;
		test_failed($test_slogan) if not $cell;
		return "0" if not $cell;
		long_sleep_found($time);
		my $review_cache_log = cache_file();
   		my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
   		get_mo_attr($base_fdn) if $rev_log;
   		my $master_mo = get_master_for_proxy($base_fdn);
   		log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
		log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
		log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
		test_failed($test_slogan) if ($rev_d != 1 or !($master_mo));
		test_passed($test_slogan) if ($tc_id == 1 and $rev_d == 1 and $master_mo);
		my $new_master;
		if($tc_id == 2 and $rev_d == 1 and $master_mo)
		{
			my $mod_attrs = "lac $oth_lac userLabel $mo_proxy_cms"."23";
			my($status,$rev_id) = proxy_mo_set_decision("CSCLI",$base_fdn,$mod_attrs);
			log_registry("Problem in setting attribute of proxy LocationArea mo..") if not $status;
			log_registry("It seems proxy LocationArea mo is not consistent after modifying attribute..") if ($status and $rev_id != 1);
			test_failed($test_slogan) if (!($status) or ($rev_id != 1));
			if($status and $rev_id == 1) {
				$new_master = get_master_for_proxy($base_fdn);
				log_registry("New Master Mo for the Given Proxy is: \n $new_master") if ($new_master and $new_master !~ /$master_mo$/);
				log_registry("There is no new master get created for proxy") if (!($new_master) or $new_master =~ /$master_mo$/);
				test_failed($test_slogan) if (!($new_master) or $new_master =~ /$master_mo$/);
				test_passed($test_slogan) if ($new_master and $new_master !~ /$master_mo$/); }
		}
		if($tc_id == 3 and $rev_d == 1 and $master_mo)
		{
			my $sac_master = get_master_for_proxy($sac_fdn);
			log_registry("It seems ServiceArea does not have master..") if not $sac_master;
			test_failed($test_slogan) if not $sac_master;
			return "0" if not $sac_master;
			log_registry("Master of ServiceArea is: $sac_master") if $sac_master;
			my $mod_attrs = "sac $oth_lac userLabel $mo_proxy_cms"."23";
			my($status,$rev_id) = proxy_mo_set_decision("CSCLI",$sac_fdn,$mod_attrs);
			log_registry("Problem in setting attribute of proxy ServiceArea mo..") if not $status;
			log_registry("It seems proxy ServiceArea mo is not consistent after modifying attribute..") if ($status and $rev_id != 1);
			test_failed($test_slogan) if (!($status) or ($rev_id != 1));
			if($status and $rev_id == 1) {
				$new_master = get_master_for_proxy($sac_fdn);
				log_registry("New Master Mo for the Given Proxy is: \n $new_master") if ($new_master and $new_master !~ /$sac_master$/);
				log_registry("There is no new master get created for proxy") if (!($new_master) or $new_master =~ /$sac_master$/);
				test_failed($test_slogan) if (!($new_master) or $new_master =~ /$sac_master$/);
				test_passed($test_slogan) if ($new_master and $new_master !~ /$sac_master$/); }
		}
		if($tc_id == 4 and $rev_d == 1 and $master_mo)
		{
			my $rac_master = get_master_for_proxy($rac_fdn);
			log_registry("It seems RoutingArea does not have master..") if not $rac_master;
			test_failed($test_slogan) if not $rac_master;
			return "0" if not $rac_master;
			log_registry("Master of RoutingArea is: $rac_master") if $rac_master;
			my $mod_attrs = "rac 37 userLabel $mo_proxy_cms"."23";
			my($status,$rev_id) = proxy_mo_set_decision("CSCLI",$rac_fdn,$mod_attrs);
			log_registry("Problem in setting attribute of proxy RoutingArea mo..") if not $status;
			log_registry("It seems proxy RoutingArea mo is not consistent after modifying attribute..") if ($status and $rev_id != 1);
			test_failed($test_slogan) if (!($status) or ($rev_id != 1));
			if($status and $rev_id == 1) {
				$new_master = get_master_for_proxy($rac_fdn);
				log_registry("New Master Mo for the Given Proxy is: \n $new_master") if ($new_master and $new_master !~ /$rac_master$/);
				log_registry("There is no new master get created for proxy") if (!($new_master) or $new_master =~ /$rac_master$/);
				test_failed($test_slogan) if (!($new_master) or $new_master =~ /$rac_master$/);
				test_passed($test_slogan) if ($new_master and $new_master !~ /$rac_master$/); }
		}
###############################  Clean up Process ##########################################
  		log_registry("CLEANUP: Deleting Cell: $cell");
		$time = sleep_start_time();
                my $clean_issue = delete_mo_CS(mo => $cell);
		log_registry("Warning: Problem in deletion of MO $cell ") if $clean_issue;
		$status = does_mo_exist_CLI( base => CSCLI, mo => $base_fdn);
  		log_registry("Specified MO => $base_fdn exist...") if ($status eq "YES");
		log_registry("Proxy also get deleted with the UtranCell.....") if not $status;
		log_registry("Deleting master mo $master_mo") if not $status;
		$clean_issue = delete_mo_CS(mo => $master_mo);
		log_registry("Warning: Problem in deletion of MO $master_mo") if $clean_issue;
		log_registry("Deleting master mo $new_master") if $new_master;
		$clean_issue = delete_mo_CS(mo => $new_master) if $new_master;
		log_registry("Warning: Problem in deletion of MO $new_master") if ($new_master and $clean_issue);
	}
	else
	{
		log_registry("It seems mo is not in Redundant state,while it should be");
		test_failed($test_slogan); 
	}
  }
  else
  {
        log_registry("It seems no synched RNC found....");
        test_failed($test_slogan);
  }
}

sub FUT003  # 4.4.1.2.3
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.3; Create   - Create  rncRoutingArea when no master exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($lac_fdn,$attr_lac) = get_fdn("LocationArea","create");
  my ($base_fdn,$attr) = get_fdn("RoutingArea","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
	my @list_LAs = PICK_NEW_LAS(1);
	my $lac_val = $list_LAs[0];
	$lac_fdn = "$lac_fdn"."_TEMP_1";
	$lac_fdn = base_fdn_modify($rnc_name,$lac_fdn);
        $attr_lac = "$attr_lac"." "."lac"." "."$lac_val";
        my ($lac_status,$rev_lac) = proxy_mo_create_decision("CSCLI",$lac_fdn,$attr_lac,"no wait");
	test_failed($test_slogan) if not $lac_status;
	return "0" if not $lac_status;
	$base_fdn = base_fdn_modify($lac_fdn,$base_fdn);
	my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	if($status and $rev_id == 7)
	{
                my $sac_fdn = "$lac_fdn".","."ServiceArea="."$mo_proxy_cms"."_TEMP_2";
                my ($sac_status,$rev_sac) = proxy_mo_create_decision("CSCLI",$sac_fdn,"sac 1","no wait");
		test_failed($test_slogan) if not $sac_status ;
                return "0" if not $sac_status;
                my $time = sleep_start_time();
                my $cell = create_UtranCell($rnc_name,"lac $lac_val sac 1 $attr ");
		log_registry("It seems problem in creation of UtranCell  ...") if not $cell;
		test_failed("$test_slogan") if not $cell;
		return "0" if not $cell;
                long_sleep_found($time);
                my $review_cache_log = cache_file();
                my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
                get_mo_attr($base_fdn) if $rev_log;
                my $master_mo = get_master_for_proxy($base_fdn);
                log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
                log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
		log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
                test_passed($test_slogan) if ($rev_d == 1);
                test_failed($test_slogan) if ($rev_d != 1);
###############################  Clean up Process ##########################################
		my $master_la = get_master_for_proxy($lac_fdn);
                log_registry("CLEANUP: Deleting Cell: $cell");
                $time = sleep_start_time();
                my $clean_issue = delete_mo_CS(mo => $cell);
		log_registry("Warning: Problem in deletion of MO $cell ") if $clean_issue;
                $status = does_mo_exist_CLI( base => CSCLI, mo => $base_fdn);
                log_registry("Specified MO => $base_fdn exist...") if ($status eq "YES");
                log_registry("Proxy also get deleted with the UtranCell.....") if not $status;
		$clean_issue = delete_mo_CS(mo => $master_la) if $master_la;
		log_registry("Warning: Problem in deletion of MO $master_la") if $clean_issue;
	}
	else
	{
		log_registry("It seems mo is not in Redundant state,while it should be");
		test_failed($test_slogan); 
	}
  }
  else
  {
	log_registry("It seems no synched RNC found....");
	test_failed($test_slogan);
  } 
}

sub FUT004  # 4.4.1.2.4 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.4; Create   - Create  rncServiceArea when no master exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($lac_fdn,$attr_lac) = get_fdn("LocationArea","create");
  my ($base_fdn,$attr) = get_fdn("ServiceArea","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
        my @list_LAs = PICK_NEW_LAS(1);
        my $lac_val = $list_LAs[0];
	$lac_fdn = "$lac_fdn"."_TEMP_2";
	$lac_fdn = base_fdn_modify($rnc_name,$lac_fdn);
        $attr_lac = "$attr_lac"." "."lac"." "."$lac_val";
        my ($lac_status,$rev_lac) = proxy_mo_create_decision("CSCLI",$lac_fdn,$attr_lac,"no wait");
	test_failed($test_slogan) if not $lac_status;
        return "0" if not $lac_status;
	$base_fdn = base_fdn_modify($lac_fdn,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
        if($status and $rev_id == 7)
        {
                my $time = sleep_start_time();
                my $cell = create_UtranCell($rnc_name,"lac $lac_val $attr ");
		log_registry("It seems problem in creation of UtranCell...") if not $cell;
		test_failed($test_slogan) if not $cell;
		return "0" if not $cell;
                long_sleep_found($time);
                my $review_cache_log = cache_file();
                my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
                get_mo_attr($base_fdn) if $rev_log;
                my $master_mo = get_master_for_proxy($base_fdn);
                log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
                log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
		log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
                test_passed($test_slogan) if ($rev_d == 1);
                test_failed($test_slogan) if ($rev_d != 1);
###############################  Clean up Process ##########################################
		my $master_la = get_master_for_proxy($lac_fdn);
                log_registry("CLEANUP: Deleting Cell: $cell");
                $time = sleep_start_time();
                my $clean_issue = delete_mo_CS(mo => $cell);
		log_registry("Warning: Problem in deletion of MO $cell ") if $clean_issue;
                $status = does_mo_exist_CLI( base => CSCLI, mo => $base_fdn);
                log_registry("Specified MO => $base_fdn exist...") if ($status eq "YES");
                log_registry("Proxy also get deleted with the UtranCell.....") if not $status;
                $clean_issue = delete_mo_CS(mo => $master_la) if $master_la;
		log_registry("Warning: Problem in deletion of MO $master_la") if $clean_issue;
        }
	else
	{
		log_registry("It seems mo is not in Redundant state,while it should be");
		test_failed($test_slogan);
	}

  }
  else
  {
        log_registry("It seems no SYNCHED RNC found..."); 
        test_failed($test_slogan);
  }
}

sub FUT005  # 4.4.2.2.1
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.2.1; Set Proxy MO - Set   rncLocationArea attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($base_fdn,$attr) = get_fdn("LocationArea","set");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
        my @list_LAs = PICK_NEW_LAS(2);
        my $lac_val = $list_LAs[0];
	$base_fdn = base_fdn_modify($rnc_name,$base_fdn);
        my $attr_create = "lac"." "."$lac_val";
        my ($status,$rev) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr_create,"no wait");
        if($status)
        {
		$lac_val = $list_LAs[1];
		$attr = "$attr"." "."lac"." "."$lac_val";
	  	my ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$base_fdn,$attr);		
		log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
		test_passed($test_slogan) if ($status and ($rev_id == 7));
		test_failed($test_slogan) if (!($status) or ($rev_id != 7)); 
      	}
	else
	{
		test_failed($test_slogan); 
	}
  }
  else
  {
        log_registry("It seems no SYNCHED RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT006  # 4.4.2.2.4 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.2.4; Set Proxy MO - Set   rncRoutingArea attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $lac_fdn;
  my ($base_fdn,$attr) = get_fdn("RoutingArea","set");
  my ($count,@la_FDN) = get_CMS_mo("LocationArea",$mo_proxy_cms);
  if($count)
  {
	foreach(@la_FDN)
        {
                $lac_fdn = $_ if ($_ =~ /MeContext=/);
        }
        log_registry("It seems no Proxy Location Area exist created by $mo_proxy_cms , please run the TC 4.4.2.2.1 once") if not $lac_fdn;
        test_failed($test_slogan) if not $lac_fdn;
        return "0" if not $lac_fdn;
	$base_fdn = base_fdn_modify($lac_fdn,$base_fdn);
	my $attr_create = "rac"." "."1";
	my ($status_create,$rev_create) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr_create);
	my ($status,$rev_id) = 	proxy_mo_set_decision("CSCLI",$base_fdn,$attr) if $status_create;
	log_registry("It seems no RoutingArea has been get created to set attributes....") if not ($status_create and $rev_create == 7);
	return "0" if not ($status_create and $rev_create == 7);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
	test_passed($test_slogan) if ($status and ($rev_id == 7));
	test_failed($test_slogan) if (!($status) or ($rev_id != 7));
  }
  else
  {
        log_registry("It seems no Location Area exist created by $mo_proxy_cms , please run the TC 4.4.2.2.1 once");
        test_failed($test_slogan);
  }
}

sub FUT007  # 4.4.2.2.6
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.2.6; Set Proxy MO - Set   rncServiceArea attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info"; 
  log_registry("$tc_info");
  my $lac_fdn;
  my ($base_fdn,$attr) = get_fdn("ServiceArea","set");
  my ($count,@la_FDN) = get_CMS_mo("LocationArea",$mo_proxy_cms);
  if($count)
  {
        foreach(@la_FDN) {
                $lac_fdn = $_ if ($_ =~ /MeContext=/); }
        log_registry("It seems no Proxy Location Area exist created by $mo_proxy_cms , please run the 4.4.2.2.1 once") if not $lac_fdn;
        test_failed($test_slogan) if not $lac_fdn;
        return "0" if not $lac_fdn;
	$base_fdn = base_fdn_modify($lac_fdn,$base_fdn);
        my $attr_create = "sac"." "."1";
        my ($status_create,$rev_create) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr_create);
        my ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$base_fdn,$attr) if ($status_create and $rev_create == 7);
        log_registry("It seems no ServiceArea has been get created to set attributes....") if not ($status_create and $rev_create == 7);
	return "0" if not ($status_create and $rev_create == 7);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
	test_passed($test_slogan) if ($status and ($rev_id == 7));
	test_failed($test_slogan) if (!($status) or ($rev_id != 7));
  }
  else
  {
        log_registry("It seems no Service Area exist created by $mo_proxy_cms , please run the TC 4.4.2.2.1 once");
        test_failed($test_slogan);
  }
}

sub FUT008  # 4.4.2.2.9 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.2.9; Set Proxy MO - Set   rncExternalUtranCell attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($base_fdn,$attr) = get_fdn("ExternalUtranCell","set");
  my ($count,@EUC_FDN) = get_CMS_mo("ExternalUtranCell",$mo_proxy_cms);
  if($count)
  {
	my ($status,$rev_id) = 	proxy_mo_set_decision("CSCLI",$EUC_FDN[0],$attr,"NW");
	test_passed($test_slogan) if ($status and ($rev_id == 7));
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
	test_failed($test_slogan) if (!($status) or ($rev_id != 7));
  }
  else
  {
        log_registry("It seems no ExternalUtranCell exist created by $mo_proxy_cms ..... ");
        test_failed($test_slogan);
  }
}

sub FUT009  # 4.4.3.2.1 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.1; Delete   - Delete   rncLocationArea from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $lac_fdn;
  my ($count,@la_FDN) = get_CMS_mo("LocationArea",$mo_proxy_cms);
  if($count)
  {
        foreach(@la_FDN)
        {
                $lac_fdn = $_ if ($_ =~ /MeContext=/);
        }
        log_registry("It seems no Proxy Location Area exist created by $mo_proxy_cms ........") if not $lac_fdn;
        test_failed($test_slogan) if not $lac_fdn;
        return "0" if not $lac_fdn;
	proxy_mo_delete_decision($test_slogan,"CSCLI",$lac_fdn);
  }
  else
  {
        log_registry("It seems no Location Area exist created by $mo_proxy_cms ......... ");
        test_failed($test_slogan);
  }
}

sub FUT010  # 4.4.3.2.2 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.2; Delete   - Delete   rncRoutingArea from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rac_fdn;
  my ($count,@ra_FDN) = get_CMS_mo("RoutingArea",$mo_proxy_cms);
  if($count)
  {
        foreach(@ra_FDN)
        {
                $rac_fdn = $_ if ($_ =~ /MeContext=/);
        }
        log_registry("It seems no Proxy Routing Area exist created by $mo_proxy_cms ..........") if not $rac_fdn;
        test_failed($test_slogan) if not $rac_fdn;
        return "0" if not $rac_fdn;
	proxy_mo_delete_decision($test_slogan,"CSCLI",$rac_fdn);
  }
  else
  {
        log_registry("It seems no Routing Area exist created by $mo_proxy_cms .........");
        test_failed($test_slogan);
  }
}

sub FUT011  # 4.4.3.2.3 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.3; Delete   - Delete   rncServiceArea from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $sac_fdn;
  my ($count,@sa_FDN) = get_CMS_mo("ServiceArea",$mo_proxy_cms);
  if($count)
  {
        foreach(@sa_FDN)
        {
                $sac_fdn = $_ if ($_ =~ /MeContext=/);
        }
        log_registry("It seems no Proxy Service Area exist created by $mo_proxy_cms .........") if not $sac_fdn;
        test_failed($test_slogan) if not $sac_fdn;
        return "0" if not $sac_fdn;
	proxy_mo_delete_decision($test_slogan,"CSCLI",$sac_fdn);
  }
  else
  {
        log_registry("It seems no Service Area exist created by $mo_proxy_cms ........");
        test_failed($test_slogan);
  }
}

sub FUT012  # 4.4.3.2.7 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.7; Delete   - Delete   ExternalUtranCell from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@EUC_FDN) = get_CMS_mo("ExternalUtranCell",$mo_proxy_cms);
  if($count)
  {
	proxy_mo_delete_decision($test_slogan,"CSCLI", $EUC_FDN[0]);
  }
  else
  {
        log_registry("It seems no ExternalUtranCell exist created by $mo_proxy_cms ............");
        test_failed($test_slogan);
  }
}

sub FUT013 # 4.4.1.2.21 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.21;Create - Create proxy ExternalUtranCell when no master exists through netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
 
  my ($base_fdn,$attr) = get_fdn("ExternalUtranCell","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
	my $IurLink = pick_a_mo($rnc_name,IurLink);
	log_registry("It seems no IurLink has been selected for the RNC => $rnc_name") if not $IurLink;
	test_failed($test_slogan) if not $IurLink;
	return "0" if not $IurLink;
	$base_fdn = base_fdn_modify($IurLink,$base_fdn);
	my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$attr);
	test_passed($test_slogan) if ($status and $rev_id == 7);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
	test_failed($test_slogan) if not ($status and $rev_id == 7);
  }
  else
  {
	log_registry("It seems no synched RNC found....");
	test_failed($test_slogan);
  }
}


sub FUT014  # 4.4.1.2.15
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.15; Create   - Create proxy rncLocationArea, when no master exists through netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($base_fdn,$attr) = get_fdn("LocationArea","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
        my @list_LAs = PICK_NEW_LAS(1);
        my $lac_val = $list_LAs[0];
	$base_fdn = base_fdn_modify($rnc_name,$base_fdn);
        $attr = "$attr"." "."lac"." "."$lac_val";
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$attr,"no wait");
        if($status and $rev_id == 7)
        {
                my $sac_fdn = "$base_fdn".","."ServiceArea="."$mo_proxy_cms"."_TEMP_1";
                my ($sac_status,$rev_sac) = proxy_mo_create_decision("CLI",$sac_fdn,"sac 1");
		test_failed($test_slogan) if not $sac_status;
                return "0" if not $sac_status;
                my $time = sleep_start_time();
                my $cell = create_UtranCell($rnc_name,"lac $lac_val sac 1");
		log_registry("It seems problem in creation of UtranCell ...") if not $cell;
		test_failed($test_slogan) if not $cell;
		return "0" if not $cell;
                long_sleep_found($time);
                my $review_cache_log = cache_file();
                my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
                get_mo_attr($base_fdn) if $rev_log;
                my $master_mo = get_master_for_proxy($base_fdn);
                log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
                log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
		log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
                test_passed($test_slogan) if ($rev_d == 1);
                test_failed($test_slogan) if ($rev_d != 1);
###############################  Clean up Process ##########################################
                log_registry("CLEANUP: Deleting Cell: $cell");
                $time = sleep_start_time();
                my $clean_issue = delete_mo_CS(mo => $cell);
		log_registry("Warning: Problem in deletion of MO $cell ") if $clean_issue;	
                $status = does_mo_exist_CLI( base => CLI, mo => $base_fdn);
                log_registry("Specified MO => $base_fdn exist...") if ($status eq "YES");
                log_registry("Proxy also get deleted with the UtranCell.....") if not $status;
                $clean_issue = delete_mo_CS(mo => $master_mo);
		log_registry("Warning: Problem in deletion of Master MO $master_mo") if $clean_issue;
        }
	else
	{
		log_registry("It seems mo is not in Redundant state,while it should be");
		test_failed($test_slogan); 
	}
  }
  else
  {
        log_registry("It seems no synched RNC found....");
        test_failed($test_slogan);
  }
}

sub FUT015  # 4.4.1.2.17 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.17; Create   - Create proxy rncRoutingArea when no master exists through netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($lac_fdn,$attr_lac) = get_fdn("LocationArea","create");
  my ($base_fdn,$attr) = get_fdn("RoutingArea","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
        my @list_LAs = PICK_NEW_LAS(1);
        my $lac_val = $list_LAs[0];
	$lac_fdn = "$lac_fdn"."_TEMP_1";
	$lac_fdn = base_fdn_modify($rnc_name,$lac_fdn);
        $attr_lac = "$attr_lac"." "."lac"." "."$lac_val";
        my ($lac_status,$rev_lac) = proxy_mo_create_decision("CLI",$lac_fdn,$attr_lac,"no wait");
	test_failed($test_slogan) if not $lac_status;
        return "0" if not $lac_status;
	$base_fdn = base_fdn_modify("$lac_fdn","$base_fdn");
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$attr);
        if($status and $rev_id == 7)
        {
                my $sac_fdn = "$lac_fdn".","."ServiceArea="."$mo_proxy_cms"."_TEMP_2";
                my ($sac_status,$rev_sac) = proxy_mo_create_decision("CLI",$sac_fdn,"sac 1","no wait");
		test_failed($test_slogan) if not $sac_status;
                return "0" if not $sac_status;
                my $time = sleep_start_time();
                my $cell = create_UtranCell($rnc_name,"lac $lac_val sac 1 $attr ");
		log_registry("It seems there is a problem in creation of UtranCell..") if not $cell;
		test_failed($test_slogan) if not $cell;
		return "0" if not $cell;
                long_sleep_found($time);
                my $review_cache_log = cache_file();
                my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
                get_mo_attr($base_fdn) if $rev_log;
                my $master_mo = get_master_for_proxy($base_fdn);
                log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
                log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
		log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
                test_passed($test_slogan) if ($rev_d == 1);
                test_failed($test_slogan) if ($rev_d != 1);
###############################  Clean up Process ##########################################
                log_registry("CLEANUP: Deleting Cell: $cell");
		my $master_la = get_master_for_proxy($lac_fdn);
                $time = sleep_start_time();
                my $clean_issue = delete_mo_CS(mo => $cell);
		log_registry("Warning: Problem in deletion of MO $cell ") if $clean_issue;
                $status = does_mo_exist_CLI( base => CLI, mo => $base_fdn);
                log_registry("Specified MO => $base_fdn exist...") if ($status eq "YES");
                log_registry("Proxy also get deleted with the UtranCell.....") if not $status;
                $clean_issue = delete_mo_CS(mo => $master_la) if $master_la;
		log_registry("Warning: Problem in deletion of MO $master_la") if $clean_issue;
        }
	else
	{
		log_registry("It seems mo is not in Redundant state,while it should be");
		test_failed($test_slogan); 
	}
  }
  else
  {
        log_registry("It seems no synched RNC found....");
        test_failed($test_slogan);
  }
}

sub FUT016  # 4.4.1.2.19 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.19; Create   - Create proxy rncServiceArea when no master exists through netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($lac_fdn,$attr_lac) = get_fdn("LocationArea","create");
  my ($base_fdn,$attr) = get_fdn("ServiceArea","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
        my @list_LAs = PICK_NEW_LAS(1);
        my $lac_val = $list_LAs[0];
	$lac_fdn = "$lac_fdn"."_TEMP_2";
	$lac_fdn = base_fdn_modify("$rnc_name","$lac_fdn");
        $attr_lac = "$attr_lac"." "."lac"." "."$lac_val";
        my ($lac_status,$rev_lac) = proxy_mo_create_decision("CLI",$lac_fdn,$attr_lac,"no wait");
	test_failed($test_slogan) if not $lac_status;
        return "0" if not $lac_status;
	$base_fdn = base_fdn_modify($lac_fdn,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$attr);
        if($status and $rev_id == 7)
        {
                my $time = sleep_start_time();
                my $cell = create_UtranCell($rnc_name,"lac $lac_val $attr ");
		log_registry("It seems problem in creation of UtranCell..") if not $cell;
		test_failed($test_slogan) if not $cell;
		return "0" if not $cell;
                long_sleep_found($time);
                my $review_cache_log = cache_file();
                my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
                get_mo_attr($base_fdn) if $rev_log;
                my $master_mo = get_master_for_proxy($base_fdn);
                log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
                log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
		log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
                test_passed($test_slogan) if ($rev_d == 1);
                test_failed($test_slogan) if ($rev_d != 1);
###############################  Clean up Process ##########################################
		my $master_la = get_master_for_proxy($lac_fdn);
                log_registry("CLEANUP: Deleting Cell: $cell");
                $time = sleep_start_time();
                my $clean_issue = delete_mo_CS(mo => $cell);
		log_registry("Warning: Problem in deletion of MO $cell ") if $clean_issue;
                $status = does_mo_exist_CLI( base => CLI, mo => $base_fdn);
                log_registry("Specified MO => $base_fdn exist...") if ($status eq "YES");
                log_registry("Proxy also get deleted with the UtranCell.....") if not $status;
                $clean_issue = delete_mo_CS(mo => $master_la) if $master_la;
		log_registry("Warning: Problem in deletion of MO $master_la") if $clean_issue;
        }
	else
	{
		log_registry("It seems mo is not in Redundant state,while it should be");
		test_failed($test_slogan); 
	}
  }
  else
  {
        log_registry("It seems no SYNCHED RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT017  # 4.4.3.2.9 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.9; Delete   - Delete   rncLocationArea through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $lac_fdn;
  my ($count,@la_FDN) = get_CMS_mo("LocationArea",$mo_proxy_cms);
  if($count)
  {
        foreach(@la_FDN)
        {
                $lac_fdn = $_ if ($_ =~ /MeContext=/);
        }
        log_registry("It seems no Proxy LocationArea exist created by $mo_proxy_cms , please run the TC 1.5.11DNSA once") if not $lac_fdn;
        test_failed($test_slogan) if not $lac_fdn;
        return "0" if not $lac_fdn;
	proxy_mo_delete_decision($test_slogan,"CLI",$lac_fdn);
  }
  else
  {
        log_registry("It seems no Location Area exist created by $mo_proxy_cms , please run the TC 1.5.11DNSA once");
        test_failed($test_slogan);
  }
}

sub FUT018  # 4.4.3.2.10 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.10 Delete   - Delete   rncRoutingArea through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rac_fdn;

  my ($count,@ra_FDN) = get_CMS_mo("RoutingArea",$mo_proxy_cms);
  if($count)
  {
        foreach(@ra_FDN)
        {
                $rac_fdn = $_ if ($_ =~ /MeContext=/);
        }
        log_registry("It seems no Proxy RoutingArea exist created by $mo_proxy_cms , please run the TC 1.5.11DNSA once") if not $rac_fdn;
        test_failed($test_slogan) if not $rac_fdn;
        return "0" if not $rac_fdn;
	proxy_mo_delete_decision($test_slogan,"CLI",$rac_fdn);
  }
  else
  {
        log_registry("It seems no Routing Area exist created by $mo_proxy_cms , please run the TC 1.5.11DNSA once");
        test_failed($test_slogan);
  }
}

sub FUT019  # 4.4.3.2.11 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.11; Delete   - Delete   rncServiceArea through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
  my ($lac_fdn,$attr_lac) = get_fdn("LocationArea","create");
  my ($sac_fdn,$attr_sac) = get_fdn("ServiceArea","delete");
  my ($rac_fdn,$attr_rac) = get_fdn("RoutingArea","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
        my @list_LAs = PICK_NEW_LAS(1);
        my $lac_val = $list_LAs[0];
	$lac_fdn = base_fdn_modify("$rnc_name","$lac_fdn");
        $attr_lac = "$attr_lac"." "."lac"." "."$lac_val";
        my ($lac_status,$rev_lac) = proxy_mo_create_decision("CLI",$lac_fdn,$attr_lac,"no wait");
	test_failed($test_slogan) if not $lac_status;
	return "0" if not $lac_status;
	$sac_fdn = base_fdn_modify("$lac_fdn","$sac_fdn");
	my ($sac_status,$rev_sac) = proxy_mo_create_decision("CLI",$sac_fdn,$attr_sac,"no wait") if $lac_status;
	test_failed($test_slogan) if not $sac_status;
	return "0" if not $sac_status;
	$rac_fdn = base_fdn_modify($lac_fdn,$rac_fdn);
	my ($rac_status,$rev_rac) = proxy_mo_create_decision("CLI",$rac_fdn,$attr_rac,"no wait") if $lac_status;
	test_failed($test_slogan) if not $rac_status;
	return "0" if not $rac_status;
  	proxy_mo_delete_decision($test_slogan,"CLI",$sac_fdn);	
   }
   else
   {
	log_registry("It seems no sync RNC found.....");
	test_failed($test_slogan);
   }
}

sub FUT020  # 4.4.3.2.15 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.15; Delete   - Delete   ExternalUtranCell through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@EUC_FDN) = get_CMS_mo("ExternalUtranCell",$mo_proxy_cms);
  if($count)
  {
	proxy_mo_delete_decision($test_slogan,"CLI",$EUC_FDN[0]);
  }
  else
  {
        log_registry("It seems no ExternalUtranCell exist created by $mo_proxy_cms .............");
        test_failed($test_slogan);
  }
}

sub FUT021  #4.4.1.2.7 and 4.4.1.2.43
{
  my $test_slogan = $_[0];
  my $tc_id,$tc_info;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.1\.2\.7/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.1\.2\.43/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.7; Create proxy MbmsServiceArea when no master exists from an application" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.43 ; Create   - Create   MbmsServiceArea attribute sac to a value that already has a master named to it" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($base_fdn,$attr) = get_fdn("MbmsServiceArea","create");
  my $rnc_name = pick_a_ne(Mbms);
  $rnc_name = remove_rdn($rnc_name);
  log_registry("$rnc_name");

  if($rnc_name)
  {
	my $M_MSA;
	if($tc_id == 2) {
		my ($count,@MSA) = get_CMS_mo("MbmsServiceArea","$rnc_name");
		log_registry("It seems RNC does not have any pre-existing MbmsServiceArea ..") if not $count;
		test_failed($test_slogan) if not $count;
		return "0" if not $count;
		foreach(@MSA) {
			my $master = get_master_for_proxy($_);
			$M_MSA = $master if $master;
			last if $M_MSA; }
		log_registry("It seems selected proxy MbmsServiceArea is not in correct plmn ..") if not $M_MSA;
		test_failed($test_slogan) if not $M_MSA;
		return "0" if not $M_MSA;
		$M_MSA =~ s/\n+//g;
		$M_MSA =~ s/MbmsServiceArea\=.+//g;
		$M_MSA = "$M_MSA"."MbmsServiceArea=65500";
		my $result = mo_create_decision("0",$M_MSA,"sac 60000");
		$result = master_for_proxy_handle("0",$M_MSA,"sac 60000") if ($result and $result eq "KO");
		log_registry("Problem in creation of master MbmsServiceArea ..") if not $result;
		test_failed($test_slogan) if not $result;
		return "0" if not $result; }
        my $Mbms = pick_a_mo($rnc_name,Mbms);
        log_registry("It seems no Mbms has been selected for the RNC => $rnc_name") if not $Mbms;
	test_failed($test_slogan) if not $Mbms;
        return "0" if not $Mbms;
	$base_fdn = base_fdn_modify($Mbms,$base_fdn);
	$base_fdn =~ s/$mo_proxy_cms/65500/g if ($tc_id == 2);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr,"no wait");
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
        my @list_LAs = PICK_NEW_LAS(1);
        my $lac_val = $list_LAs[0];
	my ($lac_fdn,$attr_lac) = get_fdn("LocationArea","create");
	$lac_fdn = "$lac_fdn"."_TEMP_1";
	$lac_fdn = base_fdn_modify("$rnc_name",$lac_fdn);
        $attr_lac = "$attr_lac"." "."lac"." "."$lac_val";
        my ($lac_status,$rev_lac) = proxy_mo_create_decision("CSCLI",$lac_fdn,$attr_lac,"no wait");
	test_failed($test_slogan) if not $lac_status;
	return "0" if not $lac_status;
        my $sac_fdn = "$lac_fdn".","."ServiceArea="."$mo_proxy_cms"."_TEMP_1";
        my ($sac_status,$rev_sac) = proxy_mo_create_decision("CSCLI",$sac_fdn,"sac 65500","no wait");
	test_failed($test_slogan) if not $sac_status;
        return "0" if not $sac_status;
        my $time = sleep_start_time();
        my $cell = create_UtranCell($rnc_name,"lac $lac_val sac 65500");
        log_registry("It seems problem in creation of UtranCell..") if not $cell;
        test_failed($test_slogan) if not $cell;
        return "0" if not $cell;
#        long_sleep_found($time); # eeitjn just to see can we speed up...
 	my $MbmsCch = "$cell".","."MbmsCch=$mo_proxy_cms";
	#my $attr_MbmsCch = "nonPlMbmsSaRef"." "."$base_fdn";
        my $attr_MbmsCch = "nonPlMbmsSac"." "."65500";
	log_registry("Creating MbmsCch MO $MbmsCch under UtranCell and attributes for MO will be $attr_MbmsCch");
	log_registry("Creation process of MbmsCch MO can be seen in $cs_log_file by current date and time...");
	$time = sleep_start_time();
	my $MbmsCch_result = create_mo_CS(mo => $MbmsCch,attributes => $attr_MbmsCch);
       	log_registry("Problem in creation of MbmsCch mo ...") if $MbmsCch_result;
 	test_failed($test_slogan) if $MbmsCch_result;
	return "0" if $MbmsCch_result;
#	log_registry("Discussion pending with Dev team why CC is not getting nudge automatically?");
#	my $force_nudge = forceCC($MbmsCch);
#	long_sleep_found($force_nudge) if $force_nudge;
	long_sleep_found($time);# Discussion pending with Dev team
        my $review_cache_log = cache_file();
        my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
        get_mo_attr($base_fdn) if $rev_log;
        my $master_mo = get_master_for_proxy($base_fdn);
        log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
        log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
	log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
        test_failed($test_slogan) if ($rev_d != 1);
        test_passed($test_slogan) if ($rev_d == 1 and $tc_id == 1);
	if($tc_id == 2)
	{
		my $flag = 0;
		$flag = 1 if (!($master_mo) or $master_mo !~ /SAC\_/);
		$master_mo =~ s/\n+//g;
		log_registry("Newly create master MbmsServiceArea for proxy $base_fdn is: \n $master_mo") if $master_mo;
		log_registry("Newly created master for proxy $base_fdn is not get modified itself like SAC_") if $flag;
		test_failed($test_slogan) if $flag;
		test_passed($test_slogan) if not $flag;
	##################### Clean up for second TC ###############################
		my $clean_issue,$mo;
		my ($lac_count,@lac) = get_CMS_mo("LocationArea",$mo_proxy_cms);
        	$mo = join(" ",$MbmsCch,$cell,$master_mo,$M_MSA,@lac);
        	my @mo = split(" ",$mo);
        	foreach(@mo) {
	                log_registry("Clean up: Deleting MO $_ ");
       	         	$clean_issue = delete_mo_CS( mo => $_);
                	log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
	}

  }
  else
  {
        log_registry("It seems no synched RNC found....");
        test_failed($test_slogan);
  }
}

sub FUT022  # 4.4.2.2.14 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.2.14; Set Proxy MO - Set Proxy MO MbmsServiceArea attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $MSA_FDN;
  my ($base_fdn,$attr) = get_fdn("MbmsServiceArea","set");
  my ($count,@mo_fdn) = get_CMS_mo("MbmsServiceArea",$mo_proxy_cms);
  if($count)
  {
	foreach(@mo_fdn)
	{
		$MSA_FDN = $_ if ($_ =~ /MeContext=/); 
	}
	log_registry("It seems no Proxy MbmsServiceArea exist created by proxy.pl .........") if not $MSA_FDN;
	test_failed(test_slogan) if not $MSA_FDN;
	return "0" if not $MSA_FDN;
        my ($status,$rev_id) = 	proxy_mo_set_decision("CSCLI",$MSA_FDN,$attr);
	log_registry("It seems mo is not in Consistent state,while it should be") if (!($status) or $rev_id != 1);
	test_passed($test_slogan) if ($status and ($rev_id == 1));
	test_failed($test_slogan) if (!($status) or ($rev_id != 1));
##############################Clean up delete MbmsServiceArea/MbmsCch/UtranCell/LA #########################################
	log_registry("============================ CLEAN UP =======================================");
	log_registry("Deleting MbmsCch..............");
	my ($count_MbmsCch,@MbmsCch_fdn) = get_CMS_mo("MbmsCch",$mo_proxy_cms);
	foreach(@MbmsCch_fdn)
	{
		log_registry("Deleting MO: $_ ");
		my $clean_issue = delete_mo_CS(mo => $_);
		log_registry("Warning: Problem in deletion of MO $_ ") if $clean_issue;
	}	
	log_registry("Deleting MbmsServiceArea...............");
	foreach(@mo_fdn)
	{
		log_registry("Deleting MO: $_ ");
	        my $clean_issue = delete_mo_CS(mo => $_);
		log_registry("Warning: Problem in deletion of MO $_ ") if $clean_issue;
	}
        log_registry("Deleting Cell..........");
	my ($count_cell,@cell) = get_CMS_mo("UtranCell",$mo_proxy_cms);
	foreach(@cell)
	{
		log_registry("Deleting MO: $_ ");
		my $clean_issue = delete_mo_CS(mo => $_);
		log_registry("Warning: Problem in deletion of MO $_ ") if $clean_issue;
	}
	log_registry("Deleteig LocationArea.............");
        my ($count_lac,@la_fdn) = get_CMS_mo("LocationArea",$mo_proxy_cms);
        foreach(@la_fdn)
	{
		log_registry("Deleting MO: $_ ");
		my $clean_issue = delete_mo_CS(mo => $_);
		log_registry("Warning: Problem in deletion of MO $_ ") if $clean_issue;
	}
  }
  else
  {
        log_registry("It seems no MbmsServiceArea exist created by $mo_proxy_cms ...........");
        test_failed($test_slogan);
  }
}

sub FUT023  # 4.4.3.2.4 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.4; Delete   - Delete   MbmsServiceArea from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($base_fdn,$attr) = get_fdn("MbmsServiceArea","delete");
#  my $rnc_name = pick_a_ne(RncFunction);

  my $rnc_name = pick_a_ne(Mbms);
  $rnc_name = remove_rdn($rnc_name);
  log_registry("$rnc_name");

  if($rnc_name)
  {
        my $Mbms = pick_a_mo($rnc_name,Mbms);
        log_registry("It seems no Mbms has been selected for the RNC => $rnc_name") if not $Mbms;
        test_failed($test_slogan) if not $Mbms;
        return "0" if not $Mbms;
	$base_fdn = base_fdn_modify($Mbms,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
	test_failed($test_slogan) if not ($status and $rev_id == 7);
        return "0" if not ($status and $rev_id == 7);
        proxy_mo_delete_decision($test_slogan,"CSCLI", $base_fdn);
  }
  else
  {
        log_registry("It seems no SYNC RNC found......."); 
        test_failed($test_slogan);
  }
}

sub FUT024  # 4.4.1.2.28 and 4.4.2.2.15
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.1\.2\.28/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.2\.2\.15/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.28; Create MbmsServiceArea when no master exists through the netsim" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.2.2.15 ; Set Proxy MO - Set Proxy MO MbmsServiceArea attribute sac value" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($base_fdn,$attr) = get_fdn("MbmsServiceArea","create");
#  my $rnc_name = pick_a_ne(RncFunction);

  my $rnc_name = pick_a_ne(Mbms);
  $rnc_name = remove_rdn($rnc_name);
  log_registry("$rnc_name");

  if($rnc_name)
  {
        my $Mbms = pick_a_mo($rnc_name,Mbms);
        log_registry("It seems no Mbms has been selected for the RNC => $rnc_name") if not $Mbms;
        test_failed($test_slogan) if not $Mbms;
        return "0" if not $Mbms;
	$base_fdn = base_fdn_modify("$Mbms","$base_fdn");
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$attr,"no wait");
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
	test_failed($test_slogan) if not ($status and $rev_id == 7);
        return "0" if not ($status and $rev_id == 7);
        my @list_LAs = PICK_NEW_LAS(1);
        my $lac_val = $list_LAs[0];
        my ($lac_fdn,$attr_lac) = get_fdn("LocationArea","create");
	$lac_fdn = "$lac_fdn"."_TEMP_1";
	$lac_fdn = base_fdn_modify("$rnc_name",$lac_fdn);
        $attr_lac = "$attr_lac"." "."lac"." "."$lac_val";
        my ($lac_status,$rev_lac) = proxy_mo_create_decision("CLI",$lac_fdn,$attr_lac,"no wait");
	test_failed($test_slogan) if not $lac_status;
        return "0" if not $lac_status;
        my $sac_fdn = "$lac_fdn".","."ServiceArea="."$mo_proxy_cms"."_TEMP_1";
        my ($sac_status,$rev_sac) = proxy_mo_create_decision("CLI",$sac_fdn,"sac 1","no wait");
	test_failed($test_slogan) if not $sac_status;
        return "0" if not $sac_status;
        my $time = sleep_start_time();
        my $cell = create_UtranCell($rnc_name,"lac $lac_val sac 1");
        log_registry("It seems problem in creation of UtranCell..") if not $cell;
        test_failed($test_slogan) if not $cell;
        return "0" if not $cell;

#        long_sleep_found($time);
        my $MbmsCch = "$cell".","."MbmsCch=$mo_proxy_cms";
        my $attr_MbmsCch = "nonPlMbmsSaRef"." "."$base_fdn";
        $time = sleep_start_time();
        my $MbmsCch_result = create_mo_CS(mo => $MbmsCch,attributes => $attr_MbmsCch);
	log_registry("Problem in creation of MbmsCch mo ...") if $MbmsCch_result;
        test_failed($test_slogan) if $MbmsCch_result;
        return "0" if $MbmsCch_result;
#        log_registry("Discussion pending with Dev team why CC is not getting nudge automatically?");
#        my $force_nudge = forceCC($MbmsCch);
#        long_sleep_found($force_nudge) if $force_nudge;

        long_sleep_found($time);# Discussion pending with Dev team
        my $review_cache_log = cache_file();
        my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
        get_mo_attr($base_fdn) if $rev_log;
        my $master_mo = get_master_for_proxy($base_fdn);
        log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
        log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
	log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);	
        test_failed($test_slogan) if ($rev_d != 1);
        test_passed($test_slogan) if ($tc_id == 1 and $rev_d == 1);
	my $new_master;
	if($tc_id == 2) {
		my ($mbms_fdn,$mod_attrs) = get_fdn("SacMbmsServiceArea","set");
		($status,$rev_id) = proxy_mo_set_decision("CSCLI","$base_fdn","$mod_attrs");
		log_registry("Problem in setting attribuite..") if not $status;
		log_registry("It seems proxy MbmsServiceArea is not consistent  after modifying attribute..") if ($status and $rev_id != 1);
		test_failed($test_slogan) if (!($status) or $rev_id != 1);
		if($status and $rev_id == 1) {
		        $new_master = get_master_for_proxy($base_fdn);
        		log_registry("New Master Mo for the Given Proxy is: \n $new_master") if $new_master;
        		log_registry("There is no new Master Mo created for the given proxy : $base_fdn") if (!($new_master) or $new_master =~ /$master_mo$/);
			test_failed($test_slogan) if (!($new_master) or $new_master =~ /$master_mo$/);
			test_passed($test_slogan) if ($new_master and $new_master !~ /$master_mo$/); } }

##############################Clean up delete MbmsServiceArea/MbmsCch/UtranCell/LA #########################################
        log_registry("============================ CLEAN UP =======================================");
        log_registry("Deleting MbmsCch..............");
        my ($count_MbmsCch,@MbmsCch_fdn) = get_CMS_mo("MbmsCch",$mo_proxy_cms);
        foreach(@MbmsCch_fdn) {
		log_registry("Deleting MO: $_ ");
                my $clean_issue = delete_mo_CS(mo => $_);
		log_registry("Warning: Problem in deletion of MO $_ ") if $clean_issue; }
        log_registry("Deleting MbmsServiceArea...............");
	log_registry("Deleting MO: $master_mo ");
        my $clean_issue = delete_mo_CS(mo => $master_mo); 
	log_registry("Warning: Problem in deletion of MO $master_mo ") if $clean_issue;
	log_registry("Deleting MO: $new_master") if ($tc_id == 2);
        $clean_issue = delete_mo_CS(mo => $new_master) if($tc_id == 2);
	log_registry("Warning: Problem in deletion of MO $new_master") if ($tc_id == 2 and $clean_issue);
        log_registry("Deleting Cell..........");
        my ($count_cell,@cell) = get_CMS_mo("UtranCell",$mo_proxy_cms);
        foreach(@cell) {
		log_registry("Deleting MO: $_ ");
                my $clean_issue = delete_mo_CS(mo => $_);
		log_registry("Warning: Problem in deletion of MO $_ ") if $clean_issue; }
        log_registry("Deleteig LocationArea.............");
        my ($count_lac,@la_fdn) = get_CMS_mo("LocationArea",$mo_proxy_cms);
        foreach(@la_fdn) {
		log_registry("Deleting MO: $_ ");
                my $clean_issue = delete_mo_CS(mo => $_);
		log_registry("Warning: Problem in deletion of MO $_ ") if $clean_issue; }
  }
  else
  {
        log_registry("It seems no synched RNC found....");
        test_failed($test_slogan);
  }
}

sub FUT025  # 4.4.3.2.12
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.12; Delete   - Delete   MbmsServiceArea through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($base_fdn,$attr) = get_fdn("MbmsServiceArea","delete");
#  my $rnc_name = pick_a_ne(RncFunction);

  my $rnc_name = pick_a_ne(Mbms);
  $rnc_name = remove_rdn($rnc_name);
  log_registry("$rnc_name");

  if($rnc_name)
  {
        my $Mbms = pick_a_mo($rnc_name,Mbms);
        log_registry("It seems no Mbms has been selected for the RNC => $rnc_name") if not $Mbms;
        test_failed($test_slogan) if not $Mbms;
        return "0" if not $Mbms;
	$base_fdn = base_fdn_modify($Mbms,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$attr);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
	test_failed($test_slogan) if not ($status and $rev_id == 7);
        return "0" if not ($status and $rev_id == 7);
        proxy_mo_delete_decision($test_slogan,"CLI", $base_fdn);
  }
  else
  {
        log_registry("It seems no SYNC RNC found.......");
        test_failed($test_slogan);
  }
}

sub FUT026  # 4.4.1.2.5
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.5; Create   - Create  ExternalGsmNetwork when no master exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($base_fdn,$attr) = get_fdn("ExternalGsmNetwork","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
	$base_fdn = base_fdn_modify($rnc_name,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	log_registry("It seems mo is not in Consistent state,while it should be") if (!($status) or $rev_id != 1);
	test_failed($test_slogan) if not ($status and $rev_id == 1);
        return "0" if not ($status and $rev_id == 1);
        my $master_mo = get_master_for_proxy($base_fdn);
        log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
        log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
	test_passed($test_slogan) if $master_mo;
	test_failed($test_slogan) if not $master_mo;
  }
  else
  {
        log_registry("It seems no SYNC RNC found.......");
        test_failed($test_slogan);
  }
}

sub FUT027  # 4.4.2.2.10 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.2.10; Set Proxy MO - Set Proxy MO ExternalGsmNetwork attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($base_fdn,$attr) = get_fdn("ExternalGsmNetwork","set");
  my ($count,@EGN_FDN) = get_CMS_mo("ExternalGsmNetwork",$mo_proxy_cms);
  if($count)
  {
        my ($status,$rev_id) =  proxy_mo_set_decision("CSCLI",$EGN_FDN[0],$attr);
        test_passed($test_slogan) if ($status and $rev_id);
        test_failed($test_slogan) if (!($status) or !($rev_id));
  }
  else
  {
        log_registry("It seems no ExternalGsmNetwork exist created by $mo_proxy_cms .......");
        test_failed($test_slogan);
  }
}

sub FUT028  # 4.4.3.2.6 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.6 ; Delete   - Delete   ExternalGsmNetwork from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@EGN_FDN) = get_CMS_mo("ExternalGsmNetwork",$mo_proxy_cms);
  if($count)
  {
        proxy_mo_delete_decision($test_slogan,"CSCLI", $EGN_FDN[0]);
  }
  else
  {
        log_registry("It seems no ExternalGsmNetwork exist created by $mo_proxy_cms ................");
        test_failed($test_slogan);
  }
########################################## CLEAN UP : Delete Master GsmPlmn MO #######################################
  log_registry("Clean UP: Deleting Master ExternalGsmPlmn MO created by ExternalGsmNetwork....");
  my ($count,@EGP_FDN) = get_CMS_mo("ExternalGsmPlmn",$mo_proxy_cms);
  my $time; 
  foreach(@EGP_FDN)
  {
  	$time = sleep_start_time();
	log_registry("Deleting MO: $_ ");
	my $clean_issue = delete_mo_CS(mo => $_);
	log_registry("Warning: Problem in deletion of MO $_ ") if $clean_issue;
  }
}

sub FUT029  #4.4.1.2.23
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.23; Create   - Create proxy ExternalGsmNetwork when no master exists through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($base_fdn,$attr) = get_fdn("ExternalGsmNetwork","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
	$base_fdn = base_fdn_modify($rnc_name,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$attr);
	log_registry("It seems mo is not in Consistent state,while it should be") if (!($status) or $rev_id != 1);
        test_failed($test_slogan) if not ($status and $rev_id == 1);
        return "0" if not ($status and $rev_id == 1);
        my $master_mo = get_master_for_proxy($base_fdn);
        log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
        log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
        test_passed($test_slogan) if $master_mo;
	test_failed($test_slogan) if not $master_mo;
  }
  else
  {
        log_registry("It seems no SYNC RNC found.......");
        test_failed($test_slogan);
  }
}

sub FUT030  # 4.4.3.2.14 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.14; Delete   - Delete   ExternalGsmNetwork through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@EGN_FDN) = get_CMS_mo("ExternalGsmNetwork",$mo_proxy_cms);
  if($count)
  {
        proxy_mo_delete_decision($test_slogan,"CLI", $EGN_FDN[0]);
  }
  else
  {
        log_registry("It seems no ExternalGsmNetwork exist created by $mo_proxy_cms .........");
        test_failed($test_slogan);
  }
########################################## CLEAN UP : Delete Master GsmPlmn MO #######################################
  log_registry("Clean UP: Deleting Master ExternalGsmPlmn MO created by ExternalGsmNetwork....");
  my ($count,@EGP_FDN) = get_CMS_mo("ExternalGsmPlmn",$mo_proxy_cms);
  my $time;
  foreach(@EGP_FDN)
  {
  	$time = sleep_start_time();
	log_registry("Deleting MO: $_ ");
        my $clean_issue = delete_mo_CS(mo => $_);
	log_registry("Warning: Problem in deletion of MO $_ ") if $clean_issue;
  }
}

sub FUT031  #4.4.1.2.6
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.6; Create   - Create   rncExternalGsmCell when no master exists from an application ";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($base_fdn,$attr) = get_fdn("ExternalGsmCell","create");
  my $rnc_name = pick_a_ne(RncFunction, ExternalGsmNetwork);
  if($rnc_name)
  {
	my $EGN = pick_a_mo($rnc_name,ExternalGsmNetwork);
	log_registry("It seems no ExternalGsmNetwork found for corresponding RNC.....") if not $EGN;
	test_failed($test_slogan) if not $EGN;
	return "0" if not $EGN;
	log_registry("Selected ExternalGsmNetwork is: $EGN");
	$base_fdn = base_fdn_modify($EGN,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
        test_failed($test_slogan) if not ($status and $rev_id == 7);
        return "0" if not ($status and $rev_id == 7);
        test_passed($test_slogan);
  }
  else
  {
        log_registry("It seems no SYNC RNC found.......");
        test_failed($test_slogan);
  }
}

sub FUT032  # 4.4.2.2.8 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.2.8; Set Proxy MO - Set   rncExternalGsmCell attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($base_fdn,$attr) = get_fdn("ExternalGsmCell","set");
  my ($count,@EGC_FDN) = get_CMS_mo("ExternalGsmCell",$mo_proxy_cms);
  if($count)
  {
        my ($status,$rev_id) =  proxy_mo_set_decision("CSCLI",$EGC_FDN[0],$attr);
        test_passed($test_slogan) if ($status and $rev_id);
        test_failed($test_slogan) if (!($status) or !($rev_id));
  }
  else
  {
        log_registry("It seems no ExternalGsmCell exist created by $mo_proxy_cms .............");
        test_failed($test_slogan);
  }
}

sub FUT033  # 4.4.3.2.5 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.5; Delete   - Delete   ExternalGsmCell from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@EGC_FDN) = get_CMS_mo("ExternalGsmCell",$mo_proxy_cms);
  if($count)
  {
        proxy_mo_delete_decision($test_slogan,"CSCLI", $EGC_FDN[0]);
  }
  else
  {
        log_registry("It seems no ExternalGsmCell exist created by $mo_proxy_cms ..............");
        test_failed($test_slogan);
  }
}

sub FUT034  #4.4.1.2.26
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.26; Create   - Create ExternalGsmCell when no master exists through the netsim ";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($base_fdn,$attr) = get_fdn("ExternalGsmCell","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
        my $EGN = pick_a_mo($rnc_name,ExternalGsmNetwork);
        log_registry("It seems no ExternalGsmNetwork found for corresponding RNC.....") if not $EGN;
        test_failed($test_slogan) if not $EGN;
        return "0" if not $EGN;
        log_registry("Selected ExternalGsmNetwork is: $EGN");
	$base_fdn = base_fdn_modify($EGN,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
        test_failed($test_slogan) if not ($status and $rev_id == 7);
        return "0" if not ($status and $rev_id == 7);
        test_passed($test_slogan); 
  }
  else
  {
        log_registry("It seems no SYNC RNC found.......");
        test_failed($test_slogan);
  }
}

sub FUT035  # 4.4.3.2.13
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.13; Delete   - Delete   ExternalGsmCell through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@EGC_FDN) = get_CMS_mo("ExternalGsmCell",$mo_proxy_cms);
  if($count)
  {
        proxy_mo_delete_decision($test_slogan,"CLI", $EGC_FDN[0]);
  }
  else
  {
        log_registry("It seems no ExternalGsmCell exist created by $mo_proxy_cms ........");
        test_failed($test_slogan);
  }
}

sub FUT036 # 4.4.1.2.32 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.32 ; Create   - Create  UtranNetwork when no master exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($base_fdn,$attr) = get_fdn("UtranNetwork","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
	$base_fdn = base_fdn_modify($rnc_name,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
        test_failed($test_slogan) if (!($status) or $rev_id != 7);
	return "0" if (!($status) or $rev_id != 7);
	my ($IurLink_fdn,$IurLink_attr) = get_fdn(IurLink,create);
	$IurLink_fdn = base_fdn_modify($rnc_name,$IurLink_fdn);
	$IurLink_attr = "$IurLink_attr"." "."$base_fdn";
	($status,$rev_id) = proxy_mo_create_decision("CSCLI",$IurLink_fdn,$IurLink_attr);
	log_registry("It seems mo is not in Consistent state,while it should be") if (!($status) or $rev_id != 1);
	test_failed($test_slogan) if not ($status and $rev_id == 1);
	return "0" if not ($status and $rev_id == 1);
####################################################################################################################
        # till 11.2.7 package this feature is not working correctly, it woul take care by 11.2.8 onwards
        #my $master_mo = get_master_for_proxy($base_fdn);
        #log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
        #log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
        #test_failed($test_slogan) if not $master_mo;
        #return "0" if not $master_mo;
####################################################################################################################
	my ($count_EUP,@EUP) = get_CMS_mo("ExternalUtranPlmn",$mo_proxy_cms);
	log_registry("It seems no master Mo has been created Yet for UtranNetwork MO....") if not $count_EUP;
	my $proxies_mo;
	if($count_EUP)
	{
		foreach(@EUP)
		{
			$proxies_mo = get_proxies_master($_);
			log_registry("Master MO for Proxy $base_fdn is: \n $_") if ($proxies_mo =~ /$base_fdn/);
		}
	}
  	my $review_cache_log = cache_file();
   	my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
	get_mo_attr($base_fdn) if $rev_log;
	log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_id != 1);
	test_passed($test_slogan) if ($rev_d == 1);
	test_failed($test_slogan) if ($rev_d != 1);
  }
  else
  {
        log_registry("It seems no synched RNC found....");
        test_failed($test_slogan);
  }
}

sub FUT037  # 4.4.3.2.19
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.19 ; Delete   - Delete   UtranNetwork and IurLink from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $flag = 1;
  my ($count_IurLink,@IurLink) = get_CMS_mo("IurLink",$mo_proxy_cms);
  if($count_IurLink) {
        $flag = proxy_mo_delete_decision("0","CSCLI", $IurLink[0]); }
  test_failed("$test_slogan") if not $flag;
  return "0" if not $flag;
  my ($count_UNK,@UNK) = get_CMS_mo("UtranNetwork",$mo_proxy_cms); 
  if($count_UNK) {
	$flag = proxy_mo_delete_decision("$test_slogan","CSCLI", $UNK[0]); }
  else {
        log_registry("It seems no UtranNetwork exist created by $mo_proxy_cms ........");
        test_failed($test_slogan); }
###################### CleanUp : deleting ExternalUtranPlmn created by UtranNetwork ###############################
  my ($count_EUP,@EUP) = get_CMS_mo("ExternalUtranPlmn",$mo_proxy_cms);
  if($count_EUP)
  {
	foreach(@EUP)
	{
	  log_registry("CLEANUP: Deleting ExternalUtranPlmn: $_");
	  delete_mo_CS(mo => $_);
	}
  }
}

sub FUT038 # 4.4.1.2.41
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.41 ; Create   - Create UtranNetwork  when no master exists through netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($base_fdn,$attr) = get_fdn("UtranNetwork","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
	$base_fdn = base_fdn_modify($rnc_name,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$attr);

        my $UtranNetworkMO = $base_fdn;

	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
        test_failed($test_slogan) if (!($status) or $rev_id != 7);
        return "0" if (!($status) or $rev_id != 7);
        my ($IurLink_fdn,$IurLink_attr) = get_fdn(IurLink,create);
	$IurLink_fdn = base_fdn_modify($rnc_name,$IurLink_fdn);
        $IurLink_attr = "$IurLink_attr"." "."$base_fdn";
        ($status,$rev_id) = proxy_mo_create_decision("CLI",$IurLink_fdn,$IurLink_attr);
	log_registry("It seems mo is not in Consistent state,while it should be") if (!($status) or $rev_id != 1);
        test_failed($test_slogan) if not ($status and $rev_id == 1);
        return "0" if not ($status and $rev_id == 1);
####################################################################################################################
	# till 11.2.7 package this feature is not working correctly, it woul take care by 11.2.8 onwards
        #my $master_mo = get_master_for_proxy($base_fdn);
        #log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
        #log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
        #test_failed($test_slogan) if not $master_mo;
        #return "0" if not $master_mo;
####################################################################################################################
        my $UNetMaster = get_master_for_proxy($UtranNetworkMO);
        log_registry("It seems $UNetMaster is master Mo for UtranNetwork MO.");
#	sleep(360) if not $UNetMaster;  # Patch by eeitjn in 13.2.9, may have to wait a bit longer 2 long sleeps .....

        my $review_cache_log = cache_file();
        my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
        get_mo_attr($base_fdn) if $rev_log;
	log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
        test_passed($test_slogan) if ($rev_d == 1);
        test_failed($test_slogan) if ($rev_d != 1);
#######################################CLEAN UP ######################################################################
	log_registry("CLEANUP: Deleting IurLink: $IurLink_fdn ; $UNetMaster");
	delete_mo_CS(mo => $IurLink_fdn);
 	delete_mo_CS(mo => $UNetMaster);
  }
  else
  {
        log_registry("It seems no synched RNC found....");
        test_failed($test_slogan);
  }
}

sub FUT039 # 4.4.1.2.33
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.33 - Create  UtranNetwork when master ExternalUtranPlmn exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($base_fdn,$attr) = get_fdn("UtranNetwork","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
	log_registry("Create first Master ExternalUtranPlmn MO....");

        my ($count_EUP,@EUP) = get_CMS_mo("ExternalUtranPlmn",$mo_proxy_cms);
	log_registry("$count_EUP,   @EUP ....");
        if ($count_EUP == 0 )
		{
		log_registry("It seems no master UtranNetwork exist"); #  Patch by eeitjn in 13.0.5, TC was failing due to previous TC failing and not cleaning up...

		my ($EUP_fdn,$EUP_attr) = get_fdn("ExternalUtranPlmn",create);
		my $EUP_result = "";
		$EUP_result = mo_create_decision("0",$EUP_fdn,$EUP_attr,"","wait for consistent");
  		$EUP_result = master_for_proxy_handle("0",$EUP_fdn,$EUP_attr,"","wait for consistent") if ($EUP_result and $EUP_result eq "KO");
		test_failed($test_slogan) if not $EUP_result;
		return "0" if not $EUP_result;
		}

	$base_fdn = base_fdn_modify($rnc_name,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
        test_failed($test_slogan) if (!($status) or $rev_id != 7);
        return "0" if (!($status) or $rev_id != 7);

#	sleep(120); # Patch by eeitjn in 13.0.5,  
#	my $proxies_mo = get_proxies_master($EUP_fdn);
#	if($proxies_mo =~ /$base_fdn/)
#	{
#		log_registry("Created Proxy MO $base_fdn has found its master $EUP_fdn");
#		log_registry("getProxiesForMaster result is: \n $proxies_mo");
#	}
#	else
#	{
#		test_failed($test_slogan);
#		return "0";
#	}
        my ($IurLink_fdn,$IurLink_attr) = get_fdn(IurLink,create);
	$IurLink_fdn = base_fdn_modify("$rnc_name",$IurLink_fdn);
        $IurLink_attr = "$IurLink_attr"." "."$base_fdn";
        ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$IurLink_fdn,$IurLink_attr);
	log_registry("It seems mo is not in Consistent state,while it should be") if not ($status and $rev_id == 1);
        test_failed($test_slogan) if not ($status and $rev_id == 1);
        return "0" if not ($status and $rev_id == 1);
        my $review_cache_log = cache_file();
        my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
        get_mo_attr($base_fdn) if $rev_log;
	log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
        test_passed($test_slogan) if ($rev_d == 1);
        test_failed($test_slogan) if ($rev_d != 1);
######################################### CLEAN UP ######################################################################
        log_registry("CLEANUP: Deleting IurLink: $IurLink_fdn");
        my $clean_issue = delete_mo_CS(mo => $IurLink_fdn);
	log_registry("Warning: Problem in deletion of MO $IurLink_fdn ") if $clean_issue;
	log_registry("CLEANUP: Deleting ExternalUtranPlmn: $EUP_fdn");
	$clean_issue = delete_mo_CS(mo => $EUP_fdn);
	log_registry("Warning: Problem in deletion of MO $EUP_fdn ") if $clean_issue;
  }
  else
  {
        log_registry("It seems no synched RNC found....");
        test_failed($test_slogan);
  }
}

sub FUT040 # 4.4.1.2.34
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.34 ; Create   - Create  UtranNetwork when master PLMN exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($base_fdn,$attr) = get_fdn("UtranNetwork","create");
  my $rnc_name = pick_a_ne(RncFunction);
  if($rnc_name)
  {
        log_registry("Create first Master Plmn MO....");
        my ($Plmn_fdn,$Plmn_attr) = get_fdn("Plmn",create);
        my $Plmn_result = "";
        $Plmn_result = mo_create_decision("0",$Plmn_fdn,$Plmn_attr,"","wait for consistent");
	$Plmn_result = master_for_proxy_handle("0",$Plmn_fdn,$Plmn_attr,"","wait for consistent") if($Plmn_result and $Plmn_result eq "KO");
        test_failed($test_slogan) if not $Plmn_result;
        return "0" if not $Plmn_result;
	$base_fdn = base_fdn_modify($rnc_name,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
        test_failed($test_slogan) if (!($status) or $rev_id != 7);
        return "0" if (!($status) or $rev_id != 7);
        my $proxies_mo = get_proxies_master($Plmn_fdn);
        if($proxies_mo =~ /$base_fdn/)
        {
                log_registry("Created Proxy MO $base_fdn has found its master $Plmn_fdn");
                log_registry("getProxiesForMaster result is: \n $proxies_mo");
        }
        else
        {
                test_failed($test_slogan);
                return "0";
        }
        my ($IurLink_fdn,$IurLink_attr) = get_fdn(IurLink,create);
	$IurLink_fdn = base_fdn_modify("$rnc_name",$IurLink_fdn);
        $IurLink_attr = "$IurLink_attr"." "."$base_fdn";
        ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$IurLink_fdn,$IurLink_attr);
	log_registry("It seems mo is not in Consistent state,while it should be") if not ($status and $rev_id == 1);
        test_failed($test_slogan) if not ($status and $rev_id == 1);
        return "0" if not ($status and $rev_id == 1);
	my $master_mo = get_master_for_proxy($base_fdn);
	log_registry("Master for Proxy $base_fdn is: $master_mo"); 
	test_failed($test_slogan) if not $master_mo;
	return "0" if not $master_mo;
	my ($count_EUP,@EUP) = get_CMS_mo("ExternalUtranPlmn",$mo_proxy_cms);
	my $flag = 0;
	if($count_EUP)
	{
	        foreach(@EUP)
       		{
			$proxies_mo = get_proxies_master($_);
               		log_registry("Proxies for Master $_ is: $proxies_mo") if ($proxies_mo =~ /\w+/);
			log_registry("No proxy exists for the Master $_") if not ($proxies_mo =~ /\w+/);
			$flag = 1 if ($proxies_mo =~ /$base_fdn/);
        	}
	}
	test_failed($test_slogan) if $flag;
	return "0" if $flag;
        my $review_cache_log = cache_file();
        my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
        get_mo_attr($base_fdn) if $rev_log;
        test_passed($test_slogan) if ($rev_d == 1);
	log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
        test_failed($test_slogan) if ($rev_d != 1);
######################################### CLEAN UP ######################################################################
        log_registry("CLEANUP: Deleting IurLink: $IurLink_fdn");
        delete_mo_CS(mo => $IurLink_fdn);
	foreach(@EUP)
	{
        	log_registry("CLEANUP: Deleting ExternalUtranPlmn: $_");
        	my $clean_issue = delete_mo_CS(mo => $_);
		log_registry("Warning: Problem in deletion of MO $_ ") if $clean_issue;
	}
	log_registry("CLEANUP: Deleting Plmn : $Plmn_fdn");
	my $clean_issue = delete_mo_CS(mo => $Plmn_fdn);
	log_registry("Warning: Problem in deletion of MO $Plmn_fdn ") if $clean_issue;
  }
  else
  {
        log_registry("It seems no synched RNC found....");
        test_failed($test_slogan);
  }
}


sub FUT041  # 4.4.2.2.11
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.2.11 ; Set Proxy MO - Set   IurLink attribute ";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($base_fdn,$attr) = get_fdn("IurLink","set");
  my ($count,@IurLink) = get_CMS_mo("IurLink",$mo_proxy_cms);
  if($count)
  {
        my ($status,$rev_id) =  proxy_mo_set_decision("CSCLI",$IurLink[0],$attr);
        test_passed($test_slogan) if ($status and $rev_id);
        test_failed($test_slogan) if (!($status) or !($rev_id));
  }
  else
  {
        log_registry("It seems no IurLink found created by $mo_proxy_cms...");
        test_failed($test_slogan);
  }
}

sub FUT042  # 4.4.3.2.8
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.8 ; Delete   - Delete   IurLink from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne(RncFunction);
  if($rnc)
  {
        my ($IurLink_fdn,$IurLink_attr) = get_fdn("IurLink","delete");
  	my $UtranNetwork = pick_a_mo($rnc,UtranNetwork);
    	log_registry("Selected UtranNetwork for IurLink is: $UtranNetwork");
        test_failed($test_slogan) if not $UtranNetwork;
	return "0" if not $UtranNetwork;
	$IurLink_fdn = base_fdn_modify($rnc,$IurLink_fdn);
        $IurLink_attr = "$IurLink_attr"." "."$UtranNetwork";
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$IurLink_fdn,$IurLink_attr);
	log_registry("It seems mo is not in Consistent state,while it should be") if not ($status and $rev_id == 1);
        test_failed($test_slogan) if not ($status and $rev_id == 1);
        return "0" if not ($status and $rev_id == 1);
 	proxy_mo_delete_decision($test_slogan,"CSCLI",$IurLink_fdn);
  }
  else
  {
        log_registry("It seems no Synched RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT043  # 4.4.3.2.16 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.16 ; Delete   - Delete   IurLink from an application using netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne(RncFunction);
  if($rnc)
  {
        my ($IurLink_fdn,$IurLink_attr) = get_fdn("IurLink","delete");
        my $UtranNetwork = pick_a_mo($rnc,UtranNetwork);
        log_registry("Selected UtranNetwork for IurLink is: $UtranNetwork");
        test_failed($test_slogan) if not $UtranNetwork;
        return "0" if not $UtranNetwork;
	$IurLink_fdn = base_fdn_modify($rnc,$IurLink_fdn);
        $IurLink_attr = "$IurLink_attr"." "."$UtranNetwork";
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$IurLink_fdn,$IurLink_attr);
	log_registry("It seems mo is not in Consistent state,while it should be") if not ($status and $rev_id == 1);
        test_failed($test_slogan) if not ($status and $rev_id == 1);
        return "0" if not ($status and $rev_id == 1);
        proxy_mo_delete_decision($test_slogan,"CLI",$IurLink_fdn);
  }
  else
  {
        log_registry("It seems no Synched RNC found...");
        test_failed($test_slogan);
  }
}
sub FUT044  # 4.4.1.3.1
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.3.1 ; Create  UtranFrequency  when no master ExternalUtranFreq initially exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD); # Select ERBS those have EUtranCellFDD
  if($ERBS)
  {
        my $UtraNetwork = pick_a_mo($ERBS,UtraNetwork);
        my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
        my ($base_fdn,$base_attr) = get_fdn("UtranFrequency","create");
        test_failed($test_slogan) if not ($UtraNetwork and $EUCFDD);
        return "0" if not ($UtraNetwork and $EUCFDD);
        log_registry("Selected UtraNetwork for UtranFrequency is: $UtraNetwork");
        log_registry("Selected EUtranCellFDD for UtranFreqRelation is: $EUCFDD");
        $base_fdn = base_fdn_modify($UtraNetwork,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$base_attr);
        test_failed($test_slogan) if not ($status and $rev_id);
        return "0" if not ($status and $rev_id);
        my ($EUF_fdn,$EUF_attr) = get_fdn("ExternalUtranFreq","create");
        log_registry("Please wait master ExternalUtranFreq MO $EUF_fdn is getting created....");
        my $result = mo_create_decision("0",$EUF_fdn,$EUF_attr,"","wait for consistent");
        $result = master_for_proxy_handle("0",$EUF_fdn,$EUF_attr,"","wait for consistent") if($result and $result eq "KO");
        log_registry("Problem in creation of ExternalUtranFreq MO.....") if not $result;
        test_failed($test_slogan) if not $result;
        return "0" if not $result;
        my $UFR_fdn = "$EUCFDD".","."UtranFreqRelation=$mo_proxy_cms";
        my $UFR_attr = "adjacentFreq"." "."$EUF_fdn"." "."utranFrequencyRef"." "."$base_fdn";
        $result = "";
        log_registry("Creating UtranFreqRelation $UFR_fdn \n attributes for UtranFreqRelation is: $UFR_attr ....");
        $result = create_mo_CS(mo=> $UFR_fdn, attributes => $UFR_attr);
        log_registry("Problem in creation of UtranFreqRelation MO.....") if $result;
        test_failed($test_slogan) if $result;
        return "0" if $result;
        my $nudge = forceCC($base_fdn);
        long_sleep_found($nudge) if $nudge;
        my $review_cache_log = cache_file();
        my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
        get_mo_attr($base_fdn) if $rev_log;
        my $master_mo = get_master_for_proxy($base_fdn);
        log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
        log_registry("There is no Master Mo exist for the given proxy while it should be : $base_fdn") if not $master_mo;
        test_failed($test_slogan) if not $master_mo;
        return "0" if not $master_mo;
        log_registry("It seems master of proxy is not matching with the master created by proxy.pl..")if ($master_mo !~ /$EUF_fdn/);
        test_failed($test_slogan) if ($master_mo !~ /$EUF_fdn/);
        return "0" if ($master_mo !~ /$EUF_fdn/);
        log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
        test_passed($test_slogan) if ($rev_d == 1);
        test_failed($test_slogan) if ($rev_d != 1);
  }
  else
  {
        log_registry("It seems no Synched ERBS found... or No Synched ERBS have EUtranCellFDD under it...");
        test_failed($test_slogan);
  }
}



sub FUTPICO044  # 4.4.1.3.1
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.3.1 ; Create  UtranFrequency  when no master ExternalUtranFreq initially exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD,"","PICOLTE"); # Select ERBS those have EUtranCellFDD 
  if($ERBS)
  {
        my $UtraNetwork = pick_a_mo($ERBS,UtraNetwork);
  	my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
        my ($base_fdn,$base_attr) = get_fdn("UtranFrequency","create");
        test_failed($test_slogan) if not ($UtraNetwork and $EUCFDD);
        return "0" if not ($UtraNetwork and $EUCFDD);
        log_registry("Selected UtraNetwork for UtranFrequency is: $UtraNetwork");
	log_registry("Selected EUtranCellFDD for UtranFreqRelation is: $EUCFDD");
	$base_fdn = base_fdn_modify($UtraNetwork,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$base_attr);
        test_failed($test_slogan) if not ($status and $rev_id);
        return "0" if not ($status and $rev_id);
 	my ($EUF_fdn,$EUF_attr) = get_fdn("ExternalUtranFreq","create");
	log_registry("Please wait master ExternalUtranFreq MO $EUF_fdn is getting created....");
	my $result = mo_create_decision("0",$EUF_fdn,$EUF_attr,"","wait for consistent");
	$result = master_for_proxy_handle("0",$EUF_fdn,$EUF_attr,"","wait for consistent") if($result and $result eq "KO");
	log_registry("Problem in creation of ExternalUtranFreq MO.....") if not $result;
	test_failed($test_slogan) if not $result;
	return "0" if not $result;
	my $UFR_fdn = "$EUCFDD".","."UtranFreqRelation=$mo_proxy_cms";
	my $UFR_attr = "adjacentFreq"." "."$EUF_fdn"." "."utranFrequencyRef"." "."$base_fdn";
	$result = "";
	log_registry("Creating UtranFreqRelation $UFR_fdn \n attributes for UtranFreqRelation is: $UFR_attr ....");
	$result = create_mo_CS(mo=> $UFR_fdn, attributes => $UFR_attr);
        log_registry("Problem in creation of UtranFreqRelation MO.....") if $result;
        test_failed($test_slogan) if $result;
        return "0" if $result;
	my $nudge = forceCC($base_fdn);
	long_sleep_found($nudge) if $nudge;
	my $review_cache_log = cache_file();
        my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
        get_mo_attr($base_fdn) if $rev_log;
        my $master_mo = get_master_for_proxy($base_fdn);
        log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
        log_registry("There is no Master Mo exist for the given proxy while it should be : $base_fdn") if not $master_mo;
	test_failed($test_slogan) if not $master_mo;
	return "0" if not $master_mo;
	log_registry("It seems master of proxy is not matching with the master created by proxy.pl..")if ($master_mo !~ /$EUF_fdn/);
	test_failed($test_slogan) if ($master_mo !~ /$EUF_fdn/);
	return "0" if ($master_mo !~ /$EUF_fdn/);
	log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
        test_passed($test_slogan) if ($rev_d == 1);
        test_failed($test_slogan) if ($rev_d != 1);
  }
  else
  {
        log_registry("It seems no Synched ERBS found... or No Synched ERBS have EUtranCellFDD under it...");
        test_failed($test_slogan);
  }
}

sub FUT045 # 4.4.2.3.1
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.3.1 ; Set Proxy MO - Set   UtranFrequency attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($count,@UF_fdn) = get_CMS_mo("UtranFrequency",$mo_proxy_cms);  
  if($count)
  {
	my $mo_fdn = $UF_fdn[0];
	log_registry("Selected UtranFrequency MO is : $mo_fdn");
	my ($base_fdn,$attr) = get_fdn("UtranFrequency","set");
	my ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$mo_fdn,$attr);
        test_passed($test_slogan) if ($status and $rev_id);
        test_failed($test_slogan) if (!($status) or !($rev_id));
############################################ CLEAN UP ###################################################################
	log_registry("Clean UP: Deleting UtranFreqRelation....");
        my %UFR = get_mo_attributes_CS(mo =>$mo_fdn,attributes => "reservedBy");
        log_registry("Deleting UtranFreqRelation MO $UFR{reservedBy} ") if ($UFR{reservedBy});
	my $clean_issue = delete_mo_CS(mo => $UFR{reservedBy}) if ($UFR{reservedBy});
	log_registry("Warning: Problem in deletion of MO $UFR{reservedBy} ") if $clean_issue;
	log_registry("Clean UP: Deleting ExternalUtranFreq....");
	my ($count_EUF,@EUF_fdn) = get_CMS_mo("ExternalUtranFreq",$mo_proxy_cms);	
	if($count_EUF)
	{
		foreach(@EUF_fdn)
		{
			log_registry("Deleting MO => $_ ");
			my $clean_issue = delete_mo_CS( mo => $_ );
			log_registry("Warning: Problem in deletion of MO $_ ") if $clean_issue;
		}
	}
	log_registry("Clean up: Deleting UtranFrequency MO $mo_fdn");
	my $clean_issu = delete_mo_CS(mo => $mo_fdn);
	log_registry("Warning: Problem in deletion of MO $mo_fdn ") if $clean_issu;
  }
  else
  {
	log_registry("It seems there is no pre-existing UtranFrequency created by cms automation...");
	test_failed($test_slogan);
  }
}

sub FUT046 # 4.4.3.3.1
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.3.1 ;Delete unreserved UtranFrequency with no corresponding Master ExternalUtranFreq from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD); # Select ERBS those have EUtranCellFDD
  if($ERBS)
  {
	my ($base_fdn,$base_attr) = get_fdn("UtranFrequency","create");
 	my $UtraNetwork = pick_a_mo($ERBS,UtraNetwork);	
        log_registry("Selected UtraNetwork for UtranFrequency is: $UtraNetwork");
	$base_fdn = base_fdn_modify($UtraNetwork,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$base_attr);
        test_failed($test_slogan) if not ($status and $rev_id);
        return "0" if not ($status and $rev_id);
	sleep 60;
        log_registry("Selected UtranFrequency MO for delete is : $base_fdn");
        proxy_mo_delete_decision($test_slogan,"CSCLI",$base_fdn);
  }
  else
  {
        log_registry("It seems NO SYNCHED ERBS found......"); 
        test_failed($test_slogan);
  }
}


sub FUT047  # 4.4.1.3.4 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.3.4 ; Create  UtranFrequency  when no master ExternalUtranFreq initially exists through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD); # Select ERBS those have EUtranCellFDD
  if($ERBS)
  {
        my $UtraNetwork = pick_a_mo($ERBS,UtraNetwork);
        my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
        my ($base_fdn,$base_attr) = get_fdn("UtranFrequency","create");
        test_failed($test_slogan) if not ($UtraNetwork and $EUCFDD);
        return "0" if not ($UtraNetwork and $EUCFDD);
        log_registry("Selected UtraNetwork for UtranFrequency is: $UtraNetwork");
        log_registry("Selected EUtranCellFDD for UtranFreqRelation is: $EUCFDD");
	$base_fdn = base_fdn_modify($UtraNetwork,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$base_attr);
        test_failed($test_slogan) if not ($status and $rev_id);
        return "0" if not ($status and $rev_id);
        my ($EUF_fdn,$EUF_attr) = get_fdn("ExternalUtranFreq","create");
        log_registry("Please wait master ExternalUtranFreq MO $EUF_fdn is getting created....");
        my $result = mo_create_decision("0",$EUF_fdn,$EUF_attr,"","wait for consistent");
	$result = master_for_proxy_handle("0",$EUF_fdn,$EUF_attr,"","wait for consistent") if($result and $result eq "KO");
        log_registry("Problem in creation of ExternalUtranFreq MO.....") if not $result;
        test_failed($test_slogan) if not $result;
        return "0" if not $result;
        my $UFR_fdn = "$EUCFDD".","."UtranFreqRelation=$mo_proxy_cms";
        my $UFR_attr = "adjacentFreq"." "."$EUF_fdn"." "."utranFrequencyRef"." "."$base_fdn";
        $result = "";
        $result = create_mo_CS(mo=> $UFR_fdn, attributes => $UFR_attr);
        log_registry("Problem in creation of UtranFreqRelation MO.....") if $result;
        test_failed($test_slogan) if $result;
        return "0" if $result;
        log_registry("wait for 3 mins to get system stabilized....");
        sleep 180;
	my $status = does_mo_exist_CLI( base => CLI, mo => $base_fdn);
	log_registry("MO $base_fdn Exist in node side............") if ($status eq "YES");
	test_failed($test_slogan) if not ($status eq "YES");
	return "0" if not ($status eq "YES");	
        my $review_cache_log = cache_file();
        my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
        get_mo_attr($base_fdn) if $rev_log;
        my $master_mo = get_master_for_proxy($base_fdn);
        log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
        log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
        log_registry("There is no Master Mo exist for the given proxy while it should be : $base_fdn") if not $master_mo;
        test_failed($test_slogan) if not $master_mo;
	my $flag = 0;
	$flag = 1 if not $master_mo;
	if($master_mo) {
        	log_registry("It seems master of proxy is not matching with the master created by proxy.pl..")if ($master_mo !~ /$EUF_fdn/);
        	test_failed($test_slogan) if ($master_mo !~ /$EUF_fdn/); 
		$flag = 1 if ($master_mo !~ /$EUF_fdn/); }
	log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
        test_passed($test_slogan) if ($rev_d == 1 and !($flag));
        test_failed($test_slogan) if ($rev_d != 1 and !($flag));
############################################ CLEAN UP ###################################################################
        log_registry("Clean UP: Deleting UtranFreqRelation....");
        log_registry("Deleting UtranFreqRelation MO $UFR_fdn");
        my $clean_issue = delete_mo_CS(mo => $UFR_fdn);
	log_registry("Warning: Problem in deletion of MO $UFR_fdn") if $clean_issue;
        log_registry("Clean UP: Deleting ExternalUtranFreq....");
        log_registry("Deleting MO => $EUF_fdn ");
        $clean_issue = delete_mo_CS( mo => $EUF_fdn );
	log_registry("Warning: Problem in deletion of MO $EUF_fdn ") if $clean_issue;
        log_registry("Clean up: Deleting UtranFrequency MO $base_fdn");
        $clean_issue = delete_mo_CS(mo => $base_fdn);
	log_registry("Warning: Problem in deletion of MO $base_fdn ") if $clean_issue;
  }
  else
  {
        log_registry("It seems no Synched ERBS found... or No Synched ERBS have EUtranCellFDD under it...");
        test_failed($test_slogan);
  }
}

sub FUT048  # 4.4.1.3.5
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.3.5 ; Create   - Create Proxy UtranFrequency when no master ExternalUtranFreq exists through the EM (netsim)  , then is autocreated";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD); # Select ERBS those have EUtranCellFDD
  if($ERBS)
  {
        my $UtraNetwork = pick_a_mo($ERBS,UtraNetwork);
        my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
        my ($base_fdn,$base_attr) = get_fdn("UtranFrequency","create");
        test_failed($test_slogan) if not ($UtraNetwork and $EUCFDD);
        return "0" if not ($UtraNetwork and $EUCFDD);
        log_registry("Selected UtraNetwork for UtranFrequency is: $UtraNetwork");
        log_registry("Selected EUtranCellFDD for UtranFreqRelation is: $EUCFDD");
	$base_fdn = base_fdn_modify($UtraNetwork,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$base_attr);
        test_failed($test_slogan) if not ($status and $rev_id);
        return "0" if not ($status and $rev_id);
        my $UFR_fdn = "$EUCFDD".","."UtranFreqRelation=$mo_proxy_cms";
        my $UFR_attr = "utranFrequencyRef"." "."$base_fdn";
	my $time = sleep_start_time();
	my $result = create_mo_CLI(mo => $UFR_fdn, base => CLI, attributes => $UFR_attr);
        log_registry("Problem in creation of UtranFreqRelation MO.....") if ($result ne OK);
        test_failed($test_slogan) if ($result ne OK);
        return "0" if ($result ne OK);
	log_registry("UtranFreqRelation MO get created on node side...");
        my $status = does_mo_exist_CLI( base => CLI, mo => $base_fdn);
        log_registry("MO $base_fdn Exist in node side............") if ($status eq "YES");
        test_failed($test_slogan) if not ($status eq "YES");
        return "0" if not ($status eq "YES");
	long_sleep_found($time);
        my $review_cache_log = cache_file();
        my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
        get_mo_attr($base_fdn) if $rev_log;
        my $master_mo = get_master_for_proxy($base_fdn);
        log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
	log_registry("No Master exist for proxy $base_fdn, it means no ExternalUtranFreq master MO has created automatically....") if not $master_mo;
	log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
        test_failed($test_slogan) if (!($master_mo) or ($rev_d != 1));
	test_passed($test_slogan) if ($master_mo and $rev_d == 1);
############################################ CLEAN UP ###################################################################
        log_registry("Clean UP: Deleting UtranFreqRelation....");
        log_registry("Deleting UtranFreqRelation MO $UFR_fdn");
        my $clean_issue = delete_mo_CS(mo => $UFR_fdn);
	log_registry("Warning: Problem in deletion of MO $UFR_fdn ") if $clean_issue;
        log_registry("Clean up: Deleting UtranFrequency MO $base_fdn");
        $clean_issue = delete_mo_CS(mo => $base_fdn);
	log_registry("Warning: Problem in deletion of MO $base_fdn ") if $clean_issue;
        log_registry("Clean UP: Deleting ExternalUtranFreq....");
	$master_mo =~ s/\n+//g;
        log_registry("Deleting MO => $master_mo ");
        $clean_issue = delete_mo_CS( mo => $master_mo);
	log_registry("Warning: Problem in deletion of MO $master_mo ") if $clean_issue;
  }
  else
  {
        log_registry("It seems no Synched ERBS found... or No Synched ERBS have EUtranCellFDD under it...");
        test_failed($test_slogan);
  }
}

sub FUT049 # 4.4.3.3.3
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.3.3 ; Delete   - Delete   UtranFrequency through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD); # Select ERBS those have EUtranCellFDD
  if($ERBS)
  {
        my ($base_fdn,$base_attr) = get_fdn("UtranFrequency","create");
        my $UtraNetwork = pick_a_mo($ERBS,UtraNetwork);
        log_registry("Selected UtraNetwork for UtranFrequency is: $UtraNetwork");
	$base_fdn = base_fdn_modify($UtraNetwork,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$base_attr);
        test_failed($test_slogan) if not ($status and $rev_id);
        return "0" if not ($status and $rev_id);
        sleep 60;
        log_registry("Selected UtranFrequency MO for delete is : $base_fdn");
        proxy_mo_delete_decision($test_slogan,"CLI",$base_fdn);
  }
  else
  {
        log_registry("It seems NO SYNCHED ERBS found......");
        test_failed($test_slogan);
  }
}

sub FUT050  # 4.4.1.4.1
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.4.1;Create Cdma2000FreqBand when no master exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne(ENodeBFunction,"NEW");
  if($ERBS)
  {
        my ($base_fdn,$attr) = get_fdn("Cdma2000FreqBand","create");
        my $Cdma2000Network = pick_a_mo($ERBS,Cdma2000Network);
        log_registry("Selected Cdma2000Network for Cdma2000FreqBand is: $Cdma2000Network");
        test_failed($test_slogan) if not $Cdma2000Network;
        return "0" if not $Cdma2000Network;
        $base_fdn = base_fdn_modify($Cdma2000Network,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
        test_failed($test_slogan) if not ($status and $rev_id == 7);
	test_passed($test_slogan) if ($status and $rev_id == 7);
  }
  else
  {
        log_registry("It seems no Synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT051  # 4.4.1.4.10
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.4.10; Create  Cdma2000Freq when no master exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
  my ($count,@CFB_FDN) = get_CMS_mo("Cdma2000FreqBand",$mo_proxy_cms);
  if($count)
  {
        my ($base_fdn,$attr) = get_fdn("Cdma2000Freq","create");
        $base_fdn = base_fdn_modify($CFB_FDN[0],$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
        test_passed($test_slogan) if ($status and $rev_id == 7);
	test_failed($test_slogan) if not ($status and $rev_id == 7);
  }
  else
  {
        log_registry("It seems no Cdma2000FreqBand MO found created by proxy.pl, which is needed for Cdma2000Freq creation");
        test_failed($test_slogan);
  }
}

sub FUT052  # 4.4.1.4.19
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.4.19;Create  ExternalCdma2000Cell when no master exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@CF_FDN) = get_CMS_mo("Cdma2000Freq",$mo_proxy_cms);
  if($count)
  {
        my ($base_fdn,$attr) = get_fdn("ExternalCdma2000Cell","create");
        $base_fdn = base_fdn_modify($CF_FDN[0],$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
        test_passed($test_slogan) if ($status and $rev_id == 7);
        test_failed($test_slogan) if not ($status and $rev_id == 7);
  }
  else
  {
        log_registry("It seems no Cdma2000Freq MO found created by proxy.pl,which is needed for ExternalCdma2000Cell creation");
        test_failed($test_slogan);
  }
}

sub FUT053  # 4.4.2.4.1 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.4.1 ; Set Proxy MO - Set   Cdma2000FreqBand attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@CFB_FDN) = get_CMS_mo("Cdma2000FreqBand",$mo_proxy_cms);
  if($count)
  {
        my ($base_fdn,$attr) = get_fdn("Cdma2000FreqBand","set");
        my ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$CFB_FDN[0],$attr);
        test_passed($test_slogan) if ($status);
        test_failed($test_slogan) if not ($status);
  }
  else
  {
        log_registry("It seems no Cdma2000FreqBand MO found created by proxy.pl..........");
        test_failed($test_slogan);
  }
}

sub FUT054  # 4.4.2.4.2
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.4.2 ; Set Proxy MO - Set   Cdma2000Freq attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@CF_FDN) = get_CMS_mo("Cdma2000Freq",$mo_proxy_cms);
  if($count)
  {
        my ($base_fdn,$attr) = get_fdn("Cdma2000Freq","set");
        my ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$CF_FDN[0],$attr);
        test_passed($test_slogan) if ($status);
        test_failed($test_slogan) if not ($status);
  }
  else
  {
        log_registry("It seems no Cdma2000Freq MO found created by proxy.pl..........");
        test_failed($test_slogan);
  }
}

sub FUT055  # 4.4.2.4.5
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.4.5 ; Set Proxy MO - Set   ExternalCdma2000Cell attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@ECC_FDN) = get_CMS_mo("ExternalCdma2000Cell",$mo_proxy_cms);
  if($count)
  {
        my ($base_fdn,$attr) = get_fdn("ExternalCdma2000Cell","set");
        my ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$ECC_FDN[0],$attr);
        test_passed($test_slogan) if ($status);
        test_failed($test_slogan) if not ($status);
  }
  else
  {
        log_registry("It seems no ExternalCdma2000Cell MO found created by proxy.pl..........");
        test_failed($test_slogan);
  }
}

sub FUT056  #4.4.3.4.7 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.4.7 ; Delete   - Delete   ExternalCdma2000Cell from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@ECC_FDN) = get_CMS_mo("ExternalCdma2000Cell",$mo_proxy_cms);
  if($count)
  {
        proxy_mo_delete_decision($test_slogan,"CSCLI",$ECC_FDN[0]);
  }
  else
  {
        log_registry("It seems no ExternalCdma2000Cell MO found created by proxy.pl..........");
        test_failed($test_slogan);
  }
}

sub FUT057  #4.4.3.4.4
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.4.4 ; Delete   - Delete   Cdma2000Freq from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@CF_FDN) = get_CMS_mo("Cdma2000Freq",$mo_proxy_cms);
  if($count)
  {
        proxy_mo_delete_decision($test_slogan,"CSCLI",$CF_FDN[0]);
  }
  else
  {
        log_registry("It seems no Cdma2000Freq MO found created by proxy.pl..........");
        test_failed($test_slogan);
  }
}

sub FUT058  #4.4.3.4.1
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.4.1 ; Delete   - Delete   Cdma2000FreqBand from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@CFB_FDN) = get_CMS_mo("Cdma2000FreqBand",$mo_proxy_cms);
  if($count)
  {
        proxy_mo_delete_decision($test_slogan,"CSCLI",$CFB_FDN[0]);
  }
  else
  {
        log_registry("It seems no Cdma2000FreqBand MO found created by proxy.pl..........");
        test_failed($test_slogan);
  }
}

sub FUT059  # 4.4.1.4.6
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.4.6;Create Proxy Cdma2000FreqBand when no master ExternalCdma2000FreqBand exists through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
#  my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD); # Select ERBS those have EUtranCellFD
  my $ERBS = pick_a_erbs_using_cell(CELL => "EUtranCellFDD", VER => "NEW");

  if($ERBS)
  {
        my ($base_fdn,$attr) = get_fdn("Cdma2000FreqBand","create");
        my $Cdma2000Network = pick_a_mo($ERBS,Cdma2000Network);
        log_registry("Selected Cdma2000Network for Cdma2000FreqBand is: $Cdma2000Network");
        test_failed($test_slogan) if not $Cdma2000Network;
        return "0" if not $Cdma2000Network;
        $base_fdn = base_fdn_modify($Cdma2000Network,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$attr);
#	log_registry("SHERE $status,$rev_id");
#       test_failed($test_slogan) if not ($status); # Patch eeitjn don't need this any more....
#	return "0" if not ($status);
	my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
	log_registry("Selected EUtranCellFDD for Cdma2000FreqBandRelation is: $EUCFDD");
	my $CFBR_fdn = "$EUCFDD".","."Cdma2000FreqBandRelation=$mo_proxy_cms";
	my $CFBR_attr = "cdma2000FreqBandRef"." "."$base_fdn";
	log_registry("Creating Cdma2000FreqBandRelation $CFBR_fdn for Cdma2000FreqBand MO.............");
	my $time = sleep_start_time();
	my $result = create_mo_CLI(mo => $CFBR_fdn, base => CLI, attributes => $CFBR_attr);
        log_registry("Problem in creation of Cdma2000FreqBandRelation MO.....") if ($result ne OK);
        test_failed($test_slogan) if ($result ne OK);
        return "0" if ($result ne OK);
        log_registry("Cdma2000FreqBandRelation MO get created on node side...");
	long_sleep_found($time);	
        my $review_cache_log = cache_file();
        my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
	my $master_mo = get_master_for_proxy($base_fdn);
        log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
        log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
	log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
        test_passed($test_slogan) if ($rev_d == 1 and $master_mo);
        test_failed($test_slogan) if ($rev_d != 1 or !($master_mo));
################################################ Clean Up ###############################################################
	log_registry("Clean UP: Deleting Cdma2000FreqBandRelation $CFBR_fdn .......");
	my $clean_issue = delete_mo_CS(mo => $CFBR_fdn);
	log_registry("Warning: Problem in deletion of MO $CFBR_fdn") if $clean_issue;
	log_registry("Clean UP: Deleting Cdma2000FreqBand MO $base_fdn.......");
	$clean_issue = delete_mo_CS(mo => $base_fdn);
        log_registry("Warning: Problem in deletion of MO $base_fdn ") if $clean_issue;
	log_registry("Clean UP: Deleting ExternalCdma2000FreqBand MO $master_mo...");
	$clean_issue = delete_mo_CS(mo => $master_mo);
	log_registry("Warning: Problem in deletion of MO $master_mo .....") if $clean_issue;
  }
  else
  {
        log_registry("It seems no Synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT060  # 4.4.1.4.15 and 4.4.2.4.3
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if($test_slogan =~ /4\.4\.1\.4\.15/);
  $tc_id = 2 if($test_slogan =~ /4\.4\.2\.4\.3/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.4.15;Create Proxy Cdma2000Freq when no master ExternalCdma2000Freq exists through the netsim" if($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.2.4.3 ; Set   - Set   Cdma2000Freq traffical Id attribute (freqCdma), missing master autofix on" if($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
#  my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD); # Select ERBS those have EUtranCellFD  // eeitjn 06 Nov 20102
  my $ERBS = pick_a_erbs_using_cell(CELL => "EUtranCellFDD", VER => "NEW");


  if($ERBS)
  {		# eeitjn Patch : pick and existing Cdma2000FreqBand , create new freq under that.

	my ($count,@P_C2FB) = get_CMS_mo("Cdma2000FreqBand",$ERBS);
	log_registry("It seems no proxy Cdma2000FreqBand mo found under ERBS $ERBS") if not $count;
	test_failed($test_slogan) if not $count;
	return "0" if not $count;

	my ($base_fdn, $base_attr) = get_fdn("Cdma2000Freq","create","no wait");
        $base_fdn = base_fdn_modify($P_C2FB[0],$base_fdn);
        ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$base_attr);

#	my $C2F = $C2F[int(rand($#C2F))];
#	($C2FR,$EC2F) = create_Cdma2000FreqRelation( C2FBR => $C2FB_fdn , C2F => $C2F,base => "CLI" ); 
#	log_registry("There is a problem in creation of Cdma2000FreqRelation ...") if not $C2FR;
#	test_failed($test_slogan) if not $C2FR;
#	return "0" if not $C2FR;

 	my $EUCFDD_fdn = "$ERBS".","."EUtranCellFDD=$mo_proxy_cms";
	my ($EUCFDD_attr ,$attr) = get_fdn("Cdma2000FreqBand","create");

        my ($count,@SEF) = select_mo_cs( MO => "SectorEquipmentFunction", KEY => "$ERBS");
        log_registry("Pickeeeeed SectorEquipmentFunction $SEF[0]");
	my $EUCFDD_attr = "userLabel"." "."$mo_proxy_cms"." "."redirectionInfoRefPrio1"." "."$base_fdn"." "."sectorFunctionRef"." "."$SEF[0]";
	
	log_registry("Creating EUtranCellFDD on node side $EUCFDD_fdn, \n Attributes will be: $EUCFDD_attr");
	my $time = sleep_start_time();
	my $result = create_mo_CLI(mo => $EUCFDD_fdn, base => CLI, attributes => $EUCFDD_attr);
        log_registry("Problem in creation of EUtranCellFDD MO.....") if ($result ne OK);
        test_failed($test_slogan) if ($result ne OK);
        return "0" if ($result ne OK);
        log_registry("EUtranCellFDD MO get created on node side...");
	long_sleep_found($time);
        my $review_cache_log = cache_file();
        my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
        my $master_mo = get_master_for_proxy($base_fdn);
        log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
        log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
	log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);

        test_failed($test_slogan) if ($rev_d != 1 or !($master_mo));
        test_passed($test_slogan) if ($tc_id == 1 and $rev_d == 1 and $master_mo);
	my $new_master;
	if($tc_id == 2 and $rev_d == 1 and $master_mo)
	{
		my($fdn,$mod_attrs) = get_fdn("freqCdma2000Freq","set");
		my($status,$rev_id) = proxy_mo_set_decision("CSCLI",$base_fdn,$mod_attrs);
		log_registry("Problem in setting attribute of proxy Cdma2000Freq mo..") if not $status;
		log_registry("It seems proxy Cdma2000Freq mo is not consistent after modifying attribute..") if ($status and $rev_id != 1);
		test_failed($test_slogan) if (!($status) or ($rev_id != 1));
		if($status and $rev_id == 1) {
			$new_master = get_master_for_proxy($base_fdn);
			log_registry("New Master Mo for the Given Proxy is: \n $new_master") if ($new_master and $new_master !~ /$master_mo$/);
			log_registry("There is no new master get created for proxy") if (!($new_master) or $new_master =~ /$master_mo$/);
			test_failed($test_slogan) if (!($new_master) or $new_master =~ /$master_mo$/);
			test_passed($test_slogan) if ($new_master and $new_master !~ /$master_mo$/); }
	}
################################################ Clean Up ###############################################################

        log_registry("Clean UP: Deleting EUtranCellFDD $EUCFDD_fdn .......");
	log_registry("To delete EUtranCellFDD MO, first reset <redirectionInfoRefPrio1> attribute to Null...");
	my $set_attr = set_attributes_mo_CLI(mo =>$EUCFDD_fdn, base => CLI , attributes=>"redirectionInfoRefPrio1");
	log_registry("Problem in setting EUtranCellFDD MO attribute..") if ($set_attr ne OK);
        my $clean_issue = delete_mo_CS(mo => $EUCFDD_fdn);
        log_registry("Warning: Problem in deletion of MO $EUCFDD_fdn") if $clean_issue;
	log_registry("Clean UP: Deleting Cdma2000Freq MO $base_fdn.......");
	$clean_issue = delete_mo_CS(mo => $base_fdn);
	log_registry("Warning: Problem in deletion of MO $base_fdn ") if $clean_issue;
#        log_registry("Clean UP: Deleting Cdma2000FreqBand MO $C2FB_fdn .......");
#        $clean_issue = delete_mo_CS(mo => $C2FB_fdn);
#        log_registry("Warning: Problem in deletion of MO $C2FB_fdn ") if $clean_issue;
        log_registry("Clean UP: Deleting ExternalCdma2000Freq MO $master_mo...");
        $clean_issue = delete_mo_CS(mo => $master_mo);
        log_registry("Warning: Problem in deletion of MO $master_mo .....") if $clean_issue;
#	log_registry("Clean UP: Deleting ExternalCdma2000FreqBand MO $master_FreqBand_mo....");
#	$clean_issue = delete_mo_CS(mo => $master_FreqBand_mo);
#	log_registry("Warning: Problem in deletion of MO $master_FreqBand_mo .......") if $clean_issue;
	log_registry("Clean UP: Deleting ExternalCdma2000Freq MO $new_master ....") if $new_master;
	$clean_issue = delete_mo_CS(mo => $new_master) if $new_master;
	log_registry("Warning: Problem in deletion of MO $new_master .......") if ($new_master and $clean_issue);
  }
  else
  {
        log_registry("It seems no Synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT061  # 4.4.1.4.24
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.4.24 ;Create Proxy ExternalCdma2000Cell when no master ExternalCdma2000Cell exists through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
#  my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD); # Select ERBS those have EUtranCellFD

  my $ERBS = pick_a_erbs_using_cell(CELL => "EUtranCellFDD", VER => "NEW");

  if($ERBS)
  {
#        my ($C2FB_fdn,$C2FB_attr) = get_fdn("Cdma2000FreqBand","create");
#        my $Cdma2000Network = pick_a_mo($ERBS,Cdma2000Network);
#        log_registry("Selected Cdma2000Network for Cdma2000FreqBand is: $Cdma2000Network");
#        test_failed($test_slogan) if not $Cdma2000Network;
#        return "0" if not $Cdma2000Network;
#        $C2FB_fdn = base_fdn_modify($Cdma2000Network,$C2FB_fdn);
#        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$C2FB_fdn,$C2FB_attr,"no wait");
#        test_failed($test_slogan) if not ($status);
#        return "0" if not ($status);
#        my ($C2F_fdn, $C2F_attr) = get_fdn("Cdma2000Freq","create");
#        $C2F_fdn = base_fdn_modify($C2FB_fdn,$C2F_fdn);
#        ($status,$rev_id) = proxy_mo_create_decision("CLI",$C2F_fdn,$C2F_attr,"no wait");
#        test_failed($test_slogan) if not ($status);
#        return "0" if not ($status);

        my ($icount,@C2F) = get_CMS_mo("Cdma2000Freq",$ERBS);
        log_registry("It seems no Cdma2000Freq mo under ERBS ... $ERBS") if not $icount;
        test_failed($test_slogan) if not $icount;
        return "0" if not $icount;


	my($base_fdn,$base_attr) = get_fdn("ExternalCdma2000Cell","create");
	$base_fdn = base_fdn_modify($C2F[0],$base_fdn);
	($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$base_attr);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
	test_failed($test_slogan) if not ($status and $rev_id == 7);
	return "0" if not ($status and $rev_id == 7);
        my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
        log_registry("Selected EUtranCellFDD for Cdma2000CellRelation is: $EUCFDD");

#        my $CFBR_fdn = "$EUCFDD".","."Cdma2000FreqBandRelation=$mo_proxy_cms";
#        my $CFBR_attr = "cdma2000FreqBandRef"." "."$C2FB_fdn";
#        log_registry("Creating Cdma2000FreqBandRelation $CFBR_fdn for Cdma2000FreqBand MO.............");
#        my $result = create_mo_CLI(mo => $CFBR_fdn, base => CLI, attributes => $CFBR_attr);
#        log_registry("Problem in creation of Cdma2000FreqBandRelation MO.....") if ($result ne OK);
#        test_failed($test_slogan) if ($result ne OK);
#        return "0" if ($result ne OK);
#        log_registry("Cdma2000FreqBandRelation MO get created on node side...");


        my $CFBR_fdn = "$EUCFDD".","."Cdma2000FreqBandRelation=1";

	my $C2CR_fdn = "$CFBR_fdn".","."Cdma2000CellRelation=$mo_proxy_cms";
	my $C2CR_attr = "userLabel"." "."$mo_proxy_cms"." "."externalCdma2000CellRef"." "."$base_fdn";
	log_registry("Creating Cdma2000CellRelation $C2CR_fdn for ExternalCdma2000Cell ....");
	my $time = sleep_start_time(); 
	$result = create_mo_CLI(mo => $C2CR_fdn, base => CLI, attributes => $C2CR_attr);
	log_registry("Problem in creation of Cdma2000CellRelation MO.....") if ($result ne OK);
	return "0" if ($result ne OK);
	long_sleep_found($time);
        my $review_cache_log = cache_file();
        my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
        my $master_mo = get_master_for_proxy($base_fdn);
        log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
        log_registry("There is no Master Mo exist for the given proxy : $base_fdn") if not $master_mo;
	log_registry("It seems mo is not in Consistent state,while it should be") if ($rev_d != 1);
        test_passed($test_slogan) if ($rev_d == 1 and $master_mo);
        test_failed($test_slogan) if ($rev_d != 1 or !($master_mo));
	my $master_mo_C2FB = get_master_for_proxy($C2FB_fdn);
	log_registry("Master Mo for the Given Proxy $C2FB_fdn is: \n $master_mo_C2FB ") if $master_mo_C2FB;
################################################ Clean Up ###############################################################
	log_registry("Clean UP: Deleting Cdma2000CellRelation $C2CR_fdn ...");
	my $clean_issue = delete_mo_CS(mo => $C2CR_fdn);
	log_registry("Warning: Problem in deletion of MO  $C2CR_fdn ") if $clean_issue ;
#        log_registry("Clean UP: Deleting Cdma2000FreqBandRelation $CFBR_fdn .......");
#        $clean_issue = delete_mo_CS(mo => $CFBR_fdn);
#        log_registry("Warning: Problem in deletion of MO $CFBR_fdn") if $clean_issue;
#        log_registry("Clean UP: Deleting Cdma2000FreqBand MO $C2FB_fdn.......");
#        $clean_issue = delete_mo_CS(mo => $C2FB_fdn);
#        log_registry("Warning: Problem in deletion of MO $C2FB_fdn ") if $clean_issue;
	log_registry("Clean UP: Deleting ExternalCdma2000Cell MO $master_mo .........");
	$clean_issue = delete_mo_CS(mo => $master_mo) if $master_mo;
	log_registry("Warning: Problem in deletion of MO $master_mo .....") if $clean_issue;
#        log_registry("Clean UP: Deleting ExternalCdma2000FreqBand MO $master_mo_C2FB ...");
#        $clean_issue = delete_mo_CS(mo => $master_mo_C2FB);
#        log_registry("Warning: Problem in deletion of MO $master_mo_C2FB .....") if $clean_issue;
  }
  else
  {
        log_registry("It seems no Synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT062  # 4.4.3.4.8
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.4.8 ; Delete   - Delete   ExternalCdma2000Cell through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne(ENodeBFunction,"NEW");
  if($ERBS)
  {
        my ($C2FB_fdn,$C2FB_attr) = get_fdn("Cdma2000FreqBand","create");
        my $Cdma2000Network = pick_a_mo($ERBS,Cdma2000Network);
        log_registry("Selected Cdma2000Network for Cdma2000FreqBand is: $Cdma2000Network");
        test_failed($test_slogan) if not $Cdma2000Network;
        return "0" if not $Cdma2000Network;
        $C2FB_fdn = base_fdn_modify($Cdma2000Network,$C2FB_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$C2FB_fdn,$C2FB_attr,"no wait");
        test_failed($test_slogan) if not ($status);
	return "0" if not ($status);
	my ($C2F_fdn,$C2F_attr) = get_fdn("Cdma2000Freq","create");
        $C2F_fdn = base_fdn_modify($C2FB_fdn,$C2F_fdn);
        ($status,$rev_id) = proxy_mo_create_decision("CLI",$C2F_fdn,$C2F_attr,"no wait");
        test_failed($test_slogan) if not ($status);
	return "0" if not ($status);	
	my ($base_fdn,$attr) = get_fdn("ExternalCdma2000Cell","create");
        $base_fdn = base_fdn_modify($C2F_fdn,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$attr);
        test_failed($test_slogan) if not ($status);
	return "0" if not $status;
	proxy_mo_delete_decision($test_slogan,"CLI",$base_fdn);	
  }
  else
  {
        log_registry("It seems no Synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT063  #4.4.3.4.5
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.4.5 ; Delete   - Delete   Cdma2000Freq through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@CF_FDN) = get_CMS_mo("Cdma2000Freq",$mo_proxy_cms);
  if($count)
  {
        proxy_mo_delete_decision($test_slogan,"CLI",$CF_FDN[0]);
  }
  else
  {
        log_registry("It seems no Cdma2000Freq MO found created by proxy.pl..........");
        test_failed($test_slogan);
  }
}

sub FUT064  #4.4.3.4.2
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.4.2 ; Delete   - Delete   Cdma2000FreqBand through the netsim";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($count,@CFB_FDN) = get_CMS_mo("Cdma2000FreqBand",$mo_proxy_cms);
  if($count) {
        proxy_mo_delete_decision($test_slogan,"CLI",$CFB_FDN[0]); }
  else {
        log_registry("It seems no Cdma2000FreqBand MO found created by proxy.pl..........");
        test_failed($test_slogan); }
################################################# Clean Up ################################################################
        my $clean_issue;
		my ($icount,@ECFB_FDN) = get_CMS_mo("ExternalCdma2000FreqBand",$mo_proxy_cms);
	if($icount) {
        foreach(@ECFB_FDN)     {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;       } }
}

sub FUT065  # 4.4.1.5.1
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.5.1 ;Create GeranFreqGroup when no master exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne(ENodeBFunction);
  if($ERBS)
  {
        my ($base_fdn,$attr) = get_fdn("GeranFreqGroup","create");
        my $GeraNetwork = pick_a_mo($ERBS,GeraNetwork);
        log_registry("Selected GeraNetwork for GeranFreqGroup is: $GeraNetwork");
        test_failed($test_slogan) if not $GeraNetwork;
        return "0" if not $GeraNetwork;
        $base_fdn = base_fdn_modify($GeraNetwork,$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
	log_registry("It seems mo is not in Redundant state,while it should be") if (!($status) or $rev_id != 7);
        test_failed($test_slogan) if not ($status and $rev_id == 7);
        test_passed($test_slogan) if ($status and $rev_id == 7);
  }
  else
  {
        log_registry("It seems no Synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT066  # 4.4.1.5.13
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.5.13;Create GeranFrequency when no master exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@GFG_FDN) = get_CMS_mo("GeranFreqGroup",$mo_proxy_cms);
  if($count)
  {
        my ($base_fdn,$attr) = get_fdn("GeranFrequency","create");
        $base_fdn = base_fdn_modify($GFG_FDN[0],$base_fdn);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr);
        test_failed($test_slogan) if not ($status and $rev_id);
	return "0" if not ($status and $rev_id);
	my $master_mo = get_master_for_proxy($base_fdn);
	log_registry("Master MO for the given proxy is: \n $master_mo") if $master_mo;
	log_registry("It seems no master MO has created automaticaly for the proxy $base_fdn...") if not $master_mo; 
	test_failed($test_slogan) if not $master_mo;
	test_passed($test_slogan) if $master_mo;
  }
  else
  {
        log_registry("It seems no GeranFreqGroup MO found created by proxy.pl, which is needed for GeranFrequency creation");
        test_failed($test_slogan);
  }
}

sub FUT067  # 4.4.2.5.1
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.5.1 ; Set Proxy MO GeranFreqGroup attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@GFG_FDN) = get_CMS_mo("GeranFreqGroup",$mo_proxy_cms);
  if($count)
  {
        my ($base_fdn,$attr) = get_fdn("GeranFreqGroup","set");
        my ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$GFG_FDN[0],$attr);
        test_passed($test_slogan) if ($status);
        test_failed($test_slogan) if not ($status);
  }
  else
  {
        log_registry("It seems no GeranFreqGroup MO found created by proxy.pl..........");
        test_failed($test_slogan);
  }
}

sub FUT068  # 4.4.2.5.5  
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.5.5 ; Set Proxy MO GeranFrequency attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@GF_FDN) = get_CMS_mo("GeranFrequency",$mo_proxy_cms);
  if($count)
  {
        my ($base_fdn,$attr) = get_fdn("GeranFrequency","set");
        my ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$GF_FDN[0],$attr);
        test_passed($test_slogan) if ($status);
        test_failed($test_slogan) if not ($status);
  }
  else
  {
        log_registry("It seems no GeranFrequency MO found created by proxy.pl..........");
        test_failed($test_slogan);
  }
}

sub FUT069  # 4.4.3.5.10 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.5.10 ; Delete GeranFrequency from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@GF_FDN) = get_CMS_mo("GeranFrequency",$mo_proxy_cms);
  if($count)
  {
	my $master_mo = get_master_for_proxy($GF_FDN[0]);
        proxy_mo_delete_decision($test_slogan,"CSCLI",$GF_FDN[0]);
##################################### Clean up ############################################
	log_registry("Clean Up: Deleting master MO $master_mo of GeranFrequency created by proxy.pl .....") if ( $master_mo =~ /$mo_proxy_cms/ );
	my $clean_issue = delete_mo_CS(mo => $master_mo) if ($master_mo =~ /$mo_proxy_cms/);
	log_registry("Warning=> Problem in deletion of master MO $master_mo ....") if $clean_issue;
  }
  else
  {
        log_registry("It seems no GeranFrequency MO found created by proxy.pl..........");
        test_failed($test_slogan);
  }
}

sub FUT070  # 4.4.3.5.1
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.5.1 ; Delete GeranFreqGroup from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");

  my ($count,@GFG_FDN) = get_CMS_mo("GeranFreqGroup",$mo_proxy_cms);
  if($count)
  {
	my $master_mo = get_master_for_proxy($GFG_FDN[0]);
        proxy_mo_delete_decision($test_slogan,"CSCLI",$GFG_FDN[0]);
##################################### Clean up ############################################
        log_registry("Clean Up: Deleting master MO $master_mo of GeranFreqGroup created by proxy.pl .....") if ($master_mo =~ /$mo_proxy_cms/);
        my $clean_issue = delete_mo_CS(mo => $master_mo) if ($master_mo =~ /$mo_proxy_cms/);
        log_registry("Warning=> Problem in deletion of master MO $master_mo ....") if $clean_issue;
  }
  else
  {
        log_registry("It seems no GeranFreqGroup MO found created by proxy.pl..........");
        test_failed($test_slogan);
  }
}

sub FUT071  # 4.4.1.6.1 and 4.4.3.6.4
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.1\.6\.1/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.3\.6\.4/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.6.1 ; Create Relation(Intra), Create a UtranRelation MO with UtranCells in same RNC" if($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.3.6.4 ; Delete an intra-RNC UtranRelation" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne(RncFunction);
  if($rnc)
  {
	my $utran_cell_1 = create_UtranCell($rnc,"uarfcnUl 10 uarfcnDl 100"); 
        test_failed($test_slogan) if not $utran_cell_1;
        return "0" if not $utran_cell_1;
        log_registry("Selected UtranCell for UtranRelation is: $utran_cell_1");
	my $utran_cell_2 = create_UtranCell($rnc,"uarfcnUl 10 uarfcnDl 100");
	test_failed($test_slogan) if not $utran_cell_2;
	return "0" if not $utran_cell_2;
	my($UtranRelation,$utranCellRef)=create_UtranRelation(F_UtranCell => "$utran_cell_1",S_UtranCell => "$utran_cell_2");
	test_failed("$test_slogan") if not $UtranRelation;
	return "0" if not $UtranRelation;
	test_passed("$test_slogan") if ($tc_id == 1);
        if ($tc_id == 2)
        {
                log_registry("Deleting UtranRelation: $UtranRelation");
                my $status = delete_mo_CLI(mo => $UtranRelation, base => "CSCLI");
                log_registry("It seems UtranRelation get deleted ..") if ($status eq "OK");
                log_registry("WARNING => There is a problem in deletion of UtranRelation..") if ($status ne "OK");
                log_registry("wait for 2 mins to get system stabilized...");
                sleep 120;
                my $state = does_mo_exist_CLI( base => CSCLI, mo => $UtranRelation);
                log_registry("UtranRelation $UtranRelation get deleted successfully...") if ($state eq "NO");
                log_registry("UtranRelation $UtranRelation is not deleted ...") if ($state eq "YES");
                test_failed($test_slogan) if ($status ne "OK" or $state eq "YES");
                test_passed($test_slogan) if ($status eq "OK" and $state eq "NO");
        }
################################################# Clean Up ################################################################
	my $clean_issue;
	log_registry("Clean up: Deleting UtranRelation $UtranRelation") if ($UtranRelation and $tc_id == 1);
	$clean_issue = delete_mo_CS( mo => $UtranRelation) if ($UtranRelation and $tc_id == 1);
	log_registry("Warning => Problem in deletion of UtranRelation.....") if $clean_issue;
	log_registry("Clean up: Deleting UtranCell $utran_cell_1 ");
	$clean_issue = delete_mo_CS( mo => $utran_cell_1 );
	log_registry("Warning => Problem in deletion of UtranCell .......") if $clean_issue;
	log_registry("Clean up: Deleting UtranCell $utran_cell_2 ");
	$clean_issue = delete_mo_CS( mo => $utran_cell_2 );
	log_registry("Warning => Problem in deletion of UtranCell .......") if $clean_issue;
  }
  else
  {
        log_registry("It seems no Synched RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT072  # 4.4.1.6.2
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.6.2 ;Create GsmRelation";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne(RncFunction);
  if($rnc)
  {
        my $utran_cell = pick_a_mo($rnc,UtranCell);
        test_failed($test_slogan) if not $utran_cell;
        return "0" if not $utran_cell;
        log_registry("Selected UtranCell for GsmRelation is: $utran_cell");
        my $base_fdn = "$utran_cell".","."GsmRelation=$mo_proxy_cms";
        my $GSMcell = pick_a_MasterMO("ExternalGsmCell");   # pick any exist master GsmCell
        my $set_result = set_mo_attributes_CS(mo => $GSMcell, attributes => "individualOffset 1 qRxLevMin 100 maxTxPowerUl 1");  # TJN: Temp fix as Cells canbe from LTE only... some attrs are blank then ..... 
	log_registry("Selected Master ExternalGsmCell is: $GSMcell ");
        my $status = create_mo_CLI( mo => $base_fdn, base => "CSCLI", attributes =>  "adjacentCell $GSMcell");
        log_registry("It seems there is some problem during creation of GsmRelation...") if ($status ne "OK");
        test_failed("$test_slogan") if ($status ne "OK");
        return "0" if ($status ne "OK");
        %attrs = get_mo_attributes_CS( mo => $base_fdn, attributes => "externalGsmCellRef");
	my $flag = 0 ;
	$flag = 1 if not ($attrs{externalGsmCellRef} =~ /ExternalGsmCell/);
	log_registry("Attribute externalGsmCellRef of GsmRelation do not have any proxy ExternalGsmCell with it") if $flag;
	test_failed($test_slogan) if $flag;
	return "0" if $flag;
	log_registry("Attribute externalGsmCellRef of GsmRelation has one proxy ExternalGsmCell with it: $attrs{externalGsmCellRef}");
	my $proxies = get_proxies_master($GSMcell);
	log_registry("It seems Master $GSMcell does not have any proxy under it.....") if not $proxies;
	test_failed($test_slogan) if not $proxies;
	return "0" if not $proxies;
	$flag = 1 if not ($proxies =~ /$attrs{externalGsmCellRef}/);
	log_registry("It seems Master $GSMcell does not have proxy ExternalGsmCell $attrs{externalGsmCellRef} under it...") if $flag;
	test_failed($test_slogan) if $flag;
	log_registry("Master of Proxy ExternalGsmCell $attrs{externalGsmCellRef} is Master ExternalGsmCell $GSMcell") if not $flag;
	test_passed($test_slogan) if not $flag;
################################## Clean up ###########################################################
	log_registry("Clean up: Deleting GsmRelaton $base_fdn");
	my $clean_issue = delete_mo_CS( mo => $base_fdn );
        log_registry("Warning => Problem in deletion of GsmRelation.....") if $clean_issue;
  }
  else
  {
        log_registry("It seems no Synched RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT073  # 4.4.1.6.3 and 4.4.3.6.5
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.1\.6\.3/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.3\.6\.5/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.6.3 ; Create oneWay Relation(Inter), Create a UtranRelation MO with UtranCells in different N RNC's" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.3.6.5 ; Delete an inter-RNC UtranRelation" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  log_registry("Related Inormation: To perform the Inter UtranRelation,in this test case we are creating 3 brand new UtranCells in which two of them have same uplink and downlink frequency value while another one has different value. these 3 Utrancells are created on 3 different RNC.") if ($tc_id == 1);
  my $rnc = pick_a_ne(RncFunction);
  my $rnc2 = pick_a_different_rnc($rnc) if $rnc;
  my $rnc3 = pick_a_different_rnc($rnc,$rnc2) if $rnc2;
  if($rnc and $rnc2 and $rnc3)
  {
	my $utran_cell_3,$UtranRelation2,$utranCellRef2,$UtranRelation3,utranCellRef3;
        my $utran_cell_1 = create_UtranCell($rnc,"uarfcnUl 10 uarfcnDl 100");
        test_failed($test_slogan) if not $utran_cell_1;
        return "0" if not $utran_cell_1;
        my $utran_cell_2 = create_UtranCell($rnc2,"uarfcnUl 10 uarfcnDl 100"); 
        test_failed($test_slogan) if not $utran_cell_2;
        return "0" if not $utran_cell_2;
	if($tc_id == 1){
        $utran_cell_3 = create_UtranCell($rnc3,"uarfcnUl 30 uarfcnDl 300");
        test_failed($test_slogan) if not $utran_cell_3;
        return "0" if not $utran_cell_3;  }
##################################### Section 1 #####################################
	log_registry("UtranRelation between two Utrancells of different RNCs...");
	my ($UtranRelation1,$utranCellRef1) = create_UtranRelation( F_UtranCell => $utran_cell_1,S_UtranCell => $utran_cell_2, RNC => "Different");	
	test_failed($test_slogan) if not $UtranRelation1;
	return "0" if not $UtranRelation1;
	if($tc_id == 1){
##################################### Section 2 ##########################################
	log_registry("UtranRelation between two Utrancells of different RNCs and having different-different uarfcnUl and uarfcnDl values...");
	($UtranRelation2,$utranCellRef2) = create_UtranRelation( F_UtranCell => $utran_cell_3,S_UtranCell => $utran_cell_2, RNC => "Different",FREQ => "Different");
	test_failed($test_slogan) if not $UtranRelation2;
	return "0" if not $UtranRelation2;
##################################### Section 3 ###########################################
	log_registry("UtranRelation between two Utrancells of different RNCs and having different-different uarfcnUl and uarfcnDl values...");
	($UtranRelation3,$utranCellRef3) = create_UtranRelation( F_UtranCell => $utran_cell_3,S_UtranCell => $utran_cell_1, RNC => "Different",FREQ => "Different");
        test_failed($test_slogan) if not $UtranRelation3;
        return "0" if not $UtranRelation3;
        test_passed("$test_slogan");  } 
        if ($tc_id == 2) {
                log_registry("Deleting UtranRelation: $UtranRelation1");
                my $status = delete_mo_CLI(mo => $UtranRelation1, base => "CSCLI");
                log_registry("It seems UtranRelation get deleted ..") if ($status eq "OK");
                log_registry("WARNING => There is a problem in deletion of UtranRelation..") if ($status ne "OK");
                log_registry("wait for 2 mins to get system stabilized...");
                sleep 120;
                my $state = does_mo_exist_CLI( base => CSCLI, mo => $UtranRelation1);
                log_registry("UtranRelation $UtranRelation1 get deleted successfully...") if ($state eq "NO");
                log_registry("UtranRelation $UtranRelation1 is not deleted ...") if ($state eq "YES");
                test_failed($test_slogan) if ($status ne "OK" or $state eq "YES");
                test_passed($test_slogan) if ($status eq "OK" and $state eq "NO"); }
################################################# Clean Up ################################################################
	my $clean_issue,$mo;
	$mo = join(" ",$UtranRelation1,$UtranRelation2,$UtranRelation3,$utran_cell_1,$utran_cell_2,$utran_cell_3) if ($tc_id == 1);
	$mo = join(" ",$utran_cell_1,$utran_cell_2) if ($tc_id == 2);
	my @mo = split(" ",$mo);
	foreach(@mo)
	{
		log_registry("Clean up: Deleting MO $_ ");
		$clean_issue = delete_mo_CS( mo => $_);
		log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
	}
  }
  else
  {
        log_registry("It seems no Synched RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT074  # 4.4.1.6.6   eeitjn changed to CSCLI as cli has problems with sequence Refs now
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.6.6 ;Create Mbmscch channel relations to MbmsServiceArea";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne(RncFunction);
  if($rnc)
  {
	my $mbms = pick_a_mo($rnc,Mbms);
	log_registry("It seems no Mbms found under selected RNC: $rnc") if not $mbms;
	test_failed("$test_slogan") if not $mbms;
        return "0" if not $mbms;
	log_registry("Selected Mbms: $mbms");
	my $mbms_sa_1 = pick_a_mo($mbms,MbmsServiceArea);
	my $mbms_sa_2 = pick_a_mo($mbms,MbmsServiceArea);
	log_registry("It seems no MbmsServiceArea exist under selected Mbms MO: $mbms") if not ($mbms_sa_1 and $mbms_sa_2);
	test_failed("$test_slogan") if not ($mbms_sa_1 and $mbms_sa_2);
        return "0" if not ($mbms_sa_1 and $mbms_sa_2);
	$mbms_sa_2 = pick_a_mo($mbms,MbmsServiceArea) if ($mbms_sa_2 =~ /^"$mbms_sa_1"$/);
	log_registry("It seems two different MbmsServiceArea not exist under selected Mbms MO: $mbms") if ($mbms_sa_2 =~ /^"$mbms_sa_1"$/);
	test_failed("$test_slogan") if ($mbms_sa_2 =~ /^"$mbms_sa_1"$/);
        return "0" if ($mbms_sa_2 =~ /^"$mbms_sa_1"$/);		
	my $time = sleep_start_time();
        my $cell = create_UtranCell($rnc);
        log_registry("It seems problem in creation of UtranCell..") if not $cell;
        test_failed($test_slogan) if not $cell;
        return "0" if not $cell;
	long_sleep_found($time);
        my $base_fdn = "$cell".","."MbmsCch=$mo_proxy_cms";
        my $attr_base_fdn = "nonPlMbmsSaRef"." "."$mbms_sa_1"." "."plMbmsSaRef"." "."$mbms_sa_2";
        log_registry("Creating MbmsCch MO under UtranCell $cell");
	$time = sleep_start_time();
        my $status = create_mo_CLI(mo => $base_fdn,base => "CSCLI",attributes => $attr_base_fdn);
        test_failed($test_slogan) if ($status ne "OK");
        return "0" if ($status ne "OK");
	my $nudge_state = nudge_cc_sybase($time);
   	log_registry("It seems CC has not nudged...") if not $nudge_state;
	log_registry("It seems CC has nudged... \n $nudge_state") if $nudge_state;
	long_sleep_found($time) if $nudge_state;
	$status = does_mo_exist_CLI( base => "CSCLI", mo => $base_fdn);
        log_registry("Specified MO => $mo_fdn exist in cs side...") if ($status eq "YES");
        log_registry("Specified MO => $mo_fdn does not exist in cs side........") if ($status ne "YES");
        test_failed("$test_slogan") if ($status ne "YES");
        return "0" if ($status ne "YES");
        my %attrs = get_mo_attributes_CS( mo => $base_fdn,attributes => "nonPlMbmsSaRef plMbmsSaRef nonPlMbmsSac plMbmsSac");
	log_registry("========================================================================================");
	get_mo_attr("$base_fdn","-o nonPlMbmsSaRef plMbmsSaRef nonPlMbmsSac plMbmsSac");
	log_registry("========================================================================================");
	my $flag = 0;
        $flag = 1 if ($attrs{nonPlMbmsSaRef} !~ /$mbms_sa_1/);
        $flag = 1 if ($attrs{plMbmsSaRef} !~ /$mbms_sa_2/);
	$flag = 1 if ($attrs{nonPlMbmsSac} == $attrs{plMbmsSac});
        log_registry("It seems attributes value of MbmsCch is not desired one") if $flag;
        test_failed("$test_slogan") if $flag;
        test_passed("$test_slogan") if not $flag;
    
################################################# Clean Up ################################################################
        log_registry("Clean up: Deleting MbmsCch $base_fdn");
        my $clean_issue = delete_mo_CS( mo => $base_fdn );
        log_registry("Warning => Problem in deletion of MbmsCch.....") if $clean_issue;
	log_registry("Clean up: Deleting UtranCell $cell");
	$clean_issue = delete_mo_CS( mo => $cell );
	log_registry("Warning => Problem in deletion of UtranCell.....") if $clean_issue;
  }
  else
  {
        log_registry("It seems no Synched RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT075  # 4.4.1.6.4
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.6.4 ; Create BothWay Relations(Inter), Create a UtranRelation MO with UtranCells in different N RNC's";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  log_registry("Related Inormation: To perform the Inter UtranRelation,in this test case we are creating 3 brand new UtranCells in which two of them have same uplink and downlink frequency value while another one has different value. these 3 Utrancells are created on 3 different RNC.");
  my $rnc = pick_a_ne(RncFunction);
  my $rnc2 = pick_a_different_rnc($rnc) if $rnc;
  my $rnc3 = pick_a_different_rnc($rnc,$rnc2) if $rnc2;
  if($rnc and $rnc2 and $rnc3)
  {
        my $utran_cell_1 = create_UtranCell($rnc,"uarfcnUl 10 uarfcnDl 100");
        test_failed($test_slogan) if not $utran_cell_1;
        return "0" if not $utran_cell_1;
        my $utran_cell_2 = create_UtranCell($rnc2,"uarfcnUl 10 uarfcnDl 100");
        test_failed($test_slogan) if not $utran_cell_2;
        return "0" if not $utran_cell_2;
        my $utran_cell_3 = create_UtranCell($rnc3,"uarfcnUl 30 uarfcnDl 300");
        test_failed($test_slogan) if not $utran_cell_3;
        return "0" if not $utran_cell_3;
##################################### Section 1 #####################################
        log_registry("Bothway UtranRelations between two Utrancells of different RNCs...");
        my ($UtranRelation1_2,$utranCellRef1_2) = create_UtranRelation( F_UtranCell => $utran_cell_1,S_UtranCell => $utran_cell_2, RNC => "Different");
        test_failed($test_slogan) if not $UtranRelation1_2;
        return "0" if not $UtranRelation1_2;
	my ($UtranRelation2_1,$utranCellRef2_1) = create_UtranRelation( F_UtranCell => $utran_cell_2,S_UtranCell => $utran_cell_1, RNC => "Different");
        test_failed($test_slogan) if not $UtranRelation2_1;
        return "0" if not $UtranRelation2_1;
##################################### Section 2 ##########################################
        log_registry("Bothway UtranRelation between two Utrancells of different RNCs and having different-different uarfcnUl and uarfcnDl values...");
        my ($UtranRelation3_2,$utranCellRef3_2) = create_UtranRelation( F_UtranCell => $utran_cell_3,S_UtranCell => $utran_cell_2, RNC => "Different",FREQ => "Different");
        test_failed($test_slogan) if not $UtranRelation3_2;
        return "0" if not $UtranRelation3_2;
        my ($UtranRelation2_3,$utranCellRef2_3) = create_UtranRelation( F_UtranCell => $utran_cell_2,S_UtranCell => $utran_cell_3, RNC => "Different",FREQ => "Different");
        test_failed($test_slogan) if not $UtranRelation2_3;
        return "0" if not $UtranRelation2_3;
##################################### Section 3 ###########################################
        log_registry("Bothway UtranRelation between two Utrancells of different RNCs and having different-different uarfcnUl and uarfcnDl values...");
        my ($UtranRelation3_1,$utranCellRef3_1) = create_UtranRelation( F_UtranCell => $utran_cell_3,S_UtranCell => $utran_cell_1, RNC => "Different",FREQ => "Different");
        test_failed($test_slogan) if not $UtranRelation3_1;
        return "0" if not $UtranRelation3_1;
        my ($UtranRelation1_3,$utranCellRef1_3) = create_UtranRelation( F_UtranCell => $utran_cell_1,S_UtranCell => $utran_cell_3, RNC => "Different",FREQ => "Different");
        test_failed($test_slogan) if not $UtranRelation1_3;
        return "0" if not $UtranRelation1_3;
	test_passed("$test_slogan");
################################################# Clean Up ################################################################
        my $clean_issue;
        my $mo = join(" ",$UtranRelation1_2,$UtranRelation2_1,$UtranRelation3_2,$UtranRelation2_3,$UtranRelation3_1,$UtranRelation1_3,$utran_cell_1,$utran_cell_2,$utran_cell_3);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
        log_registry("It seems no Synched RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT076  # 4.4.1.6.5
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.6.5 ; Create Relation, Create a UtranRelation MO with ExternalUtranCells in N RNC's";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  log_registry("Related Inormation: To perform the Intra UtranRelation,in this test case we are creating 2 brand new UtranCells and using 1 existing ExternalUtranCell. UtranCells have different uplink and downlink frequency value");
  my $rnc = pick_a_ne(RncFunction);
  if($rnc)
  {
        my ($count,@EUC_FDN) = get_CMS_mo("ExternalUtranCell");
        my $EUC; my @EUC;
        if ($count) {
                foreach(@EUC_FDN) {
                        push(@EUC,$_) if($_ !~ /MeContext\=/); } }
        $count = scalar(@EUC);
        log_registry("Total count of master ExternalUtranCell is: $count");
        log_registry("It seems no master ExternalUtranCell exist.") if not $count;
        test_failed($test_slogan) if not $count;
        return "0" if not $count;
        $count = int(rand($count));
        $EUC = $EUC[$count]; $EUC =~ s/\n+//g;
	my %attrs = get_mo_attributes_CS( mo => $EUC, attributes => "uarfcnUl uarfcnDl");
	my $uarfcnUl = $attrs{uarfcnUl};
	my $uarfcnDl = $attrs{uarfcnDl};
	log_registry("Selected ExternalUtranCell is : $EUC and its attribite uarfcnUl uarfcnDl values are $uarfcnUl and $uarfcnDl respectively");	
	test_failed($test_slogan) if not ($uarfcnUl and $uarfcnDl);
	return "0" if not ($uarfcnUl and $uarfcnDl);	
        my $utran_cell_1 = create_UtranCell($rnc,"uarfcnUl $uarfcnUl uarfcnDl $uarfcnDl");
        test_failed($test_slogan) if not $utran_cell_1;
        return "0" if not $utran_cell_1;
	my $uarfcnUl2 = int(rand(16380));
	my $uarfcnDl2 = int(rand(16380));
	$uarfcnUl2 = int(rand(16380)) if ($uarfcnUl == $uarfcnUl2);
	$uarfcnDl2 = int(rand(16380)) if ($uarfcnDl == $uarfcnDl2);
        my $utran_cell_2 = create_UtranCell($rnc,"uarfcnUl $uarfcnUl2 uarfcnDl $uarfcnDl2");
        test_failed($test_slogan) if not $utran_cell_2;
        return "0" if not $utran_cell_2;
##################################### Section 1 #####################################
        log_registry("UtranRelation between Utrancell and ExternalUtranCell having same uarfcnUl and uarfcnDl frequency...");
        my ($UtranRelation1,$utranCellRef1) = create_UtranRelation( F_UtranCell => $utran_cell_1,EUC => $EUC,RNC => "Different");
        test_failed($test_slogan) if not $UtranRelation1;
        return "0" if not $UtranRelation1;
##################################### Section 2 ##########################################
        log_registry("UtranRelation between Utrancell and ExternalUtranCell having different-different uarfcnUl and uarfcnDl values...");
        my ($UtranRelation2,$utranCellRef2) = create_UtranRelation( F_UtranCell => $utran_cell_2,EUC => $EUC,FREQ => "Different",RNC => "Different");
        test_failed($test_slogan) if not $UtranRelation2;
        return "0" if not $UtranRelation2;
	test_passed($test_slogan);
################################################# Clean Up ################################################################
        my $clean_issue;
        my $mo = join(" ",$UtranRelation1,$UtranRelation2,$utran_cell_1,$utran_cell_2);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
        log_registry("It seems no Synched RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT077  # 4.4.1.7.2, 4.4.2.3.2 and 4.4.2.3.3
{
  my $test_slogan = $_[0];
  my $tc_id,$tc_info;
  $tc_id = 1 if($test_slogan =~ /4\.4\.1\.7\.2/);
  $tc_id = 2 if($test_slogan =~ /4\.4\.2\.3\.2/);
  $tc_id = 3 if($test_slogan =~ /4\.4\.2\.3\.3/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.7.2 ; Create UtranFreqRelation with the adjacentFreq attribute set to sn ExternalUtranFreq in the SubNetwork MIB from an application" if($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.2.3.2 ; Set Proxy MO - Set   UtranFrequency attribute arfcnValueUtranDl to Non-Existing Master ExternalUtranFreq Value" if($tc_id == 2);
  $tc_info = "WRANCM_CMSSnad_4.4.2.3.3 ; Set Proxy MO - Set   UtranFrequency attribute arfcnValueUtranDl to a different already existing Master ExternalUtranFreq Value" if($tc_id == 3);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD);
  if($ERBS)
  {
	my $new_master;
        my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
        my ($EUF_fdn,$EUF_attr) = get_fdn("ExternalUtranFreq","create");
        log_registry("Please wait master ExternalUtranFreq MO $EUF_fdn is getting created....");
        my $result = mo_create_decision("0",$EUF_fdn,$EUF_attr,"","wait for consistent");
	$result = master_for_proxy_handle("0",$EUF_fdn,$EUF_attr,"","wait for consistent") if($result and $result eq "KO");
        log_registry("Problem in creation of ExternalUtranFreq MO.....") if not $result;
        test_failed($test_slogan) if not $result;
        return "0" if not $result;
        my ($UFR_fdn,$UF_fdn) = create_UtranFreqRelation(EUCFDD => $EUCFDD,EUF => $EUF_fdn);
        log_registry("It seems there is some problem in creation of UtranFreqRelation ...") if not $UFR_fdn;
	test_failed($test_slogan) if not $UFR_fdn;
        return "0" if not $UFR_fdn;
	test_passed("$test_slogan") if ($tc_id == 1);
	if($tc_id != 1)
	{
		my $flag = 0;
	        my ($NEW_EUF_fdn,$NEW_EUF_attr) = get_fdn("ExternalUtranFreq","set") if ($tc_id == 3);
	        log_registry("Please wait new master ExternalUtranFreq MO $NEW_EUF_fdn is getting created.") if($tc_id == 3);
	        $result = mo_create_decision("0",$NEW_EUF_fdn,$NEW_EUF_attr) if($tc_id == 3);
		$result = master_for_proxy_handle("0",$NEW_EUF_fdn,$NEW_EUF_attr) if($tc_id == 3 and $result and $result eq "KO");
	        log_registry("Problem in creation of ExternalUtranFreq MO.....") if (($tc_id == 3) and !($result));
	        test_failed($test_slogan) if (($tc_id == 3) and !($result));
		return "0" if (($tc_id == 3) and !($result));
		my ($fdn,$attrs) = get_fdn("dLUtranFrequency","set");
	        my ($status,$rev_id) = proxy_mo_set_decision("CLI",$UF_fdn,$attrs,"FN");
		log_registry("It seems proxy mo is not consistent after setting attribute.") if($status and ($rev_id != 1));
	        test_failed($test_slogan) if (!($status) or($rev_id != 1));
	        if ($status and ($rev_id == 1))		{
			$new_master = get_master_for_proxy($UF_fdn);
			$flag = 1 if(!($new_master) or ($new_master =~ /$EUF_fdn$/));
			$flag = 1 if(($tc_id == 3) and (!($new_master) or ($new_master !~ /$NEW_EUF_fdn$/)));
			log_registry("It seems no new master ExternalUtranFreq mo get created...") if $flag;
			$new_master =~ s/\n+//g if not $flag;
			log_registry("new Master for Proxy UtranFrequency is: $new_master") if not $flag;
			log_registry("=============================================================")if not $flag;
			get_mo_attr($new_master) if not $flag;
			log_registry("=============================================================")if not $flag;
			test_failed($test_slogan) if $flag;
			test_passed("$test_slogan") if not $flag;	}
	}
################################################# Clean Up ################################################################
        my $clean_issue,$mo;
        $mo = join(" ",$UFR_fdn,$UF_fdn,$EUF_fdn) if($tc_id == 1);
        $mo = join(" ",$UFR_fdn,$UF_fdn,$EUF_fdn,$new_master) if($tc_id != 1);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
  }
  else
  {
        log_registry("It seems no Synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT078  # 4.4.1.7.3
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.7.3 ; Create UtranFreqRelation with the adjacentFreq attribute set to sn ExternalUtranFreq in the SubNetwork MIB from an application. Create with already existing";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD);
  if($ERBS)
  {
        my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
	my ($count,@EUF_fdn) = get_CMS_mo("ExternalUtranFreq");
	my $EUF_fdn = $EUF_fdn[0] if $count;
	log_registry("It seems there is no existing ExternalUtranFreq type master MO...") if not $count;
	test_failed($test_slogan) if not $count;
        return "0" if not $count;
	my ($UFR_fdn,$UF_fdn) = create_UtranFreqRelation(EUCFDD => $EUCFDD,EUF => $EUF_fdn);
	log_registry("It seems there is some problem in creation of UtranFreqRelation ...") if not $UFR_fdn;
	test_failed($test_slogan) if not $UFR_fdn;	return "0" if not $UFR_fdn;
        test_passed("$test_slogan");
################################################# Clean Up ################################################################
        log_registry("Clean up: Deleting MO $UFR_fdn ");
        my $clean_issue = delete_mo_CS( mo => $UFR_fdn );
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
  }
  else
  {
        log_registry("It seems no Synched ERBS found...");
        test_failed($test_slogan);
  }
}



sub FUT079 # 4.4.1.7.4
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.7.4 ; Create UtranFreqRelation MO under 2 different EUtranCellFDDs with the adjacentFreq attribute set to sn ExternalUtranFreq in the SubNetwork MIB from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
my $ERBS ="";
 
#### To select ERBS with more than 2 cells ########### 
   for(my $i=1;$i<5;$i++)
   {
     $ERBS = pick_a_ne("ENodeBFunction","EUtranCellFDD");
  #  log_registry("xxxx Iteration $i xxx $ERBS");
     my ($count,@EUF) = select_mo_cs( MO => "EUtranCellFDD", KEY => $ERBS);
  #  log_registry("xxxx count is $count xxxxx"); 
     last if ($count > 2);
   }

  if($ERBS)
  {
        my $flag = 0;
        my $EUCFDD1 = pick_a_mo($ERBS,EUtranCellFDD);
        my $EUCFDD2 = pick_a_mo($ERBS,EUtranCellFDD);
        my $loop = 0;
	while ($EUCFDD1 eq $EUCFDD2){
                $loop = $loop + 1;
		$EUCFDD2 = pick_a_mo($ERBS,EUtranCellFDD);
		last if ($loop > 10);
	}
        # $EUCFDD2 = pick_a_mo($ERBS,EUtranCellFDD) if ($EUCFDD2 =~ /$EUCFDD1/);
        $flag = 1 if (!($EUCFDD1) or !($EUCFDD2) or $EUCFDD1 =~/$EUCFDD2/);
        log_registry("It seems no two different EUtranCellFDD has been found under ERBS ..") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
        my ($EUF_fdn,$EUF_attr) = get_fdn("ExternalUtranFreq","create");
        log_registry("Please wait master ExternalUtranFreq MO $EUF_fdn is getting created....");
        my $result = mo_create_decision("0",$EUF_fdn,$EUF_attr,"","wait for consistent");
	$result = master_for_proxy_handle("0",$EUF_fdn,$EUF_attr,"","wait for consistent") if ($result and $result eq "KO");
        log_registry("Problem in creation of ExternalUtranFreq MO.....") if not $result;
        test_failed($test_slogan) if not $result;
        return "0" if not $result;
	my ($UFR_fdn1,$UF_fdn1)  = create_UtranFreqRelation(EUCFDD => $EUCFDD1,EUF => $EUF_fdn);
	log_registry("It seems there is some problem in creation of UtranFreqRelation ...") if not $UFR_fdn1;
	test_failed($test_slogan) if not $UFR_fdn1;
        return "0" if not $UFR_fdn1;
	my ($UFR_fdn2,$UF_fdn2) = create_UtranFreqRelation(EUCFDD => $EUCFDD2,EUF => $EUF_fdn, X_UFR => $UFR_fdn1);
	log_registry("It seems there is some problem in creation of another UtranFreqRelation ...") if not $UFR_fdn2;
	test_failed($test_slogan) if not $UFR_fdn2;
        return "0" if not $UFR_fdn2;		
        test_passed("$test_slogan");
################################################# Clean Up ################################################################
        my $clean_issue;
        my $mo = join(" ",$UFR_fdn2,$UFR_fdn1,$UF_fdn1,$UF_fdn2,$EUF_fdn);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
        log_registry("It seems no Synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT080 # 4.4.1.7.5
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.7.5 ; Create  with the utranFrequencyRef attribute set to UtranFrequency through the EM (netsim). Create with a existing UtranFrequency";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  # my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD);
  my $ERBS ="";
 
  #### To select ERBS with more than 2 cells ########### 
  for(my $i=1;$i<5;$i++)
  {
     $ERBS = pick_a_ne("ENodeBFunction","EUtranCellFDD");
     #  log_registry("xxxx Iteration $i xxx $ERBS");
     my ($count,@EUF) = select_mo_cs( MO => "EUtranCellFDD", KEY => $ERBS);
     #  log_registry("xxxx count is $count xxxxx"); 
     last if ($count > 2);
  }
  if($ERBS)
  {
	my $flag = 0;
        my $EUCFDD1 = pick_a_mo($ERBS,EUtranCellFDD);
	my $EUCFDD2 = pick_a_mo($ERBS,EUtranCellFDD);
 	my $loop = 0;
        while ($EUCFDD1 eq $EUCFDD2){
		$loop = $loop + 1;
		$EUCFDD2 = pick_a_mo($ERBS,EUtranCellFDD);
		last if ($loop > 10);
	}
	# $EUCFDD2 = pick_a_mo($ERBS,EUtranCellFDD) if ($EUCFDD2 =~ /$EUCFDD1/);
	$flag = 1 if ($EUCFDD2 =~ /$EUCFDD1/);
	log_registry("It seems two different cells have not picked under ERBS...") if $flag;
	test_failed($test_slogan) if $flag;
	return "0" if $flag;
	my $UtraNW = pick_a_mo($ERBS,UtraNetwork);
	log_registry("It seems there is no UtraNetwork under the ERBS....") if not $UtraNW;
	test_failed("$test_slogan") if not $UtraNW;
	return "0" if not $UtraNW; 
	my ($UF,$UF_attr) = get_fdn("UtranFrequency","create");
	$UF = base_fdn_modify($UtraNW,$UF);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$UF,$UF_attr,"no wait");
        test_failed($test_slogan) if not ($status and $rev_id);
        return "0" if not ($status and $rev_id);
        my ($UFR_fdn1,$UF_fdn1,$EUF)  = create_UtranFreqRelation(EUCFDD => $EUCFDD1,UF => $UF, base => CLI);
        log_registry("It seems there is some problem in creation of UtranFreqRelation ...") if not $UFR_fdn1;
        test_failed($test_slogan) if not $UFR_fdn1;
        return "0" if not $UFR_fdn1;
	my $master_mo = get_master_for_proxy($UF);
	$flag = 1 if($master_mo !~ /$EUF/);
	log_registry("It seems created proxy $UF does not have $EUF as master") if $flag;
	test_failed($test_slogan) if $flag;
	return "0" if $flag;	
	log_registry("Existing Master ExternalUtranFreq Mo for $UF is : $EUF");
        my ($UFR_fdn2,$UF_fdn2,$T_EUF)  = create_UtranFreqRelation(EUCFDD => $EUCFDD2,UF => $UF, base => CLI);
        log_registry("It seems there is some problem in creation of UtranFreqRelation ...") if not $UFR_fdn2;
	$flag = 1 if($T_EUF !~ /$EUF/);
	log_registry("It seems Master ExternalUtranFreq Mo for $UF does not match with $EUF") if $flag;
        test_failed($test_slogan) if (!($UFR_fdn2) or $flag);
        return "0" if (!($UFR_fdn2) or $flag);
        test_passed("$test_slogan");
################################################# Clean Up ################################################################
        my $clean_issue;
	$EUF = "" if ($EUF !~ /$mo_proxy_cms/);
        my $mo = join(" ",$UFR_fdn1,$UFR_fdn2,$UF,$EUF);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
        log_registry("It seems no Synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT081 # 4.4.1.7.6
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.7.6 ; Create UtranFreqRelation with the utranFrequencyRef attribute set to UtranFrequency through the EM (netsim). Create with non existing UtranFrequency";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD);
  if($ERBS)
  {
        my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
        my $UtraNW = pick_a_mo($ERBS,UtraNetwork);
        log_registry("It seems there is no UtraNetwork under the ERBS....") if not $UtraNW;
        test_failed("$test_slogan") if not $UtraNW;
        return "0" if not $UtraNW;
	my ($UF,$UF_attr) = get_fdn("UtranFrequency","create");
	$UF = base_fdn_modify($UtraNW,$UF);
	my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$UF,$UF_attr,"no wait");
	test_failed($test_slogan) if not ($status and $rev_id);
	return "0" if not ($status and $rev_id);
        my ($UFR_fdn,$UF_fdn)  = create_UtranFreqRelation(EUCFDD => $EUCFDD,UF => $UF, base => CLI);
        log_registry("It seems there is some problem in creation of UtranFreqRelation ...") if not $UFR_fdn;
        test_failed($test_slogan) if not $UFR_fdn;
        return "0" if not $UFR_fdn;
        test_passed("$test_slogan");
################################################# Clean Up ################################################################
	my $master_mo = get_master_for_proxy($UF_fdn);
        my $clean_issue;
        my $mo = join(" ",$UFR_fdn,$UF_fdn,$master_mo);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }

  }
  else
  {
        log_registry("It seems no Synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT082 # 4.4.1.6.14 and 4.4.3.6.3
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.1\.6\.14/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.3\.6\.3/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.6.14 ; Create EutranFreqRelation MO in RNC MIB with the adjacentFreq attribute set to sn ExternalEutranFrequency " if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.3.6.3 ; Delete EutranFreqRelation MO under UtranCell" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne("RncFunction","NEW");
  if($rnc)
  {
        my ($EEF_fdn, $EEF_attr) = get_fdn("ExternalEutranFrequency","create");
        log_registry("FDN is $EEF_fdn, attributes are : $EEF_attr");
        my ($EEF_result,$rev_id) = proxy_mo_create_decision("CSCLI",$EEF_fdn,$EEF_attr,"nowait");

#	my ($EEF_fdn,$EEF_attr) = get_fdn("ExternalEutranFrequency","create");
#	my $EEF_result = mo_create_decision("0",$EEF_fdn,$EEF_attr,"","wait for consistent");
#	$EEF_result = master_for_proxy_handle("0",$EEF_fdn,$EEF_attr,"","wait for consistent");
#	log_registry("There is problem in creation of master ExternalEutranFrequency MO...") if not $EEF_result;
#	test_failed($test_slogan) if not $EEF_result;
#	return "0" if not $EEF_result;
	my $utran_cell = create_UtranCell($rnc,"uarfcnUl 10 uarfcnDl 2100");
        test_failed($test_slogan) if not $utran_cell;
        return "0" if not $utran_cell;
        log_registry("Selected UtranCell for EutranFreqRelation is: $utran_cell");
	log_registry("Wait for 2 Mins to get system stabilized....");
	sleep 120;
	my ($EFR_fdn,$EF_proxy) = create_EutranFreqRelation(UC => $utran_cell, EEF => $EEF_fdn);
	log_registry("It seems there is some problem in creation of ExternalEutranFreqRelation ...") if not $EFR_fdn;
        test_failed($test_slogan) if not $EFR_fdn;
        return "0" if not $EFR_fdn;
        test_passed("$test_slogan") if ($tc_id == 1);
	if ($tc_id == 2)
	{
		log_registry("Deleting EutranFreqRelation : $EFR_fdn");
		my $status = delete_mo_CLI(mo => $EFR_fdn, base => "CSCLI");
		log_registry("It seems EutranFreqRelation get deleted ..") if ($status eq "OK");
		log_registry("WARNING => There is a problem in deletion of EutranFreqRelation..") if ($status ne "OK");
		log_registry("wait for 2 mins to get system stabilized...");
		sleep 120;		
		my $state = does_mo_exist_CLI( base => CSCLI, mo => $EFR_fdn);
		log_registry("EutranFreqRelation $EFR_fdn get deleted successfully...") if ($state eq "NO");
		log_registry("EutranFreqRelation $EFR_fdn is not deleted ...") if ($state eq "YES");
		test_failed($test_slogan) if ($status ne "OK" or $state eq "YES");
		test_passed($test_slogan) if ($status eq "OK" and $state eq "NO");
	}
################################################# Clean Up ################################################################
	my $clean_issue,$mo;
       	$mo = join(" ",$EFR_fdn,$EF_proxy,$utran_cell,$EEF_fdn) if ($tc_id == 1);
	$mo = join(" ",$EF_proxy,$utran_cell,$EEF_fdn) if ($tc_id == 2);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
          	log_registry("Clean up: Deleting MO $_ ");
               	$clean_issue = delete_mo_CS( mo => $_);
               	log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
        log_registry("It seems no Synched RNC found having version vS or later...Or check theb sub node_version in Common.pm is correct");
        test_failed($test_slogan);
  }
}

sub FUT083 # 4.4.1.6.15
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.6.15 ; Create EutranFreqRelation MO in RNC MIB, with the externalEutranFreq attribute set to sn ExternalEutranFrequency in the SubNetwork MIB from an application. Create with already existing EutraNetwork MO and EutranFrequency MO on RNC MIB";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne("RncFunction","NEW");
  if($rnc)
  {
        my ($count,@EEF_FDN) = get_CMS_mo("ExternalEutranFrequency"); 
        log_registry("It seems there is no pre-existing master ExternalEutranFrequency MO...") if not $count;
	log_registry("Till the time simulation do not have ExternalEutranFrequency/EutranFrequency/EutraNetwork MO...") if not $count;
	log_registry("So please focus on 4.4.1.6.14 test case result for time being...") if not $count;
        test_failed($test_slogan) if not $count;
        return "0" if not $count;
	my $EEF_fdn = $EEF_FDN[0];
        my $utran_cell = create_UtranCell($rnc,"uarfcnUl 10 uarfcnDl 2100");
        test_failed($test_slogan) if not $utran_cell;
        return "0" if not $utran_cell;
        log_registry("Selected UtranCell for EutranFreqRelation is: $utran_cell");
        log_registry("Wait for 2 Mins to get system stabilized....");
        sleep 120;
        my ($EFR_fdn,$EF_proxy) = create_EutranFreqRelation(UC => $utran_cell, EEF => $EEF_fdn);
        log_registry("It seems there is some problem in creation of ExternalEutranFreqRelation ...") if not $EFR_fdn;
        test_failed($test_slogan) if not $EFR_fdn;
        return "0" if not $EFR_fdn;
        test_passed("$test_slogan");
################################################# Clean Up ################################################################
        my $clean_issue;
        my $mo = join(" ",$EFR_fdn,$utran_cell);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
               log_registry("Clean up: Deleting MO $_ ");
               $clean_issue = delete_mo_CS( mo => $_);
               log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
        log_registry("It seems no Synched RNC found having version vS or later...Or check theb sub node_version in Common.pm is correct");
        test_failed($test_slogan);
  }
}

sub FUT084 # 4.4.1.6.16
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.6.16 ; Create EutranFreqRelation MOs under 2 different UtranCells with the externalEutranFreq attribute set to sn ExternalEutranFrequency";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
#  my $rnc = pick_a_ne("RncFunction","NEW");


  my $rnc = "SubNetwork=ONRM_ROOT_MO_R,SubNetwork=RNC06,MeContext=RNC06,ManagedElement=1,RncFunction=1";
  delete_mo_thats_reserved($rnc.",EutraNetwork=4,EutranFrequency=2");
  delete_mo_thats_reserved($rnc.",EutraNetwork=4,EutranFrequency=1");
  delete_mo_thats_reserved($rnc.",EutraNetwork=4");

  if($rnc)
  {
        my ($EEF_fdn,$EEF_attr) = get_fdn("ExternalEutranFrequency","create");

        my ($EEF_result,$rev_id) = proxy_mo_create_decision("CSCLI",$EEF_fdn,$EEF_attr,"nowait");
        log_registry("EEF_result $EEF_result   ,    $rev_id ");
 
        log_registry("There is problem in creation of master ExternalEutranFrequency MO...") if not $EEF_result;
        test_failed($test_slogan) if not $EEF_result;
        return "0" if not $EEF_result;
        my $utran_cell1 = create_UtranCell($rnc,"uarfcnUl 10 uarfcnDl 2100");
        test_failed($test_slogan) if not $utran_cell1;
        return "0" if not $utran_cell1;
	my $utran_cell2 = create_UtranCell($rnc,"uarfcnUl 20 uarfcnDl 2200");
        test_failed($test_slogan) if not $utran_cell2;
        return "0" if not $utran_cell2;
        log_registry("Selected UtranCell for EutranFreqRelations are: $utran_cell1 and $utran_cell2");
        log_registry("Wait for 2 Mins to get system stabilized....");
        sleep 120;
        my ($EFR_fdn1,$EF_proxy1) = create_EutranFreqRelation(UC => $utran_cell1, EEF => $EEF_fdn);
        log_registry("It seems there is some problem in creation of ExternalEutranFreqRelation ...") if not $EFR_fdn1;
        test_failed($test_slogan) if not $EFR_fdn1;
        return "0" if not $EFR_fdn1;
	my ($EFR_fdn2,$EF_proxy2) = create_EutranFreqRelation(UC => $utran_cell2, EEF => $EEF_fdn, X_EFR => $EFR_fdn1);	
	log_registry("It seems there is some problem in creation of ExternalEutranFreqRelation ...") if not $EFR_fdn2;
	test_failed($test_slogan) if not $EFR_fdn2;
	return "0" if not $EFR_fdn2;
        test_passed("$test_slogan");
################################################# Clean Up ################################################################
        my $clean_issue;
#       my $mo = join(" ",$EFR_fdn1,$EFR_fdn2,$EF_proxy1,$EF_proxy2,$utran_cell1,$utran_cell2,$EEF_fdn);

        my $mo = join(" ",$EFR_fdn1,$EFR_fdn2,$utran_cell1,$utran_cell2);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
               log_registry("Clean up: Deleting MO $_ ");
               $clean_issue = delete_mo_CS( mo => $_);
               log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
        log_registry("It seems no Synched RNC found having version vS or later...Or check theb sub node_version in Common.pm is correct");
        test_failed($test_slogan);
  }
}

sub FUT085 # 4.4.1.6.17
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.6.17 ; Create EutranFreqRelation MO with the eutranFrequencyRef attribute set to proxy EutranFrequency through the EM/netsim where master ExternalEutranFrequency mo exist";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
#  my $rnc = pick_a_ne("RncFunction","NEW");

  my ($EEF_fdn,$EEF_attr) = get_fdn("ExternalEutranFrequency","create");
  log_registry("*** Warning 4.4.1.6.16 must be run first as it creates MO's need in this TC ***");

  my $rnc = "SubNetwork=ONRM_ROOT_MO_R,SubNetwork=RNC06,MeContext=RNC06,ManagedElement=1,RncFunction=1";

  if($rnc)
  {
	my ($count,@EUF_FDN) = get_CMS_mo("EutranFrequency",$mo_proxy_cms);
	log_registry("here it is .. $EUF_FDN[0]");
	if(!($EUF_FDN[0]))
	{
		log_registry("There is no pre existing EutranFrequency=CMSAUTOPROXY_1..");
		test_failed($test_slogan);
		return "0";
	}
	my $utran_cell = create_UtranCell($rnc,"uarfcnUl 10 uarfcnDl 2100");
        test_failed($test_slogan) if not $utran_cell;
        return "0" if not $utran_cell;
        log_registry("Selected UtranCell for EutranFreqRelation is: $utran_cell");
        log_registry("Wait for 2 Mins to get system stabilized....");
        sleep 120;
        my ($EFR_fdn,$EF_proxy) = create_EutranFreqRelation(UC => $utran_cell, EF => $EUF_FDN[0], base => "CLI");
        log_registry("It seems there is some problem in creation of EutranFreqRelation ...") if not $EFR_fdn;
        test_failed($test_slogan) if not $EFR_fdn;
        test_passed("$test_slogan") if $EFR_fdn;

################################################# Clean Up ################################################################
        my $clean_issue;
        my $EutraNetwork = remove_rdn($EUF_FDN[0]);
        my $mo = join(" ",$EFR_fdn,$utran_cell,$EEF_fdn,$EutraNetwork);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
               log_registry("Clean up: Deleting MO $_ ");
               $clean_issue = delete_mo_CS( mo => $_);
               log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
        log_registry("It seems no Synched RNC found having version vS or later...Or check theb sub node_version in Common.pm is correct");
        test_failed($test_slogan);
  }
}

sub FUT086 # 4.4.1.6.18
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.6.18 ; Create EutranFreqRelation MO with the eutranFrequencyRef attribute set to proxy EutranFrequency through the EM/netsim where master ExternalEutranFrequency mo does not exist";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = "SubNetwork=ONRM_ROOT_MO_R,SubNetwork=RNC06,MeContext=RNC06,ManagedElement=1,RncFunction=1";

  if($rnc)
  {

        my ($EF_fdn,$EF_attr) = get_fdn("EutranFrequency","create");
        my $EutraNW = pick_a_mo($rnc,"EutraNetwork");
        
        $EF_fdn = base_fdn_modify("$EutraNW","$EF_fdn");
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$EF_fdn,$EF_attr,"no wait");
        test_failed($test_slogan) if not $status;
        return "0" if not $status;

	my $utran_cell = create_UtranCell($rnc,"uarfcnUl 10 uarfcnDl 2100");
        test_failed($test_slogan) if not $utran_cell;
        return "0" if not $utran_cell;
        log_registry("Selected UtranCell for EutranFreqRelation is: $utran_cell");
        log_registry("Wait for 2 Mins to get system stabilized....");
        sleep 120;
        my ($EFR_fdn,$EF_proxy) = create_EutranFreqRelation(UC => $utran_cell, EF => $EF_fdn, base => "CLI");
        log_registry("It seems there is some problem in creation of ExternalEutranFreqRelation ...") if not $EFR_fdn;
        test_failed($test_slogan) if not $EFR_fdn;
        return "0" if not $EFR_fdn;
        test_passed("$test_slogan");
############################################ Clean Up#############################################################
        my $clean_issue;
	my $master_mo = get_master_for_proxy($EF_fdn);
        my $mo = join(" ",$EFR_fdn,$EF_proxy,$utran_cell,$master_mo);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
               log_registry("Clean up: Deleting MO $_ ");
               $clean_issue = delete_mo_CS( mo => $_);
               log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
        log_registry("It seems no Synched RNC found having version vS or later...Or check theb sub node_version in Common.pm is correct");
        test_failed($test_slogan);
  }
}

sub FUT087 # 4.4.1.3.14 and 4.4.3.6.8
{
  my $test_slogan = $_[0];
  my $tc_id,$tc_info;
  $tc_id = 1 if ( $test_slogan =~ /4\.4\.1\.3\.14/);
  $tc_id = 2 if ( $test_slogan =~ /4\.4\.3\.6\.8/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.3.14; Create UtranCellRelation between EUtranCellFDD/TDD and ExternalUtranCell when UtraNetwork is created on ERBS" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.3.6.8; Delete UtranCellRelation that exists between EUtranCellFDD/TDD and ExternalUtranCell" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS_FDD = pick_a_erbs_using_cell(CELL => "EUtranCellFDD", VER => "NEW");
  my $ERBS_TDD = pick_a_erbs_using_cell(CELL => "EUtranCellTDD", VER => "NEW");
  if($ERBS_FDD and $ERBS_TDD)
  {
        my $EUtranCellFDD = pick_a_mo("$ERBS_FDD","EUtranCellFDD");
        my $EUtranCellTDD = pick_a_mo("$ERBS_TDD","EUtranCellTDD");;
        log_registry("It seems any of EUtranCellFDD/EUtranCellTDD cell exist under ERBS...") if not ($EUtranCellFDD and $EUtranCellTDD);
        test_failed($test_slogan) if not ($EUtranCellFDD and $EUtranCellTDD);
        return "0" if not ($EUtranCellFDD and $EUtranCellTDD);
	my ($EUF,$attrs_EUF) = get_fdn("ExternalUtranFreq","create");
	my $EUF_result = mo_create_decision("0",$EUF,$attrs_EUF,"","wait for consistent");
	$EUF_result = master_for_proxy_handle("0",$EUF,$attrs_EUF,"","wait for consistent") if($EUF_result and $EUF_result eq "KO");
	log_registry("There is a problem in creation of ExternalUtranFreq MO ...") if not $EUF_result;
	test_failed($test_slogan) if not $EUF_result;
	return "0" if not $EUF_result;
	my ($EUC,$attrs_EUC) = get_fdn("MasterExternalUtranCell","create");
	my ($EUP_exist,@EUP_FDN) = get_CMS_mo("ExternalUtranPlmn");
	my $EUP_FDN = $EUP_FDN[0] if $EUP_exist;
	log_registry("It seems there is no ExternalUtranPlmn Exist ....") if not $EUP_exist;
	test_failed($test_slogan) if not $EUP_exist;
	return "0" if not $EUP_exist;
	log_registry("Selected UtranPlmn : $EUP_FDN");
	my %attrs_EUP = get_mo_attributes_CS( mo => $EUP_FDN, attributes => "mcc mnc mncLength");
#	my $flag = 0;
#	$flag = 1 if not ($attrs_EUP{mcc} and $attrs_EUP{mnc} and $attrs_EUP{mncLength});
#	log_registry("It seems any of mcc/mnc/mncLength attribute of ExternalUtranPlmn is missing...") if $flag; 
#	test_failed($test_slogan) if $flag;
#	return "0" if $flag;
        $EUP_FDN =~ s/\n//g;
	$attrs_EUC = "$attrs_EUC"." "."$EUP_FDN";
	$attrs_EUC = "$attrs_EUC"." "."mnc $attrs_EUP{mnc} mcc $attrs_EUP{mcc} mncLength $attrs_EUP{mncLength}";
	$attrs_EUC =~ s/\n//g;
	my $EUC_result = mo_create_decision("0",$EUC,$attrs_EUC,"","wait for consistent");
	$EUC_result = master_for_proxy_handle("0",$EUC,$attrs_EUC,"","wait for consistent") if($EUC_result and $EUC_result eq "KO");
	log_registry("There is a problem in creation of Master ExternalUtranCell MO ...") if not $EUC_result;
	test_failed($test_slogan) if not $EUC_result;
	return "0" if not $EUC_result;
	my ($TDD_UFR,$UF_fdn1) = create_UtranFreqRelation(EUCTDD => "$EUtranCellTDD",EUF=>"$EUF",base => "CSCLI");
	log_registry("It seems there is a problem in creation of UtranFreqRelation with EUtranCellTDD..") if not $TDD_UFR;
	test_failed($test_slogan) if not $TDD_UFR;
	return "0" if not $TDD_UFR;
	my ($FDD_UFR,$UF_fdn2) = create_UtranFreqRelation(EUCFDD => "$EUtranCellFDD",EUF=>"$EUF",base => "CSCLI");
	log_registry("It seems there is a problem in creation of UtranFreqRelation with EUtranCellFDD..") if not $FDD_UFR;
        test_failed($test_slogan) if not $FDD_UFR;
        return "0" if not $FDD_UFR;
	my ($UCR_fdn1,$P_EUC1) = create_UtranCellRelation(UFR => "$TDD_UFR",EUC => "$EUC");
	log_registry("It seems there is a problem in creation of UtranCellRelation with EUtranCellTDD..") if not $UCR_fdn1;
        test_failed($test_slogan) if not $UCR_fdn1;
        return "0" if not $UCR_fdn1;
	my ($UCR_fdn2,$P_EUC2) = create_UtranCellRelation(UFR => "$FDD_UFR",EUC => "$EUC");
        log_registry("It seems there is a problem in creation of UtranCellRelation with EUtranCellFDD..") if not $UCR_fdn2;
        test_failed($test_slogan) if not $UCR_fdn2;
        return "0" if not $UCR_fdn2;
        test_passed($test_slogan) if ($tc_id == 1);
	if ($tc_id == 2)
	{
		my $flag = 0;
		log_registry("Deleting UtranCellRelation between EUtranCellFDD and ExternalUtranCell...");
		$flag = proxy_mo_delete_decision("0","CSCLI","$UCR_fdn2","Relation");
		log_registry("Issue in deletion of UtranCellRelation b/w EUtranCellFDD and ExternalUtranCell") if not $flag;
		test_failed("$test_slogan") if not $flag;
		return "0" if not $flag;
		log_registry("Deleting UtranCellRelation between EUtranCellTDD and ExternalUtranCell...");
		$flag = proxy_mo_delete_decision("0","CSCLI","$UCR_fdn1","Relation");
		log_registry("Issue in deletion of UtranCellRelation b/w EUtranCellTDD and ExternalUtranCell") if not $flag;
		test_failed("$test_slogan") if not $flag;
		return "0" if not $flag;
		my $force_nudge = forceCC($P_EUC1);
		long_sleep_found($force_nudge) if $force_nudge;
		my $review_cache_log = cache_file();
   		my ($rev_id_1,$rev_log_1) = rev_find(file => $review_cache_log,mo => $P_EUC1);
		my ($rev_id_2,$rev_log_2) = rev_find(file => $review_cache_log,mo => $P_EUC2);
		$flag = 2 if ( $rev_id_1 != 7 or $rev_id_2 != 7);
		log_registry("It seems Proxy ExternalUtranCellFDD are not in Redundant Proxy state...") if ($flag == 2);
		test_failed("$test_slogan") if ($flag == 2);
		test_passed("$test_slogan") if ($flag != 2);
################################ Clean up #######################################################
		my $clean_issue;
                my $mo = join(" ",$FDD_UFR,$TDD_UFR,$EUC,$EUF);
                my @mo = split(" ",$mo);
                foreach(@mo)
                {
                        log_registry("Clean up: Deleting MO $_ ");
                        $clean_issue = delete_mo_CS( mo => $_);
                        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
                }
	}
   }
  else
  {
        log_registry("It seems no Synched ERBSs of version vB.1.20 or later found having EUtranCellFDD or EUtranCellTDD under it");
        test_failed($test_slogan);
  }
}

sub FUT088 # 4.4.1.3.12 and 4.4.3.6.7 
{
  my $test_slogan = $_[0];
  my $tc_id,$tc_info;
  $tc_id = 1 if ( $test_slogan =~ /4\.4\.1\.3\.12/);
  $tc_id = 2 if ( $test_slogan =~ /4\.4\.3\.6\.7/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.3.12; Create UtranCellRelation between EUtranCellFDD/TDD and UtranCell when UtraNetwork exists on ERBS" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.3.6.7 Delete UtranCellRelation that exists between EUtranCellFDD/TDD and UtranCell" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS_FDD = pick_a_erbs_using_cell(CELL => "EUtranCellFDD", VER => "NEW");
  my $ERBS_TDD = pick_a_erbs_using_cell(CELL => "EUtranCellTDD", VER => "NEW");
  my $rnc = pick_a_ne("RncFunction");
  if($ERBS_FDD and $ERBS_TDD and $rnc)
  {
        my $EUtranCellFDD = pick_a_mo("$ERBS_FDD","EUtranCellFDD");
        my $EUtranCellTDD = pick_a_mo("$ERBS_TDD","EUtranCellTDD");;
        log_registry("It seems any of EUtranCellFDD/EUtranCellTDD cell exist under ERBS...") if not ($EUtranCellFDD and $EUtranCellTDD);
        test_failed($test_slogan) if not ($EUtranCellFDD and $EUtranCellTDD);
        return "0" if not ($EUtranCellFDD and $EUtranCellTDD);
        my ($EUF,$attrs_EUF) = get_fdn("ExternalUtranFreq","create");
        my $EUF_result = mo_create_decision("0",$EUF,$attrs_EUF,"","wait for consistent");
	$EUF_result = master_for_proxy_handle("0",$EUF,$attrs_EUF,"","wait for consistent") if($EUF_result and $EUF_result eq "KO");
        log_registry("There is a problem in creation of ExternalUtranFreq MO ...") if not $EUF_result;
        test_failed($test_slogan) if not $EUF_result;
        return "0" if not $EUF_result;
	my ($UtranCell,$cell_attrs) = get_fdn("UtranCell","create");
	$UtranCell = create_UtranCell($rnc,"$cell_attrs");
        log_registry("It seems there is a problem in creation of UtranCell..") if not $UtranCell;
        test_failed($test_slogan) if not $UtranCell;
        return "0" if not $UtranCell;
        my ($TDD_UFR,$UF_fdn1) = create_UtranFreqRelation(EUCTDD => "$EUtranCellTDD",EUF=>"$EUF",base => "CSCLI");
        log_registry("It seems there is a problem in creation of UtranFreqRelation with EUtranCellTDD..") if not $TDD_UFR;
        test_failed($test_slogan) if not $TDD_UFR;
        return "0" if not $TDD_UFR;
        my ($FDD_UFR,$UF_fdn2) = create_UtranFreqRelation(EUCFDD => "$EUtranCellFDD",EUF=>"$EUF",base => "CSCLI");
        log_registry("It seems there is a problem in creation of UtranFreqRelation with EUtranCellFDD..") if not $FDD_UFR;
        test_failed($test_slogan) if not $FDD_UFR;
        return "0" if not $FDD_UFR;
        my ($UCR_fdn1,$P_EUC1) = create_UtranCellRelation(UFR => "$TDD_UFR",UC => "$UtranCell");
        log_registry("It seems there is a problem in creation of UtranCellRelation with EUtranCellTDD..") if not $UCR_fdn1;
        test_failed($test_slogan) if not $UCR_fdn1;
        return "0" if not $UCR_fdn1;
        my ($UCR_fdn2,$P_EUC2) = create_UtranCellRelation(UFR => "$FDD_UFR",UC => "$UtranCell");
        log_registry("It seems there is a problem in creation of UtranCellRelation with EUtranCellFDD..") if not $UCR_fdn2;
        test_failed($test_slogan) if not $UCR_fdn2;
        return "0" if not $UCR_fdn2;
        test_passed($test_slogan) if ($tc_id == 1);

        my %attr_EUC1 = get_mo_attributes_CS(mo => $P_EUC1 , attributes => "createdBy");
        my %attr_EUC2 = get_mo_attributes_CS(mo => $P_EUC2 , attributes => "createdBy");
        log_registry("The createdBy is $attr_EUC1{createdBy} , $attr_EUC2{createdBy} ");
        
        if ($tc_id == 2)
        {
                my $flag = 0;
                log_registry("Deleting UtranCellRelation between EUtranCellFDD and UtranCell...");
                $flag = proxy_mo_delete_decision("0","CSCLI","$UCR_fdn2","Relation");
                log_registry("Issue in deletion of UtranCellRelation b/w EUtranCellFDD and UtranCell") if not $flag;
		test_failed("$test_slogan") if not $flag;
                return "0" if not $flag;
                log_registry("Deleting UtranCellRelation between EUtranCellTDD and UtranCell...");
                $flag = proxy_mo_delete_decision("0","CSCLI","$UCR_fdn1","Relation");
                log_registry("Issue in deletion of UtranCellRelation b/w EUtranCellTDD and UtranCell") if not $flag;
		test_failed("$test_slogan") if not $flag;
                return "0" if not $flag;
		my $time = sleep_start_time();
                #my $force_nudge = forceCC($P_EUC2);
		#$force_nudge = forceCC($P_EUC1); #added for a check
                #long_sleep_found($force_nudge) if $force_nudge;
		long_sleep_found($time);
                my $review_cache_log = cache_file();
                my ($rev_id_1,$rev_log_1) = rev_find(file => $review_cache_log,mo => $P_EUC1);
                my ($rev_id_2,$rev_log_2) = rev_find(file => $review_cache_log,mo => $P_EUC2);
                $flag = 2 if ( $rev_id_1 != 7 or $rev_id_2 != 7);
                log_registry("It seems Proxy ExternalUtranCellFDD are not in Redundant Proxy state... or does not exist anymore") if ($flag == 2);
                if ($attr_EUC1{createdBy} == 0 || $attr_EUC2{createdBy} == 0)
		{
		$flag = 0;
		log_registry("****** The created by is 0 so proxy Cell will be auto deleted, if they were 1 the Cell would remain redundant proxy **********");
		}

                test_failed("$test_slogan") if ($flag == 2);
                test_passed("$test_slogan") if ($flag != 2);
		################################ Clean up #######################################################
                my $clean_issue;
                my $mo = join(" ",$FDD_UFR,$TDD_UFR,$UtranCell,$EUF);
                my @mo = split(" ",$mo);
                foreach(@mo) {
                        log_registry("Clean up: Deleting MO $_ ");
                        $clean_issue = delete_mo_CS( mo => $_);
                        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
        }
   }
  else
  {
        log_registry("It seems no Synched ERBSs of version vB.1.20 or later found having EUtranCellFDD or EUtranCellTDD under it");
        test_failed($test_slogan);
  }
}


sub FUT089 # 4.3.2.2.11 and 4.3.2.2.14
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.3\.2\.2\.11/);
  $tc_id = 2 if ($test_slogan =~ /4\.3\.2\.2\.14/);
  $tc_info = "WRANCM_CMSSnad_4.3.2.2.11; Modify Traffical Id on master UtranCell when LTE proxy ExternalUtranCellFDD exists" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.3.2.2.14; Modify GlobalId on master UtranCell when LTE proxy ExternalUtranCellFDD exists" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($count,@UCR_FDN) = get_CMS_mo("UtranCellRelation",$mo_proxy_cms);
  if($count)
  {
	log_registry("It was expecting 2 UtranCellRelation should be there created by $mo_proxy_cms, created on EUtranCellTDD and EUtranCellFDD ....") if ($count < "2");
	test_failed($test_slogan) if ($count < "2");
	return "0" if ($count < "2");
	my $UCR_FDD,$UCR_TDD,$UC_FDD,$UC_TDD,$EUCFDD_FDD,$EUCFDD_TDD;
	my $flag = 0;
	foreach (@UCR_FDN)
	{
		my %UCR_attr = get_mo_attributes_CS(mo => $_ , attributes => "externalUtranCellFDDRef adjacentCell");
		$flag = 1 if ($UCR_attr{adjacentCell} =~ /\,UtranCell/ and $UCR_attr{adjacentCell} =~ /MeContext/);
		$UCR_FDD = $_ if ($_ =~ /EUtranCellFDD/ and $flag);
		$UCR_TDD = $_ if ($_ =~ /EUtranCellTDD/ and $flag);
		$UC_FDD = $UCR_attr{adjacentCell} if ($flag and $UCR_FDD);
		$UC_TDD = $UCR_attr{adjacentCell} if ($flag and $UCR_TDD);
		$EUCFDD_FDD = $UCR_attr{externalUtranCellFDDRef} if ($flag and $UCR_FDD);
		$EUCFDD_TDD = $UCR_attr{externalUtranCellFDDRef} if ($flag and $UCR_TDD);
		$flag = 0;
		last if ($UCR_FDD and $UCR_TDD);
	}
	log_registry("It was expecting one UtranCellRelation should be with  EUtranCellTDD and one should be with EUtranCellFDD and both relation should have reference to a UtranCell ...") if not ($UCR_FDD and $UCR_TDD);
	test_failed($test_slogan) if not ($UCR_FDD and $UCR_TDD);
	return "0" if not ($UCR_FDD and $UCR_TDD);
	log_registry("Selected UtranCellRelation for Test Case are: \n $UCR_FDD \n $UCR_TDD ");
	log_registry("Selected UtranCell for Test Case is: \n $UC_FDD ");
	log_registry("Another UtranCell selected for Test Case is: \n $UC_TDD ") if ($UC_FDD !~ $UC_TDD);
	log_registry("Selected ExternalUtranCellFDD for Test Case are: \n $EUCFDD_FDD \n $EUCFDD_TDD ");
############################# for modifying primaryScramblingCode  or cId of UtranCell ############################### 
	my $base_fdn,$attrs;
	($base_fdn,$attrs) = get_fdn("UtranCell","set") if ($tc_id == 1);
	($base_fdn,$attrs) = get_fdn("cIdUtranCell","set") if ($tc_id == 2);
 	my ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$UC_FDD,$attrs,"NW");
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
	($status,$rev_id) = proxy_mo_set_decision("CSCLI",$UC_TDD,$attrs,"NW") if ($UC_FDD !~ $UC_TDD);
	test_failed($test_slogan) if not $status;
        return "0" if not $status;
	my $nudge = forceCC($EUCFDD_FDD);
	long_sleep_found($nudge);
	my $same = 0;
	$same = 1 if ($EUCFDD_FDD =~ /$EUCFDD_TDD/);
        my $state_FDD = get_proxy($EUCFDD_FDD);
        log_registry("It seems $EUCFDD_FDD is consistent...") if ($state_FDD == 1);
	if($same == 0)
	{
		my $state_TDD = get_proxy($EUCFDD_TDD);
		log_registry("It seems $EUCFDD_TDD is consistent...") if ($state_TDD == 1);	
		log_registry("It seems any of ExternalUtranCellFDD is not consistent even after consistency check nudge and have long sleep...") if (($state_TDD != 1 or $state_FDD != 1) and ($tc_id == 1));
		log_registry("=====================================================================");
		get_mo_attr($EUCFDD_TDD,"physicalCellIdentity") if ($tc_id == 1);
		get_mo_attr($EUCFDD_TDD,"cellIdentity") if ($tc_id == 2);
		log_registry("=====================================================================");
	}
	log_registry("=====================================================================");
	get_mo_attr($EUCFDD_FDD,"physicalCellIdentity") if ($tc_id == 1);
	get_mo_attr($EUCFDD_FDD,"cellIdentity") if ($tc_id == 2);
	log_registry("=====================================================================");
	my %EUCFDD_TDD_attr = get_mo_attributes_CS(mo => $EUCFDD_TDD, attributes => "physicalCellIdentity cellIdentity");
	my %EUCFDD_FDD_attr = get_mo_attributes_CS(mo => $EUCFDD_FDD, attributes => "physicalCellIdentity cellIdentity");
	my %UC_attr = get_mo_attributes_CS(mo => $UC_FDD, attributes=> "primaryScramblingCode cId"); 
	my $attr_alert = 0;
	$attr_alert = 1 if not ($EUCFDD_TDD_attr{physicalCellIdentity} and $EUCFDD_FDD_attr{physicalCellIdentity} and $UC_attr{primaryScramblingCode} and $EUCFDD_TDD_attr{cellIdentity} and $EUCFDD_FDD_attr{cellIdentity} and $UC_attr{cId});
	log_registry("Attribute seems to be missing for ExternalUtranCellFDD or UtranCell ...") if $attr_alert; 
	test_failed($test_slogan) if $attr_alert;
	return "0" if $attr_alert;
	$flag = 2 if (($EUCFDD_TDD_attr{physicalCellIdentity} != $UC_attr{primaryScramblingCode} or $EUCFDD_FDD_attr{physicalCellIdentity} != $UC_attr{primaryScramblingCode}) and ($tc_id == 1));
	log_registry("It seems physicalCellIdentity attribute does not get modified for ExternalUtranCellFDD...") if ($flag == 2);
	log_registry("physicalCellIdentity for $EUCFDD_TDD => $EUCFDD_TDD_attr{physicalCellIdentity} \n physicalCellIdentity for $EUCFDD_FDD => $EUCFDD_FDD_attr{physicalCellIdentity} ") if ($flag == 2);
	$flag = 2 if (($EUCFDD_TDD_attr{cellIdentity} !~ /$UC_attr{cId}/ or $EUCFDD_FDD_attr{cellIdentity} !~ /$UC_attr{cId}/) and ($tc_id == 2));
	log_registry("It seems cellIdentity attribute does not get modified for ExternalUtranCellFDD...") if ($flag == 2 and $tc_id == 2);
	log_registry("cellIdentity for $EUCFDD_TDD => $EUCFDD_TDD_attr{cellIdentity} \n cellIdentity for $EUCFDD_FDD => $EUCFDD_FDD_attr{cellIdentity} ") if ($flag == 2 and $tc_id == 2);
	test_failed($test_slogan) if ($flag == 2);
	test_passed("$test_slogan") if ($flag != 2);
################################################# Clean Up ################################################################
 	if($tc_id == 2)
 	{
        	my $clean_issue;
		my ($count_UFR,@UFR_FDN) = get_CMS_mo("UtranFreqRelation",$mo_proxy_cms);
		my ($count_EUF,@EUF_FDN) = get_CMS_mo("ExternalUtranFreq",$mo_proxy_cms);
        	my $mo = join(" ",$UCR_FDD,$UCR_TDD,@UFR_FDN,$UC_FDD,@EUF_FDN);
        	my @mo = split(" ",$mo);
        	foreach(@mo)
        	{
               		log_registry("Clean up: Deleting MO $_ ");
               		$clean_issue = delete_mo_CS( mo => $_);
               		log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        	}
	}
  }
  else
  {
	log_registry("It seems no UtranCellRelation exists created by $mo_proxy_cms... ");
	test_failed($test_slogan);
  }
}

sub FUT090 # 4.5.1.2.17 and 4.4.2.2.31
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.5\.1\.2\.17/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.2\.2\.31/);
  $tc_info = "WRANCM_CMSSnad_4.5.1.2.17; Set Traffic Information attribute for proxy ExternalUtranCellFDD" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.2.2.31; Set Global Id attribute for proxy ExternalUtranCellFDD" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($count,@EUCFDD) = get_CMS_mo("ExternalUtranCellFDD","$mo_proxy_cms");
  if($count)
  {
	my $flag = 0;
	my $EUCFDD;
	foreach(@EUCFDD)
	{
		my %attrs = get_mo_attributes_CS(mo => $_ , attributes => "reservedBy");
	  	$EUCFDD = $_ if ($attrs{reservedBy} =~ /UtranCellRelation/);
		last if $EUCFDD;	
	}
	log_registry("It seems ExternalUtranCellFDD are not reservedby UtranCellRelation, that is needed for this test case...") if not $EUCFDD;
	test_failed("$test_slogan") if not $EUCFDD;
	return "0" if not $EUCFDD;
	my $old_master_mo = get_master_for_proxy($EUCFDD);
	my $status,$rev_id,$base_fdn,$attrs;
	($base_fdn,$attrs) = get_fdn("ExternalUtranCellFDD","set") if ($tc_id == 1);
	($base_fdn,$attrs) = get_fdn("cIdExternalUtranCellFDD","set") if ($tc_id == 2);
	my %attr_EUCFDD = get_mo_attributes_CS(mo => $EUCFDD , attributes => "physicalCellIdentity");
	my $old_value_pcid = $attr_EUCFDD{physicalCellIdentity};
        if ($tc_id == 1)
        {
		log_registry("========= Attributes of MO Before =========");
   		my $count_attr = get_mo_attr($EUCFDD,$attrs);
   		log_registry("===========================================");
		$status = set_attributes_mo_CLI(mo => $EUCFDD, base => CSCLI, attributes => $attrs);	
		log_registry("It seems attribute of MO get set properly..") if ($status eq "OK");
		log_registry("It seems attribute of MO does not set properly..") if ($status ne "OK");
		test_failed("$test_slogan") if ($status ne "OK");
		return "0" if ($status ne "OK");
		my $stat = attr_value_comp($EUCFDD,$attrs);
                log_registry("========= Attributes of MO After =========");
                $count_attr = get_mo_attr($EUCFDD,$attrs);
                log_registry("===========================================");
		log_registry("Warning => It seems physicalCellIdentity has not be set for new value, it may be server is quick so check manually once..") if not $stat;
		$rev_id = get_proxy($EUCFDD);
		log_registry("Warning => It seems ExternalUtranCellFDD MO has been deleted after modifying attribute physicalCellIdentity, that is not expected...") if not $rev_id; 
		test_failed("$test_slogan") if not $rev_id;
		return "0" if not $rev_id;
		sleep 60;
	}
	($status,$rev_id) = proxy_mo_set_decision("CSCLI",$EUCFDD,$attrs) if ($tc_id == 2);
	log_registry("Problem in setting attribute of ExternalUtranCellFDD MO ....") if not $status;
	my $time = sleep_start_time() if ($status and $rev_id != 1);
	long_sleep_found($time) if ($status and $rev_id != 1);
	$rev_id = get_proxy($EUCFDD);
	log_registry("Proxy ExternalUtranCellFDD does not seems to be consistent after setting attribute..") if (!($status) and ($rev_id != 1));
	test_failed("$test_slogan") if (!($status) and ($rev_id != 1));
	return "0" if (!($status) and ($rev_id != 1));
	my $new_master_mo;
        if($tc_id == 2)
	{
		$new_master_mo = get_master_for_proxy($EUCFDD);
		$flag = 1 if not ($new_master_mo and $old_master_mo);
		log_registry("It seems new master MO has not been created for proxy $EUCFDD..") if $flag;
		test_failed("$test_slogan") if $flag;
		return "0" if $flag;
		log_registry("Old Master Mo for proxy => $EUCFDD \n $old_master_mo");
		log_registry("NEW Master Mo for proxy => $EUCFDD \n $new_master_mo");
		$flag = 1 if ($new_master_mo =~ /$old_master_mo/);	
		log_registry("It seems new master MO has not been created for proxy $EUCFDD..") if $flag;
        	test_failed("$test_slogan") if $flag;
        	return "0" if $flag;
		my $new_state = get_master($new_master_mo);
		my $old_state = get_master($old_master_mo);
		$flag = 1 if ($new_state != 1 or $old_state != 1);
		log_registry("It seems either old or new master MO is not consistent ...") if $flag;
		test_failed("$test_slogan") if $flag;
		return "0" if $flag; 
		log_registry("It seems old and master MO are consisitent...");
	}
	if($tc_id == 1)	
	{
		my %attr_EUCFDD = get_mo_attributes_CS(mo => $EUCFDD , attributes => "physicalCellIdentity");
		log_registry(" OLD Value of physicalCellIdentity is: $old_value_pcid \n NEW Value of physicalCellIdentity is: $attr_EUCFDD{physicalCellIdentity} after consistency check");
		log_registry("It seems physicalCellIdentity of ExternalUtranCellFDD does not seems to get back to original value or can say to old value...") if ($attr_EUCFDD{physicalCellIdentity} != $old_value_pcid);
		test_failed("$test_slogan") if ($attr_EUCFDD{physicalCellIdentity} != $old_value_pcid);
		return "0" if ($attr_EUCFDD{physicalCellIdentity} != $old_value_pcid);
	}
	test_passed($test_slogan);
################################################# Clean Up ################################################################
	if($tc_id == 2) # Half cleanup only for new entities rest wil be done in FUT091
	{
        	my $clean_issue;
        	my ($count_UFR,@UFR_FDN) = get_CMS_mo("UtranFreqRelation",$mo_proxy_cms);
		my ($count_UCR,@UCR_FDN) = get_CMS_mo("UtranCellRelation",$mo_proxy_cms);
		my $UFR,$UCR;
		my $mec = $EUCFDD;
		$mec =~ s/\,ManagedElement.+$//g;
		foreach(@UFR_FDN){ $UFR = $_ if ($_ =~ /$mec/) };
		if($UFR)
		{
			foreach(@UCR_FDN){ $UCR = $_ if ($_ =~ /$UFR/) }; 
        		my $mo = join(" ",$UCR,$UFR,$new_master_mo,@EUF_FDN);
        		my @mo = split(" ",$mo);
        		foreach(@mo)
        		{
        			log_registry("Clean up: Deleting MO $_ ");
                		$clean_issue = delete_mo_CS( mo => $_);
                		log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        		}
		}
  	}
  }
  else
  {
	log_registry("It seems no ExternalUtranCellFDD MO found created by $mo_proxy_cms ...");
	test_failed("$test_slogan");
  }
}

sub FUT091 # 4.3.2.1.19
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.3.2.1.19; Set uarfcnDl on Master ExternalUtranCell, proxy with same traffical id exists on ERBSs";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($count,@UCR) = get_CMS_mo("UtranCellRelation","$mo_proxy_cms");
  if($count)
  {
        my $flag = 0;
        my $EUC,$UCR,$EUCFDD;
        foreach(@UCR)
        {
                my %attrs = get_mo_attributes_CS(mo => $_ , attributes => "adjacentCell externalUtranCellFDDRef");
                my $tmp = $_ if ($attrs{adjacentCell} =~ /ExternalUtranCell/ and $attrs{adjacentCell} !~ /MeContext/);
		my $master_mo;
		$master_mo = get_master_for_proxy($attrs{externalUtranCellFDDRef}) if ($tmp and $attrs{externalUtranCellFDDRef});
		$EUC = $master_mo if ($master_mo and $master_mo =~ /$mo_proxy_cms/);
		$UCR = $_ if $EUC;
		$EUCFDD = $attrs{externalUtranCellFDDRef} if $EUC;
                last if $EUC;
        }
        log_registry("It seems UtranCellRelation created by $mo_proxy_cms are not associated with any master ExternalUtranCell, that is needed for this test case..") if not $EUC;
        test_failed("$test_slogan") if not $EUC;
        return "0" if not $EUC;
	$EUC =~ s/\n//g;
	log_registry("Selected UtranCellRelation : \n $UCR");
	log_registry("Selected ExternalUtranCell : \n $EUC");
	log_registry("Selected proxy ExternalUtranCellFDD : \n $EUCFDD");
	my ($ExternalUtranFreq,$attr_EUF) = get_fdn("II_ExternalUtranFreq","create");
        my $EUF_result = mo_create_decision("0",$ExternalUtranFreq,$attr_EUF,"","wait for consistent");
	$EUF_result = master_for_proxy_handle("0",$ExternalUtranFreq,$attr_EUF,"","wait for consistent") if($EUF_result and $EUF_result eq "KO");
        log_registry("There is a problem in creation of new ExternalUtranFreq MO ...") if not $EUF_result;
        test_failed($test_slogan) if not $EUF_result;
        return "0" if not $EUF_result;
	my ($base_fdn,$attr_EUC) = get_fdn("MasterExternalUtranCell","set");
	my $result = mo_set_decision("0",$EUC,$attr_EUC,"","wait for consistent");		
	log_registry("There is a problem in setting attribute of master ExternalUtranCell mo...") if ($result ne "OK");
	test_failed($test_slogan) if ($result ne "OK");
	return "0" if ($result ne "OK");
        my $proxies_mo = get_proxies_master($EUC);
	log_registry("Now Proxies for master ExternalUtranCell is: \n $proxies_mo");	
	$flag = 1 if ($proxies_mo =~ /$EUCFDD/);
	log_registry("It seems change in master ExternalUtranCell Mo does not call change in frequency action on resepctive proxes..") if $flag;
	test_failed($test_slogan) if $flag;
	return "0" if $flag;
	my($count_new,@UCR_new) = get_CMS_mo("UtranCellRelation","$mo_proxy_cms");
	log_registry("It seems UtranCellRelations are deleted...") if not $count_new;
	test_failed($test_slogan) if not $count_new;
	return "0" if not $count_new;
	foreach(@UCR_new) {
		$flag = 1 if ($_ =~ /$UCR/); }
	my %UCR = map {$_, 1} @UCR; # Compare old and new UtranCellRelation
	my @difference = grep {!$UCR {$_}} @UCR_new;
	log_registry("New UtranCelRelation : \n @difference") if (scalar(@difference));
	log_registry("It seems UtranCellRelation has not been moved to new downlink frquency value...") if ($flag or !(scalar(@difference)));
	test_failed($test_slogan) if ($flag or !(scalar(@difference)));
	return "0" if ($flag or !(scalar(@difference)));
	test_passed($test_slogan);
################################################### Clean up ##############################################################
	log_registry("=============================== CLEAN UP =====================================");
	my @new_ufr,$new_ufr;
	foreach(@difference){ $new_ufr = $_ ; $new_ufr =~ s/\,UtranCellRelation=$mo_proxy_cms//g; push(@new_ufr,$new_ufr); }
        my $clean_issue;
        my ($count_UFR,@UFR_FDN) = get_CMS_mo("UtranFreqRelation",$mo_proxy_cms);
        my ($count_EUF,@EUF_FDN) = get_CMS_mo("ExternalUtranFreq",$mo_proxy_cms);
        my $mo = join(" ",@UCR_new,@UFR_FDN,@new_ufr,$EUC,@EUF_FDN);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                 log_registry("Clean up: Deleting MO $_ ");
                 $clean_issue = delete_mo_CS( mo => $_);
                 log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
   }
   else
   {
	log_registry("It seems no UtranCellRelation found created by $mo_proxy_cms ...");
	test_failed("$test_slogan");
   }
}

sub FUT092 #4.4.1.2.70 and 4.4.1.2.72 
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.1\.2\.70/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.1\.2\.72/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.70; Create proxy ExternalUtranCellFDD, no master exists in the subnetwork" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.72; Create proxy ExternalUtranCellFDD directly on the node, no master exists in the subnetwork" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(CELL => "ExternalUtranCellFDD", VER => "NEW");
  
  if($ERBS)
  {
	my ($count_bef,@EUP_bef) = get_CMS_mo("ExternalUtranPlmn");
	log_registry("It seems no master ExternalUtranPlmn exist, so there will not be any node..") if not $count_bef;
	test_failed("$test_slogan") if not $count_bef;
	return "0" if not $count_bef;
	my $flag = 0;
	my $UtraNW = pick_a_mo($ERBS,"UtraNetwork");
	$flag = 1 if not $UtraNW;
	my $UF = pick_a_mo($UtraNW,"UtranFrequency") if not $flag;
	$flag = 1 if not (!($flag) and $UF);
	log_registry("It seems either UtraNetwork does not exist under ERBS or a UtranFrequency under UtraNetwork") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	my %UF_attrs = get_mo_attributes_CS(mo => $UF, attributes => "reservedBy arfcnValueUtranDl");
	log_registry("It seems no UtranFreqRelation Exists for the UtranFrequency...") if not $UF_attrs{reservedBy};
	test_failed($test_slogan) if not $UF_attrs{reservedBy};
	return "0" if not $UF_attrs{reservedBy};
	my @UFR = split(" ",$UF_attrs{reservedBy});
	my $UFR = $UFR[0];
	$UFR =~ s/\n+//g;
	log_registry("Selected UtranFreqRelation for the UtranCellRelation is : \n $UFR");
	my ($base_fdn,$attrs) = get_fdn("ExternalUtranCellFDD","create");
	$base_fdn = base_fdn_modify($UF,"$base_fdn");
	my $status,$rev_id;
	($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attrs,"no wait") if ($tc_id == 1);	
	($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$attrs,"no wait") if ($tc_id == 2);
	log_registry("There is problem in creation of ExternalUtranCellFDD proxy MO..") if not $status;
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
        my ($UCR_fdn,$EUC) = create_UtranCellRelation(UFR => "$UFR",base => "CLI",EUCFDD => "$base_fdn");
        log_registry("It seems there is a problem in creation of UtranCellRelation ..") if not $UCR_fdn;
        test_failed($test_slogan) if not $UCR_fdn;
        return "0" if not $UCR_fdn;
	my ($count_aft,@EUP_aft) = get_CMS_mo("ExternalUtranPlmn");
	my @difference;
	my %EUP_bef = map {$_, 1} @EUP_bef if $count_aft; # Compare old and new ExternalUtranPlmn
        @difference = grep {!$EUP_bef{$_}} @EUP_aft if $count_aft;
	my $stat = get_proxy("$base_fdn");
	$flag = 1 if (!(scalar(@difference)) or (scalar(@difference) != 1));
	log_registry("Proxy ExternalUtranCellFDD does not seems to be consistent...") if ($stat != 1);	
	log_registry("It seems one new ExternalUtranPlmn mo is get created: \n @difference") if not $flag;
	log_registry("It seems more than one new ExternalUtranPlmn mo is get created: \n @difference") if (scalar(@difference) > 1);
	get_mo_attr($difference[0]) if not $flag;

	log_registry("difference -> @difference stat -> $stat flag -> $flag count -> $count_aft : before $count_bef");

	test_failed($test_slogan) if ($stat != 1 or $flag);
	test_passed($test_slogan) if ($stat == 1 and !($flag));
######################################### Clean up #####################################################################
        my $clean_issue;
        my $mo = join(" ",$UCR_fdn,$EUC,$base_fdn,@difference);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                 log_registry("Clean up: Deleting MO $_ ");
                 $clean_issue = delete_mo_CS( mo => $_);
                 log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
	log_registry("It seems no Synched ERBS of version vB.1.20 or later found having ExternalUtranCellFDD under it");
	test_failed("$test_slogan");
  }
}

sub FUT093 # 4.4.2.3.9  and 4.5.1.2.25
{
  my $test_slogan = $_[0];
  my $tc_id,$tc_info;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.2\.3\.9/);
  $tc_id = 2 if ($test_slogan =~ /4\.5\.1\.2\.25/);
  #$tc_id = 3 if ($test_slogan =~ /4\.5\.1\.2\.26/); #Temp postponed to implement
  $tc_info = "WRANCM_CMSSnad_4.4.2.3.9; Modify physicalCellIdentity on proxy ExternalUtranCellFDD" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.5.1.2.25; Modify UtranCell uarfcnDl when LTE proxy ExternalUtranCellFDD exists" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(CELL => "EUtranCellFDD", VER => "NEW");
  my $rnc = pick_a_ne("RncFunction");
  if($ERBS and $rnc)
  {
        my $EUtranCellFDD = pick_a_mo("$ERBS","EUtranCellFDD");
        log_registry("It seems any of EUtranCellFDD cell exist under ERBS...") if not $EUtranCellFDD;
        test_failed($test_slogan) if not $EUtranCellFDD;
        return "0" if not $EUtranCellFDD;
        my ($EUF,$attrs_EUF) = get_fdn("ExternalUtranFreq","create");
        my $EUF_result = mo_create_decision("0",$EUF,$attrs_EUF,"","wait for consistent");
	$EUF_result = master_for_proxy_handle("0",$EUF,$attrs_EUF,"","wait for consistent") if($EUF_result and $EUF_result eq "KO");
        log_registry("There is a problem in creation of ExternalUtranFreq MO ...") if not $EUF_result;
        test_failed($test_slogan) if not $EUF_result;
        return "0" if not $EUF_result;
        my ($UtranCell,$cell_attrs) = get_fdn("UtranCell","create");
        $UtranCell = create_UtranCell($rnc,"$cell_attrs");
        log_registry("It seems there is a problem in creation of UtranCell..") if not $UtranCell;
        test_failed($test_slogan) if not $UtranCell;
        return "0" if not $UtranCell;
        my ($UFR,$UF_fdn) = create_UtranFreqRelation(EUCFDD => "$EUtranCellFDD",EUF=>"$EUF",base => "CSCLI");
        log_registry("It seems there is a problem in creation of UtranFreqRelation with EUtranCellFDD..") if not $UFR;
        test_failed($test_slogan) if not $UFR;
        return "0" if not $UFR;
        my ($UCR,$EUCFDD) = create_UtranCellRelation(UFR => "$UFR",UC => "$UtranCell");
        log_registry("It seems there is a problem in creation of UtranCellRelation with EUtranCellFDD..") if not $UCR;
        test_failed($test_slogan) if not $UCR;
        return "0" if not $UCR;
	my $base_fdn,$attrs,$status,$rev_id;
	($base_fdn,$attrs) = get_fdn("ExternalUtranCellFDD","set") if ($tc_id == 1);
        my %attr_EUCFDD = get_mo_attributes_CS(mo => $EUCFDD, attributes => "physicalCellIdentity");
        my $old_value_pcid = $attr_EUCFDD{physicalCellIdentity};
        if ($tc_id == 1)
        {
                log_registry("========= Attributes of MO Before =========");
                my $count_attr = get_mo_attr($EUCFDD,$attrs);
                log_registry("===========================================");
                $status = set_attributes_mo_CLI(mo => $EUCFDD, base => CSCLI, attributes => $attrs);
                log_registry("It seems attribute of MO get set properly..") if ($status eq "OK");
                log_registry("It seems attribute of MO does not set properly..") if ($status ne "OK");
                test_failed("$test_slogan") if ($status ne "OK");
                return "0" if ($status ne "OK");
                my $stat = attr_value_comp($EUCFDD,$attrs);
                log_registry("========= Attributes of MO After =========");
                $count_attr = get_mo_attr($EUCFDD,$attrs);
                log_registry("===========================================");
                log_registry("Warning => It seems physicalCellIdentity has not be set for new value, it may be server is quick so check manually once..") if not $stat;
                $rev_id = get_proxy($EUCFDD);
                log_registry("Warning => It seems ExternalUtranCellFDD MO has been deleted after modifying attribute physicalCellIdentity, that is not expected...") if not $rev_id;
                test_failed("$test_slogan") if not $rev_id;
                return "0" if not $rev_id;
                sleep 60;
        	my $time = sleep_start_time() if ($status and $rev_id != 1);
        	long_sleep_found($time) if ($status and $rev_id != 1);
        	$rev_id = get_proxy($EUCFDD);
        	log_registry("Proxy ExternalUtranCellFDD does not seems to be consistent after setting attribute..") if (!($status) and ($rev_id != 1));
        	test_failed("$test_slogan") if (!($status) and ($rev_id != 1));
        	return "0" if (!($status) and ($rev_id != 1));
                my %attr_EUCFDD = get_mo_attributes_CS(mo => $EUCFDD , attributes => "physicalCellIdentity");
                log_registry(" OLD Value of physicalCellIdentity is: $old_value_pcid \n NEW Value of physicalCellIdentity is: $attr_EUCFDD{physicalCellIdentity} after consistency check");
                log_registry("It seems physicalCellIdentity of ExternalUtranCellFDD does not seems to get back to original value or can say to old value...") if ($attr_EUCFDD{physicalCellIdentity} != $old_value_pcid);
                test_failed("$test_slogan") if ($attr_EUCFDD{physicalCellIdentity} != $old_value_pcid);
                return "0" if ($attr_EUCFDD{physicalCellIdentity} != $old_value_pcid);
        }
	if ($tc_id == 2)
	{
		my $flag = 0;
		my($count,@UCR) = get_CMS_mo("UtranCellRelation","$mo_proxy_cms");
		my ($base_fdn,$attr_UC) = get_fdn("dLUtranCell","set");
        	my $result = mo_set_decision("0",$UtranCell,$attr_UC,"","wait for consistent");
        	log_registry("There is a problem in setting attribute of master UtranCell mo...") if ($result ne "OK");
        	test_failed($test_slogan) if ($result ne "OK");
        	return "0" if ($result ne "OK");
        	my $proxies_mo = get_proxies_master($UtranCell);
        	$flag = 1 if ($proxies_mo =~ /$EUCFDD/);
        	log_registry("It seems change in master UtranCell Mo does not change in resepctive Frequency..") if $flag;
        	test_failed($test_slogan) if $flag;
        	return "0" if $flag;
        	log_registry("Now Proxies for master UtranCell is: \n $proxies_mo");
        	my($count_new,@UCR_new) = get_CMS_mo("UtranCellRelation","$mo_proxy_cms");
        	log_registry("It seems UtranCellRelations are deleted...") if not $count_new;
        	test_failed($test_slogan) if not $count_new;
        	return "0" if not $count_new;
        	foreach(@UCR_new)
        	{
                	$flag = 1 if ($_ =~ /$UCR/);
        	}
        	my %UCR = map {$_, 1} @UCR; # Compare old and new UtranCellRelation
        	my @difference = grep {!$UCR {$_}} @UCR_new;
        	log_registry("New UtranCelRelation : \n @difference") if (scalar(@difference));
        	log_registry("It seems UtranCellRelation has not been moved to new downlink frquency value...") if ($flag or !(scalar(@difference)));
        	test_failed($test_slogan) if ($flag or !(scalar(@difference)));
        	return "0" if ($flag or !(scalar(@difference)));
		$UCR = $difference[0];
	}
        test_passed($test_slogan);
################################################# Clean Up ################################################################
        my $clean_issue;
	$new_ufr = $UCR;
        $new_ufr =~ s/\,UtranCellRelation=$mo_proxy_cms//g;
	my %attr_UFR = get_mo_attributes_CS(mo => $new_ufr , attributes => "adjacentFreq");
	my $new_EUF = $attr_UFR{adjacentFreq};
	my $mo = join(" ",$UCR,$UFR,$new_ufr,$UtranCell,$new_EUF,$EUF);
	my @mo = split(" ",$mo);
        foreach(@mo)
        {
                 log_registry("Clean up: Deleting MO $_ ");
                 $clean_issue = delete_mo_CS( mo => $_);
                 log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
     }
     else
     {
	      	log_registry("It seems no Synched ERBS of version vB.1.20 or later found having EUtranCellFDD under it");
		test_failed("$test_slogan");
     }
}

sub FUT094 #4.5.1.2.23 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.5.1.2.23; Modify RNC proxy ExternalUtranCell attributes when MasterUtranCellAttributeAutoFix ON ";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(CELL => "ExternalUtranCellFDD", VER => "NEW");
  my $rnc = pick_a_ne(RncFunction);
  if($ERBS and $rnc)
  {
	my $flag = 0;
	my $EUC_PRINT_ATTR = "mcc mnc mncLength uarfcnUl ExternalUtranCellId userLabel lac rac rncId uarfcnDl parentSystem primaryScramblingCode cId";
        my $UtranNW = pick_a_mo($rnc,"UtranNetwork");
	log_registry("It seems either UtranNetwork does not exist under RNC....") if not $UtranNW ;
        test_failed("$test_slogan") if not $UtranNW;
	return "0" if not $UtranNW;
	log_registry("Selected UtranNetwork: $UtranNW");
	my $plmn = get_master_for_proxy($UtranNW);
	log_registry("It seems no master plmn mo exist for UtranNetwork $UtranNW MO..") if not $plmn;
	test_failed("$test_slogan") if not $plmn;
	return "0" if not $plmn;
	$plmn =~ s/\n+//g;
	log_registry("Master plmn of UtranNetwork: $plmn");
	my %attrs_plmn = get_mo_attributes_CS(mo =>$plmn,attributes => "mnc mcc mncLength");
	$flag = 1 if not ($attrs_plmn{mcc} and $attrs_plmn{mnc} and $attrs_plmn{mncLength});
	my %attrs_UtranNW = get_mo_attributes_CS(mo =>$UtranNW,attributes => "reservedBy");
	$flag = 1 if not ($attrs_UtranNW{reservedBy});
	log_registry("It seems attributes mcc,mnc,mncLength or IurLink of UtranNetwork or plmn are missing....") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
	my $IurLink;
	my @IurLink = split(" ","$attrs_UtranNW{reservedBy}");
	foreach(@IurLink)
	{
		$IurLink = $_ if ($_ =~ /IurLink\=/);
		last if $IurLink;
	}
	$flag = 1 if not $IurLink;
	log_registry("It seems selelcted UtranNetwork is not reserved by any valid IurLink ....") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
	log_registry("Selected IurLink: $IurLink");
	my %attrs_Iur = get_mo_attributes_CS(mo =>$IurLink,attributes => "rncId");
	$flag =1 if not ($attrs_Iur{rncId});
	log_registry("It seems rncId missing for IurLink...") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
	my $rncId = $attrs_Iur{rncId};
	my $mcc = $attrs_plmn{mcc};
	my $mnc = $attrs_plmn{mnc};
	my $mncLen = $attrs_plmn{mncLength};
	my $cId = int(rand(60000));
        my $pci = int(rand(450));
	my $UtraNW = pick_a_mo($ERBS,"UtraNetwork");
        $flag = 1 if not $UtraNW;
        my $UF = pick_a_mo($UtraNW,"UtranFrequency") if not $flag;
        $flag = 1 if not (!($flag) and $UF);
        log_registry("It seems either UtraNetwork does not exist under ERBS or a UtranFrequency under UtraNetwork") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        my $base_fdn = "$UF".",ExternalUtranCellFDD=$mo_proxy_cms";
	my $attrs = "userLabel $mo_proxy_cms cellIdentity rncId=$rncId+cId=$cId physicalCellIdentity $pci plmnIdentity mcc=$mcc+mnc=$mnc+mncLength=$mncLen";
        my ($status,$rev_id) = proxy_mo_create_decision("CLI",$base_fdn,$attrs,"no wait");
        log_registry("There is problem in creation of ExternalUtranCellFDD proxy MO..") if not $status;
        test_failed($test_slogan) if not $status;
        return "0" if not $status;
        my %UF_attrs = get_mo_attributes_CS(mo => $UF, attributes => "reservedBy");
        log_registry("It seems no UtranFreqRelation Exists for the UtranFrequency...") if not $UF_attrs{reservedBy};
        test_failed($test_slogan) if not $UF_attrs{reservedBy};
        return "0" if not $UF_attrs{reservedBy};
        my @UFR = split(" ",$UF_attrs{reservedBy});
        my $UFR = $UFR[0];
        $UFR =~ s/\n+//g;
        log_registry("Selected UtranFreqRelation for the UtranCellRelation is : \n $UFR");
        my ($UCR_fdn,$EUC) = create_UtranCellRelation(UFR => "$UFR",base => "CLI",EUCFDD => "$base_fdn");
        log_registry("It seems there is a problem in creation of UtranCellRelation ..") if not $UCR_fdn;
        test_failed($test_slogan) if not $UCR_fdn;
        return "0" if not $UCR_fdn;
	log_registry("===== Before: Attributes of Master ExternalUtranCell =============");
	get_mo_attr($EUC,"-o $EUC_PRINT_ATTR");
	log_registry("================================================================");
	my %attrs_EUC = get_mo_attributes_CS(mo =>$EUC,attributes => "uarfcnDl");
	$flag = 1 if (!($attrs_EUC{uarfcnDl}) and ($attrs_EUC{uarfcnDl} !~ /\d+/));
	log_registry("It seems uarfcnDl attribute of master ExternalUtranCell is missing ...") if $flag;
        test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	my $lac = int(rand(65090));
	my $rac = int(rand(220));
	my $ul = int(rand(16000));
	my $proxy_euc = "$IurLink".",ExternalUtranCell=$mo_proxy_cms";
	my $attrs_euc = "uarfcnDl $attrs_EUC{uarfcnDl} cId $cId uarfcnUl $ul primaryScramblingCode $pci lac $lac rac $rac";
	($status,$rev_id) = proxy_mo_create_decision("CSCLI",$proxy_euc,$attrs_euc,"no wait");
	log_registry("There is problem in creation of ExternalUtranCell proxy MO..") if not $status;
        test_failed($test_slogan) if not $status;
        return "0" if not $status;
	my $utran_cell = pick_a_cell($rnc);
	log_registry("It seems no UtranCell exist..") if not $utran_cell;
        test_failed($test_slogan) if not $utran_cell;
        return "0" if not $utran_cell;
	my ($UtranRelation,$M_EUC) = create_UtranRelation( F_UtranCell => $utran_cell, base=> "CLI",uCR => $proxy_euc);
	log_registry("It seems problem in creation of UtranRelation..") if not $UtranRelation;
        test_failed($test_slogan) if not $UtranRelation;
        return "0" if not $UtranRelation;
	$flag = 1 if ($M_EUC !~ /$EUC/);
	log_registry("It seems UtranRelation is not use selected Master ExternalUtranCell as adjacentCell..") if $flag;
	test_failed($test_slogan) if $flag;
        return "0" if $flag;
	sleep 120; # wait for 2 mins to get system stabilized
	log_registry("===== After: Attributes of Master ExternalUtranCell =============");
	get_mo_attr($EUC,"-o $EUC_PRINT_ATTR");
	log_registry("================================================================");
	%attrs_EUC = get_mo_attributes_CS(mo =>$EUC,attributes => "uarfcnUl rac lac");
	$flag = 1 if (!($attrs_EUC{uarfcnUl}) and !($attrs_EUC{rac}) and !($attrs_EUC{lac}) and ($attrs_EUC{uarfcnUl} !~/\d+/) and ($attrs_EUC{lac} !~ /\d+/) and ($attrs_EUC{rac} !~ /\d+/));
	log_registry("It seems attributes of Master ExternalUtranCell are not set ..") if $flag;
	test_failed($test_slogan) if $flag;
        return "0" if $flag;
	log_registry("It seems attributes of Master ExternalUtranCell are set now..");
	my $pci2 = int(rand(450));
 	$pci2 = int(rand(450)) if ($pci2 == $pci);
	$attrs_euc = "primaryScramblingCode $pci2 userLabel CMSAUTOPROXY2"; 
	($status,$rev_id) = proxy_mo_set_decision("CSCLI",$proxy_euc,$attrs_euc,"FN");
	log_registry("There is a problem in setting attribute of proxy ExternalUtranCell") if not $status;
        test_failed($test_slogan) if not $status;
	return "0" if not $status;
	get_proxy($proxy_euc);
	my $nudge = forceCC($EUC);
	long_sleep_found($nudge) if $nudge;
	log_registry("Checking attributes of Master ExternalUtranCell after consistency check going for long sleep...");
	%attrs_EUC = get_mo_attributes_CS(mo =>$EUC,attributes => "primaryScramblingCode");
        $flag = 1 if ($attrs_EUC{primaryScramblingCode} != $pci);
        log_registry("primaryScramblingCode attribute value for Master ExternalUtranCell is : $attrs_EUC{primaryScramblingCode}");
	log_registry("It seems primaryScramblingCode attribute value has been changed in master ExternalutranCell as well..") if $flag;
	my $state_EUC = get_master($EUC);
	log_registry("Master ExternalUtranCell $EUC seems to be consistent ...") if ($state_EUC == 1);
	log_registry("Master ExternalUtranCell $EUC does not seems to be consistent ..") if ($state_EUC != 1);
	$flag = 1 if ($state_EUC != 1);
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;		
	log_registry("Master Mo $EUC has no impact for change in proxy ExternalUtranCell attribute...");
	test_passed($test_slogan);
  }
  else
  {
		log_registry("It seems either no synched ERBS of version vB.1.20 or later having ExternalUtranCellFDD under it or no synched RNC found...");
		test_failed("$test_slogan");
  }
}

sub FUT095  # 4.3.1.1.11 and 4.3.1.1.12
{
  my $test_slogan = $_[0];
  my $result,$tc_id,$rnc;
  $tc_id = 1 if($test_slogan =~ /4\.3\.1\.1\.11/);
  $tc_id = 2 if($test_slogan =~ /4\.3\.1\.1\.12/);
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.11 ; Create master ExternalUtranCell  from an application where proxies exist on a N-1 RNC" if ($tc_id == 1);
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.12 ; Create master ExternalUtranCell from an application where proxies exist" if ($tc_id == 2);
  $rnc = pick_a_ne("RncFunction","OLD") if ($tc_id == 1);
  $rnc = pick_a_ne("RncFunction","NEW") if ($tc_id == 2);
  if($rnc)
  {
        my $flag = 0;
        my $UtranNW = pick_a_mo($rnc,"UtranNetwork");
        log_registry("It seems either UtranNetwork does not exist under RNC....") if not $UtranNW ;
        test_failed("$test_slogan") if not $UtranNW;
        return "0" if not $UtranNW;
        log_registry("Selected UtranNetwork: $UtranNW");
        my $plmn = get_master_for_proxy($UtranNW);
        log_registry("It seems no master plmn mo exist for UtranNetwork $UtranNW MO..") if not $plmn;
        test_failed("$test_slogan") if not $plmn;
        return "0" if not $plmn;
        $plmn =~ s/\n+//g;
        log_registry("Master plmn of UtranNetwork: $plmn");
        my %attrs_plmn = get_mo_attributes_CS(mo =>$plmn,attributes => "mnc mcc mncLength");
        $flag = 1 if not ($attrs_plmn{mcc} and $attrs_plmn{mnc} and $attrs_plmn{mncLength});
        my %attrs_UtranNW = get_mo_attributes_CS(mo =>$UtranNW,attributes => "reservedBy");
        $flag = 1 if not ($attrs_UtranNW{reservedBy});
        log_registry("It seems attributes mcc,mnc,mncLength or IurLink of UtranNetwork or plmn are missing....") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        my $IurLink;
        my @IurLink = split(" ","$attrs_UtranNW{reservedBy}");
        foreach(@IurLink)
        {
                $IurLink = $_ if ($_ =~ /IurLink\=/);
                last if $IurLink;
        }
        $flag = 1 if not $IurLink;
        log_registry("It seems selelcted UtranNetwork is not reserved by any valid IurLink ....") if $flag;
        return "0" if $flag;
        log_registry("Selected IurLink: $IurLink");
        my %attrs_Iur = get_mo_attributes_CS(mo =>$IurLink,attributes => "rncId");
        $flag =1 if not ($attrs_Iur{rncId});
        log_registry("It seems rncId missing for IurLink...") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        my $rncId = $attrs_Iur{rncId};
        my $mcc = $attrs_plmn{mcc};
        my $mnc = $attrs_plmn{mnc};
        my $mncLen = $attrs_plmn{mncLength};
        my $cId = int(rand(60000));
        my $psc = int(rand(450));
        my $UL_DL = int(rand(15000));
        my $lac_rac = int(rand(230));
        my $proxy_EUC = "$IurLink".",ExternalUtranCell=$mo_proxy_cms";
        my $proxy_attr = "uarfcnDl $UL_DL uarfcnUl $UL_DL primaryScramblingCode $psc cId $cId lac $lac_rac rac $lac_rac";
        log_registry("Creating Proxy ExternalUtranCell : $proxy_EUC \n attributes will be: $proxy_attr");
        $result = create_mo_CS(mo => $proxy_EUC, attributes => $proxy_attr);
        log_registry("Problem in creation of proxy ExternalUtranCell ...") if $result;
        test_failed("$test_slogan") if $result;
        return "0" if $result;
        my ($base_fdn,$attr) = get_fdn("ExternalUtranCell","create");
        $attr = "rncId $rncId uarfcnDl $UL_DL mcc $mcc uarfcnUl $UL_DL mnc $mnc primaryScramblingCode $psc cId $cId mncLength $mncLen lac $lac_rac rac $lac_rac parentSystem $plmn";
        $result = mo_create_decision("0",$base_fdn,$attr,"","wait for long sleep");
	$result = master_for_proxy_handle("0",$base_fdn,$attr,"","wait for long sleep") if($result and $result eq "KO");
        log_registry("Problem in creation of proxy ExternalUtranCell ...") if ($result ne "OK");
        test_failed("$test_slogan") if ($result ne "OK");
        return "0" if ($result ne "OK");
        my $review_cache_log = cache_file();
        my ($rev_id,$rev_log) = rev_find(file => $review_cache_log,mo => $proxy_EUC);
        log_registry("Proxy does not seems to be redundant ..") if ($rev_id != 7);
        test_failed($test_slogan) if ($rev_id != 7);
        return "0" if ($rev_id != 7);
        my $utran_cell = pick_a_cell($rnc);
        my ($UtranRelation,$p_EUC) = create_UtranRelation(F_UtranCell => $utran_cell, base=> "CSCLI",EUC => $base_fdn,FREQ => "NOCHECK");
        log_registry("It seems problem in creation of UtranRelation..") if not $UtranRelation;
        test_failed($test_slogan) if not $UtranRelation;
        return "0" if not $UtranRelation;
        $flag = 1 if ($p_EUC !~ /$proxy_EUC/);
        log_registry("It seems proxy ExternalUtranCell is not matching with utranCellRef attribute of UtranRlation ...") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        $review_cache_log = cache_file();
        my ($id_proxy,$proxy_exist) = rev_find(file => $review_cache_log,mo => $proxy_EUC);
        my ($id_master,$master_exist) = rev_find(file => $review_cache_log,mo => $base_fdn);
        $flag = 1 if ($id_proxy != 1 or $id_master != 1);
        log_registry("Proxy/master does not seems to be consistent ..") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
        test_passed($test_slogan);
################################################### Clean Up #############################################################
        my $clean_issue;
        my $mo = join(" ",$UtranRelation,$base_fdn,$proxy_EUC);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                 log_registry("Clean up: Deleting MO $_ ");
                 $clean_issue = delete_mo_CS( mo => $_);
                 log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
   }
   else
   {
        log_registry("It seems no Synched RNC found of version vS or later... Or check theb sub node_version in Common.pm is correct with its node versions") if ($tc_id == 2);
        log_registry("It seems no Synched RNC found of version vN or earlier... Or check theb sub node_version in Common.pm is correct with its node versions") if ($tc_id == 1);
        test_failed($test_slogan);
   }
}

sub FUT096  # 4.4.1.6.20
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.6.20 ; Create UtranRelation between two N RNCs";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne("RncFunction","NEW");
  my $rnc2 = pick_a_ne("RncFunction","OLD");
  if($rnc and $rnc2)
  {
	my $flag = 0; my $WcdmaCarrier,$master;
	my ($count,@WcdmaCarrier) = get_CMS_mo("WcdmaCarrier",$rnc);
	log_registry("It seems no pre-existing WcdmaCarrier exist for RNC $rnc ...") if not $count;
	foreach(@WcdmaCarrier)
	{
		$master = get_master_for_proxy($_ ,"no log entry");
		$master =~ s/\n+//g;
		$flag = 1 if ($master =~ /$rnc2/);
		$Iurlink = $_ if $flag;
		last if $flag;
	}
	log_registry("It seems RNC $rnc and another RNC $rnc2 already have pre-existing UtranRelation \n WcdmaCarrier: $WcdmaCarrier \n Master for WcdmaCarrier: $master \n Please execute Test Case again") if $flag;
	test_failed($test_slogan) if $flag;
	return "0" if $flag;
	my ($before_count,@before_WcdmaCarrier) = get_CMS_mo("WcdmaCarrier");
        my $utran_cell_1 = create_UtranCell($rnc,"uarfcnUl 10 uarfcnDl 100");
        test_failed($test_slogan) if not $utran_cell_1;
        return "0" if not $utran_cell_1;
        my $utran_cell_2 = create_UtranCell($rnc2,"uarfcnUl 10 uarfcnDl 100");
        test_failed($test_slogan) if not $utran_cell_2;
        return "0" if not $utran_cell_2;
        log_registry("Creating UtranRelation between two Utrancells of different RNCs that do not have any pre-existing relation yet...");
        my ($UtranRelation,$utranCellRef) = create_UtranRelation( F_UtranCell => $utran_cell_1,S_UtranCell => $utran_cell_2, RNC => "Different", FREQ => "NOCHECK");
        test_failed($test_slogan) if not $UtranRelation;
        return "0" if not $UtranRelation;
	my ($after_count,@after_WcdmaCarrier) = get_CMS_mo("WcdmaCarrier");
	log_registry("It seems new WcdmaCarrier MO have created") if ($after_count > $before_count);
	log_registry("Count of WcdmaCarrier Before: $before_count \n Count of WcdmaCarrier After: $after_count");
	log_registry("It seems no new WcdmaCarrier MO have created") if ($after_count <= $before_count);
        test_failed($test_slogan) if ($after_count <= $before_count);
        return "0" if ($after_count <= $before_count);	
	my %before_WcdmaCarrier = map {$_, 1} @before_WcdmaCarrier; # Compare old and new WcdmaCarrier
	my @difference = grep {!$before_WcdmaCarrier {$_}} @after_WcdmaCarrier;
	log_registry("New WcdmaCarrier MOs: \n @difference");
	test_passed($test_slogan);
	############################# CLEAN UP ##################################
        my $clean_issue;
        my $mo = join(" ",$UtranRelation,$utran_cell_1,$utran_cell_2);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
        log_registry("It seems either no Synched RNC found of version vS or later or vM or earlier, Here we are looking for two RNC one of new version and one of older version");
        test_failed($test_slogan);
  }
}

sub FUT097  #4.4.1.8.3 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.8.3 ; Create Cdma2000FreqBandRelation MO with the adjacentFreq attribute set to sn ExternalCdma2000FreqBand in the SubNetwork MIB from an application. Create with already existing Cdma2000Network MO and Cdma2000FreqBand MO on ERBS MIB";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
#  my $ERBS = pick_a_ne("ENodeBFunction","EUtranCellFDD");

  my $ERBS = pick_a_erbs_using_cell(CELL => "EUtranCellFDD", VER => "NEW");

  if($ERBS)
  {
	my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
	test_failed($test_slogan) if not $EUCFDD;
	return "0" if not $EUCFDD;
	my ($C2FB,$C2FB_attrs) = get_fdn("ExternalCdma2000FreqBand","create");
	my $result = mo_create_decision("0",$C2FB,$C2FB_attrs,"","wait for consistent");	
	$result = master_for_proxy_handle("0",$C2FB,$C2FB_attrs,"","wait for consistent") if($result and $result eq "KO");
	log_registry("Problem in creation of master ExternalCdma2000FreqBand MO $C2FB...") if ($result ne "OK");
	test_failed($test_slogan) if ($result ne "OK");
	return "0" if ($result ne "OK");
	my($C2FBR,$P_C2FB) = create_Cdma2000FreqBandRelation(EUCFDD => $EUCFDD, EC2FB => $C2FB);
	log_registry("Problem in creation of Cdma2000FreqBandRelation...") if not $C2FBR;
	test_failed($test_slogan) if not $C2FBR;
	return "0" if not $C2FBR;
	test_passed($test_slogan);
        ############################# CLEAN UP ##################################
        my $clean_issue;
        my $mo = join(" ",$C2FBR,$C2FB);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
	log_registry("It seems no synched ERBS found...");
	test_failed($test_slogan);
  }
}

sub FUT098  #4.4.1.8.4
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.8.4 ; Create Cdma2000FreqBandRelation MO under 2 different EUtranCellFDDs with the adjacentFreq attribute set to sn ExternalCdma2000FreqBand in the SubNetwork MIB from an application. Create with already existing Cdma2000Network MO and Cdma2000FreqBand MO on ERBS MIB";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne("ENodeBFunction","EUtranCellFDD");
  if($ERBS)
  {
	my $flag = 0;
        my $EUCFDD1 = pick_a_mo($ERBS,EUtranCellFDD);
	my $EUCFDD2 = pick_a_mo($ERBS,EUtranCellFDD);
	$EUCFDD2 = pick_a_mo($ERBS,EUtranCellFDD) if ($EUCFDD2 =~ /$EUCFDD1/);
	$flag = 1 if (!($EUCFDD1) or !($EUCFDD2) or $EUCFDD1 =~/$EUCFDD2/);
	log_registry("It seems no two different EUtranCellFDD has been found under ERBS ..") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
        my ($C2FB,$C2FB_attrs) = get_fdn("ExternalCdma2000FreqBand","create");
        my $result = mo_create_decision("0",$C2FB,$C2FB_attrs,"","wait for consistent");
	$result = master_for_proxy_handle("0",$C2FB,$C2FB_attrs,"","wait for consistent") if($result and $result eq "KO");
        log_registry("Problem in creation of master ExternalCdma2000FreqBand MO $C2FB...") if ($result ne "OK");
        test_failed($test_slogan) if ($result ne "OK");
        return "0" if ($result ne "OK");
        my($C2FBR1,$P_C2FB1) = create_Cdma2000FreqBandRelation(EUCFDD => $EUCFDD1, EC2FB => $C2FB);
        log_registry("Problem in creation of Cdma2000FreqBandRelation...") if not $C2FBR1;
        test_failed($test_slogan) if not $C2FBR1;
        return "0" if not $C2FBR1;
        my($C2FBR2,$P_C2FB2) = create_Cdma2000FreqBandRelation(EUCFDD => $EUCFDD2, EC2FB => $C2FB);
        log_registry("Problem in creation of Cdma2000FreqBandRelation...") if not $C2FBR2;
        test_failed($test_slogan) if not $C2FBR2;
        return "0" if not $C2FBR2;
	my %C2FB2_attrs = get_mo_attributes_CS(mo => $P_C2FB2 , attributes => "reservedBy");
	$flag = 1 if(!($C2FB2_attrs{reservedBy}) or $C2FB2_attrs{reservedBy} !~ /$C2FBR1/);
	log_registry("It seems proxy Cdma2000FreqBand is not reserved by Cdma2000FreqBandRelation created first time : $C2FBR1") if $flag;	
	get_mo_attr($P_C2FB2,"reservedBy") if $flag;
	test_failed($test_slogan) if $flag;
        return "0" if $flag;
        test_passed($test_slogan);
        ############################# CLEAN UP ##################################
        my $clean_issue;
        my $mo = join(" ",$C2FBR1,$C2FBR2,$C2FB);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
        log_registry("It seems no synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT099  #4.4.1.8.5
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.8.5 ; Create Cdma2000FreqBandRelation MO with the cdma2000FreqBandRef attribute set to Cdma2000FreqBand using EM (netsim)";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne("ENodeBFunction","EUtranCellFDD");
  if($ERBS)
  {
        my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
        test_failed($test_slogan) if not $EUCFDD;
        return "0" if not $EUCFDD;
	my ($count,@P_C2FB) = get_CMS_mo("Cdma2000FreqBand",$ERBS);
	log_registry("It seems no proxy Cdma2000FreqBand mo found under ERBS $ERBS") if not $count;
	test_failed($test_slogan) if not $count;
	return "0" if not $count;
        my($C2FBR,$C2FB) = create_Cdma2000FreqBandRelation(base => "CLI",EUCFDD => $EUCFDD, C2FB => $P_C2FB[0]);
        test_failed($test_slogan) if not $C2FBR;
        return "0" if not $C2FBR;
        test_passed($test_slogan);
        ############################# CLEAN UP ##################################
        log_registry("Clean up: Deleting MO $C2FBR ");
        my $clean_issue = delete_mo_CS( mo => $C2FBR);
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
  }
  else
  {
        log_registry("It seems no synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT100  #4.4.1.8.6
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.8.6 ; Create Cdma2000FreqBandRelation MO under 2 different EUtranCellFDDs with the cdma2000FreqBandRef attribute set to Cdma2000FreqBand through the EM (netsim)";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne("ENodeBFunction","EUtranCellFDD");
  if($ERBS)
  {
        my $flag = 0;
        my $EUCFDD1 = pick_a_mo($ERBS,EUtranCellFDD);
        my $EUCFDD2 = pick_a_mo($ERBS,EUtranCellFDD);
        $EUCFDD2 = pick_a_mo($ERBS,EUtranCellFDD) if ($EUCFDD2 =~ /$EUCFDD1/);
        $flag = 1 if (!($EUCFDD1) or !($EUCFDD2) or $EUCFDD1 =~/$EUCFDD2/);
        log_registry("It seems no two different EUtranCellFDD has been found under ERBS ..") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
        my ($count,@P_C2FB) = get_CMS_mo("Cdma2000FreqBand",$ERBS);
        log_registry("It seems no proxy Cdma2000FreqBand mo found under ERBS $ERBS") if not $count;
        test_failed($test_slogan) if not $count;
        return "0" if not $count;
        my($C2FBR1,$P_C2FB1) = create_Cdma2000FreqBandRelation(base => "CLI",EUCFDD => $EUCFDD1, C2FB => $P_C2FB[0]);
        test_failed($test_slogan) if not $C2FBR1;
        return "0" if not $C2FBR1;
        my($C2FBR2,$P_C2FB2) = create_Cdma2000FreqBandRelation(base => "CLI",EUCFDD => $EUCFDD2, C2FB => $P_C2FB[0]);
        test_failed($test_slogan) if not $C2FBR2;
        return "0" if not $C2FBR2;
        my %C2FB2_attrs = get_mo_attributes_CS(mo => $P_C2FB2 , attributes => "reservedBy");
        $flag = 1 if(!($C2FB2_attrs{reservedBy}) or $C2FB2_attrs{reservedBy} !~ /$C2FBR1/);
        log_registry("It seems proxy Cdma2000FreqBand is not reserved by Cdma2000FreqBandRelation created first time : $C2FBR1") if $flag;
        get_mo_attr($P_C2FB2,"reservedBy") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
        test_passed($test_slogan);
        ############################# CLEAN UP ##################################
        my $clean_issue;
        my $mo = join(" ",$C2FBR1,$C2FBR2);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
        log_registry("It seems no synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT101  #4.4.1.9.2 and 4.4.1.9.6
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if($test_slogan =~ /4\.4\.1\.9\.2/);
  $tc_id = 2 if($test_slogan =~ /4\.4\.1\.9\.6/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.9.2 ; Create Cdma2000CellRelation MO with the adjacentCell attribute set to sn ExternalCdma2000Cell in the SubNetwork MIB from an application. Create with already existing Cdma2000Network, Cdma2000FreqBand and Cdma2000Freq MO on ERBS MIB" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.1.9.6 ; Update attribute adjacentCell on Cdma2000CellRelation MO to a different pre-existing sn ExternalCdma2000Cell in the SubNetwork MIB from an application with already existing Cdma2000Network, Cdma2000FreqBand and Cdma2000Freq MO on ERBS" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(MO => "Cdma2000FreqBandRelation");
  if($ERBS)
  {
	my ($icount,@C2FBR) = get_CMS_mo("Cdma2000FreqBandRelation","$ERBS");
	log_registry("It seems no unique Cdma2000FreqBandRelation not found ..") if not $icount;
        test_failed($test_slogan) if not $icount;
        return "0" if not $icount;
	my $C2FBR = $C2FBR[0];
	my ($count,@MEC2C) = select_mo_cs( MO => "ExternalCdma2000Cell",NOTKEY => "MeContext");
	log_registry("It seems no pre-existing master ExternalCdma2000Cell exist") if not $count;
	test_failed($test_slogan) if not $count;
	return "0" if not $count;
	log_registry("It seems two unique ExternalCdma2000Cell not found ..") if ($tc_id == 2 and $count < 2);
	test_failed($test_slogan) if ($tc_id == 2 and $count < 2);
	return "0"  if ($tc_id == 2 and $count < 2);
        my($C2CR,$PEC2C) = create_Cdma2000CellRelation(MEC2C => $MEC2C[0], C2FBR => $C2FBR);
        test_failed($test_slogan) if not $C2CR;
        return "0" if not $C2CR;
        test_passed($test_slogan) if ($tc_id == 1);
	if ($tc_id == 2)  {
		my $flag = 0;
		my $EC2C2 = $MEC2C[1];
		my $status = set_attributes_mo_CLI(base => CSCLI, mo => $C2CR, attributes => "adjacentCell $EC2C2");
		log_registry("There is problem in setting attribute of Cdma2000CellRelation") if (!($status) or ($status ne "OK"));
		test_failed($test_slogan) if (!($status) or ($status ne "OK"));
		return "0" if (!($status) or ($status ne "OK"));
		my %param = get_mo_attributes_CS(mo => $C2CR,attributes => "adjacentCell");
		get_mo_attr($C2CR);
		$flag = 1 if(!($param{adjacentCell}) or ($param{adjacentCell} !~ /$EC2C2$/));
		log_registry("It seems adjacentCell attribute of Cdma2000CellRelation is not set for new ExternalCdma2000Cell..") if $flag;
		test_failed($test_slogan) if $flag;
		return "0" if $flag;
		my $EUCXDD = $C2FBR;
		$EUCXDD =~ s/\,Cdma2000FreqBandRelation.+//g;
		$EUCXDD =~ s/\n+//g;
		my $nudge = forceCC($EUCXDD);
		long_sleep_found($nudge);
		%param = get_mo_attributes_CS(mo => $C2CR,attributes => "adjacentCell");
		get_mo_attr($C2CR);
		$flag = 1 if(!($param{adjacentCell}) or ($param{adjacentCell} !~ /$MEC2C[0]$/));
		log_registry("It seems adjacentCell attribute of Cdma2000CellRelation is not revert back to old ExternalCdma2000Cell..") if $flag;
		test_failed($test_slogan) if $flag;
		test_passed($test_slogan) if not $flag; }
        ############################# CLEAN UP ##################################
        log_registry("Clean up: Deleting MO $C2CR ");
        my $clean_issue = delete_mo_CS( mo => $C2CR);
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
  }
  else
  {
        log_registry("It seems no synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT102 #4.4.1.9.3
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.9.3 ; Create Cdma2000CellRelation MO under 2 different EUtranCellFDD with the adjacentCell attribute set to sn ExternalCdma2000Cell in the SubNetwork MIB from an application. Create with already existing Cdma2000Network, Cdma2000FreqBand and Cdma2000Freq MO on ERBS MIB";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(MO => "Cdma2000FreqBandRelation");
  if($ERBS)
  {
        my $flag = 0;
	my ($icount,@C2FBR) = get_CMS_mo("Cdma2000FreqBandRelation",$ERBS);
	$flag = 1 if (!($icount) or $icount < 2);
        log_registry("It seems no two different Cdma2000FreqBandRelation has been found under ERBS ..") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
	my $C2FBR1 = $C2FBR[0];
	my $C2FBR2 = $C2FBR[1];
        my ($count,@MEC2C) = select_mo_cs( MO => "ExternalCdma2000Cell",NOTKEY => "MeContext");
        log_registry("It seems no pre-existing master ExternalCdma2000Cell exist") if not $count;
        test_failed($test_slogan) if not $count;
        return "0" if not $count;
        my($C2CR1,$PEC2C1) = create_Cdma2000CellRelation(MEC2C => $MEC2C[0], C2FBR => $C2FBR1);
        test_failed($test_slogan) if not $C2CR1;
        return "0" if not $C2CR1;
	my($C2CR2,$PEC2C2) = create_Cdma2000CellRelation(MEC2C => $MEC2C[0], C2FBR => $C2FBR2);
        test_failed($test_slogan) if not $C2CR2;
        return "0" if not $C2CR2;
        my %PEC2C2_attrs = get_mo_attributes_CS(mo => $PEC2C2, attributes => "reservedBy");
        $flag = 1 if(!($PEC2C2_attrs{reservedBy}) or $PEC2C2_attrs{reservedBy} !~ /$C2CR1/);
        log_registry("It seems proxy ExternalCdma2000Cell is not reserved by Cdma2000CellRelation created first time : $C2CR1") if $flag;
        get_mo_attr($PEC2C2,"reservedBy") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
        test_passed($test_slogan);
        ############################# CLEAN UP ##################################
        my $clean_issue;
        my $mo = join(" ",$C2CR1,$C2CR2);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
        log_registry("It seems no synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT103  #4.4.1.9.4
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.9.4 ; Create Cdma2000CellRelation MO with the externalCdma2000CellRef attribute set to ExternalCdma2000Cell using EM (netsim)";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(MO => "Cdma2000FreqBandRelation");
  if($ERBS)
  {
        my ($icount,@C2FBR) = get_CMS_mo("Cdma2000FreqBandRelation","$ERBS");
        test_failed($test_slogan) if not $icount;
        return "0" if not $icount;
        my $C2FBR = $C2FBR[0];
        my ($count,@PEC2C) = get_CMS_mo("ExternalCdma2000Cell","$ERBS");
        log_registry("It seems no pre-existing proxy ExternalCdma2000Cell exist") if not $count;
        test_failed($test_slogan) if not $count;
        return "0" if not $count;
        my($C2CR,$PEC2C) = create_Cdma2000CellRelation(base => "CLI",PEC2C => $PEC2C[0], C2FBR => $C2FBR);
        test_failed($test_slogan) if not $C2CR;
        return "0" if not $C2CR;
        test_passed($test_slogan);
        ############################# CLEAN UP ##################################
        log_registry("Clean up: Deleting MO $C2CR ");
        my $clean_issue = delete_mo_CS( mo => $C2CR);
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
  }
  else
  {
        log_registry("It seems no synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT104  #4.4.1.9.5
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.9.5 ; Create Cdma2000CellRelation MO under 2 different EUtranCellFDDs with the externalCdma2000CellRef attribute set to ExternalCdma2000Cell through the EM (netsim)";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(MO => "Cdma2000FreqBandRelation");
  if($ERBS)
  {
	my $flag = 0;
        my ($icount,@C2FBR) = get_CMS_mo("Cdma2000FreqBandRelation",$ERBS);
        $flag = 1 if (!($icount) or $icount < 2);
        log_registry("It seems no two different Cdma2000FreqBandRelation has been found under ERBS ..") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
        my $C2FBR1 = $C2FBR[0];
        my $C2FBR2 = $C2FBR[1];
        my ($count,@PEC2C) = get_CMS_mo("ExternalCdma2000Cell","$ERBS");
        log_registry("It seems no pre-existing proxy ExternalCdma2000Cell exist") if not $count;
        test_failed($test_slogan) if not $count;
        return "0" if not $count;
	my($C2CR1,$PEC2C1) = create_Cdma2000CellRelation(base => "CLI",PEC2C => $PEC2C[0], C2FBR => $C2FBR1);
        test_failed($test_slogan) if not $C2CR1;
        return "0" if not $C2CR1;
        my($C2CR2,$PEC2C2) = create_Cdma2000CellRelation(base => "CLI",PEC2C => $PEC2C[0], C2FBR => $C2FBR2);
        test_failed($test_slogan) if not $C2CR2;
        return "0" if not $C2CR2;
        my %PEC2C2_attrs = get_mo_attributes_CS(mo => $PEC2C2, attributes => "reservedBy");
        $flag = 1 if(!($PEC2C2_attrs{reservedBy}) or $PEC2C2_attrs{reservedBy} !~ /$C2CR1/);
        log_registry("It seems proxy ExternalCdma2000Cell is not reserved by Cdma2000CellRelation created first time : $C2CR1") if $flag;
        get_mo_attr($PEC2C2,"reservedBy") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
        test_passed($test_slogan);
        ############################# CLEAN UP ##################################
        log_registry("Clean up: Deleting MO $C2CR1 ");
        my $clean_issue = delete_mo_CS( mo => $C2CR1);
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
	log_registry("Clean up: Deleting MO $C2CR2 ");
	$clean_issue = delete_mo_CS( mo => $C2CR2);
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
  }
  else
  {
        log_registry("It seems no synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT105  #4.4.3.4.3
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.4.3 ; Delete   - Delete   Cdma2000FreqBand fails due to reservedBy set";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(MO => "Cdma2000FreqBand");
  if($ERBS)
  {
	my $C2FB;
	my ($count,@C2FB) = get_CMS_mo("Cdma2000FreqBand",$ERBS);
	test_failed($test_slogan) if not $count;
	return "0" if not $count;
	foreach(@C2FB)
	{
		my %attrs = get_mo_attributes_CS(mo => $_ , attributes=>"reservedBy");
		$C2FB = $_ if ($attrs{reservedBy} and $attrs{reservedBy} =~ /Cdma2000FreqBandRelation/);
		last if $C2FB;	
	}
	log_registry("It seems no Cdma2000FreqBand MO found having reservedBy attribute set under ERBS...") if not $C2FB;
	test_failed($test_slogan) if not $C2FB;
	return "0" if not $C2FB;
	log_registry("====================================================================================");
	get_mo_attr($C2FB,"reservedBy");
	log_registry("====================================================================================");
        log_registry("Deleting Cdma2000FreqBand : $C2FB");
        my $status = delete_mo_CLI(mo => $C2FB, base => "CSCLI");
        log_registry("It seems Cdma2000FreqBand get deleted ..") if ($status eq "OK");
        log_registry("Cdma2000FreqBand MO not get deleted") if ($status ne "OK");
        log_registry("wait for 2 mins to get system stabilized...");
        sleep 120;
        my $state = does_mo_exist_CLI( base => CSCLI, mo => $C2FB);
	my $review_cache_log = cache_file();
	my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $C2FB);
        log_registry("Cdma2000FreqBand $C2FB get deleted , It was not expected...") if (!($rev_log) or $state eq "NO");
        log_registry("Cdma2000FreqBand $C2FB is not deleted, Its ok, it can not be deleted until its reservedBy set ...") if ($rev_log and $state eq "YES");
        test_failed($test_slogan) if (!($rev_log) or $status eq "OK" or  $state eq "NO");
        test_passed($test_slogan) if ($rev_log and $status ne "OK" and $state eq "YES");
  }
  else
  {
        log_registry("It seems no synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT106  #4.4.3.4.6
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.4.6 ; Delete   - Delete   Cdma2000Freq fails due to reservedBy set";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(MO => "Cdma2000FreqBandRelation",VER => "NEW");
  if($ERBS)
  {
        my $C2FBR,$C2F,$C2FR,$EC2F;
        my ($count,@C2FBR) = get_CMS_mo("Cdma2000FreqBandRelation",$ERBS);
        test_failed($test_slogan) if not $count;
        return "0" if not $count;
	$C2FBR = $C2FBR[int(rand($#C2FBR))];	
	my ($icount,@C2F) = get_CMS_mo("Cdma2000Freq",$ERBS);
	log_registry("It seems no Cdma2000Freq mo under ERBS ...") if not $icount;
	test_failed($test_slogan) if not $icount;
	return "0" if not $icount;
        foreach(@C2F)
        {
                my %attrs = get_mo_attributes_CS(mo => $_ , attributes=>"reservedBy");
                $C2F = $_ if ($attrs{reservedBy} and $attrs{reservedBy} =~ /Cdma2000FreqRelation/);
                last if $C2F;
        }
        log_registry("It seems no Cdma2000Freq MO found having reservedBy attribute set under ERBS so we will first create aCdma2000FreqRelation with proxy Cdma2000Freq MO ...") if not $C2F;
	if(!($C2F))
	{
		$C2F = $C2F[int(rand($#C2F))];
		($C2FR,$EC2F) = create_Cdma2000FreqRelation( C2FBR => $C2FBR , C2F => $C2F,base => "CLI" ); 
		log_registry("There is a problem in creation of Cdma2000FreqRelation ...") if not $C2FR;
		test_failed($test_slogan) if not $C2FR;
		return "0" if not $C2FR;
	}
        log_registry("====================================================================================");
        get_mo_attr($C2F,"reservedBy");
        log_registry("====================================================================================");
        log_registry("Deleting Cdma2000Freq MO : $C2F");
        my $status = delete_mo_CLI(mo => $C2F, base => "CSCLI");
        log_registry("It seems Cdma2000Freq get deleted ..") if ($status eq "OK");
        log_registry("Cdma2000Freq MO is not get deleted...") if ($status ne "OK");
        log_registry("wait for 2 mins to get system stabilized...");
        sleep 120;
        my $state = does_mo_exist_CLI( base => CSCLI, mo => $C2F);
	my $review_cache_log = cache_file();
	my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $C2F);
        log_registry("Cdma2000Freq $C2F get deleted , It was not expected...") if (!($rev_log) or $state eq "NO");
        log_registry("Cdma2000Freq $C2F is not deleted, Its ok, it can not be deleted until its reservedBy set ...") if ($rev_log and $state eq "YES");
        test_failed($test_slogan) if (!($rev_log) or $status eq "OK" or  $state eq "NO");
        test_passed($test_slogan) if ($rev_log and $status ne "OK" and $state eq "YES");
	############################### Clean up #########################################
        log_registry("Clean up: Deleting MO $C2FR ") if $C2FR;
        my $clean_issue = delete_mo_CS( mo => $C2FR) if $C2FR;
        log_registry("Warning => Problem in deletion of MO ...") if ($C2FR and $clean_issue);
  }
  else
  {
        log_registry("It seems no synched ERBS found of version vB.1.20 or later having Cdma2000FreqBandRelation");
        test_failed($test_slogan);
  }
}

sub FUT107  #4.4.3.4.9
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.4.9 ; Delete   - Delete   ExternalCdma2000Cell fails due to reservedBy set";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(MO => "Cdma2000CellRelation");
  if($ERBS)
  {
        my $EC2C;
        my ($count,@EC2C) = get_CMS_mo("ExternalCdma2000Cell",$ERBS);
	log_registry("It seems no ExternalCdma2000Cell found under ERBS..") if not $count;
        test_failed($test_slogan) if not $count;
        return "0" if not $count;
        foreach(@EC2C)
        {
                my %attrs = get_mo_attributes_CS(mo => $_ , attributes=>"reservedBy");
                $EC2C= $_ if ($attrs{reservedBy} and $attrs{reservedBy} =~ /Cdma2000CellRelation/);
                last if $EC2C;
        }
        log_registry("It seems no ExternalCdma2000Cell MO found having reservedBy attribute set under ERBS...") if not $EC2C;
        test_failed($test_slogan) if not $EC2C;
        return "0" if not $EC2C;
        log_registry("====================================================================================");
        get_mo_attr($EC2C,"reservedBy");
        log_registry("====================================================================================");
        log_registry("Deleting ExternalCdma2000Cell : $EC2C");
        my $status = delete_mo_CLI(mo => $EC2C, base => "CSCLI");
        log_registry("It seems ExternalCdma2000Cell get deleted ..") if ($status eq "OK");
        log_registry("ExternalCdma2000Cell MO not get deleted") if ($status ne "OK");
        log_registry("wait for 2 mins to get system stabilized...");
        sleep 120;
        my $state = does_mo_exist_CLI( base => CSCLI, mo => $EC2C);
	my $review_cache_log = cache_file();
	my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $EC2C);
        log_registry("ExternalCdma2000Cell $EC2C get deleted , It was not expected...") if (!($rev_log) or $state eq "NO");
        log_registry("ExternalCdma2000Cell $EC2C is not deleted, Its ok, it can not be deleted until its reservedBy set ...") if ($rev_log and $state eq "YES");
        test_failed($test_slogan) if (!($rev_log) or $status eq "OK" or  $state eq "NO");
        test_passed($test_slogan) if ($rev_log and $status ne "OK" and $state eq "YES");
  }
  else
  {
        log_registry("It seems no synched ERBS found...");
        test_failed($test_slogan);
  }
}

sub FUT108  #4.4.3.2.18 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.18 ; Delete   - Delete   UtranNetwork fails from an application on a N RNC ";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne("RncFunction","UtranNetwork");
  if($rnc)
  {
        my $UN;
        my ($count,@UN) = get_CMS_mo("UtranNetwork",$rnc);
        test_failed($test_slogan) if not $count;
        return "0" if not $count;
        foreach(@UN)
        {
                my %attrs = get_mo_attributes_CS(mo => $_ , attributes=>"reservedBy");
                $UN = $_ if ($attrs{reservedBy} and $attrs{reservedBy} =~ /IurLink\=/);
                last if $UN;
        }
        log_registry("It seems no UtranNetwork MO found having reservedBy attribute set under RNC ...") if not $UN;
        test_failed($test_slogan) if not $UN;
        return "0" if not $UN;
        log_registry("====================================================================================");
        get_mo_attr($UN,"reservedBy");
        log_registry("====================================================================================");
        log_registry("Deleting UtranNetwork: $UN");
        my $status = delete_mo_CLI(mo => $UN, base => "CSCLI");
        log_registry("It seems UtranNetwork get deleted ..") if ($status eq "OK");
        log_registry("UtranNetwork MO not get deleted") if ($status ne "OK");
        log_registry("wait for 2 mins to get system stabilized...");
        sleep 120;
        my $state = does_mo_exist_CLI( base => CSCLI, mo => $UN);
	my $review_cache_log = cache_file();
	my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $UN);
        log_registry("UtranNetwork $UN get deleted , It was not expected...") if (!($rev_log) or $state eq "NO");
        log_registry("UtranNetwork $UN is not deleted, Its ok, it can not be deleted until its reservedBy set ...") if ($rev_log and $state eq "YES");
        test_failed($test_slogan) if (!($rev_log) or $status eq "OK" or  $state eq "NO");
        test_passed($test_slogan) if ($rev_log and $status ne "OK" and $state eq "YES");
  }
  else
  {
        log_registry("It seems no synched RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT109  #4.4.3.3.4
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.3.4 ; Delete   - Delete   ExternalUtranCell fails due to reservedBy set";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne("RncFunction");
  if($rnc)
  {
        my $EUC;
        my ($count,@EUC) = get_CMS_mo("ExternalUtranCell",$rnc);
        test_failed($test_slogan) if not $count;
        return "0" if not $count;
        foreach(@EUC)
        {
                my %attrs = get_mo_attributes_CS(mo => $_ , attributes=>"reservedBy");
                $EUC = $_ if ($attrs{reservedBy} and $attrs{reservedBy} =~ /UtranRelation\=/);
                last if $EUC;
        }
        log_registry("It seems no ExternalUtranCell MO found having reservedBy attribute set under RNC ...") if not $EUC;
        test_failed($test_slogan) if not $EUC;
        return "0" if not $EUC;
        log_registry("====================================================================================");
        get_mo_attr($EUC,"reservedBy");
        log_registry("====================================================================================");
        log_registry("Deleting ExternalUtranCell : $EUC");
        my $status = delete_mo_CLI(mo => $EUC, base => "CSCLI");
        log_registry("It seems ExternalUtranCell get deleted ..") if ($status eq "OK");
        log_registry("ExternalUtranCell MO not get deleted") if ($status ne "OK");
        log_registry("wait for 2 mins to get system stabilized...");
        sleep 120;
        my $state = does_mo_exist_CLI( base => CSCLI, mo => $EUC);
	my $review_cache_log = cache_file();
	my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $EUC);
        log_registry("ExternalUtranCell $EUC get deleted , It was not expected...") if (!($rev_log) or $state eq "NO");
        log_registry("ExternalUtranCell $EUC is not deleted, Its ok, it can not be deleted until its reservedBy set ...") if ($rev_log and $state eq "YES");
        test_failed($test_slogan) if (!($rev_log) or $status eq "OK" or  $state eq "NO");
        test_passed($test_slogan) if ($rev_log and $status ne "OK" and $state eq "YES");
  }
  else
  {
        log_registry("It seems no synched RNC found...");
        test_failed($test_slogan);
  }
}

sub FUT110 # 4.4.3.3.2
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.3.2 ; Delete   - Delete unreserved   UtranFrequency with corresponding Master ExternalUtranFreq from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne(ENodeBFunction,EUtranCellFDD);
  if($ERBS)
  {
        my $flag = 0;
        my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
        my $UtraNW = pick_a_mo($ERBS,UtraNetwork);
        log_registry("It seems there is no UtraNetwork under the ERBS....") if not $UtraNW;
        test_failed("$test_slogan") if not $UtraNW;
        return "0" if not $UtraNW;
        my ($UF,$UF_attr) = get_fdn("UtranFrequency","create");
        $UF = base_fdn_modify($UtraNW,$UF);
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$UF,$UF_attr,"no wait");
        test_failed($test_slogan) if not ($status and $rev_id);
        return "0" if not ($status and $rev_id);
        my ($UFR_fdn,$UF_fdn,$EUF)  = create_UtranFreqRelation(EUCFDD => $EUCFDD,UF => $UF, base => CLI);
        log_registry("It seems there is some problem in creation of UtranFreqRelation ...") if not $UFR_fdn;
        test_failed($test_slogan) if not $UFR_fdn;
        return "0" if not $UFR_fdn;
        my $master_mo = get_master_for_proxy($UF);
        $flag = 1 if($master_mo !~ /$EUF/);
        log_registry("It seems created proxy $UF does not have $EUF as master") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
	log_registry("Delete Relation $UFR_fdn");
	my $result = delete_mo_CS( mo => $UFR_fdn);
	log_registry("Problem in deletion of UtranFreqRelation ..") if $result;
	test_failed("$test_slogan") if $result;
	return "0" if $result;
	log_registry("Wait for 2 mins to get system stabilized....");
	sleep 120;
	$master_mo = get_master_for_proxy($UF);
	log_registry("Master => $master_mo");
	$flag = 1 if($master_mo !~ /$EUF/);
        log_registry("It seems now proxy $UF does not have $EUF as master") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
	log_registry("====================================================================================");
        get_mo_attr($UF);
        log_registry("====================================================================================");
	log_registry("It seems still proxy $UF have $EUF as master and no reservedBy attribute set");
	log_registry("Now deleting proxy UtranFrequency while master mo exist...");
	my $state = proxy_mo_delete_decision("$test_slogan","CSCLI","$UF");
        log_registry("Issue in deletion of UtranFrequency mo") if not $state;
	################################ Clean up #######################################################
        log_registry("Clean up: Deleting MO $EUF ");
        my $clean_issue = delete_mo_CS( mo => $EUF);
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
  }
  else
  {
		log_registry("It seems no synched ERBS found....");
		test_failed("$test_slogan");
  } 
}

sub FUT111 # 4.4.3.3.5
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.3.5 ; Delete   - Delete   ExternalUtranCell fails due to reservedBy set from UtranCellRelation and UtranRelation";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($count_UCR,@UCR) = get_CMS_mo("UtranCellRelation","$mo_proxy_cms");
  my ($count_UR,@UR) = get_CMS_mo("UtranRelation","$mo_proxy_cms");
  my ($count_EUC,@EUC) = get_CMS_mo("ExternalUtranCell","$mo_proxy_cms");
  if($count_UCR and $count_UR and $count_EUC)
  {
	my $flag = 0;
	my $MEUC,$UCR,$UR,$PEUC,$PEUCFDD;
	foreach(@EUC) {
		$MEUC = $_ if ($_ !~ /MeContext\=/);
		last if $MEUC;	}
	$flag = 1 if not $MEUC;
	log_registry("It seems no master ExternalUtranCell found created by proxy.pl") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	foreach(@UCR) {
		my %attrs = get_mo_attributes_CS(mo => $_ , attributes=>"adjacentCell externalUtranCellFDDRef");
		$UCR = $_ if ($attrs{adjacentCell} and $attrs{adjacentCell} =~ /$MEUC/);
		$PEUCFDD = $attrs{externalUtranCellFDDRef};
		last if $UCR; }
	foreach(@UR) {
		my %attrs = get_mo_attributes_CS(mo => $_ , attributes=>"adjacentCell utranCellRef");
		$UR = $_ if ($attrs{adjacentCell} and $attrs{adjacentCell} =~ /$MEUC/);
		$PEUC = $attrs{utranCellRef};
		last if $UR; }
	$flag = 1 if (!($UR) or !($UCR));
	log_registry("It seems no UtranCellRelation and UtranRelation found those have same master ExternalUtranCell as reference for adjacentCell") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	$flag = 1 if (!($PEUCFDD) or !($PEUC));
	log_registry("It seems UtranCellRelation or UtranRelation does not have proxy ExternalUtranCellFDD or ExternalUtranCell attached respectivley..") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	my $proxies = get_proxies_master($MEUC);
	log_registry("Proxies for master $MEUC are: \n $proxies") if $proxies;
	$flag = 1 if(!($proxies) or $proxies !~ /$PEUCFDD/ or $proxies !~ /$PEUC/);
	log_registry("It seems any or both proxy ExternalutranCell linked with relation does not have master ExternalUtranCell $MEUC as master") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	log_registry("Trying to delete Master ExternalUtranCell $MEUC ...");
        my $result = delete_mo_CS( mo => $MEUC );
        log_registry("Master ExternalUtranCell $MEUC is not deleted ") if $result;
	log_registry("Master ExternalUtranCell $MEUC get deleted while relation exist..") if not $result;
	log_registry("wait for 1 min ...");
	sleep 60;
        my $review_cache_log = cache_file();
        my ($Mrev_id,$Mrev_log) = rev_find(file => $review_cache_log,mo => $MEUC);
	my ($Prev_id,$Prev_log) = rev_find(file => $review_cache_log,mo => $PEUC);
	log_registry("It seems either proxy $PEUC or master $MEUC get deleted..") if (!($Mrev_log) or !($Prev_log));
	test_failed("$test_slogan") if (!($Mrev_log) or !($Prev_log));
	return "0" if (!($Mrev_log) or !($Prev_log));
	log_registry("Deleting UtranRelation $UR ....");
	$result = delete_mo_CS( mo => $UR );
	log_registry("Problem in deletion of UtranRelation...") if $result;
	test_failed("$test_slogan") if $result;
	return "0" if $result;
	sleep 60;
	$review_cache_log = cache_file();
	($Mrev_id,$Mrev_log) = rev_find(file => $review_cache_log,mo => $MEUC);
	($Prev_id,$Prev_log) = rev_find(file => $review_cache_log,mo => $PEUC);
	log_registry("It seems proxy ExternalUtranCell $PEUC get deleted ...") if not $Prev_log;	
	log_registry("Master ExternalUtranCell still exist..") if $Mrev_log;
	log_registry("It seems proxy ExternalUtranCell $PEUC is not get deleted ..") if $Prev_log;
        log_registry("Again Trying to delete Master ExternalUtranCell $MEUC ...");
        my $result = delete_mo_CS( mo => $MEUC );
        log_registry("Master ExternalUtranCell $MEUC is not deleted ") if $result;
        log_registry("Master ExternalUtranCell $MEUC get deleted while relation exist..") if not $result;
        log_registry("wait for 1 min ...");
        sleep 60;
	$review_cache_log = cache_file();
	($Mrev_id,$Mrev_log) = rev_find(file => $review_cache_log,mo => $MEUC);
	($Prev_id,$Prev_log) = rev_find(file => $review_cache_log,mo => $PEUCFDD);
        log_registry("It seems either proxy $PEUCFDD or master $MEUC get deleted..") if (!($Mrev_log) or !($Prev_log));
        test_failed("$test_slogan") if (!($Mrev_log) or !($Prev_log));
        return "0" if (!($Mrev_log) or !($Prev_log));
        log_registry("Deleting UtranCellRelation $UCR ....");
        $result = delete_mo_CS( mo => $UCR );
        log_registry("Problem in deletion of UtranCellRelation...") if $result;
        test_failed("$test_slogan") if $result;
        return "0" if $result;
        sleep 60;
        $review_cache_log = cache_file();
        ($Mrev_id,$Mrev_log) = rev_find(file => $review_cache_log,mo => $MEUC);
        ($Prev_id,$Prev_log) = rev_find(file => $review_cache_log,mo => $PEUCFDD);
        log_registry("It seems proxy ExternalUtranCell $PEUCFDD get deleted ...") if not $Prev_log;
        log_registry("Master ExternalUtranCell still exist..") if $Mrev_log;
        log_registry("It seems proxy ExternalUtranCellFDD $PEUCFDD is not get deleted ..") if $Prev_log;
	log_registry("Deleting master ExternalUtranCell $MEUC....");
        $result = delete_mo_CS( mo => $MEUC );
        log_registry("Problem in deletion of ExternalUtranCell ...") if $result;
        test_failed("$test_slogan") if $result;
        return "0" if $result;
        sleep 60;
        $review_cache_log = cache_file();
        ($Mrev_id,$Mrev_log) = rev_find(file => $review_cache_log,mo => $MEUC);
	($Prev_id,$Prev_log) = rev_find(file => $review_cache_log,mo => $PEUCFDD);
	my ($Prev_id1,$Prev_log1) = rev_find(file => $review_cache_log,mo => $PEUC);
	log_registry("It seems master ExternalUtranCell $MEUC get deleted ...") if not $Mrev_log;
	log_registry("It seems proxy ExternalUtranCellFDD $PEUCFDD get deleted ...") if not $Prev_log;
	log_registry("It seems proxy ExternalUtranCell $PEUC get deleted ...") if not $Prev_log1;
	$flag = 1 if ($Mrev_log or $Prev_log1);
	log_registry("It seems either master ExternalUtranCell or proxy ExternalUtranCell exist while all relation deleted and its is expected all master and proxy ExternalUtranCell related to relation will get deleted..") if $flag;
	test_failed($test_slogan) if $flag;
	log_registry("It seems proxy ExternalUtranCellFDD $PEUCFDD exists...") if $Prev_log;
	log_registry("Warning => SNAD does not delete unused/redundant proxy ExternalUtranCellFDD Mo as this is off by default") if $Prev_log;
	test_passed($test_slogan) if not $flag;
	####################################Clean up#################################
	log_registry("Clean up: Deleting ExternalUtranCellFDD $PEUCFDD ..");
	my $clean_issue = delete_mo_CS( mo => $PEUCFDD);
	log_registry("Warning => problem in  deletion of ExternalUtranCellFDD Mo..") if $clean_issue;
  }
  else
  {
	log_registry("It seems UtranCellRelation/UtranRelation/ExternalUtranCell created by proxy.pl does not exits");
	test_failed("$test_slogan");
  }
}

sub FUT112 # 4.4.1.2.39
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.2.39 ; Create proxy ExternalUtranCell when no master exists from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne("RncFunction");
  if($rnc)
  {
	my $cell = pick_a_mo("$rnc","UtranCell");
	log_registry("It seems no UtranCell exist under RNC..") if not $cell;
	test_failed("$test_slogan") if not $cell;
	return "0" if not $cell;
        my $IurLink = pick_a_mo($rnc,IurLink);
        log_registry("It seems no IurLink has been selected for the RNC => $rnc") if not $IurLink;
        test_failed($test_slogan) if not $IurLink;
        return "0" if not $IurLink;
  	my ($base_fdn,$attr) = get_fdn("ExternalUtranCell","create");
        $base_fdn = base_fdn_modify("$IurLink","$base_fdn");
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$base_fdn,$attr,"no wait");
	log_registry("It seems proxy ExternalUtranCell get created...") if $status;
	log_registry("There is a problem in creation of proxy ExternalUtranCell MO ..") if not $status;
	test_failed("$test_slogan") if not $status;
	return "0" if not $status;
        my ($UtranRelation,$M_EUC) = create_UtranRelation( F_UtranCell => $cell, base=> "CLI",uCR => $base_fdn);
        log_registry("It seems problem in creation of UtranRelation..") if not $UtranRelation;
        test_failed($test_slogan) if not $UtranRelation;
        return "0" if not $UtranRelation;
	my $master = get_master_for_proxy($base_fdn);
	log_registry("Master of proxy ExternalUtranCell $base_fdn is: \n $master") if $master;
	my $flag = 0;
	$flag = 1 if (!($master) or $master !~ /$M_EUC/);
	log_registry("It seems master of created proxy ExternalUtranCell $base_fdn does not seems to be master ExternalUtranCell created by UtranRelation..") if $flag;
	test_failed($test_slogan) if $flag;
	return "0" if $flag;
	test_passed($test_slogan);
        ############################# CLEAN UP ##################################
        my $clean_issue;
        my $mo = join(" ",$UtranRelation,$M_EUC);
        my @mo = split(" ",$mo);
        foreach(@mo)
        {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
        }
  }
  else
  {
	log_registry("It seems no Synched RNC found ....");
	test_failed($test_slogan);
  }
}

sub FUT113 #4.4.1.2.45 and 4.4.1.2.46
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.1\.2\.45/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.1\.2\.46/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.45 ; Create Proxy MO - Create Proxy MO ExternalEUtranCellFDD/TDD when no EUtranCellFDD/TDD master exists from an application" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.46 ; Create Proxy MO - Create Proxy MO ExternalEUtranCellFDD/TDD when no EUtranCellFDD/TDD master exists through the EM (netsim)" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS_FDD = pick_a_erbs_using_cell(CELL => "EUtranCellFDD");
  my $ERBS_TDD = pick_a_erbs_using_cell(CELL => "EUtranCellTDD");

  if($ERBS_FDD and $ERBS_TDD)
  {
	my $flag = 0; 
  	my $proxies_FDD = get_proxies_master($ERBS_FDD);   # from picked ERBS grep a proxy on another ERBS
  	my ($count,@EENBF_FDD) = format_proxies($proxies_FDD);
 
  	my $proxies_TDD = get_proxies_master($ERBS_TDD);   # from picked ERBS grep a proxy on another ERBS
  	my ($icount,@EENBF_TDD) = format_proxies($proxies_TDD);
	
	
	my $EENBF_FDD = $EENBF_FDD[int(rand($#EENBF_FDD))];
	my $EENBF_TDD = $EENBF_TDD[int(rand($#EENBF_FDD))];
	
	$ERBS_FDD = get_mec($EENBF_FDD);
	$ERBS_TDD = get_mec($EENBF_TDD);
	
	$flag = 1 if (!($count) or !($icount));
	log_registry("It seems that a ExternalENodeBFunction MO was not found for the choosen ERBS .. counts: $count or $icount") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	my ($EUF_count,@EUF_FDD) = get_CMS_mo("EUtranFrequency",$ERBS_FDD);
	my ($count_EUF,@EUF_TDD) = get_CMS_mo("EUtranFrequency",$ERBS_TDD);
	$flag = 1 if (!($EUF_count) or !($count_EUF));
	log_registry("It seems no EUtranFrequency MO found under any of ERBS ...") if $flag;
	test_failed("$test_slogan") if $flag;
        return "0" if $flag;
	my ($EUFR_count,@EUFR_FDD) = get_CMS_mo("EUtranFreqRelation",$ERBS_FDD);
	my ($count_EUFR,@EUFR_TDD) = get_CMS_mo("EUtranFreqRelation",$ERBS_TDD);
	$flag = 1 if (!($EUFR_count) or !($count_EUFR));
        log_registry("It seems no EUtranFreqRelation found under any of ERBS ...") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;

	my $EUF_FDD = $EUF_FDD[0];
	my $EUF_TDD = $EUF_TDD[0];
	my $EUFR_FDD = $EUFR_FDD[int(rand($#EUFR_FDD))];

#	my @temp_EUFR_TDD = grep {$_ =~ /E36000/}@EUFR_TDD;
#	my $EUFR_TDD = $temp_EUFR_TDD[int(rand($#temp_EUFR_TDD))];

	my $EUFR_TDD = $EUFR_TDD[int(rand($#EUFR_TDD))];

	my ($EEUCFDD,$attr_EEUCFDD) = get_fdn("ExternalEUtranCellFDD","create");
	my ($EEUCTDD,$attr_EEUCTDD) = get_fdn("ExternalEUtranCellTDD","create");
	$EEUCFDD = base_fdn_modify("$EENBF_FDD","$EEUCFDD");
	$EEUCTDD = base_fdn_modify("$EENBF_TDD","$EEUCTDD");
	$attr_EEUCFDD = "$attr_EEUCFDD"." "."$EUF_FDD";
	$attr_EEUCTDD = "$attr_EEUCTDD"." "."$EUF_TDD";
	my $status_EEUCFDD,$status_EEUCTDD,$rev_EEUCFDD,$rev_EEUCTDD;
	($status_EEUCFDD,$rev_EEUCFDD) = proxy_mo_create_decision("CSCLI",$EEUCFDD,$attr_EEUCFDD,"no wait") if($tc_id == 1);
	($status_EEUCTDD,$rev_EEUCTDD) = proxy_mo_create_decision("CSCLI",$EEUCTDD,$attr_EEUCTDD,"no wait") if($tc_id == 1);
	($status_EEUCFDD,$rev_EEUCFDD) = proxy_mo_create_decision("CLI",$EEUCFDD,$attr_EEUCFDD,"no wait") if($tc_id == 2);
	($status_EEUCTDD,$rev_EEUCTDD) = proxy_mo_create_decision("CLI",$EEUCTDD,$attr_EEUCTDD,"no wait") if($tc_id == 2);
	$flag = 1 if (!($status_EEUCFDD) or !($status_EEUCTDD));
	log_registry("There is a problem in creation of ExternalEUtranCellTDD/ExternalEUtranCellFDD MO ...") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	my $nudge = forceCC($EEUCTDD);
	my $nudge2 = forceCC($EEUCFDD);

	log_registry("The return from nudge is $nudge and $nudge2 ");
# 	long_sleep_found($nudge) if $nudge;	 # eeitjn it did seem to nudge CC to run so put in two minute wait

        log_registry("Wait for 2 Mins to get system stabilized....");
        sleep 120;
        
        my $review_cache_log = cache_file();
        my ($rev_FDD,$rev_log_FDD) = rev_find(file => $review_cache_log,mo => $EEUCFDD);
	my ($rev_TDD,$rev_log_TDD) = rev_find(file => $review_cache_log,mo => $EEUCTDD);
	$flag = 1 if ($rev_FDD != 7 or $rev_TDD != 7);
	log_registry("It seems either of ExternalEUtranCellTDD/ExternalEUtranCellFDD MO is not Redundant ...") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
	log_registry("It seems ExternalEUtranCellTDD/ExternalEUtranCellFDD MOs are Redundant ...");
	my $EUCR_FDD = create_EUtranCellRelation(base=>"CLI", EUFR=>$EUFR_FDD,EEUCXDD => $EEUCFDD);
	my $EUCR_TDD = create_EUtranCellRelation(base=>"CLI", EUFR=>$EUFR_TDD,EEUCXDD => $EEUCTDD);
	$flag = 1 if (!($EUCR_FDD) or !($EUCR_TDD));
	log_registry("There is a problem in creation of any of EUtranCellRelation with ExternalEUtranCellTDD/ExternalEUtranCellFDD MO....") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	my $master_FDD = get_master_for_proxy($EEUCFDD);
	my $master_TDD = get_master_for_proxy($EEUCTDD);
	$flag = 1 if ($master_FDD !~ "MissingMaster" or $master_TDD !~ "MissingMaster");
	log_registry("Master Mo does not exist for proxy ExternalEUtranCellTDD/ExternalEUtranCellFDD MO...") if not $flag;
	log_registry("Master MO for ExternalEUtranCellFDD is: $master_FDD") if $master_FDD;
	log_registry("Master MO for ExternalEUtranCellTDD is: $master_TDD") if $master_TDD;
        $review_cache_log = cache_file();
        ($rev_FDD,$rev_log_FDD) = rev_find(file => $review_cache_log,mo => $EEUCFDD);
	($rev_TDD,$rev_log_TDD) = rev_find(file => $review_cache_log,mo => $EEUCTDD);
	$flag = 1 if(!($rev_FDD) or !($rev_TDD) or $rev_FDD != 3 or $rev_TDD != 3);
	log_registry("It seems either of ExternalEUtranCellTDD/FDD does not have MissingMaster consistency state, Flag is $flag , $rev_FDD or $rev_TDD is 3 ??") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;	
	test_passed("$test_slogan");
	####################################### Clean up #####################################################
	my $clean_issue,$mo;
        $mo = join(" ",$EUCR_FDD,$EUCR_TDD,$EEUCFDD,$EEUCTDD);
        my @mo = split(" ",$mo);
        foreach(@mo) {
        	log_registry("Clean up: Deleting MO $_ ");
        	$clean_issue = delete_mo_CS( mo => $_);
        	log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; 
        	
        	# eeitjn if any failed to delete retry using CLI (EUtranCellRelation were not deleting in 13.0)
                if ($clean_issue) {
                	    my $status = delete_mo_CLI(mo => $_, base => "CLI");
                	    log_registry("Delete result => $status");   
                	    }
        	
        	
        	}
  }
  else
  {
  	log_registry("It seems no Synched ERBS found that have ExternalEUtranCellFDD/ExternalEUtranCellTDD under it...");
  	log_registry("or could not find ERBS suitable which would not generate a master Cell for FDD or TDD...");
	test_failed("$test_slogan");
  }
}

sub FUT114 #4.4.1.11.2
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.11.2; Create Cdma2000FreqRelation (valid) with the adjacentFreq attribute set to snExternalCdma2000Freq. Proxy freq and parents exist on the ERBS;; 2";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(MO => "Cdma2000FreqBandRelation",VER => "NEW");
  if($ERBS)
  {
        my ($count,@C2FBR) = get_CMS_mo("Cdma2000FreqBandRelation",$ERBS);
        test_failed($test_slogan) if not $count;
        return "0" if not $count;
        my $C2FBR = $C2FBR[int(rand($#C2FBR))];
	log_registry("Selected Cdma2000FreqBandRelation : $C2FBR");
	my %C2FBR_attrs = get_mo_attributes_CS(mo =>$C2FBR,attributes => "adjacentFreqBand");
	log_registry("It seems selected Cdma2000FreqBandRelation has no point to ExternalCdma2000FreqBand mo ..") if not $C2FBR_attrs{adjacentFreqBand};
	test_failed($test_slogan) if not $C2FBR_attrs{adjacentFreqBand};
	return "0" if not $C2FBR_attrs{adjacentFreqBand};
	my $EC2FB = $C2FBR_attrs{adjacentFreqBand};
	$EC2FB =~ s/\n+//g;
	log_registry("Selected ExternalCdma2000FreqBand mo: $EC2FB");
	my ($icount,@EC2F) = get_CMS_mo("ExternalCdma2000Freq","$EC2FB");
	log_registry("It seems selected ExternalCdma2000FreqBand does not have any master ExternalCdma2000Freq Mo under it..") if not $icount;
	test_failed($test_slogan) if not $icount;
	return "0" if not $icount;
	my $EC2F = $EC2F[int(rand($#EC2F))];
	log_registry("Selected ExternalCdma2000Freq mo: $EC2F");
	my ($C2FR,$C2F) = create_Cdma2000FreqRelation( C2FBR => $C2FBR , EC2F => $EC2F,base => "CSCLI" );
	log_registry("There is a problem in creation of Cdma2000FreqRelation ...") if not $C2FR;
	test_failed($test_slogan) if not $C2FR;
	return "0" if not $C2FR;
        log_registry("====================================================================================");
        get_mo_attr($C2F,"reservedBy");
        log_registry("====================================================================================");
        test_passed($test_slogan);
        ############################### Clean up #########################################
        log_registry("Clean up: Deleting MO $C2FR ");
        my $clean_issue = delete_mo_CS( mo => $C2FR);
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
  }
  else
  {
        log_registry("It seems no synched ERBS found of version vB.1.20 having Cdma2000FreqBandRelation");
        test_failed($test_slogan);
  }
}

sub FUT115 #4.4.1.11.3
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.11.3; Create Cdma2000FreqRelation MOs (using an application), under 2 EUtranCellFDDs in the same ERBS, with their adjacentFreq attributes set to the same snExternalCdma2000Freq;; 2";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(CELL=> "EUtranCellFDD",VER => "NEW");
  if($ERBS)
  {
        my ($count_euc,@EUC) = get_CMS_mo("EUtranCellFDD",$ERBS);
	log_registry("It seems selected ERBS does not have atleast 2 EUtranCellFDD MO under it.. $ERBS") if (!($count_euc) or ($count_euc < 2));
	test_failed($test_slogan) if (!($count_euc) or ($count_euc < 2));
        return "0" if (!($count_euc) or ($count_euc < 2));
	my $EUC1 = $EUC[0];
	my $EUC2 = $EUC[1];
	log_registry("Selected First EUtranCellFDD : $EUC1");
	log_registry("Selected Second EUtranCellFDD : $EUC2");
        my ($count_c2fbr1,@C2FBR1) = get_CMS_mo("Cdma2000FreqBandRelation",$EUC1);
	log_registry("It seems no Cdma2000FreqBandRelation exist for EUtranCellFDD mo $EUC1") if not $count_c2fbr1;
        test_failed($test_slogan) if not $count_c2fbr1;
        return "0" if not $count_c2fbr1;
        my $C2FBR1 = $C2FBR1[int(rand($#C2FBR1))];
	my ($count_c2fbr2,@C2FBR2) = get_CMS_mo("Cdma2000FreqBandRelation",$EUC2);
	log_registry("It seems no Cdma2000FreqBandRelation exist for EUtranCellFDD mo $EUC2") if not $count_c2fbr2;
        test_failed($test_slogan) if not $count_c2fbr2;
        return "0" if not $count_c2fbr2;
        my $C2FBR2 = $C2FBR2[int(rand($#C2FBR2))];
        log_registry("Selected First Cdma2000FreqBandRelation : $C2FBR1");
	log_registry("Selected Second Cdma2000FreqBandRelation : $C2FBR2");
        my %C2FBR_attrs = get_mo_attributes_CS(mo =>$C2FBR1,attributes => "adjacentFreqBand");
        log_registry("It seems selected Cdma2000FreqBandRelation does not pointing to ExternalCdma2000FreqBand mo ..") if not $C2FBR_attrs{adjacentFreqBand};
        test_failed($test_slogan) if not $C2FBR_attrs{adjacentFreqBand};
        return "0" if not $C2FBR_attrs{adjacentFreqBand};
        my $EC2FB = $C2FBR_attrs{adjacentFreqBand};
        $EC2FB =~ s/\n+//g;
        log_registry("Selected ExternalCdma2000FreqBand mo: $EC2FB");
        my ($icount,@EC2F) = get_CMS_mo("ExternalCdma2000Freq","$EC2FB");
        log_registry("It seems any of selected ExternalCdma2000FreqBand does not have any master ExternalCdma2000Freq Mo under it..") if not $icount;
        test_failed($test_slogan) if not $icount;
        return "0" if not $icount;
        my $EC2F = $EC2F[int(rand($#EC2F))];
        log_registry("Selected First ExternalCdma2000Freq mo: $EC2F");
        my ($C2FR1,$C2F1) = create_Cdma2000FreqRelation( C2FBR => $C2FBR1 , EC2F => $EC2F,base => "CSCLI" );
        log_registry("There is a problem in creation of Cdma2000FreqRelation ...") if not $C2FR1;
        test_failed($test_slogan) if not $C2FR1;
        return "0" if not $C2FR1;
	my ($C2FR2,$C2F2) = create_Cdma2000FreqRelation( C2FBR => $C2FBR2, EC2F => $EC2F,base => "CSCLI" );
        log_registry("There is a problem in creation of Cdma2000FreqRelation ...") if not $C2FR2;
        test_failed($test_slogan) if not $C2FR2;
        return "0" if not $C2FR2;
	my %C2F2_attrs = get_mo_attributes_CS(mo =>$C2F2,attributes => "reservedBy");
	log_registry("It seems $C2F2 does not reservedBy Cdma2000FreqRelation $C2FR1...") if ($C2F2_attrs{reservedBy} !~ /$C2FR1/);
        test_failed($test_slogan) if ($C2F2_attrs{reservedBy} !~ /$C2FR1/);
        log_registry("====================================================================================");
        get_mo_attr($C2F1,"reservedBy");
        log_registry("====================================================================================");
        log_registry("====================================================================================");
        get_mo_attr($C2F2,"reservedBy");
        log_registry("====================================================================================");
        test_passed($test_slogan) if ($C2F2_attrs{reservedBy} =~ /$C2FBR1/);
        ############################### Clean up #########################################
        log_registry("Clean up: Deleting MO $C2FR1 ");
        my $clean_issue = delete_mo_CS( mo => $C2FR1);
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
	log_registry("Clean up: Deleting MO $C2FR2 ");
        $clean_issue = delete_mo_CS( mo => $C2FR2);
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
  }
  else
  {
        log_registry("It seems no synched ERBS found of version vB.1.20 having EUtranCellFDD under it");
        test_failed($test_slogan);
  }
}

sub FUT116  #4.4.1.11.4
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.11.4; Create Cdma2000FreqRelation using netsim, Cdma2000FrequencyRef is set to proxy Cdma2000Frequency, master snExternalCdma2000Freq exists;;1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(MO => "Cdma2000FreqBandRelation",VER => "NEW");
  if($ERBS)
  {
        my ($count,@C2FBR) = get_CMS_mo("Cdma2000FreqBandRelation",$ERBS);
        test_failed($test_slogan) if not $count;
        return "0" if not $count;
        my $C2FBR = $C2FBR[int(rand($#C2FBR))];
        my ($icount,@C2F) = get_CMS_mo("Cdma2000Freq",$ERBS);
        log_registry("It seems no Cdma2000Freq mo under ERBS ... $ERBS") if not $icount;
        test_failed($test_slogan) if not $icount;
        return "0" if not $icount;
        my $C2F = $C2F[int(rand($#C2F))];
        my ($C2FR,$EC2F) = create_Cdma2000FreqRelation( C2FBR => $C2FBR , C2F => $C2F,base => "CLI" );
        log_registry("There is a problem in creation of Cdma2000FreqRelation ...") if not $C2FR;
        test_failed($test_slogan) if not $C2FR;
        return "0" if not $C2FR;
        log_registry("====================================================================================");
        get_mo_attr($C2F,"reservedBy");
        log_registry("====================================================================================");
	test_passed($test_slogan);
        ############################### Clean up #########################################
        log_registry("Clean up: Deleting MO $C2FR ");
        my $clean_issue = delete_mo_CS( mo => $C2FR);
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
  }
  else
  {
		log_registry("It seems no synched ERBS found of version vB.1.20 or later having Cdma2000FreqBandRelation");
		test_failed($test_slogan);
  }
}

sub FUT117  #4.4.1.11.5
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.11.5; Create Cdma2000FreqRelation using netsim. The Cdma2000FrequencyRef is set to proxy Cdma2000Frequency. Master snExternalCdma2000Freq does not exist;;1 ";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(MO => "Cdma2000FreqBandRelation",VER => "NEW");
  if($ERBS)
  {
        my ($count,@C2FBR) = get_CMS_mo("Cdma2000FreqBandRelation",$ERBS);
        test_failed($test_slogan) if not $count;
        return "0" if not $count;
        my $C2FBR = $C2FBR[int(rand($#C2FBR))];
        my ($icount,@C2FB) = get_CMS_mo("Cdma2000FreqBand",$ERBS);
        log_registry("It seems no Cdma2000FreqBand mo under ERBS ... $ERBS") if not $icount;
        test_failed($test_slogan) if not $icount;
        return "0" if not $icount;
	my $C2FB = $C2FB[int(rand($#C2FB))];
	my ($C2F,$attrs) = get_fdn("Cdma2000Freq","create");
	$C2F = base_fdn_modify("$C2FB","$C2F");
	my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$C2F,$attrs,"no wait");
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
        my ($C2FR,$EC2F) = create_Cdma2000FreqRelation( C2FBR => $C2FBR , C2F => $C2F,base => "CLI" );
        log_registry("There is a problem in creation of Cdma2000FreqRelation ...") if not $C2FR;
        test_failed($test_slogan) if not $C2FR;
        return "0" if not $C2FR;
        log_registry("====================================================================================");
        get_mo_attr($C2F,"reservedBy");
        log_registry("====================================================================================");
	test_passed($test_slogan);
	##################### Clean up for second TC ###############################
        my $clean_issue,$mo;
	$mo = join(" ",$C2FBR,$C2F,$EC2F);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }

  }
  else
  {
		log_registry("It seems no synched ERBS found of version vB.1.20 or later having Cdma2000FreqBandRelation");
		test_failed($test_slogan);
  }
}

sub FUT118 #4.4.3.6.9
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.6.9 ; Delete Cdma2000FreqRelation MO under EUtranCellFDD and EUtranCellTDD in ERBS MIBs when more than one Cdma2000Freqrelations exits (valid/netsim);Normal;2";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS1 = pick_a_erbs_using_cell(CELL=> "EUtranCellFDD",VER => "NEW");
  my $ERBS2 = pick_a_erbs_using_cell(CELL=> "EUtranCellTDD",VER => "NEW");
  if($ERBS1 and $ERBS2)
  {
        my ($count_euc,@EUC) = get_CMS_mo("EUtranCellFDD",$ERBS1);
        log_registry("It seems selected ERBS does not have atleast 3 EUtranCellFDD MO under it.. $ERBS1") if (!($count_euc) or ($count_euc < 3));
        test_failed($test_slogan) if (!($count_euc) or ($count_euc < 3));
        return "0" if (!($count_euc) or ($count_euc < 3));
        my $EUC1 = $EUC[0];
        my $EUC2 = $EUC[1];
	my $EUC3 = $EUC[2];
        log_registry("Selected First EUtranCellFDD : $EUC1");
        log_registry("Selected Second EUtranCellFDD : $EUC2");
	log_registry("Selected Third EUtranCellFDD : $EUC3");
        my ($count_c2fbr1,@C2FBR1) = get_CMS_mo("Cdma2000FreqBandRelation",$EUC1);
        log_registry("It seems no Cdma2000FreqBandRelation exist for EUtranCellFDD mo $EUC1") if not $count_c2fbr1;
        test_failed($test_slogan) if not $count_c2fbr1;
        return "0" if not $count_c2fbr1;
        my $C2FBR1 = $C2FBR1[int(rand($#C2FBR1))];
        my ($count_c2fbr2,@C2FBR2) = get_CMS_mo("Cdma2000FreqBandRelation",$EUC2);
        log_registry("It seems no Cdma2000FreqBandRelation exist for EUtranCellFDD mo $EUC2") if not $count_c2fbr2;
        test_failed($test_slogan) if not $count_c2fbr2;
        return "0" if not $count_c2fbr2;
        my $C2FBR2 = $C2FBR2[int(rand($#C2FBR2))];
    	my ($count_c2fbr3,@C2FBR3) = get_CMS_mo("Cdma2000FreqBandRelation",$EUC3);
        log_registry("It seems no Cdma2000FreqBandRelation exist for EUtranCellFDD mo $EUC3") if not $count_c2fbr3;
        test_failed($test_slogan) if not $count_c2fbr3;
        return "0" if not $count_c2fbr3;
        my $C2FBR3 = $C2FBR3[int(rand($#C2FBR3))];
        log_registry("Selected First Cdma2000FreqBandRelation : $C2FBR1");
        log_registry("Selected Second Cdma2000FreqBandRelation : $C2FBR2");
	log_registry("Selected Third Cdma2000FreqBandRelation : $C2FBR3");
        my %C2FBR_attrs = get_mo_attributes_CS(mo =>$C2FBR1,attributes => "adjacentFreqBand");
        log_registry("It seems selected Cdma2000FreqBandRelation does not pointing to ExternalCdma2000FreqBand mo ..") if not $C2FBR_attrs{adjacentFreqBand};
        test_failed($test_slogan) if not $C2FBR_attrs{adjacentFreqBand};
        return "0" if not $C2FBR_attrs{adjacentFreqBand};
        my $EC2FB = $C2FBR_attrs{adjacentFreqBand};
        $EC2FB =~ s/\n+//g;
        log_registry("Selected ExternalCdma2000FreqBand mo: $EC2FB");
        my ($icount,@EC2F) = get_CMS_mo("ExternalCdma2000Freq","$EC2FB");
        log_registry("It seems any of selected ExternalCdma2000FreqBand does not have any master ExternalCdma2000Freq Mo under it..") if not $icount;
        test_failed($test_slogan) if not $icount;
        return "0" if not $icount;
        my $EC2F = $EC2F[int(rand($#EC2F))];
        log_registry("Selected First ExternalCdma2000Freq mo: $EC2F");
        my ($C2FR1,$C2F1) = create_Cdma2000FreqRelation( C2FBR => $C2FBR1 , EC2F => $EC2F,base => "CSCLI" );
        log_registry("There is a problem in creation of Cdma2000FreqRelation ...") if not $C2FR1;
        test_failed($test_slogan) if not $C2FR1;
        return "0" if not $C2FR1;
        my ($C2FR2,$C2F2) = create_Cdma2000FreqRelation( C2FBR => $C2FBR2, EC2F => $EC2F,base => "CSCLI" );
        log_registry("There is a problem in creation of Cdma2000FreqRelation ...") if not $C2FR2;
        test_failed($test_slogan) if not $C2FR2;
        return "0" if not $C2FR2;
	my ($C2FR3,$C2F3) = create_Cdma2000FreqRelation( C2FBR => $C2FBR3, EC2F => $EC2F,base => "CSCLI" );
        log_registry("There is a problem in creation of Cdma2000FreqRelation ...") if not $C2FR3;
        test_failed($test_slogan) if not $C2FR3;
        return "0" if not $C2FR3;
######################### Relation with EUtranCellTDD cells ###################################
	my ($count_euc,@EUCTDD) = get_CMS_mo("EUtranCellTDD",$ERBS2);
        log_registry("It seems selected ERBS does not have atleast 3 EUtranCellFDD MO under it.. $ERBS2") if (!($count_euc) or ($count_euc < 3));
        test_failed($test_slogan) if (!($count_euc) or ($count_euc < 3));
        return "0" if (!($count_euc) or ($count_euc < 3));
        my $EUCTDD1 = $EUCTDD[0];
        my $EUCTDD2 = $EUCTDD[1];
	my $EUCTDD3 = $EUCTDD[2];
        log_registry("Selected First EUtranCellFDD : $EUCTDD1");
        log_registry("Selected Second EUtranCellFDD : $EUCTDD2");
	log_registry("Selected Third EUtranCellFDD : $EUCTDD3");
        my ($count_c2fbr_tdd1,@C2FBR_TDD1) = get_CMS_mo("Cdma2000FreqBandRelation",$EUCTDD1);
        log_registry("It seems no Cdma2000FreqBandRelation exist for EUtranCellFDD mo $EUCTDD1") if not $count_c2fbr_tdd1;
        test_failed($test_slogan) if not $count_c2fbr_tdd1;
        return "0" if not $count_c2fbr_tdd1;
        my $C2FBR_TDD1 = $C2FBR_TDD1[int(rand($#C2FBR_TDD1))];
        my ($count_c2fbr_tdd2,@C2FBR_TDD2) = get_CMS_mo("Cdma2000FreqBandRelation",$EUCTDD2);
        log_registry("It seems no Cdma2000FreqBandRelation exist for EUtranCellFDD mo $EUCTDD2") if not $count_c2fbr_tdd2;
        test_failed($test_slogan) if not $count_c2fbr_tdd2;
        return "0" if not $count_c2fbr_tdd2;
        my $C2FBR_TDD2 = $C2FBR_TDD2[int(rand($#C2FBR_TDD2))];
	my ($count_c2fbr_tdd3,@C2FBR_TDD3) = get_CMS_mo("Cdma2000FreqBandRelation",$EUCTDD3);
        log_registry("It seems no Cdma2000FreqBandRelation exist for EUtranCellFDD mo $EUCTDD3") if not $count_c2fbr_tdd3;
        test_failed($test_slogan) if not $count_c2fbr_tdd3;
        return "0" if not $count_c2fbr_tdd3;
        my $C2FBR_TDD3 = $C2FBR_TDD3[int(rand($#C2FBR_TDD3))];
        log_registry("Selected First Cdma2000FreqBandRelation : $C2FBR_TDD1");
        log_registry("Selected Second Cdma2000FreqBandRelation : $C2FBR_TDD2");
	log_registry("Selected Third Cdma2000FreqBandRelation : $C2FBR_TDD3");
        my %C2FBR_TDD_attrs = get_mo_attributes_CS(mo =>$C2FBR_TDD1,attributes => "adjacentFreqBand");
        log_registry("It seems selected Cdma2000FreqBandRelation does not point to ExternalCdma2000FreqBand mo ..") if not $C2FBR_TDD_attrs{adjacentFreqBand};
        test_failed($test_slogan) if not $C2FBR_TDD_attrs{adjacentFreqBand};
        return "0" if not $C2FBR_TDD_attrs{adjacentFreqBand};
        my $EC2FB_TDD = $C2FBR_TDD_attrs{adjacentFreqBand};
        $EC2FB_TDD =~ s/\n+//g;
        log_registry("Selected ExternalCdma2000FreqBand mo: $EC2FB_TDD");
        my ($icount_TDD,@EC2F_TDD) = get_CMS_mo("ExternalCdma2000Freq","$EC2FB_TDD");
        log_registry("It seems any of selected ExternalCdma2000FreqBand does not have any master ExternalCdma2000Freq Mo under it..") if not $icount_TDD;
        test_failed($test_slogan) if not $icount_TDD;
        return "0" if not $icount_TDD;
        my $EC2F_TDD = $EC2F_TDD[int(rand($#EC2F_TDD))];
        log_registry("Selected First ExternalCdma2000Freq mo: $EC2F_TDD");
        my ($C2FR1_TDD,$C2F_TDD1) = create_Cdma2000FreqRelation( C2FBR => $C2FBR_TDD1 , EC2F => $EC2F_TDD,base => "CSCLI" );
        log_registry("There is a problem in creation of Cdma2000FreqRelation ...") if not $C2FR1_TDD;
        test_failed($test_slogan) if not $C2FR1_TDD;
        return "0" if not $C2FR1_TDD;
        my ($C2FR2_TDD,$C2F_TDD2) = create_Cdma2000FreqRelation( C2FBR => $C2FBR_TDD2, EC2F => $EC2F_TDD,base => "CSCLI" );
        log_registry("There is a problem in creation of Cdma2000FreqRelation ...") if not $C2FR2_TDD;
        test_failed($test_slogan) if not $C2FR2_TDD;
        return "0" if not $C2FR2_TDD;
	my ($C2FR3_TDD,$C2F_TDD3) = create_Cdma2000FreqRelation( C2FBR => $C2FBR_TDD3, EC2F => $EC2F_TDD,base => "CSCLI" );
        log_registry("There is a problem in creation of Cdma2000FreqRelation ...") if not $C2FR3_TDD;
        test_failed($test_slogan) if not $C2FR3_TDD;
        return "0" if not $C2FR3_TDD;
############################ Deletion of relation under EUtranCellFDD #############################
        log_registry("Deleting Cdma2000FreqRelation under EUtranCellFDD on cs side ...");
        my $result = proxy_mo_delete_decision("0","CSCLI","$C2FR1","Relation");
        log_registry("Issue in deletion of Cdma2000FreqRelation under EUtranCellFDD") if not $result;
	test_failed("$test_slogan") if not $result;
        return "0" if not $result;
        my $review_cache_log = cache_file();
        my ($rev_id,$rev_log) = rev_find(file => $review_cache_log,mo => $EC2F);
        log_registry("It seems master ExternalCdma2000Frequency mo are not in Consistent state...") if ($rev_id != 1);
	test_failed("$test_slogan") if ($rev_id != 1);
	return "0" if ($rev_id != 1);
	my %C2F1_attrs = get_mo_attributes_CS(mo =>$C2F1,attributes => "reservedBy");
	log_registry("It seems $C2F1 is still reservedBy Cdma2000FreqRelation $C2FR1...") if ($C2F1_attrs{reservedBy} =~ /$C2FR1/);
	log_registry("====================================================================================");
	get_mo_attr($C2F1,"reservedBy");
	log_registry("====================================================================================");
	test_failed($test_slogan) if ($C2F1_attrs{reservedBy} =~ /$C2FR1/);
	return "0" if ($C2F1_attrs{reservedBy} =~ /$C2FR1/);
        log_registry("Deleting Cdma2000FreqRelation under EUtranCellFDD on node side ...");
        $result = proxy_mo_delete_decision("0","CLI","$C2FR2","Relation");
        log_registry("Issue in deletion of Cdma2000FreqRelation under EUtranCellFDD") if not $result;
	test_failed("$test_slogan") if not $result;
        return "0" if not $result;
        $review_cache_log = cache_file();
        ($rev_id,$rev_log) = rev_find(file => $review_cache_log,mo => $EC2F);
        log_registry("It seems master ExternalCdma2000Frequency mo are not in Consistent state...") if ($rev_id != 1);
	test_failed("$test_slogan") if ($rev_id != 1);
	return "0" if ($rev_id != 1);
	my %C2F2_attrs = get_mo_attributes_CS(mo =>$C2F2,attributes => "reservedBy");
	log_registry("It seems $C2F2 is still reservedBy Cdma2000FreqRelation $C2FR2 ...") if ($C2F2_attrs{reservedBy} =~ /$C2FR2/);
	log_registry("====================================================================================");
	get_mo_attr($C2F2,"reservedBy");
	log_registry("====================================================================================");
	test_failed("$test_slogan") if ($C2F2_attrs{reservedBy} =~ /$C2FR2/);
	return "0" if ($C2F2_attrs{reservedBy} =~ /$C2FR2/);
############################# Deletion of relation under EUtranCellTDD #############################
        log_registry("Deleting Cdma2000FreqRelation under EUtranCellTDD on cs side ...");
        $result = proxy_mo_delete_decision("0","CSCLI","$C2FR1_TDD","Relation");
        log_registry("Issue in deletion of Cdma2000FreqRelation under EUtranCellTDD") if not $result;
	test_failed($test_slogan) if not $result;
        return "0" if not $result;
        $review_cache_log = cache_file();
        ($rev_id,$rev_log) = rev_find(file => $review_cache_log,mo => $EC2F_TDD);
        log_registry("It seems master ExternalCdma2000Frequency mo are not in Consistent state...") if ($rev_id != 1);
	test_failed("$test_slogan") if ($rev_id != 1);
	return "0" if ($rev_id != 1);
	my %C2F_TDD1_attrs = get_mo_attributes_CS(mo =>$C2F_TDD1,attributes => "reservedBy");
	log_registry("It seems $C2F_TDD1 is still reservedBy Cdma2000FreqRelation $C2FR1_TDD...") if ($C2F_TDD1_attrs{reservedBy} =~ /$C2FR1_TDD/);
	log_registry("====================================================================================");
	get_mo_attr($C2F_TDD1,"reservedBy");
	log_registry("====================================================================================");
	test_failed($test_slogan) if ($C2F_TDD1_attrs{reservedBy} =~ /$C2FR1_TDD/);
	return "0" if ($C2F_TDD1_attrs{reservedBy} =~ /$C2FR1_TDD/);
        log_registry("Deleting Cdma2000FreqRelation under EUtranCellTDD on node side ...");
	$result = proxy_mo_delete_decision("0","CLI","$C2FR2_TDD","Relation");
        log_registry("Issue in deletion of Cdma2000FreqRelation under EUtranCellTDD") if not $result;
	test_failed($test_slogan) if not $result;
        return "0" if not $result;
        $review_cache_log = cache_file();
        ($rev_id,$rev_log) = rev_find(file => $review_cache_log,mo => $EC2F_TDD);
        log_registry("It seems master ExternalCdma2000Frequency mo are not in Consistent state...") if ($rev_id != 1);
	test_failed("$test_slogan") if ($rev_id != 1);
	return "0" if ($rev_id != 1);
	my %C2F_TDD2_attrs = get_mo_attributes_CS(mo =>$C2F_TDD2,attributes => "reservedBy");
	log_registry("It seems $C2F_TDD2 is still reservedBy Cdma2000FreqRelation $C2FR2_TDD...") if ($C2F_TDD2_attrs{reservedBy} =~ /$C2FR2_TDD/);
	log_registry("====================================================================================");
	get_mo_attr($C2F_TDD2,"reservedBy");
	log_registry("====================================================================================");
	test_failed($test_slogan) if ($C2F_TDD2_attrs{reservedBy} =~ /$C2FR2_TDD/);
	return "0" if ($C2F_TDD2_attrs{reservedBy} =~ /$C2FR2_TDD/);
        test_passed("$test_slogan");
  }
  else
  {
        log_registry("It seems no synched ERBS found of version vB.1.20 or later having EUtranCellFDD or EUtranCellTDD");
        test_failed($test_slogan);
  }
}

sub FUT119 #4.4.3.6.10 
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.6.10 ; Delete last Cdma2000FreqRelation MO under EUtranCellFDD and EUtranCellTDD in ERBS MIBs (valid/netsim);Normal;";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($count,@C2FR) = get_CMS_mo("Cdma2000FreqRelation",$mo_proxy_cms);
  if($count)
  {
	my $C2FR_TDD, $C2FR_FDD;
	foreach(@C2FR) {
		$C2FR_TDD = $_ if ($_ =~ /EUtranCellTDD\=/);
		$C2FR_FDD = $_ if ($_ =~ /EUtranCellFDD\=/);
		last if ($C2FR_TDD and $C2FR_FDD); }
	log_registry("It seems any of Cdma2000FreqRelation not found under EUtranCellTDD/EUtranCellFDD created by proxy.pl ") if not ($C2FR_TDD and $C2FR_FDD);
	test_failed("$test_slogan") if not ($C2FR_TDD and $C2FR_FDD);
	return "0" if not ($C2FR_TDD and $C2FR_FDD);
	my %C2FR_TDD_attrs = get_mo_attributes_CS(mo =>$C2FR_TDD,attributes => "cdma2000FreqRef");
	my %C2FR_FDD_attrs = get_mo_attributes_CS(mo =>$C2FR_FDD,attributes => "cdma2000FreqRef");
	my $flag =0;
	$flag = 1 if (!($C2FR_TDD_attrs{cdma2000FreqRef}) or !($C2FR_FDD_attrs{cdma2000FreqRef}));
	log_registry("It seems any of Cdma2000FreqRelation is not pointing to Cdma2000Freq mo...") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	my $C2F_TDD = $C2FR_TDD_attrs{cdma2000FreqRef};
	$C2F_TDD =~ s/\n+//g;
	my $C2F_FDD = $C2FR_FDD_attrs{cdma2000FreqRef};
	$C2F_FDD =~ s/\n+//g;
	my %C2F_TDD_attrs = get_mo_attributes_CS(mo =>$C2F_TDD,attributes => "reservedBy");
	my %C2F_FDD_attrs = get_mo_attributes_CS(mo =>$C2F_FDD,attributes => "reservedBy");
	my @arr1 = split(" ",$C2F_TDD_attrs{reservedBy});
	my @arr2 = split(" ",$C2F_FDD_attrs{reservedBy});
	$flag = 1 if (scalar(@arr1) != 1 or scalar(@arr2) != 1);
	log_registry("It seems any of selected Cdma2000FreqRelation is not a single/last relation for Cdma2000Freq MO..") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;		
        log_registry("Deleting Cdma2000FreqRelation under EUtranCellFDD on cs side ...");
        my $result = proxy_mo_delete_decision("0","CSCLI","$C2FR_FDD","Relation");
        log_registry("Issue in deletion of Cdma2000FreqRelation under EUtranCellFDD") if not $result;
	test_failed($test_slogan) if not $result;
        return "0" if not $result;
	my %C2F1_attrs = get_mo_attributes_CS(mo =>$C2F_FDD,attributes => "reservedBy");
	log_registry("It seems $C2F_FDD is still reservedBy Cdma2000FreqRelation $C2FR_FDD ...") if ($C2F1_attrs{reservedBy} =~ /$C2FR_FDD/);
	log_registry("====================================================================================");
	get_mo_attr($C2F_FDD,"reservedBy");
	log_registry("====================================================================================");
	test_failed($test_slogan) if ($C2F1_attrs{reservedBy} =~ /$C2FR_FDD/);
	return "0" if ($C2F1_attrs{reservedBy} =~ /$C2FR_FDD/);
        log_registry("Deleting Cdma2000FreqRelation under EUtranCellTDD on node side ...");
        $result = proxy_mo_delete_decision("0","CLI","$C2FR_TDD","Relation");
        log_registry("Issue in deletion of Cdma2000FreqRelation under EUtranCellFDD") if not $result;
	test_failed($test_slogan) if not $result;
        return "0" if not $result;
	my %C2F2_attrs = get_mo_attributes_CS(mo =>$C2F_TDD,attributes => "reservedBy");
	log_registry("It seems $C2F2 is still reservedBy Cdma2000FreqRelation $C2FR2 ...") if ($C2F2_attrs{reservedBy} =~ /$C2FR_TDD/);
	log_registry("====================================================================================");
	get_mo_attr($C2F_TDD,"reservedBy");
	log_registry("====================================================================================");
	test_failed("$test_slogan") if ($C2F2_attrs{reservedBy} =~ /$C2FR_TDD/);
	return "0" if ($C2F2_attrs{reservedBy} =~ /$C2FR_TDD/);
        test_passed("$test_slogan");
  }
  else
  {
        log_registry("It seems no pre-existing Cdma2000FreqRelation found created by proxy.pl ..");
        test_failed($test_slogan);
  }
}

sub FUT120  #4.4.1.10.13 and 4.4.3.6.11
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if($test_slogan =~ /4\.4\.1\.10\.13/);
  $tc_id = 2 if($test_slogan =~ /4\.4\.3\.6\.11/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.10.13; Create GeranCellRelation between EUtranCellFDD/TDD and ExternalGsmCell when GeraNetwork, GeranFreqGroup &GeranFrequency already exist on ERBS;; 1 " if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.3.6.11; Delete GeranCellRelation that exists between EUtranCellFDD/TDD and ExternalGsmCell;;1 " if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS1 = pick_a_erbs_using_cell(CELL => "EUtranCellFDD",VER => "NEW");
  my $ERBS2 = pick_a_erbs_using_cell(CELL => "EUtranCellTDD",VER => "NEW");
  if($ERBS1 and $ERBS2)
  {
	log_registry("Selected ERBS for TC are: \n $ERBS1 \n $ERBS2");
	my $EUCFDD = pick_a_mo($ERBS1,EUtranCellFDD);
	my $EUCTDD = pick_a_mo($ERBS2,EUtranCellTDD);
	log_registry("It seems EUtranCellFDD/EUtranCellTDD not found under corresponding ERBS..")if not($EUCFDD and $EUCTDD);
	test_failed($test_slogan) if not ($EUCFDD and $EUCTDD);
	return "0" if not ($EUCFDD and $EUCTDD);
	log_registry("Selected cells for TC are: \n $EUCFDD \n $EUCTDD ");
	my ($EGP_count,@EGP) = get_CMS_mo("ExternalGsmPlmn");
	log_registry("It seems no pre-existing ExternalGsmPlmn MO exist") if not $EGP_count;
	test_failed($test_slogan) if not $EGP_count;
	return "0" if not $EGP_count;
	my ($EGFG,$attr_EGFG) = get_fdn("ExternalGsmFreqGroup","create");
        my $result = mo_create_decision("0",$EGFG,$attr_EGFG);
	$result = master_for_proxy_handle("0",$EGFG,$attr_EGFG) if($result and $result eq "KO");
        log_registry("Problem in creation of master ExternalGsmFreqGroup MO ..") if not $result;
        test_failed($test_slogan) if not $result;
        return "0" if not $result;
	my $EGP = $EGP[int(rand($#EGP))];
	my %EGP_attrs = get_mo_attributes_CS(mo =>$EGP, attributes => "mnc mcc mncLength");	
	my ($EGC,$attr_EGC) = get_fdn("MasterExternalGsmCell","create");
	$attr_EGC = "$attr_EGC"." "."mnc $EGP_attrs{mnc}"." "."mcc $EGP_attrs{mcc}"." "."mncLength $EGP_attrs{mncLength}"." "."parentSystem $EGP";
	$attr_EGC =~ s/\n+//g;
	$result = mo_create_decision("0",$EGC,$attr_EGC);
	$result = master_for_proxy_handle("0",$EGC,$attr_EGC) if($result and $result eq "KO");
	log_registry("Problem in creation of master ExternalGsmCell MO ..") if not $result;
	test_failed($test_slogan) if not $result;
	return "0" if not $result;
	my ($GFGR1,$GeFG1) = create_GeranFreqGroupRelation(EUCXDD => $EUCFDD, EGFG => $EGFG);
	log_registry("It seems there is a problem in creation of GeranFreqGroupRelation ..") if not $GFGR1;
	test_failed($test_slogan) if not $GFGR1;
	return "0" if not $GFGR1;
        my ($GFGR2,$GeFG2) = create_GeranFreqGroupRelation(EUCXDD => $EUCTDD, EGFG => $EGFG);
        log_registry("It seems there is a problem in creation of GeranFreqGroupRelation ..") if not $GFGR2;
        test_failed($test_slogan) if not $GFGR2;
        return "0" if not $GFGR2;
	my ($GeF,$attr_GeF) = get_fdn("PGeranFrequency","create");
	my $GeF1 = base_fdn_modify("$GeFG1","$GeF");
	my $GeF2 = base_fdn_modify("$GeFG2","$GeF");
	my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$GeF1,$attr_GeF,"no wait");
	log_registry("Problem in creation of proxy GeranFrequency mo...") if not $status;
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
	($status,$rev_id) = proxy_mo_create_decision("CSCLI",$GeF2,$attr_GeF,"no wait");
        log_registry("Problem in creation of proxy GeranFrequency mo...") if not $status;
        test_failed($test_slogan) if not $status;
        return "0" if not $status;
        my ($GCR1,$EGeC1) = create_GeranCellRelation( GFGR => $GFGR1 , MEGC => $EGC,base => "CSCLI" );
        log_registry("There is a problem in creation of GeranCellRelation ...") if not $GCR1;
        test_failed($test_slogan) if not $GCR1;
	return "0" if not $GCR1;
        my ($GCR2,$EGeC2) = create_GeranCellRelation( GFGR => $GFGR2 , MEGC => $EGC,base => "CSCLI" );
        log_registry("There is a problem in creation of GeranCellRelation ...") if not $GCR2;
        test_failed($test_slogan) if not $GCR2;
        return "0" if not $GCR2;
        log_registry("====================================================================================");
        get_mo_attr($EGeC1,"reservedBy");
        log_registry("====================================================================================");
        log_registry("====================================================================================");
        get_mo_attr($EGeC2,"reservedBy");
        log_registry("====================================================================================");
        test_passed($test_slogan) if ($tc_id == 1);
	if($tc_id == 2)  {
		my $flag = 0;
		log_registry("Deleting GeranCellRelation :$GCR1 ");
                $flag = proxy_mo_delete_decision("0","CSCLI","$GCR1","Relation");
                log_registry("Issue in deletion of GeranCellRelation b/w EUtranCellFDD and ExternalGsmCell") if not $flag;
		test_failed($test_slogan) if not $flag;
                return "0" if not $flag;
                log_registry("Deleting GeranCellRelation :$GCR2 ");
                $flag = proxy_mo_delete_decision("0","CSCLI","$GCR2","Relation");
                log_registry("Issue in deletion of GeranCellRelation b/w EUtranCellTDD and ExternalGsmCell") if not $flag;
		test_failed($test_slogan) if not $flag;
                return "0" if not $flag;
                my $time = sleep_start_time();
                long_sleep_found($time);
                my $review_cache_log = cache_file();
                my ($rev_id_1,$rev_log_1) = rev_find(file => $review_cache_log,mo => $EGeC1);
                my ($rev_id_2,$rev_log_2) = rev_find(file => $review_cache_log,mo => $EGeC2);
                $flag = 2 if ( $rev_id_1 != 7 or $rev_id_2 != 7);
		$flag = 3 if ( $rev_id_1 == 0 or $rev_id_2 == 0);
                log_registry("It seems Proxy ExternalGeranCell are not in Redundant Proxy state...") if ($flag == 2);
		log_registry("It seems Proxy ExternalGeranCell are deleted that was not expected ..") if ($flag == 3);
                test_failed("$test_slogan") if ($flag == 2 or $flag == 3);
                test_passed("$test_slogan") if ($flag != 2 and $flag != 3); }
################################################# Clean Up ################################################################
        my $clean_issue,$mo;
	my %EGFG_attrs = get_mo_attributes_CS(mo =>$EGFG, attributes => "reservedBy");
        $mo = join(" ",$GCR1,$GCR2,$GFGR2,$GFGR1,$EGeC2,$EGeC1,$GeF2,$GeF1,$GeFG1,$GeFG2,$EGFG_attrs{reservedBy},$EGFG,$EGC) if($tc_id == 1);
	$mo = join(" ",$GFGR2,$GFGR1,$EGeC2,$EGeC1,$GeF2,$GeF1,$GeFG1,$GeFG2,$EGFG_attrs{reservedBy},$EGFG,$EGC)if($tc_id == 2);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
  }
  else
  {
                log_registry("It seems no synched ERBS found of version vB.1.20 or later having EUtranCellFDD or EUtranCellTDD under it");
                test_failed($test_slogan);
  }
}

sub FUT121  #4.5.1.8.10
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.5.1.8.10; Set Traffic Information attribute for proxy ExternalGeranCell (Traffic Information autofix on); Normal; 1  ";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(CELL => "EUtranCellFDD",VER => "NEW");
  if($ERBS)
  {
        log_registry("Selected ERBS for TC is: \n $ERBS");
        my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
        log_registry("It seems EUtranCellFDD not found under corresponding ERBS.. $ERBS")if not $EUCFDD;
        test_failed($test_slogan) if not $EUCFDD;
        return "0" if not $EUCFDD;
        log_registry("Selected cell for TC are: \n $EUCFDD ");
        my ($EGP_count,@EGP) = get_CMS_mo("ExternalGsmPlmn");
        log_registry("It seems no pre-existing ExternalGsmPlmn MO exist") if not $EGP_count;
        test_failed($test_slogan) if not $EGP_count;
        return "0" if not $EGP_count;
        my ($EGFG,$attr_EGFG) = get_fdn("ExternalGsmFreqGroup","create");
        my $result = mo_create_decision("0",$EGFG,$attr_EGFG);
	$result = master_for_proxy_handle("0",$EGFG,$attr_EGFG) if($result and $result eq "KO");
        log_registry("Problem in creation of master ExternalGsmFreqGroup MO ..") if not $result;
        test_failed($test_slogan) if not $result;
        return "0" if not $result;
        my $EGP = $EGP[int(rand($#EGP))];
        my %EGP_attrs = get_mo_attributes_CS(mo =>$EGP, attributes => "mnc mcc mncLength");
        my ($EGC,$attr_EGC) = get_fdn("MasterExternalGsmCell","create");
        $attr_EGC = "$attr_EGC"." "."mnc $EGP_attrs{mnc}"." "."mcc $EGP_attrs{mcc}"." "."mncLength $EGP_attrs{mncLength}"." "."parentSystem $EGP";
        $attr_EGC =~ s/\n+//g;
        $result = mo_create_decision("0",$EGC,$attr_EGC);
	$result = master_for_proxy_handle("0",$EGC,$attr_EGC) if($result and $result eq "KO");
        log_registry("Problem in creation of master ExternalGsmCell MO ..") if not $result;
        test_failed($test_slogan) if not $result;
        return "0" if not $result;
        my ($GFGR,$GeFG) = create_GeranFreqGroupRelation(EUCXDD => $EUCFDD, EGFG => $EGFG);
        log_registry("It seems there is a problem in creation of GeranFreqGroupRelation ..") if not $GFGR;
        test_failed($test_slogan) if not $GFGR;
        return "0" if not $GFGR;
        my ($GeF,$attr_GeF) = get_fdn("PGeranFrequency","create");
        $GeF = base_fdn_modify("$GeFG","$GeF");
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$GeF,$attr_GeF,"no wait");
        log_registry("Problem in creation of proxy GeranFrequency mo...") if not $status;
        test_failed($test_slogan) if not $status;
        return "0" if not $status;
        my ($GCR,$EGeC) = create_GeranCellRelation( GFGR => $GFGR , MEGC => $EGC,base => "CSCLI" );
        log_registry("There is a problem in creation of GeranCellRelation ...") if not $GCR;
        test_failed($test_slogan) if not $GCR;
        return "0" if not $GCR;
        log_registry("====================================================================================");
        get_mo_attr($EGeC);
        log_registry("====================================================================================");
	my $master_mo_bef = get_master_for_proxy($EGeC);
        log_registry("Master Mo for the Given Proxy $EGeC is: \n $master_mo_bef") if $master_mo_bef;
        log_registry("There is no Master Mo exist for the given proxy : $EGeC") if not $master_mo_bef;
	test_failed($test_slogan) if not $master_mo_bef;
	return "0" if not $master_mo_bef;
	my ($EGeC_fdn,$attrs_EGeC) = get_fdn("ExternalGeranCell","set");
	($status,$rev_id) = proxy_mo_set_decision("CSCLI",$EGeC,$attrs_EGeC);
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
	my $master_mo_aft = get_master_for_proxy($EGeC);
        log_registry("Master Mo for the Given Proxy $EGeC after changing attribute is: \n $master_mo_aft") if $master_mo_aft;
        log_registry("There is no Master Mo exist for the given proxy : $EGeC") if not $master_mo_aft;
	test_failed($test_slogan) if not $master_mo_aft;
	return "0" if not $master_mo_aft;
	my $flag = 0;
	$flag = 1 if ($master_mo_aft =~ /$master_mo_bef/);
        log_registry("It seems after setting attribute of proxy ExternalGeranCell master remains unaffected") if $flag;
	test_failed($test_slogan) if $flag;		
        test_passed($test_slogan) if not $flag;
################################################# Clean Up ################################################################
        my $clean_issue,$mo;
        my %EGFG_attrs = get_mo_attributes_CS(mo =>$EGFG, attributes => "reservedBy");
        $mo = join(" ",$GCR,$GFGR,$EGeC,$GeF,$GeFG,$EGFG_attrs{reservedBy},$EGFG,$EGC,$master_mo_aft);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
  }
  else
  {
                log_registry("It seems no synched ERBS found of version vB.1.20 having EUtranCellFDD under it");
                test_failed($test_slogan);
  }
}

sub FUT122  #4.5.1.8.11
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.5.1.8.11; SubNetwork ExternalGsmCell has RNC values set to undefined, MasterExternalGsmCellAttributeAutoFix ON (default);; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(CELL => "EUtranCellFDD",VER => "NEW");
  my $rnc = pick_a_ne("RncFunction");
  if($ERBS and $rnc)
  {
        log_registry("Selected ERBS for TC is: \n $ERBS");
        my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
        log_registry("It seems EUtranCellFDD not found under corresponding ERBS.. $ERBS")if not $EUCFDD;
        test_failed($test_slogan) if not $EUCFDD;
        return "0" if not $EUCFDD;
        log_registry("Selected cell for TC are: \n $EUCFDD ");
        my $EGN = pick_a_mo("$rnc","ExternalGsmNetwork");
        log_registry("It seems no pre-existing ExternalGsmNetwork exist under selected RNC $rnc ") if not $EGN;
        test_failed($test_slogan) if not $EGN;
        return "0" if not $EGN;
        my ($EGFG,$attr_EGFG) = get_fdn("ExternalGsmFreqGroup","create");
        my $result = mo_create_decision("0",$EGFG,$attr_EGFG);
	$result = master_for_proxy_handle("0",$EGFG,$attr_EGFG) if($result and $result eq "KO");
        log_registry("Problem in creation of master ExternalGsmFreqGroup MO ..") if not $result;
        test_failed($test_slogan) if not $result;
        return "0" if not $result;
        my ($GFGR,$GeFG) = create_GeranFreqGroupRelation(EUCXDD => $EUCFDD, EGFG => $EGFG);
        log_registry("It seems there is a problem in creation of GeranFreqGroupRelation ..") if not $GFGR;
        test_failed($test_slogan) if not $GFGR;
        return "0" if not $GFGR;
        my ($GeF,$attr_GeF) = get_fdn("PGeranFrequency","create");
        $GeF = base_fdn_modify("$GeFG","$GeF");
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$GeF,$attr_GeF,"no wait");
        log_registry("Problem in creation of proxy GeranFrequency mo...") if not $status;
        test_failed($test_slogan) if not $status;
        return "0" if not $status;
	my ($proxy_egc,$attr_egc) = get_fdn("ExternalGsmCell","create");
	my %EGN_attrs = get_mo_attributes_CS(mo =>$EGN, attributes => "mnc mcc mncLength");
	my $attr_EGeC = $attr_egc;
	$attr_EGeC =~ s/bcchFrequency.+//g;
        $attr_EGeC = "$attr_EGeC"." "."plmnIdentity mcc=$EGN_attrs{mcc}+mnc=$EGN_attrs{mnc}+mncLength=$EGN_attrs{mncLength}";
	my $EGeC = "$GeF".",ExternalGeranCell=$mo_proxy_cms";
	($status,$rev_id) = proxy_mo_create_decision("CLI",$EGeC,"$attr_EGeC","no wait");
	log_registry("Problem in creation of proxy ExternalGeranCell mo...") if not $status;
        test_failed($test_slogan) if not $status;
        return "0" if not $status;
        my ($GCR,$EGC) = create_GeranCellRelation( GFGR => $GFGR , EGeC => $EGeC,base => "CLI" );
        log_registry("There is a problem in creation of GeranCellRelation ...") if not $GCR;
        test_failed($test_slogan) if not $GCR;
        return "0" if not $GCR;
        log_registry("====================================================================================");
        get_mo_attr($EGeC);
        log_registry("====================================================================================");
	log_registry("====================================================================================");
        get_mo_attr($EGC);
        log_registry("====================================================================================");
	$proxy_egc = base_fdn_modify("$EGN","$proxy_egc");
	($status,$rev_id) = proxy_mo_create_decision("CSCLI",$proxy_egc,$attr_egc,"no wait");
	log_registry("Problem in creation of proxy ExternalGsmCell ...") if not $status;
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
	my $utran_cell = pick_a_cell($rnc);	
	log_registry("It seems no UtranCell found under selected RNC...") if not $utran_cell;
	test_failed("$test_slogan") if not $utran_cell;
	return "0" if not $utran_cell;
	my ($GR,$MEGC) = create_GsmRelation(base => "CLI", UC => $utran_cell, PEGC => $proxy_egc);
	log_registry("It seems problem in creation of GsmRelation ...") if not $GR;
	my $flag = 0; $flag = 1 if($MEGC and ($MEGC !~ /$EGC/)); $flag = 1 if ($GR and !($MEGC));
	log_registry("It seems GsmRelation does not use master ExternalGsmCell created during GeranCellRelation") if $flag;
	test_failed("$test_slogan") if ($flag or !($GR));
        log_registry("====================================================================================");
        get_mo_attr($EGC);
        log_registry("====================================================================================");
	test_passed($test_slogan) if (!($flag) and $GR);		
	########################################## Clean Up #######################################################
        my $clean_issue,$mo;
        my %EGFG_attrs = get_mo_attributes_CS(mo =>$EGFG, attributes => "reservedBy");
        $mo = join(" ",$GR,$GCR,$GFGR,$EGeC,$GeF,$GeFG,$EGFG_attrs{reservedBy},$EGFG,$EGC);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
  }
  else
  {
                log_registry("It seems either no synched ERBS of version vB.1.20 or later having EUtranCellFDD under it or no synched RNC found...");
                test_failed($test_slogan);
  }
}

sub FUT123  #4.5.1.8.13
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.5.1.8.13; Create a  GsmRelation when master ExternalGsmCell has RNC values set to undefined;; 1 ";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(CELL => "EUtranCellFDD",VER => "NEW");
  my $rnc = pick_a_ne("RncFunction");
  if($ERBS and $rnc)
  {
        log_registry("Selected ERBS for TC is: \n $ERBS");
        my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
        log_registry("It seems EUtranCellFDD not found under corresponding ERBS.. $ERBS")if not $EUCFDD;
        test_failed($test_slogan) if not $EUCFDD;
        return "0" if not $EUCFDD;
        log_registry("Selected cell for TC are: \n $EUCFDD ");
        my $EGN = pick_a_mo("$rnc","ExternalGsmNetwork");
        log_registry("It seems no pre-existing ExternalGsmNetwork exist under selected RNC") if not $EGN;
        test_failed($test_slogan) if not $EGN;
        return "0" if not $EGN;
        my ($EGFG,$attr_EGFG) = get_fdn("ExternalGsmFreqGroup","create");
        my $result = mo_create_decision("0",$EGFG,$attr_EGFG);
	$result = master_for_proxy_handle("0",$EGFG,$attr_EGFG) if($result and $result eq "KO");
        log_registry("Problem in creation of master ExternalGsmFreqGroup MO ..") if not $result;
        test_failed($test_slogan) if not $result;
        return "0" if not $result;
        my ($GFGR,$GeFG) = create_GeranFreqGroupRelation(EUCXDD => $EUCFDD, EGFG => $EGFG);
        log_registry("It seems there is a problem in creation of GeranFreqGroupRelation ..") if not $GFGR;
        test_failed($test_slogan) if not $GFGR;
        return "0" if not $GFGR;
        my ($GeF,$attr_GeF) = get_fdn("PGeranFrequency","create");
        $GeF = base_fdn_modify("$GeFG","$GeF");
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$GeF,$attr_GeF,"no wait");
        log_registry("Problem in creation of proxy GeranFrequency mo...") if not $status;
        test_failed($test_slogan) if not $status;
        return "0" if not $status;
        my ($proxy_egc,$attr_egc) = get_fdn("ExternalGsmCell","create");
        my %EGN_attrs = get_mo_attributes_CS(mo =>$EGN, attributes => "mnc mcc mncLength");
        my $attr_EGeC = $attr_egc;
        $attr_EGeC =~ s/bcchFrequency.+//g;
        $attr_EGeC = "$attr_EGeC"." "."plmnIdentity mcc=$EGN_attrs{mcc}+mnc=$EGN_attrs{mnc}+mncLength=$EGN_attrs{mncLength}";
        my $EGeC = "$GeF".",ExternalGeranCell=$mo_proxy_cms";
        ($status,$rev_id) = proxy_mo_create_decision("CLI",$EGeC,"$attr_EGeC","no wait");
        log_registry("Problem in creation of proxy ExternalGeranCell mo...") if not $status;
        test_failed($test_slogan) if not $status;
        return "0" if not $status;
        my ($GCR,$EGC) = create_GeranCellRelation( GFGR => $GFGR , EGeC => $EGeC,base => "CLI" );
        log_registry("There is a problem in creation of GeranCellRelation ...") if not $GCR;
        test_failed($test_slogan) if not $GCR;
        return "0" if not $GCR;
        log_registry("====================================================================================");
        get_mo_attr($EGeC);
        log_registry("====================================================================================");
        log_registry("====================================================================================");
        get_mo_attr($EGC);
        log_registry("====================================================================================");
        my $utran_cell = pick_a_cell($rnc);
        log_registry("It seems no UtranCell found under selected RNC...") if not $utran_cell;
        test_failed("$test_slogan") if not $utran_cell;
        return "0" if not $utran_cell;
	log_registry("Selected UtranCell: $utran_cell ");
        my ($GR,$PEGC) = create_GsmRelation(base => "CSCLI", UC => $utran_cell, MEGC => $EGC);
        log_registry("It seems problem in creation of GsmRelation ...") if not $GR;
	log_registry("It seems GsmRelation is get created with master ExternalGsmCell while master ExternalGsmCell has some undefined attributes, that was not expected..") if $GR;
	test_failed("$test_slogan") if $GR;
	return "0" if $GR;
	my $MEGC_attrs = "individualOffset 0 qRxLevMin 100 maxTxPowerUl 100";    
	$status = mo_set_decision("0",$EGC,$MEGC_attrs,"","NOWAIT");
	log_registry("Problem in setting attribute < $MEGC_attrs > of master ExternalGsmCell ..") if ($status ne "OK");
	test_failed("$test_slogan") if ($status ne "OK");
	return "0" if ($status ne "OK");
	($GR,$PEGC) = create_GsmRelation(base => "CSCLI", UC => $utran_cell, MEGC => $EGC);
	log_registry("It seems problem in creation of GsmRelation ...") if not $GR;
	test_failed("$test_slogan") if not $GR;
        log_registry("====================================================================================");
        get_mo_attr($EGC);
        log_registry("====================================================================================");
        test_passed($test_slogan) if $GR;
        ########################################## Clean Up #######################################################
        my $clean_issue,$mo;
        my %EGFG_attrs = get_mo_attributes_CS(mo =>$EGFG, attributes => "reservedBy");
        $mo = join(" ",$GR,$GCR,$GFGR,$EGeC,$GeF,$GeFG,$EGFG_attrs{reservedBy},$EGFG,$EGC);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
  }
  else
  {
                log_registry("It seems no synched ERBS of version vB.1.20 or later having EUtranCellFDD or no synched RNC found...");
                test_failed($test_slogan);
  }
}

sub FUT124 #4.4.2.2.20
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.2.20 ; Set Proxy MO - Set Proxy MO ExternalEUtranCellFDD/TDD Trafficial Information attributes, autofix on; Normal; 1";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");   
  my ($icount,@FDD) = get_CMS_mo("ExternalEUtranCellFDD" ,"MeContext");    # eeitjn : get one from a node not Subnetwork
  my ($jcount,@TDD) = get_CMS_mo("ExternalEUtranCellTDD" ,"MeContext");    # eeitjn : get one from a node not Subnetwork
  
  log_registry("$icount : $jcount ");

  if($icount and $jcount)
  {
	my $EEUCFDD,$EEUCTDD;
	my $flag = 0;
	foreach(@FDD)  {
		my $state = get_proxy("$_");
		$EEUCFDD = $_ if ($state == 1);
		last if $EEUCFDD;  }
        foreach(@TDD)  {
                my $state = get_proxy("$_");
                $EEUCTDD = $_ if ($state == 1);
                last if $EEUCTDD;  }
	$flag = 1 if not ($EEUCFDD and $EEUCTDD);
	log_registry("It seems no ExternalEUtranCellFDD/ExternalEUtranCellTDD found that is in consistent state..") if $flag;
	test_failed($test_slogan) if $flag;
	return "0" if $flag;
	log_registry("Selected ExternalEUtranCellFDD/ExternalEUtranCellTDD are: \n $EEUCFDD \n $EEUCTDD");
	my $EUCFDD = get_master_for_proxy($EEUCFDD);
	my $EUCTDD = get_master_for_proxy($EEUCTDD);
	$flag = 1 if not ($EUCFDD and $EUCTDD);
	log_registry("Its strange proxy ExternalEUtranCellFDD/ExternalEUtranCellTDD is consistent while have no master for it..") if $flag;
	test_failed($test_slogan) if $flag;
	return "0" if $flag;
        my ($FDD,$fdd_attrs) = get_fdn("ExternalEUtranCellFDD","set");
        my ($TDD,$tdd_attrs) = get_fdn("ExternalEUtranCellTDD","set");
        my ($status_EEUCFDD,$rev_EEUCFDD) = proxy_mo_set_decision("CSCLI",$EEUCFDD,$fdd_attrs,"NW");
        my ($status_EEUCTDD,$rev_EEUCTDD) = proxy_mo_set_decision("CSCLI",$EEUCTDD,$tdd_attrs,"NW");
        
        log_registry("eeitjn: The Autofix is very quick now, check function for attribute difference is too slow");
	log_registry("eeitjn: Check in the logs below for AUTOFIX is ON fixing the inconsistency");
	
	#$flag = 1 if not ($status_EEUCFDD and $status_EEUCTDD);
	#log_registry("It seems there is a problem in setting attributes of ExternalEUtranCellFDD/ExternalEUtranCellTDD MO") if $flag;
	#log_registry("There may be a chance master EUtrnacellFDD/EUtrnacellTDD mo attributes are getting effected because of change in proxy ExternalEUtranCellFDD/ExternalEUtranCellTDD mo.") if $flag;
	#test_failed($test_slogan) if $flag;
	#return "0" if $flag;
	
	#my $nudge = forceCC($EEUCFDD);
	#long_sleep_found($nudge) if $nudge;
	
	log_registry("Check proxy ExternalEUtranCellFDD/ExternalEUtranCellTDD attributes values after consistency Check...");
	log_registry("===================================================================================");
	get_mo_attr("$EEUCFDD","$fdd_attrs");
	log_registry("===================================================================================");
	get_mo_attr("$EEUCTDD","$tdd_attrs");
	log_registry("===================================================================================");
	my $state_fdd = attr_value_comp($EEUCFDD,$fdd_attrs);
	my $state_tdd = attr_value_comp($EEUCTDD,$tdd_attrs);
	$flag = 1 if ($state_fdd or $state_tdd);
	log_registry("It seems attributes of proxy ExternalEUtranCellFDD/ExternalEUtranCellTDD are modified permanently ") if $flag; 
	test_failed($test_slogan) if $flag;
	return "0" if $flag;
	log_registry("Attributes of proxy ExternalEUtranCellFDD/ExternalEUtranCellTDD are rollback to previous values..");
	test_passed($test_slogan);
  }
  else
  {
  	log_registry("It seems no ExternalEUtranCellFDD/ExternalEUtranCellTDD found  ...");
	test_failed("$test_slogan");
  }
}

sub FUT125 #4.4.3.2.20 and 4.4.3.2.22
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.3\.2\.20/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.3\.2\.22/);
  $tc_info = "WRANCM_CMSSnad_4.4.3.2.20 ; Delete Proxy MO - Delete Proxy MO ExternalEUtranCellFDD/TDD from an application" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.3.2.22 ; Delete Proxy MO - Delete Proxy MO ExternalEUtranCellFDD/TDD through the EM (netsim)" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS_FDD = pick_a_erbs_using_cell(CELL => "ExternalEUtranCellFDD");
  my $ERBS_TDD = pick_a_erbs_using_cell(CELL => "ExternalEUtranCellTDD");
  if($ERBS_FDD and $ERBS_TDD)
  {
        my $flag = 0;
        my ($count,@EENBF_FDD) = get_CMS_mo("ExternalENodeBFunction",$ERBS_FDD);
        my ($icount,@EENBF_TDD) = get_CMS_mo("ExternalENodeBFunction",$ERBS_TDD);
        $flag = 1 if (!($count) or !($icount));
        log_registry("It seems either ExternalENodeBFunction MO not found for any of ERBS..") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        my ($EUF_count,@EUF_FDD) = get_CMS_mo("EUtranFrequency",$ERBS_FDD);
        my ($count_EUF,@EUF_TDD) = get_CMS_mo("EUtranFrequency",$ERBS_TDD);
        $flag = 1 if (!($EUF_count) or !($count_EUF));
        log_registry("It seems no EUtranFrequency MO found under any of ERBS ...") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        my $EENBF_FDD = $EENBF_FDD[int(rand($#EENBF_FDD))];
        my $EENBF_TDD = $EENBF_TDD[int(rand($#EENBF_TDD))];
        my $EUF_FDD = $EUF_FDD[0];
        my $EUF_TDD = $EUF_TDD[0];
        my ($EEUCFDD,$attr_EEUCFDD) = get_fdn("ExternalEUtranCellFDD","create");
        my ($EEUCTDD,$attr_EEUCTDD) = get_fdn("ExternalEUtranCellTDD","create");
        $EEUCFDD = base_fdn_modify("$EENBF_FDD","$EEUCFDD");
        $EEUCTDD = base_fdn_modify("$EENBF_TDD","$EEUCTDD");
        $attr_EEUCFDD = "$attr_EEUCFDD"." "."$EUF_FDD";
        $attr_EEUCTDD = "$attr_EEUCTDD"." "."$EUF_TDD";
        my $status_EEUCFDD,$status_EEUCTDD,$rev_EEUCFDD,$rev_EEUCTDD;
        ($status_EEUCFDD,$rev_EEUCFDD) = proxy_mo_create_decision("CSCLI",$EEUCFDD,$attr_EEUCFDD,"no wait") if ($tc_id == 1);
        ($status_EEUCTDD,$rev_EEUCTDD) = proxy_mo_create_decision("CSCLI",$EEUCTDD,$attr_EEUCTDD,"no wait") if ($tc_id == 1);
	($status_EEUCFDD,$rev_EEUCFDD) = proxy_mo_create_decision("CLI",$EEUCFDD,$attr_EEUCFDD,"no wait") if ($tc_id == 2);
        ($status_EEUCTDD,$rev_EEUCTDD) = proxy_mo_create_decision("CLI",$EEUCTDD,$attr_EEUCTDD,"no wait") if ($tc_id == 2);
        $flag = 1 if (!($status_EEUCFDD) or !($status_EEUCTDD));
        log_registry("There is a problem in creation of ExternalEUtranCellTDD/ExternalEUtranCellFDD MO ...") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        my $nudge = forceCC($EEUCTDD);
        long_sleep_found($nudge) if $nudge;
        my $review_cache_log = cache_file();
        my ($rev_FDD,$rev_log_FDD) = rev_find(file => $review_cache_log,mo => $EEUCFDD);
        my ($rev_TDD,$rev_log_TDD) = rev_find(file => $review_cache_log,mo => $EEUCTDD);
        $flag = 1 if ($rev_FDD != 7 or $rev_TDD != 7);
        log_registry("It seems either of ExternalEUtranCellTDD/ExternalEUtranCellFDD MO is not Redundant ...") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        log_registry("It seems ExternalEUtranCellTDD/ExternalEUtranCellFDD MOs are Redundant ...");
	my $result_fdd,$result_tdd;
	$result_fdd = proxy_mo_delete_decision("0","CSCLI",$EEUCFDD) if ($tc_id == 1);
	$result_tdd = proxy_mo_delete_decision("0","CSCLI",$EEUCTDD) if ($tc_id == 1);
	$result_fdd = proxy_mo_delete_decision("0","CLI",$EEUCFDD) if ($tc_id == 2);
	$result_tdd = proxy_mo_delete_decision("0","CLI",$EEUCTDD) if ($tc_id == 2);
	$flag = 1 if not ($result_fdd and $result_tdd);
	log_registry("It seems problem in deletion of ExternalEUtranCellTDD/ExternalEUtranCellFDD MO..") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	test_passed("$test_slogan");
  }
  else
  {
        log_registry("It seems no Synched ERBS found that have ExternalEUtranCellFDD/ExternalEUtranCellTDD under it...");
        test_failed("$test_slogan");
  }
}

sub FUT126 #4.4.3.2.24
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.24 ; Delete Proxy MO - Delete Proxy MO ExternalEUtranCellFDD/TDD fails due to reservedBy set";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($icount,@FDD) = get_CMS_mo("ExternalEUtranCellFDD");
  my ($jcount,@TDD) = get_CMS_mo("ExternalEUtranCellTDD");
  if($icount and $jcount)
  {
        my $EEUCFDD,$EEUCTDD;
        my $flag = 0;
        foreach(@FDD)  {
                my %EEUCFDD = get_mo_attributes_CS(mo =>$_ ,attributes => "reservedBy");
                $EEUCFDD = $_ if ($EEUCFDD{reservedBy} and $EEUCFDD{reservedBy} =~ /EUtranCellRelation\=/);
                last if $EEUCFDD;  }
        foreach(@TDD)  {
                my %EEUCTDD = get_mo_attributes_CS(mo =>$_ ,attributes => "reservedBy");
                $EEUCTDD = $_ if ($EEUCTDD{reservedBy} and $EEUCTDD{reservedBy} =~ /EUtranCellRelation\=/);
                last if $EEUCTDD;  }
        $flag = 1 if not ($EEUCFDD and $EEUCTDD);
        log_registry("It seems no ExternalEUtranCellFDD/ExternalEUtranCellTDD found that have reservedBy attribute set..") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
        log_registry("Selected ExternalEUtranCellFDD/ExternalEUtranCellTDD are: \n $EEUCFDD \n $EEUCTDD");
	log_registry("===================================================================================");
	get_mo_attr($EEUCFDD,"reservedBy");
	log_registry("===================================================================================");
	log_registry("===================================================================================");
	get_mo_attr($EEUCTDD,"reservedBy");
	log_registry("===================================================================================");
	my $result_fdd,$result_tdd;
        $result_fdd = proxy_mo_delete_decision("0","CSCLI",$EEUCFDD);
        $result_tdd = proxy_mo_delete_decision("0","CSCLI",$EEUCTDD);
        $flag = 1 if ($result_fdd or $result_tdd);
	log_registry("It seems ExternalEUtranCellFDD/ExternalEUtranCellTDD MO are get deleted while their reservedBy attribute was set to a EUtranCellRelation ..") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
	log_registry("It seems ExternalEUtranCellTDD/ExternalEUtranCellFDD MO are not getting deleted becuase of reservedBy attribute set to a EUtranCellRelation..");
        test_passed($test_slogan);
  }
  else
  {
        log_registry("It seems no ExternalEUtranCellFDD/ExternalEUtranCellTDD found  ...");
        test_failed("$test_slogan");
  }
}


sub FUT127 #4.4.2.2.16
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.2.16 ; Set Proxy MO - Set Proxy MO ExternalEUtranCellFDD/TDD attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS_FDD = pick_a_erbs_using_cell(CELL => "ExternalEUtranCellFDD");
  my $ERBS_TDD = pick_a_erbs_using_cell(CELL => "ExternalEUtranCellTDD");
  if($ERBS_FDD and $ERBS_TDD)
  {
        my $flag = 0;
        my ($count,@EENBF_FDD) = get_CMS_mo("ExternalENodeBFunction",$ERBS_FDD);
        my ($icount,@EENBF_TDD) = get_CMS_mo("ExternalENodeBFunction",$ERBS_TDD);
        $flag = 1 if (!($count) or !($icount));
        log_registry("It seems either ExternalENodeBFunction MO not found for any of ERBS..") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        my ($EUF_count,@EUF_FDD) = get_CMS_mo("EUtranFrequency",$ERBS_FDD);
        my ($count_EUF,@EUF_TDD) = get_CMS_mo("EUtranFrequency",$ERBS_TDD);
        $flag = 1 if (!($EUF_count) or !($count_EUF));
        log_registry("It seems no EUtranFrequency MO found under any of ERBS ...") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        my $EENBF_FDD = $EENBF_FDD[int(rand($#EENBF_FDD))];
        my $EENBF_TDD = $EENBF_TDD[int(rand($#EENBF_TDD))];
        my $EUF_FDD = $EUF_FDD[0];
        my $EUF_TDD = $EUF_TDD[0];
        my ($EEUCFDD,$attr_EEUCFDD) = get_fdn("ExternalEUtranCellFDD","create");
        my ($EEUCTDD,$attr_EEUCTDD) = get_fdn("ExternalEUtranCellTDD","create");
        $EEUCFDD = base_fdn_modify("$EENBF_FDD","$EEUCFDD");
        $EEUCTDD = base_fdn_modify("$EENBF_TDD","$EEUCTDD");
        $attr_EEUCFDD = "$attr_EEUCFDD"." "."$EUF_FDD";
        $attr_EEUCTDD = "$attr_EEUCTDD"." "."$EUF_TDD";
        my $status_EEUCFDD,$status_EEUCTDD,$rev_EEUCFDD,$rev_EEUCTDD;
        ($status_EEUCFDD,$rev_EEUCFDD) = proxy_mo_create_decision("CSCLI",$EEUCFDD,$attr_EEUCFDD,"no wait");
        ($status_EEUCTDD,$rev_EEUCTDD) = proxy_mo_create_decision("CSCLI",$EEUCTDD,$attr_EEUCTDD,"no wait");
        $flag = 1 if (!($status_EEUCFDD) or !($status_EEUCTDD));
        log_registry("There is a problem in creation of ExternalEUtranCellTDD/ExternalEUtranCellFDD MO ...") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        my $nudge = forceCC($EEUCTDD);
        long_sleep_found($nudge) if $nudge;
        my $review_cache_log = cache_file();
        my ($rev_FDD,$rev_log_FDD) = rev_find(file => $review_cache_log,mo => $EEUCFDD);
        my ($rev_TDD,$rev_log_TDD) = rev_find(file => $review_cache_log,mo => $EEUCTDD);
        $flag = 1 if ($rev_FDD != 7 or $rev_TDD != 7);
        log_registry("It seems either of ExternalEUtranCellTDD/ExternalEUtranCellFDD MO is not Redundant ...") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        log_registry("It seems ExternalEUtranCellTDD/ExternalEUtranCellFDD MOs are Redundant ...");
        my $result_fdd,$result_tdd;
	my $attrs = "userLabel"." "."$mo_proxy_cms"."2";
	$result_fdd = proxy_mo_set_decision("CSCLI",$EEUCFDD,$attrs);
	$result_tdd = proxy_mo_set_decision("CLI",$EEUCTDD,$attrs);
	$flag = 1 if not ($result_fdd and $result_tdd);
        log_registry("It seems problem in setting attributes of ExternalEUtranCellTDD/ExternalEUtranCellFDD MO..") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        test_passed("$test_slogan");
	########################### Clean up ##########################
	my $clean_issue,$mo;
	$mo = join(" ",$EEUCTDD,$EEUCFDD);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
  }
  else
  {
        log_registry("It seems no Synched ERBS found that have ExternalEUtranCellFDD/ExternalEUtranCellTDD under it...");
        test_failed("$test_slogan");
  }
}

sub FUT128 #4.4.1.2.58, 4.4.1.2.61 and 4.4.1.2.62
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.1\.2\.58/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.1\.2\.61/);
  $tc_id = 3 if ($test_slogan =~ /4\.4\.1\.2\.62/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.58 ; Create EUtranFrequency when no master EUtranFrequency initially exists" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.61 ; Create EUtranFrequency when no master EUtranFrequency initially exists through the EM (netsim) " if ($tc_id == 2);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.62 ; Create - Create Proxy EUtranFrequency when no master EUtranFrequency exists through the EM (netsim) , then is autocreated" if ($tc_id == 3);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(CELL => "EUtranCellFDD");
  my $pico = "pERBS";
  my $loop = 0;
  while (index($ERBS, $pico)) {
    	$ERBS = pick_a_erbs_using_cell(CELL => "EUtranCellFDD");
	$loop = $loop + 1;
	last if($loop > 10);
  }
  if($ERBS)
  {
        my $flag = 0;
	log_registry("Selected ERBS : $ERBS");    # Picked a ERBS now going to create a cell
        my ($EUCFDD,$attr_EUCFDD) = get_fdn("EUtranCellFDD","create");
        log_registry("reade eeee i$EUCFDD,$attr_EUCFDD   ");

        my $EUCFDD_fdn = "$ERBS".","."EUtranCellFDD=$mo_proxy_cms";
        my ($count,@SEF) = select_mo_cs( MO => "SectorCarrier", KEY => "$ERBS");
        $attr_EUCFDD = $attr_EUCFDD." userLabel"." "."$mo_proxy_cms"." "."sectorCarrierRef"." "."$SEF[0]";

        my $result = create_mo_CLI(mo => $EUCFDD_fdn, base => CLI, attributes => $attr_EUCFDD);
        log_registry("Problem in creation of EUtranCellFDD MO.....") if ($result ne OK);
        test_failed($test_slogan) if ($result ne OK);
        return "0" if ($result ne OK);
        log_registry("EUtranCellFDD MO get created on node side...");


        # my $EUCFDD = pick_a_mo("$ERBS","EUtranCellFDD");
	# log_registry("It seems no EUtranCellFDD mo found under selected ERBS...") if not $EUCFDD;
	# test_failed("$test_slogan") if not $EUCFDD;
	# return "0" if not $EUCFDD;

	my $EUNW = pick_a_mo("$ERBS","EUtraNetwork");
	log_registry("It seems No EUtraNetwork exists under selected ERBS...") if not $EUNW;
	test_failed("$test_slogan") if not $EUNW;
	return "0" if not $EUNW;
	my ($PEUF,$proxy_attrs) = get_fdn("EUtranFrequency","create");
	my ($MEUF,$master_attrs) = get_fdn("MasterEUtranFrequency","create");
	$PEUF = base_fdn_modify("$EUNW","$PEUF");
	my $status,$rev_id;
	($status,$rev_id) = proxy_mo_create_decision("CSCLI",$PEUF,$proxy_attrs,"no wait") if ($tc_id == 1);
	($status,$rev_id) = proxy_mo_create_decision("CLI",$PEUF,$proxy_attrs,"no wait") if ($tc_id == 2 or $tc_id == 3);
	log_registry("It seems there is problem in creation of proxy EUtranFrequency mo ..") if not $status;
	test_failed("$test_slogan") if not $status;
	return "0" if not $status;
	if($tc_id != 3) {
			$status = mo_create_decision("0",$MEUF,$master_attrs);
			$status = master_for_proxy_handle("0",$MEUF,$master_attrs) if($status and $status eq "KO");
			log_registry("Problem in creation of master EUtranFrequency ..") if not $status;
			test_failed($test_slogan) if not $status;
			return "0" if not $status;
			my $review_cache_log = cache_file();
			my ($rev_d,$rev_log) = rev_find(file => $review_cache_log,mo => $PEUF);
			log_registry("==========================================================================");
			get_mo_attr($PEUF);
			log_registry("==========================================================================");
			$flag = 1 if (!($rev_d) or $rev_d != 7);
			log_registry("It seems proxy EUtranFrequency is not in Redundant State ..") if $flag;
			test_failed($test_slogan) if $flag;
			return "0" if $flag;   }
	my ($EUFR,$MEUF_R) = create_EUtranFreqRelation(base => CLI, PEUF => $PEUF,EUCXDD => $EUCFDD_fdn);
	log_registry("It seems there is a problem in creation of EUtranFreqRelation mo..") if not $EUFR;
	test_failed("$test_slogan") if not $EUFR;
	return "0" if not $EUFR;
	$flag = 1 if ($tc_id != 3 and ($MEUF_R !~ /$MEUF/));
	log_registry("It seems EUtranFreqRelaton does not have same master EUtranFrequency as we have created ") if $flag;
	test_failed("$test_slogan") if $flag;
        test_passed("$test_slogan") if not $flag;
	########################### Clean up ##########################
	my $clean_issue,$mo;
	$mo = join(" ",$EUFR,$PEUF,$MEUF,$MEUF_R,$EUCFDD_fdn);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                  log_registry("Clean up: Deleting MO $_ ");
                  $clean_issue = delete_mo_CS( mo => $_);
                  log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
  }
  else
  {
        log_registry("It seems no Synched ERBS found that have EUtranCellFDD under it...");
        test_failed("$test_slogan");
  }
}


sub FUT129 #4.4.3.2.26 and 4.4.3.2.28
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.3\.2\.26/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.3\.2\.28/);
  $tc_info = "WRANCM_CMSSnad_4.4.3.2.26 ; Delete - Delete unreserved EUtranFrequency with no corresponding Master EUtranFrequency from an application" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.3.2.28 ; Delete - Delete EUtranFrequency through the EM (netsim)" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne("ENodeBFunction");
  if($ERBS)
  {
	my $EUNW = pick_a_mo("$ERBS","EUtraNetwork");
	log_registry("It seems No EUtraNetwork exists under selected ERBS...") if not $EUNW;
	test_failed("$test_slogan") if not $EUNW;
	return "0" if not $EUNW;
	my ($PEUF,$proxy_attrs) = get_fdn("EUtranFrequency","create");
	$PEUF = base_fdn_modify("$EUNW","$PEUF");
	my $status,$rev_id;
	($status,$rev_id) = proxy_mo_create_decision("CSCLI",$PEUF,$proxy_attrs) if ($tc_id == 1);
	($status,$rev_id) = proxy_mo_create_decision("CLI",$PEUF,$proxy_attrs) if ($tc_id == 2);
	log_registry("It seems there is problem in creation of proxy EUtranFrequency mo or its not in Redundant State ..") if (!($status) or ($rev_id != 7));
	test_failed("$test_slogan") if (!($status) or ($rev_id != 7));
	return "0" if (!($status) or ($rev_id != 7));
	proxy_mo_delete_decision($test_slogan,"CSCLI",$PEUF) if ($tc_id == 1);
	proxy_mo_delete_decision($test_slogan,"CLI",$PEUF) if ($tc_id == 2);
  }
  else
  {
        log_registry("It seems no Synched ERBS found ...");
        test_failed("$test_slogan");
  }
}

sub FUT130 #4.4.3.2.29
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.3.2.29 ; Delete - Delete EUtranFrequency fails due to reservedBy set";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my ($count,@EUF) = select_mo_cs( MO => "EUtranFrequency", KEY => "MeContext");
  if($count)
  {
        my $EUF;
        my $flag = 0;
        foreach(@EUF)  {
                my %EUF = get_mo_attributes_CS(mo =>$_ ,attributes => "reservedBy");
                $EUF = $_ if ($EUF{reservedBy} and $EUF{reservedBy} =~ /EUtranFreqRelation\=/);
                last if $EUF;  }
        $flag = 1 if not $EUF;
        log_registry("It seems no EUtranFrequency found that have reservedBy attribute set..") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
        log_registry("Selected EUtranFrequency mo is: \n $EUF");
        log_registry("===================================================================================");
        get_mo_attr($EUF,"reservedBy");
        log_registry("===================================================================================");
        my $result = proxy_mo_delete_decision("0","CSCLI",$EUF);
        $flag = 1 if $result;
        log_registry("It seems EUtranFrequency MO are get deleted while their reservedBy attribute was set to a EUtranFreqRelation ..") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
        log_registry("It seems EUtranFrequency MO are not getting deleted becuase of reservedBy attribute set to a EUtranFreqRelation..");
        test_passed($test_slogan);
  }
  else
  {
        log_registry("It seems no proxy EUtranFrequency MO found  ...");
        test_failed("$test_slogan");
  }
}

sub FUT131 #4.4.3.2.27
{
  my $test_slogan = $_[0];
  my $tc_info;
  $tc_info = "WRANCM_CMSSnad_4.4.3.2.27 ; Delete - Delete unreserved EUtranFrequency with corresponding Master ExternalEutranFrequency from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(CELL => "EUtranCellFDD");
  if($ERBS)
  {
        my $flag = 0;
        log_registry("Selected ERBS : $ERBS");
        my $EUCFDD = pick_a_mo("$ERBS","EUtranCellFDD");
        log_registry("It seems no EUtranCellFDD mo found under selected ERBS...") if not $EUCFDD;
        test_failed("$test_slogan") if not $EUCFDD;
        return "0" if not $EUCFDD;
        my $EUNW = pick_a_mo("$ERBS","EUtraNetwork");
        log_registry("It seems No EUtraNetwork exists under selected ERBS...") if not $EUNW;
        test_failed("$test_slogan") if not $EUNW;
        return "0" if not $EUNW;
        my ($PEUF,$proxy_attrs) = get_fdn("EUtranFrequency","create");
        my ($MEUF,$master_attrs) = get_fdn("MasterEUtranFrequency","create");
        $PEUF = base_fdn_modify("$EUNW","$PEUF");
        my $status,$rev_id;
	$status = mo_create_decision("0",$MEUF,$master_attrs);
	$status = master_for_proxy_handle("0",$MEUF,$master_attrs) if($status and $status eq "KO");
        log_registry("Problem in creation of master EUtranFrequency ..") if not $status;
        test_failed($test_slogan) if not $status;
        return "0" if not $status;
        ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$PEUF,$proxy_attrs,"no wait");
        log_registry("It seems there is problem in creation of proxy EUtranFrequency mo or proxy is not in Redundant State ..") if (!($status) or ($rev_id != 7));
        test_failed("$test_slogan") if (!($status) or ($rev_id != 7));
        return "0" if (!($status) or ($rev_id != 7));
        my ($EUFR,$PEUF_R) = create_EUtranFreqRelation(base => CSCLI, MEUF => $MEUF, EUCXDD => $EUCFDD);
        log_registry("It seems there is a problem in creation of EUtranFreqRelation mo..") if not $EUFR;
        test_failed("$test_slogan") if not $EUFR;
        return "0" if not $EUFR;
        my $result = proxy_mo_delete_decision("0","CSCLI",$EUFR,"Relation");
	log_registry("It seems there is a problem in deletion of EUtranFreqRelation mo...") if not $result;
	test_failed("$test_slogan") if not $result;
	return "0" if not $result;
	$status = get_proxy($PEUF);
	log_registry("It seems proxy EUtranFrequency mo is deleted automatically with relation..") if not $status;
	test_failed("$test_slogan") if not $status;
	return "0" if not $status;
	log_registry("============================================");
	get_proxy($PEUF);
	log_registry("============================================");
	my $master = get_master_for_proxy($PEUF);
	log_registry("getMasterForProxy => $master") if $master;
	log_registry("It seems after deletion of EUtranFreqRelation proxy EUtranFrequency mo get inconsistent/redundant ..") if not $master;
	test_failed("$test_slogan") if not $master;
	return "0" if not $master;
	$result = proxy_mo_delete_decision("0","CSCLI",$PEUF);
	log_registry("It seems problem in deletion of proxy EUtranFrequency mo ..") if not $result;
	test_failed("$test_slogan") if not $result;
	test_passed("$test_slogan") if $result;
        ########################### Clean up ##########################
        my $clean_issue;
	log_registry("Clean up: Deleting MO $MEUF ");
        $clean_issue = delete_mo_CS( mo => $MEUF);
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
  }
  else
  {
        log_registry("It seems no Synched ERBS found that have EUtranCellFDD under it...");
        test_failed("$test_slogan");
  }
}


sub FUT132 #4.4.3.2.21 & 4.4.3.2.23
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if($test_slogan =~ /4\.4\.3\.2\.21/);
  $tc_id = 2 if($test_slogan =~ /4\.4\.3\.2\.23/);
  $tc_info = "WRANCM_CMSSnad_4.4.3.2.21 ; Delete Proxy MO - Delete Proxy MO ExternalENodeBFunction from an application;" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.3.2.23 ; Delete Proxy MO - Delete Proxy MO ExternalENodeBFunction through the EM (netsim)" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne("ENodeBFunction");
  if($ERBS)
  {
        log_registry("Selected ERBS : $ERBS");
        my $EUNW = pick_a_mo("$ERBS","EUtraNetwork");
        log_registry("It seems No EUtraNetwork exists under selected ERBS...") if not $EUNW;
        test_failed("$test_slogan") if not $EUNW;
        return "0" if not $EUNW;
	my $oth_attrs = get_attrs_ExternalENodeBFunction($ERBS);
        my ($EENBF,$proxy_attrs) = get_fdn("ExternalENodeBFunction","create");
        $EENBF = base_fdn_modify("$EUNW","$EENBF");
	$proxy_attrs = "$proxy_attrs"." "."$oth_attrs";
        my $status,$rev_id;
        ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$EENBF,$proxy_attrs) if ($tc_id == 1);
 	($status,$rev_id) = proxy_mo_create_decision("CLI",$EENBF,$proxy_attrs) if ($tc_id == 2);
	log_registry("Problem in creation of proxy ExternalENodeBFunction mo...") if not $status;
	test_failed("$test_slogan") if not $status;
	return "0" if not $status;
        $status = proxy_mo_delete_decision("0","CSCLI",$EENBF) if ($tc_id == 1);
	$status = proxy_mo_delete_decision("0","CLI",$EENBF) if ($tc_id == 2);
        log_registry("It seems there is a problem in deletion of ExternalENodeBFunction mo...") if not $status;
        test_failed("$test_slogan") if not $status;
	test_passed("$test_slogan") if $status;
       ########################### Clean up ##########################
        my $clean_issue;
        log_registry("Clean up: Deleting MO $EENBF") if not $status;
        $clean_issue = delete_mo_CS( mo => $EENBF) if not $status;
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
 
  }
  else
  {
        log_registry("It seems no Synched ERBS found ...");
        test_failed("$test_slogan");
  }
}


sub FUT133 #4.4.2.2.17
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  #$tc_id = 1 if($test_slogan =~ /4\.4\.3\.2\.21/);
  #$tc_id = 2 if($test_slogan =~ /4\.4\.3\.2\.23/);
  $tc_info = "WRANCM_CMSSnad_4.4.2.2.17 ; Set Proxy MO - Set Proxy MO ExternalENodeBFunction attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_ne("ENodeBFunction");
  if($ERBS)
  {
        log_registry("Selected ERBS : $ERBS");
        my $EUNW = pick_a_mo("$ERBS","EUtraNetwork");
        log_registry("It seems No EUtraNetwork exists under selected ERBS...") if not $EUNW;
        test_failed("$test_slogan") if not $EUNW;
        return "0" if not $EUNW;
	my $oth_attrs = get_attrs_ExternalENodeBFunction($ERBS);
        my ($EENBF,$proxy_attrs) = get_fdn("ExternalENodeBFunction","create");
        $EENBF = base_fdn_modify("$EUNW","$EENBF");
	$proxy_attrs = "$proxy_attrs"." "."$oth_attrs";
        my $status,$rev_id;
        ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$EENBF,$proxy_attrs,"no wait");
        log_registry("Problem in creation of proxy ExternalENodeBFunction mo...") if not $status;
        test_failed("$test_slogan") if not $status;
        return "0" if not $status;
     	my ($fdn,$set_attrs) = get_fdn("ExternalENodeBFunction","set");
	($status,$rev_id) = proxy_mo_set_decision("CSCLI",$EENBF,$set_attrs);
	log_registry("Problem in setting attributes of proxy ExternalENodeBFunction mo ...") if not $status;
	test_failed("$test_slogan") if not $status;
        test_passed("$test_slogan") if $status;
        ########################## Clean up ##########################
        my $clean_issue;
        log_registry("Clean up: Deleting MO $EENBF");
        $clean_issue = delete_mo_CS( mo => $EENBF);
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;
  }
  else
  {
        log_registry("It seems no Synched ERBS found ...");
        test_failed("$test_slogan");
  }
}

sub FUT134 #4.4.1.2.50 & 4.4.1.2.52
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.1\.2\.50/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.1\.2\.52/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.50  Create Proxy MO - Create Proxy MO with a Traffical Information different attribute value than the master from the application" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.52  Create Proxy MO - Create Proxy MO with a Traffical Information different attribute value than the master through the EM (netsim) " if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS_FDD = pick_a_erbs_using_cell(CELL => "ExternalEUtranCellFDD", VER => "vC.1.0");
  my $ERBS_TDD = pick_a_erbs_using_cell(CELL => "ExternalEUtranCellTDD", VER => "vC.1.0");
  if($ERBS_FDD and $ERBS_TDD)
  {
	my $flag = 0;
	my $EUCTDD,$EUCFDD,$EEUCFDD,$EEUCTDD,$EUCR_TDD,$EUCR_FDD;
	my @EEUCFDD; my @EEUCTDD;
	my($fcount,@FDD) = get_CMS_mo("ExternalEUtranCellFDD","$ERBS_FDD");
	my($tcount,@TDD) = get_CMS_mo("ExternalEUtranCellTDD","$ERBS_TDD");
	$flag = 1 if not ($fcount and $tcount);
	log_registry("It seems no pre-existing ExternalEUtranCellFDD/ExternalEUtranCellTDD mo found..") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	foreach(@FDD) {
		$EEUCFDD = "";
		my $state = get_proxy($_,"no log entry");
		$EEUCFDD = $_ if ($state == 1);
		push(@EEUCFDD,$EEUCFDD) if $EEUCFDD; }
	foreach(@TDD) {
		$EEUCTDD = "";
		my $state = get_proxy($_,"no log entry");
		$EEUCTDD = $_ if ($state == 1);
		push(@EEUCTDD,$EEUCTDD) if $EEUCTDD; }
	$flag = 1 if (!(scalar(@EEUCTDD)) or !(scalar(@EEUCFDD)));
	log_registry("No ExternalEUtranCellFDD/ExternalEUtranCellTDD mo found that is in consistent state.. : FDD @EEUCFDD,$EEUCFDD : TDD @EEUCTDD,$EEUCTDD") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	$EEUCTDD = $EEUCTDD[int(rand($#EEUCTDD))]; $EEUCFDD = $EEUCFDD[int(rand($#EEUCFDD))];
	$EEUCTDD =~ s/\n+//g; $EEUCFDD =~ s/\n+//g;
	log_registry("Selected Proxy ExternalEUtranCellFDD/ExternalEUtranCellTDD for reference are:\n $EEUCTDD \n $EEUCFDD");
	$EUCFDD = get_master_for_proxy($EEUCFDD);
	log_registry("Master for $EEUCFDD is: $EUCFDD") if $EUCFDD;
	$EUCTDD = get_master_for_proxy($EEUCTDD);
	log_registry("Master for $EEUCTDD is: $EUCTDD") if $EUCTDD;
	$EUCTDD =~ s/\n+//g; $EUCFDD =~ s/\n+//g;
	my %EEUCFDD_attrs = get_mo_attributes_CS(mo =>$EEUCFDD ,attributes => "eutranFrequencyRef reservedBy");
	my @EUCR_FDD = split(" ",$EEUCFDD_attrs{reservedBy});
	$EUCR_FDD = $EUCR_FDD[0] if (scalar(@EUCR_FDD));
	my %EEUCTDD_attrs = get_mo_attributes_CS(mo =>$EEUCTDD ,attributes => "eutranFrequencyRef reservedBy");
	my @EUCR_TDD = split(" ",$EEUCTDD_attrs{reservedBy});
	$EUCR_TDD = $EUCR_TDD[0] if (scalar(@EUCR_TDD));
	$flag = 1 if not($EUCFDD and $EUCTDD and (scalar(@EUCR_TDD)) and (scalar(@EUCR_FDD)));
	log_registry("It seems proxy ExternalEUtranCellFDD/ExternalEUtranCellTDD mo are consistent while it seems either anyone has no master or reservedBy attribute is not set to a relation..") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
	$EUCR_FDD =~ s/\n+//g; $EUCR_TDD =~ s/\n+//g;
	log_registry("================= Master EUtranCellFDD Mo attribute ====================");
	get_mo_attr($EUCFDD,"-o physicalLayerSubCellId physicalLayerCellIdGroup tac cellId");
	log_registry("====================================================================");
	log_registry("================= Master EUtranCellTDD Mo attribute ====================");
	get_mo_attr($EUCTDD,"-o physicalLayerSubCellId physicalLayerCellIdGroup tac cellId");
	log_registry("====================================================================");
	my %EUCFDD_attrs = get_mo_attributes_CS(mo =>$EUCFDD, attributes => "physicalLayerSubCellId physicalLayerCellIdGroup tac cellId localCellId ExternalEUtranCellFDDId");
	my %EUCTDD_attrs = get_mo_attributes_CS(mo =>$EUCTDD, attributes => "physicalLayerSubCellId physicalLayerCellIdGroup tac cellId localCellId ExternalEUtranCellTDDId");
	my $fpLSCI,$tpLSCI,$state,$rev_id,$fdd_attrs,$tdd_attrs,$fpLCIG,$tpLCIG;
	$fpLSCI = 2 if ($tc_id == 1 and $EUCFDD_attrs{physicalLayerSubCellId} < 2);
	$fpLSCI = 0 if ($tc_id == 1 and $EUCFDD_attrs{physicalLayerSubCellId} == 2);
	$tpLSCI = 2 if ($tc_id == 1 and $EUCTDD_attrs{physicalLayerSubCellId} < 2);
	$tpLSCI = 0 if ($tc_id == 1 and $EUCTDD_attrs{physicalLayerSubCellId} == 2);
	$fpLCIG = 147 if ($tc_id == 2 and $EUCFDD_attrs{physicalLayerCellIdGroup} < 147);
	$fpLCIG = 100 if ($tc_id == 2 and $EUCFDD_attrs{physicalLayerCellIdGroup} >= 147);
	$tpLCIG = 147 if ($tc_id == 2 and $EUCTDD_attrs{physicalLayerCellIdGroup} < 147);
	$tpLCIG = 100 if ($tc_id == 2 and $EUCTDD_attrs{physicalLayerCellIdGroup} >= 147);

	# Patch by eeitjn in 13.0.5, new master are now available..... different attribute names!!!!

	my %EUCFDD_attrs = get_mo_attributes_CS(mo =>$EUCFDD, attributes => "physicalLayerSubCellId physicalLayerCellIdGroup tac cellId EUtranCellFDDId localCellId ExternalEUtranCellFDDId");
	my %EUCTDD_attrs = get_mo_attributes_CS(mo =>$EUCTDD, attributes => "physicalLayerSubCellId physicalLayerCellIdGroup tac cellId EUtranCellTDDId localCellId ExternalEUtranCellTDDId");

	if (exists $EUCFDD_attrs{ExternalEUtranCellFDDId} )
		{
		$EUCFDD_attrs{EUtranCellFDDId} = $EUCFDD_attrs{ExternalEUtranCellFDDId};
		$EUCFDD_attrs{cellId} = $EUCFDD_attrs{localCellId};
		}
	if (exists $EUCTDD_attrs{ExternalEUtranCellTDDId} )
		{
		$EUCTDD_attrs{EUtranCellTDDId} = $EUCTDD_attrs{ExternalEUtranCellTDDId};
		$EUCTDD_attrs{cellId} = $EUCTDD_attrs{localCellId};
		}
	log_registry("$EUCFDD_attrs{EUtranCellFDDId} or  $EUCFDD_attrs{ExternalEUtranCellFDDId}");
	log_registry("$EUCFDD_attrs{cellId} or $EUCFDD_attrs{localCellId};");
	log_registry("$EUCTDD_attrs{EUtranCellTDDId} or $EUCTDD_attrs{ExternalEUtranCellTDDId};");
	log_registry("$EUCTDD_attrs{cellId} or $EUCTDD_attrs{localCellId};");


	$fdd_attrs = "userLabel $mo_proxy_cms physicalLayerSubCellId $fpLSCI physicalLayerCellIdGroup $EUCFDD_attrs{physicalLayerCellIdGroup} tac $EUCFDD_attrs{tac} localCellId $EUCFDD_attrs{cellId} eutranFrequencyRef $EEUCFDD_attrs{eutranFrequencyRef}" if ($tc_id == 1);
	$tdd_attrs = "userLabel $mo_proxy_cms physicalLayerSubCellId $tpLSCI physicalLayerCellIdGroup $EUCTDD_attrs{physicalLayerCellIdGroup} tac $EUCTDD_attrs{tac} localCellId $EUCTDD_attrs{cellId} eutranFrequencyRef $EEUCTDD_attrs{eutranFrequencyRef}" if($tc_id == 1);
	$fdd_attrs = "userLabel $mo_proxy_cms physicalLayerSubCellId $EUCFDD_attrs{physicalLayerSubCellId} physicalLayerCellIdGroup $fpLCIG tac $EUCFDD_attrs{tac} localCellId $EUCFDD_attrs{cellId} eutranFrequencyRef $EEUCFDD_attrs{eutranFrequencyRef}" if ($tc_id == 2);
	$tdd_attrs = "userLabel $mo_proxy_cms physicalLayerSubCellId $EUCTDD_attrs{physicalLayerSubCellId} physicalLayerCellIdGroup $tpLCIG tac $EUCTDD_attrs{tac} localCellId $EUCTDD_attrs{cellId} eutranFrequencyRef $EEUCTDD_attrs{eutranFrequencyRef}" if($tc_id == 2);
	my $fdd = $EEUCFDD;
	$fdd =~ s/ExternalEUtranCellFDD.*//g;
	$fdd = "$fdd"."ExternalEUtranCellFDD=$mo_proxy_cms";
	my $tdd = $EEUCTDD;
	$tdd =~ s/ExternalEUtranCellTDD.*//g;
	$tdd = "$tdd"."ExternalEUtranCellTDD=$mo_proxy_cms";	
	($state,$rev_id) = proxy_mo_create_decision("CSCLI",$fdd,$fdd_attrs,"no wait") if ($tc_id == 1);
	($state,$rev_id) = proxy_mo_create_decision("CLI",$fdd,$fdd_attrs,"no wait") if ($tc_id == 2);
	log_registry("Problem in creation of proxy ExternalEUtranCellFDD mo ...") if not $state;
	test_failed("$test_slogan") if not $state;
	return "0" if not $state;
	($state,$rev_id) = proxy_mo_create_decision("CSCLI",$tdd,$tdd_attrs,"no wait") if ($tc_id == 1);
	($state,$rev_id) = proxy_mo_create_decision("CLI",$tdd,$tdd_attrs,"no wait") if ($tc_id == 2);
	log_registry("Problem in creation of proxy ExternalEUtranCellTDD mo ...") if not $state;
	test_failed("$test_slogan") if not $state;
	return "0" if not $state;
	my $EUFR_fdd = $EUCR_FDD;
	$EUFR_fdd =~ s/\,EUtranCellRelation.*//g;
	my $EUFR_tdd = $EUCR_TDD;
	$EUFR_tdd =~ s/\,EUtranCellRelation.*//g;
	
	$time = sleep_start_time();

        my $EUCR_fdd = create_EUtranCellRelation(base=>"CLI", EUFR=>$EUFR_fdd,EEUCXDD => $fdd);
        my $EUCR_tdd = create_EUtranCellRelation(base=>"CLI", EUFR=>$EUFR_tdd,EEUCXDD => $tdd);
	$flag = 1 if not ($EUCR_fdd and $EUCR_tdd);
	log_registry("Issue in creation of EUtranCellRelation with ExternalEUtranCellTDD/ExternalEUtranCellFDD mo")if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	
	# Patch by eeitjn in 13.0.5, not waiting long enough... need to check those nudges

	long_sleep_found($time);
        sleep 180;

	log_registry("================= Proxy ExternalEUtranCellFDD Mo attribute ====================");
	get_mo_attr($fdd,"-o physicalLayerSubCellId physicalLayerCellIdGroup tac cellId");
	log_registry("====================================================================");
	log_registry("================= Proxy ExternalEUtranCellTDD Mo attribute ====================");
	get_mo_attr($tdd,"-o physicalLayerSubCellId physicalLayerCellIdGroup tac cellId");
	log_registry("====================================================================");
	my %fdd_attr = get_mo_attributes_CS(mo =>$fdd, attributes => "physicalLayerSubCellId physicalLayerCellIdGroup");
	my %tdd_attr = get_mo_attributes_CS(mo =>$tdd, attributes => "physicalLayerSubCellId physicalLayerCellIdGroup");
	$flag = 1 if ($fdd_attr{physicalLayerSubCellId} != $EUCFDD_attrs{physicalLayerSubCellId} or $tdd_attr{physicalLayerSubCellId} != $EUCTDD_attrs{physicalLayerSubCellId} or $fdd_attr{physicalLayerCellIdGroup} != $EUCFDD_attrs{physicalLayerCellIdGroup} or $tdd_attr{physicalLayerCellIdGroup} != $EUCTDD_attrs{physicalLayerCellIdGroup});



	log_registry("Attributes : $fdd_attr{physicalLayerSubCellId} != $EUCFDD_attrs{physicalLayerSubCellId} or $tdd_attr{physicalLayerSubCellId} != $EUCTDD_attrs{physicalLayerSubCellId} or $fdd_attr{physicalLayerCellIdGroup} != $EUCFDD_attrs{physicalLayerCellIdGroup} or $tdd_attr{physicalLayerCellIdGroup} != $EUCTDD_attrs{physicalLayerCellIdGroup} ");

	my $state_fdd = get_proxy($fdd);
	my $state_tdd = get_proxy($tdd);
	log_registry("It seems value of physicalLayerSubCellId or physicalLayerCellIdGroup attributes of ExternalEUtranCellTDD/ExternalEUtranCellFDD is changed to match master EUtranCellTDD/EUtranCellFDD attributes physicalLayerSubCellId or physicalLayerCellIdGroup value ...") if not $flag;
	log_registry("It seems value of physicalLayerSubCellId or physicalLayerCellIdGroup attributes of ExternalEUtranCellTDD/ExternalEUtranCellFDD does not match with master EUtranCellTDD/EUtranCellFDD attribute physicalLayerSubCellId or physicalLayerCellIdGroup ...") if $flag;
	test_failed("$test_slogan") if $flag;
	my $flag2 = 1 if($state_fdd !=1 or $state_tdd != 1);
	log_registry("It seems proxy ExternalEUtranCellTDD/ExternalEUtranCellFDD are not in consistent state ..") if $flag2;
	test_failed("$test_slogan") if (!($flag) and $flag2);
	test_passed("$test_slogan") if (!($flag) and !($flag2));
	
	###############################  Clean up Process #####################################
        my $clean_issue;
        my $mo = join(" ",$EUCR_fdd,$EUCR_tdd,$fdd);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
        	$clean_issue = delete_mo_NE(mo => $_);
        	log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
  }
  else
  {
        log_registry("It seems no Synched ERBS found that have ExternalEUtranCellFDD/ExternalEUtranCellTDD under it...");
        test_failed("$test_slogan");
  }
}

sub FUT135 # 4.4.2.2.22,4.4.2.2.23 and 4.4.2.2.24
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.2\.2\.22/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.2\.2\.23/);
  $tc_id = 3 if ($test_slogan =~ /4\.4\.2\.2\.24/);
  $tc_info = "WRANCM_CMSSnad_4.4.2.2.22 ; Set Proxy MO - Set EutranFrequency attribute" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.2.2.23 ; Set Proxy MO - Set EutranFrequency attribute earFcnDl to Non-Existing Master ExternalEutranFrequency Value" if ($tc_id == 2);
  $tc_info = "WRANCM_CMSSnad_4.4.2.2.24 ; Set Proxy MO - Set EutranFrequency attribute earFcnDl to a different already existing Master ExternalEutranFrequency Value" if ($tc_id == 3);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne("RncFunction","NEW");
  if($rnc)
  {
	my($EEF_fdn,$EEF_attr) = get_fdn("ExternalEutranFrequency","create");
	my $EEF_result = mo_create_decision("0",$EEF_fdn,$EEF_attr,"","wait for consistent");
	$EEF_result = master_for_proxy_handle("0",$EEF_fdn,$EEF_attr,"","wait for consistent") if($EEF_result and $EEF_result eq "KO");
	log_registry("There is problem in creation of master ExternalEutranFrequency MO...") if not $EEF_result;
	test_failed($test_slogan) if not $EEF_result;
	return "0" if not $EEF_result; 
        my $utran_cell = create_UtranCell($rnc,"uarfcnUl 10 uarfcnDl 2100");
        test_failed($test_slogan) if not $utran_cell;
        return "0" if not $utran_cell;
        log_registry("Selected UtranCell for EutranFreqRelation is: $utran_cell");
        log_registry("Wait for 2 Mins to get system stabilized....");
        sleep 120;
	my($EFR_fdn,$EF_proxy) = create_EutranFreqRelation(UC => $utran_cell, EEF => $EEF_fdn);
	log_registry("It seems there is some problem in creation of ExternalEutranFreqRelation ...") if not $EFR_fdn;
	test_failed($test_slogan) if not $EFR_fdn;
	return "0" if not $EFR_fdn;
	if($tc_id == 1) {
		my $mod_attrs = "userLabel"." "."$mo_proxy_cms"."2";
		my ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$EF_proxy,$mod_attrs);
		log_registry("It seems mo is not in consistent state after modifying attribute..") if(!($status) or $rev_id != 1);
		test_failed($test_slogan)  if (!($status) or $rev_id != 1);
		test_passed($test_slogan) if not (!($status) or $rev_id != 1); }
		my $status,$rev_id,$New_EEF_fdn,$New_EEF_attr;
		my $flag = 0;
		my %attrs_bef;
		my %EFR_attrs_aft;
	if($tc_id == 2) {
		my($EF_fdn,$mod_attrs) = get_fdn("EutranFrequency","set");
		%attrs_bef = get_mo_attributes_CS(mo =>$EF_proxy,attributes => "earfcnDl EutranFrequencyId");
		($status,$rev_id) = proxy_mo_set_decision("CSCLI",$EF_proxy,$mod_attrs,"NW");
		log_registry("It seems mo is not in consistent state after modifying attribute..") if not $status;
		test_failed($test_slogan)  if not $status;
		return "0" if not $status; }
	if($tc_id == 3) {
		my($EF_fdn,$mod_attrs) = get_fdn("ExternalEutranFrequency","set");
		($New_EEF_fdn,$New_EEF_attr) = get_fdn("ExternalEutranFrequency","set");
		$EEF_result = mo_create_decision("0",$New_EEF_fdn,$New_EEF_attr,"","wait for consistent");
		$EEF_result =  master_for_proxy_handle("0",$New_EEF_fdn,$New_EEF_attr,"","wait for consistent") if($EEF_result and $EEF_result eq "KO");
		log_registry("There is problem in creation of master ExternalEutranFrequency MO...") if not $EEF_result;
		test_failed($test_slogan) if not $EEF_result;
		return "0" if not $EEF_result;
		%attrs_bef = get_mo_attributes_CS(mo =>$EF_proxy,attributes => "earfcnDl EutranFrequencyId");
		($status,$rev_id) = proxy_mo_set_decision("CSCLI",$EF_proxy,$mod_attrs,"NW");
		log_registry("It seems mo is not in consistent state after modifying attribute..") if not $status;
		test_failed($test_slogan)  if not $status;
		return "0" if not $status; }
	if($tc_id == 3 or $tc_id == 2) {
		my $nudge = forceCC($EF_proxy);
		long_sleep_found($nudge) if $nudge;
		log_registry("========================= Updated EutranFreqRelation ====================");
		get_mo_attr($EFR_fdn);
		log_registry("==========================================================================");
		%EFR_attrs_aft = get_mo_attributes_CS(mo =>$EFR_fdn,attributes => "externalEutranFreq");
		$flag = 1 if ($EFR_attrs_aft{externalEutranFreq} =~ /$EEF_fdn$/);
		$flag = 1 if (($tc_id == 3) and ($EFR_attrs_aft{externalEutranFreq} !~ /$New_EEF_fdn$/));
		log_registry("It seems new master mo has not been assigned to proxy by changing earfcnDl attribute of proxy EutranFrequency") if $flag;
		test_failed($test_slogan) if $flag;
		return "0" if $flag;
		log_registry("New Master mo is: $EFR_attrs_aft{externalEutranFreq}");
		$status = get_proxy($EF_proxy); my $master_status = get_master($EFR_attrs_aft{externalEutranFreq});
		$flag = 1 if($status != 1 or $master_status != 1);
		log_registry("Proxy EutranFrequency or master  ExternalEutranFrequeny do not seem to be consistent after modifying attributes, while it should be") if $flag;
		log_registry("========================= Updated Proxy EutranFrequency ==================");
		get_mo_attr($EF_proxy);
		log_registry("==========================================================================");
		my %attrs_aft = get_mo_attributes_CS(mo =>$EF_proxy,attributes => "earfcnDl");
		my $flag2 = 0;
		$flag2 = 1 if(!($attrs_aft{earfcnDl}) or ($attrs_aft{earfcnDl} == $attrs_bef{earfcnDl}));
		log_registry("It seems attributes earfcnDl of proxy EutranFrequency is not modified after consistency check go for long sleep..") if $flag2;
		test_failed($test_slogan) if ($flag2 or $flag);
		test_passed($test_slogan) if (!($flag) and !($flag2)); 	}		
################################################# Clean Up ################################################################
        my $clean_issue,$mo,$master;
        $mo = join(" ",$EFR_fdn,$EF_proxy,$utran_cell,$EEF_fdn) if ($tc_id == 1);
	$mo = join(" ",$EFR_fdn,$EF_proxy,$EFR_attrs_aft{externalEutranFreq},$utran_cell,$EEF_fdn) if ($tc_id != 1);
        my @mo = split(" ",$mo);
        foreach(@mo)        {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;        }
  }
  else
  {
        log_registry("It seems no Synched RNC found of version vM or later... Or check theb sub node_version in Common.pm is correct with its node versions");
        test_failed($test_slogan);
  }
}

sub FUT136 # 4.4.2.3.4
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.3.4 ; Set Proxy MO - Set ExternalUtranCellFDD attribute";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS_FDD = pick_a_erbs_using_cell(CELL => "EUtranCellFDD", VER => "NEW");
  if($ERBS_FDD)
  {
        my $EUtranCellFDD = pick_a_mo("$ERBS_FDD","EUtranCellFDD");
        log_registry("It seems any of EUtranCellFDD cell exist under ERBS...") if not $EUtranCellFDD;
        test_failed($test_slogan) if not $EUtranCellFDD ;
        return "0" if not $EUtranCellFDD;
        my ($EUF,$attrs_EUF) = get_fdn("ExternalUtranFreq","create");
        my $EUF_result = mo_create_decision("0",$EUF,$attrs_EUF,"","wait for consistent");
	$EUF_result = master_for_proxy_handle("0",$EUF,$attrs_EUF,"","wait for consistent") if($EUF_result and $EUF_result eq "KO");
        log_registry("There is a problem in creation of ExternalUtranFreq MO ...") if not $EUF_result;
        test_failed($test_slogan) if not $EUF_result;
        return "0" if not $EUF_result;
        my ($EUC,$attrs_EUC) = get_fdn("MasterExternalUtranCell","create");
        my ($EUP_exist,@EUP_FDN) = get_CMS_mo("ExternalUtranPlmn");
        my $EUP_FDN = $EUP_FDN[0] if $EUP_exist;
        log_registry("It seems there is no ExternalUtranPlmn Exist ....") if not $EUP_exist;
        test_failed($test_slogan) if not $EUP_exist;
        return "0" if not $EUP_exist;
        log_registry("Selected UtranPlmn : $EUP_FDN");
        my %attrs_EUP = get_mo_attributes_CS( mo => $EUP_FDN, attributes => "mcc mnc mncLength");
        my $flag = 0;
        $flag = 1 if not ($attrs_EUP{mcc} and $attrs_EUP{mnc} and $attrs_EUP{mncLength});
        log_registry("It seems any of mcc/mnc/mncLength attribute of ExternalUtranPlmn is missing...") if $flag;
        test_failed($test_slogan) if $flag;
        return "0" if $flag;
        $EUP_FDN =~ s/\n//g;
        $attrs_EUC = "$attrs_EUC"." "."$EUP_FDN";
        $attrs_EUC = "$attrs_EUC"." "."mnc $attrs_EUP{mnc} mcc $attrs_EUP{mcc} mncLength $attrs_EUP{mncLength}";
        $attrs_EUC =~ s/\n//g;
        my $EUC_result = mo_create_decision("0",$EUC,$attrs_EUC);
	$EUC_result = master_for_proxy_handle("0",$EUC,$attrs_EUC) if($EUC_result and $EUC_result eq "KO");
        log_registry("There is a problem in creation of Master ExternalUtranCell MO ...") if not $EUC_result;
        test_failed($test_slogan) if not $EUC_result;
        return "0" if not $EUC_result;
        my ($FDD_UFR,$UF_fdn1) = create_UtranFreqRelation(EUCFDD => "$EUtranCellFDD",EUF=>"$EUF",base => "CSCLI");
        log_registry("It seems there is a problem in creation of UtranFreqRelation with EUtranCellFDD..") if not $FDD_UFR;
        test_failed($test_slogan) if not $FDD_UFR;
        return "0" if not $FDD_UFR;
        my ($UCR_fdn1,$P_EUC1) = create_UtranCellRelation(UFR => "$FDD_UFR",EUC => "$EUC");
        log_registry("It seems there is a problem in creation of UtranCellRelation with EUtranCellFDD..") if not ($UCR_fdn1 and $P_EUC1);
        test_failed($test_slogan) if not ($UCR_fdn1 and $P_EUC1);
        if($UCR_fdn1 and $P_EUC1)               {
                my $attrs = "userLabel"." "."$mo_proxy_cms"."34";
                my ($status,$rev_id) = proxy_mo_set_decision("CSCLI",$P_EUC1,$attrs,"FN");
                log_registry("It seems attribute is not getting set properly of proxy ExternalUtranCell mo ") if not $status;
                log_registry("It seems proxy ExternalUtranCell mo is not consistent after setting attribute..") if ($status and ($rev_id !=1));
                test_failed($test_slogan) if (!($status) or ($rev_id != 1));
                test_passed($test_slogan) if ($status and ($rev_id == 1));              }
        ################################ Clean up #######################################################
        my $clean_issue;
        my $mo = join(" ",$UCR_fdn1,$FDD_UFR,$EUC,$EUF);
        my @mo = split(" ",$mo);
        foreach(@mo)                {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue;                }
   }
  else
  {
        log_registry("It seems no Synched ERBSs of version vB.1.20 or later found having EUtranCellFDD or EUtranCellTDD under it...");
        test_failed($test_slogan);
  }
}

sub FUT137 # 4.4.2.4.6 and 4.4.2.4.9
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.2\.4\.6/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.2\.4\.9/);
  $tc_info = "WRANCM_CMSSnad_4.4.2.4.6 ; Set   - Set   ExternalCdma2000Cell traffical Id attribute (cellGlobalIdHrpd), missing master autofix on" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.2.4.9 ; Set   - Set   ExternalCdma2000Cell Traffical Information attributes (pnOffset), autofix on" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  
  my $ERBS = pick_a_erbs_using_cell(MO => "Cdma2000FreqBandRelation");
  if($ERBS)
  {  
	my ($count,@EC2P) = get_CMS_mo("ExternalCdma2000Plmn");
	log_registry("It seems no ExternalCdma2000Plmn mo found") if not $count;
	test_failed($test_slogan) if not $count;
	return "0" if not $count;
	my ($icount,@EC2F) = get_CMS_mo("ExternalCdma2000Freq");
	log_registry("It seems no ExternalCdma2000Freq mo found") if not $icount;
	test_failed($test_slogan) if not $icount;
	return "0" if not $icount;
	my ($jcount,@C2FBR) = get_CMS_mo("Cdma2000FreqBandRelation","$ERBS");
	log_registry("It seems no Cdma2000FreqBandRelation mo found for ERBS: $ERBS") if not $jcount;
	test_failed($test_slogan) if not $jcount;
	return "0" if not $jcount;
	my $EC2P = $EC2P[0];
	my $EC2F = $EC2F[int(rand($#EC2F))];
	my $C2FBR = $C2FBR[int(rand($#C2FBR))];
	$EC2F =~ s/\n+//g; $EC2P =~ s/\n+//g; $C2FBR =~ s/\n+//g;
	log_registry("Selected ExternalCdma2000Plmn mo: $EC2P");
	log_registry("Selected ExternalCdma2000Freq mo: $EC2F");
	log_registry("Selected Cdma2000FreqBandRelation mo: $C2FBR");
	my ($MEC2C,$MEC2C_attrs) = get_fdn("MasterExternalCdma2000Cell","create");
	$MEC2C = base_fdn_modify("$EC2P","$MEC2C");
	$MEC2C_attrs = "$MEC2C_attrs"." "."$EC2F";
	$MEC2C_attrs =~ s/\n+//g;
	my $result = mo_create_decision("0",$MEC2C,$MEC2C_attrs);
	$result = master_for_proxy_handle("0",$MEC2C,$MEC2C_attrs) if($result and $result eq "KO");
        log_registry("There is a problem in creation of Master ExternalCdma2000Cell MO ...") if not $result;
        test_failed($test_slogan) if not $result;
        return "0" if not $result;
	my($C2CR,$PEC2C) = create_Cdma2000CellRelation(MEC2C => $MEC2C, C2FBR => $C2FBR);
        test_failed($test_slogan) if not $C2CR;
        return "0" if not $C2CR;
	my $new_master,$fdn,$PEC2C_attrs,$status,$rev_id;
	if($tc_id == 1)		{
		($fdn,$PEC2C_attrs) = get_fdn("cTidExternalCdma2000Cell","set");
		($status,$rev_id) = proxy_mo_set_decision("CSCLI",$PEC2C,$PEC2C_attrs);
		log_registry("It seems proxy mo is not in consistent state after modifying attribute")if(!($status) or $rev_id != 1);
		test_failed($test_slogan)  if (!($status) or ($rev_id != 1));
		if($status and $rev_id == 1) {
			$new_master = get_master_for_proxy($PEC2C);
			log_registry("New Master for $PEC2C is: $new_master") if $new_master;
			log_registry("It seems no new master is get created after changing traffical identity of proxy ExternalCdma2000Cell ..") if (!($new_master) or ($new_master =~ /$MEC2C$/));
			test_failed($test_slogan) if(!($new_master) or ($new_master =~ /$MEC2C$/));
			test_passed($test_slogan) if($new_master and ($new_master !~ /$MEC2C$/)); }	}
	if($tc_id == 2)		{
		($fdn,$PEC2C_attrs) = get_fdn("cPnsExternalCdma2000Cell","set");
		($status,$rev_id) = proxy_mo_set_decision("CSCLI",$PEC2C,$PEC2C_attrs,"NW");
		log_registry("eeitjn: The Autofix is very quick now, check function for attribute difference is too slow") if not $status;
		log_registry("eeitjn: Check in the logs below for AUTOFIX is ON fixing the inconsistency") if not $status;
		
		#test_failed($test_slogan)  if not $status;
		
	         my $stat = attr_value_comp($PEC2C,$PEC2C_attrs);
                log_registry("========= Attributes of MO After =========");
                get_mo_attr($PEC2C,$PEC2C_attrs);
                log_registry("===========================================");
		log_registry("It seems pnOffset attribute of proxy ExternalCdma2000Cell is not get rollback to original value ") if $stat;
		log_registry("It seems pnOffset attribute of proxy ExternalCdma2000Cell get rollback to original value ") if not $stat;
		$master = get_master_for_proxy($PEC2C);
                log_registry("Master for $PEC2C is: $master") if $master;
		log_registry("It seems master of proxy ExternalCdma2000Cell mo is either missing or newly get created by changing pnOffset attribute of proxy ExternalCdma2000Cell ..") if (!($master) or ($master !~ /$MEC2C$/));
		test_failed($test_slogan) if($state or !($master) or ($master !~ /$MEC2C$/));
		test_passed($test_slogan) if(!($stat) and $master and ($master =~ /$MEC2C$/));	
		}
		
        ###############################  Clean up Process #####################################
        my $clean_issue,$mo;
        $mo = join(" ",$C2CR,$PEC2C,$MEC2C,$new_master) if ($tc_id == 1);
	$mo = join(" ",$C2CR,$PEC2C,$MEC2C) if ($tc_id == 2);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }		
  }
  else
  {
		log_registry("It seems no synched ERBS found that have single Cdma2000FreqBandRelation");
		test_failed($test_slogan);
  }
}


sub FUT138 #4.4.1.7.7
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.1.7.7 ; Update attribute adjacentFreq on   to a different pre-existing sn ExternalUtranFreq in the SubNetwork MIB from an application with already existing UtraNetwork ";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(MO => "UtranFreqRelation");
  if($ERBS)
  {
  	my($icount,@EUF) = get_CMS_mo("ExternalUtranFreq");
	log_registry("It seems no master ExternalUtranFreq mo found") if not $icount;
        test_failed("$test_slogan") if not $icount;
        return "0" if not $icount;
        my $flag = 0;
        my $EUF,$UFR,$new_EUF;
	my @SEL_UFR;
        my($count,@UFR) = get_CMS_mo("UtranFreqRelation","$ERBS");
        log_registry("It seems no pre-existing UtranFreqRelation found with ERBS $ERBS") if not $count;
        test_failed("$test_slogan") if not $count;
        return "0" if not $count;
        foreach(@UFR) {
                $UFR = "";
                my %UFR = get_mo_attributes_CS(mo =>$_,attributes => "adjacentFreq");
                $UFR = $_ if ($UFR{adjacentFreq} and  $UFR{adjacentFreq} =~ /ExternalUtranFreq\=/);
                push(@SEL_UFR,$UFR) if $UFR; }
        $flag = 1 if not (scalar(@SEL_UFR));
        log_registry("No UtranFreqRelation under selected ERBS found that has master ExternalUtranFreq mo set as adjacentFreq") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
        $UFR = $SEL_UFR[int(rand($#SEL_UFR))];        $UFR =~ s/\n+//g;
        log_registry("Selected UtranFreqRelation for test case is:\n $UFR ");
	my %UFR_attrs_bef = get_mo_attributes_CS(mo =>$UFR ,attributes => "adjacentFreq");
	$EUF = $UFR_attrs_bef{adjacentFreq};
	$EUF =~ s/\n+//g;
	foreach(@EUF) {
               $new_EUF = $_ if ($_ !~ /$EUF$/);
               last if $new_EUF; }
	log_registry("It seems any other master ExternalUtranFreq mo does not exist other than $EUF") if not $new_EUF;
	test_failed("$test_slogan") if not $new_EUF;
	return "0" if not $new_EUF;
	$new_EUF =~ s/\n+//g;
	my $attrs = "adjacentFreq $new_EUF";
	log_registry("========= Attributes of UtranFreqRelation Before =========");
	get_mo_attr($UFR,$attrs);
	log_registry("==========================================================");
	my $status = set_attributes_mo_CLI(mo => $UFR, base => CSCLI, attributes => $attrs);
	log_registry("It seems problem in setting attribute of UtranFreqRelation ..") if not $status;
	test_failed("$test_slogan") if not $status;
	return "0" if not $status;
	$status = does_mo_exist_CLI( base => CSCLI, mo => $UFR); 
	log_registry("It seems relation has been deleted after setting adjacentFreq attribute ..") if ($status eq "NO");
	test_failed("$test_slogan") if ($status eq "NO");
	return "0" if ($status eq "NO");
	my $stat = attr_value_comp($UFR,$attrs);
	log_registry("========= Attributes of UtranFreqRelation After =========");
	get_mo_attr($UFR,$attrs);
	log_registry("=========================================================");
	log_registry("It seems attribute has not been set properly for relation ..") if not $stat;
	test_failed("$test_slogan") if not $stat;
	return "0" if not $stat;
	my $EUCXDD = $UFR;
	$EUCXDD =~ s/\,UtranFreqRelation\=.+//g;  $EUCXDD =~ s/\n+//g;
	my $nudge = forceCC($EUCXDD);
	long_sleep_found("$nudge") if $nudge;
	my %UFR_attrs_aft = get_mo_attributes_CS(mo =>$UFR ,attributes => "adjacentFreq");
	$flag = 1 if ($UFR_attrs_aft{adjacentFreq} !~ /$EUF$/);
	log_registry("========= Attributes of UtranFreqRelation After long sleep =========");
	get_mo_attr($UFR,$attrs);
	log_registry("====================================================================");
	log_registry("It seems adjacentFreq attribute of UtranFreqRelation is not rollback to original ExternalUtranFreq mo..") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
	test_passed("$test_slogan");
  }
  else
  {
        log_registry("It seems no Synched ERBS found that have UtranFreqRelation under it...");
        test_failed("$test_slogan");
  }
}


sub FUT139 #4.4.1.2.55 and 4.4.1.2.57
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if ($test_slogan =~ /4\.4\.1\.2\.55/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.1\.2\.57/);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.55  Create Proxy MO - Create Proxy MO with a Network Information different attribute value than the master from the application" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.1.2.57  Create Proxy MO - Create Proxy MO with a Network Information different attribute value than the master through the EM (netsim)" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS_FDD = pick_a_erbs_using_cell(CELL => "ExternalEUtranCellFDD", VER => "vC.1.74");
  my $ERBS_TDD = pick_a_erbs_using_cell(CELL => "ExternalEUtranCellTDD", VER => "vD.1.188");
  if($ERBS_FDD and $ERBS_TDD)
  {
	my $flag = 0;
	my $EUCTDD,$EUCFDD,$EEUCFDD,$EEUCTDD,$EUCR_TDD,$EUCR_FDD;
	my @EEUCFDD; my @EEUCTDD;
	my($fcount,@FDD) = get_CMS_mo("ExternalEUtranCellFDD","$ERBS_FDD");
	my($tcount,@TDD) = get_CMS_mo("ExternalEUtranCellTDD","$ERBS_TDD");
	$flag = 1 if not ($fcount and $tcount);
	log_registry("It seems no pre-existing ExternalEUtranCellFDD/ExternalEUtranCellTDD mo found..") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	foreach(@FDD) {
		$EEUCFDD = "";
		my $state = get_proxy($_,"no log entry");
		$EEUCFDD = $_ if ($state == 1);
		push(@EEUCFDD,$EEUCFDD) if $EEUCFDD; }
	foreach(@TDD) {
		$EEUCTDD = "";
		my $state = get_proxy($_,"no log entry");
		$EEUCTDD = $_ if ($state == 1);
		push(@EEUCTDD,$EEUCTDD) if $EEUCTDD; }
	$flag = 1 if (!(scalar(@EEUCTDD)) or !(scalar(@EEUCFDD)));
	log_registry("No ExternalEUtranCellFDD/ExternalEUtranCellTDD mo found that is in consistent state..") if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	$EEUCTDD = $EEUCTDD[int(rand($#EEUCTDD))]; $EEUCFDD = $EEUCFDD[int(rand($#EEUCFDD))];
	$EEUCTDD =~ s/\n+//g; $EEUCFDD =~ s/\n+//g;
	log_registry("Selected Proxy ExternalEUtranCellFDD/ExternalEUtranCellTDD for reference are:\n $EEUCTDD \n $EEUCFDD");
	$EUCFDD = get_master_for_proxy($EEUCFDD);
	log_registry("Master for $EEUCFDD is: $EUCFDD") if $EUCFDD;
	$EUCTDD = get_master_for_proxy($EEUCTDD);
	log_registry("Master for $EEUCTDD is: $EUCTDD") if $EUCTDD;
	$EUCTDD =~ s/\n+//g; $EUCFDD =~ s/\n+//g;
	my %EEUCFDD_attrs = get_mo_attributes_CS(mo =>$EEUCFDD ,attributes => "eutranFrequencyRef reservedBy");
	my @EUCR_FDD = split(" ",$EEUCFDD_attrs{reservedBy});
	$EUCR_FDD = $EUCR_FDD[0] if (scalar(@EUCR_FDD));
	my %EEUCTDD_attrs = get_mo_attributes_CS(mo =>$EEUCTDD ,attributes => "eutranFrequencyRef reservedBy");
	my @EUCR_TDD = split(" ",$EEUCTDD_attrs{reservedBy});
	$EUCR_TDD = $EUCR_TDD[0] if (scalar(@EUCR_TDD));
	$flag = 1 if not($EUCFDD and $EUCTDD and (scalar(@EUCR_TDD)) and (scalar(@EUCR_FDD)));
	log_registry("It seems proxy ExternalEUtranCellFDD/ExternalEUtranCellTDD mo are consistent while it seems either anyone has no master or reservedBy attribute is not set to a relation..") if $flag;
        test_failed("$test_slogan") if $flag;
        return "0" if $flag;
	$EUCR_FDD =~ s/\n+//g; $EUCR_TDD =~ s/\n+//g;
	log_registry("================= Master EUtranCellFDD Mo attribute ====================");
	get_mo_attr($EUCFDD,"-o physicalLayerSubCellId physicalLayerCellIdGroup tac cellId EUtranCellFDDId");
	log_registry("====================================================================");
	log_registry("================= Master EUtranCellTDD Mo attribute ====================");
	get_mo_attr($EUCTDD,"-o physicalLayerSubCellId physicalLayerCellIdGroup tac cellId EUtranCellTDDId");
	log_registry("====================================================================");

	# Patch by eeitjn in 13.0.5, new master are now available..... different attribute names!!!!

	my %EUCFDD_attrs = get_mo_attributes_CS(mo =>$EUCFDD, attributes => "physicalLayerSubCellId physicalLayerCellIdGroup tac cellId EUtranCellFDDId localCellId ExternalEUtranCellFDDId");
	my %EUCTDD_attrs = get_mo_attributes_CS(mo =>$EUCTDD, attributes => "physicalLayerSubCellId physicalLayerCellIdGroup tac cellId EUtranCellTDDId localCellId ExternalEUtranCellTDDId");

	if (exists $EUCFDD_attrs{ExternalEUtranCellFDDId} )
		{
		$EUCFDD_attrs{EUtranCellFDDId} = $EUCFDD_attrs{ExternalEUtranCellFDDId};
		$EUCFDD_attrs{cellId} = $EUCFDD_attrs{localCellId};
		}
	if (exists $EUCTDD_attrs{ExternalEUtranCellTDDId} )
		{
		$EUCTDD_attrs{EUtranCellTDDId} = $EUCTDD_attrs{ExternalEUtranCellTDDId};
		$EUCTDD_attrs{cellId} = $EUCTDD_attrs{localCellId};
		}
	log_registry("$EUCFDD_attrs{EUtranCellFDDId} or  $EUCFDD_attrs{ExternalEUtranCellFDDId}");
	log_registry("$EUCFDD_attrs{cellId} or $EUCFDD_attrs{localCellId};");
	log_registry("$EUCTDD_attrs{EUtranCellTDDId} or $EUCTDD_attrs{ExternalEUtranCellTDDId};");
	log_registry("$EUCTDD_attrs{cellId} or $EUCTDD_attrs{localCellId};");



	my $fddId,$tddId;
	$fdd_attrs = "userLabel $mo_proxy_cms physicalLayerSubCellId $EUCFDD_attrs{physicalLayerSubCellId} physicalLayerCellIdGroup $EUCFDD_attrs{physicalLayerCellIdGroup} tac $EUCFDD_attrs{tac} localCellId $EUCFDD_attrs{cellId} eutranFrequencyRef $EEUCFDD_attrs{eutranFrequencyRef} masterEUtranCellFDDId $mo_proxy_cms";
	$tdd_attrs = "userLabel $mo_proxy_cms physicalLayerSubCellId $EUCTDD_attrs{physicalLayerSubCellId} physicalLayerCellIdGroup $EUCTDD_attrs{physicalLayerCellIdGroup} tac $EUCTDD_attrs{tac} localCellId $EUCTDD_attrs{cellId} eutranFrequencyRef $EEUCTDD_attrs{eutranFrequencyRef} masterEUtranCellTDDId $mo_proxy_cms";

	log_registry("$fdd_attrs");
	log_registry("$tdd_attrs");
	my $fdd = $EEUCFDD;
	$fdd =~ s/ExternalEUtranCellFDD.*//g;
	$fdd = "$fdd"."ExternalEUtranCellFDD=$mo_proxy_cms";
	my $tdd = $EEUCTDD;
	$tdd =~ s/ExternalEUtranCellTDD.*//g;
	$tdd = "$tdd"."ExternalEUtranCellTDD=$mo_proxy_cms";	
	($state,$rev_id) = proxy_mo_create_decision("CSCLI",$tdd,$tdd_attrs,"no wait") if ($tc_id == 1);
	($state,$rev_id) = proxy_mo_create_decision("CLI",$tdd,$tdd_attrs,"no wait") if ($tc_id == 2);
	log_registry("Problem in creation of proxy ExternalEUtranCellTDD mo ...") if not $state;
	test_failed("$test_slogan") if not $state;
	return "0" if not $state;
	($state,$rev_id) = proxy_mo_create_decision("CSCLI",$fdd,$fdd_attrs,"no wait") if ($tc_id == 1);
	($state,$rev_id) = proxy_mo_create_decision("CLI",$fdd,$fdd_attrs,"no wait") if ($tc_id == 2);
	log_registry("Problem in creation of proxy ExternalEUtranCellFDD mo ...") if not $state;
	test_failed("$test_slogan") if not $state;
	return "0" if not $state;
	my $EUFR_fdd = $EUCR_FDD;
	$EUFR_fdd =~ s/\,EUtranCellRelation.*//g;
	my $EUFR_tdd = $EUCR_TDD;
	$EUFR_tdd =~ s/\,EUtranCellRelation.*//g;
        my $EUCR_fdd = create_EUtranCellRelation(base=>"CLI", EUFR=>$EUFR_fdd,EEUCXDD => $fdd);
        my $EUCR_tdd = create_EUtranCellRelation(base=>"CLI", EUFR=>$EUFR_tdd,EEUCXDD => $tdd);
	$flag = 1 if not ($EUCR_fdd and $EUCR_tdd);
	log_registry("Issue in creation of EUtranCellRelation with ExternalEUtranCellTDD/ExternalEUtranCellFDD mo")if $flag;
	test_failed("$test_slogan") if $flag;
	return "0" if $flag;
	log_registry("================= Proxy ExternalEUtranCellFDD Mo attribute ====================");
	get_mo_attr($fdd,"-o physicalLayerSubCellId physicalLayerCellIdGroup tac cellId masterEUtranCellFDDId");
	log_registry("====================================================================");
	log_registry("================= Proxy ExternalEUtranCellTDD Mo attribute ====================");
	get_mo_attr($tdd,"-o physicalLayerSubCellId physicalLayerCellIdGroup tac cellId masterEUtranCellTDDId");
	log_registry("====================================================================");
	my %fdd_attr = get_mo_attributes_CS(mo =>$fdd, attributes => "masterEUtranCellFDDId");
	my %tdd_attr = get_mo_attributes_CS(mo =>$tdd, attributes => "masterEUtranCellTDDId");
	$flag = 1 if ($fdd_attr{masterEUtranCellFDDId} !~ /$EUCFDD_attrs{EUtranCellFDDId}/ or $tdd_attr{masterEUtranCellTDDId} != $EUCTDD_attrs{EUtranCellTDDId});
	my $nudge = forceCC($fdd);
	$nudge = forceCC($tdd);
	long_sleep_found($time);

#	long_sleep_found($nudge) if $nudge;
	my $state_fdd = get_proxy($fdd);
	my $state_tdd = get_proxy($tdd);
	log_registry("It seems value of masterEUtranCellFDDId or masterEUtranCellTDDId attributes of ExternalEUtranCellFDD/ExternalEUtranCellTDD is changed to match master EUtranCellFDD/EUtranCellTDD attributes EUtranCellFDDId or EUtranCellTDDId value ...") if not $flag;
	log_registry("It seems value of masterEUtranCellFDDId or masterEUtranCellTDDId attributes of ExternalEUtranCellFDD/ExternalEUtranCellTDD is not matching with master EUtranCellFDD/EUtranCellTDD attributes EUtranCellFDDId or EUtranCellTDDId value ...") if $flag;
	test_failed("$test_slogan") if $flag;
	my $flag2 = 1 if($state_fdd !=1 or $state_tdd != 1);
	log_registry("It seems proxy ExternalEUtranCellTDD/ExternalEUtranCellFDD are not in consistent state ..") if $flag2;
	test_failed("$test_slogan") if (!($flag) and $flag2);
	my $action12 = 0;
	my $action3 = 0;
	$action12 = 1 if (!($flag) and !($flag2));
        my $EUNW = pick_a_mo("$ERBS_FDD","EUtraNetwork");
        log_registry("It seems No EUtraNetwork exists under selected ERBS: $ERBS_FDD") if not $EUNW;
	$flag = 1 if not $EUNW;
	my $EENBF,$proxy_attrs,$fdn;
	if(!($flag)) {
        	my $oth_attrs = get_attrs_ExternalENodeBFunction($ERBS_FDD);
        	($EENBF,$proxy_attrs) = get_fdn("ExternalENodeBFunction","create");
        	$EENBF = base_fdn_modify("$EUNW","$EENBF") if not $flag;
		my $mEfid = "$mo_proxy_cms"."23";
        	$proxy_attrs = "$proxy_attrs"." "."$oth_attrs"." "."masterEnbFunctionId $mEfid";
        	my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$EENBF,$proxy_attrs,"no wait");
        	log_registry("Problem in creation of proxy ExternalENodeBFunction mo...") if not $status;
		$flag = 1 if not $status;
		log_registry("===================== ExternalENodeBFunction attribute Before ===============")if not $flag;
		get_mo_attr($EENBF,"masterEnbFunctionId")if not $flag;
		log_registry("=============================================================================")if not $flag;
		$fdn = "$EENBF".",ExternalEUtranCellFDD=$mo_proxy_cms" if not $flag;
		my $attrs = "userLabel $mo_proxy_cms physicalLayerSubCellId $EUCFDD_attrs{physicalLayerSubCellId} physicalLayerCellIdGroup $EUCFDD_attrs{physicalLayerCellIdGroup} tac $EUCFDD_attrs{tac} localCellId $EUCFDD_attrs{cellId} eutranFrequencyRef $EEUCFDD_attrs{eutranFrequencyRef} masterEUtranCellFDDId $EUCFDD_attrs{EUtranCellFDDId}";
		my $state = 1;
		($state,$rev_id) = proxy_mo_create_decision("CSCLI",$fdn,$attrs,"no wait") if not $flag;
		log_registry("Problem in creation of proxy ExternalEUtranCellFDD mo...") if not $state;
		$flag = 1 if not $state;
		my $nudge = forceCC($EENBF) if not $flag;
		long_sleep_found($nudge) if (!($flag) and $nudge);
		my %EENBF_attrs = get_mo_attributes_CS(mo =>$EENBF, attributes => "masterEnbFunctionId")if not $flag;
		log_registry("It seems masterEnbFunctionId attribute of ExternalENodeBFunction is not rollback to original value..") if (!($flag) and $EENBF_attrs{masterEnbFunctionId} =~ /$mEfid$/);
		log_registry("======================== ExternalENodeBFunction attribute After ===============")if not $flag;
		get_mo_attr($EENBF,"masterEnbFunctionId")if not $flag;
		log_registry("===============================================================================")if not $flag;
		$flag = 1 if ($EENBF_attrs{masterEnbFunctionId} =~ /$mEfid$/);
		$state = get_proxy($EENBF);
		log_registry("It seems proxy ExternalEnodeBFunction is not consistent...") if ($state != 1);
		$flag = 1 if ($state != 1);
		test_failed("$test_slogan") if $flag;
		$action3 = 1 if not $flag; 	}
	test_passed("$test_slogan") if ($action3 and $action12);
	###############################  Clean up Process #####################################
        my $clean_issue;
        my $mo = join(" ",$EUCR_fdd,$EUCR_tdd,$fdd,$fdn,$EENBF);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
        log_registry("Clean up: Deleting MO $tdd");
        $clean_issue = delete_mo_NE(mo => $tdd);
        log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; 
  }
  else
  {
        log_registry("It seems no Synched ERBS of version vC.1.0 or later found that have ExternalEUtranCellFDD/ExternalEUtranCellTDD under it...");
        test_failed("$test_slogan");
  }
}

sub FUT140 #4.4.2.2.21
{
  my $test_slogan = $_[0];
  my $tc_info = "WRANCM_CMSSnad_4.4.2.2.21 ; Set Proxy MO - Set Proxy MO ExternalENodeBFunction Trafficial Information attributes";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(CELL => "ExternalEUtranCellFDD", VER => "NEW");
  
  $ERBS = "SubNetwork=ONRM_ROOT_MO_R,SubNetwork=ERBS-SUBNW-1,MeContext=LTE01ERBS00124,ManagedElement=1,ENodeBFunction=1";
  if($ERBS)
  {
	my $EEUCFDD; my @EEUCFDD;
	my $EUNW = pick_a_mo("$ERBS","EUtraNetwork");
        log_registry("It seems No EUtraNetwork exists under selected ERBS: $ERBS") if not $EUNW;
	test_failed($test_slogan) if not $EUNW;
	return "0" if not $EUNW;
	my($fcount,@FDD) = get_CMS_mo("ExternalEUtranCellFDD","$ERBS");
	foreach(@FDD) {
        	$EEUCFDD = "";
        	my $state = get_proxy($_,"no log entry");
        	$EEUCFDD = $_ if ($state == 1);
        	push(@EEUCFDD,$EEUCFDD) if $EEUCFDD; }
	log_registry("No ExternalEUtranCellFDD mo found that is in consistent state..") if not (scalar(@EEUCFDD));
	test_failed($test_slogan) if not (scalar(@EEUCFDD));
	return "0" if not (scalar(@EEUCFDD));
	$EEUCFDD = $EEUCFDD[int(rand($#EEUCFDD))];  $EEUCFDD =~ s/\n+//g;
	log_registry("Selected Proxy ExternalEUtranCellFDD for reference is : $EEUCFDD");
	my $EUCFDD = get_master_for_proxy($EEUCFDD);
	log_registry("Master for $EEUCFDD is: $EUCFDD") if $EUCFDD;
	log_registry("It seems selected proxy ExternalEUtranCellFDD is consistent while has no master ..") if not $EUCFDD;
	test_failed($test_slogan) if not $EUCFDD;
	return "0" if not $EUCFDD;
	$EUCFDD =~ s/\n+//g;

	# Patch by eeitjn in 13.0.5, new master are now available..... different attribute names!!!!

	my %EUCFDD_attrs = get_mo_attributes_CS(mo =>$EUCFDD, attributes => "physicalLayerSubCellId physicalLayerCellIdGroup tac cellId EUtranCellFDDId localCellId ExternalEUtranCellFDDId");

	if (exists $EUCFDD_attrs{ExternalEUtranCellFDDId} )
		{
		$EUCFDD_attrs{EUtranCellFDDId} = $EUCFDD_attrs{ExternalEUtranCellFDDId};
		$EUCFDD_attrs{cellId} = $EUCFDD_attrs{localCellId};
		}

#	my %EUCFDD_attrs = get_mo_attributes_CS(mo =>$EUCFDD, attributes => "physicalLayerSubCellId physicalLayerCellIdGroup tac cellId EUtranCellFDDId");


	my %EEUCFDD_attrs = get_mo_attributes_CS(mo =>$EEUCFDD ,attributes => "eutranFrequencyRef");
	my $oth_attrs = get_attrs_ExternalENodeBFunction($ERBS);
        my ($EENBF,$proxy_attrs) = get_fdn("ExternalENodeBFunction","create");
        $EENBF = base_fdn_modify("$EUNW","$EENBF");
        $proxy_attrs = "$proxy_attrs"." "."$oth_attrs";
        my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$EENBF,$proxy_attrs,"no wait");
        log_registry("Problem in creation of proxy ExternalENodeBFunction mo...") if not $status;
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
	my $fdn = "$EENBF".",ExternalEUtranCellFDD=$mo_proxy_cms";
	my $attrs = "userLabel $mo_proxy_cms physicalLayerSubCellId $EUCFDD_attrs{physicalLayerSubCellId} physicalLayerCellIdGroup $EUCFDD_attrs{physicalLayerCellIdGroup} tac $EUCFDD_attrs{tac} localCellId $EUCFDD_attrs{cellId} eutranFrequencyRef $EEUCFDD_attrs{eutranFrequencyRef} masterEUtranCellFDDId $EUCFDD_attrs{EUtranCellFDDId}";
	($status,$rev_id) = proxy_mo_create_decision("CSCLI",$fdn,$attrs,"no wait");
	log_registry("Problem in creation of proxy ExternalEUtranCellFDD mo...") if not $status;
	test_failed($test_slogan) if not $status;
	return "0" if not $status;		
	my $nudge = forceCC($EENBF);
	long_sleep_found($nudge) if $nudge;
	log_registry("===================== ExternalENodeBFunction attribute Before ===============");
        get_mo_attr($EENBF,"masterEnbFunctionId");
        log_registry("=============================================================================");
	my $state = get_proxy($EENBF);
	log_registry("It seems proxy ExternalEnodeBFunction is not consistent...") if ($state != 1);
	test_failed($test_slogan) if ($state != 1);
	return "0" if ($state != 1);
	my $new_id = "$mo_proxy_cms"."32";
	my $new_attrs = "masterEnbFunctionId"." "."$new_id";
	($status,$rev_id) = proxy_mo_set_decision("CSCLI",$EENBF,$new_attrs,"NW");
	
	log_registry("eeitjn: The Autofix is very quick now, check function for attribute difference is too slow");
	log_registry("eeitjn: Check in the logs below for AUTOFIX is ON fixing the inconsistency");
	
	#log_registry("Either Problem in setting attribute ...") if not $status;
	#test_failed($test_slogan) if not $status;
	#return "0" if not $status;
	#$nudge = forceCC($EENBF);
	#long_sleep_found($nudge) if $nudge;
	
	my %EENBF_attr_aft = get_mo_attributes_CS(mo =>$EENBF, attributes => "masterEnbFunctionId");
	log_registry("It seems masterEnbFunctionId attribute of ExternalENodeBFunction is not rollback to original value..") if ($EENBF_attr_aft{masterEnbFunctionId} =~ /$new_id$/);
        log_registry("======================== ExternalENodeBFunction attribute After ===============");
	get_mo_attr($EENBF,"masterEnbFunctionId");
	log_registry("===============================================================================");
	$state = get_proxy($EENBF);
	log_registry("It seems proxy ExternalEnodeBFunction is not consistent...") if ($state != 1);
	test_failed("$test_slogan") if (($EENBF_attr_aft{masterEnbFunctionId} =~ /$new_id$/) or ($state != 1));
	test_passed("$test_slogan") if (($EENBF_attr_aft{masterEnbFunctionId} !~ /$new_id$/) and ($state == 1));
        ###############################  Clean up Process #####################################
        my $clean_issue;
        my $mo = join(" ",$fdn,$EENBF);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
	}
	else
	{
		log_registry("It seems no synched ERBS found, having ExternalEUtranCellFDD under it..");
		test_failed($test_slogan);
	}
}

sub FUT141 # 4.4.2.1.12 and 4.4.2.1.5, 4.4.2.1.13
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_id = 1 if($test_slogan =~ /4\.4\.2\.1\.12/);
  $tc_id = 2 if($test_slogan =~ /4\.4\.2\.1\.5/);
  $tc_id = 3 if($test_slogan =~ /4\.4\.2\.1\.13/);
  $tc_info = "WRANCM_CMSSnad_4.4.2.1.12 ; Set Master MO - Set UtranCell Master MO attribute lac/rac/sac to a new lac/rac/sac value with no reservedBy on proxy MO" if($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.2.1.5 ; Set   - Set UtranCell Master MO attribute locationAreaRef/routingAreaRef/serviceAreaRef" if($tc_id == 2);
  $tc_info = "WRANCM_CMSSnad_4.4.2.1.13 ; Set Master MO - Set UtranCell Master MO attribute lac/rac/sac to a new lac/rac/sac value with a reservedBy on proxy MO" if($tc_id == 3);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne("RncFunction");
  if($rnc)
  {
	my @lac = PICK_NEW_LAS(1);
	my $lac = $lac[0];
	log_registry("No new lac value selected for location area..") if not $lac;
	test_failed($test_slogan) if not $lac;
	return "0" if not $lac;
	log_registry("Newly Selected lac value for location area is: $lac");
	my ($count,@LA) = select_mo_cs( MO => "LocationArea", ATTR => "lac", VAL => "$lac"); 
	log_registry("Newly Selected lac value already have master/proxy Location Area while for this Test Case we need a non existing LA ..") if $count;
	test_failed($test_slogan) if $count;
	return "0" if $count;
	my $cell = create_UtranCell($rnc);
	log_registry("Problem in creation of UtranCell...") if not $cell;
	test_failed($test_slogan) if not $cell;
	return "0" if not $cell;
	log_registry("Created Cell is: $cell");
	my %cell_attrs_bef = get_mo_attributes_CS(mo =>$cell,attributes => "lac sac rac locationAreaRef routingAreaRef serviceAreaRef");
	log_registry("===========================================================================");
	get_mo_attr("$cell","-o lac sac rac locationAreaRef routingAreaRef serviceAreaRef");
	log_registry("===========================================================================");
	my $la = "$rnc".",LocationArea=$mo_proxy_cms";
	my $la_attrs = "lac $lac userLabel $mo_proxy_cms";
	my $status = proxy_mo_create_decision("CSCLI",$la,$la_attrs,"no wait");
	log_registry("Problem in creation of proxy Location Area..") if not $status;
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
	my $sa = "$la".",ServiceArea=$mo_proxy_cms";
	my $sac = int(rand(65500));
	$sac = int(rand(65500)) if ($sac == $cell_attrs_bef{sac});
	my $sa_attrs = "sac $sac userLabel $mo_proxy_cms";
	$status = proxy_mo_create_decision("CSCLI",$sa,$sa_attrs,"no wait");
	log_registry("Problem in creation of proxy Service Area..") if not $status;
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
	my $ra = "$la".",RoutingArea=$mo_proxy_cms";
	my $rac = int(rand(250));
	$rac = int(rand(250)) if ($rac == $cell_attrs_bef{rac});
	my $ra_attrs = "rac $rac userLabel $mo_proxy_cms";
	$status = proxy_mo_create_decision("CSCLI",$ra,$ra_attrs,"no wait");
	log_registry("Problem in creation of proxy Routing Area..") if not $status;
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
	my $attrs,$cell2;
	$attrs = "lac $lac rac $rac sac $sac" if($tc_id != 2);
	if($tc_id == 3) {
        	$cell2 = create_UtranCell($rnc,"$attrs");
                log_registry("Problem in creation of UtranCell ..") if not $cell2;
                test_failed($test_slogan) if not $cell2;
                return "0" if not $cell2;  
		log_registry("==================================================================");
		get_mo_attr("$la","-o lac reservedBy");
		log_registry("==================================================================");
		get_mo_attr("$sa","-o sac reservedBy");
		log_registry("==================================================================");
		get_mo_attr("$ra","-o rac reservedBy");
		log_registry("==================================================================");  }
	$attrs = "locationAreaRef $la routingAreaRef $ra serviceAreaRef $sa" if($tc_id == 2);
	$status = proxy_mo_set_decision("CSCLI",$cell,$attrs);
	log_registry("Problem in setting attribute of UtranCell mo..") if not $status;
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
	my %cell_attrs_aft = get_mo_attributes_CS(mo =>$cell,attributes => "lac sac rac locationAreaRef routingAreaRef serviceAreaRef");
	log_registry("==================== After Setting lac/sac/rac of UtranCell ====================");
	get_mo_attr("$cell","-o lac sac rac locationAreaRef routingAreaRef serviceAreaRef");
	log_registry("================================================================================");
	my $flag = 0;
	$flag = 1 if not($cell_attrs_aft{lac} and $cell_attrs_aft{sac} and $cell_attrs_aft{rac} and $cell_attrs_aft{locationAreaRef} and $cell_attrs_aft{routingAreaRef} and $cell_attrs_aft{serviceAreaRef});
	$flag = 1 if ($cell_attrs_aft{routingAreaRef} !~ /$ra$/ and $cell_attrs_aft{serviceAreaRef} !~ /$sa$/ and $cell_attrs_aft{locationAreaRef} !~ /$la$/);
	$flag = 1 if ($cell_attrs_aft{rac} != $rac and $cell_attrs_aft{sac} != $sac and $cell_attrs_aft{lac} != $lac);
	log_registry("It seems either any of lac/rac/sac/locationAreaRef/routingAreaRef/serviceAreaRef attribute of UtranCell is Null or lac/sac/rac attributes value does not matching with new lac/sac/rac value or locationAreaRef/routingAreaRef/serviceAreaRef attribute values does not matching with the new LA/SA/RA created..") if $flag;
	test_failed($test_slogan) if $flag;
	my $master_la;
  	if(!$flag) {
		my $match_la = is_resby("$la","$cell");
		my $match_sa = is_resby("$sa","$cell");
		my $match_ra = is_resby("$ra","$cell");
		log_registry("================================================================================");
		get_mo_attr("$la","reservedBy");
		log_registry("================================================================================");
		get_mo_attr("$sa","reservedBy");
		log_registry("================================================================================");
		get_mo_attr("$ra","reservedBy");
		log_registry("================================================================================");
		$flag = 1 if not ($match_la and $match_sa and $match_ra);
		log_registry("It seems reservedBy attribute of LA/SA/RA is not matching with UtranCell ..") if $flag;
		$master_la = get_master_for_proxy($la);
		my $master_sa = get_master_for_proxy($sa);
		my $master_ra = get_master_for_proxy($ra);
		my $flag2 = 0; my $flag3 =0; my $flag4 = 0;my $flag5 = 0;
		$flag2 = 1 if not ($master_la and $master_sa and $master_ra);
		log_registry("It seems Master Mo has not been created for the proxy LA/SA/RA automatically ..") if $flag2;
		log_registry("Master for proxy LA/SA/RA are: \n $master_la \n $master_sa \n $master_ra") if not $flag2;
		my $state_la = get_proxy($la);
		my $state_sa = get_proxy($sa);
		my $state_ra = get_proxy($ra);
		$flag3 = 1 if ( $state_la != 1 or $state_sa != 1 or $state_ra != 1);
		log_registry("It seems proxy LA/SA/RA are not in consistent state ...") if $flag3;
		if(!$flag2) {
			$state_la = get_master($master_la);
			$state_sa = get_master($master_sa);
			$state_ra = get_master($master_ra);
			$flag4 = 1 if ( $state_la != 1 or $state_sa != 1 or $state_ra != 1);
			log_registry("It seems Master LA/SA/RA are not in consistent state ...") if $flag4; }
		$match_la = is_resby("$cell_attrs_bef{locationAreaRef}","$cell","no log entry");
		$match_sa = is_resby("$cell_attrs_bef{serviceAreaRef}","$cell","no log entry");
		$match_ra = is_resby("$cell_attrs_bef{routingAreaRef}","$cell","no log entry");
		$flag5 = 1 if ($match_la or $match_sa or $match_ra);
		log_registry("It seems old proxy LA/SA/RA still have reservedBy attribute set to UtranCell $cell") if $flag5;
		$flag = 1 if ($flag or $flag2 or $flag3 or $flag4 or $flag5);
		test_failed($test_slogan) if $flag;
		test_passed($test_slogan) if not $flag; }	
		
	#################################### Clean up#######################
        my $clean_issue;
	$master_la =~ s/\n+//g;
        my $mo = join(" ",$cell,$cell2,$master_la);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }

  }
  else
  {
	log_registry("It seems no synched RNC found...");
	test_failed($test_slogan);
  } 
}

sub FUT142 # 4.4.2.1.6, 4.4.2.1.7,4.4.2.1.8,4.4.2.1.2,4.4.2.1.3 and 4.4.2.1.4
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;	
  $tc_id = 1 if ($test_slogan =~ /4\.4\.2\.1\.6/);
  $tc_id = 3 if ($test_slogan =~ /4\.4\.2\.1\.7/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.2\.1\.8/);
  $tc_id = 4 if ($test_slogan =~ /4\.4\.2\.1\.2/);
  $tc_id = 6 if ($test_slogan =~ /4\.4\.2\.1\.3/);
  $tc_id = 5 if ($test_slogan =~ /4\.4\.2\.1\.4/);
  $tc_info = "WRANCM_CMSSnad_4.4.2.1.6 ; Set Master MO - Set UtranCell Master MO attribute lac to a new lac value with no reservedBy on proxy MO" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.2.1.7 ; Set Master MO - Set UtranCell Master MO attribute rac to a new rac value with no reservedBy on proxy MO" if ($tc_id == 3);
  $tc_info = "WRANCM_CMSSnad_4.4.2.1.8 ; Set Master MO - Set UtranCell Master MO attribute sac to a new sac value with no reservedBy on proxy MO" if ($tc_id == 2);
  $tc_info = "WRANCM_CMSSnad_4.4.2.1.2 ; Set Master MO - Set UtranCell Master MO attribute locationAreaRef" if ($tc_id == 4);
  $tc_info = "WRANCM_CMSSnad_4.4.2.1.3 ; Set Master MO - Set UtranCell Master MO attribute routingAreaRef" if ($tc_id == 6);
  $tc_info = "WRANCM_CMSSnad_4.4.2.1.4 ; Set Master MO - Set UtranCell Master MO attribute serviceAreaRef" if ($tc_id == 5);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne("RncFunction");
  if($rnc)
  {
	my @lac = PICK_NEW_LAS(1);
	my $lac = $lac[0];
	log_registry("No new lac value selected for location area..") if not $lac;
	test_failed($test_slogan) if not $lac;
	return "0" if not $lac;
	log_registry("Newly Selected lac value for location area is: $lac");
	my ($count,@LA) = select_mo_cs( MO => "LocationArea", ATTR => "lac", VAL => "$lac"); 
	log_registry("Newly Selected lac value already have master/proxy Location Area while for this Test Case we need a non existing LA ..") if $count;
	test_failed($test_slogan) if $count;
	return "0" if $count;
	my $cell = create_UtranCell($rnc);
	log_registry("Problem in creation of UtranCell...") if not $cell;
	test_failed($test_slogan) if not $cell;
	return "0" if not $cell;
	log_registry("Created Cell is: $cell");
	my %cell_attrs_bef = get_mo_attributes_CS(mo =>$cell,attributes => "lac sac rac locationAreaRef routingAreaRef serviceAreaRef");
	log_registry("===========================================================================");
	get_mo_attr("$cell","-o lac sac rac locationAreaRef routingAreaRef serviceAreaRef");
	log_registry("===========================================================================");
	my $la,,$sa,$ra,$sac,$rac,$status;
	if($tc_id == 1 or $tc_id == 4) {
		$la = "$rnc".",LocationArea=$mo_proxy_cms";
		my $la_attrs = "lac $lac userLabel $mo_proxy_cms";
		$status = proxy_mo_create_decision("CSCLI",$la,$la_attrs,"no wait");
		log_registry("Problem in creation of proxy Location Area..") if not $status;
		test_failed($test_slogan) if not $status;
		return "0" if not $status; 
		$sac = $cell_attrs_bef{sac};
		$rac = $cell_attrs_bef{rac};   }
	if($tc_id != 3 and $tc_id != 6 and $tc_id != 4) {
        	$sac = int(rand(65500)) if($tc_id == 2 or $tc_id == 5);
        	$sac = int(rand(65500)) if ($tc_id == 2 or $tc_id == 5 and $sac == $cell_attrs_bef{sac});
		$la = $cell_attrs_bef{locationAreaRef} if($tc_id == 2 or $tc_id == 5); $la =~ s/\n+//g;
		$ra = $cell_attrs_bef{routingAreaRef} if($tc_id == 2 or $tc_id == 5); $ra =~ s/\n+//g;
		$sa = "$la".",ServiceArea=$mo_proxy_cms";
		my $sa_attrs = "sac $sac userLabel $mo_proxy_cms";
		$status = proxy_mo_create_decision("CSCLI",$sa,$sa_attrs,"no wait");
		log_registry("Problem in creation of proxy Service Area..") if not $status;
		test_failed($test_slogan) if not $status;
		return "0" if not $status;  }
	if($tc_id != 2 and $tc_id != 5 and $tc_id != 4) {
        	$rac = int(rand(250)) if($tc_id == 3 or $tc_id == 6);
        	$rac = int(rand(250)) if ($tc_id == 3 or $tc_id == 6 and $rac == $cell_attrs_bef{rac}); 
		$la = $cell_attrs_bef{locationAreaRef} if($tc_id == 3 or $tc_id == 6); $la =~ s/\n+//g;
		$sa = $cell_attrs_bef{serviceAreaRef} if($tc_id == 3 or $tc_id == 6); $sa =~ s/\n+//g;
		$ra = "$la".",RoutingArea=$mo_proxy_cms"; 
		my $ra_attrs = "rac $rac userLabel $mo_proxy_cms";
		$status = proxy_mo_create_decision("CSCLI",$ra,$ra_attrs,"no wait");
		log_registry("Problem in creation of proxy Routing Area..") if not $status;
		test_failed($test_slogan) if not $status;
		return "0" if not $status;    }
	$ra = $cell_attrs_bef{routingAreaRef} if($tc_id == 4);
	$sa = $cell_attrs_bef{serviceAreaRef} if($tc_id == 4);
	my $attrs;
	$attrs = "lac $lac userLabel $mo_proxy_cms" if ($tc_id == 1);
	$attrs = "sac $sac userLabel $mo_proxy_cms" if ($tc_id == 2);
	$attrs = "rac $rac userLabel $mo_proxy_cms" if ($tc_id == 3);
        $attrs = "locationAreaRef $la userLabel $mo_proxy_cms" if ($tc_id == 4);
        $attrs = "serviceAreaRef $sa userLabel $mo_proxy_cms" if ($tc_id == 5);
        $attrs = "routingAreaRef $ra userLabel $mo_proxy_cms" if ($tc_id == 6);
	$status = proxy_mo_set_decision("CSCLI",$cell,$attrs);
	log_registry("Problem in setting attribute of UtranCell mo..") if not $status;
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
	my %cell_attrs_aft = get_mo_attributes_CS(mo =>$cell,attributes => "lac sac rac locationAreaRef routingAreaRef serviceAreaRef");
	log_registry("==================== After Setting lac/sac/rac of UtranCell ====================");
	get_mo_attr("$cell","-o lac sac rac locationAreaRef routingAreaRef serviceAreaRef");
	log_registry("================================================================================");
	my $flag = 0;
	$flag = 1 if not($cell_attrs_aft{lac} and $cell_attrs_aft{sac} and $cell_attrs_aft{rac} and $cell_attrs_aft{locationAreaRef} and $cell_attrs_aft{routingAreaRef} and $cell_attrs_aft{serviceAreaRef});
	$flag = 1 if ($tc_id == 1 and $cell_attrs_aft{routingAreaRef} !~ /$ra$/ and $cell_attrs_aft{serviceAreaRef} !~ /$sa$/ and $cell_attrs_aft{locationAreaRef} !~ /$la$/);
	$flag = 1 if ($tc_id == 2 and $cell_attrs_aft{serviceAreaRef} !~ /$sa$/);
	$flag = 1 if ($tc_id == 3 and $cell_attrs_aft{routingAreaRef} !~ /$ra$/);
	log_registry("It seems either any of lac/rac/sac/locationAreaRef/routingAreaRef/serviceAreaRef attribute of UtranCell is Null or locationAreaRef/routingAreaRef/serviceAreaRef attribute values does not matching with the new LA/SA/RA created..") if $flag;
        $flag = 1 if ($tc_id == 4 and $cell_attrs_aft{lac} ne $lac);
        $flag = 1 if ($tc_id == 5 and $cell_attrs_aft{sac} ne $sac);
        $flag = 1 if ($tc_id == 6 and $cell_attrs_aft{rac} ne $rac);
        log_registry("It seems either any of lac/rac/sac/locationAreaRef/routingAreaRef/serviceAreaRef attribute of UtranCell is Null or lac/sac/rac attribute values does not matching with the new lac/sac/rac value") if $flag;
	test_failed($test_slogan) if $flag;
	my $master_la,$master_sa,$master_ra;
  	if(!$flag) {
		my $match_la = is_resby("$la","$cell");
		my $match_sa = is_resby("$sa","$cell");
		my $match_ra = is_resby("$ra","$cell");
		log_registry("================================================================================");
		get_mo_attr("$la","reservedBy") if($tc_id == 1 or $tc_id == 4);
		get_mo_attr("$sa","reservedBy") if($tc_id != 3 and $tc_id != 4 and $tc_id != 6);
		get_mo_attr("$ra","reservedBy") if($tc_id != 2 and $tc_id != 4 and $tc_id != 5);
		log_registry("================================================================================");
		$flag = 1 if not ($match_la and $match_sa and $match_ra);
		log_registry("It seems reservedBy attribute of LA/SA/RA is not matching with UtranCell ..") if $flag;
		$master_la = get_master_for_proxy($la);
		$master_sa = get_master_for_proxy($sa);
		$master_ra = get_master_for_proxy($ra);
		my $flag2 = 0; my $flag3 =0; my $flag4 = 0;my $flag5 = 0;
		$flag2 = 1 if not ($master_la and $master_sa and $master_ra);
		log_registry("It seems Master Mo has not been created for the proxy LA/SA/RA automatically ..") if $flag2;
		log_registry("Master for proxy LA/SA/RA are: \n $master_la \n $master_sa \n $master_ra") if not $flag2;
		my $state_la = get_proxy($la);
		my $state_sa = get_proxy($sa);
		my $state_ra = get_proxy($ra);
		$flag3 = 1 if ( $state_la != 1 or $state_sa != 1 or $state_ra != 1);
		log_registry("It seems proxy LA/SA/RA are not in consistent state ...") if $flag3;
		if(!$flag2) {
			$state_la = get_master($master_la);
			$state_sa = get_master($master_sa);
			$state_ra = get_master($master_ra);
			$flag4 = 1 if ( $state_la != 1 or $state_sa != 1 or $state_ra != 1);
			log_registry("It seems Master LA/SA/RA are not in consistent state ...") if $flag4; }
		$match_la = 0; $match_sa = 0; $match_ra = 0;
		$match_la = is_resby("$cell_attrs_bef{locationAreaRef}","$cell","no log entry")if($tc_id == 1 or $tc_id ==4);
		$match_sa = is_resby("$cell_attrs_bef{serviceAreaRef}","$cell","no log entry")if($tc_id != 3 and $tc_id != 6 and $tc_id != 4);
		$match_ra = is_resby("$cell_attrs_bef{routingAreaRef}","$cell","no log entry")if($tc_id != 2 and $tc_id != 5 and $tc_id != 4);
		$flag5 = 1 if ($match_la or $match_sa or $match_ra);
		log_registry("It seems old proxy LA/SA/RA still have reservedBy attribute set to UtranCell $cell") if $flag5;
		$flag = 1 if ($flag or $flag2 or $flag3 or $flag4 or $flag5);
		test_failed($test_slogan) if $flag;
		test_passed($test_slogan) if not $flag; }
		
	#################################### Clean up#######################
        my $clean_issue,$mo;
	$master_la =~ s/\n+//g;
        $mo = join(" ",$cell,$master_la) if ($tc_id == 1 or $tc_id == 4);
        $mo = join(" ",$cell,$master_sa) if ($tc_id == 2 or $tc_id == 5);
        $mo = join(" ",$cell,$master_ra) if ($tc_id == 3 or $tc_id == 6);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
  }
  else
  {
	log_registry("It seems no synched RNC found...");
	test_failed($test_slogan);
  } 
}

sub FUT143 # 4.4.2.1.9, 4.4.2.1.10,4.4.2.1.11
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;	
  $tc_id = 1 if ($test_slogan =~ /4\.4\.2\.1\.9/);
  $tc_id = 3 if ($test_slogan =~ /4\.4\.2\.1\.10/);
  $tc_id = 2 if ($test_slogan =~ /4\.4\.2\.1\.11/);
  $tc_info = "WRANCM_CMSSnad_4.4.2.1.9 ; Set Master MO - Set UtranCell Master MO attribute lac to a new lac value with a reservedBy on proxy MO" if ($tc_id == 1);
  $tc_info = "WRANCM_CMSSnad_4.4.2.1.10 ; Set Master MO - Set UtranCell Master MO attribute rac to a new rac value with a reservedBy on proxy MO" if ($tc_id == 3);
  $tc_info = "WRANCM_CMSSnad_4.4.2.1.11 ; Set Master MO - Set UtranCell Master MO attribute sac to a new sac value with a reservedBy on proxy MO" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $rnc = pick_a_ne("RncFunction");
  if($rnc)
  {
	my($count,@LA) = get_CMS_mo("LocationArea","$rnc");
	log_registry("It seems selected RNC does not have two or more LocationArea under it .. $rnc") if (!($count) or $count < 2);
	test_failed($test_slogan) if (!($count) or $count < 2);
	return "0" if (!($count) or $count < 2);
	my $cell = create_UtranCell($rnc);
	log_registry("Problem in creation of UtranCell...") if not $cell;
	test_failed($test_slogan) if not $cell;
	return "0" if not $cell;
	log_registry("Created Cell is: $cell");
	my %cell_attrs_bef = get_mo_attributes_CS(mo =>$cell,attributes => "lac sac rac locationAreaRef routingAreaRef serviceAreaRef");
	log_registry("===========================================================================");
	get_mo_attr("$cell","-o lac sac rac locationAreaRef routingAreaRef serviceAreaRef");
	log_registry("===========================================================================");
	my $la,$sa,$ra,$lac,$sac,$rac,$status,$clean_flag,$cell2;
	my $oldLA = $cell_attrs_bef{locationAreaRef}; $oldLA =~ s/\n+//g;
	my $oldSA = $cell_attrs_bef{serviceAreaRef}; $oldSA =~ s/\n+//g;
	my $oldRA = $cell_attrs_bef{routingAreaRef}; $oldRA =~ s/\n+//g;
	if($tc_id == 1) {
		my $newLA,$sa_attrs,$ra_attrs;
		foreach(@LA) {
			$newLA = $_ if($_ !~ /$oldLA$/);
			last if $newLA; }
		$newLA =~ s/\n+//g;
		log_registry("New selected Location Area is: $newLA");
		my %la_attrs = get_mo_attributes_CS(mo => $newLA,attributes => "lac reservedBy");
		log_registry("It seems selected LA: $newLA does not reservedBy with any previous UtranCell") if (!($la_attrs{reservedBy}) or $la_attrs{reservedBy} !~ /UtranCell/);
		test_failed($test_slogan) if (!($la_attrs{reservedBy}) or $la_attrs{reservedBy} !~ /UtranCell/);
		return "0" if (!($la_attrs{reservedBy}) or $la_attrs{reservedBy} !~ /UtranCell/);
		$la = $newLA;
		$lac = $la_attrs{lac};
		$sac = $cell_attrs_bef{sac};
		$rac = $cell_attrs_bef{rac};
		my($count,@SA) = select_mo_cs(MO => "ServiceArea", ATTR => "sac", VAL => "$sac", KEY => "$newLA");
		log_registry("Selected Location Area does not have ServiceArea of sac value $sac, so creating the same") if not $count;
		$sa = $SA[0] if $count;
		$clean_flag = 1 if not $count;
                $sa = "$la".",ServiceArea=$mo_proxy_cms" if not $count;
                $sa_attrs = "sac $sac userLabel $mo_proxy_cms" if not $count;
                $status = proxy_mo_create_decision("CSCLI",$sa,$sa_attrs,"no wait") if not $count; $status = 1 if $count;
                log_registry("Problem in creation of proxy Service Area..") if not ($count or $status);
                test_failed($test_slogan) if not ($count or $status);
                return "0" if not ($count or $status);
		log_registry("ServiceArea corresponding to LocationArea is: $sa");
		my($count_ra,@RA) = select_mo_cs(MO => "RoutingArea", ATTR => "rac", VAL => "$rac", KEY => "$newLA");
		log_registry("Selected Location Area does not have RoutingArea of rac value $rac, so creating the same") if not $count_ra;
		$ra = $RA[0] if $count_ra;
		$clean_flag = 1 if not $count_ra;
                $ra = "$la".",RoutingArea=$mo_proxy_cms" if not $count_ra;
                $ra_attrs = "rac $rac userLabel $mo_proxy_cms" if not $count_ra;
                $status = proxy_mo_create_decision("CSCLI",$ra,$ra_attrs,"no wait")if not $count_ra;$status = 1 if $count_ra;
                log_registry("Problem in creation of proxy Routing Area..") if not ($count_ra or $status);
                test_failed($test_slogan) if not ($count_ra or $status);
                return "0" if not ($count_ra or $status);
		log_registry("RotingArea corresponding to LocationArea is: $ra"); }
	if($tc_id == 2) {
		$la = $oldLA;
		$ra = $oldRA;	
		$rac = $cell_attrs_bef{rac};
		$lac = $cell_attrs_bef{lac};
		my($count,@SA) = get_CMS_mo("ServiceArea","$la");
		foreach(@SA) {
			$sa = $_ if($_ !~ /$oldSA$/);
			last if $sa; }
		log_registry("It seems no other ServiceArea Found under LocationArea $la") if not $sa;
		if(!($sa))  {
			$clean_flag = 1;
			$sac = int(rand(65530));
			$sac = int(rand(65530)) if($sac == $cell_attrs_bef{sac});
			$sa = "$la".",ServiceArea=$mo_proxy_cms"; 
			my $sa_attrs = "sac $sac userLabel $mo_proxy_cms";
			$status = proxy_mo_create_decision("CSCLI",$sa,$sa_attrs,"no wait");
			log_registry("Problem in creation of proxy Service Area..") if not $status;
			test_failed($test_slogan) if not $status;
			return "0" if not $status;
			$cell2 = create_UtranCell($rnc,"lac $lac sac $sac rac $rac");
			log_registry("Problem in creation of UtranCell ..") if not $cell2;
			test_failed($test_slogan) if not $cell2;
			return "0" if not $cell2;
			get_mo_attr("$sa","-o sac reservedBy");  } $sa =~ s/\n+//g;
		log_registry("Selected ServiceArea : $sa");
		my %sa_attrs = get_mo_attributes_CS(mo => $sa,attributes => "sac reservedBy");
		log_registry("It seems selected SA: $sa does not reservedBy with any previous UtranCell") if (!($sa_attrs{reservedBy}) or $sa_attrs{reservedBy} !~ /UtranCell/);
		test_failed($test_slogan) if (!($sa_attrs{reservedBy}) or $sa_attrs{reservedBy} !~ /UtranCell/);
		return "0" if (!($sa_attrs{reservedBy}) or $sa_attrs{reservedBy} !~ /UtranCell/);
		$sac = $sa_attrs{sac};	}
	if($tc_id == 3) {
		$la = $oldLA;
		$sa = $oldSA;	
		$sac = $cell_attrs_bef{sac};
		$lac = $cell_attrs_bef{lac};
		my($count,@RA) = get_CMS_mo("RoutingArea","$la");
		foreach(@RA) {
			$ra = $_ if($_ !~ /$oldRA$/);
			last if $ra; }
		log_registry("It seems no other RoutingArea Found under LocationArea $la,so creating one with reservedBy set to one other UtranCell") if not $ra;
		if(!($ra))  {
			$clean_flag = 1;
			$rac = int(rand(250));
			$rac = int(rand(250)) if($rac == $cell_attrs_bef{rac});
			$ra = "$la".",RoutingArea=$mo_proxy_cms"; 
			my $ra_attrs = "rac $rac userLabel $mo_proxy_cms";
			$status = proxy_mo_create_decision("CSCLI",$ra,$ra_attrs,"no wait");
			log_registry("Problem in creation of proxy Routing Area..") if not $status;
			test_failed($test_slogan) if not $status;
			return "0" if not $status;
			$cell2 = create_UtranCell($rnc,"lac $lac sac $sac rac $rac");
			log_registry("Problem in creation of UtranCell ..") if not $cell2;
			test_failed($test_slogan) if not $cell2;
			return "0" if not $cell2;
			get_mo_attr("$ra","-o rac reservedBy");  } $ra =~ s/\n+//g;
		log_registry("Selected RoutingArea : $ra");
		my %ra_attrs = get_mo_attributes_CS(mo => $ra,attributes => "rac reservedBy");
		log_registry("It seems selected RA: $ra does not reservedBy with any previous UtranCell") if (!($ra_attrs{reservedBy}) or $ra_attrs{reservedBy} !~ /UtranCell/);
		test_failed($test_slogan) if (!($ra_attrs{reservedBy}) or $ra_attrs{reservedBy} !~ /UtranCell/);
		return "0" if (!($ra_attrs{reservedBy}) or $ra_attrs{reservedBy} !~ /UtranCell/);
		$rac = $ra_attrs{rac};	}
	my $attrs;
	$attrs = "lac $lac userLabel $mo_proxy_cms" if ($tc_id == 1);
	$attrs = "sac $sac userLabel $mo_proxy_cms" if ($tc_id == 2);
	$attrs = "rac $rac userLabel $mo_proxy_cms" if ($tc_id == 3);
	$status = proxy_mo_set_decision("CSCLI",$cell,$attrs);
	log_registry("Problem in setting attribute of UtranCell mo..") if not $status;
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
	my %cell_attrs_aft = get_mo_attributes_CS(mo =>$cell,attributes => "lac sac rac locationAreaRef routingAreaRef serviceAreaRef");
	log_registry("==================== After Setting lac/sac/rac of UtranCell ====================");
	get_mo_attr("$cell","-o lac sac rac locationAreaRef routingAreaRef serviceAreaRef");
	log_registry("================================================================================");
	my $flag = 0;
	$flag = 1 if not($cell_attrs_aft{lac} and $cell_attrs_aft{sac} and $cell_attrs_aft{rac} and $cell_attrs_aft{locationAreaRef} and $cell_attrs_aft{routingAreaRef} and $cell_attrs_aft{serviceAreaRef});
	$flag = 1 if ($tc_id == 1 and $cell_attrs_aft{routingAreaRef} !~ /$ra$/ and $cell_attrs_aft{serviceAreaRef} !~ /$sa$/ and $cell_attrs_aft{locationAreaRef} !~ /$la$/);
	$flag = 1 if ($tc_id == 2 and $cell_attrs_aft{serviceAreaRef} !~ /$sa$/);
	$flag = 1 if ($tc_id == 3 and $cell_attrs_aft{routingAreaRef} !~ /$ra$/);
	log_registry("It seems either any of lac/rac/sac/locationAreaRef/routingAreaRef/serviceAreaRef attribute of UtranCell is Null or locationAreaRef/routingAreaRef/serviceAreaRef attribute values does not matching with the new LA/SA/RA created..") if $flag;
	test_failed($test_slogan) if $flag;
	my $master_la,$master_sa,$master_ra;
  	if(!$flag) {
		my $match_la = is_resby("$la","$cell");
		my $match_sa = is_resby("$sa","$cell");
		my $match_ra = is_resby("$ra","$cell");
		$flag = 1 if not ($match_la and $match_sa and $match_ra);
		log_registry("It seems reservedBy attribute of LA/SA/RA is not matching with UtranCell ..") if $flag;
		$master_la = get_master_for_proxy($la);
		$master_sa = get_master_for_proxy($sa);
		$master_ra = get_master_for_proxy($ra);
		my $flag2 = 0; my $flag3 =0; my $flag4 = 0;my $flag5 = 0;
		$flag2 = 1 if not ($master_la and $master_sa and $master_ra);
		log_registry("It seems Master Mo has not been created for the proxy LA/SA/RA automatically ..") if $flag2;
		log_registry("Master for proxy LA/SA/RA are: \n $master_la \n $master_sa \n $master_ra") if not $flag2;
		my $state_la = get_proxy($la);
		my $state_sa = get_proxy($sa);
		my $state_ra = get_proxy($ra);
		$flag3 = 1 if ( $state_la != 1 or $state_sa != 1 or $state_ra != 1);
		log_registry("It seems proxy LA/SA/RA are not in consistent state ...") if $flag3;
		if(!$flag2) {
			$state_la = get_master($master_la);
			$state_sa = get_master($master_sa);
			$state_ra = get_master($master_ra);
			$flag4 = 1 if ( $state_la != 1 or $state_sa != 1 or $state_ra != 1);
			log_registry("It seems Master LA/SA/RA are not in consistent state ...") if $flag4; }
		$match_la = 0; $match_sa = 0; $match_ra = 0;
		$match_la = is_resby("$cell_attrs_bef{locationAreaRef}","$cell","no log entry")if($tc_id == 1);
		$match_sa = is_resby("$cell_attrs_bef{serviceAreaRef}","$cell","no log entry")if($tc_id != 3);
		$match_ra = is_resby("$cell_attrs_bef{routingAreaRef}","$cell","no log entry")if($tc_id != 2);
		$flag5 = 1 if ($match_la or $match_sa or $match_ra);
		log_registry("It seems old proxy LA/SA/RA still have reservedBy attribute set to UtranCell $cell") if $flag5;
		$flag = 1 if ($flag or $flag2 or $flag3 or $flag4 or $flag5);
		test_failed($test_slogan) if $flag;
		test_passed($test_slogan) if not $flag; }	
	#################################### Clean up#######################
        my $clean_issue,$mo;
	$master_la =~ s/\n+//g;
        $mo = join(" ",$cell,$master_sa,$master_ra) if ($tc_id == 1 and $clean_flag);
        $mo = join(" ",$cell,$cell2,$master_sa) if ($tc_id == 2 and $clean_flag);
        $mo = join(" ",$cell,$cell2,$master_ra) if ($tc_id == 3 and $clean_flag);
	$mo = $cell if not $clean_flag;
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
  }
  else
  {
	log_registry("It seems no synched RNC found...");
	test_failed($test_slogan);
  } 
}


sub FUT144  #4.3.1.4.44
{
  my $test_slogan = $_[0];
  my $tc_info,$tc_id;
  $tc_info = "WRANCM_CMSSnad_4.3.1.4.44 ; Create   - Create ExternalGsmCell with BandIndicator value different to ExternalGsmFreq from an application";
  $test_slogan = "$test_slogan"."-"."$tc_info";
  log_registry("$tc_info");
  my $ERBS = pick_a_erbs_using_cell(CELL => "EUtranCellFDD",VER => "NEW");
  if($ERBS)
  {
	log_registry("Selected ERBS for TC is: \n $ERBS");
	my $EUCFDD = pick_a_mo($ERBS,EUtranCellFDD);
	log_registry("It seems EUtranCellFDD not found under corresponding ERBS..")if not $EUCFDD;
	test_failed($test_slogan) if not $EUCFDD;
	return "0" if not $EUCFDD;
	log_registry("Selected cell for TC is: \n $EUCFDD");
	my ($EGP_count,@EGP) = get_CMS_mo("ExternalGsmPlmn");
	log_registry("It seems no pre-existing ExternalGsmPlmn MO exist") if not $EGP_count;
	test_failed($test_slogan) if not $EGP_count;
	return "0" if not $EGP_count;
	my ($EGFG,$attr_EGFG) = get_fdn("ExternalGsmFreqGroup","create");
        my $result = mo_create_decision("0",$EGFG,$attr_EGFG);
	$result = master_for_proxy_handle("0",$EGFG,$attr_EGFG) if($result and $result eq "KO");
        log_registry("Problem in creation of master ExternalGsmFreqGroup MO ..") if not $result;
        test_failed($test_slogan) if not $result;
        return "0" if not $result;
	my $EGP = $EGP[int(rand($#EGP))];
	my %EGP_attrs = get_mo_attributes_CS(mo =>$EGP, attributes => "mnc mcc mncLength");
	my ($EGC,$attr_EGC) = get_fdn("MasterExternalGsmCell","create");
	$attr_EGC =~ s/cellIdentity.*$//g;
	my $attr_EGC1 = "$attr_EGC"." "."mnc $EGP_attrs{mnc}"." "."mcc $EGP_attrs{mcc}"." "."mncLength $EGP_attrs{mncLength}"." "."parentSystem $EGP"." "."bandIndicator 0 cellIdentity 65512";
	my $attr_EGC2 = "$attr_EGC"." "."mnc $EGP_attrs{mnc}"." "."mcc $EGP_attrs{mcc}"." "."mncLength $EGP_attrs{mncLength}"." "."parentSystem $EGP"." "."bandIndicator 1 cellIdentity 65513";
	my $attr_EGC3 = "$attr_EGC"." "."mnc $EGP_attrs{mnc}"." "."mcc $EGP_attrs{mcc}"." "."mncLength $EGP_attrs{mncLength}"." "."parentSystem $EGP"." "."bandIndicator 2 cellIdentity 65514";
	$attr_EGC1 =~ s/\n+//g; $attr_EGC2 =~ s/\n+//g; $attr_EGC3 =~ s/\n+//g;
	my $EGC1 = "$EGC"."1"; my $EGC2 = "$EGC"."2"; my $EGC3 = "$EGC"."3";
	$result = mo_create_decision("0",$EGC1,$attr_EGC1);
	$result = mo_create_decision("0",$EGC2,$attr_EGC2);
	$result = mo_create_decision("0",$EGC3,$attr_EGC3);
	$result = master_for_proxy_handle("0",$EGC,$attr_EGC1) if($result and $result eq "KO");
	log_registry("Problem in creation of master ExternalGsmCell MO ..") if not $result;
	test_failed($test_slogan) if not $result;
	return "0" if not $result;
	my ($GFGR1,$GeFG1) = create_GeranFreqGroupRelation(EUCXDD => $EUCFDD, EGFG => $EGFG);
	log_registry("It seems there is a problem in creation of GeranFreqGroupRelation ..") if not $GFGR1;
	test_failed($test_slogan) if not $GFGR1;
	return "0" if not $GFGR1;
	my ($GeF,$attr_GeF) = get_fdn("PGeranFrequency","create");
	my $GeF1 = base_fdn_modify("$GeFG1","$GeF");
	my ($status,$rev_id) = proxy_mo_create_decision("CSCLI",$GeF1,$attr_GeF,"no wait");
	log_registry("Problem in creation of proxy GeranFrequency mo...") if not $status;
	test_failed($test_slogan) if not $status;
	return "0" if not $status;
        my ($GCR1,$EGeC1) = create_GeranCellRelation( GFGR => $GFGR1 , MEGC => $EGC1,base => "CSCLI" );
        log_registry("There is a problem in creation of GeranCellRelation ...") if not $GCR1;
        test_failed($test_slogan) if not $GCR1;
	return "0" if not $GCR1;
        my ($GCR2,$EGeC2) = create_GeranCellRelation( GFGR => $GFGR1 , MEGC => $EGC2,base => "CSCLI" );
        log_registry("There is a problem in creation of GeranCellRelation ...") if not $GCR2;
        test_failed($test_slogan) if not $GCR2;
	return "0" if not $GCR2;
        my ($GCR3,$EGeC3) = create_GeranCellRelation( GFGR => $GFGR1 , MEGC => $EGC3,base => "CSCLI" );
        log_registry("There is a problem in creation of GeranCellRelation ...") if not $GCR3;
        test_failed($test_slogan) if not $GCR3;
	return "0" if not $GCR3;
        log_registry("====================================================================================");
        get_mo_attr($EGeC1,"reservedBy");
        log_registry("====================================================================================");
        get_mo_attr($EGeC2,"reservedBy");
        log_registry("====================================================================================");
        get_mo_attr($EGeC3,"reservedBy");
        log_registry("====================================================================================");
	my $stat1 = get_master($EGC1);	
	my $stat2 = get_master($EGC2);	
	my $stat3 = get_master($EGC3);	
	my $flag = 0;my $flag2 = 0;
	$flag = 1 if ($stat1 != 1 or $stat2 != 1 or $stat3 != 1);
	log_registry("It seems any of Master ExternalGsmCell is not consistent...")if $flag;
	$stat1 = get_proxy($EGeC1);
	$stat2 = get_proxy($EGeC2);
	$stat3 = get_proxy($EGeC3);
	$flag2 = 1 if ($stat1 != 1 or $stat2 == 1 or $stat3 == 1);
	log_registry("It is expected Proxy $EGeC1 should be consistent while proxy $EGeC2 and $EGeC3 should be in Inconsistent state..");
	log_registry("It seems are not in desired state") if $flag2;
	test_failed("$test_slogan") if ($flag2 or $flag);
        test_passed($test_slogan) if not ($flag or $flag2);
################################################# Clean Up ################################################################
        my $clean_issue,$mo;
	my %EGFG_attrs = get_mo_attributes_CS(mo =>$EGFG, attributes => "reservedBy");
        $mo = join(" ",$GCR1,$GCR2,$GCR3,$GFGR1,$EGeC1,$EGeC2,$EGeC3,$GeF1,$GeFG1,$EGFG_attrs{reservedBy},$EGFG,$EGC);
        my @mo = split(" ",$mo);
        foreach(@mo) {
                log_registry("Clean up: Deleting MO $_ ");
                $clean_issue = delete_mo_CS( mo => $_);
                log_registry("Warning => Problem in deletion of MO ...") if $clean_issue; }
  }
  else
  {
                log_registry("It seems no synched ERBS found of version vB.1.20 or later having EUtranCellFDD under it");
                test_failed($test_slogan);
  }
}

# added by eeitjn to fromat the return from the get_Proxies_Master function 

sub format_proxies
{
  my $proxies = $_[0] ;
  my @EE = split("\n",$proxies);
  my $count_FDN = scalar @EE;
  foreach(@EE) 
        	{
        	$_ =~ s/.//;
		$_ =~ s/\]//g;
  		}
  return ($count_FDN,@EE);	
}


1;
