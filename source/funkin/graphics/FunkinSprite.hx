package funkin.graphics;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;

/**
 * An FlxSprite with additional functionality.
 * - A more efficient method for creating solid color sprites.
 * - TODO: Better cache handling for textures.
 */
class FunkinSprite extends FlxSprite
{
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
    var sprite = new FunkinSprite(x, y);
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
    var sprite = new FunkinSprite(x, y);
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
    var sprite = new FunkinSprite(x, y);
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
    if (!isTextureCached(key)) FlxG.log.warn('Texture not cached, may experience stuttering! $key');

    loadGraphic(key);

    return this;
  }

  /**
   * Load an animated texture (Sparrow atlas spritesheet) as the sprite's texture.
   * @param key The key of the texture to load.
   * @return This sprite, for chaining.
   */
  public function loadSparrow(key:String):FunkinSprite
  {
    var graphicKey = Paths.image(key);
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
    var graphicKey = Paths.image(key);
    if (!isTextureCached(graphicKey)) FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');

    this.frames = Paths.getPackerAtlas(key);

    return this;
  }

  public static function isTextureCached(key:String):Bool
  {
    return FlxG.bitmap.get(key) != null;
  }

  public static function cacheTexture(key:String):Void
  {
    var graphic = flixel.graphics.FlxGraphic.fromAssetKey(key, false, null, true);
    if (graphic == null)
    {
      FlxG.log.warn('Failed to cache graphic: $key');
    }
    else
    {
      trace('Successfully cached graphic: $key');
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
   * Ensure scale is applied when cloning a sprite.
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
}
