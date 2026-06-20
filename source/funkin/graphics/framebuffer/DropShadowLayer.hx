package funkin.graphics.framebuffer;

import flixel.util.FlxColor;
import funkin.graphics.FunkinCamera;
import funkin.graphics.shaders.BlurShaderDown;
import funkin.graphics.shaders.BlurShaderShadow;
import funkin.graphics.shaders.BlurShaderUp;
import openfl.filters.ShaderFilter;

class DropShadowLayer extends FunkinBufferSprite
{
  public function new(camera:FunkinCamera, _color:FlxColor = 0xFFFFFFFF, sampleSteps:Int = 2, blurAmt:Float = 4, distX:Float = 5, distY:Float = 5)
  {
    // The resolution scale here is 0.35
    // This is just to prevent the game from applying a shader to a massive texture lmao
    super(0, 0, camera, 1, 0.010, 0.35);

    filters = [];

    // down samples
    for (i in 0...sampleSteps)
    {
      var downFilter:ShaderFilter = new ShaderFilter(new BlurShaderDown(1 / (i + 1), blurAmt));
      filters.push(downFilter);
    }

    // up samples
    for (i in 0...sampleSteps)
    {
      var upFilter:ShaderFilter = new ShaderFilter(new BlurShaderUp(sampleSteps - i, blurAmt));
      filters.push(upFilter);
    }

    var finalFilter:ShaderFilter = new ShaderFilter(new BlurShaderShadow(_color, distX, distY));
    filters.push(finalFilter);
  }
}
