=head1 NAME

  Dv Reports

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(int2byte time2sec sec2time _bp in_array);

our(
  %lang,
  $html,
  $db,
  $admin,
  %conf
);

my $Internet = Internet->new($db, $admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);
my $Sessions = Internet::Sessions->new($db, $admin, \%conf);

require Internet::Traffic_detail;

#**********************************************************
=head2 internet_use_all_monthes()

=cut
#**********************************************************
sub internet_use_allmonthes {

  $FORM{allmonthes} = 1;
  internet_report_use();

  return 1;
}

#**********************************************************
=head2 internet_report_use();

=cut
#**********************************************************
sub internet_report_use {

  my %HIDDEN = ();
  $HIDDEN{COMPANY_ID} = $FORM{COMPANY_ID} if ($FORM{COMPANY_ID});
  $HIDDEN{sid} = $sid if ($FORM{sid});

  my %ext_fields = (
    arpu         => $lang{ARPU},
    arpuu        => $lang{ARPPU},
    date         => $lang{DATE},
    month        => $lang{MONTH},
    login        => $lang{USER},
    fio          => $lang{FIO},
    hour         => $lang{HOURS},
    build        => $lang{ADDRESS_BUILD},
    district_name=> $lang{DISTRICT},
    street_name  => $lang{ADDRESS_STREET},
    login_count  => $lang{USERS},
    count        => $lang{COUNT},
    sum          => $lang{SUM},
    terminate_cause => "$lang{HANGUP} $lang{STATUS}",
    gid             => $lang{GROUPS},
    duration_sec    => $lang{DURATION},
    users_count     => $lang{USERS},
    sessions_count  => $lang{SESSIONS},
    traffic_recv    => $lang{SENT},
    traffic_sent    => $lang{RECV},
    traffic_sum     => $lang{TRAFFIC},
    traffic_2_sum   => "$lang{TRAFFIC} 2",
    company_name    => $lang{COMPANY}
  );

  reports(
    {
      DATE        => $FORM{DATE},
      HIDDEN      => \%HIDDEN,
      REPORT      => '',
      PERIOD_FORM => 1,
      EXT_TYPE    => {
        PER_MONTH       => $lang{PER_MONTH},
        DISTRICT        => $lang{DISTRICT},
        STREET          => $lang{STREET},
        BUILD           => $lang{BUILD},
        TP              => "$lang{TARIF_PLANS}",
        GID             => "$lang{GROUPS}",
        TERMINATE_CAUSE => 'TERMINATE_CAUSE',
        COMPANIES       => $lang{COMPANIES}
      },
    }
  );

  %CHARTS    = (
    TYPES => {
      login_count    => 'column',
      users_count    => 'column',
      sessions_count => 'column',
      traffic_recv   => 'column',
      traffic_sent   => 'column',
      duration_sec   => 'column'
    },
    PERIOD        => (! $FORM{TYPE} && ! $FORM{DATE}) ? 'month_stats' : ''
  );

  my %TP_NAMES = ();
  my $list = $Tariffs->list({ MODULE => 'Dv', NEW_MODEL_TP => 1, COLS_NAME => 1 });
  foreach my $line (@$list) {
    $TP_NAMES{ $line->{id} } = $line->{name};
  }

  if ($FORM{TERMINATE_CAUSE}) {
    $LIST_PARAMS{TERMINATE_CAUSE} = $FORM{TERMINATE_CAUSE};
  }
  elsif ($FORM{TP_ID}) {
    $LIST_PARAMS{TP_ID} = $FORM{TP_ID};
  }

  $Sessions->{debug}=1 if ($FORM{DEBUG});
  my Abills::HTML $table;
  our %DATA_HASH;
  ($table, $list) = result_former({
    INPUT_DATA      => $Sessions,
    FUNCTION        => 'reports2',
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'USERS_COUNT,SESSIONS_COUNT,TRAFFIC_RECV,TRAFFIC_SENT,DURATION_SEC,SUM',
    SKIP_USER_TITLE => (! $FORM{TYPE} || $FORM{TYPE} ne 'USER') ? 1 : undef,
    SELECT_VALUE    => {
      terminate_cause => internet_terminate_causes({ REVERSE => 1 }),
      gid             => sel_groups({ HASH_RESULT => 1 }),
      tp_id           => \%TP_NAMES
    },
    CHARTS       => 'users_count,sessions_count,traffic_recv,traffic_sent,duration_sec',
    CHARTS_XTEXT => 'auto', #$x_text,
    EXT_TITLES   => \%ext_fields,
    FILTER_COLS  => {
      duration_sec    => '_sec2time_str',
      traffic_recv    => 'int2byte',
      traffic_sent    => 'int2byte',
      traffic_sum     => 'int2byte',
      terminate_cause => "search_link:internet_report_use:TERMINATE_CAUSE,$pages_qs",
      company_name    => "search_link:internet_report_use:COMPANY_NAME,$pages_qs",
      tp_id           => "search_link:internet_report_use:TP_ID,$pages_qs",
      month           => "search_link:internet_report_use:MONTH,$pages_qs",
      gid             => "search_link:internet_report_use:GID,$pages_qs",
      date            => "search_link:internet_report_use:DATE,DATE",
      login           => "search_link:from_users:UID,type=1,$pages_qs",
      build           => "search_link:internet_report_use:LOCATION_ID,LOCATION_ID,TYPE=USER,$pages_qs",
      district_name   => "search_link:internet_report_use:DISTRICT_ID,DISTRICT_ID,TYPE=USER,$pages_qs",
      street_name     => "search_link:internet_report_use:STREET_ID,STREET_ID,TYPE=USER,$pages_qs",
    },
    TABLE   => {
      width      => '100%',
      caption    => "$lang{REPORTS}",
      qs         => $pages_qs,
      ID         => 'REPORTS_DV_USE',
      EXPORT     => 1,
      SHOW_COLS_HIDDEN => { TYPE      => $FORM{TYPE},
        show      => 1,
        FROM_DATE => $FORM{FROM_DATE},
        TO_DATE   => $FORM{TO_DATE},
      }
    },
    MAKE_ROWS    => 1,
    SEARCH_FORMER=> 1,
    #TOTAL        => 1
  });

  print $html->make_charts(
    {
      DATA          => \%DATA_HASH,
      #AVG           => \%AVG,
      #TYPE          => \@CHART_TYPE,
      TITLE         => 'Internet',
      TRANSITION    => 1,
      OUTPUT2RETURN => 1,
      %CHARTS
    }
  );

  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      rows       => [
        [
          "$lang{USERS}: " . $html->b($Sessions->{USERS}),
          "$lang{SESSIONS}: " . $html->b($Sessions->{SESSIONS}),
          "$lang{TRAFFIC}: "
            . $html->b(int2byte($Sessions->{TRAFFIC}))
            . $html->br()
            . "$lang{TRAFFIC} IN: "
            . $html->b(int2byte($Sessions->{TRAFFIC_IN}))
            . $html->br()
            . "$lang{TRAFFIC} OUT: "
            . $html->b(int2byte($Sessions->{TRAFFIC_OUT}))
          ,

          "$lang{TRAFFIC} 2: " . $html->b(int2byte($Sessions->{TRAFFIC_2})) . $html->br() . "$lang{TRAFFIC} 2 IN: " . $html->b(int2byte($Sessions->{TRAFFIC_2_IN})) . $html->br() . "$lang{TRAFFIC} 2 OUT: " . $html->b(int2byte($Sessions->{TRAFFIC_2_OUT})),

          "$lang{DURATION}: " . $html->b(sec2time($Sessions->{DURATION_SEC}, { str => 1 })),
          "$lang{SUM}: " . $html->b($Sessions->{SUM})
        ]
      ],
      rowcolor => 'even'
    }
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 internet_report_debetors($attr)

