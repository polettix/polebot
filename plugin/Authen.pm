package Polebot::Plugin::Authen;
use strict;
use warnings;
use Digest::MD5 qw( md5_hex );
use Config::Tiny;

use base 'Polebot::Plugin::Base';

my %expected_for;

sub description { return 'authentication support via challenge' }

sub msg {
   my $self = shift;
   my ($who, $where, $msg) = @_;
   my $master = $self->master();
   my $logger = $master->logger();

   my ($speaker) = split /!/, $who;
   if ($msg =~ /\A\s* challenge \s*\z/msx) {
      $master->logout($speaker);

      my $challenge = time() . rand();
      if (defined (my $pass = $self->password_for($speaker))) {
         my $total = "$challenge $pass\n";
         $expected_for{$speaker} = md5_hex($total);
      }

      $logger->debug("talking to $speaker");
      $self->say($speaker => "md5sum <<<'$challenge your-password-here'");
   } ## end if ($msg =~ /\A\s* challenge \s*\z/)
   elsif (my ($password) = $msg =~ /\A\s* (?:identify|login) \s+ (.*)/mxs) {
      if (exists $expected_for{$speaker}
         && $expected_for{$speaker} eq $password)
      {
         $self->master()->login($speaker);
         $self->say($speaker, 'authentication ok');
         delete $expected_for{$speaker};
      }
      else {
         $self->say($speaker, 'authentication failed');
      }
   } ## end elsif (my ($password) = $msg...
   elsif ($msg =~ /\A\s* logout \s*\z/mxs) {
      if ($master->is_authenticated($speaker)) {
         $master->logout($speaker);
         $self->say($speaker, 'logout ok');
      }
      else {
         $self->say($speaker, 'not authenticated');
      }
   }
   elsif ($msg =~ /\A\s* who \s*\z/msx) {
      if ($master->is_authenticated($speaker)) {
         $self->say($speaker, join ', ', $master->authenticated());
      }
      else {
         $self->say($speaker, 'not authenticated');
      }
   }
   return;
} ## end sub msg

sub password_for {
   my $self = shift;
   my ($nick) = @_;
   
   $self->load_passwords() unless exists $self->{password_for};
   return unless exists $self->{password_for}{$nick};
   return $self->{password_for}{$nick};
}

sub load_passwords {
   my $self = shift;
   if (my $conf = $self->master()->get_plugin_config(ref $self)) {
      if (-e $conf->{passfile}) {
         $self->{password_for} = Config::Tiny->read($conf->{passfile})->{_};
      }
   }
   else {
      $self->{password_for} = {};
   }
}

1;
