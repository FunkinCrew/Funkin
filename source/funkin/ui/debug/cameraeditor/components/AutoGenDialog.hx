package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.events.MouseEvent;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorAutoGeneratorHandler;

/**
 * The dialog that appears when the user wants to automatically generate camera events.
 */
@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/data/ui/camera-editor/dialogs/auto-gen.xml'))
class AutoGenDialog extends Dialog
{
  var cameraEditorState:CameraEditorState = null;

  public function new(state:CameraEditorState)
  {
    super();

    this.cameraEditorState = state;
  }

  /**
   * Called when the Cancel button is clicked.
   */
  @:bind(dialogCancel, MouseEvent.CLICK)
  function onClickCancel(_):Void
  {
    this.hideDialog(DialogButton.CANCEL);
  }

  /**
   * Called when the Generate button is clicked.
   */
  @:bind(dialogGenerate, MouseEvent.CLICK)
  function onClickGenerate(_):Void
  {
    CameraEditorAutoGeneratorHandler.autoGenEvents(this.cameraEditorState, {
      placementMode: autoGenPlacementMode.selectedItem.id,
    });
    this.hideDialog(DialogButton.OK);
  }
}
#end
