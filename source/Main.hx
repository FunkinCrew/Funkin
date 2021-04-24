package;

import flixel.FlxGame;
import openfl.display.FPS;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		#if !cpp
			throw("Hey! FNFM+ only compiles for cpp, not web or other sys.");
		#end
		super();
		addChild(new FlxGame(0, 0, TitleState, 1, 60, 120, true));

		#if !mobile
		addChild(new FPS(10, 3, 0xFFFFFF));
		#end
	}
}
