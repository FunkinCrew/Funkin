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
import haxe.io.Bytes;

/**
 * Utility functions for interacting with `.fnfc` files.
 */
@:nullSafety
class FNFCUtil
{
  /**
   * Open a song's chart from a `.fnfc` file and play it in the Play State.
   *
   * @param fnfcPath The absolute file path to the `.fnfc` file to load.
   * @param difficulty The difficulty level to play.
   * @param variation The variation of the song to play, such as "default", "erect", or "pico".
   */
  public static function playSongFromFNFCPath(fnfcPath:String, difficulty:String, variation:String):Void
  {
    var fnfcData:FNFCData = loadDataFromFNFCPath(fnfcPath);
    var targetSong:Song = loadSongFromFNFCData(fnfcData);

    var targetDifficulty:Null<SongDifficulty> = targetSong.getDifficulty(difficulty, variation);
    if (targetDifficulty == null) throw 'Could not find chart: $difficulty-$variation';

    // Instrumental audio
    var audioInstTrack:Null<FunkinSound> = null;
    var instBytes:Null<Bytes> = fnfcData.instrumentals.get(variation);
    if (instBytes == null) throw 'Could not find instrumental: $variation';
    audioInstTrack = SoundUtil.buildSoundFromBytes(instBytes);
    if (audioInstTrack == null) throw 'Could not load instrumental: $variation';

    var audioVocalTrackGroup = new VoicesGroup();

    // Player vocal audio
    var playerVocalList:Array<String> = targetDifficulty.characters.playerVocals ?? [];
    for (vocalId in playerVocalList)
    {
      var vocalBytes:Null<Bytes> = fnfcData.vocals.get(vocalId);
      if (vocalBytes == null) throw 'Could not find vocals: $vocalId';
      var audioVocalTrack:Null<FunkinSound> = SoundUtil.buildSoundFromBytes(vocalBytes);
      if (audioVocalTrack == null) throw 'Could not load vocals: $vocalId';

      audioVocalTrackGroup.addPlayerVoice(audioVocalTrack);
    }

    // Opponent vocal audio
    var opponentVocalList:Array<String> = targetDifficulty.characters.opponentVocals ?? [];
    for (vocalId in opponentVocalList)
    {
      var vocalBytes:Null<Bytes> = fnfcData.vocals.get(vocalId);
      if (vocalBytes == null) throw 'Could not find vocals: $vocalId';
      var audioVocalTrack:Null<FunkinSound> = SoundUtil.buildSoundFromBytes(vocalBytes);
      if (audioVocalTrack == null) throw 'Could not load vocals: $vocalId';

      audioVocalTrackGroup.addOpponentVoice(audioVocalTrack);
    }

    // Transition to the play state.
    LoadingState.loadPlayState({
      targetSong: targetSong,
      targetDifficulty: difficulty,
      targetVariation: variation,
      practiceMode: false,
      botPlayMode: false,
      minimalMode: false,
      startTimestamp: 0,
      playbackRate: 1,
      overrideMusic: true,
    }, false, true, function(targetState)
    {
      // Apply the instrumental and the vocals manually after the state loads.
      // overrideMusic ensures that the game doesn't attempt to load music from the game's assets folder.
      @:nullSafety(Off)
      FlxG.sound.music = audioInstTrack;
      targetState.vocals = audioVocalTrackGroup;
    });
  }

  /**
   * Load a song's data from an `.fnfc` file's zip entries.
   * This can be used to open the chart in the Chart Editor or Camera Editor.
   *
   * @param fnfcPath The absolute file path to the `.fnfc` file to load.
   * @param loadAudio Whether to additionally load the audio tracks from the `.fnfc` file.
   * @return An object containing the data from the `.fnfc` file, ready to be opened in a debug editor.
   */
  public static function loadDataFromFNFCPath(fnfcPath:String, loadAudio:Bool = true):FNFCData
  {
    return loadDataFromFNFCBytes(FileUtil.readBytesFromPath(fnfcPath), loadAudio);
  }

