#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

my $libpath;
our ($Bin, %conf, $base_dir, @MODULES);
BEGIN {
  use FindBin '$Bin';
  # Assuming we are in '/usr/abills/misc/db_check/'
  # Should point to abills root dir
  $libpath = $Bin . '/../../';
}
use lib $Bin;
use lib $libpath;
use lib $libpath . 'lib';
use lib $libpath . 'Abills/mysql';

require 'libexec/config.pl';
$base_dir //= $libpath;

# Enable Autoflush
$| = 1;

use Abills::Base qw/_bp parse_arguments in_array/;
use Abills::Misc;
use Abills::Experimental;
use Abills::SQL;
use Admins;
use Parser::Dump;
use Parser::Scheme;

my $db = Abills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'}, { CHARSET => $conf{dbcharset} });
my $admin = Admins->new( $db, \%conf );
$admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' } );

my %ARGS = %{ parse_arguments(\@ARGV) };

my $debug = 0;
if ( $ARGS{DEBUG} ) {
  $debug = $ARGS{DEBUG};
  Parser::Dump::set_debug($debug);
  _bp(undef, undef, { SET_ARGS => { TO_CONSOLE => 1 } });
}

my %cached = ();
if ( $ARGS{FROM_CACHE} ) {
  $cached{$base_dir . 'db'} = 1;
  
#  map { $cached{$_} = 1; } split(',\s?', $ARGS{FROM_CACHE});
}

main();
exit 0;

#**********************************************************
=head2 main()

=cut
#**********************************************************
sub main {
  
  # Get list of modules
  my $all_modules = existing_modules_list();
  
  # Parse dump
  my %dump_info = ();
  if ( $ARGS{SKIP_DUMP} ){
    ## Do nothing
  }
  elsif ( $ARGS{FILE} ) {
    Parser::Dump::parse_accumulate($ARGS{FILE});
    
#    if ($debug > 3){
#      _bp('', Parser::Dump::get_accumulated()->{msgs_unreg_requests}, {EXIT => 1, TO_CONSOLE => 1});
#    }
  }
  else {
    # Get hash for all existing tables structure
    for my $dir ( 'db' ){ #, 'db/update' ) {
      my $dir_path = $base_dir . $dir;
      my $cache_path = $dir_path . '/parser_dump.cache';
    
      if ( exists $cached{$dir_path} ) {
        
        if ( -e $cache_path ) {
          print " Use cache for $dir_path \n" if ($debug);
          %dump_info = (%dump_info, %{ Parser::Dump::read_from_file( $cache_path ) });
        }
        else {
          print " No cache for $dir_path \n" if ($debug);
          Parser::Dump::parse_accumulate($dir_path, { SAVE_TO => $cache_path }) };
        }
      
      else {
        Parser::Dump::parse_accumulate($dir_path, { SAVE_TO => $cache_path }) };
    }
  }
  
  
  %dump_info = %{   Parser::Dump::get_accumulated({ USE_CACHE => \%dump_info }) };
  
  if ($debug > 4 && $ARGS{D_TABLE} ) {
    if ( !exists $dump_info{$ARGS{D_TABLE}} ) {
      die "TABLE $ARGS{D_TABLE} was not found in dump";
    }
  
    _bp($ARGS{D_TABLE}, $dump_info{$ARGS{D_TABLE}});
    
    if ( $ARGS{D_FIELD} && exists $dump_info{ $ARGS{D_TABLE} }->{columns}{ $ARGS{D_FIELD} } ) {
      _bp($ARGS{D_FIELD}, $dump_info{$ARGS{D_TABLE}}->{columns}{$ARGS{D_FIELD}});
    }
  
    exit 0;
  }
  
  print "Found " . scalar(keys %dump_info) . " tables\n" if ($debug);
  
  # Get info for tables from DB
  my $scheme_parser = Parser::Scheme->new($db, $admin, \%conf);
  my %scheme_info = %{  $scheme_parser->parse() };
  
  if ($debug > 4 && $ARGS{S_TABLE} ) {
    if ( !exists $scheme_info{$ARGS{S_TABLE}} ) {
      die "TABLE $ARGS{S_TABLE} was not found in scheme";
    }
    
    _bp($ARGS{S_TABLE}, $scheme_info{$ARGS{S_TABLE}});
    
    if ( $ARGS{S_FIELD} && exists $scheme_info{ $ARGS{S_TABLE} }->{columns}{ $ARGS{S_FIELD} } ) {
      _bp($ARGS{S_FIELD}, $scheme_info{$ARGS{S_TABLE}}->{columns}{$ARGS{S_FIELD}});
    }
    
    exit 0;
  }
  
  
  # Get all tables from DB
  my @existing_tables = sort keys %scheme_info;
  foreach my $table ( @existing_tables ) {
    # Filter tables with module name but not enabled
    if ( $table =~ /^([a-z]+)\_/){
      my $name = ucfirst $1;
      # Skip if it is module name and not enabled module
      
      next if is_disabled_module_name($name, $all_modules);
#      print "$name \n  ";
    }
    
    if ( exists $dump_info{$table}) {
      # Compare columns and types
      compare_tables($table, $dump_info{$table}, $scheme_info{$table})
    }
  }
  
  if ($ARGS{SHOW_CREATE}) {
    foreach my $table ( sort keys %dump_info ) {
      if ( $table =~ /^([a-z]+)\_/ ) {
        my $name = ucfirst $1;
        # Skip if it is module name and not enabled module
      
        next if (is_disabled_module_name($name, $all_modules));
      }
    
      if ( !exists $scheme_info{$table} ) {
        print "  You should possibly create table $table \n";
      }
    
    }
  }
  
}

