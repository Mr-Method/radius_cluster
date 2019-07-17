=head1 NAME

  Base info grabber

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Filters qw( dec2hex _mac_former);
use Abills::Base qw( in_array );

our @skip_ports_types = [135,142,136,1,24,250,300,53];

#********************************************************
=head2 equipment_test($attr)

  Arguments:
    $attr
      PORT_INFO
      PORT_ID    - Port ID (Get stats for one port)
      TIMEOUT
      TEST_OID   - Array of oids
      PORT_STATUS

  Returns:
    ports_info_hash_ref

=cut
#********************************************************
sub equipment_test{
  my ($attr) = @_;

  my %snmp_info = (
    DESCRIBE  => '.1.3.6.1.2.1.1.1.0',
    SYSTEM_ID => '.1.3.6.1.2.1.1.5.0',
    PORTS     => '.1.3.6.1.2.1.2.2.1.3', # port Type
    #   PORTS_DESCRIBE=> '.1.3.6.1.2.1.2.2.1.2', # ifDescr
    #FIRMWARE  => '1.3.6.1.2.1.16.19.2.0',
    FIRMWARE2 => '',
    UPTIME    => '.1.3.6.1.2.1.1.3.0',
    SERIAL    => '',
    LOAD      => '',
    MEM       => '',
  );

  my %snmp_ports_info = (
    PORT_NAME   => '.1.3.6.1.2.1.2.2.1.2',
    PORT_STATUS => '.1.3.6.1.2.1.2.2.1.8',
    PORT_IN     => '.1.3.6.1.2.1.2.2.1.10',
    PORT_OUT    => '.1.3.6.1.2.1.2.2.1.16',
    PORT_SPEED  => '.1.3.6.1.2.1.2.2.1.5',
    PORT_DESCR  => '.1.3.6.1.2.1.31.1.1.1.18',
    PORT_TYPE   => '.1.3.6.1.2.1.2.2.1.3',
    PORT_IN_ERR => '.1.3.6.1.2.1.2.2.1.14',
    PORT_OUT_ERR=> '.1.3.6.1.2.1.2.2.1.20',
  );

  if ( $FORM{ping} ){
    host_diagnostic( $FORM{ping} );
  }
  #Change port status
  elsif ( $attr->{PORT_STATUS} ){
    my ($port, $status) = split( /:/, $attr->{PORT_STATUS} );

    # status
    # 0 - active
    # 1 - disable
    snmp_set({
      SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
      OID            => [ $snmp_ports_info{PORT_STATUS} . '.' . $port, "integer", "$status" ]
    });

    return 0;
  }

  my %ports_info = ();
  my $perl_scalar = _get_snmp_oid( $attr->{SNMP_TPL} );

  foreach my $key (keys %snmp_ports_info) {
    if($perl_scalar && $perl_scalar->{$key}) {
      $snmp_ports_info{$key} = $perl_scalar->{$key};
    }
  }

  if($perl_scalar && $perl_scalar->{ports}) {
    foreach my $key (keys %{ $perl_scalar->{ports} }) {
      $snmp_ports_info{$key} = $perl_scalar->{ports}->{$key}->{OIDS};
    }
  }

  if ( $attr->{PORT_INFO} ){
    print "Debug" if($FORM{DEBUG});
    if ( $attr->{PORT_INFO} =~ /TRAFFIC/ ){
      $attr->{PORT_INFO} .= ",PORT_IN,PORT_OUT";
    }

    my @port_info_list = split( /,\s?/, $attr->{PORT_INFO} );

    foreach my $type ( @port_info_list ){
      my $oid = '';

      if($type eq 'DISTANCE') {
        next;
      }

      if ( $snmp_ports_info{$type} ){
        $oid = $snmp_ports_info{$type};
      }
      elsif (ref $attr->{SNMP_TPL} eq 'HASH' && $attr->{SNMP_TPL}->{$type} ){
        $oid = $attr->{SNMP_TPL}->{$type}->{OIDS};
      }
      else{
        next;
      }

      my $ports_info = snmp_get({
        %{$attr},
        OID     => $oid . (($attr->{PORT_ID}) ? ".$attr->{PORT_ID}" : q{}),
        WALK    => ($attr->{PORT_ID}) ? 0 : 1,
        DEBUG   => ($FORM{DEBUG} && $FORM{DEBUG} > 2) ? 1 : undef
      });

      if ( !defined($ports_info) ){
        next;
      }

      if($attr->{PORT_ID}) {
        $ports_info{$attr->{PORT_ID}}{$type} = $ports_info;
        next;
      }

      foreach my $port ( @{$ports_info} ){
        next if (!defined($port));
        my ($port_id, $data) = split( /:/, $port, 2 );
        $ports_info{$port_id}{$type} = $data;
      }
    }

    if(in_array('DISTANCE', \@port_info_list) && $snmp_ports_info{DISTANCE}) {
      foreach my $port (sort { $a <=> $b } keys %ports_info) {
        if(! $ports_info{$port}{PORT_TYPE}) {
          $ports_info{$port}{PORT_TYPE} = snmp_get({
            %{$attr},
            OID   => $snmp_ports_info{PORT_TYPE}.'.'.$port,
          });
        }

        next if($ports_info{$port}{PORT_STATUS} != 1 || $ports_info{$port}{PORT_TYPE} != 6);

        my $result = snmp_set({
          %{$attr},
          OID     => [ $snmp_ports_info{DISTANCE_ACTIVE} .'.'. $port, 'integer', 1 ],
          DEBUG   => ($FORM{DEBUG} && $FORM{DEBUG} > 2) ? 1 : undef
        });

        #print "Port: $port /Port_status: $ports_info{$port}{PORT_STATUS} / $ports_info{$port}{PORT_TYPE} Result $result<br>\n";
        if($result) {
          my $oid = $snmp_ports_info{DISTANCE};
          my $ports_info = snmp_get({
            %{$attr},
            OID   => $oid.'.'.$port,
            DEBUG => ($FORM{DEBUG} && $FORM{DEBUG} > 2) ? 1 : undef
          });
          $ports_info{$port}{DISTANCE} = $ports_info;
        }
      }
    }
  }

  if ( $attr->{TEST_OID} ){
    my %result_hash = ();

    if ($attr->{TEST_OID} ne '1') {
      my @test_oids = split(/,\s?/, $attr->{TEST_OID});
      foreach my $k ( keys %snmp_info ) {
        if (! in_array($k, \@test_oids)) {
          delete $snmp_info{$k};
        }
      }
    }

    foreach my $key ( keys %snmp_info ){
      my $snmp_oid = $snmp_info{$key};

      if ($key eq 'PORTS') {
        next;
      }

      if ( $snmp_oid ){
        my $res = snmp_get( {
          %{$attr},
          OID => $snmp_oid,
        } );

        if ( $res ){
          $result_hash{$key} = $res;
        }
        else {
          #Last if no response
          if($key eq 'UPTIME') {
            return {};
          }
        }
      }
    }

    my %snmp_info_result = ();
    foreach my $key ( keys %result_hash ){
      my $value = $result_hash{$key};
      $snmp_info_result{$key} = $value;
    }

    #Get ports
    my $ports_arr = snmp_get({
      %{$attr},
      OID  => $snmp_info{'PORTS'},
      WALK => 1
    });

    my $ports_list = ();
    for (my $i = 0; $i <= $#{ $ports_arr }; $i++) {
      my (undef, $type) = split(/:/, $ports_arr->[$i]);
      if (@skip_ports_types && !in_array($type, \@skip_ports_types)){
        push @{$ports_list}, $ports_arr->[$i];
      }
    }

    $snmp_info_result{'PORTS'} = $#{$ports_list} + 1;
    return \%snmp_info_result;
  }

  return \%ports_info;
}

