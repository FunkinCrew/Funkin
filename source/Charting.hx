package;

import flixel.FlxG;
import flixel.FlxState;

class Charting extends FlxState
{
	override function create()
	{
		FlxG.sound.music.stop();

		super.create();
	}
}
