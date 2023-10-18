package funkin.play.song;

import funkin.util.SortUtil;
import flixel.sound.FlxSound;
import openfl.utils.Assets;
import funkin.modding.events.ScriptEvent;
import funkin.modding.IScriptedClass;
import funkin.audio.VoicesGroup;
import funkin.data.song.SongRegistry;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongRegistry;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongData.SongTimeChange;
import funkin.data.song.SongData.SongTimeFormat;
import funkin.data.IRegistryEntry;

/**
 * This is a data structure managing information about the current song.
 * This structure is created when the game starts, and includes all the data
 * from the `metadata.json` file.
 * It also includes the chart data, but only when this is the currently loaded song.
 *
 * It also receives script events; scripted classes which extend this class
 * can be used to perform custom gameplay behaviors only on specific songs.
 */
@:nullSafety
class Song implements IPlayStateScriptedClass implements IRegistryEntry<SongMetadata>
{
  public static final DEFAULT_SONGNAME:String = "Unknown";
  public static final DEFAULT_ARTIST:String = "Unknown";
  public static final DEFAULT_TIMEFORMAT:SongTimeFormat = SongTimeFormat.MILLISECONDS;
  public static final DEFAULT_DIVISIONS:Null<Int> = null;
  public static final DEFAULT_LOOPED:Bool = false;
  public static final DEFAULT_STAGE:String = "mainStage";
  public static final DEFAULT_SCROLLSPEED:Float = 1.0;

  public final id:String;

  /**
   * Song metadata as parsed from the JSON file.
   * This is the data for the `default` variation specifically,
   * and is needed for the IRegistryEntry interface.
   * Will only be null if the song data could not be loaded.
   */
  public final _data:Null<SongMetadata>;

  final _metadata:Array<SongMetadata>;

  final variations:Array<String>;
  final difficulties:Map<String, SongDifficulty>;

  /**
   * Set to false if the song was edited in the charter and should not be saved as a high score.
   */
  public var validScore:Bool = true;

  public var songName(get, never):String;

  function get_songName():String
  {
    if (_data != null) return _data?.songName ?? DEFAULT_SONGNAME;
    if (_metadata.length > 0) return _metadata[0]?.songName ?? DEFAULT_SONGNAME;
    return DEFAULT_SONGNAME;
  }

  public var songArtist(get, never):String;

  function get_songArtist():String
  {
    if (_data != null) return _data?.artist ?? DEFAULT_ARTIST;
    if (_metadata.length > 0) return _metadata[0]?.artist ?? DEFAULT_ARTIST;
    return DEFAULT_ARTIST;
  }

  /**
   * @param id The ID of the song to load.
   * @param ignoreErrors If false, an exception will be thrown if the song data could not be loaded.
   */
  public function new(id:String)
  {
    this.id = id;

    variations = [];
    difficulties = new Map<String, SongDifficulty>();

    _data = _fetchData(id);

    _metadata = _data == null ? [] : [_data];

    variations.clear();
    variations.push(Constants.DEFAULT_VARIATION);

    if (_data != null && _data.playData != null)
    {
      for (vari in _data.playData.songVariations)
        variations.push(vari);
    }

    for (meta in fetchVariationMetadata(id))
      _metadata.push(meta);

    if (_metadata.length == 0)
    {
      trace('[WARN] Could not find song data for songId: $id');
      return;
    }

    populateDifficulties();
  }

  @:allow(funkin.play.song.Song)
  public static function buildRaw(songId:String, metadata:Array<SongMetadata>, variations:Array<String>, charts:Map<String, SongChartData>,
      validScore:Bool = false):Song
  {
    var result:Song = new Song(songId);

    result._metadata.clear();
    for (meta in metadata)
      result._metadata.push(meta);

    result.variations.clear();
    for (vari in variations)
      result.variations.push(vari);

    result.difficulties.clear();
    result.populateDifficulties();

    for (variation => chartData in charts)
      result.applyChartData(chartData, variation);

    result.validScore = validScore;

    return result;
  }

