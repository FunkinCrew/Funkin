package funkin.ui.haxeui.components.editors.camera;

import haxe.ui.events.EventType;
import haxe.ui.events.UIEvent;

class CameraViewportEvent extends UIEvent
{
  public static inline var ZOOM:EventType<CameraViewportEvent> = "cameraViewportZoom";

  public var zoomDelta:Float = 0;

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
    postClone(c);
    return c;
  }
}
