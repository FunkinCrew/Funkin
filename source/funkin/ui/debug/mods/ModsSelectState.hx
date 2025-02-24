package funkin.ui.debug.mods;

import flixel.FlxG;
import funkin.audio.FunkinSound;
import funkin.input.Cursor;
import funkin.modding.PolymodHandler;
import funkin.save.Save;
import funkin.ui.debug.mods.components.ModInfoWindow;
import funkin.ui.debug.mods.components.ModButton;
import haxe.ui.backend.flixel.UISubState;
import haxe.ui.events.UIEvent;
import haxe.ui.components.Button;
import haxe.ui.containers.VBox;
import haxe.ui.containers.windows.WindowManager;
import haxe.ui.tooltips.ToolTipManager;

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/mod-select/main-view.xml"))
class ModsSelectState extends UISubState
{
  var modListLoadedBox:VBox;
  var modListUnloadedBox:VBox;
  var modListLoadAll:Button;
  var modListUnloadAll:Button;
  var modListApplyButton:Button;
  var modListExitButton:Button;

  var prevPersistentDraw:Bool;
  var prevPersistentUpdate:Bool;

  override public function create()
  {
    super.create();

    // prev shit copied from latencystate
    prevPersistentDraw = FlxG.state.persistentDraw;
    prevPersistentUpdate = FlxG.state.persistentUpdate;

    FlxG.state.persistentDraw = false;
    FlxG.state.persistentUpdate = false;

    Cursor.show();
    WindowManager.instance.reset();
    WindowManager.instance.container = windowContainer;

    for (mod in PolymodHandler.getAllMods())
    {
      var loaded = Save.instance.enabledModIds.contains(mod.id);

      var button = new ModButton(mod);
      button.tooltip = "Click to Enable/Disable.\nRight Click to View Info.";

      button.onRightClick = function(_) {
        for (window in WindowManager.instance.windows)
          WindowManager.instance.closeWindow(window);

        var infoWindow = new ModInfoWindow(mod);
        infoWindow.linkedButton = button;
        WindowManager.instance.addWindow(infoWindow);
      }

      button.onClick = function(_) {
        if (button.parentComponent == modListLoadedBox)
        {
          modListLoadedBox.removeComponent(button, false);
          modListUnloadedBox.addComponentAt(button, 0);
        }
        else
        {
          modListUnloadedBox.removeComponent(button, false);
          modListLoadedBox.addComponentAt(button, 0);
        }
      }

      if (loaded) modListLoadedBox.addComponent(button);
      else
        modListUnloadedBox.addComponent(button);
    }

    modListLoadAll.onClick = function(_) {
      while (modListUnloadedBox.childComponents.length > 0)
      {
        var mod = modListUnloadedBox.childComponents[0];

        modListUnloadedBox.removeComponent(mod, false);
        modListLoadedBox.addComponent(mod);
      }
    }

    modListUnloadAll.onClick = function(_) {
      while (modListLoadedBox.childComponents.length > 0)
      {
        var mod = modListLoadedBox.childComponents[0];

        modListLoadedBox.removeComponent(mod, false);
        modListUnloadedBox.addComponent(mod);
      }
    }

    modListLoadedBox.registerEvent(UIEvent.COMPONENT_ADDED, function(_) {
      modListApplyButton.disabled = false;
    });
    modListUnloadedBox.registerEvent(UIEvent.COMPONENT_ADDED, function(_) {
      modListApplyButton.disabled = false;
    });

    modListApplyButton.onClick = function(_) save();
    modListExitButton.onClick = function(_) close();
  }

  override public function close()
  {
    FlxG.state.persistentDraw = prevPersistentDraw;
    FlxG.state.persistentUpdate = prevPersistentUpdate;

    Cursor.hide();
    WindowManager.instance.reset();
    ToolTipManager.instance.reset();

    super.close();
  }

  function save()
  {
    var loadMods = [];
    for (child in modListLoadedBox.childComponents)
    {
      loadMods.push(child.id);
    }

    trace("Loading Mods: " + loadMods);

    Save.instance.enabledModIds = loadMods;

    PolymodHandler.forceReloadAssets();
    modListApplyButton.disabled = true;
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight)
    {
      FunkinSound.playOnce(Paths.sound("chartingSounds/ClickDown"));
    }

    if (FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight)
    {
      FunkinSound.playOnce(Paths.sound("chartingSounds/ClickUp"));
    }

    if (controls.BACK) close();
    if (controls.ACCEPT) save();
  }
}
