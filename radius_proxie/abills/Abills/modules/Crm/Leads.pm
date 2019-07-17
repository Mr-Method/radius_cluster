use strict;
use warnings FATAL => 'all';

our (
  @PRIORITY,

  $html,
  %lang,
  $admin,
  $db,
  %conf,
);

#our Crm $Crm;
#our Admins $Admins;
my $Crm = Crm->new($db, $admin, \%conf);
my $Admins = Admins->new($db, \%conf);
use Abills::Base qw/in_array mk_unique_value/;


#**********************************************************
=head2 crm_lead_search()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub crm_lead_search {
  # добавляет нового лида и перенаправляет на страницу профиля
  if ($FORM{add}) {
    $Crm->crm_lead_add({ %FORM });

    _error_show($Crm);

    $html->message('success', $lang{ADDED}, $lang{LEAD_ADDED_MESSAGE} . $html->button("тут",
        "index=" . get_function_index('crm_lead_info') . "&LEAD_ID=$Crm->{INSERT_ID}"));

    return 1;
  }

  my $submit_button_name = $lang{SEARCH};
  my $submit_button_action = 'search';
  my $id_disabled = '';
  my $id_hidden = '';

  my $lead_source_select = $html->form_select(
    'SOURCE',
    {
      SELECTED    => $FORM{SOURCE} || q{},
      SEL_LIST    => translate_list($Crm->leads_source_list({ COLS_NAME => 1 }), 'name'),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
      MAIN_MENU   => get_function_index('crm_source_types'),
    }
  );

  my $responsible_admin = sel_admins({ NAME => 'RESPONSIBLE' });

  my $date_range = $html->form_daterangepicker(
    {
      NAME      => 'PERIOD',
#      FORM_NAME => 'report_panel',
#      WITH_TIME => $FORM{TIME_FORM} || 0
    }
  );

  my $current_step_select = _progress_bar_step_sel();

  my $tpl = $html->tpl_show(
    _include('crm_lead_search', 'Crm'),
    {
      SUBMIT_BTN_NAME   => $submit_button_name,
      SUBMIT_BTN_ACTION => $submit_button_action,
      DISABLE_ID        => $id_disabled,
      HIDE_ID           => $id_hidden,
      LEAD_SOURCE       => $lead_source_select,
      RESPONSIBLE_ADMIN => $responsible_admin,
      DATE              => $date_range,
      CURRENT_STEP_SELECT => $current_step_select,
      INDEX               => get_function_index('crm_leads'),
      %FORM
    }, {OUTPUT2RETURN => 1}
  );


  form_search({TPL => $tpl});
}
#**********************************************************

=head2 crm_lead_search_old() - search leads

  Arguments:
    $attr -

  Returns:

  Examples:

=cut

#**********************************************************
sub crm_lead_search_old {

  my $submit_button_name = $lang{SEARCH};
  my $submit_button_action = 'search';
  my $id_disabled = '';
  my $id_hidden = '';

  my $lead_source_select = $html->form_select(
    'SOURCE',
    {
      SELECTED    => $FORM{SOURCE} || q{},
      SEL_LIST    => translate_list($Crm->leads_source_list({ COLS_NAME => 1 }), 'name'),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
      MAIN_MENU   => get_function_index('crm_source_types'),
    }
  );

  if ($FORM{search}) {

    # поиск лида по параметрам с формы

    my $leads_list = $Crm->crm_lead_list(
      {
        FIO         => $FORM{FIO} || '_SHOW',
        ID          => $FORM{LEAD_ID} || '_SHOW',
        PHONE       => $FORM{PHONE} || '_SHOW',
        EMAIL       => $FORM{EMAIL} || '_SHOW',
        COMPANY     => $FORM{COMPANY} || '_SHOW',
        COMMENTS    => $FORM{COMMENTS} || '_SHOW',
        SOURCE      => $FORM{SOURCE} || '_SHOW',
        DATE        => $FORM{DATE} || '_SHOW',
        RESPONSIBLE => $FORM{RESPONSIBLE} || '_SHOW',
        ADDRESS     => $FORM{ADDRESS} || '_SHOW',
#        CITY        => $FORM{CITY} || '_SHOW',
        BUILD       => $FORM{ADDRESS_BUILD} || '_SHOW',
        FLAT        => $FORM{ADDRESS_FLAT} || '_SHOW',
        COLS_NAME   => 1,
        COLS_UPPER  => 1,
      }
    );

    _error_show($Crm);

    # если нашло одного лида, кидает на страницу информации
    if ($leads_list && ref $leads_list eq 'ARRAY' && scalar @{$leads_list} == 1) {
      $html->message("info", $lang{SUCCESS}, "1 $lang{LEAD}");
      # crm_lead_info($leads_list->[0]->{ID});
      $html->redirect('?index=' . get_function_index('crm_lead_info') . "&LEAD_ID=$leads_list->[0]->{ID}",
        { WAIT => 1 });
      return 1;
    }

    # если нашло больше чем одного лида, показывает панели лидов с ссылкой на их профиль
    elsif ($leads_list && ref $leads_list eq 'ARRAY' && scalar @{$leads_list} > 1) {
      crm_lead_panels(@$leads_list);
      return 1;
    }

    # если не нашло ни одного лида, то дает возможность добавить нового с параметрами поискаы
    $html->message('info', "$lang{LEAD_NOT_FOUND}", "$lang{INPUT_DATA_TO_ADD_LEAD}");

    $submit_button_name = "$lang{ADD}";
    $submit_button_action = 'add';
    $id_disabled = 'disabled';
    $id_hidden = 'hidden';
  }

  # добавляет нового лида и перенаправляет на страницу профиля
  if ($FORM{add}) {
    $Crm->crm_lead_add({ %FORM });

    _error_show($Crm);

    $html->message('success', $lang{ADDED}, $lang{LEAD_ADDED_MESSAGE} . $html->button("тут",
        "index=" . get_function_index('crm_lead_info') . "&LEAD_ID=$Crm->{INSERT_ID}"));

    return 1;
  }

  my $responsible_admin = sel_admins({ NAME => 'RESPONSIBLE' });

  $html->tpl_show(
    _include('crm_lead_search', 'Crm'),
    {
      SUBMIT_BTN_NAME   => $submit_button_name,
      SUBMIT_BTN_ACTION => $submit_button_action,
      DISABLE_ID        => $id_disabled,
      HIDE_ID           => $id_hidden,
      LEAD_SOURCE       => $lead_source_select,
      RESPONSIBLE_ADMIN => $responsible_admin,
      %FORM
    }
  );

  return 1;
}

#**********************************************************

