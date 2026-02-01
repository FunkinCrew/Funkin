package funkin.memory;

import flixel.FlxG;
import funkin.play.notes.notestyle.NoteStyle;
import openfl.utils.AssetType;
import openfl.Assets;
import openfl.media.Sound;
import funkin.util.flixel.sound.FlxPartialSound;
import funkin.memory.FunkinMemory.CacheTriplet;
import funkin.memory.CacheLifeCycle;

@:nullSafety
@:allow(funkin.memory.FunkinMemory)
class SoundCache
{
  // after thinking about it, I don't think we should combine sounds and textures in one structure.
  static var cacheTriplet:CacheTriplet<Sound> =
    {
      permanent: [],
      current: [],
      previous: []
    };

  static function initCache():Void
  {
    CacheLifeCycle.initCache(cacheTriplet);
  }

  static function cache(key:String):Void
  {
    if (cacheTriplet.current.exists(key)) return;

    var sound:Null<Sound> = CacheLifeCycle.reuseIfPossible(cacheTriplet, key) ?? Assets.getSound(key, true);

    if (sound != null) cacheTriplet.current.set(key, sound);
  }

  static function permanentCache(key:String):Void
  {
    if (cacheTriplet.permanent.exists(key)) return;

    var sound:Null<Sound> = Assets.getSound(key, true);
    if (sound != null) cacheTriplet.permanent.set(key, sound);
  }

  static function preparePurge():Void
  {
    CacheLifeCycle.preparePurge(cacheTriplet);
  }

  /**
   * Purges unused sounds from the cache.
   */
  static function purge():Void
  {
    for (key in cacheTriplet.previous.keys())
    {
      if (cacheTriplet.permanent.exists(key))
      {
        cacheTriplet.previous.remove(key);
        continue;
      }
      var sound:Null<Sound> = cacheTriplet.previous.get(key);
      if (sound != null)
      {
        FunkinMemory.log('Cleaning SOUND asset $key');
        Assets.cache.removeSound(key);
        cacheTriplet.previous.remove(key);
      }
    }

    // Clears out files within the songs folder and the music folder
    FunkinMemory.log("Purging unused sounds from memory...");
    var allSounds = Assets.cache.sound.keys();
    for (file in allSounds)
    {
      if (!file.endsWith(".ogg") || file.contains("freakyMusic")) continue;

      file = file.replace(" ", "");

      if (file.contains("shared") || Assets.exists('shared:$file', AssetType.SOUND))
      {
        file = 'shared:$file';
      }

      if (cacheTriplet.permanent.exists(file) || !Assets.cache.hasSound(file)) continue;
      FunkinMemory.log('Cleaning SOUND asset $file');
      Assets.cache.removeSound(file);
    }

    FlxPartialSound.clearCache();
  }
}
