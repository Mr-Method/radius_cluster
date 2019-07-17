=head1 NAME

  Ports information and managment

=cut
use strict;
use warnings FATAL => 'all';
use Abills::Base qw(int2byte in_array int2ip _bp);

our(
  %lang,
  $html,
  $admin,
  $db,
  %conf,
  %permissions
);

my @service_status_colors = ($_COLORS[9], "840000", '#808080', '#0000FF', $_COLORS[6], '#009999');
my @service_status = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE}, $lang{ERROR}, $lang{BREAKING});
our @port_types = ('', 'RJ45', 'GBIC', 'Gigabit', 'SFP');
our @skip_ports_types = [
  135,
  142,
  136,
  1,
  24,
  250,
  300,
  53
];

my @ports_state = ('', "Up", "Down", 'Damage', 'Corp vlan', 'Dormant', 'Not Present', 'lowerLayerDown');
#my @admin_ports_state = ('', 'Enabled', 'Disabled', 'Testing');
my @admin_ports_state = ('', 'Up', 'Down', 'Testing');
my @ports_state_color = ('', '#008000', '#FF0000');

require Equipment::Pon_mng;

my $Equipment = Equipment->new( $db, $admin, \%conf );
my $used_ports;

#********************************************************
=head2 equipment_ports_full($attr)

  Aargumnets:
    $attr
      SNMP_COMMUNITY
      NAS_INFO

  Results:

