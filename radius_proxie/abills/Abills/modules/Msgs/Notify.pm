=head1 NAME

  Notify admins and users

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(sendmail _bp);

our ($db,
  %lang,
  $html,
  $admin,
  %conf,
  $ui
);

my $Msgs = Msgs->new($db, $admin, \%conf);
my $Sender = Abills::Sender::Core->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_notify_admins($attr)

  Arguments:
    $attr
      STATE
      MSGS
      MSG_ID
      SENDER_AID
      SENDER_UID
      SKIP_TELEGRAM
      AID

  Results:

=cut
#**********************************************************
sub msgs_notify_admins {
  my ($attr) = @_;

  my $admins_resposible_for_chapter = $Msgs->admins_list({
    EMAIL_NOTIFY => 1,
    DISABLE      => 0,
    AID          => $attr->{AID},
    CHAPTER_ID   => $FORM{CHAPTER},
    COLS_NAME    => 1
  });

  my $message_id = $attr->{MSG_ID} || $Msgs->{INSERT_ID} || '--';
  my $reply_id   = $Msgs->{REPLY_ID} || '--';
  my $Msgs_      = $attr->{MSGS};
  my $subject    = ($Msgs_->{SUBJECT} || $FORM{SUBJECT} || q{}) . ($FORM{REPLY_SUBJECT}
                                                                 ? ' / ' . $FORM{REPLY_SUBJECT}
                                                                 : '');

  my $site = '';
  my $referer = ($conf{BILLING_URL} || $ENV{HTTP_REFERER} || '');
  if ( $referer && $referer =~ /(https?:\/\/[a-zA-Z0-9:\.\-]+)\/?/g ) {
    $site = $1;
  }

  foreach my $line ( @{$admins_resposible_for_chapter} ) {
    next if ( !$line->{email_notify} );

    my $RESPOSIBLE = ($FORM{RESPOSIBLE} && $FORM{RESPOSIBLE} eq $line->{aid}) ? $lang{YES} : $lang{NO};
    my $message = $html->tpl_show(
      _include('msgs_email_notify', 'Msgs'),
      {
        SITE       => $site,
        LOGIN      => $Msgs->{LOGIN} || $FORM{LOGIN} || $ui->{LOGIN} || $user->{LOGIN} || '',
        ADMIN      => ($FORM{INNER_MSG}) ? "$lang{ADMIN}: $admin->{A_LOGIN} (" . ($admin->{A_FIO} || q{}) . '}' : '',
        UID        => $Msgs->{UID} || $FORM{UID} || $LIST_PARAMS{UID} || '',
        DATE       => $DATE,
        TIME       => $TIME,
        ID         => $message_id . (($reply_id) ? " / $reply_id" : ''),
        RESPOSIBLE => $RESPOSIBLE,
        SUBJECT    => $subject,
        STATUS     => $attr->{STATE} || $FORM{STATE} || 0,
        MESSAGE    => $FORM{MESSAGE} || $FORM{REPLY_TEXT} || $Msgs->{MESSAGE} || '',
        ATTACHMENT => ($FORM{FILE_UPLOAD} && $FORM{FILE_UPLOAD}->{filename}) ? $FORM{FILE_UPLOAD}->{filename} : q{}
      },
      { OUTPUT2RETURN => 1 }
    );

    sendmail($conf{ADMIN_MAIL},
      $line->{email},
      "$conf{WEB_TITLE}  -  $lang{NEW_MESSAGE} " . $subject,
      $message,
      $conf{MAIL_CHARSET} || 'utf-8', undef,
      { MAIL_HEADER => [ "X-ABillS-Msg-ID: $message_id", "X-ABillS-Reply-ID: $reply_id" ] });
  }

  if ( $conf{TELEGRAM_TOKEN} && ! $attr->{SKIP_TELEGRAM} ) {
    # Get resposible admin
    my $message_info = $Msgs->messages_list({
      MSG_ID     => $message_id,
      RESPOSIBLE => '_SHOW',
      COLS_NAME  => 1
    });

    if (
      # Error
      $Msgs->{errno}
        # Broken response
        || (!$message_info || ref $message_info ne 'ARRAY' || !$message_info->[0] || ref $message_info->[0] ne 'HASH')
        # If no resposible, don't need to notify
        || !$message_info->[0]->{resposible}
    ) {
      return 0;
    }

    my $resposible_aid = $message_info->[0]->{resposible} || q{};

    # If he has sent a message, he knows about it
    if ( $attr->{SENDER_AID} && $attr->{SENDER_AID} eq $resposible_aid ) {
      return 1;
    }

    #my $link = $site . "/admin/index.cgi?get_index=msgs_admin&full=1&chg=" . ($message_id || '');
    my $message = $FORM{MESSAGE} || $FORM{REPLY_TEXT} || $Msgs->{MESSAGE} || '';

    require Msgs::Messaging;
    msgs_send_via_telegram($message_id, {
      AID         => $resposible_aid,
      SUBJECT     => $lang{YOU_HAVE_NEW_REPLY} . " '". $html->b($subject) ."'",
      SENDER_UID  => $attr->{SENDER_UID},
      MESSAGE     => $message,
      SENDER_TYPE => $Contacts::TYPES{TELEGRAM},
      PARSE_MODE  => 'HTML'
    });
  }

  return 1;
}

