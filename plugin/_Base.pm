package Polebot::Plugin::Base;
use strict;
use warnings;
use Carp;

sub new {
   my ($package, $master, $filename) = @_;
   croak "please specify this object's master" unless defined $master;
   return bless { master => $master, filename => $filename }, $package;
};
sub stop {
   return;
}
sub master { return shift->{master} }
sub filename { return shift->{filename} }

sub name {
   my $self = shift;
   (my $name = ref $self) =~ s/^.*:://;
   return $name;
}
sub description { return 'base class for polebot plugins' }

sub _public {
   my $self = shift;
   my ($who, $where, $message) = @_;
   return;
}
sub only_from_operator { return 0 }
sub only_from_admin { return 0 }

sub say { 
   my $self = shift;
   return $self->master()->say(@_);
}

sub is_for_me {
   my $self = shift;
   my ($input) = @_;
   my $nick = $self->master()->irc()->nick_name();
   return $input =~ /\A $nick (?: [:,] | \s*\z) /mxs;
}

sub ensure_for_me {
   my $self = shift;
   my ($message) = @_;
   return $message if $self->is_for_me($message);
   my $nick = $self->master()->irc()->nick_name();
   return "$nick: $message";
}

1;