=cut
#********************************************************
sub equipment_ports_full {
  my($attr)=@_;

  my $SNMP_COMMUNITY = $attr->{SNMP_COMMUNITY};
  my $nas_id         = $FORM{NAS_ID};
  my $Equipment_     = $attr->{NAS_INFO};

  if ( $Equipment_->{TYPE_ID} && $Equipment_->{TYPE_ID} == 4 ){
    my @header_arr = (
      "$lang{MAIN}:index=$index&visual=2&NAS_ID=$nas_id",
      "PON:index=$index&visual=2&NAS_ID=$nas_id&TYPE=PON",
    );

    print $html->table_header( \@header_arr, { TABS => 1 } );
    if($FORM{TYPE} && $FORM{TYPE} eq 'PON') {
      equipment_pon_ports($attr);
      return 1;
    }
  }

  #Check snmp template
  my $ports_tpl;
  my %tpl_fields = ();

  if ( defined( $Equipment_->{STATUS} ) && $Equipment_->{STATUS} != 1 ){
    my $perl_scalar = _get_snmp_oid( $Equipment_->{SNMP_TPL} );
    if ( $perl_scalar && $perl_scalar->{ports} ){
      $ports_tpl = $perl_scalar->{ports};

      foreach my $key ( keys %{ $perl_scalar->{ports} } ){
        next if (ref $key eq 'HASH');
        if($perl_scalar->{ports}->{$key}->{PARSER} ne 'hidden') {
          $tpl_fields{$key} = $key;
        }
      }
    }
  }

  $tpl_fields{PORT_DESCR}  = "Description";
  $tpl_fields{NATIVE_VLAN} = "Native VLAN dynamic";

  #New
  my $default_fields = 'PORT_NAME,PORT_STATUS,ADMIN_PORT_STATUS,UPLINK,LOGIN,MAC,VLAN,PORT_ALIAS,TRAFFIC';
  my ($table, $list) = result_former({
    DEFAULT_FIELDS => $default_fields,
    FIEDLS_NO_SORT => 1,
    BASE_PREFIX  => 'ID',
    TABLE        => {
      width            => '100%',
      caption          => $lang{PORTS},
      qs               => "&visual=$FORM{visual}&NAS_ID=$nas_id",
      SHOW_COLS        => {
        %tpl_fields,
        #ID           => 'ID',
        PORT_NAME         => "$lang{PORT} $lang{NAME}",
        PORT_STATUS       => "$lang{PORT} $lang{STATUS}",
        ADMIN_PORT_STATUS => "Admin $lang{STATUS}",
        UPLINK            => "UPLINK",
        FIO               => $lang{FIO},
        LOGIN             => $lang{LOGIN},
        MAC               => "MAC",
        IP                => "IP",
        VLAN              => "Native VLAN static",
        ADDRESS_FULL      => $lang{ADDRESS},
        DEPOSIT           => $lang{DEPOSIT},
        TP_NAME           => $lang{TARIF_PLAN},
        PORT_ALIAS        => $lang{COMMENTS},
        TRAFFIC           => $lang{TRAFFIC},
        PORT_SPEED        => $lang{SPEED},
      },
      SHOW_COLS_HIDDEN => {
        visual => $FORM{visual},
        NAS_ID => $nas_id,
      },
      ID       => 'EQUIPMENT_PORTS',
      EXPORT   => 1,
    },
  });

  my @cols = ();
  if ( $table->{COL_NAMES_ARR} ){
    @cols = @{ $table->{COL_NAMES_ARR} };
  }

  my $cols_list = join( ',', @cols );
  my $ports_info;
  $cols_list .= ',PORT_TYPE';
  #Get snmp info
  if ( ! $Equipment_->{STATUS} ){
    $ports_info = equipment_test(
      {
        VERSION        => $Equipment_->{SNMP_VERSION},
        SNMP_COMMUNITY => $SNMP_COMMUNITY,
        PORT_INFO      => $cols_list, # || 'STATUS,PORT_NAME,PORT_STATUS,IN,OUT,speed,pair_length',
        SNMP_TPL       => $Equipment_->{SNMP_TPL},
        %{$attr}
      }
    );
  }
  else {
    $html->message( 'warn', $lang{INFO}, "$lang{STATUS} $service_status[$Equipment_->{STATUS}]" );
  }

  if(! $ports_info || ! scalar %$ports_info) {
    $html->message( 'warn', 'Offline mode');

    my $port_nums = $Equipment_->{PORTS} || 10;
    for(my $i=1; $i<=$port_nums; $i++ ) {
      $ports_info->{$i}={};
    }
  }

  my $port_shift = 0;
  #if($Equipment_->{MODEL_ID} && $Equipment_->{MODEL_ID} == 185) {
  if($Equipment_->{PORT_SHIFT}) {
    $port_shift = $Equipment_->{PORT_SHIFT};
  }

  #ports Autoshift
  foreach my $key (keys %{$ports_info}){
    if ($#skip_ports_types > -1 && in_array($ports_info->{$key}{PORT_TYPE}, \@skip_ports_types) || ! $ports_info->{$key}{PORT_TYPE}){
      delete $ports_info->{$key};
    }
  }

  my @ports_arr = keys %{ $ports_info };

  $used_ports = equipments_get_used_ports({
    NAS_ID     => $nas_id,
    PORTS_ONLY => 1,
    FULL_LIST  => 1,
  });

  #get info
  $list = $Equipment->port_list({
    NAS_ID     => $nas_id,
    TP_NAME    => '_SHOW',
    %LIST_PARAMS,
    SORT       => 1,
    PAGE_ROWS  => 100,
    COLS_UPPER => 1,
    COLS_NAME  => 1
  });

  _error_show( $Equipment );

  foreach my $line ( @{$list} ){
    $ports_info->{ $line->{port} } = { %{ ($ports_info->{ $line->{port} }) ? $ports_info->{ $line->{port} } : {} }, %{$line} };
  }

  my @all_rows = ();

  #Get users mac
  my %users_mac = ();

  my $users_mac = $Equipment->mac_log_list({
    PORT      => '_SHOW',
    PAGE_ROWS => 20000,
    COLS_NAME => 1,
    NAS_ID    => $nas_id,
    GROUP_BY  => 'port',
    MAC_COUNT => '_SHOW'
  });

  foreach my $line (@$users_mac) {
    $users_mac{$line->{port} || 0} = $line->{mac_count};
  }

  foreach my $port ( @ports_arr ){
    $ports_info->{$port}{STATUS} = 1;
    my @row = ($port);
    for ( my $i = 1; $i <= $#cols; $i++ ){
      my $col_id = $cols[$i];

      if ( $col_id eq 'ADMIN_PORT_STATUS' ){
        push @row, (defined( $ports_info->{$port}->{ADMIN_PORT_STATUS} ))  ? $html->color_mark(
              $admin_ports_state[ $ports_info->{$port}->{ADMIN_PORT_STATUS} ],
              $ports_state_color[ $ports_info->{$port}->{ADMIN_PORT_STATUS} ] ) : '--';
      }
      elsif ( $col_id eq 'TRAFFIC' ){
        push @row,
          "in: " . int2byte( $ports_info->{$port}{PORT_IN} ) . $html->br() . "out: " . int2byte( $ports_info->{$port}{PORT_OUT} );
      }
      elsif ( $col_id eq 'IP' || $col_id eq 'LOGIN' || $col_id eq 'ADDRESS_FULL' || $col_id eq 'FIO' ||  $col_id eq 'TP_NAME'){
        my $value = '';
        my $snmp_port = $port - $port_shift;
        if ($used_ports->{$snmp_port}) {
          if ($col_id eq 'LOGIN') {
            $value .= show_used_info( $used_ports->{ $snmp_port } );
          }
          else {
            foreach my $uinfo (@{ $used_ports->{$snmp_port} }) {
              $value .= $html->br() if ($value);

              if ($col_id eq 'IP') {
                $value .= int2ip($uinfo->{ip_num}) || "";
              }
              elsif ($col_id eq 'ADDRESS_FULL') {
                $value .= $uinfo->{address_full} || "";
              }
              elsif ($col_id eq 'FIO') {
                $value .= $uinfo->{fio} || "";
              }
              elsif ($col_id eq 'TP_NAME') {
                $value .= $uinfo->{tp_id} || "";
                $value .= ':';
                $value .= $uinfo->{tp_name} || "";
              }
            }
          }
        }
        push @row, $value;
      }
      elsif ( $col_id eq 'MAC' )  {
        my $value = q{};
        if($users_mac{$port}) {
          $value = $html->button(
                $users_mac{$port}, "index=" .get_function_index( 'equipment_mac_log' ). "&NAS_ID=$nas_id&PORT=$port&search=1",
                { BUTTON => 1 } );
        }
        push @row, $value;
      }
      elsif ($ports_info->{$port} && $ports_info->{$port}->{$col_id} ){
        if ( $col_id eq 'PORT_STATUS' ){
          push @row, ($ports_info->{$port} && $ports_info->{$port}{PORT_STATUS})
              ? $html->button(
                $html->color_mark( $ports_state[ $ports_info->{$port}{PORT_STATUS} ],
                  $ports_state_color[ $ports_info->{$port}{PORT_STATUS} ] ),
                "index=$index&change=1&ID=" . (($used_ports->{$port} && ref $used_ports->{$port} eq 'HASH' && $used_ports->{$port}->{id}) ? $used_ports->{$port}->{id} : q{})
                  . "&PORT=$port&STATUS=" . (($ports_info->{$port}{PORT_STATUS}) ? 1 : 0) . "&NAS_ID=$nas_id"
                ,
                { TITLE => (($ports_info->{$port}{PORT_STATUS}) ? $lang{HANGUP} : $lang{ACTIVE} ) }
              )
              : '';
        }
        elsif ( $col_id eq 'UPLINK' ){
          my $value = '';
          if ($ports_info->{$port} && $used_ports->{ 'sw:' . $ports_info->{$port}->{UPLINK} }) {
            $value .= show_used_info( $used_ports->{ 'sw:' . $ports_info->{$port}->{UPLINK} } );
          }
          push @row, $value;
        }
        elsif($col_id eq 'VLAN' || $col_id eq 'NATIVE_VLAN') {
          if (defined($ports_info->{$port-$port_shift})) {
            push @row, $ports_info->{$port - $port_shift}->{$col_id};
          }
          else {
            push @row, q{};
          }
        }
        else{
          push @row, $ports_info->{$port}->{$col_id};
        }
      }
      else{
        push @row, '';
      }
    }

    push @row, $html->button( $lang{INFO}, "index=$index&visual=$FORM{visual}&PORT=$port&chg=" . $port . "&NAS_ID=$nas_id",
        { class => 'change' } )
        . $html->button( $lang{DEL}, "index=$index&visual=$FORM{visual}&PORT=$port&del=" . $port . "&NAS_ID=$nas_id",
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
=head2 equipment_ports($attr)

  Arguments:
    $attr


=cut
#********************************************************
sub equipment_ports{
  my ($attr) = @_;

  #my $SNMP_COMMUNITY = $attr->{SNMP_COMMUNITY} || q{};
  $Equipment->{ACTION} = 'add';
  $Equipment->{ACTION_LNG} = $lang{ADD};

  if ( $FORM{add} ){
    $Equipment->port_add( { %FORM } );

    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{ADDED}" );
      if($FORM{SNMP}) {
#        equipment_test({
#          SNMP_COMMUNITY => $SNMP_COMMUNITY,
#          PORT_STATUS    => "$FORM{PORT}:".(int( $FORM{STATUS} ) + 1)
#        });
      }
      $Equipment->{ID}     = $Equipment->{INSERT_ID};
      $FORM{chg}           = $Equipment->{ID};
      $Equipment->{ACTION} = 'change';
      $Equipment->{ACTION_LNG} = $lang{CHANGE};
    }
  }
  elsif ( $FORM{change} ){
    $Equipment->port_change( { %FORM } );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );
      if($FORM{SNMP}) {
#        equipment_test({
#          SNMP_COMMUNITY=> $SNMP_COMMUNITY,
#          PORT_STATUS   =>($FORM{PORT} ? $FORM{PORT} : q{}).":".($FORM{STATUS} ? $FORM{STATUS} : q{})
#        });
      }

      $Equipment->{ACTION} = 'change';
      $Equipment->{ACTION_LNG} = $lang{CHANGE};
    }
  }
  elsif ( defined( $FORM{del} ) && defined( $FORM{COMMENTS} ) ){
    $Equipment->port_info({ NAS_ID => $FORM{NAS_ID}, PORT => $FORM{del} } );
    if ( !$Equipment->{errno} ){
      $Equipment->port_del( $Equipment->{ID} );
      if ( !$Equipment->{errno} ){
        $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
        delete $FORM{PORT};
      }
    }
  }
  elsif ( $FORM{PORT} ){
    $Equipment->port_info({ NAS_ID => $FORM{NAS_ID}, PORT => $FORM{PORT} } );
    if ( !$Equipment->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGING} $lang{PORT}: $FORM{PORT}" );
      $Equipment->{ACTION} = 'change';
      $Equipment->{ACTION_LNG} = $lang{CHANGE};
    }
  }

  _error_show( $Equipment, { ID => 451, MESSAGE => $lang{PORT} } ) ;

  $FORM{visual} = 2 if (!defined( $FORM{visual} ) && !$FORM{PORT});

  #Get users from dhcp
