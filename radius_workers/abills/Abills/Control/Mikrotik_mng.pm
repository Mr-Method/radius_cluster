use strict;
use warnings FATAL => 'all';

our (@state_colors, $db, %lang, $base_dir, %conf);
our Abills::HTML $html;
our Admins $admin;

use Nas;
my $Nas = Nas->new($db, \%conf, $admin);

require Abills::Nas::Mikrotik;

use Abills::Experimental;

#**********************************************************
=head2 mikrotik_configure()

=cut
#**********************************************************
sub mikrotik_configure {
  my ($Nas_) = @_;
  
  my %connection_types = (
    pppoe           => 'PPPoE',
    pptp            => 'PPTP(VPN)',
    freeradius_dhcp => 'Freeradius DHCP'
  );
  
  $html->message('info', "Mikrotik $lang{CONFIGURATION}");
  
  ### Step 0 : check access ###
  my Abills::Nas::Mikrotik $mikrotik = _mikrotik_init_and_check_access($Nas_, {
      DEBUG => 3
    });
  
  if (!$mikrotik) {
    return 0;
  };
  
  if ($FORM{action}){
    $mikrotik->radius_add($FORM{RADIUS_IP}, {REPLACE => 1});
    
  }
  

  ### Step 1 : Select connection type ###
  my $connection_type_select = $html->form_select('CONNECTION_TYPE', {
      SEL_LIST => [ map { { id => $_, name => $connection_types{$_} } } sort keys %connection_types ],
      SELECTED => $FORM{CONNECTION_TYPE} || ''
    });
  my $connection_type_label = $html->element('label', $lang{CONNECTION_TYPE}, { class => 'control-label' });
  
  print $html->element('div', $html->form_main(
      {
        CONTENT => $connection_type_label . " : " . $connection_type_select,
        HIDDEN  => { index => "$index", subf => $FORM{subf} || 0, mikrotik_configure => 1, NAS_ID => $FORM{NAS_ID} },
        SUBMIT  => { go => $lang{CHOOSE} },
        METHOD  => 'GET',
        class   => 'form navbar-form'
      }
    ), { class => 'well well-sm' });
  
  return 0 if (!$FORM{CONNECTION_TYPE});
  
  
  ### Step 2 : show template ###
  my @ip_addresses = ($ENV{HTTP_HOST});
  my $interfaces = local_network_interfaces_list();
  if ( $interfaces && ref $interfaces eq 'HASH' ) {
    foreach my $interface_name ( sort keys %{$interfaces} ) {
      if ( exists $interfaces->{$interface_name}->{ADDR} && defined $interfaces->{$interface_name}->{ADDR} ) {
        push @ip_addresses, $interfaces->{$interface_name}->{ADDR};
      }
    }
  }
  
  my %local_if_select_args = (
    SEL_ARRAY   => \@ip_addresses,
    SELECTED    => $ENV{HTTP_HOST} || '',
    NO_ID       => 1,
    EX_PARAMS   => ' data-input-disables=RADIUS_IP_CUSTOM ',
    SEL_OPTIONS => { '' => '' }
  );
  
  my %template_args = (
    DNS          => '8.8.8.8',
    USE_NAT      => 1,
    FLOW_PORT    => '9996',
    EXTRA_INPUTS => ''
  );
  
  my $make_form_row = sub {
    $html->tpl_show(templates('form_row_dynamic_size'),
      {
        COLS_LEFT  => 'col-md-3',
        COLS_RIGHT => 'col-md-9',
        ID         => $_[0],
        NAME       => $_[1],
        VALUE      => $_[2]
      }
      , { OUTPUT2RETURN => 1 });
  };
  
  my $make_input = sub {
    my $input = $html->form_input($_[0], $_[1], { OUTPUT2RETURN => 1 });
    $make_form_row->( $_[0], $_[2], $input );
  };
  
  if ( $FORM{CONNECTION_TYPE} eq 'pppoe' ) {
    my $remote_interfaces = $mikrotik->interfaces_list();
    if ($remote_interfaces && ref $remote_interfaces eq 'ARRAY' && scalar @$remote_interfaces){
      my $interface_select = $html->form_select('PPPOE_INTERFACE', {
          SEL_LIST => $remote_interfaces,
          SEL_KEY => 'name',
          SEL_NAME => 'name',
          
          NO_ID => 1
        });
      $template_args{EXTRA_INPUTS} .= $make_form_row->('PPPOE_INTERFACE', $lang{INTERFACE}, $interface_select);
    }
  }
  elsif ( $FORM{CONNECTION_TYPE} eq 'pptp' ) {
    
  }
  elsif ( $FORM{CONNECTION_TYPE} eq 'freeradius_dhcp' ) {
    my $flow_ip_select = $html->form_select('FLOW_COLLECTOR', {
        %local_if_select_args,
        EX_PARAMS => ' data-input-disables=FLOW_COLLECTOR_CUSTOM ',
      });
    my $flow_select_with_input =
      $html->element('div', $flow_ip_select, { class => 'col-md-5 no-padding' })
        . $html->element('div',
        $html->element('p', $lang{OR}, { class => 'form-control-static' }), { class => 'col-md-1 no-padding' }
      )
        . $html->element('div',
        $html->form_input('FLOW_COLLECTOR', $FORM{FLOW_COLLECTOR}, { ID => 'FLOW_COLLECTOR_CUSTOM' }),
        { class => 'col-md-6 no-padding' }
      );
  
    $template_args{EXTRA_INPUTS} .= $make_form_row->('FLOW_COLLECTOR', "Flow collector IP", $flow_select_with_input);
    $template_args{EXTRA_INPUTS} .= $make_input->('FLOW_PORT', $FORM{FLOW_PORT} || '9996', "Flow $lang{PORT}");
  }
  
  my $ip_pools = $Nas->nas_ip_pools_list({ COLS_NAME => 1, NAS_ID => $FORM{NAS_ID} });
  
  # Append first and last ips
  my @ip_pools_mapped =
    map {
      {
        id => $_->{id},
        name => $_->{pool_name} . ' (' . $_->{first_ip} . '-' . $_->{last_ip} . ')'
      }
    } @$ip_pools;
  
  $template_args{IP_POOL_SELECT} = $html->form_select('IP_POOL', {
      SEL_LIST => \@ip_pools_mapped,
      SEL_KEY  => 'pool_name',
      MAIN_MENU => get_function_index('form_ip_pools')
    });
  
  $template_args{RADIUS_IP_SELECT} = $html->form_select('RADIUS_IP', \%local_if_select_args);
  
  $html->tpl_show(templates('form_mikrotik_configure'), {
      %template_args
    }
  );
  
  return 1;
}

