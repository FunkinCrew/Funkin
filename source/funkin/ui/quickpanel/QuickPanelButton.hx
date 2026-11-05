package funkin.ui.quickpanel;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.ui.quickpanel.QuickPanelState;
import funkin.group.FunkinGroup;
import funkin.ui.quickpanel.QuickPanelGroup;
import funkin.ui.quickpanel.QuickPanelState;
import funkin.ui.quickpanel.QuickPanelTypes;
import funkin.util.EaseUtil;
import funkin.util.TouchUtil;

/**
 * One entry in the quick panel.
 */
class QuickPanelButton extends FunkinSpriteGroup
{
  public static final ITEM_WIDTH:Int = 320;
  public static final ITEM_HEIGHT:Int = 100;
  public static final ICON_WIDTH:Int = 100;

  /**
   * Alpha while a touch is held on the button.
   */
  static final PRESS_ALPHA:Float = 0.7;

  /**
   * Fade-out duration on accept
   */
  static final FADE_DURATION:Float = 5 / 24;

  /**
   * How long for a bump to hold its peak size
   */
  static final BUMP_HOLD:Float = 5 / 30;

  /**
    *How long for a bump to settle back to its normal size.
   */
  static final BUMP_SETTLE:Float = 5 / 30;

  /**
   * The biggest a bump can be.
   */
  static final BUMP_PEAK:Float = 1.04;

  /**
   * How much the bump overshoots.
   */
  static final BUMP_OVERSHOOT:Float = 4.9;

  /**
   * The biggest a bump can be, but bigger
   */
  static final BUMP_BIG_PEAK:Float = 1.2;

  /**
   * How much the biggest bump can overshoot
   */
  static final BUMP_BIG_OVERSHOOT:Float = 3.0;

  /**
   * How much to bump the button's icon
   */
  static final ICON_BUMP:Float = 0.05;

  /**
   * How long for a bump to hold its peak size, but icon!
   */
  static final ICON_BUMP_HOLD:Float = 1 / 30;

  /**
   * How long for a bump to settle back to its normal size, but icon!
   */
  static final ICON_BUMP_SETTLE:Float = 9 / 30;

  /**
   * How much the bump overshoots, but icon!
   */
  static final ICON_BUMP_OVERSHOOT:Float = 2.6;

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

  /**
   * Helper tween variable for fading
   */
  var fadeTween:Null<FlxTween> = null;

  /**
   * A collection of tweens related to bumpin'
   */
  var bumpTweens:Array<FlxTween> = [];

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

    setFadeAlpha(1.0);
  }

  /**
   * Fades the button out.
   */
  public function fadeOut():Void
  {
    cancelFade();
    fadeTween = FlxTween.num(localAlpha, 0, FADE_DURATION, {
      ease: FlxEase.cubeOut,
      onComplete: (_) -> fadeTween = null
    }, (a:Float) -> localAlpha = a);
  }

  /**
   * Snaps the button's alpha properly.
   * @param a Alpha
   */
  function setFadeAlpha(a:Float):Void
  {
    cancelFade();
    localAlpha = a * alphaMultiplier;
  }

  /**
   * Cancels the fading, if one is going on right now.
   */
  function cancelFade():Void
  {
    if (fadeTween == null) return;
    fadeTween.cancel();
    fadeTween = null;
  }

  /**
   * Plays a nice little bump animation for this button, bumps it for the icon too.
   * @param big Use the bigger accept bump.
   */
  public function playBump(big:Bool = false):Void
  {
    stopBump();

    var peak:Float = big ? BUMP_BIG_PEAK : BUMP_PEAK;

    localScale.x = peak;
    localScale.y = peak;
    setIconBump(ICON_BUMP);

    bumpTweens.push(FlxTween.num(peak, 1, BUMP_SETTLE, {
      startDelay: BUMP_HOLD,
      ease: EaseUtil.backOut(big ? BUMP_BIG_OVERSHOOT : BUMP_OVERSHOOT)
    }, (v:Float) ->
      {
        localScale.x = v;
        localScale.y = v;
      }));

    bumpTweens.push(FlxTween.num(ICON_BUMP, 0, ICON_BUMP_SETTLE, {
      startDelay: ICON_BUMP_HOLD,
      ease: EaseUtil.backOut(ICON_BUMP_OVERSHOOT)
    }, setIconBump));
  }

  /**
   * Stops any bump that is ongoing.
   */
  function stopBump():Void
  {
    for (tween in bumpTweens) tween.cancel();
    bumpTweens = [];

    localScale.x = 1;
    localScale.y = 1;
    setIconBump(0);
  }

  /**
   * Sets the icon bump scaling with the given offset.
   * @param offset Ofsset
   */
  function setIconBump(offset:Float):Void
  {
    icon.localScale.x = ICON_SCALE_X + offset;
    icon.localScale.y = ICON_SCALE_Y + offset;
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

    stopBump();

    if (selected) playBump();
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
      setFadeAlpha(PRESS_ALPHA);
      FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/menu-press'), 0.1);
    }

    // Only react to releases of a press that started on this button,
    // so a stray release doesnt unfade buttons mid-transition.
    if (TouchUtil.justReleased && touchHeld)
    {
      touchHeld = false;
      setFadeAlpha(1.0);

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
    cancelFade();
    for (tween in bumpTweens) if (tween != null) tween.cancel();
    bumpTweens = [];
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