  /**
   * Load a song's data from an `.fnfc` file's zip entries.
   *
   * @param fnfcBytes The byte data of the `.fnfc` file to load.
   * @param loadAudio Whether to additionally load the audio tracks from the `.fnfc` file.
   * @return An object containing the data from the `.fnfc` file, ready to be opened in a debug editor.
   */
  public static function loadDataFromFNFCBytes(fnfcBytes:Bytes, loadAudio:Bool = true):FNFCData
  {
    var mappedFileEntries:Map<String, haxe.zip.Entry> = FileUtil.mapZIPEntriesByName(FileUtil.readZIPFromBytes(fnfcBytes));

    var manifest:ChartManifestData = loadChartManifestFromFNFCZipEntries(mappedFileEntries);

    var songId:String = manifest.songId;

    var songMetadatas:Map<String, SongMetadata> = [];
    var songChartDatas:Map<String, SongChartData> = [];

    // Default variation metadata
    var baseMetadata = loadSongMetadataFromFNFCZipEntries(mappedFileEntries, manifest, Constants.DEFAULT_VARIATION);
    songMetadatas.set(Constants.DEFAULT_VARIATION, baseMetadata);

    // Default variation chart data
    var baseChartData = loadSongChartDataFromFNFCZipEntries(mappedFileEntries, manifest, Constants.DEFAULT_VARIATION);
    songChartDatas.set(Constants.DEFAULT_VARIATION, baseChartData);

    // Additional variation metadata and chart data
    var variationList:Array<String> = baseMetadata.playData.songVariations;
    for (variation in variationList)
    {
      var metadata = loadSongMetadataFromFNFCZipEntries(mappedFileEntries, manifest, variation);
      songMetadatas.set(variation, metadata);

      var chartData = loadSongChartDataFromFNFCZipEntries(mappedFileEntries, manifest, variation);
      songChartDatas.set(variation, chartData);
    }

    // Instrumental and vocal audio data
    var instrumentals:Map<String, Bytes> = [];
    var vocals:Map<String, Bytes> = [];

    // Default variation instrumental and vocal audio data
    if (loadAudio)
    {
      var metadata:Null<SongMetadata> = songMetadatas.get(Constants.DEFAULT_VARIATION);
      if (metadata == null) throw 'Could not locate default variation metadata for audio loading.';

      var instBytes:Bytes = loadInstBytesFromFNFCZipEntries(mappedFileEntries, manifest, metadata);
      instrumentals.set(Constants.DEFAULT_VARIATION, instBytes);

      var vocalsBytes:Map<String, Bytes> = loadVocalBytesFromFNFCZipEntries(mappedFileEntries, manifest, metadata);
      vocals.append(vocalsBytes);
    }

    // Alternate variation instrumental and vocal audio data
    if (loadAudio)
    {
      for (variation in variationList)
      {
        var metadata:Null<SongMetadata> = songMetadatas.get(variation);
        if (metadata == null) throw 'Could not locate variation metadata for audio loading.';

        var instBytes:Bytes = loadInstBytesFromFNFCZipEntries(mappedFileEntries, manifest, metadata);
        instrumentals.set(variation, instBytes);

        var vocalsBytes:Map<String, Bytes> = loadVocalBytesFromFNFCZipEntries(mappedFileEntries, manifest, metadata);
        vocals.append(vocalsBytes);
      }
    }

    return {
      manifest: manifest,

      songMetadatas: songMetadatas,
      songChartDatas: songChartDatas,

      instrumentals: instrumentals,
      vocals: vocals,
    }
  }

  /**
   * Build the song data from an FNFC file into a Song object that can be played in the Play State.
   *
   * @param data The parsed data from an FNFC file.
   * @return A Song object that can be played in the Play State, that includes parsed metadata and chart data.
   */
  public static function loadSongFromFNFCData(data:FNFCData):Song
  {
    var songId:String = data.manifest.songId;
    var songMetadata:Array<SongMetadata> = data.songMetadatas.values();
    var songVariation:String = Constants.DEFAULT_VARIATION;
    var songChartDatas:Map<String, SongChartData> = data.songChartDatas;

    var includeScript:Bool = false;
    var validScore:Bool = false;

    return Song.buildRaw(songId, songMetadata, songVariation, songChartDatas, includeScript, validScore);
  }

