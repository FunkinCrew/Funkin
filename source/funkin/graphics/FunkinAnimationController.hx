package funkin.graphics;

import animate.FlxAnimateController;
import flixel.FlxG;
import funkin.Conductor;

@:access(funkin.graphics.FunkinSprite)
class FunkinAnimationController extends FlxAnimateController
{
  /**
   * The sprite that this animation controller is attached to.
   */
  var _parentSprite:FunkinSprite;

  /**
   * Whether this animation controller should sync its animations to the Conductor's song position.
   */
  public var shouldUseConductorSync:Bool = false;

  public function new(sprite:FunkinSprite)
  {
    super(sprite);
    _parentSprite = sprite;
  }

  override function set_frameIndex(frame:Int):Int
  {
    _parentSprite._renderTextureDirty = true;
    return super.set_frameIndex(frame);
  }

  var lastSongPositionMs:Null<Float> = null;

  override function update(elapsed:Float):Void
  {
    if (!shouldUseConductorSync)
    {
      lastSongPositionMs = null;
      super.update(elapsed);
      return;
    }

    if (curAnim == null || Conductor.instance == null) return;

    var songPositionMs = Conductor.instance.songPosition;

    if (lastSongPositionMs == null)
    {
      lastSongPositionMs = songPositionMs;
      return;
    }

    var deltaMs = songPositionMs - lastSongPositionMs;
    lastSongPositionMs = songPositionMs;

    if (deltaMs <= 0) return;

    var adjustedElapsed = (deltaMs / 1000.0) * (timeScale * FlxG.animationTimeScale);
    curAnim.update(adjustedElapsed);
  }

  /**
   * We override `FlxAnimationController`'s `play` method to account for texture atlases.
   */
  override public function play(animName:String, force = false, reversed = false, frame = 0):Void
  {
    if (animName == null || animName == '') animName = _parentSprite.getDefaultSymbol();

    if (!_parentSprite.hasAnimation(animName))
    {
      // Skip if the animation doesn't exist
      trace('Animation ${animName} does not exist!');
      return;
    }

    super.play(animName, force, reversed, frame);

    if (shouldUseConductorSync && Conductor.instance != null && curAnim != null) lastSongPositionMs = Conductor.instance.songPosition;
  }
}
