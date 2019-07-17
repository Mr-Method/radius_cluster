=head1 NAME

  IPTV User portal

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array next_month convert);
use Abills::HTML;
use Tariffs;

our (
  $html,
  %lang,
  $Tv_service,
  $db,
  $admin,
  @service_status,
  $Iptv,
);

my $Tariffs = Tariffs->new($db, \%conf, $admin);

#**********************************************************
=head2 iptv_subcribe_add() - IPTV user interface

=cut
#**********************************************************
sub iptv_subcribe_add {

  my $services = tv_services_sel({ USER_PORTAL => 2, STATUS => 0 });

  my $tp_list = $Tariffs->list(
    {
      CHANGE_PRICE => '<=' . ($user->{DEPOSIT} + $user->{CREDIT}),
      MODULE       => 'Iptv',
      MONTH_FEE    => '_SHOW',
      DAY_FEE      => '_SHOW',
      CREDIT       => '_SHOW',
      COMMENTS     => '_SHOW',
      SERVICE_ID   => $FORM{SERVICE_ID},
      FILTER_ID    => '_SHOW',
      NEW_MODEL_TP => 1,
      COLS_NAME    => 1,
      DOMAIN_ID    => $user->{DOMAIN_ID},
      COLS_UPPER   => 1
    }
  );

  if ($Tariffs->{TOTAL} < 1) {
    $html->message('err', $lang{ERROR}, $lang{ERR_NO_AVAILABLE_TP}, { ID => 891 });
    return 1;
  }

  my @skip_tp_changes = ();
  #  if ($conf{DV_SKIP_CHG_TPS}) {
  #    @skip_tp_changes = split(/,\s?/, $conf{DV_SKIP_CHG_TPS});
  #  }

  $Tv_service = tv_load_service('', { SERVICE_ID => $FORM{SERVICE_ID} });

  my $tp_list_show = '';
  foreach my $tp (@$tp_list) {
    next if (in_array($tp->{tp_id}, \@skip_tp_changes));
    next if ($Iptv->{TP_ID} && $tp->{tp_id} == $Iptv->{TP_ID} && $user->{EXPIRE} eq '0000-00-00');
    $tp->{RADIO_BUTTON} = '';

    $user->{CREDIT} = ($user->{CREDIT} > 0) ? $user->{CREDIT} : (($tp->{credit} > 0) ? $tp->{credit} : 0);

    if ($tp->{day_fee} + $tp->{month_fee} < $user->{DEPOSIT} + $user->{CREDIT} || $tp->{abon_distribution}) {
      $tp->{RADIO_BUTTON} = $html->form_input('TP_ID', $tp->{tp_id}, { TYPE => 'radio', OUTPUT2RETURN => 1 });
    }
    else {
      $tp->{RADIO_BUTTON} = $lang{ERR_SMALL_DEPOSIT};
    }

    if ($Tv_service && $Tv_service->can('service_info')) {
      $tp->{COMMENTS} = $Tv_service->service_info($tp);
    }

    $tp_list_show .= $html->tpl_show(_include('iptv_tp_info_panel', 'Iptv'), $tp, { OUTPUT2RETURN => 1 });
  }

  $html->tpl_show(_include('iptv_subscribes', 'Iptv'), {
    TP_SEL      => $tp_list_show,
    SERVICE_SEL => $services,
    EMAIL       => $user->{EMAIL}
  });

  return 1;
}

#**********************************************************
=head2 iptv_user_info() - IPTV user interface

