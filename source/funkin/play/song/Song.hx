package funkin.play.song;

import funkin.audio.VoicesGroup;
import funkin.audio.FunkinSound;
import funkin.data.IRegistryEntry;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongOffsets;
import funkin.data.song.SongData.SongTimeChange;
import funkin.data.song.SongData.SongTimeFormat;
import funkin.data.song.SongRegistry;
import funkin.modding.IScriptedClass.IPlayStateScriptedClass;
import funkin.modding.events.ScriptEvent;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.util.SortUtil;

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
  /**
   * The default value for the song's name
   */
  public static final DEFAULT_SONGNAME:String = 'Unknown';

  /**
   * The default value for the song's artist
   */
  public static final DEFAULT_ARTIST:String = 'Unknown';

  /**
   * The default value for the song's time format
   */
  public static final DEFAULT_TIMEFORMAT:SongTimeFormat = SongTimeFormat.MILLISECONDS;

  /**
   * The default value for the song's divisions
   */
  public static final DEFAULT_DIVISIONS:Null<Int> = null;

  /**
   * The default value for whether the song loops.
   */
  public static final DEFAULT_LOOPED:Bool = false;

  /**
   * The default value for the song's playable stage.
   */
  public static final DEFAULT_STAGE:String = 'mainStage';

  /**
   * The default value for the song's scroll speed.
   */
  public static final DEFAULT_SCROLLSPEED:Float = 1.0;

  // key = variation id, value = metadata
  final _metadata:Map<String, SongMetadata>;

  /**
   * holds the difficulties (as in SongDifficulty) for each variation
   * difficulties.get('default').get('easy') would return the easy difficulty for the default variation
   */
  final difficulties:Map<String, Map<String, SongDifficulty>>;

  /**
   * The list of variations a song has.
   */
  public var variations(get, never):Array<String>;

  function get_variations():Array<String>
  {
    return _metadata.keys().array();
  }

  // this returns false so that any new song can override this and return true when needed
  public function isSongNew(currentDifficulty:String, currentVariation:String):Bool
  {
    return false;
  }

  /**
   * Set to false if the song was edited in the charter and should not be saved as a high score.
   */
  public var validScore:Bool = true;

  /**
   * The readable name of the song.
   */
  public var songName(get, never):String;

  function get_songName():String
  {
    if (_data != null) return _data?.songName ?? DEFAULT_SONGNAME;
    if (_metadata.size() > 0) return _metadata.get(Constants.DEFAULT_VARIATION)?.songName ?? DEFAULT_SONGNAME;
    return DEFAULT_SONGNAME;
  }

  /**
   * The artist of the song.
   */
  public var songArtist(get, never):String;

  function get_songArtist():String
  {
    if (_data != null) return _data?.artist ?? DEFAULT_ARTIST;
    if (_metadata.size() > 0) return _metadata.get(Constants.DEFAULT_VARIATION)?.artist ?? DEFAULT_ARTIST;
    return DEFAULT_ARTIST;
  }

  /**
   * The artist of the song.
   */
  public var charter(get, never):String;

  function get_charter():String
  {
    if (_data != null) return _data?.charter ?? 'Unknown';
    if (_metadata.size() > 0) return _metadata.get(Constants.DEFAULT_VARIATION)?.charter ?? 'Unknown';
    return Constants.DEFAULT_CHARTER;
  }

  /**
   * @param id The ID of the song to load.
   * @param ignoreErrors If false, an exception will be thrown if the song data could not be loaded.
   */
  public function new(id:String)
  {
    this.id = id;

    difficulties = new Map<String, Map<String, SongDifficulty>>();

    _data = _fetchData(id);

    _metadata = _data == null ? [] : [Constants.DEFAULT_VARIATION => _data];

    if (_data != null && _data.playData != null)
    {
      for (vari in _data.playData.songVariations)
      {
        if (!validateVariationId(vari))
        {
          trace('  [WARN] Variation id "$vari" is invalid, skipping...');
          continue;
        }

        var variMeta:Null<SongMetadata> = fetchVariationMetadata(id, vari);
        if (variMeta != null)
        {
          _metadata.set(variMeta.variation, variMeta);
          trace('  Loaded variation: $vari');
        }
        else
        {
          FlxG.log.warn('[SONG] Failed to load variation metadata (${id}:${vari}), is the path correct?');
          trace('  FAILED to load variation: $vari');
        }
      }
    }

    if (_metadata.size() == 0)
    {
      trace('[WARN] Could not find song data for songId: $id');
      return;
    }

    populateDifficulties();
  }

  /**
   * Build a song from existing metadata rather than loading it from the `assets` folder.
   * Used by the Chart Editor.
   *
   * @param songId The ID of the song.
   * @param metadata The metadata of the song.
   * @param variations The list of variations this song has.
   * @param charts The chart data for each variation.
   * @param includeScript Whether to initialize the scripted class tied to the song, if it exists.
   * @param validScore Whether the song is elegible for highscores.
   * @return The constructed song object.
   */
  public static function buildRaw(songId:String, metadata:Array<SongMetadata>, variations:Array<String>, charts:Map<String, SongChartData>,
      includeScript:Bool = true, validScore:Bool = false):Song
  {
    @:privateAccess
    var result:Null<Song> = null;

    if (includeScript && SongRegistry.instance.isScriptedEntry(songId))
    {
      var songClassName:Null<String> = SongRegistry.instance.getScriptedEntryClassName(songId);
      @:privateAccess
      if (songClassName != null) result = SongRegistry.instance.createScriptedEntry(songClassName);
    }
    else
    {
      @:privateAccess
      result = SongRegistry.instance.createEntry(songId);
    }

    if (result == null) throw 'ERROR: Could not build Song instance ($songId), is the attached script bad?';

    result._metadata.clear();
    for (meta in metadata)
    {
      result._metadata.set(meta.variation, meta);
    }

    result.difficulties.clear();
    result.populateDifficulties();

    for (variation => chartData in charts)
    {
      result.applyChartData(chartData, variation);
    }

    result.validScore = validScore;

    return result;
  }

  /**
   * Retrieve a list of the raw metadata for the song.
   * @return The metadata JSON objects for the song's variations.
   */
  public function getRawMetadata():Array<SongMetadata>
  {
    return _metadata.values();
  }

  /**
   * List the album IDs for each variation of the song.
   * @return A map of variation IDs to album IDs.
   */
  public function listAlbums(variation:String):Map<String, String>
  {
    var result:Map<String, String> = new Map<String, String>();

    for (variationMap in difficulties)
    {
      for (difficultyId in variationMap.keys())
      {
        var meta:Null<SongDifficulty> = variationMap.get(difficultyId);
        if (meta != null && meta.album != null)
        {
          result.set(difficultyId, meta.album);
        }
      }
    }

    return result;
  }

  /**
   * Input a difficulty ID and a variation ID, and get the album ID.
   * @param diffId
   * @param variation
   * @return String
   */
  public function getAlbumId(diffId:String, variation:String):String
  {
    var diff:Null<SongDifficulty> = getDifficulty(diffId, variation);
    if (diff == null) return '';

    return diff.album ?? '';
  }

  public function getStickerPackId(diffId:String, variation:String):Null<String>
  {
    var diff:Null<SongDifficulty> = getDifficulty(diffId, variation);
    if (diff == null) return null;

    return diff.stickerPack;
  }

  /**
   * Populate the difficulty data from the provided metadata.
   * Does not load chart data (that is triggered later when we want to play the song).
   */
  function populateDifficulties():Void
  {
    if (_metadata == null || _metadata.size() == 0) return;

    // Variations may have different artist, time format, generatedBy, etc.
    for (metadata in _metadata.values())
    {
      if (metadata == null || metadata.playData == null) continue;

      // If there are no difficulties in the metadata, there's a problem.
      if (metadata.playData.difficulties.length == 0)
      {
        trace('[SONG] Warning: Song $id (variation ${metadata.variation}) has no difficulties listed in metadata!');
        continue;
      }

      // This resides within difficulties
      var difficultyMap:Map<String, SongDifficulty> = new Map<String, SongDifficulty>();

      // There may be more difficulties in the chart file than in the metadata,
      // (i.e. non-playable charts like the one used for Pico on the speaker in Stress)
      // but all the difficulties in the metadata must be in the chart file.
      for (diffId in metadata.playData.difficulties)
      {
        var difficulty:SongDifficulty = new SongDifficulty(this, diffId, metadata.variation);

        difficulty.songName = metadata.songName;
        difficulty.songArtist = metadata.artist;
        difficulty.charter = metadata.charter ?? Constants.DEFAULT_CHARTER;
        difficulty.timeFormat = metadata.timeFormat;
        difficulty.divisions = metadata.divisions;
        difficulty.timeChanges = metadata.timeChanges;
        difficulty.looped = metadata.looped;
        difficulty.generatedBy = metadata.generatedBy;
        difficulty.offsets = metadata?.offsets ?? new SongOffsets();

        difficulty.difficultyRating = metadata.playData.ratings.get(diffId) ?? 0;
        difficulty.album = metadata.playData.album;
        difficulty.stickerPack = metadata.playData.stickerPack;

        difficulty.stage = metadata.playData.stage;
        difficulty.noteStyle = metadata.playData.noteStyle;

        difficulty.characters = metadata.playData.characters;
        difficultyMap.set(diffId, difficulty);
      }
      difficulties.set(metadata.variation, difficultyMap);
    }
  }

  /**
   * Parse and cache the chart for all difficulties of this song.
   * @param force Whether to forcibly clear the list of charts first.
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
      // Retrieve the cached difficulty data. This one could potentially be null.
      var nullDiff:Null<SongDifficulty> = getDifficulty(diffId, variation);

      // if the difficulty doesn't exist, create a new one, and then proceed to fill it with data.
      // I mostly do this since I don't wanna throw around ? everywhere for null check lol?
      var difficulty:SongDifficulty = nullDiff ?? new SongDifficulty(this, diffId, variation);

      if (nullDiff == null)
      {
        trace('Fabricated new difficulty for $diffId.');
        var metadata = _metadata.get(variation);
        difficulties.get(variation)?.set(diffId, difficulty);

        if (metadata != null)
        {
          difficulty.songName = metadata.songName;
          difficulty.songArtist = metadata.artist;
          difficulty.charter = metadata.charter ?? Constants.DEFAULT_CHARTER;
          difficulty.timeFormat = metadata.timeFormat;
          difficulty.divisions = metadata.divisions;
          difficulty.timeChanges = metadata.timeChanges;
          difficulty.looped = metadata.looped;
          difficulty.generatedBy = metadata.generatedBy;
          difficulty.offsets = metadata?.offsets ?? new SongOffsets();

          difficulty.stage = metadata.playData.stage;
          difficulty.noteStyle = metadata.playData.noteStyle;

          difficulty.characters = metadata.playData.characters;
        }
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
   * @param variation The variation ID to fetch the difficulty for. Or you can use `variations`.
   * @param variations A list of variations to fetch the difficulty for. Looks for the first variation that exists.
   * @return The difficulty data.
   */
  public function getDifficulty(?diffId:String, ?variation:String, ?variations:Array<String>):Null<SongDifficulty>
  {
    if (diffId == null) diffId = listDifficulties(variation, variations)[0];
    if (variation == null) variation = Constants.DEFAULT_VARIATION;
    if (variations == null) variations = [variation];

    for (currentVariation in variations)
    {
      if (difficulties.get(currentVariation)?.exists(diffId) ?? false)
      {
        return difficulties.get(currentVariation)?.get(diffId);
      }
    }

    return null;
  }

  /**
   * Returns the first valid variation that matches both the difficulty id, and the current character / possible input variations
   * @param diffId
   * @param currentCharacter
   * @param possibleVariations
   * @return Null<String>
   */
  public function getFirstValidVariation(?diffId:String, ?currentCharacter:PlayableCharacter, ?possibleVariations:Array<String>):Null<String>
  {
    if (possibleVariations == null)
    {
      possibleVariations = getVariationsByCharacter(currentCharacter);
    }

    if (diffId == null) diffId = listDifficulties(null, possibleVariations)[0];

    for (variationId in possibleVariations)
    {
      if (difficulties.get('$variationId')?.exists(diffId) ?? false) return variationId;
    }

    return null;
  }

  /**
   * Given that this character is selected in the Freeplay menu,
   * which variations should be available?
   * @param char The playable character to query.
   * @return An array of available variations.
   */
  public function getVariationsByCharacter(?char:PlayableCharacter):Array<String>
  {
    if (char == null)
    {
      var result = variations;
      result.sort(SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_VARIATION_LIST));
      return result;
    }

    var result = [];
    for (variation in variations)
    {
      var metadata = _metadata.get(variation);

      var playerCharId = metadata?.playData?.characters?.player;
      if (playerCharId == null) continue;

      if (char.shouldShowCharacter(playerCharId))
      {
        result.push(variation);
      }
    }

    result.sort(SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_VARIATION_LIST));

    return result;
  }

  /**
   * Nearly the same thing as getVariationsByCharacter, but takes a character ID instead.
   * @param charId
   * @return Array<String>
   * @see getVariationsByCharacter
   */
  public function getVariationsByCharacterId(?charId:String):Array<String>
  {
    var charPlayer = PlayerRegistry.instance.fetchEntry(charId ?? '');

    return getVariationsByCharacter(charPlayer);
  }

  /**
   * List all the difficulties in this song.
   *
   * @param variationId Optionally filter by a single variation.
   * @param variationIds Optionally filter by multiple variations.
   * @param showLocked Include charts which are not unlocked
   * @param showHidden Include charts which are not accessible to the player.
   *
   * @return The list of difficulties.
   */
  public function listDifficulties(?variationId:String, ?variationIds:Array<String>, showLocked:Bool = false, showHidden:Bool = false):Array<String>
  {
    if (variationIds == null) variationIds = [];
    if (variationId != null) variationIds.push(variationId);

    if (variationIds.length == 0) return [];

    var diffFiltered:Array<String> = variationIds.map(function(variationId:String):Array<String> {
      var metadata = _metadata.get(variationId);
      return metadata?.playData?.difficulties ?? [];
    })
      .flatten()
      .filterNull()
      .distinct();

    diffFiltered = diffFiltered.filter(function(diffId:String):Bool {
      if (showHidden) return true;
      for (targetVariation in variationIds)
      {
        if (isDifficultyVisible(diffId, targetVariation)) return true;
      }
      return false;
    });

    diffFiltered.sort(SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_DIFFICULTY_LIST_FULL));

    return diffFiltered;
  }

  /**
   * TODO: This line of code makes me sad, but you can't really fix it without a breaking migration.
   * @return `easy`, `erect`, `normal-pico`, etc.
   * @deprecated This function is deprecated, Funkin no longer uses suffixed difficulties.
   */
  public function listSuffixedDifficulties(variationIds:Array<String>, ?showLocked:Bool, ?showHidden:Bool):Array<String>
  {
    var result = [];

    for (variation in variationIds)
    {
      var difficulties = listDifficulties(variation, null, showLocked, showHidden);
      for (difficulty in difficulties)
      {
        var suffixedDifficulty = (variation != Constants.DEFAULT_VARIATION
          && variation != 'erect') ? '$difficulty-${variation}' : difficulty;
        result.push(suffixedDifficulty);
      }
    }

    result.sort(SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_DIFFICULTY_LIST_FULL));

    return result;
  }

  public function hasDifficulty(diffId:String, ?variationId:String, ?variationIds:Array<String>):Bool
  {
    if (variationIds == null) variationIds = [];
    if (variationId != null) variationIds.push(variationId);

    for (targetVariation in variationIds)
    {
      if (difficulties.get(targetVariation)?.exists(diffId) ?? false) return true;
    }
    return false;
  }

  public function isDifficultyVisible(diffId:String, variationId:String):Bool
  {
    var variation = _metadata.get(variationId);
    if (variation == null) return false;
    return variation.playData.difficulties.contains(diffId);
  }

  /**
   * Return the list of available alternate instrumentals.
   * Scripts can override this, fun.
   * @param variationId
   * @param difficultyId
   */
  public function listAltInstrumentalIds(difficultyId:String, variationId:String):Array<String>
  {
    var targetDifficulty:Null<SongDifficulty> = getDifficulty(difficultyId, variationId);
    if (targetDifficulty == null) return [];

    return targetDifficulty?.characters?.altInstrumentals ?? [];
  }

  public function getBaseInstrumentalId(difficultyId:String, variationId:String):String
  {
    var targetDifficulty:Null<SongDifficulty> = getDifficulty(difficultyId, variationId);
    if (targetDifficulty == null) return '';

    return targetDifficulty?.characters?.instrumental ?? '';
  }

  /**
   * Purge the cached chart data for each difficulty/variation of this song.
   */
  public function clearCharts():Void
  {
    for (variationMap in difficulties)
    {
      for (diff in variationMap)
      {
        diff.clearChart();
      }
    }
  }

  public function onPause(event:PauseScriptEvent):Void {};

  public function onResume(event:ScriptEvent):Void {};

  public function onSongLoaded(event:SongLoadScriptEvent):Void {};

  public function onSongStart(event:ScriptEvent):Void {};

  public function onSongEnd(event:ScriptEvent):Void {};

  public function onGameOver(event:ScriptEvent):Void {};

  public function onSongRetry(event:SongRetryEvent):Void {};

  public function onNoteIncoming(event:NoteScriptEvent) {};

  public function onNoteHit(event:HitNoteScriptEvent) {};

  public function onNoteMiss(event:NoteScriptEvent):Void {};

  public function onNoteHoldDrop(event:HoldNoteScriptEvent) {}

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

  function fetchVariationMetadata(id:String, vari:String):Null<SongMetadata>
  {
    var version:Null<thx.semver.Version> = SongRegistry.instance.fetchEntryMetadataVersion(id, vari);
    if (version == null) return null;
    var meta:Null<SongMetadata> = SongRegistry.instance.parseEntryMetadataWithMigration(id, vari, version);
    return meta;
  }

  static final VARIATION_REGEX = ~/^[a-z][a-z0-9]+$/;

  /**
   * Validate that the variation ID is valid.
   * Auto-accept if it's one of the base game default variations.
   * Reject if the ID starts with a number, or contains invalid characters.
   */
  static function validateVariationId(variation:String):Bool
  {
    if (Constants.DEFAULT_VARIATION_LIST.contains(variation)) return true;

    return VARIATION_REGEX.match(variation);
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
  public var charter:String = Constants.DEFAULT_CHARTER;
  public var timeFormat:SongTimeFormat = Constants.DEFAULT_TIMEFORMAT;
  public var divisions:Null<Int> = null;
  public var looped:Bool = false;
  public var offsets:SongOffsets = new SongOffsets();
  public var generatedBy:String = SongRegistry.DEFAULT_GENERATEDBY;

  public var timeChanges:Array<SongTimeChange> = [];

  public var stage:String = Constants.DEFAULT_STAGE;
  public var noteStyle:String = Constants.DEFAULT_NOTE_STYLE;
  public var characters:SongCharacterData = null;

  public var scrollSpeed:Float = Constants.DEFAULT_SCROLLSPEED;

  public var difficultyRating:Int = 0;
  public var album:Null<String> = null;
  public var stickerPack:Null<String> = null;

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

  public function getInstPath(instrumental = ''):String
  {
    if (characters != null)
    {
      if (instrumental != '' && characters.altInstrumentals.contains(instrumental))
      {
        var instId = '-$instrumental';
        return Paths.inst(this.song.id, instId);
      }
      else
      {
        // Fallback to default instrumental.
        var instId = (characters.instrumental ?? '') != '' ? '-${characters.instrumental}' : '';
        return Paths.inst(this.song.id, instId);
      }
    }
    else
    {
      return Paths.inst(this.song.id);
    }
  }

  public function cacheInst(instrumental = ''):Void
  {
    funkin.FunkinMemory.cacheSound(getInstPath(instrumental));
  }

  public function playInst(volume:Float = 1.0, instId:String = '', looped:Bool = false):Void
  {
    var suffix:String = (instId != '') ? '-$instId' : '';

    FlxG.sound.music = FunkinSound.load(Paths.inst(this.song.id, suffix), volume, looped, false, true, false, null, null, true);

    // Workaround for a bug where FlxG.sound.music.update() was being called twice.
    FlxG.sound.list.remove(FlxG.sound.music);
  }

  /**
   * Cache the vocals for a given character.
   * @param id The character we are about to play.
   */
  public function cacheVocals():Void
  {
    for (voice in buildVoiceList())
    {
      trace('Caching vocal track: $voice');
      funkin.FunkinMemory.cacheSound(voice);
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
    var result:Array<String> = [];
    result = result.concat(buildPlayerVoiceList());
    result = result.concat(buildOpponentVoiceList());
    if (result.length == 0)
    {
      var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-$variation' : '';
      // Try to use `Voices.ogg` if no other voices are found.
      if (Assets.exists(Paths.voices(this.song.id, ''))) result.push(Paths.voices(this.song.id, '$suffix'));
    }
    return result;
  }

  public function buildPlayerVoiceList():Array<String>
  {
    var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-$variation' : '';

    // Automatically resolve voices by removing suffixes.
    // For example, if `Voices-bf-car-erect.ogg` does not exist, check for `Voices-bf-erect.ogg`.
    // Then, check for  `Voices-bf-car.ogg`, then `Voices-bf.ogg`.

    if (characters.playerVocals == null)
    {
      var playerId:String = characters.player;
      var playerVoice:String = Paths.voices(this.song.id, '-${playerId}$suffix');

      while (playerVoice != null && !Assets.exists(playerVoice))
      {
        // Remove the last suffix.
        // For example, bf-car becomes bf.
        playerId = playerId.split('-').slice(0, -1).join('-');
        // Try again.
        playerVoice = playerId == '' ? null : Paths.voices(this.song.id, '-${playerId}$suffix');
      }
      if (playerVoice == null)
      {
        // Try again without $suffix.
        playerId = characters.player;
        playerVoice = Paths.voices(this.song.id, '-${playerId}');
        while (playerVoice != null && !Assets.exists(playerVoice))
        {
          // Remove the last suffix.
          playerId = playerId.split('-').slice(0, -1).join('-');
          // Try again.
          playerVoice = playerId == '' ? null : Paths.voices(this.song.id, '-${playerId}$suffix');
        }
      }

      return playerVoice != null ? [playerVoice] : [];
    }
    else
    {
      // The metadata explicitly defines the list of voices.
      var playerIds:Array<String> = characters?.playerVocals ?? [characters.player];
      var playerVoices:Array<String> = playerIds.map((id) -> Paths.voices(this.song.id, '-$id$suffix'));

      return playerVoices;
    }
  }

  public function buildOpponentVoiceList():Array<String>
  {
    var suffix:String = (variation != null && variation != '' && variation != 'default') ? '-$variation' : '';

    // Automatically resolve voices by removing suffixes.
    // For example, if `Voices-bf-car-erect.ogg` does not exist, check for `Voices-bf-erect.ogg`.
    // Then, check for  `Voices-bf-car.ogg`, then `Voices-bf.ogg`.

    if (characters.opponentVocals == null)
    {
      var opponentId:String = characters.opponent;
      var opponentVoice:String = Paths.voices(this.song.id, '-${opponentId}$suffix');
      while (opponentVoice != null && !Assets.exists(opponentVoice))
      {
        // Remove the last suffix.
        opponentId = opponentId.split('-').slice(0, -1).join('-');
        // Try again.
        opponentVoice = opponentId == '' ? null : Paths.voices(this.song.id, '-${opponentId}$suffix');
      }
      if (opponentVoice == null)
      {
        // Try again without $suffix.
        opponentId = characters.opponent;
        opponentVoice = Paths.voices(this.song.id, '-${opponentId}');
        while (opponentVoice != null && !Assets.exists(opponentVoice))
        {
          // Remove the last suffix.
          opponentId = opponentId.split('-').slice(0, -1).join('-');
          // Try again.
          opponentVoice = opponentId == '' ? null : Paths.voices(this.song.id, '-${opponentId}$suffix');
        }
      }

      return opponentVoice != null ? [opponentVoice] : [];
    }
    else
    {
      // The metadata explicitly defines the list of voices.
      var opponentIds:Array<String> = characters?.opponentVocals ?? [characters.opponent];
      var opponentVoices:Array<String> = opponentIds.map((id) -> Paths.voices(this.song.id, '-$id$suffix'));

      return opponentVoices;
    }
  }

  /**
   * Create a VoicesGroup, an audio object that can play the vocals for all characters.
   * @param charId The player ID.
   * @return The generated vocal group.
   */
  public function buildVocals(?instId:String = ''):VoicesGroup
  {
    var result:VoicesGroup = new VoicesGroup();

    var playerVoiceList:Array<String> = this.buildPlayerVoiceList();
    var opponentVoiceList:Array<String> = this.buildOpponentVoiceList();

    // Add player vocals.
    for (playerVoice in playerVoiceList)
    {
      if (!Assets.exists(playerVoice)) continue;
      result.addPlayerVoice(FunkinSound.load(playerVoice, 1.0, false, false, false, false, null, null, true));
    }

    // Add opponent vocals.
    for (opponentVoice in opponentVoiceList)
    {
      if (!Assets.exists(opponentVoice)) continue;
      result.addOpponentVoice(FunkinSound.load(opponentVoice, 1.0, false, false, false, false, null, null, true));
    }

    // Sometimes the sounds don't set their important value to true, so we have to do this manually.
    result.forEach(function(snd:FunkinSound) {
      snd.important = true;
    });

    result.playerVoicesOffset = offsets.getVocalOffset(characters.player, instId);
    result.opponentVoicesOffset = offsets.getVocalOffset(characters.opponent, instId);

    return result;
  }
}
