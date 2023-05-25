package funkin.play.song;

import flixel.sound.FlxSound;
import openfl.utils.Assets;
import funkin.modding.events.ScriptEvent;
import funkin.modding.IScriptedClass;
import funkin.audio.VoicesGroup;
import funkin.play.song.SongData.SongChartData;
import funkin.play.song.SongData.SongDataParser;
import funkin.play.song.SongData.SongEventData;
import funkin.play.song.SongData.SongMetadata;
import funkin.play.song.SongData.SongNoteData;
import funkin.play.song.SongData.SongPlayableChar;
import funkin.play.song.SongData.SongTimeChange;
import funkin.play.song.SongData.SongTimeFormat;

/**
 * This is a data structure managing information about the current song.
 * This structure is created when the game starts, and includes all the data
 * from the `metadata.json` file.
 * It also includes the chart data, but only when this is the currently loaded song.
 *
 * It also receives script events; scripted classes which extend this class
 * can be used to perform custom gameplay behaviors only on specific songs.
 */
class Song implements IPlayStateScriptedClass
{
  public final songId:String;

  final _metadata:Array<SongMetadata>;

  final variations:Array<String>;
  final difficulties:Map<String, SongDifficulty>;

  /**
   * Set to false if the song was edited in the charter and should not be saved as a high score.
   */
  public var validScore:Bool = true;

  public function new(id:String)
  {
    this.songId = id;

    variations = [];
    difficulties = new Map<String, SongDifficulty>();

    _metadata = SongDataParser.parseSongMetadata(songId);
    if (_metadata == null || _metadata.length == 0)
    {
      throw 'Could not find song data for songId: $songId';
    }

    populateFromMetadata();
  }

  public function getRawMetadata():Array<SongMetadata>
  {
    return _metadata;
  }

  /**
   * Populate the song data from the provided metadata,
   * including data from individual difficulties. Does not load chart data.
   */
  function populateFromMetadata():Void
  {
    // Variations may have different artist, time format, generatedBy, etc.
    for (metadata in _metadata)
    {
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
        // difficulty.noteSkin = metadata.playData.noteSkin;

        difficulty.chars = new Map<String, SongPlayableChar>();
        for (charId in metadata.playData.playableChars.keys())
        {
          var char = metadata.playData.playableChars.get(charId);

          difficulty.chars.set(charId, char);
        }

        difficulties.set(diffId, difficulty);
      }
    }
  }

  /**
   * Parse and cache the chart for all difficulties of this song.
   */
  public function cacheCharts(?force:Bool = false):Void
  {
    if (force)
    {
      clearCharts();
    }

    trace('Caching ${variations.length} chart files for song $songId');
    for (variation in variations)
    {
      var chartData:SongChartData = SongDataParser.parseSongChartData(songId, variation);
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
        difficulty.notes = chartData.notes.get(diffId);
        difficulty.scrollSpeed = chartData.getScrollSpeed(diffId);

        difficulty.events = chartData.events;
      }
    }
    trace('Done caching charts.');
  }

  /**
   * Retrieve the metadata for a specific difficulty, including the chart if it is loaded.
   * @param diffId The difficulty ID, such as `easy` or `hard`.
   * @return The difficulty data.
   */
  public inline function getDifficulty(diffId:String = null):SongDifficulty
  {
    if (diffId == null) diffId = difficulties.keys().array()[0];

    return difficulties.get(diffId);
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
    return 'Song($songId)';
  }

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

  public var songName:String = SongValidator.DEFAULT_SONGNAME;
  public var songArtist:String = SongValidator.DEFAULT_ARTIST;
  public var timeFormat:SongTimeFormat = SongValidator.DEFAULT_TIMEFORMAT;
  public var divisions:Int = SongValidator.DEFAULT_DIVISIONS;
  public var looped:Bool = SongValidator.DEFAULT_LOOPED;
  public var generatedBy:String = SongValidator.DEFAULT_GENERATEDBY;

  public var timeChanges:Array<SongTimeChange> = [];

  public var stage:String = SongValidator.DEFAULT_STAGE;
  public var chars:Map<String, SongPlayableChar> = null;

  public var scrollSpeed:Float = SongValidator.DEFAULT_SCROLLSPEED;

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

  public function getPlayableChar(id:String):SongPlayableChar
  {
    return chars.get(id);
  }

  public function getPlayableChars():Array<String>
  {
    return chars.keys().array();
  }

  public function getEvents():Array<SongEventData>
  {
    return cast events;
  }

  public inline function cacheInst():Void
  {
    FlxG.sound.cache(Paths.inst(this.song.songId));
  }

  public inline function playInst(volume:Float = 1.0, looped:Bool = false):Void
  {
    FlxG.sound.playMusic(Paths.inst(this.song.songId), volume, looped);
  }

  /**
   * Cache the vocals for a given character.
   * @param id The character we are about to play.
   */
  public inline function cacheVocals(?id:String = 'bf'):Void
  {
    for (voice in buildVoiceList(id))
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
  public function buildVoiceList(?id:String = 'bf'):Array<String>
  {
    var playableCharData:SongPlayableChar = getPlayableChar(id);
    if (playableCharData == null)
    {
      trace('Could not find playable char $id for song ${this.song.songId}');
      return [];
    }

    // Automatically resolve voices by removing suffixes.
    // For example, if `Voices-bf-car.ogg` does not exist, check for `Voices-bf.ogg`.

    var playerId:String = id;
    var voicePlayer:String = Paths.voices(this.song.songId, '-$id');
    while (voicePlayer != null && !Assets.exists(voicePlayer))
    {
      // Remove the last suffix.
      // For example, bf-car becomes bf.
      playerId = playerId.split('-').slice(0, -1).join('-');
      // Try again.
      voicePlayer = playerId == '' ? null : Paths.voices(this.song.songId, '-${playerId}');
    }

    var opponentId:String = playableCharData.opponent;
    var voiceOpponent:String = Paths.voices(this.song.songId, '-${opponentId}');
    while (voiceOpponent != null && !Assets.exists(voiceOpponent))
    {
      // Remove the last suffix.
      opponentId = opponentId.split('-').slice(0, -1).join('-');
      // Try again.
      voiceOpponent = opponentId == '' ? null : Paths.voices(this.song.songId, '-${opponentId}');
    }

    var result:Array<String> = [];
    if (voicePlayer != null) result.push(voicePlayer);
    if (voiceOpponent != null) result.push(voiceOpponent);
    if (voicePlayer == null && voiceOpponent == null)
    {
      // Try to use `Voices.ogg` if no other voices are found.
      if (Assets.exists(Paths.voices(this.song.songId, ''))) result.push(Paths.voices(this.song.songId, ''));
    }
    return result;
  }

  /**
   * Create a VoicesGroup, an audio object that can play the vocals for all characters.
   * @param charId The player ID.
   * @return The generated vocal group.
   */
  public function buildVocals(charId:String = 'bf'):VoicesGroup
  {
    var result:VoicesGroup = new VoicesGroup();

    var voiceList:Array<String> = buildVoiceList(charId);

    if (voiceList.length == 0)
    {
      trace('Could not find any voices for song ${this.song.songId}');
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
