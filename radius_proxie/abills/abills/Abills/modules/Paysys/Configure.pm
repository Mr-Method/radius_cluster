#package Paysys::Configure;

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(cmd);

our ($db,
  %conf,
  $admin,
  $op_sid,
  $html,
  %lang,
  $base_dir,
  %ADMIN_REPORT,
  %PAYSYS_PAYMENTS_METHODS,
  @WEEKDAYS,
  @MONTHES,
  %FEES_METHODS,
  @TERMINAL_STATUS,
);

use Paysys;

our Paysys $Paysys;

#**********************************************************
=head2 paysys_configure_main()

=cut
#**********************************************************
sub paysys_configure_main {
  #my $paysys_folder = "$base_dir" . 'Abills/modules/Paysys/systems/';

  # show form for paysys connection
  if ($FORM{add_form}) {
    my $btn_value = $lang{ADD};
    my $btn_name = 'add_paysys';
    my ($paysys_select, $json_list) = _paysys_select_systems();

    $html->tpl_show(
      _include('paysys_connect_system', 'Paysys'),
      {
        BTN_VALUE     => $btn_value,
        BTN_NAME      => $btn_name,
        PAYSYS_SELECT => $paysys_select,
        JSON_LIST     => $json_list,
        PAYMENT_METHOD_SEL => _paysys_select_payment_method(),
      },
    );
  }

  # add system in paysys connection
  if ($FORM{add_paysys}) {
    $Paysys->paysys_connect_system_add({
      PAYSYS_ID => $FORM{PAYSYS_ID},
      NAME      => $FORM{NAME},
      MODULE    => $FORM{MODULE},
      PAYSYS_IP => $FORM{IP},
      STATUS    => $FORM{STATUS},
    });

    my $payment_system = $FORM{MODULE};
    my $require_module = _configure_load_payment_module($payment_system);

    if ($require_module->can('get_settings')) {
      my $config = Conf->new($db, $admin, \%conf);
      my %settings = $require_module->get_settings();

      foreach my $key (sort keys %{$settings{CONF}}) {
        if($key =~ /_NAME_/) {
          my $new_key = $key;
          my $new_name = uc($FORM{NAME});
          $new_key =~ s/_NAME_/_$new_name\_/;

          $config->config_add({ PARAM => $new_key, VALUE => $FORM{$key}, REPLACE => 1 });
        }
        else{
          $config->config_add({ PARAM => $key, VALUE => $FORM{$key}, REPLACE => 1 });
        }
      }

    }

    if (!_error_show($Paysys)) {
      $html->message('info', $lang{SUCCESS}, $lang{ADDED});
    }
  }

  #  if ($FORM{MERCHANT}) {
  #    paysys_merchant_configuration();
  #    return 1;
  #  }

  # change %CONF params in db
  if ($FORM{change}) {
    my $config = Conf->new($db, $admin, \%conf);

    my $payment_system = $FORM{MODULE};
    my $require_module = _configure_load_payment_module($payment_system);

    if ($require_module->can('get_settings')) {
      my %settings = $require_module->get_settings();

      foreach my $key (sort keys %{$settings{CONF}}) {
        if($key =~ /_NAME_/){
          my $old_name = uc($FORM{OLD_NAME});
          $key =~ s/_NAME_/_$old_name\_/;
        }
        my $new_key = $key;

        if($FORM{NAME} ne $FORM{OLD_NAME}){
          my $old_name = uc($FORM{OLD_NAME});
          my $name = uc($FORM{NAME});
          $new_key =~ s/$old_name/$name/;
        }

        if ($FORM{$key} && $FORM{$key} ne '') {
          $config->config_add({ PARAM => $new_key, VALUE => $FORM{$key}, REPLACE => 1 });
        }
        else {
          $config->config_del($key);
        }

      }
    }

    $Paysys->paysys_connect_system_change({
      %FORM,
      PAYSYS_IP => $FORM{IP},
    });
  }
  elsif ($FORM{del}) {
    $Paysys->paysys_connect_system_delete({
      ID => $FORM{del},
      %FORM
    });
    _error_show($Paysys);
  }

  if ($FORM{chg}) {
    my $btn_value = $lang{CHANGE};
    my $btn_name = 'change';

    my $connect_system_info = $Paysys->paysys_connect_system_info({
      ID               => $FORM{chg},
      SHOW_ALL_COLUMNS => 1,
      COLS_NAME        => 1,
      COLS_UPPER       => 1,
    });

    my ($paysys_select, $json_list) = _paysys_select_systems($connect_system_info->{name}, $connect_system_info->{paysys_id});

    $html->tpl_show(
      _include('paysys_connect_system', 'Paysys'),
      {
        PAYSYS_SELECT => $paysys_select,
        JSON_LIST     => $json_list,
        BTN_VALUE     => $btn_value,
        BTN_NAME      => $btn_name,
        ($connect_system_info && ref $connect_system_info eq "HASH" ? %$connect_system_info : () ),
#        %$connect_system_info,
        ACTIVE        => $connect_system_info->{status},
        IP            => $connect_system_info->{paysys_ip},
        PRIORITY      => $connect_system_info->{priority},
        HIDE_SELECT   => 'hidden',
        ID            => $FORM{chg},
        PAYMENT_METHOD_SEL => _paysys_select_payment_method({PAYMENT_METHOD => $connect_system_info->{payment_method}}),
      },
    );
  }

  # table to show all systems in folder
  my $table_for_systems = $html->table(
    {
      caption => "",
      width   => '100%',
      title   =>
        [ '#', $lang{PAY_SYSTEM}, $lang{MODULE}, $lang{VERSION}, $lang{STATUS}, 'IP', $lang{PRIORITY}, $lang{PERIODIC}, $lang{REPORT}, $lang{TEST}, '', '' ],
      MENU    => "$lang{ADD}:index=$index&add_form=1:add",
      DATA_TABLE => 1,
    }
  );

  my $systems = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    COLS_NAME        => 1,
  });

  foreach my $payment_system (@$systems) {

    my $require_module = _configure_load_payment_module($payment_system->{module});
    # check if module already on new verision and has get_settings sub
    if ($require_module->can('get_settings')) {
      my %settings = $require_module->get_settings();

      my $status = $payment_system->{status} || 0;
      my $paysys_name = $payment_system->{name} || '';
      my $id = $payment_system->{id} || 0;
      my $paysys_id = $payment_system->{paysys_id} || 0;
      my $paysys_ip = $payment_system->{paysys_ip} || '';
      my $priority  = $payment_system->{priority} || 0;

      $status = (!($status) ? $html->color_mark("$lang{DISABLE}", 'danger') : $html->color_mark(
        "$lang{ENABLE}",
        'success'));

      my $change_button = $html->button("$lang{CHANGE}",
        "index=$index&MODULE=$payment_system->{module}&chg=$id&PAYSYSTEM_ID=$paysys_id",
        { class => 'change' });
      my $delete_button = $html->button("$lang{DEL}",
        "index=$index&MODULE=$payment_system->{module}&del=$id&PAYSYSTEM_ID=$paysys_id",
        { class => 'del', MESSAGE => "$lang{DEL} $paysys_name", });

      my $test_button = $lang{NOT_EXIST};
      if ($require_module->can('has_test')) {
        my $test_index = get_function_index('paysys_configure_test');
        $test_button = $html->button("$lang{START_PAYSYS_TEST}",
          "index=$test_index&MODULE=$payment_system->{module}&PAYSYSTEM_ID=$paysys_id",
          { class => 'btn btn-success btn-xs' });
      }

      $table_for_systems->addrow(
        $paysys_id,
        $paysys_name,
        $payment_system->{module},
        $settings{VERSION},
        $status,
        $paysys_ip,
        $priority,
        $require_module->can('periodic') ? $html->color_mark("$lang{YES}", 'success') : $html->color_mark("$lang{NO}",'#f04'),
        $require_module->can('report')   ? $html->color_mark("$lang{YES}", 'success') : $html->color_mark("$lang{NO}",'#f04'),
        $test_button,
        $change_button,
        $delete_button,
      );
    }

  }

  print $table_for_systems->show();

  return 1;
}

