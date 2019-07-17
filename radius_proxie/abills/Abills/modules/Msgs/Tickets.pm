=head2 NAME

  Tasks

=cut

use strict;
use warnings FATAL => 'all';
use Encode qw(_utf8_on);

use Abills::Base qw(urlencode in_array int2byte convert);
use Msgs::Misc::Attachments;
use Shedule;

our(
  $db,
  %conf,
  %lang,
  $admin,
  $html,
  %permissions,
  @WEEKDAYS,
  @MONTHES
);


my $Msgs = Msgs->new($db, $admin, \%conf);
my $Sender = Abills::Sender::Core->new($db, $admin, \%conf);
my $Attachments = Msgs::Misc::Attachments->new($db, $admin, \%conf);

my @send_methods = ($lang{MESSAGE}, 'E-MAIL');
my @priority_colors = ('#8A8A8A', $_COLORS[8], $_COLORS[9], '#E06161', $_COLORS[6]);
my @priority = ($lang{VERY_LOW}, $lang{LOW}, $lang{NORMAL}, $lang{HIGH}, $lang{VERY_HIGH});

$_COLORS[6] //= 'red';
$_COLORS[8] //= '#FFFFFF';
$_COLORS[9] //= '#FFFFFF';

if ( in_array('Sms', \@MODULES) ) {
  $send_methods[2] = ($lang{SEND} || q{}) ." SMS";
}
if ( $conf{MSGS_REDIRECT_FILTER_ADD} ) {
  $send_methods[3] = 'Web redirect';
}


#**********************************************************
=head2 msgs_admin_privileges($attr)

  Arguments:
    $aid

  Returns:
    \@A_CHAPTER, \%A_PRIVILEGES, \%CHAPTERS_DELIGATION

=cut
#**********************************************************
sub msgs_admin_privileges {
  my ($aid) = @_;

  my $a_list = $Msgs->admins_list({ AID => $aid, DISABLE => 0 });
  my %A_PRIVILEGES = ();
  my %CHAPTERS_DELIGATION = ();
  my @A_CHAPTER = ();

  foreach my $line ( @{$a_list} ) {
    if ( $line->[5] > 0 ) {
      push @A_CHAPTER, "$line->[5]:$line->[3]";
      $CHAPTERS_DELIGATION{ $line->[5] } = $line->[3];
      $A_PRIVILEGES{ $line->[5] } = $line->[2];
    }
  }

  return \@A_CHAPTER, \%A_PRIVILEGES, \%CHAPTERS_DELIGATION;
}

#**********************************************************
=head2 msgs_admin($attr) - Admin messages

  Attributes:
    $attr

=cut
#**********************************************************
sub msgs_admin {
  my ($attr) = @_;

  $Msgs->{TAB1_ACTIVE} = "active";

  $FORM{chg} = $FORM{CHG_MSGS} if ( $FORM{CHG_MSGS} );
  $FORM{del} = $FORM{DEL_MSGS} if ( $FORM{DEL_MSGS} );

  $Msgs->{ACTION} = 'send';
  $Msgs->{LNG_ACTION} = $lang{SEND};
  my $uid = $FORM{UID};

  #Get admin privileges
  my ($A_CHAPTER, $A_PRIVILEGES, $CHAPTERS_DELIGATION) = msgs_admin_privileges($admin->{AID});

  if($FORM{ajax} && $FORM{SURVEY_ID}){
    $Msgs->survey_subject_info($FORM{SURVEY_ID});
    print "$Msgs->{TPL}";
    return 1;
  }

  if ( $FORM{MSG_HISTORY} ) {
    form_changes({
      SEARCH_PARAMS => {
        MODULE => 'Msgs',
        ACTION => 'MSG_ID:'. $FORM{MSG_HISTORY} ."*"
      }
    });

    return 1;
  }
  elsif($FORM{TASK}) {
    require Msgs::Tasks;
    msgs_tasks();
    return 1;
  }
  elsif ( $FORM{CHANGE_SUBJECT} && $FORM{SUBJECT} ne '' ){
    $Msgs->message_change({
      ID      => $FORM{chg},
      SUBJECT => $FORM{SUBJECT},
    });
    _error_show($Msgs);

    $Msgs->message_reply_add({
      ID               => $FORM{chg},
      REPLY_TEXT       => "$lang{SUBJECT_CHANGED} '$FORM{OLD_SUBJECT}' $lang{ON} '$FORM{SUBJECT}'",
      REPLY_INNER_MSG  => 1,
      AID              => $admin->{AID},
    });
    _error_show($Msgs);
  }
  elsif ( $FORM{CHANGE_MSGS_TAGS} ) {
    $Msgs->{TAB1_ACTIVE} = "active";
    $Msgs->quick_replys_tags_add({ IDS => $FORM{TAGS_IDS}, MSG_ID => $FORM{chg} });
    if ( !$Msgs->{errno} ) {
      $html->message('info', $lang{INFO}, "$lang{ADD} $Msgs->{TOTAL} $lang{TAGS}");
    }
  }
  elsif ( $FORM{MSG_PRINT_ID} ) {
    msgs_ticket_form({ MSG_PRINT_ID => $FORM{MSG_PRINT_ID}, UID => $uid });
    return 1;
  }
  elsif ( $FORM{NEXT_MSG} ) {
    # Get next message
    my $list = $Msgs->messages_list({
      ID        => ">$FORM{NEXT_MSG}",
      STATE     => 0,
      PAGE_ROWS => 1,
      COLS_NAME => 1,
    });

    if ( $Msgs->{TOTAL} > 0 ) {
      my $user_info = user_info($list->[0]->{uid});
      if($user_info) {
        print $user_info->{TABLE_SHOW} || q{};
      }
      msgs_ticket_show({ ID => $list->[0]->{id} });
      return 1;
    }
  }
  elsif ( $FORM{deligate} ) {
    $Msgs->message_change({
      ID         => $FORM{deligate},
      DELIGATION => $FORM{level},
      ADMIN_READ => "0000-00-00 00:00:00",
      RESPOSIBLE => 0,
    });

    $Msgs->message_reply_add({
      ID              => $FORM{deligate},
      AID             => $conf{SYSTEM_ADMIN_ID} || 2,
      IP              => $admin->{SESSION_IP},
      STATE           => 0,
      REPLY_TEXT      => "$lang{DELIGATE} : " . ($admin->{A_FIO} || $admin->{A_LOGIN} || ''),
      REPLY_INNER_MSG => 1
    });

    $html->message('info', $lang{INFO}, "$lang{DELIGATED}") if ( !$Msgs->{errno} );
  }
  elsif ( $FORM{WORK} ) {
    if ( !msgs_work({ WORK_LIST => 1, UID => $uid, MESSAGE_ID => $FORM{WORK}, MNG => 1 }) ) {
      return 1;
    }

    msgs_ticket_show({
      ID                  => $FORM{WORK},
      A_PRIVILEGES        => $A_PRIVILEGES,
      CHAPTERS_DELIGATION => $CHAPTERS_DELIGATION,
    });

    msgs_work({ WORK_LIST => 1, MESSAGE_ID => $FORM{WORK}, UID => $uid });

    return 1;
  }
  elsif ( $FORM{export} ) {
    msgs_export();
    return 1;
  }
  elsif ( $FORM{add_dispatch} && $FORM{del} ) {
    my @ids = split(/, /, $FORM{del});
    for my $id ( @ids ) {
      $Msgs->message_change(
        {
          DISPATCH_ID => $FORM{DISPATCH_ID},
          ID          => $id
        }
      );
    }

    $html->message('info', $lang{INFO}, "$lang{DISPATCH} $lang{ADD} # $FORM{del}") if ( !$Msgs->{errno} );
  }
  elsif ( $FORM{reply} && $FORM{ID}) {
    # Add message reply
    $Msgs->{TAB2_ACTIVE} = "active";
    _msgs_reply_admin();
    return 1;
  }
  elsif ( $FORM{ATTACHMENT} ) {
    return msgs_attachment_show(\%FORM);
  }
  elsif ( $FORM{PHOTO} ) {
    my $media_return = form_image_mng({
      TO_RETURN => 1,
      #EXTERNAL_ID =>
    });

    if ( $FORM{IMAGE} ) {
      $FORM{reply} = 1;
      $FORM{ID} = $FORM{PHOTO};
      $FORM{FILE_UPLOAD} = $media_return;
      msgs_admin();
    }

    return 0;
  }

  if ( $FORM{chg} ) {
    $Msgs->{TAB2_ACTIVE} = (!$Msgs->{TAB1_ACTIVE}) ? "active" : "";
    msgs_ticket_show({
      A_PRIVILEGES        => $A_PRIVILEGES,
      CHAPTERS_DELIGATION => $CHAPTERS_DELIGATION,
    });

    msgs_work({ WORK_LIST => 1, MESSAGE_ID => $FORM{chg}, UID => $uid });
    return 0;
  }
  elsif ( $FORM{change} ) {
    msgs_ticket_change();

    msgs_ticket_show({
      A_PRIVILEGES        => $A_PRIVILEGES,
      CHAPTERS_DELIGATION => $CHAPTERS_DELIGATION,
    });

    return 1;
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ) {
    msgs_redirect_filter({
      DEL    => 1,
      UID    => $uid,
      MSG_ID => $FORM{del}
    });

    $Msgs->message_del({ ID => $FORM{del}, UID => $uid });
    $html->message('info', $lang{INFO}, "$lang{DELETED} # $FORM{del}") if ( !$Msgs->{errno} );
  }

  if ( scalar keys %{ $CHAPTERS_DELIGATION } > 0 ) {
    $LIST_PARAMS{CHAPTERS_DELIGATION} = $CHAPTERS_DELIGATION;
    $LIST_PARAMS{PRIVILEGES} = $A_PRIVILEGES;
    $LIST_PARAMS{UID} = undef if ( !$uid );
  }

  if ( $FORM{search_form} ) {
    msgs_form_search({ A_PRIVILEGES => $A_PRIVILEGES });
  }
  elsif ( $FORM{add_form} ) {
    my $return = msgs_admin_add();
    return ($return == 2) ? 2 : 1;
  }

  $LIST_PARAMS{STATE} = undef if ( $FORM{STATE} && $FORM{STATE} =~ /^\d+$/ && $FORM{STATE} == 3 );
  $LIST_PARAMS{PRIORITY} = undef if ( $FORM{PRIORITY} && $FORM{PRIORITY} == 5 );
  $LIST_PARAMS{CHAPTER} = $FORM{CHAPTER} if ( $FORM{CHAPTER} );
  $LIST_PARAMS{DESC} = 'DESC' if ( !$FORM{sort} );
  $LIST_PARAMS{RESPOSIBLE} = $attr->{ADMIN}->{AID} if ( $attr->{ADMIN}->{AID} );

  msgs_list({
    A_PRIVILEGES        => $A_PRIVILEGES,
    A_CHAPTER           => $A_CHAPTER,
    CHAPTERS_DELIGATION => $CHAPTERS_DELIGATION,
  });

  return 1;
}

#**********************************************************
=head2 msgs_ticket_change($attr)

=cut
#**********************************************************
sub msgs_ticket_change {

  $Msgs->{TAB3_ACTIVE} = "active";
  if ( $FORM{STATE} && $FORM{STATE} > 0 ) {
    $FORM{DONE_DATE} = $DATE if ( $FORM{STATE} == 2 );
    $FORM{CLOSED_DATE} = "$DATE  $TIME" if ( $FORM{STATE} == 1 || $FORM{STATE} == 2 );
  }

  #Watch
  if ( $FORM{WATCH} ) {
    if ( $FORM{del} ) {
      $Msgs->msg_watch_del({ ID => $FORM{ID}, AID => $admin->{AID} });
    }
    else {
      $Msgs->msg_watch(\%FORM);
    }
  }
  else {
    # _msgs_change_resposible will need AID of current responsible admin,
    # so should be executed first
    # We skip changing inside to avoid unnecessary queries
    if ( defined $FORM{RESPOSIBLE} ) {
      _msgs_change_responsible($FORM{ID}, $FORM{RESPOSIBLE}, {
        SKIP_CHANGE => 1
      });
    }
    $Msgs->message_change({ %FORM, USER_READ => "0000-00-00  00:00:00" });
  }

  if ( !_error_show($Msgs) ) {
    $html->message('info', $lang{INFO}, "$lang{CHANGED}");
  }

  $FORM{chg} = $FORM{ID} if ( $FORM{ID} );

  return 1;
}

