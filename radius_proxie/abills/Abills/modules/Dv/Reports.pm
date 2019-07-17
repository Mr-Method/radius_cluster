=head1 NAME

  Dv Reports

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(int2byte time2sec sec2time);

our(
  %lang,
  $html,
  $db,
  $admin,
  %conf
);

my $Dv       = Dv->new($db, $admin, \%conf);
my $Tariffs  = Tariffs->new($db, \%conf, $admin);
my $Sessions = Dv_Sessions->new($db, $admin, \%conf);

#**********************************************************
=head2 dv_use_all_monthes()

=cut
#**********************************************************
sub dv_use_allmonthes {

  $FORM{allmonthes} = 1;
  dv_use();

  return 1;
}

#**********************************************************
# dv_use();
#**********************************************************
#@deprecated
sub dv_use {

  my %CAPTIONS_HASH = (
    '1:DATE:right'          => $lang{DATE},
    '2:USERS:left'          => $lang{USERS},
    '3:USERS_FIO:left'      => $lang{FIO},
    '4:TP:left'             => $lang{TARIF_PLAN},
    '5:SESSIONS:right'      => $lang{SESSIONS},
    '6:TRAFFIC_RECV:right'  => "$lang{TRAFFIC} $lang{RECV}",
    '7:TRAFFIC_SENT:right'  => "$lang{TRAFFIC} $lang{SENT}",
    '8:TRAFFIC_SUM:right'   => $lang{TRAFFIC},
    '9:TRAFFIC_2_SUM:right' => $lang{TRAFFIC} . " 2",
    '91:DURATION:right'     => $lang{DURATION},
    '92:SUM:right'          => $lang{SUM}
  );

  my $ACCT_TERMINATE_CAUSES_REV = dv_terminate_causes({ REVERSE => 1 });
  my $i                         = 1;
  my $list                      = $Conf->config_list({ PARAM => 'ifu*' });
  my %INFO_LISTS                = ();

  foreach my $line (@$list) {
    my $field_id = '';
    if ($line->[0] =~ /ifu(\S+)/) {
      $field_id = $1;
    }

    my (undef, $type, $name) = split(/:/, $line->[1]);

    $CAPTIONS_HASH{ (90 + $i) . ':' . $field_id . ':left' } = $name;

    if ($type == 2) {
      my $list2 = $users->info_lists_list({ LIST_TABLE => $field_id . '_list' });
      foreach my $line2 (@$list2) {
        $INFO_LISTS{$field_id}{ $line2->[0] } = $line2->[1];
      }
    }
    $i++;
  }

  my %HIDDEN = ();

  $HIDDEN{COMPANY_ID} = $FORM{COMPANY_ID} if ($FORM{COMPANY_ID});
  $HIDDEN{sid} = $sid if ($FORM{sid});

  reports(
    {
      DATE      => $FORM{DATE},
      REPORT    => '',
      HIDDEN    => \%HIDDEN,
      EX_PARAMS => {
        HOURS => "$lang{HOURS}",
        USERS => "$lang{USERS}"
      },
      EXT_TYPE => {
        TP              => "$lang{TARIF_PLANS}",
        GID             => "$lang{GROUPS}",
        TERMINATE_CAUSE => 'TERMINATE_CAUSE',
        COMPANIES       => $lang{COMPANIES}
      },
      PERIOD_FORM => 1,
      FIELDS      => {%CAPTIONS_HASH},
      XML         => 1,
      EX_INPUTS   => [
        $html->form_select(
          'DIMENSION',
          {
            SELECTED => $FORM{DIMENSION},
            SEL_HASH => {
              ''   => 'Auto',
              'Bt' => 'Bt',
              'Kb' => 'Kb',
              'Mb' => 'Mb',
              'Gb' => 'Gb'
            },
            NO_ID => 1
          }
        )
      ]
    }
  );

  if ($FORM{TP_ID}) {
    $LIST_PARAMS{TP_ID} = $FORM{TP_ID};
    $pages_qs .= "&TP_ID=$FORM{TP_ID}";
  }

  if ($FORM{COMPANY_ID}) {
    $LIST_PARAMS{COMPANY_ID} = $FORM{COMPANY_ID};
    $pages_qs .= "&COMPANY_ID=$FORM{COMPANY_ID}";
  }

  my $output = '';

  my %TP_NAMES    = ();
  my %GROUP_NAMES = ();

  my %DATA_HASH = ();
  my %DATA_HASH2= ();
  my %CHART     = ();
  my %AVG       = (
    MONEY    => 0,
    TRAFFIC  => 0,
    DURATION => 0
  );

  my @CHART_TYPE  = ('column', 'line');
  my @CHART_TYPE2 = ('area',   'area');
  my $graph_type  = '';
  my $table_sessions;
  my $type        = $FORM{TYPE} || '';

  #Day reposrt
  if ($FORM{DATE}) {
    #Used Traffic
    $table_sessions = $html->table(
      {
        width      => '100%',
        caption    => "$lang{SESSIONS}",
        title      => [ "$lang{DATE}", "$lang{USERS}", "$lang{SESSIONS}", "$lang{TRAFFIC} ", "$lang{TRAFFIC} 2", $lang{DURATION}, $lang{SUM} ],
        cols_align => [ 'right', 'left', 'right', 'right', 'right', 'right', 'right' ],
        qs         => $pages_qs,
        ID         => 'DV_REPORTS_SESSIONS'
      }
    );

    if ($FORM{EX_PARAMS} && $FORM{EX_PARAMS} eq 'HOURS') {

      $list = $Sessions->reports({%LIST_PARAMS});
      my $num;
      foreach my $line (@$list) {
        $table_sessions->addrow($html->b($line->[0]), $line->[1], $line->[2], int2byte($line->[3], { DIMENSION => $FORM{DIMENSION} }), int2byte($line->[4], { DIMENSION => $FORM{DIMENSION} }), $line->[5], $html->b($line));

        $AVG{USERS}    = $line->[1]           if ($AVG{USERS} < $line->[1]);
        $AVG{TRAFFIC}  = $line->[3]           if ($AVG{TRAFFIC} < $line->[3]);
        $AVG{DURATION} = time2sec($line->[5]) if ($AVG{DURATION} < time2sec($line->[5]));
        $AVG{MONEY}    = $line->[6]           if ($AVG{MONEY} < $line->[6]);

        if ($line->[0] =~ /(\d+)-(\d+)-(\d+) (\d+)/) {
          $num = $4 + 1;
        }
        elsif ($line->[0] =~ /(\d+)-(\d+)/) {
          $CHART{X_LINE}[$num] = $line->[0];
          $num++;
        }

        $DATA_HASH{USERS}[$num]     = $line->[1];
        $DATA_HASH2{TRAFFIC}[$num]  = $line->[3];
        $DATA_HASH2{DURATION}[$num] = time2sec($line->[5]);
        $DATA_HASH{MONEY}[$num]     = $line->[6];

      }

      $graph_type = 'day_stats';
      $output     = $html->make_charts(
        {
          PERIOD        => $graph_type,
          DATA          => \%DATA_HASH2,
          AVG           => \%AVG,
          TYPE          => [ 'area', 'area' ],
          TRANSITION    => 1,
          OUTPUT2RETURN => 1
        }
      );

    }
    else {
      $list = $Sessions->reports({%LIST_PARAMS});
      foreach my $line (@$list) {
        $table_sessions->addrow($html->b($line->[0]), $html->button("$line->[1]", "index=15&UID=$line->[7]&DATE=$line->[0]"), $line->[2], int2byte($line->[3], { DIMENSION => $FORM{DIMENSION} }), int2byte($line->[4], { DIMENSION => $FORM{DIMENSION} }), $line->[5], $html->b($line->[6]));
      }
    }
  }
  else {
    #Used Traffic
    my @caption     = ();
    my @field_align = ();
    my %fields_hash = ();
    my @fields_arr  = ();

    if ($FORM{FIELDS}) {
      @fields_arr = split(/, /, $FORM{FIELDS});
      foreach my $line (@fields_arr) {
        $fields_hash{$line} = 1;
      }

      $i = 0;
      foreach my $line (sort keys %CAPTIONS_HASH) {
        my (undef, $val, $align) = split(/:/, $line);

        if ($fields_hash{$val}) {
          push @caption,     $CAPTIONS_HASH{$line};
          push @field_align, $align;
          $fields_arr[$i] = $val;
          $i++;
        }
      }
    }
    else {
      @caption = ("$lang{DATE}", "$lang{USERS}", "$lang{SESSIONS}", "$lang{TRAFFIC} ", "$lang{TRAFFIC} 2", $lang{DURATION}, $lang{SUM});
      @field_align = ('right', 'right', 'right', 'right', 'right', 'right', 'right');
    }

    $graph_type = 'month_stats';

    if ($type eq 'USER') {
      $caption[0] = "$lang{USER}";
    }
    if ($type eq 'COMPANIES') {
      $caption[0] = "$lang{COMPANIES}";
    }
    elsif ($type eq 'TERMINATE_CAUSE') {
      $caption[0] = "$lang{ERROR}";
      @CHART_TYPE = ('pie');
      $graph_type = 'pie';
    }
    elsif ($type eq 'TP') {
      $caption[0] = "$lang{TARIF_PLAN}";
      @CHART_TYPE2 = ('column', 'line');
      $CHART{AXIS_CATEGORY_skip} = 0;
    }
    elsif ($type eq 'GID') {
      @CHART_TYPE2 = ('column', 'line');
      $CHART{AXIS_CATEGORY_skip} = 0;

      $caption[0] = $lang{GROUPS};
      my $list2 = $users->groups_list();

      foreach my $line (@$list2) {
        $GROUP_NAMES{ $line->[0] } = $line->[1];
      }

    }
    elsif ($FORM{TP_ID}) {
      $caption[0]     = "$lang{LOGINS}";
      $field_align[0] = 'left';
    }

    $table_sessions = $html->table(
      {
        width      => '100%',
        caption    => "$lang{SESSIONS}",
        title      => \@caption,
        cols_align => \@field_align,
        qs         => $pages_qs,
        ID         => 'DV_REPORTS_SESSIONS'
      }
    );

    my $num  = 0;
    $list = $Sessions->reports({%LIST_PARAMS, COLS_NAME => undef });

    foreach my $line (@$list) {
      my @rows = ();
      if ($FORM{FIELDS}) {
        for ($i = 0 ; $i <= $#caption ; $i++) {
          if ($fields_arr[$i] =~ /TRAFFIC/) {
            push @rows, int2byte($line->[$i], { DIMENSION => $FORM{DIMENSION} });
          }
          elsif ($fields_arr[$i] =~ /USERS/ || $fields_arr[$i] =~ /USERS_FIO/) {
            push @rows, $html->button("$line->[$i]", "index=11&UID=" . ($line->[ $#fields_arr + 1 ]));
          }
          elsif ($fields_arr[$i] =~ /^_/ && ref($INFO_LISTS{ $fields_arr[$i] }) eq 'HASH') {
            push @rows, ($INFO_LISTS{ $fields_arr[$i] }{ $line->[$i] }) ? $INFO_LISTS{ $fields_arr[$i] }{ $line->[$i] } : '';
          }
          elsif ($fields_arr[$i] =~ 'TP') {
            if (scalar keys %TP_NAMES == 0) {
              $list = $Tariffs->list({ MODULE => 'Dv', NEW_MODEL_TP => 1, COLS_NAME => 1 });
              foreach my $line2 (@$list) {
                $TP_NAMES{ $line2->{id} } = $line2->{name};
              }
            }

            push @rows, (($type eq 'TP') ? $line->{id} : $line->{name})
                . '. ' . $html->button($TP_NAMES{ (($type eq 'TP') ? $line->{id} : $line->{name}) }, "index=$index&TP_ID=" . (($type eq 'TP') ? $line->{id} : $line->{name}) . "$pages_qs");
          }
          elsif ($fields_arr[$i] =~ 'GID') {
            push @rows, $line->[0] . '. ' . $html->button($GROUP_NAMES{ $line->[0] }, "index=$index&GID=$line->[0]$pages_qs");
          }
          else {
            push @rows, $line->[$i];
          }
        }
      }
      else {
        my $button = '';
        if ($type eq 'USER') {
          $button = $html->button($line->[0], "index=11&UID=$line->[7]");
        }
        elsif ($type eq 'TP') {
          $button = $line->[0] . '. ' . $html->button($TP_NAMES{ $line->[0] }, "index=$index&TP_ID=$line->[0]$pages_qs");
        }
        elsif ($type eq 'COMPANIES') {
          $button = $html->button("$line->[0]", "index=13&COMPANY_ID=$line->[8]");
        }
        elsif ($type eq 'GID') {
          $button = $line->[0] . '. ' . $html->button($GROUP_NAMES{ $line->[0] }, "index=$index&GID=$line->[0]$pages_qs");
        }
        elsif ($FORM{TP_ID}) {
          $button = $html->button("$line->[0]", "index=11&$type=$line->[0]&UID=$line->[7]");
        }
        elsif ($type eq 'TERMINATE_CAUSE') {
          $button = $html->button($ACCT_TERMINATE_CAUSES_REV->{ $line->[0] }, "index=$index&$type=$line->[0]&TERMINATE_CAUSE=$line->[0]$pages_qs");

          $DATA_HASH{TYPE}[ $num + 1 ] = $line->[3];
          $CHART{X_TEXT}[$num] = $line->[0];

          $num++;
        }
        else {
          $button = $html->button($line->[0], "index=$index&$type=$line->[0]$pages_qs");
        }

        @rows = ($button, $line->[1], $line->[2], int2byte($line->[3], { DIMENSION => $FORM{DIMENSION} }), int2byte($line->[4], { DIMENSION => $FORM{DIMENSION} }), $line->[5], $html->b($line->[6]));

        if ($type ne 'TERMINATE_CAUSE') {
          $AVG{USERS} = $line->[1] if ($AVG{USERS} && $AVG{USERS} < $line->[1]);
          $AVG{TRAFFIC} = $line->[3] if ($AVG{TRAFFIC} && $AVG{TRAFFIC} < $line->[3]);

          $AVG{DURATION} = time2sec($line->[5]) if ($AVG{DURATION} < time2sec($line->[5]));
          $AVG{MONEY}    = $line->[6]           if ($AVG{MONEY} < $line->[6]);

          if ($line->[0] =~ /(\d+)-(\d+)-(\d+)/) {
            $num = $3;
          }
          elsif ($line->[0] =~ /(\d+)-(\d+)/) {
            $CHART{X_LINE}[$num] = $line->[0];
            $num++;
          }
          else {
            $CHART{X_TEXT}[$num] = $line->[0];
            $num++;
          }

          $DATA_HASH{USERS}[$num]     = $line->[1];
          $DATA_HASH2{TRAFFIC}[$num]  = $line->[3];
          $DATA_HASH2{DURATION}[$num] = time2sec($line->[5]);
          $DATA_HASH{MONEY}[$num]     = $line->[6];
        }
      }

      $table_sessions->addrow(@rows);
    }

    if ($graph_type ne 'pie') {

      $output = $html->make_charts(
        {
          PERIOD        => $graph_type,
          DATA          => \%DATA_HASH2,
          AVG           => \%AVG,
          TYPE          => \@CHART_TYPE2,
          TRANSITION    => 1,
          OUTPUT2RETURN => 1,
          %CHART
        }
      );
    }
  }

  my $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right', 'right', 'right', 'right', 'right' ],
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

          "$lang{DURATION}: " . $html->b($Sessions->{DURATION}),
          "$lang{SUM}: " . $html->b($Sessions->{SUM})
        ]
      ],
      rowcolor => 'even'
    }
  );

  print $table_sessions->show() . $table->show();

  $table = $html->table({ rows => [ [$output] ] });
  print $table->show();

  if ($graph_type ne '') {
    $html->make_charts(
      {
        PERIOD     => $graph_type,
        DATA       => \%DATA_HASH,
        AVG        => \%AVG,
        TYPE       => \@CHART_TYPE,
        TRANSITION => 1,
        %CHART
      }
    );
  }

  return 1;
}

