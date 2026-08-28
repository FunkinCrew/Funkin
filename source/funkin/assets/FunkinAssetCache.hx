package funkin.assets;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxDestroyUtil;
import funkin.assets.Assets.AssetType as FunkinAssetType;
import funkin.assets.Paths.AssetPath;
import funkin.assets.ValidatedPaths as Paths;
import funkin.util.SortUtil;
import funkin.util.assets.AssetsUtil;
import funkin.util.assets.StagedCache;
import funkin.util.assets.StagedCache.IStagedCache;
import funkin.util.collection.CallbackMap;
import haxe.io.Bytes;
import lime.app.Future;
import lime.app.Promise;
import lime.graphics.Image as LimeImage;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import lime.media.AudioBuffer as LimeAudioBuffer;
import lime.utils.AssetCache as LimeAssetCache;
import lime.utils.AssetType as LimeAssetType;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.Assets as OpenFLAssets;
import openfl.utils.ByteArray;
import openfl.utils.IAssetCache as OpenFLIAssetCache;
import flixel.system.FlxAssets.FlxGraphicAsset;
import lime.app.Promise;

using funkin.graphics.framebuffer.BitmapDataUtil;

// @:nullSafety

/**
 * An override for the OpenFL AssetCache class to override the internal cache with our own.
 * This allows us to be more specific about when assets are cached, and when they are purged.
 *
 * USAGE GUIDE:
 * Call fetch functions when you want to get and/or load an Asset asynchronously.
 * Call cache functions when you want to load the Asset into memory asynchronously, without necessarily needing the asset.
 * Call get functions when you want to get the Asset synchronously, this will cause stutters during the game's process.
 */
@:allow(funkin.assets.FunkinBitmapFrontend, funkin.util.assets.StagedCache)
class FunkinAssetCache implements OpenFLIAssetCache
{
  // NOTE FROM MOON: In theory, this async thing could cause issues where we try and fetch assets multiple times between frames causing overhead
  // because we don't check if an asset is in progress of being fetched/loaded or not.. right now as of writing this it isn't happening.
  // But, I'm keeping this here just as a heads up!

  /**
   * An internal list of all the available StagedCaches.
   */
  var stagedCaches:Array<IStagedCache>;

  /**
   * A staged cache for BitmapData.
   * Helps with tracking and purging unused assets.
   */
  var stagedBitmapData:StagedCache<BitmapData>;

  /**
   * A staged cache for Fonts.
   * Helps with tracking and purging unused assets.
   */
  var stagedFont:StagedCache<Font>;

  /**
   * A staged cache for Sounds.
   * Helps with tracking and purging unused assets.
   */
  var stagedSound:StagedCache<Sound>;

  /**
   * Cache containing Text (such as JSON or TXT files)
   */
  var stagedText:StagedCache<String>;

  /**
   * Cache containing Binary data (anything not covered by its own cache)
   */
  var stagedBytes:StagedCache<openfl.utils.ByteArray>;

  /**
   * A cache for the result of `Assets.list(type)`.
   */
  var assetListCaches:Map<FunkinAssetType, Array<AssetPath>>;

  /**
   * A cache for the result of `Assets.list()`.
   */
  var assetListBaseCache:Null<Array<AssetPath>> = null;

  /**
   * The singleton instance of the asset cache.
   */
  public static var instance(get, never):FunkinAssetCache;

  static var _instance:Null<FunkinAssetCache> = null;

  /**
   * Whether or not the asset cache is enabled.
   * Required by OpenFL but never actually used.
   */
  public var enabled(get, set):Bool;

  static function get_instance():FunkinAssetCache
  {
    if (FunkinAssetCache._instance == null) _instance = new FunkinAssetCache();
    if (FunkinAssetCache._instance == null) throw 'Could not initialize singleton FunkinAssetCache!';
    return FunkinAssetCache._instance;
  }

  public function new()
  {
    stagedBitmapData = new StagedCache<BitmapData>();
    stagedBitmapData.onRemove.add((key:String, asset:BitmapData) ->
    {
      FunkinLimeAssetCache.instance.removeImage(key);
      FlxDestroyUtil.dispose(asset);
    });

    stagedFont = new StagedCache<Font>();
    stagedFont.onRemove.add((key:String, asset:Font) ->
    {
      // Is there a proper method to destroy fonts?
      FunkinLimeAssetCache.instance.removeFont(key);
      asset = null;
    });

    stagedSound = new StagedCache<Sound>();
    stagedSound.onRemove.add((key:String, asset:Sound) ->
    {
      FunkinLimeAssetCache.instance.removeAudio(key);
      asset = null;
    });

    stagedText = new StagedCache<String>();
    stagedText.onRemove.add((_:String, asset:String) ->
    {
      asset = null;
    });

    stagedBytes = new StagedCache<openfl.utils.ByteArray>();
    stagedBytes.onRemove.add((_:String, asset:openfl.utils.ByteArray) ->
    {
      // clear() explicitly frees up the memory used by the ByteArray.
      asset.clear();
      asset = null;
    });

    stagedCaches = [
      // FunkinBitmapFrontend.instance.stagedFlxGraphic,
      // stagedBitmapData, <-- Technically we do not need this since we call FunkinBitmapFrontEnd's purge and it already removes the bitmapdata BUT with safety checks soooooo :P
      stagedFont,
      stagedSound,
      stagedText,
      stagedBytes,
    ];

    assetListCaches = [];
    assetListBaseCache = null;

    enabled = true;
  }

  /**
   * Clear assets from the asset cache.
   *
   * @param prefix (Optional) Only asset paths starting with this prefix will be cleared.
   */
  public function clear(?prefix:String):Void
  {
    if (prefix == null)
    {
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS '.bold().bg_lime() + ' Force clearing asset cache...');
      #end
      for (cache in stagedCaches) cache.clearCache();
      FunkinBitmapFrontend.instance.reset();
      assetListCaches = [];
      assetListBaseCache = null;
    }
    else
    {
      #if FEATURE_DEBUG_TRACY
      cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.clear($prefix)');
      #end
      for (cache in stagedCaches) cache.clearCacheByPrefix(prefix);
      FunkinBitmapFrontend.instance.resetByPrefix(prefix);
    }
  }

  /**
   * Clear assets from the asset cache, and clear caches of `Assets.list()` too.
   * NOTE: This is a little dangerous since you're un-caching EVERYTHING, even stuff set to cache permanently.
   * Generally only do this if you plan on reloading and pre-caching important assets afterwards.
   */
  public function forceClearCache():Void
  {
    final CLEAR_PERMANENT:Bool = true;

    #if VERBOSE_ASSET_CACHE
    trace(' ASSETS '.bold().bg_lime() + ' Force clearing asset cache...');
    #end

    for (cache in stagedCaches)
    {
      cache.clearCache(CLEAR_PERMANENT);
    }
    FunkinBitmapFrontend.instance.forceClear();
    assetListCaches = [];
    assetListBaseCache = null;
  }

