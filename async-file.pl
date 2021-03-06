package WebTail;
use FindBin;
use lib "$FindBin::Bin/./local/lib/perl5";
use lib "$FindBin::Bin/.";
use IO::Async::Loop;
my $loop = IO::Async::Loop->new;
use Data::Dumper;
use Net::Async::HTTP::Server;
use WebTail;
use Net::Async::WebSocket::Server;
use MIME::Base64;


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
        my $path = $req->path;
        # my $auth = $req->header; # authorization;
        # print "path $path, $auth\n";
        my @auth = split /Basic /, $req->header('authorization');
        my $authFailer = sub {
            my $response = HTTP::Response->new( 401 );
            $response->add_content("auth req");
            $response->header( "WWW-Authenticate" => "basic realm=\"localhost\"" );
            $response->content_type( "text/html" );
            $response->content_length( length $response->content ); 
            $req->respond( $response ); 
        };
        if (scalar @auth != 2) {
            &$authFailer();
            return;
        }
        $decoded = decode_base64($auth[1]); 
        print "\ndec $decoded\n";
        if ($decoded ne "rufree:1") {
            &$authFailer();
            return;
        }
        my $response = HTTP::Response->new( 200 );
        my $filename = './index.html';
        open(FH, '<', $filename) or die $!;
        my $html = '';
        while(<FH>){
            $html .= $_;
        }
        close(FH);
        $html =~ s/pathpath/$path/g;
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
