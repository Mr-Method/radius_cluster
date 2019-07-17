#

=head1 Paysys_Base

  Paysys_Base - module for payments

=head1 SYNOPSIS

  paysys_load('Paysys_Base');

=cut

use strict;
use Abills::Filters;
use Abills::Base qw(sendmail convert);
use Finance;

our (
  $admin,
  $db,
  %conf,
  %PAYSYS_PAYMENTS_METHODS,
  %lang,
  $html,
  $base_dir
);

my $payments = Finance->payments($db, $admin, \%conf);
#my $fees     = Finance->fees($db, $admin, \%conf);
my $Paysys   = Paysys->new($db, $admin, \%conf);

my @status = ("$lang{UNKNOWN}", #0
  "$lang{TRANSACTION_PROCESSING}", #1
  "$lang{COMPLETE}", #2
  "$lang{CANCELED}", #3
  "$lang{EXPIRED}", #4
  "$lang{INCORRECT_CHECKSUM}", #5
  "$lang{PAYMENT_ERROR}", #6
  "$lang{DUBLICATE}", #7
  "$lang{USER_ERROR}", #8
  "$lang{USER_NOT_EXIST}", #9
  "$lang{SMALL_PAYMENT_SUM}", #10
  'SQL_ERROR',                #11
  'TEST',                     #12
  'WAIT',                     #13
  'REJECT',                   #14
  'UNPAID',                   #15
  'WRONG_SUM',                #16
  'PAYMENT_SQL_ERROR',        #17
);

#**********************************************************
=head2 function paysys_pay() - make payment;

  Arguments:
    $attr
      DEBUG             - Level of debugging;
      EXT_ID            - External unique identifier of payment;
      CHECK_FIELD       - Synchronization field for subscriber;
      USER_ID           - Identifier for subscriber;
      PAYMENT_SYSTEM    - Short name of payment system;
      PAYMENT_SYSTEM_ID - ID of payment system;
      CURRENCY          - The exchange rate for the payment of the system;
      CURRENCY_ISO      -
      SUM               - Payment amount;
      DATA              - HASH_REF Transaction infromation field;
      ORDER_ID          - Transaction identifier in ABillS;
      MK_LOG            - Logging;
      REGISTRATION_ONLY - Add payment info without real payment
      PAYMENT_DESCRIBE  - Description of payment;
      PAYMENT_ID        - if this attribute is on(1), function will return two values:
                                    $status_code - status code;
                                    $payments_id - transaction identifier in ABillS;
      USER_INFO         - Additional information;
      ERROR             - Status error;
  Returns:
    Payment status code.
    All codes:
      0   Operation was successfully completed
      1   User not present in the system
      2   The error in the database
      3   Such payment already exists in the system (payments list)
      5   Improper payment amount. It arises in systems with a tandem payment if the user starts a transaction with one amount but in the process of changing the amount of the transaction
      6   Too small amount
      7   The amount of the payment more than permitted
      8   The transaction is not found (Paysys list not found)
      9   Payments already exists
      10  This payment is not found in the system
      11  For this group of users not allowed to use external payment (Paysys)
      12  An unknown SQL error payment
      13  Error logging external payments (Paysys list exist transaction)
      14  User withot bill account
      15
      17  SQL when conducting payment
      28  Wrong exchange
      35  Wrong signature


  Examples:
    my $result_code = paysys_pay({
        PAYMENT_SYSTEM    => OP,
        PAYMENT_SYSTEM_ID => 100,
        CHECK_FIELD       => UID,
        USER_ID           => 1,
        SUM               => 50.00,
        EXT_ID            => 11111111,
        DATA              => \%FORM,
        CURRENCY          => $conf{PAYSYS_PAYNET_CURRENCY},
        PAYMENT_DESCRIBE  => 'Payment with paysystem Oplata'
        PAYMENT_ID        => 1,
        MK_LOG            => 1,
        DEBUG             => 7
    });
    $result_code - payment status code.

    my ($result_code, $payments_id ) = paysys_pay({
    PAYMENT_SYSTEM    => $payment_system,
    PAYMENT_SYSTEM_ID => $payment_system_id,
    CHECK_FIELD       => $CHECK_FIELD,
    USER_ID           => $request_params{customer_id},
    SUM               => $request_params{sum},
    EXT_ID            => $request_params{transaction_id},
    DATA              => \%request_params,
    CURRENCY          => $conf{PAYSYS_PAYNET_CURRENCY},
    MK_LOG            => 1,
    PAYMENT_ID        => 1,
    DEBUG             => $debug
});
=cut

