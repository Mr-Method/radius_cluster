#!/usr/bin/perl

=head1 NAME

  Ureports sender

=cut

use strict;
use warnings FATAL => 'all';

BEGIN {
  use FindBin '$Bin';
  our %conf;
  do $Bin . '/config.pl';
  unshift( @INC,
    $Bin . '/../',
    $Bin . "/../Abills/mysql",
    $Bin . '/../lib/',
    $Bin . '/../Abills/modules' );
}

my $version = 0.72;
my $debug = 0;
our ($db,
  %conf,
  $TIME,
  @MODULES,
  %lang,
  %ADMIN_REPORT,
  %LIST_PARAMS,
  $DATE);

use Abills::Defs;
use Abills::Base qw(int2byte in_array sendmail parse_arguments);
use Abills::Templates;
use Abills::Misc;
use Admins;
use Shedule;
use Dv;
use Dv_Sessions;
use Finance;
use Fees;
use Ureports;
use Tariffs;
use POSIX qw(strftime);

our $html = Abills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
    csv      => 1
  }
);


#my $begin_time = check_time();
$db = Abills::SQL->connect( $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef } );

my $admin = Admins->new( $db, \%conf );
$admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' } );

my $Ureports = Ureports->new( $db, $admin, \%conf );
my $fees     = Fees->new( $db, $admin, \%conf );
my $tariffs  = Tariffs->new( $db, \%conf, $admin );
my $Sessions = Dv_Sessions->new( $db, $admin, \%conf );
my $Shedule  = Shedule->new( $db, $admin, \%conf );

if ($html->{language} ne 'english') {
  do $Bin . "/../language/english.pl";
  do $Bin . "/../Abills/modules/Ureports/lng_english.pl";
}

do $Bin . "/../language/$html->{language}.pl";
do $Bin . "/../Abills/modules/Ureports/lng_$html->{language}.pl";

#my %FORM_BASE      = ();
#my @service_status = ("$lang{ENABLE}", "$lang{DISABLE}", "$lang{NOT_ACTIVE}");
#my @service_type   = ("E-mail", "SMS", "Fax");

#my %REPORTS        = (
#  1 => "$lang{DEPOSIT_BELOW}",
#  2 => "$lang{PREPAID_TRAFFIC_BELOW}",
#  3 => "$lang{TRAFFIC_BELOW}",
#  4 => "$lang{MONTH_REPORT}",
#);
my %SERVICE_LIST_PARAMS = ();

#Arguments
my $argv = parse_arguments( \@ARGV );

if ( defined( $argv->{help} ) ){
  help();
  exit;
}

if ( $argv->{DEBUG} ){
  $debug = $argv->{DEBUG};
  print "DEBUG: $debug\n";
}

$DATE = $argv->{DATE} if ($argv->{DATE});

my $debug_output = ureports_periodic_reports( { %{$argv} } );

print $debug_output;

#**********************************************************
=head2 ureports_send_reports($type, $destination, $message, $attr)

=cut
#**********************************************************
sub ureports_send_reports {
  my ($type, $destination, $message, $attr) = @_;

  if ($attr->{MESSAGE_TEPLATE}) {
    $message = $html->tpl_show( _include( $attr->{MESSAGE_TEPLATE}, 'Ureports' ), $attr,
      { OUTPUT2RETURN => 1 } );
  }
  else {
    $message = $html->tpl_show( _include( 'ureports_report_'.$attr->{REPORT_ID}, 'Ureports' ), $attr,
      { OUTPUT2RETURN => 1 } );
  }

  if ( $debug > 6 ){
    print "$type $destination $message\n";
  }
  elsif ( $type == 0 ){
    $attr->{MESSAGE} = $message;
    $message = $html->tpl_show( _include( 'ureports_email_message', 'Ureports' ), $attr, { OUTPUT2RETURN => 1 } );

    my $subject = $attr->{SUBJECT} || '';
    if ( !sendmail( $conf{ADMIN_MAIL}, $destination, $subject, $message . "\n[$attr->{REPORT_ID}]",
      $conf{MAIL_CHARSET} ) ){
      return 0;
    }
  }
  elsif ( $type == 1 ){
    if ( in_array( 'Sms', \@MODULES ) ){
      $attr->{MESSAGE} = $message;
      $message = $html->tpl_show( _include( 'ureports_sms_message', 'Ureports' ), $attr, { OUTPUT2RETURN => 1 } );

      load_module( 'Sms' );
      sms_send(
        {
          NUMBER    => $destination,
          MESSAGE   => $message,
          DEBUG     => $debug,
          UID       => $attr->{UID},
          PERRIODIC => 1
        }
      );
    }
    elsif ( $conf{UREPORTS_SMS_CMD} ){
      cmd( "$conf{UREPORTS_SMS_CMD} $destination $message" );
    }
  }
  elsif ( $type == 2 ){

  }

  return 1;
}

