#!/usr/bin/perl
#
# --------------
# USAGE:
#  
#  recent-ntimes.pl [atime|ctime|mtime] PATH
#  recent-ntimes.pl PATH  # defaults to 'atime'
#
#
# Note: for accurate atimes, make sure fs is not mounted with 'noatime' or 'relatime'
#
#   mount -o remount,strictatime /some/mount/point
#
# --------------


use strict;
use warnings;

$| = 1;

use Path::Class qw( file dir );

die "too many arguments\n" if (scalar(@ARGV) > 2);

my $start_dir = pop @ARGV;
die "Must supply a start dir as argument!\n" unless ($start_dir);
$start_dir = dir( $start_dir )->resolve;

my $stat_meth = pop @ARGV || 'atime'; 

die "bad file stat method '$stat_meth' - must me atime, mtime or ctime\n" unless (
  $stat_meth eq 'atime' ||
  $stat_meth eq 'ctime' ||
  $stat_meth eq 'mtime'
);

my @files = ();
my $now = time;

print "Working on $start_dir/ ...\n";
my $c = 0;

$start_dir->recurse(
  depthfirst => 1,
  preorder   => 0,
  callback => sub {
    $c++;
    my $File = shift;
    if (-f $File) {
      my $ntime = $File->stat->$stat_meth;
      push @files, {
        ntime => $ntime,
        diff => ($now - $ntime),
        file => $File
      };
    }
    print "    Processed $c files\t\t\r" if ($c =~ /00$/); # 100 at a time
  }
);

print "    Processed $c files.\n";


print join("\n", '', map {

  my $d = $_->{diff};
  my $dur =
    $d > 2*60*60*24*30*12 ? sprintf('%4s yrs',  int($d/(60*60*24*30*12))) :
    $d > 2*60*60*24*30    ? sprintf('%3s mnths',int($d/(60*60*24*30)))    :
    $d > 2*60*60*24       ? sprintf('%4s days', int($d/(60*60*24)))       :
    $d > 2*60*60          ? sprintf('%4s hrs',  int($d/(60*60)))          :
    $d > 99               ? sprintf('%4s min',  int($d/60))               :
  sprintf('%4s sec',$d);

  "[$stat_meth:$dur]  $_->{file}"

} sort { $a->{ntime} <=> $b->{ntime} } @files );

print join(' ',"\n\n",(scalar @files),'files',"\n");

__END__

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

