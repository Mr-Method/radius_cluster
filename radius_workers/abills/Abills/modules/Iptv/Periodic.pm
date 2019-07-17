=head1 NAME

  IPTV Periodic

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(sendmail days_in_month);
use Tariffs;

our(
  %lang,
  $Conf,
  $db,
  $admin,
  %conf,
  %ADMIN_REPORT,
  $Iptv,
  $html
);

my $Tariffs = Tariffs->new( $db, \%conf, $admin );
my $Fees = Fees->new( $db, $admin, \%conf );

#**********************************************************
=head2 iptv_daily_screen_fees($attr)

=cut
#**********************************************************
#sub iptv_daily_screen_fees{
#  my ($attr) = @_;
#
#  $debug = $attr->{DEBUG} || 0;
#  my $debug_output = '';
#  #my $DOMAIN_ID = $attr->{DOMAIN_ID} || 0;
#
#  if ( $attr->{USERS_WARNINGS_TEST} ){
#    return $debug_output;
#  }
#
#  $Iptv->{debug} = 1 if ($debug > 6);
#
#  my $tp_list = $Iptv->screens_list(
#    {
#      NUM       => '_SHOW',
#      DAY_FEE   => '_SHOW',
#      FILTER_ID => '_SHOW',
#      TP_ID     => '_SHOW',
#      COLS_NAME => 1
#    }
#  );
#
#  foreach my $tp ( @$tp_list ){
#    if ( $tp->{day_fee} > 0 ){
#      $Iptv->{debug} = 1 if ($debug > 6);
#      my $ulist = $Iptv->users_screens_list(
#        {
#          TP_ID     => $tp->{tp_id},
#          COLS_NAME => 1
#        }
#      );
#    }
#  }
#
#  $DEBUG .= $debug_output;
#  return $debug_output;
#}

#**********************************************************
=head2 iptv_daily_fees($attr)

