#**********************************************************
=head1 NAME

  Admin manage functions

=cut


use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array);
use Abills::Defs;

our $db;
our $admin;
our $html;
our %lang;
our @WEEKDAYS;
our @MONTHES;
our @status;

#**********************************************************
=head2 form_admins() - Admins mange form

=cut
#**********************************************************
sub form_admins {

  my $Employees;

  if( in_array('Employees', \@MODULES) ){
    load_module("Employees", $html);
    $Employees = Employees->new($db, $admin, \%conf);
  }
  my $admin_form = Admins->new($db, \%conf);
  $admin_form->{ACTION}     = 'add';
  $admin_form->{LNG_ACTION} = $lang{ADD};

  if ($FORM{AID}) {
    $admin_form->info($FORM{AID});
    _error_show($admin_form);

    if(! $FORM{DOMAIN_ID}) {
      $FORM{DOMAIN_ID}  = $admin_form->{DOMAIN_ID} if($admin_form->{DOMAIN_ID});
    }

    $pages_qs         = "&AID=$admin_form->{AID}". (($FORM{subf}) ? "&subf=$FORM{subf}" : '');

    my $A_LOGIN = $html->form_main({
        CONTENT => $html->form_select(
          'AID',
          {
            SELECTED  => $FORM{AID},
            SEL_LIST  => $admin->list({%LIST_PARAMS, COLS_NAME => 1}),
            SEL_KEY   => 'aid',
            SEL_VALUE => 'login,name',
          }
        ),
        HIDDEN => {
          index => $index,
          subf  => $FORM{subf}
        },
        SUBMIT => { show => $lang{SHOW} },
        class  => 'navbar-form navbar-right',
    });

    $LIST_PARAMS{AID} = $admin_form->{AID};
    my @admin_menu = (
      $lang{INFO}       . "::AID=$admin_form->{AID}:change",
      $lang{LOG}        . ':'. get_function_index('form_changes') . ":AID=$admin_form->{AID}:history",
      $lang{FEES}       . ":3:AID=$admin_form->{AID}:fees",
      $lang{PAYMENTS}   . ":2:AID=$admin_form->{AID}:payments",
      $lang{PERMISSION} . ":52:AID=$admin_form->{AID}:permissions",
      $lang{PASSWD}     . ":54:AID=$admin_form->{AID}:password",
      $lang{GROUP}      . ":58:AID=$admin_form->{AID}:users",
      $lang{ACCESS}     . ":59:AID=$admin_form->{AID}:",
      'Paranoid'   . ':'. get_function_index('form_admins_full_log') .":AID=$admin_form->{AID}:",
      $lang{CONTACTS}   . ":61:AID=$admin_form->{AID}:contacts",
      $lang{DOMAINS}    . ":113:AID=$admin_form->{AID}:contacts",
    );

    if(in_array('Msgs', \@MODULES)) {
      push @admin_menu, "$lang{MESSAGES}:".get_function_index('msgs_admin') .":AID=$admin_form->{AID}:msgs";
    }

    func_menu(
      {
        $lang{NAME} => $A_LOGIN
      },
      \@admin_menu,
      { f_args => { ADMIN => $admin_form } }
    );

    form_passwd({ ADMIN => $admin_form }) if (defined($FORM{newpassword}));

    if ($FORM{subf}) {
      return 0;
    }
    elsif ($FORM{change}) {
      $admin_form->{MAIN_SESSION_IP} = $admin->{SESSION_IP};

      # Check it was default password
      if ($FORM{newpassword} && !$conf{DEFAULT_PASSWORD_CHANGED} && $FORM{AID} == 1 && $FORM{newpassword} ne 'abills'){
        $Conf->config_add({ PARAM => 'DEFAULT_PASSWORD_CHANGED', VALUE => 1, REPLACE => 1});
        _error_show($Conf);
        $conf{DEFAULT_PASSWORD_CHANGED} = 1;
      }

      $admin_form->change({%FORM});
      if (!$admin_form->{errno}) {
        $html->message('info', $lang{CHANGED}, "$lang{CHANGED} ");
      }
    }
    $admin_form->{ACTION}     = 'change';
    $admin_form->{LNG_ACTION} = $lang{CHANGE};
  }
  elsif ($FORM{add}) {
    $admin_form->{AID} = $admin->{AID};
    if (!$FORM{A_LOGIN}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} $lang{ADMIN} $lang{LOGIN}");
    }
    else {
      $admin_form->add({ %FORM, DOMAIN_ID => $FORM{DOMAIN_ID} || $admin->{DOMAIN_ID} });
      if (!$admin_form->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{ADDED}");
      }
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    if ($FORM{del} == $conf{SYSTEM_ADMIN_ID}) {
      $html->message('err', $lang{ERROR}, "Can't delete system admin. Check " . '$conf{SYSTEM_ADMIN_ID}=1;');
    }
    else {
      $admin_form->{AID} = $admin->{AID};
      $admin_form->del($FORM{del});
      if (!$admin_form->{errno}) {
        $html->message('info', $lang{DELETED}, "$lang{DELETED}");
      }
    }
  }
  elsif($FORM{REGISTER_TELEGRAM}){
    $admin_form->change({AID => $admin->{AID}, TELEGRAM_ID => $FORM{telegram_id}});
    $html->message("info", $lang{SUCCESS}, "Telegram ID $lang{ADDED}");
    return 1;
  }

  _error_show($admin_form);

  $admin_form->{PASPORT_DATE} = $html->date_fld2(
    'PASPORT_DATE',
    {
      FORM_NAME => 'admin_form',
      WEEK_DAYS => \@WEEKDAYS,
      MONTHES   => \@MONTHES,
      #DATE      => $user_pi->{PASPORT_DATE}
    }
  );

  if( in_array('Employees', \@MODULES)){
    $admin_form->{POSITIONS} = $html->form_select(
      'POSITION',
      {
        SELECTED    => $FORM{POSITION} || $admin_form->{POSITION},
        SEL_LIST    => $Employees->position_list({ COLS_NAME => 1 }),
        SEL_KEY     => 'id',
        SEL_VALUE   => 'position',
        NO_ID       => 1,
        SEL_OPTIONS => { '' => '--' },
      }
    );
  }

  $admin_form->{FULL_LOG}  = ($admin_form->{FULL_LOG}) ? 'checked' : '';
  $admin_form->{DISABLE}   = ( defined($admin_form->{DISABLE}) && $admin_form->{DISABLE} > 0) ? 'checked' : '';
  $admin_form->{GROUP_SEL} = sel_groups({ GID => $admin_form->{GID}, SKIP_MUULTISEL => 1 });

  if ($admin->{DOMAIN_ID}) {
    $admin_form->{DOMAIN_SEL} = $admin->{DOMAIN_NAME};
  }
  elsif (in_array('Multidoms', \@MODULES)) {
    load_module('Multidoms', $html);
    $admin_form->{DOMAIN_SEL} = multidoms_domains_sel({ SHOW_ID => 1 });
  }
  else {
    $admin_form->{DOMAIN_SEL} = '';
  }

  #check if have GPS modules and position. If so, show a link to map
  if (in_array('Maps', \@MODULES) && $admin_form->{GPS_IMEI} && $admin_form->{GPS_IMEI} ne ''){
    my $maps_index = get_function_index('maps_show_poins');
    my $link = "?index=$maps_index&show_gps=$admin_form->{AID}";
    $admin_form->{GPS_ROUTE_BTN} = $html->button($html->element('span', '', { class=> 'glyphicon glyphicon-globe' }), undef , {
         GLOBAL_URL => $link,
         target     => '_blank',
         class      => 'btn btn-info',
         NO_LINK_FORMER => 1
    });

    $admin_form->{GPS_ICON_BTN} = $html->button($html->element('span', '', { class => 'glyphicon glyphicon-picture' }), undef , {
         GLOBAL_URL     => $link,
         class          => 'btn btn-default',
         NO_LINK_FORMER => 1,
         JAVASCRIPT     => '#',
         ex_params      => qq/onclick='loadToModal("?get_index=gps_add_thumbnail&header=2&AID=$FORM{AID}")'/,
         SKIP_HREF      => 1
    });
  }
  $admin_form->{INDEX} = 50;
  $html->tpl_show(templates('form_admin'), $admin_form);

  my $list = $admin_form->admins_groups_list({ ALL => 1, COLS_NAME => 1 });
  my %admin_groups = ();
  foreach my $line (@$list) {
    $admin_groups{ $line->{aid} } .= ", $line->{gid}:$line->{name}";
  }

  delete($LIST_PARAMS{AID});
  delete $admin_form->{COL_NAMES_ARR};

  if(in_array('Employees', \@MODULES)){
    $admin_form->{SHOW_EMPLOYEES} = 1;
  }

  my Abills::HTML $table;
  my $admins_list;
  ($table, $admins_list) = result_former({
    INPUT_DATA      => $admin_form,
    FUNCTION        => 'list',
    BASE_FIELDS     => 4,
    FUNCTION_FIELDS => 'permission,log,passwd,info,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      name           => $lang{FIO},
      position       => $lang{POSITION},
      regdate 	     => $lang{REGISTRATION},
      disable        => $lang{STATUS},
      aid            => '#',
      g_name         => $lang{GROUPS},
      domain_name    => 'Domain',
      start_work     => $lang{BEGIN},
      gps_imei       => 'GPS IMEI',
      birthday       => $lang{BIRTHDAY},
      api_key        => 'API_KEY',
      telegram_id    => 'Telegram ID',
    },
    TABLE => {
      width      => '100%',
      caption    => $lang{ADMINS},
      qs         => $pages_qs,
      ID         => 'ADMINS_LIST',
      MENU       => "$lang{SEARCH}:search_form=1&index=$index:search"
    }
  });

  foreach my $line (@$admins_list) {
    my @fields_array = ();
    for (my $i = 0; $i < 4+$admin_form->{SEARCH_FIELDS_COUNT}; $i++) {
      my $field_name = $admin_form->{COL_NAMES_ARR}->[$i] || '';

      if ( $field_name eq 'disable' && $line->{disable} =~ /\d+/ ){
        $line->{disable} = $status[ $line->{disable} ];
      }
      elsif($field_name eq 'gname') {
        $line->{gname} .= $admin_groups{ $line->{aid} },
      }

      push @fields_array, $line->{$field_name};
    }

    my $geo_button = '';
    if(in_array('Employees', \@MODULES)){
      $geo_button = $html->button($lang{GEO}, "index=" . get_function_index('employees_geolocation') ."&eid=$line->{aid}")
    }

    $table->addrow(@fields_array,
      $html->button($lang{PERMISSION}, "index=$index&subf=52&AID=$line->{aid}", { class => 'permissions' })
      . $geo_button
      . $html->button($lang{LOG},        "index=$index&subf=51&AID=$line->{aid}", { class => 'history' })
      . $html->button($lang{PASSWD},     "index=$index&subf=54&AID=$line->{aid}", { class => 'password' })
      . $html->button($lang{INFO},       "index=$index&AID=$line->{aid}",         { class => 'change' })
      . $html->button($lang{DEL},        "index=$index&del=$line->{aid}", { MESSAGE => "$lang{DEL} $line->{aid}?", class => 'del' })
    );
  }

  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right' ],
      rows       => [ [ "$lang{TOTAL}:", $html->b($admin_form->{TOTAL}) ] ]
    }
  );
  print $table->show();

  system_info();

  return 1;
}

