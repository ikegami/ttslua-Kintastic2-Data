#!perl

use v5.14;
use strict;
use warnings;

use Test::More;

use IPC::Run qw( run );

BEGIN {
   $ENV{DEVEL_TESTS}
      or plan skip_all => "Permission checks are only performed when DEVEL_TESTS=1";

   -e ".git"
      or plan skip_all => "Permission checks are only performed from the repository";

   $^O ne 'MSWin32'
      or plan skip_all => "Permission checks can't be performed on Win32";
}

{
   run [ "git", "ls-files" ],
      \undef,
      \my $output;

   die( "git killed by signal ".( $? && 0x7F )."\n" ) if $? && 0x7F;
   die( "git existed with error ".( $? >> 8 )."\n" )  if $? >> 8;

   my @qfns = split qr/^/m, $output;
   chomp( @qfns );

   for my $qfn ( @qfns ) {
      my @stat = stat( $qfn )
         or do {
            my $e = "$!";
            fail( "stat $qfn" );
            diag( "Can't stat \"$qfn\": $e\n" );
            next;
         };

      my $mode = $stat[ 2 ];
      is( sprintf( "%04o", $mode & 0400 ), '0400', "$qfn is readable" );
      is( sprintf( "%04o", $mode & 0002 ), '0000', "$qfn isn't world writable" );
      if ( $qfn =~ /\.(?:t|pl)\z/ ) {
         is( sprintf( "%04o", $mode & 0100 ), '0100', "$qfn is executable" );
      } else {
         is( sprintf( "%04o", $mode & 0111 ), '0000', "$qfn isn't executable" );
      }
   }

   done_testing();
}
