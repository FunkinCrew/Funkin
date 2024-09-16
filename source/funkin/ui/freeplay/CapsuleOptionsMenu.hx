package funkin.ui.freeplay;

import funkin.graphics.shaders.PureColor;
import funkin.input.Controls;
import flixel.group.FlxSpriteGroup;
import funkin.graphics.FunkinSprite;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextAlign;

@:nullSafety
class CapsuleOptionsMenu extends FlxSpriteGroup
{
  var capsuleMenuBG:FunkinSprite;
  var parent:FreeplayState;

  var queueDestroy:Bool = false;

  var instrumentalIds:Array<String> = [''];
  var currentInstrumentalIndex:Int = 0;

  var currentInstrumental:FlxText;

  public function new(parent:FreeplayState, x:Float = 0, y:Float = 0, instIds:Array<String>):Void
  {
    super(x, y);

    this.parent = parent;
    this.instrumentalIds = instIds;

    capsuleMenuBG = FunkinSprite.createSparrow(0, 0, 'freeplay/instBox/instBox');

    capsuleMenuBG.animation.addByPrefix('open', 'open0', 24, false);
    capsuleMenuBG.animation.addByPrefix('idle', 'idle0', 24, true);
    capsuleMenuBG.animation.addByPrefix('open', 'open0', 24, false);

    currentInstrumental = new FlxText(0, 36, capsuleMenuBG.width, '');
    currentInstrumental.setFormat('VCR OSD Mono', 40, FlxTextAlign.CENTER, true);

    final PAD = 4;
    var leftArrow = new InstrumentalSelector(parent, PAD, 30, false, parent.getControls());
    var rightArrow = new InstrumentalSelector(parent, capsuleMenuBG.width - leftArrow.width - PAD, 30, true, parent.getControls());

    var label:FlxText = new FlxText(0, 5, capsuleMenuBG.width, 'INSTRUMENTAL');
    label.setFormat('VCR OSD Mono', 24, FlxTextAlign.CENTER, true);

    add(capsuleMenuBG);
    add(leftArrow);
    add(rightArrow);
    add(label);
    add(currentInstrumental);

    capsuleMenuBG.animation.finishCallback = function(_) {
      capsuleMenuBG.animation.play('idle', true);
    };
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
    @:privateAccess
    if (parent.controls.BACK)
    {
      close();
      return;
    }

    var changedInst = false;
    if (parent.getControls().UI_LEFT_P)
    {
      currentInstrumentalIndex = (currentInstrumentalIndex + 1) % instrumentalIds.length;
      changedInst = true;
    }
    if (parent.getControls().UI_RIGHT_P)
    {
      currentInstrumentalIndex = (currentInstrumentalIndex - 1 + instrumentalIds.length) % instrumentalIds.length;
      changedInst = true;
    }
    if (!changedInst && currentInstrumental.text == '') changedInst = true;

    if (changedInst)
    {
      currentInstrumental.text = instrumentalIds[currentInstrumentalIndex].toTitleCase() ?? '';
      if (currentInstrumental.text == '') currentInstrumental.text = 'Default';
    }

    if (parent.getControls().ACCEPT)
    {
      onConfirm(instrumentalIds[currentInstrumentalIndex] ?? '');
    }
  }

  public function close():Void
  {
    // Play in reverse.
    capsuleMenuBG.animation.play('open', true, true);
    capsuleMenuBG.animation.finishCallback = function(_) {
      parent.cleanupCapsuleOptionsMenu();
      queueDestroy = true;
    };
  }

  /**
   * Override this with `capsuleOptionsMenu.onConfirm = myFunction;`
   */
  public dynamic function onConfirm(targetInstId:String):Void
  {
    throw 'onConfirm not implemented!';
  }
}

/**
 * The difficulty selector arrows to the left and right of the difficulty.
 */
class InstrumentalSelector extends FunkinSprite
{
  var controls:Controls;
  var whiteShader:PureColor;

  var parent:FreeplayState;

  var baseScale:Float = 0.6;

  public function new(parent:FreeplayState, x:Float, y:Float, flipped:Bool, controls:Controls)
  {
    super(x, y);

    this.parent = parent;

    this.controls = controls;

    frames = Paths.getSparrowAtlas('freeplay/freeplaySelector');
    animation.addByPrefix('shine', 'arrow pointer loop', 24);
    animation.play('shine');

    whiteShader = new PureColor(FlxColor.WHITE);

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

    new FlxTimer().start(2 / 24, function(tmr) {
      scale.x = scale.y = 1 * baseScale;
      whiteShader.colorSet = false;
      updateHitbox();
    });
  }
}
