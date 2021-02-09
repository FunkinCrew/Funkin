package;

import openfl.utils.Assets as OpenFlAssets;
import openfl.utils.AssetType;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	
	static var currentLevel:String;
	
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}
	
	static function getPath(file:String, type:AssetType)
	{
		if (currentLevel != null)
		{
			var levelPath = getLibraryPath(currentLevel, file);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
			
			levelPath = getLibraryPath("shared", file);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}
		
		return 'assets/$file';
	}
	
	inline static function getLibraryPath(library:String, file:String)
	{
		return '$library:assets/$library/$file';
	}
	
	inline static public function file(file:String, type:AssetType = TEXT)
	{
		return getPath(file, type);
	}
	
	inline static public function sound(key:String)
	{
		return getPath('sounds/$key.$SOUND_EXT', SOUND);
	}
	
	inline static public function soundRandom(key:String, min:Int, max:Int)
	{
		return getPath('sounds/$key${FlxG.random.int(min, max)}.$SOUND_EXT', SOUND);
	}
	
	inline static public function music(key:String)
	{
		return getPath('music/$key.$SOUND_EXT', MUSIC);
	}
	
	inline static public function image(key:String)
	{
		return getPath('images/$key.png', IMAGE);
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