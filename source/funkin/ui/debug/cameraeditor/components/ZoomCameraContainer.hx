package funkin.ui.debug.cameraeditor.components;

import funkin.play.event.ZoomCameraSongEvent;
#if FEATURE_CAMERA_EDITOR
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;

/**
 * The contents of the Properties panel, while a Zoom Camera event is selected.
 */
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/camera-editor/components/properties/zoom-camera.xml"))
class ZoomCameraContainer extends VBox
{
  public var cameraEditorState:CameraEditorState;

  public function new(state:CameraEditorState)
  {
    super();
    cameraEditorState = state;
    zoomCameraEasePreview.event = cameraEditorState.selectedSongEvent;
  }

  @:bind(zoomCameraEasePreview, UIEvent.CHANGE)
  function onChange_zoomCameraEasePreview(_):Void
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
    var modeType:String = cameraEditorState.selectedSongEvent.getString('mode') ?? ZoomCameraSongEvent.DEFAULT_MODE;
    if (modeType == 'stage') zoomCameraMode.selectedIndex = 0;
    else if (modeType == 'direct') zoomCameraMode.selectedIndex = 1;

    zoomCameraZoomLevel.value = cameraEditorState.selectedSongEvent.getFloat('zoom') ?? ZoomCameraSongEvent.DEFAULT_ZOOM;
    zoomCameraZoomLevelSlider.value = zoomCameraZoomLevel.value;
    zoomCameraDuration.value = cameraEditorState.selectedSongEvent.getFloat('duration') ?? ZoomCameraSongEvent.DEFAULT_DURATION;

    zoomCameraEasePreview.event = cameraEditorState.selectedSongEvent;
    updateCameraPreview();
    updateBlockVisuals();
  }

  /**
   * Called when the Zoom Level number stepper is changed.
   */
  @:bind(zoomCameraZoomLevel, UIEvent.CHANGE)
  function onChange_zoomCameraZoomLevel(_):Void
  {
    var value:Float = zoomCameraZoomLevel.value;

    trace('Zoom Camera: Zoom Level changed to ' + value);

    if (zoomCameraZoomLevelSlider != null && zoomCameraZoomLevel.value != zoomCameraZoomLevelSlider.value)
    {
      zoomCameraZoomLevelSlider.value = zoomCameraZoomLevel.value;
    }

    cameraEditorState.selectedSongEvent.set('zoom', value);
    updateCameraPreview();
  }

  /**
   * Called when the Zoom Level slider is changed.
   */
  @:bind(zoomCameraZoomLevelSlider, UIEvent.CHANGE)
  function onChange_zoomCameraZoomLevelSlider(_):Void
  {
    var value:Float = zoomCameraZoomLevelSlider.value;

    trace('Zoom Camera: Zoom Level changed to ' + value);

    if (zoomCameraZoomLevel != null && zoomCameraZoomLevel.value != zoomCameraZoomLevelSlider.value)
    {
      zoomCameraZoomLevel.value = zoomCameraZoomLevelSlider.value;
    }

    cameraEditorState.selectedSongEvent.set('zoom', value);
    updateCameraPreview();
  }

  /**
   * Called when the Zoom Mode field is changed.
   */
  @:bind(zoomCameraMode, UIEvent.CHANGE)
  function onChange_zoomCameraMode(_):Void
  {
    if (zoomCameraMode.selectedItem == null)
    {
      cameraEditorState.selectedSongEvent.set('mode', ZoomCameraSongEvent.DEFAULT_MODE);
      return;
    }

    var index:Int = zoomCameraMode.selectedIndex;
    var value:String = 'stage';
    if (index == 1) value = 'direct';

    trace('Zoom Camera: Mode changed to ' + value);

    cameraEditorState.selectedSongEvent.set('mode', value);
    updateCameraPreview();
  }

  /**
   * Called when the Zoom Camera Duration field is changed.
   */
  @:bind(zoomCameraDuration, UIEvent.CHANGE)
  function onChange_zoomCameraDuration(_):Void
  {
    var value:Float = zoomCameraDuration.value;

    cameraEditorState.selectedSongEvent.set('duration', value);
    updateCameraPreview();
    updateBlockVisuals();
  }

  override public function destroy():Void
  {
    super.destroy();
    zoomCameraEasePreview.cleanup();
  }
}
#end
