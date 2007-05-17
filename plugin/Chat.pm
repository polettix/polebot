package Polebot::Plugin::Chat;
use strict;
use warnings;
use base 'Polebot::Plugin::Base';

sub only_from_admin { return 1 };

sub msg {
   my $self = shift;
   my ($who, $where, $msg) = @_;
   my ($speaker) = split /!/, $who;
   my $master = $self->master();

   if (my ($channel) = $msg =~ /\bop \s+ (\S+)/mxs) {
      $master->post_irc(mode => $channel => '+o' => $speaker);
      return 1;
   }

   return;
}

1;

