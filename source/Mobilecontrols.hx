package;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;

import ui.FlxVirtualPad;
import ui.Hitbox;

import Config;

class Mobilecontrols extends FlxSpriteGroup
{
    public var hitboxisenabled:Bool = false;
	public var keyboardisenabled:Bool = false;

	public var downscroll_isenabled:Bool = false;

    var _pad:FlxVirtualPad;
	var _subPad:FlxVirtualPad;

	var _hb:Hitbox;


	public function leftJustPressed():Bool
	{
		switch (controlmode)
		{
			case 2:
				return _pad.buttonLeft.justPressed || _subPad.buttonLeft.justPressed;
			default:
				return _pad.buttonLeft.justPressed;
		}
	}

	public function downJustPressed():Bool
	{
		switch (controlmode)
		{
			case 2:
				return _pad.buttonDown.justPressed || _subPad.buttonDown.justPressed;
			default:
				return _pad.buttonDown.justPressed;
		}
	}

	public function upJustPressed():Bool
	{
		switch (controlmode)
		{
			case 2:
				return _pad.buttonUp.justPressed || _subPad.buttonUp.justPressed;
			default:
				return _pad.buttonUp.justPressed;
		}
	}

	public function rightJustPressed():Bool
	{
		switch (controlmode)
		{
			case 2:
				return _pad.buttonRight.justPressed || _subPad.buttonRight.justPressed;
			default:
				return _pad.buttonRight.justPressed;
		}
	}

	public function leftPressed():Bool
	{
		switch (controlmode)
		{
			case 2:
				return _pad.buttonLeft.pressed || _subPad.buttonLeft.pressed;
			default:
				return _pad.buttonLeft.pressed;
		}
	}

	public function downPressed():Bool
	{
		switch (controlmode)
		{
			case 2:
				return _pad.buttonDown.pressed || _subPad.buttonDown.pressed;
			default:
				return _pad.buttonDown.pressed;
		}
	}

	public function upPressed():Bool
	{
		switch (controlmode)
		{
			case 2:
				return _pad.buttonUp.pressed || _subPad.buttonUp.pressed;
			default:
				return _pad.buttonUp.pressed;
		}
	}

	public function rightPressed():Bool
	{
		switch (controlmode)
		{
			case 2:
				return _pad.buttonRight.pressed || _subPad.buttonRight.pressed;
			default:
				return _pad.buttonRight.pressed;
		}
	}
		


	public function leftReleased():Bool
		{
			switch (controlmode)
			{
				case 2:
					return _pad.buttonLeft.justReleased || _subPad.buttonLeft.justReleased;
				default:
					return _pad.buttonLeft.justReleased;
			}
		}
	
		public function downReleased():Bool
		{
			switch (controlmode)
			{
				case 2:
					return _pad.buttonDown.justReleased || _subPad.buttonDown.justReleased;
				default:
					return _pad.buttonDown.justReleased;
			}
		}
	
		public function upReleased():Bool
		{
			switch (controlmode)
			{
				case 2:
					return _pad.buttonUp.justReleased || _subPad.buttonUp.justReleased;
				default:
					return _pad.buttonUp.justReleased;
			}
		}
	
		public function rightReleased():Bool
		{
			switch (controlmode)
			{
				case 2:
					return _pad.buttonRight.justReleased || _subPad.buttonRight.justReleased;
				default:
					return _pad.buttonRight.justReleased;
			}
		}


	public var controlmode:Int = 0;

	private var controls(get, never):Controls;
	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	//keys
	public var UP:Bool;
	public var RIGHT:Bool;
	public var DOWN:Bool;
	public var LEFT:Bool;

	public var UP_P:Bool;
	public var RIGHT_P:Bool;
	public var DOWN_P:Bool;
	public var LEFT_P:Bool;

	public var UP_R:Bool;
	public var RIGHT_R:Bool;
	public var DOWN_R:Bool;
	public var LEFT_R:Bool;

	var config:Config = new Config();
	var mcontrols:Mobilecontrols; 

	// now controls here
    public function new()
    {
        super();

		downscroll_isenabled = config.getdownscroll();

		// load control mode num from Config.hx
		controlmode = config.getcontrolmode();


		//controlmode
		switch controlmode{
			case 1: //left default
				_pad = new FlxVirtualPad(LEFT_FULL, NONE);
				_pad.alpha = 0.855;
				this.add(_pad);

			case 2:
				// keyboardisenabled = true;
				_pad = new FlxVirtualPad(RIGHT_FULL, NONE);
				_pad.alpha = 0.855;
				this.add(_pad);
			
				_subPad = new FlxVirtualPad(LEFT_FULL, NONE);
				_subPad.alpha = 0.855;
				this.add(_subPad);

			case 3:
				_hb = new Hitbox();
				hitboxisenabled = true;
				add(_hb);

			// case 4: //split 
			// 	_pad = new FlxVirtualPad(SPLIT, NONE);
			// 	_pad.alpha = 0.855;
			// 	this.add(_pad);

			default: //default (0)
				_pad = new FlxVirtualPad(RIGHT_FULL, NONE);
				_pad.alpha = 0.855;
				this.add(_pad);
		}
    }

	override public function update(elapsed:Float) {
		group.update(elapsed);

		if (moves)
			updateMotion(elapsed);


		UP = controls.UP;
		RIGHT = controls.RIGHT;
		DOWN = controls.DOWN;
		LEFT = controls.LEFT;

		UP_P = controls.UP_P;
		RIGHT_P = controls.RIGHT_P;
		DOWN_P = controls.DOWN_P;
		LEFT_P = controls.LEFT_P;

		UP_R = controls.UP_R;
		RIGHT_R = controls.RIGHT_R;
		DOWN_R = controls.DOWN_R;
		LEFT_R = controls.LEFT_R;
	

		if (hitboxisenabled){

			UP = UP || _hb.up.pressed;
			RIGHT = RIGHT || _hb.right.pressed;
			DOWN = DOWN || _hb.down.pressed;
			LEFT = LEFT || _hb.left.pressed;

			UP_P = UP_P || _hb.up.justPressed;
			RIGHT_P = RIGHT_P || _hb.right.justPressed;
			DOWN_P = DOWN_P || _hb.down.justPressed;
			LEFT_P = LEFT_P || _hb.left.justPressed;

			UP_R = UP_R || _hb.up.justReleased;
			RIGHT_R = RIGHT_R || _hb.right.justReleased;
			DOWN_R = DOWN_R || _hb.down.justReleased;
			LEFT_R = LEFT_R  || _hb.left.justReleased;

		}

		if (!hitboxisenabled){

			UP = UP || upPressed();
			RIGHT = RIGHT || rightPressed();
			DOWN = DOWN || downPressed();
			LEFT = LEFT || leftPressed();

			UP_P = UP_P || upJustPressed();
			RIGHT_P = RIGHT_P || rightJustPressed();
			DOWN_P = DOWN_P || downJustPressed();
			LEFT_P = LEFT_P || leftJustPressed();

			UP_R = UP_R || upReleased();
			RIGHT_R = RIGHT_R || rightReleased();
			DOWN_R = DOWN_R || downReleased();
			LEFT_R = LEFT_R || leftReleased();

		}
	}
}

