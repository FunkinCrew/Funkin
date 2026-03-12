package funkin.group;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSort;
import funkin.util.SortUtil;
import flixel.math.FlxPoint;

/**
 * A FunkinGroup of FlxSprites.
 */
typedef FunkinSpriteGroup = FunkinGroup<FlxSprite>;

/**
 * FlxSpriteGroup but better. Kinda like if `FlxNestedSprite` and `FlxSpriteGroup` were merged.
 */
class FunkinGroup<T:FlxSprite> extends FlxSprite
{
  /**
   * The children of this FunkinGroup.
   */
  public var children:Null<Array<T>>;

  /**
   * The size of this FunkinGroup. Read only.
   */
  public var size(get, never):Int;

  function get_size():Int
  {
    return children.length;
  }

  /**
   * The length of this FunkinGroup. Read only.
   *
   * Alias to `size`.
   */
  public var length(get, never):Int;

  function get_length():Int
  {
    return size;
  }

  /**
   * The max size of this FunkinGroup. 0 and below is infinite.
   */
  public var maxSize(default, set):Int = 0;

  function set_maxSize(value:Int):Int
  {
    if (value < 0) value = 0;

    maxSize = value;

    if (size > maxSize && maxSize > 0)
    {
      for (child in 0...size)
      {
        if (child > maxSize) remove(children[child]);
      }
    }

    return maxSize;
  }

  /**
   * The width of all the FunkinGroup's children's displays put together.
   *
   * Meant as a replacement of frameWidth.
   */
  public var accurateWidth(get, null):Float = 0;

  /**
   * The height of all the FunkinGroup's children's displays put together.
   *
   * Meant as a replacement of frameHeight.
   */
  public var accurateHeight(get, null):Float = 0;

  /**
   * If this is false, the FunkinGroup will update children normally. Otherwise,
   * it will not (obviously).
   *
   * Useful for outside objects to modify this group's children. (Extending
   * classes can just override updateChildren)
   *
   * `false` by default.
   */
  public var customChildUpdate:Bool = false;

  /**
   * Should this FunkinGroup treat itself more like one image (in scale terms).
   *
   * `true` by default.
   */
  public var preciseScale:Bool = true;

  /**
   * Should this FunkinGroup treat itself more like one image (in angle terms).
   *
   * `true` by default.
   */
  public var preciseAngle:Bool = true;

  override function get_width():Float
  {
    if (size < 1) return 0;

    var leftMostSpr:T = sort(function(order:Int, a:T, b:T):Int
    {
      if (a == null || b == null) return 0;
      return FlxSort.byValues(order, x + a.localX, x + b.localX);
    }, false)[0];

    var rightMostSpr:T = sort(function(order:Int, a:T, b:T):Int
    {
      if (a == null || b == null) return 0;
      return FlxSort.byValues(order, (x + a.localX) + a.width, (x + b.localX) + b.width);
    }, false, FlxSort.DESCENDING)[0];

    return Math.abs((x + rightMostSpr.localX) + rightMostSpr.width) - (x + leftMostSpr.localX);
  }

  override function get_height():Float
  {
    if (size < 1) return 0;

    var downwardsMostSpr:T = sort(function(order:Int, a:T, b:T):Int
    {
      if (a == null || b == null) return 0;
      return FlxSort.byValues(order, (y + a.localY) + a.height, (y + b.localY) + b.height);
    }, false, FlxSort.DESCENDING)[0];

    var upwardsMostSpr:T = sort(function(order:Int, a:T, b:T):Int
    {
      if (a == null || b == null) return 0;
      return FlxSort.byValues(order, y + a.localY, y + b.localY);
    }, false)[0];

    return Math.abs(((y + downwardsMostSpr.localY) + downwardsMostSpr.height) - (y + upwardsMostSpr.localY));
  }

  // include scale with frame sizes for better accuracy

