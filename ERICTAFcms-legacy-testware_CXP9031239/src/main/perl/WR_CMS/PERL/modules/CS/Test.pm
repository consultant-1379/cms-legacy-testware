package CS::Test;

require 5.005_62;
use strict;
use warnings;
#use lib "/net/atrnjump/share/guitest/perl/lib/perl5/site_perl/5.8.6";
use XML::Twig;
use Log::Log4perl qw(get_logger :levels);

Log::Log4perl->init("/opt/ericsson/atoss/tas/WR_CMS/PERL/modules/Log/log4perl.conf");

my $logger = get_logger();

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use CS::Test ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw(   ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
   activate_plan
   attrs_to_get_are_OK
   attrs_to_set_are_OK
   create_mo_CS
   create_plan
   delete_mo_CS
   delete_plan
   does_mo_exist_CS
   does_plan_exist
   get_class_attributes_CS
   get_mo_attributes_CS
   get_mo_children_CS
   get_mo_list_for_class_CS
   mo_name_is_OK
   set_mo_attributes_CS
   %result_code_CS
   %result_string_CS
);

our $VERSION = '0.01';


my @results = qw( OK
                  MO_NAME_INVALID
                  ATTRIBUTES_INVALID
                  PLAN_NAME_INVALID
                  SERVER_NAME_INVALID
                  MO_ALREADY_EXISTS
                  MO_DOESNT_EXIST
                  MIM_VERSION_INVALID
                  PLAN_ALREADY_EXISTS
                  PLAN_DOESNT_EXIST
                  MIM_FILE_NOT_FOUND
                  ATTRIBUTE_IS_RESTRICTED
                  CS_ERROR
                  UNKNOWN_ERROR
		  NO_CHILD
                );
                     
our %result_code_CS   = map {$results[$_], $_} 0..$#results;
our %result_string_CS = reverse %result_code_CS;


# Preloaded methods go here.

# Use Sys::Hostname module to get the hostname of the machine that the script is running on
use Sys::Hostname;

my $seg_cs = segment_cs_id();
my $cstest = find_cstest();


#
# Get the attributes from CS for the MO instance given
#
# Arguments:
#   mo         : MO instance (FDN)              [mandatory]
#   attributes : space separated list of words
#   server     : boolean - Region or Segment
#   plan       : plan name
#
# Output:
#   hash containing the name and value of any attributes found, in the format
#   $mo_hash{attr} = value
#
eval
{
   sub get_mo_attributes_CS
   {
      my %param = ( server     => "Segment",    # values here are the defaults
                    plan       => "",
                    attributes => "",
                    @_
                  );

      my $mo_fdn     = mo_name_is_OK($param{mo}, qr/SubNetwork=\S+/) or return;
      my $attributes = attrs_to_get_are_OK($param{attributes}) or return;
      my $plan       = plan_is_OK($param{plan}) or return;
      my $cs_server  = get_cs_server($param{server}) or return;

	
      if (get_mo_data("$cstest $plan -s $cs_server e $mo_fdn")) # check if MO exists
      {
         $logger->error("MO name $mo_fdn doesn't exist\n");
         return;
      }

      my $mo_data    = get_mo_data("$cstest $plan -s $cs_server lm $mo_fdn -l 0 $attributes") or return;

      return extract_mo_data($mo_data, $param{attributes}, "instance");
   }
};

if ($@)
{
   $logger->error("CS::Test is unable to get MO attributes.\n Error is: $!\n");
}



#
# Get the attributes from CS for the MO class given
#
# Arguments:
#   mo         : MO class                       [mandatory]
#   attributes : space separated list of words
#   server     : boolean - Region or Segment
#   plan       : plan name
#
# Output:
#   hash containing the name and value of any attributes found, in the format
#   $mo_hash{fdn}{attr} = value
#
eval
{
   sub get_class_attributes_CS
   {
      my %param = ( server     => "Segment",    # values here are the defaults
                    plan       => "",
                    attributes => "",
                    @_
                  );

      my $mo_class   = mo_name_is_OK($param{mo}, qr/\w+/) or return;

      my $attributes = attrs_to_get_are_OK($param{attributes}) or return;

      my $plan       = plan_is_OK($param{plan}) or return;

      my $cs_server  = get_cs_server($param{server}) or return;


      my $mo_data    = get_mo_data("$cstest $plan -s $cs_server lt $mo_class $attributes") or return;

      return extract_mo_data($mo_data, $param{attributes}, "class");
   }
};

if ($@)
{
   $logger->error("CS::Test is unable to get MO class attributes.\n Error is: $!\n");
}


#
# Set the attributes in CS for the MO instance given
#
# Arguments:
#   mo         : MO instance                                  [mandatory]
#   attributes : space separated list of (name value) words   [mandatory]
#   server     : boolean - Region or Segment
#   plan       : plan name
#
# Output:
#   result     : return $result_code_CS{OK} if OK, or some other result_code_CS if a problem occurred
#

eval
{
   sub set_mo_attributes_CS
   {
      my %param = ( server     => "Segment",    # values here are the defaults
                    plan       => "",
                    @_
                  );

      my $mo_fdn     = mo_name_is_OK($param{mo}, qr/SubNetwork=\S+/) or return $result_code_CS{MO_NAME_INVALID};
      my $attributes = attrs_to_set_are_OK($param{attributes}) or return $result_code_CS{ATTRIBUTES_INVALID};
      my $plan       = plan_is_OK($param{plan}) or return $result_code_CS{PLAN_DOESNT_EXIST};
      my $cs_server  = get_cs_server($param{server}) or return $result_code_CS{SERVER_NAME_INVALID};

      if (get_mo_data("$cstest $plan -s $cs_server e $mo_fdn")) # check if MO exists
      {
         $logger->error("MO name $mo_fdn doesn't exist\n");
         return $result_code_CS{MO_DOESNT_EXIST};
      }
      if (my $result = `$cstest $plan -s $cs_server sa $mo_fdn $attributes`)
      {
         $logger->error("Error setting attributes\n From CS got: $result\n");
         return $result_code_CS{ATTRIBUTE_IS_RESTRICTED} if $result =~ m/The attribute is restricted/ or $result =~ m/AttributeNotSettable/ ;
         return $result_code_CS{CS_ERROR};
      }
      else
      {
         $logger->info("Attributes set OK\n");
         return $result_code_CS{OK};
      }
   }
};

