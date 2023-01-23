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
  public static final TITLE = "Friday Night Funkin'";

  /**
   * The current version number of the game.
   * Modify this in the `project.xml` file.
   */
  public static var VERSION(get, null):String;

  /**
   * A suffix to add to the game version.
   * Add a suffix to prototype builds and remove it for releases.
   */
  public static final VERSION_SUFFIX = ' PROTOTYPE';

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
  public static final URL_ITCH:String = "https://ninja-muffin24.itch.io/funkin/purchase";

  /**
   * Link to the game's page on Kickstarter.
   */
  public static final URL_KICKSTARTER:String = "https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game/";

  /**
   * GIT REPO DATA
   */
  // ==============================

  #if debug
  /**
   * The current Git branch.
   */
  public static final GIT_BRANCH = funkin.util.macro.GitCommit.getGitBranch();

  /**
   * The current Git commit hash.
   */
  public static final GIT_HASH = funkin.util.macro.GitCommit.getGitCommitHash();
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
   * OTHER
   */
  // ==============================

  /**
   * The scale factor to use when increasing the size of pixel art graphics.
   */
  public static final PIXEL_ART_SCALE = 6;

  /**
   * The BPM of the title screen and menu music.
   * TODO: Move to metadata file.
   */
  public static final FREAKY_MENU_BPM = 102;

  /**
   * The volume at which to play the countdown before the song starts.
   */
  public static final COUNTDOWN_VOLUME = 0.6;

  public static final DEFAULT_VARIATION = 'default';
  public static final DEFAULT_DIFFICULTY = 'normal';
}
