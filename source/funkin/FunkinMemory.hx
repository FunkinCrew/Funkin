package funkin;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.save.Save;
import funkin.util.HardwareProfileUtil;
import funkin.util.HardwareProfileUtil.HardwareSnapshot;
import funkin.util.HardwareProfileUtil.RuntimeCacheProfile;
import openfl.utils.AssetType;
import openfl.Assets;
import openfl.system.System;
import openfl.media.Sound;
import lime.app.Future;
import lime.app.Promise;

/**
 * Handles caching of textures and sounds for the game.
 * TODO: Remove this once Eric finishes the memory system.
 */
@:nullSafety
class FunkinMemory
{
  static var permanentCachedTextures:Map<String, FlxGraphic> = [];
  static var currentCachedTextures:Map<String, FlxGraphic> = [];
  static var previousCachedTextures:Map<String, FlxGraphic> = [];

  // waow
  static var permanentCachedSounds:Map<String, Sound> = [];
  static var currentCachedSounds:Map<String, Sound> = [];
  static var previousCachedSounds:Map<String, Sound> = [];

  static var purgeFilter:Array<String> = ["/week", "/characters", "/charSelect", "/results"];
  public static var runtimeHardware(default, null):Null<HardwareSnapshot> = null;
  public static var runtimeCacheProfile(default, null):RuntimeCacheProfile = BALANCED;

  static var shouldWarmGpuTextures:Bool = true;
  static var aggressivePurge:Bool = false;
  static var uiTexturePrecacheLimit:Int = 240;
  static var countdownSoundPrecacheLimit:Int = 40;

  static inline function ensureRuntimeProfileConfigured():Void
  {
    if (runtimeHardware == null) configureRuntimeCacheProfile();
  }

  static function chooseConfiguredCacheProfile(snapshot:HardwareSnapshot):RuntimeCacheProfile
  {
    var mode:String = Save?.instance?.options?.memoryProfile ?? "Auto";
    return switch (mode)
    {
      case "GPU Heavy":
        GPU_HEAVY;
      case "Balanced":
        BALANCED;
      case "RAM Saver":
        RAM_SAVER;
      default:
        HardwareProfileUtil.chooseCacheProfile(snapshot);
    };
  }

  public static function configureRuntimeCacheProfile():Void
  {
    runtimeHardware = HardwareProfileUtil.snapshot();
    runtimeCacheProfile = chooseConfiguredCacheProfile(runtimeHardware);

    // Tune cache aggressiveness based on the selected runtime profile.
    switch (runtimeCacheProfile)
    {
      case GPU_HEAVY:
        shouldWarmGpuTextures = true;
        aggressivePurge = false;
        uiTexturePrecacheLimit = -1;
        countdownSoundPrecacheLimit = -1;
      case BALANCED:
        shouldWarmGpuTextures = true;
        aggressivePurge = false;
        uiTexturePrecacheLimit = 240;
        countdownSoundPrecacheLimit = 40;
      case RAM_SAVER:
        shouldWarmGpuTextures = false;
        aggressivePurge = true;
        uiTexturePrecacheLimit = 96;
        countdownSoundPrecacheLimit = 16;
    }

    log('Runtime cache profile: ${runtimeCacheProfile}');
    log('Renderer: ${runtimeHardware.rendererType} / ${runtimeHardware.driverInfo}');
  }

  static inline function getLibraryFromKey(key:String):Null<String>
  {
    var splitIndex:Int = key.indexOf(':');
    if (splitIndex <= 0) return null;
    return key.substring(0, splitIndex);
  }

  static inline function isLibraryLoadedForKey(key:String):Bool
  {
    var library:Null<String> = getLibraryFromKey(key);
    return library == null || Assets.getLibrary(library) != null;
  }

