package funkin.graphics.framebuffer;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
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

  var _cameraBufferFrame:FlxFrame;
  var _usedCamera:FunkinCamera;

  override function get_width():Float
  {
    return _usedCamera.texture.width;
  }

  override function get_height():Float
  {
    return _usedCamera.texture.height;
  }

  public function new(x:Float = 0, y:Float = 0, camera:FunkinCamera, baseZoom:Float = -1, bufferDelay:Float = 0)
  {
    super(x, y);

    _usedCamera = camera;

    // We need the previous frame from the camera
    _usedCamera.renderBuffer = true;

    @:privateAccess
    _cameraBufferFrame = new FlxFrame(new FlxGraphic('CAMERA_BUFFER', _usedCamera.texture));
    _cameraBufferFrame.frame = FlxRect.get(0, 0, _usedCamera.width, _usedCamera.height);

    this.baseZoom = baseZoom;
    this.bufferDelay = bufferDelay;
  }

  override function drawFrameComplex(frame:FlxFrame, camera:FlxCamera):Void
  {
    _cameraBufferFrame.frame.set(0, 0, _usedCamera.texture.width, _usedCamera.texture.height);

    final willUseRenderTexture = checkRenderTexture();
    final matrix = this._matrix;

    frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
    prepareDrawMatrix(matrix, camera);

    // The only time render texture would be used for this class is when filters are applied
    // So just applying the filters directly without checking is fine I think
    if (willUseRenderTexture && _cameraBufferFrame.parent.bitmap != null)
    {
      filterRenderer.applyFilters(_cameraBufferFrame.parent.bitmap);

      if (filtered)
      {
        camera.drawPixels(filterRenderer.graphic?.imageFrame.frame, null, matrix, colorTransform, blend, antialiasing, shader);
      }
      else
      {
        camera.drawPixels(_cameraBufferFrame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
      }
    }
    else
    {
      camera.drawPixels(_cameraBufferFrame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
    }
  }

  override function isOnScreen(?camera:FlxCamera):Bool
  {
    // Who knew that rendering an entire camera buffer to a sprite would fuck with its bounding box?
    return true;
  }
}