  function get_accurateWidth():Float
  {
    if (size < 1) return 0;

    var leftMostSpr:T = sort(function(order:Int, a:T, b:T):Int
    {
      if (a == null || b == null) return 0;
      return FlxSort.byValues(order, x + a.localX, x + b.localX);
    }, false)[0];

    var rightMostSpr:T = sort(function(order:Int, a:T, b:T):Int
    {
      if (a == null || b == null) return 0;
      return FlxSort.byValues(order, (x + a.localX) + (a.frameWidth * a.scale.x), (x + b.localX) + (b.frameWidth * a.scale.x));
    }, false, FlxSort.DESCENDING)[0];

    return Math.abs(((x + rightMostSpr.localX) + (rightMostSpr.frameWidth * rightMostSpr.scale.x)) - (x + leftMostSpr.localX));
  }

  function get_accurateHeight():Float
  {
    if (size < 1) return 0;

    var downwardsMostSpr:T = sort(function(order:Int, a:T, b:T):Int
    {
      if (a == null || b == null) return 0;
      return FlxSort.byValues(order, (y + a.localY) + (a.frameHeight * a.scale.y), (y + b.localY) + (b.frameHeight * a.scale.y));
    }, false, FlxSort.DESCENDING)[0];

    var upwardsMostSpr:T = sort(function(order:Int, a:T, b:T):Int
    {
      if (a == null || b == null) return 0;
      return FlxSort.byValues(order, y + a.localY, y + b.localY);
    }, false)[0];

    return Math.abs(((y + downwardsMostSpr.localY) + (downwardsMostSpr.frameHeight * downwardsMostSpr.scale.y)) - (y + upwardsMostSpr.localY));
  }

  /**
   * Sets this FunkinGroup's `origin` to the center of its complete graphic.
   *
   * Replacement for `centerOrigin`.
   */
  public function resetOrigin():Void
  {
    if (size < 1) return;

    var upwardsMostSpr:T = sort(function(order:Int, a:T, b:T):Int
    {
      if (a == null || b == null) return 0;
      return FlxSort.byValues(order, y + a.localY, y + b.localY);
    }, false)[0];

    var leftMostSpr:T = sort(function(order:Int, a:T, b:T):Int
    {
      if (a == null || b == null) return 0;
      return FlxSort.byValues(order, x + a.localX, x + b.localX);
    }, false)[0];

    origin.set(leftMostSpr.localX + width / 2, upwardsMostSpr.localY + height / 2);
  }

  /**
   * Constructor for FunkinGroup.
   *
   * @param x Starting X.
   * @param y Starting Y.
   * @param maxSize Starting max size.
   * @param preciseScale Whether to treat the FunkinGroup like one image (with scale).
   * @param preciseAngle Whether to treat the FunkinGroup like one image (with angle).
   */
  public function new(?x:Float, ?y:Float, ?maxSize:Int, ?preciseScale:Bool, ?preciseAngle:Bool)
  {
    super(x, y);

    children = [];

    this.maxSize = maxSize ?? 0;

    if (preciseScale != null) this.preciseScale = preciseScale;
    if (preciseAngle != null) this.preciseAngle = preciseAngle;
  }

  /**
   * Gets the child at an index.
   *
   * @param index The position.
   * @return The child or null.
   */
  public inline function getChildAt(index:Int):Null<T>
  {
    if (index < 0 || index >= size) return null;

    return children[index];
  }

  /**
   * Sets the child at an index.
   *
   * @param index The position.
   * @param replacement A new child to replace the old one.
   */
  public inline function setChildAt(index:Int, replacement:T):Void
  {
    if (index < 0 || index >= size) return;

    children[index] = replacement;
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    updateChildren();

    for (child in children)
    {
      if (child != null && child.exists && child.active) child.update(elapsed);
    }
  }

  override public function draw():Void
  {
    for (child in children)
    {
      if (child != null && child.exists && child.visible) child.draw();
    }
  }

