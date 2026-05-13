package funkin.play.cutscene;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import funkin.play.PlayState;
import funkin.graphics.FunkinSprite;
#if html5
import funkin.graphics.video.FlxVideo;
#end
#if hxvlc
import funkin.graphics.video.FunkinVideoSprite;
#end
//
// ~PATHS~
//
import funkin.assets.Assets as Assets;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Paths.AnimateAtlasAssetPathBuilder;
import funkin.assets.Paths.MusicAssetPathBuilder;
import funkin.assets.ValidatedPaths as Paths;

/**
 * Assumes you are in the PlayState.
 */
class VideoCutscene
{
  #if hxvlc
  @:noCompletion
  static final DEFAULT_LANGUAGE:String = 'English';
  #end
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
  public static var onVideoStarted:FlxSignal = new FlxSignal();

  /**
   * Called if the video is paused.
   */
  public static var onVideoPaused:FlxSignal = new FlxSignal();

  /**
   * Called if the video is resumed.
   */
  public static var onVideoResumed:FlxSignal = new FlxSignal();

  /**
   * Called if the video is restarted. onVideoStarted is not called.
   */
  public static var onVideoRestarted:FlxSignal = new FlxSignal();

  /**
   * Called when the video is ended or skipped.
   */
  public static var onVideoEnded:FlxSignal = new FlxSignal();

  /**
   * Play a video cutscene.
   * TODO: Currently this is hardcoded to start the countdown after the video is done.
   *
   * @param assetPath The path to the video file. Use Paths.file(path) to get the correct path.
   * @param cutseneType The type of cutscene to play, determines what the game does after. Defaults to `CutsceneType.STARTING`.
   */
  public static function play(assetPath:AssetPath, ?cutsceneType:CutsceneType = STARTING):Void
  {
    if (PlayState.instance == null) return;

    if (assetPath == null) throw 'Input is not a valid AssetPath, did you call Paths.video()?';

    #if FEATURE_VIDEO_PLAYBACK
    if (!assetPath.exists())
    {
      // Display a popup.
      funkin.util.WindowUtil.showError('Error playing video', 'Video file does not exist: ${assetPath.toString()}');
      trace('Video file does not exist: ${assetPath.toString()}');

      return;
    }
    else
    {
      trace('Video file available for playback: ${assetPath.toString()}');
    }
    #end

    // Trigger the cutscene. Don't play the song in the background.
    PlayState.instance.isInCutscene = true;
    PlayState.instance.camHUD.visible = false;

    // Display a black screen to hide the game while the video is playing.
    blackScreen = new FunkinSprite(-200, -200).makeSolidColor(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
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

    #if NO_FEATURE_VIDEO_PLAYBACK
    trace(' WARNING '.warning() + ' Video playback is not enabled. Calling video end callback instead.');
    finishVideo();
    #else
    #if html5
    playVideoHTML5(assetPath);
    #elseif hxvlc
    playVideoNative(assetPath);
    #else
    throw 'No video support for this platform!';
    #end
    #end
  }

  /**
   * @return Whether a video cutscene is currently playing.
   */
  public static function isPlaying():Bool
  {
    #if (html5 || hxvlc)
    return vid != null;
    #else
    return false;
    #end
  }

  #if html5
  static function playVideoHTML5(assetPath:AssetPath):Void
  {
    // Video displays OVER the FlxState.
    vid = new FlxVideo(assetPath.toString());

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
  static function playVideoNative(assetPath:AssetPath):Void
  {
    // Video displays OVER the FlxState.
    vid = new FunkinVideoSprite(0, 0);

    if (vid != null)
    {
      vid.zIndex = 0;

      vid.active = false;

      vid.bitmap.onFormatSetup.add(function():Void
      {
        if (vid.bitmap != null && vid.bitmap.bitmapData != null)
        {
          final scale:Float = Math.min(FlxG.width / vid.bitmap.bitmapData.width, FlxG.height / vid.bitmap.bitmapData.height);

          vid.setGraphicSize(vid.bitmap.bitmapData.width * scale, vid.bitmap.bitmapData.height * scale);
          vid.updateHitbox();
          vid.screenCenter();
        }
      });

      vid.bitmap.onEncounteredError.add(function(msg:String):Void
      {
        finishVideo(0.5);
      });

      vid.bitmap.onEndReached.add(finishVideo.bind(0.5));

      vid.cameras = [PlayState.instance.camCutscene];

      PlayState.instance.add(vid);

      PlayState.instance.refresh();

      final fileOptions:Array<String> = [];

      #if FEATURE_VIDEO_SUBTITLES
      if (Preferences.subtitles)
      {
        fileOptions.push(':sub-language=$DEFAULT_LANGUAGE');
      }
      else
      {
        fileOptions.push(':sub-language=none');
      }

      fileOptions.push(':audio-language=$DEFAULT_LANGUAGE');
      #end

      if (vid.load(assetPath.toString(), fileOptions) && vid.play())
      {
        onVideoStarted.dispatch();
      }
    }
    else
    {
      trace('ALERT: Video is null! Could not play cutscene!');
    }
  }
  #end

  /**
   * Restart the current video cutscene from the beginning.
   */
  public static function restartVideo():Void
  {
    #if html5
    if (vid != null)
    {
      vid.restartVideo();
      vid.resumeVideo();
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

  /**
   * Pause the current video cutscene.
   */
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

  /**
   * Hide the current video cutscene.
   */
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

  /**
   * Show the current video cutscene, if it is hidden.
   */
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

  /**
   * Resume the current video cutscene, if it is paused.
   */
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

    var currentCutsceneType:CutsceneType = VideoCutscene.cutsceneType;

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

    FlxTween.tween(blackScreen, {alpha: 0}, transitionTime, {
      ease: FlxEase.quadInOut,
      onComplete: (twn:FlxTween) ->
      {
        PlayState.instance.remove(blackScreen);
        blackScreen = null;
      }
    });
    FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.stageZoom}, transitionTime, {
      ease: FlxEase.quadInOut,
      onComplete: (twn:FlxTween) ->
      {
        onVideoEnded.dispatch();
        onCutsceneFinish(currentCutsceneType);
      }
    });
  }

  /**
   * The default callback used when a cutscene is finished.
   * You can specify your own callback when calling `VideoCutscene#play()`.
   */
  static function onCutsceneFinish(currentCutsceneType:CutsceneType):Void
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

  /**
   * Destroy the active cutscene, if any. Separate from finishVideo() so that it doesn't trigger onCutsceneFinish().
   */
  public static function destroyVideo():Void
  {
    #if html5
    if (vid != null) PlayState.instance.remove(vid);
    #end

    #if hxvlc
    if (vid != null)
    {
      vid.stop();
      PlayState.instance.remove(vid);
    }
    #end

    #if (html5 || hxvlc)
    if (vid != null)
    {
      vid?.destroy();
      vid = null;
    }
    #end

    if (blackScreen != null)
    {
      PlayState.instance.remove(blackScreen);
      blackScreen = null;
    }
  }
}

/**
 * The different types of cutscenes, determines how the game behaves when the video is finished.
 */
enum CutsceneType
{
  STARTING; // The default cutscene type. Starts the countdown after the video is done.
  MIDSONG; // Does nothing.
  ENDING; // Ends the song after the video is done.
}
