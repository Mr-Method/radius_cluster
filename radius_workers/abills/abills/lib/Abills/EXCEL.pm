package Abills::EXCEL;

=head1 NAME

  EXCEL output Functions

=cut

use strict;
our (
  %FORM,
  %LIST_PARAMS,
  %COOKIES,
  $index,
  $pages_qs,
  $SORT,
  $DESC,
  $PG,
  $PAGE_ROWS,
  $SELF_URL,
);

#use base 'Exporter';
use Encode qw(decode);

our $VERSION = 2.01;
my $CONF;
my $workbook;
my $IMG_PATH = '';

use Spreadsheet::WriteExcel;
my Spreadsheet::WriteExcel $worksheet;

my %text_colors = (
  'text-danger' => 'red',
  '#FF0000'     => 'red',
);

#**********************************************************
# Create Object
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  Spreadsheet::WriteExcel->import();

  require Abills::HTML;
  Abills::HTML->import();

  $CONF = $attr->{CONF} if (defined($attr->{CONF}));

  my $self = {};
  bless($self, $class);

  if ($attr->{NO_PRINT}) {
    $self->{NO_PRINT} = 1;
  }

  $FORM{_export}='xml';

  if ($attr->{language}) {
    $self->{language} = $attr->{language};
  }
  elsif ($COOKIES{language}) {
    $self->{language} = $COOKIES{language};
  }
  else {
    $self->{language} = $CONF->{default_language} || 'english';
  }

  $self->{TYPE}='excel' if(! $self->{TYPE});

  return $self;
}

#**********************************************************
=head2 form_input($name, $value, $attr)

