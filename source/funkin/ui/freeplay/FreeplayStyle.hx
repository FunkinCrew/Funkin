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
      throw 'Could not parse album data for id: $id';
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
    return funkin.assets.Paths.formatRelative(_data?.bgAsset ?? "ui/freeplay/backgrounds/bf/week1", 'ui/freeplay/styles/$id', Constants.EXT_IMAGE);
  }

  /**
   * Get the asset key for the difficulty selector.
   * @return The asset key
   */
  public function getSelectorAssetKey():String
  {
    return funkin.assets.Paths.formatRelative(
      _data?.selectorAsset ?? "ui/freeplay/interface/difficulty-selector",
      'ui/freeplay/styles/$id',
      Constants.EXT_IMAGE
    );
  }

  /**
   * Get the asset key for the number assets.
   * @return The asset key
   */
  public function getCapsuleAssetKey():String
  {
    return funkin.assets.Paths.formatRelative(
      _data?.capsuleAsset ?? "ui/freeplay/interface/freeplay-capsule/capsule/capsule-bf",
      'ui/freeplay/styles/$id',
      Constants.EXT_IMAGE
    );
  }

  /**
   * Get the asset key for the capsule art.
   * @return The asset key
   */
  public function getNumbersAssetKey():String
  {
    return funkin.assets.Paths.formatRelative(_data?.numbersAsset ?? "ui/freeplay/styles/bf/digital-numbers", 'ui/freeplay/styles/$id', Constants.EXT_IMAGE);
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
