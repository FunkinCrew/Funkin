package funkin.assets;

import funkin.memory.StagedCache;
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

/**
 * An override for the HaxeFlixel BitmapFrontend class to provide additional logging.
 */
// MOON NOTES
// * A potential issue I can see with the current implementation is that checking if a cached graphic even exists
// * puts that same said cached graphic into the current cache, which may cause issues if the same asset is being loaded multiple times in a row,
// * but it should be fine for now since we don't have any cases of that happening. If that does end up being an issue, we can add a separate "peek"
// * function to check if an asset exists without moving it to the current cache, and then only move it when it's actually added to the stage or something like that.
//
// * Also staged caching is misleading lol, probably should call it double buffered caching or whatevs. Frick!
class FunkinBitmapFrontend extends flixel.system.frontEnds.BitmapFrontEnd
{
  /**
   * The singleton instance of the FunkinBitmapFrontend.
   */
  public static var instance(get, never):FunkinBitmapFrontend;

  static var _instance:Null<FunkinBitmapFrontend> = null;

  public var stagedFlxGraphic:StagedCache<FlxGraphic>;

  static function get_instance():FunkinBitmapFrontend
  {
    if (FunkinBitmapFrontend._instance == null) _instance = new FunkinBitmapFrontend();
    if (FunkinBitmapFrontend._instance == null) throw 'Could not initialize singleton FunkinBitmapFrontend!';
    return FunkinBitmapFrontend._instance;
  }

  public function new()
  {
    stagedFlxGraphic = new StagedCache<FlxGraphic>(function(graphic:FlxGraphic)
    {
      // Custom removal logic if needed
    }, function(graphic:FlxGraphic)
    {
    });

    super();
  }

  override public function addGraphic(graphic:FlxGraphic):FlxGraphic
  {
    if (!stagedFlxGraphic.exists(graphic.key) || stagedFlxGraphic.get(graphic.key) == null)
    {
      stagedFlxGraphic.current.set(graphic.key, graphic);
    }
    else if (stagedFlxGraphic.get(graphic.key) != graphic)
    {
      removeByKey(graphic.key);
      stagedFlxGraphic.current.set(graphic.key, graphic);
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
    FlxG.log.warn('Texture not cached, may experience stuttering! ${id}');
    var graphic:FlxGraphic = FlxGraphic.fromBitmapData(FunkinAssetCache.instance.getBitmapData(id), false, id);
    // TODO: make the graphic keys (graphic.key) be set too EVERYWHERE
    return addGraphic(graphic);
    #end
  }

  // This is wildly different from the original approach of FunkinAssetCache where we recache the asset if it exists. But we need this internally for the other bitmapfrontend
  // functions to work properly, otherwise we'd need to override every single function that gets a graphic from the cache without needing it to be specifically loaded in memory.

  override public function get(key:String):FlxGraphic
  {
    return stagedFlxGraphic.get(key);
  }

  override public function findKeyForBitmap(bmd:BitmapData):String
  {
    for (key in stagedFlxGraphic.allKeys())
    {
      var obj = stagedFlxGraphic.get(key);
      if (obj != null && obj.bitmap == bmd) return key;
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
    if (key != null)
    {
      remove(stagedFlxGraphic.get(key));
    }
  }

  override public function clearCache():Void
  {
    if (stagedFlxGraphic != null)
    {
      for (key in stagedFlxGraphic.previous.keys())
      {
        var graphic:FlxGraphic = stagedFlxGraphic.previous.get(key);
        if (graphic != null && graphic.useCount <= 0)
        {
          remove(graphic);
        }
      }
      stagedFlxGraphic.previous.clear();
    }
  }

  /**
   * Forcefully clears the 'previous' staged cache while preserving
   * specified assets. Used to control cached graphics and prevent crashes.
   *
   * @param filter Array of keywords (e.g. ["font", "ui"]) to keep in memory.
   */
  public function clearExcept(filter:Array<String>):Void
  {
    if (stagedFlxGraphic == null) return;

    for (key in stagedFlxGraphic.previous.keys())
    {
      if (!filter.exists(keyword -> key.contains(keyword)))
      {
        var graphic:FlxGraphic = stagedFlxGraphic.previous.get(key);
        if (graphic != null && graphic.useCount <= 0)
        {
          trace('[FUCCCKKK] Clearing cached graphic: ' + key);
          remove(graphic);
          stagedFlxGraphic.previous.remove(key);
          FunkinAssetCache.instance.removeBitmapData(key);
        }
      }
    }
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
    if (stagedFlxGraphic == null) return;

    for (key in stagedFlxGraphic.previous.keys())
    {
      if (filter.exists(keyword -> key.contains(keyword)))
      {
        var graphic:FlxGraphic = stagedFlxGraphic.previous.get(key);
        if (graphic != null && graphic.useCount <= 0)
        {
          trace('[FUCCCKKK] Clearing cached graphic: ' + key);
          remove(graphic);
          stagedFlxGraphic.previous.remove(key);
          FunkinAssetCache.instance.removeBitmapData(key);
        }
      }
    }
  }

  // Idk what would be a good way to implement this, we got either A. Check for unusued graphics *everywhere*
  // or B. Check for unused graphics in the previous buffer.
  // For now this is just gonna be A as default because thats what the original BitmapFrontEnd does, but we can always change it later if we want to.

  override public function clearUnused():Void
  {
    for (key in stagedFlxGraphic.allKeys())
    {
      var obj = stagedFlxGraphic.get(key);
      if (obj != null && obj.useCount <= 0 && !obj.persist && obj.destroyOnNoUse)
      {
        removeByKey(key);
      }
    }
  }

  override function removeKey(key:String):Void
  {
    if (key != null)
    {
      FunkinAssetCache.instance.removeBitmapData(key);
      stagedFlxGraphic.remove(key);
    }
  }

  override public function reset():Void
  {
    if (stagedFlxGraphic != null)
    {
      for (key in stagedFlxGraphic.allKeys())
      {
        removeByKey(key);
      }
      stagedFlxGraphic.previous.clear();
      stagedFlxGraphic.current.clear();
    }
  }

  public function resetByPrefix(prefix:String):Void
  {
    if (stagedFlxGraphic != null)
    {
      for (key in stagedFlxGraphic.allKeys())
      {
        if (key.startsWith(prefix))
        {
          removeByKey(key);
        }
      }
    }
  }

  override public function onAssetsReload(_):Void
  {
    // TODO: Implement asset reload logic if needed, for now just copy pasted from original BitmapFrontEnd.
    for (key in stagedFlxGraphic.allKeys())
    {
      var obj = stagedFlxGraphic.get(key);
      if (obj != null && obj.canBeRefreshed)
      {
        obj.onAssetsReload();
      }
    }
  }
}
