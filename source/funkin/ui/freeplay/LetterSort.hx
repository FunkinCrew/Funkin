package funkin.ui.freeplay;

import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.input.Controls;
import funkin.util.SwipeUtil;
import funkin.util.TouchUtil;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.audio.FunkinSound;

class LetterSort extends FlxSpriteGroup
{
  public var letters:Array<FreeplayLetter> = [];
  public var letterHitboxes:Array<FlxObject> = [];

  // starts at 2, cuz that's the middle letter on start (accounting for fav and #, it should begin at ALL filter)
  var curSelection:Int = 2;

  public var changeSelectionCallback:String->Void;

  var leftArrow:FlxSprite;
  var rightArrow:FlxSprite;
  var grpSeperators:Array<FlxSprite> = [];

  public var inputEnabled:Bool = true;

  public var instance(default, set):FreeplayState;

  var swipeBounds:FlxObject;

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
      // letter.visible = false;
      add(letter);

      var letterHitbox:FlxObject = new FlxObject(letter.x - 50, letter.y - 50, 50, 50);
      letterHitbox.cameras = cameras;
      letterHitbox.active = false;
      letterHitboxes.push(letterHitbox);

      letters.push(letter);

      if (i != 2) letter.scale.x = letter.scale.y = 0.8;

      var darkness:Float = Math.abs(i - 2) / 6;

      letter.color = letter.color.getDarkened(darkness);

      // don't put the last seperator
      if (i == 4) continue;

      var sep:FlxSprite = new FlxSprite((i * 80) + 60, 20).loadGraphic(Paths.image("freeplay/seperator"));
      // sep.animation.play("seperator");
      sep.color = letter.color.getDarkened(darkness);
      add(sep);

      grpSeperators.push(sep);
    }

    var letterHitbox:FlxObject = new FlxObject(0, 0, 1, 1);
    letterHitbox.cameras = cameras;
    letterHitbox.active = false;
    letterHitboxes.push(letterHitbox);

    rightArrow = new FlxSprite(380, 15).loadGraphic(Paths.image("freeplay/miniArrow"));
    // rightArrow.animation.play("arrow");
    add(rightArrow);

    swipeBounds = new FlxObject(440, 60, 460, 80);
    swipeBounds.cameras = cameras;
    swipeBounds.active = false;

    changeSelection(0);
  }

  var controls(get, never):Controls;

  inline function get_controls():Controls
    return PlayerSettings.player1.controls;

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);
    #if FEATURE_TOUCH_CONTROLS
    @:privateAccess
    if (TouchUtil.justPressed) inputEnabled = instance != null && TouchUtil.overlaps(swipeBounds, instance.funnyCam);
    #end

    if (inputEnabled)
    {
      #if FEATURE_TOUCH_CONTROLS
      if (TouchUtil.pressAction())
      {
        for (index => letter in letterHitboxes)
        {
          @:privateAccess
          if (!TouchUtil.overlaps(letter, instance.funnyCam)) continue;

          if (index == 2 || index == 5) continue;

          var selectionChanges:Array<Int> = [-1, -1, 0, 1, 1];
          var changeValue = selectionChanges[index];

          if (changeValue != 0)
          {
            changeSelection(changeValue);

            if (index == 0 || index == 4)
            {
              changeSelection(changeValue, false);
            }
          }

          break;
        }
      }
      #end

      @:privateAccess
      {
        if (controls.FREEPLAY_LEFT #if FEATURE_TOUCH_CONTROLS
          || (TouchUtil.overlaps(swipeBounds, instance.funnyCam) && SwipeUtil.swipeLeft) #end) changeSelection(-1);

        if (controls.FREEPLAY_RIGHT #if FEATURE_TOUCH_CONTROLS
          || (TouchUtil.overlaps(swipeBounds, instance.funnyCam) && SwipeUtil.swipeRight) #end) changeSelection(1);
      }
    }
  }

  public function changeSelection(diff:Int = 0, playSound:Bool = true):Void
  {
    doLetterChangeAnims(diff);

    var multiPosOrNeg:Float = diff > 0 ? 1 : -1;

    // if we're moving left (diff < 0), we want control of the right arrow, and vice versa
    var arrowToMove:FlxSprite = diff < 0 ? leftArrow : rightArrow;
    arrowToMove.offset.x = 3 * multiPosOrNeg;

    new FlxTimer().start(2 / 24, function(_) {
      arrowToMove.offset.x = 0;
    });
    if (playSound && diff != 0) FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
  }

  /**
   * Buncho timers and stuff to move the letters and seperators
   * Seperated out so we can call it again on letters with songs within them
   * @param diff
   */
  function doLetterChangeAnims(diff:Int):Void
  {
    var ezTimer:Int->FlxSprite->Float->Void = function(frameNum:Int, spr:FlxSprite, offsetNum:Float) {
      new FlxTimer().start(frameNum / 24, function(_) {
        spr.offset.x = offsetNum;
      });
    };

    var positions:Array<Float> = [-10, -22, 2, 0];

    // if we're moving left, we want to move the positions the same amount, but negative direciton
    var multiPosOrNeg:Float = diff > 0 ? 1 : -1;

    for (sep in grpSeperators)
    {
      ezTimer(0, sep, positions[0] * multiPosOrNeg);
      ezTimer(1, sep, positions[1] * multiPosOrNeg);
      ezTimer(2, sep, positions[2] * multiPosOrNeg);
      ezTimer(3, sep, positions[3] * multiPosOrNeg);
    }

    for (index => letter in letters)
    {
      letter.offset.x = positions[0] * multiPosOrNeg;

      new FlxTimer().start(1 / 24, function(_) {
        letter.offset.x = positions[1] * multiPosOrNeg;
        if (index == 0) letter.visible = false;
      });

      new FlxTimer().start(2 / 24, function(_) {
        letter.offset.x = positions[2] * multiPosOrNeg;
        if (index == 0.) letter.visible = true;
      });

      if (index == 2)
      {
        ezTimer(3, letter, 0);
        // letter.offset.x = 0;
        continue;
      }

      ezTimer(3, letter, positions[3] * multiPosOrNeg);
    }

    curSelection += diff;
    if (curSelection < 0) curSelection = letters[0].regexLetters.length - 1;
    if (curSelection >= letters[0].regexLetters.length) curSelection = 0;

    for (letter in letters)
      letter.changeLetter(diff, curSelection);

    if (changeSelectionCallback != null) changeSelectionCallback(letters[2].regexLetters[letters[2].curLetter]); // bullshit and long lol!
  }

  @:noCompletion
  private function set_instance(value:FreeplayState):FreeplayState
  {
    instance = value;

    if (value != null)
    {
      @:privateAccess
      swipeBounds.cameras = [value.funnyCam];
    }
    else
    {
      swipeBounds.cameras = cameras;
    }

    return instance;
  }
}

