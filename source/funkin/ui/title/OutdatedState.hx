package funkin.ui.title;

import haxe.Http;
import haxe.Json;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import funkin.ui.MusicBeatState;
import funkin.util.Constants;
import funkin.util.VersionUtil;

using StringTools;

/**
 * Class that notifies the player that there is an update
 */
class OutdatedState extends MusicBeatState
{
  #if windows
  static final URL:String = 'https://itch.io/api/1/x/wharf/latest?target=ninja-muffin24/funkin&channel_name=windows-64bit';
  static final OS_CHECK:String = 'Windows';
  #end

  #if mac
  static final URL:String = 'https://itch.io/api/1/x/wharf/latest?target=ninja-muffin24/funkin&channel_name=osx';
  static final OS_CHECK:String = 'macOS';
  #end

  #if linux
  static final URL:String = 'https://itch.io/api/1/x/wharf/latest?target=ninja-muffin24/funkin&channel_name=linux-64bit';
  static final OS_CHECK:String = 'Linux';
  #end

  /**
   * Whether the game is outdated or not
   */
  public static var outdated(get, never):Bool;

  static var currentVersion:Null<String> = null;
  static var newVersion:Null<String> = null;

  var leftState:Bool = false;

  static function get_outdated():Bool
  {
    if (currentVersion == null || newVersion == null)
    {
      retrieveVersions();
    }

    return VersionUtil.validateVersionStr(currentVersion, '<' + newVersion);
  }

  override function create():Void
  {
    super.create();

    var bg:FunkinSprite = new FunkinSprite().makeSolidColor(FlxG.width, FlxG.height, FlxColor.BLACK);
    add(bg);

    var txt:FlxText = new FlxText(0, 0, FlxG.width,
      'HEY! You\'re running an outdated version of the game!\nCurrent version is '
      + currentVersion
      + ' while the most recent version is '
      + newVersion
      + '!\n Press ACCEPT-Button to go to itch.io, '
      + '\nor BACK-Button to ignore this!!',
      32);
    txt.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, CENTER);
    txt.screenCenter();
    add(txt);

    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.pause();
    }
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (leftState)
    {
      return;
    }

    if (controls.ACCEPT)
    {
      FlxG.openURL('https://ninja-muffin24.itch.io/funkin');
    }

    if (controls.BACK)
    {
      leftState = true;

      if (FlxG.sound.music != null)
      {
        FlxG.sound.music.resume();
      }

      FlxG.switchState(() -> new TitleState());
    }
  }

  static function retrieveVersions():Void
  {
    var http:Http = new Http(URL);
    http.onData = function(data) {
      if (data == null || data.length == 0) return;
      var json = Json.parse(data);
      newVersion = sanitizeVersion(json.latest);
    };
    http.request(false);

    newVersion = newVersion ?? sanitizeVersion(Constants.VERSION);
    currentVersion = sanitizeVersion(Constants.VERSION);
  }

  static function sanitizeVersion(version:String):String
  {
    return ~/[^0-9.]/g.replace(version, "");
  }

  /**
   * @return `OutdatedState` or `TitleState`
   */
  public static function build():MusicBeatState
  {
    #if debug
    return new TitleState();
    #else
    return outdated ? new OutdatedState() : new TitleState();
    #end
  }
}
