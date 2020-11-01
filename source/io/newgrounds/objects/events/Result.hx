package io.newgrounds.objects.events;

class Result<T:ResultBase> {
	
	public var echo(default, null):String;
	public var component(default, null):String;
	
	public var data(default, null):T;
	public var success(default, null):Bool;
	public var debug(default, null):Bool;
	public var error(default, null):Error;
	
	public function new(core:NGLite, data:Dynamic) {
		
		echo = data.echo;
		component = data.component;
		
		data = data.data;
		success = data.success;
		debug = data.debug;
		
		if(!data.success) {
			
			error = new Error(data.error.message, data.error.code);
			core.logError('$component fail: $error');
			
		} else
			this.data = data;
	}
}

typedef ResultBase = { };

typedef SessionResult = {
	> ResultBase,
	
	var session:Dynamic;
}

typedef GetHostResult = {
	> ResultBase,
	
	var host_approved:Bool;
}

typedef GetCurrentVersionResult = {
	> ResultBase,
	
	var current_version:String;
	var client_deprecated:Bool;
}

typedef LogEventResult = {
	> ResultBase,
	
	var event_name:String;
}

typedef GetDateTimeResult = {
	> ResultBase,
	
	var datetime:String;
}

typedef GetVersionResult = {
	> ResultBase,
	
	var version:String;
}

typedef PingResult = {
	> ResultBase,
	
	var pong:String;
}

typedef MedalListResult = {
	> ResultBase,
	
	var medals:Array<Dynamic>;
}

typedef MedalUnlockResult = {
	> ResultBase,
	
	var medal_score:String;
	var medal:Dynamic;
}

typedef ScoreBoardResult = {
	> ResultBase,
	
	var scoreboards:Array<Dynamic>;
}

typedef ScoreResult = {
	> ResultBase,
	
	var scores:Array<Score>;
	var scoreboard:Dynamic;
}

typedef PostScoreResult = {
	> ResultBase,
	
	var tag:String;
	var scoreboard:Dynamic;
	var score:Score;
}