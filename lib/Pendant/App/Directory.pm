package Pendant::App::Directory;
use warnings;
use strict;
use parent qw(Plack::App::Directory);
use Plack::Util::Accessor qw(trim);
use URI::Escape;

# Stolen from rack/directory.rb
my $dir_file = "<tr><td align='left'><a href='%s'>%s</a></td><td align='left'>%s</td><td align='left'>%s</td><td align='left'>%s</td></tr>";
my $dir_page = <<PAGE;
<h1>%s</h1>
<hr />
<table width="100%">
  <tr>
    <th align='left'>Name</th>
    <th align='left'>Size</th>
    <th align='left'>Type</th>
    <th align='left'>Last Modified</th>
  </tr>
%s
</table>
<hr />
PAGE

sub serve_path {
    my($self, $env, $dir, $fullpath) = @_;
    if (-f $dir) {
        return $self->SUPER::serve_path($env, $dir, $fullpath);
    }

    $dir =~ s{/\.?$}{};

    my $dir_url = $env->{SCRIPT_NAME} . $env->{PATH_INFO};

    if ($dir_url !~ m{/$}) {
        return $self->return_dir_redirect($env);
    }

    if($dir_url =~ /^\./) {
        return $self->return_dir_redirect($env);
    }

    my @files; # = ([ "../", "Parent Directory", '', '', '' ]);

    my $dh = DirHandle->new($dir);
    my $trim_re = '(' . join('|', @{$self->trim}) . ')$';
    $trim_re = qr/$trim_re/;

    my @children;
    while (defined(my $ent = $dh->read)) {
        next if $ent eq '.' or $ent eq '..' or $ent =~ /^\./;
        (my $link = $ent) =~ s/$trim_re//;
        push @children, {ent => $ent, link => $link};
    }

    for my $basename (sort { $a cmp $b } @children) {
        my $file = "$dir/$basename->{ent}";
        my $url = $dir_url . $basename->{link};

        my $is_dir = -d $file;
        my @stat = stat _;

        $url = join '/', map {uri_escape($_)} split m{/}, $url;

        if ($is_dir) {
            $basename->{ent} .= "/";
            $url      .= "/";
        }

        my $mime_type = $is_dir ? 'directory' : ( Plack::MIME->mime_type($file) || 'text/plain' );
        push @files, [ $url, $basename->{link}, $stat[7], $mime_type, HTTP::Date::time2str($stat[9]) ];
    }

    my $path  = Plack::Util::encode_html("Equinócio 2013.1");
    my $files = join "\n", map {
        my $f = $_;
        sprintf $dir_file, map Plack::Util::encode_html($_), @$f;
    } @files;
    my $page  = sprintf $dir_page, $path, $files;
    return [ 200, ['Content-Type' => 'text/html; charset=utf-8'], [ $page ] ];
}

1;
