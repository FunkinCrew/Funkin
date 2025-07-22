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
import flixel.tweens.FlxTween;
import funkin.ui.MusicBeatState;
import flixel.util.FlxTimer;
import funkin.ui.AtlasMenuList.AtlasMenuItem;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.MenuList.MenuTypedList;
import funkin.ui.MenuList.MenuListItem;
import funkin.ui.title.TitleState;
import funkin.ui.story.StoryMenuState;
import funkin.ui.Prompt;
import funkin.util.WindowUtil;
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
  var goingToOptions:Bool = false;
  var goingBack:Bool = false;
  var canInteract(get, set):Bool;
  var _canInteract:Bool = false;

  function get_canInteract():Bool
  {
    return _canInteract;
  }

  function set_canInteract(value:Bool):Bool
  {
    _canInteract = value;
    trace('canInteract set to: ' + value);
    return value;
  }

  static var rememberedSelectedIndex:Int = 0;

  // this should never be false on non-mobile targets.
  var hasUpgraded:Bool = false;
  var upgradeSparkles:FlxTypedSpriteGroup<UpgradeSparkle>;

  public function new(_overrideMusic:Bool = false)
  {
    super();
    overrideMusic = _overrideMusic;

    upgradeSparkles = new FlxTypedSpriteGroup<UpgradeSparkle>();
    magenta = new FlxSprite(Paths.image('menuBGMagenta'));
    camFollow = new FlxObject(0, 0, 1, 1);
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

    magenta.scrollFactor.x = bg.scrollFactor.x;
    magenta.scrollFactor.y = bg.scrollFactor.y;
    magenta.setGraphicSize(Std.int(bg.width));
    magenta.updateHitbox();
    magenta.x = bg.x;
    magenta.y = bg.y;
    magenta.visible = false;

    // TODO: Why doesn't this line compile I'm going fucking feral

    if (Preferences.flashingLights) add(magenta);

    menuItems = new MenuTypedList<AtlasMenuItem>();
    add(menuItems);
    menuItems.onChange.add(onMenuItemChange);
    menuItems.onAcceptPress.add(function(_) {
      // canInteract = false;
      FlxFlicker.flicker(magenta, 1.1, 0.15, false, true);
    });

    menuItems.enabled = true; // can move on intro
    createMenuItem('storymode', 'mainmenu/storymode', function() {
      FlxG.signals.preStateSwitch.addOnce(function() {
        funkin.FunkinMemory.clearFreeplay();
        funkin.FunkinMemory.purgeCache();
      });
      startExitState(() -> new StoryMenuState());
    });
    createMenuItem('freeplay', 'mainmenu/freeplay', function() {
      persistentDraw = true;
      persistentUpdate = false;
      if (menuItems != null) rememberedSelectedIndex = menuItems.selectedIndex;
      // Freeplay has its own custom transition
      FlxTransitionableState.skipNextTransIn = true;
      FlxTransitionableState.skipNextTransOut = true;

      // Since CUTOUT_WIDTH is static it might retain some old inccrect values so we update it before loading freeplay
      FreeplayState.CUTOUT_WIDTH = funkin.ui.FullScreenScaleMode.gameCutoutSize.x / 1.5;

      var rememberedFreeplayCharacter = FreeplayState.rememberedCharacterId;
      #if FEATURE_DEBUG_FUNCTIONS
      // Debug function: Hold SHIFT when selecting Freeplay to swap character without the char select menu
      var targetCharacter:Null<String> = (FlxG.keys.pressed.SHIFT) ? (FreeplayState.rememberedCharacterId == "pico" ? "bf" : "pico") : rememberedFreeplayCharacter;
      #else
      var targetCharacter:Null<String> = rememberedFreeplayCharacter;
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
      canInteract = true;
    });

    if (hasUpgraded)
    {
      #if FEATURE_OPEN_URL
      // In order to prevent popup blockers from triggering,
      // we need to open the link as an immediate result of a keypress event,
      // so we can't wait for the flicker animation to complete.
      var hasPopupBlocker = #if web true #else false #end;
      createMenuItem('merch', 'mainmenu/merch', selectMerch, hasPopupBlocker);
      #end
    }
    else
    {
      add(upgradeSparkles);

      createMenuItem('upgrade', 'mainmenu/upgrade', function() {
        #if FEATURE_MOBILE_IAP
        InAppPurchasesUtil.purchase(InAppPurchasesUtil.UPGRADE_PRODUCT_ID, FlxG.resetState);
        canInteract = true;
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
    var spacing = 160;
    var top = (FlxG.height - (spacing * (menuItems.length - 1))) / 2;
    for (i in 0...menuItems.length)
    {
      var menuItem = menuItems.members[i];
      menuItem.x = FlxG.width / 2;
      menuItem.y = top + spacing * i;
      menuItem.scrollFactor.x = #if !mobile 0.0 #else 0.4 #end; // we want a lil scroll on mobile, for the cute gyro effect
      // This one affects how much the menu items move when you scroll between them.
      menuItem.scrollFactor.y = 0.4;

      if (i == 1)
      {
        camFollow.setPosition(menuItem.getGraphicMidpoint().x, menuItem.getGraphicMidpoint().y);
      }
    }

    menuItems.selectItem(rememberedSelectedIndex);

    if (!hasUpgraded)
    {
      // the upgrade item
      var targetItem = menuItems.members[2];
      for (i in 0...8)
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

    // TODO: Why does this specific function break with null safety?
    @:nullSafety(Off)
    subStateOpened.add((sub:FlxSubState) -> {
      if (Type.getClass(sub) == FreeplayState)
      {
        new FlxTimer().start(0.5, _ -> {
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
      addOptionsButton(35, FlxG.height - 210, function() {
        if (!canInteract || menuItems != null && menuItems.busy) return;

        trace("OPTIONS: Interact complete.");
        startExitState(() -> new funkin.ui.options.OptionsState());
      });
    }

    if (backButton != null)
    {
      backButton.onConfirmStart.add(function():Void {
        if (backButton == null) return;
        goingBack = true;
        if (menuItems != null) menuItems.enabled = false;
        trace('BACK: Interact Start');
      });
    }

    if (optionsButton != null)
    {
      optionsButton.onConfirmStart.add(function():Void {
        if (optionsButton == null) return;
        goingToOptions = true;
        if (menuItems != null) menuItems.enabled = false;
        trace('OPTIONS: Interact Start');
      });
    }
    #end

    super.create();

    // This has to come AFTER!
    if (this.leftWatermarkText != null)
    {
      this.leftWatermarkText.text = Constants.VERSION;

      #if FEATURE_NEWGROUNDS
      if (NewgroundsClient.instance.isLoggedIn())
      {
        this.leftWatermarkText.text += ' | Newgrounds: Logged in as ${NewgroundsClient.instance.user?.name}';
      }
      #end
    }
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
    if (menuItems != null)
    {
      var item = new AtlasMenuItem(name, Paths.getSparrowAtlas(atlas), callback);
      item.fireInstantly = fireInstantly;
      item.ID = menuItems.length;

      item.scrollFactor.set();

      // Set the offset of the item so the sprite is centered on the origin.
      item.centered = true;
      item.changeAnim('idle');

      menuItems.addItem(name, item);
    }
  }

  var buttonGrp:Array<FlxSprite> = [];

  function createMenuButtion(name:String, atlas:String, callback:Void->Void):Void
  {
    var item = new funkin.mobile.ui.FunkinButton(Math.round(FlxG.width * 0.8), Math.round(FlxG.height * 0.7));
    item.makeGraphic(250, 250, FlxColor.BLUE);
    item.onDown.add(callback);
    buttonGrp.push(item);
  }

  override function closeSubState():Void
  {
    magenta.visible = false;
    #if FEATURE_TOUCH_CONTROLS
    if (backButton != null)
    {
      backButton.animation.play('idle');
      backButton.resetCallbacks();
    }
    if (optionsButton != null)
    {
      optionsButton.animation.play('idle');
      optionsButton.resetCallbacks();
    }
    #end
    super.closeSubState();
    canInteract = true;
  }

  override function finishTransIn():Void
  {
    super.finishTransIn();
    canInteract = true;
    if (menuItems != null)
    {
      menuItems.busy = false;
      menuItems.enabled = true;
    }
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
    canInteract = true;
  }
  #end

  public function openPrompt(prompt:Prompt, onClose:Void->Void):Void
  {
    if (menuItems != null) menuItems.enabled = false;
    persistentUpdate = false;

    prompt.closeCallback = function() {
      if (menuItems != null) menuItems.enabled = true;
      if (onClose != null) onClose();
    }

    openSubState(prompt);
  }

  function startExitState(state:NextState):Void
  {
    #if mobile
    // This just softlocks the menu items and prevents any further interaction.. needs testing with keyboard.
    if (!canInteract && !ControlsHandler.usingExternalInputDevice) return;
    #end

    if (menuItems != null)
    {
      menuItems.enabled = false; // disable for exit
      canInteract = false;
      rememberedSelectedIndex = menuItems.selectedIndex;

      var duration = 0.4;
      menuItems.forEach(function(item) {
        if (menuItems != null && menuItems.selectedIndex != item.ID)
        {
          FlxTween.tween(item, {alpha: 0}, duration, {ease: FlxEase.quadOut});
        }
        else
        {
          item.visible = false;
        }
      });

      #if mobile
      if (optionsButton != null) FlxTween.tween(optionsButton, {alpha: 0}, duration, {ease: FlxEase.quadOut});
      if (backButton != null) FlxTween.tween(backButton, {alpha: 0}, duration, {ease: FlxEase.quadOut});
      #end

      new FlxTimer().start(duration, function(_) {
        trace('Exiting MainMenuState...');
        FlxG.switchState(state);
        canInteract = true;
      });
    }
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

    if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
    {
      FlxG.sound.music.volume += 0.5 * elapsed;
    }
    handleInputs();
    if (menuItems != null)
    {
      #if mobile
      // if (optionsButton != null) optionsButton.active = canInteract && (!menuItems.busy && !goingBack);
      // if (backButton != null) backButton.active = canInteract && (!menuItems.busy && !goingToOptions);
      #end
      if (_exiting) menuItems.enabled = false;
    }
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

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.P)
    {
      FlxG.switchState(() -> new funkin.ui.charSelect.CharacterUnlockState('pico'));
    }

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.W)
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

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.M)
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

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.R)
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

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.N)
    {
      @:privateAccess
      {
        funkin.save.Save.instance.data.unlocks.charactersSeen = ["bf"];
        funkin.save.Save.instance.data.unlocks.oldChar = false;
      }
    }

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT && FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.E)
    {
      funkin.save.Save.instance.debug_dumpSave();
    }
    #end

    if (controls.BACK) goBack();
  }

  public function goBack():Void
  {
    if (menuItems == null) return;
    if (canInteract && !menuItems.busy)
    {
      trace("BACK: Interact complete.");
      canInteract = false;
      menuItems.busy = true;
      rememberedSelectedIndex = menuItems.selectedIndex;
      FlxG.switchState(() -> new TitleState());
      FunkinSound.playOnce(Paths.sound('cancelMenu'));
    }
  }
}
