package funkin.assets;

import flixel.graphics.FlxGraphic;
import funkin.util.assets.StagedCache;
import openfl.display.BitmapData;
import animate.FlxAnimateFrames;
import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.frames.FlxFrame;

//
// ~PATHS~
//
// MOON NOTES
// * A potential issue I can see with the current implementation is that checking if a cached graphic even exists
// * puts that same said cached graphic into the current cache, which may cause issues if the same asset is being loaded multiple times in a row,
// * but it should be fine for now since we don't have any cases of that happening. If that does end up being an issue, we can add a separate "peek"
// * function to check if an asset exists without moving it to the current cache, and then only move it when it's actually added to the stage or something like that.
//
// * Also staged caching is misleading lol, probably should call it double buffered caching or whatevs. Frick!

/**
 * An override for the HaxeFlixel BitmapFrontend class,
 * to provide additional logging and stricter asset caching.
 */
@:nullSafety
@:access(funkin.assets.FunkinAssetCache, funkin.util.assets.StagedCache)
class FunkinBitmapFrontend extends flixel.system.frontEnds.BitmapFrontEnd
{
  /**
   * The singleton instance of the FunkinBitmapFrontend.
   */
  public static var instance(get, never):FunkinBitmapFrontend;

  static var _instance:Null<FunkinBitmapFrontend> = null;

  static function get_instance():FunkinBitmapFrontend
  {
    if (FunkinBitmapFrontend._instance == null) _instance = new FunkinBitmapFrontend();
    if (FunkinBitmapFrontend._instance == null) throw 'Could not initialize singleton FunkinBitmapFrontend!';
    return FunkinBitmapFrontend._instance;
  }

  /**
   * A staged cache for FlxGraphics.
   * Helps with tracking and purging unused assets.
   */
  public var stagedFlxGraphic:StagedCache<FlxGraphic>;

  public function new()
  {
    stagedFlxGraphic = new StagedCache<FlxGraphic>();

    // Called whenever a graphic is purged from the cache.
    stagedFlxGraphic.onRemove.add(onRemoveFlxGraphic);
    stagedFlxGraphic.onPrePurge.add(onPrePurgeFlxGraphic);
    stagedFlxGraphic.onPostPurge.add(onPostPurgeFlxGraphic);

    super();
  }

  override public function addGraphic(graphic:FlxGraphic):FlxGraphic
  {
    // Check if the graphic is valid before adding it to cache.
    if (!isValid(graphic))
    {
      throw 'FlxGraphic tried to add an invalid graphic!';
    }

    #if VERBOSE_ASSET_CACHE
    // Most assets loaded as textures use the full asset path as the key.
    // Exceptions include:
    // - FlxText generates assets with keys like "text236"
    // - FunkinSprite.makeSolidColor generates assets with keys like "solid#000000"
    // - FlxSprite.makeGraphic generates assets with keys like "solid#000000:1024x768"
    //   - In particular, HaxeUI does this a lot to make its graphics.
    trace(' ASSETS '.bold().bg_lime() + ' Cached FlxGraphic: ${graphic.key}');
    #end

    if (!stagedFlxGraphic.exists(graphic.key) || stagedFlxGraphic.get(graphic.key) == null)
    {
      stagedFlxGraphic.cache(graphic.key, graphic);
    }
    else if (stagedFlxGraphic.get(graphic.key) != graphic)
    {
      removeByKey(graphic.key);
      stagedFlxGraphic.cache(graphic.key, graphic);
    }

    return graphic;
  }

  override public function create(width:Int, height:Int, color:FlxColor, unique = false, ?key:String):FlxGraphic
  {
    // Make the default key for FlxSprite.makeSolidColor() more readable.
    key ??= 'solid#${color.toHexString(true, false)}:${width}x${height}';
    return super.create(width, height, color, unique, key);
  }

  /**
   * Makes a FlxGraphic from a FlxGraphicAsset, BitmapData, or asset path string, just without caching it.
   * Note: Alot of mods will use this to replace FlxG.bitmap.add() lol...... - Moon
   * @param   graphic  Optional FlxGraphics object to create FlxGraphic from.
   * @param   unique   Ensures that the bitmap data uses a new slot in the cache.
   * @param   key      Force the cache to use a specific Key to index the bitmap.
   * @return  The FlxGraphic we just created.
   */
  public function createGraphic(graphic:FlxGraphicAsset, unique = false, ?key:String):FlxGraphic
  {
    if ((graphic is FlxGraphic))
    {
      return FlxGraphic.fromGraphic(cast graphic, unique, key);
    }
    else if ((graphic is BitmapData))
    {
      return FlxGraphic.fromBitmapData(cast graphic, unique, key, false);
    }

    // String case
    return FlxGraphic.fromAssetKey(Std.string(graphic), unique, key, false);
  }

