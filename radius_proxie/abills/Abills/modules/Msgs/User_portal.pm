=head NAME

 User Portal

=cut

use strict;
use warnings FATAL => 'all';
use Time::Piece;
use Abills::Base qw(urlencode convert int2byte);
use Msgs::Misc::Attachments;

our(
  $db,
  %conf,
  $html,
  %lang,
  $admin,
);

# Todo: generalize ( Now there are separate arrays in almost each Msgs .pm file)
my @priority_colors = ('#8A8A8A', $_COLORS[8], $_COLORS[9], '#E06161', $_COLORS[6]);
my @priority = ($lang{VERY_LOW}, $lang{LOW}, $lang{NORMAL}, $lang{HIGH}, $lang{VERY_HIGH});

my $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_user() - Client web interface

=cut
#**********************************************************
sub msgs_user {

  if ($FORM{edit_reply}) {
    _user_edit_reply();
    return 1;
  }

  #If User have new unread msg, open it
  #(Return msg object with LAST_ID)
  if($user->{UID} && !($FORM{ID} || $Msgs->{LAST_ID} || $Msgs->{INSERT_ID} || $Msgs->{ID}) ){

    my %SHOW_PARAMS = (
      UID        => $user->{UID},
      USER_READ  => '0000-00-00  00:00:00',
      ADMIN_READ => '>0000-00-00 00:00:00',
      INNER_MSG  => 0,
    );

    $Msgs->messages_new({%SHOW_PARAMS});
  }

  my $msgs_status = msgs_sel_status({ HASH_RESULT => 1 });

  $Msgs->{STATE_SEL} = $html->form_select(
    'STATE',
    {
      SELECTED   => $FORM{STATE} || 0,
      #SEL_HASH   => { %{$msgs_status}{(0,1,2)} },
      SEL_HASH   => {
        0 => $msgs_status->{0},
        1 => $msgs_status->{1},
        2 => $msgs_status->{2}
    },
    NO_ID      => 1,
    USE_COLORS => 1,
    }
  );

  $Msgs->{PRIORITY_SEL} = msgs_sel_priority();

  if ($FORM{send}) {

    if ($conf{MSGS_USER_REPLY_SECONDS_LIMIT}){
      my $fresh_messages = $Msgs->messages_list({
        UID       => $user->{UID},
        STATE     => $FORM{STATE},
        GET_NEW   => $conf{MSGS_USER_REPLY_SECONDS_LIMIT},
        COLS_NAME => 1
      });

      if ($Msgs->{TOTAL} > 0){
        my $message_sent = $fresh_messages->[0] || {};
        my $message_sent_id = $message_sent->{id} || 0;

        my $header_message = "$lang{MESSAGE} $message_sent_id. $lang{EXIST} ";

        $html->redirect(
          "?index=$index&sid=" . ($sid || $user->{SID} || $user->{sid})
          . "&ID=$message_sent_id#last_msg",
          {
            WAIT => 3,
            MESSAGE => $header_message
          }
        );

        exit 0;
      }
    }

    $Msgs->message_add(
      {
        UID       => $user->{UID},
        STATE     => ($FORM{STATE}) ? $FORM{STATE} : 0,
        USER_READ => "$DATE  $TIME",
        IP        => $ENV{'REMOTE_ADDR'},
        %FORM,
        USER_SEND => 1,
      }
    );

    if ( !$Msgs->{errno} ) {

      #Add attachment
      if ( $FORM{FILE_UPLOAD}->{filename} && $Msgs->{MSG_ID} ) {

        my $attachment_saved = msgs_receive_attachments($Msgs->{MSG_ID}, {
            MSG_INFO => {
              UID => $user->{UID}
            }
        });

        if (!$attachment_saved){
          _error_show($Msgs);
          $html->message('err', $lang{ERROR}, "Can't save attachment");
        }
      }

      $html->message('info', $lang{INFO}, "$lang{MESSAGE} # $Msgs->{MSG_ID}.  $lang{MSG_SENDED} ");
      msgs_notify_admins();

      my $message_added_text = "$lang{MESSAGE} " . ($Msgs->{MSG_ID} ? " #$Msgs->{MSG_ID} " : '') . $lang{MSG_SENDED};
      my $header_message = urlencode($message_added_text);
      my $message_link = "?index=$index&sid=" . ($sid || $user->{SID} || $user->{sid})
        . "&MESSAGE=$header_message&ID=" . ($Msgs->{MSG_ID} || q{}) . '#last_msg';

      $html->redirect( $message_link,
        {
          MESSAGE_HTML => $html->message(
            'info',
            $lang{INFO},
            $html->button($message_added_text, $message_link, { class => 'alert-link' }),
            { OUTPUT2RETURN => 1 }
          ),
          WAIT         => '0'
        }
      );
      exit 0;
    }

    return 1;
  }
  elsif ($FORM{ATTACHMENT}) {
    return msgs_attachment_show(\%FORM);
  }
  elsif ($FORM{ID} || $Msgs->{LAST_ID}) {
    if ($FORM{reply}) {
      my %params = ();
      $params{CLOSED_DATE} = $DATE if ($FORM{STATE} && $FORM{STATE} > 0);
      $params{DONE_DATE}   = $DATE if ($FORM{STATE} && $FORM{STATE} > 1);
      $params{ADMIN_READ}  = "0000-00-00  00:00:00" if (! $FORM{INNER});

      $Msgs->message_change({
        UID            => $LIST_PARAMS{UID},
        ID             => $FORM{ID},
        STATE          => $FORM{STATE},
        RATING         => $FORM{RATING}         ? $FORM{RATING}         : 0,
        RATING_COMMENT => $FORM{RATING_COMMENT} ? $FORM{RATING_COMMENT} : '',
        %params
      });

      if ($FORM{REPLY_SUBJECT} || $FORM{REPLY_TEXT} || $FORM{FILE_UPLOAD} || $FORM{SURVEY_ID}) {
        $Msgs->message_reply_add({
          %FORM,
          AID => 0,
          IP  => $admin->{SESSION_IP},
          UID => $LIST_PARAMS{UID}
        });

        if (!$Msgs->{errno}) {
          #Save signature
          if ( $FORM{signature} && $FORM{ID} ) {
            msgs_receive_signature($user->{UID}, $FORM{ID}, $FORM{signature});
          }

          #Add attachment
          if ( $FORM{FILE_UPLOAD}->{filename} && $Msgs->{REPLY_ID} ) {
            my $attachment_saved = msgs_receive_attachments($Msgs->{MSG_ID} || $FORM{ID}, {
                REPLY_ID => $Msgs->{REPLY_ID},
                MSG_INFO => {
                  UID => $user->{UID}
                }
              });

            if ( !$attachment_saved ) {
              _error_show($Msgs);
              $html->message('err', $lang{ERROR}, "Can't save attachment");
            }
          }
        }
        $html->message( 'info', $lang{INFO}, "$lang{REPLY}" );

        msgs_notify_admins({
          MSG_ID     => $FORM{ID},
          SENDER_UID => $user->{UID}
        });

        # Instant redirect
        my $header_message = urlencode("$lang{MESSAGE} $lang{SENDED}" . ($Msgs->{INSERT_ID} ? " : $Msgs->{INSERT_ID}" : ''));
        $html->redirect("?index=$index&sid=".( $sid || $user->{SID} || $user->{sid} )
          ."&MESSAGE=$header_message&ID=" . ($Msgs->{MSG_ID} || $FORM{ID} || q{}) . '#last_msg');
        exit 0;
      }
      return 1;
    }
    elsif ($FORM{change}) {
      $Msgs->message_change({
        UID        => $LIST_PARAMS{UID},
        ID         => $FORM{ID},
        ADMIN_READ => "0000-00-00 00:00:00",
        STATE      => $FORM{STATE} || 0,
      });

      if ($FORM{SURVEY_ANSWER}) {
        msgs_survey_show({ SURVEY_ANSWER => $FORM{SURVEY_ANSWER} });
      }
    }

    if ($Msgs->{LAST_ID}) {
      $FORM{ID} = $Msgs->{LAST_ID};
    }

    $Msgs->message_info($FORM{ID}, { UID => $LIST_PARAMS{UID} });
    _error_show($Msgs);
    if ($Msgs->{errno}) {
      return 1;
    }

    $Msgs->{ACTION}        = 'reply';
    $Msgs->{LNG_ACTION}    = $lang{REPLY};
    $Msgs->{STATE_NAME}    = $html->color_mark($msgs_status->{$Msgs->{STATE}}) if(defined($Msgs->{STATE}) && $msgs_status->{$Msgs->{STATE}});
    $Msgs->{PRIORITY_TEXT} = $html->color_mark($priority[ $Msgs->{PRIORITY} ], $priority_colors[ $Msgs->{PRIORITY} ]);

    if ($Msgs->{PRIORITY} == 4) {
      $Msgs->{MAIN_PANEL_COLOR} = 'box-danger';
    }
    elsif ($Msgs->{PRIORITY} == 3) {
      $Msgs->{MAIN_PANEL_COLOR} = 'box-warning';
    }
    elsif ($Msgs->{PRIORITY} >= 1) {
      $Msgs->{MAIN_PANEL_COLOR} = 'box-info';
    }
    else {
      $Msgs->{MAIN_PANEL_COLOR} = 'box-primary';
    }

    my @REPLIES = ();
    if ($Msgs->{ID}) {
      my $main_msgs_id = $Msgs->{ID};

      my $replies_list = $Msgs->messages_reply_list({
        MSG_ID       => $main_msgs_id,
        CONTENT_SIZE => '_SHOW',
        INNER_MSG    => 0,
        CONTENT_TYPE => '_SHOW',
        COLS_NAME    => 1
      });

      my $total_reply = $Msgs->{TOTAL};
      my $reply = '';

      if ($Msgs->{SURVEY_ID}) {
        my $main_message_survey = msgs_survey_show({
          SURVEY_ID => $Msgs->{SURVEY_ID},
          MSG_ID    => $Msgs->{ID},
          MAIN_MSG  => 1,
          NOTIFICATION_MSG => ($Msgs->{STATE} && $Msgs->{STATE} == 9) ? 1 : 0,
        });

        if($main_message_survey){
          push @REPLIES, $main_message_survey;
        }
      }

      foreach my $line (@$replies_list) {

        $FORM{REPLY_ID} = $line->{id};

        if ($line->{survey_id}) {
          push @REPLIES, msgs_survey_show({
              SURVEY_ID => $line->{survey_id},
              REPLY_ID  => $line->{id},
              TEXT      => $line->{text}
            });
        }
        else {
          if ($FORM{QUOTING} && $FORM{QUOTING} == $line->{id}) {
            $reply = $line->{text} if (! $FORM{json});
          }

          # Should check multiple attachments if got at least one
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

            $attachment_html = msgs_get_attachments_view($attachments_list, { NO_COORDS => 1 });
          }

          $FORM{ID} //= q{};
          my $quoting_button = $html->button(
            $lang{QUOTING}, "index=$index&QUOTING=$line->{id}&ID=$FORM{ID}&sid=". ($sid || q{}), { BUTTON => 1 }
          );
          my $edit_reply_button = '';
          if ($line->{creator_id} && $line->{creator_id} eq $user->{LOGIN}) {
            my $n = gmtime() + 3600 * 3;
            my $d = Time::Piece->strptime($line->{datetime}, "%Y-%m-%d %H:%M:%S");
            if (($n-$d)/60 < 5) {
              $edit_reply_button = $html->button(
                "$lang{EDIT}", "",
                { class => 'btn btn-default btn-xs reply-edit-btn', ex_params => "reply_id='$line->{id}'"}
              );
            }
          }

          push @REPLIES, $html->tpl_show(
              _include('msgs_reply_show', 'Msgs'),
              {
                LAST_MSG   => ($total_reply == $#REPLIES + 2) ? 'last_msg' : '',
                REPLY_ID   => $line->{id},
                DATE       => $line->{datetime},
                CAPTION    => convert($line->{caption}, { text2html => 1, json => $FORM{json} }),
                PERSON     => $line->{creator_id},
                MESSAGE    => msgs_text_quoting($line->{text}),
                COLOR      => (($line->{aid} > 0) ? 'box-success' : 'box-theme'),
                QUOTING    => $quoting_button,
                EDIT       => $edit_reply_button,
                ATTACHMENT => $attachment_html,
              },
              { OUTPUT2RETURN => 1 }
            );

          if ($reply ne '') {
            $reply =~ s/^/>  /g;
            $reply =~ s/\n/> /g;
          }
        }
      }

      if (!$Msgs->{ACTIVE_SURWEY} && ($Msgs->{STATE} < 1 || $Msgs->{STATE} == 6)) {
        push @REPLIES, $html->tpl_show(_include('msgs_client_reply', 'Msgs'), { %$Msgs, REPLY_TEXT => $reply }, { OUTPUT2RETURN => 1 });
      }
      else {
        #$html->message('info',  $lang{INFO},  "$msg_status[$Msgs->{STATE}] $lang{DATE}: $Msgs->{CLOSED_DATE}");
      }

      $Msgs->{MESSAGE} = convert($Msgs->{MESSAGE}, { text2html => 1, SHOW_URL => 1, json => $FORM{json} });
      $Msgs->{SUBJECT} = convert($Msgs->{SUBJECT}, { text2html => 1, json => $FORM{json} });

      if ($Msgs->{FILENAME}) {
        # Should check multiple attachments if got at least one
          my $attachments_list = $Msgs->attachments_list({
            MESSAGE_ID     => $Msgs->{ID},
            FILENAME     => '_SHOW',
            CONTENT_SIZE => '_SHOW',
            CONTENT_TYPE => '_SHOW',
            COORDX       => '_SHOW',
            COORDY       => '_SHOW',
          });

          $Msgs->{ATTACHMENT} = msgs_get_attachments_view($attachments_list, { NO_COORDS => 1 });
      }

      if ($Msgs->{STATE} == 9) {
        push @REPLIES, $html->button( "$lang{CLOSE}", "index=$index&STATE=10&ID=$FORM{ID}&change=1&sid=$sid",
            { class => 'btn btn-primary' } );
      }

      $Msgs->{REPLY} = join(($FORM{json}) ? ',' : '', @REPLIES);
      while ($Msgs->{MESSAGE} && $Msgs->{MESSAGE} =~ /\[\[(\d+)\]\]/) {
        my $msg_button = $html->button( $1, "&index=$index&ID=$1",
                { class => 'badge bg-blue'});
        $Msgs->{MESSAGE} =~ s/\[\[\d+\]\]/$msg_button/;
      }

      if (my $last_reply_index = scalar (@$replies_list)){
        $Msgs->{UPDATED} = $replies_list->[$last_reply_index - 1]->{datetime};
      }
      else {
        $Msgs->{UPDATED} = '--';
      }

      $html->tpl_show(_include('msgs_client_show', 'Msgs'), {
          %$Msgs,
          ID => $main_msgs_id
        });

      my %params = ();
      my $state = $FORM{STATE};
      $params{CLOSED_DATE} = $DATE if ($state && $state > 0);
      $params{DONE_DATE} = $DATE if ($state && $state > 1);

      $Msgs->message_change({
        UID       => $LIST_PARAMS{UID},
        ID        => $FORM{ID},
        USER_READ => "$DATE  $TIME",
        %params
      });

      msgs_redirect_filter({
        DEL => 1,
        UID => $LIST_PARAMS{UID},
      });
    }

    #return  0;
  }
  elsif(!$FORM{SEARCH_MSG_TEXT}) {
    $Msgs->{CHAPTER_SEL} = $html->form_select(
      'CHAPTER',
      {
        SELECTED       => $Msgs->{CHAPTER} || $conf{MSGS_USER_DEFAULT_CHAPTER} || undef,
        SEL_LIST       => $Msgs->chapters_list({ INNER_CHAPTER => 0, COLS_NAME => 1 }),
        MAIN_MENU      => get_function_index('msgs_chapters'),
        MAIN_MENU_ARGV => ($Msgs->{CHAPTER}) ? "chg=$Msgs->{CHAPTER}" : ''
      }
    );

    $html->tpl_show(
      _include('msgs_send_form_user', 'Msgs'),
      {
        %$Msgs,
      }
    );
  }

  if ($FORM{MESSAGE}) {
    $html->message('info', '', "$FORM{MESSAGE}");
  }

  _error_show($Msgs);

  my %statusbar_status = (
    0 => $msgs_status->{0},
    1 => $msgs_status->{1},
    2 => $msgs_status->{2},
    3 => $msgs_status->{3},
    4 => $msgs_status->{4},
    5 => $msgs_status->{5},
    6 => $msgs_status->{6}
  );

  $pages_qs .= "&SEARCH_MSG_TEXT=$FORM{SEARCH_MSG_TEXT}" if( $FORM{SEARCH_MSG_TEXT});

  my $status_bar = msgs_status_bar({ MSGS_STATUS => \%statusbar_status, USER_UNREAD => 1, SHOW_ONLY => 3 });
  if (! $FORM{sort}){
    $LIST_PARAMS{SORT} = '5 DESC, 4';
    delete $LIST_PARAMS{DESC};
    if(! defined($FORM{STATE})) {
      $LIST_PARAMS{STATE} = '!1,!2';
    }
  }

  $LIST_PARAMS{INNER_MSG} = 0;
  delete($LIST_PARAMS{STATE}) if ($FORM{STATE} && $FORM{STATE} =~ /\d+/ && $FORM{STATE} == 3);
  delete($LIST_PARAMS{PRIORITY}) if ($FORM{PRIORITY} && $FORM{PRIORITY} == 5);

  if (!defined($FORM{STATE}) && !$FORM{ALL_MSGS}) {
    $FORM{ALL_OPENED} = 1;
  }

  #===================================

  $html->tpl_show(_include('msgs_user_search_form', 'Msgs'), {%$Msgs});

  #If search messeges create custom table, else create deffult

  my $table;

  if ($FORM{SEARCH_MSG_TEXT}) {
    my $request_search_word = $FORM{SEARCH_MSG_TEXT};
    $request_search_word =~ s/\\/\\\\/gi;
    $request_search_word =~ s/\%/\\%/gi;
    $request_search_word =~ s/\'/\\'/gi;

    my $list = $Msgs->messages_list(
      {
        SUBJECT             => '_SHOW',
        CHAPTER_NAME        => '_SHOW',
        DATETIME            => '_SHOW',
        STATE               => '_SHOW',
        USER_READ           => '_SHOW',
        REPLY_TEXT          => '_SHOW',
        MESSAGE             => '_SHOW',
        SEARCH_MSGS_BY_WORD => $request_search_word,
        %LIST_PARAMS,
        COLS_NAME => 1
      }
    );

    $table = msgs_user_search_table(
      {
        ID          => $FORM{ID},
        SID         => $sid,
        TOTAL_MSGS  => $Msgs->{TOTAL},
        JSON        => $FORM{json},
        STATUS_BAR  => $status_bar,
        SEARCH_TEXT => $FORM{SEARCH_MSG_TEXT},
      },
      $msgs_status,
      $list
    );
  }
  else {
    my $list = $Msgs->messages_list({
      SUBJECT        => '_SHOW',
      DATETIME       => '_SHOW',
      STATE          => '_SHOW',
      USER_READ      => '_SHOW',
      %LIST_PARAMS,
      COLS_NAME      => 1
    });

    $table = $html->table({
      width   => '100%',
      caption => $lang{MESSAGES},
      title   => [ '#', $lang{SUBJECT}, $lang{DATE}, $lang{STATUS}, '-' ],
      qs      => $pages_qs,
      pages   => $Msgs->{TOTAL},
      ID      => 'MSGS_LIST',
      header  => $status_bar,
    });

    foreach my $line (@$list) {
      $table->{rowcolor} = ($FORM{ID} && $line->{id} == $FORM{ID}) ? 'row_active' : undef;
      $line->{subject} = convert($line->{subject}, { text2html => 1, json => $FORM{json} });

      $table->addrow(
        $line->{id},
        ($line->{user_read} ne '0000-00-00 00:00:00')
        ? $html->button((($line->{subject}) ? "$line->{subject}" : $lang{NO_SUBJECT}), "index=$index&ID=$line->{id}&sid=$sid#last_msg")
        : $html->button($html->b((($line->{subject}) ? "$line->{subject}" : $lang{NO_SUBJECT})), "index=$index&ID=$line->{id}&sid=$sid#last_msg"),
        $line->{datetime},
        $html->color_mark($msgs_status->{ $line->{state} }),
        $html->button($lang{SHOW}, "index=$index&ID=$line->{id}&sid=$sid", { class => 'show' })
      );
    }
  }

  print $table->show();

  $Msgs->{TOTAL_MSG} = $Msgs->{TOTAL};
  #my %SHOW_PARAMS = (ADMIN_READ => '0000-00-00 00:00:00',);

  $table = $html->table(
    {
      width      => '100%',
      rows       => [
        [
          "$lang{TOTAL}:  " . $html->b( $Msgs->{TOTAL_MSG} ),
          #$html->color_mark( "$lang{IN_WORK}:  " . $html->b( $Msgs->{IN_WORK} ), $msgs_status_colors[3] ),
          "$lang{OPEN}: " . $html->b( $Msgs->{OPEN} ),
          #$html->color_mark( "$lang{CLOSED_UNSUCCESSFUL}:  " . $html->b( $Msgs->{UNMAKED} ), $msgs_status_colors[1] ),
          #$html->color_mark( "$lang{CLOSED_SUCCESSFUL}:  " . $html->b( $Msgs->{CLOSED} ), $msgs_status_colors[2] ),
        ]
      ],
      rowcolor => 'total'
    }
  );
  print $table->show();

  delete $LIST_PARAMS{SORT};

  show_user_chat();

  return 1;
}
#**********************************************************
=head2 show_user_chat() - Shows chat at the user side

  Arguments:

  Returns:
    true
