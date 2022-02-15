package ui;

import flixel.util.FlxStringUtil;
import haxe.ds.EnumValueMap;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class AtlasText extends FlxTypedSpriteGroup<AtlasChar>
{
	public static var fonts:EnumValueMap<AtlasFont, AtlasFontData> = new EnumValueMap<AtlasFont, AtlasFontData>();

	public var text(default, set):String = '';
	public var font:AtlasFontData;

	override public function new(?x:Float = 0, ?y:Float = 0, text:String, ?fontType:AtlasFont = Default)
	{
		if (!fonts.exists(fontType))
		{
			fonts.set(fontType, new AtlasFontData(fontType));
		}
		font = fonts.get(fontType);
		super(x, y);
		this.text = text;
	}

	function set_text(text:String = '')
	{
		var casedTextNew:String = restrictCase(text);
		var casedText:String = restrictCase(this.text);
		this.text = text;
		if (casedTextNew == casedText)
		{
			return text;
		}
		if (casedTextNew.indexOf(casedText) == 0)
		{
			appendTextCased(casedTextNew.substr(casedText.length));
			return this.text;
		}
		group.kill();
		if (casedTextNew == '')
		{
			return this.text;
		}
		appendTextCased(casedTextNew);
		return this.text;
	}

	public function restrictCase(text:String)
	{
		switch (font.caseAllowed)
		{
			case Both:
				return text;
			case Upper:
				return text.toUpperCase();
			case Lower:
				return text.toLowerCase(); 
		}
	}

	public function appendTextCased(text:String)
	{
		var length:Int = group.countLiving();
		var nextX:Float = 0;
		var nextY:Float = 0;
		if (length == -1)
		{
			length = 0;
		}
		else if (length > 0)
		{
			var member:AtlasChar = group.members[length - 1];
			nextX = member.x + member.width - x;
			nextY = member.y + member.height - font.maxHeight - y;
		}
		var split:Array<String> = text.split('');
		var spr:AtlasChar;
		for (char in split)
		{
			switch (char)
			{
				case '\n':
					nextX = 0;
					nextY += font.maxHeight;
				case ' ':
					nextX += 40;
				default:
					if (length >= group.members.length)
					{
						spr = new AtlasChar(null, null, font.atlas, char);
					}
					else
					{
						spr = group.members[length];
						spr.revive();
						spr.char = char;
						spr.alpha = 1;
					}
					spr.x = nextX;
					spr.y = nextY + font.maxHeight - spr.height;
					add(spr);
					nextX += spr.width;
					length++;
			}
		}
	}

	override public function toString()
	{
		var x:LabelValuePair = LabelValuePair.weak('x', this.x);
		var y:LabelValuePair = LabelValuePair.weak('y', this.y);
		var text:LabelValuePair = LabelValuePair.weak('text', this.text);
		return "InputItem, " + FlxStringUtil.getDebugString([x, y, text]);
	}
}

class AtlasFontData
{
	public static var upperChar:EReg = new EReg("^[A-Z]\\d+$","");
	public static var lowerChar:EReg = new EReg("^[a-z]\\d+$","");

	public var atlas:FlxAtlasFrames;
	public var maxHeight:Float = 0;
	public var caseAllowed:Case = Both;
	
	public function new(font:AtlasFont)
	{
		var path = 'fonts/'+font.getName().toLowerCase();
		atlas = Paths.getSparrowAtlas(path);
		atlas.parent.destroyOnNoUse = false;
		atlas.parent.persist = true;

		var hasUpper:Bool = false;
		var hasLower:Bool = false;
		for (framedata in atlas.frames)
		{
			maxHeight = Math.max(maxHeight, framedata.frame.height);
			if (!hasUpper)
			{
				hasUpper = upperChar.match(framedata.name);
			}
			if (!hasLower)
			{
				hasLower = lowerChar.match(framedata.name);
			}
		}
		if (hasUpper != hasLower)
		{
			caseAllowed = hasUpper ? Upper : Lower;
		}
	}
}