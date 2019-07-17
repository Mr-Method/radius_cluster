package Extreceipt;

=head1 NAME

 Extreceipt sql functions

=cut

use strict;
use parent 'dbcore';
my $MODULE = 'Extreceipt';

use Abills::Base qw/_bp/;

#**********************************************************
=head2 new($db, $admin, \%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf) = @_;

  $admin->{MODULE} = $MODULE;
  
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 list($attr)

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;
  $self->query("SELECT
      e.*,
      p.sum,
      ucp.value as phone,
      ucm.value as mail
      FROM extreceipts e
      LEFT JOIN payments p ON (p.id = e.payments_id)
      LEFT JOIN users_contacts ucp ON (ucp.uid = p.uid AND ucp.type_id=2)
      LEFT JOIN users_contacts ucm ON (ucm.uid = p.uid AND ucm.type_id=9)
      WHERE e.status = ?;",
    undef,
    { Bind => [ $attr->{STATUS} ], COLS_NAME => 1 }
  );

  return $self->{list};
}

#**********************************************************
=head2 info($payments_id)

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($id) = @_;
  $self->query("SELECT
      e.*,
      p.sum,
      ucp.value as phone,
      ucm.value as mail
      FROM extreceipts e
      LEFT JOIN payments p ON (p.id = e.payments_id)
      LEFT JOIN users_contacts ucp ON (ucp.uid = p.uid AND ucp.type_id=2)
      LEFT JOIN users_contacts ucm ON (ucm.uid = p.uid AND ucm.type_id=9)
      WHERE e.payments_id = ?;",
    undef,
    { Bind => [ $id ], COLS_NAME => 1 }
  );

  return $self->{list};
}

#**********************************************************
=head2 get_new_payments($start_id)

=cut
#**********************************************************
sub get_new_payments {
  my $self = shift;
  my ($start_id) = @_;

  $self->query("SELECT id FROM payments ORDER BY id DESC LIMIT 1;",
    undef,
    { }
  );

  my $last_id = $self->{list}[0][0];
  
  $self->query("INSERT INTO extreceipts (payments_id) SELECT id FROM payments WHERE id > ? AND id <= ? AND method IN (?);",
    'do',
    { Bind => [ $start_id, $last_id, $self->{conf}->{EXTRECEIPT_METHODS} ] }
  );

  $self->{LAST_ID} = $last_id;

  return 1;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'PAYMENTS_ID',
    TABLE        => 'extreceipts',
    DATA         => $attr
  });
  
  return 1
}


1