  public function getRawMetadata():Array<SongMetadata>
  {
    return _metadata;
  }

  /**
   * Populate the difficulty data from the provided metadata.
   * Does not load chart data (that is triggered later when we want to play the song).
   */
  function populateDifficulties():Void
  {
    if (_metadata == null || _metadata.length == 0) return;

    // Variations may have different artist, time format, generatedBy, etc.
    for (metadata in _metadata)
    {
      if (metadata == null || metadata.playData == null) continue;

      // There may be more difficulties in the chart file than in the metadata,
      // (i.e. non-playable charts like the one used for Pico on the speaker in Stress)
      // but all the difficulties in the metadata must be in the chart file.
      for (diffId in metadata.playData.difficulties)
      {
        var difficulty:SongDifficulty = new SongDifficulty(this, diffId, metadata.variation);

        variations.push(metadata.variation);

        difficulty.songName = metadata.songName;
        difficulty.songArtist = metadata.artist;
        difficulty.timeFormat = metadata.timeFormat;
        difficulty.divisions = metadata.divisions;
        difficulty.timeChanges = metadata.timeChanges;
        difficulty.looped = metadata.looped;
        difficulty.generatedBy = metadata.generatedBy;

        difficulty.stage = metadata.playData.stage;
        difficulty.noteStyle = metadata.playData.noteSkin;

        difficulties.set(diffId, difficulty);

        difficulty.characters = metadata.playData.characters;
      }
    }
  }

  /**
   * Parse and cache the chart for all difficulties of this song.
   */
  public function cacheCharts(force:Bool = false):Void
  {
    if (force)
    {
      clearCharts();
    }

    trace('Caching ${variations.length} chart files for song $id');
    for (variation in variations)
    {
      var version:Null<thx.semver.Version> = SongRegistry.instance.fetchEntryChartVersion(id, variation);
      if (version == null) continue;
      var chart:Null<SongChartData> = SongRegistry.instance.parseEntryChartDataWithMigration(id, variation, version);
      if (chart == null) continue;
      applyChartData(chart, variation);
    }
    trace('Done caching charts.');
  }

  function applyChartData(chartData:SongChartData, variation:String):Void
  {
    var chartNotes = chartData.notes;

    for (diffId in chartNotes.keys())
    {
      // Retrieve the cached difficulty data.
      var difficulty:Null<SongDifficulty> = difficulties.get(diffId);
      if (difficulty == null)
      {
        trace('Fabricated new difficulty for $diffId.');
        difficulty = new SongDifficulty(this, diffId, variation);
        difficulties.set(diffId, difficulty);
      }
      // Add the chart data to the difficulty.
      difficulty.notes = chartNotes.get(diffId) ?? [];
      difficulty.scrollSpeed = chartData.getScrollSpeed(diffId) ?? 1.0;

      difficulty.events = chartData.events;
    }
  }

  /**
   * Retrieve the metadata for a specific difficulty, including the chart if it is loaded.
   * @param diffId The difficulty ID, such as `easy` or `hard`.
   * @return The difficulty data.
   */
  public inline function getDifficulty(?diffId:String):Null<SongDifficulty>
  {
    if (diffId == null) diffId = listDifficulties()[0];

    return difficulties.get(diffId);
  }

  /**
   * List all the difficulties in this song.
   * @param variationId Optionally filter by variation.
   * @return The list of difficulties.
   */
  public function listDifficulties(?variationId:String):Array<String>
  {
    if (variationId == '') variationId = null;

    var diffFiltered:Array<String> = difficulties.keys().array().filter(function(diffId:String):Bool {
      if (variationId == null) return true;
      var difficulty:Null<SongDifficulty> = difficulties.get(diffId);
      if (difficulty == null) return false;
      return difficulty.variation == variationId;
    });

    diffFiltered.sort(SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_DIFFICULTY_LIST));

