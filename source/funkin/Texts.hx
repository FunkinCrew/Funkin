package funkin;

/**
 * Class `Texts` handles all the texts in the menus and during gameplay that would normally be hardcoded.
 */
class Texts
{
  inline static final VALUE_REPLACER:String = "${value}";

  public static var instance(get, never):Texts;
  static var _instance:Null<Texts> = null;

  static function get_instance():Texts
  {
    if (_instance == null) _instance = new Texts();
    return _instance;
  }

  public static function reloadTexts()
  {
    _instance = new Texts();
  }

  var _data:Dynamic;

  function new()
  {
    if (!Assets.exists(Paths.json("texts")))
    {
      throw "Error: No file \"texts.json\" can be found!";
    }

    _data = haxe.Json.parse(Assets.getText(Paths.json("texts")));
  }

  public function getTitleTexts()
  {
    return _data?.title?.texts ?? [];
  }

  public function getTitleSplitter()
  {
    return _data?.title?.randomTextSplitter ?? "--";
  }

  public function getText(group:String, ?replacerValues:Array<Dynamic>)
  {
    var groups:Array<String> = group.split("/");
    var output:Dynamic = null;

    for (field in groups)
    {
      var useThing = output ?? _data;
      if (Reflect.hasField(useThing, field))
      {
        output = Reflect.field(useThing, field);
      }
      else
      {
        return null;
      }
    }

    if (Std.isOfType(output, String))
    {
      var strOutput:String = cast output;
      if (replacerValues != null)
      {
        // first we check if the text has a macro "${value}", which we set to the 1st (0th technically teehee) member of the replacerValues
        // if not then we go ${value1} ${value2} etc... to replace with corresponding replacerValues!!
        // this is primarily cuz of the results screen requiring 2 replacer values, song title and song composers goddamnit

        var newValueReplacer:Int->String = function(num:Int = 1) return VALUE_REPLACER.replace("}", num + "}");

        if (!strOutput.contains(newValueReplacer(1)))
        {
          strOutput = strOutput.replace(VALUE_REPLACER, Std.string(replacerValues[0]));
        }
        else
        {
          for (i in 0...replacerValues.length)
          {
            strOutput = strOutput.replace(newValueReplacer(i + 1), Std.string(replacerValues[i]));
          }
        }
      }

      return strOutput;
    }

    return null;
  }
}

enum abstract TitleTextCommand(String) from String to String
{
  var SHOW_TEXT:String = "show-text";
  var APPEND_TEXT:String = "append-text";
  var CLEAR_TEXT:String = "clear-text";
  var SHOW_LOGO:String = "show-logo";
  var HIDE_LOGO:String = "hide-logo";
  var FINISH_INTRO:String = "finish-intro";
}
