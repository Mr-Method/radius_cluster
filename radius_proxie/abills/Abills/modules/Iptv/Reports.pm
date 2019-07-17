=head2 NAME

  Iptv Reports

=cut

use strict;
use warnings FATAL => 'all';

our(
  $Iptv,
  %lang,
  $html
);

#***********************************************************
=head2 iptv_report($type, $attr)

=cut
#***********************************************************
sub iptv_report{
  my ($attr) = @_;

  my $REPORT = "Module: Iptv\n";
  %LIST_PARAMS = %{ $attr->{LIST_PARAMS} } if (defined( $attr->{LIST_PARAMS} ));

  return $REPORT;
}

#**********************************************************
=head2 iptv_use_allmonthes();

=cut
#**********************************************************
sub iptv_use_allmonthes{
  $FORM{allmonthes} = 1;
  iptv_use();
  return 1;
}

#**********************************************************
=head2 iptv_use() - Iptv Reports

=cut
#**********************************************************
sub iptv_use{

  result_former(
    {
      INPUT_DATA      => $Iptv,
      FUNCTION        => 'services_reports',
      BASE_FIELDS     => 5,
      SKIP_USER_TITLE => 1,
      EXT_TITLES      => {
        id        => '#',
        service_id=> '#',
        name      => $lang{NAME},
        active    => $lang{ACTIV},
        total     => $lang{SUBSCRIBES},
        users     => $lang{USERS},
      },
      TABLE => {
        width   => '100%',
        caption => $lang{SERVICES},
        qs      => $pages_qs,
        pages   => $Iptv->{TOTAL},
        ID      => 'IPTV_SERVICES_REPORT',
        EXPORT  => 1
      },
      MAKE_ROWS => 1,
      TOTAL     => "TOTAL_USERS:USERS;TOTAL_ACTIVE_USERS:ACTIV;SUBSCRIBES:SUBSCRIBES"
    }
  );

  return 1;
}


#**********************************************************
=head2 iptv_reports_channels($attr) - Reports: channels use

=cut
#**********************************************************
sub iptv_reports_channels{
  #my ($attr) = @_;

  my $list = $Iptv->reports_channels_use( { %LIST_PARAMS, COLS_NAME => 1 } );

  if ( !defined $list || ref $list ne 'ARRAY' ){
    $html->message( 'warn', $lang{ERROR}, $lang{ERR_NOT_EXISTS} );
  };

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "$lang{CHANNELS}",
      title      => [ $lang{NUM}, $lang{NAME}, $lang{USERS}, $lang{DEBETORS} ],
      cols_align => [ 'right', 'left', 'right', 'right' ],
      qs         => $pages_qs,
      pages      => $Iptv->{TOTAL},
      ID         => 'IPTV_CHANNELS',
    }
  );
  foreach my $line ( @{$list} ){
    $table->addrow( $html->b( $line->{num} ), $line->{name}, $line->{users}, $line->{debetors} );
  }

  print $table->show();

  return 1;
}

1;