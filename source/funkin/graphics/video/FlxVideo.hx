package funkin.graphics.video;

import flixel.FlxBasic;
import flixel.FlxSprite;
import openfl.events.NetStatusEvent;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;

/**
 * Plays a video via a NetStream. Only works on HTML5.
 */
class FlxVideo extends FlxBasic
{
  var video:Video;
  var netStream:NetStream;

  public var finishCallback:Void->Void;

  /**
   * Doesn't actually interact with Flixel shit, only just a pleasant to use class
   */
  public function new(videoPath:String)
  {
    super();

    video = new Video();
    video.x = 0;
    video.y = 0;

    FlxG.addChildBelowMouse(video);

    var netConnection = new NetConnection();
    netConnection.connect(null);

    netStream = new NetStream(netConnection);
    netStream.client = {onMetaData: client_onMetaData};
    netConnection.addEventListener(NetStatusEvent.NET_STATUS, netConnection_onNetStatus);
    netStream.play(videoPath);
  }

  public function finishVideo():Void
  {
    netStream.dispose();
    FlxG.removeChild(video);

    if (finishCallback != null) finishCallback();
  }

  public function client_onMetaData(metaData:Dynamic)
  {
    video.attachNetStream(netStream);

    video.width = FlxG.width;
    video.height = FlxG.height;
  }

  function netConnection_onNetStatus(event:NetStatusEvent):Void
  {
    if (event.info.code == 'NetStream.Play.Complete') finishVideo();
  }
}
