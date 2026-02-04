package funkin.save;

import flixel.util.FlxSave;
import funkin.input.Controls.Device;
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.play.scoring.Scoring;
import funkin.play.scoring.Scoring.ScoringRank;
import funkin.save.migrator.RawSaveData_v1_0_0;
import funkin.save.migrator.SaveDataMigrator;
import funkin.ui.debug.charting.ChartEditorState.ChartEditorLiveInputStyle;
import funkin.ui.debug.charting.ChartEditorState.ChartEditorTheme;
import funkin.ui.debug.stageeditor.StageEditorState.StageEditorTheme;
import funkin.util.FileUtil;
import funkin.util.macro.ConsoleMacro;
import funkin.util.macro.SaveMacro;
import funkin.util.SerializerUtil;
import funkin.mobile.ui.FunkinHitbox;
import thx.semver.Version;
#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.Medals;
import funkin.api.newgrounds.Leaderboards;
#end

@:nullSafety
@:build(funkin.util.macro.SaveMacro.buildSaveProperties())
class Save implements ConsoleClass
{
  public static final SAVE_DATA_VERSION:thx.semver.Version = "2.1.1";
  public static final SAVE_DATA_VERSION_RULE:thx.semver.VersionRule = ">=2.1.0 <2.2.0";

  public static var system:SaveSystem = new SaveSystem();

  /**
   * Singleton for our Save class
   */
  public static var instance(get, never):Save;

  static var _instance:Null<Save> = null;

  static function get_instance():Save
  {
    if (_instance == null) return load();
    return _instance;
  }

  var data:RawSaveData;

  public static function load():Save
  {
    trace(' SAVE '.bold().bg_note_down() + ' Loading save...');

    // Bind save data.
    final loadedSave:Save = loadFromSlot(Constants.BASE_SAVE_SLOT);
    _instance ??= loadedSave;

    return loadedSave;
  }

  public static function clearData():Void
  {
    _instance = Save.system.clearSlot(Constants.BASE_SAVE_SLOT);
  }

  /**
   * Constructing a new Save will load the default values.
   */
  @:nullSafety(Off)
  public function new(?data:RawSaveData)
  {
    this.data = data ??= Save.getDefaultData();
    // Build macro will inject SaveProperty initialization here automatically

    // Make sure the verison number is up to date before we flush.
    updateVersionToLatest();
  }

  public static function getDefaultData():RawSaveData
  {
    #if mobile
    var refreshRate:Int = FlxG.stage.window.displayMode.refreshRate;
    if (refreshRate < 60) refreshRate = 60;
    #end
    return {
      // Version number is an abstract(Array) internally.
      // This means it copies by reference, so merging save data overides the version number lol.
      version: thx.Dynamics.clone(Save.SAVE_DATA_VERSION),
      volume: 1.0,
      mute: false,
      api:
        {
          newgrounds:
            {
              sessionId: null,
            }
        },
      scores:
        {
          // No saved scores.
          levels: [],
          songs: [],
        },
      favoriteSongs: [],
      options:
        {
          // Reasonable defaults.
          framerate: #if mobile refreshRate #else 60 #end,
          naughtyness: true,
          downscroll: false,
          flashingLights: true,
          zoomCamera: true,
          debugDisplay: 'Off',
          debugDisplayBGOpacity: 50,
          subtitles: true,
          hapticsMode: 'All',
          hapticsIntensityMultiplier: 1,
          autoPause: true,
          vsyncMode: 'Off',
          strumlineBackgroundOpacity: 0,
          autoFullscreen: false,
          globalOffset: 0,
          audioVisualOffset: 0,
          unlockedFramerate: false,
          screenshot:
            {
              shouldHideMouse: true,
              fancyPreview: true,
              previewOnSave: true,
            },
          controls:
            {
              // Leave controls blank so defaults are loaded.
              p1:
                {
                  keyboard: {},
                  gamepad: {},
                },
              p2:
                {
                  keyboard: {},
                  gamepad: {},
                },
            },
        },
      #if mobile
      mobileOptions:
        {
          // Reasonable defaults.
          screenTimeout: false,
          controlsScheme: FunkinHitboxControlSchemes.Arrows,
          noAds: false
        },
      #end
      mods:
        {
          // No mods enabled.
          enabledMods: [],
          modOptions: [],
        },
      unlocks:
        {
          // Default to having seen the default character.
          charactersSeen: ["bf"],
          oldChar: false
        },
      optionsChartEditor:
        {
          // Reasonable defaults.
          previousFiles: [],
          noteQuant: 3,
          chartEditorLiveInputStyle: ChartEditorLiveInputStyle.None,
          theme: ChartEditorTheme.Light,
          playtestStartTime: false,
          playtestAudioSettings: false,
          playtestResultsSettings: false,
          downscroll: false,
          showNoteKinds: true,
          metronomeVolume: 1.0,
          hitsoundVolumePlayer: 1.0,
          hitsoundVolumeOpponent: 1.0,
          instVolume: 1.0,
          playerVoiceVolume: 1.0,
          opponentVoiceVolume: 1.0,
          playbackSpeed: 0.5,
          themeMusic: true
        },
      optionsStageEditor:
        {
          previousFiles: [],
          moveStep: "1px",
          angleStep: 5,
          theme: StageEditorTheme.Light,
          bfChar: "bf",
          gfChar: "gf",
          dadChar: "dad"
        }
    };
  }

  /**
   * NOTE: Modifications will not be saved without calling `Save.flush()`!
   */
  public var options(get, never):SaveDataOptions;

  function get_options():SaveDataOptions
  {
    return data.options;
  }

