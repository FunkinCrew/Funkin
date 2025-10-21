package tools;

/**
 * Enum abstract representing ANSI codes for text colors, background colors, and text styles.
 */
// TODO: Add more colors maybe?

enum abstract AnsiCode(String) from String to String
{
  var RESET = '\x1b[0m';
  var BOLD = '\x1b[1m';
  var DIM = '\x1b[2m';
  var UNDERLINE = '\x1b[4m';
  var BLINK = '\x1b[5m';
  var INVERSE = '\x1b[7m';
  var HIDDEN = '\x1b[8m';
  var STRIKETHROUGH = '\x1b[9m';

  var BLACK = '\x1b[30m';
  var RED = '\x1b[31m';
  var GREEN = '\x1b[32m';
  var YELLOW = '\x1b[33m';
  var BLUE = '\x1b[34m';
  var MAGENTA = '\x1b[35m';
  var CYAN = '\x1b[36m';
  var WHITE = '\x1b[37m';

  var BG_BLACK = '\x1b[40m';
  var BG_RED = '\x1b[41m';
  var BG_GREEN = '\x1b[42m';
  var BG_YELLOW = '\x1b[43m';
  var BG_BLUE = '\x1b[44m';
  var BG_MAGENTA = '\x1b[45m';
  var BG_CYAN = '\x1b[46m';
  var BG_WHITE = '\x1b[47m';
  var BG_ORANGE = '\x1b[48;5;208m';

  var BRIGHT_BLACK = '\x1b[90m';
  var BRIGHT_RED = '\x1b[91m';
  var BRIGHT_GREEN = '\x1b[92m';
  var BRIGHT_YELLOW = '\x1b[93m';
  var BRIGHT_BLUE = '\x1b[94m';
  var BRIGHT_MAGENTA = '\x1b[95m';
  var BRIGHT_CYAN = '\x1b[96m';
  var BRIGHT_WHITE = '\x1b[97m';

  var BG_BRIGHT_BLACK = '\x1b[100m';
  var BG_BRIGHT_RED = '\x1b[101m';
  var BG_BRIGHT_GREEN = '\x1b[102m';
  var BG_BRIGHT_YELLOW = '\x1b[103m';
  var BG_BRIGHT_BLUE = '\x1b[104m';
  var BG_BRIGHT_MAGENTA = '\x1b[105m';
  var BG_BRIGHT_CYAN = '\x1b[106m';
  var BG_BRIGHT_WHITE = '\x1b[107m';
}

/**
 * This class provides functionality for applying ANSI codes to strings for terminal output.
 */
@:nullSafety
class AnsiUtil
{
  #if sys
  @:noCompletion
  static final REGEX_TEAMCITY_VERSION:EReg = ~/^9\.(0*[1-9]\d*)\.|\d{2,}\./;

  @:noCompletion
  static final REGEX_TERM_256:EReg = ~/(?i)-256(color)?$/;

  @:noCompletion
  static final REGEX_TERM_TYPES:EReg = ~/(?i)^screen|^xterm|^vt100|^vt220|^rxvt|color|ansi|cygwin|linux/;
  #end

