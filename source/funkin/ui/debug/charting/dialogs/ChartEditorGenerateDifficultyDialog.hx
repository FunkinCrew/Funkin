package funkin.ui.debug.charting.dialogs;

import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import funkin.ui.debug.charting.components.ChartEditorDifficultyItem;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;

// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/dialogs/generate-difficulty.xml"))
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorGenerateDifficultyDialog extends ChartEditorBaseDialog
{
  public function new(state2:ChartEditorState, params2:DialogParams)
  {
    super(state2, params2);

    dialogCancel.onClick = function(_) {
      hideDialog(DialogButton.CANCEL);
    }

    dialogHints.onClick = function(_) {
      generateDifficulties(true);
      hideDialog(DialogButton.APPLY);
    };

    dialogNotes.onClick = function(_) {
      generateDifficulties(false);
      hideDialog(DialogButton.APPLY);
    };

    difficultyView.addComponent(new ChartEditorDifficultyItem(state2, difficultyView));

    chartEditorState.isHaxeUIDialogOpen = true;
  }

  function generateDifficulties(onlyHints:Bool):Void
  {
    for (item in difficultyView.findComponents(null, ChartEditorDifficultyItem))
    {
      if (!item.difficultyFrame.hidden && item.difficultyDropdown.value != null)
      {
        chartEditorState.generateChartDifficulty(
          {
            difficultyId: item.difficultyDropdown.value.value,
            algorithm: RemoveNthTooClose(item.nStepper.value),
            onlyHints: onlyHints
          });
      }
    }
  }

  // TODO: this should probably not be in the update function
  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    dialogHints.disabled = cast(difficultyView.getComponentAt(0), ChartEditorDifficultyItem).difficultyFrame.hidden;
    dialogNotes.disabled = cast(difficultyView.getComponentAt(0), ChartEditorDifficultyItem).difficultyFrame.hidden;
  }

  public override function onClose(event:DialogEvent):Void
  {
    super.onClose(event);

    chartEditorState.isHaxeUIDialogOpen = false;
  }

  public override function lock():Void
  {
    super.lock();
    this.dialogCancel.disabled = true;
  }

  public override function unlock():Void
  {
    super.unlock();
    this.dialogCancel.disabled = false;
  }

  public static function build(state:ChartEditorState, ?closable:Bool, ?modal:Bool):ChartEditorGenerateDifficultyDialog
  {
    var dialog = new ChartEditorGenerateDifficultyDialog(state,
      {
        closable: closable ?? false,
        modal: modal ?? true
      });

    dialog.showDialog(modal ?? true);

    return dialog;
  }
}
