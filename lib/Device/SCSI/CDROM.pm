package Device::SCSI::CDROM;
require 5.005;
use base Device::SCSI;
use strict;
use vars qw( $ID );

$ID=' $Id: CDROM.pm,v 1.1 2001/06/23 01:31:28 abuse Exp $ ';

use Carp;

=head1 NAME

Device::SCSI::CDROM - Perl module to control SCSI CD-ROM devices

=head1 SYNOPSIS

 use Device::SCSI::CDROM;
 # use the same way as Device::SCSI but with extra methods.

=head1 DESCRIPTION

This is an incomplete package that may ultimately provide device-specific
support for CD-ROM and other read-only units. The API is poor and may change
at any time.

=over 4

=item B<disc_info>

 my($first, $last)=$device->disc_info;

This returns the track numbers of the first and last track on the CD
inserted in the drive.

=cut

sub disc_info {
  my $self=shift;
  my($data, $sense)=$self->execute(pack("C x5 C n x", 0x43, 1, 20), 20); # READ TOC
  return undef if $sense->[0];
  my($first, $last)=unpack("x2 C C", $data);
  return($first, $last);
}    

=item B<toc>

 my $tracks=$device->toc;
 my $first=$tracks->{FIRST};
 my $last=$tracks->{LAST};
 foreach my $track ($first..$last, 'CD') {
   my $trackstart=$tracks->{$track}{START};
   my $trackend=$tracks->{$track}{FINISH};
   # use these values
 }

This reads the Table Of Contents on the CD, and returns a hashref containing
information on all thr tracks on the CD. The keys are:

=over 8

=item FIRST

The number of the first track on the CD.

=item LAST

The number of the last track on the CD.

=item CD

A hashref with keys B<START> and B<FINISH> mapping to the block numbers of
the start and end of the CD.

=item (Numbers 1 ... 99)

A hashref with keys B<START> and B<FINISH> mapping to the block numbers of
the start and end of the track with the same number as the key.

=back

=cut

sub toc {
  my $self=shift;
  
  my($first,$last)=($self->disc_info);
  return undef unless defined $last;
  
  my %tracks=(
	      FIRST => $first,
	      LAST => $last,
	     );
  foreach my $track ($first..$last) {
    my($data, $sense)=$self->execute(pack("C x5 C n x", 0x43, $track, 20), 20); # READ TOC
    die "Can't read track $track" if $sense->[0];
    # 2 -> first, 3 -> last 8..11 -> start 16..19 -> end
    my($start, $end)=unpack("x8 N x4 N", $data);
    $tracks{$track}={
		     START => $start,
		     FINISH => $end
		    };
  }
  $tracks{CD}={
	       START => $tracks{$first}{START},
	       FINISH => $tracks{$last}{FINISH}
	      };
  
  return \%tracks;
}

=back

=head1 AUTHOR

All code and documentation by Peter Corlett <abuse@cabal.org.uk>.

=head1 COPYRIGHT

Copyright (C) 2000-2004 Peter Corlett <abuse@cabal.org.uk>. All
rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SUPPORT / WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=cut

1;
