=head2 NAME

  Internet::Monitoring

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(mk_unique_value int2ip int2byte cmd);

my $chart_height           = 350;
my $chart_new_window_width = 450;

my $new_window_size = ($chart_new_window_width * 1.2) . ":" . ($chart_height * 1.35);

our(
  $db,
  %conf,
  $admin,
  $html,
  %lang,
  @bool_vals,
  @state_colors,
  %permissions
);

my $Sessions = Internet::Sessions->new($db, $admin, \%conf);
my $Nas      = Nas->new($db, \%conf, $admin);

#**********************************************************
=head2 internet_online() - Show online sessions

=cut
#**********************************************************
sub internet_online {

  $Sessions->{debug}=1 if ($FORM{DEBUG} && $FORM{DEBUG} > 5);

  my $message;
  if ($FORM{ping}) {
    if ($FORM{ping} eq '0.0.0.0' && $FORM{SESSION_ID}) {
      $Sessions->online_info( { ACCT_SESSION_ID  => $FORM{SESSION_ID}, NAS_ID => $FORM{NAS_ID} });
      $FORM{ping} = $Sessions->{FRAMED_IP_ADDRESS};
    }

    host_diagnostic($FORM{ping});
  }
  elsif($FORM{mac_info}) {
    my $result = get_oui_info($FORM{mac_info});
    $html->message('info', $lang{INFO}, "MAC: $FORM{mac_info}\n $result");
  }
  elsif ($FORM{hangup}) {
    my ($nas_id, $nas_port_id, $acct_session_id, $user_name) = split(/ |\+/, $FORM{hangup}, 4);

    $Nas->info({ NAS_ID => $nas_id });

    if (_error_show($Nas)) {
      return 0;
    }

    $Sessions->online_info( { ACCT_SESSION_ID  => $acct_session_id, NAS_ID => $nas_id });

    _error_show($Sessions);

    require Abills::Nas::Control;
    Abills::Nas::Control->import();

    my $Nas_cmd = Abills::Nas::Control->new($db, \%conf);
    my $ret = $Nas_cmd->hangup(
      $Nas,
      $nas_port_id || 0,
      $user_name || '',
      {
        DEBUG                => $FORM{DEBUG} || undef,
        ACCT_TERMINATE_CAUSE => 6,
        SESSION_ID           => $acct_session_id,
        %$Sessions,
        INTERNET             => 1
      }
    );

    if ($ret == 0) {
      $message = "$lang{NAS} ID: $nas_id\n $lang{NAS} IP: $Nas->{NAS_IP}\n $lang{PORT}: $nas_port_id\n SESSION_ID: $acct_session_id\n\n Return: $ret";
      sleep 3;
      $admin->{MODULE}='Internet';
      $admin->action_add($FORM{UID}, $user_name, { MODULE => 'Internet', TYPE => 15 });
    }
    elsif ($ret == 1) {
      $message = "$Nas->{NAS_TYPE} NAS NOT supported yet";
    }

    $html->message('info', $lang{INFO}, "$message $ret");
  }
  elsif ($FORM{diagnostic}) {
    internet_diagnostic($FORM{diagnostic});
  }
  elsif ($FORM{zapall}) {
    $Sessions->zap(0, 0, 0, { ALL => 1, %FORM });
    $html->message('info', $lang{INFO}, "Zapped all sessions");
  }
  elsif ($FORM{zap}) {
    my ($uid, $nas_id, $nas_port_id, $acct_session_id) = split(/ /, $FORM{zap}, 4);
    $Sessions->zap($nas_id, $nas_port_id, $acct_session_id, \%FORM);

    if (_error_show($Sessions)) {
      return 0;
    }

    $Nas->info({ NAS_ID => $nas_id });
    $message = "\n$lang{NAS} ID: $nas_id\n $lang{NAS} IP: ". ($Nas->{NAS_IP} || q{}) ."\n $lang{PORT}: $nas_port_id\n SESSION_ID: $acct_session_id\n\n";
    my ($Y, $M, undef) = split(/-/, $DATE, 3);
    $Sessions->list({
      UID             => $uid,
      DATE            => ">=$Y-$M-01",
      ACCT_SESSION_ID => $acct_session_id,
      NAS_PORT        => $nas_port_id,
      NAS_ID          => $nas_id,
      PAGE_ROWS       => 1
    });

    if ($Sessions->{TOTAL} < 1) {
      $message .= $html->button('ADD_TO_LOG', "index=$index&tolog=$acct_session_id&nas_id=$nas_id&nas_port_id=$nas_port_id&ZAPED=1", { BUTTON => 2 })
        . ' ' . $html->button($lang{DEL}, "index=$index&del=$acct_session_id&nas_id=$nas_id&nas_port_id=$nas_port_id&ZAPED=1", { BUTTON => 2 });
    }
    else {
      $message .= $lang{EXIST};
      $Sessions->online_del(
        {
          NAS_ID          => $nas_id,
          NAS_PORT        => $nas_port_id,
          ACCT_SESSION_ID => $acct_session_id
        }
      );
    }

    $html->message('info', $lang{INFO}, $message);
  }
  elsif ($FORM{tolog}) {
    $FORM{IDS}=~s/\s+//g if ($FORM{IDS});
    my $Acct;
    if(in_array('Internet', \@MODULES)) {
      require Acct2;
      Acct2->import();
      $Acct = Acct2->new($db, \%conf);
    }
    else {
      require Acct;
      Acct->import();
      $Acct = Acct->new($db, \%conf);
    }

    $Sessions->online({
      ACCT_SESSION_ID   => '_SHOW',
      ACCT_SESSION_ID   => $FORM{IDS} || $FORM{tolog},
      ZAPED             => 1,
      ACCT_INPUT_OCTETS => '_SHOW',
      ACCT_OUTPUT_OCTETS=> '_SHOW',
      EX_INPUT_OCTETS   => '_SHOW',
      EX_OUTPUT_OCTETS  => '_SHOW',
      ACCT_SESSION_TIME => '_SHOW',
      NAS_PORT_ID       => $FORM{nas_port_id} || '_SHOW',
      NAS_IP            => '_SHOW',
      CLIENT_IP         => '_SHOW',
      CONNECT_INFO      => '_SHOW',
      CID               => '_SHOW',
      USER_NAME         => '_SHOW',
      SESSION_START     => '_SHOW',
      NAS_ID            => $FORM{nas_id},
    });

    my $online_list = $Sessions->{nas_sorted};
    my $nas_list    = $Nas->list({
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      DOMAIN_ID  => ($admin->{DOMAIN_ID}) ? $admin->{DOMAIN_ID} : undef
    });

    my @results     = ();
    my @added       = ();
    my $ACCT_INFO;

    foreach my $nas_row (@$nas_list) {
      next if (!defined($online_list->{ $nas_row->{NAS_ID} }));
      foreach my $line (@{ $online_list->{ $nas_row->{NAS_ID} } }) {
        push @added, $line->{acct_session_id};

        $ACCT_INFO->{INBYTE}               = $line->{acct_input_octets};
        $ACCT_INFO->{OUTBYTE}              = $line->{acct_output_octets};
        $ACCT_INFO->{INBYTE2}              = $line->{ex_input_octets};
        $ACCT_INFO->{OUTBYTE2}             = $line->{ex_output_octets};
        $ACCT_INFO->{'Acct-Session-Time'}  = $line->{acct_session_time};
        $ACCT_INFO->{'Acct-Session-Id'}    = $line->{acct_session_id};
        $ACCT_INFO->{'NAS-Port'}           = $line->{nas_port_id};
        $ACCT_INFO->{'Nas-IP-Address'}     = $nas_row->{nas_ip};
        $ACCT_INFO->{'Framed-IP-Address'}  = $line->{client_ip};
        $ACCT_INFO->{'Connect-Info'}       = $line->{connect_info};
        $ACCT_INFO->{'Calling-Station-Id'} = $line->{calling_station_id} || $line->{CID};
        $ACCT_INFO->{'User-Name'}          = $line->{user_name};
        $ACCT_INFO->{SESSION_START}        = $line->{session_start};
        $ACCT_INFO->{'Acct-Terminate-Cause'} = 3;
        $ACCT_INFO->{'Acct-Status-Type'}     = 'Stop';

        $Acct->accounting($ACCT_INFO, $nas_row);

        push @results, "$ACCT_INFO->{'User-Name'} ($line->{acct_session_id}) ". (($Acct->{errno}) ? $lang{ERROR} : $lang{ADDED});
      }
    }

    $html->message('info', $lang{REPORTS}, join($html->br(), @results));
    $Sessions->online_del({ SESSIONS_LIST => \@added });
  }
  elsif ($FORM{del}) {
    if ($FORM{IDS}) {
      my @sessions_list = split(/, /, $FORM{IDS});
      $Sessions->online_del({ SESSIONS_LIST => \@sessions_list });
      $FORM{del} = $FORM{IDS};
    }
    else {
      $Sessions->online_del(
        {
          NAS_ID          => $FORM{nas_id},
          NAS_PORT        => $FORM{nas_port_id},
          ACCT_SESSION_ID => $FORM{del}
        }
      );
    }

    if (!_error_show($Sessions)) {
      $message = "$lang{NAS}: ". ($FORM{nas_id} || '') ."\n"
        . "$lang{PORT}: ". ($FORM{nas_port_id} || '') ." \n"
        . "ACCT_SESSION_ID:  ". ($FORM{del} || '');

      $html->message('info', $lang{DELETED}, $message);
    }
  }
  elsif($FORM{search}) {
    foreach my $key ( keys %FORM ) {
      $LIST_PARAMS{$key}=$FORM{$key};
    }
    $LIST_PARAMS{ALL}=1;
    delete $LIST_PARAMS{DOMAIN_ID};
    $LIST_PARAMS{SKIP_DOMAIN}=1;
  }

  my $service_status = sel_status({ HASH_RESULT => 1 });

  # online count
  my $list     = $Sessions->online_count({ %LIST_PARAMS, COLS_NAME => 1 });

  my $nas_list = $Nas->list({ COLS_NAME => 1, PAGE_ROWS => 50000 });

  my $cure = '';
  if ($FORM{ZAPED}) {
    $LIST_PARAMS{ZAPED} = 1;
    $LIST_PARAMS{ACCT_SESSION_ID} = '_SHOW' if (! $LIST_PARAMS{ACCT_SESSION_ID});
    $cure = 'Zap';
    $pages_qs .= "&ZAPED=1";
  }
  else {
    $Sessions->{ZAPED} = 0 if (!$Sessions->{ZAPED});
    $cure = 'Online';
  }

  $html->short_info_panels_row(
    [
      {
        ID     => mk_unique_value(10),
        NUMBER => $Sessions->{ONLINE} || ' 0',
        NUMBER_SIZE => '40px',
        ICON   => 'plane',
        TEXT   => $html->button("Online", "index=$index"),
        COLOR  => 'green',
        SIZE   => 3
      },
      {
        ID          => mk_unique_value( 10 ),
        NUMBER      => $Sessions->{ZAPED} || ' 0',
        NUMBER_SIZE => '40px',
        ICON        => 'remove',
        TEXT        => $html->button( "$lang{ZAPED}", "index=$index&ZAPED=1" ),
        COLOR       => 'orange',
        SIZE        => 3
      }
    ]
  );

  if($FORM{NAS_ID}) {
    $pages_qs .= "&NAS_ID=$FORM{NAS_ID}";
    $LIST_PARAMS{NAS_ID} = $FORM{NAS_ID};
  }
  elsif ($Sessions->{TOTAL} && $Sessions->{TOTAL} > 500 && ! $FORM{show_columns}){
    if(!($FORM{ZAPED} || $FORM{FILTER})) {
      print internet_online_search();
      my $table = $html->table({
        width      => '100%',
        caption    => "Online $lang{TOTAL} ($lang{NAS}: $Sessions->{TOTAL_NAS})",
        title      => [ "NAS ID", "NAS $lang{NAME}", "NAS IP", $lang{TYPE}, $lang{SESSIONS}, $lang{USERS}, "ZAPPED", $lang{ERROR}, $lang{GUEST}, "-" ],
        qs         => $pages_qs,
        ID         => 'ONLINE'
      });

      foreach my $line (@$list) {
        $table->{rowcolor} = ($FORM{NAS_ID} && $line->{nas_id} eq $FORM{NAS_ID}) ? 'row_active' : undef;
        $table->addrow($line->{nas_id}, $line->{nas_name}, $line->{nas_ip}, $line->{nas_type}, $line->{nas_total_sessions}, $line->{nas_total_users}, ($line->{nas_zaped} > 0) ? $html->button($line->{nas_zaped}, "index=$index&NAS_ID=$line->{nas_id}&ZAPED=1") : 0,
          $html->button($line->{nas_error_sessions}, "index=$index&NAS_ID=$line->{nas_id}&NAS_ERROR_SESSIONS=1"),
          $html->button($line->{guest}, "index=$index&NAS_ID=$line->{nas_id}&FILTER=1&FILTER_FIELD=GUEST"),
          $html->button($lang{SHOW}, "index=$index&NAS_ID=$line->{nas_id}", { class => 'show' }));
      }

      print $table->show();
      return 0;
    }
  }

  if ($FORM{FILTER}) {
    $LIST_PARAMS{FILTER_FIELD}=$FORM{FILTER_FIELD};
    $LIST_PARAMS{FILTER}=$FORM{FILTER};
  }

  if($FORM{NAS_ERROR_SESSIONS}) {
    $LIST_PARAMS{NAS_ERROR_SESSIONS} = $FORM{NAS_ERROR_SESSIONS};
  }

  if(-f '/usr/abills/webreports/internet_online_count.log') {
    print $html->button($html->img('/reports/internet_online_count-day.png', 'online',
      { EX_PARAMS => q{class="img-responsive" width="380" height="125"}  }),
      '', { GLOBAL_URL => '/reports/' });
  }

  my %online_status = (
    0 => "(1) $lang{START}",
    1 => "(1) $lang{START}",
    2 => '(2) Zapped',
    3 => '(3) Alive',
    5 => '(5) Error 5',
    6 => '(6) Error 6',
    9 => '(9) Renew Session',
    10=> '(10) IPN without accounting',
    11=> '(11) IP reserved'
  );

  my %EXT_TITLES = (
    'fio'                 => $lang{FIO},
    'user_name'           => "RAD User-Name",
    'login'               => $lang{LOGIN},
    'nas_port_id'         => $lang{PORT},
    'client_ip_num'       => 'IP',
    'duration_sec2'       => $lang{DURATION},
    'acct_input_octets'   => $lang{RECV},
    'acct_output_octets'  => $lang{SENT},
    'ex_input_octets'     => "Ex_IN",
    'ex_output_octets'    => "Ex_OUT",
    'nas_name'            => $lang{NAS},
    'acct_session_id'     => "SESSION_ID",
    'connect_info'        => "CONNECT_INFO",
    'guest'               => $lang{GUEST},
    'turbo'               => 'TURBO',
    'ip'                  => "$lang{STATIC} IP",
    'netmask'             => 'NETMASK',
    'speed'               => $lang{SPEED},
    'calls_tp_id'         => 'Online TP_ID',
    'tp_id',              => 'TP_ID',
    #'port'        => "$lang{USER_PORT}",
    'cid'                 => 'CID',
    'filter_id'           => 'Filter ID',
    'tp_name'             => $lang{TARIF_PLAN},
    'last_alive'          => $lang{LAST_UPDATE},
    'internet_status'     => "Internet $lang{STATUS}",
    'internet_expire'     => "Internet $lang{EXPIRE}",
    'session_sum'         => "$lang{SESSIONS} $lang{SUM}",
    'status'              => "Online $lang{STATUS}",
    'remote_id'           => 'REMOTE_ID',
    'circuit_id'          => 'CIRCUIT_ID',
    'hostname'            => 'HOSTNAME',
    'switch_port'         => "$lang{SWITCH} $lang{PORT}",
    'vlan'                => 'vlan',
    'server_vlan'         => 'server_vlan',
    'switch_mac'          => $lang{SWITCH} . " MAC",
    'switch_name'         => $lang{SWITCH},
    'switch_id'           => "$lang{SWITCH} ID",
    'dhcp_id'             => 'dhcp_id',
    'dhcp_ends'           => 'dhcp_ends',,
    'service_id'          => '# SERVICE_ID',
    framed_ipv6_prefix    => 'IPV6',
    framed_interface_id   => 'FRAMED_INTERFACE_ID',
    delegated_ipv6_prefix => 'DELEGATED_IPV6_PREFIX',
    'cpe_mac'             => 'CPE MAC'
  );

  my Abills::HTML $table;

  ($table, $list) = result_former({
    INPUT_DATA      => $Sessions,
    FUNCTION        => 'online',
    DEFAULT_FIELDS  => 'LOGIN,FIO,DURATION_SEC2,CLIENT_IP_NUM,ACCT_INPUT_OCTETS,ACCT_OUTPUT_OCTETS',
    BASE_FIELDS     => 0,
    FUNCTION_FIELDS => 'ping, zap, hangup, graphics',
    EXT_TITLES      => \%EXT_TITLES,
    FILTER_COLS  => {
      duration_sec    => '_sec2time_str',
      online_duration => '_sec2time_str',
      client_ip_num   => 'int2ip',
    },
    #SELECT_VALUE    => {
    #   status  => \%online_status,
    #},
    TABLE           => {
      width      => '100%',
      caption    => $cure,
      SELECT_ALL => ($FORM{ZAPED}) ? "users_list:IDS:$lang{SELECT_ALL}" : undef,
      qs         => $pages_qs,
      ID         => 'INTERNET_ONLINE',
      EXPORT     => 1,
    },
    SKIP_PAGES   => 1
  });

  my $dub_ports  = ($Sessions->{dub_ports}) ? $Sessions->{dub_ports} : undef;
  my $dub_logins = ($Sessions->{dub_logins}) ? $Sessions->{dub_logins} : undef;
  my $dub_ips    = ($Sessions->{dub_ips}) ? $Sessions->{dub_ips} : undef;
  my $online     = $Sessions->{nas_sorted};

  foreach my $nas_row (@$nas_list) {
    next if (!defined($online->{ $nas_row->{nas_id} }));
    next if (($FORM{NAS_ID} && $FORM{NAS_ID} != $nas_row->{nas_id}) && !$FORM{ZAPED});

    my $l     = $online->{ $nas_row->{nas_id} };
    my $total = $#{$l} + 1;
    if(! $FORM{json}) {
      $table->{rowcolor} = 'bg-info';
      $table->{extra} = "colspan='" . ($Sessions->{SEARCH_FIELDS_COUNT}) . "'";
      $table->addrow("$nas_row->{nas_id}:"
        . $html->button($html->b($nas_row->{nas_name}),
        "index=" . get_function_index('form_nas') . "&NAS_ID=$nas_row->{nas_id}")
        . ":$nas_row->{nas_ip}:$lang{TOTAL}: $total "
        . ($permissions{5}{1} ? $html->button("Zap $lang{SESSIONS}", "index=$index&zapall=1&NAS_ID=$nas_row->{nas_id}",
        { MESSAGE => "Do you realy want zap all sessions on NAS '$nas_row->{nas_id}' ?", class => 'btn btn-default' }) : '')
        . $html->button("$lang{ERROR}",
        "index=" . get_function_index('internet_error') . "&NAS_ID=$nas_row->{nas_id}&search_form=1&search=1",
        { class => 'btn btn-default' })
        . $html->button("", "#",
        { class                                                      => 'btn btn-default', ICON =>
          'glyphicon glyphicon-stats', TITLE                         => "$lang{GRAPH} $lang{NAS}",
          NEW_WINDOW                                                 =>
          internet_get_chart_query("NAS_ID=$nas_row->{nas_id}", '1',
            $chart_new_window_width, $chart_height), NEW_WINDOW_SIZE => "$new_window_size" })
      );
    }

    foreach my $line (@$l) {
      undef($table->{rowcolor});
      undef($table->{extra});

      if (defined($dub_logins->{ $line->{user_name} }) && $dub_logins->{ $line->{user_name} } > 1) {
        $table->{rowcolor} = '#FFFF00';
      }
      elsif ($nas_row->{nas_type} ne 'ipcad'
        && $nas_row->{nas_type} ne 'dhcp'
        && defined($line->{nas_port_id})
        && defined($nas_row->{nas_id})
        && defined($dub_ports->{ $nas_row->{nas_id} }{ $line->{nas_port_id} })
        && $dub_ports->{ $nas_row->{nas_id} }{ $line->{nas_port_id} } > 1) {
        $table->{rowcolor} = '#00FF40';
      }
      elsif ($line->{client_ip} && defined($dub_ips->{ $nas_row->{nas_id} }{ $line->{client_ip} }) && $dub_ips->{ $nas_row->{nas_id} }{ $line->{client_ip} } > 1) {
        $table->{rowcolor} = '#0080C0';
      }

      my @fields_array = ();
      if ($FORM{ZAPED}) {
        push @fields_array,
          $html->form_input('IDS', "$line->{acct_session_id}", { TYPE => 'checkbox', FORM_ID => 'users_list' });
      }

      for (my $i = 0; $i < $Sessions->{SEARCH_FIELDS_COUNT}; $i++) {
        my $val = '';
        my $col_name = $Sessions->{COL_NAMES_ARR}->[$i];
        if ($conf{EXT_BILL_ACCOUNT} && $Sessions->{COL_NAMES_ARR}->[$i] eq 'ext_bill_deposit') {
          $val = ($line->{ext_bill_deposit} < 0) ? $html->color_mark($line->{ext_bill_deposit},
              $_COLORS[6])                       : $line->{ext_bill_deposit};
        }
        elsif ($col_name eq 'deleted') {
          $val = $html->color_mark($bool_vals[ $line->{deleted} ],
              ($line->{deleted} == 1) ? $state_colors[ $line->{deleted} ] : '');
        }
        elsif ($col_name eq 'status') {
          $val = $online_status{  $line->{status} };
        }
        elsif ($col_name eq 'duration_sec2') {
          $val = _sec2time_str($line->{duration_sec2});
        }
        elsif ($col_name eq 'client_ip_num') {
          $val = int2ip($line->{client_ip_num});
          $line->{client_ip} = $val;
        }
        elsif($col_name eq 'switch_id' && $line->{switch_id}) {
          my $nas_index = get_function_index('equipment_info');

          if(! $nas_index) {
            $nas_index = get_function_index('form_nas');
          }

          if($nas_index) {
            $val = $html->button($line->{switch_id}, "index=$nas_index&NAS_ID=". $line->{switch_id});
          }
          else {
            $val = $line->{switch_id};
          }
        }
        elsif ($col_name eq 'internet_status') {
          if (defined($line->{internet_status})) {
            my ($status, $color) = split( /:/, $service_status->{ $line->{internet_status} || 0 } || '' );
            $val = $html->color_mark( $status, $color );
          }
          else {
            $val = '-';
          }
        }
        elsif ($col_name eq 'user_name' || $col_name eq 'login') {
          if ($line->{uid}) {
            $val = $html->button($line->{$Sessions->{COL_NAMES_ARR}->[$i]}, "index=15&UID=$line->{uid}");
          }
          else {
            $val = $line->{$Sessions->{COL_NAMES_ARR}->[$i]};
          }
        }
        elsif ($col_name =~ /acct_input_octets|acct_output_octets|ex_input_octets|ex_output_octets/) {
          $val = int2byte($line->{$Sessions->{COL_NAMES_ARR}->[$i]});
        }
        elsif ($col_name eq 'cid') {
          if ($line->{$col_name}) {
            $val = $html->color_mark($line->{$col_name}, 'code');
            if ($line->{$col_name} =~ /$Abills::Filters::MAC/ && ! $FORM{json}) {
              $val .= ' '.$html->button( $lang{INFO}, "index=$index&mac_info=$line->{cid}&UID=$line->{uid}",
                { class => 'info' } );
            }
          }
        }
        elsif ($col_name eq 'guest') {
          $val = ($line->{$col_name}) ? $html->color_mark($lang{YES}, $_COLORS[6]) : $lang{NO};
        }
        else {
          $val = $line->{$col_name};
        }

        if ($val && $FORM{FILTER} && $FORM{FILTER_FIELD} eq uc($col_name)) {
          my $filter = $FORM{FILTER};
          $filter =~ s/\*//g;
          my $search_color_mark = $html->color_mark($filter, $_COLORS[6]);
          $val =~ s/(.*)$filter(.*)/$1$search_color_mark$2/i;
        }

        push @fields_array, $val;
      }

      my @function_fields = (
        $html->button('P', "index=$index&ping=". int2ip($line->{ client_ip_num })."&SESSION_ID=$line->{acct_session_id}$pages_qs",
          { TITLE => 'ping', BUTTON => 1 }),
        $html->button("$lang{GRAPH} $lang{USER}", "#", {
            class      => 'stats',
            NEW_WINDOW =>  internet_get_chart_query("UID=$line->{uid}", '1', $chart_new_window_width, $chart_height),
            NEW_WINDOW_SIZE => $new_window_size
          })
      );

      if ($permissions{5}{1}) {
        push @function_fields, $html->button('Z', "index=$index&zap=$line->{uid}+$nas_row->{nas_id}+"
              .($line->{nas_port_id} || q{})."+$line->{acct_session_id}$pages_qs",
            { TITLE => 'Zap', class => 'del', NO_LINK_FORMER => 1 });
      }

      if ($permissions{5}{2}) {
        push @function_fields, ($FORM{ZAPED}) ? '' : $html->button('H', "index=$index&FRAMED_IP_ADDRESS="
                .($line->{client_ip} || q{0.0.0.0})
                ."&hangup=$nas_row->{nas_id}+".($line->{nas_port_id} || q{})
                ."+$line->{acct_session_id}+$line->{user_name}&UID=$line->{uid}$pages_qs",
              { TITLE => 'Hangup', class => 'off' });
      }

      $table->addrow(@fields_array, join(' ', @function_fields));
    }
  }

  my $output = $table->show();

  if ($FORM{ZAPED}) {
    $output = $html->form_main(
      {
        CONTENT => $output,
        HIDDEN  => {
          index  => "$index",
          ZAPED  => 1,
          NAS_ID => $FORM{NAS_ID}
        },
        SUBMIT => {
          del   => "$lang{DEL}",
          tolog => "$lang{ADD} to LOG"
        },
        METHOD => 'POST',
        NAME   => 'users_list',
        ID     => 'users_list',
      }
    );
  }
  else {
    $output = internet_online_search() . $output;

    #TODO MOreelegent solution
    if(! $FORM{json}) {
      $output .=
        ($permissions{5}{1} ? $html->button('Zap All', "index=$index&zapall=1",
          { class   => 'btn btn-default btn-danger', ICON => 'glyphicon glyphicon-trash',
            MESSAGE => "Do you realy want ZAP all sessions ?" }) : '')
          . $html->button("$lang{GRAPH} $lang{NAS}", "#",
          { class           => 'btn btn-default', ICON => 'glyphicon glyphicon-stats',
            NEW_WINDOW      => internet_get_chart_query('NAS_ID=all', '1', $chart_new_window_width, $chart_height),
            NEW_WINDOW_SIZE => "$new_window_size" })
          . $html->button("$lang{GRAPH} $lang{TARIF_PLANS}", "#",
          { class           => 'btn btn-default', ICON => 'glyphicon glyphicon-stats',
            NEW_WINDOW      => internet_get_chart_query('TP_ID=all', '1', $chart_new_window_width, $chart_height),
            NEW_WINDOW_SIZE => "$new_window_size" })
          . $html->button("$lang{GRAPH} $lang{GROUPS}", "#",
          { class           => 'btn btn-default', ICON => 'glyphicon glyphicon-stats',
            NEW_WINDOW      => internet_get_chart_query('GID=all', '1', $chart_new_window_width, $chart_height),
            NEW_WINDOW_SIZE => "$new_window_size" });
    }
  }

  print $output;

  return 1;
}


