package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.play.event.FocusCameraSongEvent;
import funkin.ui.haxeui.components.editors.camera.EaseGraphPreview;
import haxe.ui.events.UIEvent;

/**
 * The contents of the Properties panel, while a Focus Camera event is selected.
 */
@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/data/ui/camera-editor/components/properties/focus-camera.xml'))
class FocusCameraContainer extends BaseEventContainer
{
  public function new(state:CameraEditorState)
  {
    super(state);
    focusCameraEaseFrame.easeGraphPreview.defaultEase = FocusCameraSongEvent.DEFAULT_CAMERA_EASE;
    focusCameraEaseFrame.easeGraphPreview.classicEnabled = true;
    focusCameraEaseFrame.easeGraphPreview.event = cameraEditorState.selectedSongEvent;

    bindFloatField(focusCameraXPos, 'x');
    bindFloatField(focusCameraYPos, 'y');
    bindFloatField(focusCameraDuration, 'duration');

    focusCameraEaseFrame.easeGraphPreview.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void {
      updateCameraPreview();
      updateBlockVisuals();
    });
  }

  override function getEasePreview():Null<EaseGraphPreview>
  {
    return focusCameraEaseFrame.easeGraphPreview;
  }

  /**
   * Loads the data for the currently selected event into the UI.
   */
  public function loadCurrentEventData():Void
  {
    if (cameraEditorState.selectedSongEvent == null) return;

    var eventTarget:Int = cameraEditorState.selectedSongEvent.getInt('char') ?? FocusCameraSongEvent.DEFAULT_TARGET;
    focusCameraTarget.selectItemBy(function(data):Bool
    {
      var dataId:Int = Std.parseInt(data.id);
      return dataId == eventTarget;
    });

    loadFloatField(focusCameraXPos, 'x', FocusCameraSongEvent.DEFAULT_X_POSITION);
    loadFloatField(focusCameraYPos, 'y', FocusCameraSongEvent.DEFAULT_Y_POSITION);
    loadFloatField(focusCameraDuration, 'duration', FocusCameraSongEvent.DEFAULT_DURATION);

    focusCameraEaseFrame.easeGraphPreview.event = cameraEditorState.selectedSongEvent;
    updateCameraPreview();
    updateBlockVisuals();
  }

  /**
   * Called when the Focus Camera Target field is changed.
   */
  @:bind(focusCameraTarget, UIEvent.CHANGE)
  function onChange_focusCameraTarget(_):Void
  {
    if (focusCameraTarget.selectedItem == null)
    {
      cameraEditorState.selectedSongEvent.set('char', FocusCameraSongEvent.DEFAULT_TARGET);
      return;
    }

    var value:Int = Std.parseInt(focusCameraTarget.selectedItem.id);

    cameraEditorState.selectedSongEvent.set('char', value);
    updateCameraPreview();
  }

}
#end
