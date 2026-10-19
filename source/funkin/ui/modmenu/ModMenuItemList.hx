package funkin.ui.modmenu;

import funkin.group.FunkinGroup.FunkinSpriteGroup;
import funkin.graphics.FunkinSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import funkin.audio.FunkinSound;
import flixel.util.FlxDirection;

/**
 * The item list class for the two lists in mod menu.
 *
 * Items are stored bottom to top: index 0 is drawn at the BOTTOM and the last index at the top,
 * which is how mods stack in the load order. Anything called "first" or "top" in the selection
 * functions below is about what's on screen, so it's the LAST index.
 */
class ModMenuItemList extends FunkinSpriteGroup
{
  /**
   * The Y offset for items in the list.
   */
  public static var ITEM_X_OFFSET:Float = 40;

  /**
   * The Y offset for items in the list.
   */
  public static var ITEM_Y_OFFSET:Float = 60;

  /*
   * The value to lerp for the scroll bar.
   */
  public static var SCROLL_LERP:Float = 16;
  /*
   * The scrollbar's width.
   */
  public static var SCROLLBAR_WIDTH:Float = 10;
  /*
   * The scrollbar's top margin.
   */
  public static var SCROLLBAR_TOP_MARGIN:Float = -42;
  /*
   * The scrollbar's bottom margin.
   */
  public static var SCROLLBAR_BOTTOM_MARGIN:Float = -60;
  /*
   * The scrollbar's minimum thumb height.
   */
  public static var SCROLLBAR_MIN_THUMB:Float = 24;
  /*
   * The scrollbar's track color
   */
  public static var SCROLLBAR_TRACK_COLOR:FlxColor = 0xFF3A393E;
  /*
   * The scrollbar's track alpha
   */
  public static var SCROLLBAR_TRACK_ALPHA:Float = 0.6;
  /*
   * The scrollbar's thumb color
   */
  public static var SCROLLBAR_THUMB_COLOR:FlxColor = 0xFF57565A;
  /*
   * The scrollbar's thumb alpha
   */
  public static var SCROLLBAR_THUMB_ALPHA:Float = 0.95;

  /**
   * Whether items that are scrolled out of view are put to sleep, so they stop updating and drawing.
   * Turn this off to check that culling isn't the cause of something.
   */
  public static var CULL_OFFSCREEN_ITEMS:Bool = true;

  /**
   * Gap between two neighbouring items.
   */
  static inline final ITEM_GAP:Float = 16;

  /**
   * Distance between the tops of two neighbouring items.
   */
  static final ITEM_STRIDE:Float = ModMenuItem.ICON_HEIGHT + ITEM_GAP;

  /**
   * How far past the visible area items stay awake, so scrolling never reveals a "sleeping" item.
   * Do you think items snore too...
   */
  static final CULL_MARGIN:Float = ITEM_STRIDE * 2;

  /**
   * The selected item in this list.
   */
  public var selectedModItem:Null<ModMenuItem> = null;

  /**
   * The selected index in this list.
   */
  public var selectedItemIndex(get, never):Int;

  /**
   * The pinned top-most mod id in this list.
   */
  public var pinnedTopModId:Null<String> = null;

  /**
   * The mod menu items this list contains.
   */
  public var modItems:Array<ModMenuItem>;

  /**
   * The current title this list has.
   */
  public var title(default, set):String = "Disabled";

  /**
   * The title text associated with this list.
   */
  public var titleText:FlxText;

  /**
   * The scrollbar's track sprite.
   */
  public var scrollbarTrack:FunkinSprite;

  /**
   * The scrollbar's thumb sprite.
   */
  public var scrollbarThumb:FunkinSprite;

  /**
   * The viewport height for the list.
   */
  public var viewportHeight:Float = 320;

  /**
   * The scrolling display offset.
   */
  public var displayScrollOffset:Float = 0;

  var scrollAnimFrom:Float = 0;
  var scrollAnimTo:Float = 0;
  var scrollAnimTime:Float = 0;
  var scrollAnimDuration:Float = 0;

  /**
   * The scrolling offset.
   */
  public var scrollOffset:Float = 0;

  /**
   * The target scrolling offset.
   */
  public var targetScrollOffset:Float = 0;

