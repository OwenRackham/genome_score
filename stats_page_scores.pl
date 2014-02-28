#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

sub DBConnect {
    my $database = shift || 'superfamily';
        my $user = shift || 'rackham';
        my $password = shift || 'blank';
    my $dsn = "DBI:mysql:$database:127.0.0.1;";
my $dbh;
        if($password eq 'blank'){
$dbh = DBI->connect( $dsn, "$user");
        }else{

   $dbh = DBI->connect( $dsn, "$user" , "$password" );
}
    return $dbh;
}

my %domains_dets;
my %all_dets;
	my $dbh = rackham::DBConnect('superfamily','rackham','Cadsas82');
	### 0 genome.genome,1  genes,2  matches,3  percent,4  coverage,5  domains,6  superfamilies
	###7  average_family_size,8  percent_duplication,9  average_length,10  average_hit_length
	###11  domain_combinations,12  families,13  unique_architectures,14  domain,15  taxonomy
 	my $sth =   $dbh->prepare( "select genome.genome,genes,matches,percent,coverage,domains,superfamilies,average_family_size,percent_duplication,average_length,average_hit_length,domain_combinations,families,unique_architectures,domain,taxonomy from info,genome where genome.genome = info.genome and include in ('y','s');" );
	$sth->execute;
	while (my @temp = $sth->fetchrow_array ) {
		print Dumper \@temp;
		$domains_dets{$temp[14]}{$temp[0]}{'percent'} = $temp[3];
		$domains_dets{$temp[14]}{$temp[0]}{'coverage'} = $temp[4];
		$domains_dets{$temp[14]}{$temp[0]}{'domains'} = $temp[5];
		$domains_dets{$temp[14]}{$temp[0]}{'superfamilies'} = $temp[6];
		$domains_dets{$temp[14]}{$temp[0]}{'average_familiy_size'} = $temp[7];
		$domains_dets{$temp[14]}{$temp[0]}{'percent_duplication'} = $temp[8];
		$domains_dets{$temp[14]}{$temp[0]}{'average_length'} = $temp[9];
		$domains_dets{$temp[14]}{$temp[0]}{'average_hit_length'} = $temp[10];
		$domains_dets{$temp[14]}{$temp[0]}{'domain_combinatoins'} = $temp[11];
		$domains_dets{$temp[14]}{$temp[0]}{'families'} = $temp[12];
		$domains_dets{$temp[14]}{$temp[0]}{'unique_architecture'} = $temp[13];
		
		push($domains_dets{$temp[14]}{'percent'},$temp[3]);
		push($domains_dets{$temp[14]}{'coverage'},$temp[4]);
		push($domains_dets{$temp[14]}{'domains'},$temp[5]);
		push($domains_dets{$temp[14]}{'superfamilies'},$temp[6]);
		push($domains_dets{$temp[14]}{'average_familiy_size'},$temp[7]);
		push($domains_dets{$temp[14]}{'percent_duplication'},$temp[8]);
		push($domains_dets{$temp[14]}{'average_length'},$temp[9]);
		push($domains_dets{$temp[14]}{'average_hit_length'},$temp[10]);
		push($domains_dets{$temp[14]}{'domain_combinatoins'},$temp[11]);
		push($domains_dets{$temp[14]}{'families'},$temp[12]);
		push($domains_dets{$temp[14]}{'unique_architecture'},$temp[13]);		
	}
	
	print Dumper \%domain_dets;
	
	
	

