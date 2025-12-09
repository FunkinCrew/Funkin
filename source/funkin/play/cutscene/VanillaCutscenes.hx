package funkin.play.cutscene;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.audio.FunkinSound;
import flixel.util.FlxTimer;
import funkin.util.HapticUtil;

/**
 * Static methods for playing cutscenes in the PlayState.
 * TODO: Un-hardcode this shit!!!!!1!
 */
class VanillaCutscenes
{
  static var blackScreen:FlxSprite;

  static final TWEEN_DURATION:Float = 2.0;

  /**
   * Plays the cutscene that appears at the start of Winter Horrorland.
   * TODO: Move this to `winter-horrorland.hxc`
   */
  public static function playHorrorStartCutscene():Void
  {
    PlayState.instance.isInCutscene = true;
    PlayState.instance.camHUD.visible = false;

    blackScreen = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
    blackScreen.scrollFactor.set(0, 0);
    blackScreen.zIndex = 1000000;
    PlayState.instance.add(blackScreen);

    new FlxTimer().start(0.1, function(_) {
      trace('Playing horrorland cutscene...');
      PlayState.instance.remove(blackScreen);

      // Force set the camera position and zoom.
      PlayState.instance.cameraFollowPoint.setPosition(400, -2050);
      PlayState.instance.resetCamera();
      FlxG.camera.zoom = 2.5;

      // Play the Sound effect.
      HapticUtil.vibrate(0.1, 0.5, 1, 1);
      FunkinSound.playOnce(Paths.sound('Lights_Turn_On'), function() {
        // Fade in the HUD.
        trace('SFX done...');
        PlayState.instance.camHUD.visible = true;
        PlayState.instance.camHUD.alpha = 0.0; // Use alpha rather than visible to let us fade it in.
        FlxTween.tween(PlayState.instance.camHUD, {alpha: 1.0}, TWEEN_DURATION, {ease: FlxEase.quadInOut});

        // Start the countdown.
        trace('Zoom out done...');
        trace('Begin countdown (ends cutscene)');
        PlayState.instance.startCountdown();
      });
    });
  }
}
