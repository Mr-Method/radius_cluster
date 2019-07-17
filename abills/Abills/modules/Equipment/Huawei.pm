=head1 NAME

 huawei snmp monitoring and managment

=cut

use strict;
use warnings;
use Abills::Base qw(in_array _bp int2byte load_pmodule2);
use Abills::Filters qw(bin2hex bin2mac);

our(
  $html,
  %lang
);

my $Telnet;
#**********************************************************
=head2 _huawei_get_ports($attr) - Get OLT ports

=cut
#**********************************************************
sub _huawei_get_ports {
  my ($attr) = @_;

  my $ports_info = equipment_test({
    %{$attr},
    PORT_INFO  => 'PORT_NAME,PORT_DESCR,PORT_STATUS,PORT_SPEED,PORT_IN,PORT_OUT,PORT_TYPE',
  });

  foreach my $key ( keys %{ $ports_info } ) {
    if ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} =~ /^1|250$/ && $ports_info->{$key}{PORT_NAME} =~ /(.PON)/) {
      my $type = lc($1);
      my $branch = decode_port($key);
      $ports_info->{$key}{BRANCH} = $branch;
      $ports_info->{$key}{PON_TYPE} = $type;
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_DESCR};
    }
    else {
      delete($ports_info->{$key});
    }
  }

  return \%{$ports_info};
}
#**********************************************************
=head2 _huawei_onu_list($port_list, $attr) -

  Arguments:
    $port_list
    $attr

  Results:

=cut
#**********************************************************
sub _huawei_onu_list{
  my ($port_list, $attr) = @_;

  my @all_rows = ();

  foreach my $snmp_id (keys %{ $port_list }) {
    my $type = $port_list->{$snmp_id}{PON_TYPE};
    my %total_info = ();
    my $snmp = _huawei({TYPE => $type});
    my @cols = ('PORT_ID', 'ONU_ID', 'ONU_SNMP_ID', 'PON_TYPE', 'ONU_DHCP_PORT');
    foreach my $oid_name ( keys %{ $snmp } ){
      if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info' ){
        next;
      }

      push @cols, $oid_name;
      print "OID: $oid_name -- $snmp->{$oid_name}->{NAME} -- $snmp->{$oid_name}->{OIDS} \n"  if ($attr->{DEBUG} && $attr->{DEBUG} > 2);

      my $oid = $snmp->{$oid_name}->{OIDS};
      if (!$oid) {
        next;
      }

      #print $oid . '.' . $snmp_id . "\n";
      my $values = snmp_get({
        %{$attr},
        WALK    => 1,
        OID     => $oid . '.' . $snmp_id,
        TIMEOUT => 25
      });

      foreach my $line (@{$values}) {
        next if (! $line);
        #print "$line\n";
        my ($onu_id, $oid_value) = split( /:/, $line, 2 );

        if ($attr->{DEBUG} && $attr->{DEBUG} > 3) {
          print $oid . '->' . "$onu_id, $oid_value \n";
        }
        my $function = $snmp->{$oid_name}->{PARSER};
        if ($function && defined( &{$function} ) ) {
          ($oid_value) = &{ \&$function }($oid_value);
        }
        $total_info{$oid_name}{$snmp_id . '.' . $onu_id} = $oid_value;
      }
    }

    foreach my $key (keys %{ $total_info{ONU_STATUS} }) {
      my %onu_info = ();
      my ($branch, $onu_id) = split(/\./, $key, 2);
      for (my $i = 0; $i <= $#cols; $i++) {
        my $value = '';
        my $oid_name = $cols[$i];
        if ($oid_name eq 'ONU_ID') {
          $value = $onu_id;
        }
        elsif ($oid_name eq 'PORT_ID') {
          $value = $port_list->{$snmp_id}->{ID};
        }
        elsif ($oid_name eq 'PON_TYPE') {
          $value = $type;
        }
        elsif ($oid_name eq 'ONU_DHCP_PORT') {
          $value = decode_port($branch) . ':' . $onu_id;
        }
        elsif ($oid_name eq 'ONU_SNMP_ID') {
          $value = $key;
        }
         else {
          $value = $total_info{$cols[$i]}{$key};
        }
        $onu_info{$oid_name}=$value;
      }
      push @all_rows, {%onu_info};
    }
  }

  return \@all_rows;
}

