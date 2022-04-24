unit module YahooFinance;;

use Text::Utils :normalize-string;


#| Define specific names for data files and their default subdirectories
sub get-infil-names($Symbol, :$dir = 'data' --> Hash) is export {
    my %ifils = [
        daily => "{$dir}/{$Symbol}-daily.csv",
        split => "{$dir}/{$Symbol}-splits.csv",
        div   => "{$dir}/{$Symbol}-dividends.csv",
        gain  => "{$dir}/{$Symbol}-cap-gains.csv",
        buy   => "{$dir}/{$Symbol}-buys.csv",
        sale  => "{$dir}/{$Symbol}-sales.csv",
        note  => "{$dir}/{$Symbol}-notes.csv",
        #merge => "{$dir}/{$Symbol}-merges.csv",
        # this file has no default directory
        trans => "{$Symbol}-transactions.csv",
    ];
    %ifils
}

#| Define specific names for data files and their default subdirectories
sub get-outfil-names($Symbol, :$dir = 'testout' --> Hash) is export {
    my %ofils = [
        daily => "{$dir}/{$Symbol}-daily.csv",
        split => "{$dir}/{$Symbol}-splits.csv",
        div   => "{$dir}/{$Symbol}-dividends.csv",
        gain  => "{$dir}/{$Symbol}-cap-gains.csv",
        buy   => "{$dir}/{$Symbol}-buys.csv",
        sale  => "{$dir}/{$Symbol}-sales.csv",
        # this file has no default directory
        trans => "{$Symbol}-transactions.csv",
    ];
    %ofils
}

my $debug = 0;

role Note {
    has $.Note is rw = "";;
}

role Event {
    has $.Name;
}

role Data {
    has $.Symbol is required;
    has $.Date   is required;
}

role Trade does Note {
    # used by Buy or Sale
    has $.Symbol is required;
    has $.Date   is required;
    has $.Shares is required;
}

# in the sales file
# headers: Date,Shares,Proceeds
class Sale does Trade does Event is export {
    has $.Proceeds is required;
    submethod TWEAK { $!Name = 'SA' }
    method write-header($fh) {
        $fh.say: "Date,Shares,Proceeds,Note"
    }
    method write-data($fh) {
        $fh.print: qq:to/HERE/;
        {self.Date},{self.Shares},{self.Proceeds},{self.Note}
        HERE
    }
}

# in the buys file
# headers: Date,Shares,TotalCost
class Buy does Trade does Event is export {
    has $.TotalCost is required;
    submethod TWEAK { $!Name = 'B' }
    method write-header($fh) {
        $fh.say: "Date,Shares,TotalCost,Note"
    }
    method write-data($fh) {
        $fh.print: qq:to/HERE/;
        {self.Date},{self.Shares},{self.TotalCost},{self.Note}
        HERE
    }
}

# in the .daily file
# headers: Date,Open,High,Low,Close,Adj Close,Volume
class Quote does Data is export {
    has $.Open      is required;
    has $.High      is required;
    has $.Low       is required;
    has $.Close     is required;
    has $.Adj-Close is required;
    has $.Volume    is required;

    method write-header($fh) {
        $fh.print: qq:to/HERE/;
        Date,Open,High,Low,Close,Adj Close,Volume
        HERE
    }
    method write-data($fh) {
        $fh.print: qq:to/HERE/;
        {self.Date},{self.Open},{self.High},{self.Low},{self.Close},{self.Adj-Close},{self.Volume}
        HERE
    }
}

# in the .mergers file
# headers: Date,Stock Splits
# ??? see Yahoo Finance
class Merger does Data does Event is export {
    has $.Merger is required;
    submethod TWEAK { $!Name = 'M' }
}

# in the .splits file
# headers: Date,Stock Splits
class Split does Data does Event is export {
    has $.Split is required;
    submethod TWEAK { $!Name = 'SP' }

    method write-header($fh) {
        $fh.print: qq:to/HERE/;
        Date,Stock Splits
        HERE
    }
    method write-data($fh) {
        $fh.print: qq:to/HERE/;
        {self.Date},{self.Split}
        HERE
    }
}

