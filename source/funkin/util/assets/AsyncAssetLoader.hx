package funkin.util.assets;

import flixel.FlxG;
import sys.thread.Thread;
import sys.thread.Lock;

class AsyncAssetLoader
{
  static var workingThreads:Array<Thread> = [];
  static var lock:Lock = new Lock();

  public static function loadGraphic(path:String):Thread
  {
    var thread = Thread.create(() -> {
      FlxG.bitmap.add(path);
      trace('LOADED ASYNC: $path');
      lock.release();
    });
    workingThreads.push(thread);
    return thread;
  }

  public static function waitForAssets():Void
  {
    trace("WAITING FOR ASSETS");
    for (_ in workingThreads)
    {
      lock.wait();
    }
    workingThreads = [];
    trace("FINISHED LOADING ASSETS");
  }
}