#**********************************************************
=head2 _huawei_unregister($attr);

  Arguments:
    $attr

  Returns;
    \@unregister

=cut
#**********************************************************
sub _huawei_unregister {
  my ($attr) = @_;
  my @unregister = ();

  my $snmp = _huawei({ TYPE => 'unregister' });

  my $unreg_result = snmp_get({
    %{$attr},
    WALK    => 1,
    OID     => $snmp->{UNREGISTER}->{OIDS},
    #TIMEOUT => 8,
    SILENT  => 1
  });

  foreach my $line ( @$unreg_result ) {
    my ($id, $mac_bin)=split(/:/, $line);
    push @unregister, {
      id  => $id,
      mac => bin2mac($mac_bin)
    }
  }

  return \@unregister;
}

#**********************************************************
=head2 _huawei($attr) - Snmp recovery

  Arguments:
    $attr
      TYPE

  http://pastebin.com/wjj68SUX

=cut
#**********************************************************
sub _huawei{
  my ($attr) = @_;

  my %snmp = (
   epon => {
     'ONU_MAC_SERIAL' => {
       NAME => 'Mac/Serial',
       OIDS => '.1.3.6.1.4.1.2011.6.128.1.1.2.53.1.3',
       PARSER => 'bin2mac'
     },
     'ONU_STATUS' => {
       NAME => 'Status',
       OIDS => '.1.3.6.1.4.1.2011.6.128.1.1.2.57.1.15',
       PARSER => ''
     },
     'ONU_TX_POWER' => {
       NAME   => 'ONU_TX_POWER',
       OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.104.1.4',
       PARSER => '_huawei_convert_power'
     }, #tx_power = tx_power * 0.01;
     'ONU_RX_POWER' => {
       NAME => 'ONU_RX_POWER',
       OIDS => '.1.3.6.1.4.1.2011.6.128.1.1.2.104.1.5',
       PARSER => '_huawei_convert_power'
     }, #tx_power = tx_power * 0.01;
     'OLT_RX_POWER' => {
       NAME   => 'OLT_RX_POWER',
       OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.104.1.1',
       PARSER => '_huawei_convert_olt_power'
     }, #olt_rx_power = olt_rx_power * 0.01 - 100;
     'ONU_DESC' => {
       NAME   => 'DESCRIBE',
       OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.2.53.1.9',
       PARSER => '_huawei_convert_desc'
     },
     'ONU_IN_BYTE' => {
       NAME => 'PORT_IN',
       OIDS => '',
       PARSER => ''
     },
     'ONU_OUT_BYTE' => {
       NAME => 'PORT_OUT',
       OIDS => '',
       PARSER => ''
     },
     'TEMPERATURE' => {
       NAME   => 'TEMPERATURE',
       OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.104.1.2',
       PARSER => '_huawei_convert_temperature'
     },
     'reset' => {
       NAME   => '',
       OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.57.1.2',
       PARSER => ''
     },
     main_onu_info => {
       'HARD_VERSION' => {
         NAME   => 'Hhard_Version',
         OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.55.1.4',
         PARSER => ''
       },
       'SOFT_VERSION' => {
         NAME => 'Soft_Version',
         OIDS => '.1.3.6.1.4.1.2011.6.128.1.1.2.55.1.5',
         PARSER => ''
       },
       'VOLTAGE' => {
         NAME => 'VOLTAGE',
         OIDS => '.1.3.6.1.4.1.2011.6.128.1.1.2.104.1.6',
         PARSER => '_huawei_convert_voltage'
       },
       'DISTANCE' => {
         NAME => 'DISTANCE',
         OIDS => '.1.3.6.1.4.1.2011.6.128.1.1.2.57.1.19',
         PARSER => '_huawei_convert_distance'
       }
     }
   },
   gpon => {
     'ONU_MAC_SERIAL' => {
       NAME   => 'Mac/Serial',
       OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.3',
       PARSER => 'bin2hex'
     },
     'ONU_STATUS' => {
       NAME   => 'STATUS',
       OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.46.1.15',
       PARSER => ''
     },
     'ONU_TX_POWER' => {
       NAME   => 'ONU_TX_POWER',
       OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.3',
       PARSER => '_huawei_convert_power'
     }, # tx_power = tx_power * 0.01;
     'ONU_RX_POWER' => {
       NAME   => 'ONU_RX_POWER',
       OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.4',
       PARSER => '_huawei_convert_power'
     }, # rx_power = rx_power * 0.01;
     'OLT_RX_POWER' => {
       NAME   => 'OLT_RX_POWER',
       OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.6',
       PARSER => '_huawei_convert_olt_power'
     }, # olt_rx_power = olt_rx_power * 0.01 - 100;
     'ONU_DESC' => {
       NAME   => 'DESCRIBE',
       OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.9',
       PARSER => '_huawei_convert_desc'
     },
     'ONU_IN_BYTE' => {
       NAME => 'PORT_IN',
       OIDS => '1.3.6.1.4.1.2011.6.128.1.1.4.23.1.4',
       PARSER => ''
     },
     'ONU_OUT_BYTE' => {
       NAME => 'PORT_OUT',
       OIDS => '1.3.6.1.4.1.2011.6.128.1.1.4.23.1.3',
       PARSER => ''
     },
     'TEMPERATURE' => {
       NAME   => 'TEMPERATURE',
       OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.1',
       PARSER => '_huawei_convert_temperature'
     },
     'reset' => {
       NAME   => '',
       OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.46.1.2',
       PARSER => ''
     },
     main_onu_info => {
       'VERSION_ID' => {
         NAME => 'Version_ID',
         OIDS => '.1.3.6.1.4.1.2011.6.128.1.1.2.45.1.1',
         PARSER => ''
       },
       'VENDOR_ID' => {
         NAME => 'Vendor_ID',
         OIDS => '.1.3.6.1.4.1.2011.6.128.1.1.2.45.1.5',
         PARSER => ''
       },
       'EQUIPMENT_ID' => {
         NAME => 'Equipment_ID',
         OIDS => '.1.3.6.1.4.1.2011.6.128.1.1.2.45.1.4',
         PARSER => ''
       },
       'VOLTAGE' => {
         NAME => 'VOLTAGE',
         OIDS => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.5',
         PARSER => '_huawei_convert_voltage'
       },
       'DISTANCE' => {
         NAME   => 'DISTANCE',
         OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.46.1.20',
         PARSER => '_huawei_convert_distance'
       },
       'LINE_PROFILE' => {
         NAME => 'ont-lineprofile',
         OIDS => '1.3.6.1.4.1.2011.6.128.1.1.2.43.1.7',
         PARSER => ''
       },
       'SRV_PROFILE' => {
         NAME => 'ont-srvprofile',
         OIDS => '1.3.6.1.4.1.2011.6.128.1.1.2.43.1.8',
         PARSER => ''
       },
       'ETH_DUPLEX' => {
         NAME => 'Ethernet Duplex mode',
         OIDS => '.1.3.6.1.4.1.2011.6.128.1.1.2.62.1.3',
         PARSER => '_huawei_convert_duplex',
         WALK => '1'
       },
       'ETH_SPEED' => {
         NAME   => 'Ethernet Speed',
         OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.62.1.4',
         PARSER => '_huawei_convert_speed',
         WALK   => '1'
       },
       'ETH_ADMIN_STATE' => {
         NAME   => 'Ethernet Admin state',
         OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.62.1.5',
         PARSER => '_huawei_convert_admin_state',
         WALK   => '1'
       },
       'ONU_PORTS_STATUS' => {
         NAME   => 'ONU_PORTS_STATUS',
         OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.62.1.22',
         PARSER => '_huawei_convert_state',
         WALK   => '1'
       },
       'VLAN' => {
         NAME   => 'VLAN',
         OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.62.1.7',
         PARSER => '_huawei_convert_eth_vlan',
         WALK   => '1'
       }
     }
   },
   unregister => {
     UNREGISTER => {
       NAME   => 'UNREGISTER',
       # GPON
       OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.2.48.1.2',
       #OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.2.52.1.2',
       PARSER => '',
       WALK   => '1'
     }
   }
  );

  #  Получить все сервис-порты: 1.3.6.1.4.1.2011.5.14.3.1.1.1
  if ($attr->{TYPE}) {
    return $snmp{$attr->{TYPE}};
  }

  return \%snmp;
}
#**********************************************************
=head2 _huawei_onu_status();

