package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;
import openfl.Assets;

class PuddleShader extends FlxRuntimeShader
{
  public function new()
  {
    super(Assets.getText(Paths.frag('puddle')));
  }
}
