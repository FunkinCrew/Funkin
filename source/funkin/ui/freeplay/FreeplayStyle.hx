package funkin.ui.freeplay;

import funkin.data.freeplay.style.FreeplayStyleData;
import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.data.IRegistryEntry;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;

/**
 * A class representing the data for a style of the Freeplay menu.
 */
@:nullSafety
class FreeplayStyle implements IRegistryEntry<FreeplayStyleData>
{
  /**
   * The internal ID for this freeplay style.
   */
  // public final id:String;

  /**
   * The full data for a freeplay style.
   */
  // public final _data:FreeplayStyleData;
  public function new(id:String, ?params:Dynamic)
  {
    this.id = id;
    this._data = _fetchData(id);

    if (_data == null)
    {
      throw 'Could not parse freeplay style for id: $id';
    }
  }

  /**
   * Get the background art as a graphic, ready to apply to a sprite.
   * @return The built graphic
   */
  public function getBgAssetGraphic():FlxGraphic
  {
    return FlxG.bitmap.add(Paths.image(getBgAssetKey()));
  }

  /**
   * Get the asset key for the background.
   * @return The asset key
   */
  public function getBgAssetKey():String
  {
    return _data?.bgAsset ?? "ui/freeplay/backgrounds/bf/week1";
  }

  /**
   * Get the asset key for the difficulty selector.
   * @return The asset key
   */
  public function getSelectorAssetKey():String
  {
    return _data?.selectorAsset ?? "ui/freeplay/interface/difficulty-selector";
  }

  /**
   * Get the asset key for the number assets.
   * @return The asset key
   */
  public function getCapsuleAssetKey():String
  {
    return _data?.capsuleAsset ?? "ui/freeplay/interface/freeplay-capsule/capsule/capsule-bf";
  }

  /**
   * Get the asset key for the capsule art.
   * @return The asset key
   */
  public function getNumbersAssetKey():String
  {
    return _data?.numbersAsset ?? "digital_numbers";
  }

  /**
   * Return the deselected color of the text outline
   * for freeplay capsules.
   * @return The deselected color
   */
  public function getCapsuleDeselCol():FlxColor
  {
    return FlxColor.fromString(_data?.capsuleTextColors[0] ?? "#00ccff") ?? 0x00CCFF;
  }

  /**
   * Get the asset key for the freeplay random music.
   * @return The asset key
   */
  public function getFreeplayRandomMusicAssetKey():String
  {
    return _data?.sounds?.freeplayRandomMusic ?? 'ui/freeplay/freeplay-random/freeplay-random';
  }

  /**
   * Get the asset key for the favorite sound.
   * @return The asset key
   */
  public function getFavoriteSoundAssetKey():String
  {
    return _data?.sounds?.favorite ?? 'ui/freeplay/sounds/favorite';
  }

  /**
   * Get the asset key for the unfavorite sound.
   * @return The asset key
   */
  public function getUnfavoriteSoundAssetKey():String
  {
    return _data?.sounds?.unfavorite ?? 'ui/freeplay/sounds/unfavorite';
  }

  /**
   * Get the asset key for the scroll menu sound.
   * @return The asset key
   */
  public function getScrollMenuSoundAssetKey():String
  {
    return _data?.sounds?.menu?.scroll ?? 'ui/main-menu/scroll-menu';
  }

  /**
   * Get the asset key for the cancel menu sound.
   * @return The asset key
   */
  public function getCancelMenuSoundAssetKey():String
  {
    return _data?.sounds?.menu?.cancel ?? 'ui/main-menu/cancel-menu';
  }

  /**
   * Get the asset key for the confirm sound.
   * @return The asset key
   */
  public function getConfirmMenuSoundAssetKey():String
  {
    return _data?.sounds?.menu?.confirm ?? 'ui/main-menu/confirm-menu';
  }

  /**
   * Return the song selection transition delay.
   * @return The start delay
   */
  public function getStartDelay():Float
  {
    return _data?.startDelay ?? 0.0;
  }

  public function toString():String
  {
    return 'Style($id)';
  }

  /**
   * Return the selected color of the text outline
   * for freeplay capsules.
   * @return The selected color
   */
  public function getCapsuleSelCol():FlxColor
  {
    return FlxColor.fromString(_data?.capsuleTextColors[1] ?? "#00ccff") ?? 0x00CCFF;
  }

  public function destroy():Void
  {
  }

  static function _fetchData(id:String):Null<FreeplayStyleData>
  {
    return FreeplayStyleRegistry.instance.parseEntryDataWithMigration(id, FreeplayStyleRegistry.instance.fetchEntryVersion(id));
  }
}
