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
   * Initialize the caches.
   */
  public static function initialCache():Void
  {
    // BitmapCache.init();
  }

  /**
   * Purges all the game's asset caches.
   *
   * @param callGarbageCollector Whether to forcibly invoke the system's garbage collector after purging.
   */
  public static inline function purgeCache(callGarbageCollector:Bool = false):Void
  {
    FunkinAssetCache.instance.preparePurgeCache();
    FunkinAssetCache.instance.purgeCache();
    // preparePurgeTextureCache();
    preparePurgeSoundCache();
    // purgeTextureCache();
    purgeSoundCache();
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
  public static function cacheTexture(key:AssetPath):Void
  {
    // BitmapCache.cache(key);
    FunkinAssetCache.instance.cacheFlxGraphic(key);
  }

  /**
   * Permanently caches a texture with the given key.
   * @param key The key of the texture to cache.
   */
  static function permanentCacheTexture(key:AssetPath):Void
  {
    // BitmapCache.permanentCache(key);
    FunkinAssetCache.instance.cacheFlxGraphic(key);
  }

  /**
   * Forces the GPU to load and upload a FlxGraphic.
   */
  private static function warmGraphic(graphic:FlxGraphic):Void
  {
    // BitmapCache.warmGraphic(graphic);
  }

  /**
   * Checks, if graphic with given path cached in memory.
   */
  public static function getCachedGraphic(path:AssetPath):Future<FlxGraphic>
  {
    return FunkinAssetCache.instance.fetchFlxGraphic(path, true);
  }

  /**
   * Prepares the cache for purging unused textures.
   */
  public static inline function preparePurgeTextureCache():Void
  {
    // BitmapCache.preparePurge();
    trace('UNUSED');
  }

  /**
   * Purges unused textures from the cache.
   */
  public static function purgeTextureCache():Void
  {
    // BitmapCache.purge();
    trace('UNUSED');
  }

  /**
   * Determine whether the texture with the given key is cached.
   * @param key The key of the texture to check.
   * @return Whether the texture is cached.
   */
  public static function isTextureCached(key:AssetPath):Bool
  {
    // return BitmapCache.isCached(key);
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
    // TODO: Texture paths should fall back to the default values. AND MAKE THIS WORK ?
    // cacheTexture(Paths.image(style.getNoteAssetPath() ?? 'gameplay/notestyles/funkin/notes'));
    // cacheTexture(style.getHoldNoteAssetPath() ?? 'gameplay/notestyles/funkin/note-holds');
    // cacheTexture(Paths.image(style.getStrumlineAssetPath() ?? 'gameplay/notestyles/funkin/note-strumline'));
    // cacheTexture(Paths.image(style.getSplashAssetPath() ?? 'gameplay/notestyles/funkin/note-splashes'));

    // cacheTexture(Paths.image(style.getHoldCoverDirectionAssetPath(LEFT) ?? 'gameplay/notestyles/funkin/hold-cover-left'));
    // cacheTexture(Paths.image(style.getHoldCoverDirectionAssetPath(RIGHT) ?? 'gameplay/notestyles/funkin/hold-cover-right'));
    // cacheTexture(Paths.image(style.getHoldCoverDirectionAssetPath(UP) ?? 'gameplay/notestyles/funkin/hold-cover-up'));
    // cacheTexture(Paths.image(style.getHoldCoverDirectionAssetPath(DOWN) ?? 'gameplay/notestyles/funkin/hold-cover-down'));

    // cacheTexture(Paths.image(style.buildCountdownSpritePath(TWO) ?? 'gameplay/notestyles/funkin/countdown/graphics/ready'));
    // cacheTexture(Paths.image(style.buildCountdownSpritePath(ONE) ?? 'gameplay/notestyles/funkin/countdown/graphics/set'));
    // cacheTexture(Paths.image(style.buildCountdownSpritePath(GO) ?? 'gameplay/notestyles/funkin/countdown/graphics/go'));

    // cacheSound(style.getCountdownSoundPath(THREE) ?? 'gameplay/notestyles/funkin/countdown/sound/intro-three');
    // cacheSound(style.getCountdownSoundPath(TWO) ?? 'gameplay/notestyles/funkin/countdown/sound/intro-two');
    // cacheSound(style.getCountdownSoundPath(ONE) ?? 'gameplay/notestyles/funkin/countdown/sound/intro-one');
    // cacheSound(style.getCountdownSoundPath(GO) ?? 'gameplay/notestyles/funkin/countdown/sound/intro-go');

    // cacheTexture(Paths.image(style.buildJudgementSpritePath('sick') ?? 'gameplay/notestyles/funkin/popup/sick'));
    // cacheTexture(Paths.image(style.buildJudgementSpritePath('good') ?? 'gameplay/notestyles/funkin/popup/good'));
    // cacheTexture(Paths.image(style.buildJudgementSpritePath('bad') ?? 'gameplay/notestyles/funkin/popup/bad'));
    // cacheTexture(Paths.image(style.buildJudgementSpritePath('shit') ?? 'gameplay/notestyles/funkin/popup/shit'));

    // cacheTexture(Paths.image(style.buildComboNumSpritePath(0) ?? 'gameplay/notestyles/funkin/popup/digit-0'));
    // cacheTexture(Paths.image(style.buildComboNumSpritePath(1) ?? 'gameplay/notestyles/funkin/popup/digit-1'));
    // cacheTexture(Paths.image(style.buildComboNumSpritePath(2) ?? 'gameplay/notestyles/funkin/popup/digit-2'));
    // cacheTexture(Paths.image(style.buildComboNumSpritePath(3) ?? 'gameplay/notestyles/funkin/popup/digit-3'));
    // cacheTexture(Paths.image(style.buildComboNumSpritePath(4) ?? 'gameplay/notestyles/funkin/popup/digit-4'));
    // cacheTexture(Paths.image(style.buildComboNumSpritePath(5) ?? 'gameplay/notestyles/funkin/popup/digit-5'));
    // cacheTexture(Paths.image(style.buildComboNumSpritePath(6) ?? 'gameplay/notestyles/funkin/popup/digit-6'));
    // cacheTexture(Paths.image(style.buildComboNumSpritePath(7) ?? 'gameplay/notestyles/funkin/popup/digit-7'));
    // cacheTexture(Paths.image(style.buildComboNumSpritePath(8) ?? 'gameplay/notestyles/funkin/popup/digit-8'));
    // cacheTexture(Paths.image(style.buildComboNumSpritePath(9) ?? 'gameplay/notestyles/funkin/popup/digit-9'));

    // @:privateAccess
    // {
    //   style.buildHoldCoverFrames();
    //   style.buildSplashFrames();
    // }
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
