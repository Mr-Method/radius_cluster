#!/usr/bin/perl

=head1 NAME

  Paysys processing system
  Check payments incomming request

=cut

use strict;

BEGIN {
  our $libpath = '../';
  our $sql_type = 'mysql';
  unshift(@INC,
    $libpath . "Abills/$sql_type/",
    $libpath . "Abills/modules/",
    $libpath . "Abills/",
    $libpath . '/lib/');

  our $begin_time = 0;
  eval {require Time::HiRes;};
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use Abills::Defs;
do "../libexec/config.pl";

use Abills::Base;
use Abills::Filters;
use Users;
use Paysys;
use Finance;
use Admins;
use Conf;

our $silent = 1;
our %lang;
our $debug = $conf{PAYSYS_DEBUG} || 0;
our $html = Abills::HTML->new({ CONF => \%conf });
our $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

our $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => $ENV{REMOTE_ADDR} });
$admin->{DATE} = $DATE;

delete $FORM{language};
require Abills::Misc;
require Abills::Templates;
require Paysys::Paysys_Base;

#Operation status
my $status = '';

# read conf for DB
our $Conf = Conf->new($db, $admin, \%conf);

do "../language/$html->{language}.pl";

if ($Paysys::VERSION < 3.2) {
  print "Content=-Type: text/html\n\n";
  print "Please update module 'Paysys' to version 3.2 or higher. http://abills.net.ua/";
  return 0;
}

#Check allow ips
if ($conf{PAYSYS_IPS}) {
  if ($ENV{REMOTE_ADDR} && !check_ip($ENV{REMOTE_ADDR}, $conf{PAYSYS_IPS})) {
    print "Content-Type: text/html\n\n";
    my $error = "Error: IP '$ENV{REMOTE_ADDR}' DENY by System";
    sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "ABillS - Paysys", "IP '$ENV{REMOTE_ADDR}' DENY by System",
      "$conf{MAIL_CHARSET}", "2 (High)");
    mk_log($error);
    exit;
  }
}

if ($conf{PAYSYS_PASSWD}) {
  my ($user, $password) = split(/:/, $conf{PAYSYS_PASSWD});

  if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
    $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
    my ($REMOTE_USER, $REMOTE_PASSWD) = split(/:/, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));

    if ((!$REMOTE_PASSWD)
      || ($REMOTE_PASSWD && $REMOTE_PASSWD ne $password)
      || (!$REMOTE_USER)
      || ($REMOTE_USER && $REMOTE_USER ne $user)) {
      print "WWW-Authenticate: Basic realm=\"Billing system\"\n";
      print "Status: 401 Unauthorized\n";
      print "Content-Type: text/html\n\n";
      print "Access Deny";
      exit;
    }
  }
}

our $Paysys = Paysys->new($db, $admin, \%conf);
our $payments = Finance->payments($db, $admin, \%conf);
our $users = Users->new($db, $admin, \%conf);
our %PAYSYS_PAYMENTS_METHODS = %{ cfg2hash($conf{PAYSYS_PAYMENTS_METHODS}) };

#debug =========================================
my $output2 = get_request_info();

if ($debug > 2) {
  mk_log($output2);
}
#END debug =====================================



#NEW SCHEME ====================================
if($conf{PAYSYS_NEW_SCHEME}){
  require Paysys::Configure;
  require Paysys::User_portal;

  my $connected_systems_list = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
  });

  foreach my $connected_system (@$connected_systems_list){
    my $remote_ip = $ENV{REMOTE_ADDR};
    my $paysys_ip = $connected_system->{paysys_ip};
    my $module    = $connected_system->{module};

    if(check_ip($remote_ip, $paysys_ip)){
      my $INPUT_DATA = get_request_info();
      mk_log("$INPUT_DATA", {
          PAYSYS_ID => $module,

        });
      my $REQUIRE_OBJECT = _configure_load_payment_module($module);
      mk_log("$module loaded\n", {
          PAYSYS_ID => $module
        });
      my $PAYSYS_OBJECT = $REQUIRE_OBJECT->new($db, $admin, \%conf, {
        CUSTOM_NAME => $connected_system->{name},
        CUSTOM_ID   => $connected_system->{paysys_id}});
      mk_log("$module object created\n", {
          PAYSYS_ID => $module
        });
      $PAYSYS_OBJECT->proccess(\%FORM);
      mk_log("$module process ended\n\n", {
          PAYSYS_ID => $module
        });
      exit;
    }
  }

  # payment function
  paysys_payment_gateway();

  exit;
}


#**********************************************************
=head2 paysys_payment_gateway()

  Arguments:
     -
    
  Returns:
  
=cut
#**********************************************************
sub paysys_payment_gateway {
  # load header
  $html->{METATAGS} = templates('metatags');
  $html->{WEB_TITLE} = 'Payment Gateway';

  print $html->header();

  my ($result, $user_info) = paysys_check_user({
    CHECK_FIELD => $conf{PAYSYS_GATEWAY_IDENTIFIER} || 'UID',
    USER_ID     => $FORM{IDENTIFIER},
  });

  my %TEMPLATES_ARGS = ();

  if ($FORM{PAYMENT_SYSTEM}) {
    my $payment_system_info = $Paysys->paysys_connect_system_info({
      PAYSYS_ID => $FORM{PAYMENT_SYSTEM},
      MODULE    => '_SHOW',
      COLS_NAME => '_SHOW'
    });

    if($Paysys->{errno}){
      print $html->message('err', "$lang{ERROR}", 'Payment system not exist');
    }
    else{
      my $Module = _configure_load_payment_module($payment_system_info->{module});
      my $Paysys_Object = $Module->new($db, $admin, \%conf, { HTML => $html });
      print $Paysys_Object->user_portal($user_info, {
          %FORM,
        });
    }
    return 1;
  }

  if($result == 0){
    #SHOW TEMPLATE WITH PAYMENT SYSTEMS SELECT
    $TEMPLATES_ARGS{IDENTIFIER} = $FORM{IDENTIFIER};
    my $connected_systems = $Paysys->paysys_connect_system_list({
      PAYSYS_ID => '_SHOW',
      NAME      => '_SHOW',
      MODULE    => '_SHOW',
      STATUS    => 1,
      COLS_NAME => 1,
    });

    $TEMPLATES_ARGS{OPERATION_ID} = mk_unique_value(8, { SYMBOLS => '0123456789' });
    if (in_array('Maps', \@MODULES)) {
#      $TEMPLATES_ARGS{MAP} = paysys_maps();
    }

    my $count = 1;
    foreach my $payment_system (@$connected_systems) {
      my $Module = _configure_load_payment_module($payment_system->{module});

      if ($Module->can('user_portal')) {
        $TEMPLATES_ARGS{PAY_SYSTEM_SEL} .= _paysys_system_radio({
          NAME    => $payment_system->{name},
          MODULE  => $payment_system->{module},
          ID      => $payment_system->{paysys_id},
          CHECKED => $count == 1 ? 'checked' : '',
        });
        $count++;
      }
    }

    $html->tpl_show(_include('paysys_main', 'Paysys'), \%TEMPLATES_ARGS,
      { OUTPUT2RETURN => 0});

    return 1;
  }
  elsif($result == 1){
    $html->message("err", "Try again");
  }
  elsif($result == 11){
    $html->message("err", "Paysys Disable");
  }

  $html->tpl_show(_include('paysys_gateway', 'Paysys'), \%TEMPLATES_ARGS,
    { });
}

#END NEW SCHEME ================================





load_pmodule('Digest::MD5');
our $md5 = Digest::MD5->new();

if ($conf{PAYSYS_SUCCESSIONS}) {
  $conf{PAYSYS_SUCCESSIONS} =~ s/[\n\r]+//g;
  my @systems_arr = split(/;/, $conf{PAYSYS_SUCCESSIONS});
  # IPS:ID:NAME:SHORT_NAME:MODULE_function;
  foreach my $line (@systems_arr) {
    my ($ips, $id, undef, $short_name, $function) = split(/:/, $line);

    my %system_params = (
      SYSTEM_SHORT_NAME => $short_name,
      SYSTEM_ID         => $id
    );

    if (check_ip($ENV{REMOTE_ADDR}, $ips)) {
      if ($function =~ /(\S+)\.pm/) {
        load_pay_module("$1", { SYS_PARAMS => \%system_params });
      }
      else {
        &{ \&$function }(\%system_params);
      }

      exit;
    }

    %system_params = ();
  }
}

