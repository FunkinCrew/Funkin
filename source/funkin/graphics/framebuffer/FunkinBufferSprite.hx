package funkin.graphics.framebuffer;

import flixel.FlxCamera;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxRect;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;

using funkin.graphics.framebuffer.BitmapDataUtil;

/**
 * A `FunkinSprite` with its sole purpose of rendering a `FlxCamera`.
 */
@:access(funkin.graphics.FunkinCamera)
class FunkinBufferSprite extends FunkinSprite
{
  var _cameraBufferFrame:FlxFrame;
  var _usedCamera:FunkinCamera;

  override function get_width():Float
  {
    return _usedCamera._previousFrameTexture.width;
  }

  override function get_height():Float
  {
    return _usedCamera._previousFrameTexture.height;
  }

  public function new(x:Float = 0, y:Float = 0, camera:FunkinCamera)
  {
    super(x, y);

    _usedCamera = camera;

    // We need the previous frame from the camera
    _usedCamera.renderBuffer = true;

    @:privateAccess
    _cameraBufferFrame = new FlxFrame(new FlxGraphic('', null));
    _cameraBufferFrame.frame = FlxRect.get(0, 0, _usedCamera.width, _usedCamera.height);
    _cameraBufferFrame.parent.bitmap = _usedCamera._previousFrameTexture;
  }

  override function drawFrameComplex(frame:FlxFrame, camera:FlxCamera):Void
  {
    _cameraBufferFrame.frame.set(0, 0, _usedCamera._previousFrameTexture.width, _usedCamera._previousFrameTexture.height);

    final willUseRenderTexture = checkRenderTexture();
    final matrix = this._matrix;

    frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
    prepareDrawMatrix(matrix, camera);

    // The only time render texture would be used for this class is when filters are applied
    // So just applying the filters directly without checking is fine I think
    if (willUseRenderTexture && _cameraBufferFrame.parent.bitmap != null)
    {
      filterRenderer.applyFilters(_cameraBufferFrame.parent.bitmap);

      if (filtered)
      {
        camera.drawPixels(filterRenderer.graphic?.imageFrame.frame, null, matrix, colorTransform, blend, antialiasing, shader);
      }
      else
      {
        camera.drawPixels(_cameraBufferFrame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
      }
    }
    else
    {
      camera.drawPixels(_cameraBufferFrame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
    }
  }

  override function isOnScreen(?camera:FlxCamera):Bool
  {
    // Who knew that rendering an entire camera buffer to a sprite would fuck with its bounding box?
    return true;
  }
}
