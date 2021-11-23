package ui;

import haxe.ds.EnumValueMap;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

using StringTools;

enum Case
{
	Both;
	Upper;
	Lower;
}

class AtlasText extends FlxTypedSpriteGroup<Dynamic>
{
	public static var fonts:EnumValueMap<AtlasFont, AtlasFontData> = new EnumValueMap<AtlasFont, AtlasFontData>();

	public var text:String = '';
	public var font:AtlasFontData;

	override public function new(x:Float = 0, y:Float = 0, text:String, fontType:AtlasFont = Default)
	{
		if (!fonts.exists(fontType))
			fonts.set(fontType, new AtlasFontData(fontType));
		font = fonts.get(fontType);
		super(x, y);
		set_text(text);
	}

	public function set_text(text:String = '')
	{
		var b:String = restrictCase(text);
		var c:String = restrictCase(this.text);
		this.text = text;
		if (b == c) return text;
		if (b.indexOf(c) == 0)
		{
			appendTextCased(b.substr(c.length));
			return this.text;
		}
		if (b == '') return this.text;
		appendTextCased(b);
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
		var b = group.countLiving();
		var c:Float = 0;
		var d:Dynamic = 0;
		if (b == -1)
		{
			b = 0;
		}
		else if (b > 0)
		{
			d = group.members[b - 1];
			c = d.x + d.width - x;
			d = d.y + d.height - font.maxHeight - y;
		}
		var split = text.split('');
		var k;
		for (char in 0...split.length)
		{
			switch (split[char])
			{
				case '\n':
					c = 0;
					d += font.maxHeight;
				case ' ':
					c += 40;
				default:
					if (group.members.length <= b)
					{
						k = new AtlasChar(0, 0, font.atlas, split[char]);
					}
					else
					{
						k = group.members[b];
						k.revive();
						k.set_char(split[char]);
						k.set_alpha(1);
					}
					k.set_x(c);
					k.set_y(d + font.maxHeight - k.height);
					add(k);
					c += k.width;
					++b;
			}
		}
	}
}

class AtlasFontData
{
	public var caseAllowed = Both;
	public var maxHeight = 0;
	public var atlas:FlxAtlasFrames;
	public static var upperChar = new EReg("^[A-Z]\\d+$","");
	public static var lowerChar = new EReg("^[a-z]\\d+$","");
	
	public function new(font:AtlasFont)
	{
		var path = 'fonts/'+font.getName().toLowerCase();
		atlas = Paths.getSparrowAtlas(path);
		atlas.parent.destroyOnNoUse = false;
		atlas.parent.persist = true;

		var thingie = false;
		var thingie2 = false;
		for (i in 0...atlas.frames.length)
		{
			var framedata = atlas.frames[i];
			maxHeight = Std.int(Math.max(maxHeight, framedata.frame.height));
			if (!thingie)
			{
				thingie = upperChar.match(framedata.name);
			}
			if (!thingie2)
			{
				thingie2 = lowerChar.match(framedata.name);
			}
		}
		if (thingie != thingie2)
		{
			caseAllowed = thingie ? Upper : Lower;
		}
	}
}