=head2 crm_leads() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub crm_leads {

  if ($FORM{add_form}) {
    my $submit_button_name = "$lang{ADD}";
    my $submit_button_action = 'add';
    my $id_disabled = 'disabled';
    my $id_hidden = 'hidden';

    my $lead_source_select = $html->form_select(
      'SOURCE',
      {
        SELECTED    => $FORM{SOURCE} || q{},
        SEL_LIST    => translate_list($Crm->leads_source_list({ COLS_NAME => 1 }), 'name'),
        SEL_KEY     => 'id',
        SEL_VALUE   => 'name',
        NO_ID       => 1,
        SEL_OPTIONS => { "" => "" },
        MAIN_MENU   => get_function_index('crm_source_types'),
      }
    );

    my $priority_select = $html->form_select(
      'PRIORITY',
      {
        SELECTED    => $FORM{PRIORITY} || q{},
        SEL_ARRAY   => \@PRIORITY,
        NO_ID       => 1,
        SEL_OPTIONS => { "" => "" },
        ARRAY_NUM_ID=> 1,
      }
    );

    my $responsible_admin = sel_admins({ NAME => 'RESPONSIBLE', SELECTED => $admin->{AID} });

    $html->tpl_show(
      _include('crm_lead_search', 'Crm'),
      {
        %FORM,
        SUBMIT_BTN_NAME   => $submit_button_name,
        SUBMIT_BTN_ACTION => $submit_button_action,
        DISABLE_ID        => $id_disabled,
        HIDE_ID           => $id_hidden,
        LEAD_SOURCE       => $lead_source_select,
        RESPONSIBLE_ADMIN => $responsible_admin,
        DATE              => $html->form_datepicker('DATE', $DATE),
        PRIORITY_SEL      => $priority_select,
        INDEX             => get_function_index('crm_leads'),
        # AJAX_SUBMIT_FORM  => 'ajax-submit-form',
        # %$lead_info
      }
    );
  }
  elsif ($FORM{chg}) {
    my $lead_info = $Crm->crm_lead_info({ ID => $FORM{chg} });

    my $submit_button_name = "$lang{CHANGE}";
    my $submit_button_action = 'change';
    my $id_disabled = 'disabled';
    my $id_hidden = 'hidden';

    my $priority_select = $html->form_select(
      'PRIORITY',
      {
        SELECTED     => (defined $lead_info->{PRIORITY}) ? $lead_info->{PRIORITY} : ($FORM{PRIORITY} || q{}),
        SEL_ARRAY    => \@PRIORITY,
        # SEL_KEY   => 'id',
        # SEL_VALUE => 'name',
        ARRAY_NUM_ID => 1,
        NO_ID        => 1,
        SEL_OPTIONS  => { "" => "" },
        # MAIN_MENU => get_function_index('crm_source_types'),
      }
    );

    my $lead_source_select = $html->form_select(
      'SOURCE',
      {
        SELECTED    => $FORM{SOURCE} || $lead_info->{SOURCE},
        SEL_LIST    => translate_list($Crm->leads_source_list({ COLS_NAME => 1 }), 'name'),
        SEL_KEY     => 'id',
        SEL_VALUE   => 'name',
        NO_ID       => 1,
        SEL_OPTIONS => { "" => "" },
      }
    );

    my $responsible_admin = sel_admins({ SELECTED => $FORM{RESPONSIBLE} || $lead_info->{RESPONSIBLE},
      NAME                                        => 'RESPONSIBLE' });

    $html->tpl_show(
      _include('crm_lead_search', 'Crm'),
      {
        SUBMIT_BTN_NAME   => $submit_button_name,
        SUBMIT_BTN_ACTION => $submit_button_action,
        DISABLE_ID        => $id_disabled,
        HIDE_ID           => $id_hidden,
        LEAD_SOURCE       => $lead_source_select,
        RESPONSIBLE_ADMIN => $responsible_admin,
        AJAX_SUBMIT_FORM  => 'ajax-submit-form',
        PRIORITY_SEL      => $priority_select,
        INDEX             => get_function_index('crm_leads'),
        %$lead_info
      }
    );

    if ($FORM{TEMPLATE_ONLY}) {
      return 1;
    }
  }
  elsif ($FORM{add}) {
    $Crm->crm_lead_add({ %FORM, CURRENT_STEP => 1 });

    if (!_error_show($Crm)) {
      $html->message('info', $lang{ADDED},);
    }
  }
  elsif ($FORM{del}) {
    $Crm->crm_lead_delete({ ID => $FORM{del} });
    delete $FORM{COMMENTS};
    if (!_error_show($Crm)) {
      $html->message('info', $lang{DELETED},);
    }
  }
  elsif ($FORM{change}) {
    $Crm->crm_lead_change({ %FORM });

    if (!_error_show($Crm)) {
      $html->message('info', $lang{CHANGED},);
    }

  }

  return 1 if $FORM{MESSAGE_ONLY};
  $LIST_PARAMS{PAGE_ROWS}      = 1000000000;
  $LIST_PARAMS{SKIP_DEL_CHECK} = 1;
  my Abills::HTML $table;

  %LIST_PARAMS = %FORM if ($FORM{search});

  result_former(
    {
      INPUT_DATA      => $Crm,
      FUNCTION        => 'crm_lead_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, FIO, PHONE, EMAIL, COMPANY, ADMIN_NAME, DATE, CURRENT_STEP_NAME, LAST_ACTION, PRIORITY, UID, LOGIN",
      HIDDEN_FIELDS   => 'STEP_COLOR,CURRENT_STEP',
      FUNCTION_FIELDS => 'crm_lead_info:$lang{INFO}:lead_id,change, del',
      FILTER_COLS     => {
        current_step_name => '_crm_current_step_color::STEP_COLOR,',
        last_action       => '_crm_last_action::LEAD_ID',
      },
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        'lead_id'           => "#",
        'fio'               => $lang{FIO},
        'phone'             => $lang{PHONE},
        'company'           => $lang{COMPANY},
        'email'             => 'E-Mail',
        'date'              => "$lang{DATE} $lang{REGISTRATION}",
        'admin_name'        => "$lang{RESPOSIBLE}",
        'current_step_name' => "$lang{STEP}",
        'last_action'       => "$lang{LAST} $lang{ACTION}",
        'priority'          => "$lang{PRIORITY}",
        'login'             => "$lang{LOGIN}",
        # 'comments'  => $lang{COMMENTS},
      },
      SKIP_PAGES      => 1,
      TABLE           => {
        width       => '100%',
        caption     => $lang{LEADS},
        qs          => $pages_qs,
        ID          => 'CRM_LEADS',
        MENU        => "$lang{ADD}:index=$index&add_form=1:add",
        DATA_TABLE  => { "order"=> [[ 6, "desc" ]]},
        title_plain => 1,
        #EXPORT  => 1,
      },
      SELECT_VALUE    => {
        priority => { 0 => "$PRIORITY[0]:text-default",
          1             => "$PRIORITY[1]:text-warning",
          2             => "$PRIORITY[2]:text-danger" }
      },
      # SELECT_VALUE    => {
      #   paid  => {
      #     0 => "$lang{NO}:text-danger",
      #     1 => "$lang{YES}:text-primary",
      #   }
      # },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Crm',
      TOTAL           => 1,
      SKIP_TOTAL_FORM => 1

    }
  );


  return 1;
}

