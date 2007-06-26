package Polebot::Plugin::Timer;
use strict;
use warnings;
use base 'Polebot::Plugin::Base';

sub description { 'useless module to demonstrate a timer implementation' }
sub only_from_operator { return 1 }

sub public {
   my $self = shift;
   my ($who, $where, $msg) = @_;
   return unless $self->is_for_me($msg);

   if ($msg =~ /\b start \s+ useless \s+ timer (?: \s+ (\d+))? \s*\z/mxs) {
      my $delay = $1 || 5;
      $delay = 5 unless $delay > 5;
      delete $self->{stop};
      $self->set_recall(sub { $self->useless_message($where->[0]) },
         $delay);
      $self->say($where->[0], "timer installato, lavoro ogni $delay secondi");
   }
   elsif ($msg =~ /\b stop \s+ useless \s+ timer \s*\z/mxs) {
      $self->{stop} = 1;
      $self->say($where->[0], 'dopo la prossima smetto');
   }
   else {
      return 0;
   }

   return 1;
} ## end sub public

sub useless_message {
   my $self = shift;
   my ($channel) = @_;
   $self->say($channel, 'esatto, questo messaggio è inutile...');
}

sub set_recall {
   my $self = shift;
   my ($sub, $delay) = @_;

   my $wrap_sub;
   $wrap_sub = sub {
      $sub->();
      $self->master()->call_me($wrap_sub, $delay)
         unless $self->{stop};
   };
   $wrap_sub->();

   return;
} ## end sub set_recall

1;