  #if mobile
  /**
   * NOTE: Modifications will not be saved without calling `Save.flush()`!
   */
  public var mobileOptions(get, never):SaveDataMobileOptions;

  function get_mobileOptions():SaveDataMobileOptions
  {
    return data.mobileOptions;
  }
  #end

  /**
   * NOTE: Modifications will not be saved without calling `Save.flush()`!
   */
  public var modOptions(get, never):Map<String, Dynamic>;

  function get_modOptions():Map<String, Dynamic>
  {
    return data.mods.modOptions;
  }

  /**
   * The user's current volume setting.
   */
  @:saveProperty(data.volume)
  public var volume:SaveProperty<Float>;

  /**
   * Whether the user's volume is currently muted.
   */
  @:saveProperty(data.mute)
  public var mute:SaveProperty<Bool>;

  ///
  /// API
  ///

  /**
   * The current session ID for the logged-in Newgrounds user, or null if the user is cringe.
   */
  @:saveProperty(data.api.newgrounds.sessionId)
  public var ngSessionId:SaveProperty<Null<String>>;

  ///
  /// MODS
  ///
  @:saveProperty(data.mods.enabledMods)
  public var enabledModIds:SaveProperty<Array<String>>;

  ///
  /// CHART EDITOR OPTIONS
  ///
  @:saveProperty(data.optionsChartEditor.previousFiles, [])
  public var chartEditorPreviousFiles:SaveProperty<Array<String>>;

  @:saveProperty(data.optionsChartEditor.hasBackup, false)
  public var chartEditorHasBackup:SaveProperty<Bool>;

  @:saveProperty(data.optionsChartEditor.noteQuant, 3)
  public var chartEditorNoteQuant:SaveProperty<Int>;

  @:saveProperty(data.optionsChartEditor.chartEditorLiveInputStyle, ChartEditorLiveInputStyle.None)
  public var chartEditorLiveInputStyle:SaveProperty<ChartEditorLiveInputStyle>;

  @:saveProperty(data.optionsChartEditor.downscroll, false)
  public var chartEditorDownscroll:SaveProperty<Bool>;

  @:saveProperty(data.optionsChartEditor.showNoteKinds, true)
  public var chartEditorShowNoteKinds:SaveProperty<Bool>;

  @:saveProperty(data.optionsChartEditor.showSubtitles, true)
  public var chartEditorShowSubtitles:SaveProperty<Bool>;

  @:saveProperty(data.optionsChartEditor.playtestStartTime, false)
  public var chartEditorPlaytestStartTime:SaveProperty<Bool>;

  @:saveProperty(data.optionsChartEditor.playtestAudioSettings, false)
  public var chartEditorPlaytestAudioSettings:SaveProperty<Bool>;

  @:saveProperty(data.optionsChartEditor.playtestResultsSettings, false)
  public var chartEditorPlaytestResultsSettings:SaveProperty<Bool>;

  @:saveProperty(data.optionsChartEditor.theme, ChartEditorTheme.Light)
  public var chartEditorTheme:SaveProperty<ChartEditorTheme>;

  @:saveProperty(data.optionsChartEditor.metronomeVolume, 1.0)
  public var chartEditorMetronomeVolume:SaveProperty<Float>;

  @:saveProperty(data.optionsChartEditor.hitsoundVolumePlayer, 1.0)
  public var chartEditorHitsoundVolumePlayer:SaveProperty<Float>;

  @:saveProperty(data.optionsChartEditor.hitsoundVolumeOpponent, 1.0)
  public var chartEditorHitsoundVolumeOpponent:SaveProperty<Float>;

  @:saveProperty(data.optionsChartEditor.instVolume, 1.0)
  public var chartEditorInstVolume:SaveProperty<Float>;

  @:saveProperty(data.optionsChartEditor.playerVoiceVolume, 1.0)
  public var chartEditorPlayerVoiceVolume:SaveProperty<Float>;

  @:saveProperty(data.optionsChartEditor.opponentVoiceVolume, 1.0)
  public var chartEditorOpponentVoiceVolume:SaveProperty<Float>;

  @:saveProperty(data.optionsChartEditor.themeMusic, true)
  public var chartEditorThemeMusic:SaveProperty<Bool>;

  @:saveProperty(data.optionsChartEditor.playbackSpeed, 0.5)
  public var chartEditorPlaybackSpeed:SaveProperty<Float>;

  /**
   * Marks whether a character has been introduced in the Character Select screen.
   */
  @:saveProperty(data.unlocks.charactersSeen, ["bf"])
  public var charactersSeen:SaveProperty<Array<String>>;

  /**
   * Marks whether the player has seen the spotlight animation, which should only display once per save file ever.
   */
  @:saveProperty(data.unlocks.oldChar)
  public var oldChar:SaveProperty<Bool>;

  ///
  /// STAGE EDITOR
  ///
  @:saveProperty(data.optionsStageEditor.previousFiles, [])
  public var stageEditorPreviousFiles:SaveProperty<Array<String>>;
  @:saveProperty(data.optionsStageEditor.hasBackup, false)
  public var stageEditorHasBackup:SaveProperty<Bool>;
  @:saveProperty(data.optionsStageEditor.moveStep, "1px")
  public var stageEditorMoveStep:SaveProperty<String>;
  @:saveProperty(data.optionsStageEditor.angleStep, 5.0)
  public var stageEditorAngleStep:SaveProperty<Float>;
  @:saveProperty(data.optionsStageEditor.theme, StageEditorTheme.Light)
  public var stageEditorTheme:SaveProperty<StageEditorTheme>;

