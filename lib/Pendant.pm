package Pendant;
use Template;
use Web::Simple;
use Pod::Html;
use Org::To::HTML qw(org_to_html);
use Text::Markdown qw(markdown);
use Git::PurePerl;

has repo => ( is => 'lazy' );
has repo_dir => ( is => 'ro', default => sub { $ENV{GIT_REPO} } );
has tt => (
  is => 'ro',
  default =>
    sub { Template->new( INCLUDE_PATH => 'root', WRAPPER => 'wrapper' ) }
);
has extensions => ( is => 'lazy', required => 1 );

sub _lazy_build {
  my ($self) = @_;
  my %h = map { ( $_->[0] => 1 ) } $self->handlers;
}

sub _build_repo {
  Git::PurePerl->new( directory => shift->repo_dir );
}

sub dispatch_request {
  sub (GET + /)       { warn "(GET /)";       shift->get_dir('/'); },
    sub (GET + /**/)  { warn "(GET + /**/)";  shift->get_dir(@_) },
    sub (GET + /**.*) { warn "(GET + /**.*)"; shift->get_file(@_) }
}

sub error_404 { [ 404, [ 'Content-type', 'text/html' ], ['Not Found'] ] }

sub get_dir {
  my ( $self, $dir ) = @_;
  my $tree = $self->repo->master->tree;
  return [
    200,
    [ 'Content-type', 'text/html' ],
    [ $self->render(
        dir => {
          tree     => $tree,
          link_for => sub { $self->link_for_entry(@_) }
        }
      )
    ]
  ];
}

sub link_for_entry {
  my ( $self, $entry ) = @_;
  my $fname = $entry->filename;
  return "$fname/" if $entry->object->kind eq 'tree';
  my $re = '('
    . join( '|',
    map { ( length( $_->[0] ) ? $_->[0] : () ) } $self->handlers )
    . ')';
  $fname =~ s/$re$//;
  return $fname;
}

sub get_file {
  my ( $self, $file ) = @_;
  for my $ext ( $self->handlers ) {
    my $fname = "$file$ext->[0]";
#    warn $fname;
    my $entry = $self->find_entry($fname) or next;
    return [
      200,
      [ 'Content-type', 'text/html' ],
      [ $ext->[1]->( $entry->object->content ) ]
    ];
  }
  return $self->error_404($file);
}

sub find_entry {
  my ( $self, $name ) = @_;
  my $tree = $self->repo->master->tree;
  my ($entry) =
    grep { $_->filename eq $name } $tree->directory_entries;
  return $entry;
}

sub render {
  my ( $self, $type, $vars ) = @_;
  my $out;
  $self->tt->process( $type, $vars, \$out )
    or die $self->tt->error();
  return $out;
}

sub handlers {
  my ($self) = @_;
  return [
    '.org' => sub {
      $self->render(
        page => {
          rendered_content =>
            org_to_html( source_str => shift(), naked => 1 )->[2]
        }
      );
      }
    ],
    [
    '.md' => sub {
      $self->render( page => { rendered_content => markdown( shift() ) } );
      }
    ],
    [ '', sub { shift() } ];    # no handlers registered, return the
                                # plain file content
}

Pendant->run_if_script;
