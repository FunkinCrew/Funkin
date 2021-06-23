package ui;

import flixel.FlxG;
import flixel.group.FlxGroup;
import ui.FlxVirtualPad;
import Controls.KeyboardScheme;

class Controller
{
	static var controls:Controls;
    public static var _pad:FlxVirtualPad;


	public static function init(group:FlxGroup, ?DPad:FlxDPadMode, ?Action:FlxActionMode)
	{
        if(controls == null) //create controls one time only!
			controls = PlayerSettings.player1.controls;

        if(_pad != null)
        {
            //remove old pad
            _pad = null;

        }
		_pad = new FlxVirtualPad(DPad, Action);

		//disable mobile control first
		_pad.alpha = 0;



		//then enable if its mobile or debugging
		#if mobile 
    	_pad.alpha = 0.85;
		#end
		#if debug //i dunno could it be using || for multiple condition, cuz i'm stupis	
		_pad.alpha = 0.85;
		#end


		group.add(_pad);
    }

    public  static var ACCEPT(get, never):Bool;
	static inline function get_ACCEPT()
    return _pad.buttonA.justPressed || controls.ACCEPT;


	public static var BACK(get, never):Bool;
    static inline function get_BACK()
    {
		return _pad.buttonB.justPressed || controls.BACK;
    }

    //LEFT SIDE, pressed ARROW SHIT
	public static var DOWN_P(get, never):Bool;
    static inline function get_DOWN_P()
    {
        return _pad.buttonDown.justPressed || controls.DOWN_P;
    }

	public static var UP_P(get, never):Bool;
    static inline function get_UP_P()
	{
		return _pad.buttonUp.justPressed || controls.UP_P;
	}

	public static var LEFT_P(get, never):Bool;
    static inline function get_LEFT_P()
	{
		return _pad.buttonLeft.justPressed || controls.LEFT_P;
	}

	public static var RIGHT_P(get, never):Bool;
    static inline function get_RIGHT_P()
	{
		return _pad.buttonRight.justPressed || controls.RIGHT_P;
	}


	// LEFT SIDE, hold ARROW SHIT
	public static var DOWN(get, never):Bool;
    static inline function get_DOWN()
	{
		return _pad.buttonDown.pressed || controls.DOWN;
	}

	public static var UP(get, never):Bool;
    static inline function get_UP()
	{
		return _pad.buttonUp.pressed || controls.UP;
	}

	public static var LEFT(get, never):Bool;
    static inline function get_LEFT()
	{
		return _pad.buttonLeft.pressed || controls.LEFT;
	}

	public static var RIGHT(get, never):Bool;
    static inline function get_RIGHT()
	{
		return _pad.buttonRight.pressed || controls.RIGHT;
	}

	// LEFT SIDE, release ARROW SHIT
	public static var DOWN_R(get, never):Bool;
    static inline function get_DOWN_R()
	{
		return _pad.buttonDown.justReleased || controls.DOWN_R;
	}

	public static var UP_R(get, never):Bool;
    static inline function get_UP_R()
	{
		return _pad.buttonUp.justReleased || controls.UP_R;
	}

	public static var LEFT_R(get, never):Bool;
    static inline function get_LEFT_R()
	{
		return _pad.buttonLeft.justReleased || controls.LEFT_R;
	}

	public static var RIGHT_R(get, never):Bool;
    static inline function get_RIGHT_R()
	{
		return _pad.buttonRight.justReleased || controls.RIGHT_R;
	}


    //Function key press

    public static var SHIFT(get, never):Bool;
    static inline function get_SHIFT()
	{
		return FlxG.keys.pressed.SHIFT;
	}

        
}