  /**
   * Loads a song from an `.fnfc` file at the given path.
   *
   * @param fnfcPath The absolute file path to the `.fnfc` file to load.
   * @return A Song object containing the data from the `.fnfc` file, ready to be played in the Play State.
   */
  public static function loadSongFromFNFCPath(fnfcPath:String):Song
  {
    return loadSongFromFNFCData(loadDataFromFNFCPath(fnfcPath));
  }

  /**
   * Build the song data for a song from the game's assets folder into a song that can be parsed by one of the game's debug editors.
   * Useful for testing, or quickly getting started from an existing song's chart.
   *
   * @param songId The ID of the song to load.
   * @return An object containing the data for the chart, ready to save to an `.fnfc` file, or open in a debug editor.
   */
  public static function buildFNFCDataFromTemplate(songId:String, loadAudio:Bool = true):FNFCData
  {
    var song:Null<Song> = SongRegistry.instance.fetchEntry(songId);

    if (song == null) throw 'Could not find song with ID: $songId';

    var songManifest:ChartManifestData = new ChartManifestData(songId);
    var songMetadatas:Map<String, SongMetadata> = [];
    var songChartDatas:Map<String, SongChartData> = [];
    var instrumentals:Map<String, Bytes> = [];
    var vocals:Map<String, Bytes> = [];

    var rawSongMetadata:Array<SongMetadata> = song.getRawMetadata();

    // Load the song metadata and chart data
    for (metadata in rawSongMetadata)
    {
      if (metadata == null) continue;
      var variation:String = metadata.variation.isBlank() ? Constants.DEFAULT_VARIATION : metadata.variation;

      // Clone the metadata to prevent modifying the original in-place.
      var metadataClone:SongMetadata = metadata.clone();
      metadataClone.variation = variation;
      if (metadataClone != null) songMetadatas.set(variation, metadataClone);

      // Freshly parsed chart data.
      var chartData:Null<SongChartData> = SongRegistry.instance.parseEntryChartData(songId, metadata.variation);
      if (chartData != null) songChartDatas.set(variation, chartData);
    }

    // Load instrumental and vocal audio data
    if (loadAudio)
    {
      for (variation => metadata in songMetadatas)
      {
        if (metadata == null) continue;

        var instBytes:Bytes = loadInstBytesFromTemplate(songId, metadata);
        instrumentals.set(variation, instBytes);

        var vocalsBytes:Map<String, Bytes> = loadVocalBytesFromTemplate(songId, metadata);
        vocals.append(vocalsBytes);
      }
    }

    return {
      manifest: songManifest,

      songMetadatas: songMetadatas,
      songChartDatas: songChartDatas,

      instrumentals: instrumentals,
      vocals: vocals,
    }
  }

  static function loadInstBytesFromFNFCZipEntries(mappedFileEntries:Map<String, haxe.zip.Entry>, manifest:ChartManifestData, metadata:SongMetadata):Bytes
  {
    var instId:String = metadata?.playData?.characters?.instrumental ?? '';
    var instFileName:String = manifest.getInstFileName(instId);
    var instBytes:Bytes = loadBytesFromFNFCZipEntries(mappedFileEntries, instFileName);
    return instBytes;
  }

  static function loadInstBytesFromTemplate(songId:String, metadata:SongMetadata):Bytes
  {
    var instId:String = metadata?.playData?.characters?.instrumental ?? '';
    var instFileName:String = funkin.Paths.inst(songId, instId == '' ? '' : '-$instId');

    var instBytes:Null<Bytes> = Assets.getBytes(instFileName);
    if (instBytes == null) throw 'Could not load instrumental: $instFileName';

    return instBytes;
  }

