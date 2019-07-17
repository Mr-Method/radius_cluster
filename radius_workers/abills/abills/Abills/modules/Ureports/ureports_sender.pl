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
    $Bin . '/../Abills/',
    $Bin . '/../lib/',
    $Bin . '/../Abills/modules' );
}

my $version = 0.74;
my $debug = 0;
our (
  $db,
  %conf,
  $TIME,
  @MODULES,
  %lang,
  %ADMIN_REPORT,
  %LIST_PARAMS,
  $DATE
);

use Abills::Defs;
use Abills::Base qw(int2byte in_array sendmail parse_arguments cmd date_diff);
use Abills::Templates;
use Abills::Misc;

use Ureports::Send qw/ureports_send_reports/;

use Admins;
use Shedule;
#use Dv;
use Dv_Sessions;
#use Internet;
use Internet::Sessions;
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

#Always our for crossmodules
our $admin = Admins->new( $db, \%conf );
$admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' } );

my $Ureports = Ureports->new( $db, $admin, \%conf );
my $Fees     = Fees->new( $db, $admin, \%conf );
my $Tariffs  = Tariffs->new( $db, \%conf, $admin );
my $Shedule  = Shedule->new( $db, $admin, \%conf );
my $Sessions;
if(in_array('Internet', \@MODULES)) {
  $Sessions = Internet::Sessions->new($db, $admin, \%conf);
}
else {
  $Sessions = Dv_Sessions->new($db, $admin, \%conf);
}

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

my $debug_output = ureports_periodic_reports($argv);
print $debug_output;

