package Tags;

=head2

  Tags

=cut

use strict;
use parent qw(dbcore);
my $MODULE = 'Tags';

#**********************************************************
# Init
#**********************************************************
sub new{
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = { };
  bless( $self, $class );

  $admin->{MODULE} = $MODULE;
  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head2 info($id) TAG information

=cut
#**********************************************************
sub info{
  my $self = shift;
  my ($id) = @_;

  $self->query( "SELECT * FROM tags WHERE id = ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}


#**********************************************************
=head2 add($attr)

=cut
#**********************************************************
sub add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'tags', $attr );
  $self->{admin}->system_action_add( "TAG_ID:$self->{INSERT_ID}", { TYPE => 1 } );

  return $self;
}

#**********************************************************
=head2 change()

=cut
#**********************************************************
sub change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'tags',
      DATA            => $attr,
      EXT_CHANGE_INFO => "TAG_ID:$attr->{ID}"
    }
  );

  return $self->{result};
}

#**********************************************************
=head2 del($id); Delete user info from all tables

=cut
#**********************************************************
sub del{
  my $self = shift;
  my ($id) = @_;

  $self->query_del( 'tags', { ID => $id } );

  $self->{admin}->system_action_add( "TAG_ID:$id", { TYPE => 10 } );
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  #my $PG        = ($attr->{PG})        ? $attr->{PG}             : 0;
  #my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? int($attr->{PAGE_ROWS}) : 25;

  my $WHERE = $self->search_former( $attr, [
      [ 'NAME', 'STR', 'name', 1 ],
      [ 'COMMENTS', 'STR', 'comments', 1 ],
      [ 'PRIORITY', 'int', 'priority', 1 ],
      [ 'ID', 'INT', 'id', ],
    ],
    { WHERE => 1,
    }
  );

  $self->query( "SELECT $self->{SEARCH_FIELDS} id
     FROM tags
     $WHERE
      ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 user_list($attr)

=cut
#**********************************************************
sub tags_user{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{EXT_TABLES} = '';

  my $WHERE = $self->search_former( $attr, [
      #['FIO',        'STR', 'pi.fio',           ],
      [ 'TAG_ID', 'INT', 't.id', ],
      [ 'LAST_ABON', 'INT', 'tu.date', ],
      #['UID',        'INT', 'tu.uid',            ],
     ['USERS_SUM',     'INT', 'SUM(tu.uid) AS tu.users_sum',     ],

    ],
    { WHERE => 1,

    }
  );

  my $EXT_TABLE = '';
  $EXT_TABLE = $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  $self->query( "SELECT t.name,
       tu.date,
       t.comments,
       t.priority,
       t.id
     FROM tags t
     LEFT JOIN tags_users tu ON (tu.tag_id = t.id AND tu.uid='$attr->{UID}')
     $EXT_TABLE
     $WHERE
     GROUP BY t.id
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ( $self->{TOTAL} > 0 ){
    $self->query( "SELECT count( DISTINCT tu.uid) AS total
     FROM tags t
     LEFT JOIN tags_users tu ON (tu.tag_id = t.id)
     $WHERE", undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 tags_user_change($attr)

=cut
#**********************************************************
sub tags_user_change{
  my $self = shift;
  my ($attr) = @_;

  $self->{admin}->{MODULE}=$MODULE;
  $self->user_del( $attr );

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

    $self->query( "INSERT INTO tags_users (uid, tag_id, date)
        VALUES (?, ?, CURDATE());",
      undef,
      { MULTI_QUERY => \@MULTI_QUERY } );
  }

  $self->{admin}->action_add( $attr->{UID}, $attr->{IDS}, { TYPE => 1 } );

  return $self;
}

#**********************************************************
=head2 user_del($attr)

=cut
#**********************************************************
sub user_del{
  my $self = shift;
  my ($attr) = @ _;

  $self->query_del( 'tags_users', undef, { uid => $attr->{UID},
    } );

  $self->{admin}->action_add( $attr->{UID}, "", { TYPE => 10 } );

  return $self;
}

#**********************************************************
=head2 tags_list($attr)

=cut
#**********************************************************
sub tags_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  # my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  # my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{EXT_TABLES} = '';

  my $WHERE = $self->search_former( $attr, [
      ['FIO',        'STR',    'up.fio',  ],
      ['TAG_ID',     'INT',    't.id',    ],
      ['LAST_ABON',  'INT',    'tu.date', ],
      ['UID',        'INT',    'tu.uid',  ],
    ],
    {
      WHERE => 1,
    }
  );

  my $EXT_TABLE = '';
  $EXT_TABLE = $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  $self->query( "SELECT t.name,
       tu.date,
       t.comments,
       t.priority,
       t.id,
       u.disable,
       u.uid,
       u.id as login
     FROM tags_users tu
     RIGHT JOIN tags t ON (t.id=tu.tag_id)
     LEFT JOIN users u ON (u.uid=tu.uid)
     $EXT_TABLE
     $WHERE
     ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

1
