package funkin.graphics;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;
import openfl.display3D.textures.TextureBase;
import funkin.graphics.framebuffer.FixedBitmapData;
import openfl.display.BitmapData;
import openfl.Assets;
import funkin.util.MemoryUtil;

/**
 * An FlxSprite with additional functionality.
 * - A more efficient method for creating solid color sprites.
 * - TODO: Better cache handling for textures.
 */
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

  /**
   * Apply an OpenFL `BitmapData` to this sprite.
   * @param input The OpenFL `BitmapData` to apply
   * @return This sprite, for chaining
   */
  public function loadBitmapData(input:BitmapData):FunkinSprite
  {
    loadGraphic(input);

    return this;
  }

  /**
   * Apply an OpenFL `TextureBase` to this sprite.
   * @param input The OpenFL `TextureBase` to apply
   * @return This sprite, for chaining
   */
  public function loadTextureBase(input:TextureBase):FunkinSprite
  {
    var inputBitmap:FixedBitmapData = FixedBitmapData.fromTexture(input);

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
      currentCachedTextures.set(key, graphic);
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
    currentCachedTextures = [];
  }

  public static function purgeCache():Void
  {
    // Everything that is in previousCachedTextures but not in currentCachedTextures should be destroyed.
    for (graphicKey in previousCachedTextures.keys())
    {
      var graphic = previousCachedTextures.get(graphicKey);
      if (graphic == null) continue;
      FlxG.bitmap.remove(graphic);
      Assets.cache.removeBitmapData(graphicKey);
      graphic.persist = false; // so the gc remembers to clear it
      graphic.destroyOnNoUse = true;
      graphic.destroy();
      previousCachedTextures.remove(graphicKey);
    }
    MemoryUtil.collect(true);
  }

  static function isGraphicCached(graphic:FlxGraphic):Bool
  {
    if (graphic == null) return false;
    var result = FlxG.bitmap.get(graphic.key);
    if (result == null) return false;
    if (result != graphic)
    {
      FlxG.log.warn('Cached graphic does not match original: ${graphic.key}');
      return false;
    }
    return true;
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

  public override function destroy():Void
  {
    frames = null;
    // Cancel all tweens so they don't continue to run on a destroyed sprite.
    // This prevents crashes.
    FlxTween.cancelTweensOf(this);
    super.destroy();
  }
}
