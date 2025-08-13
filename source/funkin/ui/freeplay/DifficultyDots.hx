package funkin.ui.freeplay;

import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;

class DifficultyDots extends FlxTypedSpriteGroup<DifficultyDot>
{
  public var groupOffset:Float = 14.7;
  public var distance:Int = 30;
  public var shiftAmt:Float = 0; // (distance * amount) / 2;

  // public var daSong:Null<FreeplaySongData> = currentCapsule.freeplayData;
  // final maxDotsPerRow:Int = 8;
  public var currentDifficultyList:Array<String> = [];

  public var usedDots:Array<DifficultyDot> = [];
  public var isActive:Bool = true;

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
    // why we use indexes here um???
    var _erected:Bool = false;
    for (i in 0...currentDifficultyList.length)
    {
      _erected = Constants.DEFAULT_DIFFICULTY_LIST_ERECT.contains(currentDifficultyList[i]);
      final dot:DifficultyDot = new DifficultyDot(currentDifficultyList[i], i, _erected);
      this.add(dot);
      dot.x += FlxG.random.float(-150, 50);
      // trace('Difficulty: ${currentDifficultyList[i]}, erected: $_erected, x: ${dot.x}');
    }
  }

  public function regenDots(diffArray:Array<String>, ?active:Bool = true):Void
  {
    currentDifficultyList = diffArray;
    usedDots = [];

    isActive = active;
    trace(isActive);

    for (dot in members)
    {
      dot.visible = false;
      trace(dot);
      if (currentDifficultyList.contains(dot.difficultyId)) usedDots.push(dot);
    }

    for (dot in usedDots)
      dot.visible = true;
  }

  var prevDotAmount:Int = 0;

  public function refreshDots(index:Int, prevIndex:Int, ?daSongData:funkin.ui.freeplay.FreeplayState.FreeplaySongData):Void
  {
    trace(usedDots);
    trace(daSongData);

    shiftAmt = (distance * usedDots.length) / 2;
    trace('index: $index, prevIndex: $prevIndex');

    if (usedDots.length > Constants.DEFAULT_FREEPLAY_DOTS_IN_ROW) this.x = funkin.ui.freeplay.FreeplayState.DEFAULT_DOTS_GROUP_POS[0]
      - groupOffset * (Constants.DEFAULT_FREEPLAY_DOTS_IN_ROW - 1);
    else
      this.x = funkin.ui.freeplay.FreeplayState.DEFAULT_DOTS_GROUP_POS[0] - groupOffset * (usedDots.length - 1);

    var curRow:Int = 0;
    var curDot:Int = 0;

    for (i in 0...usedDots.length)
    {
      var curDotSpr:DifficultyDot = usedDots[i];
      var targetState:DotState = SELECTED;
      var targetType:DotType = NORMAL;
      if (curDotSpr.erected) targetType = ERECT;
      var diffId:String = curDotSpr.difficultyId;

      curDotSpr.important = false;

      // I could "oneline" this condition too, but i dont wanna hurt your eyes :troll:
      if (i == index)
      {
        targetState = SELECTED;
      }
      else
      {
        targetState = (i == prevIndex) ? DESELECTING : DESELECTED
      }

      curDotSpr.visible = true;
      curDotSpr.x = (funkin.ui.freeplay.FreeplayState.CUTOUT_WIDTH * funkin.ui.freeplay.FreeplayState.DJ_POS_MULTI)
        + ((this.x + (distance * curDot)) - shiftAmt);
      curDotSpr.y = funkin.ui.freeplay.FreeplayState.DEFAULT_DOTS_GROUP_POS[1] + distance * curRow;

      curDot++;

      if (curDot >= Constants.DEFAULT_FREEPLAY_DOTS_IN_ROW)
      {
        curDot = 0;
        curRow++;
      }

      /*if (daSong?.data.hasDifficulty(diffId, daSong?.data.getFirstValidVariation(diffId, currentCharacter)) == false)
        {
          targetType = INACTIVE;
        }
        else
        {
          if (daSongData?.isDifficultyNew(diffId) == true)
            if (targetType == ERECT)
              difficultyDots.group.members[i].important = true;
      }*/

      if (daSongData?.isDifficultyNew(diffId) && targetType == ERECT)
      {
        curDotSpr.important = true;
      }
      // originally was gonna hide the dots if erect/nightmare wasnt present, leaving this functionality just in case
      // mods (or we) need to display a different amount
      /*if (i > usedDots.length - 1 && usedDots.length != 5)
        {
          members[i].visible = false;
      }*/

      curDotSpr.updateState(targetType, targetState);
    }

    prevDotAmount = usedDots.length;
  }

  public function fade(fadeIn:Bool):Void
  {
    for (i in 0...members.length)
      fadeIn ? members[i].fadeIn() : members[i].fadeOut();
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
   * Erected or nit, dum dum.
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

    pulseSpr.visible = important;

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
/*
  class DifficultyDotOLD extends FlxSpriteGroup
  {


  public function new(id:String, num:Int, erected:Bool)
  {
    updateState();
  }





  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
  }


  }
 */
