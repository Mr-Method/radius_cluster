=head1 NAME

  Start page table

=head1 VERSION

  0.1

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Defs;

our ($db,
  %lang,
  $html,
  @bool_vals,
  @MONTHES,
  @WEEKDAYS,
  @_COLORS,
  %permissions,
  $admin,
  $ui,
  %conf
);

my $Msgs = Msgs->new($db, $admin, \%conf);

my $MESSAGE_ICON = q{};
if($html && $html->{TYPE} && $html->{TYPE} eq 'html') {
  $MESSAGE_ICON = $html->element('span', '', { class => 'fa fa-envelope-o', OUTPUT2RETURN => 1 });
}

#***************************************************************
=head2 msgs_sp_show_overdue($attr)

=cut
#***************************************************************
sub msgs_sp_show_overdue {
  msgs_sp_show_new({ STATE => 12 });
}

#***************************************************************
=head2 msgs_sp_show_new($attr)

=cut
#***************************************************************
sub msgs_sp_show_new {
  my ($attr) = @_;

  $attr ||= {};
  my $list = $Msgs->messages_list(
    {
      LOGIN          => '_SHOW',
      CLIENT_ID      => '_SHOW',
      DATETIME       => '_SHOW',
      SUBJECT        => '_SHOW',
      CHAPTER        => '_SHOW',
      CHAPTER_NAME   => '_SHOW',
      PRIORITY       => '_SHOW',
      PLAN_DATE_TIME => '_SHOW',
      SORT           => 'id',
      DESC           => 'desc',
      STATE          => ($attr && $attr->{STATE}) ? $attr->{STATE} : 0,
      PAGE_ROWS      => 5,
      COLS_NAME      => 1
    }
  );
  my $badge = '';
  if(!$attr->{STATE}){
    use Abills::Base qw/days_in_month/;

    my($y, $m, undef) = split("-", $DATE);

    my $start_date = "$y-$m-01";
    my $end_date = "$y-$m-" . days_in_month({DATE => $DATE});

    my $all_open_msgs = $Msgs->{OPEN};

    my $closed_in_month = $Msgs->messages_list(
      {
        CLOSED_DATE    => ">=$start_date;<=$end_date",

        SORT           => 'id',
        DESC           => 'desc',
        PAGE_ROWS      => 9999999,
      }
    );

    my $opened_in_month = $Msgs->messages_list(
      {
        DATE           => ">=$start_date;<=$end_date",

        SORT           => 'id',
        DESC           => 'desc',
        PAGE_ROWS      => 9999999,
      }
    );

    my $scalar_opened_in_month = $opened_in_month ? scalar (@$opened_in_month) : 0;
    my $scalar_closed_in_month = $closed_in_month ? scalar (@$closed_in_month) : 0;

    my $opened_per_month_badge = $html->element('small', ($scalar_opened_in_month), {
        class                   => 'label bg-warning',
        'data-tooltip'          => "$lang{OPEN} $lang{FOR_} $lang{MONTH}",
        'data-tooltip-position' => 'top'
      });
    my $closed_per_month_badge = $html->element('small', ($scalar_closed_in_month), {
        class                   => 'label bg-green',
        'data-tooltip'          => "$lang{CLOSED} $lang{FOR_} $lang{MONTH}",
        'data-tooltip-position' => 'top'
      });
    my $all_opend_messages = $html->element('small', $all_open_msgs, {
        class => 'label  bg-primary',
        'data-tooltip'          => "$lang{ALL} $lang{OPEN}",
        'data-tooltip-position' => 'top'
      });

    $badge = $all_opend_messages . $opened_per_month_badge . $closed_per_month_badge;
  }

  return msgs_sp_table($list, {
    CAPTION      => ($attr->{STATE}) ? $lang{OVERDUE} : $lang{MESSAGES},
    SKIP_ICON => 1,
    DATE_KEY     => ($attr->{STATE}) ? 'plan_date_time' : 'datetime',
    DATA_CAPTION => ($lang{DATE}),
    BADGE        => $badge
    });
}

#**********************************************************
=head2 msgs_user_watch()

=cut
#**********************************************************
sub msgs_user_watch {

  my $watched_links = $Msgs->msg_watch_list({
    COLS_NAME => 1,
    AID       => $admin->{AID}
  });
  _error_show($Msgs);

  my $watched_messages_list = $Msgs->messages_list(
    {
      MSG_ID     => join(';', map {$_->{main_msg}} @$watched_links) || 0,
      COLS_NAME  => 1,
      PAGE_ROWS  => 5,
      LOGIN      => '_SHOW',
      STATE      => '_SHOW',
      PRIORITY   => '_SHOW',
      LAST_REPLIE_DATE => '_SHOW',
      SORT             => 'last_replie_date',
    }
  );
  _error_show($Msgs);

  my $badge = $html->element('small', scalar @{$watched_links}, {
      class => 'label pull-right bg-green',
    });

  return msgs_sp_table($watched_messages_list, {
    BADGE           => $badge,
    CAPTION         => $lang{WATCHED},
    DATA_CAPTION    => $lang{LAST_ACTIVITY},
      DATE_KEY => 'last_replie_date',
    EXTRA_LINK_DATA => "&STATE=12", # state for watching messages
  });
}