#********************************************************
=head2 get_vlans($attr) - Get VLANs

  Arguments:
    $attr
      SNMP_TPL
      NAS_INFO
      VERSION

  Returns:
    Hash of vlans

=cut
#********************************************************
sub get_vlans{
  my ($attr) = @_;

  my $oid = '.1.3.6.1.2.1.17.7.1.4.3.1.1';

  if($attr->{NAS_INFO}) {
    $attr->{VERSION} //= $attr->{NAS_INFO}->{SNMP_VERSION};
  }

  my $perl_scalar = _get_snmp_oid( $attr->{SNMP_TPL} );
  if($perl_scalar && $perl_scalar->{VLANS}) {
    $oid = $perl_scalar->{VLANS};
  }

  my $value = snmp_get({
    %{$attr},
    OID  => $oid,
    WALK => 1
  });

  my %vlan_hash = ();

  foreach my $line ( @{$value} ){
    next if (!$line);

    if ( $line =~ /^(\d+):(.*)/ ){
      my $vlan_id = $1;
      my $name    = $2;
      $vlan_hash{$vlan_id}{NAME} = $name;
    }
    elsif ( $line =~ /^\d+.(\d+)\.(\d+):(.+)/ ){
      my $type = $1;
      my $vlan_id = $2;
      my $value2 = $3;

      if ( $type == 1 ){
        $vlan_hash{$vlan_id}{NAME} = $value2;
      }
      #ports
      elsif ( $type == 2 ){
        my $p = unpack( "B64", $value2 );
        my $ports = '';
        for ( my $i = 0; $i < length( $p ); $i++ ){
          my $port_val = substr( $p, $i, 1 );
          if ( $port_val == 1 ){
            $ports .= ($i + 1) . ", ";
          }
        }

        $vlan_hash{$vlan_id}{PORTS} = $ports;
      }
      elsif ( $type == 6 ){
        $vlan_hash{$vlan_id}{STATUS} = $value2;
      }
    }
  }

  return \%vlan_hash;
}

#********************************************************
=head2 equipment_fdb_grab($attr) - Show FDB table

  Arguments:
    $attr

