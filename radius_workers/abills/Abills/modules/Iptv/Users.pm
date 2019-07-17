=head NAME


=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array cmd);
require Abills::Misc;


our (
  $Iptv,
  %FORM,
  $html,
  %lang,
  $db,
  %conf,
  $admin,
  %permissions,
  @MONTHES_LIT,
  $Tv_service,
  $users,
  $user,
  @MODULES,
  $DATE,
  $TIME,
  $index,
  %LIST_PARAMS,
);

my $Tariffs = Tariffs->new($db, \%conf, $admin);
#my $Iptv = Iptv->new( $db, $admin, \%conf );

#**********************************************************
=head2 iptv_user($attr) - Users info

=cut
#**********************************************************
sub iptv_user {
  my ($attr) = @_;

  $Iptv->{UID} = $FORM{UID};
  $FORM{CID} = $FORM{CID2} if ($FORM{CID2});
  $Iptv->{db}{db}->{AutoCommit} = 0;
  $Iptv->{db}->{TRANSACTION} = 1;
  my $sunbscribe_count = 0;

  if ($FORM{REGISTRATION_INFO}) {
    # Info
    load_module('Docs', $html);
    $users = Users->new($db, $admin, \%conf);
    $Iptv = $Iptv->user_info($Iptv->{ID});
    my $pi = $users->pi({ UID => $Iptv->{UID} });
    $user = $users->info($Iptv->{UID}, { SHOW_PASSWORD => $permissions{0}{3} });

    ($Iptv->{Y}, $Iptv->{M}, $Iptv->{D}) = split(/-/, (($pi->{CONTRACT_DATE}) ? $pi->{CONTRACT_DATE} : $DATE), 3);
    $pi->{CONTRACT_DATE_LIT} = "$Iptv->{D} " . $MONTHES_LIT[ int($Iptv->{M}) - 1 ] . " $Iptv->{Y} $lang{YEAR}";
    $Iptv->{MONTH_LIT} = $MONTHES_LIT[ int($Iptv->{M}) - 1 ];

    if ($Iptv->{Y} =~ /(\d{2})$/) {
      $Iptv->{YY} = $1;
    }

    if (!$FORM{pdf}) {
      if (in_array('Mail', \@MODULES)) {
        load_module('Mail', $html);
        my $Mail = Mail->new($db, $admin, \%conf);
        my $list = $Mail->mbox_list({ UID => $Iptv->{UID} });
        foreach my $line (@{$list}) {
          $Mail->{EMAIL_ADDR} = $line->[0] . '@' . $line->[1];
          $user->{EMAIL_INFO} .= $html->tpl_show(_include('mail_user_info', 'Mail'), $Mail, { OUTPUT2RETURN => 1 });
        }
      }
    }
    print $html->header();
    $Iptv->{PASSWORD} = $user->{PASSWORD} if (!$Iptv->{PASSWORD});
    return $html->tpl_show(
      _include('iptv_user_memo', 'Iptv', { pdf => $FORM{pdf} }),
      {
        %{$user},
        %{$pi},
        DATE => $DATE,
        TIME => $TIME,
        %{$Iptv},
      }
    );
    return 0;
  }
  elsif ($FORM{send_message}) {
    if (!$FORM{send}) {
      $user->{IPTV_MODEMS} = $html->tpl_show(_include('iptv_send_message', 'Iptv'), { %{$attr}, %{$user} });
      return 0;
    }
    #$FORM{chg}=$FORM{ID};
  }
  elsif ($FORM{new}) {

  }
  elsif ($FORM{import}) {
    if ($FORM{add}) {
      my $import_accounts = import_former(\%FORM);
      my $total = $#{$import_accounts} + 1;

      $html->message('info', $lang{INFO},
        "$lang{ADDED}\n $lang{FILE}: $FORM{UPLOAD_FILE}{filename}\n Size: $FORM{UPLOAD_FILE}{Size}\n Count: $total");

      return 1
    }

    $html->tpl_show(templates('form_import'), {
      IMPORT_FIELDS => 'LOGIN,TP_ID,STATUS,CID',
      CALLBACK_FUNC => 'iptv_user'
    });

    return 1;
  }
  elsif ($FORM{add}) {
    if (!iptv_user_add({ %FORM, %{($attr) ? $attr : {}} })) {
      if ($FORM{SERVICE_ID}) {
        return 0;
      }
      return 1;
    }
  }
  elsif ($FORM{change}) {
    $Iptv->user_change(\%FORM);

    if ($Iptv->{OLD_STATUS} && !$Iptv->{STATUS}) {
      iptv_user_activate($Iptv, {
        USER       => $users,
        REACTIVATE => (!$Iptv->{STATUS}) ? 1 : 0,
      });
    }

    if (!$Iptv->{errno}) {
      $Iptv->{ACCOUNT_ACTIVATE} = $attr->{USER_INFO}->{ACTIVATE};
      #if ( !$FORM{STATUS} && ($FORM{GET_ABON} || !$FORM{TP_ID}) ){
      #  service_get_month_fee( $Iptv, { SERVICE_NAME => $lang{TV} } );
      #}

      if ($FORM{change_now}) {
        $Iptv->user_channels({ ID => $FORM{ID} });
      }

      $Iptv->{MESSAGE} = "$lang{CHANGED}: $FORM{ID}";
    }
    $Iptv->{MANDATORY_CHANNELS} = iptv_mandatory_channels($attr->{TP_ID});
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Iptv->user_info($FORM{del});
    if (!$Iptv->{errno}) {
      $Iptv->user_del({ ID => $FORM{del} });
      if (!$Iptv->{errno}) {
        $Iptv->{ID} = $FORM{del};
        $html->message('info', $lang{INFO}, "$lang{DELETED} [ $Iptv->{ID} ]");
        delete $Iptv->{ID};
      }
    }
  }
  else {
    my $list = $Iptv->user_list({ UID => $FORM{UID}, COLS_NAME => 1 });
    $sunbscribe_count = $Iptv->{TOTAL};
    if ($Iptv->{TOTAL} == 1) {
      $FORM{chg} = $list->[0]->{id};
    }
    elsif ($Iptv->{TOTAL} == 0) {
      $FORM{add_form} = 1;
    }
  }

  if ($FORM{chg}) {
    $Iptv->user_info($FORM{chg});
  }

  $Tv_service = iptv_user_services(\%FORM);

  if ($FORM{new_device}) {
    iptv_new_devices();
    return 1;
  }

  if ($FORM{activation_code}) {
    iptv_activation_code();
    return 1;
  }

  if ($FORM{watch_now}) {
    iptv_watch_now();
    return 1;
  }

  if ($attr->{REGISTRATION} && $FORM{add}) {
    return 1;
  }

  #my $user;
  #if ( $conf{IPTV_SUBSCRIBE_CMD} ){
  #  $Iptv->{SUBSCRIBE_FORM} = iptv_sel_subscribes( $Iptv );
  #}

  $Iptv->{SUBSCRIBE_FORM} = tv_services_sel({ %$Iptv, FORM_ROW => 1, UNKNOWN => 1 });

  if (!$Iptv->{ID}) {
    if ($attr->{ACTION}) {
      $user->{ACTION} = $attr->{ACTION};
      $user->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user->{ACTION} = 'add';
      $user->{LNG_ACTION} = $lang{ACTIVATE};
    }

    $Iptv->{TP_ADD} = $html->form_select(
      'TP_ID',
      {
        SELECTED  => $FORM{TP_ID} || $Iptv->{TP_ID} || '',
        SEL_LIST  => $Tariffs->list({
          MODULE       => 'Iptv',
          NEW_MODEL_TP => 1,
          COLS_NAME    => 1,
          DOMAIN_ID    => $admin->{DOMAIN_ID},
          SERVICE_ID   => $Iptv->{SERVICE_ID}
        }),
        SEL_KEY   => 'tp_id',
        SEL_VALUE => 'id,name',
      }
    );

    $Iptv->{TP_DISPLAY_NONE} = "style='display:none'";
  }
  elsif ($Iptv->{UID}) {
    $Iptv->{REGISTRATION_INFO} = $html->button($lang{MEMO},
      "qindex=$index&UID=$Iptv->{UID}&ID=$Iptv->{ID}&REGISTRATION_INFO=1",
      { BUTTON => 1, ex_params => 'target=_new' });

    if ($conf{DOCS_PDF_PRINT}) {
      $Iptv->{REGISTRATION_INFO_PDF} = $html->button("$lang{MEMO} (PDF)",
        "qindex=$index&UID=$Iptv->{UID}&ID=$Iptv->{ID}&REGISTRATION_INFO=1&pdf=1",
        { ex_params => 'target=_new', BUTTON => 1 });
    }

    iptv_user_channels_list({ ID => $FORM{ID}, TP_ID => $Iptv->{TP_ID} });

    $user->{TP_IDS} = $Iptv->{TP_ID};
    if ($attr->{ACTION}) {
      $user->{ACTION} = $attr->{ACTION};
      $user->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user->{ACTION} = 'change';
      $user->{LNG_ACTION} = $lang{CHANGE};
    }

    $FORM{chg} = $Iptv->{ID} if (!$FORM{chg});
    $user->{CHANGE_TP_BUTTON} = $html->button($lang{CHANGE},
      'UID=' . $Iptv->{UID} . '&index=' . get_function_index('iptv_chg_tp') . '&ID=' . $Iptv->{ID}
        . (($Iptv->{SERVICE_ID}) ? "&SERVICE_ID=$Iptv->{SERVICE_ID}" : q{}),
      { class => 'change' });

    if ($Tv_service && $Tv_service->{SEND_MESSAGE}) {
      $user->{SEND_MESSAGE} = $html->button("$lang{SEND} $lang{MESSAGE}",
        "index=$index&ID=$Iptv->{ID}&UID=" . $Iptv->{UID} . "&send_message=1"
          . (($Iptv->{SERVICE_ID}) ? "&SERVICE_ID=$Iptv->{SERVICE_ID}" : q{}),
        { BUTTON => 1 });
    }

    require Internet::Service_mng;
    my $Service = Internet::Service_mng->new({ lang => \%lang });

    ($Iptv->{NEXT_FEES_WARNING}, $Iptv->{NEXT_FEES_MESSAGE_TYPE}) = $Service->service_warning({
      SERVICE => $Iptv,
      USER    => $users,
      DATE    => $DATE
    });

    if ($Iptv->{NEXT_FEES_WARNING}) {
      $Iptv->{NEXT_FEES_WARNING} = $html->message($Iptv->{NEXT_FEES_MESSAGE_TYPE}, $Iptv->{TP_NAME},
        $Iptv->{NEXT_FEES_WARNING}, { OUTPUT2RETURN => 1 });
    }
  }

  $Iptv->{STATUS_SEL} = sel_status({ STATUS => $Iptv->{STATUS} });
  my $service_info1 = q{};
  my $service_info2 = q{};
  my $service_info_subscribes = q{};

  if ($FORM{chg} || $FORM{USER_CHANNELS} || $FORM{add_form} || $attr->{REGISTRATION}) {
    iptv_users_screens($Iptv);
    if (!$FORM{screen}) {
      if ($Tv_service->{SERVICE_USER_FORM}) {
        my $fn = $Tv_service->{SERVICE_USER_FORM};
        &{\&$fn}({ %{$attr}, %{$user}, %{$Iptv}, SHOW_USER_FORM => 1 });
      }
      elsif ($Iptv->{SUBSCRIBE_FORM_FULL}) {
        $service_info_subscribes = $Iptv->{SUBSCRIBE_FORM_FULL};
      }
      else {
        $service_info1 = $html->tpl_show(_include('iptv_user', 'Iptv'), {
          %{($attr) ? $attr : {}},
          %{$Iptv},
          %{($user) ? $user : {}} },
          { ID => 'iptv_user', OUTPUT2RETURN => 1 });
      }

      if ($Iptv->{ID}) {
        $service_info_subscribes .= iptv_user_channels({ SERVICE_INFO => $Iptv });
      }
    }

    if (($Iptv->{UID} && $Iptv->{SERVICE_ID} && $Iptv->{SERVICE_MODULE} && $Iptv->{TP_ID})
      || ($Iptv->{SERVICE_MODULE} && $Iptv->{SERVICE_MODULE} eq "SmartUp")) {
      my $chg_dev = $FORM{chg} || "";
      my $module_dev = $FORM{MODULE} || "";
      my $service_dev = $Iptv->{SERVICE_ID} || "";
      if ($Tv_service->can('customer_add_device')) {
        print $html->button("Add Device by Uniq",
          "get_index=iptv_user&new_device=1&header=2&UID=$Iptv->{UID}&SERVICE_ID=$service_dev&MODULE=$module_dev&chg_d=$chg_dev",
          {
            class         => 'btn-xs',
            LOAD_TO_MODAL => 1,
            BUTTON        => 1,
          });
      }
      if ($Tv_service->can('get_code')) {
        print $html->button("Activation code",
          "get_index=iptv_user&activation_code=1&header=2&UID=$Iptv->{UID}&SERVICE_ID=$service_dev&MODULE=$module_dev&activ_code=$chg_dev",
          {
            class         => 'btn-xs',
            LOAD_TO_MODAL => 1,
            BUTTON        => 1,
          });
      }
      if ($Tv_service->can('get_url')) {
        print $html->button("Watch now",
          "get_index=iptv_user&watch_now=1&header=2&UID=$Iptv->{UID}&SERVICE_ID=$service_dev&MODULE=$module_dev&watch_now=$chg_dev",
          {
            class         => 'btn-xs',
            BUTTON        => 1,
            target     => '_new',
          });
#        my $result = $Tv_service->get_url({ %FORM, %LIST_PARAMS, INDEX => $index, DEVICE => 1, });
#        if ($result->{result}{web_url}) {
#          print $html->button('Watch now', '', {
#            GLOBAL_URL => $result->{result}{web_url},
#            target     => '_new',
#            class      => 'btn btn-xs',
#            BUTTON     => 1,
#          });
#        }
      }
    }

    if ($attr->{ACCOUNT_INFO}) {
      return 1;
    }
    delete $FORM{chg};
  }

  $service_info_subscribes .= iptv_users_list({ USER_ACCOUNT => $sunbscribe_count || 1 });

  if($attr->{PROFILE_MODE}) {
    return '', $service_info1, $service_info2, $service_info_subscribes;
  }

  print $service_info1 . $service_info2 . $service_info_subscribes;

  return 1;
}


