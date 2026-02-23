package funkin.graphics;

import animate.internal.RenderTexture;
import flash.geom.ColorTransform;
import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import funkin.graphics.framebuffer.FixedBitmapData;
import funkin.graphics.shaders.RuntimeCustomBlendShader;
import openfl.display.OpenGLRenderer;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import flixel.graphics.tile.FlxDrawQuadsItem;
import flixel.graphics.tile.FlxDrawTrianglesItem;

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
  static final KHR_BLEND_MODES:Array<BlendMode> = [DARKEN, HARDLIGHT, #if !desktop LIGHTEN, #end OVERLAY, DIFFERENCE, COLORDODGE, COLORBURN, SOFTLIGHT, EXCLUSION, HUE, SATURATION, COLOR, LUMINOSITY];

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

  var _blendShader:RuntimeCustomBlendShader;
  var _backgroundFrame:FlxFrame;

  var _blendRenderTexture:RenderTexture;
  var _backgroundRenderTexture:RenderTexture;

  var _cameraTexture:FixedBitmapData;
  var _cameraMatrix:FlxMatrix;

  @:nullSafety(Off)
  public function new(id:String = 'unknown', x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0, zoom:Float = 0)
  {
    super(x, y, width, height, zoom);

    this.id = id;

    _backgroundFrame = new FlxFrame(new FlxGraphic('', null));
    _backgroundFrame.frame = new FlxRect();

    _blendShader = new RuntimeCustomBlendShader();

    _backgroundRenderTexture = new RenderTexture(this.width, this.height);
    _blendRenderTexture = new RenderTexture(this.width, this.height);

    _cameraMatrix = new FlxMatrix();
    _cameraTexture = FixedBitmapData.create(this.width, this.height);

    crossCameraBlending = false;
  }

  override function drawPixels(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false,
      ?shader:FlxShader):Void
  {
    var shouldUseShader:Bool = (!hasKhronosExtension && KHR_BLEND_MODES.contains(blend)) || SHADER_REQUIRED_BLEND_MODES.contains(blend);

    // Fallback to the shader implementation if the device doesn't support `KHR_blend_equation_advanced`, or if
    // the specified blend mode requires the shader.
    if (shouldUseShader)
    {
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

      _backgroundFrame.frame.set(0, 0, this.width, this.height);

      // Clear the camera's graphics
      // It'll get redrawn anyway
      this.clearDrawStack();
      this.canvas.graphics.clear();

      _blendRenderTexture.init(this.width, this.height);
      _blendRenderTexture.drawToCamera((camera, frameMatrix) ->
      {
        var pivotX:Float = width / 2;
        var pivotY:Float = height / 2;

        frameMatrix.copyFrom(matrix);
        frameMatrix.translate(-pivotX, -pivotY);
        frameMatrix.scale(this.scaleX, this.scaleY);
        frameMatrix.translate(pivotX, pivotY);
        camera.drawPixels(frame, pixels, frameMatrix, transform, null, smoothing, shader);
      });
      _blendRenderTexture.render();

      _blendShader.sourceSwag = _blendRenderTexture.graphic.bitmap;
      _blendShader.backgroundSwag = _cameraTexture;

      _blendShader.blendSwag = blend;
      _blendShader.updateViewInfo(width, height, this);

      _backgroundFrame.parent.bitmap = _blendRenderTexture.graphic.bitmap;

      _backgroundRenderTexture.init(Std.int(this.width * Lib.current.stage.window.scale), Std.int(this.height * Lib.current.stage.window.scale));
      _backgroundRenderTexture.drawToCamera((camera, matrix) ->
      {
        camera.zoom = this.zoom;
        matrix.scale(Lib.current.stage.window.scale, Lib.current.stage.window.scale);
        camera.drawPixels(_backgroundFrame, null, matrix, canvas.transform.colorTransform, null, false, _blendShader);
      });

      _backgroundRenderTexture.render();

      // Resize the frame so it always fills the screen
      _cameraMatrix.identity();
      _cameraMatrix.scale(1 / (this.scaleX * Lib.current.stage.window.scale), 1 / (this.scaleY * Lib.current.stage.window.scale));
      _cameraMatrix.translate(((width - width / this.scaleX) * 0.5), ((height - height / this.scaleY) * 0.5));

      super.drawPixels(_backgroundRenderTexture.graphic.imageFrame.frame, null, _cameraMatrix, null, null, smoothing, null);
    }
    else
    {
      super.drawPixels(frame, pixels, matrix, transform, blend, smoothing, shader);
    }
  }

  override function startQuadBatch(graphic:FlxGraphic, colored:Bool, hasColorOffsets:Bool = false, ?blend:BlendMode, smooth:Bool = false,
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

  override function startTrianglesBatch(graphic:FlxGraphic, smoothing:Bool = false, isColored:Bool = false, ?blend:BlendMode, ?hasColorOffsets:Bool,
      ?shader:FlxShader):FlxDrawTrianglesItem
  {
    // Can't batch complex non-coherent blends, so always force a new batch
    if (hasKhronosExtension
      && !(OpenGLRenderer.__coherentBlendsSupported ?? false)
      && KHR_BLEND_MODES.contains(blend)) return getNewDrawTrianglesItem(graphic, smoothing, isColored, blend, hasColorOffsets, shader);

    return super.startTrianglesBatch(graphic, smoothing, isColored, blend, hasColorOffsets, shader);
  }

  override function destroy():Void
  {
    super.destroy();

    _blendRenderTexture.destroy();
    _backgroundRenderTexture.destroy();

    _cameraTexture.dispose();
  }
}
