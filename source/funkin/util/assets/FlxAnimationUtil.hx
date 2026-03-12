package funkin.util.assets;

import flixel.FlxSprite;
import funkin.graphics.FunkinSprite;
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

    var frameRate:Int = anim.frameRate ?? 24;
    var looped:Bool = anim.looped ?? false;
    var flipX:Bool = anim.flipX ?? false;
    var flipY:Bool = anim.flipY ?? false;

    if (anim.frameIndices != null && anim.frameIndices.length > 0)
    {
      target.animation.addByIndices(anim.name, anim.prefix, anim.frameIndices, '', frameRate, looped, flipX, flipY);
    }
    else
    {
      target.animation.addByPrefix(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
    }
  }

  /**
   * Properly adds an animation to a texture atlas sprite based on the provided animation data.
   */
  public static function addTextureAtlasAnimation(target:FunkinSprite, anim:AnimationData):Void
  {
    if (!target.isAnimate) return;
    if (anim.prefix == null) return;

    var frameRate:Int = anim.frameRate ?? 24;
    var looped:Bool = anim.looped ?? false;
    var flipX:Bool = anim.flipX ?? false;
    var flipY:Bool = anim.flipY ?? false;
    var animType:String = anim.animType ?? "framelabel";

    if (anim.frameIndices != null && anim.frameIndices.length > 0)
    {
      switch (animType)
      {
        case "framelabel":
          target.anim.addByFrameLabelIndices(anim.name, anim.prefix, anim.frameIndices, frameRate, looped, flipX, flipY);
        case "symbol":
          target.anim.addBySymbolIndices(anim.name, anim.prefix, anim.frameIndices, frameRate, looped, flipX, flipY);
      }
    }
    else
    {
      switch (animType)
      {
        case "framelabel":
          target.anim.addByFrameLabel(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
        case "symbol":
          target.anim.addBySymbol(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
      }
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
   * Properly adds multiple animations to a texture atlas sprite based on the provided animation data.
   */
  public static function addTextureAtlasAnimations(target:FunkinSprite, animations:Array<AnimationData>):Void
  {
    for (anim in animations)
    {
      addTextureAtlasAnimation(target, anim);
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
