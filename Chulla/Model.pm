#
# Chullaformer
#   (C) 2010-2013 Jose Miguel Parrella Romero <j@bureado.com>
#
# This is free software under the same terms of Perl.
#

package Chulla::Model;

use base qw(Class::DBI::SQLite Chulla);

__PACKAGE__->set_db('Main',
                    "dbi:SQLite:dbname=chulla.sql",
                    '', '',
                    {sqlite_unicode => 1,}
                   );
1;
