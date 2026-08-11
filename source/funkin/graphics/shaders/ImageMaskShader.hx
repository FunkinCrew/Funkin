package funkin.graphics.shaders;

import flixel.graphics.tile.FlxGraphicsShader;
import openfl.display.BitmapData;

class ImageMaskShader extends FlxGraphicsShader
{
  public var maskImage(default, set):BitmapData;

  /*
    Loads an image for the mask.
    While you *could* directly set the value of the mask, this function works for both HTML5 and native targets.
   */
  public function loadMask(path:String)
  {
    #if html5
    BitmapData.loadFromFile(path).onComplete(function(bmp:BitmapData)
    {
      maskImage = bmp;
    });
    #else
    maskImage = Assets.getBitmapData(path, false);
    #end
  }

  function set_maskImage(_bitmapData:BitmapData):BitmapData
  {
    image.input = _bitmapData;

    return _bitmapData;
  }

  @:glFragmentSource('
        #pragma header

        uniform sampler2D image;

        void main()
        {
            vec4 originalTexture = flixel_texture2D(bitmap, openfl_TextureCoordv);
            vec4 maskTexture = flixel_texture2D(image, openfl_TextureCoordv);

            gl_FragColor = vec4(originalTexture.r * maskTexture.a, originalTexture.g * maskTexture.a, originalTexture.b * maskTexture.a, maskTexture.a);
        }
    ')
  public function new()
  {
    super();
  }
}
