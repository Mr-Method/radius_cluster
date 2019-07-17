#package Paysys::PaysysOld;
use strict;
use warnings FATAL => 'all';
#use v5.20.2;
# FIXME remove this and remove goto
no warnings 'deprecated';

use Abills::Base qw(load_pmodule convert);

our ($db,
  %conf,
  $admin,
  $op_sid,
  $html,
  %lang,
  $base_dir,
  %ADMIN_REPORT,
  %PAYSYS_PAYMENTS_METHODS,
  @WEEKDAYS,
  @MONTHES,
  %FEES_METHODS,
  @TERMINAL_STATUS,
  %PAYSYSTEM_CONF,
  $PAYSYSTEM_VERSION,
  $PAYSYSTEM_NAME,
  $PAYSYSTEM_IP,
  @status,
  @status_color,
);

our Paysys $Paysys;
our Finance $Payments;
our Finance $Fees;

my %PAY_SYSTEMS = (
  41 => "Webmoney",
  42 => "Rbkmoney",
  43 => "SMSProxy",
  44 => "OSMP",
  45 => "Portmone",
  46 => "Ukrpays",
  47 => "USMP",
  48 => "Privat Bank (Visa/Master Cards)",
  49 => "Pegas",
  50 => "Comepay",
  51 => "24_non_STOP",
  52 => "24_non_STOP_SELF",
  53 => "Express_Oplata",
  54 => "Privat Bank - Privat 24",
  55 => "Pay4",
  56 => "АИС ЕРИП",
  57 => "EasySoft",
  58 => "Liberty Reserve",
  59 => "QIWI",
  60 => "Ibox",
  61 => "OSMPv4",
  62 => 'LiqPAY',
  63 => 'UkrNET',
  64 => 'Regulpay',
  65 => 'Privat - Terminal',
  66 => 'Paypal',
  67 => 'Sberbank',
  68 => 'Gigs',
  69 => 'Autopay Visa MasterCards',
  70 => 'CyberPlat',
  71 => 'Telcell',
  #  72 => 'Ipay',
  73 => 'Yandex',
  74 => 'Alpha-pay',
  75 => 'Zaplati',
  76 => 'Paynet',
  77 => 'CyberPlat Visa/Master cards',
  78 => 'Epay',
  79 => 'Private bank terminal (json)',
  80 => 'Pegas Self Terminals',
  81 => 'Payonline - QIWI',
  82 => 'Payonline - WebMoney',
  83 => 'Payonline - Yandex money',
  84 => 'Payonline - Bank card',
  85 => "Термінали України",
  86 => 'Perfectmoney',
  87 => 'OKPay',
  88 => 'Bitcoin',
  89 => 'Smsonline',
  90 => 'Cashcom',
  91 => 'PayU',
  92 => 'CoPayCo',
  93 => 'Minbank',
  94 => 'Redsys',
  95 => 'Gateway Technologies',
  96 => 'Webmoney UA',
  97 => 'PayMaster',
  98 => 'Ecommerce Connect (UPC)',
  99 => 'TYME',
  100=> 'E-manat', # Modenis
  101=> 'Evostok',
  102=> 'Stripe',
  103=> 'Oschadbank',
  104=> 'Kaznachey',
  106=> 'Paykeeper',
  105=> 'Robokassa',
  107=> 'Chelyabinvestbank',
  108=> 'Platon',
  109=> 'Fondy',
  110=> 'Walletone',
  111=> 'Mobilnik',
  112=> 'Idram',
  114=> 'Oschadbank',
  115=> 'Goldenpay',
  116=> 'Mixplat',
  117=> 'Yandex Kassa',
  118=> 'Deltapay',
  119=> 'Unipay',
  120=> 'Tinkoff',
  121=> 'Cloudpayments',
  122=> 'PaymasterRu',
  123=> 'Rncb',
  124=> 'P24_API',
  125=> 'Electrum',
  126=> 'Plategka',
  127=> 'City24',
  128=> 'ConcordBank',
);

my %CONF_OPTIONS = (
  PAYSYS_WEBMONEY_ACCOUNTS     => 41,
  PAYSYS_RBKMONEY_ID           => 42,
  PAYSYS_SMSPROXY              => 43,
  PAYSYS_OSMP_ACCOUNT_KEY      => 44,
  PAYSYS_PORTMONE_PAYEE_ID     => 45,
  PAYSYS_UKRPAYS_SERVICE_ID    => 46,
  PAYSYS_USMP_ACCOUNT_KEY      => 47,
  PAYSYS_PB_MERID              => 48,
  PAYSYS_PEGAS                 => 49,
  PAYSYS_COMEPAY               => 50,
  PAYSYS_24_NON_STOP_SECRET    => 51,
  PAYSYS_24_NON_STOP_SECRET    => 52,
  PAYSYS_EXPRESS_OPLATA        => 53,
  PAYSYS_P24_MERCHANT_ID       => 54,
  PAYSYS_PAY4                  => 55,
  PAYSYS_ERIPT                 => 56,
  PAYSYS_EASYPAY_SERVICE_ID    => 57,
  PAYSYS_LR_ACCOUNT_NUMBER     => 58,
  PAYSYS_QIWI_TERMINAL_ID      => 59,
  PAYSYS_IBOX_ACCOUNT_KEY      => 60,
  PAYSYS_OSMP_ACCOUNT_KEY      => 61,
  PAYSYS_LIQPAY_MERCHANT_ID    => 62,
  PAYSYS_UKRNET_ACCOUNT_KEY    => 63,
  PAYSYS_REGULPAY_ACCOUNT_KEY  => 64,
  PAYSYS_PRIVAT_TERMINAL_ACCOUNT_KEY => 65,
  PAYSYS_PAYPAL_RECIEVER_EMAIL => 66,
  PAYSYS_SBERBANK_PASSWORD     => 67,
  PAYSYS_GIGS_IPS              => 68,
  PAYSYS_AUTOPAY_PROVIDER      => 69,
  PAYSYS_CYBERPLAT_ACCOUNT_KEY    => 70,
  PAYSYS_TELLCELL_ACCOUNT_KEY     => 71,
  PAYSYS_IPAY_MERCHANT_ID         => 72,
  PAYSYS_YANDEX_ID                => 73,
  PAYSYS_ALFA_PAY_ACCOUNT_KEY     => 74,
  PAYSYS_ZAPLATI_SUMY_ACCOUNT_KEY => 75,
  PAYSYS_USMP_ACCOUNT_KEY         => 76,
  PAYSYS_CP_VISA                  => 77,
  PAYSYS_EPAY_ACCOUNT_KEY         => 78,
  PAYSYS_PRIVATE_JSON_ACCOUNT_KEY => 79,
  PAYSYS_PEGAS_SELF_TERMINALS     => 80,
  PAYSYS_QIWI_PAYONLINE_ACCOUNT_KEY         => 81,
  PAYSYS_WEBMONEY_PAYONLINE_ACCOUNT_KEY     => 82,
  PAYSYS_YANDEX_MONEY_PAYONLINE_ACCOUNT_KEY => 83,
  PAYSYS_BANK_CARD_PAYONLINE_ACCOUNT_KEY    => 84,
  PAYSYS_WEBMONEY_TERMINAL                  => 85,
  PAYSYS_PERFECTMONEY_ACCOUNTID             => 86,
  PAYSYS_OKPAY_KEY                          => 87,
  PAYSYS_BITCOIN_KEY                        => 88,
  PAYSYS_SMSONLINE_KEY                      => 89,
  PAYSYS_CASHCOM_PROVIDER_ID                => 90,
  PAYSYS_PAYU_MERCHANT                      => 91,
  PAYSYS_COPAYCO_SHOP_ID                    => 92,
  PAYSYS_MINBANK_MERCHANT_ID                => 93,
  PAYSYS_REDSYS_MERCHANT_ID                 => 94,
  PAYSYS_GT_ID                              => 95,
  PAYSYS_WEBMONEY_UA                        => 96,
  PAYSYS_PAYMASTER_SECRET                   => 97,
  PAYSYS_UPC_MERCHANT_ID                    => 98,
  PAYSYS_EVOSTOK_KEY                        => 101,
  PAYSYS_STRIPE_SECRET_KEY                  => 102,
  PAYSYS_PAYKEEPER_KEY                      => 106,
  PAYSYY_KAZNACHEY_SECRET_KEY				        => 104,
  PAYSYS_ROBOKASSA_PASSWORD_ONE             => 105,
  PAYSYS_CHINVESTBANK_PASS                  => 107,
  PAYSYS_PLATON_KEY                         => 108,
  PAYSYS_FONDY_PASSWORD                     => 109,
  PAYSYS_WALLETONE_MERCH_ID                 => 110,
  MOBILNIK_SUPLIER_ID                       => 111,
  PAYSYS_IDRAM_SECRET_KEY                   => 112,
  PAYSYS_OSCHADBANK_SECRET_KEY              => 114,
  PAYSYS_MIXPLAT_SECRET_KEY                 => 116,
  PAYSYS_YANDEX_KASSA_SCID                  => 117,
  PAYSYS_TINKOFF_TERMINAL_KEY               => 120,
  PAYSYS_CLOUDPAYMENTS_ID                   => 121,
  PAYSYS_PAYMASTERRU_MERCHANT_ID            => 122,
  PAYSYS_ELECTRUM_URL                       => 125,
  PAYSYS_PLATEGKA_MERCHANT_ID               => 126,
);

#my @TERMINAL_TYPES = ('EasyPay',  'Privatbank');


paysys_load('Paysys_Base');

if ($conf{PAYSYS_SUCCESSIONS}) {
  $conf{PAYSYS_SUCCESSIONS} =~ s/[\n\r]+//g;
  my @systems_arr = split(/;/, $conf{PAYSYS_SUCCESSIONS});

  # IPS:ID:NAME:SHORT_NAME:MODULE_function;
  foreach my $line (@systems_arr) {
    my (undef, $id, $name, $short_name, undef) = split(/:/, $line);
    $PAY_SYSTEMS{$id} = $name;
    my $system_conf_name = uc('PAYSYS_' . $short_name);
    $CONF_OPTIONS{$system_conf_name} = $id;
    $conf{$system_conf_name}         = 1;
  }
}
#**************************************************************
=head2 paysys_user_del()  -Delete user from module

=cut
#**************************************************************
sub paysys_user_del {
  my ($uid) = @_;

  $Paysys->{UID} = $uid;
  $Paysys->del(0, { UID => $uid });

  return 0;
}

#**********************************************************
=head2 paysys_import_fees() - Import fees from_file

=cut
#**********************************************************
sub paysys_import_fees {

  paysys_import_form(
    {
      TYPE           => 'FEES',
      BINDING_FIELDS => $conf{PAYSYS_FEES_BINDING},
      IMPORT_EXPR    => $conf{PAYSYS_FEES_IMPORT},
      IMPORT_RULES => $lang{FEES},
      FORM           => \%FORM
    }
  );

  return 1;
}

#**********************************************************
=head2  paysys_import_payments() - Import payments from_file

=cut
#**********************************************************
sub paysys_import_payments {

  paysys_import_form(
    {
      TYPE         => 'PAYMENTS',
      IMPORT_TYPE  => $FORM{IMPORT_TYPE},
      IMPORT_RULES => $conf{PAYSYS_IMPORT_RULES},
      FORM         => \%FORM
    }
  );

  return 1;
}

#**********************************************************
=head2 paysys_import_form($attr) - Import from file

  Arguments:
    TYPE
    IMPORT_TYPE
    IMPORT_RULES
    FORM          - Input data hash_ref
    DEBUG         -

  Returns:

=cut
#**********************************************************
sub paysys_import_form {
  my ($attr) = @_;

  my @import_types = ();
  if ($attr->{IMPORT_RULES}) {
    @import_types = split(/,/, $attr->{IMPORT_RULES});
  }

  my %PAYMENTS_METHODS = ();

  my $debug = $attr->{DEBUG} || 0;
  my $table;
  my $FORM  = $attr->{FORM};

  #exchange rate list
  my $er_list   = $Payments->exchange_list({ COLS_NAME => 1 });
  my %ER_ISO2ID = ();
  foreach my $line (@$er_list) {
    $ER_ISO2ID{ $line->{iso} } = $line->{id};
    if ($FORM->{ER} && $FORM->{ER} == $line->{id}) {
      $FORM->{ER}       = $line->{rate};
      $FORM->{CURRENCY} = $line->{iso};
      last;
    }
  }

  if ($FORM->{IMPORT}) {
    #Default import extration
    my $import_expr = ($attr->{IMPORT_EXPR}) ? $attr->{IMPORT_EXPR} : '(\d+)\t(.+)\t(\d+)\t(\S+)\t([0-9.,]+)\t(\d{2}-\d{2}-\d{4})\t(.+)\t(.+):ID, FIO, PHONE, CONTRACT_ID, SUM, DATE, ADDRESS, DESCRIBE';

    #Default Binding field
    my $BINDING_FIELD = $attr->{BINDING_FIELDS} || $FORM->{BINDING_FIELD} || 'CONTRACT_ID';

    if (defined($attr->{IMPORT_TYPE})) {
      $import_expr = $conf{ 'PAYSYS_IMPORT_EXPRATION_' . $attr->{IMPORT_TYPE} };
      $BINDING_FIELD = $conf{ 'PAYSYS_IMPORT_BINDING_' . $attr->{IMPORT_TYPE} } if ($conf{ 'PAYSYS_IMPORT_BINDING_' . $attr->{IMPORT_TYPE} });
    }

    my ($DATA_ARR, $BINDING_IDS);
    my %binding_hash = ();
    my $total_count  = 0;
    my $total_sum    = 0;

    #Confirmation
    if (defined($FORM->{IDS})) {
      my @IDS = split(/, /, $FORM->{IDS});
      for (my $i = 0 ; $i <= $#IDS ; $i++) {
        my $ID        = $IDS[$i];
        my %DATA_HASH = (
          PAYSYS_EXT_ID  => $ID,
          EXT_ID         => $FORM->{ 'EXT_ID_' . $ID },
          PHONE          => $FORM->{ 'PHONE_' . $ID },
          FIO            => $FORM->{ 'FIO_' . $ID },
          SUM            => $FORM->{ 'SUM_' . $ID },
          DATE           => $FORM->{ 'DATE_' . $ID },
          TYPE           => $FORM->{ 'TYPE_' . $ID },
          PAYMENT_METHOD => $FORM->{ 'PAYMENT_METHOD_' . $ID },
          METHOD         => $FORM->{ 'METHOD_' . $ID },
          DESCRIBE       => $FORM->{ 'DESCRIBE_' . $ID },
          INNER_DESCRIBE => $FORM->{ 'INNER_DESCRIBE_' . $ID },
          ADDRESS        => $FORM->{ 'ADDRESS_' . $ID },
          $BINDING_FIELD => $FORM->{ $BINDING_FIELD . '_' . $ID },
          UID            => $FORM->{ 'UID_' . $ID },
          CURRENCY       => $FORM->{ 'CURRENCY_' . $ID }
        );

        push @{$DATA_ARR}, {%DATA_HASH};
        if ($DATA_HASH{$BINDING_FIELD}) {
          push @{$BINDING_IDS}, $DATA_HASH{$BINDING_FIELD};
        }
        else {
          push @{$BINDING_IDS}, '*';
        }
      }
    }
    #Get data from file
    elsif ($FORM->{FILE_DATA}) {
      ($DATA_ARR, $BINDING_IDS) = paysys_import_parse($FORM->{FILE_DATA}{Contents}, $import_expr,
        $BINDING_FIELD, { DEBUG => $debug, ENCODE => $FORM->{ENCODE} });

      if($FORM{METHOD} == 113){
        for(my $i=0; $i <= $#{$DATA_ARR}; $i++){
          if($DATA_ARR->[$i]->{UID} =~ /\D+/ || $DATA_ARR->[$i]->{UID} eq ''){
            my %BUILDS_LETTERS =  (1 => "А", 2 => "Б", 3 => "В");
            my ($bank_street, $bank_build, $bank_flat) = $DATA_ARR->[$i]->{ADDRESS} =~ /(\d+)","(.+)","(.+)/;
            my $address = Address->new($db, $admin, \%conf);
            my $street_info = $address->street_list({COLS_NAME => 1, NAME => '_SHOW', SECOND_NAME => $bank_street});

            $bank_street = $street_info->[0]->{street_name};

            if($bank_build =~ /-/){
              my ($num, $letter_num) = split('-', $bank_build);
              $bank_build = $num . "-" . $BUILDS_LETTERS{$letter_num};
            }

            if($bank_flat =~ /-/){
              my ($num, $letter_num) = split('-', $bank_flat);
              $bank_flat = $num . "-" . $BUILDS_LETTERS{$letter_num};
            }

            my $user_info = $users->list({ COLS_NAME       => 1,
              FIO             => '_SHOW',
              ADDRESS_STREET  => $street_info->[0]->{street_name},
              ADDRESS_FLAT    => $bank_flat,
              ADDRESS_BUILD   => $bank_build});
            if($#{$user_info} == 0){
              $DATA_ARR->[$i]->{UID} = $user_info->[0]->{uid};
              $DATA_ARR->[$i]->{ADDRESS} = "$bank_street $bank_build, $bank_flat";
            }
            elsif($#{$user_info} == -1){
              $html->message( "err", "ID $lang{NOT_EXIST}", "$lang{LINE} $i - $DATA_ARR->[$i]->{FIO}" );
            }
            else{
              my $users_without_id = '';
              foreach my $user_ (@$user_info){
                if($user_->{fio} eq $DATA_ARR->[$i]->{FIO}){
                  $DATA_ARR->[$i]->{UID} = $user_->{uid};
                  $DATA_ARR->[$i]->{ADDRESS} = "$bank_street $bank_build, $bank_flat";
                }
                else{
                  $users_without_id .= "$lang{FIO} - $user_->{fio};  UID - " . $html->button( "$user_->{uid}",
                    "index=30&UID=$user_->{uid}" ) . "\n";
                }
              }
              if($DATA_ARR->[$i]->{UID} eq ''){
                $html->message( "err", "MORE THEN ONE ID", "$lang{LINE} $i:\n $users_without_id" );
              }
            }
          }
        }
      }

      $table = $html->table(
        {
          width => '100%',
          rows  => [ [ $lang{NAME}, $FORM->{FILE_DATA}{filename} ], [ $lang{TOTAL}, $#{$DATA_ARR} + 1 ],
            [ "$lang{SIZE}", $FORM->{FILE_DATA}{Size} ] ]
        }
      );

      print $table->show();
    }

    #my $PAYMENTS_METHODS = get_payment_methods();

    my $ids = join(';', @{ ($BINDING_IDS) ? $BINDING_IDS : {} });

    if ($ids eq '') {
      $html->message( 'err', $lang{ERROR}, "'$ids' $lang{USER_NOT_EXIST}" );
      return 0;
    }

    my $users = Users->new($db, $admin, \%conf);
    my $list = $users->list(
      {
        FIO            => '_SHOW',
        $BINDING_FIELD => $ids,
        PAGE_ROWS      => 1000000,
        COLS_NAME      => 1
      }
    );

    if (_error_show($users, { ID => 1719 })) {
      return 0;
    }

    foreach my $line (@$list) {
      if ($line->{lc($BINDING_FIELD)}) {
        $binding_hash{ lc($line->{lc($BINDING_FIELD)}) } = $line->{uid}.':'.$line->{login}.':'. ($line->{fio} || '');
      }
    }

    my %HIDDEN_HASH = ();

    if ($FORM->{PAYMENTS}) {
      for (my $i = 0 ; $i <= $#{$DATA_ARR} ; $i++) {
        my $ID = $DATA_ARR->[$i]->{PAYSYS_EXT_ID} || $i;

        my ($uid, $login, $fio);

        if ( $DATA_ARR->[$i]->{UID} && $DATA_ARR->[$i]->{UID} > 0) {
          $uid = $DATA_ARR->[$i]->{UID};
        }
        elsif ($binding_hash{ lc($DATA_ARR->[$i]->{$BINDING_FIELD}) } ) {
          ($uid, $login, $fio) = split(/:/, $binding_hash{ lc($DATA_ARR->[$i]->{$BINDING_FIELD}) });
        }

        my $ext_id = $DATA_ARR->[$i]->{EXT_ID} || "$DATA_ARR->[$i]->{DATE}_$attr->{IMPORT_TYPE}.$ID";

        if ($uid) {
          my $user_   = $users->info($uid);
          # ddelete param for cross modules
          delete $user_->{PAYMENTS_ADDED};

          $Payments->add(
            $user_,
            {
              SUM            => $DATA_ARR->[$i]->{SUM},
              DESCRIBE       => $DATA_ARR->[$i]->{DESCRIBE} || '',
              METHOD         => (defined($DATA_ARR->[$i]->{PAYMENT_METHOD}) && $DATA_ARR->[$i]->{PAYMENT_METHOD} ne '') ? $DATA_ARR->[$i]->{PAYMENT_METHOD} : 1,
              DATE           => $DATA_ARR->[$i]->{DATE} || undef,
              EXT_ID         => $ext_id,
              CHECK_EXT_ID   => $ext_id,
              INNER_DESCRIBE => $DATA_ARR->[$i]->{INNER_DESCRIBE} || '',
              ER             => (defined($FORM->{ER})) ? $FORM->{ER} : $DATA_ARR->[$i]->{ER},
              CURRENCY       => (defined($FORM->{CURRENCY})) ? $FORM->{CURRENCY} : undef
            }
          );

          if ($Payments->{errno} && $Payments->{errno} == 7) {
            $html->message( 'err', $lang{ERROR},
              "$lang{EXIST}: EXT_ID: " . $html->button( "$ext_id", "&index=2&ID=$Payments->{ID}" ) );
          }
          else {
            $total_count++;
            $total_sum += $DATA_ARR->[$i]->{SUM};
            if (! $FORM->{SKIP_CROSSMODULES_CALLS}) {
              cross_modules_call('_payments_maked', {
                  USER_INFO    => $user_,
                  QUITE        => 1,
                  SUM          => $DATA_ARR->[$i]->{SUM},
                  PAYMENT_ID   => $Payments->{PAYMENT_ID},
                  SKIP_MODULES => 'Paysys,Sqlcmd'
                });
            }
          }
        }
        else {
          $html->message( 'err', $lang{ERROR},
            "$lang{NOT_EXIST} $BINDING_FIELD - '$DATA_ARR->[$i]->{$BINDING_FIELD}' \n Ext ID: $ext_id ",
            { ID => 1720 } );
        }
      }

      print $html->message( 'info', $lang{INFO}, "$lang{TOTAL}: $total_count $lang{SUM}: $total_sum" );
      return 0;
    }
    elsif ($FORM->{FEES}) {
      for (my $i = 0 ; $i <= $#{$DATA_ARR} ; $i++) {
        my $ID = $DATA_ARR->[$i]->{PAYSYS_EXT_ID} || $i;
        if ($binding_hash{ $DATA_ARR->[$i]->{$BINDING_FIELD} }) {
          #($uid, $login, $fio)
          my ($uid) = split(/:/, $binding_hash{ $DATA_ARR->[$i]->{$BINDING_FIELD} });
          my $user_ = $users->info($uid);
          $Fees->take(
            $user_,
            $DATA_ARR->[$i]->{SUM},
            {
              DESCRIBE       => $DATA_ARR->[$i]->{DESCRIBE}       || '',
              INNER_DESCRIBE => $DATA_ARR->[$i]->{EXT_ID}         || '',
              DATE           => $DATA_ARR->[$i]->{DATE}           || undef,
              INNER_DESCRIBE => $DATA_ARR->[$i]->{INNER_DESCRIBE} || '',
              METHOD         => $DATA_ARR->[$i]->{METHOD},
            }
          );

          if ($Fees->{errno} && $Fees->{errno} == 7) {
            $html->message( 'err', $lang{ERROR},
              "$lang{EXIST}: EXT_ID: $DATA_ARR->[$i]->{DATE}.$attr->{IMPORT_TYPE}.$ID" );
          }
          else {
            $total_count++;
            $total_sum += $DATA_ARR->[$i]->{SUM};
          }
        }
        else {
          $html->message( 'err', "$lang{FEES} - $lang{ERROR}",
            "$lang{NOT_EXIST} $BINDING_FIELD - $DATA_ARR->[$i]->{$BINDING_FIELD} " );
        }
      }

      print $html->message( 'info', $lang{INFO}, "$lang{TOTAL}: $total_count $lang{SUM}: $total_sum" );
      return 0;
    }
    elsif ($FORM->{CANCEL_PAYMENTS}) {
      my @payments_arr = ();

      for (my $i = 0 ; $i <= $#{$DATA_ARR} ; $i++) {
        #my $ID = $DATA_ARR->[$i]->{PAYSYS_EXT_ID} || $i;
        if ($DATA_ARR->[$i]->{EXT_ID}) {
          push @payments_arr, $DATA_ARR->[$i]->{EXT_ID};
        }
      }

      if ($#payments_arr == -1) {
        $html->message( 'err', $lang{ERROR}, "_NO_DATA" );
        return 0;
      }

      $list = $Payments->list(
        {
          EXT_ID    => join(';', @payments_arr),
          PAGE_ROWS => 1000000,
          COLS_NAME => 1
        }
      );

      foreach my $line (@$list) {
        $Payments->del({ UID => $line->{uid} }, $line->{id});
        $total_count++;
        $total_sum += $line->{sum};
      }

      $html->message( 'info', $lang{DELETED}, "\n$lang{TOTAL}: $total_count $lang{SUM}: $total_sum" );
      return 0;
    }
    else {

      $table = $html->table(
        {
          width      => '100%',
          caption    => "$lang{PRE} Import - $import_types[$attr->{IMPORT_TYPE}]",
          title      => [ 'ID', "$lang{FIO}", "$lang{PHONE}", "$lang{CONTRACT_ID}", "$lang{SUM}", "$lang{DATE}",
            "$lang{BANK} $lang{ACCOUNT}", "$lang{TYPE}", "$lang{ADDRESS}", "$lang{DESCRIBE}",
            "$lang{INNER} $lang{DESCRIBE}", "$lang{BINDING}", "EXT ID", '-' ],
          cols_align => [ 'left', 'left', 'right', 'right', 'left', 'right', 'right', 'center:noprint', 'center:noprint' ],
          qs         => $pages_qs,
          ID         => 'PAYSYS_IMPORT_LIST',
          SELECT_ALL => "FORM_IMPORT:IDS:$lang{SELECT_ALL}",
          EXPORT     => 1,
        }
      );

      #Draw table
      for (my $i = 0 ; $i <= $#{$DATA_ARR} ; $i++) {
        my $ID = $DATA_ARR->[$i]->{PAYSYS_EXT_ID} || $i;

        my $PAYMENT_METHOD_SEL = '';

        if ($attr->{TYPE} eq 'PAYMENTS') {
          $PAYMENT_METHOD_SEL = $html->form_select(
            'PAYMENT_METHOD_' . $ID,
            {
              SELECTED => $DATA_ARR->[$i]->{PAYMENT_METHOD} || $FORM{METHOD} ||'',
              SEL_HASH => \%PAYMENTS_METHODS,
              NO_ID    => 1,
              SORT_KEY => 1
            }
          );
        }
        elsif ($attr->{TYPE} eq 'FEES') {
          %FEES_METHODS = %{ get_fees_types({ SHORT => 1 }) };

          $PAYMENT_METHOD_SEL = $html->form_select(
            'METHOD_' . $ID,
            {
              SELECTED => $DATA_ARR->[$i]->{METHOD} || '',
              SEL_HASH => {%FEES_METHODS},
              NO_ID    => 1,
              SORT_KEY => 1
            }
          );
        }

        my $info = '';

        if ($binding_hash{ lc($DATA_ARR->[$i]->{$BINDING_FIELD}) }) {
          my ($uid, $login, $fio) = split(/:/, $binding_hash{ lc($DATA_ARR->[$i]->{$BINDING_FIELD}) });
          $info = $html->button($fio, "&index=11&UID=$uid", { TARGET => $uid }) . "/$login/$uid";
          $table->{rowcolor} = undef;
        }
        else {
          $table->{rowcolor} = $_COLORS[6];
        }

        #print "$DATA_ARR->[$i]->{TERMINAL_ID}, $DATA_ARR->[$i]->{NUM_AGENT}<br>";
        my $date = $DATA_ARR->[$i]->{DATE} || $FORM{DATE};
        $table->addrow(
          $html->form_input('IDS', $ID, { TYPE => 'checkbox' }) . $ID,
          $html->form_input('FIO_' . $ID,   $DATA_ARR->[$i]->{FIO}   || '', { SIZE => 40 }) . "$info",
          $html->form_input('PHONE_' . $ID, $DATA_ARR->[$i]->{PHONE} || '', { SIZE => 12 }),
            ($BINDING_FIELD eq 'CONTRACT_ID') ? $DATA_ARR->[$i]->{CONTRACT_ID} : $html->form_input('CONTRACT_ID_' . $ID, $DATA_ARR->[$i]->{CONTRACT_ID} || '', { SIZE => 12 }),
          $DATA_ARR->[$i]->{SUM},
          $date,
          $DATA_ARR->[$i]->{BANK_ACCOUNT},
          $PAYMENT_METHOD_SEL,
          $DATA_ARR->[$i]->{ADDRESS},
          $html->form_input('DESCRIBE_' . $ID,          $DATA_ARR->[$i]->{DESCRIBE}       || ''),
          $html->form_input('INNER_DESCRIBE_' . $ID,    $DATA_ARR->[$i]->{INNER_DESCRIBE} || ''),
          $html->form_input($BINDING_FIELD . '_' . $ID, $DATA_ARR->[$i]->{$BINDING_FIELD} || ''),
          $html->form_input('EXT_ID_' . $ID,            $DATA_ARR->[$i]->{EXT_ID}         || $date . '_' . $attr->{IMPORT_TYPE} . $ID),
        );

        $HIDDEN_HASH{ 'SUM_' . $ID }          = $DATA_ARR->[$i]->{SUM};
        $HIDDEN_HASH{ 'DATE_' . $ID }         = $DATA_ARR->[$i]->{DATE} || $FORM{DATE};
        $HIDDEN_HASH{ 'BANK_ACCOUNT_' . $ID } = $DATA_ARR->[$i]->{BANK_ACCOUNT};
        $HIDDEN_HASH{ 'ADDRESS_' . $ID }      = $DATA_ARR->[$i]->{ADDRESS};

        $total_count++;
        $total_sum += $DATA_ARR->[$i]->{SUM};
      }
    }

    print $html->form_main(
      {
        CONTENT => $table->show() . $html->form_input( $attr->{TYPE}, 1, { TYPE =>
            'radio' } ) . (($attr->{TYPE} && $attr->{TYPE} eq 'FEES') ? "$lang{FEES}" : " $lang{PAYMENTS} " . $html->form_input(
            'CANCEL_PAYMENTS', 1, { TYPE => 'radio' } ) . " $lang{CANCEL_PAYMENTS} ") . ' ' . $html->form_input(
          'SKIP_CROSSMODULES_CALLS', 1, { TYPE => 'checkbox' } ) . " $lang{NO} $lang{MODULES} ",
        HIDDEN  => {
          index       => "$index",
          OP_SID      => $op_sid,
          IMPORT_TYPE => $FORM{IMPORT_TYPE},
          BINDING_FIELD => $BINDING_FIELD,
          %HIDDEN_HASH
        },
        SUBMIT  => { IMPORT => "IMPORT" },
        NAME    => 'FORM_IMPORT'
      }
    );

    $table = $html->table(
      {
        width      => '100%',
        cols_align => [ 'right', 'right' ],
        rows       => [ [ "$lang{TOTAL}:", "$total_count", "$lang{SUM}", $total_sum ] ]
      }
    );

    print $table->show();
  }

  my %info = ();
  $info{IMPORT_TYPE_SEL} = $html->form_select(
    'IMPORT_TYPE',
    {
      SELECTED     => $FORM{IMPORT_TYPE},
      SEL_ARRAY    => \@import_types || undef,
      ARRAY_NUM_ID => 1
    }
  );

  $info{ENCODE_SEL} = $html->form_select(
    'ENCODE',
    {
      SELECTED  => $FORM{ENCODE},
      SEL_ARRAY => [ '', 'win2utf8', 'utf82win', 'win2koi', 'koi2win', 'win2iso', 'iso2win', 'win2dos', 'dos2win', 'cp8662utf8'],
    }
  );

  my $PAYMENTS_METHODS  = get_payment_methods();

  if (scalar  keys %ER_ISO2ID > 0) {
    $info{SEL_ER} = $html->form_select(
      'ER',
      {
        SELECTED      => $FORM{ER_ID} || $FORM{ER},
        SEL_LIST      => $er_list,
        SEL_KEY       => 'id',
        SEL_VALUE     => 'money,short_name,',
        NO_ID         => 1,
        MAIN_MENU     => get_function_index('form_exchange_rate'),
        MAIN_MENU_ARGV=> "chg=". ($FORM{ER} || ''),
        SEL_OPTIONS   => { '' => '' }
      }
    );

    $info{FORM_ER} = $html->tpl_show(templates('form_row'), { ID => '',
        NAME                                                     => "$lang{CURRENCY} : $lang{EXCHANGE_RATE}",
        VALUE                                                     => $info{SEL_ER} }, { OUTPUT2RETURN => 1 });
  }

  $info{METHOD} = $html->form_select(
    'METHOD',
    {
      SELECTED => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : 0,
      SEL_HASH => $PAYMENTS_METHODS,
      NO_ID    => 1,
    }
  );

  $html->tpl_show(_include('paysys_file_import', 'Paysys'), \%info);

  return 1;
}

#**********************************************************
=head2 paysys_payment($attr) - User portal payment interface

=cut
#**********************************************************
sub paysys_payment {
  my ($attr) = @_;

  if($FORM{SUM}) {
    $FORM{SUM} = 0 if($FORM{SUM} !~ /^[\.\,0-9]+$/);
    $FORM{SUM} = sprintf("%.2f", $FORM{SUM});
  }
  else {
    $FORM{SUM} = 0;
  }

  if($FORM{SUM} == 0 && $user) {
    if (defined(&recomended_pay)) {
      $FORM{SUM} = recomended_pay($user);

      if($conf{PAYSYS_NEXT_INVOICING_PERIODS} && $conf{PAYSYS_NEXT_INVOICING_PERIODS} =~ /\d+/){
        $FORM{SUM} = $FORM{SUM} * $conf{PAYSYS_NEXT_INVOICING_PERIODS};
      }
    }
  }

  # EXTERNAL COMMANDS CODE BEGIN
  if($FORM{PAYMENT_SYSTEM} && $user->{UID} && $conf{PAYSYS_EXTERNAL_START_COMMAND}){
    my $start_command = $conf{PAYSYS_EXTERNAL_START_COMMAND} || q{};
    #my $end_command   = ($Config->config_info({PARAM => 'PAYSYS_EXTERNAL_END_COMMAND'}))->{VALUE};
    #my $time          = ($Config->config_info({PARAM => 'PAYSYS_EXTERNAL_TIME'}))->{VALUE};
    my $attempts      = $conf{PAYSYS_EXTERNAL_ATTEMPTS} || 0;
    my $main_user_information = $Paysys->paysys_user_info({UID => $user->{UID}});

    if($main_user_information->{TOTAL} == 0){
      $Paysys->paysys_user_add({ ATTEMPTS          => 1,
        UID               => $user->{UID},
        EXTERNAL_USER_IP  => $ENV{REMOTE_ADDR}});
    }
    else{
      if( $main_user_information->{ATTEMPTS} && (! $attempts || $main_user_information->{ATTEMPTS} < $attempts)){
        my (undef, $now_month)  = split('-', $DATE);
        my (undef, $last_month) = split('-', $main_user_information->{EXTERNAL_LAST_DATE});
        my $paysys_id     = $main_user_information->{PAYSYS_ID};
        if(int($now_month) != int($last_month)){
          $Paysys->paysys_user_change({
            ATTEMPTS           => 1,
            UID                => $user->{UID},
            PAYSYS_ID          => $paysys_id,
            EXTERNAL_LAST_DATE => "$DATE $TIME",
            EXTERNAL_USER_IP   => ip2int($ENV{REMOTE_ADDR}),
          });
        }
        else{
          my $user_attempts = $main_user_information->{ATTEMPTS} + 1;
          $Paysys->paysys_user_change({
            ATTEMPTS  => $user_attempts,
            UID       => $user->{UID},
            PAYSYS_ID => $paysys_id,
            CLOSED    => 0,
            EXTERNAL_LAST_DATE => "$DATE $TIME",
            EXTERNAL_USER_IP   => ip2int($ENV{REMOTE_ADDR}),
          });
        }
      }
    }

    my $result = cmd($start_command, {
        PARAMS => { %$user, IP => $ENV{REMOTE_ADDR} },
      });

    if($result && $result =~ /(\d+):(.+)/) {
      my $code = $1;
      my $text = $2;

      if($code == 1){
        my $button = $html->button("$lang{SET} $lang{CREDIT}", "OPEN_CREDIT_MODAL=1", { class => 'btn btn-success'});
        $html->message('warn', $text, $button,);
        return 1;
      }

      if ($code) {
        $html->message('warn', $lang{INFO}, $text, { ID => 1730 });
        return 1;
      }
    }
  }

  my %info    = ();

  if ($ENV{'REQUEST_METHOD'} eq 'POST' && $ENV{'QUERY_STRING'}) {
    my @pairs = split(/&/, $ENV{'QUERY_STRING'});
    foreach my $pair (@pairs) {
      my ($side, $value) = split(/=/, $pair, 2);
      $FORM{$side}=$value if (! $FORM{$side});
    }
  }

  if ($FORM{pre} && $FORM{SUM} <= 0 && $FORM{PAYMENT_SYSTEM} != 43) {
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_SUM}" );
    goto PRE_LABEL;
  }

  if($user->{GID}) {
    $user->group_info($user->{GID});
    if ($user->{DISABLE_PAYSYS}) {
      $html->message( 'err', $lang{ERROR}, "$lang{DISABLE}" );
      return 0;
    }
  }

  if($FORM{INTERACT}) {
    if(! $FORM{UID} && $FORM{pre}) {
      $info{MESSAGE} = $html->message( 'err', $lang{ERROR}, "$lang{ENTER} UID", { OUTPUT2RETURN => 1 } );
      goto PRE_LABEL;
    }
    else {
      $users->list({ UID => $FORM{UID} });
      if ($users->{TOTAL} == 0) {
        $info{MESSAGE} = $html->message( 'err', $lang{ERROR}, "$lang{USER_NOT_EXIST}", { OUTPUT2RETURN => 1 } );
        goto PRE_LABEL;
      }
    }
  }

  if (! $FORM{PAYMENT_SYSTEM}) {
    $FORM{PAYMENT_SYSTEM}=0;
  }

  if( $FORM{PAYMENT_SYSTEM} && $FORM{INTERACT} && $conf{PAYSYS_INTERACT_PARAMS}){
    my @params  = split(/,[\r\n\s]?/, $conf{PAYSYS_INTERACT_PARAMS});
    my $message = '';
    my $u_pi = $users->pi( {UID => $FORM{UID}} );
    $attr->{FIO} = $u_pi->{FIO};
    $attr->{UID} = $u_pi->{UID};
    foreach my $param (@params){
      if($param eq 'FIO'){
        $message .= "<h4><b>$lang{FIO}:</b>$u_pi->{FIO}</h4>";
      }
      if($param eq 'ADDRESS_FULL'){
        $message .= "<h4><b>$lang{ADDRESS}:</b>$u_pi->{ADDRESS_FULL}</h4>";
      }
    }
    print "\t$lang{INFO}";
    print $message;
  }

  if ($conf{PAYSYS_MIN_SUM} && $FORM{SUM}>0 && $conf{PAYSYS_MIN_SUM} > $FORM{SUM}  ) {
    $html->message( 'err', $lang{ERROR}, "$lang{PAYSYS_MIN_SUM_MESSAGE} $conf{PAYSYS_MIN_SUM}" );
    goto PRE_LABEL;
  }
  elsif ($conf{PAYSYS_MAX_SUM} && $FORM{SUM}>0 && $conf{PAYSYS_MAX_SUM} < $FORM{SUM}  ) {
    $html->message( 'err', $lang{ERROR}, "ERR_BIG_SUM: $conf{PAYSYS_MAX_SUM}" );
    goto PRE_LABEL;
  }
  # new fast pay form
  elsif($conf{PAYSYS_IPAY_FAST_PAY} && ($FORM{ipay_pay} || $FORM{ipay_register_purchase} || $FORM{ipay_purchase})){
    #    $user->pi({UID => $user->{UID}});
    if(($FORM{ipay_pay} || $FORM{ipay_register_purchase}) && $FORM{SUM} <= 0){
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_SUM}" );
      return 1;
    }

    require Paysys::systems::Ipay;
    Paysys::systems::Ipay->import();
    my $Ipay = Paysys::systems::Ipay->new2(\%conf, \%FORM, \%lang, $index, $user, {HTML => $html, SELF_URL => $SELF_URL, DATETIME => "$DATE $TIME"});
    my $IPAY_HTML = $Ipay->paysys_ipay();
    $info{IPAY_HTML} = $IPAY_HTML;

  }
  elsif ($FORM{PAYMENT_SYSTEM} == 41 || $FORM{PAYMENT_SYSTEM} == 85
    #|| $FORM{LMI_PAYMENT_NO}
  ) {
    paysys_webmoney();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 42) {
    paysys_rbkmoney();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 43) {
    paysys_smsproxy();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 45 || $FORM{SHOPORDERNUMBER}) {
    paysys_portmone();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 46) {
    return paysys_ukrpays($attr);
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 48) {
    paysys_privatbank();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 50) {
    paysys_comepay();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 54) {
    return paysys_privatbank_p24($attr);
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 57) {
    paysys_easypay_fastpay();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 58) {
    paysys_lr();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 66) {
    paysys_paypal();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 67) {
    paysys_sberbank();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 69) {
    paysys_autopay();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 65) {
    paysys_privat_fastpay();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 62 || $FORM{pay_way}) {
    return paysys_liqpay($attr);
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 59) {
    return paysys_qiwi($attr);
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 72) {
    paysys_ipay();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 73) {
    paysys_yandex();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 77 or defined($FORM{abillserrormsg})) {
    paysys_cp_visa();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 86) {
    paysys_perfectmoney();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 87) {
    paysys_okpay();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 81
    || $FORM{PAYMENT_SYSTEM} == 82
    || $FORM{PAYMENT_SYSTEM} == 83
    || $FORM{PAYMENT_SYSTEM} == 84
    || $FORM{payonline_transaction}
    || $FORM{payonline_transaction_error}
    || $FORM{ErrorCode}) {
    paysys_payonline();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 89) {
    paysys_smsonline();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 90) {
    paysys_cashcom();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 91) {
    paysys_payu();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 92) {
    paysys_copayco();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 93 ||  $FORM{minbank_msg} || $FORM{minbank_action}) {
    paysys_minbank();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 94) {
    paysys_redsys();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 97) {
    paysys_paymaster();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 98) {
    paysys_upc();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 101) {
    paysys_evostok();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 102) {
    paysys_stripe($attr);
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 106) {
    paysys_paykeeper();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 104) {
    paysys_kaznachey();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 105) {
    paysys_robokassa();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 108) {
    paysys_platon();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 109) {
    paysys_fondy();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 110) {
    paysys_walletone();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 112) {
    paysys_idram();
  }
  elsif ($FORM{PAYMENT_SYSTEM} == 116) {
    paysys_mixplat();
  }
  elsif($FORM{PAYMENT_SYSTEM} == 117) {
    paysys_yandex_kassa($attr);
  }
  elsif($FORM{PAYMENT_SYSTEM} == 120) {
    paysys_tinkoff();
  }
  elsif($FORM{PAYMENT_SYSTEM} == 121) {
    paysys_cloudpayments();
  }
  elsif($FORM{PAYMENT_SYSTEM} == 122) {
    paysys_paymaster_ru();
  }
  elsif($FORM{PAYMENT_SYSTEM} == 125) {
    paysys_electrum();
  }
  elsif($FORM{PAYMENT_SYSTEM} == 126) {
    paysys_plategka();
  }
  else {
    PRE_LABEL:

    $info{OPERATION_ID} = mk_unique_value(8, { SYMBOLS => '0123456789' });

    #show interact
    # new fast pay form
    if($conf{PAYSYS_IPAY_FAST_PAY} && !$FORM{INTERACT}){
      #      $users->pi({UID => $user->{UID}});
      require Paysys::systems::Ipay;
      my $Ipay = Paysys::systems::Ipay->new2(\%conf, \%FORM, \%lang, $index, $user, {HTML => $html, SELF_URL => $SELF_URL, DATETIME => "$DATE $TIME"});
      my $IPAY_HTML = $Ipay->paysys_ipay();
      $info{IPAY_HTML} = $IPAY_HTML;

    }
    my $payment_systems_visual = paysys_system_sel() || '';

    if($payment_systems_visual ne ''){
      $info{PAY_SYSTEM_SEL} .= $payment_systems_visual;
    }
    else{
      $info{HIDE_FOOTER} = 'hidden';
    }

    if (in_array('Maps', \@MODULES)) {
      $info{MAP} = paysys_maps();
    }

    if ($FORM{INTERACT}) {
      return $html->tpl_show(_include('paysys_interact', 'Paysys'), \%info, { OUTPUT2RETURN => $attr->{OUTPUT2RETURN} });
    }
    else {
      return $html->tpl_show(_include('paysys_main', 'Paysys'), \%info, { OUTPUT2RETURN => $attr->{OUTPUT2RETURN} });
    }
  }
}

