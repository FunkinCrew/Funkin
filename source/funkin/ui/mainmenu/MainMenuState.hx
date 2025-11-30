package funkin.ui.mainmenu;

import flixel.addons.transition.FlxTransitionableState;
#if FEATURE_DEBUG_MENU
import funkin.ui.debug.DebugMenuSubState;
#end
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.math.FlxPoint;
import flixel.util.typeLimit.NextState;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import funkin.graphics.FunkinCamera;
import funkin.audio.FunkinSound;
import funkin.util.SwipeUtil;
import funkin.util.InputUtil;
import flixel.tweens.FlxTween;
import funkin.ui.MusicBeatState;
import funkin.ui.UIStateMachine;
import funkin.ui.UIStateMachine.UIState;
import flixel.util.FlxTimer;
import funkin.ui.AtlasMenuList.AtlasMenuItem;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.MenuList.MenuTypedList;
import funkin.ui.MenuList.MenuListItem;
import funkin.ui.title.TitleState;
import funkin.ui.story.StoryMenuState;
import funkin.ui.Prompt;
import funkin.util.WindowUtil;
import funkin.mobile.ui.FunkinButton;
import funkin.util.MathUtil;
import funkin.util.TouchUtil;
import funkin.api.newgrounds.Referral;
import funkin.ui.mainmenu.UpgradeSparkle;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
#if FEATURE_DISCORD_RPC
import funkin.api.discord.DiscordClient;
#end
#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.NewgroundsClient;
#end
#if mobile
import funkin.mobile.input.ControlsHandler;
import funkin.mobile.util.InAppPurchasesUtil;
#end

@:nullSafety
class MainMenuState extends MusicBeatState
{
  var menuItems:Null<MenuTypedList<AtlasMenuItem>>;

  var bg:Null<FlxSprite>;
  var magenta:FlxSprite;
  var camFollow:FlxObject;

  #if mobile
  var gyroPan:Null<FlxPoint>;
  #end

  var overrideMusic:Bool = false;
  var uiStateMachine:UIStateMachine = new UIStateMachine();
  var canInteract(get, never):Bool;

  function get_canInteract():Bool
  {
    return uiStateMachine.canInteract();
  }

  static var rememberedSelectedIndex:Int = 0;

  // this should never be false on non-mobile targets.
  var hasUpgraded:Bool = false;
  var upgradeSparkles:FlxTypedSpriteGroup<UpgradeSparkle>;

  public function new(_overrideMusic:Bool = false)
  {
    super();
    overrideMusic = _overrideMusic;

    // Start in Entering state during screen fade in
    uiStateMachine.transition(Entering);

    upgradeSparkles = new FlxTypedSpriteGroup<UpgradeSparkle>();
    magenta = new FlxSprite(Paths.image('menuBGMagenta'));
    camFollow = new FlxObject(0, 0, 1, 1);

    // TODO: enabling and disabling keys is a lil quirky,
    // we should move towards unifying the UI and it's inputs into this UIStateMachine managed system
    FlxG.keys.enabled = true;
  }

