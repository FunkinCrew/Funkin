package funkin.ui.modmenu;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDirection;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.graphics.framebuffer.DropShadowLayer;
import funkin.input.Cursor;
import funkin.modding.PolymodHandler;
import funkin.ui.FullScreenScaleMode;
import funkin.ui.MusicBeatState;
import funkin.ui.UIStateMachine;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.transition.Transition;
import funkin.ui.transition.preload.hotreload.HotReloadState;
import funkin.util.FileUtil;
import funkin.util.PropertyAnimator;
import haxe.io.Path;
#if android
import funkin.external.android.DataFolderUtil;
#elseif ios
import lime.system.System;
#end
#if FEATURE_ONE_CLICK_INSTALL
import funkin.modding.install.ModInstaller.OneClickRequest;
#end
#if FEATURE_TOUCH_CONTROLS
import funkin.mobile.input.ControlsHandler;
import funkin.util.MathUtil;
import funkin.util.TouchUtil;
#end

/**
 * The user interface for the mod menu.
 */
class ModMenuState extends MusicBeatState
{
  /**
   * The currently active ModMenuState.
   * There should be only one ModMenuState in existence at a time, we can use a singleton.
   */
  public static var instance:Null<ModMenuState> = null;

  /**
   * The mod ID for base game.
   */
  public static inline final BASE_GAME_MOD_ID:String = '__base_game__';

  /**
   * The base path for the base game.
   */
  public static inline final BASE_GAME_MOD_ICON_PATH:String = 'ui/mods/base-icon';

  /**
   * The full mod menu scene with bf gf and such.
   */
  public var scene:ModMenuScene;

  /**
   * BF in the mod menu.
   */
  public var bf(get, never):ModMenuCharacter;

  inline function get_bf():ModMenuCharacter return scene.bf;

  /**
   * GF in the mod menu.
   */
  public var gf(get, never):ModMenuCharacter;

  inline function get_gf():ModMenuCharacter return scene.gf;

  /**
   * The ambience in the mod menu.
   */
  public var ambience:ModMenuAmbience;

  /**
   * The drop shadow layer instance for UI elements.
   */
  public var dropShadowUI:DropShadowLayer;

  /**
   * The drop shadow layer instance for characters.
   * Slightly weaker than the UI one.
   */
  public var dropShadowCharacters:DropShadowLayer;

  /**
   * The camera that houses the characters in the mod menu.
   * Required for a weaker drop shadow effect on the characters specifically.
   */
  public var camCharacters:FunkinCamera;

  /**
   * The camera that houses some UI elements in the mod menu.
   * Yes, really. This is needed for layering.
   */
  public var camHUD:FunkinCamera;

  /**
   * The camera that houses literally everything else.
   */
  public var camOther:FunkinCamera;

  var leftRectangle:FunkinSprite = new FunkinSprite();
  var rightRectangle:FunkinSprite = new FunkinSprite();
  var buttonBackToMenu:ModMenuButton = new ModMenuButton();
  var buttonOpenFolder:ModMenuButton = new ModMenuButton();
  var buttonDone:ModMenuButton = new ModMenuButton();

  /**
   * For some reason back to menu button's hitbox is bigger than the graphics.
   */
  var hitboxOpenFolder:FunkinSprite;

  /**
   * Handles the overall state of the menu, and so what can be interacted with.
   */
  var uiState:UIStateMachine;

  /**
   * Delay between navigation steps.
   */
  static final NAV_DELAY:Float = 0.6;

  /**
   * Initial value of the multiplier for accelerating the delay timer.
   */
  static final NAV_ACCELERATION_INITIAL:Float = 2.5;

  /**
   * Limit of the multiplier for accelerating the delay timer.
   */
  static final NAV_ACCELERATION_LIMIT:Float = 7.5;

  /**
   * Array of directions used for navigation handling.
   */
  static final NAV_DIRECTIONS:Array<FlxDirection> = [FlxDirection.UP, FlxDirection.DOWN, FlxDirection.LEFT, FlxDirection.RIGHT];

  /**
   * Currently used direction when holding a key.
   */
  var heldDirection(default, set):Null<FlxDirection> = null;

  function set_heldDirection(value:Null<FlxDirection>):Null<FlxDirection>
  {
    heldDirection = value;

    navDelayTimer = 0;
    navSpeed = NAV_ACCELERATION_INITIAL;

    return value;
  }

  /**
   * Timer of the delay between steps.
   */
  var navDelayTimer:Float = 0;

  /**
   * Current speed of the delay timer.
   */
  var navSpeed:Float = NAV_ACCELERATION_INITIAL;

  /**
   * Whether the last thing selected was in the left column (the disabled list and the open folder button)
   * or the right column (the enabled list and the done button). The back button uses this to know where to return to.
   */
  var lastColumnLeft:Bool = true;

  var disabledModItems:ModMenuItemList = new ModMenuItemList();
  var enabledModItems:ModMenuItemList = new ModMenuItemList();

  /**
   * The dependency rules, disk sync and apply logic for both the enabled and disabled mod lists.
   */
  var lists:ModListManager;

  /**
   * Drag and drop, and one-click installs handler.
   */
  public var installer:ModMenuInstaller;

  var selection:ModMenuSelection = DisabledModList;
  var openFolderAnimator:PropertyAnimator;
  var doneButtonAnimator:PropertyAnimator;
  var lastSelectDir:Null<FlxDirection> = null;
  var menuBG:FunkinSprite;

  public function new()
  {
    super();

    ambience = new ModMenuAmbience({
      baseAmbiencePath: 'ui/mods/mod-menu-ambience/mod-menu-ambience',
      randomSoundPath: 'ui/mods/sounds',
      randomSoundWait: 7.0,
      randomTimeRange: FlxPoint.get(6.0, 10.0),
      fadeInTime: 4.0
    });

    ModMenuScene.cacheAssets();

    camCharacters = new FunkinCamera('modMenuCharacters');
    camHUD = new FunkinCamera('modMenuHUD');
    camOther = new FunkinCamera('modMenuOther');
    lists = new ModListManager(disabledModItems, enabledModItems, (newSelection) ->
    {
      selection = newSelection;
    });

    // uiState
    uiState = new UIStateMachine();
    uiState.onStateChanged(onUIStateChange);
  }

