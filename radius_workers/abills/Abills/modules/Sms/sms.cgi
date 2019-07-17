#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';


BEGIN {
  unshift @INC, '../lib/';
}

use Abills::HTML;
my $sms_log = 'sms.log';
my $html = Abills::HTML->new();

print "Content-Type: text/html\n\n";
print "Ok";

if(open(my $fh, '>>', 'sms.log')) {
  print $fh "----------------------------\n";
  foreach my $key (sort keys %FORM) {
    print $fh "$key -> $FORM{$key}\n";
  }

  close($fh)
}
else {
  print "Can;t open '$sms_log' $!";
}


1;
