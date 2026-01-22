package funkin.ui.debug.cameraeditor.handlers;

#if FEATURE_CAMERA_EDITOR
import haxe.io.Bytes;
import haxe.io.Path;
import funkin.util.DateUtil;
import funkin.util.FileUtil;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.importer.ChartManifestData;

/**
 * Handles saving, loading, importing, and exporting for the camera editor.
 */
class CameraEditorImportExportHandler
{
  public static final BACKUPS_PATH:String = './backups/charts/';

  /**
   * Loads an FNFC chart from byte data and returns its parsed contents.
   * @param state The Camera Editor state to apply the loaded data to.
   * @param bytes The byte data for the FNFC file to load.
   * @return `true` if the file was successfully loaded, `false` otherwise.
   */
  public static function loadFNFCFromBytes(state:CameraEditorState, bytes:Bytes):Bool
  {
    // [Array<SongMetadata>, Array<SongChartData>, ChartManifestData, Map<String, Bytes>, Map<String, Bytes>]
    var entries:Array<Dynamic> = funkin.ui.debug.charting.handlers.ChartEditorImportExportHandler.genericLoadFNFC(bytes);

    if (entries == null || entries.length != 5)
    {
      throw 'Invalid or corrupted FNFC file.';
      return false;
    }

    state.songMetadatas = entries[0];
    state.songDatas = entries[1];
    state.songManifestData = entries[2];
    state.audioInstTrackData = entries[3];
    state.audioVocalTrackData = entries[4];
    state.buildStage();

    return true;
  }

  /**
   * Loads an FNFC chart from an absolute file path and returns its parsed contents.
   * @param state The Camera Editor state to apply the loaded data to.
   * @param path The absolute path to the FNFC file to load.
   * @return `true` if the file was successfully loaded, `false` otherwise.
   */
  public static function loadFNFCFromPath(state:CameraEditorState, path:String):Bool
  {
    var bytes:Null<Bytes> = FileUtil.readBytesFromPath(path);
    if (bytes == null) return false;

    return loadFNFCFromBytes(state, bytes);
  }

  /**
   * Evaluates the list of backups,
   * @return The file path to the latest chart backup, or null if no backups exist.
   */
  public static function getLatestBackupPath():Null<String>
  {
    return funkin.ui.debug.charting.handlers.ChartEditorImportExportHandler.getLatestBackupPath();
  }

  /**
   * Retrieve the latest chart backup file, then return a string containing identifying info like the full filename and timestamp.
   * @return The formatted info.
   */
  public static function getLatestBackupInfo():Null<String>
  {
    return funkin.ui.debug.charting.handlers.ChartEditorImportExportHandler.getLatestBackupInfo();
  }

