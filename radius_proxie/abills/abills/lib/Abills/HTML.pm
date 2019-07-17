package Abills::HTML;

=head1 NAME

Abills::HTML - HTML visualisation functions with bootstrap support

=head1 SYNOPSIS

    use Abills::HTML;

    $html = Abills::HTML->new(
       {
         CONF     => \%conf,
         NO_PRINT => 0,
         PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
         CHARSET  => $conf{default_charset},
       }
    );

    print $html->header();

    print $html->button('User', "index=15&UID=123");

=cut

use strict;
use warnings;

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

our (@_COLORS, %LIST_PARAMS, %COOKIES, $index, $SORT, $DESC, $PG, $PAGE_ROWS, $SELF_URL);

our $VERSION = 7.00;
use base 'Exporter';
our @EXPORT = qw(
  get_cookies
  set_cookies
  form_parse
  link_former
  @_COLORS
  %FORM
  %LIST_PARAMS
  %COOKIES
  $index
  $pages_qs
  $SORT
  $DESC
  $PG
  $PAGE_ROWS
  $SELF_URL
);

our %FORM = ();
our $pages_qs = '';
my $IMG_PATH = '';
my $CONF;
my $row_number = 0;
my $lang;

#http://www.mcanerin.com/en/articles/meta-language.asp
my %ISO_LANGUAGE_CODE = (
  english     => 'en',
  russian     => 'ru',
  ukrainian   => 'uk',
  bulgarian   => 'bg',
  french      => 'fr',
  armenian    => 'hy',
  azeri       => 'az',
  belarussian => 'be',
  spanish     => 'es',
  uzbek       => 'uz',
  polish      => 'pl',
);

my %button_class_icons = (
  add      => 'glyphicon glyphicon-plus text-success',
  search   => 'glyphicon glyphicon-search',
  info     => 'glyphicon glyphicon-info-sign',
  del      => 'glyphicon glyphicon-trash text-danger',
  fees     => 'glyphicon glyphicon-collapse-down',
  password => 'glyphicon glyphicon-lock',
  stats    => 'glyphicon glyphicon-stats text-success',
  print    => 'glyphicon glyphicon-print',
  user     => 'glyphicon glyphicon-user',
  history  => 'glyphicon glyphicon-book',
  show     => 'glyphicon glyphicon-list-alt',
);

#**********************************************************
=head2 new($attr)

  $attr
    NO_PRINT
    CONF
    LANG
    ADMIN
    HTML_STYLE

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  $IMG_PATH = (defined($attr->{IMG_PATH})) ? $attr->{IMG_PATH} : '../img/';
  $CONF = $attr->{CONF} if (defined($attr->{CONF}));

  my $self = {};
  bless($self, $class);

  if ($attr->{NO_PRINT}) {
    $self->{NO_PRINT} = 1;
  }

  if ($attr->{ADMIN}) {
    $self->{admin} = $attr->{ADMIN};
  }

  if ($attr->{LANG}) {
    $lang = $attr->{LANG};
  }

  if (!$CONF->{CURRENCY_ICON}) {
    $CONF->{CURRENCY_ICON} = 'glyphicon glyphicon-euro';
  }

  $self->{OUTPUT} = '';
  #$self->{COLORS} = $attr->{COLORS} if ($attr->{COLORS});
  %FORM = form_parse();
  get_cookies();
  $self->{HTML_FORM} = \%FORM;
  $SORT = $FORM{sort} || 1;
  $DESC = ($FORM{desc}) ? 'DESC' : '';
  $PG = $FORM{pg} || 0;
  $self->{CHARSET} = (defined($attr->{CHARSET})) ? $attr->{CHARSET} : 'utf8';

  $self->{HTML_STYLE} = 'lte_adm';
  if($attr->{HTML_STYLE}) {
    $self->{HTML_STYLE} = $attr->{HTML_STYLE};
  }
  elsif ($CONF->{HTML_STYLE}) {
    $self->{HTML_STYLE} = $CONF->{HTML_STYLE};
  }

  $CONF->{base_dir} = '/usr/abills' if (!$CONF->{base_dir});

  if ($FORM{PAGE_ROWS}) {
    $PAGE_ROWS = $FORM{PAGE_ROWS};
  }
  elsif ($attr->{PAGE_ROWS}) {
    $PAGE_ROWS = int($attr->{PAGE_ROWS});
  }
  else {
    $PAGE_ROWS = $CONF->{list_max_recs} || 25;
  }

  if ($attr->{METATAGS}) {
    $self->{METATAGS} = $attr->{METATAGS};
  }

  if ($attr->{PATH}) {
    $self->{PATH} = $attr->{PATH};
    $IMG_PATH = $self->{PATH} . 'img';
  }

  my $prot = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  $ENV{PROT} = $prot;
  $SELF_URL = (defined($ENV{HTTP_HOST})) ? "$prot://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}" : '';

  if ($attr->{EXPORT_LIST}) {
    $self->{EXPORT_LIST} = 1;
  }

  $self->{SESSION_IP} = $ENV{REMOTE_ADDR} || '0.0.0.0';
  $self->{domain} = $ENV{SERVER_NAME};
  $self->{secure} = '';

  @_COLORS = (
    '#FDE302', # 0 TH
    '#FFFFFF', # 1 TD.1
    '#eeeeee', # 2 TD.2
    '#dddddd', # 3 TH.sum, TD.sum
    '#E1E1E1', # 4 border
    '#FFFFFF', # 5
    '#FF0000', # 6 Error
    '#000088', # 7 vlink
    '#0000A0', # 8 Link
    '#000000', # 9 Text
    '#FFFFFF', #10 background
  );           #border

  %LIST_PARAMS = (
    SORT      => $SORT,
    DESC      => $DESC,
    PG        => $PG,
    PAGE_ROWS => $PAGE_ROWS,
  );

  $index = 0;
  if ($FORM{index} && $FORM{index} =~ /^\d+$/) {
    $index = $FORM{index};
  }

  $self->{index} = $index;

  if ($ENV{REQUEST_URI} && $ENV{REQUEST_URI} =~ /(.*)\//) {
    $self->{web_path} = $1;
    $self->{web_path} .= '/' if ($self->{web_path} !~ /\/$/);
  }

  if ($attr->{language}) {
    $self->{language} = $attr->{language};
  }
  elsif ($FORM{language} && $FORM{language} =~ /^[a-z\_]+$/) {
    $self->{language} = $FORM{language};
    $self->set_cookies('language', "$FORM{language}", "Fri, 1-Jan-2038 00:00:01", '/');
  }
  elsif ($COOKIES{language} && $COOKIES{language} =~ /^[a-z\_]+$/) {
    $self->{language} = $COOKIES{language};
    $FORM{language} = $self->{language};
  }
  else {
    $self->{language} = $CONF->{default_language} || 'english';
  }

  $self->{content_language} = $ISO_LANGUAGE_CODE{$self->{language}} || 'ru';
  $self->{TYPE} = 'html';

  #Make  PDF output
  if ($FORM{pdf} || $attr->{pdf}) {
    $FORM{pdf} = 1;
    eval {require PDF::API2;};
    if (!$@) {
      PDF::API2->import();
      require Abills::PDF;
      $self = Abills::PDF->new(
        {
          IMG_PATH => $IMG_PATH,
          NO_PRINT => defined($attr->{'NO_PRINT'}) ? $attr->{'NO_PRINT'} : 1,
          CONF     => $CONF,
          CHARSET  => $attr->{CHARSET},
          TYPE     => 'pdf'
        }
      );
    }
    else {
      print "Content-Type: text/html\n\n";
      my $name = 'PDF::API2';
      print "Can't load '$name'\n" .
        " Install Perl Module <a href='http://abills.net.ua/wiki/doku.php/abills:docs:manual:soft:$name'>$name</a>\n" .
        " Main Page <a href='http://abills.net.ua/wiki/doku.php/abills:docs:other:ru?&#ustanovka_perl_modulej'>Perl modules installation</a>\n" .
        " or install from <a href='http://www.cpan.org'>CPAN</a>\n";
      exit; #return 0;
    }
  }
  elsif (defined($FORM{xml})) {
    require Abills::XML;
    $self = Abills::XML->new(
      {
        IMG_PATH        => $IMG_PATH,
        NO_PRINT        => defined($attr->{'NO_PRINT'}) ? $attr->{'NO_PRINT'} : 1,
        CONF            => $CONF,
        CHARSET         => $attr->{CHARSET},
        CONFIG_TPL_SHOW => \&tpl_show,
        TYPE            => 'xml'
      }
    );
  }
  elsif ($FORM{csv} || $attr->{csv}) {
    require Abills::CONSOLE;
    $self = Abills::CONSOLE->new(
      {
        IMG_PATH => $IMG_PATH,
        NO_PRINT => defined($attr->{'NO_PRINT'}) ? $attr->{'NO_PRINT'} : 1,
        CONF     => $CONF,
        CHARSET  => $attr->{CHARSET},
        TYPE     => 'csv'
      }
    );
  }
  elsif ($FORM{xls} || $attr->{xls}) {
    $FORM{xls} = 1;
    eval {require Spreadsheet::WriteExcel;};
    if (!$@) {
      require Abills::EXCEL;
      $self = Abills::EXCEL->new(
        {
          IMG_PATH => $IMG_PATH,
          NO_PRINT => defined($attr->{'NO_PRINT'}) ? $attr->{'NO_PRINT'} : 1,
          CONF     => $CONF,
          CHARSET  => $attr->{CHARSET},
          TYPE     => 'xls'
        }
      );
    }
    else {
      print "Content-Type: text/html\n\n";
      my $name = 'Spreadsheet::WriteExcel';
      print "Can't load '$name'\n" .
        " Install Perl Module <a href='http://abills.net.ua/wiki/doku.php/abills:docs:manual:soft:$name'>$name</a>\n" .
        " Main Page <a href='http://abills.net.ua/wiki/doku.php/abills:docs:other:ru?&#ustanovka_perl_modulej'>Perl modules installation</a>\n" .
        " or install from <a href='http://www.cpan.org'>CPAN</a>\n";
      exit; #return 0;
    }
  }
  elsif ($FORM{json}) {
    require Abills::JSON_;
    $self = Abills::JSON_->new(
      {
        IMG_PATH        => $IMG_PATH,
        NO_PRINT        => defined($attr->{'NO_PRINT'}) ? $attr->{'NO_PRINT'} : 1,
        CONF            => $CONF,
        FORM            => \%FORM,
        CHARSET         => $attr->{CHARSET},
        CONFIG_TPL_SHOW => \&tpl_show,
        TYPE            => 'json'
      }
    );
  }

  return $self;
}

#**********************************************************
=head2 form_parse() Parse html query input

  Return:
    Output HASH