# in the .dividends file
# headers: Date,Dividends
class Dividend does Data does Event is export {
    has $.Dividend is required;
    submethod TWEAK { $!Name = 'D' }

    method write-header($fh) {
        $fh.print: qq:to/HERE/;
        Date,Dividends
        HERE
    }
    method write-data($fh) {
        $fh.print: qq:to/HERE/;
        {self.Date},{self.Dividend}
        HERE
    }
}

# in the cap gains file
# headers: Date,Capital Gains
class CapGain does Data does Event is export  {
    has $.Gain is required;
    submethod TWEAK { $!Name = 'G' }

    method write-header($fh) {
        $fh.print: qq:to/HERE/;
        Date,Capital Gains
        HERE
    }
    method write-data($fh) {
        $fh.print: qq:to/HERE/;
        {self.Date},{self.Gain}
        HERE
    }
}

class Transaction does Note does Event is export {
    has $.Date   is required;
    has $.Symbol is required;

    # has at least one of the following types
    # but no more than one of each
    # each has a setter method          # Transaction object attrs:
    has Buy      $.buy;    # .TotalCost,.Shares # self.b-shares, self.b-cost
    has Sale     $.sale;   # .Shares, .Proceeds # self.s-shares, self.s-proceeds
    has Split    $.split;  # .Split     # self.splitr
    has Dividend $.divps;  # .Dividend  # self.d-div
    has CapGain  $.gainps; # .Gain      # self.g-gain

    has $.b-shares   = 0;
    has $.b-cost     = 0;
    has $.s-shares   = 0;
    has $.s-proceeds = 0;
    has $.splitr     = 0;
    has $.d-div      = 0;
    has $.g-gain     = 0;
    has $.close      = 0;

    # other attributes required for final state for a given date
    # (with corresponding header titles):
    has $.prevtotsh   is rw = 0;
    has $.prevtotcost is rw = 0;
    has $.prevclose   is rw = 0;

    has $.totsh       is rw = 0;
    has $.totcost     is rw = 0;
    submethod TWEAK { $!Name = '' }

    #| call after completing assembly from all events on the same day
    method error-check {
        my @err;
        my $m;
        if self.buy and self.sale {
            $m = "Can't have a buy and a sale on the same day at the moment";
            @err.push: $m;
        }
        elsif self.buy or self.sale {
            if self.split or self.divps or self.gainps {
                $m = "Can't have any other transaction with a buy or sale on the same day at the moment";
                @err.push: $m;
            }
        }
        elsif self.split {
            if self.divps or self.gainps {
                $m = "Can't have any other transaction with a split on the same day at the moment";
                @err.push: $m;
            }
        }
        if @err.elems {
            note "FATAL: Invalid transaction combo(s):";
            note "     $_" for @err;
            die  "Too many errors!\n";
        }
    }

    # desired format:
    # f1         f2     f3    f4         f5          f6    f7        f8       f9         f10       f11    f12
    # Date      ,Symbol,Event,PrevTotSh ,PrevTotCost,Split,GainPerSh,DivPerSh,TotSh     ,TotCost  ,Close, Notes
    # 2002-12-17,TAREX ,(unk),nnnnnn.nnn,nnnnnn.nn  ,ccccc,nnnnnn.nn,nnnn.nn ,nnnnnn.nnn,nnnnnn.nn,
    # .Date      .Symbol .Name .prevtotsh .prevtotcost                        .p
    method write-header($fh) {
        # do it in two chunks due to length
        # first  6 fields (1-6)
        # field:  f1         f2     f3                          f4         f5          f6
        $fh.print: "Date      ,Symbol,Event      ,PrevTotSh ,PrevTotCost,Split ,";

# Date      ,Symbol,Event      ,PrevTotSh ,PrevTotCost,Split ,GainPerSh,DivPerSh,TotSh     ,TotCost  ,Close, Notes
# 1980-01-14,SLASX ,SP:SA:B:G:D,     0.000,       0.00,0.0000,     0.00,    0.18,     0.000,     0.00,  6.890,  6.890

        # second 6 fields (7-12)
        # field   f7        f8       f9         f10       f11    f12
        $fh.say: "GainPerSh,DivPerSh,TotSh     ,TotCost  ,Close  , Notes";
    }

