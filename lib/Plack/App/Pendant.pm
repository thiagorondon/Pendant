package Plack::App::Pendant;
use warnings;
use strict;

use File::ShareDir;
use Try::Tiny;
use parent qw(Plack::Component);
use Plack::App::File;
use Plack::Util::Accessor qw(formats _app);

sub default_formats {
  [qw(OrgMode)];
}

sub prepare_app {
  my $self = shift;
  my $root = try { File::ShareDir::dist_dir('Pendant') } || 'share';

  my $builder = Plack::Builder->new;

  for my $spec ( @{ $self->formats || $self->default_formats } ) {
    my ( $package, %args );
    if ( ref $spec eq 'ARRAY' ) {

      # For the backward compatiblity
      # [ 'PanelName', key1 => $value1, ... ]
      $package = shift @$spec;
      $builder->add_middleware( "Pendant::$package", @$spec );
    } else {
      my $spec_copy = $spec;
      $spec_copy = "Pendant::$spec_copy" unless ref $spec_copy;
      $builder->add_middleware($spec_copy);
    }
  }

  my $app = $builder->wrap( Plack::App::File->new( root => $root ) );
  $self->_app($app);
}

sub call {
  my ( $self, $env ) = @_;
  return $self->_app->($env);
}

1;