=cut
#**********************************************************
sub _huawei_onu_status{

  my %status = (
    1 => 'Online:text-green',
    2 => 'Offline:text-red',
  );

  return \%status;
}
#**********************************************************
=head2 decode_port($dec) - Decode onu int

  Arguments:
    $dec

  Returns:
    deparsing string

=cut
#**********************************************************
sub decode_port {
  my ($dec) = @_;

  $dec =~ s/\.\d+//;
  my $frame = ($dec & 0xF0000) / 256;
  my $slot = ($dec & 0xF000) / 8192;
  my $port = ($dec & 0xF00) / 256;

  return $frame . '/' . $slot . '/' . $port;
}

#**********************************************************
=head2 _huawei_set_desc_port($attr) - Set Description to OLT ports

=cut
#**********************************************************
sub _huawei_set_desc {
  my ($attr) = @_;

  my $oid = $attr->{OID} || '' ;

  if ($attr->{PORT}) {
    $oid = '1.3.6.1.2.1.31.1.1.1.18.'.$attr->{PORT};
  }

  snmp_set({
    SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
    OID            => [ $oid, "string", "$attr->{DESC}" ]
  });

  return 1;
}

#**********************************************************
=head2 _huawei_get_service_ports($attr) - Get OLT service ports

  Arguments:
    $attr
      ONU_SNMP_ID

