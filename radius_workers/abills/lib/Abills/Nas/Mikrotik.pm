package Abills::Nas::Mikrotik;
use strict;
use warnings FATAL => 'all';

use Abills::Base qw(_bp cmd);
require "Abills/Misc.pm";

my %BP_ARGS = ( TO_CONSOLE => 1 );
#**********************************************************
=head2 new() - Constructor

=cut
#**********************************************************
sub new($;$) {
  my $class = shift;
  my ($host, $CONF, $attr) = @_;

  my $self = { };
  bless( $self, $class );

  my $nas_ip_mng_port = $host->{nas_mng_ip_port} || $host->{NAS_MNG_IP_PORT} || return 0;
  my ($nas_ip, $coa_port, $ssh_port) = split( ":", $nas_ip_mng_port );
  $ssh_port ||= $coa_port || '22';

  $self->{backend} = $attr->{backend} || (($ssh_port eq '8728') ? 'api' : 'ssh');
  $self->{ip_address} = $nas_ip || $host->{NAS_IP};
  $self->{login} = $host->{nas_mng_user} || $host->{NAS_MNG_USER} || '';

  if ( $self->{backend} eq 'ssh' ) {
    require Abills::Nas::Mikrotik::SSH;
    Abills::Nas::Mikrotik::SSH->import();
    $self->{executor} = Abills::Nas::Mikrotik::SSH->new( $host, $CONF, $attr );
  }
  elsif ( $self->{backend} eq 'api' ) {
    require Abills::Nas::Mikrotik::API;
    Abills::Nas::Mikrotik::API->import();
    $self->{executor} = Abills::Nas::Mikrotik::API->new( $host, $CONF, $attr );
  }
  else {
    return 0;
  }

  $self->{nas_type} = $host->{nas_type};

  # Allowing to use custom messages
  if ( $attr->{MESSAGE_CALLBACK} && ref $attr->{MESSAGE_CALLBACK} eq 'CODE' ) {
    $self->{message_cb} = $attr->{MESSAGE_CALLBACK};
  }
  else {
    $self->{message_cb} = sub { print shift };
  }

  # Configuring debug options
  $self->{debug} = 0;
  if ($attr->{DEBUG}){
    $self->{debug} = $attr->{DEBUG};
    if ($attr->{FROM_WEB}) {
      delete $BP_ARGS{TO_CONSOLE};
      $BP_ARGS{TO_WEB_CONSOLE} = 1;
    }
  }


  if ( !ref($self->{executor}) && !$self->{executor} ) {
    return 0;
  }

  return $self;
}

#**********************************************************
=head2 execute($command) -

  Arguments:
    $command -

  Returns:
    1 - if success

=cut
#**********************************************************
sub execute {
  my $self = shift;
  return $self->{executor}->execute(@_);
}

#**********************************************************
=head2 has_access()

=cut
#**********************************************************
sub has_access {
  my $self = shift;

  my $has_access = $self->{executor}->check_access();

  if ($has_access == -5 && $self->{backend} eq 'ssh'){
      $self->generate_key($self->{login});
  }

  return $has_access;
}

#**********************************************************
=head2 generate_key($admin_name) - generates SSH key

  Arguments:
    $admin_name - name for admin ( for key name )

  Returns:
    1 - if generated

=cut
#**********************************************************
sub generate_key {
  my $self = shift;
  my ( $admin_name ) =  @_;

  our $base_dir;
  $base_dir ||= '/usr/abills';

  my $cmd = qq { $base_dir/misc/certs_create.sh ssh $admin_name SKIP_CERT_UPLOAD };
  system ( $cmd );

  return 1;
}

#**********************************************************
=head2 upload_key($attr) - uploads key for remote ssh management

  Arguments:
    $attr - hash_ref
      ADMIN_NAME    - admin to upload key for. Will be created if not exists
      SYSTEM_ADMIN  - current active admin
      SYSTEM_PASSWD - current password

  Returns:
    1 - if success

=cut
#**********************************************************
sub upload_key {
  my $self = shift;
  my ($attr) = @_;

  if ( !$self->{backend} eq 'api' ) {
    print " !!! Only API supported \n";
    return 0;
  }

  return $self->{executor}->upload_key( $attr );
}

