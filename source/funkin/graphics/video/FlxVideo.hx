package funkin.graphics.video;

#if html5
import flixel.util.FlxColor;
import funkin.audio.FunkinSound;
import openfl.events.NetStatusEvent;
import openfl.media.SoundTransform;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;

/**
 * Plays a video via a NetStream. Only works on HTML5.
 * This does NOT replace hxvlc, nor does hxvlc replace this.
 * hxvlc only works on native and does not work on HTML5!
 */
@:nullSafety
class FlxVideo extends FunkinSprite
{
  var video:Video;
  var netStream:NetStream;
  var videoPath:String = "";

  /**
   * A callback to execute when the video finishes.
   */
  public var finishCallback:Null<Void->Void> = null;

  @:nullSafety(Off)
  public function new(?videoPath:String)
  {
    super();

    video = new Video();

    var netConnection:NetConnection = new NetConnection();
    netConnection.connect(null);
    netStream = new NetStream(netConnection);
    netConnection.addEventListener(NetStatusEvent.NET_STATUS, onNetConnectionNetStatus);

    load(videoPath);

    makeSolidColor(2, 2, FlxColor.TRANSPARENT);
  }

  public function load(?videoPath:String):Bool
  {
    if (videoPath == null) return false;

    if (!funkin.assets.Assets.exists(videoPath)) return false;

    this.videoPath = videoPath;

    video.x = 0;
    video.y = 0;
    video.alpha = 0;

    FlxG.game.addChild(video);

    netStream.client = {
      onMetaData: onClientMetaData
    };
    netStream.play(videoPath);

    return true;
  }

  /**
   * Tell the FlxVideo to pause playback.
   */
  public function pauseVideo():Void
  {
    if (netStream != null)
    {
      netStream.pause();
    }
  }

  /**
   * Tell the FlxVideo to resume if it is paused.
   */
  public function resumeVideo():Void
  {
    // Resume playing the video.
    if (netStream != null)
    {
      netStream.resume();
    }
  }

  var videoAvailable:Bool = false;
  var frameTimer:Float = 0;

  static final FRAME_RATE:Float = 60;

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (frameTimer >= (1 / FRAME_RATE))
    {
      frameTimer = 0;
      // TODO: We just draw the video buffer to the sprite 60 times a second.
      // Can we copy the video buffer instead somehow?
      pixels.draw(video);
    }

    if (videoAvailable) frameTimer += elapsed;
  }

  /**
   * Tell the FlxVideo to seek to the beginning.
   */
  public function restartVideo():Void
  {
    // Seek to the beginning of the video.
    if (netStream != null)
    {
      netStream.seek(0);
    }
  }

  /**
   * Tell the FlxVideo to end.
   */
  public function finishVideo():Void
  {
    netStream.dispose();
    FlxG.removeChild(video);

    if (finishCallback != null) finishCallback();
  }

  override public function destroy():Void
  {
    if (netStream != null)
    {
      netStream.dispose();

      if (FlxG.game.contains(video)) FlxG.game.removeChild(video);
    }

    super.destroy();
  }

  /**
   * Callback executed when the video stream loads.
   * @param metaData The metadata of the video
   */
  public function onClientMetaData(metaData:Dynamic):Void
  {
    video.attachNetStream(netStream);

    onVideoReady();
  }

  function onVideoReady():Void
  {
    final videoWidth:Int = video.videoWidth;
    final videoHeight:Int = video.videoHeight;

    if (videoWidth <= 0 || videoHeight <= 0)
    {
      return;
    }

    video.width = videoWidth;
    video.height = videoHeight;
    video.smoothing = true;

    makeGraphic(videoWidth, videoHeight, FlxColor.TRANSPARENT);
    setGraphicSize(FlxG.width, FlxG.height);
    updateHitbox();

    videoAvailable = true;

    FunkinSound.onVolumeChanged.add(onVolumeChanged);
    onVolumeChanged(FlxG.sound.muted ? 0 : FlxG.sound.volume);
  }

  function onVolumeChanged(volume:Float):Void
  {
    netStream.soundTransform = new SoundTransform(volume);
  }

  function onNetConnectionNetStatus(event:NetStatusEvent):Void
  {
    if (event.info.code == 'NetStream.Play.Complete') finishVideo();
  }
}
#end