=cut
#**********************************************************
sub form_parse {
  my $self = shift;

  %FORM = ();
  my ($boundary, @pairs);
  my $buffer;
  my $name;

  return %FORM if (!defined($ENV{'REQUEST_METHOD'}));

  if ($ENV{HTTP_TRANSFER_ENCODING} && $ENV{HTTP_TRANSFER_ENCODING} eq 'chunked') {
    my $newtext;
    while (read(STDIN, $newtext, 1)) {
      $buffer .= $newtext;
    }
    # ($prefix, $buffer) = split(/[\r\n]+/, $buffer);
    # if ($buffer && hex("0x$prefix") > 0) {
    #   $ret = substr($buffer, 0, hex("0x$prefix"));
    # }
  }
  elsif ($ENV{'REQUEST_METHOD'} eq "GET") {
    $buffer = $ENV{'QUERY_STRING'};
  }
  elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
    read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
  }

  if (!defined($ENV{CONTENT_TYPE}) || $ENV{CONTENT_TYPE} !~ /boundary/) {
    @pairs = split(/&/, $buffer || '');
    $FORM{__BUFFER} = $buffer if ($#pairs > -1);

    foreach my $pair (@pairs) {
      my ($side, $value) = split(/=/, $pair, 2);
      if (defined($value)) {
        $value =~ tr/+/ /;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        $value =~ s/<!--(.|\n)*-->//g;
        #$value =~ s/<([^>]|\n)*>//g;

        if (!$self->{SKIP_QUOTE}) {
          #Check quotes
          $value =~ s/\\/\\\\/g;
          $value =~ s/\"/\\\"/g;
          $value =~ s/\'/\\\'/g;
          $value =~ s/&rsquo;/\\\'/g;
        }
      }
      else {
        $value = '';
      }

      if (defined($side) && defined($FORM{$side})) {
        $FORM{$side} .= ", $value";
      }
      else {
        $FORM{((defined($side)) ? $side : '')} = $value;
      }
    }
  }
  else {
    ($boundary = $ENV{CONTENT_TYPE}) =~ s/^.*boundary=(.*)$/$1/;

    $FORM{__BUFFER} = $buffer;
    @pairs = split(/--$boundary/, $buffer);
    @pairs = splice(@pairs, 1, $#pairs - 1);
    for my $part (@pairs) {
      $part =~ s/[\r]\n$//g;
      my (undef, $firstline, $datas) = split(/[\r]\n/, $part, 3);
      next if $firstline =~ /filename=\"\"/;
      $firstline =~ s/^Content-Disposition: form-data; //;
      my (@columns) = split(/;\s+/, $firstline);

      ($name = $columns[0]) =~ s/^name=\"([^\"]+)\"$/$1/g;
      my $blankline;
      if ($#columns > 0) {
        if ($datas =~ /^Content-Type:/) {
          ($FORM{"$name"}->{'Content-Type'}, $blankline, $datas) = split(/[\r]\n/, $datas, 3);
          $FORM{"$name"}->{'Content-Type'} =~ s/^Content-Type: ([^\s]+)$/$1/g;
        }
        else {
          ($blankline, $datas) = split(/[\r]\n/, $datas, 2);
          $FORM{"$name"}->{'Content-Type'} = "application/octet-stream";
        }
      }
      else {
        ($blankline, $datas) = split(/[\r]\n/, $datas, 2);
        if (grep (/^$name$/, keys(%FORM))) {
          if (defined($FORM{$name})) {
            $FORM{$name} .= ", $datas";
          }
          elsif (@{$FORM{$name}} > 0) {
            push(@{$FORM{$name}}, $datas);
          }
          else {
            my $arrvalue = $FORM{$name};
            undef $FORM{$name};
            $FORM{$name}[0] = $arrvalue;
            push(@{$FORM{$name}}, $datas);
          }
        }
        else {
          #next if $datas =~ /^\s*$/;
          $datas =~ s/"/\\"/g;
          $datas =~ s/'/\\'/g;
          $FORM{"$name"} = $datas;
        }
        next;
      }
      for my $currentColumn (@columns) {
        my ($currentHeader, $currentValue) = $currentColumn =~ /^([^=]+)="([^\"]+)"$/;
        if ($currentHeader eq 'filename') {
          if ($currentValue =~ /(\S+)\\(\S+)$/) {
            $currentValue = $2;
          }
        }
        $FORM{"$name"}->{"$currentHeader"} = $currentValue;
      }

      $FORM{"$name"}->{'Contents'} = $datas;
      $FORM{"$name"}->{'Size'} = length($FORM{"$name"}->{'Contents'});
    }
  }

  return %FORM;
}

#**********************************************************
=head2 form_input($name, $value, $attr) - Show form input

  Arguments:
    $name
    $value
    $attr
      EX_PARAMS
      TYPE      - Input type (submit, hidden, checkbox)
      STATE     - State for checkbox
      FORM_ID   - Main form ID
      SUCCESS   - Green button for submit input
      DISABLED  - disable input
      ID        - custom id attr for element, uses $name otherwise

  Returns:
    html Input obj

=cut
#**********************************************************
sub form_input {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  my $type = $attr->{TYPE} || 'text';
  my $ex_params = '';

  if ($attr->{EX_PARAMS}) {
    $ex_params = $attr->{EX_PARAMS};
  }

  my $css_class = '';
  if ($attr->{class}) {
    $css_class = " class='$attr->{class}'";
  }
  elsif ($type =~ /text/i) {
    $css_class = " class='form-control'";
  }
  elsif ($type =~ /submit/i) {
    $css_class = " class='btn btn-" . (($attr->{SUCCESS}) ? 'success' : 'primary') . "'";
  }

  my $state = ($attr->{STATE}) ? ' checked ' : '';
  my $size = (defined($attr->{SIZE})) ? " size='$attr->{SIZE}'" : '';
  my $form = '';

  if ($attr->{FORM_ID}) {
    if ($attr->{FORM_ID} ne 'SKIP') {
      $form = " FORM='$attr->{FORM_ID}'";
    }
  }
  elsif ($self->{FORM_ID}) {
    $form = " FORM='$self->{FORM_ID}'";
  }

  if ($attr->{DISABLED}) {
    $ex_params .= ' disabled="disabled"';
  }

  my $id = $attr->{ID} || $name;

  $self->{FORM_INPUT} = "<input type='$type' name='$name' value=\"" . ($value // '') . "\"$state$size$css_class $ex_params$form ID='$id'/>";

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#**********************************************************
=head2 form_textarea($name, $value, $attr) - Show form textarea input

  Arguments:
    $name
    $value
    $attr
  Returns:

=cut
#**********************************************************
sub form_textarea {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  my $cols = $attr->{COLS} || 45;
  my $rows = $attr->{ROWS} || 4;

  $self->{FORM_INPUT} = "<textarea id='$name' name='$name' cols=$cols rows=$rows class='form-control'>" . ($value || '') . "</textarea>";

  if ($attr->{HIDE}) {
    $self->{FORM_INPUT} = "<div class=\"box box-theme\">
  <div class='box-header with-border'>
    <a data-toggle='collapse' data-parent='#accordion' href='#collapseOne'>$name</a>
  </div>
  <div id='collapseOne' class='box-collapse collapse'>
    <div class='box-body'>
       $self->{FORM_INPUT}
    </div>
  </div>
</div>";
  }

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#**********************************************************
=head2 form_main($attr) - Create input form container

  Arguments:

    $attr
      CONTENT    - Main content
      HIDDEN     - Hidden fields hash_ref
              { index => 21 }
      SUBMIT     - Submit elent hash_ref
              { submit => $lang{ADD} }
      ID         - Form id
      EXPORT_CONTENT - Export content
      METHOD     - HTTP Method for submit
      ENCTYPE
      NAME
      TARGET
      class
      OUTPUT2RETURN

  Results:

    output result string

  Examples:

=cut
#**********************************************************
sub form_main {
  my $self = shift;
  my ($attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne ($attr->{ID} || q{})) {
    return '';
  }

  my $METHOD = ($attr->{METHOD}) ? $attr->{METHOD} : 'POST';

  $self->{FORM} = "<FORM ";
  if ($attr->{ID}) {
    $self->{FORM} .= "ID='$attr->{ID}' ";
    $self->{FORM_ID} = $attr->{ID};
  }

  $self->{FORM} .= $attr->{class}
    ? " class='$attr->{class} form-main' role='form' "
    : " class='form form-horizontal form-main' role='form' ";
  $self->{FORM} .= " name='$attr->{NAME}' " if ($attr->{NAME});
  $self->{FORM} .= " enctype='$attr->{ENCTYPE}' " if ($attr->{ENCTYPE});
  $self->{FORM} .= " target='$attr->{TARGET}' " if ($attr->{TARGET});
  $self->{FORM} .= " action='$SELF_URL' METHOD='$METHOD'>\n";

  if (defined($attr->{HIDDEN})) {
    my $H = $attr->{HIDDEN};
    while (my ($k, $v) = each(%$H)) {
      if ($k) {
        my $form = ($attr->{ID}) ? " form='$attr->{ID}'" : '';
        $self->{FORM} .= "<input type='hidden' name='$k' value='" . ($v || '') . "'$form>\n";
      }
    }
  }

  if (defined($attr->{CONTENT})) {
    $self->{FORM} .= $attr->{CONTENT};
  }

  if ($attr->{SUBMIT}) {
    my $H = $attr->{SUBMIT};
    foreach my $k (sort keys %$H) {
      my $v = $H->{$k};
      my $form = ($attr->{ID}) ? " form='$attr->{ID}'" : '';
      if ($k) {
        $self->{FORM} .= "<input type='submit' name='$k' value='" . ($v || '') . "' class='btn btn-primary'$form>\n";
      }
    }
  }

  $self->{FORM} .= "</form>\n";
  delete($self->{FORM_ID});

  if ($attr->{OUTPUT2RETURN}) {
    return $self->{FORM};
  }
  elsif (defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $self->{FORM};
    $self->{FORM} = '';
  }

  return $self->{FORM};
}

#**********************************************************
=head2 form_select($name, $attr) - Create FORM select element

  Arguments:

    $name        - Element name
    $attr
      SEL_ARRAY      - ARRAY_ref
      ARRAY_NUM_ID   - treat array item position as id
      SEL_HASH       - HASH_ref
        SORT_VALUE
        SORT_KEY_NUM
      SEL_LIST       - list of array_hash
      SEL_KEY        - key for option name
      SEL_VALUE      - key for option value
      NO_ID          - Do not display hash key
      SELECTED       - Selected value
      POPUP_WINDOW   - Make popup window
      FORM_ID        - Main form ID
      ID             - Elemet ID
      MAIN_MENU      - Main menu link for main function
      MAIN_MENU_ARGV - Arguments for main menu
      EXT_BUTTON     - Allow second button next to MAIN_MENU
      WRITE_TO_DATA  - Writes to HTML5 attr 'data-' named values from list
      STYLE          - Array of element style
      SEL_OPTIONS    - Extra sel options HASH_REF { key => value, ... }
      EXPORT_CONTENT - Export content
      USE_COLORS     - Use color for hash value
      EX_PARAMS      - Extra HTML attributes
      NORMAL_WIDTH   - By default, all selects in .form-horizontal .form-group will have .form-group width,
                       this options sets width to 100% (.form-control styles)
      AUTOSUBMIT     - Submit form when selected ( $URL or 'form' )
      REQUIRED       - Make select required ( do not allow to send form when empty ) label should have class .required
      MULTIPLE       - Allow to choose few values from one select
      OUTPUT2RETURN

  Results:

    output result string

  Examples:

=cut
#**********************************************************
sub form_select {
  my $self = shift;
  my ($name, $attr) = @_;

  if ($attr->{POPUP_WINDOW}) {
    return $self->form_window($name, $attr);
  }

  my $ex_params = ($attr->{EX_PARAMS}) ? $attr->{EX_PARAMS} : '';
  my $css_class = q{ class='};
  $css_class .= ($attr->{class}) ? $attr->{class} : 'form-control';
  $css_class .= ' normal-width' if ($attr->{NORMAL_WIDTH});
  $css_class .= q{'};

  my $form = '';
  if ($attr->{FORM_ID}) {
    $form = " form='$attr->{FORM_ID}'";
  }
  elsif ($self->{FORM_ID}) {
    $form = " form='$self->{FORM_ID}'";
  }

  if ($attr->{AUTOSUBMIT}) {
    $ex_params .= 'data-auto-submit="' . $attr->{AUTOSUBMIT} . '"';
  }

  if ($attr->{REQUIRED}) {
    $ex_params .= ' required="required"';
  }

  if ($attr->{MULTIPLE}) {
    $ex_params .= ' multiple="multiple"';
  }

  my $element_id = ($attr->{ID}) ? $attr->{ID} : $name;

  $self->{SELECT} = "<select name='$name' $ex_params ID='$element_id'$css_class style='max-width: 300px;'$form>\n";

  if (defined($attr->{SEL_OPTIONS})) {
    foreach my $k (keys(%{$attr->{SEL_OPTIONS}})) {
      $self->{SELECT} .= "<option value='$k'";
      $self->{SELECT} .= ' selected' if (defined($attr->{SELECTED}) && $k eq $attr->{SELECTED});
      $self->{SELECT} .= ">" . ($attr->{SEL_OPTIONS}->{$k} || '') . "\n";
    }
  }

  my @multiselect = ();
  if ($attr->{SELECTED} && $attr->{SELECTED} =~ /,\s?/) {
    @multiselect = split(',\s?', $attr->{SELECTED});
  }

  if (defined($attr->{SEL_ARRAY})) {
    my $H = $attr->{SEL_ARRAY};
    my $i = 0;

    foreach my $v (@$H) {
      my $id = (($attr->{ARRAY_NUM_ID})) ? $i : $v;
      $self->{SELECT} .= "<option value='$id'";
      if ($attr->{STYLE}) {
        if ($attr->{STYLE}->[$i] && $attr->{STYLE}->[$i] =~ /#/) {
          $self->{SELECT} .= "style='COLOR:$attr->{STYLE}->[$i];' ";
        }
        elsif ($attr->{STYLE}->[$i]) {
          $self->{SELECT} .= " class='$attr->{STYLE}->[$i]'";
        }
      }
      if (
        defined($attr->{SELECTED})
          && (($attr->{ARRAY_NUM_ID} && $i eq $attr->{SELECTED})
          || ($attr->{ARRAY_NUM_ID} && grep {$_ eq $i} @multiselect)
          || ($v eq $attr->{SELECTED}))
      ) {
        $self->{SELECT} .= ' selected';
      }
      $self->{SELECT} .= '>' . (defined($v) ? $v : '') . "\n";
      $i++;
    }
  }
  #  elsif (defined($attr->{SEL_MULTI_ARRAY})) {
  #    my $key                      = $attr->{MULTI_ARRAY_KEY};
  #    my $value                    = $attr->{MULTI_ARRAY_VALUE};
  #    my $H                        = $attr->{SEL_MULTI_ARRAY};
  #    my @MULTI_ARRAY_VALUE_PREFIX = ();
  #
  #    if ($attr->{MULTI_ARRAY_VALUE_PREFIX}) {
  #      @MULTI_ARRAY_VALUE_PREFIX = split(/,/, $attr->{MULTI_ARRAY_VALUE_PREFIX});
  #    }
  #
  #    foreach my $v (@$H) {
  #      $self->{SELECT} .= "<option value='$v->[$key]'";
  #      $self->{SELECT} .= ' selected' if (defined($attr->{SELECTED}) && $v->[$key] eq $attr->{SELECTED});
  #      $self->{SELECT} .= '>';
  #
  #      #Value
  #      $self->{SELECT} .= "$v->[$key] " if (!$attr->{NO_ID});
  #
  #      if ($value =~ /,/) {
  #        my @values      = split(/,/, $value);
  #        my $key_num     = 0;
  #        my @values_arr = ();
  #        foreach my $val_keys (@values) {
  #          push @values_arr, (($attr->{MULTI_ARRAY_VALUE_PREFIX} && $MULTI_ARRAY_VALUE_PREFIX[$key_num]) ? $MULTI_ARRAY_VALUE_PREFIX[$key_num] . $v->[ int($val_keys) ] : $v->[ int($val_keys) ]);
  #          $key_num++;
  #        }
  #        $self->{SELECT} .= join(' : ', @values_arr);
  #      }
  #      else {
  #        $self->{SELECT} .= "$v->[$value]";
  #      }
  #      $self->{SELECT} .= "\n";
  #    }
  #  }
  elsif ($attr->{SEL_LIST}) {
    my $has_selected = defined($attr->{SELECTED});
    my $key = $attr->{SEL_KEY} || 'id';
    my $value = $attr->{SEL_VALUE} || 'name';
    my $H = $attr->{SEL_LIST};
    my @SEL_VALUE_PREFIX = ();

    if ($attr->{SEL_VALUE_PREFIX}) {
      @SEL_VALUE_PREFIX = split(/,/, $attr->{SEL_VALUE_PREFIX});
    }

    my $add_data_to_option = $attr->{WRITE_TO_DATA};
    foreach my $v (@$H) {
      $self->{SELECT} .= "<option value='" . ((ref $v eq 'HASH' && $v->{$key}) ? $v->{$key} : '') . "'";
      $self->{SELECT} .= "style='COLOR:#$v->{color};'" if (ref $v eq 'HASH' && $v->{color});

      if ($has_selected) {
        if (ref $v eq 'HASH' && defined($v->{$key})) {
          if ($v->{$key} eq $attr->{SELECTED}) {
            $self->{SELECT} .= ' selected ';
          }
          elsif ($v->{$key} ~~ @multiselect) {
            $self->{SELECT} .= ' selected ';
          }
        }
      }

      if ($add_data_to_option && $v->{$add_data_to_option}) {
        $self->{SELECT} .= ' data-' . $add_data_to_option . '="' . ($v->{$add_data_to_option} || q{}) . '"';
      }

      $self->{SELECT} .= '>';
      #Value
      $self->{SELECT} .= ' ' . ((ref $v eq 'HASH' && $v->{$key}) || '') . ' ' if (!$attr->{NO_ID});

      if ($value =~ /,/) {
        my @values = split(/,/, $value);
        my @values_arr = ();
        for (my $key_num = 0; $key_num <= $#values; $key_num++) {
          my $val_keys = $values[$key_num] || '';
          push @values_arr, (($attr->{SEL_VALUE_PREFIX} && $SEL_VALUE_PREFIX[$key_num]) ? $SEL_VALUE_PREFIX[$key_num] : '')
            . ((ref $v eq 'HASH' && $v->{$val_keys}) ? $v->{$val_keys} : '');
        }
        if ($#values_arr > -1) {
          $self->{SELECT} .= join(' : ', @values_arr);
        }
      }
      else {
        $self->{SELECT} .= ((ref $v eq 'HASH' && $v->{$value}) ? $v->{$value} : '');
      }
      $self->{SELECT} .= "</option>\n";
    }
  }
  elsif ($attr->{SEL_HASH}) {
    my @H = ();
    my @group_colors = ('#000000', '#008000', '#0000A0', '#D76B00', '#790000', '#808000', '#3D7A7A');
    my $group_id = 0;
    if ($attr->{SORT_KEY}) {
      @H = sort keys %{$attr->{SEL_HASH}};
    }
    elsif ($attr->{SORT_KEY_NUM}) {
      @H = sort {$a <=> $b} keys %{$attr->{SEL_HASH}};
    }
    else {
      @H = sort {($attr->{SEL_HASH}->{$a} || '') cmp ($attr->{SEL_HASH}->{$b} || '')} keys %{$attr->{SEL_HASH}};
    }

    foreach my $k (@H) {
      if (ref $attr->{SEL_HASH}->{$k} eq 'ARRAY') {
        $self->{SELECT} .= "<optgroup label='== $k ==' title='$k'>\n";

        foreach my $val (@{$attr->{SEL_HASH}->{$k}}) {
          $self->{SELECT} .= "<option value='$val'";
          $self->{SELECT} .= " style='COLOR:$attr->{STYLE}->[$val];' " if ($attr->{STYLE});
          if (defined($attr->{SELECTED})) {
            if ($val eq $attr->{SELECTED}) {
              $self->{SELECT} .= ' selected'
            }
            elsif ($val ~~ @multiselect) {
              $self->{SELECT} .= ' selected';
            }
          }

          $self->{SELECT} .= '>';

          #$self->{SELECT} .= "$val " if (! $attr->{NO_ID});
          $self->{SELECT} .= "$val\n";
        }
        $self->{SELECT} .= "</optgroup>";
      }
      elsif (ref $attr->{SEL_HASH}->{$k} eq 'HASH') {
        $self->{SELECT} .= "<optgroup label='== $k ==' title='= $k =' style='font-weight: bold'>\n";

        my @sorted_list = ();
        if ($attr->{SORT_VALUE}) {
          @sorted_list = sort {
            length($attr->{SEL_HASH}->{$k}->{$a} || '') <=> length($attr->{SEL_HASH}->{$k}->{$b} || '')
              || $attr->{SEL_HASH}->{$k}->{$a} cmp $attr->{SEL_HASH}->{$k}->{$b}
          } keys %{$attr->{SEL_HASH}->{$k}};
        }
        else {
          @sorted_list = sort {length($a || 0) <=> length($b || 0) || $a cmp $b} keys %{$attr->{SEL_HASH}->{$k}};
        }

        foreach my $val (@sorted_list) {
          $self->{SELECT} .= "\n<option value='$val'";
          $self->{SELECT} .= " style='COLOR:$attr->{STYLE}->[$val];' " if ($attr->{STYLE} && $attr->{STYLE}->[$val]);

          if ($attr->{STYLE} && $attr->{STYLE}->[$val]) {
            if ($attr->{STYLE}->[$val] =~ /^#/) {
              $self->{SELECT} .= " style='COLOR:$attr->{STYLE}->[$val];' ";
            }
            else {
              $self->{SELECT} .= " class='$attr->{STYLE}->[$val]' ";
            }
          }
          elsif ($attr->{GROUP_COLOR} && $group_colors[$group_id]) {
            $self->{SELECT} .= " style='COLOR:$group_colors[$group_id];' ";
          }

          if (defined($attr->{SELECTED})) {
            if ($val eq $attr->{SELECTED}) {
              $self->{SELECT} .= ' selected';
            }
            elsif ($val ~~ @multiselect) {
              $self->{SELECT} .= ' selected';
            }
          }
          $self->{SELECT} .= ">";
          $self->{SELECT} .= "$attr->{SEL_HASH}->{$k}->{$val}\n";
        }
        $self->{SELECT} .= "\n</optgroup>\n";
        $group_id++;
      }
      else {
        $self->{SELECT} .= "<option value='$k'";
        my $value = $attr->{SEL_HASH}{$k} || '';
        if ($k && $attr->{STYLE} && $attr->{STYLE}->[$k]) {
          $self->{SELECT} .= " style='COLOR:$attr->{STYLE}->[$k];' ";
        }
        elsif ($attr->{USE_COLORS}) {
          my @arr = split(/:/, $value);
          $value = $arr[0] || q{};
          my $color = $arr[$#arr] || q{};
          if ($color =~ /^#?([A-F0-9]+)$/i) {
            $color = '#' . $1;
          }
          $self->{SELECT} .= " style='COLOR:$color;' ";
        }

        if (defined($attr->{SELECTED})) {
          if ($k eq $attr->{SELECTED}) {
            $self->{SELECT} .= ' selected ';
          }
          elsif ($k ~~ @multiselect) {
            $self->{SELECT} .= ' selected ';
          }
        }

        $self->{SELECT} .= '>';
        $self->{SELECT} .= "$k " if (!$attr->{NO_ID});
        $self->{SELECT} .= $value . "\n";
      }
    }
  }

  $self->{SELECT} .= "</select>\n";

  if ($attr->{MAIN_MENU}) {
    my $input = q{};
    if ($attr->{CHECKBOX}) {
      my $checkbox_name = $attr->{CHECKBOX};
      my $checkbox_title = $attr->{CHECKBOX_TITLE} || q{};
      my $state = $FORM{$checkbox_name} || $attr->{CHECKBOX_STATE};
      $input = $self->form_input($checkbox_name, '1', {
        TYPE      => 'checkbox',
        EX_PARAMS => "NAME='$checkbox_name' data-tooltip='$checkbox_title'",
        ID        => 'DATE',
        STATE     => $state
      },
        { OUTPUT2RETURN => 1 });
    }

    $self->{SELECT} = "
      <div class='input-group'>
      $self->{SELECT}
      <span class='input-group-addon'> $input"
      . $self->button('info', "index=$attr->{MAIN_MENU}" . (($attr->{MAIN_MENU_ARGV}) ? "&$attr->{MAIN_MENU_ARGV}" : ''), { class => 'show' })
      . ($attr->{EXT_BUTTON} || '')
      . "</span></div>\n";
  }
  elsif ($attr->{EXT_BUTTON}) {
    $self->{SELECT} = "
      <div class='input-group'>
      $self->{SELECT}
      <span class='input-group-addon'>"
      . ($attr->{EXT_BUTTON} || '')
      . "</span></div>\n";
  }

  return $self->{SELECT};
}

#**********************************************************
=head2 form_window($name, $attr) - Show modal windows

  Arguments:
    $name   - Windows name
    $attr   - Extra elements

  Returns:
    $self->{WINDOW}

=cut
#**********************************************************
sub form_window {
  my $self = shift;
  my ($name, $attr) = @_;

  #my $ex_params = (defined($attr->{EX_PARAMS})) ? $attr->{EX_PARAMS} : '';

  my $action = $attr->{ACTION} || $SELF_URL;
  #my $form_id      = $attr->{FORM_ID}  || 'FormModal';
  my $window_type = $attr->{POPUP_WINDOW_TYPE} || 'search';
  my $searchString = $attr->{SEARCH_STRING} || '';
  my $js_script = $attr->{JS} || 'search';
  my $parent_input_name = $attr->{PARENT_INPUT} || '';

  my $main_menu = $attr->{MAIN_MENU} || '';
  #my $main_menu_argv = $attr->{MAIN_MENU_ARGV} || '';

  # Counter for storing params in array
  $self->{button_num}++;
  my $buttonNum = $self->{button_num} - 1;

  $self->{WINDOW} = "
   <div class='input-group'> ";

  my $tooltip = $attr->{TOOLTIP} ? " data-tooltip='$attr->{TOOLTIP}' data-tooltip-position='left auto'" : '';

  if ($attr->{HAS_NAME}) {
    $self->{WINDOW} .= "<input type='hidden' value='%" . $name . "%' name='$name' id='$name'/>
      <input type='text' $tooltip value='" . (($attr->{VALUE}) ? $attr->{VALUE} : '%' . $name . '%') . "' name='" . $name . "1' id='$name\_1' class='form-control'/>";
  }
  else {
    $self->{WINDOW} .= "<input type='text' value='" . ($attr->{VALUE} || '') . "' name='$name' class='form-control'/>";
  }

  $self->{WINDOW} .= "<span class='input-group-addon'> ";

  if ($attr->{MAIN_MENU}) {
    # FIXME : NAS_ID?
    $self->{WINDOW} .= " <div style='display:inline; cursor:pointer;'>
          <a onclick='replace(hrefValue( \"" . $SELF_URL . "\", \"" . $main_menu . "\", \"NAS_ID\"))'>
            <span class='glyphicon glyphicon-list-alt'></span>
          </a>
      </div>\n";
  }

  my $modal_size = $attr->{POPUP_SIZE} || '';
  $self->{WINDOW} .= "
    <a id='btnPopupOpen' type='button' onclick=\'openModal($buttonNum, \"TemplateBased\", \"$modal_size\");\'>
       <span class='glyphicon glyphicon-search'></span>
    </a>
    <div class='clear_results' style='display:inline; cursor:pointer;'>
      <span class='glyphicon glyphicon-remove'></span>
    </div>\n";

  $self->{WINDOW} .= "
    </span>
   </div>

   <script>
     modalsArray[modalsArray.length] = new Array(\'$action\',\'$name\',\'$parent_input_name\',\'$searchString\',\'$window_type\');
     //console.log(searchString);
   </script>
   <script type='text/javascript' src='/styles/default_adm/js/$js_script.js'></script>\n";

  return $self->{WINDOW};
}

#**********************************************************
=head2 set_cookies($name, $value, $expiration, $path, $attr) - Set cookies

  Arguments:

    $name        - Cookie name
    $value       - Cookie value
    $expiration  - Cookie expire (Default: 24 hour)
    $path        - web path
    $attr        -
      SKIP_SAVE    - Skip Save cookie
      DOMAIN       - domain
      SECURE       - secure world

  Results:

    print cookie

=cut
#**********************************************************
sub set_cookies {
  my $self = shift;
  my ($name, $value, $expiration, $path, $attr) = @_;

  $expiration = gmtime(time() + (($CONF->{web_session_timeout}) ? $CONF->{web_session_timeout} : 86400)) . " GMT" if (!$expiration);
  $value = '' if (!$value);

  my $cookie = "Set-Cookie: $name=$value; expires=\"$expiration\"; ";

  if ($path && $path ne "") {
    $cookie .= " path=$path; ";
  }

  if ($self->{domain}) {
    $cookie .= " domain=$self->{domain}; ";
  }
  elsif ($attr->{DOMAIN}) {
    $cookie .= " domain=$attr->{DOMAIN}; ";
  }

  if (!$attr->{SKIP_SAVE}) {
    $COOKIES{$name} = $value;
  }

  if ($self->{secure}) {
    $cookie .= " $self->{secure}";
  }
  elsif ($attr->{SECURE}) {
    $cookie .= " $attr->{SECURE}";
  }

  print $cookie . "\n";
}

#**********************************************************
=head2 get_cookies() - get cookie values and return hash of it

  Results:

    return cookies (HASH_REF)

  Examples:

    my $cookies = $html->get_cookies();

=cut
#**********************************************************
sub get_cookies {
  #my $self = shift;

  if (defined($ENV{'HTTP_COOKIE'})) {
    my (@rawCookies) = split(/; /, $ENV{'HTTP_COOKIE'});
    foreach (@rawCookies) {
      my ($key, $val) = split(/=/, $_);
      $COOKIES{$key} = $val;
    }
  }

  return \%COOKIES;
}

#**********************************************************
=head2 menu($menu_items, $menu_args, $permissions, $attr) - Make menu

  Arguments:
    $menu_items   - Menu items hash_ref
    $menu_args    - Extra menu arguments
    $permissions  - Admin permissions hash_ref
    $attr         - Extra attrinbutes

  Returns:
    $menu_navigator, $menu_text

=cut
#**********************************************************
sub menu {
  my $self = shift;
  my ($menu_items, $menu_args, $permissions, $attr) = @_;
  my $menu_navigator = '';
  my $root_index = 0;
  my %tree = ();
  my %menu = ();
  my $sub_menu_array;
  my $EX_ARGS = (defined($attr->{EX_ARGS})) ? $attr->{EX_ARGS} : '';
  my $fl = $attr->{FUNCTION_LIST};


  # make navigate line
  if ($index > 0) {
    $root_index = $index;
    my $h = $menu_items->{$root_index};
    my @menu_links = ();
    my @plain_breadcrumb = ();

    while (my ($par_key, $name) = each(%$h)) {
      my $ex_params = '';
      if (defined($menu_args->{$root_index})) {
        if ($menu_args->{$root_index} =~ /=/) {
          $ex_params = "&$menu_args->{$root_index}";
        }
        elsif (defined($FORM{ $menu_args->{$root_index} })) {
          $ex_params = '&' . "$menu_args->{$root_index}=$FORM{$menu_args->{$root_index}}";
        }
      }

      unshift @menu_links, $self->button($name, "index=$root_index$ex_params");
      unshift @plain_breadcrumb, $name if ($root_index > 10);

      $tree{$root_index} = 1;
      if ($par_key && $par_key > 0) {
        $root_index = $par_key;
        $h = $menu_items->{$par_key};
      }
    }
    if ($#plain_breadcrumb) {
      $self->{BREADCRUMB} = join(' > ', @plain_breadcrumb);
    }
    $menu_navigator = "<ol class='breadcrumb'>" . join($self->li('>'), map {$self->li($_)} @menu_links) . "</ol>\n";
  }

  $FORM{root_index} = $root_index;
  if ($root_index > 0) {
    my $ri = $root_index - 1;
    if (defined($permissions) && (!defined($permissions->{$ri}))) {
      $self->{ERROR} = "Access deny $ri";
      return '', '';
    }
  }

  my @s = sort {$b <=> $a} keys %$menu_items;

  foreach my $ID (@s) {
    my $VALUE_HASH = $menu_items->{$ID};
    foreach my $parent (keys %$VALUE_HASH) {
      if (!defined($menu_args->{$ID}) || (defined($menu_args->{$ID}) && (defined($FORM{ $menu_args->{$ID} }) || $menu_args->{$ID} =~ /=/))) {
        push(@{$menu{$parent}}, "$ID:" . ($VALUE_HASH->{$parent} || ''));
      }
    }
  }
  my @last_array = ();
  my $menu_text = "<ul class='sidebar-menu'>";
  my $level = 0;
  my $parent = 0;
  my %main_ids = ();

  foreach my $line (@{$menu{$parent}}) {
    #($ID, $name)
    my ($ID, undef) = split(/:/, $line, 2);
    $main_ids{ "sub" . $ID } = 1;
  }

  label:
  $sub_menu_array = \@{$menu{$parent}};
  #my $m_item = '';
  #my %table_items = ();

  while (my $sm_item = pop @$sub_menu_array) {
    my ($ID, $name) = split(/:/, $sm_item, 2);
    my $id = (($ID =~ /^sub([0-9]+)/) ? $1 : $ID);
    next if ((!defined($attr->{ALL_PERMISSIONS})) && (!defined($permissions->{ $id - 1 })) && $parent == 0);

    my $active = '';
    my $class = '';
    if ($parent == 0 && $menu{$ID}) {
      $class = "treeview";
    }
    if (defined($tree{$ID}) && $parent == 0) {
      #      $name   = '<span class="glyphicon glyphicon-chevron-right"></span> '.$self->b($name);
      $active = 'active';
    }
    elsif (defined($tree{$ID})) {
      $active = 'active menu-open';
    }
    my $ext_args = "$EX_ARGS";

    if (defined($menu_args->{$id})) {
      $ext_args = ($menu_args->{$id} =~ /=/) ? "&$menu_args->{$id}" : "&$menu_args->{$id}=$FORM{$menu_args->{$id}}";
      #$name = $self->b($name) if ($name !~ /<b>/);
      #$active = ' active';
    }
    if ($menu{$ID} && $fl->{$ID} ne 'null') {
      push @{$menu{$ID}}, "sub" . $ID . ":" . $name;
      $fl->{ "sub" . $ID } = $fl->{$ID};
    }
    if (($parent != 0 && ($level eq 1 || $level eq 2)) && !$main_ids{ $ID }) {
      $name = "<i class='fa fa-circle-o'></i>" . $name;
    }
    my $ex_params = ($parent == 0) ? (($fl->{$ID} ne 'null') ? ' id=' . $fl->{$ID} : '') : '';
    $ex_params .= ($menu{$ID} && $fl->{$ID} eq 'null' || $fl->{ "sub" . $ID }) ? " onclick='return false'" : "";
    $name .= "<span class='pull-right-container'>\n<i class='fa fa-angle-left pull-right'></i>\n</span>" if ($menu{$ID});
    #my $link = $self->button($name, "index=" . (($ID =~ /^sub([0-9]+)/) ? $1 : $ID) . "$ext_args", { ex_params => ($parent == 0) ? (($fl->{$ID} ne 'null') ? ' id=' . $fl->{$ID} : '') : '', SKIP_HREF => ($menu{$ID} && $fl->{$ID} eq 'null' || $fl->{ "sub" . $ID } )? "1" : '' });
    my $link = $self->button($name, ($menu{$ID} && $fl->{$ID} eq 'null' || $fl->{ "sub" . $ID }) ? "index=$index" : "index=" . (($ID =~ /^sub([0-9]+)/) ? $1 : $ID) . "$ext_args", { ex_params => $ex_params });
    if ($parent == 0) {
      #User add function
      #if ($ID == 1) {
      #  $link .= "<span>[+]</span>";
      #}
      $menu_text .= "<li class='$class $active'>$link\n";
    }
    elsif (defined($menu{$ID})) {
      $menu_text .= "<li class='$active'>$link\n\n";
    }
    else {
      $menu_text .= "<li class='$active'>$link\n";
    }

    if (!$menu{$ID}) {
      $menu_text .= "</li>\n";
    }
    else {
      $menu_text .= "<ul class='treeview-menu'>\n ";
    }

    if (defined($menu{$ID})) {
      $level++;
      push @last_array, $parent;
      $parent = $ID;
      $sub_menu_array = \@{$menu{$parent}};
    }
  }

  if ($#last_array > -1) {
    $menu_text .= "</ul></li>\n";
    $parent = pop @last_array;
    $level--;
    goto label;
  }

  $menu_text .= "</ul>\n";

  return($menu_navigator, $menu_text);
}

#**********************************************************
=head2 menu_right($menu_items, $menu_args, $permissions, $attr) - Make menu

  Arguments:
    $menu_item_name    - Menu item name
    $menu_item_id      - Menu item name
    $menu_content      - Menu html code;
    $attr    - Full html if item is apdded.
      HTML        - Full html if item is added.
      SKIN        - Skin menu.
  Returns:
    $right_menu_html

=cut
#**********************************************************
sub menu_right {
  my $self = shift;
  my ($menu_item_name, $menu_item_id, $menu_content, $attr) = @_;
  my $right_menu_html = '';
  my $menu_item = $self->li("<a href='#$menu_item_id' id='$menu_item_id\_btn' data-toggle='tab' aria-expanded='false'>$menu_item_name</a>", { class => 'active' });

  if (!$attr->{HTML}) {
    $right_menu_html = "<aside class='control-sidebar $attr->{SKIN}'>\n";
    $right_menu_html .= "<ul class='nav nav-tabs nav-justified control-sidebar-tabs'>\n</ul>\n<div class='tab-content'>\n</div>\n";
  }
  if (!defined($menu_content)) {
    $menu_content = '';
  }

  $right_menu_html = $attr->{HTML} if ($attr->{HTML});
  $right_menu_html =~ s/class='active'//g;
  $right_menu_html =~ s/ active//g;
  $right_menu_html =~ s/(<ul class='nav nav-tabs nav-justified control-sidebar-tabs'>\n)/$1$menu_item \n/g;
  $right_menu_html =~ s/(<div class='tab-content'>\n)/$1<div class='tab-pane active' id='$menu_item_id'>\n$menu_content<\/div>\n/g;

  if (!$attr->{HTML}) {
    $right_menu_html .= "</aside>";
    $right_menu_html .= "<div class='control-sidebar-bg'></div>";
  }

  return $right_menu_html;
}
#**********************************************************
=head2 menu2($menu_items, $menu_args, $permissions, $attr) - User portal menu

=cut
#**********************************************************
sub menu2 {
  my $self = shift;
  return $self->menu(@_);
  my ($menu_items, $menu_args, $permissions, $attr) = @_;

  my $menu_navigator = '';
  my $root_index = 0;
  my %tree = ();
  my %menu = ();
  #  my $ext_args       = (defined($attr->{EX_ARGS})) ? $attr->{EX_ARGS} : '';
  #  my $fl             = $attr->{FUNCTION_LIST};

  # make navigate line
  if ($index > 0) {
    $root_index = $index;
    my $h = $menu_items->{$root_index};

    while (my ($par_key, $name) = each(%$h)) {
      my $ex_params = (defined($menu_args->{$root_index}) && defined($FORM{ $menu_args->{$root_index} })) ? '&' . "$menu_args->{$root_index}=$FORM{$menu_args->{$root_index}}" : '';
      $menu_navigator = " " . $self->button($name, "index=$root_index$ex_params") . '/' . $menu_navigator;
      $tree{$root_index} = 1;
      if ($par_key > 0) {
        $root_index = $par_key;
        $h = $menu_items->{$par_key};
      }
    }
  }

  $FORM{root_index} = $root_index;
  if ($root_index > 0) {
    my $ri = $root_index - 1;
    if (defined($permissions) && (!defined($permissions->{$ri}))) {
      $self->{ERROR} = "Access deny $ri";
      return '', '';
    }
  }

  my @menu_sorted = sort {$a <=> $b} keys %$menu_items;

  foreach my $ID (@menu_sorted) {
    my $VALUE_HASH = $menu_items->{$ID};
    foreach my $parent (sort keys %$VALUE_HASH) {
      push @{$menu{$parent}}, "$ID:$VALUE_HASH->{$parent}";
    }
  }

  my $menu_text = "<ul class='nav nav-pills nav-stacked'>\n";

  $menu_text .= $self->mk_menu(\%menu, $menu_args, $attr);

  $menu_text .= "</ul>\n";

  return($menu_navigator, $menu_text);
}

#**********************************************************
=head2 mk_menu($menu, $menu_args, $attr) - Make user menu

  Arguments:
    $menu         - Menu hash_ref
    $menu_args    - Menu arguments
    $attr
      PARENT        - Parent element
      EX_ARGS       - Extra arguments
      FUNCTION_LIST - Functions list
      SKIP_HREF     - Skip SKIP_HREF for dynamic reload

  Returns:

    formed menu

=cut
#**********************************************************
sub mk_menu {
  my $self = shift;
  my ($menu, $menu_args, $attr) = @_;

  my $parent = $attr->{PARENT} || 0;
  my $formed_menu = '';
  my $ext_args = ($attr->{EX_ARGS}) ? $attr->{EX_ARGS} : '';;
  my $fl = $attr->{FUNCTION_LIST};

  foreach my $parent_line (@{$menu->{$parent}}) {
    my ($parent_id, $parent_name) = split(/:/, $parent_line);
    $formed_menu .= "<li>" .
      $self->button("$parent_name", "#", { ex_params => "onclick=\"showContent('index.cgi?qindex=$parent_id&header=2$ext_args', this)\" ",
        NO_LINK_FORMER                               => 1,
        SKIP_HREF                                    => $attr->{SKIP_HREF},
        ID                                           => ($fl->{$parent_id}) ? $fl->{$parent_id} : '' }) .
      "</li>\n";

    if (ref $menu->{$parent_id} eq 'ARRAY') {
      $formed_menu .= '<ul>';
      $formed_menu .= $self->mk_menu($menu, $menu_args, { %$attr, PARENT => $parent_id });
      $formed_menu .= '</ul>';
    }
  }

  return $formed_menu;
}

#**********************************************************
=head2 header() - header of main page

  Arguments:

    $attr
      header
      CONTENT_LANGUAGE


  Examples:

    $html->header();

=cut
#**********************************************************
sub header {
  my $self = shift;
  my ($attr) = @_;

  $self->{header} = "Content-Type: text/html\n";
  $self->{header} .= "Access-Control-Allow-Origin: *"
    . "\n\n";

  $self->{HEADERS_SENT} = 1;

  if (($attr->{header} && $attr->{header} == 2) || !$self->{METATAGS}) {
    return $self->{header};
  }

  my %info = (
    JAVASCRIPT => 'functions.js',
    PRINTCSS   => 'print.css',
  );

  if ($self->{PATH}) {
    $info{JAVASCRIPT} = "$self->{PATH}$info{JAVASCRIPT}";
    $info{PRINTCSS} = "$self->{PATH}$info{PRINTCSS}";
  }

  $CONF->{WEB_TITLE} = $self->{WEB_TITLE} if ($self->{WEB_TITLE});

  $info{TITLE} = $CONF->{WEB_TITLE} || "~AsmodeuS~ Billing System";
  $info{HTML_STYLE} = $self->{HTML_STYLE};

  if ($FORM{REFRESH}) {
    my $text = $ENV{REQUEST_URI};
    $text =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    $info{REFRESH} = "<META HTTP-EQUIV=\"Refresh\" CONTENT=\"$FORM{REFRESH}; URL=$text\"/>\n";
  }

  $info{CHARSET} = $self->{CHARSET};
  $info{CONTENT_LANGUAGE} = $attr->{CONTENT_LANGUAGE} || $self->{content_language} || 'ru';
  $info{CALLCENTER_MENU} = $self->{CALLCENTER_MENU};

  $info{WEBSOCKET_URL} = '';
  if ($CONF->{WEBSOCKET_URL} || $CONF->{WEBSOCKET_ENABLED}) {
    if (!$CONF->{WEBSOCKET_URL}) {
      $info{WEBSOCKET_URL} = ($ENV{HTTP_HOST} || '') . "/admin/wss/";
    }
    else {
      $info{WEBSOCKET_URL} = $CONF->{WEBSOCKET_URL};
    }
  }

  $info{SIDEBAR_HIDDEN} = (exists $COOKIES{menuHidden})
    ? ($COOKIES{menuHidden} eq 'true') ? 'sidebar-collapse' : ''
    : '';

  $info{BREADCRUMB} = ($self->{BREADCRUMB}) ? '| ' . $self->{BREADCRUMB} : '';

  $self->{header} .= $self->tpl_show($self->{METATAGS} || '', \%info, {
    OUTPUT2RETURN      => 1,
    ID                 => $FORM{EXPORT_CONTENT},
    SKIP_DEBUG_MARKERS => 1
  });

  return $self->{header};
}

#**********************************************************
=head2 table() - Create table object

  Arguments:

    $attr
      caption     - table caption
      caption_icon - append icon to caption (exemple 'fa fa-info')
      width       - table width
      title       - table title array ref
      title_plain - plain table title array ref (without sort fields)
      header      - header buttons (array of buttons)
      border      - Table border
      qs          - Extra query string for element
      ID          - table ID
      MENU        - ???
      EXPORT      - show button for exporting table
      DATA_TABLE  - create table with data table plugin
      IMPORT      - Show import form
      summary     - Count elements and sum feess or sum payments
      NOT_RESPONSIVE
      SHOW_COLS_HIDDEN - Hidden columns for gum fields
      SKIP_TOP_PAGES - Skip top pages
      HIDE_TABLE  - Hide tible to cut
      SELECT_ALL  - Show select ID form
       'form_name:field_name:show_name'
      pages       - Show pages
      SHOW_FULL_LIST - Show full list page
      HAS_FUNCTION_FIELDS - boolean. Special CSS rules will be apllied to align last column to right
      MULTISELECT_ACTIONS       - form toolbar button ( see @table_actions_panel())
      SHOW_MULTISELECT_ACTIONS - show/hide buttons for selected checkboxes (with param)

  Returns:

     Table object

  Examples:

    my $table = $html->table(
    {
      width      => '100%',
      caption    => "Table caption",
      title      => [ "$lang{LOGIN}", "$lang{FIO}", "$lang{PHONE}" ],
      qs         => $pages_qs,
      ID         => 'TABLE_ID',
      export     => 1
    }
    );

    $table->addrow('test', 'Ivan Pupkin', '39999999999');

    $table->show();

  Table with header buttons:

    my @status_bar = (
      "$lang{ALL}:index=$index&NOTE_STATUS=ALL",
      "$lang{ACTIVE}:index=$index&NOTE_STATUS=0",
      "$lang{CLOSED}:index=$index&NOTE_STATUS=1",
      "$lang{INWORK}:index=$index&NOTE_STATUS=2"
    );

    my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{NOTEPAD},
      title      => [ $lang{DATE} . '/' . $lang{TIME}, $lang{ADDED}, $lang{STATUS}, $lang{SUBJECT}, '-', '-' ],
      cols_align => [ 'left', 'right', 'right', 'right', 'center', 'center' ],
      pages      => $Notepad->{TOTAL},
      header     => $html->table_header(\@status_bar),
      ID         => 'NOTEPAD_ID',
      MENU       => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
      EXPORT     => 1
      SELECT_ALL => 'users_list:UID:$lang{SELECT_ALL}',
      DATA_TABLE => 1,
    }
  );

=cut
#**********************************************************
#@returns Abills::HTML
sub table {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $parent = ref($proto) && $proto;
  my $self;

  $self = {};
  bless($self, $class);

  $self->{MAX_ROWS} = $parent->{MAX_ROWS};
  $self->{HTML} = $parent;
  $self->{prototype} = $proto;
  $self->{NO_PRINT} = $proto->{NO_PRINT};

  my ($attr) = @_;
  $self->{before_table} = '';
  $self->{table_caption} = '';
  $self->{rows} = '';
  $self->{summary} = '';

  #  my $width       = (defined($attr->{width}))  ? " width=\"$attr->{width}\""   : '';
  my $table_responsive = (($attr->{NOT_RESPONSIVE}) ? '' : ' table-responsive');
  my $border = ($attr->{border}) ? ' panel-body' : '';

  my $table_class = (defined($attr->{class})) ? $attr->{class} : 'table table-striped table-hover table-condensed';
  $table_class .= $attr->{HAS_FUNCTION_FIELDS} ? ' with-function-fields' : '';
  $table_class = " class=\"$table_class\" ";

  if (defined($attr->{rowcolor})) {
    $self->{rowcolor} = $attr->{rowcolor};
  }
  else {
    $self->{rowcolor} = undef;
  }

  $self->{ID} = $attr->{ID} || '';
  $attr->{qs} = '' if (!$attr->{qs});
  $self->{SELECT_ALL} = $attr->{SELECT_ALL} if (!$FORM{EXPORT_CONTENT});
  $self->{MULTISELECT_ACTIONS} = $attr->{MULTISELECT_ACTIONS};
  $self->{SHOW_MULTISELECT_ACTIONS} = $attr->{SHOW_MULTISELECT_ACTIONS};

  if (defined($attr->{rows})) {
    my $rows = $attr->{rows};
    foreach my $line (@$rows) {
      $self->addrow(@$line);
    }
  }

  # Table Caption
  my $show_cols = '';
  my $show_cols_button = '';

  my $pagination = '';
  if ($attr->{pages} && !$FORM{EXPORT_CONTENT}) {
    $self->{SHOW_FULL_LIST} = $attr->{SHOW_FULL_LIST};
    my $op = '';
    if ($FORM{index}) {
      $op = "index=$FORM{index}";
    }
    elsif ($FORM{qindex}) {
      $op = "index=$FORM{qindex}";
    }
    elsif ($index) {
      $op = "index=$index";
    }

    $pagination = $self->pages($attr->{pages}, "$op$attr->{qs}", { SKIP_NAVBAR => 1, %{$attr ? $attr : {}} });
  }

  if ($attr->{caption} || $attr->{caption1}) {
    if ($attr->{SHOW_COLS} && scalar %{$attr->{SHOW_COLS}}) {

      my $col_divider_count = int((scalar keys(%{$attr->{SHOW_COLS}})) / 2);
      my $modal_size = ($col_divider_count >= 3) ? 'lg' : 'sm';

      $show_cols .= "<div class='modal fade' id='" . $attr->{ID} . "_cols_modal' tabindex='-1' role='dialog' aria-hidden='true'>
  <div class='modal-dialog modal-$modal_size'>
    <div class='modal-content'>
      <div class='modal-header'>
        <button type='button' class='close' data-dismiss='modal' aria-hidden='true'>&times;</button>
      </div>
      <div class='modal-body text-left' id='nestedform'>";

      $show_cols .= "<FORM action='$SELF_URL' METHOD='post' name='form_show_cols' id='form_show_cols'>\n" if (!$attr->{SKIP_FORM});

      foreach my $param_name ('index', 'sort', 'desc', 'pg', 'PAGE_ROWS', 'search', 'USERS_STATUS', 'STATUS', 'STATE') {
        if ($FORM{$param_name}) {
          $show_cols .= "<input type=hidden form='form_show_cols' name=$param_name value='$FORM{$param_name}'>\n";
        }
      }

      if ($attr->{SHOW_COLS_HIDDEN}) {
        foreach my $key (keys %{$attr->{SHOW_COLS_HIDDEN}}) {
          $show_cols .= "<input type='hidden' name='$key' value='" . ($attr->{SHOW_COLS_HIDDEN}->{$key} || '') . "'>";
        }
      }

      my $col_counter = 0;
      $show_cols .= "<div class='row'><div class='col-md-6'>";
      foreach my $k (sort keys %{$attr->{SHOW_COLS}}) {

        if ($k eq 'uid' && ($FORM{UID} && $FORM{UID} ne '_SHOW')) {
          $show_cols .= "<input type=hidden name=UID value=$FORM{UID}>";
          next;
        }

        if ($col_divider_count - $col_counter++ == 0) {
          #Close prev cols and open new;
          $show_cols .= "</div><div class='col-md-6'>";
        }

        my $v = $attr->{SHOW_COLS}->{$k};
        $show_cols .= "<input type='checkbox' name='show_columns' value='" . uc($k) . "'";
        $show_cols .= ($attr->{ACTIVE_COLS}->{$k}) ? " checked='checked'" : '';
        $show_cols .= "> " . ($v || '') . "<br>\n";
      }
      $show_cols .= "</div></div>";

      if (!$attr->{SKIP_FORM}) {

        my $footer_btns = "<hr/>
      <div class='row text-center'>
        <input type='submit' id='del_cols' name=del_cols class='btn btn-default' value='Reset to default'>
        <input type='submit' id='show_cols' name=show_cols class='btn btn-primary' value='Save'>
      </div>
      ";

        $show_cols .= "$footer_btns";
        $show_cols .= "</FORM>\n";
      }

      $show_cols .= "

  </div>
  </div>
  </div>
</div>\n";

      $show_cols_button = "<button title='Extra fields' class='btn btn-box-tool' data-toggle='modal' data-target='#" . $attr->{ID} . "_cols_modal'><span class='glyphicon glyphicon-option-horizontal'></span></button>";
    }

    my $collapse_icon = ($attr->{HIDE_TABLE}) ? 'fa-plus' : 'fa-minus';
    $self->{table_caption} .= ""
      . (($attr->{ID}) ? "<button type='button' title='Show/Hide' class='btn btn-box-tool' data-widget='collapse'><i class='fa $collapse_icon'></i></button>" : '')
      . $show_cols_button;
  }

  my @header_obj = ();

  if ($attr->{header}) {
    if (ref $attr->{header} eq 'ARRAY') {
      $attr->{header} = $self->table_header($attr->{header}, { IN_DROPDOWN => 1 });
    }

    push @header_obj, $attr->{header};
  }

  if ($attr->{MENU}) {
    my @menu_buttons = ();
    if (ref $attr->{MENU} eq 'ARRAY') {
      push @menu_buttons, @{$attr->{MENU}};
    }
    else {
      my @menu_arr = split(/;/, $attr->{MENU});
      if ($attr->{MULTISELECT_ACTIONS}) {

        # Change to actions_panel
        my @actions_from_buttons = map {
          my ($name, $ext_attr, $css_class) = split(/:/, $_);
          {
            TITLE  => $name,
            ACTION => $ext_attr,
            #            CLASS  => $css_class,
            ICON   => $button_class_icons{$css_class}
          };
        } @menu_arr;

        $self->{before_table} .= $self->table_actions_panel(\@actions_from_buttons);
      }
      else {
        foreach my $line (@menu_arr) {
          my ($name, $ext_attr, $css_class) = split(/:/, $line);
          push @menu_buttons, $self->button($name, $ext_attr, { class => $css_class }) . "\n";
        }
      }
    }
    $self->{EXPORT_OBJ} .= join('', @menu_buttons);
  }

  #Export object
  if ($attr->{EXPORT} && $parent->{EXPORT_LIST} && !$FORM{EXPORT_CONTENT}) {
    my @export_formats = ('xml', 'csv', 'json');
    my $export_obj = '';

    eval {require Spreadsheet::WriteExcel;};
    if (!$@) {
      push @export_formats, 'xls';
    }
    #instantiate new dropdown menu
    $export_obj .= "<button title='Export' role='button' class='dropdown-toggle btn btn-box-tool' data-toggle='dropdown'" .
      " aria-haspopup='true' aria-expanded='false'>" .
      "<span class='glyphicon glyphicon-export'></span>" .
      "</button>" .
      "<ul class='dropdown-menu' style='min-width: 0;'>";

    #Fill dropdown list with items
    foreach my $export_name (@export_formats) {
      my $params = "&$export_name=1";
      if ($attr->{qs} !~ /PAGE_ROWS\=/) {
        $params .= "&PAGE_ROWS=1000000";
      }
      else {
        $attr->{qs} =~ s/PAGE_ROWS\=\d+/PAGE_ROWS\=100000/;
      }

      $export_obj .= "<li>";
      $export_obj .= $self->button($export_name,
        "qindex=$index$attr->{qs}"
          . (($PG) ? "&pg=$PG" : q{})
          . (($SORT) ? "&sort=$SORT" : q{})
          . (($DESC) ? "&desc=$DESC" : q{})
          . "&EXPORT_CONTENT=$attr->{ID}&header=1$params",
        { ex_params => 'target=export',
          class     => '' }) . "\n";
      $export_obj .= "</li>";
    }
    #close list and dropdown block
    $export_obj .= "</ul>";

    $self->{table_caption} = $export_obj . ($self->{table_caption} || '');
  }

  push @header_obj, $self->{EXPORT_OBJ} if ($self->{EXPORT_OBJ});

  if ($attr->{IMPORT}) {
    $self->{table_caption} = qq{<a role='button' title='Import' class='btn btn-box-tool' onclick='loadToModal("$attr->{IMPORT}")'>
      <span class='glyphicon glyphicon-import'></span>
    </a>
    } . $self->{table_caption};
  }

  #  if (defined($attr->{VIEW})) {
  #    $self->{table} .= "<TR><TD class='tcaption'>$attr->{VIEW}</td></TR>\n";
  #  }

  #my $colspan='';
  if ($#header_obj > -1) {
    $self->{table_export} = $self->{EXPORT_OBJ};

    if ($attr->{header}) {
      $self->{table_status_bar} = $attr->{header};
    }
  }

  $attr->{caption} = '' if (!$attr->{caption});
  my $collapse = ($attr->{HIDE_TABLE}) ? 'collapsed-box' : '';

  if ($attr->{DATA_TABLE}) {
    if (ref($attr->{DATA_TABLE}) ne 'HASH') {
      $attr->{DATA_TABLE} = {
        dom => qq'<"row"
        <"col-md-6"l>
        <"col-md-6"fp>
        >rtip'
      };
    }
    $attr->{DATA_TABLE}->{language} = { url => "/styles/$self->{HTML}{HTML_STYLE}/plugins/datatables/lang/" . $self->{prototype}{content_language} . ".json" };
    my $ATTR = ($attr) ? JSON->new->indent->encode($attr->{DATA_TABLE}) : '';
    if ($attr->{DT_CLICK}) {
      $show_cols = qq(
      <script>
      jQuery(function(){
        jQuery("td").hover(function() {
          jQuery(this).css('cursor','pointer');
        }, function() {
          jQuery(this).css('cursor','auto');
        });

        jQuery("tr").on("click", "td", function() {
          var table = jQuery(this).closest('table').DataTable();
          table.search('"' + this.innerText + '"').draw();
        });
      })
      </script>
      ) . $show_cols;
    }
    $show_cols = qq(
		<script>
		  jQuery(document).ready(function() {
		  	var table = jQuery("#$self->{ID}_").DataTable($ATTR);
		  });
		</script>
	  ) . $show_cols;
    # Data table has its own sort
    if ($attr->{title} && !$attr->{title_plain} && !$attr->{SORT}) {
      $attr->{title_plain} = $attr->{title};
      delete $attr->{title};
    }
  }

  my $box_theme = ($attr->{LITE_HEADER}) ? 'box-solid' : 'box-theme';
  $self->{table} = $show_cols . '<div class="box ' . $box_theme . ' FK ' . $collapse . '"\>';

  $self->{table_status_bar} ||= $attr->{caption1} || '';
  $self->{table_export} ||= '';

  # Form fist row
  my $table_caption_size = 9;
  my $table_filters = '';
  if ($self->{table_status_bar}) {
    $table_caption_size = 3;
    $table_filters = qq{
      <div class='col-md-6 text-center'>
        <div class='btn-group btn-group-xs'>
          $self->{table_status_bar}
        </div>
      </div>
    }
  }

  my $table_export = '';
  if ($self->{table_export}) {$table_export = "<div class='btn-group'>" . $self->{table_export} . "</div>"}

  my $table_management_buttons = '';
  if ($self->{table_caption}) {
    $table_management_buttons = "<div class='btn-group'>" . $self->{table_caption} . "</div>";
  }

  my $extra_btn = '';
  if ($attr->{EXTRA_BTN}) {
    $extra_btn = "<div class='btn-group'>" . $attr->{EXTRA_BTN} . "</div>";
  }
  my $caption_icon = '';
  if ($attr->{caption_icon}) {
    $caption_icon = "<i class='" . $attr->{caption_icon} . "' style='font-size:18px; margin-right: 5px'></i>";
  }
  if ($attr->{caption} || $self->{table_caption}) {
    $self->{table} .= "<div class='box-header with-border hidden-print text-center'>
    <div class='row'>
      <div class='col-md-$table_caption_size pull-left text-left'>
        $caption_icon
        <h4 class='box-title table-caption'>$attr->{caption}</h4>
      </div>
      $table_filters
      <div class='col-md-3 pull-right text-right'>
        $extra_btn
        $table_management_buttons
      </div>
    </div>
    </div>";
  }

  $self->{table} .= qq{   <div class="$border box-body $table_responsive" id="p_$self->{ID}" align="left">
  <div class='row'>
      <div class='col-md-6 pull-left text-left'>
        $table_export
      </div>
      <div class='col-md-6 pull-right text-right'>
        <div class='hidden-print'>
            $pagination
         </div>
      </div>
    </div>
  <TABLE $table_class ID="$self->{ID}_">\n};

  $self->{pagination} = $pagination;

  # NOTICE: May be changed in DATA_TABLE if block ($attr->{title} -> $attr->{title_plain})
  if (defined($attr->{title})) {
    $SORT = $LIST_PARAMS{SORT};
    $self->{table} .= $self->table_title($SORT, $FORM{desc}, $PG, $attr->{title}, $attr->{qs});
    $self->{title_arr} = $attr->{title};
  }
  elsif (defined($attr->{title_plain})) {
    $self->{table} .= $self->table_title_plain($attr->{title_plain});
  }
  if ($attr->{summary}) {
    $self->{summary} = $self->table_summary($attr->{summary})
  }
  return $self;
}
#**********************************************************
=head2 table_summary($attr) - Add summary in footer box table

  Arguments:
   $attr     - summary content

  Results:
  $self->{summary} - summamry

=cut
#**********************************************************
sub table_summary {
  my ($self, $attr) = @_;
  if ($attr) {
    $self->{summary} .= $attr;
  }

  return $self->{summary};
}

#**********************************************************
=head2 addrows(@row) - Add rows to table

  Arguments:
    @row     - array of row elements

  Results:
    $self->{rows} - Formed row

=cut
#**********************************************************
sub addrow {
  my ($self, @row) = @_;

  my $css_class = '';

  if ($self->{rowcolor}) {
    if ($self->{rowcolor} =~ /^#/) {
      $css_class = " bgcolor='$self->{rowcolor}'";
    }
    else {
      $css_class = " class='$self->{rowcolor}'";
    }
  }

  my $extra = ($self->{extra}) ? ' ' . $self->{extra} : '';

  my $row_extra = '';
  if ($self->{row_extra}) {
    $row_extra = ' ' . $self->{row_extra};
  }

  $row_number++;
  $self->{rows} .= '<tr' . $css_class . $row_extra . '>'; # id='row_$row_number'>";

  for (my $num = 0; $num <= $#row; $num++) {
    my $val = $row[$num];
    $self->{rows} .= '<TD' . $extra . '>';
    if ($self->{sub_ref}) {
      my $sub_val = '';
      if (ref $val eq 'HASH') {
        while (my ($k, $v) = each %$val) {
          $sub_val .= "$k : " . ((defined($v)) ? $v : '') . $self->br();
        }
        $val = $sub_val if ($sub_val);
      }
    }
    $self->{rows} .= $val if (defined($val));
    $self->{rows} .= '</TD>';
  }

  $self->{rows} .= '</TR>' . "\n";
  return $self->{rows};
}

#**********************************************************
=head2 addtd(@row) - Add rows to table form td objects

  Arguments:
    @row     - array of td elements

  Returns:


=cut
#**********************************************************
sub addtd {
  my ($self, @row) = @_;

  my $css_class = '';
  if ($self->{rowcolor}) {
    if ($self->{rowcolor} =~ /^#/) {
      $css_class = "' bgcolor='$self->{rowcolor}'";
    }
    else {
      $css_class = $self->{rowcolor};
    }
  }

  my $row_extra = '';
  if ($self->{row_extra}) {
    $row_extra = ' ' . $self->{row_extra};
  }

  $row_number++;
  $self->{rows} .= '<tr class=\'' . $css_class . '\' ' . $row_extra . '>';
  foreach my $val (@row) {
    $self->{rows} .= $val;
  }

  $self->{rows} .= '</TR>' . "\n";

  return $self->{rows};
}

#**********************************************************
=head2 th($value, $attr) - Table TH element

  Arguments:
    $value   - value
    $attr    -
=cut
#**********************************************************
sub th {
  my ($self, $value, $attr) = @_;

  $attr->{TH} = 1;

  return $self->td($value, $attr);
}

#**********************************************************
=head2 td($value, $attr) - Table TD element

  Arguments:
    $value   - value
    $attr    -
      TH  - make  TH element

=cut
#**********************************************************
sub td {
  my (undef, $value, $attr) = @_;
  my $extra = '';

  if ($attr) {
    while (my ($k, $v) = each %$attr) {
      next if ($k eq 'TH');
      $extra .= " $k='$v'";
    }
  }

  my $td = '';

  if ($attr->{TH}) {
    $td = '<TH ' . $extra . '>';
    $td .= $value if (defined($value));
    $td .= '</TH>';
  }
  else {
    $td = '<TD ' . $extra . '>';
    $td .= $value if (defined($value));
    $td .= '</TD>';
  }

  return $td;
}

#**********************************************************
=head2 table_header($header_arr, $attr) - Table header function button

  Arguments
   $header_arr   - array of elements
   $attr         - Extra attributes
     SHOW_ONLY
     TABS        - SHow like tabs

  Returns:
    $header      - Header

  Examples:

    my @header_arr = (
      $lang{ALL}:index=$index&ALL_MSGS=1",
      $lang{NEXT}:index=$index&NEXT_MSGS=1"
    );

    $html->table_header(\@header_arr, {
      TABS      => $attr->{NO_UID} || $attr->{TABS},
      SHOW_ONLY => $attr->{SHOW_ONLY} || 5
    })

=cut
#**********************************************************
sub table_header {
  my $self = shift;
  my ($header_arr, $attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
    return '';
  }

  my $header = '';
  my $qs = $ENV{QUERY_STRING};
  $qs =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
  my $drop_down = '';

  my $elements_before_dropdown = $attr->{SHOW_ONLY} || 5;

  my $i = 0;
  foreach my $element (@{$header_arr}) {
    my ($name, $url, $extra) = split(/:/, $element, 3);
    my $active = '';
    if (!$url) {
      $active = 'active';
    }
    elsif ($url eq $qs) {
      $active = 'active';
    }
    else {
      my @url_argv = split(/&/, $url);
      my %params_hash = ();
      foreach my $line (@url_argv) {
        my ($k, $v) = split(/=/, $line);
        $params_hash{($k || '')} = $v;
      }

      if ($params_hash{index} && $FORM{index} && $params_hash{index} eq $FORM{index} && $attr->{USE_INDEX}) {
        $active = 'active';
      }
    }
    $active = 'active' if ($attr->{ACTIVE} && $attr->{ACTIVE} eq $url);
    my %url_params = ();

    if ($extra) {
      if ($extra =~ /MESSAGE=(.+)/) {
        $url_params{MESSAGE} = $1;
      }

      if ($extra =~ /class=(.+)/) {
        $url_params{class} = $1;
      }
    }

    if ($attr->{TABS} || $attr->{NAV}) {
      if ($url =~ /^#/) {
        $url_params{ex_params} = $extra;
        $url_params{GLOBAL_URL} = $url;
      }

      if ($attr->{SHOW_ONLY} && $attr->{SHOW_ONLY} <= $i) {
        if ($attr->{SHOW_ONLY} == $i) {
          $header .= $self->li($self->button($name, $url, \%url_params), { class => "$active" });
          $header .= qq{<li role="presentation" class="dropdown">};
          #$self->button($name, $url, { class => "btn btn-default $active" });
          $header .= qq{<a class="dropdown-toggle" data-toggle="dropdown" href="#" role="button" aria-haspopup="true" aria-expanded="false" ><span class="caret"></span></a>};
        }
        elsif ($attr->{SHOW_ONLY} < $i) {
          $drop_down .= $self->li($self->button($name, $url, \%url_params))
        }
      }
      else {
        $header .= $self->li($self->button($name, $url, \%url_params), { class => "$active" });
      }
    }
    elsif ($i == $elements_before_dropdown && $#{$header_arr} > $elements_before_dropdown) {
      $header .= $self->button($name, $url, { class => "btn btn-default $active" });
      $header .= "<button class='btn dropdown-toggle' data-toggle='dropdown'><span class='caret'></span></button>";
    }
    elsif ($i > $elements_before_dropdown) {
      $drop_down .= $self->li($self->button($name, $url, { class => '' }))
    }
    else {
      $header .= $self->button($name, $url, { class => "btn btn-default $active" });
    }

    $i++;
  }

  if ($drop_down) {
    $header .= "<ul class='dropdown-menu dropdown-menu-right'>$drop_down</ul>";
  }

  if ($attr->{TABS}) {
    $header = "<ul class='nav nav-tabs'>$header</ul>";
  }
  elsif ($attr->{NAV}) {
    $header = "<ul class='nav nav-pills'>$header</ul>";
  }
  elsif ($attr->{STAND_ALONE}) {
    $header = "<div class='btn-group btn-group-xs pull-middle' role='group'>$header</div>";
  }

  return $header;
}

#**********************************************************
=head2 table_title($sort, $desc, $pg, $caption, $qs, $attr) - Show table column  titles with word derectives

  Arguments:
   $sort      - sort column
   $desc      - DESC / ASC
   $pg        - page id
   $caption   - array off caption
   $qs        -

  Returns:
    $self->{table_title} - Table object

=cut
#**********************************************************
sub table_title {
  my $self = shift;
  my ($sort, $desc, $pg, $caption, $qs, $attr) = @_;
  my $op = '';

  if (!$qs) {
    $qs = '';
  }

  if (!$desc) {
    $desc = '';
  }

  if ($sort && $sort =~ /^(\d+)/) {
    $sort = $1;
  }
  else {
    $sort = 1;
  }

  $self->{table_title} = "<thead><tr>";
  my $i = 1;

  my $css_class = ($attr->{class}) ? " class='table_title'" : '';

  if ($self->{SELECT_ALL}) {
    if ($self->{MULTISELECT_ACTIONS}) {
      $self->{before_table} .= $self->table_actions_panel($self->{MULTISELECT_ACTIONS}, {
        HIDDEN => !$self->{SHOW_MULTISELECT_ACTIONS}
      });
    }
    $self->{SELECT_ALL} = $self->table_select_all_checkbox($self->{SELECT_ALL});
    $self->{table_title} .= "<th>$self->{SELECT_ALL}</th>";
  }

  foreach my $line (@$caption) {
    $self->{table_title} .= "<th$css_class> ";
    my $img = '';
    if ($line && $line ne '-') {
      if ($sort != $i) {

      }
      elsif ($desc && $desc eq 'DESC') {
        $img = 'glyphicon-sort-by-attributes-alt';
        $desc = '';
      }
      elsif ($sort > 0) {
        $img = 'glyphicon-sort-by-attributes';
        $desc = 'DESC';
      }

      if ($FORM{index}) {
        $op = "index=$FORM{index}";
      }
      elsif ($index) {
        $op = "index=$index";
      }

      $self->{table_title} .= $self->button($line, "$op$qs&pg=$pg&sort=$i&desc=$desc");
      $self->{table_title} .= " <span class='glyphicon $img'></span>" if ($img);
    }
    else {
      $self->{table_title} .= '';
    }

    $self->{table_title} .= "</th>\n";
    $i++;
  }
  $self->{table_title} .= "</TR></thead>\n";

  return $self->{table_title};
}

#**********************************************************
=head2 table_title($caption, $attr) - Show table column titles without sort element

  Arguments:
   $caption   - array off caption
   $attr      - Extra params

  Returns:
    $self->{table_title} - Table object

=cut
#**********************************************************
sub table_title_plain {
  my $self = shift;
  my ($caption, $attr) = @_;
  $self->{table_title} = "<thead><TR>";

  if ($self->{SELECT_ALL}) {
    if ($self->{MULTISELECT_ACTIONS}) {
      $self->{before_table} .= $self->table_actions_panel($self->{MULTISELECT_ACTIONS}, {
        HIDDEN => !$self->{SHOW_MULTISELECT_ACTIONS}
      });
    }
    my $checkbox_html = $self->table_select_all_checkbox($self->{SELECT_ALL});
    $self->{table_title} .= "<th>$checkbox_html</th>";
  }

  my $css_class = ($attr->{class}) ? " class='table_title'" : '';

  foreach my $line (@$caption) {
    $self->{table_title} .= "<TH$css_class>" . ($line || '') . "</TH>";
  }

  $self->{table_title} .= "</TR></thead>\n";

  return $self->{table_title};
}

#**********************************************************
=head2 table_select_all_checkbox($options_string) -

  Arguments:
     $options_string - "ignored:CHECKBOX_ID:ignored"

  Returns:
    string - html + javascript

=cut
#**********************************************************
sub table_select_all_checkbox {
  my ($self, $options_string) = @_;

  # my ($form_name, $element_name, $caption)
  my (undef, $element_name, undef) = split(/:/, $options_string);
  $element_name ||= 'IDS';
  return qq{
    <script>
      jQuery(function() {
        var checkboxes = jQuery('input:checkbox[id=\"$element_name\"]');
        var event_name = 'ontablecheckboxeschange.$element_name';
        if (typeof(window['Events']) !== 'undefined'){
          checkboxes.on('click', Events.emitAsCallback(event_name));
        }
        jQuery('input#$self->{ID}_checkAll').click(function () {
          checkboxes.prop('checked', this.checked)
          if (typeof(window['Events']) !== 'undefined'){Events.emit(event_name)}
        });
      });
    </script>
    <input type='checkbox' id='$self->{ID}_checkAll'/>
  };
}

#**********************************************************
=head2 table_actions_panel(\@actions, $attr) -

  Arguments:
     $actions - arr_ref
       action - hash_ref
         PARAM    - name of param to view
         ACTION   - URL where to send
         PARAM    - name for checkbox to look for (will honor only first action's PARAM)
         ICON     - show on hover
         TITLE    - show on hover
         COMMENTS -  ask about comments before send

     $attr
       HIDDEN - will hide actions panel by default and show when selected elements

  Returns:
    string - html + javascript

  Example:
    $table->table_actions_panel([
      {
        TITLE    => $lang{DEL},
        ICON     => 'glyphicon glyphicon-trash',
        ACTION   => "$SELF_URL?index=$index&del=1",
        PARAM    => "IDS",
        CLASS    => 'btn-danger',
        COMMENTS => "$lang{DEL}?"
      },
      {
        TITLE  => $lang{SEEN},
        ICON   => 'glyphicon glyphicon-ok',
        ACTION => "$SELF_URL?index=$index&seen=1",
        PARAM  => "IDS"
      }
    ]);

=cut
#**********************************************************
sub table_actions_panel {
  my ($self, $actions, $attr) = @_;

  $attr //= {};

  my $panel_param = '';
  my $hidden = '';

  my $form_action_button = sub {
    my ($action) = @_;

    return '' if (ref $action ne 'HASH' || !$action->{ACTION});
    my $action_param = '';
    if ($action->{PARAM} && !$panel_param) {
      $panel_param = $action->{PARAM};
      $action_param = $action->{PARAM}
        ? qq{data-param-name="$action->{PARAM}"}
        : '';
    }
    my $comments_param = $action->{COMMENTS}
      ? qq{data-comments="$action->{COMMENTS}"}
      : '';

    return $self->button($action->{TITLE}, $action->{ACTION}, {
      ICON           => $action->{ICON},
      NO_LINK_FORMER => 1,
      class          => 'btn btn-sm margin-bottom table-action-button ' . ($action->{CLASS} // 'btn-default'),
      ex_params      => qq{data-original-url="$action->{ACTION}" $action_param $comments_param}
    });
  };

  my @actions_html = map {$form_action_button->($_)} @$actions;

  if ($panel_param && $attr->{HIDDEN}) {
    $hidden = $attr->{HIDDEN};
  }

  my %action_panel_attr = (
    OUTPUT2RETURN => 1,
    class         => 'btn-group pull-left table-action-panel ',
    style         => ($hidden) ? 'display:none' : '',
  );

  if ($panel_param) {
    $action_panel_attr{'data-param'} = $panel_param;
  }

  my $actions_panel = $self->element('div', join('', @actions_html), \%action_panel_attr);

  return $actions_panel;
}

#**********************************************************
=head2 show($attr) - show table content

  Arguments:

    $attr    -
      EXPORT_CONTENT
      OUTPUT2RETURN
      NO_DEBUG_MARKERS

  Examples:

    $table->show();

=cut
#**********************************************************
sub show {
  my $self = shift;
  my ($attr) = shift;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
    return '';
  }

  $self->{show} = ($self->{before_table}
    ? "<div class='row'><div class='col-md-12 btn-toolbar'>$self->{before_table}</div></div>"
    : '')
    . $self->{table}
    . $self->{rows}
    . "</TABLE>\n";

  #  if ($self->{pagination}) {
  #    $self->{show} .= "<hr/><div class='row'><div class='col-md-3 pull-right text-right'>$self->{pagination}</div></div>"
  #  }
  $self->{show} .= (($self->{ID}) ? "</div>\n" : '</div>');

  if ($self->{summary} || $self->{pagination}) {
    $self->{show} .= $self->{summary};
  }
  $self->{show} .= '</div>';

  if (!$attr->{NO_DEBUG_MARKERS}) {
    $self->{show} = "<!-- $self->{ID} start table  -->"
      . $self->{show}
      . "<!-- $self->{ID} end table -->";
  }

  if ((defined($self->{NO_PRINT})) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{prototype}->{OUTPUT} .= $self->{show};
    $self->{show} = '';
  }

  return $self->{show};
}

#**********************************************************
=head2 link_former($text, $attr) - Format link

  Arguments:
    $text   -  Text for format
    $attr   -
       SKIP_SPACE - Skip space format

  Returns:
    $text  -  Formated text

=cut
#**********************************************************
sub link_former {
  my ($self) = shift;
  my ($text, $attr) = @_;

  return $text if (!$text);

  $text =~ s/ /+/g if (!$attr->{SKIP_SPACE});
  $text =~ s/&/&amp;/g;
  $text =~ s/>/&gt;/g;
  $text =~ s/</&lt;/g;
  $text =~ s/\"/&quot;/g;
  $text =~ s/\*/&#42;/g;
  #$text =~ s/\+/%2B/g;

  return $text;
}

#**********************************************************
=head2 img($img, $name, $attr) - show image

  Arguments:
    $img    - Img file
    $name   - Img name
    $attr   - Extra attr
      EX_PARAMS - Extra_params
      class

  Returns:
    Image object

=cut
#**********************************************************
sub img {
  my $self = shift;
  my ($img, $name, $attr) = @_;

  my $img_path = ($img =~ s/^://) ? "$IMG_PATH/" : '';

  my $class = $attr->{class} || 'img-responsive';
  my $ex_params = $attr->{EX_PARAMS} || '';

  return "<img alt='" . ($name || q{}) . "' src='$img_path$img' class='$class' $ex_params>";
}

#**********************************************************
=head2 button($name, $params, $attr) - Create link element

  Arguments:
    $name     - Link name
    $params   - Link params (url)
    $attr    -
      class          - Add class for element
      BUTTON         - Make link like button
      ID             -
      NO_LINK_FORMER -
      JAVASCRIPT     -
      GLOBAL_URL     - Global link
      ex_params      -
      LOAD_TO_MODAL  - loads $params link to modal instead of going to page
      MESSAGE        - Opens '#comments_add' modal to enter COMMENTS before submit
      CONFIRM        - Opens '#comments_add' modal without COMMENTS
      AJAX           - allow AJAX submit form. Will load result page as JSON, and if 'MESSAGE' found in result will show it.
                       This attribute treated as boolean,
                       but event with name "AJAX_SUBMIT.$attr->{AJAX}" will be triggered after submit
                       Expects $params have 'qindex' or 'get_index'.
      IMG            -
      TITLE          -
      SKIP_HREF      -
      ICON           - Img class <i class=".."></i>
      ADD_ICON       - Img class <i class=".."></i>. Instead of replacing button text will add icon to it
      COPY           - onclick button will copy text to clipboard


  Returns:

    String with element

  Examples:

    print $html->button('User', "index=15&UID=123", { class => 'btn btn-default' });

=cut
#**********************************************************
sub button {
  my $self = shift;
  my ($name, $params, $attr) = @_;
  my $ex_attr = ($attr->{ex_params}) ? " $attr->{ex_params}" : '';

  $params = ($attr->{GLOBAL_URL}) ? $attr->{GLOBAL_URL} : "$SELF_URL?" . (($params) ? $params : '');
  $params = $attr->{JAVASCRIPT} if (defined($attr->{JAVASCRIPT}));
  $params = $self->link_former($params) if (!$attr->{NO_LINK_FORMER} || !$attr->{GLOBAL_URL});

  if ($attr->{NEW_WINDOW}) {
    my $x = 640;
    my $y = 480;
    if ($attr->{NEW_WINDOW_SIZE}) {
      ($x, $y) = split(/:/, $attr->{NEW_WINDOW_SIZE});
    }
    $ex_attr .= " onclick=\"window.open('$attr->{NEW_WINDOW}', null,
            'toolbar=0,location=0,directories=0,status=1,menubar=0,'+
            'scrollbars=1,resizable=1,'+
            'width=$x, height=$y');\"";
    $params = '#';
  }

  if ($attr->{IMG_BUTTON}) {
    my $img_path = ($attr->{IMG} && $attr->{IMG} =~ s/^://) ? "$IMG_PATH/" : '';
    $name = "<img alt='$name' src='$img_path$attr->{IMG_BUTTON}'>";
  }
  elsif ($attr->{IMG}) {
    my $img_path = ($attr->{IMG} =~ s/^://) ? "$IMG_PATH/" : '';
    my $alt = ($attr->{IMG_ALT}) ? $attr->{IMG_ALT} : 'image';
    $name = "<img alt='$alt' src='$img_path$attr->{IMG}'> $name";
  }

  if ($attr->{COPY}) {

    $attr->{COPY} =~ s/'/\\\'/g;
    $attr->{COPY} =~ s/"/\\\'/g;
    $attr->{COPY} =~ s/\n/ /g;

    $ex_attr .= qq/ onclick="copyToBuffer('$attr->{COPY}', true)" /;;
    $attr->{SKIP_HREF} = 1;
  }

  if ($attr->{MESSAGE} || $attr->{CONFIRM}) {
    my $text_message = $attr->{MESSAGE} || $attr->{CONFIRM};
    my $comments_type = $attr->{CONFIRM} ? 'confirm' : '';
    my $ajax_params = $attr->{AJAX} || '';

    $text_message =~ s/'/\\\'/g;
    $text_message =~ s/"/\\\'/g;
    $text_message =~ s/\n/<br>/g;

    # title, link, attr_json;
    my $onclick_str = q/onClick="cancelEvent(event);/
      . qq/showCommentsModal('$text_message', '$params',/
      . qq/{ ajax: '$ajax_params', type : '$comments_type' } )"/;
    $ex_attr .= " $onclick_str ";
    $attr->{SKIP_HREF} = 1;
  }

  my $css_class = '';
  my $name_text = '';

  if ($attr->{BUTTON}) {
    if ($attr->{BUTTON} == 2) {
      $css_class = " class='btn btn-xs btn-primary'";
    }
    else {
      $css_class = " class='btn btn-default btn-xs'";
    }
  }
  elsif ($attr->{class}) {
    $css_class = $attr->{class};
    $name_text = $name if ($name && $name !~ /\'|\"/);

    if ($button_class_icons{$css_class}) {
      $name = "<span class='glyphicon $button_class_icons{$css_class}'></span>";
      $css_class = " class='hidden-print'";
    }
    elsif ($css_class eq 'payments') {
      $name = "<span class='glyphicon " . ($CONF->{CURRENCY_ICON} || 'glyphicon-euro') . "'></span>";
      $css_class = " class='hidden-print'";
    }
    elsif ($css_class =~ /show/) {
      $css_class = '';
      $name = "<span class='glyphicon glyphicon-list-alt'></span>";
    }
    elsif ($css_class =~ 'change') {
      $css_class = '';
      $name = "<span class='glyphicon glyphicon-pencil'></span>";
    }
    #elsif($class =~ 'print') {
    #  $class='';
    #  $name="<span class='glyphicon glyphicon-print'></span>";
    #}
    elsif ($css_class =~ 'off') {
      $css_class = '';
      $name = "<span class='glyphicon glyphicon-off text-danger'></span>";
    }
    elsif ($css_class =~ '_on') {
      $css_class = '';
      $name = "<span class='glyphicon glyphicon-off text-success'></span>";
    }
    elsif ($css_class =~ 'sendmail') {
      $css_class = '';
      $name = "<span class='glyphicon glyphicon-envelope'></span>";
    }
    else {
      $css_class = " class='$css_class'";
    }
  }

  my $title = '';
  if ($attr->{TITLE}) {
    $title = " title=\"$attr->{TITLE}\"";
  }
  elsif ($name_text) {
    $title = " title=\"$name_text\"";
  }
  elsif ($name && $name !~ /[<#]/) {
    $title = " title=\"$name\"";
  }

  if ($attr->{target}) {
    $ex_attr .= " target='$attr->{target}'";
  }

  my $id_val = ($attr->{ID}) ? "ID=\"$attr->{ID}\"" : '';
  my $href = ($attr->{SKIP_HREF}) ? '' : "href=\"$params\"";

  if ($attr->{ICON}) {
    $name = qq{<span class="$attr->{ICON}"></span>};
  }
  elsif ($attr->{ADD_ICON}) {
    $name = qq{<i class="$attr->{ADD_ICON}"></i>$name};
  }

  $name //= '';

  if ($attr->{LOAD_TO_MODAL}) {
    my $load_func = ($attr->{LOAD_TO_MODAL} eq 'raw') ? 'loadRawToModal' : 'loadToModal';
    return qq{<a $css_class onclick="cancelEvent(event);$load_func('$params')" $ex_attr $id_val $title>$name</a>};
  }

  return "<a $title $css_class $href $ex_attr $id_val>$name</a>";
}

#**********************************************************
=head2 message($type, $caption, $message, $attr) - Show message box

  Arguments:
    $type     - Box type:
       info
       err
       warn
    $caption  - Box caption
    $message  - Message
    $attr
      ID    - Message ID
      EXTRA - Extra text
      OUTPUT2RETURN

  Examples:

   $html->message('err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}");

=cut
#**********************************************************
sub message {
  my $self = shift;
  my ($type, $caption, $message, $attr) = @_;

  $caption .= ': ' . $attr->{ID} if ($attr->{ID});
  my $icon = '';
  my $class = '';

  if ($type eq 'err' || $type eq 'error' || $type eq 'danger') {
    $class = 'callout-danger';
    $icon = "<span class='glyphicon glyphicon-remove-sign'></span>";
  }
  elsif ($type eq 'info') {
    $class = 'callout-success';
    $icon = "<span class='glyphicon glyphicon-ok-sign'></span>";
  }
  elsif ($type eq 'warn' || $type eq 'warning') {
    $class = 'callout-warning';
    $icon = "<span class='glyphicon glyphicon-exclamation-sign'></span>";
  }
  else {
    $class = 'callout-' . $type;
  }

  if (!defined($message)) {
    $message = '';
  }
  else {
    $message =~ s/\n/<br>/g;
  }

  my $output = qq{
    <div class="callout $class text-left">
  };

  if ($caption) {
    $output .= "<h4>$icon $caption</h4>";
  }
  else {
    #$output .= $icon;
  }

  $output .= $message;

  if ($attr->{EXTRA}) {
    $output .= $attr->{EXTRA};
  }

  $output .= '</div>';

  if ($attr->{OUTPUT2RETURN}) {
    return $output;
  }
  elsif ($self->{NO_PRINT}) {
    $self->{OUTPUT} .= $output;
    return $output;
  }
  else {
    print $output;
  }

  return;
}

#**********************************************************
=head2 color_mark($text, $color) - Hightlight text

  Arguments:
    $text    - Input text
    $color   - Color or css style
      code - Mark for code text

  Returns:
    Mark text

  Examples:

    print color_mark('hello world', 'bg-danger');

=cut
#**********************************************************
sub color_mark {
  my $self = shift;
  my ($text, $color) = @_;

  my $output = '';

  if ($color && $color eq 'code') {
    $output = "<code>$text</code>";
  }
  elsif ($color && $color !~ m/[0-9A-F]{3,6}/i) {
    $output = "<p class='$color'>$text</p>";
  }
  elsif ($color) {
    $output = "<font color=$color>" . ($text || q{}) . "</font>";
  }
  elsif (!$color && $text && $text =~ /(.+):([#A-F0-9]{3,10})$/i) {
    $output = "<font color=$2>$1</font>";
  }
  else {
    $output = $text || q{};
  }

  return $output;
}

#**********************************************************
=head2 pages($count, $argument, $attr) - Make pages and count total records

  Argumenst:
    $count     - Show pages elemnts
    $argument  - Arguments
    $attr      - Extra atrtr
     SHOW_FULL_LIST

  Returns:
    Formed pages

=cut
#**********************************************************
sub pages {
  my $self = shift;
  my ($count, $argument, $attr) = @_;

  return '' if ($self->{MAX_ROWS});

  if (defined($attr->{recs_on_page})) {
    $PAGE_ROWS = $attr->{recs_on_page};
  }

  if ($PG !~ /^\d+$/) {
    $PG = 0;
  }

  my $begin = 0;

  $self->{pages} = '';
  $begin = ($PG - $PAGE_ROWS * 3 < 0) ? 0 : $PG - $PAGE_ROWS * 3;

  $argument .= "&sort=$FORM{sort}" if ($FORM{sort});
  $argument .= "&desc=$FORM{desc}" if ($FORM{desc});

  return $self->{pages} if ($count < $PAGE_ROWS);

  for (my $i = $begin; ($i <= $count && $i < $PG + $PAGE_ROWS * 5); $i += $PAGE_ROWS) {
    $self->{pages} .= (($i == $PG) ? $self->li($self->button(($i == 0 ? 1 : $i), "$argument&pg=$i"), { class => 'active' }) : $self->li($self->button(($i == 0 ? 1 : $i), "$argument&pg=$i")));
  }

  my $_GO2PAGE = ($self->{HTML}{LANG}{GO2PAGE}) ? $self->{HTML}{LANG}{GO2PAGE} : '';
  if ($self->{SHOW_FULL_LIST}) {
    $self->{pages} .= $self->element('li',
      $self->button($self->element('span', '', { class => "fa fa-arrows-v" }),
        "$argument&PAGE_ROWS=100000")
    );
  }

  return qq{
  <div class='hidden-print'>
    <ul class='pagination pagination-sm'><li><a data-toggle='modal' data-target='#gotopage'>
      <span class="glyphicon glyphicon-chevron-down"></span></a></li>$self->{pages}
    </ul>
  </div>


<div class="modal fade" id="gotopage" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-sm">
        <div class="modal-content">
            <div class="modal-header text-center">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
                 <h4 class="modal-title">$_GO2PAGE ( 1 .. $count ):</h4>
            </div>
            <div class="modal-body text-left">
            <div class='row'>
              <div class='col-md-9'>
                <input class='form-control' id='pagevalue' type='text'  size='9' maxlength=8/>
              </div>
              <div class='col-md-3'>
                <button type="button"  class="btn btn-primary pull-right" data-dismiss="modal" onclick="checkval('index.cgi?$argument&pg=')">OK</button>
              </div>
            </div>
      </div>
        </div>
    </div>
</div>
};

}

#**********************************************************
=head2 date_fld2($base_name, $attr) - Make data field

  Arguments:
    $base_name  - Field name
    $attr       - Extra rguments
      FORM_NAME  - Form name
      DATE       - Date
      TIME       - Time
      NO_DEFAULT_DATE - Dont show default date. (by Default date cur date)
      MONTHES    - Monthes names array of names
      WEEK_DAYS  - Week days name
      TABINDEX   - Form tab index
      NEXT_DAY   - Show next day (Tommorow)

  Returns:
    data field element

  Examples:
    print $html->date_fld2('ACTIVATE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1 }) ],

=cut
#**********************************************************
sub date_fld2 {
  my $self = shift;
  my ($base_name, $attr) = @_;

  my $form_name = ($attr->{FORM_NAME}) ? "form='$attr->{FORM_NAME}' " : '';
  my $date = '';
  my $size = 10;

  my ($year, $month, $day);

  if ($attr->{DATE}) {
    $date = $attr->{DATE};
    if ($attr->{TIME}) {
      $date .= ' ' . $attr->{TIME};
      $size = 20;
    }
  }
  elsif ($FORM{$base_name}) {
    $date = $FORM{$base_name};
    $self->{$base_name} = $date;
  }
  # Default Date
  elsif (!$attr->{NO_DEFAULT_DATE}) {
    my ($mday, $mon, $curyear) = (localtime(time + (($attr->{NEXT_DAY}) ? 86400 : 0)))[3, 4, 5];
    $month = $mon + 1;
    $year = $curyear + 1900;
    $day = $mday;

    if ($base_name =~ /to/i) {
      $day = ($month != 2 ? (($month % 2) ^ ($month > 7)) + 30 : (!($year % 400) || !($year % 4) && ($year % 25) ? 29 : 28));
    }
    elsif ($base_name =~ /from/i && !$attr->{NEXT_DAY}) {
      $day = 1;
    }
    $date = sprintf("%d-%.2d-%.2d", $year, $month, $day);
    $self->{$base_name} = $date;
  }

  my $tabindex = ($attr->{TABINDEX}) ? "tabindex=$attr->{TABINDEX}" : '';

  my $result = qq{<input type=text name='$base_name' value='$date' size=$size class='form-control datepicker' ID='$base_name' $form_name$tabindex>};

  return $result;
}

#**********************************************************
=head2 log_print($level, $text) - Print log

=cut
#**********************************************************
sub log_print {
  my $self = shift;
  my ($level, $text) = @_;
  my %log_levels;

  if ($self->{debug} && $self->{debug} < $log_levels{$level}) {
    return 0;
  }

  print <<"[END]";
<TABLE width="640" border="0" cellpadding="0" cellspacing="0">
<tr><TD bgcolor="#00000">
<TABLE width="100%" border="0" cellpadding="2" cellspacing="1">
<tr><TD bgcolor="FFFFFF">

<TABLE width="100%">
<tr bgcolor="$_COLORS[3]"><th>
$level
</th></TR>
<tr><TD>
$text
</TD></TR>
</TABLE>

</TD></TR>
</TABLE>
</TD></TR>
</TABLE>
[END]

  return 1;
}

#**********************************************************
=head2 tpl_show($tpl, $variables_ref, $attr) - Show templates

  Arguments:

    $tpl             - Template text
    $variables_ref   - Variables hash_ref
    $attr            - Extra atributes
      EXPORT_CONTENT
      SKIP_DEBUG_MARKERS - do not show "<!-- START: >" markers
      OUTPUT2RETURN
      SKIP_VARS
      SKIP_QUOTE
      TPL         - Template Name after defined variable $tpl ignored
      MODULE      - Module
      ID

  Examples:

    print $html->tpl_show(templates('form_user'), { LOGIN => 'Pupkin' });

=cut
#**********************************************************
sub tpl_show {
  my $self = shift;
  my ($tpl, $variables_ref, $attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne ($attr->{ID} || q{})) {
    return '';
  }

  if ($attr->{TPL}) {
    $tpl = $self->get_tpl($attr->{TPL}, $attr->{MODULE});

    if ($attr->{HELP}) {
      my $help_template = $self->get_tpl($attr->{TPL} . '_help', $attr->{MODULE});
      if ($help_template && $help_template !~ /^No such/) {
        $tpl .= $self->element('div', $help_template, {
          class => 'help-template hidden',
          style => 'display : none;'
        });
      }
    }
  }

  if (!$attr->{SOURCE} && $tpl) {
    while ($tpl =~ /\%(\w{1,60})(\=?)([A-Za-z0-9\_\.\/\\\]\[:\-]{0,50})\%/g) {
      my $var = $1;
      my $delimiter = $2;
      my $default = $3;

      #    if ($var =~ /$\{exec:.+\}$/) {
      #      my $exec = $1;
      #      if ($exec !~ /$\/usr/abills\/\misc\/ /);
      #      my $exec_content = system("$1");
      #      $tpl =~ s/\%$var\%/$exec_content/g;
      #     }
      #    els

      if (defined($variables_ref->{$var})) {
        $variables_ref->{$var} =~ s/\%$var\%//g;
      }
      else {
        $variables_ref->{$var} = q{};
      }

      if ($attr->{SKIP_VARS} && $attr->{SKIP_VARS} =~ /$var/) {
      }
      elsif ($default && $default =~ /expr:(.*)/) {
        my @expr_arr = split(/\//, $1, 2);
        if ($#expr_arr > 0) {
          $variables_ref->{$var} =~ s/$expr_arr[0]/$expr_arr[1]/g;
        }
        $default =~ s/\//\\\//g;
        $default =~ s/\[/\\\[/g;
        $default =~ s/\]/\\\]/g;
        $tpl =~ s/\%$var$delimiter$default%/$variables_ref->{$var}/g;
      }
      elsif (defined($variables_ref->{$var})) {
        if ($variables_ref->{$var} !~ /\=\'|\' | \'/ && !$attr->{SKIP_QUOTE}) {
          $variables_ref->{$var} =~ s/\'/&rsquo;/g;
        }
        $tpl =~ s/\%$var$delimiter$default%/$variables_ref->{$var}/g;
      }
      else {
        $tpl =~ s/\%$var$delimiter$default\%/$default/g;
      }
    }
  }

  if ($CONF->{WEB_DEBUG} && !$attr->{SKIP_DEBUG_MARKERS}) {
    $tpl = "<!--START: " . ($attr->{ID} ? $attr->{ID} : '') . " -->\n $tpl\n<!--END: " . ($attr->{ID} ? $attr->{ID} : '') . "-->\n";
  }

  if ($attr->{OUTPUT2RETURN}) {
    return $tpl;
  }
  elsif ($attr->{MAIN}) {
    $self->{OUTPUT} .= $tpl;
    return $tpl;
  }
  elsif ($attr->{notprint} || $self->{NO_PRINT}) {
    $self->{OUTPUT} .= $tpl;
    return $tpl;
  }
  else {
    if ($self->{CHANGE_TPLS} && $attr->{ID}) {
      $tpl .= "<div class='bg-warning'>[<a href='$SELF_URL?index=91&ID=$attr->{ID}&create=:$attr->{ID}'>change templates</a>]</div>\n";
    }

    print $tpl;
  }
}

#**********************************************************
=head2 get_tpl($tpl, $module)

  Arguments:
    pdf
    CHECK_ONLY
    DEBUG
    SUFIX

=cut
#**********************************************************
sub get_tpl {
  my ($self, $tpl, $module, $attr) = @_;

  my $sufix = ($attr->{pdf} || $FORM{pdf}) ? '.pdf' : '.tpl';
  $tpl .= '_' . $attr->{SUFIX} if ($attr->{SUFIX});

  my $domain_path = $self->{admin};
  my $admin;

  if ($self->{admin}) {
    $admin = $self->{admin};
  }

  $domain_path = '';
  if ($admin->{DOMAIN_ID}) {
    $domain_path = "$admin->{DOMAIN_ID}/";
  }
  elsif ($FORM{DOMAIN_ID}) {
    $domain_path = "$FORM{DOMAIN_ID}/";
  }

  our $Bin;
  use FindBin '$Bin';

  start:
  my @search_paths = (
    # Custom templates with domain and language
    $Bin . '/../Abills/templates/' . $domain_path . $module . '_' . $tpl . "_$self->{language}" . $sufix,
    '../Abills/templates/' . $domain_path . $module . '_' . $tpl . "_$self->{language}" . $sufix,
    '../../Abills/templates/' . $domain_path . $module . '_' . $tpl . "_$self->{language}" . $sufix,

    # Custom templates with domain
    '../../Abills/templates/' . $domain_path . $module . '_' . $tpl . $sufix,
    '../Abills/templates/' . $domain_path . $module . '_' . $tpl . $sufix,

    # Custom templates with domain or language
    $Bin . '/../Abills/templates/' . $domain_path . $module . '_' . $tpl . $sufix,
    $Bin . '/../Abills/templates/' . $module . '_' . $tpl . "_$self->{language}" . $sufix
  );

  if ($FORM{NAS_GID}) {
    unshift(@search_paths,
      $Bin . '/../Abills/templates/' . $domain_path . '/' . $FORM{NAS_GID} . '/' . $module . '_' . $tpl . "_$self->{language}" . $sufix,
      $Bin . '/../Abills/templates/' . $domain_path . '/' . $FORM{NAS_GID} . '/' . $module . '_' . $tpl . $sufix,
    );
  }

  foreach my $result_template (@search_paths) {
    if ($attr->{DEBUG}) {
      print $result_template . "\n";
    }

    if (-f $result_template) {
      if ($attr->{CHECK_ONLY}) {
        return 1;
      }
      else {
        #TODO: generalize similar code
        if ($attr->{pdf} || $FORM{pdf}) {
          return $result_template;
        }
        return tpl_content($result_template)
      }
    }
  }

  if ($attr->{CHECK_ONLY}) {
    return 0;
  }

  if ($module) {
    $tpl = "modules/$module/templates/$tpl";
  }

  foreach my $prefix ('../', @INC) {
    my $realfilename = "$prefix/Abills/$tpl$sufix";

    if ($attr->{DEBUG}) {
      print $realfilename . "\n";
    }

    if (-f $realfilename) {
      #TODO: generalize similar code
      if ($attr->{pdf} || $FORM{pdf}) {
        return $realfilename;
      }
      return tpl_content($realfilename)
    }
  }

  if ($attr->{SUFIX}) {
    $tpl =~ /\/([a-z0-9\_\.\-]+)$/i;
    $tpl = $1;
    $tpl =~ s/_$attr->{SUFIX}$//;
    delete $attr->{SUFIX};
    goto start;
  }

  return "No such module template [$tpl]\n";
}

#**********************************************************
=head2 tpl_content($filename, $attr)

=cut
#**********************************************************
sub tpl_content {
  my ($filename) = @_;
  my $tpl_content = '';

  open(my $fh, '<', $filename) || die "Can't open file '$filename' $!";
  while (<$fh>) {
    if (/\$/) {
      my $res = $_;
      if ($res) {
        $res =~ s/\_\{(\w+)\}\_/$lang->{$1}/sg;
        $res =~ s/\{secretkey\}//g;
        $res =~ s/\{dbpasswd\}//g;
        $res = eval " \"$res\" " if ($res !~ /\`/);
        $tpl_content .= $res || q{};
      }
    }
    else {
      # Old
      s/\_\{(\w+)\}\_/$lang->{$1}/sg;
      $tpl_content .= $_;
      #        # New check speed
      #        my $row = $_;
      #        if ($row =~ /\_\{(\w+)\}\_/sg) {
      #          my $text = $1;
      #          if($lang{$text}) {
      #            $row =~ s/\_\{(\w+)\}\_/$lang{$text}/sg;
      #          }
      #          else {
      #            $row =~ s/\_\{(\w+)\}\_/$text/sg;
      #          }
      #        }
      #        $tpl_content .= $row;
    }
  }
  close($fh);

  return $tpl_content;
}

#**********************************************************
=head2 test() - test function

  Show input variables
    %FORM     - Form
    %COOKIES  - Cookies
    %ENV      - Enviropment

  Arguments:
    $attr
      HEADER  - show content type header

  Result:
    TRUE or FALSE

  Examples:

    $html->test();

=cut
#**********************************************************
sub test {
  #my $self = shift;
  my ($attr) = @_;

  if ($attr->{HEADER}) {
    print "Content-Type: text/html\n\n";
  }
  elsif (!$CONF->{WEB_DEBUG} || $CONF->{WEB_DEBUG} < 2) {
    return 0;
  }

  delete $FORM{__BUFFER};
  my $output = '<br/>FORM : {<br/>';
  while (my ($k, $v) = each %FORM) {
    $output .= "&nbsp&nbsp$k : " . ($v || q{''}) . ",<br/>";
  }
  $output =~ s/,$//g;

  $output .= "}<br/>COOKIES : {<br/>";
  while (my ($k, $v) = each %COOKIES) {
    $output .= "&nbsp&nbsp$k : " . ($v || q{''}) . ",<br/>";
  }
  $output =~ s/,$//g;
  $output .= "}\n";

  my $output_html = $output;
  $output =~ s/\&nbsp|\<br\/\>//gm;
  print qq{<div class='main-footer' id=test><p ><a href='#' data-tooltip="$output_html" data-tooltip-position='top' class='noprint'>Debug</a> $output </p></div>\n};

  return 1;
}

#**********************************************************
=head2 letters_list($attr); - Show letter pagination

  Arguments:
    $attr
      EXPR

  Returns:
    leter object

=cut
#**********************************************************
sub letters_list {
  my $self = shift;
  my ($attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
    return '';
  }

  $pages_qs = $attr->{pages_qs} = ($attr->{pages_qs}) ? $attr->{pages_qs} : '';
  $pages_qs =~ s/letter=\S+//g;
  my @alphabet = ('0-9', 'a-z');

  if ($attr->{EXPR}) {
    push @alphabet, $attr->{EXPR};
  }

  my $letters = $self->li($self->button('All', "index=$index"), { class => (!$FORM{letter}) ? 'active' : undef });

  foreach my $line (@alphabet) {
    my $first = '';
    my $last = '';
    if ($line =~ /(\d)\-(\d)/) {
      $first = $1;
      $last = $2;
    }
    else {
      $line =~ /(\S)-(\S)/;
      $first = ord($1);
      $last = ord($2);
    }

    for (my $i = $first; $i <= $last; $i++) {
      my $l = ($i > 10) ? chr($i) : $i;
      my $active = '';
      if ($FORM{letter} && $FORM{letter} eq $l) {
        $active = 'active';
      }
      $letters .= $self->li($self->button($l, "index=$index&letter=$l" . ($pages_qs || '')), { class => $active });
    }
  }

  if (defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $letters;
    return '';
  }
  else {
    return "
      <div class='rules hidden-print'>
        <ul class='pagination pagination-sm'>$letters</ul>
      </div>\n";
  }
}

#**********************************************************
=head2 make_charts($attr) - Make different charts

   If given only one series and X_TEXT as YYYY-MM, will build columned compare chart

   Arguments:
     $attr
       DATA    - Data hash
         [object_name:value]
            value - Array_ref of values

       PERIOD  - Graphic period: week, year, month, hour, pie
       TYPES   - Object type: LINE, COLUMN, AREA, SCATTER, PIE
       X_TEXT  - Text for X
       DEBUG   - Enable debug for function
       SKIP_COMPARE - Skip compare mode
       SINGLE_COMPARE -  Single cross year compare. Use column name

   Result:
     TRUE or FALSE

=cut
#**********************************************************
sub make_charts {
  my $self = shift;
  my ($attr) = @_;

  my $result = '';

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne ($attr->{ID} || q{})) {
    return '';
  }

  my %CHART_OPTIONS = ();
  my $DATA = $attr->{DATA};
  my @result_arr = ();
  my $debug = $attr->{DEBUG} || 0;

  my $single_compare_key = $attr->{SINGLE_COMPARE} || $FORM{SINGLE_COMPARE} || 0;

  my @series_names = keys(%{$DATA});

  if ($single_compare_key) {
    $DATA = { $single_compare_key => $DATA->{$single_compare_key} };
  }

  my $series_count = scalar keys(%{$DATA});

  my $categories = $attr->{X_TEXT};
  my $chart_types = $attr->{TYPES};

  my $chart_categories = undef;

  $result .= "<hr>Series count: $series_count" if ($debug);

  if ($attr->{PERIOD}) {
    $CHART_OPTIONS{chart_period} = $attr->{PERIOD};

    # Pass days in month to display month chart correctly
    if ($attr->{PERIOD} eq 'month_stats') {
      $CHART_OPTIONS{days_in_month} = $attr->{DAYS} || 31;
    }
  }

  my %compare = ();
  while (my ($series_name, $series_values) = each %{$DATA}) {
    %compare = ();

    # Remove first array value (to start it from 1 not 0 index)
    shift(@{$series_values});

    for (my $i = 0; $i <= $#{$series_values}; $i++) {
      $series_values->[$i] ||= '0';

      # if text YYYY-MM make compare hash
      if (!$attr->{SKIP_COMPARE} && $categories && $categories->[$i] && $categories->[$i] =~ /^(\d{4})\-(\d{2})$/) {
        my $year = $1;
        my $month = $2;
        $compare{$month}->{$year} = $series_values->[$i];
      }
    }
    # Compare hash action
    if (scalar %compare > 1) {
      my @val_new = ();
      $CHART_OPTIONS{compare_enable} = 1;
      foreach my $month (sort keys (%compare)) {
        foreach my $year (sort keys (%{$compare{$month}})) {
          push @val_new, $compare{$month}->{$year};
        }
        $series_values = \@val_new;
      }
    }

    my $values_text = join('", "', @{$series_values});
    my $chart_type = ($chart_types->{$series_name}) ? lc $chart_types->{$series_name} : 'line';
    push @result_arr, qq{["$series_name", "$chart_type", ["$values_text"] ]};
  }

  my $compare_x_text = '';
  #my @compare_data_columns = ();
  if ($CHART_OPTIONS{compare_enable}) {
    if ($series_count != 1) {
      my @compare_x_text_arr = ();
      foreach my $month (sort keys (%compare)) {
        push @compare_x_text_arr, qq/
          { name: "$month",
            categories: ["/ . join('", "', sort keys (%{$compare{$month}}))
          . qq/" ]\n } /;
      }

      $compare_x_text = join(',', @compare_x_text_arr);
    }
    else {
      my %year_hash = ('undef' =>
        [ undef, "'01'", "'02'", "'03'", "'04'", "'05'", "'06'", "'07'", "'08'", "'09'", "'10'", "'11'", "'12'" ]);
      my @years_arr = keys %{$compare{'01'}};

      foreach my $month (sort keys (%compare)) {
        foreach my $year (@years_arr) {
          $year_hash{$year}->[int($month)] = $compare{$month}->{$year} || 'null';
        }
      }

      my @result_rows = ();
      push @result_rows, "[null, " . join(', ', @{$year_hash{undef}}[1. . 12]) . ']';

      foreach my $year (sort keys %year_hash) {
        if ($year eq 'undef') {
          next;
        }

        push @result_rows, "['" . $year . "'," . join(', ', @{$year_hash{$year}}[1. . 12]) . ']';
      }

      my $compare_js_params = join(', ', @result_rows);

      $compare_x_text = $compare_js_params;
    }
  }

  $result .= "<hr>Compare categories: " . ($compare_x_text || q{}) if ($debug);

  if ($categories) {
    $CHART_OPTIONS{compare_single} = ($CHART_OPTIONS{compare_enable} && ($series_count == 1));

    if ($compare_x_text) {
      $chart_categories = $compare_x_text;
    }
    else {
      for (my $i = 0; $i <= $#{$categories}; $i++) {
        if (!defined($categories->[$i])) {
          $categories->[$i] = '';
        }
      }
      $chart_categories = "'" . (($#{$categories} > -1) ? join("','", @{$categories}) : '') . "'";
    }
  }

  if (!$self->{CHARTS_HIGHCHARTS_LOADED}) {
    $result .= "<script type='text/javascript' src='/styles/default_adm/js/charts/highcharts.js'></script>";
    $self->{CHARTS_HIGHCHARTS_LOADED} = 1;
  }

  if ($CHART_OPTIONS{compare_enable}) {
    if ($CHART_OPTIONS{compare_single}) {
      my $compare_key_select = $self->form_select(
        'SINGLE_COMPARE',
        {
          SEL_ARRAY     => \@series_names,
          SELECTED      => $single_compare_key,
          FORM_ID       => 'report_panel',
          EX_PARAMS     => ' onchange="document.report_panel.submit()" ',
          OUTPUT2RETURN => 1
        }
      );

      $result .= $self->element('div', $compare_key_select, { class => 'col-md-6 pull-right' });
    }
    $result .= "<script src='/styles/default_adm/js/charts/highcharts-grouped.js'></script>";
  }

  if (!$self->{CHARTS_LOADED}) {
    $result .= qq{
      <script type='text/javascript' src='/styles/default_adm/js/charts/charts.js'></script>
    };
    $self->{CHARTS_LOADED} = 1;
  }

  my @chars_arr = ('a' ... 'z');
  $CHART_OPTIONS{chart_id} = 'chart_' . join('', map {$chars_arr[int(rand($#chars_arr))]} (0 ... 10));
  $result .= qq{
    <div id='$CHART_OPTIONS{chart_id}' style='width: 100%; height: 100%; margin-bottom: 10px'></div>
  };

  my $chart_vars = join(",\n", @result_arr);

  my @chart_options_arr = ();
  foreach my $option_name (keys %CHART_OPTIONS) {
    push(@chart_options_arr, qq{ "$option_name" : "$CHART_OPTIONS{$option_name}" }) if ($CHART_OPTIONS{$option_name});
  }
  my $chart_options_str = join(',', @chart_options_arr);

  $chart_categories //= '';
  $result .= qq{<script> initChart([ $chart_categories ], [ $chart_vars ], { $chart_options_str });</script>};

  unless ($attr->{OUTPUT2RETURN}) {
    print $result;
  }

  return $result;
}
#**********************************************************
=head2 make_charts_simple($attr) - Make different charts

   If given only one series and X_TEXT as YYYY-MM, will build columned compare chart

   Arguments:
     $attr
       DATA    - Data hash
         [object_name:value]
            value - Array_ref of values
       TYPES    - Object type: LINE, COLUMN, AREA, SCATTER, PIE
       X_TEXT   - Text for X
       Y_TITLE  - Title for Y
       GRAPH_ID - <div> id
       TITLE    - Graph Title
   Result:
     TRUE or FALSE

=cut
#**********************************************************
sub make_charts_simple {
  my $self = shift;
  my ($attr) = @_;
  my $result = '';

  my $DATA = $attr->{DATA};
  my $categories = $attr->{X_TEXT} || '';
  my $title_y = $attr->{Y_TITLE} || '';
  my $graph_title = $attr->{TITLE} || '';
  my $chart_types = $attr->{TYPES};
  my $dimension = $attr->{DIMENSION} || '';

  my $graph_id = $attr->{GRAPH_ID} || do {
    my @chars_arr = ('a' ... 'z');
    'chart_' . join('', map {$chars_arr[int(rand($#chars_arr))]} (0 ... 10));
  };

  $title_y = "$title_y ($dimension)" if ($dimension);
  my $categories_vars = join('", "', @{$categories});

  my @series_arr = ();
  foreach my $series_name (sort keys %{$DATA}) {
    my $series_values = $DATA->{$series_name};
    for (my $i = 0; $i <= $#{$series_values}; $i++) {
      if (!$series_values->[$i]) {
        $series_values->[$i] = 'null';
      }
    }
    my $values_text = join(', ', @{$series_values});
    my $chart_type = ($chart_types->{$series_name}) ? lc $chart_types->{$series_name} : 'line';
    push @series_arr, "{ name: \"$series_name\", type: \"$chart_type\", data: [$values_text] }";
  }
  my $series_vars = join(",\n", @series_arr);
  $result .= qq{
    <div id='$graph_id' style='width: 100%; height: 100%; margin-bottom: 10px'></div>
  };

  if (!$self->{CHARTS_HIGHCHARTS_LOADED}) {
    $result .= "<script type='text/javascript' src='/styles/default_adm/js/charts/highcharts.js'></script>";
    $self->{CHARTS_HIGHCHARTS_LOADED} = 1;
  }

  $result .= qq{
    <script>
      \$(function () {
        Highcharts.theme = { colors: ["#f45b5b", "#8085e9", "#8d4654", "#7798BF", "#aaeeee", "#ff0066", "#eeaaee", "#55BF3B", "#DF5353", "#7798BF", "#aaeeee"]};
        Highcharts.setOptions(Highcharts.theme);
        \$('#$graph_id').highcharts({
          chart: {
            type: 'line',
          },
          title: {
            text: '$graph_title'
          },
          xAxis: {
            categories: ["$categories_vars"]
          },
          yAxis: {
            title: {
              text: '$title_y'
            },
          },
          tooltip: {
            valueSuffix: ' $dimension'
          },
          series: [$series_vars]
        });
      });
    </script>
  };

  unless ($attr->{OUTPUT2RETURN}) {
    print $result;
  }

  return $result;
}
#**********************************************************
=head2 make_charts3($attr) - Make different charts

   If given only one series and X_TEXT as YYYY-MM, will build columned compare chart

   Arguments:
     $name - header of charts
     $type - type of chart: Line, Area, Bar, Donut
     $attr
       element - chart id
       data    - Data array of hashes
         [:value]
            value - Array_ref of values
       xkeys   - Keys for X
       labels  - Name of data sourse
       postUnits   - Name of units (Mb/s etc)
   Result:
     string

=cut
#**********************************************************
sub make_charts3 {
  my $self = shift;
  my ($name, $type, $attr) = @_;

  $attr->{element} = "graph_" . $attr->{element};
  my $ATTR = JSON->new->indent->encode($attr);

  my $chart = $self->element('div', undef, { id => $attr->{element}, class => 'graph', style => 'height: 250px' });
  my $result = $self->element('div', $self->element('h5', $name, { class => 'text-center' }) . $chart, { class => 'span6' });

  $result .= qq(
  	<link rel='stylesheet' type='text/css' href='/styles/$self->{HTML_STYLE}/plugins/morris/morris.css'>
    <script type='text/javascript' src='/styles/default_adm/js/raphael.min.js'></script>
	  <script type='text/javascript' src='/styles/$self->{HTML_STYLE}/plugins/morris/morris.min.js'></script>
    <script>
	    Morris.$type($ATTR);
	  </script> );

  return $result;
}
#**********************************************************
=head2 br($attr) - Make HTML <br> element (Break line)

  Examples:

   $html->br();

=cut
#**********************************************************
sub br {
  #my $self = shift;

  return '<br/>';
}

#**********************************************************
=head2 li($item, $attr) - Make HTML <li> element (list item)

  Arguments:

    $item     - Text
    $attr     - $attr
      class   - element class
      id      - element id

  Examples:

   $html->li('list item');

=cut
#**********************************************************
sub li {
  my $self = shift;
  my ($item, $attr) = @_;

  my $class = ($attr->{class}) ? ' class=\'' . $attr->{class} . '\'' : '';
  my $id_val = ($attr->{id}) ? ' id=\'' . $attr->{id} . '\'' : '';

  return '<li' . $class . $id_val . '>' . $item . '</li>';
}

#**********************************************************
=head2 pre($message, $attr) - Make HTML <pre> element

  Arguments:

    $text     - Text
    $attr     - $attr

  Examples:

   $html->per('Preformated text');

=cut
#**********************************************************
sub pre {
  my $self = shift;
  my ($text, $attr) = @_;

  if (!defined($text)) {
    $text = q{};
  }
  my $output = qq{<pre>\n$text\n</pre>};

  if ($attr->{OUTPUT2RETURN}) {
    return $output;
  }
  elsif ($self->{NO_PRINT}) {
    $self->{OUTPUT} .= $output;
    return $output;
  }
  else {
    print $output;
  }
}

#**********************************************************
=head2 b($message, $attr) - Make HTML <b> element (bold text)

  Arguments:

    $text     - Text
    $attr     - $attr

  Examples:

   $html->b('BOLD text');

=cut
#**********************************************************
sub b {
  my $self = shift;
  my ($text) = @_;

  my $output = (defined($text)) ? "<b>$text</b>" : '';

  return $output;
}

#**********************************************************
=head2 element($name, $value, $attr) - Create HTML element

  Arguments:
    $name      - Element name
    $value     - value
    $attr      - Extra params
      class

  Returns:
    return result string

  Examples:

    $html->element('div', 'Hello word', { class => "btn btn-default" });

=cut
#**********************************************************
sub element {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  my $params = '';
  if (ref $attr eq 'HASH') {
    while (my ($k, $v) = each %$attr) {
      next if ($k eq 'OUTPUT2RETURN');
      $params .= "$k=\"" . ($v || q{}) . "\" ";
    }
  }

  $self->{FORM_INPUT} = "<$name $params>" . ($value // q{}) . "</$name>";

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#***********************************************************
=head2 badge($text, $attr) - Make HTML badge

  Arguments:

    $text     - Text
    $attr     - $attr
      TYPE    - bootstrap badge class

  Examples:

    $html->badge('Badge text');

=cut
#***********************************************************
sub badge {
  my $self = shift;
  my ($text, $attr) = @_;

  my $type = ($attr->{TYPE}) ? "$attr->{TYPE}" : 'bg-gray-active';

  return "<span class='label $type'>" . ($text || '') . "</span>";
}

#***********************************************************
=head2 progress_bar($attr) - Make progress bar

  Arguments:

    $attr            - $attr
      TOTAL          -
      COMPLETE       -
      TEXT           -
      PERCENT_TYPE   - Progress bar with bage.If active you can use other arguments:
      MAX            - Max value
      ACTIVE         - Animation of progress bar
      COLOR          - Dinamic color:
                       1.ADAPTIVE- color is taken from precent of MAX ;
                       1.MAX_COLOR- color is taken from precent of TOTAL;

  Examples:

    print $html->progress_bar({
          TEXT     => 'Show memmory',
          TOTAL    => 12,
          COMPLETE => 16,
          COLOR    => ADAPTIVE,
          ACTIVE   => 1
        });

=cut
#***********************************************************
sub progress_bar {
  my $self = shift;
  my ($attr) = @_;

  my $complete = 0;
  my $one_percent = 0;

  if ($attr->{TOTAL} && $attr->{TOTAL} =~ /\d+/ && $attr->{COMPLETE}) {
    $one_percent = $attr->{TOTAL} / 100;
    $attr->{COMPLETE} =~ s/\%//;
    $complete = ($one_percent > 0) ? sprintf('%.f', $attr->{COMPLETE} / $one_percent) : 0;
  }
  my ($first_step, $second_step, $third_step) = ($complete, 0, 0);

  if ($complete > 50) {
    $first_step = 50;
    $second_step = $complete - 50;

    if ($second_step > 30) {
      $second_step = 30;
      $third_step = $complete - 80;
    }
  }
  my %progress_bar;
  my $text_color = ($complete < 10) ? 'text-success' : '';
  my $ret = '';
  my $bar_color = '';
  my $bage_color = '';
  my $color_val = $attr->{MAX} ? $attr->{MAX} / 100 : 0;
  my $active = $attr->{ACTIVE} ? 'active' : '';
  my $bage_text;
  if ($attr->{PERCENT_TYPE}) {

    if (defined($attr->{BAGE_TEXT})) {
      $bage_text = $attr->{BAGE_TEXT};
    }
    else {
      $bage_text = $complete . '%';
    }

    if ($attr->{COLOR} eq 'MAX_COLOR') {
      if ($complete < 25) {
        $bar_color = 'red';
        $bage_color = 'red';
      }
      elsif ($complete < 50) {
        $bar_color = 'yellow';
        $bage_color = 'yellow';
      }
      elsif ($complete < 75) {
        $bar_color = 'blue';
        $bage_color = 'blue';
      }
      else {
        $bar_color = 'green';
        $bage_color = 'green';
      }
    }
    elsif ($attr->{COLOR} eq 'ADAPTIVE') {
      if ($attr->{COMPLETE} < $color_val * 25) {
        $bar_color = 'red';
        $bage_color = 'red';
      }
      elsif ($attr->{COMPLETE} < $color_val * 50) {
        $bar_color = 'yellow';
        $bage_color = 'yellow';
      }
      elsif ($attr->{COMPLETE} < $color_val * 75) {
        $bar_color = 'blue';
        $bage_color = 'blue';
      }
      else {
        $bar_color = 'green';
        $bage_color = 'green';
      }
    }
    else {
      $bar_color = $attr->{COLOR} ? $attr->{COLOR} : 'green';
      $bage_color = $attr->{COLOR} ? $attr->{COLOR} : 'green';
    }

    $ret = qq{<div class="row">
                <div class="col-md-8">
                 <div class="progress progress-xs progress-striped $active">
                   <div class="progress-bar progress-bar-$bar_color" style="width: $complete%"></div>
                 </div>
                </div>
                <div class="col-md-3"><span class="badge bg-$bage_color">$bage_text</span>
               </div>
              </div>
    };
  }
  else {
    $bar_color = $attr->{COLOR} ? $attr->{COLOR} : 'green';
    $bage_color = $attr->{COLOR} ? $attr->{COLOR} : 'green';
    $ret = qq{
   <div class="progress-bar progress-bar-success" style="width: $first_step%">
     <p class="$text_color"> $attr->{TEXT} </p> <span class="sr-only">$first_step% Complete (success)</span>
   </div> };

    if ($second_step) {
      $ret .= qq{<div class="progress-bar progress-bar-warning progress-bar-striped" style="width: $second_step%">
      <span class="sr-only">$second_step% Complete (warning) </span>
    </div>};
    }

    if ($third_step) {
      $ret .= qq{ <div class="progress-bar progress-bar-danger" style="width: $third_step%">
      <span class="sr-only">$third_step% Complete (danger)</span>
    </div> };
    }

    $ret = qq{<div class="progress"> $ret </div> };
    return $ret;

  }
  return $ret;

}

#***********************************************************
=head2 short_info_panels_row($panels, $attr) - Nice looking element to show some simple information presented as number

  If you don't provide $panels->{LINK} it will not have a box-footer.
  If you don't provide $panels->{SIZE} it will have 100% width.

  Also you can provide $html->button element to $attr->{TEXT}.

ARGUMENTS:
  $panels - hash_ref or array_ref of hash_ref
   MANDATORY
    * ID     - unique value, used to apply CSS rules (can not start from a number)
    * NUMBER - number
    * TEXT   - text that describes number (Can be a link)
    * ICON   - an identifying part of glyphicon name (e.g for 'glyphicon glyphicon-plus' it will be 'plus')

   OPTIONAL
    * SIZE   - size in columns if you are too lazy to form a template;
    * LINK   - $html->button formed link element where user can see full information
    * COLOR  - by default it will be got from AColorPalette, but you can pass here HEX, text, RGB or RGBA color
    * TEXT_COLOR - text color (including icon)

  $attr
    * OUTPUT2RETURN

EXAMPLES:

 $html->short_info_panels_row(
   {
     ID     => mk_unique_value(10),
     NUMBER => 42,
     ICON   => 'globe',
     TEXT   => $html->button("The Answer", undef, { GLOBAL_URL => 'https://uk.wikipedia.org/wiki/%D0%92%D1%96%D0%B4%D0%BF%D0%BE%D0%B2%D1%96%D0%B4%D1%8C_%D0%BD%D0%B0_%D0%BF%D0%B8%D1%82%D0%B0%D0%BD%D0%BD%D1%8F_%D0%B6%D0%B8%D1%82%D1%82%D1%8F,_%D0%92%D1%81%D0%B5%D1%81%D0%B2%D1%96%D1%82%D1%83_%D1%96_%D0%B2%D0%B7%D0%B0%D0%B3%D0%B0%D0%BB%D1%96', OUTPUT2RETURN => 1 }),
     COLOR  => 'purple',
     SIZE   => 3
   }
 );

 Row of panels with footer and returned result

  my $panel = $html->short_info_panels_row(
  [
   {
     ID     => mk_unique_value(10),
     NUMBER => 42,
     TEXT   => "The Answer",
     ICON   => 'globe',
     LINK   => $html->button("$lang{FULL}", undef, { GLOBAL_URL => 'https://uk.wikipedia.org/wiki/%D0%92%D1%96%D0%B4%D0%BF%D0%BE%D0%B2%D1%96%D0%B4%D1%8C_%D0%BD%D0%B0_%D0%BF%D0%B8%D1%82%D0%B0%D0%BD%D0%BD%D1%8F_%D0%B6%D0%B8%D1%82%D1%82%D1%8F,_%D0%92%D1%81%D0%B5%D1%81%D0%B2%D1%96%D1%82%D1%83_%D1%96_%D0%B2%D0%B7%D0%B0%D0%B3%D0%B0%D0%BB%D1%96', OUTPUT2RETURN => 1 }),
     COLOR  => 'purple',
     SIZE   => 3
   },
   {
     ID     => mk_unique_value(10),
     NUMBER => 42,
     ICON   => 'globe',
     TEXT   => $html->button("The Answer", undef, { GLOBAL_URL => 'https://uk.wikipedia.org/wiki/%D0%92%D1%96%D0%B4%D0%BF%D0%BE%D0%B2%D1%96%D0%B4%D1%8C_%D0%BD%D0%B0_%D0%BF%D0%B8%D1%82%D0%B0%D0%BD%D0%BD%D1%8F_%D0%B6%D0%B8%D1%82%D1%82%D1%8F,_%D0%92%D1%81%D0%B5%D1%81%D0%B2%D1%96%D1%82%D1%83_%D1%96_%D0%B2%D0%B7%D0%B0%D0%B3%D0%B0%D0%BB%D1%96', OUTPUT2RETURN => 1 }),
     COLOR  => 'purple',
     SIZE   => 3
   }
  ],
   {
     OUTPUT2RETURN =>1
   }
 );

=cut
#***********************************************************
sub short_info_panels_row {
  my $self = shift;
  my ($panels, $attr) = @_;

  unless (ref $panels eq 'ARRAY') {
    $panels = [ $panels ];
  }

  #system colors
  my $system_colors = 'PRIMARY, INFO, SUCCESS, WARNING, DEFAULT, DANGER';

  my $result = "<div class='row'>";
  foreach my $panel (@$panels) {
    my $number = ($panel->{NUMBER} && $panel->{NUMBER} ne '') ? $panel->{NUMBER} : '';
    my $number_size = $panel->{NUMBER_SIZE} || '20px';
    my $text = $panel->{TEXT} || '';

    my $icon = $panel->{ICON} || '';
    my $link = $panel->{LINK} || '';
    my $color = $panel->{COLOR} || '';
    my $size = $panel->{SIZE} || '';

    my $id = "short_info_panel_" . $panel->{ID};

    #color definition
    my $text_color = ($panel->{TEXT_COLOR}) ? "color: $panel->{TEXT_COLOR};" : 'color: white;';

    my $color_definition = '';

    if ($color eq '' || $system_colors !~ uc $color) {
      if ($color ne '') { #define CSS rules for given color
        $color_definition = qq{
          <style>
            #$id {
              border-color : $color;
            }

            #$id .summary a {
              $text_color
            }

            #$id > .box-heading {
              border-color: $color;
              $text_color
              background-color: $color;
            }
          </style>
        };
      }
      else { #define JavaScript that will aply color
        $color_definition = qq{
          <script>
            jQuery(function(){
              var id = '$id';

              var color = aColorPalette.getNextColorRGBA(0.4);
              var text_color = '$text_color' || '';

              var color_definition = '' +
              '<style> ' +
              '  #' + id + ' {border-color : ' + color + ';} ' +
              '  #' + id + ' .summary a {' + text_color + '} ' +
              '  #' + id + ' > .box-heading {border-color: ' + color + '; ' + text_color + ' background-color: ' + color + ';} ' +
              '</style> ';

              jQuery('#' + id).prepend(color_definition);
            });
          </script>
        };
      }
    }

    my $footer = '';
    if ($panel->{LINK}) {
      $footer = qq{
        <div class='box-footer row'>
          <div class='pull-left'>$link</div>
        </div>
      };
    }

    my $columns = '';
    if ($icon) {
      $columns = qq{
            <div class="col-xs-3">
              <i class="glyphicon glyphicon-$icon fa-5x"></i>
            </div>
            <div class="col-xs-9 text-right">
              <div style="font-size: $number_size">$number</div>
              <div class='summary'>$text</div>
            </div>
      };
    }
    else {
      $columns = qq{
            <div class="col-xs-12 text-center">
              <div style="font-size: $number_size">$number</div>
              <div class='summary'>$text</div>
            </div>
      };
    }

    my $panel_html = qq{

      $color_definition
      <div class="panel box-$color" id="$id">
        <div class="box-heading">
          <div class="row">
            $columns
          </div>
        </div>
        $footer
      </div>
    };

    if ($size ne '') {
      $panel_html = "<div class='col-md-$size'>$panel_html</div>";
    }
    $result .= $panel_html;
  }

  $result .= "</div>";

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $result;
    return $result;
  }

  print $result;
  return 1;
}


#**********************************************************
=head2 tree_menu($list, $name, $attr)

  Builds a collapsible tree menu from hashref that contains array_refs as values

  Arguments:
    $list - array_ref of hash_ref (list from DB with a COLS_NAME attr)
    $name - Name for First level of menu
    $attr
      PARENT_KEY      - hash_key for an item's  parent id. Default to PARENT_ID
      ID_KEY          - hash_key for an item's id key. Default to 'ID'

      LABEL_KEY        - hash_key for an item's label key. Default to 'NAME'
      VALUE_KEY       - hash_key for an item's value key. Default to 'ID'
      ROOT_VALUE      - Value of root (highest ieararchy level parent). Default is '';

      PARENTNESS_HASH - if  you need more complicated structure pass your own ierarchy for building menu
      LEVEL_ID_KEYS    - arr_ref of ID_KEY  for a level
      LEVEL_LABEL_KEYS - arr_ref of LABEL_KEY  for a level
      LEVEL_VALUE_KEYS - arr_ref of VALUE_KEY for a level

      LEVELS   - number of levels to display. Default is to count it automatically
      CHECKBOX - boolean, will build a checkbox at last level
      NAME     - string, name for a checkbox

      COL_SIZE - width of menu. Default is 3 if LEVELS <= 6, and 6 otherwise

  Returns:
    HTML code for a menu

  Example:

   my $list = [

    { ID => '1',  NAME => 'Level1_1', VALUE => '1' , PRENT_ID => '0'},
    { ID => '2',  NAME => 'Level1_2', VALUE => '2' , PRENT_ID => '0'},
    { ID => '3',  NAME => 'Level1_3', VALUE => '3' , PRENT_ID => '0'},
    { ID => '4',  NAME => 'Level1_4', VALUE => '4' , PRENT_ID => '0'},

    { ID => '5',  NAME => 'Level2_1', VALUE => '5' , PRENT_ID => '1'},
    { ID => '6',  NAME => 'Level2_2', VALUE => '6' , PRENT_ID => '2'},
    { ID => '7',  NAME => 'Level2_3', VALUE => '7' , PRENT_ID => '3'},
    { ID => '8',  NAME => 'Level2_4', VALUE => '8' , PRENT_ID => '4'},

    { ID => '10', NAME => 'Level3_1', VALUE => '10' , PRENT_ID => '8'},
    { ID => '11', NAME => 'Level3_2', VALUE => '11' , PRENT_ID => '8'},
    { ID => '12', NAME => 'Level3_3', VALUE => '12' , PRENT_ID => '8'},
    { ID => '13', NAME => 'Level3_4', VALUE => '13' , PRENT_ID => '8'}

  ];

  print $html->tree_menu( $list, 'Menu', { PARENT_KEY => 'PRENT_ID', LABEL_KEY => 'NAME' } );


=cut
#**********************************************************
sub tree_menu {
  shift;

  require Abills::HTML_Tree;
  Abills::HTML_Tree->import();

  my $tree_builder = Abills::HTML_Tree->new();

  return $tree_builder->tree_menu(@_);
}

#**********************************************************
=head2 build_parentness_tree($array, $attr) - build hash_ref that represents ieararchy for list (Parents and children);

  Arguments:
    $array - DB list (array of hash_ref). To build parentness we need only PARENT_ID and ID, so you can pass oly this part
    $attr
      PARENT_KEY - hash_key for an item's  parent id. Default to P
      ID_KEY     - hash_key for an item's id key. Default to 'ID'
      ROOT_VALUE - Value of root (highest ieararchy level parent). Default is '';

  Returns:
    hash_ref that represents parentness

  Example:
    If given this:
      my $list = [
        { ID => 1, PARENT_ID = '0',  ... },
        { ID => 2, PARENT_ID = 1,   ... },
        { ID => 3, PARENT_ID = 2,   ... },
        { ID => 4, PARENT_ID = 2,   ... },
      ]

    Will return this:
      $result =
      {
      '1' =>
        {
          '2' =>
          {
            '3' => '',
            '4' => ''
          }
        }
      };

=cut
#**********************************************************
sub build_parentness_tree {
  shift;

  require Abills::HTML_Tree;
  Abills::HTML_Tree->import();

  my $tree_builder = Abills::HTML_Tree->new();

  return $tree_builder->build_parentness_tree(@_);
}

#**********************************************************
=head2 fetch() - Fetch cache data

=cut
#**********************************************************
sub fetch {
  my $self = shift;

  return $self;
}

#**********************************************************
=head2 form_datepicker($name, $value, $attr) -

  Arguments:
    $name, $value, $attr -

  Returns:
    html

  Examples:
    $html->form_datepicker('DATE', '0000-00-00')

=cut
#**********************************************************
sub form_datepicker {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  my $input = $self->form_input($name, $value, { class => 'form-control datepicker', %{$attr // {}} });
  my $addon = $self->element('div', '<i class="fa fa-calendar"></i>', { class => 'input-group-addon', %{$attr // {}} });

  return $self->element('div', $input . $addon, { class => 'input-group', %{$attr // {}} });
}

#**********************************************************
=head2 form_daterangepicker($attr) - Adapter to JavaScript Date Range Picker

  Arguments:
    $attr
      NAME      - string, if specified 'NAME1/NAME2', will return as two separate fields ($FORM{NAME1}, $FORM{NAME2}).
      FORM_NAME - form id for input elements
      WITH_TIME - will allow to choose time range

  Returns:
    html

  Examples:
    $html->form_daterangepicker({
      NAME      => 'FROM_DATE/TO_DATE',
      FORM_NAME => 'report_panel',
      VALUE     => $attr->{DATE} || $FORM{'FROM_DATE_TO_DATE'},
      WITH_TIME => $attr->{TIME_FORM} || 0
    })

=cut
#**********************************************************
sub form_daterangepicker {
  my ($self) = shift;
  my ($attr) = @_;

  my $name = $attr->{NAME} || return '';
  my $value = $attr->{VALUE} || $FORM{$name} || '';

  my @names = split('/', $name, 2);
  my $hidden_inputs = '';
  my $has_hidden = 0;

  our $DATE;
  $DATE //= POSIX::strftime("%Y-%m-%d", localtime(time));

  my $date = $DATE;
  if ($attr->{THIS_MONTH}) {
    my ($year, $month) = split('-', $DATE);
    require Abills::Base;
    Abills::Base->import('days_in_month');
    my $last_day = days_in_month({ DATE => $DATE });
    $date = "$year-$month-01/$year-$month-$last_day";
    $value = $date;
  }

  if (scalar @names == 2) {
    my @values = split('/', $value, 2);

    $hidden_inputs =
      $self->form_input($names[0], $FORM{$names[0]} || $values[0] || $date,
        { TYPE => 'hidden', FORM_NAME => $attr->{FORM_NAME}, OUTPUT2RETURN => 1 })
        . $self->form_input($names[1], $FORM{$names[1]} || $values[1] || $date,
        { TYPE => 'hidden', FORM_NAME => $attr->{FORM_NAME}, OUTPUT2RETURN => 1 });

    $name = $names[0] . '_' . $names[1];

    if ($FORM{$names[0]} && $FORM{$names[1]}) {
      $value = "$FORM{$names[0]}/$FORM{$names[1]}";
    }
    else {
      $value = $value || "$date/$date";
    }

    $has_hidden = 1;
  }

  my $time_options = ($attr->{WITH_TIME}) ? ' with-time' : '';
  my $input = $self->form_input($name, $value, {
    class         => "form-control date_range_picker $time_options",
    FORM_NAME     => $attr->{FORM_NAME},
    EX_PARAMS     => (($has_hidden)
      ? " data-name1='$names[0]' data-name2='$names[1]' data-has-hidden='1' "
      : ''
    ) . ($attr->{EX_PARAMS} ? ' ' . $attr->{EX_PARAMS} . ' ' : ''),
    OUTPUT2RETURN => 1
  });

  my $addon = $self->element('div', '<i class="fa fa-calendar"></i>', { class => 'input-group-addon', OUTPUT2RETURN => 1 });

  return $self->element('div', $hidden_inputs . $input . $addon, { class => 'input-group', OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 form_timepicker($name, $value, $attr)

  Arguments:
    $name
    $value
    $attr
      EX_PARAMS
      FORM_ID   - Main form ID

  Returns:
    html

=cut
#**********************************************************
sub form_timepicker {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  my $input = $self->form_input($name, $value, { class => 'form-control timepicker', %{$attr // {}} });
  my $addon = $self->element('div', '<i class="fa fa-clock-o"></i>', { class => 'input-group-addon' });

  return $self->element('div', $input . $addon, { class => 'input-group bootstrap-timepicker', %{$attr ? $attr : {}} });
}

#**********************************************************
=head2 form_datetimepicker2($name, $attr)

  Arguments:
    $name
      $attr
         EX_PARAMS - Hash of parameters (See docs http://eonasdan.github.io/bootstrap-datetimepicker/Options/ )
  Returns:
    html

=cut
#**********************************************************

sub form_datetimepicker2 {
  my ($self, $name, $attr) = @_;
  my $result;

  $attr->{EX_PARAMS}->{locale} = $self->{content_language};
  $attr->{EX_PARAMS}->{maxDate} = localtime(time);
  $attr->{EX_PARAMS}->{format} = 'YYYY-MM-DD HH:mm' if !$attr->{EX_PARAMS}->{format};

  my $ATTR = JSON->new->encode($attr->{EX_PARAMS});

  if ($attr->{ICON}) {
    $result = qq(
                  <div class='input-group date' id='$name'>
                      <input type='text' class='form-control' name='$name' />
                      <span class='input-group-addon'>
                          <span class='glyphicon glyphicon-calendar'></span>
                      </span>
                  </div>
  				);
  }
  else {
    $result = $self->form_input($name, $name);
  }
  $result .= qq(
          <script type="text/javascript">
              \$(function () {
                  \$('#$name').datetimepicker($ATTR);
              });
          </script>
  );

  return $result;
}

#**********************************************************
=head2 form_datetimepicker($name, $value, $attr) - simple datetime chooser

  It consists of 3 elements: hidden input, and visible date and time inputs
  When form submits date and time parts are concatenated and written to hidden input

  Arguments:
    $name
    $value
    $attr
      EX_PARAMS
      FORM_ID   - Main form ID

  Returns:
    html

=cut
#**********************************************************
sub form_datetimepicker {
  my ($self, $name, $value, $attr) = @_;

  #  my $hidden_input = $self->form_input($name, $value, { TYPE => 'hidden', EX_PARAMS => 'class="datetimepicker-hidden"' });
  #
  #  my ($date, $time) = split(' ', $value, 2) if ($value);
  #  my $date_input = $self->element('div', $self->form_datepicker($name . '_DATE', $date ), {class => 'col-md-6', %{ $attr // {} } });
  #  my $time_input = $self->element('div', $self->form_timepicker($name . '_TIME', $time ), {class => 'col-md-6', %{ $attr // {} } });
  #
  #  return $self->element('div', $hidden_input . $date_input . $time_input, { class => 'datetimepicker' });

  my $result = '';

  my %datetimepicker_options = (
    sideBySide       => \1,
    showClose        => \1,
    keepInvalid      => \1,
    allowInputToggle => \1
  );

  $datetimepicker_options{locale} = $self->{content_language} || 'en';
  $datetimepicker_options{format} = 'YYYY-MM-DD HH:mm' if !$attr->{FORMAT};

  if ($attr->{PAST_ONLY}) {
    $datetimepicker_options{maxDate} = localtime(time);
  }

  my $input = $self->form_input($name, $value, { class => 'form-control', %{$attr // {}} });

  if ($attr->{ICON}) {
    $input = qq(
                  <div class='input-group' id='$name'>
                      $input
                      <span class='input-group-addon'>
                          <span class='glyphicon glyphicon-calendar'></span>
                      </span>
                  </div>
  				);
  }

  my $event_scripts = '';
  if ($attr->{TIME_HIDDEN_ID}) {
    $event_scripts .= qq{
      jQuery('#$name').on('dp.change', function(e){
        if (e.date){
          jQuery('#$attr->{TIME_HIDDEN_ID}').val(e.date.format('h:m'));
        }
      });
    };
  };
  if ($attr->{DATE_HIDDEN_ID}) {
    $event_scripts .= qq{
      jQuery('#$name').on('dp.change', function(e){
        if (e.date){
          jQuery('#$attr->{DATE_HIDDEN_ID}').val(e.date.format('Y-M-D'));
        }
      });
    };
  };

  my $options_json = JSON->new->encode(\%datetimepicker_options);
  $result .= qq(
          $input
          <script type="text/javascript">
              \$(function () {
                  \$('#$name').datetimepicker($options_json);
                  $event_scripts
              });
          </script>
  );

  return $result;
}


#**********************************************************
=head2 reminder($header, $message, $attr) - shows callout message at top of page

  Reminder is hidden, so later JS find and move it to the top of the page

  Arguments:
    $header  - string, header of callout block
    $message - string, text for callout
    $attr    - hash_ref
      class         - string, color for reminder block, one of 'info', 'warning', 'danger'. default 'info'
      VISIBLE       - do not hide callout block
      OUTPUT2RETURN - return string instead of printing

  Returns:
    string - HTML

=cut
#**********************************************************
sub reminder {
  my ($self, $header, $message, $attr) = @_;
  $attr //= {};

  my $color_class = $attr->{class} || 'info';
  $color_class .= $attr->{VISIBLE} ? '' : ' callout-to-top hidden';
  $header //= '';
  $message //= '';

  my $result = "<div class='col-md-12'><div class='callout callout-$color_class lead'>";
  $result .= "<h4>$header</h4>" if ($header);
  $result .= "<p>$message</p>" if ($message);
  $result .= "</div></div>";

  if ($attr->{OUTPUT2RETURN}) {
    return $result;
  }

  print $result;
}

#**********************************************************
=head2 redirect($url) - redirects user to given URL

  Arguments :
    $url  - where user should be redirected
    $attr - $hash_ref
      MESSAGE      - string, will be icluded in message
      MESSAGE_HTML - your custom html to show to user, MESSAGE is ignored
      WAIT         - time given to user to read message (3 if not given, and MESSAGE|MESSAGE_HTML is present)

  Returns :
    1, but you should normally avoid doing any operations after calling redirect()

=cut
#**********************************************************
sub redirect {
  my ($self, $url, $attr) = @_;

  my $wait = $attr->{WAIT} || 0;
  my $message = '';
  if ($attr->{MESSAGE} || $attr->{MESSAGE_HTML}) {

    $message = $attr->{MESSAGE_HTML} || $self->message('info', '',
      $attr->{MESSAGE} . $self->button(' Redirect ', '', { GLOBAL_URL => $url }),
      { OUTPUT2RETURN => 1 }
    );
    $wait ||= 3;
  }

  if (!$self->{HEADERS_SENT}) {

    # Instant redirect via Location
    if (!$wait && !$message) {
      print "Refresh: 0;url=$url\n\n";
      #      print "Location: $url\n\n";
      return 1;
    }

    # If have to wait or show message first, use Refresh
    print "Refresh: " . ($wait || '0') . ";url=$url\n";
    print "Content-Type: text/html\n\n";

    # Load bootstrap
    print "<link rel='stylesheet' type='text/css' href='/styles/default_adm/css/bootstrap.min.css'>\n";

    # Show message
    print "<body>
    <div class='container'>
      <div class='page-header'>
        $message
      </div>
    </div>
    </body>";

    return 1;
  }

  print "
    $message

    <!-- Emulate header -->
    <meta http-equiv='refresh' content='$wait;URL=$url'/>

    <!-- JavaScript fallback -->
    <script>setTimeout($wait, function(){ location.replace('$url') })</script>
  ";

  return 1;
}

#**********************************************************
=head2 form_blocks_togglable($first_block, $second_block) - wraps two given blocks in HTML for toggle

  Arguments:
    $first_block  - string, HTML
    $second_block - string, HTML
    $attr         - hash_ref

      ICON1       - icon for
      ICON2       -

  Returns:
    string - HTML

=cut
#**********************************************************
sub form_blocks_togglable {
  my ($self, $first_block, $second_block, $attr) = @_;

  my $icon1 = $attr->{ICON1} // 'glyphicon glyphicon-plus';
  my $icon2 = $attr->{ICON2} // 'glyphicon glyphicon-th-list';

  my $rnd_str = sub {join '', @_[ map {rand @_} 1 .. shift ]};

  my $id1 = $rnd_str->(8, 'a' .. 'z');
  my $id2 = $rnd_str->(8, 'a' .. 'z');

  return qq{
    <div id='$id1'>
      <div class='input-group'>
        $first_block
        <div class='input-group-addon'>
          <a data-toggle='block'>
            <span class='$icon1'></span>
          </a>
        </div>
      </div>
    </div>

    <div id='$id2' style='display: none'>
      <div class='input-group'>
        $second_block
        <div class='input-group-addon'>
          <a data-toggle='block'>
            <span class='$icon2'></span>
          </a>
        </div>
      </div>
    </div>
    <script>
      jQuery(function(){
        new BlockToggler('$id1', '$id2');
      })
    </script>
  };

}

#**********************************************************
=head2 charts_js() -

  Arguments:
    $attr:
      TYPE          - chart type(bar, line, pie), STRING
      X_LABELS      - labels for X axis, ARRAY
      DATA          - chart data, HASH
      TITLE         - title for chart
      BACKGROUND_COLORS - colors for each key in DATA, HASH
      OUTPUT2RETURN - return result, BOOL
      FILL          - turn off filling under line(only for LINE chart), BOOL
      HIDE_LEGEND   - do not show chart legend
      For chart with customer axes and options:
        DATA_CHART    - Chart data with data? label and other(see Example for custom chart or manual)
        OPTIONS       - Options for chart(see Example for custom chart or manual)
        manual and options - https://www.chartjs.org/docs/latest/axes/
  Returns:
    $result - chart with data
  Examples:
    BAR:
    my $chart = $html->chart({
        TYPE        => 'bar',
        X_LABELS    => ['June', 'July', 'Augst', "September", 'October', 'November'],
        DATA        => {
          'WATER' => [10, 12, 8,14,20,3],
          'GAS'   => [12,15,4,11,12,21],
          'LIGHT' => [10,15,55,22,11,4]
        },
        BACKGROUND_COLORS => {
          'WATER' => 'rgba(2, 99, 2, 0.5)',
          'GAS'   => 'rgba(255, 99, 255, 0.5)',
          'LIGHT' => 'rgba(5, 99, 132, 0.5)'
        },
        OUTPUT2RETURN => 1,
    });

    LINE:
    my $chart3 = $html->chart({
        TYPE        => 'line',
        X_LABELS    => ['June', 'July', 'Augst', "September", 'October', 'November'],
        DATA        => {
          'WATER' => [10, 12, 8,14,20,3],
          'GAS'   => [12,15,4,11,12,21],
          'LIGHT' => [10,15,55,22,11,4]
        },
        BACKGROUND_COLORS => {
          'WATER' => '#12f123',
          GAS => '#999999',
          'LIGHT' => '#ff11ff'
        },
        FILL => 'false',
        OUTPUT2RETURN => 1,
    });

    PIE:
    my $chart2 = $html->chart({
        TYPE        => 'pie',
        X_LABELS    => ['June', 'July', 'Augst', "September", 'October'],
        DATA        => {
          'MONEY' => [10, 12, 8,14,20,3],
        },
        BACKGROUND_COLORS => {
          'MONEY' => ['purple', '#ab2312', '#ff6384', 'white', '#11a113'],
        },
        OUTPUT2RETURN => 1,
    });
    Example for custom chart with 2 y axes:
      my $chart3 = $html->chart({
    TYPE     => 'line',
    DATA_CHART => {
      datasets => [ {
        data        => [1,2,3,4,5,6,7,8,9,10],
        label       => "NEW",
        yAxisID     => 'left-y-axis',
        borderColor => 'red',
      }, {
        data        => [1,2,3,4,5,6,7,8,9,10],
        label       => "ALL",
        yAxisID     => 'right-y-axis',
        borderColor => 'black',
      } ],
      labels   => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun']
    },
    OPTIONS  => {
      scales => {
        yAxes => [ {
          id       => 'left-y-axis',
          type     => 'linear',
          position => 'left',
          ticks    => {
            stepSize => 1
          }
        }, {
          id       => 'right-y-axis',
          type     => 'linear',
          position => 'right'
        } ]
      }
    }
  });
=cut
#**********************************************************
sub chart {
  my $self = shift;
  my ($attr) = @_;

  # result for return
  my $result = "";

  # prefix for canvas id
  my $canvas_id = "canvas";

  my $chart_type = $attr->{TYPE} || 'bar';                  # chart type
  my $chart_data = $attr->{DATA} || [];                     # data for chart
  my $chart_labels = $attr->{X_LABELS} || [];               # label for X line
  my $background_colors = $attr->{BACKGROUND_COLORS} || []; # color for items
  my $fill_for_line = $attr->{FILL} || '';                  # for type line - off sfilling under the line
  my $chart_title = $attr->{TITLE} || '';                   # title for chart on top of it

  # loading chart plugin and autincrement id for more then one chart
  if (!$self->{CHART_LOADED}) {
    $self->{CHART_LOADED} = 1;
  }
  else {
    $self->{CHART_LOADED}++;
  }

  $result .= qq{<script src="/styles/$self->{HTML_STYLE}/plugins/chartjs/Chart.min.js"></script>};
  $canvas_id .= $self->{CHART_LOADED};

  if ($attr->{DATA_CHART} && $attr->{OPTIONS}) {
    my $chart_data1 = JSON->new->encode($attr->{DATA_CHART});
    my $chart_options1 = JSON->new->encode($attr->{OPTIONS});
    $result .= qq{
    <canvas id="$canvas_id" class="chartjs" style="display: block; min-height: 250px"></canvas>
    <script>
       var c = document.getElementById("$canvas_id");
       var ctx = c.getContext("2d");
       var myChart = new Chart(ctx, {
         type: '$chart_type',
         data: $chart_data1,
         options: $chart_options1
      });
    </script>
  };
    return $result;
  }

  # hash which will be encode to json
  my %data = ();

  $data{labels} = $chart_labels;
  my $i = 0;

  # crreate datasets
  foreach my $dataset (keys %$chart_data) {
    $data{datasets}[$i]{label} = $dataset;
    $data{datasets}[$i]{data} = $chart_data->{$dataset};
    $data{datasets}[$i]{borderColor} = $background_colors->{$dataset};
    $data{datasets}[$i]{backgroundColor} = $background_colors->{$dataset};

    if ($attr->{FILL}) {
      $data{datasets}[$i]{fill} = $fill_for_line;
    }

    $i++;
  }

  my $json_data = JSON->new->encode(\%data);
  my $hide_legend_option = ($attr->{HIDE_LEGEND}) ? 'legend : { display : false },' : '';
  my $scales = $attr->{Y_BEGIN_ZERO} ? 'scales: { yAxes: [{ ticks: {beginAtZero: true,} }] },' : '';

  # create canvas
  $result .= qq{
    <canvas id="$canvas_id" class="chartjs" style="display: block; min-height: 250px"></canvas>
    <script>
       var c = document.getElementById("$canvas_id");
       var ctx = c.getContext("2d");
       var myChart = new Chart(ctx, {
         type: '$chart_type',
         data: $json_data,
         maintainAspectRatio : true,
         options: {
           $scales
           responsive : true,
           $hide_legend_option
           title: {
                   display: true,
                   text: '$chart_title',
                   fontSize: 16,
           },
         }
      });
    </script>
  };

  unless ($attr->{OUTPUT2RETURN}) {
    print $result;
  }

  return $result;
}

##**********************************************************
#=head2 form_file_dropzone($attr) - drag'n'drop file upload element
#
#  Arguments:
#    $attr -
#    NAME
#  Returns:
#
#
#=cut
##**********************************************************
#sub form_file_dropzone {
#  my ($self, $attr) = @_;
#
#  load_pmodule("JSON");
#  #  require JSON;
#  #  JSON->import();
#
#  my $id = $attr->{ID} || mk_unique_value(5);
#
#  my %default_options = (
#    paramName        => $attr->{NAME} || 'FILE_UPLOAD' ,
#    maxFiles         => $attr->{MAX_FILES} || 1,
#    autoProcessQueue => $attr->{HANDLE_URL} ? \1 : \0,
#  );
#
#  my %options = %default_options;
#
#  if ($attr->{HANDLE_URL}) {
#    $options{autoProcessQueue} = \1;
#    $options{url} = $attr->{HANDLE_URL};
#  }
#
#  my $options_encoded = JSON->new->encode(\%options);
#
#  my $content = qq'
#  <script src="/styles/default_adm/js/dropzone.min.js"></script>
#  <div id="$id"></div>
#  <script>
#    jQuery(function(){
#      var dropzone = new Dropzone("div#$id", $options_encoded);
#    });
#  </script>
#  ';
#
#
#  return $content;
#}


#**********************************************************
=head1 AUTHOR

~AsmodeuS~ (http://abills.net.ua/)

=cut

#**********************************************************
=head2 html_tree($list, $keys) - creates tree for DB list

  Arguments:
    $list - DB list
    $keys - levels for tree

  Returns:
    HTML code

  Example:
    my $list = $Address->build_list();
    my $keys = "city,street_name,number";
    The key value can be changed as you need
    foreach my $line (@$list) {
      $line->{number} = $html->b("$lang{ADDRESS_BUILD} $line->{number}");
    }
    my $tree = $html->html_tree($list, $keys);

=cut
#**********************************************************
sub html_tree {
  my $self = shift;
  my ($list, $keys) = @_;
  my $DATA = JSON->new->encode($list);
  my $result .= qq(
     <div id="show_tree" style="text-align: left;"> </div>
    <link rel='stylesheet' href='/styles/default_adm/css/new_tree.css'>
    <script type='text/javascript' src='/styles/default_adm/js/tree/tree.js'></script>
    <script>
      jQuery(function() {
      var keys = '$keys';
      var list = $DATA;
      var name;
      make_tree(list, keys);
      });
	  </script> );
  return $result;
}

1
