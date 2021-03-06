#!/usr/bin/perl -w

use strict;

package Notify::Settings;
use List::Util qw(any);

sub new {
    my ($caller, $dbh, $game, $faction, $who) = @_; 

    my $settings = fetch_notification_settings($dbh, $faction->{email});

    my $acting = action_is_required($game, $faction);
    my $own_move = $faction->{name} eq $who; 
    my $en = $game->{options}{'email-notify'}; 
    
    my $ended = $game->{finished};

    my $self = {
	    for_game_start => $en && $settings->{notify_game_status},
	    for_game_end   => $en && $settings->{notify_game_status}  &&  $game->{finished},
		for_my_turn    => $en && $settings->{notify_turn}         && !$game->{finished}  && $acting,
	    for_all_moves  => $en && $settings->{notify_all_moves}    && !$game->{finished}  && !$own_move,
		for_new_chat   => $en && $settings->{notify_chat}                                && !$own_move,
	};

	$self->{for_after_move} = ($self->{for_game_end} || $self->{for_my_turn} || $self->{for_all_moves}); 

    my $pkg = $settings->{notification_method} // "Notify::Email"; 
    my $to = $settings->{target} // $faction->{email}; 

    my $notifier = $pkg->new($to, $game); 
    return ($self, $notifier); 
}

sub fetch_notification_settings {
    my ($dbh, $email) = @_;
    my $settings = $dbh->selectrow_hashref(
        "select notify_turn, notify_all_moves, notify_chat, notify_game_status, package as notification_method, target from player left join notifier on player.username=notifier.player left join notifier_type on notifier.type_name=notifier.type_name where username=(select player from email where address=lower(?)) and notifier.is_primary=true",
        {},
        $email);

    $settings;
}

sub action_is_required {
    my ($game, $faction) = @_;
    my $this_faction = $faction->{name};
    return any {
        my $required_faction = $_->{faction} // $_->{player_index};
        $this_faction eq $required_faction
    } @{$game->{action_required}};
}

1;
