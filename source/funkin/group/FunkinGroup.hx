package funkin.group;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.util.FlxSort;
import funkin.util.SortUtil;
import flixel.math.FlxPoint;
import flixel.FlxCamera;
import flixel.util.FlxDestroyUtil;
import flixel.group.IFlxGroupable;

/**
 * A FunkinGroup of FlxSprites.
 */
typedef FunkinSpriteGroup = FunkinGroup<FlxSprite>;

/**
 * FlxSpriteGroup but better.
 */
class FunkinGroup<T:FlxSprite> extends FlxSprite implements IFlxGroupable<T>
{
  /**
   * A `FlxPoint` used by the Camera Editor to determine positioning.
   */
  public var vcamPoint:Null<FlxPoint> = null;

  /**
   * The children of this FunkinGroup.
   */
  public var children:Array<T>;

  /**
   * The size of this FunkinGroup. Read only.
   */
  public var size(get, never):Int;

  /**
   * Screen-space clip rect inherited from a parent FunkinGroup, if any.
   * Combined with this group's own (screen-space) `clipRect` to form the
   * effective region applied to children. `null` = nothing inherited.
   */
  var _inheritedClipRect:Null<FlxRect> = null;

  /** Reusable scratch rect for the combined effective clip. */
  var _effectiveClipRect:Null<FlxRect> = null;

  var _childOwnClips:Map<FlxSprite, FlxRect> = new Map();

  /** Register a sprite's own (local) clip that should survive the group's clipping. */
  public function setChildClipRect(child:FlxSprite, ?localClip:FlxRect):Void
  {
    if (localClip == null) _childOwnClips.remove(child);
    else
      _childOwnClips.set(child, localClip);
  }

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
   * The combined screen-space clip for this group.
  **/
  function getEffectiveClipRect():Null<FlxRect>
  {
    if (clipRect == null && _inheritedClipRect == null) return null;

    if (_effectiveClipRect == null) _effectiveClipRect = FlxRect.get();

    if (clipRect == null) return _effectiveClipRect.copyFrom(_inheritedClipRect);
    if (_inheritedClipRect == null) return _effectiveClipRect.copyFrom(clipRect);

    return clipRect.intersection(_inheritedClipRect, _effectiveClipRect);
  }

  /**
   * Pushes this group's screen-space clip down to its children.
  **/
  public function updateClipRects():Void
  {
    var screenClip:Null<FlxRect> = getEffectiveClipRect();
    var cam:FlxCamera = getDefaultCamera();

    for (child in children)
    {
      if (child == null || !child.exists) continue;

      if (Std.isOfType(child, FunkinGroup))
      {
        var childGroup:FunkinGroup<Dynamic> = cast child;

        if (screenClip == null)
        {
          childGroup._inheritedClipRect = FlxDestroyUtil.put(childGroup._inheritedClipRect);
        }
        else
        {
          if (childGroup._inheritedClipRect == null) childGroup._inheritedClipRect = FlxRect.get();
          childGroup._inheritedClipRect.copyFrom(screenClip);
        }
      }
      else
      {
        var own:FlxRect = _childOwnClips.get(child);

        if (screenClip == null)
        {
          if (own != null) child.clipRect = child.clipRect != null ? child.clipRect.copyFrom(own) : FlxRect.get().copyFrom(own);
          else if (child.clipRect != null) child.clipRect = FlxDestroyUtil.put(child.clipRect);
        }
        else
        {
          var dest:FlxRect = child.clipRect != null ? child.clipRect : FlxRect.get();
          screenToLocalClipRect(child, screenClip, dest, cam);
          if (own != null) dest = own.intersection(dest, dest);
          child.clipRect = dest;
        }
      }
    }
  }

