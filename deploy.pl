#!/usr/bin/perl -w

use File::Basename qw(dirname);
use File::Copy;
use File::Path qw(make_path);
use File::Slurp qw(slurp);
use File::Temp qw(tempfile);
use Fatal qw(open chmod rename symlink);

my $target = shift;

die "Usage: $0 target\n" if !$target or @ARGV;

if (mkdir $target) {
  print "Created directory $target\n";
} elsif (!-d $target) {
  die "Directory $target does not exist and cannot be created"; 
}

if (mkdir "logs") {
  print "Created directory logs/\n";
} elsif (!-d "logs") {
  die "Directory logs/ does not exist and cannot be created"; 
}

if (mkdir "data" and mkdir "data/log") {
  print "Created directory data/log/\n";
  my ($login,$pass,$uid,$gid) = getpwnam("daemon");
  chown $uid, $gid, "data/log";
} elsif (!-d "data/log") {
  die "Directory logs/ does not exist and cannot be created"; 
}

if (mkdir "$target/logs") {
  print "Created directory $target/logs\n";
} elsif (!-d "$target/logs") {
  die "Directory $target/logs does not exist and cannot be created"; 
}

if (mkdir "$target/data" and mkdir "$target/data/log") {
  print "Created directory $target/data/log\n";
} elsif (!-d "$target/data/log") {
  die "Directory $target/data/log does not exist and cannot be created"; 
}

my $tag = qx(git rev-parse HEAD);
my $devel = ($target eq 'www-devel');

my %untracked = map {
    (/ (.*)/g, 1)
} grep {
    /^\?/
} qx(git status --porcelain);

# if (!$devel) {
#     system "git", "diff", "--exit-code";

#     if ($?) {
#         die "Uncommitted changes, can't deploy";
#     }
# }

sub copy_with_mode {
    my ($mode, $from, $to) = @_;
    die if -d $to;

    make_path dirname $to;

    die "$from doesn't exist" if (!-f $from);

    if ($devel) {
        if (!-l $to) {
            symlink "$ENV{PWD}/$from", $to;
        }
        return 
    }

    if ($untracked{$from}) {
        die "untracked file '$from'\n"
    }

    copy $from, "$to.tmp" or die "Error copying $from to $to: $!";
    chmod $mode, "$to.tmp";
    rename "$to.tmp", $to;
}

sub mangle_with_mode {
    my ($mode, $from, $to, $mangle) = @_;
    my $data = $mangle->(scalar slurp "$from");

    my ($fh, $filename) = tempfile("tmpfileXXXXXXX",
                                   DIR=>"$target");
    print $fh $data;
    close $fh;
    chmod $mode, $filename;
    rename $filename, $to;
}

sub deploy_docs {
    # usage.html created during docker image creation rather than here to save on image size
    mangle_with_mode 0444, "usage.html", "$target/usage.html", sub {
        my $contents = shift;
        $contents =~ s{.*<body>}{}ms;
        $contents =~ s{</body>.*}{}ms;
        $contents;
    };
}