    return diffFiltered;
  }

  public function hasDifficulty(diffId:String, ?variationId:String):Bool
  {
    if (variationId == '') variationId = null;
    var difficulty:Null<SongDifficulty> = difficulties.get(diffId);
    return variationId == null ? (difficulty != null) : (difficulty != null && difficulty.variation == variationId);
  }

  /**
   * Purge the cached chart data for each difficulty of this song.
   */
  public function clearCharts():Void
  {
    for (diff in difficulties)
    {
      diff.clearChart();
    }
  }

  public function toString():String
  {
    return 'Song($id)';
  }

  public function destroy():Void {}

  public function onPause(event:PauseScriptEvent):Void {};

  public function onResume(event:ScriptEvent):Void {};

  public function onSongLoaded(event:SongLoadScriptEvent):Void {};

  public function onSongStart(event:ScriptEvent):Void {};

  public function onSongEnd(event:ScriptEvent):Void {};

  public function onGameOver(event:ScriptEvent):Void {};

  public function onSongRetry(event:ScriptEvent):Void {};

  public function onNoteHit(event:NoteScriptEvent):Void {};

  public function onNoteMiss(event:NoteScriptEvent):Void {};

  public function onNoteGhostMiss(event:GhostMissNoteScriptEvent):Void {};

  public function onSongEvent(event:SongEventScriptEvent):Void {};

  public function onStepHit(event:SongTimeScriptEvent):Void {};

  public function onBeatHit(event:SongTimeScriptEvent):Void {};

  public function onCountdownStart(event:CountdownScriptEvent):Void {};

  public function onCountdownStep(event:CountdownScriptEvent):Void {};

  public function onCountdownEnd(event:CountdownScriptEvent):Void {};

  public function onScriptEvent(event:ScriptEvent):Void {};

  public function onCreate(event:ScriptEvent):Void {};

  public function onDestroy(event:ScriptEvent):Void {};

  public function onUpdate(event:UpdateScriptEvent):Void {};

  static function _fetchData(id:String):Null<SongMetadata>
  {
    trace('Fetching song metadata for $id');
    var version:Null<thx.semver.Version> = SongRegistry.instance.fetchEntryMetadataVersion(id);
    if (version == null) return null;
    return SongRegistry.instance.parseEntryMetadataWithMigration(id, Constants.DEFAULT_VARIATION, version);
  }

  function fetchVariationMetadata(id:String):Array<SongMetadata>
  {
    var result:Array<SongMetadata> = [];
    for (vari in variations)
    {
      var version:Null<thx.semver.Version> = SongRegistry.instance.fetchEntryMetadataVersion(id, vari);
      if (version == null) continue;
      var meta:Null<SongMetadata> = SongRegistry.instance.parseEntryMetadataWithMigration(id, vari, version);
      if (meta != null) result.push(meta);
    }
    return result;
  }
}

class SongDifficulty
{
  /**
   * The parent song for this difficulty.
   */
  public final song:Song;

  /**
   * The difficulty ID, such as `easy` or `hard`.
   */
  public final difficulty:String;

  /**
   * The metadata file that contains this difficulty.
   */
  public final variation:String;

  /**
   * The note chart for this difficulty.
   */
  public var notes:Array<SongNoteData>;

  /**
   * The event chart for this difficulty.
   */
  public var events:Array<SongEventData>;

  public var songName:String = Constants.DEFAULT_SONGNAME;
  public var songArtist:String = Constants.DEFAULT_ARTIST;
  public var timeFormat:SongTimeFormat = Constants.DEFAULT_TIMEFORMAT;
  public var divisions:Null<Int> = null;
  public var looped:Bool = false;
  public var generatedBy:String = SongRegistry.DEFAULT_GENERATEDBY;

  public var timeChanges:Array<SongTimeChange> = [];

  public var stage:String = Constants.DEFAULT_STAGE;
  public var noteStyle:String = Constants.DEFAULT_NOTE_STYLE;
  public var characters:SongCharacterData = null;

  public var scrollSpeed:Float = Constants.DEFAULT_SCROLLSPEED;

  public function new(song:Song, diffId:String, variation:String)
  {
    this.song = song;
    this.difficulty = diffId;
    this.variation = variation;
  }

  public function clearChart():Void
  {
    notes = null;
  }

