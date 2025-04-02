package funkin.ui.title;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatSubState;
import thx.semver.Version;
import thx.semver.VersionRule;
import funkin.util.VersionUtil;
import lime.app.Application;
import flixel.util.typeLimit.NextState;
import haxe.Http;
import json2object.JsonParser;

/**
 * A substate that shows
 */
class OutdatedSubState extends MusicBeatSubState
{
  /**
   * The itch.io Game to use for checking updates.
   */
  public static final ITCH_TARGET:String = "ninja-muffin24/funkin";

  /**
   * The newest version.
   */
  public static var updateVersion:Null<Version>;

  /**
   * Is there a new version available?
   */
  public static var isNewVersion:Bool;

  /**
   * Is the new version a minor patch?
   */
  public static var isMinorVersion:Bool;

  /**
   * If the user has seen this state already.
   */
  public static var leftState:Bool = false;

  /**
   * State to go to when this is finished.
   */
  public var targetState:Null<NextState>;

  override public function create():Void
  {
    // Disable the parent state.
    FlxG.state.persistentDraw = false;
    FlxG.state.persistentUpdate = false;

    // Updates variables required if not cached already.
    if (updateVersion == null)
    {
      checkForUpdates();
    }

    // Close if we have already seen this, or if there is no update.
    if (!isNewVersion || leftState)
    {
      close();
      return;
    }

    var updateText:String = "HEY! There is a new " + (isMinorVersion ? 'patch' : 'update') + " available!\nCurrent version is "
      + "v"
      + Application.current.meta.get('version')
      + ", while newest version is "
      + "v"
      + updateVersion
      + "!\nPress "
      + controls.getDialogueNameFromControl(ACCEPT, true)
      + " to go to itch.io, or "
      + controls.getDialogueNameFromControl(BACK, true)
      + " to ignore this!!";

    var txt:FlxText = new FlxText(0, 0, FlxG.width - 50, updateText, 32);
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
    leftState = true;
    if (targetState != null)
    {
      FlxG.switchState(targetState);
    }

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
      trace('[UPDATE_CHECK] Error while loading itch.io game uploads! Are you sure that you are connected to the internet?');
      return;
    }

    var parser:JsonParser<ItchIOUploadStructure> = new JsonParser<ItchIOUploadStructure>();
    parser.ignoreUnknownVariables = true;
    parser.fromJson(request.responseData, null);

    if (parser.errors.length > 0)
    {
      trace('[UPDATE_CHECK] Failed to parse itch.io upload version!');

      for (error in parser.errors)
      {
        funkin.data.DataError.printError(error);
      }

      trace(request.responseData);

      return;
    }

    if (parser.value?.latest == null)
    {
      trace('[UPDATE_CHECK] Failed to get itch.io build! (Channel name: ${getChannelName()})');
      return;
    }

    updateVersion = parser.value.latest;
    updateVersion = updateVersion.withPre(''); // for -notarized-stapled-dmg in macos build at the moment

    var currentVersion:Version = Application.current.meta.get('version');
    var newVersionRule:VersionRule = '>$currentVersion';

    isNewVersion = VersionUtil.validateVersion(updateVersion, newVersionRule);
    if (isNewVersion)
    {
      trace('[UPDATE_CHECK] A new update is available! ($updateVersion)');
      var minorVersionRule:VersionRule = '${currentVersion.major}.${currentVersion.minor}.x';
      isMinorVersion = VersionUtil.validateVersion(updateVersion, minorVersionRule);
      if (isMinorVersion)
      {
        trace('[UPDATE_CHECK] Looks like Newest Version is a patch!');
      }
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

/**
 * The structure of what `https://itch.io/api/1/x/wharf/latest` returns.
 */
typedef ItchIOUploadStructure =
{
  var latest:String;
}