/**
 * The actual FlxAtlasSprite for the letters, with their animation code stuff and regex stuff
 */
class FreeplayLetter extends FlxAtlasSprite
{
  /**
   * A preformatted array of letter strings, for use when doing regex
   * ex: ['A-B', 'C-D', 'E-H', 'I-L' ...]
   */
  public var regexLetters:Array<String> = [];

  /**
   * A preformatted array of the letters, for use when accessing symbol animation info
   * ex: ['AB', 'CD', 'EH', 'IL' ...]
   */
  public var animLetters:Array<String> = [];

  /**
   * The current letter in the regexLetters array this FreeplayLetter is on
   */
  public var curLetter:Int = 0;

  public function new(x:Float, y:Float, ?letterInd:Int)
  {
    super(x, y, Paths.animateAtlas("freeplay/sortedLetters"));

    // this is used for the regex
    // /^[OR].*/gi doesn't work for showing the song Pico, so now it's
    // /^[O-R].*/gi ant it works for displaying Pico
    // https://regex101.com/r/bWFPfS/1
    // we split by underscores, simply for nice lil convinience
    var alphabet:String = 'A-B_C-D_E-H_I-L_M-N_O-R_S_T_U-Z';
    regexLetters = alphabet.split('_');
    regexLetters.insert(0, 'ALL');
    regexLetters.insert(0, 'fav');
    regexLetters.insert(0, '#');

    // the symbols from flash don't have dashes, so we clean this up for use with animations
    // (we don't need to re-export, rule of thumb is to accomodate files named in flash from dave
    //    until we get him programming classes (and since i cant find the .fla file....))
    animLetters = regexLetters.map(animLetter -> animLetter.replace('-', ''));

    if (letterInd != null)
    {
      this.anim.play(animLetters[letterInd] + " move");
      this.anim.pause();
      curLetter = letterInd;
      this.anim.onComplete.add(function() {
        this.anim.play(animLetters[curLetter] + " move");
      });
    }
  }

  /**
   * Changes the letter graphic/anim, used in the LetterSort class above
   * @param diff -1 or 1, to go left or right in the animation array
   * @param curSelection what the current letter selection is, to play the bouncing anim if it matches the current letter
   */
  public function changeLetter(diff:Int = 0, ?curSelection:Int):Void
  {
    curLetter += diff;

    if (curLetter < 0) curLetter = regexLetters.length - 1;
    if (curLetter >= regexLetters.length) curLetter = 0;

    var animName:String = animLetters[curLetter] + ' move';

    switch (animLetters[curLetter])
    {
      case "IL":
        animName = "IL move";
      case "s":
        animName = "S move";
      case "t":
        animName = "T move";
    }

    this.anim.play(animName, true);
    if (curSelection != curLetter)
    {
      this.anim.pause();
    }
    // updateHitbox();
  }
}