#**********************************************************
=head2 msgs_admin_add($attr)

=cut
#**********************************************************
sub msgs_admin_add {
  my ($attr) = @_;

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });

  if($FORM{add_form} && $FORM{next}) {
    $FORM{send_message} = 1;
  }

  if ( $FORM{send_message} || $FORM{PREVIEW} ) {
    #Multi send
    my $message = '';
    my @msgs_ids = ();
    my %NUMBERS = ();
    my @ATTACHMENTS = ();
    if ( $FORM{DISPATCH_CREATE} ) {
      $FORM{COMMENTS} = $FORM{DISPATCH_COMMENTS};
      $Msgs->dispatch_add({ %FORM, PLAN_DATE => $FORM{DISPATCH_PLAN_DATE} });
      $FORM{DISPATCH_ID} = $Msgs->{DISPATCH_ID};
      $html->message('info', $lang{INFO}, "$lang{DISPATCH} $lang{ADDED}") if ( !$Msgs->{errno} );
    }

    if ( $FORM{DELIVERY_CREATE} ) {
      $Msgs->msgs_delivery_add({ %FORM,
        SUBJECT     => $FORM{DELIVERY_COMMENTS},
        SEND_DATE   => $FORM{DELIVERY_SEND_DATE},
        SEND_TIME   => $FORM{DELIVERY_SEND_TIME},
        SEND_METHOD => $FORM{DELIVERY_SEND_METHOD},
        STATUS      => $FORM{DELIVERY_STATUS},
        PRIORITY    => $FORM{DELIVERY_PRIORITY},
      });

      $FORM{DELIVERY} = $Msgs->{DELIVERY_ID};
      $html->message('info', $lang{INFO}, "$lang{DELIVERY} $lang{ADDED}") if ( !$Msgs->{errno} );
    }


    for ( my $i = 0; $i <= 2; $i++ ) {

      # First input will come without underscore
      my $input_name = 'FILE_UPLOAD' . (($i > 0) ? "_$i" : '');

      if ( $FORM{ $input_name }->{filename} ) {
        push @ATTACHMENTS,
          {
            FILENAME     => $FORM{ $input_name }->{filename},
            CONTENT_TYPE => $FORM{ $input_name }->{'Content-Type'},
            FILESIZE     => $FORM{ $input_name }->{Size},
            CONTENT      => $FORM{ $input_name }->{Contents},
          };
      }
    }

    if ( $FORM{SEND_TYPE} && $FORM{SEND_TYPE} == 1 ) {
      $FORM{INNER_MSG} = 1;
      $FORM{STATE} = 2;
    }

    if ( $FORM{UID} ) {
      $FORM{UID} =~ s/,/;/g;
    }

    my $users_list = $users->list({
      LOGIN     => '_SHOW',
      FIO       => '_SHOW',
      PHONE     => '_SHOW',
      EMAIL     => '_SHOW',
      %FORM,
      UID       => ($FORM{UID} && $FORM{UID} =~ /\d+/) ? $FORM{UID} : undef,
      GID       => $FORM{GID},
      PAGE_ROWS => 1000000,
      DISABLE   => ($FORM{GID}) ? 0 : undef,
      COLS_NAME => 1
    });

    if ( $users->{TOTAL} < 1 ) {
      $html->message('err', $lang{ERROR}, "$lang{USER_NOT_EXIST} $FORM{UID}", { ID => 700 });
      return 0;
    }
    elsif ( _error_show($users) ) {

    }

    if ( $FORM{PREVIEW} ) {
      $html->message('info', $lang{INFO}, "$lang{PRE}\n $lang{TOTAL}: $users->{TOTAL}");
      my Abills::HTML $table;
      $users->{TOTAL} = '';
      ($table) = result_former({
        INPUT_DATA      => $users,
        LIST            => $users_list,
        BASE_FIELDS     => 1,
        MULTISELECT     => 'UID:uid',
        FUNCTION_FIELDS => '',
        TABLE           => {
          width      => '100%',
          #caption    => "$lang{PRE} - $lang{USERS}",
          qs         => $pages_qs,
          ID         => 'USERS_LIST',
          SELECT_ALL => "users_list:UID:$lang{SELECT_ALL}",
        },
        MAKE_ROWS       => 1,
      });

      $attr->{PREVIEW_FORM} = $table->show();
      delete ($FORM{UID});
    }
    elsif ( $FORM{DELIVERY} ) {
      my $uids = '';
      foreach my $line ( @{$users_list} ) {
        $uids .= $line->{uid} . ', ';
      }

      $Msgs->delivery_user_list_add({
        MDELIVERY_ID => $FORM{DELIVERY},
        IDS          => $uids,
      });
      $html->message('info', $lang{INFO},
        "$Msgs->{TOTAL} $lang{USERS_ADDED_TO_DELIVERY} №:$FORM{DELIVERY}") if ( !$Msgs->{errno} );
    }
    #Send message
    else {
      if ( $FORM{SURVEY_ID} && !$FORM{SUBJECT} ) {
        $Msgs->survey_subject_info($FORM{SURVEY_ID});
        $FORM{SUBJECT} = $Msgs->{NAME} || q{};

        if ( $Msgs->{FILENAME} ) {
          push @ATTACHMENTS,
            {
              FILENAME     => $Msgs->{FILENAME} || q{},
              CONTENT_TYPE => $Msgs->{FILE_CONTENT_TYPE} || '',
              FILESIZE     => $Msgs->{FILE_SIZE} || '',
              CONTENT      => $Msgs->{FILE_CONTENTS} || '',
            };
        }
      }

      my @uids = ();
      my %msg_for_uid = ();
      foreach my $user_info ( @{$users_list} ) {
        $FORM{UID} = $user_info->{uid};
        if ($user_info->{phone}) {
          $user_info->{phone} =~ s/(.*);.*/$1/;
          $NUMBERS{ $user_info->{phone} } = $user_info->{uid};
        }
        push @uids, $user_info->{uid};

        # #630. TEMPLATES VARIABLES IN MESSAGES
        my $user_pi = $users->pi({ UID => $user_info->{uid}, COLS_NAME => 1, COLS_UPPER => 1 });
        my $dv_info = {};
        if ( in_array('Dv', \@MODULES) ) {
          require Dv; Dv->import();
          my $Dv = Dv->new($db, $admin, \%conf);
          $dv_info = $Dv->info($user_info->{uid}, { COLS_NAME => 1, COLS_UPPER => 1 });
        }

        $message = $html->tpl_show($FORM{MESSAGE}, { %{$user_pi}, %{$dv_info} }, {
          OUTPUT2RETURN      => 1,
          SKIP_DEBUG_MARKERS => 1
        });

        if ($FORM{DAY}) {
          require JSON;

          _utf8_on($FORM{SUBJECT});
          _utf8_on($message);

          my $args = {
            UID        => $user_info->{uid},
            CHAPTER    => $FORM{CHAPTER},
            SUBJECT    => $FORM{SUBJECT},
            PRIORITY   => $FORM{PRIORITY},
            RESPOSIBLE => $FORM{RESPOSIBLE},
            MESSAGE    => $message,
            STATE      => ((!$FORM{STATE} || $FORM{STATE} == 0) && !$FORM{INNER_MSG}) ? 6 : $FORM{STATE},
            USER_READ  => '0000-00-00 00:00:00',
            IP         => $admin->{SESSION_IP}
          };

          my %action_hash = (
            module   => 'Msgs',
            function => 'message_add',
            args     => $args,
          );

          my $json_action = JSON::to_json(\%action_hash);
          my $Shedule = Shedule->new($db, $admin, \%conf);

          $FORM{DAY} = sprintf("%02d", $FORM{DAY}) unless($FORM{DAY} eq '*');
          $FORM{MONTH} = sprintf("%02d", $FORM{MONTH}) unless($FORM{MONTH} eq '*');;

          $Shedule->add({
            DESCRIBE => 'Admin message shedule',
            D        => $FORM{DAY} || '*',
            M        => $FORM{MONTH} || '*',
            Y        => $FORM{YEAR} || '*',
            TYPE     => 'call_fn',
            ACTION   => $json_action,
            COUNTS   => ($FORM{PERIODIC} ? '999' : '0'),
            UID      => "$user_info->{uid}",
          });

          next;
        }

        $Msgs->message_add(
          {
            %FORM,
            MESSAGE    => $message,
            STATE      => ((!$FORM{STATE} || $FORM{STATE} == 0) && !$FORM{INNER_MSG}) ? 6 : $FORM{STATE},
            ADMIN_READ => (!$FORM{INNER_MSG}) ? "$DATE $TIME" : '0000-00-00 00:00:00',
            USER_READ  => '0000-00-00 00:00:00',
            IP         => $admin->{SESSION_IP}
          }
        );

        if ( _error_show($Msgs) ) {
          return 0;
        }
        elsif ( $attr->{REGISTRATION} ) {
          return 1;
        }

        push @msgs_ids, $Msgs->{MSG_ID};

        $msg_for_uid{$user_info->{uid}} = {
          MSG_ID  => $Msgs->{MSG_ID}
        };

      }

      if ($FORM{DAY}) {
        $html->message('info', $lang{SHEDULE}, "$lang{ADDED} $lang{SHEDULE}");
        return 1;
      }

      if ( $users->{TOTAL} > 1 ) {
        $message = "$lang{TOTAL}: $users->{TOTAL}";
        $LIST_PARAMS{PAGE_ROWS} = 25;
      }

      if ( !$FORM{INNER_MSG} ) {
        #Web redirect
        if ( $FORM{SEND_TYPE} && $FORM{SEND_TYPE} == 3 ) {
          msgs_redirect_filter({ UID => join(',', @uids) });
        }
        #Sms Send
        elsif ( $FORM{SEND_TYPE} && $FORM{SEND_TYPE} == 2 ) {
          load_module('Sms', $html);
          sms_send(
            {
              NUMBERS => \%NUMBERS,
              MESSAGE => $FORM{MESSAGE},
              UID     => $FORM{UID},
            }
          );
        }
        else {
          msgs_notify_user({
            STATE_ID       => $FORM{STATE},
            STATE          => ($FORM{STATE} && $msgs_status->{$FORM{STATE}}) ? $msgs_status->{$FORM{STATE}} : q{},
            REPLY_ID       => 0,
            MSGS           => $Msgs,
            SEND_TYPE      => $FORM{SEND_TYPE},
            MESSAGES_BATCH => \%msg_for_uid,
            ATTACHMENTS    => \@ATTACHMENTS
          });
        }
      }

      if ( !$Msgs->{errno} ) {
        #Add attachment
        for ( my $i = 0; $i <= $#ATTACHMENTS; $i++ ) {
          $Attachments->attachment_add(
            {
              MSG_ID => ($#msgs_ids > - 1) ? \@msgs_ids : $Msgs->{MSG_ID},
              # Do not create subdirectories if have multiple uids
              UID    => ($#uids == 0) ? $uids[0] : '_',
              %{ $ATTACHMENTS[$i] }
            }
          );
        }

        $html->message('info', $lang{MESSAGES}, "$lang{SENDED} $lang{MESSAGE}");

        if ( $FORM{INNER_MSG} ) {
          msgs_notify_admins();
          if ( $FORM{SURVEY_ID} ) {
            $FORM{chg} = $Msgs->{MSG_ID};
            msgs_admin();
            return 0;
          }
        }
      }

      return 0 if ( $attr->{SEND_ONLY} || $attr->{REGISTRATION} );

      if ( $#msgs_ids < 1 ) {
        $FORM{ID} = join(',', @msgs_ids);
        my $header_message = urlencode("$lang{MESSAGE} $lang{SENDED}" . ($FORM{ID} ? " : $FORM{ID}" : ''));
        $html->redirect("?index=$index"
            . "&UID=" . ($FORM{UID} || q{})
            . "&chg=" . ($FORM{ID} || q{})
            . "&MESSAGE=$header_message#last_msg",
          {
            MESSAGE => "$lang{MESSAGE} $Msgs->{MSG_ID}. $lang{SENDED}",
          }
        );
      }
    }
  }

  print msgs_admin_add_form({
    %{ ($attr) ? $attr : {} },
    MSGS_STATUS => $msgs_status
  });

  return ($attr->{PREVIEW_FORM}) ? 2 : 1;
}


#**********************************************************
=head2 msgs_admin_add_form($attr) - Show message

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub msgs_admin_add_form {
  my ($attr) = @_;

  my $msgs_status = $attr->{MSGS_STATUS};
  my %tpl_info = ();

  if ( $attr->{ACTION} ) {
    $tpl_info{ACTION}     = $attr->{ACTION};
    $tpl_info{LNG_ACTION} = $attr->{LNG_ACTION};
  }
  else {
    $tpl_info{ACTION}     = 'send_message';
    $tpl_info{LNG_ACTION} = $lang{SEND};
  }

  my $a_list = $Msgs->admins_list(
    {
      AID       => $admin->{AID},
      DISABLE   => 0,
      COLS_NAME => 1
    }
  );
  my @A_CHAPTER = ();

  if ( $Msgs->{TOTAL} > 0 ) {
    foreach my $line ( @{$a_list} ) {
      if ( $line->{chapter_id} > 0 ) {
        push @A_CHAPTER, $line->{chapter_id} if ( $line->{priority} > 0 );
      }
    }

    if ( $#A_CHAPTER == - 1 ) {
      return 0;
    }
    else {
      $LIST_PARAMS{CHAPTER} = join(',  ', @A_CHAPTER);
    }
    $LIST_PARAMS{UID} = undef if ( !$FORM{UID} );
  }

  $Msgs->{CHAPTER_SEL} = $html->form_select(
    'CHAPTER',
    {
      SELECTED       => $Msgs->{CHAPTER},
      SEL_LIST       => $Msgs->chapters_list({ CHAPTER => $LIST_PARAMS{CHAPTER} || undef, COLS_NAME => 1 }),
      MAIN_MENU      => get_function_index('msgs_chapters'),
      MAIN_MENU_ARGV => ($Msgs->{CHAPTER}) ? "chg=$Msgs->{CHAPTER}" : ''
    }
  );

  $Msgs->{DISPATCH_SEL} = $html->form_select(
    'DISPATCH_ID',
    {
      SELECTED    => $Msgs->{DISPATCH_ID} || '',
      SEL_LIST    => $Msgs->dispatch_list({ STATE => 0, COLS_NAME => 1 }),
      SEL_OPTIONS => { '' => '--' },
      SEL_KEY     => 'id',
      SEL_VALUE   => 'plan_date,comments'
    }
  );

  if ( (!$FORM{UID} || $FORM{UID} =~ /;/) && ! $FORM{TASK}) {
    $tpl_info{GROUP_SEL} = sel_groups();
    $tpl_info{ADDRESS_FORM} = form_address({LOCATION_ID => $FORM{LOCATION_ID} || ''});

    if ( in_array('Tags', \@MODULES) ) {
      load_module('Tags', $html);
      $tpl_info{TAGS_FORM} = $html->tpl_show(
        templates('form_show_hide'),
        {
          CONTENT => tags_search_form(),
          NAME    => 'TAGS',
          ID      => 'TAGS_FORM',
          PARAMS  => 'collapsed-box'
        },
        { OUTPUT2RETURN => 1 }
      );
    }

    $tpl_info{DATE_PIKER}    = $html->form_datepicker('DELIVERY_SEND_DATE');
    $tpl_info{TIME_PIKER}    = $html->form_timepicker('DELIVERY_SEND_TIME');
    $tpl_info{STATUS_SELECT} = msgs_sel_status({ NAME => 'DELIVERY_STATUS' });

    $tpl_info{PRIORITY_SELECT} = $html->form_select(
      'DELIVERY_PRIORITY',
      {
        SELECTED     => 2,
        SEL_ARRAY    => \@priority,
        STYLE        => \@priority_colors,
        ARRAY_NUM_ID => 1
      }
    );

    $tpl_info{SEND_METHOD_SELECT} = $html->form_select(
      'DELIVERY_SEND_METHOD',
      {
        SELECTED     => 2,
        SEL_ARRAY    => \@send_methods,
        ARRAY_NUM_ID => 1
      }
    );

    $tpl_info{DELIVERY_SELECT_FORM} = sel_deliverys({ SKIP_MULTISELECT => 1, SELECTED => $FORM{DELIVERY} || '' });
    $tpl_info{SEND_DELIVERY_FORM}   = $html->tpl_show(
      _include('msgs_delivery_form', 'Msgs'),
      { %{$attr}, %FORM, %{$Msgs} },
      { OUTPUT2RETURN => 1 },
    );

    $tpl_info{BACK_BUTTON}     = $html->form_input('PREVIEW', $lang{PRE}, { TYPE => 'submit' });
    $tpl_info{SEND_EXTRA_FORM} = $html->tpl_show(_include('msgs_send_extra', 'Msgs'),
      \%tpl_info,
      { OUTPUT2RETURN => 1, ID => 'msgs_send_extra' });
  }

  #Message send  type
  my %send_types = (
    0 => "$lang{MESSAGE}",
  );

  my $sender_send_types = $Sender->available_types({ HASH_RETURN => 1, CLIENT => 1 });

  %send_types = (
    %send_types,
    %$sender_send_types
  );

  if ( in_array('Sms', \@MODULES) ) {
    $send_types{2} = "$lang{SEND} SMS";
  }

  if ( $conf{MSGS_REDIRECT_FILTER_ADD} ) {
    $send_types{3} = 'Msgs redirect';
  }

  my $send_types = $html->form_select(
    'SEND_TYPE',
    {
      SELECTED => $Msgs->{SEND_TYPE} || $FORM{SEND_TYPE} || 0,
      SEL_HASH => \%send_types,
      NO_ID    => 1
    }
  );

  $tpl_info{SEND_TYPES_FORM} = $html->tpl_show(
    templates('form_row'),
    {
      ID    => 'SEND_TYPE',
      NAME  => $lang{SEND},
      VALUE => $send_types
    },
    { OUTPUT2RETURN => 1 }
  );

  $tpl_info{STATE_SEL} = $html->form_select(
    'STATE',
    {
      SELECTED   => $Msgs->{STATE} || 0,
      #SEL_HASH => { %{$msgs_status}{(0,1,2,9)} },
      SEL_HASH   => {
        0 => $msgs_status->{0},
        1 => $msgs_status->{1},
        2 => $msgs_status->{2},
        9 => $msgs_status->{9},
      },
      USE_COLORS => 1,
      NO_ID      => 1
    }
  );

  $tpl_info{PRIORITY_SEL} = $html->form_select(
    'PRIORITY',
    {
      SELECTED     => 2,
      SEL_ARRAY    => \@priority,
      STYLE        => \@priority_colors,
      ARRAY_NUM_ID => 1
    }
  );

  $tpl_info{RESPOSIBLE} = sel_admins({ NAME => 'RESPOSIBLE', SELECTED => $admin->{AID} });
  $tpl_info{INNER_MSG}  = 'checked' if ( $conf{MSGS_INNER_DEFAULT} );
  $tpl_info{SURVEY_SEL} = msgs_survey_sel();
  $tpl_info{PERIODIC}   = 'checked' if ($FORM{PERIODIC});
  $tpl_info{PAR}        = $attr->{PAR} if ($attr->{PAR});

  my $add_tpl_form = ($attr->{TASK_ADD}) ? 'msgs_task' : 'msgs_send_form';

  if ($FORM{MESSAGE}) {
    $Msgs->{TPL_MESSAGE} = $FORM{MESSAGE} || '';
    $Msgs->{TPL_MESSAGE} =~ s/\%/&#37/g;
  }
  my $message_form = $html->tpl_show(_include($add_tpl_form, 'Msgs'),
    { %{$attr}, %FORM, %{$Msgs}, %tpl_info },
    { OUTPUT2RETURN => 1,
      ID            => 'MSGS_SEND_FORM'
    });

  #if ( $attr->{OUTPUT2RETURN} ) {
  return $message_form;
  #}
}


#**********************************************************
=head2 msgs_ticket_show($attr) - Show message

  Arguments:
    $attr
      ID
      A_PRIVILEGES
      CHAPTERS_DELIGATION

  Returns:

=cut
#**********************************************************
sub msgs_ticket_show {
  my ($attr) = @_;

  my $A_PRIVILEGES        = $attr->{A_PRIVILEGES};
  my $CHAPTERS_DELIGATION = $attr->{CHAPTERS_DELIGATION};
  my $message_id          = $attr->{ID} || $FORM{chg} || 0;
  my $msgs_managment_tpl  = ($conf{MSGS_SIMPLIFIED_MODE}) ? 'msgs_managment_simplified_mode'  : 'msgs_managment';
  my $msgs_show_tpl       = ($conf{MSGS_SIMPLIFIED_MODE}) ? 'msgs_show_simplified_mode'       : 'msgs_show';

  if ( $FORM{MESSAGE} ) {
    $html->message('info', '', $FORM{MESSAGE});
  }

  # Fix missing $FORM{UID}. TODO: remove when result folmer list will be fixed (#899)
  if ( $message_id && !$FORM{UID} ) {
    my $message_info_list = $Msgs->messages_list({
      MSG_ID    => $message_id,
      COLS_NAME => 1,
      UID       => '_SHOW'
    });

    _error_show($Msgs);

    if (
      # Check we have correct arrayref
      !$message_info_list || ref $message_info_list ne 'ARRAY' || !scalar @{$message_info_list}
          # Check we have correct hashref
          || !$message_info_list->[0] || ref $message_info_list->[0] ne 'HASH' || !$message_info_list->[0]->{uid}
    ) {
      $html->message('warn', $lang{WARNING}, 'No $FORM{UID} defined');
    }
    else {
      $FORM{UID} = $message_info_list->[0]->{uid};
      my $ui = user_info( $FORM{UID} );
      print $ui->{TABLE_SHOW};
    }
  }

  if ( $FORM{make_new} ) {
    my $old_reply = $Msgs->messages_reply_list({ ID => $FORM{make_new}, COLS_NAME => 1, COLS_UPPER => 1 });
    my $reply_text = $old_reply->[0]->{TEXT};
    $old_reply->[0]->{TEXT} =~ s/^/>  /g;
    $old_reply->[0]->{TEXT} =~ s/\n/\n> /g;
    $old_reply->[0]->{TEXT} .= "\n $lang{CREATE_TOPIC_MESSAGE}";

    $Msgs->message_add({
      USER_SEND => 1,
      UID       => $FORM{UID},
      MESSAGE   => "$lang{AUTO_CREATE_TEXT}: [[$FORM{chg}]]\n$reply_text",
      SUBJECT   => $FORM{COMMENTS},
      CHAPTER   => $FORM{chapter},
      PRIORITY  => 2,
      #TODO More fields maybe
    });

    $Attachments->attachment_copy($FORM{make_new}, $Msgs->{MSG_ID}, $FORM{UID});

    $old_reply->[0]->{TEXT} .= "\n$lang{NEW_TOPIC}: [[$Msgs->{MSG_ID}]]";
    $Msgs->message_reply_change($old_reply->[0]);
  }

  if ( $FORM{reply_del} && $FORM{COMMENTS} ) {
    if ( $FORM{SURVEY_ID} && $FORM{CLEAN} ) {
      $Msgs->survey_answer_del({ SURVEY_ID => $FORM{SURVEY_ID}, UID => $FORM{UID}, %FORM });
    }
    else {
      $Msgs->message_reply_del({ ID => $FORM{reply_del} });
    }
    $html->message('info', $lang{INFO}, "$lang{DELETED}  [$FORM{reply_del}] ") if ( !$Msgs->{errno} );
  }

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });

  print msgs_status_bar({
    NO_UID      => ($FORM{UID}) ? undef : 1,
    TABS        => 1,
    NEXT        => 1,
    MSGS_STATUS => $msgs_status
  });

  $Msgs->message_info($message_id);
  if(_error_show($Msgs)) {
    return 1;
  }
  elsif( $FORM{chg} && !($Msgs->{ID}) ) {
    $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA}");
    return 1;
  }

  $Msgs->{MAIN_ID} = $Msgs->{ID};
  $Msgs->{ACTION} = 'reply';
  $Msgs->{LNG_ACTION} = $lang{REPLY};
  $Msgs->{STATE} //= 0;
  $Msgs->{PRIORITY} //= 0;
  $Msgs->{CHAPTER} //= 0;
  $Msgs->{STATE_NAME} = $html->color_mark($msgs_status->{ $Msgs->{STATE} });

  $Msgs->{STATE_SEL} = $html->form_select('STATE', {
    SELECTED     => $Msgs->{STATE} || 0,
    SEL_HASH     => $msgs_status,
    SORT_KEY_NUM => 1,
    USE_COLORS   => 1,
    NO_ID        => 1
  });

  $Msgs->{PRIORITY_TEXT} = $html->color_mark($priority[ $Msgs->{PRIORITY} ], $priority_colors[ $Msgs->{PRIORITY} ]);
  $Msgs->{PRIORITY_SEL} = $html->form_select('PRIORITY', {
    SELECTED     => $Msgs->{PRIORITY} || 2,
    SEL_ARRAY    => \@priority,
    STYLE        => \@priority_colors,
    ARRAY_NUM_ID => 1
  });

  $Msgs->{DELIGATED} = '-';
  $Msgs->{DELIGATED} = $CHAPTERS_DELIGATION->{ $Msgs->{CHAPTER} } + 1 if ( defined($CHAPTERS_DELIGATION->{ $Msgs->{CHAPTER} }) );
  $Msgs->{DELIGATED_DOWN} = 0;

  $Msgs->{CHAPTERS_SEL} = $html->form_select('CHAPTER_ID', {
    SELECTED       => '',
    SEL_LIST       => $Msgs->chapters_list({ CHAPTER => join(',', keys %{ $A_PRIVILEGES }), COLS_NAME => 1 }),
    MAIN_MENU      => get_function_index('msgs_chapters'),
    MAIN_MENU_ARGV => "chg=$Msgs->{CHAPTER}",
    SEL_OPTIONS    => { '' => '--' },
  });

  $Msgs->{RESPOSIBLE_SEL} = sel_admins({ NAME => 'RESPOSIBLE', RESPOSIBLE => $Msgs->{RESPOSIBLE} });
  $Msgs->{DISPATCH_ID} //= 0;
  $Msgs->{DISPATCH_SEL} = $html->form_select('DISPATCH_ID', {
    SELECTED       => $Msgs->{DISPATCH_ID} || 0,
    SEL_LIST       => $Msgs->dispatch_list({ STATE => 0, COLS_NAME => 1 }),
    SEL_KEY        => 'id',
    SEL_VALUE      => 'comments',
    MAIN_MENU      => get_function_index('msgs_dispatch'),
    MAIN_MENU_ARGV => "chg=$Msgs->{DISPATCH_ID} ",
    SEL_OPTIONS    => { 0 => '--' },
  });

  $users->pi({ UID => $FORM{UID} });

  $Msgs->{MSG_CLOSED_DATE} = $html->form_input('MSG_CLOSED_DATE', "");
  $Msgs->{INNER_MSG_TEXT} = ($Msgs->{INNER_MSG})
    ? $html->element(
        'span', '',
        { class => 'btn btn-warning', ICON => 'glyphicon glyphicon-sunglasses', title => $lang{INNER} }
      )
    : '';
  $Msgs->{MAP} = msgs_maps({ %{$Msgs}, %{$users} });

  $Msgs->msg_watch_list({ MAIN_MSG => $Msgs->{ID}, AID => $admin->{AID} });
  my $uid = $Msgs->{UID} || 0;
  if ( $Msgs->{TOTAL} > 0 ) {
    $Msgs->{WATCH_BTN} = $html->button('',
      "index=$index&UID=$uid&WATCH=1&ID=$message_id&change=1&del=1",
      { class   => 'btn btn-info',
        ICON    => 'glyphicon glyphicon-eye-close',
        CONFIRM => "$lang{UNDO} $lang{WATCH}" });
  }
  else {
    $Msgs->{WATCH_BTN} = $html->button('', "index=$index&UID=$uid&WATCH=1&ID=$message_id&change=1",
      { class => 'btn btn-default', ICON => 'glyphicon glyphicon-eye-open', TITLE => $lang{WATCH} });
  }

  $Msgs->{EXPORT_BTN} = $html->button('', "index=$index&UID=$uid&export=1&ID=$message_id&change=1"
    , { class => 'btn btn-default', ICON => 'glyphicon glyphicon-export', TITLE => $lang{EXPORT} });
  $Msgs->{ID} //= 0;
  $Msgs->{SHEDULE_TABLE_OPEN} = "?index=" . get_function_index('msgs_shedule2') . "&ID=$Msgs->{ID}&DATE=";
  $Msgs->{WORK_BTN} = msgs_work({ MESSAGE_ID => $message_id });
  $Msgs->{HISTORY_BTN} = $html->button('', "index=$index" . "&MSG_HISTORY=$message_id"
    , { class => 'btn btn-default ', ICON => 'glyphicon glyphicon-time', TITLE => $lang{LOG} });

  if (in_array('Workplanning', \@MODULES)) {
    $Msgs->{WORKPLANNING_BTN} = $html->button('',
      "index=" . get_function_index('work_planning_add') . "&MSG_WORKPLANNING=$message_id"
      , { class => 'btn btn-default ', ICON => 'glyphicon glyphicon-plus', TITLE => $lang{ADD_WORKPLANNING} });
  }

  $Msgs->{MSG_PRINT_BTN} = $html->button(
    '',
    "qindex=$index&UID=$uid&MSG_PRINT_ID=$message_id&header=2" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''),
    { class => 'btn btn-default',
      ICON  => 'glyphicon glyphicon-print print',
      TITLE => $lang{PRINT}, ex_params => 'target=new'
    }
  );

  if ($permissions{4} || $conf{MSGS_TAGS_NON_PRIVILEGED}) {
    $Msgs->{ADD_TAGS_BTN} = $html->button('',
      'qindex=' . get_function_index('msgs_quick_replys_tags') . "&header=2&MSGS_ID=$message_id&UID=$uid",
      {
        LOAD_TO_MODAL => 1,
        class         => 'btn btn-default',
        ICON          => 'glyphicon glyphicon-tags',
        TITLE         => $lang{MSGS_TAGS},
      }
    );
  }

  if($conf{MSGS_TASKS}) {
    require Msgs::Tasks;
    $Msgs->{MSGS_TASK_BTN} = $html->button('',
      'index=' . $index . "&header=2&MSGS_ID=$message_id&UID=$uid&TASK=$message_id",
      {
        class         => 'btn btn-default btn-info',
        ICON          => 'glyphicon glyphicon-briefcase',
      }
    );
  }

  my $execution_time_input = $html->form_datetimepicker(
    'PLAN_DATETIME',
    (
      ($Msgs->{PLAN_DATE} && $Msgs->{PLAN_DATE} ne '0000-00-00' ? $Msgs->{PLAN_DATE} : '')
      . ' '
      . ( $Msgs->{PLAN_TIME} && $Msgs->{PLAN_TIME} ne '00:00:00' ? $Msgs->{PLAN_TIME} : '')
    ),
    {
      ICON           => 1,
      TIME_HIDDEN_ID => 'PLAN_TIME',
      DATE_HIDDEN_ID => 'PLAN_DATE'
    }
  );

  if($conf{MSGS_TASKS}) {
    $Msgs->{TASKS_LIST} = msgs_tasks_list($message_id);
  }

  $Msgs->{EXT_INFO} = $html->tpl_show(_include($msgs_managment_tpl, 'Msgs'), {
      %{$users},
      %{$Msgs},
      PHONE               => $users->{PHONE} || $users->{CELL_PHONE} || '--',
      PLAN_DATETIME_INPUT => $execution_time_input
    },
    { OUTPUT2RETURN => 1 });

  #$Msgs->{THREADS}  =  $html->button($Msgs->{SUBJECT}.  "  ($lang{DATE}: $Msgs->{DATE})  ", "");
  #if  ($Msgs->{REPLIES_COUNT}  >  0) {
  #   foreach my  $line  (@{  $Msgs->{REPLIES_COUNT} })  {
  #      my ($id, $caption, $date,  $person)=split(/|/,  $line);
  #    }
  #  }

  my $REPLIES = msgs_ticket_reply($message_id);

  $Msgs->{MESSAGE} = convert($Msgs->{MESSAGE}, { text2html => 1, json => $FORM{json}, SHOW_URL => 1 });
  $Msgs->{SUBJECT} = convert($Msgs->{SUBJECT}, { text2html => 1, json => $FORM{json} });

  my $msgs_rating_message = '';
  my $rating_icons = '';
  if ( $Msgs->{RATING} && $Msgs->{RATING} > 0 ) {
    for ( my $i = 0; $i < $Msgs->{RATING}; $i++ ) {
      $rating_icons .= "\n" . $html->element('i', '', { class => 'fa fa-star' });
    };
    for ( my $i = 0; $i < 5 - $Msgs->{RATING}; $i++ ) {
      $rating_icons .= "\n" . $html->element('i', '', { class => 'fa fa-star-o' });
    };

    my $sig_image = '';
    if ($conf{TPL_DIR} && $Msgs->{UID} && $message_id) {
      my $sig_path = "$conf{TPL_DIR}/attach/msgs/$Msgs->{UID}/$message_id" . "_sig.png";
      if ( -f $sig_path ) {
        $sig_image = $html->img("/images/attach/msgs/$Msgs->{UID}/$message_id" . "_sig.png", 'signature');
      }
    }

    push @{ $REPLIES }, $msgs_rating_message = $html->tpl_show(_include('msgs_rating_admin_show', 'Msgs'), {
          %{$Msgs},
          RATING_ICONS   => $rating_icons,
          RATING_COMMENT => $Msgs->{RATING_COMMENT},
          SIGNATURE      => $sig_image,
        },
        { OUTPUT2RETURN => 1,
        }
      );
  }

  my %params = ();
  if ( !$Msgs->{ACTIVE_SURWEY} && ($A_PRIVILEGES->{ $Msgs->{CHAPTER} } || scalar keys %{ $A_PRIVILEGES } == 0) ) {
    my $survey_sel = msgs_survey_sel();
    $params{REPLY_FORM} = $html->tpl_show(
      _include('msgs_reply', 'Msgs'),
      {
        %{$Msgs},
        REPLY_TEXT      => "",
        QUOTING         => $Msgs->{REPLY_QUOTE} || '',
        RUN_TIME_FORM   => $html->tpl_show(
          templates('form_row'),
          {
            ID    => "RUN_TIME",
            NAME  => "$lang{RUN_TIME} (mins.)",
            VALUE => $html->form_input('RUN_TIME', '00:00:00',
              { EX_PARAMS => " STYLE='background-color:  $_COLORS[3]' DISABLED  size=9" })
          },
          { OUTPUT2RETURN => 1 }
        ),
        RUN_TIME_STATUS => 'DISABLE',
        MAIN_INNER_MSG  => $Msgs->{INNER_MSG},
        INNER_MSG       => ($FORM{INNER_MSG}) ? ' checked ' : '',
        SURVEY_SEL      => $survey_sel
      },
      { OUTPUT2RETURN => 1, ID => 'MSGS_REPLY' }
    );
  }

  $params{REPLY} = join(($FORM{json}) ? ',' : '', @{ $REPLIES });

  if ( $Msgs->{FILENAME} ) {
    my $attachments_list = $Msgs->attachments_list({
      MESSAGE_ID     => $Msgs->{ID},
      FILENAME     => '_SHOW',
      CONTENT_SIZE => '_SHOW',
      CONTENT_TYPE => '_SHOW',
      COORDX       => '_SHOW',
      COORDY       => '_SHOW',
    });

    $Msgs->{ATTACHMENT} = msgs_get_attachments_view($attachments_list);
  }

  if ( $Msgs->{PRIORITY} == 4 ) {
    $params{MAIN_PANEL_COLOR} = 'box-danger';
  }
  elsif ( $Msgs->{PRIORITY} == 3 ) {
    $params{MAIN_PANEL_COLOR} = 'box-warning';
  }
  elsif ( $Msgs->{PRIORITY} >= 1 ) {
    $params{MAIN_PANEL_COLOR} = 'box-info';
  }
  else {
    $params{MAIN_PANEL_COLOR} = 'box-primary';
  }

  my $msg_tags_list = $Msgs->quick_replys_tags_list({ MSG_ID => $message_id, COLOR => '_SHOW', COLS_NAME => 1 });
  if ( $Msgs->{TOTAL} ) {
    foreach my $msg_tag ( @{$msg_tags_list} ) {
      $params{MSG_TAGS} .= ' ' . $html->element('span', $msg_tag->{reply},{
          'class' => 'label',
          'style' => "background-color:". ($msg_tag->{color} || q{}). ";border-color:white;font-weight: bold"
        });
    }
  }
  else {
    $params{MSG_TAGS_DISPLAY_STATUS} = 1;
    $params{MSG_TAGS} = $html->button('',
      'qindex=' . get_function_index('msgs_quick_replys_tags') . "&header=2&MSGS_ID=$message_id&UID=$uid",
      {
        LOAD_TO_MODAL => 1,
        class         => 'btn btn-xs btn-danger',
        ICON          => 'glyphicon glyphicon-tags',
        TITLE         => "$lang{ADD} $lang{TAGS}"
      }
    );
  }

  $Msgs->{ID} = $Msgs->{MAIN_ID};
  #    $Msgs->{MAP} = msgs_maps({ %$Msgs, %$users });
  $params{PROGRESSBAR} = msgs_progress_bar_show($Msgs);

  while ( $Msgs->{MESSAGE} && $Msgs->{MESSAGE} =~ /\[\[(\d+)\]\]/ ) {
    my $msg_button = $html->button($1, "&index=$index&chg=$1",
      { class => 'badge bg-blue' });
    $Msgs->{MESSAGE} =~ s/\[\[\d+\]\]/$msg_button/;
  }
