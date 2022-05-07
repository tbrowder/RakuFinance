unit module FinanceClasses;

#| A class to hold market data for a security for a given
#| date at open, high, or close.
class Price {
    has $.symbol    is required;
    has $.price     is required;
    has Date $.date is required;
    submethod TWEAK { $!symbol .= uc; }
}

class Open is Price {}
class High is Price {}
class Close is Price {}
