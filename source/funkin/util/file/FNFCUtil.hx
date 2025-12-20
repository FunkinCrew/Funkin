package funkin.util.file;

#if sys
import funkin.data.song.SongData.SongChartData;
import funkin.ui.transition.LoadingState;
import funkin.audio.FunkinSound;
import funkin.util.assets.SoundUtil;
import funkin.data.song.importer.ChartManifestData;
import funkin.data.song.SongRegistry;
import funkin.audio.VoicesGroup;
import funkin.data.song.SongData.SongMetadata;
import funkin.play.song.Song;
import thx.semver.Version as SemverVersion;

/**
 * Utility functions for interacting with .FNFC files.
 */
@:nullSafety
class FNFCUtil
{
  /**
   * Loads a song from
   * @param fnfcPath The absolute file path to the .FNFC file to load.
   */
  public static function loadSongFromFNFCPath(fnfcPath:String):Song
  {
    var fileBytes = sys.io.File.getBytes(fnfcPath);
    var fileEntries:Array<haxe.zip.Entry> = FileUtil.readZIPFromBytes(fileBytes);
    var mappedFileEntries:Map<String, haxe.zip.Entry> = FileUtil.mapZIPEntriesByName(fileEntries);

    var manifest:ChartManifestData = loadChartManifestFromFNFCZipEntries(mappedFileEntries);

    return loadSongFromFNFCZipEntries(mappedFileEntries, manifest);
  }

  /**
   * Open a song's chart from a .FNFC file and play it in the Play State.
   * @param fnfcPath The absolute file path to the .FNFC file to load.
   * @param difficulty The difficulty level to play.
   * @param variation The variation of the song to play, such as "default", "erect", or "pico".
   */
  public static function playSongFromFNFCPath(fnfcPath:String, difficulty:String, variation:String):Void
  {
    var fileBytes = sys.io.File.getBytes(fnfcPath);
    var fileEntries:Array<haxe.zip.Entry> = FileUtil.readZIPFromBytes(fileBytes);
    var mappedFileEntries:Map<String, haxe.zip.Entry> = FileUtil.mapZIPEntriesByName(fileEntries);

    var manifest:ChartManifestData = loadChartManifestFromFNFCZipEntries(mappedFileEntries);

    var targetSong:Song = loadSongFromFNFCZipEntries(mappedFileEntries, manifest);
    var targetDifficulty:Null<SongDifficulty> = targetSong.getDifficulty(difficulty, variation);

    if (targetDifficulty == null) throw 'Could not find chart: $difficulty-$variation';

    var audioInstTrack:Null<FunkinSound> = null;
    var audioVocalTrackGroup = new VoicesGroup();

    var instId:String = targetDifficulty.characters.instrumental ?? '';
    var audioInstTrackName:String = manifest.getInstFileName(instId);
    try
    {
      audioInstTrack = loadSoundFromFNFCZipEntries(mappedFileEntries, audioInstTrackName);
    }
    catch (e)
    {
      throw 'Could not load instrumental: $audioInstTrackName';
    }

    if (audioInstTrack == null) throw 'Could not load instrumental: $audioInstTrackName';

    // Load the player vocals.
    var playerVocalList:Array<String> = targetDifficulty.characters.playerVocals ?? [];
    for (playerVocalId in playerVocalList)
    {
      var audioVocalTrackName:String = manifest.getVocalsFileName(playerVocalId, variation);
      var audioVocalTrack = loadSoundFromFNFCZipEntries(mappedFileEntries, audioVocalTrackName);
      try
      {
        audioVocalTrackGroup.addPlayerVoice(audioVocalTrack);
      }
      catch (e)
      {
        throw 'Could not load vocals: $audioVocalTrackName';
      }
    }

    // Load the opponent vocals.
    var opponentVocalList:Array<String> = targetDifficulty.characters.opponentVocals ?? [];
    for (opponentVocalId in opponentVocalList)
    {
      var audioVocalTrackName:String = manifest.getVocalsFileName(opponentVocalId, variation);
      var audioVocalTrack = loadSoundFromFNFCZipEntries(mappedFileEntries, audioVocalTrackName);
      try
      {
        audioVocalTrackGroup.addOpponentVoice(audioVocalTrack);
      }
      catch (e)
      {
        throw 'Could not load vocals: $audioVocalTrackName';
      }
    }

    // Transition to the play state.
    LoadingState.loadPlayState(
      {
        targetSong: targetSong,
        targetDifficulty: difficulty,
        targetVariation: variation,
        practiceMode: false,
        botPlayMode: false,
        minimalMode: false,
        startTimestamp: 0,
        playbackRate: 1,
        overrideMusic: true,
      }, false, true, function(targetState) {
        // Apply the instrumental and the vocals manually after the state loads.
        // overrideMusic ensures that the game doesn't attempt to load music from the game's assets folder.
        @:nullSafety(Off)
        FlxG.sound.music = audioInstTrack;
        targetState.vocals = audioVocalTrackGroup;
      });
  }

