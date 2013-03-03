package Plack::Middleware::Pendant::MarkDown;
use warnings;
use strict;

use parent qw(Pendant::Middleware);

use Text::Markdown qw(markdown);

sub file_extension {'.md'}

sub handle_file {
  my ( $self, $file, $res ) = @_;
  $res->body( markdown( $file->slurp ) );
}

1;
