package funkin.graphics.framebuffer;

import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.textures.TextureBase;
import openfl.filters.BitmapFilter;
import animate.internal.FilterRenderer;
import flixel.math.FlxMatrix;
import openfl.display.OpenGLRenderer;
import flixel.FlxCamera;
import openfl.Lib;
import openfl.geom.Matrix;
import openfl.geom.ColorTransform;

/**
 * A utility class for `BitmapData`s.
 */
@:nullSafety
@:access(openfl.display.BitmapData)
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.display3D.Context3D)
@:access(openfl.display.OpenGLRenderer)
@:access(flixel.FlxCamera)
@:access(openfl.display.Sprite)
@:access(openfl.geom.ColorTransform)
class BitmapDataUtil
{
  static var renderer(get, never):OpenGLRenderer;
  static var _renderer:Null<OpenGLRenderer>;
  static var _renderMatrix:FlxMatrix = new FlxMatrix();

  static inline function get_renderer():OpenGLRenderer
  {
    if (_renderer == null)
    {
      _renderer = new OpenGLRenderer(FlxG.stage.context3D);
      _renderer.__worldTransform = new Matrix();
      _renderer.__worldColorTransform = new ColorTransform();
    }

    return _renderer;
  }

  /**
   * Draws the contents of multiple cameras onto a `BitmapData` object.
   *
   * @param bitmap The bitmap to draw onto.
   * @param cameras The cameras to grab the screens from.
   *
   * @return The combined camera screens as a `BitmapData`.
   */
  public static function drawCameraScreens(bitmap:BitmapData, cameras:Array<FlxCamera>):BitmapData
  {
    bitmap.__fillRect(bitmap.rect, 0, true);

    for (camera in cameras)
    {
      if (camera.filters != null && camera.filters.length > 0)
      {
        drawCameraScreen(bitmap, camera, false, true);
      }
      else
      {
        drawCameraScreen(bitmap, camera, false);
      }
    }

    return bitmap;
  }

  /**
   * Draws the contents of a camera onto a `BitmapData` object.
   *
   * Mostly copied from flixel-animate's `RenderTexture`
   * Shoutouts to ACrazyTown and MaybeMaru this is some crazy work
   * https://github.com/MaybeMaru/flixel-animate/blob/main/src/animate/internal/RenderTexture.hx
   *
   * @param bitmap The bitmap to draw onto.
   * @param camera The camera to grab the screen from.
   * @param clearBitmap Whether to clear the bitmap before drawing.
   * @param drawFlashSprite Whether to draw the camera's flash sprite instead of the canvas. WARNING: This is very slow ESPECIALLY if the camera has filters!!!
   *
   * @return The camera screen as a `BitmapData`.
   */
  public static function drawCameraScreen(bitmap:BitmapData, camera:FlxCamera, clearBitmap:Bool = true, drawFlashSprite:Bool = false):BitmapData
  {
    var pivotX:Float = FlxG.scaleMode.scale.x;
    var pivotY:Float = FlxG.scaleMode.scale.y;
    var scaleX:Float = bitmap.width / camera.width;
    var scaleY:Float = bitmap.height / camera.height;

    _renderMatrix.setTo(scaleX / pivotX, 0, 0, scaleY / pivotY, camera.flashSprite.x * scaleX / pivotX, camera.flashSprite.y * scaleY / pivotY);

    camera.render();
    camera.flashSprite.__update(false, true);

    renderer.__cleanup();

    renderer.setShader(renderer.__defaultShader);
    renderer.__allowSmoothing = false;
    renderer.__pixelRatio = Lib.current.stage.window.scale;
    renderer.__worldAlpha = 1 / camera.flashSprite.__worldAlpha;
    renderer.__worldTransform.copyFrom(camera.flashSprite.__renderTransform);
    renderer.__worldTransform.invert();
    renderer.__worldTransform.concat(_renderMatrix);
    renderer.__worldColorTransform.__copyFrom(camera.flashSprite.__worldColorTransform);
    renderer.__worldColorTransform.__invert();
    renderer.__setRenderTarget(bitmap);

    var context = renderer.__context3D;
    var cacheRTT = context.__state.renderToTexture;
    var cacheRTTDepthStencil = context.__state.renderToTextureDepthStencil;
    var cacheRTTAntiAlias = context.__state.renderToTextureAntiAlias;
    var cacheRTTSurfaceSelector = context.__state.renderToTextureSurfaceSelector;

    context.setRenderToTexture(bitmap.getTexture(context), true);
    if (clearBitmap) renderer.__clear();
    renderer.__render(drawFlashSprite ? camera.flashSprite : camera.canvas);

    if (cacheRTT != null)
    {
      context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
    }
    else
    {
      context.setRenderToBackBuffer();
    }

    return bitmap;
  }

  /**
   * Applies a `BitmapFilter` to a bitmap.
   * @param bitmap The `BitmapData` to apply the filter to.
   * @param filter The filter to apply.
   *
   * @return The `BitmapData` with the filter applied.
   */
  public static function applyFilter(bitmap:BitmapData, filter:BitmapFilter):BitmapData
  {
    return FilterRenderer.applyFilter(null, bitmap, [filter]);
  }

  /**
   * Convers a `BitmapData` to a GPU texture.
   * @param bitmap The `BitmapData` to convert.
   * @param disposeImage Whether to dispose bitmap's image or not by defaults its `true`.
   * @return The converted `BitmapData`.
   */
  public static function toGPU(bitmap:BitmapData, disposeImage:Bool = true):BitmapData
  {
    if (disposeImage)
    {
      bitmap.disposeImage();
    }
    bitmap.getTexture(FlxG.stage.context3D);

    return bitmap;
  }

  /**
   * Resizes the bitmap.
   * @param bitmap The `BitmapData` to resize.
   * @param width The new width.
   * @param height The new height.
   */
  public static function resize(bitmap:BitmapData, width:Int, height:Int):Void
  {
    if (bitmap.width == width && bitmap.height == height) return;

    bitmap.width = width;
    bitmap.height = height;

    if (!bitmap.readable)
    {
      resizeTexture(bitmap.__texture, width, height);
    }
  }

  /**
   * Resizes the hardware texture.
   * @param texture The `TextureBase` to resize.
   * @param width The new width.
   * @param height The new height.
   */
  public static function resizeTexture(texture:TextureBase, width:Int, height:Int):Void
  {
    if (texture.__width == width && texture.__height == height) return;

    var context:Context3D = texture.__context;

    texture.__width = width;
    texture.__height = height;

    context.__bindGLTexture2D(texture.__textureID);
    context.gl.texImage2D(context.gl.TEXTURE_2D, 0, texture.__internalFormat, width, height, 0, texture.__format, context.gl.UNSIGNED_BYTE, null);

    @:nullSafety(Off)
    context.__bindGLTexture2D(null);
  }

  /**
   * Copies the contents of `source` to `destination`. `destination` bitmap will be resized
   * so that it has the same size as `source`.
   * @param source The source `BitmapData`.
   * @param destination The destination `BitmapData`.
   */
  public static function copy(source:BitmapData, destination:BitmapData):Void
  {
    resize(destination, source.width, source.height);
    destination.fillRect(destination.rect, 0);
    destination.draw(source);
  }
}