#**********************************************************
=head2 get_error() - returns inner executor error

=cut
#**********************************************************
sub get_api_error {
  my $self = shift;

  return $Abills::Nas::Mikrotik::errstr;
}

#**********************************************************
=head2 get_list($list_name, $attr) - forwarding request to executor

  Arguments:
    $list_name - one of predefined commands

  Returns:
   list

=cut
#**********************************************************
sub get_list {
  my $self = shift;
  return $self->{executor}->get_list( @_ );
}

#**********************************************************
=head2 interfaces_list($filter)

  Arguments:
    $filter - hash_ref

  Returns:
  list of interfaces (filtered if filter defined)

=cut
#**********************************************************
sub interfaces_list {
  my $self = shift;
  my ($filter) = @_;

  my $interfaces_list = $self->get_list( 'interfaces' );

  return [ ] unless ($interfaces_list);

  if ( defined $filter && ref $filter eq 'HASH' ) {

    my @result_list = @{$interfaces_list};
    foreach my $filter_key ( keys %{$filter} ) {
      @result_list = grep { $_->{$filter_key} && $_->{$filter_key} eq $filter->{$filter_key} } @result_list;
    }

    return \@result_list;
  }

  return $interfaces_list;
}

#**********************************************************
=head2 addresses_list()

=cut
#**********************************************************
sub addresses_list {
  my $self = shift;

  return $self->get_list( 'addresses' );
}

#**********************************************************
=head2 adverts_list($attr) - get hotspot adverts for default user profile

=cut
#**********************************************************
sub adverts_list {
  my $self = shift;
  my $attr = shift;
  return $self->get_list('adverts', $attr);
}

#**********************************************************
=head2 leases_list() - returns leases from mikrotik

  Arguments:
    $mikrotik - Mikrotik object

  Returns:
    list

=cut
#**********************************************************
sub leases_list {
  my ($self, $attr) = @_;

  my $mikrotik_leases_list = $self->{executor}->get_list( 'dhcp_leases_generated', $attr );
  _bp( "leases arr", $mikrotik_leases_list, \%BP_ARGS ) if ($attr->{DEBUG});

  return $mikrotik_leases_list;
}

#**********************************************************
=head2 remove_leases($leases_ids_list, $attr)

  Arguments:
    $leases_ids_list - array_ref of IDs to delete
    $attr - hash_ref
    
  Returns:
    boolean

=cut
#**********************************************************
sub remove_leases {
  my ($self, $leases_ids_list, $attr) = @_;

  return 1 if ( scalar ( @{$leases_ids_list} == 0 ) );

  my @cmd_arr = ();
  my $del_cmd_chapter = 'ip dhcp-server lease remove';
  foreach my $lease_id ( @{$leases_ids_list} ) {
    print "Removing lease id $lease_id \n" if ($attr->{VERBOSE});
    push ( @cmd_arr, [ $del_cmd_chapter, [ "numbers=$lease_id" ] ]);
  }

  return $self->{executor}->execute( \@cmd_arr, { CHAINED => 1, SKIP_ERROR => 1, DEBUG => $attr->{DEBUG} } );
}


#**********************************************************
=head2 add_leases($leases_list, $attr)

  Arguments:
    $leases_list - list of leases in DB format
      [
       {
         tp_tp_id
         network
         mac
         ip
       }
      ]
    $attr
      SKIP_DHCP_NAME - add lease for all DHCP servers
      VERBOSE - be verbose
      DEBUG

  Returns:
    1

