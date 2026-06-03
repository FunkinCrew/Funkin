package funkin.ui.debug.charting.handlers;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongNoteDataUtils;
import funkin.util.VersionUtil;
import funkin.util.DateUtil;
import haxe.io.Path;
import funkin.util.SortUtil;
import funkin.util.FileUtil;
import funkin.util.FileUtil.FileWriteMode;
import haxe.io.Bytes;
import funkin.play.song.Song;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongRegistry;
import funkin.data.song.importer.ChartManifestData;
import thx.semver.Version as SemverVersion;
import funkin.util.file.FNFCUtil;
import funkin.util.file.FNFCUtil.FNFCData;

/**
 * Contains functions for importing, loading, saving, and exporting charts.
 */
@:nullSafety @:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorImportExportHandler
{
  /**
   * The local file path to save Chart Editor backups to.
   */
  public static final BACKUPS_PATH:String = './backups/charts/';

  /**
   * Loads an FNFC chart into the Chart Editor from its parsed contents.
   *
   * @param state The Chart Editor state to apply the loaded data to.
   * @param data The parsed data of the FNFC file to load.
   * @param path The path of the FNFC file, if it is known.
   */
  public static function loadSongFromFNFCData(state:ChartEditorState, data:FNFCData, ?path:String):Void
  {
    // Apply metadata and chart data.
    state.songMetadata = data.songMetadatas;
    state.songChartData = data.songChartDatas;
    state.songManifestData = data.manifest;

    // Select the default variation if the currently selected one doesn't exist in the new song.
    if (!state.songMetadata.exists(state.selectedVariation)) state.selectedVariation = Constants.DEFAULT_VARIATION;

    // Select the first available difficulty if the currently selected one doesn't exist in the new song.
    if (state.availableDifficulties.indexOf(state.selectedDifficulty) < 0) state.selectedDifficulty = state.availableDifficulties[0];

    state.sortChartData();

    // Update the conductor.
    Conductor.instance.forceBPM(null); // Disable the forced BPM.
    Conductor.instance.instrumentalOffset = state.currentInstrumentalOffset; // Loads from the metadata.
    Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);
    state.updateTimeSignature();

    // Mark all the previews as dirty so they will be redrawn with the new song data.
    state.notePreviewDirty = true;
    state.notePreviewViewportBoundsDirty = true;
    state.difficultySelectDirty = true;
    state.opponentPreviewDirty = true;
    state.playerPreviewDirty = true;

    // Remove old instrumental tracks.
    if (state.audioInstTrack != null)
    {
      state.audioInstTrack.stop();
      state.audioInstTrack = null;
    }
    ChartEditorAudioHandler.wipeInstrumentalData(state);

    // Load new instrumental tracks from the FNFC.
    state.audioInstTrackData = data.instrumentals;

    // Remove old vocal tracks.
    state.audioVocalTrackGroup.stop();
    state.audioVocalTrackGroup.clear();
    ChartEditorAudioHandler.wipeVocalData(state);

    // Load new vocal tracks from the FNFC.
    state.audioVocalTrackData = data.vocals;

    // Now the song audio is loaded, switch to the correct instrumental track
    state.switchToCurrentInstrumental();
    state.postLoadInstrumental();
    state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    // Clear the undo and redo history when loading a new song.
    state.undoHistory = [];
    state.redoHistory = [];
    state.commandHistoryDirty = true;

    // Detect stacked notes
    detectStackedNotes(state);

    var songDisplay:String = (path != null) ? path : data.manifest.songId;

    if (data.issues == null || data.issues.length == 0)
    {
      state.success('Loaded Chart', 'Loaded chart "${songDisplay}"');
    }
    else
    {
      state.warning('Loaded Chart', 'Loaded chart "$songDisplay" with issues:\n${data.issues.join("\n")}');
    }
  }

  /**
   * Loads an FNFC chart into the Chart Editor from the FNFC file's byte data.
   *
   * @param state The Chart Editor state to apply the loaded data to.
   * @param bytes The byte data for the FNFC file to load.
   * @param path The path of the FNFC file. Optional, only for logging purposes.
   * @return `null` on failure, `[]` on success, `[warnings]` on success with warnings.
   */
  public static function loadSongFromFNFCBytes(state:ChartEditorState, bytes:Bytes, ?path:String):Void
  {
    var entries:FNFCData = FNFCUtil.loadDataFromFNFCBytes(bytes, true);
    loadSongFromFNFCData(state, entries, path);

    if (path != null)
    {
      state.currentWorkingFilePath = path;
      state.saveDataDirty = false; // Just loaded file!
    }
  }

  /**
   * Loads an FNFC chart from an absolute file path and returns its parsed contents.
   *
   * @param state The Chart Editor state to apply the loaded data to.
   * @param path The absolute path to the FNFC file to load.
   * @return `null` on failure, `[]` on success, `[warnings]` on success with warnings.
   */
  public static function loadSongFromFNFCPath(state:ChartEditorState, path:String):Void
  {
    var entries:FNFCData = FNFCUtil.loadDataFromFNFCPath(path, true);
    loadSongFromFNFCData(state, entries, path);

    state.currentWorkingFilePath = path;
    state.saveDataDirty = false; // Just loaded file!
  }

  static function detectStackedNotes(state:ChartEditorState):Void
  {
    // Look for stacked notes in each chart, and display a warning if any are found.
    for (variation => chart in state.songChartData)
    {
      var metadata:Null<SongMetadata> = state.songMetadata[variation];
      if (metadata == null) continue;

      var stackedNotesCount:Int = 0;
      var affectedDiffs:Array<String> = [];

      var delay:Float = 0.5;
      for (diff => notes in chart.notes)
      {
        // If the difficulty is hidden, skip it.
        if (!metadata.playData.difficulties.contains(diff)) continue;

        // Look for stacked notes.
        var count:Int = SongNoteDataUtils.listStackedNotes(notes, 0, false).length;
        if (count > 0)
        {
          affectedDiffs.pushUnique(diff);
          stackedNotesCount += count;
        }
      }

      if (stackedNotesCount > 0)
      {
        // Difficulty names might be out of order
        affectedDiffs.sort(SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_DIFFICULTY_LIST_FULL));
        affectedDiffs = affectedDiffs.map(diff -> diff.toTitleCase());

        // Increase the delay between notifications if there are multiple variations with stacked notes, to prevent overlap.
        flixel.util.FlxTimer.wait(delay, () ->
        {
          state.warning('Stacked Notes Detected', 'Found $stackedNotesCount stacked note(s) in \'${variation.toTitleCase()}\' variation, '
            + 'on ${affectedDiffs.joinPlural()} difficult${affectedDiffs.length > 1 ? 'ies' : 'y'}.');
        });
        delay *= 1.5;
      }
    }
  }

  /**
   * Loads an FNFC chart created from a song in the game data.
   *
   * @param state The Chart Editor state to apply the loaded data to.
   * @param songId The internal song ID of the song to load.
   * @param difficulty The difficulty to select after loading the song.
   * @param variation The variation to select after loading the song.
   * @return `null` on failure, `[]` on success, `[warnings]` on success with warnings.
   */
  public static function loadSongFromTemplate(state:ChartEditorState, songId:String, ?difficulty:String, ?variation:String):Null<Array<String>>
  {
    try
    {
      var entries:FNFCData = FNFCUtil.buildFNFCDataFromTemplate(songId, true);
      loadSongFromFNFCData(state, entries, null);

      state.currentWorkingFilePath = null;
      state.saveDataDirty = false; // Just loaded template!

      // Set the variation of the song if one was passed in the params, and it isn't the default
      if (variation != null) state.selectedVariation = variation;
      // Set the difficulty of the song if one was passed in the params, and it isn't the default
      if (difficulty != null) state.selectedDifficulty = difficulty;

      return [];
    }
    catch (e)
    {
      return ['$e'];
    }
  }

  /**
   * Evaluates the list of backups,
   *
   * @param prefix An optional prefix to filter the backups by.
   * @return The file path to the latest chart backup, or null if no backups exist.
   */
  public static function getLatestBackupPath(?prefix:String):Null<String>
  {
    #if sys
    FileUtil.createDirIfNotExists(BACKUPS_PATH);

    var files:Array<String> = sys.FileSystem.readDirectory(BACKUPS_PATH);
    // Filter to only the backups for the chart editor
    files = files.filter((file:String) ->
    {
      if (!file.endsWith(Constants.EXT_CHART)) return false;
      if (prefix != null && !file.startsWith(prefix)) return false;

      return true;
    });
    if (files.length == 0) return null; // No backups.
    if (files.length == 1) return haxe.io.Path.join([BACKUPS_PATH, files[0]]);

    // Get the stats for each file so we can compare timestamps.
    // Sort the list of files by their timestamp (newest first)
    files.sort((a:String, b:String) ->
    {
      var aStat:sys.FileStat = sys.FileSystem.stat(haxe.io.Path.join([BACKUPS_PATH, a]));
      var bStat:sys.FileStat = sys.FileSystem.stat(haxe.io.Path.join([BACKUPS_PATH, b]));
      return aStat.mtime.getTime() < bStat.mtime.getTime() ? 1 : -1;
    });

    trace('Sorted backup files: ${files}');

    // The first file in the list is the latest backup.
    var latestBackupPath:String = files[0];

    return haxe.io.Path.join([BACKUPS_PATH, latestBackupPath]);
    #else
    return null;
    #end
  }

  /**
   * Retrieve the latest chart backup file, then return a string containing identifying info like the full filename and timestamp.
   * @return The formatted info.
   */
  public static function getLatestBackupInfo(?prefix:String):Null<String>
  {
    #if sys
    var latestBackupPath:Null<String> = getLatestBackupPath(prefix);
    if (latestBackupPath == null) return null;

    var latestBackupName:String = haxe.io.Path.withoutDirectory(latestBackupPath);
    latestBackupName = haxe.io.Path.withoutExtension(latestBackupName);

    final BYTES_PER_MB:Float = 1_000_000;
    var stat = sys.FileSystem.stat(latestBackupPath);
    var sizeInMB = (stat.size / BYTES_PER_MB).round(3);

    return 'Full Name: ' + latestBackupName + '\nLast Modified: ' + stat.mtime.toString() + '\nSize: ' + sizeInMB + ' MB';
    #else
    return null;
    #end
  }

  static function buildFNFCDataFromCurrentChart(state:ChartEditorState):FNFCData
  {
    return {
      songMetadatas: state.songMetadata,
      songChartDatas: state.songChartData,
      manifest: state.songManifestData,
      instrumentals: state.audioInstTrackData,
      vocals: state.audioVocalTrackData
    };
  }

  /**
   * Build an `.fnfc` file from the current chart data and export it to a user-defined location or an autosave location.
   *
   * @param state The Chart Editor state containing the chart data to export.
   * @param force Whether to export without prompting. `false` will prompt the user for a location.
   * @param targetPath where to export if `force` is `true`. If `null`, will export to the `backups` folder.
   * @param onSaveCb Callback for when the file is saved.
   * @param onCancelCb Callback for when saving is cancelled.
   */
  public static function exportCurrentChartToFNFC(state:ChartEditorState, force:Bool = false, ?targetPath:String, ?onSaveCb:String->Void, ?onCancelCb:Void->Void):Void
  {
    var fnfcData:FNFCData = ChartEditorImportExportHandler.buildFNFCDataFromCurrentChart(state);
    var zipEntries:Array<haxe.zip.Entry> = FNFCUtil.buildZIPEntriesFromFNFCData(fnfcData);

    trace('Exporting ${zipEntries.length} files to ZIP...');

    if (force)
    {
      var targetMode:FileWriteMode = Force;
      if (targetPath == null)
      {
        // Force writing to a generic path (autosave or crash recovery)
        targetMode = Skip;
        if (state.currentSongId == '') state.currentSongName = 'New Chart'; // Hopefully no one notices this silliness
        targetPath = Path.join([
          BACKUPS_PATH,
          'chart-editor-${state.currentSongId}-${DateUtil.generateTimestamp()}.${Constants.EXT_CHART}'
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
          state.saveDataDirty = false;
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
      var onSave:Array<String>->Void = function(paths:Array<String>)
      {
        if (paths.length != 1)
        {
          trace(' WARNING '.warning() + ' Could not get save path.');
          state.applyWindowTitle();
        }
        else
        {
          trace('Saved to "${paths[0]}"');
          state.currentWorkingFilePath = paths[0];
          state.applyWindowTitle();
          if (onSaveCb != null) onSaveCb(paths[0]);
        }
      };

      var onCancel:Void->Void = function()
      {
        trace('Export cancelled.');
        if (onCancelCb != null) onCancelCb();
      };

      trace('Exporting to user-defined location...');
      try
      {
        FileUtil.saveChartAsFNFC(zipEntries, onSave, onCancel, '${state.currentSongId}.${Constants.EXT_CHART}');
        state.saveDataDirty = false;
      }
      catch (e)
      {
      }
    }
  }
}
#end
