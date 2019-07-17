=head1 Delivery_Msgs

  TV services

=cut

use strict;
use warnings FATAL => 'all';

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

my $Msgs  = Msgs->new($db, $admin, \%conf);

my @priority = ($lang{VERY_LOW}, $lang{LOW}, $lang{NORMAL}, $lang{HIGH}, $lang{VERY_HIGH});

$_COLORS[6] //= 'red';
$_COLORS[8] //= '#FFFFFF';
$_COLORS[9] //= '#FFFFFF';

my @priority_colors    = ('#8A8A8A', $_COLORS[8], $_COLORS[9], '#E06161', $_COLORS[6]);
#**********************************************************
=head2 msgs_delivery_main()

  Arguments:
  Returns:

=cut
#**********************************************************
sub msgs_delivery_main {
  my $msgs_status  = msgs_sel_status({ HASH_RESULT => 1 });
  my @send_methods = ($lang{MESSAGE},'E-MAIL');

  if(in_array('Sms', \@MODULES)) {
      $Msgs->{EXTRA_PARAMS} = '';
      $send_methods[2]      = "$lang{SEND} SMS";
  }
  if($conf{MSGS_REDIRECT_FILTER_ADD}) {
      $send_methods[3]      = 'Web  redirect';
  }

  if($FORM{add_form}){
    $FORM{STATUS}            = 1;
    $Msgs->{ACTION}          = 'add';
    $Msgs->{ACTION_LNG}      = $lang{ADD};
  }
  elsif($FORM{add}){
    $Msgs->msgs_delivery_add({%FORM});

    if(!$Msgs->{errno}){
      $html->message('success', $lang{INFO}, $lang{MESSAGE}  . ' ' .  $lang{ADDED});
    }
  }
  elsif($FORM{del_delivery}){
    $Msgs->msgs_delivery_del({ID => $FORM{del_delivery}});

    if(!$Msgs->{errno}){
      $html->message('success', $lang{INFO}, $lang{MESSAGE}  . ' ' . $FORM{del_delivery} . ' '. $lang{DELETED});
    }
  }
  elsif($FORM{chg}){
    $Msgs->{ACTION}   = 'change';
    $Msgs->{ACTION_LNG} = $lang{CHANGE};
    $Msgs->msgs_delivery_info($FORM{chg});
    $FORM{STATUS} = $Msgs->{STATUS};
  }
  elsif($FORM{show}){
    $Msgs->{DISABLE}    = 'disabled';
    $Msgs->{ACTION}     = 'back';
    $Msgs->{ACTION_LNG} = $lang{BACK};
    $Msgs->msgs_delivery_info($FORM{show});
    $FORM{STATUS} = $Msgs->{STATUS};
  }
  elsif($FORM{change}){
    $Msgs->msgs_delivery_change({%FORM});

    if(!$Msgs->{errno}){
      $html->message('success', $lang{INFO}, $lang{MESSAGE}  . ' ' . $lang{CHANGED});
    }
  }

  if($FORM{add_form} || $FORM{chg} || $FORM{show}){
    $Msgs->{DATE_PIKER}      = $html->form_datepicker('SEND_DATE',$Msgs->{SEND_DATE});
    $Msgs->{TIME_PIKER}      = $html->form_timepicker('SEND_TIME',$Msgs->{SEND_TIME});
    $Msgs->{STATUS_SELECT}   = msgs_sel_status({ NAME => 'STATUS' });

    $Msgs->{PRIORITY_SELECT} = $html->form_select(
      'PRIORITY',
      {
        SELECTED     => defined($Msgs->{PRIORITY})?$Msgs->{PRIORITY}:2,
        SEL_ARRAY    => \@priority,
        STYLE        => \@priority_colors,
        ARRAY_NUM_ID => 1
      }
    );

    $Msgs->{SEND_METHOD_SELECT} = $html->form_select(
      'SEND_METHOD',
      {
        SELECTED     => defined($Msgs->{SEND_METHOD})?$Msgs->{SEND_METHOD}:2,
        SEL_ARRAY    => \@send_methods,
        ARRAY_NUM_ID => 1
      }
    );

    $html->tpl_show(_include('msgs_add_delivery', 'Msgs'), {%$Msgs});

    if($FORM{show}){
      if($FORM{IDS}){
        $Msgs->delivery_user_list_del({ ID => $FORM{IDS} });
        if (! _error_show($Msgs) ) {
          $html->message('info', $lang{DELETED}, "$lang{USERS} $FORM{IDS}");
        }
    }
      msgs_delivery_user_table({
        MDELIVERY_ID   => $FORM{show},
        FUNCTION_INDEX => $index,
        PAGE_QS        => "&show=$FORM{show}"
      });
    }
  }
  else{
    #Delivery table
    my ($table, $list) = result_former({
      INPUT_DATA      => $Msgs,
      FUNCTION        => 'msgs_delivery_list',
      DEFAULT_FIELDS  => 'ID, SEND_DATE, SEND_TIME, SUBJECT',
      FUNCTION_FIELDS => 'null',
      BASE_FIELDS     => 2,
      EXT_TITLES      => {
        id          => 'id',
        send_time   => $lang{SEND_TIME},
        send_date   => $lang{SEND_DATE},
        subject     => $lang{SUBJECT},
        text        => $lang{TEXT},
        send_method => $lang{MESSAGE},
        priority    => $lang{PRIORITY},
        status      => $lang{STATE},
        added       => $lang{ADDED},
        aid         => 'AID',
      },
      SKIP_USER_TITLE => 1,
      TABLE           => {
        width   => '100%',
        EXPORT   => 1,
        caption => "$lang{DELIVERY}",
        qs      => $pages_qs,
        ID      => 'DILIVERY_LIST',
        MENU    => "$lang{ADD}:add_form=1&index=$index:add"
      },
    });

    my $field_count = ($FORM{json}) ? $#{ $Msgs->{COL_NAMES_ARR} } : $Msgs->{SEARCH_FIELDS_COUNT};

    foreach my $line (@{$list}) {
      my @fields_array = ();
      for (my $i = 0; $i < $field_count+2; $i++) {
        my $val = '';
        my $field_name = $Msgs->{COL_NAMES_ARR}->[$i];
        if ($field_name eq 'send_method') {
          $val = @send_methods[$line->{send_method}];
        }
        elsif ($field_name eq 'priority') {
          $val = $html->color_mark($priority[ $line->{priority} ], $priority_colors[ $line->{priority} ]);
        }
        elsif ($field_name eq 'status') {
          $val = $html->color_mark($msgs_status->{ $line->{status} });
        }
        else {
          $val = $line->{ $field_name };
        }
        push @fields_array, $val;

      }
        push @fields_array,$html->button( $lang{SHOW},   "index=$index&show=$line->{id}",          { class => 'user'   }) .
                           $html->button( $lang{CHANGE}, "index=$index&chg=$line->{id}",           { class => 'change' }) .
                           $html->button( $lang{DELETE}, "index=$index&del_delivery=$line->{id}",  { class => 'del'    });
      $table->addrow(@fields_array);
  }
  print $html->form_main({
    CONTENT => $table->show({ OUTPUT2RETURN => 1  }),
    HIDDEN  => {
      index => $index,
    },
    NAME    => 'DILIVERY_LIST',
    ID      => 'DILIVERY_LIST',
  });

  my $total_dilivery = $Msgs->{TOTAL};

  $table = $html->table({
    width      => '100%',
    cols_align => [ 'right', 'right' ],
    rows       => [ [ "  $lang{TOTAL}: ",$html->b( $total_dilivery )] ]
  });

  print $table->show();
}
  return 1;
}