=cut
#**********************************************************
sub add_leases {
  my ($self, $leases_list, $attr) = @_;

  return 1 if ( scalar ( @{$leases_list} == 0 ) );

  my @cmd_arr = ();

  foreach my $lease ( @{$leases_list} ) {

    my $address_list_arg = "";
    #    if ( !$lease->{active} || $lease->{active} != 1 ){
    #      $address_list_arg .= "negative";
    #    }
    if ( !$lease->{tp_tp_id} ) {
      print " !!! Tarriff plan not selected for $lease->{login}. Skipping \n";
      next;
    } else {
      $address_list_arg = "address-list=CLIENTS_$lease->{tp_tp_id}";
    }

    my $dhcp_server_name = "dhcp_abills_network_$lease->{network}";

    if ( $attr->{SKIP_DHCP_NAME} ) {
      $dhcp_server_name = 'all';
    }
    else {
      if ( $attr->{USE_NETWORK_NAME} ) {
        $dhcp_server_name = $lease->{network_name};
      } elsif ( $attr->{DHCP_NAME_PREFIX} ) {
        $dhcp_server_name = "$attr->{DHCP_NAME_PREFIX}_$lease->{network}";
      }
    }

    print "Adding new lease address=$lease->{ip} mac-address=$lease->{mac} \n" if ($attr->{VERBOSE});

    my $cmd = "/ip dhcp-server lease add address=$lease->{ip} mac-address=$lease->{mac} server=$dhcp_server_name disabled=no $address_list_arg comment=\"ABillS generated\"";
    push ( @cmd_arr, $cmd );
  }

  return $self->{executor}->execute( \@cmd_arr, { CHAINED => 1, DEBUG => $attr->{DEBUG} } );
}

#**********************************************************
=head2 remove_all_generated_leases($nas, $attr)

  Arguments:
    $nas - nases table line
    $attr - hash_ref

  Returns:
   1 if success

=cut
#**********************************************************
sub remove_all_generated_leases {
  my ($self, $attr) = @_;

  # Skipping non-mikrotik NASes
  return 0 unless ($self->{nas_type} =~ /mikrotik/);

  my $mikrotik_leases = $self->leases_list( $attr );
  _bp( "Leases to delete", $mikrotik_leases, \%BP_ARGS ) if ($attr->{DEBUG});

  my @leases_to_delete_ids = ();
  foreach my $lease ( @{$mikrotik_leases} ) {
    push ( @leases_to_delete_ids, $lease->{id} );
  }

  return $self->remove_leases( \@leases_to_delete_ids, $attr );
}


#**********************************************************
=head2 check_dhcp_servers($networks, $attr)

  Arguments:
    $mikrotik - Mikrotik object
    $networks - networks list from DB

  Returns:
    1

=cut
#**********************************************************
sub check_dhcp_servers {
  my $self = shift;
  my ($networks, $attr) = @_;

  return $networks if ($attr->{SKIP_DHCP_NAME});
  my $DHCP_server_name_prefix = ($attr->{DHCP_NAME_PREFIX}) ? $attr->{DHCP_NAME_PREFIX} : "dhcp_abills_network_";

  my $servers_list = $self->{executor}->get_list( 'dhcp_servers' );

  my %servers_by_name = ();
  foreach my $server ( @{$servers_list} ) {
    $servers_by_name{ lc $server->{name}} = $server;
  }

  for ( my $i = 0; $i < scalar @{$networks}; $i++ ) {
    my $network = $networks->[$i];

    my $network_identifier = ($attr->{USE_NETWORK_NAME}) ? $network->{name} : "$DHCP_server_name_prefix$network->{id}";

    print "Checking for existence of $network_identifier \n" if ($attr->{VERBOSE} > 1);

    unless ( defined $servers_by_name{lc $network_identifier} ) {
      print " !!! You should add '$network_identifier' DHCP server at mikrotik or use SKIP_DHCP_NAME=1
                You also can use DHCP_NAME_PREFIX=\"\" to specify prefix
                or use USE_NETWORK_NAME=1 to use network names as identifier
                Leases for this network will be skipped!\n";
      splice @{$networks}, $i, 1;
      $i--;
    }
  }

  if ( $attr->{USE_ARP} || $attr->{DISABLE_ARP} ) {
    my $numbers = '';

    if ( $attr->{USE_NETWORK_NAME} ) {
      $numbers = join(',', map {$_->{name}} @{$networks});
    }
    else {
      foreach my $network ( @{$networks} ) {
        $numbers .= $servers_by_name{"$DHCP_server_name_prefix$network->{id}"}->{number};
      }
    }

    my $set_value = ($attr->{USE_ARP}) ? 'yes' : 'no';

    my $command = "/ip dhcp-server set add-arp=$set_value numbers=$numbers";

    if ( my $result = $self->{executor}->execute( $command ) ) {
      print "  add-arp set to: $set_value \n";
    }
    else {
      print "  !!! add-arp set failed : $result";
    };
  }

  _bp( "size of network list", scalar @{$networks}, \%BP_ARGS ) if ($attr->{DEBUG});

  return $networks;
}

