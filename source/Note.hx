package;

import flixel.FlxSprite;
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

	public function new(strumTime:Float, noteData:Int)
	{
		super();

		x += 100;
		this.strumTime = strumTime;

		this.noteData = noteData;

		makeGraphic(50, 50);
		var swagWidth:Float = 55;

		switch (Math.abs(noteData))
		{
			case 1:
				x += swagWidth * 2;
				color = FlxColor.GREEN;
			case 2:
				x += swagWidth * 3;
				color = FlxColor.RED;
			case 3:
				x += swagWidth * 1;
				color = FlxColor.BLUE;
			case 4:
				x += swagWidth * 0;
				color = FlxColor.PURPLE;
		}

		if (noteData < 0)
			alpha = 0.6;
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
			canBeHit = false;

		if (tooLate && alpha > 0.3)
			alpha *= 0.3;
	}
}
