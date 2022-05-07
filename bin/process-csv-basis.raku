#!/usr/bin/env raku

use Data::Dump::Tree;

use lib <../lib ./lib>;
use RakuFinance;
use YahooFinance;

constant $pfil = 'Portfolio.dat';
my %syms;

if $pfil.IO.r {
    check-config $pfil;
    %syms = read-config $pfil;
}
else {
    check-config $pfil, :no-say;
}

if not @*ARGS {
    say qq:to/HERE/;
    Usage: {$*PROGRAM.basename} all | <symbol> [options...][debug]

    Processes Yahoo Finance historical data files (daily, splits,
    dividends, and captital gains) for the securities found in
    the user's portfolio file '$pfil'  and can produce output
    showing their bases, gains and losses, and current values. (A
    '$pfil', with instructions, will be created if none exists.)

    Options
      go     - produce a single file showing the basis for the
               input symbol (or all known symbols) [the default]
      check  - produce a duplicate of the input files [a debug feature]
      list   - show the securities in file '$pfil'

    HERE

    exit;
}

my @tgt-syms;
my $tgt    = "all";
my $check  = 0;
my $debug  = 0;
my $list   = 0;
for @*ARGS {
    when /^ d/ { $debug = 1 }
    when /^ c/ {
        $check = 1;
        @tgt-syms.push($_) for %syms.keys;
        $tgt = 'all';
    }
    when /^ l/ { $list = 1 }
    default {
        # expecting either 'all' or a known symbol
        my $opt = $_.uc;
        if $opt ~~ /ALL/ {
            @tgt-syms.push($_) for %syms.keys;
            $tgt = 'all';
        }
        elsif %syms{$opt}:exists {
            $tgt = $opt;
            @tgt-syms.push: $tgt;
        }
        else {
            note "FATAL: unknown option '$opt'";
            note "Known symbols:";
            note "  $_" for %syms.keys.sort;
            exit;
        }
    }
}

# check for mandatory env vars and directories
constant $E1 = 'RakFinPrivDataDir';
constant $E2 = 'RakFinPubDataDir';
constant $D1 = 'public-data';
constant $D2 = '../public-data';
if %*ENV{$E1}:exists {
    # private data
    # TODO make sure its parent is NOT the current working directory
}
else {
    say "WARNING: Cannot find required environment variable '$E1'.";
}

if %*ENV{$E2}:exists {
    # public data
}
elsif $D1.IO.d {
    # public data
}
elsif $D2.IO.d {
    # public data
}
else {
    say "WARNING: Cannot find environment variable '$E2' or local directory '$D1' (or '$D2').";
}

if $list {
   if %syms.elems {
      say "List of your securities in file '$pfil':";
      show-config %syms;
   }
   else {
      say "Your '$pfil' file has no securities listed.";
   }
   exit;
}

# These hashes are collections of hashes
# holding data from Yahoo Finance
# as well as the user's buy/sell inputs
# %h{$Symbol}{$Date} = <object>
my %daily;  # object = Quote
my %splits; # object = Split
my %divs;   # object = Dividend
my %gains;  # object = Gain
my %buys;   # object = Buy
my %sales;  # object = Sale
#my %sdivs;  # object = StockDividend
#my %merges, # object = Merger
my %trans;  # object = Transaction
# group them in a giant hash
my %coll = [
    daily  => %daily,
    split  => %splits,
    divs   => %divs,
    gain   => %gains,
    buy    => %buys,
    sales  => %sales,
    trans  => %trans,
    #merge  => %merges,
    #sdivs  => %sdivs;
];

# read data
my @syms = @tgt-syms.sort;
collect-data @syms,
    :%daily,  # object = Quote
    :%splits, # object = Split
    :%divs,   # object = Dividend
    :%gains,  # object = Gain
    :%buys,   # object = Buy
    :%sales,  # object = Sale
    :$debug
;

if 0 and $debug {
    #note %daily.raku;
    note %divs.raku;
    note %gains.raku;
    note "DEBUG exit after collection"; exit;
}