#**********************************************************
=head2 paysys_system_sel($attr) - Show availeble payment system

=cut
#**********************************************************
sub paysys_system_sel {
  my ($attr) = @_;

  my %PAY_SYSTEM_ACCOUNTS = (
    41  => 'PAYSYS_WEBMONEY_ACCOUNTS',
    42  => 'PAYSYS_RBKMONEY_ID',
    43  => 'PAYSYS_SMSPROXY',
    45  => 'PAYSYS_PORTMONE_PAYEE_ID',
    46  => 'PAYSYS_UKRPAYS_SECRETKEY',
    48  => 'PAYSYS_PB_MERID',
    50  => 'PAYSYS_COMEPAY',
    54  => 'PAYSYS_P24_MERCHANT_ID',
    57  => 'PAYSYS_EASYPAY_FASTPAY',
    58  => 'PAYSYS_LR_ACCOUNT_NUMBER',
    59  => 'PAYSYS_QIWI_TERMINAL_ID',
    62  => 'PAYSYS_LIQPAY_MERCHANT_ID',
    66  => 'PAYSYS_PAYPAL_RECIEVER_EMAIL',
    67  => 'PAYSYS_SBERBANK_ACCOUNT_KEY',
    69  => 'PAYSYS_AUTOPAY_PROVIDER',
    72  => 'PAYSYS_IPAY_MERCHANT_ID',
    73  => 'PAYSYS_YANDEX_ID',
    77  => 'PAYSYS_CP_VISA',
    81  => 'PAYSYS_QIWI_PAYONLINE',
    82  => 'PAYSYS_WEBMONEY_PAYONLINE',
    83  => 'PAYSYS_YANDEX_MONEY_PAYONLINE',
    84  => 'PAYSYS_BANK_CARD_PAYONLINE',
    85  => 'PAYSYS_WEBMONEY_TERMINAL',
    86  => 'PAYSYS_PERFECTMONEY_ACCOUNTID',
    87  => 'PAYSY_OKPAY_RECEIVER',
    89  => 'PAYSYS_SMSONLINE',
    90  => 'PAYSYS_CASHCOM_PROVIDER_ID',
    91  => 'PAYSYS_PAYU_MERCHANT',
    92  => 'PAYSYS_COPAYCO_SHOP_ID',
    93  => 'PAYSYS_MINBANK_MERCHANT_ID',
    94  => 'PAYSYS_REDSYS_MERCHANT_ID',
    97  => 'PAYSYS_PAYMASTER_SECRET',
    98  => 'PAYSYS_UPC_MERCHANT_ID',
    101 => 'PAYSYS_EVOSTOK_KEY',
    102 => 'PAYSYS_STRIPE_SECRET_KEY',
    106 => 'PAYSYS_PAYKEEPER_KEY',
    104 => 'PAYSYY_KAZNACHEY_SECRET_KEY',
    105 => 'PAYSYS_ROBOKASSA_PASSWORD_ONE',
    108 => 'PAYSYS_PLATON_KEY',
    109 => 'PAYSYS_FONDY_PASSWORD',
    110 => 'PAYSYS_WALLETONE_MERCH_ID',
    112 => 'PAYSYS_IDRAM_SECRET_KEY',
    65  => 'PAYSYS_PRIVAT_TERMINAL_FAST_PAY',
    116 => 'PAYSYS_MIXPLAT_SECRET_KEY',
    117 => 'PAYSYS_YANDEX_KASSA_SCID',
    120 => 'PAYSYS_TINKOFF_TERMINAL_KEY',
    121 => 'PAYSYS_CLOUDPAYMENTS_ID',
    122 => 'PAYSYS_PAYMASTERRU_MERCHANT_ID',
    125 => 'PAYSYS_ELECTRUM_URL',
    126 => 'PAYSYS_PLATEGKA_MERCHANT_ID'
  );

  # list of paysys for user group
  my $groups_systems = ();
  if($user->{GID}){
    $Paysys->groups_settings_list({
      GID       => $user->{GID},
      PAYSYS_ID => '_SHOW',
      LIST2HASH => 'paysys_id, gid'
    });

    $groups_systems = $Paysys->{list_hash};
  }

  # New scheme for turn on payment systems
  $Paysys->paysys_connect_system_list({
    STATUS    => '_SHOW',
    LIST2HASH => 'id, status'
  });

  my $connected_systems = $Paysys->{list_hash} || {};

  while (my ($k, undef) = each %PAY_SYSTEMS) {
    if($connected_systems->{$k}){
      next;
    }

    my $DELETE = exists($PAY_SYSTEM_ACCOUNTS{$k});
    if ($DELETE != 1) {
      delete $PAY_SYSTEMS{$k};
      next;
    }

    delete $PAY_SYSTEMS{$k} if (!$conf{ $PAY_SYSTEM_ACCOUNTS{$k} });

    if ($k == 54) {
      delete $PAY_SYSTEMS{$k} if ($conf{PAYSYS_P24_SKIP_PORTAL});
    }

    # if groups systems more then zero, delete unchecked systems
    if (scalar keys %{$groups_systems} > 0) {
      delete $PAY_SYSTEMS{$k} if (!$groups_systems->{$k});
    }

  }

  if ($attr->{ONLY_SYSTEMS} && $attr->{ONLY_SYSTEMS} == 1) {
    return %PAY_SYSTEMS;
  }

  my $radio_paysys;
  my $paysys_logo_path = $base_dir . 'cgi-bin/styles/default_adm/img/paysys_logo/';
  my $file_path = q{};

  my $first_system = 1;
  foreach my $id (sort keys %PAY_SYSTEMS) {
    #radio_paysys .= "
    # <div class='col-md-4'>
    # <div class='box box-theme text-center'>
    # <div class='box-body' id='paysys-chooser'>
    #   <label class='control-element' for='$id'>
    #     <img class='img-responsive' src='http://abills.net.ua/wiki/lib/exe/fetch.php/abills:docs:modules:paysys:" . lc("$PAY_SYSTEMS{$id}") . "-logo.png'>
    #     $PAY_SYSTEMS{$id}
    #   </label>
    #     <input type='radio' required name='PAYMENT_SYSTEM' id='$id' value='$id'>
    # </div>

    # </div>

    # </div>
    # ";
    my $paysys_name = $PAY_SYSTEMS{$id};
    $paysys_name =~ s/ /_/g;
    $paysys_name = lc($paysys_name);

    if (-e "$paysys_logo_path" . lc($paysys_name) . "-logo.png") {
      $file_path = "/styles/default_adm/img/paysys_logo/" . lc($paysys_name) . "-logo.png";
    }
    else {
      $file_path = "http://abills.net.ua/wiki/lib/exe/fetch.php/abills:docs:modules:paysys:" . lc("$PAY_SYSTEMS{$id}") . "-logo.png";
    }
    $radio_paysys .= $html->tpl_show(
      _include('paysys_system_select', 'Paysys'),
      {
        PAY_SYSTEM_LC   => $file_path,
        PAY_SYSTEM      => $id,
        PAY_SYSTEM_NAME => $PAY_SYSTEMS{$id},
        CHECKED         => ($first_system == 1) ? 'checked' : ''
      },
      { OUTPUT2RETURN => 1 }
    );
    $first_system++;
  }

  return $radio_paysys;
}


#**********************************************************
=head2 paysys_log() - Show paysys operations

=cut
#**********************************************************
sub paysys_log {

  if (form_purchase_module({
    HEADER          => $user->{UID},
    MODULE          => 'Paysys',
    REQUIRE_VERSION => 4.21
  })) {
    return 0;
  }

  if ($FORM{info}) {

    $Paysys->info({ ID => $FORM{info} });
    $Paysys->{INFO} = convert($Paysys->{INFO}, { text2html => 1 });
    my @info_arr = split(/\n/, $Paysys->{INFO} || q{});
    my $table = $html->table({ width => '100%' });
    foreach my $line (@info_arr) {
      my ($k, $v) = split(/,/, $line, 2);
      $table->addrow($k, $v);
    }

    $Paysys->{INFO} = $table->show();
    $table = $html->table(
      {
        width   => '500',
        caption => $lang{INFO},
        rows    => [
          [ "ID",            $Paysys->{ID}        ],
          [ "$lang{LOGIN}", $Paysys->{LOGIN} ],
          [ "$lang{DATE}", $Paysys->{DATETIME} ],
          [ "$lang{SUM}", $Paysys->{SUM} ],
          [ "$lang{COMMISSION}", $Paysys->{COMMISSION} ],
          [ "$lang{PAY_SYSTEM}", $PAY_SYSTEMS{ $Paysys->{SYSTEM_ID} } ],
          [ "$lang{TRANSACTION}", $Paysys->{TRANSACTION_ID} ],
          [ "$lang{USER} IP", $Paysys->{CLIENT_IP} ],
          [ "PAYSYS IP",     $Paysys->{PAYSYS_IP} ],
          [ "$lang{INFO}", $Paysys->{INFO} ],
          [ "$lang{ADD_INFO}", $Paysys->{USER_INFO} ],
          [ "$lang{STATUS}", $status[ $Paysys->{STATUS} ] ],
        ],
        ID      => 'PAYSYS_INFO'
      }
    );

    print $table->show();
  }
  elsif (defined($FORM{del}) && ($FORM{COMMENTS} || $FORM{is_js_confirmed} )) {
    $Paysys->del($FORM{del});

    if (!$Paysys->{errno}) {
      $html->message( 'info', $lang{DELETED}, "$lang{DELETED} $FORM{del}" );
    }
  }

  _error_show($Paysys);

  my %info = ();

  if ($FORM{search_form} && !$user->{UID}) {
    my %ACTIVE_SYSTEMS = %PAY_SYSTEMS;

    while (my ($k, $v) = each %CONF_OPTIONS) {
      if (!$conf{$k}) {
        delete $ACTIVE_SYSTEMS{$v};
      }
    }

    $info{PAY_SYSTEMS_SEL} = $html->form_select(
      'PAYMENT_SYSTEM',
      {
        SELECTED => $FORM{PAYMENT_SYSTEM} || '',
        SEL_HASH => { '' => $lang{ALL}, %ACTIVE_SYSTEMS },
        NO_ID    => 1
      }
    );

    $info{STATUS_SEL} = $html->form_select(
      'STATUS',
      {
        SELECTED     => $FORM{STATUS} || '',
        SEL_ARRAY    => \@status,
        ARRAY_NUM_ID => 1,
        SEL_OPTIONS  => { '' => $lang{ALL} }
      }
    );

    $info{DATERANGE_PICKER} = $html->form_daterangepicker({
      NAME      => 'FROM_DATE/TO_DATE',
      #      FORM_NAME => 'invoice_add',
      VALUE     => $FORM{'FROM_DATE_TO_DATE'},
    });

    form_search({ SEARCH_FORM => $html->tpl_show(_include('paysys_search', 'Paysys'),
        { %info, %FORM },
        { OUTPUT2RETURN => 1 }),
      ADDRESS_FORM  => 1 });
  }

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }
  my Abills::HTML $table;
  my $list;
  ($table, $list) = result_former({
    INPUT_DATA      => $Paysys,
    FUNCTION        => 'list',
    BASE_FIELDS     => 7,
    FUNCTION_FIELDS => 'status, del',
    EXT_TITLES      => {
      id             => 'ID',
      system_id      => $lang{PAY_SYSTEM},
      transaction_id => $lang{TRANSACTION},
      info           => $lang{INFO},
      sum            => $lang{SUM},
      ip             => "$lang{USER} IP",
      status         => $lang{STATUS},
      date           => $lang{DATE},
      month          => $lang{MONTH},
      datetime        => $lang{DATE},
    },
    TABLE           => {
      width      => '100%',
      caption    => "Paysys",
      cols_align => [ 'left', 'left', 'right', 'right', 'left', 'right', 'right', 'center:noprint', 'center:noprint' ],
      qs         => $pages_qs,
      pages      => $Paysys->{TOTAL},
      ID         => 'PAYSYS_LOG',
      EXPORT    => "$lang{EXPORT} XML:&xml=1",
      MENU      => "$lang{SEARCH}:index=$index&search_form=1:search;",
    },
  });

  foreach my $line (@$list) {
    my @fields_array = ($line->{id},
      $html->button($line->{login}, "index=15&UID=$line->{uid}"),
      $line->{datetime},
      $line->{sum},
      (($PAY_SYSTEMS{$line->{system_id}}) ? $PAY_SYSTEMS{$line->{system_id}} : "Unknown: ". $line->{system_id}),
      $html->button("$line->{transaction_id}", "index=2&EXT_ID=$line->{transaction_id}&search=1"),
      #"$line->{status}:$status[$line->{status}]"
      "$line->{status}:" . $html->color_mark($status[$line->{status}], $status_color[$line->{status}]),
    );

    for (my $i = 7; $i < 7+$Paysys->{SEARCH_FIELDS_COUNT}; $i++) {
      push @fields_array, $line->{$Paysys->{COL_NAMES_ARR}->[$i]};
    }

    $table->addrow(
      @fields_array,
      $html->button( $lang{INFO}, "index=$index&info=$line->{id}", { class => 'show' } )
        .' '.  ($user->{UID} ? '-' : $html->button( $lang{DEL}, "index=$index&del=$line->{id}",
          { MESSAGE => "$lang{DEL} $line->{id}?", class => 'del' } ))
    );
  }
  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right', 'right', 'right' ],
      rows       => [ [ "$lang{TOTAL}:", $html->b( $Paysys->{TOTAL} ), "$lang{SUM}", $html->b( $Paysys->{SUM} ) ],
        [ "$lang{TOTAL} $lang{COMPLETE}:", $html->b( $Paysys->{TOTAL_COMPLETE} ), "$lang{SUM} $lang{COMPLETE}:",
          $html->b( $Paysys->{SUM_COMPLETE} ) ]
      ]
    }
  );
  if(!$admin->{MAX_ROWS}){
    print $table->show();
  }
  # print $table->show();

  return 1;
}

#**********************************************************
=head2  paysys_user_log() User paysys log

