package funkin.ui.modmenu;

import funkin.group.FunkinGroup.FunkinSpriteGroup;
import funkin.graphics.FunkinSprite;
import polymod.Polymod.ModMetadata;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class ModMenuItemList extends FunkinSpriteGroup
{
  public static var ITEM_X_OFFSET:Float = 40;
  public static var ITEM_Y_OFFSET:Float = 60;

  public static var SCROLLBAR_WIDTH:Float = 10;
  public static var SCROLLBAR_TOP_MARGIN:Float = -42;
  public static var SCROLLBAR_BOTTOM_MARGIN:Float = -60;
  public static var SCROLLBAR_MIN_THUMB:Float = 24;

  public static var SCROLLBAR_TRACK_COLOR:FlxColor = 0xFF3A393E;
  public static var SCROLLBAR_TRACK_ALPHA:Float = 0.6;
  public static var SCROLLBAR_THUMB_COLOR:FlxColor = 0xFF57565A;
  public static var SCROLLBAR_THUMB_ALPHA:Float = 0.95;

  public var selectedModItem:Null<ModMenuItem> = null;
  public var selectedItemIndex(get, never):Int;
  public var pinnedTopModId:Null<String> = null;
  // Separate array specifically typed to ModMenuItem
  public var modItems:Array<ModMenuItem>;

  public var title(default, set):String = "Disabled";
  public var titleText:FlxText;

  public var scrollbarTrack:FunkinSprite;
  public var scrollbarThumb:FunkinSprite;
  // Cache last built bitmap heights so we only regenerate graphics when they actually change.
  var lastTrackHeight:Int = -1;
  var lastThumbHeight:Int = -1;

  function set_title(value:String):String
  {
    titleText.text = value;
    return title;
  }

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

    titleText = new FlxText(0, 0);
    titleText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinLingLong', 'otf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER);

    scrollbarTrack = new FunkinSprite(0, 0);
    scrollbarTrack.makeGraphic(Std.int(SCROLLBAR_WIDTH), 1, SCROLLBAR_TRACK_COLOR);
    scrollbarTrack.alpha = SCROLLBAR_TRACK_ALPHA;
    scrollbarTrack.visible = false;

    scrollbarThumb = new FunkinSprite(0, 0);
    scrollbarThumb.makeGraphic(Std.int(SCROLLBAR_WIDTH), 1, SCROLLBAR_THUMB_COLOR);
    scrollbarThumb.alpha = SCROLLBAR_THUMB_ALPHA;
    scrollbarThumb.visible = false;

    updateScrollbar();
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
      children = children.filter((c) -> (Std.isOfType(c, ModMenuItem) && c == pinnedItem));
      pinnedItem.localX = ITEM_X_OFFSET;
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

    updateScrollbar();
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

  public function removeModWithoutLayout(item:ModMenuItem):Int
  {
    if (!modItems.contains(item)) return -1;
    if (isPinnedItem(item)) return -1;

    var index = modItems.indexOf(item);
    modItems.remove(item);
    this.remove(item);
    updateScrollbar();
    return index;
  }

  public function addModRaw(item:ModMenuItem):Void
  {
    if (!modItems.contains(item))
    {
      super.add(item);
      modItems.push(item);
    }

    var index = modItems.indexOf(item);
    item.localX = ITEM_X_OFFSET;
    item.localY = getModItemYPos(index) + scrollOffset;

    updateScrollbar();
  }

  public function addModRawWithoutLayout(item:ModMenuItem, index:Int = -1):Int
  {
    if (index < 0 || index > modItems.length) index = modItems.length;

    var existingIndex = modItems.indexOf(item);
    if (existingIndex != -1)
    {
      modItems.splice(existingIndex, 1);
      this.remove(item);
      if (existingIndex < index) index--;
    }

    modItems.insert(index, item);
    insert(item, index);
    updateScrollbar();
    return index;
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
    if (modItems.length == 0) return;

    var index = selectedItemIndex + 1;

    if (index >= modItems.length) index = 0;

    selectModItem(modItems[index], false);
    scrollBy(getScrollDeltaToReveal(selectedModItem));
  }

  public function moveDown():Void
  {
    if (modItems.length == 0) return;

    var index = selectedItemIndex - 1;

    if (index < 0) index = modItems.length - 1;

    selectModItem(modItems[index], false);
    scrollBy(getScrollDeltaToReveal(selectedModItem));
  }

  public function selectModItem(item:Null<ModMenuItem>, autoScroll:Bool = true):Void
  {
    if (selectedModItem != null) selectedModItem.selected = false;

    if (item == null) {
      selectedModItem = null;
      return;
    }

    selectedModItem = item;

    selectedModItem.selected = true;

    if (autoScroll) ensureItemVisible(selectedModItem);
  }

  public function repositionItems():Void
  {
    for (index => modMenuItem in modItems)
    {
      modMenuItem.localY = getModItemYPos(index) + scrollOffset;
      modMenuItem.localX = ITEM_X_OFFSET;
    }

    updateScrollbar();
  }

  public function animateItemsToLayout(duration:Float = 0.2, ?ease:EaseFunction = null, startDelay:Float = 0):Void
  {
    if (ease == null) ease = FlxEase.quadOut;
    for (index => modMenuItem in modItems)
    {
      if (modMenuItem == null || !modMenuItem.exists) continue;

      FlxTween.cancelTweensOf(modMenuItem);
      FlxTween.tween(modMenuItem, {
        localX: ITEM_X_OFFSET,
        localY: getModItemYPos(index) + scrollOffset
      }, duration, {ease: ease, startDelay: startDelay});
    }

    updateScrollbar();
  }

  public function animateItemsToLayoutForInsert(insertIndex:Int, duration:Float = 0.2, ?ease:EaseFunction = null, startDelay:Float = 0):Void
  {
    animateItemsToLayoutForInsertCount(insertIndex, 1, duration, ease, startDelay);
  }

  /**
   * Like animateItemsToLayoutForInsert, but makes room for `insertCount` items being
   * inserted starting at `insertIndex`.
   */
  public function animateItemsToLayoutForInsertCount(insertIndex:Int, insertCount:Int, duration:Float = 0.2, ?ease:EaseFunction = null, startDelay:Float = 0):Void
  {
    if (ease == null) ease = FlxEase.quadOut;
    if (insertCount < 1) insertCount = 1;

    var futureCount = modItems.length + insertCount;

    for (index => modMenuItem in modItems)
    {
      if (modMenuItem == null || !modMenuItem.exists) continue;

      var targetIndex = index;
      if (index >= insertIndex) targetIndex = index + insertCount;

      FlxTween.cancelTweensOf(modMenuItem);
      FlxTween.tween(modMenuItem, {
        localX: ITEM_X_OFFSET,
        localY: getModItemYPosForCount(targetIndex, futureCount) + scrollOffset
      }, duration, {ease: ease, startDelay: startDelay});
    }

    updateScrollbar();
  }

  public function applySwapScrollCorrection(changeIndex:Int, isInsertion:Bool):Void
  {
    var anchorIndex = getTopVisibleItemIndex();
    if (anchorIndex < 0) return;

    if (changeIndex > anchorIndex) return;

    final ITEM_PADDING:Float = 96 + 16;
    scrollOffset += isInsertion ? -ITEM_PADDING : ITEM_PADDING;
    clampScroll();
  }

  function getTopVisibleItemIndex():Int
  {
    var top:Float = getViewportTop();

    var index:Int = modItems.length - 1;
    while (index >= 0)
    {
      var item = modItems[index];
      if (item == null)
      {
        index--;
        continue;
      }

      if (item.localY + 96 > top) return index;

      index--;
    }

    return -1;
  }

  public function getModItemYPosForCount(index:Int, itemCount:Int):Float
  {
    final ICON_HEIGHT:Float = 96;
    final ITEM_PADDING:Float = ICON_HEIGHT + 16;

    return ITEM_Y_OFFSET + (ITEM_PADDING * (itemCount - 1 - index));
  }

  public function getModItemYPos(index:Int):Float
  {
    return getModItemYPosForCount(index, modItems.length);
  }

  /**
   * Top of the usable viewport, in the SAME local space the items use.
   */
  function getViewportTop():Float
  {
    return ITEM_Y_OFFSET;
  }

  /**
   * Bottom of the usable viewport in local space.
   */
  function getViewportBottom():Float
  {
    return clipRect != null ? clipRect.height : viewportHeight;
  }

  public function ensureItemVisible(item:ModMenuItem):Void
  {
    if (item == null) return;

    scrollBy(getScrollDeltaToReveal(item));
  }

  /**
   * Returns how much `scrollOffset` needs to change for `item` to sit fully
   * inside the viewport. Returns 0 when the item is already visible.
   */
  function getScrollDeltaToReveal(item:Null<ModMenuItem>):Float
  {
    if (item == null) return 0;

    var index = modItems.indexOf(item);
    if (index < 0) return 0;

    var itemHeight = 96;
    var itemTop = getModItemYPos(index) + scrollOffset;
    var top = getViewportTop();
    var bottom = getViewportBottom();

    if (itemTop < top) return (top - itemTop);
    if (itemTop + itemHeight > bottom) return -(itemTop + itemHeight - bottom);
    return 0;
  }

  function clampScroll(?itemCount:Int):Void
  {
    var count:Int = (itemCount != null) ? itemCount : modItems.length;

    var ICON_HEIGHT:Float = 96;
    var ITEM_PADDING:Float = ICON_HEIGHT + 16;
    var contentHeight = ITEM_PADDING * (count - 1) + ICON_HEIGHT;

    // Use the same viewport span as the scrollbar so the two never disagree.
    var viewSpan = getViewportBottom() - getViewportTop();

    var minScroll:Float = Math.min(0, viewSpan - contentHeight);
    var maxScroll:Float = 0;

    if (scrollOffset < minScroll) scrollOffset = minScroll;
    if (scrollOffset > maxScroll) scrollOffset = maxScroll;
  }

  /**
   * Adjusts scrollOffset so the item at `index` would be visible, assuming there are `itemCount` items in the list.
   * @param index
   * @param itemCount
   */
  public function revealSlot(index:Int, itemCount:Int):Void
  {
    var itemHeight = 96;
    var itemTop = getModItemYPosForCount(index, itemCount) + scrollOffset;
    var top = getViewportTop();
    var bottom = getViewportBottom();

    if (itemTop < top) scrollOffset += (top - itemTop);
    else if (itemTop + itemHeight > bottom) scrollOffset -= (itemTop + itemHeight - bottom);

    // Clamp against the FUTURE content size, since the incoming item isn't in modItems yet.
    clampScroll(itemCount);
    updateScrollbar();
  }

  public function scrollBy(delta:Float):Void
  {
    // Clamp first so the offset always respects the current content bounds.
    var oldOffset:Float = scrollOffset;
    scrollOffset += delta;
    clampScroll();

    // IMPORTANT: only re-layout when the scroll offset actually changed.
    // repositionItems() hard-sets every item's localX/localY, which instantly
    // kills any in-progress layout tween (e.g. the "slide up to fill the gap"
    // animation kicked off by animateItemsToLayout). Selecting an item that's
    // already on-screen produces a delta of 0; in that case there is nothing to
    // scroll, so we must NOT snap the items and stomp the running animation.
    if (scrollOffset == oldOffset) return;

    repositionItems();
  }

  /**
   * Sizes and positions the scrollbar based on the current content and viewport.
   * Hides it entirely when everything fits.
   */
  public function updateScrollbar():Void
  {
    if (scrollbarTrack == null || scrollbarThumb == null) return;

    var ICON_HEIGHT:Float = 96;
    var ITEM_PADDING:Float = ICON_HEIGHT + 16;
    var contentHeight = ITEM_PADDING * (modItems.length - 1) + ICON_HEIGHT;

    var viewTop:Float = getViewportTop();
    var viewBottom:Float = getViewportBottom();
    var viewSpan:Float = viewBottom - viewTop;

    var needsScroll = contentHeight > viewSpan;
    scrollbarTrack.visible = needsScroll;
    scrollbarThumb.visible = needsScroll;
    if (!needsScroll) return;

    var trackTop:Float = viewTop + SCROLLBAR_TOP_MARGIN;
    var trackBottom:Float = viewBottom - SCROLLBAR_BOTTOM_MARGIN;
    var trackHeight:Float = trackBottom - trackTop;
    if (trackHeight < 1) trackHeight = 1;

    var trackX:Float = (ITEM_X_OFFSET / 2) - (SCROLLBAR_WIDTH / 2);

    var thumbHeight:Float = trackHeight * (viewSpan / contentHeight);
    if (thumbHeight < SCROLLBAR_MIN_THUMB) thumbHeight = SCROLLBAR_MIN_THUMB;
    if (thumbHeight > trackHeight) thumbHeight = trackHeight;

    var minScroll:Float = Math.min(0, viewSpan - contentHeight);
    var frac:Float = (minScroll != 0) ? (scrollOffset / minScroll) : 0;
    if (frac < 0) frac = 0;
    if (frac > 1) frac = 1;

    var thumbY:Float = trackTop + frac * (trackHeight - thumbHeight);

    var trackH:Int = Std.int(trackHeight);
    if (trackH != lastTrackHeight)
    {
      scrollbarTrack.makeGraphic(Std.int(SCROLLBAR_WIDTH), trackH, SCROLLBAR_TRACK_COLOR);
      scrollbarTrack.alpha = SCROLLBAR_TRACK_ALPHA;
      lastTrackHeight = trackH;
    }

    var thumbH:Int = Std.int(thumbHeight);
    if (thumbH != lastThumbHeight)
    {
      scrollbarThumb.makeGraphic(Std.int(SCROLLBAR_WIDTH), thumbH, SCROLLBAR_THUMB_COLOR);
      scrollbarThumb.alpha = SCROLLBAR_THUMB_ALPHA;
      lastThumbHeight = thumbH;
    }

    scrollbarTrack.localX = trackX;
    scrollbarTrack.localY = trackTop;

    scrollbarThumb.localX = trackX;
    scrollbarThumb.localY = thumbY;

    scrollbarTrack.x = x + scrollbarTrack.localX;
    scrollbarTrack.y = y + scrollbarTrack.localY;
    scrollbarThumb.x = x + scrollbarThumb.localX;
    scrollbarThumb.y = y + scrollbarThumb.localY;
  }
}
