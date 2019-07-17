#!/usr/bin/perl

=head1 NAME

  ABillS Hotspot start page

  Error ID: 15xx

=cut

BEGIN {
  our $libpath = '../';
  our $sql_type = 'mysql';
  unshift( @INC,
    $libpath . "Abills/$sql_type/",
    $libpath . 'lib/',
    $libpath . 'Abills/modules/');

  eval { require Time::HiRes; };
  our $begin_time = 0;
  if ( !$@ ){
    Time::HiRes->import( qw(gettimeofday) );
    $begin_time = Time::HiRes::gettimeofday();
  }
}

our(
  $base_dir,
  %LANG,
  %lang,
  $Cards,
);

do "../libexec/config.pl";
use strict;
use warnings;
use Abills::Defs;
use Abills::Base;
use Users;
use Nas;
use Admins;
use Dv;
use Tariffs;
use Conf;
use Log;

$conf{base_dir} = $base_dir if (!$conf{base_dir});

require Abills::Templates;
require Abills::Misc;

our $html = Abills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
    METATAGS => templates( 'metatags' ),
    COLORS   => $conf{UI_COLORS},
    STYLE    => 'default_adm',
  }
);

our $VERSION = '0.23';
#Revision

my $sql = Abills::SQL->connect( $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef } );
our $db = ($conf{VERSION} && $conf{VERSION} < 0.70) ? $sql->{db} : $sql;

if ( $conf{LANGS} ){
  $conf{LANGS} =~ s/\n//g;
  my (@lang_arr) = split( /;/, $conf{LANGS} );
  %LANG = ();
  foreach my $l ( @lang_arr ){
    my ($lang, $lang_name) = split( /:/, $l );
    $lang =~ s/^\s+//;
    $LANG{$lang} = $lang_name;
  }
}

#$html->{language} = $FORM{language} if (defined( $FORM{language} ) && $FORM{language} =~ /^[a-z_]+$/);
$html->{show_header} = 1;

do "../language/english.pl";
do "../language/$html->{language}.pl";
$sid = $FORM{sid} || '';    # Session ID
$lang{MINUTES}='Mins';

my $PHONE_PREFIX     = $conf{DEFAULT_PHONE_PREFIX} || '';
my $auth_cookie_time = $conf{AUTH_COOKIE_TIME} || 86400;

if ( $ENV{REQUEST_URI} ){
  my $cookies_time = gmtime( time() + $auth_cookie_time ) . " GMT";
  $html->set_cookies( 'hotspot_userurl', "http://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/$ENV{REQUEST_URI}", "$cookies_time"
    , $html->{web_path} );
}

#cookie section ============================================
#Operation system ID
#$html->set_cookies( 'OP_SID', "$FORM{OP_SID}", "Fri, 1-Jan-2038 00:00:01",
#  $html->{web_path} ) if (defined( $FORM{OP_SID} ));

if ( $FORM{sid} ){
  $html->set_cookies( 'sid', "$FORM{sid}", "Fri, 1-Jan-2038 00:00:01", $html->{web_path} );
}

#===========================================================

our $admin = Admins->new( $db, \%conf );
$admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => $ENV{REMOTE_ADDR} } );
my $Conf = Conf->new($db, $admin, \%conf);

#my $uid = 0;
my %OUTPUT = ();
my %INFO_HASH = ();
our $CONTENT_LANGUAGE = '';
our $DOMAIN_ID = 0;
our $users = Users->new( $db, $admin, \%conf );
our $Dv = Dv->new( $db, $admin, \%conf );
my $Log = Log->new($db, \%conf);
$user = $users;

if ( $FORM{DOMAIN_ID} ){
  $admin->info( $conf{SYSTEM_ADMIN_ID}, { DOMAIN_ID => $FORM{DOMAIN_ID} } );
  $DOMAIN_ID = $admin->{DOMAIN_ID} || $FORM{DOMAIN_ID};
  $html->{WEB_TITLE} = $admin->{DOMAIN_NAME};
  if($admin->{errno}) {
    print $html->header( { CONTENT_LANGUAGE => $CONTENT_LANGUAGE } );
    print "Unknown domain admin: $admin->{errno}";
    exit;
  }
}
else{
  if ( in_array( 'Multidoms', \@MODULES )  ){
    print $html->header( { CONTENT_LANGUAGE => $CONTENT_LANGUAGE } );
    print "Wrong domain id!!!";
    #exit;
  }
}

my $Nas = Nas->new( $db, \%conf, $admin );

my %PARAMS = ();
if ( $FORM{BUY_CARD} ){

}
elsif ( $FORM{NAS_ID} ){
  $PARAMS{NAS_ID} = $FORM{NAS_ID};
}
elsif ( $FORM{NAS_IP} ){
  $PARAMS{IP} = $FORM{NAS_IP};
}
else{
  $PARAMS{IP} = $ENV{REMOTE_ADDR};
}

