package Pendant::App::Directory;
use warnings;
use strict;
use parent qw(Plack::App::Directory);
use Plack::Util::Accessor qw(trim);
use URI::Escape;

# Stolen from rack/directory.rb
my $dir_file = "<tr><td class='name'><a href='%s'>%s</a></td><td class='size'>%s</td><td class='type'>%s</td><td class='mtime'>%s</td></tr>";
my $dir_page = <<PAGE;
<html><head>
  <title>%s</title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <style type='text/css'>
table { width:100%%; }
.name { text-align:left; }
.size, .mtime { text-align:right; }
.type { width:11em; }
.mtime { width:15em; }
  </style>
</head><body>
<h1>%s</h1>
<hr />
<table>
  <tr>
    <th class='name'>Name</th>
    <th class='size'>Size</th>
    <th class='type'>Type</th>
    <th class='mtime'>Last Modified</th>
  </tr>
%s
</table>
<hr />
</body></html>
PAGE

sub serve_path {
    my($self, $env, $dir, $fullpath) = @_;

    if (-f $dir) {
        return $self->SUPER::serve_path($env, $dir, $fullpath);
    }

    my $dir_url = $env->{SCRIPT_NAME} . $env->{PATH_INFO};

    if ($dir_url !~ m{/$}) {
        return $self->return_dir_redirect($env);
    }

    if($dir_url =~ /^\./) {
        return $self->return_dir_redirect($env);
    }

    my @files = ([ "../", "Parent Directory", '', '', '' ]);

    my $dh = DirHandle->new($dir);
    my $trim_re = '(' . join('|', @{$self->trim}) . ')$';
    warn $trim_re;
    $trim_re = qr/$trim_re/;

    my @children;
    while (defined(my $ent = $dh->read)) {
        next if $ent eq '.' or $ent eq '..' or $ent =~ /^\./;
        $ent =~ s/$trim_re//;
        push @children, $ent;
    }

    for my $basename (sort { $a cmp $b } @children) {
        my $file = "$dir/$basename";
        my $url = $dir_url . $basename;

        my $is_dir = -d $file;
        my @stat = stat _;

        $url = join '/', map {uri_escape($_)} split m{/}, $url;

        if ($is_dir) {
            $basename .= "/";
            $url      .= "/";
        }

        my $mime_type = $is_dir ? 'directory' : ( Plack::MIME->mime_type($file) || 'text/plain' );
        push @files, [ $url, $basename, $stat[7], $mime_type, HTTP::Date::time2str($stat[9]) ];
    }

    my $path  = Plack::Util::encode_html("Index of $env->{PATH_INFO}");
    my $files = join "\n", map {
        my $f = $_;
        sprintf $dir_file, map Plack::Util::encode_html($_), @$f;
    } @files;
    my $page  = sprintf $dir_page, $path, $path, $files;

    return [ 200, ['Content-Type' => 'text/html; charset=utf-8'], [ $page ] ];
}

1;
