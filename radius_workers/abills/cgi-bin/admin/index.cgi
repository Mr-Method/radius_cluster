#!/usr/bin/perl

=head1 NAME

Main ABillS Admin Web interface

=cut

use strict;
use warnings FATAL => 'all';

BEGIN {
  our $libpath = '../../';
  eval { do "$libpath/libexec/config.pl" };
  our %conf;

  if(!%conf){
    print "Content-Type: text/plain\n\n";
    print "Error: Can't load config file 'config.pl'\n";
    print "Create ABillS config file /usr/abills/libexec/config.pl\n";
    exit;
  }

  my $sql_type = $conf{dbtype} || 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/",
    $libpath . '/lib/',
    $libpath,
    $libpath . 'Abills/',
    $libpath . 'Abills/mysql/',
    $libpath . 'Abills/modules/'
  );

  eval { require Time::HiRes; };
  our $begin_time;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

our ($libpath,
  $base_dir,
  %err_strs,
  %LANG,
  %lang,
  @MONTHES,
  @WEEKDAYS,
  %permissions,
  @state_colors,
  %functions,
  $ui
);

#use lib (
#  $libpath . '/lib/',
#  $libpath,
#  $libpath ."Abills/mysql/",
#  $libpath . 'Abills/modules/');

use Abills::Defs;
use Abills::Base;
use POSIX qw(strftime mktime);
use Admins;
use Users;
use Finance;
use Shedule;

our $db    = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { %conf, CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
our $admin = Admins->new($db, \%conf);
our $Conf  = Conf->new($db, $admin, \%conf);

require Abills::Misc;
require Abills::Fetcher;

$conf{base_dir}=$base_dir if (! $conf{base_dir});

our @default_search  = ( 'UID', 'LOGIN', 'FIO', 'CONTRACT_ID',
    'EMAIL', 'PHONE', 'COMMENTS', 'ADDRESS_FULL', 'CITY' );

our $html = Abills::HTML->new(
  {
    CONF     => \%conf,
    NO_PRINT => 0,
    PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
    CHARSET  => $conf{default_charset},
    COLORS   => $conf{DEFAULT_ADMIN_WEBCOLORS},
    %{ ($admin->{SETTINGS}) ? $admin->{SETTINGS} : {} }
  }
);

require Abills::Templates;
form_auth();

if ($admin->{DOMAIN_ID}) {
  $conf{WEB_TITLE} = $admin->{DOMAIN_NAME};
  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID};
  require Multidoms;
  Multidoms->import();
  my $Domains = Multidoms->new($db, $admin, \%conf);
  my $admin_domains = $Domains->admins_list({ AID => $admin->{AID}, COLS_NAME => 1 });
  if($Domains->{TOTAL}) {
    my @domains_list = ();
    foreach my $line (@$admin_domains) {
      push @domains_list, $line->{domain_id};
    }
    $LIST_PARAMS{DOMAIN_ID} = join(',', @domains_list);
    $admin->{DOMAIN_ID} = $LIST_PARAMS{DOMAIN_ID};
  }
}

$admin->{SETTINGS}{SKIN} = $admin->{SETTINGS}{SKIN} || 'skin-blue';
$admin->{SETTINGS}{RIGHT_MENU_SKIN} = ($admin->{SETTINGS}{MENU_SKIN}) ? 'control-sidebar-light' : 'control-sidebar-dark';
$admin->{SETTINGS}{FIXED_LAYOUT} = ($admin->{SETTINGS}{FIXED}) ? 'fixed' : '';
$admin->{MENU_HIDDEN} = (defined($COOKIES{"menuHidden"}) && $COOKIES{menuHidden} eq 'true') ? 'sidebar-collapse' : '';
$admin->{RIGHT_MENU_OPEN} = ($FORM{UID} && !$admin->{SETTINGS}{RIGHT_MENU_HIDDEN}) ? 'control-sidebar-open' : '';
$html->set_cookies('sid', $admin->{SID}, '', '/');

#Operation system ID
if ($FORM{OP_SID}) {
  $html->set_cookies('OP_SID', $FORM{OP_SID}, '', '', { SKIP_SAVE => 1 });
}

if ($index == 2) {
  if ($FORM{hold_date}) {
    $html->set_cookies('hold_date', $FORM{DATE}, "Fri, 1-Jan-2038 00:00:01", '');
  }
  elsif ($FORM{OP_SID}) {
    $html->set_cookies('hold_date', '', "Fri, 1-Jan-2038 00:00:01", '');
  }

  if ($FORM{OP_SID}) {
    $html->set_cookies('INNER_DESCRIBE', $FORM{INNER_DESCRIBE}, "Fri, 1-Jan-2038 00:00:01", '');
    delete $COOKIES{INNER_DESCRIBE} if (!$FORM{INNER_DESCRIBE});
  }

  if (!$FORM{INNER_DESCRIBE} && $COOKIES{INNER_DESCRIBE} && $conf{PAYMENTS_INNER_DESCRIBE_AUTOCOMPLETE}) {
    $FORM{INNER_DESCRIBE} = $COOKIES{INNER_DESCRIBE};
  }
}

if (defined($FORM{DOMAIN_ID})) {
  $html->set_cookies('DOMAIN_ID', "$FORM{DOMAIN_ID}", "Fri, 1-Jan-2038 00:00:01", $html->{web_path});
}

#Admin Web_options
if ($FORM{AWEB_OPTIONS}) {
  my %WEB_OPTIONS = (
    language          => 1,
    REFRESH           => 1,
    QUICK_REPORTS_SORT => 1,
    COLORS            => 1,
    PAGE_ROWS         => 1,
    QUICK_REPORTS     => 1,
    NO_EVENT          => 1,
    NO_EVENT_SOUND    => 1,
    GROUP_ID          => '',
    SEARCH_FIELDS     => 1,
    SKIN              => 'skin-blue',
    FIXED             => '',
    MENU_SKIN         => 1,
    RIGHT_MENU_HIDDEN => 0,
    HEADER_FIXED      => 1,
  );

  my $web_options = '';

  if (!$FORM{default}) {
    while (my ($k, undef) = each %WEB_OPTIONS) {
      if ($FORM{$k}) {
        $web_options .= "$k=$FORM{$k};";
      }
      else {
        $web_options .= "$k=$admin->{SETTINGS}{$k};" if ($admin->{SETTINGS}{$k} && ! defined($FORM{$k}));
      }
    }
  }
  else {
    $admin->settings_del();
  }

  if (defined($FORM{quick_set})) {
    my (@qm_arr) = split(/, /, $FORM{qm_item} || q{});
    $web_options .= "qm=";
    foreach my $line (@qm_arr) {
      $web_options .= (defined($FORM{ 'qm_name_' . $line })) ? "$line:" . $FORM{ 'qm_name_' . $line } . "," : "$line:,";
    }
    chop($web_options);
  }
  else {
    $web_options .= ($admin->{SETTINGS} && $admin->{SETTINGS}{qm}) ? "qm=$admin->{SETTINGS}{qm};" : q{};
  }

  $admin->change({ AID => $admin->{AID}, WEB_OPTIONS => $web_options });

  if ($FORM{QUICK}){
    print "Content-Type : text/html;\n\n";
    exit;
  }

  print "Location: $SELF_URL?index=$FORM{index};\n\n";
  exit;
}

#===========================================================
if ($admin->{GID}) {
  $LIST_PARAMS{GID} = $admin->{GID};
}

if ($admin->{MAX_ROWS} > 0) {
  $LIST_PARAMS{PAGE_ROWS} = $admin->{MAX_ROWS};
  $FORM{PAGE_ROWS}        = $admin->{MAX_ROWS};
  $html->{MAX_ROWS}       = $admin->{MAX_ROWS};
}

#Global Vars
our @bool_vals  = ($lang{NO}, $lang{YES});
our @status     = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE});
our %uf_menus   = ();  #User form menu list
our %menu_args  = ();
our %module     = ();

fl();

my @service_status = ("$lang{ENABLE}", "$lang{DISABLE}", "$lang{NOT_ACTIVE}", "$lang{HOLD_UP}",
  "$lang{DISABLE}: $lang{NON_PAYMENT}", "$lang{ERR_SMALL_DEPOSIT}");
my @service_status_colors = ($_COLORS[9], $_COLORS[6], '#808080', '#0000FF', '#FF8000', '#009999');

our $users  = Users->new($db, $admin, \%conf);
my $Shedule = Shedule->new($db, $admin, \%conf);

#Quick index
# Show only function results whithout main windows
if ($FORM{qindex} || $FORM{get_index}) {
  my $xml_start_teg = '';

  if ($FORM{get_index}) {
    $index = get_function_index($FORM{get_index});
    goto FULL_MODE if ($FORM{full});
  }
  else {
    $index = $FORM{qindex};
  }

  if ($FORM{header}) {
    $html->{METATAGS} = templates('metatags');
    print $html->header(\%FORM);
    if ($FORM{UID} || ($FORM{type} && $FORM{type} == 11)) {
      $ui = user_info($FORM{UID}, { LOGIN => ($FORM{LOGIN}) ? $FORM{LOGIN} : undef });
      if ($FORM{xml}) {
        $xml_start_teg = 'user_info';
        print "<$xml_start_teg>";
      }
    }
    else{
      if ($FORM{xml}) {
        $xml_start_teg = 'info';
        print "<$xml_start_teg>"
      }
    }
  }
#  else {
#    if ($FORM{UID} || ($FORM{type} && $FORM{type} == 11)) {
#      $ui = user_info($FORM{UID}, { LOGIN => ($FORM{LOGIN}) ? $FORM{LOGIN} : undef });
#    }
#  }

  if ($index && $index == -1) {
    $html->{METATAGS} = templates('metatags');
    print $html->header();
    form_purchase_module({ MODULE => $FORM{MODULE} });
    exit;
  }

  if (defined($module{$index})) {
    load_module($module{$index}, $html);
  }

  _function($index, { USER_INFO => $ui });

  print "</$xml_start_teg>" if ($FORM{xml});

  if ($admin->{FULL_LOG} && $functions{$index} && $functions{$index} ne 'form_events') {
    $admin->full_log_add({
      FUNCTION_INDEX => $index,
      AID            => $admin->{AID},
      FUNCTION_NAME  => $functions{$index},
      DATETIME       => 'NOW()',
      IP             => $admin->{SESSION_IP},
      SID            => $admin->{SID},
      PARAMS         => $FORM{__BUFFER}
    });
  }
  if($html->can('fetch')) {
    $html->fetch();
  }
  exit;
}

if ($FORM{POPUP} && $FORM{POPUP} == 1) {
  print "Content-type: text/html\n\n";
  get_popup_info();
  exit;
}

FULL_MODE:
#Make active lang list
if ($conf{LANGS}) {
  $conf{LANGS} =~ s/\n//g;
  my (@lang_arr) = split(/;/, $conf{LANGS});
  %LANG = ();
  foreach my $l (@lang_arr) {
    my ($lang, $lang_name) = split(/:/, $l);
    $lang =~ s/^\s+//;
    $LANG{$lang} = $lang_name;
  }
}

if ($conf{CALLCENTER_MENU}) {
  $html->{CALLCENTER_MENU} = $html->tpl_show(templates('form_callcenter_menu'), { CALLCENTER_MENU => '' }, { OUTPUT2RETURN => 1 });
}

if (defined($permissions{4}) && $permissions{4}{7}) {
  $html->{CHANGE_TPLS}=1;
}

$html->{METATAGS} = templates('metatags');
if ((($FORM{UID} && $FORM{UID} =~ /^(\d+)$/
   && $FORM{UID} > 0)
   || ($FORM{LOGIN} && $FORM{LOGIN} !~ /\*/
     && !$FORM{add} && !$FORM{next} ))
     && $permissions{0}
   ) {
  if (! $FORM{type} || $FORM{type} ne 10){
    if ( $FORM{PRE} || $FORM{NEXT} ){
      my $list = $users->list( { UID => (($FORM{PRE}) ? '<' : '>') . "$FORM{UID}", PAGE_ROWS => 1, COLS_NAME => 1, SORT
                                     => 'u.uid' } );
      $FORM{UID} = $list->[0]->{uid};
    }

    $ui = user_info( $FORM{UID}, { LOGIN => ($FORM{LOGIN}) ? $FORM{LOGIN} : undef, QUITE => 1 } );
    if ( $ui ){
      $html->{WEB_TITLE} = ($conf{WEB_TITLE} || '') .'['. ( $ui->{LOGIN} || q{deleted} ) .']';
    }
  }
}

my ($menu_text, $navigat_menu) = mk_navigator();
print $html->header();

($admin->{ONLINE_USERS}, $admin->{ONLINE_COUNT}) = $admin->online({ SID => $admin->{SID} });
$admin->{ONLINE_USERS} =~ s/\n/<br\/>/g;
$html->{LANG} = { GO2PAGE => $lang{GO2PAGE} };

my %SEARCH_TYPES = (
  10 => $lang{UNIVERSAL},
  11 => $lang{USERS},
  2  => $lang{PAYMENTS},
  3  => $lang{FEES},
  13 => $lang{COMPANY}
);

if (defined($FORM{index}) && $FORM{index} != 7 && !defined($FORM{type})) {
  $FORM{type} = $FORM{index};
}
elsif (!defined $FORM{type}) {
  $FORM{type} = 15;
}

$admin->{SEL_TYPE} = $html->form_select(
  'type',
  {
    SELECTED => (!$SEARCH_TYPES{ $FORM{type} }) ? 10 : $FORM{type},
    SEL_HASH => \%SEARCH_TYPES,
    NO_ID    => 1,
    ID       => 'type',
    class    => 'form-control input-sm margin search-type-select'
  }
);
$admin->{SEL_TYPE_SM} = $html->form_select(
  'type',
  {
    SELECTED => (!$SEARCH_TYPES{ $FORM{type} }) ? 10 : $FORM{type},
    SEL_HASH => \%SEARCH_TYPES,
    NO_ID    => 1,
    FORM_ID     => 'SMALL_SEARCH_FORM',
    ID       => 'type',
    class    => 'form-control input-sm margin search-type-select'
  }
);
#Domains sel
if (in_array('Multidoms', \@MODULES) && $permissions{10}) {
  load_module('Multidoms', $html);
  $FORM{DOMAIN_ID}        = $COOKIES{DOMAIN_ID};
  $admin->{DOMAIN_ID}     = $FORM{DOMAIN_ID};
  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} if($admin->{DOMAIN_ID} && $admin->{DOMAIN_ID} =~ /\d+/);
  $admin->{SEL_DOMAINS} = "$lang{DOMAINS}:"
  . $html->form_main(
    {
      CONTENT => multidoms_domains_sel(),
      HIDDEN  => {
        index      => $index,
        COMPANY_ID => $FORM{COMPANY_ID}
      },
      SUBMIT  => { action => "$lang{CHANGE}" }
    }
  );
}

## Visualisation begin
$admin->{DATE} = $DATE;
$admin->{TIME} = $TIME;
if ($conf{tech_works}) {
  $admin->{TECHWORK} = $html->message('err', $conf{tech_works}, '');
}

#Quick Menu
if ($admin->{SETTINGS} && !$FORM{xml}) {
  form_admin_qm();
}

my $function_name = $functions{$index} || q{};
my $module_name   = ($module{$index}) ? "$module{$index}:" : '';

print $html->tpl_show(templates('header'), { %$admin,
                                             HEADER_FIXED_CLASS  => $admin->{SETTINGS}{HEADER_FIXED} ? 'navbar-fixed-top' : '',
                                             MENU          => $menu_text,
                                             BREADCRUMB    => $navigat_menu,
                                             FUNCTION_NAME => "$module_name$function_name"
                                            },
                                            { OUTPUT2RETURN => 1 });

admin_quick_setting();

$admin->{RIGHT_MENU} = $html->menu_right($html->element('i', '', { class=>'fa fa-th-list' }), "quick_menu", $admin->{QUICK_MENU}, { HTML => $admin->{RIGHT_MENU} } );
$admin->{RIGHT_MENU} = $html->menu_right($html->element('i', '', { class=>'fa fa-user' }), "user_menu", $admin->{USER_MENU}, { HTML => $admin->{RIGHT_MENU} } ) if (defined($admin->{USER_MENU}));