  /**
   * Updates the children here. Uses the child's local variables like `localX` and `localY` to update the child's position. Like `FlxNestedSprite`!
   * Can be overriden by outside classes with `customChildUpdate`.
   */
  public function updateChildren():Void
  {
    if (customChildUpdate) return;

    for (child in children)
    {
      if (child != null && child.exists && child.active)
      {
        child.angle = angle + child.localAngle;
        child.scale.x = scale.x * child.localScale.x;
        child.scale.y = scale.y * child.localScale.y;

        var displace = new FlxPoint(child.localX, child.localY);

        var dx:Float = 0;
        var dy:Float = 0;

        dx = origin.x - child.width / 2;
        dy = origin.y - child.height / 2;

        if (preciseScale && !preciseAngle)
        {
          dx += scale.x * (child.localX - origin.x + child.width / 2);

          dy += scale.y * (child.localY - origin.y + child.height / 2);
        }
        else if (preciseAngle && !preciseScale)
        {
          var radians:Float = angle * (Math.PI / 180);
          var cos:Float = Math.cos(radians);
          var sin:Float = Math.sin(radians);

          dx += cos * (child.localX - origin.x + child.width / 2);
          dx -= sin * (child.localY - origin.y + child.height / 2);

          dy += cos * (child.localY - origin.y + child.height / 2);
          dy += sin * (child.localX - origin.x + child.width / 2);
        }
        else if (preciseAngle && preciseScale)
        {
          var radians:Float = angle * (Math.PI / 180);
          var cos:Float = Math.cos(radians);
          var sin:Float = Math.sin(radians);

          dx += scale.x * cos * (child.localX - origin.x + child.width / 2);
          dx -= scale.y * sin * (child.localY - origin.y + child.height / 2);

          dy += scale.y * cos * (child.localY - origin.y + child.height / 2);
          dy += scale.x * sin * (child.localX - origin.x + child.width / 2);
        }

        if (preciseScale || preciseAngle) displace.set(dx, dy);

        child.x = x + displace.x;
        child.y = y + displace.y;

        child.alpha = alpha * child.localAlpha;
        child.visible = visible && child.localVisible;
        // force child cameras to the group's cameras.
        if (child.cameras != cameras) child.cameras = cameras;
      }
    }
  }

  /**
   * Adds a child to this FunkinGroup. Will also return said child for convenience.
   * Can't add if `size` is at `maxSize`, instead returning null.
   *
   * @param child The child that the caller wants this FunkinGroup to add.
   * @return The same child or null.
   */
  public function add(child:T):Null<T>
  {
    if (maxSize > 0 && size >= maxSize) return null;

    children.push(child);
    return child;
  }

  /**
   * Makes a child right in this FunkinGroup. Will also return said child for convenience.
   * Can't create the child if `size` is at `maxSize`, instead returning null.
   *
   * @return The created child or null.
   */
  public function make():Null<T>
  {
    if (maxSize > 0 && size >= maxSize) return null;

    var newChild:T = cast new FlxSprite();
    children.push(newChild);
    return newChild;
  }

  /**
   * Adds a child to this FunkinGroup at a given index. Will also return said child for convenience.
   *
   * @param child The child that the caller wants this FunkinGroup to add.
   * @param index The position the caller wants the child to go in.
   * @return The same child or null.
   */
  public function insert(child:T, index:Int):Null<T>
  {
    if (size < index) return null;
    children.insert(index, child);
    return child;
  }

  /**
   * Moves select children from another FunkinGroup into this one. Only works if both FunkinGroups contain the same type.
   *
   * @param grp The other group to take from.
   * @param children The children to move.
   */
  public function move(grp:FunkinGroup<T>, children:Array<T>):Void
  {
    for (child in children)
    {
      if (grp.children.contains(child))
      {
        grp.remove(child);
        add(child);
        // update child's local position so the child stays where it was
        child.localX = x - child.x;
        child.localY = y - child.y;
      }
    }
  }

