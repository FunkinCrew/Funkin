package io.newgrounds;

#if ng_lite
typedef NG = NGLite; //TODO: test and make lite UI
#else
import io.newgrounds.utils.Dispatcher;
import io.newgrounds.objects.Error;
import io.newgrounds.objects.events.Result.SessionResult;
import io.newgrounds.objects.events.Result.MedalListResult;
import io.newgrounds.objects.events.Result.ScoreBoardResult;
import io.newgrounds.objects.events.Response;
import io.newgrounds.objects.User;
import io.newgrounds.objects.Medal;
import io.newgrounds.objects.Session;
import io.newgrounds.objects.ScoreBoard;

import haxe.ds.IntMap;
import haxe.Timer;

/**
 * The Newgrounds API for Haxe.
 * Contains many things ripped from MSGhero
 *   - https://github.com/MSGhero/NG.hx
 * @author GeoKureli
 */
class NG extends NGLite {
	
	static public var core(default, null):NG;
	static public var onCoreReady(default, null):Dispatcher = new Dispatcher();
	
	// --- DATA
	
	/** The logged in user */
	public var user(get, never):User;
	function get_user():User {
		
		if (_session == null)
			return null;
		
		return _session.user;
	}
	public var passportUrl(get, never):String;
	function get_passportUrl():String {
		
		if (_session == null || _session.status != SessionStatus.REQUEST_LOGIN)
			return null;
		
		return _session.passportUrl;
	}
	public var medals(default, null):IntMap<Medal>;
	public var scoreBoards(default, null):IntMap<ScoreBoard>;
	
	// --- EVENTS
	
	public var onLogin(default, null):Dispatcher;
	public var onLogOut(default, null):Dispatcher;
	public var onMedalsLoaded(default, null):Dispatcher;
	public var onScoreBoardsLoaded(default, null):Dispatcher;
	
	// --- MISC
	
	public var loggedIn(default, null):Bool;
	public var attemptingLogin(default, null):Bool;
	
	var _loginCancelled:Bool;
	var _passportCallback:Void->Void;
	
	var _session:Session;
	
	/** 
	 * Iniitializes the API, call before utilizing any other component
	 * @param appId     The unique ID of your app as found in the 'API Tools' tab of your Newgrounds.com project.
	 * @param sessionId A unique session id used to identify the active user.
	**/
	public function new(appId = "test", sessionId:String = null, ?onSessionFail:Error->Void) {
		
		_session = new Session(this);
		onLogin = new Dispatcher();
		onLogOut = new Dispatcher();
		onMedalsLoaded = new Dispatcher();
		onScoreBoardsLoaded = new Dispatcher();
		
		attemptingLogin = sessionId != null;
		
		super(appId, sessionId, onSessionFail);
	}
	
	/**
	 * Creates NG.core, the heart and soul of the API. This is not the only way to create an instance,
	 * nor is NG a forced singleton, but it's the only way to set the static NG.core.
	**/
	static public function create(appId = "test", sessionId:String = null, ?onSessionFail:Error->Void):Void {
		
		core = new NG(appId, sessionId, onSessionFail);
		
		onCoreReady.dispatch();
	}
	
	/**
	 * Creates NG.core, and tries to create a session. This is not the only way to create an instance,
	 * nor is NG a forced singleton, but it's the only way to set the static NG.core.
	**/
	static public function createAndCheckSession
	( appId = "test"
	, backupSession:String = null
	, ?onSessionFail:Error->Void
	):Void {
		
		var session = NGLite.getSessionId();
		if (session == null)
			session = backupSession;
		
		create(appId, session, onSessionFail);
		
		core.host = getHost();
		if (core.sessionId != null)
			core.attemptingLogin = true;
	}
	
	// -------------------------------------------------------------------------------------------
	//                                         APP
	// -------------------------------------------------------------------------------------------
	
	override function checkInitialSession(failHandler:Error->Void, response:Response<SessionResult>):Void {
		
		onSessionReceive(response, null, null, failHandler);
	}
	
