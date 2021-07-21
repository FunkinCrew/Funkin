package;

import openfl.utils.Assets;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

	static var currentLevel:String;

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	static function getPath(file:String, type:AssetType, library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath = getLibraryPathForce(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, ?library:String, type:AssetType = TEXT)
	{
		return getPath(file, type, library);
	}

	inline static public function lua(key:String,?library:String)
	{
		return getPath('data/$key.lua', TEXT, library);
	}

	inline static public function luaImage(key:String, ?library:String)
	{
		return getPath('data/$key.png', IMAGE, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String)
	{
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String)
	{
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	inline static public function voices(song:String)
	{
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase();
			switch (songLowercase) {
				case 'dad-battle': songLowercase = 'dadbattle';
				case 'philly-nice': songLowercase = 'philly';
			}
		return 'songs:assets/songs/${songLowercase}/Voices.$SOUND_EXT';
	}

	inline static public function inst(song:String)
	{
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase();
			switch (songLowercase) {
				case 'dad-battle': songLowercase = 'dadbattle';
				case 'philly-nice': songLowercase = 'philly';
			}
		return 'songs:assets/songs/${songLowercase}/Inst.$SOUND_EXT';
	}

	inline static public function image(key:String, ?library:String)
	{
		return getPath('images/$key.png', IMAGE, library);
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	inline static public function getSparrowAtlas(key:String, ?library:String, ?isCharacter:Bool = false)
	{
		var usecahce = FlxG.save.data.cacheImages;
		#if !cpp
		usecahce = false;
		#end
		if (isCharacter)
			if (usecahce)
				#if cpp
				return FlxAtlasFrames.fromSparrow(imageCached(key), file('images/characters/$key.xml', library));
				#else
				return null;
				#end
			else
				return FlxAtlasFrames.fromSparrow(image('characters/$key', library), file('images/characters/$key.xml', library));
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}

	#if cpp
	inline static public function imageCached(key:String):FlxGraphic
	{
		var data = Caching.bitmapData.get(key);
		trace('finding ${key} - ${data.bitmap}');
		return data;
	}
	#end
	
	inline static public function getPackerAtlas(key:String, ?library:String, ?isCharacter:Bool = false)
	{
		var usecahce = FlxG.save.data.cacheImages;
		#if !cpp
		usecahce = false;
		#end
		if (isCharacter)
			if (usecahce)
				#if cpp
				return FlxAtlasFrames.fromSpriteSheetPacker(imageCached(key), file('images/$key.txt', library));
				#else
				return null;
				#end
			else
				return FlxAtlasFrames.fromSpriteSheetPacker(image('characters/$key'), file('images/characters/$key.txt', library));
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}
}
