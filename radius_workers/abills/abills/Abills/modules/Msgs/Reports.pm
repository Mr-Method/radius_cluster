=head2 NAME

  Msgs Reports

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(date_inc days_in_month sec2time);

our Msgs $Msgs;
our(
  $db,
  %conf,
  $html,
  %lang,
  $admin,
  @MONTHES
);

#**********************************************************
=head2 msgs_reports()

=cut
#**********************************************************
sub msgs_reports {

  reports(
    {
      DATE_RANGE=> 1,
      DATE      => $FORM{DATE},
      REPORT    => '',
      EX_PARAMS => {
        DATE   => $lang{DATE},
        USERS  => $lang{USERS},
        ADMINS => $lang{ADMINS},
      },
      PERIOD_FORM => 1,
      EXT_TYPE    => {
        ADMINS     => $lang{ADMINS},
        RESPOSIBLE => $lang{RESPOSIBLE},
        CHAPTERS   => $lang{CHAPTERS},
        PER_MONTH  => $lang{PER_MONTH},
        DISTRICT   => $lang{DISTRICT},
        STREET     => $lang{STREET},
        BUILD      => $lang{BUILD},
        REPLY      => $lang{REPLY},
        PER_CLOSED => $lang{CLOSED},
      },
      # FIELDS => {
      #   "1:STATE" => $lang{OPEN},
      #   "2:STATE" => $lang{CLOSED_UNSUCCESSFUL},
      #   "3:STATE" => $lang{CLOSED_SUCCESSFUL}
      # },
    }
  );
  if ($FORM{TYPE} && $FORM{TYPE} eq 'PER_CLOSED') {
    report_per_month();
    return 1;
  }
  my ($table_sessions);
  my $output = '';
  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });
  my %msgs_status_without_color = map { $_ => [split(':', $msgs_status->{$_})]->[0] } keys %$msgs_status;
  
  my %DATA_HASH2 = ();
  my %CHARTS = (
    TYPES => {
      $html->color_mark($msgs_status->{0} || '') => 'column',
      $html->color_mark($msgs_status->{1} || '') => 'column',
      $html->color_mark($msgs_status->{2} || '') => 'column',
      $lang{OTHER}      => 'column',
      $lang{COUNT}      => 'line'
    }
  );

  my $graph_type = '';
  #Day reposrt
  if ($FORM{DATE} || $FORM{DAYS}) {
    if (!defined($FORM{sort})) {
      $LIST_PARAMS{SORT} = 1;
      $LIST_PARAMS{DESC} = 'DESC';
    }

    $index = get_function_index('msgs_admin');
    $FORM{ALL_MSGS}=1;
    $LIST_PARAMS{STATE} = $FORM{STATE}  if ($FORM{STATE} );
    msgs_list();
    return 1;
  }
  else {
    my $type   = $FORM{TYPE} || '';
    my @caption = ($lang{DATE},
      $html->color_mark($msgs_status->{0}),
      $html->color_mark($msgs_status->{1}),
      $html->color_mark($msgs_status->{2}),
      $lang{OTHER}, $lang{COUNT},
      $lang{RUN_TIME});

    if ( $type eq 'ADMINS' ){
      $caption[0] = $lang{ADMINS};
    }
    elsif ( $type eq 'HOURS' ){
      $caption[0] = $lang{HOURS};
      $graph_type = 'hour';
    }
    elsif ( $type eq 'USER' ){
      $caption[0] = $lang{USERS};
      $pages_qs .= "&TYPE=USER"
    }
    elsif ( $type eq 'RESPOSIBLE' ){
      $caption[0] = $lang{RESPOSIBLE};
    }
    elsif ( $type eq 'CHAPTERS' ){
      $caption[0] = $lang{CHAPTERS};
      $CHARTS{TYPES}{$lang{COUNT}} = 'pie';
    }
    elsif ( $type eq 'DISTRICT' ){
      $caption[0] = $lang{DISTRICT};
      $graph_type = '';
    }
    elsif ( $type eq 'STREET' ){
      $caption[0] = $lang{STREET};
      $graph_type = '';
    }
    elsif ( $type eq 'BUILD' ){
      $caption[0] = $lang{BUILDS};
      $graph_type = '';
    }
    elsif ( $type eq 'REPLY' ){
      $type = undef;
      $caption[$#caption+1] = $lang{REPLY};
      $graph_type = '';
    }
    else{
      $graph_type = 'month_stats';
    }

    $table_sessions = $html->table({
      width      => '100%',
      caption    => $lang{MESSAGES},
      title      => \@caption,
      qs         => $pages_qs,
      ID         => 'MSGS_REPORT'
    });

    my $num = -1;
    my $list = $Msgs->messages_reports({
      %LIST_PARAMS,
      COLS_NAME =>  0
    });

    foreach my $line (@$list) {
      my @rows = ();
      my $first_field = $html->button($line->[0], "index=$index&". ($type || 'DATE') ."=". ($line->[0] || q{}) . $pages_qs);
      if ($type) {
        if ($type eq 'USER') {
          $first_field = $html->button($line->[0], "index=15&UID=$line->[7]");
          $num++;
          $CHARTS{X_TEXT}[$num] = $line->[0];
        }
        elsif ($type eq 'HOURS') {
          $num = $line->[0];
        }
        elsif ($type eq 'ADMINS' || $type eq 'RESPOSIBLE') {
          $first_field = $html->button($line->[0], "index=$index&RESPOSIBLE=". ($line->[0] || q{}));
          $num++;
          $CHARTS{X_TEXT}[$num] = $line->[0];
        }
        elsif ($type eq 'CHAPTERS') {
          $first_field = $html->button($line->[0], "index=$index&CHAPTER_ID=$line->[8]");
          $num++;
          $CHARTS{X_TEXT}[$num] = $line->[0];
        }
        else {
          $num++;
          $CHARTS{X_TEXT}[$num] = $line->[0];
        }
      }
      if (! $type || $type eq 'DAYS') {
        @rows = ($first_field,
          $html->button( $line->[1], "index=$index&STATE=0&DATE=$line->[0]"),
          $html->button( $line->[2], "index=$index&STATE=1&DATE=$line->[0]"),
          $html->button( $line->[3], "index=$index&STATE=2&DATE=$line->[0]"),
          $html->button( $line->[4], "index=$index&STATE=>2&DATE=$line->[0]"),
          $line->[5],
          $line->[6]);
      }
      else {
        @rows = ($first_field,
          $line->[1],
          $line->[2],
          $line->[3],
          $line->[4],
          $line->[5],
          $line->[6]);
      }

      if($#caption == 7) {
        push @rows, $line->[7];
      }

      if ($line->[0] && $line->[0] =~ /(\d+)-(\d+)-(\d+)/) {
        $num = int($3);
      }
      elsif ($line->[0] && $line->[0] =~ /(\d+)-(\d+)/) {
        $num++;
        $CHARTS{X_LINE}[$num] = $line->[0];
      }

      $DATA_HASH2{ $msgs_status_without_color{0} }[$num] = $line->[1];
      $DATA_HASH2{ $msgs_status_without_color{1} }[$num] = $line->[2];
      $DATA_HASH2{ $msgs_status_without_color{2} }[$num] = $line->[3];
      $DATA_HASH2{$lang{OTHER}}[$num] = $line->[4];
      $DATA_HASH2{$lang{COUNT}}[$num] = $line->[5];

      $table_sessions->addrow(@rows);
    }

    $output = $html->make_charts({
      PERIOD        => $graph_type,
      DATA          => \%DATA_HASH2,
      TRANSITION    => 1,
      OUTPUT2RETURN => 1,
      %CHARTS
    });
  }
  
  my $table = $html->table({
    width      => '100%',
    rows       =>
    [
      [
      $html->color_mark( $msgs_status->{0} || '' ) . ': ' . $html->b( $Msgs->{OPEN} ),
      $html->color_mark( $msgs_status->{1} || '' ) . ": " . $html->b( $Msgs->{UNMAKED} ),
      $html->color_mark( $msgs_status->{2} || '' ) . ': ' . $html->b( $Msgs->{MAKED} ),
      
      "$lang{OTHER}: " . $html->b( $Msgs->{OTHER} ),
      "$lang{COUNT}: " . $html->b( $Msgs->{TOTAL} ),
      "$lang{RUN_TIME}: " . $html->b( $Msgs->{RUN_TIME} )
      ]
    ],
    rowcolor   => 'total'
  });

  print $table_sessions->show() . $table->show() . $output;

  return 1;
}

