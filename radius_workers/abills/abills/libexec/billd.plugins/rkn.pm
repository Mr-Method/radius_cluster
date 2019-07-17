=head1 NAME

   rkn

   Arguments:

     TIMEOUT

=cut

use XML::LibXML;
use URI::UTF8::Punycode;
use Encode;
use MIME::Base64;
use utf8;
binmode(STDOUT,':utf8');

use Data::Dumper;
use Abills::SQL;
use Abills::Base qw(int2ip ip2int load_pmodule2);
use Rkn;
use Events;

load_pmodule2('SOAP::Lite');
$SOAP::Constants::PREFIX_ENV = 'SOAP-ENV';

our (
  $Admin,
  $db,
  %conf,
  $argv,
  $debug,
);

my $Rkn = Rkn->new( $db, $Admin, \%conf );
my $Log = Log->new(undef, \%conf);
$Log->{LOG_FILE} = $var_dir. "log/rkn.log";
if ( $debug > 0) {
  $Log->{PRINT}=1;
}

my $total_added_main  = 0;
my $total_added_ip    = 0;
my $total_added_name  = 0;
my $total_added_url   = 0;

my @dirs = (
  $var_dir . 'db',
  $var_dir . 'db/rkn/',
  $var_dir . 'db/rkn/cfg',
  $var_dir . 'db/rkn/arch'
);
my $BASE = $var_dir . 'db/rkn/';

my @dns_skip_arr = split(/,/, $conf{RKN_SKIP_NAME}) if $conf{RKN_SKIP_NAME} ;

#make dirs
foreach my $dir ( @dirs ) {
  if (! -d $dir) {
    print "Create '$dir'\n";
    mkdir $dir;
  }
}
if ($argv->{PARSE}){
	parse_xml()
} else {
	rkn();
}
#**********************************************************
=head2 rkn($attr)

  Arguments:
    
    
  Returns:
  
=cut
#**********************************************************
sub rkn {

  my $dt = strftime("%F_%H-%M", localtime(time));
  my $newf = $BASE . "arch/" . $dt . ".zip"; 
  undef $/;
  
  open REQ, '<', $BASE . "cfg/request.xml"  or die "Can't open REQ!\n";
  my $req = <REQ>;
  close REQ;
  encode_base64($req);
  
  open SIG, '<', $BASE . "cfg/request.xml.sign" or die "Can't open SIG!\n";
  my $sig = <SIG>;
  close SIG;

  my $soap =  SOAP::Lite->service("http://vigruzki.rkn.gov.ru/services/OperatorRequest/?wsdl");
#  my $last = $soap->getLastDumpDate();
 
  my @sendresult = $soap->sendRequest($req, $sig, "2.0");
  if ($sendresult[0] eq 'false') {
  	$Log->log_print('LOG_INFO', "Rkn", $sendresult[1]);
  }

  
  my $request_count = 0;
  my $tries = 5;

  while($request_count < $tries) {
	  $request_count++;
	  sleep 30;
	  @getresult = $soap->getResult($sendresult[2]);
	  last if $getresult[0] eq 'true';
  }

  if( $getresult[0] eq 'true'){
	 open ZIP, '>', $newf;
	 print ZIP decode_base64($getresult[1]);
	 close ZIP;
  } else {
  	$Log->log_print('LOG_INFO', "Rkn", $getresult[1]);
  }
   
  if (-e $newf) {
	  system("/usr/bin/unzip -o $newf -d $BASE");
	  parse_xml();
	  unlink "$BASE/dump.xml", "$BASE/dump.xml.sig";
  } else {
	  $Events->events_add(
	              {
	                MODULE   => "Rkn",
	                COMMENTS => $trap->remoteaddr . "Don't get file: $getresult[1]"
	              }
	            );
  }
  return 1
}

#**********************************************************
=head2 parse_xml() - Parse file

