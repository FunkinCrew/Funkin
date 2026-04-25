package funkin.ui.debug.cameraeditor.handlers;

#if FEATURE_CAMERA_EDITOR
import haxe.io.Bytes;
import haxe.io.Path;
import funkin.util.DateUtil;
import funkin.util.FileUtil;
import funkin.util.file.FNFCUtil;
import funkin.util.file.FNFCUtil.FNFCData;

/**
 * Handles saving, loading, importing, and exporting for the camera editor.
 */
@:nullSafety
class CameraEditorImportExportHandler
{
  public static final BACKUPS_PATH:String = './backups/charts/';

  /**
   * Loads an FNFC chart into the Camera Editor from its parsed contents.
   *
   * @param state The Camera Editor state to apply the loaded data to.
   * @param data The parsed data of the FNFC file to load.
   * @param path The path of the FNFC file, if it is known.
   */
  public static function loadSongFromFNFCData(state:CameraEditorState, data:FNFCData, ?path:String):Void
  {
    state.currentWorkingFilePath = path;
    state.saved = true; // Just loaded file!

    state.songMetadatas = entries.songMetadatas;
    state.songDatas = entries.songChartDatas;
    state.songManifestData = entries.manifest;
    state.audioInstTrackData = entries.instrumentals;
    state.audioVocalTrackData = entries.vocals;
    state.onChartLoaded();

    trace('Loaded ${state.audioInstTrackData.size()} instrumentals and ${state.audioVocalTrackData.size()} vocals from FNFC file at "$path".');
    CameraEditorNotificationHandler.success(this.cameraEditorState, 'Loaded Chart', 'Loaded chart (${path})');

    return true;
  }

  /**
   * Loads an FNFC chart into the Camera Editor from the FNFC file's byte data.
   *
   * @param state The Camera Editor state to apply the loaded data to.
   * @param bytes The byte data for the FNFC file to load.
   * @param path The path of the FNFC file. Optional, only for logging purposes.
   * @return `null` on failure, `[]` on success, `[warnings]` on success with warnings.
   */
  public static function loadSongFromFNFCBytes(state:CameraEditorState, bytes:Bytes, ?path:String):Null<Array<String>>
  {
    try
    {
      var entries:FNFCData = FNFCUtil.loadDataFromFNFCBytes(selectedFileBytes, true);
      loadSongFromFNFCData(state, entries, path);
      return [];
    }
    catch (e)
    {
      return [e];
    }
  }

  /**
   * Loads an FNFC chart from an absolute file path and returns its parsed contents.
   *
   * @param state The Camera Editor state to apply the loaded data to.
   * @param path The absolute path to the FNFC file to load.
   * @return `null` on failure, `[]` on success, `[warnings]` on success with warnings.
   */
  public static function loadSongFromFNFCPath(state:CameraEditorState, path:String):Null<Array<String>>
  {
    try
    {
      var entries:FNFCData = FNFCUtil.loadDataFromFNFCPath(path, true);
      loadSongFromFNFCData(state, entries, path);
      return [];
    }
    catch (e)
    {
      return [e];
    }
  }

  /**
   * Fetch's a song's existing chart and audio and loads it, replacing the current song.
   *
   * @param state The current chart editor state.
   * @param songId The internal song ID to load. This is the same as the song's folder name in the assets/songs directory.
   * @param difficulty The difficulty to select after loading the song. If null, it will default to the first available difficulty.
   * @param variation The variation to select after loading the song. If null, it will default to the first available variation.
   *
   * @return `null` on failure, `[]` on success, `[warnings]` on success with warnings.
   */
  public static function loadSongAsTemplate(state:CameraEditorState, songId:String, ?difficulty:String, ?variation:String):Null<Array<String>>
  {
    try
    {
      var entries:FNFCData = FNFCUtil.buildFNFCDataFromTemplate(songId, true);
      loadSongFromFNFCData(state, entries, 'template:$songId');

      if (difficulty != null) state.currentDifficulty = difficulty;
      if (variation != null) state.switchVariation(variation);

      return [];
    }
    catch (e)
    {
      return ['$e'];
    }
  }

  /**
   * Evaluates the list of backups,
   * @return The file path to the latest chart backup, or null if no backups exist.
   */
  public static function getLatestBackupPath():Null<String>
  {
    // lmao just reuse code who gaf
    return funkin.ui.debug.charting.handlers.ChartEditorImportExportHandler.getLatestBackupPath('camera-editor-');
  }

  /**
   * Retrieve the latest chart backup file, then return a string containing identifying info like the full filename and timestamp.
   * @return The formatted info.
   */
  public static function getLatestBackupInfo():Null<String>
  {
    // lmao just reuse code who gaf
    return funkin.ui.debug.charting.handlers.ChartEditorImportExportHandler.getLatestBackupInfo('camera-editor-');
  }

  static function buildFNFCDataFromCurrentChart(state:CameraEditorState):FNFCData
  {
    return {
      songMetadatas: state.songMetadatas,
      songChartDatas: state.songDatas,
      manifest: state.songManifestData,
      instrumentals: state.audioInstTrackData,
      vocals: state.audioVocalTrackData
    };
  }

  /**
   * Build an `.fnfc` file from the current chart data and export it to a user-defined location or an autosave location.
   *
   * @param state The Camera Editor state containing the chart data to export.
   * @param force Whether to export without prompting. `false` will prompt the user for a location.
   * @param targetPath where to export if `force` is `true`. If `null`, will export to the `backups` folder.
   * @param onSaveCb Callback for when the file is saved.
   * @param onCancelCb Callback for when saving is cancelled.
   */
  public static function exportCurrentChartToFNFC(state:CameraEditorState, force:Bool = false, ?targetPath:String, ?onSaveCb:String->Void,
      ?onCancelCb:Void->Void):Void
  {
    var fnfcData:FNFCData = CameraEditorImportExportHandler.buildFNFCDataFromCurrentChart(state);
    var zipEntries:Array<haxe.zip.Entry> = FNFCUtil.buildZIPEntriesFromFNFCData(fnfcData);

    var songId:String = fnfcData.manifest.songId;

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
}
#end
