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
import lime.media.AudioBuffer as LimeAudioBuffer;
import lime.utils.AssetCache as LimeAssetCache;
import lime.utils.AssetType as LimeAssetType;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.Assets as OpenFLAssets;
import openfl.utils.ByteArray;
import openfl.utils.IAssetCache as OpenFLIAssetCache;

// @:nullSafety

/**
 * An override for the OpenFL AssetCache class to override the internal cache with our own.
 * This allows us to be more specific about when assets are cached, and when they are purged.
 */
class FunkinAssetCache implements OpenFLIAssetCache
{
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
      // asset.close();
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
      FunkinBitmapFrontend.instance.stagedFlxGraphic,
      stagedBitmapData,
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
   * @param prefix (Optional) Only asset paths starting with this prefix will be cleared.
   */
  public function clear(?prefix:String):Void
  {
    if (prefix == null)
    {
      trace('[ASSETS] Force clearing asset cache...');
      for (cache in stagedCaches) cache.clearCache();
      FunkinBitmapFrontend.instance.reset();
      assetListCaches = [];
      assetListBaseCache = null;
    }
    else
    {
      trace('[ASSETS] Force clearing cached assets with prefix: $prefix');
      for (cache in stagedCaches) cache.clearCacheByPrefix(prefix);
      FunkinBitmapFrontend.instance.resetByPrefix(prefix);
    }
  }

  /**
   * Prepare to purge the asset cache.
   * Attempting to recache any assets that were previously cached will just move them to the new cache.
   * Later, any old assets that the game didn't try to use again will be destroyed, saving memory.
   */
  public function preparePurgeCache():Void
  {
    for (cache in stagedCaches) cache.preparePurgeCache();
  }

  /**
   * Purge any assets that were previously cached, but weren't requested again since `preparePurgeCache()` was called.
   *
   * @param garbageCollect Whether to forcibly invoke the system's garbage collector after purging assets.
   */
  public function purgeCache(garbageCollect:Bool = false):Void
  {
    for (cache in stagedCaches) cache.purgeCache();
    // TODO: Cleanup purging to work with Freeplay?
    FunkinBitmapFrontend.instance.clearExcept(['freeplay/', 'stickers/']);
    // ^ Clear everything but freeplay as that has its own process, may or may not still be here depending on the future loading changes.

    // Perform garbage collection here, after we deleted a bunch of stuff, to free the memory we're no longer using.
    #if (cpp || neko || hl)
    if (garbageCollect) funkin.util.MemoryUtil.collect(true);
    #end
  }