sub deploy_cgi {
    mkdir "$target/lib";
    for my $f (qw(app.fcgi
                  app.psgi)) {
        copy_with_mode 0555, "src/$f", "$target/lib/$f";
    }

    for my $f (qw(acting.pm
                  buildings.pm
                  commands.pm
                  cults.pm
                  Analyze/EloVpPredictor.pm
                  Analyze/RatingData.pm
                  DB/Chat.pm
                  DB/Connection.pm
                  DB/EditLink.pm
                  DB/Game.pm
                  DB/IndexGame.pm
                  DB/SaveGame.pm
                  DB/Secret.pm
                  DB/Settings.pm
                  DB/UserInfo.pm
                  DB/UserValidate.pm
                  DB/Validation.pm
                  Notify/Notify.pm
                  Notify/Settings.pm
                  Notify/Email.pm
                  Notify/SMS.pm
                  Game/Constants.pm
                  Game/Factions.pm
                  Game/Factions/Acolytes.pm
                  Game/Factions/Alchemists.pm
                  Game/Factions/Auren.pm
                  Game/Factions/Chaosmagicians.pm
                  Game/Factions/Cultists.pm
                  Game/Factions/Darklings.pm
                  Game/Factions/Dragonlords.pm
                  Game/Factions/Dwarves.pm
                  Game/Factions/Engineers.pm
                  Game/Factions/Fakirs.pm
                  Game/Factions/Giants.pm
                  Game/Factions/Halflings.pm
                  Game/Factions/Icemaidens.pm
                  Game/Factions/Mermaids.pm
                  Game/Factions/Nomads.pm
                  Game/Factions/Riverwalkers.pm
                  Game/Factions/Shapeshifters.pm
                  Game/Factions/Swarmlings.pm
                  Game/Factions/Witches.pm
                  Game/Factions/Yetis.pm
                  Game/Events.pm
                  income.pm
                  ledger.pm
                  map.pm
                  resources.pm
                  scoring.pm),
               qw(Server/Alias.pm
                  Server/AppendGame.pm 
                  Server/Chat.pm
                  Server/EditGame.pm
                  Server/JoinGame.pm
                  Server/ListGames.pm
                  Server/Login.pm
                  Server/Logout.pm
                  Server/Map.pm
                  Server/NewGame.pm
                  Server/Notifier.pm
                  Server/PasswordReset.pm
                  Server/Plan.pm
                  Server/Router.pm
                  Server/Register.pm
                  Server/Request.pm
                  Server/Results.pm
                  Server/SaveGame.pm
                  Server/Security.pm
                  Server/Server.pm
                  Server/Session.pm
                  Server/Settings.pm
                  Server/Template.pm
                  Server/UserInfo.pm 
                  Server/ViewGame.pm 
                  Util/NaturalCmp.pm
                  Util/CryptUtil.pm
                  Util/PageGenerator.pm
                  Util/PasswordQuality.pm
                  Util/ServerUtil.pm
                  Util/Watchdog.pm
                  towns.pm
                  tracker.pm)) {
        copy_with_mode 0444, "src/$f", "$target/lib/$f";
    }
}

sub deploy_stc {
    mkdir "$target/stc";
    for my $f (qw(alias.js
                  common.js
                  debug.js
                  edit.js
                  faction.js
                  game.js
                  index.js
                  joingame.js
                  map.js
                  newgame.js
                  notifier.js
                  ratings.js
                  register.js
                  reset.js
                  player.js
                  prototype-1.7.1.js
                  org.css
                  settings.js
                  spinner.gif
                  stats.js
                  style.css)) {
        copy_with_mode 0444, "stc/$f", "$target/stc/$f";
    }
    copy_with_mode 0444, "robots.txt", "$target/robots.txt";
    copy_with_mode 0444, "stc/favicon.ico", "$target/favicon.ico";
    copy_with_mode 0444, "stc/favicon-inactive.ico", "$target/favicon-inactive.ico";
}

sub deploy_data {
    for my $f (qw(changes.json)) {
        my $to = "$target/data/$f";
        copy_with_mode 0444, $f, $to;
    }

    for my $f (qw(pages/content/about.pl
                  pages/content/alias.pl
                  pages/content/changes.pl
                  pages/content/edit.pl
                  pages/content/game.pl
                  pages/content/faction.pl
                  pages/content/forcedreset.pl
                  pages/content/index.pl
                  pages/content/login.pl
                  pages/content/joingame.pl
                  pages/content/login.pl
                  pages/content/map.pl
                  pages/content/mapedit.pl
                  pages/content/newgame.pl
                  pages/content/notifier.pl
                  pages/content/player.pl
                  pages/content/factioninfo.pl
                  pages/content/ratings.pl
                  pages/content/register.pl
                  pages/content/reset.pl
                  pages/content/stats.pl
                  pages/content/settings.pl
                  pages/content/usage.pl),
               qw(pages/layout/sidebar.html
                  pages/layout/topbar.html)) {
        my $to = "$target/$f";
        copy_with_mode 0444, $f, $to;
    }
}


deploy_docs;
deploy_stc;
deploy_cgi;
deploy_data;

$target =~ s/www-//;
system qq{(echo -n "$target: "; git rev-parse HEAD) >> deploy.log};
system qq{git tag -f $target};

