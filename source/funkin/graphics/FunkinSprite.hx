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
import flixel.graphics.frames.FlxFrame;
import flixel.FlxCamera;
import openfl.system.System;
import flixel.system.FlxAssets.FlxGraphicAsset;
import funkin.FunkinMemory;
import animate.internal.SymbolItem;
import animate.internal.elements.Element;
import animate.internal.elements.AtlasInstance;
import animate.FlxAnimate;
import animate.FlxAnimateFrames;

using StringTools;

typedef AtlasSpriteSettings =
{
  /**
   * If true, the texture atlas will behave as if it was exported as an SWF file.
   * Notably, this allows MovieClip symbols to play.
   */
  @:optional
  var swfMode:Bool;

  /**
   * If true, filters and masks will be cached when the atlas is loaded, instead of during runtime.
   */
  @:optional
  var cacheOnLoad:Bool;

  /**
   * The filter quality.
   * Available values are: HIGH, MEDIUM, LOW, and RUDY.
   *
   * If you're making an atlas sprite in HScript, you pass an Int instead:
   *
   * HIGH - 0
   * MEDIUM - 1
   * LOW - 2
   * RUDY - 3
   */
  @:optional
  var filterQuality:FilterQuality;

  /**
   * Optional, an array of spritemaps for the atlas to load.
   */
  @:optional
  var spritemaps:Array<SpritemapInput>;

  /**
   * Optional, string of the metadata.json contents.
   */
  @:optional
  var metadataJson:String;

  /**
   * Optional, force the cache to use a specific key to index the texture atlas.
   */
  @:optional
  var cacheKey:String;

  /**
   * If true, the texture atlas will use a new slot in the cache.
   */
  @:optional
  var uniqueInCache:Bool;

  /**
   * Optional callback for when a symbol is created.
   */
  @:optional
  var onSymbolCreate:animate.internal.SymbolItem->Void;

  /**
   * Whether to apply the stage matrix, if it was exported from a symbol instance.
   */
  @:optional
  var applyStageMatrix:Bool;

  /**
   * Whether to use legacy bounds positioning.
   */
  @:optional
  var legacyBoundsPosition:Bool;
}

/**
 * An FlxSprite with additional functionality.
 * - A more efficient method for creating solid color sprites.
 * - TODO: Better cache handling for textures.
 */
@:nullSafety
class FunkinSprite extends FlxAnimate
{
  /**
   * NOTE: This will only work on texture atlases.
   *
   * If enabled, the sprite will be offset using the bounds origin.
   * This imitates the behavior of the legacy bounds FlxAnimate had.
   * Turning this on is not recommended, only use this if you know what you're doing.
   * It's also worth noting that not all atlases will react correctly, some may need position tweaks.
   */
  public var legacyBoundsPosition:Bool = false;

  /**
   * @param x Starting X position
   * @param y Starting Y position
   */
  public function new(?x:Float = 0, ?y:Float = 0)
  {
    super(x, y);
  }

