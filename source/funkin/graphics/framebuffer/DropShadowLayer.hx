package funkin.graphics.framebuffer;

import flixel.util.FlxColor;
import funkin.graphics.FunkinCamera;
import funkin.graphics.shaders.BlurShaderDown;
import funkin.graphics.shaders.BlurShaderShadow;
import funkin.graphics.shaders.BlurShaderUp;
import openfl.filters.ShaderFilter;

/**
 * A `FunkinBufferSprite` that can render a drop shadow under every sprite for a chosen camera.
 */
class DropShadowLayer extends FunkinBufferSprite
{
  public function new(camera:FunkinCamera, _color:FlxColor = 0xFFFFFFFF, sampleSteps:Int = 2, blurAmt:Float = 4, distX:Float = 0, distY:Float = 0)
  {
    super(0, 0, camera, {
      baseZoom: 1,
      bufferDelay: 0.0010, // Ever so slight delay to improve performance just a bit.
      resolutionScale: 0.35 // Buffer sprite is downscaled to prevent the game from applying a shader to a massive texture lmao
    });

    filters = [];

    // Down samples
    for (i in 0...sampleSteps)
    {
      var downFilter:ShaderFilter = new ShaderFilter(new BlurShaderDown(1 / (i + 1), blurAmt));
      filters.push(downFilter);
    }

    // Up samples
    for (i in 0...sampleSteps)
    {
      var upFilter:ShaderFilter = new ShaderFilter(new BlurShaderUp(sampleSteps - i, blurAmt));
      filters.push(upFilter);
    }

    var finalFilter:ShaderFilter = new ShaderFilter(new BlurShaderShadow(_color, distX, distY));
    filters.push(finalFilter);
  }
}
