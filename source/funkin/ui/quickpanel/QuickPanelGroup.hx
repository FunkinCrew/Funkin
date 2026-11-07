package funkin.ui.quickpanel;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.assets.Assets;
import funkin.assets.ValidatedPaths as Paths;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.QuickPanelShader;
import funkin.group.FunkinGroup;
import funkin.ui.UIStateMachine.UIState;
import funkin.ui.quickpanel.QuickPanelTypes;
import funkin.util.EaseUtil;

/**
 * Group containing quick panel visuals
 */
class QuickPanelGroup extends FunkinSpriteGroup
{
  /**
   * Distance in pixels between the closed and open positions.
   */
  public static final OPEN_DISTANCE:Float = 467;

  /**
   * Lowest alpha the pull tab fades to while idle.
   */
  public static final TAB_MIN_ALPHA:Float = 0.25;

  /**
   * The padding for each button
   */
  static final BUTTON_PADDING:Float = 20;

  /**
   * The button angle range
   */
  static final BUTTON_ANGLE_RANGE:Float = 5;

  /**
   * The button angle distance
   */
  static final BUTTON_ANGLE_DISTANCE:Float = 20;

  /**
   * The slice angle distance
   */
  static final SLICE_ANGLE_RANGE:Float = 4.45;

  /**
   * Z-index for background
   */
  static final Z_BELOW:Int = 10;

  /**
   * Z-index for foreground
   */
  static final Z_ABOVE:Int = 11;

  /**
   * Z-index for the buttons
   */
  static final Z_BUTTONS:Int = 12;

  /**
   * Z-index for the hitboxes.
   */
  static final Z_HITBOX:Int = 200;

  /**
   * Frames (at 24fps) between panel boil steps.
   */
  static final PANEL_BOIL_INTERVAL:Int = 4;

  /**
   * The hint color
   */
  static final HINT_COLOR_NORMAL:FlxColor = 0xFFEEEEEE;

  /**
   * The hint color, darkened
   */
  static final HINT_COLOR_DARK:FlxColor = 0xFFCCCCCC;

  /**
   * How long the hint takes to slide/fade in or out.
   */
  static final HINT_DURATION:Float = 10 / 30;

  /**
   * How far the hint slides in from, in pixels.
   */
  static final HINT_SLIDE_DISTANCE:Float = 10;

  /**
   * How far (degrees) the slice kicks in the scroll direction.
   */
  static final SCROLL_DIR_AMOUNT:Float = 0.2;

  /**
   * How long the direction kick takes to return.
   */
  static final SCROLL_DIR_DURATION:Float = 6 / 30;

  /**
   * Extra slice width (degrees) on a scroll bump.
   * Dude what are these names actually?
   */
  static final SCROLL_FAT_AMOUNT:Float = 0.3;

  /**
   * How long the extra width holds before settling.
   */
  static final SCROLL_FAT_HOLD:Float = 5 / 30;

  /**
   * How long the extra width takes to settle.
   */
  static final SCROLL_FAT_SETTLE:Float = 5 / 30;

  /**
   * Back-out overshoot of the width settle.
   */
  static final SCROLL_FAT_OVERSHOOT:Float = 7.3;

  /**
   * Extra slice width (degrees) when a button is accepted.
   */
  static final ACCEPT_FAT_AMOUNT:Float = 1.05;

  /**
   * The duration of the accept flair.
   */
  static final ACCEPT_DURATION:Float = 10 / 24;

  /**
   * Number of frames the slice colour flickers over during accept (swaps every 2).
   */
  static final ACCEPT_FLICKER_FRAMES:Int = 10;

  /**
   * Accept panel colors
   */
  static final ACCEPT_COLOR_A:FlxColor = 0xFFFF596A;

  /**
   * Accept panel colors
   */
  static final ACCEPT_COLOR_B:FlxColor = 0xFFF3E63A;

  /**
   * Starting amplitude (degrees) of the deny shake.
   */
  static final DENY_SHAKE_AMOUNT:Float = 0.2;

  /**
   * The duration of the deny flair.
   */
  static final DENY_DURATION:Float = 8 / 30;

  /**
   * Number of back-and-forth shakes over DENY_DURATION.
   */
  static final DENY_SHAKE_CYCLES:Float = 2;

