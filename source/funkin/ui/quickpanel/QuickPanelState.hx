package funkin.ui.quickpanel;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.assets.Assets;
import funkin.assets.Assets.AssetType;
import funkin.assets.ValidatedPaths as Paths;
import funkin.assets.Paths.AssetPath;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.BoilShader;
import funkin.input.Controls;
import funkin.ui.UIStateMachine;
import funkin.data.quickpanel.PanelRegistry;
import funkin.data.quickpanel.PanelData.PanelButtonAnim;
import funkin.ui.quickpanel.QuickPanelTypes;
import funkin.ui.transition.Transition;
import funkin.util.MathUtil;
import funkin.util.PropertyAnimator;
import funkin.util.StateUtil;
#if FEATURE_TOUCH_CONTROLS
import funkin.util.TouchUtil;
#end

/**
 * The quick panel side menu.
 * TODO: Final one I promise, but please add comments to anything that doesn't have it + make sure theyre comprehensive
 * Like abnormal said, NO BLUE LINES! So no undocumented stuff!!
 * #sorry for getting lazy been fighting this for a while -Moon
 */
class QuickPanelState extends FlxTypedContainer<FlxBasic>
{
  public static var instance:QuickPanelState;
  public static final DEFAULT_PANEL_ID:String = 'default';

  /**
   * Horizontal travel in pixels before a tab press turns into a drag.
   */
  static final GRAB_THRESHOLD:Float = 15;

  /**
   * Fraction of OPEN_DISTANCE past which releasing a drag opens the panel.
   */
  static final OPEN_THRESHOLD:Float = 0.55;

  /**
   * Delay before held up/down starts repeating, then the repeat interval.
   */
  static final SCROLL_REPEAT_DELAY:Float = 0.4;

  /**
   * The hold spam interval.
   */
  static final SCROLL_REPEAT_INTERVAL:Float = 0.12;

  /**
   * Finger travel in pixels between drag tick sounds.
   */
  static final TICK_MIN_DISTANCE:Float = 40;

  /**
   * The cooldown for the drag tick sounds
   */
  static final TICK_COOLDOWN:Float = 0.08;

  /**
   * Seconds without input before the "(TAB) to open" hint appears.
   */
  static final HINT_INACTIVITY_DELAY:Float = 45;

  /**
   * Seconds the tab stays fully visible after activity, then how long it takes to fade to its minimum alpha
   */
  static final TAB_FADE_DELAY:Float = 3.0;

  /**
   * The tab fading duration
   */
  static final TAB_FADE_DURATION:Float = 1.5;

  /**
   * Background alpha.
   */
  static final BG_ALPHA:Float = 0.6;

  /**
   * Music ducking factor
   */
  static final MUSIC_DUCK_FACTOR:Float = 0.2;

  /**
   * Move Duration for the panel to open fully.
   */
  static final MOVE_DURATION:Float = 0.4;

  /**
   * How far below the screen the description bar sits while hidden.
   */
  static final DESCRIPTION_OFFSET:Float = 100;

  /**
   * Frames to wait after requesting the blocker before checking whether its load was cancelled.
   */
  static final BLOCKER_GRACE_FRAMES:Int = 3;

  /**
   * Whether the inactivity hint was shown or not.
   */
  static var inactivityHintUsed:Bool = false;

  /**
   * Helper timer variable for tab fading
   */
  static var tabFadeTimer:Float = 0;

  /**
   * The panel camera
   */
  public var panelCam(default, null):FunkinCamera;

  /**
   * The translucent bg for the panel
   */
  public var bg(default, null):FunkinSprite;

  /**
   * The visual panel itself
   */
  public var panel(default, null):QuickPanelGroup;

  /**
   * UI State
   */
  public var uiState(default, null):UIStateMachine;

  /**
   * The current UI state this panel is in.
   */
  public var curState(get, never):UIState;

  /**
   * Wether panel is open.
   */
  public var isOpen(get, never):Bool;

  /**
   * Locks the menu.
   */
  public var lock:Bool = false;

  public var allowOpen:Bool = true;

  /**
   * Whether the tab can be dragged
   */
  public var canPull:Bool = true;

  /**
   * Whether the panel is docked to the left edge.
   */
  public var left(default, null):Bool = false;

  /**
   * The currently selected button.
   */
  public var currentButton(get, never):Null<QuickPanelButton>;

  /**
   * The wiping sprite.
   */
  public var wipeSprite(default, null):FlxSprite;

  /**
   * The currently selected button's icon.
   */
  public var selectedIcon(default, null):FunkinSprite;

  /**
   * The currently selected button;s splash.
   */
  public var selectedSplash(default, null):FunkinSprite;

  /**
   * The circle wipe animation.
   */
  public var paWipe(default, null):PropertyAnimator;

  /**
   * The center icon bump animation.
   */
  public var paMiddle(default, null):PropertyAnimator;

  /**
   * Controls
   */
  var controls(get, never):Controls;

  /**
   * The description backing for the panel
   */
  var descriptionPanel:FunkinSprite;

  /**
   * The description text.
   */
  var descriptionText:FlxText;

  /**
   * Description panel Ypos
   */
  var descriptionPanelY:Float = 0;

  /**
   * Desciption panel text Ypos
   */
  var descriptionTextY:Float = 0;

  /**
   * The circular wipe boil shader.
   */
  var circleWipe:BoilShader;

  /**
   * The ticking sound.
   */
  var tickSound:Null<FunkinSound> = null;

  /**
   * Helper tween variable for panel moving
   */
  var moveTween:Null<FlxTween> = null;

  /**
   * Accept transition timers
   */
  var transitionTimers:Array<FlxTimer> = [];

