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

	var songText:FlxText;

	public var targetPos:FlxPoint = new FlxPoint();
	public var doLerp:Bool = false;

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

	override function update(elapsed:Float)
	{
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
		trace(value);

		// cute one liners, lol!
		songText.alpha = value ? 1 : 0.6;
		capsule.offset.x = value ? 0 : -5;
		capsule.animation.play(value ? "selected" : "unselected");
		return value;
	}
}
