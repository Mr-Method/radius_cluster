=head1 NAME

 Msgs configure interface

=cut

use strict;
use warnings FATAL => 'all';

our(
  $db,
  %conf,
  $html,
  %lang,
  @bool_vals,
  $admin
);

my $Msgs = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_admins() -  Message  system admins

=cut
#**********************************************************
sub msgs_admins {
  my @privilages_arr = ('READ', 'WRITE', 'ADD', 'ALL');

  if ($FORM{change}) {
    $Msgs->admin_change({%FORM});
    if (!$Msgs->{errno}) {
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );
    }
  }
  elsif ($FORM{chg}) {
    my $a_list = $Msgs->admins_list({ AID => $FORM{AID} });
    my %A_PRIVILEGES = ();
    my %A_MAIL_SEND = ();
    my %A_DELIGATION_LEVEL = ();

    foreach my $line (@$a_list) {
      $A_PRIVILEGES{ $line->[5] } = $line->[2];
      $A_DELIGATION_LEVEL{ $line->[5] } = $line->[3];
      $A_MAIL_SEND{ $line->[5] } = $line->[6];
      $Msgs->{ADMIN} = $line->[0];
    }

    if (!$Msgs->{errno}) {
      $html->message( 'info', $lang{INFO}, "$lang{CHANGE}" );
    }

    my $list = $Msgs->chapters_list({ AID => $FORM{AID} });
    my $table = $html->table(
      {
        width      => '100%',
        title      => [ 'ID', $lang{CHAPTERS}, $lang{ACCESS}, 'E-mail', $lang{PRIORITY} ],
        ID         => 'ADMIN_ACCESS'
      }
    );

    my @DELIGATION_LEVEL_ARR = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

    foreach my $line (@$list) {
      my $privileges = $html->form_select(
        'PRIORITY_' . $line->[0],
        {
          SELECTED      => ($A_PRIVILEGES{ $line->[0] }) ? $A_PRIVILEGES{ $line->[0] } : 0,
          SEL_ARRAY     => \@privilages_arr,
          NORMAL_WIDTH  => 1,
          ARRAY_NUM_ID  => 1
        }
      );

      my $deligation_level = $html->form_select(
        'DELIGATION_LEVEL_' . $line->[0],
        {
          SELECTED     => ($A_DELIGATION_LEVEL{ $line->[0] }) ? $A_DELIGATION_LEVEL{ $line->[0] } : 0,
          ,
          NORMAL_WIDTH => 1,
          SEL_ARRAY    => \@DELIGATION_LEVEL_ARR,
          ARRAY_NUM_ID => 1
        }
      );

      $table->addrow(
        $line->[0]
          . $html->form_input(
          'IDS',
          "$line->[0]",
          {
            TYPE  => 'checkbox',
            STATE => (defined($A_PRIVILEGES{ $line->[0] })) ? 1 : undef
          }
        ),
        $line->[1],
        $privileges,
        $html->form_input(
          'EMAIL_NOTIFY_' . $line->[0],
          1,
          {
            TYPE  => 'checkbox',
            STATE => ($A_MAIL_SEND{ $line->[0] }) ? 1 : undef
          }
        ),
        $deligation_level,
      );
    }

    $Msgs->{CHAPTERS} = $table->show();
    $html->tpl_show(_include('msgs_admin', 'Msgs'), $Msgs);
  }

  _error_show($Msgs);

  my $list = $Msgs->admins_list({ %LIST_PARAMS, COLS_NAME => 1 });
  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{ADMINS},
      title      => [ $lang{ADMIN}, $lang{CHAPTERS}, $lang{PERMISSION}, $lang{MESSAGES}, 'E-mail', $lang{PRIORITY}, "-" ],
      qs         => $pages_qs,
      ID         => 'MSGS_ADMINS'
    }
  );

  my %A_PRIVILEGES = ();
  foreach my $line (@$list) {
    $line->{chapter_name} = $line->{chapter_name} || '';
    $line->{priority} = $line->{priority} || '';
    $line->{deligation_level} = $line->{deligation_level} || '';
    $line->{aid} = $line->{aid} || '';
    $line->{chapter_id} = $line->{chapter_id} || '';
    $line->{email_notify} = $line->{email_notify} || '';
    $line->{email} = $line->{email} || '';

    push @{ $A_PRIVILEGES{ $line->{admin_login} } }, "$line->{chapter_name}|$line->{priority}|$line->{deligation_level}|$line->{aid}|$line->{chapter_id}|$line->{email_notify}|$line->{email}";
  }
  my $msgs;
  foreach my $admin_id (sort keys %A_PRIVILEGES) {
    my $rows = $#{ $A_PRIVILEGES{$admin_id} } || 0;
    my @arr = @{ $A_PRIVILEGES{$admin_id} };
    my ($chapter_name, $privilege, $deligation_level, $aid, $chapter_id, $mail_send, $priority_level) = split(/\|/, $arr[0]);
    $table->{rowcolor} = ($FORM{chg} && $FORM{chg} eq $aid) ? $table->{rowcolor} = 'bg-success' : undef;

    $table->addtd(
      $table->td($admin_id, { rowspan => ($rows > 0) ? $rows + 1 : 1 }),
      $table->td($chapter_name),
      $table->td( ($rows == 0) ? $lang{ALL} : $privilages_arr[$privilege || 0] ),
      $table->td($msgs),
      $table->td($bool_vals[$mail_send || 0]),
      $table->td($deligation_level),
      $table->td( $html->button( $lang{CHANGE}, "index=$index&chg=$aid&AID=$aid", { class => 'change' } ),
        { rowspan => (($rows > 0) ? $rows + 1 : 1) } )
    );

    if ($rows > 0) {
      for (my $i = 1; $i <= $rows; $i++) {
        ($chapter_name, $privilege, $deligation_level, $aid, $chapter_id, $mail_send, $priority_level) = split(/\|/, $arr[$i]);
        $table->addrow($chapter_name,
          $privilages_arr[$privilege || 0],
          $msgs,
          $bool_vals[($mail_send || 0)],
          $deligation_level);
      }
    }
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 msgs_progress_bar()

=cut
#**********************************************************
sub msgs_progress_bar {

  $Msgs->{ACTION} = 'add';
  $Msgs->{LNG_ACTION} = $lang{ADD};
  $LIST_PARAMS{CHAPTER_ID} = $FORM{PROGRES_BAR};
  $FORM{CHAPTER_ID} = $FORM{PROGRES_BAR};
  $pages_qs .= "&PROGRES_BAR=$FORM{CHAPTER_ID}"if($FORM{CHAPTER_ID});

  $FORM{USER_NOTICE}          = $FORM{USER_NOTICE}        ? 1:0;
  $FORM{RESPONSIBLE_NOTICE}   = $FORM{RESPONSIBLE_NOTICE} ? 1:0;
  $FORM{FOLLOWER_NOTICE}      = $FORM{FOLLOWER_NOTICE}    ? 1:0;

  $Msgs->{USER_NOTICE}        = $FORM{USER_NOTICE}        ? 'checked':'';
  $Msgs->{RESPONSIBLE_NOTICE} = $FORM{RESPONSIBLE_NOTICE} ? 'checked':'';
  $Msgs->{FOLLOWER_NOTICE}    = $FORM{FOLLOWER_NOTICE}    ? 'checked':'';

  if ($FORM{add}) {
    $Msgs->pb_add({%FORM});
    $html->message( 'info', $lang{INFO}, "$lang{ADDED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{change}) {
    $Msgs->pb_change({%FORM});
    $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{chg}) {
    $Msgs->pb_info($FORM{chg});

    $Msgs->{USER_NOTICE}        = $Msgs->{USER_NOTICE}        ? 'checked':'';
    $Msgs->{RESPONSIBLE_NOTICE} = $Msgs->{RESPONSIBLE_NOTICE} ? 'checked':'';
    $Msgs->{FOLLOWER_NOTICE}    = $Msgs->{FOLLOWER_NOTICE}    ? 'checked':'';

    $FORM{add_form} = 1;
    if (!$Msgs->{errno}) {
      $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" ) if (!$Msgs->{errno});
      $Msgs->{ACTION} = 'change';
      $Msgs->{LNG_ACTION} = $lang{CHANGE};
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Msgs->pb_del({ ID => $FORM{del} });
    $html->message( 'info', $lang{INFO}, "$lang{DELETED}" ) if (!$Msgs->{errno});
  }

  _error_show($Msgs);
  $html->tpl_show(_include('msgs_pb', 'Msgs'), $Msgs);

  result_former(
    {
      INPUT_DATA      => $Msgs,
      FUNCTION        => 'pb_list',
      BASE_FIELDS     => 3,
      DEFAULT_FIELDS  => 'STEP_NUM,STEP_NAME,STEP_TIPS',
      FUNCTION_FIELDS => 'change,del',
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        'step_num'  => $lang{NUM},
        'step_name' => $lang{NAME},
        'step_tip'  => $lang{TIPS},
      },
      TABLE => {
        width   => '100%',
        caption => "$lang{PROGRESS_BAR}",
        qs      => $pages_qs,
        ID      => 'PROGRESS_BAR_LIST',
        EXPORT  => 1,
      },
      MAKE_ROWS => 1,
      TOTAL     => 1
    }
  );

  return 1;
}


#**********************************************************
=head2 msgs_chapters()

=cut
#**********************************************************
sub msgs_chapters {
  $Msgs->{ACTION} = 'add';
  $Msgs->{LNG_ACTION} = $lang{ADD};

  if ($FORM{PROGRES_BAR}) {
    msgs_progress_bar();
    return 1;
  }
  elsif ($FORM{add}) {
    $Msgs->chapter_add({%FORM});

    $html->message( 'info', $lang{INFO}, "$lang{ADDED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{change}) {

    $Msgs->chapter_change({%FORM});

    $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{chg}) {
    $Msgs->chapter_info($FORM{chg});
    $FORM{add_form} = 1;
    if (!$Msgs->{errno}) {
      $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" ) if (!$Msgs->{errno});
      $Msgs->{ACTION} = 'change';
      $Msgs->{LNG_ACTION} = $lang{CHANGE};
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Msgs->chapter_del({ ID => $FORM{del} });

    $html->message( 'info', $lang{INFO}, "$lang{DELETED}" ) if (!$Msgs->{errno});
  }

  _error_show($Msgs);

  if ($FORM{add_form}) {
    $Msgs->{RESPONSIBLE_SEL} = sel_admins(
      {
        NORMAL_WIDTH => 1,
        NAME         => 'RESPONSIBLE',
        RESPONSIBLE   => $Msgs->{RESPONSIBLE}?$Msgs->{RESPONSIBLE}:''
      }
    );
    $Msgs->{INNER_CHAPTER} = ($Msgs->{INNER_CHAPTER}) ? '  checked' : '';
    $html->tpl_show(_include('msgs_chapter', 'Msgs'), $Msgs);
  }

  my $list = $Msgs->chapters_list(
    {
      %LIST_PARAMS,
      MSG_COUNTS => '_SHOW',
      COLS_NAME  => 1
    }
  );

  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{CHAPTERS},
      title      => [ '#', $lang{NAME}, $lang{PRIVATE}, $lang{MESSAGES}, $lang{RESPOSIBLE}, $lang{AUTO_CLOSE}, "-", "-" ],
      qs         => $pages_qs,
      MENU       => "$lang{ADD}:add_form=1&index=$index:add",
      ID         => 'MSGS_CHAPTERS'
    }
  );

  foreach my $line (@$list) {
    $table->{rowcolor} = ($FORM{chg} && $FORM{chg} eq $line->{id}) ? $table->{rowcolor} = 'bg-success' : undef;
  
    $line->{id} //= 0;
    $line->{name} //= '';
    $line->{inner_chapter} //= 0;
    $line->{msg_counts} //= 0;
  
    $table->addrow(
      $line->{id},
      $line->{name},
        defined($line->{inner_chapter}) ? $bool_vals[ $line->{inner_chapter} ] : '',
      $html->button($line->{msg_counts}, "index=". get_function_index('msgs_admin')."&CHAPTER=$line->{id}&ALL_MSGS=1"),
      $line->{admin_login} || '',
      $line->{autoclose},
      $html->button( "$lang{PROGRESS_BAR}", "index=$index&PROGRES_BAR=$line->{id}",
        { TITLE => $lang{PROGRESS_BAR}, ICON => 'glyphicon glyphicon-tasks' } ),
      $html->button( "$lang{CHANGE}", "index=$index&chg=$line->{id}", { class => 'change' } ),
      $html->button( $lang{DEL}, "index=$index&del=$line->{id}",
        { MESSAGE => "$lang{DEL} $line->{id}?", class => 'del' } )
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 msgs_dispatch_category()

=cut
#**********************************************************
sub msgs_dispatch_category {
  #my %info;

  if($FORM{add_form}){
    $Msgs->{ACTION} = 'added';
    $Msgs->{ACTION_LNG} = $lang{ADD};

    $html->message( 'info', $lang{INFO}, "$lang{ADD}" );

    $html->tpl_show(_include('msgs_dispatch_category','Msgs'), { %$Msgs });
  }
  elsif($FORM{added}){
    $Msgs->dispatch_category_add({%FORM});

    if(!$Msgs->{errno}){
      $html->message( 'info', $lang{INFO}, "$lang{ADDED}" );
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }
  elsif($FORM{del}){
    $Msgs->dispatch_category_del({ID => $FORM{del}});

    if(!$Msgs->{errno}){
      $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }
  elsif($FORM{chg}){
    $Msgs->dispatch_category_info($FORM{chg});

    if (!$Msgs->{errno}) {
      $Msgs->{ACTION} = 'change';
      $Msgs->{ACTION_LNG} = $lang{CHANGE};

      $html->message( 'info', $lang{INFO}, "$lang{CHANGE}" );

      $html->tpl_show(_include('msgs_dispatch_category','Msgs'), { %$Msgs });
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }
  elsif($FORM{change}){
    $Msgs->dispatch_category_change({%FORM});

    if(!$Msgs->{errno}){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" ) if (!$Msgs->{errno});
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }

  result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'dispatch_category_list',
    DEFAULT_FIELDS  => 'ID,NAME',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => "$lang{DISPACTH_CATEGORY}",
      qs      => $pages_qs,
      ID      => 'DISPACTH_CATEGORY',
      MENU    => "$lang{ADD}:add_form=1&index=$index:add"
    },
    MAKE_ROWS => 1,
    TOTAL     => 1
  });

  return 1;
}

#**********************************************************
=head2 msgs_survey() - Msgs survey

=cut
#**********************************************************
sub msgs_survey {
  $Msgs->{ACTION} = 'add';
  $Msgs->{LNG_ACTION} = $lang{ADD};

  my $i = 1;
  if ($FORM{ 'FILE_UPLOAD_' . $i }{filename}) {
    $FORM{FILENAME}          = $FORM{ 'FILE_UPLOAD_' . $i }{filename};
    $FORM{FILE_CONTENT_TYPE} = $FORM{ 'FILE_UPLOAD_' . $i }{'Content-Type'};
    $FORM{FILE_SIZE}         = $FORM{ 'FILE_UPLOAD_' . $i }{Size};
    $FORM{FILE_CONTENTS}     = $FORM{ 'FILE_UPLOAD_' . $i }{Contents};
  }

  if ($FORM{SURVEY_ID}) {
    msgs_survey_questions();
    return 0;
  }
  elsif ($FORM{add}) {
    $Msgs->survey_subject_add({%FORM});
    $html->message( 'info', $lang{INFO}, "$lang{ADDED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{change}) {
    $Msgs->survey_subject_change({%FORM});

    $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{chg}) {
    $Msgs->survey_subject_info($FORM{chg});

#    if($FORM{ajax}){
#      print "$Msgs->{TPL}";
#      return 1;
#    }

    $Msgs->{ACTION} = 'change';
    $Msgs->{LNG_ACTION} = $lang{CHANGE};
    $FORM{add_form} = 1;

    $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Msgs->survey_subject_del({ ID => $FORM{del} });

    $html->message( 'info', $lang{INFO}, "$lang{DELETED}" ) if (!$Msgs->{errno});
  }

  _error_show($Msgs);

  my %status_hash = (
    0 => $lang{ENABLE},
    1 => $lang{DISABLE}
  );

  if ($FORM{add_form}) {
    $Msgs->{STATUS_SEL} = $html->form_select(
      'STATUS',
      {
        SELECTED  => $Msgs->{STATUS} || 0,
        SEL_HASH  => \%status_hash,
        NO_ID     => 1
      }
    );
    if($Msgs->{TPL}) {
      $Msgs->{TPL} =~ s/\%/\&#37/g;
    }
    $html->tpl_show(_include('msgs_survey_subject', 'Msgs'), $Msgs);
  }

  result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'survey_subjects_list',
    BASE_FIELDS     => 2,
    DEFAULT_FIELDS  => 'ID,NAME,COMMENTS,STATUS,ADMIN_NAME,CREATED',
    FUNCTION_FIELDS => 'msgs_survey:$lang{QUESTIONS}:survey_id,change,del',
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
      comments   => $lang{COMMENTS},
      tpl        => $lang{TEMLATE},
      status     => $lang{STATUS},
      admin_name => $lang{ADMIN},
      created    => $lang{CREATED},
    },
    SKIP_USER_TITLE => 1,
    SELECT_VALUE    => { status => \%status_hash, },
    FILTER_COLS     => { users_count => 'search_link:form_search:LOCATION_ID,type=11', },
    TABLE           => {
      width   => '100%',
      caption => "$lang{SURVEY}",
      qs      => $pages_qs,
      ID      => 'SURVEY_LIST',
      MENU    => "$lang{ADD}:add_form=1&index=$index:add"
    },
    MAKE_ROWS => 1,
    TOTAL     => 1
  });

  return 1;
}

#**********************************************************
=head2 msgs_status() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub msgs_status {
  #my ($attr) = @_;

  my %task_closed = (0 => $lang{NO}, 1 => $lang{YES});

  $Msgs->{ACTION} = 'add';
  $Msgs->{ACTION_LNG} = $lang{ADD};

  if($FORM{add}){
    $Msgs->status_add({%FORM,
      TASK_CLOSED => ($FORM{TASK_CLOSED} && $FORM{TASK_CLOSED} eq 'on') ? 1 : 0});

    if(!$Msgs->{errno}){
      $html->message('success', $lang{INFO}, $lang{ADDED});
    }
  }
  elsif($FORM{change}){
    $Msgs->status_change({%FORM,
      TASK_CLOSED => ($FORM{TASK_CLOSED} && $FORM{TASK_CLOSED} eq 'on') ? 1 : 0});

    if(!$Msgs->{errno}){
      $html->message('success', $lang{INFO}, $lang{CHANGED});
    }
  }
  elsif($FORM{chg}){
    $Msgs->{ACTION}   = 'change';
    $Msgs->{ACTION_LNG} = $lang{CHANGE};
    $Msgs->status_info($FORM{chg});
    $Msgs->{CHECKED}  = 'checked' if ($Msgs->{TASK_CLOSED});
  }
  elsif($FORM{del} && $FORM{del} =~ /\d+/ && $FORM{COMMENTS}){
    $Msgs->status_del({ID => $FORM{del}});

    if(!$Msgs->{errno}){
      $html->message('success', $lang{INFO}, $lang{DELETED});
    }
  }

  _error_show($Msgs);

  $html->tpl_show(_include('msgs_status', 'Msgs'), $Msgs);

  result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'status_list',

    DEFAULT_FIELDS  => 'ID,NAME,READINESS,TASK_CLOSED,COLOR,ICON',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      id          => '#',
      name        => $lang{NAME},
      readiness   => "$lang{READINESS}, %",
      task_closed => $lang{TASK_CLOSED},
      color       => $lang{COLOR},
      icon        => $lang{ICON},
    },
    SKIP_USER_TITLE => 1,
    SELECT_VALUE    => { task_closed => \%task_closed, },
    FILTER_COLS  => {
      name => '_translate',
      icon => '_msgs_get_icon:ICON'
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{STATUS}",
      qs      => $pages_qs,
      ID      => 'STATUS_LIST',
      MENU    => ""
    },
    MAKE_ROWS => 1,
    TOTAL     => 1
  });

  return 1;
}

#**********************************************************
=head2 msgs_quick_replys_types()

=cut
#**********************************************************
sub msgs_quick_replys_types {

  if($FORM{add_form}){
    $Msgs->{ACTION} = 'added';
    $Msgs->{ACTION_LNG} = $lang{ADD};

    $html->message( 'info', $lang{INFO}, "$lang{ADD}" );

    $html->tpl_show(_include('msgs_quick_replys_types','Msgs'), { %$Msgs });
  }
  elsif($FORM{added}){
    $Msgs->messages_quick_replys_types_add({%FORM});

    if(!$Msgs->{errno}){
      $html->message( 'info', $lang{INFO}, "$lang{ADDED}" );
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }
  elsif($FORM{del}){
    $Msgs->messages_quick_replys_types_del({ID => $FORM{del}});

    if(!$Msgs->{errno}){
      $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }
  elsif($FORM{chg}){
    $Msgs->messages_quick_replys_types_info($FORM{chg});

    if (!$Msgs->{errno}) {
      $Msgs->{ACTION} = 'change';
      $Msgs->{ACTION_LNG} = $lang{CHANGE};

      $html->message( 'info', $lang{INFO}, "$lang{CHANGE}" );

      $html->tpl_show(_include('msgs_quick_replys_types','Msgs'), { %$Msgs });
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }
  elsif($FORM{change}){
    $Msgs->messages_quick_replys_types_change({%FORM});

    if(!$Msgs->{errno}){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" ) if (!$Msgs->{errno});
    }
    else{
      $html->message( 'err', $lang{ERROR}, $Msgs->{errno} );
    }
  }

  result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'messages_quick_replys_types_list',
    DEFAULT_FIELDS  => 'ID,NAME',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => "$lang{MSGS_TAGS_TYPES}",
      qs      => $pages_qs,
      ID      => 'QUICK_REPLYS_TYPES',
      MENU    => "$lang{ADD}:add_form=1&index=$index:add"
    },
    MAKE_ROWS => 1,
    TOTAL     => 1
  });

  return 1;
}

#**********************************************************
=head2 msgs_survey_questions()

=cut
#**********************************************************
sub msgs_survey_questions {
  $Msgs->{ACTION} = 'add';
  $Msgs->{LNG_ACTION} = $lang{ADD};
  $Msgs->{FILL_DEFAULT} = 1;

  if ($FORM{add}) {
    $Msgs->survey_question_add({%FORM});
    $html->message( 'info', $lang{INFO}, "$lang{ADDED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{change}) {
    $Msgs->survey_question_change({%FORM});
    $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{chg}) {
    $Msgs->survey_question_info($FORM{chg});

    $Msgs->{ACTION} = 'change';
    $Msgs->{LNG_ACTION} = $lang{CHANGE};

    $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" ) if (!$Msgs->{errno});
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Msgs->survey_question_del({ ID => $FORM{del} });

    $html->message( 'info', $lang{INFO}, "$lang{DELETED}" ) if (!$Msgs->{errno});
  }

  _error_show($Msgs);

  $Msgs->{USER_COMMENTS} = ($Msgs->{USER_COMMENTS}) ? 'checked' : '';
  $Msgs->{FILL_DEFAULT} = ($Msgs->{FILL_DEFAULT})  ? 'checked' : '';

  $html->tpl_show(_include('msgs_survey_question', 'Msgs'), $Msgs);
  my $list = $Msgs->survey_questions_list(
    {
      SURVEY_ID => $FORM{SURVEY_ID},
      %LIST_PARAMS,
      COLS_NAME => 1
    }
  );

  my $table = $html->table({
    width       => '100%',
    caption     => "$lang{SURVEY}",
    title_plain => [ '#', $lang{QUESTION}, $lang{PARAMS}, $lang{COMMENTS}, "$lang{USER} $lang{COMMENTS}", $lang{DEFAULT}, '-',
      '-' ],
    qs         => $pages_qs,
  });

  foreach my $line (@$list) {
    my $params =
        ($line->{params})
      ? $html->form_select(
        'PARAMS_' . $line->{num},
        {
          SELECTED     => '',
          SEL_ARRAY    => [ split(/;/, $line->{params}) ],
          ARRAY_NUM_ID => 1
        }
      )
      : '';
    $table->addrow(
      $line->{num}, $line->{question}, $line->{comments}, $params,
        ($line->{user_comments}) ? $html->form_input('USER_COMMENTS', '') : '',
      $bool_vals[ $line->{fill_default} ],
      $html->button( "$lang{CHANGE}", "index=$index&chg=$line->{id}&SURVEY_ID=$FORM{SURVEY_ID}", { class => 'change' } )
      ,
      $html->button( $lang{DEL}, "index=$index&del=$line->{id}&SURVEY_ID=$FORM{SURVEY_ID}",
        { MESSAGE => "$lang{DEL}  $line->{num}?", class => 'del' })
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 msgs_quick_replys()

=cut
#**********************************************************
sub msgs_quick_replys {

  if ( $FORM{add_form} ) {
    $Msgs->{ACTION} = 'added';
    $Msgs->{ACTION_LNG} = $lang{ADD};

    $Msgs->{QUICK_REPLYS_CATEGORY} = $html->form_select(
      'TYPE_ID',
      {
        SEL_LIST => $Msgs->messages_quick_replys_types_list({ COLS_NAME => 1 }),
        NO_ID    => 1,
        REQUIRED => 1,
      }
    );

    $html->message('info', $lang{INFO}, "$lang{ADD}");

    $html->tpl_show(_include('msgs_quick_replys', 'Msgs'), { %{$Msgs} });
  }
  elsif ( $FORM{added} ) {
    $Msgs->messages_quick_replys_add({ %FORM });

    if ( !$Msgs->{errno} ) {
      $html->message('info', $lang{INFO}, "$lang{ADDED}");
    }
    else {
      $html->message('err', $lang{ERROR}, $Msgs->{errno});
    }
  }
  elsif ( $FORM{del} ) {
    $Msgs->messages_quick_replys_del({ ID => $FORM{del} });

    if ( !$Msgs->{errno} ) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
    else {
      $html->message('err', $lang{ERROR}, $Msgs->{errno});
    }
  }
  elsif ( $FORM{chg} ) {
    $Msgs->messages_quick_replys_info($FORM{chg});

    $Msgs->{QUICK_REPLYS_CATEGORY} = $html->form_select(
      'TYPE_ID',
      {
        SELECTED => $Msgs->{TYPE_ID} ? $Msgs->{TYPE_ID} : 1,
        SEL_LIST => $Msgs->messages_quick_replys_types_list({ COLS_NAME => 1 }),
        NO_ID    => 1,
        REQUIRED => 1,
      }
    );

    if ( !$Msgs->{errno} ) {
      $Msgs->{ACTION} = 'change';
      $Msgs->{ACTION_LNG} = $lang{CHANGE};

      $html->message('info', $lang{INFO}, "$lang{CHANGE}");

      $html->tpl_show(_include('msgs_quick_replys', 'Msgs'), { %{$Msgs} });
    }
    else {
      $html->message('err', $lang{ERROR}, $Msgs->{errno});
    }
  }
  elsif ( $FORM{change} ) {
    $Msgs->messages_quick_replys_change({ %FORM });

    if ( !$Msgs->{errno} ) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}") if ( !$Msgs->{errno} );
    }
    else {
      $html->message('err', $lang{ERROR}, $Msgs->{errno});
    }
  }

  result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'messages_quick_replys_list',
    DEFAULT_FIELDS  => 'ID,REPLY,TYPE,COLOR,',
    HIDDEN_FIELDS   => 'TYPE_ID',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      id      => '#',
      reply   => $lang{TAGS},
      type_id => "$lang{TYPE} ID",
      type    => $lang{TYPE},
      color   => $lang{COLOR},
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => "$lang{MSGS_TAGS}",
      qs      => $pages_qs,
      ID      => 'QUICK_REPLYS',
      MENU    => "$lang{ADD}:add_form=1&index=$index:add"
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}


1;