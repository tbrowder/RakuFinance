unit module RakuFinance;

use Text::Utils :strip-comment;

sub read-config($cfil, :$debug --> Hash) is export {
    my %h;
    my @lines;
    if $cfil.IO.r {
        @lines = $cfil.IO.lines;
    }
    elsif $cfil ~~ Str {
        @lines = $cfil.lines;
    }

    my $err = 0;
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
        if $dat ~~ /^ (\d**4) '-' (\d\d) '-' (\d\d) $/ {
            my $y = ~$0;
            my $m = ~$1;
            my $d = ~$2;
            # check for valid numbers
            my Date $D;
            try {
                $D = Date.new("$y-$m-$d");
            }
            if $! {
                my $msg = $!.Str;
                say "ERROR: line '$line': $msg";
                ++$err;
            }
            else {
                # date should NOT be in the future
                if $D > DateTime.now.Date {
                    say "ERROR: line '$line': A future date is illegal.";
                }
        
            }
        }
        else {
            say "ERROR: line '$line' has the wrong date format (should be YYYY-MM-DD)";
            ++$err;
        }
        %h{$sym} = $dat;
    }

    if $err {
        die qq:to/HERE/;
        FATAL: Bad portfolio data file: '$cfil':
               Invalid format on one or more date lines.
        HERE
        #fail;
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
        say "Checking existing file '$cfil'..." if $debug;
        my %config = read-config $cfil, :$debug;
        if $debug {
            say "Dumping $cfil:";
            dump-config %config;
            say "DEBUG Exiting."; exit;
        }
    }
    else {
        say "Creating empty portfolio file '$cfil'..." if $debug;
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
        if $debug {
            say "DEBUG: Exiting."; exit;
        }
    }
} # sub check-config
