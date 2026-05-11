package funkin.assets;

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

/**
 * An override for the OpenFL AssetCache class to override the internal cache with our own.
 * This allows us to be more specific about when assets are cached, and when they are purged.
 */
@:nullSafety
class FunkinAssetCache implements OpenFLIAssetCache
{
  /**
   * Cache containing FlxGraphics
   */
  var current_flxGraphic:Map<String, FlxGraphic>;

  /**
   * Cache containing BitmapDatas (usually for FlxGraphics)
   */
  var current_bitmapData:Map<String, BitmapData>;

  /**
   * Cache containing Fonts
   */
  var current_font:Map<String, Font>;

  /**
   * Cache containing Sounds
   */
  var current_sound:Map<String, Sound>;

  /**
   * Cache containing Text (such as JSON or TXT files)
   */
  var current_text:Map<String, String>;

  /**
   * Cache containing Binary data (anything not covered by its own cache)
   */
  var current_bytes:Map<String, openfl.utils.ByteArray>;

  // Previous caches hold the assets that were previously cached, but weren't requested again since `preparePurgeCache()` was called.
  // If `purgeCache()` is called, any assets in these caches will be destroyed, and their memory will be freed.
  var previous_flxGraphic:Map<String, FlxGraphic>;
  var previous_bitmapData:Map<String, BitmapData>;
  var previous_font:Map<String, Font>;
  var previous_sound:Map<String, Sound>;
  var previous_text:Map<String, String>;
  var previous_bytes:Map<String, openfl.utils.ByteArray>;

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

  function get_enabled():Bool
  {
    return true;
  }

  function set_enabled(value:Bool):Bool
  {
    if (!enabled) throw 'FunkinAssetCache cannot be disabled!';
    return enabled;
  }

  static function get_instance():FunkinAssetCache
  {
    if (FunkinAssetCache._instance == null) _instance = new FunkinAssetCache();
    if (FunkinAssetCache._instance == null) throw 'Could not initialize singleton FunkinAssetCache!';
    return FunkinAssetCache._instance;
  }

  public function new()
  {
    current_flxGraphic = [];
    current_bitmapData = [];
    current_font = [];
    current_sound = [];
    current_text = [];
    current_bytes = [];
    previous_flxGraphic = [];
    previous_bitmapData = [];
    previous_font = [];
    previous_sound = [];
    previous_text = [];
    previous_bytes = [];
    assetListCaches = [];
    assetListBaseCache = null;
    enabled = true;
  }

  /**
   * Hard clear all assets from the asset cache.
   */
  public function clear(?prefix:String):Void
  {
    if (prefix == null)
    {
      trace('[ASSETS] Force clearing asset cache...');

      current_flxGraphic = [];
      current_bitmapData = [];
      current_font = [];
      current_sound = [];
      current_text = [];
      current_bytes = [];
      previous_flxGraphic = [];
      previous_bitmapData = [];
      previous_font = [];
      previous_sound = [];
      previous_text = [];
      previous_bytes = [];

      assetListCaches = [];
      assetListBaseCache = null;
    }
    else
    {
      trace('[ASSETS] Force clearing cached assets with prefix: $prefix');

      for (key in current_flxGraphic.keys())
      {
        if (key.startsWith(prefix))
        {
          removeFlxGraphic(key);
        }
      }
      for (key in current_bitmapData.keys())
      {
        if (key.startsWith(prefix))
        {
          removeBitmapData(key);
        }
      }
      for (key in current_font.keys())
      {
        if (key.startsWith(prefix))
        {
          removeFont(key);
        }
      }
      for (key in current_sound.keys())
      {
        if (key.startsWith(prefix))
        {
          removeSound(key);
        }
      }
      for (key in current_text.keys())
      {
        if (key.startsWith(prefix))
        {
          removeText(key);
        }
      }
      for (key in current_bytes.keys())
      {
        if (key.startsWith(prefix))
        {
          removeBytes(key);
        }
      }
      previous_flxGraphic = [];
      previous_bitmapData = [];
      previous_font = [];
      previous_sound = [];
      previous_text = [];
      previous_bytes = [];
    }
  }