#**********************************************************
=head2 paysys_configure_test()

=cut
#**********************************************************
sub paysys_configure_test {
  if (!$FORM{MODULE}) {
    $html->message("err", "No such payment system ");
    return 1;
  }
  elsif ($FORM{MODULE} !~ /^[A-za-z0-9\_]+\.pm$/) {
    $html->message('err', "Permission denied");
  }

  my ($payment_system_name) = $FORM{MODULE} =~ /([A-za-z0-9\_]+)\.pm/;

  my $html_for_user_id = $html->element('label', $lang{USER}, { class => 'col-md-3 control-label' })
    . $html->element('div', $html->form_input("USER_ID", $FORM{USER_ID} || '', { TYPE => 'text', }),
    { class => 'col-md-9' });

  print $html->form_main(
    {
      CONTENT => $html->element('div', $html_for_user_id, { class => 'form-group' }),
      HIDDEN  => {
        index  => "$index",
        MODULE => $FORM{MODULE},
      },
      SUBMIT  => { start_test => "$lang{START_PAYSYS_TEST}" },
      NAME    => 'FORM_PAYSYS_TEST'
    }
  );

  if ($FORM{start_test} && $FORM{USER_ID}) {
    my $user_id = $FORM{USER_ID};
    my $result = cmd("perl /usr/abills/Abills/modules/Paysys/t/$payment_system_name.t $user_id");

    print $html->element('pre', $result);
  }

  return 1;
}

