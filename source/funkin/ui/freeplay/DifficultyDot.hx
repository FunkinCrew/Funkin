package funkin.ui.freeplay;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;

enum DotType
{
  NORMAL;
  ERECT;
  INACTIVE;
}

enum DotState
{
  DESELECTING;

  DESELECTED;
  SELECTED;
}

class DifficultyDot extends FlxSpriteGroup
{
  /**
   * The difficulty id which this dot represents.
   */
  public var difficultyId:String;

  public var type:DotType = NORMAL;
  public var state:DotState = DESELECTED;

  // 0 - deselected, 1 - selected, 2 - pulse color
  var normalColors:Array<FlxColor> = [0xFF484848, 0xFFFFFFFF, 0xFF919191, 0xFFC9C9C9];
  var nightColors:Array<FlxColor> = [0xFF34296A, 0xFFC28AFF, 0xFF8A58D0, 0xFFFFB1DC];

  public var important:Bool = false;

  var pulseColor = false;

  public var dot:FlxSprite;
  public var pulse:FlxSprite;

  // var newColors:Array<FlxColor> = [0xFFE86D09, 0xFFE54400, 0xFFE83509, 0xFFF3D48A, 0xFFFAF269, 0xFFF9F0C2];

  public function new(id:String, num:Int)
  {
    super(0, 0);

    difficultyId = id;

    dot = new FlxSprite().loadGraphic(Paths.image('freeplay/seperator'));
    add(dot);

    dot.alpha = 0;

    pulse = new FlxSprite(0, 0);
    pulse.frames = Paths.getSparrowAtlas('freeplay/dotPulse');
    pulse.animation.addByPrefix('pulse', 'pulse', 12, true);
    pulse.animation.play('pulse', true, false, FlxMath.wrap(num * -2, 0, 11));
    pulse.visible = false;
    add(pulse);

    pulse.animation.onFrameChange.add(function(animName:String, frameNumber:Int, frameIndex:Int) {
      interpolateColor();
    });
  }

  var colorTween:FlxTween;
  var fadeTween:FlxTween;

  /**
   * Interpolates between 2 colors to make the dot pulse in time with the pulse's animation.
   * The colors are based on the current state of the dot.
   */
  public function interpolateColor():Void
  {
    // pulses should only start AFTER any tweens have finished, so the color doesnt jump
    if (state == DESELECTING)
    {
      if (colorTween?.finished && pulse.animation.curAnim.curFrame == 0) pulseColor = true;
    }
    else
    {
      if (pulse.animation.curAnim.curFrame == 0) pulseColor = true;
    }

    if (!important || !pulseColor) return;

    switch (type)
    {
      case NORMAL:
        switch (state)
        {
          case SELECTED:
            // slightly different logic here, a pulse cant go lighter than fully white, so we gotta make its default color darker
            color = FlxColor.interpolate(normalColors[1], normalColors[3], pulse.animation.curAnim.curFrame / pulse.animation.curAnim.numFrames);
          default:
            color = FlxColor.interpolate(normalColors[2], normalColors[0], pulse.animation.curAnim.curFrame / pulse.animation.curAnim.numFrames);
        }
      case ERECT:
        switch (state)
        {
          case SELECTED:
            color = FlxColor.interpolate(nightColors[3], nightColors[1], pulse.animation.curAnim.curFrame / pulse.animation.curAnim.numFrames);
          default:
            color = FlxColor.interpolate(nightColors[2], nightColors[0], pulse.animation.curAnim.curFrame / pulse.animation.curAnim.numFrames);
        }
      default:
        trace('trying to interpolate color on inavlid dot state!');
    }
  }

  /**
   * Updates the current visuals of the dot.
   * @param _type Changes the overall appearance of the dot.
   * @param _state Changes how the dot will react over time.
   */
  public function updateState(_type:DotType, _state:DotState):Void
  {
    type = _type;
    state = _state;

    if (colorTween != null)
    {
      colorTween.cancel();
    }
    if (fadeTween != null)
    {
      fadeTween.cancel();
    }

    dot.x = x;
    dot.y = y;

    pulse.x = (dot.x + (dot.width / 2)) - (pulse.width / 2);
    pulse.y = (dot.y + (dot.height / 2)) - (pulse.height / 2);

    pulseColor = false;

    pulse.visible = important;

    switch (type)
    {
      case NORMAL:
        if (fadeTween?.finished) dot.alpha = 1;

        switch (state)
        {
          case SELECTED:
            color = normalColors[1];

          case DESELECTING:
            colorTween = FlxTween.color(this, 0.5, normalColors[1], normalColors[0], {ease: FlxEase.quartOut});

          case DESELECTED:
            color = normalColors[0];

          default:
            trace('freeplay dot state is invalid!');
        }

      case ERECT:
        if (fadeTween?.finished) dot.alpha = 1;

        switch (state)
        {
          case SELECTED:
            color = nightColors[1];

          case DESELECTING:
            colorTween = FlxTween.color(this, 0.5, nightColors[1], nightColors[0], {ease: FlxEase.quartOut});

          case DESELECTED:
            color = nightColors[0];

          default:
            trace('freeplay dot state is invalid!');
        }

      case INACTIVE:
        color = 0xFF121212;
        if (fadeTween?.finished) dot.alpha = 0.33;

      default:
        trace('freeplay dot type is invalid!');
    }
  }

  /**
   * Fade in the dot. Used when entering Freeplay.
   */
  public function fadeIn():Void
  {
    dot.alpha = 0;
    dot.visible = true;

    if (fadeTween != null)
    {
      fadeTween.cancel();
    }

    if (type == INACTIVE)
    {
      fadeTween = FlxTween.tween(dot, {alpha: 0.33}, 0.5, {ease: FlxEase.quartOut});
    }
    else
    {
      fadeTween = FlxTween.tween(dot, {alpha: 1}, 0.5, {ease: FlxEase.quartOut});
    }
  }

  /**
   * Fade out the dot. Used when leaving Freeplay.
   */
  public function fadeOut():Void
  {
    if (fadeTween != null)
    {
      fadeTween.cancel();
    }

    fadeTween = FlxTween.tween(dot, {alpha: 0}, 0.25, {ease: FlxEase.quartOut});
    pulse.alpha = 0;
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
  }
}
