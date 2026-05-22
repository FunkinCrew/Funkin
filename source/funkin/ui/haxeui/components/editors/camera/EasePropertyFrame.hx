package funkin.ui.haxeui.components.editors.camera;

#if FEATURE_CAMERA_EDITOR
import haxe.ui.containers.Frame;

/**
 * The `Ease` collapsible frame used in camera-editor properties panels.
 * Wraps an `EaseGraphPreview` with consistent height/collapsible styling so
 * containers don't carry magic constants inline.
 *
 * The preview is accessible from the containing class via `easeGraphPreview`
 * (id), e.g. `myFrame.easeGraphPreview.event = selected;`.
 *
 * Example:
 *   <EasePropertyFrame id="focusCameraEaseFrame" />
 */
@:xml('
<frame text="Ease" collapsible="true" width="100%" height="180">
  <EaseGraphPreview id="easeGraphPreview" width="100%" height="100%" />
</frame>
')
class EasePropertyFrame extends Frame
{
  public function new()
  {
    super();
  }
}
#end
