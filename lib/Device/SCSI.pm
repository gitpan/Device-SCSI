package Device::SCSI;
require 5.005;
use strict;
use vars qw( $VERSION @ISA );
# $Id: SCSI.pm,v 1.1 2004/07/15 09:22:22 abuse Exp $
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Carp;

# This kludge attempts to load a module with the same name as the OS type.
# (e.g. SCSI::linux) and then makes this a subclass of that, so we get its
# methods

BEGIN {
  eval { require "Device/SCSI/".lc "$^O.pm" };
  if ($@) {
    croak "There doesn't seem to be a (working) SCSI driver for \"$^O\":\n$@";
  }
  eval "use base 'Device::SCSI::$^O'";
  croak $@ if $@;
}

=head1 NAME

Device::SCSI - Perl module to control SCSI devices

=head1 SYNOPSIS

  use Device::SCSI;

  @devices = Device::SCSI->enumerate;

  $device = Device::SCSI->new($devices[0]);
  %inquiry = %{ $device->inquiry };
  ($result, $sense) = $device->execute($command, $wanted, $data);
  $device->close;

=head1 DESCRIPTION

This Perl library uses Perl5 objects to make it easy to perform low-level
SCSI I/O from Perl, avoiding all the black magic and fighting with C. The
object-oriented interface allows for the application to use more than one
SCSI device simultaneously (although this is more likely to be used by the
application to cache the devices it needs in a hash.)

As well as the general purpose execute() method, there are also a number
of other helper methods that can aid in querying the device and debugging.
Note that the goats and black candles usually required to solve SCSI
problems will need to be provided by yourself.

=head1 IMPLEMENTATION

Not surprisingly, SCSI varies sufficiently from OS to OS that each one
needs to be dealt with separately. This package provides the
OS-neutral processing. The OS-specific code is provided in a module
under "Device::SCSI::" that has the same name as $^O does on your
architecture. The Linux driver is called Device::SCSI::linux, for
example.

The generic class is actually made a subclass of the OS-specific class, not
the other way round as one might have expected. In other words, it takes the
opportunity to select its parent after it has started.

=head1 METHODS

=over 4

=item B<new>

    $device = Device::SCSI->new;

    $device = Device::SCSI->new($unit_name);

Creates a new SCSI object. If $unit_name is given, it will try to open it.
On failure, it returns undef, otherwise the object.

=cut

sub new {
  my($pkg, $handle)=@_;
  
  my $self=bless [], $pkg;
  if(defined $handle) {
    return unless $self->open($handle);
  }
  return $self;
}

sub DESTROY {
  my $self=shift;

  $self->close();
}

=item B<enumerate>

    @units = Device::SCSI->enumerate;

Returns a list of all the unit names that can be given to new() and open().
There is no guarantee that all these devices will be available (indeed, this
is unlikely to be the case) and you should iterate over this list, open()ing
and inquiry()ing devices until you find the one you want.

=item B<open>

    $device->open($device_name);

Attempts to open a SCSI device, and returns $device if it can, or undef if
it can't. Reasons for not being able to open a device include it not
actually existing on your system, or you don't have sufficient permissions
to use F</dev/sg?> devices. (Many systems require you to be root to use
these.)

=item B<close>

    $device->close;

Closes the SCSI device after use. The device will also be closed if the
handle goes out of scope.

=item B<execute>

  # Reading from the device only
  ($result, $sense) = $device->execute($command, $wanted);

  # Writing (and possibly reading) from the device
  ($result, $sense) = $device->execute($command, $wanted, $data);

This method sends a raw SCSI command to the device in question. $command
should be a 10 or a 12 character string containing the SCSI command. You
will often use pack() to create this. $wanted indicates how many bytes of
data you expect to receive from the device. If you are sending data to the
device, you also need to provide that data in $data.

The data (if any) returned from the device will be in $result, and the sense
data will appear the array ref $sense. If there is any serious error, for
example if the device cannot be contacted (and the kernel has not paniced
from such hardware failure) then an exception may be thrown.

=item B<inquiry>

    %inquiry = %{ $device->inquiry };

This method provides a simple way to query the device via SCSI INQUIRY
command to identify it. A hash ref will be returned with the following keys:

=over 8

=item DEVICE

A number identifying the type of device, for example 1 for a tape drive, or
5 for a CD-ROM.

=item VENDOR

The vendor name, "HP", or "SONY" for example.

=item PRODUCT

The device product name, e.g. "HP35470A", "CD-ROM CDU-8003A".

=item REVISION

The firmware revision of the device, e.g. "1109" or "1.9a".

=back

=cut

sub inquiry {
  my $self=shift;
  
  my($data, $sense)=$self->execute(pack("C x3 C x5", 0x12, 96), 96); # INQUIRE
  my %enq;
  @enq{qw( DEVICE VENDOR PRODUCT REVISION )}=unpack("C x7 A8 A16 A4", $data);
  return \%enq;
}

=back

=head1 WARNINGS

Playing directly with SCSI devices can be hazardous and lead to loss of
data. Since such things can normally only be done as the superuser (or by
the superuser changing the permissions on F</dev/sg?> to allow mere mortals
access) the usual caveats about working as root on raw devices applies. The
author cannot be held responsible for loss of data or other damages.

=head1 SEE ALSO

The Linux SCSI-Programming-HOWTO (In F</usr/doc/HOWTO/> on Debian Linux,
similar places for other distributions) details the gory details of the
generic SCSI interface that this talks to. Perl advocates will easily notice
how much shorter this Perl is compared to the C versions detailed in that
document.

To do anything more than a bit of hacking, you'll need the SCSI standards
documents. Drafts are apparently available via anonymous FTP from:

  ftp://ftp.cs.tulane.edupub/scsi
  ftp://ftp.symbios.com/pub/standards
  ftp://ftp.cs.uni-sb.de/pub/misc/doc/scsi

There's a Usenet group dedicated to SCSI:

  news:comp.periphs.scsi - Discussion of SCSI-based peripheral devices.

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