  public var stageBoyfriendChar(get, set):String;

  function get_stageBoyfriendChar():String
  {
    if (data.optionsStageEditor.bfChar == null
      || CharacterDataParser.fetchCharacterData(data.optionsStageEditor.bfChar) == null) data.optionsStageEditor.bfChar = "bf";
    return data.optionsStageEditor.bfChar;
  }

  function set_stageBoyfriendChar(value:String):String
  {
    // Set and apply.
    data.optionsStageEditor.bfChar = value;
    Save.system.flush();
    return data.optionsStageEditor.bfChar;
  }

  public var stageGirlfriendChar(get, set):String;

  function get_stageGirlfriendChar():String
  {
    if (data.optionsStageEditor.gfChar == null
      || CharacterDataParser.fetchCharacterData(data.optionsStageEditor.gfChar ?? "") == null) data.optionsStageEditor.gfChar = "gf";
    return data.optionsStageEditor.gfChar;
  }

  function set_stageGirlfriendChar(value:String):String
  {
    // Set and apply.
    data.optionsStageEditor.gfChar = value;
    Save.system.flush();
    return data.optionsStageEditor.gfChar;
  }

  public var stageDadChar(get, set):String;

  function get_stageDadChar():String
  {
    if (data.optionsStageEditor.dadChar == null
      || CharacterDataParser.fetchCharacterData(data.optionsStageEditor.dadChar ?? "") == null) data.optionsStageEditor.dadChar = "dad";
    return data.optionsStageEditor.dadChar;
  }

  function set_stageDadChar(value:String):String
  {
    // Set and apply.
    data.optionsStageEditor.dadChar = value;
    Save.system.flush();
    return data.optionsStageEditor.dadChar;
  }

  /// UTIL FUNCTIONS

  /**
   * Call this to make sure the save data is written to disk.
   */
  public function flush():Void
  {
    Save.system.flush();
  }

  /**
   * When we've seen a character unlock, add it to the list of characters seen.
   * @param character
   */
  public function addCharacterSeen(character:String):Void
  {
    if (!data.unlocks.charactersSeen.contains(character))
    {
      trace(' SAVE '.bold().bg_note_down() + 'Seen character "$character" in Character Select!');
      data.unlocks.charactersSeen.push(character);
      trace(' SAVE '.bold().bg_note_down() + 'New list of characters seen: ${data.unlocks.charactersSeen}');
      Save.system.flush();
    }
  }

  /**
   * Return the score the user achieved for a given level on a given difficulty.
   *
   * @param levelId The ID of the level/week.
   * @param difficultyId The difficulty to check.
   * @return A data structure containing score, judgement counts, and accuracy. Returns `null` if no score is saved.
   */
  public function getLevelScore(levelId:String, difficultyId:String = 'normal'):Null<SaveScoreData>
  {
    if (data.scores?.levels == null)
    {
      if (data.scores == null)
      {
        data.scores =
          {
            songs: [],
            levels: []
          };
      }
      else
      {
        data.scores.levels = [];
      }
    }
    var level = data.scores.levels.get(levelId);
    if (level == null)
    {
      level = [];
      data.scores.levels.set(levelId, level);
    }
    return level.get(difficultyId);
  }

  /**
   * Apply the score the user achieved for a given level on a given difficulty.
   */
  public function setLevelScore(levelId:String, difficultyId:String, score:SaveScoreData):Void
  {
    var level = data.scores.levels.get(levelId);
    if (level == null)
    {
      level = [];
      data.scores.levels.set(levelId, level);
    }
    level.set(difficultyId, score);
    Save.system.flush();
  }

  public function isLevelHighScore(levelId:String, difficultyId:String = 'normal', score:SaveScoreData):Bool
  {
    var level = data.scores.levels.get(levelId);
    if (level == null)
    {
      level = [];
      data.scores.levels.set(levelId, level);
    }
    var currentScore = level.get(difficultyId);
    if (currentScore == null)
    {
      return true;
    }
    return score.score > currentScore.score;
  }

  public function hasBeatenLevel(levelId:String, ?difficultyList:Array<String>):Bool
  {
    #if UNLOCK_EVERYTHING
    return true;
    #end
    if (difficultyList == null)
    {
      difficultyList = ['easy', 'normal', 'hard'];
    }
    for (difficulty in difficultyList)
    {
      var score:Null<SaveScoreData> = getLevelScore(levelId, difficulty);
      if (score != null)
      {
        if (score.score > 0)
        {
          // Level has score data, which means we cleared it!
          return true;
        }
        else
        {
          // Level has score data, but the score is 0.
          continue;
        }
      }
    }
    return false;
  }

  /**
   * Return the score the user achieved for a given song on a given difficulty.
   *
   * @param songId The ID of the song.
   * @param difficultyId The difficulty to check.
   * @param variation The variation to check. Defaults to empty string. Appended to difficulty with `-`, e.g. `easy-pico`.
   * @return A data structure containing score, judgement counts, and accuracy. Returns `null` if no score is saved.
   */
  public function getSongScore(songId:String, difficultyId:String = 'normal', ?variation:String):Null<SaveScoreData>
  {
    var song = data.scores.songs.get(songId);
    if (song == null)
    {
      trace(' SAVE '.bold().bg_note_down() + ' WARNING '.warning() + 'Could not find song data for $songId $difficultyId $variation');
      song = [];
      data.scores.songs.set(songId, song);
    }
    // 'default' variations are left with no suffix ('easy', 'normal', 'hard'),
    // along with 'erect' variations ('erect', 'nightmare')
    // otherwise, we want to add a suffix of our current variation to get the save data.
    if (variation != null && variation != '' && variation != 'default' && variation != 'erect')
    {
      difficultyId = '${difficultyId}-${variation}';
    }
    return song.get(difficultyId);
  }

