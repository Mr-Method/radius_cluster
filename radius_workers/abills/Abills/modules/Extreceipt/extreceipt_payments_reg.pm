=head1 NAME

  Extreceipt billd plugin

=cut

use strict;
use warnings FATAL => 'all';

our (
  %conf,
  $Admin,
  $db,
  $argv,
);

my @required_conf = (
  'EXTRECEIPT_APP_ID',
  'EXTRECEIPT_SECRET',
  'EXTRECEIPT_METHODS',
  'EXTRECEIPT_GOODS_NAME',
  'EXTRECEIPT_AUTHOR',
  'EXTRECEIPT_API_URL',
 );

foreach my $key (@required_conf) {
  if (!defined($conf{$key})) {
    print "Can't find $key\n";
    return 1;
  }
}

use Extreceipt::db::Extreceipt;
use Extreceipt::API::Online_receipts;
use Conf;

my $Receipt     = Extreceipt->new($db, $Admin, \%conf);
my $Receipt_api = Online_receipts->new(\%conf);
my $Config      = Conf->new($db, $Admin, \%conf);
unless ($Receipt_api->init()) {
  print "Can't get token!\nCheck your configuration (app_id and secret).\n";
  return 1;
}

if ($argv->{CANCEL}) {
  cancel_payments($argv->{CANCEL});
}
else {
  check_receipts();
  check_payments();
  send_payments();
}

#**********************************************************
=head2 check_payments()
  Checks whether new payments appear in the payments table.
  If there are new payments, they are entered into the Receipts_main table with the status 0.
=cut
#**********************************************************
sub check_payments {

  my $start_id = $conf{EXTRECEIPT_LAST_ID} || $argv->{START} || 1;
  $Receipt->get_new_payments($start_id);
  $Config->config_add({
    PARAM   => 'EXTRECEIPT_LAST_ID',
    VALUE   => $Receipt->{LAST_ID},
    REPLACE => 1
  });
  return 1;
}

#**********************************************************
=head2 send_payments()
  Sends all payments with status 0, status changes to 1.
=cut
#**********************************************************
sub send_payments {
  my $list = $Receipt->list({ STATUS => 0 });
  foreach my $line (@$list) {
    my $command_id = $Receipt_api->payment_register($line);
    if ($command_id) {
      $Receipt->change({ PAYMENTS_ID => $line->{payments_id}, COMMAND_ID => $command_id, STATUS => 1 });
    }
  }
  return 1;
}

#**********************************************************
=head2 cancel_payments()
  Cancel payment, set status 3
=cut
#**********************************************************
sub cancel_payments {
  my ($id) = @_;
  my $info = $Receipt->info($id);
  my $command_id = $Receipt_api->payment_cancel($info->[0]);
  if ($command_id) {
    $Receipt->change({ PAYMENTS_ID => $id, CANCEL_ID => $command_id, STATUS => 3 });
  }
  return 1;
}

#**********************************************************
=head2 check_receipts()
  Checks the status of previously sent payments with status 1.
  If a check is made for them, it changes the status to 2, and fills with the ID check.
=cut
#**********************************************************
sub check_receipts {
  my $list = $Receipt->list({ STATUS => 1 });
  foreach my $line (@$list) {
    my ($fdn, $fda, $date) = $Receipt_api->get_info($line->{command_id});
    $date =~ s/T/ /;
    $date =~ s/\+.*//;
    if ($fda) {
      $Receipt->change({
        PAYMENTS_ID  => $line->{payments_id},
        FDN          => $fdn,
        FDA          => $fda,
        RECEIPT_DATE => $date,
        STATUS       => 2,
      });
    }
  }
  return 1;
}

1