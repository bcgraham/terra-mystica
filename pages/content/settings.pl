{
    layout => 'sidebar',
    scripts => [ "/stc/common.js",
                 "/stc/settings.js"],
    title => 'Settings',
    content => read_then_close(*DATA)
}

__DATA__
<div id="error"></div>
<div id="settings">
  <table class="settings-table">
    <tr><td>Username<td><span id="username" enabled="false"></span></tr>
    <tr><td>Password<td><a href='/reset/'>Change password</a></tr>
    <tr><td>Display Name<td><input id="displayname" enabled="false"></input></tr>
    <tr><td>Email Addresses<td>
        The following validated email addresses are associated with
        this account.
        <div id="email"></div></tr>
    <tr><td>Primary email<td>
        If you have multiple registered addresses, email notifications will
        be sent to this address.
        <div id="primary-email-container"></div></tr>
    <tr><td>Notification method<td>
        You can receive game updates through channels other than email. 
        <div id="notification_method_div"></div></tr>
    <tr><td>Notifications<td>
        <div>
For games with email notifications turned on, you'll get 
notified for the following events:
        </div>
        <table>
<tr>
  <div>
    <input id="notify_turn" type="checkbox" enabled="false">
    <label for="notify_turn">Your turns</label>
  </div>
  <div>
    <input id="notify_all_moves" type="checkbox" enabled="false">
    <label for="notify_all_moves">All moves</label>
  </div>
  <div>
    <input id="notify_chat" type="checkbox" enabled="false">
    <label for="notify_chat">Chat messages</label>
  </div>
  <div>
    <input id="notify_game_status" type="checkbox" enabled="false">
    <label for="notify_game_status">Game status changes (e.g. game start or end)</label>
  </div>
</tr>
        </table>
    </tr>
    <tr><td><td><input type="button" value="Update" onclick="javascript:saveSettings()"></input></tr>
  </table>
</div>
<script language="javascript">
  loadSettings();
</script>
