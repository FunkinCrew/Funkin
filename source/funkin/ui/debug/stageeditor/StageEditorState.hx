package funkin.ui.debug.stageeditor;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.system.FlxAssets.FlxSoundAsset;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.Grayscale;
import funkin.input.Cursor;
import funkin.input.TurboButtonHandler;
import funkin.input.TurboKeyHandler;
import funkin.save.Save;
import funkin.ui.debug.stageeditor.components.StageEditorObject;
import funkin.ui.debug.stageeditor.commands.FlipObjectCommand;
import funkin.ui.debug.stageeditor.commands.DeselectObjectCommand;
import funkin.ui.debug.stageeditor.commands.MoveItemCommand;
import funkin.ui.debug.stageeditor.commands.RemoveObjectCommand;
import funkin.ui.debug.stageeditor.commands.SelectObjectCommand;
import funkin.ui.debug.stageeditor.commands.StageEditorCommand;
import funkin.ui.mainmenu.MainMenuState;
import funkin.play.character.BaseCharacter;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.data.stage.StageData;
import funkin.util.WindowUtil;
import funkin.util.FileUtil;
import haxe.io.Path;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.Slider;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Screen;
import haxe.ui.events.DragEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.focus.FocusManager;
import haxe.ui.Toolkit;
import openfl.display.BitmapData;

using StringTools;

/**
 * A state dedicated to allowing the user to create and edit stages.
 * Built with HaxeUI for use by both developers and modders.
 *
 * Some functionality is split into handler classes (just like in the Chart Editor) so that people would not go insane.
 *
 * @author KoloInDaCrib NEVER FORGET!!!
 * @author anysad (refactored code)
 */
// @:nullSafety // stupid haxe-ui having non-null safe macros

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/stage-editor/main-view.xml"))
class StageEditorState extends UIState
{
  /**
   * ==============================
   * CONSTANTS
   * ==============================
   */
  public static final STAGE_EDITOR_TOOLBOX_METADATA_LAYOUT:String = Paths.ui('stage-editor/toolboxes/stage-settings');

  public static final STAGE_EDITOR_TOOLBOX_OBJECT_PROPERTIES_LAYOUT:String = Paths.ui('stage-editor/toolboxes/object-properties');
  public static final STAGE_EDITOR_TOOLBOX_OBJECT_ANIMATIONS_LAYOUT:String = Paths.ui('stage-editor/toolboxes/object-anims');
  public static final STAGE_EDITOR_TOOLBOX_OBJECT_GRAPHIC_LAYOUT:String = Paths.ui('stage-editor/toolboxes/object-graphic');
  public static final STAGE_EDITOR_TOOLBOX_CHARACTER_PROPERTIES_LAYOUT:String = Paths.ui('stage-editor/toolboxes/character-properties');

  /**
   * The base grid size for the stage editor.
   */
  public static final GRID_SIZE:Int = 10;

  /**
   * Step value you can change the object position with.
   */
  public static final BASE_STEPS:Array<Int> = [1, 2, 3, 5, 10, 25, 50, 100];

  /**
   * The default object step value.
   */
  public static final BASE_STEP:Int = 1;

  /**
   * The index of thet default object step value in the `BASE_STEPS` array.
   */
  public static final BASE_STEP_INDEX:Int = 0;

  /**
   * Angle step value you can change the object angle with.
   */
  public static final BASE_ANGLES:Array<Float> = [0.5, 1, 2, 5, 10, 15, 45, 75, 90, 180];

  /**
   * The default object angle change value.
   */
  public static final BASE_ANGLE:Float = 15;

  /**
   * The index of thet default object angle change value in the `BASE_ANGLES` array.
   */
  public static final BASE_ANGLE_INDEX:Int = 5;

  /**
   * Default positions of characters when creating a blank new stage.
   */
  public static final DEFAULT_POSITIONS:Map<CharacterType, Array<Float>> = [
    CharacterType.BF => [989.5, 885],
    CharacterType.GF => [751.5, 787],
    CharacterType.DAD => [335, 885]
  ];

  /**
   * Default camera offsets of characters when previewing their camera in the testing state.
   */
  public static final DEFAULT_CAMERA_OFFSETS:Map<CharacterType, Array<Float>> = [
    CharacterType.BF => [-100, -100],
    CharacterType.GF => [0, 0],
    CharacterType.DAD => [150, -100]
  ];

  public static final MAX_Z_INDEX:Int = 10000;

  /**
   * Colors representing characters to differentiate camera bounds.
   * Cyan -> `Boyfriend/Player`
   * Red -> `Girlfriend/Spectator`
   * Purple -> `Dad/Opponent`
   */
  public static final CHARACTER_COLORS:Map<CharacterType, FlxColor> = [
    CharacterType.BF => FlxColor.CYAN,
    CharacterType.GF => FlxColor.RED,
    CharacterType.DAD => FlxColor.PURPLE
  ];

  /**
   * Time before the animation stops being previewed.
   */
  public static final TIME_BEFORE_ANIM_STOP:Float = 3.0;

  var CHARACTER_DESELECT_SHADER:Grayscale = new Grayscale();

  /**
   * ==============================
   * INSTANCE DATA
   * ==============================
   */
  /**
   * A timer used to auto-save the stage after a period of inactivity.
   */
  var autoSaveTimer:Null<FlxTimer> = null;

  /**
   * Whether or not the player is currently testing the stage at how it would look in-game.
   */
  var isInTestMode:Bool = false;

  /**
   * The current theme used by the editor.
   * Dictates the appearance of many UI elements.
   * Currently hardcoded to just Light and Dark.
   */
  var currentTheme(default, set):StageEditorTheme = StageEditorTheme.Light;

  function set_currentTheme(value:StageEditorTheme):StageEditorTheme
  {
    if (value == null || value == currentTheme) return currentTheme;

    currentTheme = value;
    this.updateTheme();
    return value;
  }

  public var selectedProp(default, set):Null<StageEditorObject> = null;

  function set_selectedProp(value:Null<StageEditorObject>):StageEditorObject
  {
    if (selectedProp != null) selectedProp.selectedShader.amount = 0;
    this.selectedProp = value;

    // update dialogs

    if (selectedProp != null) selectedProp.selectedShader.amount = 0.135;

    return selectedProp;
  }

  public var selectedCharacter(default, set):Null<BaseCharacter> = null;