  @:noCompletion
  static final REGEX_ANSI_CODES:EReg = ~/\x1b\[[0-9;]*m/g;

  @:noCompletion
  static var codesSupported:Null<Bool> = null;

  /**
   * Safe wrapper for Sys.getEnv (returns null on non-sys targets).
   */
  static function getEnvSafe(name:String):Null<String>
  {
    #if sys
    return Sys.getEnv(name);
    #else
    return null;
    #end
  }

  // Text styles

  /** Makes the string bold. */
  public static inline function bold(str:String):String
    return apply(str, AnsiCode.BOLD);

  /** Makes the string dim/faint. */
  public static inline function dim(str:String):String
    return apply(str, AnsiCode.DIM);

  /** Underlines the string. */
  public static inline function underline(str:String):String
    return apply(str, AnsiCode.UNDERLINE);

  /** Makes the string blink. (Not widely supported on modern terminals.) */
  public static inline function blink(str:String):String
    return apply(str, AnsiCode.BLINK);

  /** Inverts the foreground and background colors of the string. */
  public static inline function inverse(str:String):String
    return apply(str, AnsiCode.INVERSE);

  /** Hides the string (renders it invisible in many terminals). */
  public static inline function hidden(str:String):String
    return apply(str, AnsiCode.HIDDEN);

  /** Applies a strikethrough effect to the string. */
  public static inline function strikethrough(str:String):String
    return apply(str, AnsiCode.STRIKETHROUGH);

  // Foreground colors

  /** Colors the string black. */
  public static inline function black(str:String):String
    return apply(str, AnsiCode.BLACK);

  /** Colors the string red. */
  public static inline function red(str:String):String
    return apply(str, AnsiCode.RED);

  /** Colors the string green. */
  public static inline function green(str:String):String
    return apply(str, AnsiCode.GREEN);

  /** Colors the string yellow. */
  public static inline function yellow(str:String):String
    return apply(str, AnsiCode.YELLOW);

  /** Colors the string blue. */
  public static inline function blue(str:String):String
    return apply(str, AnsiCode.BLUE);

  /** Colors the string magenta. */
  public static inline function magenta(str:String):String
    return apply(str, AnsiCode.MAGENTA);

  /** Colors the string cyan. */
  public static inline function cyan(str:String):String
    return apply(str, AnsiCode.CYAN);

  /** Colors the string white. */
  public static inline function white(str:String):String
    return apply(str, AnsiCode.WHITE);

  // Background colors

  /** Sets the background color to black. */
  public static inline function bg_black(str:String):String
    return apply(str, AnsiCode.BG_BLACK);

  /** Sets the background color to red. */
  public static inline function bg_red(str:String):String
    return apply(str, AnsiCode.BG_RED);

  /** Sets the background color to green. */
  public static inline function bg_green(str:String):String
    return apply(str, AnsiCode.BG_GREEN);

  /** Sets the background color to yellow. */
  public static inline function bg_yellow(str:String):String
    return apply(str, AnsiCode.BG_YELLOW);

  /** Sets the background color to blue. */
  public static inline function bg_blue(str:String):String
    return apply(str, AnsiCode.BG_BLUE);

  /** Sets the background color to magenta. */
  public static inline function bg_magenta(str:String):String
    return apply(str, AnsiCode.BG_MAGENTA);

  /** Sets the background color to cyan. */
  public static inline function bg_cyan(str:String):String
    return apply(str, AnsiCode.BG_CYAN);

  /** Sets the background color to white. */
  public static inline function bg_white(str:String):String
    return apply(str, AnsiCode.BG_WHITE);

  /** Sets the background color to orange (256-color mode). */
  public static inline function bg_orange(str:String):String
    return apply(str, AnsiCode.BG_ORANGE);

  // Bright foreground colors

  /** Colors the string bright black (gray). */
  public static inline function bright_black(str:String):String
    return apply(str, AnsiCode.BRIGHT_BLACK);

  /** Colors the string bright red. */
  public static inline function bright_red(str:String):String
    return apply(str, AnsiCode.BRIGHT_RED);

  /** Colors the string bright green. */
  public static inline function bright_green(str:String):String
    return apply(str, AnsiCode.BRIGHT_GREEN);

  /** Colors the string bright yellow. */
  public static inline function bright_yellow(str:String):String
    return apply(str, AnsiCode.BRIGHT_YELLOW);

  /** Colors the string bright blue. */
  public static inline function bright_blue(str:String):String
    return apply(str, AnsiCode.BRIGHT_BLUE);

  /** Colors the string bright magenta. */
  public static inline function bright_magenta(str:String):String
    return apply(str, AnsiCode.BRIGHT_MAGENTA);

  /** Colors the string bright cyan. */
  public static inline function bright_cyan(str:String):String
    return apply(str, AnsiCode.BRIGHT_CYAN);

  /** Colors the string bright white. */
  public static inline function bright_white(str:String):String
    return apply(str, AnsiCode.BRIGHT_WHITE);

  // Bright backgrounds

  /** Sets the background color to bright black (gray). */
  public static inline function bg_bright_black(str:String):String
    return apply(str, AnsiCode.BG_BRIGHT_BLACK);

  /** Sets the background color to bright red. */
  public static inline function bg_bright_red(str:String):String
    return apply(str, AnsiCode.BG_BRIGHT_RED);

  /** Sets the background color to bright green. */
  public static inline function bg_bright_green(str:String):String
    return apply(str, AnsiCode.BG_BRIGHT_GREEN);

  /** Sets the background color to bright yellow. */
  public static inline function bg_bright_yellow(str:String):String
    return apply(str, AnsiCode.BG_BRIGHT_YELLOW);

  /** Sets the background color to bright blue. */
  public static inline function bg_bright_blue(str:String):String
    return apply(str, AnsiCode.BG_BRIGHT_BLUE);

  /** Sets the background color to bright magenta. */
  public static inline function bg_bright_magenta(str:String):String
    return apply(str, AnsiCode.BG_BRIGHT_MAGENTA);

  /** Sets the background color to bright cyan. */
  public static inline function bg_bright_cyan(str:String):String
    return apply(str, AnsiCode.BG_BRIGHT_CYAN);

  /** Sets the background color to bright white. */
  public static inline function bg_bright_white(str:String):String
    return apply(str, AnsiCode.BG_BRIGHT_WHITE);

  /**
   * Applies the specified ANSI codes to the input string.
   *
   * You can pass one or multiple ANSI codes for combining styles.
   *
   * @param str The input string.
   * @param code The ANSI codes to apply.
   *
   * @return The styled string.
   */
  public static function apply(str:String, code:AnsiCode):String
  {
    if (str.indexOf(AnsiCode.RESET) != -1) str = StringTools.replace(str, AnsiCode.RESET, "");
    return stripCodes(code + str + AnsiCode.RESET);
  }

  /**
   * Whether ANSI codes are supported or not.
   *
   * @return `true` if ANSI codes are supported, `false` otherwise.
   */
  public static function isColorCodesSupported():Bool
  {
    if (codesSupported == null)
    {
      #if sys
      if (codesSupported == null)
      {
        final term:Null<String> = getEnvSafe('TERM');

        if (term == 'dumb') codesSupported = false;
        else
        {
          if (codesSupported != true && term != null)
          {
            codesSupported = REGEX_TERM_256.match(term) || REGEX_TERM_TYPES.match(term);
          }

          if (getEnvSafe('CI') != null)
          {
            final ciEnvNames:Array<String> = [
              "GITHUB_ACTIONS", "GITEA_ACTIONS",    "TRAVIS", "CIRCLECI",
                    "APPVEYOR",     "GITLAB_CI", "BUILDKITE",    "DRONE"
            ];

            for (ci in ciEnvNames)
            {
              if (getEnvSafe(ci) != null)
              {
                codesSupported = true;
                break;
              }
            }

            if (codesSupported != true && getEnvSafe("CI_NAME") == "codeship")
            {
              codesSupported = true;
            }
          }

          final teamCity:Null<String> = getEnvSafe("TEAMCITY_VERSION");

          if (codesSupported != true && teamCity != null)
          {
            codesSupported = REGEX_TEAMCITY_VERSION.match(teamCity);
          }

          if (codesSupported != true)
          {
            codesSupported = getEnvSafe('TERM_PROGRAM') == 'iTerm.app'
              || getEnvSafe('TERM_PROGRAM') == 'Apple_Terminal'
              || getEnvSafe('COLORTERM') != null
              || getEnvSafe('ANSICON') != null
              || getEnvSafe('ConEmuANSI') != null
              || getEnvSafe('WT_SESSION') != null;
          }
        }
      }
      #else
      codesSupported = false;
      #end
    }

    return codesSupported == true;
  }

  @:noCompletion
  static function stripCodes(output:String):String
  {
    return isColorCodesSupported() ? output : REGEX_ANSI_CODES.replace(output, '');
  }
}