  override public function create():Void
  {
    if (instance != null)
    {
      FlxG.log.warn('WARNING: ModMenuState instance already exists. This should not happen.');
    }

    instance = this;

    camCharacters.bgColor.alpha = 0;
    camHUD.bgColor.alpha = 0;
    camOther.bgColor.alpha = 0;

    FlxG.cameras.reset(camOther);
    FlxG.cameras.add(camCharacters, false);
    FlxG.cameras.add(camHUD, false);

    transIn = FlxTransitionableState.defaultTransIn;
    transOut = FlxTransitionableState.defaultTransOut;

    // Needs to come AFTER the cameras are added so the transition is layered properly
    super.create();

    enabledModItems.pinnedTopModId = BASE_GAME_MOD_ID;

    menuBG = new FunkinSprite().loadTexture('ui/mods/bg');
    menuBG.scale.set(0.66, 0.67);
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    menuBG.zIndex = 0;
    add(menuBG);

    dropShadowUI = new DropShadowLayer(cast FlxG.camera, 0xA91E1E1E, 2, 2);
    dropShadowUI.zIndex = 5;
    add(dropShadowUI);

    dropShadowCharacters = new DropShadowLayer(camCharacters, 0xA91E1E1E, 2, 1);
    dropShadowCharacters.zIndex = 0;
    dropShadowCharacters.camera = camCharacters;
    add(dropShadowCharacters);

    var topText:FunkinSprite = new FunkinSprite().loadTexture('ui/mods/top-text');
    topText.scale.set(0.66, 0.67);
    topText.updateHitbox();
    topText.screenCenter(X);
    topText.y = FlxG.height * 0.035;
    topText.zIndex = 10;
    add(topText);

    leftRectangle.x = FlxG.width * 0.047 + FullScreenScaleMode.gameCutoutSize.x / 2.5;
    leftRectangle.y = FlxG.height * 0.19;
    leftRectangle.scale.set(0.64, 0.67);
    leftRectangle.loadTexture('ui/mods/box');
    leftRectangle.updateHitbox();
    leftRectangle.zIndex = 10;
    add(leftRectangle);

    var distanceBetweenRectangles:Int = 35;
    rightRectangle.x = leftRectangle.x + leftRectangle.width + distanceBetweenRectangles;
    rightRectangle.y = leftRectangle.y;
    rightRectangle.scale.set(0.64, 0.67);
    rightRectangle.loadTexture('ui/mods/box');
    rightRectangle.updateHitbox();
    rightRectangle.zIndex = 10;
    add(rightRectangle);

    var dragTextWidth:Float = leftRectangle.width + rightRectangle.width + distanceBetweenRectangles;
    var dragText:FlxText = new FlxText(leftRectangle.x, FlxG.height * 0.13, dragTextWidth, 'Drag packs onto this window to add new stuff');
    #if FEATURE_TOUCH_CONTROLS
    dragText.text = 'Tap a mod to move it, hold and drag to reorder';
    #end
    dragText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinLingLong', 'otf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER);
    dragText.scale.set(1, 0.8);
    dragText.letterSpacing = 5;
    dragText.zIndex = 10;
    add(dragText);

    refreshModList(false);

    enabledModItems.zIndex = 15;
    enabledModItems.addElements();
    add(enabledModItems);

    disabledModItems.zIndex = 15;
    disabledModItems.addElements();
    add(disabledModItems);

    lists.attachTransitionLayer(20);

    enabledModItems.titleText.x = rightRectangle.x + (rightRectangle.width / 2) - (enabledModItems.titleText.width / 2);
    enabledModItems.titleText.y = rightRectangle.y + 14;
    disabledModItems.titleText.x = leftRectangle.x + (leftRectangle.width / 2) - (disabledModItems.titleText.width / 2);
    disabledModItems.titleText.y = leftRectangle.y + 14;

    enabledModItems.clipRect = FlxRect.get(rightRectangle.x, rightRectangle.y + 60, rightRectangle.width, rightRectangle.height - 75);
    disabledModItems.clipRect = FlxRect.get(leftRectangle.x, leftRectangle.y + 60, leftRectangle.width, leftRectangle.height - 75);

    refreshModList(false);

    buttonBackToMenu.loadTextureAtlas('ui/mods/back-arrow');
    buttonBackToMenu.scale.set(0.7, 0.7);
    buttonBackToMenu.updateHitbox();

    buttonBackToMenu.x = disabledModItems.x - 50 - FullScreenScaleMode.gameCutoutSize.x / 10;
    buttonBackToMenu.y = topText.y + (topText.height / 2) - (buttonBackToMenu.height / 2) + 3;

    buttonBackToMenu.anim.addByFrameLabel('idle', 'default', 24);
    buttonBackToMenu.anim.addByFrameLabel('press', 'press hold', 24, false);
    buttonBackToMenu.anim.addByFrameLabel('hover', 'highlighted', 24);
    buttonBackToMenu.anim.addByFrameLabel('confirm', 'confirm', 24, false);

    playBackButtonAnimation('idle', true);
    buttonBackToMenu.animation.onFinish.add((name:String) ->
    {
      switch (backPressStage)
      {
        case 1:
          trace(' MOD MENU '.bold().bg_orange() + ' Back button pressed, confirming exit...');
          backPressStage = 2;
          playBackButtonAnimation('confirm', true);
        case 2:
          trace(' MOD MENU '.bold().bg_orange() + ' Back button confirm finished, returning to main menu...');
          backPressStage = 3;
        default:
      }
    });

    buttonBackToMenu.zIndex = 10;
    add(buttonBackToMenu);

