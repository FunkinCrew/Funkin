package;

import modding.PolymodHandler;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.util.FlxColor;
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

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = InitState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	#if web
	var framerate:Int = 60; // How many frames per second the game should run at.
	#else
	var framerate:Int = 300; // How many frames per second the game should run at.

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

		// TODO: Ideally this should change to utilize a user interface.
		// 1. Call PolymodHandler.getAllMods(). This gives you an array of ModMetadata items,
		//      each of which contains information about the mod including an icon.
		// 2. Provide an interface to enable, disable, and reorder enabled mods.
		//      A design similar to that of Minecraft resource packs would be intuitive.
		// 3. The interface should save (to the save file) and output an ordered array of mod IDs.
		// 4. Replace the call to PolymodHandler.loadAllMods() with a call to PolymodHandler.loadModsById(ids:Array<String>).
		PolymodHandler.loadAllMods();

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
		// Lib.current.stage.color = null;

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
		fpsCounter = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsCounter);
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
}