  /**
   * Prepare to purge the asset cache.
   * Attempting to recache any assets that were previously cached will just move them to the new cache.
   * Later, any old assets that the game didn't try to use again will be destroyed, saving memory.
   */
  public function preparePurgeCache():Void
  {
    for (cache in stagedCaches) cache.preparePurgeCache();
    FunkinBitmapFrontend.instance.stagedFlxGraphic.preparePurgeCache();
  }

  /**
   * Purge any assets that were previously cached, but weren't requested again since `preparePurgeCache()` was called.
   *
   * @param garbageCollect Whether to forcibly invoke the system's garbage collector after purging assets.
   */
  public function purgeCache(garbageCollect:Bool = false):Void
  {
    // TODO: Cleanup purging to work with Freeplay?
    for (cache in stagedCaches) cache.purgeCache();

    #if FEATURE_HAXEUI
    purgeHaxeUIAssets();
    #end

    // Clear everything except:
    // - Stickers, so that graphics don't get lost during sticker transition (TODO: Fix this in LoadingState?)
    // - `bg_graphic_` is used to render the background color on substates, it's 1x1 pixel so probably not a problem to just keep it.
    FunkinBitmapFrontend.instance.clearExcept(['stickers/', 'bg_graphic_']);
    // ^ Clear everything but freeplay as that has its own process, may or may not still be here depending on the future loading changes.

    // Perform garbage collection here, after we deleted a bunch of stuff, to free the memory we're no longer using.
    #if (cpp || neko)
    if (garbageCollect) funkin.util.MemoryUtil.collect(true);
    #end
  }

  #if FEATURE_HAXEUI
  /**
   * Purge all image references held by HaxeUI.
   */
  public function purgeHaxeUIAssets():Void
  {
    @:privateAccess
    {
      haxe.ui.ToolkitAssets.instance?._imageCache?.clear();
      haxe.ui.ToolkitAssets.instance?._fontCache?.clear();
    }
  }
  #end

