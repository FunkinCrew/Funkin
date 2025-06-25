package funkin.graphics;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;
import openfl.display3D.textures.TextureBase;
import funkin.graphics.framebuffer.FixedBitmapData;
import openfl.display.BitmapData;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.FlxCamera;
import openfl.system.System;

using StringTools;

/**
 * An FlxSprite with additional functionality.
 * - A more efficient method for creating solid color sprites.
 * - TODO: Better cache handling for textures.
 */
@:nullSafety
class FunkinSprite extends FlxSprite
{
  /**
   * An internal list of all the textures cached with `cacheTexture`.
   * This excludes any temporary textures like those from `FlxText` or `makeSolidColor`.
   */
  static var currentCachedTextures:Map<String, FlxGraphic> = [];

  /**
   * An internal list of textures that were cached in the previous state.
   * We don't know whether we want to keep them cached or not.
   */
  static var previousCachedTextures:Map<String, FlxGraphic> = [];

  static var permanentCachedTextures:Map<String, FlxGraphic> = [];

  /**
   * @param x Starting X position
   * @param y Starting Y position
   */
  public function new(?x:Float = 0, ?y:Float = 0)
  {
    super(x, y);
  }

  /**
   * Create a new FunkinSprite with a static texture.
   * @param x The starting X position.
   * @param y The starting Y position.
   * @param key The key of the texture to load.
   * @return The new FunkinSprite.
   */
  public static function create(x:Float = 0.0, y:Float = 0.0, key:String):FunkinSprite
  {
    var sprite:FunkinSprite = new FunkinSprite(x, y);
    sprite.loadTexture(key);
    return sprite;
  }

  /**
   * Create a new FunkinSprite with a Sparrow atlas animated texture.
   * @param x The starting X position.
   * @param y The starting Y position.
   * @param key The key of the texture to load.
   * @return The new FunkinSprite.
   */
  public static function createSparrow(x:Float = 0.0, y:Float = 0.0, key:String):FunkinSprite
  {
    var sprite:FunkinSprite = new FunkinSprite(x, y);
    sprite.loadSparrow(key);
    return sprite;
  }

  /**
   * Create a new FunkinSprite with a Packer atlas animated texture.
   * @param x The starting X position.
   * @param y The starting Y position.
   * @param key The key of the texture to load.
   * @return The new FunkinSprite.
   */
  public static function createPacker(x:Float = 0.0, y:Float = 0.0, key:String):FunkinSprite
  {
    var sprite:FunkinSprite = new FunkinSprite(x, y);
    sprite.loadPacker(key);
    return sprite;
  }

  /**
   * Load a static image as the sprite's texture.
   * @param key The key of the texture to load.
   * @return This sprite, for chaining.
   */
  public function loadTexture(key:String):FunkinSprite
  {
    var graphicKey:String = Paths.image(key);
    if (!isTextureCached(graphicKey)) FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');

    loadGraphic(graphicKey);

    return this;
  }

  public function loadTextureAsync(key:String, fade:Bool = false):Void
  {
    var fadeTween:Null<FlxTween> = null;
    if (fade)
    {
      fadeTween = FlxTween.tween(this, {alpha: 0}, 0.25);
    }

    trace('[ASYNC] Start loading image (${key})');
    graphic.persist = true;
    openfl.Assets.loadBitmapData(key)
      .onComplete(function(bitmapData:openfl.display.BitmapData) {
        trace('[ASYNC] Finished loading image');
        var cache:Bool = false;
        loadBitmapData(bitmapData, cache);

        if (fadeTween != null)
        {
          fadeTween.cancel();
          FlxTween.tween(this, {alpha: 1.0}, 0.25);
        }
      })
      .onError(function(error:Dynamic) {
        trace('[ASYNC] Failed to load image: ${error}');
        if (fadeTween != null)
        {
          fadeTween.cancel();
          this.alpha = 1.0;
        }
      })
      .onProgress(function(progress:Int, total:Int) {
        trace('[ASYNC] Loading image progress: ${progress}/${total}');
      });
  }

  /**
   * Apply an OpenFL `BitmapData` to this sprite.
   * @param input The OpenFL `BitmapData` to apply
   * @return This sprite, for chaining
   */
  public function loadBitmapData(input:BitmapData, cache:Bool = true):FunkinSprite
  {
    if (cache)
    {
      loadGraphic(input);
    }
    else
    {
      var graphic:FlxGraphic = FlxGraphic.fromBitmapData(input, false, null, false);
      this.graphic = graphic;
      this.frames = this.graphic.imageFrame;
    }

    return this;
  }

  /**
   * Apply an OpenFL `TextureBase` to this sprite.
   * @param input The OpenFL `TextureBase` to apply
   * @return This sprite, for chaining
   */
  public function loadTextureBase(input:TextureBase):Null<FunkinSprite>
  {
    var inputBitmap:Null<FixedBitmapData> = FixedBitmapData.fromTexture(input);
    if (inputBitmap == null)
    {
      FlxG.log.warn('loadTextureBase - input resulted in null bitmap! $input');
      return null;
    }

    return loadBitmapData(inputBitmap);
  }

