package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.play.event.FocusCameraSongEvent;
import funkin.play.event.SongEvent;
import funkin.ui.haxeui.components.LabeledRow;
import funkin.ui.haxeui.components.editors.timeline.TimelineUtil;
import funkin.ui.haxeui.components.editors.camera.EaseGraphPreview;
import haxe.ui.events.UIEvent;

/**
 * The contents of the Properties panel, while a Focus Camera event is selected.
 */
@:build(haxe.ui.macros.ComponentMacros.build('assets/exclude/ui/editors/camera-editor/components/properties/focus-camera.xml'))
class FocusCameraContainer extends BaseEventContainer
{
  public function new(state:CameraEditorState)
  {
    super(state);
    focusCameraEaseFrame.easeGraphPreview.defaultEase = FocusCameraSongEvent.DEFAULT_CAMERA_EASE;
    focusCameraEaseFrame.easeGraphPreview.classicEnabled = true;
    focusCameraEaseFrame.easeGraphPreview.event = primaryEvent;

    bindFloatField(focusCameraXPos, 'x');
    bindFloatField(focusCameraYPos, 'y');
    bindFloatField(focusCameraDuration, 'duration');

    focusCameraEaseFrame.easeGraphPreview.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
    {
      onEasePreviewChange();
      showDuration();
    });
  }

  function showDuration():Void
  {
    var row:Null<LabeledRow> = focusCameraDuration.findAncestor(null, LabeledRow);
    if (row == null) return;
    var used:Bool = false;
    for (event in editedEvents)
    {
      if (!TimelineUtil.isFixedDuration(event)) used = true;
    }
    row.hidden = !used;
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
    if (primaryEvent == null) return;

    markShared(focusCameraTarget, allMatch('char', FocusCameraSongEvent.DEFAULT_TARGET));
    var eventTarget:Int = primaryEvent.getInt('char') ?? FocusCameraSongEvent.DEFAULT_TARGET;
    quietly(focusCameraTarget, () -> focusCameraTarget.selectItemBy(function(data):Bool
    {
      var dataId:Int = Std.parseInt(data.id);
      return dataId == eventTarget;
    }));
    rememberChoice(focusCameraTarget, eventTarget);

    loadFloatField(focusCameraXPos, 'x', FocusCameraSongEvent.DEFAULT_X_POSITION);
    loadFloatField(focusCameraYPos, 'y', FocusCameraSongEvent.DEFAULT_Y_POSITION);
    loadFloatField(focusCameraDuration, 'duration', FocusCameraSongEvent.DEFAULT_DURATION);
    showDuration();

    markShared(focusCameraEaseFrame, allMatch('ease', FocusCameraSongEvent.DEFAULT_CAMERA_EASE) && allMatch('easeDir', SongEvent.DEFAULT_EASE_DIR));
    focusCameraEaseFrame.easeGraphPreview.event = primaryEvent;
    rememberEase();
    updateCameraPreview();
    updateBlockVisuals();
  }

  /**
   * Called when the Focus Camera Target field is changed.
   */
  @:bind(focusCameraTarget, UIEvent.CHANGE)
  function onChange_focusCameraTarget(_):Void
  {
    if (primaryEvent == null || focusCameraTarget.disabled) return;
    if (focusCameraTarget.selectedItem == null) return;

    var value:Int = Std.parseInt(focusCameraTarget.selectedItem.id);
    if (!isUserChoiceChange(focusCameraTarget, value)) return;

    setOnAll('char', value);
    updateCameraPreview();
  }
}
#end