  /**
   * Fetch a FlxGraphic from the cache synchronously.
   * @param id The asset id of the FlxGraphic.
   * @throws error If the FlxGraphic does not exist in the cache and strict asset caching is enabled.
   * @return The FlxGraphic, if available.
   */
  public function getFlxGraphic(id:String):FlxGraphic
  {
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
    var result:Null<BitmapData> = stagedBitmapData.get(id);
    if (result != null)
    {
      return result;
    }
    else
    {
      // trace('[ASSETS] Bitmap data not found in cache: ' + id);
      #if FEATURE_STRICT_ASSET_CACHING
      throw 'Bitmap data not cached, cannot load synchronously: $id';
      #else
      // FlxG.log.warn('Texture not cached, may experience stuttering! ${id}');
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
    var result:Null<Font> = stagedFont.get(id);
    if (result != null)
    {
      trace('[ASSETS] Font data found in cache: ' + id);
      return result;
    }
    else
    {
      #if FEATURE_STRICT_ASSET_CACHING
      throw 'Font not cached, cannot load synchronously: $id';
      #else
      // FlxG.log.warn('Font not cached, may experience stuttering! ${id}');
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
        trace(' ASSETS '.bg_green() + 'Text file does not exist: $id');
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
   * @return The atlas frames, if available.
   */
  public function getSparrowAtlas(assetPath:AssetPath):FlxAtlasFrames
  {
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
    var txtAssetPath = assetPath.withAssetType(TEXT);

    var graphic:FlxGraphic = getFlxGraphic(assetPath.toString());
    var data:String = getText(txtAssetPath.toString());
    return FlxAtlasFrames.fromSpriteSheetPacker(graphic, data);
  }

  /**
   * Check if a FlxGraphic exists in the cache.
   * @param path The asset path of the FlxGraphic.
   * @return `true` if the FlxGraphic exists in the cache, `false` otherwise.
   */
  public function hasFlxGraphic(path:AssetPath):Bool
  {
    return FunkinBitmapFrontend.instance.stagedFlxGraphic.exists(path.toString());
  }

  /**
   * Check if a BitmapData exists in the cache.
   * @param id The asset id of the BitmapData.
   * @return `true` if the BitmapData exists in the cache, `false` otherwise.
   */
  public function hasBitmapData(id:String):Bool
  {
    return stagedBitmapData.exists(id);
  }

  /**
   * Check if a Font exists in the cache.
   * @param id The asset id of the Font.
   * @return `true` if the Font exists in the cache, `false` otherwise.
   */
  public function hasFont(id:String):Bool
  {
    return stagedFont.exists(id);
  }

  /**
   * Check if a Sound exists in the cache.
   * @param id The asset id of the Sound.
   * @return `true` if the Sound exists in the cache, `false` otherwise.
   */
  public function hasSound(id:String):Bool
  {
    return stagedSound.exists(id);
  }

  /**
   * Check if a Text exists in the cache.
   * @param id The asset id of the Text.
   * @return `true` if the Text exists in the cache, `false` otherwise.
   */
  public function hasText(id:String):Bool
  {
    return stagedText.exists(id);
  }

  /**
   * Check if a file's Bytes exists in the cache.
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
  function setFlxGraphic(id:String, flxGraphic:FlxGraphic):Void
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.setFlxGraphic($id)');
    #end
    // Make sure we don't accidentally dispose the bitmap associated with this FlxGraphic.
    var bitmap:Null<BitmapData> = stagedBitmapData.get(id);
    if (bitmap != null)
    {
      setBitmapData(id, bitmap);
    }
    else
    {
      throw 'Could not locate bitmap data for cached graphic ($id)';
    }
    // Make sure we don't accidentally destroy the graphic while we're using it.
    flxGraphic.persist = true;
    flxGraphic.destroyOnNoUse = false;
    FunkinBitmapFrontend.instance.add(flxGraphic, id);
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
    stagedFont.cache(id, font);
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
    if (hasBitmapData(assetPath.toString()))
    {
      return Future.withValue(getBitmapData(assetPath.toString()));
    }
    else
    {
      var future:Future<BitmapData> = OpenFLAssets.loadBitmapData(assetPath.toString(), false).then((bitmapData:BitmapData) ->
      {
        // Upload to the GPU only if the feature is enabled and the asset doesn't require pixel data in memory.
        if (uploadToGPU && !assetPath.needsPixelData)
        {
          bitmapData = AssetsUtil.uploadBitmapDataToGPU(bitmapData);
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
        var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmapData, false, null, false);
        setFlxGraphic(assetPath.toString(), graphic);
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
        return Future.withValue(text);
      });
    }
  }

  /**
   * Fetch bytes from a file asynchronously and return it.
   *
   * @param assetPath The path of the asset to fetch.
   * @return The bytes, if fetched.
   */
  public function fetchBytes(assetPath:AssetPath):Future<openfl.utils.ByteArray>
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

    if (!force && type != null && assetListCaches.exists(type))
    {
      var result:Null<Array<AssetPath>> = assetListCaches.get(type);
      // Invalidate empty cache.
      if (result != null && result.length == 0) assetListCaches.remove(type);

      // Accept valid cache.
      if (result != null && result.length > 0) return result;

      // Else, continue.
    }

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

        if (dir.startsWith('flxanimate/'))
        {
          dir = dir.substring('flxanimate/'.length);
          library = 'flxanimate';
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
   * Fetch a BitmapData asynchronously and cache it.
   * If it's previously cached, it will be returned immediately.
   * @param assetPath The path of the asset to cache.
   * @param uploadToGPU Whether or not to upload the BitmapData to the GPU, and delete the original image.
   *   This saves memory but breaks some functions that require accessing or drawing on the original image.
   * @return A future for the BitmapData for the asset.
   */
  public function cacheBitmapData(assetPath:AssetPath, uploadToGPU:Bool = true):Future<BitmapData>
  {
    threadCheck('cacheBitmapData(${assetPath.toString()})');

    if (hasBitmapData(assetPath.toString()))
    {
      return Future.withValue(getBitmapData(assetPath.toString()));
    }

    var recachedBitmapData:Null<BitmapData> = stagedBitmapData.get(assetPath.toString());
    if (recachedBitmapData != null)
    {
      // This line exists because null-safety creates a Future<Null<T>> instead of a Future<T>.
      var value:BitmapData = recachedBitmapData;
      return Future.withValue(value);
    }

    // bitmap is NULL augghghggh
    var future:Future<BitmapData> = OpenFLAssets.loadBitmapData(assetPath.toString(), false).then((bitmapData:BitmapData) ->
    {
      if (uploadToGPU)
      {
        bitmapData = AssetsUtil.uploadBitmapDataToGPU(bitmapData);
      }
      setBitmapData(assetPath.toString(), bitmapData);
      return Future.withValue(bitmapData);
    }).onError((err) ->
    {
      trace('[ASSETS] Error while fetching BitmapData (${assetPath}): ${err}');
    });
    return future;
  }

  /**
   * Fetch a FlxGraphic asynchronously and cache it.
   * If it's previously cached, it will be returned immediately.
   * @param assetPath The path of the asset to cache.
   * @param uploadToGPU Whether or not to upload the FlxGraphic to the GPU, and delete the original image.
   *   This saves memory but breaks some functions that require accessing or drawing on the original image.
   * @return A future for the FlxGraphic for the asset.
   */
  public function cacheFlxGraphic(assetPath:AssetPath, ?uploadToGPU:Bool):Future<FlxGraphic>
  {
    threadCheck('cacheFlxGraphic(${assetPath.toString()})');

    if (hasFlxGraphic(assetPath))
    {
      return Future.withValue(getFlxGraphic(assetPath.toString()));
    }

    var recachedFlxGraphic:Null<Future<FlxGraphic>> = recacheFlxGraphic(assetPath, uploadToGPU);
    if (recachedFlxGraphic != null) return recachedFlxGraphic;

    // NOTE: This also caches the BitmapData. Nice.
    var future:Future<FlxGraphic> = this.fetchBitmapData(assetPath, uploadToGPU).then((bitmapData:BitmapData) ->
    {
      // Create an FlxGraphic from the BitmapData.
      var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmapData, false, null, false);
      setFlxGraphic(assetPath.toString(), graphic);
      return Future.withValue(graphic);
    }).onError((err) ->
    {
      trace('[ASSETS] Error while fetching FlxGraphic (${assetPath}): ${err}');
    });
    return future;
  }

  function recacheFlxGraphic(assetPath:AssetPath, ?uploadToGPU:Bool):Null<Future<FlxGraphic>>
  {
    if (!FunkinBitmapFrontend.instance.stagedFlxGraphic.exists(assetPath.toString())) return null;

    // NOTE: This moves the bitmap data from the previous cache to the current cache.
    var future:Future<FlxGraphic> = this.cacheBitmapData(assetPath, uploadToGPU).then((_bitmapData:BitmapData) ->
    {
      var cacheValue:Null<FlxGraphic> = FunkinBitmapFrontend.instance.stagedFlxGraphic.get(assetPath.toString());
      if (cacheValue == null) throw 'Whuh?';
      var validCacheValue:FlxGraphic = cacheValue;
      return Future.withValue(validCacheValue);
    });
    return future;
  }

  /**
   * Cache a Sound asynchronously.
   * @param assetPath The path of the asset to cache.
   * @return A future for the Sound for the asset.
   */
  public function cacheSound(assetPath:AssetPath):Future<Sound>
  {
    threadCheck('cacheSound(${assetPath.toString()})');

    if (hasSound(assetPath.toString()))
    {
      return Future.withValue(getSound(assetPath.toString()));
    }

    var recachedSound:Null<Sound> = stagedSound.get(assetPath.toString());
    if (recachedSound != null)
    {
      // This line exists because null-safety creates a Future<Null<T>> instead of a Future<T>.
      var value:Sound = recachedSound;
      return Future.withValue(value);
    }

    return fetchSound(assetPath).then((sound:Sound) ->
    {
      return Future.withValue(sound);
    }).onError((err) ->
    {
      trace('[ASSETS] Error while fetching Sound (${assetPath}): ${err}');
    });
  }

  /**
   * Cache a text asynchronously.
   * @param assetPath The path of the asset to cache.
   * @return A future for the text for the asset.
   */
  public function cacheText(assetPath:AssetPath):Future<String>
  {
    threadCheck('cacheText(${assetPath.toString()})');

    if (hasText(assetPath.toString()))
    {
      return Future.withValue(getText(assetPath.toString()));
    }

    var recachedText:Null<String> = stagedText.get(assetPath.toString());
    if (recachedText != null)
    {
      // This line exists because null-safety creates a Future<Null<T>> instead of a Future<T>.
      var value:String = recachedText;
      return Future.withValue(value);
    }

    return fetchText(assetPath).then((text:String) ->
    {
      return Future.withValue(text);
    }).onError((err) ->
    {
      trace('[ASSETS] Error while fetching Text (${assetPath}): ${err}');
    });
  }

  /**
   * Cache a file's bytes asynchronously.
   * @param assetPath The path of the asset to cache.
   * @return A future for the bytes for the asset.
   */
  public function cacheBytes(assetPath:AssetPath):Future<ByteArray>
  {
    threadCheck('cacheBytes(${assetPath.toString()})');

    if (hasBytes(assetPath.toString()))
    {
      return Future.withValue(getBytes(assetPath.toString()));
    }

    var recachedBytes:Null<ByteArray> = stagedBytes.get(assetPath.toString());
    if (recachedBytes != null)
    {
      // This line exists because null-safety creates a Future<Null<T>> instead of a Future<T>.
      var value:ByteArray = recachedBytes;
      return Future.withValue(value);
    }

    return fetchBytes(assetPath).then((bytes:ByteArray) ->
    {
      return Future.withValue(bytes);
    }).onError((err) ->
    {
      trace('[ASSETS] Error while fetching Bytes (${assetPath}): ${err}');
    });
  }

  /**
   * A debugging function which prints the contents of the asset cache.
   */
  public function debug_listCachedAssets():Void
  {
    trace('[ASSETS] Cached assets:');
    trace('[ASSETS] BITMAP DATA:');
    var keys:Array<String> = stagedBitmapData.keys();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace('[ASSETS] - $key');
    }

    trace('[ASSETS] FLX GRAPHIC:');
    var keys:Array<String> = FunkinBitmapFrontend.instance.stagedFlxGraphic.keys();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace('[ASSETS] - $key');
    }

    trace('[ASSETS] FONT:');
    var keys:Array<String> = stagedFont.keys();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace('[ASSETS] - $key');
    }

    trace('[ASSETS] SOUND:');
    var keys:Array<String> = stagedSound.keys();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace('[ASSETS] - $key');
    }

