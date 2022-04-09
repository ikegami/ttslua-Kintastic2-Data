#!perl

use v5.14;
use strict;
use warnings;

use lib "t/lib";

use Test::More;
use Test::Deep qw( false true );

use TestUtils qw( basic_test port_check );

if ( !port_check() ) {
   diag( "**********************************************\n" .
         "****     Problem establishing server.     ****\n" .
         "**** Make sure Atom/VSCode isn't running. ****\n" .
         "**********************************************\n" );
}

my @tests = (
   [
      'queue',
      '
         local rv = { }

         local q = Queue:new()
         q:enqueue( "a" )
         q:enqueue( "b" )
         q:enqueue( "c" )

         while not q:is_empty() do
            table.insert( rv, q:dequeue() )
         end

         return rv
      ',
      [ "a", "b", "c" ]
   ]
);

for ( @tests ) {
   basic_test( 'lib', 'Kintastic2.Data.Queue', @$_ );
}

done_testing();
