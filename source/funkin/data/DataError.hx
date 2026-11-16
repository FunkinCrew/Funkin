package funkin.data;

import json2object.Position;
import json2object.Position.Line;
import json2object.Error;
#if FEATURE_MULTITHREADING
import hx.concurrent.collection.SynchronizedArray;
#end

@:nullSafety
class DataError
{
  #if FEATURE_MULTITHREADING
  private static var queuedErrors:SynchronizedArray<{errors:Array<Error>, id:String}> = new SynchronizedArray();
  #else
  private static var queuedErrors:Array<{errors:Array<Error>, id:String}> = [];
  #end

  /**
   * There's a possibility for JSON entries parsing to fail when loaded.
   * If the registries are loaded asynchronously, error windows would overlay one another.
   * For this reason, the errors should get added to an array and then emptied in the main thread,
   * making the window popups appear one after another.
   */
  public static function printQueuedErrors():Void
  {
    for (queuedError in queuedErrors)
    {
      showErrors(queuedError.errors, queuedError.id);
    }
    queuedErrors.clear();
  }

  public static function showErrors(errors:Array<Error>, id:String):Void
  {
    if (!funkin.util.tasks.TaskHandler.isMainThread())
    {
      queuedErrors.push({errors: errors, id: id});
      return;
    }

    var message:String = 'Failed to parse $id:\n' + json2object.ErrorUtils.convertError(errors[0]);
    if (errors.length > 1) message += '\n(and ${errors.length - 1} more)';

    funkin.util.WindowUtil.showError('Data Parsing Error', message);
  }

  public static function printError(error:Error):Void
  {
    switch (error)
    {
      case IncorrectType(vari, expected, pos):
        trace(' ERROR '.error() + 'Expected field "$vari" to be of type "$expected".');
        printPos(pos);
      case IncorrectEnumValue(value, expected, pos):
        trace(' ERROR '.error() + 'Invalid enum value (expected "$expected", got "$value")');
        printPos(pos);
      case InvalidEnumConstructor(value, expected, pos):
        trace(' ERROR '.error() + 'Invalid enum constructor (expected "$expected", got "$value")');
        printPos(pos);
      case UninitializedVariable(vari, pos):
        trace(' ERROR '.error() + 'Uninitialized variable "$vari"');
        printPos(pos);
      case UnknownVariable(vari, pos):
        trace(' ERROR '.error() + 'Unknown variable "$vari"');
        printPos(pos);
      case ParserError(message, pos):
        trace(' ERROR '.error() + 'Parsing error: ${message}');
        printPos(pos);
      case CustomFunctionException(e, pos):
        if (Std.isOfType(e, String))
        {
          trace(' ERROR '.error() + '${e}');
        }
        else
        {
          printUnknownError(e);
        }
        printPos(pos);
      default:
        printUnknownError(error);
    }
  }

  public static function printUnknownError(e:Dynamic):Void
  {
    switch (Type.typeof(e))
    {
      case TClass(c):
        trace(' ERROR '.error() + '(${Type.getClassName(c)}) ${e.toString()}');
      case TEnum(c):
        trace(' ERROR '.error() + '(${Type.getEnumName(c)}) ${e.toString()}');
      default:
        trace(' ERROR '.error() + '(${Type.typeof(e)}) ${Std.string(e)}');
    }
  }

  /**
   * TODO: Figure out the nicest way to print this.
   * Maybe look up how other JSON parsers format their errors?
   * @see https://github.com/elnabo/json2object/blob/master/src/json2object/Position.hx
   */
  static function printPos(pos:Position):Void
  {
    if (pos.lines[0].number == pos.lines[pos.lines.length - 1].number)
    {
      trace('   at ${(pos.file == '') ? 'line ' : '${pos.file}:'}${pos.lines[0].number}');
    }
    else
    {
      trace('   at ${(pos.file == '') ? 'line ' : '${pos.file}:'}${pos.lines[0].number}-${pos.lines[pos.lines.length - 1].number}');
    }
  }
}
