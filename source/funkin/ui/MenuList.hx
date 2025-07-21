package funkin.ui;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.audio.FunkinSound;
import funkin.util.TouchUtil;
import funkin.util.SwipeUtil;
import funkin.ui.Page.PageName;
import flixel.tweens.FlxEase;
import funkin.util.HapticUtil;
import flixel.tweens.FlxTween;

@:nullSafety
class MenuTypedList<T:MenuListItem> extends FlxTypedGroup<T>
{
  // Pause input variable
  public static var pauseInput:Bool = false;

  public var selectedIndex(default, null):Int = 0;
  public var selectedItem(get, never):T;

  /** Called when a new item is highlighted */
  public var onChange(default, null) = new FlxTypedSignal<T->Void>();

  /** Called when an item is accepted */
  public var onAcceptPress(default, null) = new FlxTypedSignal<T->Void>();

  /** The navigation control scheme to use */
  public var navControls:NavControls;

  /** Set to false to disable nav control */
  public var enabled:Bool = true;

  /**  */
  public var wrapMode:WrapMode = Both;

  var byName = new Map<String, T>();

  /** Set to true, internally to disable controls, without affecting vars like `enabled` */
  public var busy:Bool = false;

  // bit awkward because BACK is also a menu control and this doesn't affect that
  // #if mobile

  /** touchBuddy over here helps with the touch input! Because overlap for touch does not account for the graphic, only the hitbox.
   * And, `FlxG.pixelPerfectOverlap` uses two FlxSprites, so we can't use the `FlxTouch` object */
  public var touchBuddy:FlxSprite;

  // #end

  /** Only used in Options, basically acts the same as OptionsState's `currentName`, it's the current name of the current page in OptionsState.
   * Why is it needed? Because touch control's a bitch. Thats why. */
  public var currentPage:Null<PageName>;

  // Helper variable
  var _isMainMenuState:Bool = false;

  public function new(navControls:NavControls = Vertical, ?wrapMode:WrapMode)
  {
    this.navControls = navControls;

    if (wrapMode != null) this.wrapMode = wrapMode;
    else
    {
      this.wrapMode = switch (navControls)
      {
        case Horizontal: Horizontal;
        case Vertical: Vertical;
        default: Both;
      }
    }

    touchBuddy = new FlxSprite().makeGraphic(10, 10);
    _isMainMenuState = Std.isOfType(FlxG.state, funkin.ui.mainmenu.MainMenuState);

    super();
  }

  public function addItem(name:String, item:T):T
  {
    if (length == selectedIndex) item.select();

    byName[name] = item;
    return add(item);
  }

  public function resetItem(oldName:String, newName:String, ?callback:Void->Void):Null<T>
  {
    var item = byName[oldName];
    if (item == null) throw 'No item named: $oldName';
    byName.remove(oldName);
    byName[newName] = item;
    item.setItem(newName, callback);

    return item;
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (enabled && !busy && !pauseInput) updateControls();
  }

