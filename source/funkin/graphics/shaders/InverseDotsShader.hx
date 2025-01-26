package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;

/**
 * Create a little dotting effect.
 */
class InverseDotsShader extends FlxRuntimeShader
{
  public var amount:Float;

  public function new(amount:Float = 1.0)
  {
    super(Assets.getText(Paths.frag("InverseDots")));
    setAmount(amount);
  }

  public function setAmount(value:Float):Void
  {
    this.amount = value;
    this.setFloat("_amount", amount);
  }
}
