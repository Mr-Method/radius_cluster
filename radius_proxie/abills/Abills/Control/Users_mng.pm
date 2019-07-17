=head1 NAME

  User manage

=cut

use warnings FATAL => 'all';
use strict;
use Abills::Base qw(in_array date_diff
  gen_time check_time show_hash int2byte load_pmodule2);
use Abills::Defs;
use Attach;
use Contacts;

our ($db,
 $html,
 %lang,
 $admin,
 %permissions,
 @MONTHES,
 @WEEKDAYS,
 %uf_menus,
 %module,
 $ui,
 @bool_vals,
 @state_colors,
 @state_icon_colors,
 @status
);

my @priority_colors = ('btn-default', 'btn-info', 'btn-success', 'btn-warning', 'btn-danger');

#**********************************************************
=head2 form_users($attr) - User account managment form

=cut
#**********************************************************
sub form_users {
  my ($attr) = @_;
#  $users->contacts_migrate();

  if ($FORM{PRINT_CONTRACT}) {
    load_module('Docs', $html);
    docs_contract({ SEND_EMAIL => ($FORM{SEND_EMAIL}) ? 1 : 0 });
    return 1;
  }
  elsif ($FORM{SEND_SMS_PASSWORD}) {
    load_module('Sms', $html);
    my Users $user_info = $users->info($FORM{UID}, { SHOW_PASSWORD => 1 });
    my $pi        = $users->pi({ UID => $FORM{UID} });
    my $message   = $html->tpl_show(_include('sms_password_recovery', 'Sms'), { %$user_info, %$pi }, { OUTPUT2RETURN => 1 });
    my $sms_id    = sms_send(
      {
        NUMBER => $users->{PHONE},
        MESSAGE=> $message,
        UID    => $users->{UID},
      });

    if ( $sms_id ) {
      $html->message('info', "$lang{INFO}", "$lang{PASSWD} SMS $lang{SENDED}". (($sms_id > 1) ? "\n ID: $sms_id" : '') );
    }
    return 1;
  }
  elsif($FORM{import}) {

    if (!$permissions{0}{17}) {
      $html->message('err', $lang{ERROR}, "$lang{IMPORT} $lang{ERR_ACCESS_DENY}");
      return 0;
    }

    if ($FORM{add}) {
      my $import_accounts = import_former(\%FORM);
      my $total = $#{ $import_accounts } + 1;

      my $main_id = 'UID';
      if(! $import_accounts->[0]->{UID}) {
        if ($import_accounts->[0]->{LOGIN}) {
          $main_id = 'LOGIN';
        }
        elsif($import_accounts->[0]->{MAIN_ID}) {
          $main_id = $import_accounts->[0]->{MAIN_ID};
        }
      }

      require Bills;
      Bills->import();
      my $Bills = Bills->new($db, $admin, \%conf);

      foreach my $_user (@$import_accounts) {
        my $list = $users->list({
          LOGIN    => '_SHOW',
          $main_id => $_user->{$main_id},
          BILL_ID  => ($_user->{DEPOSIT}) ? '_SHOW' : undef,
          COLS_NAME=> 1
         });

        if($users->{TOTAL} > 0) {
          if ($_user->{DEPOSIT}) {
            $Bills->change({ BILL_ID => $list->[0]->{bill_id}, DEPOSIT => $_user->{DEPOSIT} });
          }
          $users->change($list->[0]->{uid}, { %$_user, UID => $list->[0]->{uid} });
          $users->pi_change({ %$_user, UID => $list->[0]->{uid} });
          print $html->button($list->[0]->{login}, "index=15&UID=$list->[0]->{uid}") . " ($list->[0]->{uid})' Ok". $html->br();
        }
      }

      $html->message('info', $lang{INFO}, "$lang{ADDED}\n $lang{FILE}: $FORM{UPLOAD_FILE}{filename}\n Size: $FORM{UPLOAD_FILE}{Size}\n Count: $total");

      return 1
    }

    my $import_fields = $html->form_select('IMPORT_FIELDS',
      {
        SELECTED    => $FORM{IMPORT_FIELDS},
        SEL_ARRAY   => [ 'LOGIN',
          'FIO',
          'PHONE',
          'ADDRESS_STREET',
          'ADDRESS_BUILD',
          'ADDRESS_FLAT',
          'PASPORT_NUM',
          'PASPORT_DATE',
          'PASPORT_GRANT',
          'CONTRACT_ID',
          'CONTRACT_DATE',
          'EMAIL',
          'COMMENTS'
        ],
        EX_PARAMS   => 'multiple="multiple"'
      });

    my $encode = $html->form_select(
      'ENCODE',
      {
        SELECTED  => $FORM{ENCODE},
        SEL_ARRAY => [ '', 'win2utf8', 'utf82win', 'win2koi', 'koi2win', 'win2iso', 'iso2win', 'win2dos', 'dos2win' ],
      }
    );

    my $extra_row = $html->tpl_show(templates('form_row'), {
      ID    => 'ENCODE',
      NAME  => $lang{ENCODE},
      VALUE => $encode }, { OUTPUT2RETURN => 1 });

    $html->tpl_show(templates('form_import'), {
      IMPORT_FIELDS     => 'LOGIN,CONTRACT_ID,FIO,PHONE,ADDRESS_STREET,ADDRESS_BUILD,ADDRESS_FLAT,PASPORT_NUM,PASPORT_GRANT',
      CALLBACK_FUNC     => 'form_users',
      IMPORT_FIELDS_SEL => $import_fields,
      EXTRA_ROWS        => $extra_row
    } );

    return 1;
  }
  elsif($FORM{bill_correction}) {
    my $user_info = $attr->{USER_INFO};
    form_bill_correction($user_info);
    return 1;
  }
  elsif($FORM{SUMMARY_SHOW}) {
    require Control::Users_slides;
    if ($FORM{EXPORT}) {
      print "Content-Type: application/json; charset=utf8\n\n";
      print user_full_info();
    }
    else {
      my $user_info;
      $user_info->{METRO_PANELS} = user_full_info();
      $user_info->{METRO_PANELS} =~ s/\r\n|\n//gm;
      $user_info->{HTML_STYLE}   = $html->{HTML_STYLE} || 'default_adm';
      $html->tpl_show(templates('form_client_view_metro'), $user_info);
    }
    return 1;
  }

  if ($attr->{USER_INFO}) {
    my Users $user_info = $attr->{USER_INFO};
    if (_error_show($user_info)) {
      return 0;
    }
    #Make service menu
    if (defined($FORM{newpassword})) {
      if (form_passwd({ USER_INFO => $user_info })) {
        return 0;
      }
    }

    if ($FORM{change}) {
      if (!$permissions{0}{4}) {
        $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
        return 0;
      }

      if (!$permissions{0}{9} && defined($user_info->{CREDIT}) && defined($FORM{CREDIT}) && $user_info->{CREDIT} != $FORM{CREDIT}) {
        $html->message('err', $lang{ERROR}, "$lang{CHANGE} $lang{CREDIT} $lang{ERR_ACCESS_DENY}");
        delete($FORM{CREDIT});
      }

      if (!$permissions{0}{11} && defined($FORM{REDUCTION}) && $user_info->{REDUCTION} != $FORM{REDUCTION}) {
        $html->message('err', $lang{ERROR}, "$lang{REDUCTION} $lang{ERR_ACCESS_DENY}");
        delete($FORM{REDUCTION});
      }

      if (!$permissions{0}{19}) {
        #$html->message('err', $lang{ERROR}, "$lang{EXPIRE} $lang{ERR_ACCESS_DENY}");
        delete($FORM{ACTIVATE});
      }
      if (!$permissions{0}{20}) {
        #$html->message('err', $lang{ERROR}, "$lang{EXPIRE} $lang{ERR_ACCESS_DENY}");
        delete($FORM{EXPIRE});
      }

      if ($permissions{0}{13} && $user_info->{DISABLE} =~ /\d+/&& $user_info->{DISABLE} == 2) {
        $FORM{DISABLE} = 2;
      }

      if ($conf{FIXED_FEES_DAY} &&  $FORM{ACTIVATE} && $FORM{ACTIVATE} ne '0000-00-00') {
        my $d = (split(/-/, $FORM{ACTIVATE}))[2];
        if (in_array($d, ['1', '01', '29', '30', '31' ])) {
          $html->message('info', $lang{CHANGE}, "$lang{ACTIVATE} $FORM{ACTIVATE}->0000-00-00");
          $FORM{ACTIVATE}='0000-00-00';
        }
      }

      $user_info->change($user_info->{UID}, {%FORM});
      if ($user_info->{errno}) {
        _error_show($user_info);
        user_form();
        return 0;
      }
      else {
        $html->message('info', $lang{CHANGED}, $lang{CHANGED} .' ' . ($users->{info} || '') );
        if (defined($FORM{FIO})) {
          $users->pi_change({%FORM});
        }

        if ($FORM{CREDIT} && $user_info->{CREDIT} && $user_info->{CREDIT} ne $FORM{CREDIT}) {
          $user_info->{CREDIT} = $FORM{CREDIT};
        }
        cross_modules_call('_payments_maked', { USER_INFO => $user_info, CHANGE_CREDIT => 1 });

        #External scripts
        if ($conf{external_userchange}) {
          if (!_external($conf{external_userchange}, \%FORM)) {
            return 0;
          }
        }
        if ($attr->{REGISTRATION}) {
          return 0;
        }
      }
    }
    elsif ($FORM{del_user} && $FORM{COMMENTS} && $index == 15 && $permissions{0}{5}) {
      user_del({ USER_INFO => $user_info });
      return 0;
    }
    else {
      delete($FORM{add});
      print "<div class='col-md-12 col-lg-6'>";
      user_form({ USER_INFO => $user_info });
      user_services({ USER_INFO => $user_info });
      print "</div>"
          . "<div class='col-md-12 col-lg-6'>";
      user_pi({ %$attr, USER_INFO => $user_info });
      print "</div>";
    }

    return 0;
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 0;
    }

    if ($FORM{newpassword}) {

      $conf{PASSWD_LENGTH} //= 6;

      if (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
        $html->message('err', $lang{ERROR}, "$lang{ERR_SHORT_PASSWD} $conf{PASSWD_LENGTH}");
      }
      elsif ($FORM{newpassword} eq $FORM{confirm}) {
        $FORM{PASSWORD} = $FORM{newpassword};
      }
      elsif ($FORM{newpassword} ne $FORM{confirm}) {
        $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_CONFIRM}");
      }
      else {
        $FORM{PASSWORD} = $FORM{newpassword};
      }
    }

    $FORM{REDUCTION} = 100 if ($FORM{REDUCTION} && $FORM{REDUCTION} =~ /\d+/ && $FORM{REDUCTION} > 100);

    # Add not confirm status
    if ($permissions{0}{13}) {
      $FORM{DISABLE}=2;
    }

    if ($conf{FIXED_FEES_DAY} &&  $FORM{ACTIVATE} && $FORM{ACTIVATE} ne '0000-00-00') {
      my $d = (split(/-/, $FORM{ACTIVATE}))[2];

      if (in_array($d, [1, 29, 30, 31 ])) {
        $html->message('info', $lang{CHANGE}, "$lang{ACTIVATE} $FORM{ACTIVATE}->0000-00-00");
        $FORM{ACTIVATE}='0000-00-00';
      }
    }

    my Users $user_info = $users->add({%FORM});
    if (_error_show($users, { MESSAGE =>
        "$lang{LOGIN}: " . (($users->{errno} && $users->{errno} == 7) ? $html->button($FORM{LOGIN}, "index=11&LOGIN=". ($FORM{LOGIN} || q{}) ) : '$FORM{LOGIN}' )
      })) {

      if ($FORM{NOTIFY_FN}) {
        my $fn = $FORM{NOTIFY_FN};
        if (defined(&$fn)) {
          &{ \&{$fn} }({ %FORM, NOTIFY_ID => $FORM{NOTIFY_ID} });
        }
      }

      delete($FORM{add});
      return 0;
    }
    else {
      $html->message('info', $lang{ADDED}, "$lang{ADDED} '$user_info->{LOGIN}' / [$user_info->{UID}]");
      if ($conf{external_useradd}) {
        if (!_external($conf{external_useradd}, {%FORM})) {
          return 1;
        }
      }

      $user_info = $users->info($user_info->{UID}, { SHOW_PASSWORD => 1 });
      $LIST_PARAMS{UID} = $user_info->{UID};
      $FORM{UID}        = $user_info->{UID};
      user_pi({ %$attr, REGISTRATION => 1 });

      $user_info->pi({ UID => $users->{UID} });
      $html->tpl_show(templates('form_user_info'), $user_info);

      if ($FORM{NOTIFY_FN}) {
        my $fn = $FORM{NOTIFY_FN};
        if (defined(&$fn)) {
          &{ \&{$fn} }( { %FORM, NOTIFY_ID => $FORM{NOTIFY_ID} } );
        }
      }

      if ($FORM{COMPANY_ID}) {
        form_companie_admins($attr);
      }
      return 1;
    }
  }
  #Multi user operations
  elsif ($FORM{MULTIUSER}) {
    my @multiuser_arr = split(/, /, $FORM{IDS} || q{});

    #my $count         = 0;
    my %CHANGE_PARAMS = (
      SKIP_STATUS_CHANGE => $FORM{DISABLE} ? undef : 1
    );
    while (my ($k, undef) = each %FORM) {
      if ($k =~ /^MU_(\S+)/) {
        my $val = $1;
        $CHANGE_PARAMS{$val} = $FORM{$val};
      }
    }

    if (!defined($FORM{DISABLE})) {
      $CHANGE_PARAMS{UNCHANGE_DISABLE} = 1;
    }
    else {
      $CHANGE_PARAMS{DISABLE} = $FORM{MU_DISABLE} || 0;
    }

    if ($#multiuser_arr < 0) {
      $html->message('err', $lang{MULTIUSER_OP}, "$lang{SELECT_USER}");
    }
    elsif($FORM{MU_DELIVERY} || $FORM{DELIVERY_CREATE}){
      use Msgs;
      my $Msgs  = Msgs->new($db, $admin, \%conf);
      my $delivery_info = $Msgs->msgs_delivery_info($FORM{DELIVERY});

      if ($FORM{DELIVERY_CREATE}) {
        $Msgs->msgs_delivery_add({ %FORM,
          SEND_DATE => $FORM{DELIVERY_SEND_DATE},
          SEND_TIME => $FORM{DELIVERY_SEND_TIME},
          SUBJECT   => $FORM{DELIVERY_COMMENTS}
      });
        $FORM{DELIVERY} = $Msgs->{DELIVERY_ID};
        $html->message( 'info', $lang{INFO}, "$lang{DELIVERY} $lang{ADDED} ID:$FORM{DELIVERY}" ) if (!$Msgs->{errno});
     }
     $Msgs->delivery_user_list_add(
     {
        MDELIVERY_ID => $FORM{DELIVERY},
        IDS          => $FORM{IDS},
        SEND_METHOD  => $delivery_info->{SEND_METHOD},
        # STATUS       => $delivery_info->{SEND_STATUS},
        # SENDED_DATE  => $delivery_info->{SEND_DATE} . ' '. $delivery_info->{SEND_TIME}
     });
     $html->message( 'info', $lang{INFO}, "$Msgs->{TOTAL} $lang{USERS_ADDED_TO_DELIVERY} №:$FORM{DELIVERY}" ) if (!$Msgs->{errno});
    }
    elsif (scalar keys %CHANGE_PARAMS < 1) {
      #$html->message('err', $lang{MULTIUSER_OP}, "$lang{SELECT_USER}");
    }
    else {
      foreach my $uid (@multiuser_arr) {
        if ($FORM{DEL} && $FORM{MU_DEL}) {
          my $user_info = $users->info($uid);
          user_del({ USER_INFO => $user_info });

          _error_show($users);
        }
        else {
          $users->change($uid, { UID => $uid, %CHANGE_PARAMS });
          if (_error_show($users)) {
            return 0;
          }
        }
      }
      $html->message('info', $lang{MULTIUSER_OP}, "$lang{TOTAL}: " . ($#multiuser_arr + 1) . " IDS: $FORM{IDS}");
    }
  }

  return 1;
}

#**********************************************************
=head2 form_bill_correction($attr) - Personal information form

=cut
#**********************************************************
sub form_bill_correction {
  my ($attr) = @_;

  if (! $permissions{0} || ! $permissions{0}{15}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    return 1;
  }

  $attr->{ACTION}='change_bill';
  $attr->{LNG_ACTION}=$lang{CHANGE};
  if ($FORM{change_bill}) {
    require Bills;
    Bills->import();
    my $Bill = Bills->new($db, $admin, \%conf);
    $Bill->change(\%FORM);
    if (! _error_show($Bill)) {
      $html->message('info', $lang{INFO}, $lang{CHANGED});
      $attr->{DEPOSIT}=sprintf("%.2f", $FORM{DEPOSIT});
    }
  }

  print $html->tpl_show(templates('form_bill_deposit'), $attr);

  return 1;
}

#**********************************************************
=head2 form_social_networks($attr)

=cut
#**********************************************************
sub form_social_networks {
  my($network_info)=@_;

  my ($network, $id) = split(/, /, $network_info);
  $html->message( 'info', $lang{INFO}, $network_info);
  use Abills::Auth::Core;
  my $Auth = Abills::Auth::Core->new( {
    CONF      => \%conf,
    AUTH_TYPE => ucfirst($network)
  } );

  if ($Auth->can( 'get_info' )) {
    $Auth->get_info( { CLIENT_ID => $id } );

    if($Auth->{errno}) {
      $html->message( 'err', $lang{ERROR}, "$Auth->{errno} $Auth->{errstr}");
    }

    my $table = $html->table(
      {
        width      => '400',
      }
    );

    foreach my $key (sort keys %{ $Auth->{result}  }) {
      my $result = '';
      if(ref $Auth->{result}->{$key} eq 'HASH') {
        $result = show_hash($Auth->{result}->{$key}, { OUTPUT2RETURN => 1, DELIMITER => $html->br() });
      }
      elsif(ref $Auth->{result}->{$key} eq 'ARRAY') {
        $result = join($html->br(), @{ $Auth->{result}->{$key} });
      }
      else {
        $result = $Auth->{result}->{$key};
      }
      Encode::_utf8_off($result);
      $table->addrow($key, $result);
    }
    print $table->show();
  }

  return 1;
}

#**********************************************************
=head2 user_pi($attr) - Personal information form

=cut
#**********************************************************
sub user_pi {
  my ($attr) = @_;

  my $Attach = Attach->new($db, $admin, \%conf);
  my $Contacts = Contacts->new($db, $admin, \%conf);
  my Users $user;

  if ($attr->{USER_INFO}) {
    $user = $attr->{USER_INFO};
  }
  elsif($FORM{UID}) {
    $user = $users->info($FORM{UID});
  }
  elsif($users) {
    $user = $users;
  }

  if ($FORM{REG} && $conf{CONTACTS_NEW} && $FORM{DEFAULT_CONTACT_TYPES}){
    my @default_types = split( /,\s+/, $FORM{DEFAULT_CONTACT_TYPES} );

    foreach my $contact_type_id ( @default_types ){
      my $contact = $FORM{"CONTACT_TYPE_$contact_type_id"};
      if ( $contact && $contact ne '' ){
        $Contacts->contacts_add( {
          TYPE_ID => $contact_type_id,
          VALUE   => $contact,
          UID     => $FORM{UID}
        });
        _error_show( $user );
      }
    }

  }

  if ($FORM{SOCIAL_INFO}) {
    form_social_networks($FORM{SOCIAL_INFO});
  }
  elsif ($FORM{PHOTO}) {
    form_image_mng($user);
    return 0;
  }
  elsif ($FORM{ATTACHMENT}) {
    if ($FORM{del}) {
      if ($FORM{ATTACHMENT} =~ /(.+):(.+)/) {
        $FORM{TABLE}      = $1 . '_file';
        $FORM{ATTACHMENT} = $2;
      }

      $Attach->attachment_del({
        ID    => $FORM{ATTACHMENT},
        TABLE => $FORM{TABLE},
        UID   => $user->{UID}
      });

      if ( ! _error_show($Attach) ) {
        $html->message('info', $lang{INFO}, "$lang{FILE}: '$FORM{ATTACHMENT}' $lang{DELETED}");

      }

      return 1;
    }

    form_show_attach({ UID => $user->{UID} });
    return 1;
  }
  elsif ($FORM{address}) {
    form_address_sel();
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}");
      return 0;
    }

    $user->pi_add({%FORM});
    if ( !$user->{errno} ){
      return 0 if ($attr->{REGISTRATION});
      $html->message('info', $lang{ADDED}, "$lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    if (!$permissions{0}{4}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}");
      return 0;
    }

    $user->pi_change({%FORM});
    if (!$user->{errno}) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
    }
  }
  elsif ( $FORM{CONTACTS} ){
    return user_contacts_renew();
  }

  _error_show($user);

  my $user_pi = $users->pi();

  if ($user_pi->{TOTAL} < 1 && $permissions{0}{1}) {
    if ($attr->{ACTION}) {
      $user_pi->{ACTION}     = $attr->{ACTION};
      $user_pi->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user_pi->{ACTION}     = 'add';
      $user_pi->{LNG_ACTION} = $lang{ADD};
    }
  }
  elsif ($permissions{0}{4}) {
    if ($attr->{ACTION}) {
      $user_pi->{ACTION}     = $attr->{ACTION};
      $user_pi->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user_pi->{ACTION}     = 'change';
      $user_pi->{LNG_ACTION} = $lang{CHANGE};
    }
    $user_pi->{ACTION} = 'change';
  }

  $index = 30 if (!$attr->{MAIN_USER_TPL});
  #Info fields
  $user_pi->{INFO_FIELDS} = form_info_field_tpl({ VALUES  => $user_pi });

  if (in_array('Docs', \@MODULES)) {
    if ($user_pi->{UID}){
      $user_pi->{PRINT_CONTRACT} = $html->button( "$lang{PRINT}",
        "qindex=15&UID=$user_pi->{UID}&PRINT_CONTRACT=$user_pi->{UID}" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''),
        { ex_params => ' target=new', class => 'print' } );
    }

    if ($conf{DOCS_CONTRACT_TYPES}) {
      $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
      my (@contract_types_list) = split(/;/, $conf{DOCS_CONTRACT_TYPES});

      my %CONTRACTS_LIST_HASH = ();
      $FORM{CONTRACT_SUFIX} = "|$user_pi->{CONTRACT_SUFIX}" if ($user_pi->{CONTRACT_SUFIX});
      $user_pi->{CONTRACT_SUFIX} = "($user_pi->{CONTRACT_SUFIX})" if ($user_pi->{CONTRACT_SUFIX});
      foreach my $line (@contract_types_list) {
        my ($prefix, $sufix, $name) = split(/:/, $line);
        $prefix =~ s/ //g;
        $CONTRACTS_LIST_HASH{"$prefix|$sufix"} = $name;
      }

      $user_pi->{CONTRACT_TYPE} = $html->form_select(
        'CONTRACT_TYPE',
        {
          SELECTED => $FORM{CONTRACT_SUFIX},
          SEL_HASH => { '' => '', %CONTRACTS_LIST_HASH },
          NO_ID    => 1,
          ID       => 'CONTRACT_TYPE'
        }
      );

      $user_pi->{CONTRACT_TYPE} = $html->tpl_show(templates('form_row'), { ID => "CONTRACT_TYPE",
          NAME  => $lang{TYPE},
          VALUE => $user_pi->{CONTRACT_TYPE} }, { OUTPUT2RETURN => 1 });
    }
  }

  if ($conf{ACCEPT_RULES}) {
    $user_pi->{ACCEPT_RULES_FORM} .= $html->tpl_show(templates('form_row'), {
        ID       => 'ACCEPT_RULES',
        NAME     => $lang{ACCEPT_RULES},
        VALUE    => $html->element('span',  ($user_pi->{ACCEPT_RULES}) ? $lang{YES} : $lang{NO}, { class => 'label ' . (($user_pi->{ACCEPT_RULES}) ? 'bg-green' : 'bg-warning') } ),
      },
      { OUTPUT2RETURN => 1 });
  }

  if ($conf{ADDRESS_REGISTER}) {
    my $location_id = $FORM{LOCATION_ID} || $user_pi->{LOCATION_ID};
    my $Address;

    if ($FORM{LOCATION_ID}) {
      require Address;
      Address->import();
      $Address = Address->new($db, $admin, \%conf);

      $Address->address_info($FORM{LOCATION_ID} || $user_pi->{LOCATION_ID});
    }
    else {
      $Address = {};
    }

    if ($location_id && in_array('Maps', \@MODULES)) {
      if ($user_pi->{COORDX} && $user_pi->{COORDX} == 0) {
        $user_pi->{MAP_BTN} = $html->button("", "get_index=maps_add_2&LOCATION_ID=$location_id&header=1&LOCATION_TYPE=1",
            { class => 'btn btn-default btn-sm', target => '_map', ex_params => "data-tooltip-position='top' data-tooltip='$lang{MAP} $lang{ADD}'", ICON => 'fa fa-map-marker'});
      }
      else {
        $user_pi->{MAP_BTN} = $html->button("", "get_index=maps_show_poins&full=1&show_build=". ($location_id || q{})
            ."&UID=". ($FORM{UID} || q{}) . "&header=1", { class => 'btn btn-default btn-sm', target => '_map',  ex_params => "data-tooltip-position='top' data-tooltip='$lang{MAP}'", ICON => 'fa fa-globe' });
      }
    }
    $Address->{FLAT_CHECK_FREE} = 1;
    $user_pi->{ADDRESS_TPL} = $html->tpl_show(templates('form_address_sel'), { %FORM, %$user_pi, %$Address },
      { OUTPUT2RETURN => 1, ID => 'form_address_sel' });
  }
  else {
    my $countries_hash;
    ($countries_hash, $user_pi->{COUNTRY_SEL}) = sel_countries({ NAME    => 'COUNTRY_ID',
        COUNTRY => $user_pi->{COUNTRY_ID} });
    $user_pi->{ADDRESS_TPL} = $html->tpl_show(templates('form_address'), $user_pi, { OUTPUT2RETURN => 1 });
  }

  # New contacts
  if ($conf{CONTACTS_NEW}){
    my $user_contacts_list = $Contacts->contacts_list({
      UID       => $FORM{UID},
      VALUE     => '_SHOW',
      PRIORITY  => '_SHOW',
      TYPE      => '_SHOW',
      HIDDEN    => '0'
    });
    _error_show( $Contacts );

    my $user_contact_types = $Contacts->contact_types_list( {
      SHOW_ALL_COLUMNS => 1,
      COLS_NAME        => 1,
      HIDDEN           => '0',
    } );
    _error_show( $Contacts );

    my $first_time_migrate_contacts = sub {
      my ($type_id, $field_name, $value) = @_;

      # Change contact
      $Contacts->contacts_add({
        TYPE_ID  => $type_id,
        UID      => $FORM{UID},
        VALUE    => $value,
        PRIORITY => 1,
      });
      _error_show($Contacts);

      if ( !$Contacts->{errno} && $Contacts->{INSERT_ID} ) {
        # Show new value
        push @{$user_contacts_list}, {
            id       => $Contacts->{INSERT_ID},
            uid      => $FORM{UID},
            priority => 1,
            value    => $value,
            type_id  => $type_id,
          };

        # Change user_pi
        $users->pi_change({
          UID         => $FORM{UID},
          $field_name => ''
        });
        _error_show($users);

        # Update new value
        $users->{$field_name} = $value if (!$users->{errno});
        $html->message('info', "$lang{CONTACTS} Old -> New $field_name", $lang{SUCCESS});
      }

    };

    # Check for old model contacts and copy it to new
    if (!$users->{CONTACTS_NEW_APPENDED}) {
      if ( $user_pi->{EMAIL} ) {
        $first_time_migrate_contacts->(9, 'EMAIL', $_) foreach (split(',\s?', $user_pi->{EMAIL}));
      }
      # 2
      if ( $user_pi->{PHONE} ) {
        $first_time_migrate_contacts->(2, 'PHONE', $_) foreach (split(',\s?', $user_pi->{PHONE}));
      }
    }

    # Translate type names
    map {$_->{name} = $lang{$_->{name}} || $_->{name} }@{$user_contact_types};

    $user_pi->{CONTACTS} = _build_user_contacts_form( $user_contacts_list, $user_contact_types );

    # Show contacts block
    $user_pi->{SHOW_PRETTY_USER_CONTACTS} = 'block';
  }
  else {
    #Hide contacts block
    $user_pi->{SHOW_PRETTY_USER_CONTACTS} = 'none';
  }
  my @header_arr = (
      "$lang{MAIN}:#_user_main:data-toggle='tab' aria-expanded='true'",
      "$lang{ADDRESS}:#_address:data-toggle='tab'",
      "$lang{PASPORT}:#_pasport:data-toggle='tab'",
      "$lang{COMMENTS}:#_comment:data-toggle='tab'",
      "$lang{OTHER}:#__other:data-toggle='tab'",
      "$lang{CONTACTS}:#_contacts_content:data-toggle='tab'"
  );

  $user_pi->{HEADER} = $html->table_header(\@header_arr, { TABS => 1, ACTIVE => '#_user_main' });
  $user_pi->{HEADER2} = $html->table_header(\@header_arr, { TABS => 1, SHOW_ONLY => 2, ACTIVE => '#_main' });

  $user_pi->{OLD_CONTACTS_VISIBLE} = (!exists $conf{CONTACTS_NEW} || !$conf{CONTACTS_NEW});

  $html->tpl_show(templates('form_pi'), { %$attr, UID => $LIST_PARAMS{UID}, %$user_pi }, { ID => 'form_pi' });
  return 1;
}