sub check_defined_networks {
  my ($self, $networks, $attr) = @_;

  my $mikrotik_networks = $self->{executor}->get_list( 'dhcp_servers' );

  #Sort by network address
  my %networks_by_address = ();
  foreach my $network ( @{$mikrotik_networks} ) {
    $networks_by_address{$network->{address}} = $network;
  }

  for ( my $i = 0; $i < scalar @{$networks}; $i++ ) {
    my $network = $networks->[$i];

    #    unless ( defined $servers_by_name{lc "dhcp_abills_network_$network->{id}"} ){
    #      print " !!! You should add 'dhcp_abills_network_$network->{id}' DHCP server at mikrotik or use SKIP_DHCP_NAME=1 \n     Leases for this network will be skipped!\n";
    #      splice @{$networks}, $i, 1;
    #      $i--;
    #    }
  }
}
#**********************************************************
=head2 configure_hotspot(\%arguments)

  Arguments:
    $arguments - hash_ref
      INTERFACE            - interface to apply hotspot firewall rules
      DHCP_RANGE           - range of client addresses
      ADDRESS              - local IP address for hotspot interface
      NETWORK              - hotspot network
      NETMASK              - hotspot network bits length
      GATEWAY              - WAN interface gateway
      DNS
      DNS_NAME             - name that clients are redirected to
      BILLING_IP_ADDRESS   - radius IP address
      RADIUS_SECRET

