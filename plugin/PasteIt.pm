package Polebot::Plugin::PasteIt;
use strict;
use warnings;

use base 'Polebot::Plugin::Base';

use DBI;
use Readonly;
use POE qw( Component::Server::TCP );

Readonly my $paste_uri    => 'http://pastebot.perl.it/perl/PasteIt.pl';
Readonly my $main_channel => '#polebot';

sub new {
   my $pack   = shift;
   my $self   = $pack->SUPER::new(@_);
   my $master = $self->master();

   $self->{server} = POE::Component::Server::TCP->new(
      Port        => 54321,
      Hostname    => 'localhost',
      ClientInput => sub {
         eval { $self->handle_client_input(@_) };
      },
   );

   return $self;
} ## end sub new

sub stop {
   my $self = shift;
   $self->master()->kernel()->post($self->{server} => 'shutdown');
   return;
}

sub can_reload { return 0 }

sub cleanup {
   my $text = shift;
   $text =~ tr[\x00-\x1F\x7F][ ]s;
   $text =~ s/\s+/ /g;
   $text =~ s/\A\s+|\s+\z//g;
   return $text;
} ## end sub cleanup

sub handle_client_input {
   my $self = shift;
   my ($kernel, $heap, $record) = @_[KERNEL, HEAP, ARG0];
   if (my ($nick) = $record =~ /\A check \s+ (\S+) \s*\z/mxs) {
      my $code =
        $self->master()->irc()->is_channel_member($main_channel, $nick);
      $code ||= 0;
      $heap->{client}->put("$code");
   } ## end if (my ($nick) = $record...
   elsif (my ($msg) = $record =~ /\A announce \s+ (.*)/mxs) {
      $self->master()->logger()->debug("PasteIt: ricevuto $msg");
      my ($nick, $summary, $id) = map { 
         cleanup(pack 'H*', $_) 
      } split /-/, $msg;
      my $uri = "$paste_uri?rm=showpaste;id=$id";
      $self->say($main_channel,
         qq{$nick ha messo '$summary' all'indirizzo $uri});
   } ## end elsif (my ($msg) = $record...
   $heap->{client}->put('');
   $kernel->yield('shutdown');
} ## end sub handle_client_input

sub msg {
   my $self = shift;
   my ($who, $where, $msg) = @_;

   my ($speaker) = split /!/, $who;
   my $master = $self->master();
   return
     unless $master->irc()->is_channel_operator($main_channel, $speaker)
     || $master->is_authenticated($speaker);

   my $logger = $master->logger();
   if (my ($start, $stop) =
      $msg =~ /\A paste \s+ delete \s+ (\d+)(?:-(\d+))? \s*\z/mxs)
   {
      my $dbh =
        DBI->connect('DBI:mysql:dbname=test_PasteIt', 'fakeuser', '');
      if (!$dbh) {
         $self->master()->logger()->error('could not connect to database');
         $self->say($speaker, 'could not connect to database');
         return 1;
      }

      $stop = $start unless $stop;
      my $affected = 0;
      $affected +=
        $dbh->do('UPDATE paste SET active = 0 WHERE id = ?', undef, $_)
        for $start .. $stop;
      if ($affected) {
         $self->say($speaker, 'deleted paste(s)');
      }
      else {
         $self->say($speaker, 'errors deleting, please check');
      }
      $dbh->disconnect();
   } ## end if (my ($start, $stop)...

} ## end sub msg

sub public {
   my $self = shift;
   my ($who, $where, $msg) = @_;
   return unless $self->is_for_me($msg);

   my $channel = $where->[0];

   if (my ($id) = $msg =~ /\b paste \s+ (\d+) \s*\z/mxs) {
      my $dbh =
        DBI->connect('DBI:mysql:dbname=test_PasteIt', 'fakeuser', '');
      if (!$dbh) {
         $self->master()->logger()->error('could not connect to database');
         return 1;
      }
      my $exsummary = $dbh->selectrow_hashref(
         'SELECT id, nick, summary FROM paste WHERE id = ? AND active > 0',
         undef, $id
      );
      $dbh->disconnect();

      if (defined $exsummary) {
         my $uri = "$paste_uri?rm=showpaste;id=$id";
         $self->say($channel,
                qq{paste $id: "$exsummary->{summary}",}
              . " inviato da $exsummary->{nick} su $uri");
      } ## end if (defined $exsummary)
      else {
         $self->say($channel, " il paste di id $id non esiste ");
      }

      return 1;
   } ## end if (my ($id) = $msg =~...
   elsif ($msg =~ /\A nepaste [:,]? \s*\z/mxs) {
      $self->say($channel,
         "per fare paste sul canale, puoi trovarmi su $paste_uri");
   }

   return;
} ## end sub public

1;