  override function initVars():Void
  {
    super.initVars();

    var newController:FunkinAnimationController = new FunkinAnimationController(this);

    animation = newController;
    anim = newController;
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
   * Create a new FunkinSprite with an Adobe Animate texture atlas.
   * @param x The starting X position.
   * @param y The starting Y position.
   * @param key The key of the texture to load.
   * @return The new FunkinSprite.
   */
  public static function createTextureAtlas(x:Float = 0.0, y:Float = 0.0, key:String, ?assetLibrary:Null<String>, ?settings:AtlasSpriteSettings):FunkinSprite
  {
    var sprite:FunkinSprite = new FunkinSprite(x, y);
    sprite.loadTextureAtlas(key, assetLibrary ?? "", settings);
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
    if (!FunkinMemory.isTextureCached(graphicKey)) FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');

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
   * Loads an Adobe Animate texture atlas as the sprite's texture.
   * @param key The key of the texture to load.
   * @param settings Additional settings for loading the atlas.
   * @return This sprite, for chaining.
   */
  public function loadTextureAtlas(key:Null<String>, ?assetLibrary:Null<String>, ?settings:AtlasSpriteSettings):FunkinSprite
  {
    if (key == null)
    {
      throw 'Null path specified for loadTextureAtlas()!';
    }

    var validatedSettings:AtlasSpriteSettings =
      {
        swfMode: settings?.swfMode ?? false,
        cacheOnLoad: settings?.cacheOnLoad ?? false,
        filterQuality: settings?.filterQuality ?? MEDIUM,
        spritemaps: settings?.spritemaps ?? null,
        metadataJson: settings?.metadataJson ?? null,
        cacheKey: settings?.cacheKey ?? null,
        uniqueInCache: settings?.uniqueInCache ?? false,
        onSymbolCreate: settings?.onSymbolCreate ?? null,
        legacyBoundsPosition: settings?.legacyBoundsPosition ?? false,
        applyStageMatrix: (settings?.applyStageMatrix ?? false || settings?.legacyBoundsPosition ?? false)
      };

    var assetLibrary:String = assetLibrary ?? "";
    var graphicKey:String = "";

    if (assetLibrary != "")
    {
      graphicKey = Paths.animateAtlas(key, assetLibrary);
    }
    else
    {
      graphicKey = Paths.animateAtlas(key);
    }

    // Validate asset path.
    if (!Assets.exists('${graphicKey}/Animation.json'))
    {
      throw 'No Animation.json file exists at the specified path (${graphicKey})';
    }

    this.applyStageMatrix = validatedSettings.applyStageMatrix ?? false;
    this.legacyBoundsPosition = validatedSettings.legacyBoundsPosition ?? false;

    frames = FlxAnimateFrames.fromAnimate(graphicKey, validatedSettings.spritemaps, validatedSettings.metadataJson, validatedSettings.cacheKey,
      validatedSettings.uniqueInCache, {
        swfMode: validatedSettings.swfMode,
        cacheOnLoad: validatedSettings.cacheOnLoad,
        filterQuality: validatedSettings.filterQuality,
        onSymbolCreate: validatedSettings.onSymbolCreate
      });

    return this;
  }

  /**
   * Load an animated texture (Sparrow atlas spritesheet) as the sprite's texture.
   * @param key The key of the texture to load.
   * @return This sprite, for chaining.
   */
  public function loadSparrow(key:String):FunkinSprite
  {
    var graphicKey:String = Paths.image(key);
    if (!FunkinMemory.isTextureCached(graphicKey)) FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');

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
    if (!FunkinMemory.isTextureCached(graphicKey)) FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');

    this.frames = Paths.getPackerAtlas(key);

    return this;
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
   * Whether or not this sprite has an animation with the given ID.
   * @param id The ID of the animation to check.
   */
  public function hasAnimation(id:String):Bool
  {
    var animationList:Array<String> = this.animation.getNameList();
    if (animationList.contains(id))
    {
      return true;
    }
    else if (this.isAnimate && !animationList.contains(id))
    {
      return addAnimationIfMissing(id);
    }

    return false;
  }

  /**
   * Adds an animation if it doesn't exist.
   * @param id The animation ID to check.
   */
  function addAnimationIfMissing(id:String, ?prefix:String, ?frameRate:Float, ?looped:Bool = false, ?flipX:Bool = false, ?flipY:Bool = false):Bool
  {
    @:privateAccess
    var symbols:Array<String> = this.library.dictionary.keys().array();
    var frameLabels:Array<String> = listAnimations();
    var animationPrefix:String = prefix ?? id;

    if (frameLabels.contains(animationPrefix))
    {
      // Animation exists as a frame label but wasn't added, so we add it
      anim.addByFrameLabel(id, animationPrefix, frameRate ?? this.library.frameRate, looped, flipX, flipY);
      return true;
    }
    else if (symbols.contains(animationPrefix))
    {
      // Animation exists as a symbol but wasn't added, so we add it
      anim.addBySymbol(id, animationPrefix, frameRate ?? this.library.frameRate, looped, flipX, flipY);
      return true;
    }

    return false;
  }

  /**
   * Gets the current animation ID.
   */
  public function getCurrentAnimation():String
  {
    return this.animation.curAnim?.name ?? '';
  }

  /**
   * Whether or not the current animation is finished.
   */
  public function isAnimationFinished():Bool
  {
    return this.animation?.finished ?? false;
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
   * @return A list of all the animations this sprite has available.
   */
  public function listAnimations():Array<String>
  {
    var frameLabels:Array<String> = getFrameLabelList();
    var animationList:Array<String> = this.animation.getNameList();

    return frameLabels.concat(animationList);
  }

  /**
   * TEXTURE ATLAS-EXCLUSIVE FUNCTIONS
   * These functions only work if the sprite's texture is an Adobe Animate texture atlas.
   * Calling these functions on non-texture atlases will do nothing.
   */
  /**
   * Gets a list of frame labels from the default timeline.
   */
  public function getFrameLabelList():Array<String>
  {
    if (!this.isAnimate) return [];

    var foundLabels:Array<String> = [];
    var mainTimeline = this.anim.getDefaultTimeline();

    for (layer in mainTimeline.layers)
    {
      @:nullSafety(Off)
      for (frame in layer.frames)
      {
        if (frame.name.rtrim() != '')
        {
          foundLabels.push(frame.name);
        }
      }
    }

    return foundLabels;
  }

  /**
   * Gets a frame label by its name.
   * @param name The name of the frame label to retrieve.
   * @return The frame label, or null if it doesn't exist.
   */
  public function getFrameLabel(name:String):Null<animate.internal.Frame>
  {
    if (!this.isAnimate) return null;

    var mainTimeline = this.anim.getDefaultTimeline();
    for (layer in mainTimeline.layers)
    {
      @:nullSafety(Off)
      for (frame in layer.frames)
      {
        if (frame.name == name)
        {
          return frame;
        }
      }
    }
    return null;
  }

  /**
   * Returns the default symbol in the atlas.
   */
  public function getDefaultSymbol():String
  {
    if (!this.isAnimate) return '';
    return library.timeline.name;
  }

  /**
   * Replaces the graphic of a symbol in the atlas.
   * @param symbol The symbol to replace.
   * @param graphic The new graphic to use.
   */
  public function replaceSymbolGraphic(symbol:String, graphic:FlxGraphicAsset):Void
  {
    if (!this.isAnimate) return;

    if (graphic == null)
    {
      throw 'Null graphic passed to replaceSymbolGraphic()!';
      return;
    }

    var symbolInstance:Null<SymbolItem> = this.library.getSymbol(symbol);

    if (symbolInstance == null)
    {
      throw 'Symbol not found in atlas: ${symbol}';
      return;
    }

    var elements:Array<Element> = symbolInstance.timeline.getElementsAtIndex(0);

    for (element in elements)
    {
      var atlasInstance:AtlasInstance = element.toAtlasInstance();
      var frame:FlxFrame = FlxG.bitmap.add(graphic).imageFrame.frame;
      atlasInstance.replaceFrame(frame);

      element = atlasInstance;
    }
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

    if (this.isAnimate)
    {
      if (this.applyStageMatrix || legacyBoundsPosition)
      {
        result.add(this.library.matrix.tx, this.library.matrix.ty);
      }

      if (legacyBoundsPosition)
      {
        var point = this.timeline.getBoundsOrigin(FlxPoint.get(), true);
        result.add(point.x, point.y);
        point.put();
      }
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
