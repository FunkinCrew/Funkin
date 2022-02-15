package animate;

import flixel.math.FlxPoint;
import openfl.geom.Rectangle;
import flixel.math.FlxRect;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxG;
import lime.utils.Assets;
import haxe.Json;
import openfl.utils.Assets as OpenFlAssets;

// I sincerely apologize for the rather shitty variable names and the error preventers.
// The variables are not named in the code, and I have no fucking idea what they are doing. Typedefs don't exist either.
// If you have a general understanding of the variables and have good names, please reach out to me via an issue marked as an "enhancement", or a pull request.
// 
// - AngelDTF, programmer of the Newgrounds Port
// https://github.com/AngelDTF/FNF-NewgroundsPort

class FlxAnimate extends FlxSymbol
{
	var playingAnim:Bool = false;
	var frameTickTypeShit:Float = 0;

	override public function new(x:Float, y:Float)
	{
		coolParse = Json.parse(Assets.getText(Paths.getPath('images/tightBars/Animation.json', TEXT, null)));
		coolParse.AN.TL.L.reverse();
		super(x, y, coolParse);
		frames = fromAnimate(Paths.getPath('images/tightBars/spritemap1.png', TEXT, null), Paths.getPath('images/tightBars/spritemap1.json', TEXT, null));
	}

	public static function fromAnimate(img:String, json:String)
	{
		var c1 = FlxG.bitmap.add(img);
		if (c1 == null)
			return null;
		var a1 = FlxAtlasFrames.findFrame(c1);
		if (a1 != null)
			return a1;
		if (c1 == null || json == null)
			return null;
		var a2 = new FlxAtlasFrames(c1);
		trace(json);
		if (OpenFlAssets.exists(json))
			json = OpenFlAssets.getText(json);
		var c2:Array<Dynamic> = Json.parse(json).ATLAS.SPRITES;
		for (d1 in c2)
		{
			var d2 = d1.SPRITE;
			var n = FlxRect.get(d2.x, d2.y, d2.w, d2.h);
			var m1 = new Rectangle(0, 0, n.width, n.height);
			var e = FlxPoint.get(-m1.left, -m1.top);
			var m2 = FlxPoint.get(m1.width, m1.height);
			a2.addAtlasFrame(n, m2, e, d2.name);
		}
		return a2;
	}

	override function draw()
	{
		super.draw();

		renderFrame(coolParse.AN.TL, coolParse, true);
		
		if (FlxG.keys.justPressed.E)
		{
			for (i in FlxSymbol.nestedShit.keys())
			{
				for (j in FlxSymbol.nestedShit.get(i))
				{
					j.draw();
				}
			}
			FlxSymbol.nestedShit.clear();
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE)
		{
			playingAnim = !playingAnim;
		}

		if (playingAnim)
		{
			frameTickTypeShit += elapsed;
			
			if (frameTickTypeShit >= 1 / 24)
			{
				changeFrame(1);
				frameTickTypeShit = 0;
			}
		}

		if (FlxG.keys.justPressed.RIGHT)
		{
			changeFrame(1);
		}
		if (FlxG.keys.justPressed.LEFT)
		{
			changeFrame(-1);
		}
	}
}