#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

BEGIN {
  our $Bin;
  use FindBin '$Bin';
  if ($Bin =~ m/\/abills(\/)/) {
    our $libpath = substr($Bin, 0, $-[1]);
    unshift(@INC, "$libpath/lib");
  }
  else {
    die " Should be inside /usr/abills dir \n";
  }
}

our (
  %lang,
);

use Abills::Init qw/$db $admin %conf/;
use Abills::Defs;
use Abills::HTML;
use Abills::Base qw(_bp);
use POSIX qw(strftime);
use Log qw(log_add log_print);
use Iptv;
use Abills::Sender::Core;
use Iptv;
require Abills::Misc;
require Iptv::User_portal;

our $DATE = strftime("%Y-%m-%d", localtime(time));
our $TIME = strftime("%H:%M:%S", localtime(time));

our $html = Abills::HTML->new(
  {
    CONF     => \%conf,
    NO_PRINT => 0,
    PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
    CHARSET  => $conf{default_charset},
    LANG     => \%lang,
  }
);

if ($html->{language} ne 'english') {
  do $libpath . "/language/english.pl";
}

if (-f $libpath . "/language/$html->{language}.pl") {
  do $libpath . "/language/$html->{language}.pl";
}

my $Iptv = Iptv->new($db, $admin, \%conf);
my $Log = Log->new($db, \%conf);

if ($FORM{type}) {
  print "Content-type:text/html\n\n";
  if ($FORM{type} eq 'user') {
    check_user(\%FORM);
  }
  elsif ($FORM{type} eq 'tp') {
    show_user_tp(\%FORM);
  }
  exit;
}

#SmartUp Start

if ($FORM{action} && $FORM{duid} && $FORM{ip}) {
  print "Content-type:text/html\n\n";
  if (($FORM{action} eq "login") || ($FORM{action} eq "confirm") && $FORM{phone}) {
    smartup_activation();
  }
  elsif ($FORM{action} eq "verify") {
    smartup_activation();
  }
  elsif ($FORM{action} eq "info") {
    smartup_activation();
  }
  elsif ($FORM{action} eq "pin") {
    if ($FORM{set}) {
      smartup_pin({ ACTION => "set" });
    }
    else {
      smartup_pin({ ACTION => "pin" });
    }
  }
  exit;
}

#SmartUp End

if ($conf{IPTV_PASSWORDLESS_ACCESS} && $ENV{REMOTE_ADDR}) {

  my $iptv_online = $Iptv->online(
    {
      FRAMED_IP_ADDRESS => $ENV{REMOTE_ADDR},
      TP_ID             => '_SHOW',
      COLS_NAME         => 1,
      PAGE_ROWS         => 1,
    }
  );
  _error_show($Iptv);

  if (!$iptv_online || ref $iptv_online ne 'ARRAY' && !scalar(@$iptv_online) || !$iptv_online->[0]->{tp_id}) {
    print "Content-type:text/html\n\n";
    print $html->element('h3', 'WARNING') . $html->element('p', 'This address ' . $ENV{REMOTE_ADDR} . ' is not connected to the TP');
    $Log->log_print('LOG_WARNING', '', 'Address ' . $ENV{REMOTE_ADDR} . ' not connected to the TP', { ACTION => 'AUTH' });
    exit;
  }
  else {
    $FORM{m3u_download} = 1;
    iptv_m3u($iptv_online->[0]->{tp_id});
  }
  exit;
}

#Folclor
if ($FORM{ip} || $FORM{phone} || $FORM{mbr_id}) {
  print "Content-type:text/html\n\n";
  check_user(\%FORM);
  exit;
}

if ($FORM{user_id} || $FORM{sum} || $FORM{cont_id} || $FORM{trf_id} || $FORM{message} || $FORM{start}) {
  print "Content-type:text/html\n\n";
  transfer_service(\%FORM);
  exit;
}

if (!$FORM{mac} && !$FORM{pin}) {
  print "Content-type:text/html\n\n";
  print $html->element('h3', 'WARNING') . $html->element('p', 'No mac or pin specified. No user found');
  exit;
}

mac_pin_auth();


#**********************************************************
=head2 mac_pin_auth($attr) - Mac PIN Auth

  Arguments:

  Returns:

  Example:
    check_user(/%FORM);

