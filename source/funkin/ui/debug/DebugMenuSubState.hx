package funkin.ui.debug;

import flixel.math.FlxPoint;
import flixel.FlxObject;
import flixel.FlxSprite;
import funkin.ui.MusicBeatSubState;
import funkin.ui.FullScreenScaleMode;
import funkin.ui.mainmenu.MainMenuState;
import funkin.audio.FunkinSound;
import funkin.ui.TextMenuList;
import funkin.ui.debug.charting.ChartEditorState;
import funkin.util.logging.CrashHandler;
import flixel.addons.transition.FlxTransitionableState;
import funkin.util.FileUtil;
import funkin.ui.transition.Transition;

class DebugMenuSubState extends MusicBeatSubState
{
  var items:TextMenuList;

  /**
   * Camera focus point
   */
  var camFocusPoint:FlxObject;

  public static function queryAssets(type:funkin.assets.Assets.AssetType):Array<funkin.assets.Paths.AssetPath>
  {
    return funkin.ui.mainmenu.MainMenuState.queryAssets(type);
  }

  override function create():Void
  {
    transIn = null;
    transOut = null;
    FlxTransitionableState.skipNextTransIn = true;
    super.create();

    bgColor = 0x00000000;

    // Create an object for the camera to track.
    camFocusPoint = new FlxObject(0, 0);
    add(camFocusPoint);

    // Follow the camera focus as we scroll.
    FlxG.camera.follow(camFocusPoint, null, 0.06);

    // Create the green background.
    var menuBG = new FlxSprite().loadGraphic(Paths.image('ui/main-menu/menu-desat'));
    menuBG.color = 0xFF4CAF50;
    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1 * FullScreenScaleMode.wideScale.x));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    // Create the list for menu items.
    items = new TextMenuList();
    // Move the camera when the menu is scrolled.
    items.onChange.add(onMenuChange);
    add(items);

    FlxTransitionableState.skipNextTransIn = true;

    // Create each menu item.
    // Call onMenuChange when the first item is created to move the camera .
    #if FEATURE_CHART_EDITOR
    createItem("CHART EDITOR", openChartEditor);
    #end
    #if FEATURE_CAMERA_EDITOR
    createItem("CAMERA EDITOR", openCameraEditor);
    #end
    #if FEATURE_POLYMOD_MODS
    createItem("MOD MENU", openModMenu);
    #end
    #if FEATURE_ANIMATION_EDITOR
    createItem("ANIMATION EDITOR", openAnimationEditor);
    #end
    #if FEATURE_STAGE_EDITOR
    createItem("STAGE EDITOR", openStageEditor);
    #end
    #if FEATURE_RESULTS_DEBUG
    createItem("RESULTS SCREEN DEBUG", openTestResultsScreen);
    #end
    #if sys
    createItem("OPEN CRASH LOG FOLDER", openLogFolder);
    #end
    onMenuChange(items.members[0]);
    FlxG.camera.focusOn(new FlxPoint(camFocusPoint.x, camFocusPoint.y + 500));

    #if FEATURE_HAXEUI
    // Remove the "user" stylesheet to prevent components using incorrect style data when entering an editor.
    haxe.ui.Toolkit.styleSheet.clear("user");
    #end
  }

  function onMenuChange(selected:TextMenuItem)
  {
    camFocusPoint.setPosition(selected.x + selected.width / 2, selected.y + selected.height / 2);
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (controls.BACK_P)
    {
      FunkinSound.playOnce(Paths.sound('ui/main-menu/cancel-menu'));
      exitDebugMenu();
    }
  }

  function createItem(name:String, callback:Void->Void, fireInstantly = false):TextMenuItem
  {
    var item = items.createItem(0, 100 + items.length * 100, name, BOLD, callback);
    item.fireInstantly = fireInstantly;
    item.screenCenter(X);
    return item;
  }

  #if FEATURE_CHART_EDITOR
  function openChartEditor():Void
  {
    var chartEditorParams = {};

    Transition.switchState(() -> new ChartEditorState(chartEditorParams), {
      transition: Throbber,
      assetQuery: ChartEditorState.queryAssets.bind(_, chartEditorParams)
    });
  }
  #end

  function openCharSelect():Void
  {
    Transition.switchState(() -> new funkin.ui.charSelect.CharacterSelectState(), {
      transition: Throbber,
      assetQuery: funkin.ui.transition.Transition.NO_ASSETS
    });
  }

  #if FEATURE_ANIMATION_EDITOR
  function openAnimationEditor():Void
  {
    Transition.switchState(() -> new funkin.ui.debug.anim.DebugBoundingState(), {
      transition: Throbber,
      assetQuery: funkin.ui.transition.Transition.NO_ASSETS
    });
  }
  #end

  #if FEATURE_STAGE_EDITOR
  function openStageEditor():Void
  {
    Transition.switchState(() -> new funkin.ui.debug.stageeditor.StageEditorState(), {
      transition: Throbber,
      assetQuery: funkin.ui.transition.Transition.NO_ASSETS
    });
  }
  #end

  #if FEATURE_POLYMOD_MODS
  function openModMenu():Void
  {
    Transition.switchState(() -> new funkin.ui.modmenu.ModMenuState(), {
      assetQuery: funkin.ui.modmenu.ModMenuState.queryAssets,
      transition: Throbber
    });
  }
  #end

  #if FEATURE_CAMERA_EDITOR
  function openCameraEditor():Void
  {
    Transition.switchState(() -> new funkin.ui.debug.cameraeditor.CameraEditorState(), {
      transition: None,
      assetQuery: funkin.ui.transition.Transition.NO_ASSETS
    });
  }
  #end

  #if FEATURE_RESULTS_DEBUG
  function openTestResultsScreen():Void
  {
    Transition.switchState(() -> new funkin.ui.debug.results.ResultsDebugSubState(), {
      transition: None,
      assetQuery: funkin.ui.transition.Transition.NO_ASSETS
    });
  }
  #end

  #if sys
  function openLogFolder()
  {
    FileUtil.openFolder(CrashHandler.LOG_FOLDER);
  }
  #end

  function exitDebugMenu()
  {
    // TODO: Add a transition?
    this.close();
  }
}