=cut
#**********************************************************
sub iptv_user_info {

  if ($conf{IPTV_ALLOW_GIDS}) {
    $conf{IPTV_ALLOW_GIDS} =~ s/ //g;
    my @allow_arr = split(/,/, $conf{IPTV_ALLOW_GIDS});
    if (!in_array($user->{GID}, \@allow_arr)) {
      $html->message('info', $lang{INFO}, $lang{NOT_ALLOW_GROUP}, { ID => 890 });
      return 0;
    }
  }

  my $Shedule = Shedule->new($db, $admin, \%conf);
  my %PORTAL_ACTIONS = ();
  my $service_list = $Iptv->services_list({ USER_PORTAL => '>0', COLS_NAME => 1 });

  if (!$Iptv->{TOTAL}) {

    return 1;
  }

  my $service_status = sel_status({ HASH_RESULT => 1 });
  foreach my $service (@$service_list) {
    $PORTAL_ACTIONS{$service->{id}} = $service->{user_portal};
  }

  if ($FORM{add_form}) {
    if ($FORM{add}) {
      $Iptv->{db}{db}->{AutoCommit} = 0;
      $Iptv->{db}->{TRANSACTION} = 1;

      $Iptv->user_add({ %FORM, UID => $user->{UID} });
      if (!$Iptv->{errno}) {
        $Iptv->{ACCOUNT_ACTIVATE} = $user->{ACTIVATE};
        service_get_month_fee($Iptv, { SERVICE_NAME => $lang{TV} }) if (!$FORM{STATUS});
        $Iptv->{ID} = $Iptv->{INSERT_ID};

        $Iptv->user_info($Iptv->{ID});

        $Iptv->{SERVICE_ID} //= $FORM{SERVICE_ID};
        $Tv_service = undef;
        if ($Iptv->{SERVICE_ID}) {
          $Tv_service = tv_load_service($Iptv->{SERVICE_MODULE}, { SERVICE_ID => $Iptv->{SERVICE_ID} });
        }

        my DBI $db_ = $Iptv->{db}{db};
        if (!_error_show($Iptv) && $Tv_service) {

          my $result = iptv_account_action({
            %FORM,
            ID        => $FORM{ID} || $Iptv->{ID},
            SCREEN_ID => undef,
            USER_INFO => $user
          });

          if ($result) {
            _error_show($Iptv, {
              ID          => 835,
              MESSAGE     => $Iptv->{errstr},
              MODULE_NAME => $Tv_service->{SERVICE_NAME}
            });

            $db_->rollback();
            $Iptv->{ID} = undef;
            #            my $message = '';
            #            $html->message( 'err', $lang{ERROR}, $message);
            return 1;
          }
          delete($Iptv->{db}->{TRANSACTION});
          $db_->commit();
          $db_->{AutoCommit} = 1;
        }
        else {
          delete($Iptv->{db}->{TRANSACTION});
          $db_->commit();
          $db_->{AutoCommit} = 1;
        }
        $html->message('info', $lang{INFO}, "$lang{ADDED} ID: $Iptv->{ID}");
      }
    }
    else {
      iptv_subcribe_add();
      return 1;
    }
  }
  elsif ($FORM{disable}) {
    $Iptv->user_info($FORM{ID}, { UID => $user->{UID} });
    my $disable_date = next_month();
    my ($year, $month, $day) = split(/-/, $disable_date, 3);
    $Shedule->add({
      UID          => $user->{UID},
      TYPE         => 'status',
      ACTION       => "$FORM{ID}:1",
      D            => $day,
      M            => $month,
      Y            => $year,
      COMMENTS     => "$lang{FROM}: $Iptv->{STATUS}->1",
      ADMIN_ACTION => 1,
      MODULE       => 'Iptv'
    });

    $html->message('info', $lang{INFO}, "$lang{DISABLED_WILL} $disable_date");
  }
  elsif ($FORM{chg}) {
    $FORM{ID} = $FORM{chg} if (!$FORM{ID});

    $Iptv->user_info($FORM{chg}, { UID => $user->{UID} });
    $Tv_service = undef;
    if ($Iptv->{SERVICE_ID}) {
      $Tv_service = tv_load_service($Iptv->{SERVICE_MODULE}, { SERVICE_ID => $Iptv->{SERVICE_ID} });
    }

    if ($FORM{activ_code}) {
      iptv_activation();
      return 1;
    }
    if ($FORM{watch_now}) {
      iptv_watch();
      return 1;
    }

    if ($Iptv->{TOTAL} < 1) {
      $html->message('info', $lang{INFO}, $lang{NOT_ACTIVE}, { ID => 801 });
      return 0;
    }
    elsif ($FORM{ACTIVATE}) {
      iptv_user_activate($Iptv, { USER => $user });
      return 0;
    }
    elsif ($Iptv->{STATUS} && $Iptv->{STATUS} == 5) {
      $html->message('err', $lang{INFO},
        ((defined($Iptv->{STATUS}) && $service_status->{ $Iptv->{STATUS} }) ? $service_status->{ $Iptv->{STATUS} } : q{})
          . "\n" . $html->button($lang{ACTIVATE}, "index=$index&ACTIVATE=1&chg=$FORM{chg}",
          { class => 'btn btn-primary' }), { ID => 802 });
      return 0;
    }
    if ($FORM{UID} && $FORM{ID} && ! $FORM{change_now} && ! $FORM{change_shedule}) {
      if ($Tv_service && $Tv_service->can('get_code')) {
        $Iptv->{ACTIVE_CODE} = $html->button("Activation code",
          "qindex=$index&activ_code=1&chg=$FORM{chg}&header=2",
          {
            class         => 'btn btn-success',
            LOAD_TO_MODAL => 1,
          });
      }

      if ($Tv_service && $Tv_service->can('get_url')) {
        $Iptv->{WATCH_NOW} = $html->button("Watch now",
          "qindex=$index&watch_now=1&UID=$FORM{UID}&chg=$FORM{chg}&MODULE=$FORM{MODULE}&sid=$FORM{sid}&header=2",
          {
            class  => 'btn btn-success',
            target => '_new',
          });
      }
    }

    if ($conf{IPTV_USER_CHG_TP}) {
      $Iptv->{TP_CHANGE_BTN} = $html->button($lang{CHANGE},
        'index=' . get_function_index('iptv_user_chg_tp')
          . '&ID=' . $FORM{chg}
          . '&sid=' . $sid, { class => 'change' });
    }

    if (in_array(2, [ values %PORTAL_ACTIONS ])) {
      $Iptv->{DISABLE_BTN} = $html->button($lang{DISABLE_SERVICE},
        'index=' . $index . '&sid=' . $sid . "&ID=$Iptv->{ID}&disable=1", { class => 'btn btn-default btn-danger' });
      $conf{IPTV_USER_CHG_CHANNELS} = 1;
    }

    $Iptv->{DISABLE} = $html->color_mark($service_status->{ $Iptv->{STATUS} });

    my $sheduled_actions_list = $Shedule->list({
      UID       => $user->{UID},
      TYPE      => 'status',
      MODULE    => 'Iptv',
      COLS_NAME => 1
    });

    if ($Shedule->{TOTAL} && $Shedule->{TOTAL} > 0) {
      my $shedule_action = $sheduled_actions_list->[0];
      my $action_ = $shedule_action->{action};
      my $service_id = 0;
      if ($action_ =~ /:/) {
        ($service_id, $action_) = split(/:/, $action_);
      }
      #if($action_ eq "0") {
      $Iptv->{DISABLE_BTN} = $html->badge("$lang{DISABLE_SERVICE_DATE}: $shedule_action->{y}-$shedule_action->{m}-$shedule_action->{d}");
      #}
    }

    if ($conf{IPTV_CLIENT_M3U}) {
      iptv_m3u({ SERVICE_INFO => $Iptv });
    }

    $html->tpl_show(_include('iptv_user_info', 'Iptv'), $Iptv);
    iptv_users_screens($Iptv, { SHOW_FULL => $PORTAL_ACTIONS{$Iptv->{SERVICE_ID}} });
    iptv_user_channels({ SERVICE_INFO => $Iptv, SHOW_ONLY => (!$conf{IPTV_USER_CHG_CHANNELS}) ? 1 : undef });
  }

  delete($LIST_PARAMS{LOGIN});

  result_former({
    INPUT_DATA      => $Iptv,
    FUNCTION        => 'user_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'TP_NAME,CID,SERVICE_STATUS,MONTH_FEE,DAY_FEE,IPTV_EXPIRE',
    FUNCTION_FIELDS => 'change',
    TABLE           => {
      width     => '100%',
      caption   => $lang{SUBSCRIBES},
      qs        => $pages_qs,
      SHOW_COLS => undef,
      header    => (in_array(2, [ values %PORTAL_ACTIONS ])) ? $html->button($lang{ADD},
        "index=$index&add_form=1&sid=" . ($FORM{sid} || q{}), { BUTTON => 2 }) : q{},
      ID        => 'IPTV_USERS_LIST',
    },
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      'cid'            => 'MAC',
      'tp_name'        => $lang{TARIF_PLAN},
      'service_status' => $lang{STATUS},
      'iptv_expire'    => $lang{EXPIRE},
      'month_fee'      => $lang{MONTH_FEE},
      'day_fee'        => $lang{DAY_FEE},
    },
    MAKE_ROWS       => 1,
    MODULE          => 'Iptv',
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 iptv_user_chg_tp($attr)

=cut
#**********************************************************
sub iptv_user_chg_tp {
  my ($attr) = @_;

  # my $user;
  my $table;
  my $Shedule = Shedule->new($db, $admin, \%conf);
  my $period = $FORM{period} || 0;
  if (!$conf{IPTV_USER_CHG_TP}) {
    $html->message('err', $lang{ERROR}, "$lang{NOT_ALLOW}", { ID => 802 });
    return 1;
  }

  if ($LIST_PARAMS{UID}) {
    if(! $FORM{ID}) {
      iptv_user_info();
      return 1;
    }

    $Iptv = $Iptv->user_info($FORM{ID}, { UID => $LIST_PARAMS{UID} });
    if ($Iptv->{TOTAL} < 1) {
      $html->message('info', $lang{INFO}, "$lang{NOT_ACTIVE}", { ID => 800 });
      return 1;
    }
  }
  else {
    $html->message('err', $lang{ERROR}, $lang{USER_NOT_EXIST}, { ID => 801 });
    return 0;
  }

  #Get TP groups
  $Tariffs->tp_group_info($Iptv->{TP_GID});
  if (!$Tariffs->{USER_CHG_TP}) {
    $html->message('err', $lang{ERROR}, "$lang{NOT_ALLOW}", { ID => 803 });
    return 0;
  }

  if ($FORM{TP_ID} && $Iptv->{TP_ID} == $FORM{TP_ID}) {

  }
  elsif ($FORM{set} && $FORM{ACCEPT_RULES}) {

    if ($period == 1 && $conf{IPTV_USER_CHG_TP_SHEDULE}) {
      my $seltime = POSIX::mktime(0, 0, 0, $FORM{date_D}, $FORM{date_M}, ($FORM{date_Y} - 1900));
      if ($seltime <= time()) {
        $html->message('info', $lang{INFO}, "$lang{ERR_WRONG_DATA}", { ID => 804 });
        return 0;
      }
      $FORM{date_M}++;
      my $message = q{};
      $Shedule->add(
        {
          UID      => $LIST_PARAMS{UID},
          TYPE     => 'tp',
          ACTION   => $FORM{TP_ID},
          D        => sprintf("%02.d", $FORM{date_D}),
          M        => sprintf("%02.d", $FORM{date_M}),
          Y        => $FORM{date_Y},
          DESCRIBE => "$message\n $lang{FROM}: '$FORM{date_Y}-$FORM{date_M}-$FORM{date_D}'",
          MODULE   => 'Iptv'
        }
      );
      if (!_error_show($Shedule, { ID => 805 })) {
        $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
        $Iptv->user_info($user->{UID});
        iptv_user_channels({ QUIET => 1, SERVICE_INFO => $Iptv });
      }
    }
    else {
      # Get next month
      my ($Y, $M, $D);
      if ($user->{ACTIVATE} eq '0000-00-00') {
        # Get next month
        ($Y, $M, $D) = split(/-/, $DATE, 3);
      }
      else {
        ($Y, $M, $D) = split(/-/, $user->{ACTIVATE}, 3);
      }

      if (!$conf{IPTV_USER_CHG_TP_NEXT_MONTH} && ($Iptv->{MONTH_FEE} == 0 || $Iptv->{ABON_DISTRIBUTION})) {
        ($Y, $M, $D) = split(/-/,
          POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + 86400))));
      }
      else {
        if ($user->{ACTIVATE} eq '0000-00-00') {
          # Get next month
          ($Y, $M, $D) = split(/-/, $DATE, 3);
          $D = '01';
        }
        else {
          ($Y, $M, $D) = split(/-/, $user->{ACTIVATE}, 3);
        }
        $M++;
        if ($M == 13) {
          $M = 1;
          $Y++;
        }
        $M = sprintf("%02.d", $M);
      }

      my $seltime = POSIX::mktime(0, 0, 0, $D, $M, ($Y - 1900));
      my $message = '';
      if ($seltime > time()) {
        $Shedule->add(
          {
            UID      => $LIST_PARAMS{UID},
            TYPE     => 'tp',
            ACTION   => $FORM{TP_ID},
            D        => $D,
            M        => $M,
            Y        => $Y,
            DESCRIBE => "$message\n $lang{FROM}: '$Y-$M-$D'",
            MODULE   => 'Iptv'
          }
        );
      }
      else {
        $FORM{UID} = $LIST_PARAMS{UID};
        $Iptv->user_change({ %FORM });
        if (!_error_show($user)) {
          if ($Iptv->{TP_INFO}->{MONTH_FEE} > 0 && !$Iptv->{STATUS}) {
            service_get_month_fee($Iptv, { SERVICE_NAME => "$lang{TV}" });
          }
          $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
          $Iptv->user_info($user->{UID});
        }
      }
    }
  }
  elsif ($FORM{del}) {
    $Shedule->del(
      {
        UID => $LIST_PARAMS{UID} || '-',
        ID  => $FORM{SHEDULE_ID}
      }
    );
    $html->message('info', $lang{DELETED}, "$lang{DELETED} [$FORM{SHEDULE_ID}]");
  }

  my $message = '';
  my $date_ = ($FORM{date_y} || '') . '-' . ($FORM{date_m} || '') . '-' . ($FORM{date_d} || '');
  $Shedule->info(
    {
      UID      => $user->{UID},
      TYPE     => 'tp',
      DESCRIBE => "$message\n$lang{FROM}: '$date_'",
      MODULE   => 'Iptv'
    }
  );
  if ($Shedule->{TOTAL} > 0) {
    $Tariffs->info($Shedule->{ACTION});
    $table = $html->table(
      {
        width   => '100%',
        caption => $lang{SHEDULE},
        rows    => [
          [ "$lang{TARIF_PLAN}:", "$Shedule->{ACTION} : $Tariffs->{NAME}" ],
          [ "$lang{DATE}:", "$Shedule->{Y}-$Shedule->{M}-$Shedule->{D}" ], [ "$lang{ADDED}:", "$Shedule->{DATE}" ],
          [ "ID:", "$Shedule->{SHEDULE_ID}" ]
        ]
      }
    );
    $Tariffs->{TARIF_PLAN_TABLE} = $table->show({ OUTPUT2RETURN => 1 }) . $html->form_input('SHEDULE_ID',
      "$Shedule->{SHEDULE_ID}", { TYPE => 'HIDDEN', OUTPUT2RETURN => 1 });
    if (!$Shedule->{ADMIN_ACTION}) {
      $Tariffs->{ACTION} = 'del';
      $Tariffs->{LNG_ACTION} = $lang{DEL};
      #$Tariffs->{ACTION} = $html->form_input( 'del', "$lang{DEL}  $lang{SHEDULE}", { TYPE => 'submit', OUTPUT2RETURN => 1 } );
    }
  }
  else {
    $Tariffs->{TARIF_PLAN_TABLE} = $html->form_select(
      'TP_ID',
      {
        SELECTED  => $Iptv->{TP_ID},
        SEL_LIST  =>
          $Tariffs->list({ TP_GID => $Iptv->{TP_GID}, NEW_MODEL_TP => 1, MODULE => 'Iptv', COLS_NAME => 1 }),
        SEL_KEY   => 'tp_id',
        SEL_VALUE => 'id,name',
      }
    );

    $table = $html->table({
      width   => '100%',
      caption => $lang{TRAFIF_PLAN},
    });

    my $tp_list = $Tariffs->list({
      TP_GID            => $Iptv->{TP_GID},
      CHANGE_PRICE      => '<=' . ($user->{DEPOSIT} + $user->{CREDIT}),
      MODULE            => 'Iptv',
      NEW_MODEL_TP      => 1,
      PRIORITY          => $Iptv->{TP_PRIORITY},
      ABON_DISTRIBUTION => '_SHOW',
      DAY_FEE           => '_SHOW',
      MONTH_FEE         => '_SHOW',
      COMMENTS          => '_SHOW',
      COLS_NAME         => 1,
      DOMAIN_ID         => $user->{DOMAIN_ID}
    });

    my @skip_tp_changes = ();
    if ($conf{IPTV_SKIP_CHG_TPS}) {
      @skip_tp_changes = split(/,\s?/, $conf{DV_SKIP_CHG_TPS});
    }
    foreach my $tp (@{$tp_list}) {
      next if (in_array($tp->{id}, \@skip_tp_changes));
      next if ($tp->{tp_id} == $Iptv->{TP_ID} && $user->{EXPIRE} eq '0000-00-00');
      #$table->{rowcolor} = ($table->{rowcolor} && $table->{rowcolor} eq $_COLORS[1]) ? $_COLORS[2] : $_COLORS[1];
      my $radio_but = '';
      $user->{CREDIT} = ($user->{CREDIT} && $user->{CREDIT} > 0) ? $user->{CREDIT} : (($tp->{credit} && $tp->{credit} > 0) ? $tp->{credit} : 0);
      if ($tp->{day_fee} + $tp->{month_fee} < $user->{DEPOSIT} + $user->{CREDIT} || $tp->{abon_distribution}) {
        $radio_but = $html->form_input('TP_ID', "$tp->{tp_id}", { TYPE => 'radio', OUTPUT2RETURN => 1 });
      }
      else {
        $radio_but = $lang{ERR_SMALL_DEPOSIT};
      }

      $table->addrow(
        $tp->{id},
        $html->b($tp->{name} || q{}) . $html->br() . convert($tp->{comments} || q{}, { text2html => 1 }),
        $tp->{day_fee},
        $tp->{month_fee},
        $radio_but
      );
    }
    $Tariffs->{TARIF_PLAN_TABLE} = $table->show({ OUTPUT2RETURN => 1 });
    if ($Tariffs->{TOTAL} == 0) {
      $html->message('info', $lang{INFO}, "$lang{ERR_SMALL_DEPOSIT}", { ID => 842 });
      return 0;
    }
    $Tariffs->{PARAMS} .= form_period($period) if ($conf{IPTV_USER_CHG_TP_SHEDULE} && !$conf{IPTV_USER_CHG_TP_NPERIOD});
    $Tariffs->{LNG_ACTION} = $lang{CHANGE};
    $Tariffs->{ACTION} = 'set';
  }

  $Tariffs->{UID} = $attr->{SERVICE_INFO}->{UID};
  #$Tariffs->{m}       = $m;
  $Tariffs->{TP_ID} = $Iptv->{TP_NUM};
  $Tariffs->{ID} = $Iptv->{ID};
  $Tariffs->{TP_NAME} = "$Iptv->{TP_NUM}:$Iptv->{TP_NAME}";

  $html->tpl_show(templates('form_client_chg_tp'), $Tariffs);

  return 1;
}

