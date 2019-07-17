package Callcenter;

=head1 Callcenter

Callcenter - moudle for polls

=head1 Synopsis

use Callcenter;

my $Callcenter = Callcenter->new($db, $admin, \%conf);

=cut

use strict;
use parent 'main';
our $VERSION = 0.01;

my ($admin, $CONF);
my ($SORT, $DESC, $PG, $PAGE_ROWS);


#*******************************************************************
=head2 function new() - initialize Callcenter object

  Arguments:
    $db    -
    $admin -
    %conf  -
  Returns:
    $self object

  Examples:
    $Callcenter = Callcenter->new($db, $admin, \%conf);

=cut
#*******************************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head2 callcenter_add_cals() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub callcenter_add_cals {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('callcenter_calls_handler', {DATE => $attr->{DATE} || 'NOW()',%$attr});

  return $self;

  return 1;
}

#**********************************************************
=head2 callcenter_list_calls($attr) - return list of polls

  Arguments:
    STATUS - call's status
    
  Returns:
    $self object;

  Examples:
    all polls
    my $tp_list = $Triplay->list_tp({COLS_NAME => 1});

    polls with status eq 2
    my $tp_list = $Triplay->list_tp({COLS_NAME => 1, STATUS => 2});
  
=cut
#**********************************************************
sub callcenter_list_calls {
  my $self = shift;
  my ($attr) = @_;
  
  delete $self->{COL_NAMES_ARR};

  my @WHERE_RULES = ();
  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'date';
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : 'desc';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

  if ($attr->{UNRECOGNIZED} == 1) {
    push @WHERE_RULES, "cch.uid = '0'";
  }

  if($attr->{DATE_START}){
    push @WHERE_RULES, "cch.date >= '$attr->{DATE_START}'";
  }

  if($attr->{DATE_END}){
    push @WHERE_RULES, "cch.date <= '$attr->{DATE_END}'";
  }


  my $WHERE = $self->search_former($attr, [
     ['ID',             'STR',  'cch.id',             1 ],
     # ['UID',            'INT',  'cch.uid',            1 ],
     ['USER_PHONE',     'STR',  'cch.user_phone',     1 ],
     ['OPERATOR_PHONE', 'STR',  'cch.operator_phone', 1 ],
     ['STATUS',         'INT',  'cch.status',         1 ],
     ['DATE',           'DATE', 'cch.date',           1 ],
     ['ADMIN',          'STR',  'admins.name as admin',        1 ],
     ['ADDRESS_FULL',    'STR',  "CONCAT(streets.name, ' ', builds.number, ',', pi.address_flat) AS address_full", ]
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
    cch.id,
    cch.uid
    FROM callcenter_calls_handler as cch
    LEFT JOIN users u ON u.uid=cch.uid
    LEFT JOIN users_pi pi ON pi.uid=cch.uid
    LEFT JOIN builds ON (builds.id=pi.location_id)
    LEFT JOIN streets ON (streets.id=builds.street_id)
    LEFT JOIN districts ON (districts.id=streets.district_id)
    LEFT JOIN admins ON (admins.sip_number=cch.operator_phone)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list if ($attr->{TOTAL} < 1);

  $self->query2(
    "SELECT count(*) AS total
     FROM callcenter_calls_handler",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 callcenter_change_calls($attr) - change calls status

  Arguments:
    
    
  Returns:
    $self object;

  Examples:
    $Poll->change_poll({  });
  
=cut
#**********************************************************
sub callcenter_change_calls {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'callcenter_calls_handler',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 callcenter_info_calls($attr) - 

  Arguments:
    ID      - tp's ID
    
  Returns:

  Examples:
    $call_info = $Callcenter->callcenter_info_calls({COLS_NAME => 1, ID => 1});
  
=cut
#**********************************************************
sub callcenter_info_calls {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{ID}) {
    $self->query2(
      "SELECT cch.id,
    cch.user_phone,
    cch.operator_phone,
    cch.date,
    cch.uid,
    cch.status
    FROM callcenter_calls_handler as cch
      WHERE id = ?;", undef, { COLS_NAME => 1, Bind => [ $attr->{ID} ] }
    );
  }

  return $self->{list}->[0];
}

#**********************************************************
=head2 callcenter_delete_calls($attr) - delete calls

  Arguments:
    ID   - call's ID;
    
  Returns:
    $self object;

  Examples:
    $Callcenter->callcenter_delete_calls({ID => $FORM{del}});
  
=cut
#**********************************************************
sub callcenter_delete_calls {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('callcenter_calls_handler', $attr);

  return $self;
}

1


# package Callcenter;


# use strict;
# use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

# use Exporter;
# $VERSION = 1.00;
# @ISA     = ('Exporter');

# @EXPORT = qw();

# @EXPORT_OK   = ();
# %EXPORT_TAGS = ();

# use main;
# @ISA = ("main");

# my $MODULE = 'Call_center';


# #**********************************************************
# # Init
# #**********************************************************
# sub new {
#   my $class = shift;
#   my $db    = shift;
#   ($admin, $CONF) = @_;

#   my $self = {};
#   bless($self, $class);

#   $admin->{MODULE} = $MODULE;

#   $self->{db}=$db;

#   return $self;
# }
# #**********************************************************
# #
# #**********************************************************
# sub info {
#   my $self = shift;
#   my ($id, $attr) = @_;
#   my $collum = '';
#   my $table = '';
#   my $WHERE = "WHERE id='$id'";
#   $WHERE  = $attr->{WHERE} if ($attr->{WHERE});

#   if ($attr->{FUNC} eq 'SYS_FUNC') {
#     $collum = "id, name, function, dest_type, dest_id";
#     $table = 'call_center_sys_func';
#   }
#   elsif ($attr->{FUNC} eq 'IVR_FUNC') {  
#     $collum = "id, menu_id, exten, message_id, dest_type, dest_id, menu_ret";
#     $table = 'call_center_ivr_function';
#   }
#   elsif ($attr->{FUNC} eq 'IVR') {
#     $collum = "id, name, description, message_id, invalid_loops, timeout, err_message, undef_message";
#     $table = 'call_center_ivr';
#   }
#   elsif ($attr->{FUNC} eq 'MESSAGES') {
#     $collum = "id, name, type, value, data, status";
#     $table  = 'call_center_messages';
#   }
#   elsif ($attr->{FUNC} eq 'WELCOME') {
#     $collum = "id, name, message_id, dest_type, dest_id";
#     $table  = 'call_center_welcome'; 
#   }
#   elsif ($attr->{FUNC} eq 'INTERVALS') {
#     $collum ="id, name, time_begin, time_end, week_begin, week_end, day_begin, day_end, month_begin, month_end, dest_type_true, dest_id_true, dest_type_false, dest_id_false";
#     $table  = 'call_center_intervals';
#   }
#   elsif ($attr->{FUNC} eq 'OUT_NUM') {
#     $collum ="id, exten, fio";
#     $table  = 'call_center_out_num';
#   }
#   elsif ($attr->{FUNC} eq 'SIPUSERS') {
#     $collum ="id, sip_type, username, name, ringtimer, disable, max_line, ipaddr, port, regseconds, defaultuser, fullcontact, regserver, useragent, lastms, host, type, context, deny, permit, secret,
#               language, disallow, allow, insecure, transport, dtmfmode, nat, callgroup, pickupgroup, callerid, callcounter, fromuser, fromdomain";
#     $table  = 'call_center_sipusers';
#   }
#   elsif ($attr->{FUNC} eq 'AST_CONFIG') {
#     $collum ="id, cat_metric, var_metric, commented, filename, category, var_name, var_val";
#     $table  = 'call_center_ast_config';
#     $WHERE = "WHERE category='$id'"  if (!$attr->{WHERE});
#   }
#   elsif ($attr->{FUNC} eq 'EXTENSIONS') {
#     $collum ="id, context, exten, priority, app, appdata";
#     $table  = 'call_center_extensions';
#   }
#   elsif ($attr->{FUNC} eq 'TRUNKS') {
#     $collum ="id, name, trunk_type, outcid, max_line, sip_type, channelid, prefix, channelcontext, usercontext, register, register_id, disabled, busy_next";
#     $table  = 'call_center_trunks';
#   }
#   elsif ($attr->{FUNC} eq 'OUT_ROUTE') {
#     $collum ="id, name, mohclass, context";
#     $table  = 'call_center_outbound_routes';
#   }
#   elsif ($attr->{FUNC} eq 'INPUT_ROUTE') {
#     $collum ="id, name, mohclass, context, dest_type, dest_id";
#     $table  = 'call_center_incoming_routes';
#   }
#   elsif ($attr->{FUNC} eq 'USERS_PHONE') {
#     $collum ="id, uid, phone, name";
#     $table  = 'call_center_users_phone';
#   }
#   elsif ($attr->{FUNC} eq 'CURRENT_CALL') {
#     $collum ="id, caller, operator, uid, login, status";
#     $table  = 'call_center_current_calls';
#   }

#   $self->query2("SELECT $collum
#   FROM $table
#   $WHERE;",
#   undef,
#   { INFO => 1 }
#   );

#   return $self;
# }
# #**********************************************************
# #
# #**********************************************************
# sub list {
#   my $self = shift;
#   $self->{debug} = 0;
#   my ($attr) = @_;
#   @WHERE_RULES = ();
#   $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
#   $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
#   $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
#   $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
#   my $GROUP_BY = $attr->{GROUP_BY} || '';

#   my $collum = '';
#   my $table = '';

#   my $WHERE = $self->search_former($attr, [
#      ['ID',           'INT',  'id'            ],
#      ['CAT_METRIC',   'INT',  'cat_metric'    ],
#      ['OUT_ROUTE_ID', 'INT',  'out_route_id'  ],
#      ['CONTEXT',      'INT',  'context'       ],
#      ['CATEGORY',     'INT',  'category'      ],
#      ['SIP_TYPE',     'INT',  'sip_type'      ],
#      ['UID',          'INT',  'uid'           ],
#      ['OPERATOR',     'INT',  'operator'      ],
#      ['STATUS',       'INT',  'status'        ],
#      ['PHONE',        'STR',  'phone'         ]


#     ],
#     { WHERE => 1,
#         WHERE_RULES => \@WHERE_RULES
#     }
#   );

#   my $EXT_TABLES = $self->{EXT_TABLES};

#   if ($attr->{FUNC} eq 'SYS_FUNC') {
#     $collum = "id, name, function, dest_type, dest_id";
#     $table = 'call_center_sys_func';
#   }
#   elsif ($attr->{FUNC} eq 'IVR_FUNC') {
#     $WHERE = "WHERE menu_id=$attr->{MENU_ID}";
#     $WHERE .= " AND EXTEN=$attr->{EXTEN}" if ($attr->{EXTEN});
#     $collum = "id, exten, message_id, dest_type, dest_id, menu_ret,  menu_id";
#     $table  = 'call_center_ivr_function';
#   }
#   elsif ($attr->{FUNC} eq 'IVR') {
#     $collum = "id, name, description, message_id, invalid_loops, timeout, err_message, undef_message";
#     $table  = 'call_center_ivr';
#   }
#   elsif ($attr->{FUNC} eq 'MESSAGES') {
#     $collum = "id, name, type, value, data, status";
#     $table  = 'call_center_messages';
#   }
#   elsif ($attr->{FUNC} eq 'WELCOME') {
#     $collum = "id, name, message_id, dest_type, dest_id";
#     $table  = 'call_center_welcome';
#   }
#   elsif ($attr->{FUNC} eq 'INTERVALS') {
#     $collum ="id, name, time_begin, time_end, week_begin, week_end, day_begin, day_end, month_begin, month_end, dest_type_true, dest_id_true, dest_type_false, dest_id_false";
#     $table  = 'call_center_intervals';
#   }
#   elsif ($attr->{FUNC} eq 'OUT_NUM') {
#     $collum ="id, exten, fio";
#     $table  = 'call_center_out_num';
#   }
#   elsif ($attr->{FUNC} eq 'SIPUSERS') {
#     $collum ="id, sip_type, username, name, ringtimer, disable, max_line, ipaddr, port, regseconds, defaultuser, fullcontact, regserver, useragent, lastms, host, type, context, deny, permit, secret,
#               language, disallow, allow, insecure, transport, dtmfmode, nat, callgroup, pickupgroup, callerid, callcounter, fromuser, fromdomain";
#     $table  = 'call_center_sipusers';
#   }
#   elsif ($attr->{FUNC} eq 'AST_CONFIG') {
#     $collum ="id, cat_metric, var_metric, commented, filename, category, var_name, var_val";
#     $table  = 'call_center_ast_config';
#   }
#   elsif ($attr->{FUNC} eq 'EXTENSIONS') {
#     $collum ="id, context, exten, priority, app, appdata";
#     $table  = 'call_center_extensions';
#   }
#   elsif ($attr->{FUNC} eq 'TRUNKS') {
#     $collum ="id, name, trunk_type, outcid, max_line, sip_type, channelid, prefix, channelcontext, usercontext, register, register_id, disabled, busy_next";
#     $table  = 'call_center_trunks';
#   }
#   elsif ($attr->{FUNC} eq 'OUT_ROUTE') {
#     $collum ="id, name, mohclass, context";
#     $table  = 'call_center_outbound_routes';
#   }
#   elsif ($attr->{FUNC} eq 'INPUT_ROUTE') {
#     $collum ="id, name, mohclass, context, dest_type, dest_id";
#     $table  = 'call_center_incoming_routes';
#   }
#   elsif ($attr->{FUNC} eq 'USERS_PHONE') {
#     $collum ="id, uid, phone, name";
#     $table  = 'call_center_users_phone';
#   }
#   elsif ($attr->{FUNC} eq 'CURRENT_CALL') {
#     $collum ="id, caller, operator, uid, login, status";
#     $table  = 'call_center_current_calls';
#   }

#   $self->query2("SELECT $collum
#     FROM $table
#     $WHERE $GROUP_BY
#     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
#     undef,
#     $attr
#   );


#   return $self if ($self->{errno});

#   my $list = $self->{list};

#   if ($self->{TOTAL} > 0) {
#     $self->query2("SELECT count(*) AS total FROM $table $WHERE", undef, { INFO => 1 });
#   }

#   return $list;
# }
# #**********************************************************
# # del
# #**********************************************************
# sub del {
#   my $self = shift;
#   my ($id, $attr) = @_;
#   my $table = '';
#   my $WHERE = "WHERE id='$id'";
#   $WHERE  = $attr->{WHERE} if ($attr->{WHERE});

#   if ($attr->{FUNC} eq 'SYS_FUNC') {
#     $table = 'call_center_sys_func';
#   }
#   elsif ($attr->{FUNC} eq 'IVR_FUNC') {
#     $table = 'call_center_ivr_function';
#   }
#   elsif ($attr->{FUNC} eq 'IVR') {
#     $table = 'call_center_ivr';
#   }
#   elsif ($attr->{FUNC} eq 'MESSAGES') {
#     $table  = 'call_center_messages';
#   }
#   elsif ($attr->{FUNC} eq 'WELCOME') {
#     $table  = 'call_center_welcome';
#   }
#   elsif ($attr->{FUNC} eq 'INTERVALS') {
#     $table  = 'call_center_intervals';
#   }
#   elsif ($attr->{FUNC} eq 'SIPUSERS') {
#     $table  = 'call_center_sipusers';
#   }
#   elsif ($attr->{FUNC} eq 'OUT_NUM') {
#     $table  = 'call_center_out_num';
#   }
#   elsif ($attr->{FUNC} eq 'AST_CONFIG') {
#     $table  = 'call_center_ast_config';
#     $WHERE = "WHERE category='$id'" if (!$attr->{WHERE});
#   }
#   elsif ($attr->{FUNC} eq 'EXTENSIONS') {
#     $table  = 'call_center_extensions';
#     $WHERE = "WHERE context='$id'";
#     $WHERE .= " AND exten=$attr->{EXTEN}" if ($attr->{EXTEN});
#   }
#   elsif ($attr->{FUNC} eq 'TRUNKS') {
#     $table  = 'call_center_trunks';
#   }
#   elsif ($attr->{FUNC} eq 'OUT_ROUTE') {
#     $table  = 'call_center_outbound_routes';
#   }
#   elsif ($attr->{FUNC} eq 'INPUT_ROUTE') {
#     $table  = 'call_center_incoming_routes';
#   }
#   elsif ($attr->{FUNC} eq 'USERS_PHONE') {
#     $table  = 'call_center_users_phone';
#   }
#   elsif ($attr->{FUNC} eq 'CURRENT_CALL') {
#     $table  = 'call_center_current_calls';
#   }

#   $WHERE = $attr->{WHERE} if ($attr->{WHERE});

#   $self->query2("DELETE FROM $table $WHERE;", 'do');

#   return $self;
# }
# #**********************************************************
# # Add
# #**********************************************************
# sub add {
#   my $self = shift;
#   my ($attr) = @_;
#   my $table = '';

#   %DATA = $self->get_data($attr);
  
#   if ($attr->{FUNC} eq 'SYS_FUNC') {
#     $table = 'call_center_sys_func';
#   }
#   elsif ($attr->{FUNC} eq 'IVR_FUNC') {
#     $table = 'call_center_ivr_function';
#   }
#   elsif ($attr->{FUNC} eq 'IVR') {
#     $table = 'call_center_ivr';
#   }
#   elsif ($attr->{FUNC} eq 'MESSAGES') {
#     $table  = 'call_center_messages';
#   }
#   elsif ($attr->{FUNC} eq 'WELCOME') {
#     $table  = 'call_center_welcome';
#   }
#   elsif ($attr->{FUNC} eq 'INTERVALS') {
#     $table  = 'call_center_intervals';
#   }
#   elsif ($attr->{FUNC} eq 'SIPUSERS') {
#     $table  = 'call_center_sipusers';
#   }
#   elsif ($attr->{FUNC} eq 'OUT_NUM') {
#     $table  = 'call_center_out_num';
#   }
#   elsif ($attr->{FUNC} eq 'AST_CONFIG') {
#     $table  = 'call_center_ast_config';
#   }
#   elsif ($attr->{FUNC} eq 'EXTENSIONS') {
#     $table  = 'call_center_extensions';
#   }
#   elsif ($attr->{FUNC} eq 'TRUNKS') {
#     $table  = 'call_center_trunks';
#   }
#   elsif ($attr->{FUNC} eq 'OUT_ROUTE') {
#     $table  = 'call_center_outbound_routes';
#   }
#   elsif ($attr->{FUNC} eq 'INPUT_ROUTE') {
#     $table  = 'call_center_incoming_routes';
#   }
#   elsif ($attr->{FUNC} eq 'USERS_PHONE') {
#     $table  = 'call_center_users_phone';
#   }
#   elsif ($attr->{FUNC} eq 'CURRENT_CALL') {
#     $table  = 'call_center_current_calls';
#   }

#   $self->query_add($table, $attr);

#   return $self;
# }
# #**********************************************************
# # Change
# #**********************************************************
# sub change {
#   my $self = shift;
#   my ($attr) = @_;
#   my $table = '';
#   my $CHANGE_PARAM = 'ID';
#   if ($attr->{FUNC} eq 'SYS_FUNC') {
#     $table = 'call_center_sys_func';
#   }
#   elsif ($attr->{FUNC} eq 'IVR_FUNC') {
#     $table = 'call_center_ivr_function';
#   }
#   elsif ($attr->{FUNC} eq 'IVR') {
#     $table = 'call_center_ivr';
#   }
#   elsif ($attr->{FUNC} eq 'MESSAGES') {
#     $table  = 'call_center_messages';
#   }
#   elsif ($attr->{FUNC} eq 'WELCOME') {
#     $table  = 'call_center_welcome';
#   }
#   elsif ($attr->{FUNC} eq 'INTERVALS') {
#     $table  = 'call_center_intervals';
#   }
#   elsif ($attr->{FUNC} eq 'OUT_NUM') {
#     $table  = 'call_center_out_num';
#   }
#   elsif ($attr->{FUNC} eq 'SIPUSERS') {
#     $table  = 'call_center_sipusers';
#   }
#   elsif ($attr->{FUNC} eq 'AST_CONFIG') {
#     $table  = 'call_center_ast_config';
#   }
#   elsif ($attr->{FUNC} eq 'EXTENSIONS') {
#     $table  = 'call_center_extensions';
#   }
#   elsif ($attr->{FUNC} eq 'TRUNKS') {
#     $table  = 'call_center_trunks';
#   }
#   elsif ($attr->{FUNC} eq 'OUT_ROUTE') {
#     $table  = 'call_center_outbound_routes';
#   }
#   elsif ($attr->{FUNC} eq 'INPUT_ROUTE') {
#     $table  = 'call_center_incoming_routes';
#   }
#   elsif ($attr->{FUNC} eq 'USERS_PHONE') {
#     $table  = 'call_center_users_phone';
#   }
#   elsif ($attr->{FUNC} eq 'CURRENT_CALL') {
#     $table  = 'call_center_current_calls';
#   }

#   $self->changes(
#     $admin,
#     {
#       CHANGE_PARAM => $CHANGE_PARAM,
#       TABLE        => $table,
#       DATA         => $attr
#     }
#   );

#   return $self;
# }
# #**********************************************************
# #
# #**********************************************************
# sub message_add {
#   my $self = shift;
#   my ($attr) = @_;

#   $self->query2(
#     "INSERT INTO call_center_messages "
#     . " (name, type, value, data) "
#     . " VALUES "
#     . " ('$attr->{NAME}', '$attr->{TYPE}', '$attr->{VALUE}', ?)",
#     'do',
#     { Bind => [ $attr->{DATA} ] }
#   );

#   return $self;
# }
# #**********************************************************
# #
# #**********************************************************
# sub message_change {
#   my $self = shift;
#   my ($attr) = @_;

#   $self->query2(
#     "UPDATE call_center_messages SET"
#     . " name='$attr->{NAME}', 
#         type='$attr->{TYPE}', 
#         value='$attr->{VALUE}', 
#         data = ?,
#         status='1'
#      WHERE id='$attr->{ID}'",
#     'do',
#     { Bind => [
#      $attr->{DATA} ] 
#     }
#   );

#   return $self;

# }  
# #**********************************************************
# # log_add()
# #**********************************************************
# sub log_add {
#   my $self = shift;
#   my ($attr) = @_;

#   $self->query_add('call_center_ivr_log', { %$attr,
#                                          DATETIME => 'now()'
#                                         });

#   return $self;
# }

# 1