#**********************************************************
sub paysys_pay {
  my ($attr) = @_;

  my $debug          = $attr->{DEBUG};
  my $ext_id         = $attr->{EXT_ID} || '';
  my $CHECK_FIELD    = $attr->{CHECK_FIELD};
  my $user_account   = $attr->{USER_ID};
  my $payment_system = $attr->{PAYMENT_SYSTEM};
  my $payment_system_id = $attr->{PAYMENT_SYSTEM_ID};
  my $amount         = $attr->{SUM};
  my $order_id       = $attr->{ORDER_ID};
  $users = $attr->{USER_INFO_OBJECT} if $attr->{USER_INFO_OBJECT};

  my $status         = 0;
  my $payments_id    = 0;
  my $uid            = 0;
  my $paysys_id      = 0;
  my $ext_info       = '';

  $user_account = _expr($user_account, $conf{PAYSYS_ACCOUNT_EXPR});

  if ($attr->{DATA}) {
    foreach my $k (sort keys %{ $attr->{DATA} }) {
      if ($k eq '__BUFFER') {
        next;
      }

      $ext_info .= "$k, $attr->{DATA}->{$k}\n";
    }

    if ($attr->{MK_LOG}) {
      mk_log($ext_info, { PAYSYS_ID => $payment_system, REQUEST => 'Request' });
    }
  }

  #Wrong sum
  if ($amount && $amount <= 0) {
    return 5;
  }
  #Small sum
  elsif($attr->{MIN_SUM} && $amount < $attr->{MIN_SUM}) {
    return 6;
  }
  # large sum
  elsif($attr->{MAX_SUM} && $amount > $attr->{MAX_SUM}) {
    return 7;
  }
  elsif($ext_id eq 'no_ext_id') {
    return 29;
  }

  if($debug > 6) {
    $users->{debug}=1;
    $Paysys->{debug}=1;
    $payments->{debug}=1;
  }

  #Get transaction info
  if ($order_id || $attr->{PAYSYS_ID}) {
    print "Order: $order_id\n" if ($debug > 1);

    my $list = $Paysys->list(
    {
      TRANSACTION_ID => $order_id || '_SHOW',
      ID             => $attr->{PAYSYS_ID} || undef,
      DATETIME       => '_SHOW',
      STATUS         => '_SHOW',
      SUM            => '_SHOW',
      COLS_NAME      => 1,
      DOMAIN_ID      => '_SHOW',
      SKIP_DEL_CHECK => 1
    }
    );

    # if transaction not exist
    if ($Paysys->{errno} || $Paysys->{TOTAL} < 1) {
      $status = 8;
      return $status;
    }
    #If transaction success
    elsif($list->[0]->{status} == 2) {
      $status = 9;
      return $status, $list->[0]->{id}; # added ID for second param return 08.02.2017
    }
    #elsif($list->[0]->{status} != 1) {
    #
    #}

    if (!$order_id) {
      (undef, $ext_id)=split(/:/, $list->[0]->{transaction_id});
    }

    $uid       = $list->[0]->{uid};
    $paysys_id = $list->[0]->{id};
    $amount    = $list->[0]->{sum};

    if ($amount && $list->[0]->{sum} != $amount) {
      $attr->{ERROR} = 16;
      $status = 5;
    }

    #Register success payments
    if ($attr->{REGISTRATION_ONLY}) {
      if (! $attr->{ERROR}) {
        $Paysys->change(
          {
            ID        => $paysys_id,
            STATUS    => 2,
            PAYSYS_IP => $ENV{'REMOTE_ADDR'},
            INFO      => $ext_info,
            USER_INFO => $attr->{USER_INFO} || ''
          }
         );
         return 0;
      }
    }
  }
  else {
    if($conf{PAYSYS_ACCOUNT_KEY}){
      $CHECK_FIELD = _account_expression($user_account);
    }

    my $list = $users->list({ $CHECK_FIELD   => $user_account || '---',
                              DISABLE_PAYSYS => '_SHOW',
                              GROUP_NAME     => '_SHOW',
                              COLS_NAME      => 1  });
    if ($users->{errno} || $users->{TOTAL} < 1) {
      $status = 1;
      return $status;
    }

    #disable paysys
    if ($list->[0]->{disable_paysys}) {
      return 11;
    }

    $uid = $list->[0]->{uid};
  }

  my $user = $users->info($uid);
  #Error
  if($attr->{ERROR}) {
    my $error_code = ($attr->{ERROR} == 35) ? 5 : $attr->{ERROR};

    if ( $paysys_id ) {
      $Paysys->change(
          {
            ID        => $paysys_id,
            STATUS    => $error_code,
            PAYSYS_IP => $ENV{'REMOTE_ADDR'},
            INFO      => $ext_info,
            USER_INFO => $attr->{USER_INFO}
          }
      );
    }
    else {
      $Paysys->add(
          {
            SYSTEM_ID      => $payment_system_id,
            DATETIME       => $attr->{DATE} || "$DATE $TIME",
            SUM            => ($attr->{COMMISSION} && $attr->{SUM})  ? $attr->{SUM} : $amount,
            UID            => $uid,
            IP             => $attr->{IP},
            TRANSACTION_ID => "$payment_system:$ext_id",
            INFO           => $ext_info,
            USER_INFO      => $attr->{USER_INFO},
            PAYSYS_IP      => $ENV{'REMOTE_ADDR'},
            STATUS         => $error_code
          }
      );
      $paysys_id = $Paysys->{INSERT_ID};
    }

    if($attr->{PAYMENT_ID}){
      return $error_code, $paysys_id;
    }

    return $error_code;
  }

  my $er       = '';
  my $currency = 0;

  #Exchange radte
  my $PAYMENT_SUM = 0;
  if ($attr->{CURRENCY} || $attr->{CURRENCY_ISO}) {
    $payments->exchange_info(0, {
        SHORT_NAME => $attr->{CURRENCY},
        ISO        => $attr->{CURRENCY_ISO} });
    if ($payments->{errno} && $payments->{errno} != 2) {
      return 28;
    }
    elsif ($payments->{TOTAL} > 0) {
      $er       = $payments->{ER_RATE};
      $currency = $payments->{ISO};
    }
    if ($er && $er != 1) {
      $PAYMENT_SUM = sprintf("%.2f", $amount / $er);
    }
  }

  #Sucsess
  cross_modules_call('_pre_payment', {
    USER_INFO   => $user,
    SKIP_MODULES=> 'Sqlcmd, Cards',
    SILENT      => 1,
    SUM         => $PAYMENT_SUM || $amount,
    AMOUNT      => $amount || $PAYMENT_SUM,
    EXT_ID      => "$payment_system:$ext_id",
    METHOD      => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
    timeout     => $conf{PAYSYS_CROSSMODULES_TIMEOUT} || 4,
    #DEBUG => 5,
    #SILENT => 0
  });


  $payments->add(
    $user,
    {
      SUM          => $amount,
      DATE         => $attr->{DATE},
      DESCRIBE     => $attr->{PAYMENT_DESCRIBE} || "$payment_system",
      METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ? $payment_system_id : '2',
      EXT_ID       => "$payment_system:$ext_id",
      CHECK_EXT_ID => "$payment_system:$ext_id",
      ER           => $er,
      CURRENCY     => $currency,
      USER_INFO    => $attr->{USER_INFO}
    }
  );

  #Exists
  # payments Dublicate
  if ($payments->{errno} && $payments->{errno} == 7) {
    my $list = $Paysys->list({ TRANSACTION_ID => "$payment_system:$ext_id", STATUS => '_SHOW', COLS_NAME => 1 });
    $payments_id = $payments->{ID};
    # paysys list not exist
    if ($Paysys->{TOTAL} == 0) {
      $Paysys->add(
        {
          SYSTEM_ID      => $payment_system_id,
          DATETIME       => $attr->{DATE} || "$DATE $TIME",
          SUM            => ($attr->{COMMISSION} && $attr->{SUM}) ? $attr->{SUM} : ($PAYMENT_SUM || $amount),
          UID            => $uid,
          TRANSACTION_ID => "$payment_system:$ext_id",
          INFO           => $ext_info,
          PAYSYS_IP      => $ENV{'REMOTE_ADDR'},
          STATUS         => 2,
          USER_INFO      => $attr->{USER_INFO}
        }
      );

      $paysys_id = $Paysys->{INSERT_ID};

      if (! $Paysys->{errno}) {
        cross_modules_call('_payments_maked', {
          USER_INFO  => $user,
          PAYMENT_ID => $payments_id,
          SUM        => $PAYMENT_SUM || $amount,
          AMOUNT     => $amount || $PAYMENT_SUM,
          SILENT     => 1,
          QUITE      => 1,
          timeout    => $conf{PAYSYS_CROSSMODULES_TIMEOUT} || 4,
          SKIP_MODULES => 'Cards',
        });
      }

      $status = 3;
    }
    else {
      $paysys_id = $list->[0]->{id};

      if ( $paysys_id && $list->[0]->{status} != 2) {

        $Paysys->change(
          {
            ID        => $paysys_id,
            STATUS    => 2,
            PAYSYS_IP => $ENV{'REMOTE_ADDR'},
            INFO      => $ext_info,
            USER_INFO => $attr->{USER_INFO}
          }
        );
      }

      $status = 13;
    }
  }
  #Payments error
  elsif ($payments->{errno}) {
    if ($debug > 3) {
      print "Payment Error: [$payments->{errno}] $payments->{errstr}\n";
    }

    if ($payments->{errno}==14) {
      $status = 14;
    }
    else {
      $status = 12;
    }
  }
  else {

    if ( $paysys_id ) {
      $Paysys->change(
          {
            ID        => $paysys_id,
            STATUS    => 2,
            PAYSYS_IP => $ENV{'REMOTE_ADDR'},
            INFO      => $ext_info,
            USER_INFO => $attr->{USER_INFO}
          }
      );
    }
    else {
      $Paysys->add(
          {
            SYSTEM_ID      => $payment_system_id,
            DATETIME       => $attr->{DATE} || "$DATE $TIME",
            SUM            => ($attr->{COMMISSION} && $attr->{SUM})  ? $attr->{SUM} : $amount,
            UID            => $uid,
            TRANSACTION_ID => "$payment_system:$ext_id",
            INFO           => $ext_info,
            PAYSYS_IP      => $ENV{'REMOTE_ADDR'},
            STATUS         => 2,
            USER_INFO      => $attr->{USER_INFO}
          }
      );

      $paysys_id = $Paysys->{INSERT_ID};
    }

    if (!$Paysys->{errno}) {
      cross_modules_call('_payments_maked', {
        USER_INFO   => $user,
        PAYMENT_ID  => $payments->{PAYMENT_ID},
        SUM         => $amount,
        SILENT      => 1,
        QUITE       => 1,
        timeout     => $conf{PAYSYS_CROSSMODULES_TIMEOUT} || 4,
      });
    }
    #Transactions registration error
    else {
      if ($Paysys->{errno} && $Paysys->{errno} == 7) {
        $status      = 3;
        $payments_id = $payments->{ID};
      }
      #Payments error
      elsif ($Paysys->{errno}) {
        $status = 2;
      }
    }
  }

  #Send mail
  if ($conf{PAYSYS_EMAIL_NOTICE}) {
    my $message = "\n" . "================================" .
        "System: $payment_system\n" .
        "================================" .
        "DATE: $DATE $TIME\n" .
        "LOGIN: $user->{LOGIN} [$uid]\n\n" . $ext_info . "\n\n";

        sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "$payment_system ADD", "$message", "$conf{MAIL_CHARSET}", "2 (High)");
  }

  if ($attr->{PAYMENT_ID} ) {
    return $status, $paysys_id;
  }

  return $status;
}

