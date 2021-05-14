package mobilecontrols;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;

import ui.FlxVirtualPad;
import ui.Hitbox;

import Config;//webSettings.setMediaPlaybackRequiresUserGesture(false);	 xml android:usesCleartextTraffic="true"

class Mobilecontrols extends FlxSpriteGroup
{
    public var hitboxisenabled:Bool = false;
	public var keyboardisenabled:Bool = false;

	public var downscroll_isenabled:Bool = false;

    var _pad:FlxVirtualPad;
	var _hitbox:Hitbox;


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

	var config:Config = new Config();

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
				_pad = new FlxVirtualPad(FULL, NONE);
				_pad.alpha = 0.75;
				this.add(_pad);
			case 2:
				keyboardisenabled = true;
			case 3: //custom
				_pad = new FlxVirtualPad(RIGHT_FULL, NONE);
				_pad.alpha = 0.75;
				this.add(_pad);
				_pad = config.loadcustom(_pad);
			case 4:
				_hitbox = new Hitbox();
				hitboxisenabled = true;
				add(_hitbox);
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
			UP = _hitbox.up.pressed;
			RIGHT = _hitbox.right.pressed;
			DOWN = _hitbox.down.pressed;
			LEFT = _hitbox.left.pressed;

			UP_P = _hitbox.up.justPressed;
			RIGHT_P = _hitbox.right.justPressed;
			DOWN_P = _hitbox.down.justPressed;
			LEFT_P = _hitbox.left.justPressed;

			UP_R = _hitbox.up.justReleased;
			RIGHT_R = _hitbox.right.justReleased;
			DOWN_R = _hitbox.down.justReleased;
			LEFT_R = _hitbox.left.justReleased;
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
}

