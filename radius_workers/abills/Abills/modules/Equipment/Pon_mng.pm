

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(load_pmodule2 in_array int2byte);

our(
  $html,
  %lang,
  @service_status,
  $SNMP_TPL_DIR,
);

our Equipment $Equipment;

#********************************************************
=head2 equipment_pon_init($attr)

=cut
#********************************************************
sub equipment_pon_init {
  my ($attr) = @_;
  my $nas_type = '';

  unshift( @INC, '../../Abills/modules/' );

  my $vendor_name = $attr->{VENDOR_NAME}  || $attr->{NAS_INFO}->{NAME};
  if (! $vendor_name) {
    return '';
  }

  if ( $vendor_name =~ /ELTEX/i ){
    require Equipment::Eltex;
    $nas_type = '_eltex';
  }
  elsif ( $vendor_name =~ /ZTE/i ){
    require Equipment::Zte;
    $nas_type = '_zte';
  }
  elsif ( $vendor_name =~ /HUAWEI/i ){
    require Equipment::Huawei;
    $nas_type = '_huawei';
  }
  elsif ( $vendor_name =~ /BDCOM/i ){
    require Equipment::Bdcom;
    $nas_type = '_bdcom';
  }

  return $nas_type;
}


#********************************************************
=head2 equipment_pon_get_ports($attr) - Show PON information

  Arguments:
    $attr
      SNMP_COMMUNITY
      NAS_INFO

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_pon_get_ports{
  my ($attr) = @_;

  my $port_list = $Equipment->pon_port_list({ COLS_NAME => 1, COLS_UPPER => 1, NAS_ID => $attr->{NAS_ID} });
  my $ports = ();
  foreach my $line (@$port_list){
    $ports->{$line->{snmp_id}} = $line;
  }
  my $get_ports_fn = $attr->{NAS_TYPE} . '_get_ports';

  if ( ! $Equipment->{STATUS} ){
    if ( defined( &{$get_ports_fn} ) ){
      my $olt_ports = &{ \&$get_ports_fn }({
        %{ ($attr) ? $attr : {} },
        SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
        SNMP_TPL       => $attr->{SNMP_TPL},
        MODEL_NAME     => $attr->{MODEL_NAME}
      });

      foreach my $snmp_id (keys %{ $olt_ports }) {
        if (!$ports->{$snmp_id}) {
          $Equipment->pon_port_add({ SNMP_ID => $snmp_id, NAS_ID => $attr->{NAS_ID}, %{ $olt_ports->{$snmp_id} } });
        }
        else {
          if ($ports->{$snmp_id}{BRANCH_DESC} && $ports->{$snmp_id}{BRANCH_DESC} ne $olt_ports->{$snmp_id}{BRANCH_DESC}){
            my $set_desc_fn = $attr->{NAS_TYPE} . '_set_desc';
            if ( defined( &{$set_desc_fn} ) ){
              &{ \&$set_desc_fn }({
                SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
                PORT           => $snmp_id,
                PORT_TYPE      => $ports->{$snmp_id}{PON_TYPE},
                DESC           => $ports->{$snmp_id}{BRANCH_DESC}
              });
            }
          }
        }

        foreach my $key (keys %{ $olt_ports->{$snmp_id} }) {
          $ports->{$snmp_id}{$key} = $olt_ports->{$snmp_id}{$key};
        }
      }
    }
  }
  else {
    if ($html) {
      $html->message( 'info', $lang{INFO}, "$lang{STATUS} $service_status[$Equipment->{STATUS}]" );
    }
  }

  return $ports;
}

#********************************************************
=head2 _get_snmp_oid($type, $attr) - Get oid tpl

  Arguments:
    $type
    $attr
      BASE_DIR

=cut
#********************************************************
sub _get_snmp_oid{
  my ($type, $attr) = @_;

  if ( !$type ){
    return '';
  }

  my $path = ($attr->{BASE_DIR}) ? $attr->{BASE_DIR}.'/' : q{};

  my $content = file_op({
    FILENAME => $path.$SNMP_TPL_DIR . '/' . $type,
    PATH     => $path.$SNMP_TPL_DIR,
  });

  my $result;

  if ( $content ){
    load_pmodule2( "JSON" );
    my $json = JSON->new->allow_nonref;

    $result = $json->decode( $content );
  }

  return $result;
}