#**********************************************************
=head2  function paysys_check_user() - check user in system;

  Arguments:
    $attr
      CHECK_FIELD - Searching field for user;
      USER_ID     - User identifier for CHECK_FIELD;
      EXTRA_FIELDS- Extra fields

  Returns:
    Checking code.
    All codes:
      0  - User exist;
      1  - User not exist;
      2  - SQL error;
      11 - Disable paysys for group

  Examples:
    my ($result, $list) = paysys_check_user({
     CHECK_FIELD => 'UID',
     USER_ID     => 1
    });

    $result - result code;
    $list - users information fields.

=cut
#**********************************************************
sub paysys_check_user {
  my ($attr) = @_;
  my $result = 0;

  my $CHECK_FIELD  = $attr->{CHECK_FIELD};
  my $user_account = $attr->{USER_ID};

  $user_account =~ s/\*//;

  if($conf{PAYSYS_ACCOUNT_KEY}){
    $CHECK_FIELD = _account_expression($user_account);
  }

  $user_account = _expr($user_account, $conf{PAYSYS_ACCOUNT_EXPR});

  if (! $user_account) {
    return 30;
  }

  if ($attr->{DEBUG} && $attr->{DEBUG} > 6) {
    $users->{debug}=1;
  }

  my %EXTRA_FIELDS = ();

  if($attr->{EXTRA_FIELDS}) {
    %EXTRA_FIELDS = %{ $attr->{EXTRA_FIELDS} };
  }

  my $list = $users->list({
    LOGIN          => '_SHOW',
    FIO            => '_SHOW',
    DEPOSIT        => '_SHOW',
    CREDIT         => '_SHOW',
    PHONE          => '_SHOW',
    ADDRESS_FULL   => '_SHOW',
    GID            => defined($attr->{MAIN_GID}) ? $attr->{MAIN_GID} : '_SHOW',
    DOMAIN_ID      => '_SHOW',
    DISABLE_PAYSYS => '_SHOW',
    GROUP_NAME     => '_SHOW',
    DISABLE        => '_SHOW',
    CONTRACT_ID    => '_SHOW',
    ACTIVATE       => '_SHOW',
    REDUCTION      => '_SHOW',
    %EXTRA_FIELDS,
    $CHECK_FIELD   => $user_account,
    COLS_NAME      => 1,
    COLS_UPPER     => 1,
    PAGE_ROWS      => 2,
  });

  if ($users->{errno}) {
    return 2;
  }
  elsif($users->{TOTAL} < 1) {
    return 1;
  }
  elsif ($list->[0]->{disable_paysys}) {
    return 11;
  }
  
  if( $conf{PAYSYS_OSMP_EXTRA_INFO} ){
    use Abills::Misc;
    my $recomended_pay = recomended_pay($list->[0], { SKIP_DEPOSIT_CHECK => ($attr->{SKIP_DEPOSIT_CHECK} || 0) });
    $list->[0]->{fee} = $recomended_pay;
  }
  return $result, $list->[0];
}