  /**
   * Caches textures that are always required.
   */
  public static inline function initialCache():Void
  {
    ensureRuntimeProfileConfigured();
    var hasSharedLibrary:Bool = Assets.getLibrary("shared") != null;
    var allImages:Array<String> = Assets.list();
    var cachedUiTextureCount:Int = 0;
    var cachedCountdownSoundCount:Int = 0;

    for (file in allImages)
    {
      if (!(file.endsWith(".png") #if FEATURE_COMPRESSED_TEXTURES || file.endsWith(".astc") #end)
        || file.contains("chart-editor")
        || !file.contains("ui/"))
      {
        continue;
      }

      file = file.replace(" ", ""); // Handle stray spaces.
      if (uiTexturePrecacheLimit >= 0 && cachedUiTextureCount >= uiTexturePrecacheLimit) break;

      if (file.contains("shared") || (hasSharedLibrary && Assets.exists('shared:$file', AssetType.IMAGE)))
      {
        file = 'shared:$file';
      }
      permanentCacheTexture(file);
      cachedUiTextureCount++;
    }

    permanentCacheTexture(Paths.image("healthBar"));
    permanentCacheTexture(Paths.image("menuDesat"));
    if (hasSharedLibrary)
    {
      permanentCacheTexture(Paths.image("notes", "shared"));
      permanentCacheTexture(Paths.image("noteSplashes", "shared"));
      permanentCacheTexture(Paths.image("noteStrumline", "shared"));
    }
    permanentCacheTexture(Paths.image("NOTE_hold_assets"));
    // dude
    permanentCacheTexture(Paths.image("fonts/bold", null));
    permanentCacheTexture(Paths.image("fonts/default", null));
    permanentCacheTexture(Paths.image("fonts/freeplay-clear", null));

    var allSounds:Array<String> = Assets.list(AssetType.SOUND);

    for (file in allSounds)
    {
      if (!file.endsWith(".ogg") || !file.contains("countdown/")) continue;

      file = file.replace(" ", "");
      if (countdownSoundPrecacheLimit >= 0 && cachedCountdownSoundCount >= countdownSoundPrecacheLimit) break;

      if (file.contains("shared") || (hasSharedLibrary && Assets.exists('shared:$file', AssetType.SOUND)))
      {
        file = 'shared:$file';
      }

      permanentCacheSound(file);
      cachedCountdownSoundCount++;
    }

    permanentCacheSound(Paths.sound("cancelMenu"));
    permanentCacheSound(Paths.sound("confirmMenu"));
    permanentCacheSound(Paths.sound("screenshot"));
    permanentCacheSound(Paths.sound("scrollMenu"));
    permanentCacheSound(Paths.sound("soundtray/Voldown"));
    permanentCacheSound(Paths.sound("soundtray/VolMAX"));
    permanentCacheSound(Paths.sound("soundtray/Volup"));
    permanentCacheSound(Paths.music("freakyMenu/freakyMenu"));
    permanentCacheSound(Paths.music("offsetsLoop/offsetsLoop"));
    permanentCacheSound(Paths.music("offsetsLoop/drumsLoop"));
    if (hasSharedLibrary)
    {
      permanentCacheSound(Paths.sound("missnote1", "shared"));
      permanentCacheSound(Paths.sound("missnote2", "shared"));
      permanentCacheSound(Paths.sound("missnote3", "shared"));
    }
  }

  /**
   * Clears the current texture and sound caches.
   */
  public static inline function purgeCache(callGarbageCollector:Bool = false):Void
  {
    preparePurgeTextureCache();
    purgeTextureCache();
    preparePurgeSoundCache();
    purgeSoundCache();
    #if (cpp || neko || hl)
    if (callGarbageCollector || aggressivePurge) funkin.util.MemoryUtil.collect(callGarbageCollector);
    #end
  }

  ///// TEXTURES /////

  /**
   * Determine whether the texture with the given key is cached.
   * @param key The key of the texture to check.
   * @return Whether the texture is cached.
   */
  public static function isTextureCached(key:String):Bool
  {
    return FlxG.bitmap.get(key) != null;
  }

  /**
   * Ensures a texture with the given key is cached.
   * @param key The key of the texture to cache.
   */
  public static function cacheTexture(key:String):Void
  {
    if (!isLibraryLoadedForKey(key)) return;
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
    if (shouldWarmGpuTextures) forceRender(graphic);
  }

  /**
   * Permanently caches a texture with the given key.
   * @param key The key of the texture to cache.
   */
  static function permanentCacheTexture(key:String):Void
  {
    if (!isLibraryLoadedForKey(key)) return;
    if (permanentCachedTextures.exists(key)) return;

    var graphic:Null<FlxGraphic> = FlxGraphic.fromAssetKey(key, false, null, true);
    if (graphic == null)
    {
      FlxG.log.warn('Failed to cache graphic: $key');
      return;
    }

    log('Cached graphic $key');
    graphic.persist = true;
    permanentCachedTextures.set(key, graphic);
    if (shouldWarmGpuTextures) forceRender(graphic);
    currentCachedTextures = permanentCachedTextures.copy();
  }

  /**
   * Forces the GPU to load and upload a FlxGraphic.
   */
  private static function forceRender(graphic:FlxGraphic):Void
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
   * Checks, if graphic with given path cached in memory.
   */
  public static inline function isGraphicCached(path:String):Bool
    return permanentCachedTextures.exists(path) || currentCachedTextures.exists(path) || previousCachedTextures.exists(path);

  public static function getCachedGraphic(path:String):Null<FlxGraphic>
  {
    if (permanentCachedTextures.exists(path)) return permanentCachedTextures.get(path);
    if (currentCachedTextures.exists(path)) return currentCachedTextures.get(path);
    if (previousCachedTextures.exists(path)) return previousCachedTextures.get(path); // just in case

    return null;
  }

  // Estimate VRAM used by loaded textures.
  public static function getEstimatedTextureVRAM():Float
  {
    var seenKeys:Map<String, Bool> = [];
    var totalBytes:Float = 0.0;

    var addGraphic = function(key:String, graphic:Null<FlxGraphic>):Void {
      if (seenKeys.exists(key)) return;
      seenKeys.set(key, true);
      totalBytes += estimateGraphicVRAMBytes(graphic);
    };

    for (key in permanentCachedTextures.keys())
    {
      addGraphic(key, permanentCachedTextures.get(key));
    }
    for (key in currentCachedTextures.keys())
    {
      addGraphic(key, currentCachedTextures.get(key));
    }
    for (key in previousCachedTextures.keys())
    {
      addGraphic(key, previousCachedTextures.get(key));
    }

    @:privateAccess
    if (FlxG.bitmap._cache != null)
    {
      @:privateAccess
      for (key in FlxG.bitmap._cache.keys())
      {
        addGraphic(key, FlxG.bitmap.get(key));
      }
    }

    return totalBytes;
  }

  static inline function estimateGraphicVRAMBytes(graphic:Null<FlxGraphic>):Float
  {
    var bitmap = graphic?.bitmap;
    if (bitmap == null) return 0.0;

    // Estimate bytes as RGBA plus mip overhead.
    return bitmap.width * bitmap.height * 4.0 * 1.3333334;
  }

  /**
   * Prepares the cache for purging unused textures.
   */
  public inline static function preparePurgeTextureCache():Void
  {
    if (aggressivePurge)
    {
      previousCachedTextures = [];
      currentCachedTextures = permanentCachedTextures.copy();
      return;
    }

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

      if (graphicKey.contains("fonts")) continue;

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

      if (obj == null || (obj.persist && permanentCachedTextures.exists(key)) || key.contains("fonts"))
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

  ///// NOTE STYLE //////

  public static function cacheNoteStyle(style:NoteStyle):Void
  {
    // TODO: Texture paths should fall back to the default values.
    cacheTexture(Paths.image(style.getNoteAssetPath() ?? "note"));
    cacheTexture(style.getHoldNoteAssetPath() ?? "noteHold");
    cacheTexture(Paths.image(style.getStrumlineAssetPath() ?? "strumline"));
    cacheTexture(Paths.image(style.getSplashAssetPath() ?? "noteSplash"));

    cacheTexture(Paths.image(style.getHoldCoverDirectionAssetPath(LEFT) ?? "LEFT"));
    cacheTexture(Paths.image(style.getHoldCoverDirectionAssetPath(RIGHT) ?? "RIGHT"));
    cacheTexture(Paths.image(style.getHoldCoverDirectionAssetPath(UP) ?? "UP"));
    cacheTexture(Paths.image(style.getHoldCoverDirectionAssetPath(DOWN) ?? "DOWN"));

    // cacheTexture(Paths.image(style.buildCountdownSpritePath(THREE) ?? "THREE"));
    cacheTexture(Paths.image(style.buildCountdownSpritePath(TWO) ?? "TWO"));
    cacheTexture(Paths.image(style.buildCountdownSpritePath(ONE) ?? "ONE"));
    cacheTexture(Paths.image(style.buildCountdownSpritePath(GO) ?? "GO"));

    cacheSound(style.getCountdownSoundPath(THREE) ?? "THREE");
    cacheSound(style.getCountdownSoundPath(TWO) ?? "TWO");
    cacheSound(style.getCountdownSoundPath(ONE) ?? "ONE");
    cacheSound(style.getCountdownSoundPath(GO) ?? "GO");

    cacheTexture(Paths.image(style.buildJudgementSpritePath("sick") ?? 'sick'));
    cacheTexture(Paths.image(style.buildJudgementSpritePath("good") ?? 'good'));
    cacheTexture(Paths.image(style.buildJudgementSpritePath("bad") ?? 'bad'));
    cacheTexture(Paths.image(style.buildJudgementSpritePath("shit") ?? 'shit'));

    cacheTexture(Paths.image(style.buildComboNumSpritePath(0) ?? '0'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(1) ?? '1'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(2) ?? '2'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(3) ?? '3'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(4) ?? '4'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(5) ?? '5'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(6) ?? '6'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(7) ?? '7'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(8) ?? '8'));
    cacheTexture(Paths.image(style.buildComboNumSpritePath(9) ?? '9'));
  }

  ///// SOUND //////

  public static function cacheSound(key:String):Void
  {
    if (!isLibraryLoadedForKey(key)) return;
    if (currentCachedSounds.exists(key)) return;

    if (previousCachedSounds.exists(key))
    {
      // Move the texture from the previous cache to the current cache.
      var sound:Null<Sound> = previousCachedSounds.get(key);
      previousCachedSounds.remove(key);
      if (sound != null) currentCachedSounds.set(key, sound);
      return;
    }

    var sound:Null<Sound> = Assets.getSound(key, true);
    if (sound == null) return;
    else
      currentCachedSounds.set(key, sound);
  }

  public static function permanentCacheSound(key:String):Void
  {
    if (!isLibraryLoadedForKey(key)) return;
    if (permanentCachedSounds.exists(key)) return;

    var sound:Null<Sound> = Assets.getSound(key, true);
    if (sound == null) return;
    else
      permanentCachedSounds.set(key, sound);

    if (sound != null) currentCachedSounds.set(key, sound);
  }

  public static function preparePurgeSoundCache():Void
  {
    if (aggressivePurge)
    {
      previousCachedSounds = [];
      currentCachedSounds = permanentCachedSounds.copy();
      return;
    }

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
    Assets.cache.clear("songs");
    Assets.cache.clear("music");
    // Felt lazy.
    var key = Paths.music("freakyMenu/freakyMenu");
    if (!isLibraryLoadedForKey(key)) return;
    var sound:Null<Sound> = Assets.getSound(key, true);
    if (sound != null)
    {
      permanentCachedSounds.set(key, sound);
      currentCachedSounds.set(key, sound);
    }
  }

  ///// MISC /////

  public static inline function clearFreeplay():Void
  {
    var keysToRemove:Array<String> = [];

    @:privateAccess
    for (key in FlxG.bitmap._cache.keys())
    {
      if (!key.contains("freeplay")) continue;
      if (permanentCachedTextures.exists(key) || key.contains("fonts")) continue;

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

  public static inline function clearStickers():Void
  {
    var keysToRemove:Array<String> = [];

    @:privateAccess
    for (key in FlxG.bitmap._cache.keys())
    {
      if (!key.contains("stickers")) continue;
      if (permanentCachedTextures.exists(key) || key.contains("fonts")) continue;

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

  static function log(message:String):Void
  {
    trace(' MEMORY '.bg_bright_lilac().bold() + ' ${message}');
  }
}