=cut
#**********************************************************
sub internet_report_debetors {

  result_former({
    INPUT_DATA      => $Internet,
    FUNCTION        => 'report_debetors',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'LOGIN,FIO,PHONE,TP_NAME,DEPOSIT,CREDIT,DV_STATUS',
    FUNCTION_FIELDS => '',
    EXT_TITLES      => {
      'ip'          => 'IP',
      'netmask'     => 'NETMASK',
      'speed'       => $lang{SPEED},
      'port'        => $lang{PORT},
      'cid'         => 'CID',
      'filter_id'   => 'Filter ID',
      'tp_name'     => "$lang{TARIF_PLAN}",
      'internet_status'   => "Internet $lang{STATUS}",
      'internet_status_date' => "$lang{STATUS} $lang{DATE}",
      'online'      => 'Online',
      'internet_expire'   => "Internet $lang{EXPIRE}",
      'internet_login'    => "$lang{SERVICE} $lang{LOGIN}",
      'internet_password' => "$lang{SERVICE} $lang{PASSWD}"
    },
    TABLE           => {
      width      => '100%',
      caption    => "$lang{DEBETORS}",
      qs         => $pages_qs,
      ID         => 'REPORT_DEBETORS',
      EXPORT     => 1,
    },
    MAKE_ROWS    => 1,
    MODULE       => 'Dv',
    TOTAL        => "TOTAL:$lang{TOTAL};TOTAL_DEBETORS_SUM:$lang{SUM}"
  });

  return 1;
}

