#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use locale;
use POSIX 'locale_h';
setlocale(LC_TIME, 'es_AR');   
    
use Reservas::Manager;
Reservas::Manager->to_app;


# $ plackup -r bin/app.psgi
# >> Dancer server 16622 listening on http://0.0.0.0:5000
# == Entering the development dance floor ...
