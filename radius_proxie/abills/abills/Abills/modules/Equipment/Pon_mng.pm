=head1 NAME

  PON Manage functions

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(load_pmodule in_array int2byte cmd _bp);

our (
  $html,
  %lang,
  @service_status,
  $SNMP_TPL_DIR,
);

our Equipment $Equipment;
require Equipment::Grabbers;


#********************************************************
=head2 equipment_pon_init($attr)

  Arguments:
    $attr
       VENDOR_NAME
       NAS_INFO

  Return:

=cut
#********************************************************
sub equipment_pon_init {
  my ($attr) = @_;
  my $nas_type = '';

  unshift(@INC, '../../Abills/modules/');

  my $vendor_name = $attr->{VENDOR_NAME} || $attr->{NAS_INFO}->{NAME} || q{};

  if (!$vendor_name) {
    return '';
  }

  if ($vendor_name =~ /ELTEX/i) {
    require Equipment::Eltex;
    $nas_type = '_eltex';
  }
  elsif ($vendor_name =~ /ZTE/i) {
    require Equipment::Zte;
    $nas_type = '_zte';
  }
  elsif ($vendor_name =~ /HUAWEI/i) {
    require Equipment::Huawei;
    $nas_type = '_huawei';
  }
  elsif ($vendor_name =~ /BDCOM/i) {
    require Equipment::Bdcom;
    $nas_type = '_bdcom';
  }
  elsif ($vendor_name =~ /V\-SOLUTION/i) {
    require Equipment::Vsolution;
    $nas_type = '_vsolution';
  }
  elsif($vendor_name =~ /STELS/i) {
    require Equipment::Stels;
    $nas_type = '_stels';
  }

  return $nas_type;
}


