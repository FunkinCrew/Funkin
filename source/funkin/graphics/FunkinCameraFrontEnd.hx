package funkin.graphics;

import flixel.FlxCamera;
import flixel.system.frontEnds.CameraFrontEnd;

/**
 * A `CameraFrontEnd` override that uses `FunkinCamera`!
 */
@:nullSafety
class FunkinCameraFrontEnd extends CameraFrontEnd
{
  override public function reset(?newCamera:FlxCamera):Void
  {
    super.reset(newCamera ?? new FunkinCamera());
  }
}
