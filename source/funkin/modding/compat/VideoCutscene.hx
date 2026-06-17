package funkin.modding.compat;

import funkin.play.cutscene.VideoCutscene.CutsceneType;
import funkin.play.cutscene.VideoCutscene as OriginalVideoCutscene;
import flixel.FlxSprite;
import flixel.util.FlxSignal;
#if html5
import funkin.graphics.video.FlxVideo;
#end
#if hxvlc
import funkin.graphics.video.FunkinVideoSprite;
#end
//
// ~PATHS~
//
import funkin.assets.Paths.AssetPath;
import funkin.assets.ValidatedPaths as Paths;

@:access(funkin.play.cutscene.VideoCutscene)
class VideoCutscene
{
  #if hxvlc
  @:noCompletion
  static var DEFAULT_LANGUAGE(get, never):String;

  static function get_DEFAULT_LANGUAGE():String
  {
    return OriginalVideoCutscene.DEFAULT_LANGUAGE;
  }
  #end

  static var blackScreen(get, never):FlxSprite;

  static function get_blackScreen():FlxSprite
  {
    return OriginalVideoCutscene.blackScreen;
  }

  static var cutsceneType(get, never):CutsceneType;

  static function get_cutsceneType():CutsceneType
  {
    return OriginalVideoCutscene.cutsceneType;
  }

  #if html5
  static var vid(get, never):FlxVideo;

  static function get_vid():FlxVideo
  {
    return OriginalVideoCutscene.vid;
  }
  #end

  #if hxvlc
  static var vid(get, never):FunkinVideoSprite;

  static function get_vid():FunkinVideoSprite
  {
    return OriginalVideoCutscene.vid;
  }
  #end

  /**
   * Called when the video is started.
   */
  public static var onVideoStarted(get, never):FlxSignal;

  static function get_onVideoStarted():FlxSignal
  {
    return OriginalVideoCutscene.onVideoStarted;
  }

  /**
   * Called if the video is paused.
   */
  public static var onVideoPaused(get, never):FlxSignal;

  static function get_onVideoPaused():FlxSignal
  {
    return OriginalVideoCutscene.onVideoPaused;
  }

  /**
   * Called if the video is resumed.
   */
  public static var onVideoResumed(get, never):FlxSignal;

  static function get_onVideoResumed():FlxSignal
  {
    return OriginalVideoCutscene.onVideoResumed;
  }

  /**
   * Called if the video is restarted. onVideoStarted is not called.
   */
  public static var onVideoRestarted(get, never):FlxSignal;

  static function get_onVideoRestarted():FlxSignal
  {
    return OriginalVideoCutscene.onVideoRestarted;
  }

  /**
   * Called when the video is ended or skipped.
   */
  public static var onVideoEnded(get, never):FlxSignal;

  static function get_onVideoEnded():FlxSignal
  {
    return OriginalVideoCutscene.onVideoEnded;
  }

  /**
   * Play a video cutscene.
   * TODO: Currently this is hardcoded to start the countdown after the video is done.
   *
   * @param assetPath The path to the video file. Use Paths.file(path) to get the correct path.
   * @param cutseneType The type of cutscene to play, determines what the game does after. Defaults to `CutsceneType.STARTING`.
   */
  public static function play(assetPath:Dynamic,
    ?cutsceneType:CutsceneType = STARTING):Void
  {
    if (Std.isOfType(assetPath, AssetPath))
    {
      OriginalVideoCutscene.play(assetPath, cutsceneType);
    }
    else if (Std.isOfType(assetPath, String))
    {
      var rawPath:String = haxe.io.Path.withoutExtension(assetPath).replace('assets/', '');
      var videoPath:AssetPath = Paths.video(rawPath);

      trace('Playing video cutscene at ${videoPath.toString()}');

      // Paths.video() has its own compat.
      OriginalVideoCutscene.play(videoPath, cutsceneType);
    }
    else
    {
      OriginalVideoCutscene.play(null);
    }
  }

  /**
   * @return Whether a video cutscene is currently playing.
   */
  public static function isPlaying():Bool
  {
    return OriginalVideoCutscene.isPlaying();
  }

  /**
   * Restart the current video cutscene from the beginning.
   */
  public static function restartVideo():Void
  {
    OriginalVideoCutscene.restartVideo();
  }

  /**
   * Pause the current video cutscene.
   */
  public static function pauseVideo():Void
  {
    OriginalVideoCutscene.pauseVideo();
  }

  /**
   * Hide the current video cutscene.
   */
  public static function hideVideo():Void
  {
    OriginalVideoCutscene.hideVideo();
  }

  /**
   * Show the current video cutscene, if it is hidden.
   */
  public static function showVideo():Void
  {
    OriginalVideoCutscene.showVideo();
  }

  /**
   * Resume the current video cutscene, if it is paused.
   */
  public static function resumeVideo():Void
  {
    OriginalVideoCutscene.resumeVideo();
  }

  /**
   * Finish the active video cutscene. Done when the video is finished or when the player skips the cutscene.
   * @param transitionTime The duration of the transition to the next state. Defaults to 0.5 seconds (this time is always used when cancelling the video).
   * @param finishCutscene The callback to call when the transition is finished.
   */
  public static function finishVideo(?transitionTime:Float = 0.5):Void
  {
    OriginalVideoCutscene.finishVideo(transitionTime);
  }

  /**
   * Destroy the active cutscene, if any. Separate from finishVideo() so that it doesn't trigger onCutsceneFinish().
   */
  public static function destroyVideo():Void
  {
    OriginalVideoCutscene.destroyVideo();
  }
}