    scene = new ModMenuScene(instance, camCharacters, dropShadowCharacters, lists.getEnabledModIdsWithBaseGame);
    scene.build(rightRectangle.x);

    buttonDone.x = scene.carBattery.x - 100;
    buttonDone.y = FlxG.height * 0.89;
    buttonDone.scale.set(0.65, 0.65);
    buttonDone.loadTexture('ui/mods/done');
    buttonDone.updateHitbox();
    buttonDone.zIndex = 1000;
    buttonDone.camera = camHUD;
    buttonDone.graphicName = 'done';
    add(buttonDone);

    var openFolderGraphic = #if sys 'open-folder' #else 'import-folder' #end;
    buttonOpenFolder.x = leftRectangle.x + 180;
    buttonOpenFolder.y = FlxG.height * 0.89;
    buttonOpenFolder.scale.set(0.65, 0.65);
    buttonOpenFolder.loadTexture('ui/mods/$openFolderGraphic');
    buttonOpenFolder.updateHitbox();
    buttonOpenFolder.zIndex = 1000;
    buttonOpenFolder.camera = camHUD;
    buttonOpenFolder.graphicName = openFolderGraphic;
    add(buttonOpenFolder);

    hitboxOpenFolder = new FunkinSprite(
      buttonOpenFolder.x,
      buttonOpenFolder.y
    ).makeSolidColor(Std.int(buttonOpenFolder.width), Std.int(buttonOpenFolder.height), FlxColor.GREEN);
    hitboxOpenFolder.updateHitbox();
    hitboxOpenFolder.camera = camHUD;

    openFolderAnimator = buttonOpenFolder.createPressAnimator(0.65, 0.72);
    doneButtonAnimator = buttonDone.createPressAnimator(0.65, 0.72);

    installer = new ModMenuInstaller(highlightNewMod, (enabled) ->
    {
      uiState.transition((enabled) ? Idle : Disabled);
    });
    installer.build(camHUD);

    enabledModItems.repositionItems();
    disabledModItems.repositionItems();

    var usingTouch:Bool = false;

    #if FEATURE_TOUCH_CONTROLS
    if (!ControlsHandler.usingExternalInputDevice)
    {
      usingTouch = true;
    }
    #end

    if (disabledModItems.modItems.length > 0)
    {
      if (!usingTouch)
      {
        disabledModItems.selectFirstItem();
      }
      selection = DisabledModList;
      enabledModItems.deselectAll();
    }
    else
    {
      if (!usingTouch)
      {
        enabledModItems.selectFirstItem();
      }
      selection = EnabledModList;
      disabledModItems.deselectAll();
    }

    FlxG.stage.window.onDropFile.add(onDropFile);
    FlxG.stage.window.onDropBegin.add(startFileDropHover);
    FlxG.stage.window.onDropComplete.add(hideFileDropHover);

    FlxG.autoPause = false;

    // Adding the dropshadow blacklist here since everything is initialized by this point
    dropShadowUI.blacklistSprite(menuBG);
    scene.blacklistFromShadow(dropShadowUI);

    scene.changeCharacters();

    ambience.initialize();

    disabledModItems.snapScroll();
    enabledModItems.snapScroll();

