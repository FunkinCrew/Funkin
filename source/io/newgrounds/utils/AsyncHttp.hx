package io.newgrounds.utils;

import io.newgrounds.NGLite;

import haxe.Http;
import haxe.Timer;

#if neko
import neko.vm.Thread;
#elseif java
import java.vm.Thread;
#elseif cpp
import cpp.vm.Thread;
#end

/**
 * Uses Threading to turn hxcpp's synchronous http requests into asynchronous processes
 * 
 * @author GeoKureli
 */
class AsyncHttp {
	
	inline static var PATH:String = "https://newgrounds.io/gateway_v3.php";
	
	static public function send
	( core:NGLite
	, data:String
	, onData:String->Void
	, onError:String->Void
	, onStatus:Int->Void
	) {
		
		core.logVerbose('sending: $data');
		
		#if (neko || java || cpp)
		sendAsync(core, data, onData, onError, onStatus);
		#else
		sendSync(core, data, onData, onError, onStatus);
		#end
	}
	
	static function sendSync
	( core:NGLite
	, data:String
	, onData:String->Void
	, onError:String->Void
	, onStatus:Int->Void
	):Void {
		
		var http = new Http(PATH);
		http.setParameter("input", data);
		http.onData   = onData;
		http.onError  = onError;
		http.onStatus = onStatus;
		// #if js http.async = async; #end
		http.request(true);
	}
	
	#if (neko || java || cpp)
	static var _deadPool:Array<AsyncHttp> = [];
	static var _livePool:Array<AsyncHttp> = [];
	static var _map:Map<Int, AsyncHttp> = new Map();
	static var _timer:Timer;
	
	static var _count:Int = 0;
	
	var _core:NGLite;
	var _key:Int;
	var _onData:String->Void;
	var _onError:String->Void;
	var _onStatus:Int->Void;
	var _worker:Thread;
	
	public function new (core:NGLite) {
		
		_core = core;
		_worker = Thread.create(sendThreaded);
		_key = _count++;
		_map[_key] = this;
		_core.logVerbose('async http created: $_key');
	}
	
	function start(data:String, onData:String->Void, onError:String->Void, onStatus:Int->Void) {
		
		_core.logVerbose('async http started: $_key');
		
		if (_livePool.length == 0)
			startTimer();
		
		_deadPool.remove(this);
		_livePool.push(this);
		
		_onData = onData;
		_onError = onError;
		_onStatus = onStatus;
		_worker.sendMessage({ source:Thread.current(), args:data, key:_key, core:_core });
	}
	
	function handleMessage(data:ReplyData):Void {
		
		_core.logVerbose('handling message: $_key');
		
		if (data.status != null) {
			
			_core.logVerbose('\t- status: ${data.status}');
			_onStatus(cast data.status);
			return;
		}
		
		var tempFunc:Void->Void;
		if (data.data != null) {
			
			_core.logVerbose('\t- data');
			tempFunc = _onData.bind(data.data);
			
		} else {
			
			_core.logVerbose('\t- error');
			tempFunc = _onError.bind(data.error);
		}
		
		cleanUp();
		// Delay the call until destroy so that we're more likely to use a single
		// thread on daisy-chained calls
		tempFunc();
	}
	
	inline function cleanUp():Void {
		
		_onData = null;
		_onError = null;
		
		_deadPool.push(this);
		_livePool.remove(this);
		
		if (_livePool.length == 0)
			stopTimer();
	}
	
	static function sendAsync
	( core:NGLite
	, data:String
	, onData:String->Void
	, onError:String->Void
	, onStatus:Int->Void
	):Void {
		
		var http:AsyncHttp;
		if (_deadPool.length == 0)
			http = new AsyncHttp(core);
		else
			http = _deadPool[0];
		
		http.start(data, onData, onError, onStatus);
	}
	
	static function startTimer():Void {
		
		if (_timer != null)
			return;
		
		_timer = new Timer(1000 / 60.0);
		_timer.run = update;
	}
	
	static function stopTimer():Void {
		
		_timer.stop();
		_timer = null;
	}
	
	static public function update():Void {
		
		var message:ReplyData = cast Thread.readMessage(false);
		if (message != null)
			_map[message.key].handleMessage(message);
	}
	
	static function sendThreaded():Void {
		
		while(true) {
			
			var data:LoaderData = cast Thread.readMessage(true);
			data.core.logVerbose('start message received: ${data.key}');
			
			sendSync
				( data.core
				, data.args
				, function(reply ) { data.source.sendMessage({ key:data.key, data  :reply  }); }
				, function(error ) { data.source.sendMessage({ key:data.key, error :error  }); }
				, function(status) { data.source.sendMessage({ key:data.key, status:status }); }
				);
		}
	}
	
	#end
}


#if (neko || java || cpp)
typedef LoaderData = { source:Thread, key:Int, args:String, core:NGLite };
typedef ReplyData = { key:Int, ?data:String, ?error:String, ?status:Null<Int> };
#end