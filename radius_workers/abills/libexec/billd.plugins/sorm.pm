# mkdir /usr/abills/var/sorm/abonents/
# mkdir /usr/abills/var/sorm/payments/
# mkdir /usr/abills/var/sorm/wi-fi/
# mkdir /usr/abills/var/sorm/dictionaries/
# echo "2018-01-01 00:00:01" > /usr/abills/var/sorm/last_admin_action
# echo "2018-01-01 00:00:01" > /usr/abills/var/sorm/last_payments
#
# $conf{BILLD_PLUGINS} = 'sorm';
# $conf{ISP_ID} = '1'; # идентифакатор ИСП из "информация по операторам связи и их филалах"'
#
# iconv -f UTF-8 -t CP1251 abonents.csv.utf > abonents.csv


use strict;
use warnings FATAL => 'all';

our (
  %conf,
  $Admin,
  $db,
  $users,
  $var_dir,
  $argv,
);

use Time::Piece;
use Abills::Base qw/cmd _bp in_array/;
use Abills::Misc qw/translate_list/;
use Users;
use Internet;
use Abon;
use Companies;
use Finance;
use Nas;
use Hotspot;

my $User = Users->new($db, $Admin, \%conf);
my $Company = Companies->new($db, $Admin, \%conf);
my $Payments = Finance->payments($db, $Admin, \%conf);
my $Internet = Internet->new($db, $Admin, \%conf);
my $Nas = Nas->new($db, $Admin, \%conf);
my $Abon = Abon->new($db, $Admin, \%conf);
my $Hotspot = Hotspot->new( $db, $Admin, \%conf );
my $start_date = "01.08.2017 12:00:00";
my $isp_id    = $conf{SORM_ISP_ID} || 1;
my $server_ip = $conf{SORM_SERVER} || '127.0.0.1';
my $login     = $conf{SORM_LOGIN}  || 'login';
my $pswd      = $conf{SORM_PSWD}   || 'password';
my $t = localtime;

if ($argv->{DICTIONARIES}) {
  supplement_services_dictionary();
  payments_type_dictionary();
  docs_dictionary();
  gates_dictionary();
  ippool_dictionary();
}
elsif ($argv->{START}) {
  my $users_list = $User->list({
    COLS_NAME   => 1,
    PAGE_ROWS   => 99999,
    DELETED     => 0,
    DISABLE     => 0,
  });
  
  foreach (@$users_list) {
    user_info_report($_->{uid});
  }
}
elsif ($argv->{WIFI}) {
  check_wifi();
}
else {
  check_admin_actions();
  check_system_actions();
  check_payments();
}

send_changes();


#**********************************************************
=head2 check_admin_actions($attr)

=cut
#**********************************************************
sub check_admin_actions {

  my $filename = $var_dir . "sorm/last_admin_action";
  open (my $fh, '<', $filename) or die "Could not open file '$filename' $!";
  my $last_action_date = <$fh>;
  chomp $last_action_date;
  close $fh;

  my $action_list = $Admin->action_list({ 
    COLS_NAME => 1,
    ACTIONS   => '_SHOW',
    TYPE      => '_SHOW',
    MODULE    => '_SHOW',
    DATETIME  => ">$last_action_date", 
    SORT      => 'aa.datetime', 
    DESC      => 'DESC',
    PAGE_ROWS => 99999,
  });
  
  return 1 if ($Admin->{TOTAL} < 1);

  $last_action_date = $action_list->[0]->{datetime} . "\n";

  foreach my $action (@$action_list) {
    if ($action->{module} eq 'Msgs') {

    }
    elsif ($action->{module} && $action->{module} eq 'Abon' && $action->{action_type} && $action->{action_type} eq '3') {
      my (@services) = $action->{actions} =~ m/ADD\:(\d+)/g;
      foreach (@services) {
        abon_info_report($action->{uid}, $action->{datetime}, $_);
      }
    }
    else {
      user_info_report($action->{uid}) if ($action->{uid});
    }
  }
  
  open ($fh, '>', $filename) or die "Could not open file '$filename' $!";
  print $fh $last_action_date;
  close $fh;

  return 1;
}

#**********************************************************
=head2 check_system_actions($attr)

=cut
#**********************************************************
sub check_system_actions {
  return 1;
}

#**********************************************************
=head2 check_payments($attr)

