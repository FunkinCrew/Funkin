package funkin.ui.quickpanel;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.ui.quickpanel.QuickPanelState;
import funkin.group.FunkinGroup;
import funkin.ui.quickpanel.QuickPanelGroup;
import funkin.graphics.shaders.BoilShader;
import funkin.graphics.FunkinSprite;
import funkin.util.PropertyAnimator;
import funkin.audio.FunkinSound;
import funkin.util.TouchUtil;

/**
 * The interface for an item in the options menu.
 * Extended to provide specific input data types.
 */
class QuickPanelButton extends FunkinSpriteGroup
{
  public static final ITEM_WIDTH:Int = 320;
  public static final ITEM_HEIGHT:Int = 100;
  public static final ICON_WIDTH:Int = 100;

  var boilShaderIcon:BoilShader;
  var boilShaderText:BoilShader;

  /**
   * How many frames should pass between each time the boilShader should move.
   * (the idle animation of the button changes visuals every 4 frames)
   */
  var BOIL_INTERVAL:Int = 4;

  var boilTimer:Float = 0;

  /**
   * The data assigned to this button.
   */
  public var data:QuickPanelButtonData;

  public var selected(default, set):Bool;

  function set_selected(value:Bool):Bool
  {
    selected = value;
    updateSelected();
    return selected;
  }

  /**
   * A hitbox for the button.
   */
  public var guide:FunkinSprite;

  public var bg:FunkinSprite;
  public var buttonText:FlxText;
  public var icon:FunkinSprite;
  public var paScale:PropertyAnimator;
  public var paFade:PropertyAnimator;

  var ICON_SCALE_X:Float;
  var ICON_SCALE_Y:Float;

  // for mobile, when you tap this button itll force select this index
  public var curIndex:Int = 0;
  public var panelGroup:QuickPanelGroup;

  var left:Bool = true;
  // specifically cause i cant be bothered to make custom animations for disabled buttons
  var alphaMultiplier:Float = 0;

  public function repositionSide(_left:Bool = false)
  {
    left = _left;

    buttonText.x = left ? guide.width - (ICON_WIDTH + buttonText.width + 20) : ICON_WIDTH + 20;
    icon.x = left ? guide.width - ICON_WIDTH : 0;

    // makes sense... right?
    buttonText.alignment = left ? RIGHT : LEFT;
  }

  public function new(_data:QuickPanelButtonData)
  {
    super();

    data = _data;

    alphaMultiplier = data.disabled ? 0.5 : 1.0;

    guide = new FunkinSprite(0, 0);
    guide.makeGraphic(ITEM_WIDTH, ITEM_HEIGHT, 0x00D1D1D1);
    guide.alpha = 0;
    guide.x = 0;
    guide.y = 0;
    add(guide);

    buttonText = new FlxText(0, 0, ITEM_WIDTH - (ICON_WIDTH + 20), '${data.text ?? 'NO TEXT'}', 30);
    buttonText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinOptions', 'otf'), 38, 0xFFCCCCCC, LEFT);
    buttonText.x = ICON_WIDTH + 20;
    buttonText.y = (ITEM_HEIGHT / 2) - (buttonText.height / 2);
    buttonText.offset.y = -6;
    add(buttonText);

    icon = new FunkinSprite(0, 0);
    icon.loadGraphic(Paths.image('ui/quick-panel/icons/${data.icon}'));
    add(icon);

    icon.antialiasing = true;
    icon.setGraphicSize(ICON_WIDTH, ICON_WIDTH);

    ICON_SCALE_X = icon.scale.x;
    ICON_SCALE_Y = icon.scale.y;

    icon.scale.x = ICON_SCALE_X;
    icon.scale.y = ICON_SCALE_Y;
    icon.updateHitbox();

    boilShaderIcon = new BoilShader();
    boilShaderIcon.bumpTimer();
    boilShaderIcon.amount = 100;

    boilShaderText = new BoilShader();
    boilShaderText.bumpTimer();
    boilShaderText.amount = 100;

    buttonText.shader = boilShaderText;
    icon.shader = boilShaderIcon;

    resetOrigin();
    updateSelected();

    setupAnims();

    paFade.playAnimation('release');
  }

