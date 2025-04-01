package funkin.graphics.shaders;

import openfl.display.BitmapData;
import openfl.display.BlendMode;

class RuntimeCustomBlendShader extends RuntimePostEffectShader
{
  // only different name purely for hashlink fix
  public var sourceSwag(default, set):BitmapData;

  function set_sourceSwag(value:BitmapData):BitmapData
  {
    this.setBitmapData("sourceSwag", value);
    return sourceSwag = value;
  }

  // name change make sure it's not the same variable name as whatever is in the shader file
  public var blendSwag(default, set):BlendMode;

  function set_blendSwag(value:BlendMode):BlendMode
  {
    this.setInt("blendMode", cast value);
    return blendSwag = value;
  }

  public function new()
  {
    super(Assets.getText("assets/shaders/customBlend.frag"));
  }
}
