package funkin.memory;

import funkin.assets.Paths.AssetPath;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import funkin.play.notes.notestyle.NoteStyle;
// import openfl.utils.AssetType;
import funkin.assets.Assets.AssetType;
import funkin.assets.Paths.AssetPath;
import openfl.Assets as OpenFLAssets;
import openfl.media.Sound;
import funkin.assets.Assets;
import funkin.assets.FunkinAssetCache;
import lime.app.Future;

/**
 * Handles caching of textures and sounds for the game.
 * I did this hello, this can be improved later on and I have ideas on how, but for now this functions well enough. -Zack
 */
@:nullSafety
@:allow(funkin.memory.BitmapCache, funkin.memory.SoundCache)
class FunkinMemory
{
  /**
   * Purges all the game's asset caches.
   *
   * @param callGarbageCollector Whether to forcibly invoke the system's garbage collector after purging.
   */
  public static inline function purgeCache(callGarbageCollector:Bool = false):Void
  {
    FunkinAssetCache.instance.preparePurgeCache();
    // TODO: In loading screens, you should be caching BETWEEN these.
    FunkinAssetCache.instance.purgeCache();

    #if (cpp || neko || hl)
    if (callGarbageCollector) funkin.util.MemoryUtil.collect(true);
    #end
  }

  // =========
  // TEXTURES
  // =========

  /**
   * Ensures a texture with the given key is cached.
   * @param key The key of the texture to cache.
   */
  public static function cacheTexture(assetPath:AssetPath):Void
  {
    FunkinAssetCache.instance.cacheFlxGraphic(assetPath);
  }

  /**
   * Permanently caches a texture with the given key.
   * @param key The key of the texture to cache.
   */
  static function permanentCacheTexture(assetPath:AssetPath):Void
  {
    FunkinAssetCache.instance.cacheFlxGraphic(assetPath);
  }

  /**
   * Retrieve the FlxGraphic for the given asset path, asynchronously.
   *
   * @param assetPath The path of the asset to retrieve.
   * @return A future for the FlxGraphic for the asset.
   */
  public static function getCachedGraphic(assetPath:AssetPath):Future<FlxGraphic>
  {
    return funkin.assets.Assets.loadFlxGraphic(path);
  }

  /**
   * Prepares the cache for purging unused textures.
   */
  public static inline function preparePurgeTextureCache():Void
  {
    trace(' WARNING '.warning() + 'FunkinMemory.preparePurgeTextureCache() is deprecated and should not be used.');
  }

  /**
   * Purges unused textures from the cache.
   */
  public static function purgeTextureCache():Void
  {
    trace(' WARNING '.warning() + 'FunkinMemory.purgeTextureCache() is deprecated and should not be used.');
  }

  /**
   * Determine whether the texture with the given key is cached.
   * @param key The key of the texture to check.
   * @return Whether the texture is cached.
   */
  public static function isTextureCached(key:AssetPath):Bool
  {
    return FunkinAssetCache.instance.hasFlxGraphic(key);
  }

  // =========
  // NOTE STYLE
  // =========

  /**
   *  Caches all assets for the given note style.
   * @param style The note style to cache.
   */
  public static function cacheNoteStyle(style:NoteStyle):Void
  {
    trace(' WARNING '.warning() + 'FunkinMemory.cacheNoteStyle() is deprecated and should not be used.');
  }

  // =========
  // SOUND
  // =========

  /**
   * Caches a sound with the given key.
   * @param key The key of the sound to cache.
   */
  public static function cacheSound(key:AssetPath):Void
  {
    SoundCache.cache(key);
  }

  /**
   * Permanently caches a sound with the given key.
   * @param key The key of the sound to cache.
   */
  public static function permanentCacheSound(key:AssetPath):Void
  {
    SoundCache.permanentCache(key);
  }

  /**
   * Prepares the cache for purging unused sounds.
   * Make sure to call this before `purgeSoundCache()`.
   */
  public static function preparePurgeSoundCache():Void
  {
    SoundCache.preparePurge();
  }

  /**
   * Purges unused sounds from the cache.
   * Make sure to call `preparePurgeSoundCache()`, then cache any sounds you want to keep before purging.
   */
  public static inline function purgeSoundCache():Void
  {
    SoundCache.purge();
  }

  // =========
  // MISC
  // =========

  /**
   * Clears all Freeplay assets from memory.
   */
  public static inline function clearFreeplay():Void
  {
    funkin.assets.FunkinBitmapFrontend.instance.clearOnly(['freeplay/']);
  }

  /**
   * Clears all sticker assets from memory.
   */
  public static inline function clearStickers():Void
  {
    funkin.assets.FunkinBitmapFrontend.instance.clearOnly(['stickers/']);
  }

  /**
   * Sends a trace with fancy ANSI colors.
   * @param message The message to log.
   */
  static function log(message:String):Void
  {
    trace(' MEMORY '.bg_bright_lilac().bold() + ' ${message}');
  }
}

/**
 * A structure containing a three-stage asset cache.
 */
typedef CacheTriplet<T> =
{
  /**
   * The permanent cache, containing assets which always stay in memory and are never purged.
   */
  permanent:Map<AssetPath, T>,

  /**
   * The currently cached assets. Won't be purged until the next purge cycle.
   */
  current:Map<AssetPath, T>,

  /**
   * The assets that were previously cached. May be re-cached, but if not, they will be purged.
   */
  previous:Map<AssetPath, T>
}
