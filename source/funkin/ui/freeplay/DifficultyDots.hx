package funkin.ui.freeplay;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import funkin.ui.freeplay.FreeplayState;

class DifficultyDots extends FlxTypedSpriteGroup<DifficultyDot>
{
  public var distance:Int = 30;

  public var currentDifficultyList:Array<String> = [];
  public var currentDifficultyDots:Map<String, DifficultyDot> = new Map();
  public var usedDots:Array<DifficultyDot> = [];

  var prevDifficulty:String;

  public function new(x:Float, y:Float)
  {
    super(x, y);
  }

  /**
   * Creating all difficulty dots for freeplay.
   * @param diffArray list of difficulties
   */
  public function loadDots(diffArray:Array<String>):Void
  {
    currentDifficultyList = diffArray;

    for (i in 0...currentDifficultyList.length)
    {
      if (!currentDifficultyDots.exists(currentDifficultyList[i]))
      {
        final dot:DifficultyDot = generateDifficultyDot(currentDifficultyList[i], i);
        dot.visible = false;
        this.add(dot);
        currentDifficultyDots.set(currentDifficultyList[i], dot);
      }
      else
        trace('[WARNING] Attemp creating double difficulty dot: ${currentDifficultyList[i]}');
    }

    // Add forced erected inactive dots
    erectCheck();
  }

  public function regenDots(diffArray:Array<String>):Void
  {
    currentDifficultyList = diffArray;

    for (dot in usedDots)
    {
      dot.visible = dot.erected;
      // In case we had to use one of ERECT dots as INACTIVE previously
      dot.type = (dot.erected ? ERECT : NORMAL);
    }
    // Clear array form previously used dots :steamhappy:
    usedDots = [];

    for (diff in currentDifficultyList)
    {
      var dot:DifficultyDot = currentDifficultyDots.get(diff);
      // If there's no dot for requierd difficulty (huh)
      if (dot == null) add(dot = generateDifficultyDot(diff, usedDots.length));
      usedDots.push(dot);
    }

    // Add forced erected inactive dots
    erectCheck();
  }

  public function refreshDots(?daSongData:FreeplayState.FreeplaySongData, ?currDiffString:String):Void
  {
    final totalRows:Int = Math.ceil(usedDots.length / Constants.DEFAULT_FREEPLAY_DOTS_IN_ROW);

    var _row:Int = 0;
    var _col:Float = 0;
    var _curDotSpr:DifficultyDot = null;
    for (i in 0...usedDots.length)
    {
      _curDotSpr = usedDots[i];

      // Escape plan F UCK
      if (_curDotSpr == null) continue;

      _curDotSpr.important = false;
      _curDotSpr.visible = true;

      _row = Math.floor(i / Constants.DEFAULT_FREEPLAY_DOTS_IN_ROW);
      _col = i % Constants.DEFAULT_FREEPLAY_DOTS_IN_ROW;

      final dotsInCurrentRow:Int = (_row == totalRows - 1) ? (usedDots.length - _row * Constants.DEFAULT_FREEPLAY_DOTS_IN_ROW) : Constants.DEFAULT_FREEPLAY_DOTS_IN_ROW;

      final rowOffset:Float = (dotsInCurrentRow - 1) * distance / 2;
      final xPos:Float = FreeplayState.DEFAULT_DOTS_GROUP_POS[0] - rowOffset + _col * distance;

      _curDotSpr.x = (FreeplayState.CUTOUT_WIDTH * FreeplayState.DJ_POS_MULTI) + xPos;
      _curDotSpr.y = FreeplayState.DEFAULT_DOTS_GROUP_POS[1] + distance * _row;

      if (daSongData?.isDifficultyNew(_curDotSpr.difficultyId) && _curDotSpr.erected) _curDotSpr.important = true;

      _curDotSpr.updateState(_curDotSpr.type == INACTIVE ? INACTIVE : (_curDotSpr.erected ? ERECT : NORMAL),
        (currDiffString == _curDotSpr.difficultyId) ? SELECTED : ((prevDifficulty == _curDotSpr.difficultyId) ? DESELECTING : DESELECTED));
    }
    prevDifficulty = currDiffString;
  }

  public function fade(fadeIn:Bool):Void
  {
    for (i in 0...members.length)
      fadeIn ? members[i].fadeIn() : members[i].fadeOut();
  }

  // Generates new difficulty dot from given parameters.
  private inline function generateDifficultyDot(diff:String, index:Int):DifficultyDot
  {
    return new DifficultyDot(diff, index, Constants.DEFAULT_DIFFICULTY_LIST_ERECT.contains(diff));
  }

