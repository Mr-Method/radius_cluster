=head1 NAME

   QR code generator

=cut

use strict;
use Abills::Base qw(urlencode urldecode);
our $html;

#**********************************************************
=head2 qr_make($url, $attr)

  Arguments:
    $url - base url for QRCode
    $attr - hash_ref
      PARAMS      - hash to stringified and appended to base url
      IMG_RETURN  - REturn img OBJ with html

=cut
#**********************************************************
sub qr_make {
  my ($url, $attr) = @_;

  load_pmodule( 'Imager::QRCode' );

  if ( $attr->{WRITE_TO_DISK} ){
    _print_image( $url, $attr );
    return 1;
  }

  if ( !$FORM{qindex} || $attr->{IMG_RETURN} ){
    my $img_code = _generate_img_tag( $SELF_URL, _stringify_params( $attr->{PARAMS} ), $attr );
    if ( $attr->{IMG_RETURN} ){
      return $img_code;
    }
    print $img_code
    return 0;
  }

  _print_image( $url, $attr );

  return 1;
}

#**********************************************************
=head2 _generate_img($params, $attr) - generate HTML <img> that points to same func

  Arguments:
    $params
    $attr - hash_ref

  Returns:
    HTML code for <img>

=cut
#**********************************************************
sub _generate_img_tag{
  my ($url, $params, $attr ) = @_;

  #  my $global_url_options = ($attr->{GLOBAL_URL}) ? "&GLOBAL_URL=" . Abills::Base::urlencode( $attr->{GLOBAL_URL} ) : "";
  my $global_url_options = ($attr->{GLOBAL_URL}) ? "&GLOBAL_URL=" . $attr->{GLOBAL_URL} : "";

  return $html->img( "$url$params&qrcode=1&qindex=100000$global_url_options", "qrcode",
    { OUTPUT2RETURN => 1, class => 'img-responsive center-block' }
  );
}

#**********************************************************
=head2 _print_image($params, $attr) - output QRCode image

  Arguments:
    $params - params for url
    $text - link

  Returns:
    1

=cut
#**********************************************************
sub _print_image{
  my ($url, $attr) = @_;

  my $qr = Imager::QRCode->new(
    size          => 8,
    margin        => 1,
    version       => 1,
    level         => 'M',
    casesensitive => 1,
    lightcolor    => Imager::Color->new( 255, 255, 255 ),
    darkcolor     => Imager::Color->new( 0, 0, 0 ),
  );

  my $url_to_encode = "";

  if ( $attr->{PARAMS}->{GLOBAL_URL} ){
    print "Encoded-URL: $attr->{PARAMS}->{GLOBAL_URL}\n";
    $url_to_encode = urldecode( $attr->{PARAMS}->{GLOBAL_URL} );
  }
  else{
    $url_to_encode = $url . _stringify_params( $attr->{PARAMS} ) . "full=1";
    print ""
  }

  my $img = $qr->plot( $url_to_encode );

  if ( $attr->{WRITE_TO_DISK} ){
    open ( my $QRCODE, '>', $conf{TPL_DIR} . "qrcode.jpg" );
    $img->write( fh => $QRCODE, type => 'jpeg' )
      or print $img->errstr;
  }
  elsif ( !$FORM{header} ){
    print "QRCode-URL : $url_to_encode\n";
    print "Content-Type: image/jpeg\n\n";
    $img->write( fh => \*STDOUT, type => 'jpeg' )
      or print $img->errstr;
  }

  return 1;
}


#**********************************************************
=head2 _parse_params($attr) - stringify params ( %FORM ) hash

  Arguments:
    $attr - hash_ref

  Returns:
    string

=cut
#**********************************************************
sub _stringify_params{
  my ($parameters) = @_;
  my $params = '';

  if ( ref $parameters eq 'HASH' ){
    while(my ($key, $val) = each %{ $parameters } ) {
      next if ((!$key) || ($key eq 'qrcode' || $key eq '__BUFFER' || $key eq 'qindex'));
      if ( $key eq 'index' ){
        $key = 'get_index';
        $val = $functions{ $parameters->{index} };
      }
      $params .= "$key=$val&"
    }
  }

  return "?" . $params;
}


1