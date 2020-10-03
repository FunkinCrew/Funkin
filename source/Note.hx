package;

import flixel.FlxSprite;
import flixel.util.FlxColor;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;

	public function new(strumTime:Float, noteData:Int)
	{
		super();

		this.strumTime = strumTime;
		this.noteData = noteData;

		makeGraphic(50, 50);

		switch (Math.abs(noteData))
		{
			case 1:
				color = FlxColor.GREEN;
			case 2:
				color = FlxColor.RED;
			case 3:
				color = FlxColor.BLUE;
			case 4:
				color = FlxColor.PURPLE;
		}

		if (noteData < 0)
			alpha = 0.6;
	}
}
