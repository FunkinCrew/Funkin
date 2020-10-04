package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class Boyfriend extends FlxSprite
{
	private var animOffsets:Map<String, Array<Dynamic>>;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		animOffsets = new Map<String, Array<Dynamic>>();

		var tex = FlxAtlasFrames.fromSparrow(AssetPaths.BOYFRIEND__png, AssetPaths.BOYFRIEND__xml);
		frames = tex;
		animation.addByPrefix('idle', 'BF idle dance', 24, false);
		animation.addByPrefix('singUP', 'BF NOTE UP', 24, false);
		animation.addByPrefix('singLEFT', 'BF NOTE LEFT', 24, false);
		animation.addByPrefix('singRIGHT', 'BF NOTE RIGHT', 24, false);
		animation.addByPrefix('singDOWN', 'BF NOTE DOWN', 24, false);
		animation.addByPrefix('hey', 'BF HEY', 24, false);
		animation.play('idle');

		addOffset("singUP", -25, 35);
		addOffset("singRIGHT", -40, -8);
		addOffset("singLEFT", 0, 0);
		addOffset("singDOWN", 0, -45);
		addOffset("hey", 0, -0);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var daOffset = animOffsets.get(animation.curAnim.name);

		if (animOffsets.exists(animation.curAnim.name))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			centerOffsets();
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
}
