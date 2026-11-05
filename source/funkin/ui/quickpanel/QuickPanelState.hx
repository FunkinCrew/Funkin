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
import funkin.assets.ValidatedPaths as Paths;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.input.Controls;
import funkin.ui.options.OptionsSubState;
import funkin.ui.quickpanel.QuickPanelTypes;
import funkin.ui.transition.Transition;
import funkin.util.MathUtil;
import funkin.util.PropertyAnimator;
import funkin.graphics.shaders.BoilShader;
import funkin.util.StateUtil;
import funkin.util.TouchUtil;

/**
 * The quick panel side menu.
 */
class QuickPanelState extends FlxTypedContainer<FlxBasic>
{
  /**
   * Default button data.
   * TODO: Make this not super hardcoded.
   */
  public static final DEFAULT_BUTTON_DATA:Array<QuickPanelButtonData> = [
    {
      text: 'Exit Mod',
      callback: () ->
      {
        stopMusic();
        Transition.switchState(() -> new funkin.ui.title.TitleState(), {
          assetQuery: funkin.ui.title.TitleState.queryAssets,
          transition: BlackScreen(Fade(North), Fade(South))
        });
      },
      icon: 'back',
      description: 'Return to the base game\'s title screen.',
      disabled: false
    },
    {
      text: 'Mods',
      callback: () ->
      {
        stopMusic();
        Transition.switchState(() -> new funkin.ui.modmenu.ModMenuState(), {
          assetQuery: funkin.ui.modmenu.ModMenuState.queryAssets,
          transition: BlackScreen(Fade(North), Fade(South))
        });
      },
      icon: 'mods',
      description: 'Add, remove or install custom content for the game.',
      disabled: false
    },
    {
      text: 'Freeplay',
      callback: () ->
      {
        var freeplayParams = {
          fromCharSelect: true
        };
        Transition.switchState(() -> funkin.ui.freeplay.FreeplayState.build(freeplayParams), {
          assetQuery: funkin.ui.freeplay.FreeplayState.queryAssets.bind(_, freeplayParams),
          transition: BlackScreen(None, Fade(South))
        });
      },
      icon: 'freeplay',
      description: 'Choose and play any song you\'ve previously unlocked.',
      disabled: false
    },
    {
      text: 'Online',
      callback: null,
      icon: 'online',
      description: 'Play against friends, or with people around the world.',
      disabled: true
    },
    {
      text: 'Options',
      callback: () ->
      {
        // TODO: getReturnState() was computed here and discarded. Pass it to OptionsSubState once it accepts one.
        playMenuMusic();
        Transition.switchState(() -> new OptionsSubState(), {
          assetQuery: OptionsSubState.queryAssets,
          transition: None,
          shouldPurgeCache: false
        });
      },
      icon: 'options',
      description: 'Configure various gameplay and visual settings.',
      disabled: false
    }
  ];

  /**
   * Horizontal threshold in pixels before a tab press turns into a drag.
   */
  static final GRAB_THRESHOLD:Float = 15;

  /**
   * Fraction of OPEN_DISTANCE past which releasing a drag opens the panel.
   */
  static final OPEN_THRESHOLD:Float = 0.55;

  /**
   * Seconds without input before the "(TAB) to open" hint appears.
   */
  static final HINT_INACTIVITY_DELAY:Float = 45;

  /**
   * The tab d
   */
  static final TAB_FADE_DELAY:Float = 3.0;

  static final TAB_FADE_DURATION:Float = 1.5;
  static final BG_ALPHA:Float = 0.6;
  static final MUSIC_DUCK_FACTOR:Float = 0.2;
  static final MOVE_DURATION:Float = 0.4;
  static final SCROLL_REPEAT_DELAY:Float = 0.4;
  static final SCROLL_REPEAT_INTERVAL:Float = 0.12;
  static final TICK_MIN_DISTANCE:Float = 40;
  static final TICK_COOLDOWN:Float = 0.08;
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

  public var panelCam(default, null):FunkinCamera;
  public var bg(default, null):FunkinSprite;
  public var panel(default, null):QuickPanelGroup;
  public var curState(default, null):PanelState = CLOSED;
  public var isOpen(get, never):Bool;

