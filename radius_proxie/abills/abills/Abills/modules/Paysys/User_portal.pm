#package Paysys::UserPortal;
use strict;
use warnings FATAL => 'all';

use Abills::Base;

our (
  $html,
  $base_dir,
  $admin,
  $db,
  %conf,
  %lang,
  @status,
  @status_color,
);
our Paysys $Paysys;

#**********************************************************
=head2 paysys_payment()

=cut
#**********************************************************
sub paysys_payment {
  my ($attr) = @_;

  my %TEMPLATES_ARGS = ();
  $user->pi({UID => $user->{UID}});

  if ($FORM{SUM}) {
    $FORM{SUM} = 0 if ($FORM{SUM} !~ /^[\.\,0-9]+$/);
    $FORM{SUM} = sprintf("%.2f", $FORM{SUM});
  }
  else {
    $FORM{SUM} = 0;
  }

  if ($FORM{SUM} == 0 && $user) {
    if (defined(&recomended_pay)) {
      $FORM{SUM} = recomended_pay($user);
    }
  }

  if ($user->{GID}) {
    $user->group_info($user->{GID});
    if ($user->{DISABLE_PAYSYS}) {
      $html->message('err', $lang{ERROR}, "$lang{DISABLE}");
      return 0;
    }
  }

  if($conf{PAYSYS_IPAY_FAST_PAY}){

    if(($FORM{ipay_pay} || $FORM{ipay_register_purchase} || $FORM{ipay_purchase})){
      #    $user->pi({UID => $user->{UID}});
      if(($FORM{ipay_pay} || $FORM{ipay_register_purchase}) && $FORM{SUM} <= 0){
        $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_SUM}" );
        return 1;
      }

      my $Module = _configure_load_payment_module('Ipay.pm');
      my $Paysys_Object = $Module->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang, INDEX => $index, SELF_URL => $SELF_URL });
      $TEMPLATES_ARGS{IPAY_HTML} = $Paysys_Object->user_portal_special($user, { %FORM });
      return 1;
    }
  }

  if ($FORM{PAYMENT_SYSTEM}) {
    my $payment_system_info = $Paysys->paysys_connect_system_info({
      PAYSYS_ID => $FORM{PAYMENT_SYSTEM},
      MODULE    => '_SHOW',
      COLS_NAME => '_SHOW'
    });

    if($Paysys->{errno}){
      print $html->message('err', "$lang{ERROR}", 'Payment system not exist');
    }
    else{
      my $Module = _configure_load_payment_module($payment_system_info->{module});
      my $Paysys_Object = $Module->new($db, $admin, \%conf, { HTML => $html });
      return  $Paysys_Object->user_portal($user, {
          %FORM,
        });
    }
  }

  my $connected_systems = $Paysys->paysys_connect_system_list({
    PAYSYS_ID => '_SHOW',
    NAME      => '_SHOW',
    MODULE    => '_SHOW',
    STATUS    => 1,
    COLS_NAME => 1,
    SORT      => 'priority',
  });

  $TEMPLATES_ARGS{OPERATION_ID} = mk_unique_value(8, { SYMBOLS => '0123456789' });
  if (in_array('Maps', \@MODULES)) {
#    $TEMPLATES_ARGS{MAP} = paysys_maps();
  }

  my $groups_settings = $Paysys->groups_settings_list({
    PAYSYS_ID => '_SHOW',
    GID       => '_SHOW',
    COLS_NAME => 1,
  });

  my %group_to_paysys_id = ();
  foreach my $group_settings (@$groups_settings){
    push( @{$group_to_paysys_id{$group_settings->{gid}}}, $group_settings->{paysys_id} );
  }

  my $count = 1;
  foreach my $payment_system (@$connected_systems) {

    if( $user->{GID}
        && exists $group_to_paysys_id{$user->{GID}}
        && !( in_array($payment_system->{paysys_id}, $group_to_paysys_id{$user->{GID}}) )
    ){
      next;
    }

    if($user->{GID} && !$group_to_paysys_id{$user->{GID}}){
      next;
    }
    my $Module = _configure_load_payment_module($payment_system->{module});

    if ($Module->can('user_portal')) {

      $TEMPLATES_ARGS{PAY_SYSTEM_SEL} .= _paysys_system_radio({
        NAME    => $payment_system->{name},
        MODULE  => $payment_system->{module},
        ID      => $payment_system->{paysys_id},
        CHECKED => $count == 1 ? 'checked' : '',
      });
      $count++;
    }
    elsif ($Module->can('user_portal_special')) {
      my $Paysys_Object = $Module->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang, INDEX => $index, SELF_URL => $SELF_URL });
      $TEMPLATES_ARGS{IPAY_HTML} = $Paysys_Object->user_portal_special($user, { %FORM });
    }
  }

  return $html->tpl_show(_include('paysys_main', 'Paysys'), \%TEMPLATES_ARGS,
    { OUTPUT2RETURN => $attr->{OUTPUT2RETURN} });
}

