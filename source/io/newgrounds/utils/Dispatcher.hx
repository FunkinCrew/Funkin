package io.newgrounds.utils;

/**
 * Basically shitty signals, but I didn't want to have external references.
**/
class Dispatcher {
	
	var _list:Array<Void->Void>;
	var _once:Array<Void->Void>;
	
	public function new() {
		
		_list = new Array<Void->Void>();
		_once = new Array<Void->Void>();
	}
	
	public function add(handler:Void->Void, once:Bool = false):Bool {
		
		if (_list.indexOf(handler) != -1) {
			
			// ---- REMOVE ONCE
			if (!once && _once.indexOf(handler) != -1)
				_once.remove(handler);
			
			return false;
		}
		
		_list.unshift(handler);
		if (once)
			_once.unshift(handler);
		
		return true;
	}
	
	inline public function addOnce(handler:Void->Void):Bool {
		
		return add(handler, true);
	}
	
	public function remove(handler:Void->Void):Bool {
		
		_once.remove(handler);
		return _list.remove(handler);
	}
	
	public function dispatch():Void {
		
		var i = _list.length - 1;
		while(i >= 0) {
			
			var handler = _list[i];
			
			if (_once.remove(handler))
				_list.remove(handler);
			
			handler();
			
			i--;
		}
	}
}

class TypedDispatcher<T> {
	
	var _list:Array<T->Void>;
	var _once:Array<T->Void>;
	
	public function new() {
		
		_list = new Array<T->Void>();
		_once = new Array<T->Void>();
	}
	
	public function add(handler:T->Void, once:Bool = false):Bool {
		
		if (_list.indexOf(handler) != -1) {
			
			// ---- REMOVE ONCE
			if (!once && _once.indexOf(handler) != -1)
				_once.remove(handler);
			
			return false;
		}
		
		_list.unshift(handler);
		if (once)
			_once.unshift(handler);
		
		return true;
	}
	
	inline public function addOnce(handler:T->Void):Bool {
		
		return add(handler, true);
	}
	
	public function remove(handler:T->Void):Bool {
		
		_once.remove(handler);
		return _list.remove(handler);
	}
	
	public function dispatch(arg:T):Void {
		
		var i = _list.length - 1;
		while(i >= 0) {
			
			var handler = _list[i];
			
			if (_once.remove(handler))
				_list.remove(handler);
			
			handler(arg);
			
			i--;
		}
	}
}