=cut
#**********************************************************
sub paysys_user_log {

  if ($FORM{info}) {
    $Paysys->info({ ID => $FORM{info} });

    my @info_arr = split(/\n/, $Paysys->{INFO});
    my $table = $html->table({ width => '100%' });
    foreach my $line (@info_arr) {
      my ($k, $v) = split(/,/, $line, 2);
      $table->addrow($k, $v) if ($k =~ /STATUS/);
    }

    $Paysys->{INFO} = $table->show({ OUTPUT2RETURN => 1 });

    $table = $html->table(
      {
        width => '500',
        rows =>
        [ [ "ID", $Paysys->{ID} ],
          [ "$lang{LOGIN}", $Paysys->{LOGIN} ],
          [ "$lang{DATE}", $Paysys->{DATETIME} ],
          [ "$lang{SUM}", $Paysys->{SUM} ],
          [ "$lang{PAY_SYSTEM}", $PAY_SYSTEMS{ $Paysys->{SYSTEM_ID} } ],
          [ "$lang{TRANSACTION}", $Paysys->{TRANSACTION_ID} ],
          [ "$lang{USER} IP", $Paysys->{CLIENT_IP} ],
          [ "$lang{ADD_INFO}", $Paysys->{USER_INFO} ],
          [ "$lang{INFO}", $Paysys->{INFO} ] ],
      }
    );

    print $table->show();
  }

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my $list  = $Paysys->list({%LIST_PARAMS, COLS_NAME => 1 });
  my $table = $html->table(
    {
      width      => '100%',
      caption    => "Paysys",
      title      =>
      [ 'ID', "$lang{DATE}", "$lang{SUM}", "$lang{PAY_SYSTEM}", "$lang{TRANSACTION}", "$lang{STATUS}", '-' ],
      qs         => $pages_qs,
      pages      => $Paysys->{TOTAL},
      ID         => 'PAYSYS'
    }
  );

  foreach my $line (@$list) {
    $table->addrow($line->{id},
      $line->{datetime},
      $line->{sum},
      $PAY_SYSTEMS{$line->{system_id}},
      $line->{transaction_id},
      #"$status[$line->{status}]",
      $html->color_mark($status[$line->{status}], "$status_color[$line->{status}]"),
      $html->button( $lang{INFO}, "index=$index&info=$line->{id}" ) );
  }
  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      rows       =>
      [ [ "$lang{TOTAL}:", $html->b( $Paysys->{TOTAL_COMPLETE} ), "$lang{SUM}:", $html->b( $Paysys->{SUM_COMPLETE} ) ] ]
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
=head2 paysys_webmoney() - webmoney and webmoney UA support

=cut
#**********************************************************
sub paysys_webmoney {

  conf_gid_split({ GID    => $user->{GID},
    PARAMS => [
      'PAYSYS_LMI_SECRET_KEY',
      'PAYSYS_WEBMONEY_ACCOUNTS',
    ],
  });

  if ($FORM{FALSE}) {
    $html->message( 'err', $lang{ERROR}, "$lang{FAILED} $lang{TRANSACTION} ID: $FORM{LMI_PAYMENT_NO}" );
  }
  elsif ($FORM{LMI_PAYMENT_NO}) {
    my $users = Users->new($db, $admin, \%conf);
    my $user_ = $users->info($FORM{UID});

    if (! _error_show($user_)) {
      if ($conf{PAYSYS_LMI_RESULT_URL}) {
        $html->message( 'info', $lang{INFO}, "$lang{ADDED} ID: $FORM{LMI_PAYMENT_NO}" );
      }
      else {
        paysys_show_result({ TRANSACTION_ID =>  "$FORM{'LMI_PAYMENT_NO'}" });
      }
    }
    return 0;
  }

  my %info = ();
  $info{LMI_PAYMENT_NO} = $FORM{OPERATION_ID};

  if ($conf{PAYSYS_WEBMONEY_TESTMODE}) {
    my ($LMI_MODE, $LMI_SIM_MODE) = split(/:/, $conf{PAYSYS_WEBMONEY_TESTMODE}, 2);
    $info{TEST_MODE} = "
   <input type='hidden' name='LMI_SIM_MODE' value='$LMI_SIM_MODE'>
   <font color='red'>$lang{TEST_MODE} (LMI_MODE: $LMI_MODE, LMI_SIM_MODE: $LMI_SIM_MODE)</font>";
  }


  # Terminal auth type
  if ($FORM{PAYMENT_SYSTEM} == 85) {
    $info{AT}='?at=authtype_8';
  }

  my @ACCOUNTS = split(/;/, $conf{PAYSYS_WEBMONEY_ACCOUNTS});
  $info{ACCOUNTS_SEL} = $html->form_select(
    'LMI_PAYEE_PURSE',
    {
      SELECTED  => $FORM{sum_val},
      SEL_ARRAY => \@ACCOUNTS,
      NO_ID     => 1
    }
  );

  $info{LMI_PAYMENT_AMOUNT}    = $FORM{SUM};
  my $pay_describe             = "Login: $LIST_PARAMS{LOGIN}, UID: $LIST_PARAMS{UID}";
  $info{DESCRIBE}              = $pay_describe;
  $info{LMI_PAYMENT_DESC}      = ($conf{dbcharset} eq 'utf8') ? convert($pay_describe, { utf82win => 1 }) : $pay_describe;
  $conf{PAYSYS_LMI_RESULT_URL} = "http://$ENV{SERVER_NAME}" . (($ENV{SERVER_PORT} != 80) ? ":$ENV{SERVER_PORT}" : '') . "/paysys_check.cgi" if (!$conf{PAYSYS_LMI_RESULT_URL});
  $info{ACTION_URL}            = ($conf{PAYSYS_WEBMONEY_UA}) ? 'https://lmi.PayMaster.ua/' : 'https://merchant.webmoney.ru/lmi/payment.asp'.($info{AT} || '');

  $html->tpl_show(_include('paysys_webmoney_add', 'Paysys'), \%info);

  return 1;
}

#**********************************************************
=head2 paysys_paymaster() - webmoney and webmoney UA support

=cut
#**********************************************************
sub paysys_paymaster {

  conf_gid_split({ GID    => $user->{GID},
    PARAMS => [
      'PAYSYS_LMI_SECRET_KEY',
      'PAYSYS_WEBMONEY_ACCOUNTS',
    ],
  });

  if ($FORM{FALSE}) {
    $html->message( 'err', $lang{ERROR}, "$lang{FAILED} $lang{TRANSACTION} ID: $FORM{LMI_PAYMENT_NO}" );
  }
  elsif($FORM{LMI_CLIENT_MESSAGE}) {
    $html->message( 'err', $lang{ERROR}, "$FORM{LMI_CLIENT_MESSAGE}" );
  }
  elsif ($FORM{LMI_PAYMENT_NO}) {
    my $users = Users->new($db, $admin, \%conf);
    my $user_ = $users->info($FORM{UID});

    if (! _error_show($user_)) {
      if ($conf{PAYSYS_LMI_RESULT_URL}) {
        $html->message( 'info', $lang{INFO}, "$lang{ADDED} ID: $FORM{LMI_PAYMENT_NO}" );
      }
      else {
        paysys_show_result({ TRANSACTION_ID =>  "$FORM{'LMI_PAYMENT_NO'}" });
      }
    }

    return 0;
  }

  my %info = ();
  $info{LMI_PAYMENT_NO} = $FORM{OPERATION_ID};

  if ($conf{PAYSYS_PAYMASTER_TESTMODE}) {
    my ($LMI_MODE, $LMI_SIM_MODE) = split(/:/, $conf{PAYSYS_PAYMASTER_TESTMODE}, 2);
    $info{TEST_MODE} = "
   <input type='hidden' name='LMI_SIM_MODE' value='$LMI_SIM_MODE'>
   <font color='red'>$lang{TEST_MODE} (LMI_MODE: $LMI_MODE, LMI_SIM_MODE: $LMI_SIM_MODE)</font>";
  }

  # Terminal auth type
  if ($FORM{PAYMENT_SYSTEM} == 85) {
    $info{AT}='?at=authtype_8';
  }

  # bugfix: my @ACCOUNTS = split(/;/, $conf{PAYSYS_WEBMONEY_ACCOUNTS});
  my @ACCOUNTS = $conf{PAYSYS_WEBMONEY_ACCOUNTS} ? split(/;/, $conf{PAYSYS_WEBMONEY_ACCOUNTS}) : '';
  $info{ACCOUNTS_SEL} = $html->form_select(
    'LMI_PAYEE_PURSE',
    {
      SELECTED  => $FORM{sum_val},
      SEL_ARRAY => \@ACCOUNTS,
      NO_ID     => 1
    }
  );

  $info{LMI_PAYMENT_AMOUNT}    = $FORM{SUM};
  my $pay_describe             = "Login: $LIST_PARAMS{LOGIN}, UID: $LIST_PARAMS{UID}";
  $info{DESCRIBE}              = $pay_describe;
  $info{LMI_PAYMENT_DESC}      = ($conf{dbcharset} eq 'utf8') ? convert($pay_describe, { utf82win => 1 }) : $pay_describe;
  $conf{PAYSYS_LMI_RESULT_URL} = "http://$ENV{SERVER_NAME}" . (($ENV{SERVER_PORT} != 80) ? ":$ENV{SERVER_PORT}" : '') . "/paysys_check.cgi" if (!$conf{PAYSYS_LMI_RESULT_URL});
  # bugfix: $info{ACTION_URL}            = 'https://lmi.PayMaster.ua/'.$info{AT};
  $info{ACTION_URL}            = 'https://lmi.PayMaster.ua/'. ($info{AT} ? $info{AT} : '');

  $html->tpl_show(_include('paysys_paymaster_add', 'Paysys'), \%info);
}


#**********************************************************
=head paysys_ukrpays($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub paysys_ukrpays {
  my ($attr) = @_;

  my $payment_system    = $attr->{SYSTEM_SHORT_NAME} || 'UKRPAYS';
  my $payment_system_id = $attr->{SYSTEM_ID}         || 46;
  my %info = ();
  $FORM{SYSTEM_SHORT_NAME}=$payment_system;


  if ($FORM{FALSE}) {
    $html->message( 'err', $lang{ERROR}, "$lang{FAILED} $lang{TRANSACTION} ID: $FORM{OPERATION_ID}" );
    return 0;
  }
  if ($FORM{TRUE}) {
    paysys_show_result({ %$attr, TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}" });
    return 1;
  }

  #pre registration payments throught start
  if ($LIST_PARAMS{UID} && $LIST_PARAMS{UID} =~ /:/) {
    #Info section
    $Paysys->add(
      {
        SYSTEM_ID      => $payment_system_id,
        SUM            => $FORM{SUM},
        UID            => $LIST_PARAMS{UID},
        IP             => "$ENV{'REMOTE_ADDR'}",
        TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
        STATUS         => 1,
        DOMAIN_ID      => $user->{DOMAIN_ID}
      }
    );

    if ($Paysys->{errno}) {
      $html->message( 'err', "$lang{ERROR}", "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}'" );
      return 0;
    }

    %info = (
      UID => "$FORM{OPERATION_ID}:$admin->{DOMAIN_ID}",
      FIO => $user->{FIO}
    );
  }
  else {
    if (! $user->{FIO}) {
      $user->pi({ UID => $LIST_PARAMS{UID} || $user->{UID} });
    }

    %info = (
      UID => $LIST_PARAMS{UID},
      FIO => $user->{FIO}
    );
  }

  conf_gid_split({ GID    => $user->{GID},
    PARAMS => [
      'PAYSYS_UKRPAYS_SERVICE_ID',
    ],
  });

  $info{AMOUNT} = sprintf("%.2f", $FORM{SUM});
  $info{SUS_URL_PARAMS} = $attr->{SUS_URL_PARAMS} || '';

  $conf{PAYSYS_UKRPAYS_URL} = 'https://ukrpays.com/frontend/frontend.php' if (!$conf{PAYSYS_UKRPAYS_URL});

  return $html->tpl_show(_include('paysys_ukrpays_add', 'Paysys'), \%info, { OUTPUT2RETURN => $attr->{OUTPUT2RETURN} });
}

#**********************************************************
=head2 paysys_periodic()

=cut
#**********************************************************
sub paysys_periodic {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "Paysys: Daily periodic payments\n" if ($debug > 1);

  my %PAYSYS_PAYMENT_METHODS = ();

  if($conf{PAYSYS_PAYMENTS_METHODS}) {
    %PAYSYS_PAYMENT_METHODS = %{ cfg2hash($conf{PAYSYS_PAYMENTS_METHODS}) };
  }

  if ($conf{PAYSYS_PORTMONE_PAYEE_ID}) {
    paysys_load('Portmone');

    #my $payment_system    = 'PM';
    my $payment_system_id = 45;
    my $status;

    $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
    my ($y, $m, $mday) = split(/-/, $ADMIN_REPORT{DATE});

    #replace the parameters with your own values..
    my $mon  = $m - 1;
    my $year = $y - 1900;
    my $timestamp = POSIX::mktime(0, 0, 0, $mday, $mon, $year, 0, 0, -1);
    my $DATE      = POSIX::strftime('%Y-%m-%d', localtime($timestamp - 86400));
    my $res_arr   = paysys_portmone_result(0, { DEBUG => $debug, DATE => $DATE });

    if ( ref $res_arr ne 'ARRAY' || $#{$res_arr}  == 0){
      return 0;
    }

    my %res_hash = ();
    for (my $i = 0 ; $i <= $#{$res_arr} ; $i++) {
      $res_hash{ 'PM:'.$res_arr->[$i]{ordernumber} } = $i;
    }

    my $list = $Paysys->list({ DATE           => $DATE,
      PAYMENT_SYSTEM => $payment_system_id,
      ID             => '_SHOW',
      SUM            => '_SHOW',
      TRANSACTION_ID => '_SHOW',
      STATUS         => 1,
      COLS_NAME      => 1,
    });

    my $users = Users->new($db, $admin, \%conf);
    foreach my $line (@$list) {
      #Add payments to abills
      $debug_output .= "Unfinished payment ID: $line->{id}/$line->{transaction_id}\n" if ($debug > 2);
      if (defined($res_hash{ $line->{transaction_id} })) {
        my $uid       = $line->{uid};
        my $sum       = $line->{sum};
        my $order_num = $line->{transaction_id};
        my $user_      = $users->info($uid);

        if ($res_arr->[$res_hash{$line->{transaction_id}}]{approvalcode} > 0) {
          $Payments->add(
            $user_,
            {
              SUM          => $sum,
              DESCRIBE     => 'PORTMONE',
              METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
              EXT_ID       => "PM:$order_num",
              CHECK_EXT_ID => "PM:$order_num"
            }
          );
        }

        #Exists
        if ($Payments->{errno}) {
          if ($Payments->{errno} == 7) {
            $status = 8;
          }
          else {
            $status = 4;
          }
        }
        else {
          $status = 0;
          my $info   = '';
          while(my($k, $v) = each %{ $res_arr->[$res_hash{$line->{transaction_id}}] } ) {
            $info .= "$k, $v\n";
          }

          if ($res_arr->[$res_hash{$line->{transaction_id}}]{approvalcode} > 0) {
            $status=2;
            $debug_output .= "Add payments TRANSACTION_ID: $line->{transaction_id}\n" if ($debug > 0);
          }
          else {
            $status=6;
            $debug_output .= "Add payments Error: TRANSACTION_ID: $line->{transaction_id} / [$res_hash{$line->{transaction_id}}]{error_code} ([$res_hash{$line->{transaction_id}}]{error_message}) \n" if ($debug > 0);
          }

          $Paysys->change(
            {
              ID     => $line->{id},
              INFO   => $info. ' (periodic)',
              STATUS => $status
            }
          );
          $status = 1;
        }

        if ($conf{PAYSYS_EMAIL_NOTICE}) {
          my $message = "\n" . "System: Portmone\n" . "DATE: $DATE $TIME\n" . "LOGIN: $user->{LOGIN} [$uid]\n" . "\n" . "\n" . "ID: $line->{id}\n" . "SUM: $sum\n";
          sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "Paysys Portmone Add", "$message", "$conf{MAIL_CHARSET}", "2 (High)");
        }
      }
    }
  }
  elsif($conf{PAYSYS_ELECTRUM_URL}){
    my $payment_system_id = 125;
    my $payment_system = 'Electrum';

    require Paysys::systems::Electrum;
    Paysys::systems::Electrum->import();
    my $Electrum = Paysys::systems::Electrum->new(\%conf);

    my $list = $Paysys->list({
      PAYMENT_SYSTEM => $payment_system_id,
      ID             => '_SHOW',
      SUM            => '_SHOW',
      TRANSACTION_ID => '_SHOW',
      STATUS         => 1,
      LIST2HASH      => 'transaction_id,status'
    });

    my $list2hash = $Paysys->{list_hash};

    my $list_requests = $Electrum->list_requests();

    foreach my $request (@$list_requests) {
      if ($list2hash->{"$payment_system:$request->{id}"}) {
        if ($request->{status} eq 'Paid') {
          my $paysys_status = paysys_pay(
            {
              PAYMENT_SYSTEM    => $payment_system,
              PAYMENT_SYSTEM_ID => $payment_system_id,
              #CHECK_FIELD       => $conf{PAYSYS_YANDEX_KASSA_ACCOUNT_KEY},
              #USER_ID           => $FORM{customerNumber},
              SUM               => ($request->{amount} / 100000000),
              ORDER_ID          => "$payment_system:$request->{id}",
              EXT_ID            => $request->{id},
              # REGISTRATION_ONLY => 1,
              DATA              => $request,
              MK_LOG            => 1,
              DEBUG             => 1,
            }
          );
        }
      }
    }
  }

  if($conf{PAYSYS_PLATEGKA_MERCHANT_ID}){
    my $payment_system_id = 126;
    my $payment_system = 'Plategka';

    require Paysys::systems::Plategka;
    Paysys::systems::Plategka->import();
    my $Plategka= Paysys::systems::Plategka->new(\%conf, \%FORM, $admin, $db, { HTML => $html });

    $Plategka->periodic();
  }

  if ($conf{PAYSYS_P24_API_PERIODIC} && $conf{PAYSYS_P24_API_AUTO_INFO}) {
    my @merchants = split(';', $conf{PAYSYS_P24_API_AUTO_INFO}); # list of merchants
    my $url = "https://acp.privatbank.ua/api/proxy/transactions/today"; # url for api
    my $success_payments = 0;
    my $not_success_payments = 0;
    my $already_exist_payments = 0;

    foreach my $merchant (@merchants) {
      my ($bill, $id, $token) = split(':', $merchant);

      #request for transactions list
      my $json_result = web_request($url, {
          #      POST    => qq[{"sessionId":"$session_id"}],
          DEBUG       => 0,
          HEADERS     => [ "Content-Type: application/json; charset=utf8", "id: $id", "token: $token" ],
          JSON_RETURN => 1,
        });

      # if there is no error
      if ($json_result->{StatementsResponse}) {
        # show error if something wrong
        if (!$json_result->{StatementsResponse}->{statements} || ref $json_result->{StatementsResponse}->{statements} ne 'ARRAY') {
          print "NOT ARRAY REF";
          return 1;
        }
      }

      #BPL_SUM - сумма платежа
      #BPL_OSND - коментарий
      #DATE_TIME_DAT_OD_TIM_P - дата время
      #AUT_MY_NAM -
      #BPL_PR_PR - статус(r - проведена)
      #DATE_TIME_DAT_OD_TIM_P - дата

      # get payments list for this system
      my $payments_extid_list = 'P24_API:*';
      my $payments_list = $Payments->list({ EXT_ID => $payments_extid_list,
        DATETIME                                   => '_SHOW',
        PAGE_ROWS                                  => 100000,
        COLS_NAME                                  => 1,
      });

      # make hash with added payments
      my %added_payments = ();
      foreach my $line (@$payments_list) {
        if ($line->{ext_id}) {
          $line->{ext_id} =~ s/$payments_extid_list://;
          $added_payments{ $line->{ext_id} } = "$line->{id}:" . "$line->{uid}:" . ($line->{login} || '') . ":$line->{datetime}";
        }
      }

      my $transactions = $json_result->{StatementsResponse}{statements}[0]{$bill};
      foreach my $transaction (@$transactions) {
        my ($tran_id) = keys %$transaction;
        my $transaction_info = $transaction->{$tran_id}; # get transaction info

        my $amount = $transaction_info->{BPL_SUM};
        my $comment = $transaction_info->{BPL_OSND};
        use Encode;
        $comment = decode_utf8($comment);
        my $status = $transaction_info->{BPL_PR_PR};
        my $date = $transaction_info->{DATE_TIME_DAT_OD_TIM_P};
        $date =~ s/\./\-/g;
        my ($user_identifier) = $comment =~ /$conf{PAYSYS_P24_API_PARSE}/;

        if (exists $added_payments{$tran_id}) {
          print "Payment $tran_id exist\n";
          $already_exist_payments++;
          next;
        }
        else {
          if($conf{PAYSYS_P24_API_FILTER} && $comment =~ /$conf{PAYSYS_P24_API_FILTER}/){
            next;
          }

          if ($status ne "r") {
            print "Payment $tran_id not success in private";
            $not_success_payments++;
            next;
          };

          if (!$user_identifier || $user_identifier eq "") {
            print "Payment $tran_id. User identifier is empty\n";
            $not_success_payments++;
            next;
          };

          # if payments is new - add it to base
          require Paysys::systems::P24_api;
          Paysys::systems::P24_api->import();
          my $P24 = Paysys::systems::P24_api->new(\%conf);

          my $payment_status = $P24->make_payment({
            TRANSACTION_ID => $tran_id,
            ACCOUNT_KEY    => $user_identifier,
            SUM            => $amount,
            #                      DATE           => $date || $DATE,
            COMMENT        => $comment || '',
          });

          print "Payment $tran_id. User $user_identifier. Payment status $payment_status\n";
          $success_payments++;
        }
      }
    }

    print "Sucecss payments - $success_payments\n";
    print "Not sucecss payments - $not_success_payments\n";
    print "Already exist payments - $already_exist_payments\n";
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}


#**********************************************************
=head2 paysys_portmone() -

  ?SHOPORDERNUMBER=23432432&BILL_AMOUNT=10&APPROVALCODE=12121&RESULT=0
  http://portmone.ua

=cut
#**********************************************************
sub paysys_portmone {

  paysys_load('Portmone');
  my $payment_system = 'PM';

  if ($FORM{RESULT}) {
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}", FALSE => 1 });
  }
  elsif ($FORM{SHOPORDERNUMBER}) {
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}" });
    return 0;
  }
  else {
    my %PAYSYS_PAYMENT_METHODS = ();

    if($conf{PAYSYS_PAYMENTS_METHODS}) {
      %PAYSYS_PAYMENT_METHODS = %{ cfg2hash($conf{PAYSYS_PAYMENTS_METHODS}) };
    }

    #Info section
    $Paysys->add(
      {
        SYSTEM_ID      => 45,
        DATETIME       => "$DATE $TIME",
        SUM            => $FORM{SUM},
        UID            => $LIST_PARAMS{UID},
        IP             => $FORM{IP},
        TRANSACTION_ID => "PM:$FORM{OPERATION_ID}",
        INFO           => '-',
        PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
        STATUS         => 1
      }
    );

    if ($Paysys->{errno}) {
      $html->message( 'err', "$lang{ERROR}", "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}'" );

      return 1;
    }
  }

  my %info = ();

  conf_gid_split({ GID    => $user->{GID},
    PARAMS => [
      'PAYSYS_PORTMONE_PAYEE_ID',
      'PAYSYS_PORTMONE_PASS',
    ],
  });

  if (!$conf{PAYSYS_PORTMONE_PAYEE_ID}) {
    $html->message( 'err', "$lang{ERROR}", " $lang{NOT_EXIST} " . '$conf{PAYSYS_PORTMONE_PAYEE_ID}' );
    return 0;
  }

  $conf{PAYSYS_LMI_RESULT_URL} = "http://$ENV{SERVER_NAME}" . (($ENV{SERVER_PORT} != 80) ? ":$ENV{SERVER_PORT}" : '') . "/paysys_check.cgi" if (!$conf{PAYSYS_LMI_RESULT_URL});

  if ($html->{language} eq 'english') {
    $info{LANG} = 'en';
  }
  elsif ($html->{language} eq 'ukrainian') {
    $info{LANG} = 'uk';
  }
  else {
    $info{LANG} = 'ru';
  }

  $html->tpl_show(_include('paysys_portmone_add', 'Paysys'), \%info);
}

#**********************************************************
#
#**********************************************************
sub paysys_smsproxy {
  my %info = ();

  if ($FORM{CODE}) {
    my $list = $Paysys->info({ CODE => "$FORM{CODE}", UID => 0 });

    if ($Paysys->{TOTAL} > 0) {
      my @info_arr = split(/, /, $Paysys->{INFO});
      my %INFO_HASH = ();
      foreach my $l (@info_arr) {
        my ($k, $v) = split(/: /, $l, 2);
        $INFO_HASH{$k} = $v;
      }

      if ($Paysys->{UID} > 0) {
        $html->message( 'err', $lang{ERROR}, "$lang{FAILED}" );
      }
      else {
        my $users = Users->new($db, $admin, \%conf);
        my $user_ = $users->info($LIST_PARAMS{UID});

        if (! _error_show($user_)) {
          #Exchange rate
          my $er = 1;
          $Payments->exchange_info(0, { SHORT_NAME => "SMSPROXY" });
          if ($Payments->{TOTAL} > 0) {
            $er = $Payments->{ER_RATE};
          }

          $Payments->add(
            $user,
            {
              SUM          => $Paysys->{SUM},
              DESCRIBE     => 'SMSProxy',
              METHOD       => '2',
              EXT_ID       => $Paysys->{TRANSACTION_ID},
              CHECK_EXT_ID => $Paysys->{TRANSACTION_ID},
              ER           => $er
            }
          );

          if ($Payments->{errno} && $Payments->{errno} == 7) {
            $html->message( 'err', $lang{ERROR}, "$lang{EXIST}" );
            return 0;
          }
          elsif ($Payments->{errno}) {
            $html->message( 'err', $lang{ERROR}, "$lang{ERROR} ID: $Paysys->{TRANSACTION_ID}" );
          }
          else {
            my $status = "Added $Payments->{INSERT_ID}\n";
            $html->message( 'info', $lang{INFO}, "$lang{ADDED} $lang{SUM}: $Paysys->{SUM} ID: $INFO_HASH{ID}" );
            if ($conf{PAYSYS_EMAIL_NOTICE}) {
              my $message = "\n"
                . "System: SMS PROXY\n"
                . "$lang{DATE}: $DATE $TIME\n"
                . "$lang{LOGIN}: $user->{LOGIN} [$LIST_PARAMS{UID}]\n\n\n"
                . "ID: $Paysys->{INFO}\n" . "$lang{SUM}: $Paysys->{SUM}\n"
                . "Status: $status\n";

              sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "Paysys Webmoney Add", "$message", "$conf{MAIL_CHARSET}", "2 (High)");
            }
          }
        }
        return 0;
      }

      $html->message( 'info', $lang{INFO},
        "$lang{TRANSACTION_PROCESSING} $lang{SUM}: $list->[0][3] ID: $FORM{OPERATION_ID}" );
    }
    else {
      $html->message( 'err', $lang{ERROR}, "$lang{FAILED} $lang{NOT_EXIST}" );
    }
  }

  $html->tpl_show(_include('paysys_smsproxy_add', 'Paysys'), \%info);
}

#**********************************************************
#
#**********************************************************
sub paysys_rupay {

  my %info = ();

  if ($FORM{FALSE}) {
    paysys_show_result({ TRANSACTION_ID => "$FORM{OPERATION_ID}", FALSE => 1 });
  }
  elsif ($FORM{TRUE}) {
    paysys_show_result({ TRANSACTION_ID =>  "$FORM{OPERATION_ID}" });
    return 0;
  }

  $info{SUM_VAL_SEL} = $html->form_select(
    'sum_val',
    {
      SELECTED  => $FORM{sum_val},
      SEL_ARRAY => [ 'USD', 'EUR', 'UAH', 'RUR' ],
      NO_ID     => 1
    }
  );

  $info{OPERATION_ID} = $FORM{OPERATION_ID};
  $info{SUM}          = $FORM{SUM};
  $info{DESCRIBE}     = $FORM{DESCRIBE};

  $html->tpl_show(_include('paysys_rupay_add', 'Paysys'), \%info);
}

#**********************************************************
#
#**********************************************************
sub paysys_rbkmoney {

  my %info = ();

  if ($FORM{FALSE}) {
    paysys_show_result({ TRANSACTION_ID =>  "$FORM{OPERATION_ID}", FALSE => 1 });
  }
  elsif ($FORM{TRUE}) {
    paysys_show_result({ TRANSACTION_ID =>  "$FORM{OPERATION_ID}" });
    return 0;
  }

  $info{SUM_VAL_SEL} = $html->form_select(
    'recipientCurrency',
    {
      SELECTED  => $FORM{sum_val},
      SEL_ARRAY => [ 'USD', 'EUR', 'UAH', 'RUR' ],
      NO_ID     => 1
    }
  );

  $info{OPERATION_ID} = $FORM{OPERATION_ID};
  $info{SUM}          = $FORM{SUM};
  $info{DESCRIBE}     = $FORM{DESCRIBE};

  $html->tpl_show(_include('paysys_rbkmoney_add', 'Paysys'), \%info);
}

#**********************************************************
#
#**********************************************************
sub paysys_sberbank {

  my $div = $html->element('h3', "Вы будете перенаправлены на сервис Сбербанк-онлайн", { class => 'alert alert-info'} );
  $html->{HEADERS_SENT} = 1;
  $html->redirect('https://online.sberbank.ru/', { WAIT => 4, MESSAGE_HTML => $div });
}

#**********************************************************
#
#**********************************************************
sub paysys_autopay {

  my $SUM = $FORM{SUM} * 100;
  my $div = $html->element('h3', "Вы будете перенаправлены на сервис Центральная касса", { class => 'alert alert-info'} );
  $html->{HEADERS_SENT} = 1;
  $html->redirect("https://ckassa.ru./payment/?lite-version=true#!search_provider/pt_search/$conf{PAYSYS_AUTOPAY_PROVIDER}/pay&Л/СЧЕТ=$LIST_PARAMS{UID}&amount=$SUM&force_create=true",
    { WAIT => 4, MESSAGE_HTML => $div });
}

#**********************************************************
=head2 paysys_privatbank()

  80567161228 vadim
  vadim.ignatkin@pbank.com.ua
=cut
#**********************************************************
sub paysys_privatbank {
  my %info = ();

  my $payment_system    = 'PBANK';
  my $payment_system_id = 48;
  #my $order_id          = $FORM{orderid};

  if ($FORM{FALSE}) {
    if ($FORM{reasoncode} == 11) {
      $FORM{reasoncodedesc} = "$lang{ERR_INVALID_SIGNATURE}";
    }
    elsif ($FORM{reasoncode} == 2) {
      $FORM{reasoncodedesc} = "$lang{ERR_TRANSACTION_DECLINED}";
    }
    $html->message( 'err', $lang{ERROR},
      "$lang{FAILED} ID: $FORM{orderid} [$FORM{reasoncode}/$FORM{responsecode}] $FORM{reasoncodedesc} " );
    $html->set_cookies('lastindex', "", "Fri, 1-Jan-2038 00:00:01", $html->{web_path}) if (! $FORM{INTERACT});

    return 0;
  }
  elsif ($FORM{TRUE}) {
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{orderid}" });
    return 0;
  }
  else {
    if ($FORM{SUM} <= 0) {
      $html->message( 'info', $lang{ERROR}, "$lang{ERR_WRONG_SUM} $FORM{SUM}" );
      return 0;
    }

    #Info section
    $Paysys->add(
      {
        SYSTEM_ID      => $payment_system_id,
        SUM            => $FORM{SUM},
        UID            => $LIST_PARAMS{UID},
        IP             => "$ENV{'REMOTE_ADDR'}",
        TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
        INFO           => '-',
        PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
        STATUS         => 1
      }
    );

    if ($Paysys->{errno}) {
      my $message = '';
      if ($Paysys->{errno} == 7) {
        $message = "\n$lang{EXIST}";
      }

      $html->message( 'err', "$lang{ERROR}", "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}'" . $message );
      return 0;
    }
  }

  $html->set_cookies('lastindex', "$index", "Fri, 1-Jan-2038 00:00:01") if (! $FORM{INTERACT});
  $info{OPERATION_ID}   = $FORM{OPERATION_ID};
  $info{AMOUNT}         = sprintf("%.12d", int($FORM{SUM} * 100));
  $info{AMOUNT2}        = sprintf("%.12d", int($info{AMOUNT2}));
  $info{AdditionalData} = "index=$index&UID=$LIST_PARAMS{UID}";

  load_pmodule('Digest::SHA1');

  my $ctx = Digest::SHA1->new;
  my $sign_text = $conf{PAYSYS_PB_PW} . $conf{PAYSYS_PB_MERID} . '414963' . $info{OPERATION_ID} . $info{AMOUNT} . '980' . $FORM{DESCRIBE};

  $ctx->add($sign_text);
  $info{HASH}            = $ctx->b64digest();
  $info{SignatureMethod} = 'SHA1';
  $info{HASH}            = $info{HASH} . '=';
  $info{DESCRIBE}        = $FORM{DESCRIBE};
  $info{UID}             = $FORM{UID};

  $html->tpl_show(_include('paysys_pb_add', 'Paysys'), \%info);
}

#**********************************************************
=head2  paysys_p24_get_payments() - get privat24 payments via api

=cut
#**********************************************************
sub paysys_p24_get_payments {

  paysys_load('P24');

  my ($BINDING_FIELD, $BINDING_EXPR)=('UID', '');
  if ($conf{PAYSYS_P24_EXPR}) {
    ($BINDING_FIELD, $BINDING_EXPR) = split(/:/, $conf{PAYSYS_P24_EXPR}, 2);
  }

  if ($FORM{PAYMENTS}) {
    paysys_import_form({
      TYPE => 'PAYMENTS',
      BINDING_FIELDS => $BINDING_FIELD,
      FORM => \%FORM
    });
    return 1;
  }

  my $users = Users->new($db, $admin, \%conf);

  my $total_in      = 0;
  my $total_out     = 0;
  my $total_sum_in  = 0;
  my $total_sum_out = 0;
  my %info          = ();
  #  my $merchant_id   = '';
  #  my $merchant_pass = '';

  #Get merchants
  my $merchant_sel = '';
  my @merchant_arr = ($conf{'PAYSYS_P24_MERCHANT_ID'});
  my $group_list   = $users->groups_list({ COLS_NAME => 1 });

  my $cur_merchant = '';
  my $cur_pass     = '';

  my @all_rows     = ();
  my @all_rows_color = ();

  foreach my $line (@$group_list) {
    if ( $conf{ 'PAYSYS_P24_MERCHANT_ID_' . $line->{gid} } ) {
      if ( ! in_array($conf{ 'PAYSYS_P24_MERCHANT_ID_' . $line->{gid} }, \@merchant_arr) ) {
        push @merchant_arr, $conf{ 'PAYSYS_P24_MERCHANT_ID_' . $line->{gid} };
      }

      if ($FORM{MERCHANT_ID} && $FORM{MERCHANT_ID} eq $conf{ 'PAYSYS_P24_MERCHANT_ID_' . $line->{gid} }) {
        $cur_merchant = $conf{ 'PAYSYS_P24_MERCHANT_ID_' . $line->{gid} };
        $cur_pass     = $conf{ 'PAYSYS_P24_MERCHANT_PASS_' . $line->{gid} };
        $conf{PAYSYS_P24_CARDNUM} = $conf{ 'PAYSYS_P24_CARDNUM_' . $line->{gid} } if ($conf{ 'PAYSYS_P24_CARDNUM_' . $line->{gid} }) ;
      }
    }
  }

  if ($#merchant_arr > -1) {
    $merchant_sel = "<label class='control-label'>Merchant:</label>" . $html->form_select('MERCHANT_ID',
      {
        SELECTED     => $FORM{MERCHANT_ID},
        SEL_ARRAY    => \@merchant_arr,
      });

    if($FORM{MERCHANT_ID}) {
      $pages_qs .= "&MERCHANT_ID=$FORM{MERCHANT_ID}";
    }
  }

  my $cards = '';
  my @my_cards_arr = ();

  if ($conf{PAYSYS_P24_CARDNUM}) {
    $conf{PAYSYS_P24_CARDNUM} =~ s/[\r\n ]+//;
    @my_cards_arr = split(/,/, $conf{PAYSYS_P24_CARDNUM});

    $cards = "Cards: ". $html->form_select(
      'CARD_ID',
      {
        SELECTED   => $FORM{CARD_ID},
        SEL_ARRAY  => \@my_cards_arr,
      }
    );
  }

  #exchange rate sel
  my $er_list   = $Payments->exchange_list({%FORM, COLS_NAME => 1 });
  my %ER_ISO2ID = ();
  my $er_sum    = 0;
  foreach my $line (@$er_list) {
    $ER_ISO2ID{ $line->{iso} } = $line->{id};
    if($FORM{ER} && $FORM{ER} == $line->{id}) {
      $er_sum = $line->{rate};
    }
  }

  if (!$FORM{ER} && $FORM{ISO}) {
    $FORM{ER} = $ER_ISO2ID{ $FORM{ISO} };
    $FORM{ER_ID} = $ER_ISO2ID{ $FORM{ISO} };
  }

  my $exchange_rate = '';
  if ($Payments->{TOTAL} > 0) {
    $exchange_rate = " $lang{CURRENCY} : $lang{EXCHANGE_RATE}: " . $html->form_select(
      'ER',
      {
        SELECTED      => $FORM{ER} || '',
        SEL_LIST      => $er_list,
        SEL_KEY       => 'id',
        SEL_VALUE     => 'money,short_name,',
        NO_ID         => 1,
        MAIN_MENU     => get_function_index('form_exchange_rate'),
        MAIN_MENU_ARGV=> "chg=". ($FORM{ER} || ''),
        SEL_OPTIONS   => { '' => '' }
      }
    );
  }

  my @rows = ();
  push @rows, "<label class='control-label'>$lang{FROM}:</label> " . $html->date_fld2( 'DATE_FROM', { MONTHES => \@MONTHES, WEEK_DAYS => \@WEEKDAYS } ),
    "<label class='control-label'>$lang{TO}:</label> " . $html->date_fld2( 'DATE_TO', { MONTHES => \@MONTHES, WEEK_DAYS => \@WEEKDAYS } ),
    "<label class='control-label'>$lang{COMMENTS}:</label> " . $html->form_input( 'COMMENTS', ($FORM{COMMENTS} || ''), { size => 30 } ),
    "<label class='control-label'>$lang{SUM}:</label> " . $html->form_input( 'SUM', ($FORM{SUM} || ''), { size => 5 } ),
    $cards,
    $merchant_sel,
    $html->form_input( 'show', $lang{SHOW}, { TYPE => 'submit', OUTPUT2RETURN => 1 } );

  foreach my $val ( @rows ) {
    $info{ROWS} .= $val;
  }

  my $report_form =  $html->element('div', $info{ROWS}, {
      class => 'well well-sm form-inline'
    });

  my $info = p24({ HISTORY       => 1,
    DATE          => $DATE,
    %FORM,
    MERCHANT_ID   => $cur_merchant,
    MERCHANT_PASS => $cur_pass,
  });

  my @title = ("$lang{USER} ($BINDING_FIELD)", $lang{REST}, $lang{COMMENTS}, $lang{DATE}, $lang{SUM}, 'card',
    'cardamount', 'terminal' );
  if($FORM{ER}) {
    push @title, $lang{CURRENCY};
  }

  if ($info->{data} && $info->{data}->{error}) {
    $html->message( 'err', $lang{ERROR}, "$info->{data}->{error}->[0]->{message}" );
    return 0;
  }

  my %BINDING_IDS    = ();
  my %added_payments = ();

  #Get payments
  my $payments_extid_list = 'P24:*';
  my $payments_list = $Payments->list({ EXT_ID    => $payments_extid_list,
    DATETIME  => '_SHOW',
    PAGE_ROWS => 100000,
    COLS_NAME => 1,
  });

  foreach my $line (@$payments_list) {
    if ($line->{ext_id}) {
      $line->{ext_id} =~ s/P24://;
      $added_payments{ $line->{ext_id} } = "$line->{id}:". ($line->{login} || '') .":$line->{datetime}";
    }
  }

  my $sum_params = $FORM{SUM} || '';
  $sum_params =~ s/[<>]//;

  if ($conf{PAYSYS_P24_MERCHANT_YUR}) {
    my %payments_ids = ();
    my %cant_analize = ();

    if ($conf{PAYSYS_P24_EXPR}) {
      while (my ($k, $v) = each %{ $info->{data}->{info}->[0]->{vitiazsybr}->[0]->{row} }) {
        $payments_ids{$k} = 1;
        next if (in_array($v->{col}->{BPL_A_ACC}->{content}, \@my_cards_arr));
        my $describe = $v->{col}->{BPL_OSND}->{content};
        my $ID = $k;
        $ID =~ s/ //g;

        if ($describe =~ /$BINDING_EXPR/g) {
          $BINDING_IDS{$ID} = $1;
        }
        else {
          $cant_analize{$ID} = 1;
        }
      }
    }

    my $binding_info = get_binding_ids($BINDING_FIELD, \%BINDING_IDS);

    while (my ($k, $v) = each %{ $info->{data}->{info}->[0]->{vitiazsybr}->[0]->{row} }) {
      my $ID = $k;
      $ID =~ s/ //g;
      my ($LOGIN, $FIO, $SEARCH_FIELD, $uid);
      if ($BINDING_IDS{$ID} && $binding_info->{ $BINDING_IDS{$ID} }) {
        ($LOGIN, $FIO, $uid, $SEARCH_FIELD) = split(/:/, $binding_info->{ $BINDING_IDS{$ID} });
      }

      # FIXME: if works - remove
      #$v->{col}->{BPL_NUM_DOC}->{content} = _utf8_encode($v->{col}->{BPL_NUM_DOC}->{content});

      my $description = _utf8_encode($v->{col}->{BPL_OSND}->{content});
      my $sum         = $v->{col}->{BPL_SUM}->{content};
      my $date        = $v->{col}->{BPL_DAT_OD}->{content};
      if ($date =~ /(\d+)\.(\d+)\.(\d+)/) {
        $date = "$3-$2-$1";
      }

      if ($FORM{SUM}) {
        if ($FORM{SUM}=~/</ && $sum < $sum_params) {
        }
        elsif ($FORM{SUM}=~/>/ && $sum > $sum_params) {
        }
        elsif ($sum == $FORM{SUM}) {
        }
        else {
          next;
        }
      }
      elsif ($FORM{COMMENTS} && $description !~ /$FORM{COMMENTS}/) {
        next;
      }

      my $table_id_col    = '';
      my $table_login_col = '';

      if ($added_payments{$ID}) {
        my ($id, $login, $pay_date) = split(/:/, $added_payments{$ID}, 3);
        $table_id_col = $html->button( $lang{ADDED}, "index=2&ID=$added_payments{$ID}" ) . $html->br() .
          $html->b($login) .
          $html->br() .
          $pay_date .
          $html->br() .
          $ID;
        $table_login_col = '';
      }
      else {
        $table_id_col = (in_array($v->{col}->{BPL_B_ACC}->{content}, \@my_cards_arr) && $description ne 'Account Rechards') ? $html->form_input('IDS', "$ID", { TYPE => 'checkbox' }) . $ID : '';

        $table_login_col =
          (($uid) ? $html->button($LOGIN, "index=15&UID=$uid") . $html->br() . $FIO . $html->br() . $html->form_input('CONTRACT_ID_' . $ID, "$BINDING_IDS{$ID}")
                  : (   (in_array($v->{col}->{BPL_B_ACC}->{content}, \@my_cards_arr) || $#my_cards_arr == -1 )
                && $description ne 'Account Rechards') ? $html->form_input($BINDING_FIELD . '_' . $ID, $FORM{ $BINDING_FIELD . '_' . $ID })
                                                       : '')
            . $html->form_input('UID_' . $ID,      $uid,         { TYPE => 'hidden' })
            . $html->form_input('SUM_' . $ID,      "$sum",         { TYPE => 'hidden' })
            . $html->form_input('DATE_' . $ID,     "$date",        { TYPE => 'hidden' })
            . $html->form_input('DESCRIBE_' . $ID, "$description", { TYPE => 'hidden' })
            . $html->form_input('EXT_ID_' . $ID,   "P24:$ID",      { TYPE => 'hidden' });
      }

      #added by liqpay
      if ($v->{col}->{BPL_NUM_DOC}->{content}=~m/\@/) {
        push @all_rows_color, 'success';
      }
      elsif ($cant_analize{$ID}) {
        push @all_rows_color, 'danger';
      }
      elsif(! in_array($v->{col}->{BPL_B_ACC}->{content}, \@my_cards_arr)) {
        push @all_rows_color, 'warning';
      }
      else {
        push @all_rows_color, '';
      }

      if ($description =~ /# (\d+) /) {
        my $ext_id = $1;
        my $payment_button = $html->button($ext_id, "index=2&EXT_ID=P24:$ext_id&search=1");
        $description =~ s/$ext_id/$payment_button/;
      }

      my @rows2 = (
        $table_id_col . (($cant_analize{$ID}) ? $html->element('span', '', { class => 'glyphicon glyphicon-alert' }) : ''),
        $table_login_col,
        '',
        $description,
        $date,
        $sum,
          (in_array($v->{col}->{BPL_B_ACC}->{content}, , \@my_cards_arr)) ? $html->b($v->{col}->{BPL_A_ACC}->{content}) : "$v->{col}->{BPL_A_ACC}->{content} -> $v->{col}->{BPL_B_ACC}->{content}",
        '',
        _utf8_encode($v->{col}->{BPL_NUM_DOC}->{content})
      );

      if($FORM{ER}) {
        push @rows2, sprintf("%.2f", $sum / $er_sum);
      }

      push @all_rows, \@rows2;
      if (in_array($v->{col}->{BPL_B_ACC}->{content}, \@my_cards_arr)) {
        $total_in++;
        $total_sum_in += $sum;
      }
      elsif (! in_array($v->{col}->{BPL_B_ACC}->{content}, \@my_cards_arr)) {
        $total_out++;
        $total_sum_out += $sum;
      }
    }
  }
  # Fisical  ----------------------------------------------------------------------------
  else {
    if ($conf{PAYSYS_P24_EXPR}) {
      foreach my $line (@{ $info->{data}->{info}->[0]->{statements}->[0]->{statement} }) {
        my $describe = _utf8_encode($line->{'description'});
        if ($describe =~ /$BINDING_EXPR/g) {
          $BINDING_IDS{ $line->{'appcode'} } = $1 || q{};
        }
      }
    }

    my $binding_info = get_binding_ids($BINDING_FIELD, \%BINDING_IDS);
    if($info->{data}->{info}->[0] && $info->{data}->{info}->[0] ne 'error:null') {
      foreach my $line (@{ $info->{data}->{info}->[0]->{statements}->[0]->{statement} }) {
        my $description = _utf8_encode($line->{'description'} || $line->{'terminal'});
        #$line->{'terminal'}   = _utf8_encode($line->{'termainal'});

        my $ID = $line->{'appcode'};
        my $binding_key = $BINDING_IDS{ $ID } || $FORM{ $BINDING_FIELD . '_' . $ID } || '';

        my ($LOGIN, $FIO, $uid) = split(/:/, $binding_info->{ $binding_key } || '');

        my $date = $line->{'trandate'};
        my ($sum, $currency) = split(/ /, $line->{'cardamount'});

        $currency = _utf8_encode($currency);

        if ($FORM{SUM}) {
          if ($FORM{SUM} =~ /</ && $sum < $sum_params) {
          }
          elsif ($FORM{SUM} =~ />/ && $sum > $sum_params) {
          }
          elsif ($sum == $FORM{SUM}) {
          }
          else {
            next;
          }
        }
        elsif ($FORM{COMMENTS} && $description !~ /$FORM{COMMENTS}/) {
          next;
        }

        my $client = '';
        my $table_id_col = '';

        if ($sum < 0) {
          push @all_rows_color, $_COLORS[0];
          $total_out++;
          $total_sum_out += $sum;
        }
        else {
          push @all_rows_color, '';
          #print %{ $added_payments };
          if ($added_payments{$ID}) {
            my ($id, $login, $pay_date) = split(/:/, $added_payments{$ID}, 3);
            $client = $html->button("$lang{ADDED}",
              "index=2&ID=$id") . $html->br() . $html->b($login) . $html->br() . $pay_date;
          }
          else {
            $client = '';

            if ($binding_info->{ $binding_key }) {
              $client = $html->button($LOGIN, "index=15&UID=" . ($uid || ''))
                . $html->br()
                #. ($BIND || '')
                . ' / ' . $FIO
                #. $html->form_input('UID_' . $ID, ($uid || ''), { TYPE => 'input' })
                . $html->form_input($BINDING_FIELD . '_' . $ID, $FORM{ $BINDING_FIELD . '_' . $ID })
              ;
            }
            elsif ($FORM{ $BINDING_FIELD . '_' . $ID } && $binding_info->{ $FORM{ $BINDING_FIELD . '_' . $ID } }) {
              $client = $html->form_input($BINDING_FIELD . '_' . $ID, $FORM{ $BINDING_FIELD . '_' . $ID })
                . $html->button($LOGIN, "index=15&UID=$uid") . $html->br() . $BINDING_IDS{$ID} . ' / ' . $FIO;
            }
            else {
              $client = $html->form_input($BINDING_FIELD . '_' . $ID, $FORM{ $BINDING_FIELD . '_' . $ID });
            }

            $client .= (($BINDING_FIELD ne 'UID') ? $html->form_input('UID_' . $ID, ($uid || ''),
                { TYPE => 'hidden' })             : '')
              . $html->form_input('EXT_ID_' . $ID, "P24:$ID", { TYPE => 'hidden' })
              . $html->form_input('SUM_' . $ID, "$sum", { TYPE => 'hidden' })
              . $html->form_input('CURRENCY_' . $ID, "$currency", { TYPE => 'hidden' })
              . $html->form_input('DATE_' . $ID, "$date", { TYPE => 'hidden' })
              . $html->form_input('DESCRIBE_' . $ID, $description, { TYPE => 'hidden' });

            if (($#my_cards_arr == - 1 || in_array($line->{col}->{BPL_B_ACC}->{content}, \@my_cards_arr))
              && $description ne 'Account Rechards') {
              $table_id_col = $html->form_input('IDS', "$ID", { TYPE => 'checkbox', STATE =>
                    (in_array($ID, [ split(/, /, ($FORM{IDS} || '')) ])) ? 'checked' : undef });
            }
          }

          $total_sum_in += $sum;
          $total_in++;
        }

        my @rows2 = (
          $table_id_col . $ID,
          $client,
          $line->{'rest'},
          $description,
          $date,
          "$sum $currency",
          $line->{'card'},
          $line->{'cardamount'},
          #$line->{'terminal'}
        );

        if ($FORM{ER}) {
          push @rows2, sprintf("%.2f", $sum / $er_sum);
        }

        push @all_rows, \@rows2;

        if (in_array($line->{'card'}, \@my_cards_arr)) {
          if ($sum > 0) {
            $total_in++;
            $total_sum_in += $sum;
          }
          else {
            $total_out++;
            $total_sum_out += $sum;
          }
        }
      }
    }
    #while (my ($k, $v) = each %{ @{ $info->{data}->{info} }[0]->{cardbalance}->[0] }) {
    #  $table->addrow($k, $v->[0]) if ($k ne 'card');
    #}
  }

  #  foreach my $line (@all_rows) {
  #    print '<br>';
  #    foreach my $zz (@$line) {
  #      print "$zz //
  #     ";
  #    }
  #  }

  my ($table) = result_former(
    {
      DEFAULT_FIELDS => '#,'.join(',', @title),
      TABLE          => {
        width   => '100%',
        caption =>
        "$lang{LOG} " . (($conf{PAYSYS_P24_MERCHANT_YUR}) ? 'yur' : '' ) . ' ' . (($cur_merchant) ? $cur_merchant : $conf{PAYSYS_P24_MERCHANT_ID})
        ,
        EXPORT  => 1,
        qs      => $pages_qs,
        MENU    => "$lang{INFO}:index=$index&CARD_ID=" . ($FORM{CARD_ID} || '') . "&info_card=1:info;",
        #SHOW_COLS        => \%info_oids,
        ID      => 'PAYSY_P24_LIST',
      },
    }
  );

  my $payment_list = result_row_former(
    {
      table      => $table,
      ROWS       => \@all_rows,
      ROW_COLORS => \@all_rows_color
    }
  );

  @rows = ();
  push @rows,
    $lang{PAYMENTS}
      . ' '. $html->form_input( 'PAYMENTS', 1, { TYPE => 'checkbox' } )
      . ' '. $exchange_rate
      . ' '. $html->form_input( 'IMPORT', $lang{IMPORT},
      { TYPE => 'submit', FORM_NAME => 'FORM_IMPORT', OUTPUT2RETURN => 1 } );

  $info{ROWS} = '';

  foreach my $val ( @rows ) {
    $info{ROWS} .= $html->element('div', $val, { class => 'form-group' });
  }

  my $report_form2= $html->element('div', $info{ROWS}, {
      class => 'well well-sm form-inline'
    });

  print $html->form_main(
    {
      CONTENT => $report_form
        . $payment_list
        . $report_form2
      ,
      HIDDEN  => { index  => $index },
      NAME    => 'FORM_IMPORT',
      ID      => 'FORM_IMPORT'
    }
  );

  $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{TOTAL},
      rows       =>
      [ [ "$lang{PAYMENTS}:", $html->b( $total_in ), "$lang{SUM}", $html->b( sprintf( "%.2f", $total_sum_in ) ) ],
        [ "$lang{FEES}:", $html->b( $total_out ), "$lang{SUM}", $html->b( sprintf( "%.2f", $total_sum_out ) ) ] ]
    }
  );
  if(!$admin->{MAX_ROWS}){
    print $table->show();
  }
  #print $table->show();

  return 1;
}

