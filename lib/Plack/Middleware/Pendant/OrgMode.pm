package Plack::Middleware::Pendant::OrgMode;
use warnings;
use strict;
use utf8;

use parent qw(Pendant::Middleware);

use Org::Document;
use Org::To::HTML;

sub file_extension {'.org'}

sub handle_file {
  my ( $self, $file, $res, $env ) = @_;
  open( my ($fh), '<:encoding(UTF-8)', $file )
    or die "Couldn't open $file: $!";
  local $/;
  my $string = <$fh>;
  my $oth    = Org::To::HTML->new( naked => 1 );
  my $doc    = Org::Document->new( from_string => $string );
  my ($headline) = grep { UNIVERSAL::isa( $_, 'Org::Element::Headline' ) }
    @{ $doc->children };
  $env->{'pendant.doc'}{title} = $headline->title->text;
  warn 'org';
  $res->body( $oth->export($doc) );
}

1;
