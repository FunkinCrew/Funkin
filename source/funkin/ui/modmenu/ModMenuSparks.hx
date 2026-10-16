package funkin.ui.modmenu;

import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinSprite;

/**
 * The sparks that appear in the Mod Menu.
 * Can play random animations.
 */
@:nullSafety
class ModMenuSparks extends FunkinSprite
{
  /**
   * The point in the shock sound in milliseconds that plays when the sparks end.
   *
   * 83 / 24 = The amount of frames the electrocution sequence lasts at 24 FPS.
   */
  public static final SHOCK_SOUND_END_TIME:Float = (83 / 24) * 1000;

  var _timer:FlxTimer = new FlxTimer();
  var _previousAnimation:String = '';
  var _randomAnimations:Array<String> = [];
  var shockSound:Null<FunkinSound> = null;

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

    shockSound = FunkinSound.playOnce(Paths.sound('ui/mods/sounds/sparks/electrocution').toString());
  }

  /**
   * Ends the electrocution animation.
   */
  public function endElectrocution():Void
  {
    animation.play('end');

    if (shockSound != null)
    {
      shockSound.time = SHOCK_SOUND_END_TIME;
    }
  }

  /**
   * Plays a random spark animation.
   */
  public function playRandomAnimation():Void
  {
    var randomAnimation:String = getRandomAnimation();

    this.visible = true;
    animation.play(randomAnimation);

    FunkinSound.playOnce(Paths.sound('ui/mods/sounds/sparks/spark-${randomAnimation}').toString());

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

  override public function destroy():Void
  {
    super.destroy();

    if (_timer.active) _timer.cancel();
    if (shockSound != null) shockSound.destroy();
  }
}