  /**
   * Projects a screen-space rect into a child sprite's local graphic-pixel space.
  **/
  function screenToLocalClipRect(child:FlxSprite, screenClip:FlxRect, result:FlxRect, ?camera:FlxCamera):FlxRect
  {
    var minX:Float = Math.POSITIVE_INFINITY;
    var minY:Float = Math.POSITIVE_INFINITY;
    var maxX:Float = Math.NEGATIVE_INFINITY;
    var maxY:Float = Math.NEGATIVE_INFINITY;

    var screenCorner:FlxPoint = FlxPoint.get();
    var localCorner:FlxPoint = FlxPoint.get();

    for (i in 0...4)
    {
      var sx:Float = (i == 1 || i == 2) ? screenClip.right : screenClip.left;
      var sy:Float = (i >= 2) ? screenClip.bottom : screenClip.top;

      screenCorner.set(sx, sy);
      child.transformScreenToPixels(screenCorner, camera, localCorner);

      if (localCorner.x < minX) minX = localCorner.x;
      if (localCorner.y < minY) minY = localCorner.y;
      if (localCorner.x > maxX) maxX = localCorner.x;
      if (localCorner.y > maxY) maxY = localCorner.y;
    }

    screenCorner.put();
    localCorner.put();

    return result.set(minX, minY, maxX - minX, maxY - minY);
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
   * If this is false, the FunkinGroup will update children normally. Otherwise,
   * it will not (obviously).
   *
   * Useful for outside objects to modify this group's children. (Extending
   * classes can just override positionChild or positionChildren)
   *
   * `false` by default.
   */
  public var customChildPositioning:Bool = false;

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
    var transforms = getTransformsFromAll();

    positionChildren();

    if (size < 1)
    {
      applyTransformsToAll(transforms);
      return 0;
    }

    var minLeft:Float = Math.POSITIVE_INFINITY;
    var maxRight:Float = Math.NEGATIVE_INFINITY;

    for (child in children)
    {
      if (child == null || !child.alive || !child.visible) continue;

      var transform = transforms[children.indexOf(child)];
      var left:Float;
      var right:Float;

      if (Std.isOfType(child, FunkinGroup))
      {
        var childGroup:FunkinGroup<Dynamic> = cast child;
        var childW:Float = childGroup.width;
        if (childW <= 0) continue;
        left = transform.x * scale.x;
        right = left + childW * scale.x;
      }
      else
      {
        left = transform.x * scale.x;
        right = left + child.frameWidth * child.scale.x;
      }

      if (left < minLeft) minLeft = left;
      if (right > maxRight) maxRight = right;
    }

    applyTransformsToAll(transforms);

