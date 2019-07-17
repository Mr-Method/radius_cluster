=head1 NAME

Quick reports for start page and other maintains

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array);

our ($db,
 %lang,
 $html,
 $admin);

#**********************************************************
=head2 form_quick_reports($attr)

=cut
#**********************************************************
sub form_quick_reports{
  #my ($attr) = @_;

  my %START_PAGE_F = ();

  my %quick_reports = (
    'last_payments'  => $lang{PAYMENTS},
    'add_users'      => $lang{REGISTRATION},
    'fin_summary'    => $lang{DEBETORS},
    'users_summary'  => $lang{USERS},
    'payments_types' => "$lang{TODAY} $lang{PAYMENT_TYPE}",
    'payments_self'  => "$lang{ADDED} $lang{PAYMENTS}",
  );

  foreach my $mod_name ( @MODULES ){
    load_module( $mod_name, $html );
    my $check_function = lc( $mod_name ) . '_start_page';

    if ( defined( &{$check_function} ) ){
      my $START_PAGE_F = &{ \&$check_function }();
      while(my ($k, $v) = each %{$START_PAGE_F}) {
        $quick_reports{"$mod_name:$k"} = $v if ($k);
      }
      %START_PAGE_F = ();
    }
  }

  if ( $FORM{show_reports} ){
    $html->{METATAGS} = templates( 'metatags' );
    print $html->header();

    if ( $quick_reports{$FORM{show_reports}} ){
      my ($mod, $fn) = split( /:/, $FORM{show_reports} );
      $fn = 'start_page_' . $mod if (!$fn);
      print &{ \&$fn }();
    }

    return 0;
  }

  my $table = $html->table(
    {
      width      => '640',
      caption    => "$lang{QUICK} $lang{REPORTS}",
      title      => [ ' ', "$lang{NAME}", '-', "$lang{SHOW}" ],
      ID         => 'QR_LIST'
    }
  );

  my @qr_arr = ();
  if ($admin->{SETTINGS} && $admin->{SETTINGS}{QUICK_REPORTS}){
    @qr_arr = split( /, /, $admin->{SETTINGS}{QUICK_REPORTS} );
  }

  foreach my $key ( sort keys %quick_reports ){
    $table->addrow(
      $html->form_input( 'QUICK_REPORTS', "$key",
        { TYPE => 'checkbox', STATE => (in_array( $key, \@qr_arr )) ? 'checked' : undef } ),
      $key,
      $quick_reports{$key},
      $html->button( "$lang{SHOW}", "qindex=4&show_reports=$key", { class => 'show' } )
    );
  }

  return $table->show();
}

#**********************************************************
=head2 start_page_add_users($attr) quick reports for start page

=cut
#**********************************************************
sub start_page_add_users{
  #my ($attr) = @_;

  my $table = $html->table(
    {
      width       => '100%',
      caption     => "$lang{REGISTRATION}",
      title_plain => [ "$lang{LOGIN}", "$lang{REGISTRATION}", "$lang{ADDRESS}", "$lang{DEPOSIT}" ],
      ID          => 'QR_REGISTRATION'
    }
  );

  my $list = $users->list( {
      LOGIN        => '_SHOW',
      REGISTRATION => '_SHOW',
      ADDRESS_FULL => '_SHOW',
      DEPOSIT      => '_SHOW',
      SORT         => 'uid',
      DESC         => 'desc',
      PAGE_ROWS    => 5,
      COLS_NAME    => 1
    } );

  foreach my $line ( @{$list} ){
    $table->addrow(
      $html->button( $line->{login}, "index=11&UID=$line->{uid}" ),
      $line->{registration},
      $line->{address_full},
      $line->{deposit}
    );
  }

  return $table->show();
}


#**********************************************************
=head2 start_page_last_payments($attr)

=cut
#**********************************************************
sub start_page_last_payments{
  #my ($attr) = @_;

  my $table = $html->table(
    {
      width       => '100%',
      caption     => "$lang{LAST_PAYMENT}",
      title_plain => [ "$lang{LOGIN}", "$lang{DATE}", "$lang{SUM}", "$lang{ADMIN}" ],
      ID          => 'LAST_PAYMENTS'
    }
  );

  my $Payments = Finance->payments( $db, $admin, \%conf );

  my $list = $Payments->list( {
      LOGIN      => '_SHOW',
      DATE       => '_SHOW',
      SUM        => '_SHOW',
      ADMIN_NAME => '_SHOW',
      SORT       => 'date',
      DESC       => 'desc',
      PAGE_ROWS  => 5,
      COLS_NAME  => 1
    } );

  foreach my $line ( @{$list} ){
    $table->addrow(
      $html->button( $line->{login}, "index=11&UID=$line->{uid}" ),
      $line->{datetime},
      $line->{sum},
      $line->{admin_name}
    );
  }

  return $table->show();
}