  /**
   * Prepare to purge the asset cache.
   * Attempting to cache any assets that were previously cached will just move them to the new cache.
   * Later, any old assets that the game didn't try to use again will be destroyed, saving memory.
   *
   * @param recachePersistent Whether to automatically move the persistent assets back.
   */
  public function preparePurgeCache(recachePersistent:Bool = true):Void
  {
    previous_flxGraphic = current_flxGraphic;
    current_flxGraphic = [];
    previous_bitmapData = current_bitmapData;
    current_bitmapData = [];
    previous_font = current_font;
    current_font = [];
    previous_sound = current_sound;
    current_sound = [];
    previous_text = current_text;
    current_text = [];
    previous_bytes = current_bytes;
    current_bytes = [];

    if (recachePersistent) recachePersistentAssets();
  }

  /**
   * Query the list of persistent assets, and recache them (i.e. move them from previous_cache to current_cache).
   * This guarantees they stay available between states.
   */
  function recachePersistentAssets():Void
  {
    for (asset in Assets.queryPersistentAssets(IMAGE))
    {
      recacheBitmapData(asset);
    }

    for (asset in Assets.queryPersistentAssets(IMAGE))
    {
      recacheFlxGraphic(asset);
    }

    for (asset in Assets.queryPersistentAssets(SOUND))
    {
      recacheSound(asset);
    }

    for (asset in Assets.queryPersistentAssets(TEXT))
    {
      recacheText(asset);
    }

    for (asset in Assets.queryPersistentAssets(JSON))
    {
      recacheText(asset);
    }

    for (asset in Assets.queryPersistentAssets(SHADER))
    {
      recacheText(asset);
    }

    for (asset in Assets.queryPersistentAssets(SCRIPT))
    {
      recacheText(asset);
    }

    for (asset in Assets.queryPersistentAssets(SCRIPTED_CLASS))
    {
      recacheText(asset);
    }

    for (asset in Assets.queryPersistentAssets(XML))
    {
      recacheText(asset);
    }

    for (asset in Assets.queryPersistentAssets(UNKNOWN))
    {
      recacheBytes(asset);
    }
  }

  /**
   * Purge any assets that were previously cached, but weren't requested again since `preparePurgeCache()` was called.
   */
  public function purgeCache():Void
  {
    for (key in previous_flxGraphic.keys())
    {
      var graphic:Null<FlxGraphic> = previous_flxGraphic.get(key);
      if (graphic == null) continue;
      previous_flxGraphic.remove(key);
      // Actually destroy the graphic.
      FlxG.bitmap.remove(graphic);
      graphic.destroy();
    }
    for (key in previous_bitmapData.keys())
    {
      var bitmapData:Null<BitmapData> = previous_bitmapData.get(key);
      if (bitmapData == null) continue;
      previous_bitmapData.remove(key);
      // Actually destroy the bitmap data.
      FlxDestroyUtil.dispose(bitmapData);
      FunkinLimeAssetCache.instance.removeImage(key);
    }
    for (key in previous_font.keys())
    {
      var font:Null<Font> = previous_font.get(key);
      if (font == null) continue;
      previous_font.remove(key);
      // Actually destroy the font.
      FunkinLimeAssetCache.instance.removeFont(key);
    }
    for (key in previous_sound.keys())
    {
      var sound:Null<Sound> = previous_sound.get(key);
      if (sound == null) continue;
      previous_sound.remove(key);
      // Actually destroy the sound.
      sound.close();
      FunkinLimeAssetCache.instance.removeAudio(key);
    }
    for (key in previous_text.keys())
    {
      var text:Null<String> = previous_text.get(key);
      if (text == null) continue;
      previous_text.remove(key);
      // Actually destroy the text.
      // FunkinLimeAssetCache.instance.removeText(key);
    }
    for (key in previous_bytes.keys())
    {
      var bytes:Null<openfl.utils.ByteArray> = previous_bytes.get(key);
      if (bytes == null) continue;
      previous_bytes.remove(key);
      // Actually destroy the binary.
      // FunkinLimeAssetCache.instance.removeBinary(key);
    }
    // Perform garbage collection here, after we deleted a bunch of stuff, to free the memory we're no longer using.
    MemoryUtil.compact();
  }

