package funkin.ui.debug.charting.handlers.editor;

#if FEATURE_CHART_EDITOR
import flixel.util.FlxTimer;
import funkin.save.Save;
import funkin.util.Constants;
import funkin.util.WindowUtil;
import funkin.util.logging.CrashHandler;
import haxe.io.Path;
import funkin.ui.debug.charting.handlers.chart.ChartEditorImportExportHandler;

using Lambda;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorAutoSaveHandler
{
  static var windowCloseListener:Null<Int->Void> = null;
  static var windowCrashListener:Null<String->Void> = null;

  /**
   * Setup timers and listeners to handle auto-save.
   */
  public static function setupAutoSave(state:ChartEditorState):Void
  {
    // Called when clicking the X button on the window.
    cleanupAutoSave(state);
    var closeListener:Int->Void = state.onWindowClose;
    var crashListener:String->Void = state.onWindowCrash;
    windowCloseListener = closeListener;
    windowCrashListener = crashListener;
    WindowUtil.windowExit.add(closeListener);

    // Called when the game crashes.
    CrashHandler.errorSignal.add(crashListener);
    CrashHandler.criticalErrorSignal.add(crashListener);

    state.saveDataDirty = false;
  }

  /**
   * UPDATE FUNCTIONS
   */
  public static function autoSave(state:ChartEditorState, beforePlaytest:Bool = false):Void
  {
    var needsAutoSave:Bool = state.saveDataDirty;

    // Auto-save preferences.
    state.writePreferences(needsAutoSave);

    // Auto-save the chart.
    #if html5
    // Auto-save to local storage.
    // TODO: Implement this.
    #else
    // Auto-save to temp file.
    if (needsAutoSave && state.autoSaveEnabled)
    {
      state.exportCurrentChartToFNFC(true, null);
      if (beforePlaytest)
      {
        state.displayAutosavePopup = true;
      }
      else
      {
        state.displayAutosavePopup = false;
        var absoluteBackupsPath:String = Path.join([
          Sys.getCwd(),
          ChartEditorImportExportHandler.BACKUPS_PATH
        ]);
        state.infoWithActions('Auto-Save', 'Chart auto-saved to ${absoluteBackupsPath}.', [{
          text: 'Open In Folder',
          callback: state.openBackupsFolder,
        }]);
      }
    }
    #end

    // autoSave() gets re-queued when saveDataDirty is set.
    state.dequeueAutoSave();
  }

  public static function queueAutoSave(state:ChartEditorState):Void
  {
    // Clear any existing timer.
    state.dequeueAutoSave();
    // Start the auto-save timer.
    state.autoSaveTimer = new FlxTimer().start(Constants.AUTOSAVE_TIMER_DELAY_SEC, (_) -> state.autoSave());
  }

  public static function dequeueAutoSave(state:ChartEditorState):Void
  {
    if (state.autoSaveTimer != null)
    {
      // Stop the auto-save timer.
      state.autoSaveTimer.cancel();
      state.autoSaveTimer.destroy();
      state.autoSaveTimer = null;
    }
  }

  public static function cleanupAutoSave(state:ChartEditorState):Void
  {
    var closeListener:Null<Int->Void> = windowCloseListener;
    var crashListener:Null<String->Void> = windowCrashListener;
    if (closeListener != null) WindowUtil.windowExit.remove(closeListener);
    if (crashListener != null)
    {
      CrashHandler.errorSignal.remove(crashListener);
      CrashHandler.criticalErrorSignal.remove(crashListener);
    }
    windowCloseListener = null;
    windowCrashListener = null;
  }

  public static function applyCanQuickSave(state:ChartEditorState):Void
  {
    if (state.menubarItemSaveChart == null) return;

    if (state.currentWorkingFilePath == null)
    {
      state.menubarItemSaveChart.disabled = true;
    }
    else
    {
      state.menubarItemSaveChart.disabled = false;
    }
  }

  public static function applyWindowTitle(state:ChartEditorState):Void
  {
    var inner:String = 'New Chart';
    var cwfp:Null<String> = state.currentWorkingFilePath;
    if (cwfp != null)
    {
      inner = cwfp;
    }
    if (state.currentWorkingFilePath == null || state.saveDataDirty)
    {
      inner += '*';
    }
    WindowUtil.setWindowTitle('Friday Night Funkin\' Chart Editor - ${inner} ');
  }

  public static function resetWindowTitle(state:ChartEditorState):Void
  {
    WindowUtil.setWindowTitle('Friday Night Funkin\'');
  }
}
#end
