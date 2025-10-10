package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;

/**
 * Adds a pulsing glow effect.
 */
@:nullSafety
class GlowPulseShader extends FlxRuntimeShader
{
  public var amount(default, set):Float = 0;

  function set_amount(v:Float):Float
  {
    this.setFloat('uAmount', v);
    return amount = v;
  }

  public var duration(default, set):Float = 1.5;

  function set_duration(v:Float):Float
  {
    this.setFloat('uDuration', v);
    return duration = v;
  }

  var time(default, set):Float = 0;

  function set_time(v:Float):Float
  {
    this.setFloat('uTime', v);
    return time = v;
  }

  public function new(amount:Float, duration:Float)
  {
    super(Assets.getText(Paths.frag("glowPulse")));
    this.amount = amount;
    this.duration = duration;
  }

  public function update(elapsed:Float)
  {
    // The setter tied to this value automatically propagates the value to the shader.
    this.time += elapsed;
  }
}
