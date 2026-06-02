package funkin.graphics.effects;

import funkin.graphics.effects.FunkinEffect.FunkinEffectParams;

/**
 * A `FunkinEffect` that can make the sprite float up and down, it's as shrimple as that.
 */
@:nullSafety
class FloatEffect extends FunkinEffect
{
  /**
   * The speed at which the sprite floats.
   * Decreasing this will make the sprite float faster.
   */
  public var floatSpeed:Float = 1.0;

  /**
   * The maximum float value.
   * Increasing this will make the sprite float higher.
   */
  public var maxFloat:Float = 0.05;

  var _floatValue:Float = 0;

  public function new(floatSpeed:Float = 1.0, maxFloat:Float = 0.05, ?params:FunkinEffectParams)
  {
    super('float', params);

    this.floatSpeed = floatSpeed;
    this.maxFloat = maxFloat;
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (!active) return;

    if (parentSprite == null) return;

    _floatValue += (elapsed * floatSpeed);

    parentSprite.y += Math.sin(_floatValue) * maxFloat;
  }
}