#  if ( !$used_ports ){
#    $used_ports = equipments_get_used_ports( { NAS_ID => $FORM{NAS_ID} } );
#  }

  my $visual = $FORM{visual} || 0;
  if ( $visual == 0 && !$FORM{PORT} ){
    #Show pons
    if ( $attr->{NAS_INFO}->{TYPE_ID} && $attr->{NAS_INFO}->{TYPE_ID} eq '4' ) {
      equipment_pon_onu({
        %$attr,
#        USED_PORTS => $used_ports
      });
    }
    else {
      equipment_ports_select(
        %$attr,
#        USED_PORTS => $used_ports
      );
    }
  }
  #Show vlans
  elsif ( $visual == 1 ){
    equipment_vlans({
      %$attr,
      VLAN           => 1
    });
  }
  #Show ports
  elsif ( $visual == 2 && !$FORM{PORT}){
    equipment_ports_full( $attr );
  }
  # ARP SNMP
  elsif ( $visual == 3 ){
    equipment_snmp_info({
      %$attr,
      ARP            => 1
    });
  }
  # Pon information
  elsif ( $visual == 4 ){
    equipment_pon({
      %$attr,
 #     USED_PORTS     => $used_ports
    });
  }
  #Get FDB
  elsif ( $visual == 6 ){
    equipment_snmp_info({
      %$attr,
      FDB            => 1
    });
  }
  elsif ( $visual == 8 ){
    equipment_snmp_info({
      %$attr,
    });
  }
  # Backup management
  elsif ( $visual == 9 ){
    equipment_show_snmp_backup_files("BACKUP", $FORM{NAS_ID});
  }
  elsif ( $visual == 10) {
    equipment_show_log($FORM{NAS_ID});
  }
  elsif ( $visual == 2 && $FORM{PORT}) {
    $Equipment->{TYPE_SEL} = $html->form_select(
      'TYPE_ID',
      {
        SELECTED => $Equipment->{TYPE_ID},
        SEL_LIST => [ { id => 0, name => $lang{USER} }, { id => 1, name => 'UPLINK' } ],
        NO_ID    => 1,
      }
    );

    $Equipment->{STATUS_SEL} = $html->form_select(
      'STATUS',
      {
        SELECTED => $FORM{STATUS} || 0,
        SEL_HASH => {
          0 => $lang{ENABLE},
          1 => $lang{DISABLE},
          2 => $lang{NOT_ACTIVE},
          3 => $lang{ERROR},
        },
        NO_ID    => 1,
        STYLE    => \@service_status_colors,
      }
    );
    $Equipment->{UPLINK_SEL} = $html->form_select(
      'UPLINK',
      {
        SELECTED    => $Equipment->{UPLINK} || '',
        SEL_LIST    => $Equipment->_list( {
          %LIST_PARAMS,
          NAS_ID    => '_SHOW',
          NAS_NAME  => '_SHOW',
          SHORT     => 1,
          PAGE_ROWS => 9999,
          COLS_NAME => 1 } ),
        SEL_KEY     => 'nas_id',
        SEL_VALUE   => 'nas_name',
        SEL_OPTIONS => { '' => '--' },
      }
    );

    $Equipment->{VLAN_SEL} = $html->form_select(
      'VLAN',
      {
        SELECTED    => $Equipment->{VLAN} || $FORM{VLAN} || '',
        SEL_LIST    => $Equipment->vlan_list( { %LIST_PARAMS, NAME => '_SHOW', SHORT => 1, PAGE_ROWS => 9999, COLS_NAME => 1 } ),
        SEL_KEY     => 'id',
        SEL_VALUE   => 'name',
        NO_ID       => 1,
        SEL_OPTIONS => { '' => '--' },
      }
    );

    $Equipment->{ROWS_COUNT} = 1 if (! $Equipment->{ROWS_COUNT});
    $Equipment->{BLOCK_SIZE} = 4 if (! $Equipment->{BLOCK_SIZE});

    $html->tpl_show( _include( 'equipment_port', 'Equipment' ), { %{$Equipment}, %FORM } );
  }