=cut
#**********************************************************
sub check_payments {

  my $filename = $var_dir . "sorm/last_payments";
  open (my $fh, '<', $filename) or die "Could not open file '$filename' $!";
  my $last_payment_date = <$fh>;
  chomp $last_payment_date;
  close $fh;

  my $payment_list = $Payments->list({
    DATETIME    => ">$last_payment_date",
    SUM         => '_SHOW',
    METHOD      => '_SHOW',
    CONTRACT_ID => '_SHOW',
    UID         => '_SHOW',

    COLS_NAME   => 1,
    PAGE_ROWS   => 99999,

    SORT        => 'p.date', 
    DESC        => 'DESC',
  });
  
  return 1 if ($Payments->{TOTAL} < 1);

  $last_payment_date = $payment_list->[0]->{datetime} . "\n";

  foreach my $payment (@$payment_list) {
    payment_report($payment);
  }
  
  open ($fh, '>', $filename) or die "Could not open file '$filename' $!";
  print $fh $last_payment_date;
  close $fh;

  return 1;
}

#**********************************************************
=head2 check_wifi()

=cut
#**********************************************************
sub check_wifi {

  my $filename = $var_dir . "sorm/last_wifi_action";
  open (my $fh, '<', $filename) or die "Could not open file '$filename' $!";
  my $last_wifi_date = <$fh>;
  chomp $last_wifi_date;
  close $fh;

  my $wifi_list = $Hotspot->log_list({ 
    DATE        => ">$last_wifi_date",
    ACTION      => '_SHOW',
    PHONE       => '_SHOW',
    CID         => '_SHOW',
    ACTION      => "2,3,5",
    COLS_NAME   => 1,
    PAGE_ROWS   => 99999,
    SORT        => 'date', 
    DESC        => 'DESC',
  });

  foreach my $line (@$wifi_list) {
    wifi_report($line);
  }

  return 1 if ($Hotspot->{TOTAL} < 1);

  $last_wifi_date = $wifi_list->[0]->{date} . "\n";

  # open ($fh, '>', $filename) or die "Could not open file '$filename' $!";
  # print $fh $last_wifi_date;
  # close $fh;

  return 1;
}

#**********************************************************
=head2 user_info_report($uid)