#**********************************************************
=head2 iptv_new_devices($attr) - New devices

=cut
#**********************************************************
sub iptv_new_devices {

  if ($Tv_service->can('customer_add_device')) {
    $Tv_service->customer_add_device({ %FORM, %LIST_PARAMS, INDEX => $index, DEVICE => 1, });
  }
  else {
    print "New Device";
  }

  return 1;
}

#**********************************************************
=head2 iptv_activation_code($attr) - Activation code

=cut
#**********************************************************
sub iptv_activation_code {

  if ($Tv_service->can('get_code')) {
    $Tv_service->get_code({ %FORM, %LIST_PARAMS, INDEX => $index, DEVICE => 1, });
  }

  return 1;
}

#**********************************************************
=head2 iptv_watch_now($attr) - Activation code

=cut
#**********************************************************
sub iptv_watch_now {

  if ($Tv_service->can('get_url')) {
    my $result = $Tv_service->get_url({ %FORM, %LIST_PARAMS, INDEX => $index, DEVICE => 1, });
    if ($result->{result}{web_url}) {
#      print $html->button('Watch now', '', {
#        GLOBAL_URL => $result->{result}{web_url},
#        target     => '_new',
#        class      => 'btn btn-success',
#      });
      $html->redirect($result->{result}{web_url});

      return 1;
    }
    else {
      print "Error";
    }
  }

  return 1;
}