#**********************************************************
=head2 user_form($attr) - Main user form

=cut
#**********************************************************
sub user_form {
  my ($attr) = @_;

  $index = 15 if (!$attr->{ACTION} && !$attr->{REGISTRATION});
  my $user_info = $attr->{USER_INFO};
  my $uid       = 0;

  if ($FORM{STATMENT_ACCOUNT}) {
    load_module('Docs', $html);
    docs_statement_of_account();
    exit;
  }
  elsif ($FORM{add} || $FORM{change}) {
    return form_users($attr);
  }
  elsif (!$attr->{USER_INFO}) {
    $user = Users->new($db, $admin, \%conf);

    if ($FORM{COMPANY_ID}) {
      use Customers;
      my $customers = Customers->new($db, $admin, \%conf);
      my $company = $customers->company->info($FORM{COMPANY_ID});
      $user_info->{COMPANY_ID} = $FORM{COMPANY_ID};
      $user_info->{EXDATA} =  $html->tpl_show(templates('form_row'), { ID => "",
          NAME  => $lang{COMPANY},
          VALUE => (($company->{COMPANY_ID} && $company->{COMPANY_ID} > 0) ? $html->button($company->{COMPANY_NAME}, "index=13&COMPANY_ID=$company->{COMPANY_ID}", { BUTTON => 1 }) : '') }, { OUTPUT2RETURN => 1 });
    }
    if ($admin->{GID}) {
      $user_info->{GID} = sel_groups();
    }
    else {
      $FORM{GID} = $attr->{GID};
      delete $attr->{GID};
      $user_info->{GID} = sel_groups({ SKIP_MUULTISEL => 1 });
    }

    $user_info->{EXDATA} .= $html->tpl_show(templates('form_user_exdata_add'), { %$user_info, %$attr, CREATE_BILL => ' checked' }, { OUTPUT2RETURN => 1 });
    $user_info->{EXDATA} .= $html->tpl_show(templates('form_ext_bill_add'), { CREATE_EXT_BILL => ' checked' }, { OUTPUT2RETURN => 1 }) if ($conf{EXT_BILL_ACCOUNT});

    if ($user_info->{DISABLE} && $user_info->{DISABLE} > 0) {
      $user_info->{DISABLE} = ' checked';
      if ($user_info->{DISABLE} == 5) {
        $user_info->{DISABLE_MARK} = $html->color_mark($html->b("$lang{NOT} $lang{CONFIRM}"), $_COLORS[7]);
      }
      else {
        $user_info->{DISABLE_MARK} = $html->color_mark($html->b($lang{DISABLE}), $_COLORS[6]);
        $user_info->{DISABLE_COLOR} = 'bg-warning';
      }
    }
    else {
      $user_info->{DISABLE} = "$lang{ENABLE}";
    }

    $user_info->{MONTH_NAMES} = "'". join("', '", @MONTHES) . "'";
    $user_info->{WEEKDAY_NAMES} = "'". join("', '", $WEEKDAYS[7], @WEEKDAYS[1..6]). "'";

    my $main_account = $html->tpl_show(templates('form_user'), { %$user_info, %$attr }, { OUTPUT2RETURN => 1, ID => 'form_user' });

    $user_info->{PW_CHARS}  = $conf{PASSWD_SYMBOLS} || "abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ";
    $user_info->{PW_LENGTH} = $conf{PASSWD_LENGTH}  || 6;

    $main_account .= $html->tpl_show(templates('form_password'), { %$user_info, %$attr }, { OUTPUT2RETURN => 1 });

    $main_account =~ s/<FORM.+>//ig;
    $main_account =~ s/<\/FORM>//ig;
    $main_account =~ s/<input.+type=submit.+>//ig;
    $main_account =~ s/<input.+index.+>//ig;
    $main_account =~ s/user_form/users_pi/ig;

    user_pi({ MAIN_USER_TPL => $main_account, %$attr });
  }
  else {
    $user_info = $attr->{USER_INFO};
    $FORM{UID} = $user_info->{UID} || 0;
    $uid = $user_info->{UID} || 0;

    $user_info->{COMPANY_NAME} = "$lang{NOT_EXIST} ID: $user_info->{COMPANY_ID}" if ($user_info->{COMPANY_ID} && !$user_info->{COMPANY_NAME});

    if ($permissions{0}{12}) {
      $user_info->{DEPOSIT}='--';
    }
    else {
      if ($permissions{1}) {
        $user_info->{PAYMENTS_BUTTON} = $html->button('', "index=2&UID=". $uid,
          { class => 'btn btn-sm btn-default', ICON => 'glyphicon glyphicon-plus-sign', ex_params => "data-tooltip='$lang{PAYMENTS}' data-tooltip-position='top'" });
      }

      if ($permissions{2}) {
        $user_info->{FEES_BUTTON} = $html->button('', "index=3&UID=$uid",
            { class => 'btn btn-sm btn-default', ICON => 'glyphicon glyphicon-minus-sign', ex_params => "data-tooltip='$lang{FEES}' data-tooltip-position='top'" });
      }

      if ($permissions{0}) {
        #my $as_index = get_function_index('docs_statement_of_account');
        $user_info->{PRINT_BUTTON} = $html->button('', "qindex=$index&STATMENT_ACCOUNT=$uid&UID=$uid&header=2",
            { class => 'btn btn-sm btn-default', ICON => 'glyphicon glyphicon-print', target => '_new', ex_params => "data-tooltip='$lang{STATMENT_OF_ACCOUNT}' data-tooltip-position='top'" });
      }

      if (defined($user_info->{DEPOSIT})){
        $user_info->{DEPOSIT_MARK} = ($user_info->{DEPOSIT} =~ /\d+/ && $user_info->{DEPOSIT} > 0) ? 'label-primary' : 'bg-warning';
      }
      else {
        $user_info->{DEPOSIT_MARK} = 'label-warning';
        $user_info->{DEPOSIT} = 'Not set';
      }
    }


    if (! $permissions{0}{9}) {
      $user_info->{CREDIT_READONLY}='readonly';
      $user_info->{CREDIT_DATE_READONLY}='readonly';
    }

    if (! $permissions{0}{11}) {
      $user_info->{REDUCTION_READONLY}='readonly';
      $user_info->{REDUCTION_DATE_READONLY}='readonly';
    }

    if (! $permissions{0}{18}) {
      $user_info->{EXPIRE_READONLY}='readonly';
    }

    if ($permissions{0} && $permissions{0}{15}) {
      $user_info->{BILL_CORRECTION} = $html->button('', "index=$index&UID=$uid&bill_correction=1", { ICON => 'glyphicon glyphicon-wrench' });
    }
    if ($conf{EXT_BILL_ACCOUNT} && $user_info->{EXT_BILL_ID}) {
      if (defined($user_info->{EXT_BILL_DEPOSIT})){
        $user_info->{EXT_DEPOSIT_MARK} = ($user_info->{EXT_BILL_DEPOSIT} > 0) ? 'label-primary' : 'bg-warning';
      }
      else {
        $user_info->{EXT_DEPOSIT_MARK} = 'label-warning';
        $user_info->{EXT_BILL_DEPOSIT} = 'Not set';
      }
    }
    else {
      $user_info->{EXT_DEPOSIT_MARK} = 'label-warning';
      $user_info->{EXT_BILL_DEPOSIT} = 'Not set';
    }

    if ($conf{DEPOSIT_FORMAT}) {
      $user_info->{SHOW_DEPOSIT} = sprintf("$conf{DEPOSIT_FORMAT}", $user_info->{DEPOSIT}) if ($user_info->{DEPOSIT} =~ /\d+/);
    }
    else {
      $user_info->{SHOW_DEPOSIT} = $user_info->{DEPOSIT};
    }

    $user_info->{EXDATA} = $html->tpl_show(templates('form_user_exdata'), $user_info, { OUTPUT2RETURN => 1, ID => 'form_user_exdata'  });

    $user_info->{REGISTRATION_FORM} = $html->tpl_show(templates('form_row'), { ID => '',
        NAME  => $lang{REGISTRATION},
        VALUE => $user_info->{REGISTRATION} }, { OUTPUT2RETURN => 1 });

    if ( $user_info->{DISABLE} && $user_info->{DISABLE} =~ /\d+/ ){
      if ($user_info->{DISABLE} == 1) {
        #$user_info->{DISABLE_MARK} = $html->color_mark($html->b($lang{DISABLE}), $_COLORS[6]);
        $user_info->{DISABLE_COLOR} = 'bg-danger';

        my $list = $admin->action_list(
          {
            UID       => $uid,
            TYPE      => 9,
            PAGE_ROWS => 1,
            SORT      => 1,
            DESC      => 'DESC'
          }
        );
        if ($admin->{TOTAL} > 0) {
          $list->[0][3] =~ s/^.*://g;
          $user_info->{DISABLE_COMMENTS} = $list->[0][3];
        }
      }
      elsif ($user_info->{DISABLE} == 2) {
        if (! $permissions{0}{13}) {
          $user_info->{DISABLE_MARK} = $html->button($html->color_mark($html->b("$lang{REGISTRATION} $lang{CONFIRM}"), $_COLORS[8]),
            "index=$index&DISABLE=0&UID=$uid&change=1", { BUTTON => 1 }) ;
        }
        else {
          $user_info->{DISABLE_MARK} = $html->color_mark($html->b("$lang{REGISTRATION} $lang{CONFIRM}"), $_COLORS[8]);
        }
      }

      $user_info->{DISABLE} = ' checked';
    }
    else {
      $user_info->{DISABLE} = '';
    }

    if ( $user_info->{EXPIRE} && $user_info->{EXPIRE} ne '0000-00-00' ){
      if (date_diff($user_info->{EXPIRE}, $DATE) > 1) {
        $user_info->{EXPIRE_COLOR} = 'bg-danger';
        $user_info->{EXPIRE_COMMENTS}="$lang{EXPIRE}";
      }
    }

    $user_info->{ACTION}     = 'change';
    $user_info->{LNG_ACTION} = $lang{CHANGE};

    if ($permissions{5}) {
      my $info_field_index = get_function_index('form_info_fields');
      $user_info->{ADD_INFO_FIELD} = $html->button("$lang{ADD} $lang{INFO_FIELDS}", "index=$info_field_index", { class => 'add', ex_params => ' target=_info_fields' });
    }

    if ($permissions{0}{3}) {
      $user_info->{PASSWORD} =
          ($FORM{SHOW_PASSWORD})
        ? "'$user_info->{PASSWORD}'"
        : $html->button("", "index=$index&UID=$uid&SHOW_PASSWORD=1",
              { class => 'btn btn-sm btn-default', ICON => 'fa fa-eye', ex_params => "data-tooltip='$lang{SHOW} $lang{PASSWD}' data-tooltip-position='top'"  }) . '
        ' . $html->button("", "index=" . get_function_index('form_passwd') . "&UID=$uid",
              { class => 'btn btn-sm btn-default', ICON => 'fa fa-pencil', ex_params => "data-tooltip='$lang{CHANGE} $lang{PASSWD}' data-tooltip-position='top'" });
    }

    if (in_array('Sms', \@MODULES)) {
      $user_info->{PASSWORD} .= ' ' . $html->button("", "index=$index&header=1&UID=$uid&SHOW_PASSWORD=1&SEND_SMS_PASSWORD=1", { class => 'btn btn-sm btn-default', MESSAGE => "$lang{SEND} $lang{PASSWD} SMS ?", ICON => 'fa fa-envelope', TITLE => "$lang{SEND} $lang{PASSWD} SMS" });
    }

    $user_info->{MONTH_NAMES} = "'". join("', '", @MONTHES) . "'";
    $user_info->{WEEKDAY_NAMES} = "'". join("', '", $WEEKDAYS[7], @WEEKDAYS[1..6]). "'";

    if ($attr->{REGISTRATION}) {
      my $main_account = $html->tpl_show(templates('form_user'), { %$user_info, %$attr }, { ID => 'form_user', OUTPUT2RETURN => 1 });
      $main_account =~ s/<FORM.+>//ig;
      $main_account =~ s/<\/FORM>//ig;
      $main_account =~ s/<input.+type=submit.+>//ig;
      $main_account =~ s/<input.+index.+>//ig;
      $main_account =~ s/user_form/users_pi/ig;
      user_pi({ MAIN_USER_TPL => $main_account, %$attr });
    }
    else {
      $html->tpl_show(templates('form_user'), $user_info, { ID => 'form_user' });
    }
  }

  return 1;
}
#**********************************************************
=head2 user_info_items($uid, $user_info)