  /**
   * Fetch a FlxGraphic from the cache synchronously.
   * @param id The asset id of the FlxGraphic.
   * @throws error If the FlxGraphic does not exist in the cache and strict asset caching is enabled.
   * @return The FlxGraphic, if available.
   */
  public function getSafe(id:String):FlxGraphic
  {
    var result:Null<FlxGraphic> = stagedFlxGraphic.get(id);
    if (result != null && isValid(result))
    {
      return result;
    }

    // Try to build an FlxGraphic from BitmapData.
    var graphic:FlxGraphic = FlxGraphic.fromBitmapData(FunkinAssetCache.instance.getBitmapData(id), false, id);
    return addGraphic(graphic);
  }

  // This is wildly different from the original approach of FunkinAssetCache where we recache the asset if it exists. But we need this internally for the other bitmapfrontend
  // functions to work properly, otherwise we'd need to override every single function that gets a graphic from the cache without needing it to be specifically loaded in memory.

  override public function get(assetPath:String):Null<FlxGraphic>
  {
    return stagedFlxGraphic.get(assetPath);
  }

  public function exists(key:String):Bool
  {
    return stagedFlxGraphic.exists(key);
  }

  override public function findKeyForBitmap(bmd:BitmapData):Null<String>
  {
    for (assetPath in stagedFlxGraphic.keys())
    {
      var obj = stagedFlxGraphic.get(assetPath);
      if (obj != null && obj.bitmap == bmd) return assetPath;
    }

    return null;
  }

  override public function remove(graphic:FlxGraphic):Void
  {
    if (graphic != null)
    {
      removeKey(graphic.key);
      // Sometimes with raw-cached assets the graphic's key is different from the asset key, so we need to remove both. To be safe
      // TODO: Maybe we should just override add and check through the map or something to make sure but nothing gets double cached as an assetkey..? -Moon
      graphic.destroy();
    }
  }

  override public function removeByKey(key:String):Void
  {
    stagedFlxGraphic.remove(key);
  }

  override function removeKey(key:String):Void
  {
    FunkinAssetCache.instance.removeBitmapData(key);
    stagedFlxGraphic.remove(key);
  }

  /**
   * Queues a FlxGraphic for destruction, ensuring it is removed from the cache and destroyed properly.
   * This is a useful method to queue global graphics for destruction once you don't need them.
   * Instead of forcefully removing a graphic mid-runtime.
   * @param graphic The graphic to queue for destruction.
   * @param permanent If true, the graphic will be removed from the permanent cache as well.
   */
  public function queueToDestroy(graphic:FlxGraphic, permanent:Bool = false):Void
  {
    if (stagedFlxGraphic.exists(graphic.key)) stagedFlxGraphic.removeKey(graphic.key, true);
    if (FunkinAssetCache.instance.stagedBitmapData.exists(graphic.key)) FunkinAssetCache.instance.stagedBitmapData.removeKey(graphic.key, true);

    stagedFlxGraphic.onPrePurge.dispatch(graphic.key, graphic);
    stagedFlxGraphic.previous.set(graphic.key, graphic);
    FunkinAssetCache.instance.stagedBitmapData.onPrePurge.dispatch(graphic.key, graphic.bitmap);
    FunkinAssetCache.instance.stagedBitmapData.previous.set(graphic.key, graphic.bitmap);
  }

  /**
   * @param graphic The FlxGraphic to validate.
   * @return `true` only if the FlxGraphic is valid and ready to use.
   */
  public function isValid(graphic:Null<FlxGraphic>):Bool
  {
    if (graphic == null) return false; // graphic is null
    if (graphic.isDestroyed) return false; // graphic is destroyed
    if (graphic.bitmap == null) return false; // graphic's bitmap is null
    @:privateAccess
    if (graphic.bitmap.image == null && graphic.bitmap.__texture == null)
    {
      // The bitmap has neither an image (yet to be uploaded) nor a __texture (already uploaded to GPU)
      return false;
    }
    if (graphic.bitmap.width == 0 || graphic.bitmap.height == 0)
    {
      // The bitmap has no width or height, which means the bitmap is valid but empty, which is definitely wrong.
      return false;
    }
    return true;
  }

  public function isValidByKey(key:String):Bool
  {
    return isValid(stagedFlxGraphic.get(key, false));
  }