  /**
   * Sets up the animations for the fading and scale.
   */
  public function setupAnims()
  {
    paFade = new PropertyAnimator(this);

    paFade.addAnimationByName('fade', 24);

    paFade.addProperty('fade', 'alpha', [
      1.0 * alphaMultiplier,
      0.5 * alphaMultiplier,
      0.2 * alphaMultiplier,
      0.1 * alphaMultiplier,
      0.1 * alphaMultiplier,
      0.0 * alphaMultiplier
    ]);

    paFade.addAnimationByName('press', 24);

    paFade.addProperty('press', 'alpha', [0.7 * alphaMultiplier]);

    paFade.addAnimationByName('release', 24);

    paFade.addProperty('release', 'alpha', [1.0 * alphaMultiplier]);

    paFade.setDefaultProperties();

    paScale = new PropertyAnimator(this);

    paScale.addAnimationByName('bump', 30);

    paScale.addProperty('bump', 'icon.scale.x', [
      ICON_SCALE_X + 0.05,
      ICON_SCALE_X + 0.05,
      ICON_SCALE_X + 0.02,
      ICON_SCALE_X + 0.02,
      ICON_SCALE_X + 0.02,
      ICON_SCALE_X + 0.02,
      ICON_SCALE_X - 0.01,
      ICON_SCALE_X - 0.01,
      ICON_SCALE_X - 0.01,
      ICON_SCALE_X - 0.01,
      ICON_SCALE_X
    ]);

    paScale.addProperty('bump', 'icon.scale.y', [
      ICON_SCALE_Y + 0.05,
      ICON_SCALE_Y + 0.05,
      ICON_SCALE_Y + 0.02,
      ICON_SCALE_Y + 0.02,
      ICON_SCALE_Y + 0.02,
      ICON_SCALE_Y + 0.02,
      ICON_SCALE_Y - 0.01,
      ICON_SCALE_Y - 0.01,
      ICON_SCALE_Y - 0.01,
      ICON_SCALE_Y - 0.01,
      ICON_SCALE_Y
    ]);

    paScale.addProperty('bump', 'scale.x', [
      1.04,
      1.04,
      1.04,
      1.04,
      1.04,
      1.04,
      0.98,
      0.98,
      0.98,
      0.98,
      1
    ]);

    paScale.addProperty('bump', 'scale.y', [
      1.04,
      1.04,
      1.04,
      1.04,
      1.04,
      1.04,
      0.98,
      0.98,
      0.98,
      0.98,
      1
    ]);

    paScale.addAnimationByName('bumpBig', 30);

    paScale.addProperty('bumpBig', 'icon.scale.x', [
      ICON_SCALE_X + 0.05,
      ICON_SCALE_X + 0.05,
      ICON_SCALE_X + 0.02,
      ICON_SCALE_X + 0.02,
      ICON_SCALE_X + 0.02,
      ICON_SCALE_X + 0.02,
      ICON_SCALE_X - 0.01,
      ICON_SCALE_X - 0.01,
      ICON_SCALE_X - 0.01,
      ICON_SCALE_X - 0.01,
      ICON_SCALE_X
    ]);

    paScale.addProperty('bumpBig', 'icon.scale.y', [
      ICON_SCALE_Y + 0.05,
      ICON_SCALE_Y + 0.05,
      ICON_SCALE_Y + 0.02,
      ICON_SCALE_Y + 0.02,
      ICON_SCALE_Y + 0.02,
      ICON_SCALE_Y + 0.02,
      ICON_SCALE_Y - 0.01,
      ICON_SCALE_Y - 0.01,
      ICON_SCALE_Y - 0.01,
      ICON_SCALE_Y - 0.01,
      ICON_SCALE_Y
    ]);

    paScale.addProperty('bumpBig', 'scale.x', [
      1.2,
      1.2,
      1.2,
      1.2,
      1.2,
      1.2,
      0.95,
      0.95,
      0.95,
      0.95,
      1
    ]);

    paScale.addProperty('bumpBig', 'scale.y', [
      1.2,
      1.2,
      1.2,
      1.2,
      1.2,
      1.2,
      0.95,
      0.95,
      0.95,
      0.95,
      1
    ]);

    paScale.setDefaultProperties();

    icon.scale.x = ICON_SCALE_X;
    icon.scale.y = ICON_SCALE_Y;
  }

  /**
   * Updates the button visuals based on whether it is selected.
   */
  function updateSelected()
  {
    icon.color = selected ? FlxColor.BLACK : 0xFFCCCCCC;
    buttonText.color = selected ? FlxColor.BLACK : 0xFFCCCCCC;

    boilShaderIcon.amount = selected ? 1.5 : 0.5;
    boilShaderText.amount = selected ? 1.5 : 0.5;

    BOIL_INTERVAL = selected ? 4 : 8;

    if (paScale != null)
    {
      paScale.stop();

      scale.x = 1;
      scale.y = 1;
      icon.scale.x = ICON_SCALE_X;
      icon.scale.y = ICON_SCALE_Y;
    }

    if (selected)
    {
      paScale.playAnimation('bump');
    }
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    boilTimer -= elapsed;

    if (boilTimer <= 0)
    {
      boilTimer = BOIL_INTERVAL / 24;
      boilShaderIcon.updateBoil();
      boilShaderText.updateBoil();
    }

    #if FEATURE_TOUCH_CONTROLS
    if (TouchUtil.justPressed && TouchUtil.overlaps(this))
    {
      paFade.playAnimation('press');

      FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/menu-press'), 0.1);
    }

    if (TouchUtil.justReleased)
    {
      paFade.playAnimation('release');

      if (TouchUtil.overlaps(this) && !panelGroup.lock)
      {
        panelGroup.changeSelection(curIndex, true);
      }
    }
    #end
  }

  /**
   * Calls the callback assinged in the data, if it exists.
   */
  public function doCallback()
  {
    if (data.callback != null) data.callback();
  }

  override function destroy():Void
  {
    FlxTween.cancelTweensOf(this);
    FlxTween.cancelTweensOf(this.scale);
    super.destroy();
  }
}
