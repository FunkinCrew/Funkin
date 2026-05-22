package funkin.ui.debug.cameraeditor.handlers;

#if FEATURE_CAMERA_EDITOR
import funkin.data.event.SongEventRegistry;
import funkin.play.event.SongEvent;
import funkin.ui.debug.cameraeditor.components.EditorContainer;
import funkin.ui.debug.cameraeditor.components.FocusCameraContainer;
import funkin.ui.debug.cameraeditor.components.PlayAnimationContainer;
import funkin.ui.debug.cameraeditor.components.ZoomCameraContainer;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;

/**
 * Handles the properties panel on the right of the camera editor.
 *
 * Uses a `Map<String, Class<EditorContainer>>` registry to dispatch from
 * `SongEventData.eventKind` to the matching properties container. To add a
 * new event-kind editor:
 *   1. Create a new container under `components/` extending `BaseEventContainer`
 *      (recommended — inherits `cameraEditorState`, `updateCameraPreview()`,
 *      `updateBlockVisuals()`, the ease-preview teardown hook, and the
 *      `bind/loadFloatField` / `bind/loadStringField` / `bind/loadBoolField`
 *      helpers). The constructor must accept `(state:CameraEditorState)`;
 *      `loadCurrentEventData()` is abstract on the base. Override
 *      `getEasePreview()` to return your ease preview so the base can call
 *      `cleanup()` on destroy (omit the override entirely if your event has
 *      no ease/duration — the base's `null` default short-circuits the
 *      cleanup, as in `PlayAnimationContainer`).
 *   2. Add one line to `initialize()`: `registerContainer('YourKind', YourContainer);`
 *
 * Reference implementations:
 *   - `FocusCameraContainer` / `ZoomCameraContainer` — Float fields + ease preview.
 *   - `PlayAnimationContainer` — String / Bool fields, no ease, no duration.
 *
 * Containers with no shared concerns can also implement `EditorContainer`
 * directly, but most camera-event kinds want the `BaseEventContainer` plumbing.
 *
 * The `using` statement in `import.hx` allows you to call these functions on the CameraEditorState instance directly.
 */
@:nullSafety
@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class CameraEditorPropertiesPanelHandler
{
  /**
   * Registry of properties-panel containers, keyed by `SongEventData.eventKind`.
   *
   * Populated once by `initialize()` at editor startup. Each registered class
   * MUST implement `EditorContainer` and expose a constructor
   * `new(state:CameraEditorState)`.
   */
  static final containers:Map<String, Class<EditorContainer>> = new Map();

  /**
   * Bootstrap the registry. Called once from `CameraEditorState.create()`.
   */
  public static function initialize():Void
  {
    registerContainer('FocusCamera', FocusCameraContainer);
    registerContainer('ZoomCamera', ZoomCameraContainer);
    registerContainer('PlayAnimation', PlayAnimationContainer);
  }

  /**
   * Register an editor container class for a given event kind.
   *
   * @param eventKind The event kind to register.
   * @param containerClass The container class to register.
   */
  public static function registerContainer(eventKind:String, containerClass:Class<EditorContainer>):Void
  {
    containers.set(eventKind, containerClass);
  }

  /**
   * Initialize the properties panel when first opening the Camera Editor.
   * @param state The CameraEditorState to target.
   */
  public static function initializePropertiesPanel(state:CameraEditorState):Void
  {
    var hideButton = state.propertiesPanel.findComponent('propertiesPanelActionHide');
    if (hideButton != null)
    {
      hideButton.onClick = function(_)
      {
        hidePropertiesPanel(state);
      }
    }

    hidePropertiesPanel(state);
  }

  /**
   * Update the state of the Properties panel. Call this every frame.
   * @param state The CameraEditorState to target.
   * @param elapsed The elapsed time in seconds since the last frame.
   */
  public static function updatePropertiesPanel(state:CameraEditorState, elapsed:Float):Void {}

  /**
   * Hides the Properties panel and disables input.
   * @param state The CameraEditorState to target.
   */
  public static function hidePropertiesPanel(state:CameraEditorState):Void
  {
    state.removePropertiesContainer();
    state.propertiesPanel.hidden = true;
  }

  /**
   * Set the title of the Properties panel.
   * @param state The CameraEditorState to target.
   * @param title The title to use.
   */
  public static function setPropertiesContainerTitle(state:CameraEditorState, title:String):Void
  {
    if (state.propertiesPanel != null)
    {
      state.propertiesPanel.text = title;
    }
    else
    {
      trace(' ERROR '.error() + 'Could not locate properties container.');
    }
  }

  /**
   * Remove the contents of the Properties panel, clearing the space to add new fields.
   * @param state The CameraEditorState to target.
   */
  public static function removePropertiesContainer(state:CameraEditorState):Void
  {
    var propertiesContainer:Null<VBox> = state.propertiesPanel.findComponent('propertiesContainer');
    if (propertiesContainer != null)
    {
      var contentContainer = propertiesContainer.parentComponent;

      contentContainer.removeComponent(propertiesContainer);
      propertiesContainer.destroy();
    }
    else
    {
      // No complaining, you're trying to remove something that's already been removed!
    }
  }

  /**
   * Load the selected song event into the Properties panel.
   * @param state The CameraEditorState to target.
   */
  public static function loadSelectedSongEvent(state:CameraEditorState):Void
  {
    var selected:Null<funkin.data.song.SongData.SongEventData> = state.selectedSongEvent;
    if (selected == null)
    {
      hidePropertiesPanel(state);
      return;
    }

    var containerClass:Null<Class<EditorContainer>> = containers.get(selected.eventKind);
    if (containerClass == null)
    {
      hidePropertiesPanel(state);
      return;
    }

    useContainer(state, containerClass, selected.eventKind);
  }

  /**
   * Mount a properties container into the panel.
   */
  static function useContainer(state:CameraEditorState, containerClass:Class<EditorContainer>, eventKind:String):Void
  {
    state.propertiesPanel.hidden = false;
    state.removePropertiesContainer();

    var container:EditorContainer = Type.createInstance(containerClass, [state]);
    state.propertiesPanel.addComponent(cast(container, Component));

    container.loadCurrentEventData();

    state.setPropertiesContainerTitle(resolveTitle(eventKind));
  }

  /**
   * Resolve the panel title from the SongEventRegistry, falling back to the
   * eventKind string if the event isn't registered.
   */
  static function resolveTitle(eventKind:String):String
  {
    var event:Null<SongEvent> = SongEventRegistry.getEvent(eventKind);
    return event != null ? event.getTitle() : eventKind;
  }
}
#end
