#
# Chullaformer
#   (C) 2010-2013 Jose Miguel Parrella Romero <j@bureado.com>
#
# This is free software under the same terms of Perl.
#

package Chulla;

use Chulla::Model;
use Chulla::Model::Operational;
use Chulla::Model::Raw;

use Net::Twitter;

sub new {
	my $package = shift;

	my %ignoreHash;
	my @ignoreList = qw//;

	for my $ignoreTerm ( @ignoreList ) {
		$ignoreHash{$ignoreTerm} = 1;
	}

	# Your query
	my $q = '#Quito';
	my $nt = Chulla->connect;

	return bless({ conn => $nt,
		       conf => { ignore => \%ignoreHash, count => 4, query => $q, }
		     }, $package);
}

sub connect {
	my $nt = Net::Twitter->new(
	# Your Twitter configuration settings
         traits              => [qw/API::RESTv1_1 OAuth/],
	 consumer_key        => '',
	 consumer_secret     => '',
	 access_token        => '',
	 access_token_secret => '',
         source              => 'Chullaformer 0.1',
	);
	return $nt;
}

sub populate {
	my $self    = shift;

	my $nt = $self->{conn};

	my $iListRef = $self->{conf}->{ignore};
	my %ignoreList = %$iListRef;
	my $query = $self->{conf}->{query};

	my $r  = $nt->search($query);

	foreach my $status ( @{$r->{statuses}} ) { # Resultados
		my $user = lc($status->{user}->{screen_name}) || lc($status->{from_user});

		# Do you need to ignore per language or time zone?
		if ( $status->{lang} =~ /no/ || $status->{time_zone} =~ /Copenhagen/ ) {
			print "Ignoring $status->{id} because of region: " . $status->{lang} . " " . $status->{time_zone} . "\n";
			next;
		}

		# Do you need to ignore per keywords?
		foreach my $ignore ( keys %ignoreList ) {
			if ( $user =~ /$ignore/i ) {
				print "Ignoring $status->{id} ($user) because of user: $user\n";
				next;
			}
			if ( $status->{text} =~ /$ignore/i ) {
				print "Ignoring $status->{id} ($user) because of keyword: $ignore\n";
				next;
			}
		}

		# Do you need to ignore RTs?
		if ( $status->{text} =~ /^RT / ) {
			print "Ignoring $status->{id} ($user) because of retweet\n";
			next;
		}

		# Do you need to ignore too many tags?
		(my @tagnum) = $status->{text} =~ /\#/g;
		if ( $#tagnum > 3 ) {
			print "Ignoring $status->{id} ($user) because of too many tags: $#tagnum\n";
			next;
		}
		
		# Do you need to ignore content we already tweeted?
		if ( Chulla::Model::Operational->search(reply => $status->{id}) or
		     Chulla::Model::Operational->search(reply => $status->{in_reply_to_status_id}) ) {
			print "Skipping $status->{id} because it's already on our DB\n";
			next;
		}

		# This is an operational tweet (short object)
		my $tweet = { status  => $status->{text},
                	reply   => $status->{id},
	                date    => $status->{created_at},
			user	=> $user,
	                tweeted => 0 };
		unless ( Chulla::Model::Operational->create($tweet) ) {
			# Saving on the DB
			print "Error persisting $status->{id} ($user) -- whoops\n";
			next;
		};

		# This is a raw tweet (long object)
		my %raw;
		$raw{'id'} = $status->{'id'};
		$raw{'source'} = $status->{'source'};
		$raw{'to_user_id'} = $status->{'to_user_id'};
		$raw{'geo'} = $status->{'geo'};
		$raw{'profile_image_url'} = $status->{'profile_image_url'};
		$raw{'from_user_id'} = $status->{'from_user_id'};
		$raw{'id_str'} = $status->{'id_str'};
		$raw{'iso_language_code'} = $status->{'iso_language_code'};
		$raw{'created_at'} = $status->{'created_at'};
		$raw{'text'} = $status->{'text'};
		$raw{'from_user_id_str'} = $status->{'from_user_id_str'};
		$raw{'from_user'} = $status->{'from_user'};
		$raw{'user'} = $status->{'user'}->{'screen_name'};
		$raw{'to_user'} = $status->{'to_user'};
		unless ( Chulla::Model::Raw->create(\%raw) ) {
			print "Error persisting raw tweet ($user) in SQL!\n";
		};

	undef $tweet;
	}
}

sub update {
	my $self   = shift;
	my $nt    = $self->{conn};
	my $count = $self->{conf}->{count};

	# Untweeted tweets!
	my $it = Chulla::Model::Operational->search( tweeted => 0, );

	while ((my $tweet = $it->next) && ($count >= 0)) {
	  # Go ahead and retweet it!
	  eval { $nt->retweet($tweet->reply); };
	  if ( $@ ) { # omg it failed
	    print "Error updating for " . $tweet->reply . ": ". $@ . "\n";
	    my $retries = $tweet->retries() || '0';
            ++$retries;
            $tweet->retries($retries);
            print "Retrying ($retries) " . $tweet->reply . "\n";
            if ( $retries > 3 ) {
	      $tweet->tweeted(2);
            }
	    $tweet->update or print "Error updating or unqueuing a retry " . $tweet->reply . "\n";
	  } else { # aight it worked
	    print "Done updating for " . $tweet->reply . "\n";
	    $tweet->tweeted(1);
	    $tweet->update or print "Error unqueuing " . $tweet->reply . "\n";
	    --$count;
	  }
	}
}

1;
