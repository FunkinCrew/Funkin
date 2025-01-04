package funkin;

/**
 * Class `Texts` handles all the texts in the menus and during gameplay that would normally be hardcoded.
 */
class Texts
{
  inline static final VALUE_REPLACER:String = "$value";

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

  var _data:TextData;

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

  public function getFreeplayTitle()
  {
    return _data?.freeplay?.title ?? "FREEPLAY";
  }

  public function getFreeplayOSTText()
  {
    return _data?.freeplay?.ostText ?? "OFFICIAL OST";
  }

  public function getFreeplayCharSelectHint(control:String = "")
  {
    var text:String = _data?.freeplay?.charSelectHint ?? "Press [ $value ] to change characters";
    return text.replace(VALUE_REPLACER, control);
  }

  public function getOptionsPreferencesTabName()
  {
    return _data?.options?.preferences?.tabName ?? "PREFERENCES";
  }

  public function getOptionsPreferencesNaughtyness()
  {
    return _data?.options?.preferences?.naughtyness ?? "Naughtyness";
  }

  public function getOptionsPreferencesDownscroll()
  {
    return _data?.options?.preferences?.downscroll ?? "Downscroll";
  }

  public function getOptionsPreferencesFlashing()
  {
    return _data?.options?.preferences?.flashing ?? "Flashing Lights";
  }

  public function getOptionsPreferencesCamZoom()
  {
    return _data?.options?.preferences?.camZoom ?? "Camera Zooming on Beat";
  }

  public function getOptionsPreferencesDebug()
  {
    return _data?.options?.preferences?.debug ?? "Debug Display";
  }

  public function getOptionsPreferencesAutoPause()
  {
    return _data?.options?.preferences?.autoPause ?? "Auto Pause";
  }

  public function getOptionsPreferencesUnlockedFramerate()
  {
    return _data?.options?.preferences?.unlockedFramerate ?? "Unlocked Framerate";
  }

  public function getOptionsPreferencesFPS()
  {
    return _data?.options?.preferences?.fps ?? "FPS";
  }

  public function getOptionsControlsTabName()
  {
    return _data?.options?.controls?.tabName ?? "CONTROLS";
  }

  public function getOptionsInputOffsetsTabName()
  {
    return _data?.options?.inputOffsets?.tabName ?? "INPUT OFFSETS";
  }

  public function getOptionsExit()
  {
    return _data?.options?.exit ?? "EXIT";
  }
}

typedef TextData =
{
  @:optional
  var title:TitleData;

  @:optional
  var freeplay:FreeplayData;

  @:optional
  var options:OptionsData;
}

typedef TitleData =
{
  @:optional
  var texts:Array<TitleTextData>;

  @:optional
  @:default("--")
  var randomTextSplitter:String;
}

typedef TitleTextData =
{
  var beat:Int;
  var command:TitleTextCommand;

  @:optional
  @:default([])
  var texts:Array<String>;

  @:optional
  @:default(-1)
  var randomText:Int;
}

typedef FreeplayData =
{
  @:optional
  var title:String;

  @:optional
  var ostText:String;

  @:optional
  var charSelectHint:String;
}

typedef OptionsData =
{
  @:optional
  var preferences:OptionsPreferencesData;

  @:optional
  var controls:OptionsControlsData;

  @:optional
  var inputOffsets:OptionsInputOffsetsData;

  @:optional
  var exit:String;
}

typedef OptionsPreferencesData =
{
  @:optional
  var tabName:String;

  @:optional
  var naughtyness:String;

  @:optional
  var downscroll:String;

  @:optional
  var flashing:String;

  @:optional
  var camZoom:String;

  @:optional
  var debug:String;

  @:optional
  var autoPause:String;

  @:optional
  var unlockedFramerate:String;

  @:optional
  var fps:String;
}

typedef OptionsControlsData =
{
  var tabName:String;
}

typedef OptionsInputOffsetsData =
{
  var tabName:String;
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
