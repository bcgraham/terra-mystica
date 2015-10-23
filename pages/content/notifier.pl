{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/notifier.js" ],
    title => 'Register Notifier',
    content => read_then_close(*DATA)
}

__DATA__
    <div id="error"></div>
    <div id="notifiers">
    <form id="notifierinfo" action="/app/notifier/request/">
      <table>
        <tr><td>Notifier Type<td><select name="notifier_type" id="notifier_type" onchange="javascript:renderNotifier();" enabled="false"></select>
        <tr><td><div id="recipient_word"></div><td><input name="to" id="to" enabled="false"></input>
        <tr><td><td><input type="button" value="Register" onclick="javascript:register()" enabled="false"></input>
      </table>
      <input type="hidden" id="csrf-token" name="csrf-token" value="">
    </form>
    </div>
    <div id="usage" style="display: block">
    <p>
      You can register to receive game updates by methods other than email (such as SMS). 
    </p>
    </div>
    <div id="validate" style="display: none">
      <p>
      The notifier will be registered as soon as we can validate it.
      You should have received a message with the message "notifier 
      validation for Terra Mystica". Please click on
      the link in that message to activate the new notifier.

      <p>
      Haven't received the validation message? Please check:
      <ul>
        <li> That you entered the correct recipient information above
      </ul>
    </div>
<script language="javascript">
  loadNotifiers();
</script>
