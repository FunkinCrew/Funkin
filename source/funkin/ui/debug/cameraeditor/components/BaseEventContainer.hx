package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.ui.haxeui.components.editors.camera.EaseGraphPreview;
import haxe.ui.components.CheckBox;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;

/**
 * Shared base for properties-panel containers in the Camera Editor.
 */
abstract class BaseEventContainer extends VBox implements EditorContainer
{
  public var cameraEditorState:CameraEditorState;

  public function new(state:CameraEditorState)
  {
    super();
    cameraEditorState = state;
  }

  /**
   * Populate UI controls from the currently-selected event.
   * Called once after construction by the dispatcher.
   */
  public abstract function loadCurrentEventData():Void;

  /**
   * Override to return the ease preview owned by this container, so the
   * base's `destroy()` can call `cleanup()`. Containers without an ease
   * preview return `null` (the default).
   */
  function getEasePreview():Null<EaseGraphPreview>
  {
    return null;
  }

  /**
   * Replays the camera timeline so the viewport reflects the edited values.
   * Call from any onChange handler that mutates a field affecting the
   * camera state at the current playhead.
   */
  function updateCameraPreview():Void
  {
    cameraEditorState.replayCameraTimeline(cameraEditorState.conductorInUse.songPosition);
  }

  /**
   * Refresh the timeline block visuals. Call from onChange handlers that
   * mutate a field affecting block layout (currently only `duration`).
   */
  function updateBlockVisuals():Void
  {
    cameraEditorState.timeline.viewport.refreshBlockVisuals(true);
  }

  override public function destroy():Void
  {
    super.destroy();
    final preview:Null<EaseGraphPreview> = getEasePreview();
    if (preview != null) preview.cleanup();
  }

  /**
   * Whether mutating the named field requires refreshing the timeline block
   * visuals. Override per-kind if a non-`duration` field also affects layout.
   */
  function fieldAffectsBlockVisuals(fieldName:String):Bool
  {
    return fieldName == 'duration';
  }

  /**
   * Pull the current event's Float value for `fieldName` into `stepper`,
   * falling back to `defaultValue` if the field is unset.
   * Call from `loadCurrentEventData()`.
   */
  function loadFloatField(stepper:NumberStepper, fieldName:String, defaultValue:Float):Void
  {
    final selected:Null<SongEventData> = cameraEditorState.selectedSongEvent;
    if (selected == null) return;
    stepper.value = selected.getFloat(fieldName) ?? defaultValue;
  }

  /**
   * Wire `stepper.CHANGE` to write its value into the selected event's
   * `fieldName`, then refresh the camera preview (and block visuals when
   * `fieldAffectsBlockVisuals(fieldName)`). Call once from the constructor.
   */
  function bindFloatField(stepper:NumberStepper, fieldName:String):Void
  {
    stepper.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void {
      final selected:Null<SongEventData> = cameraEditorState.selectedSongEvent;
      if (selected == null) return;
      selected.set(fieldName, stepper.value);
      updateCameraPreview();
      if (fieldAffectsBlockVisuals(fieldName)) updateBlockVisuals();
    });
  }

  /**
   * Pull the current event's String value for `fieldName` into `field`,
   * falling back to `defaultValue` if the field is unset.
   * Call from `loadCurrentEventData()`.
   */
  function loadStringField(field:TextField, fieldName:String, defaultValue:String):Void
  {
    final selected:Null<SongEventData> = cameraEditorState.selectedSongEvent;
    if (selected == null) return;
    final value:Null<String> = selected.getString(fieldName);
    field.text = value ?? defaultValue;
  }

  /**
   * Wire `field.CHANGE` to write its text into the selected event's
   * `fieldName`, then refresh the camera preview (and block visuals when
   * `fieldAffectsBlockVisuals(fieldName)`). Call once from the constructor.
   */
  function bindStringField(field:TextField, fieldName:String):Void
  {
    field.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void {
      final selected:Null<SongEventData> = cameraEditorState.selectedSongEvent;
      if (selected == null) return;
      selected.set(fieldName, field.text);
      updateCameraPreview();
      if (fieldAffectsBlockVisuals(fieldName)) updateBlockVisuals();
    });
  }

  /**
   * Pull the current event's Bool value for `fieldName` into `field`,
   * falling back to `defaultValue` if the field is unset.
   * Call from `loadCurrentEventData()`.
   */
  function loadBoolField(field:CheckBox, fieldName:String, defaultValue:Bool):Void
  {
    final selected:Null<SongEventData> = cameraEditorState.selectedSongEvent;
    if (selected == null) return;
    final value:Null<Bool> = selected.getBool(fieldName);
    field.selected = value ?? defaultValue;
  }

  /**
   * Wire `field.CHANGE` to write its selected state into the selected event's
   * `fieldName`, then refresh the camera preview (and block visuals when
   * `fieldAffectsBlockVisuals(fieldName)`). Call once from the constructor.
   */
  function bindBoolField(field:CheckBox, fieldName:String):Void
  {
    field.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void {
      final selected:Null<SongEventData> = cameraEditorState.selectedSongEvent;
      if (selected == null) return;
      selected.set(fieldName, field.selected);
      updateCameraPreview();
      if (fieldAffectsBlockVisuals(fieldName)) updateBlockVisuals();
    });
  }
}
#end
