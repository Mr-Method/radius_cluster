package Reports;

=head1 NAME

 Reports module

=cut

use strict;
use parent qw(dbcore);
our $VERSION = 2.01;

my ($SORT, $DESC, $PG, $PAGE_ROWS);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}


#**********************************************************
=head2 add(attr)

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('reports_wizard', { %$attr,
  	                                   DATE => 'NOW()',
      AID                                   => $self->{admin}->{AID}
  	                                  });
  return $self;
}

#**********************************************************
=head2 del($id, $attr)

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('reports_wizard', { ID => $id });

  return $self;
}

#**********************************************************
=head2 list($attr) - List of reports

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my @WHERE_RULES = ();
  my $WHERE;
  my $list;

  if (defined($attr->{GID})) {
    push @WHERE_RULES, "rw.gid='$attr->{GID}'";
  }
  if (defined($attr->{QUICK_REPORT})) {
    push @WHERE_RULES, "rw.quick_report='1'";
  }
  if (defined($attr->{SEND_MAIL})) {
    push @WHERE_RULES, "rw.send_mail='1'";
  }


  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query("SELECT rw.id, rw.name, rw.comments, rw.quick_report,
    rg.name as  group_name
    FROM reports_wizard rw
    LEFT JOIN reports_groups rg ON (rg.id=rw.gid)
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  $list = $self->{list};
  $self->query("SELECT count(id) AS total FROM reports_wizard rw $WHERE",
  undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 mk($attr) - Make report wizard result

=cut
#**********************************************************
sub mk {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $list;
  delete ($self->{COL_NAMES_ARR});

  $attr->{QUERY}=~s/%PG%/$PG/;
  $attr->{QUERY}=~s/%PAGE_ROWS%/$PAGE_ROWS/;
  $attr->{QUERY}=~s/%SORT%/$SORT/g;
  $attr->{QUERY}=~s/%DESC%/$DESC/;
  $attr->{QUERY}=~s/%PAGES%/LIMIT $PG, $PAGE_ROWS/;

  $self->query("$attr->{QUERY};", undef, $attr);
  $list = $self->{list};
  $self->{PAGE_TOTAL} = $self->{TOTAL};

  $self->{REPORT_COLS_NAME} = $self->{COL_NAMES_ARR};

  if ($attr->{QUERY_TOTAL}) {
    delete $self->{COL_NAMES_ARR};
    $self->query($attr->{QUERY_TOTAL},
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 info($attr)

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT *
     FROM reports_wizard
     WHERE id= ? ;",
   undef,
   { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}


#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self   = shift;
  my ($attr) = @_;

  $attr->{QUERY} =~ s/\\\'/\'/g;
  $attr->{QUERY_TOTAL} =~ s/\\\'/\'/g;

  $self->changes(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'reports_wizard',
      DATA            => $attr,
    }
  );

  return $self;
}

#**********************************************************
=head2 add_group($attr)

=cut
#**********************************************************
sub add_group {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('reports_groups', { %$attr });

  return $self;
}

#**********************************************************
=head2 list_groups($attr)

=cut
#**********************************************************
sub list_groups {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $WHERE;
  my $list;

  $self->query("SELECT id, name, comments, admins
    FROM reports_groups
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );

  $list = $self->{list};
  $self->query("SELECT count(id) AS total FROM reports_groups $WHERE",
  undef, { INFO => 1 });

  return $list;
}

#*******************************************************************
=head2 del_group($attr)

=cut
#*******************************************************************
sub del_group {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('reports_groups', $attr);

  return $self;
}

#*******************************************************************
=head2 info_group($attr)

=cut
#*******************************************************************
sub info_group {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT *
     FROM reports_groups
     WHERE id= ? ;",
   undef,
   { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change_group {
  my $self   = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'reports_groups',
      DATA            => $attr,
    }
  );

  return $self;
}

1
