package WebTail;
use Data::Dumper;
use IO::Async::Loop;
use IO::Async::FileStream;
use File::Tail;
use strict;
use Try::Catch;

our $loop = IO::Async::Loop->new;

sub processCommand {
    my $webs = shift;
    my $command1 = shift;
    my $command2 = shift;
    if ($command1 eq "list") {
        print "command is list\n";
        # my @files = glob( $command2 . '/*' );
        # print WebTail::Dumper(\@files);

        my @files = ();

        print $command2;
        opendir(DIR, $command2) or die $!;

        while (my $file = readdir(DIR)) {

            # We only want files
            next unless (-f "$command2/$file");
            push(@files, "$command2/$file");
        }

        closedir(DIR);
        my $ret = join "|", @files;
        $webs->send_text_frame($command1.",".$ret);
    } elsif ($command1 eq "tail") {
        my @files2 = ();
        push(@files2, $command2);
        foreach (@files2) {
            open my $logh, "<", $_ or
              die "Cannot open logfile - $!";
            my $filestream = IO::Async::FileStream->new(
                read_handle => $logh,

                on_initial => sub {
                    my ( $self ) = @_;
                    $self->seek_to_last( "\n" );
                },

                on_read => sub {
                    my ( $self, $buffref ) = @_;

                    while ( $$buffref =~ s/^(.*\n)// ) {
                        try {
                          my $res = $webs->send_text_frame( "data,$1" );
                        }
                        catch {
                          print "catch\n";
                        }
                    }
                    return 0;
                },
               );

            $WebTail::loop->add( $filestream );
            return $filestream;
        }
    }
}

1;
