use warnings;
use strict;
use Pendant;
use Plack::Builder;

builder {
  enable 'Static',
    path => sub {s!^/static/!!},
    root => './static/';
  Pendant->run_if_script;
};
