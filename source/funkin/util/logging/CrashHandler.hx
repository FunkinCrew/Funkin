package funkin.util.logging;

import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.FlxG.FlxRenderMethod;

/**
 * A custom crash handler that writes to a log file and displays a message box.
 */
@:nullSafety
class CrashHandler
{
  public static final LOG_FOLDER = 'logs';

  /**
   * Called before exiting the game when a standard error occurs, like a thrown exception.
   * @param message The error message.
   */
  public static var errorSignal(default, null):FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

  /**
   * Called before exiting the game when a critical error occurs, like a stack overflow or null object reference.
   * CAREFUL: The game may be in an unstable state when this is called.
   * @param message The error message.
   */
  public static var criticalErrorSignal(default, null):FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

  /**
   * Initializes
   */
  public static function initialize():Void
  {
    trace('[LOG] Enabling standard uncaught error handler...');
    Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);

    #if cpp
    trace('[LOG] Enabling C++ critical error handler...');
    untyped __global__.__hxcpp_set_critical_error_handler(onCriticalError);
    #end
  }

  /**
   * Called when an uncaught error occurs.
   * This handles most thrown errors, and is sufficient to handle everything alone on HTML5.
   * @param error Information on the error that was thrown.
   */
  static function onUncaughtError(error:UncaughtErrorEvent):Void
  {
    try
    {
      errorSignal.dispatch(generateErrorMessage(error));

      try
      {
        #if sys
        logError(error);
        #end
      }
      catch (e:Dynamic)
      {
        trace('Error while logging error: ' + e);
      }

      displayError(error);
    }
    catch (e:Dynamic)
    {
      trace('Error while handling crash: ' + e);
    }

    #if sys
    Sys.sleep(1); // wait a few moments of margin to process.
    // Exit the game. Since it threw an error, we use a non-zero exit code.
    openfl.Lib.application.window.close();
    #end
  }

  static function onCriticalError(message:String):Void
  {
    try
    {
      criticalErrorSignal.dispatch(message);

      #if sys
      logErrorMessage(message, true);
      #end

      displayErrorMessage(message);
    }
    catch (e:Dynamic)
    {
      trace('Error while handling crash: $e');

      trace('Message: $message');
    }

    #if sys
    Sys.sleep(1); // wait a few moments of margin to process.
    // Exit the game. Since it threw an error, we use a non-zero exit code.
    openfl.Lib.application.window.close();
    #end
  }

  static function displayError(error:UncaughtErrorEvent):Void
  {
    displayErrorMessage(generateErrorMessage(error));
  }

  static function displayErrorMessage(message:String):Void
  {
    lime.app.Application.current.window.alert(message, "Fatal Uncaught Exception");
  }

  #if sys
  static function logError(error:UncaughtErrorEvent):Void
  {
    logErrorMessage(generateErrorMessage(error));
  }

  static function logErrorMessage(message:String, critical:Bool = false):Void
  {
    FileUtil.createDirIfNotExists(LOG_FOLDER);

    sys.io.File.saveContent('$LOG_FOLDER/crash${critical ? '-critical' : ''}-${DateUtil.generateTimestamp()}.log', buildCrashReport(message));
  }
  #end

  static function buildCrashReport(message:String):String
  {
    var fullContents:String = '=====================\n';
    fullContents += ' Funkin Crash Report\n';
    fullContents += '=====================\n';

    fullContents += '\n';

    fullContents += buildSystemInfo();

    fullContents += '\n\n';

    fullContents += '=====================\n';

    fullContents += '\n';

    var currentState:String = 'No state loaded';
    if (FlxG.state != null)
    {
      var currentStateCls:Null<Class<Dynamic>> = Type.getClass(FlxG.state);
      if (currentStateCls != null)
      {
        currentState = Type.getClassName(currentStateCls) ?? 'No state loaded';
      }
    }

    fullContents += 'Flixel Current State: ${currentState}\n';

    fullContents += '\n';

    fullContents += '=====================\n';

    fullContents += '\n';

    fullContents += 'Haxelibs: \n';

    for (lib in Constants.LIBRARY_VERSIONS)
    {
      fullContents += '- ${lib}\n';
    }

    fullContents += '\n';

    fullContents += '=====================\n';

    fullContents += '\n';

    fullContents += 'Loaded mods: \n';

    if (funkin.modding.PolymodHandler.loadedModIds.length == 0)
    {
      fullContents += 'No mods loaded.\n';
    }
    else
    {
      for (mod in funkin.modding.PolymodHandler.loadedModIds)
      {
        fullContents += '- ${mod}\n';
      }
    }

    fullContents += '\n';

    fullContents += '=====================\n';

    fullContents += '\n';

    fullContents += message;

    fullContents += '\n';

    return fullContents;
  }

  public static function buildSystemInfo():String
  {
    var fullContents = 'Generated by: ${Constants.GENERATED_BY}\n';
    fullContents += '  Git hash: ${Constants.GIT_HASH} (${Constants.GIT_HAS_LOCAL_CHANGES ? 'MODIFIED' : 'CLEAN'})\n';
    fullContents += 'System timestamp: ${DateUtil.generateTimestamp()}\n';
    var driverInfo = FlxG?.stage?.context3D?.driverInfo ?? 'N/A';
    fullContents += 'Driver info: ${driverInfo}\n';
    #if sys
    fullContents += 'Platform: ${Sys.systemName()}\n';
    #end
    fullContents += 'Render method: ${renderMethod()}\n';

    fullContents += '\n';

    fullContents += '=====================\n';

    fullContents += '\n';

    fullContents += MemoryUtil.buildGCInfo();

    return fullContents;
  }

  static function generateErrorMessage(error:UncaughtErrorEvent):String
  {
    var errorMessage:String = "";
    var callStack:Array<haxe.CallStack.StackItem> = haxe.CallStack.exceptionStack(true);

    errorMessage += '${error.error}\n';

    for (stackItem in callStack)
    {
      switch (stackItem)
      {
        case FilePos(innerStackItem, file, line, column):
          errorMessage += '  in ${file}#${line}';
          if (column != null) errorMessage += ':${column}';
        case CFunction:
          errorMessage += '[Function] ';
        case Module(m):
          errorMessage += '[Module(${m})] ';
        case Method(classname, method):
          errorMessage += '[Function(${classname}.${method})] ';
        case LocalFunction(v):
          errorMessage += '[LocalFunction(${v})] ';
      }
      errorMessage += '\n';
    }

    return errorMessage;
  }

  public static function queryStatus():Void
  {
    @:privateAccess
    var currentStatus = Lib.current.stage.__uncaughtErrorEvents.__enabled;
    trace('ERROR HANDLER STATUS: ' + currentStatus);

    #if openfl_enable_handle_error
    trace('Define: openfl_enable_handle_error is enabled');
    #else
    trace('Define: openfl_enable_handle_error is disabled');
    #end

    #if openfl_disable_handle_error
    trace('Define: openfl_disable_handle_error is enabled');
    #else
    trace('Define: openfl_disable_handle_error is disabled');
    #end
  }

  public static function induceBasicCrash():Void
  {
    throw "This is an example of an uncaught exception.";
  }

  public static function induceNullObjectReference():Void
  {
    var obj:Dynamic = null;
    var value = obj.test;
  }

  public static function induceNullObjectReference2():Void
  {
    var obj:Dynamic = null;
    var value = obj.test();
  }

  public static function induceNullObjectReference3():Void
  {
    var obj:Dynamic = null;
    var value = obj();
  }

  static function renderMethod():String
  {
    var outputStr:String = 'UNKNOWN';
    outputStr = try
    {
      switch (FlxG.renderMethod)
      {
        case FlxRenderMethod.DRAW_TILES: 'DRAW_TILES';
        case FlxRenderMethod.BLITTING: 'BLITTING';
        default: 'UNKNOWN';
      }
    }
    catch (e)
    {
      'ERROR ON QUERY RENDER METHOD: ${e}';
    }

    return outputStr;
  }
}
