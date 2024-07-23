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

    if (FlxG.keys.justPressed.I && renderedMods.selectedIndex != 0)
    {
      changeOrder(-1);
    }

    if (FlxG.keys.justPressed.K && renderedMods.selectedIndex < renderedMods.length - 1)
    {
      changeOrder(1);
    }

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
      renderedMods.createItem(10, 10 + renderedMods.length * 100, modName, BOLD, function() {
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

  function changeOrder(change:Int):Void
  {
    var index = renderedMods.selectedIndex;
    var oldOne = renderedMods.members[index + change];
    var newOne = renderedMods.members[index];
    var newY = newOne.y;

    newOne.y = oldOne.y;
    oldOne.y = newY;

    renderedMods.members[index + change] = newOne;
    renderedMods.members[index] = oldOne;
    renderedMods.selectItem(index + change);
  }
}
