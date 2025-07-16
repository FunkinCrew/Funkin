package funkin.ui.options;

import funkin.ui.Page.PageName;
import funkin.ui.transition.LoadingState;
import funkin.ui.debug.latency.LatencyState;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import flixel.FlxObject;
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

/**
 * The main options menu
 * It mainly is controlled via the "optionsCodex" object,
 * which handles paging and going to the different submenus
 */
class OptionsState extends MusicBeatState
{
  var optionsCodex:Codex<OptionsMenuPageName>;

  public static var rememberedSelectedIndex:Int = 0;

  override function create():Void
  {
    persistentUpdate = true;

    var menuBG = new FlxSprite().loadGraphic(Paths.image('menuBG'));
    var hsv = new HSVShader(-0.6, 0.9, 3.6);
    menuBG.shader = hsv;
    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    optionsCodex = new Codex<OptionsMenuPageName>(Options);
    add(optionsCodex);

    var options:OptionsMenu = optionsCodex.addPage(Options, new OptionsMenu());
    var preferences:PreferencesMenu = optionsCodex.addPage(Preferences, new PreferencesMenu());
    var controls:ControlsMenu = optionsCodex.addPage(Controls, new ControlsMenu());

    if (options.hasMultipleOptions())
    {
      options.onExit.add(exitToMainMenu);
      controls.onExit.add(exitControls);
      preferences.onExit.add(optionsCodex.switchPage.bind(Options));
    }
    else
    {
      // No need to show Options page
      controls.onExit.add(exitToMainMenu);
      optionsCodex.setPage(Controls);
    }

    super.create();
  }

  function exitControls():Void
  {
    // Apply any changes to the controls.
    PlayerSettings.reset();
    PlayerSettings.init();

    optionsCodex.switchPage(Options);
  }

  function exitToMainMenu()
  {
    optionsCodex.currentPage.enabled = false;
    // TODO: Animate this transition?
    FlxG.switchState(() -> new MainMenuState());
  }
}

/**
 * Our default Page when we enter the OptionsState, a bit of the root
 */
class OptionsMenu extends Page<OptionsMenuPageName>
{
  var items:TextMenuList;

  /**
   * Camera focus point
   */
  var camFocusPoint:FlxObject;

  final CAMERA_MARGIN:Int = 150;

  public function new()
  {
    super();

    add(items = new TextMenuList());

    createItem("PREFERENCES", function() codex.switchPage(Preferences));
    createItem("CONTROLS", function() codex.switchPage(Controls));
    createItem("INPUT OFFSETS", function() {
      OptionsState.rememberedSelectedIndex = items.selectedIndex;
      #if web
      LoadingState.transitionToState(() -> new LatencyState());
      #else
      FlxG.state.openSubState(new LatencyState());
      #end
    });

    #if FEATURE_NEWGROUNDS
    if (NewgroundsClient.instance.isLoggedIn())
    {
      createItem("LOGOUT OF NG", function() {
        NewgroundsClient.instance.logout(function() {
          // Reset the options menu when logout succeeds.
          // This means the login option will be displayed.
          FlxG.resetState();
        }, function() {
          FlxG.log.warn("Newgrounds logout failed!");
        });
      });
    }
    else
    {
      createItem("LOGIN TO NG", function() {
        NewgroundsClient.instance.login(function() {
          // Reset the options menu when login succeeds.
          // This means the logout option will be displayed.

          // NOTE: If the user presses login and opens the browser,
          // then navigates the UI
          FlxG.resetState();
        }, function() {
          FlxG.log.warn("Newgrounds login failed!");
        });
      });
    }
    #end

    createItem("CLEAR SAVE DATA", function() {
      promptClearSaveData();
    });

    createItem("EXIT", exit);
    
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
  }

  function onMenuChange(selected:TextMenuList.TextMenuItem)
  {
    camFocusPoint.y = selected.y;
  }

  function createItem(name:String, callback:Void->Void, fireInstantly = false)
  {
    var item = items.createItem(0, 100 + items.length * 100, name, BOLD, callback);
    item.fireInstantly = fireInstantly;
    item.screenCenter(X);
    return item;
  }

  override function update(elapsed:Float)
  {
    enabled = (prompt == null);
    super.update(elapsed);
  }

  override function set_enabled(value:Bool)
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

    prompt = new Prompt("This will delete
      \nALL your save data.
      \nAre you sure?
    ", Custom("Delete", "Cancel"));
    prompt.create();
    prompt.createBgFromMargin(100, 0xFFFAFD6D);
    prompt.back.scrollFactor.set(0, 0);
    add(prompt);

    prompt.onYes = function() {
      // Clear the save data.
      funkin.save.Save.clearData();

      FlxG.switchState(() -> new funkin.InitState());
    }

    prompt.onNo = function() {
      prompt.close();
      prompt.destroy();
      prompt = null;
    }
  }
}

enum abstract OptionsMenuPageName(String) to PageName
{
  var Options = "options";
  var Controls = "controls";
  var Colors = "colors";
  var Mods = "mods";
  var Preferences = "preferences";
}
