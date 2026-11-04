package funkin.ui.debug.charting.handlers;

#if FEATURE_CHART_EDITOR
import flixel.util.FlxTimer;
import funkin.save.Save;
import funkin.util.Constants;
import funkin.util.WindowUtil;
import funkin.util.logging.CrashHandler;
import haxe.io.Path;
using Lambda;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorAutoSaveHandler
{
  /**
   * Setup timers and listeners to handle auto-save.
   */
  public static function setupAutoSave(state:ChartEditorState):Void
  {
    // Called when clicking the X button on the window.
    WindowUtil.windowExit.add(state.onWindowClose);

    // Called when the game crashes.
    CrashHandler.errorSignal.add(state.onWindowCrash);
    CrashHandler.criticalErrorSignal.add(state.onWindowCrash);

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
    if (needsAutoSave)
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

  /**
   * Called when the window was closed, to save a backup of the chart.
   * @param exitCode The exit code of the window. We use `-1` when calling the function due to a game crash.
   */
  public static function onWindowClose(state:ChartEditorState, exitCode:Int):Void
  {
    trace('Window exited with exit code: $exitCode');
    trace('Should save chart? ${state.saveDataDirty}');

    var needsAutoSave:Bool = state.saveDataDirty;

    state.writePreferences(needsAutoSave);

    if (needsAutoSave)
    {
      state.exportCurrentChartToFNFC(true, null);
    }
  }

  public static function onWindowCrash(state:ChartEditorState, message:String):Void
  {
    trace('Chart editor intercepted crash:');
    trace('${message}');

    trace('Should save chart? ${state.saveDataDirty}');

    var needsAutoSave:Bool = state.saveDataDirty;

    state.writePreferences(needsAutoSave);

    if (needsAutoSave)
    {
      state.exportCurrentChartToFNFC(true, null);
    }
  }

  public static function cleanupAutoSave(state:ChartEditorState):Void
  {
    WindowUtil.windowExit.remove(state.onWindowClose);
    CrashHandler.errorSignal.remove(state.onWindowCrash);
    CrashHandler.criticalErrorSignal.remove(state.onWindowCrash);
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
