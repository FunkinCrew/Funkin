package io.newgrounds;

import haxe.crypto.Base64;
import haxe.io.Bytes;
import haxe.PosInfos;

import io.newgrounds.Call.ICallable;
import io.newgrounds.components.ComponentList;
import io.newgrounds.crypto.EncryptionFormat;
import io.newgrounds.crypto.Cipher;
import io.newgrounds.crypto.Rc4;
import io.newgrounds.objects.Error;
import io.newgrounds.objects.events.Response;
import io.newgrounds.objects.events.Result.ResultBase;
import io.newgrounds.objects.events.Result.SessionResult;
import io.newgrounds.utils.Dispatcher;

#if !(html5 || flash || desktop || neko)
	#error "Target not supported, use: Flash, JS/HTML5, cpp or maybe neko";
#end

/**
 * The barebones NG.io API. Allows API calls with code completion
 * and retrieves server data via strongly typed Objects
 * 
 * Contains many things ripped from MSGhero's repo
 *   - https://github.com/MSGhero/NG.hx
 * 
 * @author GeoKureli
 */
class NGLite {
	
	static public var core(default, null):NGLite;
	static public var onCoreReady(default, null):Dispatcher = new Dispatcher();
	
	/** Enables verbose logging */
	public var verbose:Bool;
	public var debug:Bool;
	/** The unique ID of your app as found in the 'API Tools' tab of your Newgrounds.com project. */
	public var appId(default, null):String;
	/** The name of the host the game is being played on */
	public var host:String;
	
	@:isVar
	public var sessionId(default, set):String;
	function set_sessionId(value:String):String {
		
		return this.sessionId = value == "" ? null : value;
	}
	
	/** Components used to call the NG server directly */
	public var calls(default, null):ComponentList;
	
	/**
	 * Converts an object to an encrypted string that can be decrypted by the server.
	 * Set your preffered encrypter here,
	 * or just call setDefaultEcryptionHandler with your app's encryption settings
	**/
	public var encryptionHandler:String->String;
	
	/** 
	 * Iniitializes the API, call before utilizing any other component
	 * @param appId  	The unique ID of your app as found in the 'API Tools' tab of your Newgrounds.com project.
	 * @param sessionId A unique session id used to identify the active user.
	**/
	public function new(appId = "test", sessionId:String = null, ?onSessionFail:Error->Void) {
		
		this.appId = appId;
		this.sessionId = sessionId;
		
		calls = new ComponentList(this);
		
		if (this.sessionId != null) {
			
			calls.app.checkSession()
				.addDataHandler(checkInitialSession.bind(onSessionFail))
				.addErrorHandler(initialSessionFail.bind(onSessionFail))
				.send();
		}
	}
	
	function checkInitialSession(onFail:Error->Void, response:Response<SessionResult>):Void {
		
		if (!response.success || !response.result.success || response.result.data.session.expired) {
			
			initialSessionFail(onFail, response.success ? response.result.error : response.error);
		}
	}
	
	function initialSessionFail(onFail:Error->Void, error:Error):Void {
		
		sessionId = null;
		
		if (onFail != null)
			onFail(error);
	}
	
	/**
	 * Creates NG.core, the heart and soul of the API. This is not the only way to create an instance,
	 * nor is NG a forced singleton, but it's the only way to set the static NG.core.
	**/
	static public function create(appId = "test", sessionId:String = null, ?onSessionFail:Error->Void):Void {
		
		core = new NGLite(appId, sessionId, onSessionFail);
		
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
		
		var session = getSessionId();
		if (session == null)
			session = backupSession;
		
		create(appId, session, onSessionFail);
	}
	
	inline static public function getUrl():String {
		
		#if html5
			return js.Browser.document.location.href;
		#elseif flash
			return flash.Lib.current.stage.loaderInfo != null
				? flash.Lib.current.stage.loaderInfo.url
				: null;
		#else
			return null;
		#end
	}
	
