use strict;

package DB::Settings;
use Exporter::Easy (EXPORT => [ 'fetch_user_settings',
                                'save_user_settings']);

sub fetch_user_settings {
    my ($dbh, $username) = @_;
    
    my %res = ();

    my $player = $dbh->selectrow_hashref(
        "select username, displayname, notify_turn, notify_all_moves, notify_chat, notify_game_status from player where username = ?",
        {},
        $username);
    $res{$_} = $player->{$_} for keys %{$player};

    my $rows = $dbh->selectall_hashref(
        "select address, validated, is_primary from email where player = ?",
        'address',
        { Slice => {} },
        $username);
    $res{email} = $rows;

    $rows = $dbh->selectall_hashref(
        "select notifier.to, notifier.validated, notifier.is_primary, notifier_type.name as type, notifier_type.displayname as name from notifier join notifier_type on notifier.type_name=notifier_type.name join player on notifier.player=player.username where player = ?",
        'to',
        { Slice => {} },
        $username);
    $res{notifier} = $rows;

    \%res;
}

sub save_user_settings {
    my ($dbh, $username, $q) = @_;

    my $displayname = $q->param('displayname');
    my $primary_email = $q->param('primary_email');
    my $notification_method = $q->param('notification_method');

    if (length $displayname > 30) {
        die "Display Name too long";
    }

    $dbh->do("begin");

    $dbh->do("update player set displayname=?, notify_turn=?, notify_all_moves=?, notify_chat=?, notify_game_status=? where username=?",
             {},
             $displayname,
             scalar $q->param('notify_turn'),
             scalar $q->param('notify_all_moves'),
             scalar $q->param('notify_chat'),
             scalar $q->param('notify_game_status'),
             $username);

    if ($primary_email) {
        my ($exists) = $dbh->selectrow_array(
            "select count(*) from email where player = ? and address=lower(?)",
            { },
            $username,
            $primary_email);

        if (!$exists) {
            die "'$primary_email' is not a registered email address for '$username'\n";
        }
        
        $dbh->do("update email set is_primary=false where player=?",
                 {},
                 $username);
        $dbh->do("update email set is_primary=true where player=? and address=lower(?)",
                 {},
                 $username,
                 $primary_email);
        $dbh->do("update game_role set email=? where faction_player=?",
                 {},
                 $primary_email,
                 $username);
    }

    if ($notification_method) {
        $dbh->do("update notifier set is_primary=false where player=?",
                 {},
                 $username);
        if ($notification_method ne "email") {
            $dbh->do("update notifier set is_primary=true from notifier join notifier_type on notifier.type_name=notifier_type.name where notifier.player=? and to=lower(?)",
                     {},
                     $username,
                     $notification_method);
        }
    }

    $dbh->do("commit");
}

1;
