package funkin.ui;

import flixel.util.FlxDestroyUtil;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.util.helpers.FlxBounds;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;

class SimpleFunkinBar extends FlxSpriteGroup
{
  public var leftBar:FlxSprite;
  public var rightBar:FlxSprite;
  public var bg:FunkinSprite;

  public var bounds:FlxBounds<Float> = new FlxBounds<Float>(0, 1);
  public var percent(default, set):Float = 0.0;
  public var leftToRight(default, set):Bool = false;
  public var smoothFactor(default, set):Float = 0;

  @:noCompletion var lerpFactor:Float = 1;

  @:noCompletion inline function set_smoothFactor(i:Float):Float
  {
    lerpFactor = FlxMath.bound(i, 1);
    return smoothFactor = FlxMath.bound(i, 0, 1);
  }

  public var smoothMultiplay:Float = 25;

  // DEPRECATED!!!
  public var barCenter(get, never):Float;
  public var centerPoint(default, null):FlxPoint = FlxPoint.get();

  @:noCompletion inline function get_barCenter():Float
    return centerPoint.x;

  // you might need to change this if you want to use a custom bar
  public var barWidth(default, set):Int = 1;
  public var barHeight(default, set):Int = 1;
  public var barOffset:FlxPoint = FlxPoint.get(3, 3);

  public var basicOffset:FlxPoint = FlxPoint.get(0, 0);

  public var valueFunction:() -> Float;
  public var updateCallbackPre:(value:Float, percent:Float) -> Void;
  public var updateCallbackPost:(value:Float, percent:Float) -> Void;

  public var shouldImitateSize(default, set):Bool = true;

  public function new(x:Float, y:Float, image:String = 'healthBar', valueFunction:Void->Float = null, boundMIN:Float = 0, boundMAX:Float = 1)
  {
    super(x, y);

    this.valueFunction = valueFunction ?? () -> return 0.0;
    setBounds(boundMIN, boundMAX);

    value = FlxMath.bound(this.valueFunction(), bounds.min, bounds.max);
    percent = FlxMath.remapToRange(value, bounds.min, bounds.max, 0.0, 100.0);

    bg = FunkinSprite.create(image);
    barWidth = Std.int(bg.width - 6);
    barHeight = Std.int(bg.height - 6);

    leftBar = new FlxSprite().makeGraphic(Std.int(bg.width), Std.int(bg.height));

    rightBar = new FlxSprite().makeGraphic(Std.int(bg.width), Std.int(bg.height));
    rightBar.color = FlxColor.BLACK;

    leftBar.clipRect = FlxRect.get(0, 0, 1, 1);
    rightBar.clipRect = FlxRect.get(0, 0, 1, 1);

    antialiasing = true;

    add(leftBar);
    add(rightBar);
    add(bg);
    regenerateClips();
  }

  public var value:Float;

  override function update(elapsed:Float)
  {
    value = FlxMath.bound(valueFunction(), bounds.min, bounds.max);
    final percentValue:Float = FlxMath.remapToRange(value, bounds.min, bounds.max, 0, 100);
    percent = FlxMath.lerp(percent, percentValue, FlxMath.lerp(1, smoothMultiplay * elapsed / lerpFactor, smoothFactor));
    super.update(elapsed);
  }

  public function setBounds(min:Float = 0, max:Float = 1):FlxBounds<Float>
    return bounds.set(min, max);

  /**
   * Useful for smooth bar
   */
  public dynamic function snapPercent()
  {
    value = FlxMath.bound(valueFunction(), bounds.min, bounds.max);
    percent = FlxMath.remapToRange(value, bounds.min, bounds.max, 0, 100);
  }

  override function destroy()
  {
    bounds = null;
    barOffset = FlxDestroyUtil.put(barOffset);
    centerPoint = FlxDestroyUtil.put(centerPoint);
    if (leftBar != null)
    {
      leftBar.clipRect = FlxDestroyUtil.put(leftBar.clipRect);
      leftBar = null;
    }
    if (rightBar != null)
    {
      rightBar.clipRect = FlxDestroyUtil.put(rightBar.clipRect);
      rightBar = null;
    }
    valueFunction = null;
    updateCallbackPre = null;
    updateCallbackPost = null;
    bg = null;
    super.destroy();
  }

  var flipped(default, set):Bool = false;

