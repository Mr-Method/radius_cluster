=NAME

  Abills::Experimental

=SYNOPSYS

  Various function for symplifying and avoiding duplicates of code
  
  Uses %lang, $html

=cut
#package Abills::Experimental;

use strict;
use warnings FATAL => 'all';
#use Exporter qw(import);

our (
  %lang,
  $VERSION,
  %FORM,
#  $html,
  $index,
  @ISA,
  @EXPORT,
  @EXPORT_OK,
  %EXPORT_TAGS
);

our $html;

$VERSION = 1.00;
#
#@EXPORT = qw(
#  show_result
#  sort_array_to_hash
#  translate_list_value
#  );
#
#@EXPORT_OK = qw(
#  is_array_ref
#  is_not_empty_array_ref
#);
#
#%EXPORT_TAGS = ();

#**********************************************************
=head2 sort_array_to_hash($array_ref, $key_name)

  Arguments:
    $array_ref - [ {}, {}, ...]
    $key_name  -  key for grouping (unique)

  Returns:
    \%hash_ref

=cut
#**********************************************************
sub sort_array_to_hash {
  my ($array_ref, $key_name) = @_;

  $key_name ||= 'id';

  my %result_hash = ();
  foreach my $list_row ( @{$array_ref} ) {
    next unless ($list_row && $list_row->{$key_name});
    $result_hash{$list_row->{$key_name}} = $list_row;
  }

  return \%result_hash;
}

#**********************************************************
=head2 show_result($Module, $message) - shows error or success message

  Arguments:
    $Module  - Module DB object
    $message - message to show if no error

  Returns:
    boolean - 1 if success

=cut
#**********************************************************
sub show_result {
  my ($Module, $caption, $message, $attr) =  @_;

  $attr //= {};
  $caption //= '',
  $message //= '';

  return 0 if (_error_show($Module, { MESSAGE => $message }));

  if (exists $Module->{INSERT_ID}){
    $attr->{ID} = $Module->{INSERT_ID};
  }
  
  if ($FORM{ID} && $FORM{change}){
    $message .= $html->button($lang{SHOW}, "index=$index&chg=$FORM{ID}", { BUTTON => 1} ) if ($html->{TYPE} && $html->{TYPE} eq 'html');
  }
  
  $html->message('info', $caption, $message, $attr) if ($caption || $message);

  return 1;
}

#**********************************************************
=head2 translate_list_value($list, @key_names) - translates values inside list by keys

  Arguments:
    $list      - DB list
    @key_names - array of strings. Default ('name')

  Returns:
    $list - same list with translated values

=cut
#**********************************************************
sub translate_list_value {
  my ($list, @key_names) = @_;

  $key_names[0] //= 'name';

  return [] if !$list || ref $list ne 'ARRAY';
  
  if (scalar @key_names == 1){
    return [ map { $_->{$key_names[0]} = _translate($_->{$key_names[0]}); $_ } @$list ];
  }
  
  for (@$list){
    foreach my $key_name (@key_names){
      $_->{$key_name} = _translate($_->{$key_name});
    }
  }
  return $list;
}

#**********************************************************
=head2 is_array_ref($ref) - tests if refference is defined and is array refference

  Arguments:
    $ref - reference to test

  Returns:
    boolean

=cut
#**********************************************************
sub is_array_ref {
  return defined $_[0] && ref($_[0]) eq 'ARRAY';
}

#**********************************************************
=head2 is_not_empty_array_ref($ref)

=cut
#**********************************************************
sub is_not_empty_array_ref {
  return defined $_[0] && ref($_[0]) eq 'ARRAY' && scalar(@{$_[0]}) > 0;
}

#**********************************************************
=head2 arrays_array2table() - transforms arrays array to simple table

  Arguments:
    $lines_array - array_ref
      #0
      [ 'caption', 'value' ],
      #1
      [ 'caption, 'value' ]
    $attr - hash_ref
    
  Returns:
    string - HTML
     
=cut
#**********************************************************
sub arrays_array2table {
  my ($lines_array, $attr) = @_;
  
  my $table = '<table class="table table-hover">';
  
  $table .= join('', map {
      "<tr><td><strong>$_->[0]</strong></td><td>" . ($_->[1] || q{}) . ' </td></tr>'
    } @{ $lines_array });

  $table .= '</table>'
}

#**********************************************************
=head2 compare_hashes_deep(\%hash1, \%hash2) - deeply comparing two hashes
  
  Assuming values are scalars or hash ref
  
=cut
#**********************************************************
sub compare_hashes_deep {
  my ($hash1, $hash2) = @_;
  return 0 unless ($hash1 && $hash2);
  
  my @differences = ();
  
  use Abills::Base qw/_bp/;
  
  my @keys1 = sort keys (%{$hash1});
  my @keys2 = sort keys (%{$hash2});
  
  if ( $#keys1 != $#keys2 ) {
    return [ 'Number of keys differs ' . join(',', @keys1) . ' -  ' . join(',', @keys2) ];
  }
  
  for ( 0 .. $#keys1 ) {
    my $first_val = $hash1->{$keys1[$_]};
    my $second_val = $hash2->{$keys2[$_]};
    
    if ( ref $first_val && ref $second_val ) {
      my $diff2 = compare_hashes_deep($first_val, $second_val);
      push @differences, @{$diff2} if scalar(@{$diff2} > 0);
    }
    elsif ( !ref $first_val && !ref $second_val ) {
      if ( $first_val ne $second_val ) {
        push @differences, "hash1->{$keys1[$_]}($first_val) ne hash2->{$keys2[$_]}($second_val)";
      }
    }
  }
  
  return \@differences;
}

1;