#**********************************************************
=head2 msgs_notify_user($attr)

  Arguments:
    $attr
      REPLY_ID
      MSGS
      SEND_TYPE
         1 - Msgs delivery tpl
         
      To notify single user:
      UID
      MSG_ID
      MESSAGE
      
      To notify different users with different texts
      MESSAGES_BATCH - hash_ref
        UID => {
          MSG_ID  => integer,
          MESSAGE => string
        }

  Results:

=cut
#**********************************************************
sub msgs_notify_user {
  my ($attr) = @_;

  return 0 if ($attr->{INNER_MSG} || $attr->{REPLY_INNER_MSG} || $FORM{INNER_MSG} || $FORM{REPLY_INNER_MSG});

  if ( $attr->{MESSAGES_BATCH} && ref $attr->{MESSAGES_BATCH} ) {
    # Call self for each message id

    my %msg_id_for_user = %{ $attr->{MESSAGES_BATCH} };

    foreach my $_uid  ( sort keys %msg_id_for_user ) {
      msgs_notify_user({
        UID            => $_uid,
        MSG_ID         => $msg_id_for_user{$_uid}->{MSG_ID},
        %{$attr},
        MESSAGES_BATCH => undef,
      });
    }

    return 1;
  }

  my $message_id = $attr->{MSG_ID};
  my $reply_id = $attr->{REPLY_ID} || 0;

  my $message_params = _msgs_notify_user_collect_message_content($message_id, $attr);
  return 0 if (!$message_params);
  my $message = $message_params->{MESSAGE};
  my $subject = $message_params->{SUBJECT};
  my $state   = $message_params->{STATE};

  my $users_list = $users->list({
    LOGIN     => '_SHOW',
    FIO       => '_SHOW',
    EMAIL     => '_SHOW',
    UID       => $attr->{UID} || '-1',
    COLS_NAME => 1
  });

  my $message_tpl = ($attr->{SEND_TYPE} && $attr->{SEND_TYPE} == 1)
                      ? 'msgs_email_delivery'
                      : 'msgs_email_notify';

  # Make view url
  my $preview_url_without_message_id = '';
  my $site = $conf{CLIENT_INTERFACE_URL} || $conf{BILLING_URL} || $ENV{HTTP_REFERER} || q{};
  $site =~ s/admin\/?//;
  if ($site && $site =~ m/(https?:\/\/[a-zA-Z0-9:\.\-]+)\//g ) {
    $site = $1 || '';
    $preview_url_without_message_id = $site . "/index.cgi?get_index=msgs_user&ID=";
  }

  # Make attachments
  my $ATTACHMENTS = $attr->{ATTACHMENTS} || [];

  foreach my $user_info  ( @{$users_list} ) {

    my $preview_url = ($preview_url_without_message_id && $message_id ne '--')
      ? $preview_url_without_message_id . $message_id
      : undef;


    my $mail_message = $html->tpl_show(
      _include($message_tpl, 'Msgs'),
      {
        SITE        => $site,
        DATE        => $DATE,
        TIME        => $TIME,
        LOGIN       => $user_info->{login},
        UID         => $user_info->{uid},
        ID          => $message_id,
        ATTACHMENT  => $attr->{FILE_UPLOAD}->{filename} || '',
        SUBJECT_URL => $preview_url,

        %$message_params,

        SUBJECT     => $subject,
        STATUS      => $state,
        MESSAGE     => $message,
      },
      { OUTPUT2RETURN => 1 }
    );

    $Sender->send_message({
      UID         => $user_info->{uid},
      SUBJECT     => ($conf{WEB_TITLE} || q{}) ." - $lang{NEW_MESSAGE} " . $subject,
      SENDER_TYPE => $attr->{SEND_TYPE} || 'Mail',
      # TO_ADDRESS  => $line->{email},
      MESSAGE     => $message,
      MAIL_TPL    => $mail_message,
      ATTACHMENTS => ($FORM{SEND_TYPE} && $#{ $ATTACHMENTS } > - 1) ? $ATTACHMENTS : undef,
      ACTIONS     => $preview_url,
      MAIL_HEADER => [ "X-ABillS-Msg-ID: $message_id", "X-ABillS-REPLY-ID: $reply_id" ]
    });

    if ( $conf{TELEGRAM_TOKEN} && $message_id ne '--' ) {
      require Msgs::Messaging;
      msgs_send_via_telegram($message_id, {
          UID        => $user_info->{uid},
          MESSAGE    => $message,
          SUBJECT    => "_{YOU_HAVE_NEW_REPLY}_ '". $html->b($subject)  ."'",
          PARSE_MODE => 'HTML'
        });
    }
  }

  return 1;
}

#**********************************************************
=head2 _msgs_notify_user_collect_message_content($message_id, $attr)

   Arguments:
     $message_id
     $attr

   Returns:


=cut
#**********************************************************
sub _msgs_notify_user_collect_message_content {
  my ($message_id, $attr) = @_;

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });

  my $subject = ($attr->{SUBJECT} || '') . (($FORM{REPLY_SUBJECT}) ? ' / ' . $FORM{REPLY_SUBJECT} : '');
  my $message = $attr->{MESSAGE} || $attr->{REPLY_TEXT};
  my $state = $attr->{STATE} || ($attr->{STATE_ID} && $msgs_status->{$attr->{STATE_ID}}
    ? $msgs_status->{$attr->{STATE_ID}}
    : ''
  );

  my $responsible_name = $attr->{RESPOSIBLE_ADMIN_LOGIN};

  my $uid = $attr->{UID};

  my $is_inner_msg = $attr->{INNER_MSG};
  return 0 if ( $is_inner_msg );

  my $reply_id = $attr->{REPLY_ID};

  my $got_required_fields_from_attr = ($subject && $message && defined($state) && $uid && defined $responsible_name);

  # If no message id, check for required fields
  if ( !$message_id ) {
    if ( $got_required_fields_from_attr ) {
      # Can send with wrong id
      $message_id = '--';
    }
    else {
      # Don't have enough params, return
      _bp('msgs_notify_user', "don't have enough params") if ( $attr->{DEBUG} );
      return 0;
    }
  }
  elsif ( !$got_required_fields_from_attr ) {
    # Create new object to fix it's dirty state
    my $msg = Msgs->new($db, $admin, \%conf);
    $msg->message_info($message_id);
    return 0 if ( $msg->{errno} || $msg->{INNER_MSG} );

    $subject = $msg->{SUBJECT};
    $message = $msg->{MESSAGE};
    $uid = $msg->{UID};
    $state = ($msg->{STATE} && $msgs_status->{$msg->{STATE}}
      ? $msgs_status->{$msg->{STATE}}
      : $msg->{STATE}
    );
    my $responsible_id = $msg->{RESPOSIBLE};
    $responsible_name = ($responsible_id)
      ? do {
        my $list = $admin->list({ AID => $responsible_id, COLS_NAME => 1 });
        my $adm = ($admin->{TOTAL} && $list)
          ? $list->[0]->{name} || $list->[0]->{login}
          : '';
        $adm;
      }
      : '';

    if ( $reply_id ) {
      my $replies_for_id = $Msgs->messages_reply_list({
        ID        => $reply_id,
        MSG_ID    => $message_id,
        INNER_MSG => '0',
        PAGE_ROWS => 1,
        COLS_NAME => 1,
      });

      my $reply = $replies_for_id->[0];

      if ( $reply && ref $reply ) {
        return 0 if ( $reply->{inner_msg} );
        $message = $reply->{text};
      }
    }
  }

  if ( !$uid ) {
    _bp('msgs_notify_user', "don't have enough params") if ( $attr->{DEBUG} );
    return 0;
  };

  if ( $attr->{SURVEY_ID} ) {
    $message = msgs_survey_show({
      SURVEY_ID        => $attr->{SURVEY_ID},
      MSG_ID           => $message_id,
      SHOW_SURVAY_TEXT => 1,
      MAIN_MSG         => 1,
    });
  }

  return {
    MESSAGE    => $message,
    SUBJECT    => $subject,
    STATE      => $state,
    RESPOSIBLE => $responsible_name
  };
}

