package funkin.ui.modmenu;

import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.InitState;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.graphics.framebuffer.DropShadowLayer;
import funkin.graphics.shaders.PureColor;
import funkin.group.FunkinGroup.FunkinSpriteGroup;
import funkin.input.Cursor;
import funkin.modding.PolymodHandler;
import funkin.save.Save;
import funkin.ui.FullScreenScaleMode;
import funkin.ui.MusicBeatState;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.modmenu.ModMenuCharacter.CharacterAnimation;
import funkin.util.FileUtil;
import funkin.util.PropertyAnimator;
import funkin.util.WindowUtil;
import haxe.io.Path;
import polymod.Polymod.ModDependencies;
import polymod.Polymod.ModMetadata;
import polymod.PolymodConfig;
#if FEATURE_DISCORD_RPC
import funkin.api.discord.DiscordClient;
#end
#if android
import funkin.external.android.DataFolderUtil;
#elseif ios
import lime.system.System;
#end
#if FEATURE_ONE_CLICK_INSTALL
import funkin.modding.install.ModInstaller;
import funkin.modding.install.ModInstaller.OneClickMod;
import funkin.modding.install.ModInstaller.OneClickRequest;
import funkin.modding.install.OneClickInstallHandler;
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
  static inline final BASE_GAME_MOD_ICON_PATH:String = 'ui/mods/base-icon';

  /**
   * BF in the mod menu.
   */
  public var bf:ModMenuCharacter;

  /**
   * GF in the mod menu.
   * TODO: Implement.
   */
  public var gf:ModMenuCharacter;

  /**
   * The ambience in the mod menu.
   */
  public var ambience:ModMenuAmbience;

  /**
   * The drop shadow layer instance for UI elements.
   */
  public var dropShadowUI:Null<DropShadowLayer>;

  /**
   * The drop shadow layer instance for characters.
   * Slightly weaker than the UI one.
   */
  public var dropShadowCharacters:Null<DropShadowLayer>;

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

  #if FEATURE_ONE_CLICK_INSTALL
  /**
   * The overlay that drives a one-click install, from the confirmation prompt to the result.
   */
  var installPopup:ModMenuInstallPopup;

  /**
   * The mod a one-click install is waiting for the player to confirm.
   */
  var pendingInstall:Null<OneClickMod> = null;

  /**
   * Set once the player cancels, so a download that's already in flight gets thrown away.
   */
  var installCancelled:Bool = false;
  #end

  var disabledModItems:ModMenuItemList = new ModMenuItemList();
  var enabledModItems:ModMenuItemList = new ModMenuItemList();
  var selection:ModMenuSelection = DisabledModList;
  var transitionLayer:FunkinSpriteGroup;

  /**
   * Items that are currently flying between the two lists.
   * Each one owns the manual flight state (via ModMenuItem.startFlight), plus the
   * list/index it should land in once that flight completes.
   */
  var pendingTransitions:Array<TransitionRecord> = [];

  var bgWires:FunkinSprite;
  var darkness:FunkinSprite;
  var fileDrop:FunkinSprite;
  var openFolderAnimator:PropertyAnimator;
  var doneButtonAnimator:PropertyAnimator;
  var lastSelectDir:Int = 0;
  var newEnabledItems:Array<ModMenuItem> = [];
  var itemsInFolder:Array<String> = [];
  var crispySmokeBF:FunkinSprite;
  var crispySmokeGF:FunkinSprite;
  var smokeCloud:FunkinSprite;
  var whiteColor:PureColor = new PureColor(FlxColor.WHITE);
  var menuBG:FunkinSprite;
  var carBattery:FunkinSprite;
  var fgWires:FunkinSprite;
  var shockTimer:FlxTimer = new FlxTimer();
  var sparks:ModMenuSparks;
  var gfWire:FunkinSprite;

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

    var assetPaths:Array<String> = [
      'ui/mods/smoke',
      'ui/mods/smoke-cloud/spritemap1'
    ];

    for (assetPath in assetPaths)
    {
      FlxG.bitmap.add(Paths.image(assetPath));
    }

    camCharacters = new FunkinCamera('modMenuCharacters');
    camHUD = new FunkinCamera('modMenuHUD');
    camOther = new FunkinCamera('modMenuOther');
  }

  override public function create():Void
  {
    #if FEATURE_DISCORD_RPC
    DiscordClient.instance.setPresence({state: "In the Mod Menu", details: null});
    #end

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

    super.create();

    enabledModItems.pinnedTopModId = BASE_GAME_MOD_ID;

    menuBG = FunkinSprite.create('ui/mods/bg');
    menuBG.scale.set(0.66, 0.67);
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    menuBG.zIndex = 0;
    add(menuBG);

    #if !mobile
    dropShadowUI = new DropShadowLayer(cast FlxG.camera, 0xA91E1E1E, 2, 2);
    dropShadowUI.zIndex = 5;
    add(dropShadowUI);

    dropShadowCharacters = new DropShadowLayer(camCharacters, 0xA91E1E1E, 2, 1);
    dropShadowCharacters.zIndex = 0;
    dropShadowCharacters.camera = camCharacters;
    add(dropShadowCharacters);
    #end

    var topText:FunkinSprite = FunkinSprite.create('ui/mods/top-text');
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
    var dragText:FlxText = new FlxText(leftRectangle.x, FlxG.height * 0.13, dragTextWidth, 'Drag packs onto this window to add new mods');
    #if FEATURE_TOUCH_CONTROLS
    dragText.text = 'Tap a mod to switch lists. Swipe to scroll, hold to drag mods.';
    #end
    dragText.setFormat(Paths.font('FunkinLingLong.otf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER);
    dragText.scale.set(1, 0.8);
    dragText.letterSpacing = 5;
    dragText.zIndex = 10;
    add(dragText);

    refreshModList(false);

    enabledModItems.zIndex = 15;
    enabledModItems.addElements(this);
    add(enabledModItems);

    disabledModItems.zIndex = 15;
    disabledModItems.addElements(this);
    add(disabledModItems);

    transitionLayer = new FunkinSpriteGroup();
    transitionLayer.zIndex = 20;
    add(transitionLayer);

    enabledModItems.titleText.x = rightRectangle.x + (rightRectangle.width / 2) - (enabledModItems.titleText.width / 2);
    enabledModItems.titleText.y = rightRectangle.y + 14;
    disabledModItems.titleText.x = leftRectangle.x + (leftRectangle.width / 2) - (disabledModItems.titleText.width / 2);
    disabledModItems.titleText.y = leftRectangle.y + 14;

    enabledModItems.clipRect = FlxRect.get(0, 60, rightRectangle.width, rightRectangle.height - 75);
    disabledModItems.clipRect = FlxRect.get(0, 60, leftRectangle.width, leftRectangle.height - 75);

    refreshModList(false);

    enabledModItems.updateClipRects();
    disabledModItems.updateClipRects();

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
          trace('Back button pressed, confirming exit...');
          backPressStage = 2;
          playBackButtonAnimation('confirm', true);
        case 2:
          trace('Back button confirm finished, returning to main menu...');
          backPressStage = 3;
        default:
      }
    });

    buttonBackToMenu.zIndex = 10;
    add(buttonBackToMenu);

    carBattery = new FunkinSprite(rightRectangle.x + 475.6, FlxG.height * 0.11).loadSparrow('ui/mods/carbattery');
    carBattery.animation.addByPrefix('idle', 'idle', 24);
    carBattery.animation.play('idle');
    carBattery.animation.pause();
    carBattery.scale.set(0.75, 0.75);
    carBattery.updateHitbox();
    carBattery.zIndex = 20;
    carBattery.camera = camCharacters;
    add(carBattery);

    gfWire = new FunkinSprite(carBattery.x - 117, carBattery.y - 18).loadSparrow('ui/mods/gfwire');
    gfWire.animation.addByPrefix('idle', 'idle0', 24, false);
    gfWire.animation.addByPrefix('idle-emptychair', 'idle empty chair0', 24, false);
    gfWire.animation.addByPrefix('shock', 'shock', 24, false);
    gfWire.animation.play('idle');
    gfWire.scale.set(0.7, 0.7);
    gfWire.updateHitbox();
    gfWire.zIndex = carBattery.zIndex + 1;
    gfWire.camera = camCharacters;
    add(gfWire);

    bf = new ModMenuCharacter(carBattery.x - 119, carBattery.y + 50, 'bf');
    bf.camera = camCharacters;
    bf.animation.onFinish.add((name:String) ->
    {
      bfBlink = blinkTimer + Math.random() + (Math.random() * 5);
    });
    bfBlink = Math.random() + (Math.random() * 6);

    bf.zIndex = 30;
    add(bf);

    gf = new ModMenuCharacter(bf.x - 166, bf.y, 'gf', true);
    gf.camera = camCharacters;
    gf.animation.onFinish.add((name:String) ->
    {
      gfBlink = blinkTimer + Math.random() + (Math.random() * 9);
    });
    gfBlink = Math.random() + 6 + (Math.random() * 4);

    gf.zIndex = 25;
    add(gf);

    bgWires = new FunkinSprite(carBattery.x + 75, carBattery.y + 170).loadTexture('ui/mods/bgwires');
    bgWires.scale.set(0.7, 0.7);
    bgWires.updateHitbox();
    bgWires.zIndex = 10;
    bgWires.camera = camCharacters;
    add(bgWires);

    fgWires = new FunkinSprite(bf.x - 144, bf.y - 90).loadTextureAtlas('ui/mods/foreground-wires');
    fgWires.anim.addByFrameLabel('idle', 'idle', 24);
    fgWires.anim.addByFrameLabel('idle-pinhead', 'idle pinhead', 24);
    fgWires.anim.addByFrameLabel('shock', 'shock', 24);
    fgWires.anim.addByFrameLabel('end', 'end', 24, false);
    fgWires.animation.play('idle');
    fgWires.scale.set(0.7, 0.7);
    fgWires.updateHitbox();
    fgWires.zIndex = 35;
    fgWires.camera = camCharacters;
    add(fgWires);

    crispySmokeBF = new FunkinSprite(bf.x + 70, bf.y - 180).loadSparrow('ui/mods/smoke');
    crispySmokeBF.animation.addByPrefix('idle', 'retry_smoke', 24);
    crispySmokeBF.animation.play('idle', false, 13);
    crispySmokeBF.scale.set(0.5, 0.5);
    crispySmokeBF.updateHitbox();
    crispySmokeBF.camera = camCharacters;

    crispySmokeGF = new FunkinSprite(gf.x + 70, gf.y - 180).loadSparrow('ui/mods/smoke');
    crispySmokeGF.animation.addByPrefix('idle', 'retry_smoke', 24);
    crispySmokeGF.animation.play('idle');
    crispySmokeGF.scale.set(0.5, 0.5);
    crispySmokeGF.updateHitbox();
    crispySmokeGF.camera = camCharacters;

    crispySmokeBF.visible = false;
    crispySmokeGF.visible = false;

    crispySmokeBF.zIndex = bf.zIndex + 10;
    crispySmokeGF.zIndex = gf.zIndex + 10;

    crispySmokeBF.alpha = 0.67;
    crispySmokeGF.alpha = 0.67;

    add(crispySmokeBF);
    add(crispySmokeGF);

    smokeCloud = new FunkinSprite(carBattery.x - 415, -450).loadTextureAtlas('ui/mods/smoke-cloud', {
      useRenderTexture: true
    });
    smokeCloud.anim.addBySymbol('wholeTimeline', smokeCloud.getDefaultSymbol(), smokeCloud.library.frameRate, false);
    smokeCloud.visible = false;
    smokeCloud.scale.set(0.75, 0.75);
    smokeCloud.updateHitbox();
    smokeCloud.zIndex = 100;
    smokeCloud.camera = camCharacters;
    add(smokeCloud);

    sparks = new ModMenuSparks();
    sparks.x = FullScreenScaleMode.gameCutoutSize.x / 2.5;
    sparks.zIndex = smokeCloud.zIndex + 1;
    sparks.camera = camCharacters;
    add(sparks);

    buttonDone.x = carBattery.x - 100;
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

    openFolderAnimator = new PropertyAnimator(buttonOpenFolder);
    doneButtonAnimator = new PropertyAnimator(buttonDone);

    openFolderAnimator.addAnimationByName('select', 24);

    openFolderAnimator.addProperty('select', 'scale.x', [0.72]);
    openFolderAnimator.addProperty('select', 'scale.y', [0.72]);
    openFolderAnimator.addProperty('select', 'selected', [true]);
    openFolderAnimator.addProperty('select', 'invert', [false]);

    openFolderAnimator.addAnimationByName('deselect', 24);
    openFolderAnimator.addProperty('deselect', 'scale.x', [0.65]);
    openFolderAnimator.addProperty('deselect', 'scale.y', [0.65]);
    openFolderAnimator.addProperty('deselect', 'selected', [false]);
    openFolderAnimator.addProperty('deselect', 'invert', [false]);

    openFolderAnimator.addAnimationByName('accept', 24);
    openFolderAnimator.addProperty('accept', 'scale.x', [
      0.65 - 0.04,
      0.65 - 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65,
      0.65,
      0.65,
      0.65
    ]);
    openFolderAnimator.addProperty('accept', 'scale.y', [
      0.65 - 0.04,
      0.65 - 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65,
      0.65,
      0.65,
      0.65
    ]);
    openFolderAnimator.addProperty('accept', 'invert', [
      true,
      true,
      false,
      false,
      false,
      false,
      false,
      false,
      false
    ]);
    openFolderAnimator.addProperty('accept', 'selected', [
      false,
      false,
      true,
      true,
      true,
      false,
      false,
      false,
      false
    ]);

    doneButtonAnimator.addAnimationByName('select', 24);
    doneButtonAnimator.addProperty('select', 'scale.x', [0.72]);
    doneButtonAnimator.addProperty('select', 'scale.y', [0.72]);
    doneButtonAnimator.addProperty('select', 'selected', [true]);
    doneButtonAnimator.addProperty('select', 'invert', [false]);

    doneButtonAnimator.addAnimationByName('deselect', 24);
    doneButtonAnimator.addProperty('deselect', 'scale.x', [0.65]);
    doneButtonAnimator.addProperty('deselect', 'scale.y', [0.65]);
    doneButtonAnimator.addProperty('deselect', 'selected', [false]);
    doneButtonAnimator.addProperty('deselect', 'invert', [false]);

    doneButtonAnimator.addAnimationByName('accept', 24);
    doneButtonAnimator.addProperty('accept', 'scale.x', [
      0.65 - 0.04,
      0.65 - 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65,
      0.65,
      0.65,
      0.65
    ]);
    doneButtonAnimator.addProperty('accept', 'scale.y', [
      0.65 - 0.04,
      0.65 - 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65 + 0.04,
      0.65,
      0.65,
      0.65,
      0.65
    ]);
    doneButtonAnimator.addProperty('accept', 'invert', [
      true,
      true,
      false,
      false,
      false,
      false,
      false,
      false,
      false
    ]);
    doneButtonAnimator.addProperty('accept', 'selected', [
      false,
      false,
      true,
      true,
      true,
      false,
      false,
      false,
      false
    ]);

    darkness = new FunkinSprite();
    darkness.makeSolidColor(FlxG.width, FlxG.height, FlxColor.BLACK);
    darkness.scrollFactor.set(0, 0);
    darkness.alpha = 0;
    darkness.visible = false;
    darkness.zIndex = 3000;
    darkness.camera = camHUD;
    add(darkness);

    fileDrop = FunkinSprite.create(0, 0, 'ui/mods/drop-hover');
    fileDrop.setGraphicSize(FlxG.width * 0.95, FlxG.height * 0.9);
    fileDrop.scrollFactor.set(0, 0);
    fileDrop.updateHitbox();
    fileDrop.x = FlxG.width / 2 - (fileDrop.width / 2);
    fileDrop.y = FlxG.height / 2 - (fileDrop.height / 2);
    fileDrop.visible = false;
    fileDrop.zIndex = darkness.zIndex + 1;
    fileDrop.camera = camHUD;
    add(fileDrop);

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

    #if FEATURE_ONE_CLICK_INSTALL
    installPopup = new ModMenuInstallPopup();
    installPopup.zIndex = fileDrop.zIndex + 1;
    installPopup.setCamera(camHUD);
    add(installPopup);
    #end

    FlxG.autoPause = false;

    if (dropShadowUI != null)
    {
      dropShadowUI.renderer.blacklistSprite(menuBG);
      dropShadowUI.renderer.blacklistSprite(bgWires);
      dropShadowUI.renderer.blacklistSprite(crispySmokeBF);
      dropShadowUI.renderer.blacklistSprite(crispySmokeGF);
      dropShadowUI.renderer.blacklistSprite(sparks);
    }

    changeCharacters();

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

  function changeCharacters():Void
  {
    var modIds:Array<String> = grabEnabledModList();

    bf.prepareToSwitch('mod-bf', modIds);

    gf.previousModId = bf.previousModId;
    gf.prepareToSwitch('mod-gf', modIds);

    if (modIds.length > 1)
    {
      if (bf.isPinhead && !gf.isPinhead)
      {
        bf.currentCharacterId = 'empty-chair';
      }
      else if (!bf.isPinhead && gf.isPinhead)
      {
        gf.currentCharacterId = 'empty-chair';
      }
    }

    bf.switchCharacter();
    gf.switchCharacter();

    gfWire.visible = !gf.hasCustomWires;

    if (gf.currentCharacterId == 'empty-chair')
    {
      gfWire.zIndex = gf.zIndex + 1;
      gfWire.animation.play('idle-emptychair');
    }
    else
    {
      gfWire.zIndex = carBattery.zIndex + 1;
      gfWire.animation.play('idle');
    }

    if (bf.useSmallWire)
    {
      fgWires.animation.play('idle-pinhead');
    }
    else
    {
      fgWires.animation.play('idle');
    }

    this.refresh();
  }

  /**
   * Grabs the list of mod IDs that are currently enabled in the menu.
   */
  function grabEnabledModList():Array<String>
  {
    var modIds:Array<String> = [];

    for (item in enabledModItems.modItems)
    {
      if (item.mod != null) modIds.push(item.getModId());
    }
    modIds.push(BASE_GAME_MOD_ID);

    return modIds;
  }

  var fileDropTimer:Float = 0;
  var fileElapsed:Float = 0;
  var isHoveringFile:Bool = false;
  var animDone:Bool = false;

  function startFileDropHover():Void
  {
    isHoveringFile = true;
    trace('File drop hover start');
    fileDropTimer = 0.5;
    fileElapsed = 0;
    fileDrop.visible = true;
    darkness.visible = true;
    animDone = false;
    darkness.alpha = 0;
    fileDrop.alpha = 0;
  }

  function hideFileDropHover(x:Float, y:Float):Void
  {
    fileElapsed = 0;
    isHoveringFile = false;
    animDone = false;
    trace('File drop hover end');
    fileDropTimer = -0.08;
  }

  function rescanFolder():Void
  {
    if (exitingMenu || !allowInput || hasTransitions()) return;
    #if FEATURE_TOUCH_CONTROLS
    if (menuTouchId != -1) return;
    #end
    var newItems = PolymodHandler.getModFolderEntries();

    if (newItems.length != itemsInFolder.length || newItems.exists((entry) -> !itemsInFolder.contains(entry)))
    {
      trace("Mod folder changed, refreshing list.");
      refreshModList();
    }
  }


  /**
   * Moves an item into the unclipped transition layer at the given world coordinates, so it can be tweened independently of the lists.
   * @param item
   * @param worldX
   * @param worldY
   */
  function putItemInTransitionLayer(item:ModMenuItem, worldX:Float, worldY:Float):Void
  {
    if (item == null || transitionLayer == null) return;

    enabledModItems.remove(item);
    disabledModItems.remove(item);
    if (transitionLayer.children.contains(item)) transitionLayer.remove(item);

    item.clipRect = null;
    transitionLayer.add(item);
    item.cancelFlight();
    item.localX = worldX - transitionLayer.x;
    item.localY = worldY - transitionLayer.y;
  }

  /**
   * Immediately finishes placing an item into its destination list, bypassing any in-flight tween.
   * @param item
   * @param destinationList
   * @param index
   */
  function finishItemTransitionToList(item:ModMenuItem,
    destinationList:ModMenuItemList,
    index:Int):Void
  {
    if (item == null || destinationList == null || transitionLayer == null) return;

    var worldX:Float = transitionLayer.x + item.localX;
    var worldY:Float = transitionLayer.y + item.localY;

    transitionLayer.remove(item);

    var clamped:Int = index;
    if (clamped > destinationList.modItems.length) clamped = destinationList.modItems.length;
    if (clamped < 0) clamped = 0;
    destinationList.addModRawWithoutLayout(item, clamped);

    item.cancelFlight();
    item.localX = worldX - destinationList.x;
    item.localY = worldY - destinationList.y;

    if (incomingCount(destinationList) == 0)
    {
      destinationList.repositionItems();
    }
    else
    {
      destinationList.updateScrollbar();
    }
  }

  /**
   * Starts the manual flight that carries an item from the transition layer into its
   * destination list, tracking it via `pendingTransitions` so it can be force-settled
   * later if another swap interrupts it.
   */
  function startItemTransition(item:ModMenuItem,
    targetX:Float,
    targetY:Float,
    destinationList:ModMenuItemList,
    index:Int):Void
  {
    if (item == null) return;

    var record:TransitionRecord = {
      item: item,
      dest: destinationList,
      index: index
    };
    pendingTransitions.push(record);

    item.startFlight(targetX, targetY, 0.2, FlxEase.quadOut, () -> completeTransition(record));
  }

  /**
   * Land a single in-flight item in its destination list. Safe to call more than
   * once for the same record (subsequent calls are no-ops).
   */
  function completeTransition(record:TransitionRecord):Void
  {
    if (record == null) return;
    if (!pendingTransitions.contains(record)) return;
    pendingTransitions.remove(record);

    finishItemTransitionToList(record.item, record.dest, record.index);
  }

  /**
   * Immediately settle every in-flight item into its destination list.
   */
  function completeAllTransitions():Void
  {
    if (pendingTransitions.length == 0) return;
    for (record in pendingTransitions.copy())
    {
      record.item.finishFlight();
    }
  }

  /**
   * How many items are currently flying into `dest` (pending transitions whose destination
   * is that list).
   */
  function incomingCount(dest:ModMenuItemList):Int
  {
    var count:Int = 0;
    for (record in pendingTransitions)
    {
      if (record.dest == dest) count++;
    }
    return count;
  }


  public override function destroy():Void
  {
    super.destroy();

    #if FEATURE_ONE_CLICK_INSTALL
    installCancelled = true;
    pendingInstall = null;
    ModInstaller.cancelDownload();
    ModInstaller.cancelInstall();

    OneClickInstallHandler.clearQueue();
    #end

    FlxG.autoPause = Preferences.autoPause;
    FlxG.stage.window.onDropFile.remove(onDropFile);
    FlxG.stage.window.onDropBegin.remove(startFileDropHover);
    FlxG.stage.window.onDropComplete.remove(hideFileDropHover);

    ambience.destroy();

    instance = null;
  }

  public function onDropFile(path:String, state:String, x:Float, y:Float):Void
  {
    if (StringTools.endsWith(path, '.zip'))
    {
      var fileClean = StringTools.replace(path, '\\', '/');
      var fileName = StringTools.replace(path.substring(fileClean.lastIndexOf('/') + 1), '.zip', '');
      var destPath = PolymodHandler.MOD_FOLDER + '/' + fileName + '.zip';

      try
      {
        FileUtil.moveFile(path, destPath);
      }
      catch (e:Dynamic)
      {
        trace('Failed to move file: ' + e);
        WindowUtil.showError('Failed to move file', 'Could not move zip file to mods folder. Check logs for details.');
        return;
      }

      highlightNewMod();
    }
    else if (Path.isAbsolute(path) && FileUtil.directoryExists(path))
    {
      try
      {
        FileUtil.copyDirectory(path, Path.join([PolymodHandler.MOD_FOLDER, Path.withoutDirectory(path)]));
      }
      catch (e:Dynamic)
      {
        trace('Failed to move folder: ' + e);
        WindowUtil.showError('Failed to move folder', 'Could not move folder to mods folder. Check logs for details.');
        return;
      }

      highlightNewMod();
    }
    else
      WindowUtil.showWarning('Invalid file type', 'Only .zip files and mod folders are supported for mod installation.');
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
    if (installPopup == null) return;

    if (installPopup.isBlocking())
    {
      trace('Ignoring a one-click install, one is already in progress.');
      return;
    }

    pendingInstall = null;
    installCancelled = false;

    installPopup.showBusy('Mod Install', 'Looking this one up on GameBanana...');

    ModInstaller.fetchMetadata(request, function(mod:OneClickMod):Void
    {
      if (installCancelled) return;

      if (ModInstaller.isAlreadyInstalled(mod))
      {
        installPopup.showResult(mod.name, 'Already installed.');
        return;
      }

      pendingInstall = mod;

      startOneClickInstall();

      ModInstaller.downloadIcon(mod, function(bitmap:openfl.display.BitmapData):Void
      {
        if (installCancelled || installPopup == null) return;

        installPopup.setIcon(bitmap);
      });
    }, function(reason:String):Void
    {
      if (installCancelled) return;

      pendingInstall = null;
      installPopup.showResult('Mod Install Failed', reason);
    });
  }

  /**
   * Whether a one-click install is currently on screen.
   */
  public function isInstalling():Bool
  {
    return installPopup != null && installPopup.isBlocking();
  }

  /**
   * Tells the card how many more mods are lined up behind the one it's showing.
   */
  public function setInstallQueueCount(count:Int):Void
  {
    if (installPopup == null) return;

    installPopup.setQueueCount(count);
  }

  /**
   * Starts the download.
   */
  function startOneClickInstall():Void
  {
    final mod:Null<OneClickMod> = pendingInstall;
    if (mod == null) return;

    final credit:String = 'by ${mod.author}  (${formatFilesize(mod.filesize)})';

    installPopup.showProgress(mod.name, '${credit}\nDownloading...', 0);

    ModInstaller.download(mod, function(ratio:Float):Void
    {
      if (installCancelled) return;

      installPopup.showProgress(mod.name, '${credit}\nDownloading... ${Math.round(ratio * 100)}%', ratio);
    }, function(archivePath:String):Void
    {
      if (installCancelled) return;

      installPopup.showProgress(mod.name, '${credit}\nInstalling...', 0);

      ModInstaller.install(mod, archivePath, function(ratio:Float):Void
      {
        if (installCancelled) return;

        installPopup.showProgress(mod.name, '${credit}\nInstalling... ${Math.round(ratio * 100)}%', ratio);
      }, function(paths:Array<String>):Void
      {
        if (installCancelled) return;

        queueRequirements(mod);

        finishOneClickInstall(mod);
      }, function(reason:String):Void
      {
        if (installCancelled) return;

        installPopup.showResult(mod.name, 'Install failed.\n${reason}');
      });
    }, function(reason:String):Void
    {
      if (installCancelled) return;

      installPopup.showResult(mod.name, reason);
    });
  }

  /**
   * Handles input while the install overlay is up, and swallows everything else.
   */
  function handleInstallPopupInput():Void
  {
    switch (installPopup.state)
    {
      case Downloading:
        if (controls.BACK_P) cancelOneClickInstall();

      case Result:
        if (FlxG.keys.justPressed.ANY || controls.ACCEPT_P || controls.BACK_P #if FEATURE_TOUCH_CONTROLS || TouchUtil.justPressed #end)
        {
          installPopup.hide();
        }

      default:
    }
  }

  /**
   * Lines a mod's requirements up behind it, so they install the same way anything else does.
   *
   * @param mod The mod that was just installed.
   */
  function queueRequirements(mod:OneClickMod):Void
  {
    final requests:Array<OneClickRequest> = [];

    for (requirement in mod.requirements)
    {
      final request:Null<OneClickRequest> = ModInstaller.requestForRequirement(requirement);

      if (request == null) continue;

      requests.push(request);
    }

    OneClickInstallHandler.enqueueNext(requests);
  }

  /**
   * Refreshes the list and reports what landed.
   */
  function finishOneClickInstall(mod:OneClickMod):Void
  {
    highlightNewMod();

    installPopup.showResult(mod.name, 'Installed. Drag it over to turn it on.');
  }

  function cancelOneClickInstall():Void
  {
    installCancelled = true;
    pendingInstall = null;
    ModInstaller.cancelDownload();
    ModInstaller.cancelInstall();
    installPopup.hide();
  }

  /**
   * Renders a byte count the way a download dialog would.
   */
  function formatFilesize(bytes:Int):String
  {
    if (bytes <= 0) return '';

    if (bytes < 1024 * 1024) return '${Math.round(bytes / 1024)} KB';

    return '${Math.round(bytes / (1024 * 1024))} MB';
  }
  #end

  var secondCounter:Float = 0;
  var blinkTimer:Float = 0;
  var bfBlink:Float = 0;
  var gfBlink:Float = 0;
  var crispyTimer:Float = 0;
  var allowInput:Bool = true;
  var playedCrispySFX:Bool = false;
  var backTimer:Float = 0;

  /**
   * Tiempo sin aceptar entrada al abrir el menú (evita que el clic/tecla que lo abrió lo cierre).
   */
  var inputDelay:Float = 0.4;

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (inputDelay > 0) inputDelay -= elapsed;

    if (backPressStage == 3)
    {
      backTimer += elapsed;
      if (backTimer >= 0.35) backToMainMenu();
    }

    secondCounter += elapsed;
    if (secondCounter >= 0.5)
    {
      secondCounter = 0;
      rescanFolder();
    }

    if (!exitingMenu)
    {
      blinkTimer += elapsed;

      if (blinkTimer >= 100)
      {
        blinkTimer -= 100;
        bfBlink -= 100;
        gfBlink -= 100;
      }

      if (blinkTimer >= bfBlink && bf.animation.finished)
      {
        bfBlink = blinkTimer + Math.random() + (Math.random() * 6);
        bf.playAnimation(IDLE);
      }

      if (blinkTimer >= gfBlink && gf.animation.finished)
      {
        gfBlink = blinkTimer + Math.random() + (Math.random() * 8);
        gf.playAnimation(IDLE);
      }
    }

    handleInput(elapsed);

    if (!allowInput && !shockTimer.active)
    {
      crispyTimer += elapsed;

      if (bf.getCurrentAnimation() == CRISPY && gf.getCurrentAnimation() == CRISPY)
      {
        if (crispyTimer >= 0.7 && !playedCrispySFX)
        {
          playedCrispySFX = true;
          FunkinSound.playOnce(Paths.sound('ui/mods/sounds/crispy').toString());
        }
      }

      if (crispyTimer >= 0.3 && gf.animation.paused) gf.animation.resume();
      if (crispyTimer >= 2.5)
      {
        applyModlist();
      }
    }

    if (fadingItems.length > 0)
    {
      for (fade in fadingItems.copy())
      {
        fade.elapsed += elapsed;
        var t = Math.min(1, fade.elapsed / fade.duration);
        fade.item.localAlpha = FlxEase.quadOut(t);
        if (t >= 1) fadingItems.remove(fade);
      }
    }

    if (!animDone)
    {
      fileElapsed += elapsed;
      var t = fileElapsed / fileDropTimer;

      var adjustT = t;
      if (adjustT < 0) adjustT += 1;

      if (t > 1)
      {
        t = 1;
        animDone = true;
      }
      else if (t < -1)
      {
        t = -1;
        animDone = true;
      }
      fileDrop.alpha = FlxMath.lerp(0, 1, FlxEase.backOut(adjustT));
      darkness.alpha = FlxMath.lerp(0, 0.72, FlxEase.backOut(adjustT));
    }
  }

  function hasTransitions():Bool
  {
    return pendingTransitions.length > 0;
  }


  function handleInput(elapsed:Float):Void
  {
    #if FEATURE_ONE_CLICK_INSTALL
    if (installPopup != null && installPopup.isBlocking())
    {
      handleInstallPopupInput();
      return;
    }
    #end

    if (allowInput)
    {
      #if FEATURE_TOUCH_CONTROLS
      if (controls.BACK_P && !hasTransitions() && !exitingMenu)
      {
        pressBackButton();
        return;
      }
      if (!ControlsHandler.usingExternalInputDevice || ControlsHandler.lastInputTouch || menuTouchId != -1)
      {
        handleTouch(elapsed);

        return;
      }
      #end

      handleKeyboard();
    }
    else
    {
      if ((controls.ACCEPT_P #if FEATURE_TOUCH_CONTROLS || TouchUtil.justPressed #end) && shockTimer.active)
      {
        @:privateAccess
        shockTimer.onLoopFinished();
        shockTimer.active = false;
      }
    }
  }

  function handleMouse():Void
  {
    if (hasTransitions() || exitingMenu) return;

    if (FlxG.mouse.justPressed)
    {

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

  var holdDirection:Int = 0;
  var holdTimer:Float = 0;
  var doHoldAction:Bool = false;
  var delay:Float = 0;
  var acceptDelay:Float = 0;
  var oldSelection:ModMenuSelection;
  var lastInput:String = '';

  function playElectrocutionSequence():Void
  {
    bf.playAnimation(ELECTROCUTED, true);
    gf.playAnimation(ELECTROCUTED, true);

    carBattery.animation.resume();
    fgWires.animation.play('shock');

    gfWire.visible = true;
    gfWire.animation.play('shock');

    sparks.startElectrocution();

    var bgColor:FlxColor = menuBG.color;
    whiteColor.colorSet = true;

    if (dropShadowCharacters != null)
    {
      dropShadowCharacters.renderer.blacklistSprite(gfWire);
      dropShadowCharacters.renderer.blacklistSprite(carBattery);
      dropShadowCharacters.renderer.blacklistSprite(fgWires);
    }

    var blackFlash:FunkinSprite = new FunkinSprite(0, 0).makeSolidColor(FlxG.width, FlxG.height, 0xFF232327);
    blackFlash.zIndex = 0;
    blackFlash.camera = camCharacters;
    blackFlash.visible = false;
    add(blackFlash);
    refresh();

    shockTimer.start(81 / 24, (_) ->
    {
      bf.shader = whiteColor;
      gf.shader = whiteColor;

      blackFlash.visible = true;

      carBattery.visible = false;
      gfWire.visible = false;
      fgWires.visible = false;
      bgWires.visible = false;

      buttonDone.visible = false;
      buttonOpenFolder.visible = false;

      if (dropShadowCharacters != null)
      {
        dropShadowCharacters.visible = false;
        dropShadowCharacters.renderer.whitelistSprite(gfWire);
        dropShadowCharacters.renderer.whitelistSprite(carBattery);
        dropShadowCharacters.renderer.whitelistSprite(fgWires);
      }

      FlxTimer.wait(2 / 24, () ->
      {
        FlxG.camera.flash(0xFFFFFFFF, 1 / 24, () ->
        {
          blackFlash.destroy();
          remove(blackFlash);
        });

        changeCharacters();

        FlxTween.color(menuBG, 1, 0xFF232327, bgColor);

        buttonDone.visible = true;
        buttonOpenFolder.visible = true;

        carBattery.visible = true;
        carBattery.animation.reset();

        smokeCloud.visible = true;
        smokeCloud.animation.play('wholeTimeline');

        FunkinSound.playOnce(Paths.sound('ui/mods/sounds/smoke-cloud').toString());

        sparks.endElectrocution();

        fgWires.visible = true;
        bgWires.visible = true;
        if (dropShadowCharacters != null) dropShadowCharacters.visible = true;

        FlxTween.tween(smokeCloud, {
          alpha: 0
        }, 62 / 24, {
          ease: FlxEase.linear,
          framerate: 24
        });

        bf.applyShader();
        gf.applyShader();

        var showSmoke:Bool = false;

        if (bf.hasAnimation(CRISPY) && bf.previousModId == bf.currentModId)
        {
          showSmoke = true;
          bf.playAnimation(CRISPY, true);
        }
        else
        {
          bf.playAnimation(IDLE, true);
        }

        if (gf.hasAnimation(CRISPY) && gf.previousModId == gf.currentModId)
        {
          showSmoke = true;
          gf.playAnimation(CRISPY, true);
        }
        else
        {
          gf.playAnimation(IDLE, true);
          gf.animation.pause();
        }

        if (showSmoke)
        {
          crispySmokeBF.x += bf.smokeOffsets[0];
          crispySmokeBF.y += bf.smokeOffsets[1];
          crispySmokeBF.scale.set(bf.smokeScale[0], bf.smokeScale[1]);

          crispySmokeGF.x += gf.smokeOffsets[0];
          crispySmokeGF.y += gf.smokeOffsets[1];
          crispySmokeGF.scale.set(gf.smokeScale[0], gf.smokeScale[1]);

          crispySmokeBF.updateHitbox();
          crispySmokeGF.updateHitbox();

          crispySmokeBF.visible = bf.currentCharacterId != 'empty-chair';
          crispySmokeGF.visible = gf.currentCharacterId != 'empty-chair';

          fgWires.animation.play('end');
        }

        crispyTimer = 0;
      });
    });

    doneButtonAnimator.playAnimation('accept');
    allowInput = false;
  }

  function handleKeyboard():Void
  {
    if (hasTransitions() || exitingMenu || inputDelay > 0) return;

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
          if (pressingCtrl) orderMod(enabledModItems.selectedModItem, true);
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
          trace('lastSelectDir: ' + lastSelectDir);
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
          if (pressingCtrl) orderMod(enabledModItems.selectedModItem, false);
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
        holdTimer = 0.5;
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
            case 2:
          }
      }
    }
    if (delay > 0) delay -= FlxG.elapsed;

    if (controls.ACCEPT_P && !hasTransitions() && acceptDelay <= 0)
    {
      FunkinSound.playOnce(Paths.sound('ui/main-menu/scroll-menu'), 0.4);
      enabledModItems.repositionItems();
      disabledModItems.repositionItems();

      switch (selection)
      {
        case DisabledModList:
          enableMod(disabledModItems.selectedModItem);
        case EnabledModList:
          disableMod(enabledModItems.selectedModItem);
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
  var grabbedItem:Null<ModMenuItem>;
  var originalItemList:Null<ModMenuItemList>;
  var pressedModItem:Null<ModMenuItem>;
  var pressedMenuButton:Null<ModMenuSelection>;
  var menuTouchId:Int = -1;
  var menuTouchPoint:FlxPoint = new FlxPoint();
  var menuTouchStartX:Float = 0;
  var menuTouchStartY:Float = 0;
  var menuTouchLastY:Float = 0;
  var menuTouchAge:Float = 0;
  var menuTouchMoved:Bool = false;
  var touchScrolling:Bool = false;

  function menuButtonAtPoint():Null<ModMenuSelection>
  {
    if (hitboxOpenFolder.overlapsPoint(menuTouchPoint)) return OpenModsFolder;
    if (buttonDone.overlapsPoint(menuTouchPoint)) return Done;
    if (buttonBackToMenu.overlapsPoint(menuTouchPoint)) return BackToMenu;
    return null;
  }

  function modAtPoint(list:ModMenuItemList):Null<ModMenuItem>
  {
    final clip = list.clipRect;
    final top = list.y + (clip == null ? 60 : clip.y);
    final bottom = top + (clip == null ? list.viewportHeight : clip.height);
    if (menuTouchPoint.y < top || menuTouchPoint.y > bottom) return null;
    for (item in list.modItems)
    {
      if (!item.locked && item.overlapsPoint(menuTouchPoint)) return item;
    }
    return null;
  }

  function finishTouchDrag():Void
  {
    final item = grabbedItem;
    final sourceList = originalItemList;
    if (item == null || sourceList == null) return;
    var changed = false;
    if (sourceList == enabledModItems && leftRectangle.overlapsPoint(menuTouchPoint))
    {
      disableMod(item);
      changed = true;
    }
    else if (sourceList == disabledModItems && rightRectangle.overlapsPoint(menuTouchPoint))
    {
      changed = enableMod(item);
    }

    if (!changed)
    {
      final index = sourceList.modItems.indexOf(item);
      if (index >= 0)
      {
        startItemTransition(item, sourceList.x + ModMenuItemList.ITEM_X_OFFSET,
          sourceList.y + sourceList.getModItemYPos(index) + sourceList.scrollOffset, sourceList, index);
      }
    }
    grabbedItem = null;
  }

  function handleTouch(elapsed:Float):Void
  {
    if (exitingMenu) return;
    var touch:Null<flixel.input.touch.FlxTouch> = null;
    if (menuTouchId != -1)
    {
      for (candidate in FlxG.touches.list)
      {
        if (candidate.touchPointID == menuTouchId)
        {
          touch = candidate;
          break;
        }
      }
    }
    else if (!hasTransitions())
    {
      for (candidate in FlxG.touches.list)
      {
        if (candidate.justPressed)
        {
          touch = candidate;
          break;
        }
      }
      if (touch == null) return;

      menuTouchId = touch.touchPointID;
      touch.getWorldPosition(camOther, menuTouchPoint);
      menuTouchStartX = menuTouchPoint.x;
      menuTouchStartY = menuTouchLastY = menuTouchPoint.y;
      menuTouchAge = 0;
      menuTouchMoved = false;
      touchScrolling = false;
      pressedModItem = null;
      originalItemList = null;
      pressedMenuButton = menuButtonAtPoint();
      if (pressedMenuButton != null)
      {
        selection = pressedMenuButton;
        if (selection == BackToMenu) playBackButtonAnimation('press', true);
      }
      else
      {
        if (leftRectangle.overlapsPoint(menuTouchPoint)) originalItemList = disabledModItems;
        else if (rightRectangle.overlapsPoint(menuTouchPoint)) originalItemList = enabledModItems;
        if (originalItemList != null)
        {
          selection = originalItemList == enabledModItems ? EnabledModList : DisabledModList;
          pressedModItem = modAtPoint(originalItemList);
          if (pressedModItem != null) originalItemList.selectModItem(pressedModItem, false);
        }
      }
    }

    if (menuTouchId == -1) return;
    if (touch != null) touch.getWorldPosition(camOther, menuTouchPoint);
    final dx = menuTouchPoint.x - menuTouchStartX;
    final dy = menuTouchPoint.y - menuTouchStartY;
    final released = touch == null || !touch.pressed;
    menuTouchAge += elapsed;
    if (Math.abs(dx) > 8 || Math.abs(dy) > 8) menuTouchMoved = true;

    if (!released && pressedMenuButton == null && originalItemList != null)
    {
      if (grabbedItem == null && !touchScrolling)
      {
        if (Math.abs(dy) > 8 && Math.abs(dy) > Math.abs(dx))
        {
          touchScrolling = true;
        }
        else if (pressedModItem != null && (Math.abs(dx) > 8 || menuTouchAge >= 0.3))
        {
          grabbedItem = pressedModItem;
          grabbedItem.cancelFlight();
          putItemInTransitionLayer(grabbedItem, grabbedItem.x, grabbedItem.y);
        }
      }
      if (touchScrolling) originalItemList.scrollBy(menuTouchPoint.y - menuTouchLastY);
      if (grabbedItem != null)
      {
        grabbedItem.localX = menuTouchPoint.x - grabbedItem.width / 2 - transitionLayer.x;
        grabbedItem.localY = menuTouchPoint.y - grabbedItem.height / 2 - transitionLayer.y;
      }
    }
    menuTouchLastY = menuTouchPoint.y;

    if (!released) return;
    if (grabbedItem != null)
    {
      finishTouchDrag();
    }
    else if (!menuTouchMoved && !touchScrolling && touch != null)
    {
      if (pressedModItem != null && pressedModItem.overlapsPoint(menuTouchPoint))
      {
        if (originalItemList == enabledModItems) disableMod(pressedModItem);
        else enableMod(pressedModItem);
      }
      else if (pressedMenuButton != null && menuButtonAtPoint() == pressedMenuButton)
      {
        switch (pressedMenuButton)
        {
          case OpenModsFolder:
            openFolderAnimator.playAnimation('accept');
            openFolderAnimator.onFinish = openModsFolder;
          case Done:
            playElectrocutionSequence();
          case BackToMenu:
            backPressStage = 2;
            playBackButtonAnimation('confirm', true);
          default:
        }
      }
    }
    if (pressedMenuButton == BackToMenu && backPressStage == 0) playBackButtonAnimation('idle', true);
    menuTouchId = -1;
    pressedModItem = null;
    pressedMenuButton = null;
    originalItemList = null;
    touchScrolling = false;
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

  var tempDisabledMods:Array<ModMetadata> = [];
  var tempEnabledMods:Array<ModMetadata> = [];

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
    PolymodHandler.getAllMods(true);
    itemsInFolder = PolymodHandler.getModFolderEntries();

    tempDisabledMods = disabledModItems.modItems.map((item) -> item.mod);
    tempEnabledMods = enabledModItems.modItems.map((item) -> item.mod).filter((m) -> m != null && m.id != BASE_GAME_MOD_ID);

    var oldSelectedId:Null<String> = null;
    if (selection == DisabledModList && disabledModItems.selectedModItem != null) oldSelectedId = disabledModItems.selectedModItem.getModId();
    else if (selection == EnabledModList && enabledModItems.selectedModItem != null) oldSelectedId = enabledModItems.selectedModItem.getModId();

    newEnabledItems = [];
    var newDisabledItems = buildDisabledModList();
    buildEnabledModList();

    tempDisabledMods = [];
    tempEnabledMods = [];

    var usingTouch:Bool = false;

    #if FEATURE_TOUCH_CONTROLS
    if (!ControlsHandler.usingExternalInputDevice)
    {
      usingTouch = true;
    }
    #end

    if (!usingTouch)
    {
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

  function buildDisabledModList():Array<ModMenuItem>
  {
    var disabledMods:Array<ModMetadata> = PolymodHandler.getDisabledMods();
    var newModId:Array<String> = [];

    var liveIds:Array<String> = disabledMods.map((m) -> m.id).concat(PolymodHandler.getEnabledMods().map((m) -> m.id));

    if (tempDisabledMods.length > 0 || tempEnabledMods.length > 0)
    {
      var allKnownIds:Array<String> = tempDisabledMods.concat(tempEnabledMods).map((m) -> m.id);

      var reconciled:Array<ModMetadata> = tempDisabledMods.filter((m) -> liveIds.contains(m.id));

      for (mod in disabledMods)
      {
        if (!allKnownIds.contains(mod.id))
        {
          reconciled.push(mod);
          newModId.push(mod.id);
        }
      }

      for (mod in PolymodHandler.getEnabledMods())
      {
        if (mod.id == BASE_GAME_MOD_ID) continue;
        if (!allKnownIds.contains(mod.id))
        {
          reconciled.push(mod);
          newModId.push(mod.id);
        }
      }

      disabledMods = reconciled;
    }

    disabledModItems.title = 'DISABLED';
    disabledModItems.x = leftRectangle.x;
    disabledModItems.y = leftRectangle.y;

    var keepIds:Array<String> = disabledMods.map((m) -> m.id);
    for (item in disabledModItems.modItems.copy())
    {
      if (item.mod == null) continue;
      if (!keepIds.contains(item.getModId())) disabledModItems.removeMod(item);
    }

    var newItems:Array<ModMenuItem> = [];
    for (mod in disabledMods)
    {
      if (mod.id == BASE_GAME_MOD_ID) continue;
      if (disabledModItems.modItems.exists((it) -> it.getModId() == mod.id)) continue;

      var item = new ModMenuItem(mod);
      item.localAlpha = 0;
      disabledModItems.addModRawWithoutLayout(item, disabledModItems.modItems.length);
      newItems.push(item);
    }

    return newItems;
  }

  function buildEnabledModList():Void
  {
    var enabledMods:Array<ModMetadata> = PolymodHandler.getEnabledMods();

    var liveIds:Array<String> = enabledMods.map((m) -> m.id).concat(PolymodHandler.getDisabledMods().map((m) -> m.id));

    if (tempDisabledMods.length > 0 || tempEnabledMods.length > 0)
    {
      var allKnownIds:Array<String> = tempDisabledMods.concat(tempEnabledMods).map((m) -> m.id);
      var reconciled:Array<ModMetadata> = tempEnabledMods.filter((m) -> liveIds.contains(m.id));

      for (mod in enabledMods)
      {
        if (mod.id == BASE_GAME_MOD_ID) continue;
        if (!allKnownIds.contains(mod.id)) reconciled.push(mod);
      }

      enabledMods = reconciled;
    }

    enabledModItems.title = 'ENABLED';
    enabledModItems.x = rightRectangle.x;
    enabledModItems.y = rightRectangle.y;

    var keepIds:Array<String> = enabledMods.map((m) -> m.id);
    for (item in enabledModItems.modItems.copy())
    {
      if (item.getModId() == BASE_GAME_MOD_ID) continue;
      if (!keepIds.contains(item.getModId())) enabledModItems.removeMod(item);
    }

    for (mod in enabledMods)
    {
      if (mod.id == BASE_GAME_MOD_ID) continue;
      if (enabledModItems.modItems.exists((it) -> it.getModId() == mod.id)) continue;

      var item = new ModMenuItem(mod);
      item.localAlpha = 0;
      enabledModItems.addModRawWithoutLayout(item, enabledModItems.modItems.length);
      newEnabledItems.push(item);
    }

    if (!enabledModItems.modItems.exists((item) -> item.getModId() == BASE_GAME_MOD_ID))
    {
      var baseGameItem = new ModMenuItem(null, BASE_GAME_MOD_ICON_PATH, BASE_GAME_MOD_ID, 'Base Game', 'Default game content');
      baseGameItem.locked = true;
      enabledModItems.addModRawWithoutLayout(baseGameItem, 0);
    }
  }

  function applyModlist():Void
  {
    var backupSlot:Int = Save.system.archiveBadSaveData(FlxG.save.data);
    trace('[SAVE] Backed up current save data in case of emergency to $backupSlot!');

    var enabledModIds:Array<String> = [];
    for (modItem in enabledModItems.modItems)
    {
      var modId = modItem.getModId();
      if (modId == BASE_GAME_MOD_ID) continue;
      enabledModIds.push(modId);
    }

    PolymodHandler.disableAllMods();
    for (modId in enabledModIds)
    {
      PolymodHandler.enableMod(modId);
    }

    buttonDone.visible = false;
    buttonOpenFolder.visible = false;

    var blackScreen:FunkinSprite = new FunkinSprite().makeSolidColor(FlxG.width, FlxG.height, FlxColor.BLACK);
    blackScreen.scrollFactor.set(0, 0);
    blackScreen.camera = camHUD;
    blackScreen.zIndex = 1000;
    add(blackScreen);
    refresh();

    FlxTransitionableState.skipNextTransIn = true;
    PolymodHandler.forceReloadAssets();
    FlxG.switchState(() -> new MainMenuState());
  }

  function enableMod(item:Null<ModMenuItem>,
    ?forcedInsertIndex:Int = -1,
    ?batchFutureCount:Int = -1,
    shouldUpdateSelection:Bool = true):Bool
  {
    if (item == null) return false;
    if (!disabledModItems.modItems.contains(item)) return false;
    if (item.getModId() == BASE_GAME_MOD_ID) return false;

    item.selected = false;

    var dependenciesToEnable:Array<String> = checkDependencies(item.mod);
    trace('Dependencies to enable for ${item.getModTitle()}: ${dependenciesToEnable}');

    if (batchFutureCount == -1)
    {
      batchFutureCount = enabledModItems.modItems.length + countEnableBatch(item, []);
    }

    var originalInsertIndex:Int = forcedInsertIndex;

    if (originalInsertIndex == -1)
    {
      originalInsertIndex = enabledModItems.modItems.length;
      for (enabledMod in enabledModItems.modItems)
      {
        if (enabledMod.mod == null) continue;
        var optionalDependencies:ModDependencies = enabledMod.getOptionalDependencies();
        if (optionalDependencies != null)
        {
          var b:Bool = false;
          for (optionalDependencyId => version in optionalDependencies)
          {
            if (optionalDependencyId == item.getModId() && version.isSatisfiedBy(item.getModVersion()))
            {
              originalInsertIndex = enabledModItems.modItems.indexOf(enabledMod);
              b = true;
              break;
            }
          }
          if (b) break;
        }
      }
    }

    var nextInsertIndex = originalInsertIndex;
    for (dependencyId in dependenciesToEnable)
    {
      var dependencyItem = disabledModItems.modItems.find((it) -> it.getModId() == dependencyId);
      if (dependencyItem != null)
      {
        enableMod(dependencyItem, nextInsertIndex, batchFutureCount, false);
        nextInsertIndex++;
      }
      else
      {
        WindowUtil.showError(
          'Missing dependency',
          'Could not find dependency mod with ID: ' + dependencyId + '. Please make sure all required mods are installed.'
        );

        return false;
      }
    }

    var oldIndex:Int = disabledModItems.modItems.indexOf(item);
    var srcLocalX:Float = ModMenuItemList.ITEM_X_OFFSET;
    var srcLocalY:Float = disabledModItems.getModItemYPos(oldIndex) + disabledModItems.scrollOffset;
    var worldX:Float = disabledModItems.x + srcLocalX;
    var worldY:Float = disabledModItems.y + srcLocalY;
    disabledModItems.removeModWithoutLayout(item);
    disabledModItems.clampScrollToContent();

    var insertIndex:Int = originalInsertIndex;

    if (!transitionLayer.children.contains(item))
    {
      putItemInTransitionLayer(item, worldX, worldY);
    }

    var finalIndex:Int = insertIndex;
    for (record in pendingTransitions)
    {
      if (record.dest == enabledModItems && record.index <= finalIndex) finalIndex++;
    }

    var inFlight:Int = incomingCount(enabledModItems);

    enabledModItems.revealSlot(finalIndex, batchFutureCount);

    var targetX:Float = enabledModItems.x + ModMenuItemList.ITEM_X_OFFSET;
    var targetY:Float = enabledModItems.y + enabledModItems.getModItemYPosForCount(finalIndex, batchFutureCount) + enabledModItems.scrollOffset;

    enabledModItems.animateItemsToLayoutForInsertCount(finalIndex, inFlight + 1, 0.28, FlxEase.quartOut);
    disabledModItems.animateItemsToLayout(0.28, FlxEase.quartOut);
    startItemTransition(item, targetX, targetY, enabledModItems, finalIndex);

    if (!shouldUpdateSelection) return true;

    if (disabledModItems.modItems.length > 0)
    {
      var newIndex:Int = Std.int(Math.min(oldIndex, disabledModItems.modItems.length - 1));
      enabledModItems.deselectAll();
      disabledModItems.selectModItem(disabledModItems.modItems[newIndex], false);
      selection = DisabledModList;
    }
    else
    {
      disabledModItems.deselectAll();
      enabledModItems.selectModItem(item, false);
      selection = EnabledModList;
    }

    return true;
  }

  function disableMod(item:Null<ModMenuItem>,
    ?batchFutureCount:Int = -1,
    shouldUpdateSelection:Bool = true):Void
  {
    if (item == null) return;

    if (!enabledModItems.modItems.contains(item)) return;
    if (enabledModItems.isPinnedItem(item) || item.locked) return;

    item.selected = false;

    if (batchFutureCount == -1)
    {
      batchFutureCount = disabledModItems.modItems.length + countDisableBatch(item, []);
    }

    var brokenDependencies = validateDependencies(item.mod);
    trace('Broken dependencies for ${item.getModTitle()}: ${brokenDependencies}');
    for (dependencyTitle in brokenDependencies)
    {
      var dependencyItem = enabledModItems.modItems.find((it) -> it.getModTitle() == dependencyTitle);
      if (dependencyItem != null)
      {
        trace('Disabling ${dependencyItem.getModTitle()} since it depends on ${item.getModTitle()}');
        disableMod(dependencyItem, batchFutureCount, shouldUpdateSelection);
      }
    }

    var oldIndex:Int = enabledModItems.modItems.indexOf(item);
    var srcLocalX:Float = ModMenuItemList.ITEM_X_OFFSET;
    var srcLocalY:Float = enabledModItems.getModItemYPos(oldIndex) + enabledModItems.scrollOffset;
    var worldX:Float = enabledModItems.x + srcLocalX;
    var worldY:Float = enabledModItems.y + srcLocalY;
    enabledModItems.removeModWithoutLayout(item);
    enabledModItems.clampScrollToContent();

    if (!transitionLayer.children.contains(item))
    {
      putItemInTransitionLayer(item, worldX, worldY);
    }

    var destIndex:Int = disabledModItems.modItems.length;

    var finalIndex:Int = destIndex;
    for (record in pendingTransitions)
    {
      if (record.dest == disabledModItems && record.index <= finalIndex) finalIndex++;
    }

    var inFlight:Int = incomingCount(disabledModItems);

    disabledModItems.revealSlot(finalIndex, batchFutureCount);

    var targetX:Float = disabledModItems.x + ModMenuItemList.ITEM_X_OFFSET;
    var targetY:Float = disabledModItems.y + disabledModItems.getModItemYPosForCount(finalIndex, batchFutureCount) + disabledModItems.scrollOffset;

    disabledModItems.animateItemsToLayoutForInsertCount(finalIndex, inFlight + 1, 0.28, FlxEase.quartOut);
    enabledModItems.animateItemsToLayout(0.28, FlxEase.quartOut);
    startItemTransition(item, targetX, targetY, disabledModItems, finalIndex);

    if (!shouldUpdateSelection) return;

    disabledModItems.selectModItem(item, false);

    if (enabledModItems.modItems.length > 0)
    {
      var newIndex:Int = Std.int(Math.min(oldIndex, enabledModItems.modItems.length - 1));
      enabledModItems.selectModItem(enabledModItems.modItems[newIndex], false);
      selection = EnabledModList;
    }
    else
    {
      selection = DisabledModList;
    }
  }

  function nudgeBlocked(item:ModMenuItem, moveUp:Bool):Void
  {
    var index:Int = enabledModItems.modItems.indexOf(item);
    if (index < 0) return;

    var restY:Float = enabledModItems.getModItemYPos(index) + enabledModItems.scrollOffset;

    item.cancelFlight();
    item.localX = ModMenuItemList.ITEM_X_OFFSET;
    item.localY = restY;

    var dir:Float = moveUp ? -1 : 1;
    item.startFlight(ModMenuItemList.ITEM_X_OFFSET, restY + dir * 14, 0.07, FlxEase.quadOut, () ->
    {
      item.startFlight(ModMenuItemList.ITEM_X_OFFSET, restY, 0.12, FlxEase.quadOut);
    });
  }

  function orderMod(modItem:Null<ModMenuItem>, moveUp:Bool):Void
  {
    if (modItem == null) return;
    if (enabledModItems.isPinnedItem(modItem)) return;

    var modList:Array<ModMenuItem> = enabledModItems.modItems;
    var index = modList.indexOf(modItem);
    if (index == -1) return;

    var pinnedItem = enabledModItems.getPinnedTopItem();
    var pinnedIndex = pinnedItem != null ? modList.indexOf(pinnedItem) : -1;
    var minMovableIndex = pinnedIndex != -1 ? pinnedIndex + 1 : 0;

    if (index < minMovableIndex) return;
    if (minMovableIndex >= modList.length) return;

    var newIndex = moveUp ? index + 1 : index - 1;

    if (newIndex < minMovableIndex || newIndex >= modList.length)
    {
      nudgeBlocked(modItem, moveUp);
      return;
    }

    var otherModItem = modList[newIndex];

    var blocked:Bool = false;
    if (moveUp)
    {
      for (depId => version in otherModItem.getDependencies()) if (modItem.getModId() == depId)
      {
        blocked = true;
        break;
      }

      if (!blocked)
      {
        var myOpt = modItem.getOptionalDependencies();
        if (myOpt != null) for (depId => version in myOpt) if (otherModItem.getModId() == depId && version.isSatisfiedBy(otherModItem.getModVersion()))
        {
          blocked = true;
          break;
        }
      }
    }
    else
    {
      for (depId => version in modItem.getDependencies()) if (otherModItem.getModId() == depId)
      {
        blocked = true;
        break;
      }

      if (!blocked)
      {
        var otherOpt = otherModItem.getOptionalDependencies();
        if (otherOpt != null) for (depId => version in otherOpt) if (modItem.getModId() == depId && version.isSatisfiedBy(modItem.getModVersion()))
        {
          blocked = true;
          break;
        }
      }
    }

    if (blocked)
    {
      trace('Blocked reorder of ${modItem.getModTitle()} (dependency ordering)');
      nudgeBlocked(modItem, moveUp);
      return;
    }

    trace('Moving mod ${modItem.getModTitle()} from index $index to $newIndex');

    modList.splice(index, 1);
    modList.insert(newIndex, modItem);

    enabledModItems.deselectAll();
    enabledModItems.selectModItem(modItem);
    enabledModItems.animateItemsToLayout(0.28, FlxEase.quartOut);
  }


  function validateDependencies(mod:ModMetadata):Array<String>
  {
    var brokenDependencies:Array<String> = [];

    for (enabledModItem in enabledModItems.modItems)
    {
      var enabledMod = enabledModItem.mod;
      if (enabledMod == null) continue;

      var dependencies:ModDependencies = enabledMod.dependencies;
      for (dependencyId => version in dependencies)
      {
        if (dependencyId == mod.id) brokenDependencies.push(enabledMod.title);
      }
    }

    return brokenDependencies;
  }


  function checkDependencies(mod:ModMetadata):Array<String>
  {
    var toEnable:Array<String> = [];

    var dependencies:ModDependencies = mod.dependencies;
    for (dependencyId => version in dependencies)
    {
      if (
        !toEnable.contains(dependencyId)
        && !enabledModItems.modItems.exists((item) -> item.getModId() == dependencyId && version.isSatisfiedBy(item.getModVersion()))
      )
      {
        toEnable.push(dependencyId);
      }
    }

    return toEnable;
  }


  /**
   * Recursively counts how many mods would be enabled if we enable this mod, including itself and all dependencies.
   * @param item
   * @param seen
   * @return Int
   */
  function countEnableBatch(item:ModMenuItem, seen:Array<String>):Int
  {
    if (item == null) return 0;
    var id = item.getModId();
    if (seen.contains(id)) return 0;
    seen.push(id);

    var total:Int = 1;
    for (depId in checkDependencies(item.mod))
    {
      var depItem = disabledModItems.modItems.find((it) -> it.getModId() == depId);
      if (depItem != null) total += countEnableBatch(depItem, seen);
    }
    return total;
  }

  /**
   * Recursively counts how many mods would be disabled if we disable this mod, including itself and all dependents.
   * @param item
   * @param seen
   * @return Int
   */
  function countDisableBatch(item:ModMenuItem, seen:Array<String>):Int
  {
    if (item == null || item.mod == null) return 0;
    var id = item.getModId();
    if (seen.contains(id)) return 0;
    seen.push(id);

    var total:Int = 1;
    for (depTitle in validateDependencies(item.mod))
    {
      var depItem = enabledModItems.modItems.find((it) -> it.getModTitle() == depTitle);
      if (depItem != null) total += countDisableBatch(depItem, seen);
    }
    return total;
  }

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
    try
    {
      #if android
      DataFolderUtil.openDataFolder();
      #elseif ios
      System.openURL('shareddocuments://');
      #elseif sys
      final modsFolder:String = Path.isAbsolute(PolymodHandler.MOD_FOLDER) ? PolymodHandler.MOD_FOLDER : Path.join([
        FileUtil.gameDirectory,
        PolymodHandler.MOD_FOLDER
      ]);
      FileUtil.openFolder(modsFolder);
      #else
      FileUtil.openFolder(PolymodHandler.MOD_FOLDER);
      #end
    }
    catch (error:Dynamic)
    {
      trace('Could not open the mods folder: $error');
      FlxG.log.error('Could not open the mods folder: $error');
    }
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

/**
 * Typedef for tracking an item that's currently in-flight in the transition layer.
 */
typedef TransitionRecord =
{
  var item:ModMenuItem;
  var dest:ModMenuItemList;
  var index:Int;
}