# Button for subject chaning
  if ( scalar keys %{ $A_PRIVILEGES } == 0 || $A_PRIVILEGES->{$Msgs->{CHAPTER}} == 3 ) {
    $params{CHANGE_SUBJECT_BUTTON} = $html->button("$lang{CHANGE} $lang{SUBJECT}",
      "qindex=" . get_function_index('_msgs_show_change_subject_template') . "&header=2&subject=". ($Msgs->{SUBJECT} || q{}). "&msg_id=$Msgs->{ID}",
      {
        LOAD_TO_MODAL  => 1,
        NO_LINK_FORMER => 1,
        class          => 'change',
        TITLE          => $lang{SUBJECT}
      }
    );
  }

  if ( in_array('Workplanning', \@MODULES) ) {
    $params{WORKPLANNING} = work_planning_table_show($message_id);
  }

  #Parent
  if($Msgs->{PAR}) {
    $params{PARENT_MSG} = $html->button('PARENT: ' . $Msgs->{PAR}, 'index=' . $index . "&chg=$Msgs->{PAR}",
      { class => 'btn btn-xs btn-default text-right' });
  }
  $params{RATING_ICONS} = $rating_icons;
  $params{LOGIN}        = ($Msgs->{AID}) ? $html->b($Msgs->{A_NAME}) . " ($lang{ADMIN})" : $html->button($Msgs->{LOGIN},
      "index=15&UID=$uid");
  $params{ADMIN_LOGIN} = $admin->{A_LOGIN};

  $html->tpl_show(_include($msgs_show_tpl, 'Msgs'), { %{$Msgs}, %params });

  if ( !$FORM{quick}
    && (!$Msgs->{RESPOSIBLE} || ($Msgs->{RESPOSIBLE} =~ /^\d+$/ && $Msgs->{RESPOSIBLE} == $admin->{AID}))
  ) {
    $Msgs->message_change({
      UID        => $uid,
      ID         => $message_id,
      #USER_READ  => "0000-00-00  00:00:00",
      ADMIN_READ => "$DATE $TIME",
      SKIP_LOG   => 1
    });
  }
  show_admin_chat();

  return 1;
}
#**********************************************************
=head2 header_online_chat() Shows chats at the header main page

  Arguments:

  Returns:
    true
