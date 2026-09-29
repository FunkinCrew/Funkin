package funkin.graphics.framebuffer;

import animate.FlxAnimateFrames.FlxAnimateSpritemapCollection;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxSignal;
import funkin.graphics.FunkinCamera;
import openfl.display.BitmapData;

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
  public var texture(get, never):BitmapData;

  var _texture:Null<BitmapData> = null;

  function get_texture():BitmapData
  {
    var current:Null<BitmapData> = _texture;
    if (current == null)
    {
      current = new BitmapData(_camera.width, _camera.height, true, 0).toGPU();
      _texture = current;
    }
    return current;
  }

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

  /**
   * Set to `true` every time the buffer texture is redrawn.
   */
  public var justRendered:Bool = false;

  var dirty:Bool = false;
  var initialized:Bool = false;
  var _timer:Float = 0;
  var _camera:FunkinCamera;
  var _whiteList:Map<String, Bool> = [];
  var _whiteListCount:Int = 0;
  var _blackList:Map<String, Bool> = [];

  public function new(camera:FunkinCamera)
  {
    this._camera = camera;
  }

  /**
   * Resizes the buffer to a new size.
   * @param width The new width.
   * @param height The new height.
   */
  public function resize(width:Int, height:Int):Void
  {
    var current:Null<BitmapData> = _texture;
    if (current != null)
    {
      current.dispose();
    }

    _texture = new BitmapData(width, height, true, 0).toGPU();
  }

  /**
   * Renders the buffer onto the texture.
   */
  public function render():Void
  {
    if (!active) return;
    if (useWhitelist && _whiteListCount == 0) return;

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

      if (_timer >= delay)
      {
        _timer -= delay;
        if (_timer > delay) _timer = delay;
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
    if (_blackList.exists(graphic.key))
    {
      return false;
    }

    if (useWhitelist && !_whiteList.exists(graphic.key))
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
      _blackList.remove(key);

      if (!_whiteList.exists(key))
      {
        _whiteList.set(key, true);
        _whiteListCount++;
      }
    }
  }

  /**
   * Adds a single graphic key to the blacklist, removing it from the whitelist if present.
   * @param key The graphic key to add.
   */
  public function blacklistKey(key:String):Void
  {
    if (_whiteList.remove(key))
    {
      _whiteListCount--;
    }

    _blackList.set(key, true);
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
      blacklistKey(key);
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
    justRendered = true;

    onPostRender.dispatch();
  }

  /**
   * Destroys the buffer renderer.
   */
  public function destroy():Void
  {
    var current:Null<BitmapData> = _texture;
    if (current != null) current.dispose();
    _texture = null;
  }
}