#**********************************************************
=head2 function paysys_pay_cancel() - cancel payment;

  Arguments:
    $attr
      PAYSYS_ID      - Paysys ID (unique number of operation);
      TRANSACTION_ID - Paysys Transaction identifier
      RETURN_CANCELED_ID - 1
      DEBUG

  Returns:
    Cancel code.
    All codes:

  Examples:

    my $result = paysys_pay_cancel({
                  TRANSACTION_ID => "OP:11111111"
                 });

    $result - cancel code.

=cut
#**********************************************************
sub paysys_pay_cancel {
  my ($attr) = @_;

  my $debug  = $attr->{DEBUG};
  my $result = 0;
  my $status = 0;
  my $canceled_payment_id = 0;
  my $cancel_status = $attr->{CANCEL_STATUS} || 3;

  if($debug > 6) {
    $users->{debug}=1;
    $Paysys->{debug}=1;
    $payments->{debug}=1;
  }

  my $paysys_list = $Paysys->list({
                         ID             => $attr->{PAYSYS_ID},
                         TRANSACTION_ID => $attr->{TRANSACTION_ID} || '_SHOW',
                         SUM            => '_SHOW',
                         COLS_NAME      => 1
                        });

  if ( $Paysys->{TOTAL} ) {
    my $transaction_id = $paysys_list->[0]->{transaction_id};

    my $list       = $payments->list({ ID        => '_SHOW',
                                       EXT_ID    => "$transaction_id",
                                       BILL_ID   => '_SHOW',
                                       COLS_NAME => 1,
                                       PAGE_ROWS => 1
                                     });

    if ($status == 0) {
      if ($payments->{errno}) {
        $result = 2;
      }
      elsif ($payments->{TOTAL} < 1) {
        $result = 10;
        # cancel transaction status if no payments
        $Paysys->change(
            {
              ID     => $paysys_list->[0]->{id},
              STATUS => $cancel_status
            }
          );
      }
      else {
        my %user = (
          BILL_ID => $list->[0]->{bill_id},
          UID     => $list->[0]->{uid}
        );

        my $payment_id  = $list->[0]->{id};

        $payments->del(\%user, $payment_id);
        if ($payments->{errno}) {
          $result = 2;
        }
        else {
          $Paysys->change(
            {
              ID     => $paysys_list->[0]->{id},
              STATUS => $cancel_status
            }
          );
          $canceled_payment_id = $paysys_list->[0]->{id};
        }
      }
    }
  }
  else {
    $result = 8;
  }

  if($attr->{RETURN_CANCELED_ID}){
    return $result, $canceled_payment_id;
  }

  return $result;
}

