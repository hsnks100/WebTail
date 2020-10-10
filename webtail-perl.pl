use File::Tail ();
use threads;
use threads::shared;
use Net::WebSocket::Server;
use strict;
use Dancer2;

my @webs = ();
print ref(@webs), "........................\n";
# my %clients :shared = ();

my $conns :shared = 4;
threads->create(sub {
    print "start-end:", "$conns", "\n";
    my @files = glob( $ARGV[0] . '/*' );
    my @fs = ();
    foreach my $fileName(@files) {
        my $file = File::Tail->new(name=>"$fileName",
                                   tail => 1000,
                                   maxinterval=>1,
                                   interval=>1,
                                   adjustafter=>5,resetafter=>1,
                                   ignore_nonexistant=>1,
                                   maxbuf=>32768);
        push(@fs, $file);
    }
    do {
        my $timeout = 1;
        (my $nfound,my $timeleft,my @pending)=
            File::Tail::select(undef,undef,undef,$timeout,@fs);
        unless ($nfound) {

        } else {
            foreach (@pending) {
                my $str = $_->read;
                print $_->{"input"} . " ||||||||| ".localtime(time)." ||||||||| ".$str;

                # it doesn't works.
                foreach (@webs) {
                    $_->send_utf8("test2!!!!!!!!");
                }
            }
        }
    } until(0);
})->detach();

threads->create(sub {
    Net::WebSocket::Server->new(
        listen => 8080,
        on_connect => sub {
            my ($serv, $conn) = @_;
            push(@webs, $conn);
            $conn->on(
                utf8 => sub {
                    my ($conn, $msg) = @_;
                    $conn->send_utf8($msg);
                    # it works.
                    foreach (@webs) {
                        $_->send_utf8("test1!!!!!!!!");
                    }
                },
                );
        },
        )->start;
                })->detach();


get '/' => sub {
    my $ws_url = "ws://127.0.0.1:8080/";
    return <<"END";
    <html>
      <head><script>
          var urlMySocket = "$ws_url";

          var mySocket = new WebSocket(urlMySocket);

          mySocket.onmessage = function (evt) {
            console.log( "Got message " + evt.data );
          };

          mySocket.onopen = function(evt) {
            console.log("opening");
            setTimeout( function() {
              mySocket.send('hello'); }, 2000 );
          };

    </script></head>
    <body><h1>WebSocket client</h1></body>
  </html>
END
};

dance;