if $check {
    # write the data and exit
    rewrite-input-data @syms,
        :%daily,  # object = Quote
        :%splits, # object = Split
        :%divs,   # object = Dividend
        :%gains,  # object = Gain
        :%buys,   # object = Buy
        :%sales,  # object = Sale
        #:$debug;
    say q:to/HERE/;
    Finished rewriting input files as a check.
    Now run '$ diff -r data testout' to ensure correctness.
    HERE
    exit;
}

# assemble transactions
note "DEBUG ready to assemble transactions" if $debug;
note "      \@syms.elems = {@syms.elems}" if 0 and $debug;
my @ofils;
for @syms -> $Symbol {
    note "DEBUG assembling transactions for sym '$Symbol'..." if $debug;
    DATE: for %daily{$Symbol}.keys -> $Date {
        # the quote for the security of that day
        my $q = %daily{$Symbol}{$Date};
        my ($sp, $d, $g, $b, $sa);
        $sp = %splits{$Symbol}{$Date}:exists ?? %splits{$Symbol}{$Date} !! 0;
        $d  = %divs{$Symbol}{$Date}:exists   ?? %divs{$Symbol}{$Date}   !! 0;
        $g  = %gains{$Symbol}{$Date}:exists  ?? %gains{$Symbol}{$Date}  !! 0;
        $b  = %buys{$Symbol}{$Date}:exists   ?? %buys{$Symbol}{$Date}   !! 0;
        $sa = %sales{$Symbol}{$Date}:exists  ?? %sales{$Symbol}{$Date}  !! 0;
        my $is-transaction = 0;
        for $sp, $d, $g, $b, $sa -> $v {
            $is-transaction = 1 if $v;
        }
        if not $is-transaction {
            note "DEBUG: no transaction for sym '$Symbol', date '$Date'" if $debug > 1;
            next DATE;
        }

        my $tr; #  = Transaction.new: :$Symbol, :$Date; # ,
        # we may have another transaction on the same day
        # TODO is this even possible with string dates as the hash key???
        if %trans{$Symbol}{$Date}:exists {
            $tr = %trans{$Symbol}{$Date};
        }
        else {
            $tr = Transaction.new: :$Symbol, :$Date;
            %trans{$Symbol}{$Date} = $tr;
        }

        # add child events and
        # assemble the event names

        # commas are the field (column) separators in Yahoo Finance historical data files;
        # but colons are used for word separators within fields
        my $sep = ':';
        my $enam = "";
        if $b {
            note "Found a buy for sym $Symbol";
            $tr.set-buy($b);
            $enam ~= $sep if $enam;
            if $debug {
                ddt $b;
            }
        }
        if $sa {
            note "Found a sell for sym $Symbol";
            $tr.set-sale($sa);
            $enam ~= $sep if $enam;
            $enam ~= $sa.Name;
            if $debug {
                ddt $sa;
            }
        }
        if $sp {
            note "Found a split for sym $Symbol";
            $tr.set-split($sp);
            $enam ~= $sep if $enam;
            $enam ~= $sp.Name;
            if $debug {
                ddt $sp;
            }
        }
        if $d {
            note "Found a dividend for sym $Symbol";
            $tr.set-divps($d);
            $enam ~= $sep if $enam;
            $enam ~= $d.Name;
            if $debug {
                ddt $d;
            }
        }
        if $g {
            note "Found a gain for sym $Symbol";
            $tr.set-gainps($g);
            $enam ~= $sep if $enam;
            $enam ~= $g.Name;
            if $debug {
                ddt $g;
            }
        }
        $tr.set-event-name: $enam;

        $tr.error-check;

        if $debug {
            ddt $tr;
            note "DEBUG AND DUMPING AN ASSEMBLED TRANSACTION";
            #die "DEBUG exit after assembling one transaction\n";
        }

        =begin comment
        # TODO
        # create the max length event name
        # result was 11 chars
        # commas are field separators, Yahoo uses the colon within fields in csv files
        constant \sep = ':';
        my $et = "";
        $sp = Split.new(:Symbol("XXXXX"), :Date("0000-00-00"), :Split(""))    if not $sp;
        $d  = Dividend.new(:Dividend(0),:Symbol("XXXXX"), :Date("0000-00-00")) if not $d;
        $g  = CapGain.new(:Gain(0),:Symbol("XXXXX"), :Date("0000-00-00"))  if not $g;
        $b  = Buy.new(:Shares(0),:TotalCost(0),:Symbol("XXXXX"), :Date("0000-00-00"))      if not $b;
        $sa = Sale.new(:Shares(0),:Proceeds(0), :Symbol("XXXXX"), :Date("0000-00-00"))     if not $sa;

        $et ~= $sp.Name ~ sep;
        $et ~= $d.Name ~ sep;
        $et ~= $g.Name ~ sep;
        $et ~= $d.Name ~ sep;
        $et ~= $sa.Name;
        note "DEBUG max event name is '$et'";
        =end comment

        note "DEBUG: found a transaction for sym '$Symbol', date '$Date'" if $debug;

        if $debug > 1 {
            note $tr.raku if $debug; note "DEBUG exit with successful Transaction creation\n"; exit;
        }
    }
}