#Paysys ips
my %ip_binded_system = (
  '185.46.150.122,213.160.154.26,185.46.148.218,213.160.149.0/24,185.46.150.122,213.160.149.229,213.160.149.230,185.46.148.219'
  => 'Ibox',
  '91.194.189.69'
  => 'Payu',
  '78.140.166.69'
  => 'Okpay', # $FORM{ok_txn_id}
  '77.109.141.170'
  => 'Perfectmoney', # $FORM{PAYEE_ACCOUNT}
  '85.192.45.0/24,194.67.81.0/24,91.142.251.0/24,89.111.54.0/24,95.163.74.0/24'
  => 'Smsonline',
  '107.22.173.15,107.22.173.86,217.117.64.232/28,75.101.163.115,213.154.214.76,217.117.64.232/29, 217.77.211.38, 217.117.68.232'
  => 'Privat_terminal',
  '62.89.31.36,95.140.194.139,195.250.65.250,195.250.65.252,109.68.126.16/28, 212.42.193.76, 185.92.84.144/30, 144.76.93.104 '
  #'62.89.31.36,95.140.194.139,195.250.65.250,195.250.65.252,109.68.126.16/28,144.76.93.104,185.92.84.144/30, 217.76.12.53'
  => 'Telcell',
  '195.76.9.187,195.76.9.222'
  => 'Redsys',
  '217.77.49.157'
  => 'Rucard',
  # '77.73.26.162,77.73.26.163,77.73.26.164,217.73.198.66' #old deltapay
  '217.73.200.56,141.101.175.0/24,144.76.93.104'
  => 'Deltapay',
  '193.110.17.230'
  => 'Zaplati_sumy',
#  '91.229.115.11'
#  => 'Ipay',
  '62.149.8.166,82.207.125.57,62.149.15.210,212.42.94.154,212.42.94.131,89.184.66.69'#
  #212.42.93.154 - 24 non stop IP
  => 'Platezhka',
  '213.230.106.112/28,213.230.65.85/28'
  => 'Paynet',
  '93.183.196.26,195.230.131.50,93.183.196.28,185.44.228.240,185.44.228.249,185.44.228.250,185.44.228.251,212.42.207.83,185.44.230.112'
  => 'Easysoft',
  '77.120.97.36'
  => 'PayU',
  '87.248.226.170,217.195.80.50,94.138.149.0/24,194.186.207.0/24,194.54.14.0/24,94.51.87.80,94.51.87.83,94.51.87.85'
  => 'Sberbank',
  '46.51.203.221'
  => 'Comepay',
  '77.222.138.142,78.30.232.14,77.120.96.58,91.105.201.0/24'
  => 'Usmp',
  '54.229.105.178,54.229.105.179' #75.101.163.115, 107.22.173.15, 107.22.173.86
  => 'Liqpay',
  '195.85.198.136,195.85.198.15'
  => 'Upc',
  '212.111.95.87'
  => 'Evostok',
  '137.135.220.102'
  => 'Kaznachey',
  '212.24.63.49'
  => 'Robokassa',
  '192.168.0.0' #add IP f
  => 'Paykeeper',
  '193.105.39.6, 195.54.10.47' # add ip
  => 'Chelyabinvestbank',
  '54.76.178.89,54.154.216.60'
  => 'Fondy',
  '78.140.172.231, 62.113.223.114'
  => 'Platon',
  '81.177.31.100-81.177.31.200'
  => 'Walletone',
  '213.145.147.131'
  => 'Mobilnik',
  '82.207.124.116'
  => 'Oschadbank',
  '77.72.132.74, 77.72.128.213,​ 77.72.128.214'
  => 'Idram',
  '62.117.79.155,62.117.79.156'
  => 'Minbank',
  '89.111.54.163,89.111.54.165,185.77.232.26,185.77.233.26,185.77.232.27,185.77.233.27'
  => 'Mixplat',
#  '77.75.157.168,77.75.157.169,77.75.159.166,77.75.159.170,77.75.157.166,77.75.157.170' # OLD
  '77.75.157.168, 77.75.157.169, 77.75.159.166, 77.75.159.170, 77.75.158.144, 77.75.158.145, 77.75.158.153, 77.75.158.154, 77.75.158.162, 77.75.158.163, 77.75.155.139, 77.75.155.140, 77.75.155.148, 77.75.155.149, 77.75.155.157, 77.75.155.158'
  => 'Yandex_kassa',
  '91.194.226.0/23'
  => 'Tinkoff',
  '91.200.28.0/24, 91.227.52.0/24'
  => 'Paymaster_ru',
  '195.200.209.9, 195.200.209.15, 195.200.209.20'
  => 'Rncb',
);

#Test system
if ($conf{PAYSYS_TEST_SYSTEM} || $FORM{PAYSYS_TEST_SYSTEM}) {
#  if ($FORM{PAYSYS_TEST_SYSTEM}) {
#    $conf{PAYSYS_TEST_SYSTEM} = $FORM{PAYSYS_TEST_SYSTEM};
#  }
  my ($ips, $pay_system) = split(/:/, $conf{PAYSYS_TEST_SYSTEM});
  if (check_ip($ENV{REMOTE_ADDR}, "$ips")) {

    load_pay_module($pay_system);
    exit;
  }
}

#Proccess system
foreach my $params (keys %ip_binded_system) {
  my $ips = $params;
  if (check_ip($ENV{REMOTE_ADDR}, "$ips")) {
    load_pay_module($ip_binded_system{"$params"});
  }
}

if ($FORM{__BUFFER} && $FORM{__BUFFER} =~ /^{.+}$/ &&
  check_ip($ENV{REMOTE_ADDR},
    '75.101.163.115,107.22.173.15,107.22.173.86,213.154.214.76,217.117.64.232-217.117.64.238')) {
  load_pay_module('Private_bank_json');
}
#
elsif (check_ip($ENV{REMOTE_ADDR}, '176.9.53.221,176.9.53.221,5.9.145.93,5.9.145.89')) {
  paymaster_check_payment();
  exit;
}
# IP: 77.120.97.36
elsif ($FORM{merchantid}) {
  load_pay_module('Regulpay');
}
elsif ($FORM{request_type} && $FORM{random} || $FORM{copayco_result}) {
  load_pay_module('Copayco');
}
elsif ($FORM{xmlmsg}) {
  load_pay_module('Minbank');
}
elsif ($FORM{from} && $FORM{from} eq 'Payonline') {
  load_pay_module('Payonline');
}
elsif ($conf{PAYSYS_EXPPAY_ACCOUNT_KEY}
  && ($FORM{action} == 1
  || $FORM{action} == 2
  || $FORM{action} == 4)) {
  load_pay_module('Express');
}
elsif ($FORM{action} && $conf{PAYSYS_CYBERPLAT_ACCOUNT_KEY}) {
  load_pay_module('Cyberplat');
}
elsif ($FORM{SHOPORDERNUMBER}) {
  load_pay_module('Portmone');
}
elsif ($FORM{acqid}) {
  privatbank_payments();
}
elsif ($FORM{operation} || $ENV{'QUERY_STRING'} =~ /operation=/) {
  load_pay_module('Comepay');
}
elsif ($FORM{'<OPERATION id'} || $FORM{'%3COPERATION%20id'}) {
  load_pay_module('Express-oplata');
}
elsif ($FORM{ACT}) {
  load_pay_module('24_non_stop');
}
elsif ($conf{PAYSYS_GIGS_IPS} && $conf{PAYSYS_GIGS_IPS} =~ /$ENV{REMOTE_ADDR}/) {
  load_pay_module('Gigs');
}
elsif ($conf{PAYSYS_EPAY_ACCOUNT_KEY} && $FORM{command} && $FORM{txn_id}) {
  load_pay_module('Epay');
}
elsif ($FORM{txn_id} || $FORM{prv_txn} || defined($FORM{prv_id}) || ($FORM{command} && $FORM{account})) {
  osmp_payments();
  # new_load_pay_module('Osmp');
}
elsif (
  $conf{PAYSYS_GAZPROMBANK_ACCOUNT_KEY}
    && ($FORM{lsid}
    || $FORM{trid}
    || $FORM{dtst})
) {
  load_pay_module('Gazprombank');
}

