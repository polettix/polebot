package Polebot::Plugin::Boha;
use strict;
use warnings;

use base 'Polebot::Plugin::Base';

sub description { 'manage karma through boha' }

sub public {
   my $self = shift;
   my ($who, $where, $msg) = @_;
   return unless $self->is_for_me($msg);

   if (my ($nick) = $msg =~ /\b inc(?:rementa)? \s+ (\S+) \s*\z/mxs) {
      $self->say($where->[0], "boha: $nick++");
   }
   else {
      return;
   }

   return 1;
}

1;