    if (minLeft == Math.POSITIVE_INFINITY) return 0;
    return maxRight - minLeft;
  }

  override function get_height():Float
  {
    var transforms = getTransformsFromAll();

    positionChildren();

    if (size < 1)
    {
      applyTransformsToAll(transforms);
      return 0;
    }

    var minTop:Float = Math.POSITIVE_INFINITY;
    var maxBottom:Float = Math.NEGATIVE_INFINITY;

    for (child in children)
    {
      if (child == null || !child.alive || !child.visible) continue;

      var transform = transforms[children.indexOf(child)];
      var top:Float;
      var bottom:Float;

      if (Std.isOfType(child, FunkinGroup))
      {
        var childGroup:FunkinGroup<Dynamic> = cast child;
        var childH:Float = childGroup.height;
        if (childH <= 0) continue;
        top = transform.y;
        bottom = top + childH * scale.y;
      }
      else
      {
        top = transform.y * scale.y;
        bottom = top + child.frameHeight * child.scale.y;
      }

      if (top < minTop) minTop = top;
      if (bottom > maxBottom) maxBottom = bottom;
    }

    applyTransformsToAll(transforms);

    if (minTop == Math.POSITIVE_INFINITY) return 0;
    return maxBottom - minTop;
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
      return FlxSort.byValues(order, y + a.y, y + b.y);
    }, false)[0];

    var leftMostSpr:T = sort(function(order:Int, a:T, b:T):Int
    {
      if (a == null || b == null) return 0;
      return FlxSort.byValues(order, x + a.x, x + b.x);
    }, false)[0];

    origin.set(leftMostSpr.x + width / 2, upwardsMostSpr.y + height / 2);
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
   * Gets the screen position of the sprite, taking into account the camera scroll and the `vcamPoint` if it exists.
   * @param result An optional `FlxPoint` to store the result in. If null, a new `FlxPoint` will be created.
   * @param camera The camera to calculate the screen position relative to. If null, the default camera will be used.
   * @return The screen position of the sprite.
   */
  override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
  {
    if (result == null) result = FlxPoint.get();
    if (camera == null) camera = getDefaultCamera();
    result.set(x, y);
    if (pixelPerfectPosition) result.floor();

    if (vcamPoint != null) return result.subtract((vcamPoint.x * scrollFactor.x) + camera.scroll.x, (vcamPoint.y * scrollFactor.y) + camera.scroll.y);

    return result.subtract(camera.scroll.x * scrollFactor.x, camera.scroll.y * scrollFactor.y);
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

    for (child in children)
    {
      if (child != null && child.exists && child.active) child.update(elapsed);
    }
  }

  override public function draw():Void
  {
    for (child in children)
    {
      if (child == null || !child.exists || !child.visible) continue;

      var transforms = getTransforms(child);
      positionChild(child);

      if (this.scrollFactor.x != 1 || this.scrollFactor.y != 1)
      {
        child.scrollFactor.set(child.scrollFactor.x * this.scrollFactor.x, child.scrollFactor.y * this.scrollFactor.y);
      }

      updateClipRects();

      child.draw();

      applyTransforms(child, transforms);
    }
  }

  /**
   * Positions a child according to the group's transformations here. This function should not be permanent.
   * Can be overridden by outside classes with `customChildPositioning`.
   */
  public function positionChild(child:T):T
  {
    if (customChildPositioning) return child;

    if (child != null && child.exists && child.active)
    {
      child.angle += angle;
      child.scale.x *= scale.x;
      child.scale.y *= scale.y;

      _point.set(child.x, child.y);

      var dx:Float = 0;
      var dy:Float = 0;

      dx = origin.x - child.width / 2;
      dy = origin.y - child.height / 2;

      if (preciseScale && !preciseAngle)
      {
        dx += scale.x * (child.x - origin.x + child.width / 2);

        dy += scale.y * (child.y - origin.y + child.height / 2);
      }
      else if (preciseAngle && !preciseScale)
      {
        var radians:Float = angle * (Math.PI / 180);
        var cos:Float = Math.cos(radians);
        var sin:Float = Math.sin(radians);

        dx += cos * (child.x - origin.x + child.width / 2);
        dx -= sin * (child.y - origin.y + child.height / 2);

        dy += cos * (child.y - origin.y + child.height / 2);
        dy += sin * (child.x - origin.x + child.width / 2);
      }
      else if (preciseAngle && preciseScale)
      {
        var radians:Float = angle * (Math.PI / 180);
        var cos:Float = Math.cos(radians);
        var sin:Float = Math.sin(radians);

        dx += scale.x * cos * (child.x - origin.x + child.width / 2);
        dx -= scale.y * sin * (child.y - origin.y + child.height / 2);

        dy += scale.y * cos * (child.y - origin.y + child.height / 2);
        dy += scale.x * sin * (child.x - origin.x + child.width / 2);
      }

      if (preciseScale || preciseAngle) _point.set(dx, dy);

      child.x = x + _point.x;
      child.y = y + _point.y;

      child.alpha = alpha * child.alpha;
      // force child cameras to the group's cameras.
      if (child.cameras != cameras) child.cameras = cameras;
    }

    return child;
  }

  /**
   * Positions the children according to the group's transformations here. This function should not be permanent.
   * Can be overridden by outside classes with `customChildPositioning`.
   */
  public function positionChildren():Void
  {
    if (customChildPositioning) return;

    for (child in children)
    {
      positionChild(child);
    }
  }

  /**
   * Returns a structure of variables a child has, for saving and using later.
   *
   * @param child The child.
   * @return The child's transform values.
   */
  public function getTransforms(child:T):Dynamic
  {
    return {
      x: child.x,
      y: child.y,
      alpha: child.alpha,
      angle: child.angle,
      scale: [child.scale.x, child.scale.y],
      scrollFactor: [child.scrollFactor.x, child.scrollFactor.y]
    }
  }

  /**
   * Applies a structure of transform values (gotten from getTransforms)
   * to a child.
   *
   * @param child The child.
   * @param transforms The transform values.
   */
  public function applyTransforms(child:T, transforms:Dynamic):Void
  {
    child.x = transforms.x;
    child.y = transforms.y;
    child.alpha = transforms.alpha;
    child.angle = transforms.angle;
    child.scale.set(transforms.scale[0], transforms.scale[1]);
    child.scrollFactor.set(transforms.scrollFactor[0], transforms.scrollFactor[1]);
  }

  public function getTransformsFromAll():Array<Dynamic>
  {
    return[for (child in children) getTransforms(child)];
  }

  public function applyTransformsToAll(transforms:Array<Dynamic>):Void
  {
    if (transforms.length < children.length) return;
    for (child in 0...children.length) applyTransforms(children[child], transforms[child]);
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
    child.container = cast this;

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
        // update child's position so the child stays where it was
        child.x = x - child.x;
        child.y = y - child.y;
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
   * @param splice Unused: Only here because the interface mandates it.
   * @return The removed child.
   */
  public function remove(child:T, splice:Bool = false):Null<T>
  {
    var index = children.indexOf(child);
    if (index != -1) children.splice(index, 1);

    child.container = null;

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
   * Clears all children from this FunkinGroup.
   */
  public inline function clear():Void
  {
    for (child in children)
    {
      child.destroy();
    }

    children = [];
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
    throw 'This function is not supported in FunkinGroup';
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
    throw 'This function is not supported in FunkinGroup';
    #end
    return this;
  }

  /**
   * This functionality isn't supported in `FunkinGroup`.
   * @return this group
   */
  override public function loadGraphic(Graphic:flixel.system.FlxAssets.FlxGraphicAsset,
    Animated:Bool = false,
    Width:Int = 0,
    Height:Int = 0,
    Unique:Bool = false,
    ?Key:String):FlxSprite
  {
    return this;
  }

  /**
   * This functionality isn't supported in `FunkinGroup`.
   * @return this group
   */
  override public function loadRotatedGraphic(Graphic:flixel.system.FlxAssets.FlxGraphicAsset,
    Rotations:Int = 16,
    Frame:Int = -1,
    AntiAliasing:Bool = false,
    AutoBuffer:Bool = false,
    ?Key:String):FlxSprite
  {
    #if FLX_DEBUG
    throw 'This function is not supported in FunkinGroup';
    #end
    return this;
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

  /**
   * Iterates through every member.
   */
  public inline function iterator(?filter:T->Bool):FunkinGroupIterator<T>
  {
    return new FunkinGroupIterator<T>(children, filter);
  }

  /**
   * Iterates through every member and index.
   */
  public inline function keyValueIterator()
  {
    return children.keyValueIterator();
  }
}

class FunkinGroupIterator<T>
{
  var _groupMembers:Array<T>;
  var _filter:T->Bool;
  var _cursor:Int;
  var _length:Int;

  public inline function new(groupMembers:Array<T>, ?filter:T->Bool)
  {
    _groupMembers = groupMembers;
    _filter = filter;
    _cursor = 0;
    _length = _groupMembers.length;
  }

  public inline function next()
  {
    return hasNext() ? _groupMembers[_cursor++] : null;
  }

  public inline function hasNext():Bool
  {
    while (_cursor < _length && (_groupMembers[_cursor] == null || _filter != null && !_filter(_groupMembers[_cursor])))
    {
      _cursor++;
    }
    return _cursor < _length;
  }
}
