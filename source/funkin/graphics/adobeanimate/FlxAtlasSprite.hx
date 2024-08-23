package funkin.graphics.adobeanimate;

import flixel.util.FlxSignal.FlxTypedSignal;
import flxanimate.FlxAnimate;
import flxanimate.FlxAnimate.Settings;
import flxanimate.frames.FlxAnimateFrames;
import haxe.extern.EitherType;
import flixel.graphics.frames.FlxFrame;
import flixel.system.FlxAssets.FlxGraphicAsset;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import flixel.math.FlxPoint;

/**
 * A sprite which provides convenience functions for rendering a texture atlas with animations.
 */
class FlxAtlasSprite extends FlxAnimate
{
  static final SETTINGS:Settings =
    {
      // ?ButtonSettings:Map<String, flxanimate.animate.FlxAnim.ButtonSettings>,
      FrameRate: 24.0,
      Reversed: false,
      // ?OnComplete:Void -> Void,
      ShowPivot: false,
      Antialiasing: true,
      ScrollFactor: null,
      // Offset: new FlxPoint(0, 0), // This is just FlxSprite.offset
    };

  /**
   * Signal dispatched when an animation advances to the next frame.
   */
  public var onAnimationFrame:FlxTypedSignal<String->Int->Void> = new FlxTypedSignal();

  /**
   * Signal dispatched when a non-looping animation finishes playing.
   */
  public var onAnimationComplete:FlxTypedSignal<String->Void> = new FlxTypedSignal();

  /**
   * Signal dispatched when a looping animation finishes playing
   */
  public var onAnimationLoopComplete:FlxTypedSignal<String->Void> = new FlxTypedSignal();

  var currentAnimation:String;

  var canPlayOtherAnims:Bool = true;

  public function new(x:Float, y:Float, ?path:String, ?settings:Settings)
  {
    if (settings == null) settings = SETTINGS;

    if (path == null)
    {
      throw 'Null path specified for FlxAtlasSprite!';
    }

    super(x, y, path, settings);

    if (this.anim.stageInstance == null)
    {
      throw 'FlxAtlasSprite not initialized properly. Are you sure the path (${path}) exists?';
    }

    onAnimationComplete.add(cleanupAnimation);

    // This defaults the sprite to play the first animation in the atlas,
    // then pauses it. This ensures symbols are intialized properly.
    this.anim.play('');
    this.anim.pause();

    this.anim.onComplete.add(_onAnimationComplete);
    this.anim.onFrame.add(_onAnimationFrame);
  }

  /**
   * @return A list of all the animations this sprite has available.
   */
  public function listAnimations():Array<String>
  {
    var mainSymbol = this.anim.symbolDictionary[this.anim.stageInstance.symbol.name];
    if (mainSymbol == null)
    {
      FlxG.log.error('FlxAtlasSprite does not have its main symbol!');
      return [];
    }
    return mainSymbol.getFrameLabels().map(keyFrame -> keyFrame.name).filterNull();
  }

  /**
   * @param id A string ID of the animation.
   * @return Whether the animation was found on this sprite.
   */
  public function hasAnimation(id:String):Bool
  {
    return getLabelIndex(id) != -1;
  }

  /**
   * @return The current animation being played.
   */
  public function getCurrentAnimation():String
  {
    return this.currentAnimation;
  }

  /**
   * `anim.finished` always returns false on looping animations,
   * but this function will return true if we are on the last frame of the looping animation.
   */
  public function isLoopFinished():Bool
  {
    if (this.anim == null) return false;
    if (!this.anim.isPlaying) return false;

    // Reverse animation finished.
    if (this.anim.reversed && this.anim.curFrame == 0) return true;
    // Forward animation finished.
    if (!this.anim.reversed && this.anim.curFrame >= (this.anim.length - 1)) return true;

    return false;
  }

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
    if ((!canPlayOtherAnims && !ignoreOther) || (anim == null)) return;

    if (id == null || id == '') id = this.currentAnimation;

    if (this.currentAnimation == id && !restart)
    {
      if (anim.isPlaying)
      {
        // Skip if animation is already playing.
        return;
      }
      else
      {
        // Resume animation if it's paused.
        anim.play('', restart, false, startFrame);
      }
    }
    else
    {
      // Skip if the animation doesn't exist
      if (!hasAnimation(id))
      {
        trace('Animation ' + id + ' not found');
        return;
      }
    }

