#
# Chullaformer
#   (C) 2010-2013 Jose Miguel Parrella Romero <j@bureado.com>
#
# This is free software under the same terms of Perl.
#

package Chulla::Moderate;

use strict;
use base qw(CGI::Application Chulla);

use CGI::Application::Plugin::TT;

sub setup {
	my $self = shift;
	$self->start_mode('list');
	$self->mode_param('action');
	$self->header_add( -charset => 'utf-8' );
	$self->run_modes(
		'list' => 'list',
		'delete' => 'delete',
	);

	our $TEMPLATE_OPTIONS = {
		INCLUDE_PATH => [ '/opt/chulla' ],
		ABSOLUTE     => 1,
	};
	__PACKAGE__->tt_config( TEMPLATE_OPTIONS => $TEMPLATE_OPTIONS );
}

sub list {
	my $self = shift;
	my @it   = reverse Chulla::Model::Operational->search( tweeted => '0' );
	my $cnt  = $#it;
	my %params = ( tweets => \@it, count => $cnt );
	return $self->tt_process('/opt/chulla/list.tmpl', \%params);
}

sub delete {
	my $self = shift;
	my $reply = $self->query->param("reply");
	my $it = Chulla::Model::Operational->search(reply => "$reply");
        while ( my $tweet = $it->next ) {
        	$tweet->tweeted(3);
		$tweet->update or return "ERR";
	}
	return "OK";
}

1;