=cut
#**********************************************************
sub user_info_items {
  my ($uid, $user_info) = @_;

  my @items_arr = ();


  my %userform_menus = (
    103=> $lang{SHEDULE},
    22 => $lang{LOG},
    21 => $lang{COMPANY},
    12 => $lang{GROUP},
    18 => $lang{NAS},
    19 => $lang{BILL}
  );

  $userform_menus{17} = $lang{PASSWD} if ($permissions{0}{3});

  while (my ($k, $v) = each %uf_menus) {
    $userform_menus{$k} = $v;
  }

  foreach my $k (sort { $b <=> $a } keys %userform_menus) {
    my $v   = $userform_menus{$k};
    my $url = "index=$k&UID=$uid";
    my $active = (defined($FORM{$k})) ? $html->b($v) : $v;
    my $function_name = $functions{$k};

    my $info = '';
    if ($function_name eq 'msgs_admin') {
      load_module("Msgs", $html);
      my $count=msgs_new({ ADMIN_UNREAD => $uid });
      if ($count && $count > 0) {
        $info=$html->badge($count, { TYPE => 'alert-danger' });
      }
    }
    elsif($function_name eq 'form_shedule') {
      require Shedule;
      Shedule->import();

      my $Shedule = Shedule->new($db, $admin, \%conf);

      $Shedule->list({ UID  => $uid });
      if ($Shedule->{TOTAL}) {
        $info = $html->badge($Shedule->{TOTAL}, { TYPE => 'alert-warning' });
      }
    }

    push @items_arr, "$active $info:$url";
  }

  my $full_delete = '';
  if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8} && ($user_info->{DELETED})) {
    push @items_arr, "$lang{UNDELETE}:index=15&del_user=1&UNDELETE=1&UID=$uid:MESSAGE=$lang{UNDELETE} $lang{USER}: $user_info->{LOGIN} / $uid";
    $full_delete = "&FULL_DELETE=1";
  }

  push @items_arr, "$lang{DEL}:index=15&del_user=1&UID=$uid$full_delete:MESSAGE=$lang{USER}: $user_info->{LOGIN} / $uid" if (defined($permissions{0}{5}));

  return @items_arr;
}
#**********************************************************
=head2 user_services($attr)

  Arguments:
    USER_INFO

  Return:

