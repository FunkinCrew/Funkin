package funkin.shaderslmfao;

import flixel.addons.display.FlxRuntimeShader;
import funkin.Paths;
import openfl.utils.Assets;
import openfl.display.BitmapData;

class BlendModesShader extends FlxRuntimeShader
{
  public var camera:BitmapData;

  public function new()
  {
    super(Assets.getText(Paths.frag('blendModes')));
  }

  public function setCamera(camera:BitmapData):Void
  {
    this.camera = camera;

    this.setBitmapData('camera', camera);
  }
}