#**********************************************************
=head2 msgs_dispatch_quick_report()

=cut
#**********************************************************
sub msgs_dispatch_quick_report {
  
  my $table = $html->table(
    {
      width       => '100%',
      caption     =>
      $html->button($MESSAGE_ICON . $lang{DISPATCH}, "index=" . get_function_index('msgs_dispatch') . "&ALL_MSGS=1"),
      title_plain => [ $lang{NAME}, $lang{CREATED}, $lang{EXECUTED}, $lang{TOTAL} ],
      class       => 'table',
      ID          => 'DISPATCH_QUIK_REPORT_LIST'
    }
  );
  
  my $list = $Msgs->dispatch_list(
    {
      COLS_NAME => 1,
      PAGE_ROWS => 5,
      MSGS_DONE => '_SHOW',
      SORT      => 'created',
      DESC      => 'DESC'
    }
  );
  
  my $dispatch_index = get_function_index('msgs_dispatch');
  
  foreach my $message ( @{$list} ) {
    my $dispatch_comments = $message->{comments} || $lang{NO_SUBJECT};
    my $done_count = $message->{message_count}
      ? (int(($message->{msgs_done} * 100) / $message->{message_count}))
      : 0;
    my $dispatch_link = "index=$dispatch_index&chg=$message->{id}&ALL_MSGS=1";
  
    $table->addrow($html->button($dispatch_comments, $dispatch_link),
      $html->button($message->{created}, $dispatch_link),
      $html->progress_bar({
        TEXT     => $done_count . "%",
        TOTAL    => $message->{msgs_done},
        COMPLETE => $message->{message_count}
      }),
      $html->button($message->{message_count}, $dispatch_link),
    );
  }
  
  return $table->show();
}

#**********************************************************
=head2 msgs_open_msgs()

=cut
#**********************************************************
sub msgs_open_msgs {

  my $table = $html->table(
    {
      width       => '100%',
      caption     => $html->button($MESSAGE_ICON . $lang{RESPOSIBLE}, "index=" . get_function_index('msgs_admin') . "&STATE=0"),
      title_plain => [ $lang{RESPOSIBLE}, $lang{COUNT} ],
      class       => 'table',
      ID          => 'DISPATCH_QUIK_REPORT_LIST'
    }
  );

  my $list = $Msgs->messages_list(
    {
      COLS_NAME              => 1,
      ADMIN_LOGIN            => '_SHOW',
      RESPOSIBLE             => '_SHOW',
      RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
      STATE                  => 0,
      PAGE_ROWS              => 10000
    }
  );

  my %admins;
  my %resposble_admin;
  my $withot_admin = 0;
  foreach my $msg_info (@$list) {
    if($msg_info->{resposible_admin_login}) {
      $admins{ $msg_info->{resposible_admin_login} } += 1;
      $resposble_admin{ $msg_info->{resposible_admin_login}.'resposible' } = $msg_info->{resposible};
    }
    else {
      $withot_admin++;
    }
  }

  $table->{rowcolor}='bg-info';
  $table->addrow($lang{NOT_DEFINED}, $html->button($withot_admin, "index=" . get_function_index('msgs_admin')
        . "&RESPOSIBLE=<1" . "&STATE=0"));

  delete $table->{rowcolor};

  foreach my $admin_info (sort { $admins{$b} <=> $admins{$a} } keys %admins) {
    $table->addrow($admin_info, $html->button($admins{$admin_info}, "index=" . get_function_index('msgs_admin')
          . "&RESPOSIBLE=$resposble_admin{$admin_info.'resposible'}" . "&STATE=0"));
  }


  return $table->show();
}

#**********************************************************
=head2 msgs_sp_table($messages_list, $attr)

