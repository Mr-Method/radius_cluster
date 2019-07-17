=head1 NAME


=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(sendmail decode_base64 mk_unique_value in_array);

our(
  $db,
  $admin,
  $html,
  %conf,
  %lang,
  %err_strs,
  %LANG,
  %permissions,
  %OUTPUT,
);

#**********************************************************
=head2 admin_auth() - Primary auth form

=cut
#**********************************************************
sub auth_admin {
  #Cookie auth
  if ($conf{AUTH_METHOD}) {
    if ($index == 10) {
      $admin->online_del({ SID => $COOKIES{admin_sid} });
    }
    if (! $html || ! $html->{language}) {
      $html->{language}='english';
    }

    if($html->{language} ne 'english') {
      do "language/english.pl"
    }
    eval { do "language/$html->{language}.pl" };

    if($@) {
      print "Content-Type: text/plain\n\n";
      print "Can't load language\n";
      print $@;
      print ">> language/$html->{language}.pl << ";
      exit;
    }

    my $res = check_permissions($FORM{user}, $FORM{passwd}, $COOKIES{admin_sid}, \%FORM);

    if (! $res) {
      if ($FORM{REFERER} && $FORM{REFERER} =~ /$SELF_URL/ && $FORM{REFERER} !~ /index=10/) {
        $html->set_cookies('admin_sid', $admin->{SID}, '', '/');
        $COOKIES{admin_sid} = $admin->{SID};
        $admin->online({ SID => $admin->{SID}, TIMEOUT => $conf{web_session_timeout} });
        print "Location: $FORM{REFERER}\n\n";
      }

      #      if ($FORM{API_INFO}) {
      #        require Control::Api;
      #        form_system_info($FORM{API_INFO});
      #        return 0;
      #      }
    }
    else {
      my $cookie_sid = ($COOKIES{admin_sid} || '');
      my $admin_sid = ($admin->{SID} || '');

      if ($FORM{AJAX} || $FORM{json}){
        print "Content-Type:application/json\n\n";

        print qq{{"TYPE":"error","errstr":"Access Deny","sid":"$cookie_sid","aid":"$admin_sid","errno":"$res"}};
      }
      elsif( $FORM{xml}){
        print "Content-Type:application/xml\n\n";
        print qq{<?xml version="1.0" encoding="UTF-8"?>
        <error>
          <TYPE>error</TYPE>
          <errstr>Access Deny</errstr>
          <errno>$res</errno>
          <sid>$cookie_sid</sid>
          <aid>$admin_sid</aid>
        </error>
        };
      }
      else {
        $html->{METATAGS} = templates('metatags');
        print $html->header();
        my $err = '';

        if ( $admin->{errno} ) {
          if ( $admin->{errno} == 4 ) {
            $err = $lang{ERR_WRONG_PASSWD};
          }
        }

        form_login({ ERROR => $err });
        print "<!-- Access Deny. Auth cookie: $cookie_sid System: $admin_sid .$res -->";
      }

      if ($ENV{DEBUG}) {
        die();
      }
      else {
        exit 0;
      }
    }
  }

  #**********************************************************
  #IF Mod rewrite enabled Basic Auth
  #
  #    <IfModule mod_rewrite.c>
  #        RewriteEngine on
  #        RewriteCond %{HTTP:Authorization} ^(.*)
  #        RewriteRule ^(.*) - [E=HTTP_CGI_AUTHORIZATION:%1]
  #        Options Indexes ExecCGI SymLinksIfOwnerMatch
  #    </IfModule>
  #    Options Indexes ExecCGI FollowSymLinks
  #
  #**********************************************************
  else {
    if (defined($ENV{HTTP_CGI_AUTHORIZATION})){
      $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
      my ($REMOTE_USER, $REMOTE_PASSWD) = split( /:/, decode_base64( $ENV{HTTP_CGI_AUTHORIZATION} ) );

      if ( $REMOTE_USER ){
        $REMOTE_USER = substr( $REMOTE_USER, 0, 20 );
        $REMOTE_USER =~ s/\\//g;
      }
      else {
        $REMOTE_USER = q{};
      }
      if ($REMOTE_PASSWD) {
        $REMOTE_PASSWD = substr($REMOTE_PASSWD, 0, 20);
        $REMOTE_PASSWD=~s/\\//g;
      }

      my $res = check_permissions($REMOTE_USER, $REMOTE_PASSWD);
      if ($res == 1) {
        print "WWW-Authenticate: Basic realm=\"$conf{WEB_TITLE} Billing System\"\n";
        print "Status: 401 Unauthorized\n";
      }
      elsif ($res == 2) {
        print "WWW-Authenticate: Basic realm=\"Billing system / '$REMOTE_USER' Account Disabled\"\n";
        print "Status: 401 Unauthorized\n";
      }
    }
    else {
      print "'mod_rewrite' not install";
    }

    if ($admin->{errno}) {
      print "Content-Type: text/html\n\n";
      print $html->header();
      my $message = $lang{ERR_ACCESS_DENY};

      if ($admin->{errno} == 2) {
        $message = "Account DISABLE or $admin->{errstr}";
      }
      elsif ($admin->{errno} == 3) {
        $message = $lang{ERR_UNALLOW_IP};
      }
      elsif ($admin->{errno} == 4) {
        $message = $lang{ERR_WRONG_PASSWD} || 'ERR_WRONG_PASSWD';
      }
      else {
        $message = $err_strs{ $admin->{errno} };
      }

      $html->message( 'err', $lang{ERROR}, $message);
      exit;
    }
  }

  if($html->{language} ne 'english') {
    do "language/english.pl"
  }

  if(-f "$libpath/language/$html->{language}.pl") {
    do "$libpath/language/$html->{language}.pl";
  }

  return 1;
}

