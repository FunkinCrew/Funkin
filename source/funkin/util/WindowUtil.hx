package funkin.util;

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
		trace('Cannot open')
		#end
	}
}
