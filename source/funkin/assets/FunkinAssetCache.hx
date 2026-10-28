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
import lime.utils.Assets as LimeAssets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.Assets as OpenFLAssets;
import openfl.utils.ByteArray;
import openfl.utils.IAssetCache as OpenFLIAssetCache;
import flixel.system.FlxAssets.FlxGraphicAsset;
import lime.app.Promise;

using funkin.graphics.framebuffer.BitmapDataUtil;

/**
 * An override for the OpenFL AssetCache class to override the internal cache with our own.
 * This allows us to be more specific about when assets are cached, and when they are purged.
 *
 * USAGE GUIDE:
 * Call fetch functions when you want to get and/or load an Asset asynchronously.
 * Call cache functions when you want to load the Asset into memory asynchronously, without necessarily needing the asset.
 * Call get functions when you want to get the Asset synchronously, this will cause stutters during the game's process.
 */
@:nullSafety
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

  /**
   * Will be true if we prepare to purge, until we either finish purging or if the cycle gets "cancelled", i.e while a state transition.
   */
  public var isPurgeCycleActive(default, null):Bool = false;

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
      // asset = null;
    });

    stagedSound = new StagedCache<Sound>();
    stagedSound.onRemove.add((key:String, asset:Sound) ->
    {
      FunkinLimeAssetCache.instance.removeAudio(key);
      if (!isSoundBufferInUse(asset)) asset.close();
    });

    stagedText = new StagedCache<String>();
    stagedText.onRemove.add((_:String, asset:String) -> {
      // asset = null;
    });

    stagedBytes = new StagedCache<openfl.utils.ByteArray>();
    stagedBytes.onRemove.add((_:String, asset:openfl.utils.ByteArray) ->
    {
      // clear() explicitly frees up the memory used by the ByteArray.
      asset.clear();
      // asset = null;
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
  public function forceClearCache(?clearPermanent:Bool = true):Void
  {
    #if VERBOSE_ASSET_CACHE
    trace(' ASSETS '.bold().bg_lime() + ' Force clearing asset cache...');
    #end

    for (cache in stagedCaches)
    {
      cache.clearCache(clearPermanent);
    }

    FunkinBitmapFrontend.instance.forceClear();
    stagedBitmapData.clearCache(clearPermanent);

    assetListCaches = [];
    assetListBaseCache = null;
  }

  public function forceUnloadModAssets(modId:String, assetPaths:Array<String>):Void
  {
    forceUnloadAsset(modId);
    for (path in assetPaths) forceUnloadAsset(path);
  }

  function forceUnloadAsset(id:String):Void
  {
    FunkinBitmapFrontend.instance.stagedFlxGraphic.remove(id, true);
    stagedBitmapData.remove(id, true);
    stagedFont.remove(id, true);
    stagedSound.remove(id, true);
    stagedText.remove(id, true);
    stagedBytes.remove(id, true);

    FunkinLimeAssetCache.instance.removeImage(id);
    FunkinLimeAssetCache.instance.removeFont(id);
    FunkinLimeAssetCache.instance.removeAudio(id);
  }

  /**
   * Forces lime to forget all cached assets.
   */
  public function clearCoreAssetCache():Void
  {
    #if sys
    @:privateAccess
    for (library in lime.utils.Assets.libraries)
    {
      // Polymod wraps each library, so walk down to the original one.
      var current:Null<lime.utils.AssetLibrary> = library;
      var depth:Int = 0;
      while (current != null && depth < 8)
      {
        current.cachedText.clear();
        current.cachedBytes.clear();
        current.cachedImages.clear();
        current.cachedAudioBuffers.clear();

        var next:Dynamic = Reflect.field(current, 'fallback');
        current = Std.isOfType(next, lime.utils.AssetLibrary) ? cast next : null;
        depth++;
      }
    }
    #end
  }

  /**
   * Prepare to purge the asset cache.
   * Attempting to recache any assets that were previously cached will just move them to the new cache.
   * Later, any old assets that the game didn't try to use again will be destroyed, saving memory.
   */
  public function preparePurgeCache():Void
  {
    isPurgeCycleActive = true;

    for (cache in stagedCaches) cache.preparePurgeCache();
    FunkinBitmapFrontend.instance.stagedFlxGraphic.preparePurgeCache();
  }

  /**
   * End a purge cycle without purging, e.g. because the transition was cancelled and the old state stays alive.
   * Anything the old state still uses is picked up by the next purge, which keeps whatever a live object holds.
   */
  public function cancelPurgeCycle():Void
  {
    isPurgeCycleActive = false;
  }

  /**
   * Purge any assets that were previously cached, but weren't requested again since `preparePurgeCache()` was called.
   * @param garbageCollect Whether to forcibly invoke the system's garbage collector after purging assets.
   */
  public function purgeCache(garbageCollect:Bool = false):Void
  {
    // IMPORTANT: purgeCache() must only be called after the outgoing state has been destroyed. LoadingState defers this until postStateSwitch so that
    // FlxSprite/FlxFrame/animation objects from the old state cannot reference disposed FlxGraphics or BitmapData.

    isPurgeCycleActive = false;

    for (cache in stagedCaches) cache.purgeCache();

    #if FEATURE_HAXEUI
    purgeHaxeUIAssets();
    #end

    // Purge FlxGraphics the new state does not own.

    // NOTE: preparePurgeCache() moved every graphic to `previous`, and loading plus the new state's create() moved everything the
    // target wants back to `current`. So whatever is still in `previous` right now was NOT requested by the target state.
    // (remove(), group.clear(), ...) pins its graphic forever. Instead we ask "does a live object in the current state tree use it?".
    final stagedGraphics:StagedCache<FlxGraphic> = FunkinBitmapFrontend.instance.stagedFlxGraphic;
    final live = FunkinBitmapFrontend.instance.collectLiveGraphics();

    // Animate atlases use several graphics (spritemap1, spritemap2...) but the sprite may only expose some of them,
    // so treat every spritemap in the same folder as a live graphic as live too.
    final liveAtlasDirs:Map<String, Bool> = [];
    for (graphic in live.keys())
    {
      final atlasDir:Null<String> = getAtlasDir(graphic.key);
      if (atlasDir != null) liveAtlasDirs.set(atlasDir, true);
    }

    // Rescue graphics that a live object holds but nobody re-requested through the cache, by moving them back to `current`.
    final rescue:Array<String> = [];
    for (key => graphic in stagedGraphics.previous)
    {
      if (graphic == null) continue;
      final atlasDir:Null<String> = getAtlasDir(key);
      if (live.exists(graphic) || (atlasDir != null && liveAtlasDirs.exists(atlasDir))) rescue.push(key);
    }
    for (key in rescue)
    {
      stagedGraphics.get(key); // Reuses it
    }

    stagedGraphics.purgeCacheByPredicate((key, graphic) ->
    {
      // Prevent background graphics from getting purged (this screws up loading screens!)
      // Prevent stickers from getting purged while they are in use.
      if (key.startsWith('bg_graphic_') || key.contains('stickers')) return false;

      return true;
    });

    // Perform garbage collection here, after we deleted a bunch of stuff, to free the memory we're no longer using.
    #if (cpp || neko || js)
    if (garbageCollect) funkin.util.MemoryUtil.collect(true);
    #end
  }

  /**
   * Gets the folder of an atlas spritemap.
   * @param key The folder path to look for.
   * @return The folder of an Animate atlas spritemap.
   */
  static function getAtlasDir(key:String):Null<String>
  {
    final slash:Int = key.lastIndexOf('/');
    if (slash < 0) return null;
    return key.substr(slash + 1).startsWith('spritemap') ? key.substr(0, slash) : null;
  }

  /**
   * Close a Sound if it is not currently in use by any FlxSound.
   * @param asset The Sound to check and close if unused.
   */
  public function releaseSoundIfUnused(asset:Null<Sound>):Void
  {
    if (asset == null) return;
    if (isSoundBufferInUse(asset)) return;

    // NOTE: If this somehow crashing something after all the checks, maybe only close it if it exists in previous. - Moon
    for (key in stagedSound.keys())
    {
      if (stagedSound.get(key, false) == asset) return;
    }

    asset.close();
  }

  /**
   * Whether or not a Sound's buffer is currently in use by any FlxSound.
   * @param asset The Sound to check.
   */
  static function isSoundBufferInUse(asset:Sound):Bool
  {
    var buffer:Null<LimeAudioBuffer> = @:privateAccess asset.__buffer;
    if (buffer == null) return false;

    var sounds:Array<flixel.sound.FlxSound> = flixel.FlxG.sound.list.members.copy();
    for (sound in flixel.FlxG.sound.defaultSoundGroup.sounds) sounds.push(sound);
    sounds.push(flixel.FlxG.sound.music);

    for (sound in sounds)
    {
      if (sound == null) continue;
      var current:Null<Sound> = @:privateAccess sound._sound;
      if (current == null) continue;
      if (@:privateAccess current.__buffer == buffer) return true;
    }

    return false;
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
   * @return The FlxGraphic, if available in the cache, or `null` otherwise.
   */
  public function getFlxGraphic(id:String):FlxGraphic
  {
    return FunkinBitmapFrontend.instance.getSafe(id);
  }

  /**
   * Get a BitmapData, if it exists in the cache.
   * @param id The asset id of the BitmapData.
   * @return The BitmapData, if available in the cache, or `null` otherwise.
   */
  public function getBitmapData(id:String):Null<BitmapData>
  {
    return stagedBitmapData.get(id);
  }

  /**
   * Get a Font, if it exists in the cache.
   * @param id The asset id of the Font.
   * @return The Font, if available in the cache, or `null` otherwise.
   */
  public function getFont(id:String):Null<Font>
  {
    return stagedFont.get(id);
  }

  /**
   * Get a Sound, if it exists in the cache.
   * @param id The asset id of the Sound.
   * @return The Sound, if available in the cache, or `null` otherwise.
   */
  public function getSound(id:String):Null<Sound>
  {
    return stagedSound.get(id);
  }

  /**
   * Gets text from a file from the cache.
   *
   * @param id The asset id of the text.
   * @return The text, if available in the cache, or `null` otherwise.
   */
  public function getText(id:String):Null<String>
  {
    return stagedText.get(id);
  }

  /**
   * Gets bytes from a file from the cache.
   *
   * @param id The asset id of the bytes.
   * @return The bytes, if found in the cache, or `null` otherwise.
   */
  public function getBytes(id:String):Null<openfl.utils.ByteArray>
  {
    return stagedBytes.get(id);
  }

  /**
   * Check if a FlxGraphic exists in the cache.
   * @param assetPath The asset path of the FlxGraphic.
   * @return `true` if the FlxGraphic exists in the cache, `false` otherwise.
   */
  public function hasFlxGraphic(id:String):Bool
  {
    if (!FunkinBitmapFrontend.instance.exists(id))
    {
      return false;
    }

    if (!FunkinBitmapFrontend.instance.isValidByKey(id))
    {
      #if VERBOSE_ASSET_CACHE
      trace(' ASSETS ' + ' Removing invalid FlxGraphic "${id} from cache.');
      #end
      FunkinBitmapFrontend.instance.removeByKey(id);
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
    var bitmapData:Null<BitmapData> = stagedBitmapData.get(id);
    // NOTE: You can't use `if (stagedBitmapData.exists(id))` for null safety because null safety a lil dummmmmmmm
    if (bitmapData == null) return false;

    if (!validateBitmapData(bitmapData))
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
   * @return The BitmapData, if fetched.
   */
  public function fetchBitmapData(assetPath:AssetPath):Future<BitmapData>
  {
    #if VERBOSE_ASSET_CACHE
    trace(' ASSETS '.bold().bg_lime() + ' Fetching BitmapData: ${assetPath.toString()}');
    #end
    if (hasBitmapData(assetPath.toString()))
    {
      var bitmapData:Null<BitmapData> = getBitmapData(assetPath.toString());
      if (bitmapData == null) return cast Future.withError('BitmapData does not exist: ${assetPath.toString()}');
      return Future.withValue(cast bitmapData);
    }
    else
    {
      var future:Future<BitmapData> = OpenFLAssets
        .loadBitmapData(assetPath.toString(), false, !assetPath.needsPixelData, !assetPath.needsPixelData)
        .then((bitmapData:BitmapData) ->
        {
          bitmapData.toGPU(false);
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
   * @return The FlxGraphic, if fetched.
   */
  public function fetchFlxGraphic(assetPath:AssetPath):Future<FlxGraphic>
  {
    if (hasFlxGraphic(assetPath.toString()))
    {
      return Future.withValue(getFlxGraphic(assetPath.toString()));
    }
    else
    {
      var future:Future<FlxGraphic> = fetchBitmapData(assetPath).then((bitmapData:BitmapData) ->
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
      var sound = getSound(assetPath.toString());
      if (sound == null) return cast Future.withError('Sound does not exist: ${assetPath.toString()}');
      return Future.withValue(cast sound);
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
      var text:Null<String> = getText(assetPath.toString());
      if (text == null) return cast Future.withError('Text does not exist: ${assetPath.toString()}');
      return Future.withValue(cast text);
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
    if (hasFont(assetPath.toString()))
    {
      var font:Null<Font> = getFont(assetPath.toString());
      if (font == null) return cast Future.withError('Font does not exist: ${assetPath.toString()}');

      return Future.withValue(cast font);
    }
    else
    {
      return Font.loadFromFile(assetPath.toString()).then((font:Font) ->
      {
        if (font == null) return cast Future.withError('Font did not load: ${assetPath.toString()}');

        try
        {
          openfl.text.Font.registerFont(font);
        }
        catch (e:Dynamic)
        {
          #if VERBOSE_ASSET_CACHE
          trace(' ASSETS '.bold().bg_lime() + ' Could not register Font globally (${assetPath.toString()}): $e');
          #end
        }

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
      var bytes:Null<ByteArray> = getBytes(assetPath.toString());
      if (bytes == null) return cast Future.withError('Bytes do not exist: ${assetPath.toString()}');
      return Future.withValue(cast bytes);
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
   * @return A future that returns whether or not the BitmapData has been succesfully cached.
   */
  public function cacheBitmapData(assetPath:AssetPath, permanent:Bool = false):Future<Bool>
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.cacheBitmapData(${assetPath.toString()})');
    #end

    threadCheck('cacheBitmapData(${assetPath.toString()})');

    var promise = new Promise<Bool>();

    fetchBitmapData(assetPath).then((bitmapData:BitmapData) ->
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
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' Permanently Cached BitmapData: ${assetPath.toString()}');
        #end
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
   * @return A future that returns whether or not the BitmapData has been succesfully cached.
   */
  public function cacheFlxGraphic(assetPath:AssetPath, permanent:Bool = false):Future<Bool>
  {
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinAssetCache.cacheFlxGraphic(${assetPath.toString()})');
    #end

    threadCheck('cacheFlxGraphic(${assetPath.toString()})');

    var promise = new Promise<Bool>();

    fetchFlxGraphic(assetPath).then((flxGraphic:FlxGraphic) ->
    {
      if (permanent)
      {
        #if VERBOSE_ASSET_CACHE
        trace(' ASSETS '.bold().bg_lime() + ' Permanently Cached FlxGraphic: ${assetPath.toString()}');
        #end
        FunkinBitmapFrontend.instance.stagedFlxGraphic.cachePermanent(assetPath.toString(), flxGraphic);
        cacheBitmapData(assetPath, true); // We need the bitmapdata to persist too.
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
        trace(' ASSETS '.bold().bg_lime() + ' Permanently Cached Sound: ${assetPath.toString()}');
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
        trace(' ASSETS '.bold().bg_lime() + ' Permanently Cached Text: ${assetPath.toString()}');
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
      trace(' ASSETS '.bold().bg_lime() + ' Permanently Cached Font: ${assetPath.toString()}');
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
        trace(' ASSETS '.bold().bg_lime() + ' Permanently Cached Bytes: ${assetPath.toString()}');
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
   * @param flxGraphic The `FlxGraphic` to check.
   * @return Whether the `FlxGraphic` is invalid (the underlying image got uncached) and needs to be reloaded.
   */
  public function validateFlxGraphic(flxGraphic:FlxGraphic):Bool
  {
    return FunkinBitmapFrontend.instance.isValid(flxGraphic);
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
    trace(' ASSETS '.bold().bg_lime() + ' ==CACHED ASSETS==');
    var keys:Array<String> = stagedBitmapData.keys();
    keys.sort(SortUtil.alphabetically);
    trace(' ASSETS '.bold().bg_lime() + ' BITMAP DATA:');
    if (keys.length > 0)
    {
      for (key in keys)
      {
        var bitmapData = stagedBitmapData.get(key);
        if (bitmapData == null) continue;

        var output:String = ' - $key';
        if (stagedBitmapData.existsPermanent(key)) output += ' [P]';
        if (!bitmapData.readable) output += ' [GPU]';
        trace(' ASSETS '.bold().bg_lime() + output);
      }
    }
    else
    {
      trace(' ASSETS '.bold().bg_lime() + ' - [none]');
    }

    var keys:Array<String> = FunkinBitmapFrontend.instance.stagedFlxGraphic.keys();
    keys.sort(SortUtil.alphabetically);
    trace(' ASSETS '.bold().bg_lime() + ' FLXGRAPHIC:');
    if (keys.length > 0)
    {
      for (key in keys)
      {
        var flxGraphic = FunkinBitmapFrontend.instance.stagedFlxGraphic.get(key);
        if (flxGraphic == null) continue;

        var output:String = ' - $key';
        if (FunkinBitmapFrontend.instance.stagedFlxGraphic.existsPermanent(key)) output += ' [P]';
        if (!flxGraphic.bitmap.readable) output += ' [GPU]';
        trace(' ASSETS '.bold().bg_lime() + output);
      }
    }
    else
    {
      trace(' ASSETS '.bold().bg_lime() + ' - [none]');
    }

    var keys:Array<String> = stagedFont.keys();
    keys.sort(SortUtil.alphabetically);
    trace(' ASSETS '.bold().bg_lime() + ' FONT:');
    if (keys.length > 0)
    {
      for (key in keys)
      {
        var output:String = '- $key';
        if (stagedFont.existsPermanent(key)) output += ' [P]';
        trace(' ASSETS '.bold().bg_lime() + output);
      }
    }
    else
    {
      trace(' ASSETS '.bold().bg_lime() + ' - [none]');
    }

    var keys:Array<String> = stagedSound.keys();
    keys.sort(SortUtil.alphabetically);
    trace(' ASSETS '.bold().bg_lime() + ' SOUND:');
    if (keys.length > 0)
    {
      for (key in keys)
      {
        var output:String = '- $key';
        if (stagedSound.existsPermanent(key)) output += ' [P]';
        trace(' ASSETS '.bold().bg_lime() + output);
      }
    }
    else
    {
      trace(' ASSETS '.bold().bg_lime() + ' - [none]');
    }

    var keys:Array<String> = stagedText.keys();
    keys.sort(SortUtil.alphabetically);
    trace(' ASSETS '.bold().bg_lime() + ' TEXT:');
    if (keys.length > 0)
    {
      for (key in keys)
      {
        var output:String = '- $key';
        if (stagedText.existsPermanent(key)) output += ' [P]';
        trace(' ASSETS '.bold().bg_lime() + output);
      }
    }
    else
    {
      trace(' ASSETS '.bold().bg_lime() + ' - [none]');
    }

    var keys:Array<String> = stagedBytes.keys();
    keys.sort(SortUtil.alphabetically);
    trace(' ASSETS '.bold().bg_lime() + 'BYTES:');
    if (keys.length > 0)
    {
      for (key in keys)
      {
        var output:String = '- $key';
        if (stagedBytes.existsPermanent(key)) output += ' [P]';
        trace(' ASSETS '.bold().bg_lime() + output);
      }
    }
    else
    {
      trace(' ASSETS '.bold().bg_lime() + ' - [none]');
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
    for (key in cb_audio.keys())
    {
      if (prefix == null || StringTools.startsWith(key, prefix))
      {
        removeAudio(key);
      }
    }

    for (key in cb_font.keys())
    {
      if (prefix == null || StringTools.startsWith(key, prefix))
      {
        removeFont(key);
      }
    }

    for (key in cb_image.keys())
    {
      if (prefix == null || StringTools.startsWith(key, prefix))
      {
        removeImage(key);
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
    final audio = cb_audio.get(id);
    cb_audio.remove(id);

    LimeAssets.unload(id, LimeAssetType.SOUND);
    if (audio != null) audio.dispose();
  }

  /**
   * Remove a font from the cache by key.
   * @param id The key of the font to remove.
   */
  public function removeFont(id:String):Void
  {
    cb_font.remove(id);

    LimeAssets.unload(id, LimeAssetType.FONT);
  }

  /**
   * Remove an image from the cache by key.
   * @param id The key of the image to remove.
   */
  public function removeImage(id:String):Void
  {
    cb_image.remove(id);

    LimeAssets.unload(id, LimeAssetType.IMAGE);
  }

  public function toString():String
  {
    return 'FunkinLimeAssetCache(${audioSize()} audios, ${fontSize()} fonts, ${imageSize()} images)';
  }
}
