package funkin.graphics.adobeanimate;

import flixel.util.FlxSignal.FlxTypedSignal;
import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.math.FlxPoint;
import animate.internal.Frame;
import animate.FlxAnimateFrames.FlxAnimateSettings;

/**
 * A sprite which provides convenience functions for rendering a texture atlas with animations.
 */
@:nullSafety
class FlxAtlasSprite extends FlxAnimate
{
  /**
   * Signal dispatched when an animation advances to the next frame.
   */
  public var onAnimationFrame:FlxTypedSignal<String->Int->Void> = new FlxTypedSignal();

  /**
   * Signal dispatched when a non-looping animation finishes playing.
   */
  public var onAnimationComplete:FlxTypedSignal<String->Void> = new FlxTypedSignal();

  /**
   * Signal dispatched when a looping animation finishes playing.
   */
  public var onAnimationLoop:FlxTypedSignal<String->Void> = new FlxTypedSignal();

  var currentAnimation:String = '';

  var canPlayOtherAnims:Bool = true;

  public function new(x:Float, y:Float, ?path:String, ?settings:FlxAnimateSettings)
  {
    if (path == null)
    {
      throw 'Null path specified for FlxAtlasSprite!';
    }

    // Validate asset path.
    if (!Assets.exists('${path}/Animation.json'))
    {
      throw 'FlxAtlasSprite does not have an Animation.json file at the specified path (${path})';
    }

    super(x, y, path, settings);

    this.anim.onFinish.add(_onAnimationComplete);
    this.anim.onFrameChange.add(_onAnimationFrame);
    this.anim.onLoop.add(_onAnimationLoop);
  }

  /**
   * Gets a list of frames that have a label of any kind.
   * @param layer A specific layer to get the list. if set to `null`, it'll get a list from every layer.
   */
  public function getFrameLabels():Array<String>
  {
    var foundLabels:Array<String> = [];
    var mainTimeline = this.anim.getDefaultTimeline();

    for (layer in mainTimeline.layers)
    {
      @:nullSafety(Off)
      for (frame in layer.frames)
      {
        if (frame.name.rtrim() != '')
        {
          foundLabels.push(frame.name);
        }
      }
    }

    return foundLabels;
  }

  /**
   * Gets a frame label by its name.
   * @param name The name of the frame label to retrieve.
   * @return The frame label, or null if it doesn't exist.
   */
  public function getFrameLabel(name:String):Null<Frame>
  {
    var mainTimeline = this.anim.getDefaultTimeline();
    for (layer in mainTimeline.layers)
    {
      @:nullSafety(Off)
      for (frame in layer.frames)
      {
        if (frame.name == name)
        {
          return frame;
        }
      }
    }
    return null;
  }

  /**
   * @return A list of all the animations this sprite has available.
   */
  public function listAnimations():Array<String>
  {
    return getFrameLabels();
  }

  /**
   * Checks if the atlas has a specific animation.
   *
   * If the animation exists as a symbol or frame label, but
   * hasn't been added yet, it will be added automatically.
   *
   * @param id A string ID of the animation.
   * @return Whether the animation was found on this sprite.
   */
  public function hasAnimation(id:String):Bool
  {
    var frameLabels:Array<String> = listAnimations();
    var symbols:Array<String> = this.library.dictionary.keys().array();

    if (anim.getByName(id) == null)
    {
      if (frameLabels.contains(id))
      {
        // Animation exists as a frame label but wasn't added, so we add it
        anim.addByFrameLabel(id, id, 24, false);
        return true;
      }
      else if (symbols.contains(id))
      {
        // Animation exists as a symbol but wasn't added, so we add it
        anim.addBySymbol(id, id, 24, false);
        return true;
      }
    }
    else
    {
      return true;
    }

    return false;
  }

  /**
   * Returns the first symbol in the atlas.
   * @param
   */
  public function getFirstSymbol():String
  {
    var symbols:Array<String> = this.library.dictionary.keys().array();
    if (symbols.length > 0) return symbols[0];
    return '';
  }

  public function cleanupAnimation(_:String):Void
  {
    canPlayOtherAnims = true;
    this.anim.pause();
  }