  function set_flipped(e)
  {
    flipped = e;
    if (leftBar != null && rightBar != null)
    {
      final left = leftBar.color;
      final right = rightBar.color;
      leftToRight = e;
      if (flipped)
      {
        leftBar.color = right;
        rightBar.color = left;
      }
      else
      {
        leftBar.color = right;
        rightBar.color = left;
      }
    }
    return flipped;
  }

  public dynamic function flipBar()
  {
    return flipped = !flipped;
  }

  public dynamic function setColors(?left:FlxColor, ?right:FlxColor)
  {
    if (flipped)
    {
      if (left != null) rightBar.color = left;
      if (right != null) leftBar.color = right;
    }
    else
    {
      if (left != null) leftBar.color = left;
      if (right != null) rightBar.color = right;
    }
  }

  var leftSize:Float = 0;

  public dynamic function updateBar()
  {
    if (leftBar == null || rightBar == null) return;

    leftBar.setPosition(bg.x + basicOffset.x, bg.y + basicOffset.y);
    rightBar.setPosition(bg.x + basicOffset.x, bg.y + basicOffset.y);

    if (updateCallbackPre != null) updateCallbackPre(value, percent);

    leftSize = FlxMath.lerp(0, barWidth, (leftToRight ? percent / 100 : 1 - percent / 100));

    leftBar.clipRect.width = leftSize;
    leftBar.clipRect.height = barHeight;
    leftBar.clipRect.x = barOffset.x;
    leftBar.clipRect.y = barOffset.y;

    rightBar.clipRect.width = barWidth - leftSize;
    rightBar.clipRect.height = barHeight;
    rightBar.clipRect.x = barOffset.x + leftSize;
    rightBar.clipRect.y = barOffset.y;

    centerPoint.set(leftBar.x + leftSize + barOffset.x, leftBar.y + leftBar.clipRect.height * 0.5 + barOffset.y);

    setClipRectToFlxSprite(leftBar, leftBar.clipRect);
    setClipRectToFlxSprite(rightBar, rightBar.clipRect);
    if (updateCallbackPost != null) updateCallbackPost(value, percent);
  }

  @:access(flixel.FlxSprite)
  function setClipRectToFlxSprite(spr:FlxSprite, rect:FlxRect):FlxRect
  {
    @:bypassAccessor spr.clipRect = rect;

    if (spr.frames != null) spr.frame = spr.frames.frames[spr.animation.frameIndex];

    return rect;
  }

  public dynamic function regenerateClips()
  {
    if (shouldImitateSize)
    {
      if (leftBar != null)
      {
        leftBar.setGraphicSize(bg.width, bg.height);
        leftBar.updateHitbox();
      }
      if (rightBar != null)
      {
        rightBar.setGraphicSize(bg.width, bg.height);
        rightBar.updateHitbox();
      }
    }
    updateBar();
  }

  private function set_shouldImitateSize(should:Bool)
  {
    shouldImitateSize = should;
    if (shouldImitateSize)
    {
      if (leftBar != null)
      {
        leftBar.setGraphicSize(bg.width, bg.height);
        leftBar.updateHitbox();
      }
      if (rightBar != null)
      {
        rightBar.setGraphicSize(bg.width, bg.height);
        rightBar.updateHitbox();
      }
    }
    return should;
  }

  private function set_percent(value:Float)
  {
    final doUpdate:Bool = value != percent;
    percent = value;

    if (doUpdate) updateBar();
    return value;
  }

  private function set_leftToRight(value:Bool)
  {
    leftToRight = value;
    updateBar();
    return value;
  }

  private function set_barWidth(value:Int)
  {
    barWidth = value;
    regenerateClips();
    return value;
  }

  private function set_barHeight(value:Int)
  {
    barHeight = value;
    regenerateClips();
    return value;
  }

  @:noCompletion override inline function set_x(Value:Float):Float
  { // for dynamic center point update
    final prevX:Float = x;
    super.set_x(Value);
    centerPoint.x += Value - prevX;
    return Value;
  }

  @:noCompletion override inline function set_y(Value:Float):Float
  {
    final prevY:Float = y;
    super.set_y(Value);
    centerPoint.y += Value - prevY;
    return Value;
  }

  @:noCompletion override inline function set_antialiasing(Antialiasing:Bool):Bool
  {
    for (member in members)
      member.antialiasing = Antialiasing;

    return antialiasing = Antialiasing;
  }
}