#**********************************************************
=head2 function paysys_pay_check() - Checking existing transaction
  Arguments:
    $attr
      PAYSYS_ID      - Payment system identifier;
      TRANSACTION_ID - Transaction identifier;

  Returns:
    0      - if transaction not found;
    number - transaction ID

  Examples:

    my $result = paysys_pay_check({
                  TRANSACTION_ID => "OP:11111111"
             });

    $result - 0 or transaction id;

=cut
#**********************************************************
sub paysys_pay_check {
  my ($attr) = @_;
  my $result = 0;

  my $paysys_list = $Paysys->list({
                         ID             => $attr->{PAYSYS_ID} || '_SHOW',
                         TRANSACTION_ID => $attr->{TRANSACTION_ID} || '_SHOW',
                         SUM            => '_SHOW',
                         COLS_NAME      => 1
                        });

  if ( $Paysys->{TOTAL} ) {
    return  $paysys_list->[0]->{id}, $paysys_list->[0]->{status};
  }

  return $result;
}

#**********************************************************
=head2 function paysys_info() -
  Arguments:
    $attr
      PAYSYS_ID - Payment system identifier;

  Returns:

    Paysys object

  Examples:

    $Paysys->paysys_info({ PAYSYS_ID => 121 });

=cut
#**********************************************************
sub paysys_info {
  my ($attr) = @_;

  $Paysys->info({ ID => $attr->{PAYSYS_ID}
  	              #TRANSACTION_ID => $attr->{TRANACTION_ID}
  	            });

  return $Paysys;
}

