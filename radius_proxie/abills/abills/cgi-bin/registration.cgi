#!/usr/bin/perl -w

=head2 NAME

  Main  registration engine

=cut

use strict;
use warnings;
BEGIN {
  our $libpath  = '../';
  our $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/", $libpath . 'lib/', $libpath . 'Abills/modules/', $libpath . 'Abills/',);

  eval { require Time::HiRes; };
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}


use Abills::Defs;
our (%OUTPUT, @REGISTRATION, %lang, %LANG, $base_dir);
do "../libexec/config.pl";

use Abills::Base qw(sendmail in_array load_pmodule);
use Abills::Fetcher;
use Users;
use Finance;
use Admins;
use Tariffs;
use Sharing;

our $sid  = '';
our $html = Abills::HTML->new({ CONF => \%conf, NO_PRINT => 1, });
our $db   = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

if ($conf{LANGS}) {
  $conf{LANGS} =~ s/\n//g;
  my (@lang_arr) = split(/;/, $conf{LANGS});
  %LANG = ();
  foreach my $l (@lang_arr) {
    my ($lang, $lang_name) = split(/:/, $l);
    $lang =~ s/^\s+//;
    $LANG{$lang} = $lang_name;
  }
}

my $CAPTCHA_DIR = $base_dir . 'cgi-bin/captcha/';
my %INFO_HASH   = ();

our $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

our $users = Users->new($db, $admin, \%conf);

if($html->{language} ne 'english') {
  do $libpath . "/language/english.pl";
}

if(-f $libpath . "/language/$html->{language}.pl") {
  do $libpath."/language/$html->{language}.pl";
}

require Abills::Templates;
require Abills::Misc;

$INFO_HASH{SEL_LANGUAGE} = $html->form_select(
  'language',
  {
    EX_PARAMS => 'onChange="selectLanguage()"',
    SELECTED  => $html->{language},
    SEL_HASH  => \%LANG,
    NO_ID     => 1
  }
);

if($FORM{external_auth}) {
  get_sn_info();
}

if($conf{FB_REGISTRATION}) {
  my $log_url = "external_auth=Facebook";
  $log_url .= "&user_registration=1" if ($FORM{user_registration});
  $INFO_HASH{FB_INFO} = $html->button("Facebook", $log_url, { class => 'btn btn-primary' });
  $INFO_HASH{FB_INFO_BLOCK} = $html->button("Facebook", $log_url, { class => 'btn btn-primary btn-block' });
}

if($FORM{check_address}) {
  $INFO_HASH{CHECKED_ADDRESS_MESSAGE} = get_address_connected_message();
}

# Check modules for registration are enabled
if (@REGISTRATION){
  @REGISTRATION = grep {in_array($_, \@MODULES) } @REGISTRATION;
}

