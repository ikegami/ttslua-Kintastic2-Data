#!perl

use v5.14;
use strict;
use warnings;

use Test::More;

use IPC::Run qw( run );

BEGIN {
   $ENV{DEVEL_TESTS}
      or plan skip_all => "Whitespace checks are only performed when DEVEL_TESTS=1";

   -e ".git"
      or plan skip_all => "Whitespace are only performed from the repository";
}

sub slurp_file {
   my $qfn = shift;

   open( my $fh, '<:raw', $qfn )
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

      ok( $file !~ /\r/, "$qfn - Unix line endings" );

      ok( substr( $file, -1 ) eq "\n", "$qfn - Ends in a line feed" );

      ok( $file !~ /(?:[^\S\r\n]|[^\S\n]\r)\n/, "$qfn - No trailing whitespace" );
   }

   done_testing();
}