  public function getSongRank(songId:String, difficultyId:String = 'normal', ?variation:String):Null<ScoringRank>
  {
    return Scoring.calculateRank(getSongScore(songId, difficultyId, variation));
  }

  /**
   * Directly set the score the user achieved for a given song on a given difficulty.
   */
  public function setSongScore(songId:String, difficultyId:String, score:SaveScoreData):Void
  {
    var song = data.scores.songs.get(songId);
    if (song == null)
    {
      song = [];
      data.scores.songs.set(songId, song);
    }
    song.set(difficultyId, score);
    Save.system.flush();
  }

  /**
   * Only replace the ranking data for the song, because the old score is still better.
   */
  public function applySongRank(songId:String, difficultyId:String, newScoreData:SaveScoreData):Void
  {
    var newRank = Scoring.calculateRank(newScoreData);
    if (newScoreData == null || newRank == null) return;
    var song = data.scores.songs.get(songId);
    if (song == null)
    {
      song = [];
      data.scores.songs.set(songId, song);
    }
    var previousScoreData = song.get(difficultyId);
    var previousRank = Scoring.calculateRank(previousScoreData);
    if (previousScoreData == null || previousRank == null)
    {
      // Directly set the highscore.
      setSongScore(songId, difficultyId, newScoreData);
      return;
    }
    // Set the high score and the high rank separately.
    var newScore:SaveScoreData =
      {
        score: (previousScoreData.score > newScoreData.score) ? previousScoreData.score : newScoreData.score,
        tallies: (previousRank > newRank
          || Scoring.tallyCompletion(previousScoreData.tallies) > Scoring.tallyCompletion(newScoreData.tallies)) ? previousScoreData.tallies : newScoreData.tallies
      };
    song.set(difficultyId, newScore);
    Save.system.flush();
  }

  /**
   * Is the provided score data better than the current high score for the given song?
   * @param songId The song ID to check.
   * @param difficultyId The difficulty to check.
   * @param score The score to check.
   * @return Whether the score is better than the current high score.
   */
  public function isSongHighScore(songId:String, difficultyId:String = 'normal', score:SaveScoreData):Bool
  {
    var song = data.scores.songs.get(songId);
    if (song == null)
    {
      song = [];
      data.scores.songs.set(songId, song);
    }
    var currentScore = song.get(difficultyId);
    if (currentScore == null)
    {
      return true;
    }
    return score.score > currentScore.score;
  }

  /**
   * Is the provided score data better than the current rank for the given song?
   * @param songId The song ID to check.
   * @param difficultyId The difficulty to check.
   * @param score The score to check the rank for.
   * @return Whether the score's rank is better than the current rank.
   */
  public function isSongHighRank(songId:String, difficultyId:String = 'normal', score:SaveScoreData):Bool
  {
    var newScoreRank = Scoring.calculateRank(score);
    if (newScoreRank == null)
    {
      // The provided score is invalid.
      return false;
    }
    var song = data.scores.songs.get(songId);
    if (song == null)
    {
      song = [];
      data.scores.songs.set(songId, song);
    }
    var currentScore = song.get(difficultyId);
    var currentScoreRank = Scoring.calculateRank(currentScore);
    if (currentScoreRank == null)
    {
      // There is no primary highscore for this song.
      return true;
    }
    return newScoreRank > currentScoreRank;
  }

  /**
   * Has the provided song been beaten on one of the listed difficulties?
   * Note: This function can still take in the 'difficulty-variation' format for the difficultyList parameter
   * as it is used in the old save data format. However inputting a variation will append it to the difficulty
   * so you can do `hasBeatenSong('dadbattle', ['easy-pico'])` to check if you've beaten the Pico mix on easy.
   * or you can do `hasBeatenSong('dadbattle', ['easy'], 'pico')` to check if you've beaten the Pico mix on easy.
   * however you should not mix the two as it will append '-pico' to the 'easy-pico' if it's inputted into the array.
   * @param songId The song ID to check.
   * @param difficultyList The difficulties to check. Defaults to `easy`, `normal`, and `hard`.
   * @param variation The variation to check. Defaults to empty string. Appended to difficulty list with `-`, e.g. `easy-pico`.
   *                  This is our old format for getting difficulty/variation information, however we don't want to mess around with
   *                  save migration just yet.
   * @return Whether the song has been beaten on any of the listed difficulties.
   */
  public function hasBeatenSong(songId:String, ?difficultyList:Array<String>, ?variation:String):Bool
  {
    if (difficultyList == null)
    {
      difficultyList = ['easy', 'normal', 'hard'];
    }
    if (variation == null) variation = '';
    for (difficulty in difficultyList)
    {
      if (variation != '') difficulty = '${difficulty}-${variation}';
      var score:Null<SaveScoreData> = getSongScore(songId, difficulty);
      if (score != null)
      {
        #if NO_UNLOCK_EVERYTHING
        if (score.score > 0)
        {
          // Level has score data, which means we cleared it!
          return true;
        }
        else
        {
          // Level has score data, but the score is 0.
          continue;
        }
        #else
        return true;
        #end
      }
    }
    return false;
  }

  public function isSongFavorited(id:String):Bool
  {
    if (data.favoriteSongs == null)
    {
      data.favoriteSongs = [];
      Save.system.flush();
    };
    return data.favoriteSongs.contains(id);
  }

  public function favoriteSong(id:String):Void
  {
    if (!isSongFavorited(id))
    {
      data.favoriteSongs.push(id);
      Save.system.flush();
    }
  }