=cut
#**********************************************************
sub user_services {
  my ($attr) = @_;

  my $user_info = $attr->{USER_INFO};
  #Service tabs
  #my @header_arr = ();
#  foreach my $key (sort keys %menu_items) {
#    if (defined($menu_items{$key}{20})) {
#      if (in_array($module{$key}, \@MODULES)) {
##        if (defined($module{$key})) {
##          load_module($module{$key}, $html);
##        }
##        my $info = '';
#        #Get quick info
#        #if (lc($module{$key}.'_quick_info')) {
#        #  $info = $html->badge( _function( 0, { IF_EXIST => 1, FN_NAME => lc( $module{$key} ).'_quick_info' } ),
#        #      { TYPE => 'alert-info' } );
#        #}
#        #push @header_arr, "$menu_items{$key}{20} ".($info || '').":#$module{$key}:role='tab' data-toggle='tab'";
#      }
#    }
#  }
  #print $html->table_header(\@header_arr, { TABS => 1 });

  my $active = ' active';
  delete ($FORM{search_form});

  if ($FORM{json}) {
    foreach my $module (@MODULES) {
      $FORM{MODULE} = $module;
      my $service_func_index = 0;
      foreach my $key (sort keys %menu_items) {
        if (defined($menu_items{$key}{20})) {
          $service_func_index = $key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || !$FORM{MODULE}) && $service_func_index == 0);
        }
      }

      if ($service_func_index) {
        $index = $service_func_index;
        _function($service_func_index, { USER_INFO => $user_info });
      }
    }

    return 1;
  }

  my $uid = $user_info->{UID} || 0;

  my $service_start = 0;
  if ($FORM{DEBUG} && $FORM{DEBUG} > 4) {
    $service_start = check_time();
  }

  my $service_func_index = 0;
  my $service_func_menu = "<div class='form-group'>";

  foreach my $key (sort keys %menu_items) {
    if (defined($menu_items{$key}{20})) {
      $service_func_index = $key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || !$FORM{MODULE}) && $service_func_index == 0);
    }

    if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
      $service_func_menu .= $html->button( "$menu_items{$key}{$service_func_index}", "UID=$uid&index=$key",
        { class => 'btn btn-primary btn-xs', ex_params => 'style="margin: 0 0 3px 3px;"' } );
    }
  }

  $service_func_menu .= "</div>";
  my $module = $FORM{MODULE} || $MODULES[0];
  load_module($module, $html);

  if ($service_func_index) {
    $active = '';
    $index = $service_func_index;
    _function($service_func_index, { USER_INFO => $user_info, MENU => $service_func_menu });
    if ($FORM{DEBUG} && $FORM{DEBUG} > 4) {
      print gen_time($service_start);
    }
  }

  return 1;
}


#**********************************************************
=head2 user_right_menu($uid, $LOGIN, $attr) - User extra menu

=cut
#**********************************************************
sub user_right_menu {
  my ($uid, $user_info, $attr) = @_;

  if (!$uid) {
    return '[unknown user]'
  }

  if ($FORM{xml} || $FORM{csv} || $FORM{json} || $FORM{EXPORT_CONTENT}) {
    return $user_info->{LOGIN};
  }

  my @user_info_arr = user_info_items($uid, $user_info);
  my @items_arr = ();
#  shift(@user_info_arr);
#  shift(@user_info_arr);
#  if ($permissions{1}) {
#    shift(@user_info_arr);
#  }
#  if ($permissions{2}) {
#    shift(@user_info_arr);
#  }

  my $html_content = "<ul class='control-sidebar-menu'>";
  my $qs = $ENV{QUERY_STRING};
  $qs =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
  my $section_title = '';
  my $i=0;

  label:
  $html_content .= "<h4 class='section_title'>$section_title</h4>" if ($section_title);
  foreach my $element ( @items_arr ) {
    my ($name, $url, $extra) = split(/:/, $element, 3);
    my $active = '';
    if (!$url) {
      $active = 'active';
    }
    elsif ($url eq $qs) {
      $active = 'active';
    }
    else {
      my @url_argv = split(/&/, $url);
      my %params_hash = ();
      foreach my $line (@url_argv) {
        my ($k, $v) = split(/=/, $line);
        $params_hash{($k || '')} = $v;
      }

      if ($params_hash{index} && $FORM{index} && $params_hash{index} eq $FORM{index} && $attr->{USE_INDEX}) {
        $active = 'active';
      }
    }

    my %url_params = ();

    if ($extra) {
      if ($extra =~ /MESSAGE=(.+)/) {
        $url_params{MESSAGE} = $1;
      }

      if ($extra =~ /class=(.+)/) {
        $url_params{class} = $1;
      }
    }
    $html_content .= $html->li( $html->button( "<i class='fa fa-circle-o'></i>$name", $url, \%url_params ), { class => "$active user-menu" } );
  }

  if ($i <= 1) {
    if ($i eq 0) {
      @items_arr =();
      foreach my $key (sort keys %menu_items) {
        if (defined($menu_items{$key}{20})) {
          if (in_array($module{$key}, \@MODULES)) {

            if (defined($module{$key})) {
              load_module($module{$key}, $html);
            }
            #Get quick info
            my $info = '';
            if (lc($module{$key}.'_quick_info')) {
              $info = $html->badge( _function( 0, { IF_EXIST => 1, FN_NAME => lc( $module{$key} ).'_quick_info' } ),
                    { TYPE => 'alert-info' } );
            }

            push @items_arr, "$menu_items{$key}{20} $info:UID=$uid&index=$key";
          }
        }
      }
      $section_title = $lang{SERVICES};
    }
    elsif ($i eq 1) {
      @items_arr = @user_info_arr;
      $section_title = $lang{OTHER};
    }

    $i++;
    goto label;
  }

  $html_content .= "</ul>";

  $admin->{USER_MENU} = $html_content;

  return 1;
}


#**********************************************************
=head2 user_ext_menu($uid, $LOGIN, $attr) - User extra menu

=cut
#**********************************************************
sub user_ext_menu {
  my ($uid, $LOGIN, $attr) = @_;

  if (! $uid){
    return '[unknown user]'
  }

  if ($FORM{xml} || $FORM{csv} || $FORM{json} || $FORM{EXPORT_CONTENT}) {
    return $LOGIN;
  }

  my $ex_params = ($attr->{dv_status_color}) ? "style='color:#$attr->{dv_status_color}'" : '';
  my $icon_class = (defined($attr->{login_status})) ? $state_icon_colors[ $attr->{login_status} ] : '' ;
  my $ext_menu = $html->button("", "index=15&UID=$uid", {class => "btn btn-user btn-default $icon_class", ICON => 'fa fa-user', ex_params => $ex_params });

  my $return = $ext_menu;

  if ($attr->{SHOW_UID}) {
    $return .= $html->button($html->b(" $LOGIN"), "index=15&UID=$uid") . " (UID: $uid) ";
  }
  else {
    $return .= $html->button(($LOGIN ? "$LOGIN" : q{}), "index=15&UID=$uid" . (($attr->{EXT_PARAMS}) ? "&$attr->{EXT_PARAMS}" : ''), { TITLE => $attr->{TITLE} });
  }

  return $return;
}