#**********************************************************
=head2 mikrotik_hotspot_configure($Nas)

  Arguments:
    $Nas - billing NAS object

  Returns:

=cut
#**********************************************************
sub mikrotik_hotspot_configure {
  my ($Nas_) = @_;


#  delete $Nas_->{conf};
#  delete $Nas_->{db};
#  delete $Nas_->{admin};
#  _bp('as', $Nas_);
  my $mikrotik = Abills::Nas::Mikrotik->new( $Nas_, \%conf, {
      FROM_WEB => 1,
      MESSAGE_CALLBACK => sub { $html->message('info', shift) }
    });

  if (!$mikrotik){
    $html->message('err', $lang{ERR_WRONG_DATA}, "NAS_IP_PORT_MNG");
  }

  $html->message( "info", "Hotspot configure" );

  my $mikrotik_access = $mikrotik->has_access();

  if ( $mikrotik_access < 1 ) {

    if (!$FORM{upload_key}) {
      my $wiki_mikrotik_ssh_access_link = $html->button( $lang{HELP}, undef, {
          GLOBAL_URL => 'http://abills.net.ua/wiki/doku.php/abills:docs:nas:mikrotik:ssh',
          target     => '_blank',
          BUTTON     => 1
        } );

      $html->message( 'warn', $lang{ERROR},
        "$lang{ERR_ACCESS_DENY} : " . $html->br() . "User: $Nas_->{NAS_MNG_USER}" . $html->br() . $wiki_mikrotik_ssh_access_link );
    }

    return mikrotik_upload_key($mikrotik_access, $Nas_);
  }

  my %default_arguments = (
    #    'INTERFACE'        => 'wlan0',
    BILLING_IP_ADDRESS => $ENV{HTTP_HOST},
    'ADDRESS'          => '192.168.4.1',
    'NETWORK'          => '192.168.4.0',
    'NETMASK'          => '24',
    'MIKROTIK_GATEWAY' => '192.168.1.1',
    'DHCP_RANGE'       => '192.168.4.3-192.168.4.254',
    'MIKROTIK_DNS'     => '8.8.8.8',
    'HOTSPOT_DNS_NAME' => lc ($Nas_->{NAS_NAME}) || 'hotspot.abills.net'
  );

  if ( $FORM{action} ) {

    my @walled_garden_hosts = ();
    # Read walled garden hosts from FORM
    my $walled_garden_hosts_count = $FORM{WALLED_GARDEN_ENTRIES} || '';
    if ($walled_garden_hosts_count && $walled_garden_hosts_count =~ /^\d+$/){
      for (my $i = 0; $i < $walled_garden_hosts_count; $i++){
        push (@walled_garden_hosts, $FORM{"WALLED_GARDEN_$i"}) if ($FORM{"WALLED_GARDEN_$i"});
      }
    }

    my $result = $mikrotik->configure_hotspot({
        INTERFACE          => $FORM{INTERFACE},
        DHCP_RANGE         => $FORM{DHCP_RANGE},
        ADDRESS            => $FORM{ADDRESS},
        NETWORK            => $FORM{NETWORK},
        NETMASK            => $FORM{NETMASK},
        GATEWAY            => $FORM{GATEWAY},
        DNS                => $FORM{DNS},
        DNS_NAME           => $FORM{DNS_NAME},
        BILLING_IP_ADDRESS => $FORM{BILLING_IP_ADDRESS},
        RADIUS_SECRET      => $Nas_->{NAS_MNG_PASSWORD},
        WALLED_GARDEN      => \@walled_garden_hosts
      });

    if ($result){
      $html->message('info', $lang{SUCCESS});
    }

    return 1;
  }

  my $interfaces_list = $mikrotik->interfaces_list({ type => 'ether' });

  if (defined $interfaces_list && ref $interfaces_list eq 'ARRAY' && scalar @$interfaces_list == 0){
    $interfaces_list = [ { name => 'ether0'}, {name => 'ether1'}, {name => 'wlan0'}  ];
  }
  my $interface_select = $html->form_select('INTERFACE',{
      SELECTED  => $FORM{HOTSPOT_INTERFACE} || '',
      SEL_LIST  => $interfaces_list,
      SEL_KEY   => 'name',
      SEL_VALUE => 'name',
      NO_ID => 1
    });

  $html->tpl_show( templates( 'form_mikrotik_hotspot' ), { INTERFACE_SELECT => $interface_select, %default_arguments, %FORM } );

  return 1;
}

