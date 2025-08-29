package funkin.util;

#if sys
import sys.thread.Lock;
import sys.thread.Mutex;
import sys.thread.Thread;
#end

/**
 * Utilities for creating and managing Threads. Only available on desktop devices.
 */
class ThreadUtil
{
  #if sys
  /**
   * Data regarding every looping Thread.
   */
  public static var loopingThreads:Map<String, ThreadParams> = [];
  #end

  /**
   * Creates a Thread that executes `job` once outside of the Main Thread.
   * @param job The function to execute.
   */
  public static function createThread(job:Void->Void)
  {
    #if sys
    return Thread.create(job);
    #else
    throw "Threads aren't supported on this device.";
    return null;
    #end
  }

  /**
   * Creates a Thread that starts after a set time.
   * @param job The function to execute after the delay.
   * @param delay The delay itself.
   */
  public static function createDelayedThread(job:Void->Void, delay:Float = 1.0)
  {
    #if sys
    return Thread.create(function() {
      Sys.sleep(delay);

      job();
    });
    #else
    throw "Threads aren't supported on this device.";
    return null;
    #end
  }

  /**
   * Creates a Thread that loops infinitely until destroyed.
   * @param id The ID of the Thread, used for pausing, resuming and stopping.
   * @param job The function to execute.
   * @param startDelay The delay before the loop begins.
   * @param loopDelay The delay between every loop.
   */
  public static function createLoopingThread(id:String, job:Void->Void, startDelay:Float = 1.0, loopDelay:Float = 0.0)
  {
    #if sys
    var threadInfo:ThreadParams = {thread: null, isPaused: false, isDestroyed: false}
    loopingThreads.set(id, threadInfo);

    var thread:Thread = Thread.create(function() {
      Sys.sleep(startDelay);

      while (!threadInfo.isDestroyed)
      {
        if (threadInfo.isPaused) continue;

        job();

        Sys.sleep(loopDelay);
      }

      // Clean-up.
      if (threadInfo.isDestroyed)
      {
        threadInfo.thread = null;
        loopingThreads.remove(id);
      }
    });

    threadInfo.thread = thread;
    return thread;
    #else
    throw "Threads aren't supported on this device.";
    return null;
    #end
  }

  /**
   * Pauses a looping Thread.
   * @param id The ID of the Thread to pause.
   */
  public static function pauseThread(id:String)
  {
    #if sys
    if (loopingThreads.exists(id)) loopingThreads[id].isPaused = true;
    #else
    throw "Threads aren't supported on this device.";
    #end
  }

  /**
   * Resumes a looping Thread.
   * @param id The ID of the Thread to resume.
   */
  public static function resumeThread(id:String)
  {
    #if sys
    if (loopingThreads.exists(id)) loopingThreads[id].isPaused = false;
    #else
    throw "Threads aren't supported on this device.";
    #end
  }

  /**
   * Stops a looping Thread and destroys it afterwards.
   * @param id The ID of the Thread to stop and destroy.
   */
  public static function stopThread(id:String)
  {
    #if sys
    if (loopingThreads.exists(id)) loopingThreads[id].isDestroyed = true;
    #else
    throw "Threads aren't supported on this device.";
    #end
  }

  /**
   * Creates a Mutex which can be used with `acquire()` to acquire a temporary lock to access some ressource.
   * A Mutex must always be released by the owner Thread by using `release()` as many times as it had been acquired.
   */
  public static function createMutex()
  {
    #if sys
    return new Mutex();
    #else
    throw "Threads aren't supported on this device.";
    return null;
    #end
  }

  /**
   * Creates a Lock which blocks execution until released via `release()` or `wait(?timeout:Float)`, the latter returning `false` if the Lock doesn't get released within the provided time.
   * When created, the Lock is initially locked.
   */
  public static function createLock()
  {
    #if sys
    return new Lock();
    #else
    throw "Threads aren't supported on this device.";
    return null;
    #end
  }
}

#if sys
typedef ThreadParams =
{
  var thread:Thread;
  var isPaused:Bool;
  var isDestroyed:Bool;
}
#end
