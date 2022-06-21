package;

import sys.io.File;
import sys.FileSystem;
import lime.app.Application;
import states.menu.TitleState;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (FileSystem.exists("./log.txt"))
			FileSystem.deleteFile("./log.txt");
		
		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}

		Application.current.window.title = 'Friday Night Funkin\' Sharp Engine (V-${Application.current.meta.get("version")} ';

		#if LITE // LITE = 32bit
		Application.current.window.title += "x86)";
		#else
		Application.current.window.title += "x64)";
		#end

		#if debug
		Application.current.window.title += " [DEBUG]";
		#end

		// custom function to replace trace() calls
		haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos)
		{
			var date = new Date(2022, 6, 21, 7, 21, 0);
			date = Date.now();
			
			var finalStr = '(${date.getUTCHours()}:${date.getUTCMinutes()}:${date.getUTCSeconds()})[${infos.className} -> ${infos.methodName} at ${infos.lineNumber}]: $v';
			Sys.println(finalStr);
			if (!FileSystem.exists("./log.txt"))
			{
				File.saveContent('./log.txt', 'LOG FILE\n${date.getUTCDate()}.${date.getUTCMonth()}.${date.getUTCFullYear()} at ${date.getUTCHours()}:${date.getUTCMinutes()}:${date.getUTCSeconds()} (All times are kept in UTC)\n');
			}

			var fHandle = File.append("./log.txt");
			fHandle.writeString(finalStr + '\n');
			fHandle.close();
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		#if !debug
		initialState = TitleState;
		#end

		addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen));

		#if !mobile
		addChild(new FPS(10, 3, 0xFFFFFF));
		#end
	}
}