=cut
#**********************************************************
sub header_online_chat {
  my ($attr) = @_;
  my $list = '';
  if ($FORM{AID}) {
    my $count_messages = $Msgs->chat_count({ AID => $FORM{AID} });
    print $count_messages;
  }
  if ($attr->{UID}) {
    my $count_user_messages = $Msgs->chat_count({ UID => $attr->{UID} || '' });
    print $count_user_messages;
  }
  if ($attr->{US_MS_LIST}) {
    my $messages = $Msgs->chat_message_info({ UID => $attr->{US_MS_LIST} });
    foreach my $item (@$messages) {
      $list .= $html->tpl_show(_include('msgs_chat_header', 'Msgs'), {
        SUBJECT => $item->{subject},
        LINK    => 'index.cgi?get_index=msgs_user&ID=' . $item->{id} . '&sid=' . $user->{SID}
      }, { OUTPUT2RETURN => 1 });
    }
    print $list;
  }
  if ($FORM{SH_MS_LIST}) {
    my $messages = $Msgs->chat_message_info({ AID => $FORM{SH_MS_LIST} });
    foreach my $item (@$messages) {
      $list .= $html->tpl_show(_include('msgs_chat_header', 'Msgs'), {
        SUBJECT => $item->{subject},
        LINK    => 'index.cgi?get_index=msgs_admin&full=1&UID=' . $item->{uid} . '&chg=' . $item->{num_ticket}
      }, { OUTPUT2RETURN => 1 });
    }
    print $list;
  }
  return 1;
}
#**********************************************************
=head2 show_admin_chat() Shows chat at the admin side

  Arguments:

  Returns:
    ''