=cut
#**********************************************************
sub form_input {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  my $type  = (defined($attr->{TYPE}))  ? $attr->{TYPE}             : 'text';
  my $state = (defined($attr->{STATE})) ? ' checked="1"'            : '';
  my $size  = (defined($attr->{SIZE}))  ? " SIZE=\"$attr->{SIZE}\"" : '';
  return $value;

  $self->{FORM_INPUT} = "<input type=\"$type\" name=\"$name\" value=\"$value\"$state$size/>";

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#**********************************************************
=head2 form_main($attr) HTML Input form

=cut
#**********************************************************
sub form_main {
  my $self = shift;
  my ($attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
    return '';
  }

  if ($attr->{CONTENT}) {
    $self->{FORM} .= $attr->{CONTENT};
  }

  if (defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $self->{FORM};
    $self->{FORM} = '';
  }

  return $self;
}

#**********************************************************
=head2 form_select($name, $attr)

=cut
#**********************************************************
sub form_select {
  my $self = shift;
  my ($name, $attr) = @_;

  #my $ex_params = (defined($attr->{EX_PARAMS})) ? $attr->{EX_PARAMS} : '';

  $self->{SELECT} = '';

  if (defined($attr->{SEL_OPTIONS})) {
    my $H = $attr->{SEL_OPTIONS};
    while (my ($k, $v) = each %$H) {
      $self->{SELECT} .= "$k:$v\n";
    }
  }

  if (defined($attr->{SEL_ARRAY})) {
    my $H = $attr->{SEL_ARRAY};
    my $i = 0;
    foreach my $v (@$H) {
      my $id = (defined($attr->{ARRAY_NUM_ID})) ? $i : $v;
      $self->{SELECT} .= "$id:$v\n";
      $i++;
    }
  }
  elsif (defined($attr->{SEL_MULTI_ARRAY})) {
    my $key   = $attr->{MULTI_ARRAY_KEY};
    my $value = $attr->{MULTI_ARRAY_VALUE};
    my $H     = $attr->{SEL_MULTI_ARRAY};

    foreach my $v (@$H) {
      $self->{SELECT} .= "$v->[$key]:$v->[$value]\n";
    }
  }
  elsif (defined($attr->{SEL_HASH})) {
    my @H = ();

    if ($attr->{SORT_KEY}) {
      @H = sort keys %{ $attr->{SEL_HASH} };
    }
    else {
      @H = keys %{ $attr->{SEL_HASH} };
    }

    foreach my $k (@H) {
      $self->{SELECT} .= "$k:";

      if ($attr->{EXT_PARAMS}) {
        while (my ($ext_k, $ext_v) = each %{ $attr->{EXT_PARAMS} }) {
          $self->{SELECT} .= " $ext_k='";
          $self->{SELECT} .= $attr->{EXT_PARAMS}->{$ext_k}->{$k} if ($attr->{EXT_PARAMS}->{$ext_k}->{$k});
          $self->{SELECT} .= "'";
        }
      }

      $self->{SELECT} .= "$k:" if (!$attr->{NO_ID});
      $self->{SELECT} .= "$attr->{SEL_HASH}{$k}\n";
    }
  }

  return $self->{SELECT};
}

#**********************************************************
=head2 menu2($menu_items, $menu_args, $permissions, $attr)

=cut
#**********************************************************
sub menu2 {
  my $self = shift;
  my ($menu_items, $menu_args, $permissions, $attr) = @_;
  $self->menu($menu_items, $menu_args, $permissions, $attr);
}

#**********************************************************
=head2 menu($menu_items, $menu_args, $permissions, $attr)

=cut
#**********************************************************
sub menu {
  my $self = shift;
  my ($menu_items, $menu_args, $permissions, $attr) = @_;

  return 0 if ($FORM{index} > 0);

  my $menu_navigator = '';
  my $menu_text      = '';
  $menu_text = "<SID>$self->{SID}</SID>\n" if ($self->{SID});

  return $menu_navigator, $menu_text if ($FORM{NO_MENU});

  my $EX_ARGS = (defined($attr->{EX_ARGS})) ? $attr->{EX_ARGS} : '';
  my $fl = $attr->{FUNCTION_LIST};

  my %new_hash = ();
  while ((my ($findex, $hash) = each(%$menu_items))) {
    while (my ($parent, $val) = each %$hash) {
      $new_hash{$parent}{$findex} = $val;
    }
  }

  my $h          = $new_hash{0};
  my @last_array = ();

  my @menu_sorted = sort { $b cmp $a } keys %$h;

  for (my $parent = 0 ; $parent < $#menu_sorted + 1 ; $parent++) {
    my $val1 = $h->{ $menu_sorted[$parent] };

    my $level  = 0;
    my $prefix = '';
    my $ID     = $menu_sorted[$parent];

    next if ((!defined($attr->{ALL_PERMISSIONS})) && (!$permissions->{ $parent - 1 }) && $parent == 0);
    $menu_text .= "<MENU NAME=\"$fl->{$ID}\" ID=\"$ID\" EX_ARGS=\"" . $self->link_former($EX_ARGS) . "\" DESCRIBE=\"$val1\" TYPE=\"MAIN\"/>\n ";
    if (defined($new_hash{$ID})) {
      $level++;
      $prefix .= "   ";
      label:
      my $mi = $new_hash{$ID};

      while (my ($k, $val) = each %$mi) {
        $menu_text .= "$prefix<MENU NAME=\"$fl->{$k}\" ID=\"$k\" EX_ARGS=\"" . $self->link_former("$EX_ARGS") . "\" DESCRIBE=\"$val\" TYPE=\"SUB\" PARENT=\"$ID\"/>\n ";

        if (defined($new_hash{$k})) {
          $mi = $new_hash{$k};
          $level++;
          $prefix .= "    ";
          push @last_array, $ID;
          $ID = $k;
        }
        delete($new_hash{$ID}{$k});
      }

      if ($#last_array > -1) {
        $ID = pop @last_array;
        $level--;

        $prefix = substr($prefix, 0, $level * 1 * 3);
        goto label;
      }
      delete($new_hash{0}{$parent});
    }
  }

  return ($menu_navigator, $menu_text);
}

#**********************************************************
=head2 make_charts()

=cut
#**********************************************************
sub make_charts {

}

#**********************************************************
=head2 header($attr) - header off main page

=cut
#**********************************************************
sub header {
  my $self       = shift;
  #my ($attr)     = @_;

  if ($FORM{DEBUG}) {
    print "Content-Type: text/plain\n\n";
  }

  my $filename     =  ($self->{ID}) ? $self->{ID}.'.xls' : ($FORM{EXPORT_CONTENT}) ?  $FORM{EXPORT_CONTENT}.'.xls' : int(rand(10000000)).'.xls';
  $self->{header}  = "Content-Type: application/vnd.ms-excel; filename=$filename\n";
  $self->{header} .= "Cache-Control: no-cache\n";
  $self->{header} .= "Content-disposition: attachment;filename=\"$filename\"\n\n";

  return $self->{header};
}


#**********************************************************
=head2 table()

=cut
#**********************************************************
sub table {
  my $proto  = shift;
  my $class  = ref($proto) || $proto;
  my $parent = ref($proto) && $proto;
  my $self;

  $self = {};

  bless($self);

  $self->{prototype} = $proto;
  $self->{NO_PRINT}  = $proto->{NO_PRINT};

  my ($attr) = @_;

  if (defined($attr->{rowcolor})) {
    $self->{rowcolor} = $attr->{rowcolor};
  }

  $self->{ID}=$attr->{ID};

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
  	return $self;
  }

  if ($attr->{SELECT_ALL}) {
    $self->{SELECT_ALL}=$attr->{SELECT_ALL};
  }

  $self->{row_number} = 1;
  $self->{col_num}    = 0;

  # Create a new Excel workbook
  $workbook = Spreadsheet::WriteExcel->new(\*STDOUT);

  # Add a worksheet
  $worksheet   = $workbook->add_worksheet();

  if ($attr->{title} || $attr->{title_plain}) {
    $self->{title} = $attr->{title};
    $self->table_title($SORT, $DESC, $PG, $attr->{title}, $attr->{qs});
  }

  if ($attr->{rows}) {
    foreach my $line (@{ $attr->{rows} }) {
      $self->addrow(@$line);
    }
  }

  return $self;
}

