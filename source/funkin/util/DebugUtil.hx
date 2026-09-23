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
    var result:String = '';

    for (stackItem in callStack)
    {
      switch (stackItem)
      {
        case FilePos(innerStackItem, file, line, column):
          result += ' in ${file}#${line}';
          if (column != null) result += ':${column}';
        case CFunction:
          result += '[Function] ';
        case Module(m):
          result += '[Module(${m})] ';
        case Method(classname, method):
          result += '[Function(${classname}.${method})] ';
        case LocalFunction(v):
          result += '[LocalFunction(${v})] ';
      }
      result += '\n';
    }

    trace(result);
  }
}
