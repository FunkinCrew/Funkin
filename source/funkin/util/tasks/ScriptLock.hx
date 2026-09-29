package funkin.util.tasks;

class ScriptLock
{
  #if (sys && FEATURE_MULTITHREADING)
  static final mutex:sys.thread.Mutex = new sys.thread.Mutex();
  #end

  /**
   * Run `fn` while holding the lock and hand back its result.
   */
  public static function run<T>(fn:Void->T):T
  {
    #if (sys && FEATURE_MULTITHREADING)
    mutex.acquire();
    try
    {
      var result:T = fn();
      mutex.release();
      return result;
    }
    catch (e:Dynamic)
    {
      mutex.release();
      throw e;
    }
    #else
    return fn();
    #end
  }
}
