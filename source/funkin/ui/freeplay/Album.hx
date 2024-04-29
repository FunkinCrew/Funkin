package funkin.ui.freeplay;

import funkin.data.freeplay.album.AlbumData;
import funkin.data.freeplay.album.AlbumRegistry;
import funkin.data.animation.AnimationData;
import funkin.data.IRegistryEntry;
import flixel.graphics.FlxGraphic;

/**
 * A class representing the data for an album as displayed in Freeplay.
 */
class Album implements IRegistryEntry<AlbumData>
{
  /**
   * The internal ID for this album.
   */
  public final id:String;

  /**
   * The full data for an album.
   */
  public final _data:AlbumData;

  public function new(id:String)
  {
    this.id = id;
    this._data = _fetchData(id);

    if (_data == null)
    {
      throw 'Could not parse album data for id: $id';
    }
  }

  /**
   * Return the name of the album.
   * @
   */
  public function getAlbumName():String
  {
    return _data.name;
  }

  /**
   * Return the artists of the album.
   * @return The list of artists
   */
  public function getAlbumArtists():Array<String>
  {
    return _data.artists;
  }

  /**
   * Get the asset key for the album art.
   * @return The asset key
   */
  public function getAlbumArtAssetKey():String
  {
    return _data.albumArtAsset;
  }

  /**
   * Get the album art as a graphic, ready to apply to a sprite.
   * @return The built graphic
   */
  public function getAlbumArtGraphic():FlxGraphic
  {
    return FlxG.bitmap.add(Paths.image(getAlbumArtAssetKey()));
  }

  /**
   * Get the asset key for the album title.
   */
  public function getAlbumTitleAssetKey():String
  {
    return _data.albumTitleAsset;
  }

  public function hasAlbumTitleAnimations()
  {
    return _data.albumTitleAnimations.length > 0;
  }

  public function getAlbumTitleAnimations():Array<AnimationData>
  {
    return _data.albumTitleAnimations;
  }

  public function toString():String
  {
    return 'Album($id)';
  }

  public function destroy():Void {}

  static function _fetchData(id:String):Null<AlbumData>
  {
    return AlbumRegistry.instance.parseEntryDataWithMigration(id, AlbumRegistry.instance.fetchEntryVersion(id));
  }
}