#**********************************************************
=head2 iptv_user_add($attr) - Users add

  Arguments:
    REGISTRATION
    SERVICE_ID
    SERVICE_ADD => 1
    TP_ID
    USER_INFO
    skip_step

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub iptv_user_add {
  my ($attr) = @_;

  if ($attr->{REGISTRATION}) {
    if (!$attr->{TP_ID}) {
      return 0;
    }
    elsif ($attr->{skip_step}) {
      return 1;
    }
  }

  if(! $users && $attr->{USER_INFO}) {
    $users = $attr->{USER_INFO};
  }

  if (!$attr->{SERVICE_ID}) {
    $Tariffs->{db} = $Iptv->{db};
    my $tp_list = $Tariffs->list({
      INNER_TP_ID => $attr->{TP_ID},
      SERVICE_ID  => '_SHOW',
      NEW_MODEL_TP=> 1,
      COLS_NAME   => 1
    });

    if ($Tariffs->{TOTAL}) {
      $FORM{SERVICE_ID} = $tp_list->[0]->{service_id};
      $attr->{SERVICE_ID} = $tp_list->[0]->{service_id};
    }
  }

  $Iptv->user_add($attr);
  if (!$Iptv->{errno}) {
    $Iptv->{ACCOUNT_ACTIVATE} = $attr->{USER_INFO}->{ACTIVATE};
    $Iptv->{ID} = $Iptv->{INSERT_ID};
    $Iptv->{MANDATORY_CHANNELS} = iptv_mandatory_channels($attr->{TP_ID});

    if (!$FORM{STATUS}) {
      $Iptv->user_info($Iptv->{ID});

      ::service_get_month_fee($Iptv, {
        SERVICE_NAME => $lang{TV},
        DO_NOT_USE_GLOBAL_USER_PLS => 1
      });

      if($attr->{SERVICE_ADD}) {
        $FORM{add}=1;
        $Tv_service = iptv_user_services($attr);
      }
    }

    #$message = "$lang{ADDED} ID: $Iptv->{ID}";
    #$FORM{chg} = $Iptv->{ID};
    return $Iptv->{ID};
  }

  return 0;
}

