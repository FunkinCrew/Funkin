package funkin.data.freeplay.album;

import funkin.ui.freeplay.Album;
import funkin.data.freeplay.album.AlbumData;
import funkin.ui.freeplay.ScriptedAlbum;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class AlbumRegistry extends BaseRegistry<Album, AlbumData> implements ISingleton implements DefaultRegistryImpl
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
    super('ALBUM', 'ui/freeplay/albums', ALBUM_DATA_VERSION_RULE);
  }
}