$Nas->info( { %PARAMS } );

if ( $Nas->{TOTAL} > 0 ){
  $INFO_HASH{CITY} = $Nas->{CITY};
  $INFO_HASH{ADDRESS_STREET} = $Nas->{ADDRESS_STREET};
  $INFO_HASH{ADDRESS_BUILD} = $Nas->{ADDRESS_BUILD};
  $INFO_HASH{ADDRESS_FLAT} = $Nas->{ADDRESS_FLAT};
  $INFO_HASH{NAS_GID} = $Nas->{GID};
  $FORM{NAS_GID} = $Nas->{GID};
}

my $login_url = $conf{HOTSPOT_LOGIN_URL} || 'http://192.168.182.1:3990/prelogin?lang=' . $html->{language};
if($FORM{external_auth}) {
  #$FORM{external_auth} =
  form_social_nets();
  $FORM{GUEST_ACCOUNT}=1;
}

if ( $FORM{uamport} && $FORM{uamport} eq 'mikrotik' ){
  $login_url = 'http://192.168.182.1/login';
  #mikrotik_();
}
elsif ( $FORM{GUEST_ACCOUNT} ){
  get_hotspot_account();
}
elsif ( $FORM{PIN} ){
  check_card();
}
elsif ( $FORM{PAYMENT_SYSTEM} || $FORM{BUY_CARDS} ){
  $html->{OUTPUT} .= buy_cards();
}
elsif ( $FORM{hotspot_advert}){
  load_module('Hotspot', $html);
  hotspot_redirect($FORM{hotspot_advert}, $FORM{link_orig}, $FORM{username});
  exit;
}
else{
  print "Content-Type: text/html\n\n";
  
  $login_url = get_login_url();
  
  $INFO_HASH{PAGE_QS} = "language=$FORM{language}" if ($FORM{language});
  
  $INFO_HASH{SELL_POINTS} = $html->tpl_show( _include( 'multidoms_sell_points', 'Multidoms' ), \%OUTPUT,
    { OUTPUT2RETURN => 1 } );
  $INFO_HASH{CARDS_BUY} = buy_cards();

  $html->tpl_show(
    templates( 'form_client_hotspot_start' ),
    {
      DOMAIN_ID        => $DOMAIN_ID,
      DOMAIN_NAME      => $admin->{DOMAIN_NAME},
      CONTENT_LANGUAGE => $CONTENT_LANGUAGE,
      LOGIN_URL        => $login_url,
      LANG_LIST        => get_language_flags_list(\%LANG),
      LANG_CURRENT     => $html->{language},
      HTML_STYLE       => $html->{STYLE},
      SHOW_PAYSYS_BUY  => in_array('Paysys', \@MODULES),
      %INFO_HASH
    },
    { MAIN               => 1,
      SKIP_DEBUG_MARKERS => 1
    }
  );

  print $html->{OUTPUT};
  exit;
}


print $html->header( { CONTENT_LANGUAGE => $CONTENT_LANGUAGE } );
$OUTPUT{BODY} = $html->{OUTPUT};
print $html->tpl_show( templates( 'form_base' ), \%OUTPUT, { OUTPUT2RETURN => 1 } );

$html->test() if ($conf{debugmods} =~ /LOG_DEBUG/);

#**********************************************************
=head2 get_login_url($attr)


 http://10.5.50.1/login?fastlogin=true&login=test&password=123456

=cut
#**********************************************************
sub get_login_url{
  my ($attr) = @_;

  if ( $FORM{login_return_url} && $FORM{login_return_url} ne '' ){
    $login_url = urldecode($FORM{login_return_url});
#    $login_url =~ s/\{(\w+)\}/\%$1\%/g;
  }
  elsif ( $FORM{GUEST_ACCOUNT} && $conf{HOTSPOT_GUEST_LOGIN_URL}){
    $login_url = $conf{HOTSPOT_GUEST_LOGIN_URL};
  }
  elsif ( $conf{HOTSPOT_LOGIN_URL}){
    $login_url = $conf{HOTSPOT_LOGIN_URL};
  };

  if ( $FORM{LOGIN} ){
    $login_url =~ s/%LOGIN%/$FORM{LOGIN}/g;
  };
  if ( $FORM{PASSWORD} ){
    $login_url =~ s/%PASSWORD%/$FORM{PASSWORD}/g;
  };

  if ( defined $attr && $attr->{NAS_IP} ){
    $login_url =~ s/%NAS_IP%/$attr->{NAS_IP}/g;
  };

  if($FORM{UNIFI_SITENAME}) {
    $login_url =~ s/\%UNIFI_SITENAME\%/$FORM{UNIFI_SITENAME}/g;
  }

  return $login_url;
}

