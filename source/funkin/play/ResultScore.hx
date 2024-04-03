package funkin.play;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class ResultScore extends FlxTypedSpriteGroup<ScoreNum>
{
  public var scoreShit(default, set):Int = 0;

  function set_scoreShit(val):Int
  {
    if (group == null || group.members == null) return val;
    var loopNum:Int = group.members.length - 1;
    var dumbNumb = Std.parseInt(Std.string(val));
    var prevNum:ScoreNum;

    while (dumbNumb > 0)
    {
      group.members[loopNum].digit = dumbNumb % 10;

      // var funnyNum = group.members[loopNum];
      // prevNum = group.members[loopNum + 1];

      // if (prevNum != null)
      // {
      // funnyNum.x = prevNum.x - (funnyNum.width * 0.7);
      // }

      // funnyNum.y = (funnyNum.baseY - (funnyNum.height / 2)) + 73;
      // funnyNum.x = (funnyNum.baseX - (funnyNum.width / 2)) + 450; // this plus value is hand picked lol!

      dumbNumb = Math.floor(dumbNumb / 10);
      loopNum--;
    }

    while (loopNum > 0)
    {
      group.members[loopNum].digit = 10;
      loopNum--;
    }

    return val;
  }

  public function animateNumbers():Void
  {
    for (i in group.members)
    {
      i.playAnim();
    }
  }

  public function new(x:Float, y:Float, digitCount:Int, scoreShit:Int = 100)
  {
    super(x, y);

    for (i in 0...digitCount)
    {
      add(new ScoreNum(x + (65 * i), y));
    }

    this.scoreShit = scoreShit;
  }

  public function updateScore(scoreNew:Int)
  {
    scoreShit = scoreNew;
  }
}

class ScoreNum extends FlxSprite
{
  public var digit(default, set):Int = 10;

  function set_digit(val):Int
  {
    if (val >= 0 && animation.curAnim != null && animation.curAnim.name != numToString[val])
    {
      animation.play(numToString[val], true, false, 0);
      updateHitbox();

      switch (val)
      {
        case 1:
        // offset.x -= 15;
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

    return digit = val;
  }

  public function playAnim():Void
  {
    animation.play(numToString[digit], true, false, 0);
  }

  public var baseY:Float = 0;
  public var baseX:Float = 0;

  var numToString:Array<String> = [
    "ZERO", "ONE", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "DISABLED"
  ];

  public function new(x:Float, y:Float)
  {
    super(x, y);

    baseY = y;
    baseX = x;

    frames = Paths.getSparrowAtlas('resultScreen/score-digital-numbers');

    for (i in 0...10)
    {
      var stringNum:String = numToString[i];
      animation.addByPrefix(stringNum, '$stringNum DIGITAL', 24, false);
    }

    animation.addByPrefix('DISABLED', 'DISABLED', 24, false);

    this.digit = 10;

    animation.play(numToString[digit], true);

    updateHitbox();
  }
}
