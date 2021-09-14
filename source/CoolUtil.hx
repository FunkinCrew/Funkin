package;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import haxe.Json;
import haxe.format.JsonParser;
import lime.math.Rectangle;
import lime.utils.Assets;
import openfl.filters.ShaderFilter;
import shaderslmfao.ScreenWipeShader;

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
		var daList:Array<String> = [];

		var swagArray:Array<String> = Assets.getText(path).trim().split('\n');

		for (item in swagArray)
		{
			// comment support in the quick lil text formats??? using //
			if (!item.trim().startsWith('//'))
				daList.push(item);
		}

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

	public static function coolSwitchState(state:FlxState, transitionTex:String = "shaderTransitionStuff/coolDots", time:Float = 2)
	{
		var screenShit:FlxSprite = new FlxSprite().loadGraphic(Paths.image("shaderTransitionStuff/coolDots"));
		var screenWipeShit:ScreenWipeShader = new ScreenWipeShader();

		screenWipeShit.funnyShit.input = screenShit.pixels;
		FlxTween.tween(screenWipeShit, {daAlphaShit: 1}, time, {
			ease: FlxEase.quadInOut,
			onComplete: function(twn)
			{
				screenShit.destroy();
				FlxG.switchState(new MainMenuState());
			}
		});
		FlxG.camera.setFilters([new ShaderFilter(screenWipeShit)]);
	}

	/**
	 * Hashlink json encoding fix for some wacky bullshit
	 * https://github.com/HaxeFoundation/haxe/issues/6930#issuecomment-384570392
	 */
	public static function coolJSON(fileData:String)
	{
		var cont = fileData;
		function is(n:Int, what:Int)
			return cont.charCodeAt(n) == what;
		return JsonParser.parse(cont.substr(if (is(0, 65279)) /// looks like a HL target, skipping only first character here:
			1 else if (is(0, 239) && is(1, 187) && is(2, 191)) /// it seems to be Neko or PHP, start from position 3:
			3 else /// all other targets, that prepare the UTF string correctly
			0));
	}

	/*
	 * frame dependant lerp kinda lol
	 */
	public static function coolLerp(base:Float, target:Float, ratio:Float):Float
	{
		return base + camLerpShit(ratio) * (target - base);
	}
}
