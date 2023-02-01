package;
#if newgrounds

import flixel.FlxG;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import io.newgrounds.NG;
import io.newgrounds.NGLite;
import io.newgrounds.components.ScoreBoardComponent.Period;
import io.newgrounds.objects.Error;
import io.newgrounds.objects.Medal;
import io.newgrounds.objects.Score;
import io.newgrounds.objects.ScoreBoard;
import io.newgrounds.objects.events.Response;
import io.newgrounds.objects.events.Result.GetCurrentVersionResult;
import io.newgrounds.objects.events.Result.GetVersionResult;
import lime.app.Application;
import openfl.display.Stage;

using StringTools;
#end
/**
 * MADE BY GEOKURELI THE LEGENED GOD HERO MVP
 */
class NGio
{
	#if newgrounds
	/**
	 * True, if the saved sessionId was used in the initial login, and failed to connect.
	 * Used in MainMenuState to show a popup to establish a new connection
	 */
	public static var savedSessionFailed(default, null):Bool = false;
	public static var scoreboardsLoaded:Bool = false;
	public static var isLoggedIn(get, never):Bool;
	inline static function get_isLoggedIn()
	{
		return NG.core != null && NG.core.loggedIn;
	}

	public static var scoreboardArray:Array<Score> = [];

	public static var ngDataLoaded(default, null):FlxSignal = new FlxSignal();
	public static var ngScoresLoaded(default, null):FlxSignal = new FlxSignal();

	public static var GAME_VER:String = "";
	
	static public function checkVersion(callback:String->Void)
	{
		trace('checking NG.io version');
		GAME_VER = "v" + Application.current.meta.get('version');

		NG.core.calls.app.getCurrentVersion(GAME_VER)
			.addDataHandler(function(response)
			{
				GAME_VER = response.result.data.currentVersion;
				trace('CURRENT NG VERSION: ' + GAME_VER);
				callback(GAME_VER);
			})
			.send();
	}

