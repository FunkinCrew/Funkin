package funkin.ui.debug.cameraeditor;

import funkin.ui.debug.charting.handlers.ChartEditorImportExportHandler;
import funkin.util.SortUtil;
#if FEATURE_CAMERA_EDITOR
import haxe.ui.containers.Panel;
import haxe.ui.containers.Panel;
import haxe.ui.focus.FocusManager;
import flixel.FlxCamera;
import funkin.graphics.FunkinCamera;
import flixel.math.FlxMath;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import funkin.play.event.SongEvent;
import funkin.data.song.SongData.SongEventData;
import flixel.FlxObject;
import funkin.data.song.SongData.SongNoteData;
import funkin.play.character.BaseCharacter;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import funkin.play.notes.NoteSprite;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import funkin.graphics.FunkinSprite;
import funkin.audio.FunkinSound;
import funkin.graphics.FunkinAnimationController;
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.data.event.SongEventRegistry;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongEventDataRaw;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongDataUtils;
import funkin.data.song.importer.ChartManifestData;
import funkin.data.stage.StageRegistry;
import funkin.graphics.FunkinCamera;
import funkin.input.Cursor;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.PlayState;
import funkin.play.character.BaseCharacter;
import funkin.play.stage.Stage;
import funkin.save.Save;
import funkin.ui.debug.cameraeditor.components.VirtualCameraRectangle;
import funkin.ui.debug.cameraeditor.commands.CameraEditorCommand;
import funkin.ui.haxeui.components.editors.timeline.TimelineEvent;
import funkin.ui.haxeui.components.editors.timeline.TimelineUtil;
import funkin.data.song.SongData.SongEventDataRaw;
import funkin.ui.debug.cameraeditor.commands.AddEventCommand;
import funkin.ui.debug.cameraeditor.commands.AddLayerCommand;
import funkin.ui.debug.cameraeditor.commands.MoveResizeEventCommand;
import funkin.ui.debug.cameraeditor.commands.RemoveEventCommand;
import funkin.ui.debug.cameraeditor.commands.RemoveLayerCommand;
import funkin.ui.debug.cameraeditor.commands.FlattenLayerCommand;
import funkin.ui.debug.cameraeditor.components.AboutDialog;
import funkin.ui.debug.cameraeditor.components.BackupAvailableDialog;
import funkin.ui.debug.cameraeditor.components.DeleteLayerConfirmDialog;
import funkin.ui.debug.cameraeditor.components.UploadChartDialog;
import funkin.ui.debug.cameraeditor.components.WelcomeDialog;
import funkin.ui.debug.cameraeditor.components.UserGuideDialog;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorCommandHandler;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorImportExportHandler;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorNotificationHandler;
import funkin.ui.haxeui.components.editors.camera.CameraViewportEvent;
import funkin.ui.debug.stageeditor.handlers.AssetDataHandler;
import funkin.ui.haxeui.components.editors.timeline.TimelineEvent;
import funkin.ui.haxeui.components.editors.timeline.TimelineUtil;
import funkin.ui.mainmenu.MainMenuState;
import funkin.util.FileUtil;
import funkin.util.MouseUtil;
import funkin.util.WindowUtil;
import funkin.util.assets.SoundUtil;
import funkin.util.logging.CrashHandler;
import funkin.util.macro.ConsoleMacro;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.ui.backend.flixel.MouseHelper;
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
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.focus.FocusManager;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;

