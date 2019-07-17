=head1 NAME

  Base info grabber

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Filters qw( dec2hex _mac_former bin2mac);
use Abills::Base qw( in_array );
require Equipment::Snmp_cmd;

my $debug = (defined($FORM{DEBUG})) ? $FORM{DEBUG} : 0;
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

  my %snmp_info = ();
  my %snmp_ports_info = ();

  my $perl_scalar = _get_snmp_oid( $attr->{SNMP_TPL} );

  if($perl_scalar && $perl_scalar->{ports}) {
    %snmp_ports_info = %{ $perl_scalar->{ports} };
  }

  if($perl_scalar && $perl_scalar->{info}) {
    %snmp_info = %{ $perl_scalar->{info} };
    if ( !$snmp_info{PORTS}{OIDS} ) {
      $snmp_info{PORTS} = $perl_scalar->{ports}->{PORT_TYPE};
      $snmp_info{PORTS}{WALK} = 1;
    }
  }

  if ( $FORM{ping} ){
    host_diagnostic( $FORM{ping} );
  }
  #Change port status
  elsif ( $attr->{PORT_STATUS} ){
    my ($port, $status) = split( /:/, $attr->{PORT_STATUS} );
#print $attr->{PORT_STATUS} . "<br>";
    # status
    # 0 - active
    # 1 - disable
    snmp_set({
      SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
      OID            => [ $snmp_ports_info{ADMIN_PORT_STATUS}{OIDS} . '.' . $port, "integer", "$status" ]
    });

    return 0;
  }

  my %ports_info = ();


  if ( $attr->{PORT_INFO} ){
    print "Debug" if($debug);
    if ( $attr->{PORT_INFO} =~ /TRAFFIC/ ){
      $attr->{PORT_INFO} .= ",PORT_IN,PORT_OUT";
    }

    my @port_info_list = split( /,\s?/, $attr->{PORT_INFO} );

    foreach my $type ( @port_info_list ){
      my $oid = '';

      if($type eq 'DISTANCE') {
        next;
      }

      if ( $snmp_ports_info{$type}{OIDS} ){
        $oid = $snmp_ports_info{$type}{OIDS};
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
        DEBUG   => ($debug > 2) ? 1 : undef
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

        if((! defined($ports_info{$port}{PORT_STATUS}) || $ports_info{$port}{PORT_STATUS} != 1)
          || (! defined($ports_info{$port}{PORT_TYPE}) || $ports_info{$port}{PORT_TYPE} != 6)) {
          next
        }

        if($attr->{TEST_DISTANCE}) {
          my $result = snmp_set({
            %{$attr},
            OID   => [ $snmp_ports_info{DISTANCE_ACTIVE}.'.'.$port, 'integer', 1 ],
            DEBUG => ($debug > 2) ? 1 : undef
          });

          #print "Port: $port /Port_status: $ports_info{$port}{PORT_STATUS} / $ports_info{$port}{PORT_TYPE} Result $result<br>\n";
          if ($result) {
            my $oid = $snmp_ports_info{DISTANCE};
            my $ports_info = snmp_get({
              %{$attr},
              OID   => $oid.'.'.$port,
              DEBUG => ($debug > 2) ? 1 : undef
            });
            $ports_info{$port}{DISTANCE} = $ports_info;
          }
        }
        else {
          $ports_info{$port}{DISTANCE} = '-';
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
      my $snmp_oid = $snmp_info{$key}{OIDS};

      if ($key eq 'PORTS' && $snmp_info{$key}{WALK}) {
        next;
      }
      if ( $snmp_oid ){
        my $res = snmp_get( {
          %{$attr},
          OID => $snmp_oid,
        } );

        if ( $res ){
          my $name = $snmp_info{$key}{NAME} || $key;
          my $function = $snmp_info{$key}->{PARSER};

          if ($function && defined( &{$function} ) ) {
            ($res) = &{ \&$function }($res);
          }
          $result_hash{$name} = $res;
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
    if ($snmp_info{'PORTS'}{WALK}) {
      my $ports_arr = snmp_get({
        %{$attr},
        OID  => $snmp_info{'PORTS'}{OIDS},
        WALK => 1
      });

      my $ports_list = ();
      for (my $i = 0; $i <= $#{ $ports_arr }; $i++) {
        next if (! $ports_arr->[$i]);
        my (undef, $type) = split(/:/, $ports_arr->[$i]);
        if (@skip_ports_types && !in_array($type, \@skip_ports_types)){
          push @{$ports_list}, $ports_arr->[$i];
        }
      }

      $snmp_info_result{'PORTS'} = $#{$ports_list} + 1;
    }
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
    $attr->{SNMP_TPL} //=$attr->{NAS_INFO}->{SNMP_TPL};
  }

  my $perl_scalar = _get_snmp_oid( $attr->{SNMP_TPL} );
  if($perl_scalar && $perl_scalar->{VLANS}) {
    $oid = $perl_scalar->{VLANS};
  }

  my $value = snmp_get({
    %{$attr},
    OID   => $oid,
    WALK  => 1,
    DEBUG => $FORM{DEBUG}
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

  if($perl_scalar && $perl_scalar->{ports}->{NATIVE_VLAN}->{OIDS}) {
    $oid = $perl_scalar->{ports}->{NATIVE_VLAN}->{OIDS};

    $value = snmp_get({
      %{$attr},
      OID  => $oid,
      WALK => 1
    });

    foreach my $line ( @{$value} ){
      next if (!$line);
      if ( $line =~ /^(\d+):(\d+)/ ){
        my $port_id = $1;
        my $vlan_id = $2; 
        if (!$vlan_hash{$vlan_id}{STATUS}) {
          if (!$vlan_hash{$vlan_id}{PORTS} ) {
            $vlan_hash{$vlan_id}{PORTS} .= "$port_id";
          }
          else {
            $vlan_hash{$vlan_id}{PORTS} .= ", $port_id";
          }
        }
      }
    }
  }
  return \%vlan_hash;
}

#********************************************************
=head2 get_fdb($attr) - Show FDB table

  Arguments:
    $attr
      NAS_INFO
      SNMP_TPL
      VERSION
      DEBUG

  Returns:
    {
    }

=cut
#********************************************************
sub get_port_vlans {
  my($attr) = @_;

  my %ports_vlans = ();

  my $oid = $attr->{PORT_VLAN_OID};

  my $port_vlan_list = snmp_get({
    TIMEOUT => 10,
    DEBUG   => $debug || 2,
    %{($attr) ? $attr : {}},
    OID     => $oid,
    WALK    => 1
  });

  foreach my $line (@$port_vlan_list) {
    my ($port, $vlan)=split(/:/, $line);
    $ports_vlans{$port}=$vlan;
  }

  return \%ports_vlans;
}

#********************************************************
=head2 get_fdb($attr) - Show FDB table

  Arguments:
    $attr
      NAS_INFO
      SNMP_TPL
      VERSION
      DEBUG

  Returns:
    {
    }

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

  if($attr->{NAS_INFO}) {
    $attr->{VERSION} //= $attr->{NAS_INFO}->{SNMP_VERSION};
    $attr->{SNMP_TPL} //=$attr->{NAS_INFO}->{SNMP_TPL};
  }

  my $snmp_oids;
  $debug = $attr->{DEBUG} || 0;
  my $nas_type = '';
  my $vendor_name = $attr->{NAS_INFO}->{VENDOR_NAME} || $attr->{NAS_INFO}->{NAME} || q{};
  if ($attr->{NAS_INFO}->{TYPE_ID} && $attr->{NAS_INFO}->{TYPE_ID} == 4) {
    $nas_type = equipment_pon_init($attr);
    if (defined(&{ $nas_type })) {

    }
  }
  elsif($vendor_name eq 'Cisco') {
    $nas_type = 'cisco';
  }

  my $get_fdb   = $nas_type.'_get_fdb';
  my %fdb_hash  = ();
  my $port_vlans;


  if($debug > 3) {
    print "VENDOR: $vendor_name-- $get_fdb\n";
  }

  if (defined( &{$get_fdb} )) {
    if ($debug > 1) {
      print "Function: $get_fdb\n";
    }

    %fdb_hash = &{ \&$get_fdb }( $attr );
  }
  else {
    my $oid = '.1.3.6.1.2.1.17.7.1.2.2.1.2';
    if(! $snmp_oids) {
      $snmp_oids = _get_snmp_oid($attr->{NAS_INFO}{SNMP_TPL}, $attr);
    }

    if($snmp_oids) {
      if ($snmp_oids->{PORT_VLAN_UNTAGGED}) {
        $attr->{PORT_VLAN_OID}=$snmp_oids->{PORT_VLAN_UNTAGGED};
        $port_vlans = get_port_vlans($attr);
      }
      if ($snmp_oids->{FDB_OID}) {
        $oid = $snmp_oids->{FDB_OID};
      }
    }

    if ($debug > 1) {
      print "OID: $oid\n";
    }

    my $mac_port_list = snmp_get({
      TIMEOUT => 10,
      DEBUG   => $debug || 2,
      %{($attr) ? $attr : {}},
      OID     => $oid,
      WALK    => 1
    });

    my ($expr_, $values, $attribute);
    my @EXPR_IDS = ();

    if ($snmp_oids && $snmp_oids->{FDB_EXPR}) {
      $snmp_oids->{FDB_EXPR} =~ s/\%\%/\\/g;
      ($expr_, $values, $attribute) = split( /\|/, $snmp_oids->{FDB_EXPR} || '' );
      @EXPR_IDS = split( /,/, $values );
    }

    my %ports_index = ();
    my $port_index_oid = $snmp_oids->{PORT_INDEX} || '';
    if ($port_index_oid) {
      my $value_ = snmp_get({
        TIMEOUT => 10,
        DEBUG   => $debug || 2,
        %{($attr) ? $attr : {}},
        OID     => $port_index_oid,
        WALK    => 1
      });
      foreach my $line (@{ $value_ }) {
        my ($index, $num) = split( /:/, $line, 2 );
        $ports_index{ $num } = $index;
      }
    }

    my %ports_name = ();
    my $port_name_oid = $snmp_oids->{ports}->{PORT_NAME}->{OIDS} || '';
    if ($port_name_oid) {
      my $value_ = snmp_get({
        TIMEOUT => 10,
        DEBUG   => $debug || 2,
        %{($attr) ? $attr : {}},
        OID     => $port_name_oid,
        WALK    => 1
      });
      foreach my $line (@{ $value_ }) {
        my ($index, $name) = split( /:/, $line, 2 );
        $index = $ports_index{ $index } || $index;
        $ports_name{ $index } = $name;
      }
    }

    foreach my $line (@{ $mac_port_list }) {
      next if (!$line);
      my $vlan      = 0;
      my $mac_dec;
      my $port      = 0;
      my $port_name = '';

      if ($snmp_oids && $snmp_oids->{FDB_EXPR}) {
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

        $vlan      = $result{VLAN} || 0;
        $mac_dec   = $result{MAC} || '';
        $port      = $ports_index{ $result{PORT} } || $result{PORT} || '';
        $port_name = $ports_name{ $port } || '';
      }
      else {
        ($oid, $mac_port_list) = split( /:/, $line, 2 );

        $oid =~ /(\d+)\.(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})$/;
        my $record_type = $1;
        $mac_dec = $2 || q{};
        if( $record_type == 1) {
          #$vlan = $value;
        }
        elsif($record_type == 2) {
          $port      = $mac_port_list;
          $port_name =  $ports_name{ $port } || '';
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
      if(defined($port)) {
        $fdb_hash{$mac_dec}{2} = $port;
      }
      # 3 status
      # 4 vlan
      if($vlan) {
        $fdb_hash{$mac_dec}{4} = $vlan;
      }

      if($port_vlans && $port_vlans->{$port}) {
        $fdb_hash{$mac_dec}{4} = $port_vlans->{$port};
      }

      # 5 port name
      if($port_name) {
        $fdb_hash{$mac_dec}{5} = $port_name;
      }
    }
  }

  return \%fdb_hash;
}

#********************************************************
=head2 cisco_get_fdb($attr)

  Arguments:
    $attr,
      SNMP_COMMUNITY
      NAS_INFO
      SNMP_TPL
      FILTER
      DEBUG

  Returns:
    {}

=cut
#********************************************************
sub cisco_get_fdb {
  my($attr)=@_;
  my %fdb_result = ();

  if($attr->{DEBUG}) {
    $debug = $attr->{DEBUG};
  }

  my $oid = '.1.3.6.1.4.1.9.9.46.1.3.1.1.2';
  my $value = snmp_get({
    TIMEOUT => 10,
    DEBUG   => $debug || 2,
    %{($attr) ? $attr : {}},
    OID     => $oid,
    WALK    => 1
  });

  my @vlans = ();
  foreach my $vlan_info (@$value) {
     if($vlan_info =~ /(\d+):/) {
       push @vlans, $1;
     }
  }

  my %port_index = ();

  foreach my $vlan ( @vlans ) {
    my $vlan_snmp = $attr->{SNMP_COMMUNITY};
    $vlan_snmp =~ s|\@|\@$vlan\@|;

    my $if_indexes = snmp_get({
      TIMEOUT        => 10,
      DEBUG          => $debug || 2,
      %{($attr) ? $attr : {}},
      SNMP_COMMUNITY => $vlan_snmp,
      OID            => '.1.3.6.1.2.1.17.1.4.1.2',
      WALK           => 1
    });

    foreach my $if_index_info ( @$if_indexes  ) {
      if($if_index_info && $if_index_info =~ /(\d+):(\d+)/) {
        $port_index{$1}=$2;
      }
    }
  }

  #Get fdb per VLAN
  foreach my $vlan ( @vlans ) {
    my $vlan_snmp = $attr->{SNMP_COMMUNITY};
    $vlan_snmp =~ s|\@|\@$vlan\@|;

    my $fdb_list = snmp_get({
      TIMEOUT        => 10,
      DEBUG          => $debug || 2,
      %{($attr) ? $attr : {}},
      SNMP_COMMUNITY => $vlan_snmp,
      OID            => '.1.3.6.1.2.1.17.4.3.1',
      WALK           => 1
    });

    foreach my $fdb_info ( @$fdb_list  ) {
      if($fdb_info && $fdb_info =~ /(\d+)\.([\d\.]+):(.+)/) {
        my $id      = $1;
        my $mac_dec = $2;
        my $result  = $3;

        my $port_name = q{};
        if($id == 1 ) {
          $result = _mac_former( $mac_dec );
        }
        elsif($id == 2) {
          $port_name = $port_index{$result};
        }

        $fdb_result{$mac_dec}{$id} = $result;
        # 3 status
        # 4 vlan
        if($vlan) {
          $fdb_result{$mac_dec}{4} = $vlan;
        }
        # 5 port name

        if($port_name) {
          $fdb_result{$mac_dec}{5} = $port_name;
        }
      }
    }
  }

  return %fdb_result;
}

1;