if (check_ip($ENV{REMOTE_ADDR}, '92.125.0.0/24')) {
  osmp_payments_v4();
}
elsif ($conf{PAYSYS_ERIPT_IPS} && check_ip($ENV{REMOTE_ADDR}, $conf{PAYSYS_ERIPT_IPS})) {
  load_pay_module('Erip');
}
elsif (check_ip($ENV{REMOTE_ADDR}, '79.142.16.0/21')) {
  print "Content-Type: text/xml\n\n" . "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" . "<response>\n" . "<result>300</result>\n" . "<result1>$ENV{REMOTE_ADDR}</result1>\n" . " </response>\n";
  exit;
}
elsif ($FORM{payment} && $FORM{payment} =~ /pay_way/) {
  load_pay_module('P24');
}
elsif ($conf{'PAYSYS_YANDEX_ACCCOUNT'} && $FORM{code}) {
  load_pay_module('Yandex');
}
elsif ($FORM{command}) {
  osmp_payments();
}
#ipay new load
elsif (($FORM{xml} && $conf{PAYSYS_IPAY_FAST_PAY}) || check_ip($ENV{REMOTE_ADD}, '91.229.115.11')) {
  require Paysys::systems::Ipay;
  Paysys::systems::Ipay->import();
  my $Ipay = Paysys::systems::Ipay->new2(\%conf, \%FORM, undef, undef, $users,
    { HTML => $html, SELF_URL => $SELF_URL, DATETIME => "$DATE $TIME" });
  $Ipay->ipay_check_payments();
  exit;
}
#FIXME
elsif (check_ip($ENV{REMOTE_ADDR}, '192.168.1.168')) {
  require Paysys::systems::Plategka;
  Paysys::systems::Plategka->import();
  my $Plategka= Paysys::systems::Plategka->new(\%conf, \%FORM, $admin, $db, { HTML => $html });

  $Plategka->pay();
  exit;
}
elsif (check_ip($ENV{REMOTE_ADDR}, '62.149.15.210')){
  require Paysys::systems::City24;
  Paysys::systems::City24->import();
  my $City24= Paysys::systems::City24->new($db, $admin, \%conf);

  $City24->proccess(\%FORM);
  exit;
}
elsif (check_ip($ENV{REMOTE_ADDR}, '192.168.1.200')){
  require Paysys::systems::Osmp;
  Paysys::systems::Osmp->import();
  my $Osmp = Paysys::systems::Osmp->new($db, $admin, \%conf);

  $Osmp->proccess(\%FORM);

  exit;
}

#New module load method
#
#use FindBin '$Bin';
#my %systems_ips = ();
#my %systemS_params = ();
#
#my $modules_dir = $Bin."/../Abills/modules/Paysys/";
#$debug = 4;
#opendir DIR, $modules_dir or die "Can't open dir '$modules_dir' $!\n";
#    my @paysys_modules = grep  /\.pm$/  , readdir DIR;
#closedir DIR;
#
#for(my $i=0; $i<=$#paysys_modules; $i++) {
#  my $paysys_module = $paysys_modules[$i];
#  undef $system_ips;
#  undef $systems_ident_params;
#
#  print "$paysys_module";
#  require "$modules_dir$paysys_module";
#
#  my $pay_function = $paysys_module.'_payment';
#  if (! defined(&$pay_function)) {
#    print "Not found" if ($debug > 2);
#    next;
#   }
#
#  if ($debug > 3) {
#
#    if ($system_ips) {
#      my @ips = split(/,/, $system_ips);
#      foreach my $ip (@ips) {
#        $systems_ips{$ip}="$paysys_module"."_payment";
#       }
#     }
#    elsif (defined(%systems_ident_params)) {
#      while(my ($param, $function) = %systems_ident_params) {
#        $systemS_params{$param}="$paysys_module:$function";;
#       }
#     }
#
#    if (!$@) {
#      print "Loaded";
#     }
#    print "<br>\n";
#   }
#}

paysys_payments();

#**********************************************************
=head2  paysys_payments() - Make paysys payments

=cut
#**********************************************************
sub paysys_payments {

  if ($FORM{LMI_PAYMENT_NO}) {# || $FORM{LMI_HASH}) {
    wm_payments();
  }
  elsif ($FORM{userField_UID}) {
    load_pay_module('Rbkmoney');
    #print 'lol';
  }
  elsif ($FORM{id_ups}) {
    load_pay_module('Ukrpays');
  }
  elsif ($FORM{smsid}) {
    smsproxy_payments();
  }
  elsif ($FORM{sign}) {
    usmp_payments();
  }
  elsif ($FORM{lr_paidto}) {
    load_pay_module('Libertyreserve');
  }
  else {
    print "Content-Type: text/html\n\n";
    if ($FORM{INTERACT}) {
      interact_mode();
    }
    elsif (scalar keys %FORM > 0) {
      print "Error: Unknown payment system";
      mk_log($output2, { PAYSYS_ID => 'Unknown' });
    }
    else {
      $FORM{INTERACT} = 1;
      interact_mode();
    }
  }
}


#**********************************************************
#MerID=100000000918471
#OrderID=test00000001g5hg45h45
#AcqID=414963
#Signature=e2DkM6RYyNcn6+okQQX2BNeg/+k=
#ECI=5
#IP=217.117.65.41
#CountryBIN=804
#CountryIP=804
#ONUS=1
#Time=22/01/2007 13:56:38
#Signature2=nv7CcUe5t9vm+uAo9a52ZLHvRv4=
#ReasonCodeDesc=Transaction is approved.
#ResponseCode=1
#ReasonCode=1
#ReferenceNo=702308304646
#PaddedCardNo=XXXXXXXXXXXX3982
#AuthCode=073291
#**********************************************************
sub privatbank_payments {

  #Get order
  #my $status            = 0;
  my $payment_system = 'PBANK';
  my $payment_system_id = 48;
  my $order_id = $FORM{orderid};

  $db->{db}->{AutoCommit} = 0;
  $db->{TRANSACTION} = 1;

  my $list = $Paysys->list(
    {
      TRANSACTION_ID => "$payment_system:$order_id",
      STATUS         => 1,
      COLS_NAME      => 1
    }
  );

  if ($Paysys->{TOTAL} > 0) {
    if ($FORM{reasoncode} == 1) {
      my $uid = $list->[0]->{uid};
      my $sum = $list->[0]->{sum};
      my $user = $users->info($uid);

      cross_modules_call('_pre_payment', { USER_INFO => $user,
          SKIP_MODULES                               => 'Sqlcmd',
          QUITE                                      => 1
        });

      $payments->add(
        $user,
        {
          SUM          => $sum,
          DESCRIBE     => $payment_system,
          METHOD       =>
            ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
          EXT_ID       => "$payment_system:$order_id",
          CHECK_EXT_ID => "$payment_system:$order_id"
        }
      );

      #Exists
      if ($payments->{errno} && $payments->{errno} == 7) {
        $status = 8;
      }
      elsif ($payments->{errno}) {
        $status = 4;
      }
      else {
        $Paysys->change(
          {
            ID        => $list->[0]{id},
            PAYSYS_IP => $ENV{'REMOTE_ADDR'},
            INFO      =>
            "ReasonCode: $FORM{reasoncode}\n Authcode: $FORM{authcode}\n PaddedCardNo:$FORM{paddedcardno}\n ResponseCode: $FORM{responsecode}\n ReasonCodeDesc: $FORM{reasoncodedesc}\n IP: $FORM{IP}\n Signature:$FORM{signature}"
            ,
            STATUS    => 2
          }
        );

        cross_modules_call('_payments_maked', { USER_INFO => $user,
            SUM                                           => $sum,
            QUITE                                         => 1 });
      }

      if ($conf{PAYSYS_EMAIL_NOTICE}) {
        my $message = "\n" . "System: Privat Bank\n" . "DATE: $DATE $TIME\n" . "LOGIN: $user->{LOGIN} [$uid]\n" . "\n" . "\n" . "ID: $list->[0][0]\n" . "SUM: $sum\n";

        sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "Privat Bank Add", "$message", "$conf{MAIL_CHARSET}",
          "2 (High)");
      }
    }
    else {
      $status = 6;

      if ($FORM{reasoncode} == 36) {
        $status = 3;
      }

      $Paysys->change(
        {
          ID        => $list->[0]{id},
          PAYSYS_IP => $ENV{'REMOTE_ADDR'},
          INFO      => "ReasonCode: $FORM{reasoncode}. $FORM{reasoncodedesc} responsecode: $FORM{responsecode}",
          STATUS    => $status
        }
      );
    }
  }

  if (!$db->{db}->{AutoCommit}) {
    if ($status == 8) {
      $db->{db}->rollback();
    }
    else {
      $db->{db}->commit();
    }

    $db->{db}->{AutoCommit} = 1;
  }

  my $home_url = '/index.cgi';
  $home_url = $ENV{SCRIPT_NAME};
  $home_url =~ s/paysys_check.cgi/index.cgi/;

  if ($FORM{ResponseCode} == 1 || $FORM{responsecode} == 1) {
    print "Location: $home_url?PAYMENT_SYSTEM=48&orderid=$FORM{orderid}&TRUE=1" . "\n\n";
  }
  else {
    #print "Content-Type: text/html\n\n";
    #print "FAILED PAYSYS: Portmone SUM: $FORM{BILL_AMOUNT} ID: $FORM{SHOPORDERNUMBER} STATUS: $status";
    print "Location:$home_url?PAYMENT_SYSTEM=48&orderid=$FORM{orderid}&FALSE=1&reasoncodedesc=$FORM{reasoncodedesc}&reasoncode=$FORM{reasoncode}&responsecode=$FORM{responsecode}" . "\n\n";
  }

  exit;
}

