=head1 NAME

  Msgs Shedule

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(days_in_month date_diff load_pmodule);

our (
  %lang,
  $html,
  $admin,
  %conf,
  $db,
  @WEEKDAYS,
  @MONTHES
);

my $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_show_shedule_table($attr) - show interactive table with tasks

ARGUMENTS
  $attr - hash
    ADMINS - array of hashes with admins to display
      [
        {aid, name},
        {aid, name}
      ]
    ADMINS_JOBS  - array of jobs
      [
        {
          administrator: aid,
          tasks: [ { id, start, length, name, info },  { id, start, length, name, info} ]
        },
        {
          administrator: aid,
          tasks: [ { id, start, length, name, info },  { id, start, length, name, info} ]
        }
      ]
    NEW_TASKS     - array of free tasks
      [
        {id, name, length, info},
        {id, name, length, info}
      ]
    TASKS_INFO - hash_ref of html content for tooltip
      {
        id : html,
        id : html
      }
    OPTIONS       - hash of options
       COLUMNS    - columns for tasks               || 9
       START_TIME - time for first column           || 9
       FRACTION   - time for one column (minutes)   || 60 (one hour)


    OUTPUT2RETURN - return result string;
    DEBUG         - show debug information
=cut
#**********************************************************
sub msgs_show_shedule_table {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG};
  my $json = JSON->new->utf8(0);

  my $admins_json = $json->encode($attr->{ADMINS});
  my @tasks = $attr->{ADMINS_JOBS};
  my @new_tasks_arr = $attr->{NEW_TASKS};
  my $tasks_info = $attr->{TASKS_INFO} || {};

  my $columns = $attr->{OPTIONS}->{COLUMNS} || 9;
  my $start_time = $attr->{OPTIONS}->{START_TIME} || 9;
  my $fraction = $attr->{OPTIONS}->{FRACTION} || 60;
  my $time_unit = $attr->{OPTIONS}->{TIME_UNIT} || 0;
  my $highlighted = $attr->{OPTIONS}->{ACTIVE} || 0;

  if ( ref ($columns) eq 'ARRAY' ) {
    $columns = $json->encode($columns);
  }

  if ( $debug ) {
    print "<hr> COLUMNS   : $columns ";
    print "<br> START_TIME: $start_time";
    print "<br> FRACTION  : $fraction";
    print "<br> TIME_UNIT  : $time_unit";
  }

  my $container = '#hour-grid';

  #form options
  my $init_options = "
    tableOptions = {
    container: '$container',
    administrators: $admins_json,
    hours: $columns,
    startTime: $start_time,
    fraction: $fraction,
    timeUnit : $time_unit,
    highlighted : $highlighted
    };
    AWorkTable.init(tableOptions);
    ";
  if ( $debug ) {
    print "<hr><b>Options:</b> $init_options<hr>"
  }

  #form jobs
  my $jobs = 'AWorkTable.addJobs(' . $json->encode(@tasks) . ');';
  if ( $debug ) {
    print "<hr><b>Jobs:</b> $jobs<hr>"
  }
  #form tasks
  #    my $new_tasks_size = scalar @new_tasks_arr;
  my $new_tasks = 'ATasks.addTasks(' . $json->encode(@new_tasks_arr) . ');';
  if ( $debug ) {
    print "<hr><b>New tasks:</b> $new_tasks<hr>"
  }
  $tasks_info = 'tasksInfo = ' . $json->encode($tasks_info) . ';';

  #Output
  my $result = "
    <script>
    jQuery(function(){
    $init_options
    $tasks_info
    $jobs
    $new_tasks
    AWorkTable.render();
    });
    </script>";

  if ( $attr->{OUTPUT2RETURN} ) {
    return $html->tpl_show(_include('msgs_shedule_table', 'Msgs'),
      {
        OPTIONS_SCRIPT     => $result,
        OUTPUT2RETURN      => 1,
        TASK_STATUS_SELECT => $attr->{TASK_STATUS_SELECT}
      });
  }
  else {
    $html->tpl_show(_include('msgs_shedule_table', 'Msgs'),
      {
        OPTIONS_SCRIPT     => $result,
        TASK_STATUS_SELECT => $attr->{TASK_STATUS_SELECT}
      });
  }
}