  /**
   * Locks the menu.
   */
  public var lock:Bool = false;

  /**
   * Whether the tab can be dragged
   */
  public var canPull:Bool = true;

  public var left(default, null):Bool = false;
  public var currentButton(get, never):Null<QuickPanelButton>;
  public var wipeSprite(default, null):FlxSprite;
  public var selectedIcon(default, null):FunkinSprite;
  public var selectedSplash(default, null):FunkinSprite;
  public var paWipe(default, null):PropertyAnimator;
  public var paMiddle(default, null):PropertyAnimator;

  var controls(get, never):Controls;
  var descriptionPanel:FunkinSprite;
  var descriptionText:FlxText;
  var descriptionPanelY:Float = 0;
  var descriptionTextY:Float = 0;
  var circleWipe:BoilShader;
  var tickSound:Null<FunkinSound> = null;
  var moveTween:Null<FlxTween> = null;
  var transitionTimers:Array<FlxTimer> = [];
  var curSelected:Int = 0;
  var scrollHoldTime:Float = 0;
  var scrollRepeating:Bool = false;
  var inactivityTimer:Float = 0;
  var hintVisible:Bool = false;
  var hostState:Null<MusicBeatState> = null;
  // TODO: Probably lock these behind the touch define.

  /**
   * True from a touch landing on the tab until it lifts.
   */
  var tracking:Bool = false;

  var trackStartX:Float = 0;
  var trackDistance:Float = 0;
  var prevTrackDistance:Float = 0;

  /**
   * How open the panel was (px) when the press began.
   */
  var dragStartOpenness:Float = 0;

  /**
   * Where the finger wants the panel (px open), after rubber-banding.
   */
  var dragTarget:Float = 0;

  /**
   * Smoothed openness actually applied to the panel.
   */
  var dragCurrent:Float = 0;

  var tickDistance:Float = 0;
  var tickCooldown:Float = 0;
  // Music ducking: remember which sound we ducked so we never restore a different one.
  var duckedMusic:Null<FlxSound> = null;
  var duckedFromVolume:Float = 1;
  // Host blocking: remember the flags we overwrote so they can be put back exactly.
  var blocker:Null<PanelBlockerSubState> = null;
  var savedPersistence:Array<
    {state:FlxState, update:Bool, draw:Bool}> = [];

  /**
   * True while the blocker (and the panel's assets) are being loaded.
   */
  var blockerPending:Bool = false;

  /**
   * The blocker that has been constructed by the transition but not opened yet.
   */
  var pendingBlocker:Null<PanelBlockerSubState> = null;

  /**
   * Incremented per request. A blocker whose request id no longer matches is stale and closes itself.
   */
  var blockerRequest:Int = 0;

  var blockerPendingFrames:Int = 0;

  /**
   * Whether the panel body and transition visuals have been built.
   */
  var panelVisualsBuilt:Bool = false;

  public function new()
  {
    super();

    createCamera();
    buildBackdrop();

    panel = new QuickPanelGroup(DEFAULT_BUTTON_DATA, onButtonTapped);
    add(panel);

    tickSound = new FunkinSound();
    tickSound.loadEmbedded(Paths.sound('ui/quick-panel/sounds/tab-pull').toFlxSoundAsset());
    tickSound.volume = 1;
    FlxG.sound.defaultSoundGroup.add(tickSound);
    FlxG.sound.list.add(tickSound);

    forEach(obj -> obj.cameras = [panelCam]);

    repositionSide(left);
  }

  function createCamera(reset:Bool = false):Void
  {
    panelCam = new FunkinCamera('panelCam', 0, 0, FlxG.width, FlxG.height);
    panelCam.bgColor = FlxColor.TRANSPARENT;
    panelCam.zoom = 1;
    FlxG.cameras.add(panelCam, false);
    if (reset) forEach(obj -> obj.cameras = [panelCam]);
  }

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
   * Builds the entirety of the panel
   * Called once the blocker transition has finished loading them.
   */
  function ensurePanelVisuals():Void
  {
    if (panelVisualsBuilt) return;
    panelVisualsBuilt = true;

    panel.buildBody();

    buildTransitionVisuals();
    setupTransitionAnims();
    wipeSprite.flipX = left;

    // Members added after construction may not inherit the camera.
    panel.cameras = [panelCam];
    var built:Array<FlxBasic> = [wipeSprite, selectedIcon, selectedSplash];
    for (obj in built) obj.cameras = [panelCam];
  }

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