    method write-data($fh) {
        # helper: aliases in proper field (column) order
        # field:  f1         f2     f3    f4         f5          f6
        #         2002-12-17,TAREX ,(unk),nnnnnn.nnn,nnnnnn.nn  ,ccccc,
        my $f1  = sprintf "%-10.10s", self.Date;
        my $f2  = sprintf "%-6.6s",   self.Symbol;
        my $f3  = sprintf "%-11.11s", self.Name; # event or transaction code
        my $f4  = sprintf "%10.3f",   self.prevtotsh;
        my $f5  = sprintf "%11.2f",   self.prevtotcost;
        my $f6  = sprintf "%6.4f",    self.splitr;
        $fh.print: "$f1,$f2,$f3,$f4,$f5,$f6,";

        # field:  f7    f8        f9         f10        f11       f12
        #         ccccc,nnnnnn.nn,nnnnn.nnn ,nnnnnn.nnn,nnnnnn.nn,
        # objects we need a value from:
        my $f7  = sprintf "%9.2f", self.g-gain;
        my $f8  = sprintf "%8.2f", self.d-div;

        my $f9  = sprintf "%10.3f", self.totsh;
        my $f10 = sprintf "%9.2f", self.totcost;
        my $f11 = sprintf "%7.3f", self.close;
        my $f12 = sprintf "%-s", self.Note;
        $fh.say: "$f7,$f8,$f9,$f10,$f11,$f12";
    }

    method set-split($sp) {
        return if not $sp;
        $!split = $sp if 0;
        # TODO decode into $!splitr
        $!splitr = 0; # FIX!!
    }
    method set-close($close) {
        $!close = $close if $close
    }
    method set-divps($d) {
        $!divps = $d if 0 and $d;
        $!d-div = $d.Dividend;
    }
    method set-gainps($g) {
        $!gainps = $g if 0 and $g;
        $!g-gain = $g.Gain;
    }
    method set-buy($b) {
        $!buy = $b if 0 and $b;
        $!b-shares = $b.Shares;
        $!b-cost   = $b.TotalCost;
    }
    method set-sale($sa) {
        $!sale = $sa if 0 and $sa;
        $!s-shares   = $sa.Shares;
        $!s-proceeds = $sa.Proceeds;

    }
    method set-event-name($enam) {
        $!Name = $enam if $enam
    }
}

sub process-line($line is copy --> List) {
    my @t = $line.split: ',';
    my @data;
    for @t -> $w is copy {
        $w = normalize-string $w;
        @data.push: $w;
    }
    @data
}

sub read-daily($ifil, :$Symbol, :$debug --> Hash) is export {
    my %h;
    my @lines = $ifil.IO.lines;
    my $hdr = @lines.shift;
    return %h if not @lines.elems;

    # process the header
    my @hdrs = process-line $hdr;
    my $nh = @hdrs.elems;

    # process the data
    # headers: Date,Open,High,Low,Close,Adj Close,Volume
    for @lines.kv -> $i, $line is copy {
        # skip blank lines in human-made files
        next if $line !~~ /\S/;
        my @data = process-line $line;
        my $nd   = @data.elems;
        die "FATAL: File '$ifil', line {$i+2}, wrong number elems (should be $nh): $nd"
            if $nd != $nh;
        my $o = Quote.new: :$Symbol,
        :Date(@data[0]),
        :Open(@data[1]),
        :High(@data[2]),
        :Low(@data[3]),
        :Close(@data[4]),
        :Adj-Close(@data[5]),
        :Volume(@data[6]);
        %h{@data[0]} = $o;
    }
    %h

} # sub read-daily

sub read-splits($ifil, :$Symbol, :$debug --> Hash) is export {
    my %h;
    my @lines = $ifil.IO.lines;
    my $hdr = @lines.shift;
    return %h if not @lines.elems;

    # process the header
    # headers: Date,Stock Splits
    my @hdrs = process-line $hdr;
    my $nh   = @hdrs.elems;

    # process the data
    for @lines.kv -> $i, $line is copy {
        # skip blank lines in human-made files
        next if $line !~~ /\S/;
        my @data = process-line $line;
        my $nd   = @data.elems;
        die "FATAL: File '$ifil', line {$i+2}, wrong number elems (should be $nh): $nd"
            if $nd != $nh;
        my $o = Split.new: :$Symbol,
        :Date(@data[0]),
        :Stock-Split(@data[1]);
        %h{@data[0]} = $o;
    }
    %h

} # read-splits