#**********************************************************
=head2 internet_report_tp()

=cut
#**********************************************************
sub internet_report_tp {

  my $list = $Internet->report_tp({
    %LIST_PARAMS,
    COLS_NAME => 1
  });

  my $table = $html->table(
    {
      caption     => $lang{TARIF_PLANS},
      width       => '100%',
      title       => [ "#", $lang{NAME}, $lang{TOTAL}, $lang{ACTIV}, $lang{DISABLE},
        $lang{DEBETORS}, "ARPPU $lang{ARPPU}", "ARPU $lang{ARPU}" ],
      ID          => 'REPORTS_TARIF_PLANS'
    }
  );

  my $internet_users_list_index = get_function_index('internet_users_list') || 0;

  my ($total_users, $totals_active, $total_disabled, $total_debetors)=(0,0,0,0);
  foreach my $line (@$list) {
    $line->{id} = 0 if (! defined($line->{id}));
    $line->{tp_id} = 0 if (! defined($line->{tp_id}));
    $table->addrow(
      $line->{id},
      $html->button($line->{name}, "index=$internet_users_list_index&TP_ID=$line->{tp_id}"),
      $html->button($line->{counts}, "index=$internet_users_list_index&TP_ID=$line->{tp_id}"),
      $html->button($line->{active}, "index=$internet_users_list_index&TP_ID=$line->{tp_id}&INTERNET_STATUS=0"),
      $html->button($line->{disabled}, "index=$internet_users_list_index&TP_ID=$line->{tp_id}&INTERNET_STATUS=1"),
      $html->button($line->{debetors}, "index=$internet_users_list_index&TP_ID=$line->{tp_id}&DEPOSIT=<0&search=1"),
      sprintf('%.2f', $line->{arppu} || 0),
      sprintf('%.2f', $line->{arpu} || 0)
    );

    $total_users    += $line->{counts};
    $totals_active  += $line->{active};
    $total_disabled += $line->{disabled};
    $total_debetors += $line->{debetors};
  }

  $table->addrow(
    '',
    $lang{TOTAL},
    $total_users,
    $totals_active,
    $total_disabled,
    $total_debetors
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 internet_pools_report()

=cut
#**********************************************************
sub internet_pools_report {
  my ($attr) = @_;
  $attr //= \%FORM;

  my $DDebug = 0;

  require Nas;
  Nas->import();
  my Nas $Nas = Nas->new($db, \%conf, $admin);

  # Get dv static ips
  my $static_assigned_list = $Internet->list({
    IP_NUM    => '>0.0.0.0',
    COLS_NAME => 1,
    PAGE_ROWS => 100000
  });
  _error_show($Internet);

  my @static_ips = map {$_->{ip_num}} @{$static_assigned_list};

  # Get online ips
  my $active_assigned_list = $Sessions->online({
    CLIENT_IP_NUM => '_SHOW',
    NAS_ID        => '_SHOW',
    COLS_NAME     => 1,
    PAGE_ROWS     => 100000
  });
  _error_show($Sessions);

  my @online_ips = map {$_->{client_ip_num}} @{$active_assigned_list};

  # Get pools
  my $pools_list = $Nas->nas_ip_pools_list({
    COLS_NAME        => 1,
    INTERNET         => in_array('Internet', \@MODULES),
    SHOW_ALL_COLUMNS => 1,
    PAGE_ROWS        => 10000
  });

  _error_show($Nas);

  my %pools_by_id = map {$_->{id} => $_} @{$pools_list};

  # Assign ips to pools
  my %ips_for_pool = ();
  # {
  #  '%pool_id%' => {
  #    ips => {
  #      'ip_address' => type # (0 - dynamic, 1 - static, static-in-dynamic - 2 )
  #    },
  #    static_count  => '%num%',
  #    dynamic_count => '%num%',
  #    count         => '%num%'  - total
  #  },
  #   ...
  #}

  my $find_pool_for_address = sub {
    my $ip_addr_num = shift;
    foreach my $pool ( @{$pools_list} ) {
      return $pool->{id} if ( $ip_addr_num >= $pool->{ip} && $ip_addr_num <= $pool->{last_ip_num} );
    }

    return 0;
  };

  my @static_without_pool = ();
  foreach my $static_addr ( @static_ips ) {
    my $pool_id = $find_pool_for_address->($static_addr);

    if ( !$pool_id ) {
      push (@static_without_pool, $static_addr);
      next;
    }

    $ips_for_pool{$pool_id}->{count} //= 0;
    $ips_for_pool{$pool_id}->{static_count} //= 0;
    $ips_for_pool{$pool_id}->{dynamic_count} //= 0;

    if ( !$pools_by_id{$pool_id}->{static} ) {
      # Showing errornous assigning static ip from dynamic pool
      $ips_for_pool{$pool_id}->{ip}->{$static_addr} = 2;
      $ips_for_pool{$pool_id}->{static_count} += 1;
    }
    else {
      $ips_for_pool{$pool_id}->{ip}->{$static_addr} = 1;
      $ips_for_pool{$pool_id}->{static_count} += 1;
    }

    $ips_for_pool{$pool_id}->{count} += 1;
  }

  my @dynamic_without_pool = ();
  foreach my $online_addr ( @online_ips ) {
    # Skip if found static ip in online
    next if ( grep {$_ == $online_addr} @static_ips );

    my $pool_id = $find_pool_for_address->($online_addr);

    if ( !$pool_id ) {
      push (@dynamic_without_pool, $online_addr);
      next;
    }

    $ips_for_pool{$pool_id}->{count} //= 0;
    $ips_for_pool{$pool_id}->{static_count} //= 0;
    $ips_for_pool{$pool_id}->{dynamic_count} //= 0;

    # Showing errornous assigning static ip from dynamic pool
    if ( $pools_by_id{$pool_id}->{static} ) {
      $ips_for_pool{$pool_id}->{ip}->{$online_addr} = 1;
      $ips_for_pool{$pool_id}->{dynamic_count} += 1;
    }
    else {
      $ips_for_pool{$pool_id}->{ip}->{$online_addr} = 0;
      $ips_for_pool{$pool_id}->{dynamic_count} += 1;
    }

    $ips_for_pool{$pool_id}->{count} += 1;

  }

  # Check pool sizes and build fillness data
  foreach my $pool_id ( sort keys %ips_for_pool ) {

    my $dynamic = $ips_for_pool{$pool_id}->{dynamic_count} / $pools_by_id{$pool_id}->{ip_count};
    my $static = $ips_for_pool{$pool_id}->{static_count} / $pools_by_id{$pool_id}->{ip_count};
    #    my $free = 1 - ($ips_for_pool{$pool_id}{count} / $pools_by_id{$pool_id}{ip_count});
    my $free = 1 - ($dynamic + $static);

    $ips_for_pool{$pool_id}->{usage}->{dynamic} = sprintf("%.2f", $dynamic * 100);
    $ips_for_pool{$pool_id}->{usage}->{static} = sprintf("%.2f", $static * 100);
    $ips_for_pool{$pool_id}->{usage}->{free} = sprintf("%.2f", $free * 100);
  }

  _bp('Pool using with percents', \%ips_for_pool) if ( $DDebug );
  return \%ips_for_pool if ( $attr->{RETURN_USAGE} );

  my %charts = ();

  foreach my $pool_id ( sort keys %pools_by_id ) {

    my $normal_fill = ($pools_by_id{$pool_id}->{static}) ? 'static' : 'dynamic';
    my $errornous_fill = ($pools_by_id{$pool_id}->{static}) ? 'dynamic' : 'static';

    if ( !$ips_for_pool{$pool_id} || !$ips_for_pool{$pool_id}->{usage} ) {
      $charts{$pool_id} = $html->chart({
        TYPE              => 'pie',
        X_LABELS          => [ $lang{FREE} ],
        DATA              => {
          'USAGE' => [ 100 ],
        },
        HIDE_LEGEND       => 1,
        BACKGROUND_COLORS => {
          'USAGE' => [ '#4CAF50' ],
        },
        OUTPUT2RETURN     => 1,
      });
      next;
    }

    my @usage = (
      $ips_for_pool{$pool_id}->{usage}->{free},
      $ips_for_pool{$pool_id}->{usage}->{$normal_fill},
    );
    push (@usage,
      $ips_for_pool{$pool_id}->{usage}->{$errornous_fill}) if ( $ips_for_pool{$pool_id}->{usage}->{$errornous_fill} > 0 );

    $charts{$pool_id} = $html->chart({
      TYPE              => 'pie',
      X_LABELS          => [ $lang{FREE}, $lang{USED}, $lang{ERROR} ],
      DATA              => {
        'USAGE' => \@usage,
      },
      HIDE_LEGEND       => 1,
      BACKGROUND_COLORS => {
        #        'USAGE' => [ 'rgb(255,205,86)', 'rgb(255,99,132)', 'rgb(54, 162, 235)' ],
        'USAGE' => [ '#4CAF50', '#FF9800', '#F44336' ],
      },
      OUTPUT2RETURN     => 1,
    });
  }

  my $pools_index = get_function_index('form_ip_pools');

  my @rows = ();
  my $result = '';
  my $wrap_size = ($attr->{WRAP_SIZE} || '3');
  my $charts_in_row = 12 / $wrap_size;
  my $current_charts_in_row = 0;

  foreach my $pool_id ( sort keys %pools_by_id ) {
    my $pool = $pools_by_id{$pool_id};
    my $errornous_fill = ($pools_by_id{$pool_id}->{static}) ? 'dynamic' : 'static';

    $result .= $html->tpl_show(_include('internet_pool_report_single', 'Internet'),
      {
        COLS_SIZE   => $wrap_size,
        NAME        => $html->button($pool->{pool_name}, "index=$pools_index&chg=$pool->{id}"),
        NAS_NAME    => $pool->{static} ? $lang{STATIC} : ($pool->{nas_name} || $lang{NO}),
        IP_RANGE    => $pool->{first_ip} . '-' . $pool->{last_ip},

        USED        => $ips_for_pool{$pool_id}->{count} // 0,
        FREE        => $ips_for_pool{$pool_id}->{usage}{free} // 100,
        ERROR       => $ips_for_pool{$pool_id}->{usage}{$errornous_fill} // 0,

        USAGE_CHART => $charts{$pool_id},
      },
      { OUTPUT2RETURN => 1 }
    );

    $current_charts_in_row += 1;
    if ( $current_charts_in_row >= $charts_in_row ) {
      push (@rows, $html->element('div', $result, { class => 'row' }));
      $result = '';
      $current_charts_in_row = 0;
    }
  }
  # Wrap last row
  push (@rows, $html->element('div', $result, { class => 'row' })) if ( $result );

  my $return_html = ($attr->{RETURN_HTML} || $attr->{OUTPUT2RETURN});
  $result = $html->element('div', join('', @rows), {
      class         => 'row',
      OUTPUT2RETURN => $return_html
    }
  );
  return $result if ( $attr->{RETURN_HTML} );

  if ( !$attr->{OUTPUT2RETURN} ) {
    print $result;
  }

  return \%charts;
}

1;