package Polebot::Plugin::Announce;
use strict;
use warnings;
use base 'Polebot::Plugin::Base';
use POE;
use POE::Wheel::UDP;
use POE::Filter::Stream;

sub new {
   my $pack = shift;
   my $self = $pack->SUPER::new(@_);
   my $master = $self->master();
   $self->master()->kernel()->state('announcement', sub {
      my $stuff = $_[ARG0];
      for my $channel (keys %{ $self->{channels} ||= {} }) {
         $self->say($channel, @{$stuff->{payload}});
      }
   });
   $self->{wheel} = POE::Wheel::UDP->new(
      LocalAddr  => 'localhost',
      LocalPort  => 12345,
      InputEvent => 'announcement',
      Filter     => POE::Filter::Stream->new(),
   );
   return $self;
} ## end sub new

sub DESTROY {
   my $self = shift;
   $self->master()->kernel()->state('announcement');
   return;
}

sub only_for_operators { return 1; }

sub msg {
   my $self = shift;
   my ($who, $where, $msg) = @_;
   my ($speaker) = split /!/, $who;
   return $self->_execute($who, [ $speaker ], $msg);
}

sub public {
   my $self = shift;
   my ($who, $where, $msg) = @_;
   return unless $self->is_for_me($msg);
   return $self->_execute(@_);
}

sub _execute {
   my $self = shift;
   my ($who, $where, $msg) = @_;

   my $chan;
   if (($chan) = $msg =~ /\b announce \s+ on (?: \s+ (\S+))? \s*\z/mxs) {
      $chan = $where->[0] unless defined $chan;
      $self->{channels}{$chan} = 1;
      $self->say($where->[0], "announcement on $chan is active now");
      return 1;
   }
   elsif (($chan) = $msg =~ /\b 
         (?: quiet \s+ in | announce \s+ off)
         (?: \s+ (\S+))? \s*\z
      /mxs) {
      $chan = $where->[0] unless defined $chan;
      delete $self->{channels}{$chan};
      $self->say($where->[0], "announcement on $chan shut off");
      return 1;
   }
   return;
}

1;