  /**
   * Load an animated texture (Sparrow atlas spritesheet) as the sprite's texture.
   * @param key The key of the texture to load.
   * @return This sprite, for chaining.
   */
  public function loadSparrow(key:String):FunkinSprite
  {
    var graphicKey:String = Paths.image(key);
    if (!isTextureCached(graphicKey)) FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');

    this.frames = Paths.getSparrowAtlas(key);

    return this;
  }

  /**
   * Load an animated texture (Packer atlas spritesheet) as the sprite's texture.
   * @param key The key of the texture to load.
   * @return This sprite, for chaining.
   */
  public function loadPacker(key:String):FunkinSprite
  {
    var graphicKey:String = Paths.image(key);
    if (!isTextureCached(graphicKey)) FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');

    this.frames = Paths.getPackerAtlas(key);

    return this;
  }

  /**
   * Determine whether the texture with the given key is cached.
   * @param key The key of the texture to check.
   * @return Whether the texture is cached.
   */
  public static function isTextureCached(key:String):Bool
  {
    return FlxG.bitmap.get(key) != null;
  }

  /**
   * Ensure the texture with the given key is cached.
   * @param key The key of the texture to cache.
   */
  public static function cacheTexture(key:String):Void
  {
    // We don't want to cache the same texture twice.
    if (currentCachedTextures.exists(key)) return;

    if (previousCachedTextures.exists(key))
    {
      // Move the graphic from the previous cache to the current cache.
      var graphic = previousCachedTextures.get(key);
      previousCachedTextures.remove(key);
      if (graphic != null) currentCachedTextures.set(key, graphic);
      return;
    }

    // Else, texture is currently uncached.
    var graphic:FlxGraphic = FlxGraphic.fromAssetKey(key, false, null, true);
    if (graphic == null)
    {
      FlxG.log.warn('Failed to cache graphic: $key');
    }
    else
    {
      trace('Successfully cached graphic: $key');
      graphic.persist = true;
      currentCachedTextures.set(key, graphic);
    }
  }

  public static function permanentCacheTexture(key:String):Void
  {
    // We don't want to cache the same texture twice.
    if (permanentCachedTextures.exists(key)) return;

    // Else, texture is currently uncached.
    var graphic:FlxGraphic = FlxGraphic.fromAssetKey(key, false, null, true);
    if (graphic == null)
    {
      FlxG.log.warn('Failed to cache graphic: $key');
    }
    else
    {
      trace('Successfully cached graphic: $key');
      graphic.persist = true;
      permanentCachedTextures.set(key, graphic);
    }

    currentCachedTextures = permanentCachedTextures;
  }

  public static function cacheSparrow(key:String):Void
  {
    cacheTexture(Paths.image(key));
  }

  public static function cachePacker(key:String):Void
  {
    cacheTexture(Paths.image(key));
  }

  /**
   * Call this, then `cacheTexture` to keep the textures we still need, then `purgeCache` to remove the textures that we won't be using anymore.
   */
  public static function preparePurgeCache():Void
  {
    previousCachedTextures = currentCachedTextures;

    for (graphicKey in previousCachedTextures.keys())
    {
      if (!permanentCachedTextures.exists(graphicKey)) continue;
      previousCachedTextures.remove(graphicKey);
    }

    currentCachedTextures = permanentCachedTextures;
  }

  public static function purgeCache():Void
  {
    // Everything that is in previousCachedTextures but not in currentCachedTextures should be destroyed.
    for (graphicKey in previousCachedTextures.keys())
    {
      var graphic = previousCachedTextures.get(graphicKey);
      if (graphic == null) continue;
      FlxG.bitmap.remove(graphic);
      graphic.destroy();
      previousCachedTextures.remove(graphicKey);
    }
    @:privateAccess
    if (FlxG.bitmap._cache == null)
    {
      @:privateAccess
      FlxG.bitmap._cache = new Map();
      System.gc();
      return;
    }

    @:privateAccess
    for (key in FlxG.bitmap._cache.keys())
    {
      var obj:Null<FlxGraphic> = FlxG.bitmap.get(key);
      if (obj == null) continue;
      if (obj.persist) continue;
      if (permanentCachedTextures.exists(key)) continue;
      if (!(obj.useCount <= 0 || key.contains("characters") || key.contains("charSelect") || key.contains("results"))) continue;

      FlxG.bitmap.removeKey(key);
      obj.destroy();
    }
    openfl.Assets.cache.clear("songs");
    openfl.Assets.cache.clear("sounds");
    openfl.Assets.cache.clear("music");

    System.gc();
  }

  static function isGraphicCached(graphic:FlxGraphic):Bool
  {
    var result = null;
    if (graphic == null) return false;
    result = FlxG.bitmap.get(graphic.key);
    if (result == null) return false;
    if (result != graphic)
    {
      FlxG.log.warn('Cached graphic does not match original: ${graphic.key}');
      return false;
    }
    return true;
  }

