package funkin.util.tasks;

import lime.system.ThreadPool;

/**
 * A utility class which provides functions for performing parallel tasks in a thread-safe, cross-platform manner.
 * @see https://player03.com/openfl/threads-guide/
 */
class TaskHandler
{
  static var threadPool(get, never):ThreadPool;
  static var _threadPool:Null<ThreadPool> = null;

  static function get_threadPool():ThreadPool
  {
    if (_threadPool == null)
    {
      _threadPool = buildThreadPool();
    }
    return _threadPool;
  }

  /**
   * A mapping between job identifiers and the callback functions for those jobs.
   */
  static var callbackHandlers:Map<Int, TaskCallbacks> = new Map();

  static function buildThreadPool():ThreadPool
  {
    trace('[TASK] Starting thread pool...');
    var minThreads = 1;
    // TODO: Determine a better value for this.
    var maxThreads = 16;

    var result = new ThreadPool(minThreads, maxThreads); // , MULTI_THREADED

    trace('[TASK] Thread pool started...');

    // In single-threaded mode, this determines the % of CPU time to spend on jobs.
    // In multithreaded mode, this does nothing.
    // ThreadPool.workLoad = 1 / 2;

    result.onRun.add(onTaskStarted);
    result.onComplete.add(onTaskComplete);
    result.onError.add(onTaskError);
    result.onProgress.add(onTaskProgress);

    return result;
  }

  /**
   * Queue a task to be performed asynchronously.
   *
   * @param task A function of the form `(currentState:State, workOutput:WorkOutput)->Void`
   *   `currentState` is a dynamic object which persists between calls of the task.
   *   `workOutput` is used for sending progress and errors to the main thread.
   * @param initialState The `State` object to pass to the task the first time it runs.
   * @return A unique ID for the task, which lets you cancel it later or query its status.
   */
  public static function performTask(params:PerformTaskParams):Int
  {
    var jobID:Int = threadPool.run(params.task, params.initialState);

    callbackHandlers.set(jobID, params.taskCallbacks);

    return jobID;
  }

  public static function cancelAllTasks()
  {
    threadPool.cancel("System cancelled all tasks.");
  }

  public static function countJobsInProgress():Int
  {
    return threadPool.activeJobs;
  }

  /**
   * Returns false if we are currently not in the main thread (i.e. we are in a worker thread).
   */
  public static function isMainThread():Bool
  {
    return ThreadPool.isMainThread();
  }

  static function cleanCallbacks(jobID:Int):Void
  {
    if (callbackHandlers.exists(jobID))
    {
      callbackHandlers.remove(jobID);
    }
  }

  /**
   * Called when any task is started.
   */
  static function onTaskStarted(input:Dynamic):Void
  {
    // The job ID that just received the event.
    // TODO: Somehow filter onTaskStarted callbacks to just the ones for the current job.
    var jobID:Int = threadPool.activeJob.id;

    if (callbackHandlers.exists(jobID))
    {
      var callbacks = callbackHandlers.get(jobID);
      if (callbacks.onStart != null)
      {
        callbacks.onStart(input);
      }
    }
  }

  /**
   * Called when any task is completed.
   */
  static function onTaskComplete(input:Dynamic):Void
  {
    // The job ID that just received the event.
    // TODO: Somehow filter onTaskComplete callbacks to just the ones for the current job.
    var jobID:Int = threadPool.activeJob.id;

    if (callbackHandlers.exists(jobID))
    {
      var callbacks = callbackHandlers.get(jobID);
      if (callbacks.onComplete != null)
      {
        callbacks.onComplete(input);
      }
    }

    // Since we got a COMPLETE event, we won't be receiving more callbacks for this job.
    cleanCallbacks(jobID);
  }

  /**
   * Called when any task throws an error.
   */
  static function onTaskError(input:Dynamic):Void
  {
    // The job ID that just received the event.
    // TODO: Somehow filter onTaskError callbacks to just the ones for the current job.
    var jobID:Int = threadPool.activeJob.id;

    if (callbackHandlers.exists(jobID))
    {
      var callbacks = callbackHandlers.get(jobID);
      if (callbacks.onError != null)
      {
        callbacks.onError(input);
      }
    }

    // Since we got an ERROR event, we won't be receiving more callbacks for this job.
    cleanCallbacks(jobID);
  }

  /**
   * Called when any task calls `sendProgress()`.
   */
  static function onTaskProgress(input:Dynamic):Void
  {
    // The job ID that just received the event.
    // TODO: Somehow filter onTaskProgress callbacks to just the ones for the current job.
    var jobID:Int = threadPool.activeJob.id;

    if (callbackHandlers.exists(jobID))
    {
      var callbacks = callbackHandlers.get(jobID);
      if (callbacks.onProgress != null)
      {
        callbacks.onProgress(input);
      }
    }
  }
}

/**
 * Parameters to be passed to `TaskHandler.performTask()`
 */
typedef PerformTaskParams =
{
  /**
   * The task to perform.
   * Must be a function which takes a `State` and a `WorkOutput` as arguments and returns nothing.
   */
  var task:Task;

  var ?initialState:State;
  var ?taskCallbacks:TaskCallbacks;
}

typedef TaskCallbacks =
{
  var ?onStart:Dynamic->Void;
  var ?onComplete:Dynamic->Void;
  var ?onError:Dynamic->Void;
  var ?onProgress:Dynamic->Void;
}

/**
 * An object which handles the status of tasks.
 * Call `sendProgress()` or `sendComplete()` or `sendError()` to send status to the main thread.
 */
typedef WorkOutput = lime.system.WorkOutput;

/**
 * An object which handles the state for tasks.
 * Add any parameters you want here to pass into the running task.
 */
typedef State = lime.system.WorkOutput.State;

/**
 * A task to be performed.
 * Must be a function of the form `(State, WorkOutput) -> Void`
 */
typedef Task = lime.system.WorkOutput.WorkFunction<State->WorkOutput->Void>;
