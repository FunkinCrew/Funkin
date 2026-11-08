package funkin.ui.quickpanel;

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
import funkin.data.quickpanel.PanelData.PanelButtonAnim;
import funkin.util.assets.FlxAnimationUtil;

/**
 * One entry in the quick panel.
 */
class QuickPanelButton extends FunkinSpriteGroup
{
  /**
   * The width of the button
   */
  public static final ITEM_WIDTH:Int = 320;

  /**
   * The height of the button
   */
  public static final ITEM_HEIGHT:Int = 100;

  /**
   * The width of the icon
   */
  public static final ICON_WIDTH:Int = 100;

  /**
   * Gap between the icon and the label.
   */
  static final LABEL_GAP:Float = 20;

  /**
   * The color of the text for this button
   */
  static final TEXT_COLOR:FlxColor = 0xFFCCCCCC;

  /**
   * The color of the text for this button when selected
   */
  static final SELECTED_COLOR:FlxColor = FlxColor.BLACK;

  /**
   * Boil strength while selected.
   */
  static final BOIL_AMOUNT_SELECTED:Float = 1.5;

  /**
   * Boil strength while idle
   */
  static final BOIL_AMOUNT_IDLE:Float = 0.5;

  /**
   * Frames (at 24fps) between boil steps while selected.
   */
  static final BOIL_INTERVAL_SELECTED:Int = 4;

  /**
   * Frames (at 24fps) between boil steps while idle.
   */
  static final BOIL_INTERVAL_IDLE:Int = 8;

  /**
   * Alpha while a touch is held on the button.
   */
  static final PRESS_ALPHA:Float = 0.7;

  /**
   * Alpha multiplier for disabled buttons.
   */
  static final DISABLED_ALPHA:Float = 0.5;

  /**
   * How long the fade-out takes when another button is accepted.
   */
  static final FADE_DURATION:Float = 5 / 24;

  /**
   * How long a bump holds its peak before settling.
   */
  static final BUMP_HOLD:Float = 5 / 30;

  /**
   * How long a bump takes to settle back to normal size.
   */
  static final BUMP_SETTLE:Float = 5 / 30;

  /**
   * Peak scale of the selection bump.
   */
  static final BUMP_PEAK:Float = 1.04;

  /**
   * Back-out overshoot of the selection bump.
   */
  static final BUMP_OVERSHOOT:Float = 4.9;

  /**
   * Peak scale of the accept bump.
   */
  static final BUMP_BIG_PEAK:Float = 1.2;

  /**
   * Back-out overshoot of the accept bump.
   */
  static final BUMP_BIG_OVERSHOOT:Float = 3.0;

  /**
   * Extra icon scale at the peak of a bump, on top of its base scale.
   */
  static final ICON_BUMP:Float = 0.05;

  /**
   * How long the icon holds its peak before settling.
   */
  static final ICON_BUMP_HOLD:Float = 1 / 30;

  /**
   * How long the icon takes to settle.
   */
  static final ICON_BUMP_SETTLE:Float = 9 / 30;

  /**
   * Back-out overshoot of the icon settle.
   */
  static final ICON_BUMP_OVERSHOOT:Float = 2.6;

  /**
   * The data assigned to this button.
   */
  public var data:QuickPanelButtonData;

  /**
   * Whether this is the highlighted button, setting it updates the flair on this button
   */
  public var selected(default, set):Bool;

  /**
   * Invisible sprite that defines the button's size and hit area.
   */
  public var guide:FunkinSprite;

  /**
   * The button text
   */
  public var buttonText:FlxText;

  /**
   * The Button Icon
   */
  public var icon:FunkinSprite;

  /**
   * This button's index in the panel.
   */
  public var curIndex:Int = 0;

  /**
   * Called when a touch that started on this button is released on it.
   */
  public var onTapped:Null<QuickPanelButton->Void> = null;

  /**
   * Whether this button is inside the panel's scroll window. Buttons outside it ignore touches.
   */
  public var inView:Bool = true;

  /**
   * Alpha from the panel's scrolling, multiplied with the fade and disabled alpha.
   */
  public var viewAlpha(default, set):Float = 1;

  public var isAnimated:Bool = false;

  /**
   * The animation data this button's icon was built with.
   */
  public var animData(default, null):PanelButtonAnim;

  var fadeAlpha:Float = 1;