=cut
#**********************************************************
sub show_admin_chat {
  if ($FORM{ADD}) {
    msgs_chat_add();
    return 1;
  }
  if ($FORM{SHOW}) {
    msgs_chat_show();
    return 1;
  }
  if ($FORM{COUNT}) {
    my $count = $Msgs->chat_count({ Msg_ID => $FORM{MSG_ID}, SENDER => 'aid' });
    print $count;
    return 1;
  }
  if ($FORM{CHANGE}) {
    $Msgs->chat_change({ Msg_ID => $FORM{MSG_ID}, SENDER => 'aid'});
    return 1;
  }
  if ($conf{MSGS_CHAT}) {
    my $fn_index = get_function_index('show_admin_chat');
    $html->tpl_show(_include('msgs_admin_chat', 'Msgs'), {
      F_INDEX    => $fn_index,
      AID        => $admin->{AID},
      NUM_TICKET => $Msgs->{ID}
    });
  }
  return '';
}
#**********************************************************
=head2 msgs_chat_add() Add chat message to db

  Arguments:

  Returns:
    true
=cut
#**********************************************************
sub msgs_chat_add {
  if ($FORM{MESSAGE}) {
    $Msgs->chat_add({
      MESSAGE     => $FORM{MESSAGE},
      UID         => $FORM{UID} || '0',
      AID         => $FORM{AID} || '0',
      NUM_TICKET  => $FORM{MSG_ID} || '0',
      MSGS_UNREAD => '0',
    });
    if (!$Msgs->{errno}) {
      $html->message('info', $lang{INFO}, $lang{ADDED});
    }
  }
  return '';
}
#**********************************************************
=head2 msgs_chat_show() - Shows chat messages

  Arguments:

  Returns:
    true
=cut
#**********************************************************
sub msgs_chat_show {
  my $list = $Msgs->chat_list({Msg_ID => $FORM{MSG_ID}});
  foreach my $line (@$list) {
    if ($FORM{ADMIN} && $line->{uid} eq '0') {
      $html->tpl_show(_include('msgs_chat_to', 'Msgs'), {
        MESSAGE => $line->{message},
        DATE    => $line->{date},
        SENDER  => 'You',
      });
    }
    elsif ($FORM{ADMIN} && $line->{aid} eq '0') {
      $html->tpl_show(_include('msgs_chat_from', 'Msgs'), {
        MESSAGE => $line->{message},
        DATE    => $line->{date},
        SENDER  => 'User',
      });
    }
    if ($FORM{USER} && $line->{uid}eq'0') {
      print $html->tpl_show(_include('msgs_chat_from', 'Msgs'), {
        MESSAGE => $line->{message},
        DATE    => $line->{date},
        SENDER  => 'Admin',
      }, {OUTPUT2RETURN => 1});
    }
    elsif ($FORM{USER} && $line->{aid}eq'0') {
      print $html->tpl_show(_include('msgs_chat_to', 'Msgs'), {
        MESSAGE => $line->{message},
        DATE    => $line->{date},
        SENDER  => 'You',
      }, {OUTPUT2RETURN => 1});
    }
  }
  return '';
}

#**********************************************************
=head2 msgs_ticket_reply