  static function loadVocalBytesFromFNFCZipEntries(mappedFileEntries:Map<String, haxe.zip.Entry>, manifest:ChartManifestData,
      metadata:SongMetadata):Map<String, Bytes>
  {
    var vocals:Map<String, Bytes> = [];

    var variation:String = metadata.variation.isBlank() ? Constants.DEFAULT_VARIATION : metadata.variation;

    // Get the player vocal list and opponent vocal list
    // If either are null, default to the player and opponent characters
    // If either are empty, don't load vocals for them
    var playerVoiceList:Array<String> = metadata?.playData.characters?.playerVocals ?? [
      metadata?.playData?.characters?.player ?? Constants.DEFAULT_CHARACTER
    ];
    var opponentVoiceList:Array<String> = metadata?.playData.characters?.opponentVocals ?? [
      metadata?.playData?.characters?.opponent ?? 'dad'
    ];
    var voicesList:Array<String> = playerVoiceList.concat(opponentVoiceList);

    for (voiceId in voicesList)
    {
      var trackKeySuffix:String = (variation.isBlank() || variation == Constants.DEFAULT_VARIATION) ? '' : '-${variation}';
      var trackKey:String = '$voiceId$trackKeySuffix';
      // For example, for voice ID "bf" on variation "pico", the file name would be "Voices-bf-pico.ogg"

      var voiceFileName:String = manifest.getVocalsFileName(voiceId, metadata.variation);
      var voiceBytes:Bytes = loadBytesFromFNFCZipEntries(mappedFileEntries, voiceFileName);
      vocals.set(trackKey, voiceBytes);
    }

    return vocals;
  }

  static function loadVocalBytesFromTemplate(songId:String, metadata:SongMetadata):Map<String, Bytes>
  {
    var vocals:Map<String, Bytes> = [];

    var variation:String = metadata.variation.isBlank() ? Constants.DEFAULT_VARIATION : metadata.variation;

    // Get the player vocal list and opponent vocal list
    // If either are null, default to the player and opponent characters
    // If either are empty, don't load vocals for them
    var playerVoiceList:Array<String> = metadata?.playData.characters?.playerVocals ?? [
      metadata?.playData?.characters?.player ?? Constants.DEFAULT_CHARACTER
    ];
    var opponentVoiceList:Array<String> = metadata?.playData.characters?.opponentVocals ?? [
      metadata?.playData?.characters?.opponent ?? 'dad'
    ];
    var voicesList:Array<String> = playerVoiceList.concat(opponentVoiceList);

    for (voiceId in voicesList)
    {
      var trackKeySuffix:String = (variation.isBlank() || variation == Constants.DEFAULT_VARIATION) ? '' : '-${variation}';
      var trackKey:String = '$voiceId$trackKeySuffix';
      // For example, for voice ID "bf" on variation "pico", the file name would be "Voices-bf-pico.ogg"

      // CUE AWFUL SUFFIX-STRIPPING LOGIC
      // TODO: Merge this with the logic in Song.buildPlayerVoiceList()

      var originalVoiceId:String = voiceId;
      var voicePath:Null<String> = funkin.Paths.voices(songId, '-$voiceId$trackKeySuffix');

      while (voicePath != null && !Assets.exists(voicePath))
      {
        // Continously strip the suffix (leaving the variation) until we find a valid voice file.
        // For example if "Voices-bf-car-pico.ogg" doesn't exist, try "Voices-bf-pico.ogg"
        voiceId = voiceId.split('-').slice(0, -1).join('-');
        voicePath = voiceId == '' ? null : funkin.Paths.voices(songId, '-$voiceId$trackKeySuffix');
      }
      if (voicePath == null)
      {
        voiceId = originalVoiceId;
        voicePath = funkin.Paths.voices(songId, '-$voiceId');
        while (voicePath != null && !Assets.exists(voicePath))
        {
          // Continously strip the suffix (omitting the variation) until we find a valid voice file.
          // For example if "Voices-bf-car.ogg" doesn't exist, try "Voices-bf.ogg"
          voiceId = voiceId.split('-').slice(0, -1).join('-');
          voicePath = voiceId == '' ? null : funkin.Paths.voices(songId, '-$voiceId');
        }
      }

      if (voicePath == null)
      {
        var originalVoicePath:String = funkin.Paths.voices(songId, '-$originalVoiceId$trackKeySuffix');
        throw 'Could not locate vocal track: $originalVoicePath';
      }

      var voiceBytes:Null<Bytes> = Assets.getBytes(voicePath);
      if (voiceBytes == null) throw 'Could not load vocals: $voicePath';
      vocals.set(trackKey, voiceBytes);
    }

    return vocals;
  }

