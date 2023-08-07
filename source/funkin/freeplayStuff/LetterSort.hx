package funkin.freeplayStuff;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.graphics.adobeanimate.FlxAtlasSprite;

class LetterSort extends FlxTypedSpriteGroup<FlxSprite>
{
  public var letters:Array<FreeplayLetter> = [];

  // starts at 2, cuz that's the middle letter on start (accounting for fav and #, it should begin at ALL filter)
  var curSelection:Int = 2;

  public var changeSelectionCallback:String->Void;

  var leftArrow:FlxSprite;
  var rightArrow:FlxSprite;
  var grpSeperators:Array<FlxSprite> = [];

  public function new(x, y)
  {
    super(x, y);

    leftArrow = new FlxSprite(-20, 15).loadGraphic(Paths.image("freeplay/miniArrow"));
    // leftArrow.animation.play("arrow");
    leftArrow.flipX = true;
    add(leftArrow);

    for (i in 0...5)
    {
      var letter:FreeplayLetter = new FreeplayLetter(i * 80, 0, i);
      letter.x += 50;
      letter.y += 50;
      letter.ogY = y;
      add(letter);

      letters.push(letter);

      if (i != 2) letter.scale.x = letter.scale.y = 0.8;
      else
      {
        // letter.x += 10;
        // letter.scale.x = letter.scale.y = 1.1;
      }

      var darkness:Float = Math.abs(i - 2) / 6;

      letter.color = letter.color.getDarkened(darkness);

      // don't put the last seperator
      if (i == 4) continue;

      var sep:FlxSprite = new FlxSprite((i * 80) + 55, 20).loadGraphic(Paths.image("freeplay/seperator"));
      // sep.animation.play("seperator");
      sep.color = letter.color.getDarkened(darkness);
      add(sep);

      grpSeperators.push(sep);
    }

    rightArrow = new FlxSprite(380, 15).loadGraphic(Paths.image("freeplay/miniArrow"));

    // rightArrow.animation.play("arrow");
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
    var ezTimer:Int->FlxSprite->Float->Void = function(frameNum:Int, spr:FlxSprite, offsetNum:Float) {
      new FlxTimer().start(frameNum / 24, function(_) {
        spr.offset.x = offsetNum;
      });
    };

    var positions:Array<Float> = [-10, -22, 2, 0];

    if (diff < 0)
    {
      for (sep in grpSeperators)
      {
        ezTimer(0, sep, positions[0]);
        ezTimer(1, sep, positions[1]);
        ezTimer(2, sep, positions[2]);
        ezTimer(3, sep, positions[3]);
      }

      for (index => letter in letters)
      {
        letter.offset.x = positions[0];

        new FlxTimer().start(1 / 24, function(_) {
          letter.offset.x = positions[1];
          if (index == 0) letter.visible = false;
        });

        new FlxTimer().start(2 / 24, function(_) {
          letter.offset.x = positions[2];
          if (index == 0.) letter.visible = true;
        });

        if (index == 2)
        {
          ezTimer(3, letter, 0);
          // letter.offset.x = 0;
          continue;
        }

        ezTimer(3, letter, positions[3]);
      }

      leftArrow.offset.x = 3;
      new FlxTimer().start(2 / 24, function(_) {
        leftArrow.offset.x = 0;
      });
    }
    else if (diff > 0)
    {
      for (sep in grpSeperators)
      {
        ezTimer(0, sep, -positions[0]);
        ezTimer(1, sep, -positions[1]);
        ezTimer(2, sep, -positions[2]);
        ezTimer(3, sep, -positions[3]);
      }
      // same timing and functions and shit as the left one... except to the right!!

      for (index => letter in letters)
      {
        letter.offset.x = -positions[0];

        new FlxTimer().start(1 / 24, function(_) {
          letter.offset.x = -positions[1];
          if (index == 0) letter.visible = false;
        });

        new FlxTimer().start(2 / 24, function(_) {
          letter.offset.x = -positions[2];
          if (index == 0) letter.visible = true;
        });

        if (index == 2)
        {
          ezTimer(3, letter, 0);
          // letter.offset.x = 0;
          continue;
        }

        ezTimer(3, letter, -positions[3]);
      }

      rightArrow.offset.x = -3;
      new FlxTimer().start(2 / 24, function(_) {
        rightArrow.offset.x = 0;
      });
    }

    curSelection += diff;
    if (curSelection < 0) curSelection = letters[0].arr.length - 1;
    if (curSelection >= letters[0].arr.length) curSelection = 0;

    for (letter in letters)
      letter.changeLetter(diff, curSelection);

    if (changeSelectionCallback != null) changeSelectionCallback(letters[2].arr[letters[2].curLetter]); // bullshit and long lol!
  }
}

class FreeplayLetter extends FlxAtlasSprite
{
  public var arr:Array<String> = [];

  public var curLetter:Int = 0;

  public var ogY:Float = 0;

  public function new(x:Float, y:Float, ?letterInd:Int)
  {
    super(x, y, Paths.animateAtlas("freeplay/sortedLetters"));
    // frames = Paths.getSparrowAtlas("freeplay/letterStuff");
    // this.anim.play("AB");
    // trace(this.anim.symbolDictionary);

    var alphabet:String = "AB-CD-EH-I L-MN-OR-s-t-UZ";
    arr = alphabet.split("-");
    arr.insert(0, "ALL");
    arr.insert(0, "fav");
    arr.insert(0, "#");

    // trace(arr);

    // for (str in arr)
    // {
    //   animation.addByPrefix(str, str + " "); // string followed by a space! intentional!
    // }

    // animation.addByPrefix("arrow", "mini arrow");
    // animation.addByPrefix("seperator", "seperator");

    if (letterInd != null)
    {
      this.anim.play(arr[letterInd] + " move");
      this.anim.pause();
      curLetter = letterInd;
    }
  }

  public function changeLetter(diff:Int = 0, ?curSelection:Int)
  {
    curLetter += diff;

    if (curLetter < 0) curLetter = arr.length - 1;
    if (curLetter >= arr.length) curLetter = 0;

    var animName:String = arr[curLetter] + " move";

    switch (arr[curLetter])
    {
      case "I L":
        animName = "IL move";
      case "s":
        animName = "S move";
      case "t":
        animName = "T move";
    }

    this.anim.play(animName);
    if (curSelection != curLetter)
    {
      trace(animName);
      trace(curLetter);
      trace(curSelection);
      this.anim.pause();
    }
    // updateHitbox();
  }
}
