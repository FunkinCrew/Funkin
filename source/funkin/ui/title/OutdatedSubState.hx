package funkin.ui.title;

import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import funkin.ui.MusicBeatSubState;
import lime.app.Application;
import haxe.Http;

class OutdatedSubState extends MusicBeatSubState
{
  public static var leftState:Bool = false;

  static final URL:String = "https://raw.githubusercontent.com/FunkinCrew/Funkin/main/Project.xml";

  static var currentVersion:Null<String> = null;
  static var newVersion:Null<String> = null;

  public static var outdated(get, never):Bool;

  static function get_outdated():Bool
  {
    if (currentVersion == null || newVersion == null)
    {
      retrieveVersions();
    }

    return currentVersion != newVersion;
  }

  override function create():Void
  {
    super.create();

    var bg:FunkinSprite = new FunkinSprite().makeSolidColor(FlxG.width, FlxG.height, FlxColor.BLACK);
    add(bg);

    var txt:FlxText = new FlxText(0, 0, FlxG.width,
      "HEY! You're running an outdated version of the game!\nCurrent version is "
      + 'v$currentVersion'
      + " while the most recent version is "
      + 'v$newVersion'
      + "! Press Space to go to itch.io, or ESCAPE to ignore this!!",
      32);
    txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
    txt.screenCenter();
    add(txt);

    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.pause();
    }
  }

  override function update(elapsed:Float):Void
  {
    if (controls.ACCEPT)
    {
      FlxG.openURL("https://ninja-muffin24.itch.io/funkin");
    }
    if (controls.BACK)
    {
      leftState = true;

      if (FlxG.sound.music != null)
      {
        FlxG.sound.music.resume();
      }

      this.close();
    }
    super.update(elapsed);
  }

  static function retrieveVersions():Void
  {
    var http:Http = new Http(URL);

    http.onData = function(data:String) {
      var xml:Xml = Xml.parse(data);
      var project:Xml = xml.elementsNamed("project").next();
      var app:Xml = project.elementsNamed("app").next();

      newVersion = app.get("version").toString();
    };

    http.request(false);

    currentVersion = Application.current.meta.get('version');
  }
}
