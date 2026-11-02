package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.ui.debug.cameraeditor.commands.EditEventPropertiesCommand;
import funkin.ui.haxeui.components.editors.camera.EaseGraphPreview;
import haxe.ui.components.CheckBox;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import funkin.ui.haxeui.components.editors.timeline.TimelineUtil;
import haxe.ui.events.UIEvent;

/**
 * Shared base for properties-panel containers in the Camera Editor.
 */
abstract class BaseEventContainer extends VBox implements EditorContainer
{
  public var cameraEditorState:CameraEditorState;

  /**
   * Every event being edited. All of them share the same event kind.
   */
  var editedEvents(get, never):Array<SongEventData>;

  function get_editedEvents():Array<SongEventData>
  {
    return cameraEditorState.selectedSongEvents;
  }

  /**
   * The event the panel reads its values from.
   */
  var primaryEvent(get, never):Null<SongEventData>;

  function get_primaryEvent():Null<SongEventData>
  {
    return editedEvents.length > 0 ? editedEvents[0] : null;
  }

  /**
   * A copy of each edited event's value as of the last recorded edit.
   */
  var lastSnapshot:Array<Dynamic> = [];

  public function new(state:CameraEditorState)
  {
    super();
    cameraEditorState = state;
    lastSnapshot = takeSnapshot();
  }

  function takeSnapshot():Array<Dynamic>
  {
    return [for (event in editedEvents) Reflect.copy(event.valueAsStruct())];
  }

  /**
   * Records what has changed since the last snapshot into the undo history.
   */
  function commitEdit():Bool
  {
    var current:Array<Dynamic> = takeSnapshot();
    if (current.length != lastSnapshot.length) return false;
    if (!snapshotsDiffer(lastSnapshot, current)) return false;
    EditEventPropertiesCommand.push(cameraEditorState, editedEvents, lastSnapshot, current);
    lastSnapshot = current;
    return true;
  }

  static function snapshotsDiffer(a:Array<Dynamic>, b:Array<Dynamic>):Bool
  {
    for (i in 0...a.length)
    {
      for (field in Reflect.fields(a[i]).concat(Reflect.fields(b[i])))
      {
        if (Reflect.field(a[i], field) != Reflect.field(b[i], field)) return true;
      }
    }
    return false;
  }

  /**
   * Points the panel at the current selection again, without rebuilding it.
   */
  public function reload():Void
  {
    lastSnapshot = takeSnapshot();
    loadCurrentEventData();
  }

  /**
   * Writes a value to the field on every edited event.
   */
  function setOnAll(fieldName:String, value:Dynamic):Void
  {
    for (event in editedEvents) event.set(fieldName, value);
  }

  /**
   * Copies a field from the primary event onto the other edited events.
   */
  function copyFromPrimary(fieldName:String):Void
  {
    final primary:Null<SongEventData> = primaryEvent;
    if (primary == null) return;
    final value:Dynamic = primary.getDynamic(fieldName);
    for (event in editedEvents)
    {
      if (event != primary) TimelineUtil.setEventField(event, fieldName, value);
    }
  }

  /**
   * Whether every edited event has the same value for the field.
   */
  function allMatch(fieldName:String, defaultValue:Dynamic):Bool
  {
    final primary:Null<SongEventData> = primaryEvent;
    if (primary == null) return true;
    final value:Dynamic = primary.getDynamic(fieldName) ?? defaultValue;
    for (event in editedEvents)
    {
      final other:Dynamic = event.getDynamic(fieldName) ?? defaultValue;
      if (other != value) return false;
    }
    return true;
  }

  /**
   * Fields only stay editable when they are the same.
   */
  function markShared(component:Component, shared:Bool):Void
  {
    component.disabled = !shared;
    component.tooltip = shared ? null : 'The selected events have different values';
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
    // Loading a selection also comes through here, the replay only matters when something changed.
    if (commitEdit()) cameraEditorState.requestCameraReplay();
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
    final selected:Null<SongEventData> = primaryEvent;
    if (selected == null) return;
    markShared(stepper, allMatch(fieldName, defaultValue));
    stepper.value = selected.getFloat(fieldName) ?? defaultValue;
  }

  /**
   * Wire `stepper.CHANGE` to write its value into the selected event's
   * `fieldName`, then refresh the camera preview (and block visuals when
   * `fieldAffectsBlockVisuals(fieldName)`). Call once from the constructor.
   */
  function bindFloatField(stepper:NumberStepper, fieldName:String):Void
  {
    stepper.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
    {
      if (primaryEvent == null || stepper.disabled) return;
      setOnAll(fieldName, stepper.value);
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
    final selected:Null<SongEventData> = primaryEvent;
    if (selected == null) return;
    markShared(field, allMatch(fieldName, defaultValue));
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
    field.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
    {
      if (primaryEvent == null || field.disabled) return;
      setOnAll(fieldName, field.text);
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
    final selected:Null<SongEventData> = primaryEvent;
    if (selected == null) return;
    markShared(field, allMatch(fieldName, defaultValue));
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
    field.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
    {
      if (primaryEvent == null || field.disabled) return;
      setOnAll(fieldName, field.selected);
      updateCameraPreview();
      if (fieldAffectsBlockVisuals(fieldName)) updateBlockVisuals();
    });
  }
}
#end
