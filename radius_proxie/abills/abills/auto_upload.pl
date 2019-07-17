#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use utf8;
use feature 'say';

BEGIN {
  use FindBin '$Bin';
  
  my $libpath = '/.'; #assuming we are in /usr/abills/
  
  unshift( @INC, $Bin . "$libpath/" );
  unshift( @INC, $Bin . "$libpath" );
  unshift( @INC, $Bin . "$libpath/Abills" );
  unshift( @INC, $Bin . "$libpath/lib" );
}

use Abills::Base qw/cmd ssh_cmd parse_arguments/;
use Abills::Fetcher qw/web_request/;

my %ARGS = %{ parse_arguments(\@ARGV) };

my $debug = (exists $ARGS{DEBUG} && defined $ARGS{DEBUG} && $ARGS{DEBUG} ne '0') ? $ARGS{DEBUG} : 0;
my $upload_mode = (exists $ARGS{UPLOAD} && defined $ARGS{UPLOAD} && $ARGS{UPLOAD} ne '0') ? 1 : 0;

my $UNAUTORIZED_DOWNLOAD_PATH = 'https://support.abills.net.ua/';

# Public accessed modules
my %public_modules = (
  'Maps.pm'     => {
    LOCAL_PATH    => '/usr/abills/Abills/mysql/',
    UPLOAD_PATHES => [
      '/home/asm/new/Maps.pm',
      '/var/www/abills.net.ua/subdomains/demo/abills/Abills/mysql/Maps.pm',
      '/var/www/abills.net.ua/subdomains/support/abills/cgi-bin/Maps.pm',
    ]
  },
  'Cablecat.pm' => {
    LOCAL_PATH    => '/usr/abills/Abills/mysql/',
    UPLOAD_PATHES =>
    [
      '/home/asm/new/Cablecat.pm',
      '/var/www/abills.net.ua/subdomains/demo/abills/Abills/mysql/Cablecat.pm',
      '/var/www/abills.net.ua/subdomains/support/abills/cgi-bin/Cablecat.pm',
    ]
  }
);

my $REMOTE_HOST = 'abills.net.ua';
my $REMOTE_PORT = '22';
my $REMOTE_USER = 'root';
my $REMOTE_KEY = '/root/.ssh/id_rsa';

my $REMOTE_OWNER_NAME = 'www-data';

my $SCP = `which scp`;
chomp ($SCP);

if ( $upload_mode ) {
  upload();
}
else {
  download();
}
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


#**********************************************************
=head2 upload() - uploads all described modules to abills.net.ua to given locations

=cut
#**********************************************************
sub upload{
  
  my @remote_commands = ();
  
  foreach my $module ( keys %public_modules ) {
    my $local_path = $public_modules{$module}->{LOCAL_PATH} . $module;
    
    if ( !-f $local_path ) {
      say "  !! Not exists : $local_path";
      next;
    }
    
    my @remote_pathes = @{ $public_modules{$module}->{UPLOAD_PATHES} };
    
    # Upload files
    # Upload to first location, add add 'cp' commands for other pathes
    my $first_path = shift @remote_pathes;
    if ( defined $first_path ) {
      my $upload_cmd = "$SCP $local_path $REMOTE_USER\@$REMOTE_HOST:$first_path";
      say "$module -> $first_path" if ($debug);
      say $upload_cmd if ($debug > 1);
      cmd($upload_cmd);
    }
    else {
      # No pathes given;
      next;
    }
    
    foreach my $remote_path ( @remote_pathes ) {
      push @remote_commands, "cp $first_path $remote_path";
      push @remote_commands, "chown $REMOTE_OWNER_NAME $remote_path";
    }
  }
  
  # Authorize as root and do other operations
  say join("\n", @remote_commands) if $debug;
  ssh_cmd( join(';', @remote_commands), {
      NAS_MNG_IP_PORT => $REMOTE_HOST . ':' . $REMOTE_PORT,
      NAS_MNG_USER    => $REMOTE_USER,
      SSH_KEY         => $REMOTE_KEY,
    });
  
}