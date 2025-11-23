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

/**
 * Contains functions for importing, loading, saving, and exporting charts.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorImportExportHandler
{
  public static final BACKUPS_PATH:String = './backups/charts/';

  /**
   * Fetch's a song's existing chart and audio and loads it, replacing the current song.
   */
  public static function loadSongAsTemplate(state:ChartEditorState, songId:String, targetSongDifficulty:String = null, targetSongVariation:String = null):Void
  {
    trace('===============START');

    var song:Null<Song> = SongRegistry.instance.fetchEntry(songId, {variation: targetSongVariation});

    if (song == null) return;

    // Load the song metadata.
    var rawSongMetadata:Array<SongMetadata> = song.getRawMetadata();
    var songMetadata:Map<String, SongMetadata> = [];
    var songChartData:Map<String, SongChartData> = [];

    for (metadata in rawSongMetadata)
    {
      if (metadata == null) continue;
      var variation = (metadata.variation == null || metadata.variation == '') ? Constants.DEFAULT_VARIATION : metadata.variation;

      // Clone to prevent modifying the original.
      var metadataClone:SongMetadata = metadata.clone();
      metadataClone.variation = variation;
      if (metadataClone != null) songMetadata.set(variation, metadataClone);

      var chartData:Null<SongChartData> = SongRegistry.instance.parseEntryChartData(songId, metadata.variation);
      if (chartData != null) songChartData.set(variation, chartData);
    }

    loadSong(state, songMetadata, songChartData, new ChartManifestData(songId));

    state.sortChartData();

    ChartEditorAudioHandler.wipeInstrumentalData(state);
    ChartEditorAudioHandler.wipeVocalData(state);

    for (variation in state.availableVariations)
    {
      if (variation == Constants.DEFAULT_VARIATION)
      {
        state.loadInstFromAsset(Paths.inst(songId));
      }
      else
      {
        state.loadInstFromAsset(Paths.inst(songId, '-$variation'), variation);
      }

      for (difficultyId in song.listDifficulties(variation, true, true))
      {
        var diff:Null<SongDifficulty> = song.getDifficulty(difficultyId, variation);
        if (diff == null) continue;

        var instId:String = diff.variation == Constants.DEFAULT_VARIATION ? '' : diff.variation;

        var playerVoiceList:Array<String> = diff.buildPlayerVoiceList(); // SongDifficulty accounts for variation already.
        for (voice in playerVoiceList)
        {
          state.loadVocalsFromAsset(voice, diff.characters.player, instId);
        }

        var opponentVoiceList:Array<String> = diff.buildOpponentVoiceList();
        for (voice in opponentVoiceList)
        {
          state.loadVocalsFromAsset(voice, diff.characters.opponent, instId);
        }

        // Set the difficulty of the song if one was passed in the params, and it isn't the default
        if (targetSongDifficulty != null
          && targetSongDifficulty != state.selectedDifficulty
          && targetSongDifficulty == diff.difficulty) state.selectedDifficulty = targetSongDifficulty;
        // Set the variation of the song if one was passed in the params, and it isn't the default
        if (targetSongVariation != null
          && targetSongVariation != state.selectedVariation
          && targetSongVariation == diff.variation) state.selectedVariation = targetSongVariation;
      }
    }

    state.isHaxeUIDialogOpen = false;
    state.currentWorkingFilePath = null; // New file, so no path.
    state.switchToCurrentInstrumental();

    state.postLoadInstrumental();

    state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    // Actually state the correct variation loaded
    for (metadata in rawSongMetadata)
    {
      if (metadata.variation == state.selectedVariation) state.success('Success', 'Loaded song (${metadata.songName})');
    }

    trace('===============END');
  }

  /**
   * Loads a chart from parsed song metadata and chart data into the editor.
   * @param newSongMetadata The song metadata to load.
   * @param newSongChartData The song chart data to load.
   */
  public static function loadSong(state:ChartEditorState, newSongMetadata:Map<String, SongMetadata>, newSongChartData:Map<String, SongChartData>,
      ?newSongManifestData:ChartManifestData):Void
  {
    state.songMetadata = newSongMetadata;
    state.songChartData = newSongChartData;
    if (newSongManifestData != null)
    {
      state.songManifestData = newSongManifestData;
    }

    if (!state.songMetadata.exists(state.selectedVariation))
    {
      state.selectedVariation = Constants.DEFAULT_VARIATION;
    }
    // Use the first available difficulty as a fallback if the currently selected one cannot be found.
    if (state.availableDifficulties.indexOf(state.selectedDifficulty) < 0) state.selectedDifficulty = state.availableDifficulties[0];

    var delay:Float = 0.5;
    for (variation => chart in state.songChartData)
    {
      var metadata:SongMetadata = state.songMetadata[variation] ?? continue;
      var stackedNotesCount:Int = 0;
      var affectedDiffs:Array<String> = [];

      for (diff => notes in chart.notes)
      {
        if (!metadata.playData.difficulties.contains(diff)) continue;

        var count:Int = SongNoteDataUtils.listStackedNotes(notes, 0, false).length;

        if (count > 0)
        {
          affectedDiffs.push(diff.toTitleCase());
          stackedNotesCount += count;
        }
      }

      if (stackedNotesCount > 0)
      {
        // Difficulty names might be out of order due to how maps work
        affectedDiffs.sort(SortUtil.defaultsThenAlphabetically.bind(['Easy', 'Normal', 'Hard', 'Erect', 'Nightmare']));

        // Delay it so it doesn't overlap other notifications
        flixel.util.FlxTimer.wait(delay, () -> {
          state.warning('Stacked Notes Detected',
            'Found $stackedNotesCount stacked note(s) in \'${variation.toTitleCase()}\' variation, ' +
            'on ${affectedDiffs.joinPlural()} difficult${affectedDiffs.length > 1 ? 'ies' : 'y'}.');
        });
        delay *= 1.5;
      }
    }

    Conductor.instance.forceBPM(null); // Disable the forced BPM.
    Conductor.instance.instrumentalOffset = state.currentInstrumentalOffset; // Loads from the metadata.
    Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);
    state.updateTimeSignature();

    state.notePreviewDirty = true;
    state.notePreviewViewportBoundsDirty = true;
    state.difficultySelectDirty = true;
    state.opponentPreviewDirty = true;
    state.playerPreviewDirty = true;

    // Remove instrumental and vocal tracks, they will be loaded next.
    if (state.audioInstTrack != null)
    {
      state.audioInstTrack.stop();
      state.audioInstTrack = null;
    }
    state.audioVocalTrackGroup.stop();
    state.audioVocalTrackGroup.clear();

    // Clear the undo and redo history
    state.undoHistory = [];
    state.redoHistory = [];
    state.commandHistoryDirty = true;
  }

  /**
   * Load a chart's metadata, chart data, and audio from an FNFC file path.
   * @param state
   * @param path
   * @return `null` on failure, `[]` on success, `[warnings]` on success with warnings.
   */
  public static function loadFromFNFCPath(state:ChartEditorState, path:String):Null<Array<String>>
  {
    var bytes:Null<Bytes> = FileUtil.readBytesFromPath(path);
    if (bytes == null) return null;

    trace('Loaded ${bytes.length} bytes from $path');

    var result:Null<Array<String>> = loadFromFNFC(state, bytes);
    if (result != null)
    {
      state.currentWorkingFilePath = path;
      state.saveDataDirty = false; // Just loaded file!
    }

    return result;
  }

  /**
   * Load a chart's metadata, chart data, and audio from an FNFC archive.
   * @param state
   * @param bytes
   * @param instId
   * @return `null` on failure, `[]` on success, `[warnings]` on success with warnings.
   */
  public static function loadFromFNFC(state:ChartEditorState, bytes:Bytes):Null<Array<String>>
  {
    var output:Array<String> = [];

    // TODO: Combine with code in FNFCUtil.hx

    // Read the ZIP/.FNFC file, and create a map of entries.
    var fileEntries:Array<haxe.zip.Entry> = FileUtil.readZIPFromBytes(bytes);
    var mappedFileEntries:Map<String, haxe.zip.Entry> = FileUtil.mapZIPEntriesByName(fileEntries);
    var manifestString:String = mappedFileEntries.get('manifest.json')?.data?.toString() ?? throw 'Could not locate manifest.';
    var manifest:ChartManifestData = ChartManifestData.deserialize(manifestString) ?? throw 'Could not read manifest.';

    var baseMetadataPath:String = manifest.getMetadataFileName();
    var baseMetadataString:String = mappedFileEntries.get(baseMetadataPath)?.data?.toString() ?? throw 'Could not locate metadata (default).';
    var baseMetadataVersion:SemverVersion = VersionUtil.getVersionFromJSON(baseMetadataString) ?? throw 'Could not read metadata version (default).';
    var baseMetadata:SongMetadata = SongRegistry.instance.parseEntryMetadataRawWithMigration(baseMetadataString, baseMetadataPath,
      baseMetadataVersion) ?? throw 'Could not read metadata (default).';

    var songMetadatas:Map<String, SongMetadata> = [];
    songMetadatas.set(Constants.DEFAULT_VARIATION, baseMetadata);

    var baseChartDataPath:String = manifest.getChartDataFileName();
    var baseChartDataString:String = mappedFileEntries.get(baseChartDataPath)?.data?.toString() ?? throw 'Could not locate chart data (default).';
    var baseChartDataVersion:SemverVersion = VersionUtil.getVersionFromJSON(baseChartDataString) ?? throw 'Could not read chart data version (default).';
    var baseChartData:SongChartData = SongRegistry.instance.parseEntryChartDataRawWithMigration(baseChartDataString, baseChartDataPath,
      baseChartDataVersion) ?? throw 'Could not read chart data (default).';

    var songChartDatas:Map<String, SongChartData> = [];
    songChartDatas.set(Constants.DEFAULT_VARIATION, baseChartData);

    var variationList:Array<String> = baseMetadata.playData.songVariations;

    for (variation in variationList)
    {
      var variMetadataPath:String = manifest.getMetadataFileName(variation);
      var variMetadataString:String = mappedFileEntries.get(variMetadataPath)?.data?.toString() ?? throw 'Could not locate metadata ($variation).';
      var variMetadataVersion:SemverVersion = VersionUtil.getVersionFromJSON(variMetadataString) ?? throw 'Could not read metadata ($variation) version.';
      var variMetadata:SongMetadata = SongRegistry.instance.parseEntryMetadataRawWithMigration(variMetadataString, variMetadataPath, variMetadataVersion,
        variation) ?? throw 'Could not read metadata ($variation).';

      songMetadatas.set(variation, variMetadata);

      var variChartDataPath:String = manifest.getChartDataFileName(variation);
      var variChartDataString:String = mappedFileEntries.get(variChartDataPath)?.data?.toString() ?? throw 'Could not locate chart data ($variation).';
      var variChartDataVersion:SemverVersion = VersionUtil.getVersionFromJSON(variChartDataString) ?? throw 'Could not read chart data version ($variation).';
      var variChartData:SongChartData = SongRegistry.instance.parseEntryChartDataRawWithMigration(variChartDataString, variChartDataPath,
        variChartDataVersion, variation) ?? throw 'Could not read chart data ($variation).';
      songChartDatas.set(variation, variChartData);
    }
    loadSong(state, songMetadatas, songChartDatas, manifest);

    state.sortChartData();

    ChartEditorAudioHandler.wipeInstrumentalData(state);
    ChartEditorAudioHandler.wipeVocalData(state);

    // Load instrumentals
    for (variation in state.availableVariations)
    {
      var variMetadata:Null<SongMetadata> = songMetadatas.get(variation);
      if (variMetadata == null) continue;

      var instId:String = variMetadata?.playData?.characters?.instrumental ?? '';

      var instFileName:String = manifest.getInstFileName(instId);
      var instFileBytes:Bytes = mappedFileEntries.get(instFileName)?.data ?? throw 'Could not locate instrumental ($instFileName).';
      if (!ChartEditorAudioHandler.loadInstFromBytes(state, instFileBytes, instId)) throw 'Could not load instrumental ($instFileName).';

      var playerCharId:String = variMetadata?.playData?.characters?.player ?? Constants.DEFAULT_CHARACTER;
      var playerVoiceList:Array<String> = variMetadata?.playData.characters?.playerVocals ?? [playerCharId];
      for (voice in playerVoiceList)
      {
        var playerVocalsFileName:String = manifest.getVocalsFileName(voice, variation);
        var playerVocalsFileBytes:Null<Bytes> = mappedFileEntries.get(playerVocalsFileName)?.data;
        if (playerVocalsFileBytes == null)
        {
          output.push('Could not find vocals ($playerVocalsFileName).');
          // throw 'Could not find vocals ($playerVocalsFileName).';
        }
        else if (!ChartEditorAudioHandler.loadVocalsFromBytes(state, playerVocalsFileBytes, voice, instId))
        {
          output.push('Could not parse vocals ($playerCharId).');
          // throw 'Could not parse vocals ($playerCharId).';
        }
      }

      var opponentCharId:Null<String> = variMetadata?.playData?.characters?.opponent ?? "dad";
      var opponentVoiceList:Array<String> = variMetadata?.playData.characters?.opponentVocals ?? [opponentCharId];
      for (voice in opponentVoiceList)
      {
        var opponentVocalsFileName:String = manifest.getVocalsFileName(voice, variation);
        var opponentVocalsFileBytes:Null<Bytes> = mappedFileEntries.get(opponentVocalsFileName)?.data;
        if (opponentVocalsFileBytes == null)
        {
          output.push('Could not find vocals ($opponentVocalsFileName).');
        }
        else if (!ChartEditorAudioHandler.loadVocalsFromBytes(state, opponentVocalsFileBytes, voice, instId))
        {
          output.push('Could not parse vocals ($opponentCharId).');
        }
      }
    }

    // Apply chart data.
    trace(songMetadatas);
    trace(songChartDatas);

    state.switchToCurrentInstrumental();
    state.postLoadInstrumental();
    state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    return output;
  }

  /**
   * Evaluates the list of backups,
   * @return The file path to the latest chart backup, or null if no backups exist.
   */
  public static function getLatestBackupPath():Null<String>
  {
    #if sys
    FileUtil.createDirIfNotExists(BACKUPS_PATH);

    var files:Array<String> = sys.FileSystem.readDirectory(BACKUPS_PATH);
    // Filter to only the backups for the chart editor
    files = files.filter((file:String) -> {
      return file.endsWith(Constants.EXT_CHART);
    });
    if (files.length == 0) return null; // No backups.
    if (files.length == 1) return haxe.io.Path.join([BACKUPS_PATH, files[0]]);

    // Get the stats for each file so we can compare timestamps.
    // Sort the list of files by their timestamp (newest first)
    files.sort((a:String, b:String) -> {
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
  public static function getLatestBackupInfo():Null<String>
  {
    #if sys
    var latestBackupPath:Null<String> = getLatestBackupPath();
    if (latestBackupPath == null) return null;

    var latestBackupName:String = haxe.io.Path.withoutDirectory(latestBackupPath);
    latestBackupName = haxe.io.Path.withoutExtension(latestBackupName);

    var stat = sys.FileSystem.stat(latestBackupPath);
    var sizeInMB = (stat.size / 1000000).round(3);

    return "Full Name: " + latestBackupName + "\nLast Modified: " + stat.mtime.toString() + "\nSize: " + sizeInMB + " MB";
    #else
    return null;
    #end
  }

  /**
   * @param force Whether to export without prompting. `false` will prompt the user for a location.
   * @param targetPath where to export if `force` is `true`. If `null`, will export to the `backups` folder.
   * @param onSaveCb Callback for when the file is saved.
   * @param onCancelCb Callback for when saving is cancelled.
   */
  public static function exportAllSongData(state:ChartEditorState, force:Bool = false, targetPath:Null<String>, ?onSaveCb:String->Void,
      ?onCancelCb:Void->Void):Void
  {
    var zipEntries:Array<haxe.zip.Entry> = [];

    var variations = state.availableVariations;

    if (state.currentSongMetadata.playData.difficulties.pushUnique(state.selectedDifficulty))
    {
      // Just in case the user deleted all or didn't add a difficulty
      state.difficultySelectDirty = true;
    }

    for (variation in variations)
    {
      var variationId:String = variation;
      if (variation == '' || variation == 'default' || variation == 'normal')
      {
        variationId = '';
      }

      if (variationId == '')
      {
        var variationMetadata:Null<SongMetadata> = state.songMetadata.get(variation);
        if (variationMetadata != null)
        {
          variationMetadata.version = funkin.data.song.SongRegistry.SONG_METADATA_VERSION;
          variationMetadata.generatedBy = funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY;
          zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-metadata.json', variationMetadata.serialize()));
        }
        var variationChart:Null<SongChartData> = state.songChartData.get(variation);
        if (variationChart != null)
        {
          variationChart.version = funkin.data.song.SongRegistry.SONG_CHART_DATA_VERSION;
          variationChart.generatedBy = funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY;
          zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-chart.json', variationChart.serialize()));
        }
      }
      else
      {
        var variationMetadata:Null<SongMetadata> = state.songMetadata.get(variation);
        if (variationMetadata != null)
        {
          zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-metadata-$variationId.json', variationMetadata.serialize()));
        }
        var variationChart:Null<SongChartData> = state.songChartData.get(variation);
        if (variationChart != null)
        {
          variationChart.version = funkin.data.song.SongRegistry.SONG_CHART_DATA_VERSION;
          variationChart.generatedBy = funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY;
          zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-chart-$variationId.json', variationChart.serialize()));
        }
      }
    }

    if (state.audioInstTrackData != null) zipEntries = zipEntries.concat(state.makeZIPEntriesFromInstrumentals());
    if (state.audioVocalTrackData != null) zipEntries = zipEntries.concat(state.makeZIPEntriesFromVocals());

    zipEntries.push(FileUtil.makeZIPEntry('manifest.json', state.songManifestData.serialize()));

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
      var onSave:Array<String>->Void = function(paths:Array<String>) {
        if (paths.length != 1)
        {
          trace(' WARNING '.bold().bg_yellow() + ' Could not get save path.');
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

      var onCancel:Void->Void = function() {
        trace('Export cancelled.');
        if (onCancelCb != null) onCancelCb();
      };

      trace('Exporting to user-defined location...');
      try
      {
        FileUtil.saveChartAsFNFC(zipEntries, onSave, onCancel, '${state.currentSongId}.${Constants.EXT_CHART}');
        state.saveDataDirty = false;
      }
      catch (e) {}
    }
  }
}
#end