#**********************************************************
=head3 form_login() - Admin http login page

  Arguments:
    $attr
      ERROR

  Returns:

=cut
#**********************************************************
sub form_login {
  my ($attr) = @_;

  if ($FORM{forgot_passwd}) {
    if ($FORM{email}) {
      require Digest::SHA;
      Digest::SHA->import('sha256_hex');
      $admin->list({ EMAIL => $FORM{email} });
      if ($admin->{TOTAL} > 0) {
        my $digest = Digest::SHA::sha256_hex("$FORM{email}$DATE 1234567890");
        my $message = "Go to the following link to change your password. \n $SELF_URL?index=10&recovery_passwd=$digest";
        sendmail("$conf{ADMIN_MAIL}", "$FORM{email}", "$PROGRAM Password Repair", "$message", "$conf{MAIL_CHARSET}", "");
        $html->message('info', 'E-mail sended.');
      }
      else {
        $html->message('error', 'Wrong e-mail.');
      }
      exit;
    }
    else {
      $html->tpl_show(templates('form_admin_forgot_passwd'), \%FORM);
      exit;
    }
  }
  elsif ($FORM{recovery_passwd}) {
    require Digest::SHA;
    Digest::SHA->import('sha256_hex');
    my $admins_list = $admin->list({
      EMAIL     => '_SHOW',
      COLS_NAME => 1
    });
    foreach (@$admins_list) {
      my $digest = Digest::SHA::sha256_hex("$_->{email}$DATE 1234567890");
      if ($digest eq $FORM{recovery_passwd}) {
        if ($FORM{newpassword}) {
          my $admin_form = Admins->new($db, \%conf);
          $admin_form->info($_->{aid});
          $admin_form->change({ PASSWORD => $FORM{newpassword}, AID => $_->{aid} });
          if (!$admin_form->{errno}) {
            $html->message('info', $lang{CHANGED}, "$lang{CHANGED} ");
          }
        }
        else {
          my $password_form;
          $password_form->{PW_CHARS}      = $conf{PASSWD_SYMBOLS} || "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWYXZ";
          $password_form->{PW_LENGTH}     = $conf{PASSWD_LENGTH}  || 6;
          $password_form->{ACTION}        = 'change';
          $password_form->{LNG_ACTION}    = "$lang{CHANGE}";
          $password_form->{HIDDDEN_INPUT} = $html->form_input('recovery_passwd', $digest, { TYPE => 'hidden', OUTPUT2RETURN => 1 });
          $html->tpl_show(templates('form_password'), $password_form);
        }
        last;
      }
    }
    exit;
  }

  my %first_page = ();

  if ($conf{tech_works}) {
    $html->message( 'info', $lang{INFO}, $conf{tech_works} );
    return 0;
  }

  #Make active lang list
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

  my %QT_LANG = (
    byelorussian => 22,
    bulgarian    => 20,
    english      => 31,
    french       => 37,
    polish       => 90,
    russian      => 96,
    ukrainian      => 129,
  );

  $first_page{SEL_LANGUAGE} = $html->form_select(
    'language',
    {
      SELECTED     => $html->{language},
      SEL_HASH     => \%LANG,
      NO_ID        => 1,
      EX_PARAMS =>  "style='width:100%'",
      #      NORMAL_WIDTH => 1,
      EXT_PARAMS   => { qt_locale => \%QT_LANG}
    }
  );

  $first_page{TITLE} = $lang{AUTH};

  if (! $FORM{REFERER} && $ENV{HTTP_REFERER} && $ENV{HTTP_REFERER}  =~ /$SELF_URL/) {
    $FORM{REFERER} = $ENV{HTTP_REFERER};
  }

  if($attr->{ERROR}) {
    $first_page{ERROR_MSG} = $html->message( 'danger text-center', $lang{ERROR}, $attr->{ERROR}, {
        OUTPUT2RETURN => 1
      } );
  }

  if ($conf{TECH_WORKS}){
    $first_page{TECH_WORKS_BLOCK_VISIBLE} = 1;
    $first_page{TECH_WORKS_MESSAGE} = $conf{TECH_WORKS};
  }
  if ($conf{ADMIN_PASSWORD_RECOVERY}) {
    $first_page{PSWD_BTN} = $html->button("$lang{FORGOT_PASSWORD}?", "index=10&forgot_passwd=1");
  }

  $html->tpl_show(templates('form_login'), \%first_page, $attr);

  return 1;
}