	static public function getSessionId():String {
		
		#if html5
			
			var url = getUrl();
			
			// Check for URL params
			var index = url.indexOf("?");
			if (index != -1) {
				
				// Check for session ID in params
				for (param in url.substr(index + 1).split("&")) {
					
					index = param.indexOf("=");
					if (index != -1 && param.substr(0, index) == "ngio_session_id")
						return param.substr(index + 1);
				}
			}
			
		#elseif flash
			
			if (flash.Lib.current.stage.loaderInfo != null
			&&  Reflect.hasField(flash.Lib.current.stage.loaderInfo.parameters, "ngio_session_id"))
				return Reflect.field(flash.Lib.current.stage.loaderInfo.parameters, "ngio_session_id");
			
		#end
		
		return null;
		
		// --- EXAMPLE LOADER PARAMS
		//{ "1517703669"                : ""
		//, "ng_username"               : "GeoKureli"
		//, "NewgroundsAPI_SessionID"   : "F1LusbG6P8Qf91w7zeUE37c1752563f366688ac6153996d12eeb111a2f60w2xn"
		//, "NewgroundsAPI_PublisherID" : 1
		//, "NewgroundsAPI_UserID"      : 488329
		//, "NewgroundsAPI_SandboxID"   : "5a76520e4ae1e"
		//, "ngio_session_id"           : "0c6c4e02567a5116734ba1a0cd841dac28a42e79302290"
		//, "NewgroundsAPI_UserName"    : "GeoKureli"
		//}
	}
	
	// -------------------------------------------------------------------------------------------
	//                                   CALLS
	// -------------------------------------------------------------------------------------------
	
	var _queuedCalls:Array<ICallable> = new Array<ICallable>();
	var _pendingCalls:Array<ICallable> = new Array<ICallable>();
	
	@:allow(io.newgrounds.Call)
	@:generic
	function queueCall<T:ResultBase>(call:Call<T>):Void {
		
		logVerbose('queued - ${call.component}');
		
		_queuedCalls.push(call);
		checkQueue();
	}
	
	@:allow(io.newgrounds.Call)
	@:generic
	function markCallPending<T:ResultBase>(call:Call<T>):Void {
		
		_pendingCalls.push(call);
		
		call.addDataHandler(function (_):Void { onCallComplete(call); });
		call.addErrorHandler(function (_):Void { onCallComplete(call); });
	}
	
	function onCallComplete(call:ICallable):Void {
		
		_pendingCalls.remove(call);
		checkQueue();
	}
	
	function checkQueue():Void {
		
		if (_pendingCalls.length == 0 && _queuedCalls.length > 0)
			_queuedCalls.shift().send();
	}
	
	// -------------------------------------------------------------------------------------------
	//                                   LOGGING / ERRORS
	// -------------------------------------------------------------------------------------------
	
	/** Called internally, set this to your preferred logging method */
	dynamic public function log(any:Dynamic, ?pos:PosInfos):Void {//TODO: limit access via @:allow
		
		haxe.Log.trace('[Newgrounds API] :: ${any}', pos);
	}
	
	/** used internally, logs if verbose is true */
	inline public function logVerbose(any:Dynamic, ?pos:PosInfos):Void {//TODO: limit access via @:allow
		
		if (verbose)
			log(any, pos);
	}
	
	/** Used internally. Logs by default, set this to your preferred error handling method */
	dynamic public function logError(any:Dynamic, ?pos:PosInfos):Void {//TODO: limit access via @:allow
		
		log('Error: $any', pos);
	}
	
	/** used internally, calls log error if the condition is false. EX: if (assert(data != null, "null data")) */
	inline public function assert(condition:Bool, msg:Dynamic, ?pos:PosInfos):Bool {//TODO: limit access via @:allow
		if (!condition)
			logError(msg, pos);
		
		return condition;
	}
	
	// -------------------------------------------------------------------------------------------
	//                                       ENCRYPTION
    // -------------------------------------------------------------------------------------------
	
	/** Sets */
	public function initEncryption
	( key   :String
	, cipher:Cipher = Cipher.RC4
	, format:EncryptionFormat = EncryptionFormat.BASE_64
	):Void {
		
		if (cipher == Cipher.NONE)
			encryptionHandler = null;
		else if (cipher == Cipher.RC4)
			encryptionHandler = encryptRc4.bind(key, format);
		else
			throw "aes not yet implemented";
	}
	
	function encryptRc4(key:String, format:EncryptionFormat, data:String):String {
		
		if (format == EncryptionFormat.HEX)
			throw "hex format not yet implemented";
		
		var keyBytes:Bytes;
		if (format == EncryptionFormat.BASE_64)
			keyBytes = Base64.decode(key);
		else
			keyBytes = null;//TODO
		
		var dataBytes = new Rc4(keyBytes).crypt(Bytes.ofString(data));
		
		if (format == EncryptionFormat.BASE_64)
			return Base64.encode(dataBytes);
		
		return null;
	}
}