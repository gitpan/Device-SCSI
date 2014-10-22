package Device::SCSI::linux;
require 5.005;
use strict;
use fields qw( fh name );
use vars qw( $VERSION );
# $Id: linux.pm,v 1.1 2004/07/15 09:22:23 abuse Exp $
$VERSION = do { my @r=(q$Revision: 1.1 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

use Carp;
use Fcntl ':mode';

=head1 NAME

Device::SCSI::linux - Perl module providing Linux-specific SCSI support

=head1 SYNOPSIS

Don't use this, use Device::SCSI instead.

=head1 DESCRIPTION

This is the Linux-specific SCSI driver that is called upon by the
Device::SCSI module. Normal programs should not use this class
directly. Methods within are documented in the Device::SCSI man page.

=cut

# Returns the list of valid device nodes. This sets a hard upper limit on
# the number of devices, but then again, scanning all those /dev/sg* files
# takes ages too. Something clever scanning /dev/ would be, erm, clever.
sub enumerate {
  opendir DIR, "/dev" or croak "Can't read /dev: $!";
  my %devs;
  foreach my $file (sort readdir DIR) {
    my @stat=lstat "/dev/$file";
    next unless scalar @stat;	# next if stat() failed
    next unless S_ISCHR($stat[2]); # next if file isn't character special
    my $major=int($stat[6]/256);
    next unless $major==21; # major number of /dev/sg* is 21
    my $minor=$stat[6]%256;
    next if exists $devs{$minor};
    $devs{$minor}=$file;
  }
  return map {$devs{$_}} sort {$a<=>$b} keys %devs;
}

sub open {
  my Device::SCSI::linux $self=shift;
  my $handle=shift;
  $self->close() if defined $self->{fh};
  if (defined $handle) {
    my $fh=new IO::File("+</dev/$handle");
    return unless defined $fh;
    $self->{fh}=$fh;
    $self->{name}=$handle;
  }
  return $self;
}

sub close {
  my Device::SCSI::linux $self=shift;

  undef $self->{fh};
}

sub execute {
  my Device::SCSI::linux $self=shift;
  croak "Not a reference" unless ref $self;
  my($command, $wanted, $data)=@_;
  
  croak "SCSI command must be 10 or 12 bytes"
    unless(length $command==10 || length $command);
  $data='' unless defined $data;
  
  my $packet=pack("i4 I x16",
		  36+length($command.$data),
		  36+$wanted, 0, 0,
		  length($command)==12?1:0
		 );
  my $iobuf=$packet.$command.$data;
  my $ret=syswrite $self->{fh}, $iobuf, length($iobuf);
  croak "Can't write to $self->{name}: $!"
    unless defined $ret;
  $ret=sysread $self->{fh}, $iobuf, length($packet)+$wanted;
  croak "Can't read from $self->{name}: $!"
    unless defined $ret;
  my @data=unpack("i4 I C16", substr($iobuf, 0, 36));
  croak "SCSI I/O error $data[3] on $self->{name}"
    if $data[3];
  
  return (substr($iobuf, 36), [ @data[5..20] ]);
}

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
