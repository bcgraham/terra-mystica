use strict;
no indirect;

package Server::AppendGame;

use JSON;
use Moose;
use Method::Signatures::Simple;
use POSIX qw(strftime);
use Server::Server;

extends 'Server::Server';

use Crypt::CBC;

use DB::Connection;
use DB::EditLink;
use DB::Game;
use DB::IndexGame;
use DB::SaveGame;
use DB::Secret;
use Email::Notify;
use Server::Security;
use Server::Session;

use tracker;

method verify_key($dbh, $read_id, $faction_name, $faction_key) {
    my ($secret, $iv) = get_secret $dbh;

    my $cipher = Crypt::CBC->new(-key => $secret,
                                 -blocksize => 8,
                                 -iv => $iv,
                                 -add_header => 0,
                                 -cipher => 'Blowfish');
    my $data = $cipher->decrypt(pack "h*", $faction_key);
    my $game_secret = unpack("h*", $data ^ $faction_name);

    return "${read_id}_$game_secret";
};

sub log_game_event {
    my $entry = shift;

    my @time = gmtime;
    my $datestamp = strftime "%Y-%m-%d", @time;
    $entry->{timestamp_utc} = strftime "%Y-%m-%d %T", @time;

    open my $fh, ">>", "../../data/log/events-$datestamp" or die "$!";
    my $row = encode_json($entry)."\n";
    syswrite $fh, $row;
    close $fh;
};

method handle($q) {
    $self->no_cache();

    my $read_id = $q->param_or_die('game');
    $read_id =~ s{.*/}{};
    $read_id =~ s{[^A-Za-z0-9_]}{}g;

    my $faction_name = $q->param_or_die('preview-faction');
    my $faction_key = $q->param_or_die('faction-key');
    my $orig_faction_name = $faction_name;

    my $preview = $q->param_or_die('preview');
    my $append = '';

    my $dbh = get_db_connection;
    my $username = username_from_session_token($dbh,
                                               $q->cookie('session-token') // '');

    begin_game_transaction $dbh, $read_id;

    my $write_id;
    if ($faction_key eq '') {
        $write_id = get_write_id_for_user $dbh, $username, $read_id, $faction_name;
    } else {
        $write_id = $self->verify_key($dbh,
                                      $read_id, $faction_name, $faction_key);
    }

    if ($faction_name =~ /^player/) {
        $preview =~ s/\r//g;
        if ($preview =~ /^(\s*resign\s*)$/) {
            $append = "drop-faction $faction_name\n";
        } elsif ($preview =~ s/(setup (\w+))//i) {
            $faction_name = lc $2;
            $append = "$1\n";
            $append .= join "\n", (map { chomp; "$faction_name: $_" } grep { /\S/ } split /\n/, $preview);
        } 
    } else {
        $append = join "\n", (map { "$faction_name: $_" } grep { /\S/ } split /\n/, $preview);
    }

    my ($prefix_content, $new_content) = get_game_content $dbh, $read_id, $write_id;
    chomp $new_content;
    $new_content .= "\n";

    chomp $append;
    $append .= "\n";
# Strip empty lines from new content
    $append =~ s/(\r\n)+/$1/g;
    $append =~ s/(\n)+/$1/g;

    $new_content .= $append;

    my $players = get_game_players($dbh, $read_id);
    my $metadata = get_game_metadata($dbh, $read_id);
    my $factions = get_game_factions($dbh, $read_id);

    my $res = terra_mystica::evaluate_game {
        rows => [ split /\n/, "$prefix_content\n$new_content" ],
        faction_info => $factions,
        players => $players,
        metadata => $metadata,
        delete_email => 0
    };

    if (!@{$res->{error}}) {
        eval {
            save $dbh, $write_id, $new_content, $res;
        }; if ($@) {
            print STDERR "error: $@\n";
            $res->{error} = [ $@ ]
        }
    };

    if (@{$res->{error}}) {
        $dbh->do("rollback");
    } else {
        eval {
            log_game_event {
                event => 'append',
                username => $username,
                faction => $faction_name,
                faction_username => $factions->{$faction_name}{username},
                game => $read_id,
                commands => $preview,
                round => $res->{round},
                turn => $res->{turn},
                ip => $q->remote_addr(),
                agent => $q->user_agent(),
            };
        }; if ($@) {
            print STDERR "error writing game log: $@\n";
        }

        finish_game_transaction $dbh;
    }

    if (!@{$res->{error}}) {
        if ($res->{options}{'email-notify'}) {
            my $factions = $dbh->selectall_arrayref(
                "select game_role.faction as name, email.address as email, player.displayname from game_role left join email on email.player = game_role.faction_player left join player on player.username = game_role.faction_player where game = ? and email.is_primary",
                { Slice => {} },
                $read_id);
            for my $faction (@{$factions}) {
                my $eval_faction = $res->{factions}{$faction->{name}};
                if ($eval_faction) {
                    $faction->{recent_moves} = $eval_faction->{recent_moves};
                    $faction->{VP} = $eval_faction->{VP};
                }
            }
            my $game = {
                name => $read_id,
                factions => { map { ($_->{name}, $_) } @{$factions} },
                finished => $res->{finished},
                options => $res->{options},
                action_required => $res->{action_required},
            };
            notify_after_move $dbh, $write_id, $game, $faction_name, $append;
        }
    }

    my $had_error = scalar @{$res->{error}};

    my $out = {
        error => $res->{error},
        action_required => $res->{action_required},
        round => $res->{round},
        turn => $res->{turn},
        new_faction_key => (($orig_faction_name eq $faction_name or $had_error) ?
                            undef :
                            edit_link_for_faction $dbh, $write_id, $faction_name),
    };
    eval {
        ($out->{chat_message_count},
         $out->{chat_unread_message_count}) = get_chat_count($dbh, $read_id, $username);
    };

    $out->{metadata} = get_game_metadata $dbh, $read_id;

    $self->output_json($out);
}

1;