=cut
#**********************************************************
sub iptv_daily_fees{
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';

  my $DOMAIN_ID = $attr->{DOMAIN_ID} || 0;
  if ( $attr->{USERS_WARNINGS_TEST} ){
    return $debug_output;
  }

  $debug_output .= "Iptv: Daily periodic fees\n" if ($debug > 1);
  $LIST_PARAMS{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID});
  $LIST_PARAMS{DOMAIN_ID} = $DOMAIN_ID;
  my %USERS_LIST_PARAMS = (REGISTRATION => "<$ADMIN_REPORT{DATE}");
  $USERS_LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{GID} = $attr->{GID} if ($attr->{GID});

  #$USERS_LIST_PARAMS{ACTIVE_DAY_FEE} = 1;
  $Tariffs->{debug} = 1 if ($debug > 6);

  my $list = $Tariffs->list(
    {
      %LIST_PARAMS,
      TP_NAME      => '_SHOW',
      MODULE       => 'Iptv',
      DAY_FEE      => '_SHOW',
      FEES_METHOD  => '_SHOW',
      PAYMENT_TYPE => '_SHOW',
      NEW_MODEL_TP => 1,
      COLS_NAME    => 1
    }
  );
  foreach my $tp ( @{$list} ){

    if ( $tp->{day_fee} > 0 ){
      $Iptv->{debug} = 1 if ($debug > 6);
      my $ulist = $Iptv->user_list({
        ACTIVATE       => "<=$ADMIN_REPORT{DATE}",
        EXPIRE         => "0000-00-00,>$ADMIN_REPORT{DATE}",
        LOGIN_STATUS   => 0,
        SERVICE_STATUS => 0,
        DELETED        => 0,
        DEPOSIT        => '_SHOW',
        CREDIT         => '_SHOW',
        BILL_ID        => '_SHOW',
        REDUCTION      => '_SHOW',
        TP_ID          => $tp->{tp_id},
        %USERS_LIST_PARAMS,
        COLS_NAME      => 1
      });

      foreach my $u ( @{$ulist} ){
        my %user = (
          UID     => $u->{uid},
          BILL_ID => $u->{bill_id}
        );
        my %PARAMS = (
          DESCRIBE => "Tv: $lang{DAY_FEE_SHORT} $tp->{name} ($tp->{tp_id})",
          DATE     => "$ADMIN_REPORT{DATE} $TIME",
          METHOD   => ($tp->{fees_method}) ? $tp->{fees_method} : 1
        );
        if ( $tp->{payment_type} || $u->{deposit} + $u->{credit} > 0 ){
          $Fees->take( \%user, $tp->{day_fee}, \%PARAMS );
          $debug_output .= "UID: $u->{uid} SUM: $tp->{day_fee} REDUCTION: $u->{reduction}\n" if ($debug > 0);
        }
      }
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}

#**********************************************************
=head2 iptv_monthly_next_tp($attr) - Change tp in next period

=cut
#**********************************************************
sub iptv_monthly_next_tp{
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';

  $debug_output = "Iptv - Change tp to next tp\n" if ($debug > 1);
  $Tariffs->{debug} = 1 if ($debug > 6);
  my %USERS_LIST_PARAMS = ();
  my $START_PERIOD_DAY = ($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} : 1;
  my %tp_list = ();
  my $list = $Tariffs->list(
    {
      MODULE       => 'Iptv',
      NEW_MODEL_TP => 1,
      COLS_NAME    => 1
    }
  );

  foreach my $tp ( @{$list} ){
    $tp_list{ $tp->{id} } = $tp->{tp_id};
  }

  my $tp_list = $Tariffs->list(
    {
      NEXT_TARIF_PLAN => '>0',
      CREDIT          => '_SHOW',
      NEXT_TP_ID      => '_SHOW',
      NEW_MODEL_TP    => 1,
      MODULE          => 'Iptv',
      COLS_NAME       => 1
    }
  );

  my %tp_ages = ();
  foreach my $tp_info (@$tp_list) {
    $tp_ages{$tp_info->{id}}=$tp_info->{age};
  }

  my ($y, $m, $d) = split( /-/, $ADMIN_REPORT{DATE}, 3 );
  my $date_unixtime = POSIX::mktime( 0, 0, 0, $d, ($m - 1), $y - 1900, 0, 0, 0 );
  my %CHANGED_TPS = ();

  foreach my $tp_info ( @{$tp_list} ){
    $Iptv->{debug} = 1 if ($debug > 6);
    my $ulist = $Iptv->user_list(
      {
        ACTIVATE       => "<=$ADMIN_REPORT{DATE}",
        EXPIRE         => "0000-00-00,>$ADMIN_REPORT{DATE}",
        IPTV_EXPIRE    => "0000-00-00,>$ADMIN_REPORT{DATE}",
        SERVICE_STATUS => 0,
        LOGIN_STATUS   => 0,
        TP_ID          => $tp_info->{tp_id},
        SORT           => 1,
        PAGE_ROWS      => 1000000,
        DELETED        => 0,
        LOGIN          => '_SHOW',
        REDUCTION      => '_SHOW',
        DEPOSIT        => '_SHOW',
        CREDIT         => '_SHOW',
        COMPANY_ID     => '_SHOW',
        IPTV_EXPIRE    => '_SHOW',
        COLS_NAME      => 1,
        %USERS_LIST_PARAMS
      }
    );
    foreach my $u ( @{$ulist} ){
      my %user = (
        ID             => $u->{id},
        LOGIN          => $u->{login},
        UID            => $u->{uid},
        REDUCTION      => $u->{reduction},
        ACTIVATE       => $u->{activate},
        DEPOSIT        => $u->{deposit},
        CREDIT         => ($u->{credit} > 0) ? $u->{credit} : $tp_info->{credit},
        COMPANY_ID     => $u->{company_id},
        SERVICE_STATUS => $u->{service_status},
        EXPIRE         => $u->{iptv_expire},
        EXT_DEPOSIT    => ($u->{ext_deposit}) ? $u->{ext_deposit} : 0,
      );

      my $expire = undef;

      if (!$CHANGED_TPS{ $user{UID} }
        && ((!$tp_info->{age} && ($d == $START_PERIOD_DAY) || $user{ACTIVATE} ne '0000-00-00')
        || ($tp_info->{age} && $user{EXPIRE} eq $ADMIN_REPORT{DATE}) )) {

        if ($user{EXPIRE} ne '0000-00-00') {
          if ($user{EXPIRE} eq $ADMIN_REPORT{DATE}) {
            if (!$tp_ages{$tp_info->{id}}) {
              $expire = '0000-00-00';
            }
            else {
              my $next_age = $tp_ages{$tp_info->{id}};
              $expire = POSIX::strftime("%Y-%m-%d",
                localtime(POSIX::mktime(0, 0, 0, $d, $m, ($y - 1900), 0, 0, 0) + $next_age * 86400));
            }
          }
          else {
            next;
          }
        }
        elsif ($user{ACTIVATE} ne '0000-00-00') {
          my ($activate_y, $activate_m, $activate_d) = split( /-/, $user{ACTIVATE}, 3 );
          my $active_unixtime = POSIX::mktime( 0, 0, 0, $activate_d, $activate_m - 1, $activate_y - 1900, 0, 0, 0 );
          if ($date_unixtime - $active_unixtime < 31 * 86400) {
            next;
          }
        }
        $debug_output .= " Login: $user{LOGIN} ($user{UID}) ID: $user{ID} ACTIVATE: $user{ACTIVATE} TP_ID: $tp_info->{id} ($tp_list{ $tp_info->{id} }) -> $tp_info->{next_tp_id} ($tp_list{ $tp_info->{next_tp_id} })\n";
        $CHANGED_TPS{ $user{ID} } = 1;

        $Iptv->user_change({
          ID     => $user{ID},
          STATUS => 0,
          TP_ID  => $tp_list{ $tp_info->{next_tp_id} }
        });

        if (!$Iptv->{errno}) {
          iptv_account_action(
            {
              change => 1,
              UID    => $user{UID},
              ID     => $user{ID},
              TP_ID  => $tp_info->{next_tp_id},
              EXPIRE => $expire
            }
          );
        }
      }
    }
  }

  return $debug_output;
}

#**********************************************************
=head2 iptv_monthly_fees($attr) -  Monthly periodic

  Check screens pay
  Ceeck channels pay


=cut
#**********************************************************
sub iptv_monthly_fees{
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;

  my $debug_output = '';
  $debug_output .= "Iptv - Monthly periodic payments\n" if ($debug > 1);
  my $START_PERIOD_DAY = ($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} : 1;

  #Change TP to next TP
  $debug_output .= iptv_monthly_next_tp( $attr );
  #require Users;
  #Users->import();

  $LIST_PARAMS{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID});
  my %USERS_LIST_PARAMS = (
    ACTIVATE  => "<=$ADMIN_REPORT{DATE}",
    EXPIRE    => "0000-00-00,>$ADMIN_REPORT{DATE}",
    PAGE_ROWS => 1000000,
  );

  $USERS_LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{EXT_BILL} = 1 if ($conf{BONUS_EXT_FUNCTIONS});
  #my $users = Users->new( $db, $admin, \%conf );

  #close period Fees
  if ( $conf{IPTV_CLOSE_PERIOD} ){
    $Conf->config_info( { PARAM => 'IPTV_CLOSED_PERIOD' } );
    if ( $Conf->{VALUE} ne '1' ){
      $debug_output .= "Period not closed\n" if ($debug > 1);
      $DEBUG .= $debug_output;
      return $debug_output;
    }
  }

  my %FEES_METHODS = %{ get_fees_types( { SHORT => 1 } ) };
  $Tariffs->{debug} = 1 if ($debug > 6);
  my $list = $Tariffs->list({
    %LIST_PARAMS,
    MODULE             => 'Iptv',
    MONTH_FEE          => '_SHOW',
    MIN_USE            => '_SHOW',
    PAYMENT_TYPE       => '_SHOW',
    POSTPAID_MONTH_FEE => '_SHOW',
    REDUCTION_FEE      => '_SHOW',
    FEES_METHOD        => '_SHOW',
    EXT_BILL_ACCOUNT   => '_SHOW',
    FILTER_ID          => '_SHOW',
    ABON_DISTRIBUTION  => '_SHOW',
    CREDIT             => '_SHOW',
    COLS_NAME          => 1,
    NEW_MODEL_TP       => 1
  });

  $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
  my ($y, $m, $d) = split( /-/, $ADMIN_REPORT{DATE}, 3 );
  $m--;

  my $date_unixtime = POSIX::mktime( 0, 0, 0, $d, $m, $y - 1900, 0, 0, 0 );

  #Get Preview month begin end
  if ( $m == 0 ){
    $m = 12;
    $y--;
  }

  $m = sprintf( "%02.d", $m );
  my $days_in_month = days_in_month( { DATE => "$y-$m-01" } );
  #my $pre_month_begin = "$y-$m-01";
  #my $pre_month_end = "$y-$m-$days_in_month";

  foreach my $tp ( @{$list} ){
    my $TP_ID = $tp->{tp_id};
    my $min_use = $tp->{min_use};
    my $postpaid = $tp->{payment_type};
    my $tp_postpaid = $tp->{postpaid_monthly_fee};
    my $month_fee = $tp->{month_fee};
    my $TP_NUM = $tp->{id};

    if ( $d != $START_PERIOD_DAY && ! $tp->{abon_distribution}){
      $debug_output .= "Next\n" if ($debug > 1);
      $DEBUG .= $debug_output;
      next;
    }

    $debug_output .= "TP ID: $TP_NUM MF: $month_fee POSTPAID: $postpaid REDUCTION: $tp->{reduction_fee} EXT_BILL_ID: $tp->{ext_bill_account} CREDIT: $tp->{credit} MIN_USE: $min_use\n" if ($debug > 1);
    $Iptv->{debug} = 1 if ($debug > 6);

    # uid -> [ { SUM      =>
    #            DESCRIBE =>
    #            } ]
    my %users_services = ();

    $debug_output .= iptv_channels_fees({
      %USERS_LIST_PARAMS,
      TP             => $tp,
      DEBUG          => $debug,
      USERS_SERVICES => \%users_services,
    });

    $debug_output .= iptv_screen_fees({
      %USERS_LIST_PARAMS,
      TP             => $tp,
      DEBUG          => $debug,
      USERS_SERVICES => \%users_services,
    });

    #Monthfee & min use
    if ($tp->{abon_distribution}) {
      $month_fee = $month_fee / $days_in_month;
    }

    my $ulist_main = $Iptv->user_list({
      LOGIN          => '_SHOW',
      ACTIVATE       => "<=$ADMIN_REPORT{DATE}",
      EXPIRE         => "0000-00-00,>$ADMIN_REPORT{DATE}",
      SERVICE_STATUS => "0;5",
      LOGIN_STATUS   => 0,
      SERVICE_STATUS => '_SHOW',
      DEPOSIT        => '_SHOW',
      CREDIT         => '_SHOW',
      BILL_ID        => '_SHOW',
      REDUCTION      => '_SHOW',
      TP_ID          => $TP_ID,
      SORT           => 1,
      PAGE_ROWS      => 1000000,
      COLS_NAME      => 1,
      %USERS_LIST_PARAMS
    });

    foreach my $u ( @{$ulist_main} ){
      $debug_output .= " Login: $u->{login} ($u->{uid})  TP_ID: $u->{tp_id} Fees: $tp->{month_fee} REDUCTION: $u->{reduction}  $u->{deposit} $u->{credit}\n" if ($debug > 3);
      my %user = (
        ID          => $u->{id},
        LOGIN       => $u->{login},
        UID         => $u->{uid},
        BILL_ID     => ($tp->{ext_bill_account} > 0) ? $u->{ext_bill_id} : $u->{bill_id},
        REDUCTION   => ($tp->{reduction_fee}) ? $u->{reduction} : 0,
        ACTIVATE    => $u->{activate},
        DEPOSIT     => $u->{deposit},
        CREDIT      => ($u->{credit} > 0) ? $u->{credit} : $tp->{credit},
        IPTV_STATUS => $u->{service_status},
      );

      my $total_sum = 0;
      if ( $month_fee > 0 || $min_use > 0 ){
        my %FEES_DSC = (
          MODULE            => "Iptv",
          SERVICE_NAME      => $lang{TV},
          TP_ID             => $tp->{id},
          TP_NAME           => $tp->{name},
          FEES_PERIOD_MONTH => $lang{MONTH_FEE_SHORT},
          FEES_METHOD       => $FEES_METHODS{ $tp->{fees_method} }
        );

        #Check bill ID and deposit
        if ( !$user{BILL_ID} && !defined( $user{DEPOSIT} ) ){
          print "[ $user{UID} ] $user{LOGIN} - Don't have money account\n";
          next;
        }

        #Month Fee ====
        push @{ $users_services{ $u->{uid} } },
          {
            SUM      => $month_fee,
            DESCRIBE => fees_dsc_former( \%FEES_DSC )
          };

        #If deposit is above-zero or TARIF PALIN is POST PAID or PERIODIC PAYMENTS is POSTPAID
        if ( $postpaid == 1
          || $user{DEPOSIT} + $user{CREDIT} > 0
          || $tp_postpaid == 1 )
        {
          if ( $conf{IPTV_CLOSE_PERIOD} ){

          }
          #begin of month fee
          elsif ( $user{ACTIVATE} eq '0000-00-00' && $d != $START_PERIOD_DAY && ! $tp->{abon_distribution} ){
            next;
          }
          # If activation set to monthly Fees taken throught 30 days
          elsif ( $user{ACTIVATE} ne '0000-00-00' && ! $tp->{abon_distribution}){
            my ($activate_y, $activate_m, $activate_d) = split( /-/, $user{ACTIVATE}, 3 );
            my $active_unixtime = POSIX::mktime( 0, 0, 0, $activate_d, ($activate_m - 1), $activate_y - 1900, 0, 0,
              0 );

            #Block small deposit
            if ( $tp->{FIXED_FEES_DAY} && ($d != $activate_d || ($d != $START_PERIOD_DAY && $activate_d > 28)) ){
              next;
            }
            elsif ( $date_unixtime - $active_unixtime < 30 * 86400 ){
              next;
            }
            else{
              next;
            }
          }
        }
        #Block negative
        elsif ( !$tp->{small_deposit_action} ){
          $debug_output .= "Block negative  Login: $u->{login} // $user{DEPOSIT} + $user{CREDIT} > 0\n";
          iptv_account_action(
            {
              NEGDEPOSIT => 1,
              FILTER_ID  => $tp->{filter_id},
              ID         => $user{ID},
              UID        => $user{UID},
              LOGIN      => $user{LOGIN},
            }
          );
          next;
        }

        #Block small deposit
        if (
          iptv_neg_deposti_action({
            TP       => $tp,
            USER     => $u,
            SERVICES => $users_services{ $u->{uid} }
          })
        )
        {
          iptv_account_action({
            NEGDEPOSIT  => 1,
            FILTER_ID => $tp->{filter_id},
            ID        => $user{ID},
            UID       => $user{UID},
            LOGIN     => $user{LOGIN},
          });

          $debug_output .= " SMALL_DEPOSIT_BLOCK." if ($debug > 3);
          next;
        }
      }

      #Get fees
      my $ret = get_service_fee(
        \%user,
        \%users_services,
        {
          DATE   => $ADMIN_REPORT{DATE},
          METHOD => 1,
          DEBUG  => $debug
        }
      );

      if ( $ret ){
        if ( $debug > 0 ){
          $debug_output .= " $user{LOGIN} UID: $user{UID} SUM: $total_sum REDUCTION: $user{REDUCTION} CHANGE ACTIVATE\n";
        }
        #          $users->change(
        #                    $user{UID},
        #                    {
        #                      UID      => $user{UID},
        #                      ACTIVATE => $ADMIN_REPORT{DATE}
        #                    });
      }
    }
  }

  if ( $conf{IPTV_CLOSE_PERIOD} ){
    $Conf->config_del( 'IPTV_CLOSED_PERIOD' );
    $Conf->config_add(
      {
        PARAM => 'IPTV_CLOSED_PERIOD',
        VALUE => "$DATE $TIME"
      }
    );
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}

#**********************************************************
=head2 iptv_users_warning_messages()

=cut
#**********************************************************
sub iptv_users_warning_messages {
  my %LIST_PARAMS = (USERS_WARNINGS => 'y');
  my $list = $Iptv->user_list( { %LIST_PARAMS } );
  $ADMIN_REPORT{USERS_WARNINGS} = sprintf( "%-14s| %4s|%-20s| %9s| %8s|\n", $lang{LOGIN}, 'TP', $lang{TARIF_PLAN}, $lang{DEPOSIT},
    $lang{CREDIT} ) . "---------------------------------------------------------------\n";
  return 0 if ($Iptv->{TOTAL} < 1);
  my %USER_INFO = ();
  foreach my $line ( @{$list} ){

    #u.id, u.email, u.tp_id, u.credit, u.deposit, tp.name, tp.uplimit
    $USER_INFO{LOGIN} = $line->[0];
    $USER_INFO{TP_NAME} = $line->[5];
    $USER_INFO{TP_ID} = $line->[2];
    $USER_INFO{DEPOSIT} = $line->[4];
    $USER_INFO{CREDIT} = $line->[3];
    my $email = ((!defined( $line->[1] )) || $line->[1] eq '') ? "$line->[0]\@$conf{USERS_MAIL_DOMAIN}" : "$line->[1]";
    $ADMIN_REPORT{USERS_WARNINGS} .= sprintf( "%-14s| %4d|%-20s| %9.4f| %8.2f|\n", $USER_INFO{LOGIN}, $USER_INFO{TP_ID},
      $USER_INFO{TP_NAME}, $USER_INFO{DEPOSIT}, $USER_INFO{CREDIT} );
    my $message = $html->tpl_show( _include( 'iptv_users_warning_messages', 'Iptv' ), \%USER_INFO,
      { notprint => 'yes' } );
    sendmail( "$conf{ADMIN_MAIL}", "$email", "???????????? ??????? ??????????.", "$message", "$conf{MAIL_CHARSET}",
      "2 (High)" );
  }
  $ADMIN_REPORT{USERS_WARNINGS} .= "---------------------------------------------------------------
$lang{TOTAL}: $Iptv->{TOTAL}\n";
}

#***********************************************************
=head2 iptv_sheduler($type, $action, $uid)

   Arguments:
     $type    - Action type
     $action  - Actin value
     $uid     - UID
     $attr
       DATE

=cut
#***********************************************************
sub iptv_sheduler{
  my ($type, $action, $uid, $attr) = @_;

  my %info = ();
  my ($service_id, $action_) = split( /:/, $action );
  $Iptv->user_info( $service_id );

  if ( $type eq 'tp' ){
    my $service_list;
    if($conf{IPTV_TRANSFER_SERVICE}) {
      $service_list = iptv_transfer_service($Iptv);
    }

    $Iptv->user_change(
      {
        ID    => $service_id,
        UID   => $uid,
        TP_ID => $action_
      }
    );

    $info{change} = 1;
    $info{UID}    = $uid;
    $info{TP_ID}  = $action_;
    $info{ID}     = $service_id;
    $Iptv->{TP_ID}= $action_;
    if ( iptv_account_action( { %info, CHANGE_TP => 1 } ) ){
      _error_show($Iptv);
    }

    # Transfer service
    if($service_list) {
      iptv_transfer_service($Iptv, {
          SERVICE_LIST => $service_list
        });
    }


    my $d  = (split(/-/, $ADMIN_REPORT{DATE}, 3))[2];
    my $START_PERIOD_DAY = $conf{START_PERIOD_DAY} || 1;
    $FORM{RECALCULATE}= 0;

    if ($Iptv->{errno}) {
      return $Iptv->{errno};
    }
    else {
      if ($Iptv->{TP_INFO}->{ABON_DISTRIBUTION} || $d == $START_PERIOD_DAY) {
        $Iptv->{TP_INFO}->{MONTH_FEE} = 0;
      }
      $user = undef;
      $FORM{RECALCULATE} = 1;
      service_get_month_fee($Iptv, {
        QUITE        => 1,
        SHEDULER     => 1,
        SERVICE_NAME => $lang{TV},
        DATE         => $attr->{DATE}
      });
    }
  }
  #Set channel
  elsif ( $type eq 'channels' ){
    return 0 if ($action eq '');
    $action_          =~ s/;/, /g;
    $FORM{IDS}        = $action_;
    $LIST_PARAMS{UID} = $uid;
    $FORM{change_now} = 1;
    if ( !$Iptv->{errno} ){
      iptv_user_channels( { QUIET => 1, SERVICE_INFO => $Iptv } );
    }
    else{
      print "!! UID: $uid ID: $service_id / $Iptv->{errno}\n";
    }
    #iptv_user_channels( { QUIET => 1, SERVICE_INFO => $Iptv } );
  }
  elsif ( $type eq 'status' ){
    $Iptv->user_change({
      ID      => $service_id,
      UID     => $uid,
      DISABLE => $action_
    });

    iptv_account_action( { %info, CHANGE_TP => 1 }  );
  }

  return 1;
}


1;