#********************************************************
=head2 equipment_pon($attr) - Show PON information

  Arguments:
    $attr
      SNMP_COMMUNITY
      NAS_INFO

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_pon{
  my ($attr) = @_;

  my $SNMP_COMMUNITY = $attr->{SNMP_COMMUNITY};
  my $nas_id = $FORM{NAS_ID};

  $Equipment->vendor_info( $Equipment->{VENDOR_ID} );
  #For old version
  my $nas_type = equipment_pon_init($attr);

  if (!$nas_type) {
    return 0;
  }

  my $snmp = &{ \&{$nas_type} }({ TYPE => $FORM{ONU_TYPE} });

  if ( $FORM{ONU} ){
    pon_onu_state( $FORM{ONU}, {
      %{$attr},
      snmp        => $snmp,
      ONU_TYPE    => $FORM{ONU_TYPE},
      ONU_SNMP_ID => $FORM{info_pon_onu}
    });
    return 1;
  }
  elsif ( $FORM{graph_pon_onu} ){
    equipment_pon_onu_graph({  ONU_SNMP_ID => $FORM{graph_pon_onu}, snmp => $snmp });
  }
  elsif($FORM{chg_pon_onu}) {
    $html->message('info', "$lang{CHANGE} ONU", "$FORM{chg_pon_onu}");
  }
  elsif($FORM{unregister}) {
    equipment_unregister_onu($attr);
    return 1;
  }
  elsif ( $FORM{onuReset} ){
    if ( snmp_set( $SNMP_COMMUNITY, $snmp->{reset}->{OIDS} . '.' . $FORM{onuReset}, "integer", "1" ) ){
      $html->message( 'info', $lang{INFO}, $lang{REBOOT} .': '. $snmp->{reset}->{OIDS} );
    }
  }

  if ( $SNMP_Session::errmsg ){
    $html->message( 'err', $lang{ERROR},
      "OID: " . ($attr->{OID} || q{}) . "\n\n $SNMP_Session::errmsg\n\n$SNMP_Session::suppress_warnings\n" );
  }

  my $pon_types = ();
  my $olt_ports = ();
  #Port select
  my $port_list = $Equipment->pon_port_list({ COLS_NAME => 1, COLS_UPPER => 1, NAS_ID => $Equipment->{NAS_ID} });
  foreach my $line (@$port_list){
    $pon_types->{ $line->{pon_type} } = uc($line->{pon_type});
    $olt_ports->{ $line->{id} } = "$line->{branch_desc} ($line->{branch})" if ($FORM{PON_TYPE} && $FORM{PON_TYPE} eq $line->{pon_type});
  }

  $FORM{PON_TYPE} = '' if (!$FORM{PON_TYPE});
  my @rows = ();
  push @rows, "$lang{TYPE}:", $html->form_select( 'PON_TYPE',
      {
        SELECTED => $FORM{PON_TYPE},
        SEL_HASH => $pon_types,
        #SORT_KEY_NUM=> 1,
        SEL_OPTIONS => { '' => $lang{SELECT_TYPE} },
        EX_PARAMS => " data-auto-submit='index=$index&visual=$FORM{visual}&NAS_ID=$nas_id' ",
        NO_ID    => 1
      } );

  push @rows, "$lang{PORTS}:", $html->form_select( 'OLT_PORT',
      {
        SELECTED    => $FORM{OLT_PORT},
        SEL_HASH    => $olt_ports,
        #SORT_KEY_NUM=> 1,
        SEL_OPTIONS => { '' => $lang{SELECT_PORT} },
        EX_PARAMS => " data-auto-submit='index=$index&visual=$FORM{visual}&NAS_ID=$nas_id&PON_TYPE=$FORM{PON_TYPE}' ",
        NO_ID       => 1
      } );

  my $unregister_fn = $nas_type . '_unregister';
  if(defined( &$unregister_fn )) {
    my $macs = &{ \&$unregister_fn }({ %$attr });

    push @rows, $html->button($lang{UNREGISTER} .' '. ( $#{ $macs }+1 ),
        "index=$index&visual=$FORM{visual}&NAS_ID=$nas_id&PON_TYPE=$FORM{PON_TYPE}&unregister=1",
        { class => 'btn btn-default'. (($#{ $macs } > -1) ? ' btn-warning' : q{}) });
  }

  my %info = ();
  foreach my $val ( @rows ){
    $info{ROWS} .= $html->element( 'div', $val, { class => 'form-group' } );
  }

  #Get users mac
  my %users_mac = ();
  my $users_mac = $Equipment->mac_log_list({
    PORT      => '_SHOW',
    MAC       => '_SHOW',
    PAGE_ROWS => 20000,
    COLS_NAME => 1,
    NAS_ID    => $nas_id
  });

  foreach my $line (@$users_mac) {
    push @{ $users_mac{$line->{port}} }, $line->{mac};
  }

  my $report_form = $html->element( 'div', $info{ROWS}, { class => 'well well-sm' } );

  print $html->form_main({
    CONTENT => $report_form,
    HIDDEN  => {
      'index'  => $index,
      'visual' => $FORM{visual},
      'NAS_ID' => $nas_id
    },
    NAME    => 'report_panel',
    ID      => 'report_panel',
    class   => 'form-inline',
  });

  my $page_gs = "&visual=$FORM{visual}&NAS_ID=$nas_id";
  $page_gs .= "&PON_TYPE=$FORM{PON_TYPE}" if ($FORM{PON_TYPE});
  $page_gs .= "&OLT_PORT=$FORM{OLT_PORT}" if ($FORM{OLT_PORT});
  $LIST_PARAMS{NAS_ID}   = $nas_id;
  $LIST_PARAMS{PON_TYPE} = $FORM{PON_TYPE} || '';
  $LIST_PARAMS{OLT_PORT} = $FORM{OLT_PORT} || '';

  my ($table, $list) = result_former({
    INPUT_DATA      => $Equipment,
    FUNCTION        => 'onu_list',
    DEFAULT_FIELDS  => 'BRANCH,ONU_ID,MAC_SERIAL,STATUS,RX_POWER',
    SKIP_PAGES      => 1,
    BASE_FIELDS     => 1,
    TABLE           => {
      width            => '100%',
      caption          => "PON ONU",
      qs               => $page_gs,
      SHOW_COLS        => {
        onu_snmp_id  => "SNMP ID",
        branch       => "BRANCH",
        onu_id       => "ONU_ID",
        mac_serial   => "MAC_SERIAL",
        status       => $lang{ONU_STATUS},
        rx_power     => "RX_POWER",
        tx_power     => "TX_POWER",
        olt_rx_power => "OLT_RX_POWER",
        comments     => $lang{COMMENTS},
        address_full => $lang{ADDRESS},
        login        => $lang{LOGIN},
        traffic      => $lang{TRAFFIC},
        onu_dhcp_port=> "DHCP $lang{PORTS}",
        distance     => $lang{DISTANCE},
        fio          => $lang{FIO},
        user_mac     => "$lang{USER} MAC",
        vlan_id      => 'VLAN',
        datetime     => $lang{UPDATED}
      },
      SHOW_COLS_HIDDEN => {
        PON_TYPE => $FORM{PON_TYPE},
        OLT_PORT => $FORM{OLT_PORT},
        visual => $FORM{visual},
        NAS_ID => $nas_id,
      },
      ID               => 'EQUIPMENT_ONU',
      EXPORT           => 1,
    }
  });

  my $used_ports = equipments_get_used_ports({
    NAS_ID     => $nas_id,
    FULL_LIST  => 1,
    PORTS_ONLY => 1,
  });

  my @cols = ();
  if ( $table->{COL_NAMES_ARR} ){
    @cols = @{ $table->{COL_NAMES_ARR} };
  }
  my @all_rows = ();
  foreach my $line ( @$list ){
    my @row = ();

    for ( my $i = 0; $i <= $#cols; $i++ ){
      my $col_id = $cols[$i];
      last if ($col_id eq 'id');
      #print "Port: $port col: $i '$col_id' // $olt_ports->{$port}->{$col_id} //<br>";
      if ($col_id eq 'login' || $col_id eq 'address_full'){
        my $value;
        if ($used_ports->{$line->{dhcp_port}}) {
          foreach my $uinfo (@{ $used_ports->{$line->{dhcp_port}} }) {
            $value .= $html->br() if ($value);
            if ($col_id eq 'login') {
              $value .= $html->button( $uinfo->{login}, "index=11&UID=$uinfo->{uid}" );
            }
            elsif ($col_id eq 'address_full') {
              $value .= $uinfo->{address_full} || "";
            }
          }
        }
        elsif ( $line->{user_mac} && $users_mac{$line->{user_mac}} )  {
          foreach my $mac ( @{ $users_mac{$line->{user_mac}} }) {
            if ($used_ports->{$mac}) {
              foreach my $uinfo (@{ $used_ports->{$mac} }) {
                $value .= $html->br() if ($value);
                if ($col_id eq 'login') {
                  $value .= $html->button( $uinfo->{login}, "index=11&UID=$uinfo->{uid}" );
                  if($uinfo->{duration}) {
                    $value .= " ($uinfo->{duration})";
                    my $dhcp_user_index = get_function_index('dhcphosts_user');
                    $value .= ' '. $html->button( $uinfo->{login},
                      "index=$dhcp_user_index&UID=$uinfo->{uid}&add_form=1&PORTS="
                        .($line->{onu_dhcp_port} || $line->{dhcp_port}) ."&NAS_ID=$nas_id&OPTION_82=1",
                      { class => 'add', TITLE => "$lang{ADD} DHCP" });
                  }
                  else {
                    $value .= ' (Dv)';
                  }
                }
                elsif ($col_id eq 'address_full') {
                  $value .= $uinfo->{address_full} || "";
                }
              }
            }
          }
        }
        else {
          $value = '';
        }
        push @row, $value;
        next;
      }
      elsif ( $col_id eq 'traffic' ){
        my ($in, $out) = split( /,/, $line->{traffic} );
        push @row, "in: " . int2byte( $in ) . $html->br() . "out: " . int2byte( $out );
      }
      elsif ( $col_id =~ /power/ ){
        push @row, pon_tx_alerts( $line->{$col_id} );
      }
      elsif ( $col_id eq 'status' ){
        push @row, pon_onu_convert_state($nas_type, $line->{status}, $line->{pon_type} );
      }
      elsif ( $col_id eq 'branch' ){
        push @row, uc($line->{pon_type}) . ' ' . $line->{$col_id};
      }
      elsif ( $col_id eq 'user_mac' ){
        #onu_dhcp_port;
        my $macs;
        if($users_mac{$line->{$col_id}}) {
          $macs = $users_mac{$line->{$col_id}};
        }
        elsif($line->{onu_dhcp_port} && $users_mac{$line->{onu_dhcp_port}}) {
          $macs = $users_mac{$line->{onu_dhcp_port}};
        }
        push @row, ( ($macs) ? join($html->br(), @{ $macs }) : '--' );
      }
      else{
        push @row, $line->{$col_id};
      }
    }

    my @control_row = ();
    push @control_row, $html->button( '', "index=$index" . $page_gs . "&onuReset="
          . $line->{onu_snmp_id} . "&ONU_TYPE=" . $line->{pon_type},
        { class => 'glyphicon glyphicon-retweet', TITLE => 'reboot' } );
    push @control_row, $html->button( $lang{INFO},  "index=$index" . $page_gs . "&info_pon_onu=" . $line->{id} . "&ONU="
          . $line->{onu_snmp_id} . "&ONU_TYPE="  . $line->{pon_type},
        { class => 'info' } );
    push @control_row, $html->button( $lang{CHANGE},  "index=$index&chg_pon_onu=" . $line->{id}
          . "&visual=$FORM{visual}&NAS_ID=$nas_id",
        { class => 'change' } );

    push @row, join(' ', @control_row);
    #    push @row, $html->button( $lang{DEL},
    #     "index=$index&del_pon_onu=" . $line->{id}
    #      . "&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}",
    #      { MESSAGE => "$lang{DEL} $lang{PORT}: $line->{id}?", class => 'del' } );
    push @all_rows, \@row;
  }

  print result_row_former({
    table      => $table,
    ROWS       => \@all_rows,
    TOTAL_SHOW => 1,
  });

  print '<script>$(function () {
  var $table = $(\'#EQUIPMENT_ONU_\');
  var correct = ($table.find(\'tbody\').find(\'tr\').first().find(\'td\').length - $table.find(\'thead th\').length );
  for (var i = 0; i < correct; i++) {
    $table.find(\'thead th:last-child\').after(\'<th></th>\');
  }
    var dataTable = $("#EQUIPMENT_ONU_")
      .DataTable({
        "language": {
          paginate: {
              first:    "«",
              previous: "‹",
              next:     "›",
              last:     "»",
          },
          "zeroRecords":    "'.$lang{NOT_EXIST}.'",
          "lengthMenu":     "'.$lang{SHOW}.' _MENU_",
          "search":         "'.$lang{SEARCH}.':",
          "info":           "'.$lang{SHOWING}.' _START_ - _END_ '.$lang{OF}.' _TOTAL_ ",
          "infoEmpty":      "'.$lang{SHOWING}.' 0",
          "infoFiltered":   "('.$lang{TOTAL}.' _MAX_)",
        },
        "ordering": false,
        "lengthMenu": [[25, 50, -1], [25, 50, "'.$lang{ALL}.'"]]
      });
            var column = dataTable.column("0");
            // Toggle the visibility
            column.visible( ! column.visible() );
    });</script>';

  return 1;
}

#********************************************************
=head2 equipment_unregister_onu($attr) - Show unregister OLN ONU

  Arguments:
    $attr
      NAS_INFO

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_unregister_onu {
  my ($attr) = @_;
  my $nas_id = $attr->{NAS_ID} || $FORM{NAS_ID};
  $Equipment->vendor_info( $Equipment->{VENDOR_ID} );
  my $nas_type = equipment_pon_init($attr);

  if($FORM{register}) {
    my $cmd = $SNMP_TPL_DIR . '/register_'.$nas_type;
    if(-x $cmd) {
      cmd($cmd, { DEBUG => 1 });
    }

    $html->message('info', $lang{INFO}, "$lang{ADDED}");
  }

  my $unregister_fn = $nas_type . '_unregister';
  my $unregister_list = &{ \&$unregister_fn }({ %$attr });

  result_former({
    FUNCTION_FIELDS => ":add:id;mac:&register_onu=1&visual=4&NAS_ID=$nas_id&PON_TYPE=&unregister=1&register=1",
    TABLE         => {
      width            => '100%',
      caption          => $lang{UNREGISTER},
      qs               => $pages_qs,
      SHOW_COLS_HIDDEN => { visual => $FORM{visual}, },
      ID               => 'EQUIPMENT_UNGERISTER',
    },
    DATAHASH      => $unregister_list,
    TOTAL         => 1
  });

  return 1;
}

#********************************************************
=head2 equipment_pon_onu($attr) - Show PON ONU information

  Arguments:
    $attr
      NAS_INFO

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_pon_onu{
  my ($attr) = @_;
  $Equipment->vendor_info( $Equipment->{VENDOR_ID} );
  #For old version
  my $nas_type = equipment_pon_init($attr);
  if (!$nas_type) {
    return 0;
  }

  my $used_ports = equipments_get_used_ports({
    NAS_ID     => $FORM{NAS_ID},
    FULL_LIST  => 1,
    PORTS_ONLY => 1,
  });

  my $page_gs = "&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}";
  $LIST_PARAMS{NAS_ID} = $FORM{NAS_ID};
  $LIST_PARAMS{PON_TYPE} = $FORM{PON_TYPE} || '';
  $LIST_PARAMS{OLT_PORT} = $FORM{OLT_PORT} || '';

  my ($table, $list) = result_former({
    INPUT_DATA      => $Equipment,
    FUNCTION        => 'onu_list',
    BASE_FIELDS     => 2,
    DEFAULT_FIELDS  => 'COMMENTS,MAC_SERIAL,STATUS,RX_POWER,LOGIN',
    SKIP_PAGES      => 1,
    TABLE           => {
      width            => '100%',
      caption          => "PON ONU",
      qs               => $page_gs,
      SHOW_COLS        => {
        mac_serial   => "MAC_SERIAL",
        status       => $lang{STATUS},
        rx_power     => "RX_POWER",
        tx_power     => "TX_POWER",
        olt_rx_power => "OLT_RX_POWER",
        comments     => $lang{COMMENTS},
        address_full => $lang{ADDRESS},
        login        => $lang{USER},
        traffic      => $lang{TRAFFIC},
        distance     => $lang{DISTANCE},
        datetime     => $lang{UPDATED},
      },
      SHOW_COLS_HIDDEN => {
        PON_TYPE => $FORM{PON_TYPE},
        OLT_PORT => $FORM{OLT_PORT},
        visual   => $FORM{visual},
        NAS_ID   => $FORM{NAS_ID},
      },
      ID               => '_EQUIPMENT_ONU',
      EXPORT           => 1,
    },
  });

  my @cols = ();
  if ( $table->{COL_NAMES_ARR} ){
    @cols = @{ $table->{COL_NAMES_ARR} };
  }
  my @all_rows = ();
  foreach my $line ( @$list ){
    my @row = ();

    for ( my $i = 0; $i <= $#cols; $i++ ){
      my $col_id = $cols[$i];
      last if ($col_id eq 'id');
      #print "Port: $port col: $i '$col_id' // $olt_ports->{$port}->{$col_id} //<br>";
      if ($col_id eq 'login' || $col_id eq 'address_full' || $col_id eq 'ID'){
        my $value;
        if ($used_ports->{$line->{dhcp_port}}) {
          if ($col_id eq 'ID') {
            $value = 'busy'
          }
          else {
            foreach my $uinfo (@{ $used_ports->{$line->{dhcp_port}} }) {
              $value .= $html->br() if ($value);
              if ($col_id eq 'login') {
                $value .= $html->button( $uinfo->{login}, "index=11&UID=$uinfo->{uid}" );
              }
              elsif ($col_id eq 'address_full') {
                $value .= $uinfo->{address_full} || "";
              }
            }
          }
        }
        else {
          if ($col_id eq 'ID') {
            $value = 'free'
          }
          else {
            $value = '';
          }
        }
        push @row, $value;
      }
      elsif ( $col_id =~ /power/ ){
        push @row, pon_tx_alerts( $line->{$col_id} );
      }
      elsif ( $col_id eq 'status' ){
        push @row, pon_onu_convert_state( $nas_type, $line->{status}, $line->{pon_type} );
      }
      else{
        push @row, $line->{$col_id};
      }
    }

    push @row, "<div value='" . $line->{dhcp_port}
        . "' class='clickSearchResult'><button title='$line->{dhcp_port}' class='btn "
        . (($used_ports->{$line->{dhcp_port}}) ? 'btn-warning' : 'btn-success') . "' onclick=\"fill_search_results('PORTS', '$line->{dhcp_port}')\"  >"
        . uc($line->{pon_type}) . " $line->{branch}:$line->{onu_id}</button></div>";


    push @all_rows, \@row;
  }

  print result_row_former({
    table        => $table,
    ROWS       => \@all_rows,
    #    TOTAL_SHOW => 1,
  });

  print '<script>$(function () {
    var table = $("#_EQUIPMENT_ONU_")
      .DataTable({
        "language": {
          paginate: {
              first:    "«",
              previous: "‹",
              next:     "›",
              last:     "»",
          },
          "zeroRecords":    "'.$lang{NOT_EXIST}.'",
          "lengthMenu":     "'.$lang{SHOW}.' _MENU_",
          "search":         "'.$lang{SEARCH}.':",
          "info":           "'.$lang{SHOWING}.' _START_ - _END_ '.$lang{OF}.' _TOTAL_ ",
          "infoEmpty":      "'.$lang{SHOWING}.' 0",
          "infoFiltered":   "('.$lang{TOTAL}.' _MAX_)",
      },
      "ordering": false,
      "lengthMenu": [[25, 50, -1], [25, 50, "'.$lang{ALL}.'"]]
      });
      var column = table.column("0");
      // Toggle the visibility
      column.visible( ! column.visible() );
      table.search( \'free\' ).draw();
    });</script>';

  return 1;
}

#********************************************************
=head2 pon_onu_state($id, $attr) - Get ONU info

  Arguments:
    $id
    $attr
      SNMP_COMMUNITY
      OUTPUT2RETURN
      VENDOR_ID
      snmp

  Returns:

=cut
#********************************************************
sub pon_onu_state{
  my ($id, $attr) = @_;

  $Equipment->vendor_info( $attr->{VENDOR_ID} || $Equipment->{VENDOR_ID} );

  #For old version
  my $nas_type = equipment_pon_init({ %{ ($attr) ? $attr : {} }, VENDOR_NAME => $Equipment->{NAME} });
  my $nas_id   = $attr->{NAS_ID} || $FORM{NAS_ID};
  my $pon_type = $attr->{PON_TYPE} || $FORM{ONU_TYPE} || 'epon';
  my @quick_info = ('EQUIPMENT_ID', 'DISTANCE', 'VENDOR_ID', 'ONU_PORTS_STATUS', 'VLAN');

  if($FORM{DEBUG}) {
    $attr->{DEBUG}=$FORM{DEBUG};
  }

  if (!$nas_type) {
    print "No PON device init\n";
    return 0;
  }

  if(! $attr->{VERSION}) {
    $attr->{VERSION} = $FORM{SNMP_VERSION} || $Equipment->{SNMP_VERSION};
  }

  my $snmp_info;
  if($attr->{snmp}) {
    $snmp_info = $attr->{snmp};
  }
  else {
    $snmp_info = &{ \&{$nas_type} }({ TYPE => $pon_type });
  }

  my $page_gs = "&visual=". ($FORM{visual} || 4) ."&NAS_ID=$nas_id";
  $page_gs .= "&PON_TYPE=$pon_type";
  $page_gs .= "&OLT_PORT=$FORM{OLT_PORT}" if ($FORM{OLT_PORT});

  my @info = ([
    'ONU',
    $id
      . $html->element('span', $pon_type,
        { class => 'btn btn-sm btn-default', TITLE => $lang{NAS} } )
      . $html->button('', "NAS_ID=$nas_id&index=".get_function_index('equipment_info')
        ."&visual=4&ONU=$id&info_pon_onu=". ($attr->{ONU_SNMP_ID} || q{}). "&ONU_TYPE=$pon_type",
        { class => 'btn btn-sm btn-success', ICON => 'glyphicon glyphicon-info-sign', TITLE => $lang{NAS} } )
      . $html->button('',
           "NAS_ID=$nas_id&index=".get_function_index('equipment_info')
           . "&ONU=$id&visual=4",
        { class => 'btn btn-sm btn-warning', ICON => 'glyphicon glyphicon-repeat', TITLE => $lang{REBOOT} } )
   ]
  );

  #FETCH INFO
  my %port_info = ();
  foreach my $oid_name ( sort keys %{ $snmp_info } ) {
    my $oid = $snmp_info->{$oid_name}->{OIDS} || q{};

    if (!$oid || $oid_name eq 'reset') {
      next;
    }

    my $add_2_oid = $snmp_info->{$oid_name}->{ADD_2_OID} || '';
    my $value = snmp_get({
      %$attr,
      VERSION => '2',
      OID     => $oid.'.'.$id.$add_2_oid,
    });

    my $function = $snmp_info->{$oid_name}->{PARSER};

    if ($function && defined( &{$function} ) ) {
      ($value) = &{ \&$function }($value);
    }

    if ( $oid_name =~ /STATUS/ ){
      if ($value) {
        $value = pon_onu_convert_state($nas_type, $value, $pon_type );
      }
    }

    if($snmp_info->{$oid_name}->{NAME}) {
      $oid_name = $snmp_info->{$oid_name}->{NAME};
    }

    $port_info{$id}{$oid_name} = $value;
  }

  foreach my $oid_name ( sort keys %{ $snmp_info->{main_onu_info} } ){
    if($attr->{QUICK} && ! in_array($oid_name, \@quick_info)) {
      next;
    }

    my $oid = $snmp_info->{main_onu_info}->{$oid_name}->{OIDS};

    if(! $oid) {
      next;
    }

    my $value = q{};

    if ($snmp_info->{main_onu_info}->{$oid_name}->{WALK}){
      my $value_list = snmp_get({
        %{$attr},
        OID    => $oid . '.' . $id,
        TIMEOUT=> 3,
        WALK   => 1,
      });

      if($value_list) {
        foreach my $line (@{$value_list}) {
          my ($oid_, $val) = split( /:/, $line, 2 );
          my $function = $snmp_info->{main_onu_info}->{$oid_name}->{PARSER};
          if ($function && defined( &{$function} )) {
            ($oid_, $val) = &{ \&$function }($line);
          }

          $value .= "$oid_ - $val\n"; #.$html->br();
        }
      }
    }
    else {
      my $add_2_oid = $snmp_info->{main_onu_info}->{$oid_name}->{ADD_2_OID} || '';

      $value = snmp_get( {
        %{$attr},
        OID => $oid . '.' . $id . $add_2_oid
      } );

      my $function = $snmp_info->{main_onu_info}->{$oid_name}->{PARSER};
      if ($function && defined( &{$function} ) ) {
        ($value) = &{ \&$function }($value);
      }
    }

    if($snmp_info->{main_onu_info}->{$oid_name}->{NAME}) {
      $oid_name = $snmp_info->{main_onu_info}->{$oid_name}->{NAME};
    }

    $port_info{$id}{$oid_name} = $value;
  }

  push @info, @{ port_result_former(\%port_info, {
    PORT        => $id,
    #INFO_FIELDS => $info_fields
  }) };

  my $function = $nas_type . '_get_service_ports';
  if ($function && defined( &{$function} ) ) {
    my @sp_arr = &{ \&$function }({%{$attr}, ONU_SNMP_ID => $id});
    foreach my $line (@sp_arr) {
      push @info, [ $line->[0], $line->[1] ];
    }
  }

  if($attr->{OUTPUT2RETURN}) {
    return \@info;
  }

  my $table = $html->table({
    width  => '100%',
    qs     => $pages_qs,
    ID     => 'EQUIPMENT_ONU_INFO',
    rows   => \@info
  });

  print $table->show();

  equipment_pon_onu_graph({
    ONU_SNMP_ID => $attr->{ONU_SNMP_ID},
    PON_TYPE    => $pon_type,
    snmp        => $snmp_info
  });

  if ( ! $attr->{snmp} || ! $attr->{snmp}->{onu_info} || scalar keys %{ $attr->{snmp}->{onu_info} } == 0 ){
    return 0;
  }

  my %info_oids = ();

  foreach my $oid_name ( keys %{ $attr->{snmp}->{onu_info} } ){
    $info_oids{ uc( $oid_name ) } = $oid_name;
  }

  my $list;
  ($table, $list) = result_former({
    DEFAULT_FIELDS => 'ONUUNIIFSPEED,ONUUNIIFSPEEDLIMIT',
    BASE_PREFIX  => 'PORT,STATUS',
    TABLE        => {
      width            => '100%',
      caption          => $lang{PORTS},
      qs               => "&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&ONU=$FORM{ONU}",
      SHOW_COLS        => \%info_oids,
      SHOW_COLS_HIDDEN => {
        visual => $FORM{visual},
        NAS_ID => $FORM{NAS_ID},
        ONU    => $FORM{ONU},
      },
      ID  => 'EQUIPMENT_ONU_PORTS',
    },
  });

  my %ports_info = ();
  my @cols = ();
  if ( $table->{COL_NAMES_ARR} ){
    @cols = @{ $table->{COL_NAMES_ARR} };
  }

  foreach my $oid_name ( @cols ){
    if ( !$attr->{snmp}->{onu_info}->{ $info_oids{$oid_name} } ){
      next;
    }
    my $oid = $attr->{snmp}->{onu_info}->{ $info_oids{$oid_name} } . '.' . $id;
    my $value_arr = snmp_get({
      %{$attr},
      OID  => $oid,
      WALK => 1
    });

    foreach my $line ( @{$value_arr} ){
      my ($port_id, $value) = split( /:/, $line, 2 );
      $ports_info{$oid_name}{$id}{$port_id} = $value;
    }
  }

  my $ports_arr = snmp_get({
    %{$attr},
    WALK => 1,
    OID  => 'enterprises.3320.101.12.1.1.8.' . $id
  });

  my @all_rows = ();

  foreach my $key_ ( sort @{$ports_arr} ){
    my ($port_id, $state) = split( /:/, $key_ );

    if ( $state == 1 ){
      $state = "up";
    }
    elsif ( $state == 2 ){
      $state = "down";
    }

    my @arr = ($port_id, $state);

    for ( my $i = 2; $i <= $#cols; $i++ ){
      my $val_id = $cols[$i];
      push @arr, $ports_info{$val_id}{$id}{$port_id};
    }

    push @all_rows, \@arr;
  }

  print result_row_former({
    table => $table,
    ROWS  => \@all_rows,
  });

  return 1;
}

#********************************************************
=head2 pon_tx_alerts($tx) - Make pon tx alerts

  Arguments:
    $tx  - Tx value

   Excellent -20 - -25
   Worth     -10 - -27
   Very bed  -8  - -30

  Returns:
    $tx with color marks

=cut
#********************************************************
sub pon_tx_alerts {
  my ($tx) = @_;

  if(!$tx || $tx == 65535) {
    $tx = '';
  }
  elsif($tx > 0) {
    $tx = $html->color_mark($tx, 'text-green' );
  }
  elsif ($tx > -8 || $tx < -30) {
    $tx = $html->color_mark($tx, 'text-red' );
  }
  elsif($tx > -10 || $tx < -27) {
    $tx = $html->color_mark($tx, 'text-yellow' );
  }
  else {
    $tx = $html->color_mark($tx, 'text-green' );
  }

  return $tx;
}

#********************************************************
=head2 equipment_pon_ports($attr) - Show PON information

  Arguments:
    $attr
      SNMP_COMMUNITY
      NAS_INFO

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_pon_ports{
  my ($attr) = @_;

  my @ports_state = ('', 'UP', 'DOWN', 'Damage', 'Corp vlan', 'Dormant', 'Not Present', 'lowerLayerDown');
  my @ports_state_color = ('', '#008000', '#FF0000');
  if($attr->{NAS_INFO}) {
    $attr->{VERSION} //= $attr->{NAS_INFO}->{SNMP_VERSION};
  }

  my $debug = $attr->{DEBUG} || 0;
  my $nas_id = $FORM{NAS_ID} || 0;

  $Equipment->vendor_info( $Equipment->{VENDOR_ID} );
  #For old version
  my $nas_type = equipment_pon_init($attr);
  if (!$nas_type) {
    return 0;
  }

  my $func_ports_state = $nas_type . '_ports_state';
  if (defined( &{$func_ports_state} ) ) {
    @ports_state = &{ \&$func_ports_state}();
  }

  if ($FORM{chg_pon_port}){
    $Equipment->{ACTION} = 'change_pon_port';
    $Equipment->{ACTION_LNG} = $lang{CHANGE};

    my $vlan_hash = get_vlans( $attr );
    my %vlans = ();
    foreach my $vlan_id (keys %{$vlan_hash}) {
      $vlans{ $vlan_id } = "Vlan$vlan_id ($vlan_hash->{ $vlan_id }->{NAME})";
    }

    $Equipment->{VLAN_SEL} = $html->form_select('VLAN_ID', {
      SELECTED    => $FORM{VLAN_ID} || '',
      SEL_OPTIONS => { '' => '--' },
      SEL_HASH    => \%vlans,
      NO_ID       => 1
    });

    $html->tpl_show( _include( 'equipment_pon_port', 'Equipment' ), { %{$Equipment}, %FORM } );
  }
  elsif ( $FORM{change_pon_port} ){
    $Equipment->pon_port_change( { %FORM } );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );
    }
  }
  elsif ( defined( $FORM{del_pon_port} ) && $FORM{COMMENTS} ){
    $Equipment->pon_port_del( $FORM{del_pon_port} );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
    }
    elsif ($Equipment->{ONU_TOTAL}){
      $html->message( 'err', $lang{ERROR}, "$lang{REGISTERED} $Equipment->{ONU_TOTAL} onu!" );
    }
  }

  my $olt_ports = equipment_pon_get_ports({
    %{$attr},
    NAS_ID     => $Equipment->{NAS_ID},
    NAS_TYPE   => $nas_type,
    SNMP_TPL   => $Equipment->{SNMP_TPL},
    MODEL_NAME => $Equipment->{MODEL_NAME}
  });

  $pages_qs = "&visual=$FORM{visual}&NAS_ID=$nas_id&TYPE=PON";
  my ($table) = result_former({
    DEFAULT_FIELDS => 'PON_TYPE,BRANCH,BRANCH_DESC,VLAN_ID,PORT_SPEED,PORT_STATUS,TRAFFIC',
    BASE_PREFIX  => 'ID',
    TABLE        => {
      width            => '100%',
      caption          => "PON $lang{PORTS}",
      qs               => $pages_qs,
      SHOW_COLS        => {
        #ID           => 'ID',
        BRANCH      => "BRANCH",
        PON_TYPE    => "PON_TYPE",
        BRANCH_DESC => "$lang{COMMENTS}",
        VLAN_ID     => "VLAN",
        TRAFFIC     => $lang{TRAFFIC},
        PORT_STATUS => $lang{STATUS},
        PORT_SPEED  => $lang{SPEED},
      },
      SHOW_COLS_HIDDEN => {
        PON_TYPE => $FORM{PON_TYPE},
        OLT_PORT => $FORM{OLT_PORT},
        visual   => $FORM{visual},
        NAS_ID   => $nas_id,
      },
      ID               => 'EQUIPMENT_PON_PORTS',
      EXPORT           => 1,
    }
  });

  my @cols = ();
  if ($table->{COL_NAMES_ARR}) {
    @cols = @{ $table->{COL_NAMES_ARR} };
  }

  my @all_rows = ();
  my @ports_arr = keys %{ $olt_ports };
  foreach my $port (@ports_arr) {
    my @row = ($port);
    for (my $i = 1; $i <= $#cols; $i++) {
      my $col_id = $cols[$i];

      if($debug) {
        print "Port: $port col: $i '$col_id' // ".($olt_ports->{$port}->{$col_id} || 'uninicialize')." //<br>";
      }

      if ($col_id eq 'TRAFFIC') {
        push @row,
          "in: ".int2byte( $olt_ports->{$port}{PORT_IN} ).$html->br()."out: ".int2byte( $olt_ports->{$port}{PORT_OUT} );
      }
      elsif ($olt_ports->{$port} && $olt_ports->{$port}->{$col_id}) {
        if ($col_id eq 'PORT_STATUS') {
          push @row, ($olt_ports->{$port} && $olt_ports->{$port}{PORT_STATUS})
                                                                         ? $html->color_mark(
                $ports_state[ $olt_ports->{$port}{PORT_STATUS} ],
                $ports_state_color[ $olt_ports->{$port}{PORT_STATUS} ] ) : '';
        }
        else {
          push @row, $olt_ports->{$port}->{$col_id};
        }
      }
      else {
        push @row, '';
      }
    }

    $olt_ports->{$port}{ID} ||= '';
    $olt_ports->{$port}{BRANCH_DESC} ||= '';

    push @row, $html->button( $lang{INFO},
        "index=$index&chg_pon_port=".$olt_ports->{$port}{ID}
          ."&BRANCH_DESC=".$olt_ports->{$port}{BRANCH_DESC}.$pages_qs,
        { class => 'change' } )
        . $html->button( $lang{DEL},
        "index=$index&del_pon_port=".$olt_ports->{$port}{ID}.$pages_qs,
        { MESSAGE => "$lang{DEL} $lang{PORT}: $port?", class => 'del' } );

    push @all_rows, \@row;
  }

  print result_row_former({
    table      => $table,
    ROWS       => \@all_rows,
    TOTAL_SHOW => 1,
  });

  return 1;
}

#********************************************************
=head2 equipment_pon_onu_graph($attr) - show element graphics

  Arguments:
    $attr
      ONU_SNMP_ID
      PON_TYPE
      snmp

=cut
#********************************************************
sub equipment_pon_onu_graph{
  my ($attr) = @_;

  my $snmp_id         = $attr->{ONU_SNMP_ID} || $FORM{graph_pon_onu};
  my $onu_info        = $Equipment->onu_info( $snmp_id );
  my $pon_type        = $attr->{PON_TYPE} || $FORM{ONU_TYPE};

  if(! defined($Equipment->{ONU_ID})) {
    return 0;
  }

  my @onu_graph_types = split(',', $onu_info->{ONU_GRAPH} || q{});
  my $snmp_info       = $attr->{snmp};
  my %graph_hash      = ();
  my @rows            = ();

  $FORM{PERIOD} = 6 if (!$FORM{PERIOD});
  my $start_time = time() - $FORM{PERIOD} * 3600 || '';
  my %periods = (
    6    => "6 $lang{HOURS}",
    12   => "12 $lang{HOURS}",
    24   => "$lang{DAY}",
    168  => "$lang{WEEK}",
    720  => "$lang{MONTH}",
    8760 => "$lang{YEAR}"
  );

  push @rows, "$lang{PERIOD}:", $html->form_select( 'PERIOD', {
    SELECTED     => $FORM{PERIOD},
    SEL_HASH     => \%periods,
    SORT_KEY_NUM => 1,
    ID           => 'type',
    EX_PARAMS    =>
     "data-auto-submit='index=$index&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&graph_pon_onu=$snmp_id&ONU_TYPE=$pon_type'",
    NO_ID        => 1
  } );

  push @rows, $html->form_input( 'show', $lang{SHOW}, { TYPE => 'submit', FORM_ID => 'period_panel' } );

  my %info = ();
  foreach my $val (@rows) {
    $info{ROWS} .= $html->element( 'div', $val, { class => 'form-group' } );
  }

  my $report_form = $html->element( 'div', $info{ROWS}, {
   class => 'well well-sm',
  } );

  print $html->form_main({
    CONTENT => $report_form, #. $FIELDS . $TAGS,
    HIDDEN  => {
      index         => $index,
      visual        => $FORM{visual},
      NAS_ID        => $FORM{NAS_ID},
      #graph_pon_onu => $snmp_id,
      ONU_TYPE      => $pon_type,
      info_pon_onu  => $FORM{info_pon_onu},
      ONU           => $FORM{ONU}
    },
    NAME    => 'period_panel',
    ID      => 'period_panel',
    class   => 'form-inline',
  });

  require Equipment::Graph;

  foreach my $graph_type (@onu_graph_types) {
    my @onu_ds_names = ();
    if ($graph_type eq 'SIGNAL' && $snmp_info && ($snmp_info->{ONU_RX_POWER}->{OIDS} || $snmp_info->{OLT_RX_POWER}->{OIDS})) {
      push @onu_ds_names, $snmp_info->{ONU_RX_POWER}->{NAME} || q{};
      push @onu_ds_names, $snmp_info->{OLT_RX_POWER}->{NAME} || q{};
      $graph_hash{SIGNAL} = get_graph_data({
        NAS_ID     => $FORM{NAS_ID},
        PORT       => $onu_info->{ONU_SNMP_ID},
        TYPE       => 'SIGNAL',
        DS_NAMES   => \@onu_ds_names,
        START_TIME => $start_time
      });

      $graph_hash{SIGNAL}{DIMENSION} = 'dBm' if $graph_hash{SIGNAL};
    }
    elsif ($graph_type eq 'TEMPERATURE' && $snmp_info->{TEMPERATURE}->{OIDS}) {
      push @onu_ds_names, $snmp_info->{TEMPERATURE}->{NAME};
      $graph_hash{TEMPERATURE} = get_graph_data({
        NAS_ID     => $FORM{NAS_ID},
        PORT       => $onu_info->{ONU_SNMP_ID},
        TYPE       => 'TEMPERATURE',
        DS_NAMES   => \@onu_ds_names,
        START_TIME => $start_time
      });
      $graph_hash{TEMPERATURE}{DIMENSION} = '°C' if $graph_hash{TEMPERATURE};
    }
    elsif ($graph_type eq 'SPEED' && ($snmp_info->{ONU_IN_BYTE}->{OIDS} || $snmp_info->{ONU_OUT_BYTE}->{OIDS})) {
      push @onu_ds_names, $snmp_info->{ONU_IN_BYTE}->{NAME};
      push @onu_ds_names, $snmp_info->{ONU_OUT_BYTE}->{NAME};
      $graph_hash{SPEED} = get_graph_data({
        NAS_ID   => $FORM{NAS_ID},
        PORT     => $onu_info->{ONU_SNMP_ID},
        TYPE     => 'SPEED',
        DS_NAMES => \@onu_ds_names,
        START_TIME => $start_time
      });

      $graph_hash{SPEED}{DIMENSION} = 'Mbit/s' if $graph_hash{SPEED};
    }
  }

  my @graphs = ();
  foreach my $graph_type (sort keys %graph_hash) {
    my $graph = $graph_hash{ $graph_type };
    my @time_arr = ();
    my %graph_data = ();
    if ($graph) {
      foreach my $val (@{ $graph->{data} }) {
        push @time_arr, POSIX::strftime("%b %d %H:%M", localtime($val->[0]));

        for (my $i = 0; $i <= $#{ $graph->{meta}->{legend} }; $i++) {
          my $index = $i + 1;
          if ($graph_type eq 'SPEED') {
            $val->[$index] = sprintf("%.2f", $val->[$index] / (1024 * 1024) * 8) if ($val->[$index]);
          }
          else {
            $val->[$index] = sprintf("%.2f", $val->[$index]) if ($val->[$index]);
          }
          push @{ $graph_data{ $graph->{meta}->{legend}->[$i] } }, $val->[$index];
        }
      }

      push @graphs, $html->make_charts2( {
        GRAPH_ID      => lc($graph_type),
        DIMENSION     => $graph->{DIMENSION},
        TITLE         => $graph_type,
        TRANSITION    => 1,
        X_TEXT        => \@time_arr,
        DATA          => \%graph_data,
        OUTPUT2RETURN => 1
      } );
    }
  }

  #_error_show($Equipment);
  print "
  <div class=row>
  <div class='col-md-4'>" .($graphs[0] || q{}) ."</div>
  <div class='col-md-4'>" .($graphs[1] || q{}) ."</div>
  <div class='col-md-4'>" .($graphs[3] || q{}) ."</div>
  </div>
  ";


  return 1;
}

#**********************************************************
=head2 pon_onu_convert_state($nas_type, $status, $pon_type)

=cut
#**********************************************************
sub pon_onu_convert_state{
  my ($nas_type, $status, $pon_type) = @_;

  my $status_hash = ();
  my $get_status_fn = $nas_type . '_onu_status';

  if ( defined( &{$get_status_fn} ) ){
    $status_hash = &{ \&{$get_status_fn} }($pon_type);
  }

  if (!$status_hash->{ $status }) {
    $status_hash->{ $status } = "Unknown_status($status):text-orange"
  }

  my ($status_desc, $color) = split( /:/, $status_hash->{ $status } );
  $status = $html->color_mark( $status_desc, $color );

  return $status;
}

1
