package funkin.play.components;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;

class ComboMilestone extends FlxTypedSpriteGroup<FlxSprite>
{
  var effectStuff:FlxSprite;

  var wasComboSetup:Bool = false;
  var daCombo:Int = 0;

  var grpNumbers:FlxTypedGroup<ComboMilestoneNumber>;

  var onScreenTime:Float = 0;

  public function new(x:Float, y:Float, daCombo:Int = 0)
  {
    super(x, y);

    this.daCombo = daCombo;

    effectStuff = new FlxSprite(0, 0);
    effectStuff.frames = Paths.getSparrowAtlas('ui/combo-milestone/funkin/comboMilestone');
    effectStuff.animation.addByPrefix('funny', 'NOTE COMBO animation', 24, false);
    effectStuff.animation.play('funny');
    effectStuff.animation.finishCallback = function(nameThing) {
      kill();
    };
    effectStuff.setGraphicSize(Std.int(effectStuff.width * 0.7));
    add(effectStuff);

    grpNumbers = new FlxTypedGroup<ComboMilestoneNumber>();
    // add(grpNumbers);
  }

  public function forceFinish():Void
  {
    if (onScreenTime < 0.9)
    {
      new FlxTimer().start((Conductor.instance.beatLengthMs / 1000) * 0.25, function(tmr) {
        forceFinish();
      });
    }
    else
      effectStuff.animation.play('funny', true, false, 18);
  }

  override function update(elapsed:Float)
  {
    onScreenTime += elapsed;

    if (effectStuff.animation.curAnim.curFrame == 17) effectStuff.animation.pause();

    if (effectStuff.animation.curAnim.curFrame == 2 && !wasComboSetup)
    {
      setupCombo(daCombo);
    }

    if (effectStuff.animation.curAnim.curFrame == 18)
    {
      grpNumbers.forEach(function(spr:ComboMilestoneNumber) {
        spr.animation.reset();
      });
    }

    if (effectStuff.animation.curAnim.curFrame == 20)
    {
      grpNumbers.forEach(function(spr:ComboMilestoneNumber) {
        spr.kill();
      });
    }

    super.update(elapsed);
  }

  function setupCombo(daCombo:Int)
  {
    FunkinSound.playOnce(Paths.sound('comboSound'));

    wasComboSetup = true;
    var stringNum:String = Std.string(daCombo);

    for (i in 0...stringNum.length)
    {
      var coolnumber:ComboMilestoneNumber = new ComboMilestoneNumber(450 - (100 * i), 20 + 14 * i, stringNum.charAt(stringNum.length - 1 - i));
      coolnumber.setGraphicSize(Std.int(coolnumber.width * 0.7));
      grpNumbers.add(coolnumber);
      add(coolnumber);
    }
  }
}

class ComboMilestoneNumber extends FlxSprite
{
  public function new(x:Float, y:Float, digit:String)
  {
    super(x - 20, y);

    frames = Paths.getSparrowAtlas('ui/combo-milestone/funkin/comboMilestoneNumbers');
    animation.addByPrefix(digit, digit, 24, false);
    animation.play(digit);
    updateHitbox();
  }

  var shiftedX:Bool = false;

  override function update(elapsed:Float)
  {
    if (animation.curAnim.curFrame == 2 && !shiftedX)
    {
      shiftedX = true;
      x += 20;
    }

    super.update(elapsed);
  }
}