  /**
   * Currently selected index
   */
  var curSelected:Int = 0;

  /**
   * Helper variable for spam-holding
   */
  var scrollHoldTime:Float = 0;

  /**
   * Is spamming
   */
  var scrollRepeating:Bool = false;

  /**
   * Helper timer variable for tab fading
   */
  var inactivityTimer:Float = 0;

  var hintVisible:Bool = false;

  /**
   * Is a press happening on the tab right now
   */
  var tracking:Bool = false;

  /**
   * Helper variable for the starting touch position
   */
  var trackStartX:Float = 0;

  /**
   * Helper variable for the distance traveled since the touch.
   */
  var trackDistance:Float = 0;

  /**
   * Helper variable for the previous distance traveled since the touch.
   */
  var prevTrackDistance:Float = 0;

  /**
   * How open the panel was, in pixels, when the press began.
   */
  var dragStartOpenness:Float = 0;

  /**
   * Where the press wants the panel, in pixels, after rubber-banding.
   */
  var dragTarget:Float = 0;

  /**
   * Smoothed openness actually applied to the panel.
   */
  var dragCurrent:Float = 0;

  /**
   * The current ticking distance
   */
  var tickDistance:Float = 0;

  /**
   * The current ticking cooldown
   */
  var tickCooldown:Float = 0;

  /**
   * The ducked sound.
   */
  var duckedMusic:Null<FlxSound> = null;

  /**
   * Ducked from what volume
   */
  var duckedFromVolume:Float = 1;

  /**
   * The blocker substate
   */
  var blocker:Null<PanelBlockerSubState> = null;

  /**
   * Remembered state data so we'd avoid annoying bugs for modders.
   */
  var savedPersistence:Array<
    {state:FlxState, update:Bool, draw:Bool}> = [];

  /**
   * The blocker constructed by the transition but not opened yet.
   */
  var pendingBlocker:Null<PanelBlockerSubState> = null;

  /**
   * Incremented per request. A blocker whose request id no longer matches is stale and closes itself.
   */
  var blockerRequest:Int = 0;

  /**
   * Blocker pending in frames.
   */
  var blockerPendingFrames:Int = 0;

  /**
   * Whether the panel body and transition visuals have been built.
   */
  var panelVisualsBuilt:Bool = false;

  /**
   *
   */
  public var panelId(default, null):String;

  public var pullTabEnabled(default, null):Bool;

  var buttonData:Array<QuickPanelButtonData> = [];

  /**
   * Makes a new QuickPanel.
   */
  public function new(panelId:String = 'default', showPullTab:Bool = true)
  {
    super();

    if (instance != null)
    {
      FlxG.log.warn('WARNING: QuickPanelState instance already exists. This should not happen.');
    }

    instance = this;

    this.panelId = panelId;
    this.pullTabEnabled = showPullTab;

    uiState = new UIStateMachine('QuickPanel', [
      PanelClosed => [PanelLoading, PanelDragging, PanelOpen],
      PanelLoading => [PanelOpen, PanelClosed],
      PanelDragging => [PanelLoading, PanelOpen, PanelClosed],
      PanelOpen => [PanelDragging, PanelConfirming, PanelClosed],
      PanelConfirming => [PanelClosed]
    ], PanelClosed);

    createCamera();
    buildBackdrop();

    buttonData = PanelRegistry.instance.listButtonData(panelId);
    panel = new QuickPanelGroup(buttonData, onButtonTapped, !pullTabEnabled);
    add(panel);

    tickSound = new FunkinSound();
    tickSound.loadEmbedded(Paths.sound('ui/quick-panel/sounds/tab-pull').toFlxSoundAsset());
    tickSound.volume = 1;
    FlxG.sound.defaultSoundGroup.add(tickSound);
    FlxG.sound.list.add(tickSound);

    forEach(obj -> obj.cameras = [panelCam]);

    repositionSide(left);
  }

  /**
   * Docks the panel to the left or right edge and snaps it to its current state.
   * If there's a drag in progress just can it
   * @param left We going left?
   */
  public function repositionSide(left:Bool = false):Void
  {
    this.left = left;

    var textCenterX:Float = (left ? FlxG.width + 443 : FlxG.width - 443) / 2;
    descriptionText.x = textCenterX - descriptionText.width / 2;

    if (wipeSprite != null) wipeSprite.flipX = left;
    panel.setSide(left);

    if (uiState.is(PanelOpen)) openPanel(true);
    else
      closePanel(true);
  }

  /**
   * Opens the panel.
   * @param instant Open it instantly
   */
  public function openPanel(instant:Bool = false):Void
  {
    if (blocker == null)
    {
      if (!canOpen()) return;
      requestBlocker(instant);
      return;
    }

    if (!uiState.is(PanelOpen) && !uiState.transition(PanelOpen)) return;

    duckMusic();
    movePanel(panel.openX, instant);

    panel.setTabOnTop(true);
    panel.pullTabVisual.release(curState);

    panel.bodyActive = true;
    changeSelection();
    fadeScreen(false, instant);
  }

  /**
   * Closes the panel.
   * @param instant Close it instantly
   */
  public function closePanel(instant:Bool = false):Void
  {
    lock = false;

    closeBlocker();

    if (!uiState.is(PanelClosed)) uiState.transition(PanelClosed);

    restoreMusic();
    movePanel(panel.closedX, instant);

    panel.setTabOnTop(true);
    panel.pullTabVisual.playIdle(curState);
    panel.clearSelection();

    fadeScreen(true, instant);
  }

  /**
   * Force shows the "(TAB) to open" hint on the next update.
   */
  public function showHint():Void
  {
    if (!pullTabEnabled) return;
    inactivityTimer = -1;
  }