  function set_selectedCharacter(value:Null<BaseCharacter>):BaseCharacter
  {
    if (selectedCharacter != null) selectedCharacter.shader = CHARACTER_DESELECT_SHADER;
    this.selectedCharacter = value;

    if (selectedCharacter != null) selectedCharacter.shader = null;
    // update dialog
    return selectedCharacter;
  }

  /**
   * The list of command previously performed. Used for undoing previous actions.
   */
  var undoHistory:Array<StageEditorCommand> = [];

  /**
   * The list of commands that have been undone. Used for redoing previous actions.
   */
  var redoHistory:Array<StageEditorCommand> = [];

  /**
   * The current move mode which detects which objects to move in the editor;
   * `StageEditorSelectionMode.OBJECTS` -> `Objects/Props`
   * `StageEditorSelectionMode.CHARACTERS` -> `Characters`
   */
  var currentSelectionMode:StageEditorSelectionMode = StageEditorSelectionMode.OBJECTS;

  /**
   * The internal index what what object step is in use.
   * Increment to make the object move more and decrement to make object move less.
   */
  var moveStepIndex:Int = BASE_STEP_INDEX;

  /**
   * The step at which an object or character is moved.
   * E.g., if `moveStep` is 5, pressing the arrow keys will move the object by 5 pixels.
   */
  var moveStep(get, never):Int;

  function get_moveStep():Int
  {
    return BASE_STEPS[moveStepIndex];
  }

  /**
   * The internal index what what object value change is in use.
   * Increment to make the object turn more and decrement to make object turn less.
   */
  var angleStepIndex:Int = BASE_ANGLE_INDEX;

  /**
   * The step at which an object or character is rotated.
   * E.g., if `angleStep` is 5, pressing the rotate buttons will rotate the object by 5 degrees.
   */
  var angleStep(get, never):Float;

  function get_angleStep():Float
  {
    return BASE_ANGLES[angleStepIndex];
  }

  /**
   * The name of the current selected item that is being displayed in the bottom bar.
   */
  var selectedItemName:String = 'None';

  /**
   * The item that is currently being dragged.
   */
  var dragTargetItem:Null<FlxSprite> = null;

  /**
   * The start position of the dragged item.
   */
  var dragStartPositions:Array<Float> = [];

  /**
   * The offset by how much the object has been moved.
   */
  var dragOffset:Array<Float> = [];

  /**
   * Whether or not the item has just been dragged.
   */
  var dragWasMoving:Bool = false;

  /**
   * ==============================
   * INPUT
   * ==============================
   */
  /**
   * Handler used to track how long the user has been holding the undo keybind.
   */
  var undoKeyHandler:TurboKeyHandler = TurboKeyHandler.build([FlxKey.CONTROL, FlxKey.Z]);

  /**
   * Variable used to track how long the user has been holding the redo keybind.
   */
  var redoKeyHandler:TurboKeyHandler = TurboKeyHandler.build([FlxKey.CONTROL, FlxKey.Y]);

  /**
   * ==============================
   * DIRTY FLAGS
   * ==============================
   */
  /**
   * Whether the stage has been modified since it was last saved.
   * Used to determine whether to auto-save, etc.
   */
  var saveDataDirty(default, set):Bool = false;

  function set_saveDataDirty(value:Bool):Bool
  {
    if (value == saveDataDirty) return value;

    if (value)
    {
      // Start the auto-save timer.
      // autoSaveTimer = new FlxTimer().start(Constants.AUTOSAVE_TIMER_DELAY_SEC, (_) -> autoSave());
    }
    else
    {
      if (autoSaveTimer != null)
      {
        // Stop the auto-save timer.
        autoSaveTimer.cancel();
        autoSaveTimer.destroy();
        autoSaveTimer = null;
      }
    }

    saveDataDirty = value;
    applyWindowTitle();
    return saveDataDirty;
  }

  var shouldShowBackupAvailableDialog(get, set):Bool;

  function get_shouldShowBackupAvailableDialog():Bool
  {
    return Save.instance.stageEditorHasBackup && StageEditorImportExportHandler.getLatestBackupPath() != null;
  }

  function set_shouldShowBackupAvailableDialog(value:Bool):Bool
  {
    return Save.instance.stageEditorHasBackup = value;
  }

  /**
   * A list of previous working file paths.
   * Also known as the "recent files" list.
   * The first element is [null] if the current working file has not been saved anywhere yet.
   */
  public var previousWorkingFilePaths(default, set):Array<Null<String>> = [null];

  function set_previousWorkingFilePaths(value:Array<Null<String>>):Array<Null<String>>
  {
    // Called only when the WHOLE LIST is overridden.
    previousWorkingFilePaths = value;
    applyWindowTitle();
    populateOpenRecentMenu();
    applyCanQuickSave();
    return value;
  }

  /**
   * The current file path which the stage editor is working with.
   * If `null`, the current stage has not been saved yet.
   */
  public var currentWorkingFilePath(get, set):Null<String>;

  function get_currentWorkingFilePath():Null<String>
  {
    return previousWorkingFilePaths[0];
  }

  function set_currentWorkingFilePath(value:Null<String>):Null<String>
  {
    if (value == previousWorkingFilePaths[0]) return value;

    if (previousWorkingFilePaths.contains(null))
    {
      // Filter all instances of `null` from the array.
      previousWorkingFilePaths = previousWorkingFilePaths.filter(function(x:Null<String>):Bool {
        return x != null;
      });
    }

    if (previousWorkingFilePaths.contains(value))
    {
      // Move the path to the front of the list.
      previousWorkingFilePaths.remove(value);
      previousWorkingFilePaths.unshift(value);
    }
    else
    {
      // Add the path to the front of the list.
      previousWorkingFilePaths.unshift(value);
    }

    while (previousWorkingFilePaths.length > Constants.MAX_PREVIOUS_WORKING_FILES)
    {
      // Remove the last path in the list.
      previousWorkingFilePaths.pop();
    }

    populateOpenRecentMenu();
    applyWindowTitle();

    return value;
  }

  /**
   * Whether the undo/redo histories have changed since the last time the UI was updated.
   */
  var commandHistoryDirty:Bool = true;

  /**
   * If true, we are currently in the process of quitting the stage editor.
   * Skip any update functions as most of them will call a crash.
   */
  var criticalFailure:Bool = false;

  /**
   * ==============================
   * HAXEUI
   * ==============================
   */
  /**
   * Whether the user is focused on an input in the Haxe UI, and inputs are being fed into it.
   * If the user clicks off the input, focus will leave.
   */
  var isHaxeUIFocused(get, never):Bool;

