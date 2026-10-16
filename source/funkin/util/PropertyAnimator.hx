package funkin.util;

import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxTimer;

private typedef AnimationInfo =
{
  framerate:Int,
  length:Int,
  loop:Bool
}

private typedef AnimatorProperty =
{
  object:Dynamic,
  field:String,
  startValue:Dynamic,
  values:Array<Dynamic>,
  interrupted:Bool,
  offset:Float
}

class PropertyAnimator implements IFlxDestroyable
{
  public var anims:Map<String, Array<AnimatorProperty>> = new Map<String, Array<AnimatorProperty>>();
  public var animInfo:Map<String, AnimationInfo> = new Map<String, AnimationInfo>();
  public var originalValues:Map<String, Dynamic> = new Map<String, Dynamic>();

  var _animTimer:FlxTimer = new FlxTimer();

  public var object:Dynamic;
  public var onFinish:Null<() -> Void> = null;
  public var curAnim(default, set):String;

  function set_curAnim(val:String):String
  {
    curAnim = val;
    return val;
  }

  public var curFrame(default, set):Int;

  function set_curFrame(val:Int):Int
  {
    curFrame = val;

    if (!anims.exists(curAnim)) return val;

    for (property in anims[curAnim])
    {
      if (property.interrupted || property.values[curFrame] == null) continue;

      if (property.offset != 0) Reflect.setProperty(property.object, property.field, property.values[curFrame] + property.offset);
      else
        Reflect.setProperty(property.object, property.field, property.values[curFrame]);
    }

    return val;
  }

  public function forceAnimFrame(animName:String, frame:Int):Void
  {
    curAnim = animName;
    curFrame = frame;
  }

  /**
   * utility var, this one gets our current option easily
   */
  var curAnimInfo(get, never):AnimationInfo;

  function get_curAnimInfo():AnimationInfo
  {
    if (!animInfo.exists(curAnim)) return null;

    return animInfo[curAnim];
  }

  public function new(?object:Dynamic):Void
  {
    this.object ??= object;
  }

  public function setDefaultProperties():Void
  {
    for (key in originalValues.keys())
    {
      originalValues[key] = Reflect.getProperty(object, key);
    }
  }

  public function pause():Void
  {
    _animTimer.active = false;
  }

  public function unpause():Void
  {
    _animTimer.active = true;
  }

  public function stop():Void
  {
    _animTimer.cancel();
  }

  public function reset():Void
  {
    _animTimer.cancel();
    for (property in originalValues.keys())
    {
      var target = object;
      var path = property.split(".");
      var field = path.pop();
      for (component in path)
      {
        target = Reflect.getProperty(target, component);
        if (!Reflect.isObject(target)) throw 'The object does not have the property "$component" in "$property"';
      }

      Reflect.setProperty(target, field, originalValues[property]);
    }
  }

  public function interruptProperty(propertyToCancel:String):Void
  {
    var interuptableProperty:Null<AnimatorProperty> = anims[curAnim].find(property -> property.field == propertyToCancel);

    if (interuptableProperty == null)
    {
      trace('PROPERTYANIMATOR: Attempted to interrupt $propertyToCancel. This is not a property that is present!');
    }
    else
    {
      interuptableProperty.interrupted = true;
    }
  }

  public function playAnimation(name:String, ?restoreDefaults:Bool = false):Void
  {
    if (!anims.exists(name))
    {
      trace('PROPERTYANIMATOR: Animation $name does not exist!');
      return;
    }

    if (restoreDefaults) reset();

    for (property in anims[name]) property.interrupted = false;

    curAnim = name;
    curFrame = 0;
    onFinish = null;

    var setCurFrameOnTimer:FlxTimer->Void = (timer:FlxTimer) ->
    {
      curFrame = curAnimInfo.loop ? FlxMath.wrap(curFrame + 1, 0, curAnimInfo.length - 1) : timer.elapsedLoops;
      if (!curAnimInfo.loop && timer.finished && onFinish != null) onFinish();
    };

    _animTimer.start(1 / curAnimInfo.framerate, setCurFrameOnTimer, curAnimInfo.loop ? 0 : curAnimInfo.length - 1);
  }

  public function addAnimationByName(name:String, framerate:Int, ?loop:Bool = false):Void
  {
    anims.set(name, []);
    animInfo.set(name, {
      framerate: framerate,
      length: 0,
      loop: loop
    });

  }

  function propertyExistsInAnim(name:String, propertyToFind:String):Bool
  {
    for (property in anims[name])
    {
      if (property.field == propertyToFind) return true;
    }
    return false;
  }


  public function setPropertyOffset(animName:String, propertyToFind:String, offset:Float):Void
  {
    var propertyToOffset:Null<AnimatorProperty> = anims[animName].find(property -> property.field == propertyToFind);

    if (propertyToOffset == null) trace('PROPERTYANIMATOR: Attempted to set offset on $propertyToOffset. This is not a property that is present!');
    else
      propertyToOffset.offset = offset;
  }

  public function addProperty(name:String, property:String, values:Array<Dynamic>, ?offset:Float = 0):Void
  {
    if (!anims.exists(name))
    {
      trace('PROPERTYANIMATOR: Attempted to add $property to $name! This animation does not exist!');
      return;
    }

    if (!propertyExistsInAnim(name, property))
    {
      var target = object;
      var path = property.split(".");
      var field = path.pop();

      for (component in path)
      {
        target = Reflect.getProperty(target, component);
        if (!Reflect.isObject(target)) throw 'The object does not have the property "$component" in "$property"';
      }

      anims[name].push({
        object: target,
        field: field,
        startValue: null,
        values: values,
        interrupted: false,
        offset: offset
      });

      if (animInfo[name].length < values.length) animInfo[name].length = values.length;

      if (!originalValues.exists(property)) originalValues.set(property, null);

    }
    else
    {
      trace('PROPERTYANIMATOR: Animation $name already has values for $property!');
    }
  }

  public function destroy():Void
  {
    _animTimer.cancel();
    object = null;
    anims = null;
  }
}

