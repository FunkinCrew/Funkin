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

  /**
   * Caches textures that are always required.
   */
  public static inline function initialCache():Void
  {
    var allImages:Array<String> = Assets.list();

    for (file in allImages)
    {
      if (!(file.endsWith(".png") #if FEATURE_COMPRESSED_TEXTURES || file.endsWith(".astc") #end)
        || file.contains("chart-editor")
        || !file.contains("ui/"))
      {
        continue;
      }

      file = file.replace(" ", ""); // Handle stray spaces.

      if (file.contains("shared") || Assets.exists('shared:$file', AssetType.IMAGE))
      {
        file = 'shared:$file';
      }
      permanentCacheTexture(file);
    }

    permanentCacheTexture(Paths.image("healthBar"));
    permanentCacheTexture(Paths.image("menuDesat"));
    permanentCacheTexture(Paths.image("notes", "shared"));
    permanentCacheTexture(Paths.image("noteSplashes", "shared"));
    permanentCacheTexture(Paths.image("noteStrumline", "shared"));
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

      if (file.contains("shared") || Assets.exists('shared:$file', AssetType.SOUND))
      {
        file = 'shared:$file';
      }

      permanentCacheSound(file);
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
    permanentCacheSound(Paths.sound("missnote1", "shared"));
    permanentCacheSound(Paths.sound("missnote2", "shared"));
    permanentCacheSound(Paths.sound("missnote3", "shared"));
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
    if (currentCachedTextures.exists(key))
    {
      return; // Already cached.
    }

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
    }
    else
    {
      trace('Successfully cached graphic: $key');
      graphic.persist = true;
      currentCachedTextures.set(key, graphic);
    }
  }

  /**
   * Permanently caches a texture with the given key.
   * @param key The key of the texture to cache.
   */
  static function permanentCacheTexture(key:String):Void
  {
    if (permanentCachedTextures.exists(key))
    {
      return; // Already cached.
    }

    var graphic:Null<FlxGraphic> = FlxGraphic.fromAssetKey(key, false, null, true);
    if (graphic == null)
    {
      FlxG.log.warn('Failed to cache graphic: $key');
    }
    else
    {
      trace('Successfully cached graphic: $key');
      graphic.persist = true;
      permanentCachedTextures.set(key, graphic);
    }

    currentCachedTextures = permanentCachedTextures;
  }

  /**
   * Prepares the cache for purging unused textures.
   */
  public inline static function preparePurgeTextureCache():Void
  {
    previousCachedTextures = currentCachedTextures;

    for (graphicKey in previousCachedTextures.keys())
    {
      if (permanentCachedTextures.exists(graphicKey))
      {
        previousCachedTextures.remove(graphicKey);
      }
    }

    currentCachedTextures = permanentCachedTextures;
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

      if (obj == null || obj.persist || permanentCachedTextures.exists(key) || key.contains("fonts"))
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
    if (permanentCachedSounds.exists(key)) return;

    var sound:Null<Sound> = Assets.getSound(key, true);
    if (sound == null) return;
    else
      permanentCachedSounds.set(key, sound);

    if (sound != null) currentCachedSounds.set(key, sound);
  }

  public static function preparePurgeSoundCache():Void
  {
    previousCachedSounds = currentCachedSounds;

    for (key in previousCachedSounds.keys())
    {
      if (permanentCachedSounds.exists(key))
      {
        previousCachedSounds.remove(key);
      }
    }

    currentCachedSounds = permanentCachedSounds;
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
      trace('Cleaning up $key');
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
      trace('Cleaning up $key');
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
}
