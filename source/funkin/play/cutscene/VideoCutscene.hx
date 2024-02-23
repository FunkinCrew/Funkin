package funkin.play.cutscene;

import funkin.play.PlayState;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
#if html5
import funkin.graphics.video.FlxVideo;
#end
#if hxCodec
import hxcodec.flixel.FlxVideoSprite;
#end

/**
 * Assumes you are in the PlayState.
 */
class VideoCutscene
{
  static var blackScreen:FlxSprite;

  /**
   * Play a video cutscene.
   * TODO: Currently this is hardcoded to start the countdown after the video is done.
   * @param path The path to the video file. Use Paths.file(path) to get the correct path.
   */
  public static function play(filePath:String):Void
  {
    if (PlayState.instance == null) return;

    if (!openfl.Assets.exists(filePath))
    {
      // Display a popup.
      lime.app.Application.current.window.alert('Video file does not exist: ${filePath}', 'Error playing video');
      return;
    }

    var rawFilePath = Paths.stripLibrary(filePath);

    // Trigger the cutscene. Don't play the song in the background.
    PlayState.instance.isInCutscene = true;
    PlayState.instance.camHUD.visible = false;
    PlayState.instance.camCutscene.visible = true;

    // Display a black screen to hide the game while the video is playing.
    blackScreen = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
    blackScreen.scrollFactor.set(0, 0);
    blackScreen.cameras = [PlayState.instance.camCutscene];
    PlayState.instance.add(blackScreen);

    #if html5
    playVideoHTML5(filePath);
    #elseif hxCodec
    playVideoNative(rawFilePath);
    #else
    throw "No video support for this platform!";
    #end
  }

  public static function isPlaying():Bool
  {
    #if (html5 || hxCodec)
    return vid != null;
    #else
    return false;
    #end
  }

  #if html5
  static var vid:FlxVideo;

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
    }
    else
    {
      trace('ALERT: Video is null! Could not play cutscene!');
    }
  }
  #end

  #if hxCodec
  static var vid:FlxVideoSprite;

  static function playVideoNative(filePath:String):Void
  {
    // Video displays OVER the FlxState.
    vid = new FlxVideoSprite(0, 0);

    if (vid != null)
    {
      vid.zIndex = 0;
      vid.bitmap.onEndReached.add(finishVideo.bind(0.5));

      vid.cameras = [PlayState.instance.camCutscene];

      PlayState.instance.add(vid);

      PlayState.instance.refresh();
      vid.play(filePath, false);

      // Resize videos bigger or smaller than the screen.
      vid.bitmap.onTextureSetup.add(() -> {
        vid.setGraphicSize(FlxG.width, FlxG.height);
        vid.updateHitbox();
        vid.x = 0;
        vid.y = 0;
        // vid.scale.set(0.5, 0.5);
      });
    }
    else
    {
      trace('ALERT: Video is null! Could not play cutscene!');
    }
  }
  #end

  public static function finishVideo(?transitionTime:Float = 0.5):Void
  {
    trace('ALERT: Finish video cutscene called!');

    #if html5
    if (vid != null)
    {
      PlayState.instance.remove(vid);
    }
    #end

    #if hxCodec
    if (vid != null)
    {
      vid.stop();
      PlayState.instance.remove(vid);
    }
    #end

    #if (html5 || hxCodec)
    vid.destroy();
    vid = null;
    #end

    PlayState.instance.camCutscene.visible = true;
    PlayState.instance.camHUD.visible = true;

    FlxTween.tween(blackScreen, {alpha: 0}, transitionTime,
      {
        ease: FlxEase.quadInOut,
        onComplete: function(twn:FlxTween) {
          PlayState.instance.remove(blackScreen);
          blackScreen = null;
        }
      });
    FlxTween.tween(FlxG.camera, {zoom: PlayState.instance.defaultCameraZoom}, transitionTime,
      {
        ease: FlxEase.quadInOut,
        onComplete: function(twn:FlxTween) {
          PlayState.instance.startCountdown();
        }
      });
  }
}
