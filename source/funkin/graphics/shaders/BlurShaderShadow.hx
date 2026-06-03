package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;
import openfl.display.BitmapData;
import flixel.util.FlxColor;

class BlurShaderShadow extends FlxShader
{
  @:glFragmentSource('
    #pragma header
    // literally just offsets the image and colors it
    // used as the last step in the DropShadowLayer

    // x offset of drop shadow
    uniform float offsetX;
    // y offset of drop shadow
    uniform float offsetY;

    // color of shadow
    uniform vec4 shadowCol;

    void main()
    {
      vec2 imageRatio = vec2(1.0 / openfl_TextureSize.x, 1.0 / openfl_TextureSize.y);
      vec4 color = texture2D(bitmap, vec2(openfl_TextureCoordv.x - (offsetX*imageRatio.x),openfl_TextureCoordv.y - (offsetY*imageRatio.y)));

      gl_FragColor = vec4(shadowCol * color.a);
    }
  ')
  public function new(_shadowColor:FlxColor = 0xFF000000, _distX:Float = 5, _distY:Float = 5)
  {
    super();

    shadowCol.value = [_shadowColor.redFloat, _shadowColor.greenFloat, _shadowColor.blueFloat, _shadowColor.alphaFloat];
    offsetX.value = [_distX];
    offsetY.value = [_distY];
  }
}
