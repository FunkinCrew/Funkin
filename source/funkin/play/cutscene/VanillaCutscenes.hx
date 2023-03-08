package funkin.play.cutscene;

// import hxcodec.flixel.FlxVideoSprite;
// import hxcodec.flixel.FlxCutsceneState;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.graphics.video.FlxVideo;

/**
 * Static methods for playing cutscenes in the PlayState.
 * TODO: Un-hardcode this shit!!!!!1!
 */
class VanillaCutscenes
{
  /**
   * Well, well, well, what have we got here?
   */
  public static function playUghCutscene():Void
  {
    playVideoCutscene('music/ughCutscene.mp4');
  }

  /**
   * Nice bars for an ugly, boring teenager!
   */
  public static function playGunsCutscene():Void
  {
    playVideoCutscene('music/gunsCutscene.mp4');
  }

  /**
   * Don't you have a school to shoot up?
   */
  public static function playStressCutscene():Void
  {
    playVideoCutscene('music/stressCutscene.mp4');
  }

  static var blackScreen:FlxSprite;

  /**
   * Plays a cutscene from a video file, then starts the countdown once the video is done.
   * TODO: Cutscene is currently skipped on native platforms.
   */
  static function playVideoCutscene(path:String):Void
  {
    // Tell PlayState to stop the song until the video is done.
    PlayState.isInCutscene = true;
    PlayState.instance.camHUD.visible = false;

    // Display a black screen to hide the game while the video is playing.
    blackScreen = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
    blackScreen.scrollFactor.set(0, 0);
    blackScreen.cameras = [PlayState.instance.camCutscene];
    PlayState.instance.add(blackScreen);

    #if html5
    // Video displays OVER the FlxState.
    vid = new FlxVideo(path);
    vid.finishCallback = finishCutscene.bind(0.5);
    #else
    // Video displays OVER the FlxState.
    // vid = new FlxVideoSprite(0, 0);

    vid.cameras = [PlayState.instance.camCutscene];

    PlayState.instance.add(vid);

    vid.playVideo(Paths.file(path), false);
    vid.onEndReached.add(finishCutscene.bind(0.5));
    #end
  }

  static var vid:#if html5 FlxVideo #else Dynamic /**FlxVideoSprite **/ #end;

  /**
   * Does the cleanup to start the countdown after the video is done.
   * Gets called immediately if the video can't be played.
   */
  public static function finishCutscene(?transitionTime:Float = 2.5):Void
  {
    trace('ALERT: Finish cutscene called!');

    #if html5
    #else
    vid.stop();
    PlayState.instance.remove(vid);
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
    FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCameraZoom}, transitionTime,
      {
        ease: FlxEase.quadInOut,
        onComplete: function(twn:FlxTween) {
          PlayState.instance.startCountdown();
        }
      });
  }

  /**
   * FNF corruption mod???
   */
  public static function playHorrorStartCutscene():Void
  {
    PlayState.isInCutscene = true;
    PlayState.instance.camHUD.visible = false;

    blackScreen = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
    blackScreen.scrollFactor.set(0, 0);
    PlayState.instance.add(blackScreen);

    new FlxTimer().start(0.1, _ -> finishCutscene(2.5));
  }
}