#**********************************************************
=head2 crm_lead_info ($lead_id) -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_lead_info {
  my ($lead_id) = @_;

  if($FORM{delete_uid}){
    $Crm->crm_lead_change({
      ID  => $FORM{LEAD_ID},
      UID => 0,
    });

    if(!_error_show($Crm)){
      $html->message('info', "$lang{SUCCESS}", "$lang{DELETED}");
    }
  }

  if ($FORM{SAVE}) {
    $Crm->crm_lead_change({
      PHONE   => $FORM{phone_2},
      SOURCE  => $FORM{source_2},
      EMAIL   => $FORM{email_2},
      ADDRESS => $FORM{address_2},
      COMPANY => $FORM{company_2},
      ID      => $FORM{TO_LEAD_ID},
    });

    $html->message('success', "$lang{SUCCESS} $lang{IMPORT}", "");
  }

  if ($FORM{LEAD_ID}) {
    $lead_id = $FORM{LEAD_ID};
  }

  if (defined $FORM{CUR_STEP}) {
    $Crm->crm_lead_change({ ID => $FORM{LEAD_ID}, CURRENT_STEP => $FORM{CUR_STEP} + 1 || '0' });

    return 1;
  }

  if($FORM{add_uid}){
    $Crm->crm_lead_change({
      ID  => $FORM{LEAD_ID},
      UID => $FORM{add_uid},
    });

    if(!_error_show($Crm)){
      my $lead_button = $html->button("$lang{LEAD}", "index=" . get_function_index("crm_lead_info") . "&LEAD_ID=$FORM{LEAD_ID}");
      $html->message('info', "$lang{SUCCESS}", "$lang{GO2PAGE} $lead_button");
    }
  }

  my $user_button = $lang{NOT_EXIST};

  require Control::Users_mng;
  my $user_search = user_modal_search({
#    EXTRA_BTN_PARAMS => "&TO_LEAD_ID=" . ($lead_id),
    #    CALLBACK_FN => 'crm_lead_info',
  });

  return 1 if ($FORM{user_search_form} && $FORM{user_search_form}==1);

    $user_button = $html->tpl_show(
      _include('crm_lead_add_user', 'Crm'),
      {
        USER_SEARCH => $user_search,
        LEAD_ID     => $lead_id,
        INDEX       => get_function_index('crm_lead_info'),
      }, {OUTPUT2RETURN => 1}
    );

  if (defined $FORM{STEP_ID} && defined $FORM{add_message}) {

    $Crm->progressbar_comment_add({ %FORM, DATE => "$DATE $TIME" });

    _error_show($Crm);
  }
  elsif ($FORM{delete_message}) {
    $Crm->progressbar_comment_delete({ ID => $FORM{delete_message} });

    _error_show($Crm);
  }

  my $lead_info = $Crm->crm_lead_info({ ID => $lead_id });


  my $delete_user_button = '';

  if($lead_info->{UID} && $lead_info->{UID} > 0){
    $user_button = $html->button("$lead_info->{ID}", "index=15&UID=$lead_info->{UID}",{
        ADD_ICON  => 'fa fa-user',
        class => 'btn btn-default',
      });

    $delete_user_button = $html->button("", "index=$index&delete_uid=1&LEAD_ID=$lead_info->{LEAD_ID}",{
        ICON  => 'fa fa-trash',
        class => 'btn btn-default',
      });
  }

  my $change_button = $html->button(
    "$lang{CHANGE}",
    "get_index=crm_leads&header=2&chg=$lead_id&TEMPLATE_ONLY=1",
    {
      # ICON          => 'glyphicon glyphicon-edit',
      LOAD_TO_MODAL => 1,
      class         => 'btn btn-primary btn-block',
    }
  );

  my $convert_data_button = $html->button(
    "$lang{IMPORT}",
    "get_index=crm_lead_convert&header=2&FROM_LEAD_ID=$lead_id",
    {
      LOAD_TO_MODAL => 1,
      class         => 'btn btn-warning btn-block',
    }
  );

  my $add_user_button = $html->button(
    "$lang{ADD} $lang{USER}",
    "qindex=" . get_function_index("crm_lead_info") . "&TO_LEAD_ID=$lead_id&header=2",
    {
      class         => 'btn btn-warning btn-block',
      LOAD_TO_MODAL => 1,
    }
  );

  my $source_info = $Crm->leads_source_info({ ID => $lead_info->{SOURCE}, COLS_NAME => 1 });
  $lead_info->{SOURCE} = _crm_name_translate($source_info->{NAME});

  my $lead_profile_panel = $html->tpl_show(_include('crm_lead_profile_panel', 'Crm'),
    { %$lead_info,
      CHANGE_BUTTON => $change_button,
      CONVERT_DATA_BUTTON => $convert_data_button,
      ADD_USER_BUTTON => $add_user_button,
      USER_BUTTON => $user_button,
      DELETE_USER_BUTTON => $delete_user_button,
    },
    { OUTPUT2RETURN => 1, });

  # progressbar
  my $lead_progress_bar = crm_progressbar_show($lead_id);

  $html->tpl_show(
    _include('crm_lead_info', 'Crm'),
    {
      LEAD_PROFILE_PANEL => $lead_profile_panel,
      PROGRESSBAR        => $lead_progress_bar,
    }
  );

  return 1;
}

#**********************************************************

=head2 crm_lead_panels() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut

#**********************************************************
sub crm_lead_panels {
  my (@leads) = @_;

  my $lead_profile_panels = '';

  foreach my $each_lead (@leads) {
    my $button_to_lead_info = $html->button("$lang{INFO}",
      "index=" . get_function_index('crm_lead_info') . "&LEAD_ID=$each_lead->{ID}",
      { class => 'btn btn-primary btn-block' });

    $lead_profile_panels .= $html->tpl_show(_include('crm_lead_profile_panel', 'Crm'),
      { %$each_lead, BUTTON_TO_LEAD_INFO => $button_to_lead_info }, { OUTPUT2RETURN => 1, });
  }

  print $lead_profile_panels;

  return 1;
}

#**********************************************************

=head2 crm_progressbar_steps() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub crm_progressbar_steps {

  my $btn_name = 'add';
  my $btn_value = $lang{ADD};
  my $step_info = {};

  if ($FORM{add}) {
    $Crm->crm_progressbar_step_add({ %FORM });
  }
  elsif ($FORM{chg}) {

    $step_info = $Crm->crm_progressbar_step_info({ ID => $FORM{chg} });
    $btn_name = 'change';
    $btn_value = $lang{CHANGE};
  }
  elsif ($FORM{del}) {
    $Crm->crm_progressbar_step_delete({ ID => $FORM{del} });
  }
  elsif ($FORM{change}) {
    $Crm->crm_progressbar_step_change({ %FORM });
  }

  _error_show($Crm);

  $html->tpl_show(
    _include('crm_progressbar_step_add', 'Crm'),
    {
      BTN_NAME  => $btn_name,
      BTN_VALUE => $btn_value,
      %$step_info
    }
  );

  result_former(
    {
      INPUT_DATA      => $Crm,
      FUNCTION        => 'crm_progressbar_step_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, STEP_NUMBER, NAME, COLOR, DESCRIPTION",
      FUNCTION_FIELDS => 'change,del',
      FILTER_COLS     => {
        name => '_crm_name_translate::name,'
      },
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        'id'          => "ID",
        'step_number' => "$lang{STEP}",
        'name'        => $lang{NAME},
        'color'       => $lang{COLOR},
        'description' => $lang{DESCRIBE},
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{STEP},
        qs      => $pages_qs,
        ID      => 'CRM_PROGRESSBAR_STEPS',

        # MENU    => "$lang{ADD}:index=$index&add=1:add",
        #EXPORT  => 1,
      },

      # SELECT_VALUE    => {
      #   paid  => {
      #     0 => "$lang{NO}:text-danger",
      #     1 => "$lang{YES}:text-primary",
      #   }
      # },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Crm',
      TOTAL           => "TOTAL:$lang{TOTAL};TOTAL_SUM:$lang{SUM}",
    }
  );

  return 1;
}