  public function unfavoriteSong(id:String):Void
  {
    if (isSongFavorited(id))
    {
      data.favoriteSongs.remove(id);
      Save.system.flush();
    }
  }

  public function getControls(playerId:Int, inputType:Device):Null<SaveControlsData>
  {
    switch (inputType)
    {
      case Keys:
        return (playerId == 0) ? data?.options?.controls?.p1.keyboard : data?.options?.controls?.p2.keyboard;
      case Gamepad(_):
        return (playerId == 0) ? data?.options?.controls?.p1.gamepad : data?.options?.controls?.p2.gamepad;
    }
  }

  public function hasControls(playerId:Int, inputType:Device):Bool
  {
    var controls = getControls(playerId, inputType);
    if (controls == null) return false;
    var controlsFields = Reflect.fields(controls);
    return controlsFields.length > 0;
  }

  public function setControls(playerId:Int, inputType:Device, controls:SaveControlsData):Void
  {
    final getPlayer:Int->PlayerControlData = function(id) return id == 0 ? data.options.controls.p1 : data.options.controls.p2;
    switch (inputType)
    {
      case Keys:
        getPlayer(playerId).keyboard = controls;
      case Gamepad(_):
        getPlayer(playerId).gamepad = controls;
    }
  }

  public function isCharacterUnlocked(characterId:String):Bool
  {
    switch (characterId)
    {
      case 'bf':
        return true;
      case 'pico':
        return hasBeatenLevel('weekend1');
      default:
        trace('Unknown character ID: ' + characterId);
        return true;
    }
  }

  /**
   * Retrieve the mod options object for a given mod ID.
   * This is a dynamic object that mods can write any values they like to.
   *
   * @param modId The mod ID to retrieve
   * @return The mod options for the given mod ID.
   */
  public function getModOptions(modId:String):Dynamic
  {
    if (!data.mods.modOptions.exists(modId))
    {
      data.mods.modOptions.set(modId, {});
    }

    return data.mods.modOptions.get(modId);
  }

  /**
   * Store the mod options object for a given mod ID.
   * Call this function to ensure your changes get written to the user's save file.
   *
   * @param modId The mod ID to store data for.
   * @param options The mod options object.
   */
  public function setModOptions(modId:String, options:Dynamic):Void
  {
    data.mods.modOptions.set(modId, options);
    Save.system.flush();
  }

  /**
   * If you set slot to `2`, it will load an independent save file from slot 2.
   * @param slot
   */
  @:haxe.warning("-WDeprecated")
  static function loadFromSlot(slot:Int):Save
  {
    trace('[SAVE] Loading save from slot $slot...');
    FlxG.save.bind(Constants.SAVE_NAME + slot, Constants.SAVE_PATH);
    switch (FlxG.save.status)
    {
      case EMPTY:
        trace('[SAVE] Save data in slot ${slot} is empty, checking for legacy save data...');
        switch (Save.system.fetchLegacySaveData())
        {
          case None:
            trace('[SAVE] No legacy save data found.');
            var gameSave:Save = new Save();
            FlxG.save.mergeData(gameSave.data, true);
            return gameSave;
          case Some(legacySaveData):
            trace('[SAVE] Found legacy save data, converting...');
            var gameSave = SaveDataMigrator.migrateFromLegacy(legacySaveData);
            FlxG.save.mergeData(gameSave.data, true);
            return gameSave;
        }
      case ERROR(_): // DEPRECATED: Unused
        return handleSaveDataError(slot);
      case SAVE_ERROR(_):
        return handleSaveDataError(slot);
      case LOAD_ERROR(_):
        return handleSaveDataError(slot);
      case BOUND(_, _):
        trace('[SAVE] Loaded existing save data in slot ${slot}.');
        var gameSave = SaveDataMigrator.migrate(FlxG.save.data);
        FlxG.save.mergeData(gameSave.data, true);
        return gameSave;
    }
  }

  /**
   * Call this when there is an error loading the save data in slot X.
   */
  static function handleSaveDataError(slot:Int):Save
  {
    var msg = 'There was an error loading your save data in slot ${slot}.';
    msg += '\nPlease report this issue to the developers.';
    funkin.util.WindowUtil.showError("Save Data Failure", msg);
    // Don't touch that slot anymore.
    // Instead, load the next available slot.
    var nextSlot:Int = slot + 1;
    if (nextSlot > 1000) throw "End of save data slots. Can't load any more.";
    return loadFromSlot(nextSlot);
  }

  public static function debug_queryBadSaveData():Void
  {
    final RECOVERY_SLOT_START = 1000;
    final RECOVERY_SLOT_END = 1100;
    var firstBadSaveData = querySlotRange(RECOVERY_SLOT_START, RECOVERY_SLOT_END);
    if (firstBadSaveData > 0)
    {
      trace('[SAVE] Found bad save data in slot ${firstBadSaveData}!');
      trace('We should look into recovery...');
      trace(haxe.Json.stringify(fetchFromSlotRaw(firstBadSaveData)));
    }
  }

  static function fetchFromSlotRaw(slot:Int):Null<Dynamic>
  {
    var targetSaveData = new FlxSave();
    targetSaveData.bind(Constants.SAVE_NAME + slot, Constants.SAVE_PATH);
    if (targetSaveData.isEmpty()) return null;
    return targetSaveData.data;
  }