    trace('[ASSETS] TEXT:');
    var keys:Array<String> = stagedText.keys();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace('[ASSETS] - $key');
    }

    trace('[ASSETS] BYTES:');
    var keys:Array<String> = stagedBytes.keys();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace('[ASSETS] - $key');
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
      trace(' ERROR '.error() + '$info: Tried to queue asset caching from the main thread.');
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

  /**
   * A dummy cache. IAssetCache mandates that these exist but we don't use them.
   */
  public var bitmapData:Map<String, BitmapData> = [];

  /**
   * A dummy cache. IAssetCache mandates that these exist but we don't use them.
   */
  public var font:Map<String, Font> = [];

  /**
   * A dummy cache. IAssetCache mandates that these exist but we don't use them.
   */
  public var sound:Map<String, Sound> = [];
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

    cb_audio.onGet.add((key:String) ->
    {
      trace('[LIME] Retrieved cached audio: ' + key);
    });

    cb_audio.onSet.add((key:String, value:LimeAudioBuffer) ->
    {
      trace('[LIME] Cached audio: ' + key);
    });

    cb_font.onGet.add((key:String) ->
    {
      trace('[LIME] Retrieved cached font: ' + key);
    });

    cb_font.onSet.add((key:String, value:Font) ->
    {
      trace('[LIME] Cached font: ' + key);
    });

    cb_image.onGet.add((key:String) ->
    {
      trace('[LIME] Retrieved cached image: ' + key);
    });

    cb_image.onSet.add((key:String, value:LimeImage) ->
    {
      trace('[LIME] Cached image: ' + key);
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
    return 'FunkinLimeAssetCache';
  }
}
