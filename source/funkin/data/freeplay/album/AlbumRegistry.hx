package funkin.data.freeplay.album;

import funkin.ui.freeplay.Album;
import funkin.data.freeplay.album.AlbumData;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class AlbumRegistry extends BaseRegistry<Album, AlbumData, AlbumEntryParams> implements DefaultRegistryImpl
{
  static var _instance:Null<AlbumRegistry>;

  public static var instance(get, never):AlbumRegistry;

  static function get_instance():AlbumRegistry
  {
    if (_instance == null)
    {
      _instance = new AlbumRegistry();
    }
    return _instance;
  }

  /**
   * The current version string for the album data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateAlbumData()` function.
   */
  public static final ALBUM_DATA_VERSION:thx.semver.Version = '1.0.3';

  public static final ALBUM_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

  public function new()
  {
    super({
      registryId: 'ALBUM',
      dataFilePath: 'ui/freeplay/albums/',
      nestedEntries: false,
      versionRule: ALBUM_DATA_VERSION_RULE
    });
  }
}

typedef AlbumEntryParams =
{
}