  /**
   * Fetch a FlxGraphic from the cache synchronously.
   * @param id The asset id of the FlxGraphic.
   * @throws error If the FlxGraphic does not exist in the cache and strict asset caching is enabled.
   * @return The FlxGraphic, if available.
   */
  public function getFlxGraphic(id:String):FlxGraphic
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.getFlxGraphic($id)');
    #end
    getBitmapData(id);
    return FunkinBitmapFrontend.instance.getSafe(id);
  }

  /**
   * Get a BitmapData, if it exists in the cache.
   * @param id The asset id of the BitmapData.
   * @throws error If the BitmapData does not exist in the cache and strict asset caching is enabled.
   * @return The BitmapData, if available.
   */
  public function getBitmapData(id:String):BitmapData
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.getBitmapData($id)');
    #end
    var result:Null<BitmapData> = stagedBitmapData.get(id);

    if (validateBitmapData(result))
    {
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS '.bold().bg_lime() + ' Bitmap data found in cache: ' + id);
      #end
      return result;
    }
    else
    {
      stagedBitmapData.remove(id);
      #if FEATURE_STRICT_ASSET_CACHING
      throw 'Bitmap data not cached, cannot load synchronously: $id';
      #else
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS '.bold().bg_lime() + ' Bitmap data not found in cache: ' + id);
      #end
      var bitmapData:BitmapData = OpenFLAssets.getBitmapData(id);
      setBitmapData(id, bitmapData);
      return bitmapData;
      #end
    }
  }

  /**
   * Get a Font, if it exists in the cache.
   * @param id The asset id of the Font.
   * @throws error If the Font does not exist in the cache and strict asset caching is enabled.
   * @return The Font, if available.
   */
  public function getFont(id:String):Font
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.getFont($id)');
    #end
    var result:Null<Font> = stagedFont.get(id);
    if (result != null)
    {
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS '.bold().bg_lime() + ' Font data found in cache: ' + id);
      #end
      return result;
    }
    else
    {
      #if FEATURE_STRICT_ASSET_CACHING
      throw 'Font not cached, cannot load synchronously: $id';
      #else
      var font:Font = OpenFLAssets.getFont(id);
      setFont(id, font);
      return font;
      #end
    }
  }

  /**
   * Get a Sound, if it exists in the cache.
   * @param id The asset id of the Sound.
   * @throws error If the Sound does not exist in the cache and strict asset caching is enabled.
   * @return The Sound, if available.
   */
  public function getSound(id:String):Sound
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.getSound($id)');
    #end
    var result:Null<Sound> = stagedSound.get(id);
    if (result != null)
    {
      return result;
    }
    else
    {
      #if FEATURE_STRICT_ASSET_CACHING
      throw 'Sound not cached, cannot load synchronously: $id';
      #else
      // FlxG.log.warn('Sound not cached, may experience stuttering! ${id}');
      var sound:Sound = OpenFLAssets.getSound(id);
      setSound(id, sound);
      return sound;
      #end
    }
  }

  /**
   * Gets text from a file.
   * @param id The asset id of the text.
   * @throws error If the text does not exist in the cache and strict asset caching is enabled.
   * @return The text, if available.
   */
  public function getText(id:String):String
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.getText($id)');
    #end
    var result:Null<String> = stagedText.get(id);
    if (result != null)
    {
      return result;
    }
    else
    {
      #if FEATURE_STRICT_ASSET_CACHING
      throw 'Text not cached, cannot load synchronously: $id';
      #else
      // Why is FlxG.log.warn so fucking expensive?
      // FlxG.log.warn('Text not cached, may experience stuttering! ${id}');

      if (!OpenFLAssets.exists(id))
      {
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' Text file does not exist: $id');
        #end
        funkin.util.DebugUtil.printCallStack();
        throw 'Text file does not exist: $id';
      }

      var text:String = OpenFLAssets.getText(id);
      setText(id, text);
      return text;
      #end
    }
  }

  /**
   * Gets bytes from a file.
   * @param id The asset id of the bytes.
   * @throws error If the bytes do not exist in the cache and strict asset caching is enabled.
   * @return The bytes, if available.
   */
  public function getBytes(id:String):openfl.utils.ByteArray
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.getBytes($id)');
    #end
    var result:Null<openfl.utils.ByteArray> = stagedBytes.get(id);
    if (result != null)
    {
      return result;
    }
    else
    {
      #if FEATURE_STRICT_ASSET_CACHING
      throw 'Bytes not cached, cannot load synchronously: $id';
      #else
      // FlxG.log.warn('Bytes not cached, may experience stuttering! ${id}');
      var bytes:openfl.utils.ByteArray = OpenFLAssets.getBytes(id);
      setBytes(id, bytes);
      return bytes;
      #end
    }
  }

  /**
   * Get a Sparrow Atlas, if its graphic exists in the cache.
   *
   * @param assetPath The path to the image, created with `Paths.image`.
   *   We automatically assume the XML is next to it.
   * @throws error If the graphic does not exist in the cache and strict asset caching is enabled.
   * @return The atlas frames, if available.pixel/
   */
  public function getSparrowAtlas(assetPath:AssetPath):FlxAtlasFrames
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.getSparrowAtlas(${assetPath.toString()})');
    #end
    var xmlAssetPath = assetPath.withAssetType(XML);

    var graphic:FlxGraphic = getFlxGraphic(assetPath.toString());
    var data:String = getText(xmlAssetPath.toString());
    return FlxAtlasFrames.fromSparrow(graphic, data);
  }

  /**
   * Get a Packer Atlas, if its graphic exists in the cache.
   *
   * @param assetPath The path to the image, created with `Paths.image`.
   *   We automatically assume the TXT is next to it.
   * @throws error If the graphic does not exist in the cache and strict asset caching is enabled.
   * @return The atlas frames, if available.
   */
  public function getPackerAtlas(assetPath:AssetPath):FlxAtlasFrames
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.getPackerAtlas(${assetPath.toString()})');
    #end
    var txtAssetPath = assetPath.withAssetType(TEXT);

    var graphic:FlxGraphic = getFlxGraphic(assetPath.toString());
    var data:String = getText(txtAssetPath.toString());
    return FlxAtlasFrames.fromSpriteSheetPacker(graphic, data);
  }

  /**
   * Check if a FlxGraphic exists in the cache.
   * @param assetPath The asset path of the FlxGraphic.
   * @return `true` if the FlxGraphic exists in the cache, `false` otherwise.
   */
  public function hasFlxGraphic(assetPath:AssetPath):Bool
  {
    if (!FunkinBitmapFrontend.instance.exists(assetPath.toString()))
    {
      return false;
    }

    if (!FunkinBitmapFrontend.instance.isValidByKey(assetPath.toString()))
    {
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS ' + ' Removing invalid FlxGraphic "${assetPath.toString()} from cache.');
      #end
      FunkinBitmapFrontend.instance.removeByKey(assetPath.toString());
      return false;
    }

    return true;
  }

  /**
   * Check if a BitmapData exists in the cache.
   * NOTE: This has to take a String id for `IAssetCache`.
   *
   * @param id The asset id of the BitmapData.
   * @return `true` if the BitmapData exists in the cache, `false` otherwise.
   */
  public function hasBitmapData(id:String):Bool
  {
    if (!stagedBitmapData.exists(id))
    {
      return false;
    }

    if (!validateBitmapData(stagedBitmapData.get(id)))
    {
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS ' + ' Removing invalid BitmapData "$id" from cache.');
      #end
      stagedBitmapData.remove(id);
      return false;
    }

    return true;
  }

  /**
   * Check if a Font exists in the cache.
   * NOTE: This has to take a String id for `IAssetCache`.
   *
   * @param id The asset id of the Font.
   * @return `true` if the Font exists in the cache, `false` otherwise.
   */
  public function hasFont(id:String):Bool
  {
    return stagedFont.exists(id);
  }

  /**
   * Check if a Sound exists in the cache.
   * NOTE: This has to take a String id for `IAssetCache`.
   *
   * @param id The asset id of the Sound.
   * @return `true` if the Sound exists in the cache, `false` otherwise.
   */
  public function hasSound(id:String):Bool
  {
    return stagedSound.exists(id);
  }

  /**
   * Check if a Text exists in the cache.
   * NOTE: This has to take a String id for `IAssetCache`.
   *
   * @param id The asset id of the Text.
   * @return `true` if the Text exists in the cache, `false` otherwise.
   */
  public function hasText(id:String):Bool
  {
    return stagedText.exists(id);
  }

  /**
   * Check if a file's Bytes exists in the cache.
   * NOTE: This has to take a String id for `IAssetCache`.
   *
   * @param id The asset id of the bytes.
   * @return `true` if the bytes exist in the cache, `false` otherwise.
   */
  public function hasBytes(id:String):Bool
  {
    return stagedBytes.exists(id);
  }

  /**
   * Remove a specific FlxGraphic from the cache.
   * @param id The asset id of the FlxGraphic.
   * @return `true` if the FlxGraphic was removed from the cache, `false` otherwise.
   */
  public function removeFlxGraphic(id:String):Bool
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.removeFlxGraphic($id)');
    #end
    if (FunkinBitmapFrontend.instance.stagedFlxGraphic.exists(id))
    {
      FunkinBitmapFrontend.instance.removeByKey(id);
      return true;
    }

    return false;
  }

  /**
   * Remove a specific BitmapData from the cache.
   * @param id The asset id of the BitmapData.
   * @return `true` if the BitmapData was removed from the cache, `false` otherwise.
   */
  public function removeBitmapData(id:String):Bool
  {
    return stagedBitmapData.remove(id);
  }

  /**
   * Remove a specific Font from the cache.
   * @param id The asset id of the Font.
   * @return `true` if the Font was removed from the cache, `false` otherwise.
   */
  public function removeFont(id:String):Bool
  {
    return stagedFont.remove(id);
  }

  /**
   * Remove a specific Sound from the cache.
   * @param id The asset id of the Sound.
   * @return `true` if the Sound was removed from the cache, `false` otherwise.
   */
  public function removeSound(id:String):Bool
  {
    return stagedSound.remove(id);
  }

  /**
   * Remove a specific Text from the cache.
   * @param id The asset id of the Text.
   * @return `true` if the Text was removed from the cache, `false` otherwise.
   */
  public function removeText(id:String):Bool
  {
    return stagedText.remove(id);
  }

  /**
   * Remove a specific file's Bytes from the cache.
   * @param id The asset id of the bytes.
   * @return `true` if the bytes were removed from the cache, `false` otherwise.
   */
  public function removeBytes(id:String):Bool
  {
    return stagedBytes.remove(id);
  }

  /**
   * Add an FlxGraphic to the cache.
   * @param id The asset id of the FlxGraphic.
   * @param flxGraphic The FlxGraphic to add to the cache.
   */
  public function setFlxGraphic(id:String, flxGraphic:FlxGraphicAsset):FlxGraphic
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.setFlxGraphic($id)');
    #end
    // Make sure we don't accidentally dispose the bitmap associated with this FlxGraphic.
    if (hasBitmapData(id)) getBitmapData(id);

    var graphic = FunkinBitmapFrontend.instance.add(flxGraphic, false, id);
    // Make sure we don't accidentally destroy the graphic while we're using it.
    graphic.persist = true;
    graphic.destroyOnNoUse = false;
    return graphic;
  }

  /**
   * Add a BitmapData to the cache.
   * @param id The asset id of the BitmapData.
   * @param bitmapData The BitmapData to add to the cache.
   */
  public function setBitmapData(id:String, bitmapData:BitmapData):Void
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.setBitmapData($id)');
    #end
    if (!validateBitmapData(bitmapData)) throw "Bitmap cache tried to add an invalid Bitmap!";
    stagedBitmapData.cache(id, bitmapData);
  }

  /**
   * Add a Font to the cache.
   * @param id The asset id of the Font.
   * @param font The Font to add to the cache.
   */
  public function setFont(id:String, font:Font):Void
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.setFont($id)');
    #end
    // Always permanent cache fonts.
    stagedFont.cachePermanent(id, font);
  }

  /**
   * Add a Sound to the cache.
   * @param id The asset id of the Sound.
   * @param sound The Sound to add to the cache.
   */
  public function setSound(id:String, sound:Sound):Void
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.setSound($id)');
    #end
    stagedSound.cache(id, sound);
  }

  /**
   * Add a Text to the cache.
   * @param id The asset id of the Text.
   * @param text The Text to add to the cache.
   */
  public function setText(id:String, text:String):Void
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.setText($id)');
    #end
    stagedText.cache(id, text);
  }

  /**
   * Add a Bytes to the cache.
   * @param id The asset id of the bytes.
   * @param bytes The bytes to add to the cache.
   */
  public function setBytes(id:String, bytes:Bytes):Void
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.setBytes($id)');
    #end
    stagedBytes.cache(id, bytes);
  }

  /**
   * Fetch a BitmapData asynchronously and return it.
   * If it's in the cache, it will be returned immediately.
   * If it's not in the cache, it will be loaded and cached, then returned.
   *
   * @param assetPath The path of the asset to fetch.
   * @param uploadToGPU Whether or not to upload the BitmapData to the GPU before caching.
   * @return The BitmapData, if fetched.
   */
  public function fetchBitmapData(assetPath:AssetPath, uploadToGPU:Bool = true):Future<BitmapData>
  {
    #if VERBOSE_ASSET_CACHE
    trace(' ASSETS '.bold().bg_lime() + ' Fetching BitmapData: ${assetPath.toString()}');
    #end
    if (hasBitmapData(assetPath.toString()))
    {
      return Future.withValue(getBitmapData(assetPath.toString()));
    }
    else
    {
      var future:Future<BitmapData> = OpenFLAssets
        .loadBitmapData(assetPath.toString(), false, !assetPath.needsPixelData, !assetPath.needsPixelData)
        .then((bitmapData:BitmapData) ->
        {
          if (uploadToGPU)
          {
            bitmapData.toGPU(false);
          }
          setBitmapData(assetPath.toString(), bitmapData);
          return Future.withValue(bitmapData);
        });
      return future;
    }
  }

  /**
   * Fetch a FlxGraphic asynchronously and return it.
   * If it's in the cache, it will be returned immediately.
   * If it's not in the cache, it will be loaded and cached, then returned.
   *
   * @param assetPath The path of the asset to fetch.
   * @param uploadToGPU Whether or not to upload the underlying BitmapData to the GPU before caching.
   * @return The FlxGraphic, if fetched.
   */
  public function fetchFlxGraphic(assetPath:AssetPath, ?uploadToGPU:Bool):Future<FlxGraphic>
  {
    if (hasFlxGraphic(assetPath))
    {
      return Future.withValue(getFlxGraphic(assetPath.toString()));
    }
    else
    {
      var future:Future<FlxGraphic> = fetchBitmapData(assetPath, uploadToGPU).then((bitmapData:BitmapData) ->
      {
        // Create an FlxGraphic from the BitmapData.
        var graphic:FlxGraphic = setFlxGraphic(assetPath.toString(), bitmapData);
        return Future.withValue(graphic);
      });
      return future;
    }
  }

  /**
   * Fetch a Sound asynchronously and return it.
   * If it's in the cache, it will be returned immediately.
   * If it's not in the cache, it will be loaded and cached, then returned.
   *
   * @param assetPath The path of the asset to fetch.
   * @return The Sound, if fetched.
   */
  public function fetchSound(assetPath:AssetPath):Future<Sound>
  {
    if (hasSound(assetPath.toString()))
    {
      return Future.withValue(getSound(assetPath.toString()));
    }
    else
    {
      return OpenFLAssets.loadSound(assetPath.toString()).then((sound:Sound) ->
      {
        setSound(assetPath.toString(), sound);
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' Cached Sound: ${assetPath.toString()}');
        #end
        return Future.withValue(sound);
      });
    }
  }

  /**
   * Fetch text from a file asynchronously and return it.
   *
   * @param assetPath The path of the asset to fetch.
   * @return The text, if fetched.
   */
  public function fetchText(assetPath:AssetPath):Future<String>
  {
    if (hasText(assetPath.toString()))
    {
      return Future.withValue(getText(assetPath.toString()));
    }
    else
    {
      return OpenFLAssets.loadText(assetPath.toString()).then((text:String) ->
      {
        setText(assetPath.toString(), text);
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' Cached Text: ${assetPath.toString()}');
        #end
        return Future.withValue(text);
      });
    }
  }

  /**
   * Fetch font data from a file asynchronously and return it.
   *
   * @param assetPath The path of the asset to fetch.
   * @return The font, if fetched.
   */
  public function fetchFont(assetPath:AssetPath):Future<Font>
  {
    if (hasText(assetPath.toString()))
    {
      return Future.withValue(getFont(assetPath.toString()));
    }
    else
    {
      return OpenFLAssets.loadFont(assetPath.toString()).then((font:Font) ->
      {
        setFont(assetPath.toString(), font);
        return Future.withValue(font);
      });
    }
  }

  /**
   * Fetch bytes from a file asynchronously and return it.
   *
   * @param assetPath The path of the asset to fetch.
   * @return The bytes, if fetched.
   */
  public function fetchBytes(assetPath:AssetPath):Future<ByteArray>
  {
    if (hasBytes(assetPath.toString()))
    {
      return Future.withValue(getBytes(assetPath.toString()));
    }
    else
    {
      return OpenFLAssets.loadBytes(assetPath.toString()).then((bytes:openfl.utils.ByteArray) ->
      {
        setBytes(assetPath.toString(), bytes);
        return Future.withValue(bytes);
      });
    }
  }

  /**
   * Fetch a Sparrow spitesheet asynchronously and return it.
   * If the graphic exists in the cache, it will be returned immediately.
   * If it's not in the cache, it will be loaded and cached, then returned.
   *
   * @param assetPath The path of the image asset to fetch.
   *   The XML asset can be inferred from the image path.
   * @return The atlas frames, if fetched.
   */
  public function fetchSparrowAtlas(assetPath:AssetPath):Future<FlxAtlasFrames>
  {
    var xmlAssetPath:AssetPath = assetPath.withAssetType(XML);
    cacheFlxGraphic(assetPath);
    cacheText(xmlAssetPath);

    var result:Promise<FlxAtlasFrames> = new Promise();
    var graphic:Future<FlxGraphic> = fetchFlxGraphic(assetPath);
    var data:Future<String> = fetchText(xmlAssetPath);
    var onBothComplete:Void->Void = () ->
    {
      var graphicResult:Null<FlxGraphic> = graphic.value;
      var dataResult:Null<String> = data.value;
      if (graphicResult == null || dataResult == null)
      {
        result.error('Unknown error while loading asset');
      }
      else
      {
        result.complete(FlxAtlasFrames.fromSparrow(graphicResult, dataResult));
      }
    };
    graphic.onComplete((_) ->
    {
      if (data.isComplete) onBothComplete();
    }).onError((err) ->
      {
        result.error(err);
      });
    data.onComplete((_) ->
    {
      if (graphic.isComplete) onBothComplete();
    }).onError((err) ->
      {
        result.error(err);
      });
    return result.future;
  }

  /**
   * Fetch a Packer spitesheet asynchronously and return it.
   * If the graphic exists in the cache, it will be returned immediately.
   * If it's not in the cache, it will be loaded and cached, then returned.
   *
   * @param assetPath The path of the image asset to fetch.
   *   The TXT asset can be inferred from the image path.
   * @return The atlas frames, if fetched.
   */
  public function fetchPackerAtlas(assetPath:AssetPath):Future<FlxAtlasFrames>
  {
    var txtAssetPath:AssetPath = assetPath.withAssetType(XML);
    cacheFlxGraphic(assetPath);
    cacheText(txtAssetPath);

    var result:Promise<FlxAtlasFrames> = new Promise();
    var graphic:Future<FlxGraphic> = fetchFlxGraphic(assetPath);
    var data:Future<String> = fetchText(txtAssetPath);
    var onBothComplete:Void->Void = () ->
    {
      var graphicResult:Null<FlxGraphic> = graphic.value;
      var dataResult:Null<String> = data.value;
      if (graphicResult == null || dataResult == null)
      {
        result.error('Unknown error while loading asset');
      }
      else
      {
        result.complete(FlxAtlasFrames.fromSpriteSheetPacker(graphicResult, dataResult));
      }
    };
    graphic.onComplete((_) ->
    {
      if (data.isComplete) onBothComplete();
    }).onError((err) ->
      {
        result.error(err);
      });
    data.onComplete((_) ->
    {
      if (graphic.isComplete) onBothComplete();
    }).onError((err) ->
      {
        result.error(err);
      });
    return result.future;
  }

  /**
   * List all assets of the given type.
   * Has functionality for caching because this apparently takes a while.
   *
   * @param type The type of assets to list.
   * @param force Whether or not to force a re-list.
   * @return The list of assets.
   */
  public function list(?type:FunkinAssetType, force:Bool = false):Array<AssetPath>
  {
    var results:Array<AssetPath> = [];

    if (!force && type == null)
    {
      // Invalidate empty cache.
      if (assetListBaseCache != null && assetListBaseCache.length == 0)
      {
        assetListBaseCache = null;
      }

      // Accept valid cache.
      if (assetListBaseCache != null && assetListBaseCache.length > 0) return assetListBaseCache;

      // Else, continue.
    }
    else if (!force && type != null && assetListCaches.exists(type))
    {
      var result:Null<Array<AssetPath>> = assetListCaches.get(type);
      // Invalidate empty cache.
      if (result != null && result.length == 0) assetListCaches.remove(type);

      // Accept valid cache.
      if (result != null && result.length > 0) return result;

      // Else, continue.
    }

    // Invalidate cache if we're forcing.
    if (force) assetListBaseCache = null;

    // Actually list the assets and evaluate them by type.
    // If we've already cached the list of ALL the assets, we can start there :)
    var allAssets:Array<String> = assetListBaseCache != null ? assetListBaseCache.map((assetPath) ->
    {
      return assetPath.toString();
    }) : openfl.utils.Assets.list();

    for (assetPath in allAssets)
    {
      if (type == null || AssetsUtil.guessTypeByExtension(assetPath) == type)
      {
        var path:haxe.io.Path = new haxe.io.Path(assetPath);
        var dir:String = path.dir ?? '';
        var file:String = path.file;
        var ext:String = path.ext ?? '';
        var library:String = 'default';

        // A bunch of hard-coded asset detections.

        if (dir.startsWith('flixel/'))
        {
          dir = dir.substring('flixel/'.length);
          library = 'flixel';
        }

        if (dir.startsWith('haxeui-flixel/'))
        {
          dir = dir.substring('haxeui-flixel/'.length);
          library = 'haxeui-flixel';
        }

        if (dir == 'assets') dir = 'assets/';

        if (dir.startsWith('assets/')) dir = dir.substring('assets/'.length);

        results.push(Paths.file('$dir/$file', '$ext', true, library));
      }
    }

    // Cache the final list.
    if (type != null)
    {
      #if FEATURE_DEBUG_TRACY
      cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.assetListCache($type)');
      #end
      assetListCaches.set(type, results);
    }
    else
    {
      #if FEATURE_DEBUG_TRACY
      cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.assetListCache(base)');
      #end
      assetListBaseCache = results;
    }

    return results;
  }

  /**
   * FunkinAssetCache caches the result of `Assets.list()` for improved performance,
   * but sometimes you need to redo the cache (like when the mod list changes).
   *
   * @param force `true` to ignore any existing cache, `false` to only rebuild empty caches.
   */
  public function cacheAssetLists(force:Bool = false):Void
  {
    var perf = new funkin.util.logging.Perf('cacheAssetLists(${force})');
    // Cache the results of Assets.list(), forcibly clearing any previous cache.
    FunkinAssetCache.instance.list(null, force);
    @:privateAccess
    for (type in Assets.ASSET_TYPES)
    {
      FunkinAssetCache.instance.list(type, force);
    }
    perf.print();
  }

  /**
   * Fetch a BitmapData asynchronously and cache it.
   * If it's previously cached, it will be returned immediately.
   *
   * @param assetPath The path of the asset to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @param uploadToGPU Whether or not to upload the BitmapData to the GPU, and delete the original image.
   *   This saves memory but breaks some functions that require accessing or drawing on the original image.
   * @return A future that returns whether or not the BitmapData has been succesfully cached.
   */
  public function cacheBitmapData(assetPath:AssetPath, permanent:Bool = false, uploadToGPU:Bool = true):Future<Bool>
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.cacheBitmapData(${assetPath.toString()})');
    #end

    threadCheck('cacheBitmapData(${assetPath.toString()})');

    var promise = new Promise<Bool>();

    fetchBitmapData(assetPath, uploadToGPU).then((bitmapData:BitmapData) ->
    {
      // On success, resolve the promise with true
      if (validateBitmapData(bitmapData))
      {
        var _:Int = bitmapData.width; // Trigger
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' Cached BitmapData: ${assetPath.toString()}');
        #end
      }

      if (permanent)
      {
        stagedBitmapData.cachePermanent(assetPath.toString(), bitmapData);
      }
      promise.complete(validateBitmapData(bitmapData));
      return Future.withValue(bitmapData);
    }).onError((err) ->
      {
        trace(' ASSETS '.bold().bg_lime() + ' ERROR '.error() + ' Error while caching BitmapData (${assetPath}): ${err}');
        // On failure, intercept the error and safely resolve with false
        promise.complete(false);
      });

    return promise.future;
  }

  /**
   * Fetch a FlxGraphic asynchronously and cache it.
   * If it's previously cached, it will be returned immediately.
   *
   * @param assetPath The path of the asset to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @param uploadToGPU Whether or not to upload the FlxGraphic to the GPU, and delete the original image.
   *   This saves memory but breaks some functions that require accessing or drawing on the original image.
   * @return A future that returns whether or not the BitmapData has been succesfully cached.
   */
  public function cacheFlxGraphic(assetPath:AssetPath, permanent:Bool = false, uploadToGPU:Bool = true):Future<Bool>
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.cacheFlxGraphic(${assetPath.toString()})');
    #end

    threadCheck('cacheFlxGraphic(${assetPath.toString()})');

    var promise = new Promise<Bool>();

    fetchFlxGraphic(assetPath, uploadToGPU).then((flxGraphic:FlxGraphic) ->
    {
      if (FunkinBitmapFrontend.instance.isValid(flxGraphic))
      {
        flxGraphic.bitmap?.getTexture(FlxG.stage.context3D);
      }

      if (permanent)
      {
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' Cached FlxGraphic: ${assetPath.toString()}');
        #end
        FunkinBitmapFrontend.instance.stagedFlxGraphic.cachePermanent(assetPath.toString(), flxGraphic);
        cacheBitmapData(assetPath, true, true); // We need the bitmapdata to persist too.
      }

      // On success, resolve the promise with true
      promise.complete(FunkinBitmapFrontend.instance.isValid(flxGraphic));
      return Future.withValue(flxGraphic);
    }).onError((err) ->
      {
        trace(' ASSETS '.bold().bg_lime() + ' ERROR '.error() + ' Error while caching BitmapData (${assetPath}): ${err}');
        // On failure, intercept the error and safely resolve with false
        promise.complete(false);
      });

    return promise.future;
  }

  /**
   * Cache a Sound asynchronously.
   * If it's previously cached, it will be returned immediately.
   *
   * @param assetPath The path of the asset to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future that returns whether or not the Sound has been succesfully cached.
   */
  public function cacheSound(assetPath:AssetPath, permanent:Bool = false):Future<Bool>
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.cacheSound(${assetPath.toString()})');
    #end

    threadCheck('cacheSound(${assetPath.toString()})');

    var promise = new Promise<Bool>();

    fetchSound(assetPath).then((sound:Sound) ->
    {
      // On success, resolve the promise with true

      if (permanent)
      {
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' Cached Sound: ${assetPath.toString()}');
        #end
        stagedSound.cachePermanent(assetPath.toString(), sound);
      }

      promise.complete(sound != null);
      return Future.withValue(sound);
    }).onError((err) ->
      {
        trace(' ASSETS '.bold().bg_lime() + ' ERROR '.error() + ' Error while fetching Sound (${assetPath}): ${err}');
        // On failure, intercept the error and safely resolve with false
        promise.complete(false);
      });

    return promise.future;
  }

  /**
   * Cache a text asynchronously.
   * If it's previously cached, it will be returned immediately.
   *
   * @param assetPath The path of the asset to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future that returns whether or not the text has been succesfully cached.
   */
  public function cacheText(assetPath:AssetPath, permanent:Bool = false):Future<Bool>
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.cacheText(${assetPath.toString()})');
    #end

    threadCheck('cacheText(${assetPath.toString()})');

    var promise = new Promise<Bool>();

    fetchText(assetPath).then((text:String) ->
    {
      // On success, resolve the promise with true

      if (permanent)
      {
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' Cached Text: ${assetPath.toString()}');
        #end
        stagedText.cachePermanent(assetPath.toString(), text);
      }

      promise.complete(text != null && text != '');
      return Future.withValue(text);
    }).onError((err) ->
      {
        trace(' ASSETS '.bold().bg_lime() + ' ERROR '.error() + ' Error while fetching Text (${assetPath}): ${err}');
        // On failure, intercept the error and safely resolve with false
        promise.complete(false);
      });

    return promise.future;
  }

  /**
   * Cache a font asynchronously.
   * If it's previously cached, it will be returned immediately.
   *
   * @param assetPath The path of the asset to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future that returns whether or not the font has been succesfully cached.
   */
  public function cacheFont(assetPath:AssetPath):Future<Bool>
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.cacheFont(${assetPath.toString()})');
    #end

    threadCheck('cacheFont(${assetPath.toString()})');

    var promise = new Promise<Bool>();

    fetchFont(assetPath).then((font:Font) ->
    {
      // On success, resolve the promise with true
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS '.bold().bg_lime() + ' Cached Font: ${assetPath.toString()}');
      #end

      // Always permanent cache fonts.
      stagedFont.cachePermanent(assetPath.toString(), font);

      promise.complete(font != null);
      return Future.withValue(font);
    }).onError((err) ->
      {
        trace(' ASSETS '.bold().bg_lime() + ' ERROR '.error() + ' Error while fetching Font (${assetPath}): ${err}');
        // On failure, intercept the error and safely resolve with false
        promise.complete(false);
      });

    return promise.future;
  }

  /**
   * Cache a file's bytes asynchronously.
   *
   * @param assetPath The path of the asset to cache.
   * @param permanent If `true`, cache the asset permanently, persisting between state switches.
   * @return A future that returns whether or not the Bytes has been succesfully cached.
   */
  public function cacheBytes(assetPath:AssetPath, permanent:Bool = false):Future<Bool>
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.cacheBytes(${assetPath.toString()})');
    #end

    threadCheck('cacheBytes(${assetPath.toString()})');

    var promise = new Promise<Bool>();

    fetchBytes(assetPath).then((bytes:ByteArray) ->
    {
      // On success, resolve the promise with true

      if (bytes != null && permanent)
      {
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' Cached Bytes: ${assetPath.toString()}');
        #end
        stagedBytes.cachePermanent(assetPath.toString(), bytes);
      }

      promise.complete(bytes != null);
      return Future.withValue(bytes);
    }).onError((err) ->
      {
        trace(' ASSETS '.bold().bg_lime() + ' ERROR '.error() + ' Error while fetching Bytes (${assetPath}): ${err}');
        // On failure, intercept the error and safely resolve with false
        promise.complete(false);
      });

    return promise.future;
  }

  // Helper functions to be used in other classes so we avoid really really long lines.
  // also useful for adding persistent objects into the game that dont need assetpaths.

  /**
   * Adds the FlxGraphic to the cache permanently.
   * @param key The key for the cache.
   * @param flxGraphic The FlxGraphicAsset to cache.
   */
  public function permaCacheFlxGraphic(key:String, flxGraphic:FlxGraphicAsset):FlxGraphic
  {
    var graphic:FlxGraphic = setFlxGraphic(key, flxGraphic);
    FunkinBitmapFrontend.instance.stagedFlxGraphic.cachePermanent(key, graphic);
    permaCacheBitmapData(key, graphic.bitmap);
    return graphic;
  }

  /**
   * Adds the bitmap to the cache permanently.
   * @param key The key for the cache.
   * @param bitmap The BitmapData to cache.
   */
  public function permaCacheBitmapData(key:String, bitmap:BitmapData):Void
  {
    setBitmapData(key, bitmap);
    stagedBitmapData.cachePermanent(key, bitmap);
  }

  /**
   * Adds the bytes to the cache permanently.
   * @param key The key for the cache.
   * @param bytes The Bytes to cache.
   */
  public function permaCacheBytes(key:String, bytes:Bytes):Void
  {
    setBytes(key, bytes);
    stagedBytes.cachePermanent(key, bytes);
  }

  /**
   * Adds the text to the cache permanently.
   * @param key The key for the cache.
   * @param text The text to cache.
   */
  public function permaCacheText(key:String, text:String):Void
  {
    setText(key, text);
    stagedText.cachePermanent(key, text);
  }

  /**
   * Adds the sound to the cache permanently.
   * @param key The key for the cache.
   * @param sound The Sound to cache.
   */
  public function permaCacheSound(key:String, sound:Sound):Void
  {
    setSound(key, sound);
    stagedSound.cachePermanent(key, sound);
  }

  /**
   * @param bitmapData The `BitmapData` to check.
   * @return Whether the `BitmapData` is invalid (the underlying image got uncached) and needs to be reloaded.
   */
  public function validateBitmapData(bitmapData:BitmapData):Bool
  {
    // Check if the graphic is valid before returning.
    if (bitmapData == null) return false;
    @:privateAccess
    if (bitmapData.image == null && bitmapData.__texture == null)
    {
      // The bitmap has neither an image (yet to be uploaded) nor a __texture (already uploaded to GPU)
      return false;
    }
    if (bitmapData.width == 0 || bitmapData.height == 0)
    {
      // The bitmap has no width or height, which means the bitmap is valid but empty, which is definitely wrong.
      return false;
    }

    return true;
  }

  /**
   * @param frame The `FlxFrame` to check.
   * @return Whether the `FlxFrame` is invalid (the underlying image got uncached) and needs to be reloaded.
   */
  public function validateFrame(frame:FlxFrame):Bool
  {
    if (frame == null) return false;

    if (!FunkinBitmapFrontend.instance.isValid(frame.parent)) return false;

    return true;
  }

  /**
   * @param frames The `FlxFramesCollection` to check.
   * @return Whether the `FlxFramesCollection` is invalid (the underlying image got uncached) and needs to be reloaded.
   */
  public function validateFramesCollection(frames:FlxFramesCollection):Bool
  {
    if (frames == null) return false;
    if (frames.frames.length == 0) return false;

    for (frame in frames.frames)
    {
      if (!validateFrame(frame))
      {
        trace('Frame "${frame.name}" is invalid, did you uncache the underlying graphic?');
        return false;
      }
    }

    return true;
  }

  /**
   * A debugging function which prints the contents of the asset cache.
   */
  public function debug_listCachedAssets():Void
  {
    trace(' ASSETS '.bold().bg_lime() + ' Cached assets:');
    trace(' ASSETS '.bold().bg_lime() + ' BITMAP DATA:');
    var keys:Array<String> = stagedBitmapData.keys();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace(' ASSETS '.bold().bg_lime() + '- $key');
    }

    trace(' ASSETS '.bold().bg_lime() + ' FLX GRAPHIC:');
    var keys:Array<String> = FunkinBitmapFrontend.instance.stagedFlxGraphic.keys();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace(' ASSETS '.bold().bg_lime() + ' - $key');
    }

    trace(' ASSETS '.bold().bg_lime() + ' FONT:');
    var keys:Array<String> = stagedFont.keys();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace(' ASSETS '.bold().bg_lime() + ' - $key');
    }

    trace(' ASSETS '.bold().bg_lime() + ' SOUND:');
    var keys:Array<String> = stagedSound.keys();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace(' ASSETS '.bold().bg_lime() + '- $key');
    }

    trace(' ASSETS '.bold().bg_lime() + ' TEXT:');
    var keys:Array<String> = stagedText.keys();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace(' ASSETS '.bold().bg_lime() + ' - $key');
    }

    trace(' ASSETS '.bold().bg_lime() + 'BYTES:');
    var keys:Array<String> = stagedBytes.keys();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace(' ASSETS '.bold().bg_lime() + ' - $key');
    }
  }

  public function toString():String
  {
    return 'FunkinAssetCache';
  }

  /**
   * Asset caching creates a task in another to perform the asset loading.
   * For some reason, trying to do this outside the main thread causes the task to never start.
   * Eric's solution: Complain if you try to call cacheBytes from outside the main thread.
   */
  static inline function threadCheck(info:String):Void
  {
    // if (!TaskHandler;.isMainThread())
    if (false)
    {
      trace(' ERROR '.error() + ' $info: Tried to queue asset caching from the main thread.');
      throw '$info: Tried to queue asset caching from the main thread.';
    }
  }

  function get_enabled():Bool
  {
    return true;
  }

  function set_enabled(value:Bool):Bool
  {
    if (!enabled) throw 'FunkinAssetCache cannot be disabled!';
    return enabled;
  }
}