if ($@)
{
   $logger->error("CS::Test is unable to set attributes.\n Error is: $!\n");
}


#
# Get the list of MO instances from CS for the MO class given
#
# Arguments:
#   mo         : MO class              [mandatory]
#   server     : boolean - Region or Segment
#   plan       : plan name
#
# Output:
#   array containing the name of any MOs found
#
eval
{
   sub get_mo_list_for_class_CS
   {
      my %param = ( server     => "Segment",    # values here are the defaults
                    plan       => "",
                    @_
                  );

      my ($mo_class) = $param{mo} =~ m/\b(\w+)\b/ or return;

      my $plan       = plan_is_OK($param{plan}) or return;

      my $cs_server  = get_cs_server($param{server}) or return;
      
      my $mo_list    = get_mo_data("$cstest $plan -s $cs_server lt $mo_class  | grep -v SGSN") or return;

      return split /\n/, $mo_list;
   }
};

if ($@)
{
   $logger->error("CS::Test is unable to get MO list for class.\n Error is: $!\n");
}



#
# Check if the given MO name exists in the CS
#
#   mo         : MO instance                                  [mandatory]
#   server     : boolean - Region or Segment
#   plan       : plan name
#
# Output:
#   result     : result_code_CS{MO_ALREADY_EXISTS} or result_code_CS{MO_DOESNT_EXIST}, or another result_code_CS value if a problem occurred
#
eval
{
   sub does_mo_exist_CS
   {
      my %param = ( server     => "Segment",    # values here are the defaults
                    plan       => "",
                    @_
                  );
      my $mo_fdn     = mo_name_is_OK($param{mo}, qr/SubNetwork=\S+/) or return $result_code_CS{MO_NAME_INVALID};
      my $plan       = plan_is_OK($param{plan}) or return $result_code_CS{PLAN_DOESNT_EXIST};
      my $cs_server  = get_cs_server($param{server}) or return $result_code_CS{SERVER_NAME_INVALID};

      if (get_mo_data("$cstest $plan -s $cs_server e $mo_fdn")) # check if MO exists
      {
         $logger->info("MO $mo_fdn doesn't exist\n");
         return $result_code_CS{MO_DOESNT_EXIST};
      }

      $logger->info("MO $mo_fdn exists\n");
      return $result_code_CS{MO_ALREADY_EXISTS};
   }
};

if ($@)
{
   $logger->error("CS::Test is unable to get MO existence information.\n Error is: $!\n");
}


#
# Get the children from CS for the MO instance given
#
# Arguments:
#   mo         : MO instance (FDN)              [mandatory]
#   server     : boolean - Region or Segment
#   plan       : plan name
#
# Output:
#   result code
#   array containing the name of any children found
#
eval
{
   sub get_mo_children_CS
   {
      my %param = ( server     => "Segment",    # values here are the defaults
                    plan       => "",
                    @_
                  );

      my $mo_fdn     = mo_name_is_OK($param{mo}, qr/SubNetwork=\S+/) or return;
      my $plan       = plan_is_OK($param{plan}) or return;
      my $cs_server  = get_cs_server($param{server}) or return;

      if (get_mo_data("$cstest $plan -s $cs_server e $mo_fdn")) # check if MO exists
      {
         $logger->error("MO name $mo_fdn doesn't exist\n");
         return $result_code_CS{MO_DOESNT_EXIST};
      }

      my $children = get_mo_data("$cstest $plan -s $cs_server lm $mo_fdn") or return $result_code_CS{CS_ERROR};
      my @children = split /\s+/, $children;
      shift(@children);
      return $result_code_CS{NO_CHILD} unless @children;      
      return ($result_code_CS{OK}, @children);
   }
};

if ($@)
{
   $logger->error("CS::Test is unable to get MO children.\n Error is: $!\n");
}




#
# Check if the given plan name exists in the CS
#
# Arguments:
#   plan   : string              [mandatory]
#
# Output:
#   result : result_code_CS if a problem occurred or plan doesn't exist, otherwise return undef if plan exists

#
eval
{
   sub does_plan_exist
   {
      my $plan = shift;
      unless ($plan and $plan =~ m/\w+/) # check if plan has a valid name
      {
         $logger->error("Must give a valid plan name, plan name \"$plan\" is not valid\n");
         return $result_code_CS{PLAN_NAME_INVALID};
      }
      if (my $planned_data = `$cstest -s Region_CS lp`)
      {
         if ($planned_data =~ m/^$plan\b/m)
         {
            $logger->info("Plan name $plan exists\n");
            return;
         }
      }
      $logger->info("Plan name $plan doesn't exist\n");
      return $result_code_CS{PLAN_DOESNT_EXIST};
   }
};

if ($@)
{
   $logger->error("CS::Test is unable to get plan information.\n Error is: $!\n");
}



