package funkin.freeplayStuff;

import flixel.FlxSprite;
import flixel.util.FlxSignal;

class DJBoyfriend extends FlxSprite
{
	public var animHITsignal:FlxSignal;

	public function new(x:Float, y:Float)
	{
		super(x, y);

		animHITsignal = new FlxSignal();

		animOffsets = new Map<String, Array<Dynamic>>();

		frames = Paths.getSparrowAtlas('freeplay/bfFreeplay');
		animation.addByPrefix('intro', "boyfriend dj intro", 24, false);
		animation.addByPrefix('idle', "Boyfriend DJ0", 24);
		animation.addByPrefix('confirm', "Boyfriend DJ confirm", 24);

		addOffset('intro', 0, 0);
		addOffset('idle', -4, -426);

		playAnim('intro');
		animation.finishCallback = function(anim)
		{
			switch (anim)
			{
				case "intro":
					animHITsignal.dispatch();
					playAnim('idle'); // plays idle anim after playing intro
			}
		};
	}

	// playAnim stolen from Character.hx, cuz im lazy lol!
	public var animOffsets:Map<String, Array<Dynamic>>;

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
}
