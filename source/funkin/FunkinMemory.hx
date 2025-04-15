package funkin;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
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
class FunkinMemory
{
  static var permanentCachedTextures:Map<String, FlxGraphic> = [];
  static var currentCachedTextures:Map<String, FlxGraphic> = [];
  static var previousCachedTextures:Map<String, FlxGraphic> = [];

  // waow
  static var permanentCachedSounds:Map<String, Sound> = [];
  static var currentCachedSounds:Map<String, Sound> = [];
  static var previousCachedSounds:Map<String, Sound> = [];

  /**
   * Caches textures that are always required.
   */
  public static inline function initialCache():Void
  {
    var allImages:Array<String> = Assets.list(AssetType.IMAGE);

    for (file in allImages)
    {
      if (!file.endsWith(".png") || file.contains("chart-editor") || !file.contains("ui/"))
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
    permanentCacheSound(Paths.sound("missnote1", "shared"));
    permanentCacheSound(Paths.sound("missnote2", "shared"));
    permanentCacheSound(Paths.sound("missnote3", "shared"));
  }

  /**
   * Clears the current texture and sound caches.
   */
  public static inline function purgeCache(?callGarbageCollector:Bool = false):Void
  {
    preparePurgeTextureCache();
    purgeTextureCache();
    preparePurgeSoundCache();
    purgeSoundCache();
    if (callGarbageCollector) System.gc();
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
      var graphic = previousCachedTextures.get(key);
      previousCachedTextures.remove(key);
      currentCachedTextures.set(key, graphic);
      return;
    }

    var graphic = FlxGraphic.fromAssetKey(key, false, null, true);
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

    var graphic = FlxGraphic.fromAssetKey(key, false, null, true);
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

      var graphic = previousCachedTextures.get(graphicKey);
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
      var obj = FlxG.bitmap.get(key);

      if (obj == null || obj.persist || permanentCachedTextures.exists(key) || key.contains("fonts"))
      {
        continue;
      }

      if (obj.useCount > 0 && !key.contains("characters") && !key.contains("charSelect") && !key.contains("results"))
      {
        continue;
      }

      FlxG.bitmap.removeKey(key);
      obj.destroy();
    }
  }

  ///// SOUND //////

  public static function cacheSound(key:String):Void
  {
    if (currentCachedSounds.exists(key)) return;

    if (previousCachedSounds.exists(key))
    {
      // Move the texture from the previous cache to the current cache.
      var sound = previousCachedSounds.get(key);
      previousCachedSounds.remove(key);
      currentCachedSounds.set(key, sound);
      return;
    }

    var sound = Assets.getSound(key, true);
    if (sound == null) return;
    else
      currentCachedSounds.set(key, sound);
  }

  public static function permanentCacheSound(key:String):Void
  {
    if (permanentCachedSounds.exists(key)) return;

    var sound = Assets.getSound(key, true);
    if (sound == null) return;
    else
      permanentCachedSounds.set(key, sound);

    currentCachedSounds.set(key, sound);
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

      var sound = previousCachedSounds.get(key);
      if (sound != null)
      {
        Assets.cache.removeSound(key);
        previousCachedTextures.remove(key);
        sound = null;
      }
    }
    Assets.cache.clear("songs");
    Assets.cache.clear("music");
    // Felt lazy.
    var key = Paths.music("freakyMenu/freakyMenu");
    var sound = Assets.getSound(key, true);
    permanentCachedSounds.set(key, sound);
    currentCachedSounds.set(key, sound);
  }

  ///// MISC /////

  public static inline function clearFreeplay():Void
  {
    @:privateAccess
    for (key in FlxG.bitmap._cache.keys())
    {
      var obj = FlxG.bitmap.get(key);
      if (obj == null) continue;

      if (!key.contains("stickers"))
      {
        continue;
      }

      if (permanentCachedTextures.exists(key) || key.contains("fonts")) continue;

      trace('Queued $key to clean up');

      new Future<String>(function() {
        new FlxTimer().start(1 / 24, function(_) {
          FlxG.bitmap.removeKey(key);
          if (currentCachedTextures.exists(key)) currentCachedTextures.remove(key);
          obj.destroy();
          Assets.cache.clear(key);
          trace('$key destroyed');
        });
        return '$key destroyed';
      }, true);
    }

    preparePurgeSoundCache();
    purgeSoundCache();
  }
}
