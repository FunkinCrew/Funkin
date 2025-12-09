package funkin.api.newgrounds;

import funkin.save.Save;
import funkin.api.newgrounds.Medals.Medal;
#if FEATURE_NEWGROUNDS
import io.newgrounds.Call.CallError;
import io.newgrounds.NG;
import io.newgrounds.NGLite;
import io.newgrounds.NGLite.LoginOutcome;
import io.newgrounds.NGLite.LoginFail;
import io.newgrounds.objects.events.Outcome;
import io.newgrounds.utils.MedalList;
import io.newgrounds.utils.SaveSlotList;
import io.newgrounds.utils.ScoreBoardList;
import io.newgrounds.objects.User;

@:build(funkin.util.macro.EnvironmentMacro.build())
@:nullSafety
class NewgroundsClient
{
  @:envField
  static final API_NG_APP_ID:Null<String>;

  @:envField
  static final API_NG_ENC_KEY:Null<String>;

  public static var instance(get, never):NewgroundsClient;

  static var _instance:Null<NewgroundsClient> = null;

  static function get_instance():NewgroundsClient
  {
    if (NewgroundsClient._instance == null) _instance = new NewgroundsClient();
    if (NewgroundsClient._instance == null) throw "Could not initialize singleton NewgroundsClient!";
    return NewgroundsClient._instance;
  }

  public var user(get, never):Null<User>;
  public var medals(get, never):Null<MedalList>;
  public var leaderboards(get, never):Null<ScoreBoardList>;
  public var saveSlots(get, never):Null<SaveSlotList>;

