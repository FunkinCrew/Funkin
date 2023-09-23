package funkin.graphics.framebuffer;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display3D.textures.TextureBase;

/**
 * A camera, but grabbable.
 */
@:access(openfl.display.DisplayObject)
@:access(openfl.display.BitmapData)
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.textures.TextureBase)
@:access(flixel.graphics.FlxGraphic)
@:access(flixel.graphics.frames.FlxFrame)
class GrabbableCamera extends FlxCamera
{
  final grabbed:Array<BitmapData> = [];
  final texturePool:Array<TextureBase> = [];
  final defaultShader:FlxShader = new FlxShader();

  final bgTexture:TextureBase;
  final bgBitmap:BitmapData;
  final bgFrame:FlxFrame;

  public function new(x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0, zoom:Float = 0)
  {
    super(x, y, width, height, zoom);
    bgTexture = pickTexture(width, height);
    bgBitmap = FixedBitmapData.fromTexture(bgTexture);
    bgFrame = new FlxFrame(new FlxGraphic('', null));
    bgFrame.parent.bitmap = bgBitmap;
    bgFrame.frame = new FlxRect();
  }

  /**
   * Grabs the camera screen and returns it as a `BitmapData`. The returned bitmap
   * will not be referred by the camera, so changing it will not affect the scene.
   * @param applyFilters if this is `true`, the camera's filters will be applied to the grabbed bitmap
   * @return the grabbed bitmap data
   */
  public function grabScreen(applyFilters:Bool):BitmapData
  {
    final texture = pickTexture(width, height);
    final bitmap = FixedBitmapData.fromTexture(texture);
    squashTo(bitmap, applyFilters);
    return bitmap;
  }

  function squashTo(bitmap:BitmapData, applyFilters:Bool):Void
  {
    static final matrix = new FlxMatrix();

    // resize the background bitmap if needed
    if (bgTexture.__width != width || bgTexture.__height != height)
    {
      resizeTexture(bgTexture, width, height);
      bgBitmap.__resize(width, height);
      bgFrame.parent.bitmap = bgBitmap;
    }

    // grab the bitmap
    render();
    bitmap.fillRect(bitmap.rect, 0);
    matrix.setTo(1, 0, 0, 1, flashSprite.x, flashSprite.y);
    if (applyFilters)
    {
      bitmap.draw(flashSprite, matrix);
    }
    else
    {
      final tmp = flashSprite.filters;
      flashSprite.filters = null;
      bitmap.draw(flashSprite, matrix);
      flashSprite.filters = tmp;
    }

    // also copy to the background bitmap
    bgBitmap.fillRect(bgBitmap.rect, 0);
    bgBitmap.draw(bitmap);

    // clear graphics data
    super.clearDrawStack();
    canvas.graphics.clear();

    // render the background bitmap
    bgFrame.frame.set(0, 0, width, height);
    matrix.setTo(viewWidth / width, 0, 0, viewHeight / height, viewMarginLeft, viewMarginTop);
    drawPixels(bgFrame, matrix);
  }

  function resizeTexture(texture:TextureBase, width:Int, height:Int):Void
  {
    texture.__width = width;
    texture.__height = height;
    final context = texture.__context;
    final gl = context.gl;
    context.__bindGLTexture2D(texture.__textureID);
    gl.texImage2D(gl.TEXTURE_2D, 0, texture.__internalFormat, width, height, 0, texture.__format, gl.UNSIGNED_BYTE, null);
    context.__bindGLTexture2D(null);
  }

  override function destroy():Void
  {
    super.destroy();
    disposeTextures();
  }

  override function clearDrawStack():Void
  {
    super.clearDrawStack();
    // also clear grabbed bitmaps
    for (bitmap in grabbed)
    {
      texturePool.push(@:privateAccess bitmap.__texture);
      bitmap.dispose();
    }
    grabbed.clear();
  }

  function pickTexture(width:Int, height:Int):TextureBase
  {
    // zero-sized textures will be problematic
    width = width < 1 ? 1 : width;
    height = height < 1 ? 1 : height;
    if (texturePool.length > 0)
    {
      final res = texturePool.pop();
      if (res.__width != width || res.__height != height)
      {
        resizeTexture(res, width, height);
      }
      return res;
    }
    return Lib.current.stage.context3D.createTexture(width, height, BGRA, true);
  }

  function disposeTextures():Void
  {
    trace('disposing textures');
    for (bitmap in grabbed)
    {
      bitmap.dispose();
    }
    grabbed.clear();
    for (texture in texturePool)
    {
      texture.dispose();
    }
    texturePool.resize(0);
    bgTexture.dispose();
    bgBitmap.dispose();
  }
}
