# intranet-crawler

Crawl the intranet and create a database structure.
Crawling takes a long time especially at depths > 3.
Run with `perl scripts/crawlIntranet.pl --help` for usage.

## Dependencies

Uses some non-core perl modules.
Install with cpanm

    cpanm WWW::SimpleRobot HTML::Strip --verbose

## Example crawling

    perl scripts/crawlIntranet.pl --depth 1 --site http://about.google/ --index data/intranet.1depth.tsv
    # Apply scores to make searching better
    perl scripts/addScoresToDatabase.pl data/intranet.1depth.tsv > data/intranet.1depth.scores.tsv

## Database structure

Tab seprated file of 

    word  url  [score]

Where score is present only if you ran `addScoresToDatabase.pl`

## Example queries

Search results will include the URL and the search score.

    $ perl scripts/search.pl --depth 1 --numhits 10 ambitious leadership
    search.pl: Total hits found: 2. Displaying up to the top 10 hits.
    https://sustainability.google/  0.555248061
    https://diversity.google/annual-report/ 0.27038993

    