  private function new()
  {
    trace(' NEWGROUNDS '.bold().bg_orange() + ' Initializing client...');

    #if FEATURE_NEWGROUNDS_DEBUG
    trace(' NEWGROUNDS '.bold().bg_orange() + ' App ID: ${API_NG_APP_ID}');
    trace(' NEWGROUNDS '.bold().bg_orange() + ' Encryption Key: ${API_NG_ENC_KEY}');
    #end

    if (!hasValidCredentials())
    {
      FlxG.log.warn("Tried to initialize Newgrounds client, but credentials are invalid!");
      return;
    }

    @:nullSafety(Off)
    {
      NG.create(API_NG_APP_ID, getSessionId(), #if FEATURE_NEWGROUNDS_DEBUG true #else false #end, onLoginResolved);

      NG.core.setupEncryption(API_NG_ENC_KEY);
    }
  }

  public function init()
  {
    if (NG.core == null) return;

    trace(' NEWGROUNDS '.bold().bg_orange() + ' Setting up connection...');

    #if FEATURE_NEWGROUNDS_DEBUG
    NG.core.verbose = true;
    #end

    NG.core.onLogin.add(onLoginSuccessful);

    if (NG.core.attemptingLogin)
    {
      // Session ID was valid and we should be logged in soon.
      trace(' NEWGROUNDS '.bold().bg_orange() + ' Waiting for existing login!');
    }
    else
    {
      #if FEATURE_NEWGROUNDS_AUTOLOGIN
      // Attempt an automatic login.
      trace(' NEWGROUNDS '.bold().bg_orange() + ' Attempting new login immediately!');
      this.autoLogin();
      #else
      trace(' NEWGROUNDS '.bold().bg_orange() + ' Not logged in, you have to login manually!');
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
    if (NG.core == null)
    {
      FlxG.log.warn("No Newgrounds client initialized! Are your credentials invalid?");
      return;
    }

    if (NG.core.attemptingLogin)
    {
      trace(" NEWGROUNDS '.bold().bg_orange() + ' Login attempt ongoing, will not login until finished.");
      return;
    }

    if (onSuccess != null && onError != null)
    {
      NG.core.requestLogin(onLoginResolvedWithCallbacks.bind(_, onSuccess, onError));
    }
    else
    {
      NG.core.requestLogin(onLoginResolved);
    }
  }

  public function autoLogin(?onSuccess:Void->Void, ?onError:Void->Void):Void
  {
    if (NG.core == null)
    {
      FlxG.log.warn("No Newgrounds client initialized! Are your credentials invalid?");
      return;
    }

    var dummyPassport:String->Void = function(_) {
      // just a dummy passport, so we don't create a popup
      // otherwise `NG.core.requestLogin()` will automatically attempt to open a tab at the beginning of the game
      // users should go to the Options Menu to login to NG
      // we cancel the request, so we can call it later
      NG.core.cancelLoginRequest();
    };

    if (onSuccess != null && onError != null)
    {
      NG.core.requestLogin(onLoginResolvedWithCallbacks.bind(_, onSuccess, onError), dummyPassport);
    }
    else
    {
      NG.core.requestLogin(onLoginResolved, dummyPassport);
    }
  }

  /**
   * Log out of Newgrounds and invalidate the current session.
   * @param onSuccess An optional callback for when the logout is successful.
   */
  public function logout(?onSuccess:Void->Void, ?onError:Void->Void):Void
  {
    if (NG.core != null)
    {
      if (onSuccess != null && onError != null)
      {
        NG.core.logOut(onLogoutResolvedWithCallbacks.bind(_, onSuccess, onError));
      }
      else
      {
        NG.core.logOut(onLogoutResolved);
      }
    }

    Save.instance.ngSessionId.value = null;
  }

  /**
   * @return `true` if the user is logged in to Newgrounds.
   */
  public function isLoggedIn():Bool
  {
    #if FEATURE_NEWGROUNDS
    return NG.core != null && NG.core.loggedIn;
    #else
    return false;
    #end
  }

  /**
   * @returns `false` if either the app ID or the encryption key is invalid.
   */
  static function hasValidCredentials():Bool
  {
    return !(API_NG_APP_ID == null
      || API_NG_APP_ID == ""
      || (API_NG_APP_ID != null && API_NG_APP_ID.contains(" "))
      || API_NG_ENC_KEY == null
      || API_NG_ENC_KEY == ""
      || (API_NG_ENC_KEY != null && API_NG_ENC_KEY.contains(" ")));
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
    if (NG.core == null) return;

    trace(' NEWGROUNDS '.bold().bg_orange() + ' Login successful!');

    // Persist the session ID.
    Save.instance.ngSessionId.value = NG.core.sessionId;

    trace(' NEWGROUNDS '.bold().bg_orange() + ' Submitting medal request...');
    NG.core.requestMedals(onFetchedMedals);

    trace(' NEWGROUNDS '.bold().bg_orange() + ' Submitting leaderboard request...');
    NG.core.scoreBoards.loadList(onFetchedLeaderboards);
    trace(' NEWGROUNDS '.bold().bg_orange() + ' Submitting save slot request...');
    NG.core.saveSlots.loadList(onFetchedSaveSlots);
  }

  function onLoginFailed(result:LoginFail):Void
  {
    switch (result)
    {
      case CANCELLED(type):
        switch (type)
        {
          case PASSPORT:
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Login cancelled by passport website.');
          case MANUAL:
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Login cancelled by application.');
          default:
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Login cancelled by unknown source.');
        }
      case ERROR(error):
        switch (error)
        {
          case HTTP(error):
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Login failed due to HTTP error: ${error}');
          case RESPONSE(error):
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Login failed due to response error: ${error.message} (${error.code})');
          case RESULT(error):
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Login failed due to result error: ${error.message} (${error.code})');
          default:
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Login failed due to unknown error: ${error}');
        }
      default:
        trace(' NEWGROUNDS '.bold().bg_orange() + ' Login failed due to unknown reason.');
    }
  }

  function onLogoutSuccessful():Void
  {
    trace(' NEWGROUNDS '.bold().bg_orange() + ' Logout successful!');
  }

  function onLogoutFailed(result:CallError):Void
  {
    switch (result)
    {
      case HTTP(error):
        trace(' NEWGROUNDS '.bold().bg_orange() + ' Logout failed due to HTTP error: ${error}');
      case RESPONSE(error):
        trace(' NEWGROUNDS '.bold().bg_orange() + ' Logout failed due to response error: ${error.message} (${error.code})');
      case RESULT(error):
        trace(' NEWGROUNDS '.bold().bg_orange() + ' Logout failed due to result error: ${error.message} (${error.code})');
      default:
        trace(' NEWGROUNDS '.bold().bg_orange() + ' Logout failed due to unknown error: ${result}');
    }
  }

  function onFetchedMedals(outcome:Outcome<CallError>):Void
  {
    trace(' NEWGROUNDS '.bold().bg_orange() + ' Fetched medals!');
  }

  function onFetchedLeaderboards(outcome:Outcome<CallError>):Void
  {
    trace(' NEWGROUNDS '.bold().bg_orange() + ' Fetched leaderboards!');

    // trace(funkin.api.newgrounds.Leaderboards.listLeaderboardData());
  }

  function onFetchedSaveSlots(outcome:Outcome<CallError>):Void
  {
    trace(' NEWGROUNDS '.bold().bg_orange() + ' Fetched save slots!');

    NGSaveSlot.instance.checkSlot();
  }

  function get_user():Null<User>
  {
    if (NG.core == null || !this.isLoggedIn()) return null;
    return NG.core.user;
  }

  function get_medals():Null<MedalList>
  {
    if (NG.core == null || !this.isLoggedIn()) return null;
    return NG.core.medals;
  }

  function get_leaderboards():Null<ScoreBoardList>
  {
    if (NG.core == null || !this.isLoggedIn()) return null;
    return NG.core.scoreBoards;
  }

  function get_saveSlots():Null<SaveSlotList>
  {
    if (NG.core == null || !this.isLoggedIn()) return null;
    return NG.core.saveSlots;
  }

  static function getSessionId():Null<String>
  {
    #if js
    // We can fetch the session ID from the URL.
    var result:Null<String> = NGLite.getSessionId();
    if (result != null) return result;
    #end

    // We have to fetch the session ID from the save file.
    return Save.instance.ngSessionId.value;
  }
}

/**
 * Wrapper for `NewgroundsClient` that prevents submitting cheated data.
 */
class NewgroundsClientSandboxed
{
  public static var user(get, never):Null<User>;

  static function get_user()
  {
    return NewgroundsClient.instance.user;
  }

  public static function isLoggedIn()
  {
    return NewgroundsClient.instance.isLoggedIn();
  }
}
#end