#**********************************************************
=head2 form_admins_group($attr);

=cut
#**********************************************************
sub form_admins_groups {
  my ($attr) = @_;

  if (!defined($attr->{ADMIN})) {
    $FORM{subf} = 58;
    form_admins();
    return 1;
  }

  my Admins $admin_ = $attr->{ADMIN};

  if ($FORM{change}) {
    $admin_->admin_groups_change({%FORM});
    if (_error_show($admin_)) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED} GID: [$FORM{GID}]");
    }
  }

  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{GROUP},
      title      => [ 'ID', $lang{NAME} ],
      cols_align => [ 'left', 'left', 'center' ],
    }
  );

  my $list = $admin_->admins_groups_list({ AID => $LIST_PARAMS{AID} });
  my %admins_group_hash = ();

  foreach my $line (@$list) {
    $admins_group_hash{ $line->[0] } = 1;
  }

  $list = $users->groups_list({ DOMAIN_ID => $admin_->{DOMAIN_ID} || undef });
  foreach my $line (@$list) {
    $table->addrow($html->form_input('GID', $line->[0], { TYPE => 'checkbox', STATE => (defined($admins_group_hash{ $line->[0] })) ? 'checked' : undef }) . $line->[0],
      $line->[1]);
  }

  print $html->form_main(
    {
      CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
      HIDDEN  => {
        index => $index,
        AID   => $FORM{AID},
        subf  => $FORM{subf}
      },
      SUBMIT => { change => "$lang{CHANGE}" }
    }
  );

  return 1;
}

