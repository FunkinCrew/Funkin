package freeplayStuff;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;

class SongMenuItem extends FlxSpriteGroup
{
	var capsule:FlxSprite;

	public var selected(default, set):Bool = false;

	public var songTitle:String = "Test";

	public var songText:FlxText;

	public var targetPos:FlxPoint = new FlxPoint();
	public var doLerp:Bool = false;
	public var doJumpIn:Bool = false;

	public function new(x:Float, y:Float, song:String)
	{
		super(x, y);

		this.songTitle = song;

		capsule = new FlxSprite();
		capsule.frames = Paths.getSparrowAtlas('freeplay/freeplayCapsule');
		capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
		capsule.animation.addByPrefix('unselected', 'mp3 capsule w backing NOT SELECTED', 24);
		// capsule.animation
		add(capsule);

		songText = new FlxText(120, 40, 0, songTitle, 40);
		songText.font = "5by7";
		songText.color = 0xFF43C1EA;
		add(songText);

		selected = selected; // just to kickstart the set_selected
	}

	var frameTicker:Float = 0;
	var frameTypeBeat:Int = 0;

	var xFrames:Array<Float> = [1.7, 1.8, 0.85, 0.85, 0.97, 0.97, 1];
	var xPosLerpLol:Array<Float> = [0.9, 0.4, 0.16, 0.16, 0.22, 0.22, 0.245]; // NUMBERS ARE JANK CUZ THE SCALING OR WHATEVER

	override function update(elapsed:Float)
	{
		if (doJumpIn)
		{
			frameTicker += elapsed;

			if (frameTicker >= 1 / 24 && frameTypeBeat < xFrames.length)
			{
				frameTicker = 0;

				scale.x = xFrames[frameTypeBeat];
				scale.y = 1 / xFrames[frameTypeBeat];
				x = FlxG.width * xPosLerpLol[Std.int(Math.min(frameTypeBeat, xPosLerpLol.length - 1))];

				frameTypeBeat += 1;
			}
		}

		if (doLerp)
		{
			x = CoolUtil.coolLerp(x, targetPos.x, 0.3);
			y = CoolUtil.coolLerp(y, targetPos.y, 0.4);
		}

		if (FlxG.keys.justPressed.ALT)
			selected = false;
		if (FlxG.keys.justPressed.CONTROL)
			selected = true;

		super.update(elapsed);
	}

	function set_selected(value:Bool):Bool
	{
		// trace(value);

		// cute one liners, lol!
		songText.alpha = value ? 1 : 0.6;
		capsule.offset.x = value ? 0 : -5;
		capsule.animation.play(value ? "selected" : "unselected");
		return value;
	}
}
