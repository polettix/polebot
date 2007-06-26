package Polebot::Plugin::Help; # FIXME
use strict;
use warnings;
use Readonly;
use base 'Polebot::Plugin::Base';

Readonly my $uri => 'http://www.polettix.it/cgi-bin/wiki.pl/Programming/nepaste';

sub description { 'provide generic help about the bot' }

sub public {
   my $self = shift;
   my ($who, $where, $msg) = @_;
   return unless $self->is_for_me($msg);
   if ($msg =~ /\bhelp \?? \s*\z/imxs) {
      $self->say($where->[0], "tutto su di me: $uri");
   }
   else {
      return 0;
   }

   return 1;
}

1;