#
# Create a plan with the given name
#
# Arguments:
#   plan   : string              [mandatory]
#
# Output:
#   result : result_code_CS if a problem occurred, otherwise return undef if plan created OK
#   
#   
eval
{
   sub create_plan
   {
      my $plan = shift;
      unless ($plan and $plan =~ m/\w+/) # check if plan has a valid name
      {
         $logger->error("Must give a plan name\n");
         return $result_code_CS{PLAN_NAME_INVALID};
      }
      
      my $result = does_plan_exist($plan);   # check if plan already exists
      if ($result and $result == $result_code_CS{PLAN_DOESNT_EXIST})
      {
         if (system("$cstest -s Region_CS cp $plan"))   # should return 0 if plan was created OK
         {
            $logger->error("Unknown problem occurred while creating plan name $plan\n");
            return $result_code_CS{CS_ERROR};
         }
         else
         {
            $logger->info("Plan name $plan created OK\n");
            return;
         }
      }
      elsif ($result)  # some other error occurred
      {
         $logger->error("Error when checking if plan name $plan exists, error is $result, error message is $result_string_CS{$result}\n");
         return $result;
      } 
      return $result_code_CS{PLAN_ALREADY_EXISTS};
   }
};

if ($@)
{
   $logger->error("CS::Test is unable to create plan.\n Error is: $!\n");
}


#
# Delete a plan with the given name
#
# Arguments:
#   plan   : string              [mandatory]
#
# Output:
#   result : result_code_CS if a problem occurred, otherwise return undef if plan deleted OK
#
eval
{
   sub delete_plan
   {
      my $plan = shift;
      unless ($plan and $plan =~ m/\w+/) # check if plan has a valid name
      {
         $logger->error("Must give a plan name\n");
         return $result_code_CS{PLAN_NAME_INVALID};
      }
      my $result = does_plan_exist($plan);   # check if plan already exists
      if ($result)
      {
         $logger->error("Error when checking if plan name $plan already exists, error is $result, error message is $result_string_CS{$result}\n");
         return $result;
      }

      if (system("$cstest -s Region_CS dp $plan"))   # should return 0 if plan was deleted OK
      {
         $logger->error("Unknown problem occurred while deleting plan name $plan\n");
         return $result_code_CS{CS_ERROR};
      }
      else
      {
         $logger->info("Plan name $plan deleted OK\n");
         return;
      }
   }
};

if ($@)
{
   $logger->error("CS::Test is unable to delete plan.\n Error is: $!\n");
}




#
# Activate a plan with the given name
#
# Arguments:
#   plan   : string              [mandatory]
#
# Output:
#   result : result_code_CS if a problem occurred, otherwise return undef if plan activated OK
#
eval
{
   sub activate_plan
   {
      my $plan = shift;
      unless ($plan and $plan =~ m/\w+/) # check if plan has a valid name
      {
         $logger->error("Must give a plan name\n");
         return $result_code_CS{PLAN_NAME_INVALID};
      }
      my $result = does_plan_exist($plan);   # check if plan already exists
      if ($result)
      {
         $logger->error("Error when checking if plan name $plan already exists, error is $result, error message is $result_string_CS{$result}\n");
         return $result;
      }

      if (system("$cstest -s Region_CS -p $plan update"))   # should return 0 if plan was activated OK
      {
         $logger->error("Unknown problem occurred while activating plan name $plan\n");
         return $result_code_CS{CS_ERROR};
      }
      else
      {
         $logger->info("Plan name $plan activated OK\n");
         return;
      }
   }
};

if ($@)
{
   $logger->error("CS::Test is unable to activate plan.\n Error is: $!\n");
}


#
# Create an MO with the given name
#
# Arguments:
#   MO         : string              [mandatory]
#   attributes : space separated list of words
#   server     : boolean - Region or Segment
#   plan       : plan name
#
# Output:
#   result     : result_code_CS if a problem occurred, otherwise return undef
#
eval
{
   sub create_mo_CS
   {
      my %param = ( server  => "Segment",    # values here are the defaults
                    plan    => "",
                    attributes => "",
                    @_
                  );

      
      my $mo_fdn     = mo_name_is_OK($param{mo}, qr/SubNetwork=\S+/) or return $result_code_CS{MO_NAME_INVALID};
      my $plan       = plan_is_OK($param{plan}) or return $result_code_CS{PLAN_DOESNT_EXIST};
      my $cs_server  = get_cs_server($param{server}) or return $result_code_CS{SERVER_NAME_INVALID};

      unless (get_mo_data("$cstest $plan -s $cs_server e $mo_fdn")) # check if MO exists
      {
         $logger->error("MO name $mo_fdn already exists\n");
         return $result_code_CS{MO_ALREADY_EXISTS};
      }

      my ($parent, $mo_class) = $mo_fdn =~ m/(SubNetwork=.*),(\w+)/;
      $logger->info("MO class is $mo_class,\tParent is $parent\n");

      if (get_mo_data("$cstest $plan -s $cs_server e $parent")) # check if parent MO exists
      {
         $logger->error("Parent MO $parent doesn't exist\n");
         return $result_code_CS{MO_DOESNT_EXIST};
      }      

      my $mim_file; 
      if ($param{server} =~ m/Segment/i)
      {
         # get the MIM data from the MeContext MO
         my ($meContext) = $mo_fdn =~ m/(SubNetwork.*?MeContext=[^,\s]+)/ or return $result_code_CS{MO_NAME_INVALID};
         $logger->info("meContext is $meContext\n");
         my %result = get_mo_attributes_CS( mo         => $meContext,
                                            attributes => "neMIMName mirrorMIBversion",
                                            plan       => $param{plan},
                                            server     => $param{server} );

         $logger->info("MIM name is $result{neMIMName} and mirror MIM version is $result{mirrorMIBversion}\n");
# print"\n\n eeimacn: MIB version is $result{mirrorMIBversion} \n\n";

         return $result_code_CS{MIM_VERSION_INVALID} unless $result{neMIMName} and $result{mirrorMIBversion};
         
         $mim_file = get_mim_file($result{neMIMName}, $result{mirrorMIBversion}) or return $result_code_CS{MIM_FILE_NOT_FOUND};
      }
      else  # MO must be in the Region CS
      {
         $mim_file = get_mim_file("RANOS_SUBNETWORK_MODEL", "") or return $result_code_CS{MIM_FILE_NOT_FOUND};
      }

      my ($result, %attributes) = get_mandatory_attributes( $mo_class, $mim_file);

      return $result_code_CS{ATTRIBUTES_INVALID} if $result;  # some problem in fetching mandatory attrs
   
      # if any attributes are given in the argument list, then these will override the defaults
      if ($param{attributes})
      {
         my %override_attrs = split /\s+/, $param{attributes};
         %attributes = (%attributes, %override_attrs);
      }

      my @attrs = %attributes; # flatten the hash into a list
      my $attrs = scalar @attrs ? "-attr @attrs" : "";  # add -attr prefix if any attributes exist
      $logger->info("$cstest $plan -s $cs_server cm $mo_fdn $attrs\n");
      if (my $result = `$cstest $plan -s $cs_server cm $mo_fdn -attr @attrs`)
      {
         $logger->error("Error creating MO - From CS got: $result\n");
         return $result_code_CS{CS_ERROR};
      }

      $logger->info("MO created OK\n");
      return;  # return undef as MO was created OK
   }
};

