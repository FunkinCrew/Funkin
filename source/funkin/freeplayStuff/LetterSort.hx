package funkin.freeplayStuff;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

class LetterSort extends FlxTypedSpriteGroup<FreeplayLetter>
{
  public var letters:Array<FreeplayLetter> = [];

  var curSelection:Int = 0;

  public var changeSelectionCallback:String->Void;

  public function new(x, y)
  {
    super(x, y);

    var leftArrow:FreeplayLetter = new FreeplayLetter(-20, 20);
    leftArrow.animation.play("arrow");
    leftArrow.flipX = true;
    add(leftArrow);

    for (i in 0...5)
    {
      var letter:FreeplayLetter = new FreeplayLetter(i * 80, 0, i);
      letter.ogY = y;
      add(letter);

      letters.push(letter);

      if (i == 2) letter.scale.x = letter.scale.y = 1.2;

      var darkness:Float = Math.abs(i - 2) / 6;

      letter.color = letter.color.getDarkened(darkness);

      // don't put the last seperator
      if (i == 4) continue;

      var sep:FreeplayLetter = new FreeplayLetter((i * 80) + 55, 20);
      sep.animation.play("seperator");
      sep.color = letter.color.getDarkened(darkness);
      add(sep);
    }

    var rightArrow:FreeplayLetter = new FreeplayLetter(380, 20);
    rightArrow.animation.play("arrow");
    add(rightArrow);

    changeSelection(0);
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.E) changeSelection(1);
    if (FlxG.keys.justPressed.Q) changeSelection(-1);
  }

  public function changeSelection(diff:Int = 0)
  {
    curSelection += diff;
    if (curSelection < 0) curSelection = letters.length - 1;
    if (curSelection >= letters.length) curSelection = 0;

    for (letter in letters)
      letter.changeLetter(diff, curSelection);

    if (changeSelectionCallback != null) changeSelectionCallback(letters[2].arr[letters[2].curLetter]); // bullshit and long lol!
  }
}

class FreeplayLetter extends FlxSprite
{
  public var arr:Array<String> = [];

  public var curLetter:Int = 0;

  public var ogY:Float = 0;

  public function new(x:Float, y:Float, ?letterInd:Int)
  {
    super(x, y);
    frames = Paths.getSparrowAtlas("freeplay/letterStuff");

    var alphabet:String = "abcdefghijklmnopqrstuvwxyz";
    arr = alphabet.split("");
    arr.insert(0, "ALL");
    arr.insert(0, "#");
    arr.insert(0, "fav");

    for (str in arr)
    {
      animation.addByPrefix(str, str + " "); // string followed by a space! intentional!
    }

    animation.addByPrefix("arrow", "mini arrow");
    animation.addByPrefix("seperator", "seperator");

    if (letterInd != null)
    {
      animation.play(arr[letterInd]);
      curLetter = letterInd;
    }
  }

  public function changeLetter(diff:Int = 0, ?curSelection:Int)
  {
    curLetter += diff;

    if (curLetter < 0) curLetter = arr.length - 1;
    if (curLetter >= arr.length) curLetter = 0;

    animation.play(arr[curLetter]);
  }
}
