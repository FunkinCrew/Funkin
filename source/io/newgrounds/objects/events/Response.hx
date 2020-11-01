package io.newgrounds.objects.events;

import io.newgrounds.objects.events.Result.ResultBase;
import haxe.Json;
import io.newgrounds.objects.Error;

typedef DebugResponse = {
	
	var exec_time:Int;
	var input:Dynamic;
}

class Response<T:ResultBase> {
	
	public var success(default, null):Bool;
	public var error(default, null):Error;
	public var debug(default, null):DebugResponse;
	public var result(default, null):Result<T>;
	
	public function new (core:NGLite, reply:String) {
		
		var data:Dynamic;
		
		try {
			data = Json.parse(reply);
			
		} catch (e:Dynamic) {
			
			data = Json.parse('{"success":false,"error":{"message":"${Std.string(reply)}","code":0}}');
		}
		
		success = data.success;
		debug = data.debug;
		
		if (!success) {
			error = new Error(data.error.message, data.error.code);
			core.logError('Call unseccessful: $error');
			return;
		}
		
		result = new Result<T>(core, data.result);
	}
}
