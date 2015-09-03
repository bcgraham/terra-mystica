function register() {
    $("error").innerHTML = "";
    $("validate").style.display = "none";

    try {
        var fields = ["to", "notifier_type"];
        var error = "";

        fields.each(function (field) {
            $(field).style.backgroundColor = "#fff";
        });

        fields.each(function (field) {
            if ($(field).value == "") {
                $(field).style.backgroundColor = "#fbb";
                error += "Field " + field + " must be non-empty<br>";
            }
        });

        if (error != "") {
            throw error;
        }

        $("csrf-token").value = getCSRFToken();
        $("notifierinfo").request({
            method:"post",
            onFailure: function() {
                    $("error").innerHTML = "An unknown error occured";
            },
            onSuccess: function(transport) {
                state = transport.responseText.evalJSON();
                if (state.error.length) {
                    $("error").innerHTML = state.error.join("<br>");
                } else {
                    $("validate").style.display = "block";
                    $("usage").style.display = "none";
                }
            }
        });    
    } catch (e) {
        handleException(e);
    }
}

function loadNotifiers() {
    var target = "/app/notifier/list-available/";

    var form_params = {
        "cache-token": new Date() - Math.random(),
        "csrf-token": getCSRFToken()
    };

    disableDescendants($("notifiers"));

    new Ajax.Request(target, {
        method: "post",
        parameters: form_params,
        onSuccess: function(transport){
            state = transport.responseText.evalJSON();
            enableDescendants($("notifiers"));
            if (state.link) {
                document.location = state.link;
            } else if (state.error.length) {
                $("error").innerHTML = state.error.join("<br>");
            } else {
                renderNotifiers(state);
            }
        }
    });
}

function renderNotifier() {
    var notifier_type = $("notifier_type"); 
    $("recipient_word").update(notifier_type.readAttribute("data-recipient-word")); 
}

function renderNotifiers(state) {
    var notifier_type = $("notifier_type"); 
    $H(state.notifier).each(function (elem) {
        var option = new Element("option", {"value": elem.key, "data-recipient-word": elem.recipient_word}).update(elem.displayname);
        
        if (elem.value.is_primary) {
            option.selected = true;
        }

        notifier_type.insert(option);
    });

}
