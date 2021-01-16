package;

import flixel.FlxGame;
#if !final
import openfl.display.FPS;
#end
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, TitleState));

		#if !final
		addChild(new FPS(10, 3, 0xFFFFFF));
		#end
	}
}