#**********************************************************
=head2 compare_tables($table1, $table2)

=cut
#**********************************************************
sub compare_tables {
  my ($table_name, $dump_table, $sql_table) = @_;
  
  #  if ($table_name eq 'msgs_unreg_requests'){
  #    _bp('', $dump_table);
  #    _bp('', $sql_table);
  #    exit 0;
  #  }
  
  my $dump_cols_ref = $dump_table->{columns};
  my $sql_cols_ref = $sql_table->{columns};
  
  # If found global differences, than should check it more
  print "Checking table $table_name\n" if ($debug);
  #    _bp('', \@differences);
  
  my @dump_cols = sort keys %{ $dump_cols_ref };
  my @sql_cols = sort keys %{ $sql_cols_ref };
  
  my @existing_in_dump_but_not_sql = grep { !in_array($_, \@sql_cols) } @dump_cols;
  my @existing_in_sql_but_not_in_dump = grep { !in_array($_, \@dump_cols) } @sql_cols;
  
  for ( @dump_cols ) {
    if ( !in_array($_, \@sql_cols) ) {
      my $col_definition = get_column_definition($dump_cols_ref->{$_});
        
      show_tip("ALTER TABLE `$table_name` ADD COLUMN `$_` " . "$col_definition;");
    }
  }
  
  if ( scalar @existing_in_dump_but_not_sql ) {
    print "  Somebody have forgot to define (or execute) ALTER ADD COLUMN for columns:\n" if ($debug);
    print join('', map {"    $_ \n"} @existing_in_dump_but_not_sql) if ($debug);
  }
  
  if ( scalar @existing_in_sql_but_not_in_dump ) {
    print "  This columns was not found in Dump \n" if ($debug);
    do {print "$table_name.$_\n" for (@existing_in_sql_but_not_in_dump)} if ($debug);
  }
  
  # Getting only both existing cols for check
  my %hash_for_unique_keys = ();
  foreach ( @dump_cols ) {
    $hash_for_unique_keys{$_} = 1 if (exists $dump_cols_ref->{$_} && exists $sql_cols_ref->{$_});
  }
  my @both_existing = sort keys %hash_for_unique_keys;
  
  # Now can check types
  foreach my $col ( @both_existing ) {
    my $dump_type = lc $dump_cols_ref->{$col}->{Type};
    my $sql_type = lc $sql_cols_ref->{$col}->{Type};
    
    if ( $dump_type ne $sql_type ) {
      print "  Found wrong defined type for $table_name.$col \n" if ($debug);
      
      # Check if data will not be stripped in case of modification
      my ($dump_size) = $dump_type =~ /\((\d+)\)/;
      my ($sql_size) = $sql_type =~ /\((\d+)\)/;
      if ($dump_size && $sql_size && $sql_size > $dump_size && !$ARGS{ALLOW_DATA_STRIP}){
        print " Will truncate data if applied ($sql_size -> $dump_size). skipping. use \$ARGS{ALLOW_DATA_STRIP} \n" if ($debug);
        next;
      };
      
      print "Expected: '$dump_type' ne Got: '$sql_type' \n" if ($debug);
      my $col_definition = get_column_definition($dump_cols_ref->{$col});
  
      show_tip("ALTER TABLE `$table_name` MODIFY COLUMN `$col` " . "$col_definition;", {
          PREV => uc $sql_type,
          NEW  => uc $col_definition
        });
    }
  }
  
}

