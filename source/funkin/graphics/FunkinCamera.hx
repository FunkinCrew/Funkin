package funkin.graphics;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawQuadsItem;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.graphics.tile.FlxGraphicsShader;
import funkin.graphics.framebuffer.FunkinBufferRenderer;
import openfl.Lib;
import openfl.geom.ColorTransform;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.OpenGLRenderer;
import openfl.display3D.Context3DBlendTarget;

using funkin.graphics.framebuffer.BitmapDataUtil;

/**
 * A FlxCamera with additional powerful features:
 * - Added the ability to grab the camera screen as a `BitmapData` and use it as a texture.
 */
@:nullSafety
@:access(openfl.display.DisplayObject)
@:access(openfl.display.BitmapData)
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.textures.TextureBase)
@:access(flixel.graphics.FlxGraphic)
@:access(flixel.graphics.frames.FlxFrame)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.geom.ColorTransform)
@:access(funkin.graphics.framebuffer.FunkinBufferRenderer)
class FunkinCamera extends FlxCamera
{
  /**
   * The ID of this camera, used for debugging.
   */
  public var id:String;

  /**
   * If `true` the camera will render the previous frame to a buffer before rendering the current frame.
   * This buffer can then be accessed via `camera.texture`.
   *
   * Disabled by default since this can impact performance.
   */
  public var renderBuffer:Bool = false;

  /**
   * If `true`, and `renderBuffer` is on, the camera only draws into its buffer and never onto the
   * screen.
   */
  public var bufferOnly:Bool = false;

  /**
   * The renderer used to render the buffer.
   */
  public var bufferRenderer:FunkinBufferRenderer;

  /**
   * The shader to use on all objects rendering through this camera (only if the incoming objects do not define a shader).
   * If null defaults to `FlxGraphicsShader`
   */
  public var defaultShader:Null<FlxGraphicsShader> = null;

  /**
   * The rendered buffer texture.
   */
  public var texture(get, never):BitmapData;

  function get_texture():BitmapData
  {
    return bufferRenderer.texture;
  }

  @:nullSafety(Off)
  public function new(id:String = 'unknown', x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0, zoom:Float = 0)
  {
    super(x, y, width, height, zoom);

    this.id = id;

    bufferRenderer = new FunkinBufferRenderer(this);
  }

  /**
   * Allocates the render textures and shader used by the shader blend fallback.
   */
  @:nullSafety(Off) @:nullSafety(Off)
  override function startQuadBatch(graphic:FlxGraphic,
    colored:Bool,
    hasColorOffsets:Bool = false,
    ?blend:BlendMode,
    smooth:Bool = false,
    ?shader:FlxGraphicsShader,
    ?blendTarget:Context3DBlendTarget):FlxDrawQuadsItem
  {
    if (shader == null) shader = defaultShader;

    return super.startQuadBatch(graphic, colored, hasColorOffsets, blend, smooth, shader, getBlendTarget(blendTarget, blend));
  }

  var _backBufferTarget:Null<Context3DBlendTarget> = null;

  function getBlendTarget(blendTarget:Null<Context3DBlendTarget>,
    ?blend:BlendMode):Context3DBlendTarget
  {
    if (blendTarget != null) return blendTarget;
    if (!canvas.cacheAsBitmap || blend == null || blend == NORMAL) return Context3DBlendTarget.BlendRenderTarget;

    if (_backBufferTarget == null) _backBufferTarget = Context3DBlendTarget.BlendMergedTarget(viewportRect);

    return _backBufferTarget;
  }

  public var blackListKeys:Array<String> = [];
  public var whiteListKeys:Array<String> = [];
  public var useWhitelist:Bool = false;

  function shouldRender(graphic:FlxGraphic):Bool
  {
    if (blackListKeys.contains(graphic.key))
    {
      return false;
    }

    if (useWhitelist && !whiteListKeys.contains(graphic.key))
    {
      return false;
    }

    return !graphic.isDestroyed;
  }

  @:allow(flixel.system.frontEnds.CameraFrontEnd)
  override function render():Void
  {
    // The pass that would go to the screen, on a camera that only exists to fill its buffer. The
    // buffer's own pass is the one with `dirty` set, and it is left alone.
    if (renderBuffer && bufferOnly && !bufferRenderer.dirty) return;

    __applyFlashSpriteFilters();

    if (FlxG.renderTile)
    {
      __apply__rotated__matrix();
    }

    var currItem:flixel.graphics.tile.FlxDrawBaseItem<Dynamic> = _headOfDrawStack;
    while (currItem != null)
    {
      if (renderBuffer && bufferRenderer.dirty)
      {
        if (!bufferRenderer.shouldRender(currItem.graphics))
        {
          currItem = currItem.next;
          continue;
        }
      }

      var shader = null;
      final quadItem:FlxDrawQuadsItem = cast currItem;
      if (quadItem != null)
      {
        var graphics = quadItem.graphics;
        if (graphics != null && graphics.shader != null && Type.getClass(graphics.shader) != FlxGraphicsShader) shader = graphics.shader;
        if (shader == null) shader = quadItem.shader;
      }

      final triItem:FlxDrawTrianglesItem = cast currItem;
      if (triItem != null && shader == null)
      {
        var graphics = triItem.graphics;
        if (graphics != null && graphics.shader != null && Type.getClass(graphics.shader) != FlxGraphicsShader) shader = graphics.shader;
        if (shader == null) shader = triItem.shader;
      }

      if (shader == null && defaultShader != null) shader = defaultShader;
      if (shader != null)
      {
        shader.sampleAttachment.value = [shouldRender(currItem.graphics)];

        if (currItem.type == flixel.graphics.tile.FlxDrawBaseItem.FlxDrawItemType.TILES) shader.bitmap.wrap = openfl.display3D.Context3DWrapMode.CLAMP;
      }

      currItem.render(this);
      currItem = currItem.next;
    }
  }

  override function startTrianglesBatch(graphic:FlxGraphic,
    smoothing:Bool = false,
    isColored:Bool = false,
    ?blend:BlendMode,
    ?hasColorOffsets:Bool,
    ?shader:FlxGraphicsShader,
    ?blendTarget:Context3DBlendTarget):FlxDrawTrianglesItem
  {
    if (shader == null) shader = defaultShader;

    return super.startTrianglesBatch(graphic, smoothing, isColored, blend, hasColorOffsets, shader, getBlendTarget(blendTarget, blend));
  }

  override function clearDrawStack():Void
  {
    if (renderBuffer && bufferRenderer.active)
    {
      bufferRenderer.render();
    }

    super.clearDrawStack();
  }

  override function destroy():Void
  {
    renderBuffer = false;

    super.destroy();

    bufferRenderer.destroy();
  }
}
