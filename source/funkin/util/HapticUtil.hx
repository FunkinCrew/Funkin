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
   * A default vibration preset.
   */
  public static var defaultVibrationPreset(get, never):VibrationPreset;

  /**
   * Triggers vibration.
   * If there is any gamepad connected it tries to trigger SDL's rumble on all of the gamepads.
   * If there is no any gamepad connected it triggers lime's vibration.
   * @param period The time for one complete vibration.
   * @param duration The time taken for a complete cycle.
   * @param amplitude The distance of movement of the wave from its original position.
   */
  public static function vibrate(period:Int = Constants.DEFAULT_VIBRATION_PERIOD, duration:Int = Constants.DEFAULT_VIBRATION_DURATION, amplitude:Int = 0):Void
  {
    if (!Preferences.vibration) return;

    Haptic.vibrate(period, duration, amplitude);
  }

  /**
   * Triggers vibration using a preset.
   * If there is any gamepad connected it tries to trigger SDL's rumble on all of the gamepads.
   * If there is no any gamepad connected it triggers lime's vibration.
   * @param vibrationPreset Vibration's data.
   */
  public static function vibrateByPreset(vibrationPreset:VibrationPreset = null):Void
  {
    if (!Preferences.vibration) return;

    var preset:VibrationPreset = defaultVibrationPreset;

    if (vibrationPreset != null) preset = vibrationPreset;

    Haptic.vibrate(preset.period, preset.duration, preset.amplitude);
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
          final finalAmplitude:Int = Math.floor(targetAmplitude * 2);

          vibrate(Constants.DEFAULT_VIBRATION_PERIOD, Constants.DEFAULT_VIBRATION_DURATION, finalAmplitude);
        }
      }, function(currentAmplitude:Float) {
        vibrate(0, Math.floor(Constants.DEFAULT_VIBRATION_DURATION / 10), Math.floor(currentAmplitude));
      });
  }

  static function get_defaultVibrationPreset():VibrationPreset
  {
    var preset:VibrationPreset = {period: Constants.DEFAULT_VIBRATION_PERIOD, duration: Constants.DEFAULT_VIBRATION_DURATION, amplitude: 0};
    return preset;
  }
}

/**
 * A typedef containing data needed for vibrate function call.
 */
typedef VibrationPreset =
{
  /**
   * The time for one complete vibration.
   */
  var period:Int;

  /**
   * The time taken for a complete cycle.
   */
  var duration:Int;

  /**
   * The distance of movement of the wave from its original position.
   */
  var amplitude:Int;
}
