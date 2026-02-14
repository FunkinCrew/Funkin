package tools;

/**
 * Enum abstract representing ANSI codes for text colors, background colors, and text styles.
 * TODO: Add more colors?
 */
@SuppressWarnings(["checkstyle:FieldDocComment", "checkstyle:MemberName", "checkstyle:TypeDocComment"])
enum abstract AnsiCode(String) from String to String
{
  public var RESET = '\x1b[0m';
  public var BOLD = '\x1b[1m';
  public var DIM = '\x1b[2m';
  public var UNDERLINE = '\x1b[4m';
  public var BLINK = '\x1b[5m';
  public var INVERSE = '\x1b[7m';
  public var HIDDEN = '\x1b[8m';
  public var STRIKETHROUGH = '\x1b[9m';

  // 30-37 set foreground to standard colors
  public var BLACK = '\x1b[30m';
  public var RED = '\x1b[31m';
  public var GREEN = '\x1b[32m';
  public var YELLOW = '\x1b[33m';
  public var BLUE = '\x1b[34m';
  public var MAGENTA = '\x1b[35m';
  public var CYAN = '\x1b[36m';
  public var WHITE = '\x1b[37m';

  // 38 has two modes
  // [38;2;#m uses one of 256 colors
  public var ORANGE = '\x1b[38;5;208m';

  // [38;2;RR;GG;BBm uses 24-bit color RGB
  public var NOTE_LEFT = '\x1b[38;2;255;34;170m';
  public var NOTE_DOWN = '\x1b[38;2;0;238;255m';
  public var NOTE_UP = '\x1b[38;2;0;204;0m';
  public var NOTE_RIGHT = '\x1b[38;2;204;17;17m';

  // 40-47 set background to standard colors
  public var BG_BLACK = '\x1b[40m';
  public var BG_RED = '\x1b[41m';
  public var BG_GREEN = '\x1b[42m';
  public var BG_YELLOW = '\x1b[43m';
  public var BG_BLUE = '\x1b[44m';
  public var BG_MAGENTA = '\x1b[45m';
  public var BG_CYAN = '\x1b[46m';
  public var BG_WHITE = '\x1b[47m';

  // 48 has two modes
  // [48;2;#m uses one of 256 colors
  // Color names via https://hexdocs.pm/color_palette/ansi_color_codes.html
  public var BG_SEA_GREEN = '\x1b[48;5;50m';
  public var BG_PIST = '\x1b[48;5;112m';
  public var BG_BRONZE = '\x1b[48;5;137m';
  public var BG_BRIGHT_LAVENDER = '\x1b[48;5;141m';
  public var BG_LIME = '\x1b[48;5;154m';
  public var BG_MINT_GREEN = '\x1b[48;5;156m';
  public var BG_HOPBUSH = '\x1b[48;5;169m';
  public var BG_BRIGHT_LILAC = '\x1b[48;5;177m';
  public var BG_GOLDENROD = '\x1b[48;5;178m';
  public var BG_CORN = '\x1b[48;5;184m';
  public var BG_TEA_GREEN = '\x1b[48;5;193m';
  public var BG_LIGHT_RED = '\x1b[48;5;196m';
  public var BG_STRAWBERRY = '\x1b[48;5;204m';
  public var BG_SHOCKING_PINK = '\x1b[48;5;207m';
  public var BG_ORANGE = '\x1b[48;5;208m';
  public var BG_SALMON = '\x1b[48;5;209m';
  public var BG_LIGHT_PINK = '\x1b[48;5;213m';

  // [48;2;RR;GG;BBm uses 24-bit color RGB
  public var BG_PURPLE = '\x1b[48;2;121;37;199m';
  public var BG_NOTE_LEFT = '\x1b[48;2;255;34;170m';
  public var BG_NOTE_DOWN = '\x1b[48;2;0;238;255m';
  public var BG_NOTE_UP = '\x1b[48;2;0;204;0m';
  public var BG_NOTE_RIGHT = '\x1b[48;2;204;17;17m';

