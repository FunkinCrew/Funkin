package funkin.graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;
import openfl.Assets;
import funkin.assets.Paths;
import funkin.assets.Assets;

@:nullSafety
class PuddleShader extends FlxRuntimeShader
{
  public function new()
  {
    super(Assets.getText(Paths.frag('ui/shaders/puddle')));
  }
}