#**********************************************************
=head2 _paysys_system_radio($attr) - Show availeble payment system

=cut
#**********************************************************
sub _paysys_system_radio {
  my ($attr) = @_;

  my $radio_paysys;
  my $paysys_logo_path = $base_dir . 'cgi-bin/styles/default_adm/img/paysys_logo/';
  my $file_path = q{};

  my $paysys_name   = $attr->{NAME};
  my ($paysys_module) = $attr->{MODULE} =~ /(.+)\.pm$/ ;
  $paysys_module =~ s/ /_/g;
  $paysys_module = lc($paysys_module);

  if (-e "$paysys_logo_path" . lc($paysys_module) . "-logo.png") {
    $file_path = "/styles/default_adm/img/paysys_logo/" . lc($paysys_module) . "-logo.png";
  }
  else {
    $file_path = "http://abills.net.ua/wiki/lib/exe/fetch.php/abills:docs:modules:paysys:" . lc("$paysys_module") . "-logo.png";
  }

  $radio_paysys .= $html->tpl_show(
    _include('paysys_system_select', 'Paysys'),
    {
      PAY_SYSTEM_LC   => $file_path,
      PAY_SYSTEM      => $attr->{ID},
      PAY_SYSTEM_NAME => $paysys_name,
      CHECKED         => $attr->{CHECKED}
    },
    { OUTPUT2RETURN => 1 }
  );

  return $radio_paysys;
}


#**********************************************************
=head2 paysys_user_log()

=cut
#**********************************************************
sub paysys_user_log {

  my %PAY_SYSTEMS = ();

  my $connected_systems = $Paysys->paysys_connect_system_list({
    PAYSYS_ID => '_SHOW',
    NAME      => '_SHOW',
    MODULE    => '_SHOW',
    STATUS    => 1,
    COLS_NAME => 1,
  });

  foreach my $payment_system (@$connected_systems) {
    $PAY_SYSTEMS{$payment_system->{paysys_id}} = $payment_system->{name};
  }

  if ($FORM{info}) {
    $Paysys->info({ ID => $FORM{info} });

    my @info_arr = split(/\n/, $Paysys->{INFO});
    my $table = $html->table({ width => '100%' });
    foreach my $line (@info_arr) {
      my ($k, $v) = split(/,/, $line, 2);
      $table->addrow($k, $v) if ($k =~ /STATUS/);
    }

    $Paysys->{INFO} = $table->show({ OUTPUT2RETURN => 1 });

    $table = $html->table(
      {
        width => '500',
        rows  =>
        [ [ "ID", $Paysys->{ID} ],
          [ "$lang{LOGIN}", $Paysys->{LOGIN} ],
          [ "$lang{DATE}", $Paysys->{DATETIME} ],
          [ "$lang{SUM}", $Paysys->{SUM} ],
          [ "$lang{PAY_SYSTEM}", $PAY_SYSTEMS{ $Paysys->{SYSTEM_ID} } ],
          [ "$lang{TRANSACTION}", $Paysys->{TRANSACTION_ID} ],
          [ "$lang{USER} IP", $Paysys->{CLIENT_IP} ],
          [ "$lang{ADD_INFO}", $Paysys->{USER_INFO} ],
          [ "$lang{INFO}", $Paysys->{INFO} ] ],
      }
    );

    print $table->show();
  }

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my $list = $Paysys->list({ %LIST_PARAMS, COLS_NAME => 1 });
  my $table = $html->table(
    {
      width   => '100%',
      caption => "Paysys",
      title   =>
      [ 'ID', "$lang{DATE}", "$lang{SUM}", "$lang{PAY_SYSTEM}", "$lang{TRANSACTION}", "$lang{STATUS}", '-' ],
      qs      => $pages_qs,
      pages   => $Paysys->{TOTAL},
      ID      => 'PAYSYS'
    }
  );

  foreach my $line (@$list) {
    $table->addrow($line->{id},
      $line->{datetime},
      $line->{sum},
      $PAY_SYSTEMS{$line->{system_id}},
      $line->{transaction_id},
      #"$status[$line->{status}]",
      $html->color_mark($status[$line->{status}], "$status_color[$line->{status}]"),
      $html->button($lang{INFO}, "index=$index&info=$line->{id}"));
  }
  print $table->show();

  $table = $html->table(
    {
      width => '100%',
      rows  =>
      [ [ "$lang{TOTAL}:", $html->b($Paysys->{TOTAL_COMPLETE}), "$lang{SUM}:", $html->b($Paysys->{SUM_COMPLETE}) ] ]
    }
  );
  print $table->show();

  return 1;
}

1;