package funkin.ui.debug.stageeditor;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.system.FlxAssets.FlxSoundAsset;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.input.Cursor;
import funkin.input.TurboButtonHandler;
import funkin.input.TurboKeyHandler;
import funkin.save.Save;
import funkin.ui.debug.stageeditor.components.StageEditorObject;
import funkin.ui.debug.stageeditor.commands.RemoveObjectCommand;
import funkin.ui.debug.stageeditor.commands.StageEditorCommand;
import funkin.play.character.BaseCharacter;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.data.stage.StageData;
import funkin.util.WindowUtil;
import funkin.util.FileUtil;
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

  /**
   * ==============================
   * INSTANCE DATA
   * ==============================
   */

  /**
   * A timer used to auto-save the chart after a period of inactivity.
   */
  var autoSaveTimer:Null<FlxTimer> = null;

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
    selectedProp?.selectedShader.setAmount(0);
    this.selectedProp = value;

    // update dialogs

    selectedProp?.selectedShader.setAmount(1);

    return selectedProp;
  }

  public var selectedCharacter(default, set):Null<BaseCharacter> = null;

  function set_selectedCharacter(value:Null<BaseCharacter>):BaseCharacter
  {
    this.selectedCharacter = value;
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
   * The step at which an object or character is moved.
   * E.g., if `moveStep` is 5, pressing the arrow keys will move the object by 5 pixels.
   */
  var moveStep:Int = 1;

  /**
   * The step at which an object or character is rotated.
   * E.g., if `angleStep` is 5, pressing the rotate buttons will rotate the object by 5 degrees.
   */
  var angleStep:Float = 5.0;

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
    return Screen.instance.hasSolidComponentUnderPoint(FlxG.mouse.viewX, FlxG.mouse.viewY);
  }

  /**
   * The value of `isCursorOverHaxeUI` from the previous frame.
   * This is useful because we may have just clicked a menu item, causing the menu to disappear.
   */
  var wasCursorOverHaxeUI:Bool = false;

  /**
   * Set by StageEditorDialogHandler, used to prevent background interaction while the dialog is open.
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
  var menubarItemViewChars:MenuCheckBox;

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

  /**
   * ==============================
   * STAGE DATA
   * ==============================
   */

  /**
   * The data representing the current stage.
   */
  var stageData:StageData = new StageData();

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
    // WindowManager.instance.reset();
    if (FlxG.sound.music != null) FlxG.sound.music?.stop();
    // WindowUtil.setWindowTitle("Friday Night Funkin\' Stage Editor");

    // new StageEditorAssetDataHandler(this);

    // Show the mouse cursor.
    Cursor.show();

    loadPreferences();

    uiCamera = new FunkinCamera('stageEditorUI');
    stageCamera = new FlxCamera();

    cameraFollowPoint = new FlxObject(0, 0, 2, 3);
    cameraFollowPoint.screenCenter();

    initCameras();

    buildDefaultStageData();

    this.updateTheme();
    buildGrid();

    initCharacters();
    initVisuals();

    setupUIListeners();

    stageCamera.follow(cameraFollowPoint);

    refresh();

    if (params != null && params.fnfsTargetPath != null)
    {
      // var result:Null<Array<String>> = this.loadFromFNFSPath(params.fnfsTargetPath);
      // if (result != null)
      // {
      //   if (result.length == 0)
      //   {
      //     this.success('Loaded Stage', 'Loaded stage (${params.fnfsTargetPath})');
      //   }
      //   else
      //   {
      //     this.warning('Loaded Stage', 'Loaded stage with issues (${params.fnfsTargetPath})\n${result.join("\n")}');
      //   }
      // }
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
    trace(previousWorkingFilePaths);
    trace(currentWorkingFilePath);

    moveStep = Std.parseInt(StringTools.replace(save.stageEditorMoveStep, "px", ""));
    angleStep = save.stageEditorAngleStep;
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
      else menuItemRecentStage.disabled = false;

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
    if (gridBitmap == null) throw 'ERROR: Tried to build grid, but gridBitmap is null! Check StageEditorThemeHandler.updateTheme().';

    gridTiledSprite = new FlxTiledSprite(gridBitmap, gridBitmap.width, gridBitmap.height, true, true);
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

      var positionMarker = new FlxShapeCircle(0, 0, 30, cast {thickness: 2, color: color }, color);

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

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    stageCamera.follow(cameraFollowPoint);

    if ((FlxG.mouse.wheel > 0 || (FlxG.mouse.wheel < 0 && stageCamera.zoom > 0.11)) && !isCursorOverHaxeUI)
    {
      stageCamera.zoom += FlxG.mouse.wheel / 10;
      this.updateGridBitmapSize();
    }

    handleMenubar();

    handleFileKeybinds();
    handleEditKeybinds();
  }

  function setupUIListeners():Void
  {
    menubarItemNewStage.onClick = _ -> this.openWelcomeDialog(true);
    // other stuff here
    menubarItemNewObj.onClick = _ -> this.openNewObjectDialog();
    menubarItemDelete.onClick = _ -> {
      if (selectedProp != null) performCommand(new RemoveObjectCommand(selectedProp));
      else this.error('No Object Selected', 'Please select an object to delete.');
    };
    menubarItemWindowStage.onChange = event -> this.setToolboxState(STAGE_EDITOR_TOOLBOX_METADATA_LAYOUT, event.value);
    menubarItemAbout.onClick = _ -> this.openAboutDialog();
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
    //

    // CTRL + Q = Quit to Menu
    //
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
  function playSound( path:String, volume:Float = 1.0):Void
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
    // var cwfp:Null<String> = currentWorkingFilePath;
    // if (cwfp != null)
    // {
    //   inner = cwfp;
    // }
    // if (currentWorkingFilePath == null || saveDataDirty)
    // {
    //   inner += '*';
    // }
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