#**********************************************************
=head2 get_column_definition()

=cut
#**********************************************************
sub get_column_definition {
  my ($dump_col_info) = @_;
  
  my $default_val = '';
  if (defined $dump_col_info->{Default}){
    if (ref $dump_col_info->{Default} && ref $dump_col_info->{Default} eq 'SCALAR'){
      $default_val = qq{${$dump_col_info->{Default}}};
    }
    elsif ($dump_col_info->{Default}){
      if ($dump_col_info->{Default} eq 'NOW'){
        $default_val = qq{NOW()};
      }
      else {
        $default_val = qq{'$dump_col_info->{Default}'};
      }
    }
    elsif ($dump_col_info->{Default} eq '0'){
      $default_val = '0';
    }
    else {
      $default_val = "''";
    }
  }
  
  return uc ($dump_col_info->{Type})
    . (($dump_col_info->{Null} && $dump_col_info->{Null} eq 'No') ? ' NOT NULL' : '')
    . ( $default_val
        ? (' DEFAULT ' . $default_val)
        : ''
      );
}

#**********************************************************
=head2 show_tip($tip)

=cut
#**********************************************************
sub show_tip {
  my ($tip, $attr) = @_;
  
  if ($ARGS{BATCH}){
    print "$tip\n";
    return 1;
  }
  
  if ($ARGS{APPLY_ALL}){
    $admin->query2($tip, 'do', {});
    return 1;
  }
  
  my $text = ($attr->{PREV} && $attr->{NEW}) ? "Current: $attr->{PREV}\n Change to : $attr->{NEW} \n $tip" : $tip;
  print "\n $text \n Apply? (y/N): ";
  chomp(my $ok = <STDIN>);
  
  if ($ok ne 'y'){
    print " Skipped \n";
    return 1;
  };
  
  $admin->query2($tip, 'do', {});
  if ($admin->{errno}){
    print "\n Error happened : " . ($admin->{errno} || '') . "\n";
    return 0;
  }
  else {
    print "Applied successfully \n";
  }
  
  return 1;
}

#**********************************************************
=head2 existing_modules_list()

=cut
#**********************************************************
sub existing_modules_list {
  
  my $dirs_list = _get_files_in($base_dir . 'Abills/modules', { WITH_DIRS => 1 });
  
  my @module_names = grep { -d $base_dir . 'Abills/modules/' . $_ } @{$dirs_list};
  
  return \@module_names;
}

#**********************************************************
=head2 is_disabled_module_name()

=cut
#**********************************************************
sub is_disabled_module_name {
  my ($name, $exisiting_modules) = @_;
  
  $name = 'Equipment' if ($name eq 'Pon');
  $name = 'Crm' if ($name eq 'Cashbox');
  
  return (in_array($name, $exisiting_modules) && !in_array($name, \@MODULES));
}

1;