  /**
   * Fades the pull tab to a given alpha value.
   * @param targetAlpha The alpha to fade to
   * @param duration How long would the fade take
   */
  public function fadeTab(targetAlpha:Float, duration:Float = 0.3):Void
  {
    FlxTween.cancelTweensOf(panel.pullTabVisual);
    if (duration <= 0)
    {
      panel.pullTabVisual.localAlpha = targetAlpha;
      return;
    }
    FlxTween.tween(panel.pullTabVisual, {
      localAlpha: targetAlpha
    }, duration, {
      ease: FlxEase.expoOut
    });
  }

  /**
   * Fades the dim background and description bar in or out.
   * @param out Are we going in or out
   */
  public function fadeScreen(out:Bool = false, instant:Bool = false):Void
  {
    FlxTween.cancelTweensOf(bg);
    FlxTween.cancelTweensOf(descriptionPanel);
    FlxTween.cancelTweensOf(descriptionText);

    if (!pullTabEnabled) fadeTab(out ? 0 : 1, instant ? 0 : 0.3);

    var bgAlpha:Float = out ? 0.0 : BG_ALPHA;
    var offset:Float = out ? DESCRIPTION_OFFSET : 0;

    if (instant)
    {
      bg.alpha = bgAlpha;
      descriptionPanel.y = descriptionPanelY + offset;
      descriptionText.y = descriptionTextY + offset;
      if (out && uiState.is(PanelClosed)) panel.bodyActive = false;

      return;
    }

    FlxTween.tween(bg, {
      alpha: bgAlpha
    }, 0.3, {
      ease: FlxEase.expoOut
    });
    FlxTween.tween(descriptionPanel, {
      y: descriptionPanelY + offset
    }, 0.4, {
      ease: FlxEase.expoOut
    });
    FlxTween.tween(descriptionText, {
      y: descriptionTextY + offset
    }, 0.4, {
      ease: FlxEase.expoOut,
      onComplete: (_) ->
      {
        if (out && uiState.is(PanelClosed)) panel.bodyActive = false;
      }
    });
  }

  /**
   * Updates the panel description.
   * @param text The text to use.
   */
  public function updateDescription(text:String):Void
  {
    if (descriptionText.text != text) descriptionText.text = text;
  }

  /**
   * Changes the selected button.
   * @param change How far to move the selection, or the index to jump to when `snap` is true.
   * @param snap If true, `change` is an absolute index. Snapping to the already-selected button accepts it.
   */
  public function changeSelection(change:Int = 0, snap:Bool = false):Void
  {
    if (!uiState.is(PanelOpen) || panel.buttons.length == 0) return;

    var prevSelected:Int = curSelected;
    var lastIndex:Int = panel.buttons.length - 1;
    curSelected = snap ? Std.int(FlxMath.bound(change, 0, lastIndex)) : FlxMath.wrap(curSelected + change, 0, lastIndex);

    if (snap || change != 0) FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/menu-scroll').toFlxSoundAsset());

    if (panel.buttons[prevSelected] != null && panel.buttons[prevSelected] != currentButton) panel.buttons[prevSelected].doUnselectCallback();

    var data:QuickPanelButtonData = currentButton.data;
    panel.showSelection(curSelected, data.disabled == true);
    updateDescription(data.description ?? '');

    if (snap && curSelected == prevSelected)
    {
      clickSelected();
      return;
    }

    var direction:Int = if (snap) (prevSelected > curSelected ? -1 : 1); else if (prevSelected == curSelected) 0; else (change < 0 ? -1 : 1);
    panel.playScrollBump(direction);
    currentButton.doSelectCallback();
  }

  /**
   * Plays the confirm transition, then runs the button's callback.
   * @param data The button data to use
   */
  public function startTransition(data:QuickPanelButtonData):Void
  {
    var animData:PanelButtonAnim = data.buttonAnim ?? PanelEntry.DEFAULT_ANIM_DATA;
    var acceptAnimName:Null<String> = null;

    switch (animData.animType)
    {
      case SPARROW_ATLAS:
        selectedIcon.loadSparrow('ui/quick-panel/icons/${data.icon}');
        acceptAnimName = animData.acceptName ?? "accept";
        selectedIcon.animation.addByPrefix(acceptAnimName, animData.acceptPrefix ?? "accept0", 24, false);
        // Hold on the first frame until the icon pops in at the center.
        selectedIcon.animation.play(acceptAnimName, true);
        selectedIcon.animation.pause();

      default:
        selectedIcon.loadGraphic(Paths.image('ui/quick-panel/icons/${data.icon}').toFlxGraphicAsset());
    }

    selectedIcon.scale.set(1.4, 1.4);
    selectedIcon.antialiasing = true;
    selectedIcon.updateHitbox();
    selectedIcon.screenCenter();

    afterFrames(6, () ->
    {
      wipeSprite.visible = true;
      paWipe.playAnimation('wipe', true);
    });

    afterFrames(8, () ->
    {
      selectedIcon.visible = true;
      if (acceptAnimName != null) selectedIcon.animation.play(acceptAnimName, true);
      paMiddle.playAnimation('bump', true);

      selectedSplash.visible = true;
      selectedSplash.animation.play('splash');
    });

    afterFrames(22, () ->
    {
      FlxTween.tween(selectedIcon, {
        alpha: 0
      }, 8 / 24, {
        ease: FlxEase.expoOut
      });
      if (data.callback != null) data.callback();
    });
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // wtf! someone just called flxg.cameras.reset!! Relax i'll handle it, i am the angry pumpkin
    if (panelCam == null || !FlxG.cameras.list.contains(panelCam)) createCamera(true);

    updateBlockerRequest();
    updateHint(elapsed);
    updateTabFade(elapsed);
    updatePanelInput(elapsed);
    updateNavigation(elapsed);

    #if FEATURE_DEBUG_FUNCTIONS
    if (FlxG.keys.justPressed.B) showHint(); // Shows the hint
    if (FlxG.keys.justPressed.F) repositionSide(!left); // Moves the panel to the side
    #end
  }