#  equipment_ports_full( $attr );
  return 1;
}

#********************************************************
=head2 equipment_ports_select($attr)

  Aargumnets:
    $attr
      NAS_INFO
      USED_PORTS

  Results:

=cut
#********************************************************
sub equipment_ports_select {
#  my ($attr) = @_;

  my $nas_id = $Equipment->{NAS_ID} || $FORM{NAS_ID} || do {
    $html->message('err', $lang{ERROR}, "NO \$FORM{NAS_ID}");
    return 0;
  };

  $used_ports = equipments_get_used_ports({NAS_ID => $nas_id});
  $Equipment->_info($nas_id);
  $Equipment->model_info( $Equipment->{MODEL_ID} );
  
  my $ports = $Equipment->{PORTS} || 0;

  if ( $FORM{SELECT} ){
    print $html->element('div', equipment_port_panel( $Equipment ), { class => 'modal-body' });
    return 1;
  }

  my $table = $html->table({
    width    => '500',
    caption  => $lang{PORTS},
    rowcolor => 'odd',
    class    => 'form'
  });

  my @cols = ();
  for ( my $i = 1; $i <= $ports; $i++ ){
    if ( $#cols > 6 ){
      $table->addtd( @cols );
      @cols = ();
    }

    my $tdcolor = 'white';
    my $ui = '';

    if ( $used_ports->{$i} ){
      $tdcolor = '#00FF00';
      foreach my $uinfo ( @{ $used_ports->{$i} } ){
        my ($uid, $login) = split( /:/, $uinfo );
        next if ($uid =~ /^sw:/);
        $ui .= user_ext_menu( $uid, $login, { SHOW_LOGIN => 1 } );
      }
    }
    else{
      push(
        @cols,
        $table->td(
          $html->element(
            'div',
            $html->button( "$i", "index=$index&NAS_ID=$FORM{NAS_ID}&PORT_ID=$i", { BUTTON => 1 } ),
            {
              class => 'clickSearchResult',
              value => $i.'----'
            }
          )
            . $html->br()
            . $ui,
          { align => 'center', bgcolor => $tdcolor }
        )
      );
    }
  }

  $table->addtd( @cols );
  print $table->show();

  return 1;
}

#********************************************************
=head2 equipments_get_used_ports() - Get user info by Dhcphosts NAS, Dv MAC

   Arguments:
     $attr
       NAS_ID      - NAS id
       GET_MAC     - Add MAC identifier to user hash
       GET_NAS_MAC - Get NAS MAC
       FULL_LIST   - Add full list
       PORTS_ONLY  - Get only ports
       COLS_UPPER  - Upper Cols
       DEBUG       - Debug mode

   Results:
     Hash_ref

