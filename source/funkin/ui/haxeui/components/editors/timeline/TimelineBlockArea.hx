package funkin.ui.haxeui.components.editors.timeline;

#if FEATURE_CAMERA_EDITOR
import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMatrix;
import flixel.util.FlxColor;
import haxe.ui.Toolkit;
import haxe.ui.assets.ImageInfo;
import haxe.ui.containers.Box;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;

/**
 * The content area of the timeline (batched)
 */
class TimelineBlockArea extends Box
{
  /**
   * Size of each rounded rect in the generated texture.
   */
  static inline var SLICE_SIZE:Int = 16;
  static inline var SLICE_CORNER:Int = 6;

  static inline var SLICE_MID:Int = 7;
  static inline var SLICE_MID_SIZE:Int = 2;

  static inline var FILL_X:Int = 0;
  static inline var RING_THIN_X:Int = SLICE_SIZE;
  static inline var RING_THICK_X:Int = SLICE_SIZE * 2;

  static var atlas:Null<FlxGraphic> = null;
  static var iconFrames:Map<String, FlxFrame> = [];
  static var requestedImages:Map<String, Bool> = [];

  /**
   * The viewport whose blocks get drawn here.
   */
  public var viewport:Null<TimelineViewport> = null;

  var scratchFrame:Null<FlxFrame> = null;
  var quadMatrix:FlxMatrix = new FlxMatrix();
  var quadTransform:ColorTransform = new ColorTransform();

  var clipLeft:Float = 0;
  var clipTop:Float = 0;
  var clipRight:Float = 0;
  var clipBottom:Float = 0;

  public function new()
  {
    super();
    ensureAtlas();
    for (path in TimelineEventBlock.ICON_RESOURCES) requestImage(path);
    requestImage(TimelineEventBlock.TRIANGLE_RESOURCE);
  }

  override public function draw():Void
  {
    drawBlocks();
    super.draw();
  }

  function drawBlocks():Void
  {
    var vp:Null<TimelineViewport> = viewport;
    ensureAtlas();
    if (vp == null || hidden || atlas == null) return;

    var scaleX:Float = Toolkit.scaleX;
    var scaleY:Float = Toolkit.scaleY;
    var originX:Float = _surface.x;
    var originY:Float = _surface.y;

    clipLeft = originX;
    clipTop = originY;
    clipRight = originX + componentWidth * scaleX;
    clipBottom = originY + componentHeight * scaleY;
    if (clipRight <= clipLeft || clipBottom <= clipTop) return;

    var blockHeight:Float = vp.blockHeight * scaleY;

    for (camera in cameras)
    {
      if (camera == null || !camera.visible || !camera.exists) continue;

      for (block in vp.eventBlocks)
      {
        if (block.hidden) continue;
        drawBody(camera, vp, block, originX + block.drawLeft * scaleX, originY + block.blockTop * scaleY, block.drawWidth * scaleX, blockHeight, scaleX);
      }

      // Instant events get a faint triangle.
      var triangle:Null<FlxFrame> = getImage(TimelineEventBlock.TRIANGLE_RESOURCE);
      if (triangle != null)
      {
        for (block in vp.eventBlocks)
        {
          if (block.hidden || !block.instant) continue;
          var size:Float = iconSize(vp, block);
          var w:Float = block.blockWidth >= maxIconSize(vp) + iconPadding(vp) * 2 ? size / 2 : block.blockWidth;
          drawImage(camera, triangle, originX + block.blockLeft * scaleX, originY + block.blockTop * scaleY, w * scaleX, blockHeight, bodyColor(vp, block),
            TimelineEventBlock.TRIANGLE_OPACITY);
        }
      }

      for (kind => path in TimelineEventBlock.ICON_RESOURCES)
      {
        var icon:Null<FlxFrame> = getImage(path);
        if (icon == null) continue;
        for (block in vp.eventBlocks)
        {
          if (block.hidden || block.eventData.eventKind != kind) continue;
          var size:Float = iconSize(vp, block);
          var left:Float = block.blockWidth >= maxIconSize(vp) + iconPadding(vp) * 2 ? iconPadding(vp) : (block.blockWidth - size) / 2;
          var top:Float = (vp.blockHeight - size) / 2;
          drawImage(camera, icon, originX + (block.blockLeft + left) * scaleX, originY + (block.blockTop + top) * scaleY, size * scaleX, size * scaleY,
            FlxColor.WHITE, 1);
        }
      }

      for (block in vp.eventBlocks)
      {
        if (block.hidden || block.eventData.eventKind != funkin.play.event.CustomSongEvent.KIND) continue;
        var tag:Null<FlxFrame> = tagFrame(funkin.play.event.CustomSongEvent.tagFor(block.eventData.getString('name')));
        if (tag == null) continue;
        var size:Float = iconSize(vp, block);
        var tagWidth:Float = size * tag.frame.width / tag.frame.height;
        var left:Float = block.blockWidth >= tagWidth + iconPadding(vp) * 2 ? iconPadding(vp) : (block.blockWidth - tagWidth) / 2;
        var top:Float = (vp.blockHeight - size) / 2;
        drawImage(camera, tag, originX + (block.blockLeft + left) * scaleX, originY + (block.blockTop + top) * scaleY, tagWidth * scaleX, size * scaleY,
          FlxColor.WHITE, 1);
      }
    }
  }