using StringTools;

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
  public static final BACKUPS_PATH:String = './backups/charts/';

  /**
   * The current instance of the Camera Editor.
   */
  public static var instance:CameraEditorState = null;

  public static final SEEK_TOLERANCE_MS:Float = 300;

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

  public var currentDifficulty:String = "hard";

  public var currentNotes(get, never):Array<SongNoteData>;

  public var cameraRect:VirtualCameraRectangle = new VirtualCameraRectangle(0, 0);

  public var vCamDebug:FunkinSprite = null;

  var cachedEventIndex = 0;
  var cachedNoteIndex = 0;

  function get_currentSongMetadata():Null<SongMetadata>
  {
    return songMetadatas.get(currentVariation);
  }

  function get_currentSongChartData():Null<SongChartData>
  {
    return songDatas.get(currentVariation);
  }

  function get_currentNotes():Array<SongNoteData>
  {
    var chartData = currentSongChartData;
    if (chartData == null) return [];
    var notes = chartData.notes.get(currentDifficulty);
    if (notes == null) return [];
    return notes;
  }

  public var currentStage:Null<Stage> = null;

  // Song chart data we have to hold onto just to save properly later.
  public var audioInstTrackData:Map<String, Bytes> = [];
  public var audioVocalTrackData:Map<String, Bytes> = [];

  /**
   * The song manifest data.
   * If none already exists, it's initialized with the current song name in lower-kebab-case.
   */
  var _songManifestData:Null<ChartManifestData> = null;

  public var songManifestData(get, set):ChartManifestData;

  function get_songManifestData():ChartManifestData
  {
    if (_songManifestData != null) return _songManifestData;

    var defaultSongId:String = (currentSongMetadata.songName ?? 'New Song').trim().toLowerKebabCase().sanitize();
    if (defaultSongId == '') defaultSongId = 'new-song';
    _songManifestData = new ChartManifestData(defaultSongId);

    return _songManifestData;
  }

  function set_songManifestData(value:ChartManifestData):ChartManifestData
  {
    return _songManifestData = value;
  }

  public var selectedSongEvent(default, set):Null<SongEventData> = null;

  var hasClipboardEvent:Bool = false;

  function set_selectedSongEvent(value:Null<SongEventData>):Null<SongEventData>
  {
    if (value == null && selectedSongEvent == null) return value;
    if (value != null && selectedSongEvent != null && value == selectedSongEvent) return value;

    selectedSongEvent = value;
    CameraEditorPropertiesPanelHandler.loadSelectedSongEvent(this);

    return value;
  }

  // simple getter to remove bunch of `if (selectedSongEvent != null)` esque checks
  var isSelectingSongEvent(get, never):Bool;

  inline function get_isSelectingSongEvent():Bool return selectedSongEvent != null;

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

  @:bind(menubarItemExtendedBounds.selected)
  public var showCameraExtendedBounds(default, set):Bool = false;

  function set_showCameraExtendedBounds(val:Bool):Bool
  {
    showCameraExtendedBounds = val;
    cameraRect.showExtendedBounds = val;
    return val;
  }

  @:bind(menubarItemPassepartout.selected)
  public var showCameraPassepartout(default, set):Bool = false;

  function set_showCameraPassepartout(val:Bool):Bool
  {
    showCameraPassepartout = val;
    cameraRect.showPassepartout = val;
    menubarSliderPassepartoutTransparency.disabled = !val;
    return val;
  }

  @:bind(menubarSliderPassepartoutTransparency.pos)
  public var cameraPassepartoutTransparency(default, set):Float = 50;

  function set_cameraPassepartoutTransparency(val:Float):Float
  {
    cameraPassepartoutTransparency = val;
    cameraRect.passepartoutTransparency = val / 100;
    return val;
  }

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
   * The camera that the HUD is rendered to.
   */
  var camHUD:FlxCamera;

  /**
   * The camera that the game underneath the HUD is rendered to.
   */
  var camGame:FlxCamera;

  /**
   * The default zoom level of the stage's camera, used for calculating relative zoom levels for events like ZoomCamera. Updated whenever a new stage is built.
   */
  var defaultStageZoom:Float = 1.0;

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

  var deleteLayerConfirmDialog:Dialog;

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
  var commandHistoryDirty(default, set):Bool = true;

  function set_commandHistoryDirty(value:Bool):Bool
  {
    commandHistoryDirty = value;

    if (value)
    {
      updateUndoRedoMenuItems();
      commandHistoryDirty = false;
    }

    return commandHistoryDirty;
  }

  /**
   * If true, we are currently in the process of quitting the chart editor.
   * Skip any update functions as most of them will call a crash.
   */
  var criticalFailure:Bool = false;

  var songEvents:Array<SongEventData> = [];

  var addEventMenu:AddEventMenu;
  var shouldShowBackupAvailableDialog(get, set):Bool;

  function get_shouldShowBackupAvailableDialog():Bool
  {
    return Save.instance.cameraEditorHasBackup.value && CameraEditorImportExportHandler.getLatestBackupPath() != null;
  }

  function set_shouldShowBackupAvailableDialog(value:Bool):Bool
  {
    return Save.instance.cameraEditorHasBackup.value = value;
  }

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
    vCamDebug = new FunkinSprite(0, 0);
    vCamDebug.makeGraphic(32, 32, FlxColor.RED);
    vCamDebug.origin.set(16, 16);

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

    populateLoadVariationMenu();
    populateOpenRecentMenu();

    registerTimelineEvents();

    addEventMenu = new AddEventMenu(function(eventData)
    {
      var selectedLayer = timeline.viewport.layers[timeline.viewport.selectedLayerIndex];
      var raw:SongEventDataRaw = eventData;
      raw.editorLayer = selectedLayer.name == "Default" ? null : selectedLayer.name;

      var cmd = new AddEventCommand(eventData);
      CameraEditorCommandHandler.performCommand(this, cmd);
      selectedSongEvent = eventData;
    });

    add(cameraRect);
    // add(vCamDebug);
    vCamDebug.zIndex = cameraRect.zIndex + 1;

    mainView.registerEvent(CameraViewportEvent.ZOOM, onViewportZoom);

    CameraEditorPropertiesPanelHandler.initializePropertiesPanel(this);

    Screen.instance.registerEvent(KeyboardEvent.KEY_DOWN, onScreenKeyDown);

    // TODO: Reuse ChartEditorShortcutHandler.applyPlatformShortcutText() when more shortcuts are added.
    #if mac
    menubarItemUndo.shortcutText = '⌘+Z';
    menubarItemRedo.shortcutText = '⌘+Y';
    #end

    if (params != null && params.fnfcTargetPath != null)
    {
      // Chart editor was opened from the command line. Open the FNFC file now!
      var selectedFileBytes:Null<Bytes> = FileUtil.readBytesFromPath(params.fnfcTargetPath);
      if (selectedFileBytes == null)
      {
        trace('Failed to load bytes for FNFC from ${params.fnfcTargetPath}');
        return;
      }

      var entries = ChartEditorImportExportHandler.genericLoadFNFC(selectedFileBytes, true);
      if (entries == null)
      {
        CameraEditorNotificationHandler.failure(this, 'Failed to Load Chart', 'Failed to load chart (${params.fnfcTargetPath})');
        return;
      }

      CameraEditorNotificationHandler.success(this, 'Loaded Chart', 'Loaded chart (${params.fnfcTargetPath})');

      this.currentWorkingFilePath = params.fnfcTargetPath;
      this.saved = true; // Just loaded file!

      this.songMetadatas = entries.songMetadatas;
      this.songDatas = entries.songChartDatas;
      this.songManifestData = entries.manifest;
      this.audioInstTrackData = entries.instrumentals;
      this.audioVocalTrackData = entries.vocals;
      this.onChartLoaded();
    }
    else
    {
      var welcomeDialog = this.openWelcomeDialog();
      if (shouldShowBackupAvailableDialog)
      {
        openBackupAvailableDialog(welcomeDialog);
      }
    }
  }

  var goToPoint:FlxPoint = new FlxPoint();

  var previousTime:Float = 0;
  var completedEvents:Array<SongEventData> = [];

  /**
   * Process song events for the current chart.
   * This never removes them as we need to maybe reprocess events depending on the time of the song.
   * EX: Reversing the song time should re-trigger events that were already triggered.
   */
  public function processEvents():Void
  {
    if (songEvents == null || songEvents.length == 0) return;
    for (i in cachedEventIndex...songEvents.length)
    {
      var eventData = songEvents[i];
      if (completedEvents.contains(eventData)) continue;
      if (eventData == null || eventData.time > conductorInUse.songPosition || eventData.time < previousTime) continue;
      trace('Processing event: ' + eventData.eventKind + ' at ' + eventData.time);

      switch (eventData.eventKind)
      {
        case "FocusCamera":
          cameraRect.handleFocusCamera(eventData);
        case "ZoomCamera":
          cameraRect.handleZoomCamera(defaultStageZoom, eventData);
      }

      completedEvents.push(eventData);
      cachedEventIndex = i + 1;
    }

    previousTime = conductorInUse.songPosition;
  }

  public override function dispatchEvent(event:ScriptEvent):Void
  {
    super.dispatchEvent(event);

    if (currentStage != null)
    {
      ScriptEventDispatcher.callEvent(currentStage, event);

      currentStage.dispatchToCharacters(event);
    }
  }

  var previousNoteTime:Float = 0;
  var previousNotes:Array<SongNoteData> = [null,null,null,null,null,null,null,null];

  function processNotes():Void
  {
    var notes:Array<SongNoteData> = currentNotes;
    if (notes == null) return;

    var dad:BaseCharacter = currentStage.getDad();
    var bf:BaseCharacter = currentStage.getBoyfriend();

    for (i in cachedNoteIndex...notes.length)
    {
      var note = notes[i];
      if (note.time > conductorInUse.songPosition || note.time < previousNoteTime) continue;

      var isPlayer = note.getStrumlineIndex() == 0;
      var char:BaseCharacter = isPlayer ? bf : dad;

      if (char != null)
      {
        previousNotes[note.data] = note;
        playSingAnimation(note);
      }
      cachedNoteIndex = i + 1;
    }

    previousNoteTime = conductorInUse.songPosition;

    // Hold notes
    for (note in previousNotes)
    {
      if (note == null) continue;
      if (note.length <= 0 || note.time + note.length < conductorInUse.songPosition || note.time > conductorInUse.songPosition) continue;

      var isPlayer = note.getStrumlineIndex() == 0;
      var char:BaseCharacter = isPlayer ? bf : dad;

      if (char != null) char.holdTimer = 0;
    }
  }

  var _cameraTarget:FlxPoint = new FlxPoint();
  var _autoSeekTimer:Float = 0;

  public override function update(elapsed:Float):Void
  {
    // Save the stage if exiting through the F4 keybind.
    // Soon the EvacuateDebugPlugin will move us to the new state.
    if (FlxG.keys.justPressed.F4)
    {
      performCleanup();
      return;
    }

    if (autoSeek)
    {
      _autoSeekTimer += elapsed;

      if (_autoSeekTimer >= 0.5)
      {
        trace('Auto-seek elapsed: ' + conductorInUse.songPosition);
        autoSeek = false;
        _autoSeekTimer = 0;
        replayCameraTimeline(conductorInUse.songPosition);
      }
    }

    if (currentStage != null)
    {
      currentStage.vcamPoint = cameraRect.vCamPoint;
      vCamDebug.x = cameraRect.vCamPoint.x;
      vCamDebug.y = cameraRect.vCamPoint.y;
    }

    conductorInUse.update();

    // TODO: sync vocals if they desync, im just too lazy to put this in rn
    if (currentInstrumental != null && currentInstrumental.playing)
    {
      processEvents();
      processNotes();
      timeline.songPosition = conductorInUse.songPosition;
    }
    else if (currentVocals.length > 0 && currentVocals[0].playing)
    {
      for (vocal in currentVocals)
        if (vocal.playing) vocal.pause();
    }

    super.update(elapsed);

    MouseUtil.mouseCamDrag(goToPoint);
    _cameraTarget.x = FlxMath.lerp(_cameraTarget.x, goToPoint.x, 0.8);
    _cameraTarget.y = FlxMath.lerp(_cameraTarget.y, goToPoint.y, 0.8);

    FlxG.camera.scroll.copyFrom(_cameraTarget);

    if (!isCameraRelative)
    {
      // subtract the vcam point since it moves everything
      FlxG.camera.scroll.x -= cameraRect.vCamPoint.x;
      FlxG.camera.scroll.y -= cameraRect.vCamPoint.y;
    }

    if (FlxG.keys.justPressed.SPACE) onPlayPause(null);
    if (FlxG.keys.justPressed.R) onStopPlayback(null);
    if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.A) addEventMenu.show();

    if (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickDown"));
    if (FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickUp"));

    this.updatePropertiesPanel(elapsed);
  }

  /**
   * Builds the current stage based on the current song metadata.
   */
  public function buildStage():Void
  {
    cachedEventIndex = 0;
    cachedNoteIndex = 0;
    previousNotes = [null,null,null,null,null,null,null,null];

    remove(cameraRect);
    if (currentSongMetadata == null) return;
    var stageID = currentSongMetadata.playData.stage;

    previousTime = 0;
    songEvents = currentSongChartData.events;

    if (currentStage != null)
    {
      ScriptEventDispatcher.callEvent(currentStage, new ScriptEvent(DESTROY, false));
      remove(currentStage);
      currentStage.kill();
      currentStage = null;
    }

    currentStage = StageRegistry.instance.fetchEntry(stageID);

    if (currentStage == null)
    {
      throw 'Could not retrieve stage: $stageID';
    }

    currentStage.revive();

    var campaignId:String = Stage.getCampaignID(stageID);

    Paths.setCurrentLevel(campaignId);

    var event:ScriptEvent = new ScriptEvent(CREATE, false);
    ScriptEventDispatcher.callEvent(currentStage, event);

    add(currentStage);
    currentStage.vcamPoint = cameraRect.vCamPoint;
    currentStage.onCreate(null);

    var songCharacterData = currentSongMetadata.playData.characters;

    if (songCharacterData == null) return;

    var gf:Null<BaseCharacter> = CharacterDataParser.fetchCharacter(songCharacterData.girlfriend);

    var dad:Null<BaseCharacter> = CharacterDataParser.fetchCharacter(songCharacterData.opponent);

    var bf:Null<BaseCharacter> = CharacterDataParser.fetchCharacter(songCharacterData.player);

    FlxG.camera.filters = [];

    var buildChar:Null<BaseCharacter>->CharacterType->Void = (char, charType) ->
    {
      if (char == null) return;

      char.currentStage = currentStage;
      char.debug = true;

      char.onCreate(null);

      // Needs to come AFTER `onCreate()` so that stuff in scripts work properly!!!
      // Examples include Nene's A-Bot and the Week 7 rimlight shader.
      currentStage.addCharacter(char, charType);

      char.onUpdate(null);
      char.onAdd(null);
      cast(char.animation, FunkinAnimationController).shouldUseConductorSync = true;
    };

    buildChar(gf, GF);
    buildChar(bf, BF);
    buildChar(dad, DAD);

    currentStage.resetStage();
    currentStage.refresh();

    goToPoint.x = 0;
    goToPoint.y = 0;

    FlxG.camera.scroll.x = 0;
    FlxG.camera.scroll.y = 0;

    trace("Built stage: " + stageID);
    add(cameraRect);
    cameraRect.currentStage = currentStage;

    cameraRect.zoom = currentStage.camZoom;
    defaultStageZoom = currentStage.camZoom;
    resetScrollPosition();
  }

  function resetScrollPosition()
  {
    cameraRect.setFocusPoint(cameraRect.defaultPosition.x, cameraRect.defaultPosition.y, true);
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

    var hasRecentFiles:Bool = false;

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

      hasRecentFiles = true;
    }

    menubarOpenRecent.disabled = !hasRecentFiles;
    #else
    menubarOpenRecent.hide();
    #end
  }

  /**
   * Updates the list of variations in the `File->Load Variation` menu.
   */
  public function populateLoadVariationMenu():Void
  {
    if (menubarLoadVariation == null) return;
    if (songMetadatas == null || songMetadatas.size() == 0)
    {
      menubarLoadVariation.disabled = true;
      return;
    };

    menubarLoadVariation.removeAllComponents();

    var variations:Array<String> = songMetadatas.keyValues();
    var hasAdditionalVariations = variations.length > 1;

    if (hasAdditionalVariations)
    {
      variations.sort(SortUtil.defaultsThenAlphabetically.bind(Constants.DEFAULT_VARIATION_LIST));
      for (variation in variations)
      {
        var menuItemVariation:MenuItem = new MenuItem();
        menuItemVariation.text = variation.toTitleCase();
        menuItemVariation.onClick = function(_:MouseEvent):Void
        {
          switchVariation(variation);
        }
        menubarLoadVariation.addComponent(menuItemVariation);
      }
    }

    menubarLoadVariation.disabled = !hasAdditionalVariations;
  }

  public function switchVariation(target:String):Void
  {
    this.currentVariation = target;

    // Maybe make this changeable in the ui?
    currentDifficulty = (target == 'erect') ? 'nightmare' : 'hard';

    onChartLoaded();
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
    trace(save.cameraEditorHasBackup.value);

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
    populateLoadVariationMenu();
    loadCurrentInstrumentalAndVocals();
    buildStage();
    updateWindowTitle();
    timeline.viewport.layers = [];
    timeline.viewport.selectedLayerIndex = 0;
    loadTimeline();
  }

  /**
   * Loads all the events into the timeline so it can display and edit them.
   */
  public function loadTimeline():Void
  {
    timeline.setEvents(currentSongChartData.events);
    timeline.setStepLengthMs(conductorInUse.stepLengthMs);
  }

  function registerTimelineEvents():Void
  {
    timeline.viewport.registerEvent(MouseEvent.RIGHT_MOUSE_DOWN, _ -> addEventMenu.show());
    timeline.viewport.registerEvent(TimelineEvent.EVENT_SELECTED, (e:TimelineEvent) -> selectedSongEvent = e.eventData);
    timeline.viewport.registerEvent(TimelineEvent.SEEK, (e:TimelineEvent) -> setTimePosition(e.seekPositionMs));

    timeline.viewport.registerEvent(TimelineEvent.EVENT_MOVED, function(e:TimelineEvent)
    {
      var cmd = new MoveResizeEventCommand(e.eventData, e.oldTime, TimelineUtil.getEventDurationSteps(e.eventData), e.oldLayerName, e.newTime,
        TimelineUtil.getEventDurationSteps(e.eventData), e.newLayerName);
      CameraEditorCommandHandler.performCommand(this, cmd);
    });

    timeline.viewport.registerEvent(TimelineEvent.EVENT_RESIZED, function(e:TimelineEvent)
    {
      var layerName:String = e.eventData.editorLayer ?? 'Default';
      var cmd = new MoveResizeEventCommand(e.eventData, e.eventData.time, e.oldDuration, layerName, e.eventData.time, e.newDuration, layerName);
      CameraEditorCommandHandler.performCommand(this, cmd);
    });

    timeline.toolbar.findComponent('btnTogglePlayback').registerEvent(MouseEvent.CLICK, _ -> togglePlayback());

    timeline.registerEvent(TimelineEvent.LAYER_ADDED, function(e:TimelineEvent)
    {
      var cmd = new AddLayerCommand(e.layerData, e.layerIndex);
      CameraEditorCommandHandler.performCommand(this, cmd);
    });

    timeline.registerEvent(TimelineEvent.LAYER_REMOVED, function(e:TimelineEvent)
    {
      var layerName:String = e.layerData.name;

      // note/todo: should find a way to get how many events are in each layer easier than this
      var eventCount:Int = 0;
      for (event in currentSongChartData.events)
      {
        var editorLayer = event.editorLayer ?? "Default";
        if (editorLayer == layerName) eventCount++;
      }

      if (eventCount > 0)
      {
        if (deleteLayerConfirmDialog == null)
        {
          var dialog = new DeleteLayerConfirmDialog(layerName, eventCount,
            () -> {
              var cmd = new FlattenLayerCommand(e.layerData, e.layerIndex);
              CameraEditorCommandHandler.performCommand(this, cmd);
            },
            () -> {
              var cmd = new RemoveLayerCommand(e.layerData, e.layerIndex);
              CameraEditorCommandHandler.performCommand(this, cmd);
            });
          dialog.showDialog(true);
          deleteLayerConfirmDialog = dialog;
          dialog.onDialogClosed = (_) -> deleteLayerConfirmDialog = null;
        }
      }
      else
      {
        var cmd = new RemoveLayerCommand(e.layerData, e.layerIndex);
        CameraEditorCommandHandler.performCommand(this, cmd);
      }
    });
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

    var buildVocal:Null<Array<String>>->Void = (vocals:Null<Array<String>>) ->
    {
      for (voice in vocals)
      {
        var variSuffix:String = currentVariation == Constants.DEFAULT_VARIATION ? '' : '-$currentVariation';
        var vocalTrackKey:String = '$voice$variSuffix';

        var vocalData:Null<Bytes> = audioVocalTrackData.get(vocalTrackKey);
        if (vocalData != null)
        {
          var vocalSound = SoundUtil.buildSoundFromBytes(vocalData);
          currentVocals.push(vocalSound);
        }
        else
        {
          trace('Missing vocal track "$vocalTrackKey" (available: ${audioVocalTrackData.keyValues()})');
        }
      }
    };

    var currentCharactersData:SongCharacterData = currentSongMetadata.playData.characters;
    // Default to the character ID if the array is null, but NOT if the array is empty.
    buildVocal(currentCharactersData.playerVocals ?? [currentCharactersData.player]);
    buildVocal(currentCharactersData.opponentVocals ?? [currentCharactersData.opponent]);

    trace('    Instrumental:' + (currentInstrumental != null ? ' Loaded' : ' Missing'));
    trace('    Vocals: ' + currentVocals.length + ' loaded');

    if (FlxG.sound.music != null && FlxG.sound.music.playing)
    {
      FlxG.sound.music.stop();
      FlxG.sound.music = null;
    }

    FlxG.sound.music = currentInstrumental;

    conductorInUse.forceBPM(null);
    conductorInUse.instrumentalOffset = currentSongMetadata.offsets.instrumental;
    conductorInUse.mapTimeChanges(currentSongMetadata.timeChanges);
    timeline.songLength = currentInstrumental.length;
    timeline.songPosition = 0;
    timeline.setStepLengthMs(conductorInUse.stepLengthMs);

    cachedEventIndex = 0;
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

    currentInstrumental.play(false, currentInstrumental.time);
    for (vocal in currentVocals)
    {
      vocal.time = currentInstrumental.time;
      vocal.play(false, vocal.time);
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

  var lastSeekReplay:Float = 0;
  var autoSeek:Bool = false;

  /**
   * Sets the time position of the current instrumental and vocal tracks.
   * If `forceReplay` is false, the camera timeline will only replay if the seek is large enough (greater than 250m)
   * @param position The time position to set, in milliseconds.
   * @param forceReplay Forcibly replay the timeline, ignoring optimizations
   **/
  public function setTimePosition(position:Float, forceReplay:Bool = false):Void
  {
    if (currentInstrumental == null) return;

    currentInstrumental.time = position;
    for (vocal in currentVocals)
    {
      vocal.time = position;
    }

    if (!forceReplay)
    {
      var diff = Math.abs(position - lastSeekReplay);
      autoSeek = true;

      if (diff > SEEK_TOLERANCE_MS)
      {
        autoSeek = false;
        lastSeekReplay = position;
        replayCameraTimeline(position);
      }
    }
    else replayCameraTimeline(position);
    timeline.songPosition = conductorInUse.songPosition;
  }

  function playSingAnimation(note:SongNoteData):Void
  {
    var isPlayer = note.getStrumlineIndex() == 0;
    var char:BaseCharacter = isPlayer ? currentStage.getBoyfriend() : currentStage.getDad();

    if (char != null)
    {
      var noteSprite = new NoteSprite(null);
      noteSprite.noteData = note;
      noteSprite.kind = note.kind;
      var event:HitNoteScriptEvent = new HitNoteScriptEvent(noteSprite, 0.0, 0, 'perfect', false, 0);
      currentStage.dispatchToCharacters(event);
    }
  }

  public function replayCameraTimeline(position:Float):Void
  {
    if (cameraRect == null) return;

    if (currentSongChartData == null) return;

    cameraRect.cancelAllTweens();
    cameraRect.zoom = defaultStageZoom;
    cameraRect.setFocusPoint(cameraRect.defaultPosition.x, cameraRect.defaultPosition.y, true);

    conductorInUse.update(0);
    cameraRect.update(0);

    completedEvents = [];
    previousNoteTime = 0;

    if (songEvents != null && songEvents.length > 0)
    {
      var replayEvents:Array<SongEventData> = songEvents.filter(function(eventData:SongEventData):Bool
      {
        return eventData != null && eventData.time <= position;
      });

      replayEvents.sort(function(a:SongEventData, b:SongEventData):Int
      {
        if (a.time < b.time) return -1;
        if (a.time > b.time) return 1;
        return 0;
      });

      for (eventData in replayEvents)
      {
        conductorInUse.update(eventData.time);
        cameraRect.update(0);

        switch (eventData.eventKind)
        {
          case "FocusCamera":
            cameraRect.handleFocusCamera(eventData);
          case "ZoomCamera":
            cameraRect.handleZoomCamera(defaultStageZoom, eventData);
        }

        completedEvents.push(eventData);
      }

      var lastEvent = replayEvents[replayEvents.length - 1];
      cachedEventIndex = songEvents.indexOf(lastEvent);
    }

    var notes:Array<SongNoteData> = currentNotes;
    var dad:BaseCharacter = currentStage != null ? currentStage.getDad() : null;
    var bf:BaseCharacter = currentStage != null ? currentStage.getBoyfriend() : null;
    var dadShouldKeepSinging:Bool = false;
    var bfShouldKeepSinging:Bool = false;

    var dadSingTime = dad.singTimeSteps * (conductorInUse.stepLengthMs / Constants.MS_PER_SEC);
    var bfSingTime = bf.singTimeSteps * (conductorInUse.stepLengthMs / Constants.MS_PER_SEC);

    // replay notes
    if (notes != null)
    {
      var latestDadNote:SongNoteData = null;
      var latestBFNote:SongNoteData = null;

      for (note in notes)
      {
        if (note == null) continue;
        if (note.time > position) continue;

        previousNotes[note.data] = note;

        var isPlayer = note.getStrumlineIndex() == 0;
        if (isPlayer)
        {
          if (latestBFNote == null || note.time >= latestBFNote.time) latestBFNote = note;
        }
        else
        {
          if (latestDadNote == null || note.time >= latestDadNote.time) latestDadNote = note;
        }
      }

      if (latestDadNote != null)
      {
        conductorInUse.update(latestDadNote.time);
        playSingAnimation(latestDadNote);
        if (latestDadNote.length == 0) dadShouldKeepSinging = latestDadNote.time + 300 > position;
        else if (latestDadNote.length > 0) dadShouldKeepSinging = latestDadNote.time + latestDadNote.length > position;
      }

      if (latestBFNote != null)
      {
        conductorInUse.update(latestBFNote.time);
        playSingAnimation(latestBFNote);
        if (latestBFNote.length == 0) bfShouldKeepSinging = latestBFNote.time + 300 > position;
        else if (latestBFNote.length > 0) bfShouldKeepSinging = latestBFNote.time + latestBFNote.length > position;
      }

      if (latestDadNote != null && latestBFNote != null)
      {
        var latestNote = latestDadNote.time > latestBFNote.time ? latestDadNote : latestBFNote;
        cachedNoteIndex = notes.indexOf(latestNote);
      }
      else if (latestDadNote != null) cachedNoteIndex = notes.indexOf(latestDadNote);
      else if (latestBFNote != null) cachedNoteIndex = notes.indexOf(latestBFNote);
    }

    if (dad != null) dad.animation.update(0);
    if (bf != null) bf.animation.update(0);

    if (!dadShouldKeepSinging && dad != null)
    {
      if (!StringTools.startsWith(dad.animation.curAnim.name, 'idle')) dad.dance(true);
    }
    if (!bfShouldKeepSinging && bf != null)
    {
      if (!StringTools.startsWith(bf.animation.curAnim.name, "idle")) bf.dance(true);
    }
    conductorInUse.update(position);

    cameraRect.update(0);

    previousTime = conductorInUse.songPosition;
    previousNoteTime = position;
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
        exitConfirmDialog = Dialogs.messageBox('You are about to leave the editor without saving.\n\nAre you sure? ', 'Leave Editor',
          MessageBoxType.TYPE_YESNO, true, function(btn:DialogButton)
        {
          exitConfirmDialog = null;
          if (btn == DialogButton.YES)
          {
            // Write a backup, and remember we have one for next time.
            saveBackup();

            performCleanup();
            FlxG.switchState(() -> new MainMenuState());
          }
        });
      }

      return;
    }
    else
    {
      // No need to show confirmation, just exit immediately.
      performCleanup();
      FlxG.switchState(() -> new MainMenuState());
    }
  }

  @:bind(menubarItemUndo, MouseEvent.CLICK)
  function onMenubarUndo(_)
  {
    CameraEditorCommandHandler.undoLastCommand(this);
  }

  @:bind(menubarItemRedo, MouseEvent.CLICK)
  function onMenubarRedo(_)
  {
    CameraEditorCommandHandler.redoLastCommand(this);
  }

  override function reloadAssets():Void
  {
    performCleanup();
    super.reloadAssets();
  }

  /**
   * Called before we exit the editor to perform any necessary cleanup.
   */
  function performCleanup():Void
  {
    // Remove reference to stage and remove sprites from it to save memory and prevent crashes.
    if (currentStage != null)
    {
      currentStage.vcamPoint = null;
      ScriptEventDispatcher.callEvent(currentStage, new ScriptEvent(DESTROY, false));
      remove(currentStage);
      currentStage.kill();
      currentStage = null;
    }

    writePreferences(!saved);
    resetWindowTitle();

    WindowUtil.windowExit.remove(windowClose);
    CrashHandler.errorSignal.remove(autosavePerCrash);
    CrashHandler.criticalErrorSignal.remove(autosavePerCrash);

    Screen.instance.unregisterEvent(KeyboardEvent.KEY_DOWN, onScreenKeyDown);

    Cursor.hide();
    FlxG.sound.music.stop();
  }

  function updateUndoRedoMenuItems():Void
  {
    if (undoHistory.length == 0)
    {
      menubarItemUndo.disabled = true;
      menubarItemUndo.text = 'Undo';
    }
    else
    {
      menubarItemUndo.disabled = false;
      menubarItemUndo.text = 'Undo ${undoHistory[undoHistory.length - 1].toString()}';
    }

    if (redoHistory.length == 0)
    {
      menubarItemRedo.disabled = true;
      menubarItemRedo.text = 'Redo';
    }
    else
    {
      menubarItemRedo.disabled = false;
      menubarItemRedo.text = 'Redo ${redoHistory[redoHistory.length - 1].toString()}';
    }
  }

  function onScreenKeyDown(event:KeyboardEvent):Void
  {
    if (isHaxeUIFocused) return;

    // see: https://haxe.org/manual/lf-pattern-matching-tuples.html
    // for how this multiple pattern matching works
    switch ([event.keyCode, event.ctrlKey, isSelectingSongEvent])
    {
      case [FlxKey.Z, true, _]: // ctrl + z -> undo
        CameraEditorCommandHandler.undoLastCommand(this);
      case [FlxKey.Y, true, _]: // ctrl + y -> redo -- note: I sorta like the ctrl + shift + z method to redo...
        CameraEditorCommandHandler.redoLastCommand(this);
      case [FlxKey.C, true, true]: // ctrl + c -> copy
        SongDataUtils.writeItemsToClipboard({
          notes: [],
          events: [selectedSongEvent]
        });
        hasClipboardEvent = true;
      case [FlxKey.X, true, true]: // ctrl + x -> cut
        SongDataUtils.writeItemsToClipboard({
          notes: [],
          events: [selectedSongEvent]
        });
        hasClipboardEvent = true;
        CameraEditorCommandHandler.performCommand(this, new RemoveEventCommand(selectedSongEvent));
        selectedSongEvent = null;
      case [FlxKey.V, true, _] if (hasClipboardEvent): // ctrl + v -> paste at playhead
        var clipboard = SongDataUtils.readItemsFromClipboard();
        if (clipboard.valid != true || clipboard.events.length == 0) return;

        var pasteMs = Conductor.instance.songPosition;

        if (pasteMs < 0) pasteMs = 0;
        if (pasteMs > timeline.viewport.songLengthMs) pasteMs = timeline.viewport.songLengthMs;

        var newEvent = clipboard.events[0];
        newEvent.time = pasteMs;

        CameraEditorCommandHandler.performCommand(this, new AddEventCommand(newEvent));
        selectedSongEvent = newEvent;

      case [FlxKey.DELETE, _, true] | [FlxKey.BACKSPACE, _, true]: // delete/backspace (with a note selected) -> delete selected note
        var cmd = new RemoveEventCommand(selectedSongEvent);
        CameraEditorCommandHandler.performCommand(this, cmd);
        selectedSongEvent = null;

      default:
        // unbound/do nothing
    }
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
    completedEvents = [];
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

  function onViewportZoom(e:CameraViewportEvent):Void
  {
    // TODO: make this wheel zoom sensitivity configurable
    MouseUtil.mouseWheelZoom(0.08, e.zoomDelta);
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

  /**
   * Builds and opens a dialog letting the user create a new chart, open a recent chart, or load from a template.
   * @param state The current chart editor state.
   * @param closable Whether the dialog can be closed by the user.
   * @return The dialog that was opened.
   */
  function openWelcomeDialog():WelcomeDialog
  {
    final CLOSABLE:Bool = false;
    final MODAL:Bool = true;

    var dialog = new WelcomeDialog(this, CLOSABLE);

    dialog.zIndex = 1_000;

    dialog.showDialog(MODAL);

    return dialog;
  }

  function openBackupAvailableDialog(?welcomeDialog:WelcomeDialog):BackupAvailableDialog
  {
    final MODAL:Bool = true;

    var dialog = new BackupAvailableDialog(this, welcomeDialog);

    dialog.zIndex = 2_000;

    dialog.showDialog(MODAL);

    return dialog;
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
