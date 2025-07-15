package funkin.ui.freeplay;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

@:nullSafety
class FreeplayScore extends FlxTypedSpriteGroup<ScoreNum>
{
  public var scoreShit(default, set):Int = 0;

  function set_scoreShit(val):Int
  {
    if (group == null || group.members == null) return val;

    var dumbNumb:Int = Std.parseInt(Std.string(val)) ?? 0;
    dumbNumb = Std.int(Math.min(dumbNumb, Math.pow(10, group.members.length) - 1));

    var loopNum:Int = group.members.length - 1;

    while (dumbNumb > 0)
    {
      group.members[loopNum].digit = dumbNumb % 10;

      dumbNumb = Math.floor(dumbNumb / 10);
      loopNum--;
    }

    while (loopNum >= 0)
    {
      group.members[loopNum].digit = 0;
      loopNum--;
    }

    return val;
  }

  public function new(x:Float, y:Float, digitCount:Int, scoreShit:Int = 100, ?styleData:FreeplayStyle)
  {
    super(0, y);

    for (i in 0...digitCount)
    {
      if (styleData == null)
      {
        add(new ScoreNum(x + (45 * i), y, 0));
      }
      else
      {
        add(new ScoreNum(x + (45 * i), y, 0, styleData));
      }
    }

    this.scoreShit = scoreShit;
  }

  public function updateScore(scoreNew:Int)
  {
    scoreShit = scoreNew;
  }
}

/**
 * ScoreNum is the number graphic that is used for the completion percentage.
 * It handles offsetting / positioning of the numbers so they look a bit nicer placed
 * NOTE: this is actually a bit similar to the ResultScore class, should perhaps tidy the logic up?
 */
@:nullSafety
class ScoreNum extends FlxSprite
{
  public var digit(default, set):Int = 0;

  function set_digit(val):Int
  {
    if (animation.curAnim != null && animation.curAnim.name != numToString[val])
    {
      animation.play(numToString[val], true, false, 0);
      updateHitbox();

      switch (val)
      {
        case 1:
          offset.x -= 15;
        case 5:
          // set offsets
          // offset.x += 0;
          // offset.y += 10;

        case 7:
          // offset.y += 6;
        case 4:
          // offset.y += 5;
        case 9:
          // offset.y += 5;
        default:
          centerOffsets(false);
      }
    }

    return val;
  }

  public function new(x:Float, y:Float, ?initDigit:Int = 0, ?styleData:FreeplayStyle)
  {
    super(x, y);

    if (styleData == null)
    {
      frames = Paths.getSparrowAtlas('digital_numbers');
    }
    else
    {
      frames = Paths.getSparrowAtlas(styleData.getNumbersAssetKey());
    }

    for (i in 0...10)
    {
      animation.addByPrefix(getIntToString(i), '${getIntToString(i)} DIGITAL', 24, false);
    }

    this.digit = initDigit ?? 0;

    animation.play(getIntToString(digit), true);

    setGraphicSize(Std.int(width * 0.4));
    updateHitbox();
  }

  final numToString:Array<String> = ["ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE"];

  function getIntToString(number:Int):String
  {
    if (numToString[number] == null) return numToString[0];
    return numToString[number];
  }
}
