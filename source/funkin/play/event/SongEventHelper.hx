package funkin.play.event;

import flixel.tweens.FlxEase;
import openfl.display.BitmapData;
import flixel.FlxSprite;
import funkin.assets.FunkinBitmapFrontend;

class SongEventHelper
{
  public static var EASE_CANVAS_SIZE:Int = 200;

  /**
   * A list of all the easing functions available to song events.
   * TODO: Make this an enum to easily pair it with the corresponding functions?
   */
  public static final EASE_TYPES:Array<String> = [
    'sine',
    'quad',
    'cube',
    'quart',
    'quint',
    'expo',
    'smoothStep',
    'smootherStep',
    'elastic',
    'back',
    'bounce',
    'circ'
  ];

  public static final EASE_DIRS:Array<String> = ['In', 'Out', 'InOut'];
  public static var easeDotCache:Map<String, Array<FlxSprite>> = new Map<String, Array<FlxSprite>>();

  static function getEaseFunc(base:String, dir:String):Dynamic
  {
    var f = Reflect.field(FlxEase, base + dir);
    if (f != null) return f;
    return FlxEase.linear;
  }

  /**
   * The key a graph is drawn under, or null if the ease has no graph.
   */
  static function graphKey(key:String):Null<String>
  {
    if (key == 'linearIn' || key == 'linearInOut' || key == 'linearOut') return 'linear';
    if (key == 'linear' || key == 'INSTANT') return key;
    for (ease in EASE_TYPES)
    {
      for (dir in EASE_DIRS)
      {
        if (key == ease + dir) return key;
      }
    }
    return null;
  }

  /**
   * The graph for an ease.
   */
  static function easeGraphic(key:String):Null<flixel.graphics.FlxGraphic>
  {
    var drawKey:Null<String> = graphKey(key);
    if (drawKey == null) return null;
    var name:String = 'easegfx_' + drawKey;
    var gfx:Null<flixel.graphics.FlxGraphic> = FlxG.bitmap.get(name);
    if (gfx != null && FunkinBitmapFrontend.instance.isValid(gfx)) return gfx;
    var func:Dynamic = (drawKey == 'INSTANT') ? null : resolveEaseFuncForKey(drawKey);
    var bd:Null<BitmapData> = createBitmapFromFunc(func, drawKey);
    if (bd == null) return null;
    gfx = flixel.graphics.FlxGraphic.fromBitmapData(bd, false, name);
    gfx.destroyOnNoUse = false;
    return gfx;
  }

  public static function getEaseBitmap(key:String):Null<BitmapData>
  {
    return easeGraphic(key)?.bitmap;
  }

  static function getEaseRange(func:Dynamic, samples:Int):
    {min:Float, max:Float}
  {
    if (func == null || samples <= 0) return {
      min: 0.0,
      max: 1.0
    };

    var min:Float = 0.0;
    var max:Float = 1.0;
    var hasValue:Bool = false;

    for (i in 0...samples)
    {
      var t:Float = if (samples > 1) (i / (samples - 1)) else 0.0;
      var raw = func(t);
      if (Math.isNaN(raw)) continue;

      if (!hasValue)
      {
        min = raw;
        max = raw;
        hasValue = true;
      }
      else
      {
        if (raw < min) min = raw;
        if (raw > max) max = raw;
      }
    }

    if (!hasValue) return {
      min: 0.0,
      max: 1.0
    };
    return {
      min: min,
      max: max
    };
  }

  static function getEaseY(raw:Float, size:Int, range:
    {min:Float, max:Float}):Int
  {
    var v:Float = raw;
    var span = range.max - range.min;

    if (span > 0) v = (raw - range.min) / span;

    v = if (v < 0) 0 else if (v > 1) 1 else v;
    return Std.int((1 - v) * (size - 1));
  }

  static function createBitmapFromFunc(func:Dynamic, key:String, thickness:Int = 2):BitmapData
  {
    try
    {
      var size = EASE_CANVAS_SIZE;
      var bd = new BitmapData(size, size, false, 0xFF202223);
      if (key.toLowerCase() == 'instant') return bd;
      if (thickness < 1) thickness = 1;
      var half = Std.int(thickness / 2);
      var range = getEaseRange(func, size);

      // Draw horizontal lines at y=1 and y=0 for reference.
      var y1 = getEaseY(1, size, range);
      var y0 = getEaseY(0, size, range);
      bd.fillRect(new openfl.geom.Rectangle(0, y1 - half, size, thickness), 0xFF404040);
      bd.fillRect(new openfl.geom.Rectangle(0, y0 - half, size, thickness), 0xFF404040);

      var lastY:Int = -1;
      for (i in 0...size)
      {
        var t:Float = if (size > 1) (i / (size - 1)) else 0.0;
        var raw = func(t);
        if (!Math.isNaN(raw))
        {
          var y:Int = getEaseY(raw, size, range);
          if (lastY == -1)
          {
            for (xx in (
              i
              - half
            )...(
              i
              + half
              + 1
              )) if (xx >= 0 && xx < size) for (yy in (y - half)...(y + half + 1)) if (yy >= 0 && yy < size) bd.setPixel32(xx, yy, 0xFFFFFFFF);
          }
          else
          {
            var a = Std.int(Math.min(y, lastY));
            var b = Std.int(Math.max(y, lastY));
            for (xx in (
              i
              - half
            )...(i + half + 1)) if (xx >= 0 && xx < size) for (yy in a - half...b + half + 1) if (yy >= 0 && yy < size) bd.setPixel32(xx, yy, 0xFFFFFFFF);
          }
          lastY = y;
        }
      }
      return bd;
    }
    catch (e:Dynamic)
    {
      return null;
    }
  }

