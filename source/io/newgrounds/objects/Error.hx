package io.newgrounds.objects;
class Error {
	
	public var code(default, null):Int;
	public var message(default, null):String;
	
	public function new (message:String, code:Int = 0) {
		
		this.message = message;
		this.code = code;
	}
	
	public function toString():String {
		
		if (code > 0)
			return '#$code - $message';
		
		return message;
	}
}