#**********************************************************
=head2 addrows(@row)

=cut
#**********************************************************
sub addrow {
  my $self = shift;
  my (@row) = @_;

  $self->{row_number}++;

  if (! $worksheet) {
  	return $self;
  }

  $worksheet->set_column(0, 3, 25);

  for( my $col_num=0; $col_num <= $#row ; $col_num++) {
    my $val = $row[$col_num];
    if(! $self->{title}->[$col_num] || ($self->{title}->[$col_num] && $self->{title}->[$col_num] eq '-')) {
      next;
    }

    if($val =~ /\[(.+)\|(.{0,100})\]/) {
      $worksheet->write_url( $self->{row_number}, $col_num, $SELF_URL .'?'. $1, $2);
    }
    elsif($val =~ /_COLOR:(.+):(.+)/) {
      my $color  = $1;
      my $text   = $2;

      my $format = $workbook->add_format(
        color   => ($color =~ /^#(\d+)/) ? $1 : $text_colors{$color},
        size    => 10,
        #bold => 1
      );

      $worksheet->write( $self->{row_number}, $col_num, decode( 'utf8', $text ), $format || undef );
    }
    else {
      if($val =~ /^0/) {
        $worksheet->write_string( $self->{row_number}, $col_num, decode( 'utf8', $val ), $self->{format} || undef );
      }
      else {
        $worksheet->write( $self->{row_number}, $col_num, decode( 'utf8', $val ), $self->{format} || undef );
      }
    }

    print "addrow: $self->{row_number} col: $col_num = $val\n" if ($FORM{DEBUG});
  }

  return $self;
}

#**********************************************************
=head2 addtd(@row)

=cut
#**********************************************************
sub addtd {
  my $self  = shift;
  my (@row) = @_;

  my $select_present = ($self->{SELECT_ALL}) ? 1 : 0;

  for (my $i=0; $i<=$#row; $i++) {
    my $val = $row[($i+$select_present)];

    if(!$self->{title}->[$self->{col_num}] || ($self->{title}->[$self->{col_num}] && $self->{title}->[$self->{col_num}] eq '-')) {
      next;
    }

    if($val =~ /\[(.+)\|(.{0,100})\]/) {
      $worksheet->write_url( $self->{row_number}, $self->{col_num}, $SELF_URL .'?'. $1, decode( 'utf8', $2));
    }
    elsif($val =~ /_COLOR:(.+):(.+)/) {
      my $color  = $1;
      my $text   = $2;

      my $format = $workbook->add_format(
        color   => ($color =~ /^#(\d+)/) ? $1 :$text_colors{$color},
        size    => 10,
        #bold    => 1,
          #bg_color=> 'silver',
      );

      $worksheet->write( $self->{row_number}, $self->{col_num}, decode( 'utf8', $text ), $format || undef );
    }
    else {
      $worksheet->write( $self->{row_number}, $self->{col_num}, decode( 'utf8', $val ), undef );
    }
    print "addtd: $self->{row_number} col: $self->{col_num} = $val\n" if ($FORM{DEBUG});
    $self->{col_num}++;
  }

  $self->{row_number}++;
  $self->{col_num}=0;

  return $self;
}

#**********************************************************
=head2 table_title($sort, $desc, $pg, $caption, $qs)

=cut
#**********************************************************
sub table_title {
  my $self = shift;
  my ($sort, $desc, $pg, $caption, $qs) = @_;

  my $title_format = $workbook->add_format(
    color   => 'black',
    size    => 10,
    bold    => 1,
    bg_color=> 'silver',
  );

  my $i = 0;
  foreach my $line (@$caption) {
    $worksheet->write(0, $i, decode('utf8', $line), $title_format);
    $i++;
  }

  return $self;
}

#**********************************************************
=head2 img($img, $name, $attr)

=cut
#**********************************************************
sub img {
  my $self = shift;
  my ($img, $name) = @_;

  return "";

  my $img_path = ($img =~ s/^://) ? "$IMG_PATH/" : '';
  return "<img alt='$name' src='$img_path$img' border='0'>";
}

#**********************************************************
=head2 show($attr)

=cut
#**********************************************************
sub show {
  my $self = shift;
  my ($attr) = @_;

  $workbook->close() if ($workbook);
  $self->{show} = '';
  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
    return '';
  }

  if ($self->{NO_PRINT} && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{prototype}->{OUTPUT} .= $self->{show};
    $self->{show} = '';
  }

  return $self->{show};
}

#**********************************************************
=head2 button($name, $params, $attr)
=cut
#**********************************************************
sub button {
  my $self = shift;
  my ($name, $params) = @_;

  return "[$params|$name]";
}

#**********************************************************
# Show message box
# message($self, $type, $caption, $message)
# $type - info, err
#**********************************************************
sub message {
  my $self = shift;
  my ($type, $caption, $message) = @_;
  my $output = "$type: [CAPTION] $message\n";

  if (defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $output;
    return $output;
  }
  else {
    print $output;
  }
}

#**********************************************************
=head2 pages($count, $argument, $attr) - Make pages and count total records

=cut
#**********************************************************
sub pages {
  my $self = shift;
  my ($count, $argument, $attr) = @_;

  if (defined($attr->{recs_on_page})) {
    $PAGE_ROWS = $attr->{recs_on_page};
  }

  my $begin = 0;

  return '' if ($count < $PAGE_ROWS);

  $self->{pages} = '';
  $begin = ($PG - $PAGE_ROWS * 3 < 0) ? 0 : $PG - $PAGE_ROWS * 3;

  for (my $i = $begin ; ($i <= $count && $i < $PG + $PAGE_ROWS * 10) ; $i += $PAGE_ROWS) {
    $self->{pages} .= ($i == $PG) ? "[$i] " : $i. '';
  }

  return $self->{pages} . "\n";
}

#**********************************************************
=head2 date_fld2($base_name, $attr)

=cut
#**********************************************************
sub date_fld2 {
  my $self = shift;
  my ($base_name, $attr) = @_;

  my ($mday, $mon, $curyear) = (localtime(time))[3..5];

  my $day   = sprintf("%.2d", $FORM{ $base_name . 'D' } || 1);
  my $month = sprintf("%.2d", $FORM{ $base_name . 'M' } || $mon);
  my $year  = $FORM{ $base_name . 'Y' } || $curyear + 1900;

  my $result = sprintf("%d-%.2d-%.2d", $year, $month, $day);

  if ($FORM{$base_name}) {
    my $date = $FORM{$base_name};
    $self->{$base_name} = $date;
  }
  elsif (!$attr->{NO_DEFAULT_DATE}) {
    ($mday, $mon, $curyear) = (localtime(time + (($attr->{NEXT_DAY}) ? 86400 : 0)))[3,4,5];

    $month = $mon + 1;
    $year  = $curyear + 1900;
    $day   = $mday;

    if ($base_name =~ /to/i) {
      $day = ($month != 2 ? (($month % 2) ^ ($month > 7)) + 30 : (!($year % 400) || !($year % 4) && ($year % 25) ? 29 : 28));
    }
    elsif ($base_name =~ /from/i && !$attr->{NEXT_DAY}) {
      $day = 1;
    }
    my $date = sprintf("%d-%.2d-%.2d", $year, $month, $day);
    $self->{$base_name} = $date;
  }

  return $result;
}

#**********************************************************
=head2 tpl_show($tpl, $variables_ref, $attr);

=cut
#**********************************************************
sub tpl_show {
  my $self = shift;
  my ($tpl, $variables_ref, $attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
    return '';
  }

  if (!$attr->{SOURCE}) {
    while ($tpl =~ /\%(\w+)(\=?)([A-Za-z0-9\_\.\/\\\]\[:\-]{0,50})\%/g) {
      my $var       = $1;
      my $delimiter = $2;
      my $default   = $3;

      #    if ($var =~ /$\{exec:.+\}$/) {
      #      my $exec = $1;
      #      if ($exec !~ /$\/usr/abills\/\misc\/ /);
      #      my $exec_content = system("$1");
      #      $tpl =~ s/\%$var\%/$exec_content/g;
      #     }
      #    els

      if ($attr->{SKIP_VARS} && $attr->{SKIP_VARS} =~ /$var/) {
      }
      elsif ($default && $default =~ /expr:(.*)/) {
        my @expr_arr = split(/\//, $1, 2);
        $variables_ref->{$var} =~ s/$expr_arr[0]/$expr_arr[1]/g;
        $default               =~ s/\//\\\//g;
        $default               =~ s/\[/\\\[/g;
        $default               =~ s/\]/\\\]/g;
        $tpl                   =~ s/\%$var$delimiter$default%/$variables_ref->{$var}/g;
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

  if ($attr->{OUTPUT2RETURN}) {
    return $tpl;
  }
  elsif ($attr->{MAIN}) {
    $self->{OUTPUT} .= "$tpl";
    return $tpl;
  }
  elsif ($attr->{notprint} || $self->{NO_PRINT}) {
    $self->{OUTPUT} .= $tpl;
    return $tpl;
  }
  else {
    print $tpl;
  }
}

#**********************************************************
# letters_list();
#**********************************************************
sub letters_list {
  my ($self, $attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
    return "";
  }

  $pages_qs = $attr->{pages_qs} if (defined($attr->{pages_qs}));

  my $output = '<LETTERS>' . $self->button('All ', "index=$index");
  for (my $i = 97 ; $i < 123 ; $i++) {
    my $l = chr($i);
    if ($FORM{letter} && $FORM{letter} eq $l) {
      $output .= "<b>$l </b>";
    }
    else {
      $output .= $self->button("$l", "index=$index&letter=$l$pages_qs") . "\n";
    }
  }
  $output .= '</LETTERS>';

  if (defined($self->{NO_PRINT})) {
    $self->{OUTPUT} .= $output;
    return '';
  }
  else {
    print $output;
  }

}

#**********************************************************
=head2 color_mark() Mark text

=cut
#**********************************************************
sub color_mark {
  my $self = shift;
  my ($message, $color, $attr) = @_;

  return $message if ($attr->{SKIP_XML});
  my $output = ($color) ? '_COLOR:'. $color .':'.$message : $message;

  return $output;
}

#**********************************************************
=head2 br() - Break line

=cut
#**********************************************************
sub br {
  my $self = shift;

  return "\n";
}

#**********************************************************
=head2 element($name, $value, $attr)

=cut
#**********************************************************
sub element {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  $self->{FORM_INPUT} = '';
  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#**********************************************************
=head2 fetch() - Fetch cache data

=cut
#**********************************************************
sub fetch  {
  my $self = shift;

  return $self;
}

#**********************************************************
=head2  AUTOLOAD Autoload secondary funtions

=cut
#**********************************************************
sub AUTOLOAD {
  our $AUTOLOAD;

  return if ($AUTOLOAD =~ /::DESTROY$/);
  my $function = $AUTOLOAD;

  if($function =~ /table_header|progress_bar/) {
    return q{};
  }

  my ($self, $data) = @_;

  return $data;
}

1
