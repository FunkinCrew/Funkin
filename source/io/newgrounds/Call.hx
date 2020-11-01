package io.newgrounds;

import io.newgrounds.utils.Dispatcher;
import io.newgrounds.utils.AsyncHttp;
import io.newgrounds.objects.Error;
import io.newgrounds.objects.events.Result;
import io.newgrounds.objects.events.Result.ResultBase;
import io.newgrounds.objects.events.Response;

import haxe.ds.StringMap;
import haxe.Json;

/** A generic way to handle calls agnostic to their type */
interface ICallable {
	
	public var component(default, null):String;
	
	public function send():Void;
	public function queue():Void;
	public function destroy():Void;
}

class Call<T:ResultBase>
	implements ICallable {
	
	public var component(default, null):String;
	
	var _core:NGLite;
	var _properties:StringMap<Dynamic>;
	var _parameters:StringMap<Dynamic>;
	var _requireSession:Bool;
	var _isSecure:Bool;
	
	// --- BASICALLY SIGNALS
	var _dataHandlers:TypedDispatcher<Response<T>>;
	var _successHandlers:Dispatcher;
	var _httpErrorHandlers:TypedDispatcher<Error>;
	var _statusHandlers:TypedDispatcher<Int>;
	
	public function new (core:NGLite, component:String, requireSession:Bool = false, isSecure:Bool = false) {
		
		_core = core;
		this.component = component;
		_requireSession = requireSession;
		_isSecure = isSecure && core.encryptionHandler != null;
	}
	
	/** adds a property to the input's object. **/
	public function addProperty(name:String, value:Dynamic):Call<T> {
		
		if (_properties == null)
			_properties = new StringMap<Dynamic>();
		
		_properties.set(name, value);
		
		return this;
	}
	
	/** adds a parameter to the call's component object. **/
	public function addComponentParameter(name:String, value:Dynamic, defaultValue:Dynamic = null):Call<T> {
		
		if (value == defaultValue)//TODO?: allow sending null value
			return this;
		
		if (_parameters == null)
			_parameters = new StringMap<Dynamic>();
		
		_parameters.set(name, value);
		
		return this;
	}
	
	/** Handy callback setter for chained call modifiers. Called when ng.io replies successfully */
	public function addDataHandler(handler:Response<T>->Void):Call<T> {
		
		if (_dataHandlers == null)
			_dataHandlers = new TypedDispatcher<Response<T>>();
		
		_dataHandlers.add(handler);
		return this;
	}
	
	/** Handy callback setter for chained call modifiers. Called when ng.io replies successfully */
	public function addSuccessHandler(handler:Void->Void):Call<T> {
		
		if (_successHandlers == null)
			_successHandlers = new Dispatcher();
		
		_successHandlers.add(handler);
		return this;
	}
	
	/** Handy callback setter for chained call modifiers. Called when ng.io does not reply for any reason */
	public function addErrorHandler(handler:Error->Void):Call<T> {
		
		if (_httpErrorHandlers == null)
			_httpErrorHandlers = new TypedDispatcher<Error>();
		
		_httpErrorHandlers.add(handler);
		return this;
	}
	
	/** Handy callback setter for chained call modifiers. No idea when this is called; */
	public function addStatusHandler(handler:Int->Void):Call<T> {//TODO:learn what this is for
		
		if (_statusHandlers == null)
			_statusHandlers = new TypedDispatcher<Int>();
		
		_statusHandlers.add(handler);
		return this;
	}

	/** 
	 * Sends the call to the server, do not modify this object after calling this
	 * @param secure    If encryption is enabled, it will encrypt the call.
	**/
	public function send():Void {
		
		var data:Dynamic = {};
		data.app_id = _core.appId;
		data.call = {};
		data.call.component  = component;
		
		if (_core.debug)
			addProperty("debug", true);
		
		if (_properties == null || !_properties.exists("session_id")) {
			// --- HAS NO SESSION ID
			
			if (_core.sessionId != null) {
				// --- AUTO ADD SESSION ID
				
				addProperty("session_id", _core.sessionId);
				
			} else if (_requireSession){
				
				_core.logError(new Error('cannot send "$component" call without a sessionId'));
				return;
			}
		}
		
		if (_properties != null) {
			
			for (field in _properties.keys())
				Reflect.setField(data, field, _properties.get(field));
		}
		
		if (_parameters != null) {
			
			data.call.parameters = {};
			
			for (field in _parameters.keys())
				Reflect.setField(data.call.parameters, field, _parameters.get(field));
		}
		
		_core.logVerbose('Post  - ${Json.stringify(data)}');
		
		if (_isSecure) {
			
			var secureData = _core.encryptionHandler(Json.stringify(data.call));
			data.call = {};
			data.call.secure = secureData;
			
			_core.logVerbose('    secure - $secureData');
		}
		
		_core.markCallPending(this);
		
		AsyncHttp.send(_core, Json.stringify(data), onData, onHttpError, onStatus);
	}
	
	/** Adds the call to the queue */
	public function queue():Void {
		
		_core.queueCall(this);
	}
	
	function onData(reply:String):Void {
		
		_core.logVerbose('Reply - $reply');
		
		if (_dataHandlers == null && _successHandlers == null)
			return;
		
		var response = new Response<T>(_core, reply);
		
		if (_dataHandlers != null)
			_dataHandlers.dispatch(response);
		
		if (response.success && response.result.success && _successHandlers != null)
			_successHandlers.dispatch();
		
		destroy();
	}
	
	function onHttpError(message:String):Void {
		
		_core.logError(message);
		
		if (_httpErrorHandlers == null)
			return;
		
		var error = new Error(message);
		_httpErrorHandlers.dispatch(error);
	}
	
	function onStatus(status:Int):Void {
		
		if (_statusHandlers == null)
			return;
		
		_statusHandlers.dispatch(status);
	}
	
	public function destroy():Void {
		
		_core = null;
		
		_properties = null;
		_parameters = null;
		
		_dataHandlers = null;
		_successHandlers = null;
		_httpErrorHandlers = null;
		_statusHandlers = null;
	}
}