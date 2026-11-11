package funkin.ui.modmenu;

import flixel.FlxG;
import flixel.tweens.FlxEase;
import funkin.InitState;
import funkin.audio.FunkinSound;
import funkin.group.FunkinGroup.FunkinSpriteGroup;
import funkin.modding.PolymodHandler;
import funkin.save.Save;
import funkin.ui.modmenu.ModMenuState.ModMenuSelection;
import funkin.ui.transition.preload.hotreload.ModReloader;
import funkin.util.WindowUtil;
import polymod.Polymod.ModDependencies;
import polymod.Polymod.ModMetadata;

/**
 * Everything about the two mod lists that isn't drawing them is done here!
 * Plus extra helper stuff! Alot of these functions and whatnot aren't used frequently..
 * But... it is useful for messing around and during development.
 *
 * Rules: which dependencies come along when enabling or disabling, and what blocks a reorder.
 * Disk management: reconciling the lists with the mods folder, and applying the result to Polymod, very simple tho.
 * Movement: enabling, disabling and reordering mods.
 * Transitions: the items that transition between the lists while that happens.
 *
 * The actual lists themselves only know how to lay out and scroll their items.
 * Any selection changes are basically reported through `setSelection`.
 */
class ModListManager
{
  /**
   * How long the lists take to close the gap / make room, in seconds.
   */
  static inline final LIST_REFLOW_DURATION:Float = 0.28;

  /**
   * How long it takes for a single transition / item flight to finish, in seconds! gagaga!
   */
  static inline final FLIGHT_DURATION:Float = 0.2;

  /**
   * The list with disabled mods.
   */
  final disabledList:ModMenuItemList;

  /**
   * The list with enabled mods.
   */
  final enabledList:ModMenuItemList;

  /**
   * Callback that gets called when there's a selection change.
   */
  final setSelection:ModMenuSelection->Void;

  /**
   * The mods that are inside the mod folder currently.
   */
  var itemsInFolder:Array<String> = [];

  /**
   * The disabled mods that the list already held before syncing started.
   * Used to prevent existing items to be rebuilt.
   */
  var carriedDisabledMods:Array<ModMetadata> = [];

  /**
   * The enabled mods that the list already held before syncing started.
   * Used to prevent existing items to be rebuilt.
   */
  var carriedEnabledMods:Array<ModMetadata> = [];

  /**
   * The group that mid-flight items are drawn in.
   * Created on `attachTransitionLayer()`.
   */
  public var transitionLayer(default, null):FunkinSpriteGroup;

  /**
   * Whether any item is still flying.
   */
  public var hasTransitions(get, never):Bool;

  /**
   * Items that are currently mid-flight between the two lists.
   * Each one owns their own transition state (via `ModMenuItem.startFlight`), plus the
   * list/index it should land in once that flight completes.
   */
  final pending:Array<TransitionRecord> = [];

  /**
   * Creates a new list manager instance.
   * @param disabledList The disabled list instance we want to use.
   * @param enabledList The enabled list instance we want to use.
   * @param setSelection The callback for when there's a selection change.
   */
  public function new(disabledList:ModMenuItemList,
    enabledList:ModMenuItemList,
    setSelection:ModMenuSelection->Void)
  {
    this.disabledList = disabledList;
    this.enabledList = enabledList;
    this.setSelection = setSelection;
  }

  // RULES AND DISK SYNC //

  /**
   * Gets the enabled mod ids and returns them.
   * @return Array<String> The array that includes the enabled mod ids.
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
   * Gets the enabled mod ids including the base game mod, and returns them.
   * @return Array<String> The array that includes both the enabled mod ids and the base game mod.
   */
  public function getEnabledModIdsWithBaseGame():Array<String>
  {
    var modIds:Array<String> = [];

    // The list stores its items bottom to top (see `ModMenuItemList.getModItemYPosForCount`), so the top-most mod is the LAST item.
    // Callers pick the first mod that has what they're looking for, so this has to go top to bottom, with the base game last.
    var i:Int = enabledList.modItems.length;
    while (i-- > 0)
    {
      var item = enabledList.modItems[i];
      if (item.mod != null) modIds.push(item.getModId());
    }
    modIds.push(ModMenuState.BASE_GAME_MOD_ID);

    return modIds;
  }

