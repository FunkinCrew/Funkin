package;

import openfl.utils.Assets as OpenFlAssets;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	
	static var currentLevel:String;
	
	static public function file(file:String)
	{
		var path = 'assets/$file';
		if (currentLevel != null && OpenFlAssets.exists('$currentLevel:$path'))
			return '$currentLevel:$path';
		
		return path;
	}
	
	inline static public function sound(key:String)
	{
		return file('sounds/$key.$SOUND_EXT');
	}
	
	inline static public function soundRandom(key:String, min:Int, max:Int)
	{
		return file('sounds/$key${FlxG.random.int(min, max)}.$SOUND_EXT');
	}
	
	inline static public function music(key:String)
	{
		return file('music/$key.$SOUND_EXT');
	}
	
	inline static public function image(key:String)
	{
		return file('images/$key.png');
	}
	
	inline static public function getSparrowAtlas(key:String)
	{
		return FlxAtlasFrames.fromSparrow(image(key), file('images/$key.xml'));
	}
	
	inline static public function getPackerAtlas(key:String)
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key), file('images/$key.txt'));
	}
}