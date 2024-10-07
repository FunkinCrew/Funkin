package funkin.api.newgrounds;

import funkin.save.Save;
import funkin.api.newgrounds.Medals;
#if FEATURE_NEWGROUNDS
import io.newgrounds.Call.CallError;
import io.newgrounds.NG;
import io.newgrounds.NGLite;
import io.newgrounds.NGLite.LoginOutcome;
import io.newgrounds.NGLite.LoginFail;
import io.newgrounds.objects.events.Outcome;
import io.newgrounds.utils.MedalList;
import io.newgrounds.utils.ScoreBoardList;
import io.newgrounds.objects.User;

@:nullSafety
class NewgroundsClient
{
  static final CLIENT_ID:String = "816168432860790794";

  public static var instance(get, never):NewgroundsClient;
  static var _instance:Null<NewgroundsClient> = null;

  static function get_instance():NewgroundsClient
  {
    if (NewgroundsClient._instance == null) _instance = new NewgroundsClient();
    if (NewgroundsClient._instance == null) throw "Could not initialize singleton NewgroundsClient!";
    return NewgroundsClient._instance;
  }

  var client:Null<NG>;

  public var user(get, never):Null<User>;
  public var medals(get, never):Null<MedalList>;
  public var leaderboards(get, never):Null<ScoreBoardList>;

  private function new()
  {
    if (NewgroundsCredentials.ENCRYPTION_KEY.contains(' '))
    {
      trace('[NEWGROUNDS] Encryption key not valid, disabling...');
      return;
    }

    trace('[NEWGROUNDS] Initializing client...');
    var debug = #if FEATURE_NEWGROUNDS_DEBUG true #else false #end;
    client = new NG(NewgroundsCredentials.APP_ID, getSessionId(), debug, onLoginResolved);
    client.setupEncryption(NewgroundsCredentials.ENCRYPTION_KEY);
  }

  public function init()
  {
    if (client == null) return;

    trace('[NEWGROUNDS] Setting up connection...');

    #if FEATURE_NEWGROUNDS_DEBUG
    client.verbose = true;
    #end

    client.onLogin.add(onLoginSuccessful);

    if (client.attemptingLogin)
    {
      // Session ID was valid and we should be logged in soon.
      trace('[NEWGROUNDS] Waiting for existing login!');
    }
    else
    {
      #if FEATURE_NEWGROUNDS_AUTOLOGIN
      // Attempt an automatic login.
      trace('[NEWGROUNDS] Attempting new login immediately!');
      this.login();
      #else
      trace('[NEWGROUNDS] Not logged in, you have to login manually!');
      #end
    }
  }

  /**
   * Attempt to log into Newgrounds and create a session ID.
   */
  public function login():Void
  {
    if (client == null) return;
    client.requestLogin(onLoginResolved);
  }

  /**
   * Log out of Newgrounds and invalidate the current session.
   */
  public function logout():Void
  {
    if (client != null) client.logOut();

    Save.instance.ngSessionId = null;
    client = null;
  }

  public function isLoggedIn():Bool
  {
    return client != null && client.loggedIn;
  }

  function onLoginResolved(outcome:LoginOutcome):Void
  {
    switch (outcome)
    {
      case SUCCESS:
        onLoginSuccessful();
      case FAIL(result):
        onLoginFailed(result);
    }
  }

  function onLoginSuccessful():Void
  {
    if (client == null) return;

    trace('[NEWGROUNDS] Login successful!');

    // Persist the session ID.
    Save.instance.ngSessionId = client.sessionId;

    trace('[NEWGROUNDS] Submitting medal request...');
    client.requestMedals(onFetchedMedals);
    trace('[NEWGROUNDS] Submitting leaderboard request...');
    client.scoreBoards.loadList(onFetchedLeaderboards);
  }

  function onLoginFailed(result:LoginFail):Void
  {
    switch (result)
    {
      case CANCELLED(type):
        switch (type)
        {
          case PASSPORT:
            trace('[NEWGROUNDS] Login cancelled by passport website.');
          case MANUAL:
            trace('[NEWGROUNDS] Login cancelled by application.');
          default:
            trace('[NEWGROUNDS] Login cancelled by unknown source.');
        }
      case ERROR(error):
        switch (error)
        {
          case HTTP(error):
            trace('[NEWGROUNDS] Login failed due to HTTP error: ${error}');
          case RESPONSE(error):
            trace('[NEWGROUNDS] Login failed due to response error: ${error.message} (${error.code})');
          case RESULT(error):
            trace('[NEWGROUNDS] Login failed due to result error: ${error.message} (${error.code})');
          default:
            trace('[NEWGROUNDS] Login failed due to unknown error: ${error}');
        }
      default:
        trace('[NEWGROUNDS] Login failed due to unknown reason.');
    }
  }

  function onFetchedMedals(outcome:Outcome<CallError>):Void
  {
    trace('[NEWGROUNDS] Fetched medals!');

    Medals.award(Medal.StartGame);
  }

  function onFetchedLeaderboards(outcome:Outcome<CallError>):Void
  {
    trace('[NEWGROUNDS] Fetched leaderboards!');

    trace(funkin.api.newgrounds.Leaderboards.listLeaderboardData());
  }

  function get_user():Null<User>
  {
    if (client == null || !this.isLoggedIn()) return null;
    return client.user;
  }

  function get_medals():Null<MedalList>
  {
    if (client == null || !this.isLoggedIn()) return null;
    return client.medals;
  }

  function get_leaderboards():Null<ScoreBoardList>
  {
    if (client == null || !this.isLoggedIn()) return null;
    return client.scoreBoards;
  }

  static function getSessionId():Null<String>
  {
    #if js
    // We can fetch the session ID from the URL.
    var result:Null<String> = NGLite.getSessionId();
    if (result != null) return result;
    #end

    // We have to fetch the session ID from the save file.
    return Save.instance.ngSessionId;
  }
}
#end