  /**
   * Deny panel colors
   */
  static final DENY_COLOR_A:FlxColor = 0xFF7C6969;

  /**
   * Deny panel colors
   */
  static final DENY_COLOR_B:FlxColor = 0xFF6F6969;

  /**
   * Fraction of the deny animation after which the slice swaps from colour A to colour B.
   */
  static final DENY_COLOR_SWAP:Float = 2 / 8;

  /**
   * The slice colour breathe period.
   */
  static final BREATHE_HALF_PERIOD:Float = 1.0;

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

  /**
   * Collection of buttons this panel has.
   */
  public var buttons(default, null):Array<QuickPanelButton> = [];

  /**
   * Whether the panel background and buttons have been built.
   */
  public var bodyBuilt(default, null):Bool = false;

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

  /**
   * The pull hint text.
   */
  var pullHint:FlxText;

  /**
   * The panel shader
   */
  var panelShader:QuickPanelShader;

  /**
   * A group containing the buttons this panel has,
   */
  var grpButtons:FunkinGroup<QuickPanelButton>;

  /**
   * A collection of button data associated with the buttons we have currently.
   */
  var buttonData:Array<QuickPanelButtonData>;

  /**
   * Gets called when a button gets tapped.
   */
  var onButtonTapped:QuickPanelButton->Void;

  /**
   * Helper tween variable for the hint flair
   */
  var hintTween:Null<FlxTween> = null;

  /**
   * Whether the hint is currently doing the breathing flair
   */
  var hintBreathing:Bool = false;

  /**
   * Helper variable for the hint breathing flair.
   */
  var hintBreatheTimer:Float = 0;

  /**
   * A collection of tweens that are used for the scrolling flair
   */
  var scrollTweens:Array<FlxTween> = [];

  /**
   * Helper twene variable for the small little breath flair.
   */
  var breatheTween:Null<FlxTween> = null;

  /**
   * Helper variable for the panel boiling
   */
  var panelBoilTimer:Float = 0;

  /**
   * Helper variable for little extra angular flair for the panel shader.
   */
  var defaultDirExtra:Float = 0;

  /**
   * Helper variable for extra extra-thickness flair for the panel shader
   */
  var defaultFatExtra:Float = 0;

  /**
   * The default slice color
   */
  var defaultSliceColor:FlxColor = FlxColor.WHITE;

  /**
   * Callback of the deny animation that is currently playing, if any.
   */
  var pendingDenyDone:Null<Void->Void> = null;

  /**
   * Creates a new QuickPanelGroup
   * @param buttonData Buttons to build in `buildBody()`.
   * @param onButtonTapped Forwarded to every button.
   */
  public function new(buttonData:Array<QuickPanelButtonData>,
    onButtonTapped:QuickPanelButton->Void,
    hidePullTab:Bool = false)
  {
    super();

    this.buttonData = buttonData;
    this.onButtonTapped = onButtonTapped;

    pullExtra = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
    pullExtra.scrollFactor.set(0, 0);
    pullExtra.scale.set(FlxG.width, FlxG.height);
    pullExtra.updateHitbox();
    // Both scale and localScale need setting here.
    pullExtra.localScale.x = FlxG.width;
    pullExtra.localScale.y = FlxG.height;
    pullExtra.localY = 0;
    pullExtra.visible = false; // Nothing to trail behind until the panel exists.
    add(pullExtra);

    pullHint = new FlxText(0, 0, 600, "How the fuck did you get here?", 30);
    pullHint.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinOptions', 'otf'), 38, HINT_COLOR_NORMAL, RIGHT);
    pullHint.localY = (FlxG.height / 2) - (pullHint.height / 2);
    pullHint.localAlpha = 0;
    add(pullHint);

    var _tabKey:Bool = !hidePullTab;
    #if FEATURE_TOUCH_CONTROLS
    _tabKey = false;
    #end
    pullTabVisual = new QuickPanelPullTab(0, 0, _tabKey);
    pullTabVisual.localY = (FlxG.height / 2) - (pullTabVisual.height / 2);
    pullTabVisual.playIdle(PanelClosed);
    pullTabVisual.zIndex = Z_ABOVE;
    if (hidePullTab) pullTabVisual.localAlpha = 0;
    add(pullTabVisual);

    pullTabHitbox = new FlxSprite().makeGraphic(200, 280, 0xFFFF9191);
    pullTabHitbox.scrollFactor.set(0, 0);
    pullTabHitbox.localAlpha = 0;
    pullTabHitbox.updateHitbox();
    pullTabHitbox.zIndex = Z_HITBOX;
    pullTabHitbox.localY = (FlxG.height / 2) - (pullTabHitbox.height / 2);
    add(pullTabHitbox);

    setSide(left);
    refresh();
  }

