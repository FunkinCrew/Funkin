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
import flixel.math.FlxMatrix;
import flixel.graphics.frames.FlxFrame;
import flixel.FlxCamera;
import openfl.system.System;
import flixel.system.FlxAssets.FlxGraphicAsset;
import funkin.FunkinMemory;
import animate.internal.SymbolItem;
import animate.internal.elements.Element;
import animate.internal.elements.AtlasInstance;
import animate.internal.elements.SymbolInstance;
import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import haxe.io.Path;

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
   * Also positions the Texture Atlas as it displays in Animate.
   * Turning this on is only recommended if you prepositioned the character in Animate.
   * For other cases, it should be turned off to act similarly to a normal FlxSprite.
   */
  @:optional
  var applyStageMatrix:Bool;
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
   * @param x Starting X position
   * @param y Starting Y position
   * @param path The asset path for the graphic
   * @param atlasSettings The optional settings for the texture atlas
   */
  public function new(?x:Float = 0, ?y:Float = 0, ?path:String, ?atlasSettings:AtlasSpriteSettings)
  {
    super(x, y);

    if (path != null)
    {
      var ext:String = Path.extension(path);

      switch (ext)
      {
        case 'png':
          this.loadGraphic(path);

        case '':
          // Do the opposite of Paths.animateAtlas since that function is called in loadTextureAtlas.
          var lib:String = Paths.getLibrary(path);

          if (lib == 'preload')
          {
            path = path.replace('assets/images/', '');
          }
          else
          {
            path = path.replace('$lib:assets/$lib/images/', '');
          }

          this.loadTextureAtlas(path, lib, atlasSettings);

        default:
          FlxG.log.warn('Texture path $path is not a valid path. Make sure the path points to either an image or a folder with the texture atlas files!');
      }
    }
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

    if (!Assets.exists(graphicKey, IMAGE))
    {
      FlxG.log.error('Texture not found, check your path! $graphicKey');
      return this;
    }

    if (!FunkinMemory.isTextureCached(graphicKey))
    {
      FlxG.log.warn('Texture not cached, may experience stuttering! $graphicKey');
    }

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
        applyStageMatrix: settings?.applyStageMatrix ?? false
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
    var animationList:Array<String> = this.animation?.getNameList() ?? [];
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
  function addAnimationIfMissing(id:String):Bool
  {
    @:privateAccess
    var symbols:Array<String> = this.library.dictionary.keys().array();
    var frameLabels:Array<String> = listAnimations();

    if (frameLabels.contains(id))
    {
      // Animation exists as a frame label but wasn't added, so we add it
      anim.addByFrameLabel(id, id, this.library.frameRate, false);
      return true;
    }
    else if (symbols.contains(id))
    {
      // Animation exists as a symbol but wasn't added, so we add it
      anim.addBySymbol(id, id, this.library.frameRate, false);
      return true;
    }

    return false;
  }

  /**
   * Gets the current animation ID.
   */
  public function getCurrentAnimation():String
  {
    return this.animation?.curAnim?.name ?? '';
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
    var animationList:Array<String> = this.animation?.getNameList() ?? [];

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
    if (!this.isAnimate)
    {
      trace('WARNING: getFrameLabelList() only works texture atlases!');
      return [];
    }

    var foundLabels:Array<String> = [];
    var mainTimeline:Null<animate.internal.Timeline> = this.library.timeline;

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
    if (!this.isAnimate)
    {
      trace('WARNING: getFrameLabel() only works texture atlases!');
      return null;
    }

    for (layer in this.timeline.layers)
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
    if (!this.isAnimate)
    {
      trace('WARNING: getDefaultSymbol() only works texture atlases!');
      return '';
    }

    return library.timeline.name;
  }

  /**
   * Replaces the graphic of a symbol in the atlas.
   * @param symbol The symbol to replace.
   * @param graphic The new graphic to use.
   * @param adjustScale Whether to adjust the scale of new frame to match the old one.
   */
  public function replaceSymbolGraphic(symbol:String, ?graphic:Null<FlxGraphicAsset>, ?adjustScale:Bool = true):Void
  {
    if (!this.isAnimate)
    {
      trace('WARNING: replaceSymbolGraphic() only works texture atlases!');
      return;
    }

    var elements:Array<Element> = getSymbolElements(symbol);

    for (element in elements)
    {
      var atlasInstance:AtlasInstance = element.toAtlasInstance();
      var frame:Null<FlxFrame> = graphic != null ? FlxG.bitmap.add(graphic).imageFrame.frame : null;

      atlasInstance.replaceFrame(frame, adjustScale);
      element = atlasInstance;
    }
  }

  /**
   * Returns the first element of a symbol in the atlas.
   * @param symbol The symbol to get elements from.
   * @return The first element of the symbol. WARNING: Can be null.
   */
  public function getFirstElement(symbol:String):Null<Element>
  {
    if (!this.isAnimate)
    {
      trace('WARNING: getFirstElement() only works texture atlases!');
      return null;
    }

    var symbolElements:Array<Element> = getSymbolElements(symbol);
    return symbolElements.length > 0 ? symbolElements[0] : null;
  }

  /**
   * Returns the elements of a symbol in the atlas.
   * @param symbol The symbol to get elements from.
   */
  public function getSymbolElements(symbol:String):Array<Element>
  {
    if (!this.isAnimate)
    {
      trace('WARNING: getSymbolElements() only works texture atlases!');
      return [];
    }

    var symbolInstance:Null<SymbolItem> = this.library.getSymbol(symbol);

    if (symbolInstance == null)
    {
      throw 'Symbol not found in atlas: ${symbol}';
      return [];
    }

    var elements:Array<Element> = symbolInstance.timeline.getElementsAtIndex(0);

    if (elements?.length == 0)
    {
      trace('WARNING: No Atlas Elements found for "$symbol" symbol.');
    }

    return elements ?? [];
  }

  /**
   * Scales an element by a certain multiplier.
   * @param element The element to scale.
   * @param scale The scale multiplier.
   * @param positionOffset The offset to apply to `tx` and `ty` after scaling.
   * (Or in other words, the position of the element.)
   */
  public function scaleElement(element:Element, scale:Float, positionOffset:Float = 0, scaleEverything:Bool = false):Void
  {
    if (!this.isAnimate)
    {
      trace('WARNING: scaleElement() only works texture atlases!');
      return;
    }

    var elementMatrix:FlxMatrix = element.matrix;

    if (scaleEverything)
    {
      elementMatrix.scale(scale, scale);
      return;
    }

    var symbolInstance:SymbolInstance = element.parentFrame.convertToSymbol(0, 1);
    var transformPoint:FlxPoint = symbolInstance.transformationPoint;

    elementMatrix.a += scale;
    elementMatrix.d += scale;

    elementMatrix.tx -= transformPoint.x * scale;
    elementMatrix.ty -= transformPoint.y * scale;

    elementMatrix.tx -= positionOffset;
    elementMatrix.ty -= positionOffset;
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

  override function preparePixelPerfectMatrix(matrix:FlxMatrix)
  {
    matrix.tx = Math.round(matrix.tx / this.scale.x) * this.scale.x;
    matrix.ty = Math.round(matrix.ty / this.scale.y) * this.scale.y;
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