=cut
#**********************************************************
sub msgs_sp_table {
  my ($messages_list, $attr) = @_;

  if (!$messages_list || ref $messages_list ne 'ARRAY'){
    $messages_list = [];
  }

  my $statuses_list = $Msgs->status_list({
    NAME      => '_SHOW',
    COLOR     => '_SHOW',
    LOGIN     => '_SHOW',
    ICON      => '_SHOW',
    SORT      => 'id',
    COLS_NAME => 1,
  });

  _error_show($Msgs);

  my %statuses_by_id = ();
  $statuses_by_id{$_->{id}} = $_ foreach (@$statuses_list);

  my @priority_colors_list = (
    'bg-navy disabled',
    'bg-black disabled',
    ' ',
    'bg-yellow',
    'bg-red'
  );

  my $badge = $attr->{BADGE} || '';
  my $extra_link_data = $attr->{EXTRA_LINK_DATA} || '';
  my $msgs_admin_index = get_function_index('msgs_admin');

  my $table = $html->table(
    {
      width       => '100%',
      caption     => $html->button(($attr->{SKIP_ICON} ? '' : $MESSAGE_ICON) . ($attr->{CAPTION} || '') . "&nbsp;&nbsp;" ,
        "index=$msgs_admin_index&ALL_MSGS=1$extra_link_data") . $badge,
      title_plain => [ '', ($attr->{DATA_CAPTION} || $lang{DATE}), $lang{LOGIN}, $lang{SUBJECT}, $lang{CHAPTER} ],
      class       => 'table',
      ID          => 'USER_WATCH_LIST'
    }
  );

  foreach my $msg_info ( @{$messages_list} ) {
    my $status_id = $msg_info->{state};
    my $state_icon = $statuses_by_id{$status_id}->{icon} || '';
    my $status_name = _translate($statuses_by_id{$status_id}->{name}) || $statuses_by_id{$status_id}->{name};

    $table->{rowcolor} = $priority_colors_list[$msg_info->{priority}] || '';

    my $chapter = ($msg_info->{chapter_name})
      ? ( length($msg_info->{chapter_name}) > 30)
        ? $html->element('span', substr($msg_info->{chapter_name}, 0, 30) . '...', { title => $msg_info->{chapter_name} })
        : $msg_info->{chapter_name}
      : $lang{NO_CHAPTER};

    my $subject = ($msg_info->{subject})
      ? ( length($msg_info->{subject}) > 30)
        ? $html->element('span', substr($msg_info->{subject}, 0, 30) . '...', { title => $msg_info->{subject} })
        : $msg_info->{subject}
      : $lang{NO_SUBJECT};

    $table->addrow(
      # State
      $html->element('i', '', {
          class                   => $state_icon,
          'data-tooltip'          => $status_name,
          'data-tooltip-position' => 'left auto'
        },
      ),

      # Date showed in moment humanized format
      $html->element('span', '', {
          'data-value' => $msg_info->{($attr->{DATE_KEY} || 'date')},
          class => 'moment-insert' }
      ),

      # If have login, show link to user
      ($msg_info->{uid}
        ? $html->button($msg_info->{login}, "index=15&UID=$msg_info->{uid}")
        : '' ),

      # Subject stripped to 30 symbols
      $html->button( $subject,
        "index=" . $msgs_admin_index . "&UID=" . $msg_info->{uid} . "&chg=" . $msg_info->{id}),

      # Chapter stripped to 30 symbols
      $html->button( $chapter,
        'index='. get_function_index('msgs_chapters') . "&chg=" . $msg_info->{chapter_id})
   );
  }

  return $table->show();
}

#**********************************************************
=head2 msgs_rating()

=cut
#**********************************************************
sub msgs_rating {

  my ($y, $m, undef) = split('-', $DATE);

  my $table = $html->table(
    {
      width       => '100%',
      caption     => $html->button($MESSAGE_ICON . $lang{EVALUATION_OF_PERFORMANCE},
                       "index=" . get_function_index('msgs_admin') . "&STATE=0"
                     ),
      title_plain => [ "$lang{LOGIN}", "$lang{SUBJECT}", "$lang{ASSESSMENT}" ],
      class       => 'table',
      ID          => 'EVALUATION_OF_PERFORMANCE_TABLE',
    }
  );

  my $list = $Msgs->messages_list(
    {
      RATING                 => '1;2;3;4;5',
      DATE                   => ">$y-$m-01",

      ADMIN_LOGIN            => '_SHOW',
      RESPOSIBLE             => '_SHOW',
      RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
      SUBJECT                => '_SHOW',
      STATE                  => '_SHOW',

      PAGE_ROWS              => 5,
      SORT                   => 'date',
      COLS_NAME              => 1,
    }
  );

  foreach my $msg_info (@$list) {

    $table->addrow(
      $msg_info->{resposible_admin_login} ? $msg_info->{resposible_admin_login} : $lang{ALL},
      $html->button($msg_info->{subject} ? $msg_info->{subject} : $lang{NO_SUBJECT}, "index=" . get_function_index('msgs_admin') . "&UID=" . $msg_info->{uid} . "&chg=" . $msg_info->{id}),
      msgs_rating_icons($msg_info->{rating}),
    );
  }

  return $table->show();
}

#**********************************************************
=head2 msgs_rating_icons()

=cut
#**********************************************************
sub msgs_rating_icons {
  my ($rating) = @_;

  my $rating_icons        = '';
  if ($rating && $rating > 0) {
    for (my $i = 0 ; $i < $rating ; $i++) {
      $rating_icons .= "\n" . $html->element('i', '', { class => 'fa fa-star' });
    }
    for (my $i = 0 ; $i < 5 - $rating ; $i++) {
      $rating_icons .= "\n" . $html->element('i', '', { class => 'fa fa-star-o' });
    }
  }
  return $rating_icons;
}

1
