use warnings;
use strict;
use Pendant;
use Plack::Builder;

builder {
  enable 'Debug';
  Pendant->to_psgi_app;
};