#**********************************************************
=head2 ureports_periodic_reports($attr)

  Arguments:
    $attr

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

  $Tariffs->{debug} = 1 if ($debug > 6);
  my $list = $Tariffs->list( {
    REDUCTION_FEE    => '_SHOW',
    DAY_FEE          => '_SHOW',
    MONTH_FEE        => '_SHOW',
    PAYMENT_TYPE     => '_SHOW',
    EXT_BILL_ACCOUNT => '_SHOW',
    CREDIT           => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME        => 1
  } );

  $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
  $SERVICE_LIST_PARAMS{CUR_DATE} = $ADMIN_REPORT{DATE};
  my $d = (split( /-/, $ADMIN_REPORT{DATE}, 3 ))[2];
  #my $reports_type = 0;

  foreach my $tp ( @{$list} ){
    $debug_output .= "TP ID: $tp->{tp_id} DF: $tp->{day_fee} MF: $tp->{month_fee} POSTPAID: $tp->{payment_type} REDUCTION: $tp->{reduction_fee} EXT_BILL: $tp->{ext_bill_account} CREDIT: $tp->{credit}\n" if ($debug > 1);

    #Get users
    $Ureports->{debug} = 1 if ($debug > 5);

    my %users_params = (
      DATE           => '0000-00-00',
      TP_ID          => $tp->{tp_id},
      SORT           => 1,
      PAGE_ROWS      => 1000000,
      ACCOUNT_STATUS => 0,
      STATUS         => 0,
      ACTIVATE       => '_SHOW',
      REDUCTION      => '_SHOW',
      %SERVICE_LIST_PARAMS,
      MODULE         => '_SHOW',
      COLS_NAME      => 1,
      COLS_UPPER     => 1,
    );

    if(in_array('Internet', \@MODULES)) {
      $users_params{INTERNET_TP} = 1;
      $users_params{INTERNET_STATUS} = '_SHOW';
      $users_params{INTERNET_EXPIRE} = '_SHOW';
    }
    else {
      $users_params{DV_TP} = 1;
      $users_params{DV_STATUS} = '_SHOW';
    }

    my $ulist = $Ureports->tp_user_reports_list( \%users_params  );

    foreach my $user ( @{$ulist} ){
      #Check bill id and deposit
      my %PARAMS = ();
      $user->{TP_ID} = $tp->{tp_id};
      my $internet_status = $user->{DV_STATUS} || $user->{INTERNET_STATUS} || 0;
      my $internet_expire = $user->{INTERNET_EXPIRE} || 0;
      #Skip disabled user
      next if ($internet_status == 1 || $internet_status == 2 || $internet_status == 3);
      $user->{VALUE} =~ s/,/\./s;
      $debug_output .= "LOGIN: $user->{LOGIN} ($user->{UID}) DEPOSIT: $user->{deposit} CREDIT: $user->{credit} Report id: $user->{REPORT_ID} INTERNET STATUS: $internet_status $user->{DESTINATION_ID}\n" if ($debug > 3);

      if ( $user->{BILL_ID} && defined( $user->{DEPOSIT} ) ){
        #Skip action for pay opearation
        if ( $user->{MSG_PRICE} > 0 && $user->{DEPOSIT} + $user->{CREDIT} < 0 && $tp->{payment_type} == 0 ){
          $debug_output .= "UID: $user->{UID} REPORT_ID: $user->{REPORT_ID} DEPOSIT: $user->{DEPOSIT}/$user->{CREDIT} Skip action Small Deposit for sending\n" if ($debug > 0);
          next;
        }

        my $reduction_division = ($user->{REDUCTION} >= 100) ? 1 : ((100 - $user->{REDUCTION}) / 100);

        # Recomended payments
        my $total_daily_fee = 0;
        my $cross_modules_return = cross_modules_call( '_docs', {
          FEES_INFO     => 1,
          UID           => $user->{UID},
          SKIP_DISABLED => 1,
          SKIP_MODULES  => 'Ureports,Sqlcmd',
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
#              if($cross_modules_return->{$module}{abon_distribution} && ! $conf{INTERNET_FULL_MONTH}) {
#                $user->{RECOMMENDED_PAYMENT} += ($cross_modules_return->{$module}{month} / 30);
#              }
#              else {
               $user->{RECOMMENDED_PAYMENT} += $cross_modules_return->{$module}{month};
#              }
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

        if($conf{UREPORTS_ROUNDING} && $user->{RECOMMENDED_PAYMENT} > 0) {
          if(int($user->{RECOMMENDED_PAYMENT}) < $user->{RECOMMENDED_PAYMENT}) {
            $user->{RECOMMENDED_PAYMENT} = int($user->{RECOMMENDED_PAYMENT}+1);
          }
        }

        $user->{DEPOSIT} = sprintf( "%.2f", $user->{DEPOSIT} );
        if ( $total_daily_fee > 0 ){
          $user->{EXPIRE_DAYS} = int( $user->{DEPOSIT} / $reduction_division / $total_daily_fee );
        }
        else{
          #Internet expire
          $user->{EXPIRE_DAYS} = $user->{TP_EXPIRE};
        }

        $user->{EXPIRE_DATE} = POSIX::strftime( "%Y-%m-%d", localtime( time + $user->{EXPIRE_DAYS} * 86400 ) );

        #Report 1 Deposit belove and dv status active
        if ( $user->{REPORT_ID} == 1 ){
          if ( $user->{VALUE} > $user->{DEPOSIT} && !$internet_status ){
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
              $rest = ($conf{INTERNET_INTERVAL_PREPAID}) ? $Sessions->{REST}->{ $line->{interval_id} }->{ $line->{traffic_class} }  :  $Sessions->{REST}->{ $line->{traffic_class} };
              #$rest = 0;
              # if ($line->{prepaid} && $line->{prepaid} > 0
              #    && defined($line->{traffic_class})
              #    && $Sessions->{REST}
              #    && $Sessions->{REST}->{ $line->{traffic_class} }
              #    && $Sessions->{REST}->{ $line->{traffic_class} } > 0) {
              #   $rest = $Sessions->{REST}->{ $line->{traffic_class} };
              # }

              #REST MB
              $PARAMS{REST}          = $rest;
              #REST GB
              $PARAMS{REST_GB}       = sprintf("%.2f", ($rest/1024));
              $PARAMS{REST_DIMENSION}= int2byte($rest);
              $PARAMS{PREPAID}       = $line->{prepaid};

              $PARAMS{'REST_'.($line->{traffic_class} || 0)}=$rest;
              $PARAMS{'REST_DIMENSION_'. ($line->{traffic_class} || 0)}=int2byte($rest);
              $PARAMS{'PREPAID_'.($line->{traffic_class} || 0)}=$line->{prepaid} || 0;

              if ( $rest < $user->{VALUE} ){
                $PARAMS{MESSAGE} .= "================\n $lang{TRAFFIC} $lang{TYPE}: $line->{traffic_class}\n$lang{BEGIN}: $line->{interval_begin}\n"
                  . "$lang{END}: $line->{interval_end}\n"
                  . "$lang{TOTAL}: $line->{prepaid}\n"
                  . "\n $lang{REST}: "
                  . $rest . "\n================";
              }
            }

            if(! $PARAMS{MESSAGE}) {
              next;
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
          if ( $user->{CREDIT_EXPIRE} <= $user->{VALUE} ){
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  => "$lang{CREDIT} $lang{EXPIRE}",
              SUBJECT  => "$lang{CREDIT} $lang{EXPIRE}",
              CREDIT_EXPIRE_DAYS => $user->{CREDIT_EXPIRE}
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
          #if ( $user->{TP_EXPIRE} == $user->{VALUE} ){
          if ( $user->{EXPIRE_DAYS} == $user->{VALUE} ){
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
          if ( $user->{TP_MONTH_FEE} * $reduction_division > $user->{DEPOSIT} + $user->{CREDIT} ){
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  =>
              "$lang{SMALL_DEPOSIT_FOR_NEXT_MONTH}. $lang{DEPOSIT}: $user->{DEPOSIT} $lang{TARIF_PLAN} $user->{TP_MONTH_FEE}"
              ,
              SUBJECT  => $lang{ERR_SMALL_DEPOSIT}
            );
          }
          else{
            next;
          }
        }
        #Report 11 - Small deposit for next month activation with predays XX trigger
        elsif ( $user->{REPORT_ID} == 11 && $internet_expire < $user->{VALUE}){
          if ( $user->{TP_MONTH_FEE} && $user->{TP_MONTH_FEE} > $user->{DEPOSIT} ){
            my $recharge = $user->{TP_MONTH_FEE} + (($user->{DEPOSIT} < 0) ? abs($user->{DEPOSIT}) : 0) ;
            %PARAMS = (
              DESCRIBE => "$lang{REPORTS} ($user->{REPORT_ID}) ",
              MESSAGE  => "$lang{SMALL_DEPOSIT_FOR_NEXT_MONTH} $lang{BALANCE_RECHARCHE} $recharge",
              SUBJECT  => $lang{DEPOSIT_BELOW}
            );
          }
          else{
            next;
          }
        }
        #Report 13 All service expired throught
        elsif ( $user->{REPORT_ID} == 13 && !$internet_status ){
          if ($user->{EXPIRE_DAYS} && $user->{EXPIRE_DAYS} <= $user->{VALUE}){

            $debug_output .= "(Day fee: $total_daily_fee / $user->{EXPIRE_DAYS} -> $user->{VALUE} \n" if ($debug > 4);

            if ( $user->{EXPIRE_DAYS} <= $user->{VALUE} && $user->{EXPIRE_DAYS}>=0 ){
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
          if ( $internet_status && $internet_status != 3 ){
            my @service_status = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE}, $lang{HOLD_UP},
              "$lang{DISABLE}: $lang{NON_PAYMENT}", "$lang{ERR_SMALL_DEPOSIT}",
              "$lang{VIRUS_ALERT}" );

            my $message = "Internet: $service_status[$internet_status]";
            if ($internet_status == 5) {
              $message .= "\n $lang{RECOMMENDED_PAYMENT}:  $user->{RECOMMENDED_PAYMENT}\n";
            }

            %PARAMS = (
              DESCRIBE => $lang{REPORTS},
              MESSAGE  => $message,
              SUBJECT  => "Internet: $service_status[$internet_status]"
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
          if($debug > 2) {
            $Report->{debug}=1;
          }
          my $report_function = $Report->{SYS_CONF}{REPORT_FUNCTION};
          if($debug > 1) {
            print "Function: $report_function Name: $Report->{SYS_CONF}{REPORT_NAME} Tpl: $Report->{SYS_CONF}{TEMPLATE}\n";
          }

          $Report->$report_function($user, $argv);
          if($Report->{errno}) {
            print "ERROR: [$Report->{errno}] $Report->{errstr}\n";
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
            TP_ID     => $user->{TP_ID},
            MESSAGE   => $PARAMS{MESSAGE},
            DATE      => "$ADMIN_REPORT{DATE} $TIME",
            METHOD    => 1,
            MESSAGE_TEPLATE => $PARAMS{MESSAGE_TEPLATE},
            DEBUG     => $debug
          }
        );

        if ( $debug < 5 && ! $PARAMS{SKIP_UPDATE_REPORT}){
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
            $Fees->take( $user, $sum, { %PARAMS } );
            if ( $Fees->{errno} ){
              print "Error: [$Fees->{errno}] $Fees->{errstr} ";
              if ( $Fees->{errno} == 14 ){
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

