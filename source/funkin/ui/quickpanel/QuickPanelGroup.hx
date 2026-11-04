package funkin.ui.quickpanel;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.assets.Assets;
import funkin.assets.ValidatedPaths as Paths;
import funkin.graphics.FunkinSprite;
import funkin.group.FunkinGroup;
import funkin.ui.quickpanel.QuickPanelTypes;
import funkin.graphics.shaders.QuickPanelShader;
import funkin.util.PropertyAnimator;

/**
 * Group containing quick panel visuals
 */
class QuickPanelGroup extends FunkinSpriteGroup
{
  /**
   * Distance in pixels between the closed and the open position.
   */
  public static final OPEN_DISTANCE:Float = 467;

  /**
   * Lowest alpha the pull tab fades to while idle.
   */
  public static final TAB_MIN_ALPHA:Float = 0.25;

  static final PANEL_BOIL_INTERVAL:Int = 4;
  static final HINT_COLOR_NORMAL:FlxColor = 0xFFEEEEEE;
  static final HINT_COLOR_DARK:FlxColor = 0xFFCCCCCC;
  static final BUTTON_PADDING:Float = 20;
  static final BUTTON_ANGLE_RANGE:Float = 5;
  static final BUTTON_ANGLE_DISTANCE:Float = 20;
  static final SLICE_ANGLE_RANGE:Float = 4.45;
  static final Z_BELOW:Int = 10;
  static final Z_ABOVE:Int = 11;
  static final Z_BUTTONS:Int = 12;
  static final Z_HITBOX:Int = 200;

  /**
   * The animated panel background.
   */
  public var panelSprite(default, null):FlxSprite;

  /**
   * The visible tab you pull or tap.
   */
  public var pullTabVisual(default, null):QuickPanelPullTab;

  /**
   * Invisible, larger hit area for the tab.
   */
  public var pullTabHitbox(default, null):FlxSprite;

  public var buttons(default, null):Array<QuickPanelButton> = [];

  /**
   * Whether the panel is docked to the left edge of the screen.
   */
  public var left(default, null):Bool = false;

  /**
   * Group x when fully closed.
   */
  public var closedX(get, never):Float;

  /**
   * Group x when fully open.
   */
  public var openX(get, never):Float;

  /**
   * Solid fill trailing behind the panel so over-pulling never shows a gap.
   */
  var pullExtra:FlxSprite;

  var pullHint:FlxText;
  var panelShader:QuickPanelShader;
  var grpButtons:FunkinGroup<QuickPanelButton>;
  var paScroll:PropertyAnimator;
  var paColor:PropertyAnimator;
  var paHint:PropertyAnimator;
  var panelBoilTimer:Float = 0;
  var hintBreathing:Bool = false;
  var hintBreatheTimer:Float = 0;