  /**
   * Save the current chart data to the specified path.
   * @param state The current state of the camera editor, containing the chart data to save.
   * @param force If `true`, will write the file without prompting the user.
   *    If a `targetPath` to save to is not specified, save to the `backups` directory.
   * @param targetPath The path to save to.
   * @param onSaveCb Callback to call when the file is saved.
   * @param onCancelCb Callback to call when the file is not saved.
   */
  public static function saveFNFCToPath(state:CameraEditorState, force:Bool = false, ?targetPath:String, onSaveCb:Null<String->Void>,
      onCancelCb:Null<Void->Void>):Void
  {
    var zipEntries:Array<haxe.zip.Entry> = [];

    var songId:String = state.songManifestData.songId;

    var variations:Array<String> = state.songMetadatas.keyValues();

    for (variation in variations)
    {
      var variationId:String = variation;
      if (variation == '' || variation == 'default' || variation == 'normal')
      {
        variationId = '';
      }

      if (variationId == '')
      {
        var variationMetadata:Null<SongMetadata> = state.songMetadatas.get(variation);
        if (variationMetadata != null)
        {
          variationMetadata.version = funkin.data.song.SongRegistry.SONG_METADATA_VERSION;
          variationMetadata.generatedBy = funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY;
          zipEntries.push(FileUtil.makeZIPEntry('${songId}-metadata.json', variationMetadata.serialize()));
          trace('Metadata: ' + variationMetadata.generatedBy);
        }
        var variationChart:Null<SongChartData> = state.songDatas.get(variation);
        if (variationChart != null)
        {
          variationChart.version = funkin.data.song.SongRegistry.SONG_CHART_DATA_VERSION;
          variationChart.generatedBy = funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY;
          zipEntries.push(FileUtil.makeZIPEntry('${songId}-chart.json', variationChart.serialize()));
        }
      }
      else
      {
        var variationMetadata:Null<SongMetadata> = state.songMetadatas.get(variation);
        if (variationMetadata != null)
        {
          zipEntries.push(FileUtil.makeZIPEntry('${songId}-metadata-$variationId.json', variationMetadata.serialize()));
        }
        var variationChart:Null<SongChartData> = state.songDatas.get(variation);
        if (variationChart != null)
        {
          variationChart.version = funkin.data.song.SongRegistry.SONG_CHART_DATA_VERSION;
          variationChart.generatedBy = funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY;
          zipEntries.push(FileUtil.makeZIPEntry('${songId}-chart-$variationId.json', variationChart.serialize()));
        }
      }
    }

    if (state.audioInstTrackData != null) zipEntries = zipEntries.concat(makeZIPEntriesFromInstrumentals(state));
    if (state.audioVocalTrackData != null) zipEntries = zipEntries.concat(makeZIPEntriesFromVocals(state));

    zipEntries.push(FileUtil.makeZIPEntry('manifest.json', state.songManifestData.serialize()));

    trace('Exporting ${zipEntries.length} files to ZIP...');

    if (force)
    {
      var targetMode:FileWriteMode = Force;
      if (targetPath == null)
      {
        // Force writing to a generic path (autosave or crash recovery)
        targetMode = Skip;
        targetPath = Path.join([
          BACKUPS_PATH,
          'camera-editor-${songId}-${DateUtil.generateTimestamp()}.${Constants.EXT_CHART}'
        ]);
        // We have to force write because the program will die before the save dialog is closed.
        trace('Force exporting to $targetPath...');
        try
        {
          FileUtil.saveFilesAsZIPToPath(zipEntries, targetPath, targetMode);
          // On success.
          if (onSaveCb != null) onSaveCb(targetPath);
        }
        catch (e)
        {
          // On failure.
          if (onCancelCb != null) onCancelCb();
        }
      }
      else
      {
        // Force write since we know what file the user wants to overwrite.
        trace('Force exporting to $targetPath...');
        try
        {
          // On success.
          FileUtil.saveFilesAsZIPToPath(zipEntries, targetPath, targetMode);
          state.saved = true;
          if (onSaveCb != null) onSaveCb(targetPath);
        }
        catch (e)
        {
          // On failure.
          if (onCancelCb != null) onCancelCb();
        }
      }
    }
    else
    {
      // Prompt and save.
      var onSave:Array<String>->Void = function(paths:Array<String>) {
        if (paths.length != 1)
        {
          trace(' WARNING '.warning() + ' Could not get save path.');
          state.updateWindowTitle();
        }
        else
        {
          trace('Saved to "${paths[0]}"');
          state.currentWorkingFilePath = paths[0];
          state.updateWindowTitle();
          if (onSaveCb != null) onSaveCb(paths[0]);
        }
      };

      var onCancel:Void->Void = function() {
        trace('Export cancelled.');
        if (onCancelCb != null) onCancelCb();
      };

      trace('Exporting to user-defined location...');
      try
      {
        FileUtil.saveChartAsFNFC(zipEntries, onSave, onCancel, '${songId}.${Constants.EXT_CHART}');
        state.saved = true;
      }
      catch (e) {}
    }
  }

  /**
   * Create a list of ZIP file entries from the current loaded instrumental tracks in the chart eidtor.
   * @param state The chart editor state.
   * @return `Array<haxe.zip.Entry>`
   */
  public static function makeZIPEntriesFromInstrumentals(state:CameraEditorState):Array<haxe.zip.Entry>
  {
    var zipEntries = [];

    var instTrackIds:Array<String> = state.audioInstTrackData.keys().array();
    for (key in instTrackIds)
    {
      if (key == 'default')
      {
        var data:Null<Bytes> = state.audioInstTrackData.get('default');
        if (data == null)
        {
          trace(' WARNING '.warning() + ' Failed to access inst track ($key)');
          continue;
        }
        zipEntries.push(FileUtil.makeZIPEntryFromBytes('Inst.ogg', data));
      }
      else
      {
        var data:Null<Bytes> = state.audioInstTrackData.get(key);
        if (data == null)
        {
          trace(' WARNING '.warning() + ' Failed to access inst track ($key)');
          continue;
        }
        zipEntries.push(FileUtil.makeZIPEntryFromBytes('Inst-${key}.ogg', data));
      }
    }

    return zipEntries;
  }

  /**
   * Create a list of ZIP file entries from the current loaded vocal tracks in the chart eidtor.
   * @param state The chart editor state.
   * @return `Array<haxe.zip.Entry>`
   */
  public static function makeZIPEntriesFromVocals(state:CameraEditorState):Array<haxe.zip.Entry>
  {
    var zipEntries = [];

    var vocalTrackIds:Array<String> = state.audioVocalTrackData.keys().array();
    for (key in state.audioVocalTrackData.keys())
    {
      var data:Null<Bytes> = state.audioVocalTrackData.get(key);
      if (data == null)
      {
        trace(' WARNING '.warning() + ' Failed to access vocal track ($key)');
        continue;
      }
      zipEntries.push(FileUtil.makeZIPEntryFromBytes('Voices-${key}.ogg', data));
    }

    return zipEntries;
  }
}
#end
