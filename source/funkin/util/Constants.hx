package funkin.util;

import lime.app.Application;
import flixel.util.FlxColor;

class Constants
{
	/**
	 * The scale factor to use when increasing the size of pixel art graphics.
	 */
	public static final PIXEL_ART_SCALE = 6;

	public static final HEALTH_BAR_RED:FlxColor = 0xFFFF0000;
	public static final HEALTH_BAR_GREEN:FlxColor = 0xFF66FF33;

	public static final COUNTDOWN_VOLUME = 0.6;

	public static final VERSION_SUFFIX = ' PROTOTYPE';
	public static var VERSION(get, null):String;

	#if debug
	public static final GIT_HASH = funkin.util.macro.GitCommit.getGitCommitHash();

	static function get_VERSION():String
	{
		return 'v${Application.current.meta.get('version')} (${GIT_HASH})' + VERSION_SUFFIX;
	}
	#else
	static function get_VERSION():String
	{
		return 'v${Application.current.meta.get('version')}' + VERSION_SUFFIX;
	}
	#end

	public static final URL_KICKSTARTER:String = "https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game/";
	public static final URL_ITCH:String = "https://ninja-muffin24.itch.io/funkin";
}
