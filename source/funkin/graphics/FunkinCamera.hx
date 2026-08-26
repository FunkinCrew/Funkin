package funkin.graphics;

import animate.internal.RenderTexture;
import flash.geom.ColorTransform;
import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawQuadsItem;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import funkin.graphics.framebuffer.FunkinBufferRenderer;
import funkin.graphics.shaders.RuntimeCustomBlendShader;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.OpenGLRenderer;

using funkin.graphics.framebuffer.BitmapDataUtil;

/**
 * A FlxCamera with additional powerful features:
 * - Added the ability to grab the camera screen as a `BitmapData` and use it as a texture.
 * - Added support for the following blend modes for a sprite through shaders:
 *   - DARKEN
 *   - HARDLIGHT
 *   - LIGHTEN
 *   - OVERLAY
 *   - DIFFERENCE
 *   - INVERT
 *   - COLORDODGE
 *   - COLORBURN
 *   - SOFTLIGHT
 *   - EXCLUSION
 *   - HUE
 *   - SATURATION
 *   - COLOR
 *   - LUMINOSITY
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
   * Whether or not the device supports the OpenGL extension `KHR_blend_equation_advanced`.
   * If `false`, a shader implementation will be used to render certain blend modes.
   */
  public static var hasKhronosExtension(get, never):Bool;

  static inline function get_hasKhronosExtension():Bool
  {
    #if FORCE_BLEND_SHADER
    return false;
    #else
    @:privateAccess
    return OpenGLRenderer.__complexBlendsSupported ?? false;
    #end
  }

  /**
   * A list of blend modes that require the OpenGL extension `KHR_blend_equation_advanced`.
   *
   * NOTE:
   *  - `LIGHTEN` is supported natively on desktop, but not other platforms.
   *  - While `DARKEN` is supported natively on desktop, it causes issues with transparency.
   */
  static final KHR_BLEND_MODES:Array<BlendMode> = [
    DARKEN,
    HARDLIGHT,
    #if !desktop LIGHTEN, #end
    OVERLAY,
    DIFFERENCE,
    COLORDODGE,
    COLORBURN,
    SOFTLIGHT,
    EXCLUSION,
    HUE,
    SATURATION,
    COLOR,
    LUMINOSITY
  ];

  /**
   * A list of blend modes that require the shader no matter what.
   * This is due to these blend modes not being supported on any platform.
   */
  static final SHADER_REQUIRED_BLEND_MODES:Array<BlendMode> = [INVERT];

  /**
   * The ID of this camera, used for debugging.
   */
  public var id:String;

  /**
   * If `true` the blend shader will try to blend with the cameras underneath it.
   * This is useful for, say, making a strumline note have a shader-only blend mode like `INVERT`.
   *
   * Defaults to `false` since this can impact performance.
   */
  public var crossCameraBlending:Bool;

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
   * The rendered buffer texture.
   */
  public var texture(get, never):BitmapData;

  function get_texture():BitmapData
  {
    return bufferRenderer.texture;
  }

  var _blendShader:RuntimeCustomBlendShader;
  var _blendBackgroundFrame:FlxFrame;
  var _foregroundRenderTexture:RenderTexture;
  var _blendedRenderTexture:RenderTexture;
  var _cameraTexture:BitmapData;
  var _cameraMatrix:FlxMatrix;

  @:nullSafety(Off)
  public function new(id:String = 'unknown', x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0, zoom:Float = 0)
  {
    super(x, y, width, height, zoom);

    this.id = id;

    _blendShader = new RuntimeCustomBlendShader();

    _blendedRenderTexture = new RenderTexture(this.width, this.height);
    _foregroundRenderTexture = new RenderTexture(this.width, this.height);

    _blendBackgroundFrame = new FlxFrame(new FlxGraphic('', _foregroundRenderTexture.graphic.bitmap));
    _blendBackgroundFrame.frame = new FlxRect();

    _cameraMatrix = new FlxMatrix();

    _cameraTexture = new BitmapData(this.width, this.height, true, 0).toGPU();

    crossCameraBlending = false;

    bufferRenderer = new FunkinBufferRenderer(this);
  }

  override function drawPixels(?frame:FlxFrame,
    ?pixels:BitmapData,
    matrix:FlxMatrix,
    ?transform:ColorTransform,
    ?blend:BlendMode,
    ?smoothing:Bool = false,
    ?shader:FlxShader):Void
  {
    var shouldUseShader:Bool = (!hasKhronosExtension && KHR_BLEND_MODES.contains(blend)) || SHADER_REQUIRED_BLEND_MODES.contains(blend);

    // Fallback to the shader implementation if the device doesn't support `KHR_blend_equation_advanced`, or if
    // the specified blend mode requires the shader.
    if (shouldUseShader)
    {
      bufferRenderer.active = false;

      if (crossCameraBlending)
      {
        var camerasUnderneath:Array<FlxCamera> = FlxG.cameras.list.copy();

        for (i in camerasUnderneath.length - 1...-1)
        {
          if (i > FlxG.cameras.list.indexOf(this))
          {
            camerasUnderneath.remove(camerasUnderneath[i]);
          }
        }

        _cameraTexture.drawCameraScreens(camerasUnderneath);

        for (camera in camerasUnderneath)
        {
          camera.clearDrawStack();
          camera.canvas.graphics.clear();
        }
      }
      else
      {
        _cameraTexture.drawCameraScreen(this);
      }

      _blendBackgroundFrame.frame.set(0, 0, this.width, this.height);

      // Clear the camera's graphics
      // It'll get redrawn anyway
      this.clearDrawStack();
      this.canvas.graphics.clear();

      _foregroundRenderTexture.init(this.width, this.height);
      _foregroundRenderTexture.drawToCamera((camera, frameMatrix) ->
      {
        var pivotX:Float = width / 2;
        var pivotY:Float = height / 2;

        frameMatrix.copyFrom(matrix);
        frameMatrix.translate(-pivotX, -pivotY);
        frameMatrix.scale(this.scaleX, this.scaleY);
        frameMatrix.rotateWithTrig(_cosScrollAngle, _sinScrollAngle);
        frameMatrix.translate(pivotX, pivotY);
        camera.drawPixels(frame, pixels, frameMatrix, transform, null, smoothing, shader);
      });
      _foregroundRenderTexture.render();

      _blendShader.sourceSwag = _foregroundRenderTexture.graphic.bitmap;
      _blendShader.backgroundSwag = _cameraTexture;

      _blendShader.blendSwag = blend;
      _blendShader.updateViewInfo(width, height, this);

      // On some displays, the DPI can be less than 1, which causes the blend shader to look bad
      // We just clamp the scale to 1 to avoid this!
      var clampedScale:Float = Math.max(1, Lib.current.stage.window.scale);

      _blendedRenderTexture.init(Std.int(this.width * clampedScale), Std.int(this.height * clampedScale));
      _blendedRenderTexture.drawToCamera((camera, matrix) ->
      {
        camera.zoom = this.zoom;
        matrix.scale(clampedScale, clampedScale);
        camera.drawPixels(_blendBackgroundFrame, null, matrix, canvas.transform.colorTransform, null, false, _blendShader);
      });

      _blendedRenderTexture.render();

      // Resize the frame so it always fills the screen
      _cameraMatrix.identity();
      _cameraMatrix.scale(1 / (this.scaleX * clampedScale), 1 / (this.scaleY * clampedScale));
      _cameraMatrix.translate(((width - width / this.scaleX) * 0.5), ((height - height / this.scaleY) * 0.5));
      _cameraMatrix.translate(-width * 0.5, -height * 0.5);
      _cameraMatrix.rotateWithTrig(_cosScrollAngle, -_sinScrollAngle);
      _cameraMatrix.translate(width * 0.5, height * 0.5);

      super.drawPixels(_blendedRenderTexture.graphic.imageFrame.frame, null, _cameraMatrix, null, null, smoothing, null);

      bufferRenderer.active = true;
    }
    else
    {
      super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
    }
  }

  override function startQuadBatch(graphic:FlxGraphic,
    colored:Bool,
    hasColorOffsets:Bool = false,
    ?blend:BlendMode,
    smooth:Bool = false,
    ?shader:FlxShader):FlxDrawQuadsItem
  {
    // Can't batch complex non-coherent blends, so always force a new batch
    if (hasKhronosExtension && !(OpenGLRenderer.__coherentBlendsSupported ?? false) && KHR_BLEND_MODES.contains(blend))
    {
      var itemToReturn = null;

      if (FlxCamera._storageTilesHead != null)
      {
        itemToReturn = FlxCamera._storageTilesHead;
        var newHead = FlxCamera._storageTilesHead.nextTyped;
        itemToReturn.reset();
        FlxCamera._storageTilesHead = newHead;
      }
      else
      {
        itemToReturn = new FlxDrawQuadsItem();
      }

      // TODO: catch this error when the dev actually messes up, not in the draw phase
      if (graphic.isDestroyed) throw 'Cannot queue ${graphic.key}. This sprite was destroyed.';

      itemToReturn.graphics = graphic;
      itemToReturn.antialiasing = smooth;
      itemToReturn.colored = colored;
      itemToReturn.hasColorOffsets = hasColorOffsets;
      itemToReturn.blend = blend;
      @:nullSafety(Off)
      itemToReturn.shader = shader;

      itemToReturn.nextTyped = _headTiles;
      _headTiles = itemToReturn;

      if (_headOfDrawStack == null)
      {
        _headOfDrawStack = itemToReturn;
      }

      if (_currentDrawItem != null)
      {
        _currentDrawItem.next = itemToReturn;
      }

      _currentDrawItem = itemToReturn;

      return itemToReturn;
    }

    return super.startQuadBatch(graphic, colored, hasColorOffsets, blend, smooth, shader);
  }

  @:allow(flixel.system.frontEnds.CameraFrontEnd)
  override function render():Void
  {
    // The pass that would go to the screen, on a camera that only exists to fill its buffer. The
    // buffer's own pass is the one with `dirty` set, and it is left alone.
    if (renderBuffer && bufferOnly && !bufferRenderer.dirty) return;

    @:nullSafety(Off)
    flashSprite.filters = filtersEnabled ? filters : null;

    if (FlxG.renderTile)
    {
      canvas.transform.matrix = __get__rotated__matrix();
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

      currItem.render(this);
      currItem = currItem.next;
    }
  }

  override function startTrianglesBatch(graphic:FlxGraphic,
    smoothing:Bool = false,
    isColored:Bool = false,
    ?blend:BlendMode,
    ?hasColorOffsets:Bool,
    ?shader:FlxShader):FlxDrawTrianglesItem
  {
    // Can't batch complex non-coherent blends, so always force a new batch
    if (
      hasKhronosExtension
      && !(OpenGLRenderer.__coherentBlendsSupported ?? false)
      && KHR_BLEND_MODES.contains(blend)
    ) return getNewDrawTrianglesItem(graphic, smoothing, isColored, blend, hasColorOffsets, shader);

    return super.startTrianglesBatch(graphic, smoothing, isColored, blend, hasColorOffsets, shader);
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

    _foregroundRenderTexture.destroy();
    _blendedRenderTexture.destroy();

    _cameraTexture.dispose();

    bufferRenderer.destroy();
  }
}