=cut
#**********************************************************
sub mac_pin_auth {

  if ($FORM{mac}) {
    $FORM{mac} =~ s/_SHOW//;
    $FORM{mac} =~ s/\*//;
  }

  if ($FORM{pin}) {
    $FORM{pin} =~ s/_SHOW//;
    $FORM{pin} =~ s/\*//;
  }

  my $iptv_list = $Iptv->user_list(
    {
      CID            => $FORM{mac},
      PIN            => $FORM{pin},
      SERVICE_STATUS => '_SHOW',
      LOGIN          => '_SHOW',
      TP_ID          => '_SHOW',
      DEPOSIT        => '_SHOW',
      CREDIT         => '_SHOW',
      COLS_NAME      => 1,
      PAGE_ROWS      => 1,
    }
  );
  _error_show($Iptv);

  if (!$iptv_list || ref $iptv_list ne 'ARRAY' && !scalar(@$iptv_list)) {
    print "Content-type:text/html\n\n";
    if ($FORM{mac}) {
      print $html->element('h3', 'WARNING') . $html->element('p', 'Wrong CID:' . $FORM{mac} . '. No user found');
      $Log->log_print('LOG_WARNING', '', "Wrong CID: $FORM{mac}. No user found", { ACTION => 'AUTH' });
    }
    elsif ($FORM{pin}) {
      print $html->element('h3', 'WARNING') . $html->element('p', 'Wrong PIN:' . $FORM{pin} . '. No user found');
      $Log->log_print('LOG_WARNING', '', "Wrong PIN: $FORM{pin}. No user found", { ACTION => 'AUTH' });
    }
    exit 0;
  }

  my $service = $iptv_list->[0];
  if (!$service->{login} || !$service->{tp_id}) {
    print "Content-type:text/html\n\n";
    print $html->element('h3', 'WARNING') . $html->element('p',
      'TP_ID:' . $service->{tp_id} . '. No activated service');
    $Log->log_print('LOG_WARNING', $service->{login},
      "TP_ID: $service->{tp_id}. No activated service", { ACTION => 'AUTH' });
  }

  # service_status 1 means it is disabled
  if ($service->{service_status}) {
    $Log->log_print('LOG_WARNING', $service->{login},
      "SERVICE_STATUS: $service->{service_status}. No activated service. ", { ACTION => 'AUTH' });
  }
  if (($service->{deposit} + $service->{credit}) <= 0) {
    $Log->log_print('LOG_WARNING', $service->{login},
      "DEPOSIT: $service->{deposit}. Too small deposit. ", { ACTION => 'AUTH' });
  }
  else {
    $FORM{m3u_download} = 1;
    iptv_m3u($service->{tp_id});
  }

  return 1;
}

#**********************************************************
=head2 check_user($attr) - search uid by ip or uid

  Arguments:
    $attr{ip}  - user ip
    $attr{uid} - user ip

  Returns:
   UID

  Example:

    check_user(/%FORM);

=cut
#**********************************************************
sub check_user {
  my ($params) = @_;

  my %result = ();

  if ($params->{uid} || $params->{mbr_id}) {
    my $iptv_list = $Iptv->user_list(
      {
        UID            => $params->{uid} || '_SHOW',
        LOGIN          => '_SHOW',
        SERVICE_STATUS => '_SHOW',
        DEPOSIT        => '_SHOW',
        CREDIT         => '_SHOW',
        TP_ID          => '_SHOW',
        SUBSCRIBE_ID   => $params->{mbr_id} || '_SHOW',
        COLS_NAME      => 1,
        PAGE_ROWS      => 1,
      }
    );
    _error_show($Iptv);

    if (!$iptv_list || ref $iptv_list ne 'ARRAY' && !scalar(@$iptv_list) || !$iptv_list->[0]->{uid}) {
      $result{status} = '-1';
      $result{err} = '-1';
      $result{errmsg} = "User is not found";
      #      $Log->log_print('LOG_WARNING', '', 'No user found', { ACTION => 'AUTH' });
      print _json_former(\%result);
      exit;
    }

    my $service = $iptv_list->[0];
    # service_status 1 means it is disabled
    if ($service->{service_status}) {
      $result{ERROR} .= "SERVICE_STATUS: $service->{service_status}. No activated service. ";
      $Log->log_print('LOG_WARNING', $service->{login},
        "SERVICE_STATUS: $service->{service_status}. No activated service. ", { ACTION => 'AUTH' });
    }
    if (($service->{deposit} + $service->{credit}) <= 0) {
      $result{ERROR} .= "DEPOSIT: $service->{deposit}. Too small deposit. ";
      $Log->log_print('LOG_WARNING', $service->{login},
        "DEPOSIT: $service->{deposit}. Too small deposit. ", { ACTION => 'AUTH' });
    }

    $result{user_id} = $service->{uid};
  }
  elsif ($params->{ip}) {

    my $iptv_online = $Iptv->online(
      {
        FRAMED_IP_ADDRESS => $params->{ip},
        UID               => '_SHOW',
        COLS_NAME         => 1,
        PAGE_ROWS         => 1,
      }
    );

    if (!$iptv_online || ref $iptv_online ne 'ARRAY' && !scalar(@$iptv_online) || !$iptv_online->[0]->{uid}) {
      $result{ERROR} .= 'Address ' . $params->{ip} . ' is not connected to any uid';
      $Log->log_print('LOG_WARNING', '', 'Address ' . $params->{ip} . ' not connected to any uid', { ACTION => 'AUTH' });
    }
    else {
      $result{UID} = $iptv_online->[0]->{uid};
    }
  }

  print _json_former(\%result);
}

