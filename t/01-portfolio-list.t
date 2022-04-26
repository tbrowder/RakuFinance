use Test;

use RakuFinance;

plan 5;

# test the Portfolio.dat subs
my (@n, @s);
@n[1] = 'invalid date format';
@s[1] = 'xyz 5/12/2002';

@n[2] = 'invalid month';
@s[2] = 'xyz 2002-13-05';

@n[3] = 'invalid day';
@s[3] = 'xyz 2002-02-30';

@n[4] = 'future dates are invalid';
@s[4] = 'xyz 2102-02-30';

for 1..4 -> $n {
    dies-ok {
        my $s = @s[$n];
        my %h = read-config $s;
    }, "{@n[$n]}";
}

my $f = "data/Portfolio.dat";
dies-ok {
    my %h = read-config $f;
}, "bad Portfolio.dat file";