  /**
   * Load the chart manifest from an FNFC file's zip entries.
   *
   * @param mappedFileEntries The zip entries from an FNFC file.
   * @throws error If the manifest could not be loaded.
   * @return The parsed ChartManifestData object.
   */
  static function loadChartManifestFromFNFCZipEntries(mappedFileEntries:Map<String, haxe.zip.Entry>):ChartManifestData
  {
    var manifestStr:Null<String> = loadStringFromFNFCZipEntries(mappedFileEntries, 'manifest.json');

    var manifest:ChartManifestData = ChartManifestData.deserialize(manifestStr) ?? throw 'Could not parse manifest.';

    return manifest;
  }

  /**
   * Load the metadata for a song variation from an FNFC file's zip entries.
   *
   * @param mappedFileEntries The zip entries from an FNFC file.
   * @param manifest The chart manifest data, usually parsed from that FNFC file.
   * @param variation The name of the song variation to load.
   * @return The metadata for that song variation.
   */
  static function loadSongMetadataFromFNFCZipEntries(mappedFileEntries:Map<String, haxe.zip.Entry>, manifest:ChartManifestData, variation:String):SongMetadata
  {
    var metadataPath:String = manifest.getMetadataFileName(variation);

    var metadataStr:String = loadStringFromFNFCZipEntries(mappedFileEntries, metadataPath);

    var metadataVersion:Null<SemverVersion> = VersionUtil.getVersionFromJSON(metadataStr);
    if (metadataVersion == null) throw 'Could not parse metadata version ($variation).';

    var metadata:Null<SongMetadata> = SongRegistry.instance.parseEntryMetadataRawWithMigration(metadataStr, metadataPath, metadataVersion, variation);
    if (metadata == null) throw 'Could not parse metadata ($variation).';

    return metadata;
  }

  /**
   * Load the chart data for a song variation from an FNFC file's zip entries.
   *
   * @param mappedFileEntries The zip entries from an FNFC file.
   * @param manifest The chart manifest data, usually parsed from that FNFC file.
   * @param variation The name of the song variation to load.
   * @return The chart data for that song variation.
   */
  static function loadSongChartDataFromFNFCZipEntries(mappedFileEntries:Map<String, haxe.zip.Entry>, manifest:ChartManifestData, variation:String):SongChartData
  {
    var chartDataPath:String = manifest.getChartDataFileName(variation);

    var chartDataStr:String = loadStringFromFNFCZipEntries(mappedFileEntries, chartDataPath);

    var chartDataVersion:Null<SemverVersion> = VersionUtil.getVersionFromJSON(chartDataStr);
    if (chartDataVersion == null) throw 'Could not read chart data version (default).';

    var chartData:Null<SongChartData> = SongRegistry.instance.parseEntryChartDataRawWithMigration(chartDataStr, chartDataPath, chartDataVersion);
    if (chartData == null) throw 'Could not read chart data (default).';

    return chartData;
  }

  /**
   * Read the string data of a file from an FNFC file's zip entries.
   *
   * @param mappedFileEntries The zip entries from an FNFC file.
   * @param fileName The name of the file to load.
   * @return The string data of the file.
   */
  static function loadStringFromFNFCZipEntries(mappedFileEntries:Map<String, haxe.zip.Entry>, fileName:String):String
  {
    return loadBytesFromFNFCZipEntries(mappedFileEntries, fileName).toString();
  }

