package funkin.ui.debug.stageeditor.handlers;

import lime.utils.Bytes;
import flixel.util.FlxTimer;
import funkin.ui.debug.stageeditor.dialogs.StageEditorAboutDialog;
import funkin.ui.debug.stageeditor.dialogs.StageEditorBackupDialog;
import funkin.ui.debug.stageeditor.dialogs.StageEditorNewObjectDialog;
import funkin.ui.debug.stageeditor.dialogs.StageEditorURLObjectDialog;
import funkin.ui.debug.stageeditor.dialogs.StageEditorUserGuideDialog;
import funkin.ui.debug.stageeditor.dialogs.StageEditorWelcomeDialog;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogDropTarget;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;

/**
 * Handles dialogs for the new Stage Editor.
 */
@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorDialogHandler
{
  /**
   * Builds and opens a dialog giving brief credits for the stage editor.
   * @param state The current stage editor state.
   * @return The dialog that was opened.
   */
  public static function openAboutDialog(state:StageEditorState, closable:Bool = true):Null<Dialog>
  {
    var dialog = StageEditorAboutDialog.build(state, closable);

    dialog.zIndex = 1000;
    state.isHaxeUIDialogOpen = true;

    return dialog;
  }

  /**
   * Builds and opens a dialog letting the user create a new stage, open a recent stage, or load from a template.
   * @param state The current stage editor state.
   * @param closable Whether the dialog can be closed by the user.
   * @return The dialog that was opened.
   */
  public static function openWelcomeDialog(state:StageEditorState, closable:Bool = true):Null<Dialog>
  {
    var dialog = StageEditorWelcomeDialog.build(state, closable);

    dialog.zIndex = 1000;
    state.isHaxeUIDialogOpen = true;

    return dialog;
  }

  public static function openURLObjectDialog(state:StageEditorState, callback:Bytes->Void, onFail:Void->Void):Null<Dialog>
  {
    var dialog = StageEditorURLObjectDialog.build(state, callback, onFail);

    dialog.zIndex = 1000;
    state.isHaxeUIDialogOpen = true;

    return dialog;
  }

  /**
   * Builds and opens a dialog letting the user create a new object.
   *
   * @param state The current stage editor state.
   * @return The dialog that was opened.
   */
  public static function openNewObjectDialog(state:StageEditorState, ?bitmapData:openfl.display.BitmapData, ?closable:Bool, ?modal:Bool):Null<Dialog>
  {
    var dialog = StageEditorNewObjectDialog.build(state, bitmapData, closable, modal);

    dialog.zIndex = 1000;
    state.isHaxeUIDialogOpen = true;

    return dialog;
  }

  public static function openBackupAvailableDialog(state:StageEditorState, welcomeDialog:Null<Dialog>, ?closable:Bool, ?modal:Bool):Null<Dialog>
  {
    var dialog = StageEditorBackupDialog.build(state, welcomeDialog, closable, modal);

    dialog.zIndex = 1000;
    state.isHaxeUIDialogOpen = true;

    return dialog;
  }

  /**
   * Builds and opens a dialog where the user can confirm to leave the stage editor if they have unsaved changes.
   * @param state The current stage editor state.
   * @return The dialog that was opened.
   */
  public static function openLeaveConfirmationDialog(state:StageEditorState):Dialog
  {
    var dialog:Null<Dialog> = Dialogs.messageBox("You are about to leave the editor without saving.\n\nAre you sure?", "Leave Editor",
      MessageBoxType.TYPE_YESNO, true, button -> {
        state.isHaxeUIDialogOpen = false;
        if (button == DialogButton.YES)
        {
          state.autoSave();
          state.quitStageEditor();
        }
    });

    dialog.destroyOnClose = true;
    state.isHaxeUIDialogOpen = true;

    dialog.onDialogClosed = _ -> {
      state.isHaxeUIDialogOpen = false;
    };

    dialog.zIndex = 1000;

    return dialog;
  }

  /**
   * Builds and opens a dialog displaying the user guide, providing guidance and help on how to use the stage editor.
   *
   * @param state The current stage editor state.
   * @return The dialog that was opened.
   */
  public static function openUserGuideDialog(state:StageEditorState, closable:Bool = true):Null<Dialog>
  {
    var dialog = StageEditorUserGuideDialog.build(state, closable);

    dialog.zIndex = 1000;
    state.isHaxeUIDialogOpen = true;

    return dialog;
  }

  /**
   * ==============================
   * DROP HANDLERS
   * ==============================
   */
  static var dropHandlers:Array<DialogDropTarget> = [];

    /**
   * Add a callback for when a file is dropped on a component.
   *
   * On OS X you can’t drop on the application window, but rather only the app icon
   * (either in the dock while running or the icon on the hard drive) so this must be disabled
   * and UI updated appropriately.
   */
  public static function addDropHandler(state:StageEditorState, dropTarget:DialogDropTarget):Void
  {
    #if desktop
    if (!FlxG.stage.window.onDropFile.has(onDropFile)) FlxG.stage.window.onDropFile.add(onDropFile);

    dropHandlers.push(dropTarget);
    #else
    trace('addDropHandler not implemented for this platform');
    #end
  }

  /**
   * Remove a callback for when a file is dropped on a component.
   */
  public static function removeDropHandler(state:StageEditorState, dropTarget:DialogDropTarget):Void
  {
    #if desktop
    dropHandlers.remove(dropTarget);
    #end
  }

  /**
   * Clear ALL drop handlers, including the core handler.
   * Call this only when leaving the stage editor entirely.
   */
  public static function clearDropHandlers(state:StageEditorState):Void
  {
    #if desktop
    dropHandlers = [];
    FlxG.stage.window.onDropFile.remove(onDropFile);
    #end
  }

  static final EPSILON:Float = 0.01;

  static function onDropFile(path:String):Void
  {
    // a VERY short timer to wait for the mouse position to update
    new FlxTimer().start(EPSILON, function(_) {
      for (handler in dropHandlers)
      {
        if (handler.component.hitTest(FlxG.mouse.viewX, FlxG.mouse.viewY))
        {
          handler.handler(path);
          return;
        }
      }
    });
  }
}
