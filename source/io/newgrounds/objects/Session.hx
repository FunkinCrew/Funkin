package io.newgrounds.objects;

class Session extends Object {
	
	/** If true, the session_id is expired. Use App.startSession to get a new one.*/
	public var expired(default, null):Bool;
	
	/** A unique session identifier */
	public var id(default, null):String;
	
	/** If the session has no associated user but is not expired, this property will provide a URL that can be used to sign the user in. */
	public var passportUrl(default, null):String;
	
	/** If true, the user would like you to remember their session id. */
	public var remember(default, null):Bool;
	
	/** If the user has not signed in, or granted access to your app, this will be null */
	public var user(default, null):User;
	
	//TODO:desciption
	public var status(get, never):SessionStatus;
	
	public function new(core:NGLite, data:Dynamic = null) { super(core, data); }
	
	override public function parse(data:Dynamic):Void {
		
		id = data.id;
		expired = data.expired;
		passportUrl = data.passport_url;
		remember = data.remember;
		
		// --- KEEP THE SAME INSTANCE
		if (user == null)
			user = data.user;
		// TODO?: update original user instance with new data. (probly not) 
		
		super.parse(data);
	}
	
	public function get_status():SessionStatus {
		
		if (expired || id == null || id == "")
			return SessionStatus.SESSION_EXPIRED;
		
		if (user != null && user.name != null && user.name != "")
			return SessionStatus.USER_LOADED;
		
		return SessionStatus.REQUEST_LOGIN;
	}
	
	public function expire():Void {
		
		expired = true;
		id = null;
		user = null;
	}
}

@:enum
abstract SessionStatus(String) {
	
	var SESSION_EXPIRED = "session-expired";
	var REQUEST_LOGIN   = "request-login";
	var USER_LOADED     = "user-loaded";
}