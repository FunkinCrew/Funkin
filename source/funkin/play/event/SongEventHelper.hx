package funkin.play.event;

import flixel.tweens.FlxEase;
import openfl.display.BitmapData;
import flixel.FlxSprite;

class SongEventHelper
{
  public static var EASE_CANVAS_SIZE:Int = 200;
  public static var easeBitmapMap:Map<String, BitmapData> = new Map<String, BitmapData>();
  public static var easeDirList:Array<String> = ["sine", "quad", "cube", "quart", "quint", "expo", "smoothStep", "smootherStep", "elastic", "back", "bounce", "circ"];
  public static var easeDirs:Array<String> = ["In", "Out", "InOut"];
  public static var easeDotCache:Map<String, Array<FlxSprite>> = new Map<String, Array<FlxSprite>>();

  public static function generateEaseGraphsBitmaps():Void
  {
    for (ease in easeDirList)
      for (dir in easeDirs)
      {
        final func = getEaseFunc(ease, dir);
        if (func == null) continue;
        final key = ease + dir;
        if (!easeBitmapMap.exists(key))
        {
          final bd = createBitmapFromFunc(func, key);
          if (bd != null) easeBitmapMap.set(key, bd);
        }
      }
    var k = "INSTANT";
    if (!easeBitmapMap.exists(k))
    {
      final bd = createBitmapFromFunc(null, k);
      if (bd != null) easeBitmapMap.set(k, bd);
    }
    k = "linear";
    if (!easeBitmapMap.exists(k))
    {
      final bd = createBitmapFromFunc(FlxEase.linear, k);
      if (bd != null) easeBitmapMap.set(k, bd);
    }
  }

  static function getEaseFunc(base:String, dir:String):Dynamic
  {
    var f = Reflect.field(FlxEase, base + dir);
    if (f != null) return f;
    return FlxEase.linear;
  }

  public static function getEaseBitmap(key:String):BitmapData
  {
    if (key == "linearIn" || key == "linearInOut" || key == "linearOut") key = "linear";
    return easeBitmapMap.get(key);
  }

  static function getEaseRange(func:Dynamic, samples:Int):{min:Float, max:Float}
  {
    if (func == null || samples <= 0) return {min: 0.0, max: 1.0};

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

    if (!hasValue) return {min: 0.0, max: 1.0};
    return {min: min, max: max};
  }

  static function getEaseY(raw:Float, size:Int, range:{min:Float, max:Float}):Int
  {
    var v:Float = raw;
    var span = range.max - range.min;

    if (span > 0)
      v = (raw - range.min) / span;

    v = if (v < 0) 0 else if (v > 1) 1 else v;
    return Std.int((1 - v) * (size - 1));
  }

  static function createBitmapFromFunc(func:Dynamic, key:String, thickness:Int = 2):BitmapData
  {
    try
    {
      var size = EASE_CANVAS_SIZE;
      var bd = new BitmapData(size, size, false, 0xFF202223);
      if (key.toLowerCase() == "instant") return bd;
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
            for (xx in (i - half)...(i + half + 1))
              if (xx >= 0 && xx < size) for (yy in (y - half)...(y + half + 1))
                if (yy >= 0 && yy < size) bd.setPixel32(xx, yy, 0xFFFFFFFF);
          }
          else
          {
            var a = Std.int(Math.min(y, lastY));
            var b = Std.int(Math.max(y, lastY));
            for (xx in (i - half)...(i + half + 1))
              if (xx >= 0 && xx < size) for (yy in a - half...b + half + 1)
                if (yy >= 0 && yy < size) bd.setPixel32(xx, yy, 0xFFFFFFFF);
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

  public static function createSpriteFromKey(key:String, displayW:Int, displayH:Int):FlxSprite
  {
    var bd = getEaseBitmap(key);
    if (bd == null) return null;
    var graphicName = "easegfx_" + key;
    var gfx = FlxG.bitmap.add(bd, true, graphicName);
    final spr = new FlxSprite();
    spr.loadGraphic(gfx);
    if (bd.width > 0 && bd.height > 0)
    {
      var sx = displayW / bd.width;
      var sy = displayH / bd.height;
      spr.scale.set(sx, sy);
    }
    spr.updateHitbox();
    spr.antialiasing = false;
    return spr;
  }

  public static function getOrCreateEaseDotSprites(key:String, frameCount:Int = 30, dotRadius:Int = 3, dotWidth:Int = 16):Array<FlxSprite>
  {
    if (easeDotCache.exists(key)) return easeDotCache.get(key);
    var baseBd:BitmapData = getEaseBitmap(key);
    if (baseBd == null) return null;
    var easeFunc:Dynamic = resolveEaseFuncForKey(key);
    var sizeH:Int = baseBd.height;
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
      var bd:BitmapData = new BitmapData(dotWidth, sizeH, false, 0xFF202223);
      var centerX:Int = Std.int(dotWidth / 2);
      for (dx in -dotRadius...dotRadius + 1)
        for (dy in -dotRadius...dotRadius + 1)
        {
          var px = centerX + dx;
          var py = y + dy;
          if (px >= 0 && px < dotWidth && py >= 0 && py < sizeH) if (dx * dx + dy * dy <= dotRadius * dotRadius) bd.setPixel32(px, py, 0xFFFFFFFF);
        }
      var gfxName = "ease_dot_" + key + "_" + f;
      var gfx = FlxG.bitmap.add(bd, true, gfxName);
      var spr = new FlxSprite();
      spr.loadGraphic(gfx);
      sprites.push(spr);
    }
    easeDotCache.set(key, sprites);
    return sprites;
  }

  static function resolveEaseFuncForKey(key:String):Dynamic
  {
    var lk = key;
    if (lk == null || lk.toLowerCase() == "linear") return FlxEase.linear;
    if (lk.toLowerCase() == "instant") return null;
    for (dir in easeDirs)
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