#**********************************************************
=head2 iptv_m3u($attr) - iptv_m3u

  Arguments:
    $attr
      SERVICE_INFO

=cut
#**********************************************************
sub iptv_m3u {
  my ($attr) = @_;

  my $tp_id = $attr->{SERVICE_INFO}->{TP_ID} || 0;

  #Show
  #my $err_message;
  my %hash = ();
  if ($FORM{m3u_download}) {
    my $m3u = '#EXTM3U';
    if (!$Iptv->{STATUS}) {

      my $list = $Tariffs->ti_list(
        {
          TP_ID     => $tp_id,
          COLS_NAME => 1
        }
      );

      if ($Tariffs->{TOTAL} > 0) {
        my $interval_id = $list->[0]->{id};
        $list = $Iptv->channel_ti_list(
          {
            %LIST_PARAMS,
            USER_INTERVAL_ID => $interval_id,
            STREAM           => '_SHOW',
            COLS_NAME        => 1,
            SORT             => 2,
          }
        );

        if ($Iptv->{TOTAL} > 0) {
          foreach my $line (@{$list}) {
            $m3u .= "\n#EXTINF:-1 group-title=\"" . ($line->{group_title} || q{}) . "\", " . ($line->{name} || q{}) . "\n" . ($line->{stream} || q{});
          }

          my $deposit = sprintf("%.2f", $user->{DEPOSIT});
          my $credit = sprintf("%.2f", $user->{CREDIT});
          my $fio = $user->{FIO} || q{};
          %hash = (
            access    => 'all',
            fio       => $fio,
            user_info =>
              "������������ $fio. <br> ��� ������ " . $deposit . "���<br> ������ " . $credit . "��� <br>",
            m3u       => $m3u,
          );
        }
        #        else{
        #          $hash{err_message} = "����������� ������ �������.";
        #          $err_message = "����������� ������ �������.";
        #        }
      }
      #      else{
      #        $hash{err_message} = "����������� ������ �������.";
      #        $err_message = "����������� ������ �������.";
      #      }
    }

    my $file_size = length($m3u);
    my $file_name = $FORM{m3u_download};

    print "Content-Type: video/mpeg;  filename=\"$file_name\"\n" . "Content-Disposition:  attachment;  filename=\"$file_name\"; " . "size=$file_size" . "\n\n";
    print "$m3u";

    exit 1;
  }

  $Iptv->{M3U_LIST} = $html->button(($lang{DOWNLOAD} || '') . ' M3U ',
    "index=$index&chg=$Iptv->{ID}&UID=$user->{UID}&m3u_download=tv_channels.m3u", { class => 'btn btn-primary' });

  return 1;
}

#**********************************************************
=head2 iptv_watch_now($attr) - Activation code

=cut
#**********************************************************
sub iptv_watch {

  if ($Tv_service && $Tv_service->can('get_url')) {
    my $result = $Tv_service->get_url({ %FORM, %LIST_PARAMS, INDEX => $index, DEVICE => 1, });
    if ($result->{result}{web_url}) {
      $html->redirect($result->{result}{web_url});
    }
    else {
      print "Error";
    }
  }

  return 1;
}

#**********************************************************
=head2 iptv_activation_code($attr) - Activation code

=cut
#**********************************************************
sub iptv_activation {

  if ($Tv_service && $Tv_service->can('get_code')) {
    $user->info($user->{UID}, {
      SHOW_PASSWORD => 1,
    });
    $Tv_service->get_code({ %$user, INDEX => $index, DEVICE => 1, });
  }

  return 1;
}


1;