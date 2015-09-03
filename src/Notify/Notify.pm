#!/usr/bin/perl -w

use strict;

package Notify::Notify;
use Exporter::Easy (EXPORT => [ 'notify_after_move',
                                'notify_game_started',
                                'notify_new_chat' ]);

use DB::EditLink;
use Notify::Settings; 

sub notify_after_move {
    my ($dbh, $write_id, $game, $who_moved, $moves) = @_;
    
    $moves =~ s/^$who_moved:/  /gm;

    for my $faction (values %{$game->{factions}}) {
        my ($settings, $notifier) = Notify::Settings->new($dbh, $game, $faction, $who_moved);
        next unless $settings->{for_after_move}; 

        my $link = edit_link_for_faction $dbh, $write_id, $faction->{name};
        my $msg;

        $msg = $notifier->message_for_game_end ($game)                                      if ($settings->{for_game_end});
        $msg = $notifier->message_for_active   ($game, $who_moved, $moves, $faction, $link) if ($settings->{for_my_turn});
        $msg = $notifier->message_for_observer ($game, $who_moved, $moves)                  if ($settings->{for_all_moves});
        
        $notifier->notify($msg); 
    }
}

sub notify_new_chat {
    my ($dbh, $game, $who_sent, $message) = @_;
    
    $message =~ s/^/  /gm;

    for my $faction (values %{$game->{factions}}) {
        my ($settings, $notifier) = Notify::Settings->new($dbh, $game, $faction, $who_sent);
        next unless $settings->{for_new_chat}; 
        
        my $msg = $notifier->message_for_new_chat($game, $who_sent, $message);  
        $notifier->notify($msg); 
    }
}

sub notify_game_started {
    my ($dbh, $game) = @_;

    for my $faction (@{$game->{players}}) {
        my ($settings, $notifier) = Notify::Settings->new($dbh, $game, $faction);
        next unless $settings->{for_game_start}; 

        my $msg = $notifier->message_for_game_start($game);
        $notifier->notify($msg); 
    }
}

1;