#**********************************************************
=head2 conf_gid_split() - Find payment system paramerts for some user group (GID)

  Arguments:
    $attr
      GID         - group identifier;
      PARAMS      - Array of parameters
      SERVICE     - Service ID
      SERVICE2GID - Service to gid
                      delimiter :
                      separator ;

  Returns:
    TRUE or FALSE

  Examples:

    conf_gid_split({ GID    => 1,
                     PARAMS => [
                         'PAYSYS_UKRPAYS_SERVICE_ID',
                      ],
                 })
=cut
#**********************************************************
sub conf_gid_split {
  my ($attr) = @_;

  my $gid    = $attr->{GID};

  if ($attr->{SERVICE} && $attr->{SERVICE2GID}) {
  	my @services_arr = split(/;/, $attr->{SERVICE2GID});
  	foreach my $line (@services_arr) {
  		my($service, $gid_id)=split(/:/, $line);
  		if($attr->{SERVICE} == $service) {
        $gid = $gid_id;
  			last;
  	  }
  	}
  }

  if ($attr->{PARAMS}) {
    my $params = $attr->{PARAMS};
    foreach my $key ( @$params ) {
      if ($conf{$key .'_'. $gid}) {
        $conf{$key} = $conf{$key .'_'. $gid};
        $FORM{MAIN_GID} = $gid; # gid
      }
    }

  }

  return 1;
}

#**********************************************************
=head2 mk_log($message, $attr) - add data to logfile;

Make log file for paysys request

  Arguments:
    $message -
    $attr
      PAYSYS_ID - payment system ID
      REQUEST   - System Request
      REPLY     - ABillS Reply
      SHOW      - print message to output
      LOG_FILE  - Log file. (Default: paysys_check.log)

  Returns:

     TRUE or FALSE

  Examples:
    mk_log("Data for logfile", { PAYSYS_ID => '63' });