# TODO sub write-transactions
say "Writing fund transaction output files...";
for @syms -> $Symbol {

    my %ofils = get-outfil-names($Symbol);
    my $ofil = %ofils<trans>;
    my $fh = open $ofil, :w;
    Transaction.write-header: $fh;
    my @dates = %trans{$Symbol}.keys.sort;

    # we need zero values to compare for the first actual data
    # normally that probably be needed unless the historical
    # data has been tampered with
    my $prev-tr = Transaction.new: :$Symbol, :Date(@dates[0]);

    if 0 and $debug {
        ddt $prev-tr;
        note "DEBUG exit after dumping the default beginning Transaction\n";
        exit;
    }

    # + If a $0.08 cash dividend is distributed on Feb 19
    #   (ex. date) and the Feb 18 ceosing price is $24.96, the
    #  pre-dividend data are multiplied by (1-0.08/24.96) = 0.9968.

    # How to handle a reinvested dividend or capital gain:
    #   div or gain announced on day X as price/share
    #   use the closing price that day to adjust the
    #     associated data:
    #     + deduct the dividend/gain from the previous day's closing
    #       price
    #     + use that value as the current value
    #     + use that value to buy new shares at that
    #   use TD Ameritrade statement for month of December 2000 as
    #     the source (see acc-data/TDAmeritrade-transactions.csv)
    #
    # TODO finish this
    note "Tom, finish here, check work...";
    sub calc-div-alloc($prev-close, $div-per-sh) {
    }
    sub calc-gain-alloc() {
    }
    sub calc-split-alloc() {
    }

    DATE: for @dates.kv -> $i is copy, $Date {
        ++$i;
        my $tr = %trans{$Symbol}{$Date};
        # we have to fill in the empty values from the pieces
        $tr.prevtotsh   = $prev-tr.totsh;
        $tr.prevtotcost = $prev-tr.totcost;
        $tr.prevclose   = $prev-tr.close;

        my $totshares = $tr.totsh;
        my $totcost   = $tr.totcost;
        my $close     = $tr.close; # per share

        my $gainps    = $tr.g-gain;
        my $divps     = $tr.d-div;

        if $debug {
            say qq:to/HERE/;
            Transaction $i
            ============================
            prev-shares = $prev-tr.totsh
            prev-cost   = $prev-tr.totcost
            prev-close  = $prev-tr.close

            totshares   = $tr.totsh
            totcost     = $tr.totcost
            close       = $tr.close # per share

            b-shares    = $tr.b-shares
            b-cost s    = $tr.b-cost
            s-shares    = $tr.s-shares
            s-proceeds  = $tr.s-proceeds
            splitr      = $tr.splitr
            gainps      = $tr.g-gain
            divps       = $tr.d-divp
            close       = $tr.close
            HERE
        }

        # put in new data

        $tr.write-data: $fh;

        #if 0 and $debug and $i == 19 {
        if $debug {
            #ddt $tr;
            say $tr.raku;
            $fh.close;
            say note "DEBUG exit after dumping Transaction $i after writing its final output\n";
            exit;
        }


        $prev-tr = $tr;
        next DATE;
    }
    $fh.close;
}

