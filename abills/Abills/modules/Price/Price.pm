package Price;
use strict;
use parent 'main';
our $VERSION = 0.01;
my ($admin,
    $CONF);
my ($SORT,
    $DESC,
    $PG,
    $PAGE_ROWS);

#*******************************************************************

sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db}    = $db;
  $self->{admin} = $admin;
  $self->{conf}  = $CONF;

  return $self;
}

#*******************************************************************

sub add_service {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('price_services_list', {%$attr});

  return $self;
}

sub del_service {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('price_services_list', $attr);

  return $self;
}

sub change_service {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'price_services_list',
      DATA         => $attr
    }
  );
  return $self;
}

sub show_services {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query2(
    "SELECT *
    FROM price_services_list
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;", undef, $attr
  );

  my $list = $self->{list};
  return $list;
}

sub take_service_info {

  my $self = shift;
  my ($attr) = @_;

  if ($attr->{ID}) {
    $self->query2(
      "SELECT *
      FROM price_services_list
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
    );
  }

  return $self;
}
return 1;

