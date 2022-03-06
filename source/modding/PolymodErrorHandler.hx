package modding;

import polymod.Polymod;

class PolymodErrorHandler
{
	/**
	 * Show a popup with the given text.
	 * This displays a system popup, it WILL interrupt the game.
	 * Make sure to only use this when it's important, like when there's a script error.
	 * 
	 * @param name The name at the top of the popup.
	 * @param desc The body text of the popup.
	 */
	public static function showAlert(name:String, desc:String):Void
	{
		lime.app.Application.current.window.alert(desc, name);
	}

	public static function onPolymodError(error:PolymodError):Void
	{
		// Perform an action based on the error code.
		switch (error.code)
		{
			case MOD_LOAD_PREPARE:
				logInfo('[POLYMOD]: ${error.message}');
			case MOD_LOAD_DONE:
				logInfo('[POLYMOD]: ${error.message}');
			case MISSING_ICON:
				logWarn('[POLYMOD]: A mod is missing an icon. Please add one.');
			case SCRIPT_PARSE_ERROR:
				// A syntax error when parsing a script.
				logError('[POLYMOD]: ${error.message}');
				showAlert('Polymod Script Parsing Error', error.message);
			case SCRIPT_EXCEPTION:
				// A runtime error when running a script.
				logError('[POLYMOD]: ${error.message}');
				showAlert('Polymod Script Execution Error', error.message);
			case SCRIPT_CLASS_NOT_FOUND:
				// A scripted class tried to reference an unknown superclass.
				logError('[POLYMOD]: ${error.message}');
				showAlert('Polymod Script Parsing Error', error.message);
			default:
				// Log the message based on its severity.
				switch (error.severity)
				{
					case NOTICE:
						logInfo('[POLYMOD]: ${error.message}');
					case WARNING:
						logWarn('[POLYMOD]: ${error.message}');
					case ERROR:
						logError('[POLYMOD]: ${error.message}');
				}
		}
	}

	static function logInfo(message:String):Void
	{
		trace('[INFO ] ${message}');
	}

	static function logError(message:String):Void
	{
		trace('[ERROR] ${message}');
	}

	static function logWarn(message:String):Void
	{
		trace('[WARN ] ${message}');
	}
}