#**********************************************************
=head2 internet_online_search()

=cut
#**********************************************************
sub internet_online_search {

  my %FILTER_FIELDS = (
    USER_NAME      => $lang{LOGIN},
    FIO            => $lang{FIO},
    NAS_PORT_ID    => $lang{PORT},
    DURATION       => $lang{DURATION},
    CLIENT_IP      => 'IP',
    CID            => 'CID',
    CPE_MAC        => 'CPE_MAC',
    TP_ID          => $lang{TARIF_PLAN},
    CONNECT_INFO   => 'CONNECT_INFO',
    GUEST          => $lang{GUEST},
    TURBO_MODE     => $lang{TURBO_MODE},
    JOIN_SERVICE   => $lang{JOIN_SERVICE},
    ADDRESS_FULL   => $lang{ADDRESS},
    ACCT_SESSION_ID=> 'SESSION_ID',
    UID            => 'UID',
    LAST_ALIVE     => $lang{LAST_UPDATE},
    GID            => "$lang{GROUP} ID",
    TAGS           => "$lang{TAGS}",
  );

  my $FIELDS_SEL = $html->form_select(
    'FILTER_FIELD',
    {
      SELECTED => $FORM{FILTER_FIELD},
      SEL_HASH => \%FILTER_FIELDS,
      NO_ID    => 1,
      ID       => 'type'
    }
  );

  my $report_form = $html->element( 'div', "$lang{FILTERS}: ". $html->form_input('FILTER', $FORM{FILTER}). " $lang{FIELDS}: ".
      $FIELDS_SEL
      . " $lang{REFRESH} (sec): ". $html->form_input('REFRESH', int($FORM{REFRESH} || 0), { SIZE => 4 })
      . $html->form_input('SHOW', $lang{SHOW}, { TYPE => 'SUBMIT' }), {
      class => 'well well-sm',
    } );

  return $html->form_main(
    {
      CONTENT => $report_form,
      HIDDEN  => {
        index  => "$index",
        NAS_ID => $FORM{NAS_ID}
      },
      METHOD => 'GET',
      class  => 'form-inline'
    }
  );
}

