package funkin.ui.debug.stageeditor;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.input.Cursor;
import funkin.input.TurboButtonHandler;
import funkin.input.TurboKeyHandler;
import funkin.save.Save;
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

  public static final LIGHT_MODE_COLORS:Array<FlxColor> = [0xFFE7E6E6, 0xFFF8F8F8];
  public static final DARK_MODE_COLORS:Array<FlxColor> = [0xFF181919, 0xFF202020];

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
  public var cameraFollowPoint:FlxObject;

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
   * The `Edit -> New Object` menu item.
   */
  var menubarItemNewObj:MenuItem;

  /**
   * The `Edit -> Find Object` menu item.
   */
  var menubarItemFindObj:MenuItem;

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

  var characters:Map<String, BaseCharacter> = new Map<String, BaseCharacter>();

  var cameraBounds:FlxTypedGroup<FlxSprite>;

  var characterPositionMarkers:Array<FlxShapeCircle> = [];

  var characterFloorLines:Array<FlxSprite> = [];

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

    // Show the mouse cursor.
    Cursor.show();

    uiCamera = new FunkinCamera('stageEditorUI');
    stageCamera = new FlxCamera();

    cameraFollowPoint = new FlxObject(0, 0, 2, 3);
    cameraFollowPoint.screenCenter();

    initCameras();
    initCharacters();
    initVisuals();

    setupUIListeners();

    stageCamera.follow(cameraFollowPoint);

    refresh();
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
  }

  function setupUIListeners():Void
  {
    menubarItemNewStage.onClick = _ -> this.openWelcomeDialog();
    // other stuff here
    menubarItemAbout.onClick = _ -> this.openAboutDialog();
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
