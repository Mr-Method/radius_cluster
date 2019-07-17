=head1 NAME

  Groups manage

=cut

use warnings FATAL => 'all';
use strict;
use Abills::Defs;
use Abills::Base qw(in_array);

our (
  $db,
  $html,
  %lang,
  $admin,
  %permissions,
  @bool_vals,
);


#**********************************************************
=head2 form_groups() - users groups

=cut
#**********************************************************
sub form_groups {

  if ($FORM{add_form}) {
    if ($LIST_PARAMS{GID} || $LIST_PARAMS{GIDS}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 0
    }
    $users->{ACTION}     = 'add';
    $users->{LNG_ACTION} = $lang{ADD};
    if(in_array('Multidoms', \@MODULES)) {
      load_module('Multidoms', $html);
      $users->{DOMAIN_FORM} = $html->tpl_show(templates('form_row'), { ID    => '',
          NAME  => "DOMAIN_ID",
          VALUE => multidoms_domains_sel({ SHOW_ID => 1, DOMAIN_ID => $admin->{DOMAIN_ID} })
        },
        { OUTPUT2RETURN => 1 });
    }

    $html->tpl_show(templates('form_groups'), $users);
    return 0;
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message( 'err', $lang{ERROR}, $lang{ERR_ACCESS_DENY} );
      return 0;
    }
    elsif ($LIST_PARAMS{GID} || $LIST_PARAMS{GIDS}) {
      $html->message( 'err', $lang{ERROR}, $lang{ERR_ACCESS_DENY} );
    }
    else {
      $users->group_add({%FORM});
      if (!$users->{errno}) {
        $html->message( 'info', $lang{ADDED}, "$lang{ADDED} [". ($FORM{GID} || q{}) ."]" );
      }
    }
  }
  elsif ($FORM{change}) {
    if (!$permissions{0}{4}) {
      $html->message( 'err', $lang{ERROR}, $lang{ERR_ACCESS_DENY} );
      return 0;
    }

    $users->group_change($FORM{chg}, {%FORM});
    if (!$users->{errno}) {
      $html->message( 'info', $lang{CHANGED}, "$lang{CHANGED} ". ($FORM{chg} || q{}));
    }
  }
  elsif (defined($FORM{GID})) {
    $users->group_info($FORM{GID});

    $LIST_PARAMS{GID} = $users->{GID};
    delete $LIST_PARAMS{GIDS};
    $pages_qs = "&GID=$users->{GID}". (($FORM{subf}) ? "&subf=$FORM{subf}" : q{} );

    my $groups = $html->form_main(
      {
        CONTENT => $html->form_select(
          'GID',
          {
            SELECTED  => $users->{GID},
            SEL_LIST  => $users->groups_list({ COLS_NAME => 1 }),
            SEL_KEY   => 'gid',
            NO_ID     => 1
          }
        ),
        HIDDEN => { index => $index },
        SUBMIT => { show  => $lang{SHOW} },
        class  => 'navbar-form navbar-right',
      }
    );

    func_menu(
      {
        $lang{NAME} => $groups
      },
      [
        $lang{CHANGE}   . "::GID=$users->{GID}:change",
        $lang{USERS}    . ":11:GID=$users->{GID}:users",
        $lang{PAYMENTS} . ":2:GID=$users->{GID}:payments",
        $lang{FEES}     . ":3:GID=$users->{GID}:fees",
      ]
    );

    if (!$permissions{0}{4}) {
      return 0;
    }

    $users->{ACTION}        = 'change';
    $users->{LNG_ACTION}    = $lang{CHANGE};
    $users->{SEPARATE_DOCS} = ($users->{SEPARATE_DOCS})  ? 'checked' : '';
    $users->{ALLOW_CREDIT}  = ($users->{ALLOW_CREDIT})   ? 'checked' : '';
    $users->{DISABLE_PAYSYS}= ($users->{DISABLE_PAYSYS}) ? 'checked' : '';
    $users->{DISABLE_CHG_TP}= ($users->{DISABLE_CHG_TP}) ? 'checked' : '';
    $users->{BONUS}         = ($users->{BONUS}) ? 'checked' : '';

    if(in_array('Multidoms', \@MODULES)) {
      load_module('Multidoms', $html);
      $users->{DOMAIN_FORM} = $html->tpl_show(templates('form_row'), { ID    => '',
          NAME  => "DOMAIN_ID",
          VALUE => multidoms_domains_sel({ SHOW_ID => 1, DOMAIN_ID => $users->{DOMAIN_ID} })
        },
        { OUTPUT2RETURN => 1 });
    }

    $html->tpl_show(templates('form_groups'), $users);

    return 0;
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS} && $permissions{0}{5}) {
    $users->list({ GID => $FORM{del} });

    if ($users->{TOTAL} > 0 && $FORM{del} > 0) {
      $html->message( 'info', $lang{DELETED}, "$lang{USER_EXIST}." );
    }
    else {
      $users->group_del($FORM{del});
      if (!$users->{errno}) {
        $html->message( 'info', $lang{DELETED}, "$lang{DELETED} GID: $FORM{del}" );
      }
    }
  }

  _error_show($users);

  my $list  = $users->groups_list({%LIST_PARAMS, COLS_NAME => 1 });

  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{GROUPS},
      title      => [ '#', $lang{NAME}, $lang{DESCRIBE}, $lang{USERS}, "$lang{ALLOW} $lang{CREDIT}",
        "$lang{DISABLE} Paysys", "$lang{DISABLE} $lang{USER_CHG_TP}", '-' ],
      qs         => $pages_qs,
      pages      => $users->{TOTAL},
      ID         => 'GROUPS',
      FIELDS_IDS => $users->{COL_NAMES_ARR},
      EXPORT     => 1,
      MENU       => "$lang{ADD}:index=$index&add_form=1:add"
    }
  );

  foreach my $line (@$list) {
    my $delete = (defined( $permissions{0}{5} )) ? $html->button( $lang{DEL},
        "index=" . get_function_index( 'form_groups' ) . "$pages_qs&del=$line->{gid}",
        { MESSAGE => "$lang{DEL} [$line->{gid}] $line->{name}?", class => 'del' } ) : '';

    $table->addrow($html->b($line->{gid}),
      $line->{name},
      $line->{descr},
      $html->button($line->{users_count}, "index=7&GID=$line->{gid}&search_form=1&search=1&type=11"),
      $bool_vals[$line->{allow_credit}],
      $bool_vals[$line->{disable_paysys}],
      $bool_vals[$line->{disable_chg_tp}],
      $html->button( $lang{INFO}, "index=" . get_function_index( 'form_groups' ) . "&GID=$line->{gid}",
        { class => 'change' } )
        .' '.$delete );
  }
  print $table->show();

  $table = $html->table({
    width      => '100%',
    rows       => [ [ "$lang{TOTAL}:", $html->b( $users->{TOTAL} ) ] ]
  });

  print $table->show();

  return 1;
}


1;