  /**
   * Return true if the given save slot is not empty.
   * @param slot The slot number to check.
   * @return Whether the slot is not empty.
   */
  @:haxe.warning("-WDeprecated")
  static function querySlot(slot:Int):Bool
  {
    var targetSaveData:FlxSave = new FlxSave();
    targetSaveData.bind(Constants.SAVE_NAME + slot, Constants.SAVE_PATH);
    switch (targetSaveData.status)
    {
      case EMPTY:
        return false;
      case ERROR(_): // DEPRECATED: Unused
        return false;
      case LOAD_ERROR(_):
        return false;
      case SAVE_ERROR(_):
        return false;
      case BOUND(_, _):
        return true;
    }
  }

  /**
   * Return true if any of the slots in the given range is not empty.
   * @param start The starting slot number to check.
   * @param end The ending slot number to check.
   * @return The first slot in the range that is not empty, or `-1` if none are.
   */
  static function querySlotRange(start:Int, end:Int):Int
  {
    for (i in start...end)
    {
      if (querySlot(i)) return i;
    }
    return -1;
  }

  /**
   * Serialize this Save into a JSON string.
   * @param pretty Whether the JSON should be big ol string (false),
   *        or pretty printed formatted with tabs (true)
   * @return The JSON string.
   */
  public function serializeJson(pretty:Bool = true):String
  {
    var ignoreNullOptionals:Bool = true;
    var writer = new json2object.JsonWriter<RawSaveData>(ignoreNullOptionals);
    return writer.write(data, pretty ? ' ' : null);
  }

  public function updateVersionToLatest():Void
  {
    this.data.version = Save.SAVE_DATA_VERSION;
  }

  public function debug_dumpSaveJsonSave():Void
  {
    FileUtil.saveFile(haxe.io.Bytes.ofString(this.serializeJson()), [FileUtil.FILE_FILTER_JSON], null, null, './save.json', 'Write save data as JSON...');
  }

  public function debug_dumpSaveJsonPrint():Void
  {
    trace(this.serializeJson());
  }

  #if FEATURE_NEWGROUNDS
  public static function saveToNewgrounds():Void
  {
    if (_instance == null) return;
    trace('[SAVE] Saving Save Data to Newgrounds...');
    funkin.api.newgrounds.NGSaveSlot.instance.save(_instance.data);
  }

  public static function loadFromNewgrounds(onFinish:Void->Void):Void
  {
    trace('[SAVE] Loading Save Data from Newgrounds...');

    funkin.api.newgrounds.NGSaveSlot.instance.load((data:Dynamic) -> {
      FlxG.save.bind(Constants.SAVE_NAME + Constants.BASE_SAVE_SLOT, Constants.SAVE_PATH);

      if (FlxG.save.status != EMPTY)
      {
        // best i can do in case the NG file is corrupted or something along those lines
        var backupSlot:Int = Save.system.archiveBadSaveData(FlxG.save.data);
        trace('[SAVE] Backed up current save data in case of emergency to $backupSlot!');
      }

      FlxG.save.erase();
      FlxG.save.bind(Constants.SAVE_NAME + Constants.BASE_SAVE_SLOT, Constants.SAVE_PATH); // forces regeneration of the file as erase deletes it

      var gameSave = SaveDataMigrator.migrate(data);
      FlxG.save.mergeData(gameSave.data, true);
      _instance = gameSave;
      onFinish();
    }, (error:io.newgrounds.Call.CallError) -> {
      var errorMsg:String = io.newgrounds.Call.CallErrorTools.toString(error);

      var msg = 'There was an error loading your save data from Newgrounds.';
      msg += '\n${errorMsg}';
      msg += '\nAre you sure you are connected to the internet?';
      funkin.util.WindowUtil.showError("Newgrounds Save Slot Failure", msg);
    });
  }
  #end
}

/**
 * An anonymous structure containingg all the user's save data.
 * Isn't stored with JSON, stored with some sort of Haxe built-in serialization?
 */
typedef RawSaveData =
{
  // Flixel save data.
  var volume:Float;
  var mute:Bool;

  /**
   * A semantic versioning string for the save data format.
   */
  var version:Version;

  var api:SaveApiData;

  /**
   * The user's saved scores.
   */
  var scores:SaveHighScoresData;

  /**
   * The user's preferences.
   */
  var options:SaveDataOptions;

  var unlocks:SaveDataUnlocks;

  #if mobile
  /**
   * The user's preferences for mobile.
   */
  var mobileOptions:SaveDataMobileOptions;
  #end

  /**
   * The user's favorited songs in the Freeplay menu,
   * as a list of song IDs.
   */
  var favoriteSongs:Array<String>;

  var mods:SaveDataMods;

  /**
   * The user's preferences specific to the Chart Editor.
   */
  var optionsChartEditor:SaveDataChartEditorOptions;

  /**
   * The user's preferences specific to the Stage Editor.
   */
  var optionsStageEditor:SaveDataStageEditorOptions;
};

typedef SaveApiData =
{
  var newgrounds:SaveApiNewgroundsData;
}

typedef SaveApiNewgroundsData =
{
  var sessionId:Null<String>;
}

typedef SaveDataUnlocks =
{
  /**
   * Every time we see the unlock animation for a character,
   * add it to this list so that we don't show it again.
   */
  var charactersSeen:Array<String>;

  /**
   * This is a conditional when the player enters the character state
   * For the first time ever
   */
  var oldChar:Bool;
}

/**
 * An anoymous structure containing options about the user's high scores.
 */
typedef SaveHighScoresData =
{
  /**
   * Scores for each level (or week).
   */
  var levels:SaveScoreLevelsData;

  /**
   * Scores for individual songs.
   */
  var songs:SaveScoreSongsData;
};

