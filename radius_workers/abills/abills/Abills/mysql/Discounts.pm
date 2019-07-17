=head1 NAME

  Discounts - module for discounts

=head1 SYNOPSIS

  use Discounts;
  my $Discounts = Discounts->new($db, $admin, \%conf);

=cut

package Discounts;

use strict;
use parent qw(main);

my ($admin, $CONF);

#*******************************************************************
=head2 function new()

=cut
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

#**********************************************************
=head2 add_discount() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub add_discount {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('discounts_discounts', {%$attr});

  return $self;
}

#*******************************************************************

=head2 function list_discount() - get list of all discounts

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Discounts->list_discount({ COLS_NAME => 1});

=cut

#*******************************************************************
sub list_discount {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query2(
    "SELECT * FROM discounts_discounts
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
   FROM discounts_discounts",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************

=head2 function info_discount() - get information about discount

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $disc_info = $Discounts->info_discount({ ID => 1 });

=cut

#*******************************************************************
sub info_discount {
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
      "SELECT * FROM discounts_discounts
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#*******************************************************************

=head2 function change_discount() - change discount's information in datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Discounts->change_discount({
      ID     => 1,
      SIZE   => 10,
      NAME   => 'TEST'
    });


=cut

#*******************************************************************
sub change_discount {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'discounts_discounts',
      DATA         => $attr
    }
  );

  return $self;
}

#*******************************************************************

=head2 function delete_discount() - delete discount

  Arguments:
    $attr

  Returns:

  Examples:
    $Discounts->delete_discount( {ID => 1} );

=cut

#*******************************************************************
sub delete_discount {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('discounts_discounts', $attr);

  return $self;
}


#**********************************************************
=head2 user_discounts() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub user_discounts_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query2( "SELECT dd.name,
       dud.date,
       dd.size,
       dd.comments,
       dd.id
     FROM discounts_discounts dd
     LEFT JOIN discounts_user_discounts dud ON (dud.discount_id = dd.id AND dud.uid='$attr->{UID}')
     GROUP BY dd.id
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 discount_user_change($attr)

=cut
#**********************************************************
sub discount_user_change{
  my $self = shift;
  my ($attr) = @_;

  $self->discounts_user_del( $attr );

  if ( $attr->{IDS} ){
    my @ids_arr = split( /, /, $attr->{IDS} || '' );
    my @MULTI_QUERY = ();

    for ( my $i; $i <= $#ids_arr; $i++ ){
      my $id = $ids_arr[$i];

      push @MULTI_QUERY, [
          $attr->{ 'UID' },
          $id
        ];
    }

    $self->query2( "INSERT INTO discounts_user_discounts (uid, discount_id, date)
        VALUES (?, ?, curdate());",
      undef,
      { MULTI_QUERY => \@MULTI_QUERY } );
  }

  return $self;
}

#**********************************************************
# user_del()
#**********************************************************
sub discounts_user_del{
  my $self = shift;
  my ($attr) = @ _;

  $self->query_del( 'discounts_user_discounts', undef, { uid => $attr->{UID},
    } );

  # $self->{admin}->action_add( $attr->{UID}, "", { TYPE => 10 } );

  return $self;
}

1