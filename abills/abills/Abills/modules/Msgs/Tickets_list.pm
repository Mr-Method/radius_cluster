=head1 NAME

  Tickets list

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(convert);

our ($db,
  %lang,
  $html,
  $admin,
  %conf,
  %permissions,
);

# my @priority = ($lang{VERY_LOW}, $lang{LOW}, $lang{NORMAL}, $lang{HIGH}, $lang{VERY_HIGH});

my @priority = ();
if ($html) {
  @priority = (
    $html->element('span', '', { class => 'fa fa-thermometer-0', OUTPUT2RETURN => 1 }),
    $html->element('span', '', { class => 'fa fa-thermometer-1', OUTPUT2RETURN => 1 }),
    $html->element('span', '', { class => 'fa fa-thermometer-2', OUTPUT2RETURN => 1 }),
    $html->element('span', '', { class => 'fa fa-thermometer-3', OUTPUT2RETURN => 1 }),
    $html->element('span', '', { class => 'fa fa-thermometer-4', OUTPUT2RETURN => 1 })
  );
}

$_COLORS[6] //= 'red';
$_COLORS[8] //= '#FFFFFF';
$_COLORS[9] //= '#FFFFFF';

my @priority_colors = ('#8A8A8A', $_COLORS[8], $_COLORS[9], '#E06161', $_COLORS[6]);

my $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_form_search($attr) - Msgs search

  Attributes:
    $attr

=cut
#**********************************************************
sub msgs_form_search {
  my ($attr) = @_;

  my $A_PRIVILEGES = $attr->{A_PRIVILEGES};
  $Msgs->{STATE_SEL} = msgs_sel_status({ ALL => 1, MULTI_SEL => 1 });
  $Msgs->{MSGS_TAGS_SEL} = msgs_sel_tags({ ALL => 1, MULTI_SEL => 1 });

  #  $Msgs->{STATE_SEL} = $html->form_select(
  #    'STATE',
  #    {
  #      SELECTED    => $FORM{STATE},
  #      SEL_OPTIONS => { '' => $lang{ALL} },
  #      STYLE       => \@msgs_status_colors,
  #      SEL_HASH    => {
  #        $msgs_status->{0} => {
  #          0             => $msgs_status->{0},
  #          3             => $msgs_status->{3},
  #          4             => $msgs_status->{4},
  #          5             => $msgs_status->{5},
  #          6             => $msgs_status->{6},
  #          7             => $msgs_status->{7},
  #          8             => $msgs_status->{8},
  #          '0;3;4;5;6;7' => "$lang{ALL}",
  #        },
  #        $msgs_status->{1} => { 1 => $msgs_status->{1} },
  #        $msgs_status->{2} => { 2 => $msgs_status->{2} },
  #      },
  #      GROUP_COLOR => 1,
  #    }
  #  );

  $Msgs->{PRIORITY_SEL} = $html->form_select(
    'PRIORITY',
    {
      SELECTED     => $FORM{PRIORITY} || 5,
      SEL_OPTIONS  => { '' => $lang{ALL} },
      SEL_ARRAY    => \@priority,
      STYLE        => \@priority_colors,
      ARRAY_NUM_ID => 1
    }
  );

  $Msgs->{CHAPTER_SEL} = $html->form_select(
    'CHAPTER',
    {
      SELECTED       => $FORM{CHAPTER} || 0,
      SEL_LIST       => $Msgs->chapters_list({ CHAPTER => join(',', keys %{ $A_PRIVILEGES }), COLS_NAME => 1 }),
      MAIN_MENU      => get_function_index('msgs_chapters'),
      MAIN_MENU_ARGV => "chg=" . ($Msgs->{CHAPTER} || q{}),
      SEL_OPTIONS    => { '' => $lang{ALL} },
    }
  );

  $Msgs->{PLAN_DATE} = "0000-00-00";
  $Msgs->{PLAN_TIME} = "00:00:00";
  $Msgs->{MSG_ID} = undef;
  $Msgs->{RESPOSIBLE_SEL} = sel_admins({ NAME => 'RESPOSIBLE' });;
  $Msgs->{PLAN_DATE_PICKER}= $html->form_daterangepicker(
    {
      NAME      => 'PLAN_FROM_DATE/PLAN_TO_DATE',
    }
  );

  form_search({
    SEARCH_FORM     => $html->tpl_show(_include('msgs_search', 'Msgs'), { %{$Msgs}, %FORM }, { OUTPUT2RETURN => 1 }),
    NO_DEFAULT_DATE => 0,
    ADDRESS_FORM    => 1,
    SHOW_PERIOD     => 1,
  });

  if ( $LIST_PARAMS{STATE} && $LIST_PARAMS{STATE} =~ s/,\s?/;/ ) {

  }

  return 1;
}