#**********************************************************
=head2 osmp_payments($attr)

   OSMP
   Pegas
   TYPO 24

=cut
#**********************************************************
sub osmp_payments {
  my ($attr) = @_;

  if ($debug > 1) {
    print "Content-Type: text/plain\n\n";
  }

  my ($user, $password) = ('', '');

  if ($conf{PAYSYS_PEGAS_PASSWD}) {
    ($user, $password) = split(/:/, $conf{PAYSYS_PEGAS_PASSWD});
  }
  elsif ($conf{PAYSYS_OSMP_LOGIN}) {
    ($user, $password) = ($conf{PAYSYS_OSMP_LOGIN}, $conf{PAYSYS_OSMP_PASSWD});
  }

  if ($user && $password) {
    if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
      $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
      my ($REMOTE_USER, $REMOTE_PASSWD) = split(/:/, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));
      if ((!$REMOTE_PASSWD)
        || ($REMOTE_PASSWD && $REMOTE_PASSWD ne $password)
        || (!$REMOTE_USER)
        || ($REMOTE_USER && $REMOTE_USER ne $user)) {
        print "WWW-Authenticate: Basic realm=\"Billing system\"\n";
        print "Status: 401 Unauthorized\n";
        print "Content-Type: text/html\n\n";
        print "Access Deny";
        exit;
      }
    }
  }

  print "Content-Type: text/xml\n\n";

  my $payment_system = $attr->{SYSTEM_SHORT_NAME} || 'OSMP';
  my $payment_system_id = $attr->{SYSTEM_ID} || 44;
  my $CHECK_FIELD = $conf{PAYSYS_OSMP_ACCOUNT_KEY} || $attr->{CHECK_FIELDS} || 'UID';
  my $txn_id = 'osmp_txn_id';

  my %status_hash = (
    0   => 'Success',
    1   => 'Temporary DB error',
    4   => 'Wrong client indentifier',
    5   => 'User not exist', #'Failed witness a signature',
    6   => 'Unknown terminal',
    7   => 'Payments deny',

    8   => 'Double request',
    9   => 'Key Info mismatch',
    79  => 'Счёт абонента не активен',
    300 => 'Unknown error',
  );

  my %abills2osmp = (
    0  => 0, # Ok
    1  => 5, # Not exist user
    2  => 300, # sql error
    3  => 0, # dublicate payment
    5  => 300, # wrong sum
    11 => 7,
    13 => '0', # Paysys exist transaction
    30 => 4,   # No input
    #        => 90,  #Payments error
  );

  #For pegas
  if ($conf{PAYSYS_PEGAS} && $ENV{REMOTE_ADDR} ne '213.186.115.164') {
    $txn_id = 'txn_id';
    $payment_system = 'PEGAS';
    $payment_system_id = 49;
    $status_hash{5} = 'Неверный индентификатор абонента';
    $status_hash{243} = 'Невозможно проверитьсостояние счёта';
    $CHECK_FIELD = $conf{PAYSYS_PEGAS_ACCOUNT_KEY} || 'UID';

    if ($conf{PAYSYS_PEGAS_SELF_TERMINALS} && $FORM{terminal}) {
      if ($conf{PAYSYS_PEGAS_SELF_TERMINALS} =~ /$FORM{terminal}/) {
        $payment_system_id = 80;
        $payment_system = 'PST';
      }
    }
  }

  #my $comments = '';
  my $command = $FORM{command};

  #  if ($FORM{account} && $CHECK_FIELD eq 'UID') {
  #    $FORM{account} =~ s/^0+//g;
  #  }
  #  elsif ($FORM{account} && $CHECK_FIELD eq 'LOGIN' && $conf{PAYSYS_OSMP_ACCOUNT_RULE}) {
  #    $FORM{account} = sprintf($conf{PAYSYS_OSMP_ACCOUNT_RULE},$FORM{account}) ;
  #  }

  my %RESULT_HASH = (result => 300);
  my $results = '';

  mk_log("$payment_system: $ENV{QUERY_STRING}") if ($debug > 0);
  #Check user account
  #https://service.someprovider.ru:8443/paysys_check.cgi?command=check&txn_id=1234567&account=0957835959&sum=10.45
  if ($command eq 'check') {
    my ($result_code, $list) = paysys_check_user({
      CHECK_FIELD => $CHECK_FIELD,
      USER_ID     => $FORM{account},
      DEBUG       => $debug,
      SKIP_DEPOSIT_CHECK => 1
    });

    $status = ($abills2osmp{$result_code}) ? $abills2osmp{$result_code} : 0;

    $RESULT_HASH{result} = $status;

    if ($result_code == 11) {
      $RESULT_HASH{disable_paysys} = 1;
    }

    # Qiwi testing, check if exist param sum
    if (!$FORM{sum}) {
      $RESULT_HASH{result} = 300;
    }

    # Qiwi testing, account regexp check
    if ($conf{PAYSYS_OSMP_ACCOUNT_REXEXP} && ($FORM{account} !~ $conf{PAYSYS_OSMP_ACCOUNT_REXEXP})) {
      $RESULT_HASH{result} = 4;
    }

    #For OSMP
    # old code for standart osmp inheritance
    # if ( $payment_system_id == 44 ){

    # new code for standart osmp inheritance
    if (!$conf{PAYSYS_PEGAS} && !$conf{PAYSYS_OSMP_EXT_PARAMS}) {
      $RESULT_HASH{$txn_id} = $FORM{txn_id};
      $RESULT_HASH{prv_txn} = $FORM{prv_txn};
      $RESULT_HASH{comment} = "Balance: $list->{deposit} $list->{fio} " if ($status == 0);
    }
    #For pegas
    elsif ($conf{PAYSYS_PEGAS}) {
      $RESULT_HASH{$txn_id} = $FORM{txn_id};
      $RESULT_HASH{prv_txn} = $FORM{prv_txn} if ($FORM{prv_txn});
      $RESULT_HASH{balance} = "$list->{deposit}";
      $RESULT_HASH{fio} = "$list->{fio}";
    }
    #Use Extra params
    elsif ($conf{PAYSYS_OSMP_EXT_PARAMS}) {
      if ($payment_system_id == 99 || $payment_system_id == 67) {
        my @arr = split(/,[\r\n\s]?/, $conf{PAYSYS_OSMP_EXT_PARAMS});
        my $i = 1;
        foreach my $param  (@arr) {
          $RESULT_HASH{'fields'}{"field" . $i . " name='$param'"} = $FORM{$param} || $list->{$param};
          $i++;
        }
      }
      else {
        my @arr = split(/,[\r\n\s]?/, $conf{PAYSYS_OSMP_EXT_PARAMS});
        foreach my $param  (@arr) {
          $RESULT_HASH{$param} = $FORM{$param} || $list->{$param};
        }
        # add 'osmp_txn_id' param with txn_id value
        $RESULT_HASH{$txn_id} = $FORM{txn_id}
      }
    }
    # extra info tag
    if ($conf{PAYSYS_OSMP_EXTRA_INFO}) {
      $RESULT_HASH{'extra_info'}{'deposit'} = $list->{'deposit'};
      $RESULT_HASH{'extra_info'}{'fee'} = $list->{'fee'};

      if(in_array('Internet', \@MODULES)){
        use Internet;
        require Internet::Service_mng;

        my $Internet = Internet->new($db, $admin, \%conf);
        $Internet->info($list->{uid});
        my $Service = Internet::Service_mng->new({ lang => \%lang });

        my ($message, $type) = $Service->service_warning({
          SERVICE => $Internet,
          USER    => $list,
          DATE    => $DATE
        });

        if($message){
          my ($date) = $message =~ /(\d{4}\-\d{2}\-\d{2})/gm;
          ($RESULT_HASH{'extra_info'}{'next_fee_date'}) = $date,
        }
      };


      if (in_array('Dv', \@MODULES)) {
        load_module('Dv');
        my ($message, undef) = dv_warning({ USER => $list });
        my ($date, $sum) = (defined $message && $message ne '') ? split("\n", $message) : ('no date', '');
        ($RESULT_HASH{'extra_info'}{'next_fee_date'}) = $date =~ /\((\d{4}-\d{2}-\d{2})\)/g;
      }
    }
  }
  #Cancel payments
  elsif ($command eq 'cancel') {
    my $prv_txn = $FORM{prv_txn};
    $RESULT_HASH{prv_txn} = $prv_txn;

    my $cancel_result = paysys_pay_cancel({
      PAYSYS_ID      => $prv_txn,
      TRANSACTION_ID => "$payment_system:*"
    });

    $RESULT_HASH{result} = $cancel_result;

#    my $list = $payments->list({ ID => "$prv_txn",
#      EXT_ID                        => "$payment_system:*",
#      BILL_ID                       => '_SHOW',
#      COLS_NAME                     => 1 });
#
#    if ($payments->{errno} && $payments->{errno} != 7) {
#      $RESULT_HASH{result} = 1;
#    }
#    elsif ($payments->{TOTAL} < 1) {
#      if ($conf{PAYSYS_PEGAS}) {
#        $RESULT_HASH{result} = 0;
#      }
#      else {
#        $RESULT_HASH{result} = 79;
#      }
#    }
#    else {
#      my %user = (
#        BILL_ID => $list->{bill_id},
#        UID     => $list->{uid}
#      );
#
#      $payments->del(\%user, $prv_txn);
#      if (!$payments->{errno}) {
#        $RESULT_HASH{result} = 0;
#      }
#      else {
#        $RESULT_HASH{result} = 1;
#      }
#    }
  }
  # ?command=verify&date=20050815
  elsif ($command eq 'verify') {
    $FORM{DATE} =~ /(\d{4}\d{2}\d{2})/;

    #my $date = "$1-$2-$3";
    my $list = $payments->list({
      EXT_ID       => "$payment_system:*",
      BILL_ID      => '_SHOW',
      $CHECK_FIELD => '_SHOW',
      SUM          => '_SHOW',
      DATETIME     => '_SHOW',
      COLS_NAME    => 1 });

    #my $content = '';
    foreach my $line (@{$list}) {
      my $txt_id = $line->{ext_id};
      $txt_id =~ s/$payment_system://g;
      my $date_ = date_format($line->{datetime}, "%d.%m.%Y %H:%M:%S");
      my $user_id = $line->{lc($CHECK_FIELD)};
      $RESULT_HASH{verify} .= qq{ <payment txn_id="$txt_id" prv_txn="$line->{id}" account="$user_id" amount="$line->{sum}" date="$date_"/> };
    }

    $RESULT_HASH{result} = 0;
  }
  # command=balance
  elsif ($command eq 'balance') {

  }
  #https://service.someprovider.ru:8443/payment_app.cgi?command=pay&txn_id=1234567&txn_date=20050815120133&account=0957835959&sum=10.45
  elsif ($command eq 'pay') {
    if ($conf{PAYSYS_OSMP_TXN_DATE} && $FORM{txn_date} =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/) {
      $DATE = "$1-$2-$3";
      $TIME = "$3-$5-$6";
    }

    my ($status_code, $payments_id) = paysys_pay({
      PAYMENT_SYSTEM    => $payment_system,
      PAYMENT_SYSTEM_ID => $payment_system_id,
      CHECK_FIELD       => $CHECK_FIELD,
      USER_ID           => $FORM{account},
      SUM               => $FORM{sum},
      EXT_ID            => $FORM{txn_id},
      DATA              => \%FORM,
      DATE              => "$DATE $TIME",
      CURRENCY_ISO      => $conf{PAYSYS_OSMP_CURRENCY},
      MK_LOG            => 1,
      PAYMENT_ID        => 1,
      DEBUG             => $debug,
      PAYMENT_DESCRIBE  => $FORM{payment_describe} || '',
    });

    # Qiwi testing, check if exist param sum
    if (!$FORM{sum}) {
      $status_code = 5;
    }

    $status = (defined($abills2osmp{$status_code})) ? $abills2osmp{$status_code} : 90;

    $RESULT_HASH{result} = $status;
    $RESULT_HASH{$txn_id} = $FORM{txn_id};
    $RESULT_HASH{prv_txn} = $payments_id;
    $RESULT_HASH{sum} = $FORM{sum};
  }

  #Result output
  $RESULT_HASH{comment} = $status_hash{ $RESULT_HASH{result} } if ($RESULT_HASH{result} && !$RESULT_HASH{comment});

  while (my ($k, $v) = each %RESULT_HASH) {
    if (ref $v eq "HASH") {
      $results .= "<$k>\n";
      while (my ($key, $value) = each %$v) {
        my ($end_key, undef) = split(" ", $key);
        $results .= "<$key>$value</$end_key>\n";
      }
      $results .= "</$k>\n";
    }
    else {
      $results .= "<$k>$v</$k>\n";
    }
  }

  chomp($results);

  my $response = qq{<?xml version="1.0" encoding="UTF-8"?>
<response>
$results
</response>
};

  print $response;
  if ($debug > 0) {
    mk_log("$response", { PAYSYS_ID => "$attr->{SYSTEM_ID}/$attr->{SYSTEM_SHORT_NAME}" });
  }

  exit;
}