#**********************************************************
=head2 check_permissions() - Checkadmin permission

  Arguments:
    $login
    $password
    $session_sid
    $attr
      API_KEY

  Returns:

    0 - Access
    1 - Deny
    2 - Disable
    3 - Deny IP
    4 - Wrong passwd
    5 - Wrong LDAP Auth
    6 - Deny IP/Time

=cut
#**********************************************************
sub check_permissions {
  my ($login, $password, $session_sid, $attr) = @_;

  $login    = '' if (!defined($login));
  $password = '' if (!defined($password));

  if ($conf{ADMINS_ALLOW_IP}) {
    $conf{ADMINS_ALLOW_IP} =~ s/ //g;
    my @allow_ips_arr = split(/,/, $conf{ADMINS_ALLOW_IP});
    my %allow_ips_hash = ();
    foreach my $ip (@allow_ips_arr) {
      $allow_ips_hash{$ip} = 1;
    }
    if (!$allow_ips_hash{ $ENV{REMOTE_ADDR} }) {
      if($conf{HIDE_WRONG_PASSWORD}) {
        $password = '****';
      }
      $admin->system_action_add("$login:$password DENY IP: $ENV{REMOTE_ADDR}", { TYPE => 11 });
      $admin->{errno} = 3;
      return 3;
    }
  }

  my %PARAMS = (
    IP    => $ENV{REMOTE_ADDR} || '0.0.0.0',
    SHORT => 1
  );

  $login    =~ s/"/\\"/g;
  $login    =~ s/'/\\'/g;
  $password =~ s/"/\\"/g;
  $password =~ s/'/\\'/g;

  if ($session_sid && ! $login && (! $attr->{API_KEY} && ! $attr->{key})) {
    $admin->online_info({ SID => $session_sid });
    if ($admin->{TOTAL} > 0 && $ENV{REMOTE_ADDR} eq $admin->{IP}) {
      $admin->{SID} = $session_sid;
    }
    else {
      $admin->online_del({ SID => $session_sid });
    }
  }
  else {
    if (! $session_sid) {
      Abills::HTML::get_cookies();
      $admin->{SID} = $COOKIES{admin_sid};
    }
    else {
      $admin->{SID} = mk_unique_value(14);
    }
    #LDAP auth
    if($conf{LDAP_IP}) {
      require Abills::Auth::Ldap;
      Abills::Auth::Ldap->import();
      my $Auth = Abills::Auth::Core->new({
        CONF      => \%conf,
        AUTH_TYPE => $FORM{external_auth}
      });

      my $result = $Auth->check_access({
        LOGIN    => $login . ',ou=users',
        PASSWORD => $password
      });

      if ($result) {
        $PARAMS{LOGIN}   = $login;
        $PARAMS{EXTERNAL_AUTH} = 'ldap';
      }
      else {
        $admin->{errno} = 5;
        return 2;
      }
    }
    elsif($attr->{API_KEY}
        || ($conf{US_API} && $attr->{key})) {
      $PARAMS{API_KEY}   = $attr->{API_KEY} || $attr->{key} || q{123};
    }
    else {
      $PARAMS{LOGIN}   = $login;
      $PARAMS{PASSWORD}= $password;
    }
  }

  $admin->info($admin->{AID}, \%PARAMS);

  if ($admin->{errno}) {
    if ($admin->{errno} == 4) {
      if($conf{HIDE_WRONG_PASSWORD}) {
        $password = '****';
      }
      $admin->system_action_add("$login:$password", { TYPE => 11 });
      $admin->{errno} = 4;
    }
    elsif ($admin->{errno} == 2) {
      return 2;
    }

    return 1;
  }
  elsif ($admin->{DISABLE} == 1) {
    $admin->{errno}  = 2;
    $admin->{errstr} = 'DISABLED';
    return 2;
  }

  if ($admin->{WEB_OPTIONS}) {
    my @WO_ARR = split(/;/, $admin->{WEB_OPTIONS});
    foreach my $line (@WO_ARR) {
      my ($k, $v) = split(/=/, $line);
      next if(! $k);
      $admin->{SETTINGS}{$k} = $v;

      if ($html)  {
        if($k eq 'language' && $attr->{language}) {
          $v = $attr->{language};
        }
        $html->{$k}=$v;
      }
    }

    if($admin->{SETTINGS}{PAGE_ROWS} ) {
      $PAGE_ROWS = $FORM{PAGE_ROWS} || $admin->{SETTINGS}{PAGE_ROWS};
      $LIST_PARAMS{PAGE_ROWS}=$PAGE_ROWS;
    }
  }

  if ($admin->{ADMIN_ACCESS}) {
    my $list = $admin->access_list({
      AID       => $admin->{AID},
      DISABLE   => 0,
      COLS_NAME => 1
    });

    my $deny = ($admin->{TOTAL}) ? 1 : 0;
    foreach my $line (@$list) {
      my $time       = $TIME;
      $time          =~ s/://g;
      $line->{begin} =~ s/://g;
      $line->{end}   =~ s/://g;
      my $wday = (localtime(time))[6];

      if ((! $line->{day} || $wday+1 == $line->{day})
        && $time > $line->{begin} && $time < $line->{end}) {
        if (check_ip($ENV{REMOTE_ADDR}, "$line->{ip}/$line->{bit_mask}")) {
          $deny = 0;
          last;
        }
      }
    }

    if ($deny) {
      $admin->{MODULE}='';
      $admin->system_action_add("DENY IP: $ENV{REMOTE_ADDR}", { TYPE => 50 });
      return 6;
    }
  }

  %permissions = %{ $admin->get_permissions() };

  if($permissions{0} && $permissions{0}{17}) {
    $html->{EXPORT_LIST}=1;
  }
  if (defined($permissions{4}) && $permissions{4}{7}) {
    $html->{CHANGE_TPLS}=1;
  }

  #if (! $admin->{SID} && ! $attr->{API_KEY}) {
  if (! $admin->{SID}) {
    $admin->{SID} = mk_unique_value(14);
  }

  return 0;
}