    anim.onComplete.removeAll();
    anim.onComplete.add(function() {
      if (loop)
      {
        onAnimationLoopComplete.dispatch(id);
        this.anim.play(id, restart, false, startFrame);
        this.currentAnimation = id;
      }
      else
      {
        onAnimationComplete.dispatch(id);
      }
    });

    // Prevent other animations from playing if `ignoreOther` is true.
    if (ignoreOther) canPlayOtherAnims = false;

    // Move to the first frame of the animation.
    trace('Playing animation $id');
    // FlxG.log.notice('Playing animation $id');
    if (this.anim.symbolDictionary.exists(id) || (this.anim.getByName(id) != null))
    {
      this.anim.play(id, restart, false, startFrame);
    }
    if (getFrameLabelNames().indexOf(id) != -1)
    {
      goToFrameLabel(id);
    }
    anim.curFrame += startFrame;
    this.currentAnimation = id;
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);
  }

  /**
   * Returns true if the animation has finished playing.
   * Never true if animation is configured to loop.
   */
  public function isAnimationFinished():Bool
  {
    return this.anim.finished;
  }

  /**
   * Returns true if the animation has reached the last frame.
   * Can be true even if animation is configured to loop.
   */
  public function isLoopComplete():Bool
  {
    return (anim.reversed && anim.curFrame == 0 || !(anim.reversed) && (anim.curFrame) >= (anim.length - 1));
  }

  /**
   * Stops the current animation.
   */
  public function stopAnimation():Void
  {
    if (this.currentAnimation == null) return;

    this.anim.removeAllCallbacksFrom(getNextFrameLabel(this.currentAnimation));

    goToFrameIndex(0);
  }

  function addFrameCallback(label:String, callback:Void->Void):Void
  {
    var frameLabel = this.anim.getFrameLabel(label);
    frameLabel.add(callback);
  }

  function goToFrameLabel(label:String):Void
  {
    this.anim.goToFrameLabel(label);
  }

  function getFrameLabelNames(?layer:EitherType<Int, String> = null)
  {
    var labels = this.anim.getFrameLabels(layer);
    var array = [];
    for (label in labels)
    {
      array.push(label.name);
    }

    return array;
  }

  function getNextFrameLabel(label:String):String
  {
    return listAnimations()[(getLabelIndex(label) + 1) % listAnimations().length];
  }

  function getLabelIndex(label:String):Int
  {
    return listAnimations().indexOf(label);
  }

  function goToFrameIndex(index:Int):Void
  {
    this.anim.curFrame = index;
  }

  public function cleanupAnimation(_:String):Void
  {
    canPlayOtherAnims = true;
    // this.currentAnimation = null;
    this.anim.pause();
  }

  function _onAnimationFrame(frame:Int):Void
  {
    if (currentAnimation != null)
    {
      onAnimationFrame.dispatch(currentAnimation, frame);
      if (isLoopComplete()) onAnimationLoopComplete.dispatch(currentAnimation);
    }
  }

  function _onAnimationComplete():Void
  {
    if (currentAnimation != null)
    {
      onAnimationComplete.dispatch(currentAnimation);
    }
  }

  var prevFrames:Map<Int, FlxFrame> = [];

  public function replaceFrameGraphic(index:Int, ?graphic:FlxGraphicAsset):Void
  {
    if (graphic == null || !Assets.exists(graphic))
    {
      var prevFrame:Null<FlxFrame> = prevFrames.get(index);
      if (prevFrame == null) return;

      prevFrame.copyTo(frames.getByIndex(index));
      return;
    }

    var prevFrame:FlxFrame = prevFrames.get(index) ?? frames.getByIndex(index).copyTo();
    prevFrames.set(index, prevFrame);

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

  public function getBasePosition():Null<FlxPoint>
  {
    // var stagePos = new FlxPoint(anim.stageInstance.matrix.tx, anim.stageInstance.matrix.ty);
    var instancePos = new FlxPoint(anim.curInstance.matrix.tx, anim.curInstance.matrix.ty);
    var firstElement = anim.curSymbol.timeline?.get(0)?.get(0)?.get(0);
    if (firstElement == null) return instancePos;
    var firstElementPos = new FlxPoint(firstElement.matrix.tx, firstElement.matrix.ty);

    return instancePos + firstElementPos;
  }

  public function getPivotPosition():Null<FlxPoint>
  {
    return anim.curInstance.symbol.transformationPoint;
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
