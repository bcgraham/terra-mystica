var state = null;
var id = document.location.pathname;

function listGames(games, div, mode, status) {
    var action_required_count = 0;
    var fields = $H({
        "id": "Game",
        "link": "Faction",
        "time_since_update": "Last move",
        "round": "Round",
        "waiting_for": "Waiting for",
        "status_msg": "Status",
        "vp": "VP"
    });
    if (isMobile.any()) {
       fields = $H({
        "id": "Game",
        "link": "Faction",
        "status_msg": "Status",
       }); 
    }

    var thead = new Element("thead");
    var tbody = new Element("tbody");
    fields.each(function (field) {
        thead.insert(new Element("td").update(field.value));
    });
    games.each(function(elem) {
        elem.status = "";
        elem.status_msg = "";
        if (elem.dropped) {
            elem.status = "game-status-dropped";
            elem.status_msg = "dropped out";
        } else if (elem.action_required && !elem.aborted) {
            elem.status = "game-status-action-required";
            if (mode == "user") {
                elem.status_msg = "your turn";
            } else {
                elem.status_msg = "player's turn";
            }

            action_required_count++;

            if (elem.deadline_hours) {
                var deadline_seconds = elem.deadline_hours * 3600;
                if (elem.seconds_since_update >= deadline_seconds * 0.75) {
                    var dropping_in_seconds = deadline_seconds - elem.seconds_since_update
                    var dropping_in = seconds_to_pretty_time(dropping_in_seconds);

                    if (dropping_in_seconds <= 0) {
                        elem.status_msg += ", drop imminent ";
                    } else {
                        elem.status_msg += ", dropping in " + dropping_in;
                    }
                    elem.status = 'game-status-dropping-soon';
                }
            }
        } else if (elem.unread_chat_messages > 0) {
            elem.status = "game-status-action-unread-chat";
            elem.status_msg = "new chat";
            action_required_count++;
        }

        if (elem.seconds_since_update) {
            elem.time_since_update = seconds_to_pretty_time(elem.seconds_since_update) + " ago";
        }
        if (elem.vp) { elem.vp += " vp"; }
        if (elem.rank) { elem.vp += " (" + elem.rank + ")"; }

        if (elem.aborted) {
            elem.vp = "";
            elem.status_msg = "aborted";
        } else if (elem.finished) {
            elem.status_msg = "finished";
        }
        elem.link = new Element("a", {"href": elem.link, "class": "passthrough-color"}).update(elem.role);

        var row = new Element("tr", {"class": elem.status});
        fields.each(function(field) {
            var td;
            if (field.key == "link") {
                td = factionTableCell(elem.role);
                td.innerHTML = "";
                td.insert(elem.link);
            } else {
                td = new Element("td").update(elem[field.key])
            }
            row.insert(td);
        });

        $(tbody).insert(row);
    });
    if (mode == "user") {
        var link = new Element('a', {"href": "#", "accesskey": "n"}).update("Refresh");
        link.onclick = function() { fetchGames(div, mode, status, nextGame); } 
        var td = new Element('td').insert(link);
        var tr = new Element('tr').insert(new Element("td")).insert(td);
        $(tbody).insert(tr);

        if (status == "running") {
            moveRequired = (action_required_count > 0);
            setTitle();
        }
    }

    $(div).update("");
    $(div).insert(thead);
    $(div).insert(tbody);
}

function nextGame(games, div, mode, status) {
    games.each(function(elem) {
        if (elem.action_required) { document.location = elem.link; }
    });
    listGames(games, div, mode, status);
}

