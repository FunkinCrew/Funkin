package funkin.ui.modmenu;

import flixel.tweens.FlxEase;
import funkin.audio.FunkinSound;
import funkin.modding.PolymodHandler;
import funkin.ui.modmenu.ModMenuState.ModMenuSelection;
import funkin.util.PromptUtil;

/**
 * Name WIP I dont like it.
 *
 * The controller is here, we got transitions too, and this class just guides things around.
 * Do I like it? Feels like doing too much... Might have to squash this with the other mod list classes
 * to make it simpler. Hmm.
 */
class ModListMover
{
  static inline final LIST_REFLOW_DURATION:Float = 0.28;

  final disabledList:ModMenuItemList;
  final enabledList:ModMenuItemList;
  final rules:ModListController;
  final transitions:ModMenuTransitions;
  final setSelection:ModMenuSelection->Void;

  public function new(disabledList:ModMenuItemList,
    enabledList:ModMenuItemList,
    rules:ModListController,
    transitions:ModMenuTransitions,
    setSelection:ModMenuSelection->Void)
  {
    this.disabledList = disabledList;
    this.enabledList = enabledList;
    this.rules = rules;
    this.transitions = transitions;
    this.setSelection = setSelection;
  }

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
      blockedIncompatible(item);
      return false;
    }

    item.selected = false;

    var dependenciesToEnable:Array<String> = rules.getMissingDependencies(item.mod);
    trace('Dependencies to enable for ${item.getModTitle()}: ${dependenciesToEnable}');

    if (batchFutureCount == -1)
    {
      batchFutureCount = enabledList.modItems.length + rules.countEnableBatch(item, []);
    }

    var insertIndex:Int = forcedInsertIndex;
    if (insertIndex == -1) insertIndex = rules.findEnableInsertIndex(item);

    var nextInsertIndex = insertIndex;
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
        PromptUtil.openPrompt({
          icon: 'warning',
          title: 'MISSING DEPENDENCY!',
          description: 'Could not find dependency mod with ID "${dependencyId}". Please make sure all required mods are installed.',
          buttons: [{
            text: 'Okay',
            defaultCancel: true
          }]
        }, [0, 50]);

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

  public function disable(item:Null<ModMenuItem>,
    ?batchFutureCount:Int = -1,
    shouldUpdateSelection:Bool = true):Void
  {
    if (item == null) return;

    if (!enabledList.modItems.contains(item)) return;
    if (enabledList.isPinnedItem(item) || item.locked) return;

    item.selected = false;

    if (batchFutureCount == -1)
    {
      batchFutureCount = disabledList.modItems.length + rules.countDisableBatch(item, []);
    }

    // Disable any mods that depend on this mod as well.
    var brokenDependencies = rules.getEnabledDependents(item.mod);
    trace('Broken dependencies for ${item.getModTitle()}: ${brokenDependencies}');
    for (dependencyTitle in brokenDependencies)
    {
      var dependencyItem = enabledList.modItems.find((it) -> it.getModTitle() == dependencyTitle);
      if (dependencyItem != null)
      {
        trace('Disabling ${dependencyItem.getModTitle()} since it depends on ${item.getModTitle()}');
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

  function flyBetweenLists(item:ModMenuItem, source:ModMenuItemList, dest:ModMenuItemList, insertIndex:Int, batchFutureCount:Int):Int
  {
    var oldIndex:Int = source.modItems.indexOf(item);
    var worldX:Float = source.x + ModMenuItemList.ITEM_X_OFFSET;
    var worldY:Float = source.y + source.getModItemYPos(oldIndex) + source.scrollOffset;
    source.removeModWithoutLayout(item);
    source.clampScrollToContent();

    if (!transitions.isInLayer(item))
    {
      transitions.moveToLayer(item, worldX, worldY);
    }

    var finalIndex:Int = transitions.landingIndex(dest, insertIndex);
    var inFlight:Int = transitions.incomingCount(dest);

    dest.revealSlot(finalIndex, batchFutureCount);

    var targetX:Float = dest.x + ModMenuItemList.ITEM_X_OFFSET;
    var targetY:Float = dest.y + dest.getModItemYPosForCount(finalIndex, batchFutureCount) + dest.scrollOffset;

    dest.animateItemsToLayoutForInsertCount(finalIndex, inFlight + 1, LIST_REFLOW_DURATION, FlxEase.quartOut);
    source.animateItemsToLayout(LIST_REFLOW_DURATION, FlxEase.quartOut);
    transitions.startFlight(item, targetX, targetY, dest, finalIndex);

    return oldIndex;
  }

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

  function blockedIncompatible(item:ModMenuItem):Void
  {
    FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/menu-deny'), 0.7);
    item.flashBackground();
  }

  public function reorder(modItem:Null<ModMenuItem>, moveUp:Bool):Void
  {
    if (modItem == null) return;
    if (enabledList.isPinnedItem(modItem)) return;

    var modList:Array<ModMenuItem> = enabledList.modItems;
    var index = modList.indexOf(modItem);
    if (index == -1) return;

    var pinnedItem = enabledList.getPinnedTopItem();
    var pinnedIndex = pinnedItem != null ? modList.indexOf(pinnedItem) : -1;
    var minMovableIndex = pinnedIndex != -1 ? pinnedIndex + 1 : 0;

    if (index < minMovableIndex) return;
    if (minMovableIndex >= modList.length) return;

    var newIndex = moveUp ? index + 1 : index - 1;

    if (newIndex < minMovableIndex || newIndex >= modList.length)
    {
      nudgeBlocked(modItem, moveUp);
      return;
    }

    var otherModItem = modList[newIndex];

    var blocked:Bool = rules.isReorderBlocked(modItem, otherModItem, moveUp);

    if (blocked)
    {
      trace('Blocked reorder of ${modItem.getModTitle()} (dependency ordering)');
      nudgeBlocked(modItem, moveUp);
      return;
    }

    trace('Moving mod ${modItem.getModTitle()} from index $index to $newIndex');

    modList.splice(index, 1);
    modList.insert(newIndex, modItem);

    enabledList.deselectAll();
    enabledList.selectModItem(modItem);
    enabledList.animateItemsToLayout(LIST_REFLOW_DURATION, FlxEase.quartOut);
  }
}
