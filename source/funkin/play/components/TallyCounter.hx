package funkin.play.components;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText.FlxTextAlign;
import funkin.util.MathUtil;

/**
 * Numerical counters used next to each judgement in the Results screen.
 */
@:nullSafety
class TallyCounter extends FlxTypedSpriteGroup<FlxSprite>
{
  public var curNumber:Float = 0;
  public var neededNumber:Int = 0;

  public var flavour:Int = 0xFFFFFFFF;

  public var align:FlxTextAlign = FlxTextAlign.LEFT;

  public function new(x:Float, y:Float, neededNumber:Int = 0, ?flavour:Int, align:FlxTextAlign = FlxTextAlign.LEFT)
  {
    super(x, y);

    this.align = align;

    this.flavour = flavour ?? 0xFFFFFFFF;

    this.neededNumber = neededNumber;

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
      if (ind >= members.length)
      {
        var xPos = ind * (43 * this.scale.x);
        if (this.align == FlxTextAlign.RIGHT)
        {
          xPos -= (fullNumberDigits * (43 * this.scale.x));
        }
        var numb:TallyNumber = new TallyNumber(xPos, 0, num);
        numb.scale.set(this.scale.x, this.scale.y);
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

@:nullSafety
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
