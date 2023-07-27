package funkin.util;

import flixel.util.FlxColor;
import lime.app.Application;

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
  public static var VERSION(get, null):String;

  /**
   * A suffix to add to the game version.
   * Add a suffix to prototype builds and remove it for releases.
   */
  public static final VERSION_SUFFIX:String = ' PROTOTYPE';

  #if debug
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

  #if debug
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
   * The base colors of the notes.
   */
  public static final COLOR_NOTES:Array<FlxColor> = [0xFFFF22AA, 0xFF00EEFF, 0xFF00CC00, 0xFFCC1111];

  /**
   * STAGE DEFAULTS
   */
  // ==============================

  /**
   * Default difficulty for charts.
   */
  public static final DEFAULT_DIFFICULTY:String = 'normal';

  /**
   * Default player character for charts.
   */
  public static final DEFAULT_CHARACTER:String = 'bf';

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
   * If true, the player will not receive the ghost miss penalty if there are no notes within the hit window.
   * This is the thing people have been begging for forever lolol.
   */
  public static final GHOST_TAPPING:Bool = false;

  /**
   * TIMING
   */
  // ==============================

  /**
   * The number of seconds in a minute.
   */
  public static final SECS_PER_MIN:Int = 60;

  /**
   * The number of milliseconds in a second.
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
   * All MP3 decoders introduce a playback delay of `528` samples,
   * which at 44,100 Hz (samples per second) is ~12 ms.
   */
  public static final MP3_DELAY_MS:Float = 528 / 44100 * MS_PER_SEC;

  /**
   * The default BPM of the conductor.
   */
  public static final DEFAULT_BPM:Float = 100.0;

  /**
   * The default numerator for the time signature.
   */
  public static final DEFAULT_TIME_SIGNATURE_NUM:Int = 4;

  /**
   * The default denominator for the time signature.
   */
  public static final DEFAULT_TIME_SIGNATURE_DEN:Int = 4;

  /**
   * Number of steps in a beat.
   * One step is one 16th note and one beat is one quarter note.
   */
  public static final STEPS_PER_BEAT:Int = 4;

  /**
   * OTHER
   */
  // ==============================
  public static final LIBRARY_SEPARATOR:String = ':';

  /**
   * The scale factor to use when increasing the size of pixel art graphics.
   */
  public static final PIXEL_ART_SCALE:Float = 6;

  /**
   * The volume at which to play the countdown before the song starts.
   */
  public static final COUNTDOWN_VOLUME:Float = 0.6;

  public static final STRUMLINE_X_OFFSET:Float = 48;
  public static final STRUMLINE_Y_OFFSET:Float = 24;

  /**
   * The default intensity for camera zooms.
   */
  public static final DEFAULT_ZOOM_INTENSITY:Float = 0.015;

  /**
   * The default rate for camera zooms (in beats per zoom).
   */
  public static final DEFAULT_ZOOM_RATE:Int = 4;
}
