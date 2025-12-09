package funkin.graphics;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import lime.graphics.cairo.Cairo;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.DisplayObjectRenderer;
import openfl.display.Graphics;
import openfl.display.OpenGLRenderer;
import openfl.display3D.Context3D;
import openfl.filters.BitmapFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
#if (js && html5)
import lime._internal.graphics.ImageCanvasUtil;
import openfl.display.CanvasRenderer;
import openfl.display._internal.CanvasGraphics as GfxRenderer;
#else
import openfl.display.CairoRenderer;
import openfl.display._internal.CairoGraphics as GfxRenderer;
#end

/**
 * A modified `FlxSprite` that supports filters.
 * The name's pretty much self-explanatory.
 */
@:nullSafety
@:access(openfl.geom.Rectangle)
@:access(openfl.filters.BitmapFilter)
@:access(flixel.graphics.frames.FlxFrame)
class FlxFilteredSprite extends FlxSprite
{
  @:noCompletion var _renderer:FlxAnimateFilterRenderer = new FlxAnimateFilterRenderer();

  @:noCompletion var _filterMatrix:FlxMatrix = new FlxMatrix();

  /**
   * An `Array` of shader filters (aka `BitmapFilter`).
   */
  public var filters(default, set):Null<Array<BitmapFilter>>;

  /**
   * a flag to update the image with the filters.
   * Useful when trying to render a shader at all times.
   */
  public var filterDirty:Bool = false;

  @:noCompletion var filtered:Bool = false;

  // These appear to be a little troublesome to null safe.
  @:nullSafety(Off)
  @:noCompletion var _blankFrame:FlxFrame;

  @:nullSafety(Off)
  var _filterBmp1:BitmapData;
  @:nullSafety(Off)
  var _filterBmp2:BitmapData;

  override public function update(elapsed:Float)
  {
    super.update(elapsed);
    if (!filterDirty && filters != null)
    {
      for (filter in filters)
      {
        if (filter.__renderDirty)
        {
          filterDirty = true;
          break;
        }
      }
    }
  }

  @:noCompletion
  override function initVars():Void
  {
    super.initVars();
    _filterMatrix = new FlxMatrix();
    filters = null;
    filtered = false;
  }

  override public function draw():Void
  {
    checkEmptyFrame();

    if (alpha == 0 || _frame.type == FlxFrameType.EMPTY) return;

    if (dirty) // rarely
      calcFrame(useFramePixels);

    if (filterDirty) filterFrame();

    for (camera in cameras)
    {
      if (!camera.visible || !camera.exists || !isOnScreen(camera)) continue;

      getScreenPosition(_point, camera).subtractPoint(offset);

      if (isSimpleRender(camera)) drawSimple(camera);
      else
        drawComplex(camera);

      #if FLX_DEBUG
      FlxBasic.visibleCount++;
      #end
    }

    #if FLX_DEBUG
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
  }

