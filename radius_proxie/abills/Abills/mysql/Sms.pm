package Sms;
=head1 NAME

  Dialup & Vpn  managment functions

=cut

use strict;
use warnings FATAL => 'all';
use parent 'main';

my $MODULE = 'Sms';
my ($admin, $CONF);
my $SORT      = 1;
my $DESC      = '';
my $PG        = 0;
my $PAGE_ROWS = 25;


#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;
  my $self = {};

  bless($self, $class);

  $self->{db}=$db;
  $self->{admin}=$admin;
  $self->{conf}=$CONF;

  return $self;
}

#**********************************************************
=head2 info($attr) - Sms status info

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT *
     FROM sms_log
   WHERE id = ?;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ]}
  );

  return $self;
}

#**********************************************************
=head2 add($attr) - Add sms log records

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('sms_log', { %$attr });

  return $self;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'sms_log',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 del(attr) - Del log record

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('sms_log',$attr);

  return $self;
}

#**********************************************************
=head2 list($attr) - Sms log list

=cut
#**********************************************************
sub list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{EXT_TABLES}     = '';
  $self->{SEARCH_FIELDS}  = '';
  $self->{SEARCH_FIELDS_COUNT}=0;

  if ($attr->{INTERVAL}) {
    ($attr->{FROM_DATE}, $attr->{TO_DATE}) = split(/\//, $attr->{INTERVAL}, 2);
  }

  my $WHERE =  $self->search_former($attr, [
      ['DATETIME',       'DATE','sms.datetime',               1 ],
      ['STATUS',         'INT', 'sms.status',                 1 ],
      ['PHONE',          'STR', 'sms.phone',                  1 ],
      ['MESSAGE',        'STR', 'sms.message',                1 ],
      ['EXT_ID',         'STR', 'sms.ext_id',                 1 ],
      ['EXT_STATUS',     'STR', 'sms.ext_status',             1 ],
      ['STATUS_DATE',    'DATE','sms.status_date',            1 ],
      ['FROM_DATE|TO_DATE','DATE',"DATE_FORMAT(sms.datetime, '%Y-%m-%d')"],
      ['ID',             'INT', 'sms.id'                       ],
    ],
    { WHERE            => 1,
      USERS_FIELDS_PRE => 1,
      USE_USER_PI      => 1,
      SKIP_USERS_FIELDS=> [ 'UID' ]
    }
  );

  my $EXT_TABLE = $self->{EXT_TABLES};

  $self->query2("SELECT
      $self->{SEARCH_FIELDS}
      sms.uid,
      sms.id
     FROM sms_log sms
     LEFT JOIN users u ON (u.uid=sms.uid)
     $EXT_TABLE
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query2("SELECT count( DISTINCT sms.id) AS total FROM sms_log sms
    LEFT JOIN users u ON (u.uid=sms.uid)
    $EXT_TABLE
    $WHERE",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}


1;