  override public function destroy():Void
  {
    for (child in children)
    {
      child.destroy();
    }

    children = null;

    super.destroy();
  }

  /**
   * Removes a child from the group, also returns it for convenience.
   *
   * @param child The child to remove.
   * @return The removed child.
   */
  public function remove(child:T):Null<T>
  {
    var index = children.indexOf(child);
    if (index != -1) children.splice(index, 1);

    return child;
  }

  /**
   * Applies a function to all children.
   *
   * @param func A function that modifies one child at a time.
   */
  public function forEach(func:T->Void):Void
  {
    for (child in children)
    {
      if (child != null)
      {
        func(child);
      }
    }
  }

  /**
   * Sorts the children of this FunkinGroup. Returns the sorted children
   *
   * @param func     The sorting function to use - you can use one of the premade ones in
   *                 `FlxSort` or write your own using `FlxSort.byValues()` as a "backend".
   * @param setGroup Whether to actually sort the children of this group,
   *                 so the caller can grab a sorted list without this group
   *                 actually sorting the children.
   * @param order    A constant that defines the sort order.
   *                 Possible values are `FlxSort.ASCENDING` (default) and `FlxSort.DESCENDING`.
   * @return         The sorted children list.
   */
  public inline function sort(func:(Int, T, T) -> Int, setGroup:Bool = true, order = FlxSort.ASCENDING):Null<Array<T>>
  {
    if (setGroup)
    {
      children.sort(func.bind(order));
      return children;
    }
    else
    {
      var fakeKids = children.copy();
      fakeKids.sort(func.bind(order));
      return fakeKids;
    }
  }

  /**
   * Refreshes the group, by redoing the render order of all children.
   * It does this based on the `zIndex` of each child.
   */
  public function refresh():Void
  {
    sort(SortUtil.byZIndex);
  }

  /**
   * Get's the first alive child under this FunkinGroup. Returns null if it can't
   * find squat.
   *
   * @return The alive child or null.
   */
  public inline function getFirstAlive():Null<T>
  {
    for (child in children)
    {
      if (child.exists && child.alive) return child;
    }

    return null;
  }

  /**
   * Get's the first dead child under this FunkinGroup. Returns null if it can't
   * find squat.
   * getFirstAlive's evil twin.
   *
   * @return The dead child or null.
   */
  public inline function getFirstDead():Null<T>
  {
    for (child in children)
    {
      if (!child.alive) return child;
    }

    return null;
  }

  /**
   * Counts the amount of alive children in this FunkinGroup.
   *
   * @return The alive child number or null.
   */
  public inline function countLiving():Int
  {
    var i = 0;

    for (child in children)
    {
      if (child.alive) i++;
    }

    return i;
  }

  /**
   * Counts the amount of dead children in this FunkinGroup.
   *
   * @return The dead child number or null.
   */
  public inline function countDead():Int
  {
    var i = 0;

    for (child in children)
    {
      if (!child.alive) i++;
    }

    return i;
  }

  /**
   * Gets the first nonexistent child in the family and returns it.
   * Good for recycling.
   *
   * @return The child or null.
   */
  public inline function getFirstAvailable():Null<T>
  {
    for (child in children)
    {
      if (!child.exists) return child;
    }

    return null;
  }

  /**
   * Gets the index of the first null child under this FunkinGroup.
   * -1 means it failed
   *
   * @return The index.
   */
  public inline function getFirstNull():Int
  {
    for (child in 0...size)
    {
      if (children[child] == null) return child;
    }

    return -1;
  }

  /**
   * Gets the first existing child in the family and returns it.
   * Good for recycling.
   *
   * @return The child or null.
   */
  public inline function getFirstExisting():Null<T>
  {
    for (child in children)
    {
      if (child.exists) return child;
    }

    return null;
  }

