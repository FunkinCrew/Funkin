package funkin.util.assets;

import flixel.FlxG;
import sys.thread.Thread;
import sys.thread.Mutex;

class AsyncAssetLoader
{
  public static var remaining(default, null):AsyncRemaining = new AsyncRemaining();

  public static function loadGraphic(path:String):Void
  {
    remaining.increment();
    Thread.create(() -> {
      FlxG.bitmap.add(path);
      trace('LOADED ASYNC: $path');
      remaining.decrement();
    });
  }

  public static function waitForAssets():Void
  {
    trace("WAITING FOR ASSETS");
    while (true)
    {
      if (remaining.get() <= 0)
      {
        break;
      }
    }
    trace("FINISHED LOADING ASSETS");
  }
}

private class AsyncRemaining
{
  public var mutex(default, null):Mutex;
  public var remaining(default, null):Int;

  public function new()
  {
    remaining = 0;
    mutex = new Mutex();
  }

  public function increment():Void
  {
    mutex.acquire();
    remaining++;
    mutex.release();
  }

  public function decrement():Void
  {
    mutex.acquire();
    remaining--;
    mutex.release();
  }

  public function get():Int
  {
    mutex.acquire();
    var rem:Int = remaining;
    mutex.release();
    return rem;
  }
}
