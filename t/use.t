#!/usr/bin/env perl
$^W=1; # for systems where env gets confused by "perl -w"
use strict;
use vars qw( $VERSION );

# $Id: use.t,v 1.2 2004/07/15 09:29:44 abuse Exp $
$VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Test;
BEGIN { plan tests => 1 }

use Device::SCSI; ok(1);
exit;