  static function loadSoundFromFNFCZipEntries(mappedFileEntries:Map<String, haxe.zip.Entry>, soundName:String):FunkinSound
  {
    var soundData:Null<haxe.zip.Entry> = mappedFileEntries.get(soundName);
    if (soundData == null) throw 'Could not locate sound: $soundName';

    var vocalTrack:Null<FunkinSound> = SoundUtil.buildSoundFromBytes(soundData.data);
    if (vocalTrack == null) throw 'Could not parse sound: $soundName';

    return vocalTrack;
  }

  static function loadChartManifestFromFNFCZipEntries(mappedFileEntries:Map<String, haxe.zip.Entry>):ChartManifestData
  {
    var manifestData:Null<haxe.zip.Entry> = mappedFileEntries.get('manifest.json');
    if (manifestData == null) throw 'Could not locate manifest.';

    var manifestString:Null<String> = manifestData?.data?.toString();
    if (manifestString == null) throw 'Could not read manifest.';

    var manifest:ChartManifestData = ChartManifestData.deserialize(manifestString) ?? throw 'Could not parse manifest.';

    return manifest;
  }

  static function loadSongFromFNFCZipEntries(mappedFileEntries:Map<String, haxe.zip.Entry>, manifest:ChartManifestData):Song
  {
    var songId:String = manifest.songId;

    // id-metadata.json

    var baseMetadataPath:String = manifest.getMetadataFileName();
    var baseMetadataString:String = mappedFileEntries.get(baseMetadataPath)?.data?.toString() ?? throw 'Could not locate metadata (default).';
    var baseMetadataVersion:SemverVersion = VersionUtil.getVersionFromJSON(baseMetadataString) ?? throw 'Could not read metadata version (default).';
    var baseMetadata:SongMetadata = SongRegistry.instance.parseEntryMetadataRawWithMigration(baseMetadataString, baseMetadataPath,
      baseMetadataVersion) ?? throw 'Could not read metadata (default).';

    var songMetadatas:Map<String, SongMetadata> = [];
    songMetadatas.set(Constants.DEFAULT_VARIATION, baseMetadata);

    // id-chart.json

    var baseChartDataPath:String = manifest.getChartDataFileName();
    var baseChartDataString:String = mappedFileEntries.get(baseChartDataPath)?.data?.toString() ?? throw 'Could not locate chart data (default).';
    var baseChartDataVersion:SemverVersion = VersionUtil.getVersionFromJSON(baseChartDataString) ?? throw 'Could not read chart data version (default).';
    var baseChartData:SongChartData = SongRegistry.instance.parseEntryChartDataRawWithMigration(baseChartDataString, baseChartDataPath,
      baseChartDataVersion) ?? throw 'Could not read chart data (default).';

    var songChartDatas:Map<String, SongChartData> = [];
    songChartDatas.set(Constants.DEFAULT_VARIATION, baseChartData);

    // Variation metadata and chart data

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
        variChartDataVersion) ?? throw 'Could not read chart data ($variation).';

      songChartDatas.set(variation, variChartData);
    }

    // Combine into a Song object that can be played in PlayState.
    var song = Song.buildRaw(songId, songMetadatas.values(), variationList, songChartDatas, false, false);

    return song;
  }
}
#end
