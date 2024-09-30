package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;

/**
 * Create a little dotting effect.
 */
class InverseDotsShader extends FlxRuntimeShader
{
  public function new()
  {
    super(Assets.getText(Paths.frag("InverseDots")));
  }
}