#**********************************************************
=head2 auth_user($user_name, $password, $session_id, $attr)

=cut
#**********************************************************
sub auth_user {
  my ($login, $password, $session_id, $attr) = @_;

  if($attr->{USER}) {
    $user = $attr->{USER};
  }

  my $ret                  = 0;
  my $res                  = 0;
  my $REMOTE_ADDR          = $ENV{'REMOTE_ADDR'} || '';
  my $uid                  = 0;
  require Abills::Auth::Core;
  Abills::Auth::Core->import();

  my $Auth;
  if($FORM{external_auth}) {
    $Auth = Abills::Auth::Core->new({
      CONF      => \%conf,
      AUTH_TYPE => $FORM{external_auth},
      USERNAME  => $login,
      SELF_URL  => $SELF_URL
    });

    $Auth->check_access(\%FORM);

    if($Auth->{auth_url}) {
      print "Location: $Auth->{auth_url}\n\n";
      exit;
    }
    elsif($Auth->{USER_ID}) {
      $user->list({
        $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
        LOGIN                => '_SHOW',
        COLS_NAME            => 1
      });

      if($user->{TOTAL}) {
        $uid = $user->{list}->[0]->{uid};
        $user->{LOGIN} = $user->{list}->[0]->{login};
        $user->{UID} = $uid;
        $res = $uid;
      }
      else {
        if(! $sid) {
          $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message( 'err', $lang{ERROR}, $lang{ERR_UNKNOWN_SN_ACCOUNT}, {OUTPUT2RETURN => 1});
          return 0;
        }
      }
    }
    else {
      $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message('err', $lang{ERROR}, $lang{ERR_SN_ERROR}, {OUTPUT2RETURN => 1});
      return 0;
    }
  }

  if (!$conf{PASSWORDLESS_ACCESS}) {
    if($ENV{USER_CHECK_DEPOSIT}) {
      $conf{PASSWORDLESS_ACCESS} = $ENV{USER_CHECK_DEPOSIT};
    }
    elsif($attr->{PASSWORDLESS_ACCESS}) {
      $conf{PASSWORDLESS_ACCESS}=1;
    }
  }

  #Passwordless Access
  if ($conf{PASSWORDLESS_ACCESS}) {
    ($ret, $session_id, $login) = passwordless_access($REMOTE_ADDR, $session_id, $login,
      { PASSWORDLESS_GUEST_ACCESS => $conf{PASSWORDLESS_GUEST_ACCESS} });

    if($ret) {
      return ($ret, $session_id, $login);
    }
  }

  if ($index == 1000) {
    $user->web_session_del({ SID => $session_id });
    return 0;
  }
  elsif ($session_id) {
    $user->web_session_info({ SID => $session_id });

    if ($user->{TOTAL} < 1) {
      delete $FORM{REFERER};
      #$html->message('err', "$lang{ERROR}", "$lang{NOT_LOGINED}");
      #return 0;
    }
    elsif ($user->{errno}) {
      $html->message( 'err', $lang{ERROR} );
    }
    elsif ( $conf{web_session_timeout} < $user->{SESSION_TIME} ){
      $html->message( 'info', "$lang{INFO}", 'Session Expire' );
      $user->web_session_del({ SID => $session_id });
      return 0;
    }
    elsif ($user->{REMOTE_ADDR} ne $REMOTE_ADDR) {
      $html->message( 'err', "$lang{ERROR}", 'WRONG IP' );
      $user->web_session_del({ SID => $session_id });
      return 0;
    }
    else {
      $user->info($user->{UID}, { USERS_AUTH => 1 });
      $admin->{DOMAIN_ID}=$user->{DOMAIN_ID};
      $user->web_session_update({ SID => $session_id });
      #Add social id
      if ($Auth->{USER_ID}) {
        $user->pi_change( {
          $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
          UID                  => $user->{UID}
        } );
      }

      return ($user->{UID}, $session_id, $user->{LOGIN});
    }
  }

  if ($login && $password) {
    if ($conf{wi_bruteforce}) {
      $user->bruteforce_list(
        {
          LOGIN    => $login,
          PASSWORD => $password,
          CHECK    => 1
        }
      );

      if ($user->{TOTAL} > $conf{wi_bruteforce}) {
        $OUTPUT{BODY} = $html->tpl_show(templates('form_bruteforce_message'), undef);
        return 0;
      }
    }

    #check password from RADIUS SERVER if defined $conf{check_access}
    if ($conf{check_access}) {
      $Auth = Abills::Auth::Core->new({
        CONF      => \%conf,
        AUTH_TYPE => 'Radius'});

      $res = $Auth->check_access({
        LOGIN    => $login,
        PASSWORD => $password
      });
    }
    #check password direct from SQL
    else {
      $res = auth_sql($login, $password) if ($res < 1);
    }
  }
  elsif ($login && !$password) {
    $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message( 'err', $lang{ERROR}, $lang{ERR_WRONG_PASSWD}, {OUTPUT2RETURN => 1} );
  }

  #Get user ip
  if (defined($res) && $res > 0) {
    $user->info($user->{UID} || 0, {
        LOGIN     => ($user->{UID}) ? undef : $login,
        DOMAIN_ID => $FORM{DOMAIN_ID}
      });

    if ($user->{TOTAL} > 0) {
      $session_id          = mk_unique_value(16);
      $ret                 = $user->{UID};
      $user->{REMOTE_ADDR} = $REMOTE_ADDR;
      $admin->{DOMAIN_ID}  = $user->{DOMAIN_ID};
      $login               = $user->{LOGIN};
      $user->web_session_add(
        {
          UID         => $user->{UID},
          SID         => $session_id,
          LOGIN       => $login,
          REMOTE_ADDR => $REMOTE_ADDR,
          EXT_INFO    => $ENV{HTTP_USER_AGENT},
          COORDX      => $FORM{coord_x} || '',
          COORDY      => $FORM{coord_y} || ''
        }
      );
    }
    else {
      $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message( 'err', $lang{ERROR}, $lang{ERR_WRONG_PASSWD}, {OUTPUT2RETURN => 1} );
    }
  }
  else {
    if ($login || $password) {
      $user->bruteforce_add(
        {
          LOGIN       => $login,
          PASSWORD    => $password,
          REMOTE_ADDR => $REMOTE_ADDR,
          AUTH_STATE  => $ret
        }
      );

      $OUTPUT{MESSAGE} = $html->message( 'err', $lang{ERROR}, $lang{ERR_WRONG_PASSWD},
        { OUTPUT2RETURN => 1 } );
    }
    $ret = 0;
  }

  #Vacations only part
  if (in_array('Vacations', \@MODULES) ) {
    load_module('Vacations');
    my $Vacations = Vacations->new($db, $admin, \%conf);
    if ($ret) {
      $Vacations->vacation_log_add({
        IP       => $REMOTE_ADDR,
        EMAIL    => $login,
        COMMENTS => "Success login",
      });
    }
    else {
      $Vacations->vacation_log_add({
        IP       => $REMOTE_ADDR,
        EMAIL    => $login,
        COMMENTS => "Wrong password",
      });
    }
  }

  return ($ret, $session_id, $login);
}

