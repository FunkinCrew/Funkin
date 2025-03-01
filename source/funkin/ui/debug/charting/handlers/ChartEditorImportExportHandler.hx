package funkin.ui.debug.charting.handlers;

import funkin.util.VersionUtil;
import funkin.util.DateUtil;
import haxe.io.Path;
import funkin.util.SerializerUtil;
import funkin.util.SortUtil;
import funkin.util.FileUtil;
import funkin.util.FileUtil.FileWriteMode;
import haxe.io.Bytes;
import funkin.play.song.Song;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongRegistry;
import funkin.data.song.importer.ChartManifestData;

/**
 * Contains functions for importing, loading, saving, and exporting charts.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorImportExportHandler
{
  public static final BACKUPS_PATH:String = './backups/';

  /**
   * Fetch's a song's existing chart and audio and loads it, replacing the current song.
   */
  public static function loadSongAsTemplate(state:ChartEditorState, songId:String):Void
  {
    trace('===============START');

    var song:Null<Song> = SongRegistry.instance.fetchEntry(songId);

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

    loadSong(state, songMetadata, songChartData);

    state.sortChartData();

    ChartEditorAudioHandler.wipeInstrumentalData(state);
    ChartEditorAudioHandler.wipeVocalData(state);
    state.stopExistingVocals();

    var variations:Array<String> = state.availableVariations;
    for (variation in variations)
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
        var voiceList:Array<String> = diff.buildVoiceList(); // SongDifficulty accounts for variation already.

        if (voiceList.length == 2)
        {
          state.loadVocalsFromAsset(voiceList[0], diff.characters.player, instId);
          state.loadVocalsFromAsset(voiceList[1], diff.characters.opponent, instId);
        }
        else if (voiceList.length == 1)
        {
          state.loadVocalsFromAsset(voiceList[0], diff.characters.player, instId);
        }
        else
        {
          trace('[WARN] Strange quantity of voice paths for difficulty ${difficultyId}: ${voiceList.length}');
        }
      }
    }

    state.isHaxeUIDialogOpen = false;
    state.currentWorkingFilePath = null; // New file, so no path.
    state.switchToCurrentInstrumental();

    state.postLoadInstrumental();

    state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    state.success('Success', 'Loaded song (${rawSongMetadata[0].songName})');

    trace('===============END');
  }

  /**
   * Loads a chart from parsed song metadata and chart data into the editor.
   * @param newSongMetadata The song metadata to load.
   * @param newSongChartData The song chart data to load.
   */
  public static function loadSong(state:ChartEditorState, newSongMetadata:Map<String, SongMetadata>, newSongChartData:Map<String, SongChartData>):Void
  {
    state.songMetadata = newSongMetadata;
    state.songChartData = newSongChartData;

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
    var warnings:Array<String> = [];

    var songMetadatas:Map<String, SongMetadata> = [];
    var songChartDatas:Map<String, SongChartData> = [];

    var fileEntries:Array<haxe.zip.Entry> = FileUtil.readZIPFromBytes(bytes);
    var mappedFileEntries:Map<String, haxe.zip.Entry> = FileUtil.mapZIPEntriesByName(fileEntries);

    var manifestBytes:Null<Bytes> = mappedFileEntries.get('manifest.json')?.data;
    if (manifestBytes == null) throw 'Could not locate manifest.';
    var manifestString = manifestBytes.toString();
    var manifest:Null<ChartManifestData> = ChartManifestData.deserialize(manifestString);
    if (manifest == null) throw 'Could not read manifest.';

    // Get the song ID.
    var songId:String = manifest.songId;

    var baseMetadataPath:String = manifest.getMetadataFileName();
    var baseChartDataPath:String = manifest.getChartDataFileName();

    var baseMetadataBytes:Null<Bytes> = mappedFileEntries.get(baseMetadataPath)?.data;
    if (baseMetadataBytes == null) throw 'Could not locate metadata (default).';
    var baseMetadataString:String = baseMetadataBytes.toString();
    var baseMetadataVersion:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(baseMetadataString);
    if (baseMetadataVersion == null) throw 'Could not read metadata version (default).';

    var baseMetadata:Null<SongMetadata> = SongRegistry.instance.parseEntryMetadataRawWithMigration(baseMetadataString, baseMetadataPath, baseMetadataVersion);
    if (baseMetadata == null) throw 'Could not read metadata (default).';
    songMetadatas.set(Constants.DEFAULT_VARIATION, baseMetadata);

    var baseChartDataBytes:Null<Bytes> = mappedFileEntries.get(baseChartDataPath)?.data;
    if (baseChartDataBytes == null) throw 'Could not locate chart data (default).';
    var baseChartDataString:String = baseChartDataBytes.toString();
    var baseChartDataVersion:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(baseChartDataString);
    if (baseChartDataVersion == null) throw 'Could not read chart data (default) version.';

    var baseChartData:Null<SongChartData> = SongRegistry.instance.parseEntryChartDataRawWithMigration(baseChartDataString, baseChartDataPath,
      baseChartDataVersion);
    if (baseChartData == null) throw 'Could not read chart data (default).';
    songChartDatas.set(Constants.DEFAULT_VARIATION, baseChartData);

    var variationList:Array<String> = baseMetadata.playData.songVariations;

    for (variation in variationList)
    {
      var variMetadataPath:String = manifest.getMetadataFileName(variation);
      var variChartDataPath:String = manifest.getChartDataFileName(variation);

      var variMetadataBytes:Null<Bytes> = mappedFileEntries.get(variMetadataPath)?.data;
      if (variMetadataBytes == null) throw 'Could not locate metadata ($variation).';
      var variMetadataString:String = variMetadataBytes.toString();
      var variMetadataVersion:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(variMetadataString);
      if (variMetadataVersion == null) throw 'Could not read metadata ($variation) version.';

      var variMetadata:Null<SongMetadata> = SongRegistry.instance.parseEntryMetadataRawWithMigration(baseMetadataString, variMetadataPath, variMetadataVersion);
      if (variMetadata == null) throw 'Could not read metadata ($variation).';
      songMetadatas.set(variation, variMetadata);

      var variChartDataBytes:Null<Bytes> = mappedFileEntries.get(variChartDataPath)?.data;
      if (variChartDataBytes == null) throw 'Could not locate chart data ($variation).';
      var variChartDataString:String = variChartDataBytes.toString();
      var variChartDataVersion:Null<thx.semver.Version> = VersionUtil.getVersionFromJSON(variChartDataString);
      if (variChartDataVersion == null) throw 'Could not read chart data version ($variation).';

      var variChartData:Null<SongChartData> = SongRegistry.instance.parseEntryChartDataRawWithMigration(variChartDataString, variChartDataPath,
        variChartDataVersion);
      if (variChartData == null) throw 'Could not read chart data ($variation).';
      songChartDatas.set(variation, variChartData);
    }

    ChartEditorAudioHandler.wipeInstrumentalData(state);
    ChartEditorAudioHandler.wipeVocalData(state);

    // Load instrumentals
    for (variation in [Constants.DEFAULT_VARIATION].concat(variationList))
    {
      var variMetadata:Null<SongMetadata> = songMetadatas.get(variation);
      if (variMetadata == null) continue;

      var instId:String = variMetadata?.playData?.characters?.instrumental ?? '';
      var playerCharId:String = variMetadata?.playData?.characters?.player ?? Constants.DEFAULT_CHARACTER;
      var opponentCharId:Null<String> = variMetadata?.playData?.characters?.opponent;

      var instFileName:String = manifest.getInstFileName(instId);
      var instFileBytes:Null<Bytes> = mappedFileEntries.get(instFileName)?.data;
      if (instFileBytes != null)
      {
        if (!ChartEditorAudioHandler.loadInstFromBytes(state, instFileBytes, instId))
        {
          throw 'Could not load instrumental ($instFileName).';
        }
      }
      else
      {
        throw 'Could not find instrumental ($instFileName).';
      }

      var playerVocalsFileName:String = manifest.getVocalsFileName(playerCharId);
      var playerVocalsFileBytes:Null<Bytes> = mappedFileEntries.get(playerVocalsFileName)?.data;
      if (playerVocalsFileBytes != null)
      {
        if (!ChartEditorAudioHandler.loadVocalsFromBytes(state, playerVocalsFileBytes, playerCharId, instId))
        {
          warnings.push('Could not parse vocals ($playerCharId).');
          // throw 'Could not parse vocals ($playerCharId).';
        }
      }
      else
      {
        warnings.push('Could not find vocals ($playerVocalsFileName).');
        // throw 'Could not find vocals ($playerVocalsFileName).';
      }

      if (opponentCharId != null)
      {
        var opponentVocalsFileName:String = manifest.getVocalsFileName(opponentCharId);
        var opponentVocalsFileBytes:Null<Bytes> = mappedFileEntries.get(opponentVocalsFileName)?.data;
        if (opponentVocalsFileBytes != null)
        {
          if (!ChartEditorAudioHandler.loadVocalsFromBytes(state, opponentVocalsFileBytes, opponentCharId, instId))
          {
            warnings.push('Could not parse vocals ($opponentCharId).');
            // throw 'Could not parse vocals ($opponentCharId).';
          }
        }
        else
        {
          warnings.push('Could not find vocals ($opponentVocalsFileName).');
          // throw 'Could not find vocals ($opponentVocalsFileName).';
        }
      }
    }

    if (manifest.midiFile != null)
    {
      state.midiData = mappedFileEntries.get(manifest.midiFile)?.data;
      state.midiFile = manifest.midiFile;
    }

    // Apply chart data.
    trace(songMetadatas);
    trace(songChartDatas);
    loadSong(state, songMetadatas, songChartDatas);

    state.switchToCurrentInstrumental();

    return warnings;
  }

  public static function getLatestBackupPath():Null<String>
  {
    #if sys
    if (!sys.FileSystem.exists(BACKUPS_PATH)) sys.FileSystem.createDirectory(BACKUPS_PATH);

    var entries:Array<String> = sys.FileSystem.readDirectory(BACKUPS_PATH);
    entries.sort(SortUtil.alphabetically);

    var latestBackupPath:Null<String> = entries[(entries.length - 1)];

    if (latestBackupPath == null) return null;
    return haxe.io.Path.join([BACKUPS_PATH, latestBackupPath]);
    #else
    return null;
    #end
  }

  public static function getLatestBackupDate():Null<Date>
  {
    #if sys
    var latestBackupPath:Null<String> = getLatestBackupPath();
    if (latestBackupPath == null) return null;

    var latestBackupName:String = haxe.io.Path.withoutDirectory(latestBackupPath);
    latestBackupName = haxe.io.Path.withoutExtension(latestBackupName);

    var parts = latestBackupName.split('-');

    // var chart:String = parts[0];
    // var editor:String = parts[1];
    var year:Int = Std.parseInt(parts[2] ?? '0') ?? 0;
    var month:Int = Std.parseInt(parts[3] ?? '1') ?? 1;
    var day:Int = Std.parseInt(parts[4] ?? '0') ?? 0;
    var hour:Int = Std.parseInt(parts[5] ?? '0') ?? 0;
    var minute:Int = Std.parseInt(parts[6] ?? '0') ?? 0;
    var second:Int = Std.parseInt(parts[7] ?? '0') ?? 0;

    var date:Date = new Date(year, month - 1, day, hour, minute, second);
    return date;
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
    if (state.midiData != null) zipEntries.push(state.makeZIPEntryFromMidi());

    var manifest:ChartManifestData = new ChartManifestData(state.currentSongId, state.midiFile);
    zipEntries.push(FileUtil.makeZIPEntry('manifest.json', manifest.serialize()));

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
          'chart-editor-${DateUtil.generateTimestamp()}.${Constants.EXT_CHART}'
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
          trace('[WARN] Could not get save path.');
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