  /**
   * Fetch a FlxGraphic from the cache synchronously.
   * @param id The asset id of the FlxGraphic.
   * @throws error If the FlxGraphic does not exist in the cache and strict asset caching is enabled.
   * @return The FlxGraphic, if available.
   */
  public function getFlxGraphic(id:String):FlxGraphic
  {
    var result:Null<FlxGraphic> = current_flxGraphic.get(id);
    if (result != null)
    {
      return result;
    }
    else
    {
      #if FEATURE_STRICT_ASSET_CACHING
      throw 'Flixel graphic not cached, cannot load synchronously: $id';
      #else
      FlxG.log.warn('Texture not cached, may experience stuttering! ${id}');
      var graphic:FlxGraphic = FlxGraphic.fromBitmapData(getBitmapData(id));
      setFlxGraphic(id, graphic);
      return graphic;
      #end
    }
  }

  /**
   * Get a BitmapData, if it exists in the cache.
   * @param id The asset id of the BitmapData.
   * @throws error If the BitmapData does not exist in the cache and strict asset caching is enabled.
   * @return The BitmapData, if available.
   */
  public function getBitmapData(id:String):BitmapData
  {
    var result:Null<BitmapData> = current_bitmapData.get(id);
    if (result != null)
    {
      return result;
    }
    else
    {
      trace('[ASSETS] Bitmap data not found in cache: ' + id);
      #if FEATURE_STRICT_ASSET_CACHING
      throw 'Bitmap data not cached, cannot load synchronously: $id';
      #else
      FlxG.log.warn('Texture not cached, may experience stuttering! ${id}');
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
    var result:Null<Font> = current_font.get(id);
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
      FlxG.log.warn('Font not cached, may experience stuttering! ${id}');
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
    var result:Null<Sound> = current_sound.get(id);
    if (result != null)
    {
      return result;
    }
    else
    {
      #if FEATURE_STRICT_ASSET_CACHING
      throw 'Sound not cached, cannot load synchronously: $id';
      #else
      FlxG.log.warn('Sound not cached, may experience stuttering! ${id}');
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
    var result:Null<String> = current_text.get(id);
    if (result != null)
    {
      return result;
    }
    else
    {
      #if FEATURE_STRICT_ASSET_CACHING
      throw 'Text not cached, cannot load synchronously: $id';
      #else
      FlxG.log.warn('Text not cached, may experience stuttering! ${id}');

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
    var result:Null<openfl.utils.ByteArray> = current_bytes.get(id);
    if (result != null)
    {
      return result;
    }
    else
    {
      #if FEATURE_STRICT_ASSET_CACHING
      throw 'Bytes not cached, cannot load synchronously: $id';
      #else
      FlxG.log.warn('Bytes not cached, may experience stuttering! ${id}');
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
    return current_flxGraphic.exists(path.toString());
  }

  /**
   * Check if a BitmapData exists in the cache.
   * @param id The asset id of the BitmapData.
   * @return `true` if the BitmapData exists in the cache, `false` otherwise.
   */
  public function hasBitmapData(id:String):Bool
  {
    return current_bitmapData.exists(id);
  }

  /**
   * Check if a Font exists in the cache.
   * @param id The asset id of the Font.
   * @return `true` if the Font exists in the cache, `false` otherwise.
   */
  public function hasFont(id:String):Bool
  {
    return current_font.exists(id);
  }

  /**
   * Check if a Sound exists in the cache.
   * @param id The asset id of the Sound.
   * @return `true` if the Sound exists in the cache, `false` otherwise.
   */
  public function hasSound(id:String):Bool
  {
    return current_sound.exists(id);
  }

  /**
   * Check if a Text exists in the cache.
   * @param id The asset id of the Text.
   * @return `true` if the Text exists in the cache, `false` otherwise.
   */
  public function hasText(id:String):Bool
  {
    return current_text.exists(id);
  }

  /**
   * Check if a file's Bytes exists in the cache.
   * @param id The asset id of the bytes.
   * @return `true` if the bytes exist in the cache, `false` otherwise.
   */
  public function hasBytes(id:String):Bool
  {
    return current_bytes.exists(id);
  }

  /**
   * Remove a specific FlxGraphic from the cache.
   * @param id The asset id of the FlxGraphic.
   * @return `true` if the FlxGraphic was removed from the cache, `false` otherwise.
   */
  public function removeFlxGraphic(id:String):Bool
  {
    var result:Bool = false;
    var graphic:Null<FlxGraphic> = previous_flxGraphic.get(id);
    if (graphic != null)
    {
      FlxG.bitmap.remove(graphic);
      graphic.destroy();
      result = previous_flxGraphic.remove(id) || result;
    }
    graphic = current_flxGraphic.get(id);
    if (graphic != null)
    {
      FlxG.bitmap.remove(graphic);
      graphic.destroy();
      result = current_flxGraphic.remove(id) || result;
    }
    return result;
  }

  /**
   * Remove a specific BitmapData from the cache.
   * @param id The asset id of the BitmapData.
   * @return `true` if the BitmapData was removed from the cache, `false` otherwise.
   */
  public function removeBitmapData(id:String):Bool
  {
    var result:Bool = false;
    var bitmap:Null<BitmapData> = previous_bitmapData.get(id);
    if (bitmap != null)
    {
      FlxDestroyUtil.dispose(bitmap);
      result = previous_bitmapData.remove(id) || result;
    }
    bitmap = current_bitmapData.get(id);
    if (bitmap != null)
    {
      FlxDestroyUtil.dispose(bitmap);
      result = current_bitmapData.remove(id) || result;
    }
    return result;
  }

  /**
   * Remove a specific Font from the cache.
   * @param id The asset id of the Font.
   * @return `true` if the Font was removed from the cache, `false` otherwise.
   */
  public function removeFont(id:String):Bool
  {
    return current_font.remove(id) || previous_font.remove(id);
  }

  /**
   * Remove a specific Sound from the cache.
   * @param id The asset id of the Sound.
   * @return `true` if the Sound was removed from the cache, `false` otherwise.
   */
  public function removeSound(id:String):Bool
  {
    return current_sound.remove(id) || previous_sound.remove(id);
  }

  /**
   * Remove a specific Text from the cache.
   * @param id The asset id of the Text.
   * @return `true` if the Text was removed from the cache, `false` otherwise.
   */
  public function removeText(id:String):Bool
  {
    return current_text.remove(id) || previous_text.remove(id);
  }

  /**
   * Remove a specific file's Bytes from the cache.
   * @param id The asset id of the bytes.
   * @return `true` if the bytes were removed from the cache, `false` otherwise.
   */
  public function removeBytes(id:String):Bool
  {
    return current_bytes.remove(id) || previous_bytes.remove(id);
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
    var bitmap:Null<BitmapData> = previous_bitmapData.get(id) ?? current_bitmapData.get(id);
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
    current_flxGraphic.set(id, flxGraphic);
    previous_flxGraphic.remove(id);
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
    current_bitmapData.set(id, bitmapData);
    previous_bitmapData.remove(id);
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
    current_font.set(id, font);
    previous_font.remove(id);
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
    current_sound.set(id, sound);
    previous_sound.remove(id);
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
    current_text.set(id, text);
    previous_text.remove(id);
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
    current_bytes.set(id, bytes);
    previous_bytes.remove(id);
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

    if (!force && type == null && assetListBaseCache != null)
    {
      return assetListBaseCache;
    }

    if (!force && type != null && assetListCaches.exists(type))
    {
      var result:Null<Array<AssetPath>> = assetListCaches.get(type);
      if (result != null) return result;
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

    var recachedBitmapData:Null<BitmapData> = recacheBitmapData(assetPath);
    if (recachedBitmapData != null)
    {
      // This line exists because null-safety creates a Future<Null<T>> instead of a Future<T>.
      var value:BitmapData = recachedBitmapData;
      return Future.withValue(value);
    }

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

  function recacheBitmapData(assetPath:AssetPath):Null<BitmapData>
  {
    if (!previous_bitmapData.exists(assetPath.toString())) return null;

    // Move the graphic from the previous cache to the current cache.
    var cacheValue:Null<BitmapData> = previous_bitmapData.get(assetPath.toString());
    if (cacheValue == null) throw 'Whuh?';
    var validCacheValue:BitmapData = cacheValue;
    setBitmapData(assetPath.toString(), validCacheValue);
    return validCacheValue;
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
    if (!previous_flxGraphic.exists(assetPath.toString())) return null;

    // NOTE: This moves the bitmap data from the previous cache to the current cache.
    var future:Future<FlxGraphic> = this.cacheBitmapData(assetPath, uploadToGPU).then((_bitmapData:BitmapData) ->
    {
      // Move the graphic from the previous cache to the current cache.
      var cacheValue:Null<FlxGraphic> = previous_flxGraphic.get(assetPath.toString());
      if (cacheValue == null) throw 'Whuh?';
      var validCacheValue:FlxGraphic = cacheValue;
      setFlxGraphic(assetPath.toString(), validCacheValue);
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

    var recachedSound:Null<Sound> = recacheSound(assetPath);
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

  function recacheSound(assetPath:AssetPath):Null<Sound>
  {
    if (!previous_text.exists(assetPath.toString())) return null;

    // Move the sound from the previous cache to the current cache.
    var cacheValue:Null<Sound> = previous_sound.get(assetPath.toString());
    if (cacheValue == null) throw 'Whuh?';
    var validCacheValue:Sound = cacheValue;
    setSound(assetPath.toString(), validCacheValue);
    return validCacheValue;
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

    var recachedText:Null<String> = recacheText(assetPath);
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

  function recacheText(assetPath:AssetPath):Null<String>
  {
    if (!previous_text.exists(assetPath.toString())) return null;

    // Move the text from the previous cache to the current cache.
    var cacheValue:Null<String> = previous_text.get(assetPath.toString());
    if (cacheValue == null) throw 'Whuh?';
    var validCacheValue:String = cacheValue;
    setText(assetPath.toString(), validCacheValue);
    return validCacheValue;
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

    var recachedBytes:Null<ByteArray> = recacheBytes(assetPath);
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

  function recacheBytes(assetPath:AssetPath):Null<ByteArray>
  {
    if (!previous_bytes.exists(assetPath.toString())) return null;

    // Move the bytes from the previous cache to the current cache.
    var cacheValue:Null<openfl.utils.ByteArray> = previous_bytes.get(assetPath.toString());
    if (cacheValue == null) throw 'Whuh?';
    var validCacheValue:ByteArray = cacheValue;
    setBytes(assetPath.toString(), validCacheValue);
    return validCacheValue;
  }

  /**
   * A debugging function which prints the contents of the asset cache.
   */
  public function debug_listCachedAssets():Void
  {
    trace('[ASSETS] Cached assets:');
    trace('[ASSETS] BITMAP DATA:');
    var keys:Array<String> = current_bitmapData.keys().array();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace('[ASSETS] - $key');
    }

    trace('[ASSETS] FLX GRAPHIC:');
    var keys:Array<String> = current_flxGraphic.keys().array();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace('[ASSETS] - $key');
    }

    trace('[ASSETS] FONT:');
    var keys:Array<String> = current_font.keys().array();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace('[ASSETS] - $key');
    }

    trace('[ASSETS] SOUND:');
    var keys:Array<String> = current_sound.keys().array();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace('[ASSETS] - $key');
    }

    trace('[ASSETS] TEXT:');
    var keys:Array<String> = current_text.keys().array();
    keys.sort(SortUtil.alphabetically);
    for (key in keys)
    {
      trace('[ASSETS] - $key');
    }

    trace('[ASSETS] BYTES:');
    var keys:Array<String> = current_bytes.keys().array();
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

/**
 * An override for the HaxeFlixel BitmapFrontend class to provide additional logging.
 */
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

  public function new()
  {
    super();
  }

  /**
   * Add an asset to the cache.
   * @param graphic The asset to add.
   * @param unique Whether or not the asset is unique.
   * @param key The key of the asset.
   * @return The FlxGraphic, if added.
   */
  override public function add(graphic:flixel.system.FlxAssets.FlxGraphicAsset, unique:Bool = false, ?key:String):FlxGraphic
  {
    if ((graphic is FlxGraphic))
    {
      return FlxGraphic.fromGraphic(cast graphic, unique, key);
    }
    else if ((graphic is BitmapData))
    {
      return FlxGraphic.fromBitmapData(cast graphic, unique, key);
    }

    // String case
    // Try to retreive a cached FlxGraphic for the asset path if one already exists.
    return FunkinAssetCache.instance.getFlxGraphic(graphic);
  }
}
