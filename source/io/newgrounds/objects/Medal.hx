package io.newgrounds.objects;

import io.newgrounds.objects.events.Response;
import io.newgrounds.objects.events.Result.MedalUnlockResult;
import io.newgrounds.utils.Dispatcher;
import io.newgrounds.NGLite;

class Medal extends Object {
	
	inline static public var EASY       :Int = 1;
	inline static public var MODERATE   :Int = 2;
	inline static public var CHALLENGING:Int = 3;
	inline static public var DIFFICULT  :Int = 4;
	inline static public var BRUTAL     :Int = 5;
	
	static var difficultyNames:Array<String> = 
		[ "Easy"
		, "Moderate"
		, "Challenging"
		, "Difficult"
		, "Brutal"
		];
	// --- FROM SERVER
	public var id         (default, null):Int;
	public var name       (default, null):String;
	public var description(default, null):String;
	public var icon       (default, null):String;
	public var value      (default, null):Int;
	public var difficulty (default, null):Int;
	public var secret     (default, null):Bool;
	public var unlocked   (default, null):Bool;
	// --- HELPERS
	public var difficultyName(get, never):String;
	
	public var onUnlock:Dispatcher;
	
	public function new(core:NGLite, data:Dynamic = null):Void {
		
		onUnlock = new Dispatcher();
		
		super(core, data);
	}

	@:allow(io.newgrounds.NG)
	override function parse(data:Dynamic):Void {
		
		var wasLocked = !unlocked;
		
		id          = data.id;
		name        = data.name;
		description = data.description;
		icon        = data.icon;
		value       = data.value;
		difficulty  = data.difficulty;
		secret      = data.secret == 1;
		unlocked    = data.unlocked;
		
		super.parse(data);
		
		if (wasLocked && unlocked)
			onUnlock.dispatch();
		
	}
	
	public function sendUnlock():Void {
		
		if (_core.sessionId == null) {
			// --- Unlock regardless, show medal popup to encourage NG signup
			unlocked = true;
			onUnlock.dispatch();
			//TODO: save unlock in local save
		}
		
		_core.calls.medal.unlock(id)
			.addDataHandler(onUnlockResponse)
			.send();
	}
	
	function onUnlockResponse(response:Response<MedalUnlockResult>):Void {
		
		if (response.success && response.result.success) {
			
			parse(response.result.data.medal);
			
			// --- Unlock response doesn't include unlock=true, so parse won't change it.
			if (!unlocked) {
				
				unlocked = true;
				onUnlock.dispatch();
			}
		}
	}
	
	/** Locks the medal on the client and sends an unlock request, Server responds the same either way. */ 
	public function sendDebugUnlock():Void {
		
		if (NG.core.sessionId == null) {
			
			onUnlock.dispatch();
			
		} else {
			
			unlocked = false;
			
			sendUnlock();
		}
	}
	
	public function get_difficultyName():String {
		
		return difficultyNames[difficulty - 1];
	}
	
	public function toString():String {
		
		return 'Medal: $id@$name (${unlocked ? "unlocked" : "locked"}, $value pts, $difficultyName).';
	}
}