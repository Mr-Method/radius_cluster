package Dom;
=name2
  Dom

=VERSION

  VERSION = 0.01
=cut

use strict;
use warnings FATAL => 'all';

use parent 'main';
my $MODULE = 'Dom';

use Dom;

my $admin;
my $CONF;
my $SORT      = 1;
my $DESC      = '';
my $PG        = 1;
my $PAGE_ROWS = 25;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $admin->{MODULE} = $MODULE;

  $self->{db}    = $db;
  $self->{admin} = $admin;
  $self->{conf}  = $CONF;

  return $self;
}

#**********************************************************
=head2 list($attr) - List user info and status

  Arguments:
    $attr

  Returns
    array_of_hash

=cut
#**********************************************************
sub list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();
  my $WHERE =  $self->search_former($attr, [
    [ 'FIO',            'STR', 'pi.fio',           1],
    [ 'ADDRESS_BUILD',  'INT', 'pi.address_build', 1],
    [ 'UID',            'INT', 'pi.uid',           1],
    [ 'CITY',           'STR', 'pi.city',          1],
    [ 'COMPANY_ID',     'INT', 'u.company_id',     1],
    [ 'DISABLE',        'INT', 'u.disable',        1],
    [ 'ADDRESS_FLAT',   'STR', 'pi.address_flat',  1],
    [ 'CREDITOR',       'INT', 'creditor', "IF(u.credit>0, 1, 0) AS creditor ",  1],
    [ 'DEBETOR',        'INT', 'debetor', "IF(IF(company.id IS NULL, b.deposit, cb.deposit)<0, 1, 0) AS debetor", 1],
    [ 'ADDRESS_STREET', 'STR', 'pi.address_street',  1],
    ],
  {
    WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES
  });
  $self->query2("SELECT $self->{SEARCH_FIELDS} pi.email
     FROM users_pi pi
      LEFT JOIN users u ON (pi.uid=u.uid)
      LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN companies company ON  (u.company_id=company.id)
      LEFT JOIN bills cb ON (company.bill_id=cb.id)
    $WHERE
      GROUP BY pi.uid
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  my $list = $self->{list};

  $self->query2("SELECT COUNT(*) AS total
     FROM users_pi pi
     $WHERE;",
     undef, {INFO => 1 }
  );
  return $list;
}

1