=cut
#**********************************************************
sub mk_log {
  my ($message, $attr) = @_;

  my $paysys          = $attr->{PAYSYS_ID} || '';
  my $paysys_log_file = $attr->{LOG_FILE} || $base_dir . 'var/log/paysys_check.log';

  if (open(my $fh, '>>', "$paysys_log_file")) {
    if ($attr->{SHOW}) {
      print "$message";
    }
    $ENV{REMOTE_ADDR} //= '127.0.0.1';
    print $fh "\n$DATE $TIME $ENV{REMOTE_ADDR} $paysys =========================\n";

    if ($attr->{REQUEST}) {
      print $fh "$attr->{REQUEST}\n=======\n";
    }

    print $fh $message;
    close($fh);
  }
  else {
    print "Content-Type: text/plain\n\n";
    print "Can't open log file '$paysys_log_file' $!\n";
    print "Error:\n";
    print "================\n$message================\n";
    die "Can't open log file '$paysys_log_file' $!\n";
    return 0;
  }


  return 1;
}

#**********************************************************
=head2 paysys_show_result($attr) - Show result

  WEB form show result

  Attributes:
    $attr
      TRANSACTION_ID
      UID
      SUM
      SHOW_TRUE_PARAMS - Hash ref
        {NAME:VALUE}
      SHOW_FALSE_PARAMS - Hash ref
        {NAME:VALUE}
  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub paysys_show_result {
  my ($attr) = @_;

  my $transaction_true = 1;
  if ($attr->{TRANSACTION_ID}) {
    my $list = $Paysys->list(
      {
        TRANSACTION_ID => $attr->{TRANSACTION_ID},
        UID            => $attr->{UID} || $LIST_PARAMS{UID},
        SUM            => '_SHOW',
        STATUS         => '_SHOW',
        USER_INFO      => '_SHOW',
        INFO           => '_SHOW',
        COLS_NAME      => 1,
        SKIP_DEL_CHECK => 1,
        SORT           => 'id'
      }
    );

    if ($Paysys->{TOTAL} > 0) {
      $attr->{SUM}=$list->[0]->{sum};
      $FORM{PAYSYS_ID}= $list->[0]->{id};

      if ($list->[0]->{status} != 2) {
        $attr->{MESSAGE} = $status[$list->[0]->{status}];
        $transaction_true = 0;
      }
    }
    else {
      $attr->{MESSAGE} = $lang{ERR_NO_TRANSACTION};
      $attr->{FALSE}   = 1;
      $transaction_true = 0;
    }

    if ($list->[0]->{info} && $list->[0]->{info} =~ /TP_ID,(\d+)/) {
      $FORM{TP_ID}=$1;
    }

    $attr->{USER_INFO} = $list->[0]->{user_info};
  }

  my $qs = '';
  foreach my $key ( keys %FORM) {
    next if ($key eq '__BUFFER');
    $qs .= '&'. $key .'='. $FORM{$key};
  }

  $attr->{BTN_REFRESH} = $html->button( $lang{REFRESH}, "index=$index" . $qs, { BUTTON => 1 } );
  if ($attr->{FALSE}) {
    if ($attr->{SHOW_FALSE_PARAMS}) {
      while(my($key, $value) = each %{ $attr->{SHOW_FALSE_PARAMS} }) {
        $attr->{EXTRA_MESSAGE} .= "$key - $value".$html->br();
      }
    }

    $html->tpl_show(_include('paysys_false', 'Paysys'), { %$attr });
    $transaction_true = 0;
  }
  else {
    if ($attr->{SHOW_TRUE_PARAMS}) {
      while(my($key, $value) = each %{$attr->{SHOW_TRUE_PARAMS} }) {
        $attr->{EXTRA_MESSAGE} .= "$key - $value".$html->br();
      }
    }

    $FORM{TRUE}     = 1;
    $html->tpl_show(_include('paysys_complete', 'Paysys'), { %$attr }) if (! $attr->{QUITE});
  }

  $html->set_cookies('lastindex', "", "Fri, 1-Jan-2038 00:00:01") if (! $FORM{INTERACT});

  return $transaction_true;
}

#**********************************************************
=head2 payasys_import_parse($content, $import_expr, $BINDING_FIELD) - Parce file

  Arguments:
    $content
    $import_expr
    $BINDING_FIELD
    $attr
      DEBUG
      ENCODE

  Returns:
    return \@DATA_ARR, \@BINDING_IDS;