=cut
#**********************************************************
sub configure_hotspot {
  my $self = shift;
  my ($arguments) = @_;

  my $interface = $arguments->{INTERFACE};
  my $range = $arguments->{DHCP_RANGE};
  my $address = $arguments->{ADDRESS};
  my $network = $arguments->{NETWORK};
  my $netmask = $arguments->{NETMASK};
  my $gateway = $arguments->{GATEWAY};
  my $dns_server = $arguments->{DNS};

  my $dns_name = $arguments->{DNS_NAME};
  my $pool_name = "hotspot-pool-1";

  my $radius_address = $arguments->{BILLING_IP_ADDRESS};
  my $radius_secret = $arguments->{RADIUS_SECRET};

  $self->execute(
    [
      # Configure WAN
      [
        '/ip/address/add', {
          address   => "$address/$netmask",
          comment   => "HOTSPOT",
          disabled  => "no",
          interface => $interface,
          network   => $network
        }
      ],

      [
        '/ip/route/add', {
          disabled       => "no",
          distance       => 1,
          'dst-address'  => '0.0.0.0/0',
          gateway        => $gateway,
          scope          => 30,
          'target-scope' => 10
        }
      ],

      # ADD IP pool for hotspot users
      [
        '/ip/pool/add',
        { name => 'hotspot-pool-1', ranges => $range }
      ],

      # Add DNS for resolving
      [ '/ip/dns/set', {
          'allow-remote-requests' => 'yes',
          'cache-max-ttl'         => "1w",
          'cache-size'            => '10000KiB',
          'max-udp-packet-size'   => 512,
          'servers'               => "$address,$dns_server"
        }
      ],
      [
        '/ip/dns/static/add', {
          name    => "$dns_name",
          address => $address
        }
      ],

      # Add DHCP Server
      [
        '/ip/dhcp-server/add', {
          'address-pool'  => 'hotspot-pool-1',
          authoritative   => 'after-2sec-delay',
          'bootp-support' => 'static',
          'disabled'      => 'no',
          interface       => $interface,
          'lease-time'    => '1h',
          name            => 'hotspot_dhcp'
        }
      ],

      [ '/ip/dhcp-server/config/set', { 'store-leases-disk' => '5m' } ],

      [ '/ip/dhcp-server/network/add', {
          address => "$network/$netmask",
          comment => "Hotspot network",
          gateway => $address
        }
      ],
      # Prevent blocking ABillS Server
      #      qq{/ip hotspot ip-binding add address=$radius_address type=bypassed},
      [ '/ip/firewall/nat/add', {
          chain         => 'pre-hotspot',
          'dst-address' => $radius_address,
          action        => 'accept'
        }
      ],
    ],
    {
      SHOW_RESULT => 1,
      SKIP_ERROR  => 1,
      CHAINED     => 1
    }
  );

  $self->{message_cb}( "\n Configuring Hotspot \n" );

  $self->execute(
    [
      # Add HOTSPOT profile
      [ '/ip/hotspot/profile/add',
        { name                   => 'hsprof1',
          'dns-name'             => $dns_name,
          'hotspot-address'      => $address,
          'html-directory'       => 'hotspot',
          'http-cookie-lifetime' => '1d',
          'http-proxy'           => "0.0.0.0:0",
          'login-by'             => "cookie,http-chap",
          'rate-limit'           => "",
          'smtp-server'          => "0.0.0.0",
          'split-user-domain'    => "no",
          'use-radius'           => "yes"
        }
      ],
      [ '/ip/hotspot/add',
        { name                => 'hotspot1',
          'address-pool'      => $pool_name,
          'addresses-per-mac' => 2,
          disabled            => "no",
          'idle-timeout'      => "5m",
          interface           => $interface,
          'keepalive-timeout' => "none",
          profile             => "hsprof1" }
      ],
      [ '/ip/hotspot/user/profile/set',
        {
          'idle-timeout'       => 'none',
          'keepalive-timeout'  => '2m',
          'shared-users'       => 1,
          'status-autorefresh' => '1m',
          'transparent-proxy'  => 'no'
        },
        {
          name                 => 'default',
        }
      ],
      ['/ip/hotspot/service-port/set',
        {
          disabled => "yes",
          ports    => 21
        },
        {
          name => "ftp",
        }
      ],
      [ '/ip hotspot walled-garden ip add', {
          action        => "accept",
          disabled      => "no",
          'dst-address' => $address
        }
      ],
      [ '/ip hotspot walled-garden ip add', {
          action        => 'accept',
          disabled      => "no",
          'dst-address' => $radius_address
        }
      ],
      [ '/ip hotspot set', {
          numbers        => 'hotspot1',
          'address-pool' => 'none'
        }
      ],
      [ '/ip firewall nat add', {
          action   => "masquerade",
          chain    => "srcnat",
          disabled => "no"
        }
      ]
    ],
    {
      SHOW_RESULT => 1,
      SKIP_ERROR  => 1,
    }
  );

  $self->{message_cb}( "\n  Configuring RADIUS\n" );

  $self->execute(
    [
      [ "/radius add", { address => $radius_address, secret => $radius_secret, service => "hotspot" } ],
      [ "/ip hotspot profile set", { 'use-radius' => 'yes' }, {name => 'hsprof1'} ],
      [ "/radius set", { timeout => '00:00:01', numbers => '0' } ]
    ],
    {
      SHOW_RESULT => 1,
      SKIP_ERROR  => 1,
    }
  );

  $self->{message_cb}( "\n Configuring Hotspot walled-garden \n" );

  my @walled_garden_hosts = (
    $radius_address,
    $dns_server
  );

  if ( $arguments->{WALLED_GARDEN} && ref $arguments->{WALLED_GARDEN} eq 'ARRAY' ) {
    push( @walled_garden_hosts, @{ $arguments->{WALLED_GARDEN} } );
  };

  my @walled_garden_commands = ();
  foreach ( @walled_garden_hosts ) {
    push( @walled_garden_commands, [ '/ip hotspot walled-garden add', { 'dst-host' => $_ } ]);
  }

  $self->execute(
    \@walled_garden_commands,
    {
      SHOW_RESULT => 1,
      SKIP_ERROR  => 1,
    }
  );

  $self->{message_cb}( "\n Uploading custom captive portal \n" );

  #First of all we need move files to /tmp to prevent access restrictions

  my $hotspot_temp_dir = '/tmp/abills_';
  cmd("mkdir $hotspot_temp_dir");

  my $command = "cp $main::base_dir/misc/hotspot/hotspot.tar.gz $hotspot_temp_dir/hotspot.tar.gz";
  $command .= " && cd $hotspot_temp_dir && tar -xvf hotspot.tar.gz;";

  _bp("Unpacking portal files", "$command", \%BP_ARGS) if ($self->{debug} > 1);

  cmd ( $command );

  if ( $radius_address ne '10.0.0.2' ) {

    $self->{message_cb}( "\n  Renaming Billing URL \n" );

    my $temp_file = '/tmp/hotspot_temp';
    my $login_page = "$hotspot_temp_dir/hotspot/login.html";

    # Cat and sed to temp file
    $command = "cat $login_page | sed 's/10\.0\.0\.2/$radius_address/g' > $temp_file";
    _bp("renaming 1", "$command", \%BP_ARGS) if ($self->{debug} > 1);
    print cmd( $command );

    # Cat back to normal file
    $command = "cat $temp_file > $login_page";
    _bp("Renaming 2", "$command", \%BP_ARGS) if ($self->{debug} > 1);
    print cmd( $command );
  }

  my $ssh_remote_admin = $self->{executor}->{admin} || 'abills_admin';
  my $ssh_remote_host = $self->{executor}->{host};
  my $ssh_remote_port = $self->{executor}->{ssh_port} || 22;
  my $ssh_cert = $self->{executor}->{ssh_key} || '';

  my $scp_file = $arguments->{SCP_FILE};
  unless ( $scp_file ) {
    $scp_file = cmd ( "which scp" );
    chomp( $scp_file );
  }

  my $port_option = '';
  if ( $ssh_remote_port != 22 ) {
    $port_option = "-P $ssh_remote_port";
  }

  my $cert_option = '';
  if ( $ssh_cert ne '' ) {
    $cert_option = "-i $ssh_cert -o StrictHostKeyChecking=no";
  }

  $command = "cd $hotspot_temp_dir && ";
  $command .= "$scp_file $port_option $cert_option -B -r hotspot $ssh_remote_admin\@$ssh_remote_host:/ && rm -rf hotspot";

  $self->{message_cb}( "\n  Uploading captive portal files \n" );

  _bp("Upload files", "Executing cmd : $command \n", \%BP_ARGS) if ($self->{debug} > 1);

  cmd( $command );

  return 1;

}

