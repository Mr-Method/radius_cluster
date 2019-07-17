package Abills::JSON_;

=head1 NAME

 JSON Visualiation Functions

=cut

use strict;
our (
  %FORM,
  %COOKIES,
  $index,
  $pages_qs,
  $SORT,
  $DESC,
  $PG,
  $PAGE_ROWS,
  $SELF_URL,
  $CONFIG_TPL_SHOW,
);

my $debug;
my %log_levels;
my $IMG_PATH='';
my $CONF;
my @table_rows = ();

#**********************************************************
# Create Object
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  $IMG_PATH = (defined($attr->{IMG_PATH})) ? $attr->{IMG_PATH} : '../img/';
  $CONF = $attr->{CONF} if (defined($attr->{CONF}));

  require Abills::HTML;
  Abills::HTML->import();

  my $self = { };
  bless($self, $class);

  if ($attr->{NO_PRINT}) {
    $self->{NO_PRINT} = 1;
  }

  $self->{CHARSET} = (defined($attr->{CHARSET})) ? $attr->{CHARSET} : 'utf8';

  if ($attr->{language}) {
    $self->{language} = $attr->{language};
  }
  elsif ($COOKIES{language}) {
    $self->{language} = $COOKIES{language};
  }
  else {
    $self->{language} = $CONF->{default_language} || 'english';
  }

  $self->{TYPE} = 'json' if (!$self->{TYPE});

  return $self;
}

#**********************************************************
=head2 form_input()

=cut
#**********************************************************
sub form_input {
  my $self = shift;
  my ($name, $value) = @_;

  $self->{FORM_INPUT} = "\"$name\" : { \"value\" : \"$value\" }";

  return $self->{FORM_INPUT};
}

#**********************************************************
=head2 form_main($attr)

=cut
#**********************************************************
sub form_main {
  my $self = shift;
  my ($attr) = @_;

  if ($FORM{EXPORT_CONTENT}) {
    if($FORM{EXPORT_CONTENT} eq $attr->{EXPORT_CONTENT}) {
      return $attr->{CONTENT};
    }
    elsif( $FORM{EXPORT_CONTENT} ne $attr->{ID}) {
      return '';
    }
  }

  my @arr = ();

  if (defined($attr->{HIDDEN})) {
    my $H = $attr->{HIDDEN};
    while (my ($k, $v) = each(%$H)) {
      push @arr, $self->form_input($k, $v);
    }
  }

  if ($attr->{CONTENT}) {
    push @arr, $attr->{CONTENT};
  }

  if (defined($attr->{SUBMIT})) {
    my $H = $attr->{SUBMIT};
    while (my ($k, $v) = each(%$H)) {
      push @arr, $self->form_input($k, $v);
    }
  }

  my $tpl_id = $attr->{ID} || 'main_form';
  my $json_body = "{\n" . join(", \n", @arr) . "}";

  if($FORM{EXPORT_CONTENT}){
    return $attr->{CONTENT};
  }
  elsif (! $attr->{OUTPUT2RETURN}) {
    push @{ $self->{JSON_OUTPUT} }, {
        $tpl_id => $json_body
      };
    return ;
  }
  else {
    return qq{ "$tpl_id" : $json_body };
  }
}

