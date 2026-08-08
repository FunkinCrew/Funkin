package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;

/**
 * Note... not actually gaussian!
 */
@:nullSafety
class GaussianBlurShader extends FlxRuntimeShader
{
  public var amount(default, set):Float = 1;

  function set_amount(val:Float):Float
  {
    this.amount = val;
    this.setFloat('_amount', val);

    return val;
  }

  public function new(amount:Float = 1.0)
  {
    super(Assets.getText(Paths.frag('ui/shaders/gaussian-blur')));
    this.amount = amount;
  }

  @:deprecated('Set amount directly instead')
  public function setAmount(value:Float):Void
  {
    this.amount = value;
  }
}