  public function new(buttonData:Array<QuickPanelButtonData>,
    onButtonTapped:QuickPanelButton->Void)
  {
    super();

    pullExtra = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
    pullExtra.scrollFactor.set(0, 0);
    pullExtra.scale.set(FlxG.width, FlxG.height);
    pullExtra.updateHitbox();
    // Both scale and localScale need setting here (see original note).
    pullExtra.localScale.x = FlxG.width;
    pullExtra.localScale.y = FlxG.height;
    pullExtra.localY = 0;
    add(pullExtra);

    pullHint = new FlxText(0, 0, 600, "you're not supposed to see this! if you do, i seriously messed up!", 30);
    pullHint.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinOptions', 'otf'), 38, HINT_COLOR_NORMAL, RIGHT);
    pullHint.localY = (FlxG.height / 2) - (pullHint.height / 2);
    pullHint.localAlpha = 0;
    add(pullHint);

    pullTabVisual = new QuickPanelPullTab(0, 0, #if FEATURE_TOUCH_CONTROLS false #else true #end);
    pullTabVisual.localY = (FlxG.height / 2) - (pullTabVisual.height / 2);
    pullTabVisual.playIdle(CLOSED);
    pullTabVisual.zIndex = Z_ABOVE;
    add(pullTabVisual);

    panelSprite = new FlxSprite();
    panelSprite.frames = Assets.getSparrowAtlas(Paths.image('ui/quick-panel/panel-bg'));
    panelSprite.animation.addByIndices('idle', 'thingidle instance 10', [for (i in 0...16) i], '', 12, true);
    panelSprite.animation.play('idle');
    panelSprite.updateHitbox();
    panelSprite.scrollFactor.set(0, 0);
    panelSprite.localY = 0;
    panelSprite.zIndex = Z_BELOW;
    add(panelSprite);

    panelShader = new QuickPanelShader();
    panelSprite.shader = panelShader;
    panelSprite.animation.onFrameChange.add((_, _, _) -> panelShader.updateFrameInfo(panelSprite.frame));
    panelShader.updateFrameInfo(panelSprite.frame);

    pullTabHitbox = new FlxSprite().makeGraphic(200, 280, 0xFFFF9191);
    pullTabHitbox.scrollFactor.set(0, 0);
    pullTabHitbox.localAlpha = 0;
    pullTabHitbox.updateHitbox();
    pullTabHitbox.zIndex = Z_HITBOX;
    pullTabHitbox.localY = (FlxG.height / 2) - (pullTabHitbox.height / 2);
    add(pullTabHitbox);

    grpButtons = new FunkinGroup<QuickPanelButton>();
    grpButtons.zIndex = Z_BUTTONS;
    add(grpButtons);

    for (index => data in buttonData)
    {
      var button = new QuickPanelButton(data);
      button.curIndex = index;
      button.onTapped = onButtonTapped;
      grpButtons.add(button);
      buttons.push(button);
    }

    setupAnims();
    setSide(left);
    refresh();
  }

  /**
   * Mirrors every member for the given screen edge.
   * @param left Whether to mirror left or right
   */
  public function setSide(left:Bool):Void
  {
    this.left = left;

    pullTabVisual.localX = left ? 120 - pullTabVisual.width : -120;
    pullTabHitbox.localX = left ? 145 - pullTabHitbox.width : -145;

    panelSprite.localX = left ? -panelSprite.width : 0;
    pullExtra.localX = left ? -(pullExtra.width + panelSprite.width) + 5 : panelSprite.width - 5;

    panelSprite.flipX = left;
    pullTabVisual.flipX = left;

    pullHint.localX = left ? 135 : -135 - pullHint.width;
    pullHint.alignment = left ? LEFT : RIGHT;

    layoutButtons();
  }

  function layoutButtons():Void
  {
    var count:Int = buttons.length;
    if (count == 0) return;

    var angleStep:Float = count > 1 ? (BUTTON_ANGLE_RANGE * 2) / (count - 1) : 0;
    var fullHeight:Float = (QuickPanelButton.ITEM_HEIGHT * count) + (BUTTON_PADDING * (count - 1));
    var startY:Float = (FlxG.height / 2) - (fullHeight / 2);
    var baseX:Float = left ? -panelSprite.width + 58 : 98;

    for (index => button in buttons)
    {
      var targetAngle:Float = BUTTON_ANGLE_RANGE - (angleStep * index);
      var dist:Float = Math.abs(Math.cos(targetAngle) * BUTTON_ANGLE_DISTANCE);

      button.localX = left ? baseX + dist : baseX - dist;
      button.localY = startY + ((QuickPanelButton.ITEM_HEIGHT + BUTTON_PADDING) * index);
      button.localAngle = left ? -targetAngle : targetAngle;
      button.repositionSide(left);
    }
  }

  /**
   * Puts the pull tab above / below the panel sprite.
   * @param top Whether its uptop and down below.
   */
  public function setTabOnTop(top:Bool):Void
  {
    panelSprite.zIndex = top ? Z_BELOW : Z_ABOVE;
    pullTabVisual.zIndex = top ? Z_ABOVE : Z_BELOW;
    refresh();
  }

  /**
   * Highlights one button and points the shader slice at it.
   * @param index The index of the button to highlight.
   * @param disabled Whether button is disabled or not.
   */
  public function showSelection(index:Int, disabled:Bool):Void
  {
    for (i => button in buttons) if (i == index || button.selected) button.selected = (i == index);

    var count:Int = buttons.length;
    var step:Float = count > 1 ? (SLICE_ANGLE_RANGE * 2) / (count - 1) : 0;

    panelShader.sliceVisible = true;
    panelShader.doLerp = true;
    panelShader.dir = -90 + (SLICE_ANGLE_RANGE - (step * index));
    panelShader.sliceColorStart = disabled ? QuickPanelShader.START_COLOR_DISABLED : QuickPanelShader.START_COLOR_NORMAL;
    panelShader.sliceColorEnd = disabled ? QuickPanelShader.END_COLOR_DISABLED : QuickPanelShader.END_COLOR_NORMAL;
    paColor.playAnimation('breathe');
  }

  /**
   * Deselects every button and hides the shader slice.
   */
  public function clearSelection():Void
  {
    for (button in buttons)
    {
      if (button.selected) button.selected = false;
    }

    paColor.stop();
    panelShader.sliceVisible = false;
  }

  /**
   * Plays the scroll bump animation.
   * @param direction -1 = moved up, 1 = moved down, 0 = no movement.
   */
  public function playScrollBump(direction:Int):Void
  {
    paScroll.onFinish = null;
    paScroll.playAnimation(direction < 0 ? 'bumpUp' : (direction > 0 ? 'bumpDown' : 'bumpNeutral'));
  }

  public function playDeny(onDone:Void->Void):Void
  {
    panelShader.doLerp = false;
    paScroll.playAnimation('deny', true);
    paScroll.onFinish = () ->
    {
      // Clear immediately so later animations don't re-run this.
      paScroll.onFinish = null;
      panelShader.doLerp = true;
      if (onDone != null) onDone();
    };
  }

  public function playAccept(selectedIndex:Int):Void
  {
    paScroll.onFinish = null;
    paScroll.playAnimation('accept', true);
    panelShader.doLerp = false;

    for (i => button in buttons)
    {
      if (i == selectedIndex) button.paScale.playAnimation('bumpBig');
      else
        button.paFade.playAnimation('fade');
    }
  }

  public function showHint(text:String):Void
  {
    pullHint.text = text;
    pullHint.color = HINT_COLOR_NORMAL;
    hintBreathing = false;
    hintBreatheTimer = 0;

    paHint.playAnimation(left ? 'slideRight' : 'slideLeft');
    paHint.onFinish = () ->
    {
      paHint.onFinish = null;
      hintBreathing = true;
    };
  }

  public function hideHint():Void
  {
    hintBreathing = false;
    paHint.onFinish = null;
    paHint.playAnimation('disappear');
    pullHint.color = HINT_COLOR_NORMAL;
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    panelBoilTimer -= elapsed;
    if (panelBoilTimer <= 0)
    {
      panelBoilTimer += PANEL_BOIL_INTERVAL / 24;
      panelShader.updateBoil();
    }

    if (hintBreathing)
    {
      hintBreatheTimer += elapsed;
      pullHint.color = FlxColor.interpolate(HINT_COLOR_DARK, HINT_COLOR_NORMAL, (Math.cos(hintBreatheTimer * 2) / 2) + 0.5);
    }
  }

  override public function destroy():Void
  {
    if (paHint != null) paHint.onFinish = null;
    if (paScroll != null) paScroll.onFinish = null;
    if (pullTabVisual != null) FlxTween.cancelTweensOf(pullTabVisual);
    FlxTween.cancelTweensOf(this);

    buttons = [];

    super.destroy();
  }

  function setupAnims():Void
  {
    paHint = new PropertyAnimator(pullHint);

    final fadeIn = [
      0.0,
      0.0,
      0.5,
      0.5,
      0.7,
      0.7,
      0.9,
      0.9,
      0.95,
      0.95,
      1.0,
      1.0
    ];
    final fadeOut = [
      1.0,
      1.0,
      0.95,
      0.95,
      0.9,
      0.9,
      0.7,
      0.7,
      0.5,
      0.5,
      0.0,
      0.0
    ];
    final slide = [
      10.0,
      10.0,
      5.0,
      5.0,
      2.0,
      2.0,
      1.0,
      1.0,
      0.05,
      0.05,
      0.0,
      0.0
    ];

    paHint.addAnimationByName('slideLeft', 30);
    paHint.addProperty('slideLeft', 'offset.x', [for (v in slide) -v]);
    paHint.addProperty('slideLeft', 'localAlpha', fadeIn.copy());

    paHint.addAnimationByName('slideRight', 30);
    paHint.addProperty('slideRight', 'offset.x', slide.copy());
    paHint.addProperty('slideRight', 'localAlpha', fadeIn.copy());

    paHint.addAnimationByName('disappear', 30);
    paHint.addProperty('disappear', 'localAlpha', fadeOut);

    paHint.setDefaultProperties();

    // Slice movement
    paScroll = new PropertyAnimator(panelShader);

    final bumpFat = [
      0.3,
      0.3,
      0.3,
      0.3,
      0.3,
      0.3,
      -0.25,
      -0.25,
      -0.05,
      -0.05,
      0.0
    ];

    paScroll.addAnimationByName('bumpUp', 30);
    paScroll.addProperty('bumpUp', 'dirExtra', [
      -0.2,
      -0.2,
      -0.03,
      -0.03,
      -0.01,
      -0.01,
      0.0
    ]);
    paScroll.addProperty('bumpUp', 'fatExtra', bumpFat.copy());

    paScroll.addAnimationByName('bumpDown', 30);
    paScroll.addProperty('bumpDown', 'dirExtra', [
      0.2,
      0.2,
      0.03,
      0.03,
      0.01,
      0.01,
      0.0
    ]);
    paScroll.addProperty('bumpDown', 'fatExtra', bumpFat.copy());

    paScroll.addAnimationByName('bumpNeutral', 30);
    paScroll.addProperty('bumpNeutral', 'fatExtra', bumpFat.copy());

    paScroll.addAnimationByName('accept', 24);
    paScroll.addProperty('accept', 'fatExtra', [
      1.05,
      1.05,
      1.1,
      1.1,
      1.0,
      1.0,
      -0.05,
      -0.05,
      -0.05,
      -0.05,
      0.0
    ]);
    paScroll.addProperty('accept', 'sliceColor', [
      0xFFFF596A,
      0xFFFF596A,
      0xffF3E63A,
      0xffF3E63A,
      0xFFFF596A,
      0xFFFF596A,
      0xffF3E63A,
      0xffF3E63A,
      0xFFFF596A,
      0xFFFF596A,
      0xffF3E63A
    ]);

    paScroll.addAnimationByName('deny', 30);
    paScroll.addProperty('deny', 'sliceColor', [0xFF7C6969, 0xFF7C6969, 0xff6f6969, 0xff6f6969]);
    paScroll.addProperty('deny', 'dirExtra', [
      0.2,
      0.2,
      -0.2,
      -0.2,
      0.1,
      0.1,
      -0.1,
      -0.1,
      0.0
    ]);

    paScroll.setDefaultProperties();

    // Slice colour breathing
    paColor = new PropertyAnimator(panelShader);
    paColor.addAnimationByName('breathe', 12, true);
    paColor.addProperty('breathe', 'sliceLerp', [
      0.0, 0.0, 0.1, 0.1, 0.2, 0.2, 0.5, 0.5, 0.8, 0.8, 0.9, 0.9,
      1.0, 1.0, 0.9, 0.9, 0.8, 0.8, 0.5, 0.5, 0.2, 0.2, 0.1, 0.1
    ]);
    paColor.setDefaultProperties();
    paColor.playAnimation('breathe');
  }

  override function set_active(v:Bool):Bool
  {
    grpButtons.active = v;
    return super.set_active(v);
  }

  /// Helpers

  inline function get_closedX():Float return left ? 0 : FlxG.width;

  inline function get_openX():Float return xForOpenness(OPEN_DISTANCE);

  /**
   * Converts "pixels open" (0 = closed, OPEN_DISTANCE = open) into a group x position.
   */
  public inline function xForOpenness(openness:Float):Float return closedX + (left ? openness : -openness);

  /**
   * Inverse of xForOpenness.
   */
  public inline function opennessOf(groupX:Float):Float return (groupX - closedX) * (left ? 1 : -1);
}
