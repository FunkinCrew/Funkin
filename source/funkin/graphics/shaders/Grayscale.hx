package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;
import funkin.assets.Paths;
import funkin.assets.Assets;

@:nullSafety
class Grayscale extends FlxRuntimeShader
{
  public var amount:Float = 1;

  public function new(amount:Float = 1)
  {
    super(Assets.getText(Paths.frag('ui/shaders/grayscale')));
    setAmount(amount);
  }

  public function setAmount(value:Float):Void
  {
    amount = value;
    this.setFloat('_amount', amount);
  }
}
