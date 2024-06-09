package funkin.ui;

import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxSignal;
import funkin.audio.FunkinSound;

class MenuTypedList<T:MenuListItem> extends FlxTypedGroup<T>
{
  public var selectedIndex(default, null) = 0;
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
  public var busy(default, null):Bool = false;

  // bit awkward because BACK is also a menu control and this doesn't affect that

  public function new(navControls:NavControls = Vertical, ?wrapMode:WrapMode)
  {
    this.navControls = navControls;

    if (wrapMode != null) this.wrapMode = wrapMode;
    else
      this.wrapMode = switch (navControls)
      {
        case Horizontal: Horizontal;
        case Vertical: Vertical;
        default: Both;
      }
    super();
  }

  public function addItem(name:String, item:T):T
  {
    if (length == selectedIndex) item.select();

    byName[name] = item;
    return add(item);
  }

  public function resetItem(oldName:String, newName:String, ?callback:Void->Void):T
  {
    if (!byName.exists(oldName)) throw "No item named:" + oldName;

    var item = byName[oldName];
    byName.remove(oldName);
    byName[newName] = item;
    item.setItem(newName, callback);

    return item;
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (enabled && !busy) updateControls();
  }

  inline function updateControls()
  {
    var controls = PlayerSettings.player1.controls;

    var wrapX = wrapMode.match(Horizontal | Both);
    var wrapY = wrapMode.match(Vertical | Both);
    var newIndex = switch (navControls)
    {
      case Vertical: navList(controls.UI_UP_P, controls.UI_DOWN_P, wrapY);
      case Horizontal: navList(controls.UI_LEFT_P, controls.UI_RIGHT_P, wrapX);
      case Both: navList(controls.UI_LEFT_P || controls.UI_UP_P, controls.UI_RIGHT_P || controls.UI_DOWN_P, !wrapMode.match(None));

      case Columns(num): navGrid(num, controls.UI_LEFT_P, controls.UI_RIGHT_P, wrapX, controls.UI_UP_P, controls.UI_DOWN_P, wrapY);
      case Rows(num): navGrid(num, controls.UI_UP_P, controls.UI_DOWN_P, wrapY, controls.UI_LEFT_P, controls.UI_RIGHT_P, wrapX);
    }

    if (newIndex != selectedIndex)
    {
      FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
      selectItem(newIndex);
    }

    // Todo: bypass popup blocker on firefox
    if (controls.ACCEPT) accept();
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

  public function accept()
  {
    var selected = members[selectedIndex];
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

  public function selectItem(index:Int)
  {
    members[selectedIndex].idle();

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

class MenuListItem extends FlxSprite
{
  public var callback:Void->Void;
  public var name:String;

  /**
   * Set to true for things like opening URLs otherwise, it may it get blocked.
   */
  public var fireInstantly = false;

  public var selected(get, never):Bool;

  function get_selected()
    return alpha == 1.0;

  public function new(x = 0.0, y = 0.0, name:String, callback)
  {
    super(x, y);

    setData(name, callback);
    idle();
  }

  function setData(name:String, ?callback:Void->Void)
  {
    this.name = name;

    if (callback != null) this.callback = callback;
  }

  /**
   * Calls setData and resets/redraws the state of the item
   * @param name      the label.
   * @param callback  Unchanged if null.
   */
  public function setItem(name:String, ?callback:Void->Void)
  {
    setData(name, callback);

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

class MenuTypedItem<T:FlxSprite> extends MenuListItem
{
  public var label(default, set):T;

  public function new(x = 0.0, y = 0.0, label:T, name:String, callback)
  {
    super(x, y, name, callback);
    // set label after super otherwise setters fuck up
    this.label = label;
  }

  /**
   * Use this when you only want to show the label
   */
  function setEmptyBackground()
  {
    var oldWidth = width;
    var oldHeight = height;
    makeGraphic(1, 1, 0x0);
    width = oldWidth;
    height = oldHeight;
  }

  function set_label(value:T)
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
