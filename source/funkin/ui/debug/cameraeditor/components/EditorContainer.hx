package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR

/**
 * Common interface for camera-editor properties-panel containers.
 *
 * Each container is keyed in `CameraEditorPropertiesPanelHandler.containers`
 * by an event-kind string (e.g. `'FocusCamera'`, `'ZoomCamera'`) and is
 * instantiated when the user selects an event of that kind in the timeline.
 *
 */
interface EditorContainer
{
  /**
   * Pull the currently-selected event's field values into the UI controls.
   * Called once after construction by the dispatcher.
   */
  public function loadCurrentEventData():Void;
}
#end