#**********************************************************
=head2 show_user_tp($attr) - search tp by ip or uid

  Arguments:
    $attr{ip}  - user ip
    $attr{uid} - user ip

  Returns:
   UID

  Example:

    show_user_tp(/%FORM);

=cut
#**********************************************************
sub show_user_tp {
  my ($params) = @_;

  my %result = ();

  if ($params->{uid} || $params->{user_id}) {
    my $iptv_list = $Iptv->user_list(
      {
        UID            => $params->{user_id} || $params->{uid},
        LOGIN          => '_SHOW',
        SERVICE_STATUS => '_SHOW',
        DEPOSIT        => '_SHOW',
        CREDIT         => '_SHOW',
        TP_ID          => '_SHOW',
        COLS_NAME      => 1,
        PAGE_ROWS      => 1,
      }
    );
    _error_show($Iptv);

    if (!$iptv_list || ref $iptv_list ne 'ARRAY' && !scalar(@$iptv_list) || !$iptv_list->[0]->{tp_id}) {
      $result{ERROR} .= 'Wrong UID. No user found. ';
      $Log->log_print('LOG_WARNING', '', 'No user found', { ACTION => 'AUTH' });
      print _json_former(\%result);
      exit;
    }

    my $service = $iptv_list->[0];
    # service_status 1 means it is disabled
    if ($service->{service_status}) {
      $result{ERROR} .= "SERVICE_STATUS: $service->{service_status}. No activated service. ";
      $Log->log_print('LOG_WARNING', $service->{login},
        "SERVICE_STATUS: $service->{service_status}. No activated service. ", { ACTION => 'AUTH' });
    }
    if (($service->{deposit} + $service->{credit}) <= 0) {
      print "OKK";
      $result{ERROR} .= "DEPOSIT: $service->{deposit}. Too small deposit. ";
      $Log->log_print('LOG_WARNING', $service->{login},
        "DEPOSIT: $service->{deposit}. Too small deposit. ", { ACTION => 'AUTH' });
    }
    else {
      print "12222";
    }
  }
  #  elsif($params->{ip}){
  #
  #    my $iptv_online = $Iptv->online(
  #      {
  #        FRAMED_IP_ADDRESS => $params->{ip},
  #        UID               => '_SHOW',
  #        COLS_NAME         => 1,
  #        PAGE_ROWS         => 1,
  #      }
  #    );
  #
  #    if(!$iptv_online || ref $iptv_online ne 'ARRAY' && !scalar(@$iptv_online) || !$iptv_online->[0]->{tp_id}){
  #      $result{ERROR} .= 'Address ' . $params->{ip} . ' is not connected to any tp';
  #      $Log->log_print('LOG_WARNING', '', 'Address ' . $params->{ip} . ' is not connected to any tp', { ACTION => 'AUTH' });
  #    }
  #    else{
  #      $result{TP_ID} = $iptv_online->[0]->{tp_id};
  #    }
  #  }

  print _json_former(\%result);
}

#**********************************************************
=head2 _json_former($request) - hash2json

