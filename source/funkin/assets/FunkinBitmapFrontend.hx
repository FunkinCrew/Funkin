package funkin.assets;

import funkin.util.assets.StagedCache;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxDestroyUtil;
import funkin.assets.Assets.AssetType as FunkinAssetType;
import funkin.assets.Paths.AssetPath;
import funkin.util.assets.AssetsUtil;
import funkin.util.MemoryUtil;
import funkin.util.SortUtil;
import funkin.util.collection.CallbackMap;
import haxe.io.Bytes;
import lime.app.Future;
import lime.app.Promise;
import lime.graphics.Image as LimeImage;
import lime.media.AudioBuffer as LimeAudioBuffer;
import lime.utils.AssetCache as LimeAssetCache;
import lime.utils.AssetType as LimeAssetType;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.Assets as OpenFLAssets;
import openfl.utils.ByteArray;
import openfl.utils.IAssetCache as OpenFLIAssetCache;
//
// ~PATHS~
//
import funkin.assets.Assets as Assets;
import funkin.assets.ValidatedPaths as Paths;

using StringTools;
using Lambda;

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

    super();
  }

  override public function addGraphic(graphic:FlxGraphic):FlxGraphic
  {
    trace('[BITMAPFRONTEND] Caching FlxGraphic: ${graphic.key}');
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

  /**
   * Fetch a FlxGraphic from the cache synchronously.
   * @param id The asset id of the FlxGraphic.
   * @throws error If the FlxGraphic does not exist in the cache and strict asset caching is enabled.
   * @return The FlxGraphic, if available.
   */
  public function getSafe(id:String):FlxGraphic
  {
    var result:Null<FlxGraphic> = stagedFlxGraphic.get(id);
    if (result != null) return result;

    #if FEATURE_STRICT_ASSET_CACHING
    throw 'Flixel graphic not cached, cannot load synchronously: $id';
    #else
    FlxG.log.warn('BitmapFrontend says not cached, may experience stuttering! ${id}');
    var graphic:FlxGraphic = FlxGraphic.fromBitmapData(FunkinAssetCache.instance.getBitmapData(id), false, id);
    // TODO: make the graphic keys (graphic.key) be set too EVERYWHERE
    return addGraphic(graphic);
    #end
  }

  // This is wildly different from the original approach of FunkinAssetCache where we recache the asset if it exists. But we need this internally for the other bitmapfrontend
  // functions to work properly, otherwise we'd need to override every single function that gets a graphic from the cache without needing it to be specifically loaded in memory.

  override public function get(assetPath:String):Null<FlxGraphic>
  {
    return stagedFlxGraphic.get(assetPath);
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
      graphic.destroy();
    }
  }

  override public function removeByKey(key:String):Void
  {
    stagedFlxGraphic.remove(key);
  }

  override public function clearCache():Void
  {
    // Clear everything in the cache, except permanent assets.
    // trace("CLEARED CACHED");
    // stagedFlxGraphic.clearCache();
    stagedFlxGraphic.clearCacheByPredicate((key, graphic) ->
    {
      if (graphic == null) return true;
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

  // Idk what would be a good way to implement this, we got either A. Check for unusued graphics *everywhere*
  // or B. Check for unused graphics in the previous buffer.
  // For now this is just gonna be A as default because thats what the original BitmapFrontEnd does, but we can always change it later if we want to.

  override public function clearUnused():Void
  {
    stagedFlxGraphic.clearCacheByPredicate((key, graphic) ->
    {
      if (graphic == null) return true;
      if (graphic.useCount > 0) return false;
      if (graphic.persist) return false;
      if (!graphic.destroyOnNoUse) return false;

      return true;
    });
  }

  override function removeKey(key:String):Void
  {
    FunkinAssetCache.instance.removeBitmapData(key);
    stagedFlxGraphic.remove(key);
  }

  override public function reset():Void
  {
    stagedFlxGraphic.clearCache();
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

  function onRemoveFlxGraphic(assetPath:String, graphic:FlxGraphic):Void
  {
    // Called when an FlxGraphic is purged from the StagedCache.
    FunkinAssetCache.instance.removeBitmapData(assetPath);
    if (graphic != null) graphic.destroy();
  }

  function onPrePurgeFlxGraphic(assetPath:String, graphic:FlxGraphic):Void
  {
    // Called before a mass purge is performed on the StagedCache.
    if (graphic != null)
    {
      graphic.persist = false;
    }
  }
}
