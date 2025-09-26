package funkin.util.assets;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.data.animation.AnimationData;

@:nullSafety
class FlxAnimationUtil
{
  /**
   * Properly adds an animation to a sprite based on the provided animation data.
   */
  public static function addAtlasAnimation(target:FlxSprite, anim:AnimationData):Void
  {
    if (anim.prefix == null) return;
    var frameRate = anim.frameRate == null ? 24 : anim.frameRate;
    var looped = anim.looped == null ? false : anim.looped;
    var flipX = anim.flipX == null ? false : anim.flipX;
    var flipY = anim.flipY == null ? false : anim.flipY;

    if (anim.frameIndices != null && anim.frameIndices.length > 0)
    {
      // trace('addByIndices(${anim.name}, ${anim.prefix}, ${anim.frameIndices}, ${frameRate}, ${looped}, ${flipX}, ${flipY})');
      target.animation.addByIndices(anim.name, anim.prefix, anim.frameIndices, '', frameRate, looped, flipX, flipY);
      // trace('RESULT:${target.animation.getAnimationList()}');
    }
    else
    {
      // trace('addByPrefix(${anim.name}, ${anim.prefix}, ${frameRate}, ${looped}, ${flipX}, ${flipY})');
      target.animation.addByPrefix(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
      // trace('RESULT:${target.animation.getAnimationList()}');
    }
  }

  /**
   * Properly adds multiple animations to a sprite based on the provided animation data.
   */
  public static function addAtlasAnimations(target:FlxSprite, animations:Array<AnimationData>):Void
  {
    for (anim in animations)
    {
      addAtlasAnimation(target, anim);
    }
  }

  /**
   * Combine two FlxFramesCollection objects into one.
   * @param a The first FlxFramesCollection
   * @param b The second FlxFramesCollection
   * @return FlxFramesCollection The combined FlxFramesCollection
   */
  public static function combineFramesCollections(a:FlxFramesCollection, b:FlxFramesCollection):FlxFramesCollection
  {
    @:nullSafety(Off)
    var result:FlxFramesCollection = new FlxFramesCollection(null, ATLAS, null);

    for (frame in a.frames)
    {
      result.pushFrame(frame);
    }
    for (frame in b.frames)
    {
      result.pushFrame(frame);
    }

    return result;
  }
}
