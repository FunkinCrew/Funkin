package;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxSave;
import flixel.math.FlxPoint;

import flixel.ui.FlxVirtualPad;
import ui.Hitbox;

class Mobilecontrols extends FlxSpriteGroup
{
    public var hitboxisenabled:Bool = false;
	public var keyboardisenabled:Bool = false;

    var _pad:FlxVirtualPad;
	var _hb:Hitbox;

    var _saveconrtol:FlxSave;

	var controlmode:Int = 0;

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

	// now controls here
    public function new()
    {
        super();
		_saveconrtol = new FlxSave();
    	_saveconrtol.bind("saveconrtol");

		// load control mode num from FlxSave
		if (_saveconrtol.data.buttonsmode == null){
			controlmode = 0;
		}else{
			controlmode = _saveconrtol.data.buttonsmode[0];
		}
		//controlmode
		switch controlmode{
			case 1: //left default
				_pad = new FlxVirtualPad(FULL, NONE);
				_pad.alpha = 0.75;
				this.add(_pad);
			case 2:
				keyboardisenabled = true;
			case 3: //custom
				_pad = new FlxVirtualPad(RIGHT_FULL, NONE);
				_pad.alpha = 0.75;
				this.add(_pad);
				loadcustom(_pad);
			case 4:
				_hb = new Hitbox();
				hitboxisenabled = true;
				add(_hb);
			default: //default (0)
				_pad = new FlxVirtualPad(RIGHT_FULL, NONE);
				_pad.alpha = 0.75;
				this.add(_pad);
		}
    }

	override public function update(elapsed:Float) {
		group.update(elapsed);

		if (moves)
			updateMotion(elapsed);
		
		if (keyboardisenabled){
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
		}

		if (hitboxisenabled){
			UP = _hb.up.pressed;
			RIGHT = _hb.right.pressed;
			DOWN = _hb.down.pressed;
			LEFT = _hb.left.pressed;

			UP_P = _hb.up.justPressed;
			RIGHT_P = _hb.right.justPressed;
			DOWN_P = _hb.down.justPressed;
			LEFT_P = _hb.left.justPressed;

			UP_R = _hb.up.justReleased;
			RIGHT_R = _hb.right.justReleased;
			DOWN_R = _hb.down.justReleased;
			LEFT_R = _hb.left.justReleased;
		}

		if (!keyboardisenabled && !hitboxisenabled){
			UP = _pad.buttonUp.pressed;
			RIGHT = _pad.buttonRight.pressed;
			DOWN = _pad.buttonDown.pressed;
			LEFT = _pad.buttonLeft.pressed;

			UP_P = _pad.buttonUp.justPressed;
			RIGHT_P = _pad.buttonRight.justPressed;
			DOWN_P = _pad.buttonDown.justPressed;
			LEFT_P = _pad.buttonLeft.justPressed;

			UP_R = _pad.buttonUp.justReleased;
			RIGHT_R = _pad.buttonRight.justReleased;
			DOWN_R = _pad.buttonDown.justReleased;
			LEFT_R = _pad.buttonLeft.justReleased;
		}
	}

	function loadcustom(?_pad:FlxVirtualPad):Void{
		//load pad
		if (_saveconrtol.data.buttons[0] != null)
		{
			var tempCount:Int = 0;

			for(buttons in _pad)
			{
				buttons.x = _saveconrtol.data.buttons[tempCount].x;
				buttons.y = _saveconrtol.data.buttons[tempCount].y;
				tempCount++;
			}
		}else { trace('ERROR: failed to load custom controls'); }	
	
	}
}