#**********************************************************
=head2 internet_diagnostic($diagnostic_info) - Global search submodule

  Arguments:
    $diagnostic_info

  Returs:
     TRUE/FALSE

=cut
#**********************************************************
sub internet_diagnostic {
  my ($diagnostic) = @_;

  my ($diag_num,$diag_params) = split(/:/, $diagnostic, 2);
  my ($ip, $uid, $nas_id, undef, $acct_session_id) = split(/ /, $diag_params);

  my ($name, $cmd);
  my @diagnostic_rules = split(/;/, $conf{INTERNET_EXTERNAL_DIAGNOSTIC});
  for(my $i=0; $i<=$#diagnostic_rules; $i++) {
    ($name, $cmd)=split(/:/, $diagnostic_rules[$i]);
    if ($i == $diag_num) {
      last;
    }
  }

  my $ACCT_INFO = $Sessions->online_info({
    NAS_ID            => $nas_id,
    NAS_IP_ADDRESS    => '_SHOW',
    ACCT_SESSION_ID   => $acct_session_id,
    UID               => $uid,
    FRAMED_IP_ADDRESS => $ip
  });

  my $res = cmd($cmd, {
      PARAMS => $ACCT_INFO,
      SET_ENV=> 1
    });

  print $html->message('info', $lang{DIAGNOSTIC} .' '. ($name || q{}), $res);

  return 1;
}