#**********************************************************
=head2 msgs_list($attr) - Message list and filters

=cut
#**********************************************************
sub msgs_list {
  my ($attr) = @_;

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });

  my $A_CHAPTER = $attr->{A_CHAPTER};

  if ( $FORM{RESPOSIBLE} ) {
    $LIST_PARAMS{RESPOSIBLE} = $FORM{RESPOSIBLE};
    $pages_qs .= "&RESPOSIBLE=$FORM{RESPOSIBLE}";
  }
  elsif ( $FORM{STATE} && $FORM{STATE} =~ /^\d+$/ && $FORM{STATE} == 8 ) {
    $pages_qs .= "&RESPOSIBLE=$admin->{AID}";
    $LIST_PARAMS{STATE} = $FORM{STATE};
  }
  my $table_add_msg_btn = !(defined($FORM{CHAPTER})) ||
      (
        $attr->{A_PRIVILEGES} &&
          $attr->{A_PRIVILEGES}->{ $FORM{CHAPTER} } &&
          $attr->{A_PRIVILEGES}->{ $FORM{CHAPTER} } > 1
      ) ||
      !(defined($attr->{A_PRIVILEGES}->{$FORM{CHAPTER}})) ? "$lang{ADD}:add_form=1&UID=" . ($FORM{UID} || '') . "&index=$index:add" : '';

  $attr->{MODULE} = 'Msgs';
  my Abills::HTML $table; my $list;

  # state for watching messages
  if($FORM{STATE} && $FORM{STATE} == 12){
    my $watched_links = $Msgs->msg_watch_list({
      COLS_NAME => 1,
      AID       => $admin->{AID}
    });
    _error_show($Msgs);

    $LIST_PARAMS{MSG_ID}= join(';', map {$_->{main_msg}} @$watched_links) || 0;
  }

  ($table, $list) = result_former({
    INPUT_DATA      => $Msgs,
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,CLIENT_ID,SUBJECT,CHAPTER_NAME,DATETIME,STATE,PRIORITY,RESPOSIBLE_ADMIN_LOGIN',
    HIDDEN_FIELDS   => 'UID,PRIORITY_ID,STATE_ID,CHG_MSGS,DEL_MSGS,ADMIN_READ,REPLIES_COUNTS,RESPOSIBLE',
    APPEND_FIELDS   => 'UID',
    FUNCTION        => 'messages_list',
    FUNCTION_FIELDS => 'msgs_admin:show:chg_msgs;uid,msgs_admin:del:del_msgs;state:&ALL_MSGS=1',
    MAP             => (!$FORM{UID}) ? 1 : undef,
    MAP_FIELDS      => 'ADDRESS_FLAT,ID,CLIENT_ID,SUBJECT',
    MAP_FILTERS     => {
      id => 'search_link:msgs_admin:UID,chg={ID}',
    },
    MULTISELECT     => scalar keys %{ $attr->{CHAPTERS_DELIGATION} } == 0 ? 'del:id:MSGS_LIST' : '',
    FILTER_VALUES => {
      rating   => sub {
        my ($rating) = @_;
        msgs_rating_icons($rating);
      },
      state    => sub {
        my ($state_id, $line) = @_;
        _msgs_list_state_form($state_id, $line, $msgs_status, $attr->{CHAPTERS_DELIGATION})
      },
      state_id => sub {
        "$_[0]";
      },
      priority => sub {
        my ($priority_id) = @_;
        $priority_id //= 3; # Normal
        $html->color_mark($priority[$priority_id], $priority_colors[$priority_id])
      },
      deposit  => sub {
        my ($deposit, $line) = @_;
        ($permissions{0} && !$permissions{0}{12})
          ? '--'
          : (($deposit || 0) + ($line->{credit} || 0) < 0)
          ? $html->color_mark($deposit, 'text-danger')
          : $deposit
      },
      id       => sub {
        my ($id, $line) = @_;
        return ($line->{inner_msg})
          ? $id . $html->b("($lang{PRIVATE_MSGS_CHAR})")
          : $id
      },
    },
    FILTER_COLS   => {
      login          =>
      "_msgs_list_login_form::FUNCTION=msgs_list,UID" . ($attr->{MODULES} ? ", MODULES=$attr->{MODULES}" : ''),
      client_id      => "_msgs_list_client_id_form::FUNCTION=msgs_list,UID,FIO,AID",
      subject        => "_msgs_list_subject_form::FUNCTION=msgs_list,UID,ID",
      plan_date_time => "_msgs_list_plan_date_time_form::FUNCTION=msgs_list,ID",
      status         => "_msgs_list_status_form::FUNCTION=msgs_list",
      disable        => "_msgs_list_status_form::FUNCTION=msgs_list",
    },
    EXT_TITLES    => {
      'id'                     => $lang{NUM},
      'client_id'              => $lang{USER},
      'subject'                => $lang{SUBJECT},
      'chapter_name'           => $lang{CHAPTERS},
      'datetime'               => $lang{DATE},
      'state'                  => $lang{STATE},
      'closed_date'            => $lang{CLOSED},
      'resposible_admin_login' => $lang{RESPOSIBLE},
      'admin_login'            => $lang{ADMIN},
      'priority'               => $lang{PRIORITY},
      'plan_date_time'         => $lang{EXECUTION},
      'run_time'               => $lang{RUN_TIME},
      'soft_deadline'          => 'Soft deadline',
      'hard_deadline'          => 'Hard deadline',
      'user_read'              => $lang{USER_READ},
      'admin_read'             => $lang{ADMIN_READ},
      'replies_counts'         => "replies_counts",
      'chapter_id'             => $lang{CHAPTERS},
      'deligation'             => $lang{DELIGATE},
      'dispatch_id'            => $lang{DISPATCH},
      'message'                => $lang{MESSAGE},
      'ip'                     => 'IP',
      'msg_phone'              => "CALL $lang{PHONE}",
      'quality_control'        => 'QUALITY_CONTROL',
      'last_replie_date'       => $lang{LAST_ACTIVITY},
      'rating'                 => $lang{RATING},
      'chg_msgs'               => $lang{NUM},
      'del_msgs'               => $lang{NUM},
      'uid'                    => 'UID',
      'downtime'               => $lang{DOWNTIME},
    },
    TABLE         => {
      width      => '100%',
      caption    => $lang{MESSAGES},
      qs         => $pages_qs
        . (defined($FORM{STATE}) ? "&STATE=$FORM{STATE}" : '&ALL_MSGS=1')
        . (!$FORM{UID} ? '&UID=' : ''),
      ID         => 'MSGS_LIST',
      header     => msgs_status_bar({ MSGS_STATUS => $msgs_status, NEXT => 1 }),
      SELECT_ALL =>
        ($attr->{CHAPTERS_DELIGATION} && scalar keys %{ $attr->{CHAPTERS_DELIGATION} } == 0) || $attr->{SELECT_ALL_ON} ? "MSGS_LIST:del:$lang{SELECT_ALL}" : ''
      ,
      EXPORT     => 1,
      MENU       => $table_add_msg_btn
        . ";$lang{SEARCH}:search_form=1&index=" . get_function_index('msgs_admin') . ":search"
    },
    MAKE_ROWS     => 1,
    SEARCH_FORMER => 1,
    MODULE        => 'Msgs',
  });

  $index = get_function_index('msgs_admin');
  _error_show($Msgs);

  if ( $FORM{UID} && !defined($FORM{STATE}) && !$FORM{ALL_MSGS} && $Msgs->{TOTAL} == 1 ) {
    msgs_ticket_show({ ID => $list->[0]->{id} });
    return 1;
  }

  if ( $FORM{subf} ) {
    $index = $FORM{subf};
  }

  my $total_msgs = $Msgs->{TOTAL};

  my $dispatch_arr = msgs_dispatch_sel(
    $attr->{ALLOW_TO_CLEAR_DISPATCH}
    ? {
        SELECTED    => $attr->{DISPATCH_ID},
        SEL_OPTIONS => { '' => '' },
      }
    : undef
  );

  if($A_CHAPTER && $#{ $A_CHAPTER } == - 1) {
    push @$dispatch_arr, $html->form_input('COMMENTS', "$lang{DEL} $lang{MESSAGES}",
        { TYPE => 'submit', class => 'btn btn-danger', FORM_ID => 'MSGS_LIST' });
  }

  my $info = '';
  foreach my $val ( @$dispatch_arr ) {
    $info .= $html->element('div', $val, { class => 'form-group' });
  }

  if($info) {
    $info = $html->element('div', $info, { class => 'well well-sm form-inline' })
  }

  my $table2 = $html->table({
    width => '100%',
    rows  => [ [ "  $lang{TOTAL}: ", $html->b($total_msgs) ] ]
  });

  print $html->form_main({
    CONTENT => $table->show({ OUTPUT2RETURN => 1 })
      . $table2->show({ OUTPUT2RETURN => 1 })
      . $info,
    HIDDEN  => {
      index => $index,
      #UID  => $FORM{UID},
      STATE => $FORM{STATE}
    },
    NAME    => 'MSGS_LIST',
    ID      => 'MSGS_LIST',
  });

  # Quick message preview
  if ( $html->{TYPE} && $html->{TYPE} eq 'html' ) {
    print '<script src="/styles/default_adm/js/msgs/message_preview.js"></script>';
  }

  return 1;
}

