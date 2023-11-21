package funkin.save;

import flixel.util.FlxSave;
import funkin.save.migrator.SaveDataMigrator;
import thx.semver.Version;
import funkin.input.Controls.Device;
import funkin.save.migrator.RawSaveData_v1_0_0;
import funkin.save.migrator.SaveDataMigrator;
import funkin.ui.debug.charting.ChartEditorState.ChartEditorLiveInputStyle;
import funkin.ui.debug.charting.ChartEditorState.ChartEditorTheme;
import thx.semver.Version;

@:nullSafety
@:forward(volume, mute)
abstract Save(RawSaveData)
{
  // Version 2.0.1 adds attributes to `optionsChartEditor`, that should return default values if they are null.
  public static final SAVE_DATA_VERSION:thx.semver.Version = "2.0.1";
  public static final SAVE_DATA_VERSION_RULE:thx.semver.VersionRule = "2.0.x";

  // We load this version's saves from a new save path, to maintain SOME level of backwards compatibility.
  static final SAVE_PATH:String = 'FunkinCrew';
  static final SAVE_NAME:String = 'Funkin';

  static final SAVE_PATH_LEGACY:String = 'ninjamuffin99';
  static final SAVE_NAME_LEGACY:String = 'funkin';

  public static function load():Void
  {
    trace("[SAVE] Loading save...");

    // Bind save data.
    loadFromSlot(1);
  }

  public static function get():Save
  {
    return FlxG.save.data;
  }

  /**
   * Constructing a new Save will load the default values.
   */
  public function new()
  {
    this =
      {
        version: Save.SAVE_DATA_VERSION,

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
        options:
          {
            // Reasonable defaults.
            naughtyness: true,
            downscroll: false,
            flashingLights: true,
            zoomCamera: true,
            debugDisplay: false,
            autoPause: true,

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

        mods:
          {
            // No mods enabled.
            enabledMods: [],
            modOptions: [],
          },

        optionsChartEditor:
          {
            // Reasonable defaults.
            previousFiles: [],
            noteQuant: 3,
            chartEditorLiveInputStyle: ChartEditorLiveInputStyle.None,
            theme: ChartEditorTheme.Light,
            playtestStartTime: false,
            downscroll: false,
            metronomeEnabled: true,
            hitsoundsEnabledPlayer: true,
            hitsoundsEnabledOpponent: true,
            instVolume: 1.0,
            voicesVolume: 1.0,
            playbackSpeed: 1.0,
          },
      };
  }

  public var options(get, never):SaveDataOptions;

  function get_options():SaveDataOptions
  {
    return this.options;
  }

  public var modOptions(get, never):Map<String, Dynamic>;

  function get_modOptions():Map<String, Dynamic>
  {
    return this.mods.modOptions;
  }

  /**
   * The current session ID for the logged-in Newgrounds user, or null if the user is cringe.
   */
  public var ngSessionId(get, set):Null<String>;

  function get_ngSessionId():Null<String>
  {
    return this.api.newgrounds.sessionId;
  }

  function set_ngSessionId(value:Null<String>):Null<String>
  {
    this.api.newgrounds.sessionId = value;
    flush();
    return this.api.newgrounds.sessionId;
  }

  public var enabledModIds(get, set):Array<String>;

  function get_enabledModIds():Array<String>
  {
    return this.mods.enabledMods;
  }

  function set_enabledModIds(value:Array<String>):Array<String>
  {
    this.mods.enabledMods = value;
    flush();
    return this.mods.enabledMods;
  }

  public var chartEditorPreviousFiles(get, set):Array<String>;

  function get_chartEditorPreviousFiles():Array<String>
  {
    if (this.optionsChartEditor.previousFiles == null) this.optionsChartEditor.previousFiles = [];

    return this.optionsChartEditor.previousFiles;
  }

  function set_chartEditorPreviousFiles(value:Array<String>):Array<String>
  {
    // Set and apply.
    this.optionsChartEditor.previousFiles = value;
    flush();
    return this.optionsChartEditor.previousFiles;
  }

  public var chartEditorHasBackup(get, set):Bool;

  function get_chartEditorHasBackup():Bool
  {
    if (this.optionsChartEditor.hasBackup == null) this.optionsChartEditor.hasBackup = [];

    return this.optionsChartEditor.hasBackup;
  }

  function set_chartEditorHasBackup(value:Array<String>):Bool
  {
    // Set and apply.
    this.optionsChartEditor.hasBackup = value;
    flush();
    return this.optionsChartEditor.hasBackup;
  }

  public var chartEditorNoteQuant(get, set):Int;

  function get_chartEditorNoteQuant():Int
  {
    if (this.optionsChartEditor.noteQuant == null) this.optionsChartEditor.noteQuant = 3;

    return this.optionsChartEditor.noteQuant;
  }

  function set_chartEditorNoteQuant(value:Int):Int
  {
    // Set and apply.
    this.optionsChartEditor.noteQuant = value;
    flush();
    return this.optionsChartEditor.noteQuant;
  }

  public var chartEditorLiveInputStyle(get, set):ChartEditorLiveInputStyle;

  function get_chartEditorLiveInputStyle():ChartEditorLiveInputStyle
  {
    if (this.optionsChartEditor.chartEditorLiveInputStyle == null) this.optionsChartEditor.chartEditorLiveInputStyle = ChartEditorLiveInputStyle.None;

    return this.optionsChartEditor.chartEditorLiveInputStyle;
  }

  function set_chartEditorLiveInputStyle(value:ChartEditorLiveInputStyle):ChartEditorLiveInputStyle
  {
    // Set and apply.
    this.optionsChartEditor.chartEditorLiveInputStyle = value;
    flush();
    return this.optionsChartEditor.chartEditorLiveInputStyle;
  }

  public var chartEditorDownscroll(get, set):Bool;

  function get_chartEditorDownscroll():Bool
  {
    if (this.optionsChartEditor.downscroll == null) this.optionsChartEditor.downscroll = false;

    return this.optionsChartEditor.downscroll;
  }

  function set_chartEditorDownscroll(value:Bool):Bool
  {
    // Set and apply.
    this.optionsChartEditor.downscroll = value;
    flush();
    return this.optionsChartEditor.downscroll;
  }

  public var chartEditorPlaytestStartTime(get, set):Bool;

  function get_chartEditorPlaytestStartTime():Bool
  {
    if (this.optionsChartEditor.playtestStartTime == null) this.optionsChartEditor.playtestStartTime = false;

    return this.optionsChartEditor.playtestStartTime;
  }

  function set_chartEditorPlaytestStartTime(value:Bool):Bool
  {
    // Set and apply.
    this.optionsChartEditor.playtestStartTime = value;
    flush();
    return this.optionsChartEditor.playtestStartTime;
  }

  public var chartEditorTheme(get, set):ChartEditorTheme;

  function get_chartEditorTheme():ChartEditorTheme
  {
    if (this.optionsChartEditor.theme == null) this.optionsChartEditor.theme = ChartEditorTheme.Light;

    return this.optionsChartEditor.theme;
  }

  function set_chartEditorTheme(value:ChartEditorTheme):ChartEditorTheme
  {
    // Set and apply.
    this.optionsChartEditor.theme = value;
    flush();
    return this.optionsChartEditor.theme;
  }

  public var chartEditorMetronomeEnabled(get, set):Bool;

  function get_chartEditorMetronomeEnabled():Bool
  {
    if (this.optionsChartEditor.metronomeEnabled == null) this.optionsChartEditor.metronomeEnabled = true;

    return this.optionsChartEditor.metronomeEnabled;
  }

  function set_chartEditorMetronomeEnabled(value:Bool):Bool
  {
    // Set and apply.
    this.optionsChartEditor.metronomeEnabled = value;
    flush();
    return this.optionsChartEditor.metronomeEnabled;
  }

  public var chartEditorHitsoundsEnabledPlayer(get, set):Bool;

  function get_chartEditorHitsoundsEnabledPlayer():Bool
  {
    if (this.optionsChartEditor.hitsoundsEnabledPlayer == null) this.optionsChartEditor.hitsoundsEnabledPlayer = true;

    return this.optionsChartEditor.hitsoundsEnabledPlayer;
  }

  function set_chartEditorHitsoundsEnabledPlayer(value:Bool):Bool
  {
    // Set and apply.
    this.optionsChartEditor.hitsoundsEnabledPlayer = value;
    flush();
    return this.optionsChartEditor.hitsoundsEnabledPlayer;
  }

  public var chartEditorHitsoundsEnabledOpponent(get, set):Bool;

  function get_chartEditorHitsoundsEnabledOpponent():Bool
  {
    if (this.optionsChartEditor.hitsoundsEnabledOpponent == null) this.optionsChartEditor.hitsoundsEnabledOpponent = true;

    return this.optionsChartEditor.hitsoundsEnabledOpponent;
  }

  function set_chartEditorHitsoundsEnabledOpponent(value:Bool):Bool
  {
    // Set and apply.
    this.optionsChartEditor.hitsoundsEnabledOpponent = value;
    flush();
    return this.optionsChartEditor.hitsoundsEnabledOpponent;
  }

  public var chartEditorInstVolume(get, set):Float;

  function get_chartEditorInstVolume():Float
  {
    if (this.optionsChartEditor.instVolume == null) this.optionsChartEditor.instVolume = 1.0;

    return this.optionsChartEditor.instVolume;
  }

  function set_chartEditorInstVolume(value:Float):Float
  {
    // Set and apply.
    this.optionsChartEditor.instVolume = value;
    flush();
    return this.optionsChartEditor.instVolume;
  }

  public var chartEditorVoicesVolume(get, set):Float;

  function get_chartEditorVoicesVolume():Float
  {
    if (this.optionsChartEditor.voicesVolume == null) this.optionsChartEditor.voicesVolume = 1.0;

    return this.optionsChartEditor.voicesVolume;
  }

  function set_chartEditorVoicesVolume(value:Float):Float
  {
    // Set and apply.
    this.optionsChartEditor.voicesVolume = value;
    flush();
    return this.optionsChartEditor.voicesVolume;
  }

  public var chartEditorPlaybackSpeed(get, set):Float;

  function get_chartEditorPlaybackSpeed():Float
  {
    if (this.optionsChartEditor.playbackSpeed == null) this.optionsChartEditor.playbackSpeed = 1.0;

    return this.optionsChartEditor.playbackSpeed;
  }

  function set_chartEditorPlaybackSpeed(value:Float):Float
  {
    // Set and apply.
    this.optionsChartEditor.playbackSpeed = value;
    flush();
    return this.optionsChartEditor.playbackSpeed;
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
    var level = this.scores.levels.get(levelId);
    if (level == null)
    {
      level = [];
      this.scores.levels.set(levelId, level);
    }

    return level.get(difficultyId);
  }

  /**
   * Apply the score the user achieved for a given level on a given difficulty.
   */
  public function setLevelScore(levelId:String, difficultyId:String, score:SaveScoreData):Void
  {
    var level = this.scores.levels.get(levelId);
    if (level == null)
    {
      level = [];
      this.scores.levels.set(levelId, level);
    }
    level.set(difficultyId, score);

    flush();
  }

  public function isLevelHighScore(levelId:String, difficultyId:String = 'normal', score:SaveScoreData):Bool
  {
    var level = this.scores.levels.get(levelId);
    if (level == null)
    {
      level = [];
      this.scores.levels.set(levelId, level);
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
    if (difficultyList == null)
    {
      difficultyList = ['easy', 'normal', 'hard'];
    }
    for (difficulty in difficultyList)
    {
      var score:Null<SaveScoreData> = getLevelScore(levelId, difficulty);
      // TODO: Do we need to check accuracy/score here?
      if (score != null)
      {
        return true;
      }
    }
    return false;
  }

  /**
   * Return the score the user achieved for a given song on a given difficulty.
   *
   * @param songId The ID of the song.
   * @param difficultyId The difficulty to check.
   * @return A data structure containing score, judgement counts, and accuracy. Returns `null` if no score is saved.
   */
  public function getSongScore(songId:String, difficultyId:String = 'normal'):Null<SaveScoreData>
  {
    var song = this.scores.songs.get(songId);
    if (song == null)
    {
      song = [];
      this.scores.songs.set(songId, song);
    }
    return song.get(difficultyId);
  }

  /**
   * Apply the score the user achieved for a given song on a given difficulty.
   */
  public function setSongScore(songId:String, difficultyId:String, score:SaveScoreData):Void
  {
    var song = this.scores.songs.get(songId);
    if (song == null)
    {
      song = [];
      this.scores.songs.set(songId, song);
    }
    song.set(difficultyId, score);

    flush();
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
    var song = this.scores.songs.get(songId);
    if (song == null)
    {
      song = [];
      this.scores.songs.set(songId, song);
    }

    var currentScore = song.get(difficultyId);
    if (currentScore == null)
    {
      return true;
    }

    return score.score > currentScore.score;
  }

  /**
   * Has the provided song been beaten on one of the listed difficulties?
   * @param songId The song ID to check.
   * @param difficultyList The difficulties to check. Defaults to `easy`, `normal`, and `hard`.
   * @return Whether the song has been beaten on any of the listed difficulties.
   */
  public function hasBeatenSong(songId:String, ?difficultyList:Array<String>):Bool
  {
    if (difficultyList == null)
    {
      difficultyList = ['easy', 'normal', 'hard'];
    }
    for (difficulty in difficultyList)
    {
      var score:Null<SaveScoreData> = getSongScore(songId, difficulty);
      // TODO: Do we need to check accuracy/score here?
      if (score != null)
      {
        return true;
      }
    }
    return false;
  }

  public function getControls(playerId:Int, inputType:Device):SaveControlsData
  {
    switch (inputType)
    {
      case Keys:
        return (playerId == 0) ? this.options.controls.p1.keyboard : this.options.controls.p2.keyboard;
      case Gamepad(_):
        return (playerId == 0) ? this.options.controls.p1.gamepad : this.options.controls.p2.gamepad;
    }
  }

  public function hasControls(playerId:Int, inputType:Device):Bool
  {
    var controls = getControls(playerId, inputType);
    var controlsFields = Reflect.fields(controls);
    return controlsFields.length > 0;
  }

  public function setControls(playerId:Int, inputType:Device, controls:SaveControlsData):Void
  {
    switch (inputType)
    {
      case Keys:
        if (playerId == 0)
        {
          this.options.controls.p1.keyboard = controls;
        }
        else
        {
          this.options.controls.p2.keyboard = controls;
        }
      case Gamepad(_):
        if (playerId == 0)
        {
          this.options.controls.p1.gamepad = controls;
        }
        else
        {
          this.options.controls.p2.gamepad = controls;
        }
    }

    flush();
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
   * Call this to make sure the save data is written to disk.
   */
  public function flush():Void
  {
    FlxG.save.flush();
  }

  /**
   * If you set slot to `2`, it will load an independe
   * @param slot
   */
  static function loadFromSlot(slot:Int):Void
  {
    trace("[SAVE] Loading save from slot " + slot + "...");

    FlxG.save.bind('$SAVE_NAME${slot}', SAVE_PATH);

    if (FlxG.save.isEmpty())
    {
      trace('[SAVE] Save data is empty, checking for legacy save data...');
      var legacySaveData = fetchLegacySaveData();
      if (legacySaveData != null)
      {
        trace('[SAVE] Found legacy save data, converting...');
        FlxG.save.mergeData(SaveDataMigrator.migrateFromLegacy(legacySaveData));
      }
    }
    else
    {
      trace('[SAVE] Loaded save data.');
      FlxG.save.mergeData(SaveDataMigrator.migrate(FlxG.save.data));
    }

    trace('[SAVE] Done loading save data.');
    trace(FlxG.save.data);
  }

  static function fetchLegacySaveData():Null<RawSaveData_v1_0_0>
  {
    trace("[SAVE] Checking for legacy save data...");
    var legacySave:FlxSave = new FlxSave();
    legacySave.bind(SAVE_NAME_LEGACY, SAVE_PATH_LEGACY);
    if (legacySave?.data == null)
    {
      trace("[SAVE] No legacy save data found.");
      return null;
    }
    else
    {
      trace("[SAVE] Legacy save data found.");
      trace(legacySave.data);
      return cast legacySave.data;
    }
  }
}

/**
 * An anonymous structure containingg all the user's save data.
 */
typedef RawSaveData =
{
  // Flixel save data.
  var volume:Float;
  var mute:Bool;

  /**
   * A semantic versioning string for the save data format.
   */
  @:jcustomparse(funkin.data.DataParse.semverVersion)
  @:jcustomwrite(funkin.data.DataWrite.semverVersion)
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

  var mods:SaveDataMods;

  /**
   * The user's preferences specific to the Chart Editor.
   */
  var optionsChartEditor:SaveDataChartEditorOptions;
};

typedef SaveApiData =
{
  var newgrounds:SaveApiNewgroundsData;
}

typedef SaveApiNewgroundsData =
{
  var sessionId:Null<String>;
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

  /**
   * The accuracy percentage.
   */
  var accuracy:Float;
}

typedef SaveScoreTallyData =
{
  var killer:Int;
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
   * Whether some particularly fowl language is displayed.
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
   * @default `false`
   */
  var debugDisplay:Bool;

  /**
   * If enabled, the game will automatically pause when tabbing out.
   * @default `true`
   */
  var autoPause:Bool;

  var controls:
    {
      var p1:
        {
          var keyboard:SaveControlsData;
          var gamepad:SaveControlsData;
        };
      var p2:
        {
          var keyboard:SaveControlsData;
          var gamepad:SaveControlsData;
        };
    };
};

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
   * Keybind for skipping a cutscene.
   * @default `Escape`
   */
  var ?CUTSCENE_SKIP:Array<Int>;

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
   * Metronome sounds in the Chart Editor.
   * @default `true`
   */
  var ?metronomeEnabled:Bool;

  /**
   * If true, playtest songs from the current position in the Chart Editor.
   * @default `false`
   */
  var ?playtestStartTime:Bool;

  /**
   * Player note hit sounds in the Chart Editor.
   * @default `true`
   */
  var ?hitsoundsEnabledPlayer:Bool;

  /**
   * Opponent note hit sounds in the Chart Editor.
   * @default `true`
   */
  var ?hitsoundsEnabledOpponent:Bool;

  /**
   * Instrumental volume in the Chart Editor.
   * @default `1.0`
   */
  var ?instVolume:Float;

  /**
   * Voices volume in the Chart Editor.
   * @default `1.0`
   */
  var ?voicesVolume:Float;

  /**
   * Playback speed in the Chart Editor.
   * @default `1.0`
   */
  var ?playbackSpeed:Float;
};
