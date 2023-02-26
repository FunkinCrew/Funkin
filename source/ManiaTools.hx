package;

import Controls;
import flixel.FlxG;

class ManiaTools
{
	private static var controls(get, never):Controls;

	private static function get_controls():Controls
		return PlayerSettings.player1.controls;

	public static function getHoldKeysToNumber(keyCount:Int = 4):Array<Bool>
	{
		if (keyCount == 1) return [FlxG.keys.pressed.SPACE];
		if (keyCount == 2) return [FlxG.keys.pressed.F, FlxG.keys.pressed.J];
		if (keyCount == 3) return [FlxG.keys.pressed.F, FlxG.keys.pressed.SPACE, FlxG.keys.pressed.J];
		if (keyCount == 4) return [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
		if (keyCount == 5) return [FlxG.keys.pressed.D, FlxG.keys.pressed.F, FlxG.keys.pressed.SPACE, FlxG.keys.pressed.J, FlxG.keys.pressed.K];
		if (keyCount == 6) return [FlxG.keys.pressed.S, FlxG.keys.pressed.D, FlxG.keys.pressed.F, FlxG.keys.pressed.J, FlxG.keys.pressed.K, FlxG.keys.pressed.L];

		return [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
	}

	public static function getPressedKeysToNumber(keyCount:Int = 4):Array<Bool>
	{
		if (keyCount == 1) return [FlxG.keys.justPressed.SPACE];
		if (keyCount == 2) return [FlxG.keys.justPressed.F, FlxG.keys.justPressed.J];
		if (keyCount == 3) return [FlxG.keys.justPressed.F, FlxG.keys.justPressed.SPACE, FlxG.keys.justPressed.J];
		if (keyCount == 4) return [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
		if (keyCount == 5) return [FlxG.keys.justPressed.D, FlxG.keys.justPressed.F, FlxG.keys.justPressed.SPACE, FlxG.keys.justPressed.J, FlxG.keys.justPressed.K];
		if (keyCount == 6) return [FlxG.keys.justPressed.S, FlxG.keys.justPressed.D, FlxG.keys.justPressed.F, FlxG.keys.justPressed.J, FlxG.keys.justPressed.K, FlxG.keys.justPressed.L];

		return [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
	}

	public static function getReleasedKeysToNumber(keyCount:Int = 4):Array<Bool>
	{
		if (keyCount == 1) return [FlxG.keys.justReleased.SPACE];
		if (keyCount == 2) return [FlxG.keys.justReleased.F, FlxG.keys.justReleased.J];
		if (keyCount == 3) return [FlxG.keys.justReleased.F, FlxG.keys.justReleased.SPACE, FlxG.keys.justReleased.J];
		if (keyCount == 4) return [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
		if (keyCount == 5) return [FlxG.keys.justReleased.D, FlxG.keys.justReleased.F, FlxG.keys.justReleased.SPACE, FlxG.keys.justReleased.J, FlxG.keys.justReleased.K];
		if (keyCount == 6) return [FlxG.keys.justReleased.S, FlxG.keys.justReleased.D, FlxG.keys.justReleased.F, FlxG.keys.justReleased.J, FlxG.keys.justReleased.K, FlxG.keys.justReleased.L];

		return [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
	}
}