#**********************************************************
=head2 user_info($uid, $attr) - User info panel

=cut
#**********************************************************
sub user_info {
  my ($uid, $attr) = @_;

  my $user_info = $users->info($uid, \%FORM);
  my @admin_groups = split(/,s?/, $admin->{GID});

  if($uid && $users->{errno}) {
    if (! $attr || ! $attr->{QUITE}) {
      _error_show($users, { MESSAGE => "$lang{USER} '$uid' "  });
    }
    return $users;
  }
  elsif (! $users->{TOTAL} && !$FORM{UID}) {
    return 0;
  }
  elsif( $#admin_groups > -1 && $admin_groups[0] && ! in_array($users->{GID}, \@admin_groups)) {
    $html->message('err', $lang{ERROR}, "Access deny GID: $users->{GID} not allow");
    return 0;
  }
  else {
    if($users->{errno}) {
      if (!$attr || !$attr->{QUITE}) {
        _error_show( $users, { MESSAGE => "$lang{USER} '". ($uid || q{}) ."' " } );
      }
      return $users;
    }
    $uid = $user_info->{UID};
  }

  if ($LIST_PARAMS{FIO} && $LIST_PARAMS{FIO} ne '_SHOW') {
    $LIST_PARAMS{FIO}='_SHOW';
  }

  my $del_class = '';
  my $deleted   = '';
  my $domain_id = '';

  if ($user_info->{DELETED}) {
    $deleted   = $html->b($lang{DELETED});
    $del_class = ' alert-danger';
  }

  my $ext_menu  = user_ext_menu($uid, $user_info->{LOGIN}, { SHOW_UID => 1, login_status => $user_info->{DISABLE} });

  if (! $admin->{DOMAIN_ID} && $user_info->{DOMAIN_ID}) {
    $domain_id = " DOMAIN: $user_info->{DOMAIN_ID}";
  }

  my $pre_button  = $html->button(" ", "index=$index&UID=$uid&PRE=$uid",
    { class=> 'pull-left btn btn-sm btn-default', ICON => 'glyphicon glyphicon-arrow-left', TITLE => $lang{BACK} } );
  my $next_button = $html->button(" ", "index=$index&UID=$uid&NEXT=$uid",
    { class=> 'pull-right btn btn-sm btn-default', ICON => 'glyphicon glyphicon-arrow-right', TITLE => $lang{NEXT} } );

  #show tags
  my $user_tags   = '';
  if (in_array('Tags', \@MODULES)) {
    require Tags;
    Tags->import();
    my $Tags = Tags->new($db, $admin, \%conf);

    my $list  = $Tags->tags_user({
      NAME      => '_SHOW',
      PRIORITY  => '_SHOW',
      DATE      => '_SHOW',
      UID       => $uid,
      COLS_NAME => 1
    });

    my @tags_arr = ();

    foreach my $line (@$list) {
      if ($line->{date}) {
        push @tags_arr, $html->element('span', $line->{name}, { class => "btn btn-xs $priority_colors[$line->{priority}]" });
      }
    }

    $user_tags = ((@tags_arr) ? join(" ", @tags_arr) : '')
        . $html->element('span', '', { class => "btn btn-default btn-xs glyphicon glyphicon-tags",
        title   => "$lang{ADD} Tag",
        onclick => "loadToModal('$SELF_URL?qindex=".get_function_index('tags_user')."&UID=$uid&header=2&FORM_NAME=USERS_TAG')"
    });
  }

  my $full_info = '';
  $full_info .= ($permissions{1}) ? $html->button('', "index=2&UID=$uid",
      { TITLE => $lang{PAYMENTS}, class => 'btn btn-success btn-xs', ICON => 'glyphicon glyphicon-plus-sign' }) : '';
  $full_info .= ' '.(($permissions{2}) ? $html->button('', "index=3&UID=$uid",
      { TITLE => $lang{FEES}, class => 'btn btn-default btn-xs', ICON => 'glyphicon glyphicon-minus-sign' }) : '');
  $full_info .= ' '.$html->button('', "index=$index&UID=$uid&SUMMARY_SHOW=1",
    { TITLE => $lang{INFO}, class => 'btn btn-default btn-xs', ICON => 'glyphicon glyphicon-th-large' });

  $user_info->{TABLE_SHOW} = $html->element('div', "$pre_button $ext_menu $full_info $domain_id $deleted $user_tags  $next_button",
    { class => "well well-sm$del_class", align => "center" });

  #main function button
  if (! $FORM{step} ) {
    #my @header_arr = user_info_items($uid, $user_info);
    #$user_info->{TABLE_SHOW} .= $html->table_header(\@header_arr, { TABS => 1, SHOW_ONLY => 7, USE_INDEX => 1 });
    # End main function
  }

  user_right_menu($uid, $user_info);

  $LIST_PARAMS{UID} = $uid;
  $FORM{UID}        = $uid;
  $pages_qs         = "&UID=$uid";
  $pages_qs        .= "&subf=$FORM{subf}" if ($FORM{subf});

  return $user_info;
}


#**********************************************************
=head2 form_users_list($attr)

