#!/usr/bin/perl -w

use strict;

package SMS::Notify;
use Exporter::Easy (EXPORT => [ 'sms_after_move' ]);

use DB::EditLink;
use Game::Constants;
use WWW::Twilio::API;

my $domain = "http://tella.snerrman.net";

sub notify_by_sms {
    my ($to, $body) = @_;
    my $from = get_from_number;

    return if !$to or !$from or !$body;

    my $twilio = new WWW::Twilio::API( AccountSid => $ENV{"TWILIO_SID"},
                                       AuthToken  => $ENV{"TWILIO_SECRET"}, );

    my $response = $twilio->POST('Messages.json',
                                 From => $from,
                                 To   => $to,
                                 Body => $body );
    my $content = JSON::from_json($response->{content});

    if ($content->{error_code}) {
        print STDERR "Error sending SMS: $content->{error_code}: $content->{error_message} \n";
    }
}

sub get_from_number {
    @numbers = split /:/, $ENV{"TWILIO_NUMBERS"}
    return @numbers[rand @numbers]
}

sub sms_after_move {
    my ($dbh, $write_id, $game, $who_moved) = @_;

    my %acting = ();

    for (@{$game->{action_required}}) {
        $acting{$_->{faction} // $_->{player_index}} = 1;
    }

    # TODO: should send a message when game is over

    for my $faction (values %{$game->{factions}}) {
        my $phone = $faction->{phone};

        next if ($faction->{name} eq $who_moved);

        if (!$game->{finished} and $acting{$faction->{name}}) {
            my $link = edit_link_for_faction $dbh, $write_id, $faction->{name};
            my $text = "Your turn! $domain$link";
            notify_by_sms $phone, $text 
        }
    }
}

1;