#**********************************************************
=head2 form_social_nets()

=cut
#**********************************************************
sub form_social_nets {

  use Abills::Auth::Core;
  my $Auth;

  if($FORM{external_auth}) {
    $Auth = Abills::Auth::Core->new({
      CONF      => \%conf,
      AUTH_TYPE => $FORM{external_auth},
      SELF_URL  => $SELF_URL,
      DOMAIN_ID => $DOMAIN_ID
    });

    $Auth->check_access(\%FORM);

    if($Auth->{auth_url}) {
      print "Location: $Auth->{auth_url}\n\n";
      exit;
    }
    elsif($Auth->{USER_ID}) {
      my $users_list = $users->list({
        $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
        LOGIN                => '_SHOW',
        PASSWORD             => '_SHOW',
        FIO                  => '_SHOW',
        COLS_NAME            => 1
      });

      if($users->{TOTAL}) {
        $users->{LOGIN} = $users_list->[0]->{login};
        $users->{UID}   = $users_list->[0]->{uid};
        $COOKIES{hotspot_username}=$users_list->[0]->{login};
        $COOKIES{hotspot_password}=$users_list->[0]->{password};

        mk_cookie({
          hotspot_username=> $COOKIES{hotspot_username},
          hotspot_password=> $COOKIES{hotspot_password},
        });
        return 1;
      }
      #For user registration
      else {
        $FORM{'3.'.$Auth->{CHECK_FIELD}} = $Auth->{USER_ID};
        #UID                  => $user->{UID}
        #print "Content-Type: text/html\n\n";
        #print "/ $Auth->{CHECK_FIELD} / $Auth->{USER_ID} //";
      }
    }
    else {
      $html->message('err', $lang{ERROR}, $lang{ERR_SN_ERROR}
          .' Start registration'."\n ID: "
          . ($Auth->{USER_ID} || q{})
          . (($Auth->{errno}) ? "\n Error: ".$Auth->{errstr} : '')
      );
      $FORM{external_auth_failed}=1;
    }
  }

  my %first_page = ();
  if ($conf{AUTH_VK_ID}) {
    $first_page{SOCIAL_AUTH_BLOCK} = $html->element( 'li',
      $html->button( '', "external_auth=Vk&DOMAIN_ID=$DOMAIN_ID", { class => 'icon-vk', ICON => 'fa fa-vk' } ),
      { OUTPUT2RETURN => 1 }
    )
  }

  if ($conf{AUTH_FACEBOOK_ID}) {
    $first_page{SOCIAL_AUTH_BLOCK} .= $html->element( 'li',
      $html->button( '', "external_auth=Facebook&DOMAIN_ID=$DOMAIN_ID", { class => 'icon-facebook', ICON => 'fa fa-facebook' } ),
      { OUTPUT2RETURN => 1 }
    );
  }

  if ($conf{AUTH_GOOGLE_ID}) {
    $first_page{SOCIAL_AUTH_BLOCK} .= $html->element( 'li',
      $html->button( '', "external_auth=Google&DOMAIN_ID=$DOMAIN_ID", { class => 'icon-google', ICON => 'fa fa-google' } ),
      { OUTPUT2RETURN => 1 }
    );
  }

  if ($conf{AUTH_INSTAGRAM_ID}) {
    $first_page{SOCIAL_AUTH_BLOCK} .= $html->element( 'li',
      $html->button( '', "external_auth=Instagram&DOMAIN_ID=$DOMAIN_ID", { class => 'icon-instagram', ICON => 'fa fa-instagram' } ),
      { OUTPUT2RETURN => 1 }
    );
  }

  $OUTPUT{BODY} = $html->tpl_show(templates('form_ext_auth'),
    \%first_page,
    { MAIN => 1,
      ID   => 'form_client_login'
    });

  return 1;
}

#**********************************************************
=head2 get_hotspot_account()