#********************************************************
=head2 equipment_pon_get_ports($attr) - Show PON information

  Arguments:
    $attr
      SNMP_COMMUNITY
      NAS_INFO
      USED_PORTS   - Used ports information

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_pon_get_ports {
  my ($attr) = @_;

  my $port_list = $Equipment->pon_port_list({
    %$attr,
    COLS_NAME  => 1,
    COLS_UPPER => 1,
    NAS_ID     => $attr->{NAS_ID}
  });
  my $ports = ();
  foreach my $line (@$port_list) {
    $ports->{$line->{snmp_id}} = $line;
  }
  my $get_ports_fn = $attr->{NAS_TYPE} . '_get_ports';

  if (!$Equipment->{STATUS}) {
    if (defined(&{$get_ports_fn})) {
      my $olt_ports = &{\&$get_ports_fn}({
        %{($attr) ? $attr : {}},
        SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
        SNMP_TPL       => $attr->{SNMP_TPL},
        MODEL_NAME     => $attr->{MODEL_NAME}
      });
      foreach my $snmp_id (keys %{$olt_ports}) {
        if (!$ports->{$snmp_id}) {
          $Equipment->pon_port_list({
            %$attr,
            COLS_NAME => 1,
            NAS_ID    => $attr->{NAS_ID},
            SNMP_ID   => $snmp_id
          });
          if (!$Equipment->{TOTAL}) {
            $Equipment->pon_port_add({ SNMP_ID => $snmp_id, NAS_ID => $attr->{NAS_ID}, %{$olt_ports->{$snmp_id}} });
            $olt_ports->{$snmp_id}{ID} = $Equipment->{INSERT_ID};
          }
        }
        else {
          if ($conf{EQUIPMENT_SNMP_WR} && $ports->{$snmp_id}{BRANCH_DESC} && $ports->{$snmp_id}{BRANCH_DESC} ne $olt_ports->{$snmp_id}{BRANCH_DESC}) {
            my $set_desc_fn = $attr->{NAS_TYPE} . '_set_desc';
            if (defined(&{$set_desc_fn})) {
              my $result = &{\&$set_desc_fn}({
                %{($attr) ? $attr : {}},
                SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
                PORT           => $snmp_id,
                PORT_TYPE      => $ports->{$snmp_id}{PON_TYPE},
                DESC           => $ports->{$snmp_id}{BRANCH_DESC}
              });

              if (!$result) {
                $html->message('err', $lang{ERROR}, "Can't write port descr");
              }
            }
          }
        }

        foreach my $key (keys %{$olt_ports->{$snmp_id}}) {
          $ports->{$snmp_id}{$key} = $olt_ports->{$snmp_id}{$key};
        }
      }
    }
  }
  else {
    if ($html) {
      $html->message('warn', $lang{INFO}, "$lang{STATUS} $service_status[$Equipment->{STATUS}]");
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
sub _get_snmp_oid {
  my ($type, $attr) = @_;

  #  if ( !$type ){
  #    return '';
  #  }
  my $path = ($attr->{BASE_DIR}) ? $attr->{BASE_DIR} . '/' : q{};

  my $def_content = file_op({
    FILENAME      => $path . $SNMP_TPL_DIR . '/default.snmp',
    PATH          => $path . $SNMP_TPL_DIR,
    SKIP_COMMENTS => '^\/\/'
  });

  my $def_result;
  if ($def_content) {
    load_pmodule("JSON");
    my $json = JSON->new->allow_nonref;
    $def_result = $json->decode($def_content);
  }

  my $content;
  $content = file_op({
    FILENAME      => $path . $SNMP_TPL_DIR . '/' . $type,
    PATH          => $path . $SNMP_TPL_DIR,
    SKIP_COMMENTS => '^\/\/'
  }) if ($type);

  my $result = ();

  if ($content) {
    load_pmodule("JSON");
    my $json = JSON->new->allow_nonref;
    $result = $json->decode($content);
  }
  my @array_keys = ('info', 'status', 'ports');
  foreach my $key (keys %{$def_result}) {
    if (in_array($key, \@array_keys)) {
      foreach my $key2 (keys %{$def_result->{$key}}) {
        $result->{$key}->{$key2} = $def_result->{$key}->{$key2} if (!$result->{$key}->{$key2});
      }
    }
    else {
      $result->{$key} = $def_result->{$key} if (!$result->{$key});
    }
  }

  return $result;
}


#********************************************************
=head2 equipment_pon($attr) - Show PON information

  Arguments:
    $attr
      SNMP_COMMUNITY
      NAS_INFO
      USED_PORTS

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_pon {
  my ($attr) = @_;

  my $SNMP_COMMUNITY = $attr->{SNMP_COMMUNITY};
  my $nas_id = $FORM{NAS_ID};

  #For old version
  $Equipment->vendor_info($Equipment->{VENDOR_ID});
  if (!$attr->{VENDOR_NAME}) {
    $attr->{VENDOR_NAME} = $Equipment->{NAME};
  }

  if ($FORM{DEBUG}) {
    $attr->{DEBUG} = $FORM{DEBUG};
  }

  my $nas_type = equipment_pon_init($attr);

  if (!$nas_type) {
    return 0;
  }

  my $snmp = &{\&{$nas_type}}({ TYPE => $FORM{ONU_TYPE} });

  if ($FORM{unregister_list}) {
    equipment_unregister_onu_list($attr);
    return 1;
  }
  elsif ($FORM{onuReset}) {
    if ($snmp->{reset} && $snmp->{reset}->{OIDS}) {
      my $reset_value = (defined($snmp->{reset}->{RESET_VALUE})) ? $snmp->{reset}->{RESET_VALUE} : 1;

      if (snmp_set({ SNMP_COMMUNITY => $SNMP_COMMUNITY, OID =>
        [ $snmp->{reset}->{OIDS} . '.' . $FORM{onuReset}, "integer", $reset_value ] })) {
        $html->message('info', $lang{INFO}, "ONU " . $lang{REBOOTED});
      }
    }
    else {
      $html->message('err', $lang{ERROR}, "Can't find reset SNMP OID", { ID => 499 });
    }
  }

  if ($FORM{ONU}) {
    pon_onu_state($FORM{ONU}, {
      %{$attr},
      snmp        => $snmp,
      ONU_TYPE    => $FORM{ONU_TYPE},
      ONU_SNMP_ID => $FORM{info_pon_onu},
      #BRANCH      => $onu_list->[0]->{branch},
      #ONU_ID      => $onu_list->[0]->{onu_id},
    });

    return 1;
  }
  elsif ($FORM{graph_onu}) {
    equipment_pon_onu_graph({ ONU_SNMP_ID => $FORM{graph_onu}, snmp => $snmp });
  }
  elsif ($FORM{chg_onu}) {
    $html->message('info', "$lang{CHANGE} ONU", $FORM{chg_onu});
  }
  elsif ($FORM{reg_onu}) {
    if (equipment_register_onu({ %FORM, %$attr })) {
      return 1;
    }
  }
  elsif ($FORM{del_onu}) {
    equipment_delete_onu($attr);
    #    $html->message('info', "$lang{DEL} ONU", "$FORM{del_onu}");
  }

  if ($SNMP_Session::errmsg) {
    $html->message('err', $lang{ERROR},
      "OID: " . ($attr->{OID} || q{}) . "\n\n $SNMP_Session::errmsg\n\n$SNMP_Session::suppress_warnings\n");
  }

  my $pon_types = ();
  my $olt_ports = ();
  #Port select
  my $port_list = $Equipment->pon_port_list({
    COLS_NAME  => 1,
    COLS_UPPER => 1,
    NAS_ID     => $Equipment->{NAS_ID}
  });

  foreach my $line (@$port_list) {
    $pon_types->{ $line->{pon_type} } = uc($line->{pon_type});
    if ($FORM{PON_TYPE} && $FORM{PON_TYPE} eq $line->{pon_type}) {
      $olt_ports->{ $line->{id} } = "$line->{branch_desc} ($line->{branch})";
    }
    else {
      $olt_ports->{ $line->{id} } = "$line->{pon_type} $line->{branch_desc} ($line->{branch})";
    }
  }

  $FORM{PON_TYPE} = '' if (!$FORM{PON_TYPE});

  my @rows = ();
  if (!$FORM{SERVICE_PORTS} && !$FORM{LINE_PROFILES}) {
    push @rows, $html->element('div', "$lang{TYPE}: " . $html->form_select('PON_TYPE',
      {
        SELECTED    => $FORM{PON_TYPE},
        SEL_HASH    => $pon_types,
        SEL_OPTIONS => { '' => $lang{SELECT_TYPE} },
        EX_PARAMS   => " data-auto-submit='index=$index&visual=$FORM{visual}&NAS_ID=$nas_id' ",
        NO_ID       => 1
      }));

    push @rows, $html->element('div', "$lang{PORTS}: " . $html->form_select('OLT_PORT',
      {
        SELECTED    => $FORM{OLT_PORT},
        SEL_HASH    => $olt_ports,
        SEL_OPTIONS => { '' => $lang{SELECT_PORT} },
        EX_PARAMS   => " data-auto-submit='index=$index&visual=$FORM{visual}&NAS_ID=$nas_id&PON_TYPE=$FORM{PON_TYPE}' ",
        NO_ID       => 1
      }));
  }
  my $unregister_fn = $nas_type . '_unregister';
  if (defined(&$unregister_fn)) {
    if (!$Equipment->{STATUS}) {
      my $macs = &{\&$unregister_fn}({ %$attr });

      push @rows, $html->button($lang{UNREGISTER} . ' ' . ($#{$macs} + 1),
        "index=$index&visual=$FORM{visual}&NAS_ID=$nas_id&PON_TYPE=$FORM{PON_TYPE}&unregister_list=1",
        { class => 'btn btn-default' . (($#{$macs} > -1) ? ' btn-warning' : q{}) });
    }
    else {
      $html->message('warn', $lang{INFO}, "$lang{STATUS} $service_status[$Equipment->{STATUS}]");
    }
  }

  my %info = ();

  #  if ($nas_type eq '_huawei') {
  #    my $buttons .= $html->li( $html->button( 'SERVICE_PORTS',
  #        "index=$index&visual=$FORM{visual}&NAS_ID=$nas_id&SERVICE_PORTS=1" ),
  #      { class => ($FORM{SERVICE_PORTS}) ? 'active' : '' } );

  #    $buttons .= $html->li( $html->button( 'LINE_PROFILES',
  #        "index=$index&visual=$FORM{visual}&NAS_ID=$nas_id&LINE_PROFILES=1" ),
  #      { class => ($FORM{LINE_PROFILES}) ? 'active' : '' } );

  #    $info{ROWS} .= $html->element( 'ul', $buttons, { class => 'nav navbar-nav' } );
  #  }
  foreach my $val (@rows) {
    $info{ROWS} .= $html->element('div', $val, { class => 'navbar-form navbar-right form-group' });
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
    push @{$users_mac{$line->{port} || 0}}, $line->{mac};
  }

  my $report_form = $html->element('div', $info{ROWS}, { class => 'navbar navbar-default' });

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
  $LIST_PARAMS{BRANCH}   = '_SHOW';

  my %EXT_TITLES = (
    onu_snmp_id   => "SNMP ID",
    branch        => $lang{BRANCH},
    onu_id        => "ONU_ID",
    mac_serial    => "MAC_SERIAL",
    status        => $lang{ONU_STATUS},
    rx_power      => "RX $lang{POWER}",
    tx_power      => "TX $lang{POWER}",
    olt_rx_power  => "OLT RX $lang{POWER}",
    comments      => $lang{COMMENTS},
    address_full  => $lang{ADDRESS},
    login         => $lang{LOGIN},
    traffic       => $lang{TRAFFIC},
    onu_dhcp_port => "DHCP $lang{PORTS}",
    distance      => $lang{DISTANCE},
    fio           => $lang{FIO},
    user_mac      => "$lang{USER} MAC",
    vlan_id       => 'Native VLAN Statics',
    datetime      => $lang{UPDATED},
  );

  my ($table, $list) = result_former({
    INPUT_DATA      => $Equipment,
    FUNCTION        => 'onu_list',
    DEFAULT_FIELDS  => 'BRANCH,ONU_ID,MAC_SERIAL,STATUS,RX_POWER',
    HIDDEN_FIELDS   => 'DELETED',
    SKIP_PAGES      => 1,
    SKIP_USER_TITLE => 1,
    BASE_FIELDS     => 1,
    EXT_TITLES      => \%EXT_TITLES,
    TABLE           => {
      width            => '100%',
      caption          => "PON ONU",
      qs               => $page_gs,
      SHOW_COLS        => \%EXT_TITLES,
      SHOW_COLS_HIDDEN => {
        PON_TYPE => $FORM{PON_TYPE},
        OLT_PORT => $FORM{OLT_PORT},
        visual   => $FORM{visual},
        NAS_ID   => $nas_id,
      },
      ID               => 'EQUIPMENT_ONU',
      EXPORT           => 1,
    }
  });

  my $used_ports = $attr->{USED_PORTS};

  if (!$used_ports) {
    $used_ports = equipments_get_used_ports({
      NAS_ID    => $nas_id,
      FULL_LIST => 1,
    });
  }

  my @cols = ();
  if ($table->{COL_NAMES_ARR}) {
    @cols = @{$table->{COL_NAMES_ARR}};
  }
  my @all_rows = ();

  foreach my $line (@$list) {
    my @row = ();
    for (my $i = 0; $i <= $#cols; $i++) {
      my $col_id = $cols[$i];
      last if ($col_id eq 'id');
      #print "Port: $port col: $i '$col_id' // $olt_ports->{$port}->{$col_id} //<br>";
      if ($col_id eq 'login' || $col_id eq 'address_full' || $col_id eq 'user_mac' || $col_id eq 'fio') {
        my $value;
        if ($used_ports->{$line->{dhcp_port}}) {
          if ($col_id eq 'login') {
            $value .= show_used_info($used_ports->{ $line->{dhcp_port} });
          }
          else {
            foreach my $uinfo (@{$used_ports->{$line->{dhcp_port}}}) {
              $value .= $html->br() if ($value);
              if ($col_id eq 'address_full') {
                $value .= $uinfo->{address_full} || "";
              }
              elsif ($col_id eq 'user_mac') {
                $value .= $uinfo->{cid} || "";
              }
              elsif ($col_id eq 'fio') {
                $value .= $uinfo->{fio} || "";
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
      elsif ($col_id eq 'traffic') {
        my ($in, $out) = split(/,/, $line->{traffic});
        push @row, "in: " . int2byte($in) . $html->br() . "out: " . int2byte($out);
      }
      elsif ($col_id =~ /power/) {
        push @row, pon_tx_alerts($line->{$col_id});
      }
      elsif ($col_id eq 'status') {
        push @row, ($line->{deleted}) ? $html->color_mark("Deleted", 'text-red') : pon_onu_convert_state($nas_type, $line->{status}, $line->{pon_type});
      }
      elsif ($col_id eq 'branch') {
        my $br = uc($line->{pon_type}) . ' ' . $line->{$col_id};
        $br = $html->color_mark($br, 'text-red') if ($line->{deleted});
        push @row, $br;
      }
      elsif ($col_id eq 'user_mac') {
        my $macs;
        if ($users_mac{$line->{$col_id}}) {
          $macs = $users_mac{$line->{$col_id}};
        }
        elsif ($line->{onu_dhcp_port} && $users_mac{$line->{onu_dhcp_port}}) {
          $macs = $users_mac{$line->{onu_dhcp_port}};
        }
        push @row, (($macs) ? join($html->br(), @{$macs}) : '--');
      }
      else {
        push @row, ($line->{deleted}) ? $html->color_mark($line->{$col_id}, 'text-red') : $line->{$col_id} if ($col_id ne 'deleted');
      }
    }

    my @control_row = ();
    if (!$line->{deleted}) {
      push @control_row, $html->button('', "index=$index" . $page_gs . "&onuReset="
        . $line->{onu_snmp_id} . "&ONU_TYPE=" . $line->{pon_type},
        { ICON => 'glyphicon glyphicon-retweet', TITLE => $lang{REBOOT} . " ONU" });
      push @control_row, $html->button($lang{INFO}, "index=$index" . $page_gs . "&info_pon_onu=" . $line->{id} . "&ONU="
        . $line->{onu_snmp_id} . "&ONU_TYPE=" . $line->{pon_type},
        { class => 'info' });
      #      push @control_row, $html->button( $lang{CHANGE},  "index=$index&chg_onu=" . $line->{id}
      #            . "&visual=$FORM{visual}&NAS_ID=$nas_id",
      #          { class => 'change' } );
    }
     push @control_row, $html->button($lang{DEL},
       "NAS_ID=$FORM{NAS_ID}&index=" . get_function_index('equipment_info')
         . "&visual=$FORM{visual}&ONU_TYPE=$line->{pon_type}&del_onu=$line->{id}&clear_in_db=$line->{deleted}",
         { MESSAGE => "$lang{DEL} ONU: $line->{branch}:$line->{onu_id}?", class => 'del' });

    push @row, join(' ', @control_row);
    push @all_rows, \@row;
  }

  print result_row_former({
    table           => $table,
    ROWS            => \@all_rows,
    TOTAL_SHOW      => 1,
    EXTRA_HTML_INFO => '<script>$(function () {
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
          "zeroRecords":    "' . $lang{NOT_EXIST} . '",
          "lengthMenu":     "' . $lang{SHOW} . ' _MENU_",
          "search":         "' . $lang{SEARCH} . ':",
          "info":           "' . $lang{SHOWING} . ' _START_ - _END_ ' . $lang{OF} . ' _TOTAL_ ",
          "infoEmpty":      "' . $lang{SHOWING} . ' 0",
          "infoFiltered":   "(' . $lang{TOTAL} . ' _MAX_)",
        },
        "ordering": false,
        "lengthMenu": [[25, 50, -1], [25, 50, "' . $lang{ALL} . '"]]
      });
            var column = dataTable.column("0");
            // Toggle the visibility
            column.visible( ! column.visible() );
    });</script>'
  });

  return 1;
}

#********************************************************
=head2 equipment_unregister_onu_list($attr) - Show unregister OLN ONU

  Arguments:
    $attr
      NAS_INFO

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_unregister_onu_list {
  my ($attr) = @_;

  my $nas_id = $attr->{NAS_ID} || $FORM{NAS_ID};
  #For old version
  $Equipment->vendor_info($Equipment->{VENDOR_ID});
  if (!$attr->{VENDOR_NAME}) {
    $attr->{VENDOR_NAME} = $Equipment->{NAME};
  }

  my $nas_type = equipment_pon_init($attr);
  $attr->{NAS_ID} = $nas_id;

  $attr->{FULL} = 1;

  my $unregister_fn = $nas_type . '_unregister';
  my $unregister_list = &{\&$unregister_fn}({ %$attr });
  $pages_qs = "&visual=$FORM{visual}&NAS_ID=$nas_id&unregister_list=1";
  result_former({
    FUNCTION_FIELDS => ":add:id;mac;sn;branch;onu_type;pon_type;type;mac_serial;equipment_id;vendor;branch_num:&visual=4&NAS_ID=$nas_id&reg_onu=1",
    TABLE           => {
      width            => '100%',
      caption          => $lang{UNREGISTER},
      EXT_TITLES       => {
        sn               => $lang{MAC_SERIAL},
        branch           => $lang{BRANCH},
        ONU_TYPE         => $lang{TYPE},
        SOFTWARE_VERSION => $lang{VERSION}
      },
      qs               => $pages_qs,
      SHOW_COLS_HIDDEN => { visual => $FORM{visual} },
      ID               => 'EQUIPMENT_UNGERISTER',
    },
    DATAHASH        => $unregister_list,
    TOTAL           => 1
  });

  return 1;
}

#********************************************************
=head2 equipment_register_onu($attr) - PON ONU registration

  Arguments:
    $attr
      NAS_INFO

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_register_onu {
  my ($attr) = @_;

  my $nas_id = $attr->{NAS_ID} || $attr->{NAS_INFO}->{NAS_ID};
  #For old version
  $Equipment->vendor_info($Equipment->{VENDOR_ID});
  if (!$attr->{VENDOR_NAME}) {
    $attr->{VENDOR_NAME} = $Equipment->{NAME};
  }

  my $nas_type = equipment_pon_init($attr);

  my $cmd = $SNMP_TPL_DIR . '/register' . $nas_type . '_custom';
  $cmd = $SNMP_TPL_DIR . '/register' . $nas_type if (!-x $cmd);

  my $list = $Equipment->_list({
    NAS_ID           => $nas_id,
    MNG_HOST_PORT    => '_SHOW',
    NAS_MNG_USER     => '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    INTERNET_VLAN    => '_SHOW',
    TR_069_VLAN      => '_SHOW',
    IPTV_VLAN        => '_SHOW',
    COLS_NAME        => 1,
    PAGE_ROWS        => 1,
  });

  if ($Equipment->{TOTAL}) {
    $attr->{NAS_INFO}{MNG_HOST_PORT} = $list->[0]->{nas_mng_ip_port};
    $attr->{NAS_INFO}{MNG_USER} = $list->[0]->{mng_user};
    $attr->{NAS_INFO}{NAS_MNG_USER} = $list->[0]->{nas_mng_user};
    $attr->{NAS_INFO}{NAS_MNG_PASSWORD} = $conf{EQUIPMENT_OLT_PASSWORD} || $list->[0]->{nas_mng_password};
    $attr->{NAS_INFO}{PROFILE} = $conf{EQUIPMENT_ONU_PROFILE} if ($conf{EQUIPMENT_ONU_PROFILE});
    $attr->{NAS_INFO}{ONU_TYPE} = $conf{EQUIPMENT_ONU_TYPE} if ($conf{EQUIPMENT_ONU_TYPE});

    my $port_list = $Equipment->pon_port_list({
      %$attr,
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      BRANCH     => $FORM{BRANCH},
      NAS_ID     => $nas_id
    });

    $attr->{DEF_VLAN}    = $port_list->[0]->{VLAN_ID} || $list->[0]->{internet_vlan};
    $attr->{PORT_VLAN}   = $attr->{DEF_VLAN};
    $attr->{TR_069_VLAN} = $list->[0]->{tr_069_vlan} || '';
    $attr->{IPTV_VLAN}   = $list->[0]->{iptv_vlan} || '';

    my $result = q{};
    my $result_code = '';
    my $unregister_form_fn = $nas_type . '_unregister_form';

    if ($FORM{reg_onu} && defined(&$unregister_form_fn) && !$FORM{onu_registration}) {
      &{\&$unregister_form_fn}({ %FORM, %$attr });
      return 1;
    }
    else {
      my $parse_line_profile = $nas_type . '_prase_line_profile';
      if (defined(&$parse_line_profile)) {
        my $line_profiles = &{\&$parse_line_profile}({ %FORM, %$attr });
        foreach my $key (keys %$line_profiles) {
          $FORM{LINE_PROFILE_DATA} .= "$key:";
          $FORM{LINE_PROFILE_DATA} .= join(',', @{$line_profiles->{$key}});
          # foreach my $vlan (@{$line_profiles->{$key}}) {
          #   $FORM{LINE_PROFILE_DATA} .= "$vlan";
          #   if ($line_profiles->{$key}->[ $#{$line_profiles->{$key}} ] ne $vlan) {
          #     $FORM{LINE_PROFILE_DATA} .= ",";
          #   }
          # }
          $FORM{LINE_PROFILE_DATA} .= ";";
        }
      }

      if (-x $cmd) {
        $attr->{TR_069_PROFILE}     = $conf{TR_069_PROFILE} || 'ACS';
        $attr->{INTERNET_USER_VLAN} = $conf{INTERNET_USER_VLAN} || '101';
        $attr->{TR_069_USER_VLAN}   = $conf{TR_069_USER_VLAN} || '102';
        $attr->{IPTV_USER_VLAN}     = $conf{IPTV_USER_VLAN} || '103';
        $attr->{VLAN_ID}            = $FORM{VLAN_ID_HIDE} || '';

        delete $attr->{NAS_INFO}->{ACTION_LNG};
        $result = cmd($cmd, {
          DEBUG   => $FORM{DEBUG} || 0,
          PARAMS  => { %$attr, %FORM, %{$attr->{NAS_INFO}} },
          ARGV    => 1,
          timeout => 30
        });
        $result_code = $? >> 8;
      }

      if ($result_code) {
        $html->message('info', $lang{INFO}, $result);
        $result =~ s/\n/ /g;
        if ($result =~ /ONU: \d+\/\d+\/\d+\:(\d+) ADDED/) {
          my $onu = ();
          $onu->{NAS_ID}       = $nas_id;
          $onu->{ONU_ID}       = $1 || 0;
          $onu->{ONU_DHCP_PORT}= $port_list->[0]->{BRANCH} . ':' . $onu->{ONU_ID};
          $onu->{PORT_ID}      = $port_list->[0]->{ID};
          $onu->{ONU_MAC_SERIAL} = $FORM{MAC_SERIAL};
          $onu->{ONU_DESC}     = $FORM{ONU_DESC};
          $onu->{ONU_SNMP_ID}  = $port_list->[0]->{SNMP_ID} . '.' . $onu->{ONU_ID};
          $onu->{LINE_PROFILE} = $FORM{LINE_PROFILE};
          $onu->{SRV_PROFILE}  = $FORM{SRV_PROFILE};

          my $onu_list = $Equipment->onu_list({ COLS_NAME => 1, PORT_ID => $onu->{PORT_ID}, ONU_SNMP_ID => $onu->{ONU_SNMP_ID} });
          if ($onu_list->[0]->{id}) {
            $Equipment->onu_change({ ID => $onu_list->[0]->{id}, ONU_STATUS => 0, DELETED => 0, %{$onu} });
          }
          else {
            $Equipment->onu_add({ %{$onu} });
          }
        }
        return 1;
      }
      else {
        $html->message('err', $lang{ERROR}, "$result");
        return 0;
      }
    }
  }

  return 0;
}
#********************************************************
=head2 equipment_delete_onu($attr) - Delete PON ONU

  Arguments:
    $attr
      NAS_INFO

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_delete_onu {
  my ($attr) = @_;

  #my $nas_id = $attr->{NAS_ID} || $attr->{NAS_INFO}->{NAS_ID};
  #For old version
  $Equipment->vendor_info($Equipment->{VENDOR_ID});
  if (!$attr->{VENDOR_NAME}) {
    $attr->{VENDOR_NAME} = $Equipment->{NAME};
  }

  my $nas_type = equipment_pon_init($attr);
  my $onu_info = $Equipment->onu_info($FORM{del_onu});

  $attr->{NAS_INFO}{NAS_MNG_PASSWORD} = $conf{EQUIPMENT_OLT_PASSWORD} if ($conf{EQUIPMENT_OLT_PASSWORD});
  $attr->{NAS_INFO}{PROFILE} = $conf{EQUIPMENT_ONU_PROFILE} if ($conf{EQUIPMENT_ONU_PROFILE});

  my $cmd = $SNMP_TPL_DIR . '/register' . $nas_type . '_custom';
  $cmd = $SNMP_TPL_DIR . '/register' . $nas_type if (!-x $cmd);
  my $result = '';
  my $result_code = '';

  if (-x $cmd && !$onu_info->{DELETED} && $FORM{COMMENTS} ne 'database') {
    delete $attr->{NAS_INFO}->{ACTION_LNG};
    $result = cmd($cmd, {
      DEBUG   => $FORM{DEBUG} || 0,
      PARAMS  => { %$attr, %FORM, %$onu_info, %{$attr->{NAS_INFO}} },
      ARGV    => 1,
      timeout => 30
    });

    $result_code = $? >> 8;
  }
  else {
    $result = "ONU: " . $onu_info->{BRANCH} . ":" . $onu_info->{ONU_ID} . " DELETED";
    $result_code = 1;
  }

  if ($result_code) {
    $html->message('info', $lang{INFO}, "$result");
    $Equipment->onu_del($FORM{del_onu});
    return 1;
  }
  else {
    $html->message('err', $lang{ERROR}, "$result");
    return 0;
  }

  return 0;
}
#********************************************************
=head2 equipment_pon_onu($attr) - Show PON ONU information

  Arguments:
    $attr
      NAS_INFO
      USED_PORTS -

  Returns:
    TRUE or FALSE
=cut
#********************************************************
sub equipment_pon_onu {
  my ($attr) = @_;

  my $nas_id = $attr->{NAS_INFO}{NAS_ID} || $FORM{NAS_ID};
  $Equipment->vendor_info($Equipment->{VENDOR_ID});
  _error_show($Equipment);

  #For old version
  if (!$attr->{VENDOR_NAME}) {
    $attr->{VENDOR_NAME} = $Equipment->{NAME};
  }
  my $nas_type = equipment_pon_init($attr);
  if (!$nas_type) {
    return 0;
  }

  my $used_ports = $attr->{USED_PORTS};
  if (!$used_ports) {
    $used_ports = equipments_get_used_ports({
      NAS_ID     => $nas_id,
      FULL_LIST  => 1,
      PORTS_ONLY => 1,
    });
    _error_show($Equipment);

  }

  my $page_gs = "&visual=$FORM{visual}&NAS_ID=$nas_id";
  $LIST_PARAMS{NAS_ID} = $nas_id;
  $LIST_PARAMS{PON_TYPE} = $FORM{PON_TYPE} || '';
  $LIST_PARAMS{OLT_PORT} = $FORM{OLT_PORT} || '';
  $LIST_PARAMS{BRANCH}   = $FORM{BRANCH} || '_SHOW' || '';

  my ($table, $list) = result_former({
    INPUT_DATA     => $Equipment,
    FUNCTION       => 'onu_list',
    BASE_FIELDS    => 2,
    DEFAULT_FIELDS => 'COMMENTS,MAC_SERIAL,STATUS,RX_POWER,LOGIN',
    SKIP_PAGES     => 1,
    TABLE          => {
      width            => '100%',
      caption          => "PON ONU",
      qs               => $page_gs,
      SHOW_COLS        => !$FORM{IN_MODAL}
        ? {
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
        vlan_id      => 'VLAN',
      }
        : {},
      SHOW_COLS_HIDDEN => {
        PON_TYPE => $FORM{PON_TYPE},
        OLT_PORT => $FORM{OLT_PORT},
        visual   => $FORM{visual},
        NAS_ID   => $nas_id,
      },
      ID               => '_EQUIPMENT_ONU',
      EXPORT           => 1,
    },
  });

  my $search_result_input_name = $FORM{PORT_INPUT_NAME} || 'PORTS';
  my $server_vlan = $attr->{NAS_INFO}->{SERVER_VLAN};

  my $port_vlan_list = $Equipment->pon_port_list({
    NAS_ID    => $nas_id,
    COLS_NAME => 1,
  });
  _error_show($Equipment);

  my %vlan_for_port = ();
  $vlan_for_port{$_->{id}} = $_->{vlan_id} foreach (@$port_vlan_list);

  my @cols = ();
  if ($table->{COL_NAMES_ARR}) {
    @cols = @{$table->{COL_NAMES_ARR}};
  }
  my @all_rows = ();

  foreach my $line (@$list) {
    my @row = ();

    for (my $i = 0; $i <= $#cols; $i++) {
      my $col_id = $cols[$i];
      last if ($col_id eq 'id');
      #print "Port: $port col: $i '$col_id' // $olt_ports->{$port}->{$col_id} //<br>";
      if ($col_id eq 'login' || $col_id eq 'address_full' || $col_id eq 'ID') {
        my $value = '';
        #print $used_ports->{$line->{dhcp_port}};
        if ($used_ports->{$line->{dhcp_port}}) {

          if ($col_id eq 'ID') {
            $value = 'busy'
          }
          else {
            foreach my $uinfo (@{$used_ports->{$line->{dhcp_port}}}) {
              $value .= $html->br() if ($value);
              if ($col_id eq 'login') {
                $value .= $html->button($uinfo->{login}, "index=11&UID=$uinfo->{uid}");
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
      elsif ($col_id =~ /power/) {
        push @row, pon_tx_alerts($line->{$col_id});
      }
      elsif ($col_id eq 'status') {
        push @row, pon_onu_convert_state($nas_type, $line->{status}, $line->{pon_type});
      }
      else {
        push @row, $line->{$col_id};
      }
    }

    my $btn_class = ($used_ports->{$line->{dhcp_port}}) ? 'btn-warning' : 'btn-success';

    my $data_value = ''
      . $search_result_input_name . '::' . $line->{dhcp_port}
      . '#@#' . 'SERVER_VLAN::' . $server_vlan
      . '#@#' . ($vlan_for_port{$line->{id}} ? "VLAN::$vlan_for_port{$line->{id}}" : ($line->{vlan} ? "VLAN::$line->{vlan}" : ''))
    ;

    push @row, "<div value='$line->{dhcp_port}' class='clickSearchResult'>"
      . "<button title='$line->{dhcp_port}' class='btn $btn_class'"
      . " onclick=\"fillSearchResults('$search_result_input_name', '$data_value')\"  >"
      . uc($line->{pon_type}) . " $line->{branch}:$line->{onu_id}</button>
        </div>";

    #Add to form
    #Equipment attach onu to user
    # $conf{EQUIPMENT_ONU_ATTACH}
    # NAS/PORT (DEFAULT)
    # MAC_SERIAL
    # SERVER_VLAN
    # VLAN

    push @all_rows, \@row;
  }

  print result_row_former({
    table => $table,
    ROWS  => \@all_rows,
  });

  print '<script>' . qq{jQuery(function () {
    var table = jQuery("#_EQUIPMENT_ONU_")
      .DataTable({
        "language": {
          paginate: {
              first:    "«",
              previous: "‹",
              next:     "›",
              last:     "»",
          },
          "zeroRecords":    "$lang{NOT_EXIST}",
          "lengthMenu":     "$lang{SHOW} _MENU_",
          "search":         "$lang{SEARCH}:",
          "info":           "$lang{SHOWING} _START_ - _END_ $lang{OF} _TOTAL_ ",
          "infoEmpty":      "$lang{SHOWING} 0",
          "infoFiltered":   "($lang{TOTAL} _MAX_)",
      },
      "ordering": false,
      "lengthMenu": [[25, 50, -1], [25, 50, "$lang{ALL}"]]
      });
      var column = table.column("0");
      
      // Toggle the visibility
      column.visible( ! column.visible() );
      table.search( 'free' ).draw();
      
      
       //<input type="search" class="form-control input-sm" placeholder="" aria-controls="_EQUIPMENT_ONU_">

      // Separate input for format independent MAC search
      var mac_input = jQuery('<input />', {
        'id' : 'EQUIPMENT_ONU_MAC',
        'class' : 'form-control input-sm',
        'type' : 'search'
        });
      
      mac_input.on('keyup',
       function(){
        var mac_any_format = this.value;
        var mac_symbols = mac_any_format.replace(/[:.]/gi,'').split('');
        console.log('raw symbols', mac_symbols);
        
        var mac_table_format = '';
        
        for (var i=0; i < mac_symbols.length; i++){
          
          if (i % 2 === 0 && i !== 0){
            mac_table_format += ':';
          }
          
          mac_table_format += mac_symbols[i];
        }
        
        console.log('search', mac_table_format);
        table.search(mac_table_format, false, false).draw();
      });
      
      var mac_label = jQuery('<label/>').text('MAC:').append(mac_input)
      jQuery('#_EQUIPMENT_ONU__filter').append(mac_label);

      
    });
    } . '</script>';

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
      BRANCH
      SHOW_FIELDS   - List fields on result
      NAS_ID        - NAS_ID
      snmp

  Returns:

=cut
#********************************************************
sub pon_onu_state {
  my ($id, $attr) = @_;

  #  $id = "1.8." . $id . ".72.192" if ($attr->{ONU_TYPE} && $attr->{ONU_TYPE} eq "gpon" && length $id < 25);
  #  $id = "1.8." . $id . ".17.192" if ($attr->{PON_TYPE} && $attr->{PON_TYPE} eq "gpon" && length $id < 25);
  #  _bp('', \$attr, {HEADER=>1});
  $Equipment->vendor_info($attr->{VENDOR_ID} || $Equipment->{VENDOR_ID});

  if (!$id) {
    #print "Can't find id";
    return [ [ 'Error:', "Can't find id" ] ];
  }

  #For old version
  my $nas_type = equipment_pon_init({ %{($attr) ? $attr : {}}, VENDOR_NAME => $Equipment->{NAME} });
  my $nas_id = $attr->{NAS_ID} || $FORM{NAS_ID};
  my $pon_type = $attr->{PON_TYPE} || $FORM{ONU_TYPE} || 'epon';
  my @quick_info = ('EQUIPMENT_ID', 'DISTANCE', 'VENDOR_ID', 'ONU_PORTS_STATUS', 'VLAN');

  if ($FORM{DEBUG}) {
    $attr->{DEBUG} = $FORM{DEBUG};
  }

  if (!$nas_type) {
    print "No PON device init\n";
    return 0;
  }

  if (!$attr->{VERSION}) {
    $attr->{VERSION} = $FORM{SNMP_VERSION} || $Equipment->{SNMP_VERSION};
  }

  if (!$attr->{BRANCH}) {
    my $onu_list = $Equipment->onu_list({
      #ONU_DHCP_PORT   => $attr->{PORT},
      NAS_ID      => $nas_id,
      ONU_SNMP_ID => $id,
      NAS_NAME    => '_SHOW',
      ONU_ID      => '_SHOW',
      MAC_SERIAL  => '_SHOW',
      #ONU_SNMP_ID     => '_SHOW',
      COLS_NAME   => 1
    });

    $attr->{BRANCH}     = $onu_list->[0]{branch} || q{};
    $attr->{ONU_SERIAL} = $onu_list->[0]{mac_serial} || q{};
    $attr->{ONU_ID}     = $onu_list->[0]{onu_id} || '0';
    $attr->{NAS_NAME}   = $onu_list->[0]{nas_name} || q{};
  }

  my @show_fields = ();
  if ($attr->{SHOW_FIELDS}) {
    @show_fields = split(/,\s?/, $attr->{SHOW_FIELDS});
    @quick_info = @show_fields;
  }

  my $snmp_info;
  if ($attr->{snmp}) {
    $snmp_info = $attr->{snmp};
  }
  else {
    $snmp_info = &{\&{$nas_type}}({ TYPE => $pon_type });
  }

  my $page_gs = "&visual=" . ($FORM{visual} || 4) . "&NAS_ID=$nas_id";
  $page_gs .= "&PON_TYPE=$pon_type";
  $page_gs .= "&OLT_PORT=$FORM{OLT_PORT}" if ($FORM{OLT_PORT});

  my $tr_069_data = tr_069_get_data({ QUERY => {
    'InternetGatewayDevice.DeviceInfo.SerialNumber'   => $attr->{ONU_SERIAL},
    'InternetGatewayDevice.ManagementServer.Username' => $attr->{NAS_NAME} }, PROJECTION => [ '_id' ], DEBUG => ($FORM{DEBUG} || 0)
  });

  my $tr_069_button = ($tr_069_data->[0]->{_id}) ? $html->button('',
    "NAS_ID=$nas_id&index=" . get_function_index('equipment_info')
      . "&visual=4&ONU=$id&info_pon_onu=" . ($attr->{ONU_SNMP_ID} || q{}) . "&ONU_TYPE=$pon_type&tr_069_id=$tr_069_data->[0]->{_id}",
    { class => 'btn btn-sm btn-success', ICON => 'glyphicon glyphicon-edit', TITLE => "TR-069" }) : '';

  my @info = ([
    'ONU',
    $html->element('span', "$pon_type " . ($attr->{BRANCH} || q{}) . (($attr->{ONU_ID}) ? ":$attr->{ONU_ID}" : q{}),
      { class => 'btn btn-sm btn-default', TITLE => 'ONU' })
      . $html->button('',
      "NAS_ID=$nas_id&index=" . get_function_index('equipment_info')
        . "&visual=4&ONU=$id&info_pon_onu=" . ($attr->{ONU_SNMP_ID} || q{}) . "&ONU_TYPE=$pon_type",
      { class => 'btn btn-sm btn-success', ICON => 'glyphicon glyphicon-info-sign', TITLE => $lang{INFO} })
      . $tr_069_button
      . $html->button('',
      "NAS_ID=$nas_id&index=" . get_function_index('equipment_info')
        . "&visual=4&onuReset=$id&ONU=$id&tr_069_id=" . ($FORM{tr_069_id} || q{}) . "&info_pon_onu=" . ($attr->{ONU_SNMP_ID} || q{}) . "&ONU_TYPE=$pon_type",
      { class => 'btn btn-sm btn-warning', ICON => 'glyphicon glyphicon-retweet', TITLE => $lang{REBOOT} . " ONU" })
      . $html->button('',
      "NAS_ID=$nas_id&index=" . get_function_index('equipment_info')
        . "&visual=4&ONU_TYPE=$pon_type&del_onu=" . ($FORM{info_pon_onu} || $attr->{ONU_SNMP_ID}) . (($attr->{ONU_ID}) ? "&LLID=$attr->{ONU_ID}" : q{}),
      { MESSAGE => "$lang{DEL} ONU $attr->{BRANCH}:$attr->{ONU_ID}?", class => 'btn btn-sm btn-danger', ICON => 'glyphicon glyphicon-ban-circle', TITLE => "$lang{DEL} ONU" })
      . "($id)"
  ]);

  if ($FORM{tr_069_id}) {
    my $table = $html->table({
      width => '100%',
      qs    => $pages_qs,
      ID    => 'EQUIPMENT_ONU_INFO',
      rows  => \@info
    });

    print $table->show();
    tr_069_cpe_info($FORM{tr_069_id}, { %FORM });

    return 1;
  }
  #FETCH INFO
  my %port_info = ();
  my @data2hash_param = ('ETH_ADMIN_STATE', 'ETH_DUPLEX', 'ETH_SPEED', 'VLAN');
  foreach my $oid_name (sort keys %{$snmp_info}) {

    if ($#show_fields > -1 && !in_array($oid_name, \@show_fields)) {
      next;
    }

    my $oid = $snmp_info->{$oid_name}->{OIDS} || q{};

    if (!$oid || $oid_name eq 'reset') {
      next;
    }

    my $add_2_oid = $snmp_info->{$oid_name}->{ADD_2_OID} || '';

    my $value = snmp_get({
      %$attr,
      VERSION => '2',
      OID     => $oid . '.' . $id . $add_2_oid,
      SILENT  => 1,
    });

    my $function = $snmp_info->{$oid_name}->{PARSER};

    if ($function && defined(&{$function})) {
      ($value) = &{\&$function}($value);
    }

    if ($oid_name =~ /STATUS/) {
      if ($value) {
        $value = pon_onu_convert_state($nas_type, $value, $pon_type);
      }
    }

    if ($snmp_info->{$oid_name}->{NAME}) {
      $oid_name = $snmp_info->{$oid_name}->{NAME};
    }

    $port_info{$id}{$oid_name} = $value;
  }

  foreach my $oid_name (sort keys %{$snmp_info->{main_onu_info}}) {
    if ($attr->{QUICK} && !in_array($oid_name, \@quick_info)) {
      next;
    }

    my $oid = $snmp_info->{main_onu_info}->{$oid_name}->{OIDS};

    if (!$oid) {
      next;
    }

    my $value = q{};

    if ($snmp_info->{main_onu_info}->{$oid_name}->{WALK}) {
      my $value_list = snmp_get({
        %{$attr},
        OID     => $oid . '.' . $id,
        TIMEOUT => 3,
        WALK    => 1,
      });

      if ($value_list) {
        foreach my $line (@{$value_list}) {
          my ($oid_, $val) = split(/:/, $line, 2);
          my $function = $snmp_info->{main_onu_info}->{$oid_name}->{PARSER};
          if ($function && defined(&{$function})) {
            ($oid_, $val) = &{\&$function}($line);
          }

          if (in_array($oid_name, \@data2hash_param)) {
            #$port_info{$id}{$oid_name}{$oid_} = $val;
            if(ref $port_info{$id}{$oid_name} eq 'HASH') {
              $port_info{$id}{$oid_name}{$oid_} = $val;
            }
            else {
              $port_info{$id}{$oid_name} = { $oid_ => $val };
            }
          }
          else {
            $value .= $oid_.' '.$val."\n"; #. $html->br();
          }
        }
      }
    }
    else {
      my $add_2_oid = $snmp_info->{main_onu_info}->{$oid_name}->{ADD_2_OID} || '';

      $value = snmp_get({
        %{$attr},
        OID => $oid . '.' . $id . $add_2_oid
      });

      my $function = $snmp_info->{main_onu_info}->{$oid_name}->{PARSER};
      if ($function && defined(&{$function})) {
        ($value) = &{\&$function}($value);
      }
    }

    if ($snmp_info->{main_onu_info}->{$oid_name}->{NAME}) {
      $oid_name = $snmp_info->{main_onu_info}->{$oid_name}->{NAME};
    }

    if ($value) {
      $port_info{$id}{$oid_name} = $value;
    }
  }

  $FORM{TEST_DISTANCE} = 1 if (!$attr->{SHOW_FILEDS});
  push @info, @{ port_result_former(\%port_info, {
    PORT => $id,
    #INFO_FIELDS => $info_fields
  })};

  if ($attr->{OUTPUT2RETURN}) {
    return \@info;
  }

  my $function = $nas_type . '_get_service_ports';
  if ($function && defined(&{$function})) {
    my @sp_arr = &{\&$function}({ %{$attr}, ONU_SNMP_ID => $id });
    foreach my $line (@sp_arr) {
      push @info, [ $line->[0], $line->[1] ];
    }
  }

  my $table = $html->table({
    width => '100%',
    qs    => $pages_qs,
    ID    => 'EQUIPMENT_ONU_INFO',
    rows  => \@info
  });

  print $table->show();

  equipment_pon_onu_graph({
    ONU_SNMP_ID => $attr->{ONU_SNMP_ID},
    PON_TYPE    => $pon_type,
    snmp        => $snmp_info
  });

  if (!$attr->{snmp} || !$attr->{snmp}->{onu_info} || scalar keys %{$attr->{snmp}->{onu_info}} == 0) {
    return 0;
  }

  my %info_oids = ();

  foreach my $oid_name (keys %{$attr->{snmp}->{onu_info}}) {
    $info_oids{ uc($oid_name) } = $oid_name;
  }

  my $list;
  ($table, $list) = result_former({
    DEFAULT_FIELDS => 'ONUUNIIFSPEED,ONUUNIIFSPEEDLIMIT',
    BASE_PREFIX    => 'PORT,STATUS',
    TABLE          => {
      width            => '100%',
      caption          => $lang{PORTS},
      qs               => "&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&ONU=$FORM{ONU}",
      SHOW_COLS        => \%info_oids,
      SHOW_COLS_HIDDEN => {
        visual => $FORM{visual},
        NAS_ID => $FORM{NAS_ID},
        ONU    => $FORM{ONU},
      },
      ID               => 'EQUIPMENT_ONU_PORTS',
    },
  });

  my %ports_info = ();
  my @cols = ();
  if ($table->{COL_NAMES_ARR}) {
    @cols = @{$table->{COL_NAMES_ARR}};
  }

  foreach my $oid_name (@cols) {
    if (!$attr->{snmp}->{onu_info}->{ $info_oids{$oid_name} }) {
      next;
    }
    my $oid = $attr->{snmp}->{onu_info}->{ $info_oids{$oid_name} } . '.' . $id;
    my $value_arr = snmp_get({
      %{$attr},
      OID  => $oid,
      WALK => 1
    });

    foreach my $line (@{$value_arr}) {
      my ($port_id, $value) = split(/:/, $line, 2);
      $ports_info{$oid_name}{$id}{$port_id} = $value;
    }
  }

  my $ports_arr = snmp_get({
    %{$attr},
    WALK => 1,
    OID  => 'enterprises.3320.101.12.1.1.8.' . $id
  });

  my @all_rows = ();

  foreach my $key_ (sort @{$ports_arr}) {
    my ($port_id, $state) = split(/:/, $key_);

    if ($state == 1) {
      $state = "up";
    }
    elsif ($state == 2) {
      $state = "down";
    }

    my @arr = ($port_id, $state);

    for (my $i = 2; $i <= $#cols; $i++) {
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

  if (!$tx || $tx == 65535) {
    $tx = '';
  }
  elsif ($tx > 0) {
    $tx = $html->color_mark($tx, 'text-green');
  }
  elsif ($tx > -8 || $tx < -30) {
    $tx = $html->color_mark($tx, 'text-red');
  }
  elsif ($tx > -10 || $tx < -27) {
    $tx = $html->color_mark($tx, 'text-yellow');
  }
  else {
    $tx = $html->color_mark($tx, 'text-green');
  }

  return $tx;
}

#********************************************************
=head2 equipment_pon_ports($attr) - Show PON information

  Arguments:
    $attr
      SNMP_COMMUNITY
      NAS_INFO
      DEBUG

  Returns:
    TRUE or FALSE

=cut
#********************************************************
sub equipment_pon_ports {
  my ($attr) = @_;

  my @ports_state = ('', 'UP', 'DOWN', 'Damage', 'Corp vlan', 'Dormant', 'Not Present', 'lowerLayerDown');
  my @ports_state_color = ('', '#008000', '#FF0000');
  if ($attr->{NAS_INFO}) {
    $attr->{VERSION} //= $attr->{NAS_INFO}->{SNMP_VERSION};
  }

  my $debug = $attr->{DEBUG} || 0;
  my $nas_id = $FORM{NAS_ID} || 0;

  $Equipment->vendor_info($Equipment->{VENDOR_ID});
  #For old version
  if (!$attr->{VENDOR_NAME}) {
    $attr->{VENDOR_NAME} = $Equipment->{NAME};
  }

  my $nas_type = equipment_pon_init($attr);
  if (!$nas_type) {
    return 0;
  }

  my $func_ports_state = $nas_type . '_ports_state';
  if (defined(&{$func_ports_state})) {
    @ports_state = &{\&$func_ports_state}();
  }

  if ($FORM{chg_pon_port}) {
    $Equipment->pon_port_info($FORM{chg_pon_port});

    $Equipment->{ACTION} = 'change_pon_port';
    $Equipment->{ACTION_LNG} = $lang{CHANGE};
    $attr->{SNMP_TPL} = $attr->{NAS_INFO}->{SNMP_TPL};

    my $vlan_hash = get_vlans($attr);
    my %vlans = ();

    foreach my $vlan_id (keys %{$vlan_hash}) {
      $vlans{ $vlan_id } = "Vlan$vlan_id (". (($vlan_hash->{ $vlan_id }->{NAME}) ? $vlan_hash->{ $vlan_id }->{NAME} : q{}) .")";
    }

    $Equipment->{VLAN_SEL} = $html->form_select('VLAN_ID', {
      SELECTED    => $FORM{VLAN_ID} || '',
      SEL_OPTIONS => { '' => '--' },
      SEL_HASH    => \%vlans,
      NO_ID       => 1
    });

    $html->tpl_show(_include('equipment_pon_port', 'Equipment'), { %{$Equipment}, %FORM });
  }
  elsif ($FORM{change_pon_port}) {
    $Equipment->pon_port_change({ %FORM });
    if (!$Equipment->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif (defined($FORM{del_pon_port}) && $FORM{COMMENTS}) {
    $Equipment->pon_port_del($FORM{del_pon_port});
    if (!$Equipment->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
    elsif ($Equipment->{ONU_TOTAL}) {
      $html->message('err', $lang{ERROR}, "$lang{REGISTERED} $Equipment->{ONU_TOTAL} onu!");
    }
  }

  my $olt_ports = equipment_pon_get_ports({
    %{$attr},
    ONU_COUNT  => '_SHOW',
    NAS_ID     => $Equipment->{NAS_ID},
    NAS_TYPE   => $nas_type,
    SNMP_TPL   => $Equipment->{SNMP_TPL},
    MODEL_NAME => $Equipment->{MODEL_NAME}
  });

  foreach my $key (keys %$olt_ports)
  {
    if ($olt_ports->{$key}{pon_type} eq "epon") {
      $olt_ports->{$key}{FREE_ONU} = 64 - $olt_ports->{$key}{onu_count};
    }
    if ($olt_ports->{$key}{pon_type} eq "gpon") {
      $olt_ports->{$key}{FREE_ONU} = 128 - $olt_ports->{$key}{onu_count};
    }
    if ($olt_ports->{$key}{pon_type} eq "gepon") {
      $olt_ports->{$key}{FREE_ONU} = 128 - $olt_ports->{$key}{onu_count};
    }
  }

  $pages_qs = "&visual=$FORM{visual}&NAS_ID=$nas_id&TYPE=PON";
  my ($table) = result_former({
    DEFAULT_FIELDS => 'PON_TYPE,BRANCH,PORT_ALIAS,VLAN_ID,ONU_COUNT,FREE_ONU,PORT_STATUS,TRAFFIC',
    BASE_PREFIX    => 'ID',
    TABLE          => {
      width            => '100%',
      caption          => "PON $lang{PORTS}",
      qs               => $pages_qs,
      SHOW_COLS        => {
        #ID          => 'Billing ID',
        BRANCH      => $lang{BRANCH},
        PON_TYPE    => $lang{TYPE},
        BRANCH_DESC => "BRANCH_DESC",
        VLAN_ID     => "VLAN",
        TRAFFIC     => $lang{TRAFFIC},
        PORT_STATUS => $lang{STATUS},
        PORT_SPEED  => $lang{SPEED},
        ONU_COUNT   => "ONU $lang{COUNT}",
        FREE_ONU    => "$lang{COUNT} $lang{FREE_ONU} ONU",
        PORT_NAME   => "BRANCH_NAME",
        PORT_ALIAS  => $lang{COMMENTS}
      },
      SHOW_COLS_HIDDEN => {
        PON_TYPE => $FORM{PON_TYPE},
        OLT_PORT => $FORM{OLT_PORT},
        visual   => $FORM{visual},
        NAS_ID   => $nas_id,
        TYPE     => 'PON'
      },
      ID               => 'EQUIPMENT_PON_PORTS',
      EXPORT           => 1,
    }
  });

  my @cols = ();
  if ($table->{COL_NAMES_ARR}) {
    @cols = @{$table->{COL_NAMES_ARR}};
  }


  #Get onu list
  #my %onu_count = ();

  my @all_rows = ();
  my @ports_arr = keys %{$olt_ports};
  foreach my $port (@ports_arr) {
    my @row = ($port);
    for (my $i = 1; $i <= $#cols; $i++) {
      my $col_id = $cols[$i];

      if ($debug) {
        print "Port: $port col: $i '$col_id' // " . ($olt_ports->{$port}->{$col_id} || 'uninicialize') . " //<br>";
      }

      if ($col_id eq 'TRAFFIC') {
        push @row,
          "in: " . int2byte($olt_ports->{$port}{PORT_IN}) . $html->br() . "out: " . int2byte($olt_ports->{$port}{PORT_OUT});
      }
      elsif ($col_id eq 'ONU_COUNT') {
        my $onu = ($olt_ports->{$port}{ONU_COUNT}) ? $html->button($olt_ports->{$port}{ONU_COUNT},
          "index=$index&visual=4&NAS_ID=$FORM{NAS_ID}&PON_TYPE=$olt_ports->{$port}{PON_TYPE}&OLT_PORT=$olt_ports->{$port}{ID}") : q{};

        push @row, $onu;
      }
      elsif ($olt_ports->{$port} && $olt_ports->{$port}->{$col_id}) {
        if ($col_id eq 'PORT_STATUS') {
          push @row, ($olt_ports->{$port} && $olt_ports->{$port}{PORT_STATUS})
            ? $html->color_mark(
            $ports_state[ $olt_ports->{$port}{PORT_STATUS} ],
            $ports_state_color[ $olt_ports->{$port}{PORT_STATUS} ]) : '';
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
    $olt_ports->{$port}{PORT_ALIAS} ||= '';
    $olt_ports->{$port}{VLAN_ID} ||= '';

    push @row, $html->button($lang{INFO},
      "index=$index&chg_pon_port=" . $olt_ports->{$port}{ID}
        . "&VLAN_ID=" . $olt_ports->{$port}{VLAN_ID}
        . "&BRANCH_DESC=" . $olt_ports->{$port}{PORT_ALIAS} . $pages_qs,
      { class => 'change' })
      . $html->button($lang{DEL},
      "index=$index&del_pon_port=" . $olt_ports->{$port}{ID} . $pages_qs,
      { MESSAGE => "$lang{DEL} $lang{PORT}: $port?", class => 'del' });

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
sub equipment_pon_onu_graph {
  my ($attr) = @_;

  my $snmp_id = $attr->{ONU_SNMP_ID} || $FORM{graph_onu};
  my $onu_info = $Equipment->onu_info($snmp_id);
  my $pon_type = $attr->{PON_TYPE} || $FORM{ONU_TYPE};

  if (!defined($Equipment->{ONU_ID})) {
    return 0;
  }

  my @onu_graph_types = split(',', $onu_info->{ONU_GRAPH} || q{});
  my $snmp_info = $attr->{snmp};
  my %graph_hash = ();
  my @rows = ();

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

  push @rows, "$lang{PERIOD}:", $html->form_select('PERIOD', {
    SELECTED     => $FORM{PERIOD},
    SEL_HASH     => \%periods,
    SORT_KEY_NUM => 1,
    ID           => 'type',
    EX_PARAMS    =>
      "data-auto-submit='index=$index&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&graph_onu=$snmp_id&ONU_TYPE=$pon_type&info_pon_onu=$FORM{info_pon_onu}&ONU=$FORM{ONU}'",
    NO_ID        => 1
  });

  push @rows, $html->form_input('show', $lang{SHOW}, { TYPE => 'submit', FORM_ID => 'period_panel' });

  my %info = ();
  foreach my $val (@rows) {
    $info{ROWS} .= $html->element('div', $val, { class => 'form-group' });
  }

  my $report_form = $html->element('div', $info{ROWS}, {
    class => 'well well-sm',
  });

  print $html->form_main({
    CONTENT => $report_form, #. $FIELDS . $TAGS,
    HIDDEN  => {
      index        => $index,
      visual       => $FORM{visual},
      NAS_ID       => $FORM{NAS_ID},
      #graph_onu => $snmp_id,
      ONU_TYPE     => $pon_type,
      info_pon_onu => $FORM{info_pon_onu},
      ONU          => $FORM{ONU}
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
        NAS_ID     => $FORM{NAS_ID},
        PORT       => $onu_info->{ONU_SNMP_ID},
        TYPE       => 'SPEED',
        DS_NAMES   => \@onu_ds_names,
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
      foreach my $val (@{$graph->{data}}) {
        push @time_arr, POSIX::strftime("%b %d %H:%M", localtime($val->[0]));

        for (my $i = 0; $i <= $#{$graph->{meta}->{legend}}; $i++) {
          my $index = $i + 1;
          if ($graph_type eq 'SPEED') {
            $val->[$index] = sprintf("%.2f", $val->[$index] / (1024 * 1024) * 8) if ($val->[$index]);
          }
          else {
            $val->[$index] = sprintf("%.2f", $val->[$index]) if ($val->[$index]);
          }
          push @{$graph_data{ $graph->{meta}->{legend}->[$i] }}, $val->[$index];
        }
      }
      push @graphs, $html->make_charts_simple({
        GRAPH_ID      => lc($graph_type),
        DIMENSION     => $graph->{DIMENSION},
        TITLE         => $graph_type,
        TRANSITION    => 1,
        X_TEXT        => \@time_arr,
        DATA          => \%graph_data,
        OUTPUT2RETURN => 1
      });
    }
  }
  #_error_show($Equipment);
  print "<div class=row>";
  foreach my $graph (@graphs) {
    print "<div class='col-md-" . (12 / ($#graphs + 1)) . "'>" . ($graph || q{}) . "</div>";
  }
  print "</div>";

  return 1;
}

#**********************************************************
=head2 pon_onu_convert_state($nas_type, $status, $pon_type)

  Arguments:
    $nas_type
    $status
    $pon_type

  Results:
    $status

=cut
#**********************************************************
sub pon_onu_convert_state {
  my ($nas_type, $status, $pon_type) = @_;

  my $status_hash = ();
  my $get_status_fn = $nas_type . '_onu_status';

  if (defined(&{$get_status_fn})) {
    $status_hash = &{\&{$get_status_fn}}($pon_type);
  }

  if (!$status_hash->{ $status }) {
    $status_hash->{ $status } = "Unknown_status($status):text-orange"
  }

  my ($status_desc, $color) = split(/:/, $status_hash->{ $status });
  $status = $html->color_mark($status_desc, $color);

  return $status;
}
#**********************************************************
=head2 equipment_pon_form()

=cut
#**********************************************************
sub equipment_pon_form {

  $Equipment->{OLT_SEL} = $html->form_select(
    'NAS_ID',
    {
      SEL_OPTIONS => { '' => '--' },
      SEL_LIST    => $Equipment->_list({ NAS_NAME => '_SHOW', COLS_NAME => 1, PAGE_ROWS => 10000, TYPE_NAME => 4 }),
      SEL_KEY     => 'nas_id',
      SEL_VALUE   => 'nas_id,nas_name',
      NO_ID       => 1,
    }
  );
  $FORM{INDEX} = get_function_index('equipment_info');
  $html->tpl_show(_include('equipment_pon', 'Equipment'), { %{$Equipment}, %FORM });

  return 1;
}


1