sub msgs_delivery_user_table {
  my ($attr) = @_;
  my @users_status = ($lang{WAIT_TO_SEND}, $lang{SENDED});

  my $user_list = $Msgs->delivery_user_list({
    MDELIVERY_ID   => $attr->{MDELIVERY_ID},
    PAGE_ROWS      => 1000000,
    COLS_NAME      => 1,
  });

  my ($user_table, $list) = result_former({
    INPUT_DATA      => $Msgs,
    LIST            => $user_list,
    DEFAULT_FIELDS  => 'LOGIN, FIO, EMAIL, STATUS ',
    FUNCTION_INDEX  => $attr->{FUNCTION_INDEX}//=0,
    HIDDEN_FIELDS   => 'UID,STATUS,',
     MULTISELECT    => 'IDS:id:DELIVERY_USERS_LIST_FORM',
    BASE_FIELDS     => 5,
    SKIP_USER_TITLE => 1,
    EXT_TITLES      =>
    {
      id          => 'id',
      login       => $lang{LOGIN},
      fio         => $lang{FIO},
      status      => $lang{STATUS},
      uid         => 'uid',
      email       => 'Email'
    },
    TABLE => {
      width      => '100%',
      qs         => $attr->{PAGE_QS} || $pages_qs,
      ID         => 'DELIVERY_USERS_LIST',
      SELECT_ALL => "DELIVERY_USERS_LIST_FORM:IDS:$lang{SELECT_ALL}",
    },
  });

    my $field_count = ($FORM{json}) ? $#{ $Msgs->{COL_NAMES_ARR} } : $Msgs->{SEARCH_FIELDS_COUNT};

    foreach my $line (@{$list}) {
      my @fields_array = ();
      push @fields_array, $html->form_input('IDS',$line->{id},
        {
          TYPE    => 'checkbox',
          FORM_ID => 'DELIVERY_USERS_LIST_FORM',
          ID      => 'IDS',
        }
      );
      for (my $i = 0; $i < $field_count+5; $i++) {
        my $val = '';
        my $field_name = $Msgs->{COL_NAMES_ARR}->[$i];
        if ($field_name eq 'status') {
          $val = $users_status[$line->{status}];
        }
        else {
          $val = $line->{ $field_name };
        }
        push @fields_array, $val;

      }
        push @fields_array,$html->button( $lang{DELETE}, "index=$index&show=$FORM{show}&IDS=$line->{id}",{ class => 'del'});
        $user_table->addrow(@fields_array);
  }

  my $total_dilivery_users = $Msgs->{TOTAL};

   my $total_table = $html->table({
    width      => '100%',
    cols_align => [ 'right', 'right' ],
    rows       => [ [ "  $lang{TOTAL}: ",$html->b( $total_dilivery_users )] ]
  });

  print $html->form_main({
    CONTENT =>  $user_table->show({ OUTPUT2RETURN => 1  }). $total_table->show({OUTPUT2RETURN=>1}) . $html->form_input('APPLY', $lang{DEL}, {TYPE => 'submit', FORM_ID => 'DELIVERY_USERS_LIST_FORM'}),
    HIDDEN  => {
      index => $index,
      show  => $FORM{show},
    },
    NAME    => 'DELIVERY_USERS_LIST_FORM',
    ID      => 'DELIVERY_USERS_LIST_FORM',
  });

  1
}

#**********************************************************
=head2 sel_deliverys($attr) - show select user group

  Attributes:
    $attr
      SELECTED
      HASH_RESULT     - Return results as hash
      SKIP_MUULTISEL  - Skip multiselect

  Returns:
    GID select form

=cut
#**********************************************************
sub sel_deliverys {
  my ($attr) = @_;

  my $list = $Msgs->msgs_delivery_list({
    SUBJECT   => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 100000
  });

  my $DELIVERY_SEL = $html->form_select(
    'DELIVERY',{
      SELECTED       => $attr->{SELECTED}?$attr->{SELECTED}:0,
      SEL_LIST       => $list,
      SEL_VALUE      => 'subject',
      SEL_KEY        => 'id',
      SORT_KEY_NUM   => 1,
      NO_ID          => 1,
      SEL_OPTIONS    => { '' => '--' },
    }
  );

return $DELIVERY_SEL;
}

1