  /**
   * Updates the hint flair and text.
   * @param elapsed Elapsed.
   */
  function updateHint(elapsed:Float):Void
  {
    if (inactivityTimer > 0 && !inactivityHintUsed && pullTabEnabled) inactivityTimer -= elapsed;

    if (userIsActive())
    {
      inactivityTimer = HINT_INACTIVITY_DELAY;

      if (hintVisible)
      {
        hintVisible = false;
        panel.hideHint();
      }
    }

    if (inactivityTimer < 0 && !hintVisible)
    {
      inactivityHintUsed = true;
      hintVisible = true;
      resetTabFade();
      panel.showHint(uiState.is(PanelOpen), canPull);
    }

    if (uiState.is(PanelClosed))
    {
      bg.alpha = MathUtil.smoothLerpPrecision(bg.alpha, hintVisible ? BG_ALPHA : 0, elapsed, 1);
    }
  }

  /**
   * Checks whether the player is active or not.
   * Any key except volume keys or any touch counts as activity.
   * @return They active?
   */
  function userIsActive():Bool
  {
    var keyPressed:Bool = FlxG.keys.pressed.ANY && !controls.VOLUME_MUTE && !controls.VOLUME_UP && !controls.VOLUME_DOWN;

    #if FEATURE_DEBUG_FUNCTIONS
    keyPressed = keyPressed && !FlxG.keys.pressed.B;
    #end

    var touchPressed:Bool = false;
    #if FEATURE_TOUCH_CONTROLS
    touchPressed = TouchUtil.touch != null && TouchUtil.touch.pressed;
    #end
    return keyPressed || touchPressed;
  }

  /**
   * Updates the tab fade flair.
   * @param elapsed Elapsed.
   */
  function updateTabFade(elapsed:Float):Void
  {
    if (!pullTabEnabled) return;

    var tab = panel.pullTabVisual;

    #if FEATURE_TOUCH_CONTROLS
    if (tracking)
    {
      tabFadeTimer = 0;
      tab.localAlpha = 1.0;
      return;
    }
    #end

    if (!uiState.is(PanelClosed) || hintVisible) return;

    tabFadeTimer += elapsed;
    var progress:Float = FlxMath.bound((tabFadeTimer - TAB_FADE_DELAY) / TAB_FADE_DURATION, 0, 1);
    tab.localAlpha = FlxMath.lerp(1.0, QuickPanelGroup.TAB_MIN_ALPHA, progress);
  }

  /**
   * Resets the tab fade flair
   */
  function resetTabFade():Void
  {
    tabFadeTimer = 0;
    fadeTab(1.0);
  }

  /**
   * Updates the panel's input
   * @param elapsed Elapsied.
   */
  function updatePanelInput(elapsed:Float):Void
  {
    if (isHostTransitioning()) return;

    #if FEATURE_TOUCH_CONTROLS
    updateTracking(elapsed);
    #end

    if (uiState.is(PanelClosed) && !canOpen()) return;

    switch (curState)
    {
      case PanelClosed | PanelOpen:
        if (uiState.is(PanelOpen) && controls.BACK_P)
        {
          closePanel();
          FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/close-tab-click').toFlxSoundAsset());
          return;
        }

        #if FEATURE_DEBUG_MENU
        if (pullTabEnabled ? FlxG.keys.justPressed.TAB : controls.DEBUG_MENU)
        {
          resetTabFade();
          if (uiState.is(PanelClosed))
          {
            openPanel();
            FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/open-tab-click').toFlxSoundAsset());
          }
          else
          {
            closePanel();
            FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/close-tab-click').toFlxSoundAsset());
          }
          return;
        }
        #end

        #if FEATURE_TOUCH_CONTROLS
        updateTabTouch();
        #end

      case PanelDragging:
        #if FEATURE_TOUCH_CONTROLS
        updateDrag(elapsed);
        #end

      default:
        // PanelLoading / PanelConfirming: no input.
    }
  }

  // Yeah

  public function canOpen():Bool
  {
    if (!allowOpen) return false;
    if (isHostTransitioning()) return false;
    if (FlxG.state != null && FlxG.state.subState != null) return false;
    return true;
  }

  /**
   * Checks whether the current state is transitioning or not.
   */
  function isHostTransitioning():Bool
  {
    return Transition.isTransitionActive();
  }

  /**
   * Updates the navigation for the panel.
   * @param elapsed Elapsed.
   */
  function updateNavigation(elapsed:Float):Void
  {
    if (lock || !uiState.canInteract()) return;

    if (controls.ACCEPT_P)
    {
      clickSelected();
      return;
    }

    var up:Bool = controls.UI_UP;
    var down:Bool = controls.UI_DOWN;

    if (up == down) // neither, or both
    {
      scrollHoldTime = 0;
      scrollRepeating = false;
      return;
    }

    var direction:Int = up ? -1 : 1;

    if (controls.UI_UP_P || controls.UI_DOWN_P)
    {
      scrollHoldTime = 0;
      scrollRepeating = false;
      changeSelection(direction);
      return;
    }

    scrollHoldTime += elapsed;

    if (!scrollRepeating)
    {
      if (scrollHoldTime >= SCROLL_REPEAT_DELAY)
      {
        scrollRepeating = true;
        scrollHoldTime = 0;
        changeSelection(direction);
      }
    }
    else if (scrollHoldTime >= SCROLL_REPEAT_INTERVAL)
    {
      scrollHoldTime -= SCROLL_REPEAT_INTERVAL;
      changeSelection(direction);
    }
  }

