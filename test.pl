# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Test;
BEGIN { plan tests => 32 };
use Array::Splice qw ( splice_aliases push_aliases unshift_aliases );

# Initial tests cribbed from t/op/splice.t in the Perl distribution
my @a = (1..10);

sub j { join(":",@_) }

print "not " unless j(splice_aliases(@a,@a,0,11,12)) eq "" && j(@a) eq j(1..12);
print "ok 1\n";

print "not " unless j(splice_aliases(@a,-1,1)) eq "12" && j(@a) eq j(1..11);
print "ok 2\n";

print "not " unless j(splice_aliases(@a,0,1)) eq "1" && j(@a) eq j(2..11);
print "ok 3\n";

print "not " unless j(splice_aliases(@a,0,0,0,1)) eq "" && j(@a) eq j(0..11);
print "ok 4\n";

print "not " unless j(splice_aliases(@a,5,1,5)) eq "5" && j(@a) eq j(0..11);
print "ok 5\n";

print "not " unless j(splice_aliases(@a, @a, 0, 12, 13)) eq "" && j(@a) eq j(0..13);
print "ok 6\n";

print "not " unless j(splice_aliases(@a, -@a, @a, 1, 2, 3)) eq j(0..13) && j(@a) eq j(1..3);
print "ok 7\n";

print "not " unless j(splice_aliases(@a, 1, -1, 7, 7)) eq "2" && j(@a) eq j(1,7,7,3);
print "ok 8\n";

print "not " unless j(splice_aliases(@a,-3,-2,2)) eq j(7) && j(@a) eq j(1,2,7,3);
print "ok 9\n";

print "not " unless push_aliases(@a,9,10) eq '6' && j(@a) eq j(1,2,7,3,9,10);
print "ok 10\n";

print "not " unless unshift_aliases(@a,11,12) eq '8' && j(@a) eq j(11,12,1,2,7,3,9,10);
print "ok 11\n";

my @args;
sub TIEARRAY { bless {} }
sub SPLICE_ALIASES { @args = @_; 7,8,9 } 
tie my @tied, 'main';
print "not " unless j(splice_aliases(@tied,5,10,1,2,3)) eq j(7,8,9) &&
    j(@args) eq j(tied(@tied),5,10,1,2,3);;
print "ok 12\n";

# Check reference counts
my (%destroyed,@expect_to_destroy,@insertion);

sub DESTROY { $destroyed{$_[0]}++ };

sub expect_to_destroy {
    @expect_to_destroy = map { "$_" } @_;
    %destroyed = ();
}

sub were_right_things_destroyed {
    # print "@expect_to_destroy -- @{[ keys %destroyed ]}\n";
    print "not " if ( grep { ! delete $destroyed{$_} } @expect_to_destroy  ) || %destroyed;
}

sub were_right_things_inserted {
    print "not " if @_ != @insertion || grep { \$_ != \shift } @insertion;
    @insertion = ();
}

@a = map { bless [ $_ ] } 1..100;
my @b = map { bless [ $_ ] } 101..200;
my (@foo,$foo);

# Shrink - void context
expect_to_destroy @a[5..9];
splice_aliases @a, 5, 5, splice @b, 0, 2;
were_right_things_destroyed;
print "ok 13\n";

# Shrink - scalar context
expect_to_destroy @a[5..8];
@insertion =  splice @b, 0, 4;
$foo = splice_aliases @a, 5, 5, @insertion;
were_right_things_inserted @a[5..8];
print "ok 14\n";
were_right_things_destroyed;
print "ok 15\n";
expect_to_destroy $foo;
undef $foo;
were_right_things_destroyed;
print "ok 16\n";

# Shrink - list context
expect_to_destroy;
@foo = splice_aliases @a, 5, 5;
were_right_things_destroyed;
print "ok 17\n";
expect_to_destroy @foo;
@foo = ();
were_right_things_destroyed;
print "ok 18\n";

# Same size - void context
expect_to_destroy @a[5..9];
splice_aliases @a, 5, 5, splice @b, 0, 5;
were_right_things_destroyed;
print "ok 19\n";

# Same size - scalar context
expect_to_destroy @a[5..8];
$foo = splice_aliases @a, 5, 5, splice @b, 0, 5;
were_right_things_destroyed;
print "ok 20\n";
expect_to_destroy $foo;
undef $foo;
were_right_things_destroyed;
print "ok 21\n";

# Same size - list context
expect_to_destroy;
@insertion = splice @b, 0, 5;
@foo = splice_aliases @a, 5, 5, @insertion;
were_right_things_inserted @a[5..9];
print "ok 22\n";
were_right_things_destroyed;
print "ok 23\n";
expect_to_destroy @foo;
@foo = ();
were_right_things_destroyed;
print "ok 24\n";

# Grow - void context
expect_to_destroy @a[5..9];
@insertion = splice @b, 0, 10;
splice_aliases @a, 5, 5, @insertion;
were_right_things_inserted @a[5..14];
print "ok 25\n";
were_right_things_destroyed;
print "ok 26\n";

# Grow - scalar context
expect_to_destroy @a[5..8];
$foo = splice_aliases @a, 5, 5, splice @b, 0, 10;
were_right_things_destroyed;
print "ok 27\n";
expect_to_destroy $foo;
undef $foo;
were_right_things_destroyed;
print "ok 28\n";

# Grow - list context
expect_to_destroy;
@foo = splice_aliases @a, 5, 5, splice @b, 0, 10;
were_right_things_destroyed;
print "ok 29\n";
expect_to_destroy @foo;
@foo = ();
were_right_things_destroyed;
print "ok 30\n";

# Pure insertions
splice_aliases @a,0,0,splice @b, 0, 10;
splice_aliases @a,-1,0,splice @b, 0, 10;
splice_aliases @a,5,0,splice @b, 0, 10;

expect_to_destroy @a;
@a = ();
were_right_things_destroyed;
print "ok 31\n";

expect_to_destroy @b;
@b = ();
were_right_things_destroyed;
print "ok 32\n";
