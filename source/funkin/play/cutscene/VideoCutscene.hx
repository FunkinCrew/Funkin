package funkin.play.cutscene;

import funkin.play.PlayState;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
#if html5
import funkin.graphics.video.FlxVideo;
#end
#if hxvlc
import funkin.graphics.video.FunkinVideoSprite;
#end

/**
 * Assumes you are in the PlayState.
 */
class VideoCutscene
{
  static var blackScreen:FlxSprite;
  static var cutsceneType:CutsceneType;

  #if html5
  static var vid:FlxVideo;
  #end
  #if hxvlc
  static var vid:FunkinVideoSprite;
  #end

  /**
   * Called when the video is started.
   */
  public static final onVideoStarted:FlxSignal = new FlxSignal();

  /**
   * Called if the video is paused.
   */
  public static final onVideoPaused:FlxSignal = new FlxSignal();

  /**
   * Called if the video is resumed.
   */
  public static final onVideoResumed:FlxSignal = new FlxSignal();

  /**
   * Called if the video is restarted. onVideoStarted is not called.
   */
  public static final onVideoRestarted:FlxSignal = new FlxSignal();

  /**
   * Called when the video is ended or skipped.
   */
  public static final onVideoEnded:FlxSignal = new FlxSignal();

  /**
   * Play a video cutscene.
   * TODO: Currently this is hardcoded to start the countdown after the video is done.
   * @param path The path to the video file. Use Paths.file(path) to get the correct path.
   * @param cutseneType The type of cutscene to play, determines what the game does after. Defaults to `CutsceneType.STARTING`.
   */
  public static function play(filePath:String, ?cutsceneType:CutsceneType = STARTING):Void
  {
    if (PlayState.instance == null) return;

    if (!openfl.Assets.exists(filePath))
    {
      // Display a popup.
      // lime.app.Application.current.window.alert('Video file does not exist: ${filePath}', 'Error playing video');
      // return;

      // TODO: After moving videos to their own library,
      // this function ALWAYS FAILS on web, but the video still plays.
      // I think that's due to a weird quirk with how OpenFL libraries work.
      trace('Video file does not exist: ${filePath}');
    }

    var rawFilePath = Paths.stripLibrary(filePath);

    // Trigger the cutscene. Don't play the song in the background.
    PlayState.instance.isInCutscene = true;
    PlayState.instance.camHUD.visible = false;

    // Display a black screen to hide the game while the video is playing.
    blackScreen = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
    blackScreen.scrollFactor.set(0, 0);
    blackScreen.cameras = [PlayState.instance.camCutscene];
    PlayState.instance.add(blackScreen);

    VideoCutscene.cutsceneType = cutsceneType;

    #if mobile
    if (cutsceneType == ENDING)
    {
      PlayState.instance.togglePauseButton();
    }
    #end

    #if html5
    playVideoHTML5(rawFilePath);
    #elseif hxvlc
    playVideoNative(filePath);
    #else
    throw "No video support for this platform!";
    #end
  }

  public static function isPlaying():Bool
  {
    #if (html5 || hxvlc)
    return vid != null;
    #else
    return false;
    #end
  }

  #if html5
  static function playVideoHTML5(filePath:String):Void
  {
    // Video displays OVER the FlxState.
    vid = new FlxVideo(filePath);
    if (vid != null)
    {
      vid.zIndex = 0;

      vid.finishCallback = finishVideo.bind(0.5);

      vid.cameras = [PlayState.instance.camCutscene];

      PlayState.instance.add(vid);

      PlayState.instance.refresh();

      onVideoStarted.dispatch();
    }
    else
    {
      trace('ALERT: Video is null! Could not play cutscene!');
    }
  }
  #end