  /**
   * Updates the pull-tab tracking
   * @param elapsed Elapsed.
   */
  #if FEATURE_TOUCH_CONTROLS
  function updateTracking(elapsed:Float):Void
  {
    if (TouchUtil.justReleased) tracking = false;
    if (!tracking) return;

    var touch = TouchUtil.touch;
    if (touch == null)
    {
      tracking = false;
      return;
    }

    tickCooldown -= elapsed;

    trackDistance = Math.abs(touch.x - trackStartX);
    tickDistance += Math.abs(trackDistance - prevTrackDistance);
    prevTrackDistance = trackDistance;
  }

  /**
   * Updates presses for the pull-tab.
   */
  function updateTabTouch():Void
  {
    var overTab:Bool = TouchUtil.overlaps(panel.pullTabHitbox);

    if (TouchUtil.justPressed && overTab) beginTabPress();

    if (tracking && canPull && trackDistance > GRAB_THRESHOLD)
    {
      if (!panel.bodyBuilt)
      {
        tracking = false;
        panel.setTabOnTop(true);
        openPanel();
        FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/open-tab-click').toFlxSoundAsset());
        return;
      }

      grabPanel();
      FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/tab-release-pull').toFlxSoundAsset());
      return;
    }

    // Without dragging, sliding off the tab cancels the press.
    if (tracking && !canPull && !overTab) cancelTabPress();

    if (TouchUtil.justReleased && overTab)
    {
      if (uiState.is(PanelClosed))
      {
        openPanel();
        FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/open-tab-click').toFlxSoundAsset());
      }
      else
      {
        closePanel();
        FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/close-tab-click').toFlxSoundAsset());
      }
      return;
    }

    // Tapping outside an open panel closes it.
    if (uiState.is(PanelOpen) && TouchUtil.justPressed && !overTab && !TouchUtil.overlaps(panel.panelSprite))
    {
      closePanel();
      FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/close-tab-click').toFlxSoundAsset());
    }
  }

  /**
   * Startss the tab pressing and their variables
   */
  function beginTabPress():Void
  {
    var touch = TouchUtil.touch;
    if (touch == null) return;

    tracking = true;
    trackStartX = touch.x;
    trackDistance = 0;
    prevTrackDistance = 0;
    tickDistance = 0;
    dragStartOpenness = panel.opennessOf(panel.x);

    panel.setTabOnTop(false);
    panel.pullTabVisual.press(curState);

    FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/tab-press').toFlxSoundAsset());
  }
  #end

  /**
   * Cancels the current tab press.
   */
  function cancelTabPress():Void
  {
    tracking = false;
    panel.setTabOnTop(true);
    panel.pullTabVisual.release(curState);
  }

  /**
   * Grabs the panel itself.
   */
  function grabPanel():Void
  {
    if (!uiState.transition(PanelDragging)) return;

    // Stop any open/close tween so it doesn't fight the finger.
    cancelMoveTween();
    panel.bodyActive = true;

    dragCurrent = panel.opennessOf(panel.x);
    dragTarget = dragCurrent;

    panel.setTabOnTop(true);
    panel.pullTabVisual.grab(curState);
    panel.clearSelection();
  }

  /**
   * Updates the dragging for pulling the pulltab.
   * @param elapsed Elapsedx
   */
  #if FEATURE_TOUCH_CONTROLS
  function updateDrag(elapsed:Float):Void
  {
    var touch = TouchUtil.touch;

    if (touch != null)
    {
      var raw:Float = dragStartOpenness + (touch.x - trackStartX) * (left ? 1 : -1);
      var progress:Float = Math.min(raw / QuickPanelGroup.OPEN_DISTANCE, 1.0);

      dragTarget = Math.max(0, QuickPanelGroup.OPEN_DISTANCE * FlxEase.sineOut(progress) + raw * 0.1);

      var openRatio:Float = Math.min(dragTarget / QuickPanelGroup.OPEN_DISTANCE, 1.0);

      dragCurrent = MathUtil.smoothLerpPrecision(dragCurrent, dragTarget, elapsed, 0.1);
      panel.x = panel.xForOpenness(dragCurrent);

      bg.alpha = MathUtil.smoothLerpPrecision(bg.alpha, FlxMath.lerp(0, BG_ALPHA, openRatio), elapsed, 0.1);

      playDragTick(openRatio);
    }

    if (touch == null || TouchUtil.justReleased)
    {
      tracking = false;

      if (dragTarget > QuickPanelGroup.OPEN_DISTANCE * OPEN_THRESHOLD)
      {
        openPanel();
        FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/open-tab-soft').toFlxSoundAsset());
      }
      else
      {
        closePanel();
        FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/close-tab-soft').toFlxSoundAsset());
      }
    }
  }
  #end

  /**
   * Plays the drag ticking sound.
   * @param openRatio The ratio for each tiick.
   */
  function playDragTick(openRatio:Float):Void
  {
    if (tickSound == null) return;
    if (tickDistance <= TICK_MIN_DISTANCE || tickCooldown >= 0) return;

    tickDistance = 0;
    tickCooldown = TICK_COOLDOWN;

    tickSound.pitch = FlxMath.lerp(0.8, 1.25, openRatio);
    tickSound.pan = FlxMath.lerp(left ? -0.5 : 0.5, 0, openRatio);
    tickSound.play(true);
  }

  function onButtonTapped(button:QuickPanelButton):Void
  {
    if (lock || !uiState.canInteract()) return;
    changeSelection(button.curIndex, true);
  }