#**********************************************************
=head2 osmp_payments_v4($attr)

   OSMP Ver.4
   Elsom

=cut
#**********************************************************
sub osmp_payments_v4 {
  my ($attr) = @_;

  my $version = '0.3';
  $debug = $conf{PAYSYS_DEBUG} || 0;
  print "Content-Type: text/xml\n\n";

  my $payment_system = $attr->{SYSTEM_SHORT_NAME} || 'OSMP';
  my $payment_system_id = $attr->{SYSTEM_ID} || 61;

  my $CHECK_FIELD = $conf{PAYSYS_OSMP_ACCOUNT_KEY} || 'UID';
  $FORM{__BUFFER} = '' if (!$FORM{__BUFFER});
  $FORM{__BUFFER} =~ s/data=//;

  load_pmodule('XML::Simple');

  $FORM{__BUFFER} =~ s/encoding="windows-1251"//g;
  my $_xml = eval {XML::Simple::XMLin("$FORM{__BUFFER}", forcearray => 1)};

  if ($@) {
    mk_log("---- Content:\n" . $FORM{__BUFFER} . "\n----XML Error:\n" . $@ . "\n----\n");

    return 0;
  }
  else {
    if ($debug == 1) {
      mk_log($FORM{__BUFFER});
    }
  }

  my %request_hash = ();
  my $status_id = 30;
  my $result_code = 0;
  my $service_id = 0;
  my $response = '';

  my $BALANCE = 0.00;
  my $OVERDRAFT = 0.00;
  my $txn_date = "$DATE$TIME";
  $txn_date =~ s/[-:]//g;
  my $txn_id = 0;

  $request_hash{'protocol-version'} = $_xml->{'protocol-version'}->[0];
  $request_hash{'request-type'} = $_xml->{'request-type'}->[0] || 0;
  $request_hash{'terminal-id'} = $_xml->{'terminal-id'}->[0];
  $request_hash{'login'} = $_xml->{'extra'}->{'login'}->{'content'};
  $request_hash{'password'} = $_xml->{'extra'}->{'password'}->{'content'};
  $request_hash{'password-md5'} = $_xml->{'extra'}->{'password-md5'}->{'content'};
  $request_hash{'client-software'} = $_xml->{'extra'}->{'client-software'}->{'content'};
  my $transaction_number = $_xml->{'transaction-number'}->[0] || '';

  $request_hash{'to'} = $_xml->{to};

  # Check password
  if ($request_hash{'password-md5'}) {
    $md5->reset;
    $md5->add($conf{PAYSYS_OSMP_PASSWD});
    $conf{PAYSYS_OSMP_PASSWD} = lc($md5->hexdigest());
  }
  # Check osmp login
  if ($conf{PAYSYS_OSMP_LOGIN} ne $request_hash{'login'}
    || ($request_hash{'password-md5'} && $conf{PAYSYS_OSMP_PASSWD} ne $request_hash{'password-md5'})) {
    $status_id = 150;
    $result_code = 1;

    $response = qq{
<txn-date>$txn_date</txn-date>
<status-id>$status_id</status-id>
<txn-id>$txn_id</txn-id>
<result-code>$result_code</result-code>
};
  }
  elsif (defined($_xml->{'status'})) {
    my $count = $_xml->{'status'}->[0]->{count};
    my @payments_arr = ();
    my %payments_status = ();

    for (my $i = 0; $i < $count; $i++) {
      push @payments_arr, $_xml->{'status'}->[0]->{'payment'}->[$i]->{'transaction-number'}->[0];
    }

    my $ext_ids = "'$payment_system:" . join("', '$payment_system:", @payments_arr) . "'";
    my $list = $payments->list({ EXT_IDS => $ext_ids, PAGE_ROWS => 100000 });

    if ($payments->{errno}) {
      $status_id = 78;
    }
    else {
      foreach my $line (@{$list}) {
        my $ext = $line->[7];
        $ext =~ s/$payment_system://g;
        $payments_status{$ext} = $line->[0];
      }

      foreach my $id (@payments_arr) {
        if ($id < 1) {
          $status_id = 160;
        }
        elsif ($payments_status{$id}) {
          $status_id = 60;
        }
        else {
          $status_id = 10;
        }

        $response .= qq{
<payment transaction-number="$id" status="$status_id" result-code="0" final-status="true" fatal-error="true">
</payment>\n };
      }
    }
  }

  #User info
  elsif ($request_hash{'request-type'} == 1) {
    my $to = $request_hash{'to'}->[0];
    my $amount = $to->{'amount'}->[0];
    my $sum = $amount->{'content'};
    #my $currency = $amount->{'currency-code'};
    my $account_number = $to->{'account-number'}->[0];
    $service_id = $to->{'service-id'}->[0];
    #my $receipt_number = $_xml->{receipt}->[0]->{'receipt-number'}->[0];

    my $user;

    #    if ( $account_number !~ /$conf{USERNAMEREGEXP}/ ){
    #      $status_id = 4;
    #      $result_code = 1;
    #    }
    #    elsif ( $CHECK_FIELD eq 'UID' ){
    #      $user = $users->info( $account_number );
    #      $BALANCE = sprintf( "%2.f", $user->{DEPOSIT} );
    #      $OVERDRAFT = $user->{CREDIT};
    #    }
    #    else{
    #      my $list = $users->list( { $CHECK_FIELD => $account_number,
    #                                 DEPOSIT   => '_SHOW',
    #                                 CREDIT    => '_SHOW',
    #                                 FIO       => '_SHOW',
    #                                 COLS_NAME => 1
    #                              } );
    #
    #      if ( !$users->{errno} && $users->{TOTAL} > 0 ){
    #        my $uid = $list->[0]->{uid};
    #        $user = $users->info( $uid );
    #        $BALANCE = sprintf( "%2.f", $user->{deposit} );
    #        $OVERDRAFT = $user->{credit};
    #      }
    #    }
    #
    #    if ( $users->{errno} ){
    #      $status_id = 79;
    #      $result_code = 1;
    #    }
    #    elsif ( $users->{TOTAL} < 1 ){
    #      $status_id = 5;
    #      $result_code = 1;
    #    }

    ($result_code, $user) = paysys_check_user({
      CHECK_FIELD => $CHECK_FIELD,
      USER_ID     => $account_number,
    });
    my $fio = convert(($user->{FIO} || ''), { utf82win => 1});

    if($result_code == 1){
      $result_code = 5;
      $status_id   = 10;
    }

    $response = qq{<txn-date>$txn_date</txn-date>
<status-id>$status_id</status-id>
<txn-id>$txn_id</txn-id>
<result-code>$result_code</result-code>
<from>
<service-id>$service_id</service-id>
<account-number>$account_number</account-number>
</from>
<to>
<service-id>1</service-id>
<amount>$sum</amount>
<account-number>$account_number</account-number>
</to>
<extra name="FIO">$fio</extra>
<extra name="disp1">$fio</extra>};
  }
  # Payments
  elsif ($request_hash{'request-type'} == 2) {
    my $to = $request_hash{'to'}->[0];
    my $amount = $to->{'amount'}->[0];
    my $sum = $amount->{'content'};
    #my $currency = $amount->{'currency-code'};
    my $account_number = $to->{'account-number'}->[0];
    $service_id = $to->{'service-id'}->[0];
    my $receipt_number = $_xml->{receipt}->[0]->{'receipt-number'}->[0];

    $txn_id = 0;
#    my $user;
#    my $payments_id = 0;
    my ($status_code, $payments_id) = paysys_pay({
      PAYMENT_SYSTEM    => $payment_system,
      PAYMENT_SYSTEM_ID => $payment_system_id,
      CHECK_FIELD       => $CHECK_FIELD,
      USER_ID           => $account_number,
      SUM               => $sum,
      EXT_ID            => $receipt_number,
      DATA              => \%FORM,
      DATE              => "$DATE $TIME",
#      CURRENCY_ISO      => $conf{PAYSYS_OSMP_CURRENCY},
      MK_LOG            => 1,
      PAYMENT_ID        => 1,
      DEBUG             => $debug,
      PAYMENT_DESCRIBE  => $FORM{payment_describe} || '',
    });

    $status_id = ($status_code == 0 || $status_code == 13) ? 60 : 160;
    $result_code = ($status_code == 0 || $status_code == 13) ? 0 : 160;
#    if ($CHECK_FIELD eq 'UID') {
#      $user = $users->info($account_number);
#      $BALANCE = sprintf("%2.f", $user->{DEPOSIT});
#      $OVERDRAFT = $user->{CREDIT};
#    }
#    else {
#      my $list = $users->list({ $CHECK_FIELD => $account_number });
#
#      if (!$users->{errno} && $users->{TOTAL} > 0) {
#        my $uid = $list->[0]->[ 5 + $users->{SEARCH_FIELDS_COUNT} ];
#        $user = $users->info($uid);
#        $BALANCE = sprintf("%2.f", $user->{DEPOSIT});
#        $OVERDRAFT = $user->{CREDIT};
#      }
#    }
#
#    if ($users->{errno}) {
#      $status_id = 79;
#      $result_code = 1;
#    }
#    elsif ($users->{TOTAL} < 1) {
#      $status_id = 5;
#      $result_code = 1;
#    }
#    else {
#      cross_modules_call('_pre_payment', { USER_INFO => $user, QUITE => 1, SUM => $sum });
#      #Add payments
#      $payments->add(
#        $user,
#        {
#          SUM          => $sum,
#          DESCRIBE     => "$payment_system",
#          METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{44}) ? 44 : '2',
#          EXT_ID       => "$payment_system:$transaction_number",
#          CHECK_EXT_ID => "$payment_system:$transaction_number"
#        }
#      );
#
#      cross_modules_call('_payments_maked', { USER_INFO => $user, SUM => $sum, QUITE => 1 });
#
#      #Exists
#      if ($payments->{errno} && $payments->{errno} == 7) {
#        $status_id = 10;
#        $result_code = 1;
#        $payments_id = $payments->{ID};
#      }
#      elsif ($payments->{errno}) {
#        $status_id = 78;
#        $result_code = 1;
#      }
#      else {
#        $Paysys->add(
#          {
#            SYSTEM_ID      => $payment_system_id,
#            DATETIME       => "$DATE $TIME",
#            SUM            => "$sum",
#            UID            => "$user->{UID}",
#            IP             => '0.0.0.0',
#            TRANSACTION_ID => "$payment_system:$transaction_number",
#            INFO           => " STATUS: $status_id RECEIPT Number: $receipt_number",
#            PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
#          }
#        );
#
#        $payments_id = ($Paysys->{INSERT_ID}) ? $Paysys->{INSERT_ID} : 0;
#        $txn_id = $payments_id;
#      }
#    }

    $response = qq{
<txn-date>$txn_date</txn-date>
<txn-id>$payments_id</txn-id>
<result-code>$result_code</result-code>
<receipt>
<datetime>0</datetime>
</receipt>
<from>
<service-id>$service_id</service-id>
<amount>$sum</amount>
<account-number>$account_number</account-number>
</from>
<to>
<service-id>$service_id</service-id>
<amount>$sum</amount>
<account-number>$account_number</account-number>
</to>
}
  }
  # Cancel payment
  elsif ($request_hash{'request-type'} == 3) {
    my $result = paysys_pay_cancel({
      TRANSACTION_ID => "$payment_system:$transaction_number"
    });
    `echo "RESULT - $result" >> /tmp/buffer`;
    my $output = qq{
    <?xml version="1.0" encoding="windows-1251"?>
    <response>
<protocol-version>4.00</protocol-version>
<request-type>3</request-type>
<terminal-id>$request_hash{'terminal-id'}</terminal-id>
<result-code>$result</result-code>
<status-id>60</status-id>
<transaction-number>$transaction_number</transaction-number>
</response>
    };
    print $output;

    if ($debug > 0) {
      mk_log("RESPONSE:\n" . $output);
    }

    return 1;
  }
  # Pack processing
  elsif ($request_hash{'request-type'} == 10) {
    my $count = $_xml->{auth}->[0]->{count};
    #my $final_status = '';
    my $fatal_error = '';
    my $payments_id;
    for (my $i = 0; $i < $count; $i++) {
      %request_hash = %{ $_xml->{auth}->[0]->{payment}->[$i] };
      my $to = $request_hash{'to'}->[0];
      $transaction_number = $request_hash{'transaction-number'}->[0] || '';

      #    my $amount         = $to->{'amount'}->[0];
      my $sum = $to->{'amount'}->[0];

      #    my $currency       = $amount->{'currency-code'};
      my $account_number = $to->{'account-number'}->[0];
      $service_id = $to->{'service-id'}->[0];
      my $receipt_number = $_xml->{receipt}->[0]->{'receipt-number'}->[0];

      if ($CHECK_FIELD eq 'UID') {
        $user = $users->info($account_number);
        $BALANCE = sprintf("%2.f", $user->{DEPOSIT});
        $OVERDRAFT = $user->{CREDIT};
      }
      else {
        my $list = $users->list({ $CHECK_FIELD => $account_number });

        if (!$users->{errno} && $users->{TOTAL} > 0) {
          my $uid = $list->[0]->[ 5 + $users->{SEARCH_FIELDS_COUNT} ];
          $user = $users->info($uid);
          $BALANCE = sprintf("%2.f", $user->{DEPOSIT});
          $OVERDRAFT = $user->{CREDIT};
        }
      }

      if ($users->{errno}) {
        $status_id = 79;
        $result_code = 1;
      }
      elsif ($users->{TOTAL} < 1) {
        $status_id = 0;
        $result_code = 0;
      }
      else {
        cross_modules_call('_pre_payment',
          {
            USER_INFO => $user,
            SUM       => $FORM{PAY_AMOUNT},
            QUITE     => 1
          }
        );

        #Add payments
        $payments->add(
          $user,
          {
            SUM          => $sum,
            DESCRIBE     => "$payment_system",
            METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{44}) ? 44 : '2',
            EXT_ID       => "$payment_system:$transaction_number",
            CHECK_EXT_ID => "$payment_system:$transaction_number"
          }
        );

        #Exists
        if ($payments->{errno} && $payments->{errno} == 7) {
          $status_id = 10;
          $result_code = 1;
          $payments_id = $payments->{ID};
        }
        elsif ($payments->{errno}) {
          $status_id = 78;
          $result_code = 1;
        }
        else {
          $Paysys->add(
            {
              SYSTEM_ID      => $payment_system_id,
              DATETIME       => "$DATE $TIME",
              SUM            => "$sum",
              UID            => "$user->{UID}",
              IP             => '0.0.0.0',
              TRANSACTION_ID => "$payment_system:$transaction_number",
              INFO           => " STATUS: $status_id RECEIPT Number: $receipt_number",
              PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
            }
          );

          $payments_id = ($Paysys->{INSERT_ID}) ? $Paysys->{INSERT_ID} : 0;
          $txn_id = $payments_id;
          $status_id = 51;
        }
      }

      $fatal_error = ($status_id != 51 && $status_id != 0) ? 'true' : 'false';
      $response .= qq{
<payment status="$status_id" transaction-number="$transaction_number" result-code="$result_code" final-status="true"fatal-error="$fatal_error">
<to>
<service-id>$service_id</service-id>
<amount>$sum</amount>
<account-number>$account_number</account-number>
</to>
</payment>

};

    }
  }

  my $output = qq{<?xml version="1.0" encoding="windows-1251"?>
<response requestTimeout="60">
<protocol-version>4.00</protocol-version>
<configuration-id>0</configuration-id>
<request-type>$request_hash{'request-type'}</request-type>
<terminal-id>$request_hash{'terminal-id'}</terminal-id>
<transaction-number>$transaction_number</transaction-number>
<status-id>$status_id</status-id>
};

  $output .= $response . qq{
<extra name="REMOTE_ADDR">$ENV{REMOTE_ADDR}</extra>
<extra name="client-software">ABillS Paysys $payment_system $version</extra>
<extra name="version-conf">$version</extra>
<extra name="serial">$version</extra>
<extra name="BALANCE">$BALANCE</extra>
<extra name="OVERDRAFT">$OVERDRAFT</extra>
<operator-id>$admin->{AID}</operator-id>
</response>};

  print $output;

  if ($debug > 0) {
    mk_log("RESPONSE:\n" . $output);
  }

  return $status_id;
}

