package funkin.ui.modmenu;

import flixel.FlxState;
import flixel.tweens.FlxEase;
import funkin.group.FunkinGroup.FunkinSpriteGroup;

typedef TransitionRecord =
{
  var item:ModMenuItem;
  var dest:ModMenuItemList;
  var index:Int;
}

/**
 * Handles how the items fly and.. well "transition" between the two lists.
 * Each mid-transition item is tracked with a `TranitionRecord`, so an interrupting input can settle it early.
 */
class ModMenuTransitions
{
  static inline final FLIGHT_DURATION:Float = 0.2;

  public var layer(default, null):FunkinSpriteGroup;
  public var hasPending(get, never):Bool;

  function get_hasPending():Bool
  {
    return pending.length > 0;
  }

  final disabledList:ModMenuItemList;
  final enabledList:ModMenuItemList;
  final pending:Array<TransitionRecord> = [];

  public function new(disabledList:ModMenuItemList, enabledList:ModMenuItemList)
  {
    this.disabledList = disabledList;
    this.enabledList = enabledList;
  }

  /**
   * Creates the layer and adds it to the state.
   * @param zIndex Should be above the lists, so items fly over them.
   */
  public function attach(state:FlxState, zIndex:Int):Void
  {
    layer = new FunkinSpriteGroup();
    layer.zIndex = zIndex;
    state.add(layer);
  }

  public function isInLayer(item:ModMenuItem):Bool
  {
    return layer != null && layer.children.contains(item);
  }

  public function moveToLayer(item:ModMenuItem, worldX:Float, worldY:Float):Void
  {
    if (item == null || layer == null) return;

    enabledList.remove(item);
    disabledList.remove(item);
    if (layer.children.contains(item)) layer.remove(item);

    item.clipRect = null;
    layer.add(item);
    item.cancelFlight();
    item.localX = worldX - layer.x;
    item.localY = worldY - layer.y;
  }

  public function startFlight(item:ModMenuItem,
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

    item.startFlight(targetX, targetY, FLIGHT_DURATION, FlxEase.quadOut, () -> complete(record));
  }

  public function findRecord(item:ModMenuItem):Null<TransitionRecord>
  {
    for (record in pending)
    {
      if (record.item == item) return record;
    }
    return null;
  }

  public function complete(record:TransitionRecord):Void
  {
    if (record == null) return;
    if (!pending.contains(record)) return;
    pending.remove(record);

    landInList(record.item, record.dest, record.index);
  }

  public function completeAll():Void
  {
    if (pending.length == 0) return;
    for (record in pending.copy())
    {
      record.item.finishFlight();
    }
  }

  public function incomingCount(dest:ModMenuItemList):Int
  {
    var count:Int = 0;
    for (record in pending)
    {
      if (record.dest == dest) count++;
    }
    return count;
  }

  public function landingIndex(dest:ModMenuItemList, index:Int):Int
  {
    var finalIndex:Int = index;
    for (record in pending)
    {
      if (record.dest == dest && record.index <= finalIndex) finalIndex++;
    }
    return finalIndex;
  }

  function landInList(item:ModMenuItem,
    destinationList:ModMenuItemList,
    index:Int):Void
  {
    if (item == null || destinationList == null || layer == null) return;

    var worldX:Float = layer.x + item.localX;
    var worldY:Float = layer.y + item.localY;

    layer.remove(item);

    var clamped:Int = index;
    if (clamped > destinationList.modItems.length) clamped = destinationList.modItems.length;
    if (clamped < 0) clamped = 0;
    destinationList.addModRawWithoutLayout(item, clamped);

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
}
