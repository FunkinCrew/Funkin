package funkin.graphics.framebuffer;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.BlurShaderShadow;
import funkin.graphics.shaders.BlurShaderDown;
import funkin.graphics.shaders.BlurShaderUp;
import openfl.filters.ShaderFilter;
import flixel.util.FlxColor;

class DropShadowLayer extends FunkinBufferSprite
{
  public function new(camera:FunkinCamera, _color:FlxColor = 0xFFFFFFFF, sampleSteps:Int = 3, blurAmt:Float = 4, distX:Float = 5, distY:Float = 5)
  {
    super(0, 0, camera, 1, 0);

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

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    scale.set(_usedCamera.zoom, _usedCamera.zoom);
    offset.set(width * (_usedCamera.zoom - 1) / 2, height * (_usedCamera.zoom - 1) / 2);
  }
}
