package funkin.play.components;

import funkin.graphics.FunkinSprite;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.text.FlxText.FlxTextAlign;
import funkin.util.MathUtil;

/**
 * Numerical counters used to display the clear percent.
 */
class ClearPercentCounter extends FlxTypedSpriteGroup<FlxSprite>
{
  public var curNumber:Int = 0;
  public var neededNumber:Int = 0;

  public function new(x:Float, y:Float, neededNumber:Int = 0)
  {
    super(x, y);

    this.neededNumber = neededNumber;

    var clearPercentText:FunkinSprite = FunkinSprite.create(0, 0, 'resultScreen/clearPercent/clearPercentText');
    add(clearPercentText);

    if (curNumber == neededNumber) drawNumbers();
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

    var fullNumberDigits:Int = Std.int(Math.max(1, Math.ceil(MathUtil.logBase(10, neededNumber))));

    while (tempCombo != 0)
    {
      seperatedScore.push(tempCombo % 10);
      tempCombo = Math.floor(tempCombo / 10);
    }

    if (seperatedScore.length == 0) seperatedScore.push(0);

    seperatedScore.reverse();

    for (ind => num in seperatedScore)
    {
      var digitIndex = ind + 1;
      if (digitIndex >= members.length)
      {
        var xPos = (digitIndex - 1) * (72 * this.scale.x);
        var yPos = 72;
        // Three digits = LRL so two different numbers aren't adjacent to each other.
        var variant:Bool = (fullNumberDigits % 2 != 0) ? (digitIndex % 2 == 0) : (digitIndex % 2 == 1);
        var numb:ClearPercentNumber = new ClearPercentNumber(xPos, yPos, num);
        numb.scale.set(this.scale.x, this.scale.y);
        add(numb);
      }
      else
      {
        members[digitIndex].animation.play(Std.string(num));
      }
    }
  }
}

class ClearPercentNumber extends FlxSprite
{
  public function new(x:Float, y:Float, digit:Int, variant:Bool = false)
  {
    super(x, y);

    frames = Paths.getSparrowAtlas('resultScreen/clearPercent/clearPercentNumber${variant ? 'Right' : 'Left'}');

    for (i in 0...10)
    {
      animation.addByPrefix('$i', 'number $i 0', 24, false);
    }

    animation.play('$digit');
    updateHitbox();
  }
}
