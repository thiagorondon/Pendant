package Pendant;
use Template;
use Web::Simple;
use Pod::Html;
use Org::To::HTML qw(org_to_html);
use Text::Markdown qw(markdown);

sub dispatch_request {
  sub ()            { },
    sub (GET + /)   { redispatch_to 'Home' },
    sub (GET + /**) { shift->get_file(@_) }
}

sub error_404 { [ 404, [ 'Content-type', 'text/html' ], ['Not Found'] ] }

sub get_file {
  my ( $self, $file ) = @_;
  for my $ext ( $self->handlers ) {
    my $fname = "$file.$ext->[0]";
    return [
      200,
      [ 'Content-type', 'text/html' ],
      [ $self->render( $fname, $ext ) ]
      ]
      if -f $fname;
  }
  return $self->error_404($file);
}

my $tt = Template->new( INCLUDE_PATH => 'root' );

sub render {
  my ( $self, $fname, $ext, $type ) = @_;
  $type ||= 'page';
  my $content = $ext->[1]->($fname);
  my $out;
  $tt->process( $type, { content => $content }, \$out ) or die $tt->error();
  return $out;
}

sub handlers {
  return [
    org => sub { org_to_html( source_file => shift(), naked => 1 )->[2] }
    ], [
    md => sub {
      markdown(
        do { local ( @ARGV, $/ ) = shift(); <> }
      );
      }
    ];
}

Pendant->run_if_script;
