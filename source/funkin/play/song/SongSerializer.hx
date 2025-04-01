package funkin.play.song;

import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.util.SerializerUtil;
import funkin.util.FileUtil;
import lime.utils.Bytes;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

/**
 * TODO: Refactor and remove this.
 */
class SongSerializer
{
  /**
   * Access a SongChartData JSON file from a specific path, then load it.
   * @param	path The file path to read from.
   */
  public static function importSongChartDataSync(path:String):SongChartData
  {
    var fileData = FileUtil.readStringFromPath(path);

    if (fileData == null) return null;

    var songChartData:SongChartData = fileData.parseJSON();

    return songChartData;
  }

  /**
   * Access a SongMetadata JSON file from a specific path, then load it.
   * @param	path The file path to read from.
   */
  public static function importSongMetadataSync(path:String):SongMetadata
  {
    var fileData = FileUtil.readStringFromPath(path);

    if (fileData == null) return null;

    var songMetadata:SongMetadata = fileData.parseJSON();

    return songMetadata;
  }

  /**
   * Prompt the user to browse for a SongChartData JSON file path, then load it.
   * @param	callback The function to call when the file is loaded.
   */
  public static function importSongChartDataAsync(callback:SongChartData->Void):Void
  {
    FileUtil.browseFileReference(function(fileReference:FileReference) {
      var data = fileReference.data.toString();

      if (data == null) return;

      var songChartData:SongChartData = data.parseJSON();

      if (songChartData != null) callback(songChartData);
    });
  }

  /**
   * Prompt the user to browse for a SongMetadata JSON file path, then load it.
   * @param	callback The function to call when the file is loaded.
   */
  public static function importSongMetadataAsync(callback:SongMetadata->Void):Void
  {
    FileUtil.browseFileReference(function(fileReference:FileReference) {
      var data = fileReference.data.toString();

      if (data == null) return;

      var songMetadata:SongMetadata = data.parseJSON();

      if (songMetadata != null) callback(songMetadata);
    });
  }
}