  public static function liveFrame(sprite:Null<FlxSprite>):Null<flixel.graphics.frames.FlxFrame>
  {
    if (sprite == null || !FunkinBitmapFrontend.instance.isValid(sprite.graphic)) return null;
    var frame:Null<flixel.graphics.frames.FlxFrame> = sprite.frame;
    return (frame != null && frame.frame != null) ? frame : null;
  }

  static var easeGraphCache:Map<String, FlxSprite> = new Map<String, FlxSprite>();

  public static function createSpriteFromKey(key:String, displayW:Int, displayH:Int):FlxSprite
  {
    var cacheKey:String = '$key:${displayW}x$displayH';
    var cached:Null<FlxSprite> = easeGraphCache.get(cacheKey);
    if (cached != null && liveFrame(cached) != null) return cached;
    if (cached != null) cached.destroy();
    easeGraphCache.remove(cacheKey);
    var gfx:Null<flixel.graphics.FlxGraphic> = easeGraphic(key);
    if (gfx == null) return null;
    var spr = new FlxSprite();
    spr.loadGraphic(gfx);
    if (gfx.width > 0 && gfx.height > 0) spr.scale.set(displayW / gfx.width, displayH / gfx.height);
    spr.updateHitbox();
    spr.antialiasing = false;
    easeGraphCache.set(cacheKey, spr);
    return spr;
  }

  public static function getOrCreateEaseDotSprites(key:String, frameCount:Int = 30, dotRadius:Int = 3, dotWidth:Int = 16):Array<FlxSprite>
  {
    if (easeDotCache.exists(key))
    {
      var valid:Bool = true;
      for (spr in easeDotCache.get(key))
      {
        if (liveFrame(spr) == null)
        {
          valid = false;
          break;
        }
      }
      if (valid) return easeDotCache.get(key);
      for (spr in easeDotCache.get(key))
        spr.destroy();
      easeDotCache.remove(key);
    }
    if (graphKey(key) == null) return null;
    var easeFunc:Dynamic = resolveEaseFuncForKey(key);
    var sizeH:Int = EASE_CANVAS_SIZE;
    var range = getEaseRange(easeFunc, sizeH);
    var sprites:Array<FlxSprite> = [];
    for (f in 0...frameCount)
    {
      var t:Float = if (frameCount > 1) (f / (frameCount - 1.0)) else 0.0;
      var raw:Float = 0.0;
      try
      {
        raw = if (easeFunc != null) easeFunc(t) else 0.0;
      }
      catch (e:Dynamic)
      {
        raw = FlxEase.linear(t);
      }
      if (Math.isNaN(raw)) raw = 0.0;
      var y:Int = getEaseY(raw, sizeH, range);
      var gfxName:String = 'ease_dot_' + key + '_' + f;
      var gfx:Null<flixel.graphics.FlxGraphic> = FlxG.bitmap.get(gfxName);
      if (gfx == null || !FunkinBitmapFrontend.instance.isValid(gfx))
      {
        var bd:BitmapData = new BitmapData(dotWidth, sizeH, false, 0xFF202223);
        var centerX:Int = Std.int(dotWidth / 2);
        for (dx in -dotRadius...dotRadius + 1) for (dy in -dotRadius...dotRadius + 1)
        {
          var px = centerX + dx;
          var py = y + dy;
          if (px >= 0 && px < dotWidth && py >= 0 && py < sizeH) if (dx * dx + dy * dy <= dotRadius * dotRadius) bd.setPixel32(px, py, 0xFFFFFFFF);
        }
        gfx = flixel.graphics.FlxGraphic.fromBitmapData(bd, false, gfxName);
      }
      gfx.destroyOnNoUse = false;
      var spr = new FlxSprite();
      spr.loadGraphic(gfx);
      sprites.push(spr);
    }
    easeDotCache.set(key, sprites);
    return sprites;
  }

  public static function resolveEaseDirFromKey(key:String):String
  {
    final DEFAULT_DIR:String = 'In';

    if (key == null || key == '') return DEFAULT_DIR;

    for (dir in EASE_DIRS)
    {
      if (key.endsWith(dir)) return dir;
    }

    return DEFAULT_DIR;
  }

  public static function resolveEaseTypeFromKey(key:String):Null<String>
  {
    if (key == null || key == '') return null;

    if (key.startsWith('linear')) return 'linear';
    if (key.startsWith('INSTANT')) return 'INSTANT';
    if (key.startsWith('CLASSIC')) return 'CLASSIC';

    for (type in EASE_TYPES)
    {
      if (key.startsWith(type)) return type;
    }

    return null;
  }

  static function resolveEaseFuncForKey(key:String):Dynamic
  {
    var lk = key;
    if (lk == null || lk.toLowerCase() == 'linear') return FlxEase.linear;
    if (lk.toLowerCase() == 'instant') return null;
    for (dir in EASE_DIRS)
    {
      if (lk.length >= dir.length && lk.substr(lk.length - dir.length, dir.length) == dir)
      {
        var base = lk.substr(0, lk.length - dir.length);
        return getEaseFunc(base, dir);
      }
    }
    return FlxEase.linear;
  }
}