  function get_isHaxeUIFocused():Bool
  {
    return FocusManager.instance.focus != null;
  }

  /**
   * Whether the user's mouse cursor is hovering over a SOLID component of the HaxeUI.
   * If so, we can ignore certain mouse events underneath.
   */
  var isCursorOverHaxeUI(get, never):Bool;

  function get_isCursorOverHaxeUI():Bool
  {
    return Screen.instance.hasSolidComponentUnderPoint(Screen.instance.currentMouseX, Screen.instance.currentMouseY);
  }

  /**
   * The value of `isCursorOverHaxeUI` from the previous frame.
   * This is useful because we may have just clicked a menu item, causing the menu to disappear.
   */
  var wasCursorOverHaxeUI:Bool = false;

  /**
   * Set by StageEditorDialogHandler, used to prevent background interaction while a dialog is open.
   */
  var isHaxeUIDialogOpen:Bool = false;

  /**
   * The Dialog components representing the currently available tool windows.
   * Dialogs are retained here even when collapsed or hidden.
   */
  var activeToolboxes:Map<String, CollapsibleDialog> = new Map<String, CollapsibleDialog>();

  /**
   * ==============================
   * CAMERA RELATED ITEMS
   * ==============================
   */
  /**
   * The UI camera component we're using for this state to show UI components.
   */
  var uiCamera:FlxCamera;

  /**
   * The Stage camera component we're using for this state to show the stage itself.
   */
  var stageCamera:FlxCamera;

  /**
   * An empty FlxObject contained in the scene.
   * The current gameplay camera will always follow this object. Tween its position to move the camera smoothly.
   *
   * It needs to be an object in the scene for the camera to be configured to follow it.
   * We optionally make this a sprite so we can draw a debug graphic with it.
   */
  var cameraFollowPoint:FlxObject;

  /**
   * ==============================
   * HAXEUI COMPONENTS
   * ==============================
   */
  /**
   * The menubar at the top of the screen.
   */
  var menubar:MenuBar;

  /**
   * The `File -> New Stage` menu item.
   */
  var menubarItemNewStage:MenuItem;

  /**
   * The `File -> Open Stage` menu item.
   */
  var menubarItemOpenStage:MenuItem;

  /**
   * The `File -> Open Recent` menu.
   */
  var menubarItemOpenRecent:Menu;

  /**
   * The `File -> Save Stage` menu item.
   */
  var menubarItemSaveStage:MenuItem;

  /**
   * The `File -> Save Stage As` menu item.
   */
  var menubarItemSaveStageAs:MenuItem;

  /**
   * The `File -> Clear Assets` menu item.
   */
  var menubarItemClearAssets:MenuItem;

  /**
   * The `File -> Exit` menu item.
   */
  var menubarItemExit:MenuItem;

  /**
   * The `Edit -> Undo` menu item.
   */
  var menubarItemUndo:MenuItem;

  /**
   * The `Edit -> Redo` menu item.
   */
  var menubarItemRedo:MenuItem;

  /**
   * The `Edit -> New Object` menu item.
   */
  var menubarItemNewObj:MenuItem;

  /**
   * The `Edit -> Find Object` menu item.
   */
  var menubarItemFindObj:MenuItem;

  /**
   * The `Edit -> Copy Object` menu item.
   */
  var menubarItemCopy:MenuItem;

  /**
   * The `Edit -> Cut Object` menu item.
   */
  var menubarItemCut:MenuItem;

  /**
   * The `Edit -> Paste Object` menu item.
   */
  var menubarItemPaste:MenuItem;

  /**
   * The `Edit -> Delete Object` menu item.
   */
  var menubarItemDelete:MenuItem;

  /**
   * The `View -> View Characters` menu check box.
   */
  var menubarItemViewCharacters:MenuCheckBox;

  /**
   * The `View -> View Name Text` menu check box.
   */
  var menubarItemViewNameText:MenuCheckBox;

  /**
   * The `View -> View Floor Lines` menu check box.
   */
  var menubarItemViewFloorLines:MenuCheckBox;

  /**
   * The `View -> View Position Markers` menu check box.
   */
  var menubarItemViewPosMarkers:MenuCheckBox;

  /**
   * The `View -> View Camera Bounds` menu check box.
   */
  var menubarItemViewCamBounds:MenuCheckBox;

  /**
   * The `Test Stage` menubar button.
   */
  var menubarButtonText:Button;

  var menubarSpriteDependent(get, never):Array<MenuItem>;

  function get_menubarSpriteDependent():Array<MenuItem>
  {
    return [
      menubarItemCopy,
      menubarItemCut,
      menubarItemFlipX,
      menubarItemFlipY,
      menubarItemDelete
    ];
  }

  /**
   * ==============================
   * STAGE DATA
   * ==============================
   */
  /**
   * The data representing the current stage.
   */
  var stageData:Null<StageData> = new StageData();

  /**
   * The name of the current stage.
   */
  var currentStageName(get, set):String;

  function get_currentStageName():String
  {
    if (stageData.name == null) stageData.name = 'Unknown';
    return stageData.name;
  }

  function set_currentStageName(value:String):String
  {
    return stageData.name = value;
  }

  var currentStageId(get, set):String;

  function get_currentStageId():String
  {
    return currentStageName.toLowerCamelCase().sanitize();
  }

  function set_currentStageId(value:Null<String>):String
  {
    return value;
  }

  /**
   * The zoom level of the current stage.
   */
  var currentStageZoom(get, set):Float;

  function get_currentStageZoom():Float
  {
    if (stageData.cameraZoom == null) stageData.cameraZoom = 1.0;
    return stageData.cameraZoom;
  }

  function set_currentStageZoom(value:Float):Float
  {
    return stageData.cameraZoom = value;
  }

  /**
   * The directory where assets for the current stage are stored.
   * If `null`, defaults to `shared`.
   */
  var currentStageDirectory(get, set):String;

  function get_currentStageDirectory():String
  {
    if (stageData.directory == null) stageData.directory = 'shared';
    return stageData.directory;
  }

  function set_currentStageDirectory(value:String):String
  {
    return stageData.directory = value;
  }

  /**
   * The characters data in the current stage.
   */
  var currentCharacters(get, set):StageDataCharacters;