if ($FORM{FORGOT_PASSWD}) {
  password_recovery();
}
elsif (!@REGISTRATION){
  print "Content-Type: text/html\n\n";
  print "Can't find modules services for registration";
  exit;
}
elsif ($FORM{qindex} && $FORM{qindex} =~ /^\d+$/ && $FORM{qindex} == 30 && !$conf{REGISTRATION_NO_ADDRESS_REGISTER}) {
  require Control::Address_mng;
  form_address_sel();
}
elsif ($#REGISTRATION > -1) {
  my $m = ($FORM{module} && $FORM{module} =~ /^[a-z\_0-9]+$/i && in_array($FORM{module}, \@MODULES))
  ? $FORM{module}
  : $REGISTRATION[0];
  
  if ($m ne 'Osbb' && $m ne 'Vacations' && $m ne 'Expert') {
    my $choose_module_buttons = '';
    if ($#REGISTRATION > 0 && !$FORM{registration}) {
      foreach my $registration_module (@REGISTRATION) {
        $choose_module_buttons .= $html->button($registration_module, "module=$registration_module", { class => 'btn btn-lg btn-default' }) . ' ';
      }
    }
    # check address button
    $choose_module_buttons .= "<button type='button' class='btn btn-lg btn-success' data-toggle='modal' data-target='#checkAddress'>" . $lang{CHECK_ADDRESS} . "</button>";
    $html->{HEADER_ROW} = $html->element('div', $choose_module_buttons, { class => 'row'});
  }
  else {
    $INFO_HASH{user_registration} = $FORM{user_registration} || '';
  }
  $INFO_HASH{CAPTCHA} = get_captcha();

  $INFO_HASH{RULES} = $html->tpl_show(templates('form_accept_rules'), {}, { OUTPUT2RETURN => 1 });
  $INFO_HASH{language} = $html->{language};

  if (!$FORM{DOMAIN_ID}) {
    $FORM{DOMAIN_ID}      = 0;
    $INFO_HASH{DOMAIN_ID} = 0;
  }
  
  if ($conf{REGISTRATION_CAPTCHA} && ($FORM{reg} || $FORM{add})) {
    unless (check_captcha(\%FORM)) {
      delete $FORM{reg};
      delete $FORM{add};
    }
  }
  
  load_module($m, $html);

  $m = lc($m);

  my $function = $m . '_registration';

  if(defined(&$function)) {
    my $return = &{ \&{$function} }(\%INFO_HASH);
    
    # Send E-mail to admin after registration
    if ($return && $return > 1) {
      my $message = $html->tpl_show(templates('registration_admin_notification'),
        {
          LOGIN => $FORM{LOGIN},
          FIO   => $FORM{FIO},
          DATE  => $DATE,
          TIME  => $TIME,
          REMOTE_ADDR=> $ENV{REMOTE_ADDR},
          MODULE=> $m,
          EMAIL => $FORM{EMAIL}
        },
        { OUTPUT2RETURN => 1});

      if ($conf{REGISTRATION_EXTERNAL}) {
        if (!_external($conf{REGISTRATION_EXTERNAL}, { %FORM })) {
          #return 0;
        }
      }

      sendmail(
        $conf{ADMIN_MAIL},
        $conf{ADMIN_MAIL},
        'New registration request',
        $message,
        $conf{MAIL_CHARSET},
        ''
      );
  
      if ($conf{REGISTRATION_REDIRECT}) {
        $html->redirect($conf{REGISTRATION_REDIRECT}, { MESSAGE => $lang{SENDED} });
        exit 0;
      }
    }
  }
  else {
    $html->message('err', $FORM{module}, 'No registration for module');
  }
}

$admin->{SETTINGS}->{SKIN}         = 'skin-blue';
$admin->{SETTINGS}->{FIXED_LAYOUT} = '';
$admin->{MENU_HIDDEN}              = '';
$admin->{RIGHT_MENU_OPEN}          = '';

if (!($FORM{header} && $FORM{header} == 2)) {
  print $html->header();

  $OUTPUT{HTML_STYLE} = 'default_adm';
  $OUTPUT{BODY}       = $html->{OUTPUT};
  # check address form
  $OUTPUT{ADDRESS}    = $html->tpl_show(templates('form_address_build_sel'), { HIDE_ADD_BUILD_BUTTON => "style='display:none;'"  }, {OUTPUT2RETURN => 1});
  $OUTPUT{TITLE}      = "$conf{WEB_TITLE} - $lang{REGISTRATION}";
  
  print $html->tpl_show(templates('registration'), { %OUTPUT, TITLE_TEXT => $lang{REGISTRATION} });
}
else {
  print "Content-Type: text/html\n\n";
  print $html->{OUTPUT};
}

#**********************************************************
=head2 password_recovery() - Password recovery

=cut
#**********************************************************
sub password_recovery {
  if ($FORM{SEND} && (!$conf{REGISTRATION_CAPTCHA} || check_captcha(\%FORM))) {
    password_recovery_process();
  }

  my %info = ();
  if (in_array('Sms', \@MODULES)) {
    $info{EXTRA_PARAMS} = $html->tpl_show(_include('sms_check_form', 'Sms'), undef, { OUTPUT2RETURN => 1 });
  }

  $info{CAPTCHA} = get_captcha();

  $html->tpl_show(templates('form_forgot_passwd'), { %FORM, %info });

  return 1;
}

#**********************************************************
=head2 password_recovery_process()

