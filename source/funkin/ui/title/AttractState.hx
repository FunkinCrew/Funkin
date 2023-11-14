package funkin.ui.title;

#if html5
import funkin.graphics.video.FlxVideo;
#else
import hxcodec.flixel.FlxVideoSprite;
#end
import funkin.ui.MusicBeatState;

/**
 * After about 2 minutes of inactivity on the title screen,
 * the game will enter the Attract state, as a reference to physical arcade machines.
 *
 * In the current version, this just plays the Kickstarter trailer, but this can be changed to
 * gameplay footage, a generic game trailer, or something more elaborate.
 */
class AttractState extends MusicBeatState
{
  static final ATTRACT_VIDEO_PATH:String = Paths.videos('kickstarterTrailer');

  public override function create():Void
  {
    // Pause existing music.
    FlxG.sound.music.stop();

    #if html5
    playVideoHTML5(ATTRACT_VIDEO_PATH);
    #else
    playVideoNative(ATTRACT_VIDEO_PATH);
    #end
  }

  #if html5
  var vid:FlxVideo;

  function playVideoHTML5(filePath:String):Void
  {
    // Video displays OVER the FlxState.
    vid = new FlxVideo(filePath);
    if (vid != null)
    {
      vid.zIndex = 0;

      vid.finishCallback = onAttractEnd;

      add(vid);
    }
    else
    {
      trace('ALERT: Video is null! Could not play cutscene!');
    }
  }
  #else
  var vid:FlxVideoSprite;

  function playVideoNative(filePath:String):Void
  {
    // Video displays OVER the FlxState.
    vid = new FlxVideoSprite(0, 0);

    if (vid != null)
    {
      vid.zIndex = 0;
      vid.bitmap.onEndReached.add(onAttractEnd);

      add(vid);
      vid.play(filePath, false);
    }
    else
    {
      trace('ALERT: Video is null! Could not play cutscene!');
    }
  }
  #end

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // If the user presses any button, skip the video.
    if (FlxG.keys.justPressed.ANY)
    {
      onAttractEnd();
    }
  }

  /**
   * When the attraction state ends (after the video ends or the user presses any button),
   * switch immediately to the title screen.
   */
  function onAttractEnd():Void
  {
    #if html5
    if (vid != null)
    {
      remove(vid);
    }
    #else
    if (vid != null)
    {
      vid.stop();
      remove(vid);
    }
    #end
    vid.destroy();
    vid = null;

    FlxG.switchState(new TitleState());
  }
}
