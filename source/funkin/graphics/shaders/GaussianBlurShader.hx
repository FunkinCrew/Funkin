package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;

/**
 * Note... not actually gaussian!
 */
@:nullSafety
class GaussianBlurShader extends FlxRuntimeShader
{
  public var amount:Float = 1;

  public function new(amount:Float = 1.0)
  {
    super(Assets.getText(Paths.frag('ui/shaders/gaussian-blur')));
    setAmount(amount);
  }

  public function setAmount(value:Float):Void
  {
    this.amount = value;
    this.setFloat('_amount', amount);
  }
}
