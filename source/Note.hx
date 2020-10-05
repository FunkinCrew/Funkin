package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;

	public var noteScore:Float = 1;

	public static var swagWidth:Float = 160 * 0.7;

	public function new(strumTime:Float, noteData:Int)
	{
		super();

		x += 50;
		this.strumTime = strumTime;

		this.noteData = noteData;

		var tex = FlxAtlasFrames.fromSparrow(AssetPaths.NOTE_assets__png, AssetPaths.NOTE_assets__xml);
		frames = tex;
		animation.addByPrefix('greenScroll', 'green0');
		animation.addByPrefix('redScroll', 'red0');
		animation.addByPrefix('blueScroll', 'blue0');
		animation.addByPrefix('purpleScroll', 'purple0');

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
		antialiasing = true;

		switch (Math.abs(noteData))
		{
			case 1:
				x += swagWidth * 2;
				animation.play('greenScroll');
			case 2:
				x += swagWidth * 3;
				animation.play('redScroll');
			case 3:
				x += swagWidth * 1;
				animation.play('blueScroll');
			case 4:
				x += swagWidth * 0;
				animation.play('purpleScroll');
		}

		if (noteData < 0)
		{
			noteScore * 0.2;
			alpha = 0.6;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
				&& strumTime < Conductor.songPosition + Conductor.safeZoneOffset)
			{
				canBeHit = true;
			}
			else
				canBeHit = false;

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset)
				tooLate = true;
		}
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition)
			{
				wasGoodHit = true;
			}
		}

		if (tooLate)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}
