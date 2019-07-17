package Contacts;

=head1 NAME

  Users manage functions

=cut

use strict;
use parent 'main';
use v5.16;
use Conf;
use Attach;

my $admin;
my $CONF;
my $SORT = 1;
my $DESC = '';
my $PG   = 1;
my $PAGE_ROWS = 25;

my %default_types = (
  1  => 'CELL_PHONE',
  2  => 'PHONE',
  3  => 'SKYPE',
  4  => 'ICQ',
  5  => 'VIBER',
  6  => 'TELEGRAM',
  7  => 'FACEBOOK',
  8  => 'VK',
  9  => 'EMAIL',
  10 => 'GOOGLE PUSH',
);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($db)  = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = '';

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}


#**********************************************************
=head2 contacts_list($attr)

  Arguments:
    $attr - hash_ref
      UID
      VALUE
      PRIORITY
      TYPE
      TYPE_NAME

  Returns:
    list

=cut
#**********************************************************
sub contacts_list{
  my $self = shift;
  my ($attr) = @_;

  $self->{errno} = 0;
  $self->{errstr} = '';

  return [] if (!$attr->{UID});

  #!!! Important !!! Only first list will work without this
  delete $self->{COL_NAMES_ARR};

  my $WHERE = '';

  $WHERE = $self->search_former( $attr, [
      [ 'UID',        'INT', 'uc.uid',      1 ],
      [ 'VALUE',      'STR', 'uc.value',    1 ],
      [ 'PRIORITY',   'INT', 'uc.priority', 1 ],
      [ 'TYPE',       'INT', 'uc.type_id',  1 ],
      [ 'TYPE_NAME',  'STR', 'uct.name',    1 ],
      [ 'HIDDEN',     'INT', 'uct.hidden'     ]
    ],
    {
      WHERE => 1
    }
  );

  if ($attr->{SHOW_ALL_COLUMNS}){
    $self->{SEARCH_FIELDS} = '*'
  }

  # Removing unnecessary comma
  $self->{SEARCH_FIELDS} =~ s/,.?$//;

  $self->query2( "
    SELECT $self->{SEARCH_FIELDS}
    FROM users_contacts uc
    LEFT JOIN users_contact_types uct ON (uc.type_id=uct.id)
     $WHERE ORDER BY priority;"
    , undef, {COLS_NAME => 1,  %{ $attr ? $attr : {} }}
  );

  return $self->{list};
}

#**********************************************************
=head2 contacts_info($id)

  Arguments:
    $id - id for contacts

  Returns:
    hash_ref

=cut
#**********************************************************
sub contacts_info{
  my $self = shift;
  my ($id) = @_;

  my $list = $self->contacts_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0] || {};
}

#**********************************************************
=head2 contacts_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub contacts_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('users_contacts', $attr, { REPLACE => 1 });

  return 1;
}

#**********************************************************
=head2 contacts_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub contacts_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('users_contacts', undef, $attr);

  return 1;
}

#**********************************************************
=head2 contacts_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub contacts_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'users_contacts',
      DATA         => $attr,
    });

  return 1;
}

#**********************************************************
=head2 contact_types_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub contact_types_list{
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  #!!! Important !!! Only first list will work without this
  delete $self->{COL_NAMES_ARR};

  my $WHERE = '';

  $WHERE = $self->search_former( $attr, [
      [ 'ID',         'INT', 'id',         1 ],
      [ 'NAME',       'STR', 'name',       1 ],
      [ 'IS_DEFAULT', 'INT', 'is_default', 1 ],
      [ 'HIDDEN',     'INT', 'hidden'        ]
    ],
    {
      WHERE => 1
    }
  );

  if ($attr->{SHOW_ALL_COLUMNS}){
    $self->{SEARCH_FIELDS} = '*,'
  }

  $self->query2( "SELECT $self->{SEARCH_FIELDS} id FROM users_contact_types $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, $attr );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************
=head2 contact_types_info($id)

  Arguments:
    $id - id for contact_types

  Returns:
    hash_ref

=cut
#**********************************************************
sub contact_types_info{
  my $self = shift;
  my ($id) = @_;

  my $list = $self->contact_types_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0] || {};
}

#**********************************************************
=head2 contact_types_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub contact_types_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('users_contact_types', $attr);

  return 1;
}

#**********************************************************
=head2 contact_types_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub contact_types_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('users_contact_types', $attr);

  return 1;
}

#**********************************************************
=head2 contact_types_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub contact_types_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'users_contact_types',
      DATA         => $attr,
    });

  return 1;
}

#**********************************************************
=head2 social_add_info() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub social_add_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('users_social_info', $attr, { REPLACE => ($attr->{REPLACE}) ? 1 : undef });

  return 1;
}

#**********************************************************
=head2 social_list_info($attr) -

  Arguments:
    $attr -

  Returns:
    $self object;

  Examples:

=cut
#**********************************************************
sub social_list_info {
  my $self = shift;
  my ($attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my @WHERE_RULES = ();
  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'uid';
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : 'desc';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 10000;

  #if ($attr->{UNRECOGNIZED} == 1) {
  #  push @WHERE_RULES, "cch.uid = '0'";
  #}

  my $WHERE = $self->search_former($attr, [
      # ['UID',               'INT',  'usi.uid',               1 ],
      ['SOCIAL_NETWORK_ID', 'INT',  'usi.social_network_id', 1 ],
      ['NAME',              'STR',  'usi.name',              1 ],
      ['EMAIL',             'STR',  'usi.email as social_email', 1 ],
      ['BIRTHDAY',          'DATE', 'usi.birthday',          1 ],
      ['GENDER',            'STR',  'usi.gender',            1 ],
      ['LIKES',             'STR',  'usi.likes',             1 ],
      ['PHOTO',             'STR',  'usi.photo',             1 ],
      ['LOCALE',            'STR',  'usi.locale',            1 ],
      ['FRIENDS_COUNT',     'STR',  'usi.friends_count',     1 ],
    ],
    {   WHERE            => 1,
      USE_USER_PI      => 1,
      USERS_FIELDS_PRE => 1,
      WHERE_RULES      => \@WHERE_RULES,
    }
  );

  my $EXT_TABLE = $self->{EXT_TABLES} || '';

  $self->query2(
    "SELECT
    $self->{SEARCH_FIELDS}
    usi.uid
    FROM users_social_info as usi
    LEFT JOIN users u ON u.uid=usi.uid
    $EXT_TABLE
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list if ($attr->{TOTAL} < 1);

  $self->query2(
    "SELECT COUNT(*) AS total
     FROM users_social_info",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 contact_type_id_for_name($name) - get contact_type_id for name

  Arguments:
    $name -
    
  Returns:
    
    
=cut
#**********************************************************
sub contact_type_id_for_name {
  my $self = shift;
  my ($name) = @_;
  
  state $contact_types;
  if (!defined $contact_types){
    my $contact_types_list = $self->contact_types_list({ID => '_SHOW', 'NAME' => '_SHOW', COLS_NAME => 1});
    my %id_name_hash = ();
    map { $id_name_hash{uc $_->{name}} = $_->{id} } @{$contact_types_list};
    $contact_types = \%id_name_hash;
  }
  
  return $contact_types->{uc $name} || 0;
}

1;
