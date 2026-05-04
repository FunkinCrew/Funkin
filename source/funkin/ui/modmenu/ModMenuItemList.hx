package funkin.ui.modmenu;

import funkin.group.FunkinGroup;
import funkin.group.FunkinGroup.FunkinSpriteGroup;
import funkin.modding.PolymodHandler;
import polymod.Polymod.ModMetadata;

class ModMenuItemList extends FunkinGroup<ModMenuItem>
{
  public var selectedModItem:Null<ModMenuItem> = null;
  public var selectedItemIndex(get, never):Int;

  function get_selectedItemIndex():Int
  {
    return this.children.indexOf(selectedModItem);
  }

  public function new()
  {
    super();
  }

  public function addMod(mod:ModMetadata):Void
  {
    trace('- ${mod.title} [${mod.id}]: ${mod.description}');

    var modMenuItem = new ModMenuItem(mod);
    this.add(modMenuItem);

    var index = this.children.indexOf(modMenuItem);
    modMenuItem.localX = 0;
    modMenuItem.localY = getModItemYPos(index);
  }

  public function selectFirstItem():Void
  {
    selectModItem(this.children[0]);
  }

  public function deselect():Void
  {
    selectModItem(null);
  }

  /**
   * If there is an item above the current selection, select that.
   * Otherwise, tell the menu to move outside the list.
   */
  public function moveUp():Bool
  {
    if (selectedItemIndex == 0)
    {
      deselect();

      return true;
    }

    selectModItem(this.children[selectedItemIndex - 1]);
    return false;
  }

  /**
   * If there is an item below the current selection, select that.
   * Otherwise, tell the menu to move outside the list.
   */
  public function moveDown():Bool
  {
    if (selectedItemIndex == this.children.length - 1)
    {
      deselect();

      return true;
    }

    selectModItem(this.children[selectedItemIndex + 1]);
    return false;
  }

  public function moveLeft():Void
  {
  }

  public function moveRight():Void
  {
  }

  public function onAccept():Void
  {
  }

  function selectModItem(item:Null<ModMenuItem>):Void
  {
    if (selectedModItem != null)
    {
      selectedModItem.selected = false;
    }

    selectedModItem = item;

    selectedModItem.selected = true;
  }

  function repositionItems():Void
  {
    for (index => modMenuItem in this.children)
    {
      modMenuItem.localY = getModItemYPos(index);
    }
  }

  function getModItemYPos(index:Int):Float
  {
    final BASE_HEIGHT:Float = 16;
    final ICON_HEIGHT:Float = 96;
    final ITEM_PADDING:Float = ICON_HEIGHT + 16;

    return BASE_HEIGHT + (ITEM_PADDING * index);
  }
}