#**********************************************************
=head2 internet_online_builds() - show builds with statuses

=cut
#**********************************************************
sub internet_online_builds {
  require Address; Address->import();
  my $Address = Address->new($db, $admin, \%conf);
  
  my $online_count_for_build = $Sessions->users_online_count_by_builds();
  _error_show($Sessions) and return 0;
  my %online_for_location_id = map { $_->{id} => $_->{online_count} } @$online_count_for_build ;

  my $online_has_guest = $Sessions->users_online_count_by_builds({GUEST => 1});
  _error_show($Sessions) and return 0;
  my %online_for_guest_location_id = map { $_->{id} => $_->{online_count} } @$online_has_guest ;

  my $districts_list = $Address->district_list( {
    COLS_NAME => 1,
    SORT      => 'd.name',
    PAGE_ROWS => 10000
  } );
  return if (_error_show($Address));
  
  my $districts_content = '';
  foreach my $district ( @{$districts_list} ) {
    # Get all streets
    my $streets_list = $Address->street_list( {
      DISTRICT_ID => $district->{id},
      STREET_NAME => '_SHOW',
      SECOND_NAME => '_SHOW',
      COLS_NAME   => 1,
      SORT        => 's.name',
      PAGE_ROWS   => 10000
    } );
    return if (_error_show($Address));
    
    my $streets_content = '';
    foreach my $street ( @{$streets_list} ) {
      my $builds_list = $Address->build_list({
        STREET_ID   => $street->{id},
        COLS_NAME   => 1,
        USERS_COUNT => '_SHOW',
        SORT        => 1,
        PAGE_ROWS   => 10000
      });
      return if ( _error_show($Address) );
  
      my %street_users = (
        total  => 0,
        online => 0,
      );
  
      my $builds_content = '';
      my $builds_count = 0;
      foreach my $build ( @{$builds_list} ) {
    
        my $btn_class = 'btn-default';
        
        $street_users{total} += $build->{users_count};
        
        my $has_online = ($online_for_location_id{$build->{id}});
        my $has_guest = ($online_for_guest_location_id{$build->{id}});
        if ($has_online) {
          $street_users{online} += $online_for_location_id{$build->{id}};
          $btn_class = 'btn-success';
        }
        elsif ($has_guest) {
          $street_users{online} += $online_for_guest_location_id{$build->{id}};
          $btn_class = 'btn-warning';
        }
        elsif ($build->{users_count}){
          $btn_class = 'btn-danger';
        }
  
        $builds_count += 1;
        $builds_content .= $html->button($build->{number},
          "index=7&type=11&search=1&search_form=1&LOCATION_ID=$build->{id}&BUILDS=$street->{id}", {
            class         => 'btn btn-lg btn-build ' . $btn_class,
            OUTPUT2RETURN => 1
          }
        );
        
      }
  
      my $offline_users = ($street_users{total} || 0) - ($street_users{online} || 0);
      my $street_online_text = join(' / ',
        $html->element('span', $street_users{total} || '0', { class => 'text-muted', title => $lang{TOTAL} }),
        $html->element('span', $street_users{online} || '0', { class => 'text-success', title => $lang{ONLY_ONLINE} }),
        $html->element('span', $offline_users || '0', { class => 'text-danger', title => $lang{ONLY_OFFLINE} }),
      );
      
      $streets_content .= $html->tpl_show(templates('form_show_hide'), {
          NAME    => $street->{street_name}
            . ($street->{second_name}
              ? " ( $street->{second_name} ) "
              : '')
            . " ( $street_online_text ) "
            ,
          CONTENT => '<div class="button-block">' . $builds_content . '</div>',
          PARAMS  => 'collapsed-box'
        },
        {
          OUTPUT2RETURN => 1
        });
    }
  
    $districts_content .= $html->tpl_show( templates('form_show_hide'), {
        NAME    => $lang{DISTRICT} . ' ' . $district->{name} . ' ( ' . (scalar @{$streets_list}) . ' )',
        CONTENT => $streets_content,
        PARAMS  => 'collapsed-box'
      }, {
        OUTPUT2RETURN => 1
      } );
  };
  
  
  $html->tpl_show(_include('internet_online_builds', 'Internet'),
    {
      DISTRICT_PANELS => $districts_content
    }
  );

  return 1;
}


1;