  function get_currentCharacters():StageDataCharacters
  {
    if (stageData.characters == null) stageData.characters = stageData.makeDefaultCharacters();
    return stageData.characters;
  }

  function set_currentCharacters(value:StageDataCharacters):StageDataCharacters
  {
    return stageData.characters = value;
  }

  /**
   * The list of props in the current stage.
   */
  var currentProps(get, set):Array<StageDataProp>;

  function get_currentProps():Array<StageDataProp>
  {
    if (stageData.props == null) stageData.props = [];
    return stageData.props;
  }

  function set_currentProps(value:Array<StageDataProp>):Array<StageDataProp>
  {
    return stageData.props = value;
  }

  /**
   * ==============================
   * RENDERED OBJECTS
   * ==============================
   */
  /**
   * A map of all loaded characters.
   */
  public var characters:Map<String, BaseCharacter> = new Map<String, BaseCharacter>();

  /**
   * A list of all props currently in the scene.
   * This is a separate list from `members` for easier management.
   */
  public var spriteArray:Array<StageEditorObject> = [];

  /**
   * A group of showing camera bounds for each character.
   */
  var cameraBounds:FlxTypedGroup<FlxSprite>;

  /**
   * A list of position markers for each character.
   */
  var characterPositionMarkers:Array<FlxShapeCircle> = [];

  /**
   * A list of floor lines for each character.
   */
  var characterFloorLines:Array<FlxSprite> = [];

  /**
   * Th text object used to display the name of the currently hovered/selected object.
   */
  var objectNameText:FlxText;

  /**
   * The IMAGE used for the grid. Updated by StageEditorThemeHandler.
   */
  var gridBitmap:Null<BitmapData> = null;

  /**
   * The tiled sprite used to display the grid.
   * The height is the length of the song, and scrolling is done by simply the sprite.
   */
  var gridTiledSprite:Null<FlxSprite> = null;

  /**
   * The params which were passed in when the Stage Editor was initialized.
   */
  var params:Null<StageEditorParams>;

  public function new(?params:StageEditorParams)
  {
    super();
    this.params = params;
  }

  override public function create():Void
  {
    super.create();
    if (FlxG.sound.music != null) FlxG.sound.music?.stop();

    // Show the mouse cursor.
    Cursor.show();

    loadPreferences();

    uiCamera = new FunkinCamera('stageEditorUI');
    stageCamera = new FlxCamera();

    cameraFollowPoint = new FlxObject(0, 0, 2, 3);
    cameraFollowPoint.screenCenter();

    initCameras();

    buildDefaultStageData();

    buildGrid();
    this.updateTheme();

    initCharacters();
    initVisuals();

    setupUIListeners();
    setupTurboKeyHandlers();

    stageCamera.follow(cameraFollowPoint, LOCKON, Constants.DEFAULT_CAMERA_FOLLOW_RATE * 4);

    refresh();

    if (params != null && params.fnfsTargetPath != null)
    {
      var result:Null<Array<String>> = this.loadFromFNFSPath(params.fnfsTargetPath);
      if (result != null)
      {
        if (result.length == 0)
        {
          this.success('Loaded Stage', 'Loaded stage (${params.fnfsTargetPath})');
        }
        else
        {
          this.warning('Loaded Stage', 'Loaded stage with issues (${params.fnfsTargetPath})\n${result.join("\n")}');
        }
      }
    }
    else if (params != null && params.targetStageId != null)
    {
      this.loadStageAsTemplate(params.targetStageId);
    }
    else
    {
      var welcomeDialog = this.openWelcomeDialog(false);
      // if (shouldShowBackupAvailableDialog) this.openBackupAvailableDialog(welcomeDialog);
    }
  }

  public function loadPreferences():Void
  {
    var save:Save = Save.instance;

    if (previousWorkingFilePaths[0] == null)
    {
      previousWorkingFilePaths = [null].concat(save.stageEditorPreviousFiles);
    }
    else
    {
      previousWorkingFilePaths = [currentWorkingFilePath].concat(save.stageEditorPreviousFiles);
    }

    moveStepIndex = BASE_STEPS.indexOf(Std.parseInt(StringTools.replace(save.stageEditorMoveStep, "px", "")));
    angleStepIndex = BASE_ANGLES.indexOf(save.stageEditorAngleStep);
    currentTheme = save.stageEditorTheme;
  }

  public function writePreferences(hasBackup:Bool):Void
  {
    var save:Save = Save.instance;

    var filteredWorkingFilePaths:Array<String> = [];
    for (path in previousWorkingFilePaths)
      if (path != null) filteredWorkingFilePaths.push(path);
    save.stageEditorPreviousFiles = filteredWorkingFilePaths;

    if (hasBackup) trace('Queuing backup prompt for next time!');
    save.stageEditorHasBackup = hasBackup;

    save.stageEditorMoveStep = '${moveStep}px';
    save.stageEditorAngleStep = angleStep;
    save.stageEditorTheme = currentTheme;
  }

  public function populateOpenRecentMenu():Void
  {
    if (menubarItemOpenRecent == null) return;

    #if sys
    menubarItemOpenRecent.removeAllComponents();

    for (stagePath in previousWorkingFilePaths)
    {
      if (stagePath == null) continue;

      var menuItemRecentStage:MenuItem = new MenuItem();
      menuItemRecentStage.text = stagePath;
      // menuItemRecentStage.onClick  add logic

      if (!FileUtil.fileExists(stagePath))
      {
        trace('Previously loaded stage file (${stagePath.toString()}) does not exist, disabling link...');
        menuItemRecentStage.disabled = true;
      }
      else
        menuItemRecentStage.disabled = false;

      menubarItemOpenRecent.addComponent(menuItemRecentStage);
    }
    #else
    menubarItemOpenRecent.hide();
    #end
  }

  function buildDefaultStageData():Void
  {
    stageData = new StageData();
  }

  /**
   * Initializes the HUD and Stage cameras.
   */
  function initCameras():Void
  {
    uiCamera.bgColor.alpha = 0;
    FlxG.cameras.reset(stageCamera);
    FlxG.cameras.add(uiCamera, false);
    FlxG.cameras.setDefaultDrawTarget(stageCamera, true);

    root.scrollFactor.set();
    root.cameras = [uiCamera];
    root.width = FlxG.width;
    root.height = FlxG.height;

    add(cameraFollowPoint);
  }

