package funkin.util.protocol;

import haxe.io.Path;

/**
 * Handles the inter-process communication for one-click install requests.
 */
@:nullSafety
class OneClickBridge
{
  /**
   * How long the running instance waits between heartbeats, in milliseconds.
   */
  public static inline final HEARTBEAT_INTERVAL:Float = 2000.0;

  /**
   * How long the running instance waits between queue checks, in milliseconds.
   */
  public static inline final POLL_INTERVAL:Float = 500.0;

  /**
   * How long a heartbeat can be stale before the running instance is considered dead, in
   * milliseconds.
   */
  static inline final STALE_MILLIS:Float = 10000.0;

  /**
   * The name of the directory holding queued requests, relative to the temp directory.
   */
  static inline final QUEUE_DIR_NAME:String = 'oneclick';

  /**
   * The name of the heartbeat lock, relative to the temp directory.
   */
  static inline final LOCK_FILE_NAME:String = 'oneclick.lock';

  /**
   * Names of the environment variables that might point at a temp directory on Windows.
   */
  static final TEMP_ENV_VARS:Array<String> = ['TEMP', 'TMPDIR', 'TEMPDIR', 'TMP'];

  // Wall clock rather than frame deltas. The game stops updating the moment it loses focus, which
  // is exactly when somebody clicks an install link, so a delta based timer would freeze the
  // heartbeat and every link would spawn a second copy of the game.
  static var lastHeartbeat:Float = 0.0;
  static var lastPoll:Float = 0.0;
  static var holdsLock:Bool = false;

  /**
   * Pulls the first `funkin-mod:` URL out of a command line.
   *
   * @param args The raw arguments, usually `Sys.args()`.
   * @return The URL, or null if there isn't one.
   */
  public static function extractUrl(args:Null<Array<String>>):Null<String>
  {
    if (args == null) return null;

    final prefix:String = '${Constants.ONE_CLICK_SCHEME}:';

    for (arg in args)
    {
      if (arg == null) continue;

      final trimmed:String = StringTools.trim(arg);
      if (StringTools.startsWith(trimmed.toLowerCase(), prefix)) return trimmed;
    }

    return null;
  }

  /**
   * Whether another copy of the game is currently running and listening for requests.
   */
  public static function isInstanceLive():Bool
  {
    #if sys
    final lockPath:Null<String> = getLockPath();
    if (lockPath == null) return false;

    try
    {
      if (!sys.FileSystem.exists(lockPath)) return false;

      final written:Null<Float> = Std.parseFloat(StringTools.trim(sys.io.File.getContent(lockPath)));
      if (written == null || Math.isNaN(written)) return false;

      final age:Float = Date.now().getTime() - written;

      // If the heartbeat is older than STALE_MILLIS, the running instance is considered dead and we can take over.
      return age < STALE_MILLIS;
    }
    catch (e:Dynamic)
    {
      trace('Failed to read the one-click lock: ${e}');
    }
    #end

    return false;
  }

  /**
   * Drops a URL into the queue for the running instance to pick up.
   *
   * @param url The URL to hand over.
   * @return Whether the request was written.
   */
  public static function enqueue(url:String):Bool
  {
    #if sys
    final queueDir:Null<String> = getQueueDir();
    if (queueDir == null) return false;

    try
    {
      ensureDir(queueDir);

      // The random suffix keeps two links clicked in the same millisecond from colliding.
      final name:String = '${Std.string(Date.now().getTime())}-${Std.random(0x7FFFFFFF)}.txt';

      sys.io.File.saveContent(Path.join([queueDir, name]), url);

      return true;
    }
    catch (e:Dynamic)
    {
      trace('Failed to queue a one-click request: ${e}');
    }
    #end

    return false;
  }

  /**
   * Marks this process as the instance that owns incoming requests.
   * Safe to call more than once.
   */
  public static function claimLock():Void
  {
    #if sys
    holdsLock = true;
    lastPoll = Date.now().getTime();

    writeHeartbeat();
    #end
  }