=cut
#**********************************************************
sub _json_former {
  my ($request) = @_;
  my @text_arr = ();

  if (ref $request eq 'ARRAY') {
    foreach my $key (@{$request}) {
      push @text_arr, _json_former($key);
    }
    return '[' . join(', ', @text_arr) . "]";
  }
  elsif (ref $request eq 'HASH') {
    foreach my $key (keys %{$request}) {
      my $val = _json_former($request->{$key});
      push @text_arr, qq{\"$key\":$val};
    }
    return '{' . join(', ', @text_arr) . "}";
  }
  else {
    $request //= '';
    if ($request =~ '^[0-9]$') {
      return qq{$request};
    }
    else {
      return qq{\"$request\"};
    }
  }
}

#**********************************************************
=head2 transfer_service($attr)

  Arguments:
    $attr{user_id}  - user ip
    $attr{sum} - user ip
    $attr{cont_id}
    $attr{trf_id}
    $attr{message}
    $attr{start}

  Returns:
   UID

  Example:

    transfer_service(/%FORM);

=cut
#**********************************************************
sub transfer_service {
  my ($params) = @_;

  my %result = ();
  my $tarrifs = ();

  if ($params->{user_id}) {
    my $iptv_list = $Iptv->user_info($params->{user_id});
    _error_show($Iptv);

    if (!$iptv_list) {
      $result{status} = '-1';
      print _json_former(\%result);
      exit;
    }

    my $iptv_user = $Iptv->user_list(
      {
        ID             => $iptv_list->{ID},
        LOGIN          => '_SHOW',
        SERVICE_STATUS => '_SHOW',
        DEPOSIT        => '_SHOW',
        CREDIT         => '_SHOW',
        TP_ID          => '_SHOW',
        COLS_NAME      => 1,
        PAGE_ROWS      => 1,
      }
    );
    my $service = $iptv_user->[0];

    if (($service->{deposit} + $service->{credit}) <= 0) {
      $result{status} = '-2';
      print _json_former(\%result);
      exit;
    }
    else {
      require Tariffs;
      Tariffs->import();
      my $Tariffs = Tariffs->new($db, \%conf, $admin);

      $tarrifs = $Tariffs->list({
        NAME        => "_SHOW",
        ACTIV_PRICE => "_SHOW",
        MODULE      => 'Iptv',
        SERVICE_ID  => $iptv_list->{SERVICE_ID},
        FILTER_ID   => $params->{trf_id},
        COLS_NAME   => 1
      });

      $Iptv->{TP_INFO}->{PERIOD_ALIGNMENT} = $Iptv->{PERIOD_ALIGNMENT} || 0;
      $Iptv->{TP_INFO}->{MONTH_FEE} = $Iptv->{MONTH_FEE};
      $Iptv->{TP_INFO}->{DAY_FEE} = $Iptv->{DAY_FEE};
      $Iptv->{TP_INFO}->{TP_ID} = $Iptv->{TP_ID};
      $Iptv->{TP_INFO}->{ABON_DISTRIBUTION} = $Iptv->{ABON_DISTRIBUTION};
      $Iptv->{TP_INFO}->{ACTIV_PRICE} = $tarrifs->[0]{activate_price};

      service_get_month_fee($Iptv, {
        SERVICE_NAME => $iptv_list->{SERVICE_MODULE},
        QUITE        => 1,
      });
    }
  }

  $result{id} = $Iptv->{FEES_ID}[0] || 0;
  $result{status} = '1';
  print _json_former(\%result);

  return 1;
}


#**********************************************************
=head2 smartup_activation($attr)

  Arguments:

  Returns:


=cut
#**********************************************************
sub smartup_activation {

  my %result;
  my $code = 10000000 + int rand(89999999);
  my $exist_device = 0;
  my $Users  = Users->new($db, $admin, \%conf);
  my $Sender = Abills::Sender::Core->new($db, $admin, \%conf);

  my $device = $Iptv->device_list({
    UID         => '_SHOW',
    SERVICE_ID  => '_SHOW',
    DEV_ID      => $FORM{duid},
    ENABLE      => '_SHOW',
    IP_ACTIVITY => '_SHOW',
    CODE        => '_SHOW',
  });

  if (!$Iptv->{TOTAL}) {
    $result{uid} = '';
    $result{status} = '';
    $result{tid} = '';
    my $service_list = $Iptv->services_list({
      MODULE    => "SmartUp",
      COLS_NAME => 1,
    });
    if ($Iptv->{TOTAL}) {
      $Iptv->device_add({
        DEV_ID        => $FORM{duid},
        UID           => 0,
        ENABLE        => 1,
        DATE_ACTIVITY => POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime()),
        IP_ACTIVITY   => '',
        SERVICE_ID    => $service_list->[0]{id},
        CODE          => $code,
      });

      $exist_device = 1;
    }
  }

  my $params = $Iptv->extra_params_list({
    SERVICE_ID => $device->[0]{SERVICE_ID},
    GROUP_ID   => '_SHOW',
    TP_ID      => '_SHOW',
    SMS_TEXT   => '_SHOW',
    SEND_SMS   => '_SHOW',
    IP_MAC     => '_SHOW',
    BALANCE    => '_SHOW',
    MAX_DEVICE => '_SHOW',
    PIN        => '_SHOW',
  });

  my $default_params = $Iptv->extra_params_list({
    SERVICE_ID => $device->[0]{SERVICE_ID},
    GROUP_ID   => '_SHOW',
    TP_ID      => '_SHOW',
    SMS_TEXT   => '_SHOW',
    SEND_SMS   => '_SHOW',
    IP_MAC     => "0.0.0.0/0",
    BALANCE    => '_SHOW',
    MAX_DEVICE => '_SHOW',
    PIN        => '_SHOW',
  });
  my $default_count = @$default_params;

  $device = $Iptv->device_list({
    UID         => '_SHOW',
    SERVICE_ID  => '_SHOW',
    DEV_ID      => $FORM{duid},
    ENABLE      => '_SHOW',
    IP_ACTIVITY => '_SHOW',
    CODE        => '_SHOW',
  });

  if ($Iptv->{TOTAL} == 1) {
    if ($FORM{action} eq "login" || $FORM{action} eq "confirm") {
      $result{uid} = '';
      $result{status} = '';
      $result{tid} = '';
      if ($FORM{action} eq "confirm") {
        if ($device->[0]{UID} && $device->[0]{CODE} && $device->[0]{CODE} eq $FORM{code}) {
          $device->[0]{ENABLE} = 0;
          $Iptv->device_change({
            ID            => $device->[0]{id},
            ENABLE        => 0,
            DATE_ACTIVITY => POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime()),
          });

          my $main_params = 0;
          foreach my $element (@$params) {
            if (check_ip($FORM{ip}, $element->{IP_MAC}) && $element->{IP_MAC} ne "0.0.0.0/0") {
              $Sender->send_message({
                TO_ADDRESS  => $FORM{phone},
                MESSAGE     => $element->{SMS_TEXT},
                SENDER_TYPE => 'Sms',
                UID         => $device->[0]{UID}
              });
              $main_params = 1;
              last;
            }
          }
          if ($default_count && !$main_params) {
            $Sender->send_message({
              TO_ADDRESS  => $FORM{phone},
              MESSAGE     => $default_params->[0]{SMS_TEXT},
              SENDER_TYPE => 'Sms',
              UID         => $device->[0]{UID}
            });
          }
        }
      }
      my $user = $Iptv->user_list({
        TP_FILTER  => '_SHOW',
        UID        => $device->[0]{UID},
        SERVICE_ID => $device->[0]{SERVICE_ID},
        COLS_NAME  => 1,
      });

      $result{status} = ($device->[0]{ENABLE} == 1) ? "unverified" : "active";

      if ($Iptv->{TOTAL} > 0) {
        $result{uid} = $device->[0]{UID};
        $result{tid} = $user->[0]{filter_id};
        print _json_former(\%result);
        exit;
      }
      else {
        my $res = _ip_user_search($device->[0]{SERVICE_ID}, $device->[0]{ID}, $device->[0]{CODE}, $exist_device);
        if ($res && $res->{uid}) {
          my %final_result;
          $final_result{status} = $result{status};
          $final_result{tid} = $res->{tid};
          $final_result{uid} = $res->{uid};
          print _json_former(\%final_result);
          exit;
        }

        my $user_info = $Users->list({
          LOGIN     => "tv" . substr($FORM{phone}, 2, 10),
          FIO       => '_SHOW',
          PHONE     => '_SHOW',
          COLS_NAME => 1,
          PAGE_ROWS => 1,
        });

        if ($Users->{TOTAL}) {
          foreach my $element (@$params) {
            if (check_ip($FORM{ip}, $element->{IP_MAC})) {
              $user = $Iptv->user_list({
                TP_FILTER  => '_SHOW',
                UID        => $user_info->[0]{uid} || $user_info->[0]{UID},
                SERVICE_ID => $element->{SERVICE_ID},
                COLS_NAME  => 1,
              });

              $Iptv->device_list({
                UID         => $user_info->[0]{uid} || $user_info->[0]{UID},
                SERVICE_ID  => '_SHOW',
                DEV_ID      => '_SHOW',
                ENABLE      => '_SHOW',
                IP_ACTIVITY => '_SHOW',
              });

              if ($element->{MAX_DEVICE} > $Iptv->{TOTAL}) {
                $result{tid} = $user->[0]{filter_id} || '';
                $result{uid} = $user_info->[0]{uid} || $user_info->[0]{UID};
                $Iptv->device_change({
                  ID  => $device->[0]{ID},
                  UID => $user_info->[0]{uid} || $user_info->[0]{UID},
                });
                if ($exist_device) {
                  $Sender->send_message({
                    TO_ADDRESS  => $FORM{phone},
                    MESSAGE     => $device->[0]{CODE},
                    SENDER_TYPE => 'Sms',
                    UID         => $result{uid}
                  });
                }
              }

              print _json_former(\%result);
              return 1;
              last;
            }
          }

          if ($default_count) {
            $user = $Iptv->user_list({
              TP_FILTER  => '_SHOW',
              UID        => $user_info->[0]{uid} || $user_info->[0]{UID},
              SERVICE_ID => $default_params->[0]{SERVICE_ID},
              COLS_NAME  => 1,
            });

            $Iptv->device_list({
              UID         => $user_info->[0]{uid} || $user_info->[0]{UID},
              SERVICE_ID  => '_SHOW',
              DEV_ID      => '_SHOW',
              ENABLE      => '_SHOW',
              IP_ACTIVITY => '_SHOW',
            });

            if ($default_params->[0]{MAX_DEVICE} > $Iptv->{TOTAL}) {
              $result{tid} = $user->[0]{filter_id} || '';
              $result{uid} = $user_info->[0]{uid} || $user_info->[0]{UID};
              $Iptv->device_change({
                ID  => $device->[0]{ID},
                UID => $user_info->[0]{uid} || $user_info->[0]{UID},
              });
              if ($exist_device) {
                $Sender->send_message({
                  TO_ADDRESS  => $FORM{phone},
                  MESSAGE     => $device->[0]{CODE},
                  SENDER_TYPE => 'Sms',
                  UID         => $device->[0]{UID}
                });
              }
            }
            print _json_former(\%result);
            return 1;
          }
        }
        else {
          foreach my $element (@$params) {
            if (check_ip($FORM{ip}, $element->{IP_MAC}) && $element->{IP_MAC} ne "0.0.0.0/0") {
              #              my $user_phone = '';
              #              if ($FORM{phone} =~ /^380\d{9}$/) {
              #                $user_phone = substr($FORM{phone}, 2, 10);
              #              }
              #              else {
              #                $result{status} = '';
              #                $result{tid} = '';
              #                $result{uid} = '';
              #                print _json_former(\%result);
              #                return 1;
              #              }
              #              my $Payments = Finance->payments($db, $admin, \%conf);
              #              $Users->add({
              #                CREATE_BILL => 1,
              #                LOGIN       => "tv$user_phone",
              #                GID         => $element->{GROUP_ID},
              #              });
              #              my $uid = $Users->{INSERT_ID};
              #              $Users->info($uid);
              #              $Users->pi_add({ UID => $uid, PHONE => $FORM{phone} });
              #
              #              $Payments->add($Users, {
              #                SUM => $element->{BALANCE},
              #              });
              #
              #              $Iptv->user_add({
              #                UID        => $uid,
              #                TP_ID      => $element->{TP_ID},
              #                SERVICE_ID => $element->{SERVICE_ID},
              #                PIN        => $element->{PIN},
              #              });
              #
              #              $result{uid} = $uid;
              #              $user = $Iptv->user_list({
              #                TP_FILTER  => '_SHOW',
              #                UID        => $uid,
              #                SERVICE_ID => $element->{SERVICE_ID},
              #                COLS_NAME  => 1,
              #              });
              #              $result{tid} = $user->[0]{filter_id} || '';

              $Iptv->device_change({
                ID  => $device->[0]{ID},
                UID => '0',
              });

              $result{tid} = '';
              $result{uid} = '';
              print _json_former(\%result);
              return 1;
              last;
            }
          }
          if ($default_count) {
            my $user_phone = '';
            if ($FORM{phone} =~ /^380\d{9}$/) {
              $user_phone = substr($FORM{phone}, 2, 10);
            }
            else {
              $result{status} = '';
              $result{tid} = '';
              $result{uid} = '';
              print _json_former(\%result);
              return 1;
            }
            my $Payments = Finance->payments($db, $admin, \%conf);
            $Users->add({
              CREATE_BILL => 1,
              LOGIN       => "tv$user_phone",
              GID         => $default_params->[0]{GROUP_ID},
            });
            my $uid = $Users->{INSERT_ID};
            $Users->info($uid);
            $Users->pi_add({ UID => $uid, PHONE => $FORM{phone} });

            $Payments->add($Users, {
              SUM => $default_params->[0]{BALANCE},
            });

            $Iptv->user_add({
              UID        => $uid,
              TP_ID      => $default_params->[0]{TP_ID},
              SERVICE_ID => $default_params->[0]{SERVICE_ID},
              PIN        => $default_params->[0]{PIN},
            });

            $result{uid} = $uid;
            $user = $Iptv->user_list({
              TP_FILTER  => '_SHOW',
              UID        => $uid,
              SERVICE_ID => $default_params->[0]{SERVICE_ID},
              COLS_NAME  => 1,
            });
            $result{tid} = $user->[0]{filter_id} || '';

            $Iptv->device_change({
              ID  => $device->[0]{ID},
              UID => $uid,
            });

            if ($exist_device) {
              $Sender->send_message({
                TO_ADDRESS  => $FORM{phone},
                MESSAGE     => $device->[0]{CODE},
                SENDER_TYPE => 'Sms',
                UID         => $uid,
              });
            }

            print _json_former(\%result);
            return 1;
          }
        }
      }
    }
    elsif ($FORM{action} eq "verify") {
      $Iptv->{TOTAL} = 0;
      $result{status} = '';
      $result{tid} = '';
      my $user = $Iptv->user_list({
        TP_FILTER  => '_SHOW',
        UID        => $device->[0]{UID},
        SERVICE_ID => $device->[0]{SERVICE_ID},
        COLS_NAME  => 1,
      });

      if ($Iptv->{TOTAL} > 0) {
        $result{tid} = $user->[0]{filter_id};
        $result{status} = $device->[0]{ENABLE} eq 1 ? "unverified" : "active";
      }
      else {
        my $res = _ip_user_search($device->[0]{SERVICE_ID}, $device->[0]{ID}, $device->[0]{CODE}, $exist_device);
        if ($res && $res->{uid}) {
          my %final_result;
          $final_result{tid} = $res->{tid};
          $final_result{status} = $device->[0]{ENABLE} eq 1 ? "unverified" : "active";
          print _json_former(\%final_result);
          exit;
        }
        else {
          my %final_result;
          $final_result{tid} = '';
          $final_result{status} = '';
          print _json_former(\%final_result);
          exit;
        }
      }
    }
    else {
      my $user = $Users->info($device->[0]{UID});
      $result{login} = $user->{LOGIN};
      $result{balance} = $user->{DEPOSIT};
      if (!$Users->{TOTAL}) {
        my $res = _ip_user_search($device->[0]{SERVICE_ID}, $device->[0]{ID}, $device->[0]{CODE}, $exist_device);
        if ($res && $res->{uid}) {
          my %final_result;
          $final_result{login} = $res->{login};
          $final_result{balance} = $res->{balance};
          print _json_former(\%final_result);
          exit;
        }
        else {
          my %final_result;
          $final_result{login} = '';
          $final_result{balance} = '';
          print _json_former(\%final_result);
          exit;
        }
      }
      print _json_former(\%result);
      exit;
    }
  }

  print _json_former(\%result);
}