#**********************************************************
=head2 get_binding_ids($BINDING_FIELD, $BINDING_IDS) - Get binding values

  Arguments:
    $BINDING_FIELD
    $BINDING_IDS

=cut
#**********************************************************
sub get_binding_ids {
  my($BINDING_FIELD, $BINDING_IDS)=@_;

  my %binding_assigns = ();
  if(ref $BINDING_IDS ne 'HASH') {
    return \%binding_assigns;
  }

  if($BINDING_IDS && ref $BINDING_IDS  eq 'HASH') {
    my $ids = join(',', values %$BINDING_IDS);
    my $list = $users->list(
      {
        FIO            => '_SHOW',
        $BINDING_FIELD => $ids,
        PAGE_ROWS      => 1000000,
        $BINDING_FIELD => '_SHOW',
        COLS_NAME      => 1
      }
    );

    foreach my $line (@$list) {
      $binding_assigns{ $line->{lc($BINDING_FIELD)} } = $line->{login}.':'.($line->{fio} || '').':'.$line->{uid};
    }
  }

  return \%binding_assigns;
}

#**********************************************************
=head2 paysys_p24($attr)

=cut
#**********************************************************
sub paysys_p24 {
  #my ($attr) = @_;

  paysys_load('P24');

  if ($FORM{info_card}) {
    my $info = p24({ CARD_INFO => $FORM{CARD_ID} || $conf{'PAYSYS_P24_CARDNUM'} });

    if ($info->{data}->{error}) {
      $html->message( 'err', $lang{ERROR}, "$info->{data}->{error}->[0]->{message}" );
    }

    my $table = $html->table(
      {
        caption => 'CARD_INFO',
        width   => '100%',
        ID      => 'CARD_INFO'
      }
    );

    while (my ($k, $v) = each %{ $info->{data}->{info}->[0]->{cardbalance}->[0]->{card}->[0] }) {
      $table->addrow($k, $v->[0]);
      $table->{caption} = 'CARD: ' . $v->[0] if ($k eq 'account');
    }

    while (my ($k, $v) = each %{ @{ $info->{data}->{info} }[0]->{cardbalance}->[0] }) {
      $table->addrow($k, $v->[0]) if ($k ne 'card');
    }

    print $table->show();
  }
  else {
    paysys_p24_get_payments();
  }

  return 0 if ($conf{PAYSYS_P24_MERCHANT_YUR});

  return 1;
}

#**********************************************************
=head2 paysys_start_page($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub paysys_start_page {
  #my ($attr) = @_;

  my %START_PAGE_F = (
    'paysys_nbu_exchange_rates' => "$lang{EXCHANGE_RATE} ". ($lang{NBU} || q{}),
    'paysys_p24_exchange_rates' => "$lang{EXCHANGE_RATE} Privat",
    'paysys_nbkr_exchange_rates'=> "$lang{EXCHANGE_RATE} $lang{NBKR}");

  return \%START_PAGE_F;
}

#**********************************************************
=head2 paysys_p24_exchange_rates($attr) - get exchange rates from p24

=cut
#**********************************************************
sub paysys_p24_exchange_rates {
  #my ($attr) = @_;

  my $private_data = web_request(
    "https://api.privatbank.ua/p24api/pubinfo?json&exchange&coursid=11",
    {
      CURL        => 1,
      POST        => 1,
      JSON_RETURN => 1
    }
  );

  my $private_table = $html->table(
    {
      width   => '100%',
      caption => "Privat $lang{EXCHANGE_RATE}",
      title   => [ $lang{CURRENCY}, $lang{CURRENCY_BUY}, $lang{CURRENCY_SALE} ],
      ID      => 'P24_CURRENCY',
      # EXPORT  => 1
    }
  );

  if(ref $private_data eq 'ARRAY'){
    foreach my $pinfo (@$private_data) {
      $private_table->addrow( $html->b("$pinfo->{ccy} / $pinfo->{base_ccy}"),
        sprintf('%.4f', $pinfo->{buy}),
        sprintf('%.4f', $pinfo->{sale}));
    }
  }

  return $private_table->show();
}


#**********************************************************
=head2 paysys_p24_ex_rates_print($attr) - pring table for p24 exchange rates

  Arguments:


  Returns:

=cut
#**********************************************************
sub paysys_p24_ex_rates_print {

  print paysys_p24_exchange_rates();

  return 1;
}
#**********************************************************
=head2 paysys_nbu_exchange_rates($attr) - get exchange rates from nbu

  Arguments:


  Returns:
    $table

=cut
#**********************************************************
sub paysys_nbu_exchange_rates {

  my $nbu_data = web_request(
    "https://api.privatbank.ua/p24api/pubinfo?json&exchange&coursid=3",
    {
      CURL        => 1,
      POST        => 1,
      JSON_RETURN => 1
    }
  );

  my $nbu_table = $html->table(
    {
      width   => '100%',
      caption => "НБУ $lang{EXCHANGE_RATE}",
      title   => [ $lang{CURRENCY}, $lang{CURRENCY_BUY}, $lang{CURRENCY_SALE} ],
      ID      => 'NBU_CURRENCY',
      #EXPORT  => 1
    }
  );

  if(ref $nbu_data eq 'ARRAY'){
    foreach my $nbuinfo (@$nbu_data) {
      $nbu_table->addrow("<b>$nbuinfo->{ccy} / $nbuinfo->{base_ccy}</b>",
        sprintf('%.4f', $nbuinfo->{buy}),
        sprintf('%.4f', $nbuinfo->{sale}));
    }
  }

  return $nbu_table->show();
}

#**********************************************************
=head2 paysys_nbu_ex_rates_print($attr) - print table for nbu exchange rates

  Arguments:


  Returns:

=cut
#**********************************************************
sub paysys_nbu_ex_rates_print {

  print paysys_nbu_exchange_rates;

  return 1;
}


#**********************************************************
=head2 paysys_nbu_exchange_rates($attr) - get exchange rates from nbu

  Arguments:


  Returns:
    $table

=cut
#**********************************************************
sub paysys_nbkr_exchange_rates {

  my $nbkr_xml_data = web_request(
    "http://www.nbkr.kg/XML/daily.xml",
    {
      CURL        => 1,
    }
  );

  load_pmodule('XML::Simple');

  my $nbkr_data = eval { XML::Simple::XMLin("$nbkr_xml_data", forcearray => 1) };

  if ($@) {
    return 0;
  }

  my $exchange_rate_date = $nbkr_data->{Date};

  my $nkbr_table = $html->table(
    {
      width   => '100%',
      caption => "$lang{NBKR} $lang{EXCHANGE_RATE}",
      title   => [ $lang{CURRENCY}, "$exchange_rate_date" ],
      ID      => 'NBKR_CURRENCY',
      #EXPORT  => 1
    }
  );

  foreach my $currency (@ {$nbkr_data->{Currency} }){
    $nkbr_table->addrow("$currency->{ISOCode}/KGS", $html->b($currency->{Value}->[0]));
  }

  return $nkbr_table->show();
}

#**********************************************************
=head2 paysys_nbu_ex_rates_print($attr) - print table for nbu exchange rates

  Arguments:


  Returns:

=cut
#**********************************************************
sub paysys_nbkr_ex_rates_print {

  print paysys_nbkr_exchange_rates;

  return 1;
}

#**********************************************************
=head2 paysys_privatbank_p24($attr) User portal payments system with privat 24

=cut
#**********************************************************
sub paysys_privatbank_p24 {
  my ($attr) = @_;

  my $payment_system    = $attr->{SYSTEM_SHORT_NAME} || 'P24';
  my $payment_system_id = $attr->{SYSTEM_ID}         || 54;
  $FORM{SYSTEM_SHORT_NAME}=$payment_system;
  my %info = ();

  if ($FORM{TRUE}) {
    paysys_show_result({ %$attr, TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}" });
    return 1;
  }
  elsif ($FORM{OrderID}) {
    paysys_show_result({ TRANSACTION_ID =>  "$payment_system:$FORM{OrderID}" });
    return 0;
  }
  else {
    if ($FORM{SUM} <= 0) {
      $html->message( 'info', $lang{ERROR}, "$lang{ERR_WRONG_SUM} $FORM{SUM}" );
      return 0;
    }

    if ($conf{PAYSYS_GROUP_SPLIT_ACCOUNTS}) {
      if ($conf{'PAYSYS_P24_COMMISSION_'. $user->{GID}}) {
        $conf{PAYSYS_P24_COMMISSION}=$conf{'PAYSYS_P24_COMMISSION_'. $user->{GID}};
      }
    }

    if ($conf{PAYSYS_P24_COMMISSION}) {
      $conf{PAYSYS_P24_COMMISSION} =~ /([0-9\.]+)([\%]?)/;
      $info{COMMISSION} = $1;
      my $type = $2;

      if ($type) {
        $info{COMMISSION_SUM} = sprintf("%.2f", $FORM{SUM} / 100 * $info{COMMISSION});
      }
      else {
        $info{COMMISSION_SUM} = sprintf("%.2f", $info{COMMISSION});
      }
    }

    #Info section
    $Paysys->add(
      {
        SYSTEM_ID      => $payment_system_id,
        DATETIME       => "$DATE $TIME",
        SUM            => $FORM{SUM},
        COMMISSION     => $info{COMMISSION_SUM},
        UID            => $LIST_PARAMS{UID},
        IP             => $ENV{'REMOTE_ADDR'},
        TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
        INFO           => ($ENV{REQUEST_URI} =~ /start.cgi/) ? "start.cgi\nTP_ID,$FORM{TP_ID}" : $SELF_URL,
        PAYSYS_IP      => $ENV{'REMOTE_ADDR'},
        #USER_INFO      => ($ENV{REQUEST_URI} =~ /start.cgi/) ? 'start.cgi' : '',
        STATUS         => 1
      }
    );

    if ($Paysys->{errno}) {
      my $message = '';
      if ($Paysys->{errno} == 7) {
        $message = "\n$lang{EXIST}";
      }

      $html->message( 'err', "$lang{ERROR}", "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}' " . $message );
      return 0;
    }

  }

  $FORM{TOTAL_SUM} = sprintf("%.2f", $FORM{SUM} + ($info{COMMISSION_SUM} || 0));
  $conf{PAYSYS_P24_MERCHANT_CURRENCY}='USD' if(! $conf{PAYSYS_P24_MERCHANT_CURRENCY});
  $info{UID} = $FORM{UID};

  # check if not user GID
  if(!$user->{GID}){
    use Users;
    my $User_obj = Users->new($db, $admin, \%conf);
    my $user_info = $User_obj->info($info{UID}, {GID => '_SHOW', COLS_NAME => 1});
    # if everything ok - add gid to %info
    if(!$User_obj->{errno}){
      $info{GID} = $user_info->{GID};
    }
  }

  conf_gid_split({ GID    => $user->{GID} || $info{GID},
    PARAMS => [
      'PAYSYS_P24_COMMISSION',
      'PAYSYS_P24_MERCHANT_ID',
      'PAYSYS_P24_MERCHANT_PASS',
    ]
  });

  $html->set_cookies('lastindex', "$index", "Fri, 1-Jan-2038 00:00:01") if (! $FORM{INTERACT});
  $info{RETURN_URL} = $attr->{RETURN_URL} || $ENV{PROT}.'://'. $ENV{SERVER_NAME}.':'. $ENV{SERVER_PORT} . '/paysys_check.cgi';
  #"OPERATION_ID=$FORM{OPERATION_ID}&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}";

  return $html->tpl_show(_include('paysys_privatbank_p24_add', 'Paysys'), { %info, %$user }, $attr);
}

#**********************************************************
=head2 paysys_liqpay($attr) - User portal payments system with LiqPAY

=cut
#**********************************************************
sub paysys_liqpay {
  my ($attr) = @_;

  paysys_load('Liqpay');

  my %info = ();

  if ($FORM{TRUE} || $FORM{status}) {
    paysys_show_result({ TRANSACTION_ID => $FORM{order_id} || $FORM{OPERATION_ID} });
    return 0;
  }
  else {
    $info{COMMISSION_SUM} = 0;
    if ($FORM{SUM} <= 0) {
      $html->message( 'info', $lang{ERROR}, "$lang{ERR_WRONG_SUM} $FORM{SUM}" );
      return 0;
    }

    if ($conf{PAYSYS_LIQPAY_COMMISSION}) {
      $conf{PAYSYS_LIQPAY_COMMISSION} =~ /([0-9\.]+)([\%]?)/;
      $info{COMMISSION} = $1;
      my $type = $2;

      if ($type) {
        $info{COMMISSION_SUM} = sprintf("%.2f", ($FORM{SUM} + ($FORM{SUM} / 100 * $info{COMMISSION})) / 100 * $info{COMMISSION});
        $info{COMMISSION_SUM} = int($info{COMMISSION_SUM} * 100);
        $info{COMMISSION_SUM} = ($info{COMMISSION_SUM} + 1) / 100;
      }
      else {
        $info{COMMISSION_SUM} = sprintf("%.2f", $info{COMMISSION});
      }
    }

    #Info section
    $Paysys->add(
      {
        SYSTEM_ID      => 62,
        SUM            => $FORM{SUM},
        COMMISSION     => $info{COMMISSION_SUM},
        UID            => $LIST_PARAMS{UID},
        IP             => $ENV{'REMOTE_ADDR'},
        TRANSACTION_ID => "Liqpay:$FORM{OPERATION_ID}",
        INFO           => $FORM{DESCRIBE},
        PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
        STATUS         => 1,
        DOMAIN_ID      => $user->{DOMAIN_ID},
      }
    );

    if ($Paysys->{errno}) {
      $html->message( 'err', "$lang{ERROR}", "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}'" );
      return 0;
    }
  }

  $FORM{TOTAL_SUM} = sprintf("%.2f", $FORM{SUM} + $info{COMMISSION_SUM});
  my %methods = (
    'card'   => "Visa/Master Card",
    'liqpay' => "LiqPAY"
  );

  $info{PAY_WAY_SEL} = $html->form_select(
    'METHOD',
    {
      SELECTED => $FORM{METHOD},
      SEL_HASH => \%methods,
      NO_ID    => 1
    }
  );

  $html->set_cookies('lastindex', "$index", "Fri, 1-Jan-2038 00:00:01") if (! $FORM{INTERACT});
  if (! $user->{FIO}) {
    if((!$user || !$user->{UID}) && $users){
      $user = $users;
    }
    $user->pi({ UID => $LIST_PARAMS{UID} || $user->{UID} });
  }

  if($conf{PAYSYS_LIQPAY_DESCRIPTION}){
    my @vars = $conf{PAYSYS_LIQPAY_DESCRIPTION} =~ /\%(.+?)\%/g;
    foreach my $var (@vars){
      $conf{PAYSYS_LIQPAY_DESCRIPTION} =~ s/\%$var\%/($user->{$var} || '')/ge;
    }
  }

  my $description = $conf{PAYSYS_LIQPAY_DESCRIPTION} || "\n$lang{FIO} : " . ($user->{FIO} || $attr->{FIO} || '') . ";\n Лицевой счет: " . ($user->{UID} || $attr->{UID}) . ";\n";
  use Encode qw(decode);
  $description = decode('UTF-8', $description);

  if ($conf{PAYSYS_LIQPAY_V2}) {
    ($info{SIGN}, $info{BODY}) =  liqpay_make_request2({ DOMAIN_ID => $user->{DOMAIN_ID},
      GID       => $user->{GID},
      %FORM });
  }
  else {
    ($info{SIGN}, $info{BODY}) =  liqpay_make_request3({ DOMAIN_ID => $user->{DOMAIN_ID},
      GID       => $user->{GID},
      DESCRIPTION => $description,
      %FORM });
  }

  return $html->tpl_show(_include('paysys_liqpay_add', 'Paysys'), { %{ ($attr) ? $attr : {}}, %info, %$user, TOTAL_SUM => $FORM{TOTAL_SUM} });
}

#**********************************************************
# Payment system: Liberty Reserver
# https://www.libertyreserve.com
#
#  $conf{PAYSYS_LR_ACCOUNT_NUMBER} = "U4035898"; # Enter your account
#  $conf{PAYSYS_LR_STORE_NAME} = ""; # Enter the name of your store
#  $conf{PAYSYS_LR_SECURITY_WORD} = ""; # Your store's security word
#  $conf{PAYSYS_LR_EMAIL} = ""; # Your e-mail
#
#**********************************************************
sub paysys_lr {
  #my ($attr) = @_;

  if ($FORM{FALSE}) {
    paysys_show_result({ TRANSACTION_ID => "LR:$FORM{OPERATION_ID}", FALSE => 1 });
    return 0;
  }
  elsif ($FORM{TRUE}) {
    paysys_show_result({ TRANSACTION_ID => "LR:$FORM{OPERATION_ID}" });
    return 0;
  }

  my %info = ();
  $html->set_cookies('lastindex', "$index", "Fri, 1-Jan-2038 00:00:01")  if (! $FORM{INTERACT});
  $conf{PAYSYS_LMI_RESULT_URL} = "http://$ENV{SERVER_NAME}" . (($ENV{SERVER_PORT} != 80) ? ":$ENV{SERVER_PORT}" : '') . "/paysys_check.cgi" if (!$conf{PAYSYS_LMI_RESULT_URL});
  $html->tpl_show(_include('paysys_lr_add', 'Paysys'), \%info);
}

#**********************************************************
=head2 paysys_qiwi($attr) Paysys OSMP QIWI

=cut
#**********************************************************
sub paysys_qiwi {
  my ($attr) = @_;

  my %info = ();

  paysys_load('Qiwi');

  #my $payment_system    = 'QIWI';
  my $payment_system_id = 59;

  if ($FORM{send_invoice}) {
    $FORM{COMMENT} = $user->{LOGIN};

    if($FORM{PHONE} !~ /^(\d{10})$/) {
      _error_show({ errno => 21, errstr => 'ERR_WRONG_PHONE' });
    }
    else {
      my $result = qiwi_invoice_request(\%FORM);

      if ($result->{'result-code'}->[0]->{fatal} eq 'true') {
        my $error = "$result->{'result-code'}->[0]->{content}";
        if ($result->{'result-code'}->[0]->{content} == 150) {
          $error .= " $lang{ERR_TERMINAL}";
        }
        elsif ($result->{'result-code'}->[0]->{content} == 298) {
          $error .= " $lang{REGISTER_IN} QIWI-wallet";
        }
        $html->message( 'err', "$lang{ERROR}", "$lang{ERROR}: $error" );
      }
      else {
        $html->message( 'info', "$lang{INFO}",
          "$lang{INVOICE_SENDED} ID: '$FORM{OPERATION_ID}'\n$lang{PHONE}: $FORM{PHONE}" );
        $Paysys->add(
          {
            SYSTEM_ID      => $payment_system_id,
            DATETIME       => "$DATE $TIME",
            SUM            => $FORM{SUM},
            UID            => $LIST_PARAMS{UID},
            IP             => "$ENV{'REMOTE_ADDR'}",
            TRANSACTION_ID => "$FORM{OPERATION_ID}",
            INFO           => '-',
            PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
            STATUS         => 1,
          }
        );
      }
      return 0;
    }
  }

  $user->pi({ UID => $LIST_PARAMS{UID} });
  $info{PHONE}=$user->{PHONE};

  if (in_array('Dv', \@MODULES)) {
    require Dv;
    Dv->import();

    my $Dv = Dv->new($db, $admin, \%conf);
    $Dv = $Dv->info($LIST_PARAMS{UID});
    if ($Dv->{MONTH_ABON} > $FORM{SUM}) {
      $FORM{SUM}      = $Dv->{MONTH_ABON};
      $info{DESCRIBE} = "$lang{TARIF_PLAN_SUM}";
    }
  }

  return $html->tpl_show(_include('paysys_qiwi_add', 'Paysys'), \%info, $attr);
}

#**********************************************************
=head2 paysys_qiwi_list()

=cut
#**********************************************************
sub paysys_qiwi_list {

  #my %info = ();
  paysys_load('Qiwi');

  my $list = $Paysys->list({ %LIST_PARAMS, PAYMENT_SYSTEM => 59, INFO => '-', COLS_NAME => 1 });
  my $table = $html->table(
    {
      width      => '100%',
      caption    => "Paysys",
      title      =>
      [ 'ID', "$lang{LOGIN}", "$lang{DATE}", "$lang{SUM}", "$lang{PAY_SYSTEM}", "$lang{TRANSACTION}", "IP",
        "$lang{STATUS}", '-' ],
      qs         => $pages_qs,
      pages      => $Paysys->{TOTAL},
      ID         => 'PAYSYS_QIWI_LIST',
      EXPORT     => 1
    }
  );

  my %status_hash = (
    10  => 'Не обработана',
    20  => 'Отправлен запрос провайдеру',
    25  => 'Авторизуется',
    30  => 'Авторизована',
    48  => 'Проходит финансовый контроль',
    49  => 'Проходит финансовый контроль',
    50  => 'Проводится',
    51  => 'Проведена (51)',
    58  => 'Перепроводится',
    59  => 'Принята к оплате',
    60  => 'Проведена',
    61  => 'Проведена',
    125 => 'Не смогли отправить провайдеру',
    130 => 'Отказ от провайдера',
    148 => 'Не прошел фин. контроль',
    149 => 'Не прошел фин. контроль',
    150 => 'Ошибка авторизации (неверный логин/пароль)',
    160 => 'Не проведена',
  );

  my @ids_arr = ();
  foreach my $line (@$list) {
    push @ids_arr, $line->{transaction_id};
  }

  my $result = qiwi_status({ IDS => \@ids_arr });

  my %res_hash = ();
  if ($result->{'bills-list'}) {
    foreach my $id (keys %{ $result->{'bills-list'}->[0]->{bill} }) {
      $res_hash{$id} = $result->{'bills-list'}->[0]->{bill}->{$id}->{status};
    }
  }

  foreach my $line (@$list) {
    $table->addrow(
      $line->{id},
      $html->button("$line->{login}", "index=15&UID=$line->{uid}"),
      $line->{datetime},
      $line->{sum},
      $PAY_SYSTEMS{$line->{system_id}},
      $html->button("$line->{transaction_id}", "index=2&EXT_ID=QIWI:$line->{transaction_id}&search=1"),
      $line->{ip},
      $status_hash{ $res_hash{ $line->{transaction_id} } },
      $html->button( $lang{INFO}, "index=$index&info=$line->{id}" )
    );
  }
  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      rows       => [ [ "$lang{TOTAL}:", $html->b( $Paysys->{TOTAL} ), "$lang{SUM}", $html->b( $Paysys->{SUM} ) ] ]
    }
  );
  print $table->show();
  return 1;
}

#**********************************************************
=head2 paysys_paypal() - User portal payments system with privat 24