=cut
#**********************************************************
sub get_hotspot_account{

  my $Tariffs = Tariffs->new( $db, \%conf, $admin );

  load_module( 'Dv', $html );
  load_module( 'Cards', $html );

  if ($FORM{external_auth_failed}) {
    return 0;
  }

  my $extra_auth = 1;
  my $nas_id     = $FORM{NAS_ID} || '';

  $login_url = get_login_url();
  if ($FORM{PIN}) {
    my $login = $FORM{LOGIN} || q{};
    my $pin   = $FORM{PIN} || q{};
    cards_card_info({ INFO_ONLY => 1 });

    if($login eq $FORM{LOGIN} && $pin eq $FORM{PASSWORD}) {
      $login_url = get_login_url();
      print "Location: $login_url\n\n";
      exit;
    }
    else {
      $html->message( 'info', "$lang{GUEST_ACCOUNT}", "Wrong pin\n$lang{USER}: '$COOKIES{hotspot_username}'" );
      $html->tpl_show( templates( 'form_client_hotspot_pin' ),
        { %FORM });

      return 0;
    }
  }
  elsif ( $COOKIES{hotspot_username} ){
    $html->message( 'info', "$lang{GUEST_ACCOUNT}", "$lang{USER} : '$COOKIES{hotspot_username}' ");
    if ( $conf{HOTSPOT_CHECK_PHONE} ){
      $extra_auth = cards_card_info( {
        PIN         => $COOKIES{hotspot_password},
        FOOTER_TEXT => $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
          { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ),
        HEADER_TEXT => $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
          { class => 'btn btn-default btn-xs' } ),
        INFO_ONLY => 1,
        UID       => $users->{UID}
        } );

      if($extra_auth) {
        $html->tpl_show( templates( 'form_client_hotspot_pin' ), { %FORM } );
      }
    }
    else {
      $extra_auth = cards_card_info({
        PIN         => $COOKIES{hotspot_password},
        FOOTER_TEXT => $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
          { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ),
        HEADER_TEXT =>
          $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
            { class => 'btn btn-default btn-xs' } ),
        UID         => $users->{UID}
      });
    }

    if ($extra_auth) {
      return 1;
    }
    else {
      $extra_auth = 1;
#      mk_cookie({
#        hotspot_username=> '',
#        hotspot_password=> '',
#        hotspot_card_id => '',
#      });

      delete $COOKIES{qw(hotspot_username hotspot_password hotspot_card_id)};

      $html->message( 'warn', "$lang{GUEST_ACCOUNT}", "$lang{DELETED}");
    }
  }
  elsif ( $FORM{mac} ){
    my $list = $Dv->list({
      #DATE => $DATE,
      PASSWORD  => '_SHOW',
      CID       => $FORM{mac},
      COLS_NAME => 1,
    });

    if ( $Dv->{TOTAL} == 1 ){
      cards_card_info({
        PIN         => "$list->[0]->{PASSOWRD}",
        FOOTER_TEXT => $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
          { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ),
        HEADER_TEXT => $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
          { class => 'btn btn-default btn-xs' } )
      });

      return 0;
    }
  }
  else{
    #    my $a = `echo "$DATE $TIME Can't find MAC: $FORM{mac} // $COOKIES{hotspot_user_id}" >> /tmp/mac_test`;
  }

  my $tp_list = $Tariffs->list({
    PAGE_ROWS    => 1,
    SORT         => 1,
    NAME         => '_SHOW',
    DOMAIN_ID    => $DOMAIN_ID,
    PAYMENT_TYPE => 2,
    COLS_NAME    => 1,
    NEW_MODEL_TP => 1,
  });

  if ( $Dv->{TOTAL} ){
    $html->message( 'info', "$lang{ERROR}", "Guest mode disable for mac '$FORM{mac}'", { } );
    $Log->log_print('LOG_ERR', $FORM{mac}, "Guest mode disable for mac '$FORM{mac}'", { NAS => $Nas });
    #    my $a = `echo "$DATE $TIME Guest mode disable: $FORM{mac} // $COOKIES{hotspot_user_id}" >> /tmp/mac_test`;
    return 0;
  }

  my $user_mac = $FORM{mac} || $COOKIES{hotspot_user_id} || '';
  #  my $a = `echo "REG GUEST: $DATE $TIME: $FORM{mac} COOKIES: $COOKIES{hotspot_user_id} user_mac: $user_mac" >> /tmp/mac_test`;

  if ( $Tariffs->{TOTAL} < 1 ){
    $html->message( 'info', "$lang{INFO}", "$lang{GUEST_ACCOUNT} $lang{DISABLE}", { } );
    $Log->log_print('LOG_ERR', $FORM{mac}, "$lang{GUEST_ACCOUNT} $lang{DISABLE}", { NAS => $Nas });
    return 0;
  }

  #Check SOCIAL_NETS for guest connection
  if ($conf{HOTSPOT_CHECK_SOCIAL_NETS}) {
    if (! $FORM{external_auth} && form_social_nets()) {
      $extra_auth = 0;
    }
  }

  #Check phone for guest connection
  if ( $conf{HOTSPOT_CHECK_PHONE} ){
    if($FORM{PIN}) {
      $extra_auth = 0;
    }
    elsif ( defined( $FORM{PHONE} )
      && (!$FORM{PHONE} || ($conf{PHONE_FORMAT} && $FORM{PHONE} !~ /$conf{PHONE_FORMAT}/ ))){
      _error_show({ errno => 21, err_str => 'ERR_WRONG_PHONE' }, { ID => 1505 });
    }

    if ( !$FORM{PHONE} ){
      $html->tpl_show( templates( 'form_client_hotspot_phone' ),
        { %FORM, PHONE_PREFIX => $PHONE_PREFIX },
      );
      $extra_auth = 0;
    }
    else {
      $extra_auth = 1;
      #Check register phone
      my $dv_list = $Dv->list({
        #DATE => $DATE,
        PASSWORD  => '_SHOW',
        CID       => '_SHOW',
        PHONE     => $FORM{PHONE},
        COLS_NAME => 1,
      });

      if ( $Dv->{TOTAL} == 1 ){
        $extra_auth = cards_card_info( {
          FOOTER_TEXT => $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
              { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ),
          HEADER_TEXT => $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
              { class => 'btn btn-default btn-xs' } ),
          INFO_ONLY => 1,
          UID       => $dv_list->[0]->{uid}
          } );

        if($extra_auth) {
          $html->tpl_show( templates( 'form_client_hotspot_pin' ), { %FORM } );
        }

        return 0;
      }
    }
  }

  if (! $extra_auth) {
    return 0;
  }

  foreach my $line ( @{$tp_list} ){
    $FORM{'TP_NAME'} = $line->{name};
    $FORM{'4.TP_ID'} = $line->{id};
  }

  $FORM{create} = 1;
  $FORM{COUNT}  = 1;
  $FORM{SERIAL} = 'G';
  my $return = cards_users_add( { NO_PRINT => 1 } );
  $FORM{add} = 1;

  if ( ref( $return ) eq 'ARRAY' ){
    foreach my $line ( @{$return} ){
      $FORM{'1.LOGIN'}       = $line->{LOGIN};
      $FORM{'1.PASSWORD'}    = $line->{PASSWORD};
      $FORM{'4.CID'}         = $user_mac;
      $FORM{'1.CREATE_BILL'} = 1;
      if ( $FORM{PHONE} ){
        $FORM{'3.PHONE'} = $PHONE_PREFIX . $FORM{PHONE};
      }

      $line->{UID} = dv_wizard_user( { SHORT_REPORT => 1 } );

      if ( $line->{UID} < 1 ){
        $html->message( 'err', "$lang{ERROR}", "$lang{LOGIN}: '$line->{LOGIN}'", { ID => 1506 } );

        last if (!$line->{SKIP_ERRORS});
      }
      else{
        #Confim card creation
        if ( cards_users_gen_confim( { %{$line}, SUM => ($FORM{'5.SUM'}) ? $FORM{'5.SUM'} : 0 } ) == 0 ){
          return 0;
        }

        #Sendsms
        if ( $FORM{PHONE} && in_array( 'Sms', \@MODULES ) ){
          load_module( 'Sms', $html );
          my $message = $html->tpl_show( _include( 'dv_reg_complete_sms', 'Dv' ), { %FORM, %{$line} },
            { OUTPUT2RETURN => 1 } );

          my $phone = $PHONE_PREFIX . $FORM{PHONE};

          my $sms_result = sms_send( {
            NUMBER     => $phone,
            MESSAGE    => $message,
            UID        => $line->{UID},
            RIZE_ERROR => 1,
          } );

          if ( !$sms_result ){
            $users->change( $line->{UID},
              { UID             => $line->{UID},
                DISABLE         => 1,
                ACTION_COMMENTS => 'Unknown phone',
            });

            $html->message( 'info', '',
              $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
                { BUTTON => 2 } ) );
            return 0;
          }
        }

        # 24 hours login
        mk_cookie({
          hotspot_username=> $line->{LOGIN},
          hotspot_password=> $line->{PASSWORD},
          hotspot_card_id => $line->{PASSWORD},
        });

        $login_url = get_login_url();
        #Send email
        if ( $FORM{EMAIL} ){
          my $message = $html->tpl_show( _include( 'dv_reg_complete_mail', 'Dv' ), { %FORM }, { OUTPUT2RETURN => 1 } );
          sendmail( "$conf{ADMIN_MAIL}", "$FORM{EMAIL}", "$lang{REGISTRATION}", "$message", "$conf{MAIL_CHARSET}", '' );
        }

        if ( $conf{HOTSPOT_CHECK_PHONE} ){
          cards_card_info( {
            SERIAL      => "$line->{SERIAL}".sprintf( "%.11d", $line->{NUMBER} ),
            FOOTER_TEXT => $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
              { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ),
            HEADER_TEXT => $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
              { class => 'btn btn-default btn-xs' } ),
            INFO_ONLY => 1
          } );

          $html->tpl_show( templates( 'form_client_hotspot_pin' ),
            { %FORM },
          );
        }
        else {
          cards_card_info( {
              SERIAL      => "$line->{SERIAL}".sprintf( "%.11d", $line->{NUMBER} ),
              UID         => $line->{UID},
              FOOTER_TEXT => $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
                { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ),
              HEADER_TEXT =>$html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$nas_id",
                { class => 'btn btn-default btn-xs' } )
            } );
        }
        #$html->{OUTPUT} .= $html->button($lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$FORM{DOMAIN_ID}&NAS_ID=$nas_id", { BUTTON => 1 }) . ' ' . $html->button($lang{LOGIN_IN_TO_HOTSPOT}, '', { GLOBAL_URL => "$login_url", BUTTON => 1 });
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 check_card()

