#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use utf8;
use feature 'say';

BEGIN {
  use FindBin '$Bin';
  
  my $libpath = '/../'; #assuming we are in /usr/abills/misc
  
  unshift( @INC, $Bin . "$libpath/lib" );
}

use Abills::Base qw/parse_arguments/;
use Abills::Fetcher qw/web_request/;

my %ARGS = %{ parse_arguments(\@ARGV) };
my $debug = (exists $ARGS{DEBUG} && defined $ARGS{DEBUG} && $ARGS{DEBUG} ne '0') ? $ARGS{DEBUG} : 0;

# Public accessed modules
my %public_modules = (
  'Maps.pm'     => {
    LOCAL_PATH    => '/usr/abills/Abills/mysql/',
  },
  'Cablecat.pm' => {
    LOCAL_PATH    => '/usr/abills/Abills/mysql/',
  }
);

my $UNAUTORIZED_DOWNLOAD_PATH = 'https://support.abills.net.ua/';

download();

exit 0;

#**********************************************************
=head2 download() - downloads described modules from support.abills.net.ua

=cut
#**********************************************************
sub download{
  
  foreach my $filename ( keys %public_modules ) {
    my $local_path = $public_modules{$filename}->{LOCAL_PATH} . $filename;
    my $url = $UNAUTORIZED_DOWNLOAD_PATH . $filename;
    
    say "$url -> $local_path" if ($debug);
    
    my $file_content = web_request($url);
    
    if ( length $file_content > 5 * 1024 ) {
      open (my $local_fh, '>', $local_path) or die $!;
      print $local_fh $file_content;
    }
    else {
      say $file_content;
      exit 1;
    }
  }
  
  exit 0;
}

