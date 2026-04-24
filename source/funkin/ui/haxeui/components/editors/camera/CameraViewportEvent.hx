package funkin.ui.haxeui.components.editors.camera;

import haxe.ui.events.EventType;
import haxe.ui.events.UIEvent;

class CameraViewportEvent extends UIEvent
{
  public static inline var ZOOM:EventType<CameraViewportEvent> = "cameraViewportZoom";
  public static inline var PAN_START:EventType<CameraViewportEvent> = "cameraViewportPanStart";
  public static inline var PAN:EventType<CameraViewportEvent> = "cameraViewportPan";
  public static inline var PAN_END:EventType<CameraViewportEvent> = "cameraViewportPanEnd";
  public static inline var GESTURE_PAN:EventType<CameraViewportEvent> = "cameraViewportGesturePan";

  public var zoomDelta:Float = 0;
  public var panDeltaX:Float = 0;
  public var panDeltaY:Float = 0;

  public function new(type:String)
  {
    super(type);
  }

  override public function clone():CameraViewportEvent
  {
    var c = new CameraViewportEvent(type);
    c.type = type;
    c.bubble = bubble;
    c.target = target;
    c.data = data;
    c.canceled = canceled;
    c.zoomDelta = zoomDelta;
    c.panDeltaX = panDeltaX;
    c.panDeltaY = panDeltaY;
    postClone(c);
    return c;
  }
}