  inline function updateControls():Void
  {
    var controls = PlayerSettings.player1.controls;

    var wrapX = wrapMode.match(Horizontal | Both);
    var wrapY = wrapMode.match(Vertical | Both);

    var newIndex = 0;

    // Define unified input handlers
    final inputUp:Bool = controls.UI_UP_P || (!_isMainMenuState && SwipeUtil.swipeUp);
    final inputDown:Bool = controls.UI_DOWN_P || (!_isMainMenuState && SwipeUtil.swipeDown);
    final inputLeft:Bool = controls.UI_LEFT_P || (!_isMainMenuState && SwipeUtil.swipeLeft);
    final inputRight:Bool = controls.UI_RIGHT_P || (!_isMainMenuState && SwipeUtil.swipeRight);

    // Keepin' these for keyboard/controller support on mobile platforms
    newIndex = switch (navControls)
    {
      case Vertical: navList(inputUp, inputDown, wrapY);
      case Horizontal: navList(inputLeft, inputRight, wrapX);
      case Both: navList(inputLeft || inputUp, inputRight || inputDown, !wrapMode.match(None));

      case Columns(num): navGrid(num, inputLeft, inputRight, wrapX, inputUp, inputDown, wrapY);
      case Rows(num): navGrid(num, inputUp, inputDown, wrapY, inputLeft, inputRight, wrapX);
    };

    #if FEATURE_TOUCH_CONTROLS
    // Update touch position
    if (TouchUtil.pressed)
    {
      touchBuddy.setPosition(TouchUtil.touch.x, TouchUtil.touch.y);
    }

    if (funkin.mobile.input.ControlsHandler.usingExternalInputDevice)
    {
      if (newIndex != selectedIndex)
      {
        FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
        selectItem(newIndex);
      }
    }
    else if (TouchUtil.pressed)
    {
      for (i in 0...members.length)
      {
        final item = members[i];
        final menuCamera = FlxG.cameras.list[1];

        final itemOverlaps:Bool = !_isMainMenuState && TouchUtil.overlaps(item, menuCamera);
        final itemPixelOverlap:Bool = _isMainMenuState && FlxG.pixelPerfectOverlap(touchBuddy, item, 0);

        final isTouchingItem:Bool = itemOverlaps || itemPixelOverlap;

        if (item.available && isTouchingItem && TouchUtil.justPressed)
        {
          var prevIndex:Int = selectedIndex;

          if (!_isMainMenuState && selectedIndex != i)
          {
            newIndex = i;
            break;
          }
          else
          {
            FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
            selectItem(i);
          }

          if (_isMainMenuState)
          {
            if (prevIndex == i)
            {
              FlxTween.cancelTweensOf(item);
              item.scale.set(1.1, 1.1);
              FlxTween.tween(item.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});

              HapticUtil.vibrate(0, 0.05, 1);
              accept();
            }
            else
            {
              FlxTween.cancelTweensOf(item);
              item.scale.set(0.94, 0.94);
              FlxTween.tween(item.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.backOut});

              HapticUtil.vibrate(0, 0.01, 0.5);
            }
          }
          else
          {
            accept();
          }

          break;
        }
      }
    }

    if (newIndex != selectedIndex && !_isMainMenuState)
    {
      FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
      selectItem(newIndex);
    }
    #else
    if (newIndex != selectedIndex)
    {
      FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
      selectItem(newIndex);
    }
    #end

    // Todo: bypass popup blocker on firefox
    if (controls.ACCEPT) accept();

    return;
  }

  function navAxis(index:Int, size:Int, prev:Bool, next:Bool, allowWrap:Bool):Int
  {
    if (prev == next) return index;

    if (prev)
    {
      if (index > 0) index--;
      else if (allowWrap) index = size - 1;
    }
    else
    {
      if (index < size - 1) index++;
      else if (allowWrap) index = 0;
    }

    return index;
  }

  /**
   * Controls navigation on a linear list of items such as Vertical.
   * @param prev
   * @param next
   * @param allowWrap
   */
  inline function navList(prev:Bool, next:Bool, allowWrap:Bool)
  {
    return navAxis(selectedIndex, length, prev, next, allowWrap);
  }

  /**
   * Controls navigation on a grid
   * @param latSize   The size of the fixed axis of the grid, or the "lateral axis"
   * @param latPrev   Whether the 'prev' key is pressed along the fixed-lengthed axis. eg: "left" in Column mode
   * @param latNext   Whether the 'next' key is pressed along the fixed-lengthed axis. eg: "right" in Column mode
   * @param prev      Whether the 'prev' key is pressed along the variable-lengthed axis. eg: "up" in Column mode
   * @param next      Whether the 'next' key is pressed along the variable-lengthed axis. eg: "down" in Column mode
   * @param allowWrap unused
   */
  function navGrid(latSize:Int, latPrev:Bool, latNext:Bool, latAllowWrap:Bool, prev:Bool, next:Bool, allowWrap:Bool):Int
  {
    // The grid length along the variable-length axis
    var size = Math.ceil(length / latSize);
    // The selected position along the variable-length axis
    var index = Math.floor(selectedIndex / latSize);
    // The selected position along the fixed axis
    var latIndex = selectedIndex % latSize;

    latIndex = navAxis(latIndex, latSize, latPrev, latNext, latAllowWrap);
    index = navAxis(index, size, prev, next, allowWrap);

    return Std.int(Math.min(length - 1, index * latSize + latIndex));
  }

  public function accept():Void
  {
    var selected = members[selectedIndex];

    if (!selected.available) return;

    onAcceptPress.dispatch(selected);

    if (selected.fireInstantly) selected.callback();
    else
    {
      busy = true;
      FunkinSound.playOnce(Paths.sound('confirmMenu'));
      FlxFlicker.flicker(selected, 1, 0.06, true, false, function(_) {
        busy = false;
        selected.callback();
      });
    }
  }

  public function cancelAccept()
  {
    FlxFlicker.stopFlickering(members[selectedIndex]);
    busy = false;
  }

  /**
   * Selects an item in the list. If the item is not available, it will select the next available item.
   * @param index The index of the item to select.
   */
  public function selectItem(index:Int):Void
  {
    members[selectedIndex].idle();

    if (!members[index].available)
    {
      if (index < selectedIndex)
      {
        final newIndex:Int = (index - 1 < 0) ? index + 1 : index - 1;
        selectItem(newIndex);
        return;
      }
      else if (index > selectedIndex)
      {
        final newIndex:Int = (index + 1 > members.length) ? index - 1 : index + 1;
        selectItem(newIndex);
        return;
      }
    }

    selectedIndex = index;

    var selected = members[selectedIndex];
    selected.select();
    onChange.dispatch(selected);
  }

  public function has(name:String)
  {
    return byName.exists(name);
  }

  public function getItem(name:String)
  {
    return byName[name];
  }

  override function destroy()
  {
    super.destroy();
    byName.clear();
    onChange.removeAll();
    onAcceptPress.removeAll();
  }

  inline function get_selectedItem():T
  {
    return members[selectedIndex];
  }
}

