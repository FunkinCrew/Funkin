package funkin.graphics.framebuffer;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;

using funkin.graphics.framebuffer.BitmapDataUtil;

/**
 * A `FunkinSprite` with its sole purpose of rendering a `FlxCamera`.
 */
@:access(funkin.graphics.FunkinCamera)
@:nullSafety
class FunkinBufferSprite extends FunkinSprite
{
  /**
   * The key of the graphic used for the buffer.
   */
  public static final BUFFER_TEXTURE_KEY:String = 'CAMERA_TEXTURE';

  /**
   * The base zoom of the camera.
   * The buffer will always be rendered at this zoom.
   * If set to `-1`, the buffer will be rendered at whatever zoom the camera was on the previous frame.
   */
  public var baseZoom(get, set):Float;

  function get_baseZoom():Float
  {
    return _usedCamera.bufferRenderer.zoom;
  }

  function set_baseZoom(value:Null<Float>):Float
  {
    if (value == null) return _usedCamera.bufferRenderer.zoom;
    return _usedCamera.bufferRenderer.zoom = value;
  }

  /**
   * The delay before the buffer is rendered.
   * If set to `0`, the buffer will be rendered immediately.
   *
   * Could be useful for performance.
   */
  public var bufferDelay(get, set):Float;

  function get_bufferDelay():Float
  {
    return _usedCamera.bufferRenderer.delay;
  }

  function set_bufferDelay(value:Null<Float>):Float
  {
    if (value == null) return _usedCamera.bufferRenderer.delay;
    return _usedCamera.bufferRenderer.delay = value;
  }

  /**
   * The renderer used by this sprite.
   */
  public var renderer(get, never):FunkinBufferRenderer;

  function get_renderer():FunkinBufferRenderer
  {
    return _usedCamera.bufferRenderer;
  }

  var _usedCamera:FunkinCamera;

  public function new(x:Float = 0, y:Float = 0, camera:FunkinCamera, baseZoom:Float = -1, bufferDelay:Float = 0)
  {
    super(x, y);

    _usedCamera = camera;

    // We need the previous frame from the camera
    _usedCamera.renderBuffer = true;

    this.baseZoom = baseZoom;
    this.bufferDelay = bufferDelay;

    @:privateAccess
    var bufferGraphic:FlxGraphic = new FlxGraphic(BUFFER_TEXTURE_KEY, _usedCamera.texture);
    this.frameWidth = bufferGraphic.width;
    this.frameHeight = bufferGraphic.height;
    this.frames = bufferGraphic.imageFrame;
    this.updateHitbox();

    // Force the filter renderer to use a specific key for its graphic
    // Allows the buffer renderer to identify the graphic properly
    this.filterRenderer.graphicKey = BUFFER_TEXTURE_KEY;

    // Prevent the buffer from being rendered onto itself.
    this.renderer.blacklistSprite(this);
  }

  override function drawFrameComplex(frame:FlxFrame, camera:FlxCamera):Void
  {
    final willUseRenderTexture = checkRenderTexture();
    final matrix = this._matrix;

    frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
    prepareDrawMatrix(matrix, camera);

    if (this.filters != null && this.filters.length > 0)
    {
      filterRenderer.applyFilters(this._usedCamera.texture);

      if (filtered)
      {
        camera.drawPixels(filterRenderer.graphic?.imageFrame.frame, null, matrix, colorTransform, blend, antialiasing, shader);
      }
      else
      {
        camera.drawPixels(frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
      }
    }
    else
    {
      camera.drawPixels(frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
    }
  }
}