=cut
#**********************************************************
sub password_recovery_process {

  # Possible pairs are
  #   login + mail
  #   login + phone
  #   uid + mail
  #   uid + phone
  unless ( ($FORM{LOGIN} || $FORM{UID} || $FORM{CONTRACT_ID}) && ($FORM{EMAIL} || $FORM{PHONE}) ) {
    $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA}");
    return 0;
  }

  # Do not send empty parameters to list (we checked them below)
  my @args_can_be_empty = qw( PHONE UID LOGIN EMAIL CONTRACT_ID );
  foreach my $arg (@args_can_be_empty) {
    delete $FORM{$arg} if (exists $FORM{$arg} && ($FORM{$arg} eq '' || $FORM{$arg} eq '*'));
  }

  my $users_list = $users->list({
    PHONE => '_SHOW',
    EMAIL => '_SHOW',
    %FORM,
    COLS_NAME => 1
  });

  if (!$users->{TOTAL} || $users->{TOTAL} < 1) {
    my $search_param = ($FORM{PHONE} && $FORM{PHONE} ne '') ? $lang{CELL_PHONE} : 'E-mail';
    $html->message('err', $lang{ERROR}, "$lang{USER} $lang{NOT_EXIST} $lang{OR} $search_param $lang{NOT_EXIST}");
    return 0;
  }

  my $user = $users_list->[0];

  my $email = $user->{email};
  my $phone = $user->{phone};
  my $uid   = $user->{uid};

  my $pi = $users->pi({ UID => $uid });
  my $user_info = $users->info($uid, { SHOW_PASSWORD => 1 });

  my $message = $html->tpl_show(
    templates('msg_passwd_recovery'),
    {
      MESSAGE => "$lang{LOGIN}:  $users->{LOGIN}\n" . "$lang{PASSWD}: $users->{PASSWORD}\n\n",
      %{$user_info},
      %{$pi}
    },
    { OUTPUT2RETURN => 1 }
  );

  if ($email && $email ne '') {
    sendmail("$conf{ADMIN_MAIL}", "$email", "$PROGRAM Password Repair", "$message", "$conf{MAIL_CHARSET}", "");
    $html->message('info', $lang{INFO}, "$lang{SENDED}");
  }
  else {
    $html->message('info', $lang{INFO}, "E-Mail $lang{NOT_EXIST}");
  }

  if ($FORM{SEND_SMS} && in_array('Sms', \@MODULES)) {
    load_module('Sms', $html);
    my $sms_sent = sms_send({
      NUMBER  => $phone,
      MESSAGE => $message,
      UID     => $uid
    });

    if ($sms_sent){
      $html->message('info', "$lang{INFO}", "SMS $lang{SENDED}");
    }
  }

  return 1;
}

#**********************************************************
=head2 get_address_connected_message()

=cut
#**********************************************************
sub get_address_connected_message {

  require Control::Address_mng;
  require Address;
  my $Address = Address->new($db, $admin, \%conf);

  my $info = $Address->build_info({ID => $FORM{LOCATION_ID}});
  
  return ($info->{PLANNED_TO_CONNECT} && $info->{PLANNED_TO_CONNECT} == 1)
    ? "<div class='callout callout-info'>$lang{CHECK_ADDRESS_PLANNED_TO_CONNECT_MSG}</div>"
    : "<div class='callout callout-info'>$lang{CHECK_ADDRESS_CONNECTED_MSG}</div>";
}

#**********************************************************
=head2 get_captcha()

