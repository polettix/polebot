package Polebot::Plugin::Logger;
use strict;
use warnings;
use base 'Polebot::Plugin::Base';
use IO::Handle;
use Config::Tiny;
use File::Spec::Functions qw( catfile );

my %last_for;
sub public {
   my $self = shift;
   my ($who, $where, $msg) = @_;
   my ($speaker) = split /!/, $who;
   my $channel = $where->[0];

   my $logline;
   (my ($action) = $msg =~ /\A \x{01} ACTION \s+ (.*) \x{01} \z/mxs;
   if ($action) {
      $msg = "$speaker $action";
      $logline = "*\t$msg";
   }
   else {
      $logline = "<$speaker>\t$msg";
   }

   my $when = localtime;
   $last_for{$channel}{lc $speaker} = { said => $msg, at => $when };
   my $my_nick = $self->master()->irc()->nick_name();
   if ($msg =~ /\A $my_nick\s*: \s*hai\s+visto\s+ (\S+) \s*\?\s* \z/mxs) {
      my $looked = $1;
      if (exists $last_for{$channel}{lc $looked}) {
         my $record = $last_for{$channel}{lc $looked};
         $self->say($channel, qq{l'ultima volta che ho visto $looked è stato il $record->{when}, quando ha detto: «$record->{said}»});
      }
      else {
         $self->say($channel, 'spiacente, non ricordo');
      }
   }

   my $server = $self->master()->irc()->server_name();
   my $fh = $self->handle_for($server, $channel) or return;
   print {$fh} "[$when] $logline\n";
   return;
} ## end sub public

sub stop {
   shift->close_all();
}

sub handle_for {
   my $self = shift;
   my ($server, $channel) = @_;
   my $key = join '!', $server, $channel;
   
   my $handle_for = $self->{handles_for} ||= {};
   if (!exists $handle_for->{$key}) {
      my $filename = $channel;
      if (my $conf = $self->master()->get_plugin_config(ref $self)) {
         $filename = $conf->{filename};
         $filename =~ s/\%c/$channel/gmxs;
         $filename =~ s/\%s/$server/gmsx;
         $filename = catfile($conf->{logdir}, $filename);
      }
      
      open $handle_for->{$key}, '>>', $filename or return;
      $handle_for->{$key}->autoflush();
   }
   return $handle_for->{$key};
} ## end sub handle_for

sub close_all {
   my $self = shift;
   $self->{handles_for} = {};
   return;
}

1;

