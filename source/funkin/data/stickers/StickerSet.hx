package funkin.data.stickers;

import funkin.data.stickers.StickerData;
import funkin.data.stickers.StickerRegistry;
import funkin.data.IRegistryEntry;
import funkin.graphics.FunkinSprite;

/**
 * A class representing the data for a sticker set as displayed in the Sticker SubState.
 */
class StickerSet implements IRegistryEntry<StickerData>
{
  /**
   * The internal ID for this sticker set.
   */
  public final id:String;

  /**
   * The full data for this sticker set.
   */
  public final _data:StickerData;

  public function new(id:String)
  {
    this.id = id;
    this._data = _fetchData(id);

    if (_data == null)
    {
      throw 'Could not parse sticker set data for id: $id';
    }
  }

  /**
   * Return the name of the sticker set.
   * @return The name of the sticker set
   */
  public function getStickerSetName():String
  {
    return _data.name;
  }

  /**
   * Return the artist of the sticker set.
   * @return The list of artists
   */
  public function getStickerSetArtist():String
  {
    return _data.artist;
  }

  /**
   * Get the asset key for the album art.
   * @return The asset key
   */
  public function getStickerSetAssetKey():String
  {
    return _data.assetPath;
  }

  /**
   * Gets the stickers for a given sticker name.
   * @param stickerName The name of the sticker to get.
   * @return The sticker.
   */
  public function getStickers(stickerName:String):Array<String>
  {
    return _data.stickers[stickerName];
  }

  /**
   * Gets the sticker pack for a given pack name.
   * @param packName The name of the pack to get.
   * @return The sticker pack.
   */
  public function getPack(packName:String):Array<String>
  {
    return _data.stickerPacks[packName];
  }

  public function toString():String
  {
    return 'StickerSet($id)';
  }

  public function destroy():Void {}

  static function _fetchData(id:String):Null<StickerData>
  {
    return StickerRegistry.instance.parseEntryDataWithMigration(id, StickerRegistry.instance.fetchEntryVersion(id));
  }
}

class StickerSprite extends FunkinSprite
{
  public var timing:Float = 0;

  public function new(x:Float, y:Float, filePath:String):Void
  {
    super(x, y);
    if (!Assets.exists(Paths.image(filePath)))
    {
      throw 'File path does not exist! ($filePath)';
    }
    loadTexture(filePath);
    updateHitbox();
    scrollFactor.set();
  }
}