#**********************************************************
=head2 smsproxy_payments()

  Request:
    https//demo.abills.net.ua:9443/paysys_check.cgi?skey=827ccb0eea8a706c4c34a16891f84e7b&smsid=1208992493215&num=1171&operator=Tester&user_id=1234567890&cost=1.5&msg=%20Test_messages

=cut
#**********************************************************
sub smsproxy_payments {

  my $sms_num = $FORM{num} || 0;
  my $cost = $FORM{cost_rur} || 0;
  my $skey = $FORM{skey} || '';
  #my $prefix = $FORM{prefix} || '';

  my %prefix_keys = ();
  my $service_key = '';

  if ($conf{PAYSYS_SMSPROXY_KEYS} && $conf{PAYSYS_SMSPROXY_KEYS} =~ /:/) {
    my @keys_arr = split(/,/, $conf{PAYSYS_SMSPROXY_KEYS});

    foreach my $line (@keys_arr) {
      my ($num, $key) = split(/:/, $line);
      if ($num eq $sms_num) {
        $prefix_keys{$num} = $key;
        $service_key = $key;
      }
    }
  }
  else {
    $prefix_keys{$sms_num} = $conf{PAYSYS_SMSPROXY_KEYS};
    $service_key = $conf{PAYSYS_SMSPROXY_KEYS};
  }

  $md5->reset;
  $md5->add($service_key);
  my $digest = $md5->hexdigest();

  print "smsid: $FORM{smsid}\n";

  if ($digest ne $skey) {
    print "status:reply\n";
    print "content-type: text/plain\n\n";
    print "Wrong key!\n";
    return 0;
  }

  my $code = mk_unique_value(8);

  #Info section
  my ($transaction_id) = split(/\./, $FORM{smsid}, 2);

  my $er = 1;
  $payments->exchange_info(0, { SHORT_NAME => "SMSPROXY" });
  if ($payments->{TOTAL} > 0) {
    $er = $payments->{ER_RATE};
  }

  if ($payments->{errno}) {
    print "status:reply\n";
    print "content-type: text/plain\n\n";
    print "PAYMENT ERROR: $payments->{errno}!\n";
    return 0;
  }

  $Paysys->add(
    {
      SYSTEM_ID      => 43,
      DATETIME       => "$DATE $TIME",
      SUM            => "$cost",
      UID            => "",
      IP             => "0.0.0.0",
      TRANSACTION_ID => "$transaction_id",
      INFO           => "ID: $FORM{smsid}, NUM: $FORM{num}, OPERATOR: $FORM{operator}, USER_ID: $FORM{user_id}",
      PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
      CODE           => $code
    }
  );

  if ($Paysys->{errno} && $Paysys->{errno} == 7) {
    print "status:reply\n";
    print "content-type: text/plain\n\n";
    print "Request dublicated $FORM{smsid}\n";
    return 0;
  }

  print "status:reply\n";
  print "content-type: text/plain\n\n";
  print $conf{PAYSYS_SMSPROXY_MSG} if ($conf{PAYSYS_SMSPROXY_MSG});
  print " CODE: $code";

  return 1;
}