=cut
#**********************************************************
sub paysys_paypal {
  my %info = ();

  paysys_load('Paypal');
  my $payment_system_id = 66;
  my $payment_system    = 'Paypal';
  my $feesPayer;
  my $receiverPrimaryArray;
  my $memo;
  my $pin;
  my $preapprovalKey;
  my $reverseAllParallelPaymentsOnError;
  my $senderEmail;
  #our $trackingId; #paypal


  if ($FORM{cancel}) {
    $html->message( 'err', $lang{ERROR}, "$lang{FAILED} ID: $FORM{OPERATION_ID} Cancel" );
  }
  elsif ($FORM{finish}) {
    $Paysys->info({ CODE => $FORM{OPERATION_ID} });
    if ($Paysys->{TOTAL} > 0) {
      if ($Paysys->{UID} != $LIST_PARAMS{UID}) {
        $html->message( 'err', $lang{ERROR}, "$lang{FAILED} ID: $FORM{OPERATION_ID}" );
      }
      else {
        if ($Paysys->{STATUS} == 2) {
          $html->message( 'info', $lang{INFO},
            "$lang{ADDED} $lang{SUM}: $Paysys->{SUM} $lang{TRANSACTION} ID: $FORM{OPERATION_ID}" );
        }
        elsif ($Paysys->{STATUS} == 1) {
          my $resArray = CallPaymentDetails('', '', $FORM{OPERATION_ID});
          my $result = '';
          while (my ($k, $v) = each %$resArray) {
            $v =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
            $result .= "$k -> $v\n";
          }

          if ($resArray->{status} eq 'COMPLETED') {
            $Paysys->change(
              {
                ID     => $Paysys->{ID},
                STATUS => 2,
                INFO   => "$result"
              }
            );

            my $ext_id = "$Paysys->{TRANSACTION_ID}";
            $Payments->add(
              $user,
              {
                SUM          => $Paysys->{SUM},
                DESCRIBE     => 'Paypal',
                METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
                EXT_ID       => $ext_id,
                CHECK_EXT_ID => $ext_id,
              }
            );
          }
          else {
            $html->message( 'err', $lang{ERROR}, "$lang{FAILED} ID: $FORM{OPERATION_ID} / $Paysys->{TRANSACTION_ID}" );
          }

          $html->message( 'info', $lang{INFO},
            "$lang{ADDED} $lang{SUM}: $Paysys->{SUM} $lang{TRANSACTION} ID: $FORM{OPERATION_ID}" );

        }
        else {
          $html->message( 'err', $lang{ERROR},
            "$lang{FAILED} ID: $FORM{OPERATION_ID} / $Paysys->{TRANSACTION_ID}/ $Paysys->{STATUS}" );
        }
      }
    }
    else {
      $html->message( 'err', $lang{ERROR}, "$lang{FAILED} $lang{TRANSACTION}: $FORM{OPERATION_ID} $lang{NOT_FOUND}" );
    }
    $html->set_cookies('lastindex', "", "Fri, 1-Jan-2038 00:00:01")  if (! $FORM{INTERACT});
    return 0;
  }
  else {
    if ($FORM{SUM} <= 0) {
      $html->message( 'info', $lang{ERROR}, "$lang{ERR_WRONG_SUM} $FORM{SUM}" );
      return 0;
    }

    if ($Paysys->{errno}) {
      $html->message( 'err', "$lang{ERROR}", "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}'" );
      return 0;
    }
    else {
      if ($FORM{STEP}) {
        my $ipnNotificationUrl = "https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi";
        my $returnUrl          = "https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?OPERATION_ID=$FORM{OPERATION_ID}&PAYMENT_SYSTEM=66&index=$index&finish=1";
        my $cancelUrl          = "https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?OPERATION_ID=$FORM{OPERATION_ID}&PAYMENT_SYSTEM=66&index=$index&cancel=1";
        my $trackingId         = $FORM{OPERATION_ID};
        my $actionType         = 'PAY';
        #$FORM{SUM}             = $FORM{FULL_SUM};

        my $resArray = CallPay($actionType,
          $cancelUrl,
          $returnUrl,
          [ $conf{PAYSYS_PAYPAL_RECIEVER_EMAIL} ], [ $FORM{FULL_SUM} ],
          $receiverPrimaryArray, [ $FORM{OPERATION_ID} ],
          $feesPayer,
          $ipnNotificationUrl,
          $memo,
          $pin,
          $preapprovalKey,
          $reverseAllParallelPaymentsOnError,
          $senderEmail,
          $trackingId);

        my $message = '';
        if ($resArray->{'error(0).errorId'}) {
          #Invalid header
          if($resArray->{'error(0).errorId'} == 560022) {
            $message = $resArray->{'error(0).message'};
          }
          else {
            $message = $resArray->{'error(0).message'};
          }

          $message =~ s/\+/ /g;
          $message =~ s/\%3A/:/g;
          $message =~ s/\%2C/,/g;
        }

        #Info section
        $Paysys->add(
          {
            SYSTEM_ID      => $payment_system_id,
            DATETIME       => "$DATE $TIME",
            SUM            => $FORM{SUM},
            UID            => $LIST_PARAMS{UID},
            IP             => "$ENV{'REMOTE_ADDR'}",
            TRANSACTION_ID => "$payment_system:" . ($resArray->{'payKey'} || $FORM{OPERATION_ID}),
            INFO           => "OPERATION_ID: $FORM{OPERATION_ID} FULL_SUM: $FORM{FULL_SUM}". (! $resArray->{'responseEnvelope.ack'} || $resArray->{'responseEnvelope.ack'} ne 'Success') ? $message : '',
            CODE           => "$FORM{OPERATION_ID}",
            PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
            STATUS         => ($resArray->{'responseEnvelope.ack'} && $resArray->{'responseEnvelope.ack'} eq 'Success') ? 1 : 6
          }
        );
        if ($resArray->{'responseEnvelope.ack'} eq 'Success') {
          $html->set_cookies('lastindex', "$index", "Fri, 1-Jan-2038 00:00:01");
          if ("" eq $preapprovalKey) {
            # redirect for web approval flow
            my $cmd = "cmd=_ap-payment&paykey=" . $resArray->{"payKey"};
            $info{PP_LINK} = RedirectToPayPal($cmd, { OUTPUT2RETURN => undef });
          }
          else {
            # payKey is the key that you can use to identify the payment resulting from the Pay call
            #my $payKey = $resArray->{"payKey"};
            # paymentExecStatus is the status of the payment
            #my $paymentExecStatus = $resArray->{"paymentExecStatus"};
          }
        }
        else {
          $html->message( 'err', $lang{ERROR}, "$lang{FAILED} ID: $FORM{OPERATION_ID}\n\n$message" );

          if ($conf{PAYSYS_DEBUG} > 2) {
            print "Content-Type: text/html\n\n";
            while (my ($k, $v) = each %$resArray) {
              print "$k, $v <br>";
            }
          }
          return 0;
        }
      }
      else {
        $FORM{FULL_SUM}  = $FORM{SUM};
        $FORM{COMMISION} = 0.00;
        if ($conf{PAYSYS_PAYPAL_COMMISSION}) {
          $conf{PAYSYS_PAYPAL_COMMISSION}=~s/%SUM%/$FORM{SUM}/;
          $FORM{COMMISION} = eval($conf{PAYSYS_PAYPAL_COMMISSION});
          $FORM{FULL_SUM}  = $FORM{SUM}+$FORM{COMMISION};
        }
      }
    }
  }
  #print "Content-Type: text/html\n\n";

  $html->tpl_show(_include('paysys_paypal_add', 'Paysys'), { %info, %$user });
}

#**********************************************************
=head2 paysys_ipay($attr) User portal payments system with Ipay

=cut
#**********************************************************
sub paysys_ipay {
  my ($attr) = @_;

  load_pmodule('LWP::UserAgent');
  load_pmodule('XML::Simple');
  my $xs = XML::Simple->new();
  my $ua = LWP::UserAgent->new;
  paysys_load('Ipay');

  my $payment_system    = 'Ipay';
  my $payment_system_id = 72;

  # при неудачной оплате
  if($FORM{FALSE}){
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}" , FALSE => 1});
    return 0;
  }
  # при удачной оплате
  if($FORM{TRUE}){
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}" });
    return 0;
  }

  # мерчант данные
  #my $merch_key  = $conf{PAYSYS_IPAY_MERCHANT_KEY};
  my $merch_id   = int($conf{PAYSYS_IPAY_MERCHANT_ID});
  #my $system_key = $conf{PAYSYS_IPAY_SYSTEM_KEY};
  my $service_id = int($conf{PAYSYS_IPAY_SERVICE_ID});
  my $post_url   = "https://api.sandbox.ipay.ua/";
  my $url_good   = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?index=$index&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&OPERATION_ID=$FORM{OPERATION_ID}&TRUE=1";
  my $url_bad    = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?index=$index&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&OPERATION_ID=$FORM{OPERATION_ID}&FALSE=1";
  my $amount     = $FORM{SUM} * 100;
  $conf{PAYSYS_IPAY_CURRENCY} = 'UAH' if (!$conf{PAYSYS_IPAY_CURRENCY});
  $conf{PAYSYS_IPAY_LANGUAGE} = 'ru' if (!$conf{PAYSYS_IPAY_LANGUAGE});

  # salt & signature
  my ($salt, $signature) = salt_sign({signature => 1});

  # xml hash для xml данных
  my $xml_hash = {
    'payment' => {
      'urls' => {
        'good' => [$url_good],
        'bad'  => [$url_bad]
      },
      'auth' => {
        'mch_id' => [$merch_id],
        'salt'   => [$salt],
        'sign'   => [$signature]
      },
      'transactions' => [{
        'transaction' => [{
          'mch_id'   => [$merch_id],
          'srv_id'   => [$service_id],
          'type'     => [11],
          'amount'   => [$amount],
          'currency' => [$conf{PAYSYS_IPAY_CURRENCY}],
          'desc'     => ['Оплата'],
          'info'     => ["{'UID':$user->{UID},'OID':$FORM{OPERATION_ID}}"]
        }]
      }],
      'lifetime'=> [12],
      'version' => ['3.00'],
      'lang'    => [$conf{PAYSYS_IPAY_LANGUAGE}]
    }
  };

  # xml Данные
  my $xml = $xs->XMLout($xml_hash,
    'XMLDecl'  => '<?xml version="1.0" encoding="UTF8"?>',
    'RootName' => 'payment');

  $ua->ssl_opts( 'verify_hostname' => 0);
  my $resp = $ua->post( $post_url, { 'data' => $xml });

  my $ipay_xml = $resp->decoded_content;
  my $ipay_data = $xs->XMLin($ipay_xml);
  my $pay_url = $ipay_data->{url};

  # добавление в таблицу платежа
  $Paysys->add(
    {
      SYSTEM_ID      => $payment_system_id,
      DATETIME       => "$FORM{DATETIME}",
      SUM            => $FORM{SUM},
      UID            => $LIST_PARAMS{UID},
      IP             => "$ENV{'REMOTE_ADDR'}" || '0.0.0.0',
      TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
      PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
      STATUS         => 1,
      USER_INFO      => ''
    }
  );

  if ($Paysys->{errno}) {
    my $message = '';
    if ($Paysys->{errno} == 7) {
      $message = "\n$lang{EXIST}";
    }

    $html->message( 'err', "$lang{ERROR}", "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}'" . $message );
    return 0;
  }
  my %info = ();
  # данные в шаблон
  $info{ORDER_ID} = $FORM{OPERATION_ID};
  $info{SUM}      = $FORM{SUM};
  $info{IPAY_URL} = $pay_url;

  return $html->tpl_show(_include('paysys_ipay_add', 'Paysys'), \%info, { OUTPUT2RETURN => $attr->{OUTPUT2RETURN} });
}

#**********************************************************
=head2 paysys_cp_visa($attr) User portal payments system with Cyberplat Visa

=cut
#**********************************************************
sub paysys_cp_visa {
  my ($attr) = @_;

  if (defined($FORM{abillserrormsg})) {
    my @AbillsErrorMsg = ('Transaction successfuly added', 'User not found', 'Billing system error', 'Dublicate payment', 'Transaction error');

    $html->message( 'err', $lang{ERROR}, "$lang{FAILED} - $AbillsErrorMsg[$FORM{abillserrormsg}]" );

    #print 'lol';
  }
  else {
    my @fio;
    my $users = Users->new($db, $admin, \%conf);
    $user = $users->info($LIST_PARAMS{UID});
    $users->pi({ UID => $LIST_PARAMS{UID} });
    (@fio) = split(' ', $users->{FIO});

    my %info = ();
    my $sum;
    $info{PAYMENT_NO} = $FORM{OPERATION_ID};

    if ($FORM{SUM} =~ /^(\d+)\.?(\d+)?$/) {
      $sum = "$1$2";
    }
    $info{amount_with_point} = $FORM{SUM};
    $info{desc}              = $FORM{DESCRIBE};

    if ($conf{PAYSYS_CP_VISA_TEST_MODE} == 1) {
      $info{lastname}   = 'Ivanov';
      $info{firstname}  = 'Ivan';
      $info{middlename} = 'Ivanovich';
      $info{email}      = 'support@cyberplat.com';
      $info{phone}      = 7445 - 4060;
    }
    else {
      $info{lastname}   = $fio[0]         || '';
      $info{firstname}  = $fio[1]         || '';
      $info{middlename} = $fio[2]         || '';
      $info{email}      = $users->{EMAIL} || '';
      $info{phone}      = $users->{PHONE} || '';

    }

    return $html->tpl_show(_include('paysys_cyberplat_visa', 'Paysys'), \%info, { OUTPUT2RETURN => $attr->{OUTPUT2RETURN} });
  }
}


#**********************************************************
# User web portal payments system with Payonline
#**********************************************************
sub paysys_payonline {
  my ($attr) = @_;

  if (defined($FORM{payonline_transaction})) {
    $html->message( 'info', $lang{INFO}, "$lang{ADDED} $lang{TRANSACTION}: $FORM{payonline_transaction}" );
    $html->set_cookies('lastindex', "", "Fri, 1-Jan-2038 00:00:01");
  }

  elsif (defined($FORM{ErrorCode})) {
    my @error_codes = (
      ' Возникла техническая ошибка, попробуйте повторить попытку оплаты спустя некоторое время',
      ' Провести платеж по банковской карте невозможно. Вам стоит воспользоваться другим способом оплаты',
      ' Платеж отклоняется банком-эмитентом карты. Плательщику стоит связаться с банком, выяснить причину отказа и повторить попытку оплаты.'
    );

    $html->message( 'err', $lang{ERROR}, "$lang{FAILED}: \n" . ($error_codes[ $FORM{ErrorCode} - 1 ]) );
  }

  else {
    $html->set_cookies('lastindex', "", "Fri, 1-Jan-2038 00:00:01");
    my $payment_href       = '';
    my $payment_type_title = '';

    if ($FORM{PAYMENT_SYSTEM} == 81) {

      #QIWI
      $payment_href       = 'https://secure.payonlinesystem.com/ru/payment/select/qiwi/';
      $payment_type_title = 'QIWI';

    }
    elsif ($FORM{PAYMENT_SYSTEM} == 82) {

      #Webmoney
      $payment_href       = 'https://secure.payonlinesystem.com/ru/payment/select/webmoney/';
      $payment_type_title = 'Webmoney';

    }
    elsif ($FORM{PAYMENT_SYSTEM} == 83) {

      #Yandex.Money
      $payment_href       = 'https://secure.payonlinesystem.com/ru/payment/select/yandexmoney/';
      $payment_type_title = 'Yandex.Money';
    }
    elsif ($FORM{PAYMENT_SYSTEM} == 84) {

      #Bank.Card
      $payment_href       = 'https://secure.payonlinesystem.com/ru/payment/';
      $payment_type_title = 'Bank.Card';
    }
    my %info = ();
    my $sum;
    $info{OrderId} = $FORM{OPERATION_ID};

    if ($FORM{SUM} =~ /^(\d{1,5})\.?(\d{1,2})?$/) {
      $sum = $FORM{SUM};
    }
    $info{amount}   = $sum;
    $info{desc}     = "Login:$LIST_PARAMS{LOGIN} Transaction:$FORM{OPERATION_ID} UID:$LIST_PARAMS{UID}";
    $info{form_url} = $payment_href;

    load_pmodule('Digest::MD5');

    $info{securitykey} =
      md5_hex('MerchantId='
        . $conf{PAYSYS_PAYONLINE_MERCHANT_ID}
        . '&OrderId='
        . $info{OrderId}
        . '&Amount='
        . $sum
        . '&Currency=RUB&OrderDescription='
        . $info{desc}
        . '&PrivateSecurityKey='
        . $conf{PAYSYS_PAYONLINE_SECURITY_KEY});

    $info{payment_form_title} = $payment_type_title;
    $info{payment_system_id} = $FORM{PAYMENT_SYSTEM};

    $info{returnurl} = "https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?index=$index&payonline_transaction=$info{OrderId}&sid=$FORM{sid}";
    $info{failurl} = "https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}";    #?index=$index&payonline_transaction_error=$info{OrderId}&sid=$FORM{sid}
    $html->set_cookies('lastindex', "$index", "Fri, 1-Jan-2038 00:00:01") if (! $FORM{INTERACT});

    return $html->tpl_show(_include('paysys_payonline_add', 'Paysys'), \%info, { OUTPUT2RETURN => $attr->{OUTPUT2RETURN} });
  }
}


#**********************************************************
=head2 paysys_yandex()

=cut
#**********************************************************
sub paysys_yandex {

  paysys_load('Yandex');
  Yandex->import();
  my $Ym = Yandex->ym_new($db, $admin, \%conf);
  my $ym_token = '';

  my %YANDEX_ERR = (
    'illegal_params'      => 'Обязательные параметры платежа отсутствуют или имеют недопустимые значения.',
    'illegal_param_label' => 'Недопустимое значение параметра label.',
    'phone_unknown'       => 'Указан номер телефона не связанный со счетом пользователя или получателя платежа.',
    'payment_refused'      => 'Отказано в приёме платежа (например пользователь попробовал заплатить за товар, которого нет в магазине).',
    'authorization_reject'=> "В авторизации платежа отказано. Возможные причины:\n\n
     - транзакция с текущими параметрами запрещена для данного пользователя;\n
     - пользователь не принял Соглашение об использовании системы \"Яндекс.Деньги\". ",
    'not_enough_funds'   =>   'На счете плательщика недостаточно средств. Необходимо пополнить счет и провести новый платеж.',
    'limit_exceeded'     =>  "Превышен один из лимитов на операции:\n\n
    - на сумму операции для выданного токена авторизации; \n
    - сумму операции за период времени для выданного токена авторизации; \n
    - ограничений платежной системы для различных видов операций.\n\n
    Техническая ошибка, повторите вызов операции позднее."
  );

  if ($FORM{code}) {
    $Ym->receiveOAuthToken({ code => $FORM{code} });
    if($Ym->{error}) {
      $html->message( 'err', "$lang{INFO} Token", "$Ym->{error} $Ym->{error_str}" );
    }
    else {
      $Ym->query2("UPDATE users_pi SET ym_token=ENCODE('$Ym->{token}', '$conf{secretkey}') WHERE uid='$LIST_PARAMS{UID}';", 'do');
      $ym_token = $Ym->{token};
      delete $FORM{PAYMENT_SYSTEM};
      $html->message( 'info', "$lang{INFO}", "Yandex.Money Токен обновлён, теперь можете совершать оплату" );
      paysys_payment();
      return 0;
    }
  }
  else {
    $Ym->query2("SELECT DECODE(ym_token, '$conf{secretkey}') AS ym_token FROM users_pi WHERE uid='$LIST_PARAMS{UID}';", undef, { INFO => 1 });
    if ($Ym->{TOTAL} > 0 && $Ym->{YM_TOKEN}  ne '') {
      $ym_token  = $Ym->{YM_TOKEN};
    }
    else {
      $Ym->yandex_get_token({ SUM => $FORM{SUM} });
      return 0;
    }
  }

  if ($FORM{CONFIRM_PAYMENT}) {
    my $result_hash = $Ym->ym_process_payment($ym_token, $FORM{REQUEST_ID});

    if($Ym->{error}) {
      if ($Ym->{error} == 2) {
        $Ym->query2("UPDATE users_pi SET ym_token='' WHERE uid='$LIST_PARAMS{UID}';", 'do');
      }

      if ($YANDEX_ERR{$Ym->{error_str}}) {
        $html->message( 'err', "$lang{ERROR}",
          "$YANDEX_ERR{$Ym->{error_str}} \n $Ym->{status} \n $Ym->{error_description}" )
      }
      else {
        $html->message( 'err', "$lang{ERROR}", "$lang{ERR_UNKNOWN} $Ym->{error} $Ym->{error_str}" );
      }
      `echo "\nERROR: !! $Ym->{error} $Ym->{error_str}" >> /tmp/ym`;
    }
    else {
      $Paysys->info({ CODE => $FORM{REQUEST_ID} });
      if ($Paysys->{TOTAL} > 0) {
        if ($Paysys->{UID} != $LIST_PARAMS{UID}) {
          $html->message( 'err', $lang{ERROR}, "$lang{FAILED} ID: $FORM{OPERATION_ID}" );
        }
        else {
          if ($Paysys->{STATUS} == 2) {
            $html->message( 'info', $lang{INFO},
              "$lang{ADDED} $lang{SUM}: $Paysys->{SUM} $lang{TRANSACTION} ID: $FORM{OPERATION_ID}" );
          }
          elsif ($Paysys->{STATUS} < 2) {
            if ($result_hash->{status} eq 'success') {
              my $result = '';
              my %result;
              while(my($k, $v)=each %result) {
                $result .= "$k: $v; ";
              }
              $Paysys->change({
                ID     => $Paysys->{ID},
                STATUS => 2,
                INFO   => "$result"
              });

              if (! $Paysys->{error}) {
                cross_modules_call('_pre_payment', { USER_INFO   => $user,
                    SKIP_MODULES=> 'Sqlcmd',
                    QUITE       => 1,
                    SUM         => $Paysys->{SUM},
                  });

                $Payments->add($user,
                  {
                    METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{73}) ? 73 : '2',
                    EXT_ID       => "$Paysys->{TRANSACTION_ID}",
                    CHECK_EXT_ID => "$Paysys->{TRANSACTION_ID}",
                    SUM          => $Paysys->{SUM},
                  });

                #Exists
                if ($Payments->{errno} && $Payments->{errno} == 7) {
                  $html->message( 'err', $lang{ERROR}, "$lang{EXIST}: " );
                }
                elsif ($Payments->{errno}) {
                  $html->message( 'err', $lang{ERROR}, "$lang{ERROR}" );
                }
                else {
                  cross_modules_call('_payments_maked', {
                      USER_INFO  => $user,
                      PAYMENT_ID => $Payments->{PAYMENT_ID},
                      SUM        => $Paysys->{SUM},
                      QUITE      => 1
                    });
                }
              }
            }
          }
        }
      }

      $html->message( 'info', $lang{INFO}, "$lang{ADDED} $lang{SUM}: $Paysys->{SUM} ID: $Paysys->{TRANSACTION_ID}" );
    }
  }
  else {
    my $result_hash = $Ym->ym_request_payment_p2p($ym_token, undef, "$FORM{SUM}",
      "$FORM{OPERATION_ID}", "$user->{LOGIN} UID: $LIST_PARAMS{UID}");

    if($Ym->{error}) {
      if ($Ym->{error} == 2) {
        $Ym->query2("UPDATE users_pi SET ym_token='' WHERE uid='$LIST_PARAMS{UID}';", 'do');
      }

      if ($YANDEX_ERR{$Ym->{error_str}}) {
        $html->message( 'err', "$lang{ERROR} $lang{STEP} 1",
          "$YANDEX_ERR{$Ym->{error_str}} \n $Ym->{status} \n $Ym->{error_description}" )
      }
      else {
        $html->message( 'err', "$lang{ERROR}", "$lang{ERR_UNKNOWN} $Ym->{error} $Ym->{error_str}" );
      }
      `echo "\nERROR: !! $Ym->{error} $Ym->{error_str}" >> /tmp/ym`;
    }
    else {
      my %info  = ();
      $info{REQUEST_ID}=$result_hash->{request_id};
      $html->tpl_show(_include('paysys_ym_confirm', 'Paysys'), \%info);

      $Paysys->add(
        {
          SYSTEM_ID      => 73,
          DATETIME       => "$DATE $TIME",
          SUM            => $FORM{SUM},
          UID            => $LIST_PARAMS{UID},
          IP             => $ENV{REMOTE_ADDR},
          TRANSACTION_ID => "YM:$FORM{OPERATION_ID}",
          STATUS         => 1,
          CODE           => $result_hash->{request_id},
          PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
        }
      );
    }
  }
}

#**********************************************************
=head2 paysys_perfectmoney()

=cut
#**********************************************************
sub paysys_perfectmoney {

  my $payment_system    = 'PM';
  #my $payment_system_id = 86;

  if ($FORM{FALSE}) {
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}", FALSE => 1 });
    return 0;
  }
  elsif($FORM{TRUE}) {
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}" });
    return 0;
  }
  my %info = ();
  $html->tpl_show(_include('paysys_perfectmoney_add', 'Paysys'), \%info);
}


#**********************************************************
#
#**********************************************************
sub paysys_okpay {
  #my ($attr) =@_;

  my %info = ();
  my $payment_system    = 'Okpay';
  #my $payment_system_id = 87;

  if ($FORM{FALSE}) {
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}", FALSE => 1 });
    return 0;
  }
  elsif($FORM{TRUE}) {
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}" });
    return 0;
  }

  $html->tpl_show(_include('paysys_okpay_add', 'Paysys'), \%info);
}

#**********************************************************
=head2 paysys_smsonline() Smsm Online

=cut
#**********************************************************
sub paysys_smsonline {
  #my ($attr)=@_;

  #my $operation_id      = $FORM{OPERATION_ID};
  my $payment_system    = 'SMSO';
  my $payment_system_id = 89;

  my $table = $html->table({
    width      => '100%',
    caption    => 'Оплата через смс',
    title      => ['Sms на номер', 'Текст смс', 'Баланс будет пополнен на', 'Cтоимость смс'],
    ID         => 'SMSONLINE_ID'
  });

  while (my ($key, $value) = each(%{$conf{SMSONLINE}})){

    $table->addrow(
      $key,
      "$value->{pref} $FORM{OPERATION_ID}",
      "$value->{price_with_vat} грн.",
      "$value->{price} грн."
    );
  }
  print $table->show();

  $Paysys->add({
    SYSTEM_ID      => $payment_system_id,
    DATETIME       => "'$DATE $TIME'",
    SUM            => 0,
    UID            => "$LIST_PARAMS{UID}",
    IP             => '0.0.0.0',
    TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
    INFO           => "$payment_system:$FORM{OPERATION_ID}",
    PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
    STATUS         => 1
  });
}


#**********************************************************
# 80567161228 vadim
# vadim.ignatkin@pbank.com.ua
#**********************************************************
sub paysys_cashcom {
  my %info = ();

  $html->tpl_show(_include('paysys_cashcom_add', 'Paysys'), \%info);
}

#**********************************************************
#
#**********************************************************
sub paysys_payu {
  my %info = ();
  my $debug;
  my $payment_system    = 'PAYU';
  my $payment_system_id = 91;
  #my $order_id          = $FORM{orderid};

  paysys_load('Payu');

  if ($FORM{FALSE}) {
    if ($FORM{reasoncode} == 11) {
      $FORM{reasoncodedesc} = "$lang{ERR_INVALID_SIGNATURE}";
    }
    elsif ($FORM{reasoncode} == 2) {
      $FORM{reasoncodedesc} = "$lang{ERR_TRANSACTION_DECLINED}";
    }
    $html->message( 'err', $lang{ERROR},
      "$lang{FAILED} ID: $FORM{orderid} [$FORM{reasoncode}/$FORM{responsecode}] $FORM{reasoncodedesc} " );
    $html->set_cookies('lastindex', "", "Fri, 1-Jan-2038 00:00:01");

    return 0;
  }
  elsif ($FORM{TRUE}) {
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{orderid}" });
    return 0;
  }
  else {
    if ($FORM{SUM} <= 0) {
      $html->message( 'info', $lang{ERROR}, "$lang{ERR_WRONG_SUM} $FORM{SUM}" );
      return 0;
    }

    #Info section
    $Paysys->add(
      {
        SYSTEM_ID      => $payment_system_id,
        DATETIME       => "$DATE $TIME",
        SUM            => $FORM{SUM},
        UID            => $LIST_PARAMS{UID},
        IP             => "$ENV{'REMOTE_ADDR'}",
        TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
        INFO           => '-',
        PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
        STATUS         => 1
      }
    );

    if ($Paysys->{errno}) {
      $html->message( 'err', "$lang{ERROR}", "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}'" );
      return 0;
    }
  }

  my %forSend = (
    'ORDER_REF'        => $FORM{OPERATION_ID}, # Uniqe order
    'ORDER_PNAME[]'    => "$FORM{DESCRIBE}", #, "Тест товар №1", "Test_goods3" ), # Array with data of goods
    'ORDER_PCODE[]'    => "Payment", # "testgoods2", "testgoods3" ), # Array with codes of goods
    'ORDER_PINFO[]'    => "", #, "", "" ), # Array with additional data of goods
    'ORDER_PRICE[]'    => "$FORM{SUM}", # "0.11", "0.12" ), # Array with prices of goods
    'ORDER_QTY[]'      => 1, # 2, 1 ), # Array with data of counts of each goods
    'ORDER_VAT[]'      => 0, # 0, 0 ), # Array with VAT of each goods
    'ORDER_SHIPPING'   => 0, # Shipping cost
    'PRICES_CURRENCY'  => "UAH",  # Currency
    'LANGUAGE'         => "RU",
    'BILL_FNAME'       => "$PROGRAM", # ...  etc.
    #'ORDER_DATE'      => '2014-01-18 15:44:00'
  );

  if ( ! $conf{PAYSYS_PAYU_MERCHANT} || ! $conf{PAYSYS_PAYU_SECRET} ) {
    $html->message( 'err', $lang{ERROR}, 'Not set  $conf{PAYSYS_PAYU_MERCHANT} $conf{PAYSYS_PAYU_SECRET}' );
    return 0;
  }

  $forSend{'MERCHANT'}  = $conf{PAYSYS_PAYU_MERCHANT};
  if( !$forSend{'ORDER_DATE'} ) {
    $forSend{'ORDER_DATE'} = "$DATE $TIME";
  }

  $forSend{'TESTORDER'} = ( $debug > 2 ) ? "TRUE" : "FALSE";

  $forSend{'DEBUG'}    = ($debug>1) ? 1 : 0;
  $forSend{ORDER_HASH} = mk_signature(mk_array(\%forSend));
  #if ( count($opt) === 0 ) return $this;
  foreach my $k ( keys %forSend )  {
    $info{FIELDS}.="<input type=hidden name=$k value='$forSend{$k}'>\n";
  }

  $html->tpl_show(_include('paysys_payu_add', 'Paysys'), \%info);
}


#**********************************************************
#
#**********************************************************
sub paysys_copayco {
  my %info = ();

  my $payment_system    = 'CoPayCo';
  my $payment_system_id = 92;
  #my $order_id          = $FORM{orderid};
  $FORM{DATETIME}       = "$DATE $TIME";
  $FORM{CURRENCY}       = 'UAH';
  $FORM{RANDOM}         = '428';

  paysys_load('Copayco');

  if ($FORM{FALSE}) {
    if ($FORM{reasoncode} == 11) {
      $FORM{reasoncodedesc} = "$lang{ERR_INVALID_SIGNATURE}";
    }
    elsif ($FORM{reasoncode} == 2) {
      $FORM{reasoncodedesc} = "$lang{ERR_TRANSACTION_DECLINED}";
    }
    $html->message( 'err', $lang{ERROR},
      "$lang{FAILED} ID: $FORM{orderid} [$FORM{reasoncode}/$FORM{responsecode}] $FORM{reasoncodedesc} " );
    $html->set_cookies('lastindex', "", "Fri, 1-Jan-2038 00:00:01");

    return 0;
  }
  elsif ($FORM{TRUE}) {
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{orderid}" });
    return 0;
  }
  else {
    if ($FORM{SUM} <= 0) {
      $html->message( 'info', $lang{ERROR}, "$lang{ERR_WRONG_SUM} $FORM{SUM}" );
      return 0;
    }

    #Info section
    $Paysys->add(
      {
        SYSTEM_ID      => $payment_system_id,
        DATETIME       => "$FORM{DATETIME}",
        SUM            => $FORM{SUM},
        UID            => $LIST_PARAMS{UID},
        IP             => "$ENV{'REMOTE_ADDR'}",
        TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
        INFO           => '-',
        PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
        STATUS         => 1
      }
    );

    if ($Paysys->{errno}) {
      my $message = '';
      if ($Paysys->{errno} == 7) {
        $message = "\n$lang{EXIST}";
      }

      $html->message( 'err', "$lang{ERROR}", "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}'" . $message );

      return 0;
    }
  }


  $FORM{SUM} = int($FORM{SUM}*100);
  $FORM{SIGN} = copayco_sign(\%FORM);

  $html->tpl_show(_include('paysys_copayco_add', 'Paysys'), { %FORM, %info });
}


#**********************************************************
#
#**********************************************************
sub paysys_redsys {
  #my ($attr)=@_;
  use Conf;
  my $Conf = Conf->new($db, $admin, \%conf);

  paysys_load('Redsys');

  my %info              = ();
  my $payment_system    = 'Redsys';
  my $payment_system_id = 94;
  $FORM{DATETIME}       = "$DATE $TIME";
  $FORM{CURRENCY}       = 'EUR';

  if ($FORM{FALSE}) {
    if ($FORM{reasoncode} == 11) {
      $FORM{reasoncodedesc} = "$lang{ERR_INVALID_SIGNATURE}";
    }
    elsif ($FORM{reasoncode} == 2) {
      $FORM{reasoncodedesc} = "$lang{ERR_TRANSACTION_DECLINED}";
    }
    #$html->message('err', $lang{ERROR}, "$lang{FAILED} ID: $payment_system:$FORM{OPERATION_ID}");
    $html->set_cookies('lastindex', "", "Fri, 1-Jan-2038 00:00:01");
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}" , FALSE => 1});
    return 0;
  }
  elsif ($FORM{TRUE}) {
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}" });
    return 0;
  }
  else {
    if ($FORM{SUM} <= 0) {
      $html->message( 'info', $lang{ERROR}, "$lang{ERR_WRONG_SUM} $FORM{SUM}" );
      return 0;
    }

    #Info section
    $Paysys->add(
      {
        SYSTEM_ID      => $payment_system_id,
        DATETIME       => "$FORM{DATETIME}",
        SUM            => $FORM{SUM},
        UID            => $LIST_PARAMS{UID},
        IP             => "$ENV{'REMOTE_ADDR'}" || '0.0.0.0',
        TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
        PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
        STATUS         => 1,
        USER_INFO      => $conf{PAYSYS_USER_INFO_PROCESS} || ''
      }
    );

    if ($Paysys->{errno}) {
      my $message = '';
      if ($Paysys->{errno} == 7) {
        $message = "\n$lang{EXIST}";
      }

      $html->message( 'err', "$lang{ERROR}", "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}'" . $message );

      return 0;
    }
  }

  $FORM{TOTAL_SUM}  = $FORM{SUM}*100;
  $FORM{PARAMS}     = redsys_create_params(\%FORM);
  $FORM{SIGN}       = redsys_sign(\%FORM);

  return $html->tpl_show(_include('paysys_redsys_add', 'Paysys'), { %FORM, %info });
}

#**********************************************************
#
#**********************************************************
sub paysys_upc {
  #my ($attr)=@_;

  my $payment_system    = 'UPC';
  my $payment_system_id = 98;
  $FORM{DATETIME}       = "$DATE $TIME";
  $FORM{CURRENCY}       = 'UAH';

  my $status   = $FORM{TranCode} || 0;
  my $order_id = $FORM{OrderID} || '';

  our %error_codes;
  paysys_load('Upc');


  if ($FORM{FALSE}) {
    my $message  = ($error_codes{$status}) ? $error_codes{$status} : $status;

    if ($FORM{reasoncode} == 11) {
      $FORM{reasoncodedesc} = "$lang{ERR_INVALID_SIGNATURE}";
    }
    elsif ($FORM{reasoncode} == 2) {
      $FORM{reasoncodedesc} = "$lang{ERR_TRANSACTION_DECLINED}";
    }

    $html->message( 'err', $lang{ERROR}, "$lang{FAILED} ID: $order_id \n[$status]\n $message" );
    $html->set_cookies('lastindex', "", "Fri, 1-Jan-2038 00:00:01");

    return 0;
  }
  elsif ($FORM{OrderID}) {
    paysys_show_result({ TRANSACTION_ID =>  "$payment_system:$order_id" });
    return 0;
  }
  else {
    if ($FORM{SUM} <= 0) {
      $html->message( 'info', $lang{ERROR}, "$lang{ERR_WRONG_SUM} $FORM{SUM}" );
      return 0;
    }

    #Info section
    $Paysys->add(
      {
        SYSTEM_ID      => $payment_system_id,
        DATETIME       => "$FORM{DATETIME}",
        SUM            => $FORM{SUM},
        UID            => $LIST_PARAMS{UID},
        IP             => "$ENV{'REMOTE_ADDR'}",
        TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
        INFO           => '-',
        PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
        STATUS         => 1
      }
    );

    if ($Paysys->{errno}) {
      my $message = "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}'";
      if ($Paysys->{errno} == 7) {
        $message .= "\n$lang{EXIST}";
      }

      $html->message( 'err', "$lang{ERROR}", $message );

      return $message;
    }
  }

  my %info = ();
  $info{TOTALSUM}     = $FORM{SUM};
  $FORM{SUM}          = $FORM{SUM}*100;
  $FORM{PURCHASETIME} = $FORM{DATETIME};
  $FORM{PURCHASETIME} =~ s/[:\-\ ]//g;
  $FORM{PURCHASETIME} =~ s/^20//;

  $FORM{SIGN}         = upc_sign(\%FORM);

  $html->set_cookies('lastindex', "$index", "Fri, 1-Jan-2038 00:00:01") if (! $FORM{INTERACT});

  my $return = $html->tpl_show(_include('paysys_upc_add', 'Paysys'), { %FORM, %info });
  return $return;
}

