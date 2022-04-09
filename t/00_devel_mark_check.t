#!perl

use v5.14;
use strict;
use warnings;

use Test::More;

use IPC::Run qw( run );

BEGIN {
   $ENV{DEVEL_TESTS}
      or plan skip_all => "Mark checks are only performed when DEVEL_TESTS=1";

   -e ".git"
      or plan skip_all => "Mark checks are only performed from the repository";
}

sub slurp_file {
   my $qfn = shift;

   open( my $fh, '<', $qfn )
      or die( "Can't open \"$qfn\": $!\n" );

   local $/;
   return <$fh>;
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
      my $file = eval { slurp_file( $qfn ) }
         or do {
            my $e = $@;
            fail( "Read $qfn" );
            diag( $e );
            next;
         };

      ok( $file !~ /~{3}|&{3}/, "$qfn - Has no developer bookmarks" );
   }

   done_testing();
}
