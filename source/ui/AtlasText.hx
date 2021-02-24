package ui;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.frames.FlxAtlasFrames;

@:forward
abstract BoldText(AtlasText) from AtlasText to AtlasText
{
	inline public function new (x = 0.0, y = 0.0, text:String)
	{
		this = new AtlasText(x, y, text, Bold);
	}
}

/**
 * Alphabet.hx has a ton of bugs and does a bunch of stuff I don't need, fuck that class
 */
class AtlasText extends FlxTypedSpriteGroup<AtlasChar>
{
	static var maxHeights = new Map<AtlasFont, Float>();
	public var text(default, set):String;
	
	var atlas:FlxAtlasFrames;
	var maxHeight = 0.0;
	
	public function new (x = 0.0, y = 0.0, text:String, font:AtlasFont = Default)
	{
		atlas = Paths.getSparrowAtlas("fonts/" + font.getName().toLowerCase());
		if (maxHeights.exists(font))
		{
			maxHeight = 0;
			for (frame in atlas.frames)
				maxHeight = Math.max(maxHeight, frame.frame.height);
			maxHeights[font] = maxHeight;
		}
		maxHeight = maxHeights[font];
		
		super(x, y);
		
		this.text = text;
	}
	
	function set_text(value:String)
	{
		if (this.text == value)
			return this.text;
		
		group.kill();
		
		var xPos:Float = 0;
		var yPos:Float = 0;
		
		var charCount = 0;
		for (char in value.split(""))
		{
			switch(char)
			{
				case " ":
				{
					xPos += 40;
				}
				case "\n":
				{
					xPos = 0;
					yPos += 55;
				}
				default:
				{
					var charSprite:AtlasChar;
					if (group.members.length <= charCount)
						charSprite = new AtlasChar(atlas, char);
					else
					{
						charSprite = group.members[charCount];
						charSprite.revive();
						charSprite.char = char;
					}
					charSprite.x = xPos;
					charSprite.y = yPos + maxHeight - charSprite.height;
					add(charSprite);
					
					xPos += charSprite.width;
					charCount++;
				}
			}
		}
		// updateHitbox();
		return this.text = value;
	}
}

class AtlasChar extends FlxSprite
{
	public var char(default, set):String;
	public function new(x = 0.0, y = 0.0, atlas:FlxAtlasFrames, char:String)
	{
		super(x, y);
		frames = atlas;
		this.char = char;
		antialiasing = true;
	}
	
	function set_char(value:String)
	{
		if (this.char != value)
		{
			animation.addByPrefix("anim", getAnimPrefix(value), 24);
			animation.play("anim");
			updateHitbox();
		}
		
		return this.char = value;
	}
	
	function getAnimPrefix(char:String)
	{
		return switch (char)
		{
			case '-': '-dash-';
			case '.': '-period-';
			case ",": '-comma-';
			case "'": '-apostraphie-';
			case "?": '-question mark-';
			case "!": '-exclamation point-';
			case "\\": '-back slash-';
			case "/": '-forward slash-';
			case "*": '-multiply x-';
			case "“": '-start quote-';
			case "”": '-end quote-';
			default: char;
		}
	}
}

enum AtlasFont
{
	Default;
	Bold;
}