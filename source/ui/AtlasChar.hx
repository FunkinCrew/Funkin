package ui;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class AtlasChar extends FlxSprite
{
	var char:String;

	override public function new(x:Float = 0, y:Float = 0, atlas:FlxAtlasFrames, char:String)
	{
		super(x, y);
		set_frames(atlas);
		set_char(char);
		set_antialiasing(true);
	}

	public function set_char(char:String)
	{
		if (this.char != char)
		{
			var prefix = getAnimPrefix(char);
			animation.addByPrefix('anim', prefix, 24);
			animation.play('anim');
			updateHitbox();
		}
		return this.char = char;
	}

	public function getAnimPrefix(char:String)
	{
		switch (char)
		{
			case "!":
				return "-exclamation point-";
			case "'":
				return "-apostraphie-";
			case "*":
				return "-multiply x-";
			case ",":
				return "-comma-";
			case "-":
				return "-dash-";
			case ".":
				return "-period-";
			case "/":
				return "-forward slash-";
			case "?":
				return "-question mark-";
			case "\\":
				return "-back slash-";
			case "“":
				return "-start quote-";
			case "”":
				return "-end quote-";
			default:
				return char;
		}
	}
}