package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.media.Sound;
import openfl.utils.Assets;

using StringTools;

class Paths
{
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static var localTrackedAssets:Array<String> = [];

	public static function clearUnusedMemory()
	{
		for (key in currentTrackedAssets.keys())
		{
			if (!localTrackedAssets.contains(key) && key != null)
			{
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null)
				{
					Assets.cache.removeBitmapData(key);
					Assets.cache.clearBitmapData(key);
					Assets.cache.clear(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}

		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && key != null)
			{
				var obj = currentTrackedSounds.get(key);
				if (obj != null)
				{
					Assets.cache.removeSound(key);
					Assets.cache.clearSounds(key);
					Assets.cache.clear(key);
					currentTrackedSounds.remove(key);
				}
			}
		}
	}

	public static function clearStoredMemory()
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				Assets.cache.removeBitmapData(key);
				Assets.cache.clearBitmapData(key);
				Assets.cache.clear(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		@:privateAccess
		for (key in Assets.cache.getSoundKeys())
		{
			if (key != null && !currentTrackedSounds.exists(key))
			{
				var obj = Assets.cache.getSound(key);
				if (obj != null)
				{
					Assets.cache.removeSound(key);
					Assets.cache.clearSounds(key);
					Assets.cache.clear(key);
				}
			}
		}

		localTrackedAssets = [];
	}

	inline static public function txt(key:String):String
		return 'assets/$key.txt';

	inline static public function xml(key:String):String
		return 'assets/$key.xml';

	inline static public function json(key:String):String
		return 'assets/$key.json';

	inline static public function video(key:String):String
		return 'assets/$key.mp4';

	inline static public function font(key:String):String
		return 'assets/fonts/$key';

	static public function sound(key:String, ?cache:Bool = true):Sound
		return returnSound('sounds/$key', cache);
	
	inline static public function soundRandom(key:String, min:Int, max:Int)
		return sound(key + FlxG.random.int(min, max), library);

	inline static public function music(key:String, ?cache:Bool = true):Sound
		return returnSound('music/$key', cache);

	inline static public function voices(song:String, ?cache:Bool = true):Sound
		return returnSound('songs/' + ${song.toLowerCase()} + '/Voices', cache);

	inline static public function inst(song:String, ?cache:Bool = true):Sound
		return returnSound('songs/' + ${song.toLowerCase()} + '/Inst', cache);

	inline static public function image(key:String, ?cache:Bool = true):FlxGraphic
		return returnGraphic('images/$key', cache);

	inline static public function getSparrowAtlas(key:String, ?cache:Bool = true):FlxAtlasFrames
		return FlxAtlasFrames.fromSparrow(returnGraphic('images/$key', cache), xml('images/$key'));

	inline static public function getPackerAtlas(key:String, ?cache:Bool = true):FlxAtlasFrames
		return FlxAtlasFrames.fromSpriteSheetPacker(returnGraphic('images/$key', cache), txt('images/$key'));

	public static function returnGraphic(key:String, ?cache:Bool = true):FlxGraphic
	{
		var path:String = 'assets/$key.png';
		if (Assets.exists(path, IMAGE))
		{
			if (!currentTrackedAssets.exists(path))
			{
				var graphic:FlxGraphic = FlxGraphic.fromBitmapData(Assets.getBitmapData(path), false, path, cache);
				graphic.persist = true;
				currentTrackedAssets.set(path, graphic);
			}

			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}

		trace('$key its null');
		return null;
	}

	public static function returnSound(key:String, ?cache:Bool = true):Sound
	{
		#if web
		if (Assets.exists('assets/$key.mp3', SOUND))
		{
			var path:String = 'assets/$key.mp3';
			if (!currentTrackedSounds.exists(path))
				currentTrackedSounds.set(path, Assets.getSound(path, cache));

			localTrackedAssets.push(path);
			return currentTrackedSounds.get(path);
		}
		#else
		if (Assets.exists('assets/$key.ogg', SOUND))
		{
			var path:String = 'assets/$key.ogg';
			if (!currentTrackedSounds.exists(path))
				currentTrackedSounds.set(path, Assets.getSound(path, cache));

			localTrackedAssets.push(path);
			return currentTrackedSounds.get(path);
		}
		#end

		trace('$key its null');
		return null;
	}
}
