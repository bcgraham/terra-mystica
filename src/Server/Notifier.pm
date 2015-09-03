use strict;

package Server::Notifier;

use Moose;
use Server::Server;
use Method::Signatures::Simple;

extends 'Server::Server';

use DB::Connection;
use DB::Secret;
use DB::Validation;
use Server::Session;
use Util::CryptUtil;

has 'mode' => (is => 'ro', required => 1);

my $domain = 'http://tella.snerrman.net'; 

method handle($q, $suffix) {
    $self->no_cache();
    my $dbh = get_db_connection;
    my $mode = $self->mode();

    if ($mode eq 'validate') {
        $self->validate_notifier($q, $dbh, $suffix);
    } elsif ($mode eq 'request') {
        $self->request_notifier($q, $dbh);
    } elsif ($mode eq 'list-available') {
        $self->list_notifiers($q, $dbh);
    } else {
        die "Unknown mode $mode";
    }
}

method request_notifier($q, $dbh) {
    my @error = ();

    my $notifier_type = $q->param('notifier_type');
    my $to = $q->param('to');
    my $username = username_from_session_token($dbh,
                                               $q->cookie('session-token') // '');

    if (!$username) {
        push @error, "not logged in";
    } else {
        verify_csrf_cookie_or_die $q, $self;
    }

    if (!@error) {
        my ($notifier_in_use) = $dbh->selectrow_array("select count(*) from notifier where lower(target) = lower(?)", {}, $to);

        if ($notifier_in_use) {
            push @error, "The notifier is already registered";
        }

        my ($is_valid_notifier) = $dbh->selectrow_array("select count(*) from notifier_type where lower(name) = lower(?)", {}, $notifier_type);

        if (!$is_valid_notifier) {
            push @error, "'$notifier_type' is not a valid notifier"
        }
    }

    if (!@error) {
        my $data = {
            username => $username,
            to => $to,
            notifier_type => $notifier_type,
        };
        my $token = insert_to_validate $dbh, $data;

        my $url = sprintf "%s/app/notifier/validate/%s", $domain, $token;

        my $res = $dbh->selectrow_hashref("select package from notifier where notifier_type = ?", {}, $notifier_type);
        my $pkg = $res->{package};
        my $notifier = $pkg->new($to); 
        my $msg = $notifier->message_for_validation($url); 
        $notifier->notify($msg);
    }

    $self->output_json({ error => [@error] });
}

method validate_notifier($q, $dbh, $suffix) {
    my $token = $suffix // $q->param('token');

    my ($secret, $iv) = get_secret;
    eval {
        my @data = ();
        my $payload = fetch_validate_payload $dbh, $token;
        @data = ($payload->{username}, $payload->{to}, $payload->{notifier_type});

        $self->add_notifier($dbh, @data);
        $self->output_html("<h3>Notifier registered</h3>");
    }; if ($@) {
        print STDERR "token: $token\n";
        print STDERR $@;
        $self->output_html("<h3>Validation failed</h3>");
    }
}

method add_notifier($dbh, $user, $to, $notifier_type) {
    my ($already_done) = $dbh->selectrow_array("select count(*) from notifier where lower(target) = lower(?)", {}, $to);
    my ($is_valid_notifier) = $dbh->selectrow_array("select count(*) from notifier_type where lower(name) = lower(?)", {}, $notifier_type);

    if (!$already_done and $is_valid_notifier) {
        $dbh->do('begin');
        $dbh->do('insert into notifier (target, player, validated, notifier_type, is_primary) values (lower(?), ?, ?, ?, false)',
                 {}, $to, $user, 1, $notifier_type);
        $dbh->do('commit');
    }

    return $already_done;
}

method list_notifiers($dbh, $user, $to) {
    my ($notifiers_list) = $dbh->selectall_hashref("select name, displayname, recipient_word from notifier_type;",
                                                  { Slice => {} });

    $self->output_json($notifiers_list);
}

1;
