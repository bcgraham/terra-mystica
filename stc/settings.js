var state = null;

function loadOrSaveSettings(save) {
    var target = "/app/settings/";

    var form_params = {
        "cache-token": new Date() - Math.random(),
        "csrf-token": getCSRFToken()
    };
    if (save) {
        form_params['displayname'] = $("displayname").value;
        form_params['notify_turn'] = $("notify_turn").checked;
        form_params['notify_all_moves'] = $("notify_all_moves").checked;
        form_params['notify_chat'] = $("notify_chat").checked;
        form_params['notify_game_status'] = $("notify_game_status").checked;
        form_params['notification_method'] = $("notification_method").value;
        try {
            form_params['primary_email'] = $("primary_email").value;
        } catch (e) {
        }
        form_params['save'] = 1;
    }

    disableDescendants($("settings"));

    new Ajax.Request(target, {
        method: "post",
        parameters: form_params,
        onSuccess: function(transport){
            state = transport.responseText.evalJSON();
            enableDescendants($("settings"));
            if (state.link) {
                document.location = state.link;
            } else if (state.error.length) {
                $("error").innerHTML = state.error.join("<br>");
            } else {
                renderSettings(state);
            }
        }
    });
}

function loadSettings() {
    loadOrSaveSettings(false);
}

function saveSettings() {
    loadOrSaveSettings(true);
}

function renderSettings(state) {
    $("username").innerHTML = state.username;
    $("displayname").value = state.displayname;
    var newEmailList = new Element("ul");
    var first = true;
    var primarySelect = new Element("select", {"id": "primary_email"});
    $H(state.email).each(function (elem) {
        var row = new Element("li");
        var option = new Element("option", {"value": elem.key}).update(elem.key);
        
        if (first || elem.value.is_primary) {
            option.selected = true;
        }

        row.update(elem.key);
        newEmailList.insert(row);
        primarySelect.insert(option);
        first = false;
    });
    newEmailList.insert(new Element("div").update(
        new Element("a", { "href": "/alias/request/"}).update(
            "Add new address")));

    $("notify_turn").checked = state.notify_turn;
    $("notify_all_moves").checked = state.notify_all_moves;
    $("notify_chat").checked = state.notify_chat;
    $("notify_game_status").checked = state.notify_game_status;

    $("email").update(newEmailList);
    $("primary-email-container").update(primarySelect);

    var primaryNotifierSelect = $("notification_method");
    $H(state.notifier).each(function (elem) {
        var option = new Element("option", {"value": elem.key}).update(elem.value.name);
        
        if (elem.value.is_primary) {
            option.selected = true;
        }

        primaryNotifierSelect.insert(option);
    });
    newNotifierList.insert(new Element("div").update(
        new Element("a", { "href": "/notifier/request/"}).update(
            "Add new notifier")));

}