=cut
#**********************************************************
sub form_users_list {
  #my ($attr) = @_;

  if (!$permissions{0}{2}) {
    return 0;
  }

  if( $FORM{MULTIUSER} ) {
    form_users();
  }

  my %col_hidden = ();
  if ($FORM{COMPANY_ID} && !$FORM{change}) {
    print $html->br($html->b("$lang{COMPANY}:") . $FORM{COMPANY_ID});
    $pages_qs .= "&COMPANY_ID=$FORM{COMPANY_ID}";
    $LIST_PARAMS{COMPANY_ID} = $FORM{COMPANY_ID};
    $col_hidden{COMPANY_ID} = $FORM{COMPANY_ID};
  }

  if ($FORM{letter}) {
    $LIST_PARAMS{LOGIN} = "$FORM{letter}*";
    $pages_qs .= "&letter=$FORM{letter}";
  }

  my @statuses = ($lang{ALL},
    $lang{ACTIV},
    $lang{DEBETORS},
    $lang{DISABLE},
    $lang{EXPIRE},
    $lang{CREDIT},
    $lang{NOT_ACTIVE},
    $lang{PAID},
    $lang{UNPAID});

  if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) {
    push @statuses, $lang{DELETED},;
  }

  my $i            = 0;
  my $users_status = 0;
  my @status_bar_arr = ();

  $FORM{USERS_STATUS}=0 if (! defined($FORM{USERS_STATUS}));
  my $qs = '';
  foreach my $name (@statuses) {
    my $active = '';
    if (defined($FORM{USERS_STATUS}) && $FORM{USERS_STATUS} =~ /^\d+$/ && $FORM{USERS_STATUS} == $i) {
      $LIST_PARAMS{USER_STATUS} = 1;
      if ($i == 1) {
        $LIST_PARAMS{ACTIVE} = 1;
      }
      elsif ($i == 2) {
        $LIST_PARAMS{DEPOSIT} = '<0';
      }
      elsif ($i == 3) {
        $LIST_PARAMS{DISABLE} = 1;
      }
      elsif ($i == 4) {
        $LIST_PARAMS{EXPIRE} = "<=$DATE;>0000-00-00";
      }
      elsif ($i == 5) {
        $LIST_PARAMS{CREDIT} = ">0";
      }
      elsif ($i == 6) {
        $LIST_PARAMS{DISABLE} = 2;
      }
      elsif ($i == 7) {
        $LIST_PARAMS{PAID} = 1;
      }
      elsif ($i == 8) {
        $LIST_PARAMS{UNPAID} = 1;
      }
      elsif ($i == 9) {
        $LIST_PARAMS{DELETED} = 1;
      }

      $pages_qs   .= "&USERS_STATUS=$i";
      $users_status = $i;
      $active      = 'active';
    }
    else {
      $qs = $pages_qs;
      $qs =~ s/\&USERS_STATUS=\d//;
    }

    push @status_bar_arr, "$name:index=$index&USERS_STATUS=$i$qs";
    $i++;
  }
  my Abills::HTML $table;
  my $list;
  ($table, $list) = result_former({
    INPUT_DATA      => $users,
    FUNCTION        => 'list',
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'LOGIN,FIO,DEPOSIT,CREDIT,LOGIN_STATUS',
    FUNCTION_FIELDS => 'form_payments, form_fees',
    TABLE => {
      width      => '100%',
      FIELDS_IDS => $users->{COL_NAMES_ARR},
      caption    => "$lang{USERS} - " . $statuses[$users_status],
      cols_align => [ 'left', 'left', 'right', 'right', 'center', 'right', 'center:noprint', 'center:noprint' ],
      qs         => $pages_qs,
      ID         => 'USERS_LIST',
      SELECT_ALL => ($permissions{0}{7}) ? "users_list:IDS:$lang{SELECT_ALL}" : undef,
      SHOW_COLS_HIDDEN => \%col_hidden,
      header     => \@status_bar_arr,
      EXPORT     => ($permissions{0}{17}) ? 1 : 0,
      IMPORT     => "$SELF_URL?get_index=form_users&import=1&header=2",
      MENU       => "$lang{ADD}:index=" . get_function_index('form_wizard') . ':add' . ";$lang{SEARCH}:index=" . get_function_index('form_search') . ":search",
    }
    });

  if (_error_show($users)) {
    return 0;
  }
  elsif ($users->{TOTAL} && $users->{TOTAL} == 1 && ! $FORM{SKIP_FULL_INFO}) {
    $FORM{index} = 15;

    if (!$FORM{UID}) {
      $FORM{UID} = $list->[0]->{uid};
      if (! $FORM{LOGIN} || $FORM{LOGIN} =~ /\*/) {
        delete $FORM{LOGIN};
        $ui = user_info($FORM{UID});
        print $ui->{TABLE_SHOW} if ($ui->{TABLE_SHOW});
      }
    }

    form_users({ USER_INFO => $ui });

    return 1;
  }
  elsif (! $users->{TOTAL}) {
    $html->message('err', $lang{ERROR}, "$lang{USER} $lang{NOT_EXIST}");
    return 0;
  }

  print $html->letters_list({ pages_qs => $pages_qs }) if($conf{USER_LIST_LETTERS});

  my $search_color_mark;
  if ($FORM{UNIVERSAL_SEARCH}) {
    $search_color_mark=$html->color_mark($FORM{UNIVERSAL_SEARCH}, $_COLORS[6]);
  }

  my $countries_hash;

  if ( ! $conf{ADDRESS_REGISTER} ) {
    ($countries_hash, undef) = sel_countries();
  }

  my $base_fields = 1;
  foreach my $line (@$list) {
    my $uid      = $line->{uid};
    my $payments = ($permissions{1}) ? $html->button($lang{PAYMENTS}, "index=2&UID=$uid", { class => 'payments' }) : '';
    my $fees     = ($permissions{2}) ? $html->button($lang{FEES}, "index=3&UID=$uid", { class => 'fees' }) : '';

    if ($FORM{UNIVERSAL_SEARCH}) {
      $line->{fio} =~ s/(.*)$FORM{UNIVERSAL_SEARCH}(.*)/$1$search_color_mark$2/ if ($line->{fio});
      $line->{login}  =~ s/(.*)$FORM{UNIVERSAL_SEARCH}(.*)/$1$search_color_mark$2/ if ($line->{login});
      $line->{comments}  =~ s/(.*)$FORM{UNIVERSAL_SEARCH}(.*)/$1$search_color_mark$2/ if ($line->{comments});
    }

    my @fields_array = ();
    for ($i = $base_fields; $i < $base_fields+$users->{SEARCH_FIELDS_COUNT}; $i++) {
      my $col_name = $users->{COL_NAMES_ARR}->[$i];
      if ($conf{EXT_BILL_ACCOUNT} && $col_name eq 'ext_bill_deposit') {
        $line->{ext_bill_deposit} = ($line->{ext_bill_deposit} < 0) ? $html->color_mark($line->{ext_bill_deposit}, 'text-danger') : $line->{ext_bill_deposit};
      }
      elsif ($col_name eq 'deleted') {
        $table->{rowcolor} = ($line->{deleted} == 1) ? 'danger' : '';
        $line->{deleted} = $html->color_mark($bool_vals[ $line->{deleted} ], ($line->{deleted} == 1) ? $state_colors[ $line->{deleted} ] : '');
      }
      elsif($col_name =~ /deposit/) {
        if ($permissions{0}{12}) {
          $line->{$col_name} = '--';
        }
        else {
          my $deposit = $line->{deposit} || 0;
          if ($conf{DEPOSIT_FORMAT}) {
            $deposit = sprintf("$conf{DEPOSIT_FORMAT}", $deposit);
          }
          $line->{$col_name} =  ($deposit + ($line->{credit} || 0) < 0) ? $html->color_mark( $deposit, $_COLORS[6] ) : $deposit,
        }
      }
      elsif($col_name eq 'deposit') {
        $line->{$col_name} =  ($permissions{0}{12}) ? '--' : (($line->{deposit} ? $line->{deposit} : 0) + ($line->{credit} || 0) < 0) ? $html->color_mark($line->{deposit}, 'text-danger') : $line->{deposit},
      }
      elsif($col_name eq 'tags') {
        $line->{$col_name} =  ' '. $html->element('span', $line->{tags}, { class => "btn btn-xs $priority_colors[$line->{priority}]" });
      }
      elsif($col_name eq 'last_payment' && $line->{last_payment}) {
        my($date, undef) = split(/ /, $line->{last_payment});

        if($date && $DATE eq $date) {
          $line->{last_payment}=$html->color_mark($line->{last_payment}, 'text-danger');
        }
      }
      elsif($col_name eq 'country_id') {
        $line->{$col_name} = $countries_hash->{$line->{$users->{COL_NAMES_ARR}->[$i]}};
      }
      elsif ($FORM{UNIVERSAL_SEARCH}) {
        if ($FORM{UNIVERSAL_SEARCH} && $line->{$col_name}){
          $line->{$col_name} =~ s/(.{0,100})$FORM{UNIVERSAL_SEARCH}(.{0,100})/$1$search_color_mark$2/;
        }
      }

      if ($col_name eq 'login_status') {
        push @fields_array, $table->td($status[ $line->{login_status} ], { class => $state_colors[ $line->{login_status} ], align => 'center' });
      }
      else {
        push @fields_array, $table->td($line->{$col_name});
      }
    }

    @fields_array = ($table->td(user_ext_menu($uid, $line->{login},{login_status => $line->{login_status}})), @fields_array);

    if ($permissions{0}{7}) {
      @fields_array = ($table->td($html->form_input('IDS', "$uid", { TYPE => 'checkbox', FORM_ID => 'users_list' })), @fields_array);
    }

    $table->addtd(
      @fields_array,
      $table->td($payments .' '.$fees )
      #$table->td($fees),
    );
  }

  my @totals_rows = (
    [ $html->button("$lang{TOTAL}:", "index=$index&USERS_STATUS=0"), $html->b($users->{TOTAL}) ],
    [ $html->button("$lang{EXPIRE}:", "index=$index&USERS_STATUS=4"), $html->b($users->{TOTAL_EXPIRED}) ],
    [ $html->button("$lang{DISABLE}:", "index=$index&USERS_STATUS=3"), $html->b($users->{TOTAL_DISABLED}) ]
  );

  if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) {
    $users->{TOTAL} -= $users->{TOTAL_DELETED} || 0;
    $totals_rows[0]  = [ $html->button("$lang{TOTAL}:", "index=$index&USERS_STATUS=0"), $html->b($users->{TOTAL}) ];
    push @totals_rows, [ $html->button("$lang{DELETED}:", "index=$index&USERS_STATUS=9"), $html->b($users->{TOTAL_DELETED}) ],;
  }

  my $table2 = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right' ],
      rows       => \@totals_rows
    }
  );

  if ($permissions{0}{7} && ! $FORM{EXPORT_CONTENT}) {
    $html->{FORM_ID}='users_list';

    my @multi_operation = (
      [ $html->form_input('MU_GID',         1, { TYPE => 'checkbox', }) . $lang{GROUP},     sel_groups({ SKIP_MUULTISEL => 1 }) ],
      [ $html->form_input('MU_DISABLE',     1, { TYPE => 'checkbox', }) . $lang{DISABLE},   $html->form_input('DISABLE',     "1", { TYPE => 'checkbox', }) . $lang{CONFIRM} ],
      [ $html->form_input('MU_DEL',         1, { TYPE => 'checkbox', }) . $lang{DEL},       $html->form_input('DEL',         "1", { TYPE => 'checkbox', }) . $lang{CONFIRM} ],
      [ $html->form_input('MU_ACTIVATE',    1, { TYPE => 'checkbox', }) . $lang{ACTIVATE},  $html->date_fld2('ACTIVATE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1 }) ],
      [ $html->form_input('MU_EXPIRE',      1, { TYPE => 'checkbox', }) . $lang{EXPIRE},    $html->date_fld2('EXPIRE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1 }) ],
      [ $html->form_input('MU_CREDIT',      1, { TYPE => 'checkbox', }) . $lang{CREDIT},    $html->form_input('CREDIT',      $FORM{CREDIT}) ],
      [ $html->form_input('MU_CREDIT_DATE', 1, { TYPE => 'checkbox', }) . "$lang{CREDIT} $lang{DATE}", $html->date_fld2('CREDIT_DATE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1, DATE => $FORM{CREDIT_DATE} }) ],
      [ '', $html->form_input('MULTIUSER', $lang{APPLY}, { TYPE => 'submit' }) ],
    );


    if(in_array('Msgs', \@MODULES)){
      load_module('Msgs', $html);
      my %info = ();
      my @priority = ($lang{VERY_LOW}, $lang{LOW}, $lang{NORMAL}, $lang{HIGH}, $lang{VERY_HIGH});
      $_COLORS[6] //= 'red';
      $_COLORS[8] //= '#FFFFFF';
      $_COLORS[9] //= '#FFFFFF';
      #my @priority_colors    = ('#8A8A8A', $_COLORS[8], $_COLORS[9], '#E06161', $_COLORS[6]);
      my @send_methods = ($lang{MESSAGE},'E-MAIL');

      if(in_array('Sms', \@MODULES)) {
        $send_methods[2]      = "$lang{SEND} SMS";
      }
      if($conf{MSGS_REDIRECT_FILTER_ADD}) {
        $send_methods[3]      = 'Web  redirect';
      }
      $info{DELIVERY_SPAN_ADDON_URL} = $SELF_URL . "?index=" . get_function_index('msgs_delivery_main');
      $info{DELIVERY_SELECT_FORM} = sel_deliverys({ SKIP_MUULTISEL => 1 });
      $info{DATE_PIKER}      = $html->form_datepicker('DELIVERY_SEND_DATE');
      $info{TIME_PIKER}      = $html->form_timepicker('DELIVERY_SEND_TIME');
      $info{STATUS_SELECT}   = msgs_sel_status({ NAME => 'STATUS' });
      $info{PRIORITY_SELECT} = $html->form_select(
        'PRIORITY',
        {
          SELECTED     => 2,
          SEL_ARRAY    => \@priority,
          STYLE        => \@priority_colors,
          ARRAY_NUM_ID => 1
        }
      );
      $info{SEND_METHOD_SELECT} = $html->form_select(
        'SEND_METHOD',
        {
          SELECTED     => 2,
          SEL_ARRAY    => \@send_methods,
          ARRAY_NUM_ID => 1
        }
      );
      my $delivery_tpl = $html->tpl_show(templates('form_user_delivery_add'), \%info,{ OUTPUT2RETURN => 1 });

      @multi_operation = ([ $html->form_input('MU_DELIVERY',    1, { TYPE => 'checkbox', }) . $lang{DELIVERY}, $delivery_tpl],
        @multi_operation);
    }

    my $table3 = $html->table(
      {
        width      => '100%',
        caption    => $lang{MULTIUSER_OP},
        HIDE_TABLE => 1,
        cols_align => [ 'left', 'left' ],
        rows       => \@multi_operation,
        ID         => 'USER_MANAGMENT'
      }
    );

    print $html->form_main(
        {
          CONTENT => $table->show({ OUTPUT2RETURN => 1 })
            . ((!$admin->{MAX_ROWS}) ? $table2->show({ OUTPUT2RETURN => 1 }) : '')
            . $table3->show({ OUTPUT2RETURN => 1 })
          ,
          HIDDEN  => {
            index       => 11,
            #FULL_DELETE => ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) ? 1 : undef,
          },
          NAME    => 'users_list',
          class   => 'hidden-print',
          ID      => 'users_list',
        }
      );
  }
  else {
    print $table->show();
    print $table2->show() if (!$admin->{MAX_ROWS});
  }

  return 1;
}

#**********************************************************
=head2 user_del($attr)

=cut
#**********************************************************
sub user_del {
  my ($attr) = @_;

  my Users $user_info = $attr->{USER_INFO};

  if ($FORM{UNDELETE}) {
    $user_info->change($user_info->{UID}, { UID => $user_info->{UID}, DELETED => 0 });
    $html->message('info', $lang{UNDELETE}, "UID: [$user_info->{UID}] $lang{UNDELETE} $user_info->{LOGIN}");
    return 0;
  }

  $user_info->del({%FORM});
  $conf{DELETE_USER} = $user_info->{UID};

  if (! _error_show($user_info)) {
    if ($conf{external_userdel}) {
      if (!_external($conf{external_userdel}, { %FORM, %$user_info })) {
        $html->message('err', $lang{DELETED}, "External cmd: $conf{external_userdel}");
      }
    }
    $html->message('info', $lang{DELETED}, "UID: $user_info->{UID}\n $lang{DELETED} $user_info->{LOGIN}");
  }

  if ($FORM{FULL_DELETE}) {
    my $mods = '';
    foreach my $mod (@MODULES) {
      $mods .= "$mod,";
      load_module($mod, $html);

      my $function = lc($mod) . '_user_del';
      if (defined(&$function)) {
        &{ \&$function }($user_info->{UID}, $user_info);
      }
    }

    if (! _error_show($user_info)) {
      if ($conf{external_userdel}) {
        if (!_external($conf{external_userdel}, { %FORM, %$user_info })) {
          $html->message('err', $lang{DELETED}, "External cmd: $conf{external_userdel}");
        }
      }

      $html->message('info', $lang{DELETED}, "UID: $user_info->{UID}\n $lang{MODULES}: $mods");
    }
  }

  return 1;
}

#**********************************************************
=head2 user_group($attr)

=cut
#**********************************************************
sub user_group {
  my ($attr) = @_;
  my $user = $attr->{USER_INFO};

  if ( ! $user ) {
    $html->message('err', $lang{ERROR}, 'No user information');
    return 1;
  }

  $user->{SEL_GROUPS} = sel_groups({
    GID            => ($user && $user->{GID}) ? $user->{GID} : undef,
    SKIP_MUULTISEL => 1
  });

  $html->tpl_show(templates('form_chg_group'), $user);

  return 1;
}

#**********************************************************
=head2 user_company($attr)

=cut
#**********************************************************
sub user_company {
  my ($attr) = @_;

  my $user_info = $attr->{USER_INFO};
  require Customers;
  Customers->import();
  my $customer = Customers->new($db, $admin, \%conf);
  my $company  = $customer->company();

  form_search(
    {
      SIMPLE        => { $lang{COMPANY} => 'COMPANY_NAME' },
        HIDDEN_FIELDS => { UID       => $FORM{UID} }
    }
  );

  my $list  = $company->list({%LIST_PARAMS, COLS_NAME => 1 });
  my $table = $html->table(
    {
      width      => '100%',
      title      => [ "$lang{NAME}", "$lang{DEPOSIT}", '-' ],
      cols_align => [ 'right', 'left', 'center:noprint' ],
      qs         => $pages_qs,
      pages      => $company->{TOTAL},
      ID         => 'COMPANY_LIST'
    }
  );

  $FORM{UID} = 0 if (!$FORM{UID});
  my $user_index = get_function_index( 'form_users' );
  $table->addrow($lang{DEFAULT}, '', $html->button("$lang{DEL}", "index=" . get_function_index('form_users') . "&change=1&UID=$FORM{UID}&COMPANY_ID=0", { class => 'del' }),);

  foreach my $line (@$list) {
    $table->{rowcolor} = ($user_info->{COMPANY_ID} && $user_info->{COMPANY_ID} == $line->{id}) ? 'active' : undef;
    $table->addrow(
        ($user_info->{COMPANY_ID} && $user_info->{COMPANY_ID} == $line->{id}) ? $html->b( $line->{name} ) : $line->{name}
      ,
      $line->{deposit},
        ($user_info->{COMPANY_ID} && $user_info->{COMPANY_ID} == $line->{id}) ? '' : $html->button( "$lang{CHANGE}",
          "index=" . $user_index . "&change=1&UID=$FORM{UID}&COMPANY_ID=$line->{id}",
          { class => 'add' } ),
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_wizard($attr) - User registration wizards

  Arguments:
    $attr

  Result:
    TRUE or FALSE


=cut
#**********************************************************
sub form_wizard {
#  my ($attr) = @_;

  # Function name:module:describe
  my %steps = ();

  $index = get_function_index('form_wizard');
  my DBI $db_ = $db->{db};

  if ($conf{REG_WIZARD}) {
    $conf{REG_WIZARD} =~ s/[\r\n]+//g;
  }
  else {
    $conf{REG_WIZARD} = "user_form::$lang{ADD} $lang{USER}"
      .  ";form_payments::$lang{PAYMENTS}";

    $conf{REG_WIZARD} .= ';dv_user:Dv:Internet'                 if (in_array('Dv',   \@MODULES));
    $conf{REG_WIZARD} .= ";dhcphosts_user:Dhcphosts:IPoE/DHCP"  if (in_array('Dhcphosts', \@MODULES));
    $conf{REG_WIZARD} .= ";abon_user:Abon:$lang{ABON}"          if (in_array('Abon', \@MODULES));
    $conf{REG_WIZARD} .= ";form_fees_wizard::$lang{FEES}";
    $conf{REG_WIZARD} .= ";iptv_user:Iptv:$lang{TV}"            if (in_array('Iptv', \@MODULES));
    $conf{REG_WIZARD} .= ";msgs_admin_add:Msgs:$lang{MESSAGES}" if (in_array('Msgs', \@MODULES));
  }

  my @arr = split(/;\s?/, ';' . $conf{REG_WIZARD});
  for (my $i = 1 ; $i <= $#arr ; $i++) {
    $steps{$i} = $arr[$i];
  }

  my $return     = 0;
  my $reg_output = '';
  START:
  delete $FORM{OP_SID};
  if (!$FORM{step}) {
    $FORM{step} = 1;
  }
  elsif ($FORM{back}) {
    $FORM{step} = $FORM{step} - 2;
  }
  elsif ($FORM{update}) {
    $FORM{step}--;
    $FORM{back} = 1;
  }

  if ($FORM{UID}) {
    $LIST_PARAMS{UID} = $FORM{UID};
    $users->info($FORM{UID});
    $users->pi({ UID => $FORM{UID} });
  }

  #Make functions
  if ($FORM{step} > 1 && !$FORM{back}) {
    $html->{NO_PRINT} = 1;
    #REG:

    $db->{TRANSACTION}=1;
    $db_->{AutoCommit} = 0;

    my $step = $FORM{step} - 1;
    # $fn, $module, $describe
    my ($fn, $module, undef) = split(/:/, $steps{$step}, 3);

    if ($module) {
      if (in_array($module, \@MODULES)) {
        load_module($module, $html);
      }
      else {
        next;
      }
    }

    if (! $FORM{change}) {
      $FORM{add} = 1;
    }
    else {
      $FORM{next} = 1;
    }

    $FORM{UID} = $LIST_PARAMS{UID} if (!$FORM{UID} && $LIST_PARAMS{UID});

    if ($FORM{DEBUG}) {
      print $html->br() . "Function: $fn ". $html->br();
      while(my($k, $v)=each %FORM) {
        print "$k, $v". $html->br();
      }
    }

    $return = &{ \&$fn }({ REGISTRATION => 1, USER_INFO => ($FORM{UID}) ? $users : undef });

    $LIST_PARAMS{UID} = $FORM{UID};
    print $return. $html->br() if ($FORM{DEBUG});

    # Error
    if (! $return) {
      $db_->rollback();
      $FORM{step}      += 1;
      $FORM{back}       = 1;
      $html->{NO_PRINT} = undef;
      $FORM{add}        = undef;
      $FORM{change}     = undef;
      $reg_output       = $html->{OUTPUT};
      goto START;
    }
    else {
      $db_->commit();
    }

    $FORM{add}        = undef;
    $FORM{change}     = undef;
    $html->{NO_PRINT} = undef;

    $reg_output = $html->{OUTPUT};
  }

  my ($fn, $module);
  if($FORM{step}) {
    ($fn, $module) = split(/:/, $steps{ $FORM{step} }, 3);
  }
  my @rows = ();

  foreach my $i (sort keys %steps) {
    my $describe = (split(/:/, $steps{$i}, 3))[2] || q{};
    my $active = '';
    if ($i < $FORM{step}) {
      $active = 'btn-success';
    }
    elsif ($i == $FORM{step}) {
      $active = 'btn-primary';
    }
    else {
      $active = 'disabled';
    }

    push @rows, $html->button("$lang{STEP}: $i<br/>". ($describe || ''), "index=$index&back=1". (($FORM{UID}) ? "&UID=$FORM{UID}" : '' ). "&step=" . ($i + 2), { class => 'btn btn-default '. $active, ex_params => 'style="overflow: hidden;"' });
  }

  if ($FORM{finish}) {
    $reg_output = '';
  }

  print $html->element('div', join('', @rows), { class => "btn-group btn-group-justified sticky" });
  print $reg_output;

  if (!$steps{ $FORM{step} } || $FORM{finish} || (!$FORM{next} && $FORM{step} == 2 && !$FORM{back})) {
    $html->message('info', $lang{INFO}, "$lang{REGISTRATION_COMPLETE}");
    undef $FORM{UID};
    undef $FORM{LOGIN};
    form_users({ USER_INFO => $users });
    return 0;
  }

  if ($module) {
    if (in_array($module, \@MODULES)) {
      load_module($module, $html);
    }
    else {
      $FORM{step}++;
      goto START;
    }
  }

  $FORM{step}++;

  if($fn eq 'form_payments' && ! $FORM{SUM}) {
    $FORM{SUM}=0;
  }

  &{ \&$fn }(
    {
      %FORM,
      ACTION       => 'next',
      REGISTRATION => 1,
      #USER        => \%FORM,
      USER_INFO    => ($FORM{UID})            ? $users   : undef,
      LNG_ACTION   => ($steps{ $FORM{step} }) ? $lang{NEXT} : $lang{REGISTRATION_COMPLETE},
      BACK_BUTTON  => (($FORM{TP_ID}) ? $html->form_input('TP_ID', "$FORM{TP_ID}", { TYPE => 'hidden' }) : '') .(   ($FORM{step} > 2) ? $html->form_input('finish', "$lang{FINISH}", { TYPE =>  ($steps{ $FORM{step} }) ? 'submit' : 'hidden' }) . ' ' . $html->form_input('back', "$lang{BACK}", { TYPE => 'submit' })
                                                                                                                                      : (!$FORM{back}) ? $html->form_input('add', "$lang{FINISH}", { TYPE => 'submit' })
                                                                                                                                                       : $html->form_input('change', "$lang{FINISH}", { TYPE => 'submit' })),
      UID          => $FORM{UID},
      SUBJECT      => $lang{REGISTRATION}
    }
  );

  return 1;
}


#**********************************************************
=head2 form_contact_types()

=cut
#**********************************************************
sub form_contact_types{

  my $show_add_form = '';
  my $contact_type = { };

  my $Contacts = Contacts->new($db, $admin, \%conf);

  if ( $FORM{show_add_form} ){
    $show_add_form = 1;
  }
  elsif ( $FORM{chg} ){
    $contact_type = $Contacts->contact_types_info($FORM{chg});
    _error_show( $Contacts );

    $contact_type->{CHANGE_ID} = "ID";

    $show_add_form = 1;
  }
  elsif ( $FORM{add} ){
    $Contacts->contact_types_add( \%FORM );
    $html->message( 'info', $lang{ADDED} ) if (!_error_show( $Contacts ));
  }
  elsif ( $FORM{change} ){
    $FORM{IS_DEFAULT} = '0' if (!$FORM{IS_DEFAULT});
    $Contacts->contact_types_change( \%FORM );
    $html->message( 'info', $lang{CHANGED} ) if (!_error_show( $Contacts ));
  }
  elsif ( $FORM{del} ){
    $Contacts->contact_types_del( { ID => $FORM{del} } );
    $html->message( 'info', $lang{DELETED} ) if (!_error_show( $Contacts ));
  }

  if ( $show_add_form ){
    $contact_type->{IS_DEFAULT_CHECKED} = $contact_type->{IS_DEFAULT} ? 'checked="checked"' : q{};

    $html->tpl_show( templates( "form_contact_types" ), {
      %{$contact_type},
      SUBMIT_BTN_NAME   => ($FORM{chg}) ? "$lang{CHANGE}" : "$lang{ADD}",
      SUBMIT_BTN_ACTION => ($FORM{chg}) ? "change" : "add"
    } );
  }

  my $default_fields = 'ID,NAME,IS_DEFAULT';
  my $filter_cols = { map { $_, '_translate' } split ( ",", uc $default_fields ) };

  result_former( {
    INPUT_DATA      => $Contacts,
    FUNCTION        => 'contact_types_list',
    DEFAULT_FIELDS  => $default_fields,
    FILTER_COLS     => $filter_cols,
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      id           => '#',
      name       => $lang{NAME},
      is_default => $lang{DEFAULT}
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{CONTACTS} $lang{TYPE}",
      ID      => "CONTACT_TYPES_TABLE",
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&show_add_form=1:add"
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Events',
    TOTAL     => 1
  });

  return 1;
}

#**********************************************************
=head2 _build_user_contacts_form($user_contacts_list)

  Arguments:
    $user_contacts_list -

  Returns:

=cut
#**********************************************************
sub _build_user_contacts_form{
  my ($user_contacts_list, $user_contacts_types_list) = @_;

  my $in_reg_wizard = ($FORM{UID}) ? 0 : 1;
  my $default_types_string = q{};

  # In reg wizard, show default types
  if ( $in_reg_wizard ){
    my @default_contacts = ();
    my @default_type_ids = ();

    my @default_types = grep { $_->{is_default} } @{$user_contacts_types_list};

    foreach my $default_type ( @default_types ){
      push( @default_contacts,
          {
              type_id => $default_type->{id},
              value   => ''
          }
      );
      push( @default_type_ids, $default_type->{id} );
    }

    $user_contacts_list = \@default_contacts;
    $default_types_string = join( ", ", @default_type_ids );
  }

  # Try to load fastest possible JSON module or fail
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
          contacts => $user_contacts_list,
          options  => {
              callback_index => $index,
              types          => $user_contacts_types_list,
              uid            => $FORM{UID},
              in_reg_wizard  => $in_reg_wizard
          }
      } );

  my $user_contacts_template = $html->tpl_show(
      templates( 'form_user_contacts' ),
      {
          DEFAULT_TYPES => $default_types_string,
          JSON          => qq{ "json" : $contacts_json }
      },
      { OUTPUT2RETURN => 1 }
  );

  return $user_contacts_template;
}

#**********************************************************
=head2 user_contacts_renew()

=cut
#**********************************************************
sub user_contacts_renew{

  my $message = $lang{ERROR};
  my $status = 1;

  my $Contacts = Contacts->new($db, $admin, \%conf);
  return 0 unless ($FORM{uid} && $FORM{CONTACTS});

  if ( my $error = load_pmodule2( "JSON", { RETURN => 1 } ) ){
    print $error;
    return 0;
  }

  my $json = JSON->new();

  $FORM{CONTACTS} =~ s/\\\"/\"/g;

  my $contacts = $json->decode( $FORM{CONTACTS} );
  my DBI $db_ = $users->{db}->{db};
  if ( ref $contacts eq 'ARRAY' ){
    $db_->{AutoCommit} = 0;

    $Contacts->contacts_del( { UID => $FORM{uid} } );
    if ( $users->{errno} ){
      $db_->rollback();
      $status = $users->{errno};
      $message = $users->{sql_errstr};
    }
    else{
      foreach my $contact ( @{$contacts} ){
        $Contacts->contacts_add( { %{$contact}, UID => $FORM{uid} } );
      }

      if ( $users->{errno} ){
        $db_->rollback();
        $status = $users->{errno};
        $message = $users->{sql_errstr};
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
=head2 form_info_field_tpl($attr) - Info fields tp form

  Arguments:
    COMPANY  - Company info fields
    VALUES   - Info field value hash_ref

  Returns:
    Return formed form

=cut
#**********************************************************
sub form_info_field_tpl {
  my ($attr) = @_;

  my @field_result = ();

  my $prefix = $attr->{COMPANY} ? 'ifc*' : 'ifu*';
  my $list = $Conf->config_list(
    {
      PARAM => $prefix,
      SORT  => 2
    }
  );
  my $uid = $FORM{UID} || q{};

  foreach my $line (@$list) {
    my $field_id = '';
    if ($line->[0] =~ /$prefix(\S+)/) {
      $field_id = $1;
    }
    #($position, $type, $name, $user_portal, $can_be_changed_by_user)
    my (undef, $type, $name, $user_portal, $can_be_changed_by_user) = split(/:/, $line->[1]);
    next if ($attr->{CALLED_FROM_CLIENT_UI} && !$user_portal);

    my $input      = '';
    my $field_name = uc($field_id);
    if (!defined($type)) {
      $type = 0;
    }

    my $disabled_ex_params = ($attr->{CALLED_FROM_CLIENT_UI} && !$can_be_changed_by_user) ? 'disabled="disabled"' : '';
    #Select
    if ($type == 2) {
      $input = $html->form_select(
        $field_name,
        {
          SELECTED      => $attr->{VALUES}->{$field_name} || $FORM{$field_name},
          SEL_LIST      => $users->info_lists_list({ LIST_TABLE => $field_id . '_list', COLS_NAME => 1 }),
          SEL_OPTIONS   => { '' => '--' },
          NO_ID         => 1,
          ID            => $field_id,
          EX_PARAMS     => $disabled_ex_params,
          OUTPUT2RETURN => 1
        }
      );
    }

    #Checkbox
    elsif ($type == 4) {
      $input = $html->form_input(
        $field_name,
        1,
        {
          TYPE  => 'checkbox',
          STATE => (($attr->{VALUES} && $attr->{VALUES}->{$field_name}) || $FORM{$field_name}) ? 1 : undef,
          ID    => $field_id,
          EX_PARAMS => ((!$attr->{SKIP_DATA_RETURN}) ? "data-return='1' " : '') . $disabled_ex_params,
          OUTPUT2RETURN  => 1
        }
      );
    }

    #'ICQ',
    elsif ($type == 8) {
      $input = $html->form_input($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, {
          SIZE => 10,
          ID => $field_id,
          EX_PARAMS => $disabled_ex_params,
          OUTPUT2RETURN  => 1
        });
      if ($attr->{VALUES}->{$field_name}) {
        #
        $input .= " <a href=\"http://www.icq.com/people/about_me.php?uin=$attr->{VALUES}->{$field_name}\"><img  src=\"http://status.icq.com/online.gif?icq=$attr->{VALUES}->{$field_name}&img=21\" border='0'></a>";
      }
    }

    #'URL',
    elsif ($type == 9) {
      $input = $html->element(
        'div',
        $html->form_input($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, { ID => $field_id, EX_PARAMS => $disabled_ex_params, OUTPUT2RETURN  => 1 })
          . $html->element(
          'span',
          $html->button(
            $lang{GO},
            "",
            {
              GLOBAL_URL => $attr->{VALUES}->{$field_name},
              ex_params  => ' target=' . ($attr->{VALUES}->{$field_name} || '_new'),
            }
          ),
          { class => 'input-group-addon' }
        ),
        { class => 'input-group' }
      );
    }

    #'PHONE',
    #'E-Mail'
    #'SKYPE'
    elsif ($type == 12) {
      $input = $html->form_input($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, { SIZE => 20, ID => $field_name, EX_PARAMS => $disabled_ex_params, OUTPUT2RETURN  => 1 });
      if ($attr->{VALUES}->{$field_name}) {
        $input .=
          qq{  <script type="text/javascript" src="http://download.skype.com/share/skypebuttons/js/skypeCheck.js"></script>  <a href="skype:abills.support?call"><img src="http://mystatus.skype.com/smallclassic/$attr->{VALUES}->{$field_name}" style="border: none;" width="114" height="20"/></a>};
      }
    }
    elsif ($type == 3) {
      $input = $html->form_textarea($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, { ID => $field_id, EX_PARAMS => $disabled_ex_params, OUTPUT2RETURN  => 1 });
    }
    elsif ($type == 13) {
      my $Attach = Attach->new($db, $admin, \%conf);
      my $file_id = $attr->{VALUES}->{$field_name} || q{};

      $Attach->attachment_info({ ID => $file_id, TABLE => $field_id . '_file' });

      my $file_name = q{};
      if ($Attach->{TOTAL}) {
        $file_name = $Attach->{FILENAME};
      }

      $input = "<div class='input-group file-input'>";
      my $file_download_url = "?qindex=" . get_function_index('user_pi')
          . "&ATTACHMENT=$field_id:$file_id"
          . (($uid) ? "&UID=$uid" : '');

        $input .= qq(
	          <label class="input-group-btn">
	              <span class="btn btn-default">&hellip;
	                <input type="file" class="file-hidden" style="display: none;" name="$field_name">
	              </span>
	          </label>
	          <input type="text" readonly="readonly" class="form-control file-visible" target="_blank"
	           value="$file_name" data-url="$file_download_url"
	           />
        );

      if (exists $attr->{VALUES}->{$field_name}) {
        if ($Attach->{TOTAL} && $Attach->{FILENAME} && $permissions{0}{5}) {
          $input .= $html->element(
            'span',
            $html->button(
              "$lang{DEL}",
              "index=" . get_function_index('user_pi') . "&ATTACHMENT=$field_id:$file_id&del=1" . (($uid) ? "&UID=$uid" : ''),
              { class => 'del', MESSAGE => "$lang{DELETED}: $Attach->{FILENAME} ?" }
            ),
            { class => 'input-group-addon' }
          );
        }
      }

      $input .= "</div>";
    }

    #Photo
    elsif ($type == 15) {
      $input = $html->button('', "index=$index&PHOTO=$uid&UID=$uid", { ICON => 'glyphicon glyphicon-camera' });
      if (-f "$conf{TPL_DIR}/if_image/" . $uid . '.jpg') {
        $input .= $html->element('span', '', { class => 'glyphicon glyphicon-user' });
      }
    }

    #Social network
    #Icons
    # fa fa-vk
    # fa fa-odnoklassniki
    # fa fa-facebook
    # fa fa-twitter
    # fa fa-google-plus
    elsif ($type == 16) {

      next if ($attr->{CALLED_FROM_CLIENT_UI}); # Social icons already displaying in "Password" tab

      my $values = ($attr->{VALUES} && $attr->{VALUES}->{$field_name}) ? $attr->{VALUES}->{$field_name} : ($FORM{$field_id} || '');
      my ($k, $val) = split(/, /, $values);
      $input = "<div class='form-group'>
      <div class='col-sm-6'>"
        . $html->form_select(
        $field_name,
        {
          SELECTED  => $k,
          SEL_ARRAY => [ 'facebook', 'vk', 'twitter', 'ok', 'instagram', 'google' ],
          SEL_OPTIONS => { '' => '--' },
        }
      )
        . "</div>"
        . $html->element('span', '', { class => 'visible-xs col-xs-12', style=> 'padding-top: 10px' })
        . "<div class='col-sm-6'>"
        . "<div class='input-group' style='width: 100%'>"
        . $html->form_input($field_name, $val, { ID => $field_id, OUTPUT2RETURN  => 1 });

      if ($val) {
        $input .= $html->element('span', $html->button('', "index=" . get_function_index('user_pi') . "&UID=$uid&SOCIAL_INFO=$k, $val", { class => 'info' }), { class => 'input-group-addon' });
      }

      $input .= "</div></div></div>";
    }
    else {
      if ($attr->{VALUES}->{$field_name}) {
        $attr->{VALUES}->{$field_name} =~ s/\"/\&quot;/g;
      }
      $input = $html->form_input( $field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, {
          ID            => $field_id,
          EX_PARAMS     => $disabled_ex_params,
          OUTPUT2RETURN => 1
        } );
    }

    $attr->{VALUES}->{ 'FORM_' . $field_name } = $input;

    push @field_result,
      $html->tpl_show(
        templates('form_row_dynamic_size'),
        {
          ID         => "$field_id",
          NAME       => (_translate($name)),
          VALUE      => $input,
          COLS_LEFT  => $attr->{COLS_LEFT} || 'col-xs-4',
          COLS_RIGHT => $attr->{COLS_RIGHT} || 'col-xs-8',
        },
        { OUTPUT2RETURN => 1, ID => "$field_id" }
      );
  }

  my $info = join((($FORM{json}) ? ',' : ''), @field_result);

  return $info;
}

#**********************************************************
=head2 form_show_attach($attr)

=cut
#**********************************************************
sub form_show_attach {
  my($attr)=@_;

  require Attach;
  Attach->import();
  my $Attach = Attach->new($db, $admin, \%conf);
  my $uid = $attr->{UID} || $user->{UID};

  if ($FORM{ATTACHMENT} =~ /(.+):(\d+)/) {
    $FORM{TABLE}      = $1 . '_file';
    $FORM{ATTACHMENT} = $2;
  }

  $Attach->attachment_info(
    {
      ID    => $FORM{ATTACHMENT},
      TABLE => $FORM{TABLE},
      UID   => $uid
    }
  );

  if (! $Attach->{TOTAL}) {
    print "Content-Type: text/html\n\n";
    print "$lang{ERROR}: $lang{ATTACHMENT} $lang{NOT_EXIST}\n";
    return 0;
  }

  if($conf{ATTACH2FILE} && $Attach->{CONTENT} =~ /FILENAME: (.+)/) {
    my $filename = $1 || q{};
    $conf{ATTACH2FILE}="$conf{TPL_DIR}/attach/";

    if($uid) {
      $conf{ATTACH2FILE} .= "$uid/";
    }

    $Attach->{CONTENT} = file_op({
      FILENAME => "$conf{ATTACH2FILE}/$filename",
      PATH     => "$conf{TPL_DIR}/attach/". (($uid) ? "$uid/" : ''),
    });
  }

  print "Content-Type: $Attach->{CONTENT_TYPE}; filename=\"$Attach->{FILENAME}\"\n";
  if($Attach->{FILENAME} !~ /\.jpg|\.pdf|\.djvu|\.png|\.gif/i) {
    print   "Content-Disposition: attachment; filename=\"$Attach->{FILENAME}\"; size=\"$Attach->{FILESIZE}\";\n"
     . "Content-Length: $Attach->{FILESIZE};\n";
  }
  print  "\n";
  print $Attach->{CONTENT};

  return 1;
}

#**********************************************************
=head2 form_fees_wizard($attr)

=cut
#**********************************************************
sub form_fees_wizard {
  my ($attr) = @_;

  my $fees = Finance->fees($db, $admin, \%conf);
  my $output = '';
  my %FEES_METHODS = ();

  if ($FORM{add}) {
    %FEES_METHODS = %{ get_fees_types({ SHORT => 1 }) };

    my $i       = 0;
    my $message = '';
    while (defined($FORM{ 'METHOD_' . $i }) && $FORM{ 'METHOD_' . $i } ne '') {
      my ($type_describe, $price) = split(/:/, $FEES_METHODS{ $FORM{ 'METHOD_' . $i } }, 2);

      if (!$FORM{ 'SUM_' . $i } && $price && $price > 0) {
        $FORM{ 'SUM_' . $i } = $price;
      }

      if (! $FORM{ 'SUM_' . $i } || $FORM{ 'SUM_' . $i } <= 0) {
        $i++;
        next;
      }

      $fees->take(
        $attr->{USER_INFO},
        $FORM{ 'SUM_' . $i },
        {
          DESCRIBE => $FORM{ 'DESCRIBE_' . $i } || $FEES_METHODS{ $FORM{ 'METHOD_' . $i } },
          INNER_DESCRIBE => $FORM{ 'INNER_DESCRIBE_' . $i }
        }
      );

      $message .= "$type_describe $lang{SUM}: " . sprintf( '%.2f',
        $FORM{ 'SUM_' . $i } ) . ", " . $FORM{ 'DESCRIBE_' . $i } . "\n";

      $i++;
    }

    if ($message ne '') {
      $html->message( 'info', $lang{FEES}, "$message" );
    }

    return 1;
  }

  %FEES_METHODS = %{ get_fees_types() };

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "$lang{FEES} $lang{TYPES}",
      title      => [ '#', $lang{TYPE}, $lang{SUM}, $lang{DESCRIBE}, "$lang{ADMIN} $lang{DESCRIBE}" ],
      cols_align => [ 'right', 'left', 'left', 'left', 'center:noprint' ],
      qs         => $pages_qs,
      ID         => 'FEES_WIZARD',
    }
  );

  for (my $i = 0 ; $i <= 6 ; $i++) {
    my $method = $html->form_select(
      'METHOD_' . $i,
      {
        SELECTED => $FORM{ 'METHOD_' . $i },
        SEL_HASH => {%FEES_METHODS},
        NO_ID    => 1,
        SORT_KEY => 1
      }
    );

    $table->addrow(($i + 1), $method, $html->form_input('SUM_' . $i, $FORM{ 'SUM_' . $i }, { SIZE => 8 }), $html->form_input('DESCRIBE_' . $i, $FORM{ 'DESCRIBE_' . $i }, { SIZE => 30 }), $html->form_input('INNER_DESCRIBE_' . $i, $FORM{ 'INNER_DESCRIBE_' . $i }, { SIZE => 30 }),);
  }

  if ($attr->{ACTION}) {
    my $action = "";
    if ($attr->{ACTION}) {
      $action = $html->br() . $html->form_input( 'finish', "$lang{REGISTRATION_COMPLETE}",
        { TYPE => 'submit' } ) . ' ' . $html->form_input( 'back', "$lang{BACK}",
        { TYPE => 'submit' } ) . ' ' . $html->form_input( 'next', "$lang{NEXT}", { TYPE => 'submit' } );
    }
    else {
      $action = $html->form_input( 'change', "$lang{CHANGE}", { TYPE => 'submit' } );
    }

    $table->{extra}    = 'colspan=5 align=center';
    $table->{rowcolor} = 'even';
    $table->addrow($action);
    print $html->form_main(
        {
          CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
          HIDDEN  => {
            index => $index,
            step  => $FORM{step},
            UID   => $FORM{UID}
          },
         #SUBMIT  =>  { $atrr->{ACTION}   => $attr->{LNG_ACTION} }
        }
      );
    form_fees($attr);
  }
  else {
    return $output;
  }

  return 1;
}

1;