  function _onAnimationFrame(animName:String, frameNumber:Int, frameIndex:Int):Void
  {
    if (currentAnimation != null)
    {
      onAnimationFrame.dispatch(currentAnimation, frameNumber);
    }
  }

  function _onAnimationComplete(animName:String):Void
  {
    if (currentAnimation != null)
    {
      onAnimationComplete.dispatch(currentAnimation);
    }
    else
    {
      onAnimationComplete.dispatch('');
    }
  }

  function _onAnimationLoop(animationName:String):Void
  {
    if (currentAnimation != null)
    {
      onAnimationLoop.dispatch(currentAnimation);
    }
    else
    {
      onAnimationLoop.dispatch('');
    }
  }

  /**
   * @return The current animation being played.
   */
  public function getCurrentAnimation():String
  {
    return this.currentAnimation;
  }

  public var ignoreExclusionPref:Array<String> = [];

  /**
   * Plays an animation.
   * @param id A string ID of the animation to play.
   * @param restart Whether to restart the animation if it is already playing.
   * @param ignoreOther Whether to ignore all other animation inputs, until this one is done playing
   * @param loop Whether to loop the animation
   * @param startFrame The frame to start the animation on
   * NOTE: `loop` and `ignoreOther` are not compatible with each other!
   */
  public function playAnimation(id:String, restart:Bool = false, ignoreOther:Bool = false, loop:Bool = false, startFrame:Int = 0):Void
  {
    // Skip if not allowed to play animations.
    if ((!canPlayOtherAnims))
    {
      if (this.currentAnimation == id && restart) {}
      else if (ignoreExclusionPref != null && ignoreExclusionPref.length > 0)
      {
        var detected:Bool = false;
        for (entry in ignoreExclusionPref)
        {
          if (StringTools.startsWith(id, entry))
          {
            detected = true;
            break;
          }
        }
        if (!detected) return;
      }
      else
        return;
    }

    if (anim == null) return;

    // Try to use the first symbol in the animation if one exists.
    if (id == null || id == '') id = getFirstSymbol();

    if (!hasAnimation(id))
    {
      // Skip if the animation doesn't exist
      trace('Animation ' + id + ' not found');
      return;
    }

    // Prevent other animations from playing if `ignoreOther` is true.
    if (ignoreOther) canPlayOtherAnims = false;

    this.currentAnimation = id;

    this.anim.play(id, restart, false, startFrame);
    this.anim.curAnim.looped = loop;
  }

  /**
   * Returns true if the animation has finished playing.
   * @return Whether the animation has finished playing.
   */
  public function isAnimationFinished():Bool
  {
    return this.anim.finished;
  }

  /**
   * Stops the current animation.
   */
  public function stopAnimation():Void
  {
    if (this.currentAnimation == null) return;

    this.anim.stop();
  }

  var prevFrames:Map<Int, FlxFrame> = [];

  public function replaceFrameGraphic(index:Int, ?graphic:FlxGraphicAsset):Void
  {
    var cond = false;

    if (graphic == null) cond = true;
    else
    {
      if ((graphic is String)) cond = !Assets.exists(graphic)
      else
        cond = false;
    }
    if (cond)
    {
      var prevFrame:Null<FlxFrame> = prevFrames.get(index);
      if (prevFrame == null) return;

      prevFrame.copyTo(frames.getByIndex(index));
      return;
    }

    var prevFrame:FlxFrame = prevFrames.get(index) ?? frames.getByIndex(index).copyTo();
    prevFrames.set(index, prevFrame);

    @:nullSafety(Off) // TODO: Remove this once flixel.system.frontEnds.BitmapFrontEnd has been null safed
    var frame = FlxG.bitmap.add(graphic).imageFrame.frame;
    frame.copyTo(frames.getByIndex(index));

    // Additional sizing fix.
    @:privateAccess
    if (true)
    {
      var frame = frames.getByIndex(index);
      frame.tileMatrix[0] = prevFrame.frame.width / frame.frame.width;
      frame.tileMatrix[3] = prevFrame.frame.height / frame.frame.height;
    }
  }

  public override function destroy():Void
  {
    for (prevFrameId in prevFrames.keys())
    {
      replaceFrameGraphic(prevFrameId, null);
    }

    super.destroy();
  }
}