#**********************************************************
=head2 dv_report_use();

=cut
#**********************************************************
sub dv_report_use {

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

  $Sessions->{debug}=1 if ($FORM{DBEUG});
  my Abills::HTML $table;
  our %DATA_HASH;
  ($table, $list) = result_former({
    INPUT_DATA      => $Sessions,
    FUNCTION        => 'reports2',
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'USERS_COUNT,SESSIONS_COUNT,TRAFFIC_RECV,TRAFFIC_SENT,DURATION_SEC,SUM',
    SKIP_USER_TITLE => (! $FORM{TYPE} || $FORM{TYPE} ne 'USER') ? 1 : undef,
    SELECT_VALUE    => {
      terminate_cause => dv_terminate_causes({ REVERSE => 1 }),
      gid             => sel_groups({ HASH_RESULT => 1 }),
      tp_id           => \%TP_NAMES
    },
    CHARTS       => 'users_count,sessions_count,traffic_recv,traffic_sent,duration_sec',
    CHARTS_XTEXT => 'auto', #$x_text,
    EXT_TITLES   => \%ext_fields,
    FILTER_COLS  => {
      duration_sec    => 'sec2time_str',
      traffic_recv    => 'int2byte',
      traffic_sent    => 'int2byte',
      traffic_sum     => 'int2byte',
      terminate_cause => "search_link:dv_report_use:TERMINATE_CAUSE,$pages_qs",
      company_name    => "search_link:dv_report_use:COMPANY_NAME,$pages_qs",
      tp_id           => "search_link:dv_report_use:TP_ID,$pages_qs",
      month           => "search_link:dv_report_use:MONTH,$pages_qs",
      gid             => "search_link:dv_report_use:GID,$pages_qs",
      date            => "search_link:dv_report_use:DATE,DATE",
      login           => "search_link:from_users:UID,type=1,$pages_qs",
      build           => "search_link:dv_report_use:LOCATION_ID,LOCATION_ID,TYPE=USER,$pages_qs",
      district_name   => "search_link:dv_report_use:DISTRICT_ID,DISTRICT_ID,TYPE=USER,$pages_qs",
      street_name     => "search_link:dv_report_use:STREET_ID,STREET_ID,TYPE=USER,$pages_qs",
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
      cols_align => [ 'right', 'right', 'right', 'right', 'right', 'right' ],
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
=head2 dv_report_debetors($attr)

=cut
#**********************************************************
sub dv_report_debetors {

  result_former({
    INPUT_DATA      => $Dv,
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
      'dv_status'   => "Internet $lang{STATUS}",
      'dv_status_date' => "$lang{STATUS} $lang{DATE}",
      'online'      => 'Online',
      'dv_expire'   => "Internet $lang{EXPIRE}",
      'dv_login'    => "$lang{SERVICE} $lang{LOGIN}",
      'dv_password' => "$lang{SERVICE} $lang{PASSWD}"
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
=head2 dv_report_tp()

=cut
#**********************************************************
sub dv_report_tp {

  my $list = $Dv->report_tp({ %LIST_PARAMS,
    COLS_NAME => 1 });

  my $table = $html->table(
    {
      caption     => $lang{TARIF_PLANS},
      width       => '100%',
      title       => [ "#", "$lang{NAME}", "$lang{TOTAL}", "$lang{ACTIV}", "$lang{DISABLE}",
        "$lang{DEBETORS}", "ARPPU $lang{ARPPU}", "ARPU $lang{ARPU}" ],
      cols_align  => [ 'left', 'right', 'right', 'right', 'right', 'right' ],
      ID          => 'REPORTS_TARIF_PLANS'
    }
  );

  my $dv_users_list_index = get_function_index('dv_users_list') || 0;

  my ($total_users, $totals_active, $total_disabled, $total_debetors)=(0,0,0,0);
  foreach my $line (@$list) {
    $line->{id} = 0 if (! defined($line->{id}));
    $table->addrow(
      $line->{id},
      $html->button($line->{name}, "index=$dv_users_list_index&TP_NUM=$line->{id}"),
      $html->button($line->{counts}, "index=$dv_users_list_index&TP_NUM=$line->{id}"),
      $html->button($line->{active}, "index=$dv_users_list_index&TP_NUM=$line->{id}&DV_STATUS=0"),
      $html->button($line->{disabled}, "index=$dv_users_list_index&TP_NUM=$line->{id}&DV_STATUS=1"),
      $html->button($line->{debetors}, "index=$dv_users_list_index&TP_NUM=$line->{id}&DEPOSIT=<0&search=1"),
      $line->{arppu},
      $line->{arpu}
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

1;