  /**
   * Accepts the current button.
   */
  function clickSelected():Void
  {
    if (lock || !uiState.canInteract()) return;

    var button = currentButton;
    if (button == null) return;

    final isTransitioning:Bool = button.data?.transitioning ?? true;
    final isDisabled:Bool = button.data?.disabled ?? false;

    if (isDisabled)
    {
      lock = true;
      panel.playDeny(() -> lock = false);
      FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/menu-deny').toFlxSoundAsset());
      return;
    }

    if (!isTransitioning)
    {
      lock = true;
      panel.playAccept(curSelected, false);
      FunkinSound.playOnce(Paths.sound('ui/main-menu/confirm-menu').toFlxSoundAsset());

      afterFrames(6, () -> button.doCallback());
      afterFrames(10, () ->
      {
        panel.settleAccept();
        lock = false;
      });
      return;
    }

    if (!uiState.transition(PanelConfirming)) return;

    panel.playAccept(curSelected, isTransitioning);
    FunkinSound.playOnce(Paths.sound('ui/main-menu/confirm-menu').toFlxSoundAsset());

    startTransition(button.data);
  }

  /**
   * Creates the overlay camera
   * @param reset Whether to reset every member's camera.
   */
  function createCamera(reset:Bool = false):Void
  {
    panelCam = new FunkinCamera('panelCam', 0, 0, FlxG.width, FlxG.height);
    panelCam.bgColor = FlxColor.TRANSPARENT;
    panelCam.zoom = 1;
    FlxG.cameras.add(panelCam, false);
    if (reset) forEach(obj -> obj.cameras = [panelCam]);
  }

  /**
   * Makes the bg backdrop for the panel.
   */
  function buildBackdrop():Void
  {
    bg = new FunkinSprite(0, 0);
    bg.makeSolidColor(FlxG.width * 2, FlxG.height * 2, 0xFF1A1A1A);
    bg.scrollFactor.set(0, 0);
    bg.alpha = 0;
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    descriptionPanel = new FunkinSprite(0, 0);
    descriptionPanel.makeSolidColor(FlxG.width * 2, 60, 0xFF0B0B0B);
    descriptionPanel.scrollFactor.set(0, 0);
    descriptionPanel.updateHitbox();
    descriptionPanel.screenCenter(X);
    descriptionPanelY = FlxG.height - descriptionPanel.height;
    descriptionPanel.y = descriptionPanelY + DESCRIPTION_OFFSET;
    add(descriptionPanel);

    descriptionText = new FlxText(0, 0, 800, '', 30);
    descriptionText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinOptions', 'otf'), 30, 0xFFE6E6E6, CENTER);
    descriptionText.offset.y = -4;
    descriptionTextY = (descriptionPanelY + descriptionPanel.height / 2) - descriptionText.height / 2;
    descriptionText.y = descriptionTextY + DESCRIPTION_OFFSET;
    add(descriptionText);
  }

  /**
   * Builds the panel body and transition visuals.
   */
  function ensurePanelVisuals():Void
  {
    if (panelVisualsBuilt) return;
    panelVisualsBuilt = true;

    panel.buildBody();

    buildTransitionVisuals();
    setupTransitionAnims();
    wipeSprite.flipX = left;

    panel.cameras = [panelCam];
    var built:Array<FlxBasic> = [wipeSprite, selectedIcon, selectedSplash];
    for (obj in built) obj.cameras = [panelCam];
  }

  /**
   * Builds the transitional visual flair
   */
  function buildTransitionVisuals():Void
  {
    wipeSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
    wipeSprite.scrollFactor.set(0, 0);
    wipeSprite.updateHitbox();
    wipeSprite.screenCenter();
    wipeSprite.visible = false;
    add(wipeSprite);

    circleWipe = new BoilShader(true);
    wipeSprite.shader = circleWipe;

    selectedIcon = new FunkinSprite(0, 0);
    selectedIcon.scrollFactor.set(0, 0);
    selectedIcon.visible = false;
    selectedIcon.color = 0xFFCCCCCC;
    add(selectedIcon);

    selectedSplash = new FunkinSprite(0, 0);
    selectedSplash.frames = Assets.getSparrowAtlas(Paths.image('ui/quick-panel/splash'));
    selectedSplash.animation.addByPrefix('splash', 'splash0', 24, false);
    selectedSplash.screenCenter();
    selectedSplash.visible = false;
    selectedSplash.scale.set(1.85, 1.85);
    selectedSplash.color = 0xFFCCCCCC;
    add(selectedSplash);
  }

  /**
   * Sets up the circle wipe and center icon animations.
   */
  function setupTransitionAnims():Void
  {
    paWipe = new PropertyAnimator(circleWipe);
    paWipe.addAnimationByName('wipe', 24, false);
    paWipe.addProperty('wipe', 'circleRadius', [
      3.1,
      3.8,
      4.3,
      4.6,
      4.8,
      10.0
    ]);
    paWipe.setDefaultProperties();

    final bumpScale = [
      1.4,
      1.4,
      1.6,
      1.6,
      1.55,
      1.55,
      1.1,
      1.1,
      1.17,
      1.17,
      1.2
    ];

    paMiddle = new PropertyAnimator(selectedIcon);
    paMiddle.addAnimationByName('bump', 24, false);
    paMiddle.addProperty('bump', 'scale.x', bumpScale.copy());
    paMiddle.addProperty('bump', 'scale.y', bumpScale.copy());
    paMiddle.addProperty('bump', 'angle', [
      2.0,
      2.0,
      2.2,
      2.2,
      1.9,
      1.9,
      0.5,
      0.5,
      0.1,
      0.1,
      0.0
    ]);
    paMiddle.setDefaultProperties();
  }

