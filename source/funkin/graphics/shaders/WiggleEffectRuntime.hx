package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;
import openfl.Assets;

enum WiggleEffectType
{
  DREAMY; // 0
  WAVY; // 1
  HEAT_WAVE_HORIZONTAL; // 2
  HEAT_WAVE_VERTICAL; // 3
  FLAG; // 4
}

/**
 * To use:
 * 1. Create an instance of the class, specifying speed, frequency, and amplitude.
 * 2. Call `sprite.shader = wiggleEffect` on the target sprite.
 * 3. Call the update() method on the instance every frame.
 */
@:nullSafety
class WiggleEffectRuntime extends FlxRuntimeShader
{
  public static function getEffectTypeId(v:Null<WiggleEffectType>):Int
  {
    return WiggleEffectType.getConstructors().indexOf(Std.string(v));
  }

  public var effectType(default, set):Null<WiggleEffectType> = DREAMY;

  function set_effectType(v:Null<WiggleEffectType>):Null<WiggleEffectType>
  {
    this.setInt('effectType', getEffectTypeId(v));
    return effectType = v;
  }

  public var waveSpeed(default, set):Float = 0;

  function set_waveSpeed(v:Float):Float
  {
    this.setFloat('uSpeed', v);
    return waveSpeed = v;
  }

  public var waveFrequency(default, set):Float = 0;

  function set_waveFrequency(v:Float):Float
  {
    this.setFloat('uFrequency', v);
    return waveFrequency = v;
  }

  public var waveAmplitude(default, set):Float = 0;

  function set_waveAmplitude(v:Float):Float
  {
    this.setFloat('uWaveAmplitude', v);
    return waveAmplitude = v;
  }

  var time(default, set):Float = 0;

  function set_time(v:Float):Float
  {
    this.setFloat('uTime', v);
    return time = v;
  }

  public function new(speed:Float, freq:Float, amplitude:Float, ?effect:WiggleEffectType = DREAMY):Void
  {
    super(Assets.getText(Paths.frag('wiggle')));

    // These values may not propagate to the shader until later.
    this.waveSpeed = speed;
    this.waveFrequency = freq;
    this.waveAmplitude = amplitude;
    this.effectType = effect;
  }

  public function update(elapsed:Float)
  {
    // The setter tied to this value automatically propagates the value to the shader.
    this.time += elapsed;
  }
}