#**********************************************************
=head2 msgs_shedule_get_tasks_for_month($year, $month) - get tasks that have not defined PLAN_DATE date or date && time

  Arguments:
    $year - year with century
    $month - month num 01 to 12

  Returns:
    arr_ref, arr_ref

=cut
#**********************************************************
sub msgs_shedule_month_get_tasks {
  my ($year, $month) = @_;

  my $date_interval = "$year-$month-01/$year-$month-" . days_in_month({ DATE => "$year-$month-1" });

  #get messages for given date interval
  my $messages_list = $Msgs->messages_list(
    {
      PLAN_DATE => $date_interval,
      COLS_NAME => 1,
      STATE     => $FORM{TASK_STATUS_SELECT}
    }
  );

  #get messages where plandate is not defined
  my $free_messages_list = $Msgs->messages_list(
    {
      LOGIN     => '_SHOW',
      PLAN_DATE => '0000-00-00',
      COLS_NAME => 1,
      STATE     => $FORM{TASK_STATUS_SELECT}
    }
  );

  my @tasks_ids = ();
  my @new_tasks = ();

  for my $message ( @{$free_messages_list} ) {
    my $task_id = $message->{id};

    $message->{login} ||= '';
    $message->{subject} ||= '';

    push (@tasks_ids, $task_id);
    push (
      @new_tasks,
      {
        id   => $task_id,
        name => "$message->{login}: $message->{subject}",
      }
    );
  }

  my @assigned_date_tasks = ();
  foreach my $message ( @{$messages_list} ) {
    my $task_id = $message->{id};

    $message->{login} ||= '';
    $message->{subject} ||= '';

    push (@tasks_ids, $task_id);
    push (@assigned_date_tasks,
      {
        id        => $task_id,
        name      => "$message->{login}: $message->{subject}",
        plan_date => $message->{plan_date}
      }
    );
  }

  return (\@tasks_ids, \@new_tasks, \@assigned_date_tasks);
}

#**********************************************************
=head2 msgs_shedule2() - Visualize time and admin task assignment

