#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

die "Adds scores to the database\nUsage: $0 database.tsv > newdatabase.tsv" if(!@ARGV);


open FH, $ARGV[0];

my %word_counter; # word => count
my %url;          # word => [url1, url2,...]
my $longest=0;    # length of longest word
my %letterCount;  # Counts each letter, for determining rarity of letters
my $totalChars=0; # How many total characters in all words?
while (<FH>) {
  chomp;
  my($word,$url) = split /\t/ ;
  $word = lc($word);
  $word_counter{$word}++;
  push(@{ $url{$word} }, $url);
  $longest = length($word) if (length($word) > $longest);

  # Count characters in the word
  for my $char(split(//,$word)){
    $letterCount{$char}++;
  }
  $totalChars+=length($word);
}

# Calculate the rarity of each letter
my %charRarity;
for my $char(sort{$a cmp $b} keys(%letterCount)){
  $charRarity{$char} = 1 - $letterCount{$char}/$totalChars;
}

my $numWords = scalar(keys(%word_counter));
for my $word (sort {$a cmp $b} keys %word_counter) {
  # Initial score is the reciprocal of the ratio of this
  # word count divided by all word count.
  my $baseScore = 1 - ($word_counter{$word}/$numWords);

  # Print out all words with their URLs and score
  for my $u(sort {$a cmp $b} @{ $url{$word} }){
    # Also add in a multiplier for the word complexity.
    # The longer the word, the more complex.
    # The more rare letters, the more complex.
    my $charRarity = 1;
    for my $char(split(//, lc("$word"))){
      next if($char !~ /[a-z]/);
      $charRarity *= $charRarity{$char};
    }
    my $complexity = $charRarity * length($word)/$longest;
    my $score = sprintf("%0.9f", $baseScore * $complexity);
    $score = "0.000000001" if($score < 0.000000001);
    print join("\t", $word, $u, $score)."\n";
  }
} 