if ($function_name) {
  if (defined($module{$index})) {
    load_module($module{$index}, $html);
  }

  if (($FORM{UID} && $FORM{UID} =~ /^\d+$/ && $FORM{UID} > 0) || ($FORM{LOGIN} && $FORM{LOGIN} ne '' && $FORM{LOGIN} !~ /\*/ && !$FORM{add})){
    if ( $ui && $ui->{TABLE_SHOW} ){
      print $ui->{TABLE_SHOW};
    }

    if ($ui && $ui->{errno} && $ui->{errno} == 2) {
      $html->message( 'err', $lang{ERROR}, "[$FORM{UID}] $lang{USER_NOT_EXIST}" );
    }
    elsif ($admin->{GID} && $ui && $ui->{GID} && $admin->{GID} !~ /$ui->{GID}/) {
      $html->message( 'err', $lang{ERROR}, "[$FORM{UID}] $lang{USER_NOT_EXIST} GID: $admin->{GID} / ". ($ui->{GID} || '-') );
    }
    else {
      _function($index, { USER_INFO => $ui });
    }
  }
  elsif ($index == 0) {
    form_start();
  }
  else {
    _function($index);
  }
}
else {
  if (! $index) {
    form_start();
  }
  else {
    $html->message( 'err', $lang{ERROR}, "Function not exist ($index / $function_name)" );
  }
}

if ($admin->{FULL_LOG}) {
  $admin->full_log_add( {
      FUNCTION_INDEX => $index,
      AID            => $admin->{AID},
      FUNCTION_NAME  => $function_name,
      DATETIME       => 'NOW()',
      IP             => $admin->{SESSION_IP},
      SID            => $admin->{SID},
      PARAMS         => $FORM{__BUFFER}
  });
}

if ($begin_time > 0) {
  $conf{VERSION} = get_version();

  my $debug_mode = ($^D) ? "Debug: $^D" : '';

  $admin->{VERSION} = ($admin->{SEL_DOMAINS} || q{}) . $conf{VERSION} . ' ('. gen_time($begin_time) . ") $debug_mode";

  if (defined($permissions{4})) {
    my $output = '';
    if(-f "$conf{TPL_DIR}/NEW_VERSION") {
      my ($ctime) = (stat("$conf{TPL_DIR}/NEW_VERSION"))[10];
      if (time - $ctime < 166000) {
        open(my $fh, '<', "$conf{TPL_DIR}/NEW_VERSION");
          $output = <$fh>;
        close($fh);
      }
    }

    if(! $output) {
      #Get new version
      $output = web_request('http://abills.net.ua/misc/checksum/VERSION', { BODY_ONLY => 1, TIMEOUT => 1 });
      if(! $output) {
        $output = $conf{VERSION};
      }

      if (open(my $fh, '>', "$conf{TPL_DIR}/NEW_VERSION")) {
        print $fh $output;
        close($fh);
      }
    }

    $conf{VERSION}=~/\d+\.(\d+\.\d+)/;
    my $cur_version = $1 || 0;
    $output =~ s/\d+\.(\d+\.\d+)//;
    $output = $1 || 0;
    if($output && $output > $cur_version) {
      $admin->{VERSION} .= $html->button("NEW VERSION: 0.$output", "", { GLOBAL_URL => 'http://abills.net.ua/wiki/doku.php/abills:changelogs:0.7x', class => 'btn btn-xs btn-success', ex_params => ' target=_blank' });
    }
  }
}

if ($conf{dbdebug} && $admin->{db}->{queries_count}) {
  $admin->{VERSION} .= " q: $admin->{db}->{queries_count}";

  if ($admin->{db}->{queries_list} && $permissions{4}{5}) {
    my $queries_list = "Queries:<br><textarea cols=160 rows=10>";

    my $i = 0;
    my @q_arr = (ref $Conf->{db}->{queries_list} eq 'HASH') ? keys %{ $Conf->{db}->{queries_list} } : @{ $Conf->{db}->{queries_list} };

    foreach my $k (@q_arr) {
      $i++;
      my $count = (ref $Conf->{db}->{queries_list} eq 'HASH') ? " ($Conf->{db}->{queries_list}->{$k})" : '';
      $queries_list .= "$i $count";
      $queries_list .= " ===================================\n      $k\n ";
    }
    $queries_list .= "</textarea>";
    $admin->{VERSION} .= $html->tpl_show( templates('form_show_hide'),
      {
        CONTENT => $queries_list,
        NAME    => 'Queries: '.$i,
        ID      => 'QUERIES',
        PARAMS  => 'collapsed-box'
      },
      { OUTPUT2RETURN => 1 } );
  }
}

# Check if default password has been changed
if (!$conf{DEFAULT_PASSWORD_CHANGED}
  && $admin->{AID} == 1
  && $admin->{A_LOGIN} && $admin->{A_LOGIN} eq 'abills'
  && $html->{TYPE} eq 'html') {

  # Check it's not just an updated version with new password, but without conf variable
  $admin->info(1, { LOGIN => 'abills', PASSWORD => 'abills' });

  # $admin->{PASSWORD_MATCH}. Unexpected inverted logic
  # True means password NOT matches.
  # False means this is 'abills' admin with 'abills' password
  if (!$admin->{PASSWORD_MATCH}){
    $html->reminder($lang{WARNING}, $html->button($lang{PLEASE_CHANGE_DEFAULT_PASSWORD}, "index=50&subf=54&AID=1"), {
      class => 'danger'
    });
  }
  else {
    $Conf->config_add({ PARAM => 'DEFAULT_PASSWORD_CHANGED', VALUE => 1, REPLACE => 1});
    _error_show($Conf);
    $conf{DEFAULT_PASSWORD_CHANGED} = 1;
  }
}

if (!$conf{GUIDE_DISABLED} && $html->{TYPE} eq 'html'){
  if ($FORM{tour_ended}){
    $Conf->config_add({ PARAM => 'ADMIN_HAS_VIEWED_TOUR_' . $admin->{AID}, VALUE => 1, REPLACE => 1});
  }
  elsif(!$conf{'ADMIN_HAS_VIEWED_TOUR_' . $admin->{AID}}){
    $html->tpl_show( templates('interface_guide'));
  }
}

print $html->tpl_show(templates('footer'), $admin, { OUTPUT2RETURN => 1, RIGHT_MENU => $admin->{RIGHT_MENU} });
$html->test();

#**********************************************************
=head2 form_auth() - Primary auth form

=cut
#**********************************************************
sub form_auth {
  #Cookie auth
  if ($conf{AUTH_METHOD}) {
    if ($index == 10) {
      $admin->online_del({ SID => $COOKIES{sid} });
    }

    if (! $html || ! $html->{language}) {
      $html->{language}='english';
    }

    if($html->{language} ne 'english') {
      do "language/english.pl"
    }
    eval { do "language/$html->{language}.pl" };

    if($@) {
      print "Content-Type: text/plain\n\n";
      print "Can't load language\n";
      print $@;
      print ">> language/$html->{language}.pl << ";
      exit;
    }

    #require Abills::Templates;

    my $res = check_permissions($FORM{user}, $FORM{passwd}, $COOKIES{sid}, \%FORM);

    if (! $res) {
      if ($FORM{REFERER} && $FORM{REFERER} =~ /$SELF_URL/ && $FORM{REFERER} !~ /index=10/) {
        $html->set_cookies('sid', $admin->{SID}, '', '/');
        $COOKIES{sid} = $admin->{SID};
        $admin->online({ SID => $admin->{SID} });
        print "Location: $FORM{REFERER}\n\n";
      }

      if ($FORM{API_INFO}) {
        form_system_info($FORM{API_INFO});
        exit;
      }
    }
    else {
      $html->{METATAGS} = templates('metatags');
      #$html->set_cookies('sid', '', '', '/');
      print $html->header();
      form_login();
      print "<!-- Access Deny Coockie: ". ($COOKIES{sid} || ''). " System: ". ($admin->{SID} || '') ." $res -->";

      if ($ENV{DEBUG}) {
        die();
      }
      else {
        exit 0;
      }
    }
  }

  #**********************************************************
  #IF Mod rewrite enabled Basic Auth
  #
  #    <IfModule mod_rewrite.c>
  #        RewriteEngine on
  #        RewriteCond %{HTTP:Authorization} ^(.*)
  #        RewriteRule ^(.*) - [E=HTTP_CGI_AUTHORIZATION:%1]
  #        Options Indexes ExecCGI SymLinksIfOwnerMatch
  #    </IfModule>
  #    Options Indexes ExecCGI FollowSymLinks
  #
  #**********************************************************
  else {
    if (defined($ENV{HTTP_CGI_AUTHORIZATION})){
      $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
      my ($REMOTE_USER, $REMOTE_PASSWD) = split( /:/, decode_base64( $ENV{HTTP_CGI_AUTHORIZATION} ) );

      if ( $REMOTE_USER ){
        $REMOTE_USER = substr( $REMOTE_USER, 0, 20 );
        $REMOTE_USER =~ s/\\//g;
      }
      else {
        $REMOTE_USER = q{};
      }
      if ($REMOTE_PASSWD) {
        $REMOTE_PASSWD = substr($REMOTE_PASSWD, 0, 20);
        $REMOTE_PASSWD=~s/\\//g;
      }

      my $res = check_permissions($REMOTE_USER, $REMOTE_PASSWD);
      if ($res == 1) {
        print "WWW-Authenticate: Basic realm=\"$conf{WEB_TITLE} Billing System\"\n";
        print "Status: 401 Unauthorized\n";
      }
      elsif ($res == 2) {
        print "WWW-Authenticate: Basic realm=\"Billing system / '$REMOTE_USER' Account Disabled\"\n";
        print "Status: 401 Unauthorized\n";
      }
    }
    else {
      print "'mod_rewrite' not install";
    }

    if ($admin->{errno}) {
      print "Content-Type: text/html\n\n";
      print $html->header();
      my $message = $lang{ERR_ACCESS_DENY};

      if ($admin->{errno} == 2) {
        $message = "Account DISABLE or $admin->{errstr}";
      }
      elsif ($admin->{errno} == 3) {
        $message = $lang{ERR_UNALLOW_IP};
      }
      elsif ($admin->{errno} == 4) {
        $message = $lang{ERR_WRONG_PASSWD} || 'ERR_WRONG_PASSWD';
      }
      else {
        $message = $err_strs{ $admin->{errno} };
      }

      $html->message( 'err', $lang{ERROR}, "$message" );
      exit;
    }
  }

  if($html->{language} ne 'english') {
    do "language/english.pl"
  }
  do "$libpath/language/$html->{language}.pl";

  return 1;
}

#**********************************************************
=head2 form_admin_qm()

=cut
#**********************************************************
sub form_admin_qm {
  return 1 if !$admin->{SETTINGS};

  $admin->{SETTINGS}{qm} //= '';
  my @a = split(/,/, $admin->{SETTINGS}->{qm});
  my $i = 0;
  $admin->{QUICK_MENU} = "<ul class='control-sidebar-menu' id='admin-quick-menu'>";
  my $quick_menu_script = "<script>";
  my $qm_btns_counter = 0;

  my %rev_functions = reverse %functions;

  foreach my $line ( @a ) {
    my ($qm_id_name, $qm_name) = split(/:/, $line, 2);
    next if($qm_id_name eq 'null');
    my $qm_id = $rev_functions{$qm_id_name};

    if(! $qm_id) {
      next;
    }

    $qm_id =~ s/sub//;

    my $active = ($qm_id eq $index) ? " active" : '';
    if ( !$qm_name ) {
      next if (!$menu_names{$qm_id});
      $qm_name = $menu_names{$qm_id};
    }

    my $button = '';
    if ( defined($menu_args{$qm_id}) && $menu_args{$qm_id} !~ /=/ ) {
      $button = "<a class='$active' onclick='openModal($qm_btns_counter, \"ArrayBased\")' ><i class='fa fa-circle-o'></i>$qm_name</a>";
      $quick_menu_script .= "modalsSearchArray.push(['$lang{LOGIN}','LOGIN',$qm_id,'$SELF_URL']);\n";
      $qm_btns_counter++;
    }
    else {
      my $args = ($menu_args{$qm_id} && $menu_args{$qm_id} =~ /=/) ? '&' . $menu_args{$qm_id} : '';
      $button = $html->button( $html->element( 'i', '', { class => 'fa fa-circle-o' } ) . $qm_name, "index=$qm_id$args",
        { class => $active } );
    }
    $i++;
    $admin->{QUICK_MENU} .= $html->li( $button, { class => $active } );
  }

  $admin->{QUICK_MENU} .= $html->li( $html->button( $lang{ADD}, "index=110",
      { class => "btn bg-green btn-block btn-flat" } ) );
  $admin->{QUICK_MENU} .= $quick_menu_script . "</script>";
  $admin->{QUICK_MENU} .= "</ul>";

  return 1;
}

#**********************************************************
=head2 check_permissions() - Checkadmin permission

  Arguments:
    $login
    $password
    $session_sid
    $attr
      API_KEY

  Returns:

    0 - Access
    1 - Deny
    2 - Disable
    3 - Deny IP
    4 - Wrong passwd
    5 - Wrong LDAP Auth
    6 - Deny IP/Time

=cut
#**********************************************************
sub check_permissions {
  my ($login, $password, $session_sid, $attr) = @_;

  $login    = '' if (!defined($login));
  $password = '' if (!defined($password));

  if ($conf{ADMINS_ALLOW_IP}) {
    $conf{ADMINS_ALLOW_IP} =~ s/ //g;
    my @allow_ips_arr = split(/,/, $conf{ADMINS_ALLOW_IP});
    my %allow_ips_hash = ();
    foreach my $ip (@allow_ips_arr) {
      $allow_ips_hash{$ip} = 1;
    }
    if (!$allow_ips_hash{ $ENV{REMOTE_ADDR} }) {
      $admin->system_action_add("$login:$password DENY IP: $ENV{REMOTE_ADDR}", { TYPE => 11 });
      $admin->{errno} = 3;
      return 3;
    }
  }

  my %PARAMS = (
    IP    => $ENV{REMOTE_ADDR} || '0.0.0.0',
    SHORT => 1
  );

  $login    =~ s/"/\\"/g;
  $login    =~ s/'/\''/g;
  $password =~ s/"/\\"/g;
  $password =~ s/'/\\'/g;

  if ($session_sid && ! $login) { # && ! $attr->{API_KEY}) {
    $admin->online_info({ SID => $session_sid });
    if ($admin->{TOTAL} > 0 && $ENV{REMOTE_ADDR} eq $admin->{IP}) {
      $admin->{SID} = $session_sid;
    }
    else {
      $admin->online_del({ SID => $session_sid });
    }
  }
  else {
    if (! $session_sid) {
      Abills::HTML::get_cookies();
      $admin->{SID} = $COOKIES{sid};
    }
    else {
      $admin->{SID} = mk_unique_value(14);
    }

    #LDAP auth
    if($conf{LDAP_IP}) {
      require "Abills::Auth::Ldap";
      Abills::Auth::Ldap->import();
      my $Auth = Abills::Auth::Core->new({
        CONF      => \%conf,
        AUTH_TYPE => $FORM{external_auth}
      });

      my $result = $Auth->check_access({
        LOGIN    => $login . ',ou=users',
        PASSWORD => $password
      });

      if ($result) {
        $PARAMS{LOGIN}   = $login;
        $PARAMS{EXTERNAL_AUTH} = 'ldap';
      }
      else {
        $admin->{errno} = 5;
        return 2;
      }
    }
    elsif($attr->{API_KEY}) {
      $PARAMS{API_KEY}   = $attr->{API_KEY};
    }
    else {
      $PARAMS{LOGIN}   = "$login";
      $PARAMS{PASSWORD}= "$password";
    }
  }

  $admin->info($admin->{AID}, \%PARAMS);

  if ($admin->{errno}) {
    if ($admin->{errno} == 4) {
      $admin->system_action_add("$login:$password", { TYPE => 11 });
      $admin->{errno} = 4;
    }
    elsif ($admin->{errno} == 2) {
      return 2;
    }

    return 1;
  }
  elsif ($admin->{DISABLE} == 1) {
    $admin->{errno}  = 2;
    $admin->{errstr} = 'DISABLED';
    return 2;
  }

  if ($admin->{WEB_OPTIONS}) {
    my @WO_ARR = split(/;/, $admin->{WEB_OPTIONS});
    foreach my $line (@WO_ARR) {
      my ($k, $v) = split(/=/, $line);
      next if(! $k);
      $admin->{SETTINGS}{$k} = $v;

      if ($html)  {
        $html->{$k}=$v;
      }
    }

    if($admin->{SETTINGS}{PAGE_ROWS} ) {
      $PAGE_ROWS = $FORM{PAGE_ROWS} || $admin->{SETTINGS}{PAGE_ROWS};
      $LIST_PARAMS{PAGE_ROWS}=$PAGE_ROWS;
    }
  }

  if ($admin->{ADMIN_ACCESS}) {
    my $list = $admin->access_list({ AID       => $admin->{AID},
                                     DISABLE   => 0,
                                     COLS_NAME => 1 });

    my $deny = ($admin->{TOTAL}) ? 1 : 0;
    foreach my $line (@$list) {
      my $time       = $TIME;
      $time          =~ s/://g;
      $line->{begin} =~ s/://g;
      $line->{end}   =~ s/://g;
      my $wday = (localtime(time))[6];

      if ((! $line->{day} || $wday+1 == $line->{day})
        && $time > $line->{begin} && $time < $line->{end}) {
        if (check_ip($ENV{REMOTE_ADDR}, "$line->{ip}/$line->{bit_mask}")) {
          $deny = 0;
          last;
        }
      }
    }

    if ($deny) {
      $admin->{MODULE}='';
      $admin->system_action_add("DENY IP: $ENV{REMOTE_ADDR}", { TYPE => 50 });
      return 6;
    }
  }

  %permissions = %{ $admin->get_permissions() };

  if (! $admin->{SID} && ! $attr->{API_KEY}) {
    $admin->{SID} = mk_unique_value(14);
  }

  return 0;
}

