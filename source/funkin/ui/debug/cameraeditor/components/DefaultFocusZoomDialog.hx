package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.ui.debug.cameraeditor.CameraEditorState;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.events.MouseEvent;

/**
 * The dialog for setting the default camera focus and zoom for a song.
 */
@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/ui/editors/camera-editor/dialogs/default-focus-zoom.xml'))
class DefaultFocusZoomDialog extends Dialog
{
  var cameraEditorState:CameraEditorState;

  public function new(state:CameraEditorState)
  {
    super();
    cameraEditorState = state;

    var metadata = state.currentSongMetadata;
    if (metadata != null)
    {
      defaultCameraZoom.value = metadata.playData.defaultCameraZoom ?? 1.0;
      defaultCameraFocus.selectItemBy((data) -> Std.parseInt(data.id) == (metadata.playData.defaultCameraFocus ?? 1));
      forceCameraZoom.selected = metadata.playData.forceCameraZoom ?? false;
    }
  }

  @:bind(dialogCancel, MouseEvent.CLICK)
  function onClickCancel(_):Void
  {
    hideDialog(DialogButton.CANCEL);
  }

  @:bind(dialogApply, MouseEvent.CLICK)
  function onClickApply(_):Void
  {
    var selectedItem = defaultCameraFocus.selectedItem;
    if (selectedItem == null) throw 'Default camera focus selection is missing.';

    var focus:Null<Int> = Std.parseInt(selectedItem.id);
    if (focus == null) throw 'Default camera focus selection is invalid.';

    cameraEditorState.setDefaultCameraFocusZoom(defaultCameraZoom.value, focus, forceCameraZoom.selected);
    hideDialog(DialogButton.APPLY);
  }
}
#end
