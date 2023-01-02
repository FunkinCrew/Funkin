package funkin.util;

import flixel.util.FlxSignal.FlxTypedSignal;

class WindowUtil
{
	public static function openURL(targetUrl:String)
	{
		#if CAN_OPEN_LINKS
		#if linux
		// Sys.command('/usr/bin/xdg-open', [, "&"]);
		Sys.command('/usr/bin/xdg-open', [targetUrl, "&"]);
		#else
		FlxG.openURL(targetUrl);
		#end
		#else
		trace('Cannot open');
		#end
	}

	/**
	 * Dispatched when the game window is closed.
	 */
	public static final windowExit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

	public static function initWindowEvents()
	{
		// onUpdate is called every frame just before rendering.

		// onExit is called when the game window is closed.
		openfl.Lib.current.stage.application.onExit.add(function(exitCode:Int)
		{
			windowExit.dispatch(exitCode);
		});
	}
}
