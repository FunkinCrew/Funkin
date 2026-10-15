package funkin.ui.modmenu;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.graphics.framebuffer.DropShadowLayer;
import funkin.input.Cursor;
import funkin.modding.PolymodHandler;
import funkin.ui.FullScreenScaleMode;
import funkin.ui.MusicBeatState;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.modmenu.ModMenuCharacter.CharacterAnimation;
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
   * This flag is enabled when returning to the main menu.
   * This should disable other interaction.
   */
  var exitingMenu:Bool = false;

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
  var lastSelectDir:Int = 0;
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

    buttonOpenFolder.x = leftRectangle.x + 180;
    buttonOpenFolder.y = FlxG.height * 0.89;
    buttonOpenFolder.scale.set(0.65, 0.65);
    buttonOpenFolder.loadTexture('ui/mods/open-folder');
    buttonOpenFolder.updateHitbox();
    buttonOpenFolder.zIndex = 1000;
    buttonOpenFolder.camera = camHUD;
    buttonOpenFolder.graphicName = 'open-folder';
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
      allowInput = enabled;
    }, () ->
      {
        allowInput = true;
        hideFileDropHover();
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
    dropShadowUI.renderer.blacklistSprite(menuBG);
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
    if (exitingMenu) return;
    exitingMenu = true;
    backPressStage = 1;
    playBackButtonAnimation('press', true);
  }

  function startFileDropHover():Void
  {
    if (!allowInput) return;

    installer.showDropOverlay();
  }

  function hideFileDropHover(x:Float, y:Float):Void
  {
    if (!allowInput) return;

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

  public override function destroy():Void
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

  public function onDropFile(file:lime.utils.DroppedFile, state:String, x:Float, y:Float):Void
  {
    if (!allowInput) return;

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
   *
   * @param request The parsed link.
   */
  public function beginOneClickInstall(request:OneClickRequest):Void
  {
    if (installer == null) return;

    installer.beginOneClick(request);
  }

  /**
   * Tells the card how many more mods are lined up behind the one it's showing.
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
  var allowInput:Bool = true;
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

    if (!exitingMenu)
    {
      scene.updateBlink(elapsed);
    }

    handleInput(elapsed);

    if (!allowInput && !scene.isShocking)
    {
      if (scene.updateAftermath(elapsed)) applyModlist();
    }

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

    if (allowInput)
    {
      #if FEATURE_TOUCH_CONTROLS
      if (ControlsHandler.lastInputTouch)
      {
        handleTouch(elapsed);

        return;
      }
      #end

      handleKeyboard();
    }
    else
    {
      if ((controls.ACCEPT_P #if FEATURE_TOUCH_CONTROLS || TouchUtil.justPressed #end) && scene.isShocking)
      {
        scene.skipShock();
      }
    }
  }

  function handleMouse():Void
  {
    if (lists.hasTransitions || exitingMenu) return;

    if (FlxG.mouse.justPressed)
    {
      // TODO: Make this less bad

      var target = FlxG.mouse.getWorldPosition();

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

  var holdDirection:Int = 0; // -1 for up, 1 for down, -2 for left, 2 for right
  var holdTimer:Float = 0;
  var doHoldAction:Bool = false;
  var delay:Float = 0;
  var acceptDelay:Float = 0;
  var oldSelection:ModMenuSelection;
  var lastInput:String = '';

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
    allowInput = false;
  }

  function handleKeyboard():Void
  {
    if (lists.hasTransitions || exitingMenu) return;

    var pressingCtrl:Bool = FlxG.keys.pressed.CONTROL;
    if (controls.BACK_P)
    {
      FunkinSound.playOnce(Paths.sound('ui/main-menu/cancel-menu'), 0.4);
      pressBackButton();
      return;
    }

    oldSelection = selection;

    if (controls.UI_LEFT_P)
    {
      switch (selection)
      {
        case DisabledModList:
          selection = Done;
          lastSelectDir = -2;
        case EnabledModList:
          if (disabledModItems.modItems.length > 0)
          {
            selection = DisabledModList;
            lastSelectDir = -2;
          }
          else
            selection = OpenModsFolder;
        case OpenModsFolder:
          selection = EnabledModList;
          lastSelectDir = -2;
        case Done:
          selection = OpenModsFolder;
          lastSelectDir = -2;
        case BackToMenu:
          // Nothing
      }
    }

    if (controls.UI_RIGHT_P)
    {
      switch (selection)
      {
        case DisabledModList:
          if (enabledModItems.modItems.length > 0)
          {
            selection = EnabledModList;
            lastSelectDir = 2;
          }
        case EnabledModList:
          selection = OpenModsFolder;
          lastSelectDir = 2;
        case OpenModsFolder:
          selection = Done;
          lastSelectDir = 2;
        case Done:
          selection = DisabledModList;
          lastSelectDir = 2;
        case BackToMenu:
          // Nothing
      }
    }

    if (controls.UI_UP_P)
    {
      lastInput = 'up';
      switch (selection)
      {
        case DisabledModList:
          if (!disabledModItems.moveUp(false))
          {
            selection = BackToMenu;
            lastSelectDir = 1;
          }
        case EnabledModList:
          if (pressingCtrl) lists.reorder(enabledModItems.selectedModItem, true);
          else
          {
            if (!enabledModItems.moveUp(false))
            {
              selection = BackToMenu;
              lastSelectDir = -1;
            }
          }
        case OpenModsFolder:
          selection = DisabledModList;
          lastSelectDir = -1;
        case Done:
          selection = EnabledModList;
          lastSelectDir = -1;
        case BackToMenu:
          trace(' MOD MENU '.bold().bg_orange() + ' lastSelectDir: ' + lastSelectDir);
          if (lastSelectDir == -1) selection = Done;
          else
            selection = OpenModsFolder;
      }
    }

    if (controls.UI_DOWN_P)
    {
      lastInput = 'down';
      switch (selection)
      {
        case DisabledModList:
          if (!disabledModItems.moveDown(false))
          {
            selection = OpenModsFolder;
            lastSelectDir = 1;
          }
        case EnabledModList:
          if (pressingCtrl) lists.reorder(enabledModItems.selectedModItem, false);
          else
          {
            if (!enabledModItems.moveDown(false))
            {
              selection = Done;
              lastSelectDir = 1;
            }
          }
        case OpenModsFolder:
          selection = BackToMenu;
          lastSelectDir = 1;
        case Done:
          selection = BackToMenu;
          lastSelectDir = -1;
        case BackToMenu:
          if (lastSelectDir == -1) selection = EnabledModList;
          else
            selection = DisabledModList;
      }
    }

    if (controls.UI_UP || controls.UI_DOWN || controls.UI_LEFT || controls.UI_RIGHT)
    {
      if (holdDirection == 0)
      {
        holdDirection = controls.UI_UP ? -1 : controls.UI_DOWN ? 1 : controls.UI_LEFT ? -2 : 2;
        holdTimer = 0.5; // initial delay before starting to scroll
      }
      else if
        ((controls.UI_UP && holdDirection == -1)
          || (controls.UI_DOWN && holdDirection == 1)
          || (controls.UI_LEFT && holdDirection == -2)
          || (controls.UI_RIGHT && holdDirection == 2)
        )
      {
        holdTimer -= FlxG.elapsed;
        if (holdTimer <= 0)
        {
          doHoldAction = true;
        }
      }
    }
    else
    {
      holdDirection = 0;
      doHoldAction = false;
    }

    if (doHoldAction && delay <= 0)
    {
      delay = 0.1;
      switch (selection)
      {
        case DisabledModList:
          switch (holdDirection)
          {
            case -1:
              disabledModItems.moveUp();
            case 1:
              disabledModItems.moveDown();
            case -2:
              selection = Done;
              lastSelectDir = -2;
            case 2:
              selection = EnabledModList;
              lastSelectDir = 2;
          }
        case EnabledModList:
          switch (holdDirection)
          {
            case -1:
              enabledModItems.moveUp();
            case 1:
              enabledModItems.moveDown();
            case -2:
              if (disabledModItems.modItems.length > 0) selection = DisabledModList;
              else
                selection = Done;
              lastSelectDir = -2;
            case 2:
              selection = OpenModsFolder;
              lastSelectDir = 2;
          }
        case OpenModsFolder:
          switch (holdDirection)
          {
            case -1:
              selection = DisabledModList;
              lastSelectDir = -1;
            case 1:
              selection = DisabledModList;
              lastSelectDir = 1;
            case -2:
              selection = EnabledModList;
              lastSelectDir = -2;
            case 2:
              selection = Done;
              lastSelectDir = 2;
          }
        case Done:
          switch (holdDirection)
          {
            case -1:
              selection = EnabledModList;
              lastSelectDir = -1;
            case 1:
              selection = EnabledModList;
              lastSelectDir = 1;
            case -2:
              selection = OpenModsFolder;
              lastSelectDir = -2;
            case 2:
              selection = DisabledModList;
              lastSelectDir = 2;
          }
        case BackToMenu:
          switch (holdDirection)
          {
            case -1:
              if (lastSelectDir == -1) selection = Done; else selection = OpenModsFolder;
            case 1:
              if (lastSelectDir == -1) selection = EnabledModList; else selection = DisabledModList;
            case -2:
              // Nothing
            case 2:
              // Nothing
          }
      }
    }
    if (delay > 0) delay -= FlxG.elapsed;

    if (controls.ACCEPT_P && !lists.hasTransitions && acceptDelay <= 0)
    {
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

    if (acceptDelay > 0) acceptDelay -= FlxG.elapsed;

    if (oldSelection != selection) handleSelection();
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

  function checkItemGrab(itemList:ModMenuItemList,
    targetSelection:ModMenuSelection):Void
  {
    if (grabbedItem == null)
    {
      itemList.deselect();
    }

    for (item in itemList.modItems)
    {
      if (!item.locked && TouchUtil.overlapsComplex(item) && TouchUtil.pressed && Math.abs(TouchUtil.touch?.deltaViewX) >= touchDeltaXThreshold)
      {
        FunkinSound.playOnce(Paths.sound('ui/main-menu/scroll-menu'), 0.4);

        itemList.selectModItem(item, false);

        grabbedItem = item;
        originalItemList = itemList;

        lists.completeTransition(lists.findTransition(grabbedItem));

        lists.putItemInTransitionLayer(item, grabbedItem.x, grabbedItem.y);

        selection = targetSelection;
      }
    }
  }

  var touchScrolling:Bool = false;

  function handleTouch(elapsed:Float):Void
  {
    if (lists.hasTransitions || exitingMenu || backPressStage > 0) return;
    if (touchScrolling)
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
        checkItemGrab(enabledModItems, EnabledModList);
        checkItemGrab(disabledModItems, DisabledModList);

        if (TouchUtil.pressed && Math.abs(TouchUtil.touch?.deltaViewY) >= touchDeltaYThreshold)
        {
          touchScrolling = true;
        }
      }
      else
      {
        final targetX:Float = TouchUtil.touch?.x - grabbedItem.width / 2;
        final targetY:Float = TouchUtil.touch?.y - grabbedItem.height / 2;

        grabbedItem.localX = MathUtil.smoothLerpPrecision(grabbedItem.localX, targetX, elapsed, 0.5);
        grabbedItem.localY = MathUtil.smoothLerpPrecision(grabbedItem.localY, targetY, elapsed, 0.5);

        if (!TouchUtil.pressed)
        {
          var targetList:ModMenuItemList = null;

          var listChanged:Bool = false;

          switch (selection)
          {
            case EnabledModList:
              targetList = enabledModItems;

              if (TouchUtil.overlapsComplex(leftRectangle))
              {
                targetList = disabledModItems;

                selection = DisabledModList;

                lists.disable(grabbedItem, true);

                listChanged = true;
              }

            case DisabledModList:
              targetList = disabledModItems;

              if (TouchUtil.overlapsComplex(rightRectangle))
              {
                targetList = enabledModItems;

                selection = EnabledModList;

                final result:Bool = lists.enable(grabbedItem, true);

                listChanged = result;
              }

            default:
              // Isnt supposed to happen.
          }

          if (!listChanged)
          {
            targetList = originalItemList;

            var finalIndex:Int = targetList.modItems.indexOf(grabbedItem);

            var batchFutureCount:Int = targetList.modItems.length;

            var targetTransitionX:Float = targetList.x + ModMenuItemList.ITEM_X_OFFSET;
            var targetTransitionY:Float = targetList.y + targetList.getModItemYPosForCount(finalIndex, batchFutureCount) + targetList.scrollOffset;

            lists.startItemTransition(grabbedItem, targetTransitionX, targetTransitionY, targetList, finalIndex);
          }

          targetList.deselect();

          grabbedItem = null;
          originalItemList = null;
        }
      }
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
        exitingMenu = true;
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
        switch(oldSelection)
        {
          case OpenModsFolder:
            if(lastInput == 'up') disabledModItems.selectLastItem(lastSelectDir);
          case EnabledModList:
            var offset = (disabledModItems.length - 1) - (enabledModItems.length - 1);

            if (disabledModItems.modItems.indexOf(disabledModItems.modItems[lastModIndex + offset]) == -1) disabledModItems.selectLastItem(lastSelectDir);
            else disabledModItems.selectItem(lastModIndex + offset, lastSelectDir);
          default:
            disabledModItems.selectFirstItem(lastSelectDir);
        }
      case EnabledModList:
        switch(oldSelection)
        {
          case OpenModsFolder:
            if(lastInput == 'up') enabledModItems.selectLastItem(lastSelectDir);
          case DisabledModList:
            var offset = (enabledModItems.length - 1) - (disabledModItems.length - 1);

            if(enabledModItems.modItems.indexOf(enabledModItems.modItems[lastModIndex + offset]) == -1) enabledModItems.selectLastItem(lastSelectDir);
            else enabledModItems.selectItem(lastModIndex + offset, lastSelectDir);
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

    lastInput = '';
    if (selection != BackToMenu) lastSelectDir = 0;
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
    if (selection == DisabledModList && disabledModItems.selectedModItem != null) oldSelectedId = disabledModItems.selectedModItem.getModId();
    else if (selection == EnabledModList && enabledModItems.selectedModItem != null) oldSelectedId = enabledModItems.selectedModItem.getModId();

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
          if (itemToSelect != null) disabledModItems.selectModItem(itemToSelect);
          else
            disabledModItems.selectFirstItem();
        }
        else if (selection == EnabledModList)
        {
          var itemToSelect = enabledModItems.modItems.find((item) -> item.getModId() == oldSelectedId);
          if (itemToSelect != null) enabledModItems.selectModItem(itemToSelect);
          else
            enabledModItems.selectFirstItem();
        }
      }
      else
      {
        if (selection == DisabledModList) disabledModItems.selectFirstItem();
        else if (selection == EnabledModList) enabledModItems.selectFirstItem();
      }
    }

    if (newDisabledItems.length > 0 && doFade) animateNewItemsIn(disabledModItems, newDisabledItems);
    else
      disabledModItems.repositionItems();

    if (newEnabledItems.length > 0 && doFade) animateNewItemsIn(enabledModItems, newEnabledItems);
    else
      enabledModItems.repositionItems();

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
    FlxG.switchState(() -> new HotReloadState());
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
    #else
    #if sys
    FileUtil.openFolder(Path.join([FileUtil.gameDirectory, PolymodHandler.MOD_FOLDER]));
    #else
    FileUtil.openFolder(PolymodHandler.MOD_FOLDER);
    #end
    #end
    openFolderAnimator.playAnimation('select');
  }

  /**
   * Return to the main menu.
   */
  function backToMainMenu():Void
  {
    exitingMenu = true;
    FlxG.keys.enabled = false;
    Cursor.hide();
    FlxG.switchState(() -> new MainMenuState());
    FunkinSound.playOnce(Paths.sound('ui/main-menu/cancel-menu').toString());
  }
}

enum ModMenuSelection
{
  DisabledModList;
  EnabledModList;
  BackToMenu;
  OpenModsFolder;
  Done;
}
