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
   * Default variation for charts.
   */
  public static final DEFAULT_VARIATION:String = 'default';

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
   * OTHER
   */
  // ==============================

  /**
   * All MP3 decoders introduce a playback delay of `528` samples,
   * which at 44,100 Hz (samples per second) is ~12 ms.
   */
  public static final MP3_DELAY_MS:Float = 528 / 44100 * 1000;

  /**
   * The scale factor to use when increasing the size of pixel art graphics.
   */
  public static final PIXEL_ART_SCALE:Float = 6;

  /**
   * The BPM of the title screen and menu music.
   * TODO: Move to metadata file.
   */
  public static final FREAKY_MENU_BPM:Float = 102;

  /**
   * The volume at which to play the countdown before the song starts.
   */
  public static final COUNTDOWN_VOLUME:Float = 0.6;

  /**
   * The default intensity for camera zooms.
   */
  public static final DEFAULT_ZOOM_INTENSITY:Float = 0.015;

  /**
   * The default rate for camera zooms (in beats per zoom).
   */
  public static final DEFAULT_ZOOM_RATE:Int = 4;
}