=cut
#********************************************************
sub equipments_get_used_ports{
  my ($attr) = @_;

  my %used_ports = ();
  my $list;

  if(in_array('Internet', \@MODULES)) {
    require Internet;
    Internet->import();
    my $Internet = Internet->new($db, $admin, \%conf);

#    require Internet::Sessions;
#    Internet::Sessions->import();
#    my $Sessions = Internet::Sessions->new($db, $admin, \%conf);

    if ($attr->{DEBUG} && $attr->{DEBUG} > 6) {
      $Internet->{debug} = 1;
#      $Sessions->{debug} = 1;
    }
    $LIST_PARAMS{GROUP_BY}=' internet.id';

    $list = $Internet->list({
      %LIST_PARAMS,
      LOGIN           => '_SHOW',
      FIO             => '_SHOW',
      ADDRESS_FULL    => '_SHOW',
      CID             => '_SHOW',
      PORT            => '_SHOW',
      ONLINE          => '_SHOW',
      ONLINE_IP       => '_SHOW',
      ONLINE_CID      => '_SHOW',
      TP_NAME         => '_SHOW',
      IP              => '_SHOW',
      LOGIN_STATUS    => '_SHOW',
      INTERNET_STATUS => '_SHOW',
      NAS_ID          => $attr->{NAS_ID},
      COLS_UPPER      => $attr->{COLS_UPPER},
      COLS_NAME       => 1,
      PAGE_ROWS       => 1000000
    });

    foreach my $line (@{$list}) {

      if(! $attr->{PORTS_ONLY}) {
        if ($line->{online_cid}) {
          push @{ $used_ports{ $line->{cid} } }, $line;
        }
        elsif ($line->{cid} && $line->{cid} !~ /any/ig) {
          push @{ $used_ports{ $line->{cid} } }, $line;
        }

        if ($line->{cpe_mac}) {
          push @{ $used_ports{ $line->{cpe_mac} } }, $line;
        }
      }

      if ($attr->{NAS_ID}) {
        push @{ $used_ports{ $line->{port} } }, $line;
      }
    }

#    if ($attr->{PORTS_ONLY}) {
#      return \%used_ports;
#    }

    #Online
#    $list = $Sessions->online({
#      %LIST_PARAMS,
#      CLIENT_IP    => '_SHOW',
#      LOGIN        => '_SHOW',
#      CID          => '_SHOW',
#      UID          => '_SHOW',
#      ADDRESS_FULL => '_SHOW',
#      DURATION     => '_SHOW',
#      SWITCH_PORT  => '_SHOW',
#      COLS_UPPER   => $attr->{COLS_UPPER},
#    });

#    if($list && ref $list eq 'ARRAY') {
#      foreach my $line (@{$list}) {
#        if ($attr->{NAS_ID}) {
#          push @{ $used_ports{ $line->{switch_port} } }, $line;
#        }
#        elsif ($line->{cid} && !$used_ports{ lc($line->{cid}) }) {
#          push @{ $used_ports{ lc($line->{cid}) } }, $line;
#        }
#      }
#    }
  }
  else {
    require Dv;
    Dv->import();
    my $Dv = Dv->new($db, $admin, \%conf);

    require Dv_Sessions;
    Dv_Sessions->import();
    my $Dv_Sessions = Dv_Sessions->new($db, $admin, \%conf);
    my $Dhcphosts;
    if ( in_array( 'Dhcphosts', \@MODULES ) ){
      require Dhcphosts;
      Dhcphosts->import();
      $Dhcphosts = Dhcphosts->new( $db, $admin, \%conf );
    }

    if ($attr->{DEBUG} && $attr->{DEBUG} > 6) {
      $Dhcphosts->{debug} = 1;
      $Dv_Sessions->{debug} = 1;
      $Dv->{debug} = 1;
    }

    if (in_array('Dhcphosts', \@MODULES)) {
      $list = $Dhcphosts->hosts_list({
        %LIST_PARAMS,
        NAS_ID       => $attr->{NAS_ID},
        ADDRESS_FULL => '_SHOW',
        PORTS        => '_SHOW',
        LOGIN        => '_SHOW',
        MAC          => '_SHOW',
        COLS_NAME    => 1,
        COLS_UPPER   => $attr->{COLS_UPPER},
        PAGE_ROWS    => 100000
      });

      foreach my $line (@{$list}) {
        if ($attr->{FULL_LIST}) {
          if ($attr->{GET_MAC}) {
            $used_ports{ lc($line->{mac}) } = $line;
          }
          else {
            push @{ $used_ports{ $line->{ports} } }, $line;
          }
        }
        else {
          #push @{ $used_ports{ $line->{ports} } }, ($line->{uid} || 0) . ':' . ($line->{login} || '');
          push @{ $used_ports{ $line->{ports} } }, $line;
          if ($attr->{GET_MAC}) {
            #$used_ports{ lc($line->{mac}) } = ($line->{uid} || 0) . ':' . ($line->{login} || '');
            $used_ports{ lc($line->{mac}) } = $line;
          }
        }
      }
    }

    if ($attr->{PORTS_ONLY}) {
      return \%used_ports;
    }

    $list = $Dv->list({
      #PORTS     => '_SHOW',
      LOGIN        => '_SHOW',
      FIO          => '_SHOW',
      ADDRESS_FULL => '_SHOW',
      CID          => '_SHOW',
      COLS_NAME    => 1,
      PAGE_ROWS    => 100000
    });

    foreach my $line (@{$list}) {
      next if (!$line->{cid});
      next if ($line->{cid} =~ /any/ig);

      if ($attr->{FULL_LIST}) {
        if ($attr->{GET_MAC}) {
          $used_ports{ $line->{cid} } = $line;
        }
        else {
          push @{ $used_ports{ $line->{cid} } }, $line;
        }
      }
      else {
        $used_ports{ lc($line->{cid}) } = "$line->{uid}:$line->{login}";
      }
    }

    #Online
    $list = $Dv_Sessions->online({
      CID          => '_SHOW',
      UID          => '_SHOW',
      LOGIN        => '_SHOW',
      ADDRESS_FULL => '_SHOW',
      DURATION     => '_SHOW',
    });

    foreach my $line (@{$list}) {
      if ($line->{CID} && !$used_ports{ lc($line->{CID}) }) {
        push @{ $used_ports{ lc($line->{CID}) } }, $line;
      }
    }
  }
  if ($attr->{PORTS_ONLY} && !$attr->{FULL_LIST}) {
    my $port_list = $Equipment->port_list({
      NAS_ID     => $attr->{NAS_ID},
      UPLINK     => '_SHOW',
      PAGE_ROWS  => 1000,
      COLS_NAME  => 1
    });
    foreach my $line ( @{$port_list} ) {
      if ($line->{uplink}) {
        push @{ $used_ports{ $line->{port} } }, $line;
      }
    }
    return \%used_ports;
  }
  my $Equipment_ = Equipment->new( $db, \%conf, $admin );
  my $equipment_list = $Equipment_->_list( {
    NAS_ID          => '_SHOW',
    MAC             => '_SHOW',
    NAS_NAME        => '_SHOW',
    NAS_IP          => '_SHOW',
    STATUS          => '_SHOW',
    DISABLE         => '_SHOW',
    VENDOR_NAME     => '_SHOW',
    MODEL_NAME      => '_SHOW',
    TYPE_NAME       => '_SHOW',
    COLS_NAME       => 1,
    PAGE_ROWS       => 100000,
  } );

  my $Nas = Nas->new( $db, \%conf, $admin );
  my $nas_list = $Nas->list({
    NAS_ID    => '_SHOW',
    MAC       => '_SHOW',
    NAS_NAME  => '_SHOW',
    NAS_IP    => '_SHOW',
    NAS_TYPE  => '_SHOW',
    DISABLE   => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 100000
  });
  my %ids = ();

  @{$list} = (@{$equipment_list}, @{$nas_list});

  foreach my $line ( @{$list} ) {
    if (!$ids{ $line->{nas_id} }) {
      if ($attr->{FULL_LIST}) {
        if ( $attr->{GET_MAC} ) {
         #        $used_ports{ $line->{mac} } = $line;
        }
        elsif ( $attr->{PORTS_ONLY} ) {
          push @{ $used_ports{ 'sw:' . $line->{nas_id} } }, $line;
        }
        else {
          my $mac = ($line->{mac}) ? lc( $line->{mac} ) : q{};
          push @{ $used_ports{ $mac } }, $line;
        }
      }
      else {
        my $mac = ($line->{mac}) ? lc( $line->{mac} ) : q{};
        $used_ports{ $mac }  = "sw:$line->{id}:". ($line->{nas_name} || q{});
      }
    }
    $ids{ $line->{nas_id} } = 1;
  }

  return \%used_ports;
}