#**********************************************************
=head2 iptv_user_services($form_) - Service add

  Arguments:
    $form_ - INPUT FORM arguments

  Results:
    $Tv_service [obj]

=cut
#**********************************************************
sub iptv_user_services {
  my ($form_)=@_;

  $Iptv->{SERVICE_ID} ||= $form_->{SERVICE_ID};
  $Tv_service = undef;
  my DBI $db_ = $Iptv->{db}{db};

  if ($Iptv->{SERVICE_ID}) {
    $Tv_service = tv_load_service($Iptv->{SERVICE_MODULE}, { SERVICE_ID => $Iptv->{SERVICE_ID} });
  }
  else {
    delete($Iptv->{db}->{TRANSACTION});
    $db_->commit();
    $db_->{AutoCommit} = 1;
    return $Tv_service;
  }

  if (!::_error_show($Iptv) && $Tv_service) {

    my $action_result = iptv_account_action({
      %$form_,
      ID           => $Iptv->{ID},
      SUBSCRIBE_ID => $form_->{SUBSCRIBE_ID} || $Iptv->{SUBSCRIBE_ID},
      SCREEN_ID    => undef
    });

    if ($action_result) {
      ::_error_show($Iptv, {
        ID          => 835,
        #MESSAGE     => $Iptv->{errstr},
        MODULE_NAME => $Tv_service->{SERVICE_NAME}
      });

      $db_->rollback();
      delete $Iptv->{ID};
    }
    else {
      $html->message('info', $lang{INFO}, $Iptv->{MESSAGE}) if ($Iptv->{MESSAGE});
      if ($form_->{ARTICLE_ID} && in_array('Storage', \@MODULES)) {
        load_module('Storage', $html);
        storage_hardware({
          ADD_ONLY => 1,
          SERIAL   => $form_->{SERIAL_NUMBER},
          MAC      => $form_->{CID} || $form_->{MAC},
          add      => 1
        });
      }
    }

    if($Iptv->{MANDATORY_CHANNELS} && ref $Iptv->{MANDATORY_CHANNELS} eq 'HASH') {
      my $channel_list = join(',', keys %{ $Iptv->{MANDATORY_CHANNELS} } );
      $action_result = iptv_account_action({
        USER_CHANNELS => 1,
        UID           => $Iptv->{UID},
        ID            => $Iptv->{ID},
        IDS           => $channel_list
      });
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

  return $Tv_service;
}

#**********************************************************
=head2 iptv_mandatory_channels($tp_id) - Service add

  Arguments:
    $tp_id

  Results:
    $channels{num} => {
      ID
      FILTER_ID
      NAME
    }

=cut
#**********************************************************
sub iptv_mandatory_channels {
  my ($tp_id) = @_;

  my %tp_channels_list = ();
  $Tariffs->ti_list({ TP_ID => $tp_id, COLS_NAME => 1 });

  if ($Tariffs->{TOTAL} == 0) {
    return \%tp_channels_list;
  }

  my $channels_list = $Iptv->channel_ti_list(
    {
      INTERVAL_ID => $Tariffs->{list}->[0]->{id},
      MANDATORY   => 1,
      FILTER_ID   => '_SHOW',
      COLS_NAME   => 1
    }
  );

  foreach my $line (@{$channels_list}) {
    $tp_channels_list{ $line->{channel_id} }{NUM}       = $line->{channel_num};
    $tp_channels_list{ $line->{channel_id} }{NAME}      = $line->{name};
    $tp_channels_list{ $line->{channel_id} }{FILTER_ID} = $line->{filter_id};
  }

  return \%tp_channels_list;
}

#**********************************************************
=head2 iptv_account_action($attr) - Control external services

  Arguments:
    $attr
      negdeposit
      add
      change
      del
      channels
      PARENT_CONTROL
      USER_CHANNELS  - Chnage user channels
        IDS - Users channels ids
      SCREEN_ID
      SEND_MESSAGE
      ID
      UID
      TP_ID
      LOGIN
      CID
      STATUS
      SUBSCRIBE_ID

  Returns:

    True or False

=cut
#**********************************************************
sub iptv_account_action{
  my ($attr) = @_;

  my $result = 0;
  #my $service = '';

  if ($Iptv->{SERVICE_ID} && ! $Tv_service) {
    $Tv_service = tv_load_service( $Iptv->{SERVICE_MODULE}, { SERVICE_ID => $Iptv->{SERVICE_ID} } );
    if($Tv_service && $Tv_service->{SUBSCRIBE_COUNT}) {
      $attr->{SUBSCRIBE_COUNT} = $Tv_service->{SUBSCRIBE_COUNT};
    }
  }

  $Iptv->{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID} && !$Iptv->{TP_ID});
  my $uid = $attr->{UID} || $Iptv->{UID};
  if ( $attr->{USER_INFO} ){
    $users = $attr->{USER_INFO};
  }

  #Get chanels list
  if ( $FORM{UID} ){
    $Iptv->{CHANNELS} = iptv_user_channels_list({
      UID          => $uid,
      TP_ID        => $attr->{TP_ID} || $Iptv->{TP_ID},
      RETURN_PORTS => $conf{IPTV_STALKER_API_HOST}
    });
  }

  if ( $attr->{NEGDEPOSIT} ){
    if ( $Tv_service && $Tv_service->can('user_negdeposit') ) {
      $Tv_service->user_negdeposit( $attr );
      if ( $Tv_service->{errno} ){
        print "$Tv_service->{SERVICE_NAME} Error: [$Tv_service->{errno}]  $Tv_service->{errstr} UID: $uid $attr->{ID}\n";
      }
    }
  }
  elsif ( $attr->{add} ){
    if ( $conf{IPTV_DVCRYPT_FILENAME} ){
      iptv_dv_crypt();
    }

    if ( $conf{IPTV_USER_EXT_CMD} ){
      $Iptv->{ACTION} = 'down' if ($attr->{STATUS});
      iptv_ext_cmd( $conf{IPTV_USER_EXT_CMD}, { %{$users}, %{$Iptv} } );
    }

    if ( $Tv_service && $Tv_service->can('user_add') ){
      $users->info( $uid, { SHOW_PASSWORD => 1 } );
      $users->pi( { UID => $uid } );
      $Iptv->user_info( $attr->{ID} );
      $Iptv->{EMAIL} ||= $users->{EMAIL};
      $Tv_service->user_add( {
        %{$users},
        %{$Iptv},
        %{$attr},
        ID => $Iptv->{ID}
      } );

      if (! $Tv_service->{errno}) {
        if ($Tv_service->{SUBSCRIBE_ID}) {
          $Iptv->user_change({
            ID           => $Iptv->{ID},
            SUBSCRIBE_ID => $Tv_service->{SUBSCRIBE_ID}
          });
        }

        $result = 0;
      }
      else{
        $Iptv->{errno}  = $Tv_service->{errno};
        if ($Tv_service->{errno} == 1000) {
          $Iptv->{errstr} = $lang{WRONG_EMAIL};
        }
        elsif ($Tv_service->{errno} == 1001) {
          $Iptv->{errstr} = 'Create error';
        }
        elsif ($Tv_service->{errno} == 1002) {
          $Iptv->{errstr} = $lang{EXIST};
        }
        elsif($Tv_service->{errno} == 1003) {
          $Iptv->{errstr} = "E-mail $lang{EXIST}\n$Iptv->{EMAIL}";
        }
        elsif($Tv_service->{errno} == 1004) {
          $Iptv->{errstr} = "E-mail $lang{ERR_NOT_EXISTS}";
        }
        elsif($Tv_service->{errno} == 1005) {
          $Iptv->{errstr} = "No password";
        }
        elsif($Tv_service->{errno} == 1020) {
          $Iptv->{errstr} = "Incorrect response";
        }
        else {
          $Iptv->{errstr} = $Tv_service->{errstr};
        }
        $result = 1;
      }
    }

    if ( $attr->{SUBSCRIBE_ID} ){
      $Iptv->subscribe_change(
        {
          ID     => $FORM{SUBSCRIBE_ID},
          STATUS => 0
        }
      );
      if ( $conf{IPTV_SUBSCRIBE_CMD} ){
        $Iptv->subscribe_info( $attr->{SUBSCRIBE_ID} );
        $result = cmd(
          $conf{IPTV_SUBSCRIBE_CMD},
          {
            PARAMS => { %{$Iptv}, ACTION => 'SET' },
            ARGV   => 1,
            debug  => $conf{IPTV_CMD_DEBUG}
          }
        );
      }
    }
  }
  elsif ( $attr->{change} ){
    if ( $conf{IPTV_DVCRYPT_FILENAME} ){
      iptv_dv_crypt();
    }

    if ($Tv_service && $Tv_service->can('user_change')) {
      $users->info( $uid, { SHOW_PASSWORD => 1 } );
      $users->pi({ UID => $uid });
      $Tv_service->user_change({
        %$attr,
        %$users,
        %$Iptv,
        %FORM
      });

      if ( $Tv_service->{errno} ){
        $Iptv->{errno}  = $Tv_service->{errno};
        $Iptv->{errstr} = $Tv_service->{errstr};
        $result = 1;
      }
    }

    if ( $FORM{SUBSCRIBE_ID} ){
      $Iptv->subscribe_change({
        ID     => $attr->{SUBSCRIBE_ID},
        STATUS => 0
      });

      $Iptv->subscribe_info( $attr->{SUBSCRIBE_ID} );
      if ( $conf{IPTV_SUBSCRIBE_CMD} ){
        cmd(
          $conf{IPTV_SUBSCRIBE_CMD},
          {
            PARAMS => { %{$Iptv}, ACTION => 'SET' },
            debug  => $conf{IPTV_CMD_DEBUG}
          }
        );
      }
    }

    if ( $conf{IPTV_USER_EXT_CMD} ){
      $Iptv->{ACTION} = 'down' if ($FORM{STATUS});
      iptv_ext_cmd( $conf{IPTV_USER_EXT_CMD}, { %{$users}, %{$Iptv} } );
    }
  }
  elsif ( $attr->{channels} ){
    if ( $Tv_service && ref $Tv_service ne 'HASH') {
      if ($Tv_service->{SERVICE_USER_CHANNELS_FORM}) {
        my $fn = $Tv_service->{SERVICE_USER_CHANNELS_FORM};
        &{ \&$fn }( $attr );
      }
      elsif ($Tv_service->can('channels_change')) {
        #        print "ADD: $attr->{ADD_ID}<br>";
        #        print "DEL: $attr->{DEL} <br>\n";
        my @filters_list = ();
        my $channel_ti_list = $Iptv->channel_ti_list({
          ID        => join(';', @{$attr->{ADD_ID}}) || '-',
          FILTER_ID => '_SHOW',
          COLS_NAME => 1
        });

        foreach my $line (@$channel_ti_list) {
          if($line->{filter_id}) {
            push @filters_list, $line->{filter_id};
          }
        }

        $Tv_service->channels_change( {
          %{$users},
          %{$Iptv},
          %{$attr},
          FILTER_ID => join(',', @filters_list),
          ID        => $Iptv->{ID}
        } );
      }
    }
    elsif ( $conf{IPTV_DVCRYPT_FILENAME} ){
      iptv_dv_crypt();
    }
  }
  elsif ( $Tv_service && $attr->{USER_CHANNELS} ){
    my $channels = '';
    if ( $attr->{IDS} ){
      $channels = $attr->{IDS};
    }
    if ( $Iptv->{CHANNELS} ){
      $channels .= ($channels) ? ", $Iptv->{CHANNELS}" : $Iptv->{CHANNELS};
    }

    if($Tv_service->{SERVICE_CHANNELS_FORM}) {
      my $fn = $Tv_service->{SERVICE_USER_CHANNELS_FORM};
      &{ \&$fn }( $attr );
    }
    elsif ($Tv_service->can('change_channels')) {
      $Tv_service->change_channels( { %{$attr}, IDS => $channels } );
    }

    ::_error_show( $Tv_service, { ID => 832 } );
  }
  elsif ( $attr->{PARENT_CONTROL} ){
    if($Tv_service && $Tv_service->can('parent_control')) {
      $Tv_service->parent_control( { %{$users}, %{$Iptv}, %{$attr}, ID => $Iptv->{ID} } );
    }
  }
  elsif ( $attr->{SCREEN_ID} ){
    my %request = (
      %{$attr},
      CID => $attr->{CID},
    );

    if ( $attr->{DEL} ){
      $Iptv->users_screens_info( $Iptv->{ID}, { SCREEN_ID => $attr->{SCREEN_ID} } );
      ::_error_show( $Iptv );
      %request = (
        MAC          => $Iptv->{CID} || $attr->{CID},
        %{$attr},
        CID          => $Iptv->{CID} || $attr->{CID},
        ID           => $Iptv->{ID},
        TP_FILTER_ID => $Iptv->{FILTER_ID},
        SUB_ID       => $Iptv->{FILTER_ID},
        del          => 1,
        TYPE         => $attr->{TYPE} || 'subs_break_contract',
        DEVICE_DEL_TYPE => $attr->{DEVICE_DEL_TYPE} || 'device_break_contract'
      );

    }
    else{
      $request{BUNDLE_TYPE} = $attr->{BUNDLE_TYPE} || ($attr->{CID} ? 'subs_free_device' : undef) || 'subs_no_device';
    }

    if($Tv_service && $Tv_service->can('user_screens')) {
      $Tv_service->user_screens( \%request );
      if(! $Tv_service->{errno}) {
        $result = 1;
      }
    }

    ::_error_show( $Tv_service, { ID => 833, MESSAGE => ($Tv_service->{DEVICE_ID} ? "ID: " . $Tv_service->{DEVICE_ID} : q{}) } );
  }
  elsif ( $attr->{ACTIVATE} ){
    #iptv_account_action({ add => 1 });
  }
  elsif ( $attr->{chg} ){
    if ( $attr->{add_service} ){
      my $return = iptv_account_action(
        {
          %{$attr},
          chg => undef,
          ID  => $attr->{chg},
          add => 1
        }
      );

      if(! $return) {
        $html->message('info', $lang{ADDED}, $lang{ADDED});
      }

      return 0;
    }

    if ($Tv_service && $Tv_service->can('user_info')) {
      $users->pi( { UID => $uid } );
      $Tv_service->user_info({ %$attr, %$users, %{$Iptv} });

      if ( $Tv_service->{errno} ){
        my $message = '';
        if ( $Tv_service->{errno} == 404 ){
          if(! $user && ! $user->{UID}) {
            $message = $html->br().$html->button( "$lang{ADD} $Tv_service->{SERVICE_NAME}",
              "index=$index&UID=$uid&chg=$attr->{chg}&add_service=1", { BUTTON => 1 } );
            $Tv_service->{errstr}="$Tv_service->{SERVICE_NAME} $lang{ERR_NOT_EXISTS}";
          }
        }

        ::_error_show( $Tv_service, { ID => $Tv_service->{errno}, MESSAGE => $message } );
      }
      elsif($Tv_service->{RESULT} && $Tv_service->{RESULT}->{results} && ref $Tv_service->{RESULT}->{results} eq 'ARRAY') {
        result_former(
          {
            TABLE    => {
              width      => '100%',
              HIDE_TABLE => 1,
              caption    => $Tv_service->{SERVICE_NAME}. ' ('. ($#{ $Tv_service->{RESULT}->{results} } + 1) .')',
              ID         => 'IPTV_EXTERNAL_LIST',
            },
            DATAHASH     => $Tv_service->{RESULT}->{results},
            SKIP_TOTAL_FORM => 1,
            TOTAL        => 1
          }
        );
      }
    }
  }
  elsif ( $attr->{send_message} ){
    if ( $Tv_service && $Tv_service->can('send_message') ){
      $Tv_service->send_message($attr);
      if ( $Tv_service->{error} ){
        $Iptv->{errno}  = $Tv_service->{errno};
        $Iptv->{errstr} = $Tv_service->{errstr};
        $result = 1;
      }
    }
  }
  elsif ( $attr->{del} ){
    if ( $Tv_service && $Tv_service->can('user_del') ){
      $Tv_service->user_del({ %$attr, %{$Iptv}, ID => $attr->{del} });
      if ( $Tv_service->{error} ){
        $Iptv->{errno}  = $Tv_service->{errno};
        $Iptv->{errstr} = $Tv_service->{errstr};
        $result = 1;
      }
    }

    if ( $attr->{SUBSCRIBE_ID} ){
      $Iptv->subscribe_change(
        {
          ID     => $attr->{SUBSCRIBE_ID},
          STATUS => 6
        }
      );
      $Iptv->subscribe_info( $attr->{SUBSCRIBE_ID} );
      if ( $conf{IPTV_SUBSCRIBE_CMD} ){
        cmd(
          $conf{IPTV_SUBSCRIBE_CMD},
          {
            PARAMS => { %{$Iptv}, ACTION => 'SET' },
            debug  => $conf{IPTV_CMD_DEBUG}
          }
        );
      }
    }

    if ( $conf{IPTV_USER_EXT_CMD} ){
      $Iptv->{ACTION} = 'down' if ($FORM{STATUS});
      iptv_ext_cmd( $conf{IPTV_USER_EXT_CMD}, { %{$users}, %{$Iptv} } );
    }
  }
  elsif ( $attr->{hangup}) {
    if($Tv_service && $Tv_service->can('hangup')) {
      $Tv_service->hangup($attr);
      if ( $Tv_service->{error} ){
        $Iptv->{errno} = $Tv_service->{errno};
        $Iptv->{errstr} = $Tv_service->{errstr};
        $result = 1;
      }
    }

    $html->message( 'info', $lang{INFO}, $lang{HANGUP} );
  }

  return $result;
}

#*******************************************************************
=head2 iptv_chg_tp($attr) - Change user tarif plan

  Arguments:
    $attr
      USER_INFO


=cut
#*******************************************************************
sub iptv_chg_tp{
  my ($attr) = @_;

  my $user;

  if ( defined( $attr->{USER_INFO} ) ){
    $user = $attr->{USER_INFO};
    $Iptv = $Iptv->user_info( $FORM{ID} );
    if ( $Iptv->{TOTAL} < 1 ){
      $html->message( 'info', $lang{INFO}, $lang{NOT_ACTIVE} );
      return 0;
    }
  }
  else{
    $html->message( 'err', $lang{ERROR}, $lang{USER_NOT_EXIST} );
    return 0;
  }

  my $period = $FORM{period} || 0;

  if (
    $Iptv->{MONTH_FEE} && $Iptv->{MONTH_FEE} > 0
      && !$Iptv->{STATUS}
      && !$users->{DISABLE}
      && ( $users->{DEPOSIT} + $users->{CREDIT} > 0
      || $Iptv->{POSTPAID_ABON}
      || $Iptv->{PAYMENT_TYPE} == 1)
  )
  {
    if ( $users->{ACTIVATE} ne '0000-00-00' ){
      my ($Y, $M, $D) = split( /-/, $users->{ACTIVATE}, 3 );
      $M--;
      $Iptv->{ABON_DATE} = POSIX::strftime( '%Y-%m-%d', localtime( (POSIX::mktime( 0, 0, 0, $D, $M, ($Y - 1900), 0, 0,
        0 ) + 31 * 86400 + (($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} * 86400 : 0)) ) );
    }
    else{
      my ($Y, $M, $D) = split( /-/, $DATE, 3 );
      $M++;
      if ( $M == 13 ){
        $M = 1;
        $Y++;
      }
      if ( $conf{START_PERIOD_DAY} ){
        $D = $conf{START_PERIOD_DAY};
      }
      else{
        $D = '01';
      }
      $Iptv->{ABON_DATE} = sprintf( "%d-%02d-%02d", $Y, $M, $D );
    }
  }

  my $Shedule = Shedule->new( $db, $admin, \%conf );

  if ( $FORM{set} ){
    if ( !$permissions{0}{4} ){
      $html->message( 'err', $lang{ERROR}, $lang{ERR_ACCESS_DENY} );
      return 0;
    }

    if ( $period > 0 ){
      my ($year, $month, $day);
      if ( $period == 1 ){
        ($year, $month, $day) = split( /-/, $Iptv->{ABON_DATE}, 3 );
      }
      else{
        ($year, $month, $day) = split( /-/, $FORM{DATE}, 3 );
      }
      $Shedule->add(
        {
          UID          => $user->{UID},
          TYPE         => 'tp',
          ACTION       => "$FORM{ID}:$FORM{TP_ID}",
          D            => $day,
          M            => $month,
          Y            => $year,
          COMMENTS     => "$lang{FROM}: $Iptv->{TP_ID}:$Iptv->{TP_NAME}",
          ADMIN_ACTION => 1,
          MODULE       => 'Iptv'
        }
      );

      if ( !_error_show( $Shedule ) ){
        $html->message( 'info', $lang{CHANGED}, "$lang{CHANGED}" );
        $Iptv->user_info( $FORM{ID} || $Iptv->{UID} );
      }
    }
    else{
      $Iptv->user_change( { %FORM } );
      if ( !_error_show( $Iptv ) ){

        #Take Fees
        if ( !$Iptv->{STATUS} && $FORM{GET_ABON} ){
          service_get_month_fee( $Iptv, { SERVICE_NAME => $lang{TV} } );
        }
        $html->message( 'info', $lang{CHANGED}, "$lang{CHANGED}" );
        $Iptv->user_info( $FORM{ID} || $user->{UID} );
        if($conf{IPTV_TRANSFER_SERVICE}) {
          my $service_list = iptv_transfer_service($Iptv);
          if($service_list) {
            iptv_transfer_service($Iptv, {
              SERVICE_LIST => $service_list
            });
          }
        }
        else {
          iptv_user_channels( { QUIET => 1, USER_INFO => $Iptv } );
        }

        $Iptv->{MANDATORY_CHANNELS} = iptv_mandatory_channels($FORM{TP_ID});
        $FORM{change} = 1;
        if (iptv_user_services(\%FORM)) {
          _error_show( $Iptv );
        }
        #if ( iptv_account_action( { %FORM, CHANGE_TP => 1 } ) ){
        #  _error_show( $Iptv );
        #}
      }
    }
  }
  elsif ( $FORM{del} ){
    $Shedule->del(
      {
        UID => $user->{UID},
        ID  => $FORM{SHEDULE_ID}
      }
    );
    $html->message( 'info', $lang{DELETED}, "$lang{DELETED} [$FORM{SHEDULE_ID}]" );
  }

  $Shedule->info(
    {
      UID    => $user->{UID},
      TYPE   => 'tp',
      MODULE => 'Iptv'
    }
  );

  if ( $Shedule->{TOTAL} > 0 ){
    #tp_id, $action
    my (undef, $action)=split(/:/, $Shedule->{ACTION});
    my $table = $html->table(
      {
        width      => '100%',
        caption    => "$lang{SHEDULE}",
        rows       =>
          [ [ "$lang{TARIF_PLAN}:", $action ],
            [ "$lang{DATE}:", "$Shedule->{D}-$Shedule->{M}-$Shedule->{Y}" ],
            [ "$lang{ADMIN}:", "$Shedule->{ADMIN_NAME}" ],
            [ "$lang{ADDED}:", "$Shedule->{DATE}"       ],
            [ "ID:", "$Shedule->{SHEDULE_ID}"           ]
          ],
        ID         => 'SHEDULE_INFO'
      }
    );
    $Tariffs->{TARIF_PLAN_SEL} = $table->show() . $html->form_input( 'SHEDULE_ID', "$Shedule->{SHEDULE_ID}",
      { TYPE => 'HIDDEN' } );
    $Tariffs->{ACTION} = 'del';
    $Tariffs->{LNG_ACTION} = $lang{DEL};
  }
  else{
    $Tariffs->{TARIF_PLAN_SEL} = $html->form_select(
      'TP_ID',
      {
        SELECTED       => $Iptv->{TP_ID},
        SEL_LIST       => $Tariffs->list( {
          MODULE       => 'Iptv',
          SERVICE_ID   => $FORM{SERVICE_ID},
          NEW_MODEL_TP => 1,
          COLS_NAME    => 1 } ),
        SEL_KEY        => 'tp_id',
        SEL_VALUE      => 'id,name',
        NO_ID          => 1,
        MAIN_MENU      => ($permissions{0}{10}) ? get_function_index( 'iptv_tp' ) : undef,
        MAIN_MENU_ARGV => "TP_ID=$Iptv->{TP_ID}"
      }
    );
    $Tariffs->{PARAMS} .= form_period( $period, { ABON_DATE => $Iptv->{ABON_DATE} } );
    $Tariffs->{ACTION} = 'set';
    $Tariffs->{LNG_ACTION} = $lang{CHANGE};
  }

  $Tariffs->{UID}     = $attr->{USER_INFO}->{UID};
  $Tariffs->{TP_ID}   = $Iptv->{TP_ID};
  $Tariffs->{TP_NAME} = ($Iptv->{TP_NUM}) ? "$Iptv->{TP_NUM}:$Iptv->{TP_NAME}" : $lang{NOT_EXIST};
  $Tariffs->{ID}      = $Iptv->{ID};
  $html->tpl_show( templates( 'form_chg_tp' ), $Tariffs );

  return 1;
}


1;