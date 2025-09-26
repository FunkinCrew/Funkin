package funkin.play.components;

import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.PureColor;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxColor;

/**
 * Numerical counters used to display the clear percent.
 */
class ClearPercentCounter extends FlxTypedSpriteGroup<FlxSprite>
{
  public var curNumber(default, set):Int = 0;

  var numberChanged:Bool = false;

  function set_curNumber(val:Int):Int
  {
    numberChanged = true;
    return curNumber = val;
  }

  var small:Bool = false;
  var flashShader:PureColor;

  public function new(x:Float, y:Float, startingNumber:Int = 0, small:Bool = false)
  {
    super(x, y);

    flashShader = new PureColor(FlxColor.WHITE);
    flashShader.colorSet = false;

    curNumber = startingNumber;

    this.small = small;

    var clearPercentText:FunkinSprite = FunkinSprite.create(0, 0, 'resultScreen/clearPercent/clearPercentText${small ? 'Small' : ''}');
    clearPercentText.x = small ? 40 : 0;
    add(clearPercentText);

    drawNumbers();
  }

  /**
   * Make the counter flash turn white or stop being all white.
   * @param enabled Whether the counter should be white.
   */
  public function flash(enabled:Bool):Void
  {
    flashShader.colorSet = enabled;
  }

  var tmr:Float = 0;

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (numberChanged) drawNumbers();
  }

  function drawNumbers():Void
  {
    var seperatedScore:Array<Int> = [];
    var tempCombo:Int = Math.round(curNumber);

    while (tempCombo > 0 && tempCombo != 0)
    {
      seperatedScore.push(tempCombo % 10);
      tempCombo = Math.floor(tempCombo / 10);
    }

    if (seperatedScore.length == 0) seperatedScore.push(0);

    seperatedScore.reverse();

    for (ind => num in seperatedScore)
    {
      var digitIndex:Int = ind + 1;
      // If there's only one digit, move it to the right
      // If there's three digits, move them all to the left
      var digitOffset = (seperatedScore.length == 1) ? 1 : (seperatedScore.length == 3) ? -1 : 0;
      var digitSize = small ? 32 : 72;
      var digitHeightOffset = small ? -4 : 0;

      var xPos = (digitIndex - 1 + digitOffset) * (digitSize * this.scale.x);
      xPos += small ? -24 : 0;
      var yPos = (digitIndex - 1 + digitOffset) * (digitHeightOffset * this.scale.y);
      yPos += small ? 0 : 72;

      if (digitIndex >= members.length)
      {
        // Three digits = LLR because the 1 and 0 won't be the same anyway.
        var variant:Bool = (seperatedScore.length == 3) ? (digitIndex >= 2) : (digitIndex >= 1);
        // var variant:Bool = (seperatedScore.length % 2 != 0) ? (digitIndex % 2 == 0) : (digitIndex % 2 == 1);
        var numb:ClearPercentNumber = new ClearPercentNumber(xPos, yPos, num, variant, this.small);
        numb.scale.set(this.scale.x, this.scale.y);
        numb.shader = flashShader;
        numb.visible = true;
        add(numb);
      }
      else
      {
        members[digitIndex].animation.play(Std.string(num));
        // Reset the position of the number
        members[digitIndex].x = xPos + this.x;
        members[digitIndex].y = yPos + this.y;
        members[digitIndex].visible = true;
      }
    }
    for (ind in (seperatedScore.length + 1)...(members.length))
    {
      members[ind].visible = false;
    }
  }
}

class ClearPercentNumber extends FlxSprite
{
  public function new(x:Float, y:Float, digit:Int, variant:Bool, small:Bool)
  {
    super(x, y);

    frames = Paths.getSparrowAtlas('resultScreen/clearPercent/clearPercentNumber${small ? 'Small' : variant ? 'Right' : 'Left'}');

    for (i in 0...10)
    {
      animation.addByPrefix('$i', 'number $i 0', 24, false);
    }

    animation.play('$digit');
    updateHitbox();
  }
}
