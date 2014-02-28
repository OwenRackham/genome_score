use Google::Search;

my $search = Google::Search->Web( query => "rock" );
        while ( my $result = $search->next ) {
                print $result->rank, " ", $result->uri, "\n";
        }