=cut
#**********************************************************
sub show_user_chat {
  require Msgs::Tickets;
  if ($FORM{ADD}) {
    msgs_chat_add();
    return 1;
  }
  if ($FORM{SHOW}) {
    msgs_chat_show();
    return 1;
  }
  if ($FORM{COUNT}) {
    my $count = $Msgs->chat_count({ Msg_ID => $FORM{MSG_ID}, SENDER => 'uid' });
    print $count;
    return 1;
  }
  if ($FORM{CHANGE}) {
    $Msgs->chat_change({ Msg_ID => $FORM{MSG_ID}, SENDER => 'uid'});
    return 1;
  }
  if ($FORM{INFO}) {
    header_online_chat({UID => $FORM{UID}});
    return 1;
  }
  if ($FORM{US_MS_LIST}) {
    header_online_chat({US_MS_LIST => $FORM{US_MS_LIST}});
    return 1;
  }
  if ($FORM{ID} && $conf{MSGS_CHAT}) {
    my $fn_index = get_function_index('show_user_chat');
    $html->tpl_show(_include('msgs_user_chat', 'Msgs'), {
      F_INDEX  => $fn_index,
      UID      => $user->{UID},
      NUM_TICKET  => $Msgs->{ID}
    });
  }
  return 1;
}
#**********************************************************
=head2 msgs_user_search_table() - Create table with find msgs

  Arguments:
    $attr -
      SEARCH_TEXT - Search word
      TOTAL_MSGS -  Total msgs
      STATUS_BAR -  Table status bar
    msgs_status  = hash reff with messages status
    list         = list of messages

  Returns:  HTML Table

  Examples:
