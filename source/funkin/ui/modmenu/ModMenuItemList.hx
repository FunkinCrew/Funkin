package funkin.ui.modmenu;

import funkin.group.FunkinGroup;
import polymod.Polymod.ModMetadata;

class ModMenuItemList extends FunkinGroup<ModMenuItem>
{
  public var selectedModItem:Null<ModMenuItem> = null;
  public var selectedItemIndex(get, never):Int;
  public var pinnedTopModId:Null<String> = null;

  function get_selectedItemIndex():Int
  {
    if (selectedModItem == null) return -1;
    return this.children.indexOf(selectedModItem);
  }

  public function new()
  {
    super();
  }

  public function removeAll():Void
  {
    var pinnedItem = getPinnedTopItem();

    for (modMenuItem in this.children)
    {
      if (modMenuItem == pinnedItem) continue;
      this.remove(modMenuItem);
    }

    if (pinnedItem != null)
    {
      this.children = [pinnedItem];
      pinnedItem.localX = 0;
      pinnedItem.localY = getModItemYPos(0);
      selectedModItem = pinnedItem;
      pinnedItem.selected = true;
    }
    else
    {
      this.children = [];
      selectedModItem = null;
    }
  }

  public function deselectAll():Void
  {
    for (modMenuItem in this.children)
    {
      modMenuItem.selected = false;
    }
    selectedModItem = null;
  }

  public function removeMod(item:ModMenuItem):Void
  {
    if (!this.children.contains(item)) return;
    if (isPinnedItem(item)) return;

    this.remove(item);
    repositionItems();
  }

  public function addModRaw(item:ModMenuItem):Void
  {
    // Simply append to end; pinned item will stay at top via orderMod constraints
    this.add(item);

    var index = this.children.indexOf(item);
    item.localX = 0;
    item.localY = getModItemYPos(index);
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

    return this.children.find((item) -> item.getModId() == pinnedTopModId);
  }

  public function isPinnedItem(item:Null<ModMenuItem>):Bool
  {
    if (item == null) return false;
    if (pinnedTopModId == null) return false;

    return item.getModId() == pinnedTopModId;
  }

  public function selectFirstItem():Void
  {
    if (this.children.length == 0) return;
    selectModItem(this.children[this.children.length - 1]);
  }

  public function deselect():Void
  {
    selectModItem(null);
  }

  public function moveUp():Bool
  {
    var index = selectedItemIndex + 1;

    if (index >= this.children.length)
    {
      index = 0;
      return true;
    }

    selectModItem(this.children[index]);
    return true;
  }

  public function moveDown():Bool
  {
    var index = selectedItemIndex - 1;

    if (index < 0) index = children.length - 1;

    selectModItem(this.children[index]);
    return true;
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
  }

  public function repositionItems(reposition:Bool = true):Void
  {
    for (index => modMenuItem in this.children)
    {
      modMenuItem.localY = getModItemYPos(index);
    }

    if (selectedModItem != null && reposition)
    {
      selectFirstItem();
    }
  }

  function getModItemYPos(index:Int):Float
  {
    final BASE_HEIGHT:Float = 16;
    final ICON_HEIGHT:Float = 96;
    final ITEM_PADDING:Float = ICON_HEIGHT + 16;

    return BASE_HEIGHT + (ITEM_PADDING * (children.length - 1 - index));
  }
}
