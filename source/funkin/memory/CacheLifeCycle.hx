package funkin.memory;

import flixel.FlxG;
import funkin.play.notes.notestyle.NoteStyle;
import openfl.utils.AssetType;
import openfl.Assets;
import openfl.media.Sound;
import funkin.util.flixel.sound.FlxPartialSound;
import funkin.memory.FunkinMemory.CacheTriplet;

// dude i lowk dunno if this is even worth it but whatever
@:nullSafety
@:allow(funkin.memory.BitmapCache, funkin.memory.SoundCache)
class CacheLifeCycle
{
  static function preparePurge<T>(cache:CacheTriplet<T>):Void
  {
    for (k in cache.current.keys())
    {
      var asset:Null<T> = cache.current.get(k);
      if (asset != null) cache.previous.set(k, asset);
    }

    cache.current.clear();

    for (k in cache.previous.keys())
    {
      if (cache.permanent.exists(k))
      {
        cache.previous.remove(k);
      }
    }
  }

  static function reuseIfPossible<T>(cache:CacheTriplet<T>, key:String):Null<T>
  {
    if (!cache.previous.exists(key)) return null;

    var asset:Null<T> = cache.previous.get(key);
    cache.previous.remove(key);
    if (asset != null) cache.current.set(key, asset);
    return asset;
  }
}