#**********************************************************
=head2 paymaster_check_payment($attr)

=cut
#**********************************************************
sub paymaster_check_payment {
  #my ($attr) = @_;

  wm_payments({ SYSTEM_SHORT_NAME => 'PMASTER',
    SYSTEM_ID                     => 97
  });

  return 1;
}

#**********************************************************
=head2 wm_payments($attr) - Webmoney payments

   https://merchant.webmoney.ru/conf/guide.asp

=cut
#**********************************************************
sub wm_payments {
  my ($attr) = @_;

  my $payment_system = $attr->{SYSTEM_SHORT_NAME} || (($conf{PAYSYS_WEBMONEY_UA}) ? 'WMU' : 'WM');
  my $payment_system_id = $attr->{SYSTEM_ID} || (($conf{PAYSYS_WEBMONEY_UA}) ? 96 : 41);
  my $status_code = 0;
  my $output_content = '';

  print "Content-Type: text/html\n\n";

  #Pre request section
  if ($FORM{'LMI_PREREQUEST'} && $FORM{'LMI_PREREQUEST'} == 1) {
    $output_content = "YES";
  }
  #Payment notification
  elsif ($FORM{LMI_HASH}) {
    conf_gid_split({ GID => 0,
      PARAMS             => [
        'PAYSYS_LMI_SECRET_KEY',
        'PAYSYS_WEBMONEY_ACCOUNTS',
      ],
      SERVICE2GID        => $conf{PAYSYS_WEBMONEY_SERVICE2GID},
      SERVICE            => $FORM{LMI_MERCHANT_ID}
    });

    my $checksum = ($conf{PAYSYS_WEBMONEY_UA}) ? wm_ua_validate() : wm_validate();

    my @ACCOUNTS = split(/;/, $conf{PAYSYS_WEBMONEY_ACCOUNTS});

    if ($payment_system_id < 97 && !in_array($FORM{LMI_PAYEE_PURSE}, \@ACCOUNTS)) {
      $status = 'Not valid money account';
      $status_code = 14;
    }
    elsif (defined($FORM{LMI_MODE1}) && $FORM{LMI_MODE} == 1) {
      $status = 'Test mode';
      $status_code = 12;
    }
    elsif (length($FORM{LMI_HASH}) < 32) {
      $status = 'Not MD5 checksum' . $FORM{LMI_HASH};
      $status_code = 5;
    }
    elsif ($FORM{LMI_HASH} ne $checksum) {
      $status = "Incorect checksum '$checksum/$FORM{LMI_HASH}'";
      $status_code = 5;
    }

    my $payment_unit = '';
    if ($FORM{LMI_PAYEE_PURSE} =~ /^(\S)/) {
      $payment_unit = 'WM' . $1;
    }

    $status_code = paysys_pay({
      PAYMENT_SYSTEM    => $payment_system,
      PAYMENT_SYSTEM_ID => $payment_system_id,
      CHECK_FIELD       => 'UID',
      USER_ID           => $FORM{UID},
      SUM               => $FORM{LMI_PAYMENT_AMOUNT},
      EXT_ID            => $FORM{LMI_PAYMENT_NO},
      IP                => $FORM{IP},
      DATA              => \%FORM,
      MK_LOG            => 1,
      ERROR             => $status_code,
      CURRENCY          => $payment_unit,
      DEBUG             => $debug
    });
  }

  print $output_content;

  mk_log($output_content . "\nSTATUS CODE: $status_code/$status",
    { PAYSYS_ID => "$payment_system/$payment_system_id" });

  return 1;
}

