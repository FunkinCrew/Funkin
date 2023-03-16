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
	public var SONG = "SONG";
	public var MUSIC = "MUSIC";
	public var SOUND = "SOUND";
	public var SCRIPT = "SCRIPT";
	public var SHADER = "SHADER";
	public var WEEK = "WEEK";
	public var IMAGE = "IMAGE";
	public var VIDEO = "VIDEO";
	public var STAGE = "STAGE";
	public var CHARACTER = "CHARACTERS";
	public var MOVIE_CLIP = "MOVIE_CLIP";
	public var TEXT = "TEXT";
}
