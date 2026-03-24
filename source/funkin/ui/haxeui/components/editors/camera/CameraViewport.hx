package funkin.ui.haxeui.components.editors.camera;

import haxe.ui.containers.Box;
import haxe.ui.core.Screen;
import haxe.ui.events.MouseEvent;

@:composite(CameraViewportEvents)
class CameraViewport extends Box {}

@:dox(hide) @:noCompletion
private class CameraViewportEvents extends haxe.ui.events.Events
{
  var _viewport:CameraViewport;
  var _isPanning:Bool = false;

  public function new(viewport:CameraViewport)
  {
    super(viewport);
    _viewport = viewport;
  }

  override public function register():Void
  {
    if (!hasEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel)) registerEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
    if (!hasEvent(MouseEvent.MIDDLE_MOUSE_DOWN, _onMiddleMouseDown)) registerEvent(MouseEvent.MIDDLE_MOUSE_DOWN, _onMiddleMouseDown);
  }

  override public function unregister():Void
  {
    unregisterEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
    unregisterEvent(MouseEvent.MIDDLE_MOUSE_DOWN, _onMiddleMouseDown);
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    Screen.instance.unregisterEvent(MouseEvent.MIDDLE_MOUSE_UP, _onMiddleMouseUp);
  }

  function _onMouseWheel(e:MouseEvent):Void
  {
    var event = new CameraViewportEvent(CameraViewportEvent.ZOOM);
    event.zoomDelta = e.delta;
    _viewport.dispatch(event);
  }

  function _onMiddleMouseDown(e:MouseEvent):Void
  {
    _isPanning = true;
    Screen.instance.registerEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    Screen.instance.registerEvent(MouseEvent.MIDDLE_MOUSE_UP, _onMiddleMouseUp);
    _viewport.dispatch(new CameraViewportEvent(CameraViewportEvent.PAN_START));
  }

  function _onMouseMove(e:MouseEvent):Void
  {
    if (_isPanning)
      _viewport.dispatch(new CameraViewportEvent(CameraViewportEvent.PAN));
  }

  function _onMiddleMouseUp(e:MouseEvent):Void
  {
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    Screen.instance.unregisterEvent(MouseEvent.MIDDLE_MOUSE_UP, _onMiddleMouseUp);
    _isPanning = false;
    _viewport.dispatch(new CameraViewportEvent(CameraViewportEvent.PAN_END));
  }
}
