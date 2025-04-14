package funkin.mobile.util;

import lime.ui.Haptic;
import flixel.tweens.FlxTween;

/**
 * Utility class for extra vibration functions.
 */
@:nullSafety
class HapticUtil
{
  /**
   * Tween that is used in increasingVibrate function for tweening vibration amplitude.
   */
  public static var amplitudeTween:Null<FlxTween>;

  /**
   * Triggers vibration.
   * @param period The time for one complete vibration.
   * @param duration The time taken for a complete cycle.
   * @param amplitude The distance of movement of the wave from its original position.
   */
  public static function vibrate(period:Int = Constants.DEFAULT_VIBRATION_PERIOD, duration:Int = Constants.DEFAULT_VIBRATION_DURATION, amplitude:Int = 0):Void
  {
    #if HAPTIC_VIBRATIONS
    if (!Preferences.vibration) return;

    Haptic.vibrate(period, duration, amplitude);
    #end

    return;
  }

  /**
   * Triggers a queue of small vibrations with increasing amplitude.
   * When the amplitudeTween is finished, triggers a single strong vibration.
   * @param fromValue Start amplitude value.
   * @param toValue End amplitude value.
   * @param duration Duration of the tween.
   */
  public static function increasingVibrate(fromValue:Float, toValue:Float, duration:Float = 1):Void
  {
    #if HAPTIC_VIBRATIONS
    if (!Preferences.vibration) return;

    amplitudeTween = FlxTween.num(fromValue, toValue, duration,
      {
        onComplete: function(_) {
          vibrate(Constants.DEFAULT_VIBRATION_PERIOD, Constants.DEFAULT_VIBRATION_DURATION, Std.int(toValue * 2));
        }
      }, function(num) {
        vibrate(0, Std.int(Constants.DEFAULT_VIBRATION_DURATION / 10), Std.int(num));
      });
    #end

    return;
  }
}
