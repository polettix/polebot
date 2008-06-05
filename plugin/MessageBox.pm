package Polebot::Plugin::MessageBox;
use strict;
use warnings;

use base 'Polebot::Plugin::Base';

sub description { 'store messages for other chatters' }

sub _execute {
   my $self = shift;
   my ($who, $where, $msg) = @_;
   my ($speaker) = split /!/, $who;

   if ($msg =~ /\A \s* messaggi \?? \s*\z/mxs) {
      if (my $messagebox = $self->messagebox_for($speaker)) {
         for my $note (@$messagebox) {
            $self->say($where->[0],
               "[$note->{when}] <$note->{who}>: $note->{what}");
         }
      } ## end if (my $messagebox = $self...
      else {
         $self->say($where->[0], "non ci sono messaggi");
      }
      $self->wipe_messagebox($speaker);
      $self->clear_notification($speaker);
   } ## end if ($msg =~ /\A \s* messaggi \?? \s*\z/mxs)
   elsif (
      my ($dest, $note) =
      $msg =~ /\A
         (?:
            messaggio \s+ per |
            ricorda \s+ a
         ) \s+ (\S+) \s+ (.*) \z/mxs
     )
   {
      $dest =~ s/:\z//mxs;
      $self->record_message($dest, $speaker, $note);
      $self->say($where->[0], "messaggio per $dest registrato");
   } ## end elsif (my ($dest, $note) ...
   else {
      return;
   }

   return 1;
} ## end sub _execute

sub msg {
   my $self = shift;
   my ($who, $where, $msg) = @_;
   my ($speaker) = split /!/, $who;
   $self->fire_notification($speaker, $speaker);
   return $self->_execute($who, [$speaker], $msg);
} ## end sub msg

sub public {
   my $self = shift;
   my ($who, $where, $msg) = @_;

   my ($speaker) = split /!/, $who;
   my $target = "notice!$speaker";
   $self->fire_notification($speaker, $target);

   return unless $self->is_for_me($msg);
   my $nick = quotemeta $self->master()->irc()->nick_name();
   $msg =~ s/\A $nick [:,] \s*//mxsg;
   return $self->_execute($who, [$target], $msg);
} ## end sub public

sub fire_notification {
   my $self = shift;
   my ($speaker, $target) = @_;
   my $nick = quotemeta $self->master()->irc()->nick_name();
   if ($self->has_messages($speaker) && !$self->notify_sent($speaker)) {
      $self->say($target,
         "ho alcuni messaggi per te, /msg $nick messaggi? per leggerli");
      $self->flag_notification($speaker);
   }
   return;
} ## end sub fire_notification

sub has_messages {
   my $self = shift;
   my ($who) = @_;
   return exists $self->{box}{$who};
}

sub messagebox_for {
   my $self = shift;
   my ($who) = @_;
   return $self->{box}{$who};
}

sub record_message {
   my $self = shift;
   my ($to, $from, $msg) = @_;
   push @{$self->{box}{$to}},
     {
      who  => $from,
      what => $msg,
      when => scalar localtime(),
     };
   return;
} ## end sub record_message

sub wipe_messagebox {
   my $self = shift;
   my ($who) = @_;
   delete $self->{box}{$who};
   return;
} ## end sub wipe_messagebox

sub flag_notification {
   my $self = shift;
   my ($who) = @_;
   $self->{flag}{$who} = time();
   return;
} ## end sub flag_notification

sub clear_notification {
   my $self = shift;
   my ($who) = @_;
   delete $self->{flag}{$who};
   return;
} ## end sub clear_notification

sub notify_sent {
   my $self = shift;
   my ($who) = @_;
   $self->master()->logger()->debug("last: $self->{flag}{$who}");
   return $self->{flag}{$who} && ($self->{flag}{$who} + 3600 > time());
} ## end sub notify_sent

1;
