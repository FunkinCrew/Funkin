package funkin.util.assets;

import openfl.utils.AssetType;
import openfl.utils.Assets;

typedef ResourceCacheStats =
{
  var generation:Int;
  var catalogHits:Int;
  var catalogMisses:Int;
  var textHits:Int;
  var textMisses:Int;
  var cachedTextBytes:Int;
}

@:nullSafety
class ResourceCache
{
  public static var generation(default, null):Int = 0;

  static final MAX_TEXT_ENTRIES:Int = 512;
  static final MAX_TEXT_BYTES:Int = 16 * 1024 * 1024;

  static var catalogs:Map<String, Array<String>> = [];
  static var textValues:Map<String, String> = [];
  static var textOrder:Array<String> = [];
  static var textBytes:Int = 0;
  static var catalogHits:Int = 0;
  static var catalogMisses:Int = 0;
  static var textHits:Int = 0;
  static var textMisses:Int = 0;

  public static function beginGeneration():Int
  {
    generation++;
    catalogs.clear();
    textValues.clear();
    textOrder.resize(0);
    textBytes = 0;
    catalogHits = 0;
    catalogMisses = 0;
    textHits = 0;
    textMisses = 0;
    return generation;
  }

  public static function list(?type:AssetType):Array<String>
  {
    var key:String = Std.string(type);
    var result:Null<Array<String>> = catalogs.get(key);
    if (result != null)
    {
      catalogHits++;
      return result;
    }

    catalogMisses++;
    result = Assets.list(type);
    catalogs.set(key, result);
    return result;
  }

  public static function getText(path:String):String
  {
    var cached:Null<String> = textValues.get(path);
    if (cached != null)
    {
      textHits++;
      touchText(path);
      return cached;
    }

    textMisses++;
    var value:String = Assets.getText(path);
    textValues.set(path, value);
    textOrder.push(path);
    textBytes += value.length * 2;
    trimTextCache();
    return value;
  }

  public static function removeText(path:String):Void
  {
    var value:Null<String> = textValues.get(path);
    if (value == null) return;
    textValues.remove(path);
    textOrder.remove(path);
    textBytes -= value.length * 2;
  }

  public static function stats():ResourceCacheStats
  {
    return {
      generation: generation,
      catalogHits: catalogHits,
      catalogMisses: catalogMisses,
      textHits: textHits,
      textMisses: textMisses,
      cachedTextBytes: textBytes
    };
  }

  static function touchText(path:String):Void
  {
    textOrder.remove(path);
    textOrder.push(path);
  }

  static function trimTextCache():Void
  {
    while (textOrder.length > MAX_TEXT_ENTRIES || textBytes > MAX_TEXT_BYTES)
    {
      var oldest:Null<String> = textOrder.shift();
      if (oldest == null) return;
      var value:Null<String> = textValues.get(oldest);
      textValues.remove(oldest);
      if (value != null) textBytes -= value.length * 2;
    }
  }
}