  @:noCompletion
  override function drawComplex(camera:FlxCamera):Void
  {
    _frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
    _matrix.concat(_filterMatrix);
    _matrix.translate(-origin.x, -origin.y);
    _matrix.scale(scale.x, scale.y);

    if (bakedRotationAngle <= 0)
    {
      updateTrig();

      if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
    }

    _point.add(origin.x, origin.y);
    _matrix.translate(_point.x, _point.y);

    if (isPixelPerfectRender(camera))
    {
      _matrix.tx = Math.floor(_matrix.tx);
      _matrix.ty = Math.floor(_matrix.ty);
    }

    camera.drawPixels((filtered) ? _blankFrame : _frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
  }

  @:noCompletion
  function filterFrame()
  {
    filterDirty = false;
    _filterMatrix.identity();

    if (filters != null && filters.length > 0)
    {
      _flashRect.setEmpty();

      for (filter in filters)
      {
        _flashRect.__expand(-filter.__leftExtension,
          -filter.__topExtension, filter.__leftExtension
          + filter.__rightExtension,
          filter.__topExtension
          + filter.__bottomExtension);
      }
      _flashRect.width += frameWidth;
      _flashRect.height += frameHeight;
      @:nullSafety(Off)
      if (_blankFrame == null) _blankFrame = new FlxFrame(null);

      if (_blankFrame.parent == null || _flashRect.width > _blankFrame.parent.width || _flashRect.height > _blankFrame.parent.height)
      {
        if (_blankFrame.parent != null)
        {
          _blankFrame.parent.destroy();
          _filterBmp1.dispose();
          _filterBmp2.dispose();
        }

        _blankFrame.parent = FlxGraphic.fromRectangle(Math.ceil(_flashRect.width * 1.25), Math.ceil(_flashRect.height * 1.25), 0, true);
        _filterBmp1 = new BitmapData(_blankFrame.parent.width, _blankFrame.parent.height, 0);
        _filterBmp2 = new BitmapData(_blankFrame.parent.width, _blankFrame.parent.height, 0);
      }
      _blankFrame.offset.copyFrom(_frame.offset);
      @:nullSafety(Off)
      _blankFrame.parent.bitmap = _renderer.applyFilter(_blankFrame.parent.bitmap, _filterBmp1, _filterBmp2, frame.parent.bitmap, filters, _flashRect,
        frame.frame.copyToFlash());
      _blankFrame.frame = FlxRect.get(0, 0, _blankFrame.parent.bitmap.width, _blankFrame.parent.bitmap.height);
      _filterMatrix.translate(_flashRect.x, _flashRect.y);
      _frame = _blankFrame.copyTo();
      filtered = true;
    }
    else
    {
      resetFrame();
      filtered = false;
    }
  }

  @:noCompletion
  function set_filters(value:Null<Array<BitmapFilter>>)
  {
    if (filters != value) filterDirty = true;

    return filters = value;
  }

  @:noCompletion
  override function set_frame(value:FlxFrame)
  {
    if (value != frame) filterDirty = true;

    return super.set_frame(value);
  }

  override public function destroy()
  {
    super.destroy();
  }
}

@:noCompletion
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.filters.BitmapFilter)
@:access(openfl.geom.Rectangle)
@:access(openfl.display.Stage)
@:access(openfl.display.Graphics)
@:access(openfl.display.Shader)
@:access(openfl.display.BitmapData)
@:access(openfl.geom.ColorTransform)
@:access(openfl.display.DisplayObject)
@:access(openfl.display3D.Context3D)
@:access(openfl.display.CanvasRenderer)
@:access(openfl.display.CairoRenderer)
@:access(openfl.display3D.Context3D)
class FlxAnimateFilterRenderer
{
  var renderer:OpenGLRenderer;
  var context:Context3D;

  public function new()
  {
    // context = new openfl.display3D.Context3D(null);
    renderer = new OpenGLRenderer(FlxG.game.stage.context3D);
    renderer.__worldTransform = new Matrix();
    renderer.__worldColorTransform = new ColorTransform();
  }

  @:noCompletion function setRenderer(renderer:DisplayObjectRenderer, rect:Rectangle)
  {
    @:privateAccess
    if (true)
    {
      var displayObject = FlxG.game;
      var pixelRatio = FlxG.game.stage.__renderer.__pixelRatio;

      var offsetX = rect.x > 0 ? Math.ceil(rect.x) : Math.floor(rect.x);
      var offsetY = rect.y > 0 ? Math.ceil(rect.y) : Math.floor(rect.y);
      if (renderer.__worldTransform == null)
      {
        renderer.__worldTransform = new Matrix();
        renderer.__worldColorTransform = new ColorTransform();
      }
      if (displayObject.__cacheBitmapColorTransform == null) displayObject.__cacheBitmapColorTransform = new ColorTransform();

      renderer.__stage = displayObject.stage;

      renderer.__allowSmoothing = true;
      renderer.__setBlendMode(NORMAL);
      renderer.__worldAlpha = 1 / displayObject.__worldAlpha;

      renderer.__worldTransform.identity();
      renderer.__worldTransform.invert();
      renderer.__worldTransform.concat(new Matrix());
      renderer.__worldTransform.tx -= offsetX;
      renderer.__worldTransform.ty -= offsetY;
      renderer.__worldTransform.scale(pixelRatio, pixelRatio);

      renderer.__pixelRatio = pixelRatio;
    }
  }

