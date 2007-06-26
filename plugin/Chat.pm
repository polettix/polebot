package Polebot::Plugin::Chat;
use strict;
use warnings;
use base 'Polebot::Plugin::Base';
use Data::Dumper;

sub only_from_admin { return 1 }

sub description { return 'facilities for dealing with the IRC' }

sub msg {
   my $self = shift;
   my ($who, $where, $msg) = @_;
   my ($speaker) = split /!/, $who;
   my $master = $self->master();

   my ($nick, $channel, $what);
   if (($channel) = $msg =~ /\birc \s+ op \s+ (\S+)/mxs) {
      $master->post_irc(mode => $channel => '+o' => $speaker);
      return 1;
   }
   elsif (($channel) = $msg =~ /\birc \s+ join \s+ (\S+)/mxs) {
      $master->post_irc('join' => $channel);
   }
   elsif (($channel) = $msg =~ /\birc \s+ part \s+ (\S+)/mxs) {
      $master->post_irc('part' => $channel);
   }
   elsif (($nick, $what) = $msg =~ /\birc \s+ notice \s+ (\S+) \s+ (.*)/mxs) {
      $master->post_irc('notice' => $nick => $what);
   }
   elsif (($channel, $what) =
      $msg =~ /\b irc \s+ say \s+ (\S+) \s+ (.*)/mxs)
   {
      $master->post_irc(privmsg => $channel => $what);
   }
   elsif (($nick) = $msg =~ /\b irc \s+ whois \s+ (\S+)/mxs) {
      $master->logger()->info(Dumper($master->irc()->nick_info($nick)));
      $master->post_irc(whois => $nick);
   }
   else {
      return;
   }

   return 1;
} ## end sub msg

1;