if 0 and $debug {
    note %trans;
    note "DEBUG exit after dumping \%trans..."; exit;
}

sub collect-data(@syms,
    :%daily!,  # object = Quote
    :%splits!, # object = Split
    :%divs!,   # object = Dividend
    :%gains!,  # object = Gain
    :%buys!,   # object = Buy
    :%sales!,  # object = Sale
    #:%trans!,  # object = Transaction
    :$debug,
    ) is export {

    for @syms -> $Symbol {
        say "Collecting input data for security $Symbol...";

        my %ifils = get-infil-names($Symbol);

        # read each type of input file
        %daily{$Symbol}  = read-daily %ifils<daily>, :$Symbol, :$debug;
        %splits{$Symbol} = read-splits %ifils<split>, :$Symbol, :$debug;
        %divs{$Symbol}   = read-dividends %ifils<div>, :$Symbol, :$debug;
        %gains{$Symbol}  = read-cap-gains %ifils<gain>, :$Symbol, :$debug;
        %buys{$Symbol}   = read-buys %ifils<buy>, :$Symbol, :$debug;
        %sales{$Symbol}  = read-sales %ifils<sale>, :$Symbol, :$debug;
    }

} # sub collect-data

# we've read the files, now do something with the data

sub rewrite-input-data(@syms,
    :%daily!,  # object = Quote
    :%splits!, # object = Split
    :%divs!,   # object = Dividend
    :%gains!,  # object = Gain
    :%buys!,   # object = Buy
    :%sales!,  # object = Sale
    #:%trans!,  # object = Transaction
    :$debug,
    ) is export {

    if $debug {
        #ddt %daily;
        note %divs.raku; note "DEBUG exit"; exit;
        note %daily.raku; note "DEBUG exit"; exit;
    }

    for @syms -> $Symbol {
        my %ofils = get-outfil-names($Symbol);
        # assemble the original files
        my ($ofil, $fh);
        {
            $ofil = %ofils<daily>;
            $fh = open $ofil, :w;
            Quote.write-header: $fh;
            for %daily{$Symbol}.keys.sort -> $date {
                my $o = %daily{$Symbol}{$date};
                $o.write-data: $fh;
            }
            # add empty line to match input data
            $fh.say();
            $fh.close;
        }
        {
            $ofil = %ofils<split>;
            $fh = open $ofil, :w;
            Split.write-header: $fh;
            for %splits{$Symbol}.keys.sort -> $date {
                my $o = %splits{$Symbol}{$date};
                $o.write-data: $fh;
            }
            # add empty line to match input data
            $fh.say();
            $fh.close;
        }
        {
            $ofil = %ofils<div>;
            $fh = open $ofil, :w;
            Dividend.write-header: $fh;
            for %divs{$Symbol}.keys.sort -> $date {
                my $o = %divs{$Symbol}{$date};
                $o.write-data: $fh;
            }
            # add empty line to match input data
            $fh.say();
            $fh.close;
        }
        {
            $ofil = %ofils<gain>;
            $fh = open $ofil, :w;
            CapGain.write-header: $fh;
            for %gains{$Symbol}.keys.sort -> $date {
                my $o = %gains{$Symbol}{$date};
                $o.write-data: $fh;
            }
            # add empty line to match input data
            $fh.say();
            $fh.close;
        }
        {
            $ofil = %ofils<buy>;
            $fh = open $ofil, :w;
            Buy.write-header: $fh;
            for %buys{$Symbol}.keys.sort -> $date {
                my $o = %buys{$Symbol}{$date};
                $o.write-data: $fh;
            }
            # add empty line to match input data
            $fh.say();
            $fh.close;
        }
        {
            $ofil = %ofils<sale>;
            $fh = open $ofil, :w;
            Sale.write-header: $fh;
            for %sales{$Symbol}.keys.sort -> $date {
                my $o = %sales{$Symbol}{$date};
                $o.write-data: $fh;
            }
            # add empty line to match input data
            $fh.say();
            $fh.close;
        }
    }
} # sub rewrite-input-data
