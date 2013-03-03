package Plack::App::Pendant;
use warnings;
use strict;

use File::ShareDir;
use Try::Tiny;
use parent qw(Plack::Component);
use Pendant::App::Directory;
use Plack::Util::Accessor qw(formats root _app _tt);
use Plack::Response;
use String::TT;
use Cwd         ();
use Path::Class ();

sub default_formats {
  [qw(OrgMode MarkDown)];
}

sub prepare_app {
  my $self = shift;

  my $root = $self->root || Cwd::cwd();

  my $inc_path = Path::Class::dir($root)->subdir('.meta');
  $self->_tt( Template->new( INCLUDE_PATH => $inc_path, WRAPPER => 'wrapper' ) );

  my $builder = Plack::Builder->new;

  $builder->add_middleware( sub { $self->render_template(@_) } );

  my @extensions;
  for my $spec ( @{ $self->formats || $self->default_formats } ) {
    my ( $package, %args );
    if ( ref $spec eq 'ARRAY' ) {

      # For the backward compatiblity
      # [ 'PanelName', key1 => $value1, ... ]
      $package = shift @$spec;
      $builder->add_middleware( "Pendant::$package", root => $self->root, @$spec );
      push @extensions,
        "Plack::Middleware::Pendant::$package"->file_extension;
    } else {
      my $spec_copy = $spec;
      $spec_copy = "Pendant::$spec_copy" unless ref $spec_copy;
      $builder->add_middleware($spec_copy, root => $self->root);
      push @extensions,
        "Plack::Middleware::$spec_copy"->file_extension;
    }
  }

  my $app = $builder->wrap(
    Pendant::App::Directory->new( root => $root, trim => \@extensions ) );
  $self->_app($app);
}

sub call {
  my ( $self, $env ) = @_;
  return $self->_app->($env);
}

sub render_template {
  my ( $self, $app ) = @_;
  sub {
    my ($env) = @_;
    my $res = $app->($env);
    return $res unless ref( $res->[2] ) eq 'ARRAY';
    my $content = $res->[2][0];
    my $vars = $env->{'pendant.doc'} || {};
    my $rendered;
    $self->_tt->process( 'page', { %$vars, content => $content },
      \$rendered );
    $res->[2][0] = $rendered;
    return $res;
  }
}

1;

__END__
