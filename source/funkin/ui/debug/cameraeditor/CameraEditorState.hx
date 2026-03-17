package funkin.ui.debug.cameraeditor;

#if FEATURE_CAMERA_EDITOR
import haxe.ui.containers.Panel;
import haxe.ui.containers.Panel;
import haxe.ui.focus.FocusManager;
import funkin.data.song.SongData.SongEventData;
import flixel.FlxCamera;
import funkin.graphics.FunkinCamera;
import flixel.math.FlxMath;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import funkin.data.song.SongData.SongEventData;
import flixel.FlxObject;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import funkin.audio.FunkinSound;
import funkin.data.event.SongEventRegistry;
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.importer.ChartManifestData;
import funkin.data.stage.StageRegistry;
import funkin.input.Cursor;
import funkin.play.PlayState;
import funkin.play.character.BaseCharacter;
import funkin.play.stage.Stage;
import funkin.save.Save;
import funkin.ui.debug.cameraeditor.commands.CameraEditorCommand;
import funkin.ui.haxeui.components.editors.timeline.TimelineEvent;
import funkin.ui.haxeui.components.editors.timeline.TimelineUtil;
import funkin.data.song.SongData.SongEventDataRaw;
import funkin.ui.debug.cameraeditor.commands.AddEventCommand;
import funkin.ui.debug.cameraeditor.commands.MoveResizeEventCommand;
import funkin.ui.debug.cameraeditor.commands.RemoveEventCommand;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorCommandHandler;
import funkin.ui.debug.cameraeditor.components.AboutDialog;
import funkin.ui.debug.cameraeditor.components.UploadChartDialog;
import funkin.ui.debug.cameraeditor.components.UserGuideDialog;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorImportExportHandler;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorNotificationHandler;
import funkin.ui.debug.stageeditor.handlers.AssetDataHandler;
import funkin.ui.mainmenu.MainMenuState;
import funkin.util.FileUtil;
import funkin.util.MouseUtil;
import funkin.util.WindowUtil;
import funkin.util.assets.SoundUtil;
import funkin.util.logging.CrashHandler;
import funkin.util.macro.ConsoleMacro;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.Panel;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuOptionBox;
import haxe.ui.containers.windows.WindowManager;
import haxe.ui.core.Screen;
import haxe.ui.events.MouseEvent;
import haxe.ui.focus.FocusManager;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;

import funkin.play.PlayState;
import funkin.play.character.BaseCharacter;
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.data.stage.StageRegistry;
import funkin.play.stage.Stage;

import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;

/**
 * The EYES OF GOD......
 */
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/camera-editor/main-view.xml"))
class CameraEditorState extends UIState implements ConsoleClass
{
  /**
   * CONSTANTS
   */
  // ==============================

  /**
   * The path to save backups to, when the editor is closed unexpectedly.
   */
  public static final BACKUPS_PATH:String = "./backups/camera/";

  /**
   * The current instance of the Camera Editor.
   */
  public static var instance:CameraEditorState = null;

  /**
   * INSTANCE DATA
   */
  // ==============================
  public var currentVariation:String = Constants.DEFAULT_VARIATION;

  public var songDatas:Map<String, SongChartData> = new Map<String, SongChartData>();
  public var songMetadatas:Map<String, SongMetadata> = new Map<String, SongMetadata>();

  public var currentSongMetadata(get, never):Null<SongMetadata>;
  public var currentSongChartData(get, never):Null<SongChartData>;

  public var currentInstrumental:Null<FunkinSound> = null;
  public var currentVocals:Array<FunkinSound> = [];

  public var cameraRect:FlxSprite = new FlxSprite();

  public var vcamPoint:Null<FlxPoint> = null;

  function get_currentSongMetadata():Null<SongMetadata>
  {
    return songMetadatas.get(currentVariation);
  }

  function get_currentSongChartData():Null<SongChartData>
  {
    return songDatas.get(currentVariation);
  }

  public var currentStage:Null<Stage> = null;

  // Song chart data we have to hold onto just to save properly later.
  public var songManifestData:Null<ChartManifestData> = null;
  public var audioInstTrackData:Map<String, Bytes> = [];
  public var audioVocalTrackData:Map<String, Bytes> = [];

  public var selectedSongEvent(default, set):Null<SongEventData> = null;

