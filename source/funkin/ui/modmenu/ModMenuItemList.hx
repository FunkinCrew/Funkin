package funkin.ui.modmenu;

import funkin.group.FunkinGroup.FunkinSpriteGroup;
import funkin.graphics.FunkinSprite;
import polymod.Polymod.ModMetadata;
import flixel.math.FlxRect;

class ModMenuItemList extends FunkinSpriteGroup
{
  public var selectedModItem:Null<ModMenuItem> = null;
  public var selectedItemIndex(get, never):Int;
  public var pinnedTopModId:Null<String> = null;
  // Separate array specifically typed to ModMenuItem
  public var modItems:Array<ModMenuItem>;

  public var viewportHeight:Float = 320;
  public var scrollOffset:Float = 0;

  function get_selectedItemIndex():Int
  {
    if (selectedModItem == null) return -1;
    return this.modItems.indexOf(selectedModItem);
  }

  public function new()
  {
    super();

    modItems = [];

    // default clip rect for the list viewport
    clipRect = FlxRect.get(0, 0, ModMenuItem.ITEM_WIDTH, viewportHeight);
  }

  public function removeAll():Void
  {
    var pinnedItem = getPinnedTopItem();

    // remove all mod items except pinned
    for (item in modItems.copy())
    {
      if (item == pinnedItem) continue;
      removeMod(item);
    }

    if (pinnedItem != null)
    {
      modItems = [pinnedItem];
      children = children.filter((c) -> Std.isOfType(c, ModMenuItem) && c == pinnedItem);
      pinnedItem.localX = 0;
      pinnedItem.localY = getModItemYPos(0) + scrollOffset;
      selectedModItem = pinnedItem;
      pinnedItem.selected = true;
    }
    else
    {
      children = children.filter((c) -> !Std.isOfType(c, ModMenuItem));
      modItems = [];
      selectedModItem = null;
    }
  }

  public function deselectAll():Void
  {
    for (modMenuItem in modItems)
    {
      modMenuItem.selected = false;
    }
    selectedModItem = null;
  }

  public function removeMod(item:ModMenuItem):Void
  {
    if (!modItems.contains(item)) return;
    if (isPinnedItem(item)) return;

    modItems.remove(item);
    this.remove(item);

    repositionItems();
  }

  public function addModRaw(item:ModMenuItem):Void
  {
    if (!modItems.contains(item))
    {
      super.add(item);
      modItems.push(item);
    }

    var index = modItems.indexOf(item);
    item.localX = 0;
    item.localY = getModItemYPos(index) + scrollOffset;
  }

  public function addMod(mod:ModMetadata):Void
  {
    var modMenuItem = new ModMenuItem(mod);
    addModRaw(modMenuItem);

    if (selectedModItem == null)
    {
      selectedModItem = modMenuItem;
      selectedModItem.selected = true;
    }
  }

  public function getPinnedTopItem():Null<ModMenuItem>
  {
    if (pinnedTopModId == null) return null;

    return this.modItems.find((item) -> item.getModId() == pinnedTopModId);
  }

  public function isPinnedItem(item:Null<ModMenuItem>):Bool
  {
    if (item == null) return false;
    if (pinnedTopModId == null) return false;

    return item.getModId() == pinnedTopModId;
  }

  public function selectFirstItem():Void
  {
    if (modItems.length == 0) return;
    selectModItem(modItems[modItems.length - 1]);
  }

  public function deselect():Void
  {
    selectModItem(null);
  }

  public function moveUp():Void
  {
    var index = selectedItemIndex + 1;

    if (index >= modItems.length) index = 0;

    selectModItem(modItems[index]);
  }

  public function moveDown():Void
  {
    var index = selectedItemIndex - 1;

    if (index < 0) index = modItems.length - 1;

    selectModItem(modItems[index]);
  }

  public function selectModItem(item:Null<ModMenuItem>):Void
  {
    if (selectedModItem != null) selectedModItem.selected = false;

    if (item == null) {
      selectedModItem = null;
      return;
    }

    selectedModItem = item;

    selectedModItem.selected = true;

    ensureItemVisible(selectedModItem);
  }

  public function repositionItems():Void
  {
    for (index => modMenuItem in modItems)
    {
      modMenuItem.localY = getModItemYPos(index) + scrollOffset;
    }
  }

  public function getModItemYPos(index:Int):Float
  {
    final ICON_HEIGHT:Float = 96;
    final ITEM_PADDING:Float = ICON_HEIGHT + 16;

    return (ITEM_PADDING * (modItems.length - 1 - index));
  }

  public function ensureItemVisible(item:ModMenuItem):Void
  {
    if (item == null) return;

    var index = modItems.indexOf(item);
    if (index < 0) return;

    var itemHeight = 96;
    var itemTop = getModItemYPos(index) + scrollOffset;
    var top = clipRect != null ? clipRect.y : 0;
    var bottom = clipRect != null ? clipRect.y + clipRect.height : viewportHeight;

    if (itemTop < top)
    {
      scrollOffset += (top - itemTop);
    }
    else if (itemTop + itemHeight > bottom)
    {
      scrollOffset -= (itemTop + itemHeight - bottom);
    }

    clampScroll();
    repositionItems();
  }

  function clampScroll():Void
  {
    var ICON_HEIGHT:Float = 96;
    var ITEM_PADDING:Float = ICON_HEIGHT + 16;
    var contentHeight = ITEM_PADDING * (modItems.length - 1) + ICON_HEIGHT;

    var minScroll:Float = Math.min(0, viewportHeight - contentHeight);
    var maxScroll:Float = 0;

    if (scrollOffset < minScroll) scrollOffset = minScroll;
    if (scrollOffset > maxScroll) scrollOffset = maxScroll;
  }

  public function scrollBy(delta:Float):Void
  {
    scrollOffset += delta;
    clampScroll();
    repositionItems();
  }
}
