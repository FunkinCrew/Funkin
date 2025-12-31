package funkin.ui.credits;

#if macro
import haxe.macro.Context;
#end

using funkin.util.AnsiUtil;

@:access(funkin.ui.credits.CreditsDataHandler)
class CreditsDataMacro
{
  public static macro function loadCreditsData():haxe.macro.Expr.ExprOf<CreditsData>
  {
    #if !display
    Sys.println(' INFO '.bold().bg_blue() + ' Hardcoding credits data...');
    var json = CreditsDataMacro.fetchJSON();

    if (json == null)
    {
      Context.info(' WARNING '.bold().bg_yellow() + ' Could not fetch JSON data for credits.', Context.currentPos());
      return macro $v{CreditsDataHandler.getFallback()};
    }

    var creditsData = CreditsDataMacro.parseJSON(json);

    if (creditsData == null)
    {
      Context.info(' WARNING '.bold().bg_yellow() + ' Could not parse JSON data for credits.', Context.currentPos());
      return macro $v{CreditsDataHandler.getFallback()};
    }

    CreditsDataHandler.debugPrint(creditsData);
    return macro $v{creditsData};
    // return macro $v{null};
    #else
    // `#if display` is used for code completion. In this case we return
    // a minimal value to keep code completion fast.
    return macro $v{CreditsDataHandler.getFallback()};
    #end
  }

  #if macro
  static function fetchJSON():Null<String>
  {
    var creditsPath:String = CreditsDataHandler.CREDITS_DATA_PATH;

    #if ios
    if (!sys.FileSystem.exists(creditsPath)) creditsPath = "../../../../../" + creditsPath;
    #end

    return sys.io.File.getContent(creditsPath);
  }

  /**
   * Parse the JSON data for the credits.
   *
   * @param json The string data to parse.
   * @return The parsed data.
   */
  static function parseJSON(json:String):Null<CreditsData>
  {
    try
    {
      // TODO: Use something with better validation but that still works at macro time.
      return haxe.Json.parse(json);
    }
    catch (e)
    {
      trace(' ERROR '.bg_red().bold() + ' Failed to parse JSON data for credits.');
      trace(e);
      return null;
    }
  }
  #end
}