  /**
   * Builds the panel background, shader and buttons.
   */
  public function buildBody():Void
  {
    if (bodyBuilt) return;
    bodyBuilt = true;

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

    grpButtons = new FunkinGroup<QuickPanelButton>();
    grpButtons.zIndex = Z_BUTTONS;
    grpButtons.active = active;
    add(grpButtons);

    for (index => data in buttonData)
    {
      var button = new QuickPanelButton(data);
      button.curIndex = index;
      button.onTapped = onButtonTapped;
      grpButtons.add(button);
      buttons.push(button);
    }

    defaultDirExtra = panelShader.dirExtra;
    defaultFatExtra = panelShader.fatExtra;
    defaultSliceColor = panelShader.sliceColor;
    startBreathe();

    pullExtra.visible = true;
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
    pullTabVisual.flipX = left;

    var panelWidth:Float = panelSprite != null ? panelSprite.width : 0;
    pullExtra.localX = left ? -(pullExtra.width + panelWidth) + 5 : panelWidth - 5;

    if (panelSprite != null)
    {
      panelSprite.localX = left ? -panelSprite.width : 0;
      panelSprite.flipX = left;
    }

    pullHint.localX = left ? 135 : -135 - pullHint.width;
    pullHint.alignment = left ? LEFT : RIGHT;

    layoutButtons(true);
  }

  /**
   * Fans the buttons along the panel's curved edge.
   * @param snap Jump straight to the targets instead of gliding there.
   */
  {
    if (count == 0 || panelSprite == null) return;
    if (buttons.length == 0 || panelSprite == null) return;

    var slots:Int = visibleSlots;
    var angleStep:Float = BUTTON_ANGLE_RANGE / 2;
    var fullHeight:Float = (QuickPanelButton.ITEM_HEIGHT * slots) + (BUTTON_PADDING * (slots - 1));
    var startY:Float = (FlxG.height / 2) - (fullHeight / 2);
    var baseX:Float = left ? -panelSprite.width + 58 : 98;

    for (index => button in buttons)
    {
      var slot:Int = index - windowStart;
      var inView:Bool = slot >= 0 && slot < slots;

      var edgeSlot:Int = Std.int(FlxMath.bound(slot, 0, slots - 1));
      var targetAngle:Float = angleStep * (centerSlot - edgeSlot);
      var dist:Float = Math.abs(Math.cos(targetAngle) * BUTTON_ANGLE_DISTANCE);

      button.localX = left ? baseX + dist : baseX - dist;
      var target:ButtonTarget = buttonTargets[index];
      target.x = left ? baseX + dist : baseX - dist;
      target.y = startY + ((QuickPanelButton.ITEM_HEIGHT + BUTTON_PADDING) * slot);
      target.angle = left ? -targetAngle : targetAngle;
      target.alpha = inView ? 1 : 0;

      button.inView = inView;
      button.repositionSide(left);

      if (snap) moveButton(button, target, 1);
    }
  }


  /**
   * Moves the button a fraction of the way to its target, then hides it.
   * @param button The button to move
   * @param target The button target
   * @param t Fraction
   */
  function moveButton(button:QuickPanelButton, target:ButtonTarget, t:Float):Void
  {
    button.localX = FlxMath.lerp(button.localX, target.x, t);
    button.localY = FlxMath.lerp(button.localY, target.y, t);
    button.localAngle = FlxMath.lerp(button.localAngle, target.angle, t);
    button.viewAlpha = FlxMath.lerp(button.viewAlpha, target.alpha, t);
    button.visible = button.viewAlpha > 0.01;
  }

