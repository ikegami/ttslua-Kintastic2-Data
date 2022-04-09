#!/usr/bin/perl

# Note: This doesn't delete documents
# generated from files that no longer
# exist.

use v5.14;
use strict;
use warnings;

use File::Basename   qw( fileparse );
use File::Find::Rule qw( );
use File::Path       qw( make_path );
use FindBin          qw( $RealBin );


sub slurp_file {
   my $qfn = shift;

   open( my $fh, '<:encoding(UTF-8)', $qfn )
      or die( "Can't open \"$qfn\": $!\n" );

   local $/;
   return <$fh>;
}


sub create_file {
   my $qfn  = shift;
   my $file = shift;

   open( my $fh, '>:raw:encoding(UTF-8)', $qfn )
      or die( "Can't create \"$qfn\": $!\n" );

   print( $fh $file )
      or die( "Can't write to \"$qfn\": $!\n" );

   close( $fh )
      or die( "Can't write to \"$qfn\": $!\n" );
}


sub trim { shift =~ s/^\s+//r =~ s/\s+\z//r }


# Very inaccurate, but good enough to handle what we have.
sub title_to_anchor { lc(trim( shift )) =~ s/[^a-z0-9]//rg =~ s/[ ]/-/rg }


sub extract_toc {
   my $counts    = shift;
   my $line_num  = shift;
   my $doc_block = shift;

   my $toc = '';

   for ( $doc_block ) {
      while ( 1 ) {
         /\G \z /xsgc
            and last;

         if ( /\G ( ^ | \n ) /xsmgc ) {
            my $line_end = $1;
            $line_num += $line_end =~ tr/\n//;

            if ( /\G ( \#+ ) /xsgc ) {
               my $marker = $1;

               my $level = length( $marker );
               $level <= @$counts + 1
                  or die( "Skipped header level at line $line_num\n" );

               ++$counts->[ $level - 1 ];
               splice( @$counts, $level );

               /\G [ ] ( [^\n]+ ) \n /xsgc
                  or die( "Inscrutable header at line $line_num\n" );

               my $title = $1;
               ++$line_num;

               my $anchor = title_to_anchor( $title );

               $toc .= ( ( "    " ) x ( $level - 1 ) ) . "$counts->[ -1 ]. [$title](#$anchor)\n";
            }

            next;
         }

         if ( /\G ( `+ ) /xsgc ) {
            my $delim = $1;

            /\G ( .*? ) \Q$delim\E /xsgc
               or die( "Unterminated code block at line $line_num\n" );

            my $code = $delim . $1 . $delim;

            $line_num += $code =~ tr/\n//;
            next;
         }

         /\G [^\n`]+ /xsgc
            or die;
      }
   }

   return $toc;
}


sub extract_doc {
   my $file = shift;

   chomp( $file );
   $file .= "\n";

   my $line_num = 1;
   my @counts = 1;

   my $name;
   my $desc;
   my $doc = qq{<a name="name-and-description"></a>\n};
   my $toc = "1. [NAME AND DESCRIPTION](#name-and-description)\n";

   my @lines = split qr/^/m, $file;
   my $block_line_num = 0;
   my $first = 1;
   for my $line_num ( 1 .. @lines ) {
      my $line = $lines[ $line_num - 1 ];

      if ( $block_line_num ) {
         if ( $line =~ / ^ \]==\] /x ) {
            my $block = join( "", @lines[ $block_line_num+1-1 .. $line_num-1-1 ] );
            $doc .= ( $first ? "" : "\n" ) . $block;

            if ( $first ) {
               my $title = $lines[ $block_line_num+1-1 ];
               ( $name, $desc ) = $title =~ / ^ (\S+) \s+ - \s+ (\S.*) /x
                  or die( "Can't parse title.\n" );

               $first = 0;
            }

            $toc .= extract_toc( \@counts, $block_line_num+1, $block );
            $block_line_num = 0;
         }
      } else {
         if ( $line =~ / ^ --\[==\[ /x ) {
            $block_line_num = $line_num;
         }
      }
   }

   !$block_line_num
      or die( "Unterminated documentation block at line $block_line_num.\n" );

   !$first
      or die( "No documentation found.\n" );

   $doc =~ s/ ^ \[\[TOC\]\] \n /$toc/xm
      or die( "Missing [[TOC]] tag.\n ");

   return ( $name, $desc, $doc );
}


{
   my $lib_dir_qfn = "$RealBin/lib";
   my $doc_dir_qfn = "$RealBin/doc";

   my $errors = 0;

   my $docs = '';

   for my $rel_qfn (
      sort
         File::Find::Rule
         ->relative
         ->file
         ->name( '*.ttslua' )
         ->in( $lib_dir_qfn )
   ) {
      my ( $fn, $rel_dir_qfn ) = fileparse( $rel_qfn, '.ttslua' );
      $rel_dir_qfn =~ s{/\z}{};

      my $src_qfn     = "$lib_dir_qfn/$rel_qfn";
      my $dst_dir_qfn = "$doc_dir_qfn/$rel_dir_qfn";
      my $dst_qfn     = "$doc_dir_qfn/$rel_dir_qfn/$fn.md";
      my $rel_dst_qfn = "doc/$rel_dir_qfn/$fn.md";

      eval {
         my $file = slurp_file( $src_qfn );

         make_path( $dst_dir_qfn, { error => \my $err } );
         if ( $err && @$err ) {
            die( "Can't create path \"$dst_dir_qfn\": $err->[0]\n" );
         }

         my ( $name, $desc, $doc ) = extract_doc( $file );

         create_file( $dst_qfn, $doc );

         $docs .= "* [$name]($rel_dst_qfn#name-and-description) - $desc\n";
      };

      if ( $@ ) {
         ++$errors;
         warn( "Can't extract documentation from \"$src_qfn\": $@" );
      }
   }

   {
      my $qfn = "$RealBin/README.md";

      eval {
         my $file = slurp_file( $qfn );

         $file =~ s{
            ^ \#[ ]DOCUMENTATION\n \K
            (?: (?! \# ) [^\n]* \n )*
         }{
            "\n"  .
            $docs .
            "\n"  .
            "\n"
         }xme
            or die( "Can't find DOCUMENTATION section.\n" );

         my $toc = "1. [NAME AND DESCRIPTION](#name-and-description)\n";
         $toc .= extract_toc( [ 1 ], 1, $file );

         $file =~ s{
            ^ \#[ ]TABLE[ ]OF[ ]CONTENTS\n \K
            (?: (?! \# ) [^\n]* \n )*
         }{
            "\n" .
            $toc .
            "\n" .
            "\n"
         }xme
            or die( "Can't find TABLE OF CONTENTS section.\n" );

         create_file( $qfn, $file );
      };

      if ( $@ ) {
         ++$errors;
         warn( "Can't update README.md: $@" );
      }
   }

   exit( 1 ) if $errors;
}