    this.refresh();
  }

  var backPressStage:Int = 0;

  function playBackButtonAnimation(name:String, force:Bool = false):Void
  {
    if (buttonBackToMenu == null || buttonBackToMenu.animation == null) return;
    if (!force && buttonBackToMenu.getCurrentAnimation() == name) return;

    buttonBackToMenu.animation.play(name, force);
  }

  function pressBackButton():Void
  {
    if (uiState.is(Exiting) || !uiState.transition(Exiting)) return;
    backPressStage = 1;
    playBackButtonAnimation('press', true);
  }

  function startFileDropHover():Void
  {
    if (!canDropFiles()) return;

    installer.showDropOverlay();
  }

  function hideFileDropHover(x:Float, y:Float):Void
  {
    if (!canDropFiles()) return;

    installer.hideDropOverlay();
  }

  function rescanFolder():Void
  {
    if (lists.hasFolderChanged())
    {
      trace(' MOD MENU '.bold().bg_orange() + ' Mod folder changed, refreshing list.');
      refreshModList();
    }
  }

  // OVERRIDES //

  override public function destroy():Void
  {
    super.destroy();

    // Stops in-flight downloads, and drops the queue.
    installer?.destroy();

    FlxG.autoPause = Preferences.autoPause;
    FlxG.stage.window.onDropFile.remove(onDropFile);
    FlxG.stage.window.onDropBegin.remove(startFileDropHover);
    FlxG.stage.window.onDropComplete.remove(hideFileDropHover);

    ambience.destroy();

    instance = null;
  }

  /**
   * Callback ran when a file is dropped onto the window.
   * @param file The file that was dropped.
   * @param state The state that was dropped.
   * @param x The x position of the dropped file.
   * @param y The y position of the dropped file.
   */
  public function onDropFile(file:lime.utils.DroppedFile, state:String, x:Float, y:Float):Void
  {
    if (!canDropFiles()) return;

    installer.installDropped(file);
  }

  /**
   * Rebuilds the list after something landed in the mods folder, then flashes whatever showed up.
   * Shared by drag and drop and by one-click installs.
   */
  function highlightNewMod():Void
  {
    var newItems = refreshModList();
    for (item in newItems)
    {
      if (item.mod != null)
      {
        item.flashBackground();
        break;
      }
    }

    handleSelection();
  }

  #if FEATURE_ONE_CLICK_INSTALL
  /**
   * Begins one click install of a mod from GameBanana. This will fetch the metadata, download the icon, and start the download.
   * @param request The parsed link.
   */
  public function beginOneClickInstall(request:OneClickRequest):Void
  {
    if (installer == null) return;

    installer.beginOneClick(request);
  }

  /**
   * Tells the card how many more mods are lined up behind the one it's showing.
   * @param count The number of mods.
   */
  public function setInstallQueueCount(count:Int):Void
  {
    if (installer == null) return;

    installer.setQueueCount(count);
  }

  /**
   * Handles input while the install overlay is up, and swallows everything else.
   */
  function handleInstallPopupInput():Void
  {
    switch (installer.popup.state)
    {
      case Downloading:
        if (controls.BACK_P) installer.cancelOneClick();

      case Result:
        // The card clears itself, this is only here for a player who doesn't want to wait on it.
        if (FlxG.keys.justPressed.ANY || controls.ACCEPT_P || controls.BACK_P #if FEATURE_TOUCH_CONTROLS || TouchUtil.justPressed #end)
        {
          installer.popup.hide();
        }

      default:
        // Busy and Hidden take no input.
    }
  }
  #end

  var secondCounter:Float = 0;
  var backTimer:Float = 0;

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (backPressStage == 3)
    {
      backTimer += elapsed;
      if (backTimer >= 0.35) backToMainMenu();
    }

    secondCounter += elapsed;
    if (secondCounter >= 2)
    {
      secondCounter = 0;
      rescanFolder();
    }

    if (!uiState.is(Exiting)) scene.updateBlink(elapsed);

    syncInteractionState();

    handleInput(elapsed);

    if (scene.updateAftermath(elapsed)) applyModlist();

    if (fadingItems.length > 0)
    {
      // Iterating backwards so finished fades can be removed in place, super micro optimization
      var i:Int = fadingItems.length;
      while (i-- > 0)
      {
        var fade = fadingItems[i];
        fade.elapsed += elapsed;
        var t = Math.min(1, fade.elapsed / fade.duration);
        fade.item.localAlpha = FlxEase.quadOut(t);
        if (t >= 1) fadingItems.splice(i, 1);
      }
    }

    installer.update(elapsed);
  }

  override public function onFocus():Void
  {
    super.onFocus();
    rescanFolder();
  }

  // INPUT //

  function handleInput(elapsed:Float):Void
  {
    #if FEATURE_ONE_CLICK_INSTALL
    // The install overlay is modal, so it gets first refusal on every input.
    if (installer.popup != null && installer.popup.isBlocking())
    {
      handleInstallPopupInput();
      return;
    }
    #end

    if (uiState.canInteract())
    {
      #if FEATURE_TOUCH_CONTROLS
      if (ControlsHandler.lastInputTouch)
      {
        handleTouch(elapsed);

        return;
      }
      #end

      handleKeyboard(elapsed);
    }
    else if (uiState.is(Exiting) && scene.isShocking && (controls.ACCEPT_P #if FEATURE_TOUCH_CONTROLS || TouchUtil.justPressed #end))
    {
      scene.skipShock();
    }
  }

  function handleMouse():Void
  {
    if (lists.hasTransitions || !uiState.canInteract()) return;

    if (FlxG.mouse.justPressed)
    {
      var target:FlxPoint = FlxG.mouse.getWorldPosition();
      if (buttonBackToMenu.overlapsPoint(target))
      {
        backToMainMenu();
      }
      else if (buttonOpenFolder.overlapsPoint(target))
      {
        openModsFolder();
      }
      else if (buttonDone.overlapsPoint(target))
      {
        applyModlist();
      }
    }
  }

  var acceptDelay:Float = 0;
  var oldSelection:ModMenuSelection;
  var playingElectrocution:Bool = false;

  /**
   * Starts the electrocution sequence.
   */
  function playElectrocutionSequence():Void
  {
    var bgColor:FlxColor = menuBG.color;

    scene.playElectrocutionSequence(() ->
    {
      buttonDone.visible = false;
      buttonOpenFolder.visible = false;
    }, () ->
      {
        FlxTween.color(menuBG, 1, 0xFF232327, bgColor);

        buttonDone.visible = true;
        buttonOpenFolder.visible = true;
      });

    doneButtonAnimator.playAnimation('accept');
    uiState.transition(Exiting);
  }

  // NAVIGATION //

  /**
   * Where each direction leads from each part of the menu, in the order they should be tried.
   * The first one that can be selected gets prioritized.
   * Up and down move through any of the lists first, so for the lists this is only used once you run off the end of one
   * Going down from the bottom row wraps around to the back button, and going up from it wraps around to the bottom row.
   * @param from Which selection we're moving from.
   * @param direction The direction we want to move to.
   * @return Array<ModMenuSelection> An array containing the list of selections possible
   */
  function getNavTargets(from:ModMenuSelection, direction:FlxDirection):Array<ModMenuSelection>
  {
    return switch ([from, direction])
    {
      case [DisabledModList, FlxDirection.UP]:
        [BackToMenu];
      case [DisabledModList, FlxDirection.DOWN]:
        [OpenModsFolder];
      case [
        DisabledModList,
        FlxDirection.LEFT | FlxDirection.RIGHT
      ]:
        [EnabledModList];

      case [EnabledModList, FlxDirection.UP]:
        [BackToMenu];
      case [EnabledModList, FlxDirection.DOWN]:
        [Done];
      case [
        EnabledModList,
        FlxDirection.LEFT | FlxDirection.RIGHT
      ]:
        [DisabledModList];

      case [OpenModsFolder, FlxDirection.UP]:
        [DisabledModList, EnabledModList, BackToMenu];
      case [OpenModsFolder, FlxDirection.DOWN]:
        [BackToMenu];
      case [
        OpenModsFolder,
        FlxDirection.LEFT | FlxDirection.RIGHT
      ]:
        [Done];

      case [Done, FlxDirection.UP]:
        [EnabledModList, DisabledModList, BackToMenu];
      case [Done, FlxDirection.DOWN]:
        [BackToMenu];
      case [
        Done,
        FlxDirection.LEFT | FlxDirection.RIGHT
      ]:
        [OpenModsFolder];

      // The back button remembers which column you came from, so its jiffy
      case [BackToMenu, FlxDirection.DOWN]:
        lastColumnLeft ? [DisabledModList, EnabledModList] : [EnabledModList, DisabledModList];
      case [BackToMenu, FlxDirection.UP]:
        lastColumnLeft ? [OpenModsFolder, Done] : [Done, OpenModsFolder];
      default:
        [];
    }
  }

  /**
   * Whether the selection can be selected right now.
   * gable? Who's gable? *pukes
   * @param target the selection to check.
   */
  function isNavigable(target:ModMenuSelection):Bool
  {
    return switch (target)
    {
      case DisabledModList:
        disabledModItems.modItems.length > 0;
      case EnabledModList:
        enabledModItems.modItems.length > 0;
      default:
        true;
    }
  }

  /**
   * Checks if the UI key for the passed direction was just pressed.
   * @param direction The direction to check
   */
  function isDirectionPressed(direction:FlxDirection):Bool
  {
    return switch (direction)
    {
      case FlxDirection.UP:
        controls.UI_UP_P;
      case FlxDirection.DOWN:
        controls.UI_DOWN_P;
      case FlxDirection.LEFT:
        controls.UI_LEFT_P;
      case FlxDirection.RIGHT:
        controls.UI_RIGHT_P;
    }
  }

  /**
   * Checks if the UI key for the passed direction is being held.
   * @param direction The direction to check
   */
  function isDirectionHeld(direction:FlxDirection):Bool
  {
    return switch (direction)
    {
      case FlxDirection.UP:
        controls.UI_UP;
      case FlxDirection.DOWN:
        controls.UI_DOWN;
      case FlxDirection.LEFT:
        controls.UI_LEFT;
      case FlxDirection.RIGHT:
        controls.UI_RIGHT;
    }
  }

  /**
   * The direction the highlight slides in from. -1 up, 1 down, -2 left, 2 right.
   * @param direction The direction to go towards.
   */
  function getSlideDirection(direction:FlxDirection):Int
  {
    return switch (direction)
    {
      case FlxDirection.UP:
        -1;
      case FlxDirection.DOWN:
        1;
      case FlxDirection.LEFT:
        -2;
      case FlxDirection.RIGHT:
        2;
    }
  }

  /**
   * Reads the direction keys.
   * @param elapsed Elapsed
   */
  function handleNavigation(elapsed:Float):Void
  {
    for (direction in NAV_DIRECTIONS)
    {
      if (isDirectionPressed(direction))
      {
        heldDirection = direction;
        navigate(direction, false);

        navDelayTimer = NAV_DELAY;
        return;
      }
    }

    if (heldDirection == null) return;

    // Checks that the key is still down, instead of waiting for a release event,
    // so letting go while the menu wasn't listening can't leave it repeating forever.
    if (!isDirectionHeld(heldDirection))
    {
      heldDirection = null;

      // Another direction may still be held.
      for (direction in NAV_DIRECTIONS)
      {
        if (isDirectionHeld(direction))
        {
          heldDirection = direction;
          navDelayTimer = NAV_DELAY;
          return;
        }
      }

      return;
    }

    navDelayTimer -= elapsed * navSpeed;

    if (navSpeed < NAV_ACCELERATION_LIMIT) navSpeed += elapsed;

    if (navDelayTimer <= 0)
    {
      navigate(heldDirection, true);

      navDelayTimer = NAV_DELAY;
    }
  }

  /**
   * Moves the selection one step in a direction.
   *
   * @param direction Which way to go.
   * @param isRepeat `true` if the key is being held, keep scrolling inside a list but stop at the end.
   */
  function navigate(direction:FlxDirection, isRepeat:Bool):Void
  {
    var list:Null<ModMenuItemList> = switch (selection)
    {
      case DisabledModList:
        disabledModItems;
      case EnabledModList:
        enabledModItems;
      default:
        null;
    };

    var movingUp:Bool = direction == FlxDirection.UP;

    if (list != null && (movingUp || direction == FlxDirection.DOWN))
    {
      // Holding control moves the mod itself instead of the selection.
      if (selection == EnabledModList && FlxG.keys.pressed.CONTROL)
      {
        if (!isRepeat) lists.reorder(enabledModItems.selectedModItem, movingUp);
        return;
      }

      if (movingUp ? list.moveSelectionBy(1, false) : list.moveSelectionBy(-1, false)) return;

      if (isRepeat) return;
    }

    for (target in getNavTargets(selection, direction))
    {
      if (!isNavigable(target)) continue;

      lastSelectDir = direction;
      selection = target;
      return;
    }
  }

  function handleKeyboard(elapsed:Float):Void
  {
    if (controls.BACK_P)
    {
      FunkinSound.playOnce(Paths.sound('ui/main-menu/cancel-menu'), 0.4);
      pressBackButton();
      return;
    }

    oldSelection = selection;

    handleNavigation(elapsed);

    if (controls.ACCEPT_P && acceptDelay <= 0)
    {
      heldDirection = null;

      FunkinSound.playOnce(Paths.sound('ui/main-menu/scroll-menu'), 0.4);
      enabledModItems.repositionItems();
      disabledModItems.repositionItems();

      switch (selection)
      {
        case DisabledModList:
          lists.enable(disabledModItems.selectedModItem);
        case EnabledModList:
          lists.disable(enabledModItems.selectedModItem);
        case OpenModsFolder:
          openFolderAnimator.playAnimation('accept');
          openFolderAnimator.onFinish = openModsFolder;
        case Done:
          playElectrocutionSequence();
        case BackToMenu:
          pressBackButton();
      }

      oldSelection = selection;

      acceptDelay = 0.02;
    }

    if (acceptDelay > 0) acceptDelay -= elapsed;
    if (oldSelection != selection) handleSelection();
  }

  // UI STATE //

  /**
   * Checks if we can drop files in this menu currently.
   * @return Bool Whether files dropped onto the window should be listened to.
   */
  function canDropFiles():Bool
  {
    return uiState.is(Idle) || uiState.is(Interacting);
  }

  /**
   * Keeps the UI state in step with the items transitioning between the lists.
   */
  function syncInteractionState():Void
  {
    if (uiState.is(Idle) && lists.hasTransitions)
    {
      uiState.transition(Interacting);
    }
    else if (uiState.is(Interacting) && !lists.hasTransitions)
    {
      uiState.transition(Idle);
    }
  }

  /**
   * Calls when the ui state changes.
   * @param previous The previous state we were in.
   * @param current The current state we have now.
   */
  function onUIStateChange(previous:UIState, current:UIState):Void
  {
    heldDirection = null;
  }

  #if FEATURE_TOUCH_CONTROLS
  final touchScrollThreshold:Float = 10;
  var touchList:ModMenuItemList = null;
  var touchItem:ModMenuItem = null;
  var touchStartY:Float = 0;
  var touchLastY:Float = 0;
  var touchScrolling:Bool = false;
  final touchReorderHoldTime:Float = 0.1;
  var touchHoldTimer:Float = 0;
  var touchReordering:Bool = false;
  var touchReorderSlot:Int = -1;

  function handleTouchReorder():Void
  {
    final itemCount:Int = enabledModItems.modItems.length;
    final touchPos = TouchUtil.touch.getWorldPosition(rightRectangle.cameras[0]);
    final localY:Float = touchPos.y - enabledModItems.y - enabledModItems.scrollOffset - ModMenuItemList.ITEM_Y_OFFSET + 8;
    touchPos.put();

    var slot:Int = itemCount - 1 - Math.floor(localY / 112);
    if (slot < 0) slot = 0;
    if (slot > itemCount - 1) slot = itemCount - 1;

    if (slot == touchReorderSlot) return;

    final index:Int = enabledModItems.modItems.indexOf(touchItem);

    if (slot == index)
    {
      touchReorderSlot = slot;
      return;
    }

    lists.reorder(touchItem, slot > index);

    if (enabledModItems.modItems.indexOf(touchItem) == index) touchReorderSlot = slot;
    else
    {
      FunkinSound.playOnce(Paths.sound('ui/main-menu/scroll-menu'), 0.4);
    }
  }

  function getTouchedItem(itemList:ModMenuItemList, box:FunkinSprite):Null<ModMenuItem>
  {
    // Items scrolled outside of the box are clipped, so they can't be tapped.
    final touchPos = TouchUtil.touch.getWorldPosition(box.cameras[0]);
    final inView:Bool = touchPos.y >= box.y + 60 && touchPos.y <= box.y + box.height - 15;
    touchPos.put();

    if (!inView) return null;

    for (item in itemList.modItems)
    {
      if (TouchUtil.overlapsComplex(item)) return item;
    }

    return null;
  }

  function resetTouch():Void
  {
    if (touchReordering) enabledModItems.deselect();

    touchReordering = false;
    touchReorderSlot = -1;
    touchHoldTimer = 0;
    touchList = null;
    touchItem = null;
    touchScrolling = false;
  }

  function handleTouch(elapsed:Float):Void
  {
    if (lists.hasTransitions || uiState.is(Exiting) || backPressStage > 0 || TouchUtil.touch == null)
    {
      resetTouch();
      return;
    }

    if (TouchUtil.justPressed)
    {
      resetTouch();

      if (TouchUtil.overlapsComplex(leftRectangle))
      {
        touchList = disabledModItems;
        touchItem = getTouchedItem(disabledModItems, leftRectangle);
      }
      else if (TouchUtil.overlapsComplex(rightRectangle))
      {
        touchList = enabledModItems;
        touchItem = getTouchedItem(enabledModItems, rightRectangle);
      }

      touchStartY = TouchUtil.touch.viewY;
      touchLastY = touchStartY;
    }
    else if (touchReordering && TouchUtil.pressed)
    {
      handleTouchReorder();
    }
    else if (touchList != null && TouchUtil.pressed)
    {
      final touchY:Float = TouchUtil.touch.viewY;

      if (!touchScrolling && touchList == enabledModItems && touchItem != null && !touchItem.locked && !enabledModItems.isPinnedItem(touchItem))
      {
        touchHoldTimer += elapsed;

        if (touchHoldTimer >= touchReorderHoldTime)
        {
          FunkinSound.playOnce(Paths.sound('ui/main-menu/scroll-menu'), 0.4);

          touchReordering = true;
          touchReorderSlot = enabledModItems.modItems.indexOf(touchItem);
          enabledModItems.selectModItem(touchItem, false);

          return;
        }
      }

      if (!touchScrolling && Math.abs(touchY - touchStartY) >= touchScrollThreshold)
      {
        touchScrolling = true;
        touchLastY = touchY;
      }

      if (touchScrolling) touchList.scrollBy(touchY - touchLastY);

      touchLastY = touchY;
    }
    else if (touchList != null)
    {
      if (!touchScrolling && !touchReordering && touchItem != null && !touchItem.locked && TouchUtil.justReleased && TouchUtil.overlapsComplex(touchItem))
      {
        FunkinSound.playOnce(Paths.sound('ui/main-menu/scroll-menu'), 0.4);

        if (touchList == disabledModItems)
        {
          lists.enable(touchItem, false);
        }
        else
        {
          lists.disable(touchItem, false);
        }

        selection = (touchList == disabledModItems) ? DisabledModList : EnabledModList;
      }

      resetTouch();
    }

    if (TouchUtil.overlapsComplex(hitboxOpenFolder) && selection != OpenModsFolder)
    {
      selection = OpenModsFolder;
    }
    else if (TouchUtil.overlapsComplex(buttonDone) && selection != Done)
    {
      selection = Done;
    }
    else if (TouchUtil.overlapsComplex(buttonBackToMenu) && selection != BackToMenu)
    {
      selection = BackToMenu;
    }

    if (TouchUtil.pressAction(hitboxOpenFolder))
    {
      FunkinSound.playOnce(Paths.sound('ui/main-menu/scroll-menu'), 0.4);

      openFolderAnimator.playAnimation('accept');
      openFolderAnimator.onFinish = () ->
      {
        openModsFolder();
        openFolderAnimator.playAnimation('deselect');
      };
    }

    if (TouchUtil.pressAction(buttonDone))
    {
      FunkinSound.playOnce(Paths.sound('ui/main-menu/scroll-menu'), 0.4);

      playElectrocutionSequence();
    }

    if (TouchUtil.overlapsComplex(buttonBackToMenu) && TouchUtil.justPressed)
    {
      playBackButtonAnimation('press', true);
    }

    if (buttonBackToMenu.animation.name == 'press' && !TouchUtil.pressed)
    {
      if (TouchUtil.justReleased && TouchUtil.overlapsComplex(buttonBackToMenu))
      {
        uiState.transition(Exiting);

        backPressStage = 2;

        playBackButtonAnimation('confirm', true);
      }
      else
      {
        playBackButtonAnimation('idle', true);
      }
    }
  }
  #end

  var lastModIndex:Int = 0;

  function handleSelection():Void
  {
    FunkinSound.playOnce(Paths.sound('ui/main-menu/scroll-menu'), 0.4);

    switch (selection)
    {
      case DisabledModList | OpenModsFolder:
        lastColumnLeft = true;
      case EnabledModList | Done:
        lastColumnLeft = false;
      default:
        // nothing.
    }

    switch (selection)
    {
      case DisabledModList:
        lastModIndex = enabledModItems.selectedItemIndex;
      case EnabledModList:
        lastModIndex = disabledModItems.selectedItemIndex;
      default:
        // nothing.
    }

    if (selection != BackToMenu) playBackButtonAnimation('idle');
    disabledModItems.deselect();
    enabledModItems.deselect();

    if (openFolderAnimator.curAnim == 'select' && selection != OpenModsFolder) openFolderAnimator.playAnimation('deselect');
    if (doneButtonAnimator.curAnim == 'select' && selection != Done) doneButtonAnimator.playAnimation('deselect');

    if (disabledModItems.modItems.length == 0 && selection == DisabledModList) selection = EnabledModList;

    switch (selection)
    {
      case DisabledModList:
        switch (oldSelection)
        {
          case OpenModsFolder | Done:
            disabledModItems.selectLastItem(lastSelectDir);
          case EnabledModList:
            var offset = (disabledModItems.length - 1) - (enabledModItems.length - 1);

            if (disabledModItems.modItems.indexOf(disabledModItems.modItems[lastModIndex + offset]) == -1)
            {
              disabledModItems.selectLastItem(lastSelectDir);
            }
            else
            {
              disabledModItems.selectItem(lastModIndex + offset, lastSelectDir);
            }
          default:
            disabledModItems.selectFirstItem(lastSelectDir);
        }
      case EnabledModList:
        switch (oldSelection)
        {
          case OpenModsFolder | Done:
            enabledModItems.selectLastItem(lastSelectDir);
          case DisabledModList:
            var offset:Int = (enabledModItems.length - 1) - (disabledModItems.length - 1);
            if (enabledModItems.modItems.indexOf(enabledModItems.modItems[lastModIndex + offset]) == -1)
            {
              enabledModItems.selectLastItem(lastSelectDir);
            }
            else
            {
              enabledModItems.selectItem(lastModIndex + offset, lastSelectDir);
            }
          default:
            enabledModItems.selectFirstItem(lastSelectDir);
        }
      case OpenModsFolder:
        openFolderAnimator.playAnimation('select');
      case Done:
        doneButtonAnimator.playAnimation('select');
      case BackToMenu:
        playBackButtonAnimation('hover');
    }

    lastSelectDir = null;
  }

  // MOD LIST BUILDING //

  function animateNewItemsIn(list:ModMenuItemList, newItems:Array<ModMenuItem>):Void
  {
    list.animateItemsToLayout(0.28, FlxEase.linear);

    for (item in newItems)
    {
      fadeItemIn(item);
    }
  }

  var fadingItems:Array<
    {item:ModMenuItem, elapsed:Float, duration:Float}> = [];

  function fadeItemIn(item:ModMenuItem, duration:Float = 0.5):Void
  {
    item.localAlpha = 0;
    fadingItems.push({
      item: item,
      elapsed: 0,
      duration: duration
    });
  }

  function refreshModList(doFade:Bool = true):Array<ModMenuItem>
  {
    var oldSelectedId:Null<String> = null;
    if (selection == DisabledModList && disabledModItems.selectedModItem != null)
    {
      oldSelectedId = disabledModItems.selectedModItem.getModId();
    }
    else if (selection == EnabledModList && enabledModItems.selectedModItem != null)
    {
      oldSelectedId = enabledModItems.selectedModItem.getModId();
    }

    disabledModItems.title = 'DISABLED';
    disabledModItems.x = leftRectangle.x;
    disabledModItems.y = leftRectangle.y;

    enabledModItems.title = 'ENABLED';
    enabledModItems.x = rightRectangle.x;
    enabledModItems.y = rightRectangle.y;

    var synced = lists.syncWithDisk();
    var newDisabledItems:Array<ModMenuItem> = synced.newDisabled;
    var newEnabledItems:Array<ModMenuItem> = synced.newEnabled;

    var usingTouch:Bool = false;

    #if FEATURE_TOUCH_CONTROLS
    if (!ControlsHandler.usingExternalInputDevice)
    {
      usingTouch = true;
    }
    #end

    if (!usingTouch)
    {
      // reselect items if possible, otherwise select first item in the list
      if (oldSelectedId != null)
      {
        if (selection == DisabledModList)
        {
          var itemToSelect = disabledModItems.modItems.find((item) -> item.getModId() == oldSelectedId);
          if (itemToSelect != null)
          {
            disabledModItems.selectModItem(itemToSelect);
          }
          else
          {
            disabledModItems.selectFirstItem();
          }
        }
        else if (selection == EnabledModList)
        {
          var itemToSelect = enabledModItems.modItems.find((item) -> item.getModId() == oldSelectedId);
          if (itemToSelect != null)
          {
            enabledModItems.selectModItem(itemToSelect);
          }
          else
          {
            enabledModItems.selectFirstItem();
          }
        }
      }
      else
      {
        if (selection == DisabledModList)
        {
          disabledModItems.selectFirstItem();
        }
        else if (selection == EnabledModList)
        {
          enabledModItems.selectFirstItem();
        }
      }
    }

    if (newDisabledItems.length > 0 && doFade)
    {
      animateNewItemsIn(disabledModItems, newDisabledItems);
    }
    else
    {
      disabledModItems.repositionItems();
    }

    if (newEnabledItems.length > 0 && doFade)
    {
      animateNewItemsIn(enabledModItems, newEnabledItems);
    }
    else
    {
      enabledModItems.repositionItems();
    }

    if (!doFade)
    {
      for (item in newDisabledItems) item.localAlpha = 1;
      for (item in newEnabledItems) item.localAlpha = 1;
    }

    return newDisabledItems;
  }

  function applyModlist():Void
  {
    lists.applyToPolymod();

    buttonDone.visible = false;
    buttonOpenFolder.visible = false;

    var blackScreen:FunkinSprite = new FunkinSprite().makeSolidColor(FlxG.width, FlxG.height, FlxColor.BLACK);
    blackScreen.scrollFactor.set(0, 0);
    blackScreen.camera = camHUD;
    blackScreen.zIndex = 1000;
    add(blackScreen);
    refresh();

    FlxTransitionableState.skipNextTransIn = true;

    // Directly switch to HotReloadState; we don't need Transition since HotReloadState handles asset loading.
    Transition.switchState(() -> new HotReloadState(), {
      transition: None,
      shouldPurgeCache: false
    });
  }

  // HELPERS //

  function distanceToPoint(point1:FlxPoint, point2:FlxPoint):Float
  {
    var dx = point1.x - point2.x;
    var dy = point1.y - point2.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  /**
   * Open the folder where the user's mods are stored.
   */
  function openModsFolder():Void
  {
    #if android
    DataFolderUtil.openDataFolder();
    #elseif ios
    System.openURL('shareddocuments://');
    #elseif js
    PolymodHandler.loadModFromFileDialog(() -> highlightNewMod());
    #elseif sys
    FileUtil.openFolder(Path.join([FileUtil.gameDirectory, PolymodHandler.MOD_FOLDER]));
    #else
    FileUtil.openFolder(PolymodHandler.MOD_FOLDER);
    #end
    openFolderAnimator.playAnimation('select');
  }

  /**
   * FUCK.
   */
  public static function queryAssets(type:funkin.assets.Assets.AssetType):Array<funkin.assets.Paths.AssetPath>
  {
    var results:Array<funkin.assets.Paths.AssetPath> = [];

    results.appendUnique(ModMenuButton.queryAssets(type, 'done'));
    results.appendUnique(ModMenuButton.queryAssets(type, 'open-folder'));
    results.appendUnique(ModMenuButton.queryAssets(type, 'import-folder'));

    switch (type)
    {
      case JSON:
        results.appendUnique([funkin.assets.Paths.music('ui/mods/mod-menu-ambience').metadata()]);

        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/smoke-cloud').json());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/back-arrow').json());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/foreground-wires-bottom').json());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/foreground-wires-top').json());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/sparks').json());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/characters/bf').json());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/characters/gf').json());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/characters/empty-chair').json());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/characters/pinhead').json());

        results.appendUnique(funkin.assets.Assets.listInPath('ui/mods/characters/', JSON));

      case IMAGE:
        results.appendUnique([
          funkin.assets.Paths.image('ui/mods/smoke'),
          funkin.assets.Paths.image('ui/mods/bg'),
          funkin.assets.Paths.image('ui/mods/top-text'),
          funkin.assets.Paths.image('ui/mods/carbattery'),
          funkin.assets.Paths.image('ui/mods/gfwire'),
          funkin.assets.Paths.image('ui/mods/box'),
          funkin.assets.Paths.image('ui/mods/base-icon'),
          funkin.assets.Paths.image('ui/mods/fallback-icon'),
          funkin.assets.Paths.image('ui/mods/bgwires'),
          funkin.assets.Paths.image('ui/mods/drop-hover')
        ]);
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/smoke-cloud').image());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/back-arrow').image());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/foreground-wires-bottom').image());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/foreground-wires-top').image());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/sparks').image());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/characters/bf').image());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/characters/gf').image());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/characters/empty-chair').image());
        results.appendUnique(funkin.assets.Paths.animateAtlas('ui/mods/characters/pinhead').image());

      case XML:
        results.appendUnique([
          funkin.assets.Paths.xml('ui/mods/smoke'),
          funkin.assets.Paths.xml('ui/mods/carbattery'),
          funkin.assets.Paths.xml('ui/mods/gfwire')
        ]);

      case SOUND:
        results.appendUnique([funkin.assets.Paths.music('ui/mods/mod-menu-ambience').audio()]);
        results.appendUnique(funkin.assets.Assets.listInPath('ui/mods/sounds/', SOUND));

      case FONT:
        results.appendUnique([funkin.assets.Paths.file('ui/fonts/FunkinLingLong', 'otf')]);

      case SHADER:
        results.appendUnique([funkin.assets.Paths.frag('ui/shaders/replace-color')]);

      default:
    }
    return results;
  }

  /**
   * Return to the main menu.
   */
  function backToMainMenu():Void
  {
    uiState.transition(Exiting);
    FlxG.keys.enabled = false;
    Cursor.hide();
    Transition.switchState(() -> new MainMenuState(), {
      assetQuery: MainMenuState.queryAssets,
      transition: None
    });
    FunkinSound.playOnce(Paths.sound('ui/main-menu/cancel-menu').toString());
  }
}

/**
 * The different selections the mod menu can have.
 */
enum ModMenuSelection
{
  DisabledModList;
  EnabledModList;
  BackToMenu;
  OpenModsFolder;
  Done;
}
