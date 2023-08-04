package funkin.freeplayStuff;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

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
      add(letter);

      letters.push(letter);

      if (i == 2) letter.alpha = 0.6;

      // don't put the last seperator
      if (i == 4) continue;

      var sep:FreeplayLetter = new FreeplayLetter((i * 80) + 60, 20);
      sep.animation.play("seperator");
      add(sep);
    }

    var rightArrow:FreeplayLetter = new FreeplayLetter(380, 20);
    rightArrow.animation.play("arrow");
    add(rightArrow);

    // changeSelection(-3);
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.E) changeSelection(1);
    if (FlxG.keys.justPressed.Q) changeSelection(-1);
  }

  public function changeSelection(diff:Int = 0)
  {
    for (letter in letters)
      letter.changeLetter(diff);

    if (changeSelectionCallback != null) changeSelectionCallback(letters[2].arr[letters[2].curLetter]); // bullshit and long lol!
  }
}

class FreeplayLetter extends FlxSprite
{
  public var arr:Array<String> = [];

  public var curLetter:Int = 0;

  public function new(x:Float, y:Float, ?letterInd:Int)
  {
    super(x, y);

    frames = Paths.getSparrowAtlas("freeplay/letterStuff");

    var alphabet:String = "abcdefghijklmnopqrstuvwxyz";
    arr = alphabet.split("");
    arr.insert(0, "#");
    arr.insert(0, "ALL");
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

  public function changeLetter(diff:Int = 0)
  {
    curLetter += diff;

    if (curLetter < 0) curLetter = arr.length - 1;
    if (curLetter >= arr.length) curLetter = 0;

    animation.play(arr[curLetter]);
  }
}