/**
 * An override for the Lime AssetCache class to provide additional logging.
 */
class FunkinLimeAssetCache extends LimeAssetCache
{
  /**
   * The singleton instance of the FunkinLimeAssetCache.
   */
  public static var instance(get, never):FunkinLimeAssetCache;

  static var _instance:Null<FunkinLimeAssetCache> = null;

  static function get_instance():FunkinLimeAssetCache
  {
    if (FunkinLimeAssetCache._instance == null) _instance = new FunkinLimeAssetCache();
    if (FunkinLimeAssetCache._instance == null) throw 'Could not initialize singleton FunkinLimeAssetCache!';
    return FunkinLimeAssetCache._instance;
  }

  var cb_audio:CallbackMap<LimeAudioBuffer> = new CallbackMap();
  var cb_font:CallbackMap<Font> = new CallbackMap();
  var cb_image:CallbackMap<LimeImage> = new CallbackMap();

  static final ASSET_CACHE_VERSION:Int = 1_000;

  public function new()
  {
    super();

    version = ASSET_CACHE_VERSION;

    cb_audio.onGet.add((key:String) -> {
      #if VERBOSE_ASSET_CACHE
      trace('[LIME] Retrieved cached audio: ' + key);
      #end
    });

    cb_audio.onSet.add((key:String, value:LimeAudioBuffer) -> {
      // trace('[LIME] Cached audio: ' + key);
    });

    cb_font.onGet.add((key:String) -> {
      #if VERBOSE_ASSET_CACHE
      trace('[LIME] Retrieved cached font: ' + key);
      #end
    });

    cb_font.onSet.add((key:String, value:Font) -> {
      #if VERBOSE_ASSET_CACHE
      trace('[LIME] Cached font: ' + key);
      #end
    });

    cb_image.onGet.add((key:String) -> {
      #if VERBOSE_ASSET_CACHE
      trace('[LIME] Retrieved cached image: ' + key);
      #end
    });

    cb_image.onSet.add((key:String, value:LimeImage) -> {
      #if VERBOSE_ASSET_CACHE
      trace('[LIME] Cached image: ' + key);
      #end
    });
  }