  /**
   * Hands the list of enabled mods over to Polymod and applies it.
   */
  public function applyToPolymod():Void
  {
    // Backup the user's save data before switching mods.
    var backupSlot:Int = Save.system.archiveBadSaveData(FlxG.save.data);
    trace(' MOD MENU '.bold().bg_orange() + ' [SAVE] Backed up current save data in case of emergency to $backupSlot!');

    var enabledModIds:Array<String> = getEnabledModIds();

    PolymodHandler.disableAllMods();
    for (modId in enabledModIds)
    {
      PolymodHandler.enableMod(modId);
    }

    InitState.resetTitleState();
  }

  /**
   * Applies the list of enabled mods, then reloads the mods, scripts and registries right away.
   * Unlike hot-reloading, this doesn't purge any assets and it doesn't send you to another state!
   * So it can run while the menu is still on screen!! YES!
   *
   * @param onReloaded Called on the main thread once everything has been reloaded.
   */
  public function applyAndReload(onReloaded:Void->Void):Void
  {
    applyToPolymod();

    ModReloader.reload(null, onReloaded);
  }

  /**
   * Look for missing dependencies the mod requires in order for it to be running.
   * @param mod The mod you want to check
   * @return Array<String> The list containing all of the missing dependencies that mod requires.
   */
  public function getMissingDependencies(mod:ModMetadata):Array<String>
  {
    var toEnable:Array<String> = [];

    var dependencies:ModDependencies = mod.dependencies;
    for (dependencyId => version in dependencies)
    {
      // hollyyy nest.
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
   * Looks for and gets you the enabled dependencies this mod has.
   * @param mod The mod you want to check.
   * @return Array<String> An array containing all of the enabled dependencies this mod currently has.
   */
  public function getEnabledDependencies(mod:ModMetadata):Array<String>
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

  /**
   * Counts how many mods that will move to the enabled list if you were to enable the item given.
   *
   *  NOTE: This can probably be used more efficiently but I'm having brain fog so I'm keeping this
   * for anyone who wants to mess around.
   *
   * @param item The mod you want to check.
   * @param seen The dependency list you already counted for, can be empty
   * @return Int The count of dependencies you do need for this mod.
   */
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

  /**
   * Counts how many mods that will move to the disabled list if you were to disable the item given.
   *
   *  NOTE: This can probably be used more efficiently but I'm having brain fog so I'm keeping this
   * for anyone who wants to mess around.
   *
   * @param item The mod you want to check.
   * @param seen The dependency list you already counted for, can be empty
   * @return Int The count of dependencies that will need to be removed with this mod.
   */
  public function countDisableBatch(item:ModMenuItem, seen:Array<String>):Int
  {
    if (item == null || item.mod == null) return 0;
    var id = item.getModId();
    if (seen.contains(id)) return 0;
    seen.push(id);

    var total:Int = 1; // this item
    for (depTitle in getEnabledDependencies(item.mod))
    {
      var depItem = enabledList.modItems.find((it) -> it.getModTitle() == depTitle);
      if (depItem != null) total += countDisableBatch(depItem, seen);
    }
    return total;
  }

  /**
   * Finds which index the item would need to go to when put through the enabled mod list.
   * It will look for any mod that's already enabled, and has an optional dependency on the item
   * being enabled, so if it finds one it will load the new mod BEFORE it!
   *
   * @param item The mod you want to check.
   * @return Int The index the item would need to go to.
   */
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

  /**
   * Check if reordering is allowed.
   * If the `Mod A` requires `Mod B` and/or `Mod B` optionally uses `Mod A`, reordering is blocked!
   * But, if reordering is going upwards, it will do the same checks but in reverse.
   *
   * @param item The mod you want to compare `other`.
   * @param other The other mod you want to compare with `item`.
   * @param moveUp Whether its moving upwards or not.
   * @return Bool Whether its being blocked or not.
   */
  public function isReorderBlocked(item:ModMenuItem, other:ModMenuItem, moveUp:Bool):Bool
  {
    if (moveUp) return requires(other, item) || optionallyUses(item, other);

    return requires(item, other) || optionallyUses(other, item);
  }

  /**
   * Check if the mod requires the other
   * @param mod The mod you want to check
   * @param dependency The other mod/dependency that might be required by `mod`.
   * @return Bool Whether its required or not.
   */
  function requires(mod:ModMenuItem, dependency:ModMenuItem):Bool
  {
    for (depId => version in mod.getDependencies())
    {
      if (dependency.getModId() == depId) return true;
    }
    return false;
  }

  /**
   * Check if the mod optionally uses the other
   * @param mod The mod you want to check
   * @param dependency The other mod/dependency that might be optionally used by `mod`.
   * @return Bool Whether its being optionally used or not.
   */
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

  /**
   * Check if the mod folder had any changes
   * @return Bool Whether it had changes or not
   */
  public function hasFolderChanged():Bool
  {
    var newItems:Array<String> = PolymodHandler.readModDirectory();
    return newItems.length != itemsInFolder.length;
  }

  /**
   * Syncs both of the lists with the mod folder, then returns two arrays of newly added disabled/enabled items.
   */
  public function syncWithDisk():
    {newDisabled:Array<ModMenuItem>, newEnabled:Array<ModMenuItem>}
  {
    PolymodHandler.getDisabledModsIncludingIncompatible(true);
    itemsInFolder = PolymodHandler.readModDirectory();

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

  /**
   * Syncs the disabled list with the mod folder.
   * @return Array<ModMenuItem> An array carrying the disabled items.
   */
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
      disabledList.addMod(item, disabledList.modItems.length);
      newItems.push(item);
    }

    return newItems;
  }

  /**
   * Syncs the enabled list with the mod folder.
   * @return Array<ModMenuItem> An array carrying the enabled items.
   */
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
      enabledList.addMod(item, enabledList.modItems.length);
      newItems.push(item);
    }