  public function getStartingBPM():Float
  {
    if (timeChanges.length == 0)
    {
      return 0;
    }

    return timeChanges[0].bpm;
  }

  public function getEvents():Array<SongEventData>
  {
    return cast events;
  }

  public function cacheInst(instrumental = ''):Void
  {
    if (characters != null)
    {
      if (instrumental != '' && characters.altInstrumentals.contains(instrumental))
      {
        FlxG.sound.cache(Paths.inst(this.song.id, instrumental));
      }
      else
      {
        // Fallback to default instrumental.
        FlxG.sound.cache(Paths.inst(this.song.id, characters.instrumental));
      }
    }
    else
    {
      FlxG.sound.cache(Paths.inst(this.song.id));
    }
  }

  public inline function playInst(volume:Float = 1.0, looped:Bool = false):Void
  {
    var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-$variation' : '';
    FlxG.sound.playMusic(Paths.inst(this.song.id, suffix), volume, looped);
  }

  /**
   * Cache the vocals for a given character.
   * @param id The character we are about to play.
   */
  public inline function cacheVocals():Void
  {
    for (voice in buildVoiceList())
    {
      FlxG.sound.cache(voice);
    }
  }

  /**
   * Build a list of vocal files for the given character.
   * Automatically resolves suffixed character IDs (so bf-car will resolve to bf if needed).
   *
   * @param id The character we are about to play.
   */
  public function buildVoiceList():Array<String>
  {
    var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-$variation' : '';

    // Automatically resolve voices by removing suffixes.
    // For example, if `Voices-bf-car.ogg` does not exist, check for `Voices-bf.ogg`.

    var playerId:String = characters.player;
    var voicePlayer:String = Paths.voices(this.song.id, '-$playerId$suffix');
    while (voicePlayer != null && !Assets.exists(voicePlayer))
    {
      // Remove the last suffix.
      // For example, bf-car becomes bf.
      playerId = playerId.split('-').slice(0, -1).join('-');
      // Try again.
      voicePlayer = playerId == '' ? null : Paths.voices(this.song.id, '-${playerId}$suffix');
    }

    var opponentId:String = characters.opponent;
    var voiceOpponent:String = Paths.voices(this.song.id, '-${opponentId}$suffix');
    while (voiceOpponent != null && !Assets.exists(voiceOpponent))
    {
      // Remove the last suffix.
      opponentId = opponentId.split('-').slice(0, -1).join('-');
      // Try again.
      voiceOpponent = opponentId == '' ? null : Paths.voices(this.song.id, '-${opponentId}$suffix');
    }

    var result:Array<String> = [];
    if (voicePlayer != null) result.push(voicePlayer);
    if (voiceOpponent != null) result.push(voiceOpponent);
    if (voicePlayer == null && voiceOpponent == null)
    {
      // Try to use `Voices.ogg` if no other voices are found.
      if (Assets.exists(Paths.voices(this.song.id, ''))) result.push(Paths.voices(this.song.id, '$suffix'));
    }
    return result;
  }

  /**
   * Create a VoicesGroup, an audio object that can play the vocals for all characters.
   * @param charId The player ID.
   * @return The generated vocal group.
   */
  public function buildVocals():VoicesGroup
  {
    var result:VoicesGroup = new VoicesGroup();

    var voiceList:Array<String> = buildVoiceList();

    if (voiceList.length == 0)
    {
      trace('Could not find any voices for song ${this.song.id}');
      return result;
    }

    // Add player vocals.
    if (voiceList[0] != null) result.addPlayerVoice(new FlxSound().loadEmbedded(Assets.getSound(voiceList[0])));
    // Add opponent vocals.
    if (voiceList[1] != null) result.addOpponentVoice(new FlxSound().loadEmbedded(Assets.getSound(voiceList[1])));

    // Add additional vocals.
    if (voiceList.length > 2)
    {
      for (i in 2...voiceList.length)
      {
        result.add(new FlxSound().loadEmbedded(Assets.getSound(voiceList[i])));
      }
    }

    return result;
  }
}
