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
   [ 'new - no arg', 'local set = Set:new(                 );  local vals = set:get_values();  table.sort( vals );  return vals', [               ] ],
   [ 'new - empty',  'local set = Set:new({               });  local vals = set:get_values();  table.sort( vals );  return vals', [               ] ],
   [ 'new',          'local set = Set:new({ "a", "b", "c" });  local vals = set:get_values();  table.sort( vals );  return vals', [ "a", "b", "c" ] ],
   [ 'new - dups',   'local set = Set:new({ 1, 1, 2, 3    });  local vals = set:get_values();  table.sort( vals );  return vals', [ 1, 2, 3       ] ],

   [ 'add',          'local set = Set:new({ "a", "b", "c" });  set:add( "d" );             local vals = set:get_values();  table.sort( vals );  return vals', [ "a", "b", "c", "d"      ] ],
   [ 'add - empty',  'local set = Set:new(                 );  set:add( "d" );             local vals = set:get_values();  table.sort( vals );  return vals', [                "d"      ] ],
   [ 'add - dups',   'local set = Set:new({ "a", "b", "c" });  set:add( "c" );             local vals = set:get_values();  table.sort( vals );  return vals', [ "a", "b", "c"           ] ],
   [ 'add - return', 'local set = Set:new({ "a", "b", "c" });  set:add( "d" ):add( "e" );  local vals = set:get_values();  table.sort( vals );  return vals', [ "a", "b", "c", "d", "e" ] ],

   [ 'delete',                'local set = Set:new({ "a", "b", "c" });  set:delete( "a" );                local vals = set:get_values();  table.sort( vals );  return vals', [      "b", "c" ] ],
   [ 'delete - non-existent', 'local set = Set:new({ "a", "b", "c" });  set:delete( "d" );                local vals = set:get_values();  table.sort( vals );  return vals', [ "a", "b", "c" ] ],
   [ 'delete - empty',        'local set = Set:new(                 );  set:delete( "a" );                local vals = set:get_values();  table.sort( vals );  return vals', [               ] ],
   [ 'delete - return',       'local set = Set:new({ "a", "b", "c" });  set:delete( "a" ):delete( "b" );  local vals = set:get_values();  table.sort( vals );  return vals', [           "c" ] ],

   [ 'del',                'local set = Set:new({ "a", "b", "c" });  set:del( "a" );             local vals = set:get_values();  table.sort( vals );  return vals', [      "b", "c" ] ],
   [ 'del - non-existent', 'local set = Set:new({ "a", "b", "c" });  set:del( "d" );             local vals = set:get_values();  table.sort( vals );  return vals', [ "a", "b", "c" ] ],
   [ 'del - empty',        'local set = Set:new(                 );  set:del( "a" );             local vals = set:get_values();  table.sort( vals );  return vals', [               ] ],
   [ 'del - return',       'local set = Set:new({ "a", "b", "c" });  set:del( "a" ):del( "b" );  local vals = set:get_values();  table.sort( vals );  return vals', [           "c" ] ],

   [ 'has - positive', 'local set = Set:new({ "a", "b", "c" });  return set:has( "a" )', true  ],
   [ 'has - negative', 'local set = Set:new({ "a", "b", "c" });  return set:has( "d" )', false ],
   [ 'has - empty',    'local set = Set:new(                 );  return set:has( "a" )', false ],

   [ 'size - empty',     'local set = Set:new(           );  return set:size()', 0 ],
   [ 'size - not empty', 'local set = Set:new({ 2, 4, 6 });  return set:size()', 3 ],

   [ 'values - empty',     'local set = Set:new(                 );  local vals = { };  for value in set:values() do table.insert( vals, value ) end;  table.sort( vals );  return vals', [               ] ],
   [ 'values - not empty', 'local set = Set:new({ "a", "b", "c" });  local vals = { };  for value in set:values() do table.insert( vals, value ) end;  table.sort( vals );  return vals', [ "a", "b", "c" ] ],

   [ 'union',        'local set1 = Set:new({ "a", "b", "c", "d" });  local set2 = Set:new({ "c", "d", "e", "f" });  local set = Set:union( set1, set2 );         local vals = set:get_values();  table.sort( vals );  return vals', [ "a", "b", "c", "d", "e", "f" ] ],
   [ 's+s',          'local set1 = Set:new({ "a", "b", "c", "d" });  local set2 = Set:new({ "c", "d", "e", "f" });  local set = set1 + set2;                     local vals = set:get_values();  table.sort( vals );  return vals', [ "a", "b", "c", "d", "e", "f" ] ],
   [ 'difference',   'local set1 = Set:new({ "a", "b", "c", "d" });  local set2 = Set:new({ "c", "d", "e", "f" });  local set = Set:difference( set1, set2 );    local vals = set:get_values();  table.sort( vals );  return vals', [ "a", "b"                     ] ],
   [ 's-s',          'local set1 = Set:new({ "a", "b", "c", "d" });  local set2 = Set:new({ "c", "d", "e", "f" });  local set = set1 - set2;                     local vals = set:get_values();  table.sort( vals );  return vals', [ "a", "b"                     ] ],
   [ 'intersection', 'local set1 = Set:new({ "a", "b", "c", "d" });  local set2 = Set:new({ "c", "d", "e", "f" });  local set = Set:intersection( set1, set2 );  local vals = set:get_values();  table.sort( vals );  return vals', [           "c", "d"           ] ],
   [ 's*s',          'local set1 = Set:new({ "a", "b", "c", "d" });  local set2 = Set:new({ "c", "d", "e", "f" });  local set = set1 * set2;                     local vals = set:get_values();  table.sort( vals );  return vals', [           "c", "d"           ] ],
);

for ( @tests ) {
   basic_test( 'lib', 'Kintastic2.Data.Set', @$_ );
}

done_testing();