#**********************************************************
=head2 wm_validate() - Webmoney MD5 validate check sum

=cut
#**********************************************************
sub wm_validate {

  my $digest;

  if (length($FORM{LMI_HASH}) == 32) {
    $md5->reset;
    $md5->add($FORM{LMI_PAYEE_PURSE});
    $md5->add($FORM{LMI_PAYMENT_AMOUNT});
    $md5->add($FORM{LMI_PAYMENT_NO});
    $md5->add($FORM{LMI_MODE});
    $md5->add($FORM{LMI_SYS_INVS_NO});
    $md5->add($FORM{LMI_SYS_TRANS_NO});
    $md5->add($FORM{LMI_SYS_TRANS_DATE});
    $md5->add($conf{PAYSYS_LMI_SECRET_KEY});

    #$md5->add($FORM{LMI_SECRET_KEY});
    $md5->add($FORM{LMI_PAYER_PURSE});
    $md5->add($FORM{LMI_PAYER_WM});

    $digest = uc($md5->hexdigest());
  }
  else {
    load_pmodule('Digest::SHA', { IMPORT => 'sha256_hex' });

    my $sign_string = $FORM{LMI_PAYEE_PURSE} .
      $FORM{LMI_PAYMENT_AMOUNT} .
      $FORM{LMI_PAYMENT_NO} .
      $FORM{LMI_MODE} .
      $FORM{LMI_SYS_INVS_NO} .
      $FORM{LMI_SYS_TRANS_NO} .
      $FORM{LMI_SYS_TRANS_DATE} .
      $conf{PAYSYS_LMI_SECRET_KEY} .
      $FORM{LMI_PAYER_PURSE} .
      $FORM{LMI_PAYER_WM};

    $digest = uc(sha256_hex($sign_string));
  }

  return $digest;
}

#**********************************************************
=head2 wm_ua_validate() - validate wm ua  for paymaster

=cut
#**********************************************************
sub wm_ua_validate {
  $md5->reset;

  $md5->add($FORM{LMI_MERCHANT_ID});
  $md5->add($FORM{LMI_PAYMENT_NO});
  $md5->add($FORM{LMI_SYS_PAYMENT_ID});
  $md5->add($FORM{LMI_SYS_PAYMENT_DATE});
  $md5->add($FORM{LMI_PAYMENT_AMOUNT});
  $md5->add($FORM{LMI_PAID_AMOUNT});
  $md5->add($FORM{LMI_PAYMENT_SYSTEM});
  $md5->add($FORM{LMI_MODE});
  $md5->add($conf{PAYSYS_PAYMASTER_SECRET});

  my $digest = uc($md5->hexdigest());

  return $digest;
}


#**********************************************************
=head2 interact_mode() - Interactive mode

=cut
#**********************************************************
sub interact_mode {

  do "../language/$html->{language}.pl";

  load_module('Paysys', $html);

  $html->{NO_PRINT} = 1;
  $LIST_PARAMS{UID} = $FORM{UID};

  print paysys_payment();
  print $html->{OUTPUT} if $FORM{TRUE}; # showing payments result output
}

#**********************************************************
=head2 load_pay_module($name, $attr) - Load pay module

  Arguments:
    $name  - Paymodule name
    $attr  - Attributes
      SYS_PARAMS - System params

  Returns:

=cut
#**********************************************************
sub load_pay_module {
  my ($name, $attr) = @_;

  eval {require "Paysys/" . $name . ".pm"};

  if ($@) {
    print "Content-Type: text/plain\n\n";
    my $res = "Error: load module '" . $name . ".pm' \n $!  \n" .
      "Purchase module from http://abills.net.ua/ \n";

    print $@ if ($conf{PAYSYS_DEBUG});
    mk_log($res);

    return 0;
  }

  if ($name =~ /^\d/) {
    $name = '_' . $name;
  }

  my $function = lc($name) . '_check_payment';
  if (defined(&{$function})) {
    if ($debug > 3) {
      print 'Module: ' . $name . '.pm' . " Function: $function\n";
    }
    &{ \&{$function} }($attr->{SYS_PARAMS});
  }

  exit;
  return 1;
}

#***********************************************************
=head2 get_request_info()

=cut
#***********************************************************
sub get_request_info {
  my $info = '';

  while (my ($k, $v) = each %FORM) {
    $info .= "$k => $v\n" if ($k ne '__BUFFER');
  }

  return $info;
}

#**********************************************************
=head2 new_load_pay_module() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub new_load_pay_module {
  my ($name, $attr) = @_;

  eval {require "Paysys/systems/" . $name . ".pm"};

  if ($@) {
    print "Content-Type: text/plain\n\n";
    my $res = "Error: load module '" . $name . ".pm' \n $!  \n" .
      "Purchase module from http://abills.net.ua/ \n";

    print $@ if ($conf{PAYSYS_DEBUG});
    mk_log($res);

    return 0;
  }

  if ($name =~ /^\d/) {
    $name = '_' . $name;
  }

  my $function = lc($name) . '_check_payment';
  if (defined(&{$function})) {
    if ($debug > 3) {
      print 'Module: ' . $name . '.pm' . " Function: $function\n";
    }
    &{ \&{$function} }($attr->{SYS_PARAMS});
  }

  exit;
  return 1;
}


1
