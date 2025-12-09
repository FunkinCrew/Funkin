package funkin.graphics.framebuffer;

import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.IBitmapDrawable;
import openfl.display.OpenGLRenderer;
import openfl.display3D.textures.TextureBase;

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
   * Never use `BitmapData.fromTexture`, always use this.
   * @param texture the texture
   * @return the bitmap data
   */
  public static function fromTexture(texture:Null<TextureBase>):Null<FixedBitmapData>
  {
    if (texture == null) return null;
    final bitmapData:FixedBitmapData = new FixedBitmapData(texture.__width, texture.__height, true, 0);
    // bitmapData.readable = false;
    bitmapData.__texture = texture;
    bitmapData.__textureContext = texture.__textureContext;
    // bitmapData.image = null;
    return bitmapData;
  }
}