#**********************************************************
=head2 radius_add($host, $attr) - adds first radius server

  Arguments:
    $host - ip address
    $attr - hash_ref
      RADIUS_SECRET - use special radius secret, instead of given in host params
      COA           - port for listening COA requests (3799)
      REPLACE       - if server exists, delete it and set with given params
      SERVICES      - services to use with this radius (hotspot, ppp, dhcp)
    
  Returns:
    1 - if success
    
=cut
#**********************************************************
sub radius_add {
  my $self = shift;
  my ($host, $attr) = @_;
  
  return 0 if (!$host);
  
  # Check if there's no radius servers yet
  my $existing_servers = $self->get_list('radius');
  
  if ( my @existing = grep { $_->{address} && $_->{address} eq $host } @{$existing_servers} ) {
    
    # Already exists
    return 1 if (!$attr->{REPLACE});
    
    # Delete all
    my @delete_radius_commands = map {
      [ '/radius remove', { numbers => $_->{id} } ]
    } @existing;
    
    $self->execute(
      \@delete_radius_commands,
      {
        SHOW_RESULT => 1
      }
    );
  }
  
  my $secret = $attr->{RADIUS_SECRET} || $self->{nas_mng_password} || 'secretpass';
  my $coa = $attr->{COA} || 3799;
  my $services = $attr->{SERVICES} || 'hotspot,ppp,dhcp';
  
  $self->execute(
    [
      [ "/radius add", { address => $host, secret => $secret, service => $services } ],
      [ "/radius incoming set", { accept => 'yes', port => $coa } ],
    ],
    {
      SHOW_RESULT => 1,
      SKIP_ERROR  => 1,
    }
  );
  
  return 1;
}

##**********************************************************
#=head2 is_rechable($ip_address) - pings given address 3 times
#
#  Returns:
#    boolean - true if 3 packets received back
#
#=cut
##**********************************************************
#sub is_reachable{
#  my $self = shift;
#
#  my @cmd = ("ping", "-c 3", "-q",  "$self->{ip_address}");
#  my $res = system(@cmd);
#  my $is_rechable = $res =~ /3 received/;
#
#  return $is_rechable;
#}
1;