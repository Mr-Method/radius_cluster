use strict;
use warnings FATAL => 'all';

use Storage;
use Fees;

our ($db,
  %conf,
  %lang,
  $html,
  %permissions,
  %ADMIN_REPORT,
  %err_strs);

our Storage $Storage;
our Fees $fees;

#***********************************************************
=head2 storage_monthly_fees($attr)

=cut
#***********************************************************
sub storage_monthly_fees{
  #my ($attr) = @_;

  $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});

  my $d = (split( /-/, $ADMIN_REPORT{DATE}, 3 ))[2];

  if ( $d == 1 ) {
    my $list = $Storage->storage_rent_fees( { COLS_NAME => 1 } );

    foreach my $line ( @{$list} ) {
      $users->{BILL_ID} = $line->{bill_id};
      $users->{UID} = $line->{uid};
      $line->{rent_price} = $line->{rent_price} * $line->{count};

      $fees->take( $users, $line->{rent_price}, { DESCRIBE => "$lang{PAY_FOR_RENT} $line->{article_name}" } );

      if ( $fees->{errno} ) {
        $html->message( 'err', $lang{ERROR}, "[$fees->{errno}] $err_strs{$fees->{errno}}" );
      }
    }
  }

  if ( $d == 1 ) {
    my $list = $Storage->storage_by_installments_fees( { COLS_NAME => 1 } );

    foreach my $line ( @{$list} ) {

      $users->{BILL_ID} = $line->{bill_id};
      $users->{UID} = $line->{uid};
      my $total_sum = $line->{amount_per_month} * $line->{count};

      $fees->take( $users, $total_sum, { DESCRIBE => "$lang{BY_INSTALLMENTS} $line->{article_name}" } );

      if ( $fees->{errno} ) {
        $html->message( 'err', $lang{ERROR}, "[$fees->{errno}] $err_strs{$fees->{errno}}" );
      }
      else{
        $Storage->storage_installation_change({
          ID => $line->{id},
          MONTHES => $line->{monthes} - 1,
        });
      }
    }
  }

  return 1;
}



1;