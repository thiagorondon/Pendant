package Pendant::Middleware;
use warnings;
use strict;

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(renderer root);
use Text::MicroTemplate;
use Plack::Request;
use Path::Class;
use Cwd;

sub file_extension { }

sub handle_file { }

sub call {
  my ( $self, $env ) = @_;
  my $ext = $self->file_extension;
  if ( my $file = $self->get_file( $env->{PATH_INFO}, $ext ) ) {
    my $req = Plack::Request->new($env);
    my $res = $req->new_response(200);
    $res->headers( [ 'Content-type' => 'text/html; charset=utf-8' ] );
    $self->handle_file( $file, $res, $env );
    return $res->finalize;
  }

  return $self->app->($env);
}

sub path { Path::Class::dir( shift->root || Cwd::cwd() ) }

sub get_file {
  my ( $self, $name, $ext ) = @_;
  my $file = $self->path->file( $name . $ext );
  return unless -f $file;
  return $file;
}

1;