  // 90-97 sets a bright foreground color (non-standard)
  public var BRIGHT_BLACK = '\x1b[90m';
  public var BRIGHT_RED = '\x1b[91m';
  public var BRIGHT_GREEN = '\x1b[92m';
  public var BRIGHT_YELLOW = '\x1b[93m';
  public var BRIGHT_BLUE = '\x1b[94m';
  public var BRIGHT_MAGENTA = '\x1b[95m';
  public var BRIGHT_CYAN = '\x1b[96m';
  public var BRIGHT_WHITE = '\x1b[97m';

  // 100-107 sets a bright background color (non-standard)
  public var BG_BRIGHT_BLACK = '\x1b[100m';
  public var BG_BRIGHT_RED = '\x1b[101m';
  public var BG_BRIGHT_GREEN = '\x1b[102m';
  public var BG_BRIGHT_YELLOW = '\x1b[103m';
  public var BG_BRIGHT_BLUE = '\x1b[104m';
  public var BG_BRIGHT_MAGENTA = '\x1b[105m';
  public var BG_BRIGHT_CYAN = '\x1b[106m';
  public var BG_BRIGHT_WHITE = '\x1b[107m';
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

  // Common combos

  /**
   * Makes the string display as ERROR text.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function error(str:String):String return AnsiUtil.bold(AnsiUtil.bg_note_right(str));

  /**
   * Makes the string display as WARNING text.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function warning(str:String):String return AnsiUtil.bold(AnsiUtil.bg_yellow(str));

  /**
   * Makes the string display as INFO text.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function info(str:String):String return AnsiUtil.bold(AnsiUtil.bg_blue(str));

  // Text styles

  /**
   * Makes the string bold.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bold(str:String):String return apply(str, AnsiCode.BOLD);

  /**
   * Makes the string dim/faint.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function dim(str:String):String return apply(str, AnsiCode.DIM);

  /**
   * Underlines the string.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function underline(str:String):String return apply(str, AnsiCode.UNDERLINE);

  /**
   * Makes the string blink. (Not widely supported on modern terminals.)
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function blink(str:String):String return apply(str, AnsiCode.BLINK);

  /**
   * Inverts the foreground and background colors of the string.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function inverse(str:String):String return apply(str, AnsiCode.INVERSE);

  /**
   * Hides the string (renders it invisible in many terminals).
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function hidden(str:String):String return apply(str, AnsiCode.HIDDEN);

  /**
   * Applies a strikethrough effect to the string.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function strikethrough(str:String):String return apply(str, AnsiCode.STRIKETHROUGH);

  // Foreground colors

  /**
   * Colors the string black.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function black(str:String):String return apply(str, AnsiCode.BLACK);

  /**
   * Colors the string red.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function red(str:String):String return apply(str, AnsiCode.RED);

  /**
   * Colors the string green.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function green(str:String):String return apply(str, AnsiCode.GREEN);

  /**
   * Colors the string yellow.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function yellow(str:String):String return apply(str, AnsiCode.YELLOW);

  /**
   * Colors the string blue.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function blue(str:String):String return apply(str, AnsiCode.BLUE);

  /**
   * Colors the string magenta.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function magenta(str:String):String return apply(str, AnsiCode.MAGENTA);

  /**
   * Colors the string cyan.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function cyan(str:String):String return apply(str, AnsiCode.CYAN);

  /**
   * Colors the string white.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function white(str:String):String return apply(str, AnsiCode.WHITE);

  // Background colors

  /**
   * Sets the background color to black.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_black(str:String):String return apply(str, AnsiCode.BG_BLACK);

  /**
   * Sets the background color to red.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_red(str:String):String return apply(str, AnsiCode.BG_RED);

  /**
   * Sets the background color to green.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_green(str:String):String return apply(str, AnsiCode.BG_GREEN);

  /**
   * Sets the background color to yellow.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_yellow(str:String):String return apply(str, AnsiCode.BG_YELLOW);

  /**
   * Sets the background color to blue.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_blue(str:String):String return apply(str, AnsiCode.BG_BLUE);

  /**
   * Sets the background color to magenta.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_magenta(str:String):String return apply(str, AnsiCode.BG_MAGENTA);

  /**
   * Sets the background color to cyan.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_cyan(str:String):String return apply(str, AnsiCode.BG_CYAN);

  /**
   * Sets the background color to white.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_white(str:String):String return apply(str, AnsiCode.BG_WHITE);

  /**
   * Sets the background color to orange (256-color mode).
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_orange(str:String):String return apply(str, AnsiCode.BG_ORANGE);

  /**
   * Sets the background color to purple (256-color mode).
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_purple(str:String):String return apply(str, AnsiCode.BG_PURPLE);

  /**
   * Sets the background color to bright lilac (256-color mode).
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_bright_lilac(str:String):String return apply(str, AnsiCode.BG_BRIGHT_LILAC);

  /**
   * Sets the background color to the color of a Left note.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_note_left(str:String):String return apply(str, AnsiCode.BG_NOTE_LEFT);

  /**
   * Sets the background color to the color of a Down note.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_note_down(str:String):String return apply(str, AnsiCode.BG_NOTE_DOWN);

  /**
   * Sets the background color to the color of a Up note.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_note_up(str:String):String return apply(str, AnsiCode.BG_NOTE_UP);

  /**
   * Sets the background color to the color of a Right note.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_note_right(str:String):String return apply(str, AnsiCode.BG_NOTE_RIGHT);

  // Bright foreground colors

  /**
   * Colors the string bright black (gray).
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bright_black(str:String):String return apply(str, AnsiCode.BRIGHT_BLACK);

  /**
   * Colors the string bright red.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bright_red(str:String):String return apply(str, AnsiCode.BRIGHT_RED);

  /**
   * Colors the string bright green.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bright_green(str:String):String return apply(str, AnsiCode.BRIGHT_GREEN);

  /**
   * Colors the string bright yellow.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bright_yellow(str:String):String return apply(str, AnsiCode.BRIGHT_YELLOW);

  /**
   * Colors the string bright blue.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bright_blue(str:String):String return apply(str, AnsiCode.BRIGHT_BLUE);

  /**
   * Colors the string bright magenta.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bright_magenta(str:String):String return apply(str, AnsiCode.BRIGHT_MAGENTA);

  /**
   * Colors the string bright cyan.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bright_cyan(str:String):String return apply(str, AnsiCode.BRIGHT_CYAN);

  /**
   * Colors the string bright white.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bright_white(str:String):String return apply(str, AnsiCode.BRIGHT_WHITE);

  // Bright backgrounds

  /**
   * Sets the background color to bright black (gray).
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_bright_black(str:String):String return apply(str, AnsiCode.BG_BRIGHT_BLACK);

  /**
   * Sets the background color to bright red.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_bright_red(str:String):String return apply(str, AnsiCode.BG_BRIGHT_RED);

  /**
   * Sets the background color to bright green.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_bright_green(str:String):String return apply(str, AnsiCode.BG_BRIGHT_GREEN);

  /**
   * Sets the background color to bright yellow.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_bright_yellow(str:String):String return apply(str, AnsiCode.BG_BRIGHT_YELLOW);

  /**
   * Sets the background color to bright blue.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_bright_blue(str:String):String return apply(str, AnsiCode.BG_BRIGHT_BLUE);

  /**
   * Sets the background color to bright magenta.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_bright_magenta(str:String):String return apply(str, AnsiCode.BG_BRIGHT_MAGENTA);

  /**
   * Sets the background color to bright cyan.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_bright_cyan(str:String):String return apply(str, AnsiCode.BG_BRIGHT_CYAN);

  /**
   * Sets the background color to bright white.
   * @param str The input string to format.
   * @return The formatted string.
   */
  public static inline function bg_bright_white(str:String):String return apply(str, AnsiCode.BG_BRIGHT_WHITE);

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
  @SuppressWarnings(["checkstyle:SimplifyBooleanExpression"])
  public static function isColorCodesSupported():Bool
  {
    if (codesSupported == null)
    {
      #if sys
      if (codesSupported == null)
      {
        final term:Null<String> = getEnvSafe('TERM');

        if (term == 'dumb')
        {
          codesSupported = false;
        }
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