=cut
#**********************************************************
sub _huawei_get_service_ports {
  my ($attr) = @_;
#  push @datasource, ( data_source => { name => $line->{SOURCE} , type  => $line->{TYPE} } );

  my %snmp_oids = (
    FRAME          => '.1.3.6.1.4.1.2011.5.14.5.2.1.2',
    SLOT           => '.1.3.6.1.4.1.2011.5.14.5.2.1.3',
    PORT           => '.1.3.6.1.4.1.2011.5.14.5.2.1.4',
    ONU_ID         => '.1.3.6.1.4.1.2011.5.14.5.2.1.5',
    GEMPORT_ETH    => '.1.3.6.1.4.1.2011.5.14.5.2.1.6',
    TYPE           => '.1.3.6.1.4.1.2011.5.14.5.2.1.7',
    S_VLAN         => '.1.3.6.1.4.1.2011.5.14.5.2.1.8',
    MULTISERVICE   => '.1.3.6.1.4.1.2011.5.14.5.2.1.11',
    C_VLAN         => '.1.3.6.1.4.1.2011.5.14.5.2.1.12',
    TAG_TRANSFORM  => '.1.3.6.1.4.1.2011.5.14.5.2.1.18'
  );

  my %service_ports_info = ();
  foreach my $type (keys %snmp_oids) {
    my $oid = $snmp_oids{$type};
    my $sp_info = snmp_get({
      %{$attr},
      OID     => $oid,
      WALK    => 1
    });

    foreach my $line ( @{$sp_info} ){
      next if (!$line);
      my ($sp_id, $data) = split( /:/, $line, 2 );
      $service_ports_info{$sp_id}{$type} = $data;
    }
  }

  return %service_ports_info if (!$attr->{ONU_SNMP_ID});
  my @service_ports = ();
  my ($snmp_port_id, $onu_id) = split( /\./, $attr->{ONU_SNMP_ID}, 2 );
  my $branch = decode_port($snmp_port_id);
  my $onu = $branch.':'.$onu_id;

  foreach my $sp_id ( keys %service_ports_info ) {
    my %type = (
      1 => 'pvc',
      2 => 'eth',
      3 => 'vdsl',
      4 => 'gpon',
      5 => 'shdsl',
      6 => 'epon',
      7 => 'vcl',
      8 => 'adsl',
      9 => 'gpon', #gponOntEth
      10 => 'epon', #eponOntEth
      11 => 'gpon', #gponOntIphost
      12 => 'epon', #eponOntIphost
      14 => 'gpon'
    ); #?

    my %multi_srv_type = (
      1 => 'user-vlan',
      2 => 'user-encap',
      3 => 'user-8021p'
    );

    my %tag_transform = (
      0 => 'add',
      1 => 'transparent',
      2 => 'translate',
      3 => 'translateAndAdd',
      4 => 'addDouble',
      5 => 'translateDouble',
      6 => 'translateAndRemove',
      7 => 'remove',
      8 => 'removeDouble',
    );

    my $sp_data = $service_ports_info{$sp_id};
    if ($onu && $onu eq $sp_data->{FRAME}.'/'.$sp_data->{SLOT}.'/'.$sp_data->{PORT}.':'.$sp_data->{ONU_ID}){
      unshift @service_ports, ['Service port', "service-port $sp_id vlan $sp_data->{S_VLAN} $type{ $sp_data->{TYPE} } $branch ont $onu_id "
                            . (($sp_data->{TYPE} eq '4') ? "gemport $sp_data->{GEMPORT_ETH}" : '')
                            . (($sp_data->{TYPE} > '8') ? "eth $sp_data->{GEMPORT_ETH}" : '')
                            . " multi-service $multi_srv_type{ $sp_data->{MULTISERVICE} } $sp_data->{C_VLAN}"
                            . " tag-transform $tag_transform{ $sp_data->{TAG_TRANSFORM} }"];
    }
  }

  return @service_ports;
}
#**********************************************************
=head2 _huawei_get_free_id($attr)

   Arguments:
     $attr
       OID                - oid
       SNMP_COMMUNITY     - Port id
       MAX_ID             - Maximal id (default 128)

