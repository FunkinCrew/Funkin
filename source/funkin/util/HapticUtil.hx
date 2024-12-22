package funkin.util;

import lime.ui.Haptic;
import flixel.tweens.FlxTween;

/**
 * Utility class for extra vibration functions.
 */
class HapticUtil
{
  /**
   * Tween that is used in increasingVibrate function for tweening vibration amplitude.
   */
  public static var amplitudeTween:FlxTween;

  /**
   * Triggers vibration.
   * @param period The time for one complete vibration.
   * @param duration The time taken for a complete cycle.
   * @param amplitude The distance of movement of the wave from its original position.
   */
  public static inline function vibrate(period:Int = Constants.DEFAULT_VIBRATION_PERIOD, duration:Int = Constants.DEFAULT_VIBRATION_DURATION,
      amplitude:Int = 0):Void
  {
    if (!Preferences.vibration) return;

    Haptic.vibrate(period, duration, amplitude);
  }

  /**
   * Triggers a queue of small vibrations with increasing amplitude.
   * When the amplitudeTween is finished, triggers a single strong vibration.
   * @param startAmplitude Start amplitude value.
   * @param targetAmplitude Target amplitude value.
   * @param tweenDuration Duration of the tween.
   */
  public static function increasingVibrate(startAmplitude:Float, targetAmplitude:Float, tweenDuration:Float = 1):Void
  {
    if (!Preferences.vibration) return;

    if (amplitudeTween != null) amplitudeTween.cancel();

    amplitudeTween = FlxTween.num(startAmplitude, targetAmplitude, tweenDuration,
      {
        onComplete: function(_) {
          final lastAmplitude:Int = Math.floor(targetAmplitude * 2);
          vibrate(Constants.DEFAULT_VIBRATION_PERIOD, Constants.DEFAULT_VIBRATION_DURATION, lastAmplitude);
        }
      }, function(currentAmplitude:Float) {
        vibrate(0, Math.floor(Constants.DEFAULT_VIBRATION_DURATION / 10), Math.floor(currentAmplitude));
      });
  }
}
