=head1 NAME

  Users contracts web functions

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/_bp/;

our (
  $db,
  $admin,
  %lang,
  $users,
  $html,
  %conf
);

#**********************************************************
=head2 user_contract($attr)

=cut
#**********************************************************
sub user_contract {

  my $uid = $FORM{UID}; 
  return '' unless ($uid);

  if ($FORM{print_add_contract}) {
    my $list = $users->contracts_list({ UID => $uid, ID => $FORM{print_add_contract}, COLS_UPPER => 1 });
    $users->info($uid);
    $users->pi({ UID => $uid });
    my $company_info = {};

    if($users->{COMPANY_ID}){
      use Companies;
      my $Company = Companies->new($db, $admin, \%conf);
      $company_info = $Company->info($users->{COMPANY_ID});
    }
    if ($FORM{pdf}) {
      my $sig_img = "$conf{TPL_DIR}/sig.png";
      if ($list->[0]->{SIGNATURE}) {
        open( my $fh, '>', $sig_img);
        binmode $fh;
        my ($data) = $list->[0]->{SIGNATURE} =~ m/data:image\/png;base64,(.*)/;
        print $fh decode_base64($data);
        close $fh;
      }
      else {
        # open( my $fh, '>', $sig_img);
        # close $fh;
      }
      $html->tpl_show("$conf{TPL_DIR}/$list->[0]->{template}", { %$users, %$company_info, %{$list->[0]}, FIO_S => $users->{FIO} }, { TITLE => "Contract" });
      unlink $sig_img;
    }
    else {
      $html->tpl_show(templates($list->[0]->{template}), { %$users, %$company_info, %{$list->[0]} });
    }
    return 1;
  }
  elsif ($FORM{signature}) {
    $users->contracts_change($FORM{sign}, { SIGNATURE => $FORM{signature} });
    $html->message('info', $lang{SIGNED});
  }
  elsif ($FORM{sign}) {
    $html->tpl_show(templates('signature'), {});
    return 1;
  }
  elsif ($FORM{del}) {
    $users->contracts_del({ UID => $uid, ID => $FORM{del} });
  }
  elsif ($FORM{change}) {
    $users->contracts_change($FORM{chg}, \%FORM);
  }
  elsif ($FORM{chg}) {
    my $list = $users->contracts_list({ UID => $uid, ID => $FORM{chg}, COLS_UPPER => 1 });
    if ($users->{TOTAL} != 0) {
      $html->tpl_show(templates('form_user_contract'), { 
        BTN_NAME  => 'change',
        BTN_VALUE => $lang{CHANGE},
        TYPE_SEL  => _contract_type_select($list->[0]->{type}),
        %{$list->[0]} 
      });
    }
  }
  elsif ($FORM{add}) {
    $html->tpl_show(templates('form_user_contract'), {
      BTN_NAME  => 'adding',
      BTN_VALUE => $lang{ADD},
      TYPE_SEL  => _contract_type_select('0'),
    });
  }
  elsif ($FORM{adding}) {
    $users->contracts_add(\%FORM);
  }

  print _user_contracts_table($FORM{UID});
  return 1;
}

#**********************************************************
=head2 _user_contracts_table($attr)

=cut
#**********************************************************
sub _user_contracts_table {
  my ($uid, $attr) = @_;

  $uid = $FORM{UID} unless ($uid); 
  return '' unless ($uid);

  my $f_index;

  if ($attr->{UI}) {
    $f_index = 10;
  }
  else {
    $f_index = get_function_index('user_contract');
  }

  my $list = $users->contracts_list({ UID => $uid });

  my $table = $html->table({
    width               => '100%',
    caption             => $lang{ADDITION},
    border              => 1,
    title_plain         => [ $lang{NAME}, "#", $lang{DATE}, $lang{SIGNATURE} ],
    ID                  => 'USER_CONTRACTS',
    HAS_FUNCTION_FIELDS => 1,
    ( $attr->{UI} ? {} : MENU => "$lang{ADD}:index=" . get_function_index('user_contract') . "&add=1&UID=$uid:add" ),
  });

  foreach my $line (@$list) {
    my $sign_button = '';
    if ($line->{signature}) {
      $sign_button = $lang{SIGNED};
    }
    else {
      $sign_button = $html->button($lang{SIGN}, "qindex=" . $f_index . "&UID=$uid&sign=$line->{id}&header=2",
            { class => 'btn btn-default' });
    }
    my $print_button = $html->button('', "qindex=" . $f_index . "&UID=$uid&print_add_contract=$line->{id}&pdf=1",
            { ICON => 'glyphicon glyphicon-print', target => '_new', ex_params => "data-tooltip='$lang{PRINT}' data-tooltip-position='top'" });
    my $edit_button = $html->button('', "index=" . $f_index . "&chg=$line->{id}&UID=$uid",
            { ICON => 'glyphicon glyphicon-pencil', ex_params => "data-tooltip='$lang{EDIT}' data-tooltip-position='top'" });
    my $delete_button = $html->button('', "index=" . $f_index . "&del=$line->{id}&UID=$uid",
            { ICON => 'glyphicon glyphicon-trash text-danger', ex_params => "data-tooltip='$lang{DEL}' data-tooltip-position='top'" });
    $table->addrow($line->{name}, $line->{number}, $line->{date}, $sign_button, ($attr->{UI} ? $print_button : $print_button . $edit_button . $delete_button) );
  }

  my $result = $table->show({OUTPUT2RETURN => 1});

  return $result;
}