#**********************************************************
#
#**********************************************************
sub paysys_minbank {
  my ($attr) = @_;

  my %info = ();

  paysys_load('Minbank');

  my @msg;

  $msg[1] = 'Платеж успешно добавлен';
  $msg[2] = 'При проведении платежа возникла ошибка';
  $msg[3] = 'Платеж отменен';
  $msg[4] = 'Платеж отклоняется банком-эмитентом карты. Вам стоит связаться с банком, выяснить причину отказа и повторить попытку оплаты.';
  $msg[5] = 'Возникла техническая ошибка, попробуйте повторить попытку оплаты спустя некоторое время';


  if (defined($FORM{minbank_msg})) {
    if($FORM{minbank_msg} == 1) {
      $html->message( 'info', $lang{INFO}, "$msg[1]" );
    }
    else {
      $html->message( 'err', "$lang{ERROR}", "$msg[$FORM{minbank_msg}]" );
    }
  }
  else {
    if (defined($FORM{minbank_action})) {
      minbank_payments();
    }
    else {

      $html->set_cookies('lastindex', "", "Fri, 1-Jan-2038 00:00:01");

      my $sum;
      $info{OrderId} = $FORM{OPERATION_ID};

      if ($FORM{SUM} =~ /^(\d{1,5})\.?(\d{1,2})?$/) {
        $sum = $FORM{SUM};
      }

      $info{amount}     = $sum;
      $info{sum}        = $sum * 100;
      $info{desc}       = "Login:$LIST_PARAMS{LOGIN}<br> Transaction:$FORM{OPERATION_ID}<br> UID:$LIST_PARAMS{UID}";
      $info{form_url}   = $conf{MINBANK_URL};
      $info{merchantid} = $conf{PAYSYS_MINBANK_MERCHANT_ID};
      $info{payment_system_id} = $FORM{PAYMENT_SYSTEM};
      $info{returnurl}  = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi";
      $info{sid}        = $FORM{sid};
      $info{account}    = $LIST_PARAMS{LOGIN};
      $info{MB_MERCHANT} = $conf{PAYSYS_MINBANK_MERCHANT_ID};
      $info{MB_ID}       = $conf{PAYSYS_MINBANK_DATA_ID};

      $html->set_cookies('lastindexs', $index, "Fri, 1-Jan-2038 00:00:01");

      return $html->tpl_show(_include('paysys_minbank_add', 'Paysys'), \%info, { OUTPUT2RETURN => $attr->{OUTPUT2RETURN} });
    }
  }

}


#**********************************************************
# User portal payments system with Comepay
#
# https://shop.comepay.ru/Data/ComePayAPIIS.pdf
#**********************************************************
sub paysys_comepay {
  #my ($attr) = @_;

  paysys_load('Comepay');

  my $payment_system_id = 50;
  my $payment_system    = 'COMEPAY';

  my %info = ();

  if (defined($FORM{TRUE})) {
    paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{order}" });
    return 0;
  }
  else {
    if (! $FORM{PHONE}) {
      $user->pi({ UID => $LIST_PARAMS{UID} });
      $info{PHONE}=$user->{PHONE};
      $FORM{PHONE}=$user->{PHONE};
    }
    else {
      $info{PHONE}=$FORM{PHONE};
    }
  }

  $info{PAYSYS_URL}='https://shop.comepay.ru/Order/external/main.action';
  if ($info{PHONE} !~ /\d{10}/) {
    $info{PHONE_ERR} = $html->color_mark( $lang{ERR_WRONG_PHONE}, 'red' );
    $info{PAYSYS_URL}=$SELF_URL;
    $info{PARAMS} = "<input type=hidden name=index value=$index>
     <input type=hidden name=PAYMENT_SYSTEM value=$FORM{PAYMENT_SYSTEM}>
     <input type=hidden name=OPERATION_ID value=$FORM{OPERATION_ID}>
     <input type=hidden name=SUM value=$FORM{SUM}>
    ";
  }
  else {
    $info{TRANSACTION_ID} = comepay_mk_request({ %FORM });

    if ($info{TRANSACTION_ID} == 0) {
      $info{PAYSYS_URL}=$SELF_URL;

      $info{PARAMS} = "Error: $info{TRANSACTION_ID}
      $lang{ERR_TRANSACTION_DECLINED}
     <input type=hidden name=index value=$index>
     <input type=hidden name=PAYMENT_SYSTEM value=$FORM{PAYMENT_SYSTEM}>
     <input type=hidden name=OPERATION_ID value=$FORM{OPERATION_ID}>
     <input type=hidden name=SUM value=$FORM{SUM}>
    ";
    }
    else {
      $Paysys->add(
        {
          SYSTEM_ID      => $payment_system_id,
          DATETIME       => "$DATE $TIME",
          SUM            => $FORM{SUM},
          UID            => $LIST_PARAMS{UID},
          IP             => $FORM{IP},
          TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
          PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
          STATUS         => 1
        }
      );
    }
  }

  $html->tpl_show(_include('paysys_comepay_add', 'Paysys'), { %info, %$user });
}

#**********************************************************
#
#**********************************************************
sub paysys_evostok  {
  #my ($attr) = @_;

  my %info = (
    ACTION_URL => $conf{PAYSYS_EVOSTOK_URL}
  );

  my $message = '';

  if ($FORM{add}) {
    $conf{PAYSYS_EVOSTOK_PHONE_EXRP}='^79[0-9]{9}$' if (! $conf{PAYSYS_EVOSTOK_PHONE_EXRP});
    if($FORM{subno} !~  /$conf{PAYSYS_EVOSTOK_PHONE_EXRP}/) {
      $info{subno}=$FORM{subno};
      $message = $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_PHONE}" );
    }
    else {
      web_request("$conf{PAYSYS_EVOSTOK_URL}",
        {
          DEBUG    => 3,
          REQUEST_PARAMS => {
            subno => $FORM{subno},
            text  => $FORM{text}
          },
          CURL     => 1,
        });
      return $html->message( 'info', $lang{INFO}, "$lang{SENDED}" );
    }
  }

  my %SERVICE_HASH = %{ cfg2hash($conf{PAYSYS_EVOSTOK_TPL}) };

  $info{SERVICE_SEL}=$html->form_select(
    'text',
    {
      SELECTED => '',
      SEL_HASH => \%SERVICE_HASH,
      NO_ID    => 1,
      SORT_KEY => 1
    }
  );

  return $message . $html->tpl_show(_include('paysys_evostok_add', 'Paysys'), \%info);
}

#**********************************************************
=head2 paysys_stripe_report($attr)

=cut
#**********************************************************
sub paysys_stripe_report {
  #my ($attr) = @_;

  paysys_load('Stripe');
  Stripe->import();

  my $Stripe = Stripe->new($conf{PAYSYS_STRIPE_SECRET_KEY}, $conf{PAYSYS_STRIPE_PUBLISH_KEY});

  my @header_arr = (
    "$lang{PAYMENTS}:index=$index",
    "$lang{USERS}:index=$index&list=customers",
    "$lang{DEPOSIT}:index=$index&list=balance/history",
    "$lang{EVENTS}:index=$index&list=events",
    "Bitcoin:index=$index&list=bitcoin/receivers",
  );

  print $html->table_header(\@header_arr, { TABS => 1 });

  $Stripe->{debug}=1 if ($FORM{DEBUG});

  $Stripe->stripe_report({ REPORT => $FORM{list}, PAGE_ROWS => $LIST_PARAMS{PAGE_ROWS} });

  if ($Stripe->{errno}) {
    _error_show($Stripe);
  }

  result_former({
    TABLE => {
      width    => '100%',
      caption  => $FORM{list} || 'charges',
      #qs       => "&visual=$FORM{visual}&NAS_ID=$FORM{NAS_ID}&ONU=$FORM{ONU}",
      ID       => 'EQUIPMENT_ONU_PORTS',
    },
    DATAHASH    => ($Stripe->{result}) ? $Stripe->{result}->{data} : undef,
    TOTAL       => 1
  });

  return 1;
}


#**********************************************************
=head2 paysys_stripe($attr)

=cut
#**********************************************************
sub paysys_stripe {
  my ($attr) = @_;

  my $payment_system    = 'ST';
  my $payment_system_id = 102;

  paysys_load('Stripe');
  Stripe->import();

  my $Stripe = Stripe->new($conf{PAYSYS_STRIPE_SECRET_KEY}, $conf{PAYSYS_STRIPE_PUBLISH_KEY});
  $FORM{SYSTEM_SHORT_NAME}=$payment_system;

  if ($FORM{stripeToken}) {
    my $list  = $Paysys->list({
      TRANSACTION_ID =>  "$payment_system:$FORM{OPERATION_ID}",
      COLS_NAME      => 1,
      SUM            => '_SHOW',
      SKIP_DEL_CHECK => 1,
      SKIP_DOMAIN    => 1
    });

    if ($Paysys->{TOTAL}) {
      my $amount = $list->[0]->{sum}*100 || 0;
      $Stripe->stripe_create({
        AMOUNT      => $amount,
        CURRENCY    => $FORM{CURRENCY} || 'eur',
        SOURCE      => $FORM{stripeToken},
        DESCRIPTION => $FORM{DESCRIBE} || ''
      });

      if ($Stripe->{errno}) {
        $html->message( 'err', $lang{ERROR},
          "[$Stripe->{errno}] $Stripe->{errstr} \nID: $payment_system:$FORM{OPERATION_ID}" );
      }
      else {
        $Paysys->change({
          ID     => $list->[0]->{id},
          STATUS => 2,
          INFO   => "Token, $FORM{stripeToken}\nTP_ID, $FORM{TP_ID}\nID, $Stripe->{result}->{id}\nSTATUS, $Stripe->{result}->{status}\nAMOUNT, $Stripe->{result}->{amount}\n"
        });

        if ($user->{UID}) {
          paysys_show_result({ TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}" });
        }

        $FORM{PAYSYS_ID}= $list->[0]->{id};
        $FORM{TRUE}     = 1;
        $FORM{EMAIL}    = $FORM{stripeEmail};
        return 1;
      }
    }
    else {
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_NO_TRANSACTION}\n ID: $payment_system:$FORM{OPERATION_ID}" );
    }

    $FORM{FALSE}=1;
    return 0;
  }

  #Info section
  $Paysys->add({
    SYSTEM_ID      => $payment_system_id,
    SUM            => $FORM{SUM},
    UID            => $LIST_PARAMS{UID},
    IP             => $ENV{'REMOTE_ADDR'} || '0.0.0.0',
    PAYSYS_IP      => $ENV{'REMOTE_ADDR'} || '0.0.0.0',
    TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
    STATUS         => 1,
    DOMAIN_ID      => $user->{DOMAIN_ID} || $admin->{DOMAIN_ID}
  });

  my %info = (AMOUNT => $FORM{SUM} * 100);

  return $html->tpl_show(_include('paysys_stripe_add', 'Paysys'), \%info, $attr);
}

#**********************************************************
=head2 paysys_paykeeper()
=cut
#**********************************************************
sub paysys_paykeeper {
  paysys_load('Paykeeper');

  my %info = ();
  $info{ACTIONFORM} = "$conf{PAYSYS_PAYKEEPER_MODE}/create/";
  $user->pi({ UID => $user->{UID} });
  $info{CLIENTID} = $user->{FIO};
  $info{SUMMA}    = $FORM{SUM};
  $info{OID}      = $FORM{OPERATION_ID};
  # $info{PHONE}    = $user->{PHONE};
  $info{UID}      = $user->{UID};

  $html->tpl_show(_include('paysys_paykeeper_add', 'Paysys'), \%info);
}

#**********************************************************
=head2 paysys_kaznachey()

=cut
#**********************************************************
sub paysys_kaznachey {

  paysys_load('Kaznachey');

  # Список возможных платежных систем
  my %merchantInfo = Get_Merchant_Info($conf{PAYSYS_KAZNACHEY_GUID}, $conf{PAYSYY_KAZNACHEY_SECRET_KEY});

  my %createPaymentResponse;

  # условия создания запроса платежа
  if ($FORM{'action'} eq "create_payment") {

    #$user->pi({ UID => $user->{UID} });
    my %paymentDetails = (    #Детали платежа
      #Обязательные поля
      EMail                     => $user->{EMAIL},                                                                                                                                  #Емайл клиента
      PhoneNumber               => $user->{PHONE},                                                                                                                                  #Номер телефона клиента
      MerchantInternalPaymentId => $FORM{OID},                                                                                                                                      # Номер платежа в системе abills
      MerchantInternalUserId    => $user->{UID},                                                                                                                                    #Номер пользователя в системе abills
      #StatusUrl => "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi",
      StatusUrl                 => ($conf{PAYSYS_KAZNACHEY_CHECK_URL}) ? $conf{PAYSYS_KAZNACHEY_CHECK_URL} : "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi",
      ReturnUrl                 => "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi",                                                                                    #url возврата ползователя после платежа.
    );

    my @products = (
      {                                                                                                                                                                             # Список продуктов
        "ProductItemsNum" => "1",               # Колличество
        "ProductName"     => "Оплата",    # Наименование товара
        "ProductPrice"    => $FORM{SUM},        #Стоимость товара
        "ProductId"       => "1",               # Идентификатор товара из системы мерчанта. Необходим для аналити продаж
      }
    );

    my %request = (
      'SelectedPaySystemId' => $FORM{SelectedPaySystemId},
      'Currency'            => 'UAH',                        # Валюта  - UAH, RUB, EUR, USD
      'Language'            => 'RU',                         # Язык    - RU, EN
      'PaymentDetails'      => \%paymentDetails,             # Детали платежа
      'Products'            => \@products                    # Покупки
    );

    %createPaymentResponse = Create_Payment(%request);       # переменная ответа платежа
  }

  my %info = ();

  # Вставляем список систем в страничку шаблона
  if (%merchantInfo) {
    my $options    = 0;
    my @paySystems = $merchantInfo{'PaySystems'};

    foreach my $ps (@{ $paySystems[0] }) {
      if ($ps->{"Id"} == 1 && !$conf{PAYSYS_KAZNACHEY_TEST}) {
        next;
      }

      $options .= '<option value="' . $ps->{"Id"} . '">' . $ps->{"PaySystemName"} . '</option>';
      $info{PAYSYSTEMS} = $options;
    }
  }

  $info{SUMMA} = $FORM{SUM};    # передаем сумму продуктов на страничку

  # Ответ на запрос создания платежа
  if (%createPaymentResponse) {

    # Декодирование ответа
    $createPaymentResponse{"ExternalForm"} = decode_base64($createPaymentResponse{"ExternalForm"});

    # Переход на страницу оплаты
    print qq{
    <!DOCTYPE html>
    <html>
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    </head>
    <body>
      <br/>
      CreatePayment<br/>
      ErrorCode: $createPaymentResponse{"ErrorCode"} <br/>
      DebugMessage: $createPaymentResponse{"DebugMessage"} <br/>
      $createPaymentResponse{"ExternalForm"}
      <textarea rows="20" cols="100">$createPaymentResponse{"ExternalForm"}</textarea>
	</body>
    </html>};
  }

  # показать шаблон
  $html->tpl_show(_include('paysys_kaznachey_add', 'Paysys'), \%info);
}

#**********************************************************
# ROBOKASSA
#**********************************************************
sub paysys_robokassa {
  paysys_load('Robokassa');

  my %info = ();
  # подключение стандартного модуля для кодирования подписи
  # standard module for coding the signature
  load_pmodule('Digest::MD5');
  my $md5 = Digest::MD5->new();

  # регистрационная информация (логин, пароль #1)
  # registration info (login, password #1)
  my $mrh_login = $conf{PAYSYS_ROBOKASSA_MRCH_LOGIN};
  my $mrh_pass1 = $conf{PAYSYS_ROBOKASSA_PASSWORD_ONE};

  # номер заказа
  # number of order
  my $inv_id = $FORM{OPERATION_ID};

  # описание заказа
  # order description
  my $inv_desc = "PAYMENT";

  # сумма заказа
  # sum of order
  my $out_summ = $FORM{SUM};

  # тип товара
  # code of goods
  my $shp_Id = $user->{UID};

  # язык
  # language: en, ru
  my $culture = "ru";

  # кодировка
  # encoding
  my $encoding = "utf-8";

  # формирование подписи
  # generate signature
  #my $crc = md5_hex("$mrh_login:$out_summ:$inv_id:$mrh_pass1:shp_Id=$shp_Id");
  my $string = "$mrh_login:$out_summ:$inv_id:$mrh_pass1:shp_Id=$shp_Id";
  $md5->reset;
  $md5->add($string);
  my $signature_string = $md5->hexdigest();

  print "STRING = " . "$mrh_login:$out_summ:$inv_id:$mrh_pass1:shp_Id=$shp_Id";
  print " CRC = " . $string . " ";

  # включить тест мод
  my $testMode = ($conf{PAYSYS_ROBOKASSA_TEST_MODE}) ? $conf{PAYSYS_ROBOKASSA_TEST_MODE} : 0;

  # передаваемые данные в шаблон
  $info{SUMMA}       = $FORM{SUM};
  $info{LOGIN}       = $mrh_login;
  $info{SIGNTR}      = $signature_string;
  $info{SHP_ID}      = $shp_Id;
  $info{OID}         = $inv_id;
  $info{LANG}        = $culture;
  $info{CURR}        = "";
  $info{ENCODE}      = $encoding;
  $info{MODE}        = $testMode;
  $info{DESCRIPTION} = $inv_desc;

  # показать шаблон
  $html->tpl_show(_include('paysys_robokassa_add', 'Paysys'), \%info);
}

#**********************************************************
=head2 paysys_maps($attr)

=cut
#**********************************************************
sub paysys_maps {
  #  my ($attr) = @_;

  my %search_keys = (
    PAYSYS_PRIVAT_TERMINAL_ACCOUNT_KEY => 'Privatbank;privat;приват;Приватбанк:privat',
    PAYSYS_EASYPAY_SERVICE_ID          => 'easypay:easypay',
  );

  my %search_on_map = ();

  foreach my $key (keys %search_keys) {
    if ($conf{$key}) {
      $search_on_map{$key} = $search_keys{$key};
    }
  }

  load_module('Maps', $html);

  return maps_show_map(
    {
      QUICK             => 1,
      GET_LOCATION      => 1,
      ICON              => 'atm',
      PAYSYS            => 1,
      OBJECTS           => \%search_on_map,
      OUTPUT2RETURN     => 1,
      SMALL             => 1,
      GET_USER_POSITION => 1,
      CLIENT_MAP        => 1,
    }
  );

}

#**********************************************************
=head2 paysys_platon()
=cut
#**********************************************************
sub paysys_platon {
  paysys_load('Platon');

  load_pmodule('JSON');
  load_pmodule('Digest::MD5');
  my $md5 = Digest::MD5->new();

  #my $password = $conf{PAYSYS_PLATON_PASS};
  my %info = ();
  $info{PAY_URL} = $conf{PAYSYS_PLATON_URL};

  my $procent = $conf{PAYSYS_PLATON_COMMISSION} || 0;
  my $amount = $FORM{SUM} / ((100 - $procent)/100);
  my $commission = sprintf('%.2f',$amount - $FORM{SUM});
  my $ostatok = $amount - $commission;

  if(sprintf('%.3f',$ostatok) > sprintf('%.3f',$FORM{SUM})){
    $commission += 0.01;
    $amount     += 0.01;
  }

  my %product = (
    'amount'      => sprintf('%.2f',$amount),
    'currency'    => 'UAH',
    'description' => 'Payment'
  );


  my $json_product = JSON::to_json(\%product);


  my $base_product = encode_base64($json_product);
  $base_product =~ s/\n//g;


  $info{KEY}          = $conf{PAYSYS_PLATON_KEY};
  $info{PAYMENT}      = 'CC';
  $info{OID}          = $FORM{OPERATION_ID};
  $info{PRODUCT_DATA} = $base_product;
  $info{UID}          = $user->{UID};
  $info{URL_OK}       = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi";
  $info{COMMISSION}   = "$commission";
  $info{TOTAL}        = sprintf('%.2f',$amount);

  my $reverse_string = reverse($info{KEY}) . reverse($info{PAYMENT}) . reverse($base_product) . reverse($info{URL_OK}) . reverse($conf{PAYSYS_PLATON_PASS});


  my $uc_string = uc($reverse_string);


  $md5->reset;
  $md5->add($uc_string);

  my $md5_string = $md5->hexdigest();
  $info{SIGNATURE} = $md5_string;

  $html->tpl_show(_include('paysys_platon_add', 'Paysys'), \%info);
}

#**********************************************************
=head2 paysys_fondy() Fondy paysys

=cut
#**********************************************************
sub paysys_fondy {

  paysys_load('Fondy');
  my $payment_system    = 'Fondy';
  # Подключение модуля SHA1
  load_pmodule('Digest::SHA');
  my $sha1 = Digest::SHA->new;

  if ($FORM{TRUE} || $FORM{status}) {
    paysys_show_result({ TRANSACTION_ID => $FORM{order_id} || $FORM{OPERATION_ID} });
    return 0;
  }

  my $pass = $conf{PAYSYS_FONDY_PASSWORD};
  my %info = ();

  $info{Order_id}      = $FORM{OPERATION_ID};              # Номер транзакции в Abills
  $info{Merchant_id}   = $conf{PAYSYS_FONDY_MERCH_ID};    # ID, выданое при регистрации в Oplata
  $info{Order_desc}    = 'Оплата';                   # Описание заказа
  $info{Amount}        = $FORM{SUM} * 100;                 # Сумма
  $info{Sum}           = $FORM{SUM};
  $info{Currency}      = $conf{PAYSYS_FONDY_CURRENCY};    # Валюта
  $info{Merchant_data} = $user->{UID};                     # ID пользователя
  # Регулярные платежи
  $info{Checkbox}      = "<div class='form-group'>
						         <label class='control-label col-md-6 text-center'>$lang{REGULAR_PAYMENT}</label>
						         <input type='checkbox' name='do_token' value='on' class='col-md-1'>
					           </div>";

  # URL для ответа и URL для редиректа пользователя
  $info{Server_callback_url} = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi";
  $info{Response_url}        = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?TRUE=1&index=$index&OPERATION_ID=$payment_system:" . ($FORM{OPERATION_ID} || $FORM{order_id}) . "&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}";

  #$info{Server_callback_url} = "http://dev.abills.net.ua/paysys_check.cgi";

  # Строка для сигнатуры
  my $string_for_sign = $pass . '|';

  # Первый переход
  $FORM{Action}  = "$SELF_URL";
  $FORM{Confirm} = "$lang{PAY}";
  if ( $FORM{action} && $FORM{action} eq 'create_payment') {

    # Проверка на согласие абонента
    if ($FORM{do_token} && $FORM{do_token} eq 'on') {
      $FORM{Action}            = "https://api.fondy.eu/api/checkout/redirect/";
      $info{Amount}            = $FORM{amount};                                     # Сумма
      $info{Sum}               = sprintf('%.2f',$FORM{amount} / 100);
      $info{Order_id}          = $FORM{order_id};                                   # Айди транзакции
      $info{Merchant_id}       = $conf{PAYSYS_FONDY_MERCH_ID};                     # Айди мерчанта
      $info{Order_desc}        = 'Оплата';                                    # Описание заказа
      $info{Currency}          = $conf{PAYSYS_FONDY_CURRENCY};                     # Валюта
      $info{Merchant_data}     = $FORM{merchant_data};                              # ID пользователя
      $info{Required_rectoken} = 'Y';                                               # Токен карты
      $FORM{Confirm} = "$lang{CONFIRM_PAYMENT}";
      $info{Checkbox}          = "<div class='form-group'>
                           <label class='control-label col-md-6 text-center'>$lang{REGULAR_PAYMENT}</label>
                           <label class='control-label col-md-6'>Подключен</label>
                           </div>";
    }
    else {
      $FORM{Action}            = "https://api.fondy.eu/api/checkout/redirect/";
      $info{Amount}            = $FORM{amount};                                     # Сумма
      $info{Sum}               = sprintf('%.2f',$FORM{amount} / 100);
      $info{Order_id}          = $FORM{order_id};                                   # Айди транзакции
      $info{Merchant_id}       = $conf{PAYSYS_FONDY_MERCH_ID};                     # Айди мерчанта
      $info{Order_desc}        = 'Оплата';                                    # Описание заказа
      $info{Currency}          = $conf{PAYSYS_FONDY_CURRENCY};                     # Валюта
      $info{Merchant_data}     = $FORM{merchant_data};                              # ID пользователя
      $info{Required_rectoken} = 'N';                                               # Токен карты
      $FORM{Confirm} = "$lang{CONFIRM_PAYMENT}";
      $info{Checkbox}          = "";
    }
  }

  # Сортировка ключей в алфавитном порядке для сигнатуры
  foreach my $name (sort keys %info) {
    if ($name eq 'Checkbox' || $info{$name} eq '' || $name eq 'Sum') {
    }
    else {
      $string_for_sign = $string_for_sign . $info{$name} . '|';
    }
  }

  $string_for_sign = substr($string_for_sign, 0, -1);

  $sha1->add($string_for_sign);

  #Сигнатура
  my $signature = $sha1->hexdigest();

  $info{Signature} = $signature;

  $html->tpl_show(_include('paysys_fondy_add', 'Paysys'), \%info);

}

#**********************************************************
=head paysys_monthly($attr) - Month periodic payments

=cut
#**********************************************************
sub paysys_monthly {
  my ($attr) = @_;

  if ($FORM{TRUE} || $FORM{status}) {
    paysys_show_result({ TRANSACTION_ID => $FORM{order_id} || $FORM{OPERATION_ID} });
    return 0;
  }

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "DV: Monthly periodic payments\n" if ($debug > 1);

  $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
  my (undef, undef, $d)      = split(/-/, $ADMIN_REPORT{DATE}, 3);

  my $START_PERIOD_DAY = $conf{START_PERIOD_DAY} || 1;

  if ($d != $START_PERIOD_DAY) {
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  my $list = $Paysys->paysys_user_list(
    {
      PAYSYS_ID => '_SHOW',
      PAGE_ROWS => 100000,
      COLS_NAME => 1
    }
  );

  my %CONF_OPTIONS_REV = reverse %CONF_OPTIONS;

  foreach my $line (@$list) {
    print "$line->{uid}" if ($debug > 0);
    my $uid       = $line->{uid};
    my $token     = $line->{token};
    my $sum       = $line->{sum};
    my $paysys_id = $line->{paysys_id};

    if ($paysys_id == 109 && $conf{ $CONF_OPTIONS_REV{$paysys_id} }) {

      # Регулярная платеж для Oplata
      paysys_load('Oplata');
      $debug_output .= fondy_regular_pay($uid, $token, $sum, $paysys_id);
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}


#**********************************************************
=head2 paysys_walletone()

=cut
#**********************************************************
sub paysys_walletone {
  paysys_load('Walletone');
  my %info = ();
  $info{WMI_MERCHANT_ID}    = $conf{PAYSYS_WALLETONE_MERCH_ID};
  $info{WMI_PAYMENT_AMOUNT} = $FORM{SUM};
  $info{WMI_CURRENCY_ID}    = $conf{PAYSYS_WALLETONE_CURRENCY};
  $info{WMI_PAYMENT_NO}     = $FORM{OPERATION_ID};
  $info{WMI_DESCRIPTION}    = encode_base64('Оплата', '');
  $info{WMI_SUCCESS_URL}    = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?TRUE=1&index=$index&OPERATION_ID=OP:$FORM{OPERATION_ID}&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}";
  $info{WMI_FAIL_URL}       = "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi";
  $info{UID}                = $user->{UID};

  my $encription_key    = $conf{PAYSYS_WALLETONE_ENCRIPTION_KEY};
  my $encription_method = $conf{PAYSYS_WALLETONE_ENCRIPTION_METHOD};

  my $sign_string = "";
  my $signature   = "";

  for my $key (sort { lc($a) cmp lc($b) } keys %info) {
    $sign_string .= $info{$key};
  }

  $sign_string = $sign_string . $encription_key;

  if ($encription_method eq 'md5') {
    load_pmodule('Digest::MD5');
    $signature = Digest::MD5::md5_base64($sign_string) . '==';
  }
  elsif ($encription_method eq 'sha1') {
    load_pmodule('Digest::SHA1');
    $signature = Digest::SHA1::sha1_base64($sign_string) . '=';
  }

  $info{WMI_SIGNATURE} = $signature;

  $html->tpl_show(_include('paysys_walletone_add', 'Paysys'), \%info);
}

#**********************************************************
=head2 terminals_add() - Adding terminals with location ID

=cut
#**********************************************************
sub terminals_add {
  my %TERMINALS;

  $TERMINALS{ACTION} = 'add';      # action on page
  $TERMINALS{BTN} = "$lang{ADD}";    # button name

  # if we want to add new terminal
  if ($FORM{ACTION} && $FORM{ACTION} eq 'add') {
    $Paysys->terminal_add(
      {
        %FORM,
        TYPE        => $FORM{TERMINAL},
      }
    );
    if (!$Paysys->{errno}) {
      $html->message( 'success', $lang{ADDED}, "$lang{ADDED} $lang{TERMINAL}" );
    }
  }

  # if we want to change terminal
  elsif ($FORM{ACTION} && $FORM{ACTION} eq 'change') {
    $Paysys->terminal_change(
      {
        %FORM,
        TYPE        => $FORM{TERMINAL},
      }
    );
    if (!$Paysys->{errno}) {
      $html->message( 'success', $lang{CHANGED}, "$lang{CHANGED} $lang{TERMINAL}" );
    }
  }

  # get info about terminl into page
  if ($FORM{chg}) {
    my $terminal_info = $Paysys->terminal_info($FORM{chg});

    $TERMINALS{ACTION}      = 'change';
    $TERMINALS{COMMENT}     = $terminal_info->{COMMENT};
    $TERMINALS{TYPE}        = $terminal_info->{TYPE};
    $TERMINALS{BTN} = "$lang{CHANGE}";
    $TERMINALS{ID}          = $FORM{chg};
    $TERMINALS{STATUS}      = $terminal_info->{STATUS};
    $TERMINALS{DISTRICT_ID} = $terminal_info->{DISTRICT_ID};
    $TERMINALS{STREET_ID}   = $terminal_info->{STREET_ID};
    $TERMINALS{LOCATION_ID} = $terminal_info->{LOCATION_ID};
  }

  if ($FORM{del}) {
    $Paysys->terminal_del({ ID => $FORM{del} });
    if (!$Paysys->{errno}) {
      $html->message( 'success', $lang{DELETED}, "$lang{TERMINAL} $lang{DELETED}" );
    }
  }

  # terminal's type select
  # $TERMINALS{TERMINAL_TYPE} = $html->form_select(
  #   'TERMINAL',
  #   {
  #     SELECTED     => $TERMINALS{TYPE},
  #     SEL_ARRAY    => \@TERMINAL_TYPES,
  #     ARRAY_NUM_ID => 1,
  #     SEL_OPTIONS  => { '' => '--' },
  #   }
  # );

  $TERMINALS{TERMINAL_TYPE} = $html->form_select(
    'TERMINAL',
    {
      SELECTED => $TERMINALS{TYPE},
      SEL_LIST => $Paysys->terminal_type_list({ NAME => '_SHOW' }),
      SEL_KEY  => 'id',
      SEL_VALUE=> 'name',
      # ARRAY_NUM_ID => 1,
      NO_ID => 1,
      SEL_OPTIONS  => { '' => '--' },
      MAIN_MENU    => get_function_index('terminals_type_add'),
    }
  );

  $TERMINALS{STATUS} = $html->form_select(
    'STATUS',
    {
      SELECTED     => $TERMINALS{STATUS},
      SEL_ARRAY    => \@TERMINAL_STATUS,
      ARRAY_NUM_ID => 1,
      SEL_OPTIONS  => { '' => '--' },
      # MAIN_MENU    => get_function_index('terminals_type_add'),
    }
  );

  use Address;
  my $Address = Address->new($db, $admin, \%conf);
  my %user_pi = ();
  if ($TERMINALS{DISTRICT_ID}) {
    $user_pi{ADDRESS_DISTRICT} = ($Address->district_info({ ID => $TERMINALS{DISTRICT_ID} }))->{NAME};
  }

  if ($TERMINALS{STREET_ID}) {
    $user_pi{ADDRESS_STREET} = ($Address->street_info({ ID => $TERMINALS{STREET_ID} }))->{NAME};
  }

  if ($TERMINALS{LOCATION_ID}) {
    $user_pi{ADDRESS_BUILD} = ($Address->build_info({ ID => $TERMINALS{LOCATION_ID} }))->{NUMBER};
  }

  $TERMINALS{ADRESS_FORM} = $html->tpl_show(
    templates('form_address_search'),
    {
      %user_pi,
      DISTRICT_ID => $TERMINALS{DISTRICT_ID},
      STREET_ID   => $TERMINALS{STREET_ID},
      LOCATION_ID => $TERMINALS{LOCATION_ID},
    },
    { OUTPUT2RETURN => 1 }
  );

  $html->tpl_show(_include('paysys_terminals_add', 'Paysys'), \%TERMINALS);
  result_former(
    {
      INPUT_DATA      => $Paysys,
      FUNCTION        => 'terminal_list',
      DEFAULT_FIELDS  => 'ID, TYPE, COMMENT, STATUS, DIS_NAME, ST_NAME, BD_NUMBER',
      FUNCTION_FIELDS => 'change,del',
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        id        => '#',
        type      => $lang{TYPE},
        comment   => $lang{COMMENTS},
        status    => $lang{STATUS},
        dis_name  => $lang{DISTRICT},
        st_name   => $lang{STREET},
        bd_number => $lang{BUILD},
      },
      #SELECT_VALUE => {
      #  type => {
      #    0 => $TERMINAL_TYPES[0],
      #    1 => $TERMINAL_TYPES[1]
      #  },
      #  status => {
      #    0 => $TERMINAL_STATUS[0],
      #    1 => $TERMINAL_STATUS[1]
      #  },
      #},
      TABLE => {
        width   => '100%',
        caption => "$lang{TERMINALS}",
        qs      => $pages_qs,
        pages   => $Paysys->{TOTAL},
        ID      => 'PAYSYS_TERMINLS',
        MENU    => "$lang{ADD}:add_form=1&index=" . $index . ':add' . ";",
        EXPORT  => 1
      },
      MAKE_ROWS => 1,
      TOTAL     => 1
    }
  );

  return 1;
}

#**********************************************************
=head2 terminals_type_add() - add new terminal types

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub terminals_type_add {
  my ($attr) = @_;

  my %TERMINALS;

  $TERMINALS{ACTION} = 'add';      # action on page
  $TERMINALS{BTN}    = "$lang{ADD}";    # button name

  if($FORM{ACTION} && $FORM{ACTION} eq 'add'){
    $Paysys->terminals_type_add({%FORM});

    if(!$Paysys->{errno}){
      $html->message('info', $lang{ADDED}, $lang{SUCCESS});

      if($FORM{UPLOAD_FILE}){
        upload_file($FORM{UPLOAD_FILE}, { PREFIX    => '/terminals/',
            FILE_NAME => 'terminal_' . $Paysys->{INSERT_ID} . '.png', });
      }
    }
    else{
      $html->message('err', $lang{ERROR});
    }
  }
  elsif($FORM{ACTION} && $FORM{ACTION} eq 'change'){
    $Paysys->terminal_type_change({%FORM});

    if(!$Paysys->{errno}){
      $html->message('info', $lang{CHANGED}, $lang{SUCCESS});
      if($FORM{UPLOAD_FILE}){
        upload_file($FORM{UPLOAD_FILE}, { PREFIX    => '/terminals/',
            FILE_NAME => 'terminal_' . $FORM{ID} . '.png',
            REWRITE   => 1 });
      }
    }
    else{
      $html->message('err', $lang{ERROR});
    }
  }

  if($FORM{del}){
    $Paysys->terminal_type_delete({ID => $FORM{del}});

    if(!$Paysys->{errno}){
      $html->message('info', $lang{DELETED}, $lang{SUCCESS});
      my $filename = "$conf{TPL_DIR}/terminals/terminal_$FORM{del}.png";
      if( -f $filename){
        unlink("$filename") or die "Can't delete $filename:  $!\n";
      }
    }
    else{
      $html->message('err', $lang{ERROR});
    }
  }

  if($FORM{chg}){
    $TERMINALS{ACTION} = 'change';
    $TERMINALS{BTN}    = "$lang{CHANGE}";

    my $type_info = $Paysys->terminal_type_info( $FORM{chg} );

    $TERMINALS{COMMENT}  = $type_info->{COMMENT};
    $TERMINALS{NAME}     = $type_info->{NAME};
    $TERMINALS{ID}       = $FORM{chg}
  }

  $html->tpl_show(_include('paysys_terminals_type_add', 'Paysys'), \%TERMINALS);

  result_former(
    {
      INPUT_DATA      => $Paysys,
      FUNCTION        => 'terminal_type_list',
      DEFAULT_FIELDS  => 'ID, NAME, COMMENT',
      FUNCTION_FIELDS => 'change,del',
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        id        => '#',
        name      => $lang{NAME},
        comment   => $lang{COMMENTS},

      },
      #SELECT_VALUE => {
      #  type => {
      #    0 => $TERMINAL_TYPES[0],
      #    1 => $TERMINAL_TYPES[1]
      #  },
      #  status => {
      #    0 => $TERMINAL_STATUS[0],
      #    1 => $TERMINAL_STATUS[1]
      #  },
      #},
      TABLE => {
        width   => '100%',
        caption => "$lang{TERMINALS} $lang{TYPE}",
        qs      => $pages_qs,
        pages   => $Paysys->{TOTAL},
        ID      => 'PAYSYS_TERMINLS_TYPES',
        #MENU    => "$lang{ADD}:add_form=1&index=" . $index . ':add' . ";",
        EXPORT  => 1
      },
      MAKE_ROWS => 1,
      TOTAL     => 1
    }
  );

  return 1;
}