#**********************************************************
=head2 _msgs_list_status_form($attr) - Message list and filters

=cut
#**********************************************************
sub _msgs_list_status_form {
  my ($status) = @_;

  $_COLORS[6] //= 'red';
  $_COLORS[8] //= '#FFFFFF';
  $_COLORS[9] //= '#FFFFFF';

  $status //= 0;

  my $val;
  my @service_status = ("$lang{ENABLE}", "$lang{DISABLE}", "$lang{NOT_ACTIVE}");
  my @service_status_colors = ($_COLORS[9], $_COLORS[6], '#808080', '#0000FF', '#FF8000',
    '#009999');

  $val = ($status > 0)
    ? $html->color_mark($service_status[ $status ], $service_status_colors[ $status ])
    : "$service_status[$status]";

  return $val;
}

#**********************************************************
=head2 msgs_dispatch_sel($attr)

=cut
#**********************************************************
sub msgs_dispatch_sel {
  my ($attr) = @_;

  my @rows = (
    "$lang{DISPATCH}: ",
    $html->form_select(
      'DISPATCH_ID',
      {
        SELECTED       => $Msgs->{DISPATCH_ID} || '',
        SEL_LIST       => $Msgs->dispatch_list({ STATE => 0, COLS_NAME => 1 }),
        SEL_KEY        => 'id',
        SEL_VALUE      => 'plan_date,comments,message_count',
        MAIN_MENU      => get_function_index('msgs_dispatch'),
        MAIN_MENU_ARGV => ($Msgs->{DISPATCH_ID}) ? "chg=$Msgs->{DISPATCH_ID}" : '',
        FORM_ID        => 'MSGS_LIST',
        %{ $attr // {} }
      }
    ),
    $html->form_input('add_dispatch', "$lang{CHANGE} $lang{DISPATCH}",
      { TYPE => 'submit', OUTPUT2RETURN => 1, FORM_ID => 'MSGS_LIST' }
    )
  );

  return \@rows;
}

#**********************************************************
=head2 _msgs_list_login_form($attr) - Message list and filters

=cut
#**********************************************************
sub _msgs_list_login_form {
  my ($login, $attr) = @_;

  if ( $attr->{VALUES}->{UID} ) {
    return user_ext_menu($attr->{VALUES}->{UID}, $login,
      { EXT_PARAMS => ($attr->{VALUES}->{MODULE} ? "MODULE=" . $attr->{VALUES}->{MODULE} : undef) });
  }
}

#**********************************************************
=head2 _msgs_list_client_id_form($attr) - Message list and filters

=cut
#**********************************************************
sub _msgs_list_client_id_form {
  my ($client_id, $attr) = @_;

  my $val;

  $val = ($attr->{VALUES}->{UID} > 0 && $permissions{0}) ? $html->button($client_id,
      "index=15&UID=" . $attr->{VALUES}->{UID})          : $client_id;

  if ( $attr->{VALUES}->{FIO} && $html && $html->{TYPE} && $html->{TYPE} eq 'html') {
    $val .= $html->br() . $attr->{VALUES}->{FIO};
  }

  $val = (($attr->{VALUES}->{AID} && $attr->{VALUES}->{AID} != ($conf{USERS_WEB_ADMIN_ID} || 3)) ? $html->element(
      'span', '', {
        class => 'glyphicon glyphicon-chevron-right',
        title => $lang{OUTGOING}
      }) : '') . ($val || q{-});

  return $val;
}

#**********************************************************
=head2 _msgs_list_subject_form($attr) - Message list and filters

=cut
#**********************************************************
sub _msgs_list_subject_form {
  my ($subject, $attr) = @_;

  my $val;

  $subject = convert($subject, { text2html => 1, json => $FORM{json} });
  $val = $html->button((($subject) ? "$subject" : $lang{NO_SUBJECT}),
    "index=$index&UID=$attr->{VALUES}->{UID}&chg=$attr->{VALUES}->{ID}#last_msg");

  return $val;
}
#**********************************************************
=head2 msgs_list($attr) - Message list and filters

=cut
#**********************************************************
sub _msgs_list_plan_date_time_form {
  my ($plan_date_time, $attr) = @_;

  my $val;

  if ( $plan_date_time !~ /0000-00-00 00:00:00/ ) {
    my ($date, $time) = split(' ', $plan_date_time);
    $val = $html->button($plan_date_time,
      "index=" . get_function_index('msgs_shedule2') . "&ID=$attr->{VALUES}->{ID}&DATE=$date", { TITLE => $time });
  }
  else {
    $val = $html->button($lang{SHEDULE_BOARD},
      "index=" . get_function_index('msgs_shedule2') . "&ID=$attr->{VALUES}->{ID}&DATE=$DATE", { BUTTON => 1 });
  }

  return $val;
}


#**********************************************************
=head2 _msgs_list_state_form($attr) - Message list and filters

=cut
#**********************************************************
sub _msgs_list_state_form {
  my ($state_id, $attr, $status, $deligation) = @_;

  my $state = $html->color_mark($status->{ $state_id });

  if ( $state_id == 0 && $state ) {
    $state = $html->b($state) || $state_id;
  }

  if ($attr->{admin_read} eq '0000-00-00 00:00:00' || ($state_id eq '0' && !$attr->{replies_counts})){
    my $icon = $html->element('span', '', { class => 'glyphicon glyphicon-flag text-danger' });
    $state = $icon . ($state || '');
  }

  if ( $attr->{deligation} && $attr->{deligation} > 0 ) {
    if ( $attr->{chapter_id} && $deligation->{$attr->{chapter_id}} && $deligation->{$attr->{chapter_id}} == $attr->{deligation} ) {
      $state = $html->element('span', '', {
        class => 'glyphicon glyphicon-wrench text-danger',
        alt   => $lang{DELIVERY} }) . $state;
    }
    else {
      $state = $html->element('span', '', {
        class => 'glyphicon glyphicon-wrench text-warning',
        alt   => $lang{DELIVERY} }) . $state;
    }
  }

  return $state;
}

1;