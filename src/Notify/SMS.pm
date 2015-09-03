#!/usr/bin/perl -w

use strict;

package Notify::SMS;
use Exporter::Easy (EXPORT => [ 'notify', 
                                'message_for_game_start',
                                'message_for_game_end',
                                'message_for_active',
                                'message_for_observer',
                                'message_for_new_chat',
                                'message_for_validation' ]);

use Game::Constants;
use Twilio::API;

my $domain = "http://tella.snerrman.net";

sub new {
    my $to = shift; 

    my %self = {
        to => $to,
        from => get_from_number(),
    };

    return \%self; 
}

sub message_for_game_start {
    my ($game) = @_; 
    my $msg = "($game->{name}) Started.";
    return $msg; 
}

sub message_for_game_end {
    my ($game) = @_; 
    my $i = 0; 
    my $order = join("\n",
                     map { $i < 3 ? $i++." $_->{VP} ".pretty_faction_name($game, $_->{name}) : () }
                     sort { $b->{VP} <=> $a->{VP} }
                     grep { $_->{VP} } values %{$game->{factions}});

    return "($game->{name}) Ended. Top $i were:\n$order";
}
sub message_for_active {
    my ($game, $who_moved, $moves, $faction, $link) = @_;
    return "Your turn! $domain$link";
}
sub message_for_observer {
    my ($game, $who_moved, $moves) = @_;
    return "($game->{name}) $who_moved: \n$moves"; 
}

sub message_for_new_chat {
    my ($game, $who_moved, $moves) = @_;
    return "($game->{name}) $who_moved said: $moves";
}

sub notify {
    my ($self, $msg) = @_;
    my $from = get_from_number();

    return if !$self->{to} || !$from || !$msg;
    my $twilio = new Twilio::API(
                                  AccountSid => $ENV{"TWILIO_SID"},
                                  AuthToken  => $ENV{"TWILIO_SECRET"}, 
                                );

    my $response = $twilio->POST('Messages.json',
                                 From => $from,
                                 To   => $self->{to},
                                 Body => $msg );
    my $content = JSON::from_json($response->{content});

    if ($content->{error_code}) {
        print STDERR "Error sending SMS: $content->{error_code}: $content->{error_message} \n";
    }
}

sub get_from_number {
    my @numbers = split /:/, $ENV{"TWILIO_NUMBERS"};
    return @numbers[rand @numbers];
}

1;

