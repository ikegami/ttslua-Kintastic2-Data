package TestUtils;

use v5.14;
use strict;
use warnings;

use AnyEvent         qw( );
use AnyEvent::Handle qw( );
use AnyEvent::Socket qw( tcp_connect tcp_server );
use Cpanel::JSON::XS qw( );
use Exporter         qw( import );
use IPC::Run         qw( run );
use Test::More       qw( );
use Test::Deep       qw( );

our @EXPORT_OK = qw( basic_test bundle execute port_check text_to_lua_literal );


my $timeout            = 5;
my $tts_server_host    = "127.0.0.1";
my $tts_server_port    = 39999;
my $editor_server_host = "127.0.0.1";
my $editor_server_port = 39998;


sub text_to_lua_literal { '"'.( shift =~ s/(["\\])/\\$1/gr =~ s/\n/\\n/gr ).'"' }


sub port_check {
   eval {
      my $server_up = AnyEvent->condvar();

      my $timer1_guard = AnyEvent->timer(
         after => $timeout,
         cb => sub {
            $server_up->croak( "Timeout" );
         },
      );

      my $timer2_guard;

      my $server_guard = tcp_server( $editor_server_host, $editor_server_port,
         sub {
         },
         sub {
            $timer2_guard = AnyEvent->timer( after => 0.1, cb => $server_up );
         },
      );

      $server_up->recv();
   };

   return !$@;
}


sub bundle {
   my $script  = shift;
   my $lib_qfn = shift;

   my $bundler = $ENV{LUABUNDLER} // "luabundler";

   run [ "luabundler", "bundle", "-p" => "$lib_qfn/?.ttslua" ],
      \$script,
      \my $output,
      \my $error;

   die( $error ) if $error;

   die( "lunbundler killed by signal ".( $? && 0x7F )."\n" ) if $? && 0x7F;
   die( "lunbundler existed with error ".( $? >> 8 )."\n" )  if $? >> 8;

   return $output;
}


sub wrap_script {
   return sprintf(q{local f = function() %s end; local success, rv = pcall(f); result = { success, rv };}, $_[0] );
}


sub execute {
   my $script = shift;
   my %opts   = @_;

   my $silent = $opts{ silent };

   my $wrapped_script = wrap_script( $script );

   my $caller = sprintf(
      q{
         local script = %s
         result = nil
         Global.executeScript( script )
         local msg_data
         if result == nil then
            msg_data = {
               status  = "error",
               err_msg = "Compilation error",
            }
         elseif not result[1] then
            msg_data = {
               status  = "error",
               err_msg = "Runtime error: " .. result[2],
            }
         else
            msg_data = {
               status = "success",
               result = result[2],
            }
         end

         local success, rv = pcall(
            function()
               return JSON.encode( msg_data )
            end
         )

         if not success then
            rv = JSON.encode({
               status  = "error",
               err_msg = "Encoding error: " .. rv,
            })
         end

         return rv
      },
      text_to_lua_literal( $wrapped_script ),
   );

   my $request = Cpanel::JSON::XS->new->encode({
      messageID => 3,
      guid      => "-1",
      script    => $caller,
      returnID => 0,
   });

   my $response;

   my $accept_message = sub {
      my $fh     = shift;
      my $ok_cb  = shift;
      my $err_cb = shift;

      my $message_accepted = AnyEvent->condvar();

      my $buf = undef;

      my $handle;
      $handle = AnyEvent::Handle->new(
         fh => $fh,
         on_error => sub {
            my ( undef, $fatal, $msg ) = @_;
            $handle->destroy();
            $err_cb->( $msg );
         },
         on_eof => sub {
            $handle->destroy();

            if ( !defined( $buf ) ) {
               $err_cb->( "Connection from TTS closed without receiving a message" );
               return;
            }

            my $msg = eval { Cpanel::JSON::XS->new->decode( $buf ) };
            if ( $@ ) {
               chomp( $@ );
               $err_cb->( "Error decoding message from TTS: $@" );
               return;
            }

            $ok_cb->( $msg );
         },
         on_read => sub {
            my ( $handle ) = @_;
            $buf .= substr( $handle->{rbuf}, 0, length( $handle->{rbuf} ), '' );
         }
      );
   };

   my $handle_message = sub {
      my $msg  = shift;
      my $done = shift;

      my $msg_id = $msg->{ messageID };

      if ( $msg_id == 3 ) {  # Error messages
         my $err_msg = $msg->{ error };
         chomp( $err_msg );
         warn( "Received error from TTS: $err_msg\n" ) if !$silent;
      }

      elsif ( $msg_id == 5 ) {  # Execute Lua Code response
         my $data = $msg->{ returnValue };

         $data = eval { Cpanel::JSON::XS->new->decode( $data ) };
         if ( $@ ) {
            chomp( $@ );
            $done->croak( "Error parsing response: $@" );
            return;
         }

         if ( $data->{ status } ne "success" ) {
            my $msg = $data->{ err_msg } // "Unknown error.";
            chomp( $msg );
            $done->croak( $msg );
            return;
         }

         $done->send( $data->{ result } );
      }
   };

   my $done = AnyEvent->condvar();

   my $timer_guard = AnyEvent->timer(
      after => $timeout,
      cb => sub {
         $done->croak( "Timeout" );
      },
   );

   my $server_guard;
   {
      my $server_up = AnyEvent->condvar();

      my $timer1_guard = AnyEvent->timer(
         after => $timeout,
         cb => sub {
            $server_up->croak( "Timeout" );
         },
      );

      my $timer2_guard;

      $server_guard = tcp_server( $editor_server_host, $editor_server_port,
         sub {
            my $fh = shift;
            $accept_message->(
               $fh,
               sub {
                  my $msg = shift;
                  $handle_message->( $msg, $done );
               },
               sub {
                  my $err_msg = shift;
                  $done->croak( $err_msg );

               },
            );
         },
         sub {
            # Give a chance for accept to be called.
            $timer2_guard = AnyEvent->timer( after => 0.1, cb => $server_up );
         },
      );

      $server_up->recv();
   }

   {
      my $request_sent = AnyEvent->condvar();

      my $timer_guard = AnyEvent->timer(
         after => $timeout,
         cb => sub {
            $request_sent->croak( "Timeout\n" );
         },
      );

      my $client_guard = tcp_connect( $tts_server_host, $tts_server_port,
         sub {
            my $fh = shift;

            if ( !$fh ) {
               $request_sent->croak( "Connection to TTS failed" );
               return;
            }

            my $handle = AnyEvent::Handle->new(
               fh => $fh,
               on_error => sub {
                  my ( $handle, $fatal, $msg ) = @_;
                  $request_sent->croak( $msg );
               },
            );

            $handle->push_write( $request );

            $request_sent->();
         },
      );

      $request_sent->recv();
   }

   return $done->recv();
}


my $basic_test_code_tmpl_p1 = <<'EOS';
local preexisting = { }
for sym in ipairs( _G ) do
   preexisting[ sym ] = true
end
EOS

my $basic_test_code_tmpl_p2 = <<'EOS';
local %2$s = require( "%1$s" )
EOS

my $basic_test_code_tmpl_p3 = <<'EOS';
local returned = (
   function()
      %s
   end
)()

local new_syms = { }
for sym in ipairs( _G ) do
   if not preexisting[ sym ] then
      table.insert( new_syms, sym )
   end
end

return {
   returned = returned,
   new_syms = new_syms,
}
EOS


sub basic_test {
   my $lib      = shift;
   my $modules  = shift;
   my $name     = shift;
   my $code     = shift;
   my $expected = shift;

   if ( !ref( $modules ) ) {
      my $pkg = $modules;
      my $var = $pkg =~ s/^.*\.//r;
      $modules = { $pkg => $var };
   }

   my $wrapped_code = join( "\n",
      $basic_test_code_tmpl_p1,
      ( map { sprintf( $basic_test_code_tmpl_p2, $_, $modules->{ $_ } ) } keys( %$modules ) ),
      sprintf( $basic_test_code_tmpl_p3, $code ),
   );

   my $bundled;
   my $result = eval {
      $bundled = bundle( $wrapped_code, $lib );
      execute( $bundled );
   };

   my $e = $@ ? "$@" : "";
   chomp( $e );

   if ( !Test::More::is( $e, "", "$name - No exception" ) ) {
      if ( $ENV{ VERBOSE } ) {
         Test::More::diag( $bundled ? wrap_script( $bundled ) : $wrapped_code );
      }

      return;
   }

   my $returned = $result->{ returned };
   my $new_syms = $result->{ new_syms };

   Test::Deep::cmp_deeply( $returned, $expected, "$name - Result" );

   Test::More::ok( @$new_syms == 0, "$name - Didn't pollute _G" )
      or diag( "New symbols: " . join( ",", @$new_syms ) );
}


1
