package;

import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;

class Main extends Sprite
{
	public static var instance:Main = null;
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	public static var framerate:Int = 120; // How many frames per second the game should run at.
	public var fps:FPS;
	public var mem:MemoryCounter;

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

		instance = this;

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

		#if cpp
		initialState = Loading;
		addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, false, startFullscreen));
		#else
		addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, false, startFullscreen));
		#end

		#if !mobile
		fps = new FPS(10, 3, 0xFFFFFF);
		mem = new MemoryCounter(10, 3, 0xFFFFFF);
		fps.borderColor = flixel.util.FlxColor.BLACK;
		mem.borderColor = flixel.util.FlxColor.BLACK;

		addChild(fps);
		addChild(mem);
		#end
	}

	public function changeFPS()
	{
		fps.visible = !fps.visible;
		mem.visible = !mem.visible;
	}

	public function changeCap()
	{
		if(framerate == 60)
			framerate = 120;
		else if(framerate == 120)
			framerate = 240;
		else if(framerate == 240)
			framerate = 400;
		else
			framerate = 60;

		
		openfl.Lib.current.stage.frameRate = framerate;
			
	}
}
