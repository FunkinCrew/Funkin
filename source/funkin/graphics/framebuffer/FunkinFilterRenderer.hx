package funkin.graphics.framebuffer;

import animate.internal.FilterRenderer;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import funkin.graphics.FunkinSprite;
import openfl.display.BitmapData;
import openfl.filters.BitmapFilter;

using funkin.graphics.framebuffer.BitmapDataUtil;

/**
 * A helper for rendering filters on `FunkinSprite` instances.
 */
@:access(animate.FlxAnimate)
@:access(openfl.filters.BitmapFilter)
@:access(animate.internal.FilterRenderer)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.geom.ColorTransform)
@:access(openfl.display.BitmapData)
@:nullSafety
class FunkinFilterRenderer implements IFlxDestroyable
{
  /**
   * An optional key to use for the graphic.
   */
  public var graphicKey:String = '';

  /**
   * Graphic containing the current frame with filters.
   */
  public var graphic(default, null):Null<FlxGraphic>;

  var bitmapPool:Map<Int, Array<BitmapData>> = [];
  var parent:FunkinSprite;

  public function new(parent:FunkinSprite)
  {
    this.parent = parent;
  }

  /**
   * Apply filters to the current frame.
   * The result will be contained in the `graphic` variable.
   */
  public function applyFilters(?textureToUse:BitmapData):Void
  {
    parent.filtered = false;
    if (parent.filters == null || parent.filters.length < 1) return;

    var textureBitmap:BitmapData = textureToUse ?? parent._renderTexture.graphic.bitmap;

    var bounds:FlxRect = FlxRect.get().copyFromFlash(textureBitmap.rect);
    FilterRenderer.expandFilterBounds(bounds, parent.filters);
    parent.filterOffsets[0] = bounds.x;
    parent.filterOffsets[1] = bounds.y;

    var ceilWidth:Int = Math.ceil(bounds.width);
    var ceilHeight:Int = Math.ceil(bounds.height);

    if (graphic != null) putBitmap(graphic.bitmap);
    var bitmap:BitmapData = getBitmap(ceilWidth, ceilHeight);

    if (graphic == null)
    {
      if (!graphicKey.isBlank())
      {
        @:privateAccess
        graphic = new FlxGraphic(graphicKey, bitmap);
      }
      else
      {
        graphic = FlxGraphic.fromBitmapData(bitmap, false, null, false);
      }
    }
    else
    {
      graphic.bitmap = bitmap;
      graphic.imageFrame.frame.frame.set(0, 0, bitmap.width, bitmap.height);
    }

    var filterBmp1:Null<BitmapData> = null;
    var filterBmp2:Null<BitmapData> = null;

    var needsSecondBitmap:Bool = false;
    var needsPreserveObject:Bool = false;
    for (filter in parent.filters)
    {
      if (filter != null)
      {
        if (filter.__needSecondBitmapData) needsSecondBitmap = true;
        if (filter.__preserveObject) needsPreserveObject = true;
      }
    }

    if (needsSecondBitmap) filterBmp1 = getBitmap(graphic.width, graphic.height);
    if (needsPreserveObject) filterBmp2 = getBitmap(filterBmp1?.width ?? 1, filterBmp1?.height ?? 1);

    var result:BitmapData = _applyFilters(graphic.bitmap, textureBitmap, parent.filters, filterBmp1, filterBmp2, bounds);

    if (result != graphic.bitmap)
    {
      var previous:BitmapData = graphic.bitmap;
      graphic.bitmap = result;
      if (previous != null) putBitmap(previous);
      if (filterBmp1 == result) filterBmp1 = null;
    }

    if (filterBmp1 != null) putBitmap(filterBmp1);
    if (filterBmp2 != null) putBitmap(filterBmp2);

    bounds.put();
    parent.filtered = true;
  }

  @:nullSafety(Off)
  function _applyFilters(target:BitmapData,
    bmp:BitmapData,
    filters:Array<BitmapFilter>,
    target1:Null<BitmapData>,
    target2:Null<BitmapData>,
    bounds:FlxRect):BitmapData
  {
    var renderer = FilterRenderer.renderer;

    var bitmap:BitmapData = target;
    var bitmap2:BitmapData = target1 ?? bmp;
    var bitmap3:BitmapData = target2 ?? bmp;

    renderer.__setBlendMode(NORMAL);
    renderer.__worldAlpha = 1;
    if (renderer.__worldTransform == null)
    {
      renderer.__worldTransform = new openfl.geom.Matrix();
      renderer.__worldColorTransform = new openfl.geom.ColorTransform();
    }
    renderer.__worldTransform.identity();
    renderer.__worldColorTransform.__identity();
    bmp.__renderTransform.identity();
    bmp.__renderTransform.translate(-bounds.x, -bounds.y);
    renderer.setShader(renderer.__defaultShader);
    renderer.__setRenderTarget(bitmap);
    renderer.__scissorRect(null);
    renderer.__renderFilterPass(bmp, renderer.__defaultDisplayShader, true);

    var swapTarg:Bool = target1 != null;

    for (filter in filters)
    {
      if (filter == null) continue;

      if (swapTarg && !filter.__preserveObject && filter.__numShaderPasses == 1)
      {
        var shader = filter.__initShader(renderer, 0, null);
        renderer.__setBlendMode(filter.__shaderBlendMode);
        renderer.__setRenderTarget(bitmap2);
        renderer.__renderFilterPass(bitmap, shader, filter.__smooth);
        filter.__renderDirty = false;

        var swap:BitmapData = bitmap;
        bitmap = bitmap2;
        bitmap2 = swap;
      }
      else
      {
        bitmap = FilterRenderer.__renderGpuFilter(filter, bitmap, bitmap2, bitmap3);
      }
    }

    renderer.__setBlendMode(NORMAL);

    return bitmap;
  }

  /**
   * Pool key packed into an Int so per-frame lookups do not build strings.
   */
  static inline function poolKey(width:Int, height:Int):Int
  {
    return (width << 16) | (height & 0xFFFF);
  }

  function getBitmap(width:Int, height:Int):BitmapData
  {
    final id:Int = poolKey(width, height);
    var bitmaps:Null<Array<BitmapData>> = bitmapPool.get(id);
    if (bitmaps == null)
    {
      bitmaps = [];
      bitmapPool.set(id, bitmaps);
    }
    var pooled:Null<BitmapData> = bitmaps.pop();
    var bitmap:BitmapData = pooled ?? new BitmapData(width, height, true, 0).toGPU();
    bitmap.__fillRect(bitmap.rect, 0, true);
    return bitmap;
  }

  function putBitmap(bitmap:BitmapData):Void
  {
    final id:Int = poolKey(bitmap.width, bitmap.height);
    var bitmaps:Null<Array<BitmapData>> = bitmapPool.get(id);
    if (bitmaps == null)
    {
      bitmaps = [];
      bitmapPool.set(id, bitmaps);
    }
    if (!bitmaps.contains(bitmap)) bitmaps.push(bitmap);
  }

  /**
   * Clean up memory.
   */
  public function destroy():Void
  {
    for (bitmaps in bitmapPool.values())
    {
      for (bitmap in bitmaps)
      {
        if (bitmap.__texture != null) bitmap.__texture.dispose();
        bitmap.dispose();
      }
    }
  }
}