  function set_selectedSongEvent(value:Null<SongEventData>):Null<SongEventData>
  {
    if (value == null && selectedSongEvent == null) return value;
    if (value != null && selectedSongEvent != null && value == selectedSongEvent) return value;

    selectedSongEvent = value;
    CameraEditorPropertiesPanelHandler.loadSelectedSongEvent(this);

    return value;
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
    updateWindowTitle();
    populateOpenRecentMenu();
    applyCanQuickSave();
    return value;
  }

  /**
   * The current file path which the chart editor is working with.
   * If `null`, the current chart has not been saved yet.
   */
  public var currentWorkingFilePath(get, set):Null<String>;

  function get_currentWorkingFilePath():Null<String>
  {
    return previousWorkingFilePaths[0];
  }

  function set_currentWorkingFilePath(value:Null<String>):Null<String>
  {
    // Do nothing if the value hasn't changed.
    if (value == previousWorkingFilePaths[0]) return value;

    // Update the recent files list.

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
    updateWindowTitle();

    return value;
  }

  /**
   * Whether the current chart being worked on has been modified since it was last saved.
   */
  public var saved(default, set):Bool = true;

  function set_saved(value:Bool):Bool
  {
    saved = value;

    updateWindowTitle();

    if (!saved)
    {
      if (autoSaveTimer == null) autoSaveTimer = new FlxTimer();

      if (!autoSaveTimer.finished)
      {
        autoSaveTimer.cancel();
      }

      autoSaveTimer.start(Constants.AUTOSAVE_TIMER_DELAY_SEC, function(tmr:FlxTimer) {
        saveBackup();
      });
    }

    return value;
  }

  /**
   * The path to the current file being operated on.
   */
  public var currentFile(default, set):String = "";

  function set_currentFile(value:String):String
  {
    currentFile = value;

    updateWindowTitle();

    // TODO: Update list of recent files to include this file.

    return value;
  }

  @:bind(menubarItemRelativeView.selected)
  var isCameraRelative:Bool = false;

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
   * Set by CameraEditorDialogHandler, used to prevent background interaction while a dialog is open.
   */
  var isHaxeUIDialogOpen:Bool = false;

  /**
   * The camera that the HUD is rendered to.
   */
  var camHUD:FlxCamera;

  /**
   * The camera that the game underneath the HUD is rendered to.
   */
  var camGame:FlxCamera;

  /**
   * HAXEUI COMPONENTS
   */
  // ==============================

  /**
   * The User Guide dialog, opened from the menu bar.
   */
  public var userGuideDialog:UserGuideDialog;

  /**
   * The About dialog, opened from the menu bar.
   */
  public var aboutDialog:AboutDialog;

  /**
   * The dialog which warns the user that they are about to leave the editor without saving.
   */
  public var exitConfirmDialog:Dialog;

  /**
   * The properties panel on the right side.
   * Holds the properties container, which gets swapped when a different event type is selected.
   */
  var propertiesPanel:Panel;

  // Auto-save

  /**
   * A timer used to auto-save the chart after a period of inactivity.
   */
  var autoSaveTimer:Null<FlxTimer> = null;

  // History

  /**
   * The list of command previously performed. Used for undoing previous actions.
   */
  var undoHistory:Array<CameraEditorCommand> = [];

  /**
   * The list of commands that have been undone. Used for redoing previous actions.
   */
  var redoHistory:Array<CameraEditorCommand> = [];

  // Parameters

  /**
   * The params which were passed in when the Camera Editor was initialized.
   */
  var params:Null<CameraEditorParams>;

  /**
   * Whether the undo/redo histories have changed since the last time the UI was updated.
   */
  var commandHistoryDirty:Bool = true;

  /**
   * If true, we are currently in the process of quitting the chart editor.
   * Skip any update functions as most of them will call a crash.
   */
  var criticalFailure:Bool = false;

  var songEvents:Array<SongEventData> = [];

  var addEventMenu:AddEventMenu;

  /**
   * LIFE CYCLE FUNCTIONS
   */
  // ==============================

  public function new(?params:CameraEditorParams)
  {
    super();
    this.params = params;
  }

  public override function create():Void
  {
    cameraRect = new FlxSprite();
    cameraRect.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLUE);
    cameraRect.alpha = 0.5;