=cut
#**********************************************************
sub paysys_import_parse {
  my ($content, $import_expr, $BINDING_FIELD, $attr) = @_;

  my $debug = $attr->{DEBUG} || 0;

  my @DATA_ARR    = ();
  my @BINDING_IDS = ();

  $import_expr =~ s/ //g;
  $import_expr =~ s/\n//g;
  my ($expration, $columns) = split(/:/, $import_expr);
  my @EXPR_IDS = split(/,/, $columns);
  print "EXPRESSION: $expration\nColumns: $columns\n" if ($debug > 0);

  my @rows       = split(/[\r]{0,1}\n/, $content);
  my $line_count = 1;

  foreach my $line (@rows) {
    my %DATA_HASH = ();

    if ($attr->{ENCODE}) {
      $line = convert($line, { $attr->{ENCODE} => 1 });
    }

    #next if ($#params < $#EXPR_IDS);
    if (my @res = ($line =~ /$expration/)) {
      for (my $i = 0 ; $i <= $#res ; $i++) {
        print "$EXPR_IDS[$i] / $res[$i]\n" if ($debug > 5);
        next if ($EXPR_IDS[$i] eq 'UNDEF');

        $DATA_HASH{ $EXPR_IDS[$i] } = $res[$i];

        if ($EXPR_IDS[$i] eq 'PHONE') {
          $DATA_HASH{ $EXPR_IDS[$i] } =~ s/-//g;
        }
        elsif ($EXPR_IDS[$i] eq 'CONTRACT_ID') {
          $DATA_HASH{ $EXPR_IDS[$i] } =~ s/-//g;
        }
        elsif ($EXPR_IDS[$i] eq 'LOGIN') {
          $DATA_HASH{ $EXPR_IDS[$i] } =~ s/ //g;
        }
        elsif ($EXPR_IDS[$i] eq 'SUM') {
          $DATA_HASH{ $EXPR_IDS[$i] } =~ s/,/\./g;
        }
        elsif ($EXPR_IDS[$i] eq 'DATE') {
          if ($DATA_HASH{ $EXPR_IDS[$i] } =~ /^(\d{2})[.-](\d{2})[.-](\d{4})$/) {
            $DATA_HASH{ $EXPR_IDS[$i] } = "$3-$2-$1";
          }
          elsif ($DATA_HASH{ $EXPR_IDS[$i] } =~ /^(\d{4})[.-](\d{2})[.-](\d{2})$/) {
            $DATA_HASH{ $EXPR_IDS[$i] } = "$1-$2-$3";
          }
        }
      }

      push @DATA_ARR, {%DATA_HASH};
      push @BINDING_IDS, $DATA_HASH{$BINDING_FIELD} if ($DATA_HASH{$BINDING_FIELD});
    }
    elsif ($line ne '') {
      print $html->b( "$lang{ERROR}: line: $line_count" ) . " '$line'" . $html->br();
    }

    $line_count++;
  }

  return \@DATA_ARR, \@BINDING_IDS;
}

#**********************************************************
=head2 _account_expression() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub _account_expression {
  my ($user_account) = @_;

  my @key_expressions = split(';', $conf{PAYSYS_ACCOUNT_KEY});
  my $CHECK_FIELD = q{};

  foreach my $each_key_expression (@key_expressions) {
    my ($reg_exp, $user_check_field) = split(":", $each_key_expression);
    if ($user_account =~ /$reg_exp/) {
      $CHECK_FIELD = $user_check_field;
    }
  }

  return $CHECK_FIELD;
}

#**********************************************************
=head2 _hide_personal_field($symbols_count_show, $field)

  Arguments:
    $symbols_count_show - how much first symbols show
    $field -  string
    
  Returns:
  
=cut
#**********************************************************
sub _hide_personal_field {
  my ( $symbols_count_show, $field ) = @_;

  use Encode;
  my $field_encoded = decode_utf8($field);
  my @changed_fields = ();

  foreach my $string (split(/\s/, $field_encoded)){
    my $string_length = length($string);

    push @changed_fields, substr($string, 0, $symbols_count_show) . '*' x($string_length - $symbols_count_show);
  }
  my $result = encode_utf8(join(' ', @changed_fields));

  return $result
}
  
1
