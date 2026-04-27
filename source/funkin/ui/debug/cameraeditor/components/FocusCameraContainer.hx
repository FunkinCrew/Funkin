package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.play.event.FocusCameraSongEvent;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;

/**
 * The contents of the Properties panel, while a Focus Camera event is selected.
 */
@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/data/ui/camera-editor/components/properties/focus-camera.xml'))
class FocusCameraContainer extends VBox
{
  public var cameraEditorState:CameraEditorState;

  public function new(state:CameraEditorState)
  {
    super();
    cameraEditorState = state;
    focusCameraEasePreview.defaultEase = FocusCameraSongEvent.DEFAULT_CAMERA_EASE;
    focusCameraEasePreview.classicEnabled = true;
    focusCameraEasePreview.event = cameraEditorState.selectedSongEvent;
  }

  @:bind(focusCameraEasePreview, UIEvent.CHANGE)
  function onChange_focusCameraEasePreview(_):Void
  {
    updateCameraPreview();
    updateBlockVisuals();
  }

  function updateCameraPreview():Void
  {
    cameraEditorState.replayCameraTimeline(cameraEditorState.conductorInUse.songPosition);
  }

  function updateBlockVisuals():Void
  {
    cameraEditorState.timeline.viewport.refreshBlockVisuals(true);
  }

  /**
   * Loads the data for the currently selected event into the UI.
   */
  public function loadCurrentEventData():Void
  {
    var eventTarget:Int = cameraEditorState.selectedSongEvent.getInt('char') ?? FocusCameraSongEvent.DEFAULT_TARGET;
    focusCameraTarget.selectItemBy(function(data):Bool
    {
      var dataId:Int = Std.parseInt(data.id);
      trace('${dataId} == ${eventTarget}');
      return dataId == eventTarget;
    });

    focusCameraXPos.value = cameraEditorState.selectedSongEvent.getFloat('x') ?? FocusCameraSongEvent.DEFAULT_X_POSITION;
    focusCameraYPos.value = cameraEditorState.selectedSongEvent.getFloat('y') ?? FocusCameraSongEvent.DEFAULT_Y_POSITION;
    focusCameraDuration.value = cameraEditorState.selectedSongEvent.getFloat('duration') ?? FocusCameraSongEvent.DEFAULT_DURATION;

    focusCameraEasePreview.event = cameraEditorState.selectedSongEvent;
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

  /**
   * Called when the Focus Camera X Position field is changed.
   */
  @:bind(focusCameraXPos, UIEvent.CHANGE)
  function onChange_focusCameraXPos(_):Void
  {
    var value:Float = focusCameraXPos.value;

    cameraEditorState.selectedSongEvent.set('x', value);
    updateCameraPreview();
  }

  /**
   * Called when the Focus Camera Y Position field is changed.
   */
  @:bind(focusCameraYPos, UIEvent.CHANGE)
  function onChange_focusCameraYPos(_):Void
  {
    var value:Float = focusCameraYPos.value;

    cameraEditorState.selectedSongEvent.set('y', value);
    updateCameraPreview();
  }

  /**
   * Called when the Focus Camera Duration field is changed.
   */
  @:bind(focusCameraDuration, UIEvent.CHANGE)
  function onChange_focusCameraDuration(_):Void
  {
    var value:Float = focusCameraDuration.value;

    cameraEditorState.selectedSongEvent.set('duration', value);
    updateCameraPreview();
    updateBlockVisuals();
  }

  override public function destroy():Void
  {
    super.destroy();
    focusCameraEasePreview.cleanup();
  }
}
#end
