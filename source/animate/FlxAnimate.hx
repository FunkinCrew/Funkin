package animate;

import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxPoint;
import openfl.geom.Rectangle;
import flixel.math.FlxRect;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxG;
import lime.utils.Assets;
import haxe.Json;

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

	/**
	 * Parsing method for Animate texture atlases
	 * 
	 * @param Source 		  The image source (can be `FlxGraphic`, `String` or `BitmapData`).
	 * @param Description	  Contents of the JSON file with atlas description.
	 *                        You can get it with `Assets.getText(path/to/description.json)`.
	 *                        Or you can just pass a path to the JSON file in the assets directory.
	 * @return  Newly created `FlxAtlasFrames` collection.
	 */
	 public static function fromAnimate(Source:FlxGraphicAsset, Description:String):FlxAtlasFrames
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(Source);
		if (graphic == null)
			return null;

		// No need to parse data again
		var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(graphic);
		if (frames != null)
			return frames;

		if (graphic == null || Description == null)
			return null;

		frames = new FlxAtlasFrames(graphic);

		trace(Description);
		if (Assets.exists(Description))
			Description = Assets.getText(Description);

		var data:AnimateAtlas = Json.parse(Description);

		for (sprites in data.ATLAS.SPRITES)
		{
			var spr:AnimateSpriteData = sprites.SPRITE;

			var rect:FlxRect = FlxRect.get(spr.x, spr.y, spr.w, spr.h);
			var size:Rectangle = new Rectangle(0, 0, rect.width, rect.height);

			var offset = FlxPoint.get(-size.left, -size.top);
			var sourceSize = FlxPoint.get(size.width, size.height);

			frames.addAtlasFrame(rect, sourceSize, offset, spr.name);
		}

		return frames;
	}

	override function draw()
	{
		super.draw();

		renderFrame(coolParse.AN.TL, coolParse, true);
		
		if (FlxG.keys.justPressed.E)
		{
			for (key in FlxSymbol.nestedShit.keys())
			{
				for (symbol in FlxSymbol.nestedShit.get(key))
				{
					symbol.draw();
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

typedef AnimateAtlas =
{
	var ATLAS:AnimateSprites;
};

typedef AnimateSprites =
{
	var SPRITES:Array<AnimateSprite>;
};

typedef AnimateSprite =
{
	var SPRITE:AnimateSpriteData;
};

typedef AnimateSpriteData =
{
	var name:String;
	var x:Float;
	var y:Float;
	var w:Float;
	var h:Float;
	var rotated:Bool;
};