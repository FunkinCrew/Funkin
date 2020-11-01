package io.newgrounds.objects;

import io.newgrounds.utils.Dispatcher;
import io.newgrounds.NGLite;

class Object {
	
	var _core:NGLite;
	
	public var onUpdate(default, null):Dispatcher;
	
	public function new(core:NGLite, data:Dynamic = null) {
		
		this._core = core; 
		
		onUpdate = new Dispatcher();
		
		if (data != null)
			parse(data);
	}
	
	@:allow(io.newgrounds.NGLite)
	function parse(data:Dynamic):Void {
		
		onUpdate.dispatch();
	}
	
	
	public function destroy():Void {
		
		_core = null;
	}
}