#********************************************************
=head2 equipment_port_panel($attr) - forms HTML representation of equipments panel

  Arguments:
    $Equipment - hash
      PORT_COUNT          - count of ports
      BLOCK_SIZE          - number representing quantity of ports in a group
      ROWS_COUNT          - number of rows on panel
      PORT_NUMBERING      - (boolean) numbering by rows or by column
      FIRST_PORT_POSITION - (boolean) first port is on upper or bottom row;
      USED_PORTS          - (array) array representing numbers of used ports
      ID                  - ID of model

      SEARCH_RESULT       - (hash_ref) used for modal search (will be passed to js:fillSearchResults() )
        1 => '1'         - will set ${search_popup_name} input value to 1 (hidden ${search_popup_name} + '1' too)
        2 => 'PORT::2#@#VLAN::4#@#SERVER_VLAN::4' - same as prev, but allows multiple inputs

  Returns:
    HTML div


=cut
#********************************************************
sub equipment_port_panel{
  my ($attr) = @_;

  #This is used to display extra ports on form
  my $extra_ports_rows = { };

  my $port_count = $attr->{PORTS} || 4;
  my $block_size = $attr->{BLOCK_SIZE} || 1;
  my $rows_count = $attr->{ROWS_COUNT} || 1;
  my $port_type = $attr->{PORTS_TYPE} || 1;

  # Get port info
  my $port_list = $Equipment->port_list({
    NAS_ID    => $attr->{NAS_ID},
    VLAN      => '_SHOW',
    COLS_NAME => 1
  });

  #  $Equipment->{SEARCH_RESULT} = {
  #    1 => 'PORTS::1;VLAN::5;SERVER_VLAN::5',
  #    2 => 'PORTS::2;VLAN::15;SERVER_VLAN::5'
  #  };
  my $ports_name = (in_array('Internet', \@MODULES)) ? 'PORT' : 'PORTS';
  my $vlan_name = (in_array('Internet', \@MODULES)) ? 'VLAN' : 'VID';
  my $server_vlan_name = (in_array('Internet', \@MODULES)) ? 'SERVER_VLAN' : 'SERVER_VID';

  foreach my $line (@$port_list) {
    next if(! $line->{port});

    $Equipment->{SEARCH_RESULT}{$line->{port}}
      = $ports_name . "::" . ($line->{port} || q{})
      . '#@#' . $vlan_name . "::" . ($line->{vlan} || '')
      . '#@#' . $server_vlan_name . "::" . ($Equipment->{SERVER_VLAN} || '')
  }

  my $port_numbered_by_rows = $attr->{PORT_NUMBERING};
  my $first_port_position = $attr->{FIRST_POSITION};

  # For modal search
  my $search_result = $attr->{SEARCH_RESULT} || {};

  my $extra_ports = $Equipment->extra_ports_list( $attr->{ID} );
  _error_show( $Equipment );

  #sort by row
  my $ports_by_row = { };
  foreach my $port ( @{$extra_ports} ){
    next if(! $port->{row});
    if ( $ports_by_row->{$port->{row}} ){
      push @{ $ports_by_row->{$port->{row}} }, $port;
    }
    else{
      $ports_by_row->{$port->{row}} = [ $port ];
    }
  }

  my $ports_in_row = $port_count / $rows_count;
  my $blocks_in_row = $ports_in_row / $block_size;

  my $number = 0;

  my $panel = "<div class='equipment-panel'>\n";
  $panel .= "<link rel='stylesheet' type='text/css' href='/styles/default_adm/css/modules/equipment.css'>";

  my @reversed_rows = ();

  for ( my $row_num = 0; $row_num < $rows_count; $row_num++ ){
    my $row = "<div class='row equipment-row'>";
    for ( my $block_num = 0; $block_num < $blocks_in_row; $block_num++ ){
      my $block = "<div class='equipment-block'>";
      if ( !$port_numbered_by_rows ){
        for ( my $port_num = 0; $port_num < $block_size; $port_num++ ){
          $number++;
          if ( $number <= $port_count ){
            my $class =  (!$used_ports->{$number})
              ? "clickSearchResult port port-$port_types[$port_type]-free"
              : "clickSearchResult port port-$port_types[$port_type]-used port-used";

            $block .= _get_html_for_port( $number, $class, $search_result->{$number});
          }
        }
      }
      else{
        for ( my $port_num = 0; $port_num < $block_size; $port_num++ ){
          $number = $row_num + ($rows_count * $port_num) + ($block_num * $block_size * $rows_count) + 1;
          if ( $number <= $port_count ){
            my $class = (!$used_ports->{$number})
              ? "clickSearchResult port port-$port_types[$port_type]-free"
              : "clickSearchResult port port-$port_types[$port_type]-used port-used";

            $block .= _get_html_for_port( $number, $class, $search_result->{$number});
          }
        }
      }
      $block .= "</div>";
      $row .= $block;
    }

    #check for extra ports
    if ( $ports_by_row->{$row_num} ){
      my @extra_ports = ();

      $row .= "<div class='equipment-block'>";
      foreach my $port ( @{ $ports_by_row->{$row_num} } ){
        my $class = ($port->{state})
          ? "port port-$port_types[$port->{port_type}]-used port-used"
          : "port port-$port_types[$port->{port_type}]-free";

        $row .= _get_html_for_port( 'e' . $port->{port_number}, $class, $search_result->{$port->{port_number}} );

        push( @extra_ports, qq{ "$port->{port_number}" : $port->{port_type} } );
      }
      $row .= "</div>";

      $extra_ports_rows->{$row_num} = join( ", ", @extra_ports );
    }
    #    if ($row_num == 0) {
    #      if (($extra_port1 != 0) || ($extra_port2 != 0)) {
    #        $row .= "<div class='equipment-block'>";
    #        $row .=
    #        ($extra_port1)
    #        ? _get_port('e1', "port port-$port_types[$extra_port1]-free")
    #        : _get_port('',   "port");
    #        $row .=
    #        ($extra_port2)
    #        ? _get_port('e2', "port port-$port_types[$extra_port2]-free")
    #        : _get_port('',   "port");
    #        $row .= "</div>";
    #      }
    #    }
    #    if ($row_num == 1 || $rows_count == 1) {
    #      if (($extra_port3 != 0) || ($extra_port4 != 0)) {
    #        $row .= "<div class='equipment-block'>";
    #        $row .=
    #        ($extra_port3)
    #        ? _get_port('e3', "port port-$port_types[$extra_port3]-free")
    #        : _get_port('',   "port");
    #        $row .=
    #        ($extra_port4)
    #        ? _get_port('e4', "port port-$port_types[$extra_port4]-free")
    #        : _get_port('',   "port");
    #        $row .= "</div>";
    #      }
    #    }

    $row .= "</div>";

    if ( $first_port_position ){
      push( @reversed_rows, $row );
    }
    else{
      $panel .= $row;
    }
  }

  if ( $first_port_position ){
    #down
    my @rows = reverse @reversed_rows;
    $panel .= join( '', @rows );
  }

  $panel .= "</div>";

  #form extra_ports_json string
  my $extra_ports_json = "<input type='hidden' id='extraPortsJson' value='{ ";
  my @rows_json = ();
  foreach my $row_number ( sort keys %{$extra_ports_rows} ){
    push ( @rows_json, qq{ "$row_number" : { $extra_ports_rows->{$row_number} } } );
  }

  $extra_ports_json .= join( ", ", @rows_json );
  $extra_ports_json .= " }' >";

  $panel .= $extra_ports_json;

  return $panel;
}