#**********************************************************
=head2 form_start($attr) - Start page

  Arguments:
    $attr
       SUB_MENU

  Return:
   TRUE or FALSE

=cut
#**********************************************************
sub form_start {
  my ($attr) = @_;

  $admin->{quick_report_menu}=1;
  return 0 if ($FORM{'xml'} && $FORM{'xml'} == 1);
  my $quick_reports = '';
  my @qr_arr = ();
  if ($attr->{SUB_MENU}) {
    foreach my $mod_name (@MODULES) {
      load_module($mod_name, $html);
      my $check_function = lc($mod_name) . $attr->{SUB_MENU};
      if ( defined(&$check_function) ) {
        push @qr_arr, "$mod_name:$check_function";
      }
    }
    $quick_reports = join(', ', @qr_arr);
  }

  my %start_page = ();
  if (! $quick_reports && $admin->{SETTINGS}) {
    $quick_reports = $admin->{SETTINGS}{QUICK_REPORTS};
    @qr_arr = split(/, /, $quick_reports) if ($quick_reports);
  }

  if ($#qr_arr > -1) {
    require Control::Quick_reports;
  }
  my %start_panels;
  my $filled_panels_counter = 0;
  my %loaded_modules = ();
  for(my $i=0; $i<=$#qr_arr; $i++) {
    my $fn;
    if ($qr_arr[$i]=~/:/) {
      my ($mod_name, $function) = split(/:/, $qr_arr[$i]);
      next if (!in_array($mod_name, \@MODULES));
      if (!exists $loaded_modules{$mod_name}) { load_module($mod_name, { %$html }) };
      if ( ! $@ ) {
        $fn = $function;
        $loaded_modules{$mod_name} = 1;
      }
      else {
        next;
      }
    }
    else {
      $fn = 'start_page_'.$qr_arr[$i];
    }

      $start_panels{"$qr_arr[$i]"} .= $html->element('div',(&{ \&$fn }()),{class =>'col-lg-4 col-md-6 start-panel', id => "$qr_arr[$i]"});
  }
  my $sort_quick_reports = $admin->{SETTINGS}{QUICK_REPORTS_SORT};
  if($sort_quick_reports){
    my @sort_qr_arr = split(/, /, $sort_quick_reports);
    my $i=0;
    foreach  my $sort_panel (@sort_qr_arr){
      if($start_panels{"$sort_panel"}){
          $start_page{'INFO'} .=  $start_panels{"$sort_panel"};
          delete $start_panels{"$sort_panel"};
      }
    }

   foreach  my $sort_panel (keys %start_panels){
      $start_page{'INFO'} .= $start_panels{"$sort_panel"};
    }
  }
  else{
    foreach my $panel_name (keys %start_panels){
      $start_page{'INFO'} .=  $start_panels{$panel_name};
      delete $start_panels{"$panel_name"};
    }
  }

  delete $admin->{quick_report_menu};

  if ($conf{CUSTOM_START_PAGE} && $conf{CUSTOM_START_PAGE} ne '1')  {
    $html->tpl_show(templates($conf{CUSTOM_START_PAGE}), \%start_page);
  }
  else {
    $html->tpl_show(templates('form_start_page'), \%start_page);
  }

  return 1;
}

#**********************************************************
=head2 func_menu($header, $items, $f_args) - Functions menu

  Arguments:
    $header  - hash_ref
    $items   - hash_ref or arr_ref
    $f_args  -
    SILENT   -

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub func_menu {
  my ($header, $items, $f_args) = @_;

  my $elements     = '';
  my $buttons_list = '';

  if (! $FORM{pdf} && ! $FORM{json}) {
    foreach my $k (sort keys %$header) {
      my $v = $header->{$k};
      $buttons_list .= "$v\n";
    }

#    if (ref $items eq 'HASH') {
#      my @sorted_menu = sort {
#        $items->{$a} <=> $items->{$b}
#      } keys %$items;
#
#      foreach my $name (@sorted_menu) {
#        my $v = $items->{$name};
#        my ($subf, $ext_url, undef, $main_fn_index) = split(/:/, $v, 4);
#        $elements .= $html->li( $html->button($name, "index=". (($f_args->{MAIN_INDEX}) ? $f_args->{MAIN_INDEX} : (($main_fn_index) ? $main_fn_index : $index))
#              . (($ext_url) ? '&'.$ext_url : q{})
#              . (($subf) ? "&subf=$subf" : q{})
#          ),
#          { class => ($FORM{subf} && $FORM{subf} eq $subf) ? 'active' : '' });
#      }
#    }
#    els
    if(ref $items eq 'ARRAY') {
      foreach my $line (@$items) {
        my ($name, $subf, $ext_url, undef, $main_fn_index) = split(/:/, $line, 5);
        $elements .= $html->li( $html->button($name, "index=". (($f_args->{MAIN_INDEX}) ? $f_args->{MAIN_INDEX} : (($main_fn_index) ? $main_fn_index : $index))
            . (($ext_url) ? '&'.$ext_url : q{})
            . (($subf) ? "&subf=$subf" : q{})
        ),
        { class => ($FORM{subf} && $FORM{subf} eq $subf) ? 'active' : '' });
      }
    }
  }

  $buttons_list = $html->element( 'ul', $elements, { class => 'nav navbar-nav' } ). $buttons_list;
  my $menu = $html->element( 'div',
    $buttons_list,
    { class => 'navbar navbar-default' } );

  print $menu if (! $f_args->{SILENT});

  if ($FORM{subf}) {
    _function($FORM{subf}, $f_args->{f_args});
  }

  return 1;
}

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
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}" );
      return 0;
    }
    elsif ($LIST_PARAMS{GID} || $LIST_PARAMS{GIDS}) {
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}" );
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
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}" );
      return 0;
    }

    $users->group_change($FORM{chg}, {%FORM});
    if (!$users->{errno}) {
      $html->message( 'info', $lang{CHANGED}, "$lang{CHANGED} $FORM{chg}" );
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
      caption    => "$lang{GROUPS}",
      title      => [ '#', $lang{NAME}, $lang{DESCRIBE}, $lang{USERS}, "$lang{ALLOW} $lang{CREDIT}",
        "$lang{DISABLE} Paysys", "$lang{DISABLE} $lang{USER_CHG_TP}", '-', '-' ],
      cols_align => [ 'right', 'left', 'left', 'right', 'center', 'center' ],
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
        { class => 'change' } ), $delete );
  }
  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right' ],
      rows       => [ [ "$lang{TOTAL}:", $html->b( $users->{TOTAL} ) ] ]
    }
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_image_mng($attr)

=cut
#**********************************************************
sub form_image_mng {
  my ($attr) = @_;

  if ($FORM{IMAGE}) {
    my $file_content;

    if(ref $FORM{IMAGE} eq 'HASH' && $FORM{IMAGE}{Contents}) {
      $file_content = $FORM{IMAGE};
    }
    else {
      my $content = decode_base64($FORM{IMAGE});
      $file_content->{Contents}       = $content;
      $file_content->{Size}           = length($content);
      $file_content->{'Content-Type'} = 'image/jpeg';
    }

    if($attr->{TO_RETURN}) {
      return $file_content;
    }

    upload_file($file_content, { PREFIX    => 'if_image',
                                 FILE_NAME => "$FORM{UID}.jpg",
                                 #EXTENSIONS=> 'jpg,gif,png'
                                 REWRITE   => 1
                               });
  }
  elsif($FORM{show}) {
    print "Content-Type: image/jpeg\n\n";

    print file_op({ FILENAME => "$conf{TPL_DIR}/if_image/$FORM{UID}.jpg",
                    PATH     => "$conf{TPL_DIR}/if_image"
                  });
    return 1;
  }

  my @header_arr = (
    "$lang{MAIN}:index=$index&PHOTO=$FORM{PHOTO}&UID=$FORM{UID}",
      "Webcam:index=$index&PHOTO=$FORM{PHOTO}&UID=$FORM{UID}&webcam=1",
      "Upload:index=$index&PHOTO=$FORM{PHOTO}&UID=$FORM{UID}&upload=1"
  );

  print $html->table_header(\@header_arr, { TABS => 1 });

  $FORM{EXTERNAL_ID}=$attr->{EXTERNAL_ID};

  if($FORM{webcam}) {
    $html->tpl_show(templates('form_image_webcam'), { %FORM, %$attr },
       { ID => 'form_image_webcam' });
  }
  elsif($FORM{upload}) {
    $html->tpl_show(templates('form_image_upload'), { %FORM, %$attr },
       { ID => 'form_image_upload' });
  }
  else {
    if(-f "$conf{TPL_DIR}/if_image/$FORM{UID}.jpg") {
      print $html->img("$SELF_URL?qindex=$index&PHOTO=1&UID=$FORM{UID}&show=1");
    }
  }

  return 1;
}

#**********************************************************
=head2 form_nas_allow() - Aloow NAS servers

=cut
#**********************************************************
sub form_nas_allow{
  my ($attr) = @_;

  my @allow     = ();
  my %allow_nas = ();

  if ( $FORM{ids} ){
    @allow = split( /, /, $FORM{ids} );
  }

  my %EX_HIDDEN_PARAMS = (
    subf  => $FORM{subf},
    index => $index
  );

  if ($attr->{USER_INFO}) {
    my Users $user = $attr->{USER_INFO};
    if ($FORM{change} && $permissions{0}{4}) {
      $user->nas_add(\@allow);
      if (!$user->{errno}) {
        $html->message( 'info', $lang{INFO}, "$lang{ALLOW} $lang{NAS}: ". ($FORM{ids} || '') );
      }
    }
    elsif ($FORM{default} && $permissions{0} && $permissions{0}{4}) {
      $user->nas_del();
      if (!$user->{errno}) {
        $html->message( 'info', $lang{NAS}, $lang{CHANGED} );
      }
    }

    _error_show($user);

    my $list = $user->nas_list();
    foreach my $line (@$list) {
      $allow_nas{ $line->[0] } = 'test';
    }

    $EX_HIDDEN_PARAMS{UID} = $user->{UID};
  }
  elsif ($attr->{TP}) {
    my $tarif_plan = $attr->{TP};

    if ($FORM{change}) {
      $tarif_plan->nas_add(\@allow);
      if (! _error_show($tarif_plan)) {
        $html->message( 'info', $lang{INFO}, "$lang{ALLOW} $lang{NAS}: ". ($FORM{ids} || q{}) );
      }
    }

    my $list = $tarif_plan->nas_list();
    foreach my $nas_id (@$list) {
      $allow_nas{ $nas_id->[0] } = 1;
    }

    $EX_HIDDEN_PARAMS{TP_ID} = $tarif_plan->{TP_ID} || 0;
  }
  elsif (defined($FORM{TP_ID})) {
    $FORM{chg}  = $FORM{TP_ID};
    $FORM{subf} = $index;
    dv_tp();
    return 0;
  }

  require Nas;
  Nas->import();
  my $Nas = Nas->new($db, \%conf, $admin);
  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{NAS},
      title      => [ $lang{ALLOW}, $lang{NAME}, 'NAS-Identifier', 'IP', $lang{TYPE} ],
      qs         => $pages_qs,
      ID         => 'NAS_ALLOW'
    }
  );

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
  }

  my $list = $Nas->list({
    %LIST_PARAMS,
    PAGE_ROWS => 100000,
    COLS_NAME => 1
  });

  foreach my $line (@$list) {
    $table->addrow(
      ($line->{nas_id} || '')
      . $html->form_input('ids', $line->{nas_id},
        {
          TYPE          => 'checkbox',
          OUTPUT2RETURN => 1,
          STATE         => (defined($allow_nas{ $line->{nas_id} }) || $allow_nas{all}) ? 1 : undef
        }
      ),
      $line->{nas_name},
      $line->{nas_identifier},
      $line->{nas_ip},
      $line->{nas_type}
    );
  }

  print $html->form_main(
    {
      CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
      HIDDEN  => {%EX_HIDDEN_PARAMS},
      SUBMIT  => {
        change  => $lang{CHANGE},
        default => $lang{DEFAULT}
      }
    }
  );

  return 1;
}

#**********************************************************
=head2 form_bills($attr) - Bill account managment

  Arguments:
    $attr
      USER_INFO

  Returns:
    True or False

=cut
#**********************************************************
sub form_bills {
  my ($attr) = @_;

  my $user = $attr->{USER_INFO};
  my %BILLS_HASH = ();

  if ( ! $user && ! $FORM{COMPANY_ID}) {
    $html->message('err', $lang{ERROR}, 'No user information');
    return 1;
  }

  if ($FORM{UID} && $FORM{change}) {
    form_users({ USER_INFO => $user });
    return 0;
  }

  if (!$attr->{EXT_BILL_ONLY}) {
    require Bills;
    Bills->import();

    my $Bills = Bills->new($db, $admin, \%conf);
    my $list  = $Bills->list(
      {
        COMPANY_ONLY => 1,
        UID          => ($user) ? $user->{UID} : undef,
        COLS_NAME    => 1
      }
    );

    foreach my $line (@$list) {
      if ($line->{company_name}) {
        $BILLS_HASH{ $line->{id} } = "$line->{id} : $line->{company_name} :$line->{deposit}";
      }
      elsif ($line->{login}) {
        $BILLS_HASH{ $line->{id} } = ">> $line->{id} : Personal :$line->{deposit}";
      }
    }

    $user->{SEL_BILLS} .= $html->form_select(
      'BILL_ID',
      {
        SELECTED => '',
        SEL_HASH => { '' => '', %BILLS_HASH },
        NO_ID    => 1
      }
    );

    $user->{CREATE_BILL}      = ' checked' if (!$FORM{COMPANY_ID} && $user->{BILL_ID} && $user->{BILL_ID} < 1);
    $user->{BILL_TYPE}        = $lang{PRIMARY};
    $user->{CREATE_BILL_TYPE} = 'CREATE_BILL';
    $html->tpl_show(templates('form_chg_bill'), $user);
  }

  if ($conf{EXT_BILL_ACCOUNT} || $attr->{EXT_BILL_ONLY}) {
    $html->tpl_show(
      templates('form_chg_bill'),
      {
        BILL_ID          => $user->{EXT_BILL_ID},
        BILL_TYPE        => $lang{EXTRA},
        CREATE_BILL_TYPE => 'CREATE_EXT_BILL',
        LOGIN            => $user->{LOGIN},
        CREATE_BILL      => (!$FORM{COMPANY_ID} && ! $user->{EXT_BILL_ID}) ? ' checked' : '',
        SEL_BILLS        => $user->{SEL_BILLS},
        UID              => $user->{UID},
        SEL_BILLS        => $html->form_select(
          'EXT_BILL_ID',
          {
            SELECTED => '',
            SEL_HASH => { '' => '', %BILLS_HASH },
            NO_ID    => 1
          }
        )
      }
    );
  }

  return 1;
}

