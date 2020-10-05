package;

import flixel.graphics.frames.FlxAtlasFrames;

class Dad extends Character
{
	public function new(x:Float, y:Float)
	{
		super(x, y);
		var dadTex = FlxAtlasFrames.fromSparrow(AssetPaths.DADDY_DEAREST__png, AssetPaths.DADDY_DEAREST__xml);
		frames = dadTex;
		animation.addByPrefix('idle', 'Dad idle dance', 24);
		animation.addByPrefix('singUP', 'Dad Sing Note UP', 24);
		animation.addByPrefix('singRIGHT', 'Dad Sing Note RIGHT', 24);
		animation.addByPrefix('singDOWN', 'Dad Sing Note DOWN', 24);
		animation.addByPrefix('singLEFT', 'Dad Sing Note LEFT', 24);
		playAnim('idle');

		addOffset('idle');
		addOffset("singUP", -6, 50);
		addOffset("singRIGHT", 0, 27);
		addOffset("singLEFT", -10, 10);
		addOffset("singDOWN", 0, -30);
	}
}