=cut
#**********************************************************
sub msgs_user_search_table {
my ($attr, $msgs_status, $list) = @_;

  my $function_index = get_function_index('msgs_user') || $attr->{INDEX};

  my $table = $html->table(
      {
        width       => '100%',
        caption     => $lang{MESSAGES},
        title_plain => [ '#', $lang{SUBJECT}, $lang{MESSAGE}, $lang{DATE}, $lang{STATUS}, '-' ],
        qs          => $pages_qs . "SEARCH_MSG_TEXT=$FORM{SEARCH_MSG_TEXT}",
        pages       => $attr->{TOTAL_MSGS},
        ID          => 'MSGS_LIST_SEARCH',
        header      => $attr->{STATUS_BAR}
      }
    );

    foreach my $line (@$list) {
      $table->{rowcolor} = ($attr->{ID} && $line->{id} == $attr->{ID}) ? 'row_active' : undef;

      #Add color to search word In Subject, messegas, reply
      my $subject_color = _add_color_search($attr->{SEARCH_TEXT}, $line->{subject} );
      my ($text_color, $have_word_in_text)    = _add_color_search($attr->{SEARCH_TEXT}, $line->{message}, {SLICE => 1} );
      my ($reply_color, $have_word_in_reply)  = _add_color_search($attr->{SEARCH_TEXT}, $line->{reply_text}, {SLICE => 1} );

      #Watch if we have word in text if not add standart text
      my $resul_text = $have_word_in_text ? $text_color :  $have_word_in_reply ? $reply_color :  $text_color;

      $table->addrow(
        $line->{id},
        ($line->{user_read} ne '0000-00-00 00:00:00')
        ? $html->button((( $subject_color) ? " $subject_color" : $lang{NO_SUBJECT}), "index=$function_index&ID=$line->{id}&sid=$sid#last_msg")
        : $html->button($html->b((( $subject_color) ? " $subject_color" : $lang{NO_SUBJECT})), "index=$function_index&ID=$line->{id}&sid=$sid#last_msg"),
        $resul_text,
        $line->{datetime},
        $html->color_mark($msgs_status->{ $line->{state} }),
        $html->button($lang{SHOW}, "index=$function_index&ID=$line->{id}&sid=$sid", { class => 'show' })
      );
    }

  return $table;
}

