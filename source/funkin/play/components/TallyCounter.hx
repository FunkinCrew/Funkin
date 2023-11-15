package funkin.play.components;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

/**
 * Numerical counters used next to each judgement in the Results screen.
 */
class TallyCounter extends FlxTypedSpriteGroup<FlxSprite>
{
  public var curNumber:Float = 0;

  public var neededNumber:Int = 0;
  public var flavour:Int = 0xFFFFFFFF;

  public function new(x:Float, y:Float, neededNumber:Int = 0, ?flavour:Int = 0xFFFFFFFF)
  {
    super(x, y);

    this.flavour = flavour;

    this.neededNumber = neededNumber;
    drawNumbers();
  }

  var tmr:Float = 0;

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (curNumber < neededNumber) drawNumbers();
  }

  function drawNumbers()
  {
    var seperatedScore:Array<Int> = [];
    var tempCombo:Int = Math.round(curNumber);

    while (tempCombo != 0)
    {
      seperatedScore.push(tempCombo % 10);
      tempCombo = Math.floor(tempCombo / 10);
    }

    if (seperatedScore.length == 0) seperatedScore.push(0);

    seperatedScore.reverse();

    for (ind => num in seperatedScore)
    {
      if (ind >= members.length)
      {
        var numb:TallyNumber = new TallyNumber(ind * 43, 0, num);
        add(numb);
        numb.color = flavour;
      }
      else
      {
        members[ind].animation.play(Std.string(num));
        members[ind].color = flavour;
      }
    }
  }
}

class TallyNumber extends FlxSprite
{
  public function new(x:Float, y:Float, digit:Int)
  {
    super(x, y);

    frames = Paths.getSparrowAtlas("resultScreen/tallieNumber");

    for (i in 0...10)
      animation.addByPrefix(Std.string(i), i + " small", 24, false);

    animation.play(Std.string(digit));
    updateHitbox();
  }
}