  #if hxvlc
  static function playVideoNative(filePath:String):Void
  {
    // Video displays OVER the FlxState.
    vid = new FunkinVideoSprite(0, 0);

    if (vid != null)
    {
      vid.zIndex = 0;
      vid.active = false;
      vid.bitmap.onEncounteredError.add(function(msg:String):Void {
        trace('[VLC] Encountered an error: $msg');

        finishVideo(0.5);
      });
      vid.bitmap.onEndReached.add(finishVideo.bind(0.5));

      vid.cameras = [PlayState.instance.camCutscene];

      PlayState.instance.add(vid);

      PlayState.instance.refresh();

      if (vid.load(filePath)) vid.play();

      // Resize videos bigger or smaller than the screen.
      vid.bitmap.onFormatSetup.add(function():Void {
        if (vid == null) return;
        vid.setGraphicSize(FlxG.initialWidth, FlxG.initialHeight);
        vid.updateHitbox();
        vid.screenCenter();
        // vid.scale.set(0.5, 0.5);
      });

      onVideoStarted.dispatch();
    }
    else
    {
      trace('ALERT: Video is null! Could not play cutscene!');
    }
  }
  #end

  public static function restartVideo():Void
  {
    #if html5
    if (vid != null)
    {
      vid.restartVideo();
      onVideoRestarted.dispatch();
    }
    #end

    #if hxvlc
    if (vid != null)
    {
      vid.bitmap.time = 0;
      vid.resume();
      onVideoRestarted.dispatch();
    }
    #end
  }

  public static function pauseVideo():Void
  {
    #if html5
    if (vid != null)
    {
      vid.pauseVideo();
      onVideoPaused.dispatch();
    }
    #end

    #if hxvlc
    if (vid != null)
    {
      vid.pause();
      onVideoPaused.dispatch();
    }
    #end
  }

  public static function hideVideo():Void
  {
    #if html5
    if (vid != null)
    {
      vid.visible = false;
      blackScreen.visible = false;
    }
    #end

    #if hxvlc
    if (vid != null)
    {
      vid.visible = false;
      blackScreen.visible = false;
    }
    #end
  }

  public static function showVideo():Void
  {
    #if html5
    if (vid != null)
    {
      vid.visible = true;
      blackScreen.visible = false;
    }
    #end

    #if hxvlc
    if (vid != null)
    {
      vid.visible = true;
      blackScreen.visible = false;
    }
    #end
  }

  public static function resumeVideo():Void
  {
    #if html5
    if (vid != null)
    {
      vid.resumeVideo();
      onVideoResumed.dispatch();
    }
    #end

    #if hxvlc
    if (vid != null)
    {
      vid.resume();
      onVideoResumed.dispatch();
    }
    #end
  }

  /**
   * Finish the active video cutscene. Done when the video is finished or when the player skips the cutscene.
   * @param transitionTime The duration of the transition to the next state. Defaults to 0.5 seconds (this time is always used when cancelling the video).
   * @param finishCutscene The callback to call when the transition is finished.
   */
  public static function finishVideo(?transitionTime:Float = 0.5):Void
  {
    trace('ALERT: Finish video cutscene called!');

    var cutsceneType:CutsceneType = VideoCutscene.cutsceneType;

    #if html5
    if (vid != null)
    {
      PlayState.instance.remove(vid);
    }
    #end

    #if hxvlc
    if (vid != null)
    {
      vid.stop();
      PlayState.instance.remove(vid);
    }
    #end

    #if (html5 || hxvlc)
    vid.destroy();
    vid = null;
    #end

    PlayState.instance.camHUD.visible = true;

    FlxTween.tween(blackScreen, {alpha: 0}, transitionTime,
      {
        ease: FlxEase.quadInOut,
        onComplete: function(twn:FlxTween) {
          PlayState.instance.remove(blackScreen);
          blackScreen = null;
        }
      });
    FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.stageZoom}, transitionTime,
      {
        ease: FlxEase.quadInOut,
        onComplete: function(twn:FlxTween) {
          onVideoEnded.dispatch();
          onCutsceneFinish(cutsceneType);
        }
      });
  }

  /**
   * The default callback used when a cutscene is finished.
   * You can specify your own callback when calling `VideoCutscene#play()`.
   */
  static function onCutsceneFinish(cutsceneType:CutsceneType):Void
  {
    switch (cutsceneType)
    {
      case CutsceneType.STARTING:
        PlayState.instance.startCountdown();
      case CutsceneType.ENDING:
        PlayState.instance.endSong(true); // true = right goddamn now
      case CutsceneType.MIDSONG:
        // Do nothing.
        // throw "Not implemented!";
    }
  }
}

enum CutsceneType
{
  STARTING; // The default cutscene type. Starts the countdown after the video is done.
  MIDSONG; // Does nothing.
  ENDING; // Ends the song after the video is done.
}