=cut
#**********************************************************
sub check_card{
  load_module( 'Cards', $html );

  if ( $FORM{PIN} ){
    our $line;
    cards_card_info( { PIN => $FORM{PIN} } );

    my $buttons = '';

    if ( $FORM{LOGIN} ){
      mk_cookie({
        hotspot_username=> $FORM{LOGIN},
        hotspot_password=> $FORM{PASSWORD},
        hotspot_card_id => ($line->{PASSWORD}) ? $line->{PASSWORD} : undef,
      });

      $login_url = get_login_url();

      $buttons = $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$FORM{NAS_ID}",
        { BUTTON => 1 } )
        . ' ' . $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
        { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } );
    }
    else{
      $buttons = $html->button( $lang{RETURN_TO_START_PAGE},
        "$SELF_URL/start.cgi?DOMAIN_ID=$DOMAIN_ID&NAS_ID=$FORM{NAS_ID}", { BUTTON => 1 } );
    }

    $html->{OUTPUT} .= $buttons;
    return 0;
  }

  return 1;
}

#**********************************************************
=head2 mikrotik_($attr) Mikrotik

=cut
#**********************************************************
sub mikrotik_{
  #my ($attr) = @_;

  print << "[END]";
<form method="get" action="/hotspotlogin.cgi">
   <input name="chal" value="" type="HIDDEN">
   <input name="uamip" value="$FORM{uamip}" type="HIDDEN">
   <input name="uamport" value="mikrotik" type="HIDDEN">
   <input name="nasid" value="$FORM{nasid}" type="HIDDEN">
   <input name="mac" value="$FORM{mac}" type="HIDDEN">
   <input name="userurl" value="$FORM{userurl}" type="HIDDEN">
   <input name="login" value="login" type="HIDDEN">

   <input name="skin_id" id="skin_id" value="" type="hidden">
   <input name="uid" value="$FORM{mac_id}" type="hidden">
   <input name="pwd" value="password" type="hidden">
   <input name="submit" value="LOG IN TO HOTSPOT" class="formbutton" type="submit">
</form>
[END]

}

