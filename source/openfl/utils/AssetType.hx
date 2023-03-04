package openfl.utils;

/**
	The AssetType enum lists the core set of available
	asset types from the OpenFL command-line tools.
**/
@:enum abstract AssetType(String)
{
	public var DATA = "DATA";
	public var FONT = "FONT";
	public var SHARED = "SHARED";
	public var SONG = "SONGS";
	public var MUSIC = "MUSIC";
	public var SOUND = "SOUNDS";
	public var SCRIPT = "SCRIPTS";
	public var SHADER = "SHADERS";
	public var WEEK = "WEEKS";
	public var IMAGE = "IMAGES";
	public var VIDEO = "VIDEOS";
	public var MOVIE_CLIP = "MOVIE_CLIP";
	public var TEXT = "TEXT";
}
