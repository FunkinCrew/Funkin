package ui;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class AtlasChar extends FlxSprite
{
	public var char(default, set):String;

	override public function new(?x:Float = 0, ?y:Float = 0, atlas:FlxAtlasFrames, char:String)
	{
		super(x, y);
		frames = atlas;
		this.char = char;
		antialiasing = true;
	}

	function set_char(char:String):String
	{
		if (this.char != char)
		{
			var prefix:String = getAnimPrefix(char);
			animation.addByPrefix('anim', prefix, 24);
			animation.play('anim');
			updateHitbox();
		}
		return this.char = char;
	}

	public function getAnimPrefix(char:String):String
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