#**********************************************************
=head2 passwordless_access($remote_addr, $session_id, $login, $attr) - Get passwordless access info

   Arguments:
     $remote_addr
     $session_id
     $login
     $attr
       PASSWORDLESS_GUEST_ACCESS

   Return:
     $uid, $session_id, $login

=cut
#**********************************************************
sub passwordless_access {
  my ($remote_addr, $session_id, $login, $attr) = @_;
  my ($ret);

  my $Sessions;

  if (in_array('Internet', \@MODULES)) {
    require Internet::Sessions;
    Internet::Sessions->import();
    $Sessions = Internet::Sessions->new($db, $admin, \%conf);
  }
  else {
    require Dv_Sessions;
    Dv_Sessions->import();
    $Sessions = Dv_Sessions->new($db, $admin, \%conf);
  }

  my %params = ();

  if($attr->{PASSWORDLESS_GUEST_ACCESS}) {
    $params{GUEST} = 1;
    if($attr->{PASSWORDLESS_GUEST_ACCESS} ne '1') {
      $params{SERVICE_STATUS} = $attr->{PASSWORDLESS_GUEST_ACCESS};
      $params{INTERNET_STATUS}= $attr->{PASSWORDLESS_GUEST_ACCESS};
      delete $conf{PASSWORDLESS_ACCESS};
    }
  }

  my $list = $Sessions->online({
    USER_NAME         => '_SHOW',
    FRAMED_IP_ADDRESS => $remote_addr,
    %params
  });

  if ($Sessions->{TOTAL} == 1) {
    $login     = $list->[0]->{user_name} || $login;
    $ret       = $list->[0]->{uid};
    $session_id= mk_unique_value(14);
    $user->info($ret);

    $user->{REMOTE_ADDR} = $remote_addr;
    $user->web_session_add({
      UID         => $ret,
      SID         => $session_id,
      LOGIN       => $login,
      REMOTE_ADDR => $remote_addr,
      EXT_INFO    => $ENV{HTTP_USER_AGENT},
      COORDX      => $FORM{coord_x} || '',
      COORDY      => $FORM{coord_y} || ''
    });

    return ($ret, $session_id, $login);
  }
  else {
    my $Internet;
    if (in_array('Internet', \@MODULES)) {
      require Internet;
      Internet->import();
      $Internet = Internet->new($db, $admin, \%conf);
    }
    else {
      require Dv;
      Dv->import();
      $Internet = Dv->new($db, $admin, \%conf);
    }

    my $internet_list = $Internet->list({
      IP        => $remote_addr,
      %params,
      LOGIN     => '_SHOW',
      COLS_NAME => 1
    });

    if ($Internet->{TOTAL} && $Internet->{TOTAL} == 1) {
      $login     = $internet_list->[0]->{login} || $login;
      $ret       = $internet_list->[0]->{uid} || 0;
      $session_id= mk_unique_value(14);
      $user->info($ret);
      $user->{REMOTE_ADDR} = $remote_addr;
      return ($ret, $session_id, $user->{LOGIN});
    }
  }

  return ($ret, $session_id, $login);
}

