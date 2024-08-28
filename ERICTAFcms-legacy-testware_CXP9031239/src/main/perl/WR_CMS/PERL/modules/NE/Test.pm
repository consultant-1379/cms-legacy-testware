#!/net/atrnjump/share/guitest/perl/bin/perl
package NE::Test;

use 5.006;
use strict;
use warnings;
#use lib "/net/atrnjump/share/guitest/perl/lib";
#use Net::FTP;
use CS::Test qw( mo_name_is_OK attrs_to_get_are_OK attrs_to_set_are_OK get_mo_attributes_CS get_mo_list_for_class_CS);
use Log::Log4perl qw(get_logger :levels);

Log::Log4perl->init("/opt/ericsson/atoss/tas/WR_CMS/PERL/modules/Log/log4perl.conf");

my $logger = get_logger();

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use NE::Test ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
   do_netsim_command
   get_class_attributes_NE
   get_mo_attributes_NE
   get_moid
   get_sim_info
   set_mo_attributes_NE
   does_mo_exist_NE
   create_mo_NE
   delete_mo_NE
   %result_code_NE
   %result_string_NE
);

our $VERSION = '0.01';

my @results = qw( OK
                  MO_NAME_INVALID
                  ATTRIBUTES_INVALID
                  MO_ALREADY_EXISTS
                  MO_DOESNT_EXIST
                  MOID_INVALID
                  IP_ADDRESS_NOT_FOUND
                  MOSHELL_NOT_FOUND
                  NETSIM_VERSION_NOT_FOUND
                  SIM_INFO_NOT_FOUND
                  NETSIM_COMMAND_INVALID
                  NETSIM_SIM_INVALID
                  MIM_VERSION_INVALID
                  NETSIM_NODE_INVALID                  
                  MIM_FILE_NOT_FOUND
                  NE_ERROR
                  UNKNOWN_ERROR
		  REAL_NODE_ERROR
                );
                     
our %result_code_NE   = map {$results[$_], $_} 0..$#results;
our %result_string_NE = reverse %result_code_NE;


# Preloaded methods go here.

# These variables hold a cache of Netsim information for ip_address, netsim_pipe, sim, node - used for get_class_attributes
my %ne_ipAddress;
my %netsim_sim;
my %netsim_node;
my $netsim_pipe;

#
# Get the attributes from Netsim for the MO instance given
#
# Arguments:
#   mo         : MO instance (FDN)              [mandatory] 
#   attributes : space separated list of words
#   moid       : MO identity (integer - internal Netsim reference)
#                If the moid is specified, then the mo attribute must indicate
#                an FDN containing an MeContext identity (in order to find the
#                Sim handling the MO), e.g. SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01
#                The mo may contain additional RDN elements, but these will be ignored,
#                only the part of the FDN until the MeContext identity is significant.
#
# Output:
#   hash containing the name and value of any attributes found, in the format
#   $result{attr} = value
#
eval
{
   sub get_mo_attributes_NE
   {
      my %param = ( attributes => "",  # values here are the defaults
                    moid       => "",
                    @_
                  );

      $logger->info("MO is $param{mo}\n") if $param{mo};
      $logger->info("MOID is $param{moid}\n") if $param{moid};
      $logger->info("Attributes are $param{attributes}\n") if $param{attributes};

      attrs_to_get_are_OK($param{attributes}) or return;
      moid_is_OK($param{moid}) or return;

      my $mo_fdn         = mo_name_is_OK($param{mo}, qr/SubNetwork=.*?MeContext=/) or return;
      my ($meContext_id) = $mo_fdn =~ m/SubNetwork.*?MeContext=([^,\s]+)/ or return;
      $logger->info("mo_fdn is $mo_fdn\nmeContext_id is $meContext_id\n");

      # find IP address for this NE
      unless (exists $ne_ipAddress{$meContext_id})  # was the IP address found already for this node, if not get it
      {
         my $result;
         ($result, $ne_ipAddress{$meContext_id}) = get_ip_address($mo_fdn);
         return if $result; # some error occurred
      }
      unless ($ne_ipAddress{$meContext_id})
      {
         $logger->error("Unable to get an IP address for $mo_fdn\n");
         return;
      }
      $logger->info("ip_address is $ne_ipAddress{$meContext_id}\n");

      if ($ne_ipAddress{$meContext_id} =~ m/^159/) # get data from real node, since IP addresses for real nodes start with 159.107
      {
         if ($param{moid})
         {
            $logger->error("Argument moid ($param{moid}) is not valid when reading data from a real node\n");
            return;
         }
         return get_data_from_real_node($mo_fdn, $ne_ipAddress{$meContext_id}, $param{attributes});
      }
      else  # get data from Netsim
      {
         return get_data_from_netsim($mo_fdn, $ne_ipAddress{$meContext_id}, $param{attributes}, $meContext_id, $param{moid});
      }
   }
};

if ($@)
{
   $logger->error("NE::Test is unable to get MO attributes.\n Error is: $!\n");
}


#
# Get the attributes from Netsim for the MO class given
#
# Arguments:
#   mo         : MO class                       [mandatory]
#   attributes : space separated list of words
#
# Output:
#   hash containing the name and value of any attributes found, in the format
#   $result{fdn}{attr} = value
#
eval
{
   sub get_class_attributes_NE
   {
      my %param = ( attributes     => "",    # values here are the defaults
                    @_
                  );

      attrs_to_get_are_OK($param{attributes}) or return;

      my $mo_class   = mo_name_is_OK($param{mo}, qr/\w+/) or return;

      my @mo_list = get_mo_list_for_class_CS(mo => $mo_class) or return;
      $logger->debug("mo_list:\n@mo_list\n");

      my %result;
      for my $mo (@mo_list)
      {
         $logger->info("mo=$mo\n");
         my %mo_result = get_mo_attributes_NE ( mo => $mo, attributes => $param{attributes} );

         while (my ($attr, $value) = each %mo_result)
         {
            $result{$mo}{$attr} = $value;
            $logger->debug("Attribute: $attr = $value\n");
         }
      }

      return %result;
   }
};