  /**
   * Read the byte data of a file from an FNFC file's zip entries.
   *
   * @param mappedFileEntries The zip entries from an FNFC file.
   * @param fileName The name of the file to load.
   * @return The byte data of the file.
   */
  static function loadBytesFromFNFCZipEntries(mappedFileEntries:Map<String, haxe.zip.Entry>, fileName:String):Bytes
  {
    var data:Null<haxe.zip.Entry> = mappedFileEntries.get(fileName);
    if (data == null || data.data == null) throw 'Could not locate file: $fileName';

    return data.data;
  }

  /**
   * Construct a list of ZIP file entries from the data of a chart, so that it can be written as an `.fnfc` file.
   *
   * @param data The data of the chart to write.
   * @return A list of ZIP file entries that can be written to disk.
   */
  public static function buildZIPEntriesFromFNFCData(data:FNFCData):Array<haxe.zip.Entry>
  {
    var zipEntries:Array<haxe.zip.Entry> = [];

    var songId:String = data.manifest.songId;

    zipEntries.push(FileUtil.makeZIPEntry('manifest.json', data.manifest.serialize()));

    for (variation => metadata in data.songMetadatas)
    {
      var chartData:Null<SongChartData> = data.songChartDatas.get(variation);
      if (chartData == null) throw 'Could not find chart data for variation: $variation';

      metadata.version = funkin.data.song.SongRegistry.SONG_METADATA_VERSION;
      metadata.generatedBy = funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY;

      chartData.version = funkin.data.song.SongRegistry.SONG_CHART_DATA_VERSION;
      chartData.generatedBy = funkin.data.song.SongRegistry.DEFAULT_GENERATEDBY;

      if (variation == Constants.DEFAULT_VARIATION)
      {
        zipEntries.push(FileUtil.makeZIPEntry('${songId}-metadata.json', metadata.serialize()));
        zipEntries.push(FileUtil.makeZIPEntry('${songId}-chart.json', chartData.serialize()));
      }
      else
      {
        zipEntries.push(FileUtil.makeZIPEntry('${songId}-metadata-${variation}.json', metadata.serialize()));
        zipEntries.push(FileUtil.makeZIPEntry('${songId}-chart-${variation}.json', chartData.serialize()));
      }
    }

    zipEntries.append(buildZIPEntriesFromInstrumentals(songId, data.instrumentals));
    zipEntries.append(buildZIPEntriesFromVocals(songId, data.vocals));

    return zipEntries;
  }

  static function buildZIPEntriesFromInstrumentals(songId:String, instrumentals:Map<String, Bytes>):Array<haxe.zip.Entry>
  {
    var zipEntries:Array<haxe.zip.Entry> = [];

    for (key => data in instrumentals)
    {
      if (key == Constants.DEFAULT_VARIATION)
      {
        zipEntries.push(FileUtil.makeZIPEntryFromBytes('Inst.ogg', data));
      }
      else
      {
        zipEntries.push(FileUtil.makeZIPEntryFromBytes('Inst-${key}.ogg', data));
      }
    }

    return zipEntries;
  }

  static function buildZIPEntriesFromVocals(songId:String, vocals:Map<String, Bytes>):Array<haxe.zip.Entry>
  {
    var zipEntries:Array<haxe.zip.Entry> = [];

    for (key => data in vocals)
    {
      zipEntries.push(FileUtil.makeZIPEntryFromBytes('Voices-${key}.ogg', data));
    }

    return zipEntries;
  }
}

/**
 * The data contained in an FNFC file.
 */
typedef FNFCData =
{
  // A central `manifest` file, containing data used to parse the rest of the file.
  var manifest:ChartManifestData;
  // JSON metadata for each variation
  var songMetadatas:Map<String, SongMetadata>;
  // JSON chart data for each variation
  var songChartDatas:Map<String, SongChartData>;
  // Instrumental audio tracks
  var instrumentals:Map<String, Bytes>;
  // Vocal audio tracks
  var vocals:Map<String, Bytes>;
}
#end
