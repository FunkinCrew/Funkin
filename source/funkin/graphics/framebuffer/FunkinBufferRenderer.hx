package funkin.graphics.framebuffer;

import flixel.FlxSprite;
import funkin.graphics.FunkinCamera;
import flixel.graphics.FlxGraphic;

using funkin.graphics.framebuffer.BitmapDataUtil;

/**
 * A renderer that renders a camera's framebuffer to a texture.
 */
@:nullSafety
class FunkinBufferRenderer
{
  /**
   * The rendered texture.
   */
  public var texture:FixedBitmapData;

  /**
   * If `true`, the buffer will only render sprites that are part of a whitelist.
   */
  public var useWhitelist:Bool = false;

  /**
   * Whether or not the buffer is active.
   * If `false`, the buffer will not render anything.
   */
  public var active:Bool = true;

  /**
   * The base zoom of the buffer.
   * The buffer will always render at this zoom.
   */
  public var zoom:Float = 1;

  /**
   * The delay before the buffer is rendered.
   * If set to `0`, the buffer will be rendered immediately.
   *
   * Could be useful for performance.
   */
  public var delay:Float = 0;

  var dirty:Bool = false;
  var _timer:Float = 0;
  var _camera:FunkinCamera;
  var _whiteList:Array<String> = [];
  var _blackList:Array<String> = [];

  public function new(camera:FunkinCamera)
  {
    this._camera = camera;
    texture = FixedBitmapData.create(camera.width, camera.height);
  }

  /**
   * Renders the buffer onto the texture.
   */
  public function render():Void
  {
    if (!active) return;

    if (delay > 0)
    {
      _timer += FlxG.elapsed;

      if (_timer > delay)
      {
        _timer = 0;
        drawPreviousFrame();
      }
    }
    else
    {
      drawPreviousFrame();
    }
  }

  /**
   * Whether or not the buffer should render the specified graphic.
   * @param graphic The graphic to check.
   * @return `true` if the graphic should be rendered, `false` otherwise.
   */
  public function shouldRender(graphic:FlxGraphic):Bool
  {
    // Skip rendering the actual buffer itself... onto the buffer.
    if (graphic.key == 'CAMERA_BUFFER')
    {
      return false;
    }

    if (_blackList.contains(graphic.key))
    {
      return false;
    }

    if (useWhitelist && !_whiteList.contains(graphic.key))
    {
      return false;
    }

    return !graphic.isDestroyed;
  }

  /**
   * Adds the specified sprite to the whitelist.
   * @param sprite The sprite to add.
   */
  public function whitelistSprite(sprite:FlxSprite):Void
  {
    if (_blackList.contains(sprite.graphic.key))
    {
      _blackList.remove(sprite.graphic.key);
    }

    if (!_whiteList.contains(sprite.graphic.key))
    {
      _whiteList.push(sprite.graphic.key);
    }
  }

  /**
   * Adds the specified sprite to the blacklist.
   * @param sprite The sprite to add.
   */
  public function blacklistSprite(sprite:FlxSprite):Void
  {
    if (_whiteList.contains(sprite.graphic.key))
    {
      _whiteList.remove(sprite.graphic.key);
    }

    if (!_blackList.contains(sprite.graphic.key))
    {
      _blackList.push(sprite.graphic.key);
    }
  }

  function drawPreviousFrame():Void
  {
    dirty = true;

    _camera.canvas.graphics.clear();

    if (zoom > 0)
    {
      _camera.setScale(zoom, zoom);
      texture.drawCameraScreen(_camera);
      _camera.setScale(_camera.zoom, _camera.zoom);
    }
    else
    {
      texture.drawCameraScreen(_camera);
    }

    dirty = false;
  }

  /**
   * Destroys the buffer renderer.
   */
  public function destroy():Void
  {
    texture.dispose();
  }
}