=cut
#**********************************************************
sub _huawei_get_free_id{
  my ($attr) = @_;

  my $max_id = $attr->{MAX_ID} || '128';
  my %used_ids = ();
  my $values = snmp_get({
    %{$attr},
    WALK    => 1,
    OID     => $attr->{OID},
    TIMEOUT => 25
  });

  foreach my $line (@{$values}) {
    my ($id, undef) = split( /:/, $line, 2 );
    $used_ids{$id} = 1;
  }

  my $id = "-1";
  for (my $i = 0 ; $i <= $max_id; $i++) {
    if (!$used_ids{$i}){
      $id = $i;
      last;
    }
  }

  return $id;
}

#**********************************************************
=head2 _huawei_convert_power($power);

=cut
#**********************************************************
sub _huawei_convert_power{
  my ($power) = @_;

  $power //= 0;

  if (2147483647 == $power) {
    $power = '';
  }
  else {
    $power = $power * 0.01;
    $power  = sprintf("%.2f", $power );
  }

  return $power;
}
#**********************************************************
=head2 _huawei_convert_olt_power();

=cut
#**********************************************************
sub _huawei_convert_olt_power{
  my ($olt_power) = @_;

  $olt_power //= 0;

  if (2147483647 == $olt_power) {
    $olt_power = '';
  }
  else {
    $olt_power = $olt_power * 0.01 - 100;
    $olt_power = sprintf("%.2f", $olt_power );
  }

  return $olt_power;
}
#**********************************************************
=head2 _huawei_convert_desc();

=cut
#**********************************************************
sub _huawei_convert_desc{
  my ($desc) = @_;

  $desc //= q{};

  if ($desc eq 'ONT_NO_DESCRIPTION') {
    $desc = '';
  }
  return $desc;
}
#**********************************************************
=head2 _huawei_convert_temperature();

=cut
#**********************************************************
sub _huawei_convert_temperature{
  my ($temperature) = @_;

  $temperature //= 0;

  if (2147483647 == $temperature) {
    $temperature = '';
  }

  return $temperature;
}
#**********************************************************
=head2 _huawei_convert_voltage();

=cut
#**********************************************************
sub _huawei_convert_voltage{
  my ($voltage) = @_;

  $voltage //= 0;

  if (2147483647 == $voltage) {
    $voltage = '';
  }
  else {
    $voltage = $voltage * 0.001;
    $voltage .= ' V'
  }
  return $voltage;
}

#**********************************************************
=head2 _huawei_convert_distance();

=cut
#**********************************************************
sub _huawei_convert_distance{
  my ($distance) = @_;

  $distance //= -1;

  if ($distance eq '-1') {
    $distance = '';
  }
  else {
    $distance = $distance * 0.001;
    $distance .= ' km';
  }
  return $distance;
}

#**********************************************************
=head2 _huawei_convert_duplex();

