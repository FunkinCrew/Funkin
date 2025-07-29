package funkin.ui.debug.stageeditor;

import flixel.math.FlxPoint;
import flixel.text.FlxText;
import openfl.display.BitmapData;
import flixel.util.FlxTimer;
import flixel.FlxCamera;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.display.FlxGridOverlay;
import funkin.play.character.BaseCharacter;
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.save.Save;
import funkin.input.Cursor;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuOptionBox;
import haxe.ui.containers.menus.MenuCheckBox;
import funkin.util.FileUtil;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.debug.stageeditor.handlers.AssetDataHandler;
import funkin.ui.debug.stageeditor.handlers.AssetDataHandler.StageEditorObjectData;
import funkin.ui.debug.stageeditor.handlers.StageDataHandler;
import funkin.ui.debug.stageeditor.handlers.UndoRedoHandler.UndoAction;
import funkin.ui.debug.stageeditor.toolboxes.*;
import funkin.ui.debug.stageeditor.components.*;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.components.Button;
import haxe.ui.containers.windows.WindowList;
import haxe.ui.containers.windows.WindowManager;
import flixel.FlxObject;
import haxe.ui.components.Label;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import haxe.ui.focus.FocusManager;
import haxe.ui.core.Screen;
import funkin.util.WindowUtil;
import funkin.audio.FunkinSound;
import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import funkin.util.logging.CrashHandler;
import funkin.graphics.shaders.Grayscale;
import funkin.data.stage.StageRegistry;

/**
 * Da Stage Editor woo!!
 * made by Kolo NEVER FORGET
 */
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/stage-editor/main-view.xml"))
class StageEditorState extends UIState
{
  // i aint documenting allat
  // the uh finals
  public static final BACKUPS_PATH:String = "./stagebackups/";
  public static final LIGHT_MODE_COLORS:Array<FlxColor> = [0xFFE7E6E6, 0xFFF8F8F8];
  public static final DARK_MODE_COLORS:Array<FlxColor> = [0xFF181919, 0xFF202020];

  public static final DEFAULT_POSITIONS:Map<CharacterType, Array<Float>> = [
    CharacterType.BF => [989.5, 885],
    CharacterType.GF => [751.5, 787],
    CharacterType.DAD => [335, 885]
  ];

  public static final DEFAULT_CAMERA_OFFSETS:Map<CharacterType, Array<Float>> = [
    CharacterType.BF => [-100, -100],
    CharacterType.GF => [0, 0],
    CharacterType.DAD => [150, -100]
  ];

  public static final MAX_Z_INDEX:Int = 10000;
  public static final CHARACTER_COLORS:Array<FlxColor> = [FlxColor.RED, FlxColor.PURPLE, FlxColor.CYAN]; // FCUK IVE TURNED INTO AN AMERICAN
  public static final TIME_BEFORE_ANIM_STOP:Float = 3.0;

  public static var instance:StageEditorState = null; // unused lol

  // the other shit:tm:
  var menubar:MenuBar;

  var menubarMenuFile:Menu;
  var menubarItemNewStage:MenuItem; // new
  var menubarItemOpenStage:MenuItem; // open
  var menubarItemOpenRecent:Menu; // open recent submenu
  var menubarItemSaveStage:MenuItem; // save
  var menubarItemSaveStageAs:MenuItem; // save as
  var menubarItemClearAssets:MenuItem; // clear assets
  var menubarItemExit:MenuItem; // exit

  var menubarMenuEdit:Menu;
  var menubarItemUndo:MenuItem; // undo
  var menubarItemRedo:MenuItem; // redo
  var menubarItemCopy:MenuItem; // copy
  var menubarItemCut:MenuItem; // cut
  var menubarItemPaste:MenuItem; // paste
  var menubarItemDelete:MenuItem; // delete
  var menubarItemNewObj:MenuItem; // new
  var menubarItemFindObj:MenuItem; // find
  var menubarItemMoveStep:Menu; // move step submenu

  var menubarMenuView:Menu;
  var menubarItemThemeLight:MenuOptionBox; // light mode option
  var menubarItemThemeDark:MenuOptionBox; // dark mode option
  var menubarItemViewChars:MenuCheckBox; // view chars check
  var menubarItemViewNameText:MenuCheckBox; // view name text check
  var menubarItemViewFloorLines:MenuCheckBox; // view floor lines check
  var menubarItemViewPosMarkers:MenuCheckBox; // view pos markers check
  var menubarItemViewCamBounds:MenuCheckBox; // view cam bounds check

  var menubarMenuWindow:Menu;
  var menubarItemWindowObjectGraphic:MenuCheckBox;
  var menubarItemWindowObjectAnims:MenuCheckBox;
  var menubarItemWindowObjectProps:MenuCheckBox;
  var menubarItemWindowCharacter:MenuCheckBox;
  var menubarItemWindowStage:MenuCheckBox;

  var menubarMenuHelp:Menu;
  var menubarItemUserGuide:MenuItem;
  var menubarItemGoToBackupsFolder:MenuItem;
  var menubarItemAbout:MenuItem;

  var menubarButtonText:Button; // test stage button
  var windowList:WindowList;

  var bottomBarModeText:Label;
  var bottomBarSelectText:Label;
  var bottomBarMoveStepText:Label;
  var bottomBarAngleStepText:Label;

  var bg:FlxSprite;

  public var selectedSprite(default, set):StageEditorObject = null;

  function set_selectedSprite(value:StageEditorObject)
  {
    selectedSprite?.selectedShader.setAmount(0);
    this.selectedSprite = value;
    updateDialog(StageEditorDialogType.OBJECT_GRAPHIC);
    updateDialog(StageEditorDialogType.OBJECT_ANIMS);
    updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);

    if (selectedSprite != null)
    {
      // spriteMarker.setGraphicSize(Std.int(selectedSprite.width), Std.int(selectedSprite.height));
      // spriteMarker.updateHitbox();
    }

    selectedSprite?.selectedShader.setAmount(1);