#**********************************************************
=head2 start_page_fin_summary($attr)

=cut
#**********************************************************
sub start_page_fin_summary{
  #my ($attr) = @_;

  my $Payments = Finance->payments( $db, $admin, \%conf );
  $Payments->reports_period_summary( );

  my $table = $html->table(
    {
      width       => '100%',
      caption     => $lang{PAYMENTS},
      title_plain => [ "$lang{PERIOD}", "$lang{COUNT}", "$lang{SUM}" ],
      ID          => 'FIN_SUMMARY',
      rows        => [
        [ $html->button( $lang{DAY}, "index=2&DATE=$DATE&search=1" ),
          $Payments->{DAY_COUNT}, $Payments->{DAY_SUM} ],
        [ $lang{WEEK}, $Payments->{WEEK_COUNT}, $Payments->{WEEK_SUM} ],
        [ $lang{MONTH}, $Payments->{MONTH_COUNT}, $Payments->{MONTH_SUM} ],
      ]
    }
  );
  my $reports = $table->show();

  return $reports;
}

#**********************************************************
=head2 start_page_payments_types($attr)

=cut
#**********************************************************
sub start_page_payments_types{
  #my ($attr) = @_;

  my $PAYMENT_METHODS = get_payment_methods();

  my $Payments = Finance->payments( $db, $admin, \%conf );
  my $list = $Payments->reports( { TYPE => 'PAYMENT_METHOD',
      INTERVAL                          => "$DATE/$DATE",
      GID                               => $admin->{GID} || undef,
      COLS_NAME                         => 1
    } );

  my $table = $html->table(
    {
      width       => '100%',
      caption     => "$lang{PAYMENT_TYPE} $DATE",
      title_plain => [ "$lang{TYPE}", "$lang{COUNT}", "$lang{SUM}" ],
      ID          => 'PAYMENTS_TYPES',
    }
  );

  foreach my $line ( @{$list} ){
    $table->addrow(
      $html->button( $PAYMENT_METHODS->{$line->{method}}, "index=2&METHOD=$line->{method}&search=1" ),
      $line->{count},
      $line->{sum},
    );
  }

  my $reports = $table->show();

  return $reports;
}

#**********************************************************
=head2 start_page_users_summary($attr)

=cut
#**********************************************************
sub start_page_users_summary{
  #my ($attr) = @_;

  $users->report_users_summary( { } );

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "$lang{USERS}",
      ID         => 'USERS_SUMMARY',
      rows       => [
        [ $html->button( $lang{TOTAL}, "index=11" ),
          $users->{TOTAL_USERS}, '' ],

        [ $html->button( $lang{DISABLE}, "index=11" ),
          $users->{DISABLED_USERS}, '' ],

        [ $html->button( $lang{DEBETORS}, "index=11&USERS_STATUS=2" ),
          $users->{DEBETORS_COUNT}, $users->{DEBETORS_SUM} ],
        [ $html->button( $lang{CREDIT}, "index=11&USERS_STATUS=5" ),
          $users->{CREDITORS_COUNT}, $users->{CREDITORS_SUM} ],
      ]
    }
  );

  return $table->show();
}


#**********************************************************
=head2 start_page_payments_self($attr)

=cut
#**********************************************************
sub start_page_payments_self{
  #my ($attr) = @_;

  my $Payments = Finance->payments( $db, $admin, \%conf );
  $Payments->list( { AID => $admin->{AID},
      DATE                          => $DATE,
      PAGE_ROWS                     => 2,
      COLS_NAME                     => 1
    } );

  $admin->info( $admin->{AID} );

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "$lang{PAYMENTS} $lang{ADDED}",
      ID         => 'TODAY_PAYMENTS',
      EXPORT     => 1,
      rows       => [
        [ $lang{DATE}, $DATE ],
        [ $lang{ADMIN}, $admin->{A_FIO} ],
        [ $lang{COUNT}, ($Payments->{TOTAL} || 0) ],
        [ $lang{TOTAL}, ($Payments->{SUM} || '0.00') ],
      ]
    }
  );

  return $table->show();
}

1
