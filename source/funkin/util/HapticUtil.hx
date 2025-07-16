package funkin.util;

import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
#if FEATURE_HAPTICS
import extension.haptics.Haptic;
#end

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
   * Indicates if haptics are available.
   */
  public static var hapticsAvailable(get, never):Bool;

  /**
   * Triggers vibration.
   *
   * @param period The time for one complete vibration in seconds.
   * @param duration The time taken for a complete cycle in seconds.
   * @param amplitude The intensity of the vibration (0.0 to 1.0).
   * @param sharpness Controls the feel of vibration.
   */
  public static function vibrate(period:Float = Constants.DEFAULT_VIBRATION_PERIOD, duration:Float = Constants.DEFAULT_VIBRATION_DURATION,
      amplitude:Float = Constants.DEFAULT_VIBRATION_AMPLITUDE, sharpness:Float = Constants.DEFAULT_VIBRATION_SHARPNESS,
      ?targetHapticsModes:Array<HapticsMode>):Void
  {
    #if FEATURE_HAPTICS
    if (!HapticUtil.hapticsAvailable) return;

    final hapticsModes:Array<HapticsMode> = targetHapticsModes ?? [HapticsMode.ALL];
    if (!hapticsModes.contains(Preferences.hapticsMode)) return;

    final amplitudeValue = FlxMath.bound(amplitude * Preferences.hapticsIntensityMultiplier, 0, Constants.MAX_VIBRATION_AMPLITUDE);

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
        sharpnesses[i] = sharpness;
      }

      Haptic.vibratePattern(durations, amplitudes, sharpnesses);
    }
    else
    {
      Haptic.vibrateOneShot(duration, amplitudeValue, sharpness);
    }
    #end
  }

  /**
   * Triggers vibration using a preset.
   *
   * @param vibrationPreset Vibration's data.
   */
  public static function vibrateByPreset(vibrationPreset:VibrationPreset = null):Void
  {
    if (!HapticUtil.hapticsAvailable) return;

    final preset:VibrationPreset = (vibrationPreset != null) ? vibrationPreset : defaultVibrationPreset;

    vibrate(preset.period, preset.duration, preset.amplitude, preset.sharpness);
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
    if (!HapticUtil.hapticsAvailable) return;

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
    return {
      period: Constants.DEFAULT_VIBRATION_PERIOD,
      duration: Constants.DEFAULT_VIBRATION_DURATION,
      amplitude: Constants.DEFAULT_VIBRATION_AMPLITUDE,
      sharpness: Constants.DEFAULT_VIBRATION_SHARPNESS
    };
  }

  static function get_hapticsAvailable():Bool
  {
    #if FEATURE_HAPTICS
    if (Preferences.hapticsMode != HapticsMode.NONE) return true;
    #end

    return false;
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

  /**
   * Controls the feel of vibration.
   */
  var sharpness:Float;
}

/**
 * An abstract for vibrations preference.
 */
enum abstract HapticsMode(Int) from Int to Int
{
  /**
   * Haptics are completely disabled.
   */
  var NONE:Int = 0;

  /**
   * Only note haptics are enabled.
   */
  var NOTES_ONLY:Int = 1;

  /**
   * All the haptics are enabled.
   */
  var ALL:Int = 2;
}
