package funkin.ui.title;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatSubState;
import thx.semver.Version;
import lime.app.Application;
import funkin.ui.mainmenu.MainMenuState;
import flixel.util.typeLimit.NextState;
import haxe.Http;
import json2object.JsonParser;

class OutdatedSubState extends MusicBeatSubState
{
  /**
   * The itch.io Game to use for checking updates.
   */
  public static final ITCH_TARGET:String = "ninja-muffin24/funkin";

  /**
   * The newest version.
   */
  public static var updateVersion:Version;

  /**
   * Is there a new version available?
   */
  public static var isNewVersion:Bool;

  /**
   * If the user has seen this state already.
   */
  public static var leftState:Bool = false;

  /**
   * State to go to when this is finished.
   */
  public var targetState:NextState;

  override public function create():Void
  {
    FlxG.state.persistentDraw = false;
    FlxG.state.persistentUpdate = false;

    if (!isNewVersion || leftState)
    {
      close();
      return;
    }

    var txt:FlxText = new FlxText(0, 0, FlxG.width
      - 50,
      "HEY! You're running an outdated version of the game!\nCurrent version is "
      + "v"
      + Application.current.meta.get('version')
      + ", while the most recent version is "
      + "v"
      + updateVersion
      + "!\nPress "
      + controls.getDialogueNameFromControl(ACCEPT, true)
      + " to go to itch.io, or "
      + controls.getDialogueNameFromControl(BACK, true)
      + " to ignore this!!",
      32);
    txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
    txt.screenCenter();
    add(txt);
    super.create();
  }

  override function update(elapsed:Float):Void
  {
    if (controls.ACCEPT || controls.BACK)
    {
      if (controls.ACCEPT)
      {
        FlxG.openURL(Constants.URL_ITCH);
      }

      close();
    }

    super.update(elapsed);
  }

  override public function close():Void
  {
    FlxG.state.persistentDraw = true;
    FlxG.state.persistentUpdate = true;

    leftState = true;
    FlxG.switchState(targetState);
    super.close();
  }

  /**
   * Checks for updates.
   */
  public static function checkForUpdates():Void
  {
    var request:Http = new Http('https://itch.io/api/1/x/wharf/latest?target=${ITCH_TARGET}&channel_name=${getChannelName()}');
    request.request(false);

    if (request.responseData == null)
    {
      trace('Error while loading itch.io game uploads! Is the Game ID correct?');
      return;
    }

    var parser:JsonParser<ItchIOUploadStructure> = new JsonParser<ItchIOUploadStructure>();
    parser.ignoreUnknownVariables = true;
    parser.fromJson(request.responseData, null);

    if (parser.errors.length > 0)
    {
      trace('Failed to parse itch.io upload version!');

      for (error in parser.errors)
      {
        funkin.data.DataError.printError(error);
      }

      trace(request.responseData);

      return;
    }

    if (parser.value?.latest == null)
    {
      trace('Failed to get itch.io build! (Channel name: ${getChannelName()})');
      return;
    }

    updateVersion = parser.value.latest;
    updateVersion = updateVersion.withPre(''); // for -notarized-stapled-dmg in macos build at the moment

    var currentVersion:Version = Application.current.meta.get('version');

    isNewVersion = (updateVersion > currentVersion);

    if (isNewVersion)
    {
      trace('A new update is available!');
      trace('Current: ' + currentVersion);
      trace('Newest: ' + updateVersion);
    }
  }

  static function getChannelName():Null<String>
  {
    var toReturn:String = null;

    #if windows
    toReturn = 'windows';

    toReturn += '-64bit';
    #end

    #if linux
    toReturn = 'linux';

    toReturn += '-64bit';
    #end

    #if mac
    toReturn = 'osx';
    #end

    #if html5
    toReturn = 'html5';
    #end

    return toReturn;
  }
}

typedef ItchIOUploadStructure =
{
  var latest:String;
}