=cut
#**********************************************************
sub msgs_ticket_reply {
  my ($message_id) = @_;

  my $uid = $Msgs->{UID} || 0;
  my @REPLIES = ();
  my $msgs_reply_show_tpl = ($conf{MSGS_SIMPLIFIED_MODE}) ? 'msgs_reply_show_simplified_mode' : 'msgs_reply_show';

  if ( $Msgs->{SURVEY_ID} ) {
    my $main_message_survey = msgs_survey_show({
      SURVEY_ID => $Msgs->{SURVEY_ID},
      MSG_ID    => $Msgs->{ID},
      MAIN_MSG  => 1,
    });

    if($main_message_survey){
      push @REPLIES, $main_message_survey;
    }

  }

  my $list = $Msgs->messages_reply_list({
    MSG_ID        => $Msgs->{ID},
    COLS_NAME     => 1
  });

  my $total_reply = $Msgs->{TOTAL};

  if ( ! $Msgs->{TOTAL} || $Msgs->{TOTAL} < 1 ) {
    $Msgs->{REPLY_QUOTE} = '> '. ($Msgs->{MESSAGE} || q{});
  }

  foreach my $line ( @{$list} ) {
    if ( $line->{survey_id} ) {
      $FORM{REPLY_ID} = $line->{id};
      push @REPLIES, msgs_survey_show({
          SURVEY_ID => $line->{survey_id},
          REPLY_ID  => $line->{id},
          MSG_ID    => $Msgs->{ID},
          TEXT      => $line->{text},
        });

      delete($Msgs->{SURVEY_ID});
      next;
    }

    if ( $FORM{QUOTING} && $FORM{QUOTING} == $line->{id} ) {
      $Msgs->{REPLY_QUOTE} = '>' . $line->{text};
    }

    my $reply_color = 'box-theme';
    if ($conf{MSGS_SIMPLIFIED_MODE}){
      if ($line->{inner_msg}){
        $reply_color = 'bg-yellow';
      }
      elsif ($line->{aid} > 0){
        $reply_color = 'bg-green';
      }
      else {
        $reply_color = 'bg-aqua';
      }
    }
    else {
      if ($line->{inner_msg}){
        $reply_color = 'box-warning';
      }
      elsif ($line->{aid} > 0){
        $reply_color = 'box-success';
      }
      #      else {
      #        $msg_color = 'box-theme';
      #      }
    }

    my $new_topic_button = '';
    my $edit_reply_button = '';
    if ( $permissions{7} && $permissions{7}->{1} && $uid ) {
      $new_topic_button = $html->button($lang{CREATE_NEW_TOPIC},
        "&index=$index&chg=$message_id&UID=$uid&make_new=$line->{id}&chapter=$Msgs->{CHAPTER}",
        { MESSAGE => "$lang{NEW_TOPIC}?", BUTTON => 1 }
      );
      $edit_reply_button = $html->button(
        "$lang{EDIT}", "",
        { class => 'btn btn-default btn-xs reply-edit-btn', ex_params => "reply_id='$line->{id}'"}
      );
    }

    my $del_reply_button = $html->button(
      $lang{DEL},
      "&index=$index&chg=$message_id&reply_del=$line->{id}&UID=$uid",
      { MESSAGE => "$lang{DEL}  $line->{id}?", BUTTON => 1 }
    );

    my $quote_button = $html->button(
      $lang{QUOTING},
      "&index=$index&chg=$message_id&UID=$uid&QUOTING=$line->{id}#reply"
        . (($line->{inner_msg}) ? "&INNER_MSG=1" : '')
      , { BUTTON => 1 }
    );

    my $run_time = ($line->{run_time} && $line->{run_time} ne '00:00:00') ? "$lang{RUN_TIME}: $line->{run_time}" : '';

    my $attachment_html = '';
    if ($line->{attachment_id}){
      my $attachments_list = $Msgs->attachments_list({
        REPLY_ID     => $line->{id},
        FILENAME     => '_SHOW',
        CONTENT_SIZE => '_SHOW',
        CONTENT_TYPE => '_SHOW',
        COORDX       => '_SHOW',
        COORDY       => '_SHOW',
      });

      $attachment_html = msgs_get_attachments_view($attachments_list);
    }

    push @REPLIES, $html->tpl_show(
        _include($msgs_reply_show_tpl, 'Msgs'),
        {
          ADMIN_MSG  => $line->{aid},
          LAST_MSG   => ($total_reply == $#REPLIES + 2) ? 'last_msg' : '',
          REPLY_ID   => $line->{id},
          DATE       => $line->{datetime},
          #        CAPTION    =>  convert($line->{caption}, {
          #            text2html => 1,
          #            json => $FORM{json}
          #          })
          #          . "  #  $Msgs->{ID}  $line->{id}",
          PERSON     =>   ($line->{creator_id} || q{}) . ' ' .
            (($line->{aid})
              ? " ($lang{ADMIN})"
                . (($line->{inner_msg})
                ? "  $lang{PRIVATE}"
                : '')
              : ""),
          MESSAGE       => msgs_text_quoting($line->{text}, 1),
          QUOTING       => $quote_button,
          NEW_TOPIC     => $new_topic_button,
          EDIT          => $edit_reply_button,
          DELETE        => $del_reply_button,
          ATTACHMENT    => $attachment_html,
          COLOR         => $reply_color,
          RUN_TIME      => $run_time,
        },
        { OUTPUT2RETURN => 1, ID => $line->{id} },
      );
  }

  if ( $Msgs->{REPLY_QUOTE} ) {
    if ( $FORM{json} ) {
      $Msgs->{REPLY_QUOTE} = ''; #convert($reply, { text2html => 1, json => $FORM{json} })
    }
    else {
      #      $reply =~ s/^/>  /g;
      $Msgs->{REPLY_QUOTE} =~ s/\n/> /g;
    }
  }

  return \@REPLIES;
}


#**********************************************************
=head2 _msgs_change_responsible($message_id, $new_responsible_aid, $attr)

  Arguments:
    $message_id
    $new_responsible_aid
    $attr

=cut
#**********************************************************
sub _msgs_change_responsible {
  my ($message_id, $new_responsible_aid, $attr) = @_;

  # Check for test
  return 0 unless ( $message_id );

  my $message_info = $attr->{MESSAGE_INFO};

  # Check we have all information we need
  my $given_message_has_all_required_info = (
    ($message_info && ref $message_info eq 'HASH')
      && (defined $message_info->{subject})
      && (defined $message_info->{resposible})
      && (defined $message_info->{message})
  );

  # If there is not enough, get it ourselves
  if ( !$given_message_has_all_required_info ) {
    my $message_info_list = $Msgs->messages_list({
      MSG_ID     => $message_id,
      RESPOSIBLE => '_SHOW',
      MESSAGE    => '_SHOW',
      SUBJECT    => '_SHOW',
      UID        => '_SHOW',
      COLS_NAME  => 1
    });
    return 0 if ( $Msgs->{errno} || !$Msgs->{TOTAL} );
    $message_info = $message_info_list->[0];
  }

  my $previous_responsible_aid = $message_info->{resposible} || 0;

  # Check if it's really changed
  if ( $previous_responsible_aid eq $new_responsible_aid ) {
    return 1
  }

  # Change resposible in DB
  if ( !$attr->{SKIP_CHANGE} ) {
    $Msgs->message_change({
      ID         => $message_id,
      RESPOSIBLE => $new_responsible_aid
    });
    return 0 if ( $Msgs->{errno} );
  }

  # Check if now we have resposible and if this is not admin who changes
  return 1 if ( !$new_responsible_aid || ($admin->{AID} eq $new_responsible_aid));

  # Send notification if Telegram available
  if ( $conf{TELEGRAM_TOKEN} ) {
    # Safe section
    eval {
      require Msgs::Messaging;
      my $subject = $message_info->{subject} || '';
      my $first_message_for_mess = $message_info->{message} || '';

      return msgs_send_via_telegram($message_id, {
        AID         => $new_responsible_aid,
        SUBJECT     => $lang{YOU_HAVE_BEEN_SET_AS_RESPONSIBLE_IN} . " <b>'$subject'</b>",
        MESSAGE     => $first_message_for_mess || '',
        SENDER_UID  => $message_info->{uid},
        SENDER_TYPE => $Contacts::TYPES{TELEGRAM},
        PARSE_MODE  => 'HTML'
      });
    };
    #    if ($@) {
    # Do nothing
    # TODO: show webinterface independent message or write to log
    #    }
  }
  else {
    msgs_notify_admins({
      MSGS_ID       => $message_id,
      SKIP_TELEGRAM => 1,
      AID           => $new_responsible_aid
    });
  }

  return 1;
}

#**********************************************************
=head2 msgs_work($attr)

  Arguments:
     $attr
       WORK_LIST
       MESSAGE_ID

  Returns:

=cut
#**********************************************************
sub msgs_work {
  my ($attr) = @_;

  if ( !in_array('Crm', \@MODULES) ) {
    return q{};
  }

  if ( $attr->{WORK_LIST} ) {
    load_module('Crm', $html);
    if ( $attr->{MNG} ) {
      return crm_works({ EXT_ID => $attr->{MESSAGE_ID}, UID => $attr->{UID} });
    }
    else {
      return crm_works_list({ EXT_ID => $attr->{MESSAGE_ID}, UID => $attr->{UID} });
    }
  }

  return $html->button('', "index=$index&UID=$Msgs->{UID}&WORK=$attr->{MESSAGE_ID}",
    { class => 'btn btn-default', ICON => 'glyphicon glyphicon-wrench', TITLE => $lang{WORK} });
}

#**********************************************************
=head2 msgs_export($attr); - Export to other systems


=cut
#**********************************************************
sub msgs_export {
  #my ($attr) = @_;

  if ( $FORM{_export} ) {
    require Msgs::Export_redmine;
    Export_redmine->import();

    my $Export_redmine = Export_redmine->new($db, $admin, \%conf);

    $Export_redmine->export_task(\%FORM);
    _error_show($Export_redmine);

    if ( $Export_redmine->{RESULT}->{"issue"}->{"id"} ) {
      $html->message('info', $lang{ADDED}, "$lang{ADDED}: $Export_redmine->{RESULT}->{issue}->{id} ");
    }

    my $list = $Export_redmine->task_list();
    my $table;

    ($table, $list) = result_former(
      {
        #FUNCTION_FIELDS => "iptv_olltv:DEL:mac;serial_number:&list=$FORM{list}&del=1&COMMENTS=1",
        TABLE         => {
          width            => '100%',
          caption          => 'Redmine tasks',
          #qs               => "&list=$FORM{list}",
          #SHOW_COLS        => \%info_oids,
          SHOW_COLS_HIDDEN => {
          },
          ID               => 'MSGS_REDMINE_LIST',
        },
        DATAHASH      => $Export_redmine->{RESULT}->{issues},
        SKIPP_UTF_OFF => 1,
        # MAKE_ROWS    => 1,
        TOTAL         => 1
      }
    );
  }

  $Msgs->message_info($FORM{ID});
  $Msgs->{ACTION} = '_export';
  $Msgs->{LNG_ACTION} = $lang{EXPORT};

  $Msgs->{PRIORITY_SEL} = $html->form_select(
    'PRIORITY',
    {
      SELECTED     => 2,
      SEL_ARRAY    => \@priority,
      STYLE        => \@priority_colors,
      ARRAY_NUM_ID => 1
    }
  );

  $Msgs->{EXPORT_SYSTEM_SEL} = $html->form_select(
    'EXPORT',
    {
      SELECTED  => 'redmine',
      SEL_ARRAY => [ 'redmine' ],
      #STYLE        => \@priority_colors,
      #ARRAY_NUM_ID => 1
    }
  );

  $html->tpl_show(_include('msgs_export', 'Msgs'), $Msgs);

  return 1;
}



#**********************************************************
=head2 msgs_employee_tasks_map() - show tasks for employee on map

=cut
#**********************************************************
sub msgs_employee_tasks_map {
  my $aid = $FORM{AID} || $admin->{AID};
  my $date = $FORM{DATE} || $DATE;
  my $date_type = $FORM{DATE_TYPE} // 'PLAN_DATE';
   my @date_types = (
    { name => $lang{ALL}, id => '' },
    { name => $lang{CREATED}, id => 'DATE' },
    { name => $lang{PLANNED}, id => 'PLAN_DATE' },
    { name => $lang{DONE}, id => 'DONE_DATE' },
  );
   my $state_name_list = $Msgs->status_list({ NAME => '_SHOW', COLS_NAME => 1 });
  _error_show($Msgs) and return 0;
   my %state_name = map {$_->{id} => _translate($_->{name} || '')} @{$state_name_list};

  my $admin_select = sel_admins();

  my $date_type_select = $html->form_select('DATE_TYPE', {
      SELECTED => $date_type,
      SEL_LIST => \@date_types,
      NO_ID    => 1
    });

  #show panel for choosing admin and date
  $html->tpl_show(
    _include('msgs_map_employee_tasks', 'Msgs'),
    {
      AID_SELECT       => $admin_select,
      DATE_TYPE_SELECT => $date_type_select
    }
  );

  # if no employee choosed, then
  return 1 unless ( $aid );

  # if employee chosed, find all tasks for given date or today if no date
  my $tasks = $Msgs->messages_list(
    {
      RESPOSIBLE  => $aid,
      LOGIN       => '_SHOW',
      $date_type  => $date,
      LOCATION_ID => '_SHOW',
      STATE       => '_SHOW',
      COLS_NAME   => 1
    });

  _error_show($Msgs);

  #my $msgs_admin_index = get_function_index('msgs_admin');

  my %tasks_by_location = ();
  foreach my $task ( @{$tasks} ) {
#    $task->{subject} = $html->button(
#      $task->{subject},
#      "?index=$msgs_admin_index&chg=$task->{id}"
#    );

    if ( $tasks_by_location{$task->{build_id}} ) {
      push @{ $tasks_by_location{$task->{build_id}} }, $task;
    }
    else {
      $tasks_by_location{$task->{build_id}} = [ $task ];
    }

    $task->{location_id} = $task->{build_id};
    #$task->{login} = $task->{user_name};
    $task->{state} = $state_name{$task->{state}} || '--';

    delete $task->{build_id};
    #delete $task->{user_name};
  }

  load_module("Maps", $html);

  # enable GPS marker for this AID
  $FORM{show_gps} = $aid;
  $FORM{DATE} = $date;

  # Show a map
  maps_show_map({
    QUICK                 => 1,
    DATA                  => \%tasks_by_location,
    HIDE_ALL_LAYERS       => 1,
    LOCATION_TABLE_FIELDS => 'ID,LOGIN,SUBJECT,STATE',
  });

  return 1;
}

#**********************************************************
=head2 msgs_dispatch()

=cut
#**********************************************************
sub msgs_dispatch {

  require Contacts;
  my $Contacts = Contacts->new($db, $admin, \%conf);

  $Msgs->{ACTION} = 'add';
  $Msgs->{LNG_ACTION} = $lang{ADD};

  if ( $FORM{add} ) {
    $Msgs->dispatch_add({ %FORM });
    $html->message('info', $lang{INFO}, "$lang{ADDED}") if ( !$Msgs->{errno} );
  }
  elsif ( $FORM{print} ) {
    print $html->header();
    $Msgs->dispatch_info($FORM{print});

    my $value_list = $Conf->config_list({
      CUSTOM    => 1,
      COLS_NAME => 1
    });

    my $list = $Msgs->messages_list({
      DISPATCH_ID    => $FORM{print},
      LOGIN          => '_SHOW',
      PLAN_DATE      => '_SHOW',
      DESC           => (!$FORM{sort}) ? 'DESC' : $FORM{desc},
      ADDRESS_FULL   => '_SHOW',
      ADDRESS_STREET => '_SHOW',
      SUBJECT        => '_SHOW',
      ADDRESS_BUILD  => '_SHOW',
      CITY           => '_SHOW',
      STATE_ID       => $FORM{NO_CLOSE_MSG} ? '!(1;2)' : '*',
      ADDRESS_FLAT   => '_SHOW',
      MESSAGE        => '_SHOW',
      PASSWORD       => '_SHOW',
      USER_CONTACTS  => 1,
      FIO            => '_SHOW',
      PHONE          => '_SHOW',
      COLS_NAME      => 1
    });

    my %ORDERS = ();
    my $i = 1;

    foreach my $line ( @{$value_list} ) {
      $ORDERS{"$line->{param}"} = $line->{value};
    }

    foreach my $line ( @{$list} ) {
      my $phone_list = $Contacts->contacts_list({
        UID   => $line->{uid},
        TYPE  => '1;2',
        VALUE => '_SHOW',
      });

      foreach my $phone ( @{$phone_list} ) {
        $ORDERS{ 'ORDER_PERSONAL_INFO_PHONE_' . $i } .= $phone->{'value'} . "\n";
      }

      my $address_full = ($line->{city} || q{})
        . ' ' . ($line->{address_street} || q{})
        . ' ' . ($line->{address_build} || q{})
        . ' ' . ($line->{address_flat} || q{});

      $ORDERS{ 'ORDER_NUM_' . $i } = $i;
      $ORDERS{ 'ORDER_PERSONAL_INFO_' . $i } = ($line->{fio} || q{}) . ', ' . $address_full;
      $ORDERS{ 'ORDER_PERSONAL_INFO_LOGIN_' . $i } = $line->{login} || q{-};
      $ORDERS{ 'ORDER_PERSONAL_INFO_PASSWORD_' . $i } = $line->{password};
      $ORDERS{ 'ORDER_PERSONAL_INFO_FIO_' . $i } = $line->{fio};
      $ORDERS{ 'ORDER_PERSONAL_INFO_ADDRESS_' . $i } = $address_full;
      $ORDERS{ 'ORDER_PERSONAL_INFO_PHONE_' . $i } .= $line->{phone} || q{};
      $ORDERS{ 'ORDER_JOB_' . $i } = $line->{message};
      $ORDERS{ 'ORDER_SUBJECT_' . $i } = $line->{subject};
      $ORDERS{ 'ORDER_CHAPTER_' . $i } = $line->{chapter_name};
      $ORDERS{ 'ORDER_DATE_' . $i } = $line->{date};
      $ORDERS{ 'PLAN_DATE_' . $i } = $line->{plan_date};
      $i++;
    }

    $html->tpl_show(_include('msgs_dispatch_blank', 'Msgs'), { %{$Msgs}, %ORDERS });

    return 0;
  }
  elsif ( $FORM{change} ) {
    if ( $FORM{STATE} && $FORM{STATE} > 0 ) {
      $FORM{DONE_DATE} = "$DATE" if ( $FORM{STATE} == 2 );
      $FORM{CLOSED_DATE} = "$DATE" if ( $FORM{STATE} == 1 || $FORM{STATE} == 2 );
    }

    $Msgs->dispatch_change({ %FORM });
    $html->message('info', $lang{INFO}, $lang{CHANGED}) if ( !$Msgs->{errno} );
  }
  elsif ( $FORM{chg} ) {
    $Msgs->dispatch_info($FORM{chg});

    $Msgs->{ACTION} = 'change';
    $Msgs->{LNG_ACTION} = $lang{CHANGE};
    $FORM{add_form} = 1;
    # $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" ) if (!$Msgs->{errno});
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ) {
    $Msgs->dispatch_del({ ID => $FORM{del} });
    $html->message('info', $lang{INFO}, $lang{DELETED}) if ( !$Msgs->{errno} );
  }
  elsif ( $FORM{msg_del} && $FORM{COMMENTS} ) {
    $Msgs->message_change({
      DISPATCH_ID => 0,
      ID          => $FORM{msg_del}
    });

    $html->message('info', $lang{INFO}, "$lang{MESSAGE}  #  $FORM{msg_del} $lang{DELETED}") if ( !$Msgs->{errno} );
  }

  _error_show($Msgs);

  $LIST_PARAMS{STATE} = $FORM{STATE} if ( defined($FORM{STATE}) && $FORM{STATE} ne '' );

  if ( $FORM{add_form} ) {

    $Msgs->{STATE_SEL} = msgs_sel_status({ ALL => 1 });
    $Msgs->{RESPOSIBLE_SEL} = sel_admins({ NAME => 'RESPOSIBLE', RESPOSIBLE => $Msgs->{RESPOSIBLE} });
    $Msgs->{PLAN_DATE} = $Msgs->{PLAN_DATE} || $DATE;

    $Msgs->{CATEGORY_SEL} = $html->form_select(
      'CATEGORY',
      {
        SELECTED    => $Msgs->{CATEGORY} || 0,
        SEL_OPTIONS => { 0 => '--' },
        SEL_LIST    => $Msgs->dispatch_category_list({ COLS_NAME => 1 }),
      }
    );

    $html->tpl_show(_include('msgs_dispatch', 'Msgs'), $Msgs);
  }

  if ( $FORM{chg} ) {
    $LIST_PARAMS{DISPATCH_ID} = $FORM{chg};
    $pages_qs .= '&chg=' . $FORM{chg};
    $index = get_function_index('msgs_admin');
    delete($FORM{chg});

    msgs_list({
      SELECT_ALL_ON           => 1,
      ALLOW_TO_CLEAR_DISPATCH => 1,
      DISPATCH_ID             => $LIST_PARAMS{DISPATCH_ID}
    });

    $index = get_function_index('msgs_dispatch');

    msgs_dispatch_admins({ DISPATCH_ID => $LIST_PARAMS{DISPATCH_ID} });

    return 0;
  }

  if ( !defined($FORM{STATE}) && !$FORM{ALL_MSGS} ) {
    $FORM{STATE} = 0;
    $LIST_PARAMS{STATE} = 0;
  }

  if ( !defined($FORM{sort}) ) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'desc';
  }

  #my $list = $Msgs->dispatch_list({ %LIST_PARAMS, COLS_NAME => 1 });

  $pages_qs = '';

  if ( exists $FORM{RESPOSIBLE} && $FORM{RESPOSIBLE} ) {
    $LIST_PARAMS{RESPOSIBLE} = ($FORM{RESPOSIBLE} eq 'current') ? $admin->{AID} : $FORM{RESPOSIBLE};
  }

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });
  my Abills::HTML $table;
  my $list;
  ($table, $list) = result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'dispatch_list',
    BASE_FIELDS     => 6,
    FUNCTION_FIELDS => 'null',
    DEFAULT_FIELDS  => '',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id            => '#',
      plan_date     => $lang{EXECUTION},
      created       => $lang{CREATED},
      message_count => $lang{MESSAGES},
      comments      => $lang{COMMENTS},
      name          => $lang{CATEGORY}
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{DISPATCH},
      qs      => $pages_qs,
      ID      => 'MSGS_DISPATCH',
      header  => msgs_status_bar({ MSGS_STATUS => $msgs_status }),
      EXPORT  => 1,
      MENU    => "$lang{ADD}:add_form=1&index=$index:add"
    }
  });

  if ( $list && $list == - 1 ) {
    return 0;
  }

  foreach my $line ( @{$list} ) {
    my @fields_array = ();
    for ( my $i = 0; $i < $Msgs->{SEARCH_FIELDS_COUNT} + 6; $i++ ) {
      my $val = '';
      my $field_name = $Msgs->{COL_NAMES_ARR}->[$i] || q{};
      $val = $line->{ $field_name };
      push @fields_array, $val;
    }

    push @fields_array,
      $html->button(
        $lang{PRINT}, "#",
        {
          NEW_WINDOW      => "$SELF_URL?qindex=$index&print=$line->{id}",
          NEW_WINDOW_SIZE => "640:750",
          class           => 'print'
        }
      )
        . ' ' . $html->button($lang{CHANGE}, "index=$index&chg=$line->{id}&ALL_MSGS=1", { class => 'change' })
        . ' ' . $html->button($lang{DEL}, "index=$index&del=$line->{id}",
        { MESSAGE => "$lang{DEL} $line->{id}?", class => 'del' });

    $table->addrow(@fields_array);
  }

  print $table->show();
  $table = $html->table({
    width => '100%',
    rows  => [ [ "  $lang{TOTAL}: ", $html->b($Msgs->{TOTAL}) ] ]
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head1 msgs_survey_sel($attr)

=cut
#**********************************************************
sub msgs_survey_sel {
  my $list = $Msgs->survey_subjects_list({ PAGE_ROWS => 10000, COLS_NAME => 1 });

  if ( $Msgs->{TOTAL} > 0 ) {
    return $html->form_select(
      'SURVEY_ID',
      {
        SELECTED       => '' || $FORM{SURVEY_ID},
        SEL_LIST       => $list,
        SEL_OPTIONS    => { '' => '' },
        MAIN_MENU      => get_function_index('msgs_survey'),
        MAIN_MENU_ARGV => ($FORM{SURVEY_ID}) ? "chg=$FORM{SURVEY_ID}" : ''
      }
    );
  }

  return '';
}

#**********************************************************
=head2 msgs_maps()

=cut
#**********************************************************
sub msgs_maps {
  my ($Msgs_) = @_;

  if ( !$Msgs_->{LOCATION_ID} || !in_array('Maps', \@MODULES) ) {
    return '';
  }

  load_module('Maps', $html);

  return maps_show_map({
    QUICK                 => 1,
    DATA                  => {
      $Msgs_->{LOCATION_ID} => [ {
        uid   => $Msgs_->{UID},
        login => $Msgs_->{LOGIN},
        fio   => $Msgs_->{FIO}
      } ]
    },
    LOCATION_TABLE_FIELDS => 'LOGIN,UID,FIO',
    #GET_LOCATION => 1,
    #ICON         => 'atm',
    OUTPUT2RETURN         => 1,
    HIDE_ALL_LAYERS       => 1,
    MAP_ZOOM              => 16,
    SMALL                 => 1,
    MAP_HEIGHT            => 25,
    SHOW_BUILD            => $Msgs_->{LOCATION_ID},
    NAVIGATION_BTN        => 1
  });

}

#**********************************************************
=head2 msgs_progress_bar_show($Msgs)

=cut
#**********************************************************
sub msgs_progress_bar_show {
  my Msgs $Msgs_ = shift;

  my $pb_list = $Msgs_->pb_msg_list({
    MAIN_MSG   => $Msgs_->{ID},
    CHAPTER_ID => $Msgs_->{CHAPTER},
    COLS_NAME  => 1
  });

  _error_show($Msgs_);

  if ( $Msgs_->{TOTAL} > 0 ) {
    my $progress_name = '';
    my $cur_step = 0;
    my $tips = '';

    foreach my $line ( @{$pb_list} ) {
      my $step_map = $line->{step_date} || '';

      if ( $line->{coorx1} && $line->{coorx1} + $line->{coordy} > 0 ) {
        $step_map = $html->button($line->{step_date},
          "index=" . get_function_index('maps_show_map') . "&COORDX=$line->{coordx}&COORDY=$line->{coordy}&TITLE=$line->{step_name}+$line->{step_date}");
      }

      $progress_name .= "['" . ($line->{step_name} || $line->{step_num}) . "', '$step_map' ], ";
      if ( $line->{step_date} ) {
        $cur_step = $line->{step_num};
        $tips = $line->{step_tip};
      }
    }

    return $html->tpl_show(_include('msgs_progressbar', 'Msgs'), {
        PROGRESS_NAMES => $progress_name,
        CUR_STEP       => $cur_step || 0,
        TIPS           => $tips,
      }, { OUTPUT2RETURN => 1 });
  }

  return '';
}

#**********************************************************
=head2 _msgs_show_change_subject_template()

=cut
#**********************************************************
sub _msgs_show_change_subject_template{

  my $subject       = $FORM{subject} || '';
  my $changes_index = get_function_index('msgs_admin');
  my $msg_id       = $FORM{msg_id};

  $html->tpl_show(_include('msgs_change_subject', 'Msgs'), {
      SUBJECT => $subject,
      INDEX   => $changes_index,
      ID      => $msg_id,
    }, {  });

  return 1;
}

#**********************************************************
=head2 _msgs_edit_reply()

=cut
#**********************************************************
sub _msgs_edit_reply {

  return 1 unless ( $permissions{7} && $permissions{7}->{1} && $FORM{edit_reply} );

  $Msgs->message_reply_change({
    ID    => $FORM{edit_reply},
    TEXT  => $FORM{replyText}
  });

  return 1;
}

#**********************************************************
=head2 work_planning_table_show($message_id)

=cut
#**********************************************************
sub work_planning_table_show {
  my ($message_id) = @_;

  require Workplanning::db::Workplanning;
  Workplanning::db::Workplanning->import();

  my $Workplanning = Workplanning->new($db, $admin, \%conf);

  my $workplanning_list = $Workplanning->list({
    COLS_NAME => 1,
    DESC      => "desc",
    MSGS_ID   => $message_id
  });
  _error_show($Workplanning) and return 0;

  unless ( scalar @${workplanning_list} ) {
    return 0;
  }

  my $table = $html->table({
      caption => $lang{RELATED_WORK},
      title   => [ "ID", $lang{DATE_OF_CREATION}, $lang{DATE_OF_EXECUTION}, $lang{RESPONSIBLE}, $lang{DESCRIPTION} ],
      qs      => $pages_qs,
      ID      => "TABLE_ID",
      MENU    =>
      "$lang{SEARCH}:index=" . get_function_index('work_planning_add') . "&MSG_WORKPLANNING=$message_id&$pages_qs:add",
      EXPORT  => 1
    }
  );

  foreach my $item ( @{$workplanning_list} ) {
    $table->addrow(
      $item->{id},
      $item->{date_of_creation},
      $item->{date_of_execution},
      $item->{name},
      $item->{description}
    );
  }

  print $table->show();

  return 1;
}


#**********************************************************
=head2 _msgs_reply_admin()

=cut
#**********************************************************
sub _msgs_reply_admin {
  if ( $FORM{RUN_TIME} ) {
    my ($h, $min, $sec) = split(/:/, $FORM{RUN_TIME}, 3);
    $FORM{RUN_TIME} = ($h || 0) * 60 * 60 + ($min || 0) * 60 + ($sec || 0);
  }
  my $reply_id;

  if ( $FORM{REPLY_SUBJECT} || $FORM{REPLY_TEXT} || $FORM{FILE_UPLOAD} || $FORM{SURVEY_ID} ) {

    $Msgs->message_reply_add(
      {
        %FORM,
        AID => $admin->{AID},
        IP  => $admin->{SESSION_IP},
      }
    );
    $reply_id = $Msgs->{INSERT_ID};
    $FORM{REPLY_ID} = $reply_id;

    if ( !_error_show($Msgs) ) {

      # Fixing empty attachment filename
      if ( $FORM{FILE_UPLOAD} && $FORM{FILE_UPLOAD}->{'Content-Type'} && !$FORM{FILE_UPLOAD}->{filename} ) {
        my $extension = 'dat';
        for my $ext ( 'jpg', 'jpeg', 'png', 'gif', 'txt', 'pdf' ) {
          if ( $FORM{FILE_UPLOAD}->{'Content-Type'} =~ /$ext/i ) {
            $extension = $ext;
            last;
          }
        }
        $FORM{FILE_UPLOAD}->{filename} = 'reply_img_' . $Msgs->{INSERT_ID} . q{.} . $extension
      }

      #Add attachment
      if ( $FORM{FILE_UPLOAD}->{filename} && $FORM{ID} ) {

        my $attachment_saved = msgs_receive_attachments($FORM{ID}, {
            REPLY_ID => $Msgs->{REPLY_ID},
            UID      => $FORM{UID},
            MSG_INFO => {%$Msgs}
          });

        if (!$attachment_saved){
          _error_show($Msgs);
          $html->message('err', $lang{ERROR}, "Can't save attachment");
        }
      }

    }
  }

  my %params = ();
  my $msg_state = $FORM{STATE} || 0;
  #$FORM{STATE}         = $msg_state;
  $params{CHAPTER} = $FORM{CHAPTER_ID} if ( $FORM{CHAPTER_ID} );
  $params{STATE} = ($msg_state == 0 && !$FORM{MAIN_INNER_MESSAGE} && !$FORM{REPLY_INNER_MSG}) ? 6 : $msg_state;
  $params{CLOSED_DATE} = "$DATE  $TIME" if ( $msg_state == 1 || $msg_state == 2 );
  $params{DONE_DATE} = $DATE if ( $msg_state > 1 );

  $Msgs->message_change({
    UID        => $LIST_PARAMS{UID},
    ID         => $FORM{ID},
    USER_READ  => "0000-00-00 00:00:00",
    ADMIN_READ => "$DATE $TIME",
    %params
  });

  if ( $FORM{STEP_NUM} ) {

    my $chapter = $Msgs->pb_msg_list(
      {
        MAIN_MSG           => $FORM{ID},
        CHAPTER_ID         => $FORM{CHAPTER},
        STEP_NUM           => $FORM{STEP_NUM},
        USER_NOTICE        => '_SHOW',
        RESPONSIBLE_NOTICE => '_SHOW',
        FOLLOWER_NOTICE    => '_SHOW',
        COLS_NAME          => 1,
      }
    );

    if ( !defined($Msgs->{TOTAL}) ) {
      $Msgs->msg_watch_info($FORM{ID});
      my $watch_aid = $Msgs->{AID};

      my %send_msgs = (
        SUBJECT => $chapter->[0]->{step_name},
        MESSAGE => $FORM{REPLY_TEXT} || "$lang{CHAPTER} $chapter->[0]->{step_name} $lang{DONE}",
      );

      foreach my $chapter_info ( @{$chapter} ) {
        if ( $chapter_info->{user_notice} && $FORM{UID} ) {
          $Sender->send_message({ UID => $FORM{UID}, SENDER_TYPE => 'Mail', %send_msgs });
        }
        elsif ( $chapter_info->{responsible_notice} && $FORM{RESPOSIBLE} ) {
          $Sender->send_message({ AID => $FORM{RESPOSIBLE}, %send_msgs });
        }
        elsif ( $chapter_info->{follower_notice} && $watch_aid ) {
          $Sender->send_message({ AID => $watch_aid, %send_msgs });
        }
      }
    }

    $Msgs->pb_msg_change(\%FORM);
  }

  $FORM{chg} = $FORM{ID};
  if ( _error_show($Msgs) ) {
    return 0;
  }

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });
  $Msgs->message_info($FORM{ID});

  msgs_notify_user({
    UID        => $FORM{UID},
    STATE_ID   => $Msgs->{STATE},
    STATE      => $msgs_status->{$Msgs->{STATE}},
    REPLY_ID   => $reply_id,
    MSG_ID     => $FORM{ID},
    MSGS       => $Msgs,
    SENDER_AID => $admin->{AID},
  });

  if ( !$FORM{RESPOSIBLE} ) {
    $Msgs->message_change({
      RESPOSIBLE => $admin->{AID},
      ID         => $FORM{ID},
    });
  }

  msgs_notify_admins({
    STATE      => $msgs_status->{$Msgs->{STATE}},
    SENDER_AID => $admin->{AID},
    MSG_ID     => $FORM{ID},
    MSGS       => $Msgs,
  });

  my $header_message = urlencode("$lang{MESSAGE} $lang{SENDED}" . ($FORM{ID} ? " : $FORM{ID}" : ''));
  $html->redirect("?index=$index"
      . "&UID=" . ($FORM{UID} || q{})
      . "&chg=" . ($FORM{ID} || q{})
      . "&MESSAGE=$header_message#last_msg",
    {
      MESSAGE_HTML => $html->message('info', $lang{INFO}, "$lang{REPLY}", { OUTPUT2RETURN => 1 }),
      WAIT         => '0'
    }
  );

  return 1;
}