#**********************************************************
=head2 crm_progressbar_show($lead_id)

=cut
#**********************************************************
sub crm_progressbar_show {
  my ($lead_id) = @_;

  my $pb_list = translate_list($Crm->crm_progressbar_step_list({ COLS_NAME => 1 }), 'name');
  my $lead_info = $Crm->crm_lead_info({ ID => $lead_id });

  _error_show($Crm);

  if ($Crm->{TOTAL} > 0) {
    my $progress_name = '';
    my $cur_step = $lead_info->{CURRENT_STEP} - 1;
    my $steps_comments = '';
    my $timeline = '';

    my $tips = '';
    my $css;
    foreach my $line (@$pb_list) {
      $css .= "li.step" . ($line->{step_number} - 1) . "{border-bottom: 12px solid $line->{color} !important;}\n";

      $css .= "li.step" . ($line->{step_number} - 1) . ":before{background-color: $line->{color} !important;}\n";

      my $step_map = $line->{description} || '';

      $progress_name .= "['" . ($line->{name} || $line->{step_number}) . "', '$step_map' ], ";

      my $active_element = '';
      my $active_element_data = '';
      if ($line->{step_number} == $lead_info->{CURRENT_STEP}) {
        $active_element = "active";
        $active_element_data = "in active";
      }

      $steps_comments .= " <li class='$active_element'><a data-toggle='pill' href='#s$line->{id}' class='btn btn-default'>$line->{name}</a></li>";

      my $messages_list = $Crm->progressbar_comment_list({
        STEP_ID      => $line->{id},
        LEAD_ID      => $lead_id,
        MESSAGE      => '_SHOW',
        DATE         => '_SHOW',
        ADMIN        => '_SHOW',
        ACTION       => '_SHOW',
        PLANNED_DATE => '_SHOW',
        COLS_NAME    => 1,
        COLS_UPPER   => 1,
      });

      if ($FORM{SAVE} && $FORM{TO_LEAD_ID}) {
        foreach my $message (@$messages_list) {
          $Crm->progressbar_comment_add({
            LEAD_ID => $FORM{TO_LEAD_ID},
            MESSAGE => $message->{MESSAGE},
            DATE    => $message->{DATE},
            STEP_ID => $message->{STEP_ID},
          });
        }
      }

      my $timeline_items;

      foreach my $message (@$messages_list) {
        my %TIMELIINE_ITEM_TEMPLATE = (
          ICON   => 'glyphicon glyphicon-info-sign bg-blue',
          HEADER => $lang{NOTES},
          FOOTER => $html->button('', "index=$index&delete_message=$message->{id}&LEAD_ID=$lead_id",
            { ICON => 'glyphicon glyphicon-trash text-red' }),
        );

        if ($message->{admin} && $message->{action}) {
          my %ACTION_STATUSES = (
            '0' => 'bg-red',
            '1' => 'bg-green',
          );

          $TIMELIINE_ITEM_TEMPLATE{ICON} = 'glyphicon glyphicon-wrench ' . $ACTION_STATUSES{$message->{status} || 0};
          $TIMELIINE_ITEM_TEMPLATE{HEADER} = "$lang{ACTION}: $message->{action} [ $lang{PLANNED} $lang{DATE}:" . ($message->{planned_date} || '') . " ]";
        };


        $timeline_items .= $html->tpl_show(
          _include('crm_timeline_item', 'Crm'),
          {
            MESSAGE => $message->{message},
            DATE    => $message->{date},
            %TIMELIINE_ITEM_TEMPLATE
          },
          { OUTPUT2RETURN => 1 }
        );
      }
      my $admin_sel = sel_admins();
      my $action_sel = _actions_sel();

      $timeline .= $html->tpl_show(
        _include('crm_pb_timeline', 'Crm'),
        {
          ID             => $line->{id},
          ACTIVE         => $active_element_data,
          TIMELINE_ITEMS => $timeline_items,

          ADMIN_SEL      => $admin_sel,
          ACTION_SEL     => $action_sel,

          INDEX          => get_function_index('crm_lead_info'),
          LEAD_ID        => $FORM{LEAD_ID},
        },
        { OUTPUT2RETURN => 1 }
      );

      # if ($line->{step_date}) {
      #   $cur_step = $line->{step_number};
      #   $tips = $line->{description};
      # }
    }

    $steps_comments = $html->tpl_show(
      _include('crm_pb_steps_comments', 'Crm'),
      {
        PILLS    => $steps_comments,
        TIMELINE => $timeline,
      },
      { OUTPUT2RETURN => 1 }
    );

    return $html->tpl_show(
      _include('crm_progressbar', 'Crm'),
      {
        PROGRESS_NAMES => $progress_name,
        CUR_STEP       => $cur_step || 0,
        TIPS           => $tips,
        STEPS_COMMENTS => $steps_comments,
        CSS            => $css,
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  return '';
}

#**********************************************************
=head2 crm_source_types() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_source_types {

  my $btn_name = 'add';
  my $btn_value = $lang{ADD};
  my %source_info = ();

  if ($FORM{add}) {
    $Crm->leads_source_add({ %FORM });
  }
  elsif ($FORM{chg}) {
    %source_info = %{$Crm->leads_source_info({ ID => $FORM{chg} })};
    $btn_name = 'change';
    $btn_value = $lang{CHANGE};
  }
  elsif ($FORM{del}) {
    $Crm->leads_source_delete({ ID => $FORM{del} });
  }
  elsif ($FORM{change}) {
    $Crm->leads_source_change({ %FORM });
  }

  _error_show($Crm);

  $html->tpl_show(
    _include('crm_leads_sources', 'Crm'),
    {
      BTN_NAME  => $btn_name,
      BTN_VALUE => $btn_value,
      %source_info
    }
  );

  result_former(
    {
      INPUT_DATA      => $Crm,
      FUNCTION        => 'leads_source_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, NAME, COMMENTS",
      FUNCTION_FIELDS => 'change,del',
      SKIP_USER_TITLE => 1,
      FILTER_COLS     => {
        name => '_crm_name_translate::name,'
      },
      EXT_TITLES      => {
        'id'       => "ID",
        'name'     => $lang{NAME},
        'comments' => $lang{COMMENTS},
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{SOURCE},
        qs      => $pages_qs,
        ID      => 'CRM_SOURCE_TYPES',
        # MENU    => "$lang{ADD}:index=$index&add=1:add",
        #EXPORT  => 1,
      },
      # SELECT_VALUE    => {
      #   paid  => {
      #     0 => "$lang{NO}:text-danger",
      #     1 => "$lang{YES}:text-primary",
      #   }
      # },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Crm',
      TOTAL           => "TOTAL:$lang{TOTAL}",
    }
  );

  return 1;
}

#**********************************************************
=head2 crm_report_leads() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_reports_leads {

  my $date_range = $html->form_daterangepicker(
    {
      NAME      => 'FROM_DATE/TO_DATE',
      FORM_NAME => 'report_panel',
      WITH_TIME => $FORM{TIME_FORM} || 0
    }
  );

  my $source_select = $html->form_select(
    'SOURCE_ID',
    {
      SELECTED    => $FORM{SOURCE_ID} || q{},
      SEL_LIST    => translate_list($Crm->leads_source_list({ COLS_NAME => 1 }), 'name'),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { "" => "" },
      MAIN_MENU   => get_function_index('crm_source_types'),
    }
  );

  $html->tpl_show(
    _include('crm_leads_reports', 'Crm'),
    {
      DATE_RANGE    => $date_range,
      SOURCE_SELECT => $source_select,
    }
  );

#  $LIST_PARAMS{FROM_DATE} = $FORM{FROM_DATE} || $DATE;
#  $LIST_PARAMS{TO_DATE} = $FORM{TO_DATE} || $DATE;
  $LIST_PARAMS{SOURCE} = $FORM{SOURCE_ID} || '';
  $LIST_PARAMS{PERIOD} = ($FORM{FROM_DATE} || $DATE) . "/" . ($FORM{TO_DATE} || $DATE);

  result_former(
    {
      INPUT_DATA      => $Crm,
      FUNCTION        => 'crm_lead_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, FIO, DATE, SOURCE_NAME",
      FILTER_COLS     => {
        fio => '_crm_leads_filter::lead_id,'
      },
      # FUNCTION_FIELDS => 'change,del',
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        'lead_id'     => "ID",
        'FIO'         => $lang{FIO},
        'date'        => $lang{DATE},
        'source_name' => $lang{SOURCE},
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{LEADS},
        qs      => $pages_qs,
        ID      => 'CRM_LEADS',

        # MENU    => "$lang{ADD}:index=$index&add=1:add",
        #EXPORT  => 1,
      },

      # SELECT_VALUE    => {
      #   paid  => {
      #     0 => "$lang{NO}:text-danger",
      #     1 => "$lang{YES}:text-primary",
      #   }
      # },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Crm',
      TOTAL           => "TOTAL:$lang{TOTAL}",
    }
  );

  return 1;
}

#**********************************************************
=head2 _crm_leads_filter() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub _crm_leads_filter {
  my ($fio, $attr) = @_;

  my $id = $attr->{VALUES}{lead_id};

  my $params = "index=" . get_function_index('crm_lead_info') . "&LEAD_ID=$id";

  return $html->button($fio, $params);
}

#**********************************************************
=head2 crm_short_info() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_short_info {

  # watching if param phone exist
  my $lead_phone;
  if ($FORM{PHONE}) {
    $lead_phone = $FORM{PHONE};
  }
  else {
    print qq{ { "ERROR": 1, "DESCRIPTION": "NO PHONE"} };

    return 1;
  }

  # if module Callcenter turn on - add this call to calls handler
  if (in_array('Callcenter', \@MODULES)) {
    require Callcenter;
    Callcenter->import();
    my $Callcenter = Callcenter->new($db, $admin, \%conf);
    my $admin_info = $Admins->info($admin->{AID});

    $Callcenter->callcenter_add_cals({
      USER_PHONE     => $lead_phone,
      OPERATOR_PHONE => $admin_info->{PHONE} || 0,
      STATUS         => 3,
      UID            => $FORM{uid} || 0,
      ID             => "AE:" . mk_unique_value(10, { SYMBOLS => '1234567890' })
    });
  }

  my $Sender = Abills::Sender::Core->new($db, $admin, \%conf);

  # at first search user
  use Users;
  my $users = Users->new($db, $admin, \%conf);

  my $user_info = $users->list({
    PHONE     => $FORM{PHONE},
    FIO       => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 1,
  });

  if ($users->{TOTAL} == 1) {
    my $json_user_info = JSON::to_json($user_info->[0], { utf8 => 0 });

    my $user_link = $html->button(($user_info->[0]->{fio} || "$lang{NO} $lang{FIO}"),
      "index=" . get_function_index('crm_user_service') . "&UID=$user_info->[0]->{uid}");

    $Sender->send_message(
      {
        AID         => $admin->{AID},
        SENDER_TYPE => 'Browser',
        TITLE       => "$lang{INCOMING_CALL}",
        MESSAGE     => "$lang{FIO}: $user_link",
      }
    );

    print $json_user_info;
    return 1;
  }

  my $lead_info = $Crm->crm_lead_list(
    {
      PHONE_SEARCH => $lead_phone,
      CURRENT_STEP => '_SHOW',
      FIO          => '_SHOW',
      EMAIL        => '_SHOW',
      COMPANY      => '_SHOW',
      COMMENTS     => '_SHOW',
      COLS_NAME    => 1,
      PAGE_ROWS    => 1,
    }
  );

  if (defined $Crm->{TOTAL} && $Crm->{TOTAL} == 1) {
    my $json_lead_info = JSON::to_json($lead_info->[0], { utf8 => 0 });

    $Crm->progressbar_comment_add({
      STEP_ID => $lead_info->[0]{current_step} || 1,
      MESSAGE => "Aengine call",
      LEAD_ID => $lead_info->[0]{id},
      DATE => "$DATE $TIME"
    });

    my $lead_link = $html->button(($lead_info->[0]->{fio} || "$lang{NO} $lang{FIO}"),
      "index=" . get_function_index('crm_lead_info') . "&LEAD_ID=$lead_info->[0]->{id}");

    $Sender->send_message(
      {
        AID         => $admin->{AID},
        SENDER_TYPE => 'Browser',
        TITLE       => "$lang{INCOMING_CALL}",
        MESSAGE     => "$lang{FIO}: $lead_link",
      }
    );

    print $json_lead_info;

    # return 1;
  }
  elsif (defined $Crm->{TOTAL} && $Crm->{TOTAL} < 1) {
    $FORM{COMMENTS} = "$DATE $TIME - lead called through AEngineer";
    $Crm->crm_lead_add({ %FORM, DATE => $DATE, RESPONSIBLE => $admin->{AID} });

    if (!$Crm->{errno}) {
      my $lead_link = $html->button(($lead_info->[0]->{fio} || "$lang{NO} $lang{FIO}"),
        "index=" . get_function_index('crm_lead_info') . "&LEAD_ID=$Crm->{INSERT_ID}");

      $Sender->send_message(
        {
          AID         => $admin->{AID},
          SENDER_TYPE => 'Browser',
          TITLE       => "$lang{INCOMING_CALL}",
          MESSAGE     => "$lang{LEAD} $lang{ADDED}\n$lang{FIO}: $lead_link",
        }
      );

      print qq{ { "ERROR" : 0, "DESCRIPTION" : "NEW LEAD ADDED" } };
    }
    else {
      print qq{ { "ERROR" : 2, "CANT ADD NEW LEAD" } };
    }

    # return 1;
  }
  elsif(defined $Crm->{TOTAL} && $Crm->{TOTAL} > 1){
    print qq{ { "ERROR" : 3, "DESCRIPTION" : "MORE THEN 1 LEAD FOUND" } };
  }

  return 1;
}

#**********************************************************
=head2 crm_lead_progress_report() -

  Arguments:
    $att -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_leads_progress_report {

  my $date_range = $html->form_daterangepicker(
    {
      NAME      => 'FROM_DATE/TO_DATE',
      FORM_NAME => 'report_panel',
      WITH_TIME => $FORM{TIME_FORM} || 0
    }
  );

  $html->tpl_show(
    _include('crm_leads_reports', 'Crm'),
    {
      DATE_RANGE         => $date_range,
      HIDE_SOURCE_SELECT => 'none',
    }
  );

#  $LIST_PARAMS{FROM_DATE} = $FORM{FROM_DATE} || $DATE;
#  $LIST_PARAMS{TO_DATE} = $FORM{TO_DATE} || $DATE;
#  $LIST_PARAMS{SOURCE_ID} = $FORM{SOURCE_ID} || '';

    my $period = ($FORM{FROM_DATE} || $DATE) . "/" . ($FORM{TO_DATE} || $DATE);

  my $leads_list = $Crm->crm_lead_list({ PERIOD => $period, SOURCE => ($FORM{SOURCE_ID} || '_SHOW'), COLS_NAME => 1, DATE => '_SHOW', CURRENT_STEP => '_SHOW' });
  _error_show($Crm);
  my $steps_list = $Crm->crm_progressbar_step_list({ COLS_NAME => 1 });
  _error_show($Crm);

  my $last_step = 0;

  foreach my $step (@$steps_list) {
    $last_step = $step->{step_number};
  }

  my %HASH_BY_DATES;

  foreach my $lead (@$leads_list) {
_bp("", $lead);
    if (defined $HASH_BY_DATES{ $lead->{date} }{leads_comes}) {
      $HASH_BY_DATES{ $lead->{date} }{leads_comes}++;
    }
    else {
      $HASH_BY_DATES{ $lead->{date} }{leads_comes} = 1;
    }

    if ($last_step == $lead->{current_step}) {
      if (defined $HASH_BY_DATES{ $lead->{date} }{leads_finished}) {
        $HASH_BY_DATES{ $lead->{date} }{leads_finished}++;
      }
      else {
        $HASH_BY_DATES{ $lead->{date} }{leads_finished} = 1;
      }
    }
  }

  my @dates;
  my @leads_comes;
  my @leads_finished;

  foreach my $key (sort keys %HASH_BY_DATES) {
    push(@dates, $key);
    push(@leads_comes, $HASH_BY_DATES{$key}{leads_comes} || 0);
    push(@leads_finished, $HASH_BY_DATES{$key}{leads_finished} || 0);
  }

  my $leads_progress_table = $html->table(
    {
      ID      => 'LEADS_PROGRESS_TABLE',
      width   => '100%',
      caption => "$lang{LEADS} $lang{PROGRESS}",
      title   => [ "$lang{DATE}", "$lang{LEADS_COMES}", "$lang{LEADS_FINISHED}", $lang{PROGRESS} ]
    }
  );

  foreach my $date (reverse sort keys %HASH_BY_DATES) {

    $leads_progress_table->addrow(
      $html->button("$date", "index=" . get_function_index('crm_reports_leads') . "&FROM_DATE=$date&TO_DATE=$date", {

        }),
      $HASH_BY_DATES{$date}{leads_comes} || 0,
      $HASH_BY_DATES{$date}{leads_finished} || 0,
      $html->progress_bar(
        {
          TOTAL        => $HASH_BY_DATES{$date}{leads_comes} || 0,
          COMPLETE     => $HASH_BY_DATES{$date}{leads_finished} || 0,
          PERCENT_TYPE => 1,
          COLOR        => 'MAX_COLOR',
        },
      )
    );
  }

  print $leads_progress_table->show();

  print $html->chart({
    TYPE              => 'bar',
    X_LABELS          => \@dates,
    DATA              => {
      "$lang{LEADS_COMES}"    => \@leads_comes,
      "$lang{LEADS_FINISHED}" => \@leads_finished,
    },
    BACKGROUND_COLORS => {
      "$lang{LEADS_COMES}"    => 'rgba(2, 99, 2, 0.5)',
      "$lang{LEADS_FINISHED}" => 'rgba(255, 99, 255, 0.5)',
    },
    #OUTPUT2RETURN => 1,
  });

  return 1;
}

#**********************************************************
=head2 _crm_current_step_color() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub _crm_current_step_color {
  my ($step_name, $attr) = @_;
  return '' unless ($step_name);

  my $color = $attr->{VALUES}{STEP_COLOR};

  return $html->element('span', _translate($step_name), { class => 'label', style => "background-color:$color" });
}

#**********************************************************
=head2 _crm_last_action() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub _crm_last_action {
  my ($lead_id) = @_;

  my $list = $Crm->progressbar_comment_list({
    COLS_NAME => 1,
    LEAD_ID   => $lead_id,
    PAGE_ROWS => 1,
    DATE      => '_SHOW',
  });

  if (!$Crm->{errno}) {
    if (ref $list eq 'ARRAY' && scalar @$list > 0) {
      return "$list->[0]->{date}";
    }
  }

  return '';
}

#**********************************************************
=head2 crm_lead_convert() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_lead_convert {

  if ($FORM{TO_LEAD_ID}) {

    my $from_lead_info = $Crm->crm_lead_info({ ID => $FORM{FROM_LEAD_ID} });
    my $to_lead_info = $Crm->crm_lead_info({ ID => $FORM{TO_LEAD_ID} });

    my $from_lead_panel = $html->tpl_show(_include('crm_convert_panel', 'Crm'),
      {
        %$from_lead_info,
        POSTFIX_PANEL_ID => 1,
      }, { OUTPUT2RETURN => 1 }
    );

    my $to_lead_panel = $html->tpl_show(_include('crm_convert_panel', 'Crm'),
      {
        %$to_lead_info,
        POSTFIX_PANEL_ID => 2,
      }, { OUTPUT2RETURN => 1 }
    );

    $html->tpl_show(_include('crm_leads_convert', 'Crm'),
      {
        FROM_LEAD_PANEL     => $from_lead_panel,
        TO_LEAD_PANEL       => $to_lead_panel,
        LEFT_PANEL_POSTFIX  => 1,
        RIGHT_PANEL_POSTFIX => 2,
        INDEX               => get_function_index('crm_lead_info'),
        FROM_LEAD_ID        => $FORM{FROM_LEAD_ID},
        TO_LEAD_ID          => $FORM{TO_LEAD_ID},
      }
    );

    return 1;
  }

  my $leads_list = $Crm->crm_lead_list({
    FIO        => $FORM{FIO} || '_SHOW',
    COLS_NAME  => 1,
    COLS_UPPER => 1,
  });

  my $to_lead_select = $html->form_select(
    'TO_LEAD_ID',
    {
      SELECTED  => $FORM{TO_LEAD_ID} || q{},
      SEL_LIST  => $leads_list,
      SEL_KEY   => 'id',
      SEL_VALUE => 'fio',
      EX_PARAMS => "data-auto-submit='form'"
    }
  );

  $html->tpl_show(_include('crm_leads_convert_select', 'Crm'),
    {
      TO_LEAD_SELECT => $to_lead_select,
      FROM_LEAD_ID   => $FORM{FROM_LEAD_ID},
    }
  );

  return 1;
}

#**********************************************************
=head2 internet_search($attr) - Global search submodule

  Arguments:
    $attr
      SEARCH_TEXT
      DEBUG

  Returs:
     TRUE/FALSE

=cut
#**********************************************************
sub crm_search {
  my ($attr) = @_;

  my @default_search = ('FIO', 'PHONE', 'EMAIL', 'COMPANY', 'LEAD_CITY', 'ADDRESS', '_MULTI_HIT');

  my @qs = ();
  foreach my $field (@default_search) {
    $LIST_PARAMS{$field} = "*$attr->{SEARCH_TEXT}*";
    push @qs, "$field=*$attr->{SEARCH_TEXT}*";
  }

  if ($attr->{DEBUG}) {
    $Crm->{debug} = 1;
  }

  $Crm->crm_lead_list({
    %LIST_PARAMS,
  });

  my @info = ();

  if ($Crm->{TOTAL}) {
    push @info, {
        'TOTAL'        => $Crm->{TOTAL},
        'MODULE'       => 'Crm',
        'MODULE_NAME'  => $lang{LEADS},
        'SEARCH_INDEX' => get_function_index('crm_leads')
          . '&' . join('&', @qs) . "&search=1"
      };
  }
  elsif ($attr->{SEARCH_TEXT} =~ /\@/ || $attr->{SEARCH_TEXT} =~ /^\d+$/) {
    my $search_type = 'EMAIL';

    if ($attr->{SEARCH_TEXT} =~ /^\d+$/) {
      $search_type = 'PHONE';
    }

    push @info, {
        'TOTAL'        => 0,
        'MODULE'       => 'Crm',
        'MODULE_NAME'  => $lang{LEADS},
        'SEARCH_INDEX' => get_function_index('crm_leads')
          . '&' . join('&', @qs) . "&search=1",
        EXTRA_LINK     => "$lang{ADD}|index=" . get_function_index('crm_leads') . "&add_form=1&"
          . "$search_type=$attr->{SEARCH_TEXT}"
      };
  }

  return \@info;
}


#**********************************************************
=head2 crm_user_calling_info() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_user_service {
  #my ($attr) = @_;

  my $uid = $FORM{UID};

  require Control::Users_mng;
  use Users;
  my Users $user_info = $users->info($uid, { SHOW_PASSWORD => 1 });
  $FORM{NEWFORM} = 1;

  if ($FORM{json}) {
    #    user_form({ USER_INFO => $user_info });
    #    user_pi();
  }
  else {
    print "<div class='row'><div class='col-md-12 col-lg-6'>";
    user_form({ USER_INFO => $user_info });
    print "</div>"
      . "<div class='col-md-12 col-lg-6'>";
    user_pi();
    print "</div></div>";
  }

  if (in_array('Msgs', \@MODULES)) {
    my @msgs_rows;
    use Msgs;
    my $Msgs = Msgs->new($db, $admin, \%conf);
    my $msgs_list = $Msgs->messages_list({
      UID                    => $uid,
      DATETIME               => '_SHOW',
      SUBJECT                => '_SHOW',
      RESPOSIBLE_ADMIN_LOGIN => '_SHOW',
      COLS_NAME              => 1,
      PAGE_ROWS              => 5,
      SORT                   => 'id',
      DESC                   => 'desc'
    });

    foreach my $msgs (@$msgs_list) {
      my $button_to_subject = $html->button(($msgs->{subject} || $lang{NO_SUBJECT} || 'NO SUBJECT'),
        "index=" . get_function_index('msgs_admin') . "&UID=$uid&chg=$msgs->{id}");
      push @msgs_rows, [ $msgs->{id}, $button_to_subject, $msgs->{datetime}, ($msgs->{resposible_admin_login} || '') ];
    }

    my $msgs_table = $html->table(
      {
        width   => '100%',
        caption => "$lang{MESSAGES}",
        ID      => 'CRM_MSGS_LITE',
        title   => [ '#', $lang{SUBJECT}, $lang{DATE}, $lang{RESPOSIBLE} ],
        rows    => [ @msgs_rows ]
        #      EXPORT  => 1,
      }
    );

    print $msgs_table->show();
  }
  else {
    $html->message("warning", "$lang{MODULE} Msgs $lang{NOT_ADDED}");
  }

  if (in_array('Callcenter', \@MODULES)) {
    require Callcenter;
    Callcenter->import();
    my $Callcenter = Callcenter->new($db, $admin, \%conf);
    my $calls_list = $Callcenter->callcenter_list_calls({
      UID       => $uid,
      DATE      => '_SHOW',
      STATUS    => '_SHOW',
      COLS_NAME => 1,
      PAGE_ROWS => 5,
      SORT      => 'id',
      DESC      => 'desc'
    });
    my @calls_rows;
    my @STATUSES = ('', $lang{RINGING}, $lang{IN_PROCESSING}, $lang{PROCESSED}, $lang{NOT_PROCESSED});

    foreach my $call (@$calls_list) {
      push @calls_rows, [ $call->{id}, $call->{date}, $STATUSES[$call->{status}] ];
    }

    my $calls_table = $html->table(
      {
        width   => '100%',
        caption => "$lang{CALLS_HANDLER}",
        ID      => 'CRM_CALLS_LITE',
        title   => [ '#', $lang{DATE}, $lang{STATUS} ],
        rows    => [ @calls_rows ],

        #      EXPORT  => 1,
      }
    );
    print $calls_table->show();
  }
  else {
    $html->message("warning", "$lang{MODULE} Callcenter $lang{NOT_ADDED}");
  }

  return 1;
}

#**********************************************************
=head2 ()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _crm_name_translate {
  my ($name) = @_;

  return _translate($name);
}

#**********************************************************
=head2 lead_actions_main ($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub crm_actions_main {

  my %CRM_ACTIONS_TEMPLATE = (
    BTN_NAME  => "add",
    BTN_VALUE => $lang{ADD}
  );

  if ($FORM{add}) {
    $Crm->crm_actions_add({ %FORM });
    _error_show($Crm);
  }
  elsif ($FORM{change}) {
    $Crm->crm_actions_change({ %FORM });
    _error_show($Crm);
  }
  elsif ($FORM{del}) {
    $Crm->crm_actions_delete({ ID => $FORM{del} });
    _error_show($Crm);
  }

  if ($FORM{chg}) {
    $CRM_ACTIONS_TEMPLATE{BTN_NAME} = "change";
    $CRM_ACTIONS_TEMPLATE{BTN_VALUE} = $lang{CHANGE};

    my $action_info = $Crm->crm_actions_info({
      ID         => $FORM{chg},
      NAME       => '_SHOW',
      ACTION     => '_SHOW',
      COLS_NAME  => 1,
      COLS_UPPER => 1,
    });
    _error_show($Crm);

    if ($action_info) {
      @CRM_ACTIONS_TEMPLATE{keys %$action_info} = values %$action_info;
    }

  }

  $html->tpl_show(
    _include('crm_actions_add', 'Crm'),
    {
      %CRM_ACTIONS_TEMPLATE
    }
  );

  result_former(
    {
      INPUT_DATA      => $Crm,
      FUNCTION        => 'crm_actions_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, NAME, ACTION",
      FUNCTION_FIELDS => 'change,del',
      EXT_TITLES      => {
        'id'     => "ID",
        'name'   => $lang{NAME},
        'action' => $lang{ACTION},
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{ACTION},
        qs      => $pages_qs,
        ID      => 'CRM_ACTIONS',
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Crm',
      TOTAL           => "TOTAL:$lang{TOTAL}",
    }
  );
}

#**********************************************************
=head2 _actions_sel()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _actions_sel {
  my ($attr) = @_;

  my $actions_list = $Crm->crm_actions_list({
    NAME      => '_SHOW',
    ACTION    => '_SHOW',
    COLS_NAME => 1,
  });

  return $html->form_select('ACTION_ID',
    {
      SELECTED    => $attr->{SELECTED} || 0,
      SEL_LIST    => $actions_list,
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name,action',
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' },
      #      REQUIRED    => ($attr->{REQUIRED}) ? 'required' : undef
    });
}

#**********************************************************
=head2 crm_lead_add_user()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub crm_lead_add_user {

  if($FORM{add_uid}){
    $Crm->crm_lead_change({
      ID  => $FORM{LEAD_ID},
      UID => $FORM{UID},
    });

    if(!_error_show($Crm)){
      my $lead_button = $html->button("$lang{LEAD}", "index=" . get_function_index("crm_lead_info") . "&LEAD_ID=$FORM{LEAD_ID}");
      $html->message('info', "$lang{SUCCESS}", "$lang{GO2PAGE} $lead_button");
    }
  }

  my $lead_id = $FORM{TO_LEAD_ID};

  # Check for search form request
  require Control::Users_mng;
  my $user_search = user_modal_search({
    EXTRA_BTN_PARAMS => "",
    CALLBACK_FN => 'crm_lead_info',
  });
  return 1 if ($user_search && $user_search eq 2);

  $html->tpl_show(
    _include('crm_lead_add_user', 'Crm'),
    {
      USER_SEARCH => $user_search,
      LEAD_ID     => $lead_id,
      INDEX       => get_function_index('crm_lead_info'),
    }
  );
  return 1;
}
#**********************************************************
=head2 crm_sales_funnel() - Shows sales funnel for leads

=cut
#**********************************************************
sub crm_sales_funnel {
  reports(
    {
      DATE_RANGE       => 1,
      DATE             => $FORM{DATE},
      REPORT           => '',
      EX_PARAMS        => {
      },
      PERIOD_FORM      => 1,
      PERIODS          => 1,
      NO_TAGS          => 1,
      NO_GROUP         => 1,
      NO_ACTIVE_ADMINS => 1
    }
  );
  my ($y, $m, $d) = split('-', $DATE);
  my $from_date = "$y-$m-01";
  my $to_date = "$y-$m-" . days_in_month({ DATE => $DATE });
  my @leads_array = ();
  if ($FORM{FROM_DATE} && $FORM{TO_DATE}) {
    $from_date = $FORM{FROM_DATE};
    $to_date = $FORM{TO_DATE};
  }
  my $period = "$from_date/$to_date";
  my $list = $Crm->crm_progressbar_step_list({
    STEP_NUMBER => '_SHOW',
    NAME        => '_SHOW',
    SORT        => 2,
    COLS_NAME   => 1
  });
  my $table = $html->table(
    {
      width   => '100%',
      caption => $lang{SALES_FUNNEL},
      title   => [
        "$lang{STEP}",
        "$lang{NAME}",
        "$lang{NUMBER_LEADS}",
        "$lang{LEADS_PERCENTAGE}",
        "$lang{NUMBER_LEADS_ON_STEP}",
        "$lang{LEADS_PERCENTAGE_ON_STEP}"
      ],
      ID      => 'SALES_FUNNEL_ID'
    }
  );
  $Crm->crm_lead_list({
    PERIOD => "$from_date/$to_date",
    CURRENT_STEP => ">=1",
  });
  my $full_count = $Crm->{TOTAL};
  my $i=1;
  foreach my $item (@$list) {
    $Crm->crm_lead_list({
      PERIOD => "$from_date/$to_date",
      CURRENT_STEP => ">=$i"
    });
    my $count_for_step = $Crm->{TOTAL};
    $Crm->crm_lead_list({
      PERIOD => "$from_date/$to_date",
      CURRENT_STEP => $i
    });
    my $step_count = $Crm->{TOTAL};
    my $item_name = _translate($item->{name});
    $table->addrow(
      $item->{step_number},
      $item_name,
      $html->button( $count_for_step,
        "index=" . get_function_index('crm_leads') . "&PERIOD=$period&CURRENT_STEP=>=$item->{step_number}&search=1" ),
      $html->progress_bar({
        TEXT         => '123',
        TOTAL        => $full_count,
        COMPLETE     => $count_for_step,
        COLOR        => 'light-blue',
        PERCENT_TYPE => 1
      }),
      $html->button( $step_count,
        "index=" . get_function_index('crm_leads') . "&PERIOD=$period&CURRENT_STEP=$item->{step_number}&search=1" ),
      $html->progress_bar({
        TEXT         => '123',
        TOTAL        => $full_count,
        COMPLETE     => $step_count,
        COLOR        => 'yellow',
        PERCENT_TYPE => 1
      })
    );
    push @leads_array, {
      value     => $count_for_step + 0,
      title => $item_name,
    };
    $i++;
  }
  print $table->show();
  my $json = JSON->new()->utf8(0);
  my $data = $json->encode(\@leads_array);
  $html->tpl_show(_include('sales_funnel_chart', 'Crm'), { DATA => $data });

  return 1;
}

#**********************************************************
=head2 _actions_sel()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _progress_bar_step_sel {
  my ($attr) = @_;

  my $progress_bar_steps_list = $Crm->crm_progressbar_step_list({
    ID        => '_SHOW',
    NAME      => '_SHOW',
    COLS_NAME => 1,
  });

  my @PB_STEPS_LSIT = ();

  my $id=1;
  foreach my $step (@$progress_bar_steps_list){
    $step->{id}= $id++;
    $step->{name} = _translate($step->{name});
  }

  return $html->form_select('CURRENT_STEP',
    {
      SELECTED    => $attr->{SELECTED} || q{},
      SEL_LIST    => $progress_bar_steps_list,
#      ARRAY_NUM_ID => 1,
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' },
    });
}

1;