=cut
#**********************************************************
sub _huawei_convert_duplex{
  my ($data) = @_;

  my ($oid, $index) = split( /:/, $data, 2 );
  my $port = "Port $oid";
  my $duplex = 'Unknown';
  my %duplex_hash = (
      3 => 'Auto',
      4 => 'Half',
      5 => 'Full'
  );
  if ($duplex_hash{ $index } ) {
    $duplex = $duplex_hash{ $index };
  }

  return ($port, $duplex);
}
#**********************************************************
=head2 _huawei_convert_speed();

=cut
#**********************************************************
sub _huawei_convert_speed{
  my ($data) = @_;
  my ($oid, $index) = split( /:/, $data, 2 );
  my $port = "Port $oid";
  my $speed = 'Unknown';
  my %speed_hash = (
      4 => 'Auto',
      5 => '10 Mbit',
      6 => '100 Mbit',
      7 => '1000 Mbit'
  );
  if ($speed_hash{ $index } ) {
    $speed = $speed_hash{ $index };
  }
  return ($port, $speed);
}
#**********************************************************
=head2 _huawei_convert_admin_state();

=cut
#**********************************************************
sub _huawei_convert_admin_state{
  my ($data) = @_;
  my ($oid, $index) = split( /:/, $data, 2 );
  my $port = "Port $oid";
  my $state = 'Unknown';
  my %state_hash = (
      1 => 'Enable',
      2 => 'Disable',
  );
  if ($state_hash{ $index } ) {
    $state = $state_hash{ $index };
  }
  return ($port, $state);
}
#**********************************************************
=head2 _huawei_convert_state($data);

=cut
#**********************************************************
sub _huawei_convert_state{
  my ($data) = @_;

  my ($port, $state_id) = split( /:/, $data, 2 );

  my $state = 0;
  my %state_hash = (
    1 => 1, #'Up',
    2 => 2  #'Down',
  );

  if ($state_hash{ $state_id } ) {
    $state = $state_hash{ $state_id };
  }

  return ($port, $state);
}
#**********************************************************
=head2 _huawei_convert_eth_vlan();

=cut
#**********************************************************
sub _huawei_convert_eth_vlan{
  my ($data) = @_;
  my ($oid, $index) = split( /:/, $data, 2 );

  my $port = "Port $oid";
  my $vlan = 'Vlan'.$index;

  return ($port, $vlan);
}
#**********************************************************
=head2 _huawei_convert_cpu_usage();

=cut
#**********************************************************
sub _huawei_convert_cpu_usage{
  my ($data) = @_;
  my ($oid, $value) = split( /:/, $data, 2 );
  my ($frame, $slot) = split( /\./, $oid, 2 );
  $slot = "Slot " . $frame . "/" . $slot;
  if ($value eq '-1') {
    $value = '--';
  }
  else {
    $value .= ' %';
  }
  return ($slot, $value);
}
#**********************************************************
=head2 _huawei_convert_info_temperature();

=cut
#**********************************************************
sub _huawei_convert_info_temperature{
  my ($data) = @_;
  my ($oid, $value) = split( /:/, $data, 2 );
  my ($frame, $slot) = split( /\./, $oid, 2 );
  $slot = "Slot " . $frame . "/" . $slot;
  if ($value eq '2147483647') {
    $value = '--';
  }
  else {
    $value .= ' °C';
  }
  return ($slot, $value);
}
#**********************************************************
=head2 _huawei_convert_info_describe();

=cut
#**********************************************************
sub _huawei_convert_info{
  my ($data) = @_;
  my ($oid, $value) = split( /:/, $data, 2 );
  my ($frame, $slot) = split( /\./, $oid, 2 );
  $slot = "Slot " . $frame . "/" . $slot;
  return ($slot, $value);
}

#**********************************************************
=head2 _huawei_get_fdb($attr) - GET FDB by telnet

  Arguments:
    $attr

  Results:


