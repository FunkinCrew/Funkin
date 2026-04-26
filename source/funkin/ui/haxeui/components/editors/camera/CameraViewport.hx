package funkin.ui.haxeui.components.editors.camera;

import flixel.input.keyboard.FlxKey;
import haxe.ui.containers.Box;
import haxe.ui.core.Screen;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;
#if FEATURE_MACOS_GESTURES
import lime.ui.Gesture;
import lime.ui.Gesture.GestureType;
import funkin.input.macos.FunkinGesture;
#end

@:composite(CameraViewportEvents)
class CameraViewport extends Box {}

private enum PanSource
{
  NONE;
  MIDDLE_MOUSE;
  ALT_KEY;
}

@:dox(hide) @:noCompletion
private class CameraViewportEvents extends haxe.ui.events.Events
{
  #if FEATURE_MACOS_GESTURES
  static final MAGNIFICATION_SCALE:Float = 10.0;
  static final PAN_SCALE:Float = 0.5;

  var gesture:FunkinGesture;
  #end
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

    #if FEATURE_MACOS_GESTURES
    if (gesture == null)
    {
      var gestureParams:FunkinGestureParams = {};
      gestureParams.preGestureStart = preGestureStart;
      gestureParams.onGestureStart = onGestureStart;
      gestureParams.onGestureEnd = onGestureEnd;
      gestureParams.onMagnificationGesture = onMagnificationGesture;
      gestureParams.onScrollGesture = onScrollGesture;

      gesture = new FunkinGesture(gestureParams);
    }
    #end
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

    #if FEATURE_MACOS_GESTURES
    if (gesture != null)
    {
      gesture.destroy();
      gesture = null;
    }
    #end
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
    if (e.keyCode != FlxKey.ALT) return;
    if (!_isMouseOverViewport) return;
    if (_panSource != NONE) return;
    _beginPan(ALT_KEY);
  }

  function _onKeyUp(e:KeyboardEvent):Void
  {
    if (e.keyCode != FlxKey.ALT) return;
    if (_panSource != ALT_KEY) return;
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

  #if FEATURE_MACOS_GESTURES
  function _hitTest(x:Float, y:Float):Bool
  {
    return x >= _viewport.screenLeft
      && x <= _viewport.screenLeft + _viewport.width
      && y >= _viewport.screenTop
      && y <= _viewport.screenTop + _viewport.height;
  }

  function preGestureStart(g:Gesture):Bool
  {
    return _hitTest(FlxG.mouse.viewX, FlxG.mouse.viewY);
  }

  function onGestureStart(g:Gesture):Void
  {
    if (hasEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel)) unregisterEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);

    if (g.type == SCROLL)
    {
      _viewport.dispatch(new CameraViewportEvent(CameraViewportEvent.PAN_START));
    }
  }

  function onGestureEnd(g:Gesture):Void
  {
    if (!hasEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel)) registerEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);

    if (g.type == SCROLL)
    {
      _viewport.dispatch(new CameraViewportEvent(CameraViewportEvent.PAN_END));
    }
  }

  function onMagnificationGesture(delta:Float):Void
  {
    var event = new CameraViewportEvent(CameraViewportEvent.ZOOM);
    event.zoomDelta = delta * MAGNIFICATION_SCALE;
    _viewport.dispatch(event);
  }

  function onScrollGesture(delta:Array<Float>):Void
  {
    var event = new CameraViewportEvent(CameraViewportEvent.GESTURE_PAN);
    event.panDeltaX = delta[0] * PAN_SCALE;
    event.panDeltaY = delta[1] * PAN_SCALE;
    _viewport.dispatch(event);
  }
  #end
}