#**********************************************************
=head2 paysys_groups_settings() - check whats

=cut
#**********************************************************
sub paysys_configure_groups {

  if ($FORM{add_settings}) {
    # truncate settings table
    $Paysys->groups_settings_delete({});
    _error_show($Paysys);
  }

  use Users;
  my $Users = Users->new($db, $admin, \%conf);
  # get groups list
  my $groups_list = $Users->groups_list({
    COLS_NAME      => 1,
    DISABLE_PAYSYS => 0
  });

  # get payment systems list
  #  my %connected_payment_systems = paysys_system_sel({ ONLY_SYSTEMS => 1 });
  my $connected_payment_systems = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
  });

  if (ref $connected_payment_systems ne 'ARRAY' || !scalar(@$connected_payment_systems)) {
    $html->message('err', 'No payments system connected');
    return 1;
  }

  my @connected_payment_systems = ($lang{GROUPS});
  foreach my $system (sort @$connected_payment_systems) {
    push(@connected_payment_systems, $system->{name});
  }

  # table for settings
  my $table = $html->table(
    {
      width   => '100%',
      caption => "$lang{PAYSYS_SETTINGS_FOR_GROUPS}",
      title   => \@connected_payment_systems,
      ID      => 'PAYSYS_GROUPS_SETTINGS',
    }
  );

  # get settings from db
  my $list_settings = $Paysys->groups_settings_list({
    GID       => '_SHOW',
    PAYSYS_ID => '_SHOW',
    COLS_NAME => 1,
  });

  my %groups_settings = ();

  foreach my $gid_settings (@$list_settings) {
    $groups_settings{"SETTINGS_$gid_settings->{gid}_$gid_settings->{paysys_id}"} = 1;
  }

  # form rows for table
  foreach my $group (@$groups_list) {
    my @rows;
    next if $group->{disable_paysys} == 1;

    foreach my $system (sort @$connected_payment_systems) {
      my $input_name = "SETTINGS_$group->{gid}_$system->{paysys_id}";
      if ($FORM{add_settings} && $FORM{$input_name}) {
        $Paysys->groups_settings_add({
          GID       => $group->{gid},
          PAYSYS_ID => $system->{paysys_id},
        });
      }
      my $checkbox = $html->form_input("$input_name", "1",
        { TYPE => 'checkbox', STATE => (($FORM{$input_name} || $groups_settings{$input_name}) ? 'checked' : '') });

      my $settings_button = $html->button("$lang{SETTINGS}",
        "get_index=paysys_get_module_settings&MERCHANT=$group->{gid}&MODULE=$system->{module}&chg=1&PAYSYSTEM_ID=$system->{paysys_id}&NAME=$system->{name}&header=2",
        {
          class         => 'btn-xs',
          LOAD_TO_MODAL => 1,
        });
      push(@rows, "$lang{LOGON}" . $checkbox . "<br>" . $settings_button);

    }
    $table->addrow($group->{name}, @rows);
  }
  _error_show($Paysys);

  # form for sending settings
  print $html->form_main(
    {
      CONTENT => $table->show(),
      HIDDEN  => {
        index => "$index",
        #        OP_SID => "$op_sid",
      },
      SUBMIT  => { 'add_settings' => "$lang{CHANGE}" },
      NAME    => 'PAYSYS_GROUPS_SETTINGS'
    }
  );

  return 1;
}