#**********************************************************
=head2 paysys_idram() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub paysys_idram {
  #my ($attr)=@_;
  #paysys_load('Idram');

  my $payment_system    = 'Idram';
  my $payment_system_id = 112;
  $FORM{DATETIME}       = "$DATE $TIME";

  if ($FORM{FALSE}) {
    $html->message( 'err', $lang{ERROR}, "$lang{FAILED} $lang{TRANSACTION}" );
    return 0;
  }
  if ($FORM{TRUE}) {
    $html->message( 'success', $lang{SUCCESS}, "$lang{SUCCESS} $lang{TRANSACTION}" );
    return 1;
  }

  #Info section
  $Paysys->add(
    {
      SYSTEM_ID      => $payment_system_id,
      DATETIME       => "$FORM{DATETIME}",
      SUM            => $FORM{SUM},
      UID            => $LIST_PARAMS{UID},
      IP             => "$ENV{'REMOTE_ADDR'}" || '0.0.0.0',
      TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
      PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
      STATUS         => 1,
      USER_INFO      => ''
    }
  );

  if ($Paysys->{errno}) {
    my $message = '';
    if ($Paysys->{errno} == 7) {
      $message = "\n$lang{EXIST}";
    }

    $html->message( 'err', "$lang{ERROR}", "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}'" . $message );

    return 0;
  }

  $FORM{LANGUAGE} = $conf{PAYSYS_IDRAM_LANGUAGE} || 'AM';
  $FORM{ACCOUNT}  = $conf{PAYSYS_IDRAM_ACCOUNT};
  $FORM{DESCRIBE} = 'Payment';
  $FORM{UID}      = $user->{UID};

  $html->tpl_show(_include('paysys_idram_add', 'Paysys'), {%FORM});
}

#**********************************************************

=head2 paysys_settings($attr) - pick a system for settings changing

  Arguments:


  Returns:

=cut

