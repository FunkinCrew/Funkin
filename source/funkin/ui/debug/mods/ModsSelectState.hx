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
import polymod.util.DependencyUtil;
import polymod.Polymod.ModMetadata;

using StringTools;

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

  /**
   * A list for all enabled mods. The main point of this list is to provide priorities of enabled mods without focusing on dependencies.
   * Polymod handles sorting by dependencies internally upon loading mods.
   */
  var changeableModList:Array<String> = [];

  override public function create()
  {
    super.create();

    prevPersistentDraw = FlxG.state.persistentDraw;
    prevPersistentUpdate = FlxG.state.persistentUpdate;

    FlxG.state.persistentDraw = false;
    FlxG.state.persistentUpdate = false;

    Cursor.show();
    WindowManager.instance.reset();

    changeableModList = Save.instance.enabledModIds.copy();
    reloadModOrder();

    modListLoadAll.onClick = function(_) {
      changeableModList = PolymodHandler.getAllModIds().copy();
      reloadModOrder();
    }

    modListUnloadAll.onClick = function(_) {
      changeableModList = [];
      reloadModOrder();
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

  // This should also account for the mod order and put dependencies on the bottom.
  function reloadModOrder()
  {
    modListUnloadedBox.removeAllComponents();
    modListLoadedBox.removeAllComponents();

    var allMods:Array<ModMetadata> = listAllModsOrdered();

    for (mod in allMods)
    {
      var isLoaded:Bool = changeableModList.contains(mod.id);
      var dependableChildren:Array<String> = [];
      var optionalChildren:Array<String> = [];

      for (childMod in allMods)
      {
        if (childMod.id == mod.id) continue;
        for (dep => ver in childMod.dependencies)
        {
          if (dep == mod.id && ver.isSatisfiedBy(mod.modVersion) && !dependableChildren.contains(mod.id)) dependableChildren.push(mod.id);
        }
        for (dep => ver in childMod.optionalDependencies)
        {
          if (dep == mod.id && ver.isSatisfiedBy(mod.modVersion) && !optionalChildren.contains(mod.id)) optionalChildren.push(mod.id);
        }
      }

      // Update color of the mod title based on if it's an optional dependency, a required dependency or not a dependency at all.
      var overrideColor:Null<String> = null;
      if (optionalChildren.length > 0 && dependableChildren.length == 0)
      {
        overrideColor = "0xffff00";
      }
      else if (dependableChildren.length > 0)
      {
        overrideColor = "0xff8c00";
      }

      var button = new ModButton(mod, overrideColor);
      button.tooltip = "Click to Enable/Disable.\nRight Click to View Info.";
      if (isLoaded) button.tooltip += "\nShift+Click to Move Upwards.\nCtrl+Click to Move Downwards.";

      // Check if there is a window present and apply a different style to the corresponding button.
      if (windowContainer.childComponents.length > 0)
      {
        var firstComp = windowContainer.childComponents[0];
        if (Std.isOfType(firstComp, ModInfoWindow))
        {
          var modWindow:ModInfoWindow = cast firstComp;
          if (button.linkedMod.id == modWindow.linkedMod.id
            && button.linkedMod.modVersion == modWindow.linkedMod.modVersion) button.styleNames = "modBoxSelected";
        }
      }

      button.onRightClick = function(_) {
        cleanupBeforeSwitch();
        button.styleNames = "modBoxSelected";
        var infoWindow = new ModInfoWindow(this, mod);

        if (dependableChildren.length > 0) infoWindow.modWindowDependency.text = "This Mod is a Dependency of: " + dependableChildren.join(", ");
        if (optionalChildren.length > 0) infoWindow.modWindowOptional.text = "This Mod is an Optional Dependency of: " + optionalChildren.join(", ");

        windowContainer.addComponent(infoWindow);
      }

      button.onClick = function(_) {
        if (isLoaded)
        {
          var modIndex:Int = changeableModList.indexOf(mod.id);
          if (FlxG.keys.pressed.SHIFT) modIndex++;
          else if (FlxG.keys.pressed.CONTROL) modIndex--;

          var prevIndex:Int = changeableModList.indexOf(mod.id);
          changeableModList.remove(mod.id);

          if (prevIndex != modIndex)
          {
            // The priority of the mod has been changed.
            modIndex = Std.int(flixel.math.FlxMath.bound(modIndex, 0, changeableModList.length - 1));
            changeableModList.insert(modIndex, mod.id);
          }
          else
          {
            // Go through a list of all mods. If a mod depends on this mod to works and this mod's version satisfies the mod's version rule, remove it from the list.
            for (childMod in allMods)
            {
              if (childMod.dependencies.exists(mod.id)
                && childMod.dependencies[mod.id].isSatisfiedBy(mod.modVersion)
                && changeableModList.contains(childMod.id)) changeableModList.remove(childMod.id);
            }
          }
        }
        else
        {
          changeableModList.push(mod.id);

          // Go through a list of all mods. If a mod is a dependency of this mod and it's version satisfies this mod's version rule, add it to the list.
          for (childMod in allMods)
          {
            if (mod.dependencies.exists(childMod.id)
              && mod.dependencies[childMod.id].isSatisfiedBy(childMod.modVersion)
              && !changeableModList.contains(childMod.id)) changeableModList.push(childMod.id);
          }
        }

        reloadModOrder();
      }

      if (isLoaded) modListLoadedBox.addComponent(button);
      else
        modListUnloadedBox.addComponent(button);
    }
  }

  /**
   * Order the mods so that the enabled mods are first.
   */
  function listAllModsOrdered()
  {
    var allMods:Array<ModMetadata> = PolymodHandler.getAllMods().copy();
    var finishedList:Array<ModMetadata> = [];

    for (modId in changeableModList)
    {
      for (mod in allMods)
      {
        if (mod.id == modId)
        {
          finishedList.push(mod);
          allMods.remove(mod);
          break;
        }
      }
    }

    // Order the enabled mods by dependencies.
    finishedList = DependencyUtil.sortByDependencies(finishedList);

    // Add the remainding mods.
    finishedList = finishedList.concat(allMods);

    // Reverse the list so that the first mods go down.
    finishedList.reverse();

    return finishedList;
  }

  function cleanupBeforeSwitch()
  {
    for (window in WindowManager.instance.windows)
      WindowManager.instance.closeWindow(window);

    for (button in modListUnloadedBox.childComponents.concat(modListLoadedBox.childComponents))
    {
      if (Std.isOfType(button, ModButton))
      {
        var realButton:ModButton = cast button;
        realButton.styleNames = "modBox";
      }
    }

    windowContainer.removeAllComponents();
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
    trace("Loading Mods: " + changeableModList);

    Save.instance.enabledModIds = changeableModList;
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
