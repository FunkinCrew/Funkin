package funkin.ui.transition.stickers;

import funkin.data.stickers.StickerData;
import funkin.data.stickers.StickerRegistry;
import funkin.data.IRegistryEntry;
import funkin.graphics.FunkinSprite;

/**
 * A class representing the data for a sticker pack as displayed in the Sticker SubState.
 */
class StickerPack implements IRegistryEntry<StickerData>
{
  /**
   * The internal ID for this sticker pack.
   */
  public final id:String;

  /**
   * The full data for this sticker pack.
   */
  public final _data:StickerData;

  public function new(id:String)
  {
    this.id = id;
    this._data = _fetchData(id);

    if (_data == null)
    {
      throw 'Could not parse sticker pack data for id: $id';
    }
  }

  /**
   * Return the name of the sticker pack.
   * @return The name of the sticker pack
   */
  public function getStickerPackName():String
  {
    return _data.name;
  }

  /**
   * Return the artist of the sticker pack.
   * @return The list of artists
   */
  public function getStickerPackArtist():String
  {
    return _data.artist;
  }

  /**
   * Gets a list of all the sticker assets available in the pack.
   * @return The list of stickers as raw strings.
   */
  public function getStickers():Array<String>
  {
    return _data.stickers;
  }

  /**
   * Retrieve a random sticker from the pack.
   * @param last Whether this will be the last sticker to be placed on the screen.
   * @return An asset path to a sticker to display.
   */
  public function getRandomStickerPath(last:Bool):String
  {
    return FlxG.random.getObject(getStickers());
  }

  public function toString():String
  {
    return 'StickerPack($id)';
  }

  public function destroy():Void {}

  static function _fetchData(id:String):Null<StickerData>
  {
    return StickerRegistry.instance.parseEntryDataWithMigration(id, StickerRegistry.instance.fetchEntryVersion(id));
  }
}
