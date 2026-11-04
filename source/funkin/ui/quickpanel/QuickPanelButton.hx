package funkin.ui.quickpanel;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.ui.quickpanel.QuickPanelState;
import funkin.group.FunkinGroup;
import funkin.ui.quickpanel.QuickPanelGroup;
import funkin.ui.quickpanel.QuickPanelState;
import funkin.ui.quickpanel.QuickPanelTypes;
import funkin.graphics.shaders.BoilShader;
import funkin.graphics.FunkinSprite;
import funkin.util.PropertyAnimator;
import funkin.audio.FunkinSound;
import funkin.util.TouchUtil;

/**
 * One entry in the quick panel.
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

  /**
   * A hitbox for the button.
   */
  public var guide:FunkinSprite;

  public var buttonText:FlxText;
  public var icon:FunkinSprite;
  public var paScale:PropertyAnimator;
  public var paFade:PropertyAnimator;

  var ICON_SCALE_X:Float;
  var ICON_SCALE_Y:Float;

  /**
   * This button's index in the panel.
   */
  public var curIndex:Int = 0;

  /**
   * Called when a touch that started on this button is released on it.
   */
  public var onTapped:Null<QuickPanelButton->Void> = null;

  var touchHeld:Bool = false;
  var left:Bool = true;

  /**
   * Disabled buttons are drawn at half opacity.
   */
  var alphaMultiplier:Float = 0;

  public function repositionSide(_left:Bool = false)
  {
    left = _left;

    buttonText.localX = left ? guide.width - (ICON_WIDTH + buttonText.width + 20) : ICON_WIDTH + 20;
    icon.localX = left ? guide.width - ICON_WIDTH : 0;

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
    guide.localAlpha = 0;
    guide.localX = 0;
    guide.localY = 0;
    add(guide);

    buttonText = new FlxText(0, 0, ITEM_WIDTH - (ICON_WIDTH + 20), '${data.text ?? 'NO TEXT'}', 30);
    buttonText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinOptions', 'otf'), 38, 0xFFCCCCCC, LEFT);
    buttonText.localX = ICON_WIDTH + 20;
    buttonText.localY = (ITEM_HEIGHT / 2) - (buttonText.height / 2);
    buttonText.offset.y = -6;
    add(buttonText);

    icon = new FunkinSprite(0, 0);
    icon.loadGraphic(Paths.image('ui/quick-panel/icons/${data.icon}'));
    add(icon);

    icon.antialiasing = true;
    icon.setGraphicSize(ICON_WIDTH, ICON_WIDTH);

    ICON_SCALE_X = icon.scale.x;
    ICON_SCALE_Y = icon.scale.y;

    icon.localScale.x = ICON_SCALE_X;
    icon.localScale.y = ICON_SCALE_Y;
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
   * Sets up the fade and scale animations.
   */
  public function setupAnims()
  {
    paFade = new PropertyAnimator(this);

    paFade.addAnimationByName('fade', 24);
    paFade.addProperty('fade', 'localAlpha', [for (a in [
      1.0,
      0.5,
      0.2,
      0.1,
      0.1,
      0.0
    ]) a * alphaMultiplier]);

    paFade.addAnimationByName('press', 24);
    paFade.addProperty('press', 'localAlpha', [0.7 * alphaMultiplier]);

    paFade.addAnimationByName('release', 24);
    paFade.addProperty('release', 'localAlpha', [1.0 * alphaMultiplier]);

    paFade.setDefaultProperties();

    paScale = new PropertyAnimator(this);
    addBumpAnimation('bump', 1.04, 0.98);
    addBumpAnimation('bumpBig', 1.2, 0.95);
    paScale.setDefaultProperties();

    icon.localScale.x = ICON_SCALE_X;
    icon.localScale.y = ICON_SCALE_Y;
  }

  /**
   * Adds a squash-and-settle animation: the whole button peaks then dips, then settles at 1.
   * @param name Anim name
   * @param peak The peak scale value
   * @param dip The dip scale value.
   */
  function addBumpAnimation(name:String, peak:Float, dip:Float):Void
  {
    final iconOffsets = [
      0.05,
      0.05,
      0.02,
      0.02,
      0.02,
      0.02,
      -0.01,
      -0.01,
      -0.01,
      -0.01,
      0.0
    ];
    final groupScale = [
      peak,
      peak,
      peak,
      peak,
      peak,
      peak,
      dip,
      dip,
      dip,
      dip,
      1.0
    ];

    paScale.addAnimationByName(name, 30);
    paScale.addProperty(name, 'icon.localScale.x', [for (o in iconOffsets) ICON_SCALE_X + o]);
    paScale.addProperty(name, 'icon.localScale.y', [for (o in iconOffsets) ICON_SCALE_Y + o]);
    paScale.addProperty(name, 'localScale.x', groupScale);
    paScale.addProperty(name, 'localScale.y', groupScale.copy());
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

    if (paScale == null) return; // still constructing

    paScale.stop();

    localScale.x = 1;
    localScale.y = 1;
    icon.localScale.x = ICON_SCALE_X;
    icon.localScale.y = ICON_SCALE_Y;

    if (selected) paScale.playAnimation('bump');
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
      touchHeld = true;
      paFade.playAnimation('press');
      FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/menu-press'), 0.1);
    }

    // Only react to releases of a press that started on this button,
    // so a stray release doesnt unfade buttons mid-transition.
    if (TouchUtil.justReleased && touchHeld)
    {
      touchHeld = false;
      paFade.playAnimation('release');

      if (TouchUtil.overlaps(this) && onTapped != null) onTapped(this);
    }
    #end
  }

  /**
   * Calls the callback assigned in the data, if it exists.
   */
  public function doCallback()
  {
    if (data.callback != null) data.callback();
  }

  override function destroy():Void
  {
    onTapped = null;
    FlxTween.cancelTweensOf(this);
    FlxTween.cancelTweensOf(this.scale);
    super.destroy();
  }

  function set_selected(value:Bool):Bool
  {
    selected = value;
    updateSelected();
    return selected;
  }
}
