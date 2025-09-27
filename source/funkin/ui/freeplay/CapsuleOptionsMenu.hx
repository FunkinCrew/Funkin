package funkin.ui.freeplay;

import funkin.graphics.shaders.PureColor;
import funkin.input.Controls;
import flixel.group.FlxSpriteGroup;
import funkin.graphics.FunkinSprite;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;
#if mobile
import funkin.util.TouchUtil;
#end

@:nullSafety
class CapsuleOptionsMenu extends FlxSpriteGroup
{
  var capsuleMenuBG:FunkinSprite;
  var parent:FreeplayState;

  var queueDestroy:Bool = false;

  var options:Array<String> = [''];
  var currentOptionIndex:Int = 0;

  var currentOption:FlxText;

  var busy:Bool = false;

  var leftArrow:OptionSelector;

  var rightArrow:OptionSelector;

  public function new(parent:FreeplayState, x:Float = 0, y:Float = 0, options:Array<String>, labelText:String):Void
  {
    super(x, y);

    this.parent = parent;
    this.options = options;

    capsuleMenuBG = FunkinSprite.createSparrow(0, 0, 'freeplay/instBox/instBox');

    capsuleMenuBG.animation.addByPrefix('open', 'open0', 24, false);
    capsuleMenuBG.animation.addByPrefix('idle', 'idle0', 24, true);
    capsuleMenuBG.animation.addByPrefix('open', 'open0', 24, false);

    currentOption = new FlxText(0, 36, capsuleMenuBG.width, '');
    currentOption.setFormat('VCR OSD Mono', 40, FlxTextAlign.CENTER, true);

    final PAD = 4;
    leftArrow = new OptionSelector(parent, PAD, 30, false, parent.getControls());
    rightArrow = new OptionSelector(parent, capsuleMenuBG.width - leftArrow.width - PAD, 30, true, parent.getControls());

    var label:FlxText = new FlxText(0, 5, capsuleMenuBG.width, labelText);
    label.setFormat('VCR OSD Mono', 24, FlxTextAlign.CENTER, true);

    add(capsuleMenuBG);
    add(leftArrow);
    add(rightArrow);
    add(label);
    add(currentOption);

    capsuleMenuBG.animation.onFinish.add(function(_) {
      capsuleMenuBG.animation.play('idle', true);
    });
    capsuleMenuBG.animation.play('open', true);
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (queueDestroy)
    {
      destroy();
      return;
    }
    var changedOption:Bool = false;

    if (!busy)
    {
      @:privateAccess
      if (parent.controls.BACK #if mobile || TouchUtil.pressAction(parent.backButton) #end)
      {
        close();
        return;
      }

      if (parent.getControls().UI_LEFT_P #if mobile || TouchUtil.pressAction(leftArrow) #end)
      {
        currentOptionIndex = (currentOptionIndex + 1) % options.length;
        changedOption = true;
      }
      if (parent.getControls().UI_RIGHT_P #if mobile || TouchUtil.pressAction(rightArrow) #end)
      {
        currentOptionIndex = (currentOptionIndex - 1 + options.length) % options.length;
        changedOption = true;
      }
      if (parent.getControls()
        .ACCEPT #if mobile
        || ((TouchUtil.pressAction(currentInstrumental))
          && !(TouchUtil.overlapsComplex(leftArrow) || TouchUtil.overlapsComplex(rightArrow))) #end)
      {
        busy = true;
        onConfirm(options[currentOptionIndex] ?? '');
      }
    }

    if (!changedOption && currentOption.text == '') changedOption = true;

    if (changedOption)
    {
      currentOption.text = options[currentOptionIndex].toTitleCase() ?? '';
      if (currentOption.text == '') currentOption.text = 'Default';
    }
  }

  public function close():Void
  {
    // Play in reverse.
    capsuleMenuBG.animation.play('open', true, true);
    if (leftArrow.moveShitDownTimer != null) leftArrow.moveShitDownTimer.cancel();
    if (rightArrow.moveShitDownTimer != null) rightArrow.moveShitDownTimer.cancel();
    capsuleMenuBG.animation.onFinish.add(function(_) {
      parent.cleanupCapsuleOptionsMenu();
      queueDestroy = true;
    });
  }

  /**
   * Override this with `capsuleOptionsMenu.onConfirm = myFunction;`
   */
  public dynamic function onConfirm(targetOption:String):Void
  {
    throw 'onConfirm not implemented!';
  }
}

/**
 * The difficulty selector arrows to the left and right of the difficulty.
 */
class OptionSelector extends FunkinSprite
{
  var controls:Controls;
  var whiteShader:PureColor;

  var parent:FreeplayState;

  var baseScale:Float = 0.6;

  public var moveShitDownTimer:Null<FlxTimer> = null;

  public function new(parent:FreeplayState, x:Float, y:Float, flipped:Bool, controls:Controls)
  {
    super(x, y);

    this.parent = parent;
    this.controls = controls;

    whiteShader = new PureColor(FlxColor.WHITE);

    frames = Paths.getSparrowAtlas('freeplay/freeplaySelector');
    animation.addByPrefix('shine', 'arrow pointer loop', 24);
    animation.play('shine');

    shader = whiteShader;

    flipX = flipped;

    scale.x = scale.y = 1 * baseScale;
    updateHitbox();
  }

  override function update(elapsed:Float):Void
  {
    if (flipX && controls.UI_RIGHT_P) moveShitDown();
    if (!flipX && controls.UI_LEFT_P) moveShitDown();

    super.update(elapsed);
  }

  function moveShitDown():Void
  {
    offset.y -= 5;

    whiteShader.colorSet = true;

    scale.x = scale.y = 0.5 * baseScale;

    moveShitDownTimer = new FlxTimer().start(2 / 24, function(tmr) {
      scale.x = scale.y = 1 * baseScale;
      whiteShader.colorSet = false;
      updateHitbox();
    });
  }
}
