package funkin.util.tasks;

import lime.system.ThreadPool;
import lime.app.Promise;
import lime.app.Future;
import lime.app.Future.FutureWork;
import lime.system.WorkOutput.ThreadMode;
import haxe.Constraints.NotVoid;

/**
 * A utility class which provides functions for performing parallel tasks in a thread-safe, cross-platform manner.
 * @see https://player03.com/openfl/threads-guide/
 */
@:access(lime.app.Future.FutureWork)
class TaskHandler
{
  /**
   * TaskHandler has been refactored to share the same ThreadPool used by Lime to handle Futures.
   */
  public static function initialize():Void
  {
    trace('[TASK] Starting async task thread pool...');
    var minThreads = 1;
    // TODO: Determine a better value for this.
    var maxThreads = 16;

    FutureWork.minThreads = 1;
    FutureWork.maxThreads = 16;

    trace('[TASK] Thread pool configured...');
  }

  /**
   * Queue a task to be performed asynchronously.
   * More complicated than `getSimpleTask()`, but can perform tasks over multiple iterations,
   * and can report progress back to the main thread.
   *
   * @param params The parameters for the task:
   * @param task A function of the form `(currentState:State, workOutput:WorkOutput)->Void`
   *   `currentState` is a dynamic object which persists between calls of the task.
   *   `workOutput` has functions `sendComplete`, `sendProgress`, `sendError` to report back to the main thread.
   * @param initialState The `State` object to pass to the task the first time it runs.
   * @param promise A Promise which should be resolved when the task is done.
   *   Use `new Promise<T>()` to create one with the correct return type.
   * @return A Future which provides completion status for the task.
   *   You can use `onComplete()` to perform actions when the task is done,
   *   or `onProgress()` to perform actions when the task reports partial progress.
   */
  public static function performTask<T:NotVoid>(params:PerformTaskParams, promise:Promise<T>):Future<T>
  {
    final USE_MULTITHREADING:Bool = #if FEATURE_MULTITHREADING true #else false #end;

    params.initialState ??= {};

    @:privateAccess
    var jobID:Int = FutureWork.run(params.task, promise, params.initialState, USE_MULTITHREADING ? ThreadMode.MULTI_THREADED : ThreadMode.SINGLE_THREADED);

    return promise.future;
  }

  /**
   * Queue a simple task to be performed asynchronously.
   *
   * @param task A function, with a return value, to be executed in parallel with the main thread.
   *   Note this HAS to return something, otherwise callbacks would try (and fail) to use `Void` as an argument,
   *   and it'll fail to build with `'void' cannot be used as a function parameter`.
   *   Just `return true` if you don't need a return value.
   * @return A Future, which provides completion status for the task.
   *   You can use `onComplete((result) -> {})` to perform actions in the main thread when the task is done,
   *   or `then((result) -> {})` to chain tasks together.
   */
  public static function performSimpleTask<T:NotVoid>(task:Void->T):Future<T>
  {
    final USE_MULTITHREADING:Bool = #if FEATURE_MULTITHREADING true #else false #end;
    var future = new Future<T>(task, USE_MULTITHREADING);
    return future;
  }

  /**
   * @return The number of asynchronous tasks the thread pool is working on.
   */
  public static function countJobsInProgress():Int
  {
    return FutureWork.activeJobs;
  }

  /**
   * @return `false` if we are currently not in the main thread (i.e. we are in a worker thread).
   */
  public static function isMainThread():Bool
  {
    return ThreadPool.isMainThread();
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

  /**
   * The initial state to pass to the task.
   * Tasks that perform a small amount of work at a time before completing can modify this state
   * to pass information to the next iteration of the task.
   */
  var ?initialState:State;
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
