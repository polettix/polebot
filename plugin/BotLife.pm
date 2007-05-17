package Polebot::Plugin::BotLife;
use strict;
use warnings;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catfile );
use base 'Polebot::Plugin::Base';
use English qw( -no_match_vars );
use Carp;

sub description        { return 'manage bot life' }
sub only_from_admin { return 1 }

sub accepts {
   my $self = shift;
   my ($line) = @_;
   return $line =~ /: \s* (?: quit | restart) \s*/mxs;
}

sub msg {
   my $self = shift;
   my ($who, $where, $message) = @_;
   my ($speaker) = split /!/, $who;
   return $self->_execute($who, [ $speaker ], $message);
}

sub public {
   my $self = shift;
   my ($who, $where, $message) = @_;
   return unless $self->is_for_me($message);
   return $self->_execute(@_);
}

sub _execute {
   my $self = shift;
   my ($who, $where, $message) = @_;

   my $speaker = (split /!/, $who)[0];
   my $channel = $where->[0];
   my $master  = $self->master();

   if ($message =~ /\b quit \s*\z/mxs) {
      $master->say_now($channel, 'quitting, byez');
      $master->register_quit();
   }
   elsif ($message =~ /\b restart \s*\z/mxs) {
      my $flagfile = catfile(dirname(__FILE__), '..', 'relaunch');
      open my $fh, '>', $flagfile or croak "open('$flagfile'): $OS_ERROR";
      close $fh;
      $master->say_now($channel, "restarting, see you soon");
      $master->register_quit();
   } ## end elsif ($message =~ /: \s* (?: restart )\s*\z/mxs)
   elsif ($message =~ /\b reload \s*\z/mxs) {
      $master->defer_actions(sub { $master->load_plugins() });
      $self->say($channel, "plugin reload completed");
   }
   elsif ($message =~
      /\b logchange \s+ (DEBUG | INFO | WARN | ERROR | FATAL )\s*\z/mxs)
   {
      my $level  = $1;
      my $logger = $master->logger();
      $logger->level($1);
      $logger->debug("log level set to $level");
      $self->say($channel, "$speaker: changed loglevel");
   } ## end elsif ($message =~ ...
   elsif ($message =~ /\b stats \s*\z/mxs) {
      my $server = $master->irc()->server_name();
      my $lag    = sprintf '%.2f', $master->connector()->lag();
      my $uptime = qx{ /usr/bin/uptime };
      $self->say(
         $channel,
         "connected to $server, lag $lag s",
         "uptime: $uptime"
      );
   } ## end elsif ($message =~ /: \s* stats \s*\z/mxs)
   else {
      return;
   }
   return 1;
} ## end sub notify

1;
