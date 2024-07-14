package funkin.ui.options;

import funkin.modding.PolymodHandler;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import polymod.Polymod;
import funkin.ui.AtlasText.AtlasFont;
import funkin.graphics.FunkinCamera;
import funkin.ui.options.OptionsState.Page;
import funkin.input.Controls;
import funkin.audio.FunkinSound;
import funkin.ui.TextMenuList.TextMenuItem;

class ModMenu extends Page
{
  var grpMods:FlxTypedGroup<ModMenuItem>;
  var enabledMods:Array<ModMetadata> = [];
  var detectedMods:Array<ModMetadata> = [];

  var curSelected:Int = 0;

  public function new():Void
  {
    super();

    grpMods = new FlxTypedGroup<ModMenuItem>();
    add(grpMods);

    refreshModList();
  }

  override function update(elapsed:Float)
  {
    if (FlxG.keys.justPressed.R) {
      refreshModList();
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
      trace('Refreshed Mod List!');
      trace('ModMenu: Detected ${detectedMods.length} mods');
    }

    selections();

    if (controls.UI_UP_P) {
      selections(-1);
      FunkinSound.playOnce(Paths.sound('scrollMenu'));
    }
    
    if (controls.UI_DOWN_P) {
      selections(1);
      FunkinSound.playOnce(Paths.sound('scrollMenu'));
    }
   
    if (FlxG.keys.justPressed.SPACE || FlxG.keys.justPressed.ENTER) {
      grpMods.members[curSelected].modEnabled = !grpMods.members[curSelected].modEnabled;
      if (grpMods.members[curSelected].modEnabled) {
        FlxFlicker.flicker(grpMods.members[curSelected], 1.1, 0.0625, true, true);
        FunkinSound.playOnce(Paths.sound('confirmMenu'));
        trace('Enabled a mod!');
      } else if (!grpMods.members[curSelected].modEnabled) {
        FunkinSound.playOnce(Paths.sound('cancelMenu'));
        trace('Disabled a mod!');
      }
    }

    if (controls.BACK) {
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
      FlxG.switchState(() -> new OptionsState());
    }

    if (FlxG.keys.justPressed.I && curSelected != 0)
    {
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
      var oldOne = grpMods.members[curSelected - 1];
      grpMods.members[curSelected - 1] = grpMods.members[curSelected];
      grpMods.members[curSelected] = oldOne;
      selections(-1);
    }

    if (FlxG.keys.justPressed.K && curSelected < grpMods.members.length - 1)
    {
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
      var oldOne = grpMods.members[curSelected + 1];
      grpMods.members[curSelected + 1] = grpMods.members[curSelected];
      grpMods.members[curSelected] = oldOne;
      selections(1);
    }
    super.update(elapsed);
  }

  function selections(change:Int = 0):Void
  {
    curSelected += change;

    if (curSelected >= detectedMods.length) curSelected = 0;
    if (curSelected < 0) curSelected = detectedMods.length - 1;

    for (txt in 0...grpMods.length)
    {
      if (txt == curSelected)
      {
        grpMods.members[txt].color = FlxColor.YELLOW;
      }
      else
        grpMods.members[txt].color = FlxColor.WHITE;
    }

    organizeByY();
  }

  function refreshModList():Void
  {
    while (grpMods.members.length > 0)
    {
      grpMods.remove(grpMods.members[0], true);
    }

    #if desktop
    detectedMods = PolymodHandler.getAllMods();

    trace('ModMenu: Detected ${detectedMods.length} mods');

    for (index in 0...detectedMods.length)
    {
      var modMetadata:ModMetadata = detectedMods[index];
      var modName:String = modMetadata.title;
      var txt:ModMenuItem = new ModMenuItem(0, 10 + (40 * index), 0, modName, 48);
      txt.setFormat(Paths.font('vcr.ttf'), 48, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
      txt.text = modName;
      grpMods.add(txt);
    }
    #end
  }

  function organizeByY():Void
  {
    for (i in 0...grpMods.length)
    {
      grpMods.members[i].y = 10 + (40 * i);
    }
  }
}

class ModMenuItem extends FlxText
{
  public var modEnabled:Bool = false;
  public var daMod:String;

  public function new(x:Float, y:Float, w:Float, str:String, size:Int)
  {
    super(x, y, w, str, size);
  }

  override function update(elapsed:Float)
  {
    if (modEnabled) {
      alpha = 1;
    } else {
      alpha = 0.5;
    }
    super.update(elapsed);
  }
}
