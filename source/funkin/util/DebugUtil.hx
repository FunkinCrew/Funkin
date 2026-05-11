package funkin.util;

/**
 * Utility functions for debugging.
 */
class DebugUtil
{
  /**
   * Print the current call stack.
   */
  public static function printCallStack():Void
  {
    var callStack:Array<haxe.CallStack.StackItem> = haxe.CallStack.callStack();
    trace(callStack.join('\n'));
  }
}
