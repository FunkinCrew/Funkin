package funkin.ui.options;

import funkin.modding.PolymodHandler;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import polymod.Polymod;
import funkin.ui.options.OptionsState.Page;

class ModMenu extends Page
{
  var renderedMods:TextMenuList;
  var enabledMods:Array<ModMetadata> = [];
  var detectedMods:Array<ModMetadata> = [];

  public function new():Void
  {
    super();

    renderedMods = new TextMenuList();
    add(renderedMods);

    refreshModList();
  }

  override function update(elapsed:Float):Void
  {
    if (FlxG.keys.justPressed.R)
    {
      refreshModList();
    }

    // if (FlxG.keys.justPressed.I && curSelected != 0)
    // {
    //   var oldOne:ModMenuItem = grpMods.members[curSelected - 1];
    //   grpMods.members[curSelected - 1] = grpMods.members[curSelected];
    //   grpMods.members[curSelected] = oldOne;
    //   changeSelection(-1);
    // }

    // if (FlxG.keys.justPressed.K && curSelected < grpMods.members.length - 1)
    // {
    //   var oldOne:ModMenuItem = grpMods.members[curSelected + 1];
    //   grpMods.members[curSelected + 1] = grpMods.members[curSelected];
    //   grpMods.members[curSelected] = oldOne;
    //   changeSelection(1);
    // }

    super.update(elapsed);
  }

  function refreshModList():Void
  {
    @:privateAccess
    renderedMods.byName.clear();

    #if desktop
    detectedMods = PolymodHandler.getAllMods();

    trace('ModMenu: Detected ${detectedMods.length} mods');

    for (index in 0...detectedMods.length)
    {
      var modMetadata:ModMetadata = detectedMods[index];
      var modName:String = modMetadata.title;
      renderedMods.createItem(0, 100 + renderedMods.length * 100, modName, BOLD, function() {
        var mod:ModMetadata = detectedMods[renderedMods.selectedIndex];
        if (enabledMods.contains(mod))
        {
          enabledMods.remove(mod);
        }
        else
        {
          enabledMods.push(mod);
        }
      });
    }
    #end
  }
}
