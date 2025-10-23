package funkin.ui.title;

import flixel.util.FlxTimer;
#if FEATURE_CHECK_FOR_UPDATES
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatSubState;
import thx.semver.Version;
import thx.semver.VersionRule;
import funkin.util.VersionUtil;
import lime.app.Application;
import flixel.util.FlxSignal;
import haxe.Http;
import json2object.JsonParser;

/**
 * A substate that tells the user that an update is available.
 */
@:build(funkin.util.macro.EnvironmentMacro.build())
@:nullSafety
class OutdatedSubState extends MusicBeatSubState
{
  /**
   * The itch.io Game to use for checking updates.
   */
  @:envField({mandatoryIfDefined: "FEATURE_CHECK_FOR_UPDATES"})
  public static final ITCH_TARGET:Null<String>;

  /**
   * The newest version.
   */
  public static var updateVersion:Null<Version>;

  /**
   * Is there a new version available?
   */
  public static var isNewVersion:Null<Bool>;

  /**
   * Is the new version a minor patch?
   */
  public static var isMinorVersion:Null<Bool>;

  /**
   * If the user has seen this state already.
   */
  public static var leftState:Bool = false;

  /**
   * Signal to dispatch when this is finished.
   */
  public var onFinish:FlxSignal;

  /**
   * If you can control the menu or not.
   */
  public var canInput:Bool;

  public function new()
  {
    canInput = false;
    onFinish = new FlxSignal();

    super();
  }

  override public function create():Void
  {
    // Disable the parent state.
    FlxG.state.persistentDraw = false;
    FlxG.state.persistentUpdate = false;

    // Re-enable input after half a second to stop accidental `ACCEPT` inputs.
    new FlxTimer().start(0.5, function(_) {
      canInput = true;
    });

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

    var updateText:String = 'HEY! There is a new ${(isMinorVersion ?? true) ? 'patch' : 'update'} available!'
      + '\nThis version is v${Application.current.meta.get('version')}, while the newest version is v${updateVersion}.'
      + '\nPress ${controls.getDialogueNameFromControl(ACCEPT, true)} to go to itch.io, or ${controls.getDialogueNameFromControl(BACK, true)} to ignore this.';

    var txt:FlxText = new FlxText(0, 0, FlxG.width - 50, updateText, 32);
    txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
    txt.screenCenter();
    add(txt);

    super.create();
  }

  override function update(elapsed:Float):Void
  {
    if ((controls.ACCEPT || controls.BACK) && canInput)
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

    super.close();

    onFinish.dispatch();
    onFinish.destroy();
  }

  /**
   * Checks for updates.
   */
  public static function checkForUpdates():Void
  {
    trace('[UPDATE_CHECK] Checking for updates...');

    var request:Http = new Http('https://itch.io/api/1/x/wharf/latest?target=${ITCH_TARGET}&channel_name=${getChannelName()}');
    request.request(false);

    if (request.responseData == null)
    {
      trace('[UPDATE_CHECK] Error while loading itch.io game uploads! Are you sure that you are connected to the internet?');
      return;
    }

    var parser:JsonParser<ItchIOUploadStructure> = new JsonParser<ItchIOUploadStructure>();
    parser.ignoreUnknownVariables = true;
    parser.fromJson(request.responseData ?? '{}', null);

    if (parser.errors.length > 0)
    {
      trace('[UPDATE_CHECK] Failed to parse itch.io upload version!');

      for (error in parser.errors)
      {
        funkin.data.DataError.printError(error);
      }

      trace('  ' + request.responseData);

      return;
    }

    if (parser.value?.latest == null)
    {
      trace('[UPDATE_CHECK] Failed to get itch.io build! (Channel name: ${getChannelName()})');
      return;
    }

    var updateVersion:Version = parser.value.latest;
    if (updateVersion != null) updateVersion = updateVersion.withPre(''); // We don't check pre.

    var currentVersion:Version = Version.stringToVersion(Application.current.meta.get('version') ?? '0.0.0');
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

    OutdatedSubState.updateVersion = updateVersion;
  }

  static function getChannelName():String
  {
    var toReturn:Null<String> = null;

    #if windows
    toReturn = 'windows';
    toReturn += '-64bit'; // Only x64 builds are available.
    #end

    #if linux
    toReturn = 'linux';
    toReturn += '-64bit'; // Only x64 builds are available.
    #end

    #if mac
    toReturn = 'osx';
    #end

    if (toReturn == null)
    {
      throw "Can't find a itch.io channel name for this target. That is not good!";
    }

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
#end