#**********************************************************
=head2 form_changes($attr); - Changes list

=cut
#**********************************************************
sub form_changes {
  my ($attr) = @_;

  my %search_params = ();

  my %action_types = (
    0  => 'Unknown',
    1  => "$lang{ADDED}",
    2  => "$lang{CHANGED}",
    3  => "$lang{CHANGED} $lang{TARIF_PLAN}",
    4  => "$lang{STATUS}",
    5  => "$lang{CHANGED} $lang{CREDIT}",
    6  => "$lang{INFO}",
    7  => "$lang{REGISTRATION}",
    8  => "$lang{ENABLE}",
    9  => "$lang{DISABLE}",
    10 => "$lang{DELETED}",
    11 => '-',
    12 => "$lang{DELETED} $lang{USER}",
    13 => "Online $lang{DELETED}",
    14 => "$lang{HOLD_UP}",
    15 => "$lang{HANGUP}",
    16 => "$lang{PAYMENTS} $lang{DELETED}",
    17 => "$lang{FEES} $lang{DELETED}",
    18 => "$lang{INVOICE} $lang{DELETED}",
    26 => "$lang{CHANGE} $lang{GROUP}",
    27 => "$lang{SHEDULE} $lang{ADDED}",
    28 => "$lang{SHEDULE} $lang{DELETED}",
    29 => "$lang{SHEDULE} $lang{EXECUTED}",
    31 => "$lang{ICARDS} $lang{USED}",
    40 => "$lang{BILL} $lang{CHANGED}"
  );

  my $pages_qs2 = q{};
  if ($permissions{4}{3} && $FORM{del} && $FORM{COMMENTS}) {
    $admin->action_del($FORM{del});
    if (! _error_show($admin)) {
      $html->message( 'info', $lang{DELETED}, "$lang{DELETED} [$FORM{del}]" );
    }
  }
  elsif ($FORM{AID} && !defined($LIST_PARAMS{AID})) {
    $FORM{subf} = $index;
    $pages_qs2 .= "&AID=$FORM{AID}";
    form_admins();
    return 0;
  }
  elsif($FORM{subf}) {
    $index = $FORM{subf};
    $pages_qs2 = "&subf=$FORM{subf}";
  }

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  %search_params = %FORM;
  $search_params{MODULES_SEL} = $html->form_select(
    'MODULE',
    {
      SELECTED      => $FORM{MODULE},
      SEL_ARRAY     => [ '', @MODULES ],
      OUTPUT2RETURN => 1
    }
  );

  $search_params{TYPE_SEL} = $html->form_select(
    'TYPE',
    {
      SELECTED      => $FORM{TYPE},
      SEL_HASH      => { '' => $lang{ALL}, %action_types },
      SORT_KEY      => 1,
      OUTPUT2RETURN => 1
    }
  );

  if ($attr->{ADMIN}) {
    $search_params{ADMIN}=$attr->{ADMIN}->{A_LOGIN};
  }

  my %hidden_fileds = ();
  if($LIST_PARAMS{AID}) {
    $hidden_fileds{AID}=$LIST_PARAMS{AID};
    $pages_qs2 .= "&AID=$hidden_fileds{AID}";
  }

  if($LIST_PARAMS{UID}) {
    $hidden_fileds{UID}=$FORM{UID};
    $pages_qs2 .= "&UID=$FORM{UID}";
  }


  if($FORM{search_form}) {
    form_search({
      HIDDEN_FIELDS => \%hidden_fileds,
      SEARCH_FORM   => $html->tpl_show(templates('form_history_search'), \%search_params, { OUTPUT2RETURN => 1 })
    });
  }
  elsif(! $FORM{UID}) {
    form_changes_summary();
  }

  my $list = $admin->action_list({%LIST_PARAMS, COLS_NAME => 1 });
  $pages_qs = $pages_qs2;

  my $table = $html->table({
    width      => '100%',
    title      =>
    [ '#', $lang{LOGIN}, $lang{DATE}, $lang{CHANGED}, $lang{ADMIN}, 'IP', $lang{MODULES}, $lang{TYPE}, '-' ],
    qs         => $pages_qs,
    caption    => $lang{LOG},
    pages      => $admin->{TOTAL},
    ID         => 'ADMIN_ACTIONS',
    EXPORT     => 1,
    MENU       => "$lang{SEARCH}:search_form=1&index=$index"
        . (($FORM{UID}) ? "&UID=$FORM{UID}" : '' ) .":search;"
  });

  my $service_status = sel_status({ HASH_RESULT => 1 });

  foreach my $line (@$list) {
    my $delete = ($permissions{4} && $permissions{4}{3}) ? $html->button( $lang{DEL}, "index=$index$pages_qs&del=$line->{id}",
        { MESSAGE => "$lang{DEL} [$line->{id}] ?", class => 'del' } ) : '';

    my ($value, $color);
    if (in_array($line->{action_type}, [ 10, 28, 13, 16, 17 ])) {
      $color = 'bg-danger';
    }
    elsif (in_array($line->{action_type}, [ 1, 7 ])) {
      $table->{rowcolor} = 'alert-warning';
    }
    else {
      $table->{rowcolor} = undef;
    }

    my $message = $line->{actions} || q{};
    if (in_array($line->{action_type}, [ 4,8,9,14 ]) && $message =~ m/^(\d+)\-\>(\d+)(.{0,100})/) {
      my $from_status = $1;
      my $to_status   = $2;
      my $text        = $3 || '';

      if($service_status->{$from_status}) {
        ($value, $color) = split(/:/, $service_status->{$from_status});
        $from_status = $html->color_mark( $value, $color );
      }
      if($service_status->{$to_status}) {
        ($value, $color) = split(/:/, $service_status->{$to_status});
        $to_status = $html->color_mark( $value, $color );
      }
      $message = $from_status. '->' .$to_status . $text;
    }

    $table->addrow($html->b($line->{id}),
      $html->button($line->{login}, "index=15&UID=$line->{uid}"),
      ($color) ? $html->color_mark($line->{datetime}, $color) : $line->{datetime},
      $html->color_mark($message, $color),
      $line->{admin_login},
      $line->{ip},
      $line->{module},
      $html->color_mark($action_types{ $line->{action_type} }, $color),
      $delete);
  }

  print $table->show();

  $table = $html->table({
    width      => '100%',
    rows       => [ [ "$lang{TOTAL}:", $html->b( $admin->{TOTAL} ) ] ]
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_events($attr) - Show system events

=cut
#**********************************************************
sub form_events {
  #my ($attr) =@_;

  my @result_array = ();

  $conf{CROSS_MODULES_DEBUG}='/tmp/cross_modules';

  print "Content-Type: text/html\n\n" if ($FORM{DEBUG});
  my $cross_modules_return = cross_modules_call('_events', {
    UID => $user->{UID},
  });

  my %admin_modules = ('Events' => 1, 'Notepad' => 1);
  my $admin_groups_ids = $admin->{SETTINGS}{GROUP_ID} || '';

  if (in_array('Events', \@MODULES)){

    # Cross-modules should already import and instantiate Events
    our $Events;
    if (!$Events){
      require Events;
      Events->import();
      $Events = Events->new($db, $admin, \%conf);
    }

    if ($admin_groups_ids) {

      # Changing 'AND' to 'OR'
      $admin_groups_ids =~ s/, /;/g;
      my $groups_list = $Events->group_list( {
          ID         => $admin_groups_ids,
          MODULES    => '_SHOW',
          COLS_UPPER =>   0
      });

      if ( _error_show($Events) ){
        print "Events-Error: $Events->{sql_errstr}\n";
        return 0;
      }

      foreach my $group ( @{$groups_list} ) {
        my $group_modules_string = $group->{modules} || '';
        my @group_modules = split(',', $group_modules_string);
        map { $admin_modules{$_} = 1 } @group_modules;
      }
    }
  }

  foreach my $module (sort keys %$cross_modules_return) {
    next if ($admin_groups_ids && !$admin_modules{$module});

    my $result = $cross_modules_return->{$module};
    if ($result && $result ne ''){
      push (@result_array, $result);
    }
  }

  print "Content-Type: application/json;\n\n";
  print "[ " . join(", ", @result_array) . " ]";

  return 1;
}

#**********************************************************
=head2 form_back_money($type, $sum, $attr) - Back money to bill account

=cut
#**********************************************************
sub form_back_money {
  my ($type, $sum, $attr) = @_;
  my $uid;

  if ($type eq 'log') {
    if (defined($attr->{LOGIN})) {
      my $list = $users->list({ LOGIN => $attr->{LOGIN}, COLS_NAME => 1 });

      if ($users->{TOTAL} < 1) {
        $html->message( 'err', $lang{USER}, "[$users->{errno}] $err_strs{$users->{errno}}" );
        return 0;
      }
      $uid = $list->[0]->{uid};
    }
    else {
      $uid = $attr->{UID};
    }
  }

  my $user = $users->info($uid);

  my $OP_SID = ($FORM{OP_SID}) ? $FORM{OP_SID} : mk_unique_value(16);

  print $html->form_main(
    {
      HIDDEN => {
        index   => $index,
        subf    => $index,
        sum     => $sum,
        OP_SID  => $OP_SID,
        UID     => $uid,
        BILL_ID => $user->{BILL_ID}
      },
      SUBMIT => { bm => "$lang{BACK_MONEY} ?" }
    }
  );

  return 1;
}

#**********************************************************
=head2 form_passwd($attr)

=cut
#**********************************************************
sub form_passwd {
  my ($attr) = @_;

  my $password_form;
  my $ret  = 0;

  if (defined($FORM{AID})) {
    $password_form->{HIDDDEN_INPUT} = $html->form_input(
      'AID',
      $FORM{AID},
      {
        TYPE          => 'hidden',
        OUTPUT2RETURN => 1
      }
    );
    $index = 50;
  }
  elsif (defined($attr->{USER_INFO})) {
    $password_form->{HIDDDEN_INPUT} = $html->form_input(
      'UID',
      $FORM{UID},
      {
        TYPE          => 'hidden',
        OUTPUT2RETURN => 1
      }
    );
    $index = 15 if (!$attr->{REGISTRATION});
  }

  $conf{PASSWD_LENGTH} = 8 if (!$conf{PASSWD_LENGTH});

  if (! $FORM{newpassword}) {

  }
  elsif (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_SHORT_PASSWD} $conf{PASSWD_LENGTH}" );
    $ret = 1;
  }
  elsif ($conf{CONFIG_PASSWORD} && defined($FORM{AID}) && !Conf::check_password($FORM{newpassword}, $conf{CONFIG_PASSWORD})){

    load_module('Config', $html);
    my $explain_string = config_get_password_constraints($conf{CONFIG_PASSWORD});

    $html->message( 'err', $lang{ERROR}, "$lang{ERR_PASSWORD_INSECURE} $explain_string");
    $ret = 1;
  }
  elsif ($FORM{newpassword} eq $FORM{confirm}) {
    $FORM{PASSWORD} = $FORM{newpassword};
    return 0;
  }
  elsif ($FORM{newpassword} ne $FORM{confirm}) {
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_CONFIRM}" );
    $ret = 1;
  }

  $password_form->{PW_CHARS}   = $conf{PASSWD_SYMBOLS} || "abcdefhjmnpqrstuvwxyz123456789ABCDEFGHJKLMNPQRSTUVWYXZ";
  $password_form->{PW_LENGTH}  = $conf{PASSWD_LENGTH}  || 6;
  $password_form->{ACTION}     = 'change';
  $password_form->{LNG_ACTION} = "$lang{CHANGE}";

  $password_form->{ACTION}     = 'change';
  $password_form->{LNG_ACTION} = "$lang{CHANGE}";

  $html->tpl_show(templates('form_password'), $password_form);

  return $ret;
}

#**********************************************************
=head2 fl() Main functions

=cut
#**********************************************************
sub fl {
  if ($permissions{0}) {
    require Control::Users_mng;
    require Control::Companies_mng;
  }

  # ID:PARENT:NAME:FUNCTION:SHOW SUBMENU:module:
  my @m = (
    #"0:0::null:::",
    "1:0:<i class='fa fa-user'></i><span>$lang{CUSTOMERS}</span>:null:::",
    "11:1:$lang{LOGINS}:form_users_list:::",
    "13:1:$lang{COMPANY}:form_companies:::",
    "16:13:$lang{ADMIN}:form_companie_admins:COMPANY_ID::",

    "15:11:$lang{INFO}:form_users:UID::",
    "22:15:$lang{LOG}:form_changes:UID::",
    "17:15:$lang{PASSWD}:form_passwd:UID::",
    "18:15:$lang{NAS}:form_nas_allow:UID::",
    "19:15:$lang{BILL}:form_bills:UID::",
    "20:15:$lang{SERVICES}:null:UID::",
    "21:15:$lang{COMPANY}:user_company:UID::",
    "101:15:$lang{PAYMENTS}:form_payments:UID::",
    "102:15:$lang{FEES}:form_fees:UID::",
    "103:15:$lang{SHEDULE}:form_shedule:UID::",
    "12:15:$lang{GROUP}:user_group:UID::",
    "27:1:$lang{GROUPS}:form_groups:::",

    "30:15:$lang{USER_INFO}:user_pi:UID::",
    #"31:15:Send e-mail:form_sendmail:UID::",

    "2:0:<i class='fa fa-plus-square-o'></i><span>$lang{PAYMENTS}</span>:form_payments:::",
    "3:0:<i class='fa fa-minus-square-o'></i><span>$lang{FEES}</span>:form_fees:::",
#Config

#Monitoring
    "6:0:<i class='fa fa-eye'></i><span>$lang{MONITORING}</span>:null:::",
    "7:0:<i class='fa fa-search'></i><span>$lang{SEARCH}</span>:form_search:::",
    "8:0:<i class='fa fa-flag'></i><span>$lang{MAINTAIN}</span>:null:::",
    "9:0:<i class='fa fa-wrench'></i><span>$lang{PROFILE}</span>:admin_profile:::",
  );

  #Profile
  if ($permissions{8}){
    require Control::Profile;
    push @m,
      "110:9:$lang{FUNCTIONS_LIST}:flist:::",
      "111:9:$lang{EVENTS}:form_events:AJAX::",
      "112:9:$lang{SLIDES}:form_slides_create:::";
  }

  if ($conf{NON_PRIVILEGES_LOCATION_OPERATION}) {
    require Control::Address_mng;
    push @m, "70:8:$lang{LOCATIONS}:form_districts:::", "71:70:$lang{STREETS}:form_streets::";
  }
  else {
    require Control::Address_mng;
    push @m, "70:5:$lang{LOCATIONS}:form_districts:::", "71:70:$lang{STREETS}:form_streets::";
  }

  #Reports
  push @m, "4:0:<i class='fa fa-bar-chart'></i><span>$lang{REPORTS}</span>:form_reports:::";

  #Reports
  if($permissions{3}){
    require Control::Reports;
    push @m, "122:4:$lang{LIST_OF_LOGS}:logs_list:::";

    if($conf{AUTH_FACEBOOK_ID}){
      push @m, "127:4:$lang{SOCIAL_NETWORKS}:null:::";
      push @m, "128:127:Facebook:reports_facebook_users_info:::";
    }

    #Payments reports
    if($permissions{3}{2}) {
      push @m, "42:4:$lang{PAYMENTS}:report_payments:::",
        "43:42:$lang{MONTH}:report_payments_month:::";
    }
    #Allow fees reports
    if ($permissions{3}{3}) {
      push @m, "44:4:$lang{FEES}:report_fees:::",
        "45:44:$lang{MONTH}:report_fees_month:::";
    }

    if ($permissions{3}{4}) {
      push @m, "67:4:$lang{EVENTS}:form_changes:::";
    }

    if ($permissions{3}{5}) {
      push @m, "68:4:$lang{CONFIG}:form_system_changes:::",
               "76:4:WEB server:report_webserver:::",
               "86:4:User portal:report_bruteforce:::",
               "87:86:$lang{SESSIONS}:report_ui_last_sessions:::",
               "123:86:$lang{USER_STATISTIC}:analiz_user_statistic:::";
    }
  }

  #config functions
  if ($permissions{4}) {
    require Control::System;

    push @m, "5:0:<i class='fa fa-gear'></i><span>$lang{CONFIG}</span>:null:::",
      "62:5:$lang{NAS}:form_nas:::",
      "63:62:IP POOLs:form_ip_pools:::",
      "64:62:$lang{NAS_STATISTIC}:form_nas_stats:::",
      "65:62:$lang{GROUPS}:form_nas_groups:::",
      "66:5:$lang{EXCHANGE_RATE}:form_exchange_rate:::",

      "75:5:$lang{HOLIDAYS}:form_holidays:::",
      "85:5:$lang{SHEDULE}:form_shedule:::",
      "88:90:$lang{CONTACTS} $lang{TYPES}:form_contact_types:::",
      "90:5:$lang{MISC}:null:::",
      "91:90:$lang{TEMPLATES}:form_templates:::",
      "92:90:$lang{DICTIONARY}:form_dictionary:::",
      "93:90:Checksum:form_config:::",
      "94:90:$lang{PATHES}:form_prog_pathes:::",
      "95:90:$lang{SQL_BACKUP}:form_sql_backup:::",
      "96:90:$lang{INFO_FIELDS}:form_info_fields:::",
      "97:96:$lang{LIST}:form_info_lists:::",
      "98:90:$lang{TYPE} $lang{FEES}:form_fees_types:::",
      "99:90:billd:form_billd_plugins:::",
      "120:90:$lang{STATUS}:form_status:::",
      "121:90:$lang{ORGANIZATION_INFO}:organization_info:::",
      "124:90:$lang{PAYMENT_METHOD}:form_payment_types:::";

    #Allow Admin managment function
    if ($permissions{4}{4}) {
      require Control::Admins_mng;
      push @m, "50:5:$lang{ADMINS}:form_admins:::",
        "51:50:$lang{LOG}:form_changes:AID::",
        "52:50:$lang{PERMISSION}:form_admin_permissions:AID::",
        "54:50:$lang{PASSWD}:form_passwd:AID::",
        "55:50:$lang{FEES}:form_fees:AID::",
        "56:50:$lang{PAYMENTS}:form_payments:AID::",
        "57:50:$lang{CHANGE}:form_admins:AID::",
        "59:50:$lang{ACCESS}:form_admins_access:AID::",
        "60:50:Paranoid:form_admins_full_log:AID::",
        "61:50:$lang{CONTACTS}:form_admins_contacts:AID::",
        "69:50::form_admins_contacts_save:AID,AJAX:",

        push @m, "58:50:$lang{GROUPS}:form_admins_groups:AID::" if (! $admin->{GID});
        push @m, "113:50:Domains:form_admins_domains:AID::" if (in_array('Multidoms', \@MODULES));
    }
  }

  if ($permissions{0} && $permissions{0}{1}) {
    push @m, "24:11:$lang{ADD_USER}:form_wizard:::";
    #push @m, "14:13:$lang{ADD}:add_company:::";
    #push @m, "28:27:$lang{ADD}:add_groups:::";
  }

  if ($conf{AUTH_METHOD}) {
    $permissions{9}{1}=1;
    push @m, "10:0:<i class='fa fa-sign-out'></i><span>$lang{LOGOUT}</span>:null:::";
  }

  my $custom_menu = custom_menu();
  if($#{ $custom_menu } > -1) {
    mk_menu($custom_menu, { CUSTOM => 1 });
    return 1;
  }

  mk_menu(\@m);

  return 1;
}

#**********************************************************
=head2 mk_navigator()

=cut
#**********************************************************
sub mk_navigator {
  $admin->{test} = 'test';
  my ($menu_navigator, $menu_text_) = $html->menu(\%menu_items, \%menu_args, \%permissions, { FUNCTION_LIST => \%functions });

  if ($html->{ERROR}) {
    $html->message( 'err', $lang{ERROR}, $html->{ERROR} );
    die "$html->{ERROR}";
  }

  return $menu_text_, " " . $menu_navigator;
}

#**********************************************************
=head2 form_payments($attr) Payments form

=cut
#**********************************************************
sub form_payments {
  my ($attr) = @_;

  my $Payments = Finance->payments($db, $admin, \%conf);
  my $er;
  my %BILL_ACCOUNTS = ();

  my %PAYMENTS_METHODS = %{ get_payment_methods() };

  return 0 if (!$permissions{1});

  our $Docs;
  if (in_array('Docs', \@MODULES)) {
    load_module('Docs', $html);
  }

  if ($FORM{print}) {
    if ($FORM{INVOICE_ID}) {
      docs_invoice({%FORM});
    }
    else {
      docs_receipt({%FORM});
    }
    exit;
  }

  # autofocus on SUM field
  $Payments->{AUTOFOCUS}  = 'autofocus="autofocus"';

  if ($attr->{USER_INFO}) {
    my $user = $attr->{USER_INFO};
    $Payments->{UID} = $user->{UID};

    if ($conf{EXT_BILL_ACCOUNT}) {
      $BILL_ACCOUNTS{ $user->{BILL_ID} } = "$lang{PRIMARY} : $user->{BILL_ID}" if ($user->{BILL_ID});
      $BILL_ACCOUNTS{ $user->{EXT_BILL_ID} } = "$lang{EXTRA} : $user->{EXT_BILL_ID}" if ($user->{EXT_BILL_ID});
    }

    if (in_array('Docs', \@MODULES)) {
      $FORM{QUICK} = 1;
    }

    if (!$attr->{REGISTRATION}) {
      if (! $user->{BILL_ID}) {
        form_bills({ USER_INFO => $user });
        return 0;
      }
    }

    if ($FORM{OP_SID} && $FORM{OP_SID} eq ($COOKIES{OP_SID} || q{})) {
      $html->message( 'err', $lang{ERROR}, "$lang{EXIST}" );
    }
    elsif ($FORM{add} && $FORM{SUM}) {
      if(! $permissions{1} || ! $permissions{1}{1}) {
        $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
        return 0;
      }

      $Payments->{AUTOFOCUS}  = '';
      $FORM{SUM} =~ s/,/\./g;
      $db->{TRANSACTION}=1;
      my DBI $db_ = $db->{db};
      $db_->{AutoCommit} = 0;

      if ($FORM{SUM} !~ /[0-9\.]+/) {
        $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_SUM} SUM: $FORM{SUM}", { ID => 22 });
        return 0 if ($attr->{REGISTRATION});
      }
      else {
        $FORM{CURRENCY} = $conf{SYSTEM_CURRENCY};

        if ($FORM{ER}) {
          if ($FORM{DATE}) {
            my $list = $Payments->exchange_log_list(
              {
                DATE      => "<=$FORM{DATE}",
                ID        => $FORM{ER},
                SORT      => 'date',
                DESC      => 'desc',
                PAGE_ROWS => 1
              }
            );
            $FORM{ER_ID}    = $FORM{ER};
            $FORM{ER}       = $list->[0]->[2] || 1;
            $FORM{CURRENCY} = $list->[0]->[4] || 0;
          }
          else {
            $er = $Payments->exchange_info($FORM{ER});
            $FORM{ER_ID}    = $FORM{ER};
            $FORM{ER}       = $er->{ER_RATE};
            $FORM{CURRENCY} = $er->{ISO};
          }
        }

        if ($FORM{ER} && $FORM{ER} != 1 && $FORM{ER} > 0) {
          $FORM{PAYMENT_SUM} = sprintf("%.2f", $FORM{SUM} / $FORM{ER});
        }
        else {
          $FORM{PAYMENT_SUM} = $FORM{SUM};
        }

        #Make pre payments functions in all modules
        cross_modules_call('_pre_payment', { %$attr });
        if (!$conf{PAYMENTS_NOT_CHECK_INVOICE_SUM} && ($FORM{INVOICE_SUM} && $FORM{INVOICE_SUM} != $FORM{PAYMENT_SUM})) {
          $html->message( 'err', "$lang{PAYMENTS}: $lang{ERR_WRONG_SUM}",
            " $lang{INVOICE} $lang{SUM}: $Docs->{TOTAL_SUM}\n $lang{PAYMENTS} $lang{SUM}: $FORM{SUM}" );
        }
        else {
          $Payments->add($user, { %FORM,
              INNER_DESCRIBE => ($FORM{INNER_DESCRIBE} || q{})
                . (($FORM{DATE} && $COOKIES{hold_date}) ? " $DATE $TIME" : '') });

          if (_error_show($Payments)) {
            return 0 if ($attr->{REGISTRATION});
          }
          else {
            if( in_array('Crm', \@MODULES) && $FORM{CASHBOX_ID}){
              require Crm;
              Crm->import();
              my $Crm = Crm->new($db, $admin, \%conf);
              $Crm->add_coming({
                DATE           => $FORM{DATE},
                AMOUNT         => $FORM{SUM},
                CASHBOX_ID     => $FORM{CASHBOX_ID},
                COMING_TYPE_ID => 2,
                COMMENTS       => $FORM{DESCRIBE}
              });
            }

            $FORM{SUM} = $Payments->{SUM};
            $html->message( 'info', $lang{PAYMENTS}, "$lang{ADDED} $lang{SUM}: $FORM{SUM} ". ($er->{ER_SHORT_NAME} || q{}) );

            if ($conf{external_payments}) {
              if (!_external($conf{external_payments}, { %FORM  })) {
                return 0;
              }
            }

            #Make cross modules Functions
            $FORM{PAYMENTS_ID} = $Payments->{PAYMENT_ID};
            cross_modules_call('_payments_maked', {
              %$attr,
              SUM          => $FORM{SUM},
              PAYMENT_ID   => $Payments->{PAYMENT_ID},
              SKIP_MODULES => 'Sqlcmd',
            });
          }
        }
      }

      if (! $attr->{REGISTRATION} && ! $db->{db}->{AutoCommit}) {
        $db_->commit();
        $db_->{AutoCommit}=1;
      }
    }
    elsif ($FORM{del} && $FORM{COMMENTS}) {
      if (!defined($permissions{1}{2})) {
        $html->message( 'err', $lang{ERROR}, "[13] $err_strs{13}" );
        return 0;
      }

      $Payments->del($user, $FORM{del}, { COMMENTS => $FORM{COMMENTS} });
      if ($Payments->{errno}) {
        if ($Payments->{errno} == 3) {
          $html->message( 'err', $lang{ERROR}, "$lang{ERR_DELETE_RECEIPT} " .
              $html->button( $lang{SHOW},
                "search=1&PAYMENT_ID=$FORM{del}&index=" . (get_function_index( 'docs_receipt_list' )),
                { BUTTON => 1 } ) );
        }
        else {
          _error_show($Payments);
        }
      }
      else {
        $html->message( 'info', $lang{PAYMENTS}, "$lang{DELETED} ID: $FORM{del}" );
      }
    }

    return 1 if ($attr->{REGISTRATION} && $FORM{add});

    #exchange rate sel
    my $er_list   = $Payments->exchange_list({%FORM, COLS_NAME => 1 });
    my %ER_ISO2ID = ();
    foreach my $line (@$er_list) {
      $ER_ISO2ID{ $line->{iso} } = $line->{id};
    }

    if ($FORM{ER} && $FORM{ISO}) {
      $FORM{ER} = $ER_ISO2ID{ $FORM{ISO} };
      $FORM{ER_ID} = $ER_ISO2ID{ $FORM{ISO} };
    }
    elsif($conf{SYSTEM_CURRENCY}) {
      $FORM{ER_ID} = $ER_ISO2ID{ $conf{SYSTEM_CURRENCY} };
    }

    if ($Payments->{TOTAL} > 0) {
      $Payments->{SEL_ER} = $html->form_select(
        'ER',
        {
          SELECTED      => $FORM{ER_ID} || $FORM{ER},
          SEL_LIST      => $er_list,
          SEL_KEY       => 'id',
          SEL_VALUE     => 'money,short_name,',
          NO_ID         => 1,
          MAIN_MENU     => get_function_index('form_exchange_rate'),
          MAIN_MENU_ARGV=> "chg=". ($FORM{ER} || ''),
          SEL_OPTIONS   => { '' => '' }
        }
      );

      $Payments->{ER_FORM} = $html->tpl_show(templates('form_row'), {
        ID    => '',
        NAME  => "$lang{CURRENCY} : $lang{EXCHANGE_RATE}",
        VALUE => $Payments->{SEL_ER} },
      { OUTPUT2RETURN => 1 });
    }

    $Payments->{SEL_METHOD} = $html->form_select(
      'METHOD',
      {
        SELECTED => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : 0,
        SEL_HASH => \%PAYMENTS_METHODS,
        NO_ID    => 1,
      }
    );

    if ($permissions{1} && $permissions{1}{1}) {
      $Payments->{OP_SID} = ($FORM{OP_SID}) ? $FORM{OP_SID} : mk_unique_value(16);

      if ($conf{EXT_BILL_ACCOUNT}) {
         $Payments->{EXT_DATA_FORM}=$html->tpl_show(templates('form_row'), {
           ID    => 'BILL_ID',
           NAME  => "$lang{BILL}",
           VALUE => $html->form_select('BILL_ID',
              {
                SELECTED => $FORM{BILL_ID} || $attr->{USER_INFO}->{BILL_ID},
                SEL_HASH => \%BILL_ACCOUNTS,
                NO_ID    => 1
               }) }, { OUTPUT2RETURN => 1 });
      }

      if ($permissions{1}{4}) {
        if ($COOKIES{hold_date}) {
          ($DATE, $TIME) = split(/ /, $COOKIES{hold_date}, 2);
        }

        if ($FORM{DATE}) {
          ($DATE, $TIME) = split(/ /, $FORM{DATE});
        }

        my $date_field = $html->date_fld2('DATE', { FORM_NAME => 'user_form', DATE => $DATE, TIME => $TIME, MONTHES => \@MONTHES, WEEK_DAYS => \@WEEKDAYS });
        $Payments->{DATE_FORM} = $html->tpl_show(templates('form_row'), {
            ID    => 'DATE',
            NAME  => "$lang{DATE}",
            VALUE => $date_field . $lang{HOLD} . $html->form_input( 'hold_date', '1', { TYPE => 'checkbox',
                       EX_PARAMS => "NAME='hold_date'",
                       ID        => 'DATE',
                       STATE     => (($COOKIES{hold_date}) ? 1 : undef) }, { OUTPUT2RETURN => 1 }) },
        { OUTPUT2RETURN => 1 });
      }

      if (in_array('Docs', \@MODULES) && ! $conf{DOCS_PAYMENT_DOCS_SKIP}) {
        $Payments->{INVOICE_SEL} = $html->form_select(
          "INVOICE_ID",
          {
            SELECTED         => $FORM{INVOICE_ID} || 'create' || 0,
            SEL_LIST         => $Docs->invoices_list({ UID       => $FORM{UID},
                                                       UNPAIMENT => 1,
                                                       PAGE_ROWS => 200,
                                                       SORT      => 2,
                                                       DESC      => 'DESC',
                                                       COLS_NAME => 1 }),
            SEL_KEY          => 'id',
            SEL_VALUE        => 'invoice_num,date,total_sum,payment_sum',
            SEL_VALUE_PREFIX => "$lang{NUM}: ,$lang{DATE}: ,$lang{SUM}: ,$lang{PAYMENTS}: ",
            SEL_OPTIONS      => { 0 => "$lang{DONT_CREATE_INVOICE}",
                                  %{ (!$conf{PAYMENTS_NOT_CREATE_INVOICE}) ? { create => $lang{CREATE} } : { } }
                                 },
            NO_ID            => 1,
            MAIN_MENU        => get_function_index('docs_invoices_list'),
            MAIN_MENU_ARGV   => "UID=$FORM{UID}&INVOICE_ID=". ($FORM{INVOICE_ID} || q{})
          }
        );
        delete($FORM{pdf});
        if(! $conf{DOCS_PAYMENT_RECEIPT_SKIP}) {
          $Payments->{CREATE_RECEIPT_CHECKED}='checked';
        }

        if($conf{DOCS_PAYMENT_SENDMAIL}) {
          $Payments->{SEND_MAIL}=1;
        }
        else {
          $Payments->{SEND_MAIL}=0;
        }

        $Payments->{DOCS_INVOICE_RECEIPT_ELEMENT} = $html->tpl_show(_include('docs_create_invoice_receipt', 'Docs'),
          {%$Payments}, { OUTPUT2RETURN => 1 });
      }

      if ($attr->{ACTION}) {
        $Payments->{ACTION}     = $attr->{ACTION};
        $Payments->{LNG_ACTION} = $attr->{LNG_ACTION};
      }
      else {
        $Payments->{ACTION}     = 'add';
        $Payments->{LNG_ACTION} = $lang{ADD};
      }

      if( in_array('Crm', \@MODULES)){
        require Crm;
        Crm->import();
        my $Crm = Crm->new($db, $admin, \%conf);
        $attr->{CASHBOX_SELECT} = $html->form_select(
          'CASHBOX_ID',
          {
            SELECTED    => $FORM{CASHBOX_ID} || $attr->{CASHBOX_ID},
            SEL_LIST    => $Crm->list_cashbox({ COLS_NAME => 1 }),
            SEL_KEY     => 'id',
            SEL_VALUE   => 'name',
            NO_ID       => 1,
            SEL_OPTIONS => {"" => ""},
          }
        );
      }

      $html->tpl_show(templates('form_payments'), { %FORM, %$attr, %$Payments }, { ID => 'form_payments'  });
      #return 0 if ($attr->{REGISTRATION});
    }
  }
  elsif ($FORM{AID} && !defined($LIST_PARAMS{AID})) {
    $FORM{subf} = $index;
    form_admins();
    return 0;
  }
  elsif ($FORM{UID} && ! $FORM{type}) {
    $index = get_function_index('form_payments');
    form_users();
    return 0;
  }
  elsif ($index != 7) {
    $FORM{type} = $FORM{subf} if ($FORM{subf});
    form_search(
      {
        HIDDEN_FIELDS => {
          subf       => ($FORM{subf}) ? $FORM{subf} : undef,
          COMPANY_ID => $FORM{COMPANY_ID}
        },
        ID            => 'SEARCH_PAYMENTS',
        CONTROL_FORM  => 1
      }
    );
  }

  return 0 if (! $permissions{1}{0});

  if (! $FORM{sort}) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  $LIST_PARAMS{ID} = $FORM{ID} if ($FORM{ID});

  if ($conf{SYSTEM_CURRENCY}) {
    $LIST_PARAMS{AMOUNT}='_SHOW' if (! $FORM{AMOUNT});
    $LIST_PARAMS{CURRENCY}='_SHOW' if (! $FORM{CURRENCY});
  }

  if ($FORM{INVOICE_NUM}) {
    $LIST_PARAMS{INVOICE_NUM} = $FORM{INVOICE_NUM};
  }

  my Abills::HTML $table;
  my $payments_list;

  ($table, $payments_list) = result_former({
     INPUT_DATA      => $Payments,
     FUNCTION        => 'list',
     BASE_FIELDS     => 8,
     FUNCTION_FIELDS => 'del',
     EXT_TITLES      => {
       'id'           => $lang{NUM},
       'datetime'     => $lang{DATE},
       'dsc'          => $lang{DESCRIBE},
       'sum'          => $lang{SUM},
       'last_deposit' => $lang{OPERATION_DEPOSIT},
       'deposit'      => $lang{CURRENT_DEPOSIT},
       'method'       => $lang{PAYMENT_METHOD},
       'ext_id'       => 'EXT ID',
       'reg_date'     => "$lang{PAYMENTS} $lang{REGISTRATION}",
       'ip'           => 'IP',
       'admin_name'   => $lang{ADMIN},
       'invoice_num'  => $lang{INVOICE},
       amount         => "$lang{ALT} $lang{SUM}",
       currency       => $lang{CURRENCY}
     },
     TABLE => {
       width   => '100%',
       caption => "$lang{PAYMENTS}",
       qs      => $pages_qs,
       EXPORT  => 1,
       ID      => 'PAYMENTS',
       MENU    => "$lang{SEARCH}:search_form=1&index=2:search"
      }
    });

  $table->{SKIP_FORMER}=1;

  my %i2p_hash = ();
  if (in_array('Docs', \@MODULES)) {
    my @payment_id_arr = ();
    foreach my $p (@$payments_list) {
      push @payment_id_arr, $p->{id};
    }

    my $i2p_list = $Docs->invoices2payments_list({
      PAYMENT_ID => join(';', @payment_id_arr),
      PAGE_ROWS  => ($LIST_PARAMS{PAGE_ROWS} || 25)*3,
      COLS_NAME  => 1
    });

    foreach my $i2p (@$i2p_list) {
      #print "$i2p->{invoice_id}:$i2p->{invoiced_sum}:$i2p->{invoice_num}\n";
      push @{ $i2p_hash{$i2p->{payment_id}} }, ($i2p->{invoice_id} || '') .':'. ($i2p->{invoiced_sum} || '') .':'. ($i2p->{invoice_num} || '');
    }
  }

  $pages_qs .= "&subf=2" if (!$FORM{subf});
  foreach my $line (@$payments_list) {
    my $delete = ($permissions{1}{2}) ? $html->button( $lang{DEL},
        "index=2&del=$line->{id}$pages_qs". (($pages_qs !~ /UID=/) ? "&UID=$line->{uid}" : q{} ),
        { MESSAGE => "$lang{DEL} [$line->{id}] ?", class => 'del' } ) : '';

    my @fields_array = ();
    for (my $i = 0; $i < 8+$Payments->{SEARCH_FIELDS_COUNT}; $i++) {
      my $field_name = $Payments->{COL_NAMES_ARR}->[$i];

      if ($conf{EXT_BILL_ACCOUNT} && $field_name eq 'ext_bill_deposit') {
        $line->{ext_bill_deposit} = ($line->{ext_bill_deposit} < 0) ? $html->color_mark($line->{ext_bill_deposit}, $_COLORS[6]) : $line->{ext_bill_deposit};
      }
      elsif($field_name eq 'deleted') {
        if (defined($line->{deleted})){
          $line->{deleted} = $html->color_mark( $bool_vals[ $line->{deleted} ],
              ($line->{deleted} && $line->{deleted} == 1) ? $state_colors[ $line->{deleted} ] : '' );
        }
      }
      elsif($field_name eq 'login' && $line->{uid}) {
        $line->{login} = $html->button($line->{login}, "index=15&UID=$line->{uid}");
      }
      elsif($field_name eq 'dsc') {
        $line->{dsc} = ($line->{dsc} || q{}) . $html->br().$html->b($line->{inner_describe}) if ($line->{inner_describe});
      }
      elsif($field_name =~ /deposit/ && defined($line->{$field_name})) {
        $line->{$field_name} = ($line->{$field_name} < 0) ? $html->color_mark( $line->{$field_name}, $_COLORS[6] ) : $line->{$field_name};
      }
      elsif($field_name eq 'method') {
        $line->{method} = ($FORM{METHOD_NUM}) ? $line->{method} : $PAYMENTS_METHODS{ $line->{method} };
      }
      elsif($field_name eq 'login_status' && defined($line->{login_status})) {
        $line->{login_status} = ($line->{login_status} > 0) ? $html->color_mark($service_status[ $line->{login_status} ], $service_status_colors[ $line->{login_status} ]) : $service_status[$line->{login_status}];
      }
      elsif ($field_name eq 'bill_id') {
        $line->{bill_id} = ($conf{EXT_BILL_ACCOUNT} && $attr->{USER_INFO}) ? $BILL_ACCOUNTS{ $line->{bill_id} } : $line->{bill_id};
      }
      elsif($field_name eq 'invoice_num') {
        if (in_array('Docs', \@MODULES) && ! $FORM{xml}) {
          my $payment_sum = $line->{sum};
          my $i2p         = '';

          if ($i2p_hash{$line->{id}}) {
            foreach my $val ( @{ $i2p_hash{$line->{id}} }  ) {
              my ($invoice_id, $invoiced_sum, $invoice_num)=split(/:/, $val);
              $i2p .= $invoiced_sum . " $lang{PAID} $lang{INVOICE} #" . $html->button( $invoice_num,
                "index=" . get_function_index( 'docs_invoices_list' ) . "&ID=$invoice_id&search=1" ) . $html->br();
              $payment_sum -= $invoiced_sum;
            }
          }
          if ($payment_sum > 0) {
            $i2p .= sprintf( "%.2f", $payment_sum ) . ' ' . $html->color_mark( "$lang{UNAPPLIED}",
              $_COLORS[6] ) . ' (' . $html->button( $lang{APPLY},
              "index=" . get_function_index( 'docs_invoices_list' ) . "&UNINVOICED=1&PAYMENT_ID=$line->{id}&UID=$line->{uid}" ) . ')';
          }

          $line->{invoice_num} = $i2p;
        }
      }

      push @fields_array, $line->{$field_name};
    }

    $table->addrow(@fields_array, $delete);
  }

  print $table->show();

  if (!$admin->{MAX_ROWS}) {
    $table = $html->table(
      {
        width      => '100%',
        cols_align => [ 'right', 'right', 'right', 'right', 'right', 'right' ],
        rows       =>
        [ [ "$lang{TOTAL}:", $html->b( $Payments->{TOTAL} ), "$lang{USERS}:", $html->b( $Payments->{TOTAL_USERS} ),
            "$lang{SUM}", $html->b( $Payments->{SUM} ) ] ],
        rowcolor   => 'even'
      }
    );
    print $table->show();
  }

  return 1;
}