typedef SaveDataMods =
{
  var enabledMods:Array<String>;
  // TODO: Make this not trip up the serializer when debugging.
  @:jignored
  var modOptions:Map<String, Dynamic>;
}

/**
 * Key is the level ID, value is the SaveScoreLevelData.
 */
typedef SaveScoreLevelsData = Map<String, SaveScoreDifficultiesData>;

/**
 * Key is the song ID, value is the data for each difficulty.
 */
typedef SaveScoreSongsData = Map<String, SaveScoreDifficultiesData>;

/**
 * Key is the difficulty ID, value is the score.
 */
typedef SaveScoreDifficultiesData = Map<String, SaveScoreData>;

/**
 * An individual score. Contains the score, accuracy, and count of each judgement hit.
 */
typedef SaveScoreData =
{
  /**
   * The score achieved.
   */
  var score:Int;

  /**
   * The count of each judgement hit.
   */
  var tallies:SaveScoreTallyData;
}

typedef SaveScoreTallyData =
{
  var sick:Int;
  var good:Int;
  var bad:Int;
  var shit:Int;
  var missed:Int;
  var combo:Int;
  var maxCombo:Int;
  var totalNotesHit:Int;
  var totalNotes:Int;
}

/**
 * An anonymous structure containing all the user's options and preferences for the main game.
 * Every time you add a new option, it needs to be added here.
 */
typedef SaveDataOptions =
{
  /**
   * FPS
   * @default `60`
   */
  var framerate:Int;

  /**
   * Whether some particularly foul language is displayed.
   * @default `true`
   */
  var naughtyness:Bool;

  /**
   * If enabled, the strumline is at the bottom of the screen rather than the top.
   * @default `false`
   */
  var downscroll:Bool;

  /**
   * If disabled, flashing lights in the main menu and other areas will be less intense.
   * @default `true`
   */
  var flashingLights:Bool;

  /**
   * If disabled, the camera bump synchronized to the beat.
   * @default `false`
   */
  var zoomCamera:Bool;

  /**
   * If enabled, an FPS and memory counter will be displayed even if this is not a debug build.
   * @default `Off`
   */
  var debugDisplay:String;

  /**
   * Opacity of the debug display's background.
   * @default `50`
   */
  var debugDisplayBGOpacity:Int;

  /**
   * If enabled, subtitles will appear.
   * @default `true`
   */
  var subtitles:Bool;

  /**
   * If enabled, haptic feedback will be enabled.
   * @default `All`
   */
  var hapticsMode:String;

  /**
   * Multiplier of intensity for all the haptic feedback effects.
   * @default `1`
   */
  var hapticsIntensityMultiplier:Float;

  /**
   * If enabled, the game will automatically pause when tabbing out.
   * @default `true`
   */
  var autoPause:Bool;

  /**
   * If enabled, the game will utilize VSync (or adaptive VSync) on startup.
   * @default `Off`
   */
  var vsyncMode:String;

  /**
   * If >0, the game will display a semi-opaque background under the notes.
   * `0` for no background, `100` for solid black if you're freaky like that
   * @default `0`
   */
  var strumlineBackgroundOpacity:Int;

  /**
   * If enabled, the game will automatically launch in fullscreen on startup.
   * @default `true`
   */
  var autoFullscreen:Bool;

  /**
   * Offset the user's inputs by this many ms.
   * @default `0`
   */
  var globalOffset:Int;

  /**
   * Unused !!
   * Affects the delay between the audio and the visuals during gameplay.
   * @default `0`
   */
  var audioVisualOffset:Int;

  /**
   * If we want the framerate to be unlocked on HTML5.
   * @default `false`
   */
  var unlockedFramerate:Bool;

  /**
   * Screenshot options
   * @param shouldHideMouse Should the mouse be hidden when taking a screenshot? Default: `true`
   * @param fancyPreview Show a fancy preview? Default: `true`
   * @param previewOnSave Only show the fancy preview after a screenshot is saved? Default: `true`
   */
  var screenshot:
    {
      var shouldHideMouse:Bool;
      var fancyPreview:Bool;
      var previewOnSave:Bool;
    };

  var controls:
    {
      var p1:PlayerControlData;
      var p2:PlayerControlData;
    };
}

typedef PlayerControlData =
{
  var keyboard:SaveControlsData;
  var gamepad:SaveControlsData;
}

#if mobile
typedef SaveDataMobileOptions =
{
  /**
   * If enabled, device will be able to sleep on its own.
   * @default `false`
   */
  var screenTimeout:Bool;

  /**
   * Controls scheme for the hitbox.
   * @default `Arrows`
   */
  var controlsScheme:String;

  /**
   * If bought, the game will not show any ads.
   * @default `false`
   */
  var noAds:Bool;
}
#end

/**
 * An anonymous structure containing a specific player's bound keys.
 * Each key is an action name and each value is an array of keycodes.
 *
 * If a keybind is `null`, it needs to be reinitialized to the default.
 * If a keybind is `[]`, it is UNBOUND by the user and should not be rebound.
 */
