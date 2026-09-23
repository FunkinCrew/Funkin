package funkin.graphics.framebuffer;

import flixel.util.FlxColor;
import funkin.graphics.FunkinCamera;
import funkin.graphics.shaders.BlurShaderDown;
import funkin.graphics.shaders.BlurShaderShadow;
import funkin.graphics.shaders.BlurShaderUp;
import funkin.graphics.shaders.BlurShaderUpShadow;
import openfl.filters.ShaderFilter;
import animate.FlxAnimateFrames.FlxAnimateSpritemapCollection;
import flixel.FlxSprite;

/**
 * A `FunkinBufferSprite` that can render a drop shadow under every sprite for a chosen camera.
 */
class DropShadowLayer extends FunkinBufferSprite
{
  /**
   * If `true`, the buffer will only render sprites that are part of a whitelist.
  **/
  public var useWhitelist(default, set):Bool;

  /**
   * The `FunkinCamera` associated with this drop shadow instance.
  **/
  public var funkinCamera:FunkinCamera;

  var _filters:Array<openfl.filters.BitmapFilter> = [];
  var _whiteList:Array<String> = [];
  var _blackList:Array<String> = [];

  public function new(camera:FunkinCamera, _color:FlxColor = 0xFFFFFFFF, sampleSteps:Int = 2, blurAmt:Float = 4, distX:Float = 0, distY:Float = 0)
  {
    super(0, 0, camera, {
      baseZoom: -1,
      bufferDelay: 0.0010,
      useScreenspace: false,
      resolutionScale: 0.35
    });

    this.cameras = [camera];
    this.funkinCamera = camera;

    // Do not let the shadow texture render itself into the source buffer.
    blacklistSprite(this);

    // Keep the layer aligned to the camera in world space.
    this.x = camera.scroll.x;
    this.y = camera.scroll.y;

    // Down samples
    for (i in 0...sampleSteps)
    {
      _filters.push(new ShaderFilter(new BlurShaderDown(1 / (i + 1), blurAmt)));
    }

    // Up samples
    if (sampleSteps <= 0)
    {
      _filters.push(new ShaderFilter(new BlurShaderShadow(_color, distX, distY)));
    }
    else
    {
      for (i in 0...sampleSteps - 1)
      {
        _filters.push(new ShaderFilter(new BlurShaderUp(sampleSteps - i, blurAmt)));
      }

      // Final upsample + color offset!
      // Mix them into one shader to reduce the RTT passes needed to apply the filter.
      _filters.push(new ShaderFilter(new BlurShaderUpShadow(1, blurAmt, _color, distX, distY)));
    }

    this.filters = _filters;
  }

  /**
   * Whether the device can render to multiple color attachments.
   * If `false`, the layer renders nothing.
  **/
  public static function isSupported():Bool
  {
    var context = flixel.FlxG.stage.window.context;
    if (context.type != lime.graphics.RenderContextType.OPENGLES) return true;
    @:privateAccess
    if (openfl.display.OpenGLRenderer.__drawBuffersEXT) return true;
    return Std.parseFloat(context.version) >= 3;
  }

  override function draw():Void
  {
    if (!visible) return;
    if (useWhitelist && _whiteList.isEmpty()) return;

    x = funkinCamera.scroll.x;
    y = funkinCamera.scroll.y;

    super.draw();
  }

  override function destroy():Void
  {
    super.destroy();
  }

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

    syncCameraFilters();
  }

  public function whitelistSprite(sprite:Null<FlxSprite>):Void
  {
    if (sprite == null || sprite.graphic == null)
    {
      trace('WARNING: Tried to whitelist an invalid sprite.');
      return;
    }

    var graphicKeys:Array<String> = [sprite.graphic.key];

    // Texture atlases use a spritemap collection
    // We'll need to add all the spritemaps to the whitelist
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

    syncCameraFilters();
  }

  function syncCameraFilters():Void
  {
    funkinCamera.blackListKeys = _blackList.copy();
    funkinCamera.whiteListKeys = _whiteList.copy();
  }

  function set_useWhitelist(v:Bool):Bool
  {
    funkinCamera.useWhitelist = v;
    return useWhitelist = v;
  }
}
