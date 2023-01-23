package funkin.play.song;

import funkin.play.song.SongData.SongChartData;
import funkin.play.song.SongData.SongMetadata;
import funkin.util.SerializerUtil;
import lime.utils.Bytes;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

/**
 * Utilities for exporting a chart to a JSON file.
 * Primarily used for the chart editor.
 */
class SongSerializer
{
  /**
   * Access a SongChartData JSON file from a specific path, then load it.
   * @param	path The file path to read from.
   */
  public static function importSongChartDataSync(path:String):SongChartData
  {
    var fileData = readFile(path);

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
    var fileData = readFile(path);

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
    browseFileReference(function(fileReference:FileReference)
    {
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
    browseFileReference(function(fileReference:FileReference)
    {
      var data = fileReference.data.toString();

      if (data == null) return;

      var songMetadata:SongMetadata = data.parseJSON();

      if (songMetadata != null) callback(songMetadata);
    });
  }

  /**
   * Save a SongChartData object as a JSON file to an automatically generated path.
   * Works great on HTML5 and desktop.
   */
  public static function exportSongChartData(data:SongChartData)
  {
    var path = 'chart.json';
    exportSongChartDataAs(path, data);
  }

  /**
   * Save a SongMetadata object as a JSON file to an automatically generated path.
   * Works great on HTML5 and desktop.
   */
  public static function exportSongMetadata(data:SongMetadata)
  {
    var path = 'metadata.json';
    exportSongMetadataAs(path, data);
  }

  /**
   * Save a SongChartData object as a JSON file to a specified path.
   * Works great on HTML5 and desktop.
   * 
   * @param	path The file path to save to.
   */
  public static function exportSongChartDataAs(path:String, data:SongChartData)
  {
    var dataString = SerializerUtil.toJSON(data);

    writeFileReference(path, dataString);
  }

  /**
   * Save a SongMetadata object as a JSON file to a specified path.
   * Works great on HTML5 and desktop.
   * 
   * @param	path The file path to save to.
   */
  public static function exportSongMetadataAs(path:String, data:SongMetadata)
  {
    var dataString = SerializerUtil.toJSON(data);

    writeFileReference(path, dataString);
  }

  /**
   * Read the string contents of a file.
   * Only works on desktop platforms.
   * @param	path The file path to read from.
   */
  static function readFile(path:String):String
  {
    #if sys
    var fileBytes:Bytes = sys.io.File.getBytes(path);

    if (fileBytes == null) return null;

    return fileBytes.toString();
    #end

    trace('ERROR: readFile not implemented for this platform');
    return null;
  }

  /**
   * Write string contents to a file.
   * Only works on desktop platforms.
   * @param	path The file path to read from.
   */
  static function writeFile(path:String, data:String):Void
  {
    #if sys
    sys.io.File.saveContent(path, data);
    return;
    #end
    trace('ERROR: writeFile not implemented for this platform');
    return;
  }

  /**
   * Browse for a file to read and execute a callback once we have a file reference.
   * Works great on HTML5 or desktop.
   * 
   * @param	callback The function to call when the file is loaded.
   */
  static function browseFileReference(callback:FileReference->Void)
  {
    var file = new FileReference();

    file.addEventListener(Event.SELECT, function(e)
    {
      var selectedFileRef:FileReference = e.target;
      trace('Selected file: ' + selectedFileRef.name);
      selectedFileRef.addEventListener(Event.COMPLETE, function(e)
      {
        var loadedFileRef:FileReference = e.target;
        trace('Loaded file: ' + loadedFileRef.name);
        callback(loadedFileRef);
      });
      selectedFileRef.load();
    });

    file.browse();
  }

  /**
   * Prompts the user to save a file to their computer.
   */
  static function writeFileReference(path:String, data:String)
  {
    var file = new FileReference();
    file.addEventListener(Event.COMPLETE, function(e:Event)
    {
      trace('Successfully wrote file.');
    });
    file.addEventListener(Event.CANCEL, function(e:Event)
    {
      trace('Cancelled writing file.');
    });
    file.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent)
    {
      trace('IO error writing file.');
    });
    file.save(data, path);
  }
}
