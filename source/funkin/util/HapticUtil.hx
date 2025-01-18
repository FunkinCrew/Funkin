package funkin.util;

import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import funkin.haptic.Haptic;

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
   *
   * @param period The time for one complete vibration in seconds.
   * @param duration The time taken for a complete cycle in seconds.
   * @param amplitude The intensity of the vibration (0.0 to 1.0).
   */
  public static function vibrate(period:Float = Constants.DEFAULT_VIBRATION_PERIOD, duration:Float = Constants.DEFAULT_VIBRATION_DURATION,
      amplitude:Float = Constants.DEFAULT_VIBRATION_AMPLITUDE):Void
  {
    if (!Preferences.vibration) return;

    #if ios
    final amplitudeValue = FlxMath.bound(amplitude * 2.5, 0, Constants.MAX_VIBRATION_AMPLITUDE);
    #else
    final amplitudeValue = amplitude;
    #end

    if (period > 0)
    {
      final durations:Array<Float> = [];
      final amplitudes:Array<Float> = [];
      final sharpnesses:Array<Float> = [];

      final durationPeriod:Float = period / 2;

      for (i in 0...Math.ceil(duration / durationPeriod))
      {
        durations[i] = durationPeriod;
        amplitudes[i] = amplitudeValue;
        sharpnesses[i] = (durationPeriod < 0.1) ? 1 : 0;
      }

      Haptic.vibratePattern(durations, amplitudes, sharpnesses);
    }
    else
    {
      final sharpness:Float = (duration < 0.1) ? 1 : 0;
      Haptic.vibrateOneShot(duration, amplitudeValue, sharpness);
    }
  }

  /**
   * Triggers vibration using a preset.
   *
   * @param vibrationPreset Vibration's data.
   */
  public static function vibrateByPreset(vibrationPreset:VibrationPreset = null):Void
  {
    if (!Preferences.vibration) return;

    final preset:VibrationPreset = (vibrationPreset != null) ? vibrationPreset : defaultVibrationPreset;

    vibrate(preset.period, preset.duration, preset.amplitude);
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
          final finalAmplitude:Float = targetAmplitude * 2;

          vibrate(Constants.DEFAULT_VIBRATION_PERIOD, Constants.DEFAULT_VIBRATION_DURATION, finalAmplitude);
        }
      }, function(currentAmplitude:Float) {
        vibrate(0, Constants.DEFAULT_VIBRATION_DURATION / 10, currentAmplitude);
      });
  }

  static function get_defaultVibrationPreset():VibrationPreset
  {
    return {period: Constants.DEFAULT_VIBRATION_PERIOD, duration: Constants.DEFAULT_VIBRATION_DURATION, amplitude: Constants.DEFAULT_VIBRATION_AMPLITUDE};
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
  var period:Float;

  /**
   * The time taken for a complete cycle.
   */
  var duration:Float;

  /**
   * The distance of movement of the wave from its original position.
   */
  var amplitude:Float;
}