=cut
#**********************************************************
sub msgs_shedule2 {

  my $debug = $FORM{debug};
  my $loaded_json_result = load_pmodule("JSON", { RETURN => 1 });
  if ( $loaded_json_result ) {
    print $loaded_json_result;
    return 0;
  }

  if ( !$FORM{DATE} ) {
    $FORM{DATE} = POSIX::strftime('%Y-%m-%d', localtime);
  };

  my DBI $db_ = $Msgs->{db}->{db};
  my $options = { COLUMNS => 9, START_TIME => 9, FRACTION => 60, TIME_UNIT => 0 };
  my $default_task_length = 1;

  if ( $FORM{change} && $FORM{change} ne '' && ($FORM{jobs} || $FORM{popped}) ) {

    # Accept changes
    if ( $FORM{jobs} ) {
      my $jobs_unescaped = $FORM{jobs};
      $jobs_unescaped =~ s/\\\"/\"/g;
      my $jobs = JSON::decode_json($jobs_unescaped);

      $db_->{AutoCommit} = 0;
      for my $job ( @{$jobs} ) {
        my $aid = $job->{administrator};
        my $tasks = $job->{tasks};

        for my $task ( @{$tasks} ) {

          my $task_id = $task->{id};
          #                my $task_length = $task->{length};
          my $task_start = $task->{start} || 0;
          my $task_name = $task->{name} || '';
          #                my $task_end = $task_start + $task_length;

          my $hours_start = $task_start + $options->{START_TIME};

          if ( $options->{TIME_UNIT} == 0 && $hours_start >= 24 ) {
            $html->message('danger', "$task_name : $lang{RESETED}", "$hours_start:00:00 > 23:59:59");
            $hours_start = "00";
          }

          my $task_start_time = "$hours_start:00:00";
          if ( $debug ) {
            print "<hr>" . $task_name . " : " . $task_start . " : " . $task_start_time;
          }
          $Msgs->message_change({ ID => $task_id, PLAN_TIME => $task_start_time, RESPOSIBLE => $aid, PLAN_DATE =>
            $FORM{DATE} });
          if ( $Msgs->{errno} ) {
            $html->message('danger', $Msgs->{errstr});
            $db_->rollback();
            $html->message('danger', $lang{RESETED});
            return 0;
          }
          else {
            $html->message('success', "$task_name : $lang{CHANGED}") if ( $Msgs->{debug} );
          }
        }
      }
    }

    # Unlink tasks
    if ( $FORM{popped} ) {
      my $tasks_unescaped = $FORM{popped};
      $tasks_unescaped =~ s/\\\"/\"/g;
      my $task_ids = JSON::decode_json($tasks_unescaped);

      for my $task_id ( @{$task_ids} ) {
        $Msgs->message_change({ ID => $task_id, PLAN_TIME => '00:00:00', RESPOSIBLE => 0 });
        if ( $Msgs->{errno} ) {
          $html->message('danger', $Msgs->{errstr});
          $db_->rollback();
          $html->message('danger', $lang{RESETED});
          return 0;
        }
        else {
          $html->message('success alert-sm', "$lang{MESSAGE} $task_id: $lang{RESETED}") if ( $Msgs->{debug} );
        }
      }
    }

    $db_->commit();
    $db_->{AutoCommit} = 1;
  }

  my @admins_list = (@{ $admin->list({ GID => $admin->{GID}, DISABLE => 0, PAGE_ROWS => 1000, COLS_NAME => 1 }) });
  my @admins = ();

  #restructurize admins list
  for my $admin_ ( @admins_list ) {
    next if ( !$admin_->{aid} || $admin_->{aid} == 2 || $admin_->{aid} == 3 );
    push (@admins, {
        id   => $admin_->{aid},
        name => $admin_->{name} || $admin_->{login}
      }
    );
  }

  #by default use given_ID_task as new (unprocessed)
  my $new_task_ = 1;
  if ( defined $FORM{ID} && $FORM{ID} ne '' ) {
    $options->{ACTIVE} = $FORM{ID};
  }

  #get tasks for date
  my $date = $FORM{DATE} || 'NOW()';

  #get messages for given date
  my $messages_list = $Msgs->messages_list({
    LOGIN     => '_SHOW',
    RESPOSIBLE=> '_SHOW',
    PLAN_DATE => $date,
    COLS_NAME => 1,
    STATE     => $FORM{TASK_STATUS_SELECT}
  });

  #get messages where plantime is not defined
  my $free_messages_list = $Msgs->messages_list({
    LOGIN     => '_SHOW',
    RESPOSIBLE=> '_SHOW',
    PLAN_DATE => '0000-00-00',
    COLS_NAME => 1,
    STATE     => $FORM{TASK_STATUS_SELECT}
  });

  my @tasks_ids = ();

  my @new_tasks = ();
  my %jobs_aid = ();
  for my $message ( @{$messages_list}, @{$free_messages_list} ) {
    my $aid     = $message->{resposible};
    my $task_id = $message->{id};

    push @tasks_ids, $task_id;

    if ( $options->{ACTIVE} && ($task_id == $options->{ACTIVE}) ) {
      #if given_ID_task is inside unprocessed or assigned tasks array,
      $new_task_ = undef;
    };

    my $mess_start = substr($message->{plan_time}, 0, 2) - $options->{START_TIME};
    my $mess_name = ($message->{login} ? "$message->{login}:" : q{}) . ($message->{subject} ? $message->{subject} : q{});
    if ( $aid && $mess_start >= 0 ) {
      if ( !$jobs_aid{$aid} ) {
        $jobs_aid{$aid} = ();
      }
      push @{ $jobs_aid{$aid} }, {
          id     => $task_id,
          name   => $mess_name,
          length => $default_task_length,
          start  => $mess_start
        }
    }
    else {
      push @new_tasks, {
          id     => $task_id,
          name   => $mess_name,
          length => $default_task_length
        };
    }
  }

  #form tasks_info
  my $tasks_info = {};
  if ( scalar @tasks_ids > 0 ) {
    $tasks_info = msgs_tasks_info(\@tasks_ids);
  }

  my @jobs = ();
  for my $key ( keys %jobs_aid ) {
    push @jobs, { administrator => $key, tasks => $jobs_aid{$key} };
  }
  #save given task to new task
  if ( $FORM{ID} && $FORM{ID} ne '' && defined $new_task_ ) {
    #form new task from given ID
    my $message_info = $Msgs->message_info($FORM{ID}, { COLS_NAME => 1 });
    my $mess_name = "$message_info->{LOGIN}: $message_info->{SUBJECT}";

    $new_task_ = ({ id => $message_info->{ID}, name => $mess_name, length => $default_task_length });

    push @new_tasks, $new_task_;
  }

  my $task_status_select = msgs_sel_status({ NAME => 'TASK_STATUS_SELECT', ALL => 1 });

  msgs_show_shedule_table({
    ADMINS             => \@admins,
    #        DEBUG => 1,
    OPTIONS            => $options,
    NEW_TASKS          => \@new_tasks,
    ADMINS_JOBS        => \@jobs,
    TASKS_INFO         => $tasks_info,
    TASK_STATUS_SELECT => $task_status_select
  });

  return 1;
}

