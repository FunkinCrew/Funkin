package funkin.ui.debug.cameraeditor.handlers;

#if FEATURE_CAMERA_EDITOR
import haxe.ui.containers.Panel;
import haxe.ui.containers.VBox;
import haxe.ui.containers.HBox;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.DropDown;
import funkin.ui.debug.cameraeditor.components.FocusCameraContainer;
import funkin.ui.debug.cameraeditor.components.ZoomCameraContainer;

/**
 * Handles the properties panel on the right of the camera editor.
 *
 * The `using` statement in `import.hx` allows you to call these functions on the CameraEditorState instance directly.
 */
@:nullSafety
@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class CameraEditorPropertiesPanelHandler
{
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
      trace(' ERROR '.error() + "Could not locate properties container.");
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
    if (state.selectedSongEvent == null)
    {
      hidePropertiesPanel(state);
      return;
    }

    switch (state.selectedSongEvent.eventKind)
    {
      case 'ZoomCamera':
        useZoomCameraContainer(state);
      case 'FocusCamera':
        useFocusCameraContainer(state);
      default:
        hidePropertiesPanel(state);
    }
  }

  /**
   * Update the Properties panel to display the Zoom Camera event fields..
   * @param state The CameraEditorState to target.
   */
  public static function useZoomCameraContainer(state:CameraEditorState):Void
  {
    state.propertiesPanel.hidden = false;
    state.removePropertiesContainer();

    var zoomCameraContainer = new ZoomCameraContainer(state);
    state.propertiesPanel.addComponent(zoomCameraContainer);

    // Load current values.
    zoomCameraContainer.loadCurrentEventData();

    state.setPropertiesContainerTitle('Zoom Camera');
  }

  /**
   * Update the Properties panel to display the Focus Camera event fields..
   * @param state The CameraEditorState to target.
   */
  public static function useFocusCameraContainer(state:CameraEditorState):Void
  {
    state.propertiesPanel.hidden = false;
    state.removePropertiesContainer();

    var focusCameraContainer = new FocusCameraContainer(state);
    state.propertiesPanel.addComponent(focusCameraContainer);

    // Load current values.
    focusCameraContainer.loadCurrentEventData();

    state.setPropertiesContainerTitle('Focus Camera');
  }
}
#end