=cut
#********************************************************
sub get_fdb {
  my($attr) = @_;

  #$Nas->info({
  #  NAS_ID    => $nas_id,
  #  COLS_NAME => 1,
  #  COLS_UPPER=> 1
  #});

  #=comments
  ## Get fdb from default table
  #  my $oid = $perl_scalar->{FDB_OID} || '.1.3.6.1.2.1.17.4.3.1';    #|| '1.3.6.1.4.1.3320.152.1.1.3';
  #  my $value = snmp_get(
  #    {
  #      %$attr,
  #      OID  => $oid,
  #      WALK => 1
  #    }
  #  );
  #  my %fdb_hash = ();
  #
  #  foreach my $line (@$value) {
  #    my ($oid, $value) = split(/:/, $line, 2);
  #    $oid =~ /(\d+)\.(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})/;
  #    my $type    = $1;
  #    my $mac_dec = $2;
  #    my $mac = _mac_former($mac_dec);
  #
  #    if ($attr->{FILTER}) {
  #      if ($mac =~ m/($attr->{FILTER})/) {
  #        my $search = $1;
  #        $mac =~ s/$search/<b>$search<\/>/g;
  #      }
  #      else {
  #        next;
  #      }
  #    }
  #
  #    $fdb_hash{$mac_dec}{$type} = ($type == 1) ? $mac : $value;
  #  }
  #=cut

  #dlink version
  # '1.3.6.1.2.1.17.7.1.2.2.1.2';
  #$Equipment->vendor_info( $Equipment->{VENDOR_ID} || $attr->{VENDOR_ID} );
  #For old version

  my $debug = $attr->{DEBUG} || 0;
  my $nas_type = '';
  if ($attr->{NAS_INFO}->{TYPE_ID} && $attr->{NAS_INFO}->{TYPE_ID} == 4) {
    $nas_type = equipment_pon_init($attr);
  }

  my $get_fdb = $nas_type.'_get_fdb';
  my %fdb_hash = ();

  if (defined( &{$get_fdb} )) {
    if ($debug > 1) {
      print "Function: $get_fdb\n";
    }

    %fdb_hash = &{ \&$get_fdb }({
      %$attr,
      SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
      NAS_INFO       => $attr->{NAS_INFO},
      SNMP_TPL       => $attr->{SNMP_TPL},
      FILTER         => $attr->{FILTER} || ''
    });
  }
  else {
    my $perl_scalar = _get_snmp_oid( $attr->{SNMP_TPL} );
    my $oid = '.1.3.6.1.2.1.17.4.3.1';
    if ($perl_scalar && $perl_scalar->{FDB_OID}) {
      $oid = $perl_scalar->{FDB_OID};
    }

    if ($debug > 1) {
      print "OID: $oid\n";
    }

    my $value = snmp_get({
      %{$attr},
      OID     => $oid,
      WALK    => 1,
      TIMEOUT => 8,
      DEBUG   => $FORM{DEBUG} || 2
    });

    my ($expr_, $values, $attribute);
    my @EXPR_IDS = ();

    if ($perl_scalar && $perl_scalar->{FDB_EXPR}) {
      $perl_scalar->{FDB_EXPR} =~ s/\%\%/\\/g;
      ($expr_, $values, $attribute) = split( /\|/, $perl_scalar->{FDB_EXPR} || '' );
      @EXPR_IDS = split( /,/, $values );
    }

    foreach my $line (@{ $value }) {
      next if (!$line);
      my $vlan     = 0;
      my $mac_dec;
      my $port     = 0;

      if ($perl_scalar && $perl_scalar->{FDB_EXPR}) {
        my %result = ();

        if (my @res = ($line =~ /$expr_/g)) {
          for (my $i = 0; $i <= $#res; $i++) {
            $result{$EXPR_IDS[$i]} = $res[$i];
          }
        }

        if ($result{MAC_HEX}) {
          $result{MAC} = _mac_former( $result{MAC_HEX}, { BIN => 1 } );
        }

        if ($result{PORT_DEC}) {
          $result{PORT} = dec2hex($result{PORT_DEC});
        }

        $vlan    = $result{VLAN} || 0;
        $mac_dec = $result{MAC} || '';
        $port    = $result{PORT} || '';
      }
      else {
        ($oid, $value) = split( /:/, $line, 2 );

        $oid =~ /(\d+)\.(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})$/;
        my $record_type = $1;
        $mac_dec = $2 || q{};
        if( $record_type == 1) {
          #$vlan = $value;
        }
        elsif($record_type == 2) {
          $port    = $value;
        }
      }

      my $mac = _mac_former( $mac_dec );

      if ($attr->{FILTER}) {
        $attr->{FILTER} = lc( $attr->{FILTER} );
        if ($mac =~ m/($attr->{FILTER})/) {
          my $search = $1;
          $mac =~ s/$search/<b>$search<\/>/g;
        }
        else {
          next;
        }
      }

      # 1 mac
      $fdb_hash{$mac_dec}{1} = $mac;
      # 2 port
      if($port) {
        $fdb_hash{$mac_dec}{2} = $port;
      }
      # 3 status
      # 4 vlan
      if($vlan) {
        $fdb_hash{$mac_dec}{4} = $vlan;
      }
    }
  }

  return \%fdb_hash;
}



1;