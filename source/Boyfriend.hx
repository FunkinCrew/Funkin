package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class Boyfriend extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;

	public var debugMode:Bool = false;

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
		playAnim('idle');

		addOffset('idle');
		addOffset("singUP", -28, 27);
		addOffset("singRIGHT", -38, -7);
		addOffset("singLEFT", 12, -6);
		addOffset("singDOWN", -14, -50);
		addOffset("hey", 1, 6);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(animation.curAnim.name);
		if (animOffsets.exists(animation.curAnim.name))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
}