    WindowManager.instance.reset();
    instance = this;
    FlxG.sound.music?.stop();
    WindowUtil.setWindowTitle("Friday Night Funkin\' Camera Editor");

    loadPreferences();

    camGame = new FlxCamera();
    camHUD = new FlxCamera();
    camHUD.bgColor.alpha = 0;

    FlxG.cameras.reset(camGame);
    FlxG.cameras.add(camHUD, false);
    FlxG.cameras.setDefaultDrawTarget(camGame, true);

    persistentUpdate = false;

    super.create();
    root.scrollFactor.set();
    root.cameras = [camHUD];
    root.width = FlxG.width;
    root.height = FlxG.height;

    menubar.height = 35;
    WindowManager.instance.container = root;
    Screen.instance.addComponent(root);

    CameraEditorNotificationHandler.setupNotifications(this);
    applyCanQuickSave();

    WindowUtil.windowExit.add(windowClose);
    CrashHandler.errorSignal.add(autosavePerCrash);
    CrashHandler.criticalErrorSignal.add(autosavePerCrash);

    // Save.instance.cameraEditorHasBackup.value = false;

    Cursor.show();
    FunkinSound.playMusic('chartEditorLoop',
      {
        startingVolume: 0.0
      });
    FlxG.sound.music.fadeIn(10, 0, 1);

    registerTimelineEvents();

    addEventMenu = new AddEventMenu(function(eventData)
    {
      var cmd = new AddEventCommand(eventData);
      CameraEditorCommandHandler.performCommand(this, cmd);
      selectedSongEvent = eventData;
    });

    add(cameraRect);
    cameraRect.zIndex = 5999;

    vcamPoint = new FlxPoint();