#**********************************************************
=head2 paysys_get_module_settings($attr)

=cut
#**********************************************************
sub paysys_get_module_settings {
  #my ($attr) = @_;

  if (!$FORM{MODULE}) {
    $html->message("err", "No such payment system ");
    return 1;
  }
  elsif ($FORM{MODULE} !~ /^[A-za-z0-9\_]+\.pm$/) {
    $html->message('err', "Permission denied");
    return 1;
  }

  my $MODULE = $FORM{MODULE};
  my $merchant = $FORM{MERCHANT} ? "_$FORM{MERCHANT}" : ''; #_1, _2 ...

  my $Module_object = _configure_load_payment_module($MODULE);

  my %settings = $Module_object->get_settings();

  my $input_html = '';
  foreach my $key (sort keys % {$settings{CONF}}) {
    if($key =~ /_NAME_/ && $FORM{NAME}){
      my $name = uc($FORM{NAME});
      $key =~ s/_NAME_/_$name\_/;
    }
    if ($FORM{action}) {
      my $config = Conf->new($db, $admin, \%conf);
      if ($FORM{DELETE_MERCHANT_SETTINGS}) {
        $config->config_del($key . $merchant);
        next;
      }

      $config->config_add({ PARAM => $key . $merchant, VALUE => $FORM{$key . $merchant}, REPLACE => 1 });
      next;
    }
    my $key_value = $conf{$key . $merchant} || $settings{CONF}{$key};

    $input_html .= $html->tpl_show(
      _include('paysys_settings_input', 'Paysys'),
      {
        SETTING_LABEL => $key,
        SETTING_NAME  => $key . $merchant,
        SETTING_VALUE => $key_value,
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  $html->message('info', $lang{SUCCESS}) if ($FORM{MESSAGE_ONLY});
  return 1 if $FORM{MESSAGE_ONLY};

  my $template = $html->tpl_show(
    _include('paysys_settings_merchant', 'Paysys'),
    {
      INPUT            => $input_html,
      PAYSYSTEM_NAME   => $MODULE,
      PAYSYSTEM_ID     => $settings{ID},
      NAME             => $FORM{NAME},
      MERCHANT         => $FORM{MERCHANT},
      ACTION           => 'merchant_settings',
      AJAX_SUBMIT_FORM => 'ajax-submit-form'
    }, { OUTPUT2RETURN => 1 }
  );

  if ($FORM{RETURN_TEMPLATE}) {
    return $template
  }
  else {
    print $template;
  }

  return 1;
}

#**********************************************************
=head2 paysys_read_folder_systems()

=cut
#**********************************************************
sub _paysys_select_systems {
  my ($name, $id) = @_;
  my $systems = _paysys_read_folder_systems();

  my %HASH_TO_JSON = ();
  foreach my $system (@$systems) {
    my $Module = _configure_load_payment_module($system);
    if ($Module->can('get_settings')) {
      my %settings = $Module->get_settings();

      foreach my $key (keys %{$settings{CONF}}) {
        if(defined $name && $name ne ''){
          $name = uc($name);
          delete $settings{CONF}{$key} if $key =~ /_NAME_/;
          $key =~ s/_NAME_/_$name\_/;
          $settings{CONF}{$key} = '';

        }
      }

      @{$settings{CONF}}{keys %{$settings{CONF}}} = @conf{keys %{$settings{CONF}}};
      $settings{ID} = $id if (defined $id);
      $HASH_TO_JSON{$system} = \%settings;
    }
  }

  my $json_list = JSON->new->utf8(0)->encode(\%HASH_TO_JSON);

  return $html->form_select('MODULE',
    {
      SELECTED    => $FORM{MODULE} || '',
      SEL_ARRAY   => $systems,
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' },
    }), $json_list;
}

#**********************************************************
=head2 paysys_select_connected_systems()

=cut
#**********************************************************
sub _paysys_select_connected_systems {
  my ($attr) = @_;


  return $html->form_select('SYSTEM_ID',
    {
      SELECTED    => $attr->{SYSTEM_ID} || $FORM{SYSTEM_ID} || '',
      SEL_LIST    => $Paysys->paysys_connect_system_list({COLS_NAME => 1, ID => '_SHOW', NAME => '_SHOW'}),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' },
    });
}

#**********************************************************
=head2 _paysys_select_payment_method()

=cut
#**********************************************************
sub _paysys_select_payment_method {
  my ($attr) = @_;
  return $html->form_select('PAYMENT_METHOD',
      {
        SELECTED    => $FORM{PAYMENT_METHOD} || $attr->{PAYMENT_METHOD} || '',
        SEL_HASH   => \%PAYSYS_PAYMENTS_METHODS,
        NO_ID       => 1,
        SEL_OPTIONS => { '' => '--' },
      });
}

#**********************************************************
=head2 paysys_configure_external_commands()

=cut
#**********************************************************
sub paysys_configure_external_commands {

  my $action = 'change';
  my $action_lang = "$lang{CHANGE}";
  my %EXTERNAL_COMMANDS_SETTINGS;
  my $Config = Conf->new($db, $admin, \%conf);

  my @conf_params = ('PAYSYS_EXTERNAL_START_COMMAND', 'PAYSYS_EXTERNAL_END_COMMAND',
    'PAYSYS_EXTERNAL_ATTEMPTS', 'PAYSYS_EXTERNAL_TIME');

  if ($FORM{change}) {
    foreach my $conf_param (@conf_params) {
      $Config->config_add({ PARAM => $conf_param, VALUE => $FORM{$conf_param}, REPLACE => 1 });
    }
  }

  foreach my $conf_param (@conf_params) {
    my $param_information = $Config->config_info({ PARAM => $conf_param, DOMAIN_ID => 0 });

    $EXTERNAL_COMMANDS_SETTINGS{$conf_param} = $param_information->{VALUE};
  }

  $html->tpl_show(_include('paysys_external_commands', 'Paysys'), {
    ACTION      => $action,
    ACTION_LANG => $action_lang,
    %EXTERNAL_COMMANDS_SETTINGS
  }, { SKIP_VARS => 'IP UID' });

  return 1;
}

#**********************************************************
=head2 terminals_add() - Adding terminals with location ID

=cut
#**********************************************************
sub paysys_configure_terminals {
  my %TERMINALS;

  $TERMINALS{ACTION} = 'add';     # action on page
  $TERMINALS{BTN} = "$lang{ADD}"; # button name

  # if we want to add new terminal
  if ($FORM{ACTION} && $FORM{ACTION} eq 'add') {
    $Paysys->terminal_add(
      {
        %FORM,
        TYPE => $FORM{TERMINAL},
      }
    );
    if (!$Paysys->{errno}) {
      $html->message('success', $lang{ADDED}, "$lang{ADDED} $lang{TERMINAL}");
    }
  }

  # if we want to change terminal
  elsif ($FORM{ACTION} && $FORM{ACTION} eq 'change') {
    $Paysys->terminal_change(
      {
        %FORM,
        TYPE => $FORM{TERMINAL},
      }
    );
    if (!$Paysys->{errno}) {
      $html->message('success', $lang{CHANGED}, "$lang{CHANGED} $lang{TERMINAL}");
    }
  }

  # get info about terminl into page
  if ($FORM{chg}) {
    my $terminal_info = $Paysys->terminal_info($FORM{chg});

    $TERMINALS{ACTION} = 'change';
    $TERMINALS{COMMENT} = $terminal_info->{COMMENT};
    $TERMINALS{TYPE} = $terminal_info->{TYPE};
    $TERMINALS{BTN} = "$lang{CHANGE}";
    $TERMINALS{ID} = $FORM{chg};
    $TERMINALS{STATUS} = $terminal_info->{STATUS};
    $TERMINALS{DISTRICT_ID} = $terminal_info->{DISTRICT_ID};
    $TERMINALS{STREET_ID} = $terminal_info->{STREET_ID};
    $TERMINALS{LOCATION_ID} = $terminal_info->{LOCATION_ID};
  }

  if ($FORM{del}) {
    $Paysys->terminal_del({ ID => $FORM{del} });
    if (!$Paysys->{errno}) {
      $html->message('success', $lang{DELETED}, "$lang{TERMINAL} $lang{DELETED}");
    }
  }

  # terminal's type select
  # $TERMINALS{TERMINAL_TYPE} = $html->form_select(
  #   'TERMINAL',
  #   {
  #     SELECTED     => $TERMINALS{TYPE},
  #     SEL_ARRAY    => \@TERMINAL_TYPES,
  #     ARRAY_NUM_ID => 1,
  #     SEL_OPTIONS  => { '' => '--' },
  #   }
  # );

  $TERMINALS{TERMINAL_TYPE} = $html->form_select(
    'TERMINAL',
    {
      SELECTED    => $TERMINALS{TYPE},
      SEL_LIST    => $Paysys->terminal_type_list({ NAME => '_SHOW' }),
      SEL_KEY     => 'id',
      SEL_VALUE   => 'name',
      # ARRAY_NUM_ID => 1,
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' },
      MAIN_MENU   => get_function_index('terminals_type_add'),
    }
  );

  $TERMINALS{STATUS} = $html->form_select(
    'STATUS',
    {
      SELECTED     => $TERMINALS{STATUS},
      SEL_ARRAY    => \@TERMINAL_STATUS,
      ARRAY_NUM_ID => 1,
      SEL_OPTIONS  => { '' => '--' },
      # MAIN_MENU    => get_function_index('terminals_type_add'),
    }
  );

  use Address;
  my $Address = Address->new($db, $admin, \%conf);
  my %user_pi = ();
  if ($TERMINALS{DISTRICT_ID}) {
    $user_pi{ADDRESS_DISTRICT} = ($Address->district_info({ ID => $TERMINALS{DISTRICT_ID} }))->{NAME};
  }

  if ($TERMINALS{STREET_ID}) {
    $user_pi{ADDRESS_STREET} = ($Address->street_info({ ID => $TERMINALS{STREET_ID} }))->{NAME};
  }

  if ($TERMINALS{LOCATION_ID}) {
    $user_pi{ADDRESS_BUILD} = ($Address->build_info({ ID => $TERMINALS{LOCATION_ID} }))->{NUMBER};
  }

  $TERMINALS{ADRESS_FORM} = $html->tpl_show(
    templates('form_address_search'),
    {
      %user_pi,
      DISTRICT_ID => $TERMINALS{DISTRICT_ID},
      STREET_ID   => $TERMINALS{STREET_ID},
      LOCATION_ID => $TERMINALS{LOCATION_ID},
    },
    { OUTPUT2RETURN => 1 }
  );

  $html->tpl_show(_include('paysys_terminals_add', 'Paysys'), \%TERMINALS);
  result_former(
    {
      INPUT_DATA      => $Paysys,
      FUNCTION        => 'terminal_list',
      DEFAULT_FIELDS  => 'ID, TYPE, COMMENT, STATUS, DIS_NAME, ST_NAME, BD_NUMBER',
      FUNCTION_FIELDS => 'change,del',
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        id        => '#',
        type      => $lang{TYPE},
        comment   => $lang{COMMENTS},
        status    => $lang{STATUS},
        dis_name  => $lang{DISTRICT},
        st_name   => $lang{STREET},
        bd_number => $lang{BUILD},
      },
      #SELECT_VALUE => {
      #  type => {
      #    0 => $TERMINAL_TYPES[0],
      #    1 => $TERMINAL_TYPES[1]
      #  },
      #  status => {
      #    0 => $TERMINAL_STATUS[0],
      #    1 => $TERMINAL_STATUS[1]
      #  },
      #},
      TABLE           => {
        width   => '100%',
        caption => "$lang{TERMINALS}",
        qs      => $pages_qs,
        pages   => $Paysys->{TOTAL},
        ID      => 'PAYSYS_TERMINLS',
        MENU    => "$lang{ADD}:add_form=1&index=" . $index . ':add' . ";",
        EXPORT  => 1
      },
      MAKE_ROWS       => 1,
      TOTAL           => 1
    }
  );

  return 1;
}

#**********************************************************
=head2 terminals_type_add() - add new terminal types

=cut
#**********************************************************
sub paysys_configure_terminals_type {
  #my ($attr) = @_;

  my %TERMINALS;

  $TERMINALS{ACTION} = 'add';     # action on page
  $TERMINALS{BTN} = "$lang{ADD}"; # button name

  if ($FORM{ACTION} && $FORM{ACTION} eq 'add') {
    $Paysys->terminals_type_add({ %FORM });

    if (!$Paysys->{errno}) {
      $html->message('info', $lang{ADDED}, $lang{SUCCESS});

      if ($FORM{UPLOAD_FILE}) {
        upload_file($FORM{UPLOAD_FILE}, { PREFIX => '/terminals/',
          FILE_NAME                              => 'terminal_' . $Paysys->{INSERT_ID} . '.png', });
      }
    }
    else {
      $html->message('err', $lang{ERROR});
    }
  }
  elsif ($FORM{ACTION} && $FORM{ACTION} eq 'change') {
    $Paysys->terminal_type_change({ %FORM });

    if (!$Paysys->{errno}) {
      $html->message('info', $lang{CHANGED}, $lang{SUCCESS});
      if ($FORM{UPLOAD_FILE}) {
        upload_file($FORM{UPLOAD_FILE}, { PREFIX => '/terminals/',
          FILE_NAME                              => 'terminal_' . $FORM{ID} . '.png',
          REWRITE                                => 1 });
      }
    }
    else {
      $html->message('err', $lang{ERROR});
    }
  }

  if ($FORM{del}) {
    $Paysys->terminal_type_delete({ ID => $FORM{del} });

    if (!$Paysys->{errno}) {
      $html->message('info', $lang{DELETED}, $lang{SUCCESS});
      my $filename = "$conf{TPL_DIR}/terminals/terminal_$FORM{del}.png";
      if (-f $filename) {
        unlink("$filename") or die "Can't delete $filename:  $!\n";
      }
    }
    else {
      $html->message('err', $lang{ERROR});
    }
  }

  if ($FORM{chg}) {
    $TERMINALS{ACTION} = 'change';
    $TERMINALS{BTN} = "$lang{CHANGE}";

    my $type_info = $Paysys->terminal_type_info($FORM{chg});

    $TERMINALS{COMMENT} = $type_info->{COMMENT};
    $TERMINALS{NAME} = $type_info->{NAME};
    $TERMINALS{ID} = $FORM{chg}
  }

  $html->tpl_show(_include('paysys_terminals_type_add', 'Paysys'), \%TERMINALS);

  result_former(
    {
      INPUT_DATA      => $Paysys,
      FUNCTION        => 'terminal_type_list',
      DEFAULT_FIELDS  => 'ID, NAME, COMMENT',
      FUNCTION_FIELDS => 'change,del',
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        id      => '#',
        name    => $lang{NAME},
        comment => $lang{COMMENTS},

      },
      #SELECT_VALUE => {
      #  type => {
      #    0 => $TERMINAL_TYPES[0],
      #    1 => $TERMINAL_TYPES[1]
      #  },
      #  status => {
      #    0 => $TERMINAL_STATUS[0],
      #    1 => $TERMINAL_STATUS[1]
      #  },
      #},
      TABLE           => {
        width   => '100%',
        caption => "$lang{TERMINALS} $lang{TYPE}",
        qs      => $pages_qs,
        pages   => $Paysys->{TOTAL},
        ID      => 'PAYSYS_TERMINLS_TYPES',
        #MENU    => "$lang{ADD}:add_form=1&index=" . $index . ':add' . ";",
        EXPORT  => 1
      },
      MAKE_ROWS       => 1,
      TOTAL           => 1
    }
  );

  return 1;
}

#**********************************************************
=head2 paysys_read_folder_systems($payment_system)

=cut
#**********************************************************
sub _configure_load_payment_module {
  my ($payment_system) = @_;

  if (!$payment_system) {
    return 0;
  }

  my ($paysys_name) = $payment_system =~ /(.+)\.pm/;

  my $require_module = "Paysys::systems::$paysys_name";

  eval {require "Paysys/systems/$payment_system";};

  if (!$@) {
    $require_module->import($payment_system);
  }
  else {
    print "Error loading\n";
    print $@;
  }

  return $require_module;
}

1;