#**********************************************************
=head2 msgs_shedule_month()

=cut
#**********************************************************
sub msgs_shedule2_month {

  my $loaded_json_result = load_pmodule("JSON", { RETURN => 1 });
  if ( $loaded_json_result ) {
    print $loaded_json_result;
    return 0;
  }

  my $json = JSON->new->utf8(0);

  if ( $FORM{change} && $FORM{popped} && $FORM{jobs} ) {
    my $jobs_popped = $FORM{popped} || q{};
    $jobs_popped =~ s/\\\"/\"/g;
    my $jobs = $FORM{jobs} || q{};
    $jobs =~ s/\\\"/\"/g;

    my $tasks_popped = JSON::decode_json($jobs_popped);
    my $tasks_applied = JSON::decode_json($jobs);

    $Msgs->{db}->{db}->{AutoCommit} = 0;

    foreach my $task_popped ( @{$tasks_popped} ) {
      $Msgs->message_change({ ID => $task_popped, PLAN_DATE => '0000-00-00' });
    }

    foreach my $task_applied ( @{$tasks_applied} ) {
      $Msgs->message_change({ ID => $task_applied->{id}, PLAN_DATE => $task_applied->{plan_date} });
    }
    if ( $Msgs->{errno} ) {
      _error_show($Msgs);
    }
    else {
      my DBI $db_ = $Msgs->{db}->{db};
      $db_->commit();
      $db_->{AutoCommit} = 1;
    }
  }

  my $date = (defined $FORM{DATE}) ? $FORM{DATE} : $DATE;
  my ($cur_year, $cur_month, $cur_day);
  if ( $date =~ /(\d{4})\-(\d{2})\-(\d{2})/ ) {
    $cur_year = $1;
    $cur_month = $2;
    $cur_day = $3;
  }
  else {
    $html->message('err', $lang{ERROR}, "Incorrect DATE");
    return 0;
  }

  my $days_count = days_in_month({ DATE => $date });
  my $cur_day_time = POSIX::mktime(1, 0, 0, $cur_day - 1, $cur_month - 1, $cur_year - 1900);
  my ($mon, $year) = (localtime($cur_day_time))[4, 5];

  my @weekdays = @WEEKDAYS;
  shift @weekdays;
  my $table = $html->table({
    width       => '100%',
    border      => 1,
    title_plain => \@weekdays,
    class       => "table work-table-month no-highlight\" data-year='$cur_year' data-month='$cur_month'",
    ID          => 'MSGS_SHEDULE_MONTH_TABLE',
  });
  my @table_rows = ();

  my $day;

  # Fill first week row;
  my $first_day_time = POSIX::mktime(1, 0, 0, 1, $mon, $year);
  my $f_wday = (localtime($first_day_time))[6];
  if ( $f_wday == 0 ) {$f_wday = 7}

  # Start row with empty cells
  my @fweek_row = ();
  for ( my $i = 1; $i < $f_wday; $i++ ) {
    push (@fweek_row, $html->element('span', '', { class => 'disabled' }));
  };

  my $shedule_table_index = get_function_index("msgs_shedule2");
  my $link = "?index=$shedule_table_index&DATE=$cur_year-$cur_month-";
  # Fill all other cells
  my $current_week_row = \@fweek_row;
  my $week_day_counter = $f_wday - 1;
  for ( $day = 1; $day <= $days_count; $day++, $week_day_counter++ ) {

    my $is_weekday = '';
    if ( $week_day_counter % 7 > 4 ) {
      $is_weekday = ' weekday';
    }

    my $current = ($cur_day == $day) ? ' current' : '';

    if ( $week_day_counter % 7 == 0 ) {
      push (@table_rows, $current_week_row);
      $current_week_row = [];
    }
    my $two_digits_day = (length($day) == 1) ? '0' . $day : $day;
    push (@{$current_week_row},
      "<a href='$link$two_digits_day' target='_blank' title='$lang{SHEDULE_BOARD}' class='mday$is_weekday$current' data-mday='$day'>$day</a>");
  };

  # Finish last row
  my $days_left = 7 - scalar @{$current_week_row} - 1;
  for ( my $i = 1; $i < $days_left; $i++ ) {
    push (@{$current_week_row}, $html->element('span', '', { class => 'disabled' }));
  };
  push (@table_rows, $current_week_row);

  foreach my $week_row ( @table_rows ) {
    $table->addrow(@{$week_row});
  }

  my ($tasks_ids, $tasks_free, $tasks_for_month ) = msgs_shedule_month_get_tasks($cur_year, $cur_month);
  my $tasks_info = msgs_tasks_info($tasks_ids);

  my $tasks_script = "<script>
   jQuery(function(){
    tasksInfo = " . $json->encode($tasks_info) . ";
    ATasks.addTasks(" . $json->encode($tasks_free) . ");
    AMonthWorkTable.init();
    AMonthWorkTable.addJobs( " . $json->encode($tasks_for_month) . ");
  });
  </script>";

  my $task_status_select = msgs_sel_status({ NAME => 'TASK_STATUS_SELECT', ALL => 1 });

  my $prev_month_num = ($cur_month - 1 != 0) ? $cur_month - 1 : 12;
  my $prev_year_num = ($cur_month - 1 == 0) ? $cur_year - 1 : $cur_year;
  my $next_month_num = ($cur_month + 1 != 13) ? $cur_month + 1 : 1;
  my $next_year_num = ($cur_month + 1 == 13) ? $cur_year + 1 : $cur_year;

  $prev_month_num = "0" . $prev_month_num if ( length($prev_month_num) < 2 );
  $next_month_num = "0" . $next_month_num if ( length($next_month_num) < 2 );

  my $prev_month_date = "$prev_year_num-$prev_month_num-01";
  my $next_month_date = "$next_year_num-$next_month_num-01";

  $html->tpl_show(_include('msgs_shedule_month', 'Msgs'), {
      TABLE              => $table->show(),
      OPTIONS_SCRIPT     => $tasks_script,

      TASK_STATUS_SELECT => $task_status_select,

      DATE               => $date,
      YEAR               => $cur_year,
      MONTH_NAME         => $MONTHES[$cur_month - 1],

      PREV_MONTH_DATE    => $prev_month_date,
      NEXT_MONTH_DATE    => $next_month_date

    });

  return 1;
}

