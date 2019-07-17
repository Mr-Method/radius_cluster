package Timetracker;

=head2

  Timetracker

=cut

use strict;
use parent 'main';
my $MODULE = 'Timetracker';

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $admin->{MODULE} = $MODULE;
  $self->{db}      = $db;
  $self->{admin}   = $admin;
  $self->{conf}    = $CONF;

  return $self;
}

#**********************************************************
=head2  add()

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('timetracker', $attr);

  return $self;
}

#**********************************************************
=head2  add_element()

=cut
#**********************************************************
sub add_element {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('timetracker_element', $attr);

  return $self;
}

#**********************************************************
=head2  del() - Delete user info from all tables

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('timetracker', undef, $attr);

  return $self->{result};
}

#**********************************************************
=head2  del_element() - Delete element

=cut
#**********************************************************
sub del_element {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('timetracker_element', { ID => $id });

  return $self->{result};
}

#**********************************************************
=head2 list_element($attr) - list for element

=cut
#**********************************************************
sub list_element {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->query2(
    "SELECT id, element, priority, external_system
     FROM timetracker_element ORDER BY $SORT $DESC;",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list};
}

#**********************************************************
=head2 list_for_timetracker ($attr) - list for timetracker

=cut
#**********************************************************
sub list_for_timetracker {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  #my $PG        = ($attr->{PG})        ? $attr->{PG}             : 0;
  #my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? int($attr->{PAGE_ROWS}) : 25;

  my $WHERE = $self->search_former($attr, [ 
    [ 'AID', 'STR', 'aid', 1 ], 
    [ 'ELEMENT_ID', 'int', 'element_id', 1 ], 
    [ 'TIME_PER_ELEMENT', 'int', 'time_per_element', 1 ], 
    [ 'DATE', 'DATE', 'date', 1 ], ], 
    { WHERE => 1, });

  $self->query2(
    "SELECT aid, element_id, time_per_element, date
     FROM timetracker
     $WHERE;",
    undef,
    { COLS_NAME => 1, %$attr }
  );

  return $self->{list};
}

#**********************************************************
=head2 change_elementS($attr) -  Change element

=cut
#**********************************************************
sub change_element {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'timetracker_element',
      DATA         => $attr,
    }
  );

  return $self->{result};
}