  /**
   * Gets a random child from this FunkinGroup.
   * @param startIndex Optional offset off the front of the array.
   *                   Default value is `0`, or the beginning of the array.
   * @param length Optional restriction on the number of values you want to randomly select from.
   * @return A child or null.
   */
  public inline function getRandom(startIndex:Int = 0, length:Int = 0):Null<T>
  {
    if (size <= 0) return null;

    if (startIndex < 0) startIndex = 0;
    if (length <= 0) length = size;

    return FlxG.random.getObject(children, startIndex, length);
  }

  /**
   * Brings a child back from the graveyard.
   *
   * @param child The child to revive.
   */
  public function reviveChild(child:T):Void
  {
    if (child != null) child.revive();
  }

  /**
   * Kills all the children and then itself.
   * Revive this group via `revive()`.
   */
  override public function kill():Void
  {
    for (child in children)
    {
      if (child != null) child.kill();
    }

    super.kill();
  }

  /**
   * Revives all the children and then itself.
   */
  override public function revive():Void
  {
    for (child in children)
    {
      if (child != null) child.revive();
    }

    super.revive();
  }

  override public function clone():FunkinGroup<T>
  {
    var group = new FunkinGroup<T>(x, y, maxSize);

    for (child in children)
    {
      group.add(cast child.clone());
    }

    return group;
  }

  // =============================================================
  //   Unavailable functions that won't work with `FunkinGroup`.
  // =============================================================

  /**
   * This functionality isn't supported in `FunkinGroup`.
   * @return this group
   */
  override public function makeGraphic(Width:Int, Height:Int, Color:Int = FlxColor.WHITE, Unique:Bool = false, ?Key:String):FlxSprite
  {
    #if FLX_DEBUG
    throw "This function is not supported in FunkinGroup";
    #end
    return this;
  }

  /**
   * This functionality isn't supported in `FunkinGroup`.
   * @return this group
   */
  override public function loadGraphicFromSprite(Sprite:FlxSprite):FlxSprite
  {
    #if FLX_DEBUG
    throw "This function is not supported in FunkinGroup";
    #end
    return this;
  }

  /**
   * This functionality isn't supported in `FunkinGroup`.
   * @return this group
   */
  override public function loadGraphic(Graphic:flixel.system.FlxAssets.FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0,
      Unique:Bool = false, ?Key:String):FlxSprite
  {
    return this;
  }

  /**
   * This functionality isn't supported in `FunkinGroup`.
   * @return this group
   */
  override public function loadRotatedGraphic(Graphic:flixel.system.FlxAssets.FlxGraphicAsset, Rotations:Int = 16, Frame:Int = -1, AntiAliasing:Bool = false,
      AutoBuffer:Bool = false, ?Key:String):FlxSprite
  {
    #if FLX_DEBUG
    throw "This function is not supported in FunkinGroup";
    #end
    return this;
  }

  override function set_pixels(Value:openfl.display.BitmapData):openfl.display.BitmapData
  {
    return Value;
  }

  override function set_frame(Value:flixel.graphics.frames.FlxFrame):flixel.graphics.frames.FlxFrame
  {
    return Value;
  }

  override function get_pixels():openfl.display.BitmapData
  {
    return null;
  }

  /**
   * Internal function to update the current animation frame.
   *
   * @param	RunOnCpp	Whether the frame should also be recalculated if we're on a non-flash target
   */
  override inline function calcFrame(RunOnCpp:Bool = false):Void
  {
    // Nothing to do here
  }

  /**
   * This functionality isn't supported in `FunkinGroup`.
   */
  override inline function resetHelpers():Void
  {
  }

  /**
   * This functionality isn't supported in `FunkinGroup`.
   */
  override public inline function stamp(Brush:FlxSprite, X:Int = 0, Y:Int = 0):Void
  {
  }

  override function set_frames(Frames:flixel.graphics.frames.FlxFramesCollection):flixel.graphics.frames.FlxFramesCollection
  {
    return Frames;
  }

  /**
   * This functionality isn't supported in `FunkinGroup`.
   */
  override inline function updateColorTransform():Void
  {
  }
}