  public function applyFilter(target:BitmapData = null, target1:BitmapData = null, target2:BitmapData = null, bmp:BitmapData, filters:Array<BitmapFilter>,
      rect:Rectangle, bmpRect:Rectangle)
  {
    if (filters == null || filters.length == 0) return bmp;

    renderer.__setBlendMode(NORMAL);
    renderer.__worldAlpha = 1;

    if (renderer.__worldTransform == null)
    {
      renderer.__worldTransform = new Matrix();
      renderer.__worldColorTransform = new ColorTransform();
    }
    renderer.__worldTransform.identity();
    renderer.__worldColorTransform.__identity();

    var bitmap:BitmapData = (target == null) ? new BitmapData(Math.ceil(rect.width * 1.25), Math.ceil(rect.height * 1.25), true, 0) : target;

    var bitmap2 = (target1 == null) ? new BitmapData(Math.ceil(rect.width * 1.25), Math.ceil(rect.height * 1.25), true, 0) : target1,
      bitmap3 = (target2 == null) ? bitmap2.clone() : target2;
    renderer.__setRenderTarget(bitmap);

    bmp.__renderTransform.translate(Math.abs(rect.x) - bmpRect.x, Math.abs(rect.y) - bmpRect.y);
    bmpRect.x = Math.abs(rect.x);
    bmpRect.y = Math.abs(rect.y);

    var bestResolution = renderer.__context3D.__backBufferWantsBestResolution;
    renderer.__context3D.__backBufferWantsBestResolution = false;
    renderer.__scissorRect(bmpRect);
    renderer.__renderFilterPass(bmp, renderer.__defaultDisplayShader, true);
    renderer.__scissorRect();

    renderer.__context3D.__backBufferWantsBestResolution = bestResolution;

    bmp.__renderTransform.identity();

    var shader, cacheBitmap = null;
    for (filter in filters)
    {
      if (filter.__preserveObject)
      {
        renderer.__setRenderTarget(bitmap3);
        renderer.__renderFilterPass(bitmap, renderer.__defaultDisplayShader, filter.__smooth);
      }

      for (i in 0...filter.__numShaderPasses)
      {
        shader = filter.__initShader(renderer, i, (filter.__preserveObject) ? bitmap3 : null);
        renderer.__setBlendMode(filter.__shaderBlendMode);
        renderer.__setRenderTarget(bitmap2);
        renderer.__renderFilterPass(bitmap, shader, filter.__smooth);

        cacheBitmap = bitmap;
        bitmap = bitmap2;
        bitmap2 = cacheBitmap;
      }
      filter.__renderDirty = false;
    }
    if (target1 == null) bitmap2.dispose();
    if (target2 == null) bitmap3.dispose();

    // var gl = renderer.__gl;

    // var renderBuffer = bitmap.getTexture(renderer.__context3D);
    // @:privateAccess
    // gl.readPixels(0, 0, bitmap.width, bitmap.height, renderBuffer.__format, gl.UNSIGNED_BYTE, bitmap.image.data);
    // bitmap.image.version = 0;
    // @:privateAccess
    // bitmap.__textureVersion = -1;

    return bitmap;
  }

  public function applyBlend(blend:BlendMode, bitmap:BitmapData)
  {
    bitmap.__update(false, true);
    var bmp = new BitmapData(bitmap.width, bitmap.height, 0);

    #if (js && html5)
    ImageCanvasUtil.convertToCanvas(bmp.image);
    @:privateAccess
    var renderer = new CanvasRenderer(bmp.image.buffer.__srcContext);
    #else
    var renderer = new CairoRenderer(new Cairo(bmp.getSurface()));
    #end

    // setRenderer(renderer, bmp.rect);

    var m = new Matrix();
    var c = new ColorTransform();
    renderer.__allowSmoothing = true;
    renderer.__overrideBlendMode = blend;
    renderer.__worldTransform = m;
    renderer.__worldAlpha = 1;
    renderer.__worldColorTransform = c;

    renderer.__setBlendMode(blend);
    #if (js && html5)
    bmp.__drawCanvas(bitmap, renderer);
    #else
    bmp.__drawCairo(bitmap, renderer);
    #end

    return bitmap;
  }

  public function graphicstoBitmapData(gfx:Graphics)
  {
    if (gfx.__bounds == null) return null;
    // var cacheRTT = renderer.__context3D.__state.renderToTexture;
    // var cacheRTTDepthStencil = renderer.__context3D.__state.renderToTextureDepthStencil;
    // var cacheRTTAntiAlias = renderer.__context3D.__state.renderToTextureAntiAlias;
    // var cacheRTTSurfaceSelector = renderer.__context3D.__state.renderToTextureSurfaceSelector;

    // var bmp = new BitmapData(Math.ceil(gfx.__width), Math.ceil(gfx.__height), 0);
    // renderer.__context3D.setRenderToTexture(bmp.getTexture(renderer.__context3D));
    // gfx.__owner.__renderTransform.identity();
    // gfx.__renderTransform.identity();
    // Context3DGraphics.render(gfx, renderer);
    GfxRenderer.render(gfx, cast renderer.__softwareRenderer);
    var bmp = gfx.__bitmap;

    gfx.__bitmap = null;

    // if (cacheRTT != null)
    // {
    // 	renderer.__context3D.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
    // }
    // else
    // {
    // 	renderer.__context3D.setRenderToBackBuffer();
    // }

    return bmp;
  }
}