	static public function init()
	{
		var api = APIStuff.API;
		if (api == null || api.length == 0)
		{
			trace("Missing Newgrounds API key, aborting connection");
			return;
		}
		trace("connecting to newgrounds");
		
		#if NG_FORCE_EXPIRED_SESSION
			var sessionId:String = "fake_session_id";
			function onSessionFail(error:Error)
			{
				trace("Forcing an expired saved session. "
					+ "To disable, comment out NG_FORCE_EXPIRED_SESSION in Project.xml");
				savedSessionFailed = true;
			}
		#else
			var sessionId:String = NGLite.getSessionId();
			if (sessionId != null)
				trace("found web session id");
			
			#if (debug)
			if (sessionId == null && APIStuff.SESSION != null)
			{
				trace("using debug session id");
				sessionId = APIStuff.SESSION;
			}
			#end
		
			var onSessionFail:Error->Void = null;
			if (sessionId == null && FlxG.save.data.sessionId != null)
			{
				trace("using stored session id");
				sessionId = FlxG.save.data.sessionId;
				onSessionFail = function (error) savedSessionFailed = true;
			}
		#end
		
		NG.create(api, sessionId, #if NG_DEBUG true #else false #end, onSessionFail);
		
		#if NG_VERBOSE NG.core.verbose = true; #end
		// Set the encryption cipher/format to RC4/Base64. AES128 and Hex are not implemented yet
		NG.core.initEncryption(APIStuff.EncKey); // Found in you NG project view

		if (NG.core.attemptingLogin)
		{
			/* a session_id was found in the loadervars, this means the user is playing on newgrounds.com
			 * and we should login shortly. lets wait for that to happen
			 */
			trace("attempting login");
			NG.core.onLogin.add(onNGLogin);
		}
		//GK: taking out auto login, adding a login button to the main menu
		// else
		// {
		// 	/* They are NOT playing on newgrounds.com, no session id was found. We must start one manually, if we want to.
		// 	 * Note: This will cause a new browser window to pop up where they can log in to newgrounds
		// 	 */
		// 	NG.core.requestLogin(onNGLogin);
		// }
	}
	
	/**
	 * Attempts to log in to newgrounds by requesting a new session ID, only call if no session ID was found automatically
	 * @param popupLauncher The function to call to open the login url, must be inside
	 * a user input event or the popup blocker will block it.
	 * @param onComplete A callback with the result of the connection.
	 */
	static public function login(?popupLauncher:(Void->Void)->Void, onComplete:ConnectionResult->Void)
	{
		trace("Logging in manually");
		var onPending:Void->Void = null;
		if (popupLauncher != null)
		{
			onPending = function () popupLauncher(NG.core.openPassportUrl);
		}
		
		var onSuccess:Void->Void = onNGLogin;
		var onFail:Error->Void = null;
		var onCancel:Void->Void = null;
		if (onComplete != null)
		{
			onSuccess = function ()
			{
				onNGLogin();
				onComplete(Success);
			}
			onFail = function (e) onComplete(Fail(e.message));
			onCancel = function() onComplete(Cancelled);
		}
		
		NG.core.requestLogin(onSuccess, onPending, onFail, onCancel);
	}
	
	inline static public function cancelLogin():Void
	{
		NG.core.cancelLoginRequest();
	}

	static function onNGLogin():Void
	{
		trace('logged in! user:${NG.core.user.name}');
		FlxG.save.data.sessionId = NG.core.sessionId;
		FlxG.save.flush();
		// Load medals then call onNGMedalFetch()
		NG.core.requestMedals(onNGMedalFetch);

		// Load Scoreboards hten call onNGBoardsFetch()
		NG.core.requestScoreBoards(onNGBoardsFetch);

		ngDataLoaded.dispatch();
	}
	
	static public function logout()
	{
		NG.core.logOut();
		
		FlxG.save.data.sessionId = null;
		FlxG.save.flush();
	}

	// --- MEDALS
	static function onNGMedalFetch():Void
	{
		/*
			// Reading medal info
			for (id in NG.core.medals.keys())
			{
				var medal = NG.core.medals.get(id);
				trace('loaded medal id:$id, name:${medal.name}, description:${medal.description}');
			}

			// Unlocking medals
			var unlockingMedal = NG.core.medals.get(54352);// medal ids are listed in your NG project viewer
			if (!unlockingMedal.unlocked)
				unlockingMedal.sendUnlock();
		 */
	}

	// --- SCOREBOARDS
	static function onNGBoardsFetch():Void
	{
		/*
			// Reading medal info
			for (id in NG.core.scoreBoards.keys())
			{
				var board = NG.core.scoreBoards.get(id);
				trace('loaded scoreboard id:$id, name:${board.name}');
			}
		 */
		// var board = NG.core.scoreBoards.get(8004);// ID found in NG project view

		// Posting a score thats OVER 9000!
		// board.postScore(FlxG.random.int(0, 1000));

		// --- To view the scores you first need to select the range of scores you want to see ---

		// add an update listener so we know when we get the new scores
		// board.onUpdate.add(onNGScoresFetch);
		trace("shoulda got score by NOW!");
		// board.requestScores(20);// get the best 10 scores ever logged
		// more info on scores --- http://www.newgrounds.io/help/components/#scoreboard-getscores
	}

	static function onNGScoresFetch():Void
	{
		scoreboardsLoaded = true;

		ngScoresLoaded.dispatch();
		/* 
			for (score in NG.core.scoreBoards.get(8737).scores)
			{
				trace('score loaded user:${score.user.name}, score:${score.formatted_value}');

			}
		 */

		// var board = NG.core.scoreBoards.get(8004);// ID found in NG project view
		// board.postScore(HighScore.score);

		// NGio.scoreboardArray = NG.core.scoreBoards.get(8004).scores;
	}
	#end

	static public function logEvent(event:String)
	{
		#if newgrounds
		NG.core.calls.event.logEvent(event).send();
		trace('should have logged: ' + event);
		#else
			#if debug trace('event:$event - not logged, missing NG.io lib'); #end
		#end
	}

	static public function unlockMedal(id:Int)
	{
		#if newgrounds
		if (isLoggedIn)
		{
			var medal = NG.core.medals.get(id);
			if (!medal.unlocked)
				medal.sendUnlock();
		}
		#else
			#if debug trace('medal:$id - not unlocked, missing NG.io lib'); #end
		#end
	}

	static public function postScore(score:Int = 0, song:String)
	{
		#if newgrounds
		if (isLoggedIn)
		{
			for (id in NG.core.scoreBoards.keys())
			{
				var board = NG.core.scoreBoards.get(id);

				if (song == board.name)
				{
					board.postScore(score, "Uhh meow?");
				}

				// trace('loaded scoreboard id:$id, name:${board.name}');
			}
		}
		#else
			#if debug trace('Song:$song, Score:$score - not posted, missing NG.io lib'); #end
		#end
	}
}

enum ConnectionResult
{
	/** Log in successful */
	Success;
	/** Could not login */
	Fail(msg:String);
	/** User cancelled the login */
	Cancelled;
}
