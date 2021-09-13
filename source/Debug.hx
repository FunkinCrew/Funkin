import haxe.PosInfos;
import haxe.Log;
import flixel.system.debug.log.LogStyle;
import flixel.FlxG;

/**
 * Utility functions related to debugging and logging.
 * Developers, use these methods to the fullest to produce mods efficiently!
 */
class Debug
{
	static final LOG_STYLE_ERROR:LogStyle = new LogStyle('[ERROR] ', 'FF8888', 12, true, false, false, 'flixel/sounds/beep', true);
	static final LOG_STYLE_WARN:LogStyle = new LogStyle('[WARN ] ', 'D9F85C', 12, true, false, false, 'flixel/sounds/beep', true);
	static final LOG_STYLE_INFO:LogStyle = new LogStyle('[INFO ] ', '5CF878', 12, false);
	static final LOG_STYLE_TRACE:LogStyle = new LogStyle('[TRACE] ', '5CF878', 12, false);

	/**
	 * Log an warning message to the game's console.
	 * Plays a beep to the user and forces the console open.
	 * @param input The message to display.
	    * @param pos This magic type is auto-populated, and includes the line number and class it was called from.
	 */
	public static function logWarn(input:Dynamic, ?pos:haxe.PosInfos):Void
	{
		var output = formatOutput(input, pos);
		FlxG.log.advanced(output, LogStyle.WARNING);
		performTrace(output, 'WARN ', pos);
	}

	/**
	 * Log an error message to the game's console.
	 * Plays a beep to the user and forces the console open.
	 * @param input The message to display.
	    * @param pos This magic type is auto-populated, and includes the line number and class it was called from.
	 */
	public static function logError(input:Dynamic, ?pos:haxe.PosInfos):Void
	{
		var output = formatOutput(input, pos);
		FlxG.log.advanced(output, LogStyle.ERROR);
		performTrace(output, 'ERROR', pos);
	}

	/**
	 * Log an info message to the game's console.
	 * @param input The message to display.
	    * @param pos This magic type is auto-populated, and includes the line number and class it was called from.
	 */
	public static function logInfo(input:Dynamic, ?pos:haxe.PosInfos):Void
	{
		var output = formatOutput(input, pos);
		FlxG.log.advanced(output, LogStyle.CONSOLE);
		performTrace(output, 'INFO ', pos);
	}

	/**
	 * Log a debug message to the game's console.
	    * NOTE: We redirect all `trace()` calls to this function.
	 * @param input The message to display.
	    * @param pos This magic type is auto-populated, and includes the line number and class it was called from.
	 */
	public static function logTrace(input:Dynamic, ?pos:haxe.PosInfos):Void
	{
		var output = formatOutput(input, pos);
		FlxG.log.advanced(output, LOG_STYLE_TRACE);
		performTrace(output, 'TRACE', pos);
	}

	/**
	 * Calls the Haxe built-in trace function.
	 */
	static function performTrace(input:Dynamic, logLevel = 'TRACE'):Void
	{
		// Pass null to exclude the position..
		haxe.Log.trace('[$logLevel] $input', null);
	}

	static function formatOutput(input:Dynamic, ?pos:haxe.PosInfos)
	{
		// Format the position ourselves.
		return '(${pos.className}/${pos.methodName}#${pos.lineNumber}) : $input';
	}

	/**
	 * This function replaces the trace() function to the Flixel console.
	 * @param data 
	 * @param info 
	 */
	static function handleTrace(data:Dynamic, ?info:PosInfos):Void
	{
		var paramArray:Array<Dynamic> = [data];

		if (info.customParams != null)
		{
			for (i in info.customParams)
			{
				paramArray.push(i);
			}
		}

		logTrace(paramArray);
	}

	/**
	 * The game runs this function when it starts. Use it to initialize debug stuff.
	 */
	public static function onGameStart()
	{
		// Override trace() calls to use the Flixel console.
		Log.trace = handleTrace;

		// Add the mouse position to the debug Watch window.
		FlxG.watch.addMouse();
	}

	/**
	 * Continously display the value of a particular field of a given object
	 * in the Debug watch window, labelled with the specified name.
	 * @param object The object to watch.
	 * @param field The string name of a field of the above object.
	 * @param name
	 */
	public static function watchVariable(object:Dynamic, field:String, name):Void
	{
		#if debug
		if (name == null)
		{
			// Default to naming after the field.
			name = field;
		}
		FlxG.watch.add(object, field, name);
		#end
		// Else, do nothing outside of debug mode.
	}
}