if ($@)
{
   $logger->error("CS::Test is unable to create MO.\n Error is: $!\n");
}


#
# Delete an MO with the given name
#
# Arguments:
#   MO       : string              [mandatory]
#   server   : boolean - Region or Segment
#   plan     : plan name
#
# Output:
#   result   : result_code_CS if a problem occurred, otherwise return undef
#
eval
{
   sub delete_mo_CS
   {
      my %param = ( server     => "Segment",    # values here are the defaults
                    plan       => "",
                    @_
                  );

      my $mo_fdn     = mo_name_is_OK($param{mo}, qr/SubNetwork=\S+/) or return $result_code_CS{MO_NAME_INVALID};
      my $plan       = plan_is_OK($param{plan}) or return $result_code_CS{PLAN_DOESNT_EXIST};
      my $cs_server  = get_cs_server($param{server}) or return $result_code_CS{SERVER_NAME_INVALID};

      if (get_mo_data("$cstest $plan -s $cs_server e $mo_fdn")) # check if MO exists
      {
         $logger->error("MO name $mo_fdn doesn't exist\n");
         return $result_code_CS{MO_DOESNT_EXIST};
      }
      if (system("$cstest $plan -s $cs_server dm $mo_fdn"))   # should return 0 if MO was deleted OK
      {
         $logger->error("Error deleting MO $mo_fdn\n");
         return $result_code_CS{CS_ERROR};
      }
      $logger->info("MO deleted OK\n");
      return;      
   }
};

if ($@)
{
   $logger->error("CS::Test is unable to delete MO.\n Error is: $!\n");
}



#
# Local routines
#
sub segment_cs_id {
#	my $hostname = hostname;
#	chomp ($hostname);
#	$seg_cs = "Seg_".$hostname."_CS";
# eeichrn changed this to get it working for p4


   my $seg_cs = `grep SegmentCS= /etc/opt/ericsson/system.env` or return;
   my @seg_cs_data = split(/\n/, $seg_cs);

   $seg_cs_data[0] =~ s/SegmentCS=//;

   #chomp($seg_cs);
   #$seg_cs =~ s/SegmentCS=//;
   #print"\n\n eeitjn THIS IS THE SEG_CS: $seg_cs_data[0] \n\n";
   return "$seg_cs_data[0]";
}


sub find_cstest
{
   if (-e "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest")
   {
      $cstest = "/opt/ericsson/nms_cif_cs/etc/unsupported/bin/cstest";
   }
   elsif (-e "/opt/ericsson/nms_cif_unsupported/nms_cif_cs/bin/cstest")
   {
      $cstest = "/opt/ericsson/nms_cif_unsupported/nms_cif_cs/bin/cstest";
   }
   else
   {
      $logger->error("Couldn't find cstest client binary\n");
      return $result_code_CS{CS_ERROR};
   }
}


sub get_cs_server
{
   my $server = shift;

   my $cs_server;

   if ($server =~ /Region/i)
   {
      $cs_server = "Region_CS";
   }
   elsif ($server =~ /Segment/i)
   {
      $cs_server = $seg_cs;
   }
   elsif ($server =~ /ONRM/i)  ### 2006-02-24 added ONRM eeimhes
   {
      $cs_server = "ONRM_CS";
   }
   else
   {
      $logger->error("Invalid CS server provided, $server\n");
   }
   return $cs_server;
}


sub mo_name_is_OK
{
   my ($mo, $regex) = @_;

   unless ($mo)
   {
      $logger->error("MO name is empty\n");
      return;
   }
   $logger->debug("MO is $mo, regex is ($regex)\n");

   unless ($mo =~ m/^\b$regex\b/)
   {
      $logger->error("MO name or class is invalid: $mo\n");
      return;
   }

   return $mo;
}


