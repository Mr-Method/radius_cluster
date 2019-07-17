=head1 NAME

  billd plugin

=head2  DESCRIBE

  Get sms status from remote server

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
BEGIN {
  unshift(@INC, '/usr/abills/Abills/modules');
}

our (
  $debug,
  %conf,
  $admin,
  $db,
  $OS
);

use Sms::Sms_Broker;
use Sms;

sms_status();


#**********************************************************
=head2 sms_status() - Request for sms status

=cut
#**********************************************************
sub sms_status {
  do 'Abills/Misc.pm';
  load_module('Sms');
  print "Sms status\n" if ($debug > 1);
  my $Sms   = Sms->new($db, $admin, \%conf);

  my $Sms_service = sms_service_connect();
  if ($Sms_service->{errno}) {
    return 0;
  }

  if($Sms_service->can('get_status')) {
    my $list = $Sms->list({ STATUS => 0, COLS_NAME => 1 });
    foreach my $line ( @$list ) {

      if($debug > 1) {
        print "ID: $line->{id} DATE: $line->{datetime}\n";
      }

      $Sms_service->get_status({ REF_ID => $line->{datetime} });

      if($debug > 1) {
        print "  STATUS: ". (defined($Sms_service->{status}) ? $Sms_service->{status} : 0) ."\n";
      }

      if (! $Sms_service->{errno}) {
        if($Sms_service->{status}) {
          $Sms->change({
            ID     => $line->{id},
            STATUS => $Sms_service->{status}
          });
        }
      }
    }
  }

  return 1;
}



1;