  /**
   * Runs a callback after a number of 24fps frames.
   * @param frames The frames to run
   * @param fn The callback to run
   */
  function afterFrames(frames:Int, fn:Void->Void):Void
  {
    transitionTimers.push(new FlxTimer().start(frames / 24, _ -> fn()));
  }

  /**
   * Moves the panel to the given target.
   * @param targetX The target X pos
   * @param instant Whether it is instant.
   */
  function movePanel(targetX:Float, instant:Bool):Void
  {
    cancelMoveTween();

    if (instant) panel.x = targetX;
    else
      moveTween = FlxTween.tween(panel, {
        x: targetX
      }, MOVE_DURATION, {
        ease: FlxEase.expoOut
      });
  }

  /**
   * Cancels the move tween.
   */
  function cancelMoveTween():Void
  {
    if (moveTween == null) return;
    moveTween.cancel();
    moveTween = null;
  }

  /**
   * Ducks down the music.
   */
  function duckMusic():Void
  {
    if (duckedMusic != null) return; // Already ducked; don't compound.

    var music = FlxG.sound.music;
    if (music == null) return;

    duckedMusic = music;
    duckedFromVolume = music.volume;
    music.volume = duckedFromVolume * MUSIC_DUCK_FACTOR;
  }

  /**
   * Restores the music
   */
  function restoreMusic():Void
  {
    if (duckedMusic == null) return;

    if (FlxG.sound.music == duckedMusic && duckedMusic.exists) duckedMusic.volume = duckedFromVolume;

    duckedMusic = null;
  }

  /**
   * Opens the blocker substate through and queries the proper assets.
   * @param instant Whether the panel should snap open once ready.
   */
  function requestBlocker(instant:Bool):Void
  {
    // Already loading, or nothing to block.
    if (uiState.is(PanelLoading) || FlxG.state == null) return;
    if (!uiState.transition(PanelLoading)) return;

    blockerPendingFrames = 0;

    // Freeze the host now, so it doesn't keep running underneath the load.
    savePersistence();

    var requestId:Int = ++blockerRequest;

    Transition.openSubState(() -> new PanelBlockerSubState(), {
      assetQuery: queryPanelAssets.bind(_, buttonData),
      transition: Throbber,
      shouldPurgeCache: false,
      onConstruct: (subState) ->
      {
        var newBlocker:PanelBlockerSubState = cast subState;

        // The panel was closed or destroyed while loading.
        if (requestId != blockerRequest)
        {
          newBlocker.cancelled = true;
          return;
        }

        pendingBlocker = newBlocker;
        newBlocker.onReady = (readyBlocker) -> onBlockerReady(readyBlocker, instant);
      }
    });
  }

  /**
   * Called when the blocker substate is ready
   * @param readyBlocker The readied blocker substate.
   * @param instant Whether it is instant
   */
  function onBlockerReady(readyBlocker:PanelBlockerSubState,
    instant:Bool):Void
  {
    pendingBlocker = null;
    blockerPendingFrames = 0;
    blocker = readyBlocker;

    ensurePanelVisuals();
    openPanel(instant);
  }

  /**
   * Updates the blocker request.
   * If another transition replaced ours mid-load, the blocker never arrives.
   * Detect that and back out cleanly instead of leaving the host frozen.
   */
  function updateBlockerRequest():Void
  {
    if (!uiState.is(PanelLoading) || pendingBlocker != null) return;

    // Give the loading substate a couple of frames to actually open.
    if (++blockerPendingFrames < BLOCKER_GRACE_FRAMES) return;
    if (Transition.isTransitionActive()) return;

    closePanel(true);
  }

  /**
   * Stops every state in the stack from updating (they keep drawing) and remembers the old flags.
   */
  function savePersistence():Void
  {
    if (savedPersistence.length > 0 || FlxG.state == null) return;

    for (state in StateUtil.getAllStates(FlxG.state))
    {
      savedPersistence.push({
        state: state,
        update: state.persistentUpdate,
        draw: state.persistentDraw
      });
      state.persistentDraw = true;
      state.persistentUpdate = false;
    }
  }

  /**
   * Closes the blocker properly and restore's the host state's params.
   */
  function closeBlocker():Void
  {
    for (entry in savedPersistence)
    {
      entry.state.persistentUpdate = entry.update;
      entry.state.persistentDraw = entry.draw;
    }
    savedPersistence = [];

    // Abandon an in-flight request.
    if (uiState.is(PanelLoading))
    {
      blockerRequest++;
      if (pendingBlocker != null) pendingBlocker.cancelled = true;
      pendingBlocker = null;
      blockerPendingFrames = 0;
    }

    if (blocker == null) return;
    blocker.close();
    blocker = null;
  }

  override public function destroy():Void
  {
    for (timer in transitionTimers) if (timer != null) timer.cancel();
    transitionTimers = [];

    cancelMoveTween();

    if (bg != null) FlxTween.cancelTweensOf(bg);
    if (descriptionPanel != null) FlxTween.cancelTweensOf(descriptionPanel);
    if (descriptionText != null) FlxTween.cancelTweensOf(descriptionText);
    if (selectedIcon != null) FlxTween.cancelTweensOf(selectedIcon);

    restoreMusic();
    closeBlocker();

    if (tickSound != null)
    {
      FlxG.sound.defaultSoundGroup.remove(tickSound);
      FlxG.sound.list.remove(tickSound, true);
      tickSound.destroy();
      tickSound = null;
    }

    if (paWipe != null) paWipe.destroy();
    if (paMiddle != null) paMiddle.destroy();

    super.destroy();

    // A camera reset during a state switch may already have removed and destroyed it.
    if (panelCam != null && FlxG.cameras.list.contains(panelCam)) FlxG.cameras.remove(panelCam);
    panelCam = null;
  }