=cut
#**********************************************************
sub parse_xml {
 my $self = shift;
 my ($filename) = @_;

 my $blocklist = $Rkn->list({ HASH => '_SHOW', COLS_NAME => 1 });
 my %tmp_hash;
 
 foreach my $bl (@$blocklist) {
 	$tmp_hash{$bl->{id}} =  $bl->{hash};
 }
 if ($argv->{TEST}){
  print Dumper \%tmp_hash;
  exit 255;
 }
 
 my $parser = XML::LibXML->new();
 my $dom = $parser->parse_file("$BASE/dump.xml") or die;
 #my @allowed = ('www.youtube.com','youtube.com','ru.wikipedia.org','youtu.be');

 my $root = $dom->getDocumentElement();
 my @nodes = $root->childNodes;

 $db->{db}->{AutoCommit}=0;
 $db->{TRANSACTION}=1;

 foreach my $node (@nodes) {
 	my $blocktype = $node->getAttribute("blockType") ||'undef';
	my $id = $node->getAttribute("id");
	my $inctime = $node->getAttribute("includeTime");
	my $hash = $node->getAttribute("hash");
 	$inctime =~ s/T/ /g;
	if ( !exists $tmp_hash{$id} || $hash ne $tmp_hash{$id} ) {
		if ( $tmp_hash{$id} && $hash ne $tmp_hash{$id} ) {
			$Rkn->del($id);
			unblock($id) if $debug < 1;
			delete $tmp_hash{$id};
			print "Changed $id, $hash, $inctime \n" if ( $debug > 5);
		}
		
		$Rkn->add( { ID        => $id,
	        			BLOCKTYPE => $blocktype,
	    				HASH      => $hash,
			            INCTIME   => $inctime,
			            } );
		$total_added_main++;
		print "New $id, $hash, $inctime \n" if ( $debug > 5);
		block_ip( $id, $node->getElementsByTagName("ip") ) if ($blocktype eq 'ip' || $blocktype eq 'undef');
		block_dns( $id, $node->getElementsByTagName("domain") ) if ($blocktype eq 'domain' || $blocktype eq 'undef');
		block_dns_mask( $id, $node->getElementsByTagName("domain-mask") ) if $blocktype eq 'domain-mask';
		block_url( $id, $node->getElementsByTagName("url") );
	} else {
		delete $tmp_hash{$id};
	}
 }
 # if (!$error) {
 $db->{db}->commit();
 $db->{db}->{AutoCommit}=1;
 #    } else {
 #      $db->{db}->rollback();
 #    }

 foreach my $key ( keys %tmp_hash ) {
	$Rkn->del($key);
	unblock($id) if $debug < 1;
  	print "Delete $key \n" if ( $debug > 5);
 }

 my $ips = $Rkn->_list({ TABLE => 'rkn_ip', GROUP => 'ip', IP => '_SHOW', SKIP => 0 });
 open( FH, '>', $BASE . "ip_list") or die "Can't create file";
 	foreach my $ip ( @$ips ) {
		print FH "$ip->[0]\n";
	}
 close( FH );
 my $urls = $Rkn->_list({ TABLE => 'rkn_url', GROUP => 'url', URL => '_SHOW', SKIP => 0 });
 open( FH, '>', $BASE . "url_list") or die "Can't create file";
 	foreach my $u ( @$urls ) {
		$url = $u->[0];
		$url=~s/\[\]/\\\[\\\]/g;
		print FH "$url\n";
	}
 close( FH );
 if ($conf{RKN_DNS_TPL}){
 	my $names = $Rkn->_list({ TABLE => 'rkn_domain', GROUP => 'name', NAME => '_SHOW', SKIP => 0 });
 	open( FH, '>', $BASE . "domain_list") or die "Can't create file";
 		foreach my $name ( @$names ) {
			my $param = $conf{RKN_DNS_TPL};
			$param=~s/%NAME/$name->[0]/g;
			print FH $param . "\n";
		}
 	close( FH );
 }

 $Log->log_print('LOG_INFO', "Rkn", "$total_added_main NEW: $total_added_ip IP, $total_added_name NAME, $total_added_url URL." .
                                        keys( %tmp_hash ) . " DELETED");

 return 1
}

sub block_ip{
 my ( $id, @ips ) = @_;
 foreach my $ip ( @ips ) {
	$skip = 0;
	my $curip = $ip->firstChild()->data;
	$Rkn->add_ip( { ID => $id, IP => $curip } );
	if ( grep { $_ eq $curip} @dns_skip_arr ){
		$skip = 1;
		if ($conf{RKN_FW_SKIP_CMD} && $debug < 1){
			my $cmd=$conf{RKN_FW_SKIP_CMD};
			$cmd=~s/%IP/$name/g;
			cmd( $cmd );
		}
	}
	if ($conf{RKN_FW_ADD_CMD} && $debug < 1){
		my $cmd=$conf{RKN_FW_ADD_CMD};
		$cmd=~s/%IP/$curip/g;
		cmd( $cmd );
	}
	$total_added_ip++;
	print "Added IP $curip \n" if ( $debug > 5);
 }
}

sub block_dns{
 my ( $id, @dnames ) = @_;
 foreach my $name (@dnames) {
	$skip = 0;
	$name = puny_encode($name->firstChild()->data);
	if ( grep { $_ eq $name} @dns_skip_arr ){
		$skip = 1;
	} elsif ($conf{RKN_DNS_ADD_CMD} && $debug < 1){
		my $cmd=$conf{RKN_DNS_ADD_CMD};
		$cmd=~s/%NAME/$name/g;
		cmd( $cmd );
	}
	$Rkn->add_domain( { ID => $id, NAME => $name, SKIP => $skip } ) ;
	$total_added_name++;
	print "Added NAME $name \n" if ( $debug > 5);
 }
}

sub block_dns_mask{
 my ( $id, @dnames ) = @_;
	foreach my $name (@dnames) {
		$name = puny_encode($name->firstChild()->data);
		$Rkn->add_domain_mask( { ID => $id, NAME => $name} ) ;
		$total_dns_mask++;
		print "Added NAME $name \n" if ( $debug > 5);
	}
}

sub block_url{
 my ( $id, @urls ) = @_;
	foreach my $url (@urls) {
		$url = puny_encode($url->firstChild()->data);
		$Rkn->add_url( { ID => $id, URL => $url } );
		$total_added_url++;
		print "Added NAME $url \n" if ( $debug > 5);
	}
}

sub unblock{
 my ( $id ) = @_;
 my $unlist = $Rkn->list({ NAME => '_SHOW', IP => '_SHOW', ID => $id, COLS_NAME => 1 });
 foreach my $item (@$unlist){
 	if ($conf{RKN_FW_DEL_CMD} && $item->{ip}){
		my $ip = $item->{ip};
		my $cmd=$conf{RKN_FW_DEL_CMD};
		$cmd=~s/%IP/$ip/g;
		cmd( $cmd );
 	}
 	if ($conf{RKN_DNS_DEL_CMD} && $item->{name}){
		my $name = $item->{name};
		my $cmd=$conf{RKN_DNS_DEL_CMD};
		$cmd=~s/%NAME/$name/g;
		cmd( $cmd );
 	}
 }
}

sub puny_encode {
	my $word = shift;
	my @puny_words = ();
	foreach my $char (split(/\./, $word)) {
		if (($char !~ m/[a-z]/i) && ($char =~ /[^0-9-]/)){
				$char = puny_enc($char);
		}
		push(@puny_words, $char);
	}
	my $result = join('.', @puny_words);
	return $result;
}


