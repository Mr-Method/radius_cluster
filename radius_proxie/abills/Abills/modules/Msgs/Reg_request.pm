=head1 NAME

  Registration request

=cut

use warnings;
use strict;
use Abills::Base qw(in_array time2sec sec2time date_diff);
use Address;

our(
  $admin,
  $db,
  %conf,
  %lang,
  $html,
  @priority,
  @priority_colors
);

my $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_unreg_requests_list($attr)

=cut
#**********************************************************
sub msgs_unreg_requests_list {
  my ($attr) = @_;

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });

  if($FORM{login_check}){
    $users->list({ LOGIN => $FORM{login_check} });
    if (  $users->{TOTAL} > 0 ) {
      print "error";
    }
    else {
      print "success";
    }
    return 1;
  }

  if ( $FORM{change} && !$attr->{NOTIFY_ID} ) {
    my %params = ();
    $params{CLOSED_DATE} = "$DATE  $TIME" if ( $FORM{STATE} > 0 );
    $params{DONE_DATE} = "$DATE  $TIME" if ( $FORM{STATE} > 1 );

    if ( $FORM{OLD_PLANNED_CONTACT} ) {
      $params{DATE} = $DATE . $TIME;
      $params{DATE} =~ s/\W//g;
      $params{OLD_PLANNED_CONTACT} = $FORM{OLD_PLANNED_CONTACT};
      $FORM{OLD_PLANNED_CONTACT} =~ s/\W//g;

      if ( int($params{DATE}) >= int($FORM{OLD_PLANNED_CONTACT}) ) {
        $FORM{LAST_CONTACT} = $params{OLD_PLANNED_CONTACT};
      }
    }
    if ( $FORM{DATETIME} && !($FORM{REACTION_TIME}) ) {
      my ($reaction_in_time, $reaction_in_days);
      my ($chg_day, $chg_time) = split(' ', $FORM{DATETIME});

      #Hours reaction
      $reaction_in_time = time2sec($TIME) - time2sec($chg_time);
      $reaction_in_time = sec2time($reaction_in_time, { format => 1 });

      #Days reaction
      $reaction_in_days = date_diff($DATE, $chg_day);
      $reaction_in_days =~ s/\-//;

      #Hours and Days reaction
      $params{REACTION_TIME} = "+" . $reaction_in_days . " " . $reaction_in_time;
    }

    $Msgs->unreg_requests_change({ %FORM, %params });

    if ( !$Msgs->{errno} ) {
      $html->message('info', $lang{INFO}, $lang{CHANGED});
    }
  }
  elsif ( $attr->{NOTIFY_ID} ) {
    if ( $attr->{NOTIFY_ID} == - 1 ) {
      my $list = $Msgs->unreg_requests_list({ UID => $attr->{UID}, STATE => '!2', COLS_NAME => 1 });
      if ( $Msgs->{TOTAL} ) {
        $attr->{NOTIFY_ID} = $list->[0]->{id};
        $attr->{ACTIVATE} = 1;
      }
      else {
        return 0;
      }
    }

    $Msgs->unreg_requests_change({
      %{$attr},
      STATE => ($conf{MSG_REGREQUEST_STATUS} && !$attr->{ACTIVATE}) ? 3 : 2, #  In work
      ID    => $attr->{NOTIFY_ID}
    });

    return 0;
  }
  elsif ( $FORM{add_user} ) {
    $Msgs->unreg_requests_info($FORM{add_user} || $FORM{NOTIFY_ID});
    my @predefined_arr = ('ID', 'LOGIN', 'FIO', 'TP_ID', 'PHONE', 'EMAIL', 'TOTAL', 'ADDRESS_FLAT', 'LOCATION_ID');

    foreach my $id ( sort keys %{$Msgs} ) {
      if ( $Msgs->{$id} && ref $Msgs->{$id} eq '' && !in_array($id, \@predefined_arr) ) {
        $Msgs->{EXT_FIELDS} .= $html->form_input($id, $Msgs->{$id}, { TYPE => 'hidden' });
      }
    }

    $Msgs->{TP_SEL} = _sel_tp($FORM{TP_ID} || $Msgs->{TP_ID});
    $Msgs->{GID_SEL} = sel_groups();
    $Msgs->{ACTION_LNG} = $lang{ADD};

#    if ( defined($FORM{LOGIN}) ) {
#      if ( $FORM{LOGIN} ) {
#        $Msgs->{LOGIN} = $FORM{LOGIN};
#        $users->list({ LOGIN => $FORM{LOGIN} });
#        if ( $users->{TOTAL} > 0 ) {
#          $html->message('err', $lang{ERROR}, "$lang{USER_EXIST}");
#        }
#        else {
#          $html->message('info', $lang{INFO}, "$lang{LOGIN}  $lang{ACCEPT}");
#          $index = get_function_index('form_wizard');
#          $Msgs->{ACTION_LNG} = $lang{NEXT};
#        }
#      }
#    }
    $index = get_function_index('form_wizard');
    $Msgs->{CHECK_LOGIN_INDEX}=get_function_index('msgs_unreg_requests_list');

    $html->tpl_show(_include('msgs_add_user', 'Msgs'),
      { %FORM, %{$Msgs}, FIO => ($FORM{FIO}) ? $FORM{FIO} : $Msgs->{FIO} });

    return 0;
  }
  elsif ( $FORM{chg} ) {
    $Msgs->unreg_requests_info($FORM{chg});
    $Msgs->{OLD_PLANNED_CONTACT} = $Msgs->{PLANNED_CONTACT};
    $Msgs->{PLANNED_CONTACT} = $html->form_datetimepicker('PLANNED_CONTACT', $Msgs->{PLANNED_CONTACT});

    $Msgs->{ACTION} = 'change';
    $Msgs->{LNG_ACTION} = $lang{CHANGE};
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ) {
    if($FORM{del} =~ /\,/){
      my @ids_to_delete = split('\,', $FORM{del});

      foreach my $id (@ids_to_delete){
        $Msgs->unreg_requests_del({ ID => $id });
        $html->message('info', $lang{INFO}, "$lang{DELETED}") if ( !$Msgs->{errno} );
      }
    }
    else{
      $Msgs->unreg_requests_del({ ID => $FORM{del} });
      $html->message('info', $lang{INFO}, "$lang{DELETED}") if ( !$Msgs->{errno} );
    }

  }

  if ( $FORM{qindex} && $FORM{chg} ) {
    $Msgs->{PRIORITY_SEL} = $html->form_select(
      'PRIORITY',
      {
        SELECTED     => $FORM{PRIORITY} || 2,
        SEL_ARRAY    => \@priority,
        STYLE        => \@priority_colors,
        ARRAY_NUM_ID => 1
      }
    );

    $Msgs->{STATE_SEL} = msgs_sel_status();

    $Msgs->{STATE_NAME} = $html->color_mark($msgs_status->{ $Msgs->{STATE} });
    $Msgs->{TP_SEL} = _sel_tp($Msgs->{TP_ID});
    $Msgs->{PAID} = 'checked' if ($Msgs->{PAID});
    $Msgs->{UNREG_EXTRA_INFO} = $html->tpl_show(_include('msgs_client_extra_info', 'Msgs'), $Msgs, { OUTPUT2RETURN => 1 });

    $html->tpl_show(_include('msgs_request_show', 'Msgs'), $Msgs);
    return 0;
  }

  my ($A_CHAPTER, $A_PRIVILEGES, $CHAPTERS_DELIGATION) = msgs_admin_privileges($admin->{AID});

  if ( $#{ $A_CHAPTER } > - 1 ) {
    $LIST_PARAMS{CHAPTER} = join(',  ', @{ $A_CHAPTER });
    $LIST_PARAMS{UID} = undef if ( !$FORM{UID} );
  }

  if ( !$attr->{LIST_ONLY} && $FORM{search_form} ) {
    $Msgs->{RESPOSIBLE_SEL} = sel_admins({ NAME => 'RESPOSIBLE' });
    $Msgs->{STATE_SEL} = msgs_sel_status({ ALL => 1, MULTI_SEL => 1 });

    $Msgs->{PRIORITY_SEL} = $html->form_select(
      'PRIORITY',
      {
        SELECTED     => $FORM{PRIORITY} || 5,
        SEL_ARRAY    => [ @priority, "$lang{ALL}" ],
        STYLE        => \@priority_colors,
        ARRAY_NUM_ID => 1
      }
    );

    $Msgs->{CHAPTER_SEL} = $html->form_select(
      'CHAPTER',
      {
        SELECTED       => $Msgs->{CHAPTER} || $FORM{CHAPTER} || '',
        SEL_LIST       => $Msgs->chapters_list({ COLS_NAME => 1 }),
        MAIN_MENU      => get_function_index('msgs_chapters'),
        MAIN_MENU_ARGV => ($Msgs->{CHAPTER}) ? "chg=$Msgs->{CHAPTER}" : q{},
        SEL_OPTIONS    => { '' => $lang{ALL} },
      }
    );

    $Msgs->{PLAN_DATE} = "0000-00-00";
    $Msgs->{PLAN_TIME} = "00:00:00";

    $Msgs->{REQUESTS_ID_FORM} = $FORM{ID} || '';

    form_search(
      {
        SEARCH_FORM  =>
          $html->tpl_show(_include('msgs_request_search', 'Msgs'), { %{$Msgs}, %FORM }, { OUTPUT2RETURN => 1 }),
        ADDRESS_FORM => 1,
        SHOW_PERIOD => 1
      }
    );
  }

  $LIST_PARAMS{STATE} = undef if ( $FORM{STATE} && $FORM{STATE} == 3 );
  $LIST_PARAMS{PRIORITY} = undef if ( $FORM{PRIORITY} && $FORM{PRIORITY} == 5 );
  $LIST_PARAMS{DESC} = 'DESC' if ( !$FORM{sort} );

  if ( !defined($FORM{STATE}) && !$FORM{ALL_MSGS} ) {
    $LIST_PARAMS{STATE} = 0;
    $FORM{STATE} = 0;
  }

  $LIST_PARAMS{CHAPTER} = $FORM{CHAPTER};

  $FORM{UID} = 0 if ( !$FORM{UID} );
  my Abills::HTML $table;
  my $list;
  ($table, $list) = result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'unreg_requests_list',
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'ID,DATETIME,SUBJECT,FIO,CHAPTER,STATE,CLOSED_DATE,ADMIN_LOGIN',
    FUNCTION_FIELDS => 'null, null,null',
    MAP             => (!$FORM{UID}) ? 1 : undef,
    MAP_FIELDS      => 'ID,PHONE,FIO,ADDRESS_FLAT',
    MAP_FILTERS     => { id => 'search_link:msgs_unreg_requests:UID,chg={ID}',
    },
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      'id'                     => "$lang{NUM}",
      'fio'                    => $lang{FIO},
      'phone'                  => $lang{PHONE},
      'email'                  => 'E-MAIL',
      'subject'                => $lang{SUBJECT},
      'chapter_name'           => $lang{CHAPTERS},
      'datetime'               => "$lang{DATE}",
      'state'                  => "$lang{STATE}",
      'closed_date'            => "$lang{CLOSED}",
      'resposible_admin_login' => $lang{RESPOSIBLE},
      'admin_login'            => $lang{ADMIN},
      'priority'               => $lang{PRIORITY},
      'connection_time'        => "$lang{EXECUTION}",
      'ip'                     => 'IP',
      'district_name'          => "$lang{DISTRICTS}",
      'address_full'           => "$lang{FULL}  $lang{ADDRESS}",
      'address_street'         => "$lang{ADDRESS_STREET}",
      'address_build'          => "$lang{ADDRESS_BUILD}",
      'address_flat'           => "$lang{ADDRESS_FLAT}",
      'city'                   => "$lang{CITY}",
      'zip'                    => "$lang{ZIP}",
      'change_time'            => "$lang{LAST_ACTIVITY}",
      'reaction_time'          => "$lang{REACTION_TIME}",
      'comments'               => "$lang{COMMENTS}",
      'contact_note'           => "$lang{NOTE}",
    },
    TABLE           => {
      width      => '100%',
      caption    => "$lang{REQUESTS}",
      qs         => $pages_qs,
      ID         => 'MSGS_UNREG_LIST',
      header     => msgs_status_bar({ MSGS_STATUS => $msgs_status }),
      SELECT_ALL => (scalar keys %{ $CHAPTERS_DELIGATION } > - 1) ? "MSGS_UNREG_LIST:del:$lang{SELECT_ALL}" : '',
      EXPORT     => 1,
      MENU       =>
      "$lang{ADD}:add_form=1&UID=$FORM{UID}&index=" . get_function_index('msgs_unreg_requests') . ":add" . ";$lang{SEARCH}:search_form=1&index=" . get_function_index('msgs_unreg_requests_list') . ":search",
    }
  });

  if ( $list && $list == - 1 ) {
    return 0;
  }

  foreach my $line ( @{$list} ) {
    my @fields_array = ();
    for ( my $i = 0; $i < $Msgs->{SEARCH_FIELDS_COUNT} + 1; $i++ ) {
      my $val = '';
      my $field_name = $Msgs->{COL_NAMES_ARR}->[$i];
      if ( $field_name =~ /datetime|id/ ) {
        $val = $html->button(
          $line->{ $field_name },
          "#",
          {
            NEW_WINDOW      =>
            "$SELF_URL?qindex=" . (($attr->{LIST_ONLY}) ? $index - 1 : $index) . "&chg=$line->{id}&header=1",
            NEW_WINDOW_SIZE => "640:600",
          }
        );
      }
      elsif ( $field_name eq 'priority' ) {
        $val = $html->color_mark($priority[ $line->{priority} ], $priority_colors[ $line->{priority} ]);
      }
      elsif ( $field_name eq 'state' ) {
        my $state = $html->color_mark($msgs_status->{ $line->{state} });
        if ( $line->{state} == 0 ) {
          $state = $html->b($state);
        }

        $state = $html->element('span', $state, { class =>
            "glyphicon glyphicon-flag  text-danger" }) if ( $line->{admin_read} && $line->{admin_read} eq '0000-00-00 00:00:00' );

        if ( $line->{deligation} && $line->{deligation} > 0 ) {
          if ( $attr->{CHAPTERS_DELIGATION}->{ $line->{chapter_id} } == $line->{deligation} ) {
            $state = $html->element('span', '',
              { class => "glyphicon glyphicon-wrench text-danger", alt => "' . $lang{DELIVERED} . '" }) . $state;
          }
          else {
            $state = $html->element('span', '',
              { class => "glyphicon glyphicon-wrench  text-warning", alt => "' . $lang{DELIVERED} . '" }) . $state;
          }
        }

        $val = $state;
      }
      elsif ( $field_name =~ /status|disable/ ) {
        my @service_status = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE});
        my @service_status_colors = ("$_COLORS[9]", 'text-danger', '#808080', '#0000FF', '#FF8000', '#009999');

        $val = ($line->{ $field_name } > 0)                   ? $html->color_mark(
            $service_status[ $line->{ $field_name } ],
            $service_status_colors[ $line->{ $field_name } ]) : "$service_status[$line->{$field_name}]";
      }
      else {
        $val = $line->{ $field_name };
      }

      push @fields_array, $val;
    }

    push @fields_array,
      $html->button(
        $lang{SHOW}, "#",
        {
          NEW_WINDOW      =>
          "$SELF_URL?qindex=" . (($attr->{LIST_ONLY}) ? $index - 1 : $index) . "&chg=$line->{id}&header=1",
          NEW_WINDOW_SIZE => "640:700",
          class           => 'show'
        }
      )
        . ' ' .
        (($line->{uid}) ? $html->button($lang{INFO}, "index=15&UID=$line->{uid}", { class => 'user' }) : $html->button(
            $lang{ADD}, "index=". get_function_index('msgs_unreg_requests_list') ."&add_user=$line->{id}", { class => 'add', TITLE => $lang{ADD_USER} }))
        . ' ' .
        # reg_request do not have any chapter id!  (0)
        # (((($A_PRIVILEGES->{ $line->{chapter_id} } && $A_PRIVILEGES->{ $line->{chapter_id} } > 2)
        #     || ($A_CHAPTER && $#{ $A_CHAPTER } == - 1))                                                     ? 
          $html->button(
            $lang{DEL}, "index=$index&del=$line->{id}$pages_qs",
            { MESSAGE => "$lang{DEL} [$line->{id}] " . ($line->{subject} || q{}) . "  ?", class => 'del' });
          # : ''));

    $table->addrow($html->form_input('del', $line->{id}, { TYPE => 'checkbox', FORM_ID => 'MSGS_UNREG_LIST' }),
      @fields_array);
  }

  my $total_msgs = $Msgs->{TOTAL};

  print $html->form_main(
    {
      CONTENT => $table->show(),
      HIDDEN  => {
        index => $index,
        UID   => $FORM{UID},
        STATE => $FORM{STATE}
      },
      SUBMIT  => ($#{ $A_CHAPTER } == - 1) ? { COMMENTS => $lang{DEL} } : undef,
      NAME    => 'MSGS_UNREG_LIST',
      ID      => 'MSGS_UNREG_LIST'
    }
  );

  $table = $html->table({
    width => '100%',
    rows  => [ [ "  $lang{TOTAL}: ", $html->b($total_msgs) ] ]
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 msgs_unreg_requests($attr)

=cut
#**********************************************************
sub msgs_unreg_requests {
  my ($attr) = @_;

  if ( $FORM{add} ) {
    if ( $FORM{LOGIN} ) {
      $users->list({ LOGIN => $FORM{LOGIN} });
      if ( $users->{TOTAL} > 0 ) {
        $html->message('err', $lang{ERROR}, "$lang{USER_EXIST}");
        return 0;
      }
    }
    else {
      $FORM{LOGIN} = q{};
    }

    $Msgs->unreg_requests_add(\%FORM);

    if ( in_array('Events', \@MODULES) ) {
      require Events::API;
      Events::API->import();
      my $Events_api = Events::API->new($db, $admin, \%conf);

      $Events_api->add_event({
        MODULE      => 'Msgs',
        TITLE       => $lang{REQUESTS},
        COMMENTS    => $FORM{FIO} || '',
        EXTRA       => '?get_index=msgs_unreg_requests_list&full=1',
        GROUP_NAME  => 'CLIENTS',
        PRIORITY_ID => 3,
      });
    }

    $html->message('info', $lang{INFO}, $lang{SENDED}) if ( !$Msgs->{errno} );

    if ( $FORM{REGISTRATION_REQUEST} ) {
      return 2;
    }
  }

  _error_show($Msgs);

  $Msgs->{ACTION} = 'add';
  $Msgs->{LNG_ACTION} = $lang{SEND};

  $Msgs->{PRIORITY_SEL} = $html->form_select(
    'PRIORITY',
    {
      SELECTED     => $FORM{PRIORITY} || 2,
      SEL_ARRAY    => \@priority,
      STYLE        => \@priority_colors,
      ARRAY_NUM_ID => 1
    }
  );

  $Msgs->{STATE_SEL} = msgs_sel_status();
  $Msgs->{DATE} = "$DATE  $TIME";

  $Msgs->{CHAPTER_SEL} = $html->form_select(
    'CHAPTER',
    {
      SELECTED       => $Msgs->{CHAPTER} || undef,
      SEL_LIST       => $Msgs->chapters_list({ CHAPTER => $LIST_PARAMS{CHAPTER}, COLS_NAME => 1 }),
      MAIN_MENU      => get_function_index('msgs_chapters'),
      MAIN_MENU_ARGV => "chg=" . ($Msgs->{CHAPTER} || '')
    }
  );

  require Control::Address_mng;
  $Msgs->{ADDRESS_TPL}     = form_address({
    SHOW         => 1,
    REGISTRATION_HIDE_ADDRESS_BUTTON => $attr->{REGISTRATION_HIDE_ADDRESS_BUTTON} || 0,
  });
  $Msgs->{TP_SEL}          = _sel_tp();
  $Msgs->{UNREG_EXTRA_INFO}= $html->tpl_show(_include('msgs_client_extra_info', 'Msgs'), $Msgs, { OUTPUT2RETURN => 1 });

  my $map_visible = 0;

  if ( $FORM{REGISTRATION_REQUEST} ) {
    if ( in_array('Maps', \@MODULES) ) {
      load_module('Maps', $html);
      $Msgs->{MAPS} = maps_show_map({
        QUICK             => 1,
        OUTPUT2RETURN     => 1,
        SMALL             => 1,
        SHOW_BUILDS       => 1,
        GET_USER_POSITION => 1,
        MAP_HEIGHT        => 40,
        CLIENT_MAP        => 1,
      });

      $map_visible = 1;
    }

    $html->tpl_show(_include('msgs_client_reg_request', 'Msgs'), {
      %{$attr}, %{$Msgs},
      MAP_VISIBLE      => $map_visible,
      FORM_COL_CLASSES => $map_visible ? '' : 'col-md-push-3',
    });
  }
  else {
    $Msgs->{RESPOSIBLE_SEL} = sel_admins({ NAME => 'RESPOSIBLE' });
    $html->tpl_show(_include('msgs_unreg_request', 'Msgs'), $Msgs);
    msgs_unreg_requests_list({
      LIST_ONLY => 1
    });
  }

  return 1;
}

#**********************************************************
=head2 _sel_tp($tp_id)

=cut
#**********************************************************
sub _sel_tp {
  my ($tp_id) = @_;

  if ( in_array('Dv', \@MODULES) || in_array('Internet', \@MODULES)) {
    require Tariffs;
    Tariffs->import();
    my $Tariffs = Tariffs->new($db, \%conf, $admin);

    return $html->form_select(
      'TP_ID',
      {
        SELECTED  => $tp_id,
        SEL_LIST  => $Tariffs->list({ MODULE => 'Dv;Internet', DOMAIN_ID => $admin->{DOMAIN_ID}, COLS_NAME => 1 }),
        SEL_VALUE => 'id,name',
      }
    );
  }
  else {
    return $html->form_input('TP_ID', '');
  }
}

1