#**********************************************************
=head2 _add_color_search() - Add color to search word in text

  Arguments:
    $attr -
      SLICE - Slice text 80  or 95 if no search word
  Returns: format_text(String), Find word(Bool: 1 or 0)

  Examples:
=cut
#**********************************************************
sub _add_color_search {
  my ($word, $full_text, $attr) = @_;

  if($word && $full_text){

    #Turn off special characters for regexp
    my $quote_word = quotemeta($word);

    #my $word_with_color;
    #If we didnt want full text. Slice
    if($attr->{SLICE}){

      #Slice and search word
      my ($result_text) = $full_text =~ m/.{0,40}$quote_word.{0,40}/gi;

      #If see search word add color else onle slice
      if($result_text){

        #Add color
        $result_text =~ s/($quote_word)/<span style='background:yellow'>$1<\/span>/gi;

        return $result_text, 1;
      }
      else{
        ($result_text) = $full_text =~ m/.{0,95}/g;
        return $result_text, 0;
      }
    }

    #If see search word add color
    $full_text =~ s/($quote_word)/<span style='background:yellow'>$1<\/span>/gi;

    return $full_text;
  }
  else{
    return '';
  }
}

#**********************************************************
=head2 _user_edit_reply() 

=cut
#**********************************************************
sub _user_edit_reply {
  return 1 unless ( $FORM{edit_reply} );

  my $list = $Msgs->messages_reply_list({
    ID         => $FORM{edit_reply},
    DATETIME   => '_SHOW',
    CREATOR_ID => '_SHOW',
    COLS_NAME  => 1
  });

  return 1 unless ($list->[0]->{creator_id} eq $user->{LOGIN});
  my $n = gmtime() + 3600 * 3;
  my $d = Time::Piece->strptime($list->[0]->{datetime}, "%Y-%m-%d %H:%M:%S");
  if (($n-$d)/60 < 5) {
    $Msgs->message_reply_change({
      ID    => $FORM{edit_reply},
      TEXT  => $FORM{replyText}
    });
  };
  return 1;
}

1;