#**********************************************************
=head2 msgs_admin_quick_message()

=cut
#**********************************************************
sub msgs_admin_quick_message {
  unless ( $conf{PUSH_ENABLED} || $conf{WEBSOCKET_ENABLED} ) {
    $html->message('err', $lang{ERROR}, 'Need Websocket or Push to be configured');
    return 0;
  }

  if ( $FORM{MESSAGE} && $FORM{AID} && $FORM{SEND_TYPE} ) {

    foreach my $aid ( split(',\s?', $FORM{AID}) ) {

      # Send via sender
      my $sended = $Sender->send_message({
        AID         => $aid,
        TITLE       => $admin->{A_FIO} ? "$lang{FROM} : $admin->{A_FIO} " : '',
        MESSAGE     => $FORM{MESSAGE},
        SENDER_TYPE => $FORM{SEND_TYPE}
      });

      if ( $sended ) {
        $html->message('info', $lang{SENT} . ' : ' . $aid);
      }
    }

    return 1;
  }

  my $admins_online_list = $admin->online_list();
  # make list with checkboxes

  # Form HTML for checkbox panel
  my $checkboxes_html = '';
  foreach my $adm ( sort {$a->{aid} <=> $b->{aid}} @{$admins_online_list} ) {
    #    next if ($adm->{aid} == $admin->{AID});

    my $checkbox = $html->form_input('AID', $adm->{aid}, { TYPE => 'checkbox' });
    my $label = $html->element('label', $checkbox . $adm->{admin});
    my $checkbox_group = $html->element('div', $label, { class => 'checkbox col-md-6 text-left' });

    $checkboxes_html .= $checkbox_group;
  }

  $html->tpl_show(_include('msgs_admin_quick_message', 'Msgs'),
    {
      CHECKBOXES            => $checkboxes_html,
      PUSH_RADIO_VISIBLE    => $conf{PUSH_ENABLED},
      BROWSER_RADIO_VISIBLE => $conf{WEBSOCKET_ENABLED}
    }
  );

  return 1;
}


1;