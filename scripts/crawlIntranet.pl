#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use File::Basename qw/basename/;

use WWW::SimpleRobot;
use HTML::Strip;

local $0 = basename $0;
sub logmsg{print STDERR "$0: @_\n";}

exit main();

sub main{
  my $settings={};
  GetOptions($settings,qw(help depth=i site=s index=s)) or die $!;
  $$settings{depth}||=1;
  $$settings{site}||="http://google.com";
  $$settings{index}||="crawler.index";

  die usage() if($$settings{help});

  #my $URL="http://intranet.cdc.gov/connects/az/u.html";
  my $pages = crawl($$settings{site}, $settings);

  # Transform pages to an index of word => page
  my %word;
  while(my($url,$pageHash) = each(%$pages)){
    delete($$pageHash{html});
    delete($$pageHash{links});
    delete($$pageHash{text});
    for(@{$$pageHash{words}}){
      $word{$_}{$url} = 1;
    }
  }

  # print the index
  my @word = sort{$a cmp $b} keys(%word);
  open(my $fh, ">", $$settings{index}) or die "ERROR: could not write to $$settings{index}: $!";
  for my $word(@word){
    my $urlHash = $word{$word};
    for my $url(keys(%$urlHash)){
      print $fh join("\t", $word, $url)."\n";
    }
  }
  close $fh;

  return 0;
}

sub crawl{
  my($URL, $settings)=@_;

  my %pages;

  my $bot = WWW::SimpleRobot->new(
    URLS           => [$URL],
    #FOLLOW_REGEX   => "cdc\.gov",
    DEPTH          => $$settings{depth},
    VISIT_CALLBACK => sub{
      my ( $url, $depth, $html, $links ) = @_;
      my $htmlStripper = HTML::Strip->new();
      my $text = $htmlStripper->parse($html);
      my @words= grep{/^[a-z]+$/} split(/\s+/, $text);
      $pages{$url} = {html=>$html, text=>$text, words=>\@words, depth=>$depth, links=>$links};

      my $score = $$settings{depth} - $depth + 1;
      $pages{$url}{score} += $score;

      print STDERR ".";
    },
    BROKEN_LINK_CALLBACK => sub{
      my ( $url, $linked_from, $depth ) = @_;

      my $score = $$settings{depth} - $depth + 1;

      $pages{$url}{score} -= $score;
      $pages{$linked_from}{score} -= $score;
    },
  );
  $bot->traverse;
  print STDERR "\n";

  return \%pages;
}

sub usage{
  "$0: crawls a site and mades a simple index
  Usage: $0 [options]
  --depth  1  How many links deep to go
  --site   '' Base URL to search. Use http://.
  --index  '' Output filename
  "
}
