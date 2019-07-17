=head1 NAME

 Eltex snmp monitoring and managment

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Filters qw(bin2mac mac2dec);

our(
  $debug
);

#**********************************************************
=head2 _eltex_get_ports($attr) - Get OLT ports

=cut
#**********************************************************
sub _eltex_get_ports {
  my ($attr) = @_;

  my $count_oid = '.1.3.6.1.4.1.35265.1.21.1.8.0';
  my $ports_count = snmp_get({ %{$attr}, OID => $count_oid });
  $ports_count //= 0;
  my $oid = '1.3.6.1.4.1.35265.1.21';
  my @ports_snmp_id = (
    '2.2',
    '2.3',
    '3.2',
    '3.3',
    '4.2',
    '4.3',
    '5.2',
    '4.3'
  );

  my %ports_info_oids = (
    PORT_STATUS => '',
    IN          => '',
    OUT         => '',
    PORT_SPEED  => '.4.0',
    BRANCH_DESC => '.1.0',
  );

  my %speed_type = (2 => '1Gbps', 3 => '2Gbps');
  my $ports_info = ();
  for (my $i = 0 ; $i < $ports_count; $i++) {
    my $snmp_id = $ports_snmp_id[ $i ];
    foreach my $type (keys %ports_info_oids) {
      my $type_id = $ports_info_oids{ $type };
      next if (!$type_id);
      $ports_info->{$i}->{$type} = snmp_get({ %{$attr}, OID => $oid . '.' . $snmp_id . $type_id});
      if ($type eq 'PORT_SPEED') {
        $ports_info->{$i}->{$type} = $speed_type{ $ports_info->{$i}->{$type} };
      }
    }
    $ports_info->{$i}{BRANCH} = "0/$i";
    $ports_info->{$i}{PON_TYPE} = 'gepon';
    $ports_info->{$i}{SNMP_ID} = $i;
  }
  $ports_info->{255}{BRANCH} = 'ANY';
  $ports_info->{255}{PON_TYPE} = 'gepon';
  $ports_info->{255}{SNMP_ID} = 255;
  $ports_info->{255}{BRANCH_DESC} = 'Not assigned to any tree';

  return \%{$ports_info};
}

#**********************************************************
=head2 _eltex_onu_list($attr)

  Arguments:
    $attr
      COLS       - ARRAY refs
      INFO_OIDS  - Hash refs
      NAS_ID

=cut
#**********************************************************
sub _eltex_onu_list{
  my ($port_list, $attr) = @_;

  #my $debug     = $attr->{DEBUG} || 0;
  my @all_rows  = ();
  my %pon_types = ();
  my %port_ids  = ();

  foreach my $snmp_id (keys %{ $port_list }) {
    $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
    $port_ids{$port_list->{$snmp_id}{BRANCH}} = $port_list->{$snmp_id}{ID};
  }

  foreach my $pon_type (keys %pon_types) {
    my $snmp = _eltex({TYPE => $pon_type});

    my $onu_status_list = snmp_get( { %$attr,
      WALK => 1,
      OID  => '.1.3.6.1.4.1.35265.1.21.6.10.1.8',
    });
    my $onu_mac_list = snmp_get( { %$attr,
      WALK => 1,
      OID  => '.1.3.6.1.4.1.35265.1.21.16.2.1.3',
    });

    my %onu_cur_status = ();
    foreach my $line ( @$onu_status_list ) {
      next if (! $line);
      my($index, $status)=split(/:/, $line);
      my($port, $onu_id)=split(/\./, $index);
      $onu_cur_status{$onu_id}{STATUS}=$status;
      $onu_cur_status{$onu_id}{PORT}=$port;
    }

    foreach my $line (@{$onu_mac_list}) {
      next if (! $line);
      my ($onu_id, $mac) = split( /:/, $line, 2 );
      $onu_id =~ s/\d+\.//g;
      my $onu_mac = bin2mac($mac);
      my $onu_snmp_id = mac2dec($onu_mac);
      my %onu_info = ();
      $onu_info{PORT_ID}= (defined($onu_cur_status{$onu_id}{PORT})) ? $port_ids{'0/' . $onu_cur_status{$onu_id}{PORT}} : $port_ids{ANY} ;
      $onu_info{ONU_ID}= $onu_id;
      $onu_info{ONU_SNMP_ID}= $onu_snmp_id;
      $onu_info{PON_TYPE}= $pon_type;
      $onu_info{ONU_MAC_SERIAL} = $onu_mac;

      $onu_info{ONU_DHCP_PORT} = $onu_id;

      foreach my $oid_name ( keys %{ $snmp } ){
        #print "$oid_name -- $snmp->{$oid_name}->{NAME} -- $snmp->{$oid_name}->{OIDS} \n"  if ($debug);
        if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info' || $oid_name eq 'ONU_MAC_SERIAL' || !$onu_cur_status{$onu_id}{STATUS} && $oid_name ne 'ONU_DESC' ){
          next;
        }
        elsif ( $oid_name =~ /POWER|TEMPERATURE/ && $onu_cur_status{$onu_id}{STATUS} ne '7' ){
          $onu_info{$oid_name} = '';
          next;
        }
        elsif ( $oid_name eq 'STATUS' ){
          $onu_info{$oid_name} = $onu_cur_status{$onu_id}{STATUS};
          next;
        }

        my $oid_value = '';
        if ($snmp->{$oid_name}->{OIDS}) {
          my $oid = $snmp->{$oid_name}->{OIDS}.'.'.$onu_snmp_id;
          $oid_value = snmp_get( { %{$attr}, OID => $oid, SILENT => 1 } );
        }
        my $function = $snmp->{$oid_name}->{PARSER};
        if ($function && defined( &{$function} ) ) {
          ($oid_value) = &{ \&$function }($oid_value);
        }
        $onu_info{$oid_name} = $oid_value;
      }
      push @all_rows, {%onu_info};
    }
  }
  return \@all_rows;
}

