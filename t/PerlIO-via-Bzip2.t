# Tests for PerlIO::via::Bzip2

use blib;

use strict;
use warnings;

use Test::More tests => 11;

BEGIN {
    chdir('t') if -d 't';
    use_ok('PerlIO::via::Bzip2');
};

my $fh;

# Opening/closing
ok(open($fh, "<:via(Bzip2)", "ipsum_small.bz2"), "open for reading");
ok(close($fh), "file close");

is(open($fh, "+<:via(Bzip2)", "ipsum_small.bz2"), undef,
   "cannot read/write a bzip2 file ('+<')");

ok(open($fh, ">:via(Bzip2)", "out.bz2"), "open for write");
ok(close($fh), "file close");

is(open($fh, "+>:via(Bzip2)", "out.bz2"), undef,
   "cannot read/write a bzip2 file ('+>')");

# Decompression
for my $size (qw/small large/) {
    open($fh, "<:via(Bzip2)", "ipsum_$size.bz2");
    open(my $fh_orig, "<", "ipsum_$size.txt");
    {
        local $/ = undef;
        my $orig = <$fh_orig>;
        my $decompressed = <$fh>;
        is($decompressed, $orig, "$size file decompression");
    }
}

# Compression
for my $size (qw/small large/) {
    open(my $fh_orig, "<", "ipsum_$size.txt");
    open(my $fh_orig_cmp, "<", "ipsum_$size.bz2");
    open($fh, ">:via(Bzip2)", "ipsum_" . $size . "_via.bz2");
    {
        local $/ = undef;
        my $orig = <$fh_orig>;
        print {$fh} $orig;
        close($fh);
        open($fh, "<", "ipsum_" . $size . "_via.bz2");
        my $via_cmp = <$fh>;
        my $cmp_orig = <$fh_orig_cmp>;
        ok($via_cmp eq $cmp_orig, "$size file compression");
    }
}


# Cleanup
END {
    unlink "out.bz2";
    for my $size (qw/small large/) {
        unlink "ipsum_" . $size . "_via.bz2";
    }
}
