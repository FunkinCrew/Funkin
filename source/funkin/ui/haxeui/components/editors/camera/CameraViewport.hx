package funkin.ui.haxeui.components.editors.camera;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import haxe.ui.containers.Box;
import haxe.ui.core.Screen;
import haxe.ui.events.KeyboardEvent;
import haxe.ui.events.MouseEvent;
#if FEATURE_MACOS_GESTURES
import lime.ui.Gesture;
import lime.ui.Gesture.GestureType;
import funkin.input.macos.FunkinGesture;
import funkin.util.HaxeUIUtil;
#end

@:composite(CameraViewportEvents)
class CameraViewport extends Box
{
  public static inline var TRACKPAD_PAN_SCALE:Float = 25.0;

  public function handleTrackpadScroll():Void
  {
    var dx:Float = FlxG.mouse.deltaWheel.x;
    var dy:Float = FlxG.mouse.deltaWheel.y;
    if (dx == 0 && dy == 0) return;
    if (FlxG.keys.pressed.SHIFT) return;
    if (FlxG.mouse.gameX < screenLeft || FlxG.mouse.gameX > screenLeft + width
      || FlxG.mouse.gameY < screenTop || FlxG.mouse.gameY > screenTop + height) return;

    if (FlxG.keys.pressed.CONTROL)
    {
      if (dy == 0) return;
      var zoomEvent:CameraViewportEvent = new CameraViewportEvent(CameraViewportEvent.ZOOM);
      zoomEvent.zoomDelta = dy;
      dispatch(zoomEvent);
      return;
    }

    var panEvent:CameraViewportEvent = new CameraViewportEvent(CameraViewportEvent.GESTURE_PAN);
    panEvent.panDeltaX = -dx * TRACKPAD_PAN_SCALE;
    panEvent.panDeltaY = dy * TRACKPAD_PAN_SCALE;
    dispatch(panEvent);
  }
}

private enum PanSource
{
  NONE;
  MIDDLE_MOUSE;
  ALT_KEY;
}

@:dox(hide)
@:noCompletion
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
    return x >= _viewport.screenLeft && x <= _viewport.screenLeft + _viewport.width && y >= _viewport.screenTop && y <= _viewport.screenTop + _viewport.height;
  }

  function preGestureStart(g:Gesture):Bool
  {
    if (HaxeUIUtil.isModalDialogOpen()) return false;
    return _hitTest(FlxG.mouse.gameX, FlxG.mouse.gameY);
  }

  function onGestureStart(g:Gesture):Void
  {
    if (g.type == SCROLL)
    {
      _viewport.dispatch(new CameraViewportEvent(CameraViewportEvent.PAN_START));
    }
  }

  function onGestureEnd(g:Gesture):Void
  {
    if (g.type == SCROLL)
    {
      _viewport.dispatch(new CameraViewportEvent(CameraViewportEvent.PAN_END));
    }
  }

  function onMagnificationGesture(delta:Float, x:Float, y:Float):Void
  {
    var event:CameraViewportEvent = new CameraViewportEvent(CameraViewportEvent.ZOOM);
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
