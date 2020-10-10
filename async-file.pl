package WebTail;
use FindBin;

use lib "$FindBin::Bin/./third/lib/perl5";

use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

# use local::lib './aa/lib/perl5';
use Data::Dumper;

use Net::Async::HTTP::Server;
# use WebTail;
use Net::Async::WebSocket::Server;
# use strict;

# our $loop;

my $server = Net::Async::WebSocket::Server->new(
    on_client => sub {
        my ( undef, $client ) = @_;
        my $web;
        $client->configure(
            on_text_frame => sub {
                my ( $self, $frame ) = @_;
                $frame =~ /(.+),(.+)/;
                $web = WebTail::processCommand($self, $1, $2);
                # $self->send_text_frame( $frame );
            },
            on_close_frame => sub {
                print "frame is closed\n";
                if ($web) {
                    print "frame is closed2\n";
                    $web->close;
                }
            }
           );
    }
   );

$loop->add( $server );

$server->listen(
    service => 3000,
   )->get;
use HTTP::Response;
my $httpserver = Net::Async::HTTP::Server->new(
    on_request => sub {
        my $self = shift;
        my ( $req ) = @_;

        my $response = HTTP::Response->new( 200 );
        my $ws_url = "ws://127.0.0.1:3000";
        my $filename = './index.html';
        open(FH, '<', $filename) or die $!;
        my $html = '';
        while(<FH>){
            $html .= $_;
        }
        close(FH);
        $html =~ s/\$ws_url/$ws_url/g;
        $response->add_content($html);

        $response->content_type( "text/html" );
        $response->content_length( length $response->content );

        $req->respond( $response );
    },
   );

$loop->add( $httpserver );

$httpserver->listen(
    addr => { family => "inet6", socktype => "stream", port => 8080 },
   )->get;
$loop->run;
