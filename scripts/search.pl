#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;
use FindBin qw/$RealBin/;
use List::Util qw/min/;

sub logmsg{print STDERR basename($0).": @_\n";}

exit(main());

sub main{
	my $settings = {};
	GetOptions($settings,qw(help depth=i numhits=i)) or die $!;
	$$settings{depth}   ||= 3;
	$$settings{numhits} ||= 10;

	die usage() if($$settings{help} || !@ARGV);

	# Force lowercase
	@ARGV = map{lc($_)} @ARGV;

	my $hits = search(\@ARGV,$$settings{depth}, $settings);

	my @hits = sort {$$hits{$b} <=> $$hits{$a}} keys(%$hits);

	my $numHits = min($$settings{numhits}, scalar(@hits));
	logmsg "Total hits found: ".scalar(@hits).". Displaying up to the top $$settings{numhits} hits.";

	for(my $i=0; $i<$numHits; $i++){
		print join("\t", $hits[$i], $$hits{$hits[$i]})."\n";
	}

	return 0;
}

sub search{
	my($query, $depth, $settings) = @_;

	my $datafile = "$RealBin/../data/intranet.${depth}depth.scores.tsv";
	die "Could not load search database $datafile" if (! -f $datafile);
	
	my $db = loadDatabase($datafile,$settings);
	
	my %hitScore; # URL => score
	for my $q(@$query){
		if(!defined($$db{$q})){
			logmsg "WARNING: no hits found for query $q";
			next;
		}
		for my $url (keys(%{ $$db{$q} })){
			$hitScore{$url} += $$db{$q}{$url};
		}
	}

	return \%hitScore;
}

sub loadDatabase{
	my($database,$settings)=@_;

	my %data;

	open (my $data, $database) or die "ERROR: could not read database $database: $!";
	while (<$data>) {
		chomp;
		# TODO filter for cdc.gov in the addScoresToDatabase script
		#next if (! /\thttp.*cdc\.gov(\/|$)/);
		
		my @F = split /\t/;
		$data{$F[0]}{$F[1]}=$F[2];
	}
	close $database;

	return \%data;
}

sub usage{
	"Usage: $0 [options] search terms
	--depth   3  How many links down to search
	--numhits 10 How many results to return

	"
}

