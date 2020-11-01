package io.newgrounds.swf;

import io.newgrounds.swf.common.BaseAsset;
import io.newgrounds.objects.Medal;

import openfl.text.TextFieldAutoSize;
import openfl.text.TextField;
import openfl.display.DisplayObject;
import openfl.display.Loader;
import openfl.display.MovieClip;
import openfl.net.URLRequest;
import openfl.events.Event;

class MedalPopup extends BaseAsset {
	
	static inline var FRAME_HIDDEN:String = "hidden";
	static inline var FRAME_MEDAL_UNLOCKED:String = "medalUnlocked";
	static inline var FRAME_INTRO_COMPLETE:String = "introComplete";
	static inline var FRAME_UNLOCK_COMPLETE:String = "unlockComplete";
	static inline var MIN_TEXT_SIZE:Int = 12;
	
	public var medalIcon(default, null):MovieClip;
	public var medalName(default, null):MovieClip;
	public var medalPoints(default, null):MovieClip;
	
	public var alwaysOnTop:Bool;
	#if !ng_lite
	public var requiresSession:Bool;
	#end
	
	var _animQueue = new Array<Void->Void>();
	var _scrollSpeed:Float;
	
	public function new() {
		super();
		
		mouseEnabled = false;
		mouseChildren = false;
		
		hide();
		addFrameScript(totalFrames - 1, onUnlockAnimComplete);
	}
	
	function hide():Void {
		
		visible = false;
		gotoAndStop(FRAME_HIDDEN);
	}
	
	#if !ng_lite
	override function onReady():Void {
		super.onReady();
		
		if (NG.core.medals != null)
			onMedalsLoaded();
		else
			NG.core.onLogin.addOnce(NG.core.requestMedals.bind(onMedalsLoaded));
	}
	
	function onMedalsLoaded():Void {
		
		for (medal in NG.core.medals)
			medal.onUnlock.add(onMedalOnlock.bind(medal));
	}
	
	function onMedalOnlock(medal:Medal):Void {
		
		if (requiresSession && !NG.core.loggedIn)
			return;
		
		var loader = new Loader();
		loader.load(new URLRequest(medal.icon));
		
		playAnim(loader, medal.name, medal.value);
	}
	
	#end
	
	public function playAnim(icon:DisplayObject, name:String, value:Int):Void {
		
		if (currentLabel == FRAME_HIDDEN)
			playNextAnim(icon, name, value);
		else
			_animQueue.push(playNextAnim.bind(icon, name, value));
	}
	
	function playNextAnim(icon:DisplayObject, name:String, value:Int):Void {
		
		visible = true;
		gotoAndPlay(FRAME_MEDAL_UNLOCKED);
		
		if (alwaysOnTop && parent != null) {
			
			parent.setChildIndex(this, parent.numChildren - 1);
		}
		
		while(medalIcon.numChildren > 0)
			medalIcon.removeChildAt(0);
		
		cast(medalPoints.getChildByName("field"), TextField).text = Std.string(value);
		
		var field:TextField = cast medalName.getChildByName("field");
		field.autoSize = TextFieldAutoSize.LEFT;
		field.x = 0;
		field.text = "";
		var oldWidth = medalName.width;
		field.text = name;
		
		_scrollSpeed = 0;
		if (field.width > oldWidth + 4) {
			
			field.x = oldWidth + 4;
			initScroll(field);
		}
		
		medalIcon.addChild(icon);
	}
	
	function initScroll(field:TextField):Void {
		//TODO: Find out why scrollrect didn't work
		
		var animDuration = 0;
		
		for (frame in currentLabels){
			
			if (frame.name == FRAME_INTRO_COMPLETE )
				animDuration -= frame.frame;
			else if (frame.name == FRAME_UNLOCK_COMPLETE)
				animDuration += frame.frame;
		}
		
		_scrollSpeed = (field.width + field.x + 4) / animDuration;
		field.addEventListener(Event.ENTER_FRAME, updateScroll);
	}
	
	function updateScroll(e:Event):Void{
		
		if (currentLabel == FRAME_INTRO_COMPLETE)
			cast (e.currentTarget, TextField).x -= _scrollSpeed;
	}
	
	function onUnlockAnimComplete():Void {
		
		cast (medalName.getChildByName("field"), TextField).removeEventListener(Event.ENTER_FRAME, updateScroll);
		
		if (_animQueue.length == 0)
			hide();
		else
			(_animQueue.shift())();
	}
}
