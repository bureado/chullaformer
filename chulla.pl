#!/usr/bin/env perl

#
# Chullaformer
#   (C) 2010-2013 Jose Miguel Parrella Romero <j@bureado.com>
#
# This is free software under the same terms of Perl.
#

use strict;
use Chulla;

print "[Chullaformer] Execution started at " . localtime() . "\n";

my $bot = Chulla->new;
          $bot->update;
	  $bot->populate;

print "[Chullaformer] Execution ended at " . localtime() . "\n";