  override function create():Void
  {
    #if FEATURE_DISCORD_RPC
    DiscordClient.instance.setPresence({state: "In the Menus", details: null});
    #end

    FlxG.cameras.reset(new FunkinCamera('mainMenu'));

    transIn = FlxTransitionableState.defaultTransIn;
    transOut = FlxTransitionableState.defaultTransOut;

    #if FEATURE_MOBILE_IAP
    trace("hasInitialized: " + InAppPurchasesUtil.hasInitialized);
    if (InAppPurchasesUtil.hasInitialized) Preferences.noAds = InAppPurchasesUtil.isPurchased(InAppPurchasesUtil.UPGRADE_PRODUCT_ID);
    // If the user is faster than their shit wifi, it gets the saved noAds instead.
    hasUpgraded = Preferences.noAds;
    #else
    // just to make sure its never accidentally turned off
    hasUpgraded = true;
    #end

    if (!overrideMusic) playMenuMusic();

    // We want the state to always be able to begin with being able to accept inputs and show the anims of the menu items.
    persistentUpdate = true;
    persistentDraw = true;

    bg = new FlxSprite(Paths.image('menuBG'));
    bg.scrollFactor.x = #if !mobile 0 #else 0.17 #end; // we want a lil x scroll on mobile
    bg.scrollFactor.y = 0.17;
    bg.setGraphicSize(Std.int(FlxG.width * 1.2));
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    add(camFollow);

    magenta.scrollFactor.copyFrom(bg.scrollFactor);
    magenta.setGraphicSize(Std.int(bg.width));
    magenta.updateHitbox();
    magenta.x = bg.x;
    magenta.y = bg.y;
    magenta.visible = false;

    if (Preferences.flashingLights) add(magenta);

    menuItems = new MenuTypedList<AtlasMenuItem>();
    add(menuItems);

    menuItems.onChange.add(onMenuItemChange);
    menuItems.onAcceptPress.add(_ -> {
      FlxFlicker.flicker(magenta, 1.1, 0.15, false, true);
      uiStateMachine.transition(Interacting);
    });

    menuItems.enabled = true;

    createMenuItem('storymode', 'mainmenu/storymode', () -> {
      FlxG.signals.preStateSwitch.addOnce(() -> {
        funkin.FunkinMemory.clearFreeplay();
        funkin.FunkinMemory.purgeCache();
      });
      startExitState(() -> new StoryMenuState());
    });

    createMenuItem('freeplay', 'mainmenu/freeplay', function() {
      persistentDraw = true;
      persistentUpdate = false;
      rememberedSelectedIndex = menuItems?.selectedIndex ?? 0;
      // Freeplay has its own custom transition
      FlxTransitionableState.skipNextTransIn = true;
      FlxTransitionableState.skipNextTransOut = true;

      // Since CUTOUT_WIDTH is static it might retain some old inccrect values so we update it before loading freeplay
      FreeplayState.CUTOUT_WIDTH = funkin.ui.FullScreenScaleMode.gameCutoutSize.x / 1.5;

      #if FEATURE_DEBUG_FUNCTIONS
      // Debug function: Hold SHIFT when selecting Freeplay to swap character without the char select menu
      var targetCharacter:Null<String> = FlxG.keys.pressed.SHIFT ? (FreeplayState.rememberedCharacterId == "pico" ? "bf" : "pico") : FreeplayState.rememberedCharacterId;
      #else
      var targetCharacter:Null<String> = FreeplayState.rememberedCharacterId;
      #end

      if (!hasUpgraded)
      {
        for (i in 0...upgradeSparkles.length)
        {
          upgradeSparkles.members[i].cancelSparkle();
        }
      }

      openSubState(new FreeplayState(
        {
          character: targetCharacter
        }));
    });

    if (hasUpgraded)
    {
      #if FEATURE_OPEN_URL
      // In order to prevent popup blockers from triggering,
      // we need to open the link as an immediate result of a keypress event,
      // so we can't wait for the flicker animation to complete.
      var hasPopupBlocker:Bool = #if web true #else false #end;
      createMenuItem('merch', 'mainmenu/merch', selectMerch, hasPopupBlocker);
      #end
    }
    else
    {
      add(upgradeSparkles);

      createMenuItem('upgrade', 'mainmenu/upgrade', function() {
        #if FEATURE_MOBILE_IAP
        InAppPurchasesUtil.purchase(InAppPurchasesUtil.UPGRADE_PRODUCT_ID, FlxG.resetState);
        uiStateMachine.transition(Idle);
        #end
      });
    }

    if (#if mobile ControlsHandler.usingExternalInputDevice #else true #end)
    {
      createMenuItem('options', 'mainmenu/options', function() {
        startExitState(() -> new funkin.ui.options.OptionsState());
      });
    }

    createMenuItem('credits', 'mainmenu/credits', function() {
      startExitState(() -> new funkin.ui.credits.CreditsState());
    });

    // Reset position of menu items.
    final spacing:Float = 160;
    final top:Float = (FlxG.height - (spacing * (menuItems.length - 1))) / 2;

    for (index => menuItem in menuItems)
    {
      menuItem.x = FlxG.width / 2;
      menuItem.y = top + spacing * index;
      menuItem.scrollFactor.x = #if !mobile 0.0 #else 0.4 #end; // we want a lil scroll on mobile, for the cute gyro effect
      // This one affects how much the menu items move when you scroll between them.
      menuItem.scrollFactor.y = 0.4;

      if (index == 1) camFollow.setPosition(menuItem.getGraphicMidpoint().x, menuItem.getGraphicMidpoint().y);
    }

    menuItems.selectItem(rememberedSelectedIndex);

    if (!hasUpgraded)
    {
      // the upgrade item
      var targetItem = menuItems.members[2];
      for (_ in 0...8)
      {
        var sparkle:UpgradeSparkle = new UpgradeSparkle(targetItem.x - (targetItem.width / 2), targetItem.y - (targetItem.height / 2), targetItem.width,
          targetItem.height, FlxG.random.bool(80));
        upgradeSparkles.add(sparkle);

        sparkle.scrollFactor.x = 0.0;
        sparkle.scrollFactor.y = 0.4;
      }

      subStateClosed.add(_ -> {
        for (i in 0...upgradeSparkles.length)
        {
          upgradeSparkles.members[i].restartSparkle();
        }
      });
    }

    resetCamStuff();

    // reset camera when debug menu is closed
    subStateClosed.add(_ -> resetCamStuff(false));

    subStateOpened.add((sub:FlxSubState) -> {
      if (Std.isOfType(sub, FreeplayState))
      {
        FlxTimer.wait(0.5, () -> {
          magenta.visible = false;
        });
      }
    });

    // FlxG.camera.setScrollBounds(bg.x, bg.x + bg.width, bg.y, bg.y + bg.height * 1.2);

    #if mobile
    gyroPan = new FlxPoint();

    camFollow.y = bg.getGraphicMidpoint().y;

    // TODO: This is absolutely disgusting but what the hell sure, fix it later -Zack
    addBackButton(FlxG.width - 230, FlxG.height - 200, FlxColor.WHITE, goBack, 1.0);

    if (!ControlsHandler.usingExternalInputDevice)
    {
      addOptionsButton(35, FlxG.height - 210, goOptions);
    }

    backButton?.onConfirmStart.add(() -> {
      uiStateMachine.transition(Interacting);
      trace('BACK: Interact Start');
    });

    optionsButton?.onConfirmStart.add(() -> {
      uiStateMachine.transition(Interacting);
      trace('OPTIONS: Interact Start');
    });
    #end

    super.create();

    // This has to come AFTER!
    initLeftWatermarkText();
  }

  function initLeftWatermarkText():Void
  {
    if (leftWatermarkText == null) return;

    leftWatermarkText.text = Constants.VERSION;

    #if FEATURE_NEWGROUNDS
    if (NewgroundsClient.instance.isLoggedIn())
    {
      leftWatermarkText.text += ' | Newgrounds: Logged in as ${NewgroundsClient.instance.user?.name}';
    }
    #end
  }

  function playMenuMusic():Void
  {
    FunkinSound.playMusic('freakyMenu',
      {
        overrideExisting: true,
        restartTrack: false,
        // Continue playing this music between states, until a different music track gets played.
        persist: true
      });
  }

  function resetCamStuff(snap:Bool = true):Void
  {
    FlxG.camera.follow(camFollow, null, 0.06);

    if (snap) FlxG.camera.snapToTarget();
  }

  function createMenuItem(name:String, atlas:String, callback:Void->Void, fireInstantly:Bool = false):Void
  {
    if (menuItems == null) return;

    var item:AtlasMenuItem = new AtlasMenuItem(name, Paths.getSparrowAtlas(atlas), callback);
    item.fireInstantly = fireInstantly;
    item.ID = menuItems.length;
    item.scrollFactor.set();

    // Set the offset of the item so the sprite is centered on the origin.
    item.centered = true;
    item.changeAnim('idle');
    menuItems.addItem(name, item);
  }

  var buttonGrp:Array<FlxSprite> = [];

  function createMenuButtion(name:String, atlas:String, callback:Void->Void):Void
  {
    var item:FunkinButton = new FunkinButton(Math.round(FlxG.width * 0.8), Math.round(FlxG.height * 0.7));
    item.makeGraphic(250, 250, FlxColor.BLUE);
    item.onDown.add(callback);
    buttonGrp.push(item);
  }

  override function closeSubState():Void
  {
    magenta.visible = false;

    // when we are in Transition (fade in on new FlxState) we don't really care about substate closing
    // this fixes issue when Entering w/ fade -> interacting -> fade ends, so it transitions to Idle on our substate end here
    if (!(subState is flixel.addons.transition.Transition))
    {
      uiStateMachine.transition(Idle);

      #if FEATURE_TOUCH_CONTROLS
      // we want to reset our backButton + optionsButton if we are returning to the main menu from a substate like freeplay
      // however, we dont want to trigger these resets if we are entering the state

      backButton?.animation.play('idle');
      backButton?.resetCallbacks();

      optionsButton?.animation.play('idle');
      optionsButton?.resetCallbacks();
      #end
    }

    super.closeSubState();
  }

  function onMenuItemChange(selected:MenuListItem)
  {
    if (#if mobile ControlsHandler.usingExternalInputDevice #else true #end) camFollow.setPosition(selected.getGraphicMidpoint().x,
      selected.getGraphicMidpoint().y);
  }

  #if FEATURE_OPEN_URL
  function selectDonate()
  {
    WindowUtil.openURL(Constants.URL_ITCH);
  }

  function selectMerch()
  {
    Referral.doMerchReferral();
    uiStateMachine.transition(Idle);
  }
  #end

  public function openPrompt(prompt:Prompt, onClose:Void->Void):Void
  {
    uiStateMachine.transition(Interacting);
    persistentUpdate = false;

    prompt.closeCallback = function() {
      // in our closeSubstate override, we set the uiStateMachine, so no need to set here
      if (onClose != null) onClose();
    }

    openSubState(prompt);
  }

  function startExitState(state:NextState):Void
  {
    if (menuItems == null) return;

    uiStateMachine.transition(Exiting); // Start fade out
    rememberedSelectedIndex = menuItems.selectedIndex;

    // the fadeout duration for the initial alpha tweens, not the screen wipe fadeout!
    var fadeOutDuration:Float = 0.4;
    menuItems.forEach(item -> {
      if (rememberedSelectedIndex != item.ID) FlxTween.tween(item, {alpha: 0}, fadeOutDuration, {ease: FlxEase.quadOut});
      else
        item.visible = false;
    });

    #if mobile
    if (optionsButton != null) FlxTween.tween(optionsButton, {alpha: 0}, fadeOutDuration, {ease: FlxEase.quadOut});
    if (backButton != null) FlxTween.tween(backButton, {alpha: 0}, fadeOutDuration, {ease: FlxEase.quadOut});
    #end

    FlxTimer.wait(fadeOutDuration, () -> {
      trace('Exiting MainMenuState...');
      FlxG.switchState(state);
    });
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    Conductor.instance.update();

    #if mobile
    if (gyroPan != null && bg != null && !ControlsHandler.usingExternalInputDevice)
    {
      gyroPan.add(FlxG.gyroscope.pitch * -1.25, FlxG.gyroscope.roll * -1.25);

      // our pseudo damping
      gyroPan.x = MathUtil.smoothLerpPrecision(gyroPan.x, 0, elapsed, 2.5);
      gyroPan.y = MathUtil.smoothLerpPrecision(gyroPan.y, 0, elapsed, 2.5);

      // how far away from bg mid do we want to pan via gyroPan
      camFollow.x = bg.getGraphicMidpoint().x - gyroPan.x;
      camFollow.y = bg.getGraphicMidpoint().y - gyroPan.y;
    }
    #end

    if ((FlxG.sound.music?.volume ?? 1.0) < 0.8)
    {
      FlxG.sound.music.volume += 0.5 * elapsed;
    }
    handleInputs();

    if (menuItems != null) menuItems.busy = !canInteract;

    #if mobile
    if (optionsButton != null)
    {
      optionsButton.active = canInteract || optionsButton.confirming;
      optionsButton.enabled = optionsButton.active;
    }
    if (backButton != null)
    {
      backButton.active = canInteract || backButton.confirming;
      backButton.enabled = backButton.active;
    }
    #end
  }

  function handleInputs():Void
  {
    if (!canInteract) return;

    #if FEATURE_DEBUG_MENU
    // Open the debug menu, defaults to ` / ~
    // This includes stuff like the Chart Editor, so it should be present on all builds.
    if (controls.DEBUG_MENU)
    {
      persistentUpdate = false;
      uiStateMachine.transition(Interacting);

      // Cancel the currently flickering menu item because it's about to call a state switch
      if (menuItems != null && menuItems.busy) menuItems.cancelAccept();

      FlxG.state.openSubState(new DebugMenuSubState());
    }
    #end

    #if FEATURE_DEBUG_FUNCTIONS
    // Ctrl+Alt+Shift+P = Character Unlock screen
    // Ctrl+Alt+Shift+W = Meet requirements for Pico Unlock
    // Ctrl+Alt+Shift+M = Revoke requirements for Pico Unlock
    // Ctrl+Alt+Shift+R = Score/Rank conflict test
    // Ctrl+Alt+Shift+N = Mark all characters as not seen
    // Ctrl+Alt+Shift+E = Dump save data
    // Ctrl+Alt+Shift+L = Force crash and create a log dump

    if (InputUtil.allPressedWithDebounce([CONTROL, ALT, SHIFT, P]))
    {
      FlxG.switchState(() -> new funkin.ui.charSelect.CharacterUnlockState('pico'));
    }

    if (InputUtil.allPressedWithDebounce([CONTROL, ALT, SHIFT, W]))
    {
      FunkinSound.playOnce(Paths.sound('confirmMenu'));
      // Give the user a score of 1 point on Weekend 1 story mode (Easy difficulty).
      // This makes the level count as cleared and displays the songs in Freeplay.
      funkin.save.Save.instance.setLevelScore('weekend1', 'easy',
        {
          score: 1,
          tallies:
            {
              sick: 0,
              good: 0,
              bad: 0,
              shit: 0,
              missed: 0,
              combo: 0,
              maxCombo: 0,
              totalNotesHit: 0,
              totalNotes: 0,
            }
        });
    }

    if (InputUtil.allPressedWithDebounce([CONTROL, ALT, SHIFT, M]))
    {
      FunkinSound.playOnce(Paths.sound('confirmMenu'));
      // Give the user a score of 0 points on Weekend 1 story mode (all difficulties).
      // This makes the level count as uncleared and no longer displays the songs in Freeplay.
      for (diff in ['easy', 'normal', 'hard'])
      {
        funkin.save.Save.instance.setLevelScore('weekend1', diff,
          {
            score: 0,
            tallies:
              {
                sick: 0,
                good: 0,
                bad: 0,
                shit: 0,
                missed: 0,
                combo: 0,
                maxCombo: 0,
                totalNotesHit: 0,
                totalNotes: 0,
              }
          });
      }
    }

    if (InputUtil.allPressedWithDebounce([CONTROL, ALT, SHIFT, R]))
    {
      // Give the user a hypothetical overridden score,
      // and see if we can maintain that golden P rank.
      funkin.save.Save.instance.setSongScore('tutorial', 'easy',
        {
          score: 1234567,
          tallies:
            {
              sick: 0,
              good: 0,
              bad: 0,
              shit: 1,
              missed: 0,
              combo: 0,
              maxCombo: 0,
              totalNotesHit: 1,
              totalNotes: 10,
            }
        });
    }

    if (InputUtil.allPressedWithDebounce([CONTROL, ALT, SHIFT, N]))
    {
      @:privateAccess
      {
        funkin.save.Save.instance.data.unlocks.charactersSeen = ["bf"];
        funkin.save.Save.instance.oldChar.value = false;
      }
    }

    if (InputUtil.allPressedWithDebounce([CONTROL, ALT, SHIFT, E]))
    {
      funkin.save.Save.instance.debug_dumpSaveJsonSave();
    }
    #end

    if (controls.BACK_P) goBack();
  }

  function goOptions():Void
  {
    trace("OPTIONS: Interact complete.");
    startExitState(() -> new funkin.ui.options.OptionsState());
  }

  function goBack():Void
  {
    trace("BACK: Interact complete.");
    uiStateMachine.transition(Exiting);
    rememberedSelectedIndex = menuItems?.selectedIndex ?? 0;
    FunkinSound.playOnce(Paths.sound('cancelMenu'));

    FlxG.switchState(() -> new TitleState());
  }
}