  /**
   * Boil shader for the icon
   */
  var boilShaderIcon:BoilShader;

  /**
   * Boil shader for the text
   */
  var boilShaderText:BoilShader;

  /**
   * Current boil interval
   */
  var boilInterval:Int = BOIL_INTERVAL_IDLE;

  /**
   * Helper variable for boil cycling
   */
  var boilTimer:Float = 0;

  /**
   * Helper tween variable for fading
   */
  var fadeTween:Null<FlxTween> = null;

  /**
   * A collection of tweens related to bumpin'
   */
  var bumpTweens:Array<FlxTween> = [];

  /**
   * Icon scale X after fitting it to ICON_WIDTH. Bumps are added on top of this.
   */
  var baseIconScaleX:Float;

  /**
   * Icon scale Y after fitting it to ICON_WIDTH. Bumps are added on top of this.
   */
  var baseIconScaleY:Float;

  /**
   * Whether the current touch started on this button.
   */
  var touchHeld:Bool = false;

  /**
   * Is this button on the left
   */
  var left:Bool = true;

  /**
   * Alpha multiplier for selected buttons
   */
  var alphaMultiplier:Float = 1;

  /**
   * Creates a new QuickPanelButton
   * @param data The data to use
   */
  public function new(data:QuickPanelButtonData)
  {
    super();

    this.data = data;
    alphaMultiplier = data.disabled == true ? DISABLED_ALPHA : 1.0;

    guide = new FunkinSprite(0, 0);
    guide.makeGraphic(ITEM_WIDTH, ITEM_HEIGHT, 0x00D1D1D1);
    guide.localAlpha = 0;
    guide.localX = 0;
    guide.localY = 0;
    add(guide);

    buttonText = new FlxText(0, 0, ITEM_WIDTH - (ICON_WIDTH + LABEL_GAP), data.text ?? 'NO TEXT', 30);
    buttonText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinOptions', 'otf'), 38, TEXT_COLOR, LEFT);
    buttonText.localX = ICON_WIDTH + LABEL_GAP;
    buttonText.localY = (ITEM_HEIGHT / 2) - (buttonText.height / 2);
    buttonText.offset.y = -6;
    add(buttonText);

    buildIcon(data.buttonAnim ?? funkin.ui.quickpanel.PanelEntry.DEFAULT_ANIM_DATA);

    boilShaderIcon = new BoilShader();
    boilShaderIcon.bumpTimer();
    icon.shader = boilShaderIcon;

    boilShaderText = new BoilShader();
    boilShaderText.bumpTimer();
    buttonText.shader = boilShaderText;

    resetOrigin();
    updateSelected();
    setFadeAlpha(1.0);
  }

  function buildIcon(animData:PanelButtonAnim)
  {
    this.animData = animData;
    icon = new FunkinSprite(0, 0);

    switch (animData.animType)
    {
      case SPARROW_ATLAS:
        isAnimated = true;
        // TODO: Framerate, looping, etc. in data json, plus make this more flexible.
        icon.loadSparrow('ui/quick-panel/icons/${data.icon}');
        icon.animation.addByIndices((animData.idleName ?? "idle") + '-deselected', animData.idlePrefix ?? "idle0", [0], '', 24, true);
        icon.animation.addByPrefix(animData.idleName ?? "idle", animData.idlePrefix ?? "idle0", 24, true);
        icon.animation.addByPrefix(animData.acceptName ?? "accept", animData.acceptPrefix ?? "accept0", 24);
        icon.animation.play('idle-deselected');

      case ANIMATE_ATLAS:
        // TODO: make this better... Im honestly too tired to do it -MOon.
        icon.loadTextureAtlas('ui/quick-panel/icons/${data.icon}');

        FlxAnimationUtil.addTextureAtlasAnimation(icon, {
          name: (animData.idleName ?? "idle") + 'deselected',
          prefix: animData.idlePrefix ?? "symbol0",
          frameRate: 24,
          looped: true,
          animType: 'symbol',
          frameIndices: [0]
        });

        FlxAnimationUtil.addTextureAtlasAnimation(icon, {
          name: animData.idleName ?? "idle",
          prefix: animData.idlePrefix ?? "symbol0",
          frameRate: 24,
          looped: true,
          animType: 'symbol'
        });

        FlxAnimationUtil.addTextureAtlasAnimation(icon, {
          name: animData.acceptName ?? "accept",
          prefix: animData.acceptPrefix ?? "symbol0",
          frameRate: 24,
          animType: 'symbol'
        });

        icon.animation.play('idle-deselected');

      default:
        icon.loadGraphic(Paths.image('ui/quick-panel/icons/${data.icon}'));
    }

    icon.antialiasing = true;
    icon.setGraphicSize(ICON_WIDTH, ICON_WIDTH);
    add(icon);

    baseIconScaleX = icon.scale.x;
    baseIconScaleY = icon.scale.y;
    icon.localScale.x = baseIconScaleX;
    icon.localScale.y = baseIconScaleY;
    icon.updateHitbox();
  }

