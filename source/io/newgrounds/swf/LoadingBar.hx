package io.newgrounds.swf;

import openfl.display.MovieClip;

class LoadingBar extends MovieClip {
	
	public var bar(default, null):MovieClip;
	
	public function new() { 
		super();
		
		setProgress(0.0);
	}
	
	/**
	 * 
	 * @param value  The ratio of bytes loaded to bytes total
	 */
	public function setProgress(value:Float):Void {
		
		bar.gotoAndStop(1 + Std.int(value * (bar.totalFrames - 1)));
	}
}