#**********************************************************
=head2 form_fees($attr)

=cut
#**********************************************************
sub form_fees {
  my ($attr) = @_;
  my $period = $FORM{period} || 0;

  return 0 if (!defined($permissions{2}));

  my $Fees = Finance->fees($db, $admin, \%conf);
  my %BILL_ACCOUNTS = ();

  my $FEES_METHODS = get_fees_types();

  if ($attr->{USER_INFO}) {
    my $user = $attr->{USER_INFO};

    if ($conf{EXT_BILL_ACCOUNT}) {
      $BILL_ACCOUNTS{ $attr->{USER_INFO}->{BILL_ID} } = "$lang{PRIMARY} : $attr->{USER_INFO}->{BILL_ID}" if ($attr->{USER_INFO}->{BILL_ID});
      $BILL_ACCOUNTS{ $attr->{USER_INFO}->{EXT_BILL_ID} } = "$lang{EXTRA} : $attr->{USER_INFO}->{EXT_BILL_ID}" if ($attr->{USER_INFO}->{EXT_BILL_ID});
    }

    if (! $user->{BILL_ID} || $user->{BILL_ID} < 1) {
      form_bills({ USER_INFO => $user });
      return 0;
    }

    $Fees->{UID} = $user->{UID};
    if ($FORM{take} && $FORM{SUM}) {
      $FORM{SUM} =~ s/,/\./g;

      # add to shedule
      if ($FORM{ER} && $FORM{ER} ne '') {
        my $er = $Fees->exchange_info($FORM{ER});
        $FORM{ER}  = $er->{ER_RATE};
        $FORM{SUM} = $FORM{SUM} / $FORM{ER};
      }

      if ($period == 2) {
        my $FEES_DATE = $FORM{DATE} || $DATE;
        if (date_diff($DATE, $FEES_DATE) < 1) {
          $Fees->take($user, $FORM{SUM}, \%FORM);
          if (! _error_show($Fees)) {
            $html->message( 'info', $lang{FEES}, "$lang{TAKE} $lang{SUM}: $Fees->{SUM} $lang{DATE}: $FEES_DATE" );
          }
        }
        else {
          my ($Y, $M, $D) = split(/-/, $FEES_DATE);
          $FORM{METHOD} //= 0;
          $Shedule->add(
            {
              DESCRIBE => $FORM{DESCR},
              D        => $D,
              M        => $M,
              Y        => $Y,
              UID      => $user->{UID},
              TYPE     => 'fees',
              ACTION   => ($conf{EXT_BILL_ACCOUNT}) ? "$FORM{SUM}:$FORM{DESCRIBE}:BILL_ID=$FORM{BILL_ID}:$FORM{METHOD}" : "$FORM{SUM}:$FORM{DESCRIBE}::$FORM{METHOD}"
            }
          );

          if(! _error_show($Shedule)) {
            $html->message( 'info', $lang{SHEDULE}, $lang{ADDED});
          }
        }
      }

      #take now
      else {
        delete $FORM{DATE};
        $Fees->take($user, $FORM{SUM}, \%FORM);
        if (! _error_show($Fees)) {
          $html->message( 'info', $lang{FEES}, "$lang{TAKE} $lang{SUM}: $Fees->{SUM}" );

          #External script
          if ($conf{external_fees}) {
            if (!_external($conf{external_fees}, {%FORM})) {
              return 0;
            }
          }
        }
      }
    }
    elsif ($FORM{del} && $FORM{COMMENTS}) {
      if (!defined($permissions{2}{2})) {
        $html->message( 'err', $lang{ERROR}, "[13] $err_strs{13}" );
        return 0;
      }

      $Fees->del($user, $FORM{del}, { COMMENTS => $FORM{COMMENTS} });

      if (! _error_show($Fees)) {
        $html->message( 'info', $lang{FEES}, "$lang{DELETED} ID: $FORM{del}" );
      }
    }

    my $list = $Shedule->list(
      {
        UID  => $user->{UID},
        TYPE => 'fees'
      }
    );

    if ($Shedule->{TOTAL} > 0) {
      my $table2 = $html->table(
        {
          width       => '100%',
          caption     => "$lang{SHEDULE}",
          title_plain => [ '#', $lang{DATE}, $lang{SUM}, '-' ],
          cols_align  => [ 'right', 'right', 'right', 'left', 'center:noprint' ],
          qs          => $pages_qs,
          ID          => 'USER_SHEDULE'
        }
      );

      foreach my $line (@$list) {
        my ($sum, undef) = split(/:/, $line->[7]);
        my $delete = ($permissions{2}{2}) ? $html->button( $lang{DEL}, "index=85&del=$line->[14]",
            { MESSAGE => "$lang{DEL} ID: $line->[13]?", class => 'del' } ) : '';

        $table2->addrow($line->[13], "$line->[3]-$line->[2]-$line->[1]", sprintf('%.2f', $sum), $delete);
      }

      $Fees->{SHEDULE_FORM} = $table2->show();
    }

    $Fees->{PERIOD_FORM} = form_period($period, { TD_EXDATA => "colspan='2'" });

    if ($permissions{2} && $permissions{2}{1}) {
      #exchange rate sel
      $Fees->{SEL_ER} = $html->form_select(
        'ER',
        {
          SELECTED   => undef,
          SEL_LIST   => $Fees->exchange_list({ COLS_NAME => 1 }),
          SEL_KEY    => 'id',
          SEL_VALUE  => 'money,short_name',
          NO_ID      => 1,
          MAIN_MENU     => get_function_index('form_exchange_rate'),
          MAIN_MENU_ARGV=> "chg=". ($FORM{ER} || q{}),
          SEL_OPTIONS=> { '' => ''}
        }
      );

      if ($conf{EXT_BILL_ACCOUNT}) {
        $Fees->{EXT_DATA_FORM}=$html->tpl_show(templates('form_row'), {
           ID    => 'BILL_ID',
           NAME  => "$lang{BILL}",
           VALUE => $html->form_select('BILL_ID',
              {
                SELECTED => $FORM{BILL_ID} || $attr->{USER_INFO}->{BILL_ID},
                SEL_HASH => \%BILL_ACCOUNTS,
                NO_ID    => 1
               }) }, { OUTPUT2RETURN => 1 });
      }

      $Fees->{SEL_METHOD} = $html->form_select(
        'METHOD',
        {
          SELECTED      => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : 0,
          SEL_HASH      => $FEES_METHODS,
          NO_ID         => 1,
          SORT_KEY_NUM  => 1,
          MAIN_MENU     => get_function_index('form_fees_types'),
        }
      );

      $html->tpl_show(templates('form_fees'), $Fees, { ID => 'form_fees' }) if (!$attr->{REGISTRATION});
    }
  }
  elsif ($FORM{AID} && !defined($LIST_PARAMS{AID})) {
    $FORM{subf} = $index;
    form_admins();
    return 0;
  }
  elsif ($FORM{UID} && ! $FORM{type}) {
    form_users();
    return 0;
  }
  elsif ($index != 7) {
    $FORM{type} = $FORM{subf} if ($FORM{subf});
    if ($FORM{search_form} || $FORM{search}) {
      form_search(
        {
          HIDDEN_FIELDS => {
            subf       => ($FORM{subf}) ? $FORM{subf} : undef,
            COMPANY_ID => $FORM{COMPANY_ID}
          }
        }
      );
    }
  }

  return 0 if (!$permissions{2}{0});

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }
  my Abills::HTML $table;
  my $fees_list;
  ($table, $fees_list) = result_former({
     INPUT_DATA      => $Fees,
     FUNCTION        => 'list',
     BASE_FIELDS     => 1,
     DEFAULT_FIELDS  => 'ID,LOGIN,DATETIME,DSC,SUM,LAST_DEPOSIT,METHOD,ADMIN_NAME',
     FUNCTION_FIELDS => 'del',
     EXT_TITLES      => {
       'id'           => $lang{NUM},
       'datetime'     => $lang{DATE},
       'dsc'          => $lang{DESCRIBE},
       'sum'          => $lang{SUM},
       'last_deposit' => $lang{OPERATION_DEPOSIT},
       'deposit'      => $lang{CURRENT_DEPOSIT},
       'method'       => $lang{TYPE},
       'ip'           => 'IP',
       'reg_date'     => "$lang{FEES} $lang{REGISTRATION}",
       'admin_name'   => $lang{ADMIN},
     },
     TABLE => {
       width   => '100%',
       caption => "$lang{FEES}",
       qs      => $pages_qs,
       pages   => $Fees->{TOTAL},
       ID      => 'FEES',
       EXPORT  => 1,
       MENU    => "$lang{SEARCH}:search_form=1&index=3:search",
      }
    });

  $table->{SKIP_FORMER}=1;

  $pages_qs .= "&subf=2" if (!$FORM{subf});
  foreach my $line (@$fees_list) {
    my $delete = ($permissions{2}{2}) ? $html->button( $lang{DEL},
        "index=3&del=$line->{id}$pages_qs" . (($pages_qs !~ /UID=/) ? "&UID=$line->{uid}" : ''),
        { MESSAGE => "$lang{DEL} [$line->{id}] ?", class => 'del' } ) : '';

    my @fields_array = ();
    for (my $i = 0; $i < 1+$Fees->{SEARCH_FIELDS_COUNT}; $i++) {
       my $field_name = $Fees->{COL_NAMES_ARR}->[$i];

      if ($conf{EXT_BILL_ACCOUNT} && $field_name eq 'ext_bill_deposit') {
        $line->{ext_bill_deposit} = ($line->{ext_bill_deposit} < 0) ? $html->color_mark($line->{ext_bill_deposit}, $_COLORS[6]) : $line->{ext_bill_deposit};
      }
      elsif($field_name eq 'deleted') {
        $line->{deleted} = $html->color_mark($bool_vals[ $line->{deleted} ], ($line->{deleted} == 1) ? $state_colors[ $line->{deleted} ] : '');
      }
      elsif($field_name eq 'login' && $line->{uid}) {
        $line->{login} = $html->button($line->{login}, "index=15&UID=$line->{uid}");
      }
      elsif($field_name eq 'dsc') {
        if ($line->{dsc} =~ /# (\d+)/ && in_array('Msgs', \@MODULES)) {
          $line->{dsc} = $html->button($line->{dsc}, "index=". get_function_index('msgs_admin')."&chg=$1");
        }

        if ($line->{dsc} =~ /\$/) {
          $line->{dsc} = _translate($line->{dsc});
        }

        $line->{dsc} = $line->{dsc}.$html->br().$html->b($line->{inner_describe}) if ($line->{inner_describe});
      }
      elsif($field_name =~ /deposit/ && defined($line->{$field_name})) {
        $line->{$field_name} = ($line->{$field_name} < 0) ? $html->color_mark($line->{$field_name}, $_COLORS[6]) : $line->{$field_name};
      }
      elsif($field_name eq 'method') {
        $line->{method} //= 0;
        $line->{method} = ($FORM{METHOD_NUM}) ? $line->{method} : ($FEES_METHODS->{ $line->{method} } || $line->{method} );
      }
      elsif($field_name eq 'login_status' && defined($line->{$field_name})) {
        $line->{login_status} = ($line->{login_status} > 0) ? $html->color_mark($service_status[ $line->{login_status} ], $service_status_colors[ $line->{login_status} ]) : $service_status[$line->{login_status}];
      }
      elsif($field_name eq 'bill_id') {
        $line->{bill_id} = ($conf{EXT_BILL_ACCOUNT} && $attr->{USER_INFO}) ? $BILL_ACCOUNTS{ $line->{bill_id} } : $line->{bill_id};
      }
#      elsif($field_name eq 'invoice_num') {
#        if (in_array('Docs', \@MODULES) && ! $FORM{xml}) {
#          my $payment_sum = $line->{sum};
#          my $i2p         = '';
#
#          if ($i2p_hash{$line->{id}}) {
#            foreach my $val ( @{ $i2p_hash{$line->{id}} }  ) {
#              my ($invoice_id, $invoiced_sum, $invoice_num)=split(/:/, $val);
      #              $i2p .= $invoiced_sum ." $lang{PAID} $lang{INVOICE} #". $html->button($invoice_num, "index=". get_function_index('docs_invoices_list'). "&ID=$invoice_id&search=1"  ) . $html->br();
#              $payment_sum -= $invoiced_sum;
#            }
#          }
#
#          if ($payment_sum > 0) {
      #            $i2p .= sprintf("%.2f", $payment_sum). ' '. $html->color_mark("$lang{UNAPPLIED}", $_COLORS[6]) .' ('. $html->button($lang{APPLY}, "index=". get_function_index('docs_invoices_list') ."&UNINVOICED=1&PAYMENT_ID=$fees->{id}&UID=$line->{uid}") .')';
#          }
#
#          $line->{invoice_num} .= $i2p;
#        }
#      }

      push @fields_array, $line->{$field_name};
    }

    $table->addrow(@fields_array, $delete);
  }

  print $table->show();

  if (!$admin->{MAX_ROWS}) {
    $table = $html->table(
      {
        width      => '100%',
        cols_align => [ 'right', 'right', 'right', 'right', 'right', 'right' ],
        rows       =>
        [ [ "$lang{TOTAL}:", $html->b( $Fees->{TOTAL} ), "$lang{USERS}:", $html->b( $Fees->{TOTAL_USERS} ),
          "$lang{SUM}:", $html->b( $Fees->{SUM} ) ] ],
        rowcolor   => 'even'
      }
    );
    print $table->show();
  }

  return 1;
}


