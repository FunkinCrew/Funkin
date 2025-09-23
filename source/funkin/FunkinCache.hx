package funkin;

import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.text.Font;
import openfl.utils.AssetCache;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;

class FunkinCache extends AssetCache
{
  public static var instance:FunkinCache;

  /**
   * Second Cache are for assets that are were used last state and needs to be remove from cache
   * They are only removed when the state finished loading to actually destroy them if they aren't used
   * But are recovered from the second layer cache if they are used
   */
  @:noCompletion var _secondBitmaps:Map<String, BitmapData>;

  @:noCompletion var _secondFonts:Map<String, Font>;
  @:noCompletion var _secondSounds:Map<String, Sound>;

  public function new()
  {
    super();
    instance = this;
    // Initializes the maps
    _secondBitmaps = new Map<String, BitmapData>();
    _secondFonts = new Map<String, Font>();
    _secondSounds = new Map<String, Sound>();
  }

  public function sendToSecondLayer():Void
  {
    _secondBitmaps = bitmapData.copy();
    bitmapData.clear();

    _secondFonts = font.copy();
    font.clear();

    _secondSounds = sound.copy();
    sound.clear();
  }

  public function clearSecondLayer():Void
  {
    for (key => _ in _secondBitmaps)
    {
      FlxG.bitmap.removeByKey(key);
      LimeAssets.cache.image.remove(key);
    }
    for (key => _ in _secondFonts)
    {
      LimeAssets.cache.font.remove(key);
    }
    for (key => _ in _secondSounds)
    {
      LimeAssets.cache.audio.remove(key);
    }

    _secondBitmaps.clear();
    _secondFonts.clear();
    _secondSounds.clear();
  }

  public static function initialize():Void
  {
    Assets.cache = new FunkinCache();

    FlxG.signals.preStateSwitch.add(function() {
      instance.sendToSecondLayer();
    });

    FlxG.signals.postStateSwitch.add(function() {
      instance.clearSecondLayer();
    });
  }

  /**
    Retrieves a cached BitmapData.

    @param	id	The ID of the cached BitmapData
    @return	The cached BitmapData instance
  **/
  override public function getBitmapData(id:String):BitmapData
  {
    var mainCacheBitmap = bitmapData.get(id);
    if (mainCacheBitmap != null) return mainCacheBitmap;

    var secondLayerBitmap = _secondBitmaps.get(id);
    if (secondLayerBitmap != null)
    {
      _secondBitmaps.remove(id);
      bitmapData.set(id, secondLayerBitmap);
      return secondLayerBitmap;
    }
    return null;
  }

  /**
    Retrieves a cached Font.

    @param	id	The ID of the cached Font
    @return	The cached Font instance
  **/
  override public function getFont(id:String):Font
  {
    var mainCacheFont = font.get(id);
    if (mainCacheFont != null) return mainCacheFont;

    var secondLayerFont = _secondFonts.get(id);
    if (secondLayerFont != null)
    {
      _secondFonts.remove(id);
      font.set(id, secondLayerFont);
      return secondLayerFont;
    }
    return null;
  }

  /**
    Retrieves a cached Sound.

    @param	id	The ID of the cached Sound
    @return	The cached Sound instance
  **/
  override public function getSound(id:String):Sound
  {
    var mainCacheSound = sound.get(id);
    if (mainCacheSound != null) return mainCacheSound;

    var secondLayerSound = _secondSounds.get(id);
    if (secondLayerSound != null)
    {
      _secondSounds.remove(id);
      sound.set(id, secondLayerSound);
      return secondLayerSound;
    }
    return null;
  }

  /**
    Checks whether a BitmapData asset is cached.

    @param	id	The ID of a BitmapData asset
    @return	Whether the object has been cached
  **/
  override public function hasBitmapData(id:String):Bool
  {
    return bitmapData.exists(id) || _secondBitmaps.exists(id);
  }

  /**
    Checks whether a Font asset is cached.

    @param	id	The ID of a Font asset
    @return	Whether the object has been cached
  **/
  override public function hasFont(id:String):Bool
  {
    return font.exists(id) || _secondFonts.exists(id);
  }

  /**
    Checks whether a Sound asset is cached.

    @param	id	The ID of a Sound asset
    @return	Whether the object has been cached
  **/
  override public function hasSound(id:String):Bool
  {
    return sound.exists(id) || _secondSounds.exists(id);
  }

  /**
    Removes a BitmapData from the cache.

    @param	id	The ID of a BitmapData asset
    @return	`true` if the asset was removed, `false` if it was not in the cache
  **/
  override public function removeBitmapData(id:String):Bool
  {
    #if lime
    LimeAssets.cache.image.remove(id);
    #end
    if (bitmapData.exists(id)) return bitmapData.remove(id);
    if (_secondBitmaps.exists(id)) return _secondBitmaps.remove(id);
    return false;
  }

  /**
    Removes a Font from the cache.

    @param	id	The ID of a Font asset
    @return	`true` if the asset was removed, `false` if it was not in the cache
  **/
  override public function removeFont(id:String):Bool
  {
    #if lime
    LimeAssets.cache.font.remove(id);
    #end
    if (font.exists(id)) return font.remove(id);
    if (_secondFonts.exists(id)) return _secondFonts.remove(id);
    return false;
  }

  /**
    Removes a Sound from the cache.

    @param	id	The ID of a Sound asset
    @return	`true` if the asset was removed, `false` if it was not in the cache
  **/
  override public function removeSound(id:String):Bool
  {
    #if lime
    LimeAssets.cache.audio.remove(id);
    #end
    if (sound.exists(id)) return sound.remove(id);
    if (_secondSounds.exists(id)) return _secondSounds.remove(id);
    return false;
  }
}
