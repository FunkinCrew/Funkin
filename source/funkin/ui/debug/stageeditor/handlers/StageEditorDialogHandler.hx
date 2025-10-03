package funkin.ui.debug.stageeditor.handlers;

import lime.utils.Bytes;
import flixel.util.FlxTimer;
import funkin.ui.debug.stageeditor.dialogs.StageEditorAboutDialog;
import funkin.ui.debug.stageeditor.dialogs.StageEditorNewObjectDialog;
import funkin.ui.debug.stageeditor.dialogs.StageEditorURLObjectDialog;
import funkin.ui.debug.stageeditor.dialogs.StageEditorWelcomeDialog;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogDropTarget;
import haxe.io.Path;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.containers.Form;
import haxe.ui.containers.menus.Menu;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;
import haxe.ui.RuntimeComponentBuilder;

/**
 * Handles dialogs for the new Stage Editor.
*/
@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorDialogHandler
{
  // Paths to HaxeUI layout files for each dialog.

  public static function openAboutDialog(state:StageEditorState, closable:Bool = true):Null<Dialog>
  {
    var dialog = StageEditorAboutDialog.build(state, closable);

    dialog.zIndex = 1000;

    return dialog;
  }

  public static function openWelcomeDialog(state:StageEditorState, closable:Bool = true):Null<Dialog>
  {
    var dialog = StageEditorWelcomeDialog.build(state, closable);

    dialog.zIndex = 1000;

    return dialog;
  }

  public static function openURLObjectDialog(state:StageEditorState, callback:Bytes->Void, onFail:Void->Void):Null<Dialog>
  {
    var dialog = StageEditorURLObjectDialog.build(state, callback, onFail);

    dialog.zIndex = 1000;

    return dialog;
  }

  public static function openNewObjectDialog(state:StageEditorState, ?bitmapData:openfl.display.BitmapData = null, ?closable:Bool, ?modal:Bool):Null<Dialog>
  {
    var dialog = StageEditorNewObjectDialog.build(state, bitmapData, closable, modal);

    dialog.zIndex = 1000;

    return dialog;
  }

  static var dropHandlers:Array<DialogDropTarget> = [];

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