#**********************************************************
=head2 msgs_shedule()

=cut
#**********************************************************
sub msgs_shedule {

  my %MSGS_PERIOD = (
    0 => $lang{DAY},
    1 => "5  $lang{DAYS}",
    2 => "$lang{WEEK}",
    3 => "$lang{MONTH}",
    4 => "$lang{TOTAL}"
  );

  #my %visual_view = ();
  my $i;
  my $period = $FORM{PERIOD} || 0;
  my %calendar = ();

  my %SHOW_TYPE = (
    admins   => "$lang{ADMINS}",
    chapters => "$lang{CHAPTERS}",
    date     => "$lang{DATE}"
  );

  my @header_arr = ();

  foreach my $id ( sort keys %SHOW_TYPE ) {
    push @header_arr, "$SHOW_TYPE{$id}:index=$index&PERIOD=$period&SHOW_TYPE=$id";
  }

  print $html->table_header(\@header_arr, { TABS => 1 });

  @header_arr = ();

  foreach my $id ( sort keys %MSGS_PERIOD ) {
    push @header_arr, "$MSGS_PERIOD{$id}:index=$index&PERIOD=$id&SHOW_TYPE=" . ($FORM{SHOW_TYPE} || '');
  }

  print $html->table_header(\@header_arr, { TABS => 1 });

  if ( $period == 1 ) {
    $LIST_PARAMS{PLAN_FROM_DATE} = $DATE;
    $LIST_PARAMS{PLAN_TO_DATE} = POSIX::strftime('%Y-%m-%d', localtime(time + 86400 * 5));
  }
  elsif ( $period == 2 ) {
    $LIST_PARAMS{PLAN_WEEK} = 1;
  }
  elsif ( $period == 3 ) {
    $LIST_PARAMS{PLAN_MONTH} = 1;
  }
  elsif ( $period == 4 ) {

  }
  else {
    $LIST_PARAMS{PLAN_FROM_DATE} = $DATE;
    $LIST_PARAMS{PLAN_TO_DATE} = $DATE;
  }

  my $list = $Msgs->messages_list(
    {
      PLAN_DATE_TIME         => '_SHOW',
      RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
      CLIENT_ID              => '_SHOW',
      SUBJECT                => '_SHOW',
      %LIST_PARAMS,
      DESC                   => '',
      SORT                   => 'm.plan_date, m.plan_time',
      STATE                  => 0,
      PAGE_ROWS              => 10000,
      COLS_NAME              => 1,
    }
  );

  my $table = $html->table(
    {
      width   => '300',
      caption => "$lang{SHEDULE}",
      ID      => 'SHEDULE_LIST',
    }
  );

  my %dates = ();
  my Abills::HTML $table2;
  my @main_table_rows = ();
  my $color = 'bg-info';

  my @chapters_list = @{ $Msgs->chapters_list() };
  my @admins_list = ([ 0, "- $lang{UNKNOWN}" ],
    @{ $admin->list({ GID => $admin->{GID}, DISABLE => 0, PAGE_ROWS => 1000 }) });

  foreach my $line ( @{$list} ) {
    my ($date, $time) = split(/ /, $line->{plan_date_time} || q{});
    my @hours = ();

    my $tdcolor;
    if ( !$dates{$date} ) {
      my $caption = '';
      if ( keys %dates > 0 ) {
        if ( $FORM{SHOW_TYPE} eq 'chapters' || $FORM{SHOW_TYPE} eq 'admins' ) {
          my $title = $lang{CHAPTERS};

          if ( $FORM{SHOW_TYPE} eq 'admins' ) {
            @chapters_list = @admins_list;
            $title = $lang{ADMINS};
          }

          foreach my $chapter_info ( @chapters_list ) {
            @hours = ();
            my ($h_b, $h_e, $m_b, $s_b);
            my $link = "&nbsp;";

            for ( my $h = 0; $h < 24 * 4; $h++ ) {
              if ( $calendar{ $chapter_info->[0] } ) {
                #my $day_periods = $visual_view{$i};

                foreach my $chap_periods ( @{ $calendar{ $chapter_info->[0] } } ) {
                  my ($number, $user_name, $uid, $time_exec) = split(/\|/, $chap_periods, 4);
                  ($h_b, $m_b, $s_b) = split(/:/, $time_exec);
                  $h_e = $h_b;
                  if ( (($h / 4 >= $h_b) && ($h / 4 <= $h_e) && $m_b <= 15)
                    || ((($h - 1) / 4 == $h_b) && ($m_b <= 30 && $m_b >= 15))
                    || ((($h - 2) / 4 == $h_b) && ($m_b <= 45 && $m_b >= 30))
                    || ((($h - 3) / 4 == $h_b) && ($m_b <= 60 && $m_b >= 45)) ) {
                    $tdcolor = $color;
                    $link = "<acronym  title='$lang{USER}: $user_name\n  $line->{subject}\n ID:  $number\n  $lang{TIME}: $time'>  " . $html->button(
                      "#", "index=" . ($index - 3) . "&chg=$number&UID=$uid",) . "</acronym>";
                    last;
                  }
                  else {
                    $link = "&nbsp;";
                    $tdcolor = 'odd';
                  }
                }
              }
              else {
                $link = "&nbsp;";
                $tdcolor = 'odd';
              }

              push(@hours, $table2->td($link, { align => 'center', class => $tdcolor }));
            }

            $table2->addtd($table->td($html->b($chapter_info->[1]), { class => 'bg-primary' }), @hours);
          }

          %calendar = ();
        }

        push @main_table_rows, $table2->show({ OUTPUT2RETURN => 1 });
      }

      #       if  ($line->[19] ==  0) {
      #         $caption  =  $html->color_mark($WEEKDAYS[7],  $_COLORS[6]);
      #       }
      #       elsif ($line->[19]  == 6)  {
      #         $caption  =  $html->color_mark($WEEKDAYS[6],  $_COLORS[6]);
      #       }
      #       else  {
      #         $caption  =  $WEEKDAYS[ $line->[19] ];
      #       }

      if ( $FORM{SHOW_TYPE} && ($FORM{SHOW_TYPE} eq 'chapters' || $FORM{SHOW_TYPE} eq 'admins') ) {
        my $title;
        if ( $FORM{SHOW_TYPE} eq 'chapters' ) {
          $title = $lang{CHAPTERS};
        }
        elsif ( $FORM{SHOW_TYPE} eq 'admins' ) {
          $title = $lang{ADMINS};
        }

        $table2 = $html->table(
          {
            width    => '100',
            caption  => $caption . " $title - $date ",
            rowcolor => 'even',
            ID       => 'MSGS_SHEDULE_' . $date,
          }
        );

        #        my $list = $Msgs->messages_list(
        #          {
        #            %LIST_PARAMS,
        #            DESC      => '',
        #            SORT      => 'm.plan_date, m.plan_time',
        #            STATE     => 0,
        #            PAGE_ROWS => 10000
        #          }
        #        );

        @hours = ();
        for ( $i = 0; $i < 24; $i++ ) {
          push @hours, $table2->td($html->b($i), { colspan => 4, align => 'center' });
        }

        $table2->addtd($table2->td($html->b($title . '--'), { bgcolor => $_COLORS[0] }), @hours);
      }
      else {
        $table2 = $html->table(
          {
            width   => '300',
            caption => $caption . " / $date",
            title   => [ '#', "$lang{ADMIN}", "$lang{TIME}", "$lang{SUBJECT}" ],
            ID      => 'SHEDULE_LIST',
            class   => 'table'
          }
        );
      }

      $dates{$date} = 1;
    }

    if ( $FORM{SHOW_TYPE} && $FORM{SHOW_TYPE} eq 'chapters' ) {
      push @{ $calendar{ $line->{chapter_id} } }, "$line->{id}|$line->{client_id}|$line->{uid}|$time";
    }
    elsif ( $FORM{SHOW_TYPE} && $FORM{SHOW_TYPE} eq 'admins' ) {
      push @{ $calendar{ $line->{chapter_id} } }, "$line->{id}|$line->{client_id}|$line->{uid}|$time";
    }
    else {
      if ( $line->{state} == 3 ) {
        $table2->{rowcolor} = 'bg-danger';
      }
      elsif ( $line->{state} == 0 && date_diff($DATE, $date) < 0 ) {
        $table2->{rowcolor} = 'bg-warning';
      }

      my $state_icon = '';

      if ( $line->{state} == 1 ) {
        $state_icon = 'glyphicon glyphicon-ok-sign';
      }
      elsif ( $line->{state} == 2 ) {
        $state_icon = 'glyphicon glyphicon-warning-sign';
      }

      $table2->addrow(
        $html->button($line->{id},
          "index=" . get_function_index('msgs_admin') . "&chg=" . $line->{id} . "&UID=" . $line->{uid}),
        $line->{resposible_admin_login},
        $time,
        $line->{subject},
        $state_icon
      );
    }
  }

  if ( $table2 ) {
    if ( $FORM{SHOW_TYPE} && ($FORM{SHOW_TYPE} eq 'chapters' || $FORM{SHOW_TYPE} eq 'admins') ) {
      @chapters_list = @admins_list if ( $FORM{SHOW_TYPE} eq 'admins' );

      foreach my $chapter_info ( @chapters_list ) {
        my @hours = ();
        my ($h_b, $h_e, $m_b, $s_b);
        my $link = "&nbsp;";

        for ( my $h = 0; $h < 24 * 4; $h++ ) {
          my $tdcolor;
          if ( $calendar{ $chapter_info->[0] } ) {
            #my $day_periods = $visual_view{$i};

            #print "<b>Chapters  $chapter_info->[0]</b>/  <br>";
            foreach my $chap_periods ( @{ $calendar{ $chapter_info->[0] } } ) {

              #print "$i --  $chap_periods   <br>\n";
              my ($number, $user_name, $uid, $time) = split(/\|/, $chap_periods, 4);
              ($h_b, $m_b, $s_b) = split(/:/, $time);
              $h_e = $h_b;
              if ( (($h / 4 >= $h_b) && ($h / 4 <= $h_e) && $m_b <= 15)
                || ((($h - 1) / 4 == $h_b) && ($m_b <= 30 && $m_b >= 15))
                || ((($h - 2) / 4 == $h_b) && ($m_b <= 45 && $m_b >= 30))
                || ((($h - 3) / 4 == $h_b) && ($m_b <= 60 && $m_b >= 45)) ) {
                $tdcolor = $color;
                $link = "<acronym  title='$lang{USER}: $user_name\n  ID:  $number\n  $lang{TIME}:  $time'>  " . $html->button(
                  "#", "index=" . ($index - 3) . "&chg=$number&UID=$uid",) . "</acronym>";
                last;
              }
              else {
                $link = "&nbsp;";
                $tdcolor = $_COLORS[1];
              }
            }
          }
          else {
            $link = "&nbsp;";
            $tdcolor = $_COLORS[1];
          }

          push(@hours, $table2->td("$link", { align => 'center', bgcolor => $tdcolor }));
        }

        $table2->addtd($table->td($html->b($chapter_info->[1]), { bgcolor => $_COLORS[2] }), @hours);
      }
    }

    push @main_table_rows, $table2->show({ OUTPUT2RETURN => 1 });
  }
  else {
    print $html->message('info', $lang{INFO}, "$lang{NO_RECORD}");
    return 0;
  }

  if ( $FORM{SHOW_TYPE} && ($FORM{SHOW_TYPE} eq 'chapters' || $FORM{SHOW_TYPE} eq 'admins') ) {
    foreach my $t ( @main_table_rows ) {
      print "$t";
    }
  }
  else {
    $i = 0;
    my @table_rows = ();
    $table->{rowcolor} = 'odd';
    foreach my $line ( @main_table_rows ) {
      $i++;
      push @table_rows, $table->td($line, { valign => 'top' });
      if ( $i > 2 ) {
        $table->addtd(@table_rows);
        @table_rows = ();
        $i = 0;
      }
    }

    if ( $#table_rows > - 1 ) {
      $table->addtd(@table_rows);
    }

    print $table->show();
  }

  return 1;
}

#**********************************************************
=head2 msgs_tasks_info($id_arr, $attr) - Return (AJAX compatible) info about tasks

  Arguments:
    $id_arr - arr_ref
    $attr

  Returns:
     hash_ref

=cut
#**********************************************************
sub msgs_tasks_info {
  my ($id_arr) = @_;

  unless ( ref $id_arr eq 'ARRAY' ) {
    return 0;
  }

  my $messages_list = $Msgs->messages_list({
    ID             => $id_arr,
    FIO            => '_SHOW',
    DATETIME       => '_SHOW',
    CHAPTER_NAME   => '_SHOW',
    ADDRESS_FULL   => '_SHOW',
    PLAN_DATE_TIME => '_SHOW',
    A_NAME         => '_SHOW',
    USERS_FIELDS   => 1,
    COLS_NAME      => 1,
    COLS_UPPER     => 1
  });

  my $result = {};
  foreach my $message ( @{$messages_list} ) {
    $result->{$message->{id}} = msgs_task_info_to_html($message);
  }

  return $result;
}


1;