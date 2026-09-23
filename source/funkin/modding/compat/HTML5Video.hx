package funkin.modding.compat;

#if html5
import funkin.graphics.video.FlxVideo;
import lime.app.Event;
import openfl.events.NetStatusEvent;

/**
 * Reimplements the interface for desktop video playback using an HTML5 video.
 */
class HTML5Video extends FlxVideo
{
  /**
   * Dummy class to simulate the interface of FlxInternalVideo.
   */
  public var bitmap:DummyFlxInternalVideo = new DummyFlxInternalVideo();

  public function new()
  {
    super();
  }

  override function onVideoReady():Void
  {
    bitmap.onOpening.dispatch();

    super.onVideoReady();
  }

  override function onNetConnectionNetStatus(event:NetStatusEvent):Void
  {
    switch (event.info.code)
    {
      case 'NetStream.Play.Start':
        bitmap.onPlaying.dispatch();
      case 'NetStream.Play.Complete':
        bitmap.onEndReached.dispatch();
        finishVideo();
      case 'NetStream.Play.Stop':
        bitmap.onStopped.dispatch();
    }
  }
}

/**
 * Dummy class to simulate the interface of FlxInternalVideo.
 */
class DummyFlxInternalVideo
{
  /**
   * Event triggered when the media is opening.
   */
  public var onOpening(default, null):Event<Void->Void> = new Event<Void->Void>();

  /**
   * Event triggered when playback starts.
   */
  public var onPlaying(default, null):Event<Void->Void> = new Event<Void->Void>();

  /**
   * Event triggered when playback stops.
   */
  public var onStopped(default, null):Event<Void->Void> = new Event<Void->Void>();

  /**
   * Event triggered when the end of the media is reached.
   */
  public var onEndReached(default, null):Event<Void->Void> = new Event<Void->Void>();

  public function new()
  {
  }
}
#end