  // Cache last built bitmap heights so we only regenerate graphics when they actually change.
  var lastTrackHeight:Int = -1;
  var lastThumbHeight:Int = -1;
  // What the scrollbar was last laid out for, so it's only redone when one of these changes.
  var lastScrollbarCount:Int = -1;
  var lastScrollbarOffset:Float = 0;
  var lastScrollbarBottom:Float = 0;
  var lastScrollbarX:Float = 0;
  var lastScrollbarY:Float = 0;

  /**
   * Creates a new instance of ModMenuItemList.
   */
  public function new()
  {
    super();

    modItems = [];

    titleText = new FlxText(0, 0);
    titleText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinLingLong', 'otf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER);

    scrollbarTrack = new FunkinSprite(0, 0);
    scrollbarTrack.makeGraphic(1, 1, SCROLLBAR_TRACK_COLOR);
    scrollbarTrack.alpha = SCROLLBAR_TRACK_ALPHA;
    scrollbarTrack.visible = false;
    scrollbarTrack.origin.set(0, 0);

    scrollbarThumb = new FunkinSprite(0, 0);
    scrollbarThumb.makeGraphic(1, 1, SCROLLBAR_THUMB_COLOR);
    scrollbarThumb.alpha = SCROLLBAR_THUMB_ALPHA;
    scrollbarThumb.visible = false;
    scrollbarThumb.origin.set(0, 0);

