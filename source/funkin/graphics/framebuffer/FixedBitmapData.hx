package funkin.graphics.framebuffer;

import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.OpenGLRenderer;
import openfl.display3D.textures.TextureBase;
import openfl.Lib;

/**
 * `BitmapData` is kinda broken so I fixed it.
 */
@:nullSafety
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.display.OpenGLRenderer)
class FixedBitmapData extends BitmapData
{
  override function __drawGL(source:IBitmapDrawable, renderer:OpenGLRenderer):Void
  {
    if (Std.isOfType(source, DisplayObject))
    {
      final object:DisplayObjectContainer = cast source;
      renderer.__stage = object.stage;
    }
    super.__drawGL(source, renderer);
  }

  /**
   * Creates a `FixedBitmapData` with the given dimensions.
   * @param width The width of the bitmap
   * @param height The height of the bitmap
   * @param useGPU Whether or not this bitmap should use a hardware texture
   * @return The newly created `FixedBitmapData`
   */
  public static function create(width:Int, height:Int, useGPU:Bool = true):FixedBitmapData
  {
    if (useGPU)
    {
      var texture:TextureBase = _createTexture(width, height);
      return fromTexture(texture);
    }

    return new FixedBitmapData(width, height, true, 0);
  }

  /**
   * Creates a `FixedBitmapData` from a hardware texture.
   * @param texture The texture
   * @return The newly created `FixedBitmapData`
   */
  public static function fromTexture(texture:TextureBase):FixedBitmapData
  {
    var bitmapData:FixedBitmapData = new FixedBitmapData(texture.__width, texture.__height, true, 0);
    bitmapData.readable = false;
    bitmapData.__texture = texture;
    bitmapData.__textureContext = texture.__textureContext;

    @:nullSafety(Off)
    bitmapData.image = null;

    return bitmapData;
  }

  static function _createTexture(width:Int, height:Int):TextureBase
  {
    // Zero-sized textures will be problematic.
    width = width < 1 ? 1 : width;
    height = height < 1 ? 1 : height;

    return Lib.current.stage.context3D.createTexture(width, height, BGRA, true);
  }
}
