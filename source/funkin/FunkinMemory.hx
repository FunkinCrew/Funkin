package funkin;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import funkin.play.notes.notestyle.NoteStyle;
import openfl.utils.AssetType;
import openfl.Assets;
import openfl.system.System;
import openfl.media.Sound;
import lime.app.Future;
import lime.app.Promise;

/**
 * Handles caching of textures and sounds for the game.
 * I did this hello, this can be improved later on and I have ideas on how, but for now this functions well enough. -Zack
 */
@:nullSafety
class FunkinMemory
{
  static var permanentCachedTextures:Map<String, FlxGraphic> = [];
  static var currentCachedTextures:Map<String, FlxGraphic> = [];
  static var previousCachedTextures:Map<String, FlxGraphic> = [];
  static var permanentCachedSounds:Map<String, Sound> = [];
  static var currentCachedSounds:Map<String, Sound> = [];
  static var previousCachedSounds:Map<String, Sound> = [];
  static var purgeFilter:Array<String> = ['/week', '/characters', '/charSelect', '/results'];

  /**
   * Caches textures that are always required.
   */
  public static function initialCache():Void
  {
    var allImages:Array<String> = Assets.list();

    for (file in allImages)
    {
      if (!(file.endsWith('.png') #if FEATURE_COMPRESSED_TEXTURES || file.endsWith('.astc') #end)
        || file.contains('chart-editor')
        || !file.contains('ui/'))
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
    // dude
    permanentCacheTexture(Paths.image('ui/fonts/bold'));
    permanentCacheTexture(Paths.image('ui/fonts/default'));
    permanentCacheTexture(Paths.image('ui/fonts/freeplay-clear'));

    var allSounds:Array<String> = Assets.list(AssetType.SOUND);

    for (file in allSounds)
    {
      if (!file.endsWith('.ogg') || !file.contains('countdown/')) continue;

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
  }

  /**
   * Clears the current texture and sound caches.
   * @param callGarbageCollector Whether to call the system's garbage collector after purging.
   */
  public static inline function purgeCache(callGarbageCollector:Bool = false):Void
  {
    preparePurgeTextureCache();
    purgeTextureCache();
    preparePurgeSoundCache();
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
    if (currentCachedTextures.exists(key)) return;

    if (previousCachedTextures.exists(key))
    {
      // Move the texture from the previous cache to the current cache.
      var graphic:Null<FlxGraphic> = previousCachedTextures.get(key);
      previousCachedTextures.remove(key);
      if (graphic != null) currentCachedTextures.set(key, graphic);
      return;
    }

    var graphic:Null<FlxGraphic> = FlxGraphic.fromAssetKey(key, false, null, true);
    if (graphic == null)
    {
      FlxG.log.warn('Failed to cache graphic: $key');
      return;
    }

    log('Cached asset $key');
    graphic.persist = true;
    currentCachedTextures.set(key, graphic);
    forceRender(graphic);
  }

  /**
   * Permanently caches a texture with the given key.
   * @param key The key of the texture to cache.
   */
  static function permanentCacheTexture(key:String):Void
  {
    if (permanentCachedTextures.exists(key)) return;

    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('FunkinMemory.permanentCacheTexture($key)');
    #end

    var graphic:Null<FlxGraphic> = FlxGraphic.fromAssetKey(key, false, null, true);
    if (graphic == null)
    {
      FlxG.log.warn('Failed to cache graphic: $key');
      return;
    }

    log('Cached graphic $key');
    graphic.persist = true;
    permanentCachedTextures.set(key, graphic);
    forceRender(graphic);
    currentCachedTextures = permanentCachedTextures.copy();
  }

  public static function getCachedGraphic(path:String):Null<FlxGraphic>
  {
    if (permanentCachedTextures.exists(path)) return permanentCachedTextures.get(path);
    if (currentCachedTextures.exists(path)) return currentCachedTextures.get(path);
    if (previousCachedTextures.exists(path)) return previousCachedTextures.get(path); // just in case

    return null;
  }

  /**
   * Prepares the cache for purging unused textures.
   */
  public static inline function preparePurgeTextureCache():Void
  {
    previousCachedTextures = currentCachedTextures.copy();

    for (graphicKey in previousCachedTextures.keys())
    {
      if (permanentCachedTextures.exists(graphicKey))
      {
        previousCachedTextures.remove(graphicKey);
      }
    }

    currentCachedTextures = permanentCachedTextures.copy();
  }

  /**
   * Purges unused textures from the cache.
   */
  public static function purgeTextureCache():Void
  {
    for (graphicKey in previousCachedTextures.keys())
    {
      if (permanentCachedTextures.exists(graphicKey))
      {
        previousCachedTextures.remove(graphicKey);
        continue;
      }

      if (graphicKey.contains('fonts')) continue;

      var graphic:Null<FlxGraphic> = previousCachedTextures.get(graphicKey);
      if (graphic != null)
      {
        FlxG.bitmap.remove(graphic);
        graphic.persist = false;
        graphic.destroy();
        previousCachedTextures.remove(graphicKey);
        Assets.cache.clear(graphicKey);
      }
    }
    @:privateAccess
    if (FlxG.bitmap._cache == null)
    {
      @:privateAccess
      FlxG.bitmap._cache = new Map();
    }

    @:privateAccess
    for (key in FlxG.bitmap._cache.keys())
    {
      var obj:Null<FlxGraphic> = FlxG.bitmap.get(key);

      if (obj == null || (obj.persist && permanentCachedTextures.exists(key)) || key.contains('fonts'))
      {
        continue;
      }

      if (obj.useCount > 0)
      {
        for (purgeEntry in purgeFilter)
        {
          if (key.contains(purgeEntry))
          {
            FlxG.bitmap.removeKey(key);
            obj.persist = false;
            obj.destroy();
          }
        }
      }
    }
  }

  /**
   * Forces the GPU to load and upload a FlxGraphic.
   * @param graphic The graphic to force render.
   */
  static function forceRender(graphic:FlxGraphic):Void
  {
    if (graphic == null) return;

    var bmp:Null<FlxGraphic> = FlxG.bitmap.get(graphic.key);
    if (bmp != null && bmp.bitmap != null) var _:Int = bmp.bitmap.width; // Trigger

    // Draws sprite and actually caches it.
    var sprite = new flixel.FlxSprite();
    sprite.loadGraphic(graphic);
    sprite.draw(); // Draw sprite and load it into game's memory.
    graphic.bitmap?.getTexture(FlxG.stage.context3D); // Just in case that didn't work...
    sprite.destroy();
  }

  /**
   * Determine whether the texture with the given key is cached.
   * @param key The key of the texture to check.
   * @return Whether the texture is cached.
   */
  public static function isTextureCached(key:String):Bool
  {
    return FlxG.bitmap.get(key) != null
      && (permanentCachedTextures.exists(key) || currentCachedTextures.exists(key) || previousCachedTextures.exists(key));
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
    if (currentCachedSounds.exists(key)) return;

    if (previousCachedSounds.exists(key))
    {
      // Move the texture from the previous cache to the current cache.
      var sound:Null<Sound> = previousCachedSounds.get(key);
      previousCachedSounds.remove(key);
      if (sound != null) currentCachedSounds.set(key, sound);
      return;
    }

    if (!Assets.exists(key))
    {
      trace('WARNING: Tried to cache a sound that does not exist: $key');
      return;
    }
    var sound:Null<Sound> = Assets.getSound(key, true);
    if (sound == null)
    {
      return;
    }
    else
    {
      currentCachedSounds.set(key, sound);
    }
  }

  /**
   * Permanently caches a sound with the given key.
   * @param key The key of the sound to cache.
   */
  public static function permanentCacheSound(key:String):Void
  {
    if (permanentCachedSounds.exists(key)) return;

    if (!Assets.exists(key))
    {
      trace('WARNING: Tried to cache a sound that does not exist: $key');
    }

    var sound:Null<Sound> = Assets.getSound(key, true);
    if (sound == null)
    {
      return;
    }
    else
    {
      permanentCachedSounds.set(key, sound);
    }

    if (sound != null) currentCachedSounds.set(key, sound);
  }

  /**
   * Prepares the cache for purging unused sounds.
   */
  public static function preparePurgeSoundCache():Void
  {
    previousCachedSounds = currentCachedSounds.copy();

    for (key in previousCachedSounds.keys())
    {
      if (permanentCachedSounds.exists(key))
      {
        previousCachedSounds.remove(key);
      }
    }

    currentCachedSounds = permanentCachedSounds.copy();
  }

  /**
   * Purges unused sounds from the cache.
   */
  public static inline function purgeSoundCache():Void
  {
    for (key in previousCachedSounds.keys())
    {
      if (permanentCachedSounds.exists(key))
      {
        previousCachedSounds.remove(key);
        continue;
      }

      var sound:Null<Sound> = previousCachedSounds.get(key);
      if (sound != null)
      {
        Assets.cache.removeSound(key);
        previousCachedSounds.remove(key);
      }
    }
    Assets.cache.clear('songs');
    Assets.cache.clear('music');
    // Felt lazy.
    var key = Paths.music('ui/main-menu/freaky-menu/freaky-menu');
    var sound:Null<Sound> = Assets.getSound(key, true);
    if (sound != null)
    {
      permanentCachedSounds.set(key, sound);
      currentCachedSounds.set(key, sound);
    }
  }

  ///// MISC /////

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
      if (permanentCachedTextures.exists(key) || key.contains('fonts')) continue;

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
      if (currentCachedTextures.exists(key)) currentCachedTextures.remove(key);
      Assets.cache.clear(key);
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
      if (permanentCachedTextures.exists(key) || key.contains('fonts')) continue;

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
      if (currentCachedTextures.exists(key)) currentCachedTextures.remove(key);
      Assets.cache.clear(key);
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