  /**
   * @param id The animation ID to check.
   * @return Whether the animation is dynamic (has multiple frames). `false` for static, one-frame animations.
   */
  public function isAnimationDynamic(id:String):Bool
  {
    var animData = null;
    if (this.animation == null) return false;
    animData = this.animation.getByName(id);
    if (animData == null) return false;
    return animData.numFrames > 1;
  }

  /**
   * Acts similarly to `makeGraphic`, but with improved memory usage,
   * at the expense of not being able to paint onto the resulting sprite.
   *
   * @param width The target width of the sprite.
   * @param height The target height of the sprite.
   * @param color The color to fill the sprite with.
   * @return This sprite, for chaining.
   */
  public function makeSolidColor(width:Int, height:Int, color:FlxColor = FlxColor.WHITE):FunkinSprite
  {
    // Create a tiny solid color graphic and scale it up to the desired size.
    var graphic:FlxGraphic = FlxG.bitmap.create(2, 2, color, false, 'solid#${color.toHexString(true, false)}');
    frames = graphic.imageFrame;
    scale.set(width / 2.0, height / 2.0);
    updateHitbox();

    return this;
  }

  /**
   * Ensure scale is applied when cloning a sprite.R
   * The default `clone()` method acts kinda weird TBH.
   * @return A clone of this sprite.
   */
  public override function clone():FunkinSprite
  {
    var result = new FunkinSprite(this.x, this.y);
    result.frames = this.frames;
    result.scale.set(this.scale.x, this.scale.y);
    result.updateHitbox();

    return result;
  }

  @:access(flixel.FlxCamera)
  override function getBoundingBox(camera:FlxCamera):FlxRect
  {
    getScreenPosition(_point, camera);

    _rect.set(_point.x, _point.y, width, height);
    _rect = camera.transformRect(_rect);

    if (isPixelPerfectRender(camera))
    {
      _rect.width = _rect.width / this.scale.x;
      _rect.height = _rect.height / this.scale.y;
      _rect.x = _rect.x / this.scale.x;
      _rect.y = _rect.y / this.scale.y;
      _rect.floor();
      _rect.x = _rect.x * this.scale.x;
      _rect.y = _rect.y * this.scale.y;
      _rect.width = _rect.width * this.scale.x;
      _rect.height = _rect.height * this.scale.y;
    }

    return _rect;
  }

  /**
   * Returns the screen position of this object.
   *
   * @param   result  Optional arg for the returning point
   * @param   camera  The desired "screen" coordinate space. If `null`, `FlxG.camera` is used.
   * @return  The screen position of this object.
   */
  public override function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint
  {
    if (result == null) result = FlxPoint.get();

    if (camera == null) camera = FlxG.camera;

    result.set(x, y);
    if (pixelPerfectPosition)
    {
      _rect.width = _rect.width / this.scale.x;
      _rect.height = _rect.height / this.scale.y;
      _rect.x = _rect.x / this.scale.x;
      _rect.y = _rect.y / this.scale.y;
      _rect.round();
      _rect.x = _rect.x * this.scale.x;
      _rect.y = _rect.y * this.scale.y;
      _rect.width = _rect.width * this.scale.x;
      _rect.height = _rect.height * this.scale.y;
    }

    return result.subtract(camera.scroll.x * scrollFactor.x, camera.scroll.y * scrollFactor.y);
  }

  override function drawSimple(camera:FlxCamera):Void
  {
    getScreenPosition(_point, camera).subtractPoint(offset);
    if (isPixelPerfectRender(camera))
    {
      _point.x = _point.x / this.scale.x;
      _point.y = _point.y / this.scale.y;
      _point.round();

      _point.x = _point.x * this.scale.x;
      _point.y = _point.y * this.scale.y;
    }

    _point.copyToFlash(_flashPoint);
    camera.copyPixels(_frame, framePixels, _flashRect, _flashPoint, colorTransform, blend, antialiasing);
  }

  override function drawComplex(camera:FlxCamera):Void
  {
    _frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
    _matrix.translate(-origin.x, -origin.y);
    _matrix.scale(scale.x, scale.y);

    if (bakedRotationAngle <= 0)
    {
      updateTrig();

      if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
    }

    getScreenPosition(_point, camera).subtractPoint(offset);
    _point.add(origin.x, origin.y);
    _matrix.translate(_point.x, _point.y);

    if (isPixelPerfectRender(camera))
    {
      _matrix.tx = Math.round(_matrix.tx / this.scale.x) * this.scale.x;
      _matrix.ty = Math.round(_matrix.ty / this.scale.y) * this.scale.y;
    }

    camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
  }

  public override function destroy():Void
  {
    @:nullSafety(Off) // TODO: Remove when flixel.FlxSprite is null safed.
    frames = null;
    // Cancel all tweens so they don't continue to run on a destroyed sprite.
    // This prevents crashes.
    FlxTween.cancelTweensOf(this);
    super.destroy();
  }
}