#**********************************************************
=head2 smartup_pin($attr)

  Arguments:

  Returns:


=cut
#**********************************************************
sub smartup_pin {
  my ($attr) = @_;

  my $device = $Iptv->device_list({
    UID         => '_SHOW',
    SERVICE_ID  => '_SHOW',
    DEV_ID      => $FORM{duid},
    ENABLE      => '_SHOW',
    IP_ACTIVITY => '_SHOW',
    CODE        => '_SHOW',
  });

  my $code = 10000000 + int rand(89999999);
  my $exist_device = 0;
  my %result;
  $result{pin} = '';

  if (!$Iptv->{TOTAL}) {
    my $service_list = $Iptv->services_list({
      MODULE    => "SmartUp",
      COLS_NAME => 1,
    });
    if ($Iptv->{TOTAL}) {
      $Iptv->device_add({
        DEV_ID        => $FORM{duid},
        UID           => 0,
        ENABLE        => 1,
        DATE_ACTIVITY => POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime()),
        IP_ACTIVITY   => '',
        SERVICE_ID    => $service_list->[0]{id},
        CODE          => $code,
      });

      $device = $Iptv->device_list({
        UID         => '_SHOW',
        SERVICE_ID  => '_SHOW',
        DEV_ID      => $FORM{duid},
        ENABLE      => '_SHOW',
        IP_ACTIVITY => '_SHOW',
        CODE        => '_SHOW',
      });
      $exist_device = 1;
    }
  }

  my $user = $Iptv->user_list({
    PIN        => '_SHOW',
    UID        => $device->[0]{UID},
    SERVICE_ID => $device->[0]{SERVICE_ID},
    COLS_NAME  => 1,
  });

  if ($Iptv->{TOTAL} > 0) {
    if ($attr->{ACTION} eq "pin") {
      $result{pin} = $user->[0]{pin};
      print _json_former(\%result);
      exit;
    }
    if ($attr->{ACTION} eq "set") {
      $Iptv->user_change({
        ID  => $user->[0]{id},
        PIN => $FORM{set},
      });
      if (!$Iptv->{error} && $Iptv->{PIN}) {
        $result{pin} = $Iptv->{PIN};
        print _json_former(\%result);
      }
      exit;
    }
  }
  else {
    my $res = _ip_user_search($device->[0]{SERVICE_ID}, $device->[0]{ID}, $device->[0]{CODE}, $exist_device);
    if ($res && $res->{uid}) {
      my %final_result;

      if ($attr->{ACTION} eq "pin") {
        $final_result{pin} = $res->{pin};
        print _json_former(\%final_result);
        exit;
      }
      if ($attr->{ACTION} eq "set") {
        $user = $Iptv->user_list({
          PIN        => '_SHOW',
          UID        => $res->{uid},
          SERVICE_ID => $device->[0]{SERVICE_ID},
          COLS_NAME  => 1,
        });
        $Iptv->user_change({
          ID  => $user->[0]{id},
          PIN => $FORM{set},
        });
        if (!$Iptv->{error} && $Iptv->{PIN}) {
          $final_result{pin} = $Iptv->{PIN};
          print _json_former(\%final_result);
        }
        exit;
      }
      print _json_former(\%final_result);
      exit;
    }
  }

  print _json_former(\%result);
}