sub read-dividends($ifil, :$Symbol, :$debug --> Hash) is export {
    my %h;
    my @lines = $ifil.IO.lines;
    my $hdr = @lines.shift;
    return %h if not @lines.elems;

    # process the header
    # headers: Date,Dividends
    my @hdrs = process-line $hdr;
    my $nh = @hdrs.elems;

    # process the data
    # headers: Date,Dividends
    for @lines.kv -> $i, $line is copy {
        # skip blank lines in human-made files
        next if $line !~~ /\S/;
        my @data = process-line $line;
        my $nd   = @data.elems;
        die "FATAL: File '$ifil', line {$i+2}, wrong number elems (should be $nh): $nd"
            if $nd != $nh;
        my $o = Dividend.new: :$Symbol,
        :Date(@data[0]),
        :Dividend(@data[1]);
        %h{@data[0]} = $o;
    }
    %h

} # read-dividends

sub read-buys($ifil, :$Symbol, :$debug --> Hash) is export {
    my %h;
    my @lines = $ifil.IO.lines;
    my $hdr = @lines.shift;
    return %h if not @lines.elems;

    # process the header
    # headers: Date,Shares,TotalCost
    my @hdrs = process-line $hdr;
    my $nh = @hdrs.elems;

    # process the data
    # headers: Date,Shares,TotalCost
    for @lines.kv -> $i, $line is copy {
        # skip blank lines in human-made files
        next if $line !~~ /\S/;
        my @data = process-line $line;
        my $nd   = @data.elems;
        die "FATAL: File '$ifil', line {$i+2}, wrong number elems (should be $nh): $nd"
            if $nd != $nh;
        my $o = Buy.new: :$Symbol,
        :Date(@data[0]),
        :Shares(@data[1]),
        :TotalCost(@data[2]);
        %h{@data[0]} = $o;
    }
    %h

} # read-buys

sub read-sales($ifil, :$Symbol, :$debug --> Hash) is export {
    my %h;
    my @lines = $ifil.IO.lines;
    my $hdr = @lines.shift;
    return %h if not @lines.elems;

    # process the header
    # headers: Date,Shares,Proceeds
    my @hdrs = process-line $hdr;
    my $nh = @hdrs.elems;

    # process the data
    # headers: Date,Shares,Proceeds
    for @lines.kv -> $i, $line is copy {
        # skip blank lines in human-made files
        next if $line !~~ /\S/;
        my @data = process-line $line;
        my $nd   = @data.elems;
        die "FATAL: File '$ifil', line {$i+2}, wrong number elems (should be $nh): $nd"
            if $nd != $nh;
        my $o = Sale.new: :$Symbol,
        :Date(@data[0]),
        :Shares(@data[1]),
        :Proceeds(@data[2]);
        %h{@data[0]} = $o;
    }
    %h

} # read-sales

sub read-cap-gains($ifil, :$Symbol, :$debug --> Hash) is export {
    my %h;
    my @lines = $ifil.IO.lines;
    my $hdr = @lines.shift;
    return %h if not @lines.elems;

    # process the header
    # headers: Date,Capital Gains
    my @hdrs = process-line $hdr;
    my $nh = @hdrs.elems;

    # process the data
    # headers: Date,Capital Gains
    for @lines.kv -> $i, $line is copy {
        # skip blank lines in human-made files
        next if $line !~~ /\S/;
        my @data = process-line $line;
        my $nd   = @data.elems;
        die "FATAL: File '$ifil', line {$i+2}, wrong number elems (should be $nh): $nd"
            if $nd != $nh;
        my $o = CapGain.new: :$Symbol,
        :Date(@data[0]),
        :Gain(@data[1]);
        %h{@data[0]} = $o;
    }
    %h

} # read-cap-gains