  /**
   * Mirrors the icon and label for the given screen edge.
   * @param left Whether it is on the left side or not.
   */
  public function repositionSide(left:Bool = false):Void
  {
    this.left = left;

    buttonText.localX = left ? guide.width - (ICON_WIDTH + buttonText.width + LABEL_GAP) : ICON_WIDTH + LABEL_GAP;
    buttonText.alignment = left ? RIGHT : LEFT;
    icon.localX = left ? guide.width - ICON_WIDTH : 0;
  }

  /**
   * Fades the button out.
   */
  public function fadeOut():Void
  {
    cancelFade();
    fadeTween = FlxTween.num(fadeAlpha, 0, FADE_DURATION, {
      ease: FlxEase.cubeOut,
      onComplete: (_) -> fadeTween = null
    }, (a:Float) ->
      {
        fadeAlpha = a;
        applyAlpha();
      });
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
   * Calls the callback assigned in the data, if it exists.
   */
  public function doCallback():Void
  {
    if (data.callback != null) data.callback();
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    boilTimer -= elapsed;
    if (boilTimer <= 0)
    {
      boilTimer = boilInterval / 24;
      boilShaderIcon.updateBoil();
      boilShaderText.updateBoil();
    }

    #if FEATURE_TOUCH_CONTROLS
    updateTouch();
    #end
  }

  #if FEATURE_TOUCH_CONTROLS
  /**
   * Updates touch checks
   */
  function updateTouch():Void
  {
    if (!inView)
    {
      if (touchHeld)
      {
        touchHeld = false;
        setFadeAlpha(1.0);
      }
      return;
    }

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
  }
  #end

  /**
   * Updates this button selection flair
   */
  function updateSelected():Void
  {
    var color:FlxColor = selected ? SELECTED_COLOR : TEXT_COLOR;
    icon.color = color;
    buttonText.color = color;

    var boilAmount:Float = selected ? BOIL_AMOUNT_SELECTED : BOIL_AMOUNT_IDLE;
    boilShaderIcon.amount = boilAmount;
    boilShaderText.amount = boilAmount;
    boilInterval = selected ? BOIL_INTERVAL_SELECTED : BOIL_INTERVAL_IDLE;

    updateIconAnim();

    if (selected) playBump();
    else
      stopBump();
  }

  /**
   * Plays the looping idle animation while selected, and the single-frame deselected one otherwise.
   */
  function updateIconAnim():Void
  {
    if (!isAnimated || icon == null || animData == null) return;

    var animName:String = selected ? (animData.idleName ?? "idle") : (animData.idleName ?? "idle" + '-deselected');
    if (icon.animation.exists(animName)) icon.animation.play(animName, true);
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
    icon.localScale.x = baseIconScaleX + offset;
    icon.localScale.y = baseIconScaleY + offset;
  }

  /**
   * Snaps the button's alpha properly.
   * @param alpha Alpha
   */
  function setFadeAlpha(alpha:Float):Void
  {
    cancelFade();
    fadeAlpha = alpha;
    applyAlpha();
  }

  function applyAlpha():Void
  {
    localAlpha = fadeAlpha * alphaMultiplier * viewAlpha;
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

  override function destroy():Void
  {
    onTapped = null;
    cancelFade();
    for (tween in bumpTweens) if (tween != null) tween.cancel();
    bumpTweens = [];
    FlxTween.cancelTweensOf(this);

    super.destroy();
  }

  function set_viewAlpha(value:Float):Float
  {
    viewAlpha = value;
    applyAlpha();
    return viewAlpha;
  }

  function set_selected(value:Bool):Bool
  {
    selected = value;
    updateSelected();
    return selected;
  }
}
