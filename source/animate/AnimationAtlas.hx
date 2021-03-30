package animate;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets.FlxGraphicAsset;
import haxe.Json;
import openfl.Assets;

class AnimationAtlas
{
	public function new(data:Dynamic, atlas:FlxAtlasFrames):Void {}

	public static function fromAnimate(Source:FlxGraphicAsset, Description:String):FlxAtlasFrames
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(Source);
		if (graphic == null)
			return null;

		var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(graphic);
		if (frames != null)
			return frames;

		if (graphic == null || Description == null)
			return null;

		frames = new FlxAtlasFrames(graphic);

		var data:AnimateObject;

		var json:String = Description;

		trace(json);

		if (Assets.exists(json))
			json = Assets.getText(json);

		trace(json);

		data = cast Json.parse(json).ATLAS;

		for (sprite in data.SPRITES)
		{
			// probably nicer way to do this? Oh well
			var swagSprite:AnimateSprite = sprite.SPRITE;

			trace(swagSprite);
		}

		return frames;
	}
}

typedef AnimateObject =
{
	SPRITES:Array<Dynamic>
}

typedef AnimateSprite =
{
	var name:String;
	var x:Int;
	var y:Int;
	var w:Int;
	var h:Int;
	var rotated:Bool;
}
