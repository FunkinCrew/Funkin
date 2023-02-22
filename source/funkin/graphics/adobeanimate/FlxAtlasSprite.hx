package funkin.graphics.adobeanimate;

import flixel.util.FlxSignal.FlxTypedSignal;
import flxanimate.FlxAnimate;
import flxanimate.FlxAnimate.Settings;
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
      ShowPivot: #if debug true #else false #end,
      Antialiasing: true,
      ScrollFactor: new FlxPoint(1, 1),
      // Offset: new FlxPoint(0, 0), // This is just FlxSprite.offset
    };

  /**
   * Signal dispatched when an animation finishes playing.
   */
  public var onAnimationFinish:FlxTypedSignal<String->Void> = new FlxTypedSignal<String->Void>();

  var currentAnimation:String;

  var canPlayOtherAnims:Bool = true;

  public function new(x:Float, y:Float, path:String)
  {
    super(x, y, path);

    if (this.anim.curInstance == null)
    {
      throw 'FlxAtlasSprite not initialized properly. Are you sure the path (${path}) exists?';
    }

    this.antialiasing = true;

    onAnimationFinish.add(cleanupAnimation);

    // This defaults the sprite to play the first animation in the atlas,
    // then pauses it. This ensures symbols are intialized properly.
    this.anim.play('');
    this.anim.pause();
  }

  /**
   * @return A list of all the animations this sprite has available.
   */
  public function listAnimations():Array<String>
  {
    return this.anim.getFrameLabels();
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
   * Plays an animation.
   * @param id A string ID of the animation to play.
   * @param restart Whether to restart the animation if it is already playing.
   * @param ignoreOther Whether to ignore all other animation inputs, until this one is done playing
   */
  public function playAnimation(id:String, ?restart:Bool = false, ?ignoreOther:Bool = false):Void
  {
    // Skip if not allowed to play animations.
    if ((!canPlayOtherAnims && !ignoreOther)) return;

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
        anim.play('', false, false);
      }
    }

    // Skip if the animation doesn't exist
    if (!hasAnimation(id))
    {
      trace('Animation ' + id + ' not found');
      return;
    }

    // Stop the current animation if it is playing.
    // This includes removing existing frame callbacks.
    if (this.currentAnimation != null) this.stopAnimation();

    // Add a callback to ensure `onAnimationFinish` is dispatched.
    addFrameCallback(getNextFrameLabel(id), function() {
      trace('Animation finished: ' + id);
      onAnimationFinish.dispatch(id);
    });

    // Prevent other animations from playing if `ignoreOther` is true.
    if (ignoreOther) canPlayOtherAnims = false;

    // Move to the first frame of the animation.
    goToFrameLabel(id);
    this.currentAnimation = id;
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

  inline function goToFrameLabel(label:String):Void
  {
    this.anim.goToFrameLabel(label);
  }

  inline function getNextFrameLabel(label:String):String
  {
    return listAnimations()[(getLabelIndex(label) + 1) % listAnimations().length];
  }

  inline function getLabelIndex(label:String):Int
  {
    return listAnimations().indexOf(label);
  }

  inline function goToFrameIndex(index:Int):Void
  {
    this.anim.curFrame = index;
  }

  public function cleanupAnimation(_:String):Void
  {
    canPlayOtherAnims = true;
    this.currentAnimation = null;
    this.anim.stop();
  }
}
