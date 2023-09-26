package funkin.ui.debug.charting;

import haxe.ui.notifications.NotificationType;
import funkin.util.DateUtil;
import haxe.io.Path;
import funkin.util.SerializerUtil;
import haxe.ui.notifications.NotificationManager;
import funkin.util.FileUtil;
import funkin.util.FileUtil;
import funkin.play.song.Song;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongRegistry;

/**
 * Contains functions for importing, loading, saving, and exporting charts.
 */
@:nullSafety
@:allow(funkin.ui.debug.charting.ChartEditorState)
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

    state.clearVocals();

    var variations:Array<String> = state.availableVariations;
    for (variation in variations)
    {
      if (variation == Constants.DEFAULT_VARIATION)
      {
        ChartEditorAudioHandler.loadInstFromAsset(state, Paths.inst(songId));
      }
      else
      {
        ChartEditorAudioHandler.loadInstFromAsset(state, Paths.inst(songId, '-$variation'), variation);
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
        ChartEditorAudioHandler.loadVocalsFromAsset(state, voiceList[0], diff.characters.player, instId);
        ChartEditorAudioHandler.loadVocalsFromAsset(state, voiceList[1], diff.characters.opponent, instId);
      }
      else if (voiceList.length == 1)
      {
        ChartEditorAudioHandler.loadVocalsFromAsset(state, voiceList[0], diff.characters.player, instId);
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
        expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
      });
    #end
  }

  /**
   * Loads song metadata and chart data into the editor.
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

  /**
   * @param force Whether to force the export without prompting the user for a file location.
   * @param tmp If true, save to the temporary directory instead of the local `backup` directory.
   */
  public static function exportAllSongData(state:ChartEditorState, force:Bool = false, tmp:Bool = false):Void
  {
    var zipEntries:Array<haxe.zip.Entry> = [];

    for (variation in state.availableVariations)
    {
      var variationId:String = variation;
      if (variation == '' || variation == 'default' || variation == 'normal')
      {
        variationId = '';
      }

      if (variationId == '')
      {
        var variationMetadata:Null<SongMetadata> = state.songMetadata.get(variation);
        if (variationMetadata != null) zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-metadata.json', SerializerUtil.toJSON(variationMetadata)));
        var variationChart:Null<SongChartData> = state.songChartData.get(variation);
        if (variationChart != null) zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-chart.json', SerializerUtil.toJSON(variationChart)));
      }
      else
      {
        var variationMetadata:Null<SongMetadata> = state.songMetadata.get(variation);
        if (variationMetadata != null) zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-metadata-$variationId.json',
          SerializerUtil.toJSON(variationMetadata)));
        var variationChart:Null<SongChartData> = state.songChartData.get(variation);
        if (variationChart != null) zipEntries.push(FileUtil.makeZIPEntry('${state.currentSongId}-chart-$variationId.json',
          SerializerUtil.toJSON(variationChart)));
      }
    }

    if (state.audioInstTrackData != null) zipEntries.concat(ChartEditorAudioHandler.makeZIPEntriesFromInstrumentals(state));
    if (state.audioVocalTrackData != null) zipEntries.concat(ChartEditorAudioHandler.makeZIPEntriesFromVocals(state));

    trace('Exporting ${zipEntries.length} files to ZIP...');

    if (force)
    {
      var targetPath:String = if (tmp)
      {
        Path.join([
          FileUtil.getTempDir(),
          'chart-editor-exit-${DateUtil.generateTimestamp()}.${Constants.EXT_CHART}'
        ]);
      }
      else
      {
        Path.join([
          './backups/',
          'chart-editor-exit-${DateUtil.generateTimestamp()}.${Constants.EXT_CHART}'
        ]);
      }

      // We have to force write because the program will die before the save dialog is closed.
      trace('Force exporting to $targetPath...');
      FileUtil.saveFilesAsZIPToPath(zipEntries, targetPath);
      return;
    }

    // Prompt and save.
    var onSave:Array<String>->Void = function(paths:Array<String>) {
      trace('Successfully exported files.');
    };

    var onCancel:Void->Void = function() {
      trace('Export cancelled.');
    };

    FileUtil.saveMultipleFiles(zipEntries, onSave, onCancel, '${state.currentSongId}-chart.${Constants.EXT_CHART}');
  }
}