#**********************************************************
=head2 contracts_type()

=cut
#**********************************************************
sub contracts_type {

  if ($FORM{del}) {
    $users->contracts_type_del({ ID => $FORM{del} });
  }
  elsif ($FORM{change}) {
    $users->contracts_type_change($FORM{chg}, \%FORM);
  }
  elsif ($FORM{chg}) {
    my $list = $users->contracts_type_list({ ID => $FORM{chg}, COLS_UPPER => 1 });
    if ($users->{TOTAL} && $users->{TOTAL} > 0) {
       $html->tpl_show(templates('form_user_contracts_type'), { BTN_NAME => 'change', BTN_VALUE => $lang{CHANGE}, %{$list->[0]} });
    }
  }
  elsif ($FORM{add}) {
    $html->tpl_show(templates('form_user_contracts_type'), { BTN_NAME => 'adding', BTN_VALUE => $lang{ADD} });
  }
  elsif ($FORM{adding}) {
    $users->contracts_type_add(\%FORM);
  }

  print _contract_type_table();

  return 1;
}

#**********************************************************
=head2 _contract_type_table($attr)

=cut
#**********************************************************
sub _contract_type_table {
  
  my $list = $users->contracts_type_list({});

  my $table = $html->table({
    width               => '100%',
    caption             => "$lang{TYPES} $lang{CONTRACTS}",
    border              => 1,
    title_plain         => [ $lang{NAME}, $lang{TEMPLATE} ],
    ID                  => 'CONTRACTS_TYPE',
    HAS_FUNCTION_FIELDS => 1,
    MENU                => "$lang{ADD}:index=" . get_function_index('contracts_type') . "&add=1:add",
  });

  foreach my $line (@$list) {
    my $edit_button = $html->button('', "index=" . get_function_index('contracts_type') . "&chg=$line->{id}",
            { ICON => 'glyphicon glyphicon-pencil', ex_params => "data-tooltip='$lang{EDIT}' data-tooltip-position='top'" });
    my $delete_button = $html->button('', "index=" . get_function_index('contracts_type') . "&del=$line->{id}",
            { ICON => 'glyphicon glyphicon-trash text-danger', ex_params => "data-tooltip='$lang{DEL}' data-tooltip-position='top'" });
    $table->addrow($line->{name}, $line->{template}, $edit_button . $delete_button);
  }

  my $result = $table->show({OUTPUT2RETURN => 1});

  return $result;
}

#**********************************************************
=head2 _contract_type_select($attr)

=cut
#**********************************************************
sub _contract_type_select {
  my ($selected) = @_;

  my $list = $users->contracts_type_list({});

  if ($users->{TOTAL} == 0) {
    my $add_btn = $html->button(
      " $lang{ADD} $lang{TYPE} $lang{CONTRACTS}",
      'add=1&index=' . get_function_index('contracts_type'),
      {
        class => 'btn btn-warning',
        ADD_ICON  => 'glyphicon glyphicon-plus'
  
      }
    );
    return $add_btn;
  }

  my $result = $html->form_select('TYPE', {
    SELECTED      => ($selected || ''),
    SEL_LIST      => $list,
    NO_ID         => 1,
    OUTPUT2RETURN => 1
  });

  return $result;
}

1