package;

import flixel.FlxGame;
import flixel.FlxState;
import funkin.MemoryCounter;
import haxe.ui.Toolkit;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.media.Video;
import openfl.net.NetStream;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = funkin.InitState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	#if web
	var framerate:Int = 60; // How many frames per second the game should run at.
	#else
	// TODO: This should probably be in the options menu?
	var framerate:Int = 144; // How many frames per second the game should run at.
	#end
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

		// TODO: Replace this with loadEnabledMods().
		funkin.modding.PolymodHandler.loadAllMods();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
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

	var video:Video;
	var netStream:NetStream;
	private var overlay:Sprite;

	public static var fpsCounter:FPS;
	public static var memoryCounter:MemoryCounter;

	private function setupGame():Void
	{
		/**
		 * The `zoom` argument of FlxGame was removed in the dev branch of Flixel,
		 * since it was considered confusing and unintuitive.
		 * If you want to change how the game scales when you resize the window,
		 * you can use `FlxG.scaleMode`.
		 * -Eric
		 */

		#if !debug
		initialState = funkin.TitleState;
		#end

<<<<<<< HEAD
		initHaxeUI();

		addChild(new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen));
=======
		haxe.ui.Toolkit.init();
		addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen));
>>>>>>> origin/note-redux

		#if debug
		fpsCounter = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsCounter);
		#if !html5
		memoryCounter = new MemoryCounter(10, 13, 0xFFFFFF);
		addChild(memoryCounter);
		#end
		#end
	}

	function initHaxeUI()
	{
		// Calling this before any HaxeUI components get used is important:
		// - It initializes the theme styles.
		// - It scans the class path and registers any HaxeUI components.
		Toolkit.init();
		Toolkit.theme = "dark"; // don't be cringe
	}
}
