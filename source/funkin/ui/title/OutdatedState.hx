package funkin.ui.title;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatState;
import lime.app.Application;
import funkin.ui.mainmenu.MainMenuState;
import haxe.Http;

class OutdatedState extends MusicBeatState
{
  public static var leftState:Bool = false;
  public static var updateVersion:String = "";

  override function create()
  {
    super.create();

    var url = "https://raw.githubusercontent.com/Ethan-makes-music/Funkin/develop/gitVersion.txt";

    var request = new Http(url);

    request.onData = function(data:String) {
      // Data is the content of the .txt file
      updateVersion = data.trim();
      createText();
    };

    // Set the callback for any errors
    request.onError = function(msg:String) {
      trace("Error: " + msg);
      // In case of an error, proceed to MainMenuState or handle accordingly
      FlxG.switchState(() -> new MainMenuState());
    };

    // Send the request
    request.request(false);
  }

  function createText():Void
  {
    var ver = "v" + Application.current.meta.get('version');
    var txt:FlxText = new FlxText(0, 0, FlxG.width,
      "HEY! You're running an outdated version of the game!\nCurrent version is "
      + ver
      + " while the most recent version is "
      + updateVersion
      + "! Press Space to go to itch.io, or ESCAPE to ignore this!!",
      32);
    txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
    txt.screenCenter();
    add(txt);
  }

  override function update(elapsed:Float)
  {
    if (controls.ACCEPT)
    {
      FlxG.openURL("https://ninja-muffin24.itch.io/funkin");
      leftState = true;
      FlxG.switchState(() -> new MainMenuState());
    }
    if (controls.BACK)
    {
      leftState = true;
      FlxG.switchState(() -> new MainMenuState());
    }
    super.update(elapsed);
  }
}
