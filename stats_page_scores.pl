#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use DBI;
sub DBConnect {
    my $database = shift || 'superfamily';
        my $user = shift || 'rackham';
        my $password = shift || 'blank';
        my $host = shift || 'supfam.cs.bris.ac.uk';
    my $dsn = "DBI:mysql:$database:$host;";
my $dbh;
        if($password eq 'blank'){
$dbh = DBI->connect( $dsn, "$user");
        }else{

   $dbh = DBI->connect( $dsn, "$user" , "$password" );
}
    return $dbh;
}

sub average{
	my($data) = @_;
        if (not @$data) {
        	die("Empty array\n");
        }
        my $total = 0;
       	foreach (@$data) {
        	$total += $_;
        }
        my $average = $total / @$data;
        	return $average;
}
sub stdev{
	my($data) = @_;
        if(@$data == 1){
        	return 0;
        }
        my $average = &average($data);
        my $sqtotal = 0;
        foreach(@$data) {
        	$sqtotal += ($average-$_) ** 2;
         }
        my $std = ($sqtotal / (@$data-1)) ** 0.5;
        return $std;
}


sub get_clade {
	my $genome_id = shift;
	my $target_species = shift;
	
	my $dbh = DBConnect('superfamily','rackham');
	my $results = $dbh->selectall_arrayref( "select parent.nodename 
							   from tree as child, tree as parent 
							   where child.left_id between parent.left_id and parent.right_id and child.nodename = ?
							   order by parent.left_id desc;", undef, $genome_id);
	my @clades = map{$_->[0]} @$results;
	
	my @genomes;
	foreach my $clade (@clades){
		@genomes = split(/,/, $clade);
		my $num_species = 0;
		foreach my $genome (@genomes){
			my @include = $dbh->selectrow_array("select include from genome where genome=?",undef,$genome);
			if ($include[0] eq 'y'){
				$num_species++;
			}
		}
		if ($num_species >= $target_species){
			last;
		}

	}
	return \@genomes;
}


my $seed = $ARGV[0];
my $target_species = $ARGV[1];
my $type = $ARGV[2];
my $result = get_clade('hs',10);
my @result = @{$result};





my %domains_dets;
my %all_dets;

	my $dbh = DBConnect('superfamily','rackham');
	my $sth;
	### 0 genome.genome,1  genes,2  matches,3  percent,4  coverage,5  domains,6  superfamilies
	###7  average_family_size,8  percent_duplication,9  average_length,10  average_hit_length
	###11  domain_combinations,12  families,13  unique_architectures,14  domain,15  taxonomy
 	if(defined($seed)){
 		my $genome = join("','",@result);
 		$sth =   $dbh->prepare( "select genome.genome,genes,matches,percent,coverage,domains,superfamilies,average_family_size,percent_duplication,average_length,average_hit_length,domain_combinations,families,unique_architectures,domain,taxonomy from info,genome where genome.genome = info.genome and include in ('y','s') and genome.genome in ('$genome');" );
		$sth->execute;
		while (my @temp = $sth->fetchrow_array ) {
			$domains_dets{$temp[0]}{'Percent with Assignment'} = $temp[3];
			$domains_dets{$temp[0]}{'Percent of Sequences covered'} = $temp[4];
			$domains_dets{$temp[0]}{'Number of Superfamilies'} = $temp[6];
			$domains_dets{$temp[0]}{'Average Sequence Length'} = $temp[9];
			$domains_dets{$temp[0]}{'Average hit length'} = $temp[10];
			$domains_dets{$temp[0]}{'Number of Families'} = $temp[12];
			$domains_dets{$temp[0]}{'Number of Unique Architectures'} = $temp[13];
			
			push(@{$all_dets{'Percent with Assignment'}},$temp[3]);
			push(@{$all_dets{'Percent of Sequences covered'}},$temp[4]);
			push(@{$all_dets{'Number of Superfamilies'}},$temp[6]);
			push(@{$all_dets{'Average Sequence Length'}},$temp[9]);
			push(@{$all_dets{'Average hit length'}},$temp[10]);
			push(@{$all_dets{'Number of Families'}},$temp[12]);
			push(@{$all_dets{'Number of Unique Architectures'}},$temp[13]);		
		}
		
		my %stats;
		foreach my $stat (keys %all_dets){
			$stats{$stat}{'avg'} = &average($all_dets{$stat});
			$stats{$stat}{'std'} = &stdev($all_dets{$stat});
			my $diff = $stats{$stat}{'avg'} - $domains_dets{$seed}{$stat};
			my $perc = ($diff/$domains_dets{$seed}{$stat})*100;
			print "$seed\t$stat\t$perc\n";
		}
		
		
 	}else{
		$sth = $dbh->prepare( "select genome.genome,genes,matches,percent,coverage,domains,superfamilies,average_family_size,percent_duplication,average_length,average_hit_length,domain_combinations,families,unique_architectures,domain,taxonomy from info,genome where genome.genome = info.genome and include in ('y','s');" );	
		$sth->execute;
	while (my @temp = $sth->fetchrow_array ) {
		$domains_dets{$temp[14]}{$temp[0]}{'Percent with Assignment'} = $temp[3];
		$domains_dets{$temp[14]}{$temp[0]}{'Percent of Sequences covered'} = $temp[4];
		$domains_dets{$temp[14]}{$temp[0]}{'Number of Superfamilies'} = $temp[6];
		$domains_dets{$temp[14]}{$temp[0]}{'Average Sequence Length'} = $temp[9];
		$domains_dets{$temp[14]}{$temp[0]}{'Average hit length'} = $temp[10];
		$domains_dets{$temp[14]}{$temp[0]}{'Number of Families'} = $temp[12];
		$domains_dets{$temp[14]}{$temp[0]}{'Number of Unique Architectures'} = $temp[13];
		
		push(@{$all_dets{$temp[14]}{'Percent with Assignment'}},$temp[3]);
		push(@{$all_dets{$temp[14]}{'Percent of Sequences covered'}},$temp[4]);
		push(@{$all_dets{$temp[14]}{'Number of Superfamilies'}},$temp[6]);
		push(@{$all_dets{$temp[14]}{'Average Sequence Length'}},$temp[9]);
		push(@{$all_dets{$temp[14]}{'Average hit length'}},$temp[10]);
		push(@{$all_dets{$temp[14]}{'Number of Families'}},$temp[12]);
		push(@{$all_dets{$temp[14]}{'Number of Unique Architectures'}},$temp[13]);		
	}
	
	#print Dumper \%domains_dets;
	my %stats;
	
	foreach my $domain (keys %all_dets){
		foreach my $stat (keys %{$all_dets{$domain}}){
			$stats{$stat}{'avg'} = &average($all_dets{$domain}{$stat});
			$stats{$stat}{'std'} = &stdev($all_dets{$domain}{$stat});
		}
	}
	
	#print Dumper \%stats;
	my %id_lookup;
	$dbh = DBConnect('pqi','rackham');
	$sth =   $dbh->prepare("select name,id from method;");
	$sth->execute;
	while (my @temp = $sth->fetchrow_array ) {
		$id_lookup{$temp[0]} = $temp[1];
	}
	my %z_scores;
	
	foreach my $domain (keys %domains_dets){
	        foreach my $genome (keys %{$domains_dets{$domain}}){
	        	foreach my $stat (keys %{$domains_dets{$domain}{$genome}}){
	        		$z_scores{$genome}{$stat} = (($domains_dets{$domain}{$genome}{$stat} - $stats{$stat}{'avg'})/$stats{$stat}{'std'});
	        		
	        		if(exists($id_lookup{$stat})){
	        			print "$genome\t$id_lookup{$stat}\t$z_scores{$genome}{$stat}\n";
	        		}else{
	        			print "$genome\t$stat\t$z_scores{$genome}{$stat}\n";
	        		}
	        	}
		}	
	}
	}
	
	
	#print Dumper \%z_scores;
	
	

