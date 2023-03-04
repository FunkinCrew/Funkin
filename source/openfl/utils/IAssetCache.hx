package openfl.utils;

import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;

/**
	The IAssetCache interface provides methods for caching
	resources loaded from openfl.utils.Assets to improve
	performance.
**/
interface IAssetCache
{
	/**
		Whether caching is currently enabled.
	**/
	public var enabled(get, set):Bool;

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
	public function clear(prefix:String = null):Void;

	/**
		Clears all cached Bitmap assets, or all assets with an ID that
		matches an optional prefix.

		@param	prefix	A ID prefix
	**/
	public function clearBitmapData(prefix:String = null):Void;

	/**
		Clears all cached Font assets, or all assets with an ID that
		matches an optional prefix.

		@param	prefix	A ID prefix
	**/
	public function clearFonts(prefix:String = null):Void;

	/**
		Clears all cached Sound assets, or all assets with an ID that
		matches an optional prefix.

		@param	prefix	A ID prefix
	**/
	public function clearSounds(prefix:String = null):Void;

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
	public function getKeys(prefix:String = null):Array<String>;

	/**
		Returns the IDs of all BitmapData assets with an ID that
		matches an optional prefix.

		@param	prefix	A ID prefix
	**/
	public function getBitmapKeys(prefix:String = null):Array<String>;

	/**
		Returns the IDs of all Font assets with an ID that
		matches an optional prefix.

		@param	prefix	A ID prefix
	**/
	public function getFontKeys(prefix:String = null):Array<String>;

	/**
		Returns the IDs of all Sound assets with an ID that
		matches an optional prefix.

		@param	prefix	A ID prefix
	**/
	public function getSoundKeys(prefix:String = null):Array<String>;

	/**
		Retrieves a cached BitmapData.

		@param	id	The ID of the cached BitmapData
		@return	The cached BitmapData instance
	**/
	public function getBitmapData(id:String):BitmapData;

	/**
		Retrieves a cached Font.

		@param	id	The ID of the cached Font
		@return	The cached Font instance
	**/
	public function getFont(id:String):Font;

	/**
		Retrieves a cached Sound.

		@param	id	The ID of the cached Sound
		@return	The cached Sound instance
	**/
	public function getSound(id:String):Sound;

	/**
		Checks whether a BitmapData asset is cached.

		@param	id	The ID of a BitmapData asset
		@return	Whether the object has been cached
	**/
	public function hasBitmapData(id:String):Bool;

	/**
		Checks whether a Font asset is cached.

		@param	id	The ID of a Font asset
		@return	Whether the object has been cached
	**/
	public function hasFont(id:String):Bool;

	/**
		Checks whether a Sound asset is cached.

		@param	id	The ID of a Sound asset
		@return	Whether the object has been cached
	**/
	public function hasSound(id:String):Bool;

	/**
		Removes a BitmapData from the cache.

		@param	id	The ID of a BitmapData asset
		@return	`true` if the asset was removed, `false` if it was not in the cache
	**/
	public function removeBitmapData(id:String):Bool;

	/**
		Removes a Font from the cache.

		@param	id	The ID of a Font asset
		@return	`true` if the asset was removed, `false` if it was not in the cache
	**/
	public function removeFont(id:String):Bool;

	/**
		Removes a Sound from the cache.

		@param	id	The ID of a Sound asset
		@return	`true` if the asset was removed, `false` if it was not in the cache
	**/
	public function removeSound(id:String):Bool;

	/**
		Adds or replaces a BitmapData asset in the cache.

		@param	id	The ID of a BitmapData asset
		@param	bitmapData	The matching BitmapData instance
	**/
	public function setBitmapData(id:String, bitmapData:BitmapData):Void;

	/**
		Adds or replaces a Font asset in the cache.

		@param	id	The ID of a Font asset
		@param	bitmapData	The matching Font instance
	**/
	public function setFont(id:String, font:Font):Void;

	/**
		Adds or replaces a Sound asset in the cache.

		@param	id	The ID of a Sound asset
		@param	bitmapData	The matching Sound instance
	**/
	public function setSound(id:String, sound:Sound):Void;
}