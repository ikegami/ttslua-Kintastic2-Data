#!perl

use v5.14;
use strict;
use warnings;

use lib "t/lib";

use Test::More;
use Test::Deep qw( false true );

use File::Find::Rule qw( );

use TestUtils qw( basic_test port_check );

if ( !port_check() ) {
   diag( "**********************************************\n" .
         "****     Problem establishing server.     ****\n" .
         "**** Make sure Atom/VSCode isn't running. ****\n" .
         "**********************************************\n" );
}

my @module_qfns =
   File::Find::Rule
      ->relative
      ->file
      ->name( '*.ttslua' )
      ->in( 'lib' );

for my $module_qfn ( @module_qfns ) {
   my $module = $module_qfn =~ s/\.ttslua\z//r =~ s{/}{.}gr;

   basic_test( 'lib', { $module => 'Module' }, $module, "return not not Module", true );
}

done_testing();