#**********************************************************
=head2 mikrotik_upload_key()

=cut
#**********************************************************
sub mikrotik_upload_key {
  my ($status, $Nas_) = @_;
  return unless (defined $status && defined $Nas_);
  
  my $upload_key_for_admin = $FORM{ADMIN} || $Nas_->{NAS_MNG_USER}  || 'abills_admin';
  my $system_admin = $FORM{SYSTEM_ADMIN} || 'admin';
  my $system_password = $FORM{SYSTEM_PASSWD} || '';

  if ($FORM{upload_key}){

    $Nas_->{nas_mng_user} = $system_admin;
    $Nas_->{nas_mng_password} = $system_password;

    my $mt = Abills::Nas::Mikrotik->new( $Nas_, \%conf, {
        backend => 'api',
        FROM_WEB => 1,
        MESSAGE_CALLBACK => sub { $html->message('info', shift) },
      });


    if (!$mt->has_access()){
      $html->message('err', $lang{ERROR}, $lang{ERR_WRONG_PASSWD}. $html->br() . $mt->get_api_error());
      return 0;
    }
    else {
      my $uploaded_key = $mt->upload_key(\%FORM);
      
      if ($uploaded_key){
        my $refresh_button = $html->button($lang{REFRESH}, "index=$index&NAS_ID=$FORM{NAS_ID}&mikrotik_hotspot=1", {
            BUTTON => 1,
          });
        $html->message('info', $lang{SUCCESS}, $refresh_button);
        return 1;
      }
      else {
        $html->message('info', $lang{ERROR}, $mt->get_api_error() );
        return 0;
      }
    }
  }

  $html->tpl_show( templates('form_mikrotik_upload_key'), {
      NAS_ID          => $FORM{NAS_ID},
      ADMIN           => $upload_key_for_admin,
      SYSTEM_ADMIN    => $system_admin,
      SYSTEM_PASSWORD => $system_password,
    } );

  return 0;
}

