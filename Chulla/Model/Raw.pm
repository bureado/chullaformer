#
# Chullaformer
#   (C) 2010-2013 Jose Miguel Parrella Romero <j@bureado.com>
#
# This is free software under the same terms of Perl.
#

package Chulla::Model::Raw;

use base qw(Class::DBI::SQLite Chulla::Model);
__PACKAGE__->set_up_table("raw_tweets");
1;