#**********************************************************
sub paysys_settings {
  my ($attr) = @_;

  my $pm_folder = "$base_dir" . 'Abills/modules/Paysys/';
  my @systems;

  if ($FORM{PAYMENT_SYSTEM}) {
    my $config = Conf->new($db, $admin, \%conf);
    my $module_name = $FORM{PAYMENT_SYSTEM};

    my $module;
    my $function;
    if ($FORM{PAYMENT_SYSTEM} =~ /\|/) {
      ($function, $module) = split('\|', $module_name);

      if ($module eq 'osmp_payments') {
        %PAYSYSTEM_CONF = (
          'PAYSYS_OSMP_ACCOUNT_KEY' => '',
          'PAYSYS_OSMP_EXT_PARAMS'  => ''
        );
        foreach my $conf_var (sort keys %PAYSYSTEM_CONF) {

          $config->config_add({ PARAM => $conf_var, VALUE => $FORM{$conf_var}, REPLACE => 1 });
        }

        $config->config_add({ PARAM => $module_name . "_IP", VALUE => $FORM{ $module_name . "_IP" }, REPLACE => 1 });
      }
      else {
        paysys_load("$module");

        foreach my $conf_var (sort keys %PAYSYSTEM_CONF) {

          $config->config_add({ PARAM => $conf_var, VALUE => $FORM{$conf_var}, REPLACE => 1 });
        }

        $config->config_add({ PARAM => $module_name . "_IP", VALUE => $FORM{ $module_name . "_IP" }, REPLACE => 1 });
      }
    }
    else {
      paysys_load($module_name);

      foreach my $conf_var (sort keys %PAYSYSTEM_CONF) {

        $config->config_add({ PARAM => $conf_var, VALUE => $FORM{$conf_var}, REPLACE => 1 });
      }

      $config->config_add({ PARAM => $module_name . "_IP", VALUE => $FORM{ $module_name . "_IP" }, REPLACE => 1 });
    }

  }

  opendir(my $folder, $pm_folder);
  while (my $filename = readdir $folder) {
    if ($filename =~ /pm$/ && $filename ne 'Paysys_Base.pm') {
      my ($name, $expansion) = split(/\.+/, $filename);
      push(@systems, $name);
    }
  }
  closedir $folder;

  if ($attr->{ONLY_SYSTEMS}) {
    my @connected_systems = ();
    foreach my $option (keys %CONF_OPTIONS) {

      if ($conf{$option}) {
        if (in_array($PAY_SYSTEMS{ $CONF_OPTIONS{$option} }, \@systems)) {
          # print "$PAY_SYSTEMS{$CONF_OPTIONS{$option}}\n";
          push(@connected_systems, $PAY_SYSTEMS{ $CONF_OPTIONS{$option} });
        }
      }
    }

    return @connected_systems;
  }

  if ($conf{PAYSYS_SUCCESSIONS}) {

    $conf{PAYSYS_SUCCESSIONS} =~ s/[\n\r]+//g;
    my @systems_arr = split(/;/, $conf{PAYSYS_SUCCESSIONS});

    foreach my $line (@systems_arr) {
      #my ($ips, $id, $full_name, $short_name, $function)
      my (undef, undef, $full_name, undef, $function) = split(/:/, $line);
      push(@systems, "$full_name|$function");
    }
  }

  my $paysys_select;
  foreach my $system (@systems) {

    my $paysys_logo_path = $base_dir . 'cgi-bin/styles/default_adm/img/paysys_logo/';
    my $file_path        = q{};

    my $paysys_name = $system;
    $paysys_name =~ s/ /_/g;

    if (-e "$paysys_logo_path" . lc($paysys_name) . "-logo.png") {
      $file_path = "/styles/default_adm/img/paysys_logo/" . lc($paysys_name) . "-logo.png";
    }
    else {
      $file_path = "http://abills.net.ua/wiki/lib/exe/fetch.php/abills:docs:modules:paysys:" . lc("$paysys_name") . "-logo.png";
    }

    $paysys_select .= $html->tpl_show(
      _include('paysys_system_select', 'Paysys'),
      {
        PAY_SYSTEM_LC   => $file_path,
        PAY_SYSTEM      => $system,
        PAY_SYSTEM_NAME => $system
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  $html->tpl_show(
    _include('paysys_settings', 'Paysys'),
    {
      PAY_SYSTEM_SEL => $paysys_select,
      index          => get_function_index('paysys_settings_change')
    }
  );

  return 1;
}

#**********************************************************

=head2 paysys_settings_change($attr) - input data for settings

  Arguments:


  Returns:

=cut

#**********************************************************
sub paysys_settings_change {

  my $config = Conf->new($db, $admin, \%conf);
  my $input = '';

  my $module_name;
  my $function;
  if ($FORM{PAYMENT_SYSTEM} =~ /\|/) {
    ($function, $module_name) = split('\|', $FORM{PAYMENT_SYSTEM});

  }
  else {
    $module_name = $FORM{PAYMENT_SYSTEM};
  }

  # my $module_name = $FORM{PAYMENT_SYSTEM};
  #our $PAYSYSTEM_NAME;
  #our $PAYSYSTEM_IP;
  #our $PAYSYSTEM_VERSION;
  if ($module_name eq 'osmp_payments') {
    %PAYSYSTEM_CONF = (
      'PAYSYS_OSMP_ACCOUNT_KEY' => '',
      'PAYSYS_OSMP_EXT_PARAMS'  => ''
    );

    foreach my $conf_var (sort keys %PAYSYSTEM_CONF) {
      my $description = $config->info({ ID => $conf_var });
      my $conf_value = $conf{$conf_var} ? $conf{$conf_var} : $PAYSYSTEM_CONF{$conf_var};
      my $variable = $config->config_info({ PARAM => $conf_var, DOMAIN_ID => 0 });
      $input .= $html->tpl_show(
        _include('paysys_settings_input', 'Paysys'),
        {
          SETTING_LABEL => $conf_var,
          SETTING_NAME  => $conf_var,
          SETTING_VALUE => $variable->{TOTAL} != 0 ? $variable->{VALUE} : $conf_value,
          DESCR         => $description->{COMMENTS}
        },
        { OUTPUT2RETURN => 1 }
      );
    }

    $html->tpl_show(
      _include('paysys_settings_change', 'Paysys'),
      {
        VERSION     => sprintf('%.2f', $PAYSYSTEM_VERSION || 0),
        INPUT       => $input,
        PAYSYS_NAME => $FORM{PAYMENT_SYSTEM},
        index       => get_function_index('paysys_settings')
      }
    );

    return 1;
  }
  else {
    paysys_load("$module_name");
  }

  if (!$PAYSYSTEM_NAME) {
    $html->message('warn', '', "Not defined \$PAYSYSTEM_NAME");
    return 1;
  }

  foreach my $conf_var (sort keys %PAYSYSTEM_CONF) {
    my $description = $config->info({ ID => $conf_var });
    my $conf_value = $conf{$conf_var} ? $conf{$conf_var} : $PAYSYSTEM_CONF{$conf_var};
    my $variable = $config->config_info({ PARAM => $conf_var, DOMAIN_ID => 0 });
    $input .= $html->tpl_show(
      _include('paysys_settings_input', 'Paysys'),
      {
        SETTING_LABEL => $conf_var,
        SETTING_NAME  => $conf_var,
        SETTING_VALUE => $variable->{TOTAL} != 0 ? $variable->{VALUE} : $conf_value,
        DESCR         => $description->{COMMENTS}
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  my $variable = $config->config_info({ PARAM => $PAYSYSTEM_NAME . "_IP", DOMAIN_ID => 0 });

  $input .= $html->tpl_show(
    _include('paysys_settings_input', 'Paysys'),
    {
      SETTING_LABEL => 'IP',
      SETTING_NAME  => $PAYSYSTEM_NAME . "_IP",
      SETTING_VALUE => $variable->{TOTAL} != 0 ? $variable->{VALUE} : $PAYSYSTEM_IP,
    },
    { OUTPUT2RETURN => 1 }
  );

  $html->tpl_show(
    _include('paysys_settings_change', 'Paysys'),
    {
      VERSION     => sprintf('%.2f', $PAYSYSTEM_VERSION),
      INPUT       => $input,
      PAYSYS_NAME => $FORM{PAYMENT_SYSTEM},
      index       => get_function_index('paysys_settings')
    }
  );

  return 1;
}

#**********************************************************
=head2 paysys_bss($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub paysys_bss {
  #my ($attr) = @_;

  #!!! Fixme
  #my $UNPAID_USERS = 0;
  my @STATUSES = ('', 'Оплачено', 'UID из стандартного платежа', 'UID совпадает с базой', 'UID не совпадает с базой и заменен', 'UID не найден');
  my $UNPAID_USERS;
  my %info = ();

  if($FORM{del_sum}){
    $Paysys->bss_sum_delete({ID => $FORM{del_sum}});
  }
  if($FORM{MAKE_PAYMENTS}){
    my $result = cmd('/usr/abills/Abills/modules/Paysys/paysys_cons TYPE=PAYMENTS EMAIL_CHECK=1 DEBUG=1 IMPORT_RULE=1 METHOD=113');
  }

  # import payments

  if ($FORM{IMPORT}) {
    my @IDS = split(', ', $FORM{IDS});
    foreach my $id (@IDS) {
      my $us = $users->info($FORM{"UID_$id"});
      $Payments->add(
        $us,
        {
          SUM          => $FORM{"SUM_$id"},
          DESCRIBE     => "Услуги связи от " . $FORM{"FIO_$id"} . ". Лицевой счет " . $FORM{"UID_$id"} . ". По адресу " . $FORM{"ADDRESS_$id"},
          DATE         => $FORM{"DATE_$id"},
          METHOD       => 113,
          EXT_ID       => $FORM{"EXT_ID_$id"},
          CHECK_EXT_ID => $FORM{"EXT_ID_$id"}
        }
      );

      if (!$Payments->{errno}) {
        $Paysys->bss_change({ ID => $id, STATUS => 1, UID => $FORM{"UID_$id"} });

        # add sum to bss_sum table
        my $date_info = $Paysys->bss_sum_list({COLS_NAME => 1, DATE => $FORM{"DATE_$id"}});
        my $new_nstd_sum = $date_info->[0]->{local_nstd_sum} + $FORM{"SUM_$id"};
        my $new_nstd_count = $date_info->[0]->{nstd_count} + 1;
        $Paysys->bss_sum_change({DATE => $FORM{"DATE_$id"}, LOCAL_NSTD_SUM => $new_nstd_sum, NSTD_COUNT => $new_nstd_count});
      }
      else {
        $html->message( 'err', "$lang{ERROR} $Payments->{errno}", "$status[$Payments->{errno}]" );
      }
    }
  }

  # delete from bss_log
  if ($FORM{DELETE} && $FORM{CONFIRM} == 1) {
    my @IDS = split(', ', $FORM{IDS});
    foreach my $id (@IDS) {
      $Paysys->bss_delete({ ID => $id });

      if (!$Paysys->{errno}) {
        my $ext_id = $FORM{"EXT_ID_$id"} || '';
        $html->message( "success", "ID $id $lang{DELETED}", "$lang{SUCCESS} $ext_id" );
      }
      else {
        $html->message( "err", "$id $lang{NOT} $lang{DELETED}" );
      }
    }
  }

  # select for statuses
  my $status_sel = $html->form_select(
    'STATUS',
    {
      SELECTED     => $FORM{STATUS},
      SEL_ARRAY    => \@STATUSES,
      ARRAY_NUM_ID => 1,
    }
  );

  my @rows = ();
  push @rows, "$lang{FROM}: " . $html->date_fld2( 'DATE_FROM', { MONTHES => \@MONTHES, WEEK_DAYS => \@WEEKDAYS } ),
    "$lang{TO}: " . $html->date_fld2( 'DATE_TO', { MONTHES => \@MONTHES, WEEK_DAYS => \@WEEKDAYS } ), $status_sel,
    $html->form_input( 'show', $lang{SHOW}, { TYPE => 'submit', OUTPUT2RETURN => 1 } );

  foreach my $val (@rows) {
    $info{ROWS} .= ' ' . $html->element('div', $val, { class => 'form-group' });
  }

  my $report_form = $html->element('div', $info{ROWS}, { class => 'navbar navbar-default form-inline' });

  my $payments_list;
  if($FORM{DATE_FROM} && $FORM{DATE_TO}){
    $payments_list = $Paysys->bss_list({ COLS_NAME => 1,
      PAGE_ROWS => 9999,
      SORT      => 1,
      DESC      => 'DESC',
      %FORM });
  }
  else{
    use Abills::Base qw(days_in_month);
    $DATE =~ s/\d+$/01/;
    my $start_date = $DATE;
    my $days_in_month = days_in_month();
    $DATE =~ s/\d+$/$days_in_month/;
    my $end_date = $DATE;
    $payments_list = $Paysys->bss_list({  COLS_NAME => 1,
      PAGE_ROWS => 9999,
      SORT      => 1,
      DESC      => 'DESC',
      DATE_FROM => $start_date,
      DATE_TO   => $end_date,
    });
  }
  #my $payments_list = $Paysys->bss_list({ COLS_NAME => 1, SORT => 1, DESC => 'DESC', %FORM });

  # create bss table html
  my $bss_table = $html->table(
    {
      width      => '100%',
      caption    => "BSS",
      cols_align => [ 'right', 'right', 'right', 'right' ],
      title      =>
      [ "#", "UID", "$lang{USER}", "$lang{ADDRESS}", "$lang{COMMENTS}", "$lang{DATE}", "$lang{SUM}", "EXT ID",
        "$lang{STATUS}" ],
    }
  );

  # filling bss table with imported & not imported payments
  foreach my $user_payment (@$payments_list) {
    my ($street_build) = $user_payment->{address} =~ /(.+), .+/;
    if ($user_payment->{status} != 1) {
      if ($user_payment->{status} == 2) { $bss_table->{rowcolor} = 'info'; }
      if ($user_payment->{status} == 3) { $bss_table->{rowcolor} = 'primary'; }
      if ($user_payment->{status} == 4) { $bss_table->{rowcolor} = 'warning'; }
      if ($user_payment->{status} == 5) { $bss_table->{rowcolor} = 'danger'; }
      $bss_table->addrow(
        $html->form_input('IDS', $user_payment->{id}, { TYPE => 'checkbox' }) . $html->br() . $user_payment->{id} . $html->form_input("SUM_$user_payment->{id}", $user_payment->{sum}, { TYPE => 'hidden' }) .    # hidden sum
          $html->form_input("FIO_$user_payment->{id}",     $user_payment->{fio},     { TYPE => 'hidden' }) .                                                                                                      # hidden fio
          $html->form_input("DATE_$user_payment->{id}",     $user_payment->{date},     { TYPE => 'hidden' }) .                                                                                                      # hidden fio
          $html->form_input("ADDRESS_$user_payment->{id}", $user_payment->{address}, { TYPE => 'hidden' }) .                                                                                                      # hidden fio
          $html->form_input("EXT_ID_$user_payment->{id}",  $user_payment->{ext_id},  { TYPE => 'hidden' }),                                                                                                       # hiden ext_id
        $html->form_input("UID_$user_payment->{id}", $user_payment->{uid}, { TYPE => 'text', class => 'form-control' }) . $user_payment->{id},
        $html->button("$user_payment->{fio}", "index=7&type=10&search=1&LOGIN=$street_build", { class => 'btn btn-primary btn-xs', target => '_blank'}),
        $user_payment->{address},
        $user_payment->{description},
        $user_payment->{date},
        $user_payment->{sum},
        $user_payment->{ext_id},
        $STATUSES[ $user_payment->{status} ]
      );
      $UNPAID_USERS++;
    }
    else {
      $bss_table->{rowcolor} = 'success';
      $bss_table->addrow(
        $html->form_input('IDS', $user_payment->{id}, { TYPE => 'checkbox' }) . $user_payment->{id},
        $html->button("$user_payment->{uid}", "index=15&UID=$user_payment->{uid}", { class => 'btn btn-primary btn-xs' }),
        "$user_payment->{fio}",
        $user_payment->{address},
        $user_payment->{description},
        $user_payment->{date}, $user_payment->{sum},
        $user_payment->{ext_id},
        $STATUSES[ $user_payment->{status} ]
      );
    }
  }

  # get sums per day from bss sum table
  my $days_sum;
  if($FORM{DATE_FROM} && $FORM{DATE_TO}){
    $days_sum = $Paysys->bss_sum_list({COLS_NAME => 1,
      DATE_FROM => $FORM{DATE_FROM},
      DATE_TO => $FORM{DATE_TO},
      SORT=>'date',
      DESC=>'desc',
      PAGE_ROWS => 9999});
  }
  else{
    use Abills::Base qw(days_in_month);
    $DATE =~ s/\d+$/01/;
    my $start_date = $DATE;
    my $days_in_month = days_in_month();
    $DATE =~ s/\d+$/$days_in_month/;
    my $end_date = $DATE;

    $days_sum = $Paysys->bss_sum_list({COLS_NAME => 1,
      DATE_FROM => $start_date,
      DATE_TO => $end_date,
      SORT=>'date',
      DESC=>'desc',
      PAGE_ROWS => 9999});
  }

  # bss sum table
  my $report_sums = $html->table(
    {
      width      => '100%',
      caption    => "REPORT",
      cols_align => [ 'center', 'center', 'center', 'center' ],
      title      =>
      [ "$lang{DATE}", "$lang{STANDART_PAYMENTS}" . "($lang{BANK})", "$lang{STANDART_PAYMENTS}" . "($lang{IMPORT})",
        "$lang{NSTANDART_PAYMENTS}" . "($lang{BANK})", "$lang{NSTANDART_PAYMENTS}" . "($lang{IMPORT})", "$lang{STANDART_COUNT} ", "$lang{NSTANDART_COUNT}" ],
    }
  );

  # filling bss sum table with data
  my $bank_std_month = 0;
  my $bank_nstd_month = 0;
  my $local_std_month = 0;
  my $local_nstd_month = 0;
  my $std_count = 0;
  my $nstd_count = 0;
  foreach my $day (@$days_sum){
    $report_sums->addrow($day->{date},
      $day->{bank_std_sum},
      $day->{local_std_sum},
      $day->{bank_nstd_sum},
      $day->{local_nstd_sum},
      $day->{std_count},
      $day->{nstd_count},
      $html->button($lang{DEL}, "index=$index&del_sum=$day->{id}", { MESSAGE => "$lang{DEL} $day->{date}?", class => 'del' }));

    $bank_std_month   += $day->{bank_std_sum};
    $bank_nstd_month  += $day->{bank_nstd_sum};
    $local_std_month  += $day->{local_std_sum};
    $local_nstd_month += $day->{local_nstd_sum};
    $std_count        += $day->{std_count};
    $nstd_count       += $day->{nstd_count};
  }

  $report_sums->addrow( "$lang{MONTH}", $bank_std_month, $local_std_month, $bank_nstd_month, $local_nstd_month, $std_count, $nstd_count, '');

  load_pmodule('Net::POP3');

  # Constructors
  my @mailboxes = split(/;/, $conf{PAYSYS_EMAIL_CHECK});
  my %read_messages_from_mail_btn = ();
  foreach my $mailbox (@mailboxes) {
    my ($host, $username, $password) = split(/:/, $mailbox, 3);

    my $pop = Net::POP3->new($host, Timeout => 60);
    if (!$pop) {
      print "POP3 Error: Can't connect '$host' $!\n";
      exit;
    }

    if ($pop->login($username, $password)) {
      my $msgnums = $pop->list;       # hashref of msgnum => size
      my $total = keys %$msgnums;
      if($total > 0){
        $read_messages_from_mail_btn{MAKE_PAYMENTS} = $lang{RUN_PAYSYS_CONS};
      }
    }
  }



  #if($UNPAID_USERS > 0){
  #  use Events;
  #  my $Event = Events->new($db, $admin, \%conf);
  #  $Event->events_add({MODULE=>"Paysys", COMMENTS=>"Есть $UNPAID_USERS неоплаченых пользователей"});
  #}
  print $html->form_main(
    {
      CONTENT =>
      $report_form . $bss_table->show() . $html->form_input( "CONFIRM", 1, { TYPE => 'checkbox' } ) . "$lang{DEL}",
      HIDDEN  => {
        index       => "$index",
        OP_SID      => $op_sid,
        IMPORT_TYPE => $FORM{IMPORT_TYPE},
      },
      SUBMIT  => { IMPORT => "$lang{IMPORT}", DELETE => "$lang{DEL}", %read_messages_from_mail_btn},
      NAME    => 'FORM_IMPORT'
    }
  );

  if(!$admin->{MAX_ROWS}){
    print $report_sums->show();
  }

  # print $report_sums->show();

  return 1;
}


#**********************************************************
=head2 external_commands() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub paysys_external_commands {
  #my ($attr) = @_;

  my $action      = 'change';
  my $action_lang = "$lang{CHANGE}";
  my %EXTERNAL_COMMANDS_SETTINGS;
  my $Config      = Conf->new($db, $admin, \%conf);

  my @conf_params  = ('PAYSYS_EXTERNAL_START_COMMAND', 'PAYSYS_EXTERNAL_END_COMMAND',
    'PAYSYS_EXTERNAL_ATTEMPTS',       'PAYSYS_EXTERNAL_TIME');

  if($FORM{change}){
    foreach my $conf_param (@conf_params){
      $Config->config_add({ PARAM => $conf_param, VALUE => $FORM{$conf_param}, REPLACE => 1 });
    }
  }

  foreach my $conf_param (@conf_params){
    my $param_information = $Config->config_info({PARAM => $conf_param, DOMAIN_ID => 0});

    $EXTERNAL_COMMANDS_SETTINGS{$conf_param} = $param_information->{VALUE};
  }

  $html->tpl_show(_include('paysys_external_commands', 'Paysys'), {
      ACTION => $action,
      ACTION_LANG => $action_lang,
      %EXTERNAL_COMMANDS_SETTINGS
    }, {SKIP_VARS => 'IP UID'});

  return 1;
}

#**********************************************************
=head2 paysys_privat_fastpay() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub paysys_privat_fastpay {

  if($conf{PAYSYS_PRIVAT_TERMINAL_ACCOUNT_KEY} eq 'CONTRACT_ID' && !$user->{CONTRACT_ID}){
    $user->pi();
  }

  Abills::Base::load_pmodule('Imager::QRCode');

  # Create Imager::QRCode instance
  my $qr = Imager::QRCode->new(
    size          => 8,
    margin        => 1,
    version       => 1,
    level         => 'M',
    casesensitive => 1,
    lightcolor    => Imager::Color->new(255, 255, 255),
    darkcolor     => Imager::Color->new(0, 0, 0),
  );

  # Create image from data
  my $img = $qr->plot("EK_billidentifier_$user->{$conf{PAYSYS_PRIVAT_TERMINAL_ACCOUNT_KEY}}_$conf{PAYSYS_PRIVAT_TERMINAL_QR_ID}");

  # Save image to scalar
  my $result = '';
  # MAYBE:: write errstr to $result?
  $img->write( data => \$result, type => 'jpeg' ) or print $img->errstr;

  # making blob image for template
  my $base64_result = Abills::Base::encode_base64($result);
  my $img_src_data = "data:image/jpg;base64, $base64_result";

  my $link = $conf{PAYSYS_PRIVAT_TERMINAL_FAST_PAY} . "&acc=" . ($user->{$conf{PAYSYS_PRIVAT_TERMINAL_ACCOUNT_KEY}} || $FORM{$conf{PAYSYS_PRIVAT_TERMINAL_ACCOUNT_KEY}}) . "&amount=" . ($FORM{SUM} || 0);

  $html->tpl_show(_include('paysys_privat_terminal_fastpay', 'Paysys'), {LINK => $link, IMG_DATA => $img_src_data});

}

#**********************************************************
=head2 paysys_mixplat() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub paysys_mixplat {
  my %info;

  my $user_info = $user->pi({UID => $user->{UID}});
  $info{PHONE}      = $user_info->{PHONE};
  $info{SERVICE_ID} = $conf{PAYSYS_MIXPLAT_SECRET_KEY};
  $info{TEST}       = $conf{PAYSYS_MIXPLAT_TEST} || 0;

  load_pmodule('Digest::MD5');
  my $md5 = Digest::MD5->new();

  # Подпись запроса. Алгоритм генерации подписи:
  # md5(REQUEST_URL + ’?’ + PARAMS + SECRET_KEY), где:
  # Пример рассчёта подписи:
  # md5('/api/mc.init?service_id=999&test=1&merchant_order_id=1380722287.98895.29911:100&amount=100&phone=79991230000&description=Оплата товара&currency=RUB&success_message=Товар успешно оплаченF3DS9481GD8F942D')

  my $string = "/api/mc.init?phone=$info{PHONE}&amount=$FORM{SUM}&merchant_order_id=$FORM{OPERATION_ID}&test=$info{TEST}&service_id=$info{SERVICE_ID}&currency=$info{CURRENCY}$conf{PAYSYS_MIXPLAT_SECRET_KEY}";
  $md5->reset;
  $md5->add($string);
  my $signature_string = $md5->hexdigest();

  $info{SIGNATURE}  = $signature_string;

  $html->tpl_show(_include('paysys_mixplat_add', 'Paysys'), {%info});

}

#**********************************************************
=head2 paysys_yandex_kassa() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub paysys_yandex_kassa{
  my ($attr) = @_;
  my %info;

  my $payment_system    = 'YK';
  my $payment_system_id = 117;

  if ($FORM{CONFIRM_PAYMENT} && $FORM{CONFIRM_PAYMENT} == 1) {
    $html->message( 'success', $lang{SUCCESS}, "$lang{SUCCESS} $lang{TRANSACTION}" );
    return 1;
  }

  if ($FORM{FAIL_PAYMENT} && $FORM{FAIL_PAYMENT} == 1) {
    $html->message( 'err', $lang{ERROR}, "$lang{ERROR} $lang{TRANSACTION}" );
    return 0;
  }

  if($FORM{TRUE}){
    my $transaction_result = paysys_show_result({ %FORM, TRANSACTION_ID => $payment_system.':'.$FORM{OPERATION_ID} });
    return $transaction_result;
  }

  my $account_key = $conf{PAYSYS_YANDEX_KASSA_ACCOUNT_KEY};
  $info{SCID}     = $conf{PAYSYS_YANDEX_KASSA_SCID};
  $info{SHOP_ID}  = $conf{PAYSYS_YANDEX_KASSA_SHOP_ID};
  $info{CUSTOMER} = $user->{$account_key} || $FORM{$account_key};
  $info{YANDEX_ACTION} = $conf{PAYSYS_YANDEX_KASSA_TEST} ? 'https://demomoney.yandex.ru/eshop.xml' : 'https://money.yandex.ru/eshop.xml';
  $info{REGISTRATION_ONLY} = $attr->{REGISTRATION_ONLY} || 0;

  # use Abills::Base qw(_bp);
  # _bp("User", { %$user{'UID', 'LOGIN', 'CONTRACT_ID'}  }, {TO_WEB_CONSOLE => 1, HEADER=> 1});

  # $info{CUSTOMER} = '';

  $Paysys->add({
    SYSTEM_ID      => $payment_system_id,
    SUM            => $FORM{SUM},
    UID            => $user->{UID} || $FORM{UID},
    IP             => "$ENV{'REMOTE_ADDR'}",
    TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
    STATUS         => 1,
    DOMAIN_ID      => $user->{DOMAIN_ID}
  });

  if ($Paysys->{errno}) {
    $html->message( 'err', "$lang{ERROR}", "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}'" );
    return 0;
  }

  return $html->tpl_show(_include('paysys_yandex_kassa_add', 'Paysys'), {%info}, { OUTPUT2RETURN => $attr->{OUTPUT2RETURN} });
}

#**********************************************************
=head2 paysys_tyme_reports() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub paysys_tyme_reports {
  #my ($attr) = @_;

  my %info;

  if($FORM{del}){
    $Paysys->del_tyme_report({ID => $FORM{del}})
  }


  my $terminal_list = $Paysys->terminal_list({ COMMENT      => '_SHOW',
    ST_NAME      => '_SHOW',
    ADDRESS_FULL => '_SHOW',
    LOCATION_ID  => '_SHOW',
    COLS_NAME   => 1, });

  foreach my $index (0 .. scalar(@{$terminal_list})) {
    if($terminal_list->[$index]->{comment} =~ /^\d+$/){
      next;
    }
    delete $terminal_list->[$index];
  }

  $info{TERMINAL_SELECT} = $html->form_select(
    'TERMINAL_SELECT',
    {
      SELECTED => $FORM{TERMINAL_SELECT},
      #SEL_LIST => $Paysys->terminal_list({ COMMENT      => '_SHOW',
      #                                     ST_NAME      => '_SHOW',
      #                                     ADDRESS_FULL => '_SHOW',
      #                                     LOCATION_ID  => '_SHOW' }),
      SEL_LIST => $terminal_list,
      SEL_KEY  => 'comment',
      SEL_VALUE=> 'address_full',
      # ARRAY_NUM_ID => 1,
      NO_ID => 1,
      SEL_OPTIONS  => { '' => '--' },
    }
  );

  if(!$FORM{DATE_START} && !$FORM{DATE_END}){
    use Abills::Base qw(days_in_month);
    $DATE =~ s/\d+$/01/;
    $FORM{DATE_START} = $DATE;
    my $days_in_month = days_in_month();
    $DATE =~ s/\d+$/$days_in_month/;
    $FORM{DATE_END} = $DATE;
  }

  $LIST_PARAMS{TERMINAL}  = $FORM{TERMINAL_SELECT} if $FORM{TERMINAL_SELECT};
  $LIST_PARAMS{DATE_FROM} = $FORM{DATE_START}      if $FORM{DATE_START};
  $LIST_PARAMS{DATE_TO}   = $FORM{DATE_END}        if $FORM{DATE_END};
  $LIST_PARAMS{SORT}      = $FORM{SORT} ? $FORM{SORT} : 5;
  $LIST_PARAMS{PAGE_ROWS} = $FORM{PAGE_ROWS} ? $FORM{PAGE_ROWS} : 500;

  $html->tpl_show(_include('paysys_tyme_report', 'Paysys'), {%info});

  my ($tyme_table, $tyme_list) = result_former(
    {
      INPUT_DATA      => $Paysys,
      FUNCTION        => 'list_tyme_report',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => 'ID, LOGIN, FIO, TXN_ID, DATE, SUM, TERMINAL_LOCATION',
      FUNCTION_FIELDS => 'del',
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        id       => '#',
        login    => $lang{USER},
        fio      => $lang{FIO},
        txn_id   => $lang{TRANSACTION},
        date     => $lang{DATE},
        sum      => $lang{SUM},
        #terminal => $lang{TERMINALS},
        terminal_location => "$lang{TERMINALS} $lang{ADDRESS}"
      },
      #SELECT_VALUE => {
      #  type => {
      #    0 => $TERMINAL_TYPES[0],
      #    1 => $TERMINAL_TYPES[1]
      #  },
      #  status => {
      #    0 => $TERMINAL_STATUS[0],
      #    1 => $TERMINAL_STATUS[1]
      #  },
      #},
      TABLE => {
        width   => '100%',
        caption => "Tyme Report",
        # qs      => $pages_qs,
        #pages   => $Paysys->{TOTAL},
        ID      => 'TYME_REPORT',
        #MENU    => "$lang{ADD}:add_form=1&index=" . $index . ':add' . ";",
        EXPORT  => 1
      },
      MAKE_ROWS => 1,
      TOTAL     => 1,
      SKIP_USER_TITLE => 1
    }
  );

  my $sum = 0.00;

  foreach my $payment (@$tyme_list){
    $sum += $payment->{sum};
  }

  my @rows  = [ "$lang{SUM}:", $html->b($sum) ];
  if($conf{PAYSYS_TYME_COMMISSION}){
    push @rows, [ "$lang{COMMISSION}",  $html->b($sum * $conf{PAYSYS_TYME_COMMISSION})];
  }

  my $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right' ],
      rows       => \@rows
    }
  );
  if(!$admin->{MAX_ROWS}){
    print $table->show();
  }
  return 1;
}

#**********************************************************
=head2 paysys_easysoft_fastpay() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub paysys_easypay_fastpay {
  #my ($attr) = @_;

  my $link = $conf{PAYSYS_EASYPAY_FASTPAY} . "?account=$user->{$conf{PAYSYS_EASYPAY_ACCOUNT_KEY}}&amount=$FORM{SUM}";

  $html->tpl_show(_include('paysys_easypay_fastpay', 'Paysys'), {LINK => $link});

  return 1;
}

#**********************************************************
=head2 paysys_tinkoff() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub paysys_tinkoff {
  #my ($attr) = @_;

  if ($FORM{Init}) {
    my $payment_system_id = 120;
    my $payment_system    = 'Tinkoff';

    $Paysys->add(
      {
        SYSTEM_ID      => $payment_system_id,
        SUM            => $FORM{SUM},
        UID            => $user->{UID} || $FORM{UID},
        IP             => "$ENV{'REMOTE_ADDR'}",
        TRANSACTION_ID => "$payment_system:$FORM{OPERATION_ID}",
        STATUS         => 1,
        DOMAIN_ID      => $user->{DOMAIN_ID}
      }
    );

    if ($Paysys->{errno}) {
      $html->message( 'err', "$lang{ERROR}", "$lang{ERROR} Paysys ID: '$FORM{OPERATION_ID}'" );
      return 0;
    }

    load_pmodule('Digest::SHA');

    my $data = "Email=" . Abills::Base::urlencode($conf{ADMIN_MAIL});

    # `echo "$data" >> /tmp/buffer`;

    my %token_hash = (
      'TerminalKey' => $conf{PAYSYS_TINKOFF_TERMINAL_KEY},
      'Amount'      => ($FORM{SUM} * 100),
      'OrderId'     => $FORM{OPERATION_ID},
      'DATA'        => $data,
      'CustomerKey' => $user->{UID},
      'Password'    => $conf{PAYSYS_TINKOFF_SECRET_KEY},
    );

    my $token             = '';
    my $sort_token_string = '';
    for my $key (sort keys %token_hash) {
      $sort_token_string .= "$token_hash{$key}";
    }

    $token = Digest::SHA::sha256_hex($sort_token_string);

    # `echo "$sort_token_string" >> /tmp/buffer`;
    # `echo "$token" >> /tmp/buffer`;

    my $init_url = 'https://securepay.tinkoff.ru/rest/Init?';
    $init_url .= 'TerminalKey=' . $conf{PAYSYS_TINKOFF_TERMINAL_KEY};
    $init_url .= '&Amount=' . ($FORM{SUM} * 100);
    $init_url .= '&OrderId=' . $FORM{OPERATION_ID};
    $init_url .= '&Token=' . $token;
    $init_url .= '&DATA= ' . $data;

    my $tinkoff_init_result = web_request(
      "$init_url",
      {
        CURL => 1,

        # POST        => 1,
        JSON_RETURN => 1
      }
    );

    # use Abills::Base;
    # _bp("init_url", $tinkoff_init_result, {HEADER=>1});

    if($tinkoff_init_result->{ErrorCode} == 0){
      my $redirect_url = $tinkoff_init_result->{PaymentURL};
      $html->redirect($redirect_url);
      exit 0;
    }
  }

  $html->tpl_show(_include('paysys_tinkoff_add', 'Paysys'), {});

  return 1;
}

#**********************************************************
=head2 paysys_cloudpayments() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub paysys_cloudpayments {

  if($FORM{TRUE}){
    paysys_show_result({  %FORM, TRANSACTION_ID => $FORM{OPERATION_ID} });
    return 1;
  }

  $html->tpl_show(_include('paysys_cloudpayments_add', 'Paysys'), {
      SUM         => $FORM{SUM},
      USER_ID     => $user->{UID},
      FIO         => $user->{FIO},
      TRANSACTION => $FORM{OPERATION_ID},
      SUCCESS_URL => "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?TRUE=1&index=$index&OPERATION_ID=Cloudpayments:$FORM{OPERATION_ID}&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}",
    });

  print "HELP - ";

  return 1;
}

#**********************************************************
=head2 paysys_paymaster_ru() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub paysys_paymaster_ru {

  if ($FORM{FALSE}) {
    paysys_show_result({ TRANSACTION_ID => "$FORM{LMI_PAYMENT_NO}", FALSE => 1 });
    return 1;
  }
  elsif ($FORM{TRUE}) {
    paysys_show_result({ TRANSACTION_ID =>  "PM_RU:$FORM{LMI_PAYMENT_NO}" });
    return 0;
  }

  my %INFO;
  $INFO{ORDER_ID} = $FORM{OPERATION_ID};
  $INFO{SUM}      = $FORM{SUM};

  $INFO{LMI_MERCHANT_ID} = $conf{PAYSYS_PAYMASTERRU_MERCHANT_ID};
  $INFO{CURRENCY}        = $conf{PAYSYS_PAYMASTERRU_CURRENCY} || 'RUB';
  $INFO{USER}            = $user->{$conf{PAYSYS_PAYMASTERRU_ACCOUNT_KEY}};
  $INFO{NOTIFICATION_URL} = $ENV{PROT}.'://'. $ENV{SERVER_NAME}.':'. $ENV{SERVER_PORT} . '/paysys_check.cgi';
  $INFO{FAILURE_URL} = $ENV{PROT}.'://'. $ENV{SERVER_NAME}.':'. $ENV{SERVER_PORT} . '/paysys_check.cgi?FALSE=1';
  $INFO{SUCCESS_URL} = $ENV{PROT}.'://'. $ENV{SERVER_NAME}.':'. $ENV{SERVER_PORT} . '/index.cgi?TRUE=1';
  $INFO{SIM_MODE}    = $conf{PAYSYS_PAYMASTERRU_SIM_MODE};

  $html->tpl_show(_include('paysys_paymasterru_add', 'Paysys'), {%INFO});

  return 1;
}


#**********************************************************
=head2 paysys_p24_api() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub paysys_p24_api{
  require Paysys::systems::P24_api;
  Paysys::systems::P24_api->import();
  my $P24 = Paysys::systems::P24_api->new(\%conf);

  my $start_date = $FORM{FROM_DATE} || $DATE;
  my $end_date   = $FORM{TO_DATE}   || $DATE;

  $start_date = join '.', reverse split '-', $start_date;
  $end_date   = join '.', reverse split '-', $end_date;

  if($FORM{IDS}){
    my @ids = split(', ', $FORM{IDS});
    my $success_payments = 0;

    foreach my $transaction_id (@ids){
      my $status = $P24->make_payment({
        TRANSACTION_ID => $transaction_id,
        ACCOUNT_KEY    => $FORM{"USER_$transaction_id"},
        SUM            => $FORM{"SUM_$transaction_id"},
        DATE           => $FORM{"DATE_$transaction_id"} || $DATE,
        COMMENT        => $FORM{"COMMENT_$transaction_id"} || '',
      });

      $success_payments++ if ($status == 0);
    }
  }

  if($FORM{OTP}){
    my $is_ok_otp = $P24->send_otp($FORM{SESSION_ID}, $FORM{OTP});

    if($is_ok_otp == 1){
      my $statements = $P24->get_statements($FORM{SESSION_ID},$start_date, $end_date);

      paysys_p24_parse_statements($statements);
    }
    else{
      $html->message('err', "Wrong OTP");
    }

    return 1;
  }
  elsif($FORM{SEND_OTP}){
    $P24->choose_phone_for_otp($FORM{SESSION_ID}, $FORM{SEND_OTP});

    $html->tpl_show(_include('paysys_p24_api_send_otp', 'Paysys'), {SESSION_ID => $FORM{SESSION_ID}});
    return 1;
  }
  elsif($FORM{LOGIN} && $FORM{PASSWORD}){
    my $login_response = $P24->login($FORM{SESSION_ID}, $FORM{LOGIN}, $FORM{PASSWORD});

    #    $login_response->{message} = [{id=>'1111111', number => "050"},{id=>'1111112', number => "063"} ];

    if($login_response->{errno}){
      $html->message("err", "Something goes wrong on login step");
    }
    elsif($login_response->{message} && $login_response->{message} eq 'Authentication successfull'){
      my $statements = $P24->get_statements($FORM{SESSION_ID},$start_date, $end_date);
      paysys_p24_parse_statements($statements);
      return 1;
    }
    elsif($login_response->{message} && $login_response->{message} eq 'Confirm authorization with OTP'){
      $html->tpl_show(_include('paysys_p24_api_send_otp', 'Paysys'), {SESSION_ID => $FORM{SESSION_ID}});

      return 1;
    }
    elsif(ref $login_response->{message} eq 'ARRAY'){
      print $html->form_select(
        'SEND_OTP',
        {
          SELECTED => $FORM{SEND_OTP} || q{},
          SEL_LIST => $login_response->{message},
          SEL_KEY  => 'id',
          SEL_VALUE=> 'number',
          NO_ID => 1,
          SEL_OPTIONS => { '' => "" },
          EX_PARAMS => "data-auto-submit='index=$index&SESSION_ID=$FORM{SESSION_ID}'"
        }
      );

      return 1;
    }
  }
  my ($session_id) = $P24->create_session();

  my $is_validate = $P24->validate_session($session_id);

  if($is_validate == 0){
    $html->message("err", "Something goes wrong on validate session");
    return 1;
  }

  $html->tpl_show(_include('paysys_p24_api_login', 'Paysys'), {SESSION_ID => $session_id});


  return 1;
}

#**********************************************************
=head2 paysys_p24_parse_statements()

=cut
#**********************************************************
sub paysys_p24_parse_statements {
  my ($xml_statements) = @_;

  my $payments_extid_list = 'P24_API:*';
  my $payments_list = $Payments->list({ EXT_ID    => $payments_extid_list,
    DATETIME  => '_SHOW',
    PAGE_ROWS => 100000,
    COLS_NAME => 1,
  });


  my %added_payments = ();
  foreach my $line (@$payments_list) {
    if ($line->{ext_id}) {
      $line->{ext_id} =~ s/$payments_extid_list://;
      $added_payments{ $line->{ext_id} } = "$line->{id}:" . "$line->{uid}:" . ($line->{login} || '') .":$line->{datetime}";
    }
  }

  #  _bp("", \%added_payments);

  my $p24_api_table = $html->table({
    width      => '100%',
    caption    => "P24 Application",
    title      =>
    [ 'ID', $lang{USER}, "$lang{SUM}", "$lang{TRANSACTION}", $lang{COMMENTS}, $lang{DATE}, $lang{NAME}],
    #    qs         => $pages_qs,
    #    pages      => $Paysys->{TOTAL},
    ID         => 'P24_API'
  });

  if($conf{PAYSYS_P24_API_DEBUG_FILE}){
    $xml_statements = '';
    open( my $fh, '<', $conf{PAYSYS_P24_API_DEBUG_FILE} ) or print "Can't open '$conf{PAYSYS_P24_API_DEBUG_FILE}'. $!";
    while (<$fh>) {
      $xml_statements .= $_;
    }
    close( $fh );
  }

  load_pmodule( 'XML::Simple' );
  my $statements = eval { XML::Simple::XMLin( $xml_statements, forcearray => 1 ) };

  if($@){
    $html->message("err", "Privat answer is not XML", "$@");
    print $html->element("pre", $xml_statements);
    return 1;
  }

  foreach my $payment_row (@{$statements->{row}}){
    use utf8;
    utf8::encode($payment_row->{purpose}->[0] || '');

    #    _bp("", $payment_row->{debet}->[0]->{account});
    my $sum = $payment_row->{amount}->[0]->{amt} || '';
    #my $number      = $payment_row->{info}->[0]->{number} || '';
    my $date        = $payment_row->{info}->[0]->{postdate} || '';
    my $state       = $payment_row->{info}->[0]->{state} || '';
    my $account_hash = $payment_row->{debet}->[0]->{account};

    my ($payer_name)  =  keys %{ $account_hash };
    utf8::encode($payer_name || '');

    $date =~ s/T/ /;
    $date =~ s/(\d{4})(\d{2})(\d{2})(.*)/$1-$2-$3$4/;
    my $transaction = '';
    if($conf{PAYSYS_P24_API_NEW_SCHEME_DATE}){
      if(date_diff("$conf{PAYSYS_P24_API_NEW_SCHEME_DATE}", $date) >= 0){
        $transaction = $payment_row->{info}->[0]->{refp}|| '';
      }
      else{
        $transaction = $payment_row->{row}->{TRAN_ID}->{content} || '';
      }
    }
    else{
      $transaction = $payment_row->{row}->{TRAN_ID}->{content} || '';
    }

    my $comments    = $payment_row->{purpose}->[0];

    if($conf{PAYSYS_P24_API_FILTER} && $comments =~ /$conf{PAYSYS_P24_API_FILTER}/){
      next;
    }

    my $id   = '';
    my $user_input = '';
    my $user_identifier = '';

    if($conf{PAYSYS_P24_API_PARSE}){
      ($user_identifier) = $comments =~ /$conf{PAYSYS_P24_API_PARSE}/;
      $user_identifier //= '';
    }

    if ($sum > 0 && $state eq 'r'){
      if(exists $added_payments{$transaction}){
        $p24_api_table->{rowcolor} = 'success';
        my ($id, $uid, $login, undef) = split(':', $added_payments{$transaction});
        $user_input  = $html->button("$lang{LOGIN}: $login", "index=15&UID=" . $uid, { class=>'btn btn-success'});
        $transaction = $html->button( "$lang{ADDED}:$transaction", "index=2&ID=$id" )
      }
      else {
        $conf{PAYSYS_P24_API_ACCOUNT_KEY} = $conf{PAYSYS_P24_API_ACCOUNT_KEY} || 'UID';
        if($user_identifier ne ''){
          my $user_info = $users->list({ LOGIN        => '_SHOW',
            FIO          => '_SHOW',
            CONTRACT_ID  => '_SHOW',
            COMPANY_ID   => '_SHOW',
            COMPANY_NAME => '_SHOW',
            $conf{PAYSYS_P24_API_ACCOUNT_KEY} => $user_identifier,
            COLS_NAME    => 1,
            COLS_UPPER   => 1,
            PAGE_ROWS    => 2,
          });

          if(!$users->{errno} && (scalar @{$user_info} > 0)){
            my $login = $user_info->[0]->{LOGIN} || '';
            #            my $fio   = $user_info->[0]->{FIO}   || '';
            my $uid   = $user_info->[0]->{UID};
            my $company_id   = $user_info->[0]->{COMPANY_ID};
            my $button_text  = "$lang{LOGIN}: $login;";
            use Companies;
            my $Companies = Companies->new($db, $admin, \%conf);
            my $company_info = $Companies->info($company_id);
            if(!$Companies->{errno}){
              $button_text .= "$lang{COMPANY}: $company_info->{NAME}";
            }

            $user_input  = $html->button($button_text, "index=15&UID=" . $uid, { class => 'btn btn-xs btn-primary'});
          }
        }

        $p24_api_table->{rowcolor} = 'danger';
        $id = $html->form_input("IDS", $transaction, { TYPE => 'checkbox' });
        $user_input .= $html->form_input("USER_$transaction", $user_identifier, { TYPE => 'text' });
        $user_input .= $html->form_input("SUM_$transaction", $sum, { TYPE => 'hidden' });
        $user_input .= $html->form_input("DATE_$transaction", $date, { TYPE => 'hidden' });
        $user_input .= $html->form_input("COMMENT_$transaction", $comments, { TYPE => 'hidden' });
      }
    }
    elsif ($sum < 0){
      $p24_api_table->{rowcolor} = 'warning';
    };

    $p24_api_table->addrow($id, $user_input, $sum, $transaction, $comments, $date, $payer_name);
  }

  reports({
    PERIOD_FORM => 1,
    DATERANGE => 1,
    NO_GROUP  => 1,
    NO_TAGS   => 1,
    HIDDEN    => {LOGIN => $FORM{LOGIN}, PASSWORD => $FORM{PASSWORD}, SESSION_ID => $FORM{SESSION_ID}}
  });

  print $html->form_main(
    {
      CONTENT =>
      #      $report_form .
      $p24_api_table->show() .
        $html->form_input( "LOGIN", ($FORM{LOGIN} || ''), { TYPE => 'hidden' } ) .
        $html->form_input( "PASSWORD", ($FORM{PASSWORD} || ''), { TYPE => 'hidden' } ) .
        $html->form_input( "SESSION_ID", ($FORM{SESSION_ID}|| ''), { TYPE => 'hidden' } ),
      HIDDEN  => {
        index       => "$index",
        OP_SID      => $op_sid,
        IMPORT_TYPE => $FORM{IMPORT_TYPE},
      },
      SUBMIT  => { IMPORT => "$lang{IMPORT}" },
      NAME    => 'FORM_IMPORT'
    }
  );

  return 1;
}

#**********************************************************
=head2 paysys_electrum()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_electrum {
  my $payment_system_id = 125;
  my $payment_system    = 'Electrum';

  require Paysys::systems::Electrum;
  Paysys::systems::Electrum->import();
  my $Electrum= Paysys::systems::Electrum->new(\%conf);

  my ($is_request_added, $request_info) = $Electrum->add_request({
    SUM          => $FORM{SUM},
    OPERATION_ID => $FORM{OPERATION_ID},
  });

  if($is_request_added){
    $Paysys->add(
      {
        SYSTEM_ID      => $payment_system_id,
        SUM            => $FORM{SUM},
        UID            => $LIST_PARAMS{UID} || $user->{UID},
        IP             => "$ENV{'REMOTE_ADDR'}",
        TRANSACTION_ID => "$payment_system:$request_info->{id}",
        STATUS         => 1,
        DOMAIN_ID      => $user->{DOMAIN_ID}
      }
    );

    if(!$Paysys->{errno}){
      $html->redirect($request_info->{index_url});
      exit 0;
    }
    else{
      $html->message('err', "$lang{ERROR}", "Cant add to abills database");
    }
  }
  else{
    $html->message('err', "$lang{ERROR}", "Check your electrum settings.");
  }

  return 1;
}

#**********************************************************
=head2 paysys_groups_settings() - check whats

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_groups_settings {

  if ($FORM{add_settings}) {
    # truncate settings table
    $Paysys->groups_settings_delete({});
    _error_show($Paysys);
  }

  use Users;
  my $Users = Users->new($db, $admin, \%conf);
  # get groups list
  my $groups_list = $Users->groups_list({
    COLS_NAME      => 1,
    DISABLE_PAYSYS => 0
  });

  # get payment systems list
  my %connected_payment_systems = paysys_system_sel({ ONLY_SYSTEMS => 1 });

  my @connected_payment_systems = ($lang{GROUPS});
  foreach my $system_id (sort keys %connected_payment_systems) {
    push (@connected_payment_systems, $connected_payment_systems{$system_id});
  }

  # table for settings
  my $table = $html->table(
    {
      width   => '100%',
      caption => "$lang{PAYSYS_SETTINGS_FOR_GROUPS}",
      title   => \@connected_payment_systems,
      ID      => 'PAYSYS_GROUPS_SETTINGS',

    }
  );

  # get settings from db
  my $list_settings = $Paysys->groups_settings_list({
    GID       => '_SHOW',
    PAYSYS_ID => '_SHOW',
    COLS_NAME => 1,
  });

  my %groups_settings = ();

  foreach my $gid_settings (@$list_settings) {
    $groups_settings{"SETTINGS_$gid_settings->{gid}_$gid_settings->{paysys_id}"} = 1;
  }

  # form rows for table
  foreach my $group (@$groups_list) {
    my @rows;
    next if $group->{disable_paysys} == 1;

    foreach my $id (sort keys %connected_payment_systems) {
      my $input_name = "SETTINGS_$group->{gid}_$id";
      if ($FORM{add_settings} && $FORM{$input_name}) {
        $Paysys->groups_settings_add({
          GID       => $group->{gid},
          PAYSYS_ID => $id
        });
      }

      my $checkbox = $html->form_input("$input_name", "1",
        { TYPE => 'checkbox', STATE => (($FORM{$input_name} || $groups_settings{$input_name}) ? 'checked' : '') });

      my $settings_button = $html->button("$lang{SETTINGS}",
        "get_index=paysys_systems_configuration&MERCHANT=$group->{gid}&MODULE=$connected_payment_systems{$id}&chg=1&PAYSYSTEM_ID=$id&header=2",
        {
          class         => 'btn-xs',
          LOAD_TO_MODAL => 1,
        });
      push(@rows, "$lang{LOGON}" . $checkbox . "<br>" . $settings_button);
    }

    $table->addrow($group->{name}, @rows);
  }
  _error_show($Paysys);

  # form for sending settings
  print $html->form_main(
    {
      CONTENT => $table->show(),
      HIDDEN  => {
        index  => "$index",
        #        OP_SID => "$op_sid",
      },
      SUBMIT  => { 'add_settings' => "$lang{CHANGE}" },
      NAME    => 'PAYSYS_GROUPS_SETTINGS'
    }
  );

  return 1;
}

#**********************************************************
=head2 paysys_plategka()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_plategka {
  require Paysys::systems::Plategka;
  Paysys::systems::Plategka->import();
  my $Plategka= Paysys::systems::Plategka->new(\%conf, \%FORM, $admin, $db, { HTML => $html });

  $Plategka->user_portal($user, {
      DATE_TIME => "$DATE $TIME",
    });
}


#**********************************************************
=head2 paysys_systems_configuration() - show table with all payment systems

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_systems_configuration {
  my $paysys_folder = "$base_dir" . 'Abills/modules/Paysys/systems/';

  if($FORM{add_form}){
    my $btn_value = $lang{ADD};
    my $btn_name  = 'add_paysys';
    $html->tpl_show(
      _include('paysys_connect_system', 'Paysys'),
      {
        BTN_VALUE      => $btn_value,
        BTN_NAME       => $btn_name,
        PAYSYS_SELECT  => _paysys_select_system()
      },
    );
  }

  if($FORM{add_paysys}){
    $Paysys->paysys_connect_system_add({
      PAYSYS_ID => $FORM{PAYSYS_ID},
      NAME      => $FORM{NAME},
      MODULE    => $FORM{MODULE},
      PAYSYS_IP => $FORM{IP},
      STATUS    => $FORM{STATUS},
    });

    if(!_error_show($Paysys)){
      $html->message('info', $lang{SUCCESS}, $lang{ADDED});
    }
  }

  if($FORM{MERCHANT}){
    paysys_merchant_configuration();

    return 1;
  }

  # change %CONF params in db
  if ($FORM{change}) {
    my $config = Conf->new($db, $admin, \%conf);

    my $payment_system = $FORM{MODULE};
    my $require_module = _new_paysys_load($payment_system);

    if ($require_module->can('get_settings')) {
      my %settings = $require_module->get_settings();

      foreach my $key (sort keys %{$settings{CONF}}) {
        $config->config_add({ PARAM => $key, VALUE => $FORM{$key}, REPLACE => 1 });
      }

    }

    $html->message("info", "$lang{SETTINGS} $lang{ADDED} $lang{SUCCESS}");

    $Paysys->paysys_connect_system_change({
      %FORM,
      PAYSYS_IP => $FORM{IP},
    });
  }
  elsif($FORM{clear}){
    my $config = Conf->new($db, $admin, \%conf);

    my $payment_system = $FORM{PAYSYSTEM};
    my $require_module = _new_paysys_load($payment_system . ".pm");

    if ($require_module->can('get_settings')) {
      my %settings = $require_module->get_settings();

      foreach my $key (sort keys %{$settings{CONF}}) {
        $config->config_del($key);
      }

    }

    $html->message("info", "$lang{SETTINGS} $lang{DELETED} $lang{SUCCESS}");
  }
  elsif($FORM{del}){
    $Paysys->paysys_connect_system_delete({
      ID => $FORM{del},
      %FORM
    });
    _error_show($Paysys);
  }

  if($FORM{chg}){
    my $btn_value = $lang{CHANGE};
    my $btn_name  = 'change';
    my $connect_system_info = $Paysys->paysys_connect_system_info({
      ID               => $FORM{chg},
      SHOW_ALL_COLUMNS => 1,
      COLS_NAME        => 1,
      COLS_UPPER       => 1,
    });

    $html->tpl_show(
      _include('paysys_connect_system', 'Paysys'),
      {
        PAYSYS_SELECT  => _paysys_select_system(),
        BTN_VALUE      => $btn_value,
        BTN_NAME       => $btn_name,
        %{ ($connect_system_info) ? $connect_system_info : {} },
        ACTIVE         => $connect_system_info->{status},
        IP             => $connect_system_info->{paysys_ip}
      },
    );
  }

  # table to show all systems in folder
  my $table_for_systems = $html->table(
    {
      caption => "",
      width   => '100%',
      title   => [ '#', "$lang{PAY_SYSTEM}", "$lang{MODULE}", "$lang{VERSION}", "$lang{STATUS}", "$lang{TEST}", '', '' ],
      MENU    => "$lang{ADD}:index=$index&add_form=1:add",
    }
  );

  my $systems = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    COLS_NAME        => 1,
  });

  foreach my $payment_system (@$systems) {

    my $require_module = _new_paysys_load($payment_system->{module});
    # check if module already on new verision and has get_settings sub
    if ($require_module->can('get_settings')) {
      my %settings = $require_module->get_settings();

      my $status      = $payment_system->{status} || 0;
      my $paysys_name = $payment_system->{name} || '';
      my $id          = $payment_system->{id} || 0;
      my $paysys_id   = $payment_system->{paysys_id} || 0;

      $status = (!($status) ? $html->color_mark("$lang{DISABLE}", 'danger') : $html->color_mark(
          "$lang{ENABLE}",
          'success'));

      my $change_button = $html->button("$lang{CHANGE}", "index=$index&MODULE=$payment_system->{module}&chg=$id&PAYSYSTEM_ID=$paysys_id",
        { class => 'change' });
      my $delete_button = $html->button("$lang{DEL}", "index=$index&MODULE=$payment_system->{module}&del=$id&PAYSYSTEM_ID=$paysys_id",
        { class => 'del', MESSAGE => "$lang{DEL} $paysys_name", });

      my $test_button = $lang{NOT_EXIST};
      if($require_module->can('has_test')){
        my $test_index = get_function_index('paysys_test');
        $test_button = $html->button("$lang{START_PAYSYS_TEST}", "index=$test_index&MODULE=$payment_system->{module}&PAYSYSTEM_ID=$paysys_id",
          { class => 'btn btn-success btn-xs' });
      }

      $table_for_systems->addrow(
        "$paysys_id",
        "$paysys_name",
        "$payment_system->{module}",
        "$settings{VERSION}",
        "$status",
        $test_button,
        $change_button,
        $delete_button,
      );
    }

  }

  print $table_for_systems->show();
}

#**********************************************************
=head2 paysys_merchant_confimerchant_configuration()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_merchant_configuration {
  my $paysys_folder = "$base_dir" . 'Abills/modules/Paysys/systems/';

  if (!(-e "$paysys_folder" . "$FORM{MODULE}.pm")) {
    $html->message("err", "No such payment system in folder");
    return 1;
  }
  my $payment_system = $FORM{MODULE};
  my $merchant       = $FORM{MERCHANT};
  my $require_module = _new_paysys_load($payment_system . ".pm");

  if ($require_module->can('get_merchant_settings')) {
    my %settings = $require_module->get_merchant_settings();

    my $input_html = '';
    foreach my $key (sort keys % { $settings{CONF} }) {

      if($FORM{action}){
        my $config = Conf->new($db, $admin, \%conf);
        if($FORM{DELETE_MERCHANT_SETTINGS}){
          $config->config_del($key . "_" . $merchant);
          next;
        }
        $config->config_add({ PARAM => $key . "_" . $merchant, VALUE => $FORM{$key . "_" . $merchant}, REPLACE => 1 });
        next;
      }
      my $key_value = $conf{$key . "_" . $merchant} || $settings{CONF}{$key};

      $input_html .= $html->tpl_show(
        _include('paysys_settings_input', 'Paysys'),
        {
          SETTING_LABEL => $key,
          SETTING_NAME  => $key . "_" . $merchant,
          SETTING_VALUE => $key_value,
        },
        { OUTPUT2RETURN => 1 }
      );
    }

    $html->message('info', $lang{SUCCESS}) if ($FORM{MESSAGE_ONLY});
    return 1 if $FORM{MESSAGE_ONLY};

    $html->tpl_show(
      _include('paysys_settings_merchant', 'Paysys'),
      {
        INPUT            => $input_html,
        PAYSYSTEM_NAME   => $payment_system,
        PAYSYSTEM_ID     => $settings{ID},
        MERCHANT         => $merchant,
        ACTION           => 'merchant_settings',
        AJAX_SUBMIT_FORM => 'ajax-submit-form'
      },
    );
  }

  return 1;
}

#**********************************************************
=head2 paysys_test()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_test {
  if (!$FORM{MODULE}) {
    $html->message("err", "No such payment system ");
    return 1;
  }
  elsif($FORM{MODULE} !~ /^[A-za-z0-9\_]+\.pm$/){
    $html->message('err', "Permission denied");
  }

  my ($payment_system_name) = $FORM{MODULE} =~ /([A-za-z0-9\_]+)\.pm/;

  my $html_for_user_id = $html->element('label', $lang{USER}, {class=>'col-md-3 control-label'})
    . $html->element('div', $html->form_input("USER_ID", $FORM{USER_ID} || '', { TYPE => 'text',  }) , {class=>'col-md-9'});


  print $html->form_main(
    {
      CONTENT => $html->element('div', $html_for_user_id, {class=>'form-group'}),
      HIDDEN  => {
        index     => "$index",
        MODULE    => $FORM{MODULE},
      },
      SUBMIT  => { start_test => "$lang{START_PAYSYS_TEST}" },
      NAME    => 'FORM_PAYSYS_TEST'
    }
  );

  if ($FORM{start_test} && $FORM{USER_ID}) {
    my $user_id = $FORM{USER_ID};
    my $result = cmd("perl /usr/abills/Abills/modules/Paysys/t/$payment_system_name.t $user_id");

    print $html->element('pre', $result);
  }

  return 1;
}
#
##**********************************************************
#=head2 paysys_read_folder_systems()
#
#  Arguments:
#     -
#
#  Returns:
#
#=cut
##**********************************************************
#sub _paysys_read_folder_systems {
#  my $paysys_folder = "$base_dir" . 'Abills/modules/Paysys/systems/';
#
#  my @systems = ();
#  # read all .pm in folder
#  opendir(my $folder, $paysys_folder);
#  while (my $filename = readdir $folder) {
#    if ($filename =~ /pm$/ && $filename ne 'Paysys_Base.pm') {
#      push(@systems, $filename);
#    }
#  }
#  closedir $folder;
#
#  return \@systems
#}


#**********************************************************
=head2 paysys_read_folder_systems()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _paysys_select_system {
  my $systems = _paysys_read_folder_systems();

  return $html->form_select('MODULE',
    {
      SELECTED    => $FORM{MODULE} || '',
      SEL_ARRAY   => $systems,
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' },
    } );
}

#**********************************************************
=head2 paysys_read_folder_systems($payment_system)

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _new_paysys_load {
  my ($payment_system) = @_;

  if(!$payment_system){
    return 0;
  }

  my ($paysys_name) = $payment_system =~ /(.+)\.pm/;

  my $require_module = "Paysys::systems::$paysys_name";

  eval { require "Paysys/systems/$payment_system"; };

  if(! $@) {
    $require_module->import($payment_system);
  }
  else {
    print "Error loading\n";
    print $@;
  }

  return $require_module;
}
1;