#**********************************************************
=head2 msgs_dispatch_admins($attr) - dispatch admins

=cut
#**********************************************************
sub msgs_dispatch_admins {
  my ($attr) = @_;

  if ($FORM{change_admins}) {
    $Msgs->dispatch_admins_change({%FORM});
    $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" ) if (!$Msgs->{errno});
  }

  my $list = $Msgs->dispatch_admins_list({
    DISPATCH_ID => $attr->{DISPATCH_ID} || $FORM{chg},
    COLS_NAME => 1
  });

  my %active_admins = ();
  foreach my $line (@$list) {
    $active_admins{ $line->{aid} } = 1;
  }

  $list = $admin->list({ %LIST_PARAMS, DISABLE => 0, COLS_NAME => 1, PAGE_ROWS => 1000 });

  my $table = $html->table({
    width      => '100%',
    caption    => $lang{ADMINS},
    title      => [ '#', $lang{ADMIN}, $lang{FIO} ],
    qs         => $pages_qs,
    ID         => 'MSGS_ADMINS'
  });

  foreach my $line (@$list) {
    $table->addrow(
      $html->form_input(
        'AIDS',
        $line->{aid},
        {
          TYPE  => 'checkbox',
          STATE => ($active_admins{ $line->{aid} }) ? 1 : undef
        }
      )
        . $line->{aid},
      $line->{login},
      $line->{name}
    );
  }

  print $html->form_main({
    CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
    HIDDEN  => {
      index       => $index,
      DISPATCH_ID => $FORM{chg},
      chg         => $FORM{chg},
    },
    SUBMIT  => { change_admins => $lang{CHANGE} },
    NAME    => 'admins_list'
  });

  return 1;
}

1