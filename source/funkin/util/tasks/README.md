# funkin.util.tasks

This package contains utilities for performing multi-threaded tasks in a cross-platform, thread-safe way.

## How to Make a Task

Tasks must be a function of the form `(currentState:State, workOutput:WorkOutput)->Void`.

**Notes:**
- `currentState` is an anonymous structure which persists between calls of the task.
  - This can have any fields you like, and ideally should use a typedef.
- `workOutput` is used for sending progress and errors to the main thread.
  - `sendProgress(message:Dynamic, ?transferList:Array<Dynamic>)` calls `onProgress(message)` on the task handler.
  - `sendComplete(message:Dynamic, ?transferList:Array<Dynamic>)` calls `onComplete(message)` on the task handler.
  - `sendError(message:Dynamic, ?transferList:Array<Dynamic>)` calls `onError(message)` on the task handler.
- You have to be careful not to interact with the same thing from multiple threads.
  - A task is at its most stable when it only operates on the variables in `currentState`, and never modifies any static variables.

## Example Task

```haxe
function myTask(currentState:State, workOutput:WorkOutput):Void {
  if (currentState.output == null) {
    currentState.output = new ByteArray(currentState.input.width * currentState.input.height);
  }

  try {
    // You can do all the work in one call, but you won't be able to cancel the task!
    /*
    for (...) {
      // Do work to populate the byteDataOutput.
    }
    */

    // Instead, we do it like this.
    if (currentState.progress == null) currentState.progress = 0;

    if (currentState.progress < 10) {
      for (...) {
        // Do 1/10th of the work to populate the currentState.output.
      }
    }
    currentState.progress++;

  } catch (e) {
    // We got an error! Send it to the TaskHandler.
    workOutput.sendError(e);
  }

  // Work for this iteration is now done.
  if (currentState.progress >= 10) {
    // All work is now done!

    // Okay, so by default, including a value in the message object copies it, which is super slow and uses a bunch of memory.
    // If you include a value in the transferList, it will be MOVED to the main thread rather than copied.
    // This makes the value UNUSABLE from the thread, but it's great for performance,
    // so only do it once you know you're not going to use it anymore.
    workOutput.sendComplete({output: currentState.output}, [currentState.output]);

  } else {
    // Only some of the work is done!
    // End the execution of this threaded task. This allows another threaded task to begin,
    // and also allows the ThreadPool to cancel this task if it was requested.
    // You can include any data you like here to report your progress.
    workOutput.sendProgress({progress: currentState.progress});
  }
}
```