typedef SaveControlsData =
{
  /**
   * Keybind for navigating in the menu.
   * @default `Up Arrow`
   */
  var ?UI_UP:Array<Int>;

  /**
   * Keybind for navigating in the menu.
   * @default `Left Arrow`
   */
  var ?UI_LEFT:Array<Int>;

  /**
   * Keybind for navigating in the menu.
   * @default `Right Arrow`
   */
  var ?UI_RIGHT:Array<Int>;

  /**
   * Keybind for navigating in the menu.
   * @default `Down Arrow`
   */
  var ?UI_DOWN:Array<Int>;

  /**
   * Keybind for hitting notes.
   * @default `A` and `Left Arrow`
   */
  var ?NOTE_LEFT:Array<Int>;

  /**
   * Keybind for hitting notes.
   * @default `W` and `Up Arrow`
   */
  var ?NOTE_UP:Array<Int>;

  /**
   * Keybind for hitting notes.
   * @default `S` and `Down Arrow`
   */
  var ?NOTE_DOWN:Array<Int>;

  /**
   * Keybind for hitting notes.
   * @default `D` and `Right Arrow`
   */
  var ?NOTE_RIGHT:Array<Int>;

  /**
   * Keybind for continue/OK in menus.
   * @default `Enter` and `Space`
   */
  var ?ACCEPT:Array<Int>;

  /**
   * Keybind for back/cancel in menus.
   * @default `Escape`
   */
  var ?BACK:Array<Int>;

  /**
   * Keybind for pausing the game.
   * @default `Escape`
   */
  var ?PAUSE:Array<Int>;

  /**
   * Keybind for advancing cutscenes.
   * @default `Z` and `Space` and `Enter`
   */
  var ?CUTSCENE_ADVANCE:Array<Int>;

  /**
   * Keybind for increasing volume.
   * @default `Plus`
   */
  var ?VOLUME_UP:Array<Int>;

  /**
   * Keybind for decreasing volume.
   * @default `Minus`
   */
  var ?VOLUME_DOWN:Array<Int>;

  /**
   * Keybind for muting/unmuting volume.
   * @default `Zero`
   */
  var ?VOLUME_MUTE:Array<Int>;

  /**
   * Keybind for restarting a song.
   * @default `R`
   */
  var ?RESET:Array<Int>;
}

/**
 * An anonymous structure containing all the user's options and preferences, specific to the Chart Editor.
 */
typedef SaveDataChartEditorOptions =
{
  /**
   * Whether the Chart Editor created a backup the last time it closed.
   * Prompt the user to load it, then set this back to `false`.
   * @default `false`
   */
  var ?hasBackup:Bool;

  /**
   * Previous files opened in the Chart Editor.
   * @default `[]`
   */
  var ?previousFiles:Array<String>;

  /**
   * Note snapping level in the Chart Editor.
   * @default `3`
   */
  var ?noteQuant:Int;

  /**
   * Live input style in the Chart Editor.
   * @default `ChartEditorLiveInputStyle.None`
   */
  var ?chartEditorLiveInputStyle:ChartEditorLiveInputStyle;

  /**
   * Theme in the Chart Editor.
   * @default `ChartEditorTheme.Light`
   */
  var ?theme:ChartEditorTheme;

  /**
   * Downscroll in the Chart Editor.
   * @default `false`
   */
  var ?downscroll:Bool;

  /**
   * Show Note Kind Indicator in the Chart Editor.
   * @default `true`
   */
  var ?showNoteKinds:Bool;

  /**
   * Show Subtitles in the Chart Editor.
   * @default `true`
   */
  var ?showSubtitles:Bool;

  /**
   * Metronome volume in the Chart Editor.
   * @default `1.0`
   */
  var ?metronomeVolume:Float;

  /**
   * Hitsound volume (player) in the Chart Editor.
   * @default `1.0`
   */
  var ?hitsoundVolumePlayer:Float;

  /**
   * Hitsound volume (opponent) in the Chart Editor.
   * @default `1.0`
   */
  var ?hitsoundVolumeOpponent:Float;

  /**
   * If true, playtest songs from the current position in the Chart Editor.
   * @default `false`
   */
  var ?playtestStartTime:Bool;

  /**
   * If true, playtest songs with the current audio settings in the Chart Editor.
   * @default `false`
   */
  var ?playtestAudioSettings:Bool;

  /**
   * If true, playtest songs will play the results screen on completion.
   * @default `false`
   */
  var ?playtestResultsSettings:Bool;

  /**
   * Theme music in the Chart Editor.
   * @default `true`
   */
  var ?themeMusic:Bool;

  /**
   * Instrumental volume in the Chart Editor.
   * @default `1.0`
   */
  var ?instVolume:Float;

  /**
   * Player voice volume in the Chart Editor.
   * @default `1.0`
   */
  var ?playerVoiceVolume:Float;

  /**
   * Opponent voice volume in the Chart Editor.
   * @default `1.0`
   */
  var ?opponentVoiceVolume:Float;

  /**
   * Playback speed in the Chart Editor.
   * @default `1.0`
   */
  var ?playbackSpeed:Float;
}

typedef SaveDataStageEditorOptions =
{
  // a lot of these things were copied from savedatacharteditoroptions

  /**
   * Whether the Stage Editor created a backup the last time it closed.
   * Prompt the user to load it, then set this back to `false`.
   * @default `false`
   */
  var ?hasBackup:Bool;

  /**
   * Previous files opened in the Stage Editor.
   * @default `[]`
   */
  var ?previousFiles:Array<String>;

  /**
   * The Step at which an Object or Character is moved.
   * @default `1px`
   */
  var ?moveStep:String;

  /**
   * The Step at which an Object is rotated.
   * @default `5`
   */
  var ?angleStep:Float;

  /**
   * Theme in the Stage Editor.
   * @default `StageEditorTheme.Light`
   */
  var ?theme:StageEditorTheme;

  /**
   * The BF character ID used in testing stages.
   * @default bf
   */
  var ?bfChar:String;

  /**
   * The GF character ID used in testing stages.
   * @default gf
   */
  var ?gfChar:String;

  /**
   * The Dad character ID used in testing stages.
   * @default dad
   */
  var ?dadChar:String;
}