  /**
   * Gives up ownership, so the next launch boots normally instead of exiting silently.
   */
  public static function releaseLock():Void
  {
    #if sys
    if (!holdsLock) return;

    holdsLock = false;

    final lockPath:Null<String> = getLockPath();
    if (lockPath == null) return;

    try
    {
      if (sys.FileSystem.exists(lockPath)) sys.FileSystem.deleteFile(lockPath);
    }
    catch (e:Dynamic)
    {
      trace('Failed to release the one-click lock: ${e}');
    }
    #end
  }

  /**
   * Updates the heartbeat and checks for queued requests.
   * Call this every frame from the running instance, from something that keeps ticking while the
   * window is out of focus.
   *
   * @return The URLs that were queued, oldest first. Empty most of the time.
   */
  public static function update():Array<String>
  {
    #if sys
    if (!holdsLock) return [];

    final now:Float = Date.now().getTime();

    if (now - lastHeartbeat >= HEARTBEAT_INTERVAL) writeHeartbeat();

    if (now - lastPoll >= POLL_INTERVAL)
    {
      lastPoll = now;
      return drain();
    }
    #end

    return [];
  }

  /**
   * Reads and clears the queue.
   *
   * @return The URLs that were queued, oldest first.
   */
  public static function drain():Array<String>
  {
    final results:Array<String> = [];

    #if sys
    final queueDir:Null<String> = getQueueDir();
    if (queueDir == null) return results;

    try
    {
      if (!sys.FileSystem.exists(queueDir) || !sys.FileSystem.isDirectory(queueDir)) return results;

      final entries:Array<String> = sys.FileSystem.readDirectory(queueDir);

      // File names lead with a millisecond timestamp, so this puts the oldest request first.
      entries.sort(function(a:String, b:String):Int {
        return a < b ? -1 : (a > b ? 1 : 0);
      });

      for (entry in entries)
      {
        final path:String = Path.join([queueDir, entry]);

        try
        {
          if (sys.FileSystem.isDirectory(path)) continue;

          final url:String = StringTools.trim(sys.io.File.getContent(path));

          sys.FileSystem.deleteFile(path);

          if (url != '') results.push(url);
        }
        catch (e:Dynamic)
        {
          trace('Failed to read a queued one-click request: ${e}');
        }
      }
    }
    catch (e:Dynamic)
    {
      trace('Failed to drain the one-click queue: ${e}');
    }
    #end

    return results;
  }

  #if sys
  static function writeHeartbeat():Void
  {
    final lockPath:Null<String> = getLockPath();
    if (lockPath == null) return;

    try
    {
      ensureDir(Path.directory(lockPath));

      lastHeartbeat = Date.now().getTime();

      sys.io.File.saveContent(lockPath, Std.string(lastHeartbeat));
    }
    catch (e:Dynamic)
    {
      trace('Failed to write the one-click lock: ${e}');
    }
  }

  static function getLockPath():Null<String>
  {
    final root:Null<String> = getRootDir();
    if (root == null) return null;

    return Path.join([root, LOCK_FILE_NAME]);
  }

  static function getQueueDir():Null<String>
  {
    final root:Null<String> = getRootDir();
    if (root == null) return null;

    return Path.join([root, QUEUE_DIR_NAME]);
  }

  /**
   * Returns a directory that is safe to write to for the current user.
   */
  static function getRootDir():Null<String>
  {
    #if windows
    var path:Null<String> = null;

    for (envName in TEMP_ENV_VARS)
    {
      path = Sys.getEnv(envName);
      if (path == '') path = null;
      if (path != null) break;
    }

    if (path == null) return null;

    return Path.join([path, 'funkin']);
    #else
    return '/tmp/funkin';
    #end
  }

  static function ensureDir(dir:String):Void
  {
    if (dir == '' || sys.FileSystem.exists(dir)) return;

    sys.FileSystem.createDirectory(dir);
  }
  #end
}
