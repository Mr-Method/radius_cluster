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

  my $table = $html->table(
    {
      width   => '100%',
      caption => $html->button($MESSAGE_ICON . (($attr->{STATE}) ? $lang{OVERDUE} : $lang{MESSAGES}), "index=" . get_function_index('msgs_admin') . (($attr->{STATE}) ? '&STATE=12' : '')),
      title_plain => [ '#',    "$lang{LOGIN}", "$lang{DATE}", "$lang{SUBJECT}" ],
      cols_align  => [ 'left', 'right',        'right',       'right' ],
      ID => "MSGS_NEW_" . ($attr->{STATE} || q{_}),
      class => 'table'
    }
  );

  my $list = $Msgs->messages_list(
    {
      CLIENT_ID      => '_SHOW',
      DATETIME       => '_SHOW',
      SUBJECT        => '_SHOW',
      PRIORITY       => '_SHOW',
      PLAN_DATE_TIME => '_SHOW',
      SORT           => 'id',
      DESC           => 'desc',
      STATE          => $attr->{STATE} || 0,
      PAGE_ROWS      => 5,
      COLS_NAME      => 1
    }
  );

  return msgs_sp_table($list, {
    CAPTION      => ($attr->{STATE}) ? $lang{OVERDUE} : $lang{MESSAGES},
    DATE_KEY     => ($attr->{STATE}) ? 'plan_date_time' : 'datetime',
    DATA_CAPTION => ($lang{DATE})
  });

  foreach my $line (@$list) {
    if ($line->{priority} == 4) {
      $table->{rowcolor} = 'bg-danger';
    }
    elsif ($line->{priority} == 3) {
      $table->{rowcolor} = 'bg-warning';
    }
    elsif ($line->{priority} <= 1) {
      $table->{rowcolor} = 'bg-info';
    }
    else {
      $table->{rowcolor} = undef;
    }

    $table->addrow(
      $line->{id},
      $html->button($line->{client_id}, "index=15&UID=$line->{uid}"),
      ($attr->{STATE}) ? $line->{plan_date_time} : $line->{datetime},
      $html->button($line->{subject} || $lang{NO_SUBJECT}, "index=" . (get_function_index('msgs_admin') . "&UID=$line->{uid}&chg=" . $line->{id}))
    );
  }

  return $table->show();
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
      STATE      => '_SHOW',
      PRIORITY   => '_SHOW',
      DATE       => '_SHOW',
      SORT       => 'date',
    }
  );
  _error_show($Msgs);

  return msgs_sp_table($watched_messages_list, {
    BADGE => scalar @{$watched_links},
    CAPTION      => $lang{WATCHED},
    DATA_CAPTION => $lang{CREATED}
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
      caption     => $html->button($MESSAGE_ICON . $lang{DISPATCH}, "index=" . get_function_index('msgs_dispatch') . "&ALL_MSGS=1"),
      title_plain => [ "$lang{NAME}", "$lang{CREATED}", "$lang{EXECUTED}", "$lang{TOTAL}"],
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

  foreach my $message (@$list) {
      $table->addrow(
            $html->button($message->{comments}?$message->{comments}:$lang{NO_SUBJECT}, "index=" . get_function_index('msgs_dispatch') . "&chg=" . $message->{id}),
            $html->button($message->{created}, "index=" . get_function_index('msgs_dispatch') . "&chg=" . $message->{id}),
            $html->progress_bar({
              TEXT     => ($message->{message_count}) ? int(($message->{msgs_done}*100)/$message->{message_count}).'%' : 0 . '%',
              TOTAL    =>  $message->{msgs_done},
              COMPLETE => $message->{message_count}
            }),
            $html->button($message->{message_count}, "index=" . get_function_index('msgs_dispatch') . "&chg=" . $message->{id}),
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
      caption     => $html->button($MESSAGE_ICON . $lang{OPEN}, "index=" . get_function_index('msgs_admin') . "&STATE=0"),
      title_plain => [ "$lang{RESPOSIBLE}", "$lang{COUNT}" ],
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
    }
  );

  my %admins;
  my %resposble_admin;
  foreach my $msg_info (@$list) {
    $msg_info->{resposible_admin_login} = $msg_info->{resposible_admin_login} ? $msg_info->{resposible_admin_login} : $lang{ALL};
    $msg_info->{resposible}             = $msg_info->{resposible}             ? $msg_info->{resposible}             : 0;
    $admins{ $msg_info->{resposible_admin_login} } += 1;
    $resposble_admin{ $msg_info->{resposible_admin_login} . 'resposible' } = $msg_info->{resposible};
  }

  foreach my $admin_info (keys %admins) {
    $table->addrow($admin_info, $html->button($admins{$admin_info}, "index=" . get_function_index('msgs_admin') . "&RESPOSIBLE=$resposble_admin{$admin_info.'resposible'}" . "&STATE=0"));
  }
  return $table->show();
}

#**********************************************************
=head2 msgs_sp_table()

=cut
#**********************************************************
sub msgs_sp_table {
  my ($messages_list, $attr) = @_;

  if (!$messages_list || ref $messages_list ne 'ARRAY'){
    $messages_list = [];
  }

  my @icon = (
    'fa fa-envelope-open text-aqua', # OPEN
    'fa fa-warning text-red',        # UNDONE AND CLOSED
    'fa fa-check text-green',        # DONE AND CLOSED
    'fa fa-wrench',                  # IN WORK
    'fa fa-reply text-blue',         # NEW MESSAGE
    'fa fa-clock-o',                 # SUSPEND
    'fa fa-envelope-open-o'          # WAIT REPLY FROM USER
  );

  my $statuses_list = $Msgs->status_list({
    NAME      => '_SHOW',
    COLOR     => '_SHOW',
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

  my $badge = $html->element('small', ($attr->{BADGE} || scalar (@$messages_list)), { class => 'label pull-right bg-green' });
  my $msgs_admin_index = get_function_index('msgs_admin');

  my $table = $html->table(
    {
      width       => '100%',
      caption     => $html->button($MESSAGE_ICON . ($attr->{CAPTION} || '') . "&nbsp&nbsp" . $badge,
        "index=$msgs_admin_index&ALL_MSGS=1"),
      title_plain => [ '', ($attr->{DATA_CAPTION} || $lang{DATE}), $lang{LOGIN}, $lang{SUBJECT}, ],
      class       => 'table',
      cols_align  => [ 'center', 'center', 'center', 'right' ],
      ID          => 'USER_WATCH_LIST'
    }
  );
  foreach my $msg_info ( @{$messages_list} ) {
    my $status_id = $msg_info->{state};
    my $state_icon = $icon[$status_id] || '';
    my $status_name = _translate($statuses_by_id{$status_id}->{name}) || $statuses_by_id{$status_id}->{name};

    $table->{rowcolor} = $priority_colors_list[$msg_info->{priority}] || '';

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
        ? $html->button($msg_info->{user_name}, "index=15&UID=$msg_info->{uid}")
        : '' ),

      # Subject stripped to 30 symbols
      $html->button( $subject,
        "index=" . $msgs_admin_index . "&UID=" . $msg_info->{uid} . "&chg=" . $msg_info->{id})
    );
  }

  return $table->show();
}

#**********************************************************
=head2 msgs_rating()

=cut
#**********************************************************
sub msgs_rating {

  my $table = $html->table(
    {
      width       => '100%',
      caption     => $html->button($MESSAGE_ICON . $lang{EVALUATION_OF_PERFORMANCE}, "index=" . get_function_index('msgs_admin') . "&STATE=0"),
      title_plain => [ "$lang{LOGIN}", "$lang{SUBJECT}", "$lang{ASSESSMENT}" ],
      class       => 'table',
      ID          => 'EVALUATION_OF_PERFORMANCE_TABLE',
      cols_align  => [ 'left', 'right', 'right', 'right' ],
    }
  );

  my $list = $Msgs->messages_list(
    {
      RATING                 => '1;2;3;4;5',
      ADMIN_LOGIN            => '_SHOW',
      PAGE_ROWS              => 5,
      RESPOSIBLE             => '_SHOW',
      RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
      SUBJECT                => '_SHOW',
      STATE                  => '_SHOW',
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
