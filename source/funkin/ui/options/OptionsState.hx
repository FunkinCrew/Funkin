package funkin.ui.options;

import funkin.ui.Page.PageName;
import funkin.ui.TextMenuList;
import funkin.ui.TextMenuList.TextMenuItem;
import flixel.math.FlxPoint;
import funkin.ui.TextMenuList;
import funkin.ui.TextMenuList.TextMenuItem;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.util.FlxSignal;
import funkin.audio.FunkinSound;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.MusicBeatState;
import funkin.graphics.shaders.HSVShader;
import funkin.input.Controls;
#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.NewgroundsClient;
#end
#if FEATURE_TOUCH_CONTROLS
import funkin.util.TouchUtil;
import funkin.mobile.ui.FunkinBackButton;
import funkin.mobile.input.ControlsHandler;
import funkin.mobile.ui.options.ControlsSchemeMenu;
#end
#if FEATURE_MOBILE_IAP
import funkin.mobile.util.InAppPurchasesUtil;
#end
import flixel.util.FlxColor;
import funkin.assets.Assets;
import funkin.assets.Paths;
import funkin.ui.transition.Transition;

/**
 * The main options menu
 * It mainly is controlled via the "optionsCodex" object,
 * which handles paging and going to the different submenus
 */
class OptionsState extends MusicBeatState
{
  /**
   * Instance of the OptionsState
   */
  public static var instance:OptionsState;

  var optionsCodex:Codex<OptionsMenuPageName>;

  public var drumsBG:FunkinSound;

  public static var rememberedSelectedIndex:Int = 0;
  public static var backState:Null<String> = null;

