package funkin.graphics.framebuffer;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;

using funkin.graphics.framebuffer.BitmapDataUtil;

/**
 * Settings for a `FunkinBufferSprite`
 */
typedef FunkinBufferSpriteSettings =
{
  /**
   * The base zoom of the camera.
   * The buffer will always be rendered at this zoom.
   * If set to `-1`, the buffer will be rendered at whatever zoom the camera was on the previous frame.
   */
  @:optional
  var baseZoom:Float;

  /**
   * The delay before the buffer is rendered.
   * If set to `0`, the buffer will be rendered immediately.
   *
   * Could be useful for performance.
   */
  @:optional
  var bufferDelay:Float;

  /**
   * If enabled, the buffer will behave in screen space.
   * This is useful for reflections that need to be rendered in various zoom levels.
   *
   * By default, it's disabled. So it renders in world space.
   */
  @:optional
  var useScreenspace:Bool;

  /**
   * The resolution scale of the buffer.
   * Setting it lower than 1.0 will make the buffer render at a lower resolution.
   */
  @:optional
  var resolutionScale:Float;
}

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

  /**
   * The resolution scale of the buffer.
   * Setting it lower than 1.0 will make the buffer render at a lower resolution.
   */
  public var resolutionScale(default, set):Float = 1.0;

  function set_resolutionScale(value:Float):Float
  {
    if (value == resolutionScale) return value;
    if (value > 1.0) value = 1.0; // Clamp it down to 1.0

    resolutionScale = value;

    var newWidth:Int = Std.int(_usedCamera.width * resolutionScale);
    var newHeight:Int = Std.int(_usedCamera.height * resolutionScale);

    renderer.resize(newWidth, newHeight);
    this.setSize(newWidth, newHeight);
    this.graphic.bitmap = renderer.texture;
    this.frameWidth = newWidth;
    this.frameHeight = newHeight;
    this.frames = this.graphic.imageFrame;
    this.updateHitbox();

    return value;
  }

  /**
   * If enabled, the buffer will behave in screen space.
   * This is useful for reflections that need to be rendered in various zoom levels.
   *
   * By default, it's disabled. So it renders in world space.
   */
  public var useScreenspace(default, set):Bool = false;

  function set_useScreenspace(value:Bool):Bool
  {
    if (value == useScreenspace) return value;

    useScreenspace = value;

    // Buffer sprite needs to stick with the camera in screen space
    this.scrollFactor.set(0, 0);

    return value;
  }

  var _usedCamera:FunkinCamera;

  public function new(x:Float = 0,
    y:Float = 0,
    camera:FunkinCamera,
    params:FunkinBufferSpriteSettings)
  {
    super(x, y);

    _usedCamera = camera;

    // We need the previous frame from the camera
    _usedCamera.renderBuffer = true;

    this.baseZoom = params.baseZoom ?? -1;
    this.bufferDelay = params.bufferDelay ?? 0;
    this.useScreenspace = params.useScreenspace ?? false;

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

    // Setting this last since everything else needs to initialize first
    this.resolutionScale = params.resolutionScale ?? 1.0;
  }

  override function drawFrameComplex(frame:FlxFrame, camera:FlxCamera):Void
  {
    if (!this.visible || this.alpha <= 0) return;

    final willUseRenderTexture = checkRenderTexture();
    final matrix = this._matrix;

    frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
    prepareDrawMatrix(matrix, camera);

    if (resolutionScale != 1.0)
    {
      var scale:Float = 1.0 / resolutionScale;
      matrix.scale(scale, scale);
    }

    if (useScreenspace)
    {
      var zoom:Float = _usedCamera.zoom;
      if (zoom == 0) zoom = 0.0001;

      var baseZoom:Float = this.baseZoom;
      if (baseZoom <= 0) baseZoom = 1;

      var scale:Float = baseZoom / zoom;

      matrix.scale(scale, scale);
      matrix.tx += ((1 - scale) * (frameWidth * 0.5)) + (this.x * (1 - scale));
      matrix.ty += ((1 - scale) * (frameHeight * 0.5)) + (this.y * (1 - scale));
    }

    if (this.filters != null && this.filters.length > 0)
    {
      filterRenderer.applyFilters(renderer.texture);

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