    return selectedSprite;
  }

  public var selectedChar(default, set):BaseCharacter = null;

  function set_selectedChar(value:BaseCharacter)
  {
    this.selectedChar = value;
    updateDialog(StageEditorDialogType.CHARACTER);
    return selectedChar;
  }

  var isCursorOverHaxeUI(get, never):Bool;

  function get_isCursorOverHaxeUI():Bool
  {
    return Screen.instance.hasSolidComponentUnderPoint(Screen.instance.currentMouseX, Screen.instance.currentMouseY);
  }

  public var spriteMarker:FlxSprite;
  public var spriteArray:Array<StageEditorObject> = [];
  public var camMarker:FlxSprite;

  public var copiedSprite:StageEditorObjectData = null;

  public var stageZoom:Float = 1.0;
  public var stageName:String = "Unnamed";
  public var stageFolder:String = "shared";

  public var autoSaveTimer:FlxTimer = new FlxTimer();

  public var saved(default, set):Bool = true;
  public var currentFile(default, set):String = "";

  function set_saved(value:Bool):Bool
  {
    saved = value;

    updateWindowTitle();

    if (!autoSaveTimer.finished)
    {
      autoSaveTimer.cancel();
    }

    if (!saved)
    {
      autoSaveTimer.start(Constants.AUTOSAVE_TIMER_DELAY_SEC, function(tmr:FlxTimer) {
        FileUtil.createDirIfNotExists(BACKUPS_PATH);

        var data = this.packShitToZip();
        var path = haxe.io.Path.join([
          BACKUPS_PATH,
          'stage-editor-${funkin.util.DateUtil.generateTimestamp()}.${FileUtil.FILE_EXTENSION_INFO_FNFS.extension}'
        ]);

        FileUtil.writeBytesToPath(path, data);
        saved = true;

        Save.instance.stageEditorHasBackup = true;
        Save.instance.flush();

        notifyChange("Auto-Save", "A Backup of this Stage has been made.");
      });
    }

    return value;
  }

  function set_currentFile(value:String):String
  {
    currentFile = value;

    updateWindowTitle();

    if (currentFile != "") updateRecentFiles();

    reloadRecentFiles();

    return value;
  }

  public var undoArray:Array<UndoAction> = [];
  public var redoArray:Array<UndoAction> = [];

  public var nameTxt:FlxText;

  public var gf(get, never):BaseCharacter;
  public var bf(get, never):BaseCharacter;
  public var dad(get, never):BaseCharacter;

  function get_gf()
    return charGroups[CharacterType.GF].getFirst(StageDataHandler.checkForCharacter);

  function get_bf()
    return charGroups[CharacterType.BF].getFirst(StageDataHandler.checkForCharacter);

  function get_dad()
    return charGroups[CharacterType.DAD].getFirst(StageDataHandler.checkForCharacter);

  public var charGroups:Map<CharacterType, FlxTypedGroup<BaseCharacter>> = [];

  public var charCamOffsets:Map<CharacterType, Array<Float>> = DEFAULT_CAMERA_OFFSETS.copy();
  public var charPos:Map<CharacterType, Array<Float>> = DEFAULT_POSITIONS.copy();

  public var bitmaps:Map<String, BitmapData> = []; // used for optimizing the file size!!!

  var charDeselectShader:Grayscale = new Grayscale();
  var floorLines:Array<FlxSprite> = [];
  var posCircles:Array<FlxShapeCircle> = [];
  var camFields:FlxTypedGroup<FlxSprite>;
  var camHUD:FlxCamera;
  var camGame:FlxCamera;

  public var camFollow:FlxObject;
  public var moveOffset:Array<Float> = [];
  public var moveStep:Int = 1;
  public var moveMode:String = "assets";
  public var infoSelection:String = "None";
  public var dialogs:Map<StageEditorDialogType, StageEditorDefaultToolbox> = [];

  var allowInput(get, never):Bool;

  function get_allowInput()
  {
    return FocusManager.instance.focus == null;
  }

  var testingMode:Bool = false;

  var showChars(default, set):Bool = true;

  function set_showChars(value:Bool):Bool
  {
    this.showChars = value;

    for (cooldude in getCharacters())
      cooldude.visible = showChars;

    return value;
  }

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
    WindowManager.instance.reset();
    instance = this;
    FlxG.sound.music?.stop();
    WindowUtil.setWindowTitle("Friday Night Funkin\' Stage Editor");

    AssetDataHandler.init(this);

    camGame = new FlxCamera();
    camHUD = new FlxCamera();
    camHUD.bgColor.alpha = 0;

    FlxG.cameras.reset(camGame);
    FlxG.cameras.add(camHUD, false);
    FlxG.cameras.setDefaultDrawTarget(camGame, true);

    persistentUpdate = false;

    bg = FlxGridOverlay.create(10, 10);
    bg.scrollFactor.set();
    add(bg);

    updateBGColors();

    super.create();
    root.scrollFactor.set();
    root.cameras = [camHUD];
    root.width = FlxG.width;
    root.height = FlxG.height;

    menubar.height = 35;
    WindowManager.instance.container = root;
    Screen.instance.addComponent(root);

    // Characters setup.
    var gf = CharacterDataParser.fetchCharacter(Save.instance.stageGirlfriendChar, true);
    gf.characterType = CharacterType.GF;
    var dad = CharacterDataParser.fetchCharacter(Save.instance.stageDadChar, true);
    dad.characterType = CharacterType.DAD;
    var bf = CharacterDataParser.fetchCharacter(Save.instance.stageBoyfriendChar, true);
    bf.characterType = CharacterType.BF;

    bf.flipX = !bf.getDataFlipX();
    gf.flipX = gf.getDataFlipX();
    dad.flipX = dad.getDataFlipX();

    gf.updateHitbox();
    dad.updateHitbox();
    bf.updateHitbox();

    // Only one character per group allowed.
    charGroups = [
      CharacterType.BF => new FlxTypedGroup<BaseCharacter>(1),
      CharacterType.GF => new FlxTypedGroup<BaseCharacter>(1),
      CharacterType.DAD => new FlxTypedGroup<BaseCharacter>(1)
    ];

    gf.x = charPos[CharacterType.GF][0] - gf.characterOrigin.x + gf.globalOffsets[0];
    gf.y = charPos[CharacterType.GF][1] - gf.characterOrigin.y + gf.globalOffsets[1];
    dad.x = charPos[CharacterType.DAD][0] - dad.characterOrigin.x + dad.globalOffsets[0];
    dad.y = charPos[CharacterType.DAD][1] - dad.characterOrigin.y + dad.globalOffsets[1];
    bf.x = charPos[CharacterType.BF][0] - bf.characterOrigin.x + bf.globalOffsets[0];
    bf.y = charPos[CharacterType.BF][1] - bf.characterOrigin.y + bf.globalOffsets[1];

    selectedChar = bf;

    charGroups[CharacterType.GF].add(gf);
    charGroups[CharacterType.DAD].add(dad);
    charGroups[CharacterType.BF].add(bf);

    add(charGroups[CharacterType.GF]);
    add(charGroups[CharacterType.DAD]);
    add(charGroups[CharacterType.BF]);

    // UI Sprites setup.
    camFields = new FlxTypedGroup<FlxSprite>();
    camFields.visible = false;
    camFields.zIndex = MAX_Z_INDEX + CHARACTER_COLORS.length + 1;

    for (i in 0...CHARACTER_COLORS.length)
    {
      var floorLine = new FlxSprite().makeGraphic(FlxG.width * 10, 15, CHARACTER_COLORS[i]);
      floorLine.screenCenter(X);

      var pointer = new FlxShapeCircle(0, 0, 30, cast {thickness: 2, color: CHARACTER_COLORS[i]}, CHARACTER_COLORS[i]);

      var field = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, CHARACTER_COLORS[i]);

      pointer.alpha = floorLine.alpha = field.alpha = 0.35;
      pointer.ID = floorLine.ID = field.ID = i;
      pointer.visible = floorLine.visible = false;
      pointer.zIndex = floorLine.zIndex = MAX_Z_INDEX + 1 + i;

      add(floorLine);
      add(pointer);

      floorLines.push(floorLine);
      posCircles.push(pointer);

      camFields.add(field);
    }

    camMarker = new FlxSprite().loadGraphic(FlxGraphic.fromClass(GraphicCursorCross));
    camMarker.setGraphicSize(80, 80);
    camMarker.updateHitbox();
    camMarker.zIndex = MAX_Z_INDEX + CHARACTER_COLORS.length + 2;

    updateMarkerPos();

    add(camFields);
    add(camMarker);

    nameTxt = new FlxText(0, 0, 0, "", 24);
    nameTxt.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    nameTxt.cameras = [camHUD];
    add(nameTxt);

    camFollow = new FlxObject(0, 0, 2, 2);
    camFollow.screenCenter();
    add(camFollow);

    camGame.follow(camFollow);

    addUI();

    // Some callbacks.
    findObjDialog = new FindObjDialog(this, selectedSprite == null ? "" : selectedSprite.name);

    FlxG.stage.window.onDropFile.add(function(path:String):Void {
      if (!allowInput || welcomeDialog != null) return;

      var data = BitmapData.fromFile(path);

      if (data != null)
      {
        objNameDialog = new NewObjDialog(this, data);
        objNameDialog.showDialog();

        objNameDialog.onDialogClosed = function(_) {
          objNameDialog = null;
        }

        return;
      }
    });

    if (params?.targetStageId != null && StageRegistry.instance.hasEntry(params?.targetStageId))
    {
      var stageData = StageRegistry.instance.parseEntryDataWithMigration(params.targetStageId, StageRegistry.instance.fetchEntryVersion(params.targetStageId));

      if (stageData != null)
      {
        // Load the stage data.
        currentFile = "";
        this.loadFromDataRaw(stageData);
      }
      else
      {
        // Notify the error and create a new stage.
        notifyChange("Problem Loading the Stage", "The Stage File could not be loaded.", true);
        onMenuItemClick("new stage");
      }
    }
    else if (params?.fnfsTargetPath != null)
    {
      var bytes = FileUtil.readBytesFromPath(params.fnfsTargetPath);

      if (bytes != null)
      {
        // Open the stage file.
        currentFile = params.fnfsTargetPath;
        this.unpackShitFromZip(bytes);
      }
      else
      {
        // Notify the error and create a new stage.
        notifyChange("Problem Loading the Stage", "The Stage File could not be loaded.", true);
        onMenuItemClick("new stage");
      }
    }
    else
    {
      onMenuItemClick("new stage");
      welcomeDialog.closable = false;

      #if sys
      if (Save.instance.stageEditorHasBackup)
      {
        FileUtil.createDirIfNotExists(BACKUPS_PATH);

        var files = sys.FileSystem.readDirectory(BACKUPS_PATH);

        if (files.length > 0)
        {
          // ensures that the top most file is a backup
          files.sort(funkin.util.SortUtil.alphabetically);

          while (!files[files.length - 1].endsWith(FileUtil.FILE_EXTENSION_INFO_FNFS.extension)
            || !files[files.length - 1].startsWith("stage-editor-"))
            files.pop();
        }

        if (files.length != 0) new BackupAvailableDialog(this, haxe.io.Path.join([BACKUPS_PATH, files[files.length - 1]])).showDialog(true);
      }
      #end
    }

    WindowUtil.windowExit.add(windowClose);
    CrashHandler.errorSignal.add(autosavePerCrash);
    CrashHandler.criticalErrorSignal.add(autosavePerCrash);

    Save.instance.stageEditorHasBackup = false;

    Cursor.show();
    FunkinSound.playMusic('chartEditorLoop',
      {
        startingVolume: 0.0
      });
    FlxG.sound.music.fadeIn(10, 0, 1);
  }

  var curTestChar:Int = 0;

  override public function beatHit()
  {
    if (testingMode)
    {
      if (conductorInUse.currentBeat % 2 == 0)
      {
        for (char in getCharacters())
          char.dance(true);
      }

      for (asset in spriteArray)
      {
        if (asset.danceEvery > 0 && conductorInUse.currentBeat % asset.danceEvery == 0) asset.dance(true);
      }

      if (conductorInUse.currentBeat % 8 == 0 && !FlxG.keys.pressed.SHIFT) curTestChar++;
    }

    return super.beatHit();
  }

  override public function update(elapsed:Float):Void
  {
    // Save the stage if exiting through the F4 keybind, as it moves you to the Main Menu.
    if (FlxG.keys.justPressed.F4)
    {
      @:privateAccess
      if (!autoSaveTimer.finished) autoSaveTimer.onLoopFinished();
      resetWindowTitle();

      WindowUtil.windowExit.remove(windowClose);
      CrashHandler.errorSignal.remove(autosavePerCrash);
      CrashHandler.criticalErrorSignal.remove(autosavePerCrash);

      Cursor.hide();
      FlxG.sound.music.stop();
      return;
    }

    updateBGSize();
    conductorInUse.update();

    super.update(elapsed);

    if (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickDown"));
    if (FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickUp"));

    // testmode
    menubarMenuFile.disabled = menubarMenuEdit.disabled = bottomBarModeText.disabled = menubarMenuWindow.disabled = testingMode;
    menubarButtonText.selected = testingMode;

    if (testingMode)
    {
      for (char in getCharacters())
        char.shader = null;

      // spriteMarker.visible = camMarker.visible = false;
      findObjDialog.hideDialog(DialogButton.CANCEL);

      // cam
      camGame.follow(camFollow, LOCKON, 0.04);
      FlxG.camera.zoom = stageZoom;

      if (FlxG.keys.justPressed.TAB && !FlxG.keys.pressed.SHIFT) curTestChar++;

      if (curTestChar >= getCharacters().length) curTestChar = 0;

      bottomBarSelectText.text = Std.string(getCharacters()[curTestChar].characterType);

      var char = getCharacters()[curTestChar];
      camFollow.x = char.cameraFocusPoint.x + charCamOffsets.get(char.characterType)[0];
      camFollow.y = char.cameraFocusPoint.y + charCamOffsets.get(char.characterType)[1];

      // EXIT
      if (FlxG.keys.justPressed.ENTER) // so we dont accidentally get stuck (happened to me once, terrible experience)
        onMenuItemClick("test stage");

      return;
    }

    // some misc
    nameTxt.text = "";
    bottomBarModeText.text = (moveMode == "assets" ? "Objects" : "Characters");

    camGame.follow(camFollow);
    // camera movement

    if ((FlxG.mouse.wheel > 0 || (FlxG.mouse.wheel < 0 && camGame.zoom > 0.11))
      && !isCursorOverHaxeUI) // include the floating poing error thing
    {
      camGame.zoom += FlxG.mouse.wheel / 10;
      updateBGSize();
    }

    // key shortcuts and inputs
    if (allowInput)
    {
      // "WINDOWS" key code is the same keycode as COMMAND on mac
      if (FlxG.keys.pressed.CONTROL || FlxG.keys.pressed.WINDOWS)
      {
        if (FlxG.keys.justPressed.Z) onMenuItemClick("undo");
        if (FlxG.keys.justPressed.Y) onMenuItemClick("redo");
        if (FlxG.keys.justPressed.C) onMenuItemClick("copy object");
        if (FlxG.keys.justPressed.V) onMenuItemClick("paste object");
        if (FlxG.keys.justPressed.X) onMenuItemClick("cut object");
        if (FlxG.keys.justPressed.S) FlxG.keys.pressed.SHIFT ? onMenuItemClick("save stage as") : onMenuItemClick("save stage");
        if (FlxG.keys.justPressed.F) onMenuItemClick("find object");
        if (FlxG.keys.justPressed.O) onMenuItemClick("open stage");
        if (FlxG.keys.justPressed.N) onMenuItemClick("new stage");
        if (FlxG.keys.justPressed.Q) onMenuItemClick("exit");
      }

      if (FlxG.keys.justPressed.TAB) onMenuItemClick("switch mode");
      if (FlxG.keys.justPressed.DELETE) onMenuItemClick("delete object");
      if (FlxG.keys.justPressed.ENTER) onMenuItemClick("test stage");
      if (FlxG.keys.justPressed.F1 && welcomeDialog == null && userGuideDialog == null) onMenuItemClick("user guide");

      if (FlxG.keys.justPressed.T)
      {
        camFollow.screenCenter();
        FlxG.camera.zoom = 1;
      }

      if (FlxG.keys.pressed.W || FlxG.keys.pressed.S || FlxG.keys.pressed.A || FlxG.keys.pressed.D)
      {
        if (FlxG.keys.pressed.W) camFollow.velocity.y = -90 * (2 / FlxG.camera.zoom);
        else if (FlxG.keys.pressed.S) camFollow.velocity.y = 90 * (2 / FlxG.camera.zoom);
        else
          camFollow.velocity.y = 0;

        if (FlxG.keys.pressed.A) camFollow.velocity.x = -90 * (2 / FlxG.camera.zoom);
        else if (FlxG.keys.pressed.D) camFollow.velocity.x = 90 * (2 / FlxG.camera.zoom);
        else
          camFollow.velocity.x = 0;
      }
      else
      {
        camFollow.velocity.set();
      }
    }
    else
    {
      camFollow.velocity.set();
    }

    // movement handling
    if (FlxG.mouse.justReleased && moveOffset.length > 0) moveOffset = [];

    if (moveMode == "assets")
    {
      if (selectedSprite != null && !FlxG.mouse.overlaps(selectedSprite) && FlxG.mouse.justPressed && !isCursorOverHaxeUI)
      {
        selectedSprite = null;
      }

      for (spr in spriteArray)
      {
        if (FlxG.mouse.overlaps(spr))
        {
          if (spr.visible && !FlxG.keys.pressed.SHIFT) nameTxt.text = spr.name;

          if (FlxG.mouse.justPressed && allowInput && spr.visible && !FlxG.keys.pressed.SHIFT && !isCursorOverHaxeUI)
          {
            selectedSprite = spr;
          }
        }

        if (spr == selectedSprite)
        {
          infoSelection = spr.name;

          if (FlxG.keys.pressed.SHIFT) nameTxt.text = spr.name + " (LOCKED)";
        }
      }

      if (FlxG.mouse.pressed && allowInput && selectedSprite != null && FlxG.mouse.overlaps(selectedSprite) && FlxG.mouse.justMoved && !isCursorOverHaxeUI)
      {
        saved = false;
        updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);

        if (moveOffset.length == 0)
        {
          this.createAndPushAction(OBJECT_MOVED);

          moveOffset = [
            FlxG.mouse.getWorldPosition().x - selectedSprite.x,
            FlxG.mouse.getWorldPosition().y - selectedSprite.y
          ];
        }

        var posBros = new FlxPoint(FlxG.mouse.getWorldPosition().x - moveOffset[0], FlxG.mouse.getWorldPosition().y - moveOffset[1]);
        selectedSprite.x = (Math.floor(posBros.x) - Math.floor(posBros.x) % moveStep);
        selectedSprite.y = (Math.floor(posBros.y) - Math.floor(posBros.y) % moveStep);
      }

      if (selectedSprite != null && FlxG.keys.pressed.R)
      {
        if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT)
        {
          saved = false;
          this.createAndPushAction(OBJECT_ROTATED);
        }

        if (FlxG.keys.justPressed.LEFT) selectedSprite.angle -= Save.instance.stageEditorAngleStep;
        if (FlxG.keys.justPressed.RIGHT) selectedSprite.angle += Save.instance.stageEditorAngleStep;
      }

      arrowMovement(selectedSprite);

      for (char in getCharacters())
        char.shader = null;
    }
    else
    {
      selectedChar.shader = null;

      for (char in getCharacters())
      {
        if (char != selectedChar) char.shader = charDeselectShader;

        if (char != null && checkCharOverlaps(char)) // flxg.mouse.overlaps crashes the game
        {
          if (char.visible && !FlxG.keys.pressed.SHIFT) nameTxt.text = Std.string(char.characterType);

          if (FlxG.mouse.justPressed && allowInput && char.visible && !FlxG.keys.pressed.SHIFT && !isCursorOverHaxeUI)
          {
            selectedChar = char;
            updateDialog(StageEditorDialogType.CHARACTER);
          }
        }

        if (selectedChar == char)
        {
          infoSelection = Std.string(char.characterType);

          if (FlxG.keys.pressed.SHIFT) nameTxt.text = Std.string(char.characterType) + " (LOCKED)";
        }
      }

      if (FlxG.mouse.pressed && allowInput && checkCharOverlaps(selectedChar) && FlxG.mouse.justMoved && !isCursorOverHaxeUI)
      {
        saved = false;
        updateDialog(StageEditorDialogType.CHARACTER);

        if (moveOffset.length == 0)
        {
          this.createAndPushAction(CHARACTER_MOVED);

          moveOffset = [
            FlxG.mouse.getWorldPosition().x - selectedChar.cornerPosition.x,
            FlxG.mouse.getWorldPosition().y - selectedChar.cornerPosition.y
          ];
        }

        var posBros = new FlxPoint(FlxG.mouse.getWorldPosition().x - moveOffset[0], FlxG.mouse.getWorldPosition().y - moveOffset[1]);

        selectedChar.cornerPosition = new FlxPoint(Math.floor(posBros.x) - Math.floor(posBros.x) % moveStep,
          Math.floor(posBros.y) - Math.floor(posBros.y) % moveStep);
      }

      arrowMovement(selectedChar);
      updateMarkerPos();
    }

    if ((selectedSprite == null && moveMode == "assets") || (selectedChar == null && moveMode == "chars")) infoSelection = "None";
    bottomBarSelectText.text = infoSelection;

    // ui stuff
    nameTxt.x = FlxG.mouse.getViewPosition(camHUD).x;
    nameTxt.y = FlxG.mouse.getViewPosition(camHUD).y - nameTxt.height;

    camMarker.visible = moveMode == "chars";

    for (item in sprDependant)
      item.disabled = (moveMode != "assets" || selectedSprite == null);

    menubarItemPaste.disabled = copiedSprite == null;
    menubarItemFindObj.disabled = !(moveMode == "assets");

    if (moveMode == "chars") findObjDialog.hideDialog(DialogButton.CANCEL);

    menubarItemUndo.disabled = undoArray.length == 0;
    menubarItemRedo.disabled = redoArray.length == 0;
  }

  public function getCharacters()
  {
    return [gf, dad, bf];
  }

  function autosavePerCrash(message:String)
  {
    trace("Crashed the game for the reason: " + message);

    if (!saved)
    {
      trace("You haven't saved recently, so a backup will be made.");
      autoSaveTimer.onComplete(autoSaveTimer);
    }
  }

  function windowClose(exitCode:Int)
  {
    trace("Closing the game window.");

    if (!saved)
    {
      trace("You haven't saved recently, so a backup will be made.");
      autoSaveTimer.onComplete(autoSaveTimer);
    }
  }

  public function updateRecentFiles()
  {
    var files = Save.instance.stageEditorPreviousFiles;
    files.remove(currentFile);
    files.unshift(currentFile);

    while (files.length > Constants.MAX_PREVIOUS_WORKING_FILES)
      files.pop();

    Save.instance.stageEditorPreviousFiles = files;
    Save.instance.flush();
  }

  public function updateMarkerPos()
  {
    for (i in 0...getCharacters().length)
    {
      var char = getCharacters()[i];
      var type = char.characterType;

      charPos.set(type, [
        char.feetPosition.x - char.globalOffsets[0],
        char.feetPosition.y - char.globalOffsets[1]
      ]);

      floorLines[i].y = charPos.get(type)[1] - floorLines[i].height / 2;

      posCircles[i].y = charPos.get(type)[1] - posCircles[i].height / 2;
      posCircles[i].x = charPos.get(type)[0] - posCircles[i].width / 2;

      camFields.members[i].scale.set(1 / stageZoom, 1 / stageZoom);
      camFields.members[i].updateHitbox();

      camFields.members[i].x = char.cameraFocusPoint.x + charCamOffsets.get(type)[0] - camFields.members[i].width / 2;
      camFields.members[i].y = char.cameraFocusPoint.y + charCamOffsets.get(type)[1] - camFields.members[i].height / 2;

      if (char == selectedChar)
      {
        camMarker.x = camFields.members[i].getMidpoint().x - camMarker.width / 2;
        camMarker.y = camFields.members[i].getMidpoint().y - camMarker.height / 2;
      }
    }
  }

  // made because characters have shitty hitboxes and often cause the game to straight up crash
  // it comes from some flxobject/polymod error apparently and I have no idea why
  function checkCharOverlaps(char:BaseCharacter)
  {
    var mouseX = FlxG.mouse.x >= char.x && FlxG.mouse.x <= char.x + char.width;
    var mouseY = FlxG.mouse.y >= char.y && FlxG.mouse.y <= char.y + char.height;

    return mouseX && mouseY && !isCursorOverHaxeUI;
  }

  var moveUndoed:Bool = false;

  // i wish there was a better way to do this this looks like an eyesore
  // yanderedev fr
  function arrowMovement(obj:FlxSprite)
  {
    if (obj == null) return;
    if (FlxG.keys.pressed.R) return; // rotations

    if (allowInput)
    {
      if ((FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT)
        && !moveUndoed)
      {
        saved = false;
        moveUndoed = true;
        this.createAndPushAction(moveMode == "assets" ? OBJECT_MOVED : CHARACTER_MOVED);
      }

      if ((FlxG.keys.justReleased.UP || FlxG.keys.justReleased.DOWN || FlxG.keys.justReleased.LEFT || FlxG.keys.justReleased.RIGHT)
        && moveUndoed)
      {
        moveUndoed = false;
      }

      if (FlxG.keys.pressed.SHIFT)
      {
        if (FlxG.keys.pressed.UP) obj.y--;
        if (FlxG.keys.pressed.DOWN) obj.y++;
        if (FlxG.keys.pressed.LEFT) obj.x--;
        if (FlxG.keys.pressed.RIGHT) obj.x++;
      }
      else
      {
        if (FlxG.keys.justPressed.UP) obj.y -= moveStep;
        if (FlxG.keys.justPressed.DOWN) obj.y += moveStep;
        if (FlxG.keys.justPressed.LEFT) obj.x -= moveStep;
        if (FlxG.keys.justPressed.RIGHT) obj.x += moveStep;
      }
    }
  }

  public function updateArray()
  {
    sortAssets();
    spriteArray = [];

    for (thing in members)
    {
      if (Std.isOfType(thing, StageEditorObject)) spriteArray.push(cast thing); // characters do not extend stageeditorobject so we ball
    }

    findObjDialog.updateIndicator();
  }

  public function sortAssets()
  {
    sort(funkin.util.SortUtil.byZIndex, flixel.util.FlxSort.ASCENDING);
  }

  public function updateDialog(type:StageEditorDialogType)
  {
    if (!dialogs.exists(type)) return;

    dialogs[type].refresh();
  }

  public function toggleDialog(type:StageEditorDialogType, show:Bool = true)
  {
    if (!dialogs.exists(type)) return;

    dialogs[type].toggle(show);
  }

  public function updateWindowTitle()
  {
    var defaultTitle = "Friday Night Funkin\' Stage Editor";

    if (currentFile == "") defaultTitle += " - New File"
    else
      defaultTitle += " - " + currentFile;

    if (!saved) defaultTitle += "*";

    WindowUtil.setWindowTitle(defaultTitle);
  }

  function resetWindowTitle():Void
  {
    WindowUtil.setWindowTitle('Friday Night Funkin\'');
  }

  function updateBGColors():Void
  {
    var colArray = Save.instance.stageEditorTheme == StageEditorTheme.Dark ? DARK_MODE_COLORS : LIGHT_MODE_COLORS;

    var index = members.indexOf(bg);
    bg.kill();
    remove(bg);
    bg.destroy();

    bg = FlxGridOverlay.create(10, 10, -1, -1, true, colArray[0], colArray[1]);
    bg.scrollFactor.set();
    members.insert(index, bg);
  }

  function updateBGSize():Void
  {
    bg.scale.set(1 / FlxG.camera.zoom, 1 / FlxG.camera.zoom);
    bg.updateHitbox();
    bg.screenCenter();
  }

  function checkOverlaps(spr:FlxSprite):Bool
  {
    if (FlxG.mouse.overlaps(spr) /*spr.overlapsPoint(FlxG.mouse.getWorldPosition(spr.camera), true, spr.camera) */
      && Screen.instance != null
      && !Screen.instance.hasSolidComponentUnderPoint(FlxG.mouse.viewX, FlxG.mouse.viewY)
      && WindowManager.instance.windows.length == 0) // ik its stupid but maybe I have other cases soon (i did)
      return true;

    return false;
  }

  var sprDependant:Array<MenuItem> = [];

  function addUI():Void
  {
    menubarItemNewStage.onClick = function(_) onMenuItemClick("new stage");
    menubarItemOpenStage.onClick = function(_) onMenuItemClick("open stage");
    menubarItemSaveStage.onClick = function(_) onMenuItemClick("save stage");
    menubarItemSaveStageAs.onClick = function(_) onMenuItemClick("save stage as");
    menubarItemClearAssets.onClick = function(_) onMenuItemClick("clear assets");
    menubarItemExit.onClick = function(_) onMenuItemClick("exit");
    menubarItemUndo.onClick = function(_) onMenuItemClick("undo");
    menubarItemRedo.onClick = function(_) onMenuItemClick("redo");
    menubarItemCopy.onClick = function(_) onMenuItemClick("copy object");
    menubarItemCut.onClick = function(_) onMenuItemClick("cut object");
    menubarItemPaste.onClick = function(_) onMenuItemClick("paste object");
    menubarItemDelete.onClick = function(_) onMenuItemClick("delete object");
    menubarItemNewObj.onClick = function(_) onMenuItemClick("new object");
    menubarItemFindObj.onClick = function(_) onMenuItemClick("find object");
    menubarButtonText.onClick = function(_) onMenuItemClick("test stage");
    menubarItemUserGuide.onClick = function(_) onMenuItemClick("user guide");
    menubarItemGoToBackupsFolder.onClick = function(_) onMenuItemClick("open folder");
    menubarItemAbout.onClick = function(_) onMenuItemClick("about");

    bottomBarModeText.onClick = function(_) onMenuItemClick("switch mode");
    bottomBarSelectText.onClick = function(_) onMenuItemClick("switch focus");

    var stepOptions = ["1px", "2px", "3px", "5px", "10px", "25px", "50px", "100px"];
    bottomBarMoveStepText.text = stepOptions.contains(Save.instance.stageEditorMoveStep) ? Save.instance.stageEditorMoveStep : "1px";

    var changeStep = function(change:Int = 0) {
      var id = stepOptions.indexOf(bottomBarMoveStepText.text);
      id += change;

      if (id >= stepOptions.length) id = stepOptions.length - 1;
      else if (id < 0) id = 0;

      bottomBarMoveStepText.text = Save.instance.stageEditorMoveStep = stepOptions[id];
      var shit = Std.parseInt(StringTools.replace(bottomBarMoveStepText.text, "px", ""));
      moveStep = shit;

      updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);
      updateDialog(StageEditorDialogType.CHARACTER);
      updateDialog(StageEditorDialogType.STAGE);
    }

    bottomBarMoveStepText.onClick = function(_) changeStep(1);
    bottomBarMoveStepText.onRightClick = function(_) changeStep(-1);

    changeStep(); // update

    var angleOptions = [0.5, 1, 2, 5, 10, 15, 45, 75, 90, 180];
    bottomBarAngleStepText.text = (angleOptions.contains(Save.instance.stageEditorAngleStep) ? Save.instance.stageEditorAngleStep : 5) + "°";

    var changeAngle = function(change:Int = 0) {
      var id = angleOptions.indexOf(Save.instance.stageEditorAngleStep);
      id += change;

      if (id >= angleOptions.length) id = angleOptions.length - 1;
      else if (id < 0) id = 0;

      Save.instance.stageEditorAngleStep = angleOptions[id];
      bottomBarAngleStepText.text = (angleOptions.contains(Save.instance.stageEditorAngleStep) ? Save.instance.stageEditorAngleStep : 5) + "°";

      updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);
    }

    bottomBarAngleStepText.onClick = function(_) changeAngle(1);
    bottomBarAngleStepText.onRightClick = function(_) changeAngle(-1);

    changeAngle(); // update

    dialogs.set(StageEditorDialogType.OBJECT_GRAPHIC, new StageEditorObjectGraphicToolbox(this));
    dialogs.set(StageEditorDialogType.OBJECT_ANIMS, new StageEditorObjectAnimsToolbox(this));
    dialogs.set(StageEditorDialogType.OBJECT_PROPERTIES, new StageEditorObjectPropertiesToolbox(this));
    dialogs.set(StageEditorDialogType.CHARACTER, new StageEditorCharacterToolbox(this));
    dialogs.set(StageEditorDialogType.STAGE, new StageEditorStageToolbox(this));

    menubarItemWindowObjectGraphic.onChange = function(_) toggleDialog(StageEditorDialogType.OBJECT_GRAPHIC, menubarItemWindowObjectGraphic.selected);
    menubarItemWindowObjectAnims.onChange = function(_) toggleDialog(StageEditorDialogType.OBJECT_ANIMS, menubarItemWindowObjectAnims.selected);
    menubarItemWindowObjectProps.onChange = function(_) toggleDialog(StageEditorDialogType.OBJECT_PROPERTIES, menubarItemWindowObjectProps.selected);
    menubarItemWindowCharacter.onChange = function(_) toggleDialog(StageEditorDialogType.CHARACTER, menubarItemWindowCharacter.selected);
    menubarItemWindowStage.onChange = function(_) toggleDialog(StageEditorDialogType.STAGE, menubarItemWindowStage.selected);

    menubarItemThemeLight.onClick = function(_) {
      Save.instance.stageEditorTheme = StageEditorTheme.Light;
      updateBGColors();
    }

    menubarItemThemeDark.onClick = function(_) {
      Save.instance.stageEditorTheme = StageEditorTheme.Dark;
      updateBGColors();
    }

    menubarItemThemeDark.selected = Save.instance.stageEditorTheme == StageEditorTheme.Dark;
    menubarItemThemeLight.selected = Save.instance.stageEditorTheme == StageEditorTheme.Light;

    menubarItemViewChars.onChange = function(_) showChars = menubarItemViewChars.selected;
    menubarItemViewNameText.onChange = function(_) nameTxt.visible = menubarItemViewNameText.selected;
    menubarItemViewCamBounds.onChange = function(_) camFields.visible = menubarItemViewCamBounds.selected;

    menubarItemViewFloorLines.onChange = function(_) {
      for (awesome in floorLines)
        awesome.visible = menubarItemViewFloorLines.selected;
    }

    menubarItemViewPosMarkers.onChange = function(_) {
      for (coolbeans in posCircles)
        coolbeans.visible = menubarItemViewPosMarkers.selected;
    }

    sprDependant = [menubarItemCopy, menubarItemCut, menubarItemDelete];
    reloadRecentFiles();
  }

  function reloadRecentFiles():Void
  {
    for (a in menubarItemOpenRecent.childComponents)
      menubarItemOpenRecent.removeComponent(a);

    for (file in Save.instance.stageEditorPreviousFiles)
    {
      var filePath = new haxe.io.Path(file);
      var item = new MenuItem();
      item.text = filePath.file + "." + filePath.ext;
      item.disabled = !FileUtil.fileExists(file);

      var load = function(file:String) {
        currentFile = file;

        this.unpackShitFromZip(FileUtil.readBytesFromPath(file));

        reloadRecentFiles();
      }

      item.onClick = function(_) {
        if (!saved)
        {
          Dialogs.messageBox("Opening a new Stage will reset all your progress for this Stage.\n\nAre you sure you want to proceed?", "Open Stage",
            MessageBoxType.TYPE_YESNO, true, function(btn:DialogButton) {
              if (btn == DialogButton.YES)
              {
                saved = true;
                load(file);
              }
          });
        }
        else
        {
          load(file);
        }
      }

      menubarItemOpenRecent.addComponent(item);
    }
  }

  public var objNameDialog:NewObjDialog;
  public var findObjDialog:FindObjDialog;
  public var welcomeDialog:WelcomeDialog;
  public var userGuideDialog:UserGuideDialog;
  public var aboutDialog:AboutDialog;
  public var loadUrlDialog:LoadFromUrlDialog;
  public var exitConfirmDialog:Dialog;

  public function onMenuItemClick(item:String):Void
  {
    switch (item.toLowerCase())
    {
      case "undo" | "redo":
        this.performLastAction(item.toLowerCase() == "redo");

      case "save stage as":
        var bytes = this.packShitToZip();

        if (bytes == null)
        {
          notifyChange("Stage Save", "Problem Saving a Stage. Please try again later.", true);
          return;
        }

        FileUtil.saveFile(bytes, [FileUtil.FILE_FILTER_FNFS], function(path:String) {
          saved = true;
          currentFile = path;
        }, null, stageName + "." + FileUtil.FILE_EXTENSION_INFO_FNFS.extension);

      case "save stage":
        if (currentFile == "")
        {
          onMenuItemClick("save stage as"); // ah I love coding shortcuts
          return;
        }

        var bytes = this.packShitToZip();

        if (bytes == null)
        {
          notifyChange("Stage Save", "Problem Saving a Stage. Please try again later.", true);
          return;
        }

        FileUtil.writeBytesToPath(currentFile, bytes, Force); // mhm

        saved = true;

        reloadRecentFiles();

      case "open stage":
        if (!saved)
        {
          Dialogs.messageBox("Opening a new Stage will reset all your progress for this Stage.\n\nAre you sure you want to proceed?", "Open Stage",
            MessageBoxType.TYPE_YESNO, true, function(btn:DialogButton) {
              if (btn == DialogButton.YES)
              {
                saved = true;
                onMenuItemClick("open stage"); // ough
              }
          });

          return;
        }

        FileUtil.browseForBinaryFile("Open Stage Data", [FileUtil.FILE_EXTENSION_INFO_FNFS], function(_) {
          if (_?.fullPath == null) return;

          clearAssets();

          currentFile = _.fullPath;
          this.unpackShitFromZip(FileUtil.readBytesFromPath(currentFile));

          reloadRecentFiles();
        }, function() {
          // This function does nothing, it's there for crash prevention.
        });

      case "exit":
        if (!saved)
        {
          if (exitConfirmDialog == null)
          {
            exitConfirmDialog = Dialogs.messageBox("You are about to leave the Editor without Saving.\n\nAre you sure? ", "Leave Editor",
              MessageBoxType.TYPE_YESNO, true, function(btn:DialogButton) {
                exitConfirmDialog = null;
                if (btn == DialogButton.YES)
                {
                  saved = true;
                  onMenuItemClick("exit");
                }
            });
          }

          return;
        }

        resetWindowTitle();

        WindowUtil.windowExit.remove(windowClose);
        CrashHandler.errorSignal.remove(autosavePerCrash);
        CrashHandler.criticalErrorSignal.remove(autosavePerCrash);

        Cursor.hide();
        FlxG.switchState(() -> new MainMenuState());
        FlxG.sound.music.stop();

      case "switch mode":
        if (testingMode) return;
        moveMode = (moveMode == "assets" ? "chars" : "assets");

        selectedSprite?.selectedShader.setAmount((moveMode == "assets" ? 1 : 0));

      case "switch focus":
        if (testingMode)
        {
          curTestChar++;
        }
        else
        {
          if (moveMode == "chars")
          {
            var chars = getCharacters();
            var index = chars.indexOf(selectedChar);
            index++;

            if (index >= chars.length) index = 0;

            selectedChar = chars[index];
          }
          else
          {
            if (selectedSprite == null) return;

            var index = spriteArray.indexOf(selectedSprite);
            index++;

            if (index >= spriteArray.length) index = 0;

            selectedSprite = spriteArray[index];
          }
        }

      case "new object":
        findObjDialog.hideDialog(DialogButton.CANCEL);

        trace("aignt we making a new object baby");

        objNameDialog = new NewObjDialog(this);
        objNameDialog.showDialog();

        objNameDialog.onDialogClosed = function(_) {
          objNameDialog = null;
        }

      case "find object":
        findObjDialog.hideDialog(DialogButton.CANCEL);
        findObjDialog = new FindObjDialog(this, selectedSprite == null ? "" : selectedSprite.name);
        findObjDialog.showDialog(false);

      case "about":
        aboutDialog = new AboutDialog();
        aboutDialog.showDialog();

      case "user guide":
        userGuideDialog = new UserGuideDialog();
        userGuideDialog.showDialog();

        userGuideDialog.onDialogClosed = function(_) {
          userGuideDialog = null;
        }

      case "open folder":
        #if sys
        var absoluteBackupsPath:String = haxe.io.Path.join([Sys.getCwd(), BACKUPS_PATH]);
        FileUtil.openFolder(absoluteBackupsPath);
        #end

      case "test stage":
        if (!allowInput) return;

        camFollow.velocity.set();

        for (a in spriteArray)
        {
          a.active = true;
          a.isDebugged = testingMode;
        }

        if (!testingMode)
        {
          menubarItemWindowObjectGraphic.selected = menubarItemWindowObjectAnims.selected = menubarItemWindowObjectProps.selected = menubarItemWindowCharacter.selected = menubarItemWindowStage.selected = false;
        }

        selectedSprite?.selectedShader.setAmount((testingMode ? (moveMode == "assets" ? 1 : 0) : 0));
        testingMode = !testingMode;

      case "clear assets":
        Dialogs.messageBox("This will destroy all Objects in this Stage.\n\nAre you sure? This cannot be undone.", "Clear Assets", MessageBoxType.TYPE_YESNO,
          true, function(btn:DialogButton) {
            if (btn == DialogButton.YES)
            {
              clearAssets();
              saved = false;

              updateDialog(StageEditorDialogType.OBJECT_GRAPHIC);
              updateDialog(StageEditorDialogType.OBJECT_ANIMS);
              updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);
            }
        });

      case "center on screen":
        if (selectedSprite != null && moveMode == "assets")
        {
          selectedSprite.screenCenter();
          updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);
          saved = false;
        }

        if (selectedChar != null && moveMode == "chars")
        {
          selectedChar.screenCenter();
          updateDialog(StageEditorDialogType.CHARACTER);
          saved = false;
        }

      case "delete object":
        if (selectedSprite == null) return;

        this.createAndPushAction(OBJECT_DELETED);

        spriteArray.remove(selectedSprite);

        selectedSprite.kill();
        remove(selectedSprite, true);
        selectedSprite.destroy();
        selectedSprite = null;

        updateArray();

      case "copy object":
        if (selectedSprite == null) return;

        copiedSprite = selectedSprite.toData(true);

      case "paste object":
        if (copiedSprite == null) return;

        saved = false;
        var spr = new StageEditorObject().fromData(copiedSprite);

        var objNames = [for (a in spriteArray) a.name];

        if (objNames.contains(spr.name))
        {
          var i = 1;
          while (objNames.contains(spr.name + " (" + i + ")"))
            i++;

          spr.name += " (" + i + ")";
        }

        add(spr);
        selectedSprite = spr;
        updateArray();

      case "cut object": // rofl
        onMenuItemClick("copy object");
        onMenuItemClick("delete object"); // already changes the saved var

      case "new stage":
        if (menubarItemWindowObjectGraphic.selected) menubarItemWindowObjectGraphic.selected = false;
        if (menubarItemWindowObjectAnims.selected) menubarItemWindowObjectAnims.selected = false;
        if (menubarItemWindowObjectProps.selected) menubarItemWindowObjectProps.selected = false;
        if (menubarItemWindowCharacter.selected) menubarItemWindowCharacter.selected = false;
        if (menubarItemWindowStage.selected) menubarItemWindowStage.selected = false;

        welcomeDialog = new WelcomeDialog(this);
        welcomeDialog.showDialog();
        welcomeDialog.closable = true;
        welcomeDialog.onDialogClosed = function(_) {
          updateWindowTitle();
          welcomeDialog = null;

          updateDialog(StageEditorDialogType.OBJECT_GRAPHIC);
          updateDialog(StageEditorDialogType.OBJECT_ANIMS);
          updateDialog(StageEditorDialogType.OBJECT_PROPERTIES);
          updateDialog(StageEditorDialogType.CHARACTER);
          updateDialog(StageEditorDialogType.STAGE);
        }
    }
  }

  public function clearAssets()
  {
    selectedSprite = null;

    while (spriteArray.length > 0)
    {
      var spr = spriteArray.pop();
      spr.kill();
      remove(spr, true);
      spr.destroy();
      spr = null;
    }

    undoArray = [];
    redoArray = [];
    updateArray();
    removeUnusedBitmaps();
  }

  public function removeUnusedBitmaps()
  {
    var usedBitmaps:Array<String> = [];

    for (asset in spriteArray)
    {
      var data = asset.toData(false);
      if (data.assetPath.startsWith("#")) continue; // the simple graphics

      usedBitmaps.push(data.assetPath);
    }

    for (name => bit in bitmaps)
    {
      if (usedBitmaps.contains(name)) continue;
      bitmaps.remove(name);
    }
  }

  public function addBitmap(newBitmap:BitmapData):String
  {
    // first we check for existing bitmaps so we dont like add an extra one
    for (name => bitmap in bitmaps)
    {
      if (bitmap == newBitmap) return name;
    }

    var id:Int = 0;
    while (bitmaps.exists("image" + id))
      id++;

    bitmaps.set("image" + id, newBitmap);
    return "image" + id;
  }

  public function notifyChange(change:String, notif:String, isError:Bool = false)
  {
    NotificationManager.instance.addNotification(
      {
        title: change,
        body: notif,
        type: isError ? NotificationType.Error : NotificationType.Info
      });
  }

  public function createURLDialog(onComplete:lime.utils.Bytes->Void = null, onFail:String->Void = null)
  {
    loadUrlDialog = new LoadFromUrlDialog(onComplete, onFail);
    loadUrlDialog.onDialogClosed = function(_) {
      loadUrlDialog = null;
    }

    loadUrlDialog.showDialog();
  }
}

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
   * A theme which introduces stage colors.
   */
  var Dark;
}

enum StageEditorDialogType
{
  /**
   * The Stage Options Dialog.
   */
  STAGE;

  /**
   * The Character Options Dialog.
   */
  CHARACTER;

  /**
   * The Object Graphic Options Dialog.
   */
  OBJECT_GRAPHIC;

  /**
   * The Object Animations Options Dialog.
   */
  OBJECT_ANIMS;

  /**
   * The Object Properties Options Dialog.
   */
  OBJECT_PROPERTIES;
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