@:nullSafety
class MenuListItem extends FlxSprite
{
  public var callback:Void->Void;
  public var name:String;
  public var available:Bool;

  /**
   * Set to true for things like opening URLs otherwise, it may it get blocked.
   */
  public var fireInstantly = false;

  public var selected(get, never):Bool;

  function get_selected()
    return alpha == 1.0;

  public function new(x = 0.0, y = 0.0, name:String, callback, available:Bool = true)
  {
    super(x, y);

    // This is just here to satisfy the null-safety checker
    // setData still needs to be called since other classes may override it
    this.name = name;
    this.callback = callback;
    this.available = available;
    setData(name, callback, available);
    idle();
  }

  function setData(name:String, ?callback:Void->Void, available:Bool)
  {
    this.name = name;

    if (callback != null) this.callback = callback;

    this.available = available;
  }

  /**
   * Calls setData and resets/redraws the state of the item
   * @param name      the label.
   * @param callback  Unchanged if null.
   */
  public function setItem(name:String, ?callback:Void->Void)
  {
    setData(name, callback, available);

    if (selected) select();
    else
      idle();
  }

  public function idle()
  {
    alpha = 0.6;
  }

  public function select()
  {
    alpha = 1.0;
  }
}

@:nullSafety
class MenuTypedItem<T:FlxSprite> extends MenuListItem
{
  public var label(default, set):Null<T>;

  public function new(x = 0.0, y = 0.0, label:T, name:String, callback, available:Bool = true)
  {
    super(x, y, name, callback, available);
    // set label after super otherwise setters fuck up
    this.label = label;
  }

  /**
   * Use this when you only want to show the label
   */
  public function setEmptyBackground()
  {
    var oldWidth = width;
    var oldHeight = height;
    makeGraphic(1, 1, 0x0);
    width = oldWidth;
    height = oldHeight;
  }

  function set_label(value:Null<T>):Null<T>
  {
    if (value != null)
    {
      value.x = x;
      value.y = y;
      value.alpha = alpha;
    }
    return this.label = value;
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);
    if (label != null) label.update(elapsed);
  }

  override function draw()
  {
    super.draw();
    if (label != null)
    {
      label.cameras = cameras;
      label.scrollFactor.copyFrom(scrollFactor);
      label.draw();
    }
  }

  override function set_alpha(value:Float):Float
  {
    super.set_alpha(value);

    if (label != null) label.alpha = alpha;

    return alpha;
  }

  override function set_x(value:Float):Float
  {
    super.set_x(value);

    if (label != null) label.x = x;

    return x;
  }

  override function set_y(Value:Float):Float
  {
    super.set_y(Value);

    if (label != null) label.y = y;

    return y;
  }
}

enum NavControls
{
  Horizontal;
  Vertical;
  Both;
  Columns(num:Int);
  Rows(num:Int);
}

enum WrapMode
{
  Horizontal;
  Vertical;
  Both;
  None;
}
