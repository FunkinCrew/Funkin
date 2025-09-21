package funkin.data.freeplay.album;

import funkin.ui.freeplay.Album;
import funkin.data.freeplay.album.AlbumData;
import funkin.ui.freeplay.ScriptedAlbum;
import funkin.util.tools.ISingleton;

@:nullSafety
class AlbumRegistry extends BaseRegistry<Album, AlbumData, AlbumEntryParams, 'ui/freeplay/albums'> implements ISingleton
{
  /**
   * The current version string for the album data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateAlbumData()` function.
   */
  public static final ALBUM_DATA_VERSION:thx.semver.Version = '1.0.0';

  public static final ALBUM_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

  public function new()
  {
    super('ALBUM', ALBUM_DATA_VERSION_RULE);
  }
}

typedef AlbumEntryParams = {}