if ($@)
{
   $logger->error("NE::Test is unable to get MO class attributes.\n Error is: $!\n");
}



#
# Set the attributes in Netsim for the MO instance given
#
# Arguments:
#   mo         : MO instance                                  [mandatory]
#   attributes : space separated list of (name value) words   [mandatory]
#   moid       : MO identity (integer - internal Netsim reference)
#                If the moid is specified, then the mo attribute must indicate
#                an FDN containing an MeContext identity (in order to find the
#                Sim handling the MO), e.g. SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01
#                The mo may contain additional RDN elements, but these will be ignored,
#                only the part of the FDN until the MeContext identity is significant.
#
# Output:
#   result     : return $result_code_NE{OK} if OK, or some other result_code_CS if a problem occurred
#

eval
{
   sub set_mo_attributes_NE
   {
      my %param = ( moid => "",  # values here are the defaults
                    @_
                  );

      $logger->info("MO is $param{mo}\nMOID is $param{moid}\nattrs are $param{attributes}\n");

      attrs_to_set_are_OK($param{attributes}) or return $result_code_NE{ATTRIBUTES_INVALID};
      moid_is_OK($param{moid}) or return $result_code_NE{MOID_INVALID};

      my $mo_fdn      = mo_name_is_OK($param{mo}, qr/SubNetwork=.*?MeContext=/) or return $result_code_NE{MO_NAME_INVALID};
      my ($ip_result, $ip_address) = get_ip_address($mo_fdn);
      return $result_code_NE{IP_ADDRESS_NOT_FOUND} if $ip_result;
      $logger->info("MO is $mo_fdn, \tIP address is $ip_address\n");

      my $result;

      if ($ip_address =~ m/^159/) # get data from real node, since IP addresses for real nodes start with 159.107
      {
         if ($param{moid})
         {
            $logger->error("Argument moid ($param{moid}) is not valid when setting data on a real node\n");
            return $result_code_NE{MOID_INVALID};
         }

         my $moshell = get_moshell() or return $result_code_NE{MOSHELL_NOT_FOUND};

         my ($mo_class, $mo_identity) = $mo_fdn =~ m/,([^,]+)=([^,]+)$/;
         $logger->info("MO class is $mo_class, \tMO ID is $mo_identity\n");

         # attributes have to be set one at a time using moshell
         my %attributes = split / /, $param{attributes};
         while (my ($attr, $value) = each %attributes)
         {
            $logger->info("attr is $attr=\"$value\"\n");

            my $moshell_command = "\'lt ^$mo_class ; set $mo_class=$mo_identity $attr $value\'";
            $logger->info("$moshell $ip_address $moshell_command\n");
            
            my $mo_data = `$moshell $ip_address $moshell_command`;
            $logger->info("MO data is\n$mo_data\n");
            
            unless ($mo_data)
            {
               $logger->error("Error setting data using moshell, command was \n\t$moshell $ip_address $moshell_command\n");
               return $result_code_NE{NE_ERROR};
            }

            unless ($mo_data =~ m/>>> Set/)
            {
               $logger->error("Error setting attribute value using moshell, command was \n\t$moshell $ip_address $moshell_command\n");
               $logger->error("Output from MO shell was\n$mo_data\n");
               $result = $result_code_NE{NE_ERROR};
            }
         }
         return $result;
      }
      else  # set data on Netsim
      {
         setup_netsim_access($ip_address);

         my ($result, $netsim_pipe) = get_netsim_pipe($ip_address);
         return $result if $result;

         # find simulation handling this NE
         my ($sim_result, $sim, $node) = get_sim_data($ip_address, $netsim_pipe);
         return $sim_result if $sim_result;

         my $moid = $param{moid};
         unless ($moid)    # no moid parameter given so use FDN to find it
         {
            # extract MO RDN from FDN
            my ($mo_rdn) = $mo_fdn =~ m/(ManagedElement=.*)$/;
            $logger->info("MO RDN is $mo_rdn\n");

            # read MO data from Netsim
            my $mo_netsim_data = `rsh -n -l netsim $ip_address "echo 'dumpmotree:moid=\\\"$mo_rdn\\\",dotty;' | $netsim_pipe -q -ne $node -sim $sim"`;
            $logger->debug("MO data from Netsim:\n$mo_netsim_data\n");
            ($moid) = $mo_netsim_data =~ m/(\d+)\s+\[label/ or return  $result_code_NE{MOID_INVALID};
         }
         $logger->info("MO ID is $moid\n");

         # attributes have to be set one at a time using netsim
         my %attributes = split /\s+/, $param{attributes};
         while (my ($attr, $value) = each %attributes)
         {
            $result .= `rsh -n -l netsim $ip_address "echo 'setmoattribute:mo=\\\"$moid\\\", attributes=\\\"$attr=$value\\\";' | $netsim_pipe -q -ne $node -sim $sim"`;
            $logger->info("Setting $attr=$value\n");
            $logger->debug("Result is $result\n");
         }
         return ($result and $result =~ m/OK/) ? $result_code_NE{OK} : $result_code_NE{NE_ERROR};
      }
   }
};

if ($@)
{
   $logger->error("NE::Test is unable to set MO attributes.\n Error is: $!\n");
}

#
# Do the Netsim command for the NE instance given
#
# Arguments:
#   mo         : MO instance                                  [mandatory]
#   command    : Netsim command                               [mandatory]
#   sim        : Netsim sim
#   node       : netsim node
#
# Output:
#   result     : return value in result_code_NE
#
eval
{
   sub do_netsim_command
   {
      my ($command, $mo, $sim, $node) = @_;
      unless ($mo =~ m/\w+/)
      {
         $logger->error("Invalid MO instance, $mo\n");
         return $result_code_NE{MO_NAME_INVALID};
      }
      unless ($command =~ m/^[\w \t-.]+$/)  # command must contain only these chars
      {
         $logger->error("Invalid command, $command\n");
        # return $result_code_NE{NETSIM_COMMAND_INVALID};
      }
      if ($sim and $sim !~ m/\S+/)
      {
         $logger->error("Invalid sim, $sim\n");
         return $result_code_NE{NETSIM_SIM_INVALID};
      }
      if ($node and $node !~ m/\w+/)
      {
         $logger->error("Invalid node, $node\n");
         return $result_code_NE{NETSIM_NODE_INVALID};
      }
      $logger->debug("MO is $mo\nCommand is $command\n");
      $logger->debug("Sim is $sim\n") if $sim;
      $logger->debug("Node is $node\n") if $node;

      my $mo_fdn         = mo_name_is_OK($mo, qr/SubNetwork=.*?MeContext=/) or return $result_code_NE{MO_DOESNT_EXIST};
      my ($meContext_id) = $mo_fdn =~ m/SubNetwork.*?MeContext=([^,\s]+)/ or return $result_code_NE{MO_NAME_INVALID};
      $logger->debug("mo_fdn is $mo_fdn\nmeContext_id is $meContext_id\n");

      my ($result, $ip_address) = get_ip_address($mo_fdn);  # find IP address for this NE
      return $result_code_NE{IP_ADDRESS_NOT_FOUND} if $result;
      $logger->info("ip_address is $ip_address\n");

      if ($ip_address =~ m/^159/) # get data from real node, since IP addresses for real nodes start with 159.107
      {
         $logger->error("do_netsim_command is not valid when working towards a real node - is only valid for Netsim\n");
         return $result_code_NE{NETSIM_COMMAND_INVALID};
      }
      else  # send command to Netsim
      {
         setup_netsim_access($ip_address);
         my ($result, $netsim_pipe) = get_netsim_pipe($ip_address);
         return $result if $result;

         unless ($sim)  # Sim wasn't given in the parameter list, so try to fetch sim and node from Netsim
         {
            my $result;
            ($result, $sim, $node) = get_sim_data($ip_address, $netsim_pipe);    # find simulation handling this NE
            return $result if $result;
         }
         $logger->info("sim is $sim, node is $node\n");
         $logger->info("Netsim command is $command\n");
         $logger->info("Netsim request is rsh -l netsim $ip_address echo $command | $netsim_pipe -q -ne $node -sim $sim\n");
         
         my $ns_result = `rsh -n -l netsim $ip_address "echo $command | $netsim_pipe -q -ne $node -sim $sim"`;
         $logger->info("Result is $ns_result\n");
         return $result_code_NE{OK};
      }
   }
};

if ($@)
{
   $logger->error("NE::Test is unable to handle do_netsim_command.\n Error is: $!\n");
}


#
# Get the SIM information from Netsim for the MO instance given
#
# Arguments:
#   mo         : MO instance                                  [mandatory]
#
# Output:
#   result     : result_code_NE 
#   sim        : the sim if found
#   node       : the node if found
#
eval
{
   sub get_sim_info
   {
      my ($mo) = @_;
      unless ($mo =~ m/\w+/)
      {
         $logger->error("Invalid MO instance, $mo\n");
         return $result_code_NE{MO_NAME_INVALID};
      }
      $logger->debug("MO is $mo\n");

      my $mo_fdn         = mo_name_is_OK($mo, qr/SubNetwork=.*?MeContext=/) or return $result_code_NE{MO_DOESNT_EXIST};
      my ($meContext_id) = $mo_fdn =~ m/SubNetwork.*?MeContext=([^,\s]+)/ or return $result_code_NE{MO_NAME_INVALID};
      $logger->debug("mo_fdn is $mo_fdn\nmeContext_id is $meContext_id\n");

      my ($result, $ip_address) = get_ip_address($mo_fdn);  # find IP address for this NE
      return $result if $result;

      $logger->info("ip_address is $ip_address\n");

      if ($ip_address =~ m/^159/) # get data from real node, since IP addresses for real nodes start with 159.107
      {
         $logger->error("get_sim_info is not valid when working towards a real node - is only valid for Netsim\n");
         return $result_code_NE{NE_ERROR};
      }
      else  # get sim info from Netsim
      {
         setup_netsim_access($ip_address);
         my ($result, $netsim_pipe) = get_netsim_pipe($ip_address);
         return $result if $result;

         my ($sim_result, $sim, $node) = get_sim_data($ip_address, $netsim_pipe);    # find simulation handling this NE
         return $sim_result if $sim_result;  # some error occurred
         
         $logger->info("sim is $sim, node is $node\n");
         return ($sim_result, $sim, $node);
      }
   }
};

if ($@)
{
   $logger->error("NE::Test is unable to get Sim information.\n Error is: $!\n");
}



#
# Get the MOID information from Netsim for the MO instance given
#
# Arguments:
#   mo         : MO instance                                  [mandatory]
#
# Output:
#   result     : result_code_NE 
#   moid       : the moid if found
#
eval
{
   sub get_moid
   {
      my ($mo) = @_;
      unless ($mo =~ m/\w+/)
      {
         $logger->error("Invalid MO instance, $mo\n");
         return $result_code_NE{MO_NAME_INVALID};
      }
      $logger->debug("MO is $mo\n");

      my $mo_fdn         = mo_name_is_OK($mo, qr/SubNetwork=.*?MeContext=/) or return $result_code_NE{MO_DOESNT_EXIST};
      my ($meContext_id) = $mo_fdn =~ m/SubNetwork.*?MeContext=([^,\s]+)/ or return $result_code_NE{MO_NAME_INVALID};
      $logger->debug("mo_fdn is $mo_fdn\nmeContext_id is $meContext_id\n");

      my ($result, $ip_address) = get_ip_address($mo_fdn);  # find IP address for this NE
      return $result if $result;

      $logger->info("ip_address is $ip_address\n");

      if ($ip_address =~ m/^159/) # get data from real node, since IP addresses for real nodes start with 159.107
      {
         $logger->error("get_moid is not valid when working towards a real node - is only valid for Netsim\n");
         return $result_code_NE{NE_ERROR};
      }
      else  # get sim info from Netsim
      {
         setup_netsim_access($ip_address);
         my ($result, $netsim_pipe) = get_netsim_pipe($ip_address);
         return $result if $result;

         my ($sim_result, $sim, $node) = get_sim_data($ip_address, $netsim_pipe);    # find simulation handling this NE
         return $sim_result if $sim_result;  # some error occurred
         
         $logger->info("sim is $sim, node is $node\n");

         # extract MO RDN from FDN
         my ($mo_rdn) = $mo_fdn =~ m/(ManagedElement=.*)$/ or return $result_code_NE{MO_NAME_INVALID};
         $logger->info("MO RDN is $mo_rdn\n");

         # read MO data from Netsim
         my $mo_netsim_data = `rsh -n -l netsim $ip_address "echo 'dumpmotree:moid=\\\"$mo_rdn\\\",dotty;' | $netsim_pipe -q -ne $node -sim $sim"`;
         $logger->debug("MO data from Netsim:\n$mo_netsim_data\n");
         my ($moid) = $mo_netsim_data =~ m/(\d+)\s+\[label/ or return  $result_code_NE{MOID_INVALID};

         $logger->info("MO ID is $moid\n");
         
         return ($result_code_NE{OK}, $moid);
      }
   }
};

if ($@)
{
   $logger->error("NE::Test is unable to get MOID information.\n Error is: $!\n");
}









#
# does an MO exist on the node, for the MO instance given
#
# Arguments:
#   mo         : MO instance                                  [mandatory]
#
# Output:
#   result     : result_code_NE 
#   moid       : the moid if found
#
eval
{
   sub does_mo_exist_NE
   {
    
	 my ($mo) = @_;
      unless ($mo =~ m/\w+/)
      {
        $logger->error("Invalid MO instance, $mo\n");
         return $result_code_NE{MO_NAME_INVALID};
      }
      $logger->debug("MO is $mo\n");
     # not interested if its in the CS
	my $mo_fdn         = mo_name_is_OK($mo, qr/SubNetwork=.*?MeContext=/) or return $result_code_NE{MO_DOESNT_EXIST};
      my ($meContext_id) = $mo_fdn =~ m/SubNetwork.*?MeContext=([^,\s]+)/ or return $result_code_NE{MO_NAME_INVALID};
      my ($ip_result, $ip_address) = get_ip_address($mo_fdn);
      return $result_code_NE{IP_ADDRESS_NOT_FOUND} if $ip_result;
      $logger->info("MO is $mo_fdn, \tIP address is $ip_address\n");

      my $result;

      if ($ip_address =~ m/^159/) # get data from real node, since IP addresses for real nodes start with 159.107
      {
           $logger->info("MO is on  Real node not attempting to create\n");
           
              $logger->error("Mo is on a Real node\n Not attempting to create\n");
      return $result_code_NE{REAL_NODE_ERROR};

      }
      else  # set data on Netsim
      {
         setup_netsim_access($ip_address);

        my ($result, $netsim_pipe) = get_netsim_pipe($ip_address);
         return $result if $result;

         # find simulation handling this NE
         my ($sim_result, $sim, $node) = get_sim_data($ip_address, $netsim_pipe);
         return $sim_result if $sim_result;
         # get the moid of a rdn will show that the mo exits in the code
         
            # extract MO RDN from FDN
            my ($mo_rdn) = $mo_fdn =~ m/(ManagedElement=.*)$/;
            $logger->info("MO RDN is $mo_rdn\n");

 # read MO data from Netsim
            my $mo_netsim_data = `rsh -n -l netsim $ip_address "echo 'dumpmotree:moid=\\\"$mo_rdn\\\",dotty;' | $netsim_pipe -q -ne $node -sim $sim"`;
           $logger->debug("MO data from Netsim:\n$mo_netsim_data\n");
            my $moid = $mo_netsim_data =~ m/(\d+)\s+\[label/ or return  $result_code_NE{MO_DOESNT_EXIST};
         
         $logger->info("MO ID is $moid\n");
         return $result_code_NE{MO_ALREADY_EXISTS};
         }
    
    }
};












# Create an mo in  Netsim for the MO instance given
#
# Arguments:
#   mo         : MO instance (FDN)              [mandatory]
# Output:
#  None mo is created on netsim simulation 
#
eval
{
   sub create_mo_NE
   {
      my %param = ( moid       => "",
                    @_
                  );

      $logger->info("MO is $param{mo}\n") if $param{mo};
      $logger->info("MOID is $param{moid}\n") if $param{moid};

      moid_is_OK($param{moid}) or return;

      my $mo_fdn         = mo_name_is_OK($param{mo}, qr/SubNetwork=.*?MeContext=/) or return;
	#print"eeichrn:$mo_fdn\n";
      my ($meContext_id) = $mo_fdn =~ m/SubNetwork.*?MeContext=([^,\s]+)/ or return;
      $logger->info("mo_fdn is $mo_fdn\nmeContext_id is $meContext_id\n");

      # find IP address for this NE
      unless (exists $ne_ipAddress{$meContext_id})  # was the IP address found already for this node, if not get it
      {
         my $result;
	($result, $ne_ipAddress{$meContext_id}) = get_ip_address($mo_fdn);
         return if $result; # some error occurred
      }
      unless ($ne_ipAddress{$meContext_id})
      {
         $logger->error("Unable to get an IP address for $mo_fdn\n");
         return;
      }
      $logger->info("ip_address is $ne_ipAddress{$meContext_id}\n");
      if ($ne_ipAddress{$meContext_id} =~ m/^159/) # get data from real node, since IP addresses for real nodes start with 159.107
      {
       	$logger->error("This is a real node no attempt will be made to create mos on a real node\n");
         return $result_code_NE{REAL_NODE_ERROR}; ;
      }
      else  # get data from Netsim
      {
        setup_netsim_access($ne_ipAddress{$meContext_id});

         my ($result, $netsim_pipe) = get_netsim_pipe($ne_ipAddress{$meContext_id});
         return $result if $result;

         # find simulation handling this NE
         my ($sim_result, $sim, $node) = get_sim_data($ne_ipAddress{$meContext_id}, $netsim_pipe);
         return $sim_result if $sim_result;

         my $moid = $param{moid};

#### get info for create
 my @typerdn = split(",", $mo_fdn);
   my $typerdn = pop @typerdn;
   my ($mo_class, $mo_id_value) = $typerdn =~ m/(\w+)=(\w+)/;

my $parent_mo = join(",",@typerdn);

         unless ($moid)    # no moid parameter given so use FDN to find it
         {
            # eeichrn: extract MO RDN for parent FDN

            my ($mo_rdn) = $parent_mo =~ m/(ManagedElement=.*)$/;
            $logger->info("MO RDN is $mo_rdn\n");
            # read MO data from Netsim
            my $mo_netsim_data = `rsh -n -l netsim $ne_ipAddress{$meContext_id} "echo 'dumpmotree:moid=\\\"$mo_rdn\\\",dotty;' | $netsim_pipe -q -ne $node -sim $sim"`;
           # $logger->debug("MO data from Netsim:\n$mo_netsim_data\n");
            ($moid) = $mo_netsim_data =~ m/(\d+)\s+\[label/ or return  $result_code_NE{MOID_INVALID};
	#print"moid is $moid\n"
         }
         $logger->info("MO ID is $moid\n");

         # create the mo under the parent
#print "rsh -l netsim $ne_ipAddress{$meContext_id} echo createmo:parentid= $moid type= $mo_class ,name= $mo_id_value; | $netsim_pipe -q -ne $node -sim $sim \n";
       # $logger->info("ne_ipAddress is : $ne_ipAddress{$meContext_id}\n");
       # $logger->info("moid is: $moid \n");
       # $logger->info("mo class is: $mo_class \n");
#	$logger->info("mo id value is: $mo_id_value \n");
#	$logger->info("Net sim pipe is: $netsim_pipe \n");
#	$logger->info("Node is: $node \n");
#	$logger->info("sim is: $sim \n"); 
       my $result1 .= `rsh -n -l netsim $ne_ipAddress{$meContext_id} "echo 'createmo:parentid=\\\"$moid\\\", type=\\\"$mo_class\\\",name=\\\"$mo_id_value\\\";' | $netsim_pipe -q -ne $node -sim $sim"`;
              $logger->info("creating $mo_fdn\n");
            $logger->debug("Result is $result1\n");
        

        return ($result1 and $result1 =~ m/OK/) ? $result_code_NE{OK} : $result_code_NE{NE_ERROR};
      }
   }
};

if ($@)
{
   $logger->error("NE::Test is unable to get MO attributes.\n Error is: $!\n");
}




#
# Delete an mo in  Netsim for the MO instance given
#
# Arguments:
#   mo         : MO instance (FDN)              [mandatory]
# Output:
#  None mo is created on netsim simulation 
#
eval
{
   sub delete_mo_NE
   {
      my %param = ( moid       => "",
                    @_
                  );

      $logger->info("MO is $param{mo}\n") if $param{mo};
      $logger->info("MOID is $param{moid}\n") if $param{moid};

      moid_is_OK($param{moid}) or return;

      my $mo_fdn         = mo_name_is_OK($param{mo}, qr/SubNetwork=.*?MeContext=/) or return;
	#print"eeichrn:$mo_fdn\n";
      my ($meContext_id) = $mo_fdn =~ m/SubNetwork.*?MeContext=([^,\s]+)/ or return;
      $logger->info("mo_fdn is $mo_fdn\nmeContext_id is $meContext_id\n");

      # find IP address for this NE
      unless (exists $ne_ipAddress{$meContext_id})  # was the IP address found already for this node, if not get it

 {
         my $result;
	($result, $ne_ipAddress{$meContext_id}) = get_ip_address($mo_fdn);
         return if $result; # some error occurred
      }
      unless ($ne_ipAddress{$meContext_id})
      {
         $logger->error("Unable to get an IP address for $mo_fdn\n");
         return;
      }
      $logger->info("ip_address is $ne_ipAddress{$meContext_id}\n");
	#print"eeichrn: ip_address is $ne_ipAddress{$meContext_id}\n";
      if ($ne_ipAddress{$meContext_id} =~ m/^159/) # get data from real node, since IP addresses for real nodes start with 159.107
      {
       	$logger->error("This is a real node no attempt will be made to delete mos on a real node\n");
         return $result_code_NE{REAL_NODE_ERROR}; ;
      }
      else  # get data from Netsim
      {
        setup_netsim_access($ne_ipAddress{$meContext_id});

         my ($result, $netsim_pipe) = get_netsim_pipe($ne_ipAddress{$meContext_id});
         return $result if $result;

         # find simulation handling this NE
         my ($sim_result, $sim, $node) = get_sim_data($ne_ipAddress{$meContext_id}, $netsim_pipe);
         return $sim_result if $sim_result;

         my $moid = $param{moid};

#### get info for delete


 unless ($moid)    # no moid parameter given so use FDN to find it
         {
           
            my ($mo_rdn) = $mo_fdn =~ m/(ManagedElement=.*)$/;
            $logger->info("MO RDN is $mo_rdn\n");
            # read MO data from Netsim
            my $mo_netsim_data = `rsh -n -l netsim $ne_ipAddress{$meContext_id} "echo 'dumpmotree:moid=\\\"$mo_rdn\\\",dotty;' | $netsim_pipe -q -ne $node -sim $sim"`;
           # $logger->debug("MO data from Netsim:\n$mo_netsim_data\n");
            ($moid) = $mo_netsim_data =~ m/(\d+)\s+\[label/ or return  $result_code_NE{MOID_INVALID};
         }
         $logger->info("MO ID is $moid\n");


       my $result1 .= `rsh -n -l netsim $ne_ipAddress{$meContext_id} "echo 'deletemo:moid=\\\"$moid\\\";' | $netsim_pipe -q -ne $node -sim $sim"`;
              $logger->info("deleting $mo_fdn\n");
            $logger->debug("Result is $result1\n");
        

        return ($result1 and $result1 =~ m/OK/) ? $result_code_NE{OK} : $result_code_NE{NE_ERROR};
      }
   }
};


if ($@)
{
   $logger->error("NE::Test is unable to get MO attributes.\n Error is: $!\n");
}


#
# Local routines
#
sub get_ip_address
{
   my $mo = shift;

   my ($meContext) = $mo =~ m/(SubNetwork.*?MeContext=[^,\s]+)/ or return $result_code_NE{MO_NAME_INVALID};
   my %meContext_data  =  get_mo_attributes_CS(mo => $meContext, attributes => "ipAddress");
   return $result_code_NE{MO_DOESNT_EXIST} unless %meContext_data;

   if (exists $meContext_data{ipAddress} and $meContext_data{ipAddress} =~ m/^\d+\.\d+\.\d+\.\d+$/)
   {
      $logger->info("ip_address is $meContext_data{ipAddress}\n");
      return ($result_code_NE{OK}, $meContext_data{ipAddress});
   }
   else
   {
      $logger->error("Error reading IP Address for $meContext in cstest\n");
      return $result_code_NE{IP_ADDRESS_NOT_FOUND};
   }
}


sub get_netsim_pipe
{
   my $ip_address = shift;

   my $netsim_version_data = `rsh -n -l netsim $ip_address "ls -lt /netsim/saveconfigurations/*_server_node"`;
   unless ($netsim_version_data)
   {
      $logger->error("Error reading Netsim version data for $ip_address: $!\n");
      return $result_code_NE{NETSIM_VERSION_NOT_FOUND};
   }

   my ($netsim_version) = $netsim_version_data =~ m!/netsim/saveconfigurations/(\w+)_server_node!m;
   unless ($netsim_version)
   {
      $logger->error("Error reading Netsim version for $ip_address: $!\n");
      return $result_code_NE{NETSIM_VERSION_NOT_FOUND};
   }

   my $netsim_pipe = "/netsim/$netsim_version/netsim_pipe";
   $logger->info("netsim_pipe is $netsim_pipe\n");

   return ($result_code_NE{OK}, $netsim_pipe);
}


sub setup_netsim_access
{
   my $ip_address = shift;

   my $access_check = `rsh -n -l netsim $ip_address pwd 2>&1`;
   if ($access_check =~ m/permission denied/m)
   {
      $logger->info("Access to Netsim server denied - need to update .rhosts file on server to allow access\n");
      die "Cannot connect to host $ip_address";
   }
   else
   {
      $logger->info("Access to Netsim server granted\n");
   }
}


sub get_sim_data
{
   my ($ip_address, $netsim_pipe) = @_;
   $logger->debug("ip_address   is $ip_address\nnetsim_pipe  is $netsim_pipe\n");

   # find simulation handling this NE
   my $started_simnes = `rsh -n -l netsim $ip_address "echo .show started | $netsim_pipe -q"`;
   unless ($started_simnes)
   {
      $logger->error("Error reading started SIM data for $ip_address in Netsim: $!\n");
      return $result_code_NE{SIM_INFO_NOT_FOUND};
   }
   $logger->debug("started_simnes is $started_simnes\n");

   my ($node, $sim) = $started_simnes =~ m/(\S+)\s+$ip_address\s+(\S+)/m;
   $logger->debug("node is $node\n") if $node;
   $logger->debug("sim is $sim\n") if $sim;
   unless ($sim or $node)
   {
      $logger->debug("node not found\n") unless $node;
      $logger->debug("sim not found\n") unless $sim;
      $logger->error("Error reading SIM data for $ip_address in Netsim: $!\n");
      return $result_code_NE{SIM_INFO_NOT_FOUND};
   }

   $sim =~ s!/netsim/netsimdir/!!;
   $sim =~ s/#/\\\#/g;                    # escape any hash chars
   $logger->debug("sim is $sim, node is $node\n");

   return ($result_code_NE{OK}, $sim, $node);
}


sub moid_is_OK
{
   my $moid = shift;

   return "OK" unless $moid;   # moid is empty, since it is an optional parameter, this is OK

   unless ($moid =~ m/^\d+$/)
   {
      $logger->error("MO ID is invalid must be digits only - was \"$moid\"\n");
      return;
   }

   return "OK";
}


sub get_moshell
{
   if (my $path_to_moshell = `which moshell`)
   {
      chomp $path_to_moshell;
      $logger->debug("Path to MO shell is $path_to_moshell\n");
      return $path_to_moshell;
   }
   else
   {
      $logger->error("Unable to find moshell in the PATH\n");
      $logger->error("Please update the PATH variable to add the path to the moshell application,\n");
      $logger->error("e.g. if using a bash shell do something like\n   export PATH=\${PATH}:/home/nmsadm/moshell\n");
      $logger->error("or in a tcsh shell\n   setenv PATH \${PATH}:/home/nmsadm/moshell\n\n");
      $logger->error("If moshell is not installed, see instructions at http://utran01.epa.ericsson.se/moshell\n");
      return;
   }
}


sub get_data_from_real_node
{
   my ($mo_fdn, $ip_address, $attributes) = @_;

   my $moshell = get_moshell() or return;

   my ($mo_class, $mo_identity) = $mo_fdn =~ m/,([^,]+)=([^,]+)$/;

   my $attrs = "";
   if ($attributes)
   {
      $attrs .= "^$_\$\|" for split /\s/, $attributes;  # format attribute string for moshell
      chop $attrs;  # remove trailing |
   }

   my $moshell_command = "\'lt ^$mo_class ; get $mo_class=$mo_identity $attrs\'";

   $logger->debug("MO shell command - $moshell $ip_address $moshell_command\n");
   my $mo_data = `$moshell $ip_address $moshell_command`;
   unless ($mo_data)
   {
      $logger->error("Error reading data using moshell, command was \n\t$moshell $ip_address $moshell_command\n");
      return;
   }

   my %result;

   # the MO shell printout has different formats depending on whether any attributes were specified
   if ($attributes)
   {
      while ($mo_data =~ m/$mo_class=$mo_identity[ ]+(\w+)([^\n]+)\n/g)
      {
         my ($attr, $value) = ($1, $2);
         $value =~ s/^\s+//;
         $result{$attr} = $value;
         $logger->debug("Attr - $attr=$value\n");
      }
   }
   else   # extract all attributes returned for the MO
   {
      my $boundary = "=" x 113;           # look for "=======" boundary
      $mo_data =~ s/^.*?$boundary//s;     # strip off everything until boundary
      $mo_data =~ s/^.*?$boundary//s;     # repeat to remove more junk
      $mo_data =~ s/$boundary.*//s;       # remove trailing junk

      while ($mo_data =~ m/(\w+)([^\n]+)\n/g)
      {
         my ($attr, $value) = ($1, $2);
         $value =~ s/^\s+//;
         $result{$attr} = $value;
         $logger->debug("Attr - $attr=$value\n");
      }
   }

   return %result;
}


sub get_data_from_netsim
{
   my ($mo_fdn, $ip_address, $attributes, $meContext_id, $moid) = @_;

   setup_netsim_access($ip_address);

   # find netsim pipe version
   unless ($netsim_pipe)  # was the netsim pipe found already for this node, if not get it
   {
      my $result;
      ($result, $netsim_pipe) = get_netsim_pipe($ip_address);
      return if $result;
      $logger->info("Netsim pipe is $netsim_pipe\n");
   }

   # find simulation handling this NE
   unless (exists $netsim_sim{$meContext_id})  # was the simulation found already for this node, if not get it
   {
      my $result;
      ($result, $netsim_sim{$meContext_id}, $netsim_node{$meContext_id}) = get_sim_data($ip_address, $netsim_pipe);
      return if $result;
   }

   my $mo_netsim_data;

   if ($moid)
   {
      # read MO data from Netsim for MO ID
      $mo_netsim_data = `rsh -n -l netsim $ip_address "echo 'dumpmotree:moid=\\\"$moid\\\",printattrs;' | $netsim_pipe -q -ne $netsim_node{$meContext_id} -sim $netsim_sim{$meContext_id}"`;
      $logger->debug("MO data from Netsim:\n$mo_netsim_data\n");
   }
   else
   {
      # extract MO RDN from FDN
      my ($mo_rdn) = $mo_fdn =~ m/(ManagedElement=.*)$/;
      $logger->debug("MO RDN is $mo_rdn\n");

      # read MO data from Netsim
      $mo_netsim_data = `rsh -n -l netsim $ip_address "echo 'dumpmotree:moid=\\\"$mo_rdn\\\",printattrs;' | $netsim_pipe -q -ne $netsim_node{$meContext_id} -sim $netsim_sim{$meContext_id}"`;
      $logger->debug("MO data from Netsim:\n$mo_netsim_data\n");
   }

   my %result;
   if ($attributes)
   {
      for my $attr (split /\s/, $attributes)
      {
         my ($value) = $mo_netsim_data =~ m/\b$attr=(\S+)/i;
         $value = "" unless defined $value; # set to null string if no value found
         $result{$attr} = $value;
         $logger->debug("\tAttr $attr=$value\n");
      }
   }
   else
   {
      while ($mo_netsim_data =~ m/^\s(\S+)=(\S+)/gm)
      {
         $result{$1} = $2;
         $logger->debug("\tAttr $1=$2\n");
      }
   }

   return %result;
}





1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

NE::Test - A perl module for accessing the Network Element (NE) information using Netsim for simulated nodes or Moshell for real nodes.

=head1 SYNOPSIS

 use lib '/net/atrnjump/share/guitest/perl/lib';
 use NE::Test;

 my $mo = 'SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,UtranCell=RNC01-10-2';

 my %mo_hash = get_mo_attributes_NE( mo => $mo, attributes => 'cId pwrAdm qRxLevMin locationAreaRef' );

 print "$mo\n";

 for my $attr (sort keys %mo_hash)
 {  
    printf "   %-30s : %s\n", $attr, $mo_hash{$attr};
 }

=head1 DESCRIPTION

This module is intended for perl script authors who wish to access the network element information.

The module provides a number of functions which simplify the handling of reading/writing information to/from the NE.

The functions allow the getting and setting of MO attributes, and also allow a netsim command to be sent to the
Netsim server.

The module uses a Netsim interface when accessing simulated nodes and moshell when accessing real nodes.

The IP address in the MeContext MO is used to distinguish between real and simulated nodes.

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

=head2 get_mo_attributes_NE

This function returns the requested attributes (or all attributes) for a given MO from the NE.
The full syntax of the function call is:

 get_mo_attributes_NE( mo         => $mo, 
                       moid       => $moid;
                       attributes => "space separated list of attrs");

The parameters have the following types:

=over 3

=item mo - a string indicating an MO FDN, e.g. 'SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01'

=item moid - an integer indicating an moid, e.g. '1234'

=item attributes - a string containing a space separated list of attribute names, e.g. 'cId pwrAdm qRxLevMin'

=back

However, all the parameters are optional, except for 'mo', since there are default values for these.
The defaults have the effect of fetching all attributes for the given MO.
So, the function may be called with just the MO FDN in the 'mo' parameter, e.g.

 get_mo_attributes_NE(mo => "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01");

and all attributes for this MeContext MO will be fetched from the NE.

If the only attribute wanted was the userLabel, then the following could be used:

 get_mo_attributes_NE(mo => "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01", attributes => "userLabel");

The returned values are in the form of a hash, so to access the IP address attribute:

 my %mo_hash = get_mo_attributes_NE(mo => "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01", attributes => "userLabel");

 print "User label is $mo_hash{userLabel}\n";

To print out all the MeContext MO attributes:

 my %mo_hash = get_mo_attributes_NE(mo => "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01");
 for my $attr (sort keys %mo_hash)
 {
   printf "   %-30s : %s\n", $attr, $mo_hash{$attr};
 }


If the 'moid' is given, then this will be used instead of the 'mo' to fetch the attributes.
In this case the 'mo' parameter is only required to get the IP address from the MeContext MO
on order to find out which remote machine to contact.

=head2 set_mo_attributes_NE

This function sets the requested attributes for a given MO in the NE.
The full syntax of the function call is:

 set_mo_attributes_NE( mo         => $mo, 
                       attributes => "space separated list of name value pairs");

The 'mo' and 'attributes' parameters are mandatory.

The parameters have the following types:

=over 3

=item mo - a string indicating an MO FDN, e.g. 'SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01'

=item attributes - a string containing a space separated list of attribute name value pairs, e.g. 'cId 10 pwrAdm 75 qRxLevMin -115'

=back

The return value is either $result_code_NE{OK} which means that the set worked OK, or a result code indicating the error cause.

So, to set the userLabel to 'my_RNC';

 my $result = set_mo_attributes_NE( mo => "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01", attributes => "userLabel my_RNC" );
 if ($result)
 {
    print "result code is $result\n";
 }
 else
 {
    print "Attributes set OK\n";
 }


=head2 do_netsim_command

This function sets the requested attributes for a given MO in the NE.
The full syntax of the function call is:

 do_netsim_command( $command, $mo, $sim, $node );

The 'mo' and 'command' parameters are mandatory.

The parameters have the following types:

=over 3

=item mo - a string indicating an MO FDN, e.g. 'SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01'

=item command - a string containing a valid Netsim command, e.g. '.stop'

=item sim - a string containing a valid sim name, e.g. 'Wal-C3-notransport-RNC01'

=item node - a string containing a valid node name, e.g. 'RNC01'

=back

The return value is either $result_code_NE{OK} which means that the command worked OK, or a result code indicating the error cause.

Example usage:

 my $result = do_netsim_command(".show simnes", "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01");

 if ($result)
 {
   print "Error code is $result, error message is $result_string_NE{$result}\n";
 }
 else
 {
   print "Netsim command OK\n";
 }


=head2 get_moid

This function gets the moid for a given MO in the NE.
The full syntax of the function call is:

 get_moid( $mo );

The 'mo' parameter is mandatory.

The parameters have the following types:

=over 3

=item mo - a string indicating an MO FDN, e.g. 'SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01'

=back

The return value is either $result_code_NE{OK} and the moid if the moid was found, or a result code indicating the error cause.

So, to get the moid;

 my ($result, $moid) = get_moid( "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01" );
 if ($result)
 {
   print "Error code is $result, error message is $result_string_NE{$result}\n";
 }
 else
 {
   print "moid is $moid\n";
 }

=head2 get_sim_info

This function gets the sim and node information for a given MO in the NE.
The full syntax of the function call is:

 get_sim_info( $mo );

The 'mo' parameter is mandatory.

The parameters have the following types:

=over 3

=item mo - a string indicating an MO FDN, e.g. 'SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01'

=back

The return value is either $result_code_NE{OK} and the sim and node were found, or a result code indicating the error cause.

So, to get the moid;

 my ($result, $sim, $node) = get_sim_info( "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01" );
 if ($result)
 {
   print "Error code is $result, error message is $result_string_NE{$result}\n";
 }
 else
 {
   print "sim is $sim, node is $node\n";
 }

=head2 %result_code_NE

This is a hash containing the result codes returned from the module.
Allows use of an error string key as a test condition in evaluating results, e.g.

 my $result= set_mo_attributes_NE( mo => "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01", attributes => "userLabel my_rnc" );
 if ($result == $result_code_NE{MO_DOESNT_EXIST})
 {
   print "MO doesn't exist: Error code is $result, error message is $result_string_NE{$result}\n";
 }
 elsif ($result)  # some other error 
 {
   print "Error code is $result, error message is $result_string_NE{$result}\n";
 }
 else
 {
   print "User label attribute set OK\n";
 }


=head2 %result_string_NE

This is a hash containing the result strings returned from the module.
The string can be accessed by using the result code as the key, i.e.

 my ($result, $sim, $node) = get_sim_info( "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01" );
 if ($result)
 {
   print "Error code is $result, error message is $result_string_NE{$result}\n";
 }
 else
 {
   print "sim is $sim, node is $node\n";
 }



=head1 AUTHOR

Copyright LM Ericsson Ireland.

=head1 SEE ALSO

perl(1).

=cut