#**********************************************************
=head2 reports_tasks_rating () -

  Arguments:
    $attr -
  Returns:1

  Examples:

=cut
#**********************************************************
sub msgs_reports_tasks_rating {

  my %statistic;
  my %statistic_id;
  my %admin_name;
  my $admin_id_string = '';

  my $msg_list = $Msgs->messages_list(
    {
      ID          => '_SHOW',
      RATING      => '_SHOW',
      UID         => '_SHOW',
      ADMIN_LOGIN => '_SHOW',
      A_NAME      => '_SHOW',
      RESPOSIBLE  => '_SHOW',
      STATE_ID    => '1;2',
      PAGE_ROWS   => 18446744073709551615,
      COLS_NAME   => 1
    }
  );

  foreach my $msg (@$msg_list) {
    if (!defined($statistic{ $msg->{resposible} }{rating_1})) {
      $admin_id_string .= "$msg->{resposible};";
    }
    if (defined($msg->{rating})) {
      if ($msg->{rating} == 1) {
        $statistic{ $msg->{resposible} }{rating_1} += 1;
      }
      elsif ($msg->{rating} == 2) {
        $statistic{ $msg->{resposible} }{rating_2} += 1;
      }
      elsif ($msg->{rating} == 3) {
        $statistic{ $msg->{resposible} }{rating_3} += 1;
      }
      elsif ($msg->{rating} == 4) {
        $statistic{ $msg->{resposible} }{rating_4} += 1;
      }
      elsif ($msg->{rating} == 5) {
        $statistic{ $msg->{resposible} }{rating_5} += 1;
      }

      $statistic{ $msg->{resposible} }{rating_1} //= 0;
      $statistic{ $msg->{resposible} }{rating_2} //= 0;
      $statistic{ $msg->{resposible} }{rating_3} //= 0;
      $statistic{ $msg->{resposible} }{rating_4} //= 0;
      $statistic{ $msg->{resposible} }{rating_5} //= 0;

      if ($msg->{rating} > 0) {
        $statistic_id{ $msg->{resposible} } += 1;
        $statistic{ $msg->{resposible} }{rating_sum} += $msg->{rating};
        $statistic{ $msg->{resposible} }{midl_rating_sum} = $statistic{ $msg->{resposible} }{rating_sum} / $statistic_id{ $msg->{resposible} };
      }
      else{
        $statistic{ $msg->{resposible} }{rating_sum} += 0;
        $statistic{ $msg->{resposible} }{midl_rating_sum} = 0;
      }
    }
  }
  my $table = $html->table(
    {
      caption => $html->element('i', '', { class => 'fa fa-fw fa-bar-chart', style => 'font-size:28px;' }) . '&nbsp' . $lang{EVALUATION_OF_PERFORMANCE},
      title_plain => [ "$lang{ADMIN}", "$lang{AVERAGE_RATING}", "1", "2", "3", "4", "5" ],
      width       => '100%',
      qs          => $pages_qs,
      ID          => 'LIST_OF_LOGS_TABLE',
    }
  );

  my $admin_list = $admin->list(
    {
      AID       => $admin_id_string,
      LOGIN     => '_SHOW',
      PAGE_ROWS => 50000,
      COLS_NAME => 1
    }
  );

  foreach my $admin_ (@$admin_list) {
    $admin_name{ $admin_->{aid} } = $admin_->{login};
  }

  foreach my $statistic_key (reverse sort { $statistic{$a}->{midl_rating_sum} <=> $statistic{$b}->{midl_rating_sum} } keys %statistic) {
    $table->addrow(
      $html->button($admin_name{$statistic_key} ? $admin_name{$statistic_key} : $lang{ALL},
        "index=" . get_function_index('employees_main') . "&subf=51&AID=$statistic_key"
      ),
        ($statistic{$statistic_key}{midl_rating_sum}) ? ($statistic{$statistic_key}{midl_rating_sum} =~ m|.{4}| ? $& : $statistic{$statistic_key}{midl_rating_sum}) : 0,
      $statistic{$statistic_key}{rating_1},
      $statistic{$statistic_key}{rating_2},
      $statistic{$statistic_key}{rating_3},
      $statistic{$statistic_key}{rating_4},
      $statistic{$statistic_key}{rating_5},
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 msgs_report_menu()

  Arguments:
    $attr -
      FROM_DATE
      TO_DATE
      ADMINS_LOGIN

  Returns:1

  Examples:

=cut
#**********************************************************
sub msgs_report_menu {
  my ($attr) = @_;

  my %admin_name;
  my %date;

  if( $attr->{FROM_DATE} && $attr->{TO_DATE} ){
    %date = (
        FROM_DATE => $attr->{FROM_DATE} .= ' 00:00:01',
        TO_DATE   => $attr->{TO_DATE}   .= ' 23:59:59',
    );
  }

  my $admins_list = $Msgs->admins_list(
    {
      AID                     => '_SHOW',
      PAGE_ROWS               => 10000,
      COLS_NAME               => 1,
      DISABLE                 => '0',
    }
  );

  foreach my $line (@{$admins_list}) {
    $admin_name{$line->{aid}}      = $line->{admin_login};
  }

  my $admin_select = $html->form_select(
    'ADMINS_LOGIN',
    {
      SEL_HASH    => \%admin_name,
      SEL_OPTIONS => { '' => $lang{ALL} },
      SELECTED    => $attr->{ADMINS_LOGIN} || '',
      MULTIPLE    => 1,
    }
  );

  reports(
    {
      DATE_RANGE        => 1,
      REPORT            => '',
      NO_GROUP          => 1,
      NO_STANDART_TYPES => 1,
      NO_TAGS           => 1,
      EXT_SELECT_NAME   => $lang{ADMINS},
      EXT_SELECT        => $admin_select,
      PERIOD_FORM       => 1,
      EXT_TYPE          => { ADMINS => $lang{ADMINS} },
    }
  );

  return 1;
}

#**********************************************************
=head2 msgs_reports_requests()

=cut
#**********************************************************
sub msgs_reports_requests {
  my %admin_name;
  my @x_column_name;
  my %COLUMN;
  my %date;

  if( $FORM{FROM_DATE} && $FORM{TO_DATE} ){
    %date = (
        FROM_DATE => $FORM{FROM_DATE} . ' 00:00:01',
        TO_DATE   => $FORM{TO_DATE}   . ' 23:59:59',
    );
  }

  my $admins_list = $Msgs->admins_list(
    {
      AID                     => '_SHOW',
      PAGE_ROWS               => 10000,
      COLS_NAME               => 1,
    }
  );

  foreach my $line (@{$admins_list}) {
    $admin_name{$line->{aid}}      = $line->{admin_login};
  }

  my $admin_select = $html->form_select(
    'ADMINS_LOGIN',
    {
      SEL_HASH    => \%admin_name,
      SEL_OPTIONS => { '' => '' },
      SELECTED    => $FORM{ADMINS_LOGIN} || '',
    }
  );

  reports(
    {
      DATE_RANGE        => 1,
      REPORT            => '',
      NO_GROUP          => 1,
      NO_STANDART_TYPES => 1,
      NO_TAGS           => 1,
      EXT_SELECT_NAME   => $lang{ADMINS},
      EXT_SELECT        => $admin_select,
      PERIOD_FORM       => 1,
      EXT_TYPE          => { ADMINS => $lang{ADMINS} },
    }
  );

  my $msgs_list = $Msgs->messages_admins_reports(
    {
      AID                     => $FORM{ADMINS_LOGIN},
      %date,
      PAGE_ROWS               => 10000,
      COLS_NAME               => 1,
    }
  );

  if(! $Msgs->{TOTAL}) {
    $html->message('warning', $lang{WARNING}, $lang{NO_DATA});
    return 0;
  }

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });

  if(! defined($msgs_status->{0})) {
    $html->message('warn', "", "Please add default status 'OPEN' with ID 0 ". $html->button('Msgs status',
        "index=". get_function_index('msgs_status') ));
    return 0;
  }

  my %column_type = (
    $msgs_status->{0}  => 'COLUMN',
    $msgs_status->{1}  => 'COLUMN',
    $msgs_status->{2}  => 'COLUMN',
    $msgs_status->{3}  => 'COLUMN',
    $msgs_status->{11} => 'COLUMN',
    $lang{TOTAL}       => 'COLUMN',
  );

  my $i=-1;
  
  my $table = $html->table({
      width      => '100%',
      title      => [ "$lang{ADMIN}", "$lang{TOTAL}", "$lang{CLOSED}" ],
  });
  
  foreach my $line (@{$msgs_list}) {
    $i++;
    push  @x_column_name,$line->{id};
    $COLUMN{$msgs_status->{0}}->[$i]  = $line->{open};
    $COLUMN{$msgs_status->{1}}->[$i]  = $line->{unmaked};
    $COLUMN{$msgs_status->{2}}->[$i]  = $line->{closed};
    $COLUMN{$msgs_status->{3}}->[$i]  = $line->{in_process};
    $COLUMN{$msgs_status->{11}}->[$i] = $line->{potential_client};
    $COLUMN{$lang{TOTAL}}->[$i]       = $line->{total_msg};
    
    $table->addrow($line->{id}, $line->{total_msg}, $line->{closed});
  }

  print $table->show();
  
  $html->make_charts_simple(
    {
      TRANSITION    => 1,
      TYPES         => \%column_type,
      X_TEXT        => \@x_column_name, # name x admin login
      DATA          => \%COLUMN,
    }
  );
  
  return 1
}

#**********************************************************
=head2 msgs_reports_replys() = Report for replys

  Arguments:
    $attr -

  Return: 1

=cut
#**********************************************************
sub msgs_reports_replys {

  my $Admins = Admins->new($db, \%conf);

  msgs_report_menu(
    {
      TO_DATE      => $FORM{TO_DATE},
      FROM_DATE    => $FORM{FROM_DATE},
      ADMINS_LOGIN => $FORM{ADMINS_LOGIN},
    }
  );

  if ($FORM{ADMINS_LOGIN}) {
    $FORM{ADMINS_LOGIN} =~ s/,/;/g;
  }

  my $admins_list = $Admins->list({
    COLS_NAME => 1, 
    PAGE_ROWS => 1000, 
    DISABLE   => '0',
    AID => $FORM{ADMINS_LOGIN} || '_SHOW' 
  });
  my %date;
  if ($FORM{FROM_DATE} && $FORM{TO_DATE}) {
    %date = (
      FROM_DATE => $FORM{FROM_DATE},
      TO_DATE   => $FORM{TO_DATE},
    );
  }

  my $reply_list = $Msgs->messages_reply_list(
    {
      LOGIN => '_SHOW',
      ADMIN => '_SHOW',
      %date,
      AID => $FORM{ADMINS_LOGIN} || '_SHOW',
      COLS_NAME           => 1,
      PAGE_ROWS           => 10000,
      'FROM_DATE|TO_DATE' => $FORM{FROM_DATE_TO_DATE},
    }
  );

  my @admin_name_array;

  foreach my $admin_info (@$admins_list) {
    push @admin_name_array, $admin_info->{login};
  }

  my $column_type = _make_chart_column_type({ COLUMNS_ARRAY => \@admin_name_array, COLUM_TYPE => 'COLUMN' });
  my ($x_column_name, $chart_date, $name_column_index, $function_ref);

  if ($FORM{FROM_DATE} && $FORM{TO_DATE} && $FORM{FROM_DATE} ne $FORM{TO_DATE}) {
    ($x_column_name, $chart_date, $name_column_index) = _make_x_text_date({ DEFAULT_CHAR_DATA_HASH_NAMES => \@admin_name_array, %FORM });
    $function_ref = \&_msgs_report_reply_date;
  }
  else {
    ($x_column_name, $chart_date, $name_column_index) = _make_x_text_time({ DEFAULT_CHAR_DATA_HASH_NAMES => \@admin_name_array, %FORM });
    $function_ref = \&_msgs_report_reply_time;
  }

  $chart_date = _make_chart_date(
    {
      DATE            => $chart_date,
      NAME_INDEX_JOIN => $name_column_index,
      LIST            => $reply_list,
      CHART_LINE      => \@admin_name_array,
      FUNCTION        => $function_ref,
      CREATE_CHART    => 1,
    }
  );

  print $html->make_charts_simple(
    {
      TRANSITION => 1,
      TYPES      => $column_type,
      X_TEXT     => $x_column_name,
      DATA       => $chart_date,
    }
  );

  return 1;
}

#**********************************************************
=head2 _make_chart_column_type() = make colum type

  Arguments:
    $attr -
      COLUMNS_ARRAY = Columns name : ARRAYREF
      COLUM_TYPE    = Columns name : STRING

  Return: HASHREF with NAME => TYPE

=cut
#**********************************************************
sub _make_chart_column_type {
  my ($attr) = @_;

  my %result_colum_type;

  foreach my $colum_name (@{ $attr->{COLUMNS_ARRAY} }) {
    $result_colum_type{$colum_name} = $attr->{COLUM_TYPE};
  }

  return \%result_colum_type;
}

#**********************************************************
=head2 _msgs_report_reply_date() = filter for columns when form chart date

  Arguments:
    $attr -
      HASHREF
      HASHREF = Hash ref where NAME_OF_X_EXIS = ARRAY INDEX
=cut
#**********************************************************
sub _msgs_report_reply_date {
  my ($line, $join_hash) = @_;
  my ($date, undef) = split(/ /, $line->{datetime});

  if ($join_hash->{$date}) {
    return 1, $join_hash->{$date};
  }
  else {
    return 0, 0;
  }
}

#**********************************************************

=head2 _msgs_report_reply_time() = filter for columns when form chart date

  Arguments:
    $attr -
      HASHREF
      HASHREF = Hash ref where NAME_OF_X_EXIS = ARRAY INDEX

  Examples:

=cut

#**********************************************************
sub _msgs_report_reply_time {
  my ($line, $join_hash) = @_;

  my (undef, $time) = split(/ /, $line->{datetime});
  my ($hour) = split(/:/, $time);

  if ($join_hash->{ $hour . ":00" }) {

    # print $join_hash->{$hour .":00"}."fj";
    return 1, $join_hash->{ $hour . ":00" };
  }
  else {
    return 0, 0;
  }
}

#**********************************************************
=head2 _make_chart_date() = make chart date

  Arguments:
    $attr -
      FUNCTION = function ref; Must return 2 arguments
        1 result - Add to column sum, 2 index of array
      LIST     = array-hash
      NAME_INDEX_JOIN = Hash ref where NAME_OF_X_EXIS = ARRAY INDEX

  Returns: Chart date: Hash of arrays

=cut
#**********************************************************
sub _make_chart_date {
  my ($attr) = @_;

  foreach my $line (@{ $attr->{LIST} }) {

    #Chart lines in 1 X Column
    my ($result, $array_index) = $attr->{FUNCTION}->($line, $attr->{NAME_INDEX_JOIN});
    $attr->{DATE}->{ $line->{admin} }[$array_index] += $result if($line->{admin} && $array_index);
  }

  return $attr->{DATE};
}

#**********************************************************
=head2 _make_x_text_date() = make axis X date

  Arguments:
    $attr -
      DEFAULT_CHAR_DATA_HASH_NAMES = arrays of column names
      FROM_DATE
      TO_DATE
      FROM_DATE_TO_DATE

  Returns: \@x_column_name, \%column_date, \%name_column_index

=cut
#**********************************************************
sub _make_x_text_date {
  my ($attr) = @_;

  my @x_column_name;
  my %column_date;
  my %name_column_index;

  #Check if we have DATE and TIME
  if ($attr->{FROM_DATE_TO_DATE}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = $attr->{FROM_DATE_TO_DATE} =~ /(.+)\/(.+)/;
  }

  if (!($attr->{FROM_DATE} && $attr->{TO_DATE})) {
    $attr->{FROM_DATE}         = $DATE;
    $attr->{TO_DATE}           = $DATE;
    $attr->{FROM_DATE_TO_DATE} = "$DATE/$DATE";
  }

  my $from_date = $attr->{FROM_DATE} || $attr->{TO_DATE} || 1;
  $attr->{TO_DATE} = $attr->{TO_DATE} || $attr->{FROM_DATE} || 1;

  #End of check

  #Increment for array index
  my $date_num = 0;

  push @x_column_name, $attr->{FROM_DATE};

  $name_column_index{ $attr->{FROM_DATE} } = $date_num;

  foreach my $column_date_name (@{ $attr->{DEFAULT_CHAR_DATA_HASH_NAMES} }) {
    $column_date{$column_date_name}[$date_num] = '0.00';
  }

  my $x = 0;
  $date_num++;
  while ($from_date ne $attr->{TO_DATE}) {

    $from_date = date_inc($from_date);

    push @x_column_name, $from_date;

    $name_column_index{$from_date} = $date_num;
    foreach my $column_date_name (@{ $attr->{DEFAULT_CHAR_DATA_HASH_NAMES} }) {
      $column_date{$column_date_name}[$date_num] = '0.00';
    }
    $date_num++;
    ++$x;

    if ($x > 80000) {
      $from_date = $attr->{TO_DATE};
    }
  }

  return \@x_column_name, \%column_date, \%name_column_index;
}

#**********************************************************
=head2 _make_x_text_time() = make axis X times

  Arguments:
    $attr -
      DEFAULT_CHAR_DATA_HASH_NAMES = arrays of column names

  return \@x_column_name, \%column_date, \%name_column_index;

=cut
#**********************************************************
sub _make_x_text_time {
  my ($attr) = @_;

  my @x_column_name;
  my %column_date;
  my %name_column_index;

  my @time = (
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
    '19:00',
    '20:00',
    '21:00',
    '22:00',
    '23:00',
    '00:00',
    '01:00',
    '02:00',
    '03:00',
    '04:00',
    '05:00',
    '06:00',
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
  );

  my $date_num = 0;

  foreach my $time (@time) {

    push @x_column_name, $time;

    foreach my $column_date_name (@{ $attr->{DEFAULT_CHAR_DATA_HASH_NAMES} }) {
      $column_date{$column_date_name}[$date_num] = '0.00';
    }

    $name_column_index{$time} = $date_num;

    $date_num++;
  }

  return \@x_column_name, \%column_date, \%name_column_index;
}

#**********************************************************
=head2 msgs_report_tags() = report of tags popularity

Arguments :

Returns : 1

=cut
#**********************************************************
sub msgs_report_tags {

  reports(
    {
      DATE_RANGE  => 1,
      DATE        => $FORM{DATE},
      PERIOD_FORM => 1,
      NO_TAGS     => 1,
      NO_GROUP    => 1
    }
  );
  
  my %span_hash;
  my $list_tags = $Msgs->messages_quick_replys_list({REPLY => '_SHOW', ID => '_SHOW', COLS_NAME => 1});
  _error_show($Msgs);
  my $total_tags_used = $Msgs->messages_tags_total_count(\%FORM);
  
  my $tags_table = $html->table(
    {
      caption     => $lang{MSGS_TAGS},
      width       => '100%',
      title_plain => [ "", "$lang{NAME}", "$lang{PERCENTAGE}", "$lang{TOTAL}" ],
      ID          => 'MSGS_TAGS_REPORTS',
      # DATA_TABLE => 1,
    }
  );
  foreach my $line (@$list_tags) {
    my $count = $Msgs->messages_report_tags_count({ TAG_ID => $line->{id}, %FORM});
    $line->{count} = $count;
    $span_hash{$line->{id}} = $html->element('span', $line->{reply}, {
      class => 'label',
      style => "background-color:$line->{color};",
    });
  }
  my $plus_button = $html->element('i', "", {
      class => 'fa fa-fw fa-plus-circle tree-button',
      style => 'font-size:16px;color:green;',
    });

  foreach my $line (sort { $b->{count} <=> $a->{count} } @$list_tags) {
    next unless($line->{count});
    my %hash = ();
    foreach my $tag (@$list_tags) {
      next if ($tag->{id} eq $line->{id});
      my $sub_count = $Msgs->messages_report_tags_count({ TAG_ID => $line->{id}, SUBTAG => $tag->{id}, %FORM});
      next unless ($sub_count);
      $hash{$tag->{id}} = $sub_count;
    }
    my $tree = $span_hash{$line->{id}} .
               '<div style="display:none;">' .
               '<div class="panel panel-default">' .
               '<div class="panel-heading">' .
               $span_hash{$line->{id}} .
               ' используется с:</div>' .
               "<table class='table'><tr><th>$lang{NAME}</th><th>$lang{PERCENTAGE}</th></tr>";
    foreach my $k (sort { $hash{$b} <=> $hash{$a} } keys %hash) {
      $tree .= "<tr><td>$span_hash{$k}</td><td>" . 
               $html->progress_bar({
                   TOTAL        => $line->{count},
                   COMPLETE     => $hash{$k},
                   PERCENT_TYPE => 1,
                   COLOR        => 'MAX_COLOR',
                 }) . 
               "</td></tr>";
    }
    $tree .= '</table></div></div>';
    $tags_table->addrow( $plus_button, $tree,
      $html->progress_bar({
        TOTAL        => $total_tags_used,
        COMPLETE     => $line->{count},
        PERCENT_TYPE => 1,
        COLOR        => 'MAX_COLOR',
      }),
      $line->{count}
    );
  }

  my $table = $tags_table->show();

  $html->tpl_show(_include('msgs_tags_report', 'Msgs'), { TABLE => $table });

  return 1;
}

#**********************************************************
=head2 msgs_() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub msgs_admin_time_spend_report {
  #my ($attr) = @_;

  #my $Admins = Admins->new($db, \%conf);

  my $to_date;
  my $from_date;
  if(!$FORM{TO_DATE} && !$FORM{FROM_DATE}){
    my ($y, $m) = split('-', $DATE);
    

    $from_date = "$y-$m-01";
    $to_date   = "$y-$m-" . days_in_month();

    $FORM{FROM_DATE_TO_DATE} = "$from_date/$to_date";
  }
  
  msgs_report_menu(
    {
      TO_DATE      => $FORM{TO_DATE} || $to_date,
      FROM_DATE    => $FORM{FROM_DATE} || $from_date,
      ADMINS_LOGIN => $FORM{ADMINS_LOGIN},
    }
  );

  if ($FORM{ADMINS_LOGIN}) {
    $FORM{ADMINS_LOGIN} =~ s/,/;/g;
    
    my $reply_list = $Msgs->messages_reply_list(
      {
        LOGIN     => '_SHOW',
        ADMIN     => '_SHOW',
        MSG_ID    => '_SHOW',
        FROM_DATE => $FORM{FROM_DATE} || $from_date,
        TO_DATE   => $FORM{TO_DATE} || $to_date,
        AID       => $FORM{ADMINS_LOGIN} || '_SHOW',
        COLS_NAME => 1,
        PAGE_ROWS => 10000,
        # 'FROM_DATE|TO_DATE' => $FORM{FROM_DATE_TO_DATE},
      }
    );

    my %admins_time_per_msg;
    foreach my $reply (@$reply_list){
      $admins_time_per_msg{$reply->{aid}}{admin_login} = $reply->{admin};

      my ($h, $m, $s) = split(':', $reply->{run_time});
      my $seconds_per_reply = ($h * 3600) + ($m * 60) + $s;

      $admins_time_per_msg{$reply->{aid}}{msgs}{$reply->{main_msg}}{answers} = ($admins_time_per_msg{$reply->{aid}}{msgs}{$reply->{main_msg}}{answers} || 0) + 1;

      $admins_time_per_msg{$reply->{aid}}{msgs}{$reply->{main_msg}}{time} = ($admins_time_per_msg{$reply->{aid}}{msgs}{$reply->{main_msg}}{time} || 0) + $seconds_per_reply;

      $admins_time_per_msg{$reply->{aid}}{admin_login} = $reply->{admin};
    }

    my $spend_time_table = $html->table(
      {
        caption    => "$lang{TIME_IN_WORK}",
        width      => '100%',
        title      => [ "$lang{ADMIN}", "$lang{SUBJECT}", "$lang{REPLY} $lang{COUNT}", "$lang{TIME}" ],
        cols_align => [ 'right', 'left', 'center' ],
        ID         => 'ADMIN_SPEND_TIME'
      }
    );
    my $total_time = 0;
    foreach my $aid (sort keys %admins_time_per_msg){
      foreach my $msg (keys %{$admins_time_per_msg{$aid}{msgs}}){
        my $spend_time = sec2time($admins_time_per_msg{$aid}{msgs}{$msg}{time}, {format => 1});
        $total_time += $admins_time_per_msg{$aid}{msgs}{$msg}{time};

        my $msg_info = $Msgs->message_info($msg);

        my $subject_title = ($msg_info->{SUBJECT} || "$lang{NO_SUBJECT}");
        my $subject_button = $html->button("$subject_title", "index=" . get_function_index('msgs_admin') . "&chg=$msg", {});
          

        $spend_time_table->addrow(
          $admins_time_per_msg{$aid}{admin_login}, 
          # $msg, 
          $subject_button,
          $admins_time_per_msg{$aid}{msgs}{$msg}{answers}, 
          $spend_time);
      }
    }

    print $spend_time_table->show();

    my @rows  = [ "$lang{TOTAL} $lang{TIME}:", $html->b(sec2time($total_time, {format => 1})) ];

    my $total_spend_time_table = $html->table(
          {
            width      => '100%',
            cols_align => [ 'right',  'right' ],
            rows       => \@rows
          }
        );
    print $total_spend_time_table->show();
      
  }
  else{
    $FORM{ADMINS_LOGIN} = '!0';

    my $reply_list = $Msgs->messages_reply_list(
      {
        LOGIN     => '_SHOW',
        ADMIN     => '_SHOW',
        MSG_ID    => '_SHOW',
        FROM_DATE => $FORM{FROM_DATE} || $from_date,
        TO_DATE   => $FORM{TO_DATE} || $to_date,
        AID       => $FORM{ADMINS_LOGIN} || '_SHOW',
        COLS_NAME => 1,
        PAGE_ROWS => 10000,
        # 'FROM_DATE|TO_DATE' => $FORM{FROM_DATE_TO_DATE},
      }
    );
    
    my %admins_time_per_msg;
    foreach my $reply (@$reply_list)
    {
      my ($h, $m, $s) = split(':', $reply->{run_time});
      my $seconds_per_reply = ($h * 3600) + ($m * 60) + $s;

      $admins_time_per_msg{$reply->{aid}}{msgs}{$reply->{main_msg}} = ($admins_time_per_msg{$reply->{aid}}{msgs}{$reply->{main_msg}} || 0) + $seconds_per_reply;

      $admins_time_per_msg{$reply->{aid}}{total_time} = ( $admins_time_per_msg{$reply->{aid}}{total_time} || 0) + $seconds_per_reply;

      $admins_time_per_msg{$reply->{aid}}{reply_count} = ($admins_time_per_msg{$reply->{aid}}{reply_count} || 0) + 1;

      $admins_time_per_msg{$reply->{aid}}{admin_login} = $reply->{admin};
    }

    my $spend_time_table = $html->table(
      {
        caption    => "$lang{TIME_IN_WORK}",
        width      => '100%',
        title      => [ "$lang{ADMIN}", "$lang{REPLYS} $lang{COUNT}", "$lang{TIME}", "" ],
        cols_align => [ 'right', 'left', 'center' ],
        ID         => 'ADMIN_SPEND_TIME'
      }
    );

    foreach my $aid ( sort keys %admins_time_per_msg){
      my $show_subjects_button = $html->button(undef, "index=$index&ADMINS_LOGIN=$aid&", {class=> 'info'});

      my $spend_time = sec2time($admins_time_per_msg{$aid}{total_time}, {format => 1});
    
      $spend_time_table->addrow(
        $admins_time_per_msg{$aid}{admin_login}, 
        $admins_time_per_msg{$aid}{reply_count}, 
        # $admins_time_per_msg{$aid}{total_time},
        $spend_time,
        $show_subjects_button
      );
    }
  
    print $spend_time_table->show();
  }

  return 1;
}
  
#**********************************************************
=head2 msgs_admin_statistics()

=cut
#**********************************************************
sub msgs_admin_statistics {

  reports(
    {
      DATE_RANGE  => 1,
      DATE        => $FORM{DATE},
      PERIOD_FORM => 1,
      NO_TAGS     => 1,
      NO_GROUP    => 1
    }
  );

  my ($year, $month, undef) = split('-', $DATE);
  my $period = sprintf("%s-%#.2d", $year, $month);

  my $from_date = $period .'-01';
  my $to_date = $period .'-'.days_in_month({ DATE => $DATE });
  if($FORM{FROM_DATE_TO_DATE}) {
    ($from_date, $to_date) = split(/\//, $FORM{FROM_DATE_TO_DATE});
  }

  #Open
  my $msgs_list = $Msgs->messages_list({
    FROM_DATE              => $from_date,
    TO_DATE                => $to_date,
    RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
    COLS_NAME              => 1,
    PAGE_ROWS              => 100000,
  });

  my $msgs_hash->{0}->{NEW} = 0;
  foreach my $line (@$msgs_list) {
    if ($line->{resposible} && $msgs_hash->{$line->{resposible}}->{NEW}) {
      $msgs_hash->{$line->{resposible}}->{NEW}++;
    }
    elsif ($line->{resposible}) {
      $msgs_hash->{$line->{resposible}}->{NEW} = 1;
    }
    else {
      $msgs_hash->{0}->{NEW}++;
    }
  }

  #Close
  my $msgs_list_closed = $Msgs->messages_list({
    CLOSED_DATE            => ">=$from_date;<=$to_date",
    RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
    RATING                 => '_SHOW',
    COLS_NAME              => 1,
    PAGE_ROWS              => 100000,
  });

  $msgs_hash->{0}->{CLOSED} = 0;
  $msgs_hash->{0}->{RATING} = 0;
  foreach my $line (@$msgs_list_closed) {
    if ($line->{resposible} && $msgs_hash->{$line->{resposible}}->{CLOSED}) {
      $msgs_hash->{$line->{resposible}}->{CLOSED}++;
      $msgs_hash->{$line->{resposible}}->{RATING} += $line->{rating};
    }
    elsif ($line->{resposible}) {
      $msgs_hash->{$line->{resposible}}->{CLOSED} = 1;
      $msgs_hash->{$line->{resposible}}->{RATING} = $line->{rating};
    }
    else {
      $msgs_hash->{0}->{CLOSED}++;
    }
  }

  #Open
  my $msgs_list_open = $Msgs->messages_list({
    STATE                  => 0,
    FROM_DATE              => $from_date,
    TO_DATE                => $to_date,
    RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
    COLS_NAME              => 1,
    PAGE_ROWS              => 100000,
  });

  $msgs_hash->{0}->{OPEN} = 0;
  foreach my $line (@$msgs_list_open) {
    if ($line->{resposible} && $msgs_hash->{$line->{resposible}}->{OPEN}) {
      $msgs_hash->{$line->{resposible}}->{OPEN}++;
    }
    elsif ($line->{resposible}) {
      $msgs_hash->{$line->{resposible}}->{OPEN} = 1;
    }
    else {
      $msgs_hash->{0}->{OPEN}++;
    }
  }

  my $table = $html->table({
    caption    => "$lang{REPORTS} $from_date - $to_date",
    title      => [ "$lang{RESPOSIBLE} $lang{ADMIN}", $lang{NEW}, $lang{CLOSED}, $lang{OPEN}, $lang{AVERAGE_RATING} ],
    ID         => 'MSGS_REPORT'
  });

  my $admin_names = sel_admins({ HASH => 1 });

  my $qs_period = "&search_form=1&search=1&FROM_DATE=$from_date&TO_DATE=$to_date&index=". get_function_index('msgs_admin');

  foreach my $admin_id (sort {lc $a cmp lc $b} keys %$msgs_hash) {
    $table->addrow(
      $admin_names->{$admin_id} || $lang{NO_RESPONSIBLE},
      $html->button($msgs_hash->{$admin_id}->{NEW} || '0',  '&ALL_MSGS=1&RESPOSIBLE='.$admin_id . $qs_period),
      $html->button($msgs_hash->{$admin_id}->{CLOSED} || '0', 'STATE=2&RESPOSIBLE='. $admin_id . $qs_period),
      $msgs_hash->{$admin_id}->{OPEN} || '0',
      ($msgs_hash->{$admin_id}->{RATING} && $msgs_hash->{$admin_id}->{CLOSED}
        ? sprintf("%.2f", $msgs_hash->{$admin_id}->{RATING} / $msgs_hash->{$admin_id}->{CLOSED})
        : 0
      ),
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 report_per_month()

=cut
#**********************************************************
sub report_per_month {

  $FORM{TYPE} = 'PER_MONTH';

  if ($FORM{FROM_DATE} eq $FORM{TO_DATE}) {
    my ($y) = $FORM{FROM_DATE} =~ m/(\d{4})/;
    $y--;
    $FORM{FROM_DATE} =~ s/(\d{4})/$y/;
  }
  my @x_column_name;
  my $date_num = 0;
  my %column_date = ();
  my %column_date2 = ();

  my $closed_list = $Msgs->messages_report_closed({
    F_DATE => $FORM{FROM_DATE},
    T_DATE => $FORM{TO_DATE},
  });

  my $msgs_list = $Msgs->messages_reports({
    %LIST_PARAMS,
    TYPE      => 'PER_MONTH',
    COLS_NAME => 1
  });

  my %result = ();

  foreach my $line (@$closed_list) {
    $result{$line->{month}} = {
      closed_msgs    => $line->{total_msgs},
      average_replys => (($line->{total_msgs} && $line->{total_replys} ) ? $line->{total_replys} / $line->{total_msgs} : 0),
      average_time   => sec2time((($line->{total_msgs} && $line->{run_time} )? $line->{run_time} / $line->{total_msgs} : 0), {str => 1}),
      average_rating => (($line->{total_msgs} && $line->{total_rating}) ? $line->{total_rating} / $line->{total_msgs} : 0),
    };
  }

  foreach my $line (@$msgs_list) {
    $result{$line->{month}}{total_msgs} = $line->{total_msgs};
  }

  my $table = $html->table({
    width       => '100%',
    caption     => $lang{MESSAGES},
    title_plain => [$lang{DATE}, $lang{NEW}, $lang{CLOSED}, $lang{REPLYS_AVERAGE}, $lang{TIME_AVERAGE}, $lang{AVERAGE_SCORE_FOR_CLOSED_BIDS}, $lang{CLOSED_RATIO} ],
    qs          => $pages_qs,
    ID          => 'MSGS_REPORT',
    EXPORT      => 1,
    
  });

  foreach my $month (sort keys %result) {
    my $succ_perc = ($result{$month}{closed_msgs} && $result{$month}{total_msgs}) ? (100 * $result{$month}{closed_msgs} / $result{$month}{total_msgs}) : 0;
    $table->addrow(
      $month,
      $result{$month}{total_msgs},
      $result{$month}{closed_msgs},
      sprintf("%.2f", $result{$month}{average_replys} || 0),
      $result{$month}{average_time} || 0,
      sprintf("%.2f", $result{$month}{average_rating} || 0),
      sprintf("%.2f", $succ_perc),
    );
    push @x_column_name, $month;
    $column_date{$lang{NEW}}[$date_num] = $result{$month}{total_msgs};
    $column_date{$lang{CLOSED}}[$date_num] = $result{$month}{closed_msgs};
    $column_date2{$lang{CLOSED_RATIO}}[$date_num++] = sprintf("%.2f", $succ_perc);

  }

  print $table->show();

  $html->make_charts_simple(
    {
      TRANSITION    => 1,
      TYPES         => { $lang{NEW} => 'LINE', $lang{CLOSED} => 'LINE'},
      X_TEXT        => \@x_column_name,
      DATA          => \%column_date,
      TITLE         => "$lang{MESSAGES}, $lang{COUNT}",
    }
  );
  $html->make_charts_simple(
    {
      TRANSITION    => 1,
      TYPES         => { $lang{CLOSED_RATIO} => 'LINE'},
      X_TEXT        => \@x_column_name,
      DATA          => \%column_date2,
      TITLE         => $lang{CLOSED_RATIO},
    }
  );

  return 1;
}

#**********************************************************
=head2 msgs_templates_report()

=cut
#**********************************************************
sub msgs_templates_report {

  my $form = $html->form_input('index', $index, { TYPE => 'hidden' });
  $form .= $html->element('div', "", { class => "col-md-4" } );
  $form .= $html->element('div', msgs_survey_sel(), { class => "col-md-4" } );
  $form .= $html->element('div', $html->form_input('show', $lang{SHOW}, { TYPE => 'submit' }), { class => "col-md-1" } );
  $form = $html->element('div', $form, { class => "row" } );
  $form = $html->element('form', $form, { action => "$SELF_URL" } ) . $html->br() . $html->br();
  print $form;

  return 1 if (!$FORM{SURVEY_ID});

  my $survey_id = $FORM{SURVEY_ID};

  $Msgs->survey_questions_list({ LIST2HASH => 'id,question'});

  my $q_hash = $Msgs->{list_hash};

  my $list = $Msgs->survey_answer_list({ SURVEY_ID => $survey_id });

  my $table = $html->table({ 
    width       => '100%',
    title_plain => [$lang{USER}, $lang{QUESTION}, $lang{COMMENTS}],
    DATA_TABLE  => 1,
    DT_CLICK    => 1,
    ID          => "template_report"
  });

  foreach my $line (@$list) {
    next unless ($line->{comments});
    $table->addrow($line->{login}, $q_hash->{$line->{question_id}}, $line->{comments})
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 report_replys_and_time()

=cut
#**********************************************************
sub report_replys_and_time {

  my $date_num = 0;
  my %column_date = ();
  my %column_date2 = ();
  my @x_column_name;

  my %admin_name;

  my $admins_list = $Msgs->admins_list({
    AID                     => '_SHOW',
    PAGE_ROWS               => 10000,
    COLS_NAME               => 1,
    DISABLE                 => '0',
  });

  foreach my $line (@{$admins_list}) {
    $admin_name{$line->{aid}}      = $line->{admin_login};
  }

  my $admin_select = $html->form_select(
    'AID',
    {
      SEL_HASH    => \%admin_name,
      SELECTED    => $FORM{AID} || '',
    }
  );

  reports(
    {
      DATE_RANGE        => 1,
      REPORT            => '',
      NO_GROUP          => 1,
      NO_STANDART_TYPES => 1,
      NO_TAGS           => 1,
      EXT_SELECT_NAME   => $lang{ADMIN},
      EXT_SELECT        => $admin_select,
      PERIOD_FORM       => 1,
      EXT_TYPE          => { ADMINS => $lang{ADMINS} },
    }
  );

  return 1 unless ($FORM{AID});

  my $table = $html->table({ 
    caption     => $admin_name{$FORM{AID}},
    width       => '100%',
    title_plain => [$lang{MONTH}, $lang{REPLYS}, $lang{TIME}],
    ID          => "replys_and_time_report"
  });

  my $reply_list = $Msgs->messages_report_replys_time(\%FORM);
  foreach my $line (@$reply_list) {
    push @x_column_name, $line->{month};
    $table->addrow(
      $line->{month},
      $line->{replys},
      sec2time($line->{run_time}, {str => 1})
    );
    $column_date{$lang{REPLYS}}[$date_num] = $line->{replys};
    $column_date2{$lang{TIME}}[$date_num++] = $line->{run_time};
  }

  print $table->show();

  $html->make_charts_simple(
    {
      TRANSITION    => 1,
      TYPES         => { $lang{REPLYS} => 'LINE' },
      X_TEXT        => \@x_column_name,
      DATA          => \%column_date,
      TITLE         => $lang{REPLYS_COUNT},
    }
  );
    $html->make_charts_simple(
    {
      TRANSITION    => 1,
      TYPES         => { $lang{TIME} => 'LINE' },
      X_TEXT        => \@x_column_name,
      DATA          => \%column_date2,
      TITLE         => $lang{TIME_SPENT_ON_APPLICATIONS},
    }
  );

  return 1;
}

1;
