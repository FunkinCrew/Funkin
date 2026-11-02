package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.play.event.SongEvent;
import funkin.play.event.ZoomCameraSongEvent;
import funkin.ui.haxeui.components.editors.camera.EaseGraphPreview;
import haxe.ui.events.UIEvent;

/**
 * The contents of the Properties panel, while a Zoom Camera event is selected.
 */
@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/ui/editors/camera-editor/components/properties/zoom-camera.xml'))
class ZoomCameraContainer extends BaseEventContainer
{
  public function new(state:CameraEditorState)
  {
    super(state);
    zoomCameraEaseFrame.easeGraphPreview.event = primaryEvent;

    bindFloatField(zoomCameraDuration, 'duration');
    bindFloatField(zoomCameraWidescreenScaleX, 'widescreenScaleX');
    bindFloatField(zoomCameraWidescreenScaleY, 'widescreenScaleY');

    zoomCameraEaseFrame.easeGraphPreview.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
    {
      copyFromPrimary('ease');
      copyFromPrimary('easeDir');
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
    if (primaryEvent == null) return;

    markShared(zoomCameraMode, allMatch('mode', ZoomCameraSongEvent.DEFAULT_MODE));
    var modeType:String = primaryEvent.getString('mode') ?? ZoomCameraSongEvent.DEFAULT_MODE;
    if (modeType == 'stage')
    {
      zoomCameraMode.selectedIndex = 0;
    }
    else if (modeType == 'direct')
    {
      zoomCameraMode.selectedIndex = 1;
    }

    var zoomShared:Bool = allMatch('zoom', ZoomCameraSongEvent.DEFAULT_ZOOM);
    markShared(zoomCameraZoomLevel, zoomShared);
    markShared(zoomCameraZoomLevelSlider, zoomShared);
    loadNumber(zoomCameraZoomLevel, primaryEvent.getFloat('zoom') ?? ZoomCameraSongEvent.DEFAULT_ZOOM);
    loadNumber(zoomCameraZoomLevelSlider, zoomCameraZoomLevel.value);

    loadFloatField(zoomCameraDuration, 'duration', ZoomCameraSongEvent.DEFAULT_DURATION);
    loadFloatField(zoomCameraWidescreenScaleX, 'widescreenScaleX', ZoomCameraSongEvent.DEFAULT_WIDESCREEN_SCALE);
    loadFloatField(zoomCameraWidescreenScaleY, 'widescreenScaleY', ZoomCameraSongEvent.DEFAULT_WIDESCREEN_SCALE);

    markShared(zoomCameraEaseFrame, allMatch('ease', SongEvent.DEFAULT_EASE) && allMatch('easeDir', SongEvent.DEFAULT_EASE_DIR));
    zoomCameraEaseFrame.easeGraphPreview.event = primaryEvent;
    updateCameraPreview();
    updateBlockVisuals();
  }

  /**
   * Called when the Zoom Level number stepper is changed.
   */
  @:bind(zoomCameraZoomLevel, UIEvent.CHANGE)
  function onChange_zoomCameraZoomLevel(_):Void
  {
    if (primaryEvent == null || zoomCameraZoomLevel.disabled) return;
    if (!isUserNumberChange(zoomCameraZoomLevel, zoomCameraZoomLevel.value)) return;
    var value:Float = zoomCameraZoomLevel.value;

    if (zoomCameraZoomLevelSlider != null && zoomCameraZoomLevel.value != zoomCameraZoomLevelSlider.value)
    {
      zoomCameraZoomLevelSlider.value = zoomCameraZoomLevel.value;
    }

    setOnAll('zoom', value);
    updateCameraPreview();
  }

  /**
   * Called when the Zoom Level slider is changed.
   */
  @:bind(zoomCameraZoomLevelSlider, UIEvent.CHANGE)
  function onChange_zoomCameraZoomLevelSlider(_):Void
  {
    if (primaryEvent == null || zoomCameraZoomLevelSlider.disabled) return;
    if (!isUserNumberChange(zoomCameraZoomLevelSlider, zoomCameraZoomLevelSlider.value)) return;
    var value:Float = zoomCameraZoomLevelSlider.value;

    if (zoomCameraZoomLevel != null && zoomCameraZoomLevel.value != zoomCameraZoomLevelSlider.value)
    {
      zoomCameraZoomLevel.value = zoomCameraZoomLevelSlider.value;
    }

    setOnAll('zoom', value);
    updateCameraPreview();
  }

  /**
   * Called when the Zoom Mode field is changed.
   */
  @:bind(zoomCameraMode, UIEvent.CHANGE)
  function onChange_zoomCameraMode(_):Void
  {
    if (primaryEvent == null || zoomCameraMode.disabled) return;
    if (zoomCameraMode.selectedItem == null)
    {
      setOnAll('mode', ZoomCameraSongEvent.DEFAULT_MODE);
      return;
    }

    var index:Int = zoomCameraMode.selectedIndex;
    var value:String = 'stage';
    if (index == 1) value = 'direct';

    setOnAll('mode', value);
    updateCameraPreview();
  }
}
#end
