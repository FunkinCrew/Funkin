package funkin.ui.debug.stageeditor.dialogs;

import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import funkin.ui.debug.stageeditor.commands.AddObjectCommand;
import openfl.display.BitmapData;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;

@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/data/ui/stage-editor/dialogs/new-object.xml'))
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorNewObjectDialog extends StageEditorBaseDialog
{
  public function new(state2:StageEditorState, ?bitmapData:BitmapData = null, params2:DialogParams)
  {
    super(state2, params2);

    buttons = DialogButton.CANCEL | '{{Create}}';
    defaultButton = '{{Create}}';

    this.onDialogClosed = function(e:DialogEvent) {
      if (e.button.toString() == '{{Create}}')
      {
        e.cancel();
        var objNames = [for (obj in stageEditorState.spriteArray) obj.name];
        var objectID = this.inputField.text;
        if (objectID == '' || objectID == null || objNames.contains(objectID))
        {
          this.inputField.swapClass('invalid-value', 'valid-value');
          stageEditorState.error('Problem Creating an Object',
            objNames.contains(objectID) ? 'Object with the name ' + objectID + ' already exists!' : 'Invalid object name!');
        }
        else
        {
          stageEditorState.performCommand(new AddObjectCommand(this.inputField.text, bitmapData));
        }
      }
    }
  }

  public static function build(stageEditorState:StageEditorState, ?bitmapData:BitmapData = null, ?closable:Bool, ?modal:Bool):StageEditorNewObjectDialog
  {
    var dialog = new StageEditorNewObjectDialog(stageEditorState, bitmapData,
      {
        closable: closable ?? false,
        modal: modal ?? true
      });

    dialog.showDialog(modal ?? true);

    return dialog;
  }
}
