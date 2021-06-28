package ui;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;

import ui.FlxVirtualPad;
import ui.Hitbox;

import Config;

class Mobilecontrols extends FlxSpriteGroup
{
	public var mode:ControlsGroup = HITBOX;

	public var _hitbox:Hitbox;
	public var _virtualPad:FlxVirtualPad;

	//var config:Config;

	public function new() 
	{
		super();
		
		//config = new Config();

		// load control mode num from Config.hx
		mode = getModeFromNumber(FlxG.save.data.controlmode);
		trace(FlxG.save.data.controlmode);

		switch (mode)
		{
			case VIRTUALPAD_RIGHT:
				initVirtualPad(0);
			case VIRTUALPAD_LEFT:
				initVirtualPad(1);
			case VIRTUALPAD_CUSTOM:
				initVirtualPad(2);
			case HITBOX:
				_hitbox = new Hitbox();
				add(_hitbox);
			case KEYBOARD:
		}
	}
	var tempCount:Int = 0;
	function initVirtualPad(vpadMode:Int) 
	{
		switch (vpadMode)
		{
			
			case 1:
				_virtualPad = new FlxVirtualPad(FULL, NONE);
			case 2:
				var 
				_virtualPad = new FlxVirtualPad(FULL, NONE);
				for(buttons in _virtualPad)
				{
					buttons.x = FlxG.save.data.buttons[tempCount].x;
					buttons.y = FlxG.save.data.buttons[tempCount].y;
					tempCount++;
				}
			default: // 0
				_virtualPad = new FlxVirtualPad(RIGHT_FULL, NONE);
		}
		
		_virtualPad.alpha = 0.75;
		add(_virtualPad);
	}


	public static function getModeFromNumber(modeNum:Int):ControlsGroup {
		return switch (modeNum)
		{
			case 0: VIRTUALPAD_RIGHT;
			case 1: VIRTUALPAD_LEFT;
			case 2: KEYBOARD;
			case 3: VIRTUALPAD_CUSTOM;
			case 4:	HITBOX;

			default: VIRTUALPAD_RIGHT;

		}
	}
}

enum ControlsGroup {
	VIRTUALPAD_RIGHT;
	VIRTUALPAD_LEFT;
	KEYBOARD;
	VIRTUALPAD_CUSTOM;
	HITBOX;
}