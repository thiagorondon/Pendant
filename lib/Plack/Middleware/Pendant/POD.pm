package Plack::Middleware::Pendant::POD;
use warnings;
use strict;

use parent qw(Pendant::Middleware);

use Org::To::HTML qw(org_to_html);

sub file_extension {'.pod'}

sub handle_file {
  my ( $self, $file, $res ) = @_;
  $res->body( org_to_html( source_file => $file )->[2] );
}

1;
