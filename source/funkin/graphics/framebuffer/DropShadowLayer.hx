package funkin.graphics.framebuffer;

import flixel.FlxCamera;
import flixel.graphics.frames.FlxFrame;
import flixel.util.FlxColor;
import funkin.graphics.FunkinCamera;
import funkin.graphics.shaders.BlurShaderDown;
import funkin.graphics.shaders.BlurShaderShadow;
import funkin.graphics.shaders.BlurShaderUp;
import funkin.graphics.shaders.BlurShaderUpShadow;
import openfl.filters.ShaderFilter;
import animate.FlxAnimateFrames.FlxAnimateSpritemapCollection;
import flixel.FlxSprite;

using flixel.util.FlxColorTransformUtil;

/**
 * A `FunkinBufferSprite` that can render a drop shadow under every sprite for a chosen camera.
 */
@:access(openfl.display.BitmapData)
@:access(openfl.display.DisplayObject)
@:access(flixel.FlxCamera)
class DropShadowLayer extends FlxSprite
{
  /**
   * If `true`, the buffer will only render sprites that are part of a whitelist.
  **/
  public var useWhitelist(default, set):Bool;

  /**
   * The `FunkinCamera` associated with this drop shadow instance.
  **/
  public var funkinCamera:FunkinCamera;

  /**
   * The resolution scale of the buffer.
   * Setting it lower than 1.0 will make the buffer render at a lower resolution.
   * Default is 0.35.
  **/
  public var resolutionScale(default, set):Float = 0.35;

  /**
   * The delay before the buffer is rendered.
   * If set to `0`, the buffer will be rendered immediately.
   *
   * Could be useful for performance.
  **/
  public var bufferDelay(default, set):Float = 0.0010;

  var _filters:Array<openfl.filters.BitmapFilter> = [];
  var _bufferID:Int = -1;

  public function new(camera:FunkinCamera, _color:FlxColor = 0xFFFFFFFF, sampleSteps:Int = 2, blurAmt:Float = 4, distX:Float = 0, distY:Float = 0)
  {
    super();

    this.cameras = [camera];
    this.funkinCamera = camera;

    camera.defaultShader = new funkin.graphics.shaders.MultiBufferShader();
    // Wanted to use just a RED color format because in the end it just becomes grayish
    // But that ended up making a fully gray rect in the end
    _bufferID = camera.canvas.graphics.addBuffer(openfl.display3D.Context3DTextureFormat.BGRA);
    camera.canvas.cacheAsBitmap = true;

    // Down samples
    for (i in 0...sampleSteps)
    {
      var downFilter:ShaderFilter = new ShaderFilter(new BlurShaderDown(1 / (i + 1), blurAmt));
      _filters.push(downFilter);
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
        var upFilter:ShaderFilter = new ShaderFilter(new BlurShaderUp(sampleSteps - i, blurAmt));
        _filters.push(upFilter);
      }

      // Final upsample + color offset!
      // Mix them into one shader to reduce the RTT passes needed to apply the filter
      _filters.push(new ShaderFilter(new BlurShaderUpShadow(1, blurAmt, _color, distX, distY)));
    }

    camera.canvas.graphics.setBufferFilters(_bufferID, _filters, resolutionScale, bufferDelay);

    updateColorTransform();
  }

  override function draw():Void
  {
    if (!visible) return;
    if (useWhitelist && _whiteList.isEmpty()) return;
    if (funkinCamera.canvas.graphics.getBuffer(_bufferID) == null) return;

    render();

    super.draw();
  }

  function render():Void
  {
    // otherwise openfl will mess up somehow and keep scaling up the frame buffer until it eats all your VRAM
    if (camera.canvas.scrollRect == null)
    {
      camera.canvas.scrollRect = new openfl.geom.Rectangle(0, 0, camera.width, camera.height);
    }
    else
    {
      camera.canvas.scrollRect.width = camera.width;
      camera.canvas.scrollRect.height = camera.height;
    }

    var bufferBitmap = funkinCamera.canvas.graphics.getBuffer(_bufferID);

    if (bufferBitmap != null)
    {
      x = camera.scroll.x;
      y = camera.scroll.y;
      scale.x = 1 / (camera.totalScaleX * resolutionScale);
      scale.y = 1 / (camera.totalScaleY * resolutionScale);
    }

    if (bufferBitmap != null && (graphic == null || (graphic != null && graphic.bitmap != bufferBitmap)))
    {
      pixels = bufferBitmap;
      blacklistSprite(this);
      updateHitbox();
    }
  }

  override function destroy():Void
  {
    if (funkinCamera.canvas != null)
    {
      funkinCamera.canvas.cacheAsBitmap = false;
      camera.canvas.scrollRect = null;
    }

    super.destroy();
  }

  var _whiteList:Array<String> = [];
  var _blackList:Array<String> = [];

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

    funkinCamera.blackListKeys = _blackList.copy();
    funkinCamera.whiteListKeys = _whiteList.copy();
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

    funkinCamera.blackListKeys = _blackList.copy();
    funkinCamera.whiteListKeys = _whiteList.copy();
  }

  @:haxe.warning("-WDeprecated")
  override function updateColorTransform():Void
  {
    colorTransform.setMultipliers(color.redFloat, color.greenFloat, color.blueFloat, alpha / 2);
    useColorTransform = hasColorTransformRaw();

    dirty = true;
  }

  function set_useWhitelist(v:Bool):Bool
  {
    funkinCamera.useWhitelist = v;
    return useWhitelist = v;
  }

  function set_resolutionScale(v:Float):Float
  {
    camera.canvas.graphics.setBufferFilters(_bufferID, _filters, v, bufferDelay);
    return resolutionScale = v;
  }

  function set_bufferDelay(v:Float):Float
  {
    camera.canvas.graphics.setBufferFilters(_bufferID, _filters, resolutionScale, v);
    return bufferDelay = v;
  }

  override function drawFrameComplex(frame:FlxFrame, camera:FlxCamera):Void
  {
    if (filters == null || filters.length == 0) return;

    super.drawFrameComplex(frame, camera);
  }
}
