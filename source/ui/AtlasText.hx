package ui;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

using StringTools;

enum AtlasFont
{
	Default;
	Bold;
}

enum Case
{
	Both
	Upper
	Lower
}

class AtlasText extends FlxTypedSpriteGroup<Dynamic>
{
	public var text:String = '';

	override public function new(a = 0, b = 0, c, d = Default)
	{
		if (fonts.exists(d))
			fonts.set(d, new AtlasFontData(Case.createByIndex(d.getIndex())));
		font = fonts.get(d);
		super(a, b);
		set_text(c);
	}
}

class AtlasFontData
{
	public var caseAllowed = Both;
	public var maxHeight = 0;
	public var atlas:FlxAtlasFrames;
	public static var upperChar:Dynamic;
	public static var lowerChar:Dynamic;
	
	public function new(a:Case)
	{
		atlas = Paths.getSparrowAtlas(a.getParameters()[0].toLowerCase());
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