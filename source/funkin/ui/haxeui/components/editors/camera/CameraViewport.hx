package funkin.ui.haxeui.components.editors.camera;

import flixel.input.keyboard.FlxKey;
import haxe.ui.containers.Box;
import haxe.ui.core.Screen;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;

@:composite(CameraViewportEvents)
class CameraViewport extends Box {}

private enum PanSource
{
  NONE;
  MIDDLE_MOUSE;
  SHIFT_KEY;
}

@:dox(hide) @:noCompletion
private class CameraViewportEvents extends haxe.ui.events.Events
{
  var _viewport:CameraViewport;
  var _isPanning:Bool = false;
  var _isMouseOverViewport:Bool = false;
  var _panSource:PanSource = NONE;

  public function new(viewport:CameraViewport)
  {
    super(viewport);
    _viewport = viewport;
  }

  override public function register():Void
  {
    if (!hasEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel)) registerEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
    if (!hasEvent(MouseEvent.MIDDLE_MOUSE_DOWN, _onMiddleMouseDown)) registerEvent(MouseEvent.MIDDLE_MOUSE_DOWN, _onMiddleMouseDown);
    if (!hasEvent(MouseEvent.MOUSE_OVER, _onMouseOver)) registerEvent(MouseEvent.MOUSE_OVER, _onMouseOver);
    if (!hasEvent(MouseEvent.MOUSE_OUT, _onMouseOut)) registerEvent(MouseEvent.MOUSE_OUT, _onMouseOut);
    Screen.instance.registerEvent(KeyboardEvent.KEY_DOWN, _onKeyDown);
    Screen.instance.registerEvent(KeyboardEvent.KEY_UP, _onKeyUp);
  }

  override public function unregister():Void
  {
    unregisterEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
    unregisterEvent(MouseEvent.MIDDLE_MOUSE_DOWN, _onMiddleMouseDown);
    unregisterEvent(MouseEvent.MOUSE_OVER, _onMouseOver);
    unregisterEvent(MouseEvent.MOUSE_OUT, _onMouseOut);
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    Screen.instance.unregisterEvent(MouseEvent.MIDDLE_MOUSE_UP, _onMiddleMouseUp);
    Screen.instance.unregisterEvent(KeyboardEvent.KEY_DOWN, _onKeyDown);
    Screen.instance.unregisterEvent(KeyboardEvent.KEY_UP, _onKeyUp);
  }

  function _onMouseWheel(e:MouseEvent):Void
  {
    var event:CameraViewportEvent = new CameraViewportEvent(CameraViewportEvent.ZOOM);
    event.zoomDelta = e.delta;
    _viewport.dispatch(event);
  }

  function _onMouseOver(_:MouseEvent):Void
  {
    _isMouseOverViewport = true;
  }

  function _onMouseOut(_:MouseEvent):Void
  {
    _isMouseOverViewport = false;
  }

  function _onMiddleMouseDown(e:MouseEvent):Void
  {
    if (_panSource != NONE) return;
    Screen.instance.registerEvent(MouseEvent.MIDDLE_MOUSE_UP, _onMiddleMouseUp);
    _beginPan(MIDDLE_MOUSE);
  }

  function _onMouseMove(e:MouseEvent):Void
  {
    if (_isPanning) _viewport.dispatch(new CameraViewportEvent(CameraViewportEvent.PAN));
  }

  function _onMiddleMouseUp(e:MouseEvent):Void
  {
    Screen.instance.unregisterEvent(MouseEvent.MIDDLE_MOUSE_UP, _onMiddleMouseUp);
    if (_panSource != MIDDLE_MOUSE) return;
    _endPan();
  }

  function _onKeyDown(e:KeyboardEvent):Void
  {
    if (e.keyCode != FlxKey.SHIFT) return;
    if (!_isMouseOverViewport) return;
    if (_panSource != NONE) return;
    _beginPan(SHIFT_KEY);
  }

  function _onKeyUp(e:KeyboardEvent):Void
  {
    if (e.keyCode != FlxKey.SHIFT) return;
    if (_panSource != SHIFT_KEY) return;
    _endPan();
  }

  function _beginPan(source:PanSource):Void
  {
    _panSource = source;
    _isPanning = true;
    Screen.instance.registerEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    _viewport.customStyle.cursor = "grabbing";
    _viewport.invalidateComponentStyle();
    Screen.instance.setCursor("grabbing");
    _viewport.dispatch(new CameraViewportEvent(CameraViewportEvent.PAN_START));
  }

  function _endPan():Void
  {
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    _isPanning = false;
    _panSource = NONE;
    _viewport.customStyle.cursor = null;
    _viewport.invalidateComponentStyle();
    Screen.instance.setCursor("default");
    _viewport.dispatch(new CameraViewportEvent(CameraViewportEvent.PAN_END));
  }
}
