package funkin.ui.debug.cameraeditor;

import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.containers.dialogs.Dialogs;
import funkin.ui.debug.stageeditor.handlers.AssetDataHandler;
import funkin.ui.mainmenu.MainMenuState;
#if FEATURE_CAMERA_EDITOR
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.input.Cursor;
import funkin.save.Save;
import funkin.ui.debug.cameraeditor.components.UploadChartDialog;
import funkin.ui.debug.cameraeditor.components.AboutDialog;
import funkin.ui.debug.cameraeditor.components.UserGuideDialog;
import funkin.util.FileUtil;
import funkin.util.logging.CrashHandler;
import funkin.util.WindowUtil;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuOptionBox;
import haxe.ui.containers.windows.WindowManager;
import haxe.ui.core.Screen;
import haxe.ui.events.MouseEvent;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;

/**
 * The EYES OF GOD......
 */
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/camera-editor/main-view.xml"))
class CameraEditorState extends UIState
{
  public static final BACKUPS_PATH:String = "./backups/camera/";

  public static var instance:CameraEditorState = null;

  public var currentVariation:String = Constants.DEFAULT_VARIATION;

  public var songDatas:Map<String, SongChartData> = new Map<String, SongChartData>();
  public var songMetadatas:Map<String, SongMetadata> = new Map<String, SongMetadata>();

  public var currentSongMetadata(get, never):Null<SongMetadata>;
  public var currentSongChartData(get, never):Null<SongChartData>;

  function get_currentSongMetadata():Null<SongMetadata>
  {
    return songMetadatas.get(currentVariation);
  }

  function get_currentSongChartData():Null<SongChartData>
  {
    return songDatas.get(currentVariation);
  }

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
        saveBackup();
      });
    }

    return value;
  }

  function set_currentFile(value:String):String
  {
    currentFile = value;

    updateWindowTitle();

    // if (currentFile != "") updateRecentFiles();

    // reloadRecentFiles();

    return value;
  }

  // the other shit:tm:
  var menubar:MenuBar;

  var menubarMenuFile:Menu;
  var menubarItemExit:MenuItem;
  var menubarItemOpen:MenuItem;

  var menubarMenuEdit:Menu;

  var menubarMenuView:Menu;
  var menubarItemThemeLight:MenuOptionBox; // light mode option
  var menubarItemThemeDark:MenuOptionBox; // dark mode option

  var menubarMenuHelp:Menu;
  var menubarItemUserGuide:MenuItem;
  var menubarItemGoToBackupsFolder:MenuItem;
  var menubarItemAbout:MenuItem;

  public var userGuideDialog:UserGuideDialog;
  public var aboutDialog:AboutDialog;
  public var uploadChartDialog:UploadChartDialog;
  public var exitConfirmDialog:Dialog;

  var isCursorOverHaxeUI(get, never):Bool;

  function get_isCursorOverHaxeUI():Bool
  {
    return Screen.instance.hasSolidComponentUnderPoint(Screen.instance.currentMouseX, Screen.instance.currentMouseY);
  }

  public var autoSaveTimer:FlxTimer = new FlxTimer();

  /**
   * The params which were passed in when the Stage Editor was initialized.
   */
  var params:Null<CameraEditorParams>;

  var camHUD:FlxCamera;
  var camGame:FlxCamera;

  public function new(?params:CameraEditorParams)
  {
    super();
    this.params = params;
  }

  override public function create():Void
  {
    WindowManager.instance.reset();
    instance = this;
    FlxG.sound.music?.stop();
    WindowUtil.setWindowTitle("Friday Night Funkin\' Camera Editor");

    camGame = new FlxCamera();
    camHUD = new FlxCamera();
    camHUD.bgColor.alpha = 0;

    FlxG.cameras.reset(camGame);
    FlxG.cameras.add(camHUD, false);
    FlxG.cameras.setDefaultDrawTarget(camGame, true);

    persistentUpdate = false;

    super.create();
    root.scrollFactor.set();
    // root.cameras = [camHUD];
    root.width = FlxG.width;
    root.height = FlxG.height;

    menubar.height = 35;
    WindowManager.instance.container = root;
    Screen.instance.addComponent(root);

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

    conductorInUse.update();

    super.update(elapsed);

    if (FlxG.mouse.justPressed || FlxG.mouse.justPressedRight) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickDown"));
    if (FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickUp"));
  }

  function autosavePerCrash(message:String)
  {
    trace("Crashed the game for the reason: " + message);

    if (!saved)
    {
      trace("You haven't saved recently, so a backup will be made.");
      saveBackup();
    }
  }

  function windowClose(exitCode:Int)
  {
    trace("Closing the game window.");

    if (!saved)
    {
      trace("You haven't saved recently, so a backup will be made.");
      saveBackup();
    }
  }

  public function updateWindowTitle()
  {
    var defaultTitle = "Friday Night Funkin\' Camera Editor";

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

  function saveBackup()
  {
    FileUtil.createDirIfNotExists(BACKUPS_PATH);

    notifyChange("Auto-Save", "A Backup of this Chart has been made.");
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

  // ui function bindings

  @:bind(menubarItemOpen, MouseEvent.CLICK)
  function onOpenMenu(_)
  {
    var uploadDialog = new UploadChartDialog(this);
    uploadDialog.showDialog();
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

    resetWindowTitle();

    WindowUtil.windowExit.remove(windowClose);
    CrashHandler.errorSignal.remove(autosavePerCrash);
    CrashHandler.criticalErrorSignal.remove(autosavePerCrash);

    Cursor.hide();
    FlxG.switchState(() -> new MainMenuState());
    FlxG.sound.music.stop();
  }

  @:bind(menubarItemUserGuide, MouseEvent.CLICK)
  function onUserGuide(_)
  {
    userGuideDialog = new UserGuideDialog();
    userGuideDialog.showDialog();

    userGuideDialog.onDialogClosed = function(_) {
      userGuideDialog = null;
    }
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
    aboutDialog = new AboutDialog();
    aboutDialog.showDialog();
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