    updateScrollbar();
  }

  /**
   * Adds the elements to a Mod Menu instance.
   */
  public function addElements():Void
  {
    if (ModMenuState.instance == null) return;

    titleText.zIndex = this.zIndex + 1;
    scrollbarTrack.zIndex = titleText.zIndex + 1;
    scrollbarThumb.zIndex = scrollbarTrack.zIndex + 1;

    ModMenuState.instance.add(titleText);
    ModMenuState.instance.add(scrollbarTrack);
    ModMenuState.instance.add(scrollbarThumb);
  }

  override public function update(elapsed:Float):Void
  {
    // Before the group updates its items, so one that just started a flight is awake to fly.
    updateItemCulling();

    super.update(elapsed);

    updateScrollAnimation(elapsed);
    updateScrollFollow(elapsed);
  }

  // ADDING AND REMOVING //

  /**
   * Deselects all items within this list.
   */
  public function deselectAll():Void
  {
    for (modMenuItem in modItems)
    {
      modMenuItem.selected = false;
    }
    selectedModItem = null;
  }

  /**
   * Removes the given mod from this list.
   * @param item The mod to remove.
   */
  public function removeMod(item:ModMenuItem):Void
  {
    if (!modItems.contains(item)) return;
    if (isPinnedItem(item)) return;

    // It's leaving the list, so nothing will wake it up again.
    item.setOnScreen(true);

    modItems.remove(item);
    this.remove(item);

    repositionItems();
  }

  /**
   * Removes the given mod without repositioning items from this list.
   * @param item The mod to remove.
   */
  public function removeModWithoutLayout(item:ModMenuItem):Int
  {
    if (!modItems.contains(item)) return -1;
    if (isPinnedItem(item)) return -1;

    // It's leaving the list, so nothing will wake it up again.
    item.setOnScreen(true);

    var index = modItems.indexOf(item);
    modItems.remove(item);
    this.remove(item);
    updateScrollbar();
    return index;
  }

  /**
   * Adds the given mod into this list with the given index (if there is any).
   * @param item The mod to add.
   * @param index The index to insert it at. -1 for default.
   * @return Int The new index its at.
   */
  public function addMod(item:ModMenuItem, index:Int = -1):Int
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

  /**
   * Gets the pinned top-most item in this list
   * @return Null<ModMenuItem> The item.
   */
  public function getPinnedTopItem():Null<ModMenuItem>
  {
    if (pinnedTopModId == null) return null;

    return this.modItems.find((item) -> item.getModId() == pinnedTopModId);
  }

  /**
   * Checks if the given item is the top-most pinned item within this list.
   * @param item The item to check.
   * @return Bool Whether it is at the top or not.
   */
  public function isPinnedItem(item:Null<ModMenuItem>):Bool
  {
    if (item == null) return false;
    if (pinnedTopModId == null) return false;

    return item.getModId() == pinnedTopModId;
  }

  // SELECTION //

  /**
   * Selects the item at the top of the list, as seen on screen.
   * @param slideDir The sliding direction.
   */
  public function selectFirstItem(?slideDir:Null<FlxDirection>):Void
  {
    if (modItems.length == 0) return;
    selectModItem(modItems[modItems.length - 1], true, slideDir);
  }

  /**
   * Selects the item at the bottom of the list, as seen on screen.
   * @param slideDir The sliding direction
   */
  public function selectLastItem(?slideDir:Null<FlxDirection>):Void
  {
    if (modItems.length == 0) return;
    selectModItem(modItems[0], true, slideDir);
  }

  /**
   * Selects nothing within this list.
   */
  public function deselect():Void
  {
    selectModItem(null);
  }

  /**
   * Moves the current selection upwards/downwards depending on the step
   * @param step The amount of "steps" we take from the current selection.
   * @param allowWrap Whether to wrap the selection around or not.
   * @return Bool Whether the movement was successful or not.
   */
  public function moveSelectionBy(step:Int, allowWrap:Bool):Bool
  {
    if (modItems.length == 0) return true;

    var index = selectedItemIndex + step;

    if (index >= modItems.length)
    {
      if (!allowWrap) return false;
      index = 0;
    }
    else if (index < 0)
    {
      if (!allowWrap) return false;
      index = modItems.length - 1;
    }

    FunkinSound.playOnce(Paths.sound('ui/main-menu/scroll-menu'), 0.4);

    selectModItem(modItems[index], false, step > 0 ? FlxDirection.UP : FlxDirection.DOWN);
    scrollBy(getScrollDeltaToReveal(selectedModItem));
    return true;
  }

  /**
   * Selects the item at the given index.
   * @param index The index of the item we want to select.
   * @param slideDir Optional. The direction this input is coming from.
   */
  public function selectItem(index:Int, ?slideDir:Null<FlxDirection>):Void
  {
    if (index < 0 || index >= modItems.length) return;
    selectModItem(modItems[index], true, slideDir);
  }

  /**
   * Selects the given item.
   * @param item The item to select.
   * @param autoScroll Whether to scroll the list towards it or not.
   * @param slideDir Optional. The direction this input is coming from.
   */
  public function selectModItem(item:Null<ModMenuItem>, autoScroll:Bool = true, ?slideDir:Null<FlxDirection>):Void
  {
    if (selectedModItem != null) selectedModItem.selected = false;

    if (item == null)
    {
      selectedModItem = null;
      return;
    }

    selectedModItem = item;
    selectedModItem.selected = true;

    if (slideDir != null) selectedModItem.slideBackgroundFrom(slideDir);

    if (autoScroll) scrollBy(getScrollDeltaToReveal(selectedModItem));
  }

  // LAYOUT //

  /**
   * Repositions the items in this list.
   */
  public function repositionItems():Void
  {
    for (index => modMenuItem in modItems)
    {
      modMenuItem.cancelFlight();
      modMenuItem.localY = getModItemYPos(index) + scrollOffset;
      modMenuItem.localX = ITEM_X_OFFSET;
    }

    updateScrollbar();
  }

  /**
   * Animates the items into their proper layout in this list
   * @param duration The duration the flight would take.
   * @param ease Optional. Easing to use for the transition.
   */
  public function animateItemsToLayout(duration:Float = 0.2, ?ease:Float->Float = null):Void
  {
    if (ease == null) ease = FlxEase.quadOut;
    for (index => modMenuItem in modItems)
    {
      if (modMenuItem == null || !modMenuItem.exists) continue;
      modMenuItem.startFlight(ITEM_X_OFFSET, getModItemYPos(index) + scrollOffset, duration, ease);
    }

    updateScrollbar();
  }

  /**
   * Animates the items into the layout for inserting into this list.
   * @param insertIndex The index we'll start inserting at.
   * @param insertCount How many items we're making room for.
   * @param duration The length of the animation.
   * @param ease The ease
   */
  public function animateItemsToLayoutForInsertCount(insertIndex:Int, insertCount:Int, duration:Float = 0.2, ?ease:Float->Float = null):Void
  {
    if (ease == null) ease = FlxEase.quadOut;
    if (insertCount < 1) insertCount = 1;

    var futureCount = modItems.length + insertCount;

    for (index => modMenuItem in modItems)
    {
      if (modMenuItem == null || !modMenuItem.exists) continue;

      var targetIndex = index;
      if (index >= insertIndex) targetIndex = index + insertCount;

      modMenuItem.startFlight(ITEM_X_OFFSET, getModItemYPosForCount(targetIndex, futureCount) + scrollOffset, duration, ease);
    }

    updateScrollbar();
  }

  /**
   * Gets the mod item Y position at the given index if the given count is the list length.
   * @param index The index to calculate for
   * @param itemCount The item count we use to calculate.
   * @return Float The Y pos.
   */
  public function getModItemYPosForCount(index:Int, itemCount:Int):Float
  {
    return ITEM_Y_OFFSET + (ITEM_STRIDE * (itemCount - 1 - index));
  }

  /**
   * Gets the mod item Y pos at the given index.
   * @param index The index to check.
   * @return Float The Y pos
   */
  public function getModItemYPos(index:Int):Float
  {
    return getModItemYPosForCount(index, modItems.length);
  }

  /**
   * How tall all the items together are.
   * @param count The amount of items in the list.
   * @return Float The Y pos
   */
  function getContentHeight(count:Int):Float
  {
    return ITEM_STRIDE * (count - 1) + ModMenuItem.ICON_HEIGHT;
  }

  /**
   * The furthest `scrollOffset` can go.
   * @param count The amount of items in the list.
   * @return Float The distance it can go to.
   */
  function getMinScroll(count:Int):Float
  {
    var viewSpan = getViewportBottom() - ITEM_Y_OFFSET;

    return Math.min(0, viewSpan - getContentHeight(count));
  }

  // CULLING //

  /**
   * Puts the items that are out of view to "sleep", and wakes the ones that came back.
   * Items that are flying always stay "awake", since they have somewhere to be.
   */
  function updateItemCulling():Void
  {
    var top:Float = ITEM_Y_OFFSET;
    var bottom:Float = getViewportBottom();

    if (clipRect != null)
    {
      top = Math.min(top, clipRect.y - y);
      bottom = Math.max(bottom, clipRect.bottom - y);
    }

    top -= CULL_MARGIN;
    bottom += CULL_MARGIN;

    for (item in modItems)
    {
      var itemTop:Float = item.localY;

      item.setOnScreen(!CULL_OFFSCREEN_ITEMS || item.isInFlight || (itemTop + ModMenuItem.ICON_HEIGHT > top && itemTop < bottom));
    }
  }

  // SCROLLING //

  /**
   * Animates the scrolling.
   * @param from The position the scroll is coming from.
   * @param duration The duration of the animation
   */
  public function animateScrollFrom(from:Float, duration:Float = 0.28):Void
  {
    if (from == scrollOffset || duration <= 0)
    {
      scrollAnimDuration = 0;
      displayScrollOffset = scrollOffset;
      return;
    }

    scrollAnimFrom = from;
    scrollAnimTo = scrollOffset;
    scrollAnimTime = 0;
    scrollAnimDuration = duration;
    displayScrollOffset = from;
  }

  /**
   * Plays the eased scrolling.
   * @param Elapsed elapsed
   */
  function updateScrollAnimation(elapsed:Float):Void
  {
    if (scrollAnimDuration <= 0) return;

    scrollAnimTime += elapsed;
    var t = Math.min(1, scrollAnimTime / scrollAnimDuration);
    displayScrollOffset = scrollAnimFrom + (scrollAnimTo - scrollAnimFrom) * FlxEase.quartOut(t);
    if (t >= 1) scrollAnimDuration = 0;
    updateScrollbar();
  }

  /**
   * Eases `scrollOffset` towards `targetScrollOffset`, moving the items along with it.
   * @param elapsed Elapsed
   */
  function updateScrollFollow(elapsed:Float):Void
  {
    if (scrollOffset == targetScrollOffset) return;

    if (Math.abs(targetScrollOffset - scrollOffset) > 0.1)
    {
      var t = Math.min(1, SCROLL_LERP * elapsed);
      scrollOffset += (targetScrollOffset - scrollOffset) * t;
    }
    else
    {
      scrollOffset = targetScrollOffset;
    }

    if (scrollAnimDuration <= 0) displayScrollOffset = scrollOffset;
    repositionItems();
  }

  /**
   * Bottom of the usable viewport in local space.
   * @return Float the viewport bottom.
   */
  function getViewportBottom():Float
  {
    return clipRect != null ? clipRect.height : viewportHeight;
  }

  /**
   * Returns how much `scrollOffset` needs to change for the given mod to sit fully
   * inside the viewport. Returns 0 when the item is already visible.
   * @param item The mod to check for.
   * @return Float How much the offset needs to change
   */
  function getScrollDeltaToReveal(item:Null<ModMenuItem>):Float
  {
    if (item == null) return 0;

    var index = modItems.indexOf(item);
    if (index < 0) return 0;

    var itemTop = getModItemYPos(index) + scrollOffset;
    var top = ITEM_Y_OFFSET;
    var bottom = getViewportBottom();

    if (itemTop < top) return (top - itemTop);
    if (itemTop + ModMenuItem.ICON_HEIGHT > bottom) return -(itemTop + ModMenuItem.ICON_HEIGHT - bottom);
    return 0;
  }

  /**
   * Clamps the target scroll offset between 0 and the given count (list length if there isn't any)
   * @param itemCount Optional. How many items to account for in thist list.
   */
  function clampScroll(?itemCount:Int):Void
  {
    var count:Int = (itemCount != null) ? itemCount : modItems.length;

    var minScroll:Float = getMinScroll(count);
    var maxScroll:Float = 0;

    if (targetScrollOffset < minScroll) targetScrollOffset = minScroll;
    if (targetScrollOffset > maxScroll) targetScrollOffset = maxScroll;
  }

  /**
   * Adjusts scrollOffset and takes into account the given
   * item count so the item at the given index would be visible
   * @param index The index to check.
   * @param itemCount The count of items we want to calculate with.
   */
  public function revealSlot(index:Int, itemCount:Int):Void
  {
    var previousScroll:Float = scrollOffset;

    var itemTop = getModItemYPosForCount(index, itemCount) + scrollOffset;
    var top = ITEM_Y_OFFSET;
    var bottom = getViewportBottom();

    if (itemTop < top) scrollOffset += (top - itemTop);
    else if (itemTop + ModMenuItem.ICON_HEIGHT > bottom) scrollOffset -= (itemTop + ModMenuItem.ICON_HEIGHT - bottom);

    targetScrollOffset = scrollOffset;
    clampScroll(itemCount);
    scrollOffset = targetScrollOffset;

    animateScrollFrom(previousScroll);
    updateScrollbar();
  }

  /**
   * Clamps the scroll to the content in this list
   */
  public function clampScrollToContent():Void
  {
    targetScrollOffset = scrollOffset;
    clampScroll();
    scrollOffset = targetScrollOffset;
  }

  /**
   * Scrolls by with the given amount.
   * @param delta How much we move.
   */
  public function scrollBy(delta:Float):Void
  {
    targetScrollOffset += delta;
    clampScroll();
  }

  /**
   * Snaps the scrolling to finish its course earlier.
   */
  public function snapScroll():Void
  {
    scrollOffset = targetScrollOffset;
    repositionItems();
  }

  /**
   * Sizes and positions the scrollbar based on the current content and viewport.
   * Hides it entirely when everything fits.
   */
  public function updateScrollbar():Void
  {
    if (scrollbarTrack == null || scrollbarThumb == null) return;

    var viewTop:Float = ITEM_Y_OFFSET;
    var viewBottom:Float = getViewportBottom();

    // Nothing the scrollbar depends on changed, so it's already right.
    // We dont want to calculate anything useless now
    if (
      modItems.length == lastScrollbarCount
      && displayScrollOffset == lastScrollbarOffset
      && viewBottom == lastScrollbarBottom
      && x == lastScrollbarX
      && y == lastScrollbarY
    ) return;

    lastScrollbarCount = modItems.length;
    lastScrollbarOffset = displayScrollOffset;
    lastScrollbarBottom = viewBottom;
    lastScrollbarX = x;
    lastScrollbarY = y;

    var contentHeight = getContentHeight(modItems.length);
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

    var minScroll:Float = getMinScroll(modItems.length);
    var frac:Float = (minScroll != 0) ? (displayScrollOffset / minScroll) : 0;
    if (frac < 0) frac = 0;
    if (frac > 1) frac = 1;

    var thumbY:Float = trackTop + frac * (trackHeight - thumbHeight);

    var trackH:Int = Std.int(trackHeight);
    if (trackH != lastTrackHeight)
    {
      scrollbarTrack.scale.set(SCROLLBAR_WIDTH, trackH);
      lastTrackHeight = trackH;
    }

    var thumbH:Int = Std.int(thumbHeight);
    if (thumbH != lastThumbHeight)
    {
      scrollbarThumb.scale.set(SCROLLBAR_WIDTH, thumbH);
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

  // Setters / helpers

  function set_title(value:String):String
  {
    titleText.text = value;
    title = value;
    return title;
  }

  function get_selectedItemIndex():Int
  {
    if (selectedModItem == null) return -1;
    return this.modItems.indexOf(selectedModItem);
  }
}