#**********************************************************
=head2 form_search($attr) - Search form

  Arguments:
    $attr
      SIMPLE
      TPL
      ADDRESS_FORM  - show address form
      PLAIN_SEARCH_FORM
      SERARCH_FORM  -
      CONTROL_FORM  - Control form by $FORM{search_form}
      HIDDEN_FIELDS - { key => val }

  Returns:

=cut
#**********************************************************
sub form_search {
  my ($attr) = @_;

  my %SEARCH_DATA = $admin->get_data(\%FORM);
  my %info = ();

  my $search_type = $FORM{type} || 0;

  if ($FORM{search}) {
    if($FORM{quick_search}) {
      print "Content-Type: text/html\n\n";
      print "Quick search";
      exit;
    }

    $pages_qs = "&search=1";
    $pages_qs .= "&type=$search_type" if ($search_type && $pages_qs !~ /&type=/);

    if ($search_type == 10) {
      $FORM{type} = 11 ;
      $search_type = 11;
      $FORM{_MULTI_HIT}=1;
      if ($admin->{SETTINGS} && $admin->{SETTINGS}{SEARCH_FIELDS}) {
        @default_search = split(/, /, $admin->{SETTINGS}{SEARCH_FIELDS});
      }

      my $search_string = $FORM{LOGIN} || $FORM{UNIVERSAL_SEARCH} || q{};
      $search_string=~s/\s+$//;
      $search_string=~s/^\s+//;

      foreach my $field ( @default_search ) {
        $LIST_PARAMS{$field} = "*$search_string*";
      }
      delete $FORM{LOGIN};

      $FORM{UNIVERSAL_SEARCH}=$search_string;
    }
    else {
      $LIST_PARAMS{LOGIN} = $FORM{LOGIN};
    }

    while (my ($k, $v) = each %FORM) {
      if ($k =~ /([A-Z0-9]+|_[a-z0-9]+)/ && $v ne '' && $k ne '__BUFFER') {
        $LIST_PARAMS{$k} = $v;
        $v =~ s/=/%3D/g;
        $v =~ s/\+/%2B/g;
        $pages_qs .= "&$k=$v";
      }
    }

    if ($search_type ne $index && ! $FORM{subf} && $functions{ $search_type }) {
      my $return = 1;
      if ($search_type) {
        $return = _function($search_type);
      }

      if (! $return) {
        return 0;
      }
      elsif($FORM{json}) {
        return 1;
      }
    }
  }

  if ($attr->{HIDDEN_FIELDS} && ref $attr->{HIDDEN_FIELDS} eq 'HASH') {
    my $SEARCH_FIELDS = $attr->{HIDDEN_FIELDS};
    while (my ($k, $v) = each(%$SEARCH_FIELDS)) {
      $SEARCH_DATA{HIDDEN_FIELDS} .= $html->form_input(
        $k, ($v || q{}),
        {
          TYPE          => 'hidden',
          OUTPUT2RETURN => 1
        }
      );
    }
  }

  if (defined($attr->{SIMPLE})) {
    my $SEARCH_FIELDS = $attr->{SIMPLE};
    foreach my $k (sort keys %$SEARCH_FIELDS) {
      my $v = $SEARCH_FIELDS->{$k};
      my $input_form = '';
      if (ref $v eq 'HASH') {
        my ($field_name) = keys %$v;
        $input_form .= $html->form_select(
          (ref $v->{$field_name} eq 'HASH') ? $field_name : $k,
          {
            SELECTED => $FORM{$field_name || $k} || 0 || '',
            SEL_HASH => (ref $v->{$field_name} eq 'HASH') ? $v->{$field_name} : $v
          }
        );
      }
      else {
        $input_form .= $html->form_input($v, $FORM{$v} || '%' . $v . '%');
      }

      $SEARCH_DATA{SEARCH_FORM} .= $html->tpl_show(templates('form_row'), {
          ID    => "$k",
          NAME  => "$k",
          VALUE => $input_form
        }, { OUTPUT2RETURN => 1 });
    }

    $html->tpl_show(templates('form_search_simple'), \%SEARCH_DATA);
  }
  elsif ($attr->{TPL}) {
    print $attr->{TPL};
  }
  elsif (!$FORM{pdf}) {
    if ( $attr->{CONTROL_FORM} && ! $FORM{search_form}) {
      return '';
    }

    my $group_sel   = sel_groups();
    my %search_form = (
      2  => 'form_search_payments',
      3  => 'form_search_fees',
      11 => 'form_search_users',
      13 => 'form_search_companies'
    );

    if ($search_type == 15) {
      $FORM{type} = 11;
      $search_type= 11;
    }
    elsif($search_type == 10) {
      $FORM{UNIVERSAL_SEARCH}=$FORM{LOGIN};
      $FORM{type} = 11;
      $search_type= 11;
      $FORM{_MULTI_HIT}=1;
      #print "$admin->{SETTINGS}{SEARCH_FILEDS}";
    }

    if ($FORM{LOGIN} && $admin->{MIN_SEARCH_CHARS} && length($FORM{LOGIN}) < $admin->{MIN_SEARCH_CHARS}) {
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_SEARCH_VAL_TOSMALL}. $lang{MIN}: $admin->{MIN_SEARCH_CHARS}" );
      return 0;
    }

    if (defined($attr->{SEARCH_FORM})) {
      $SEARCH_DATA{SEARCH_FORM} = $attr->{SEARCH_FORM};
    }
    elsif ($search_type && $search_form{ $search_type }) {
      if ($FORM{type} == 2) {
        $info{SEL_METHOD} = $html->form_select(
          'METHOD',
          {
            SELECTED     => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : '',
            SEL_HASH     => get_payment_methods(),
            SORT_KEY_NUM => 1,
            NO_ID        => 1,
            SEL_OPTIONS  => { '' => $lang{ALL} }
          }
        );
        $attr->{ADDRESS_FORM}=1;
      }
      elsif ($search_type == 3) {
        $info{SEL_METHOD} = $html->form_select(
          'METHOD',
          {
            SELECTED     => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : '',
            SEL_HASH     => get_fees_types(),
            #ARRAY_NUM_ID => 1,
            SORT_KEY_NUM => 1,
            NO_ID        => 1,
            SEL_OPTIONS  => { '' => $lang{ALL} }
          }
        );
        $attr->{ADDRESS_FORM}=1;
      }
      elsif ($search_type == 11 || $search_type == 15) {
        if ($index == 30) {
          $index=7 ;
          delete $FORM{UID};
        }

        $info{INFO_FIELDS} = form_info_field_tpl({ SKIP_DATA_RETURN => 1 });

        if (in_array('Docs', \@MODULES)) {
          if ($conf{DOCS_CONTRACT_TYPES}) {
            $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
            my (@contract_types_list) = split(/;/, $conf{DOCS_CONTRACT_TYPES});

            my %CONTRACTS_LIST_HASH = ();
            foreach my $line (@contract_types_list) {
              my ($prefix, $sufix, $name) = split(/:/, $line);
              #$prefix, $sufix, $name, $tpl_name<br>";
              $prefix =~ s/ //g;
              $CONTRACTS_LIST_HASH{"$prefix|$sufix"} = $name;
            }

            $info{CONTRACT_SUFIX} = $html->form_select(
              'CONTRACT_SUFIX',
              {
                SELECTED => $FORM{CONTRACT_SUFIX},
                SEL_HASH => { '' => '', %CONTRACTS_LIST_HASH },
                NO_ID    => 1
              }
            );

            $info{CONTRACT_TYPE_FORM} = $html->tpl_show(templates('form_row'), {
              ID    => "CONTRACT_TYPE",
              NAME  => "$lang{CONTRACT} $lang{TYPE}",
              VALUE => $info{CONTRACT_SUFIX}
              }, { OUTPUT2RETURN => 1 });
          }
        }

        if(in_array('Multidoms', \@MODULES) && $permissions{10}) {
          load_module('Multidoms', $html);

          $info{DOMAIN_FORM}=$html->tpl_show(templates('form_row'), {
            ID    => 'DOMAIN_ID',
            NAME  => "Domains:",
            VALUE => multidoms_domains_sel(),
          }, { OUTPUT2RETURN => 1 });
        }
        $attr->{ADDRESS_FORM}=1;
      }
      elsif ($search_type == 13) {
        $info{INFO_FIELDS}  = form_info_field_tpl({ COMPANY => 1 });
        $info{CREDIT_DATE}  = $html->date_fld2('CREDIT_DATE',  { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 12 });
        $info{PAYMENTS}     = $html->date_fld2('PAYMENTS',     { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 14 });
        $info{REGISTRATION} = $html->date_fld2('REGISTRATION', { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 16 });
        $info{ACTIVATE}     = $html->date_fld2('ACTIVATE',     { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 17 });
        $info{EXPIRE}       = $html->date_fld2('EXPIRE',       { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 18 });
      }

      $SEARCH_DATA{SEARCH_FORM} = $html->tpl_show(templates($search_form{ $search_type }), { %FORM, %info, GROUPS_SEL => $group_sel }, { OUTPUT2RETURN => 1 });
      $SEARCH_DATA{SEARCH_FORM} .= $html->form_input('type', $search_type, { TYPE => 'hidden', FORM_ID => 'SKIP' });
    }

    if ($attr->{ADDRESS_FORM}) {
      my $address_form = '';

      if ($conf{ADDRESS_REGISTER}) {
        $address_form =  $html->tpl_show(templates('form_address_search'), { %FORM, %$users }, { OUTPUT2RETURN => 1, ID => 'form_address_sel' });
      }
      else {
        my $countries_hash;
        ($countries_hash, $users->{COUNTRY_SEL}) = sel_countries({ NAME => 'COUNTRY', COUNTRY => $users->{COUNTRY_ID} });
        $address_form = $html->tpl_show(templates('form_address'), { %FORM, %$users }, { OUTPUT2RETURN => 1, ID => 'form_address' });
      }

      $SEARCH_DATA{ADDRESS_FORM} = $html->tpl_show(templates('form_show_hide'),
         {
           CONTENT => $address_form,
           NAME    => $lang{ADDRESS},
           ID      => 'ADDRESS_FORM'
          },
         { OUTPUT2RETURN => 1 });
    }

    $SEARCH_DATA{FROM_DATE} = $html->date_fld2('FROM_DATE', { MONTHES => \@MONTHES, WEEK_DAYS => \@WEEKDAYS, NO_DEFAULT_DATE => $attr->{NO_DEFAULT_DATE} });
    $SEARCH_DATA{TO_DATE}   = $html->date_fld2('TO_DATE',   { MONTHES => \@MONTHES, WEEK_DAYS => \@WEEKDAYS, NO_DEFAULT_DATE => $attr->{NO_DEFAULT_DATE} });

    if ($index == 7) {
      my @header_arr = ();
      foreach my $k ( sort keys %SEARCH_TYPES) {
        my $v = $SEARCH_TYPES{$k};
        if ($k == 10)  {

        }
        elsif ($k == 11 || $k == 13 || $permissions{ ($k - 1) }) {
          push @header_arr, "$v:index=$index&type=$k";
        }
      }

      $SEARCH_DATA{SEL_TYPE} =  $html->table_header(\@header_arr, { TABS => 1 });
    }

    if (in_array('Tags', \@MODULES)) {
      load_module('Tags', $html);
      $SEARCH_DATA{TAGS_SEL} = tags_sel();
    }

    if ($attr->{PLAIN_SEARCH_FORM}) {
      $html->tpl_show(templates('form_search_plain'), {%SEARCH_DATA}, { ID => $attr->{ID} });
    }
    else {
      $html->tpl_show(templates('form_search'), {%SEARCH_DATA}, { ID => $attr->{ID} });
    }
  }

  return 1;
}

