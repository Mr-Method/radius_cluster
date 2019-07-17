package Events;
use strict;
use warnings FATAL => 'all';

=head2 NAME

 Events

=head2 SYNOPSIS

   $Events->events_add( {
      # Name for module
        MODULE      => 'Test',
      # Text
        COMMENTS    => 'Generated',
      # Link to see external info
        EXTRA       => 'http://abills.net.ua',
      # 1..5 Bigger is more important
        PRIORITY_ID => 1,
      } );

=cut

use Time::Local qw ( timelocal );

our $VERSION = 1.00;

use parent 'main';

# Singleton reference;
my $instance;

#**********************************************************
=head2 AUTOLOAD

  Because all namings are standart, 'add', 'change', 'del', 'info' can be generated automatically.
  
=head2 SYNOPSIS

  AUTOLOAD is called when undefined function was called in Package::Foo.
  global $AUTOLOAD var is filled with full name of called undefined function (Package::Foo::some_function)
  
  Because in this module DB tables and columns are named same as template variables, in all logic for custom operations
  the only thing that changes is table name.
  
  We can parse it from called function name and generate 'add', 'change', 'del', 'info' functions on the fly
   
=head2 USAGE

  You should use this function as usual, nothing changes in webinterface logic.
  Info functions are working regarding to 'SHOW_ALL_COLUMNS' in table_list()
  
  Just call $Events->group_info($group_id)
  
  Arguments:
    arguments are typical for operations, assuming we are working with ID column as primary key
    
  Returns:
    returns same result as usual operation functions ( Generally nothing )

=cut
#**********************************************************
sub AUTOLOAD {
  our $AUTOLOAD;
  return if ($AUTOLOAD =~ /::DESTROY$/);
  
  my ($entity_name, $operation) = $AUTOLOAD =~ /.*::(.*)_(add|del|change|info)$/;
  
  die "Undefined function $AUTOLOAD" unless ($operation && $entity_name);
   
  my ($self, $data, $attr) = @_;
  
  my $table = lc(__PACKAGE__) . '_' . $entity_name;
  
  # Check for not standart table namings
  my %unusual_names = (
    'events_events' => 'events'
  );
  if (exists $unusual_names{$table}){ $table = $unusual_names{$table} };
  
  if ($operation eq 'add'){
    return $self->query_add( $table, $data, $attr );
  }
  if ($operation eq 'del'){
    return $self->query_del( $table, $data );
  }
  if ($operation eq 'change'){
    return $self->changes2( {
      CHANGE_PARAM => 'ID',
      TABLE        =>  $table,
      DATA         => $data,
    } );
  }
  if ($operation eq 'info'){
    my $list_func_name = $entity_name . '_list';
    return undef if (!$self->can($list_func_name));
    
    my $list = $self->$list_func_name( { ID => $data, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1, COLS_NAME => 1, %{ $attr ? $attr : {} } } );
    
    return $list->[0] || { };
  }
}


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

  unless (defined $instance) {
    my ($db, $admin, $CONF) = @_;

    my $self = {
      db    => $db,
      admin => $admin,
      conf  => $CONF,
    };

    bless($self, $class);

    $instance = $self;
  }

  return $instance;
}

#**********************************************************

=head2 events_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub events_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'e.id';
  my $DESC      = ($attr->{DESC})      ? ''                 : 'DESC';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'ID',            'INT', 'e.id',                        1 ],
    [ 'MODULE',        'STR', 'e.module',                    1 ],
    [ 'NAME',          'STR', 'e.module',                    1 ],
    [ 'EXTRA',         'STR', 'e.extra',                     1 ],
    [ 'COMMENTS',      'STR', 'e.comments',                  1 ],
    [ 'STATE_ID',      'INT', 'e.state_id',                  1 ],
    [ 'PRIVACY_ID',    'INT', 'e.privacy_id',                1 ],
    [ 'PRIORITY_ID',   'INT', 'e.priority_id',               1 ],
    [ 'CREATED',       'DATE', 'e.created',                  1 ],
    [ 'GROUP_ID',      'INT', 'e.group_id AS group_id',      1 ],
    [ 'GROUP_NAME',    'INT', 'eg.name AS group_name',       1 ],
    [ 'PRIVACY_NAME',  'STR', 'epriv.name AS privacy_name',  1 ],
    [ 'PRIORITY_NAME', 'STR', 'eprio.name AS priority_name', 1 ],
    [ 'STATE_NAME',    'STR', 'es.name AS state_name',       1 ],
    [ 'GROUP_MODULES', 'STR', 'eg.modules AS group_modules', 1 ],

  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] }) } @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} 1 FROM events e
    LEFT JOIN events_privacy epriv ON (e.privacy_id = epriv.id)
    LEFT JOIN events_priority eprio ON (e.priority_id = eprio.id)
    LEFT JOIN events_state es ON (e.state_id = es.id)
    LEFT JOIN events_group eg ON (e.group_id = eg.id)
     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 state_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub state_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'id';
  my $DESC      = ($attr->{DESC})      ? 'DESC'             : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [ [ 'ID', 'INT', 'id', 1 ], [ 'NAME', 'STR', 'name', 1 ]];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] }) } @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} id FROM events_state $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 privacy_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub privacy_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'id';
  my $DESC      = ($attr->{DESC})      ? 'DESC'             : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [ [ 'ID', 'INT', 'id', 1 ], [ 'NAME', 'STR', 'name', 1 ], [ 'VALUE', 'STR', 'value', 1 ], ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] }) } @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} id FROM events_privacy $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 priority_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub priority_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'id';
  my $DESC      = ($attr->{DESC})      ? 'DESC'             : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [ 
    [ 'ID', 'INT', 'id', 1 ],
    [ 'NAME', 'STR', 'name', 1 ],
    [ 'VALUE', 'STR', 'value', 1 ]
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] }) } @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} id FROM events_priority $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************
=head2 priority_send_types_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub priority_send_types_list{
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || 'priority_id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
    ['AID',             'INT',        'aid'                   ,1 ],
    ['PRIORITY_ID',     'STR',        'priority_id'           ,1 ],
    ['SEND_TYPES',      'STR',        'send_types'            ,1 ],
  ];
  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });
  
  $self->query2( "SELECT $self->{SEARCH_FIELDS} priority_id
   FROM events_priority_send_types
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************
=head2 group_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub group_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'id';
  my $DESC      = ($attr->{DESC})      ? 'DESC'             : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [ [ 'ID', 'INT', 'id', 1 ], [ 'NAME', 'STR', 'name', 1 ], [ 'MODULES', 'STR', 'modules', 1 ], ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless exists $attr->{ $_->[0] } } @$search_columns;
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} id FROM events_group $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [] if $self->{errno};

  return $self->{list};
}

sub DESTROY{};

1;