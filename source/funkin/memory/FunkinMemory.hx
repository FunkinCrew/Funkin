package funkin.memory;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import funkin.play.notes.notestyle.NoteStyle;
import openfl.utils.AssetType;
import openfl.Assets;
import openfl.media.Sound;
import funkin.util.flixel.sound.FlxPartialSound;

/**
 * Handles caching of textures and sounds for the game.
 * I did this hello, this can be improved later on and I have ideas on how, but for now this functions well enough. -Zack
 */
@:nullSafety @:allow(funkin.memory.BitmapCache, funkin.memory.SoundCache)
class FunkinMemory
{
  /**
   * Caches textures that are always required.
   */
  public static function initialCache():Void
  {
    var allImages:Array<String> = Assets.list();

    // Looks for the UI
    for (file in allImages)
    {
      if (!(file.endsWith('.png') #if FEATURE_COMPRESSED_TEXTURES || file.endsWith('.astc') #end)
        || file.contains('chart-editor')
        || !file.contains('ui/')
        || file.contains('flixel'))
      {
        continue;
      }

      file = file.replace(' ', ''); // Handle stray spaces.

      permanentCacheTexture(file);
    }

    permanentCacheTexture(Paths.image('gameplay/general/health-bar'));
    permanentCacheTexture(Paths.image('ui/main-menu/menu-desat'));
    permanentCacheTexture(Paths.image('gameplay/notestyles/funkin/notes'));
    permanentCacheTexture(Paths.image('gameplay/notestyles/funkin/note-splashes'));
    permanentCacheTexture(Paths.image('gameplay/notestyles/funkin/note-strumline'));
    permanentCacheTexture(Paths.image('gameplay/notestyles/funkin/note-holds'));
    permanentCacheTexture(Paths.image('ui/fonts/bold'));
    permanentCacheTexture(Paths.image('ui/fonts/default'));
    permanentCacheTexture(Paths.image('ui/fonts/freeplay-clear'));
    BitmapCache.initCache();

    // Looks for countdown sounds
    var allSounds:Array<String> = Assets.list(AssetType.SOUND);

    for (file in allSounds)
    {
      if (!file.endsWith('.ogg') || !file.contains('countdown/') || file.contains('flixel')) continue;

      file = file.replace(' ', '');

      permanentCacheSound(file);
    }

    permanentCacheSound(Paths.sound('ui/main-menu/cancel-menu'));
    permanentCacheSound(Paths.sound('ui/main-menu/confirm-menu'));
    permanentCacheSound(Paths.sound('ui/main-menu/screenshot'));
    permanentCacheSound(Paths.sound('ui/main-menu/scroll-menu'));
    permanentCacheSound(Paths.sound('ui/soundtray/volume-down'));
    permanentCacheSound(Paths.sound('ui/soundtray/volume-max'));
    permanentCacheSound(Paths.sound('ui/soundtray/volume-up'));
    permanentCacheSound(Paths.music('ui/main-menu/freaky-menu/freaky-menu'));
    permanentCacheSound(Paths.music('ui/input-offsets/offsets-loop/offsets-loop'));
    permanentCacheSound(Paths.music('ui/input-offsets/drums-loop/drums-loop'));
    permanentCacheSound(Paths.sound('gameplay/general/sounds/miss-note-1'));
    permanentCacheSound(Paths.sound('gameplay/general/sounds/miss-note-2'));
    permanentCacheSound(Paths.sound('gameplay/general/sounds/miss-note-3'));
    SoundCache.initCache();
  }

  /**
   * Clears the current texture and sound caches.
   * @param callGarbageCollector Whether to call the system's garbage collector after purging.
   */
  public static inline function purgeCache(callGarbageCollector:Bool = false):Void
  {
    trace(' CLEARING CACHE '.bg_bright_lilac().bold() +  ' Disposing all cached textures, assets and sounds...');

    preparePurgeTextureCache();
    preparePurgeSoundCache();
    cleanCurrentLevel();
    purgeTextureCache();
    purgeSoundCache();
    #if (cpp || neko || hl)
    if (callGarbageCollector) funkin.util.MemoryUtil.collect(true);
    #end
  }

  ///// TEXTURES /////

  /**
   * Ensures a texture with the given key is cached.
   * @param key The key of the texture to cache.
   */
  public static function cacheTexture(key:String):Void
  {
    BitmapCache.cache(key);
  }

  /**
   * Permanently caches a texture with the given key.
   * @param key The key of the texture to cache.
   */
  static function permanentCacheTexture(key:String):Void
  {
    BitmapCache.permanentCache(key);
  }

  /**
   * Forces the GPU to load and upload a FlxGraphic.
   */
  private static function forceRender(graphic:FlxGraphic):Void
  {
    BitmapCache.forceRender(graphic);
  }

  /**
   * Checks, if graphic with given path cached in memory.
   */
  public static function getCachedGraphic(path:String):Null<FlxGraphic>
  {
    return BitmapCache.getCachedGraphic(path);
  }

  /**
   * Prepares the cache for purging unused textures.
   */
  public static inline function preparePurgeTextureCache():Void
  {
    BitmapCache.preparePurge();
  }

  /**
   * Purges unused textures from the cache.
   */
  public static function purgeTextureCache():Void
  {
    BitmapCache.purge();
  }

  /**
   * Determine whether the texture with the given key is cached.
   * @param key The key of the texture to check.
   * @return Whether the texture is cached.
   */
  public static function isTextureCached(key:String):Bool
  {
    return BitmapCache.isCached(key);
  }

  ///// NOTE STYLE //////

  /**
   *  Caches all assets for the given note style.
   * @param style The note style to cache.
   */
  public static function cacheNoteStyle(style:NoteStyle):Void
  {
    // TODO: Texture paths should fall back to the default values.
    cacheTexture(Paths.image(style.getNoteAssetPath() ?? 'gameplay/notestyles/funkin/notes'));
    cacheTexture(style.getHoldNoteAssetPath() ?? 'gameplay/notestyles/funkin/note-holds');
    cacheTexture(Paths.image(style.getStrumlineAssetPath() ?? 'gameplay/notestyles/funkin/note-strumline'));
    cacheTexture(Paths.image(style.getSplashAssetPath() ?? 'gameplay/notestyles/funkin/note-splashes'));

    cacheTexture(Paths.image(style.getHoldCoverDirectionAssetPath(LEFT) ?? 'gameplay/notestyles/funkin/hold-cover-left'));
    cacheTexture(Paths.image(style.getHoldCoverDirectionAssetPath(RIGHT) ?? 'gameplay/notestyles/funkin/hold-cover-right'));
    cacheTexture(Paths.image(style.getHoldCoverDirectionAssetPath(UP) ?? 'gameplay/notestyles/funkin/hold-cover-up'));
    cacheTexture(Paths.image(style.getHoldCoverDirectionAssetPath(DOWN) ?? 'gameplay/notestyles/funkin/hold-cover-down'));

    // cacheTexture(Paths.image(style.buildCountdownSpritePath(THREE) ?? "THREE"));
    cacheTexture(Paths.image(style.buildCountdownSpritePath(TWO) ?? 'gameplay/notestyles/funkin/countdown/graphics/ready'));
    cacheTexture(Paths.image(style.buildCountdownSpritePath(ONE) ?? 'gameplay/notestyles/funkin/countdown/graphics/set'));
    cacheTexture(Paths.image(style.buildCountdownSpritePath(GO) ?? 'gameplay/notestyles/funkin/countdown/graphics/go'));

    cacheSound(style.getCountdownSoundPath(THREE) ?? 'gameplay/notestyles/funkin/countdown/sound/intro-three');
    cacheSound(style.getCountdownSoundPath(TWO) ?? 'gameplay/notestyles/funkin/countdown/sound/intro-two');
    cacheSound(style.getCountdownSoundPath(ONE) ?? 'gameplay/notestyles/funkin/countdown/sound/intro-one');
    cacheSound(style.getCountdownSoundPath(GO) ?? 'gameplay/notestyles/funkin/countdown/sound/intro-go');

    cacheTexture(Paths.image(style.buildJudgementSpritePath('sick') ?? 'gameplay/notestyles/funkin/popup/sick'));
    cacheTexture(Paths.image(style.buildJudgementSpritePath('good') ?? 'gameplay/notestyles/funkin/popup/good'));
    cacheTexture(Paths.image(style.buildJudgementSpritePath('bad') ?? 'gameplay/notestyles/funkin/popup/bad'));
    cacheTexture(Paths.image(style.buildJudgementSpritePath('shit') ?? 'gameplay/notestyles/funkin/popup/shit'));

    cacheTexture(Paths.image(style.buildComboNumSpritePath(0) ?? 'gameplay/notestyles/funkin/popup/digit-0'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(1) ?? 'gameplay/notestyles/funkin/popup/digit-1'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(2) ?? 'gameplay/notestyles/funkin/popup/digit-2'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(3) ?? 'gameplay/notestyles/funkin/popup/digit-3'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(4) ?? 'gameplay/notestyles/funkin/popup/digit-4'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(5) ?? 'gameplay/notestyles/funkin/popup/digit-5'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(6) ?? 'gameplay/notestyles/funkin/popup/digit-6'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(7) ?? 'gameplay/notestyles/funkin/popup/digit-7'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(8) ?? 'gameplay/notestyles/funkin/popup/digit-8'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(9) ?? 'gameplay/notestyles/funkin/popup/digit-9'));

    @:privateAccess
    {
      style.buildHoldCoverFrames();
      style.buildSplashFrames();
    }
  }

  ///// SOUND //////

  /**
   * Caches a sound with the given key.
   * @param key The key of the sound to cache.
   */
  public static function cacheSound(key:String):Void
  {
    SoundCache.cache(key);
  }

  /**
   * Permanently caches a sound with the given key.
   * @param key The key of the sound to cache.
   */
  public static function permanentCacheSound(key:String):Void
  {
    SoundCache.permanentCache(key);
  }

  /**
   * Prepares the cache for purging unused sounds.
   */
  public static function preparePurgeSoundCache():Void
  {
    SoundCache.preparePurge();
  }

  /**
   * Purges unused sounds from the cache.
   */
  public static inline function purgeSoundCache():Void
  {
    SoundCache.purge();
  }

  ///// MISC /////
  // call after prep purge and before purge

  public static function cleanCurrentLevel():Void
  {
    log('Cleaning assets for level ${Paths.currentLevel}');
    if (Paths.currentLevel == null || Paths.currentLevel == "") return;
    for (key in BitmapCache.cacheTriplet.previous.keys())
    {
      if (!key.startsWith(Paths.currentLevel)) continue;
      var obj:Null<FlxGraphic> = BitmapCache.cacheTriplet.previous.get(key);
      if (obj != null)
      {
        obj.destroy();
      }
      BitmapCache.cacheTriplet.previous.remove(key);
      Assets.cache.removeBitmapData(key);
    }

    @:privateAccess
    for (key in FlxG.bitmap._cache.keys())
    {
      if (!FlxG.bitmap._cache.exists(key)) continue;

      if (!key.startsWith(Paths.currentLevel)) continue;
      var obj:Null<FlxGraphic> = FlxG.bitmap.get(key);
      if (obj != null)
      {
        obj.destroy();
      }
      FlxG.bitmap.removeKey(key);
      BitmapCache.cacheTriplet.previous.remove(key);
      Assets.cache.removeBitmapData(key);
    }

    for (key in SoundCache.cacheTriplet.previous.keys())
    {
      if (!key.startsWith(Paths.currentLevel)) continue;
      SoundCache.cacheTriplet.previous.remove(key);
      Assets.cache.removeSound(key);
      log('Cleaning SOUND asset $key');
    }

    Assets.cache.clear(Paths.currentLevel);
  }

  /**
   * Clears all Freeplay assets from memory.
   */
  public static inline function clearFreeplay():Void
  {
    var keysToRemove:Array<String> = [];

    @:privateAccess
    for (key in FlxG.bitmap._cache.keys())
    {
      if (!key.contains('freeplay')) continue;
      if (BitmapCache.cacheTriplet.current.exists(key) || key.contains('fonts')) continue;

      keysToRemove.push(key);
    }

    @:privateAccess
    for (key in keysToRemove)
    {
      log('Cleaning asset $key');
      var obj:Null<FlxGraphic> = FlxG.bitmap.get(key);
      if (obj != null)
      {
        obj.destroy();
      }
      FlxG.bitmap.removeKey(key);
      if (BitmapCache.cacheTriplet.current.exists(key)) BitmapCache.cacheTriplet.current.remove(key);
      Assets.cache.removeBitmapData(key);
    }

    preparePurgeSoundCache();
    purgeSoundCache();
  }

  /**
   * Clears all sticker assets from memory.
   */
  public static inline function clearStickers():Void
  {
    var keysToRemove:Array<String> = [];

    @:privateAccess
    for (key in FlxG.bitmap._cache.keys())
    {
      if (!key.contains('stickers')) continue;
      if (BitmapCache.cacheTriplet.permanent.exists(key) || key.contains('fonts')) continue;

      keysToRemove.push(key);
    }

    @:privateAccess
    for (key in keysToRemove)
    {
      log('Cleaning asset $key');
      var obj:Null<FlxGraphic> = FlxG.bitmap.get(key);
      if (obj != null)
      {
        obj.destroy();
      }
      FlxG.bitmap.removeKey(key);
      if (BitmapCache.cacheTriplet.current.exists(key)) BitmapCache.cacheTriplet.current.remove(key);
      Assets.cache.removeBitmapData(key);
    }
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

// Just a struct for holding the 3 map caches.

typedef CacheTriplet<T> =
{
  permanent:Map<String, T>,
  current:Map<String, T>,
  previous:Map<String, T>
}
