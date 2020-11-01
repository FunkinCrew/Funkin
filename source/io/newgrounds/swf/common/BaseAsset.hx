package io.newgrounds.swf.common;

import openfl.events.Event;
import openfl.display.MovieClip;

class BaseAsset extends MovieClip {
	
	var _coreReady:Bool = false;
	
	public function new() {
		super();
		
		setDefaults();
		
		if (stage != null)
			onAdded(null);
		else
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
	}
	
	function setDefaults():Void { }
	
	function onAdded(e:Event):Void {
		
		if (NG.core != null)
			onReady();
		else
			NG.onCoreReady.add(onReady);
	}
	
	function onReady():Void {
		
		_coreReady = true;
	}
}