  /**
   * Stops the current music playing.
   */
  public static function stopMusic():Void
  {
    if (FlxG.sound.music == null) return;
    FlxG.sound.music.destroy();
    FlxG.sound.music = null;
  }

  /**
   * Builds a NextState that recreates the current state (scripted, cppia or native).
   */
  static function getReturnState():flixel.util.typeLimit.NextState
  {
    var state:Dynamic = cast FlxG.state;
    if (state._asc != null)
    {
      if (Std.isOfType(state, funkin.ui.MusicBeatState) || Std.isOfType(state, funkin.ui.MusicBeatSubState))
      {
        return state.getHotReloadParams().targetState;
      }
      @:privateAccess
      var path:String = state._asc?.fullyQualifiedName;
      var constructorArgs:Array<Dynamic> = state._asc?.getConstructorArgs() ?? [];
      return () ->
      {
        var newState:Null<flixel.FlxState> = null;
        if (Std.isOfType(state, flixel.FlxState))
        {
          newState = flixel.FlxState.scriptInit(path, ...constructorArgs);
        }
        else if (Std.isOfType(state, FlxSubState))
        {
          newState = FlxSubState.scriptInit(path, ...constructorArgs);
        }
        if (newState == null) return new funkin.ui.mainmenu.MainMenuState();
        return newState;
      }
    }
    var clsName:String = Type.getClassName(Type.getClass(state));
    if (funkin.modding.CppiaScripts.exists(clsName))
    {
      return () ->
      {
        var newState:Null<flixel.FlxState> = funkin.modding.CppiaScripts.exists(clsName) ? cast funkin.modding.CppiaScripts.create(clsName) : null;
        if (newState == null) return new funkin.ui.mainmenu.MainMenuState();
        return newState;
      }
    }
    if (Std.isOfType(state, funkin.ui.MusicBeatState) || Std.isOfType(state, funkin.ui.MusicBeatSubState))
    {
      return state.getHotReloadParams().targetState;
    }
    return state._constructor;
  }

  /**
   * Produce a list of all the AssetPaths that the pull tab depends on to load.
   * These must be cached before the host state appears.
   *
   * @param type The type of AssetPath to return a list of paths for.
   * @return A list of AssetPaths of that type that the interface will use.
   */
  public static function queryAssets(type:AssetType):Array<AssetPath>
  {
    var results = [];

    var tabAtlases:Array<String> = ['ui/quick-panel/tabSquare'];
    #if !FEATURE_TOUCH_CONTROLS
    tabAtlases.push('ui/quick-panel/tabSquareKeyboard');
    #end

    switch (type)
    {
      case IMAGE:
        for (atlas in tabAtlases) results.append(Paths.animateAtlas(atlas).image());

      case SOUND:
        results.push(Paths.sound('ui/quick-panel/sounds/tab-pull'));
        results.push(Paths.sound('ui/quick-panel/sounds/open-tab-soft'));
        results.push(Paths.sound('ui/quick-panel/sounds/close-tab-soft'));
        results.push(Paths.sound('ui/quick-panel/sounds/open-tab-click'));
        results.push(Paths.sound('ui/quick-panel/sounds/close-tab-click'));
        #if FEATURE_TOUCH_CONTROLS
        results.push(Paths.sound('ui/quick-panel/sounds/tab-press'));
        results.push(Paths.sound('ui/quick-panel/sounds/tab-release-pull'));
        #end

      case JSON:
        for (atlas in tabAtlases) results.append(Paths.animateAtlas(atlas).json());

      default:
        // No assets.
    }

    return results;
  }

  /**
   * Produce a list of all the AssetPaths that the side panel depends on to load.
   * Loaded by the blocker transition when the panel is opened.
   *
   * @param type The type of AssetPath to return a list of paths for.
   * @return A list of AssetPaths of that type that the interface will use.
   */
  public static function queryPanelAssets(type:AssetType,
    ?buttonData:Array<QuickPanelButtonData>):Array<AssetPath>
  {
    var results = [];

    // results.append(funkin.data.quickpanel.PanelRegistry.queryPanelAssets(type, currentPanelId));
    switch (type)
    {
      case IMAGE:
        results.push(Paths.image('ui/boil_texture'));
        results.push(Paths.image('ui/quick-panel/splash'));
        results.push(Paths.image('ui/quick-panel/panel-bg'));
        if (buttonData != null) for (data in buttonData) results.push(Paths.image('ui/quick-panel/icons/${data.icon}'));

      case XML:
        results.push(Paths.xml('ui/quick-panel/splash'));
        results.push(Paths.xml('ui/quick-panel/panel-bg'));

      case SOUND:
        results.push(Paths.sound('ui/quick-panel/sounds/menu-scroll'));
        results.push(Paths.sound('ui/quick-panel/sounds/menu-deny'));
        results.push(Paths.sound('ui/main-menu/confirm-menu'));
        #if FEATURE_TOUCH_CONTROLS
        results.push(Paths.sound('ui/quick-panel/sounds/menu-press'));
        #end

      default:
        // No assets.
    }

    return results;
  }

  // Getters

  inline function get_controls():Controls return PlayerSettings.player1.controls;

  inline function get_curState():UIState return uiState.currentState;

  inline function get_isOpen():Bool return uiState.is(PanelOpen);

  function get_currentButton():Null<QuickPanelButton>
  {
    if (panel == null || curSelected < 0 || curSelected >= panel.buttons.length) return null;
    return panel.buttons[curSelected];
  }
}