  /**
   * Returns `true` if the asset with the given ID exists in the cache.
   * @param id The asset ID.
   * @param assetType The asset type.
   * @return Whether the asset exists in the cache.
   */
  override public function exists(id:String, ?assetType:LimeAssetType):Bool
  {
    if (assetType == LimeAssetType.IMAGE || assetType == null)
    {
      if (cb_image.exists(id)) return true;
    }

    if (assetType == LimeAssetType.FONT || assetType == null)
    {
      if (cb_font.exists(id)) return true;
    }

    if (assetType == LimeAssetType.SOUND || assetType == LimeAssetType.MUSIC || assetType == null)
    {
      if (cb_audio.exists(id)) return true;
    }

    return false;
  }

  override public function set(id:String, assetType:LimeAssetType, asset:Dynamic):Void
  {
    switch (assetType)
    {
      case FONT:
        cb_font.set(id, asset);

      case IMAGE:
        if (!(asset is LimeImage)) throw 'Cannot cache non-Image asset: ' + asset + ' as Image';

        cb_image.set(id, asset);

      case SOUND, MUSIC:
        if (!(asset is LimeAudioBuffer)) throw 'Cannot cache non-AudioBuffer asset: ' + asset + ' as AudioBuffer';

        cb_audio.set(id, asset);

      default:
        throw assetType + ' assets are not cachable';
    }
  }

