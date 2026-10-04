package funkin.ui.modmenu;

import flixel.FlxG;
import funkin.InitState;
import funkin.modding.PolymodHandler;
import funkin.save.Save;
import funkin.util.FileUtil;
import polymod.Polymod.ModDependencies;
import polymod.Polymod.ModMetadata;

/**
 * Controls dependency rules, disk syncing, and anything regarding list data.
 * Doesn't do animation stuff or selection or navigation or whatev, just data.
 * Poo.
 */
class ModListController
{
  final disabledList:ModMenuItemList;
  final enabledList:ModMenuItemList;

  /**
   * itemsInFolder
   */
  var itemsInFolder:Array<String> = [];

  /**
   * Mods the lists already held before a sync started, so existing items aren't rebuilt.
   */
  var carriedDisabledMods:Array<ModMetadata> = [];

  var carriedEnabledMods:Array<ModMetadata> = [];

  public function new(disabledList:ModMenuItemList, enabledList:ModMenuItemList)
  {
    this.disabledList = disabledList;
    this.enabledList = enabledList;
  }

  /**
   *
   */
  public function getEnabledModIds():Array<String>
  {
    var modIds:Array<String> = [];

    for (item in enabledList.modItems)
    {
      var modId = item.getModId();
      if (modId == ModMenuState.BASE_GAME_MOD_ID) continue;
      modIds.push(modId);
    }

    return modIds;
  }

  /**
   * Same as getEnabledModIds but with base game mod.
   */
  public function getEnabledModIdsWithBaseGame():Array<String>
  {
    var modIds:Array<String> = [];

    for (item in enabledList.modItems)
    {
      if (item.mod != null) modIds.push(item.getModId());
    }
    modIds.push(ModMenuState.BASE_GAME_MOD_ID);

    return modIds;
  }

  /**
   * Hands the enabled list over to Polymod.
   */
  public function applyToPolymod():Void
  {
    // Backup the user's save data before switching mods.
    var backupSlot:Int = Save.system.archiveBadSaveData(FlxG.save.data);
    trace('[SAVE] Backed up current save data in case of emergency to $backupSlot!');

    var enabledModIds:Array<String> = getEnabledModIds();

    PolymodHandler.disableAllMods();
    for (modId in enabledModIds)
    {
      PolymodHandler.enableMod(modId);
    }

    InitState.resetTitleState();
  }

  /**
   *
   */
  public function getMissingDependencies(mod:ModMetadata):Array<String>
  {
    var toEnable:Array<String> = [];

    var dependencies:ModDependencies = mod.dependencies;
    for (dependencyId => version in dependencies)
    {
      if (
        !toEnable.contains(dependencyId)
        && !enabledList.modItems.exists((item) -> item.getModId() == dependencyId && version.isSatisfiedBy(item.getModVersion()))
      )
      {
        toEnable.push(dependencyId);
      }
    }

    return toEnable;
  }

  /**
   *
   */
  public function getEnabledDependents(mod:ModMetadata):Array<String>
  {
    var dependents:Array<String> = [];

    for (enabledModItem in enabledList.modItems)
    {
      var enabledMod = enabledModItem.mod;
      if (enabledMod == null) continue;

      var dependencies:ModDependencies = enabledMod.dependencies;
      for (dependencyId => version in dependencies)
      {
        if (dependencyId == mod.id) dependents.push(enabledMod.title);
      }
    }

    return dependents;
  }

  public function countEnableBatch(item:ModMenuItem, seen:Array<String>):Int
  {
    if (item == null) return 0;
    var id = item.getModId();
    if (seen.contains(id)) return 0;
    seen.push(id);

    var total:Int = 1;
    for (depId in getMissingDependencies(item.mod))
    {
      var depItem = disabledList.modItems.find((it) -> it.getModId() == depId);
      if (depItem != null) total += countEnableBatch(depItem, seen);
    }
    return total;
  }

  public function countDisableBatch(item:ModMenuItem, seen:Array<String>):Int
  {
    if (item == null || item.mod == null) return 0;
    var id = item.getModId();
    if (seen.contains(id)) return 0;
    seen.push(id);

    var total:Int = 1; // this item
    for (depTitle in getEnabledDependents(item.mod))
    {
      var depItem = enabledList.modItems.find((it) -> it.getModTitle() == depTitle);
      if (depItem != null) total += countDisableBatch(depItem, seen);
    }
    return total;
  }

  public function findEnableInsertIndex(item:ModMenuItem):Int
  {
    for (enabledMod in enabledList.modItems)
    {
      if (enabledMod.mod == null) continue;

      var optionalDependencies:ModDependencies = enabledMod.getOptionalDependencies();
      if (optionalDependencies == null) continue;

      for (optionalDependencyId => version in optionalDependencies)
      {
        if (optionalDependencyId == item.getModId() && version.isSatisfiedBy(item.getModVersion()))
        {
          return enabledList.modItems.indexOf(enabledMod);
        }
      }
    }

    return enabledList.modItems.length;
  }

  public function isReorderBlocked(item:ModMenuItem, other:ModMenuItem, moveUp:Bool):Bool
  {
    if (moveUp) return requires(other, item) || optionallyUses(item, other);

    return requires(item, other) || optionallyUses(other, item);
  }

  /**
   * Checks if the mod requires the dependency.
   */
  function requires(mod:ModMenuItem, dependency:ModMenuItem):Bool
  {
    for (depId => version in mod.getDependencies())
    {
      if (dependency.getModId() == depId) return true;
    }
    return false;
  }