#**********************************************************
=head2 ureports_periodic_reports($attr)

=cut
#**********************************************************
sub ureports_periodic_reports{
  my ($attr) = @_;

  $debug = $attr->{DEBUG} || 0;
  $debug_output = '';

  $debug_output .= "Ureports: Daily spool former\n" if ($debug > 1);
  $LIST_PARAMS{MODULE} = 'Ureports';
  $LIST_PARAMS{TP_ID} = $argv->{TP_IDS} if ($argv->{TP_IDS});

  if ( $argv->{REPORT_IDS} ){
    $argv->{REPORT_IDS} =~ s/,/;/g;
    $SERVICE_LIST_PARAMS{REPORT_ID} = $argv->{REPORT_IDS} if ($argv->{REPORT_IDS});
  }

  $SERVICE_LIST_PARAMS{LOGIN} = $argv->{LOGIN} if ($argv->{LOGIN});

  $tariffs->{debug} = 1 if ($debug > 6);
  my $list = $tariffs->list( {
      REDUCTION_FEE    => '_SHOW',
      DAY_FEE          => '_SHOW',
      MONTH_FEE        => '_SHOW',
      PAYMENT_TYPE     => '_SHOW',
      EXT_BILL_ACCOUNT => '_SHOW',
      CREDIT           => '_SHOW',
      %LIST_PARAMS,
      COLS_NAME        => 1 } );

  $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
  $SERVICE_LIST_PARAMS{CUR_DATE} = $ADMIN_REPORT{DATE};
  my $d = (split( /-/, $ADMIN_REPORT{DATE}, 3 ))[2];
  #my $reports_type = 0;

  foreach my $tp ( @{$list} ){
    $debug_output .= "TP ID: $tp->{tp_id} DF: $tp->{day_fee} MF: $tp->{month_fee} POSTPAID: $tp->{payment_type} REDUCTION: $tp->{reduction_fee} EXT_BILL: $tp->{ext_bill_account} CREDIT: $tp->{credit}\n" if ($debug > 1);

    #Get users
    $Ureports->{debug} = 1 if ($debug > 5);

    my $ulist = $Ureports->tp_user_reports_list(
      {
        DATE           => '0000-00-00',
        TP_ID          => $tp->{tp_id},
        SORT           => 1,
        PAGE_ROWS      => 1000000,
        DV_TP          => 1,
        ACCOUNT_STATUS => 0,
        DV_STATUS      => '_SHOW',
        STATUS         => 0,
        ACTIVATE       => '_SHOW',
        %SERVICE_LIST_PARAMS,
        MODULE         => '_SHOW',
        COLS_NAME      => 1,
        COLS_UPPER     => 1,
      }
    );

    foreach my $user ( @{$ulist} ){
      #Check bill id and deposit
      my %PARAMS = ();
      $user->{TP_ID} = $tp->{tp_id};

      #Skip disabled user
      next if ($user->{DV_STATUS} && ($user->{DV_STATUS} == 1 || $user->{DV_STATUS} == 2 || $user->{DV_STATUS} == 3));

      $debug_output .= "LOGIN: $user->{LOGIN} ($user->{UID}) DEPOSIT: $user->{deposit} CREDIT: $user->{credit} Report id: $user->{REPORT_ID} DV STATUS: $user->{DV_STATUS} $user->{DESTINATION_ID}\n" if ($debug > 3);

      if ( $user->{BILL_ID} && defined( $user->{DEPOSIT} ) ){
        #Skip action for pay opearation
        if ( $user->{MSG_PRICE} > 0 && $user->{DEPOSIT} + $user->{CREDIT} < 0 && $tp->{payment_type} == 0 ){
          $debug_output .= "UID: $user->{UID} REPORT_ID: $user->{REPORT_ID} DEPOSIT: $user->{DEPOSIT}/$user->{CREDIT} Skip action Small Deposit for sending\n" if ($debug > 0);
          next;
        }

        # Recomended payments
        my $total_daily_fee = 0;
        my $cross_modules_return = cross_modules_call( '_docs', {
          FEES_INFO     => 1,
          UID           => $user->{UID},
          SKIP_DISABLED => 1,
          SKIP_MODULES  => 'Ureports,Sqlcmd'
        } );

        $user->{RECOMMENDED_PAYMENT} = 0;
        foreach my $module ( sort keys %{$cross_modules_return} ){
          if ( ref $cross_modules_return->{$module} eq 'HASH' ){
            if ( $cross_modules_return->{$module}{day} ){
              $total_daily_fee += $cross_modules_return->{$module}{day};
              $user->{RECOMMENDED_PAYMENT} += $cross_modules_return->{$module}{day} * 30;
            }

            if ( $cross_modules_return->{$module}{abon_distribution} ){
              $total_daily_fee += ($cross_modules_return->{$module}{month} / 30);
              $user->{RECOMMENDED_PAYMENT} += $cross_modules_return->{$module}{month};
            }
            elsif ( $cross_modules_return->{$module}{month} ){
              $user->{RECOMMENDED_PAYMENT} += $cross_modules_return->{$module}{month};
            }
          }
        }

        $user->{TOTAL_FEES_SUM} = $user->{RECOMMENDED_PAYMENT};

        if ( $user->{DEPOSIT} + $user->{CREDIT} > 0 ){
          $user->{RECOMMENDED_PAYMENT} = sprintf( "%.2f",
              ($user->{RECOMMENDED_PAYMENT} - $user->{DEPOSIT} > 0) ? ($user->{RECOMMENDED_PAYMENT} - $user->{DEPOSIT} + 0.01) : 0 );
        }
        else{
          $user->{RECOMMENDED_PAYMENT} += sprintf( "%.2f", abs( $user->{DEPOSIT} + $user->{CREDIT} ) );
        }

        $user->{DEPOSIT} = sprintf( "%.2f", $user->{DEPOSIT} );

        if ( $total_daily_fee > 0 ){
          $user->{EXPIRE_DAYS} = int( $user->{DEPOSIT} / $total_daily_fee );
        }
        else{
          $user->{EXPIRE_DAYS} = $user->{TP_EXPIRE};
        }

        $user->{EXPIRE_DATE} = POSIX::strftime( "%Y-%m-%d", localtime( time + $user->{EXPIRE_DAYS} * 86400 ) );

        #Report 1 Deposit belove and dv status active
        if ( $user->{REPORT_ID} == 1 ){
          if ( $user->{VALUE} > $user->{DEPOSIT} && !$user->{DV_STATUS} ){
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  => "$lang{DEPOSIT}: $user->{DEPOSIT}",
              SUBJECT  => "$lang{DEPOSIT_BELOW}"
            );
          }
          else{
            next;
          }
        }

        #Report 2 DEposit + credit below
        elsif ( $user->{REPORT_ID} == 2 ){
          if ( $user->{VALUE} > $user->{DEPOSIT} + $user->{CREDIT} ){
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  => "$lang{DEPOSIT}: $user->{DEPOSIT} $lang{CREDIT}: $user->{CREDIT}",
              SUBJECT  => "$lang{DEPOSIT_CREDIT_BELOW}"
            );
          }
          else{
            next;
          }
        }

        #Report 3 Prepaid traffic rest
        elsif ( $user->{REPORT_ID} == 3 ){
          if ( $Sessions->prepaid_rest( { UID => $user->{UID}, } ) ){
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              SUBJECT  => "$lang{PREPAID_TRAFFIC_BELOW}"
            );

            $list = $Sessions->{INFO_LIST};
            #my $rest_traffic = '';
            my $rest = 0;
            foreach my $line ( @{$list} ){

              $rest = ($line->{prepaid} > 0 && $Sessions->{REST}->{ $line->{traffic_class} } > 0) ? $Sessions->{REST}->{ $line->{traffic_class} } : 0;
              if ( $rest < $user->{VALUE} ){
                $PARAMS{MESSAGE} .= "================\n $lang{TRAFFIC} $lang{TYPE}: $line->{traffic_class}\n$lang{BEGIN}: $line->{interval_begin}\n" . "$lang{END}: $line->{interval_end}\n" . "$lang{TOTAL}: $line->{prepaid}\n" . "\n $lang{REST}: " . $rest . "\n================";
              }
            }
          }
        }

        # 5 => "$lang{MONTH}: $lang{DEPOSIT} + $lang{CREDIT} + $lang{TRAFFIC}",
        elsif ( $user->{REPORT_ID} == 5 && $d == 1 ){
          $Sessions->list(
            {
              UID    => $user->{UID},
              PERIOD => 6
            }
          );

          my $traffic_in = ($Sessions->{TRAFFIC_IN}) ? $Sessions->{TRAFFIC_IN} : 0;
          my $traffic_out = ($Sessions->{TRAFFIC_OUT}) ? $Sessions->{TRAFFIC_IN} : 0;
          my $traffic_sum = $traffic_in + $traffic_out;

          %PARAMS = (
            DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
            MESSAGE  =>
            "$lang{MONTH}:\n $lang{DEPOSIT}: $user->{DEPOSIT}\n $lang{CREDIT}: $user->{CREDIT}\n $lang{TRAFFIC}: $lang{RECV}: " . int2byte( $traffic_in ) . " $lang{SEND}: " . int2byte( $traffic_out ) . " \n  $lang{SUM}: " . int2byte( $traffic_sum ) . " \n"
            ,
            SUBJECT  => "$lang{MONTH}: $lang{DEPOSIT} / $lang{CREDIT} / $lang{TRAFFIC}",
          );
        }

        # 7 - credit expired
        elsif ( $user->{REPORT_ID} == 7 ){
          if ( $user->{CREDIT_EXPIRE} < $user->{VALUE} ){
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  => "$lang{CREDIT} $lang{EXPIRE}",
              SUBJECT  => "$lang{CREDIT} $lang{EXPIRE}"
            );
          }
          else{
            next;
          }
        }

        # 8 - login disable
        elsif ( $user->{REPORT_ID} == 8 ){
          if ( $user->{DISABLE} ){
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  => "$lang{LOGIN} $lang{DISABLE}",
              SUBJECT  => "$lang{LOGIN} $lang{DISABLE}"
            );
          }
          else{
            next;
          }
        }

        # 9 - X days for expire
        elsif ( $user->{REPORT_ID} == 9 ){
          if ( $user->{TP_EXPIRE} == $user->{VALUE} ){
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  => "$lang{DAYS_TO_EXPIRE}: $user->{TP_EXPIRE}",
              SUBJECT  => "$lang{TARIF_PLAN} $lang{EXPIRE}"
            );
          }
          else{
            next;
          }
        }

        # 10 - TOO SMALL DEPOSIT FOR NEXT MONTH WORK
        elsif ( $user->{REPORT_ID} == 10 ){
          if ( $user->{TP_MONTH_FEE} > $user->{DEPOSIT} + $user->{CREDIT} ){
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  =>
              "$lang{SMALL_DEPOSIT_FOR_NEXT_MONTH}. $lang{DEPOSIT}: $user->{DEPOSIT} $lang{TARIF_PLAN} $user->{TP_MONTH_FEE}"
              ,
              SUBJECT  => "$lang{ERR_SMALL_DEPOSIT}"
            );
          }
          else{
            next;
          }
        }

        #Report 11
        # Small deposit fo next month activation
        elsif ( $user->{REPORT_ID} == 11 ){
          if ( 0 > $user->{DEPOSIT} ){
            my $recharge = $user->{TP_MONTH_FEE} + $user->{DEPOSIT};
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  => "$lang{SMALL_DEPOSIT_FOR_NEXT_MONTH} $lang{BALANCE_RECHARCHE} $recharge",
              SUBJECT  => "$lang{DEPOSIT_BELOW}"
            );
          }
          else{
            next;
          }
        }

        #Report 13 All service expired throught
        elsif ( $user->{REPORT_ID} == 13 && !$user->{DV_STATUS} ){
          if ( $total_daily_fee > 0
            || ($user->{EXPIRE_DAYS} && $user->{EXPIRE_DAYS} <= $user->{VALUE})){

            $debug_output .= "(Day fee: $total_daily_fee / $user->{EXPIRE_DAYS} -> $user->{VALUE} \n" if ($debug > 4);

            if ( $user->{EXPIRE_DAYS} <= $user->{VALUE} ){
              $lang{ALL_SERVICE_EXPIRE} =~ s/XX/ $user->{EXPIRE_DAYS} /;

              my $message = $lang{ALL_SERVICE_EXPIRE};
              $message .= "\n $lang{RECOMMENDED_PAYMENT}:  $user->{RECOMMENDED_PAYMENT}\n";

              %PARAMS = (
                DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
                MESSAGE  => $message,
                SUBJECT  => $lang{ALL_SERVICE_EXPIRE},
              );
            }
            else{
              next;
            }
          }
        }
        #Report 14. Notify before abon
        elsif ( $user->{REPORT_ID} == 14 ){
          if ( $user->{EXPIRE_DAYS} <= $user->{VALUE} ){
            %PARAMS = (
              DESCRIBE => $lang{REPORTS},
              MESSAGE  => "",
              SUBJECT  => $lang{DEPOSIT}
            );
          }
          else{
            next;
          }
        }
        #Report 15 15 Dv change status
        elsif ( $user->{REPORT_ID} == 15 ){
          if ( $user->{DV_STATUS} && $user->{DV_STATUS} != 3 ){
            my @service_status = ("$lang{ENABLE}", "$lang{DISABLE}", "$lang{NOT_ACTIVE}", "$lang{HOLD_UP}",
              "$lang{DISABLE}: $lang{NON_PAYMENT}", "$lang{ERR_SMALL_DEPOSIT}",
              "$lang{VIRUS_ALERT}" );
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS}",
              MESSAGE  => "Internet: $service_status[$user->{DV_STATUS}]",
              SUBJECT  => "Internet: $service_status[$user->{DV_STATUS}]"
            );
          }
        }
        # Reports 16 Next period TP
        elsif ( $user->{REPORT_ID} == 16 ){
          $Shedule->list( {
            UID        => $user->{UID},
            Y          => '',
            M          => '',
            NEXT_MONTH => 1
          } );

          my $recomended_payment = $user->{RECOMMENDED_PAYMENT};

          if ( $Shedule->{TOTAL} > 0 ){

          }

          my $message .= "\n $lang{RECOMMENDED_PAYMENT}: $recomended_payment\n";

          %PARAMS = (
            DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
            MESSAGE  => "$message",
            SUBJECT  => "$lang{ALL_SERVICE_EXPIRE}",
          );
        }
        #Custom reports
        elsif ( $user->{module}){
          my $report_module = $user->{module};
          my $load_mod = "Ureports::$report_module";
          eval " require $load_mod ";
          if($@) {
            print $@;
            exit;
          }
          $report_module =~ s/\.pm//;
          my $mod = "Ureports::$report_module";
          my $Report = $mod->new($db, $admin, \%conf);
          my $report_function = $Report->{SYS_CONF}{REPORT_FUNCTION};
          if($debug > 1) {
            print "Function: $report_function Name: $Report->{SYS_CONF}{REPORT_NAME} Tpl: $Report->{SYS_CONF}{TEMPLATE}\n";
          }

          $Report->$report_function($user);
          if($Report->{errno}) {
            print "[$Report->{errno}] $Report->{errstr}\n";
          }

          if($Report->{PARAMS}) {
            %PARAMS = %{ $Report->{PARAMS} };
          }
          else {
            next;
          }

          $PARAMS{MESSAGE_TEPLATE} = $Report->{SYS_CONF}{TEMPLATE};
        }
      }
      else{
        print "[ $user->{UID} ] $user->{LOGIN} - Don't have money account\n";
        next;
      }

      #Send reports section
      if ( scalar keys %PARAMS > 0 ){
        ureports_send_reports(
          $user->{DESTINATION_TYPE},
          $user->{DESTINATION_ID},
          $PARAMS{MESSAGE},
          {
            %{$user},
            SUBJECT   => $PARAMS{SUBJECT},
            REPORT_ID => $user->{REPORT_ID},
            UID       => $user->{UID},
            MESSAGE   => $PARAMS{MESSAGE},
            DATE      => "$ADMIN_REPORT{DATE} $TIME",
            METHOD    => 1,
            MESSAGE_TEPLATE => $PARAMS{MESSAGE_TEPLATE}
          }
        );

        if ( $debug < 5 ){
          $Ureports->tp_user_reports_update(
            {
              UID       => $user->{UID},
              REPORT_ID => $user->{REPORT_ID}
            }
          );
        }

        if ( $user->{MSG_PRICE} > 0 ){
          my $sum = $user->{MSG_PRICE};

          if ( $debug > 4 ){
            $debug_output .= " UID: $user->{UID} SUM: $sum REDUCTION: $user->{REDUCTION}\n";
          }
          else{
            $fees->take( $user, $sum, { %PARAMS } );
            if ( $fees->{errno} ){
              print "Error: [$fees->{errno}] $fees->{errstr} ";
              if ( $fees->{errno} == 14 ){
                print "[ $user->{UID} ] $user->{LOGIN} - Don't have money account";
              }
              print "\n";
            }
            elsif ( $debug > 0 ){
              $debug_output .= " $user->{LOGIN}  UID: $user->{UID} SUM: $sum REDUCTION: $user->{REDUCTION}\n" if ($debug > 0);
            }
          }
        }

        $debug_output .= "UID: $user->{UID} REPORT_ID: $user->{REPORT_ID} DESTINATION_TYPE: $user->{DESTINATION_TYPE} DESTINATION: $user->{DESTINATION_ID}\n" if ($debug > 0);

        if ( $debug < 5 ){
          $Ureports->log_add(
            {
              DESTINATION => $user->{DESTINATION_ID},
              BODY        => (length( $PARAMS{MESSAGE} ) < 500) ? $PARAMS{MESSAGE} : '-',
              UID         => $user->{UID},
              TP_ID       => $user->{TP_ID},
              REPORT_ID   => $user->{REPORT_ID},
              STATUS      => 0
            }
          );
        }
      }
    }
  }

  #our $DEBUG .= $debug_output;
  return $debug_output;
}


#**********************************************************
#
#**********************************************************
sub help{

  print << "[END]";
Ureports sender ($version).

  DEBUG=0..6           - Debug mode
  DATE="YYYY-MM-DD"    - Send date
  REPORT_IDS=[1,2,4..] - reports ids
  LOGIN=[...,]         - make reports for some logins
  TP_IDS=[...,]        - make reports for some tarif plans
  help                 - this help
[END]

  return 1;
}

1

