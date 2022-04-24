unit module RakuFinance;

use Text::Utils :strip-comment;

sub read-config($cfil, :$debug --> Hash) is export {
    my %h;
    my @lines = $cfil.IO.lines;
    LINE: for @lines -> $line is copy {
        $line = strip-comment $line;
        next if $line !~~ /\S/;

        # Symbols are letters or numbers and may have periods for suffixes.
        # All are assumed to have dividends and capital gains reinvested
        # since purchase unless there is a stop date as the second word
        # on the same line as the symbol.
        # The second should be the date (YYYY-MM-DD) when
        # the security stopped having dividends reinvested.

        my @w = $line.uc.words;
        my $sym = @w.shift;
        my $dat = @w.elems ?? @w.shift !! 0; 
        %h{$sym} = $dat;
    }

    if $debug {
        note "DEBUG: dumping config file '$cfil':";
        dump-config  %h;
    }

    %h
} # sub read-config

sub dump-config(%h) is export {
    for %h.keys.sort -> $k {
        print "  $k";
        my $date = %h{$k};
        if $date {
            say " (reinvestment stop date: $date)";
        }
        else {
            say " (all dividends and cap gains are reinvested)";
        }
    }
} # sub dump-config

sub check-config($cfil, :$debug) is export {
    if $cfil.IO.r {
        say "Checking existing file '$cfil'...";
        my %config = read-config $cfil, :$debug;
        say "Dumping $cfil:";
        dump-config %config;
        say "Exiting."; exit;
    }
    else {
        say "Creating empty configuration file '$cfil'...";
        my $fh = open $cfil, :w;

        $fh.print: qq:to/HERE/;
        # Your list of securities of interest are entered here,
        # one per line.  All are assumed to have dividends and 
        # capital gains reinvested since purchase unless there 
        # is a stop date as the second word on the same line as 
        # the symbol. The second word should be the date (in
        # format YYYY-MM-DD) when the security stopped having 
        # dividends reinvested.
        HERE
        $fh.close;
        say "Exiting."; exit;
    }
} # sub check-config
