package funkin.ui.debug.stageeditor;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.input.Cursor;
import funkin.input.TurboButtonHandler;
import funkin.input.TurboKeyHandler;
import funkin.save.Save;
import funkin.ui.debug.stageeditor.components.StageEditorObject;
import funkin.ui.debug.stageeditor.commands.StageEditorCommand;
import funkin.play.character.BaseCharacter;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.util.WindowUtil;
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
 * @author Code refractored by anysad
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

  public var selectedProp(default, set):StageEditorObject = null;

  function set_selectedProp(value:StageEditorObject):StageEditorObject
  {
    selectedProp?.selectedShader.setAmount(0);
    this.selectedProp = value;

    // update dialogs

    selectedProp?.selectedShader.setAmount(1);

    return selectedProp;
  }

  public var selectedCharacter(default, set):BaseCharacter = null;

  function set_selectedCharacter(value:BaseCharacter)
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
   * RENDERED OBJECTS
   * ==============================
   */

  public var characters:Map<String, BaseCharacter> = new Map<String, BaseCharacter>();

  public var spriteArray:Array<StageEditorObject> = [];

  var cameraBounds:FlxTypedGroup<FlxSprite>;

  var characterPositionMarkers:Array<FlxShapeCircle> = [];

  var characterFloorLines:Array<FlxSprite> = [];

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

    new StageEditorAssetDataHandler(this);

    // Show the mouse cursor.
    Cursor.show();

    uiCamera = new FunkinCamera('stageEditorUI');
    stageCamera = new FlxCamera();

    cameraFollowPoint = new FlxObject(0, 0, 2, 3);
    cameraFollowPoint.screenCenter();

    initCameras();

    this.updateTheme();
    buildGrid();

    // initCharacters();
    initVisuals();

    setupUIListeners();

    stageCamera.follow(cameraFollowPoint);

    refresh();

    if (params != null && params.fnfsTargetPath != null)
    {
      // var result:Null<Array<String>> = this.loadStageAsTemplate(params.targetStageId);
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
      // this.loadStageAsTemplate(params.targetStageId);
    }
    else
    {
      var welcomeDialog = this.openWelcomeDialog(false);
      // if (shouldShowBackupAvailableDialog) this.openBackupAvailableDialog(welcomeDialog);
    }
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
    if (gridBitmap == null) throw 'ERROR: Tried to build grid, but gridBitmap is null! Check ChartEditorThemeHandler.updateTheme().';

    gridTiledSprite = new FlxTiledSprite(gridBitmap, gridBitmap.width, gridBitmap.height, true, true);
    gridTiledSprite.scrollFactor.set();
    add(gridTiledSprite);
    // gridTiledSprite.zIndex = 10;
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
  }

  function setupUIListeners():Void
  {
    menubarItemNewStage.onClick = _ -> this.openWelcomeDialog();
    // other stuff here
    menubarItemNewObj.onClick = _ -> this.openNewObjectDialog();
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
      // commandHistoryDirty = true;
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
    // commandHistoryDirty = true;
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
