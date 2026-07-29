package funkin.ui.modmenu;

import funkin.graphics.FunkinSprite;
import flixel.util.FlxTimer;

/**
 * The sparks that appear in the Mod Menu.
 * Can play random animations.
 */
@:nullSafety
class ModMenuSparks extends FunkinSprite
{
  var _timer:FlxTimer = new FlxTimer();
  var _previousAnimation:String = '';
  var _randomAnimations:Array<String> = [];

  public function new()
  {
    super();

    this.visible = false;

    loadTextureAtlas('ui/mods/sparks', {
      applyStageMatrix: true
    });

    loadAnimations();
    startTimer();

    animation.onFinish.add((name:String) ->
    {
      if (_randomAnimations.contains(name))
      {
        startTimer();
      }

      this.visible = false;
    });
  }

  /**
   * Starts the electrocution animation.
   * This loops indefinitely until `endElectrocution()` is called.
   */
  public function startElectrocution():Void
  {
    if (_timer.active) _timer.cancel();

    this.visible = true;

    animation.play('electrocution');
  }

  /**
   * Ends the electrocution animation.
   */
  public function endElectrocution():Void
  {
    animation.play('end');
  }

  /**
   * Plays a random spark animation.
   */
  public function playRandomAnimation():Void
  {
    var randomAnimation:String = getRandomAnimation();

    this.visible = true;
    animation.play(randomAnimation);

    _previousAnimation = randomAnimation;
  }

  function startTimer():Void
  {
    _timer.start(FlxG.random.int(6, 20), (tmr:FlxTimer) ->
    {
      playRandomAnimation();
    });
  }

  function getRandomAnimation():String
  {
    var randomAnimation:String = _randomAnimations[FlxG.random.int(0, _randomAnimations.length - 1)];

    // Retry if the animation is the same as the previous one
    // or if it doesn't exactly have a number in the name.
    if (randomAnimation == _previousAnimation) return getRandomAnimation();

    return randomAnimation;
  }

  function loadAnimations():Void
  {
    for (i in 1...12)
    {
      anim.addByFrameLabel('$i', 'spark $i', 24, false);

      _randomAnimations.push('$i');
    }

    anim.addByFrameLabel('electrocution', 'electrocution', 24);
    anim.addByFrameLabel('end', 'end', 24, false);
  }
}
