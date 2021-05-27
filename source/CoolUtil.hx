package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
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

	static var oldCamPos:FlxPoint = new FlxPoint();
	static var oldMousePos:FlxPoint = new FlxPoint();

	public static function mouseCamDrag():Void
	{
		if (FlxG.mouse.justPressedMiddle)
		{
			oldCamPos.set(FlxG.camera.scroll.x, FlxG.camera.scroll.y);
			oldMousePos.set(FlxG.mouse.screenX, FlxG.mouse.screenY);
		}

		if (FlxG.mouse.pressedMiddle)
		{
			FlxG.camera.scroll.x = oldCamPos.x - (FlxG.mouse.screenX - oldMousePos.x);
			FlxG.camera.scroll.y = oldCamPos.y - (FlxG.mouse.screenY - oldMousePos.y);
		}
	}

	public static function mouseWheelZoom():Void
	{
		if (FlxG.mouse.wheel != 0)
			FlxG.camera.zoom += FlxG.mouse.wheel * (0.1 * FlxG.camera.zoom);
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

	/*
	 * frame dependant lerp kinda lol
	 */
	public static function coolLerp(base:Float, target:Float, ratio:Float):Float
	{
		return base + camLerpShit(ratio) * (target - base);
	}
}