#**********************************************************
=head2 form_shedule()

=cut
#**********************************************************
sub form_shedule {

  require Shedule;
  Shedule->import();

  if ($FORM{add_form}) {
    $Shedule->{SEL_D} = $html->form_select(
    'D',
    {
      SELECTED => $FORM{D},
      SEL_HASH => {
        '*' => '*',
        1   => 1,
        2   => 2,
        3   => 3,
        4   => 4,
        5   => 5,
        6   => 6,
        7   => 7,
        8   => 8,
        9   => 9,
        10  => 10,
        11  => 11,
        12  => 12,
        13  => 13,
        14  => 14,
        15  => 15,
        16  => 16,
        17  => 17,
        18  => 18,
        19  => 19,
        20  => 20,
        21  => 21,
        22  => 22,
        23  => 23,
        24  => 24,
        25  => 25,
        26  => 26,
        27  => 27,
        28  => 28,
        29  => 29,
        30  => 30,
        31  => 31
      },
      NO_ID        => 1,
      SORT_KEY_NUM => 1
    });

    $Shedule->{SEL_M} = $html->form_select('M',
    {
      SELECTED => $FORM{M},
      SEL_HASH => {
        '*' => '*',
        1   => $MONTHES[0],
        2   => $MONTHES[1],
        3   => $MONTHES[2],
        4   => $MONTHES[3],
        5   => $MONTHES[4],
        6   => $MONTHES[5],
        7   => $MONTHES[6],
        8   => $MONTHES[7],
        9   => $MONTHES[8],
        10  => $MONTHES[9],
        11  => $MONTHES[10],
        12  => $MONTHES[11],
      },
      NO_ID        => 1,
      SORT_KEY_NUM => 1
    });

    my ($YEAR) = split(/-/, $DATE);

    $Shedule->{SEL_Y} = $html->form_select('Y', {
        SELECTED     => $FORM{Y},
        SEL_HASH     => { '*' => '*', $YEAR => $YEAR, ($YEAR + 1) => ($YEAR + 1), ($YEAR + 2) => ($YEAR + 2) },
        NO_ID        => 1,
        SORT_KEY_NUM => 1
    });

    $Shedule->{SEL_TYPE} = $html->form_select('TYPE',  {
      SELECTED => $FORM{TYPE},
      SEL_HASH => { 'sql' => 'SQL' },
      NO_ID    => 1,
    });

    $html->tpl_show(templates("form_shedule"), {%$Shedule},);
  }
  elsif ($FORM{add}) {
    $Shedule->add( \%FORM );

    if (!$Shedule->{errno}) {
      $html->message( 'info', $lang{ADDED}, "$lang{ADDED} [$Shedule->{INSERT_ID}]" );
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Shedule->del({ ID => $FORM{del} });
    if (!$Shedule->{errno}) {
      $html->message( 'info', $lang{DELETED}, "$lang{DELETED} [$FORM{del}]" );
    }
  }

  _error_show($Shedule);

  my %TYPES = (
    'tp'     => "$lang{CHANGE} $lang{TARIF_PLAN}",
    'fees'   => "$lang{FEES}",
    'status' => "$lang{STATUS}",
    'sql'    => 'SQL'
  );

  if ($FORM{SHEDULE_DATE}) {
    $LIST_PARAMS{SHEDULE_DATE}=$FORM{SHEDULE_DATE};
  }

  my $list  = $Shedule->list({%LIST_PARAMS, COLS_NAME => 1 });

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "$lang{SHEDULE}",
      title      =>
      [ "$lang{HOURS}", "$lang{DAY}", "$lang{MONTH}", "$lang{YEAR}", "$lang{COUNT}", "$lang{USER}", "$lang{TYPE}",
        "$lang{VALUE}", "$lang{MODULES}", "$lang{ADMINS}", "$lang{CREATED}", "$lang{COMMENTS}", "-" ],
      cols_align => [ 'right', 'right', 'right', 'right', 'right', 'left', 'right', 'right', 'right', 'left', 'right', 'center' ],
      qs         => $pages_qs,
      pages      => $Shedule->{TOTAL},
      header     =>
      [ "$lang{ALL}:index=$index" . $pages_qs, "$lang{ERROR}:index=$index&SHEDULE_DATE=<=$DATE" . $pages_qs ],
      ID         => 'SHEDULE',
      EXPORT     => 1,
      MENU       => ($FORM{UID}) ? '' : "$lang{ADD}:index=$index&add_form=1:add",
    }
  );

  my ($y, $m, $d) = (0,0,0);

  if($DATE =~ /(\d{4})\-(\d{2})\-(\d{2})/) {
    $y = $1;
    $m = $2;
    $d = $3;
  }

  foreach my $line (@$list) {
    my $delete = ($permissions{4}{3} || $permissions{0}{4})          ? $html->button( $lang{DEL},
        "index=$index&del=$line->{id}" . (($FORM{UID}) ? "&UID=$FORM{UID}" : ''),
        { MESSAGE => "$lang{DEL} [$line->{id}]?", class => 'del' } ) : '-';
    my $value = convert("$line->{action}", { text2html => 1 });

    my $shedule_date = $line->{y} . $line->{m} . $line->{d};
    if ( $line->{y} ne '*'
      && $line->{m} ne '*'
      && $line->{d} ne '*'
      && $shedule_date =~ /^\d+$/ && $shedule_date <= int($y . $m . $d)
      ){
      $table->{rowcolor} = 'danger';
    }
    else {
      $table->{rowcolor} = undef;
    }

    if ($line->{type} && $line->{type} eq 'status' && defined($line->{action})) {
      my ($action, undef) = split(/:/, $line->{action}, 2);
      $value = $html->color_mark($service_status[ $action ],
          ($table->{rowcolor} && $table->{rowcolor} eq ($service_status_colors[ $action ] || q{})) ? '#FFFFFF' : $service_status_colors[ $action ]);
    }

    $table->addrow($html->b($line->{h}),
      $line->{d},
      $line->{m},
      $line->{y},
      $line->{counts},
      $html->button($line->{login}, "index=15&UID=$line->{uid}"),
      ($TYPES{ $line->{type} }) ? $TYPES{ $line->{type} } : $line->{type},
      $value,
      $line->{module},
      $line->{admin_name},
      $line->{date},
      $line->{comments},
      $delete);
  }
  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right', 'right', 'right' ],
      rows       => [ [ "$lang{TOTAL}:", $html->b( $Shedule->{TOTAL} ) ] ]
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_period($period, $attr)