#**********************************************************
=head2 buy_cards($attr) - Buy cards

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub buy_cards{
  #my ($attr) = @_;

  my $Tariffs = Tariffs->new( $db, \%conf, $admin );
  $LIST_PARAMS{UID} = $FORM{UID};

  load_module( 'Paysys' );
  if ( $FORM{BUY_CARDS} || $FORM{PAYMENT_SYSTEM} ){
    if ( $FORM{PAYMENT_SYSTEM} && $conf{HOTSPOT_CHECK_PHONE} && !$FORM{PHONE} ){
      _error_show({ errno => 21, err_str => 'ERR_WRONG_PHONE' }, { ID => 1504 });
      $FORM{PAYMENT_SYSTEM_SELECTED} = $FORM{PAYMENT_SYSTEM};
      $FORM{PAYMENT_SYSTEM} = undef;
    }

    if ( $FORM{PAYMENT_SYSTEM} ){
      my $ret = paysys_payment( {
        OUTPUT2RETURN  => 1,
        QUITE          => 1,
        SUS_URL_PARAMS => ($FORM{UNIFI_SITENAME}) ? "&UNIFI_SITENAME=$FORM{UNIFI_SITENAME}" : q{},
        #RETURN_URL    => $ENV{PROT}.'://'. $ENV{SERVER_NAME}.':'. $ENV{SERVER_PORT} . '/start.cgi'
      } );

      $Tariffs->info( $FORM{TP_ID} );

      $FORM{'5.SUM'}      = $Tariffs->{ACTIV_PRICE} || $FORM{PAYSYS_SUM};
      $FORM{'5.DESCRIBE'} = ($FORM{SYSTEM_SHORT_NAME} || q{}) ."# $FORM{OPERATION_ID}";
      $FORM{'5.EXT_ID'}   = ($FORM{SYSTEM_SHORT_NAME} || q{}) .":$FORM{OPERATION_ID}";
      $FORM{'5.METHOD'}   = 2;
      $FORM{'3.EMAIL'}    = $FORM{EMAIL};

      if ( $FORM{TRUE} ){
        if ( $ret ){
          load_module( 'Dv', $html );
          load_module( 'Cards', $html );
          $FORM{'4.TP_ID'} = $Tariffs->{ID};

          $FORM{create} = 1;
          $FORM{COUNT} = 1;
          $FORM{SERIAL} = "$FORM{TP_ID}";
          my $return = cards_users_add( { NO_PRINT => 1 } );
          $FORM{add} = 1;

          if ( ref( $return ) eq 'ARRAY' ){
            foreach my $line ( @{$return} ){
              #password gen by Cards
              $FORM{'1.LOGIN'} = $FORM{OPERATION_ID};
              $FORM{'1.PASSWORD'} = $FORM{OPERATION_ID};
              $FORM{'1.CREATE_BILL'} = 1;
              $line->{UID} = dv_wizard_user( {
                SHORT_REPORT => 1,
                SHOW_USER    => 1
               } );

              if ( $line->{UID} < 1 ){
                $html->message( 'err', "$lang{ERROR}", "$lang{LOGIN}: '$FORM{OPERATION_ID}'", { ID => 1507 } );
                last if (!$line->{SKIP_ERRORS});
              }
              else{
                #Confim card creation
                if ( cards_users_gen_confim( { %{$line},
                    LOGIN    => $FORM{'1.LOGIN'},
                    PASSWORD => $FORM{'1.PASSWORD'},
                    PIN      => $FORM{'1.PASSWORD'},
                    SUM      => ($FORM{'5.SUM'}) ? $FORM{'5.SUM'} : 0 } ) == 0 ){
                  return 0;
                }

                # 24 hours login
                mk_cookie(
                  {
                    hotspot_username=> $line->{LOGIN},
                    hotspot_password=> $line->{PASSWORD},
                    hotspot_card_id => $line->{PASSWORD}
                  },
                  { COOKIE_TIME =>  gmtime( time() + $auth_cookie_time ) . " GMT" }
                );

                #Attach UID to payment
                if ( $FORM{PAYSYS_ID} ){
                  if ( form_purchase_module( {
                      HEADER => $user->{UID},
                      MODULE => 'Paysys',
                    } ) ){
                    exit;
                  }

                  my $Paysys = Paysys->new( $db, $admin, \%conf );
                  $Paysys->change({
                    ID => $FORM{PAYSYS_ID},
                    UID               => $line->{UID},
                    STATUS            => ($FORM{TRUE}) ? 2 : undef
                  });
                }

                $FORM{LOGIN} = $FORM{'1.LOGIN'};
                $FORM{PASSWORD} = $FORM{'1.PASSWORD'};

                #Sendsms
                if ( $FORM{PHONE} && in_array( 'Sms', \@MODULES ) ){
                  load_module( 'Sms', $html );

                  my $message = $html->tpl_show( _include( 'dv_reg_complete_sms', 'Dv' ),
                    { %{ ($Cards) ? $Cards : {} } , %FORM },
                    { OUTPUT2RETURN => 1 } );

                  sms_send({
                    NUMBER  => $FORM{PHONE},
                    MESSAGE => $message,
                    UID     => $line->{UID},
                  });
                }

                #Send email
                if ( $FORM{EMAIL} ){
                  my $message = $html->tpl_show( _include( 'dv_reg_complete_mail', 'Dv' ), { %FORM },
                    { OUTPUT2RETURN => 1 } );
                  sendmail( "$conf{ADMIN_MAIL}", "$FORM{EMAIL}", "$lang{REGISTRATION}", "$message", "$conf{MAIL_CHARSET}",
                    '' );
                }

                $login_url = get_login_url();
                cards_card_info( { #SERIAL => "$line->{SERIAL}" . sprintf("%.11d", $line->{NUMBER}),
                  ID => $FORM{CARD_ID},
                  FOOTER_TEXT => $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
                    { GLOBAL_URL => $login_url, class => 'btn btn-success btn-lg' } )
                } );


                #`echo "$DATE $TIME Login to hotspot MAC: $FORM{mac} / $COOKIES{hotspot_user_id} Card: $FORM{CARD_ID} Login: $user->{LOGIN}  UID: $line->{UID} ($login_url)" >> /tmp/mac_test`;
                #$html->{OUTPUT} .= '<center>' . $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
                #  { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ) . '</center>';
                #$html->button($lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$DOMAIN_ID&NAS_ID=$FORM{NAS_ID}",  { BUTTON => 1}).' '.
                return '';
              }
            }

          }

          return $ret;
        }
      }
      elsif ( $FORM{FALSE} ){
        $html->message( 'err', $lang{ERROR}, $html->button( $lang{ERR_TRY_AGAIN}, "$SELF_URL", { BUTTON => 1 } ), { ID => 1509 } );
      }

      return ($ret) ? $ret : '';
    }
    else{
      $INFO_HASH{UNIFI_SITENAME} = $FORM{UNIFI_SITENAME} if($FORM{UNIFI_SITENAME});

      $Tariffs->info( $FORM{TP_ID} );
      my $unique = mk_unique_value( 8, { SYMBOLS => '0123456789' } );
      return $html->tpl_show(
        templates( 'form_buy_cards_paysys' ),
        {
          %INFO_HASH,
          SUM               => $Tariffs->{ACTIV_PRICE},
          DESCRIBE          => '',
          OPERATION_ID      => $unique,
          UID               => "$unique:$DOMAIN_ID",
          TP_ID             => $FORM{TP_ID},
          DOMAIN_ID         => $DOMAIN_ID,
          PAYSYS_SYSTEM_SEL => paysys_system_sel( { PAYMENT_SYSTEM => $FORM{PAYMENT_SYSTEM_SELECTED} } )
        },
        { OUTPUT2RETURN => 1 }
      );
    }
  }

  if ( $conf{DV_REGISTRATION_TP_GIDS} ){
    $LIST_PARAMS{TP_GID} = $conf{DV_REGISTRATION_TP_GIDS};
  }
  #else {
  #  $LIST_PARAMS{TP_GID} = '>0';
  #}

  $LIST_PARAMS{DOMAIN_ID} = $DOMAIN_ID;

  my $list = $Tariffs->list(
    {
      PAYMENT_TYPE     => '<2',
      TOTAL_TIME_LIMIT => '_SHOW',
      TOTAL_TRAF_LIMIT => '_SHOW',
      ACTIV_PRICE      => '_SHOW',
      AGE              => '_SHOW',
      NAME             => '_SHOW',
      IN_SPEED         => '_SHOW',
      OUT_SPEED        => '_SHOW',
      %LIST_PARAMS,
      TP_ID            => $conf{HOTSPOT_TPS},
      MODULE           => 'Dv',
      COLS_NAME        => 1,
    }
  );

  foreach my $line ( @{$list} ){
#    my $ti_list = $Tariffs->ti_list( { TP_ID => $line->{tp_id} } );
#    if ( $Tariffs->{TOTAL} > 0 ){
#      $Tariffs->ti_info( $ti_list->[0]->[0] );
#      if ( $Tariffs->{TOTAL} > 0 ){
#        $Tariffs->tt_info( { TI_ID => $ti_list->[0]->[0], TT_ID => 0 } );
#      }
#    }

    $INFO_HASH{CARDS_TYPE} .= $html->tpl_show(
      templates( 'form_buy_cards_card' ),
      {
        TP_NAME         => $line->{name},
        ID              => $line->{id},
        TP_ID           => $line->{tp_id},
        AGE             => $line->{age} || $lang{UNLIM},
        DOMAIN_ID       => $DOMAIN_ID,
        SPEED_IN        => $line->{in_speed} || $lang{UNLIM},
        SPEED_OUT       => $line->{out_speed} || $lang{UNLIM},
        PREPAID_MINS    => ($line->{total_time_limit}) ? sprintf("%.1f", $line->{total_time_limit} / 60 / 60) : $lang{UNLIM},
        PREPAID_TRAFFIC => $line->{total_traf_limit} || $lang{UNLIM},
        PRICE           => $line->{activate_price} || 0.00,
        UNIFI_SITENAME  => ($FORM{UNIFI_SITENAME}) ? "&UNIFI_SITENAME=$FORM{UNIFI_SITENAME}" : q{}
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  return $html->tpl_show( templates( 'form_buy_cards' ), { %INFO_HASH }, { OUTPUT2RETURN => 1 } );
}

#**********************************************************
=head2 mk_cookie($cookie_hash, $attr) - Make cookie

  Arguments:
    $cookie_vals - Cookie pairs
    $attr
       COOKIE_TIME

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub mk_cookie {
  my($cookie_vals, $attr)=@_;

  if ($conf{HOTSPOT_DEBUG}) {
    return 1;
  }

  my $cookies_time = ($attr->{COOKIE_TIME}) ? $attr->{COOKIE_TIME} : gmtime( time() + $auth_cookie_time ) . " GMT";
  foreach my $key (keys %$cookie_vals) {
    $html->set_cookies( $key, $cookie_vals->{$key}, $cookies_time, $html->{web_path} );
  }

  return 1;
}

#**********************************************************
=head2 get_language_flags_list(\%LANG)

=cut
#**********************************************************
sub get_language_flags_list {
  my ($languages) = @_;
  my $result = '';
  my $href_base = "$SELF_URL?&NAS_ID=" . ($FORM{NAS_ID} || '') . "&DOMAIN_ID=" . ($FORM{DOMAIN_ID} || '');
  
  for my $name (sort keys %$languages){
    my $short_name = uc(substr($name, 0, 2));
    $result .= qq{
      <li>
        <a href="$href_base&language=$name"><img src='/styles/default_adm/img/flags/$name.png' alt='$name'/>&nbsp;$short_name</a>
      </li>
    }
  }

  return $result;
}

1