=cut
#**********************************************************
sub user_info_report {
  my ($uid) = @_;

  $User->pi({ UID => $uid });
  $User->info($uid);
  $Internet->info($uid);

  my ($family, $name, $surname) = split (' ', $User->{FIO});

  my @arr;

  $arr[0] = $isp_id;                                    # идентификатор филиала (справочник филиалов)
  $arr[1] = $User->{LOGIN};                             # login
  $arr[2] = ($Internet->{IP} && $Internet->{IP} ne '0.0.0.0') ? $Internet->{IP} : "";  # статический IP
  $arr[3] = $User->{EMAIL};                             # e-mail
  $arr[4] = $User->{PHONE} || "";                       # телефон
  $arr[5] = "";                                         # MAC-адрес
  $arr[6] = _date_format($User->{REGISTRATION}) . ' 12:00:00';       # дата договора
  $arr[7] = $User->{CONTRACT_ID} || $User->{LOGIN};     # номер договора
  $arr[8] = $User->{DISABLE};                           # статус абонента (0 - подключен, 1 - отключен)
  $arr[9] = _date_format($User->{REGISTRATION}) . ' 12:00:00';        # дата активации основной услуги
  $arr[10] = ($User->{EXPIRE} ne '0000-00-00' && $User->{EXPIRE} lt $DATE) ? _date_format($User->{EXPIRE}) : ""; # дата отключения основной услуги

#физ лицо
  if (!$User->{COMPANY_ID}) {
     
     $arr[11] = 0;             # тип абонента (0 - физ лицо, 1 - юр лицо)

    my ($passport_ser, $passport_num) = $User->{PASPORT_NUM} =~ m/(.*)\s(\d+)/;
    $passport_ser =~ s/\s//g if ($passport_ser);
    $User->{PASPORT_GRANT} =~ s/\n//g;
    $User->{PASPORT_GRANT} =~ s/\r//g;

    if ($name && $surname && $family) { 
      $arr[12] = '0';            # тип ФИО (0-структурировано, 1 - одной строкой) 
      $arr[13] = $name;          # имя
      $arr[14] = $surname;       # отчество
      $arr[15] = $family;        # фамилия
      $arr[16] = "";             # ФИО строкой
    }
    else {
      $arr[12] = '1';            # тип ФИО (0-структурировано, 1 - одной строкой) 
      $arr[13] = "";             # имя
      $arr[14] = "";             # отчество
      $arr[15] = "";             # фамилия
      $arr[16] = $User->{FIO};   # ФИО строкой
    }

    $arr[17] = "";             # дата рождения

    if ($passport_ser && $passport_num && $User->{PASPORT_GRANT}) {
      $arr[18] = '0';            # тип паспортных данных (0-структурировано, 1-одной строкой)
      $arr[19] = $passport_ser;  # серия паспорта
      $arr[20] = $passport_num;  # номер паспорта
      $arr[21] = $User->{PASPORT_GRANT} . " " . _date_format($User->{PASPORT_DATE});  # кем и когда выдан
      $arr[22] = "";             # паспортные данные строкой
    }
    else {
      $arr[18] = '1';            # тип паспортных данных (0-структурировано, 1-одной строкой)
      $arr[19] = "";             # серия паспорта
      $arr[20] = "";             # номер паспорта
      $arr[21] = "";             # кем и когда выдан
      $arr[22] = $User->{PASPORT_NUM} . " " . $User->{PASPORT_GRANT} . " " . $User->{PASPORT_DATE}; # паспортные данные строкой
    }
    $arr[23] = 1;              # тип документа (спровочник видов документов)
    $arr[24] = "";             # банк абонента
    $arr[25] = "";             # номер счета абонента

    $arr[26] = "";             # 
    $arr[27] = "";             # 
    $arr[28] = "";             # поля остаются пустыми если абонент физ. лицо
    $arr[29] = "";             # 
    $arr[30] = "";             # 
    $arr[31] = "";             # 
  }

#юр лицо
  else {

    $arr[11] = 1;              # тип абонента (0 - физ лицо, 1 - юр лицо)

    $arr[12] = "";             # 
    $arr[13] = "";             # 
    $arr[14] = "";             # 
    $arr[15] = "";             # 
    $arr[16] = "";             # 
    $arr[17] = "";             # 
    $arr[18] = "";             # 
    $arr[19] = "";             # поля остаются пустыми если абонент юр. лицо
    $arr[20] = "";             # 
    $arr[21] = "";             # 
    $arr[22] = "";             # 
    $arr[23] = "";             # 
    $arr[24] = "";             # 
    $arr[25] = "";             # 

    $Company->info($User->{COMPANY_ID});

    $arr[26] = $Company->{COMPANY_NAME};   # наименование компании
    $arr[27] = $Company->{COMPANY_VAT};    # ИНН
    $arr[28] = $Company->{REPRESENTATIVE}; # контактное лицо
    $arr[29] = $Company->{PHONE};          # контактный телефон
    $arr[30] = $Company->{BANK_NAME};      # банк абонента
    $arr[31] = $Company->{BANK_ACCOUNT};   # номер счета абонента
  }

#адрес абонента  
  my $address = ($User->{ADDRESS_FULL} || "") . ", " . ($User->{CITY} || "") . ", " . ($User->{ZIP} || "");

  $arr[32] = 1;               # тип данных адреса (0 - структурировано, 1 - одной строкой)
  $arr[33] = "";              # индекс
  $arr[34] = "";              # страна
  $arr[35] = "";              # область
  $arr[36] = "";              # район
  $arr[37] = "";              # город
  $arr[38] = "";              # улица
  $arr[39] = "";              # дом
  $arr[40] = "";              # корпус
  $arr[41] = "";              # квартира
  $arr[42] = $address;        # адрес строкой

#адрес устройства
  $arr[43] = 1;               # тип данных адреса устройства (0 - структурировано, 1 - одной строкой)
  $arr[44] = "";              # индекс
  $arr[45] = "";              # страна
  $arr[46] = "";              # область
  $arr[47] = "";              # район
  $arr[48] = "";              # город
  $arr[49] = "";              # улица
  $arr[50] = "";              # дом
  $arr[51] = "";              # корпус
  $arr[52] = "";              # квартира
  $arr[53] = $address;        # адрес строкой


  my $string = "";
  foreach (@arr) {
    $string .= '"' . ($_ // "") . '";'; 
  }
  $string =~ s/;$/\n/;
  
  _add_report('user', $string);

  return 1;
}

#**********************************************************
=head2 abon_info_report($uid, $date, $tp)

=cut
#**********************************************************
sub abon_info_report {
  my ($uid, $datetime, $tp_id) = @_;
  $User->info($uid);

  my $string = '"' . $isp_id .'";';                                      # идентификатор филиала из справочника
  $string   .= '"' . $User->{LOGIN} . '";';                              # логин
  $string   .= '"' . ($User->{CONTRACT_ID} || $User->{LOGIN} ) . '";';   # номер договора
  $string   .= '"' . $tp_id . '";';                                      # идентификатор услуги
  $string   .= '"' . _date_format($datetime) . '";';                     # дата подключения
  $string   .= '"";';                                                    # дата отключения
  $string   .= '""' . "\n";                                              # дополнительная информация

  _add_report('abon', $string);

  return 1;
}

#**********************************************************
=head2 ippool_dictionary($attr)

=cut
#**********************************************************
sub ippool_dictionary {

  my $pools_list = $Nas->nas_ip_pools_list({
    IP_COUNT         => '_SHOW',
    POOL_NAME        => '_SHOW',
    IP               => '_SHOW',
    COLS_NAME        => 1,
    SHOW_ALL_COLUMNS => 1,
    PAGE_ROWS        => 99999,
  });

  foreach my $pool (@$pools_list) {
    next unless ($pool->{ip});
    my $w=($pool->{ip}/16777216)%256;
    my $x=($pool->{ip}/65536)%256;
    my $y=($pool->{ip}/256)%256;
    my $ip = "$w.$x.$y.0";
    
    my $mask = 32 - length(sprintf ("%b", $pool->{ip_count}));

    my $string = '"' . $isp_id .'";'; 
    $string .= '"' . $pool->{pool_name} . '";';
    $string .= '"' . $ip . '";';
    $string .= '"' . $mask . '";';
    $string .= '"' . $start_date . '";';
    $string .= '""' . "\n";

    _add_report('pool', $string);
  }
  print "IP pool dictionary formed.\n";
  return 1;
}

#**********************************************************
=head2 docs_dictionary($attr)

=cut
#**********************************************************
sub docs_dictionary {
  
  my $string = '"' . $isp_id .'";"1";"01.08.2017";"";"паспорт"' . "\n";
  _add_report('d_type', $string);

  print "Docs dictionary formed.\n";
  return 1;
}

#**********************************************************
=head2 gates_dictionary($attr)

=cut
#**********************************************************
sub gates_dictionary {
  
  my $string = '"' . $isp_id .'";"1.1.1.1";"01.08.2017";"";"Radius";"Страна";"Область";" ";"город";"улица";"7";"7"' . "\n";
  _add_report('gates', $string);

  print "Gates dictionary formed.\n";
  return 1;
}

#**********************************************************
=head2 payments_type_dictionary($attr)

=cut
#**********************************************************
sub payments_type_dictionary {
  do ("/usr/abills/language/russian.pl");
  my $types = translate_list($Payments->payment_type_list({ COLS_NAME => 1 }));

  if ($conf{PAYSYS_PAYMENTS_METHODS}) {
    foreach my $line (split (';', $conf{PAYSYS_PAYMENTS_METHODS})) {
      my($id, $type) = split (':', $line);
      push (@$types, {id => $id, name => $type} );
    }
  }

  foreach (@$types) {
    my $string = '"' . $isp_id .'";';
    $string .= '"' . $_->{id} . '";';
    $string .= '"' . $start_date . '";';
    $string .= '"";';
    $string .= '"' . $_->{name} . '"' . "\n";
    _add_report('p_type', $string);
  }

  print "Payments types dictionary formed.\n";
  return 1;
}

#**********************************************************
=head2 supplement_services_dictionary();($attr)

=cut
#**********************************************************
sub supplement_services_dictionary {
  my $list = $Abon->tariff_list({ COLS_NAME => 1 });

  foreach (@$list) {
    my $string = '"' . $isp_id .'";';
    $string .= '"' . $_->{tp_id} . '";';      # номер услуги
    $string .= '"' . $_->{name} . '";';       # название услуги
    $string .= '"' . $start_date . '";';      # дата начала действия услуги 
    $string .= '"";';                         # дата окончания действия услуги
    $string .= '"' . $_->{name} . '"' . "\n"; # описание
    _add_report('sup_s', $string);
  }

  print "supplement_services dictionary formed.\n";
  return 1;
}

#**********************************************************
=head2 payment_report($attr)

=cut
#**********************************************************
sub payment_report {
  my ($attr) = @_;

  $Internet->info($attr->{uid});
  my $ip = ($Internet->{IP} ne '0.0.0.0') ? $Internet->{IP} : "";
  
  my $string = '"' . $isp_id .'";';                             # идентификатор филиала из справочника
  $string   .= '"' . $attr->{method} . '";';                    # тип оплаты из сравочника
  $string   .= '"' . ($attr->{login} || "") . '";';             # номер договора
  $string   .= '"' . $ip . '";';                                # статический IP
  $string   .= '"' . _date_format($attr->{datetime}) . '";';    # дата пополнения
  $string   .= '"' . $attr->{sum} . '";';                       # сумма пополнения
  $string   .= '"' . ($attr->{dsc} || "") . '"' . "\n";         # дополнительная информация

  _add_report('payment', $string);

  return 1;
}

#**********************************************************
=head2 wifi_report($attr)

=cut
#**********************************************************
sub wifi_report {
  my ($attr) = @_;

  my $Sessions =();
  if (in_array( 'Internet', \@MODULES )) {
    require Internet::Sessions;
    $Sessions = Internet::Sessions->new($db, $Admin, \%conf);
  }
  else {
    $Sessions = Dv_Sessions->new($db, $Admin, \%conf);
  }

  my $online_list = $Sessions->online({ 
    CLIENT_IP   => '_SHOW',
    UID         => '_SHOW',
    STARTED     => ">$attr->{date}",
    CID         => $attr->{CID},
    COLS_NAME   => 1,
    COLS_UPPER  => 1,
    SORT        => 'started',
    PAGE_ROWS   => 1
  });

  if ($Sessions->{TOTAL}) {
    $attr->{uid}  = $online_list->[0]->{uid};
    $attr->{ip}   = $online_list->[0]->{client_ip};
    $attr->{date} = $online_list->[0]->{started};
  }
  else {
    my $sessions_list = $Sessions->list({
      IP          => '_SHOW',
      UID         => '_SHOW',
      DATE        => ">$attr->{date}",
      CID         => $attr->{CID},
      COLS_NAME   => 1,
      COLS_UPPER  => 1,
      SORT        => 1,
      PAGE_ROWS   => 1
    });

    if ($Sessions->{TOTAL}) {
      $attr->{uid}  = $sessions_list->[0]->{uid};
      $attr->{ip}   = $sessions_list->[0]->{ip};
      $attr->{date} = $sessions_list->[0]->{date};
    }
    else {
      print "Can't find session info for $attr->{CID}, $attr->{id} line, hotspot_log\n";
      return 1;
    }
  }

  if (!$attr->{phone}) {
    $User->pi({ UID => $attr->{uid} });
    $attr->{phone} = $User->{PHONE};
  }

  if (!$attr->{phone}) {
    print "Can't find phone for $attr->{CID} Skip line $attr->{id}.\n";
    return 1;
  }

  if (!$attr->{login}) {
    print "Can't find user with $attr->{CID} Skip line $attr->{id}.\n";
    return 1;
  }

  my $string = '"' . $isp_id .'";';                             # идентификатор филиала из справочника
  $string   .= '"' . $attr->{phone} . '";';                     # телефон
  $string   .= '"' . $attr->{login} . '";';                     # логин
  $string   .= '"' . $attr->{ip} . '";';                        # IP
  $string   .= '"' . $attr->{CID} . '";';                       # МАС-адрес
  $string   .= '"' . $attr->{date} . '";';                      # дата и время подключения
  $string   .= '"1"' . "\n";                                    # номер антены (из справочника)

  _add_report('wifi', $string);

  return 1;
}

#**********************************************************
=head2 _add_report($type, $string)

=cut
#**********************************************************
sub _add_report {
  my ($type, $string) = @_;
# print "$type : $string";
  my %reports = (
    user    => "$var_dir/sorm/abonents/abonents.csv.utf",
    abon    => "$var_dir/sorm/abonents/services.csv.utf",
    payment => "$var_dir/sorm/payments/payments.csv.utf",
    p_type  => "$var_dir/sorm/dictionaries/pay-types.csv.utf",
    d_type  => "$var_dir/sorm/dictionaries/doc-types.csv.utf",
    gates   => "$var_dir/sorm/dictionaries/gates.csv.utf",
    pool    => "$var_dir/sorm/dictionaries/ip-numbering-plan.csv.utf",
    sup_s   => "$var_dir/sorm/dictionaries/supplement-services.csv.utf",
    wifi    => "$var_dir/sorm/wi-fi/wifi.csv.utf",
  );

  my $filename = $reports{$type};

  if ($type ne 'payment' && -e $filename) {
    open (my $fh, '<', $filename) or die "Could not open file '$filename' $!";
    while (<$fh>) {
      return 1 if ($_ eq $string);
    }
    close $fh;
  }

  open (my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
  print $fh $string;
  close $fh;

  return 1;
}

#**********************************************************
=head2 _date_format($attr)

=cut
#**********************************************************
sub _date_format {
  my ($date) = @_;

  $date =~ s/(\d{4})-(\d{2})-(\d{2})(.*)/$3.$2.$1$4/;
  return $date;
}

#**********************************************************
=head2 send_changes($attr)

=cut
#**********************************************************
sub send_changes {

  use Net::FTP;

  if (-e "/usr/abills/var/sorm/abonents/abonents.csv.utf") {
    my $file = join('_', 
      "/usr/abills/var/sorm/abonents/abonents",
      $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
    $file .= ".csv";
    print "Send $file\n";
    system("iconv -f UTF-8 -t CP1251 /usr/abills/var/sorm/abonents/abonents.csv.utf > $file");
    my $ftp = Net::FTP->new($server_ip, Debug => 0) or die "Cannot connect to $server_ip: $@";
    $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
    $ftp->cwd("/abonents/abonents") or die "Cannot change working directory ", $ftp->message;
    $ftp->put($file) or die "$file put failed ", $ftp->message;
    print $ftp->message;
    $ftp->quit;
    # unlink $file;
    unlink '/usr/abills/var/sorm/abonents/abonents.csv.utf';
  }

  if (-e "/usr/abills/var/sorm/payments/payments.csv.utf") {
    my $file = join('_', 
      "/usr/abills/var/sorm/payments/payments",
      $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
    $file .= ".csv";
    print "Send $file\n";
    system("iconv -f UTF-8 -t CP1251 /usr/abills/var/sorm/payments/payments.csv.utf > $file");
    my $ftp = Net::FTP->new($server_ip, Debug => 0) or die "Cannot connect to $server_ip: $@";
    $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
    $ftp->cwd("/payments/balance-fillup") or die "Cannot change working directory ", $ftp->message;
    $ftp->put($file) or die "$file put failed ", $ftp->message;
    print $ftp->message;
    $ftp->quit;
    # unlink $file;
    unlink '/usr/abills/var/sorm/payments/payments.csv.utf';
  }

  if (-e "/usr/abills/var/sorm/abonents/services.csv.utf") {
    my $file = join('_', 
      "/usr/abills/var/sorm/abonents/services",
      $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
    $file .= ".csv";
    print "Send $file\n";
    system("iconv -f UTF-8 -t CP1251 /usr/abills/var/sorm/abonents/services.csv.utf > $file");
    my $ftp = Net::FTP->new($server_ip, Debug => 0) or die "Cannot connect to $server_ip: $@";
    $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
    $ftp->cwd("/abonents/services") or die "Cannot change working directory ", $ftp->message;
    $ftp->put($file) or die "$file put failed ", $ftp->message;
    print $ftp->message;
    $ftp->quit;
    # unlink $file;
    unlink '/usr/abills/var/sorm/services/services.csv.utf';
  }

  if (-e "/usr/abills/var/sorm/dictionaries/gates.csv.utf") {
    my $file = join('_', 
      "/usr/abills/var/sorm/dictionaries/gates",
      $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
    $file .= ".csv";
    print "Send $file\n";
    system("iconv -f UTF-8 -t CP1251 /usr/abills/var/sorm/dictionaries/gates.csv.utf > $file");
    my $ftp = Net::FTP->new($server_ip, Debug => 0) or die "Cannot connect to $server_ip: $@";
    $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
    $ftp->cwd("/dictionaries/gates") or die "Cannot change working directory ", $ftp->message;
    $ftp->put($file) or die "$file put failed ", $ftp->message;
    print $ftp->message;
    $ftp->quit;
    # unlink $file;
    unlink '/usr/abills/var/sorm/dictionaries/gates.csv.utf';
  }

  if (-e "/usr/abills/var/sorm/dictionaries/doc-types.csv.utf") {
    my $file = join('_', 
      "/usr/abills/var/sorm/dictionaries/doc-types",
      $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
    $file .= ".csv";
    print "Send $file\n";
    system("iconv -f UTF-8 -t CP1251 /usr/abills/var/sorm/dictionaries/doc-types.csv.utf > $file");
    my $ftp = Net::FTP->new($server_ip, Debug => 0) or die "Cannot connect to $server_ip: $@";
    $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
    $ftp->cwd("/dictionaries/doc-types") or die "Cannot change working directory ", $ftp->message;
    $ftp->put($file) or die "$file put failed ", $ftp->message;
    print $ftp->message;
    $ftp->quit;
    # unlink $file;
    unlink '/usr/abills/var/sorm/dictionaries/doc-types.csv.utf';
  }

  if (-e "/usr/abills/var/sorm/dictionaries/pay-types.csv.utf") {
    my $file = join('_', 
      "/usr/abills/var/sorm/dictionaries/pay-types",
      $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
    $file .= ".csv";
    print "Send $file\n";
    system("iconv -f UTF-8 -t CP1251 /usr/abills/var/sorm/dictionaries/pay-types.csv.utf > $file");
    my $ftp = Net::FTP->new($server_ip, Debug => 0) or die "Cannot connect to $server_ip: $@";
    $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
    $ftp->cwd("/dictionaries/pay-types") or die "Cannot change working directory ", $ftp->message;
    $ftp->put($file) or die "$file put failed ", $ftp->message;
    print $ftp->message;
    $ftp->quit;
    # unlink $file;
    unlink '/usr/abills/var/sorm/dictionaries/pay-types.csv.utf';
  }

  if (-e "/usr/abills/var/sorm/dictionaries/ip-numbering-plan.csv.utf") {
    my $file = join('_', 
      "/usr/abills/var/sorm/dictionaries/ip-numbering-plan",
      $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
    $file .= ".csv";
    print "Send $file\n";
    system("iconv -f UTF-8 -t CP1251 /usr/abills/var/sorm/dictionaries/ip-numbering-plan.csv.utf > $file");
    my $ftp = Net::FTP->new($server_ip, Debug => 0) or die "Cannot connect to $server_ip: $@";
    $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
    $ftp->cwd("/dictionaries/ip-numbering-plan") or die "Cannot change working directory ", $ftp->message;
    $ftp->put($file) or die "$file put failed ", $ftp->message;
    print $ftp->message;
    $ftp->quit;
    # unlink $file;
    unlink '/usr/abills/var/sorm/dictionaries/ip-numbering-plan.csv.utf';
  }

  if (-e "/usr/abills/var/sorm/dictionaries/supplement-services.csv.utf") {
    my $file = join('_', 
      "/usr/abills/var/sorm/dictionaries/supplement-services",
      $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
    $file .= ".csv";
    print "Send $file\n";
    system("iconv -f UTF-8 -t CP1251 /usr/abills/var/sorm/dictionaries/supplement-services.csv.utf > $file");
    my $ftp = Net::FTP->new($server_ip, Debug => 0) or die "Cannot connect to $server_ip: $@";
    $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
    $ftp->cwd("/dictionaries/supplement-services") or die "Cannot change working directory ", $ftp->message;
    $ftp->put($file) or die "$file put failed ", $ftp->message;
    print $ftp->message;
    $ftp->quit;
    # unlink $file;
    unlink '/usr/abills/var/sorm/dictionaries/supplement-services.csv.utf';
  }

  if (-e "/usr/abills/var/sorm/wi-fi/wifi.csv.utf") {
    my $file = join('_', 
      "/usr/abills/var/sorm/wi-fi/wifi",
      $t->year, $t->mon, $t->mday, $t->hour, $t->min, $t->sec);
    $file .= ".csv";
    print "Send $file\n";
    system("iconv -f UTF-8 -t CP1251 /usr/abills/var/sorm/wi-fi/wifi.csv.utf > $file");
    my $ftp = Net::FTP->new($server_ip, Debug => 0) or die "Cannot connect to $server_ip: $@";
    $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
    $ftp->cwd("/wi-fi") or die "Cannot change working directory ", $ftp->message;
    $ftp->put($file) or die "$file put failed ", $ftp->message;
    print $ftp->message;
    $ftp->quit;
    # unlink $file;
    unlink '/usr/abills/var/sorm/wi-fi/wifi.csv.utf';
  }
  
  return 1;
}

1