  /**
   * Clear the cache.
   * @param prefix The prefix of the assets to clear.
   */
  override public function clear(?prefix:String):Void
  {
    if (prefix == null)
    {
      // Clear maps without overriding them, to preserve callbacks.
      cb_audio.clear();
      cb_font.clear();
      cb_image.clear();
    }
    else
    {
      for (key in cb_audio.keys())
      {
        if (StringTools.startsWith(key, prefix))
        {
          cb_audio.remove(key);
        }
      }

      for (key in cb_font.keys())
      {
        if (StringTools.startsWith(key, prefix))
        {
          cb_font.remove(key);
        }
      }

      for (key in cb_image.keys())
      {
        if (StringTools.startsWith(key, prefix))
        {
          cb_image.remove(key);
        }
      }
    }
  }

  /**
   * @return A list of keys in the audio cache.
   */
  public function audioKeys():Array<String>
  {
    return cb_audio.keyValues();
  }

  /**
   * @return The number of keys in the audio cache.
   */
  public function audioSize():Int
  {
    return cb_audio.size();
  }

  /**
   * @return A list of keys in the font cache.
   */
  public function fontKeys():Array<String>
  {
    return cb_font.keyValues();
  }

  /**
   * @return The number of keys in the font cache.
   */
  public function fontSize():Int
  {
    return cb_font.size();
  }

  /**
   * @return A list of keys in the image cache.
   */
  public function imageKeys():Array<String>
  {
    return cb_image.keyValues();
  }

  /**
   * @return The number of keys in the image cache.
   */
  public function imageSize():Int
  {
    return cb_image.size();
  }

  /**
   * Remove an audio from the cache by key.
   * @param id The key of the audio to remove.
   */
  public function removeAudio(id:String):Void
  {
    cb_audio.remove(id);
  }

  /**
   * Remove a font from the cache by key.
   * @param id The key of the font to remove.
   */
  public function removeFont(id:String):Void
  {
    cb_font.remove(id);
  }

  /**
   * Remove an image from the cache by key.
   * @param id The key of the image to remove.
   */
  public function removeImage(id:String):Void
  {
    cb_image.remove(id);
  }

  public function toString():String
  {
    return 'FunkinLimeAssetCache(${audioSize()} audios, ${fontSize()} fonts, ${imageSize()} images)';
  }
}
