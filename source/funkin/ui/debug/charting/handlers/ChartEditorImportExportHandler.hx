package funkin.ui.debug.charting.handlers;

import funkin.util.VersionUtil;
import haxe.ui.notifications.NotificationType;
import funkin.util.DateUtil;
import haxe.io.Path;
import funkin.util.SerializerUtil;
import haxe.ui.notifications.NotificationManager;
import funkin.util.FileUtil;
import funkin.util.FileUtil;
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
  /**
   * Fetch's a song's existing chart and audio and loads it, replacing the current song.
   */
  public static function loadSongAsTemplate(state:ChartEditorState, songId:String):Void
  {
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
      var metadataClone:SongMetadata = metadata.clone(variation);
      if (metadataClone != null) songMetadata.set(variation, metadataClone);

      var chartData:Null<SongChartData> = SongRegistry.instance.parseEntryChartData(songId, metadata.variation);
      if (chartData != null) songChartData.set(variation, chartData);
    }

    loadSong(state, songMetadata, songChartData);

    state.sortChartData();

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
    }

    for (difficultyId in song.listDifficulties())
    {
      var diff:Null<SongDifficulty> = song.getDifficulty(difficultyId);
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

    state.switchToCurrentInstrumental();

    state.refreshMetadataToolbox();

    #if !mac
    NotificationManager.instance.addNotification(
      {
        title: 'Success',
        body: 'Loaded song (${rawSongMetadata[0].songName})',
        type: NotificationType.Success,
        expiryMs: Constants.NOTIFICATION_DISMISS_TIME
      });
    #end
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

    Conductor.forceBPM(null); // Disable the forced BPM.
    Conductor.mapTimeChanges(state.currentSongMetadata.timeChanges);

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
    if (state.audioVocalTrackGroup != null)
    {
      state.audioVocalTrackGroup.stop();
      state.audioVocalTrackGroup.clear();
    }
  }

  public static function loadFromFNFCPath(state:ChartEditorState, path:String):Bool
  {
    var bytes:Null<Bytes> = FileUtil.readBytesFromPath(path);
    if (bytes == null) return false;

    trace('Loaded ${bytes.length} bytes from $path');

    var result:Bool = loadFromFNFC(state, bytes);
    if (result)
    {
      state.currentWorkingFilePath = path;
    }

    return result;
  }

  /**
   * Load a chart's metadata, chart data, and audio from an FNFC archive..
   * @param state
   * @param bytes
   * @param instId
   * @return Bool
   */
  public static function loadFromFNFC(state:ChartEditorState, bytes:Bytes):Bool
  {
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

    ChartEditorAudioHandler.stopExistingInstrumental(state);
    ChartEditorAudioHandler.stopExistingVocals(state);

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
          throw 'Could not load vocals ($playerCharId).';
        }
      }
      else
      {
        throw 'Could not find vocals ($playerVocalsFileName).';
      }

      if (opponentCharId != null)
      {
        var opponentVocalsFileName:String = manifest.getVocalsFileName(opponentCharId);
        var opponentVocalsFileBytes:Null<Bytes> = mappedFileEntries.get(opponentVocalsFileName)?.data;
        if (opponentVocalsFileBytes != null)
        {
          if (!ChartEditorAudioHandler.loadVocalsFromBytes(state, opponentVocalsFileBytes, opponentCharId, instId))
          {
            throw 'Could not load vocals ($opponentCharId).';
          }
        }
        else
        {
          throw 'Could not load vocals ($playerCharId-$instId).';
        }
      }
    }

    // Apply chart data.
    trace(songMetadatas);
    trace(songChartDatas);
    loadSong(state, songMetadatas, songChartDatas);

    state.switchToCurrentInstrumental();

    return true;
  }

  /**
   * @param force Whether to export without prompting. `false` will prompt the user for a location.
   * @param targetPath where to export if `force` is `true`. If `null`, will export to the `backups` folder.
   */
  public static function exportAllSongData(state:ChartEditorState, force:Bool = false, ?targetPath:String):Void
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
        if (variationMetadata != null) zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-metadata.json', variationMetadata.serialize()));
        var variationChart:Null<SongChartData> = state.songChartData.get(variation);
        if (variationChart != null) zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-chart.json', variationChart.serialize()));
      }
      else
      {
        var variationMetadata:Null<SongMetadata> = state.songMetadata.get(variation);
        if (variationMetadata != null) zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-metadata-$variationId.json',
          variationMetadata.serialize()));
        var variationChart:Null<SongChartData> = state.songChartData.get(variation);
        if (variationChart != null) zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-chart-$variationId.json', variationChart.serialize()));
      }
    }

    if (state.audioInstTrackData != null) zipEntries = zipEntries.concat(state.makeZIPEntriesFromInstrumentals());
    if (state.audioVocalTrackData != null) zipEntries = zipEntries.concat(state.makeZIPEntriesFromVocals());

    var manifest:ChartManifestData = new ChartManifestData(state.currentSongId);
    zipEntries.push(FileUtil.makeZIPEntry('manifest.json', manifest.serialize()));

    trace('Exporting ${zipEntries.length} files to ZIP...');

    if (force)
    {
      if (targetPath == null)
      {
        targetPath = Path.join([
          './backups/',
          'chart-editor-${DateUtil.generateTimestamp()}.${Constants.EXT_CHART}'
        ]);
      }

      // We have to force write because the program will die before the save dialog is closed.
      trace('Force exporting to $targetPath...');
      FileUtil.saveFilesAsZIPToPath(zipEntries, targetPath);
    }
    else
    {
      // Prompt and save.
      var onSave:Array<String>->Void = function(paths:Array<String>) {
        trace('Successfully exported files.');
      };

      var onCancel:Void->Void = function() {
        trace('Export cancelled.');
      };

      trace('Exporting to user-defined location...');
      try
      {
        FileUtil.saveChartAsFNFC(zipEntries, onSave, onCancel, '${state.currentSongId}.${Constants.EXT_CHART}');
      }
      catch (e) {}
    }
  }
}
