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

  public static function installNativeHandler():Void
  {
    #if FEATURE_NATIVE_CRASH_HANDLER
    funkin.external.crash.NativeCrash.install(LOG_FOLDER, 'Funkin');
    #end
  }

  /**
   * Set something to be shown inside of the crash log
   * @param info The something that is shown
   */
  public static function setContext(info:String):Void
  {
    #if FEATURE_NATIVE_CRASH_HANDLER
    funkin.external.crash.NativeCrash.setContext(info);
    #end
  }

  /**
   * The stack of an error that was caught and rethrown elsewhere.
   */
  public static var pendingStack:Null<Array<haxe.CallStack.StackItem>> = null;

  /**
   * Initializes
   */
  public static function initialize():Void
  {
    // In case it was not installed earlier in startup.
    installNativeHandler();

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
    trace('[CRASH] Uncaught error: ' + generateErrorMessage(error));

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

    exitAfterCrash();
  }

  static function onCriticalError(message:String):Void
  {
    trace('[CRASH] Critical error: ' + message);

    try
    {
      trace(buildCrashReport(message));

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

    exitAfterCrash();
  }
  static function exitAfterCrash():Void
  {
    #if sys
    Sys.sleep(1);

    try
    {
      var window:Null<lime.ui.Window> = openfl.Lib.application?.window;
      if (window != null) window.close();
    }
    catch (e:Dynamic)
    {
      trace('Error while closing the window: $e');
    }

    Sys.exit(1);
    #end
  }

  static function displayError(error:UncaughtErrorEvent):Void
  {
    displayErrorMessage(generateErrorMessage(error));
  }

  static function displayErrorMessage(message:String):Void
  {
    funkin.util.WindowUtil.showError("Fatal Uncaught Exception", message);
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
    if (FlxG.game != null && FlxG.state != null)
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
    fullContents += ' Git hash: ${Constants.GIT_HASH} (${Constants.GIT_HAS_LOCAL_CHANGES ? 'MODIFIED' : 'CLEAN'})\n';
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
    var callStack:Array<haxe.CallStack.StackItem> = pendingStack ?? haxe.CallStack.exceptionStack(true);
    pendingStack = null;

    errorMessage += '${error.error}\n';

    for (stackItem in callStack)
    {
      switch (stackItem)
      {
        case FilePos(innerStackItem, file, line, column):
          errorMessage += ' in ${file}#${line}';
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
    // switch/case resulted in a Null Object Reference when called before Flixel initialized.
    var outputStr:String = 'UNKNOWN';
    if (FlxG.renderMethod == FlxRenderMethod.DRAW_TILES) outputStr = 'DRAW_TILES';
    if (FlxG.renderMethod == FlxRenderMethod.BLITTING) outputStr = 'BLITTING';
    return outputStr;
  }
}