  /**
   * Puts the pull tab above / below the panel sprite.
   * @param top Whether its uptop and down below.
   */
  public function setTabOnTop(top:Bool):Void
  {
    if (panelSprite != null) panelSprite.zIndex = top ? Z_BELOW : Z_ABOVE;
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
    if (!bodyBuilt) return;

    for (i => button in buttons) if (i == index || button.selected) button.selected = (i == index);

    var step:Float = SLICE_ANGLE_RANGE / 2;
    var centerSlot:Float = (visibleSlots - 1) / 2;

    panelShader.sliceVisible = true;
    panelShader.doLerp = true;
    panelShader.dir = -90 + step * (centerSlot - (index - windowStart));
    panelShader.sliceColorStart = disabled ? QuickPanelShader.START_COLOR_DISABLED : QuickPanelShader.START_COLOR_NORMAL;
    panelShader.sliceColorEnd = disabled ? QuickPanelShader.END_COLOR_DISABLED : QuickPanelShader.END_COLOR_NORMAL;
    startBreathe();
  }

  /**
   * Deselects every button and hides the shader slice.
   */
  public function clearSelection():Void
  {
    finishDeny();

    for (button in buttons) if (button.selected) button.selected = false;

    if (!bodyBuilt) return;

    stopBreathe();
    panelShader.sliceVisible = false;
  }

  /**
   * Kicks the slice in the scroll direction and briefly widens it.
   * @param direction -1 = moved up, 1 = moved down, 0 = no movement.
   */
  public function playScrollBump(direction:Int):Void
  {
    if (!bodyBuilt) return;

    finishDeny();
    stopScroll();

    if (direction != 0)
    {
      var from:Float = SCROLL_DIR_AMOUNT * (direction < 0 ? -1 : 1);
      panelShader.dirExtra = from;
      scrollTweens.push(FlxTween.num(from, 0, SCROLL_DIR_DURATION, {
        ease: FlxEase.quintOut
      }, (v:Float) -> panelShader.dirExtra = v));
    }

    panelShader.fatExtra = SCROLL_FAT_AMOUNT;
    scrollTweens.push(FlxTween.num(SCROLL_FAT_AMOUNT, 0, SCROLL_FAT_SETTLE, {
      startDelay: SCROLL_FAT_HOLD,
      ease: EaseUtil.backOut(SCROLL_FAT_OVERSHOOT)
    }, (v:Float) -> panelShader.fatExtra = v));
  }

  /**
   * Shakes the slice and greys it out.
   * @param onDone Called once the denying is done
   */
  public function playDeny(onDone:Void->Void):Void
  {
    if (!bodyBuilt)
    {
      if (onDone != null) onDone();
      return;
    }

    finishDeny();
    stopScroll();

    pendingDenyDone = onDone;
    panelShader.doLerp = false;
    panelShader.sliceColor = DENY_COLOR_A;

    scrollTweens.push(FlxTween.num(0, 1, DENY_DURATION, {
      onComplete: (_) -> finishDeny()
    }, (t:Float) ->
      {
        panelShader.dirExtra = DENY_SHAKE_AMOUNT * (1 - t) * Math.cos(t * DENY_SHAKE_CYCLES * 2 * Math.PI);
        panelShader.sliceColor = t < DENY_COLOR_SWAP ? DENY_COLOR_A : DENY_COLOR_B;
      }));
  }

  /**
   * Widens and flickers the slice, bumps the accepted button and fades the rest.
   * @param selectedIndex The index
   */
  public function playAccept(selectedIndex:Int, transitioning:Bool = true):Void
  {
    if (!bodyBuilt) return;

    finishDeny();
    stopScroll();
    panelShader.doLerp = false;

    panelShader.fatExtra = ACCEPT_FAT_AMOUNT;
    scrollTweens.push(FlxTween.num(ACCEPT_FAT_AMOUNT, 0, ACCEPT_DURATION, {
      ease: EaseUtil.backInOut()
    }, (v:Float) -> panelShader.fatExtra = v));

    panelShader.sliceColor = ACCEPT_COLOR_A;
    scrollTweens.push(FlxTween.num(0, ACCEPT_FLICKER_FRAMES, ACCEPT_DURATION, null, (frame:Float) ->
    {
      panelShader.sliceColor = (Std.int(frame / 2) % 2 == 0) ? ACCEPT_COLOR_A : ACCEPT_COLOR_B;
    }));

    for (i => button in buttons)
    {
      if (i == selectedIndex) button.playBump(true);
      else if (transitioning) button.fadeOut();
    }
  }