sub attrs_to_get_are_OK
{
  my $attributes = shift;
  if ($attributes) { $attributes =~ s/^\s+//; }  # remove leading whitespace 
  if ($attributes)
  {
  	my @attrs = split /\s+/, $attributes;
      	foreach (@attrs)
      	{
       		unless (m/^[^\W]+/)
       		{
       			$logger->error("Attributes not valid:\n  faulty attribute is $_\n  attributes argument was: ($attributes)\n");
       			return;
        	}
      	}
   $logger->debug("Attrs are $attributes\n");
   }

   my $attrs = ($attributes) ? "-an $attributes" : "-a";
   $logger->debug("CS Attrs are $attrs\n");
   return $attrs;
}


sub attrs_to_set_are_OK
{
   my $attributes = shift;

   $attributes =~ s/^\s+//;  # remove leading whitespace

   if ($attributes)
   {
      my @attrs = split /\s+/, $attributes;
      if ((scalar @attrs) % 2)
      {
         $logger->error("Attributes not valid:\n  number of arguments is odd (", scalar @attrs, "), must be even, i.e. a list of (name value) pairs\n  attributes argument was \"$attributes\"\n");
         return;
      }

      foreach (@attrs)
      {
         unless (m/[-\w,"'<>+=;#]+/)   # allow any valid FDN char, see RFC 2253 or 3GPP TS 32.300
         {
            $logger->error("Attributes not valid:\n  faulty attribute is $_\n  attributes argument was $attributes\n");
            return;
         }
      }
   }
   $logger->debug("Attrs are $attributes\n");
   return $attributes;
}



sub plan_is_OK
{
   my $plan = shift;

   if ($plan)
   {
      $logger->info("Handling MOs in planned area $plan\n\n");
      my $planned_data = `$cstest -s Region_CS lp`;
      if ($planned_data and ($planned_data !~ m/^$plan:/m))
      {
         $logger->error("Couldn't find a planned area with the name: $plan\n");
         return;
      }
      $plan = "-p $plan";    # add a -p prefix for use in cstest application call
   }
   else
   {
      $plan = " ";  # plan is empty, so set to a blank space to return a true value
   }

   return $plan;
}


sub get_mo_data
{
   my $cs_request = shift;

   my $mo_data = `$cs_request`;

   $logger->debug("MO data is\n$mo_data\n") if $mo_data;

   if ($mo_data =~ /exception/)  # CS test error occurred, probably a java exception
   {
      $logger->error("Couldn't read data from CS, is the MO in a planned area (use -p plan)\nCS error was:\n", $mo_data);
      return;
   }

   return $mo_data;
}


sub extract_mo_data
{
   my ($mo_data, $attrs, $class_or_instance) = @_;

   my $mo;
   my %mo_hash;
   if(!$attrs) { $attrs = " "; }
   my @attributes = split /\s/, $attrs;
   my $attr_regex = join ("|", @attributes);     # create a regex for pattern match of attributes
   my @mo_data    = split(/\n/, $mo_data);

   $logger->debug("regex is $attr_regex\n");

   foreach (@mo_data)
   {
      $logger->debug("MO data line is\n$_\n");
      if (m/^(SubNetwork.*)$/)
      {
         $mo = $1;
         $logger->debug("Found MO is $1\n");
      }
      elsif (m/\b($attr_regex)\b/)
      {
         $logger->debug("MO is $mo\n");
         
         my $ipv6Address = $_;
         $ipv6Address = substr($ipv6Address, index($ipv6Address, "\""), );
         $ipv6Address =~ s/\"//g;
         
         if (m/]\s+(\w+).*:\s?(.*)/)
         {
            my ($attr, $value) = ($1, $2);
            $logger->debug("attr is  $1, value is $2\n");
            $value =~ s/\\?"//g;                           # remove any quote chars and any escaped quotes i.e. \"
            $value =~ s/<(Undefined)Value>/$1/g;           # set any "<UndefinedValue>" to "Undefined"

            if ($value =~ m/struct/)                       # special case for structs, format is attr1=value1:attr2=value2:attr3=value3
            {
               my $struct;
               $struct .= "$1;" while ($value =~ m/(\w+=\w+)/g);
               chop($struct);                              # throw away trailing semicolon
               $value = $struct;
            }

            if ($class_or_instance eq "class")          # MO class, so save FDN as well as attr=value
            {
               if (exists $mo_hash{$mo}{$attr})            # if a value has been found already for this attr
               {
                  $mo_hash{$mo}{$attr} .= " $value";       # then add the new value with a space separator
               }
               else
               {
                  $mo_hash{$mo}{$attr} = $value;           # else just save it
               }
               $logger->debug("\t$mo   $attr=$value\n");
            }
            elsif($attr =~ m/ipAddress/ && $ipv6Address =~ m/\:/)	#Check for IPv6 Address
            {
               $value = $ipv6Address;
            	
               if (exists $mo_hash{$attr})                # if a value has been found already for this attr
               {
                  $mo_hash{$attr} .= " $value";            # then add the new value with a space separator
               }
               else
               {
                  $mo_hash{$attr} = $value;                # else just save it
               }
               $logger->debug("\t$attr=$value\n");
            }
            else                                           # MO instance, so just save attr=value
            {
               if (exists $mo_hash{$attr})                 # if a value has been found already for this attr
               {
                  $mo_hash{$attr} .= " $value";            # then add the new value with a space separator
               }
               else
               {
                  $mo_hash{$attr} = $value;                # else just save it
               }
               $logger->debug("\t$attr=$value\n");
            }
         }
      }
   }

   return %mo_hash;
}

sub get_mim_file
{
   my ($neMIMName, $mirrorMIBversion) = @_;

   $mirrorMIBversion =~ s/\./_/g if $mirrorMIBversion; # replace dots with underscores
   #$mirrorMIBversion =~ s/(\d_)\d+/$1/ if $mirrorMIBversion; # remove last digit
   #changed by edavcud 15/08/06 for R5
   my $mim_path = "/opt/ericsson/nms_umts_wranmom/dat";
   $mim_path = "/opt/ericsson/nms_umts_cms_lib_com/dat" if !(-d $mim_path);
   my $mim_file = `ls -1r $mim_path/$neMIMName"_v"$mirrorMIBversion.xml`;
   unless ($mim_file)
   {
      $logger->error("MIM file $mim_file not found\n");
      return;
   }
   chomp $mim_file;
   $logger->info("MIM file is $mim_file\n");
   return $mim_file;
}
   

sub get_mandatory_attributes
{
   my ($mo_class, $mim_file) = @_;

   $logger->info("MO class is $mo_class, MIM file is $mim_file\n");
   
   # parse MIM file to attrs which are mandatory for the MO class
   my $twig = XML::Twig->new();
   $twig->parsefile($mim_file);

   my $class_search = './/class[@name="' . $mo_class . '"]';  # find the MO class data in the MIM file
   my ($mo_ref) = $twig->get_xpath($class_search);
   
   my $mo = $mo_ref->att("name");
   $logger->info("MO class is $mo\n");

   # find all the attributes in the MO class
   my %mo_hash;
   for my $mo_child ( $mo_ref->children )   # extract the attribute information from the MIM file
   {
      if ( $mo_child->tag eq "attribute" )
      {
         my $attr = $mo_child->att("name");
         $logger->debug("Attr is $attr\n");

         for my $attr_child ( $mo_child->children )
         {
            $mo_hash{$attr}{ $attr_child->tag } = $attr_child;
         }
      }
   }

   # find the mandatory attrs and their data types
   my %attributes;
   for my $attr (sort keys %mo_hash)
   {
      next unless exists $mo_hash{$attr}{mandatory};  # only want to handle mandatory attrs
      $logger->debug("Mandatory attr is $attr\n");
      my ($data_type, $min) = get_data_type( $mo_hash{$attr}{dataType} );
      $logger->debug("\tData type is $data_type\n");
      $logger->debug("\tMin is $min\n") if defined $min;
      if ($data_type eq "long")
      {
         my $value = defined $min ? $min : "0";
         $attributes{$attr} = $value;
      }
      elsif ($data_type eq "string")
      {
         $attributes{$attr} = $attr;
      }
      elsif ($data_type eq "moRef")
      {
         $logger->info("Data type is moRef\n");
         $attributes{$attr} = $attr;
      }
      else
      {
         $logger->error("Data type $data_type not supported yet!\n");
      }
   }
   return ($result_code_CS{OK}, %attributes);  # first arg is result
}


sub get_data_type
{
   my $ref = shift;

   my $child     = $ref->first_child;
   my $data_type = $child->tag;
   $logger->debug("\t$data_type\n");
   
   if ($data_type eq "sequence")
   {
      $logger->error("Sequence not handled yet!\n");
      return $data_type;
   }
   elsif ($data_type eq "string")
   {
      return $data_type;
   }
   elsif ($data_type  =~ /long/)  # match long or longlong
   {
      if (my ($min_ref) = $child->get_xpath(".//min")) # if a min value exists, return it as well
      {
         return ($data_type, $min_ref->text);
      }
      return $data_type;
   }
   elsif ($data_type eq "boolean")
   {
      return $data_type;
   }

   unless ( $child->has_children )
   {
      return $data_type;
   }

   return "Data type not handled yet";
}




1;


__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

CS::Test - A perl module for accessing the Configuration Service (CS).

=head1 SYNOPSIS

 use lib '/net/atrnjump/share/guitest/perl/lib';
 use CS::Test;

 my $plan = 'my_plan';
 my $mo   = 'SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=RNC01-10-2';

 my %mo_hash = get_mo_attributes_CS( mo => $mo, plan => $plan, attributes => 'cId pwrAdm qRxLevMin locationAreaRef' );

 print "$mo\n";

 for my $attr (sort keys %mo_hash)
 {  
    printf "   %-30s : %s\n", $attr, $mo_hash{$attr};
 }


=head1 DESCRIPTION

This module is intended for perl script authors who wish to access the Configuration Service (CS).

The module provides a number of functions which simplify the handling of reading/writing information to/from the CS.

The functions allow MO creation and deletion; planned area creation and deletion; and the getting and setting of MO attributes.


=head1 PREREQUISITES

Since some of the functions use an external XML parser that is written in C, it may be necessary to set an 
environment variable (LD_LIBRARY_PATH) so that the C library can be found.

NOTE - The error message if this variable is not set will be:

 ld.so.1: /net/atrnjump/share/guitest/perl/bin/perl: fatal: libexpat.so.0: open failed: No such file or directory


To set this using a bash shell:

 export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/net/atrnjump/share/guitest/perl/lib

or in csh or tcsh:

 setenv LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:/net/atrnjump/share/guitest/perl/lib

The XML parser also requires a later version of perl than that which comes with Solaris 8 or 9,
so when running the scripts, the version of perl used should be that at /net/atrnjump/share/guitest/perl/bin/perl.
To ensure that this version is used, the first line of the users perl script should be set to:

 #!/net/atrnjump/share/guitest/perl/bin/perl

and invoked using the absolute path to the script, e.g. 

 ./my_script.pl or /home/nmsadm/my_script.pl
 
rather than using 

 perl my_script.pl

since the latter version will use the perl binary found using the PATH environment variable.



=head1 EXPORTED FUNCTIONS

=head2 get_mo_attributes_CS

This function returns the requested attributes (or all attributes) for a given MO from the CS.
The full syntax of the function call is:

 get_mo_attributes_CS( mo         => $mo, 
                       plan       => $my_plan, 
                       server     => "Segment", 
                       attributes => "space separated list of attrs");

The parameters have the following types:

=over 3

=item mo - a string indicating an MO FDN, e.g. 'SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01'

=item plan - a string indicating a plan name, e.g. 'my_plan'

=item server - a string indicating either 'Region' or 'Segment', e.g. 'Region'

=item attributes - a string containing a space separated list of attribute names, e.g. 'cId pwrAdm qRxLevMin'

=back

However, all the parameters are optional, except for 'mo', since there are default values for these.
The defaults have the effect of fetching all attributes for the given MO, from the valid area, using the Segment CS.
So, the function may be called with just the MO FDN in the 'mo' parameter, e.g.

 get_mo_attributes_CS(mo => "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01");

and all attributes for this MeContext MO will be fetched from the valid area of the Segment CS.

If the only attribute wanted was the IP address, then the following could be used:

 get_mo_attributes_CS(mo => "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01", attributes => "ipAddress");

The returned values are in the form of a hash, so to access the IP address attribute:

 my %mo_hash = get_mo_attributes_CS(mo => "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01", attributes => "ipAddress");

 print "IP address is $mo_hash{ipAddress}\n";

To print out all the MeContext MO attributes:

 my %mo_hash = get_mo_attributes_CS(mo => "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01");
 for my $attr (sort keys %mo_hash)
 {
   printf "   %-30s : %s\n", $attr, $mo_hash{$attr};
 }

To fetch attributes from an MO in a Region CS use the 'server' parameter:

 my %mo_hash = get_mo_attributes_CS(mo => "SubNetwork=ONRM_RootMo_R,Areas=1,Plmn=PLMN_235_91_2", server => "Region",  attributes => "mcc mnc mncLength");

 print "PLMN info is $mo_hash{mcc}, $mo_hash{mnc}, $mo_hash{mncLength}\n";

=head2 set_mo_attributes_CS

This function sets the requested attributes for a given MO in the CS.
The full syntax of the function call is:

 set_mo_attributes_CS( mo         => $mo, 
                       plan       => $my_plan, 
                       server     => "Segment", 
                       attributes => "space separated list of name value pairs");

Similar to get_mo_attributes_CS, this function has default values for the 'server' (use Segment CS) and 'plan' (use valid area) 
parameters, but here the 'mo' and 'attributes' parameters are mandatory.

The parameter types are as for get_mo_attributes_CS but here the 'attributes' parameter has the type:

=over 3

=item attributes - a string containing a space separated list of attribute name value pairs, e.g. 'cId 10 pwrAdm 75 qRxLevMin -115'

=back

The return value is either $result_code_CS{OK} which means that the set worked OK, or a result code indicating the error cause.

So, to set the userLabel to 'my_RNC';

 my $result = set_mo_attributes_CS( mo => "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01", attributes => "userLabel my_RNC" );
 if ($result)
 {
    print "result code is $result\n";
 }
 else
 {
    print "Attributes set OK\n";
 }

=head2 get_class_attributes_CS

This function returns the requested attributes for all MO instances in the given MO class.
The full syntax of the function call is:

 get_class_attributes_CS( mo         => $mo, 
                          plan       => $my_plan, 
                          server     => "Segment", 
                          attributes => "space separated list of attributes");

As for get_mo_attributes_CS, this function has default values for the 'server' (use Segment CS); 'plan' (use valid area)
and 'attributes' (get all) parameters, but the 'mo' parameter is mandatory.

The parameter types are as for get_mo_attributes_CS but here the 'mo' parameter has the type:

=over 3

=item mo - a string indicating an MO class, e.g. 'UtranCell'

=back

The returned values are in the form of a hash, but in this case there are 2 sets of keys, i.e. the hash is of the form:

 $mo_hash{fdn}{attr} = value

where the first key is MO FDN and the second key is the attribute name.

To print all the qRxLevMin attributes for all UtranCells:

 my $mo_class = "UtranCell";
 my %result = get_class_attributes_CS( mo => "UtranCell", attributes => "qRxLevMin");

 for my $mo (sort keys %result)
 {
   print "$mo\n";

   for my $attr (sort keys %{$result{$mo}})
   {
      printf "%-30s : %s\n", $attr, $result{$mo}{$attr};
   }
 }

=head2 get_mo_list_for_class_CS

This function returns a list of the MO instances for the given MO class.
The full syntax of the function call is:

 get_mo_list_for_class_CS( mo     => $mo, 
                           plan   => $my_plan, 
                           server => "Segment");

As for get_mo_attributes_CS, this function has default values for the 'server' (use Segment CS) and 'plan' (use valid area), 
but the 'mo' parameter is mandatory.

The parameter types are as for get_mo_attributes_CS but here the 'mo' parameter has the type:

=over 3

=item mo - a string indicating an MO class, e.g. 'UtranCell'

=back

The returned values are in the form of an array.

An example usage is:

 my @utranCells = get_mo_list_for_class_CS( mo => "UtranCell" );
 for my $cell (@utranCells)
 {
    print "UtranCell is $cell\n";
 }

=head2 does_mo_exist_CS

This function returns an indication of the existence of the given MO instance.
The full syntax of the function call is:

 does_mo_exist_CS( mo     => $mo, 
                   plan   => $my_plan, 
                   server => "Segment");

As for get_mo_attributes_CS, this function has default values for the 'server' (use Segment CS) and 'plan' (use valid area), 
but the 'mo' parameter is mandatory.

The parameter types are as for get_mo_attributes_CS.

The return value is either $result_code_CS{MO_ALREADY_EXISTS} which means that the MO exists, 
or $result_code_CS{MO_DOESNT_EXIST} indicating that the MO doesn't exist, 
or a result code indicating the error cause.

An example usage is:

 my $result = does_mo_exist_CS( mo => "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01" );

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


=head2 get_mo_children_CS

This function returns an array of the children for the given MO instance.
The full syntax of the function call is:

 get_mo_children_CS( mo     => $mo, 
                     plan   => $my_plan, 
                     server => "Segment");

As for get_mo_attributes_CS, this function has default values for the 'server' (use Segment CS) and 'plan' (use valid area), 
but the 'mo' parameter is mandatory.

The parameter types are as for get_mo_attributes_CS.

The return value is either 'undef' which means that the children are contained in the returned array, 
or a result code indicating the error cause.

An example usage is:
 my ($result, @children) = get_mo_children_CS( mo => $mo, plan => $plan );

 unless ($result)
 {
   print "Children are:\n";
   print "  $_\n" for @children;
 }


=head2 create_plan

This function is used to create a planned area in the CS.
The full syntax of the function call is:

 create_plan($my_plan); 

where the parameter type is a string indicating the plan name.

The return value is either 'undef' which means that the plan was created OK, or a result code indicating the error cause.

An example usage is:

 my $result = create_plan("my_plan");

 if ($result)
 {
    print "result code is $result\n";
 }
 else
 {
    print "Plan created OK\n";
 }
 

=head2 activate_plan

This function is used to activate a planned area in the CS.
The full syntax of the function call is:

 activate_plan($my_plan); 

where the parameter type is a string indicating the plan name.

The return value is either 'undef' which means that the plan was activated OK, or a result code indicating the error cause.

An example usage is:

 my $result = activate_plan("my_plan");

 if ($result)
 {
    print "result code is $result\n";
 }
 else
 {
    print "Plan activated OK\n";
 }
 


=head2 delete_plan

This function is used to delete a planned area in the CS.
The full syntax of the function call is:

 delete_plan($my_plan); 

where the parameter type is a string indicating the plan name.

The return value is either 'undef' which means that the plan was deleted OK, or a result code indicating the error cause.

An example usage is:

 my $result = delete_plan("my_plan");

 if ($result)
 {
    print "result code is $result\n";
 }
 else
 {
    print "Plan deleted OK\n";
 }

=head2 does_plan_exist

This function returns an indication of the existence of the given plan name.
The full syntax of the function call is:

 does_plan_exist( $my_plan );

where the parameter type is a string indicating the plan name.

The return value is either 'undef' which means that the plan exists, or a value ($result_code_CS{PLAN_DOESNT_EXIST}) 
indicating that the plan doesn't exist, or a result code indicating the error cause.

An example usage is:

 my $result = does_plan_exist( "my_plan" );

 if ($result)
 {
    print "Plan doesn't exist, result code is $result, error message is $result_string_CS{$result}\n";
 }
 else
 {
    print "Plan exists OK\n";
 }



=head2 create_mo_CS

This function creates the given MO instance.
The full syntax of the function call is:

 create_mo_CS( mo     => $mo, 
               plan   => $my_plan, 
               server => "Segment",
               attributes => "space separated list of name value pairs");

As for get_mo_attributes_CS, all the parameters are optional, except for 'mo', since there are default values for these.

The parameter types are as for set_mo_attributes_CS.

The attributes parameter is optional, since if none are given then the default values will be used.
Any mandatory parameters without defaults will be found from the MIM file, i.e. if the type is string then
the attribute name will also be used as the value; if the type is long, then the minimum value from the MIM file is used.

Any attributes given in the parameter list will over-ride the default values.

The return value is either 'undef' which means that the MO was created, or a result code indicating the error cause.

An example usage is:

 my $mo = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=my_cell";

 my $result = create_mo_CS( mo => $mo, plan => $plan );

 if ($result)
 {
    print "MO wasn't created, result code is $result, error message is $result_string_CS{$result}\n";
 }
 else
 {
   print "MO created OK\n";

 }



=head2 delete_mo_CS

This function deletes the given MO instance.
The full syntax of the function call is:

 delete_mo_CS( mo     => $mo, 
               plan   => $my_plan, 
               server => "Segment");

As for get_mo_attributes_CS, this function has default values for the 'server' (use Segment CS) and 'plan' (use valid area), 
but the 'mo' parameter is mandatory.

The parameter types are as for get_mo_attributes_CS.

The return value is either 'undef' which means that the MO was deleted, 
or a result code indicating the error cause.

An example usage is:

 my $result = delete_mo_CS( mo => $mo );

 if ($result)
 {
    print "MO wasn't deleted, result code is $result, error message is $result_string_CS{$result}\n";
 }
 else
 {
    print "MO was deleted OK\n";
 }


=head2 mo_name_is_OK

This is a utility routine to validate the MO name which takes an MO name and a 
regular expression as arguments, and returns the name if it is OK, or undef if there is a problem.

=head2 attrs_to_get_are_OK

This is a utility routine to validate the MO attributes (to get) which takes an attribute string as the argument, 
and returns the attribute string if it is OK, or undef if there is a problem.

=head2 attrs_to_set_are_OK

This is a utility routine to validate the MO attributes (to set) which takes an attribute string as the argument, 
and returns the attribute string if it is OK, or undef if there is a problem.

=head2 %result_code_CS

This is a hash containing the result codes returned from the module.
Allows use of an error string key as a test condition in evaluating results, e.g.

 my $result = does_mo_exist_CS( mo => $mo );
 if ($result == $result_code_CS{MO_DOESNT_EXIST})
 {
   print "MO doesn't exist\n";
 }


=head2 %result_string_CS

This is a hash containing the result strings returned from the module.
The string can be accessed by using the result code as the key, i.e.

 my $result = does_mo_exist_CS( mo => $mo );
 print "Result code is $result, message is $result_string_CS{$result}\n";

=head1 AUTHOR

Copyright LM Ericsson Ireland.

=head1 SEE ALSO

perl(1).

=cut