=cut
#**********************************************************
sub get_captcha {
  
  return if (!$conf{REGISTRATION_CAPTCHA});
  if ($conf{GOOGLE_CAPTCHA_KEY}) {
    return "<script src='https://www.google.com/recaptcha/api.js'></script><div class='g-recaptcha' data-sitekey='$conf{GOOGLE_CAPTCHA_KEY}'></div>";
  }

  my $captcha_module_load_error = load_pmodule( 'Authen::Captcha', { RETURN => 1, HEADER => 1 } );

  if ($captcha_module_load_error){
    print "Content-Type: text/html\n\n";
    print $captcha_module_load_error;
  };

  my $Captcha = Authen::Captcha->new(
    data_folder   => $CAPTCHA_DIR,
    output_folder => $CAPTCHA_DIR,
  );
  
  $INFO_HASH{CAPTCHA_OBJ} = $Captcha;
  
  if (!(-d $CAPTCHA_DIR || mkdir($CAPTCHA_DIR))) {
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_CANT_CREATE_FILE} '$CAPTCHA_DIR' $lang{ERROR}: $!\n" );
    $html->message( 'info', $lang{INFO}, "$lang{NOT_EXIST} '$CAPTCHA_DIR'" );
  }
  else {
    my $number_of_characters = 5;
    my $md5sum = eval { return $Captcha->generate_code( $number_of_characters ) };
    
    if (!$md5sum) {
      print "Content-Type: text/html\n\n";
      print "Can't make captcha\n";
      print $@;
      exit;
    }
    
    $INFO_HASH{CAPTCHA} = $html->tpl_show( templates('form_captcha'), { MD5SUM => $md5sum }, { OUTPUT2RETURN => 1 } );
  }
  
  return ($Captcha, $INFO_HASH{CAPTCHA});
}

#**********************************************************
=head2 check_captcha($user_input, $md5hash)

  Arguments:
   $user_input
   $md5hash

  Returns:
    boolean

=cut
#**********************************************************
sub check_captcha {
  my ($attr) = @_;

  if ($conf{GOOGLE_CAPTCHA_KEY}) {
    my $response = $attr->{'g-recaptcha-response'};
    my $url = "https://www.google.com/recaptcha/api/siteverify?secret=$conf{GOOGLE_CAPTCHA_SECRET}&response=$response";
    my $result = web_request($url, {
      JSON_RETURN => 1,
    });
    
    if($result && ref $result eq 'HASH' && $result->{success} && $result->{success} ne 'false') {
      return 1;
    }
    $html->message('err', "Captcha: $lang{ERROR}");
    return 0;
  }
  
  my $user_input = $attr->{CCODE} || q{};
  my $md5hash    = $attr->{C} || q{};
  
  load_pmodule('Authen::Captcha', { HEADER => 1 });

  my $Captcha = Authen::Captcha->new(
    data_folder   => $CAPTCHA_DIR,
    output_folder => $CAPTCHA_DIR,
    debug         => 0
  );

  my $result = $Captcha->check_code($user_input, $md5hash);

  if ($result == 0) {
    $html->message('err', "Captcha: $lang{ERROR}");
    #file error
  }
  elsif ($result == -1) {
    $html->message('err', "Captcha: has been expired");
    #code expired
  }
  elsif ($result == -2) {
    $html->message('err', "Captcha: invalid (-2)");
    #code invalid
  }
  elsif ($result == -3) {
    #code does not match crypt
    $html->message('err', "Captcha: invalid (-3)");
  }

  return $result == 1;
}

#**********************************************************
=head2 get_sn_info()
  Social network info

=cut
#**********************************************************
sub get_sn_info {
  use Abills::Auth::Core;
  my $Auth;

  $Auth = Abills::Auth::Core->new({
    CONF      => \%conf,
    AUTH_TYPE => $FORM{external_auth},
    SELF_URL  => $SELF_URL,
  });
  $Auth->check_access(\%FORM);
  
  if($Auth->{auth_url}) {
    print "Location: $Auth->{auth_url}\n\n";
    exit;
  }
  elsif($Auth->{USER_ID}) {
    $users->list({
      $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
      LOGIN                => '_SHOW',
      PASSWORD             => '_SHOW',
      FIO                  => '_SHOW',
      COLS_NAME            => 1
    });

    if($users->{TOTAL}) {
      $html->message('warn', "$Auth->{USER_NAME} already registred");
      return 1;
    }
    else {
      $INFO_HASH{FIO} = $Auth->{USER_NAME};
      $INFO_HASH{EMAIL} = $Auth->{EMAIL};
      $INFO_HASH{USER_ID} = $Auth->{USER_ID};
      $INFO_HASH{$Auth->{CHECK_FIELD}} = $Auth->{USER_ID};
      my $login_url = $SELF_URL;
      $login_url =~ s/registration/index/;
      $login_url .= "?external_auth=Facebook";
      $INFO_HASH{login_url} = $login_url;
    }
  }  
  return 1;
}


1