    // The base game mod is always in the enabled list, pinned to the top.
    if (!enabledList.modItems.exists((item) -> item.getModId() == ModMenuState.BASE_GAME_MOD_ID))
    {
      var baseGameItem = new ModMenuItem(null, ModMenuState.BASE_GAME_MOD_ICON_PATH, ModMenuState.BASE_GAME_MOD_ID, 'Base Game', 'Default game content');
      baseGameItem.locked = true;
      enabledList.addMod(baseGameItem, 0);
    }

    return newItems;
  }

  // MOVING MODS //

  /**
   * Enables the given mod.
   * @param item The mod you want to enable.
   * @param forcedInsertIndex If not -1, will insert that mod into the index at the list. Optional.
   * @param batchFutureCount The amount of mods (if there is any) the enabled list will hold, used for dependencies.
   * @param shouldUpdateSelection Whether to update the menu's selection after enabling it.
   * @return Bool Whether or not it was successfully enabled.
   */
  public function enable(item:Null<ModMenuItem>,
    ?forcedInsertIndex:Int = -1,
    ?batchFutureCount:Int = -1,
    shouldUpdateSelection:Bool = true):Bool
  {
    if (item == null) return false;
    if (!disabledList.modItems.contains(item)) return false;
    if (item.getModId() == ModMenuState.BASE_GAME_MOD_ID) return false;
    if (!PolymodHandler.isModCompatible(item.mod))
    {
      FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/menu-deny'), 0.7);
      item.flashBackground();
      return false;
    }

    item.selected = false;

    var dependenciesToEnable:Array<String> = getMissingDependencies(item.mod);
    trace(' MOD MENU '.bold().bg_orange() + ' Dependencies to enable for ${item.getModTitle()}: ${dependenciesToEnable}');

    // If there's no specified count, just look for it
    if (batchFutureCount == -1)
    {
      batchFutureCount = enabledList.modItems.length + countEnableBatch(item, []);
    }

    var insertIndex:Int = forcedInsertIndex;
    if (insertIndex == -1) insertIndex = findEnableInsertIndex(item);

    var nextInsertIndex = insertIndex;
    // Check if the dependencies are there or not, if not, YELL AT THEM! KILL THEM! ALL OF THEM!
    for (dependencyId in dependenciesToEnable)
    {
      var dependencyItem = disabledList.modItems.find((it) -> it.getModId() == dependencyId);
      if (dependencyItem != null)
      {
        enable(dependencyItem, nextInsertIndex, batchFutureCount, false);
        nextInsertIndex++;
      }
      else
      {
        WindowUtil.showError(
          'Missing dependency',
          'Could not find dependency mod with ID "${dependencyId}". Please make sure all required mods are installed.'
        );

        return false;
      }
    }

    var oldIndex:Int = flyBetweenLists(item, disabledList, enabledList, insertIndex, batchFutureCount);

    if (!shouldUpdateSelection) return true;

    if (disabledList.modItems.length > 0)
    {
      var newIndex:Int = Std.int(Math.min(oldIndex, disabledList.modItems.length - 1));
      enabledList.deselectAll();
      disabledList.selectModItem(disabledList.modItems[newIndex], false);
      setSelection(DisabledModList);
    }
    else
    {
      disabledList.deselectAll();
      enabledList.selectModItem(item, false);
      setSelection(EnabledModList);
    }

    return true;
  }

  /**
   * Disables the given mod.
   * @param item The mod you want to disable.
   * @param batchFutureCount The amount of mods (if there is any) the disabled list will hold, used for dependencies.
   * @param shouldUpdateSelection Whether to update the menu's selection after disabling it.
   */
  public function disable(item:Null<ModMenuItem>,
    ?batchFutureCount:Int = -1,
    shouldUpdateSelection:Bool = true):Void
  {
    if (item == null) return;

    if (!enabledList.modItems.contains(item)) return;
    if (enabledList.isPinnedItem(item) || item.locked) return;

    item.selected = false;

    // If there's no specified count, just look for it
    if (batchFutureCount == -1)
    {
      batchFutureCount = disabledList.modItems.length + countDisableBatch(item, []);
    }

    // Disable any mods that depend on this mod as well.
    var brokenDependencies = getEnabledDependencies(item.mod);
    trace(' MOD MENU '.bold().bg_orange() + ' Broken dependencies for ${item.getModTitle()}: ${brokenDependencies}');
    for (dependencyTitle in brokenDependencies)
    {
      var dependencyItem = enabledList.modItems.find((it) -> it.getModTitle() == dependencyTitle);
      if (dependencyItem != null)
      {
        trace(' MOD MENU '.bold().bg_orange() + ' Disabling ${dependencyItem.getModTitle()} since it depends on ${item.getModTitle()}');
        disable(dependencyItem, batchFutureCount, shouldUpdateSelection); // share denominator
      }
    }

    // Always insert at the top of the disabled list; order there doesn't matter.
    var oldIndex:Int = flyBetweenLists(item, enabledList, disabledList, disabledList.modItems.length, batchFutureCount);

    if (!shouldUpdateSelection) return;

    disabledList.selectModItem(item, false);

    if (enabledList.modItems.length > 0)
    {
      var newIndex:Int = Std.int(Math.min(oldIndex, enabledList.modItems.length - 1));
      enabledList.selectModItem(enabledList.modItems[newIndex], false);
      setSelection(EnabledModList);
    }
    else
    {
      setSelection(DisabledModList);
    }
  }

  /**
   * Transitions the given item from one item list to another.
   * @param item The mod to transition.
   * @param source The list its coming from.
   * @param dest The list its landing in.
   * @param insertIndex Which index will it land in.
   * @param batchFutureCount How many dependencies will follow along with it
   * @return Int The old index from the list it came from.
   */
  function flyBetweenLists(item:ModMenuItem, source:ModMenuItemList, dest:ModMenuItemList, insertIndex:Int, batchFutureCount:Int):Int
  {
    var oldIndex:Int = source.modItems.indexOf(item);
    var worldX:Float = source.x + ModMenuItemList.ITEM_X_OFFSET;
    var worldY:Float = source.y + source.getModItemYPos(oldIndex) + source.scrollOffset;
    source.removeModWithoutLayout(item);
    source.clampScrollToContent();

    // Checks if the item is in the transition group
    if (!(transitionLayer != null && transitionLayer.children.contains(item)))
    {
      putItemInTransitionLayer(item, worldX, worldY);
    }

    var finalIndex:Int = landingIndex(dest, insertIndex);
    var inFlight:Int = incomingCount(dest);

    dest.revealSlot(finalIndex, batchFutureCount);

    var targetX:Float = dest.x + ModMenuItemList.ITEM_X_OFFSET;
    var targetY:Float = dest.y + dest.getModItemYPosForCount(finalIndex, batchFutureCount) + dest.scrollOffset;

    dest.animateItemsToLayoutForInsertCount(finalIndex, inFlight + 1, LIST_REFLOW_DURATION, FlxEase.quartOut);
    source.animateItemsToLayout(LIST_REFLOW_DURATION, FlxEase.quartOut);
    startItemTransition(item, targetX, targetY, dest, finalIndex);

    return oldIndex;
  }

  /**
   * Nudges the blocked item, flair.
   * @param item The item thats gonna be nudgin'.
   * @param moveUp Whether to move it upwards or not.
   */
  function nudgeBlocked(item:ModMenuItem, moveUp:Bool):Void
  {
    var index:Int = enabledList.modItems.indexOf(item);
    if (index < 0) return;

    var restY:Float = enabledList.getModItemYPos(index) + enabledList.scrollOffset;

    item.cancelFlight();
    item.localX = ModMenuItemList.ITEM_X_OFFSET;
    item.localY = restY;

    var dir:Float = moveUp ? -1 : 1;
    item.startFlight(ModMenuItemList.ITEM_X_OFFSET, restY + dir * 14, 0.07, FlxEase.quadOut, () ->
    {
      item.startFlight(ModMenuItemList.ITEM_X_OFFSET, restY, 0.12, FlxEase.quadOut);
    });
  }

  /**
   * Re-orders the given mod upwards/downwards through the list.
   * @param item The item to re-order.
   * @param moveUp Whether we're moving up or not.
   */
  public function reorder(item:Null<ModMenuItem>, moveUp:Bool):Void
  {
    if (item == null) return;
    if (enabledList.isPinnedItem(item)) return;

    var modList:Array<ModMenuItem> = enabledList.modItems;
    var index = modList.indexOf(item);
    if (index == -1) return;

    var pinnedItem = enabledList.getPinnedTopItem();
    var pinnedIndex = pinnedItem != null ? modList.indexOf(pinnedItem) : -1;
    var minMovableIndex = pinnedIndex != -1 ? pinnedIndex + 1 : 0;

    if (index < minMovableIndex) return;
    if (minMovableIndex >= modList.length) return;

    var newIndex = moveUp ? index + 1 : index - 1;

    if (newIndex < minMovableIndex || newIndex >= modList.length)
    {
      nudgeBlocked(item, moveUp);
      return;
    }

    var otherModItem = modList[newIndex];

    var blocked:Bool = isReorderBlocked(item, otherModItem, moveUp);

    if (blocked)
    {
      trace(' MOD MENU '.bold().bg_orange() + ' Blocked reorder of ${item.getModTitle()} (dependency ordering)');
      nudgeBlocked(item, moveUp);
      return;
    }

    trace(' MOD MENU '.bold().bg_orange() + ' Moving mod ${item.getModTitle()} from index $index to $newIndex');

    modList.splice(index, 1);
    modList.insert(newIndex, item);

    enabledList.deselectAll();
    enabledList.selectModItem(item);
    enabledList.animateItemsToLayout(LIST_REFLOW_DURATION, FlxEase.quartOut);
  }

  // TRANSITIONS //

  /**
   * Creates the transition group and add it to the mod menu.
   * @param zIndex the zIndex we want to give it.
   */
  public function attachTransitionLayer(zIndex:Int):Void
  {
    if (ModMenuState.instance == null) return;

    transitionLayer = new FunkinSpriteGroup();
    transitionLayer.zIndex = zIndex;
    ModMenuState.instance.add(transitionLayer);
  }

  /**
   * Pulls the given item out of its list and puts it in the transition group, to well.. transition.
   * @param item The mod to move.
   * @param worldX The X Pos.
   * @param worldY The Y Pos.
   */
  public function putItemInTransitionLayer(item:ModMenuItem, worldX:Float, worldY:Float):Void
  {
    if (item == null || transitionLayer == null) return;

    enabledList.remove(item);
    disabledList.remove(item);
    if (transitionLayer.children.contains(item)) transitionLayer.remove(item);

    item.clipRect = null;
    transitionLayer.add(item);
    item.cancelFlight();
    item.localX = worldX - transitionLayer.x;
    item.localY = worldY - transitionLayer.y;
  }

  /**
   * Initializes the item's transition, by adding it to pending with its destined list and index.
   * @param item The item to transition.
   * @param targetX X pos.
   * @param targetY Y pos.
   * @param destinationList The list the item will land on.
   * @param index The index within the list the item will land on.
   */
  public function startItemTransition(item:ModMenuItem,
    targetX:Float,
    targetY:Float,
    destinationList:ModMenuItemList,
    index:Int):Void
  {
    if (item == null) return;

    var record:TransitionRecord = {
      item: item,
      dest: destinationList,
      index: index
    };
    pending.push(record);

    item.startFlight(targetX, targetY, FLIGHT_DURATION, FlxEase.quadOut, () -> completeTransition(record));
  }

  /**
   * Looks for the transition record within our currently pending array of transitions.
   * @param item The item you want to find the record for.
   * @return Null<TransitionRecord> The transition record (if there is any).
   */
  public function findTransition(item:ModMenuItem):Null<TransitionRecord>
  {
    for (record in pending)
    {
      if (record.item == item) return record;
    }
    return null;
  }

  /**
   * Completes the transition given.
   * @param record The TransitionRecord to complete.
   */
  public function completeTransition(record:TransitionRecord):Void
  {
    if (record == null) return;
    if (!pending.contains(record)) return;
    pending.remove(record);

    landInList(record.item, record.dest, record.index);
  }

  /**
   * Completes all of the transitions we have right now.
   */
  public function completeAllTransitions():Void
  {
    if (pending.length == 0) return;
    for (record in pending) record.item.finishFlight();
  }

  /**
   * Gets the amount of items going into the given list.
   * @param dest The list to check.
   * @return Int How many items are currently entering it.
   */
  public function incomingCount(dest:ModMenuItemList):Int
  {
    var count:Int = 0;
    for (record in pending)
    {
      if (record.dest == dest) count++;
    }
    return count;
  }

  /**
   * Gets the new index value to use for the given list once all the
   * transitioning items after the given index are done.
   * @param dest The list to check.
   * @param index The index we have.
   * @return Int The final index we'd have.
   */
  public function landingIndex(dest:ModMenuItemList, index:Int):Int
  {
    var finalIndex:Int = index;
    for (record in pending)
    {
      if (record.dest == dest && record.index <= finalIndex) finalIndex++;
    }
    return finalIndex;
  }

  /**
   * Lands the item inside the given list on the given index.
   * @param item The item to land.
   * @param destinationList The list to land in.
   * @param index The index within the list to land on.
   */
  function landInList(item:ModMenuItem,
    destinationList:ModMenuItemList,
    index:Int):Void
  {
    if (item == null || destinationList == null || transitionLayer == null) return;

    var worldX:Float = transitionLayer.x + item.localX;
    var worldY:Float = transitionLayer.y + item.localY;

    transitionLayer.remove(item);

    var clamped:Int = index;
    if (clamped > destinationList.modItems.length) clamped = destinationList.modItems.length;
    if (clamped < 0) clamped = 0;
    destinationList.addMod(item, clamped);

    item.cancelFlight();
    item.localX = worldX - destinationList.x;
    item.localY = worldY - destinationList.y;

    if (incomingCount(destinationList) == 0)
    {
      destinationList.repositionItems();
    }
    else
    {
      destinationList.updateScrollbar();
    }
  }

  // Getters / Helpers

  function get_hasTransitions():Bool
  {
    return pending.length > 0;
  }
}

/**
 * The record associated with the item currently transitioning.
 */
typedef TransitionRecord =
{
  // The actual item that is moving between lists.
  var item:ModMenuItem;
  // The destionation list it will land in.
  var dest:ModMenuItemList;
  // The index in the destination list that it will land at.
  var index:Int;
}