  override public function clearCache():Void
  {
    // Clear everything in the cache, except permanent assets.
    // trace("CLEARED CACHED");
    // stagedFlxGraphic.clearCache();
    stagedFlxGraphic.clearCacheByPredicate((key, graphic) ->
    {
      // Always clear graphics that are invalid.
      if (graphic == null) return true;
      // Never
      if (graphic.useCount > 0) return false;
      if (graphic.persist) return false;

      return true;
    });
  }

  /**
   * Forcefully clears the 'previous' staged cache while preserving
   * specified assets. Used to control cached graphics and prevent crashes.
   *
   * @param filter Array of keywords (e.g. ["font", "ui"]) to keep in memory.
   */
  public function clearExcept(filter:Array<String>):Void
  {
    stagedFlxGraphic.purgeCacheByPredicate((key, graphic) -> return !filter.exists(keyword -> key.contains(keyword)));
  }

  /**
   * Forcefully clears any cache within the 'previous' staged cache that includes any
   * of the specified keywords while preserving assets that don't include those keywords.
   * Used to control cached graphics and prevent crashes.
   *
   * @param filter Array of keywords (e.g. ["font", "ui"]) to keep in memory.
   */
  public function clearOnly(filter:Array<String>):Void
  {
    stagedFlxGraphic.purgeCacheByPredicate((key, graphic) -> return filter.exists(keyword -> key.contains(keyword)));
  }

  /**
   * Forcibly clears all assets, including assets flagged as permanent.
   */
  public function forceClear():Void
  {
    stagedFlxGraphic.clearCache(true);
  }

  // Idk what would be a good way to implement this, we got either A. Check for unusued graphics *everywhere*
  // or B. Check for unused graphics in the previous buffer.
  // For now this is just gonna be A as default because thats what the original BitmapFrontEnd does, but we can always change it later if we want to.

  override public function clearUnused():Void
  {
    stagedFlxGraphic.clearCacheByPredicate((key, graphic) ->
    {
      // Always clear graphics that are invalid.
      if (graphic == null) return true;
      // Don't clear graphics we know are in use right now.
      if (graphic.useCount > 0) return false;
      if (graphic.persist) return false;
      if (!graphic.destroyOnNoUse) return false;

      return true;
    });
  }

  override public function reset():Void
  {
    stagedFlxGraphic.clearCache(false);
  }

  /**
   * Clears all cached FlxGraphics that start with the specified prefix.
   * @param prefix The prefix to match against cached FlxGraphics.
   */
  public function resetByPrefix(prefix:String):Void
  {
    for (key in stagedFlxGraphic.keys())
    {
      if (key.startsWith(prefix))
      {
        removeByKey(key);
      }
    }
  }

  override public function onAssetsReload(_):Void
  {
    // TODO: Implement asset reload logic if needed, for now just copy pasted from original BitmapFrontEnd.
    for (key in stagedFlxGraphic.keys())
    {
      var obj = stagedFlxGraphic.get(key);
      if (obj != null && obj.canBeRefreshed)
      {
        obj.onAssetsReload();
      }
    }
  }

  override function get_whitePixel():FlxFrame
  {
    if (_whitePixel == null)
    {
      var bd = new BitmapData(10, 10, true, FlxColor.WHITE);
      var graphic:FlxGraphic = FunkinAssetCache.instance.permaCacheFlxGraphic("whitePixels", bd);
      graphic.persist = true;
      _whitePixel = graphic.imageFrame.frame;
    }

    return _whitePixel;
  }

  function onRemoveFlxGraphic(assetPath:String, graphic:FlxGraphic):Void
  {
    // Remove the graphic from flixel-animate's cache if it exists
    @:privateAccess
    if (FlxAnimateFrames._cachedAtlases.exists(assetPath))
    {
      FlxAnimateFrames._cachedAtlases.remove(assetPath);
    }

    // Called when an FlxGraphic is purged from the StagedCache.
    FunkinAssetCache.instance.removeBitmapData(assetPath);

    if (graphic != null) graphic.destroy();
  }

  function onPrePurgeFlxGraphic(assetPath:String, graphic:FlxGraphic):Void
  {
    // Called before a mass purge is performed on the StagedCache.
    // This specific graphic may not necessarily be purged.
    if (graphic != null && !stagedFlxGraphic.permanent.exists(assetPath))
    {
      graphic.persist = false;
    }
  }

  function onPostPurgeFlxGraphic(assetPath:String):Void
  {
    #if VERBOSE_ASSET_CACHE
    trace('[BITMAPFRONTEND] Purging FlxGraphic: ${assetPath}');
    // funkin.util.DebugUtil.printCallStack();
    #end
  }
}