  static var tagFrames:Map<String, FlxFrame> = [];

  static function tagFrame(tag:String):Null<FlxFrame>
  {
    if (tag.length == 0) return null;
    var cached:Null<FlxFrame> = tagFrames.get(tag);
    if (cached != null) return cached;

    var text:flixel.text.FlxText = new flixel.text.FlxText(0, 0, 0, tag, 32);
    text.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 32, FlxColor.WHITE, LEFT, flixel.text.FlxText.FlxTextBorderStyle.OUTLINE,
      FlxColor.BLACK);
    text.borderSize = 2;
    text.drawFrame(true);
    var graphic:FlxGraphic = FlxGraphic.fromBitmapData(text.pixels.clone(), false, 'timeline-custom-event-tag-$tag', false);
    graphic.persist = true;
    text.destroy();

    var frame:FlxFrame = graphic.imageFrame.frame;
    tagFrames.set(tag, frame);
    return frame;
  }

  inline function maxIconSize(vp:TimelineViewport):Float
  {
    return vp.blockHeight - 4;
  }

  inline function iconPadding(vp:TimelineViewport):Float
  {
    return maxIconSize(vp) * 0.05;
  }

  function iconSize(vp:TimelineViewport, block:TimelineEventBlock):Float
  {
    var maxSize:Float = maxIconSize(vp);
    if (block.blockWidth >= maxSize + iconPadding(vp) * 2) return maxSize;
    return Math.max(16, block.blockWidth);
  }

  function layerColor(vp:TimelineViewport, block:TimelineEventBlock):FlxColor
  {
    if (block.layerIndex >= 0 && block.layerIndex < vp.layers.length) return FlxColor.fromInt(vp.layers[block.layerIndex].color);
    return FlxColor.fromInt(0x888888);
  }

  function bodyColor(vp:TimelineViewport, block:TimelineEventBlock):FlxColor
  {
    var color:FlxColor = layerColor(vp, block);
    return block.selected ? color.getLightened(0.3) : color;
  }

  function drawBody(camera:FlxCamera, vp:TimelineViewport, block:TimelineEventBlock, x:Float, y:Float, w:Float, h:Float, scale:Float):Void
  {
    var fill:FlxColor = bodyColor(vp, block);
    var fillAlpha:Float = block.selected ? 0.6 : 0.4;
    var border:FlxColor = block.selected ? FlxColor.WHITE : layerColor(vp, block);
    var borderSize:Float = (block.selected ? 2 : 1) * scale;

    if (block.instant)
    {
      // Instant events are square.
      drawAtlas(camera, SLICE_MID, SLICE_MID, 1, 1, x, y, w, h, fill, fillAlpha);
      drawAtlas(camera, SLICE_MID, SLICE_MID, 1, 1, x, y, w, borderSize, border, 1);
      drawAtlas(camera, SLICE_MID, SLICE_MID, 1, 1, x, y + h - borderSize, w, borderSize, border, 1);
      drawAtlas(camera, SLICE_MID, SLICE_MID, 1, 1, x, y + borderSize, borderSize, h - borderSize * 2, border, 1);
      drawAtlas(camera, SLICE_MID, SLICE_MID, 1, 1, x + w - borderSize, y + borderSize, borderSize, h - borderSize * 2, border, 1);
    }
    else
    {
      drawNineSlice(camera, FILL_X, x, y, w, h, fill, fillAlpha);
      drawNineSlice(camera, block.selected ? RING_THICK_X : RING_THIN_X, x, y, w, h, border, 1);
    }

    if (block.hoverEdge != null)
    {
      var edge:Float = 2 * scale;
      var realLeft:Float = x + (block.blockLeft - block.drawLeft) * scale;
      switch (block.hoverEdge)
      {
        case LEFT_EDGE:
          drawAtlas(camera, SLICE_MID, SLICE_MID, 1, 1, realLeft, y, edge, h, FlxColor.WHITE, 1);
        case RIGHT_EDGE:
          drawAtlas(camera, SLICE_MID, SLICE_MID, 1, 1, realLeft + block.blockWidth * scale - edge, y, edge, h, FlxColor.WHITE, 1);
        default:
      }
    }
  }

  /**
   * Draws a rounded rect from the atlas.
   */
  function drawNineSlice(camera:FlxCamera, sliceX:Int, x:Float, y:Float, w:Float, h:Float, color:FlxColor, alpha:Float):Void
  {
    var cw:Float = Math.min(SLICE_CORNER, Math.floor(w / 2));
    var ch:Float = Math.min(SLICE_CORNER, Math.floor(h / 2));
    var midW:Float = w - cw * 2;
    var midH:Float = h - ch * 2;
    var rightSrc:Int = sliceX + SLICE_SIZE - SLICE_CORNER;
    var bottomSrc:Int = SLICE_SIZE - SLICE_CORNER;

    // Corners
    drawAtlas(camera, sliceX, 0, SLICE_CORNER, SLICE_CORNER, x, y, cw, ch, color, alpha);
    drawAtlas(camera, rightSrc, 0, SLICE_CORNER, SLICE_CORNER, x + w - cw, y, cw, ch, color, alpha);
    drawAtlas(camera, sliceX, bottomSrc, SLICE_CORNER, SLICE_CORNER, x, y + h - ch, cw, ch, color, alpha);
    drawAtlas(camera, rightSrc, bottomSrc, SLICE_CORNER, SLICE_CORNER, x + w - cw, y + h - ch, cw, ch, color, alpha);

    // Edges
    if (midW > 0)
    {
      drawAtlas(camera, sliceX + SLICE_MID, 0, SLICE_MID_SIZE, SLICE_CORNER, x + cw, y, midW, ch, color, alpha);
      drawAtlas(camera, sliceX + SLICE_MID, bottomSrc, SLICE_MID_SIZE, SLICE_CORNER, x + cw, y + h - ch, midW, ch, color, alpha);
    }
    if (midH > 0)
    {
      drawAtlas(camera, sliceX, SLICE_MID, SLICE_CORNER, SLICE_MID_SIZE, x, y + ch, cw, midH, color, alpha);
      drawAtlas(camera, rightSrc, SLICE_MID, SLICE_CORNER, SLICE_MID_SIZE, x + w - cw, y + ch, cw, midH, color, alpha);
    }

    // Middle
    if (midW > 0 && midH > 0)
    {
      drawAtlas(camera, sliceX + SLICE_MID, SLICE_MID, SLICE_MID_SIZE, SLICE_MID_SIZE, x + cw, y + ch, midW, midH, color, alpha);
    }
  }

  inline function drawAtlas(camera:FlxCamera, sx:Float, sy:Float, sw:Float, sh:Float, dx:Float, dy:Float, dw:Float, dh:Float, color:FlxColor, alpha:Float):Void
  {
    drawQuad(camera, atlas, 0, 0, sx, sy, sw, sh, dx, dy, dw, dh, color, alpha);
  }

  function drawImage(camera:FlxCamera, frame:FlxFrame, dx:Float, dy:Float, dw:Float, dh:Float, color:FlxColor, alpha:Float):Void
  {
    var rect = frame.frame;
    drawQuad(camera, frame.parent, rect.x, rect.y, 0, 0, rect.width, rect.height, dx, dy, dw, dh, color, alpha);
  }

  /**
   * Draws part of a graphic stretched over a screen rect.
   */
  function drawQuad(camera:FlxCamera, graphic:FlxGraphic, baseX:Float, baseY:Float, sx:Float, sy:Float, sw:Float, sh:Float, dx:Float, dy:Float, dw:Float,
      dh:Float, color:FlxColor, alpha:Float):Void
  {
    if (dw <= 0 || dh <= 0 || sw <= 0 || sh <= 0 || alpha <= 0) return;

    var x0:Float = Math.max(dx, clipLeft);
    var y0:Float = Math.max(dy, clipTop);
    var x1:Float = Math.min(dx + dw, clipRight);
    var y1:Float = Math.min(dy + dh, clipBottom);
    if (x1 <= x0 || y1 <= y0) return;

    var fx:Float = sw / dw;
    var fy:Float = sh / dh;
    var srcX:Float = baseX + sx + (x0 - dx) * fx;
    var srcY:Float = baseY + sy + (y0 - dy) * fy;
    var srcW:Float = (x1 - x0) * fx;
    var srcH:Float = (y1 - y0) * fy;

    var frame:FlxFrame = getScratchFrame(graphic);
    frame.frame = frame.frame.set(srcX, srcY, srcW, srcH);

    quadMatrix.identity();
    quadMatrix.scale((x1 - x0) / srcW, (y1 - y0) / srcH);
    quadMatrix.translate(x0, y0);

    quadTransform.redMultiplier = color.redFloat;
    quadTransform.greenMultiplier = color.greenFloat;
    quadTransform.blueMultiplier = color.blueFloat;
    quadTransform.alphaMultiplier = alpha;

    camera.drawPixels(frame, null, quadMatrix, quadTransform, null, false);
  }

  /**
   * Returns a reusable frame for the given graphic.
   */
  function getScratchFrame(graphic:FlxGraphic):FlxFrame
  {
    if (scratchFrame == null || scratchFrame.parent != graphic)
    {
      scratchFrame = new FlxFrame(graphic);
      scratchFrame.frame = flixel.math.FlxRect.get(0, 0, 1, 1);
    }
    return scratchFrame;
  }

  /**
   * The loaded image for a path, or null while it loads.
   */
  static function getImage(path:String):Null<FlxFrame>
  {
    var frame:Null<FlxFrame> = iconFrames.get(path);
    if (frame != null && (frame.parent == null || frame.parent.isDestroyed))
    {
      iconFrames.remove(path);
      requestedImages.remove(path);
      requestImage(path, true);
      return null;
    }
    if (frame == null) requestImage(path);
    return frame;
  }

  static function requestImage(path:String, skipCache:Bool = false):Void
  {
    if (requestedImages.exists(path)) return;
    requestedImages.set(path, true);
    Toolkit.assets.getImage(path, function(info:ImageInfo):Void
    {
      if (info == null || info.data == null) return;
      var frame:FlxFrame = info.data;
      if (frame.parent == null || frame.parent.isDestroyed) return;
      iconFrames.set(path, frame);
    }, !skipCache);
  }


  /**
   * Builds the texture with a filled rounded rect and two outlines.
   */
  static function ensureAtlas():Void
  {
    if (atlas != null && !atlas.isDestroyed && atlas.bitmap != null) return;

    var bitmap:BitmapData = new BitmapData(SLICE_SIZE * 3, SLICE_SIZE, true, 0x0);
    paintRoundedRect(bitmap, FILL_X, 0);
    paintRoundedRect(bitmap, RING_THIN_X, 1);
    paintRoundedRect(bitmap, RING_THICK_X, 2);

    atlas = FlxGraphic.fromBitmapData(bitmap, false, 'timelineBlockAtlas', false);
    atlas.persist = true;
    atlas.destroyOnNoUse = false;
  }

  /**
   * Paints one white rounded rect, filled when `ring` is 0, otherwise an outline that many pixels thick.
   */
  static function paintRoundedRect(bitmap:BitmapData, offsetX:Int, ring:Int):Void
  {
    var radius:Float = TimelineEventBlock.CORNER_RADIUS;
    var samples:Int = 4;
    for (py in 0...SLICE_SIZE)
    {
      for (px in 0...SLICE_SIZE)
      {
        var covered:Int = 0;
        for (sy in 0...samples)
        {
          for (sx in 0...samples)
          {
            var x:Float = px + (sx + 0.5) / samples;
            var y:Float = py + (sy + 0.5) / samples;
            var inside:Bool = insideRoundedRect(x, y, 0, SLICE_SIZE, radius);
            if (inside && ring > 0) inside = !insideRoundedRect(x, y, ring, SLICE_SIZE - ring, Math.max(0, radius - ring));
            if (inside) covered++;
          }
        }
        var alpha:Int = Std.int(255 * covered / (samples * samples));
        bitmap.setPixel32(offsetX + px, py, (alpha << 24) | 0xFFFFFF);
      }
    }
  }

  static function insideRoundedRect(x:Float, y:Float, min:Float, max:Float, radius:Float):Bool
  {
    if (x < min || y < min || x > max || y > max) return false;
    var cx:Float = Math.max(min + radius, Math.min(x, max - radius));
    var cy:Float = Math.max(min + radius, Math.min(y, max - radius));
    var dx:Float = x - cx;
    var dy:Float = y - cy;
    return dx * dx + dy * dy <= radius * radius;
  }
}
#end
