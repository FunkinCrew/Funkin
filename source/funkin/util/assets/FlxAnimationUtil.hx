package funkin.util.assets;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.data.animation.AnimationData;

class FlxAnimationUtil
{
  /**
   * Properly adds an animation to a sprite based on the provided animation data.
   */
  public static function addAtlasAnimation(target:FlxSprite, anim:AnimationData)
  {
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
  public static function addAtlasAnimations(target:FlxSprite, animations:Array<AnimationData>)
  {
    for (anim in animations)
    {
      addAtlasAnimation(target, anim);
    }
  }

  public static function combineFramesCollections(a:FlxFramesCollection, b:FlxFramesCollection):FlxFramesCollection
  {
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
