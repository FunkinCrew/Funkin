package funkin.memory;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import funkin.play.notes.notestyle.NoteStyle;
import openfl.utils.AssetType;
import openfl.Assets;
import openfl.media.Sound;
import funkin.util.flixel.sound.FlxPartialSound;
import funkin.memory.FunkinMemory.CacheTriplet;
import funkin.memory.CacheLifeCycle;

@:nullSafety
@:allow(funkin.memory.FunkinMemory)
class BitmapCache
{
  static var cacheTriplet:CacheTriplet<FlxGraphic> =
    {
      permanent: [],
      current: [],
      previous: []
    };

  static var purgeFilter:Array<String> = ["/week", "/characters", "/charSelect", "/results"];

  static function initCache():Void
  {
    CacheLifeCycle.initCache(cacheTriplet);
  }

  /**
   * Ensures a texture with the given key is cached.
   * @param key The key of the texture to cache.
   */
  static function cache(key:String):Void
  {
    var graphic:Null<FlxGraphic> = CacheLifeCycle.reuseIfPossible(cacheTriplet, key) ?? FlxGraphic.fromAssetKey(key, false, null, true);

    if (graphic == null) return;

    graphic.persist = true;
    cacheTriplet.current.set(key, graphic);
    forceRender(graphic);
  }

  /**
   * Permanently caches a texture with the given key.
   * @param key The key of the texture to cache.
   */
  static function permanentCache(key:String):Void
  {
    if (cacheTriplet.permanent.exists(key)) return;

    var graphic:Null<FlxGraphic> = FlxGraphic.fromAssetKey(key, false, null, true);

    if (graphic == null) return;

    graphic.persist = true;
    cacheTriplet.permanent.set(key, graphic);
    forceRender(graphic);
  }

  /**
   * Forces the GPU to load and upload a FlxGraphic.
   */
  static function forceRender(graphic:FlxGraphic):Void
  {
    if (graphic == null) return;

    var bmp:Null<FlxGraphic> = FlxG.bitmap.get(graphic.key);
    if (bmp != null && bmp.bitmap != null) var _:Int = bmp.bitmap.width; // Trigger

    // Draws sprite and actually caches it.
    var sprite = new flixel.FlxSprite();
    sprite.loadGraphic(graphic);
    sprite.draw(); // Draw sprite and load it into game's memory.
    // graphic.bitmap?.getTexture(FlxG.stage.context3D); // Just in case that didn't work...
    sprite.destroy();
  }

  /**
   * Checks, if graphic with given path cached in memory.
   */
  static function isCached(path:String):Bool
    return (FlxG.bitmap.get(path) != null)
      && (cacheTriplet.permanent.exists(path) || cacheTriplet.current.exists(path) || cacheTriplet.previous.exists(path));

  static function getCachedGraphic(path:String):Null<FlxGraphic>
  {
    if (cacheTriplet.permanent.exists(path)) return cacheTriplet.permanent.get(path);
    if (cacheTriplet.current.exists(path)) return cacheTriplet.current.get(path);
    if (cacheTriplet.previous.exists(path)) return cacheTriplet.previous.get(path); // just in case

    return null;
  }

  /**
   * Prepares the cache for purging unused textures.
   */
  static function preparePurge():Void
  {
    CacheLifeCycle.preparePurge(cacheTriplet);
  }

  /**
   * Purges unused textures from the cache.
   */
  static function purge():Void
  {
    for (key in cacheTriplet.previous.keys())
    {
      if (cacheTriplet.permanent.exists(key))
      {
        cacheTriplet.previous.remove(key);
        continue;
      }

      if (key.contains("fonts")) continue;

      var graphic:Null<FlxGraphic> = cacheTriplet.previous.get(key);
      if (graphic != null)
      {
        FlxG.bitmap.remove(graphic);
        graphic.persist = false;
        graphic.destroy();
        cacheTriplet.previous.remove(key);
        Assets.cache.removeBitmapData(key);
      }
    }
    @:privateAccess
    if (FlxG.bitmap._cache == null)
    {
      @:privateAccess
      FlxG.bitmap._cache = new Map();
    }

    @:privateAccess
    for (key in FlxG.bitmap._cache.keys())
    {
      var obj:Null<FlxGraphic> = FlxG.bitmap.get(key);

      if (obj == null || (obj.persist && cacheTriplet.permanent.exists(key)) || key.contains("fonts") || obj.useCount <= 0)
      {
        continue;
      }

      for (purgeEntry in purgeFilter)
      {
        if (!key.contains(purgeEntry)) continue;

        FlxG.bitmap.removeKey(key);
        Assets.cache.removeBitmapData(key);
        obj.persist = false;
        obj.destroy();
      }
    }
  }
}
