package funkin.ui.haxeui.components.editors.camera;

import haxe.ui.containers.Box;
import haxe.ui.events.MouseEvent;

@:composite(CameraViewportEvents)
class CameraViewport extends Box {}

@:dox(hide) @:noCompletion
private class CameraViewportEvents extends haxe.ui.events.Events
{
  var _viewport:CameraViewport;

  public function new(viewport:CameraViewport)
  {
    super(viewport);
    _viewport = viewport;
  }

  override public function register():Void
  {
    if (!hasEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel))
      registerEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
  }

  override public function unregister():Void
  {
    unregisterEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
  }

  function _onMouseWheel(e:MouseEvent):Void
  {
    var event = new CameraViewportEvent(CameraViewportEvent.ZOOM);
    event.zoomDelta = e.delta;
    _viewport.dispatch(event);
  }
}