=cut
#**********************************************************
sub form_period {
  my ($period, $attr) = @_;

  my @periods = ("$lang{NOW}", "$lang{NEXT_PERIOD}", "$lang{DATE}");
  my $date_fld = $html->date_fld2('DATE', { FORM_NAME => 'user',
       MONTHES => \@MONTHES, WEEK_DAYS => \@WEEKDAYS, NEXT_DAY => 1 });
  my $form_period = '';

$form_period .= "<!-- period begin -->
<div>
<label class='control-label col-md-3'>$lang{DATE}</label>
<div class='col-md-9'>";

  $form_period .= "<div class='text-left'>" . $html->form_input(
    'period', "0",
    {
      TYPE          => "radio",
      STATE         => 1,
      OUTPUT2RETURN => 1
    }
  ) . "$periods[0]";

  $form_period .= "</div>\n";

  for (my $i = 1 ; $i <= $#periods ; $i++) {
    my $period_name = $periods[$i];

    $period = $html->form_input(
      'period', $i,
      {
        TYPE          => "radio",
        STATE         => ($i eq $period) ? 1 : undef,
        OUTPUT2RETURN => 1
      }
    );

    if ($i == 1) {
      next if (!$attr->{ABON_DATE});
      $period .= "$period_name  ($attr->{ABON_DATE})";
    }
    elsif ($i == 2) {
      $period .= "$period_name $date_fld";
    }

    $form_period .= "<div class='text-left'>$period</div>\n";
  }

  $form_period .= "</div> <!-- period end -->";

  return $form_period;
}

#**********************************************************
=head2 get_popup_info

=cut
#**********************************************************
sub get_popup_info {

  if (defined($FORM{NAS_SEARCH})) {
    require Control::Nas_mng;
    form_nas_search();
  }
  elsif(defined($FORM{FEEDBACK})){
    require Control::System;
    form_feedback();
  }

  return 1;
}

#**********************************************************
=head3 form_login() - Admin http login page

  Arguments:
    $attr
      ERROR

  Returns:

=cut
#**********************************************************
sub form_login {
  my ($attr) = @_;

  my %first_page = ();

  if ($conf{tech_works}) {
    $html->message( 'info', $lang{INFO}, $conf{tech_works} );
    return 0;
  }

  #Make active lang list
  if ($conf{LANGS}) {
    $conf{LANGS} =~ s/\n//g;
    my (@lang_arr) = split(/;/, $conf{LANGS});
    %LANG = ();
    foreach my $l (@lang_arr) {
      my ($lang, $lang_name) = split(/:/, $l);
      $lang =~ s/^\s+//;
      $LANG{$lang} = $lang_name;
    }
  }

  my %QT_LANG = (
    byelorussian => 22,
    bulgarian    => 20,
    english      => 31,
    french       => 37,
    polish       => 90,
    russian      => 96,
    ukraine      => 129,
  );

  $first_page{SEL_LANGUAGE} = $html->form_select(
    'language',
    {
      EX_PARAMS    => 'onChange="selectLanguage()"',
      SELECTED     => $html->{language},
      SEL_HASH     => \%LANG,
      NO_ID        => 1,
      NORMAL_WIDTH => 1,
      EXT_PARAMS   => { qt_locale => \%QT_LANG }
    }
  );

  $first_page{TITLE} = $lang{AUTH};

  if (! $FORM{REFERER} && $ENV{HTTP_REFERER} && $ENV{HTTP_REFERER}	=~ /$SELF_URL/) {
    $FORM{REFERER} = $ENV{HTTP_REFERER};
  }

  if($attr->{ERROR}) {
    $first_page{ERROR_MSG} = $html->message( 'err', $lang{ERROR}, "Error: $attr->{ERROR}" );
  }

  $html->tpl_show(templates('form_login'), \%first_page);

  return 1;
}

#**********************************************************
=head2 form_system_info($request) - API and system infomation functions

  Arguments:
    $attr

  Result:
    Info

=cut
#**********************************************************
sub form_system_info {
  my ($get_info) = @_;

  print $html->header();

  my ($version, $updated) = split(/ /, get_version());

  my %functions_api = (
    'system_information' => {
       date    => "$DATE $TIME",
       os      => uc($^O),
       billing => 'ABillS',
       name    => 'ABillS',
       version => $version,
       updated => $updated
     },
     'api_methods' => {

     },
     'api_version' => {
       version => '0.5',
       date    => '2016-07-01'
     }
  );

  my @show_functions = keys %functions_api;

  if ($get_info && in_array($get_info, \@show_functions)) {
    @show_functions = ($get_info);
  }

  my $result = '';
  foreach my $key ( @show_functions ) {
    my $table = $html->table(
      {
        width      => '100%',
        FIELDS_IDS => [ keys %{ $functions_api{$key} } ],
        rows       => [ [ values %{ $functions_api{$key} } ] ],
        ID         => $key
      }
    );

    $result .= $table->show({ OUTPUT2RETURN => 1 });
  }

  if ($FORM{json}) {
    $result = "{ $result }";
  }

  print $result;

  return 1;
}

#**********************************************************
=head2 form_monitoring($attr) - monitoring quick reports

=cut
#**********************************************************
sub form_monitoring {

  form_start({ SUB_MENU => '_sp_online' });

  return 1;
}

#**********************************************************
=head2 admin_quick_setting() - Admin quick profile configuration

=cut
#**********************************************************
sub admin_quick_setting {
  my $SEL_LANGUAGE = $html->form_select(
    'language',
    {
      NO_ID    => 1,
      SELECTED => $html->{language},
      SEL_HASH => \%LANG,
      ID       => 'type',
      class    => 'form-control margin'
    }
  );

  my $html_content = $html->tpl_show(templates('form_admin_quick_setting'), {
    INDEX             => get_function_index( 'admin_profile' ),
    SEL_LANGUAGE      => $SEL_LANGUAGE,
    %{$admin->{SETTINGS}}
  },
    { OUTPUT2RETURN => 1 }
  );

  $admin->{RIGHT_MENU} = $html->menu_right("<i class='fa fa-wrench'></i>", "admin_setting",  $html_content, { SKIN => $admin->{SETTINGS}{RIGHT_MENU_SKIN} } );

  return 1;
}

#**********************************************************
=head2 sel_admins($attr) - Admin select element

  Arguments:
    NAME     - Element name
    SELECTED - value
    REQUIRED - Required optins

  Returns:
    Select element

=cut
#**********************************************************
sub sel_admins {
  my ($attr) = @_;

  my $select_name = $attr->{NAME} || 'AID';

  return $html->form_select($select_name,
    {
      SELECTED    => $attr->{SELECTED} || $attr->{$select_name} || $FORM{$select_name} || 0,
      SEL_LIST    => $admin->list( { GID => $admin->{GID}, COLS_NAME => 1, PAGE_ROWS => 10000 } ),
      SEL_KEY     => 'aid',
      SEL_VALUE   => 'name,login',
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' },
      REQUIRED    => ($attr->{REQUIRED}) ? 'required' : undef
    } );

}


1;
