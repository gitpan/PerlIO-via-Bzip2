package PerlIO::via::Bzip2;

use 5.008000;
use strict;
use warnings;

use Compress::Bzip2 ();

our $VERSION = '0.01';

my $BUF_SIZE = 8192;


sub PUSHED {
    my ($class, $mode, $fh) = @_;

    my $self = {
        buf  => '',
        mode => $mode,
    };
    if ($mode eq 'r') {
        $self->{stream} = Compress::Bzip2::decompress_init() or return -1;
    }
    elsif ($mode eq 'w') {
        $self->{stream} = Compress::Bzip2::compress_init() or return -1;
    }
    else {
        return -1;
    }
    return bless $self => $class;
}


# Dummy function.  If not present, we get popped when binmode() is called.
sub BINMODE {
    return 0;
}


sub FILL {
    my ($self, $fh) = @_;

    my ($data);
    my $stream = $self->{stream};
    if ($stream and (read($fh, $data, $BUF_SIZE) > 0)) {
        return $stream->add($data);
    }
    elsif ($stream) {
        $self->{stream} = undef;
        return $stream->finish;
    }
    else {
        return;
    }
}


sub WRITE {
    my ($self, $buf, $fh) = @_;

    my $data = $self->{stream}->add($buf);
    return if not defined $data;
    return (print {$fh} $data) ? 1 : 0;
}


sub FLUSH {
    my ($self, $fh) = @_;

    return 0 if $self->{mode} eq 'r';
    my $data = $self->{stream}->finish;
    if ($data) {
        return (print {$fh} $data) ? 0 : -1;
    }
    return 0;
}

1;
__END__

=head1 NAME

PerlIO::via::Bzip2 - PerlIO::via layer for Bzip2 (de)compression

=head1 SYNOPSIS

    # Read a bzip2 compressed file from disk.
    open(my $fh, "<:via(Bzip2)", "compressed_file");
    my $uncompressed_data = <$fh>;

    # Compress data on-the-fly to a bzip2 compressed file on disk.
    open(my $fh, ">:via(Bzip2)", "compressed_file");
    print {$fh} $uncompressed_data;

=head1 DESCRIPTION

This module implements a PerlIO layer which will let you handle
bzip2 compressed files transparently.

=head1 BUGS

Using binmode() on an opened file for compression will pop (remove)
the layer.

=head1 PREREQUISITES

This module requires Compress::Bzip2 version 1.03.

=head1 SEE ALSO

L<PerlIO::via>

=head1 AUTHOR

Arjen Laarhoven, E<lt>arjen@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Arjen Laarhoven

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