  /**
   * Slides the hint in next to the tab.
   * @param open Whether the panel is open.
   * @param canPull For touch, whether the user is able to pull the pull-tab or not.,
   */
  public function showHint(open:Bool, canPull:Bool = true):Void
  {
    var action:String = #if FEATURE_TOUCH_CONTROLS canPull ? 'PULL' : 'TAP' #else 'TAB' #end;

    pullHint.text = '($action) to ${open ? 'close' : 'open'} quick menu';
    pullHint.color = HINT_COLOR_NORMAL;
    hintBreathing = false;
    hintBreatheTimer = 0;

    cancelHintTween();

    var slideFrom:Float = left ? HINT_SLIDE_DISTANCE : -HINT_SLIDE_DISTANCE;
    pullHint.offset.x = slideFrom;
    pullHint.localAlpha = 0;

    hintTween = FlxTween.num(0, 1, HINT_DURATION, {
      ease: FlxEase.cubeOut,
      onComplete: (_) ->
      {
        hintTween = null;
        hintBreathing = true;
      }
    }, (p:Float) ->
      {
        pullHint.localAlpha = p;
        pullHint.offset.x = slideFrom * (1 - p);
      });
  }

  /**
   * Fades the hint out from wherever it currently is.
   */
  public function hideHint():Void
  {
    hintBreathing = false;
    cancelHintTween();

    hintTween = FlxTween.num(pullHint.localAlpha, 0, HINT_DURATION, {
      ease: FlxEase.cubeIn,
      onComplete: (_) -> hintTween = null
    }, (a:Float) -> pullHint.localAlpha = a);
    pullHint.color = HINT_COLOR_NORMAL;
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (bodyBuilt)
    {
      panelBoilTimer -= elapsed;
      if (panelBoilTimer <= 0)
      {
        panelBoilTimer += PANEL_BOIL_INTERVAL / 24;
        panelShader.updateBoil();
      }
    }

    if (hintBreathing)
    {
      hintBreatheTimer += elapsed;
      pullHint.color = FlxColor.interpolate(HINT_COLOR_DARK, HINT_COLOR_NORMAL, (Math.cos(hintBreatheTimer * 2) / 2) + 0.5);
    }
  }

  override public function destroy():Void
  {
    pendingDenyDone = null;
    cancelHintTween();
    for (tween in scrollTweens) if (tween != null) tween.cancel();
    scrollTweens = [];
    stopBreathe();
    if (pullTabVisual != null) FlxTween.cancelTweensOf(pullTabVisual);
    FlxTween.cancelTweensOf(this);
    buttons = [];

    super.destroy();
  }

  override function set_active(v:Bool):Bool
  {
    if (grpButtons != null) grpButtons.active = v;
    return super.set_active(v);
  }

  // Helpers

  /**
   * Ends the current deny, if any, and runs its callback.
   */
  function finishDeny():Void
  {
    var done = pendingDenyDone;
    if (done == null) return;
    pendingDenyDone = null;

    if (panelShader != null) panelShader.doLerp = true;
    done();
  }

  /**
   * Cancels any scroll / accept / deny animation and puts the shader back at rest.
   */
  function stopScroll():Void
  {
    for (tween in scrollTweens) tween.cancel();
    scrollTweens = [];

    if (panelShader == null) return;
    panelShader.dirExtra = defaultDirExtra;
    panelShader.fatExtra = defaultFatExtra;
    panelShader.sliceColor = defaultSliceColor;
  }

  /**
   * Starts the slice colour breathing loop, unless itss already running.
   */
  function startBreathe():Void
  {
    if (breatheTween != null && breatheTween.active) return;

    panelShader.sliceLerp = 0;
    breatheTween = FlxTween.num(0, 1, BREATHE_HALF_PERIOD, {
      type: PINGPONG,
      ease: FlxEase.quadInOut
    }, (v:Float) -> panelShader.sliceLerp = v);
  }

  /**
   * Stops the breath loop.
   */
  function stopBreathe():Void
  {
    if (breatheTween == null) return;
    breatheTween.cancel();
    breatheTween = null;
  }

  /**
   * Cancels the hint tween flair.
   */
  function cancelHintTween():Void
  {
    if (hintTween == null) return;
    hintTween.cancel();
    hintTween = null;
  }

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

typedef ButtonTarget =
{
  var x:Float;
  var y:Float;
  var angle:Float;
  var alpha:Float;
}