#********************************************************
=head2 _get_html_for_port($number_, $class_)

=cut
#********************************************************
sub _get_html_for_port{
  my ($number, $class, $data_value) = @_;

  $data_value ||= $number;

  return $html->element(
    'div',
    $html->b( $number ),
    {
      class => $class,
      value => $data_value
    }
  );
}

#**********************************************************
=head2 equipment_port_info($attr)

  Arguments:

    $attr
      NAS_ID
      PORT_ID
      PORT_SHIFT
      EQUIPMENT_INFOS

  Returns:

    $information_table

=cut
#**********************************************************
sub equipment_port_info {
  my($attr) = @_;

  my $info = $attr->{EQUIPMENT_INFOS};

  if(! $attr->{PORT}) {
    return $info;
  }

  if($attr->{PORT_SHIFT}) {
    $attr->{PORT}+=$attr->{PORT_SHIFT}
  }

  my $info_fields = 'PORT_STATUS,PORT_IN,PORT_OUT,PORT_IN_ERR,PORT_OUT_ERR,DISTANCE';

  if($FORM{PORT_STATUS}) {
    $html->message('info', $lang{INFO}, "Port status");
    $attr->{PORT_STATUS}="$attr->{PORT}:$FORM{PORT_STATUS}";
  }

  my $test_result = equipment_test({
    %{ ($attr) ? $attr : {} },
    PORT_INFO => $info_fields,
    PORT_ID   => $attr->{PORT},
    TEST_DISTANCE => $attr->{TEST_DISTANCE}
  });

  if(ref $test_result ne 'HASH') {
    return $info;
  }

  push @$info, @{ port_result_former($test_result, {
        PORT        => $attr->{PORT},
        INFO_FIELDS => $info_fields
      }) };

  return $info;
}

#**********************************************************
=head2 port_result_former($port_info)

  Arguments:

    $port_info
    $attr
      PORT
      INFO_FIELDS
      EXTRA_INFO

  Returns:

    $information_table

