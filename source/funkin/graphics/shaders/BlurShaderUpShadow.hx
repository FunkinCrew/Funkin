package funkin.graphics.shaders;

import flixel.graphics.tile.FlxGraphicsShader;
import flixel.util.FlxColor;

class BlurShaderUpShadow extends FlxGraphicsShader
{
  @:glFragmentSource('
    #pragma header
		// slightly edited Dual Kawase implementation taken from https://blog.frost.kiwi/dual-kawase/
		// this is the up-sample part of the effect.

    // blur strength (distance of samples)
    uniform float offset;
    // scale of current image
    uniform float scale;

    // x/y offset of drop shadow
    uniform float offsetX;
    uniform float offsetY;

    // color of shadow
    uniform vec4 shadowCol;

    void main()
    {
      vec2 imageRatio = vec2(1.0 / openfl_TextureSize.x, 1.0 / openfl_TextureSize.y);

      vec2 uv = openfl_TextureCoordv - vec2(offsetX * imageRatio.x, offsetY * imageRatio.y) / scale;
      vec2 rcp = vec2(1.0 / (openfl_TextureSize.x/scale), 1.0 / (openfl_TextureSize.y/scale));

      vec2 halfpixel = rcp * 0.5;
      vec2 o = halfpixel * (offset / scale);

      vec4 color = vec4(0.0);

      color += flixel_texture2D(bitmap, uv + vec2(-o.x * 2.0, 0.0));
      color += flixel_texture2D(bitmap, uv + vec2( o.x * 2.0, 0.0));
      color += flixel_texture2D(bitmap, uv + vec2(0.0, -o.y * 2.0));
      color += flixel_texture2D(bitmap, uv + vec2(0.0,  o.y * 2.0));

      color += flixel_texture2D(bitmap, uv + vec2(-o.x,  o.y)) * 2.0;
      color += flixel_texture2D(bitmap, uv + vec2( o.x,  o.y)) * 2.0;
      color += flixel_texture2D(bitmap, uv + vec2(-o.x, -o.y)) * 2.0;
      color += flixel_texture2D(bitmap, uv + vec2( o.x, -o.y)) * 2.0;

      color = color / 12.0;

      // literally just offsets the image and colors it
      // used as the last step in the DropShadowLayer
      gl_FragColor = vec4(shadowCol * color.a);
    }
  ')
  public function new(_scale:Float = 1,
    _offset:Float = 1,
    _shadowColor:FlxColor = 0xFF000000,
    _distX:Float = 5,
    _distY:Float = 5)
  {
    super();

    offset.value = [_offset];
    scale.value = [_scale];
    shadowCol.value = [_shadowColor.redFloat, _shadowColor.greenFloat, _shadowColor.blueFloat, _shadowColor.alphaFloat];
    offsetX.value = [_distX];
    offsetY.value = [_distY];
  }
}