  function optionallyUses(mod:ModMenuItem, dependency:ModMenuItem):Bool
  {
    var optionalDependencies = mod.getOptionalDependencies();
    if (optionalDependencies == null) return false;

    for (depId => version in optionalDependencies)
    {
      if (dependency.getModId() == depId && version.isSatisfiedBy(dependency.getModVersion())) return true;
    }
    return false;
  }

  public function hasFolderChanged():Bool
  {
    var newItems:Array<String> = [];
    try
    {
      newItems = FileUtil.readDir(PolymodHandler.MOD_FOLDER);
    }
    catch (e:Dynamic)
    {
      trace('Failed to read mods folder: ${Std.string(e)}');
      return false;
    }

    return newItems.length != itemsInFolder.length;
  }

  public function syncWithDisk():
    {newDisabled:Array<ModMenuItem>, newEnabled:Array<ModMenuItem>}
  {
    PolymodHandler.getDisabledModsIncludingIncompatible(true);
    itemsInFolder = FileUtil.readDir(PolymodHandler.MOD_FOLDER);

    carriedDisabledMods = disabledList.modItems.map((item) -> item.mod);
    carriedEnabledMods = enabledList.modItems.map((item) -> item.mod).filter((m) -> m != null && m.id != ModMenuState.BASE_GAME_MOD_ID);

    var newDisabled:Array<ModMenuItem> = syncDisabledList();
    var newEnabled:Array<ModMenuItem> = syncEnabledList();

    carriedDisabledMods = [];
    carriedEnabledMods = [];

    return {
      newDisabled: newDisabled,
      newEnabled: newEnabled
    };
  }

  function syncDisabledList():Array<ModMenuItem>
  {
    var disabledMods:Array<ModMetadata> = PolymodHandler.getDisabledModsIncludingIncompatible();

    var liveIds:Array<String> = disabledMods.map((m) -> m.id).concat(PolymodHandler.getEnabledMods().map((m) -> m.id));

    if (carriedDisabledMods.length > 0 || carriedEnabledMods.length > 0)
    {
      var allKnownIds:Array<String> = carriedDisabledMods.concat(carriedEnabledMods).map((m) -> m.id);

      // Drop carried-over mods that no longer exist on disk at all.
      var reconciled:Array<ModMetadata> = carriedDisabledMods.filter((m) -> liveIds.contains(m.id));

      for (mod in disabledMods)
      {
        if (!allKnownIds.contains(mod.id)) reconciled.push(mod);
      }

      for (mod in PolymodHandler.getEnabledMods())
      {
        if (mod.id == ModMenuState.BASE_GAME_MOD_ID) continue;
        if (!allKnownIds.contains(mod.id)) reconciled.push(mod);
      }

      disabledMods = reconciled;
    }

    var keepIds:Array<String> = disabledMods.map((m) -> m.id);
    for (item in disabledList.modItems.copy())
    {
      if (item.mod == null) continue;
      if (!keepIds.contains(item.getModId())) disabledList.removeMod(item);
    }

    var newItems:Array<ModMenuItem> = [];
    for (mod in disabledMods)
    {
      if (mod.id == ModMenuState.BASE_GAME_MOD_ID) continue;
      if (disabledList.modItems.exists((it) -> it.getModId() == mod.id)) continue;

      var item = new ModMenuItem(mod);
      if (!PolymodHandler.isModCompatible(mod)) item.setIncompatible();
      item.localAlpha = 0;
      disabledList.addModRawWithoutLayout(item, disabledList.modItems.length);
      newItems.push(item);
    }

    return newItems;
  }

  function syncEnabledList():Array<ModMenuItem>
  {
    var enabledMods:Array<ModMetadata> = PolymodHandler.getEnabledMods().filter((m) -> PolymodHandler.isModCompatible(m));

    var liveIds:Array<String> = enabledMods.map((m) -> m.id).concat(PolymodHandler.getDisabledModsIncludingIncompatible().map((m) -> m.id));

    if (carriedDisabledMods.length > 0 || carriedEnabledMods.length > 0)
    {
      var allKnownIds:Array<String> = carriedDisabledMods.concat(carriedEnabledMods).map((m) -> m.id);
      var reconciled:Array<ModMetadata> = carriedEnabledMods.filter((m) -> liveIds.contains(m.id));

      for (mod in enabledMods)
      {
        if (mod.id == ModMenuState.BASE_GAME_MOD_ID) continue;
        if (!allKnownIds.contains(mod.id)) reconciled.push(mod);
      }

      enabledMods = reconciled;
    }

    var keepIds:Array<String> = enabledMods.map((m) -> m.id);
    for (item in enabledList.modItems.copy())
    {
      if (item.getModId() == ModMenuState.BASE_GAME_MOD_ID) continue;
      if (!keepIds.contains(item.getModId())) enabledList.removeMod(item);
    }

    var newItems:Array<ModMenuItem> = [];
    for (mod in enabledMods)
    {
      if (mod.id == ModMenuState.BASE_GAME_MOD_ID) continue;
      if (enabledList.modItems.exists((it) -> it.getModId() == mod.id)) continue;

      var item = new ModMenuItem(mod);
      item.localAlpha = 0;
      enabledList.addModRawWithoutLayout(item, enabledList.modItems.length);
      newItems.push(item);
    }

    // The base game is always in the enabled list, pinned to the top.
    if (!enabledList.modItems.exists((item) -> item.getModId() == ModMenuState.BASE_GAME_MOD_ID))
    {
      var baseGameItem = new ModMenuItem(null, ModMenuState.BASE_GAME_MOD_ICON_PATH, ModMenuState.BASE_GAME_MOD_ID, 'Base Game', 'Default game content');
      baseGameItem.locked = true;
      enabledList.addModRawWithoutLayout(baseGameItem, 0);
    }

    return newItems;
  }
}
