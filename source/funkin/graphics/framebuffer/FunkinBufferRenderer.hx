package funkin.graphics.framebuffer;

import animate.FlxAnimateFrames.FlxAnimateSpritemapCollection;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxSignal;
import funkin.graphics.FunkinCamera;

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
   * A signal that fires before the buffer is about to be rendered.
   */
  public var onPreRender:FlxSignal = new FlxSignal();

  /**
   * A signal that fires after the buffer is rendered.
   */
  public var onPostRender:FlxSignal = new FlxSignal();

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
  var initialized:Bool = false;
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
   * Resizes the buffer to a new size.
   * @param width The new width.
   * @param height The new height.
   */
  public function resize(width:Int, height:Int):Void
  {
    if (texture != null)
    {
      texture.dispose();
    }

    texture = FixedBitmapData.create(width, height);
  }

  /**
   * Renders the buffer onto the texture.
   */
  public function render():Void
  {
    if (!active) return;
    if (useWhitelist && _whiteList.isEmpty()) return;

    if (delay > 0)
    {
      // Force the timer to start at the delay the first time it's rendered
      // Prevents a blank frame from being shown when the parent camera is first created
      if (!initialized)
      {
        initialized = true;
        _timer = delay;
      }

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
  public function whitelistSprite(sprite:Null<FlxSprite>):Void
  {
    if (sprite == null || sprite.graphic == null)
    {
      trace('WARNING: Tried to whitelist an invalid sprite.');
      return;
    }

    var graphicKeys:Array<String> = [sprite.graphic.key];

    // Texture atlases use a spritemap collection
    // We'll need to add all the spritemaps to the blacklist
    if (sprite.graphic is FlxAnimateSpritemapCollection)
    {
      var spritemaps:FlxAnimateSpritemapCollection = cast sprite.graphic;
      @:privateAccess
      for (spritemap in spritemaps.spritemaps)
      {
        graphicKeys.push(spritemap.key);
      }
    }

    for (key in graphicKeys)
    {
      if (_blackList.contains(key))
      {
        _blackList.remove(key);
      }

      if (!_whiteList.contains(key))
      {
        _whiteList.push(key);
      }
    }
  }

  /**
   * Adds the specified sprite to the blacklist.
   * @param sprite The sprite to add.
   */
  public function blacklistSprite(sprite:Null<FlxSprite>):Void
  {
    if (sprite == null || sprite.graphic == null)
    {
      trace('WARNING: Tried to blacklist an invalid sprite.');
      return;
    }

    var graphicKeys:Array<String> = [sprite.graphic.key];

    // Texture atlases use a spritemap collection
    // We'll need to add all the spritemaps to the blacklist
    if (sprite.graphic is FlxAnimateSpritemapCollection)
    {
      var spritemaps:FlxAnimateSpritemapCollection = cast sprite.graphic;
      @:privateAccess
      for (spritemap in spritemaps.spritemaps)
      {
        graphicKeys.push(spritemap.key);
      }
    }

    for (key in graphicKeys)
    {
      if (_whiteList.contains(key))
      {
        _whiteList.remove(key);
      }

      if (!_blackList.contains(key))
      {
        _blackList.push(key);
      }
    }
  }

  function drawPreviousFrame():Void
  {
    dirty = true;

    onPreRender.dispatch();

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

    onPostRender.dispatch();
  }

  /**
   * Destroys the buffer renderer.
   */
  public function destroy():Void
  {
    texture.dispose();
  }
}
