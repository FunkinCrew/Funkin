package openfl.utils;

import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
#if lime
import lime.utils.Assets as LimeAssets;
#end

/**
	The AssetCache class is the default cache implementation used
	by openfl.utils.Assets, objects will be cached for the lifetime
	of the application unless removed explicitly, or using Assets
	`unloadLibrary`
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class AssetCache implements IAssetCache
{
	/**
		Whether caching is currently enabled.
	**/
	public var enabled(get, set):Bool;

	/**
		Internal
	**/
	@:noCompletion @:dox(hide) public var bitmapData:Map<String, BitmapData>;

	/**
		Internal
	**/
	@:noCompletion @:dox(hide) public var font:Map<String, Font>;

	/**
		Internal
	**/
	@:noCompletion @:dox(hide) public var sound:Map<String, Sound>;

	@:noCompletion private var __enabled:Bool = true;

	#if openfljs
	@:noCompletion private static function __init__()
	{
		untyped global.Object.defineProperty(AssetCache.prototype, "enabled", {
			get: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function () { return this.get_enabled (); }"),
			set: untyped #if haxe4 js.Syntax.code #else __js__ #end ("function (v) { return this.set_enabled (v); }")
		});
	}
	#end

	/**
		Creates a new AssetCache instance.
	**/
	public function new()
	{
		bitmapData = new Map<String, BitmapData>();
		font = new Map<String, Font>();
		sound = new Map<String, Sound>();
	}

	/**
		Clears all cached assets, or all assets with an ID that
		matches an optional prefix.

		For example:

		```haxe
		Assets.setBitmapData("image1", image1);
		Assets.setBitmapData("assets/image2", image2);

		Assets.clear("assets"); // will clear image2
		Assets.clear("image"); // will clear image1
		```

		@param	prefix	A ID prefix
	**/
	public function clear(prefix:String = null):Void
	{
		clearBitmapData(prefix);
		clearFonts(prefix);
		clearSounds(prefix);
	}

	/**
		Clears all cached Bitmap assets, or all assets with an ID that
		matches an optional prefix.

		@param	prefix	A ID prefix
	**/
	public function clearBitmapData(prefix:String = null):Void
	{
		if (prefix == null)
		{
			bitmapData = new Map<String, BitmapData>();
		}
		else
		{
			for (key in getBitmapKeys(prefix))
			{
				removeBitmapData(key);
			}
		}
	}

	/**
		Clears all cached Font assets, or all assets with an ID that
		matches an optional prefix.

		@param	prefix	A ID prefix
	**/
	public function clearFonts(prefix:String = null):Void
	{
		if (prefix == null)
		{
			font = new Map<String, Font>();
		}
		else
		{
			for (key in getFontKeys(prefix))
			{
				removeFont(key);
			}
		}
	}

	/**
		Clears all cached Sound assets, or all assets with an ID that
		matches an optional prefix.

		@param	prefix	A ID prefix
	**/
	public function clearSounds(prefix:String = null):Void
	{
		if (prefix == null)
		{
			sound = new Map<String, Sound>();
		}
		else
		{
			for (key in getSoundKeys(prefix))
			{
				removeSound(key);
			}
		}
	}

	/**
		Returns the IDs of all assets with an ID that
		matches an optional prefix.

		For example:

		```haxe
		Assets.setBitmapData("image1", image1);
		Assets.setBitmapData("assets/image2", image2);

		Assets.getKeys("assets"); // will return ["assets/image2"]
		Assets.getKeys("image"); // will return ["image1"]
		```

		@param	prefix	A ID prefix
	**/
	public function getKeys(prefix:String = null):Array<String>
	{
		var result:Array<String> = [];

		result = result.concat(getBitmapKeys(prefix));
		result = result.concat(getFontKeys(prefix));
		result = result.concat(getSoundKeys(prefix));

		return result;
	}

	/**
		Returns the IDs of all BitmapData assets with an ID that
		matches an optional prefix.

		@param	prefix	A ID prefix
	**/
	public function getBitmapKeys(prefix:String = null):Array<String>
	{
		var result:Array<String> = [];
		if (prefix == null)
		{
			for (key in bitmapData.keys())
			{
				result.push(key);
			}
		}
		else
		{
			for (key in bitmapData.keys())
			{
				if (StringTools.startsWith(key, prefix))
				{
					result.push(key);
				}
			}
		}
		return result;
	}

	/**
		Returns the IDs of all Font assets with an ID that
		matches an optional prefix.

		@param	prefix	A ID prefix
	**/
	public function getFontKeys(prefix:String = null):Array<String>
	{
		var result:Array<String> = [];
		if (prefix == null)
		{
			for (key in font.keys())
			{
				result.push(key);
			}
		}
		else
		{
			for (key in font.keys())
			{
				if (StringTools.startsWith(key, prefix))
				{
					result.push(key);
				}
			}
		}
		return result;
	}

	/**
		Returns the IDs of all Sound assets with an ID that
		matches an optional prefix.

		@param	prefix	A ID prefix
	**/
	public function getSoundKeys(prefix:String = null):Array<String>
	{
		var result:Array<String> = [];
		if (prefix == null)
		{
			for (key in sound.keys())
			{
				result.push(key);
			}
		}
		else
		{
			for (key in sound.keys())
			{
				if (StringTools.startsWith(key, prefix))
				{
					result.push(key);
				}
			}
		}
		return result;
	}

	/**
		Retrieves a cached BitmapData.

		@param	id	The ID of the cached BitmapData
		@return	The cached BitmapData instance
	**/
	public function getBitmapData(id:String):BitmapData
	{
		return bitmapData.get(id);
	}

	/**
		Retrieves a cached Font.

		@param	id	The ID of the cached Font
		@return	The cached Font instance
	**/
	public function getFont(id:String):Font
	{
		return font.get(id);
	}

	/**
		Retrieves a cached Sound.

		@param	id	The ID of the cached Sound
		@return	The cached Sound instance
	**/
	public function getSound(id:String):Sound
	{
		return sound.get(id);
	}

	/**
		Checks whether a BitmapData asset is cached.

		@param	id	The ID of a BitmapData asset
		@return	Whether the object has been cached
	**/
	public function hasBitmapData(id:String):Bool
	{
		return bitmapData.exists(id);
	}

	/**
		Checks whether a Font asset is cached.

		@param	id	The ID of a Font asset
		@return	Whether the object has been cached
	**/
	public function hasFont(id:String):Bool
	{
		return font.exists(id);
	}

	/**
		Checks whether a Sound asset is cached.

		@param	id	The ID of a Sound asset
		@return	Whether the object has been cached
	**/
	public function hasSound(id:String):Bool
	{
		return sound.exists(id);
	}

	/**
		Removes a BitmapData from the cache.

		@param	id	The ID of a BitmapData asset
		@return	`true` if the asset was removed, `false` if it was not in the cache
	**/
	public function removeBitmapData(id:String):Bool
	{
		#if lime
		LimeAssets.cache.image.remove(id);
		#end
		return bitmapData.remove(id);
	}

	/**
		Removes a Font from the cache.

		@param	id	The ID of a Font asset
		@return	`true` if the asset was removed, `false` if it was not in the cache
	**/
	public function removeFont(id:String):Bool
	{
		#if lime
		LimeAssets.cache.font.remove(id);
		#end
		return font.remove(id);
	}

	/**
		Removes a Sound from the cache.

		@param	id	The ID of a Sound asset
		@return	`true` if the asset was removed, `false` if it was not in the cache
	**/
	public function removeSound(id:String):Bool
	{
		#if lime
		LimeAssets.cache.audio.remove(id);
		#end
		return sound.remove(id);
	}

	/**
		Adds or replaces a BitmapData asset in the cache.

		@param	id	The ID of a BitmapData asset
		@param	bitmapData	The matching BitmapData instance
	**/
	public function setBitmapData(id:String, bitmapData:BitmapData):Void
	{
		this.bitmapData.set(id, bitmapData);
	}

	/**
		Adds or replaces a Font asset in the cache.

		@param	id	The ID of a Font asset
		@param	bitmapData	The matching Font instance
	**/
	public function setFont(id:String, font:Font):Void
	{
		this.font.set(id, font);
	}

	/**
		Adds or replaces a Sound asset in the cache.

		@param	id	The ID of a Sound asset
		@param	bitmapData	The matching Sound instance
	**/
	public function setSound(id:String, sound:Sound):Void
	{
		this.sound.set(id, sound);
	}

	// Get & Set Methods
	@:noCompletion private function get_enabled():Bool
	{
		return __enabled;
	}

	@:noCompletion private function set_enabled(value:Bool):Bool
	{
		return __enabled = value;
	}
}