//This was made by GWebDev lol btw this uses actuate
package;

import motion.Actuate;
import openfl.display.Sprite;
import openfl.events.AsyncErrorEvent;
import openfl.events.MouseEvent;
import openfl.events.NetStatusEvent;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;
import flixel.FlxG;

using StringTools;

class VideoHandler
{
	public var netStream:NetStream;
	public var video:Video;
	public var isReady:Bool = false;
	public var addOverlay:Bool = false;
	public var vidPath:String = "";
	public var ignoreShit:Bool = false;
	
	public function new()
	{
		isReady = false;
	}
	
	public function source(?vPath:String):Void
	{
		if (vPath != null && vPath.length > 0)
		{
		vidPath = vPath;
		}
	}
	
	public function init1():Void
	{
		isReady = false;
		video = new Video();
		video.visible = false;
	}
	
	public function init2():Void
	{
		#if web
		var netConnection = new NetConnection ();
		netConnection.connect (null);
		
		netStream = new NetStream (netConnection);
		netStream.client = { onMetaData: client_onMetaData };
		netStream.addEventListener (AsyncErrorEvent.ASYNC_ERROR, netStream_onAsyncError);

		netConnection.addEventListener (NetStatusEvent.NET_STATUS, netConnection_onNetStatus);
		netConnection.addEventListener (NetStatusEvent.NET_STATUS, onPlay);
		netConnection.addEventListener (NetStatusEvent.NET_STATUS, onEnd);
		#end
	}
	
	public function client_onMetaData (metaData:Dynamic) {
		
		video.attachNetStream (netStream);
		
		video.width = FlxG.width;
		video.height = FlxG.height;
		
	}
	
	
	public function netStream_onAsyncError (event:AsyncErrorEvent):Void {
		
		trace ("Error loading video");
		
	}
	
	
	public function netConnection_onNetStatus (event:NetStatusEvent):Void {
		trace (event.info.code);
	}
	
	public function play():Void
	{
		#if web
		ignoreShit = true;
		netStream.close();
		init2();
		netStream.play(vidPath);
		ignoreShit = false;
		#end
		trace(vidPath);
	}
	
	public function stop():Void
	{
		netStream.close();
		onStop();
	}
	
	public function restart():Void
	{
		play();
		onRestart();
	}
	
	public function update(elapsed:Float):Void
	{
		video.x = GlobalVideo.calc(0);
		video.y = GlobalVideo.calc(1);
		video.width = GlobalVideo.calc(2);
		video.height = GlobalVideo.calc(3);
	}
	
	public var stopped:Bool = false;
	public var restarted:Bool = false;
	public var played:Bool = false;
	public var ended:Bool = false;
	public var paused:Bool = false;
	
	public function pause():Void
	{
		netStream.pause();
		paused = true;
	}
	
	public function resume():Void
	{
		netStream.resume();
		paused = false;
	}
	
	public function togglePause():Void
	{
		if (paused)
		{
			resume();
		} else {
			pause();
		}
	}
	
	public function clearPause():Void
	{
		paused = false;
	}
	
	public function onStop():Void
	{
		if (!ignoreShit)
		{
			stopped = true;
		}
	}
	
	public function onRestart():Void
	{
		restarted = true;
	}
	
	public function onPlay(event:NetStatusEvent):Void
	{
		if (event.info.code == "NetStream.Play.Start")
		{
			played = true;
		}
	}
	
	public function onEnd(event:NetStatusEvent):Void
	{
		if (event.info.code == "NetStream.Play.Complete")
		{
			ended = true;
		}
	}
	
	public function alpha():Void
	{
		video.alpha = GlobalVideo.daAlpha1;
	}
	
	public function unalpha():Void
	{
		video.alpha = GlobalVideo.daAlpha2;
	}
	
	public function hide():Void
	{
		video.visible = false;
	}
	
	public function show():Void
	{
		video.visible = true;
	}
}