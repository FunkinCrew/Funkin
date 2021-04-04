package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import haxe.Json;
import lime.math.Rectangle;
import lime.utils.Assets;

using StringTools;

class CoolUtil
{
	public static var difficultyArray:Array<String> = ['EASY', "NORMAL", "HARD"];

	public static function difficultyString():String
	{
		return difficultyArray[PlayState.storyDifficulty];
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	/**
		Lerps camera, but accountsfor framerate shit?
		Right now it's simply for use to change the followLerp variable of a camera during update
		TODO LATER MAYBE:
			Actually make and modify the scroll and lerp shit in it's own function
			instead of solely relying on changing the lerp on the fly
	 */
	public static function camLerpShit(lerp:Float):Float
	{
		return lerp * (FlxG.elapsed / (1 / 60));
	}

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

		data = cast Json.parse(json).ATLAS;

		for (sprite in data.SPRITES)
		{
			// probably nicer way to do this? Oh well
			var swagSprite:AnimateSprite = sprite.SPRITE;

			var rect = FlxRect.get(swagSprite.x, swagSprite.y, swagSprite.w, swagSprite.h);

			var size = new Rectangle(0, 0, rect.width, rect.height);

			var offset = FlxPoint.get(-size.left, -size.top);
			var sourceSize = FlxPoint.get(size.width, size.height);

			frames.addAtlasFrame(rect, sourceSize, offset, swagSprite.name);
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
