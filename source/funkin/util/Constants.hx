package funkin.util;

import flixel.util.FlxColor;
import lime.app.Application;
import funkin.data.song.SongData.SongTimeFormat;

/**
 * A store of unchanging, globally relevant values.
 */
class Constants
{
  /**
   * ENGINE AND VERSION DATA
   */
  // ==============================

  /**
   * The title of the game, for debug printing purposes.
   * Change this if you're making an engine.
   */
  public static final TITLE:String = "Friday Night Funkin'";

  /**
   * The current version number of the game.
   * Modify this in the `project.xml` file.
   */
  public static var VERSION(get, never):String;

  /**
   * The generatedBy string embedded in the chart files made by this application.
   */
  public static var GENERATED_BY(get, never):String;

  static function get_GENERATED_BY():String
  {
    return '${Constants.TITLE} - ${Constants.VERSION}';
  }

  /**
   * A suffix to add to the game version.
   * Add a suffix to prototype builds and remove it for releases.
   */
  public static final VERSION_SUFFIX:String = ' PROTOTYPE';

  #if (debug || FORCE_DEBUG_VERSION)
  static function get_VERSION():String
  {
    return 'v${Application.current.meta.get('version')} (${GIT_BRANCH} : ${GIT_HASH})' + VERSION_SUFFIX;
  }
  #else
  static function get_VERSION():String
  {
    return 'v${Application.current.meta.get('version')}' + VERSION_SUFFIX;
  }
  #end

  /**
   * URL DATA
   */
  // ==============================

  /**
   * Link to download the game on Itch.io.
   */
  public static final URL_ITCH:String = 'https://ninja-muffin24.itch.io/funkin/purchase';

  /**
   * Link to the game's page on Kickstarter.
   */
  public static final URL_KICKSTARTER:String = 'https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game/';

  /**
   * GIT REPO DATA
   */
  // ==============================

  #if (debug || FORCE_DEBUG_VERSION)
  /**
   * The current Git branch.
   */
  public static final GIT_BRANCH:String = funkin.util.macro.GitCommit.getGitBranch();

  /**
   * The current Git commit hash.
   */
  public static final GIT_HASH:String = funkin.util.macro.GitCommit.getGitCommitHash();
  #end

  /**
   * COLORS
   */
  // ==============================

  /**
   * The color used by the enemy health bar.
   */
  public static final COLOR_HEALTH_BAR_RED:FlxColor = 0xFFFF0000;

  /**
   * The color used by the player health bar.
   */
  public static final COLOR_HEALTH_BAR_GREEN:FlxColor = 0xFF66FF33;

  /**
   * The base colors used by notes.
   */
  public static var COLOR_NOTES:Array<FlxColor> = [
    0xFFFF22AA, // left (0)
    0xFF00EEFF, // down (1)
    0xFF00CC00, // up (2)
    0xFFCC1111 // right (3)
  ];

  /**
   * GAME DEFAULTS
   */
  // ==============================

  /**
   * Default difficulty for charts.
   */
  public static final DEFAULT_DIFFICULTY:String = 'normal';

  /**
   * Default list of difficulties for charts.
   */
  public static final DEFAULT_DIFFICULTY_LIST:Array<String> = ['easy', 'normal', 'hard'];

  /**
   * Default player character for charts.
   */
  public static final DEFAULT_CHARACTER:String = 'bf';

  /**
   * Default player character for health icons.
   */
  public static final DEFAULT_HEALTH_ICON:String = 'face';

  /**
   * Default stage for charts.
   */
  public static final DEFAULT_STAGE:String = 'mainStage';

  /**
   * Default song for if the PlayState messes up.
   */
  public static final DEFAULT_SONG:String = 'tutorial';

  /**
   * Default variation for charts.
   */
  public static final DEFAULT_VARIATION:String = 'default';

  /**
   * The default intensity for camera zooms.
   */
  public static final DEFAULT_ZOOM_INTENSITY:Float = 0.015;

  /**
   * The default rate for camera zooms (in beats per zoom).
   */
  public static final DEFAULT_ZOOM_RATE:Int = 4;

  /**
   * The default BPM for charts, so things don't break if none is specified.
   */
  public static final DEFAULT_BPM:Float = 100.0;

  /**
   * The default name for songs.
   */
  public static final DEFAULT_SONGNAME:String = "Unknown";

  /**
   * The default artist for songs.
   */
  public static final DEFAULT_ARTIST:String = "Unknown";

  /**
   * The default note style for songs.
   */
  public static final DEFAULT_NOTE_STYLE:String = "funkin";

  /**
   * The default timing format for songs.
   */
  public static final DEFAULT_TIMEFORMAT:SongTimeFormat = SongTimeFormat.MILLISECONDS;

  /**
   * The default scroll speed for songs.
   */
  public static final DEFAULT_SCROLLSPEED:Float = 1.0;

  /**
   * Default numerator for the time signature.
   */
  public static final DEFAULT_TIME_SIGNATURE_NUM:Int = 4;

  /**
   * Default denominator for the time signature.
   */
  public static final DEFAULT_TIME_SIGNATURE_DEN:Int = 4;

  /**
   * TIMING
   */
  // ==============================

  /**
   * A magic number used when calculating scroll speed and note distances.
   */
  public static final PIXELS_PER_MS:Float = 0.45;

  /**
   * The maximum interval within which a note can be hit, in milliseconds.
   */
  public static final HIT_WINDOW_MS:Float = 160.0;

  /**
   * Constant for the number of seconds in a minute.
   */
  public static final SECS_PER_MIN:Int = 60;

  /**
   * Constant for the number of milliseconds in a second.
   */
  public static final MS_PER_SEC:Int = 1000;

  /**
   * The number of microseconds in a millisecond.
   */
  public static final US_PER_MS:Int = 1000;

