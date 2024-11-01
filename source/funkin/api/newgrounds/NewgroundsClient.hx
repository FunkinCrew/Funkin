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
    trace('[NEWGROUNDS] Initializing client...');

    #if FEATURE_NEWGROUNDS_DEBUG
    trace('[NEWGROUNDS] App ID: ${NewgroundsCredentials.APP_ID}');
    trace('[NEWGROUNDS] Encryption Key: ${NewgroundsCredentials.ENCRYPTION_KEY}');
    #end

    if (!hasValidCredentials())
    {
      FlxG.log.warn("Tried to initialize Newgrounds client, but credentials are invalid!");
      return;
    }

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
   * @param onSuccess An optional callback for when the login is successful.
   * @param onError An optional callback for when the login fails.
   */
  public function login(?onSuccess:Void->Void, ?onError:Void->Void):Void
  {
    if (client == null)
    {
      FlxG.log.warn("No Newgrounds client initialized! Are your credentials invalid?");
      return;
    }

    if (onSuccess != null && onError != null)
    {
      client.requestLogin(onLoginResolvedWithCallbacks.bind(_, onSuccess, onError));
    }
    else
    {
      client.requestLogin(onLoginResolved);
    }
  }

  /**
   * Log out of Newgrounds and invalidate the current session.
   * @param onSuccess An optional callback for when the logout is successful.
   */
  public function logout(?onSuccess:Void->Void, ?onError:Void->Void):Void
  {
    if (client != null)
    {
      if (onSuccess != null && onError != null)
      {
        client.logOut(onLogoutResolvedWithCallbacks.bind(_, onSuccess, onError));
      }
      else
      {
        client.logOut(onLogoutResolved);
      }
    }

    Save.instance.ngSessionId = null;
  }

  public function isLoggedIn():Bool
  {
    return client != null && client.loggedIn;
  }

  /**
   * @returns `false` if either the app ID or the encryption key is invalid.
   */
  static function hasValidCredentials():Bool
  {
    return !(NewgroundsCredentials.APP_ID == null
      || NewgroundsCredentials.APP_ID == ""
      || NewgroundsCredentials.APP_ID.contains(" ")
      || NewgroundsCredentials.ENCRYPTION_KEY == null
      || NewgroundsCredentials.ENCRYPTION_KEY == ""
      || NewgroundsCredentials.ENCRYPTION_KEY.contains(" "));
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

  function onLoginResolvedWithCallbacks(outcome:LoginOutcome, onSuccess:Void->Void, onError:Void->Void):Void
  {
    onLoginResolved(outcome);

    switch (outcome)
    {
      case SUCCESS:
        onSuccess();
      case FAIL(result):
        onError();
    }
  }

  function onLogoutResolved(outcome:Outcome<CallError>):Void
  {
    switch (outcome)
    {
      case SUCCESS:
        onLogoutSuccessful();
      case FAIL(result):
        onLogoutFailed(result);
    }
  }

  function onLogoutResolvedWithCallbacks(outcome:Outcome<CallError>, onSuccess:Void->Void, onError:Void->Void):Void
  {
    onLogoutResolved(outcome);

    switch (outcome)
    {
      case SUCCESS:
        onSuccess();
      case FAIL(result):
        onError();
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

  function onLogoutSuccessful():Void
  {
    trace('[NEWGROUNDS] Logout successful!');
  }

  function onLogoutFailed(result:CallError):Void
  {
    switch (result)
    {
      case HTTP(error):
        trace('[NEWGROUNDS] Logout failed due to HTTP error: ${error}');
      case RESPONSE(error):
        trace('[NEWGROUNDS] Logout failed due to response error: ${error.message} (${error.code})');
      case RESULT(error):
        trace('[NEWGROUNDS] Logout failed due to result error: ${error.message} (${error.code})');
      default:
        trace('[NEWGROUNDS] Logout failed due to unknown error: ${result}');
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