=cut
#**********************************************************
sub port_result_former {
  my($port_info, $attr) = @_;
  $html->tpl_show( _include( 'equipment_icons', 'Equipment' ));

  my @info        = ();
  my @info_fields = '';
  my @skip_params = ('PORT_OUT', 'PORT_OUT_ERR', 'ONU_OUT_BYTE', 'ONU_TX_POWER', 'OLT_RX_POWER', 'ETH_ADMIN_STATE', 'ETH_DUPLEX', 'ETH_SPEED', 'VLAN');
  my $port_id     = $attr->{PORT};

  if($attr->{INFO_FIELDS}) {
    @info_fields = split(/,/, $attr->{INFO_FIELDS});
  }
  else {
    @info_fields = sort keys %{ $port_info->{$port_id} };
  }

  foreach my $key (@info_fields) {
    next if(! defined($port_info->{$port_id}->{$key}));

    my $value = $port_info->{$port_id}->{$key};
    if(in_array($key, \@skip_params)) {
      next;
    }
    elsif($key eq 'PORT_STATUS') {
      $key   = "$lang{PORT} $lang{STATUS}";
      $value = $html->color_mark( $ports_state[ $value ],
        $ports_state_color[ $value ] );

      if($permissions{0}{22}) {
        $FORM{chg} //= q{};
        $value .= $html->button($lang{DISABLE}, "index=$index&UID=$FORM{UID}&chg=$FORM{chg}&PORT_STATUS=1",
          { ICON => 'glyphicon glyphicon-off' }
        );
      }
    }
    elsif($key eq 'ONU_IN_BYTE') {
      $key = $lang{TRAFFIC};
      $value = $lang{RECV} .': '.int2byte($value)
        . $html->br()
        . $lang{SENDED} .': '. int2byte($port_info->{$port_id}->{ONU_OUT_BYTE});
    }
    elsif($key eq 'PORT_IN') {
      $key = $lang{TRAFFIC};
      $value = $lang{RECV} .': '.int2byte($value)
        . $html->br()
        . $lang{SENDED} .': '. int2byte($port_info->{$port_id}->{PORT_OUT});
    }
    elsif ( $key eq 'ONU_RX_POWER' ){
      $key = $lang{POWER} || q{POWER};
      if($port_info->{$port_id}->{ONU_RX_POWER}) {
        $value = 'ONU_RX_POWER: ' .  pon_tx_alerts( $value );
      }
      if($port_info->{$port_id}->{ONU_TX_POWER}) {
        $value .= 'ONU_TX_POWER: '. pon_tx_alerts($port_info->{$port_id}->{ONU_TX_POWER});
      }
      if($port_info->{$port_id}->{OLT_RX_POWER}) {
        $value .= 'OLT_RX_POWER: '. pon_tx_alerts( $port_info->{$port_id}->{OLT_RX_POWER} );
      }
    }
    elsif($key eq 'ONU_PORTS_STATUS') {
      $key = "$lang{PORTS}:";
      my @ports_status = split(/\n/, $value);
      $value = q{};
      foreach my $line (@ports_status) {
        my ($port, $status)=split(/ /, $line);
        my $color       = q{};
        my $describe    = "State: Down ".$html->br();
        my $speed       = $port_info->{$port_id}->{ETH_SPEED}->{$port} || '';
        my $duplex      = $port_info->{$port_id}->{ETH_DUPLEX}->{$port} || '';
        my $admin_state = $port_info->{$port_id}->{ETH_ADMIN_STATE}->{$port} || '';
        my $vlan        = ($port_info->{$port_id}->{VLAN} && ref $port_info->{$port_id}->{VLAN} eq 'HASH' ) ? $port_info->{$port_id}->{VLAN}->{$port} : '';

#$admin_state = "Disble" if ($port  eq '5');
#$speed = '1Gb/s' if ($port eq '2');
#$speed = '10Gb/s' if ($port eq '3');
#$speed = '10Mb/s' if ($port eq '4');
#$status = 1 if ($port eq '3' || $port eq '4');
#$speed = '' if ($port eq '6' || $port eq '8');
#$admin_state = '' if ($port  eq '7' || $port eq '8');
#$duplex = 'Full';
        if ($status == 1) {
          $color   = 'text-green';
          $describe = "State: Up ".$html->br();
        }

        $describe .= "Speed: $speed ".$html->br() if ($speed);
        $describe .= "Duplex: $duplex ".$html->br() if ($duplex);
        $describe .= "Native Vlan : $vlan ".$html->br() if ($vlan);

        my $btn = q{};
        if ($admin_state) {
          my $describe_state = ($admin_state eq 'Enable') ? 'shutdown' : 'undo shutdown';
          my $badge_type = ($admin_state eq 'Enable') ? 'up' : 'down';
          $color = ($admin_state eq 'Enable') ? $color : 'text-red';
          my $badge = $html->element('span', '', { class => 'fa fa-power-off', 'data-tooltip' => $describe_state, 'data-tooltip-position' => 'top'});
          $btn .= $html->element('span', $badge, { class => 'badge badge-' . $badge_type });
        }
        $btn .= $html->element('span', '', { class => 'icon icon-eth ' . $color });
        $btn .= $html->element('span', $port, { class => 'port-num' });

        if ($speed) {
          my $color_bb = q{};
          if ($speed =~ /^\d+Gb\/s/ && $status == 1){
            $color_bb = 'text-green';
          } 
          elsif ($speed =~ /^\d+Mb\/s/ && $status == 1){
            $color_bb = 'text-yellow';
          }
          $btn .= $html->element('span', $speed, {class => 'badge-bottom ' . $color_bb }) if ($speed);
        }
        $value .= $html->element('span', $btn, {class => 'btn-ethernet', 'data-tooltip' => $describe, 'data-tooltip-position' => 'bottom'});
      }

      $value .= $html->br() . "&emsp;";

      my $help_ = q{};
      $help_ = $html->element('span', '', { class => 'fa fa-square text-dark-gray' }) . ' - Down &emsp;';
      $value .= $html->element('span', $help_, {'data-tooltip' => 'Port is Down', 'data-tooltip-position' => 'bottom'});

      $help_ = $html->element('span', '', { class => 'fa fa-square text-green' }) . ' - Up &emsp;';
      $value .= $html->element('span', $help_, {'data-tooltip' => 'Port is Up', 'data-tooltip-position' => 'bottom'});

      if (scalar keys %{ $port_info->{$port_id}->{ETH_ADMIN_STATE} }) {
        $help_ = $html->element('span', '', { class => 'fa fa-square text-red' }) . ' - Shutdown &emsp;';
        $value .= $html->element('span', $help_, {'data-tooltip' => 'Admin state shutdown', 'data-tooltip-position' => 'bottom'});
      }

    }
    elsif($key eq 'DISTANCE') {
      $value = ($FORM{TEST_DISTANCE}) ? $port_info->{$port_id}->{DISTANCE}
                                      : $html->button($lang{TEST}, "index=$index&UID=". ($FORM{UID} || q{})."&chg=". ($FORM{chg} || $FORM{ID} || q{}) ."&TEST_DISTANCE=1",
          { class => 'btn btn-default', title => $lang{DISTANCE} });
      $value  = $port_info->{$port_id}->{DISTANCE};
    }
    elsif($key eq 'PORT_IN_ERR') {
      $key = $lang{ERROR};
      $value = $html->color_mark(($port_info->{$port_id}->{PORT_IN_ERR} || 0)
          . '/'
          . ($port_info->{$port_id}->{PORT_OUT_ERR} || 0),
          ( ($port_info->{$port_id}->{PORT_OUT_ERR} || 0) + ($port_info->{$port_id}->{PORT_IN_ERR} || 0) > 0 ) ? 'text-danger' : undef );
    }
    elsif($key eq 'TEMPERATURE') {
      $value = $port_info->{$port_id}->{TEMPERATURE} . " &deg;C"; 
    }
    $key = ($lang{$key}) ? $lang{$key} : $key;
    push @info, [ $key, $value ];
  }

  return \@info;
}


1;