  /**
   * The number of microseconds in a second.
   */
  public static final US_PER_SEC:Int = US_PER_MS * MS_PER_SEC;

  /**
   * The number of nanoseconds in a microsecond.
   */
  public static final NS_PER_US:Int = 1000;

  /**
   * The number of nanoseconds in a millisecond.
   */
  public static final NS_PER_MS:Int = NS_PER_US * US_PER_MS;

  /**
   * The number of nanoseconds in a second.
   */
  public static final NS_PER_SEC:Int = NS_PER_US * US_PER_MS * MS_PER_SEC;

  /**
   * Number of steps in a beat.
   * One step is one 16th note and one beat is one quarter note.
   */
  public static final STEPS_PER_BEAT:Int = 4;

  /**
   * All MP3 decoders introduce a playback delay of `528` samples,
   * which at 44,100 Hz (samples per second) is ~12 ms.
   */
  public static final MP3_DELAY_MS:Float = 528 / 44100 * Constants.MS_PER_SEC;

  /**
   * HEALTH VALUES
   */
  // ==============================

  /**
   * The player's maximum health.
   * If the player is at this value, they can't gain any more health.
   */
  public static final HEALTH_MAX:Float = 2.0;

  /**
   * The player's starting health.
   */
  public static final HEALTH_STARTING = HEALTH_MAX / 2.0;

  /**
   * The player's minimum health.
   * If the player is at or below this value, they lose.
   */
  public static final HEALTH_MIN:Float = 0.0;

  /**
   * The amount of health the player gains when hitting a note with the KILLER rating.
   */
  public static final HEALTH_KILLER_BONUS:Float = 2.0 / 100.0 * HEALTH_MAX; // +2.0%

  /**
   * The amount of health the player gains when hitting a note with the SICK rating.
   */
  public static final HEALTH_SICK_BONUS:Float = 1.5 / 100.0 * HEALTH_MAX; // +1.0%

  /**
   * The amount of health the player gains when hitting a note with the GOOD rating.
   */
  public static final HEALTH_GOOD_BONUS:Float = 0.75 / 100.0 * HEALTH_MAX; // +0.75%

  /**
   * The amount of health the player gains when hitting a note with the BAD rating.
   */
  public static final HEALTH_BAD_BONUS:Float = 0.0 / 100.0 * HEALTH_MAX; // +0.0%

  /**
   * The amount of health the player gains when hitting a note with the SHIT rating.
   * If negative, the player will actually lose health.
   */
  public static final HEALTH_SHIT_BONUS:Float = -1.0 / 100.0 * HEALTH_MAX; // -1.0%

  /**
   * The amount of health the player gains, while holding a hold note, per second.
   */
  public static final HEALTH_HOLD_BONUS_PER_SECOND:Float = 7.5 / 100.0 * HEALTH_MAX; // +7.5% / second

  /**
   * The amount of health the player loses upon missing a note.
   */
  public static final HEALTH_MISS_PENALTY:Float = 4.0 / 100.0 * HEALTH_MAX; // 4.0%

  /**
   * The amount of health the player loses upon pressing a key when no note is there.
   */
  public static final HEALTH_GHOST_MISS_PENALTY:Float = 2.0 / 100.0 * HEALTH_MAX; // 2.0%

  /**
   * The amount of health the player loses upon letting go of a hold note while it is still going.
   */
  public static final HEALTH_HOLD_DROP_PENALTY:Float = 0.0; // 0.0%

  /**
   * The amount of health the player loses upon hitting a mine.
   */
  public static final HEALTH_MINE_PENALTY:Float = 15.0 / 100.0 * HEALTH_MAX; // 15.0%

  /**
   * SCORE VALUES
   */
  // ==============================

  /**
   * The amount of score the player gains for every send they hold a hold note.
   * A fraction of this value is granted every frame.
   */
  public static final SCORE_HOLD_BONUS_PER_SECOND:Float = 250.0;

  /**
   * FILE EXTENSIONS
   */
  // ==============================

  /**
   * The file extension used when exporting chart files.
   *
   * - "I made a new file format"
   * - "Actually new or just a renamed ZIP?"
   */
  public static final EXT_CHART = "fnfc";

  /**
   * The file extension used when loading audio files.
   */
  public static final EXT_SOUND = #if web "mp3" #else "ogg" #end;

  /**
   * The file extension used when loading video files.
   */
  public static final EXT_VIDEO = "mp4";

  /**
   * The file extension used when loading image files.
   */
  public static final EXT_IMAGE = "png";

  /**
   * The file extension used when loading data files.
   */
  public static final EXT_DATA = "json";

  /**
   * OTHER
   */
  // ==============================

  /**
   * If true, the player will not receive the ghost miss penalty if there are no notes within the hit window.
   * This is the thing people have been begging for forever lolol.
   */
  public static final GHOST_TAPPING:Bool = false;

  /**
   * The maximum number of previous file paths for the Chart Editor to remember.
   */
  public static final MAX_PREVIOUS_WORKING_FILES:Int = 10;

  /**
   * The separator between an asset library and the asset path.
   */
  public static final LIBRARY_SEPARATOR:String = ':';

  /**
   * The scale factor to use when increasing the size of pixel art graphics.
   */
  public static final PIXEL_ART_SCALE:Float = 6;

  /**
   * The volume at which to play the countdown before the song starts.
   */
  public static final COUNTDOWN_VOLUME:Float = 0.6;

  /**
   * The horizontal offset of the strumline from the left edge of the screen.
   */
  public static final STRUMLINE_X_OFFSET:Float = 48;

  /**
   * The vertical offset of the strumline from the top edge of the screen.
   */
  public static final STRUMLINE_Y_OFFSET:Float = 24;
}
