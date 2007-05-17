package Polebot::Plugin::Repubblica;
use strict;
use warnings;

use base 'Polebot::Plugin::Base';

use LWP::UserAgent;
use XML::RSS;
use Readonly;
use Data::Dumper;

Readonly my $base_uri => 'http://www.repubblica.it';
Readonly my $rss_uri => "$base_uri/rss/homepage/rss2.0.xml";

sub description { return 'repubblica.it feeds!' }

sub only_from_operator { return 1 };

sub public {
   my $self = shift;
   my ($who, $where, $message) = @_;

   return unless $self->is_for_me($message);

   if ($message =~ /dump/) {
      local $Data::Dumper::Indent = 1;
      my %copy = map { $_ => $self->{$_} } grep { $_ ne 'master' } keys %$self;
      $self->master()->logger()->debug(Dumper(\%copy));
   }
   
   my ($action, $delay) = $message =~ /\b 
      repubblica
      (?: \s+ (start | stop))?
      (?: \s+ (\d+) )?
      \s*\z
   /mxs or return;
   $action ||= '';

   my $count = 4;
   $count = $delay if ! $action && $delay && $delay > 0;
   
   my $channel = $where->[0];
   if ($action eq 'stop') {
      delete $self->{channels}{$channel};
      return 1;
   }

   my $rss = $self->check_news();
   $self->announce($channel, $rss, $count);
   if ($action eq 'start') {
      $self->{channels}{$channel} = 1;
      $self->set_recall($delay);
   }

   return 1;
}

sub set_recall {
   my $self = shift;
   my ($delay) = @_;

   return unless scalar keys %{ $self->{channels} };
   $self->master()->logger()->debug('set_recall in ' . __PACKAGE__);

   $self->master()->call_me(sub {
      $self->check_news();
      $self->set_recall($delay);
   }, $delay);
   return;
}

sub check_news {
   my $self = shift;

   my $current = $self->get_rss() or return;

   if (scalar keys %{ $self->{channels} }) {
      # Find "marker"
      my $last_title = $self->{latest};
      my @news;
      for my $new (@$current) {
         last if $new->{title} eq $last_title;
         push @news, $new;
      }
      for my $new (reverse @news) {
         for my $channel (keys %{ $self->{channels} }) {
            $self->say($channel => "$base_uri => $new->{title}");
         }
         last;
      }
   }

   $self->{latest} = $current->[0]{title};
   return $current;
}

sub announce {
   my $self = shift;
   my ($channel, $rss, $count) = @_;
   $count = 4 unless $count && $count > 0;

   if ($rss) {
      $self->say($channel => $base_uri);
      for my $item (@$rss) {
         $self->say($channel => $item->{title});
         last unless --$count;
      }
   }
   else {
      $self->say($channel => 'operation timed out');
   }
   return;
}

sub get_rss {
   my $ua = LWP::UserAgent->new(agent => 'polebot/1.0');
   $ua->timeout(5);

   my $response = $ua->get($rss_uri);
   return unless $response->is_success();

   my $rss = XML::RSS->new(version => '2.0');
   $rss->parse($response->content());
   return $rss->{items};
}

1;