  private function erectCheck():Void // Bro...
  {
    for (diff in Constants.DEFAULT_DIFFICULTY_LIST_ERECT)
    {
      if (!currentDifficultyList.contains(diff))
      {
        currentDifficultyList.push(diff);

        var dot:DifficultyDot = currentDifficultyDots.get(diff);
        if (dot == null) add(dot = generateDifficultyDot(diff, usedDots.length));
        dot.type = INACTIVE;
        usedDots.push(dot);
      }
    }
  }
}

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

  /**
   * Erected or not, dum dum.
   */
  public var erected:Bool;

  public var important:Bool = false;
  public var pulseColor:Bool = false;

  public var type:DotType = NORMAL;
  public var state:DotState = DESELECTED;

  // 0 - deselected, 1 - selected, 2 - pulse color
  var normalColors:Array<FlxColor> = [0xFF484848, 0xFFFFFFFF, 0xFF919191, 0xFFC9C9C9];
  var nightColors:Array<FlxColor> = [0xFF34296A, 0xFFC28AFF, 0xFF8A58D0, 0xFFFFB1DC];

  public var dotSpr:FlxSprite;
  public var pulseSpr:FlxSprite;

  var colorTween:FlxTween;
  var fadeTween:FlxTween;

  public function new(id:String, num:Int, erected:Bool)
  {
    super(0, 0);

    difficultyId = id;
    this.erected = erected;
    type = this.erected ? ERECT : NORMAL;

    dotSpr = new FlxSprite().loadGraphic(Paths.image('freeplay/seperator'));
    add(dotSpr);

    dotSpr.alpha = 0;

    pulseSpr = new FlxSprite(0, 0);
    pulseSpr.frames = Paths.getSparrowAtlas('freeplay/dotPulse');
    pulseSpr.animation.addByPrefix('pulse', 'pulse', 12, true);
    pulseSpr.animation.play('pulse', true, false, FlxMath.wrap(num * -2, 0, 11));
    pulseSpr.visible = false;
    add(pulseSpr);

    pulseSpr.animation.onFrameChange.add((animName:String, frameNumber:Int, frameIndex:Int) -> interpolateColor());
  }

  public function interpolateColor():Void
  {
    if (type == INACTIVE) return;

    if (state == DESELECTING)
    {
      if (colorTween?.finished && pulseSpr.animation.curAnim.curFrame == 0) pulseColor = true;
    }
    else
    {
      if (pulseSpr.animation.curAnim.curFrame == 0) pulseColor = true;
    }

    if (!important || !pulseColor) return;

    switch (type)
    {
      case NORMAL:
        switch (state)
        {
          case SELECTED:
            // slightly different logic here, a pulseSpr cant go lighter than fully white, so we gotta make its default color darker
            color = FlxColor.interpolate(normalColors[1], normalColors[3], pulseSpr.animation.curAnim.curFrame / pulseSpr.animation.curAnim.numFrames);
          default:
            color = FlxColor.interpolate(normalColors[2], normalColors[0], pulseSpr.animation.curAnim.curFrame / pulseSpr.animation.curAnim.numFrames);
        }
      case ERECT:
        switch (state)
        {
          case SELECTED:
            color = FlxColor.interpolate(nightColors[3], nightColors[1], pulseSpr.animation.curAnim.curFrame / pulseSpr.animation.curAnim.numFrames);
          default:
            color = FlxColor.interpolate(nightColors[2], nightColors[0], pulseSpr.animation.curAnim.curFrame / pulseSpr.animation.curAnim.numFrames);
        }
      default:
        trace('trying to interpolate color on inavlid dot state!');
    }
  }

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

    dotSpr.x = x;
    dotSpr.y = y;

    pulseSpr.x = (dotSpr.x + (dotSpr.width / 2)) - (pulseSpr.width / 2);
    pulseSpr.y = (dotSpr.y + (dotSpr.height / 2)) - (pulseSpr.height / 2);

    pulseColor = false;

    pulseSpr.visible = type != INACTIVE && important;

    switch (type)
    {
      case NORMAL:
        if (fadeTween?.finished) dotSpr.alpha = 1;

        switch (state)
        {
          case SELECTED:
            color = normalColors[1];

          case DESELECTING:
            colorTween = FlxTween.color(this, 0.5, normalColors[1], normalColors[0], {ease: FlxEase.quartOut});

          case DESELECTED:
            color = normalColors[0];

          default:
            trace('freeplay dotSpr state is invalid!');
        }

      case ERECT:
        if (fadeTween?.finished) dotSpr.alpha = 1;

        switch (state)
        {
          case SELECTED:
            color = nightColors[1];

          case DESELECTING:
            colorTween = FlxTween.color(this, 0.5, nightColors[1], nightColors[0], {ease: FlxEase.quartOut});

          case DESELECTED:
            color = nightColors[0];

          default:
            trace('freeplay dotSpr state is invalid!');
        }

      case INACTIVE:
        color = 0xFF121212;
        if (fadeTween?.finished) dotSpr.alpha = 0.33;

      default:
        trace('freeplay dotSpr type is invalid!');
    }
  }

  public function fadeIn():Void
  {
    dotSpr.alpha = 0;
    dotSpr.visible = true;

    fadeTween?.cancel();
    fadeTween = FlxTween.tween(dotSpr, {alpha: (type == INACTIVE ? 0.33 : .5)}, 0.5, {ease: FlxEase.quartOut});
  }

  public function fadeOut():Void
  {
    fadeTween?.cancel();

    fadeTween = FlxTween.tween(dotSpr, {alpha: 0}, 0.25, {ease: FlxEase.quartOut});
    pulseSpr.alpha = 0;
  }

  override public inline function toString():String
    return 'DiffDot(diff=$difficultyId)';
}