#**********************************************************
# form_textarea
#**********************************************************
sub form_textarea {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  $self->form_input($name, $value);

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#**********************************************************
=head2 form_select()

=cut
#**********************************************************
sub form_select {
  my $self = shift;
  my ($name, $attr) = @_;

  #my $ex_params = (defined($attr->{EX_PARAMS})) ? $attr->{EX_PARAMS} : '';

  $self->{SELECT} = "\"$name\" : {\n";
  my @sel_arr = ();

  if (defined($attr->{SEL_OPTIONS})) {
    my $H = $attr->{SEL_OPTIONS};
    while (my ($k, $v) = each %$H) {
      push @sel_arr, "\"$k\" : \"$v\"";
    }
  }

  if (defined($attr->{SEL_ARRAY})) {
    my $H = $attr->{SEL_ARRAY};
    my $i = 0;

    foreach my $v (@$H) {
      my $id = (defined($attr->{ARRAY_NUM_ID})) ? $i : $v;
      $v =~ s/\n//g;
      push @sel_arr, "\"$id\" : \"$v\"";
      $i++;
    }
  }
  elsif (defined($attr->{SEL_MULTI_ARRAY})) {
    my $key   = $attr->{MULTI_ARRAY_KEY};
    my $value = $attr->{MULTI_ARRAY_VALUE};
    my $H     = $attr->{SEL_MULTI_ARRAY};

    foreach my $v (@$H) {
      my $val = "\"$v->[$key]\"";
      #$val .= ' selected="1"' if (defined($attr->{SELECTED}) && $v->[$key] eq $attr->{SELECTED});
      #$val .= ": $v->[$key] " if (!$attr->{NO_ID});
      $val .= ": \"$v->[$value]\"";
      push @sel_arr, $val;
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
      my $val = "\"$k\" : \"";

      if ($attr->{EXT_PARAMS}) {
        while (my ($ext_k, undef) = each %{ $attr->{EXT_PARAMS} }) {
          $val .= " $ext_k=";
          $val .= $attr->{EXT_PARAMS}->{$ext_k}->{$k} if ($attr->{EXT_PARAMS}->{$ext_k}->{$k});
        }
      }

      $val .= "$k : " if (!$attr->{NO_ID});
      $val .= " $attr->{SEL_HASH}{$k}\"";
      push @sel_arr, $val;
    }
  }

  $self->{SELECT} .= join(",\n  ", @sel_arr);

  $self->{SELECT} .= "}\n";

  return $self->{SELECT};
}


#**********************************************************
# Functions list
#**********************************************************
sub menu2 {
  my $self = shift;
  my ($menu_items, $menu_args, $permissions, $attr) = @_;
  $self->menu($menu_items, $menu_args, $permissions, $attr);
}

sub menu {
  my $self = shift;
  my ($menu_items, $menu_args, $permissions, $attr) = @_;

  return 0 if ($FORM{index} > 0);

  my @menu_arr       = ();
  my $menu_navigator = '';
  my $menu_text      = '';
  push @menu_arr, qq{"SID" : { "sid" : "$self->{SID}" } \n} if ($self->{SID});

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
  my @menu_sorted = sort { $h->{$a} cmp $h->{$b} } keys %$h;

  for (my $parent = 0 ; $parent < $#menu_sorted + 1 ; $parent++) {
    my $val = $h->{ $menu_sorted[$parent] };

    my $level  = 0;
    my $prefix = '';
    my $ID     = $menu_sorted[$parent];

    next if ((!defined($attr->{ALL_PERMISSIONS})) && (!$permissions->{ $parent - 1 }) && $parent == 0);
    push @menu_arr,   " \"$fl->{$ID}\": {
      \"ID\"       : \"$ID\",
      \"EX_ARGS\"  : \"" . $self->link_former($EX_ARGS) . "\",
      \"DESCRIBE\" : \"$val\",
      \"TYPE\"     : \"MAIN\"\n }";

    if (defined($new_hash{$ID})) {
      $level++;
      $prefix .= "   ";
      label:
      my $mi = $new_hash{$ID};

      while (my ($k, $val) = each %$mi) {
        push @menu_arr, "$prefix \"sub_" . $fl->{$k} . "\": {
          \"ID\"       : \"$k\",
          \"EX_ARGS\"  :  \"" . $self->link_former("$EX_ARGS") . "\",
          \"DESCRIBE\" : \"$val\",
          \"TYPE\"     : \"SUB\",
          \"PARENT\"   : \"$ID\"\n  }";

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

  $menu_text .= join(",\n  ", @menu_arr);

  return ($menu_navigator, $menu_text);
}

#**********************************************************
# heder off main page
# make_charts()
#**********************************************************
sub make_charts () {

}

#**********************************************************
# heder off main page
# header()
#**********************************************************
sub header {
  my $self       = shift;
  my ($attr)     = @_;

  my $CHARSET = (defined($attr->{CHARSET})) ? $attr->{CHARSET} : $self->{CHARSET} || 'utf8';
  $CHARSET =~ s/ //g;

  if ($FORM{DEBUG}) {
    print "Content-Type: text/plain\n\n";
  }

  $self->{header}  = "Content-Type: application/json; charset=$CHARSET\n";
  $self->{header} .= "Access-Control-Allow-Origin: *"
                     . "\n\n";

  return $self->{header};
}

#**********************************************************
#
# css()
#**********************************************************
sub css {
  my $css = "";
  return $css;
}

#**********************************************************
=head2 table() - Init table object

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

  my ($attr)    = @_;
  $self->{rows} = '';

  $self->{table} = '';
  if ($#table_rows > -1 ) {
    $self->{table} = ',';
    @table_rows   = ();
  }

  if (defined($attr->{rowcolor})) {
    $self->{rowcolor} = $attr->{rowcolor};
  }

  if ($attr->{FIELDS_IDS}) {
    $self->{FIELDS_IDS}  = $attr->{FIELDS_IDS};
    $self->{TABLE_TITLE} = $attr->{title};
  }

  if ($attr->{rows}) {
    foreach my $line (@{ $attr->{rows} }) {
      $self->addrow(@$line);
    }
  }

  $self->{ID} = $attr->{ID};

  if ($attr->{SELECT_ALL}) {
    $self->{SELECT_ALL}=$attr->{SELECT_ALL};
  }

  if ($FORM{EXPORT_CONTENT} eq $attr->{ID}) {
    $self->{table} .= "{";
  }
  else {
    $self->{table} .= "\"TABLE_" . $attr->{ID} . "\" : {";
  }

  if (defined($attr->{caption})) {
    $self->{table} .= " \"CAPTION\" : \"$attr->{caption}\",\n";
  }

  if (defined($attr->{ID})) {
    $self->{table} .= " \"ID\" : \"$attr->{ID}\",\n";
  }

  if (defined($attr->{title})) {
    $self->{table} .= $self->table_title($SORT, $DESC, $PG, $attr->{title}, $attr->{qs});
  }
  elsif (defined($attr->{title_plain})) {
    $self->{table} .= $self->table_title_plain($attr->{title_plain});
  }

  if ($attr->{pages} && !$FORM{EXPORT_CONTENT}) {
    my $op;
    if ($FORM{index}) {
      $op = "index=$FORM{index}";
    }

    my %ATTR = ();
    if (defined($attr->{recs_on_page})) {
      $ATTR{recs_on_page} = $attr->{recs_on_page};
    }
    $self->{pages} = $self->pages($attr->{pages}, "$op$attr->{qs}", {%ATTR});
  }

  return $self;
}

#**********************************************************
=head2 addrow(@row)

=cut
#**********************************************************
sub addrow {
  my $self = shift;
  my (@row) = @_;

  if ($self->{SKIP_EXPORT_CONTENT}) {
    delete ($self->{SKIP_EXPORT_CONTENT});
    return '';
  }

  my @formed_rows   = ();
  my $select_present = ($self->{SELECT_ALL}) ? 1 : 0;

  for (my $i=0; $i<=$#row; $i++) {
    my $val = $row[$i+$select_present];
    if ($self->{FIELDS_IDS}) {
      if ($self->{FIELDS_IDS}->[$i] && $self->{TABLE_TITLE}->[$i+$select_present] ne '-' ) {
        $val =~ s/[\n\r]/ /g;
        $val =~ s/\"/\\\"/g;
        push @formed_rows, "\"$self->{FIELDS_IDS}->[$i]\" : \"$val\"";
      }
    }
    else {
      #push @formed_rows, (($self->{SKIP_FORMER}) ? "\"$val\"" : $self->link_former("\"$val\"", { SKIP_SPACE => 1 }));
    }
  }

  push @table_rows, '{'. join(', ', @formed_rows) .'}';
  push @{ $self->{table_rows} }, '{'. join(', ', @formed_rows) .'}';

  return $self->{rows};
}

#**********************************************************
=head2 addtd(@rows)

=cut
#**********************************************************
sub addtd {
  my $self  = shift;
  my (@row) = @_;

  my @formed_rows   = ();
  my $select_present = ($self->{SELECT_ALL}) ? 1 : 0;

  for (my $i=0; $i<=$#row+$select_present+1; $i++) {
    my $val = $row[$i+$select_present];
    if ($self->{FIELDS_IDS}) {
      my $title_id = ($i+$select_present < 0) ? 0 : $i+$select_present;
      if ($self->{FIELDS_IDS}->[$i] && $self->{TABLE_TITLE}->[$i] && $self->{TABLE_TITLE}->[$i] ne '-' ) {
        $val =~ s/[\n\r]/ /g;
        push @formed_rows, "\"$self->{FIELDS_IDS}->[$i]\" : \"$val\"";
      }
      else {

      }
    }
    else {
      #push @formed_rows, (($self->{SKIP_FORMER}) ? "\"$val\"" : $self->link_former("\"$val\"", { SKIP_SPACE => 1 }));
    }
  }

  push @{ $self->{table_rows} }, '{'. join(', ', @formed_rows) .'}';

  return \@formed_rows;
}

#**********************************************************
=head2 th($value, $attr) Extendet add rows

=cut
#**********************************************************
sub th {
  my $self = shift;
  my ($value) = @_;

  return $self->td($value, { TH => 1 });
}

#**********************************************************
=head2 td($value, $attr) - Extendet add rows

=cut
#**********************************************************
sub td{
  my $self = shift;
  my ($value) = @_;

  my $td = '';
  if ( defined( $value ) ){
    $td .= $value;
    $td =~ s/\"/\\\"/g;
  }

  return $td;
}

#**********************************************************
=head2 table_title_plain($caption)

  Arguments:
    $caption - ref to caption array

  Results:
    Table Title

=cut
#**********************************************************
sub table_title_plain {
  my $self = shift;
  my ($caption) = @_;

  $self->{table_title} = "\"TITLE\" : [\n";

  my @table_arr = ();
  foreach my $line (@$caption) {
    push @table_arr, "\"$line\"";
  }

  $self->{table_title} .= join(",", @table_arr) ." ],\n";

  return $self->{table_title};
}

#**********************************************************
# Show table column  titles with wort derectives
# Arguments
# table_title($sort, $desc, $pg, $caption, $qs);
# $sort - sort column
# $desc - DESC / ASC
# $pg - page id
# $caption - array off caption
#**********************************************************
sub table_title {
  my $self = shift;
  my ($sort, $desc, $pg, $caption, $qs) = @_;

  $self->{table_title} = "\"TITLE\" : [\n";

  my @table_arr = ();

  foreach my $line (@$caption) {
    push @table_arr, "\"$line\"";
  }

  $self->{table_title} .= join(",", @table_arr) ." ],\n";
  return $self->{table_title};
}

#**********************************************************
#
# img($img, $name, $attr)
#**********************************************************
sub img {
  my $self = shift;
  my ($img, $name) = @_;

  my $img_path = ($img =~ s/^://) ? "$IMG_PATH/" : '';
  $img =~ s/\&/\&amp;/g;

  return "<img alt='$name' src='$img_path$img'/>";
}

#**********************************************************
=head2 show($attr) - Show table content

=cut
#**********************************************************
sub show {
  my $self = shift;
  my ($attr) = @_;

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
    return '';
  }

  if($self->{table_rows}) {
    @table_rows = @{ $self->{table_rows} };
  }

  $self->{show} = $self->{table};
  $self->{show} .= "\"DATA_1\" : [\n  ";
  $self->{show} .= join(",\n ", @table_rows);
  $self->{show} .= "\n]\n";

  if (defined($self->{pages})) {
 #   $self->{show} = $self->{show} . ',' . $self->{pages};
  }

  $self->{show} .= "\n}\n";

  my $tpl_id    = $self->{ID} || 'DATA_1';
  my $json_body = " [\n  "
    . join(",\n ", @table_rows)
    . "\n]";

  if( $FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} eq $self->{ID} ) {
    return $self->{show};
  }
  elsif (! $attr->{OUTPUT2RETURN})  {
    push @{ $self->{JSON_OUTPUT} }, {
        $tpl_id => $json_body
    };
    return '';
  }
  else {
    return qq{ "$tpl_id" : $json_body };
  }

  if ((defined($self->{NO_PRINT})) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{prototype}->{OUTPUT} .= $self->{show};
    $self->{show} = '';
  }

  return $self->{show};
}

#**********************************************************
#
#**********************************************************
sub link_former {
  my ($self) = shift;
  my ($params) = @_;

  return $params;
}

#**********************************************************
#
# button($name, $params, $attr)
#**********************************************************
sub button {
  my $self = shift;
  my ($name, $params, $attr) = @_;
  my $ex_attr = '';

  $params = ($attr->{GLOBAL_URL}) ? $attr->{GLOBAL_URL} : "$params";
  $params = $self->link_former($params);

  $ex_attr = " TITLE='$attr->{TITLE}'" if (defined($attr->{TITLE}));
  my $button = "\"$name\" : {
                     \"url\" : \"$params\",
                     \"title\" : \"$attr->{TITLE}\"
                    }\n";

  $button = $name;

  return $button;
}

#**********************************************************
# Show message box
# message($self, $type, $caption, $message)
# $type - info, err
#**********************************************************
sub message {
  my $self = shift;
  my ($type, $caption, $message, $attr) = @_;

  if ($type eq 'warning') {
    $type='info';
  }

  my $id = ($attr->{ID}) ? qq{,"ID" : "$attr->{ID}" } : '';

  my $tpl_id = 'MESSAGE';
  my $json_body =  qq/{
                      "type"    : "$type",
                      "caption" : "$caption",
                      "messaga" : "$message"
                      $id
                     }/;

  if (! $attr->{OUTPUT2RETURN}) {
    push @{ $self->{JSON_OUTPUT} }, {
        $tpl_id => $json_body
      };
    return ;
  }
  else {
    return qq{ "$tpl_id" : $json_body };
  }

#  my $output = qq{ "$tpl_id" : $json_body };
#  if ($attr->{OUTPUT2RETURN}) {
#    return $output;
#  }
#  elsif ($self->{NO_PRINT}) {
#    $self->{OUTPUT} .= $output;
#    return $output;
#  }
#  else {
#    print $output;
#  }
}

#**********************************************************
# Make pages and count total records
# pages($count, $argument)
#**********************************************************
sub pages {
  my $self = shift;
  my ($count, $argument, $attr) = @_;

  if (defined($attr->{recs_on_page})) {
    $PAGE_ROWS = $attr->{recs_on_page};
  }

  my $begin = 0;
  my @tpl_arr = ();
  return '' if ($count < $PAGE_ROWS);
  $begin = ($PG - $PAGE_ROWS * 3 < 0) ? 0 : $PG - $PAGE_ROWS * 3;

  for (my $i = $begin ; ($i <= $count && $i < $PG + $PAGE_ROWS * 10) ; $i += $PAGE_ROWS) {
    push @tpl_arr, $self->button($i, "$argument&pg=$i") if ($i != $PG);
  }

  return "\"PAGES\": {" . join(",\n ", @tpl_arr) . "}\n";
}

#**********************************************************
=head2 date_fld2($base_name) - Make data field

=cut
#**********************************************************
sub date_fld2 {
  my $self = shift;
  my ($base_name, $attr) = @_;

  my ($sec, $min, $hour, $mday, $mon, $curyear, $wday, $yday, $isdst) = localtime(time);

  my $day   = sprintf("%.2d", $FORM{ $base_name . 'D' } || 1);
  my $month = sprintf("%.2d", $FORM{ $base_name . 'M' } || $mon);
  my $year  = $FORM{ $base_name . 'Y' } || $curyear + 1900;
  my $result = "$base_name Y=\'$year\' M=\'$month\' D=\'$day\' ";

  if ($FORM{$base_name}) {
    my $date = $FORM{$base_name};
    $self->{$base_name} = $date;
  }
  elsif (!$attr->{NO_DEFAULT_DATE}) {
    ($sec, $min, $hour, $mday, $mon, $curyear, $wday, $yday, $isdst) = localtime(time + (($attr->{NEXT_DAY}) ? 86400 : 0));

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
# log_print()
#**********************************************************
sub log_print {
  my $self = shift;
  my ($level, $text) = @_;

  if ($debug < $log_levels{$level}) {
    return 0;
  }

  print << "[END]";
<LOG_PRINT level="$level">
$text
</LOG_PRINT>
[END]
}

#**********************************************************
=head2 element($name, $value, $attr)

=cut
#********************************`**************************
sub element {
  my $self = shift;
  my ($name, $value, $attr) = @_;

  if ($attr->{ID}) {
    $value = " \"$name\" : [ $value ] ";
  }

  $self->{FORM_INPUT} = "";

  if (defined($self->{NO_PRINT}) && (!defined($attr->{OUTPUT2RETURN}))) {
    $self->{OUTPUT} .= $self->{FORM_INPUT};
    $self->{FORM_INPUT} = '';
  }

  return $self->{FORM_INPUT};
}

#**********************************************************
=head2 tpl_show($tpl, $variables_ref, $attr) - show tamplate

=cut
#**********************************************************
sub tpl_show {
  my $self = shift;
  my ($tpl, $variables_ref, $attr) = @_;
  my @val_arr = ();

  if ($attr->{CONFIG_TPL}) {
    return $CONFIG_TPL_SHOW->($self, $tpl, $variables_ref, $attr);
  }

  my $tpl_name = $attr->{ID} || "";
  my $tpl_id = $tpl_name || "_INFO";

  $tpl_name = "HASH" if (! $attr->{MAIN});

  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $tpl_name) {
    return '';
  }

  my $xml_tpl = "";

  if ($tpl_name) {
    $xml_tpl = (($self->{tpl_num} && ! $attr->{SKIP_D}) ? "\n(,) \n" : '' ) ."\"$tpl_name\" :";
    #$tpl_id=$tpl_name;
    $self->{tpl_num}++;
  }

  my $json_body = "{\n" ;
  while ($tpl =~ /\%(\w+)\%/g) {
    my $var = $1;

    if ($var =~ /ACTION_LNG/) {
      next;
    }
    elsif ($variables_ref->{$var} =~ m/^\{\n\}/i) {
      next;
    }
    elsif ($variables_ref->{$var}) {
      if ($variables_ref->{$var} !~ m/\{/g) {
        my $value = "\"$var\" : \"$variables_ref->{$var}\"";
        if(! grep { $_ eq $value } @val_arr) {
          push @val_arr, $value;
        }
        #push @val_arr, "\"-- $var\" : \"$variables_ref->{$var}\" ";
      }
      elsif ($variables_ref->{$var} =~ m/^\"TABLE\"/i) {
        push @val_arr, "\"$var\" : { $variables_ref->{$var} }";
      }
      elsif ($variables_ref->{$var} !~ m/^\"\S+\" : \{/ig) {
        push @val_arr, "\"__$var\" : { $variables_ref->{$var} }";
      }
      elsif ($variables_ref->{$var} !~ m/\"\S+\" : \{/ig) {
        push @val_arr, "\"__$var\" : { $variables_ref->{$var} }";
      }
      else {
        my $value = "\"_$var\" : $variables_ref->{$var}";
        push @val_arr, $value;
      }
    }
  }

  $json_body .= join(",\n  ", @val_arr);
  $json_body .= "}\n" ;
  $xml_tpl .= $json_body;

  if (! $attr->{OUTPUT2RETURN}) {
    push @{ $self->{JSON_OUTPUT} }, {
        $tpl_id => $json_body
      };
    return ;
  }
  else {
    return qq{ "$tpl_id" : $json_body };
  }
}

#**********************************************************
# test function
#  %FORM     - Form
#  %COOKIES  - Cookies
#  %ENV      - Enviropment
#
#**********************************************************
sub test {
  my $output = '';

  while (my ($k, $v) = each %FORM) {
    $output .= "$k | $v\n" if ($k ne '__BUFFER');
  }

  $output .= "\n";
  while (my ($k, $v) = each %COOKIES) {
    $output .= "$k | $v\n";
  }
}

#**********************************************************
# Mark text
#**********************************************************
sub color_mark {
  my $self = shift;
  my ($message, $color, $attr) = @_;

  return $message if ($attr->{SKIP_XML});

  my $output = "$message";
  return $output;
}

sub menu_right {
  my $self = shift;

  return '';
}

#**********************************************************
=head2 table_header($header, $attr) - Show table column  titles with wort derectives

  Arguments:
   $header_arr - array of elements

=cut
#**********************************************************
sub table_header {
  my $self = shift;
  my ($header_arr, $attr) = @_;
  my $header = '';
  if ($FORM{EXPORT_CONTENT} && $FORM{EXPORT_CONTENT} ne $self->{ID}) {
    return '';
  }

#  my @header_arr = ();
#
#  foreach my $element ( @{ $header_arr } ) {
#    my ($name, $url)= split(/:/, $element, 2);
#    push @header_arr, $self->button($name, $url);
#  }
#
#  $header = "\"table_header\" : {\n". join(",\n", @header_arr) ." }\n";

  return $header;
}

#**********************************************************
=head2 fetch() - Fetch cache data

=cut
#**********************************************************
sub fetch  {
  my $self = shift;

  if ($FORM{EXPORT_CONTENT}) {
    return $self;
  }

  #print "\nStart =============================================================\n";
  my @output_arr = ();
  foreach my $obj ( @{ $self->{JSON_OUTPUT} } ) {
    my ($key, $val)=each %$obj;
    push @output_arr, "\"$key\" : $val";
  }

  print "{\n". join(",\n", @output_arr) ."\n}";

  return $self;
}

#**********************************************************
=head2 short_info_panels_row() - Dummy to avoid errors

=cut
#**********************************************************
sub short_info_panels_row{
  return '';
}

#**********************************************************
=head2  AUTOLOAD Autoload secondary funtions

=cut
#**********************************************************
sub AUTOLOAD {
  our $AUTOLOAD;

  return if ($AUTOLOAD =~ /::DESTROY$/);
  my $function = $AUTOLOAD;

  if($function =~ /table_header|progress_bar|/) {
    return q{};
  }

  my ($self, $data) = @_;

  return $data;
}

1