    this.hidePropertiesPanel();
  }

  var goToPoint:FlxPoint = new FlxPoint();
  var cameraFollowPoint:FlxObject = new FlxObject();
  var lastVCamPoint:FlxPoint = new FlxPoint();

  var previousTime:Float = 0;

  public function setFocusPoint(x:Float, y:Float, force:Bool = false):Void
  {
    lastVCamPoint.copyFrom(vcamPoint);
    vcamPoint.set(lastVCamPoint.x, lastVCamPoint.y);
    cameraFollowPoint.x = x;
    cameraFollowPoint.y = y;
    _scrollTarget.set(cameraFollowPoint.x - cameraRect.width / 2, cameraFollowPoint.y - cameraRect.height / 2);
    if (force) vcamPoint.copyFrom(_scrollTarget);
  }

  /**
   * Process song events for the current chart.
   * This never removes them as we need to maybe reprocess events depending on the time of the song.
   * EX: Reversing the song time should re-trigger events that were already triggered.
   */
  public function processEvents():Void
  {
    if (songEvents == null || songEvents.length == 0) return;
    var songEventsToActivate:Array<SongEventData> = SongEventRegistry.queryEvents(songEvents, Conductor.instance.songPosition);
    for (eventData in songEventsToActivate)
    {
      if (eventData == null || eventData.time < previousTime) continue;
      trace('Processing event: ' + eventData.eventKind + ' at ' + eventData.time);

      switch (eventData.eventKind)
      {
        case "FocusCamera":
          var x:Null<Float> = eventData.getFloat('x');
          var y:Null<Float> = eventData.getFloat('y');
          var char:Null<Int> = eventData.getInt('char');
          var offsetX:Float = 0;
          var offsetY:Float = 0;
          if (x != null && y != null)
          {
            offsetX = x;
            offsetY = y;
          }

          if (char == null) char = cast eventData.value;

          if (char != null)
          {
            if (char == -1)
            {
              cameraFollowPoint.x = offsetX;
              cameraFollowPoint.y = offsetY;
              break;
            }

            trace('Focusing camera on character: ' + char + ' with offset: (' + offsetX + ', ' + offsetY + ')');

            switch (char)
            {
              case 0:
                var bf = currentStage.getBoyfriend();
                if (bf != null)
                {
                  setFocusPoint(bf.cameraFocusPoint.x + offsetX, bf.cameraFocusPoint.y + offsetY);
                }
              case 1:
                var dad = currentStage.getDad();
                if (dad != null)
                {
                  setFocusPoint(dad.cameraFocusPoint.x + offsetX, dad.cameraFocusPoint.y + offsetY);
                }
              case 2:
                var gf = currentStage.getGirlfriend();
                if (gf != null)
                {
                  setFocusPoint(gf.cameraFocusPoint.x + offsetX, gf.cameraFocusPoint.y + offsetY);
                }
            }
            trace('    Camera follow point set to: (' + cameraFollowPoint.x + ', ' + cameraFollowPoint.y + ')');
          }
      }
    }

    previousTime = Conductor.instance.songPosition;
  }

  var _scrollTarget:FlxPoint = new FlxPoint();
  var _cameraTarget:FlxPoint = new FlxPoint();

  public override function update(elapsed:Float):Void
  {
    if (currentStage != null)
    {
      currentStage.vcamPoint = vcamPoint;
      currentStage.offset.x = FlxG.camera.scroll.x;
      currentStage.offset.y = FlxG.camera.scroll.y;
    }

    // TODO: sync vocals if they desync, im just too lazy to put this in rn
    if (currentInstrumental != null && currentInstrumental.playing)
    {
      final adjustedLerp = 1.0 - Math.pow(1.0 - Constants.DEFAULT_CAMERA_FOLLOW_RATE, elapsed * 60);

      // lerp vcamPoint to cameraFollowPoint
      vcamPoint.x += (_scrollTarget.x - vcamPoint.x) * adjustedLerp;
      vcamPoint.y += (_scrollTarget.y - vcamPoint.y) * adjustedLerp;

      Conductor.instance.update();
      processEvents();
      timeline.songPosition = Conductor.instance.songPosition;
    }
    else if (currentVocals.length > 0 && currentVocals[0].playing)
    {
      for (vocal in currentVocals)
        if (vocal.playing) vocal.pause();
    }

    // Save the stage if exiting through the F4 keybind, as it moves you to the Main Menu.
    if (FlxG.keys.justPressed.F4)
    {
      @:privateAccess
      if (autoSaveTimer != null && !autoSaveTimer.finished) autoSaveTimer.onLoopFinished();
      resetWindowTitle();

      WindowUtil.windowExit.remove(windowClose);
      CrashHandler.errorSignal.remove(autosavePerCrash);
      CrashHandler.criticalErrorSignal.remove(autosavePerCrash);

      Cursor.hide();
      FlxG.sound.music.stop();
      return;
    }

    conductorInUse.update();

    super.update(elapsed);

    // MouseUtil.mouseWheelZoom(0.08);

    // DEBUG!!! enable to move the vcam with the mouse... teehee

    /*if (FlxG.mouse.pressed)
    {
      cameraFollowPoint.x += FlxG.mouse.deltaX;
      cameraFollowPoint.y += FlxG.mouse.deltaY;
      vcamPoint.set(cameraFollowPoint.x, cameraFollowPoint.y);
    }*/

    if (FlxG.mouse.pressedMiddle)
    {
      goToPoint.x -= FlxG.mouse.deltaX;
      goToPoint.y -= FlxG.mouse.deltaY;
      _cameraTarget.x = FlxMath.lerp(_cameraTarget.x, goToPoint.x, 0.8);
      _cameraTarget.y = FlxMath.lerp(_cameraTarget.y, goToPoint.y, 0.8);
    }

    FlxG.camera.scroll.copyFrom(_cameraTarget);

    if (!isCameraRelative)
    {
      // subtract the vcam point since it moves everything
      FlxG.camera.scroll.x -= vcamPoint.x;
      FlxG.camera.scroll.y -= vcamPoint.y;
    }


    if (FlxG.keys.justPressed.SPACE) onPlayPause(null);
    if (FlxG.keys.justPressed.R) onStopPlayback(null);
    if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.A) addEventMenu.show(FlxG.mouse.viewX, FlxG.mouse.viewY);

    if (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickDown"));
    if (FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickUp"));

    this.updatePropertiesPanel(elapsed);

    // DEBUG
    if (FlxG.keys.justPressed.ONE)
    {
    }
    if (FlxG.keys.justPressed.TWO)
    {
    }
    if (FlxG.keys.justPressed.ZERO)
    {
      this.hidePropertiesPanel();
    }
  }

  /**
   * Builds the current stage based on the current song metadata.
   */
  public function buildStage():Void
  {
    // vcamPoint.copyFrom(camGame.scroll);
    remove(cameraRect);
    if (currentSongMetadata == null) return;
    var stageID = currentSongMetadata.playData.stage;

    previousTime = 0;
    songEvents = currentSongChartData.events;

    if (currentStage != null)
    {
      currentStage.onDestroy(null);
      remove(currentStage);
      currentStage = null;
    }

    currentStage = StageRegistry.instance.fetchEntry(stageID);

    currentStage.revive();

    var campaignId:String = Stage.getCampaignID(stageID);

    Paths.setCurrentLevel(campaignId);

    add(currentStage);
    currentStage.vcamPoint = vcamPoint;
    currentStage.onCreate(null);

    var songCharacterData = currentSongMetadata.playData.characters;

    if (songCharacterData == null) return;

    var gf:Null<BaseCharacter> = CharacterDataParser.fetchCharacter(songCharacterData.girlfriend);

    var dad:Null<BaseCharacter> = CharacterDataParser.fetchCharacter(songCharacterData.opponent);

    var bf:Null<BaseCharacter> = CharacterDataParser.fetchCharacter(songCharacterData.player);

    FlxG.camera.filters = [];

    var buildChar:Null<BaseCharacter>->CharacterType->Void = (char, charType) -> {
      if (char == null) return;

      char.currentStage = currentStage;
      char.debug = true;
      currentStage.addCharacter(char, charType);
      char.onCreate(null);
      char.onUpdate(null);
    };

    buildChar(gf, GF);
    buildChar(bf, BF);
    buildChar(dad, DAD);

    currentStage.refresh();
    goToPoint.x = 0;
    goToPoint.y = 0;
    FlxG.camera.scroll.x = 0;
    FlxG.camera.scroll.y = 0;
    trace("Built stage: " + stageID);
    add(cameraRect);

    var camZoom:Float = currentStage.camZoom;

    // Set zoom for camera rect
    cameraRect.scale.set(1.0 / camZoom, 1.0 / camZoom);
    trace('Set camera rect zoom to: ' + camZoom);

    resetScrollPosition();
  }

  function resetScrollPosition()
  {
    if (currentStage == null) return;

    var dad = currentStage.getDad();
    if (dad != null && dad.cameraFocusPoint != null) setFocusPoint(dad.cameraFocusPoint.x, dad.cameraFocusPoint.y, true);
  }

  function autosavePerCrash(message:String)
  {
    trace("Crashed the game for the reason: " + message);

    if (!saved)
    {
      trace("You haven't saved recently, so a backup will be made.");
      saveBackup();
    }

    writePreferences(!saved);
  }

  function windowClose(exitCode:Int)
  {
    trace("Closing the game window.");

    if (!saved)
    {
      trace("You haven't saved recently, so a backup will be made.");
      saveBackup();
    }

    writePreferences(!saved);
  }

  /**
   * Updates the list of recently opened charts in the `File->Open Recent` menu.
   */
  public function populateOpenRecentMenu():Void
  {
    if (menubarOpenRecent == null) return;

    #if sys
    menubarOpenRecent.removeAllComponents();

    for (chartPath in previousWorkingFilePaths)
    {
      if (chartPath == null) continue;

      var menuItemRecentChart:MenuItem = new MenuItem();
      menuItemRecentChart.text = chartPath;
      menuItemRecentChart.onClick = onMenubarOpenRecent.bind(_, chartPath);

      if (!FileUtil.fileExists(chartPath))
      {
        trace('Previously loaded chart file (${chartPath.toString()}) does not exist, disabling link...');
        menuItemRecentChart.disabled = true;
      }
      else
      {
        menuItemRecentChart.disabled = false;
      }

      menubarOpenRecent.addComponent(menuItemRecentChart);
    }
    #else
    menubarOpenRecent.hide();
    #end
  }

  /**
   * Modify the title of the game window to reflect the current state of the editor.
   */
  public function updateWindowTitle()
  {
    var defaultTitle = "Friday Night Funkin\' Camera Editor";

    if (currentWorkingFilePath == "") defaultTitle += " - New File"
    else
      defaultTitle += " - " + currentWorkingFilePath;

    if (!saved) defaultTitle += "*";

    WindowUtil.setWindowTitle(defaultTitle);
  }

  /**
   * Only enable the "Save Chart" menu item if a chart already on disk is loaded.
   */
  function applyCanQuickSave():Void
  {
    if (menubarItemSave == null) return;

    if (currentWorkingFilePath == null)
    {
      menubarItemSave.disabled = true;
    }
    else
    {
      menubarItemSave.disabled = false;
    }
  }

  function resetWindowTitle():Void
  {
    WindowUtil.setWindowTitle('Friday Night Funkin\'');
  }

  function saveBackup()
  {
    FileUtil.createDirIfNotExists(BACKUPS_PATH);

    CameraEditorImportExportHandler.saveFNFCToPath(this, true, null, function(path:String) {
      notifyChange("Auto-Save", "A Backup of this Chart has been made.");
    }, function() {
      // Failed to save backup?
    });
  }

  /**
   * Read preferences for the Camera Editor from the user's save data.
   */
  public function loadPreferences():Void
  {
    var save:Save = Save.instance;

    if (previousWorkingFilePaths[0] == null)
    {
      previousWorkingFilePaths = [null].concat(save.cameraEditorPreviousFiles.value);
    }
    else
    {
      previousWorkingFilePaths = [currentWorkingFilePath].concat(save.cameraEditorPreviousFiles.value);
    }
  }

  /**
   * Write preferences for the Camera Editor to the user's save data.
   */
  public function writePreferences(hasBackup:Bool):Void
  {
    var save:Save = Save.instance;

    // Can't use filter() because of null safety checking!
    trace('Saving previous files: ${previousWorkingFilePaths.toString()}');
    var filteredWorkingFilePaths:Array<String> = [];
    for (chartPath in previousWorkingFilePaths)
      if (chartPath != null) filteredWorkingFilePaths.push(chartPath);
    save.cameraEditorPreviousFiles.value = filteredWorkingFilePaths;

    if (hasBackup) trace('Queuing backup prompt for next time!');
    save.cameraEditorHasBackup.value = hasBackup;

    // save.cameraEditorTheme.value = currentTheme;
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

  /**
   * Select a song event from the current chart data by its index.
   * @param index The index of the event to select.
   */
  public function selectSongEventByIndex(index:Int):Void
  {
    var selectedEvent:SongEventData = currentSongChartData.events[index];
    this.selectedSongEvent = selectedEvent;
  }

  /**
   * Ensure everything gets populated once the `songData` is loaded from a chart.
   */
  public function onChartLoaded():Void
  {
    loadCurrentInstrumentalAndVocals();
    buildStage();
    updateWindowTitle();
    loadTimeline();
  }

  /**
   * Loads all the events into the timeline so it can display and edit them.
   */
  public function loadTimeline():Void
  {
    timeline.setEvents(currentSongChartData.events);
    timeline.setStepLengthMs(Conductor.instance.stepLengthMs);
  }

  function registerTimelineEvents():Void
  {
    timeline.viewport.registerEvent(TimelineEvent.EVENT_SELECTED, (e:TimelineEvent) -> selectedSongEvent = e.eventData);
    timeline.viewport.registerEvent(TimelineEvent.SEEK, (e:TimelineEvent) -> setTimePosition(e.seekPositionMs));

    timeline.viewport.registerEvent(TimelineEvent.EVENT_MOVED, function(e:TimelineEvent)
    {
      var cmd = new MoveResizeEventCommand(
        e.eventData,
        e.oldTime, TimelineUtil.getEventDurationSteps(e.eventData), e.oldLayerName,
        e.newTime, TimelineUtil.getEventDurationSteps(e.eventData), e.newLayerName
      );
      CameraEditorCommandHandler.performCommand(this, cmd);
    });

    timeline.viewport.registerEvent(TimelineEvent.EVENT_RESIZED, function(e:TimelineEvent)
    {
      var raw:SongEventDataRaw = e.eventData;
      var layerName = raw.editorLayer != null ? raw.editorLayer : "Default";
      var cmd = new MoveResizeEventCommand(
        e.eventData,
        e.eventData.time, e.oldDuration, layerName,
        e.eventData.time, e.newDuration, layerName
      );
      CameraEditorCommandHandler.performCommand(this, cmd);
    });

    timeline.toolbar.findComponent("btnTogglePlayback").registerEvent(MouseEvent.CLICK, _ -> togglePlayback());
  }

  /**
   * Loads the current instrumental and vocal tracks based on the current variation and song metadata.
   */
  public function loadCurrentInstrumentalAndVocals():Void
  {
    if (currentSongMetadata == null) return;
    if (audioInstTrackData == null) return;
    if (audioInstTrackData.get(currentVariation) == null) return;

    currentInstrumental?.stop();
    currentInstrumental?.destroy();
    currentInstrumental = null;

    for (vocal in currentVocals)
    {
      vocal.stop();
      vocal.destroy();
    }

    currentVocals = [];

    trace('Loading instrumental for variation: ' + currentVariation);

    var instData:Null<Bytes> = audioInstTrackData.get(currentVariation);
    if (instData != null) currentInstrumental = SoundUtil.buildSoundFromBytes(instData);

    trace('Loading vocals');

    var buildVocal:Null<String>->Null<Array<String>>->Void = function(character, vocals) {
      var vocal = character;
      if (vocals != null && vocals.length > 0) vocal = vocals[0];

      var vocalData:Null<Bytes> = audioVocalTrackData.get('$currentVariation-$vocal');
      if (vocalData != null)
      {
        var vocalSound = SoundUtil.buildSoundFromBytes(vocalData);
        currentVocals.push(vocalSound);
      }
    };

    var currentCharactersData:Null<SongCharacterData> = currentSongMetadata?.playData?.characters;
    buildVocal(currentCharactersData?.player, currentCharactersData?.playerVocals);
    buildVocal(currentCharactersData?.opponent, currentCharactersData?.opponentVocals);

    trace('    Instrumental:' + (currentInstrumental != null ? ' Loaded' : ' Missing'));
    trace('    Vocals: ' + currentVocals.length + ' loaded');

    if (FlxG.sound.music != null && FlxG.sound.music.playing)
    {
      FlxG.sound.music.stop();
      FlxG.sound.music = null;
    }

    FlxG.sound.music = currentInstrumental;

    Conductor.instance.forceBPM(null);
    Conductor.instance.instrumentalOffset = currentSongMetadata.offsets.instrumental;
    Conductor.instance.mapTimeChanges(currentSongMetadata.timeChanges);
    timeline.songLength = currentInstrumental.length;
    timeline.songPosition = 0;
    timeline.setStepLengthMs(Conductor.instance.stepLengthMs);
  }

  /**
   * Toggles playback of the current instrumental and vocal tracks.
   */
  public function togglePlayback(forceStop:Bool = false):Void
  {
    if (currentInstrumental == null) return;

    if (currentInstrumental.playing || forceStop) pauseAudioPlayback();
    else
      playAudioPlayback();

    trace(currentInstrumental.playing ? "Toggled playback ON" : "Toggled playback OFF");
  }

  function playAudioPlayback():Void
  {
    if (currentInstrumental == null) return;

    currentInstrumental.play();
    for (vocal in currentVocals)
    {
      vocal.time = currentInstrumental.time;
      vocal.play();
    }
    timeline.isPlaying = true;
  }

  function pauseAudioPlayback():Void
  {
    if (currentInstrumental == null) return;

    currentInstrumental.pause();
    for (vocal in currentVocals)
    {
      vocal.pause();
    }
    timeline.isPlaying = false;
  }

  /**
   * Sets the time position of the current instrumental and vocal tracks.
   */
  public function setTimePosition(position:Float):Void
  {
    if (currentInstrumental == null) return;

    currentInstrumental.time = position;
    for (vocal in currentVocals)
    {
      vocal.time = position;
    }

    Conductor.instance.update(currentInstrumental.time);
    timeline.songPosition = Conductor.instance.songPosition;
  }

  // ui function bindings

  @:bind(menubarItemOpen, MouseEvent.CLICK)
  function onMenubarOpen(_)
  {
    var uploadDialog = new UploadChartDialog(this);
    uploadDialog.showDialog();
  }

  function onMenubarOpenRecent(_event:MouseEvent, chartPath:String)
  {
    var result:Bool = CameraEditorImportExportHandler.loadFNFCFromPath(this, chartPath);

    if (result)
    {
      CameraEditorNotificationHandler.success(this, 'Loaded Chart', 'Loaded chart (${chartPath})');
      this.currentWorkingFilePath = chartPath;
    }
    else
    {
      CameraEditorNotificationHandler.failure(this, 'Failed to Load Chart', 'Failed to load chart (${chartPath})');
    }
  }

  @:bind(menubarItemSave, MouseEvent.CLICK)
  function onMenubarSave(event:MouseEvent)
  {
    if (currentWorkingFilePath != null)
    {
      CameraEditorImportExportHandler.saveFNFCToPath(this, true, currentWorkingFilePath, function(path:String) {
        notifyChange("Chart Save", 'This chart has been saved to ${path}');
      }, function() {
        // Failed to save backup?
      });
    }
    else
    {
      this.onMenubarSaveAs(event);
    }
  }

  @:bind(menubarItemSaveAs, MouseEvent.CLICK)
  function onMenubarSaveAs(_)
  {
    CameraEditorImportExportHandler.saveFNFCToPath(this, false, null, function(path:String) {
      notifyChange("Chart Save", 'This chart has been saved to ${path}');
      currentWorkingFilePath = path;
    }, function() {
      // Failed to save backup?
    });
  }

  @:bind(menubarItemExit, MouseEvent.CLICK)
  function onMenubarExit(_)
  {
    if (!saved)
    {
      if (exitConfirmDialog == null)
      {
        exitConfirmDialog = Dialogs.messageBox("You are about to leave the editor without saving.\n\nAre you sure? ", "Leave Editor",
          MessageBoxType.TYPE_YESNO, true, function(btn:DialogButton) {
            exitConfirmDialog = null;
            if (btn == DialogButton.YES)
            {
              saveBackup();
              onMenubarExit(null);
            }
        });
      }

      return;
    }

    writePreferences(!saved);
    resetWindowTitle();

    WindowUtil.windowExit.remove(windowClose);
    CrashHandler.errorSignal.remove(autosavePerCrash);
    CrashHandler.criticalErrorSignal.remove(autosavePerCrash);

    Cursor.hide();
    FlxG.switchState(() -> new MainMenuState());
    FlxG.sound.music.stop();
  }

  @:bind(menubarItemPlayPause, MouseEvent.CLICK)
  function onPlayPause(_)
  {
    togglePlayback();
  }

  @:bind(menubarItemResetPlayback, MouseEvent.CLICK)
  function onStopPlayback(_)
  {
    var playing:Bool = currentInstrumental != null && currentInstrumental.playing;
    togglePlayback(true);
    setTimePosition(0);
    resetScrollPosition();
    if (playing) togglePlayback();
  }

  @:bind(menubarItemResetCameraScroll, MouseEvent.CLICK)
  function onResetCameraScroll(_)
  {
    goToPoint.x = 0;
    goToPoint.y = 0;
    FlxG.camera.scroll.x = 0;
    FlxG.camera.scroll.y = 0;
  }

  @:bind(menubarItemResetCameraZoom, MouseEvent.CLICK)
  function onResetCameraZoom(_)
  {
    FlxG.camera.zoom = 1.0;
  }

  @:bind(menubarItemUserGuide, MouseEvent.CLICK)
  function onUserGuide(_)
  {
    var userGuideDialog = new UserGuideDialog();
    userGuideDialog.showDialog();

    userGuideDialog.onDialogClosed = (_) -> userGuideDialog = null;
  }

  @:bind(menubarItemGoToBackupsFolder, MouseEvent.CLICK)
  function onOpenBackupsFolder(_)
  {
    #if sys
    var absoluteBackupsPath:String = haxe.io.Path.join([Sys.getCwd(), BACKUPS_PATH]);
    FileUtil.openFolder(absoluteBackupsPath);
    #end
  }

  @:bind(menubarItemAbout, MouseEvent.CLICK)
  function onAbout(_)
  {
    var aboutDialog = new AboutDialog();
    aboutDialog.showDialog();

    aboutDialog.onDialogClosed = (_) -> aboutDialog = null;
  }
}
#end

/**
 * Available themes for the stage editor state.
 */
enum abstract CameraEditorTheme(String)
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

typedef CameraEditorParams =
{
  /**
   * If non-null, load this chart immediately instead of the welcome screen.
   */
  var ?fnfcTargetPath:String;
};
