package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.play.event.ZoomCameraSongEvent;
import funkin.ui.haxeui.components.editors.camera.EaseGraphPreview;
import haxe.ui.events.UIEvent;

/**
 * The contents of the Properties panel, while a Zoom Camera event is selected.
 */
@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/data/ui/camera-editor/components/properties/zoom-camera.xml'))
class ZoomCameraContainer extends BaseEventContainer
{
  public function new(state:CameraEditorState)
  {
    super(state);
    zoomCameraEaseFrame.easeGraphPreview.event = cameraEditorState.selectedSongEvent;

    bindFloatField(zoomCameraDuration, 'duration');

    zoomCameraEaseFrame.easeGraphPreview.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void {
      updateCameraPreview();
      updateBlockVisuals();
    });
  }

  override function getEasePreview():Null<EaseGraphPreview>
  {
    return zoomCameraEaseFrame.easeGraphPreview;
  }

  /**
   * Loads the data for the currently selected event into the UI.
   */
  public function loadCurrentEventData():Void
  {
    if (cameraEditorState.selectedSongEvent == null) return;

    var modeType:String = cameraEditorState.selectedSongEvent.getString('mode') ?? ZoomCameraSongEvent.DEFAULT_MODE;
    if (modeType == 'stage')
    {
      zoomCameraMode.selectedIndex = 0;
    }
    else if (modeType == 'direct')
    {
      zoomCameraMode.selectedIndex = 1;
    }

    zoomCameraZoomLevel.value = cameraEditorState.selectedSongEvent.getFloat('zoom') ?? ZoomCameraSongEvent.DEFAULT_ZOOM;
    zoomCameraZoomLevelSlider.value = zoomCameraZoomLevel.value;
    loadFloatField(zoomCameraDuration, 'duration', ZoomCameraSongEvent.DEFAULT_DURATION);

    zoomCameraEaseFrame.easeGraphPreview.event = cameraEditorState.selectedSongEvent;
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

    cameraEditorState.selectedSongEvent.set('mode', value);
    updateCameraPreview();
  }

}
#end