#**********************************************************
=head2 _ip_user_search($attr)

  Arguments:

  Returns:


=cut
#**********************************************************
sub _ip_user_search {
  my ($service_id, $device_id, $code, $new_device) = @_;

  my %result;
  use Internet;
  use Abills::Sender::Core;
  my $Sender = Abills::Sender::Core->new($db, $admin, \%conf);
  my $Internet = Internet->new($db, $admin, \%conf);
  my $Users = Users->new($db, $admin, \%conf);

  my $params = $Iptv->extra_params_list({
    SERVICE_ID => $service_id,
    GROUP_ID   => '_SHOW',
    TP_ID      => '_SHOW',
    SMS_TEXT   => '_SHOW',
    SEND_SMS   => '_SHOW',
    IP_MAC     => '_SHOW',
    BALANCE    => '_SHOW',
    MAX_DEVICE => '_SHOW',
    PIN        => '_SHOW',
  });

  my $default_params = $Iptv->extra_params_list({
    SERVICE_ID => $service_id,
    GROUP_ID   => '_SHOW',
    TP_ID      => '_SHOW',
    SMS_TEXT   => '_SHOW',
    SEND_SMS   => '_SHOW',
    IP_MAC     => "0.0.0.0/0",
    BALANCE    => '_SHOW',
    MAX_DEVICE => '_SHOW',
    PIN        => '_SHOW',
  });

  my $default_count = @$default_params;

  my $Internet_user_list = $Internet->list({
    LOGIN      => '_SHOW',
    UID        => '_SHOW',
    FIO        => '_SHOW',
    ONLINE     => '_SHOW',
    ONLINE_IP  => $FORM{ip},
    ONLINE_CID => '_SHOW',
    TP_NAME    => '_SHOW',
    IP         => '_SHOW',
    COLS_NAME  => 1,
    PAGE_ROWS  => 1000000
  });

  if ($Internet->{TOTAL}) {
    $user = $Iptv->user_list({
      TP_FILTER  => '_SHOW',
      PIN        => '_SHOW',
      UID        => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
      SERVICE_ID => $service_id,
      COLS_NAME  => 1,
    });

    if ($Iptv->{TOTAL}) {
      $result{uid} = $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID};
      $result{tid} = $user->[0]{filter_id} || '';
      $result{pin} = $user->[0]{pin} || '';

      $Iptv->device_change({
        ID  => $device_id,
        UID => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
      });

      my $user = $Users->info($result{uid});
      my $logins_list = $Users->list({
        PHONE     => '_SHOW',
        UID       => $result{uid},
        COLS_NAME => 1,
        PAGE_ROWS => 1000000
      });

      if (($logins_list->[0]{PHONE} || $logins_list->[0]{phone})&& $new_device && $code) {
        $Sender->send_message({
          TO_ADDRESS  => $logins_list->[0]{PHONE} || $logins_list->[0]{phone},
          MESSAGE     => $code,
          SENDER_TYPE => 'Sms',
          UID         => $result{uid},
        });
      }

      $result{login} = $user->{LOGIN};
      $result{balance} = $user->{DEPOSIT};
      return \%result;
    }

    foreach my $element (@$params) {
      if (check_ip($FORM{ip}, $element->{IP_MAC}) && $element->{IP_MAC} ne "0.0.0.0/0") {
        $Iptv->user_add({
          UID        => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
          TP_ID      => $element->{TP_ID},
          SERVICE_ID => $element->{SERVICE_ID},
          PIN        => $element->{PIN},
        });

        $result{uid} = $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID};
        $user = $Iptv->user_list({
          TP_FILTER  => '_SHOW',
          PIN        => '_SHOW',
          UID        => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
          SERVICE_ID => $element->{SERVICE_ID},
          COLS_NAME  => 1,
        });
        $result{tid} = $user->[0]{filter_id} || '';
        $result{pin} = $user->[0]{pin} || '';

        $Iptv->device_change({
          ID  => $device_id,
          UID => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
        });
        my $logins_list = $Users->list({
          PHONE     => '_SHOW',
          UID       => $result{uid},
          COLS_NAME => 1,
          PAGE_ROWS => 1000000
        });

        if (($logins_list->[0]{PHONE} || $logins_list->[0]{phone})&& $new_device && $code) {
          $Sender->send_message({
            TO_ADDRESS  => $logins_list->[0]{PHONE} || $logins_list->[0]{phone},
            MESSAGE     => $code,
            SENDER_TYPE => 'Sms',
            UID         => $result{uid},
          });
        }

        my $user = $Users->info($result{uid});
        $result{login} = $user->{LOGIN};
        $result{balance} = $user->{DEPOSIT};
        return \%result;

        last;
      }
    }

    if ($default_count) {
      $Iptv->user_add({
        UID        => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
        TP_ID      => $default_params->[0]{TP_ID},
        SERVICE_ID => $default_params->[0]{SERVICE_ID},
        PIN        => $default_params->[0]{PIN},
      });

      $result{uid} = $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID};
      $user = $Iptv->user_list({
        TP_FILTER  => '_SHOW',
        PIN        => '_SHOW',
        UID        => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
        SERVICE_ID => $default_params->[0]{SERVICE_ID},
        COLS_NAME  => 1,
      });
      $result{tid} = $user->[0]{filter_id} || '';
      $result{pin} = $user->[0]{pin} || '';

      $Iptv->device_change({
        ID  => $device_id,
        UID => $Internet_user_list->[0]{uid} || $Internet_user_list->[0]{UID},
      });
      my $logins_list = $Users->list({
        PHONE     => '_SHOW',
        UID       => $result{uid},
        COLS_NAME => 1,
        PAGE_ROWS => 1000000
      });

      if (($logins_list->[0]{PHONE} || $logins_list->[0]{phone})&& $new_device && $code) {
        $Sender->send_message({
          TO_ADDRESS  => $logins_list->[0]{PHONE} || $logins_list->[0]{phone},
          MESSAGE     => $code,
          SENDER_TYPE => 'Sms',
          UID         => $result{uid},
        });
      }

      my $user = $Users->info($result{uid});
      $result{login} = $user->{LOGIN};
      $result{balance} = $user->{DEPOSIT};
      return \%result;
    }
  }

  return 0;
}

1;