#**********************************************************
=head2 form_admins_full_log($attr) - Admin fulll log

=cut
#**********************************************************
sub form_admins_full_log {
  my ($attr) = @_;

  if (!defined($attr->{ADMIN})) {
    $FORM{subf} = get_function_index('form_admins_full_log');
    form_admins();
    return 1;
  }

  my Admins $admin_ = $attr->{ADMIN};
  $admin_->{ACTION} = 'add';
  $admin_->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $admin_->full_log_add( { %FORM } );
    if (!$admin_->{errno}) {
      $html->message( 'info', $lang{ADDED}, "$lang{ADDED} $FORM{IP}" );
    }
  }
  elsif ($FORM{change}) {
    $admin_->full_log_change( { %FORM } );
    if (!$admin_->{errno}) {
      $html->message( 'info', $lang{ADDED}, "$lang{CHANGED} $FORM{IP}" );
    }
  }
  elsif ($FORM{chg}) {
    $admin_->full_log_info( $FORM{chg}, { %FORM } );
    if (!$admin_->{errno}) {
      $html->message( 'info', $lang{ADDED}, "$lang{INFO} $FORM{IP}" );
      $admin_->{ACTION} = 'change';
      $admin_->{LNG_ACTION} = $lang{CHANGE};
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $admin_->full_log_del( { ID => $FORM{del} } );
    if (!$admin_->{errno}) {
      $html->message( 'info', $lang{INFO}, "$lang{DELETED} [$FORM{del}]" );
    }
  }

  _error_show($admin_);

  if ($FORM{search_form}) {
    form_search({
      HIDDEN_FIELDS => {
        subf => $FORM{subf},
        AID  => $FORM{AID}
      }
    });
  }

  if (! $FORM{sort}) {
    $LIST_PARAMS{SORT}=1;
    $LIST_PARAMS{DESC}='desc';
  }

  result_former({
    INPUT_DATA      => $admin_,
    FUNCTION        => 'full_log_list',
    DEFAULT_FIELDS  => 'DATETIME,FUNCTION_NAME,PARAMS,IP,SID',
    FUNCTION_FIELDS => 'change,del',
    SELECT_VALUE    => {
                         disable => { 0 => $lang{ENABLE}, 1 => $lang{DISABLE} }  },
    TABLE => {
      width    => '100%',
      caption  => "Paranoid log",
      ID       => 'ADMIN_PARANOID_LOG',
      qs       => "&AID=$FORM{AID}&subf=$FORM{subf}",
      EXPORT   => 1,
      MENU     => "$lang{SEARCH}:search_form=1&index=$index&AID=$FORM{AID}&subf=$FORM{subf}:search"
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 form_admins_access($attr);

=cut
#**********************************************************
sub form_admins_access {
  my ($attr) = @_;

if(! defined($attr->{ADMIN})) {
  $FORM{subf}=59;
  form_admins();
  return 1;
}

my Admins $admin_ = $attr->{ADMIN};
$admin->{ACTION}='add';
$admin->{LNG_ACTION}=$lang{ADD};

if ($FORM{add}) {
  $admin_->access_add({ %FORM });
  if (! $admin_->{errno}) {
    $html->message('info', $lang{ADDED}, "$lang{ADDED} $FORM{IP}");
  }
}
elsif ($FORM{change}) {
  $admin_->access_change({ %FORM });
  if (! $admin_->{errno}) {
    $html->message('info', $lang{ADDED}, "$lang{CHANGED} $FORM{IP}");
  }
}
elsif ($FORM{chg}) {
  $admin_->access_info($FORM{chg}, { %FORM });
  if (! $admin_->{errno}) {
    $html->message('info', $lang{ADDED}, "$lang{INFO} $FORM{IP}");
    $admin_->{ACTION}='change';
    $admin_->{LNG_ACTION}=$lang{CHANGE};
  }
}
elsif ($FORM{del} && $FORM{COMMENTS}) {
  $admin_->access_del({ ID => $FORM{del} });
  if (! $admin_->{errno}) {
    $html->message('info', $lang{INFO}, "$lang{DELETED} [$FORM{del}]");
  }
}
else {
  $admin_->{BEGIN} = '00:00:00';
  $admin_->{END}   = '24:00:00';
  $admin_->{IP}    = '0.0.0.0';
}

_error_show($admin_);

my %DAY_NAMES = (
  0 => "$lang{ALL}",
  1 => "$WEEKDAYS[7]",
  2 => "$WEEKDAYS[1]",
  3 => "$WEEKDAYS[2]",
  4 => "$WEEKDAYS[3]",
  5 => "$WEEKDAYS[4]",
  6 => "$WEEKDAYS[5]",
  7 => "$WEEKDAYS[6]",
  8 => "$lang{HOLIDAYS}");

$admin_->{SEL_DAYS} = $html->form_select(
      'DAY',
      {
        SELECTED     => $admin_->{DAY} || $FORM{DAY} || 0,
        SEL_HASH     => \%DAY_NAMES,
        ARRAY_NUM_ID => 1
      }
    );

$admin_->{BIT_MASK_SEL} = $html->form_select(
    'BIT_MASK',
    {
      SELECTED  => $admin_->{BIT_MASK} || $FORM{BIT_MASK} || 0,
      SEL_ARRAY => [0..32],
    }
  );

  $admin_->{DISABLE}=($admin_->{DISABLE}) ? 'checked' : '';

  $html->tpl_show(templates('form_admin_access'), $admin_);

  result_former({
    INPUT_DATA      => $admin_,
    FUNCTION        => 'access_list',
    BASE_FIELDS     => 6,
    FUNCTION_FIELDS => 'change,del',
    SELECT_VALUE    => { day     => \%DAY_NAMES,
                         disable => { 0 => $lang{ENABLE}, 1 => $lang{DISABLE} }  },
    TABLE => {
      width    => '100%',
      caption  => "$lang{ADMIN} $lang{ACCESS}",
      ID       => 'ADMIN_ACCESS',
      qs       => "&AID=$FORM{AID}&subf=$FORM{subf}"
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 form_admin_permissions($attr); - Admin permitions

=cut
#**********************************************************
sub form_admin_permissions {
  my ($attr) = @_;

  my @actions = (
    [ $lang{INFO}, $lang{ADD}, $lang{LIST}, $lang{PASSWD}, $lang{CHANGE}, $lang{DEL}, $lang{ALL}, $lang{MULTIUSER_OP}, "$lang{SHOW} $lang{DELETED}",
     $lang{CREDIT},
     $lang{TARIF_PLANS},
     $lang{REDUCTION},
     "$lang{DISABLE} $lang{DEPOSIT}",
     "$lang{CONFIRM} $lang{ACTION}",
     "$lang{DELETED} $lang{SERVICE}",
     "$lang{CHANGE} $lang{BILL}",
     $lang{COMPENSATION},
     $lang{EXPORT},
     $lang{STATUS}, #18
     "$lang{ACTIVATE} $lang{DATE}",
     "$lang{EXPIRE} $lang{DATE}",
     $lang{BONUS},
     "PORT CONTROL", # 22
     "DEVICE REBOOT",
    ],    # Users
    [ $lang{LIST}, $lang{ADD}, $lang{DEL}, $lang{ALL}, $lang{DATE} ],   # Payments
    [ $lang{LIST}, $lang{GET}, $lang{DEL}, $lang{ALL} ],           # Fees
    [ $lang{LIST}, $lang{DEL}, $lang{PAYMENTS}, $lang{FEES}, $lang{EVENTS}, $lang{SYSTEM}, ],     # reports view
    [ $lang{LIST}, $lang{ADD}, $lang{CHANGE}, $lang{DEL}, $lang{ADMINS},
   "$lang{SYSTEM} $lang{LOG}", $lang{DOMAINS}, "$lang{TEMPLATES} $lang{CHANGE}", 'REBOOT SERVICE' ],            # system magment
    [ $lang{MONITORING}, $lang{HANGUP} ],
    [ $lang{SEARCH} ],                                # Search
    [ $lang{ALL} ],                                   # Modules managments
    [ $lang{PROFILE} ],
    [ $lang{LIST}, $lang{ADD}, $lang{CHANGE}, $lang{DEL} ],
  );

  my %permits = ();

  if (!defined($attr->{ADMIN})) {
    $FORM{subf} = 52;
    form_admins();
    return 1;
  }

  my Admins $admin_ = $attr->{ADMIN};

  if ($FORM{set}) {
    while (my ($k, $v) = each(%FORM)) {
      if ($v eq '1') {
        my ($section_index, $action_index) = split(/_/, $k, 2);
        $permits{$section_index}{$action_index} = 1 if (defined($section_index) && defined($action_index));
          #if ($section_index =~ /^\d+$/ && $section_index >= 0);
      }
    }

    $admin_->{MAIN_AID}        = $admin->{AID};
    $admin_->{MAIN_SESSION_IP} = $admin->{SESSION_IP};
    $admin_->set_permissions(\%permits);

    if (! _error_show($admin_)) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }

  my $p = $admin_->get_permissions();
  if (_error_show($admin_)) {
    return 0;
  }

  my %ADMIN_TYPES = (
    1 => "$lang{ALL} $lang{PERMISSION}",
    2 => "$lang{MANAGER}",
    3 => "$lang{SUPPORT}",
    4 => "$lang{ACCOUNTANT}",
  );

  if ($FORM{ADMIN_TYPE}) {
    my %admins_type_permits = ();
    my %admins_modules      = ();

    $admins_type_permits{1} = {
      0 => {
        0  => 1,
        1  => 1,
        2  => 1,
        3  => 1,
        4  => 1,
        5  => 1,
        6  => 1,
        7  => 1,
        8  => 1,
        9  => 1,
        10 => 1,
        11 => 1,
        #12 => 1,
        #13 => 1,
        14 => 1,
        16 => 1,
        17 => 1
      },
      1 => {
        0 => 1,
        1 => 1,
        2 => 1,
        3 => 1,
        4 => 1
      },
      2 => {
        0 => 1,
        1 => 1,
        2 => 1,
        3 => 1
      },
      3 => {
        0 => 1,
        1 => 1,
        2 => 1,
        3 => 1
      },
      4 => {
        0 => 1,
        1 => 1,
        2 => 1,
        3 => 1,
        4 => 1,
        5 => 1,
        6 => 1
      },
      5 => {
        0 => 1,
        1 => 1
      },
      6 => { 0 => 1 },
      7 => { 0 => 1 },
      8 => { 0 => 1 },
    };

    $admins_type_permits{2} = {
      0 => {
        0  => 1,
        1  => 1,
        2  => 1,
        3  => 1,
        4  => 1,
        9  => 1,
        10 => 1,
        11 => 1
      },
      1 => {
        0 => 1,
        1 => 1,
      },
      2 => {
        0 => 1,
        1 => 1,
      },
      5 => {
        0 => 1,
        1 => 1
      },
      6 => { 0 => 1 },
      7 => { 0 => 1 },
      8 => { 0 => 1 },
    };

    $admins_type_permits{3} = {
      0 => {
        0 => 1,
        2 => 1,
      },
      5 => {
        0 => 1,
        1 => 1
      },
      6 => { 0 => 1 },
      7 => { 0 => 1 },
      8 => { 0 => 1 },
    };

    $admins_modules{3} = {
      'Msgs'      => 1,
      'Maps'      => 1,
      'Snmputils' => 1,
      'Notepad'   => 1
    };

    $admins_type_permits{4} = {
      0 => {
        0 => 1,
        2 => 1,
      },
      1 => {
        0 => 1,
        1 => 1,
        2 => 1,
        3 => 1,
        4 => 1
      },
      2 => {
        0 => 1,
        1 => 1,
        2 => 1,
        3 => 1
      },
      3 => {
        0 => 1,
        1 => 1
      },
      6 => { 0 => 1 },
      7 => { 0 => 1 },
      8 => { 0 => 1 },
    };

    $admins_modules{4} = {
      'Docs'    => 1,
      'Paysys'  => 1,
      'Cards'   => 1,
      'Extfin'  => 1,
      'Notepad' => 1
    };

    %permits = %{ $admins_type_permits{ $FORM{ADMIN_TYPE} } };
    $admin_->{MODULES} = $admins_modules{ $FORM{ADMIN_TYPE} };
  }
  else {
    %permits = %$p;
  }

  foreach my $k (sort keys(%ADMIN_TYPES)) {
    my $button = ($FORM{ADMIN_TYPE} && $FORM{ADMIN_TYPE} eq $k) ? $html->b($ADMIN_TYPES{$k} . ' ') : $html->button($ADMIN_TYPES{$k}, "index=$index" .
    ( ($FORM{subf}) ? "&subf=$FORM{subf}" : '' ) ."&AID=$FORM{AID}&ADMIN_TYPE=$k", { BUTTON => 1 }) . '  ';
    print $button;
  }

  my $table = $html->table(
    {
      width       => '90%',
      caption     => "$lang{PERMISSION}",
      title_plain => [ 'ID', $lang{NAME}, $lang{DESCRIBE}, '-' ],
      cols_align  => [ 'right', 'left', 'center' ],
      ID          => 'ADMIN_PERMISSIONS',
    }
  );

  foreach my $k (sort keys %menu_items) {

    #my $v = $menu_items{$k};

    if (defined($menu_items{$k}{0}) && $k > 0) {
      next if ($k == 10);

      $table->{rowcolor} = 'active';
      $table->addrow("$k:", $html->b($menu_items{$k}{0}), '', '');
      $k--;

      my $actions_list = $actions[$k];
      my $action_index = 0;
      $table->{rowcolor} = undef;
      foreach my $action (@$actions_list) {
        $table->addrow(
          "$action_index",
          "$action",
          '',
          $html->form_input(
            $k . "_$action_index",
            1,
            {
              TYPE          => 'checkbox',
              OUTPUT2RETURN => 1,
              STATE         => (defined($permits{$k}{$action_index})) ? '1' : undef
            }
          )
        );

        $action_index++;
      }
    }
  }

  if (in_array('Multidoms', \@MODULES)) {
    my $k = 10;
    $table->{rowcolor} = 'active';
    $table->addrow("10:", $html->b($lang{DOMAINS}), '', '');
    my $actions_list = $actions[9];
    my $action_index = 0;
    $table->{rowcolor} = undef;
    foreach my $action (@$actions_list) {
      $table->addrow(
        "$action_index",
        "$action",
        '',
        $html->form_input(
          $k . "_$action_index",
          1,
          {
            TYPE          => 'checkbox',
            OUTPUT2RETURN => 1,
            STATE         => (defined($permits{$k}{$action_index})) ? '1' : undef
          }
        )
      );
      $action_index++;
    }
  }

  my $table2 = $html->table(
    {
      width       => '500',
      caption     => "$lang{MODULES}",
      title_plain => [ $lang{NAME}, $lang{VERSION}, '' ],
      cols_align  => [ 'left', 'left', 'center' ],
      ID          => 'ADMIN_MODULES'
    }
  );

  my $i = 0;
  my $version = '';
  foreach my $name (sort @MODULES) {
    $table2->addrow(
      $html->button("$name", '',
         { GLOBAL_URL => 'http://abills.net.ua/wiki/doku.php?id=abills:docs:modules:'. $name .':ru',
           ex_params  => 'target='.$name } ),
      $version,
      $html->form_input(
        "9_" . $i . "_" . $name,
        '1',
        {
          TYPE          => 'checkbox',
          OUTPUT2RETURN => 1,
          STATE         => ($admin_->{MODULES}{$name}) ? '1' : undef
        }
      )
    );
    $i++;
  }

  print $html->form_main(
    {
      CONTENT => $table->show({ OUTPUT2RETURN => 1 }) . $table2->show({ OUTPUT2RETURN => 1 }),
      HIDDEN  => {
        index => '50',
        AID   => $FORM{AID},
        subf  => $FORM{subf}
      },
      SUBMIT => { set => "$lang{SET}" }
    }
  );

  return 1;
}

#**********************************************************

=head2 form_admins_contacts($attr);

=cut

#**********************************************************
sub form_admins_contacts {
  my ($attr) = @_;

  my @priority = ($lang{VERY_LOW}, $lang{LOW}, $lang{NORMAL}, $lang{HIGH}, $lang{VERY_HIGH});
  my @priority_colors = ('#8A8A8A', '#3d3938', '#1456a8', '#E06161', 'red');

  if (!defined($FORM{AID})) {
    $FORM{subf} = 61;
    form_admins();
    return 1;
  }

  if ( $FORM{CONTACTS} ){
    return admin_contacts_renew();
  }

  my $table = $html->table(
    {
      width       => '100',
      caption     => "$lang{CONTACTS}",
      title_plain => [ $lang{NAME}, $lang{PRIORITY}, $lang{VALUE} ],
      cols_align  => [ 'left', 'left', 'center' ],
      ID          => 'ADMIN_CONTACTS'
    }
  );

  my $list = $admin->admins_contacts_list(
    {
      AID       => $FORM{AID},
      VALUE     => '_SHOW',
      PRIORITY  => '_SHOW',
      TYPE      => '_SHOW',
      HIDDEN    => '0'
    }
  );

  my $contacts_type_list = $admin->admins_contacts_type_list(
    {
      SHOW_ALL_COLUMNS => 1,
      COLS_NAME        => 1,
      HIDDEN           => '0',
    }
  );

    map {$_->{name} = $lang{$_->{name}} || $_->{name} }@{$contacts_type_list};

    $admin->{CONTACTS} = _build_admin_contacts_form( $list, $contacts_type_list );


  return 1;
}

#**********************************************************
=head2 form_admins_contacts_save()

=cut
#**********************************************************
sub form_admins_contacts_save {

  my $message = $lang{ERROR};
  my $status = 1;

  return 0 unless ($FORM{AID} && $FORM{CONTACTS});

  if ( my $error = load_pmodule2( "JSON", { RETURN => 1 } ) ){
    print $error;
    return 0;
  }

  my $json = JSON->new();

  $FORM{CONTACTS} =~ s/\\\"/\"/g;

  my $contacts = $json->decode( $FORM{CONTACTS} );
  my DBI $db_ = $admin->{db}->{db};
  if ( ref $contacts eq 'ARRAY' ){
    $db_->{AutoCommit} = 0;

    $admin->admin_contacts_del( { AID => $FORM{AID} } );
    if ( $admin->{errno} ){
      $db_->rollback();
      $status = $admin->{errno};
      $message = $admin->{sql_errstr};
    }
    else{
      foreach my $contact ( @{$contacts} ){
        $admin->admin_contacts_add( { %{$contact}, AID => $FORM{AID} } );
      }

      if ( $admin->{errno} ){
        $db_->rollback();
        $status = $admin->{errno};
        $message = $admin->{sql_errstr};
      }
      else{
        $db_->commit();
        $db_->{AutoCommit} = 1;
      }

      $message = $lang{CHANGED};
      $status = 0;
    }
  }

  print qq[
    {
      "status" : $status,
      "message" :  "$message"
    }
  ];

  return 1;
}

#**********************************************************
=head2 _build_user_contacts_form($user_contacts_list)

  Arguments:
    $user_contacts_list -

  Returns:

=cut
#**********************************************************
sub _build_admin_contacts_form{
  my ($admin_contacts_list, $admin_contacts_types_list) = @_;
  my $json;
  my $json_load_error = load_pmodule( "JSON", { RETURN => 1 } );

  if ( $json_load_error ){
    print $json_load_error;
    return 0;
  }
  else{
    $json = JSON->new()->utf8(0);
  }
  my $contacts_json = $json->encode( {
          contacts => $admin_contacts_list,
          options  => {
              callback_index => get_function_index('form_admins_contacts_save'),
              types          => $admin_contacts_types_list,
              AID            => $FORM{AID},
          }
      }
  );

  my $admin_contacts_template = $html->tpl_show(
      templates( 'form_admin_contacts' ),
      {
          JSON          => qq{ "json" : $contacts_json }
      },
      { OUTPUT2RETURN => 1 }
  );

  print $admin_contacts_template;
}


#**********************************************************
=head2 form_admins_domains($attr);

=cut
#**********************************************************
sub form_admins_domains {
  my ($attr) = @_;

  if (!defined($attr->{ADMIN})) {
    $FORM{subf} = 113;
    form_admins();
    return 1;
  }

  require Multidoms;
  Multidoms->import();
  my $Domains = Multidoms->new($db, $admin, \%conf);

  if ($FORM{change}) {
    $Domains->admin_change({%FORM});
    if (_error_show($Domains)) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED} GID: [$FORM{GID}]");
    }
  }

  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{GROUP},
      title      => [ 'ID', $lang{NAME} ],
      cols_align => [ 'left', 'left', 'center' ],
    }
  );

  my $list = $Domains->admins_list({ AID => $LIST_PARAMS{AID}, COLS_NAME => 1 });
  my %admins_domain_hash = ();

  foreach my $line (@$list) {
    $admins_domain_hash{ $line->{domain_id} } = 1;
  }

  $list = $Domains->multidoms_domains_list({ COLS_NAME => 1 });
  foreach my $line (@$list) {
    $table->addrow($html->form_input('DOMAIN_ID', $line->{id}, { TYPE => 'checkbox', STATE => (defined($admins_domain_hash{ $line->{id} })) ? 'checked' : undef }) . $line->{id},
      $line->{name});
  }

  print $html->form_main(
    {
      CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
      HIDDEN  => {
        index => $index,
        AID   => $FORM{AID},
        subf  => $FORM{subf}
      },
      SUBMIT => { change => $lang{CHANGE} }
    }
  );

  return 1;
}

1
