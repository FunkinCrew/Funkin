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
class FunkinMemory
{
  /**
   * Purges all the game's asset caches.
   *
   * @param callGarbageCollector Whether to forcibly invoke the system's garbage collector after purging.
   */
  public static inline function purgeCache(callGarbageCollector:Bool = false):Void
  {
    funkin.assets.FunkinAssetCache.instance.preparePurgeCache();
    funkin.assets.FunkinAssetCache.instance.purgeCache(callGarbageCollector);
    trace(' WARNING '.warning() + 'FunkinMemory.purgeCache() is deprecated and should not be used.');
  }

  // =========
  // TEXTURES
  // =========

  /**
   * Ensures a texture with the given key is cached.
   * @param assetPath The key of the texture to cache.
   */
  public static function cacheTexture(assetPath:String):Void
  {
    var parsedPath = parseAssetPath(assetPath);
    if (parsedPath == null)
    {
      throw 'Invalid asset path: $assetPath';
    }

    var trueAssetPath = funkin.assets.Paths.file(parsedPath[0], parsedPath[1]);
    funkin.assets.Assets.cacheFlxGraphic(trueAssetPath);
    log(' WARNING ' + 'FunkinMemory.cacheTexture($assetPath) is deprecated and should not be used.');
  }

  static function parseAssetPath(path:String):Null<Array<String>>
  {
    // trace('the path is $path');
    if (!StringTools.startsWith(path, "assets/"))
    {
      return null;
    }

    var lastDot:Int = path.lastIndexOf(".");

    if (lastDot <= 6 || lastDot == path.length - 1)
    {
      return null;
    }

    var assetPart:String = path.substring(7, lastDot);

    var extensionPart:String = path.substring(lastDot + 1);

    if (extensionPart.length == 0 || extensionPart.indexOf("/") != -1)
    {
      return null;
    }

    return [assetPart, extensionPart];
  }

  /**
   * Permanently caches a texture with the given key.
   * @param assetPath The key of the texture to cache.
   */
  static function permanentCacheTexture(assetPath:String):Void
  {
    var parsedPath = parseAssetPath(assetPath);
    if (parsedPath == null)
    {
      throw 'Invalid asset path: $assetPath';
    }

    var trueAssetPath = funkin.assets.Paths.file(parsedPath[0], parsedPath[1]);
    funkin.assets.Assets.cacheFlxGraphic(trueAssetPath);
    log(' WARNING ' + 'FunkinMemory.permanentCacheTexture($assetPath) is deprecated and should not be used.');
  }

  /**
   * Retrieve the FlxGraphic for the given asset path, asynchronously.
   *
   * @param assetPath The path of the asset to retrieve.
   * @return A future for the FlxGraphic for the asset.
   */
  public static function getCachedGraphic(assetPath:String):Future<FlxGraphic>
  {
    var parsedPath = parseAssetPath(assetPath);
    if (parsedPath == null)
    {
      throw 'Invalid asset path: $assetPath';
    }

    var trueAssetPath = funkin.assets.Paths.file(parsedPath[0], parsedPath[1]);
    return funkin.assets.Assets.loadFlxGraphic(trueAssetPath);
  }

  /**
   * Prepares the cache for purging unused textures.
   */
  public static inline function preparePurgeTextureCache():Void
  {
    log(' WARNING '.warning() + 'FunkinMemory.preparePurgeTextureCache() is deprecated and should not be used.');
  }

  /**
   * Purges unused textures from the cache.
   */
  public static function purgeTextureCache():Void
  {
    log(' WARNING '.warning() + 'FunkinMemory.purgeTextureCache() is deprecated and should not be used.');
  }

  /**
   * Determine whether the texture with the given key is cached.
   *
   * @param assetPath The asset path of the texture to check.
   * @return Whether the texture is cached.
   */
  public static function isTextureCached(assetPath:String):Bool
  {
    var parsedPath = parseAssetPath(assetPath);
    if (parsedPath == null)
    {
      throw 'Invalid asset path: $assetPath';
    }

    var trueAssetPath = funkin.assets.Paths.file(parsedPath[0], parsedPath[1]);
    return funkin.assets.Assets.isFlxGraphicCached(trueAssetPath);
  }

  // =========
  // NOTE STYLE
  // =========

  /**
   *  Caches all assets for the given note style.
   *
   * @param style The note style to cache.
   */
  public static function cacheNoteStyle(style:NoteStyle):Void
  {
    log(' WARNING '.warning() + 'FunkinMemory.cacheNoteStyle() is deprecated and should not be used.');
  }

  // =========
  // SOUND
  // =========

  /**
   * Caches a sound with the given asset path.
   *
   * @param assetPath The asset path of the sound to cache.
   */
  public static function cacheSound(assetPath:String):Void
  {
    var parsedPath = parseAssetPath(assetPath);
    if (parsedPath == null)
    {
      throw 'Invalid asset path: $assetPath';
    }

    var trueAssetPath = funkin.assets.Paths.file(parsedPath[0], parsedPath[1]);
    funkin.assets.Assets.cacheSound(trueAssetPath);
    log(' WARNING '.warning() + 'FunkinMemory.cacheSound($assetPath) is deprecated and should not be used.');
  }

  /**
   * Permanently caches a sound with the given asset path.
   *
   * @param assetPath The asset path of the sound to cache.
   */
  public static function permanentCacheSound(assetPath:String):Void
  {
    var parsedPath = parseAssetPath(assetPath);
    if (parsedPath == null)
    {
      throw 'Invalid asset path: $assetPath';
    }

    var trueAssetPath = funkin.assets.Paths.file(parsedPath[0], parsedPath[1]);
    funkin.assets.Assets.cacheSound(trueAssetPath);
    log(' WARNING '.warning() + 'FunkinMemory.permanentCacheSound($assetPath) is deprecated and should not be used.');
  }

  /**
   * Prepares the cache for purging unused sounds.
   * Make sure to call this before `purgeSoundCache()`.
   */
  public static function preparePurgeSoundCache():Void
  {
    log(' WARNING '.warning() + 'FunkinMemory.preparePurgeSoundCache() is deprecated and should not be used.');
  }

  /**
   * Purges unused sounds from the cache.
   * Make sure to call `preparePurgeSoundCache()`, then cache any sounds you want to keep before purging.
   */
  public static inline function purgeSoundCache():Void
  {
    log(' WARNING '.warning() + 'FunkinMemory.purgeSoundCache() is deprecated and should not be used.');
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
