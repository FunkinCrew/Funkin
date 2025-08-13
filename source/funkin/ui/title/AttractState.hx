package funkin.ui.title;

#if html5
import funkin.graphics.video.FlxVideo;
#end
#if hxvlc
import funkin.graphics.video.FunkinVideoSprite;
#end
#if FEATURE_TOUCH_CONTROLS
import funkin.util.TouchUtil;
#end
import funkin.ui.MusicBeatState;
import funkin.ui.FullScreenScaleMode;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.addons.display.FlxPieDial;

/**
 * After 40 seconds of inactivity on the title screen,
 * the game will enter the Attract state, as a reference to physical arcade machines.
 *
 * In the current version, this just plays generic game/merch trailers,
 * but this can be updated to include gameplay footage, or something more elaborate.
 */
class AttractState extends MusicBeatState
{
  /**
   * The videos that can be played by the Attract state.
   * @param path The path to the video to play.
   * This used
   */
  static final VIDEO_PATHS:Array<{path:String}> = [
    {path: Paths.videos('mobileRelease')},
    {path: Paths.videos('boyfriendEverywhere')},
  ];

  static var nextVideoToPlay:Int = 0;

  /**
   * Duration you need to touch for to skip the video.
   */
  static final HOLD_TIME:Float = 1.5;

  var pie:FlxPieDial;
  var holdDelta:Float = 0;

  public override function create():Void
  {
    // Pause existing music.
    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.destroy();
      FlxG.sound.music = null;
    }

    #if html5
    var videoPath:String = getVideoPath();
    trace('Playing web video ${videoPath}');
    playVideoHTML5(videoPath);
    #end

    #if hxvlc
    var videoPath:String = getVideoPath();
    trace('Playing native video ${videoPath}');
    playVideoNative(videoPath);
    #end

    pie = new FlxPieDial(0, 0, 40, FlxColor.WHITE, 45, CIRCLE, true, 20);
    pie.x = FlxG.width - ((pie.width * 1.5) + FullScreenScaleMode.gameNotchSize.x);
    pie.y = FlxG.height - (pie.height * 1.5);
    pie.amount = 0;
    pie.replaceColor(FlxColor.BLACK, 0x8AC5C4C4);
    add(pie);
  }

  /**
   * Get the path of a random video to display to the user.
   * @return The video path to play.
   */
  function getVideoPath():String
  {
    var result:String = VIDEO_PATHS[nextVideoToPlay].path;

    nextVideoToPlay = (nextVideoToPlay + 1) % VIDEO_PATHS.length;

    #if html5
    result = Paths.stripLibrary(result);
    #end

    return result;
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
  #end

  #if hxvlc
  var vid:FunkinVideoSprite;

  function playVideoNative(filePath:String):Void
  {
    // Video displays OVER the FlxState.
    vid = new FunkinVideoSprite(0, 0);

    if (vid != null)
    {
      vid.zIndex = 0;
      vid.active = false;
      vid.bitmap.onEncounteredError.add(function(msg:String):Void {
        trace('[VLC] Encountered an error: $msg');

        onAttractEnd();
      });
      vid.bitmap.onEndReached.add(onAttractEnd);
      vid.bitmap.onFormatSetup.add(() -> {
        vid.setGraphicSize(FlxG.initialWidth, FlxG.initialHeight);
        vid.updateHitbox();
        vid.screenCenter();
      });

      add(vid);

      if (vid.load(filePath)) vid.play();
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

    // If the user presses any button or hold their screen for 1.5 seconds, skip the video.
    if ((FlxG.keys.pressed.ANY && !controls.VOLUME_MUTE && !controls.VOLUME_UP && !controls.VOLUME_DOWN) #if FEATURE_TOUCH_CONTROLS
      || TouchUtil.touch != null && TouchUtil.touch.pressed #end)
    {
      holdDelta += elapsed;
      holdDelta = holdDelta.clamp(0, HOLD_TIME);

      pie.scale.x = pie.scale.y = FlxMath.lerp(pie.scale.x, 1.3, Math.exp(-elapsed * 140.0));
    }
    else
    {
      holdDelta = FlxMath.lerp(holdDelta, -0.1, (elapsed * 3).clamp(0, 1));
      holdDelta = holdDelta.clamp(0, HOLD_TIME);
      pie.scale.x = pie.scale.y = FlxMath.lerp(pie.scale.x, 1, Math.exp(-elapsed * 160.0));
    }

    pie.amount = Math.min(1, Math.max(0, (holdDelta / HOLD_TIME) * 1.025));
    pie.alpha = FlxMath.remapToRange(pie.amount, 0.025, 1, 0, 1);

    // If the dial is full, skip the video.
    if (pie.amount >= 1) onAttractEnd();
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
    #end

    #if hxvlc
    if (vid != null)
    {
      vid.stop();
      remove(vid);
    }
    #end

    #if (html5 || hxvlc)
    vid.destroy();
    vid = null;
    #end

    FlxG.switchState(() -> new TitleState());
  }
}