    if (curState == OPEN) openPanel(true);
    else
      closePanel(true);
  }

  public function openPanel(instant:Bool = false):Void
  {
    if (blocker == null)
    {
      requestBlocker(instant);
      return;
    }

    curState = OPEN;

    duckMusic();
    movePanel(panel.openX, instant);

    panel.setTabOnTop(true);
    panel.pullTabVisual.release(curState);

    changeSelection();
    panel.active = true;
    fadeScreen(false);
  }

  public function closePanel(instant:Bool = false):Void
  {
    curState = CLOSED;

    closeBlocker();
    restoreMusic();
    movePanel(panel.closedX, instant);

    panel.setTabOnTop(true);
    panel.pullTabVisual.playIdle(curState);
    panel.clearSelection();

    fadeScreen(true);
  }

  /**
   * Shows the "(TAB) to open" hint on the next update.
   */
  public function showHint():Void
  {
    inactivityTimer = -1;
    panel.active = true;
  }

  /**
   * Fades the pull tab to a given alpha value.
   * @param targetAlpha The alpha to fade to
   * @param duration How long would the fade take
   */
  public function fadeTab(targetAlpha:Float, duration:Float = 0.3):Void
  {
    FlxTween.cancelTweensOf(panel.pullTabVisual);
    FlxTween.tween(panel.pullTabVisual, {
      alpha: targetAlpha
    }, duration, {
      ease: FlxEase.expoOut
    });
  }

  /**
   * Fades the dim background and description bar in or out.
   * @param out Are we going in or out
   */
  public function fadeScreen(out:Bool = false):Void
  {
    FlxTween.cancelTweensOf(bg);
    FlxTween.cancelTweensOf(descriptionPanel);
    FlxTween.cancelTweensOf(descriptionText);

    FlxTween.tween(bg, {
      alpha: out ? 0.0 : BG_ALPHA
    }, 0.3, {
      ease: FlxEase.expoOut
    });

    var offset:Float = out ? DESCRIPTION_OFFSET : 0;
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
        if (out) panel.active = false;
      }
    });
  }

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
    if (curState != OPEN || panel.buttons.length == 0) return;

    var prevSelected:Int = curSelected;

    curSelected = snap ? Std.int(FlxMath.bound(change, 0, panel.buttons.length - 1)) : FlxMath.wrap(curSelected + change, 0, panel.buttons.length - 1);

    if (snap || change != 0) FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/menu-scroll').toFlxSoundAsset());

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
  }

  /**
   * Plays the confirm transition, then runs the button's callback.
   * @param data The button data to use
   */
  public function startTransition(data:QuickPanelButtonData):Void
  {
    selectedIcon.loadGraphic(Paths.image('ui/quick-panel/icons/${data.icon}').toFlxGraphicAsset());
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
    if (panelCam == null || !FlxG.cameras.list.contains(panelCam))
    {
      // wtf! someone just called flxg.cameras.reset!! Relax i'll handle it, i am the angry pumpkin
      createCamera(true);
    }

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

  function updateHint(elapsed:Float):Void
  {
    if (inactivityTimer > 0 && !inactivityHintUsed) inactivityTimer -= elapsed;

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
      panel.showHint(curState == OPEN);
    }

    if (curState == CLOSED)
    {
      bg.alpha = MathUtil.smoothLerpPrecision(bg.alpha, hintVisible ? BG_ALPHA : 0, elapsed, 1);
    }
  }

  function userIsActive():Bool
  {
    #if FEATURE_DEBUG_FUNCTIONS
    var keyPressed:Bool = FlxG.keys.pressed.ANY && !controls.VOLUME_MUTE && !controls.VOLUME_UP && !controls.VOLUME_DOWN && !FlxG.keys.pressed.B;
    #else
    var keyPressed:Bool = FlxG.keys.pressed.ANY && !controls.VOLUME_MUTE && !controls.VOLUME_UP && !controls.VOLUME_DOWN;
    #end
    var touchPressed:Bool = TouchUtil.touch != null && TouchUtil.touch.pressed;
    return keyPressed || touchPressed;
  }

  function updateTabFade(elapsed:Float):Void
  {
    var tab = panel.pullTabVisual;

    #if FEATURE_TOUCH_CONTROLS
    if (tracking)
    {
      tabFadeTimer = 0;
      tab.alpha = 1.0;
      return;
    }
    #end

    if (curState != CLOSED || hintVisible) return;

    tabFadeTimer += elapsed;
    var progress:Float = FlxMath.bound((tabFadeTimer - TAB_FADE_DELAY) / TAB_FADE_DURATION, 0, 1);
    tab.alpha = FlxMath.lerp(1.0, QuickPanelGroup.TAB_MIN_ALPHA, progress);
  }

  function resetTabFade():Void
  {
    tabFadeTimer = 0;
    fadeTab(1.0);
  }

  function updatePanelInput(elapsed:Float):Void
  {
    if (blockerPending || isHostTransitioning()) return;

    #if FEATURE_TOUCH_CONTROLS
    updateTracking(elapsed);
    #end

    switch (curState)
    {
      case CLOSED | OPEN:
        if (FlxG.keys.justPressed.TAB)
        {
          resetTabFade();
          if (curState == CLOSED)
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

        #if FEATURE_TOUCH_CONTROLS
        updateTabTouch();
        #end

      case OPENING:
        #if FEATURE_TOUCH_CONTROLS
        updateDrag(elapsed);
        #end
    }
  }

  function isHostTransitioning():Bool
  {
    if (hostState == null && Std.isOfType(FlxG.state, MusicBeatState)) hostState = cast FlxG.state;
    return hostState != null && hostState.default_trans_isTransitioning;
  }

  function updateNavigation(elapsed:Float):Void
  {
    if (lock || curState != OPEN) return;

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

  // Touch stuff

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
   * Handles presses, taps and grabs on the tab while the panel is CLOSED or OPEN.
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
      if (curState == CLOSED)
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
    if (curState == OPEN && TouchUtil.justPressed && !overTab && !TouchUtil.overlaps(panel.panelSprite))
    {
      closePanel();
      FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/close-tab-click').toFlxSoundAsset());
    }
  }

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

  function cancelTabPress():Void
  {
    tracking = false;
    panel.setTabOnTop(true);
    panel.pullTabVisual.release(curState);
  }

  function grabPanel():Void
  {
    // Stop any open/close tween so it doesnt fight the finger
    cancelMoveTween();

    dragCurrent = panel.opennessOf(panel.x);
    dragTarget = dragCurrent;

    panel.setTabOnTop(true);
    panel.pullTabVisual.grab(curState);
    panel.clearSelection();

    curState = OPENING;
  }

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
    if (lock || curState != OPEN) return;
    changeSelection(button.curIndex, true);
  }

  function clickSelected():Void
  {
    if (curState != OPEN || lock) return;

    var button = currentButton;
    if (button == null) return;

    lock = true;

    if (button.data.disabled == true)
    {
      panel.playDeny(() -> lock = false);
      FunkinSound.playOnce(Paths.sound('ui/quick-panel/sounds/menu-deny').toFlxSoundAsset());
      return;
    }

    panel.playAccept(curSelected);
    FunkinSound.playOnce(Paths.sound('ui/main-menu/confirm-menu').toFlxSoundAsset());

    startTransition(button.data);
  }

  /**
   * Runs `fn` after a number of 24fps frames.
   * @param frames How many frames of 24fps frames.
   * @param fn The callback to run
   */
  function afterFrames(frames:Int, fn:Void->Void):Void
  {
    transitionTimers.push(new FlxTimer().start(frames / 24, _ -> fn()));
  }

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

  function cancelMoveTween():Void
  {
    if (moveTween == null) return;
    moveTween.cancel();
    moveTween = null;
  }

  function duckMusic():Void
  {
    if (duckedMusic != null) return; // already ducked, don't compound

    var music = FlxG.sound.music;
    if (music == null) return;

    duckedMusic = music;
    duckedFromVolume = music.volume;
    music.volume = duckedFromVolume * MUSIC_DUCK_FACTOR;
  }

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
    if (blockerPending || FlxG.state == null) return;

    blockerPending = true;
    blockerPendingFrames = 0;
    lock = true;

    // Freeze the host now, so it doesn't keep running underneath the load.
    savePersistence();

    var requestId:Int = ++blockerRequest;

    Transition.openSubState(() -> new PanelBlockerSubState(), {
      assetQuery: queryPanelAssets,
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

  function onBlockerReady(readyBlocker:PanelBlockerSubState,
    instant:Bool):Void
  {
    blockerPending = false;
    pendingBlocker = null;
    blocker = readyBlocker;
    lock = false;

    ensurePanelVisuals();
    openPanel(instant);
  }

  /**
   * If another transition replaced ours mid-load, the blocker never arrives.
   * Detect that and back out cleanly instead of leaving the host frozen.
   */
  function updateBlockerRequest():Void
  {
    if (!blockerPending || pendingBlocker != null) return;

    // Give the loading substate a couple of frames to actually open.
    if (++blockerPendingFrames < BLOCKER_GRACE_FRAMES) return;
    if (Transition.isTransitionActive()) return;

    closePanel(true);
  }

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

  function closeBlocker():Void
  {
    // Put back exactly what we changed, rather than forcing persistentUpdate on.
    for (entry in savedPersistence)
    {
      entry.state.persistentUpdate = entry.update;
      entry.state.persistentDraw = entry.draw;
    }
    savedPersistence = [];

    // Abandon an in-flight request.
    if (blockerPending)
    {
      blockerRequest++;
      if (pendingBlocker != null) pendingBlocker.cancelled = true;
      pendingBlocker = null;
      blockerPending = false;
      lock = false;
    }

    if (blocker == null) return;
    blocker.close();
    blocker = null;
  }

  override public function destroy():Void
  {
    for (timer in transitionTimers) timer.cancel();
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

    super.destroy();

    // A camera reset during a state switch may already have removed and destroyed it.
    if (panelCam != null && FlxG.cameras.list.contains(panelCam)) FlxG.cameras.remove(panelCam);
    panelCam = null;
  }

  public static function playMenuMusic():Void
  {
    FlxG.sound.music?.stop();
    funkin.audio.MenuMusicGroup.instance.reset(OPTIONS_MENU);
  }

  public static function stopMusic():Void
  {
    if (FlxG.sound.music == null) return;
    FlxG.sound.music.destroy();
    FlxG.sound.music = null;
  }

  /**
   * Builds a NextState that recreates the current state (scripted, cppia or native).
   * Currently unused; see the TODO in the Options button.
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
      var path:String = state._asc?.fullyQualifiedName ?? '';
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

    switch (type)
    {
      case IMAGE:
        #if FEATURE_TOUCH_CONTROLS
        results.append(Paths.animateAtlas('ui/quick-panel/tabSquare').image());
        #end
        results.append(Paths.animateAtlas('ui/quick-panel/tabSquareKeyboard').image());

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
        #if FEATURE_TOUCH_CONTROLS
        results.append(Paths.animateAtlas('ui/quick-panel/tabSquare').json());
        #end
        results.append(Paths.animateAtlas('ui/quick-panel/tabSquareKeyboard').json());

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
  public static function queryPanelAssets(type:AssetType):Array<AssetPath>
  {
    var results = [];

    switch (type)
    {
      case IMAGE:
        results.push(Paths.image('ui/boil_texture'));
        results.push(Paths.image('ui/quick-panel/splash'));
        results.push(Paths.image('ui/quick-panel/panel-bg'));
        for (buttonData in DEFAULT_BUTTON_DATA)
        {
          results.push(Paths.image('ui/quick-panel/icons/${buttonData.icon}'));
        }

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

  /// Helpers

  inline function get_controls():Controls return PlayerSettings.controls;

  inline function get_isOpen():Bool return curState == OPEN;

  function get_currentButton():Null<QuickPanelButton>
  {
    if (panel == null || curSelected < 0 || curSelected >= panel.buttons.length) return null;
    return panel.buttons[curSelected];
  }
}