	/**
	 * Begins the login process
	 * 
	 * @param onSuccess Called when the login is a success
	 * @param onPending Called when the passportUrl has been identified, call NG.core.openPassportLink 
	 *                  to open the link continue the process. Leave as null to open the url automatically
	 *                  NOTE: Browser games must open links on click events or else it will be blocked by
	 *                  the popup blocker.
	 * @param onFail    
	 * @param onCancel  Called when the user denies the passport connection.
	 */
	public function requestLogin
	( onSuccess:Void->Void  = null
	, onPending:Void->Void  = null
	, onFail   :Error->Void = null
	, onCancel :Void->Void  = null
	):Void {
		
		if (attemptingLogin) {
			
			logError("cannot request another login until the previous attempt is complete");
			return;
		}
		
		if (loggedIn) {
			
			logError("cannot log in, already logged in");
			return;
		}
		
		attemptingLogin = true;
		_loginCancelled = false;
		_passportCallback = null;
		
		var call = calls.app.startSession(true)
			.addDataHandler(onSessionReceive.bind(_, onSuccess, onPending, onFail, onCancel));
		
		if (onFail != null)
			call.addErrorHandler(onFail);
		
		call.send();
	}
	
	function onSessionReceive
	( response :Response<SessionResult>
	, onSuccess:Void->Void = null
	, onPending:Void->Void = null
	, onFail   :Error->Void = null
	, onCancel :Void->Void = null
	):Void {
		
		if (!response.success || !response.result.success) {
			
			sessionId = null;
			endLoginAndCall(null);
			
			if (onFail != null)
				onFail(!response.success ? response.error : response.result.error);
			
			return;
		}
		
		_session.parse(response.result.data.session);
		sessionId = _session.id;
		
		logVerbose('session started - status: ${_session.status}');
		
		if (_session.status == SessionStatus.REQUEST_LOGIN) {
			
			_passportCallback = checkSession.bind(null, onSuccess, onCancel);
			if (onPending != null)
				onPending();
			else
				openPassportUrl();
			
		} else
			checkSession(null, onSuccess, onCancel);
	}
	
	/**
	 * Call this once the passport link is established and it will load the passport URL and
	 * start checking for session connect periodically
	 */
	public function openPassportUrl():Void {
		
		if (passportUrl != null) {
			
			logVerbose('loading passport: ${passportUrl}');
			openPassportHelper(passportUrl);
			onPassportUrlOpen();
			
		} else
			logError("Cannot open passport");
	}
	
	
	static function openPassportHelper(url:String):Void {
		var window = "_blank";
		
		#if flash
			flash.Lib.getURL(new flash.net.URLRequest(url), window);
		#elseif (js && html5)
			js.Browser.window.open(url, window);
		#elseif desktop
			
			#if (sys && windows)
				Sys.command("start", ["", url]);
			#elseif mac
				Sys.command("/usr/bin/open", [url]);
			#elseif linux
				Sys.command("/usr/bin/xdg-open", [path, "&"]);
			#end
			
		#elseif android
			JNI.createStaticMethod
				( "org/haxe/lime/GameActivity"
				, "openURL"
				, "(Ljava/lang/String;Ljava/lang/String;)V"
				) (url, window);
		#end
	}
	
	/**
	 * Call this once the passport link is established and it will start checking for session connect periodically
	 */
	public function onPassportUrlOpen():Void {
		
		if (_passportCallback != null)
			_passportCallback();
		
		_passportCallback = null;
	}
	
	function checkSession(response:Response<SessionResult>, onSucceess:Void->Void, onCancel:Void->Void):Void {
		
		if (response != null) {
			
			if (!response.success || !response.result.success) {
				
				log("login cancelled via passport");
				
				endLoginAndCall(onCancel);
				return;
			}
			
			_session.parse(response.result.data.session);
		}
		
		if (_session.status == SessionStatus.USER_LOADED) {
			
			loggedIn = true;
			endLoginAndCall(onSucceess);
			onLogin.dispatch();
			
		} else if (_session.status == SessionStatus.REQUEST_LOGIN){
			
			var call = calls.app.checkSession()
				.addDataHandler(checkSession.bind(_, onSucceess, onCancel));
			
			// Wait 3 seconds and try again
			timer(3.0,
				function():Void {
					
					// Check if cancelLoginRequest was called
					if (!_loginCancelled)
						call.send();
					else {
						
						log("login cancelled via cancelLoginRequest");
						endLoginAndCall(onCancel);
					}
				}
			);
			
		} else
			// The user cancelled the passport
			endLoginAndCall(onCancel);
	}
	
	public function cancelLoginRequest():Void {
		
		if (attemptingLogin)
			_loginCancelled = true;
	}
	
