#!/usr/bin/perl -w

use strict;

package Notify::Email;
use Exporter::Easy (EXPORT => [ 'notify', 
                                'message_for_game_start',
                                'message_for_game_end',
                                'message_for_active',
                                'message_for_observer',
                                'message_for_new_chat',
                                'message_for_validation' ]);
use Game::Constants;
use Net::SMTP;

my $domain = "http://terra.snellman.net";

sub new {
    my $to = shift; 
    my $game = shift; 
    
    my %self = {
        to => $to,
        from => get_from_email $game,
    }; 

    return \%self; 
}

method notify {
    my ($email, $msg) = @_;
    my ($subject, $body) = @msg; 

    return if !$body or !$subject or !$email;

    my $smtp = Net::SMTP->new('localhost', ( Debug => 0 ));

    $smtp->mail("www-data\@terra.snellman.net");
    if (!$smtp->to($email)) {
        print STDERR "Invalid email address $email\n";
    } else {
        $smtp->data();
        $smtp->datasend("To: $email\n");
        $smtp->datasend("From: TM Game Notification <noreply+notify-game-$game->{name}\@tella.snerrman.net>\n");
        $smtp->datasend("Subject: $subject\n");
        $smtp->datasend("\n");
        $smtp->datasend("$body\n");
        $smtp->dataend();
    }

    $smtp->quit;
}

method message_for_active {
    my ($dbh, $write_id, $game, $email, $faction, $who_moved, $moves) = @_;
    $who_moved = pretty_faction_name $game, $who_moved; 

    my $subject = "Terra Mystica PBEM ($game->{name}) - your move";

    my $link = edit_link_for_faction $dbh, $write_id, $faction->{name};
    my $body = "
It's your turn to move in Terra Mystica game $game->{name}.

Link: $domain$link";

    if ($faction->{recent_moves}) {
        $body .= "\n\nThe following has happened since your last full move:\n";
        for (@{$faction->{recent_moves}}) {
            $body .= "  $_\n";
        }
    } else {
        $body .= "

An action was taken by $who_moved:
$moves

No longer interested in email notifications for your games? Change
your email settings at $domain/settings/
";
    }
    ($subject, $body);
}

method message_for_observer {
    my ($game, $who_moved, $moves) = @_;
    $who_moved = pretty_faction_name $game, $who_moved; 

    my $subject = "Terra Mystica PBEM ($game->{name})";
    my $body = "
An action was taken in game $game->{name} by $who_moved:

$moves

No longer interested in email notifications for your games? Change
your email settings at $domain/settings/
";
    ($subject, $body);
}

method message_for_new_chat {
    my ($game, $who_moved, $moves) = @_;

    my $subject = "Terra Mystica PBEM ($game->{name})";
    my $body = "
A chat message was sent in $game->{name} by $who_moved:

$moves

No longer interested in email notifications for your games? Change
your email settings at $domain/settings/
";
    ($subject, $body);
}

method text_for_game_over {
    my ($game, $who_moved) = @_;
    my $order = join("\n",
                     map { "$_->{VP} ".pretty_faction_name($game, $_->{name}) }
                     sort { $b->{VP} <=> $a->{VP} }
                     grep { $_->{VP} } values %{$game->{factions}});

    my $subject = "Terra Mystica PBEM ($game->{name}) - game over";
    my $body = "
Game $game->{name} is over:

$order

No longer interested in email notifications for your games? Change
your email settings at $domain/settings/
";
    ($subject, $body);
}

method message_for_game_start {
    my ($game) = @_;

    my $i = 1;
    my $order = join("\n",
                     map { $i++.". ".($_->{display} // $_->{username}) }
                     @{$game->{players}});

    my $subject = "Terra Mystica PBEM ($game->{name}) - game started";
    my $body = "
Game $game->{name} has been start with the following players:

$order

No longer interested in email notifications for your games? Change
your email settings at $domain/settings/
";
    ($subject, $body);
}

sub get_from_email {
    my ($game) = @_; 
    return "TM Game Notification <noreply+notify-game-$game->{name}\@terra.snellman.net>"; 
}

sub pretty_faction_name {
    my ($game, $faction) = @_;
    my $faction_pretty = $faction;
    if (exists $faction_setups{$faction}) {
        $faction_pretty = $faction_setups{$faction}{display};
    }
    my $displayname = $game->{factions}{$faction}{displayname};
    if (defined $displayname) {
        $faction_pretty .= " ($displayname)";
    }

    $faction_pretty;
}
