package;

#if desktop
import Discord.DiscordClient;
#end

import flixel.FlxGame;
import flixel.FlxState;
import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxTween.TweenOptions;
import flixel.util.FlxTimer;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.AsyncErrorEvent;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.NetStatusEvent;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
#if desktop
import lime.app.Application;
#end

//crash handler stuff
#if ErrorDialog
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
#end

using StringTools;

class Main extends Sprite
{
	/*
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	*/
	#if (!desktop || !mobile)
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};
	#else
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 144, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	#end
	/*
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets
	*/

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

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

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}

		#if !debug
		//initialState = TitleState;
		#end

		addChild(new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

		#if !mobile
		fpsCounter = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsCounter);
		#end

		#if ErrorDialog
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end
		
		#if desktop
		Application.current.window.onFocusOut.add(onWindowFocusOut);
		Application.current.window.onFocusIn.add(onWindowFocusIn);
		#end
		
		/* 
			video = new Video();
			addChild(video);

			var netConnection = new NetConnection();
			netConnection.connect(null);

			netStream = new NetStream(netConnection);
			netStream.client = {onMetaData: client_onMetaData};
			netStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, netStream_onAsyncError);

			#if (js && html5)
			overlay = new Sprite();
			overlay.graphics.beginFill(0, 0.5);
			overlay.graphics.drawRect(0, 0, 560, 320);
			overlay.addEventListener(MouseEvent.MOUSE_DOWN, overlay_onMouseDown);
			overlay.buttonMode = true;
			addChild(overlay);

			netConnection.addEventListener(NetStatusEvent.NET_STATUS, netConnection_onNetStatus);
			#else
			netStream.play("assets/preload/music/dredd.mp4");
			#end 
		 */
	}
	/* 
		private function client_onMetaData(metaData:Dynamic)
		{
			video.attachNetStream(netStream);

			video.width = video.videoWidth;
			video.height = video.videoHeight;
		}

		private function netStream_onAsyncError(event:AsyncErrorEvent):Void
		{
			trace("Error loading video");
		}

		private function netConnection_onNetStatus(event:NetStatusEvent):Void
		{
		}

		private function overlay_onMouseDown(event:MouseEvent):Void
		{
			netStream.play("assets/preload/music/dredd.mp4");
		}
	 */

	#if desktop
	var oldVol:Float = 1.0;
	var newVol:Float = 0.3;

	public static var focused:Bool = true;

	public static var focusMusicTween:FlxTween;

	// thx for ur code ari
	function onWindowFocusOut()
	{
		focused = false;

		// Lower global volume when unfocused
		if (Type.getClass(FlxG.state) != PlayState) // imagine stealing my code smh
		{
			oldVol = FlxG.sound.volume;
			if (oldVol > 0.3)
			{
				newVol = 0.3;
			}
			else
			{
				if (oldVol > 0.1)
				{
					newVol = 0.1;
				}
				else
				{
					newVol = 0;
				}
			}

			trace("Game unfocused");

			if (focusMusicTween != null)
				focusMusicTween.cancel();
			focusMusicTween = FlxTween.tween(FlxG.sound, {volume: newVol}, 0.5);

			// Conserve power by lowering draw framerate when unfocuced
			FlxG.updateFramerate = 60;
			FlxG.drawFramerate = 60;
		}
	}

	function onWindowFocusIn()
	{
		new FlxTimer().start(0.2, function(tmr:FlxTimer)
		{
			focused = true;
		});

		// Lower global volume when unfocused
		if (Type.getClass(FlxG.state) != PlayState)
		{
			trace("Game focused");

			// Normal global volume when focused
			if (focusMusicTween != null)
				focusMusicTween.cancel();

			focusMusicTween = FlxTween.tween(FlxG.sound, {volume: oldVol}, 0.5);

			// Bring framerate back when focused
			FlxG.drawFramerate = 144;
			FlxG.updateFramerate = 144;
		}
	}
	#end

	// Code was entirely made by sqirra-rng for their fnf engine named "Izzy Engine", big props to them!!!
	// very cool person for real they don't get enough credit for their work
	#if ErrorDialog
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error + "\nPlease report this error to the GitHub page: https://github.com/nennneko5787/FNF-nekoEngine2\n\n> Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists("./crash/"))
			FileSystem.createDirectory("./crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		#if discord_rpc
		DiscordClient.shutdown();
		#end
		Sys.exit(1);
	}
	#end
}
