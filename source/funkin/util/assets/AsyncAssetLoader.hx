package funkin.util.assets;

import sys.thread.Thread;
import sys.thread.Mutex;
import openfl.media.Sound;
import openfl.utils.Assets;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;

/**
 * Helper class for preloading assets asynchronously
 */
class AsyncAssetLoader
{
  /**
   * The assets that still need to load
   */
  public static var remaining(get, null):Int = 0;

  static var mutex:Mutex = new Mutex();

  /**
   * Loads a `FlxGraphic` asynchronously
   * @param path The path to the image
   */
  public static function loadGraphic(path:String):Void
  {
    mutex.acquire();
    remaining++;
    mutex.release();

    Thread.create(() -> {
      // For thread safety we cache it ourselves
      var graphic:FlxGraphic = FlxGraphic.fromAssetKey(path, false, null, false);

      mutex.acquire();
      FlxG.bitmap.addGraphic(graphic);
      trace('Loaded async: $path');
      remaining--;
      mutex.release();
    });
  }

  /**
   * Loads a `Sound` asynchronously
   * @param path The path to the sound
   */
  public static function loadSound(path:String):Void
  {
    if (!Assets.cache.enabled)
    {
      trace('Assets cache is disabled\nThere is no use preloading $path');
      return;
    }

    mutex.acquire();
    remaining++;
    mutex.release();

    Thread.create(() -> {
      // For thread safety we cache it ourselves
      var sound:Sound = Assets.getSound(path, false);

      mutex.acquire();
      Assets.cache.setSound(path, sound);
      trace('Loaded async: $path');
      remaining--;
      mutex.release();
    });
  }

  /**
   * Halts the program until all assets finished loading
   */
  public static function waitForAssets():Void
  {
    trace('Waiting for assets');
    while (true)
    {
      if (remaining <= 0)
      {
        break;
      }
    }
    trace('Finished loading assets');
  }

  static function get_remaining():Int
  {
    mutex.acquire();
    var value:Int = remaining;
    mutex.release();
    return value;
  }
}
