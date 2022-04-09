#!perl

use v5.14;
use strict;
use warnings;

use lib "t/lib";

use Test::More;

use TestUtils qw( bundle execute port_check );

if ( !port_check() ) {
   diag( "**********************************************\n" .
         "****     Problem establishing server.     ****\n" .
         "**** Make sure Atom/VSCode isn't running. ****\n" .
         "**********************************************\n" );
}

{
   my $test = q{return true};

   my $result = eval {
      my $bundled = bundle( $test, 'lib' );
      execute( $bundled );
   };

   my $e = $@ ? "$@" : "";
   chomp( $e );

   is( $e, "", "$test - No exception" );

   ok( $result, "$test - Returned true" );
}

{
   my $test = q{error('Some runtime error')};

   my $result = eval {
      my $bundled = bundle( $test, 'lib' );
      execute( $bundled );
   };

   my $e = $@ ? "$@" : "";
   chomp( $e );

   like( $e, qr/^Runtime error: .*: Some runtime error/, "$test - Runtime error" );
}

{
   my $test = q{foo This_is_an_expected_error};

   my $result = eval {
      my $bundled = bundle( $test, 'lib' );
      execute( $bundled );
   };

   my $e = $@ ? "$@" : "";
   chomp( $e );

   like( $e, qr/^ \s* SyntaxError \b/x, "$test - Compile-time error" );
}

{
   my $test = q{foo This_is_an_expected_error};

   my $result = eval {
      execute( $test, silent => 1 );
   };

   my $e = $@ ? "$@" : "";
   chomp( $e );

   like( $e, qr/^ Compilation[ ]error \b/x, "$test - Compile-time error (No bundling)" );
}

done_testing();