  override function create():Void
  {
    instance = this;

    persistentUpdate = true;

    #if FEATURE_LAG_ADJUSTMENT
    drumsBG = FunkinSound.load(Paths.music('ui/input-offsets/drums-loop').audio().toFlxSoundAsset(), 0, true, false, false, false);
    #end

    var menuBG = new FlxSprite().loadGraphic(Paths.image('ui/main-menu/menu-bg').toFlxGraphicAsset());
    var hsv = new HSVShader(-0.6, 0.9, 3.6);
    menuBG.shader = hsv;
    menuBG.setGraphicSize(Std.int(FlxG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    optionsCodex = new Codex<OptionsMenuPageName>(Options);
    add(optionsCodex);

    var options:OptionsMenu = optionsCodex.addPage(Options, new OptionsMenu());
    var preferences:PreferencesMenu = optionsCodex.addPage(Preferences, new PreferencesMenu());
    var controls:ControlsMenu = optionsCodex.addPage(Controls, new ControlsMenu());
    #if FEATURE_LAG_ADJUSTMENT
    var offsets:OffsetMenu = optionsCodex.addPage(Offsets, new OffsetMenu());
    #end
    var saveData:SaveDataMenu = optionsCodex.addPage(SaveData, new SaveDataMenu());

    options.addSaveDataOptionsItem(saveData);
    options.addExitItem();

    if (options.hasMultipleOptions())
    {
      options.onExit.add(exitToMainMenu);
      controls.onExit.add(exitControls);
      preferences.onExit.add(optionsCodex.switchPage.bind(Options));
      #if FEATURE_LAG_ADJUSTMENT
      offsets.onExit.add(exitOffsets);
      #end
      saveData.onExit.add(optionsCodex.switchPage.bind(Options));
    }
    else
    {
      // No need to show Options page
      #if FEATURE_TOUCH_CONTROLS
      preferences.onExit.add(exitToMainMenu);
      optionsCodex.setPage(Preferences);
      #else
      controls.onExit.add(exitToMainMenu);
      optionsCodex.setPage(Controls);
      #end
    }

    super.create();
    #if FEATURE_TOUCH_CONTROLS
    addHitbox();
    hitbox.visible = false;
    #end
  }

  function exitOffsets():Void
  {
    if (drumsBG.volume > 0)
    {
      drumsBG.fadeOut(0.5, 0);
    }
    FlxG.sound.music.fadeOut(0.5, 0, function(tw)
    {
      FunkinSound.playMusic('ui/main-menu/freaky-menu/freaky-menu', {
        startingVolume: 0,
        overrideExisting: true,
        restartTrack: true,
        persist: true
      });
      FlxG.sound.music.fadeIn(0.5, 1);
    });
    optionsCodex.switchPage(Options);
  }

  function exitControls():Void
  {
    // Apply any changes to the controls.
    PlayerSettings.reset();
    PlayerSettings.init();

    optionsCodex.switchPage(Options);
  }

  function exitToMainMenu():Void
  {
    optionsCodex.currentPage.enabled = false;

    var goToState = function(state:flixel.util.typeLimit.NextState, ?assetQuery:(funkin.assets.Assets.AssetType) -> Array<funkin.assets.Paths.AssetPath>)
    {
      funkin.ui.transition.Transition.switchState(state, {
        transition: BlackScreen(Fade(North), Fade(South)),
        assetQuery: assetQuery ?? funkin.ui.transition.Transition.NO_ASSETS,
        shouldPurgeCache: false,
      });
    }

    var targetState:Null<String> = backState;
    backState = null;
    if (targetState != null)
    {
      funkin.ui.quickpanel.QuickPanelGroup.stopMusic();
      var isCompiled:Bool = funkin.modding.CppiaScripts.exists(targetState);
      var state:MusicBeatState = isCompiled ? cast funkin.modding.CppiaScripts.create(targetState) : MusicBeatState.scriptInit(targetState);
      var queryAssetsFunc = MusicBeatState.scriptStaticHasFunc(
        targetState,
        "queryAssets"
      ) ? (assetType) -> MusicBeatState.scriptStaticCall(targetState, "queryAssets", [assetType]) : null;
      if (state != null) goToState(() -> state, queryAssetsFunc);
      else
      {
        FlxG.keys.enabled = false;
        goToState(() -> new MainMenuState(), MainMenuState.queryAssets);
      }
    }
    else
    {
      FlxG.keys.enabled = false;
      goToState(() -> new MainMenuState(), MainMenuState.queryAssets);
    }
  }

  /**
   * Return a list of all AssetPaths that this state depends on to load.
   * @param type The type of AssetPath to return a list of paths for.
   * @param params The parameters to use when constructing the Options State.
   * @return The assets that the loading screen should cache.
   */
  public static function queryAssets(type:AssetType):Array<AssetPath>
  {
    var results:Array<AssetPath> = [];

    results.appendUnique(funkin.ui.options.items.CheckboxPreferenceItem.queryAssets(type));

    #if FEATURE_LAG_ADJUSTMENT
    results.appendUnique(OffsetMenu.queryAssets(type));
    #end

    switch (type)
    {
      case JSON:
        results.appendUnique([Paths.music('ui/main-menu/freaky-menu').metadata()]);

        #if FEATURE_LAG_ADJUSTMENT
        results.appendUnique([
          Paths.music('ui/input-offsets/offsets-loop').metadata(),
          Paths.music('ui/input-offsets/drums-loop').metadata()
        ]);
        #end

      case IMAGE:
        results.appendUnique([Paths.image('ui/main-menu/menu-bg')]);

      case SOUND:
        results.appendUnique([Paths.music('ui/main-menu/freaky-menu').audio()]);

        #if FEATURE_LAG_ADJUSTMENT
        results.appendUnique([
          Paths.music('ui/input-offsets/offsets-loop').audio(),
          Paths.music('ui/input-offsets/drums-loop').audio()
        ]);
        #end

      case SHADER:
        return [Paths.frag('ui/shaders/hsv')];

      default:
    }
    return results;
  }
}

/**
 * Our default Page when we enter the OptionsState, a bit of the root
 */
class OptionsMenu extends Page<OptionsMenuPageName>
{
  var items:TextMenuList;
  #if FEATURE_TOUCH_CONTROLS
  var backButton:FunkinBackButton;
  var goingBack:Bool = false;
  #end

  /**
   * Camera focus point
   */
  var camFocusPoint:FlxObject;

  final CAMERA_MARGIN:Int = 150;

  public function new()
  {
    super();
    add(items = new TextMenuList());

    createItem('PREFERENCES', function() codex.switchPage(Preferences));
    #if FEATURE_TOUCH_CONTROLS
    if (ControlsHandler.hasExternalInputDevice)
    #end
    createItem('CONTROLS', function() codex.switchPage(Controls));
    // createItem("CONTROL SCHEMES", function() {
    //   FlxG.state.openSubState(new ControlsSchemeMenu());
    // });
    #if FEATURE_LAG_ADJUSTMENT
    createItem('LAG ADJUSTMENT', function()
    {
      var switchToOffsets = function()
      {
        FunkinSound.playMusic('ui/input-offsets/offsets-loop/offsets-loop', {
          startingVolume: 0,
          overrideExisting: true,
          restartTrack: true,
          loop: true
        });
        OptionsState.instance.drumsBG.play(true);
        FlxG.sound.music.fadeIn(1, 1);
        codex.switchPage(Offsets);
      };

      if (FlxG.sound.music != null)
      {
        FlxG.sound.music.fadeOut(0.5, 0, function(tw)
        {
          switchToOffsets();
        });
      }
      else
      {
        switchToOffsets();
      }
    });
    #end
    #if FEATURE_MOBILE_IAP
    createItem('RESTORE PURCHASES', function()
    {
      InAppPurchasesUtil.restorePurchases();
    });
    #end
    #if (FEATURE_TOUCH_CONTROLS || web)
    createItem('OPEN MOD MENU', function()
    {
      funkin.ui.transition.Transition.switchState(() -> new funkin.ui.modmenu.ModMenuState(), {
        assetQuery: funkin.ui.modmenu.ModMenuState.queryAssets,
        transition: Throbber
      });
    });
    #end
    #if FEATURE_NEWGROUNDS
    if (NewgroundsClient.instance.isLoggedIn())
    {
      createItem('LOGOUT OF NG', function()
      {
        NewgroundsClient.instance.logout(function()
        {
          // Reset the options menu when logout succeeds.
          // This means the login option will be displayed.
          FlxG.resetState();
        }, function()
        {
          FlxG.log.warn('Newgrounds logout failed!');
        });
      });
    }
    else
    {
      createItem('LOGIN TO NG', function()
      {
        NewgroundsClient.instance.login(function()
        {
          // Reset the options menu when login succeeds.
          // This means the logout option will be displayed.
          // NOTE: If the user presses login and opens the browser,
          // then navigates the UI
          FlxG.resetState();
        }, function()
        {
          FlxG.log.warn('Newgrounds login failed!');
        });
      });
    }
    #end

    // Create an object for the camera to track.
    camFocusPoint = new FlxObject(0, 0, 140, 70);
    add(camFocusPoint);

    // Follow the camera focus as we scroll.
    FlxG.camera.follow(camFocusPoint, null, 0.085);
    FlxG.camera.deadzone.set(0, CAMERA_MARGIN / 2, FlxG.camera.width, FlxG.camera.height - CAMERA_MARGIN + 40);
    FlxG.camera.minScrollY = -CAMERA_MARGIN / 2;

    // Move the camera when the menu is scrolled.
    items.onChange.add(onMenuChange);

    onMenuChange(items.members[0]);

    items.selectItem(OptionsState.rememberedSelectedIndex);
    #if FEATURE_TOUCH_CONTROLS
    FlxG.touches.swipeThreshold.y = 100;
    #end
  }

  public function addSaveDataOptionsItem(saveDataMenu:SaveDataMenu):Void
  {
    // no need to show an entire new menu for just one option
    if (saveDataMenu.hasMultipleOptions())
    {
      createItem('SAVE DATA OPTIONS', function()
      {
        codex.switchPage(SaveData);
      });
    }
    else
    {
      createItem('CLEAR SAVE DATA', saveDataMenu.openSaveDataPrompt);
    }
  }

  public function addExitItem():Void
  {
    #if NO_FEATURE_TOUCH_CONTROLS
    createItem('EXIT', exit);
    #else
    backButton = new FunkinBackButton(FlxG.width - 230, FlxG.height - 200, exit, 1.0);
    backButton.onConfirmStart.add(function()
    {
      items.busy = true;
      goingBack = true;
      backButton.active = true;
    });
    add(backButton);
    #end
  }

  function onMenuChange(selected:TextMenuItem):Void
  {
    camFocusPoint.y = selected.y;
  }

  function createItem(name:String, callback:Void->Void, fireInstantly = false):TextMenuItem
  {
    var item = items.createItem(0, 100 + items.length * 100, name, BOLD, callback);
    item.fireInstantly = fireInstantly;
    item.screenCenter(X);
    return item;
  }

  override function update(elapsed:Float):Void
  {
    if ((FlxG.sound.music?.volume ?? 1.0) < 0.8)
    {
      FlxG.sound.music.volume += 0.5 * elapsed;
    }

    #if FEATURE_TOUCH_CONTROLS
    backButton.active = (!goingBack) ? !items.busy : true;
    #end
    super.update(elapsed);
  }

  override function set_enabled(value:Bool):Bool
  {
    items.enabled = value;
    return super.set_enabled(value);
  }

  /**
   * True if this page has multiple options, excluding the exit option.
   * If false, there's no reason to ever show this page.
   */
  public function hasMultipleOptions():Bool
  {
    return items.length > 2;
  }

  var prompt:Prompt;

  function promptClearSaveData():Void
  {
    if (prompt != null) return;
    prompt = new Prompt('This will delete
      /nALL your save data.
      /nAre you sure?
    ', Custom('Delete', 'Cancel'));
    prompt.create();
    prompt.createBgFromMargin(100, 0xFFFAFD6D);
    prompt.back.scrollFactor.set(0, 0);
    add(prompt);
    prompt.onYes = function()
    {
      // Clear the save data.
      funkin.save.Save.clearData();
      Transition.switchState(() -> new InitState(), {
        assetQuery: Transition.NO_ASSETS,
        transition: None
      });
    };
    prompt.onNo = function()
    {
      prompt.close();
      prompt.destroy();
      prompt = null;
    };
  }
}

enum abstract OptionsMenuPageName(String) to PageName
{
  public var Options = 'options';
  public var Controls = 'controls';
  public var Colors = 'colors';
  public var Mods = 'mods';
  public var Preferences = 'preferences';
  public var Offsets = 'offsets';
  public var SaveData = 'saveData';
}