#**********************************************************
=head2 auth_sql($login, $password) - Authentification from SQL DB

=cut
#**********************************************************
sub auth_sql {
  my ($user_name, $password) = @_;
  my $ret = 0;

  $conf{WEB_AUTH_KEY}='LOGIN' if(! $conf{WEB_AUTH_KEY});

  if ($conf{WEB_AUTH_KEY} eq 'LOGIN') {
    $user->info(0, {
        LOGIN      => $user_name,
        PASSWORD   => $password,
        DOMAIN_ID  => $FORM{DOMAIN_ID} || 0,
        USERS_AUTH => 1
      });
  }
  else {
    my @a_method = split(/,/, $conf{WEB_AUTH_KEY});
    foreach my $auth_param (@a_method) {
      $user->list({
        $auth_param => $user_name,
        PASSWORD    => $password,
        DOMAIN_ID   => $FORM{DOMAIN_ID} || 0,
        COLS_NAME   => 1
      });

      if ($user->{TOTAL}) {
        $user->info($user->{list}->[0]->{uid});
        last;
      }
    }
  }

  if ($user->{TOTAL} < 1) {
    $OUTPUT{LOGIN_ERROR_MESSAGE} = $html->message( 'err', "$lang{ERROR}", "$lang{ERR_WRONG_PASSWD}", {OUTPUT2RETURN => 1} ) if (! $conf{PORTAL_START_PAGE});
  }
  elsif (_error_show($user)) {
  }
  else {
    $ret = $user->{UID} || $user->{list}->[0]->{uid};
  }

  $admin->{DOMAIN_ID}=$user->{DOMAIN_ID};

  return $ret;
}



1;