	function endLoginAndCall(callback:Void->Void):Void {
		
		attemptingLogin = false;
		_loginCancelled = false;
		
		if (callback != null)
			callback();
	}
	
	public function logOut(onComplete:Void->Void = null):Void {
		
		var call = calls.app.endSession()
			.addSuccessHandler(onLogOutSuccessful);
		
		if (onComplete != null)
			call.addSuccessHandler(onComplete);
		
		call.addSuccessHandler(onLogOut.dispatch)
			.send();
	}
	
	function onLogOutSuccessful():Void {
		
		_session.expire();
		sessionId = null;
		loggedIn = false;
	}
	
	// -------------------------------------------------------------------------------------------
	//                                       MEDALS
	// -------------------------------------------------------------------------------------------
	
	public function requestMedals(onSuccess:Void->Void = null, onFail:Error->Void = null):Void {
		
		var call = calls.medal.getList()
			.addDataHandler(onMedalsReceived);
		
		if (onSuccess != null)
			call.addSuccessHandler(onSuccess);
		
		if (onFail != null)
			call.addErrorHandler(onFail);
		
		call.send();
	}
	
	function onMedalsReceived(response:Response<MedalListResult>):Void {
		
		if (!response.success || !response.result.success)
			return;
		
		var idList:Array<Int> = new Array<Int>();
		
		if (medals == null) {
			
			medals = new IntMap<Medal>();
			
			for (medalData in response.result.data.medals) {
				
				var medal = new Medal(this, medalData);
				medals.set(medal.id, medal);
				idList.push(medal.id);
			}
		} else {
			
			for (medalData in response.result.data.medals) {
				
				medals.get(medalData.id).parse(medalData);
				idList.push(medalData.id);
			}
		}
		
		logVerbose('${response.result.data.medals.length} Medals received [${idList.join(", ")}]');
		
		onMedalsLoaded.dispatch();
	}
	
	// -------------------------------------------------------------------------------------------
	//                                       SCOREBOARDS
	// -------------------------------------------------------------------------------------------
	
	public function requestScoreBoards(onSuccess:Void->Void = null, onFail:Error->Void = null):Void {
		
		if (scoreBoards != null) {
			
			log("aborting scoreboard request, all scoreboards are loaded");
			
			if (onSuccess != null)
				onSuccess();
			
			return;
		}
		
		var call = calls.scoreBoard.getBoards()
			.addDataHandler(onBoardsReceived);
		
		if (onSuccess != null)
			call.addSuccessHandler(onSuccess);
		
		if (onFail != null)
			call.addErrorHandler(onFail);
		
		call.send();
	}
	
	function onBoardsReceived(response:Response<ScoreBoardResult>):Void {
		
		if (!response.success || !response.result.success)
			return;
		
		var idList:Array<Int> = new Array<Int>();
		
		if (scoreBoards == null) {
			
			scoreBoards = new IntMap<ScoreBoard>();
			
			for (boardData in response.result.data.scoreboards) {
				
				var board = new ScoreBoard(this, boardData);
				scoreBoards.set(board.id, board);
				idList.push(board.id);
			}
		}
		
		logVerbose('${response.result.data.scoreboards.length} ScoreBoards received [${idList.join(", ")}]');
		
		onScoreBoardsLoaded.dispatch();
	}
	
	// -------------------------------------------------------------------------------------------
	//                                       HELPERS
	// -------------------------------------------------------------------------------------------
	
	function timer(delay:Float, callback:Void->Void):Void {
		
		var timer = new Timer(Std.int(delay * 1000));
		timer.run = function func():Void {
			
			timer.stop();
			callback();
		}
	}
	
	static var urlParser:EReg = ~/^(?:http[s]?:\/\/)?([^:\/\s]+)(:[0-9]+)?((?:\/\w+)*\/)([\w\-\.]+[^#?\s]+)([^#\s]*)?(#[\w\-]+)?$/i;//TODO:trim
	/** Used to get the current web host of your game. */
	static public function getHost():String {
		
		var url = NGLite.getUrl();
		
		if (url == null || url == "")
			return "<AppView>";
		
		if (url.indexOf("file") == 0)
			return "<LocalHost>";
		
		if (urlParser.match(url))
			return urlParser.matched(1);
		
		return "<Unknown>";
	}
}
#end