#**********************************************************
=head2  _eltex_onu_status()
 http://eltex.nsk.ru/support/knowledge/upravlenie-po-snmp.php

=cut
#**********************************************************
sub _eltex_onu_status () {

  my %status = (
    0  => 'offline:text-red',
    1  => 'allocated',
    2  => 'authInProgress',
    3  => 'cfgInProgress',
    4  => 'authFailed',
    5  => 'cfgFailed',
    6  => 'reportTimeout',
    7  => 'ok:text-green',
    8  => 'authOk',
    9  => 'resetInProgress',
    10 => 'resetOk',
    11 => 'discovered',
    12 => 'blocked',
    13 => 'checkNewFw',
    14 => 'unidentified',
    15 => 'unconfigured',
  );

  return \%status;
}

#**********************************************************
# http://eltex.nsk.ru/support/knowledge/upravlenie-po-snmp.php
#**********************************************************
sub _eltex () {
  my ($attr) = @_;
  my %snmp = (
    gepon => {
      'ONU_MAC_SERIAL' => {
        NAME => 'Mac/Serial',
        OIDS => '.1.3.6.1.4.1.35265.1.21.16.1.1.1.6',
        PARSER => 'bin2mac'
      },
      'ONU_STATUS' => {
        NAME => 'Status',
        OIDS => '.1.3.6.1.4.1.35265.1.21.6.1.1.6.6',
        PARSER => ''
      },
      'ONU_RX_POWER' => {
        NAME => 'Rx_Power',
        OIDS => '.1.3.6.1.4.1.35265.1.21.6.1.1.15.6',
        PARSER => '_eltex_convert_power'
      },# tx_power = tx_power * 0.1;
      'ONU_TX_POWER' => {
        NAME => 'Tx_Power',
        OIDS => '',
        PARSER => ''
      },
      'OLT_RX_POWER' => {
        NAME => 'Olt_Rx_Power',
        OIDS => '',
        PARSER => ''
      },
      'ONU_DESC' => {
        NAME => 'Description',
        OIDS => '.1.3.6.1.4.1.35265.1.21.16.1.1.8.6',
        PARSER => ''
      },
      'ONU_IN_BYTE' => {
        NAME => 'In',
        OIDS => '',
        PARSER => ''
      },
      'ONU_OUT_BYTE' => {
        NAME => 'Out',
        OIDS => '',
        PARSER => ''
      },
      'TEMPERATURE' => {
        NAME => 'Temperature',
        OIDS => '',
        PARSER => ''
      },
      'reset' => {
        NAME => '',
        OIDS => '.1.3.6.1.4.1.35265.1.21.6.10.1.10',
        PARSER => ''
      },
      main_onu_info => {
        'ONU_TYPE' => {
          NAME => 'Onu_Type',
          OIDS => '.1.3.6.1.4.1.35265.1.21.6.1.1.2.6',
          PARSER => '_eltex_convert_onu_type'
        },
        'SOFT_VERSION' => {
          NAME => 'Soft_Version',
          OIDS => '',
          PARSER => ''
        },
        'VOLTAGE' => {
          NAME => 'Voltage',
          OIDS => '',
          PARSER => ''
        },
        'DISATNCE' => {
          NAME => 'Distance',
          OIDS => '',
          PARSER => ''
        }
      }
    },
    gpon => {
    }

  );

  if ($attr->{TYPE}) {
    return $snmp{$attr->{TYPE}};
  }

  return \%snmp;
}

#**********************************************************
=head2 _eltex_convert_power();

=cut
#**********************************************************
sub _eltex_convert_power{
  my ($power) = @_;

  $power = $power * 0.1 if ($power);

  return $power;
}

#**********************************************************
=head2 _eltex_convert_onu_type();

=cut
#**********************************************************
sub _eltex_convert_onu_type{
  my ($id) = @_;

  my @types = ('',
      'nte-2',
      'nte-2c',
      'nte-rg-1400f',
      'nte-rg-1400g',
      'nte-rg-1400f-w',
      'nte-rg-1400g-w',
      'nte-rg-1400fc',
      'nte-rg-1400gc',
      'nte-rg-1400fc-w',
      'nte-rg-1400gc-w',
      'nte-rg-1402f',
      'nte-rg-1402g',
      'nte-rg-1402f-w',
      'nte-rg-1402g-w',
      'nte-rg-1402fc',
      'nte-rg-1402gc',
      'nte-rg-1402fc-w',
      'nte-rg-1402gc-w',
      'nte-rg-2400g',
      'nte-rg-2400g-w',
      'nte-rg-2400g-w2',
      'nte-rg-2402g',
      'nte-rg-2402g-w',
      'nte-rg-2402g-w2',
      'nte-rg-2400gc',
      'nte-rg-2400gc-w',
      'nte-rg-2400gc-w2',
      'nte-rg-2402gc',
      'nte-rg-2402gc-w',
      'nte-rg-2402gc-w2',
      'nte-rg-2402gb',
      'nte-rg-2402gb-w',
      'nte-rg-2402gb-w2',
      'nte-rg-2402gcb',
      'nte-rg-2402gcb-w',
      'nte-rg-2402gcb-w2'
  );
  return $types[$id];
}

1