=cut
#**********************************************************
sub _huawei_get_fdb{
  my ($attr) = @_;

  my %hash = ();
  if (_huawei_telnet_open($attr)) {
    my $data = _huawei_telnet_cmd("display mac-address all");
    #$data =~ s/\n/<br>/g;
    my @list = split("\n", $data || q{});
    foreach my $line (@list) {
      #print "$line ||| <br>";
      if ($line =~ /([-0-9]+)\s+.+\s+([a-z]+)\s+([a-f0-9]{2})([a-f0-9]{2})\-([a-f0-9]{2})([a-f0-9]{2})\-([a-f0-9]{2})([a-f0-9]{2})\s+([a-z]+)\s+(\d+)\s+\/(\d+)\s+\/(\d+)\s+([-0-9]+)\s+([-0-9]+)\s+(\d+)/) {
        #print "$1 | $2 | $3 | $4 | $5 | $6 | $7 | $8 | $9 | $10 | $11 | $12 | $13 | $14 | $15 | <br>";
        my $mac = "$3:$4:$5:$6:$7:$8";
        my ($srv_port, $port_type, $port, $onu_id, $van_id) = ($1, $2, $10.'/'.$11.'/'.$12, $13, $15);
        my $key = $mac.'_'.$van_id;
        if ( $attr->{FILTER} ){
          $attr->{FILTER} = lc( $attr->{FILTER} );
          if ( $mac =~ m/($attr->{FILTER})/ ){
            my $search = $1;
            $mac =~ s/$search/<b>$search<\/>/g;
          }
          else{
            next;
          }
        }
        $hash{$key}{1} = $mac;
        #$hash{$key}{2} = uc($port_type).' '.$port.(($onu_id =~ /\d+/) ? ":$onu_id" : "");
        $hash{$key}{2} = $port.(($onu_id =~ /\d+/) ? ":$onu_id" : "");
        $hash{$key}{4} = $van_id . (($srv_port =~ /\d+/) ? " ( SERVICE_PORT: $srv_port )" : "");
      }
    }
  }

  return %hash;
}

#**********************************************************
=head2 _huawei_telnet_open($attr);

  Arguments:
    $attr
      NAS_INFO

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub _huawei_telnet_open{
  my ($attr) = @_;

  my $load_data = load_pmodule2('Net::Telnet', {SHOW_RETURN => 1});
  if ($load_data) {
    return 0;
  }

  if(! $attr->{NAS_INFO}->{NAS_MNG_IP_PORT}) {
    print "NAS_MNG_IP_PORT not defined";
    return 0;
  }

  my $user_name = $attr->{NAS_INFO}->{NAS_MNG_USER} || q{};
  my $password  = $attr->{NAS_INFO}->{NAS_MNG_PASSWORD} || q{};

  $Telnet = Net::Telnet->new(
    Timeout  => 15,
    Errmode  => 'return'
  );

  my ($ip, $mng_port, undef) = split(/:/, $attr->{NAS_INFO}->{NAS_MNG_IP_PORT}, 3);
  my $port = $mng_port || 23;
  $Telnet->open(
    Host  => $ip,
    Port  => $port
  );

  if ($Telnet->errmsg) {
    print "Problem connecting to $ip, port: $port\n";
    return 0;
  }
  $Telnet->waitfor('/>>User name:/i');
  if ($Telnet->errmsg) {
    print ">Problem connecting to $ip, port: $port\n";
    return 0;
  }

  $Telnet->print($user_name);
  $Telnet->waitfor('/>>User password:/i');
  $Telnet->print($password);
  if ($Telnet->errmsg) {
    print "Telnet login or password incorrect\n";
    return 0;
  }
  $Telnet->print(" ") or print "ERROR USER OR PASS";;
  $Telnet->print(" ") or print "ERROR USER OR PASS";
  $Telnet->waitfor('/>/i') || print "ERROR USER OR PASS";
  $Telnet->print("enable");
  $Telnet->waitfor('/#/i');
  $Telnet->print("config");
  $Telnet->waitfor('/\(config\)#/i');
  if ($Telnet->errmsg) {
    print "Telnet login or password incorrect";
    return 0;
  }
  $Telnet->print("scroll");
  $Telnet->print(" ");
  $Telnet->waitfor('/#/i');

  return 1;
}

#**********************************************************
=head2 _huawei_telnet_cmd($cmd);

=cut
#**********************************************************
sub _huawei_telnet_cmd{
  my ($cmd) = @_;

  $Telnet->print($cmd);
  $Telnet->print(" ");
  my @data = $Telnet->waitfor('/#/');
  #$data[0] =~ s/\n/<br>/g;

  return $data[0];
}



1