  /**
   * Builds and displays the stage editor grid.
   */
  function buildGrid():Void
  {
    gridTiledSprite = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, FlxG.width, FlxG.height, true);
    gridTiledSprite.scrollFactor.set();
    add(gridTiledSprite);
  }

  function initCharacters():Void
  {
    var girlfriend = CharacterDataParser.fetchCharacter(Save.instance.stageGirlfriendChar, true);
    if (girlfriend != null) addCharacter(girlfriend, CharacterType.GF);

    var dad = CharacterDataParser.fetchCharacter(Save.instance.stageDadChar, true);
    if (dad != null) addCharacter(dad, CharacterType.DAD);

    var boyfriend = CharacterDataParser.fetchCharacter(Save.instance.stageBoyfriendChar, true);
    if (boyfriend != null) addCharacter(boyfriend, CharacterType.BF);
  }

  function addCharacter(character:BaseCharacter, charType:CharacterType):Void
  {
    if (character == null) return;

    character.updateHitbox();

    switch (charType)
    {
      case BF:
        this.characters.set('bf', character);
        character.flipX = !character.getDataFlipX();
        character.name = 'bf';
      case GF:
        this.characters.set('gf', character);
        character.flipX = character.getDataFlipX();
        character.name = 'gf';
      case DAD:
        this.characters.set('dad', character);
        character.flipX = character.getDataFlipX();
        character.name = 'dad';
      default:
        this.characters.set(character.characterId, character);
    }

    character.x = DEFAULT_POSITIONS[charType][0] - character.characterOrigin.x + character.globalOffsets[0];
    character.y = DEFAULT_POSITIONS[charType][1] - character.characterOrigin.y + character.globalOffsets[1];

    // Set the characters type
    character.characterType = charType;

    add(character);
  }

  function initVisuals():Void
  {
    cameraBounds = new FlxTypedGroup<FlxSprite>();
    cameraBounds.visible = false;
    cameraBounds.zIndex = MAX_Z_INDEX + CHARACTER_COLORS.size() + 1;

    for (type => color in CHARACTER_COLORS)
    {
      var i = CHARACTER_COLORS.keyValues().indexOf(type);
      var floorLine = new FlxSprite().makeGraphic(FlxG.width * 10, 15, color);
      floorLine.screenCenter(X);

      var positionMarker = new FlxShapeCircle(0, 0, 30, cast {thickness: 2, color: color}, color);

      var cameraBound = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, color);

      positionMarker.alpha = floorLine.alpha = cameraBound.alpha = 0.35;
      positionMarker.ID = floorLine.ID = cameraBound.ID = i;
      positionMarker.visible = floorLine.visible = false;
      positionMarker.zIndex = floorLine.zIndex = MAX_Z_INDEX + 1 + i;

      add(floorLine);
      add(positionMarker);

      characterFloorLines.push(floorLine);
      characterPositionMarkers.push(positionMarker);

      cameraBounds.add(cameraBound);

      add(cameraBounds);
    }

    objectNameText = new FlxText(0, 0, 0, "", 24);
    objectNameText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    objectNameText.cameras = [uiCamera];
    add(objectNameText);
  }

  /**
   * ==============================
   * UPDATE FUNCTIONS
   * ==============================
   */
  function autoSave():Void
  {
    var needsAutoSave:Bool = saveDataDirty;

    saveDataDirty = false;

    // Auto-save preferences.
    writePreferences(needsAutoSave);

    // Auto-save the stage.
    #if html5
    // Auto-save to local storage.
    // TODO: Implement this.
    #else
    // Auto-save to temp file.
    if (needsAutoSave)
    {
      // this.exportAllStageData(true, null);
      var absoluteBackupsPath:String = Path.join([Sys.getCwd(), StageEditorImportExportHandler.BACKUPS_PATH]);
      this.infoWithActions('Auto-Save', 'Stage auto-saved to ${absoluteBackupsPath}.', [
        {
          text: "Take Me There",
          callback: openBackupsFolder,
        }
      ]);
    }
    #end
  }

  /**
   * Open the backups folder in the file explorer.
   * Don't call this on HTML5.
   */
  function openBackupsFolder(?_):Bool
  {
    #if sys
    // TODO: Is there a way to open a folder and highlight a file in it?
    var absoluteBackupsPath:String = Path.join([Sys.getCwd(), StageEditorImportExportHandler.BACKUPS_PATH]);
    FileUtil.openFolder(absoluteBackupsPath);
    return true;
    #else
    trace('No file system access, cannot open backups folder.');
    return false;
    #end
  }

  public override function update(elapsed:Float):Void
  {
    // Override F4 behavior to include the autosave.
    if (FlxG.keys.justPressed.F4 && !criticalFailure)
    {
      quitStageEditor();
      return;
    }

    super.update(elapsed);

    if (criticalFailure) return;

    objectNameText.text = '';

    handleMenubar();
    handleBottomBar();

    handleMouse();
    handleFileKeybinds();
    if (!(isHaxeUIFocused || isCursorOverHaxeUI))
    {
      handleEditKeybinds();
    }
  }

  function setupUIListeners():Void
  {
    /**
     * FILE
     */
    menubarItemNewStage.onClick = _ -> this.openWelcomeDialog(true);

    /**
     * EDIT
     */
    menubarItemUndo.onClick = _ -> undoLastCommand();
    menubarItemRedo.onClick = _ -> redoLastCommand();
    menubarItemNewObj.onClick = _ -> this.openNewObjectDialog();
    menubarItemFlipX.onClick = _ -> performCommand(new FlipObjectCommand(selectedProp, true));
    menubarItemFlipY.onClick = _ -> performCommand(new FlipObjectCommand(selectedProp, false));
    menubarItemDelete.onClick = _ -> performCommand(new RemoveObjectCommand(selectedProp));

    /**
     * VIEW
     */
    menubarItemThemeLight.onChange = function(event:UIEvent) {
      if (event.target.value) currentTheme = StageEditorTheme.Light;
    };
    menubarItemThemeLight.selected = currentTheme == StageEditorTheme.Light;

    menubarItemThemeDark.onChange = function(event:UIEvent) {
      if (event.target.value) currentTheme = StageEditorTheme.Dark;
    };
    menubarItemThemeDark.selected = currentTheme == StageEditorTheme.Dark;

    menubarItemViewCharacters.onChange = _ -> {
      for (charType => character in characters)
        character.visible = menubarItemViewCharacters.selected;
    }

    menubarItemViewNameText.onChange = _ -> objectNameText.visible = menubarItemViewNameText.selected;

    /**
     * WINDOWS
     */
    menubarItemWindowStage.onChange = event -> this.setToolboxState(STAGE_EDITOR_TOOLBOX_METADATA_LAYOUT, event.value);

    /**
     * HELP
     */
    menubarItemAbout.onClick = _ -> this.openAboutDialog();

    /**
     * BOTTOM BAR
     */
    bottomBarModeText.onClick = _ -> {
      // This is by far the worst code that I have ever written.
      switch (currentSelectionMode)
      {
        case NONE:
          currentSelectionMode = OBJECTS;
        case OBJECTS:
          if (selectedProp != null) selectedProp = null;
          currentSelectionMode = CHARACTERS;
          for (charType => character in characters)
            if (character != null) character.shader = CHARACTER_DESELECT_SHADER;
        case CHARACTERS:
          currentSelectionMode = NONE;
          if (selectedCharacter != null) selectedCharacter = null;
          for (charType => character in characters)
            if (character != null) character.shader = null;
        default:
          currentSelectionMode = NONE;
      }
    }

    bottomBarSelectText.onClick = _ -> {
      if (isInTestMode)
      {

      }
      else
      {
        switch (currentSelectionMode)
        {
          case StageEditorSelectionMode.OBJECTS:
            if (selectedProp == null) return;

            var index = spriteArray.indexOf(selectedProp) + 1;
            if (index >= spriteArray.length) index = 0;

            var prop = spriteArray[index];
            if (prop == null) index++;

            selectedProp = prop;
            selectedItemName = prop.name;
          case StageEditorSelectionMode.CHARACTERS:
            var charList = [for (c in characters) c];
            var index = charList.indexOf(selectedCharacter) + 1;
            if (index >= charList.length) index = 0;

            var character:Null<BaseCharacter> = charList[index];
            if (character == null) return;

            selectedCharacter = character;
            selectedItemName = Std.string(character.characterType);
          default:
            // nothing
        }
      }
    }

    bottomBarMoveStepText.onClick = _ -> {
      if (FlxG.keys.pressed.SHIFT)
      {
        moveStepIndex = BASE_STEP_INDEX;
      }
      else
      {
        moveStepIndex++;
        if (moveStepIndex >= BASE_STEPS.length) moveStepIndex = 0;
      }
    }
    bottomBarMoveStepText.onRightClick = _ -> {
      moveStepIndex--;
      if (moveStepIndex < 0) moveStepIndex = BASE_STEPS.length - 1;
    }
    bottomBarAngleStepText.onClick = _ -> {
      if (FlxG.keys.pressed.SHIFT)
      {
        angleStepIndex = BASE_ANGLE_INDEX;
      }
      else
      {
        angleStepIndex++;
        if (angleStepIndex >= BASE_ANGLES.length) angleStepIndex = 0;
      }
    }
    bottomBarAngleStepText.onRightClick = _ -> {
      angleStepIndex--;
      if (angleStepIndex < 0) angleStepIndex = BASE_ANGLES.length - 1;
    }
  }

  /**
   * Initialize TurboKeyHandlers and add them to the state (so `update()` is called)
   * We can then probe `keyHandler.activated` to see if the key combo's action should be taken.
   */
  function setupTurboKeyHandlers():Void
  {
    // Keyboard shortcuts
    add(undoKeyHandler);
    add(redoKeyHandler);
  }

  /**
   * ==============================
   * COMMAND FUNCTIONS
   * ==============================
   */
  /**
   * Perform (or redo) a command, then add it to the undo stack.
   *
   * @param command The command to perform.
   * @param purgeRedoStack If `true`, the redo stack will be cleared after performing the command.
   */
  function performCommand(command:StageEditorCommand, purgeRedoStack:Bool = true):Void
  {
    command.execute(this);
    if (command.shouldAddToHistory(this))
    {
      undoHistory.push(command);
      commandHistoryDirty = true;
    }
    if (purgeRedoStack) redoHistory = [];
  }

  /**
   * Undo a command, then add it to the redo stack.
   * @param command The command to undo.
   */
  function undoCommand(command:StageEditorCommand):Void
  {
    command.undo(this);
    // Note, if we are undoing a command, it should already be in the history,
    // therefore we don't need to check `shouldAddToHistory(state)`
    redoHistory.push(command);
    commandHistoryDirty = true;
  }

  /**
   * Undo the last command in the undo stack, then add it to the redo stack.
   */
  function undoLastCommand():Void
  {
    var command:Null<StageEditorCommand> = undoHistory.pop();
    if (command == null)
    {
      trace('No actions to undo.');
      return;
    }
    undoCommand(command);
  }

  /**
   * Redo the last command in the redo stack, then add it to the undo stack.
   */
  function redoLastCommand():Void
  {
    var command:Null<StageEditorCommand> = redoHistory.pop();
    if (command == null)
    {
      trace('No actions to redo.');
      return;
    }
    performCommand(command, false);
  }

  /**
   * ==============================
   * STATIC FUNCTIONS
   * ==============================
   */
  /**
   * Handles passive behavior of the menu bar, such as updating labels or enabled/disabled status.
   * Does not handle onClick ACTIONS of the menubar.
   */
  function handleMenubar():Void
  {
    for (item in menubarSpriteDependent)
      item.disabled = (selectedProp == null || currentSelectionMode != OBJECTS);

    if (commandHistoryDirty)
    {
      commandHistoryDirty = false;

      // Update the Undo and Redo buttons.
      if (undoHistory.length == 0)
      {
        // Disable the Undo button.
        menubarItemUndo.disabled = true;
        menubarItemUndo.text = 'Undo';
      }
      else
      {
        // Change the label to the last command.
        menubarItemUndo.disabled = false;
        menubarItemUndo.text = 'Undo ${undoHistory[undoHistory.length - 1].toString()}';
      }

      if (redoHistory.length == 0)
      {
        // Disable the Redo button.
        menubarItemRedo.disabled = true;
        menubarItemRedo.text = 'Redo';
      }
      else
      {
        // Change the label to the last command.
        menubarItemRedo.disabled = false;
        menubarItemRedo.text = 'Redo ${redoHistory[redoHistory.length - 1].toString()}';
      }
    }
  }

  function handleBottomBar():Void
  {
    bottomBarModeText.text = currentSelectionMode.toTitleCase();
    if ((selectedProp == null && currentSelectionMode == OBJECTS)
      || (selectedCharacter == null && currentSelectionMode == CHARACTERS)
      || currentSelectionMode == NONE) selectedItemName = "None";
    bottomBarSelectText.text = selectedItemName;
    bottomBarMoveStepText.text = '${moveStep}px';
    bottomBarAngleStepText.text = '${angleStep}°';
  }

  /**
   * Small helper for MacOS, "WINDOWS" is keycode 15, which maps to "COMMAND" on Mac, which is more often used than "CONTROL"
   * Everywhere else, it just returns `FlxG.keys.pressed.CONTROL`
   * @return Bool
   */
  function pressingControl():Bool
  {
    #if mac
    return FlxG.keys.pressed.WINDOWS;
    #else
    return FlxG.keys.pressed.CONTROL;
    #end
  }

  /**
   * Handles the display and the functionality of the mouse.
   */
  function handleMouse():Void
  {
    // Mouse sounds
    if (FlxG.mouse.justPressed) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickDown"));
    if (FlxG.mouse.justReleased) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickUp"));

    objectNameText.x = FlxG.mouse.getViewPosition(uiCamera).x;
    objectNameText.y = FlxG.mouse.getViewPosition(uiCamera).y - objectNameText.height;

    var shouldHandleCursor:Bool = !isHaxeUIFocused && !isHaxeUIDialogOpen && !isCursorOverHaxeUI;

    if (shouldHandleCursor)
    {
      var targetCursorMode:Null<CursorMode> = null;

      if ((FlxG.mouse.pressed && currentSelectionMode == NONE) || FlxG.mouse.pressedMiddle)
      {
        // Player is moving their camera in the stage editor.
        targetCursorMode = Grabbing;
        var safeZoom:Float = FlxMath.bound(stageCamera.zoom, 0.3);
        cameraFollowPoint.x -= Math.round(FlxG.mouse.deltaX / 2 / safeZoom);
        cameraFollowPoint.y -= Math.round(FlxG.mouse.deltaY / 2 / safeZoom);
      }

      if ((FlxG.mouse.wheel > 0 || (FlxG.mouse.wheel < 0 && stageCamera.zoom > 0.11)) && !isCursorOverHaxeUI)
      {
        stageCamera.zoom += FlxG.mouse.wheel / 10;
        this.updateGridBitmapSize();
      }

      switch (currentSelectionMode)
      {
        case StageEditorSelectionMode.OBJECTS:
          if (selectedProp != null
            && !FlxG.mouse.pixelPerfectCheck(selectedProp)
            && FlxG.mouse.justPressed) performCommand(new DeselectObjectCommand(selectedProp));

          for (prop in spriteArray)
          {
            if (prop == null || !prop.visible) continue;

            var isOverlapping:Bool = FlxG.mouse.pixelPerfectCheck(prop);

            if (prop == selectedProp)
            {
              selectedItemName = prop.name;
              if (FlxG.keys.pressed.SHIFT) objectNameText.text = prop.name + ' (LOCKED)';

              if (FlxG.mouse.justPressed && isOverlapping && !FlxG.keys.pressed.SHIFT && !isCursorOverHaxeUI)
              {
                dragTargetItem = selectedProp;
                dragStartPositions = [selectedProp.x, selectedProp.y];
                dragOffset = [
                  FlxG.mouse.getWorldPosition().x - selectedProp.x,
                  FlxG.mouse.getWorldPosition().y - selectedProp.y
                ];
                dragWasMoving = false;
              }

              if (dragTargetItem == selectedProp && FlxG.mouse.pressed && (FlxG.mouse.deltaX != 0 || FlxG.mouse.deltaY != 0))
              {
                var mousePos = FlxG.mouse.getWorldPosition();
                prop.x = Math.floor(mousePos.x - dragOffset[0]) - Math.floor(mousePos.x - dragOffset[0]) % moveStep;
                prop.y = Math.floor(mousePos.y - dragOffset[1]) - Math.floor(mousePos.y - dragOffset[1]) % moveStep;
                // updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);

                dragWasMoving = true;
                targetCursorMode = Grabbing;
              }

              if (dragTargetItem == selectedProp && FlxG.mouse.justReleased)
              {
                if (dragWasMoving)
                {
                  var endPoints:Array<Float> = [selectedProp.x, selectedProp.y];
                  if (endPoints[0] != dragStartPositions[0] || endPoints[1] != dragStartPositions[1])
                  {
                    performCommand(new MoveItemCommand(selectedProp, dragStartPositions, endPoints));
                  }
                }
                dragTargetItem = null;
                dragOffset = [];
                dragStartPositions = [];
                dragWasMoving = false;
              }
            }

            if (isOverlapping && !FlxG.keys.pressed.SHIFT)
            {
              if (dragTargetItem == null) targetCursorMode = Pointer;
              objectNameText.text = prop.name;
              if (FlxG.mouse.justPressed && !isCursorOverHaxeUI) performCommand(new SelectObjectCommand(prop));
            }
          }
        case StageEditorSelectionMode.CHARACTERS:
          if (selectedCharacter != null
            && !FlxG.mouse.pixelPerfectCheck(selectedCharacter)
            && FlxG.mouse.justPressed) selectedCharacter = null;

          for (charType => character in characters)
          {
            if (character == null || !character.visible) continue;

            var isOverlapping:Bool = FlxG.mouse.pixelPerfectCheck(character);

            if (character == selectedCharacter)
            {
              selectedItemName = Std.string(character.characterType);
              if (FlxG.keys.pressed.SHIFT) objectNameText.text = Std.string(character.characterType) + ' (LOCKED)';

              if (FlxG.mouse.justPressed && isOverlapping && !FlxG.keys.pressed.SHIFT && !isCursorOverHaxeUI)
              {
                dragTargetItem = selectedCharacter;
                dragStartPositions = [selectedCharacter.x, selectedCharacter.y];
                dragOffset = [
                  FlxG.mouse.getWorldPosition().x - selectedCharacter.x,
                  FlxG.mouse.getWorldPosition().y - selectedCharacter.y
                ];
                dragWasMoving = false;
              }

              if (dragTargetItem == selectedCharacter && FlxG.mouse.pressed && (FlxG.mouse.deltaX != 0 || FlxG.mouse.deltaY != 0))
              {
                var mousePos = FlxG.mouse.getWorldPosition();
                character.x = Math.floor(mousePos.x - dragOffset[0]) - Math.floor(mousePos.x - dragOffset[0]) % moveStep;
                character.y = Math.floor(mousePos.y - dragOffset[1]) - Math.floor(mousePos.y - dragOffset[1]) % moveStep;
                // updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);

                dragWasMoving = true;
                targetCursorMode = Grabbing;
              }

              if (dragTargetItem == selectedCharacter && FlxG.mouse.justReleased)
              {
                if (dragWasMoving)
                {
                  var endPoints:Array<Float> = [selectedCharacter.x, selectedCharacter.y];
                  if (endPoints[0] != dragStartPositions[0] || endPoints[1] != dragStartPositions[1])
                  {
                    performCommand(new MoveItemCommand(selectedCharacter, dragStartPositions, endPoints));
                  }
                }
                dragTargetItem = null;
                dragOffset = [];
                dragStartPositions = [];
                dragWasMoving = false;
              }
            }

            if (isOverlapping && !FlxG.keys.pressed.SHIFT)
            {
              if (dragTargetItem == null) targetCursorMode = Pointer;
              objectNameText.text = Std.string(character.characterType);
              if (FlxG.mouse.justPressed && !isCursorOverHaxeUI) selectedCharacter = character;
            }
          }
        default:
          // nothing
      }

      // Actually set the cursor mode to the one we specified earlier.
      Cursor.cursorMode = targetCursorMode ?? Default;
    }
  }

  /**
   * Handle keybinds for File menu items.
   */
  function handleFileKeybinds():Void
  {
    // CTRL + N = New Stage
    if (pressingControl() && FlxG.keys.justPressed.N && !isHaxeUIDialogOpen)
    {
      this.openWelcomeDialog(true);
    }

    // CTRL + O = Open Stage
    // if (pressingControl() && FlxG.keys.justPressed.O && !isHaxeUIDialogOpen)
    // {

    // }

    if (pressingControl() && FlxG.keys.justPressed.S && !isHaxeUIDialogOpen)
    {
      if (currentWorkingFilePath == null || FlxG.keys.pressed.SHIFT)
      {
        // CTRL + SHIFT + S = Save As
        this.exportAllStageData(false, null, function(path:String) {
          // CTRL + SHIFT + S Successful
          this.success('Saved Stage', 'Stage saved successfully to ${path}.');
        }, function() {
          // CTRL + SHIFT + S Cancelled
        });
      }
      else
      {
        // CTRL + S = Save Stage
        this.exportAllStageData(true, currentWorkingFilePath);
        this.success('Saved Stage', 'Stage saved successfully to ${currentWorkingFilePath}.');
      }
    }

    // CTRL + Q = Quit to Menu
    if (pressingControl() && FlxG.keys.justPressed.Q)
    {
      this.quitStageEditor(true);
    }
  }

  /**
   * Handle keybinds for edit menu items.
   */
  function handleEditKeybinds():Void
  {
    // CTRL + Z = Undo
    if (undoKeyHandler.activated)
    {
      undoLastCommand();
    }

    // CTRL + Y = Redo
    if (redoKeyHandler.activated)
    {
      redoLastCommand();
    }

    // CTRL + H = Flip Horizontally
    if (pressingControl() && FlxG.keys.justPressed.H)
    {
      if (selectedProp != null) performCommand(new FlipObjectCommand(selectedProp, true));
    }

    // CTRL + G = Flip Vertically
    if (pressingControl() && FlxG.keys.justPressed.G)
    {
      if (selectedProp != null) performCommand(new FlipObjectCommand(selectedProp, false));
    }

    // CTRL + Delete = Delete
    if (pressingControl() && FlxG.keys.justPressed.DELETE)
    {
      performCommand(new RemoveObjectCommand(selectedProp));
    }
  }

  function quitStageEditor(exitPrompt:Bool = false):Void
  {
    // if (saveDataDirty && exitPrompt)
    // {
    //   // this.openLeaveConfirmationDialog();
    //   return;
    // }

    autoSave();

    this.hideAllToolboxes();

    // stopWelcomeMusic();
    FlxG.switchState(() -> new MainMenuState());

    resetWindowTitle();

    criticalFailure = true;
  }

  function applyCanQuickSave():Void
  {
    if (menubarItemSaveStage == null) return;

    if (currentWorkingFilePath == null)
    {
      menubarItemSaveStage.disabled = true;
    }
    else
    {
      menubarItemSaveStage.disabled = false;
    }
  }

  /**
   * Play a sound effect.
   * Automatically cleans up after itself and recycles previous FlxSound instances if available, for performance.
   * @param path The path to the sound effect. Use `Paths` to build this.
   */
  function playSound(path:String, volume:Float = 1.0):Void
  {
    var asset:Null<FlxSoundAsset> = FlxG.sound.cache(path);
    if (asset == null)
    {
      trace('WARN: Failed to play sound $path, asset not found.');
      return;
    }
    var snd:Null<FunkinSound> = FunkinSound.load(asset);
    if (snd == null) return;
    snd.autoDestroy = true;
    snd.play(true);
    snd.volume = volume;
  }

  function applyWindowTitle():Void
  {
    var inner:String = 'New Stage';
    var cwfp:Null<String> = currentWorkingFilePath;
    if (cwfp != null)
    {
      inner = cwfp;
    }
    if (currentWorkingFilePath == null || saveDataDirty)
    {
      inner += '*';
    }
    WindowUtil.setWindowTitle('Friday Night Funkin\' Stage Editor - ${inner}');
  }

  function resetWindowTitle():Void
  {
    WindowUtil.setWindowTitle('Friday Night Funkin\'');
  }
}

typedef StageEditorParams =
{
  /**
   * If non-null, load this stage immediately instead of the welcome screen.
   */
  var ?fnfsTargetPath:String;

  /**
   * If non-null, load this stage immediately instead of the welcome screen.
   */
  var ?targetStageId:String;
};

/**
 * Available themes for the stage editor state.
 */
enum abstract StageEditorTheme(String)
{
  /**
   * The default theme for the stage editor.
   */
  var Light;

  /**
   * A theme which introduces darker colors.
   */
  var Dark;
}

enum abstract StageEditorSelectionMode(String) from String to String
{
  /**
   * Moving around the stage.
   */
  var NONE;

  /**
   * Modifying objects, aka the props that are currently present in the stage.
   */
  var OBJECTS;

  /**
   * Modifying the characters that are currently present in the stage.
   */
  var CHARACTERS;
}
