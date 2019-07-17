=head1 NAME

   QR code generator

=cut

use strict;
use Abills::Base qw(urlencode urldecode load_pmodule);
our $html;

#**********************************************************
=head2 qr_make($url, $attr)

  Arguments:
    $url - base url for QRCode
    $attr - hash_ref
      PARAMS      - hash to be stringified and appended to base url
      OUTPUT2RETURN  - REturn img OBJ with html
      WRITE_TO_DISK

=cut
#**********************************************************
sub qr_make {
  my ($url, $attr) = @_;
  
  load_pmodule('Imager::QRCode');
  
  if ( $attr->{WRITE_TO_DISK} ) {
    return _encode_url_to_img($url, $attr);
  }
  
  if ( !$FORM{qindex} || $attr->{OUTPUT2RETURN} ) {
    my $img_html_tag = _generate_img_tag($SELF_URL, _stringify_params($attr->{PARAMS}), $attr);
    
    return $img_html_tag if ( $attr->{OUTPUT2RETURN} );
    
    # Else
    print $img_html_tag;
    return 1;
  }
  
  # FIXME: weird logic. Will print only if !$FORM{header}, otherwise value is lost
  _encode_url_to_img($url, $attr);
  
  return 1;
}

#**********************************************************
=head2 qr_make_image_from_string() - encodes data to qrcode

  Arguments:
    $string - data to encode
    $attr   - hash_ref (Reserved for future)
    
  Returns
    string - JPEG image content
    
=cut
#**********************************************************
sub qr_make_image_from_string {
  my ($string) = @_;
  
  return _generate_image($string);
}

#**********************************************************
=head2 _generate_img_tag($params, $attr) - generate HTML <img> that points to same func

  Arguments:
    $params
    $attr - hash_ref

  Returns:
    HTML code for <img>

=cut
#**********************************************************
sub _generate_img_tag {
  my ($url, $params, $attr ) = @_;
  
  #  my $global_url_options = ($attr->{GLOBAL_URL}) ? "&GLOBAL_URL=" . Abills::Base::urlencode( $attr->{GLOBAL_URL} ) : "";
  my $global_url_options = ($attr->{GLOBAL_URL}) ? "&GLOBAL_URL=" . $attr->{GLOBAL_URL} : "";
  
  return $html->img("$url$params&qrcode=1&qindex=100000$global_url_options", "qrcode",
    { OUTPUT2RETURN => 1, class => 'img-responsive center-block' }
  );
}

#**********************************************************
=head2 _encode_url_to_img($params, $attr) - output QRCode image

  Arguments:
    $params - params for url
    $text - link

  Returns:
    1

=cut
#**********************************************************
sub _encode_url_to_img {
  my ($url, $attr) = @_;
  
  my $url_to_encode = '';
  if ( $attr->{PARAMS}->{GLOBAL_URL} ) {
    $url_to_encode = urldecode($attr->{PARAMS}->{GLOBAL_URL});
  }
  else {
    $url_to_encode = $url . _stringify_params($attr->{PARAMS}) . "&full=1";
  }
  
  my $img = _generate_image($url_to_encode);
  
  if ( $attr->{WRITE_TO_DISK} ) {
    open (my $QRCODE, '>', $conf{TPL_DIR} . "/qrcode.jpg");
    print $QRCODE $img;
  }
  elsif ( !$FORM{header} ) {
    print "Content-Type: image/jpeg\n\n";
    print $img;
  }
  
  return 1;
}

#**********************************************************
=head2 _generate_image($data)

=cut
#**********************************************************
sub _generate_image {
  my ($data) = @_;
  
  load_pmodule('Imager::QRCode');
  
  # Create Imager::QRCode instance
  my $qr = Imager::QRCode->new(
    size          => 8,
    margin        => 1,
    version       => 1,
    level         => 'M',
    casesensitive => 1,
    lightcolor    => Imager::Color->new(255, 255, 255),
    darkcolor     => Imager::Color->new(0, 0, 0),
  );
  
  # Create image from data
  my $img = $qr->plot($data);
  
  # Save image to scalar
  my $result = '';
  # MAYBE:: write errstr to $result?
  $img->write( data => \$result, type => 'jpeg' ) or print $img->errstr;
  return $result;
}

#**********************************************************
=head2 _parse_params($attr) - stringify params ( %FORM ) hash

  Arguments:
    $attr - hash_ref

  Returns:
    string

=cut
#**********************************************************
sub _stringify_params {
  my ($parameters) = @_;
  my $params = '';
  
  if ( ref $parameters eq 'HASH' ) {
    while ( my ($key, $val) = each %{ $parameters } ) {
      
      next if ( (!$key) || ($key eq 'qrcode' || $key eq '__BUFFER' || $key eq 'qindex') );
      
      if ( $key eq 'index' ) {
        $key = 'get_index';
        $val = $functions{ $parameters->{index} };
      }
      
      $params .= "$key=" . urlencode($val) . '&';
    }
  }
  
  return "?" . $params;
}


1