#**********************************************************
=head2 _mikrotik_init_and_check_access()

=cut
#**********************************************************
sub _mikrotik_init_and_check_access {
  my ($Nas_, $attr) = @_;
    
  my $mikrotik = Abills::Nas::Mikrotik->new( $Nas_, \%conf, {
    FROM_WEB => 1,
    MESSAGE_CALLBACK => sub { $html->message('info', shift) },
      %{ $attr ? $attr : {} }
#    DEBUG => 100,
  });
  
  if (!$mikrotik){
    $html->message('err', $lang{ERR_WRONG_DATA}, "NAS_IP_PORT_MNG");
  }
  
  my $mikrotik_access = $mikrotik->has_access();
  
  if ( $mikrotik_access < 1 ) {
    
    if (!$FORM{upload_key}) {
      my $wiki_mikrotik_ssh_access_link = $html->button( $lang{HELP}, undef, {
          GLOBAL_URL => 'http://abills.net.ua/wiki/doku.php/abills:docs:nas:mikrotik:ssh',
          target     => '_blank',
          BUTTON     => 1
        } );
      
      $html->message( 'warn', $lang{ERROR},
        "$lang{ERR_ACCESS_DENY} : " . $html->br() . "User: $Nas_->{NAS_MNG_USER}" . $html->br() . $wiki_mikrotik_ssh_access_link );
    }
    
    return mikrotik_upload_key($mikrotik_access, $Nas_);
  }
  
  return $mikrotik;
}

#**********************************************************
=head2 local_network_interfaces_list()

=cut
#**********************************************************
sub local_network_interfaces_list {
  require Abills::Filters;
  Abills::Filters->import(qw/$IPV4  $MAC/);
  
  my $raw = cmd("ifconfig -a");
  my @lines = split("\n", $raw);
  
  # Need to left 2 lines (1 with name and HWAddr, second with inet address)
  my %interfaces = ();
  for (my $i = 0; $i < $#lines; $i++){
    if ($lines[$i] =~ /^([a-z0-9]*) .* ($main::MAC) /){
      my $name = $1;
      $interfaces{$name}->{MAC} = $2;
      if ($lines[$i+1] =~ /inet +(.*)/){
        my @other_params = split(' ', $1);
        foreach ( @other_params ){
          my ($attribut_name, $attribut_value) = split(':', $_);
          $interfaces{$name}->{uc $attribut_name} = $attribut_value;
        }
      }
    }
  }
  
  return \%interfaces;
}

1;