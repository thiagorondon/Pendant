package Plack::Middleware::Pendant::OrgMode;
use warnings;
use strict;

use parent qw(Plack::Middleware);

use Plack::Request;
use Plack::Util::Accessor qw(renderer);
use Path::Class;
use Cwd;
use Org::To::HTML qw(org_to_html);

sub file_extension {'.org'}

sub call {
  my ( $self, $env ) = @_;
  my $ext = $self->file_extension;
  if ( my $fname = $self->get_file_name( $env->{PATH_INFO}, $ext ) ) {
    my $req = Plack::Request->new($env);
    my $res = $req->new_response(200);
    $res->headers( [ 'Content-type' => 'text/html' ] );
    $res->body( org_to_html( source_file => $fname )->[2] );
    return $res->finalize;
  }

  return $self->app->($env);
}

sub path { Path::Class::dir( Cwd::cwd() ) }

sub get_file_name {
  my ( $self, $name, $ext ) = @_;
  my $file = $self->path->file( $name . $ext );
  return unless -f $file;
  return $file;
}

1;
