package;

import openfl.Lib;
import openfl.display.Sprite;
import openfl.net.NetConnection;
import openfl.media.Video;
import openfl.net.NetStream;
import flixel.FlxG;

class VideoState extends MusicBeatState
{
	public static var seenVideo:Bool = false;

	#if web
	private var video:Video;
	private var netStream:NetStream;
	private var overlay:Sprite;
	#end

	override function create()
	{
		super.create();

		seenVideo = true;
		FlxG.save.data.seenVideo = true;
		FlxG.save.flush();

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
		}

		#if web
		video = new Video();
		FlxG.addChildBelowMouse(video);

		var netConnection:NetConnection = new NetConnection();
		netConnection.connect(null);
		netStream = new NetStream(netConnection);
		netStream.client = {onMetaData: client_onMetaData};
		netStream.addEventListener('asyncError', netStream_onAsyncError);
		netConnection.addEventListener('netStatus', netConnection_onNetStatus);
		netStream.play(Paths.video('kickstarterTrailer'));

		overlay = new Sprite();
		overlay.graphics.beginFill(0, 0.5);
		overlay.graphics.drawRect(0, 0, 1280, 720);
		overlay.addEventListener('mouseDown', overlay_onMouseDown);
		overlay.buttonMode = true;
		#else
		finishVid(); // fallback for other targets
		#end
	}

	override function update(elapsed:Float)
	{
		if (controls.ACCEPT)
			finishVid();

		super.update(elapsed);
	}

	private function finishVid()
	{
		#if web
		netStream.dispose();
		if (FlxG.game.contains(video))
			FlxG.game.removeChild(video);
		#end

		TitleState.initialized = false;
		FlxG.switchState(new TitleState());
	}

	#if web
	private function client_onMetaData(e)
	{
		video.attachNetStream(netStream);
		video.width = video.videoWidth;
		video.height = video.videoHeight;
	}

	private function netStream_onAsyncError(e)
	{
		trace('Error loading video');
	}

	private function netConnection_onNetStatus(e)
	{
		if (e.info.code == 'NetStream.Play.Complete')
		{
			finishVid();
		}
		trace(e.toString());
	}

	private function overlay_onMouseDown(e)
	{
		netStream.soundTransform.volume = 0.2;
		netStream.soundTransform.pan = -1;
		Lib.current.stage.removeChild(overlay);
	}
	#end
}